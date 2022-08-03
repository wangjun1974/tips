### OpenShift Virtualization 
https://kubevirt.io/user-guide/operations/installation/#restricting-kubevirt-components-node-placement
```
# kubevirt 的参数
# kubectl patch -n openshift-cnv kubevirt kubevirt-kubevirt-hyperconverged --type merge --patch '{"spec": {"workloads": {"nodePlacement": {"nodeSelector": {"metal": "true"}}}}}'

# 1. 创建 Baremetal Node
# 添加 machineset 
# aws instance type: m5.metal

# 2. 为 metal 节点添加 label 'metal':'true'

# 3. 安装 Operator - OpenShift Virtualization

# 4. 创建 HyperConverged kubevirt-hyperconverged

# 5. 编辑 HyperConverged kubevirt-hyperconverged
# 添加 workloads: nodePlacement: nodeSelector: metal: 'true'
spec:
....
  workloads:
    nodePlacement:
      nodeSelector:
        metal: 'true'

# cnv service 
$ oc get svc -n openshift-cnv 
NAME                                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)           AGE
cdi-api                                              ClusterIP   172.30.71.219    <none>        443/TCP           43m
cdi-prometheus-metrics                               ClusterIP   172.30.30.187    <none>        8080/TCP          43m
cdi-uploadproxy                                      ClusterIP   172.30.218.195   <none>        443/TCP           43m
cluster-network-addons-operator-prometheus-metrics   ClusterIP   172.30.218.20    <none>        8080/TCP          43m
hco-webhook-service                                  ClusterIP   172.30.245.7     <none>        4343/TCP          47m
hostpath-provisioner-operator-service                ClusterIP   172.30.254.5     <none>        9443/TCP          47m
hyperconverged-cluster-cli-download                  ClusterIP   172.30.90.142    <none>        8080/TCP          43m
kubemacpool-service                                  ClusterIP   172.30.190.168   <none>        443/TCP           43m
kubevirt-hyperconverged-operator-metrics             ClusterIP   172.30.85.150    <none>        8383/TCP          43m
kubevirt-operator-webhook                            ClusterIP   172.30.37.42     <none>        443/TCP           42m
kubevirt-prometheus-metrics                          ClusterIP   172.30.226.210   <none>        443/TCP           42m
nmstate-webhook                                      ClusterIP   172.30.22.201    <none>        443/TCP           43m
node-maintenance-operator-service                    ClusterIP   172.30.177.210   <none>        443/TCP           47m
rhel9-armed-ostrich-ssh-service                      NodePort    172.30.80.142    <none>        22000:30101/TCP   23m
ssp-operator-service                                 ClusterIP   172.30.128.229   <none>        9443/TCP          47m
virt-api                                             ClusterIP   172.30.71.10     <none>        443/TCP           42m
virt-template-validator                              ClusterIP   172.30.38.150    <none>        443/TCP           43m

# 虚拟机的 ssh service 是
rhel9-armed-ostrich-ssh-service                      NodePort    172.30.80.142    <none>        22000:30101/TCP   23m

# vmi 
$ oc -n openshift-cnv get vmi
NAME                  AGE   PHASE     IP            NODENAME                                     READY
rhel9-armed-ostrich   27m   Running   10.130.2.23   ip-10-0-188-217.us-east-2.compute.internal   True

$ oc debug node/<node>
sh-4.4# cat >> /tmp/key <<EOF
...
EOF
sh-4.4# chmod 0400 /tmp/key
sh-4.4# 
sh-4.4# ssh -i /tmp/key cloud-user@ip-10-0-140-246.us-east-2.compute.internal -p 30101
sh-4.4# ssh -i /tmp/key cloud-user@10.130.2.23

### 查看 CNV pod 日志
# hco-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='hyperconverged-cluster-operator' -o name)

# ssp-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='ssp-operator' -o name)

# cdi-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='cdi-operator' -o name)

# cluster-network-addons-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='cluster-network-addons-operator' -o name)

# hostpath-provisioner-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='hostpath-provisioner-operator' -o name)

# node-maintenance-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='node-maintenance-operator' -o name)

# virt-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-operator' -o name | head -1)
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-operator' -o name | tail -1)

# virt-api
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-api' -o name | head -1)
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-api' -o name | tail -1)

# virt-controller
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-controller' -o name | head -1)
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-controller' -o name | tail -1)

# virt-handler
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-handler' -o name | head -1)
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-handler' -o name | tail -1)

# virt-launcher - 如果有虚拟机运行的话
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-launcher' -o name | head -1)

# virt-template-validator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-template-validator' -o name | head -1)

# hco-webhook
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='hyperconverged-cluster-webhook' -o name)

# hyperconverged-cluster-cli-download
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='hyperconverged-cluster-cli-download' -o name)

# cdi-apiserver
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l cdi.kubevirt.io='cdi-apiserver' -o name)

# cdi-deployment
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l cdi.kubevirt.io='' -o name)

# cdi-uploadproxy
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l cdi.kubevirt.io='cdi-uploadproxy' -o name)

# cdi-upload-restore - 备份恢复时会创建
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l cdi.kubevirt.io='cdi-upload-server' -o name)

# bridge-marker
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l app='bridge-marker' -o name | head -1)

# kube-cni-linux-bridge-plugin
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l app='cni-plugins' -o name | head -1)

# kubemacpool-cert-manager
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l control-plane='cert-manager' -o name)

# kubemacpool-mac-controller-manager
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l control-plane='mac-controller-manager' -o name)

# nmstate-cert-manager
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='nmstate-cert-manager' -o name)

# nmstate-handler
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='nmstate-handler' -o name | head -1)

# nmstate-webhook
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='nmstate-webhook' -o name | head -1)

# 安装 ODF
# 查看 ODF pod 日志
# ocs-operator
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l name='ocs-operator' -o name)

# odf-operator-controller-manager
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l control-plane='controller-manager' -o name) -c manager

# rook-operator
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-operator' -o name)

# noobaa-operator
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='noobaa' -l noobaa-operator='deployment' -o name)

# rook-ceph-mgr
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mgr' -l instance='a' -o name) -c mgr

# rook-ceph-mon
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mon' -l mon='a' -o name) -c mon
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mon' -l mon='b' -o name) -c mon
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mon' -l mon='c' -o name) -c mon

# rook-ceph-mds
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mds' -l mds='ocs-storagecluster-cephfilesystem-a' -o name) -c mds
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mds' -l mds='ocs-storagecluster-cephfilesystem-b' -o name) -c mds

# rook-ceph-osd
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-osd' -l ceph-osd-id='0' -o name) -c osd
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-osd' -l ceph-osd-id='1' -o name) -c osd
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-osd' -l ceph-osd-id='2' -o name) -c osd
...

# rook-ceph-crashcollector
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-crashcollector' -o name | head -1)
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-crashcollector' -o name | head -2 | tail -1)
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-crashcollector' -o name | tail -1)

# rook-ceph-osd-prepare-ocs-deviceset-gp2
$ oc -n openshift-storage logs $(oc -n openshift-storage get jobs -l app='rook-ceph-osd-prepare' -l ceph.rook.io/DeviceSet='ocs-deviceset-gp2-0' -o name)
$ oc -n openshift-storage logs $(oc -n openshift-storage get jobs -l app='rook-ceph-osd-prepare' -l ceph.rook.io/DeviceSet='ocs-deviceset-gp2-1' -o name)
$ oc -n openshift-storage logs $(oc -n openshift-storage get jobs -l app='rook-ceph-osd-prepare' -l ceph.rook.io/DeviceSet='ocs-deviceset-gp2-2' -o name)

# odf-console
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='odf-console' -o name)

# ocs-metrics-exporter
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app.kubernetes.io/name='ocs-metrics-exporter' -o name)

# noobaa-core
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='noobaa' -l noobaa-core='noobaa' -o name)

# noobaa-endpoint
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='noobaa' -l noobaa-s3='noobaa' -o name)

# noobaa-db
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='noobaa' -l noobaa-db='postgres' -o name)

# csi-addons-controller-manager
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app.kubernetes.io/name='csi-addons' -o name)

# csi-cephfsplugin-provisioner
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c csi-provisioner
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c csi-attacher
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c csi-snapshotter
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c csi-resizer
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c csi-cephfsplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c liveness-prometheus

# csi-rbdplugin-provisioner
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c csi-provisioner
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c csi-attacher
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c csi-snapshotter
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c csi-resizer
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c csi-rbdplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c liveness-prometheus

# csi-cephfsplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin' -o name | head -1) -c driver-registrar
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin' -o name | head -1) -c csi-cephfsplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin' -o name | head -1) -c liveness-prometheus

# csi-rbdplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin' -o name | head -1) -c driver-registrar
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin' -o name | head -1) -c csi-rbdplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin' -o name | head -1) -c liveness-prometheus

$ oc get storagecluster -A 
NAMESPACE           NAME                 AGE   PHASE   EXTERNAL   CREATED AT             VERSION
openshift-storage   ocs-storagecluster   50m   Ready              2022-08-02T07:57:24Z   4.10.0

$ oc get storageclass
NAME                          PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
gp2 (default)                 kubernetes.io/aws-ebs                   Delete          WaitForFirstConsumer   true                   18h
gp2-csi                       ebs.csi.aws.com                         Delete          WaitForFirstConsumer   true                   18h
gp3-csi                       ebs.csi.aws.com                         Delete          WaitForFirstConsumer   true                   18h
ocs-storagecluster-ceph-rbd   openshift-storage.rbd.csi.ceph.com      Delete          Immediate              true                   44m
ocs-storagecluster-cephfs     openshift-storage.cephfs.csi.ceph.com   Delete          Immediate              true                   44m
openshift-storage.noobaa.io   openshift-storage.noobaa.io/obc         Delete          Immediate              false                  42m

# openshift-virtualization template 
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='virt-template-validator' -o name | head -1)

# kubevirt templates
# https://github.com/kubevirt/common-templates

```