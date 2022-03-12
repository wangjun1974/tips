#!/bin/bash

usage() {
  echo "use this program to register edge cluster to acm"
  echo "usage $0 <edge_cluster_name>"
  exit 0
}


if [ x"$1" == 'x' ]; then
   usage
fi

CLUSTER_NAME=$1
mkdir -p /Users/junwang/kubeconfig/${CLUSTER_NAME}

# envs
HUB_KUBECONFIG="/Users/junwang/kubeconfig/ocp4/lb-ext.kubeconfig"
EDGE_KUBECONFIG="/Users/junwang/kubeconfig/${CLUSTER_NAME}/kubeconfig"
EDGE_AUTHJSON="/Users/junwang/kubeconfig/${CLUSTER_NAME}/auth.json"
EDGE_HOSTNAME="microshift-for-gree"
EDGE_IP="8.130.18.107"

# obtain edge kubeconfig
ssh root@${EDGE_HOSTNAME} podman cp microshift:/var/lib/microshift/resources/kubeadmin/kubeconfig /tmp/config
scp root@${EDGE_HOSTNAME}:/tmp/config ${EDGE_KUBECONFIG}
gsed -i "s|127.0.0.1|${EDGE_IP}|g" ${EDGE_KUBECONFIG}


# HUB
# HUB
# HUB
# create mangedcluster on acm
oc --kubeconfig=${HUB_KUBECONFIG} new-project ${CLUSTER_NAME}
oc --kubeconfig=${HUB_KUBECONFIG} label namespace ${CLUSTER_NAME} cluster.open-cluster-management.io/managedCluster=${CLUSTER_NAME}

cat <<EOF | oc --kubeconfig=${HUB_KUBECONFIG} apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${CLUSTER_NAME}
  namespace: ${CLUSTER_NAME}
spec:
  clusterName: ${CLUSTER_NAME}
  clusterNamespace: ${CLUSTER_NAME}
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

cat <<EOF | oc --kubeconfig=${HUB_KUBECONFIG} apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${CLUSTER_NAME}
spec:
  hubAcceptsClient: true
EOF

# generate IMPORT and CRDS manifest
IMPORT=$(oc --kubeconfig=${HUB_KUBECONFIG} get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.import\.yaml}')
CRDS=$(oc --kubeconfig=${HUB_KUBECONFIG} get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.crds\.yaml}')
# HUB
# HUB
# HUB

# put pull secret in auth.json
#cat > ${EDGE_AUTHJSON} <<EOF
# xxx
#EOF

# SPOKE
# SPOKE
# SPOKE
oc --kubeconfig=${EDGE_KUBECONFIG} new-project open-cluster-management-agent
oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=${EDGE_AUTHJSON} --type=kubernetes.io/dockerconfigjson
oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent create sa klusterlet
oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent create sa klusterlet-registration-sa
oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent create sa klusterlet-work-sa
oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

oc --kubeconfig=${EDGE_KUBECONFIG} new-project open-cluster-management-agent-addon
oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=${EDGE_AUTHJSON} --type=kubernetes.io/dockerconfigjson
oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

oc --kubeconfig=${EDGE_KUBECONFIG} project open-cluster-management-agent
echo $CRDS | base64 -d | oc --kubeconfig=${EDGE_KUBECONFIG} apply -f -
echo $IMPORT | base64 -d | oc --kubeconfig=${EDGE_KUBECONFIG} apply -f -

sleep 240
for sa in klusterlet-addon-appmgr klusterlet-addon-certpolicyctrl klusterlet-addon-iampolicyctrl-sa klusterlet-addon-policyctrl klusterlet-addon-search klusterlet-addon-workmgr ; do
  oc --kubeconfig=${EDGE_KUBECONFIG} -n open-cluster-management-agent-addon patch sa $sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
done
oc delete pod --all -n open-cluster-management-agent-addon
# SPOKE
# SPOKE
# SPOKE

