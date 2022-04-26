### Test ODF mirror

```
# 安装 subctl
$ wget https://github.com/submariner-io/submariner-operator/releases/download/subctl-release-0.10/subctl-release-0.10-darwin-amd64.tar.xz

# 检查 clusterCIDR 和 serviceCIDR 网络在集群间是否重叠
# hub cluster
$ oc --kubeconfig=./hub/lb-ext.kubeconfig get networks.config.openshift.io cluster -o json | jq .spec
{
  "clusterNetwork": [
    {
      "cidr": "10.132.0.0/14",
      "hostPrefix": 23
    }
  ],
  "externalIP": {
    "policy": {}
  },
  "networkType": "OpenShiftSDN",
  "serviceNetwork": [
    "172.32.0.0/16"
  ]
}

# 检查 clusterCIDR 和 serviceCIDR 网络在集群间是否重叠
# cluster1 cluster
$ oc --kubeconfig=./cluster1/lb-ext.kubeconfig get networks.config.openshift.io cluster -o json | jq .spec
{
  "clusterNetwork": [
    {
      "cidr": "10.128.0.0/14",
      "hostPrefix": 23
    }
  ],
  "externalIP": {
    "policy": {}
  },
  "networkType": "OVNKubernetes",
  "serviceNetwork": [
    "172.30.0.0/16"
  ]
}

# 检查 clusterCIDR 和 serviceCIDR 网络在集群间是否重叠
# cluster2 cluster
$ oc --kubeconfig=./cluster2/lb-ext.kubeconfig get networks.config.openshift.io cluster -o json | jq .spec
{
  "clusterNetwork": [
    {
      "cidr": "10.140.0.0/14",
      "hostPrefix": 23
    }
  ],
  "externalIP": {
    "policy": {}
  },
  "networkType": "OVNKubernetes",
  "serviceNetwork": [
    "172.71.0.0/16"
  ]
}

# hub 安装 ODF 
# 检查 hub ocs-operator 日志，看是否有报错 
$ oc --kubeconfig=./hub/lb-ext.kubeconfig -n openshift-storage logs $(oc --kubeconfig=./hub/lb-ext.kubeconfig -n openshift-storage get pods -l name=ocs-operator -o name)

# 检查 hub cluster ODF 是否就绪
oc --kubeconfig=./hub/lb-ext.kubeconfig get storagecluster -n openshift-storage ocs-storagecluster -o jsonpath='{.status.phase}{"\n"}'

# 检查 hub nodes 有 ODF 所需的label
oc --kubeconfig=./hub/lb-ext.kubeconfig get nodes -l cluster.ocs.openshift.io/openshift-storage=



# 为节点打标签
# 当节点不在3个AZ时
# oc label nodes  cluster.ocs.openshift.io/openshift-storage=''

# 检查 cluster1 ODF pods
$ oc --kubeconfig=./cluster1/lb-ext.kubeconfig -n openshift-storage get pods 

# 检查 cluster1 nodes 有 ODF 所需的label
$ oc --kubeconfig=./cluster1/lb-ext.kubeconfig get nodes -l cluster.ocs.openshift.io/openshift-storage=

# 检查 cluster1 ocs-operator 日志
$ oc --kubeconfig=./cluster1/lb-ext.kubeconfig -n openshift-storage logs $(oc --kubeconfig=./cluster1/lb-ext.kubeconfig -n openshift-storage get pods -l name=ocs-operator -o name)

# 检查 cluster1 ODF 是否就绪
$ oc --kubeconfig=./cluster1/lb-ext.kubeconfig get storagecluster -n openshift-storage ocs-storagecluster -o jsonpath='{.status.phase}{"\n"}'


# Install submariner manually
subctl deploy-broker --kubeconfig ./hub/lb-ext.kubeconfig

subctl join  ./broker-info.subm --kubeconfig ./hub/lb-ext.kubeconfig --label-gateway=false --clusterid=local-cluster --cable-driver=vxlan --natt=false

subctl join  ./broker-info.subm --kubeconfig ./cluster1/lb-ext.kubeconfig --label-gateway=false --clusterid=cluster1 --cable-driver=vxlan --natt=false



$ oc --kubeconfig=./cluster3/lb-ext.kubeconfig get nodes

# 检查 cluster3 mcp 
$ oc --kubeconfig=./cluster3/lb-ext.kubeconfig -n openshift-machine-config-operator logs $(oc --kubeconfig=./cluster3/lb-ext.kubeconfig -n openshift-machine-config-operator get pods -l k8s-app="machine-config-daemon" -o name) -c machine-config-daemon
$ oc --kubeconfig=./cluster3/lb-ext.kubeconfig -n openshift-machine-config-operator logs pod/machine-config-daemon-d96m6 -c machine-config-daemon


# 为节点加标签
oc --kubeconfig=./hub/lb-ext.kubeconfig annotate node ip-10-1-201-14.ap-southeast-1.compute.internal gateway.submariner.io/public-ip=ipv4:1.2.3.4
oc --kubeconfig=./cluster1/lb-ext.kubeconfig annotate node ip-10-0-166-193.ap-northeast-3.compute.internal gateway.submariner.io/public-ip=ipv4:1.2.3.5

# 部署 submariner 
# 部署 broker
$ subctl deploy-broker --kubeconfig ./hub/lb-ext.kubeconfig

$ join local-cluster 
$ subctl join  ./broker-info.subm --kubeconfig ./hub/lb-ext.kubeconfig --clusterid=local-cluster --cable-driver=vxlan --natt=false
$ oc --kubeconfig=./hub/lb-ext.kubeconfig -n submariner-operator get pods 

$ join cluster1
$ subctl join  ./broker-info.subm --kubeconfig ./cluster1/lb-ext.kubeconfig --clusterid=cluster1 --cable-driver=vxlan --natt=false
$ oc --kubeconfig=./cluster1/lb-ext.kubeconfig -n submariner-operator get pods 

# 检查 connections 
$ subctl show connections --kubeconfig ./hub/lb-ext.kubeconfig
$ subctl show connections --kubeconfig ./cluster1/lb-ext.kubeconfig

$ subctl verify ./hub/lb-ext.kubeconfig ./cluster1/lb-ext.kubeconfig --only connectivity --verbose


$ oc --kubeconfig=./hub/lb-ext.kubeconfig create namespace nginx-test
$ oc --kubeconfig=./hub/lb-ext.kubeconfig -n nginx-test create deployment nginx --image=nginxinc/nginx-unprivileged:stable-alpine
$ oc --kubeconfig=./hub/lb-ext.kubeconfig -n nginx-test get pods -o wide
10.135.4.20
$ oc --kubeconfig=./hub/lb-ext.kubeconfig run -n nginx-test tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash

$ oc --kubeconfig=./cluster1/lb-ext.kubeconfig create namespace nginx-test
$ oc --kubeconfig=./cluster1/lb-ext.kubeconfig -n nginx-test create deployment nginx --image=nginxinc/nginx-unprivileged:stable-alpine
$ oc --kubeconfig=./cluster1/lb-ext.kubeconfig -n nginx-test get pods -o wide
10.130.4.26
$ oc --kubeconfig=./cluster1/lb-ext.kubeconfig run -n nginx-test tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash


oc --kubeconfig=./hub/lb-ext.kubeconfig patch cm rook-ceph-operator-config -n openshift-storage --type json --patch  '[{ "op": "add", "path": "/data/CSI_ENABLE_OMAP_GENERATOR", "value": "true" }]'

oc --kubeconfig=./cluster1/lb-ext.kubeconfig patch cm rook-ceph-operator-config -n openshift-storage --type json --patch  '[{ "op": "add", "path": "/data/CSI_ENABLE_OMAP_GENERATOR", "value": "true" }]'


oc --kubeconfig=./hub/lb-ext.kubeconfig  patch cm rook-ceph-operator-config -n openshift-storage --type json --patch  '[{ "op": "add", "path": "/data/CSI_ENABLE_VOLUME_REPLICATION", "value": "true" }]'

oc --kubeconfig=./cluster1/lb-ext.kubeconfig  patch cm rook-ceph-operator-config -n openshift-storage --type json --patch  '[{ "op": "add", "path": "/data/CSI_ENABLE_VOLUME_REPLICATION", "value": "true" }]'

for l in $(oc --kubeconfig=./hub/lb-ext.kubeconfig get pods -n openshift-storage -l app=csi-rbdplugin-provisioner -o jsonpath={.items[*].spec.containers[*].name}) ; do echo $l ; done | egrep "csi-omap-generator|volume-replication"

for l in $(oc --kubeconfig=./cluster1/lb-ext.kubeconfig get pods -n openshift-storage -l app=csi-rbdplugin-provisioner -o jsonpath={.items[*].spec.containers[*].name}) ; do echo $l ; done | egrep "csi-omap-generator|volume-replication"

# 安装 ODF Multicluster Operatro

# 在 hub 上定义 MirrorPeer

cat <<EOF | oc --kubeconfig=./hub/lb-ext.kubeconfig apply -f -
apiVersion: multicluster.odf.openshift.io/v1alpha1
kind: MirrorPeer
metadata:
  labels:
    control-plane: odfmo-controller-manager
  name: mirrorpeer-localcluster-cluster1
spec:
  items:
  - clusterName: local-cluster
    storageClusterRef:
      name: ocs-storagecluster
      namespace: openshift-storage
  - clusterName: cluster1
    storageClusterRef:
      name: ocs-storagecluster
      namespace: openshift-storage
EOF

oc --kubeconfig=./hub/lb-ext.kubeconfig get mirrorpeer mirrorpeer-localcluster-cluster1 -o jsonpath='{.status.phase}{"\n"}'

oc --kubeconfig=./cluster1/lb-ext.kubeconfig patch storagecluster $(oc --kubeconfig=./cluster1/lb-ext.kubeconfig get storagecluster -n openshift-storage -o=jsonpath='{.items[0].metadata.name}')  -n openshift-storage --type json --patch  '[{ "op": "replace", "path": "/spec/mirroring", "value": {"enabled": true} }]'

oc --kubeconfig=./hub/lb-ext.kubeconfig patch storagecluster $(oc --kubeconfig=./hub/lb-ext.kubeconfig get storagecluster -n openshift-storage -o=jsonpath='{.items[0].metadata.name}')  -n openshift-storage --type json --patch  '[{ "op": "replace", "path": "/spec/mirroring", "value": {"enabled": true} }]'

oc --kubeconfig=./cluster1/lb-ext.kubeconfig get cephblockpool -n openshift-storage -o=jsonpath='{.items[?(@.metadata.ownerReferences[*].kind=="StorageCluster")].spec.mirroring.enabled}{"\n"}'

oc --kubeconfig=./hub/lb-ext.kubeconfig get cephblockpool -n openshift-storage -o=jsonpath='{.items[?(@.metadata.ownerReferences[*].kind=="StorageCluster")].spec.mirroring.enabled}{"\n"}'

oc --kubeconfig=./cluster1/lb-ext.kubeconfig get pods -o name -l app=rook-ceph-rbd-mirror -n openshift-storage
oc --kubeconfig=./hub/lb-ext.kubeconfig  get pods -o name -l app=rook-ceph-rbd-mirror -n openshift-storage

oc --kubeconfig=./cluster1/lb-ext.kubeconfig get cephblockpool ocs-storagecluster-cephblockpool -n openshift-storage -o jsonpath='{.status.mirroringStatus.summary}{"\n"}'

oc --kubeconfig=./hub/lb-ext.kubeconfig get cephblockpool ocs-storagecluster-cephblockpool -n openshift-storage -o jsonpath='{.status.mirroringStatus.summary}{"\n"}'


oc --kubeconfig=./hub/lb-ext.kubeconfig -n openshift-storage logs $(oc --kubeconfig=./hub/lb-ext.kubeconfig  get pods -o name -l app=rook-ceph-rbd-mirror -n openshift-storage) -c rbd-mirror


# 创建 VolumeReplicationClass 在两个集群上\
cat <<EOF | oc --kubeconfig=./hub/lb-ext.kubeconfig apply -f -
apiVersion: replication.storage.openshift.io/v1alpha1
kind: VolumeReplicationClass
metadata:
  name: odf-rbd-volumereplicationclass
spec:
  provisioner: openshift-storage.rbd.csi.ceph.com
  parameters:
    mirroringMode: snapshot
    schedulingInterval: "5m"
    replication.storage.openshift.io/replication-secret-name: rook-csi-rbd-provisioner
    replication.storage.openshift.io/replication-secret-namespace: openshift-storage
EOF

cat <<EOF | oc --kubeconfig=./cluster1/lb-ext.kubeconfig apply -f -
apiVersion: replication.storage.openshift.io/v1alpha1
kind: VolumeReplicationClass
metadata:
  name: odf-rbd-volumereplicationclass
spec:
  provisioner: openshift-storage.rbd.csi.ceph.com
  parameters:
    mirroringMode: snapshot
    schedulingInterval: "5m"
    replication.storage.openshift.io/replication-secret-name: rook-csi-rbd-provisioner
    replication.storage.openshift.io/replication-secret-namespace: openshift-storage
EOF

# 创建 MirrorStorageClass，两个集群都创建
cat <<EOF | oc --kubeconfig=./hub/lb-ext.kubeconfig apply -f -
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-storagecluster-ceph-rbdmirror
parameters:
  clusterID: openshift-storage
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-storage
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: openshift-storage
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-storage
  imageFeatures: layering,exclusive-lock,object-map,fast-diff
  imageFormat: "2"
  pool: ocs-storagecluster-cephblockpool
provisioner: openshift-storage.rbd.csi.ceph.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

cat <<EOF | oc --kubeconfig=./cluster1/lb-ext.kubeconfig apply -f -
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-storagecluster-ceph-rbdmirror
parameters:
  clusterID: openshift-storage
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-storage
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: openshift-storage
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-storage
  imageFeatures: layering,exclusive-lock,object-map,fast-diff
  imageFormat: "2"
  pool: ocs-storagecluster-cephblockpool
provisioner: openshift-storage.rbd.csi.ceph.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

oc --kubeconfig=./cluster1/lb-ext.kubeconfig new-project my-database-app
curl -s https://raw.githubusercontent.com/red-hat-storage/ocs-training/master/training/modules/ocs4/attachments/configurable-rails-app.yaml -o app/configurable-rails-app.yaml 
oc --kubeconfig=./cluster1/lb-ext.kubeconfig apply -f app/configurable-rails-app.yaml 
oc --kubeconfig=./cluster1/lb-ext.kubeconfig new-app --template=my-database-app/rails-pgsql-persistent-storageclass -p STORAGE_CLASS=ocs-storagecluster-ceph-rbdmirror -p VOLUME_CAPACITY=5Gi

oc --kubeconfig=./cluster1/lb-ext.kubeconfig get pvc

oc --kubeconfig=./cluster1/lb-ext.kubeconfig rsh -n my-database-app $(oc --kubeconfig=./cluster1/lb-ext.kubeconfig get pods -n my-database-app|grep postgresql | grep -v deploy | awk {'print $1}') psql -c "\c root" -c "\d+" -c "select * from articles"

oc --kubeconfig=./cluster1/lb-ext.kubeconfig patch OCSInitialization ocsinit -n openshift-storage --type json --patch  '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'

TOOLS_POD=$(oc --kubeconfig=./cluster1/lb-ext.kubeconfig get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc --kubeconfig=./cluster1/lb-ext.kubeconfig rsh -n openshift-storage $TOOLS_POD

rbd -p ocs-storagecluster-cephblockpool mirror pool status
rbd -p ocs-storagecluster-cephblockpool mirror snapshot schedule ls

CSIVOL=$(kubectl --kubeconfig=./cluster1/lb-ext.kubeconfig get pv $(kubectl --kubeconfig=./cluster1/lb-ext.kubeconfig get pv | grep postgresql | awk '{ print $1 }') -o jsonpath='{.spec.csi.volumeHandle}' | cut -d '-' -f 6- | awk '{print "csi-vol-"$1}')

rbd -p ocs-storagecluster-cephblockpool ls
rbd -p ocs-storagecluster-cephblockpool mirror image enable csi-vol-829552d5-c53e-11ec-b8e7-0a580a82041d snapshot

rbd -p ocs-storagecluster-cephblockpool info csi-vol-829552d5-c53e-11ec-b8e7-0a580a82041d

oc --kubeconfig=./hub/lb-ext.kubeconfig patch OCSInitialization ocsinit -n openshift-storage --type json --patch  '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'
TOOLS_POD=$(oc --kubeconfig=./hub/lb-ext.kubeconfig get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc --kubeconfig=./hub/lb-ext.kubeconfig rsh -n openshift-storage $TOOLS_POD
rbd -p ocs-storagecluster-cephblockpool ls
rbd -p ocs-storagecluster-cephblockpool info csi-vol-829552d5-c53e-11ec-b8e7-0a580a82041d
rbd -p ocs-storagecluster-cephblockpool mirror pool status


oc --kubeconfig=./hub/lb-ext.kubeconfig -n openshift-storage logs $(oc --kubeconfig=./hub/lb-ext.kubeconfig  get pods -o name -l app=rook-ceph-rbd-mirror -n openshift-storage) -c rbd-mirror

# 报错
# hub .status.mirroringStatus.summary 为 Warning
# rbd-mirror pod 里 rbd-mirror container 日志
$ oc --kubeconfig=./hub/lb-ext.kubeconfig -n openshift-storage logs $(oc --kubeconfig=./hub/lb-ext.kubeconfig  get pods -o name -l app=rook-ceph-rbd-mirror -n openshift-storage) -c rbd-mirror
...
debug 2022-04-26T08:21:08.360+0000 7f9ea27e6540  0 rbd::mirror::PoolReplayer: 0x5619b75c2900 init_rados: reverting global config option override: keyring: /etc/ceph/keyring-store/keyring -> /etc/ceph/440bbe62-76eb-4cc6-bbd8-472493db7118.client.rbd-mirror-peer.keyring,/etc/ceph/440bbe62-76eb-4cc6-bbd8-472493db7118.keyring,/etc/ceph/keyring,/etc/ceph/keyring.bin,
debug 2022-04-26T08:21:08.360+0000 7f9ea27e6540  0 rbd::mirror::PoolReplayer: 0x5619b75c2900 init_rados: reverting global config option override: mon_host: [v2:172.32.194.159:3300,v1:172.32.194.159:6789],[v2:172.32.254.149:3300,v1:172.32.254.149:6789],[v2:172.32.39.214:3300,v1:172.32.39.214:6789] -> 
debug 2022-04-26T08:21:08.360+0000 7f9ea27e6540 -1 Errors while parsing config file!
debug 2022-04-26T08:21:08.360+0000 7f9ea27e6540 -1 can't open 440bbe62-76eb-4cc6-bbd8-472493db7118.conf: (2) No such file or directory
debug 2022-04-26T08:26:08.361+0000 7f9ea27e6540  0 monclient(hunting): authenticate timed out after 300

oc --kubeconfig=./cluster1/lb-ext.kubeconfig -n openshift-storage logs $(oc --kubeconfig=./cluster1/lb-ext.kubeconfig  get pods -o name -l app=rook-ceph-rbd-mirror -n openshift-storage) -c rbd-mirror

oc --kubeconfig=./hub/lb-ext.kubeconfig -n openshift-storage rsh $(oc --kubeconfig=./hub/lb-ext.kubeconfig  get pods -o name -l app=rook-ceph-rbd-mirror -n openshift-storage)


oc --kubeconfig=./cluster1/lb-ext.kubeconfig -n openshift-storage rsh $(oc --kubeconfig=./cluster1/lb-ext.kubeconfig  get pods -o name -l app=rook-ceph-rbd-mirror -n openshift-storage)


[client.admin]
key = AQBJTWdiTQauMRAA+9EY9MfxVsrBgF39TsTkKQ==

# 删除 submariner 
oc --kubeconfig=./cluster1/lb-ext.kubeconfig delete project submariner-operator
oc --kubeconfig=./hub/lb-ext.kubeconfig delete project submariner-operator
oc --kubeconfig=./hub/lb-ext.kubeconfig delete project submariner-k8s-broker


hub
sh-4.4# cat /etc/ceph/keyring-store/keyring 

[client.rbd-mirror.a]
        key = AQBwq2dioFGvLRAAWYaceCjByVw0cnjwQmJktQ==
        caps mon = "profile rbd-mirror"
        caps osd = "profile rbd"
hub
client.rbd-mirror.a
        key: AQBwq2dioFGvLRAAWYaceCjByVw0cnjwQmJktQ==
        caps: [mon] profile rbd-mirror
        caps: [osd] profile rbd


cluster1
sh-4.4# cat /etc/ceph/keyring-store/keyring 

[client.rbd-mirror.a]
        key = AQBpq2di9wE5ChAALg8koh3vz7e99a/rNh3e3A==
        caps mon = "profile rbd-mirror"
        caps osd = "profile rbd"

cluster1
client.rbd-mirror.a
        key: AQBpq2di9wE5ChAALg8koh3vz7e99a/rNh3e3A==
        caps: [mon] profile rbd-mirror
        caps: [osd] profile rbd

cluster1
uuid: 440bbe62-76eb-4cc6-bbd8-472493db7118

hub
uuid: 34009d0d-961e-45f2-a824-b9bfe16642ec


oc --kubeconfig ./cluster1/lb-ext.kubeconfig get cephblockpool.ceph.rook.io/ocs-storagecluster-cephblockpool -n openshift-storage -ojsonpath='{.status.info.rbdMirrorBootstrapPeerSecretName}{"\n"}'  
pool-peer-token-ocs-storagecluster-cephblockpool


oc --kubeconfig ./hub/lb-ext.kubeconfig get cephblockpool.ceph.rook.io/ocs-storagecluster-cephblockpool -n openshift-storage -ojsonpath='{.status.info.rbdMirrorBootstrapPeerSecretName}{"\n"}'

```