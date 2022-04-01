#!/bin/bash

CLUSTER_KUBECONFIG=$1
OPERATOR_NAMESPACE="submariner-operator"
TEMPDIR=$(mktemp -d)

usage() {
  echo "usage: $0 [kubeconfig] [submariner-release]"
  echo "e.g.: $0 /Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig alpha-0.11"
  return 0
}

install_operator() {

  cd ${TEMDIR}

  ( ${OC_CMD} get projects | grep -q ${OPERATOR_NAMESPACE} ) || ${OC_CMD} new-project ${OPERATOR_NAMESPACE}
  ( ${OC_CMD} -n ${OPERATOR_NAMESPACE} get limitrange | grep -q "core-resource-limits" ) && ${OC_CMD} -n ${OPERATOR_NAMESPACE} delete limitrange ${OPERATOR_NAMESPACE}-core-resource-limits 

  echo "create OperatorGroup"
  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ${OPERATOR_NAMESPACE}
  namespace: ${OPERATOR_NAMESPACE}
spec:
  targetNamespaces:
  - ${OPERATOR_NAMESPACE}
EOF

  echo "create Subscription"
  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: submariner
  namespace: ${OPERATOR_NAMESPACE}
spec:
  channel: ${OPERATOR_RELEASE}
  installPlanApproval: Automatic
  name: submariner
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

  echo "wait csv......" 
  until [ $(${OC_CMD} -n ${OPERATOR_NAMESPACE} get csv | grep -E "submariner" | wc -l) != '0' ];
  do
    echo "CSV is installing......"
    sleep 5s
  done

  echo "wait Subscription status.phase == Success" 
  CSV_NAME=$(${OC_CMD} -n ${OPERATOR_NAMESPACE} get csv -l operators.coreos.com/submariner.submariner-operator='' -o name)
  until [ $(${OC_CMD} -n ${OPERATOR_NAMESPACE} get ${CSV_NAME} -o jsonpath='{.status.phase}') == "Succeeded" ];
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
  OPERATOR_RELEASE='alpha-0.11'
else
  OPERATOR_RELEASE=$2
fi

install_operator

rm -rf ${TEMPDIR}

