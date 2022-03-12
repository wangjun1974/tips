#!/bin/bash

usage() {
  echo "use this program to clean edge cluster in acm and edge node"
  echo "usage $0 <edge_cluster_name>"
  exit 0
}


if [ x"$1" == 'x' ]; then
   usage
fi

CLUSTER_NAME=$1

# envs
HUB_KUBECONFIG="/Users/junwang/kubeconfig/ocp4/lb-ext.kubeconfig"
EDGE_HOSTNAME="microshift-for-gree"

# delete mangedcluster from acm
oc --kubeconfig=${HUB_KUBECONFIG} delete managedcluster ${CLUSTER_NAME}

# remove microshift from edge
cat > /tmp/cleanup.sh <<'EOF'
systemctl stop microshift
/usr/bin/crictl stopp $(/usr/bin/crictl pods -q)
/usr/bin/crictl stop $(/usr/bin/crictl ps -aq)
/usr/bin/crictl rmp $(crictl pods -q)
rm -rf /var/lib/containers/*
crio wipe -f
EOF

scp /tmp/cleanup.sh root@${EDGE_HOSTNAME}:/tmp/cleanup.sh
ssh root@${EDGE_HOSTNAME} /bin/bash /tmp/cleanup.sh

