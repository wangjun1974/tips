### 杂项
Network Policy 生成工具<br>
https://editor.cilium.io/?id=en2dZle76uuVtRJo

OpenShift Project 定制<br>
https://developers.redhat.com/blog/2020/02/05/customizing-openshift-project-creation?ts=1632969031943#confirm_that_the_template_works

ChenChen 写的 Assisted Installer - OpenShift 文档<br>
https://github.com/cchen666/OpenShift-Labs/blob/main/Installation/Assisted-Installer.md

Quay.io
```
dig quay.io

quay.io. 42 IN A 52.22.41.62
quay.io. 42 IN A 34.224.196.162
quay.io. 42 IN A 52.0.232.252
quay.io. 42 IN A 3.216.152.103
quay.io. 42 IN A 3.214.183.120
quay.io. 42 IN A 50.16.140.223
quay.io. 42 IN A 3.213.173.170
quay.io. 42 IN A 3.233.133.41
```

```
清理 overcloud 节点
(overcloud) [stack@undercloud ~]$ for i in overcloud-ctrl01 overcloud-ctrl02 overcloud-ctrl03 overcloud-ceph01 overcloud-ceph02 overcloud-ceph03 overcloud-compute01 overcloud-compute02; do openstack baremetal node maintenance unset $i ; openstack baremetal node manage $i ; openstack baremetal node provide $i ; done
```