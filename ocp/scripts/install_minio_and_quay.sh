#!/bin/bash

CLUSTER_KUBECONFIG=$1
TEMPDIR=$(mktemp -d)

usage() {
  echo "usage: $0 [kubeconfig]"
  return 0
}

install_minio() {
  cd ${TEMPDIR}
  git clone https://github.com/vmware-tanzu/velero.git

  # deploy minio
  ${OC_CMD} -n velero apply -f velero/examples/minio/00-minio-deployment.yaml
  ${OC_CMD} -n velero expose svc minio
}

install_quay() {

  echo "create Subscription"
  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: quay-operator
  namespace: openshift-operators
spec:
  channel: stable-3.6
  installPlanApproval: Automatic
  name: quay-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: quay-operator.v3.6.4
EOF

  echo "wait Subscription status.phase == Success" 
  until [ $(${OC_CMD} -n openshift-operators get csv quay-operator.v3.6.4 -o jsonpath='{.status.phase}') == "Succeeded" ];
  do
    echo "Subscription is installing......"
    sleep 5s
  done

  ( ${OC_CMD} get projects | grep -q "example-registry" ) || {${OC_CMD} new-project example-registry

  cd ${TEMPDIR}
  ${OC_CMD} -n velero get route minio -o jsonpath='{.spec.host}' | tee quay_hostname
  QUAY_HOSTNAME=$(cat quay_hostname)

  cat <<EOF > ./config.yaml
DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
  default:
  - RadosGWStorage
  - access_key: minio
    secret_key: minio123
    hostname: ${QUAY_HOSTNAME}
    bucket_name: velero
    port: 80
    is_secure: false
    storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE: [default]
FEATURE_USER_INITIALIZE: true
FEATURE_USER_CREATION: true
SUPER_USERS:
- quayadmin
EOF

  ( ${OC_CMD} -n example-registry get secret | grep -q "config-bundle-secret" )  || ${OC_CMD} -n example-registry create secret generic --from-file config.yaml=./config.yaml config-bundle-secret

  cat <<EOF | ${OC_CMD} apply -f -
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
metadata:
  name: example-registry
  namespace: example-registry
spec:
  components:
    - managed: false
      kind: clair
    - managed: true
      kind: postgres
    - managed: false
      kind: objectstorage
    - managed: true
      kind: redis
    - managed: false
      kind: horizontalpodautoscaler
    - managed: true
      kind: route
    - managed: false
      kind: mirror
    - managed: false
      kind: monitoring
    - managed: true
      kind: tls
  configBundleSecret: config-bundle-secret
EOF

}

mkdir -p ${TEMPDIR}

if [ x$1 == 'x' ]; then
  OC_CMD='oc '
else
  OC_CMD="oc --kubeconfig=$1"
fi

install_minio
install_quay
