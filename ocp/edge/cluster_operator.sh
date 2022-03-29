#!/bin/bash

# envs
HUB_KUBECONFIG="/opt/acm/hub/lb-ext.kubeconfig"
PULL_SECRETS="/opt/acm/secrets/auth.json"

# function: check if spoke cluster exists
check_spoke_cluster_exist() {
  SPOKE_CLUSTER_NAME=$1

  if [ x${SPOKE_CLUSTER_NAME} == 'x' ]; then
    return 1
  else
    oc --kubeconfig=${HUBECONFIG} get managedcluster ${SPOKE_CLUSTER_NAME} >/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
      return 0
    else
      return 1
    fi
  fi
}

# function: check if spoke cluster api endpoint live
check_spoke_cluster_api_exist() {
  SPOKE_CLUSTER_API=$1

  if [ x${SPOKE_CLUSTER_API} == 'x' ]; then
    return 1
  else
    curl -k "https://"${SPOKE_CLUSTER_API}":6443" >/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
      return 0
    else
      return 1
    fi
  fi
}

# function: check if spoke cluster kubeconfig exist and can use it access spoke cluster
check_spoke_cluster_kubeconfig_exist() {
  SPOKE_CLUSTER_KUBECONFIG=$1

  if [ x${SPOKE_CLUSTER_KUBECONFIG} == 'x' ]; then
    return 1
  else
    oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} get projects >/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
      return 0
    else
      return 1
    fi
  fi
}

# function: remove spoke cluster
remove_spoke_cluster() {
  SPOKE_CLUSTER_NAME=$1

  if [ x${SPOKE_CLUSTER_NAME} == 'x' ]; then
    return 1
  else
    oc --kubeconfig=${HUBECONFIG} delete managedcluster ${SPOKE_CLUSTER_NAME} >/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
      rm -f /opt/acm/clusters/remove/${SPOKE_CLUSTER_NAME}
      rm -rf /opt/acm/clusters/${SPOKE_CLUSTER_NAME}
      return 0
    else
      return 1
    fi
  fi
}

# function: add spoke cluster
add_spoke_cluster() {
  SPOKE_CLUSTER_NAME=$1
  SPOKE_CLUSTER_KUBECONFIG=$2
  SPOKE_CLUSTER_API=$3

  # Hub - add namespace, label namespace
  oc --kubeconfig=${HUB_KUBECONFIG} new-project ${SPOKE_CLUSTER_NAME}
  oc --kubeconfig=${HUB_KUBECONFIG} label namespace ${SPOKE_CLUSTER_NAME} cluster.open-cluster-management.io/managedCluster=${SPOKE_CLUSTER_NAME}

  # Hub - KlusterletAddonConfig
  cat <<EOF | oc --kubeconfig=${HUB_KUBECONFIG} apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${SPOKE_CLUSTER_NAME}
  namespace: ${SPOKE_CLUSTER_NAME}
spec:
  clusterName: ${SPOKE_CLUSTER_NAME}
  clusterNamespace: ${SPOKE_CLUSTER_NAME}
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: true
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  iamPolicyController:
    enabled: true
  policyController:
    enabled: true
  searchCollector:
    enabled: true
  version: 2.2.0
EOF

  # Hub - ManagedCluster
  cat <<EOF | oc --kubeconfig=${HUB_KUBECONFIG} apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${SPOKE_CLUSTER_NAME}
spec:
  hubAcceptsClient: true
EOF

  # Hub - generate IMPORT and CRDs for spoke
  IMPORT=$(oc --kubeconfig=${HUB_KUBECONFIG} -n ${SPOKE_CLUSTER_NAME} get secret ${SPOKE_CLUSTER_NAME}-import -o jsonpath='{.data.import\.yaml}')
  CRDS=$(oc --kubeconfig=${HUB_KUBECONFIG} -n ${SPOKE_CLUSTER_NAME} get secret ${SPOKE_CLUSTER_NAME}-import -o jsonpath='{.data.crds\.yaml}')

  # Spoke - namespace open-cluster-management-agent, secret rhacm, sa klusterlet/klusterlet-registration-sa/klusterlet-work-sa
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} new-project open-cluster-management-agent
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=${PULL_SECRETS} --type=kubernetes.io/dockerconfigjson
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent create sa klusterlet
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent create sa klusterlet-registration-sa
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent create sa klusterlet-work-sa
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

  # Spoke - namespace open-cluster-management-agent-addon, sa klusterlet-addon-operator
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} new-project open-cluster-management-agent-addon
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=${PULL_SECRETS} --type=kubernetes.io/dockerconfigjson
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

  # Spoke - CRDS and IMPORT
  echo $CRDS | base64 -d | oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent apply -f -
  echo $IMPORT | base64 -d | oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent apply -f -
 
  # Spoke - sleep 60 seconds
  sleep 60

  # Spoke - patch sa and delete pods
  for sa in klusterlet-addon-appmgr klusterlet-addon-certpolicyctrl klusterlet-addon-iampolicyctrl-sa klusterlet-addon-policyctrl klusterlet-addon-search klusterlet-addon-workmgr ; do
    oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} -n open-cluster-management-agent-addon patch sa $sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
  done
  
  oc --kubeconfig=${SPOKE_CLUSTER_KUBECONFIG} delete pod --all -n open-cluster-management-agent-addon

  return 0
}

# function: reset env
reset_env() {
  CLUSTER_NAME=''
  CLUSTER_KUBECONFIG=''
  CLUSTER_API=''
}

# function: call function add_spoke_cluster add cluster to acm
add_cluster() {
  echo "cluster name is ${CLUSTER_NAME}"
  echo "kubeconfig is ${CLUSTER_KUBECONFIG}"
  echo "cluster api endpoint is ${CLUSTER_API}"

  check_spoke_cluster_exist ${CLUSTER_NAME}
  if [ $? -ne 0 ]; then
    check_spoke_cluster_api_exist ${CLUSTER_API} && check_spoke_cluster_kubeconfig_exist ${CLUSTER_KUBECONFIG}
    if [ $? -eq 0 ]; then
      add_spoke_cluster ${CLUSTER_NAME} ${CLUSTER_KUBECONFIG} ${CLUSTER_API}
      if [ $? -eq 0 ];then rm -f /opt/acm/clusters/add/${CLUSTER_NAME}; fi
    fi     
  fi
} 

# function: call function remove_spoke_cluster remove cluster from acm
remove_cluster() {
  echo "cluster name is ${CLUSTER_NAME}"
  echo "kubeconfig is ${CLUSTER_KUBECONFIG}"
  echo "cluster api endpoint is ${CLUSTER_API}"

  check_spoke_cluster_exist ${CLUSTER_NAME}
  if [ $? -eq 0 ]; then
    remove_spoke_cluster ${CLUSTER_NAME}
  fi
} 

# control loop - add cluster
if [ -d /opt/acm/clusters/add ] && [ $(ls -A /opt/acm/clusters/add | wc -m) != "0" ]; then
  for i in /opt/acm/clusters/add/* ; do 
    reset_env
    source $i
    add_cluster
  done
fi

# control loop - remove cluster
if [ -d /opt/acm/clusters/remove ] && [ $(ls -A /opt/acm/clusters/remove | wc -m) != "0" ]; then
  for i in /opt/acm/clusters/remove/* ; do
    reset_env
    source $i
    remove_cluster
  done
fi

