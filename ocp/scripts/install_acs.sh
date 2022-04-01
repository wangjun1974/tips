#!/bin/bash

CLUSTER_KUBECONFIG=$1
TEMPDIR=$(mktemp -d)

usage() {
  echo "usage: $0 [kubeconfig] [acs-release]"
  echo "e.g.: $0 /Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig rhacs-3.68"
  return 0
}

install_acs() {

  cd ${TEMDIR}

  ( ${OC_CMD} get projects | grep -q "rhacs-opeartor" ) || ${OC_CMD} new-project rhacs-operator
  ( ${OC_CMD} -n rhacs-operator get limitrange | grep -q "core-resource-limits" ) && ${OC_CMD} -n rhacs-operator delete limitrange rhacs-operator-core-resource-limits 

  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: rhacs-operator
  namespace: rhacs-operator
spec: {}
EOF

  echo "create Subscription"
  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhacs-operator
  namespace: rhacs-operator
spec:
  channel: ${ACS_RELEASE}
  installPlanApproval: Automatic
  name: rhacs-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

  echo "wait csv......" 
  until [ $(${OC_CMD} -n rhacs-operator get csv | grep -E "rhacs-operator" | wc -l) != '0' ];
  do
    echo "CSV is installing......"
    sleep 5s
  done

  echo "wait Subscription status.phase == Success" 
  CSV_NAME=$(${OC_CMD} -n rhacs-operator get csv -l operators.coreos.com/rhacs-operator.rhacs-operator='' -o name)
  until [ $(${OC_CMD} -n rhacs-operator get $CSV_NAME -o jsonpath='{.status.phase}') == "Succeeded" ];
  do
    echo "Subscription is installing......"
    sleep 5s
  done

  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: v1
data:
  password: cGFzc3dvcmQ=
  username: YWRtaW4=
kind: Secret
metadata:
  name: stackrox-password
  namespace: rhacs-operator
type: Opaque
EOF

  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: platform.stackrox.io/v1alpha1
kind: Central
metadata:
  name: stackrox-central-services
  namespace: rhacs-operator
spec:
  central:
    adminPasswordSecret:
      name: stackrox-password
    exposure:
      loadBalancer:
        enabled: false
        port: 443
      nodePort:
        enabled: false
      route:
        enabled: true
    persistence:
      persistentVolumeClaim:
        claimName: stackrox-db
  egress:
    connectivityPolicy: Online
  scanner:
    analyzer:
      scaling:
        autoScaling: Enabled
        maxReplicas: 5
        minReplicas: 2
        replicas: 3
    scannerComponent: Enabled
EOF

  echo "wait Central stackrox-central-services status.conditions[0].reason == InstallSuccessful"
  until [ $(${OC_CMD} -n rhacs-operator get Central stackrox-central-services -o jsonpath='{.status.conditions[0].reason}') == "InstallSuccessful" ];
  do
    echo "Subscription is installing......"
    sleep 5s
  done

  echo "Configuring cluster-init bundle"
  CENTRAL_DATA={\"name\":\"local-cluster\"}
  CENTRAL_PASSWORD=$(echo cGFzc3dvcmQK | base64 -d )
  CENTRAL_ROUTE=$(${OC_CMD} -n rhacs-operator get route central -o jsonpath='{.spec.host}')
  curl -k -o ~/tmp/bundle.json -X POST -u "admin:${CENTRAL_PASSWORD}" -H "Content-Type: application/json" --data ${CENTRAL_DATA} https://${CENTRAL_ROUTE}/v1/cluster-init/init-bundles
  echo "Bundle received"
 
  echo "Applying bundle"
  # No jq in container, python to the rescue
  cat ~/tmp/bundle.json | python3 -c "import sys, json; print(json.load(sys.stdin)['kubectlBundle'])" | base64 -d | ${OC_CMD} apply -f -

  echo "Create SecuredCluster ..."

  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: platform.stackrox.io/v1alpha1
kind: SecuredCluster
metadata:
  name: stackrox-secured-cluster-services
  namespace: rhacs-operator
spec:
  admissionControl:
    bypass: BreakGlassAnnotation
    contactImageScanners: ScanIfMissing
    listenOnCreates: true
    listenOnEvents: true
    listenOnUpdates: true
    timeoutSeconds: 3
  auditLogs:
    collection: Auto
  clusterName: local-cluster
  perNode:
    collector:
      collection: KernelModule
      imageFlavor: Regular
    taintToleration: TolerateTaints
EOF
}

if [ x$1 == 'x' ]; then
  OC_CMD='oc '
else
  OC_CMD="oc --kubeconfig=$1"
fi

if [ x$2 == 'x' ]; then
  ACS_RELEASE='rhacs-3.68'
else
  ACS_RELEASE=$2
fi

install_acs

rm -rf ${TEMPDIR}

