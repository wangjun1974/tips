#!/bin/bash

CLUSTER_KUBECONFIG=$1
TEMPDIR=$(mktemp -d)

usage() {
  echo "usage: $0 [kubeconfig] [acm-release]"
  echo "e.g.: $0 /Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig release-2.2"
  return 0
}

install_acm() {

  cd ${TEMDIR}

  ( ${OC_CMD} get projects | grep -q "open-cluster-management" ) || ${OC_CMD} new-project open-cluster-management
  ( ${OC_CMD} -n open-cluster-management get limitrange | grep -q "core-resource-limits" ) && ${OC_CMD} -n open-cluster-management delete limitrange open-cluster-management-core-resource-limits 


  echo "create OperatorGroup"
  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: open-cluster-management 
  namespace: open-cluster-management
spec:
  targetNamespaces:
  - open-cluster-management
EOF

  echo "create Subscription"
  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
    name: advanced-cluster-management
    namespace: open-cluster-management
spec:
    channel: ${ACM_RELEASE}
    installPlanApproval: Automatic
    name: advanced-cluster-management
    source: redhat-operators
    sourceNamespace: openshift-marketplace
EOF


  echo "wait csv......" 
  until [ $(${OC_CMD} -n open-cluster-management get csv | grep -E "advanced-cluster-management" | wc -l) != '0' ];
  do
    echo "CSV is installing......"
    sleep 5s
  done

  echo "wait Subscription status.phase == Success" 
  CSV_NAME=$(${OC_CMD} -n open-cluster-management get csv -l operators.coreos.com/advanced-cluster-management.open-cluster-management='' -o name)
  until [ $(${OC_CMD} -n open-cluster-management get $CSV_NAME -o jsonpath='{.status.phase}') == "Succeeded" ];
  do
    echo "Subscription is installing......"
    sleep 5s
  done

  echo "create multiclusterhub......" 
  cat <<EOF | ${OC_CMD} -n open-cluster-management apply -f -
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  namespace: open-cluster-management
  name: multiclusterhub
spec: {}
EOF

  echo "wait MultiClusterHub mch status.phase == Running"
  until [ $(${OC_CMD} -n open-cluster-management get MultiClusterHub multiclusterhub -o jsonpath='{.status.phase}') == "Running" ];
  do
    echo "Subscription is installing......"
    sleep 5s
  done

}

if [ x$1 == 'x' ]; then
  OC_CMD='oc '
else
  OC_CMD="oc --kubeconfig=$1"
fi

if [ x$2 == 'x' ]; then
  ACM_RELEASE='release-2.2'
else
  ACM_RELEASE=$2
fi

install_acm

rm -rf ${TEMPDIR}

