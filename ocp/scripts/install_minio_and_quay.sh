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
  cd velero
  ${OC_CMD} -n velero apply -f examples/minio/00-minio-deployment.yaml
  ${OC_CMD} -n velero expose svc minio

}

install_quay() {
  echo "install quay"  
}

mkdir -p ${TEMPDIR}

if [ x$1 == 'x' ]; then
  OC_CMD='oc '
else
  OC_CMD="oc --kubeconfig=$1"
fi

install_minio
install_quay
