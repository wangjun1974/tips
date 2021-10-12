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
osp 16.2: 在 undercloud 删除 stack 之后，overcloud 节点未被删除
执行以下命令清理 overcloud 节点
(undercloud) [stack@undercloud ~]$ for i in overcloud-ctrl01 overcloud-ctrl02 overcloud-ctrl03 overcloud-ceph01 overcloud-ceph02 overcloud-ceph03 overcloud-compute01 overcloud-compute02; do openstack baremetal node clean $i --clean-steps '[{"interface": "deploy", "step": "erase_devices_metadata"}]' ; openstack baremetal node manage $i ; openstack baremetal node provide $i ; done

(undercloud) [stack@undercloud ~]$ for i in overcloud-ctrl01 overcloud-ctrl02 overcloud-ctrl03 overcloud-ceph01 overcloud-ceph02 overcloud-ceph03 overcloud-compute01 overcloud-compute02; do openstack baremetal node maintenance unset $i ; openstack baremetal node manage $i ; openstack baremetal node provide $i ; done

查看 osp 16.2 安装日志
(undercloud) [stack@undercloud ~]$ sudo cat /var/lib/mistral/overcloud/ansible.log | grep -E 'TASK:' | cut -d '|' -f 2- | awk '!x[$0]++' | tail -10

(undercloud) [stack@undercloud ~]$ watch -n10 'sudo cat -n /var/lib/mistral/overcloud/ansible.log | grep -E "TASK:" | cut -d "|" -f 2- | cat -n | sort -uk2 | sort -n | cut -f2- | tail -10' 
https://stackoverflow.com/questions/11532157/remove-duplicate-lines-without-sorting

查看 osp16.2 ceph-ansible 安装日志
(undercloud) [stack@undercloud ~]$ watch -n10 'sudo cat -n /var/lib/mistral/overcloud/ceph-ansible/ceph_ansible_command.log | grep -E "TASK" | cut -d "|" -f 2- | cat -n | sort -uk2 | sort -n | cut -f2- | tail -10'

```

### 问题解决：更新 Mac OS 之后，git 命令报错
```
[junwang@JundeMacBook-Pro ~]$ git status
xcrun: error: invalid active developer path (/Library/Developer/CommandLineTools), missing xcrun at: /Library/Developer/CommandLineTools/usr/bin/xcrun

解决方法是重新安装开发工具 xcode-select
xcode-select --install
```

### Huawei CCE PV/PVC/StorageClass
https://support.huaweicloud.com/basics-cce/kubernetes_0030.html

### openstack vxlan 层次化端口绑定 ML2: Hierarchical Port Binding¶
https://bbs.huaweicloud.com/blogs/detail/148362<br>
https://specs.openstack.org/openstack/neutron-specs/specs/kilo/ml2-hierarchical-port-binding.html<br>

### osp 16.2 deployment failed.
```
pcs status
...
  * rabbitmq_start_0 on rabbitmq-bundle-1 'error' (1): call=2853, status='Timed Out', exitreason='', last-rc-change='2021-10-12 00:43:33Z', queued=0ms, exec=200033ms

pcs resource show rabbitmq-bundle
...
  Resource: rabbitmq (class=ocf provider=heartbeat type=rabbitmq-cluster)
   Attributes: set_policy="ha-all ^(?!amq\.).* {"ha-mode":"exactly","ha-params":2,"ha-promote-on-shutdown":"always"}"
   Meta Attrs: container-attribute-target=host notify=true
   Operations: monitor interval=10s timeout=40s (rabbitmq-monitor-interval-10s)
               start interval=0s timeout=200s (rabbitmq-start-interval-0s)
               stop interval=0s timeout=200s (rabbitmq-stop-interval-0s)

更新 resource rabbitmq 的 op start timeout
pcs resource update rabbitmq op start interval=0s timeout=400s
pcs resource update rabbitmq op monitor interval=10s timeout=120s

```

### osp 16.1 keystone oidc 的例子
https://gitlab.cee.redhat.com/sputhenp/lab/-/tree/master/templates/osp-16-1/oidc-federation

```
(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph -s 
Warning: Permanently added 'overcloud-controller-0.ctlplane' (ECDSA) to the list of known hosts.
  cluster:
    id:     ea9612e6-e9fd-4897-891f-77df9acd94e8
    health: HEALTH_WARN
            mons are allowing insecure global_id reclaim
```

### osp 16.2 tripleo ipa 
在 osp 16.2 里，推荐的 ipa 集成方式不再是 novajoin 而是 tls-e ansible<br>
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.2/html/advanced_overcloud_customization/sect-tripleo-ipa<br>

### OpenShift Container Storage Planning
https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.7/pdf/planning_your_deployment/red_hat_openshift_container_storage-4.7-planning_your_deployment-en-us.pdf<br>
