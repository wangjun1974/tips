### 

### 获取 overcloud images
```
# 以 undercloud stack 用户登录安装节点 undercloud
# 1.1 创建 images 目录 和 templates/environments 目录
(undercloud) [stack@undercloud ~]$ mkdir ~/images
(undercloud) [stack@undercloud ~]$ mkdir -p ~/templates/environments

# 1.2 安装 rhosp-director-images
# rhosp-director-images 包含 introspection 会用到的镜像
(undercloud) [stack@undercloud ~]$ sudo yum -y install rhosp-director-images

# 1.3 解压缩 overcloud-full-latest.tar
(undercloud) [stack@undercloud ~]$ tar -C ~/images -xvf /usr/share/rhosp-director-images/overcloud-full-latest.tar

# 1.4 解压缩 ironic-python-agent-latest.tar
(undercloud) [stack@undercloud ~]$ tar -C ~/images -xvf /usr/share/rhosp-director-images/ironic-python-agent-latest.tar

# 1.5 上传镜像到 undercloud 镜像服务
(undercloud) [stack@undercloud ~]$ openstack overcloud image upload --image-path ~/images

# 2.1 查看 overcloud 相关的镜像已上传到 undercloud registry
(undercloud) [stack@undercloud ~]$ openstack image list

# 2.2 查看 ironic 相关的 kernel 和 agent 以及 introspection 的 启动配置文件
# 这些文件用于 introspection 阶段远程系统启动及信息收集
(undercloud) [stack@undercloud ~]$ ls -al /var/lib/ironic/httpboot/
total 558748
drwxr-xr-x. 2 42422 42422        86 Jan 11 15:07 .
drwxr-xr-x. 4 42422 42422        38 Jan  9 21:59 ..
-rwxr-xr-x. 1 root  root    8924528 Jan 11 15:07 agent.kernel
-rw-r--r--. 1 root  root  563222736 Jan 11 15:07 agent.ramdisk
-rw-r--r--. 1 42422 42422       758 Jan  9 23:07 boot.ipxe
-rw-r--r--. 1 42422 42422       365 Jan  9 22:48 inspector.ipxe

# 3.1 查看 undercloud registry 的镜像信息
(undercloud) [stack@undercloud ~]$ curl -s -H "Accept: application/json" http://192.0.2.1:8787/v2/_catalog | jq .
{
  "repositories": [
    "rhosp-rhel8/openstack-ironic-neutron-agent",
    "rhosp-rhel8/openstack-memcached",
    "rhosp-rhel8/openstack-nova-conductor",
    "rhosp-rhel8/openstack-ironic-conductor",
    "rhosp-rhel8/openstack-swift-proxy-server",
    "rhosp-rhel8/openstack-qdrouterd",
    "rhosp-rhel8/openstack-heat-engine",
    "rhosp-rhel8/openstack-neutron-dhcp-agent",
    "rhosp-rhel8/openstack-swift-object",
    "rhosp-rhel8/openstack-zaqar-wsgi",
    "rhosp-rhel8/openstack-nova-scheduler",
    "rhosp-rhel8/openstack-nova-compute-ironic",
    "rhosp-rhel8/openstack-heat-api",
    "rhosp-rhel8/openstack-mistral-api",
    "rhosp-rhel8/openstack-mariadb",
    "rhosp-rhel8/openstack-keepalived",
    "rhosp-rhel8/openstack-mistral-engine",
    "rhosp-rhel8/openstack-iscsid",
    "rhosp-rhel8/openstack-neutron-openvswitch-agent",
    "rhosp-rhel8/openstack-placement-api",
    "rhosp-rhel8/openstack-glance-api",
    "rhosp-rhel8/openstack-ironic-inspector",
    "rhosp-rhel8/openstack-rabbitmq",
    "rhosp-rhel8/openstack-haproxy",
    "rhosp-rhel8/openstack-mistral-executor",
    "rhosp-rhel8/openstack-rsyslog",
    "rhosp-rhel8/openstack-mistral-event-engine",
    "rhosp-rhel8/openstack-neutron-l3-agent",
    "rhosp-rhel8/openstack-cron",  
    "rhosp-rhel8/openstack-nova-api",
    "rhosp-rhel8/openstack-ironic-api",
    "rhosp-rhel8/openstack-ironic-pxe",
    "rhosp-rhel8/openstack-swift-container",
    "rhosp-rhel8/openstack-swift-account",
    "rhosp-rhel8/openstack-keystone",
    "rhosp-rhel8/openstack-neutron-server"
  ]
}

# 3.2 查看 undercloud registry 是否已准备好 overcloud container images
(undercloud) [stack@undercloud ~]$ grep Completed /var/log/tripleo-container-image-prepare.log
2021-01-09 22:30:43,815 20210 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-ironic-neutron-agent:16.1] 
Completed upload for image
2021-01-09 22:30:44,124 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-memcached:16.1] Completed u
pload for image
2021-01-09 22:30:46,933 20212 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-ironic-conductor:16.1] Comp
leted upload for image
2021-01-09 22:30:48,049 20209 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-nova-conductor:16.1] Comple
ted upload for image
2021-01-09 22:30:59,481 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-qdrouterd:16.1] Completed u
pload for image
2021-01-09 22:31:20,277 20212 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-heat-engine:16.1] Complete 
 upload for image
2021-01-09 22:31:21,340 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-swift-object:16.1] Complete
d upload for image
2021-01-09 22:31:25,233 20209 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-neutron-dhcp-agent:16.1] Co
mpleted upload for image
2021-01-09 22:31:30,330 20210 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-swift-proxy-server:16.1] Co
mpleted upload for image
2021-01-09 22:31:41,835 20212 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-zaqar-wsgi:16.1] Completed 
upload for image
2021-01-09 22:31:47,899 20210 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-heat-api:16.1] Completed up
load for image
2021-01-09 22:32:01,287 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-nova-scheduler:16.1] Comple
ted upload for image
2021-01-09 22:32:49,520 20212 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-mistral-api:16.1] Complete 
 upload for image
2021-01-09 22:32:52,018 20210 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-mariadb:16.1] Completed upl
oad for image
2021-01-09 22:33:05,639 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-keepalived:16.1] Completed
upload for image
2021-01-09 22:33:06,125 20210 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-iscsid:16.1] Completed uplo
ad for image
2021-01-09 22:33:06,922 20212 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-mistral-engine:16.1] Comple
ted upload for image
2021-01-09 22:33:24,272 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-neutron-openvswitch-agent:1
6.1] Completed upload for image
2021-01-09 22:33:46,105 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-ironic-inspector:16.1] Comp
leted upload for image
2021-01-09 22:33:57,855 20210 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-placement-api:16.1] Complet
ed upload for image
2021-01-09 22:34:43,562 20210 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-haproxy:16.1] Completed upl
oad for image
2021-01-09 22:34:46,529 20209 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-nova-compute-ironic:16.1] C
ompleted upload for image
2021-01-09 22:34:48,259 20212 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-glance-api:16.1] Completed
upload for image
2021-01-09 22:34:54,716 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-rabbitmq:16.1] Completed up
load for image
2021-01-09 22:35:02,203 20209 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-rsyslog:16.1] Completed upl
oad for image
2021-01-09 22:35:07,941 20212 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-mistral-event-engine:16.1]
Completed upload for image
2021-01-09 22:35:13,312 20209 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-cron:16.1] Completed upload
 for image
2021-01-09 22:35:36,531 20209 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-ironic-api:16.1] Completed
upload for image
2021-01-09 22:35:37,130 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-neutron-l3-agent:16.1] Comp
leted upload for image
2021-01-09 22:35:41,004 20212 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-nova-api:16.1] Completed up
load for image
2021-01-09 22:35:53,109 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-swift-container:16.1] Compl
eted upload for image
2021-01-09 22:35:56,025 20212 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-swift-account:16.1] Complet
ed upload for image
2021-01-09 22:36:00,813 20209 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-ironic-pxe:16.1] Completed
upload for image
2021-01-09 22:36:06,215 20210 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-mistral-executor:16.1] Comp
leted upload for image
2021-01-09 22:36:14,502 20216 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-keystone:16.1] Completed up
load for image
2021-01-09 22:36:20,864 20212 INFO tripleo_common.image.image_uploader [  ] [registry.redhat.io/rhosp-rhel8/openstack-neutron-server:16.1] Comple
ted upload for image

# 4 注册节点到 undercloud
# 4.1 生成控制节点 instackenv-ctrl.json
# 需要首先记录节点 provision 网络的 mac 地址
# IPMI 地址，类型，用户名和口令
# 然后以如下格式添加到 instackenv-ctrl.json 中
  "nodes": [
    {
      "mac": [
        "52:54:00:78:2b:e8"
      ],
      "name": "overcloud-ctrl01",
      "pm_addr": "192.168.1.1",
      "pm_port": "6234",
      "pm_password": "password",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },

# 在虚拟化环境下可通过类似如下的命令获取 mac 地址
virsh domiflist jwang-overcloud-ctrl01 | grep provisioning | awk '{print $5}' 
virsh domiflist jwang-overcloud-ctrl02 | grep provisioning | awk '{print $5}' 
virsh domiflist jwang-overcloud-ctrl03 | grep provisioning | awk '{print $5}' 

# 在虚拟化环境下查看 IPMI 地址
vbmc list

# 根据收集到的信息生成 instackenv-ctrl.json
cat > instackenv-ctrl.json << EOF
{
  "nodes": [
    {
      "mac": [
        "52:54:00:78:2b:e8"
      ],
      "name": "overcloud-ctrl01",
      "pm_addr": "192.168.1.6",
      "pm_port": "623",
      "pm_password": "redhat",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },
    {
      "mac": [
        "52:54:00:b7:c6:e9"
      ],
      "name": "overcloud-ctrl02",
      "pm_addr": "192.168.1.7",
      "pm_port": "623",
      "pm_password": "redhat",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },    
    {
      "mac": [
        "52:54:00:c9:f0:65"
      ],
      "name": "overcloud-ctrl03",
      "pm_addr": "192.168.1.8",
      "pm_port": "623",
      "pm_password": "redhat",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    }
  ]
}
EOF

# 检查文件是否有语法错误
(undercloud) [stack@undercloud ~]$ openstack overcloud node import --validate-only ~/instackenv-ctrl.json
Successfully validated environment file

# 导入控制节点并且 introspect 控制节点
(undercloud) [stack@undercloud ~]$ openstack overcloud node import --introspect --provide instackenv-ctrl.json

# 列出 baremetal node 状态
# 节点 Power State 应为 power off
# 节点 Provisioning State 应为 available
# 节点 Maintenance 应为 available
(undercloud) [stack@undercloud ~]$ openstack baremetal node list

# introspect 失败
# 在虚拟化环境下之前定义的虚拟机与主机 CPU 特性不兼容
# 在 libvirtd 日志中存在如下报错
# Jan 11 18:28:18 base-pvg.redhat.ren libvirtd[25283]: 2021-01-11 10:28:18.110+0000: 25288: error : virCPUx86Compare:1785 : the CPU is incompatible with host CPU: Host CPU does not provide required features: xsave, avx
# 1.Open virt-manager
# 2.Go to parameters of VM
# 3.Go to cpu section
# 4.Check "Copy host CPU configuration" and click Apply

# 出错后重新 introspect 所有 Provisioning State 状态为 manageable 的节点
(undercloud) [stack@undercloud ~]$ openstack overcloud node introspect --all-manageable --provide

# 在虚拟化环境下可通过类似如下的命令获取计算节点 mac 地址
virsh domiflist jwang-overcloud-compute01 | grep provisioning | awk '{print $5}' 
virsh domiflist jwang-overcloud-compute02 | grep provisioning | awk '{print $5}' 

# 在虚拟化环境下查看计算节点 IPMI 地址
vbmc list

# 根据收集到的信息生成 instackenv-ctrl.json
cat > instackenv-compute.json << EOF
{
  "nodes": [
    {
      "mac": [
        "52:54:00:10:84:ab"
      ],
      "name": "overcloud-compute01",
      "pm_addr": "192.168.1.4",
      "pm_port": "623",
      "pm_password": "redhat",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },
    {
      "mac": [
        "52:54:00:ca:d7:a3"
      ],
      "name": "overcloud-compute02",
      "pm_addr": "192.168.1.5",
      "pm_port": "623",
      "pm_password": "redhat",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    }
  ]
}
EOF

# 检查文件是否有语法错误
(undercloud) [stack@undercloud ~]$ openstack overcloud node import --validate-only ~/instackenv-compute.json

# 导入计算节点并且 introspect 计算节点
(undercloud) [stack@undercloud ~]$ openstack overcloud node import --introspect --provide instackenv-compute.json

# 在虚拟化环境下可通过类似如下的命令获取 ceph 节点 mac 地址
virsh domiflist jwang-overcloud-ceph01 | grep provisioning | awk '{print $5}' 
virsh domiflist jwang-overcloud-ceph02 | grep provisioning | awk '{print $5}' 
virsh domiflist jwang-overcloud-ceph03 | grep provisioning | awk '{print $5}' 

# 在虚拟化环境下查看计算节点 IPMI 地址
vbmc list

# 根据收集到的信息生成 instackenv-ceph.json
cat > instackenv-ceph.json << EOF
{
  "nodes": [
    {
      "mac": [
        "52:54:00:78:2f:e3"
      ],
      "name": "overcloud-ceph01",
      "pm_addr": "192.168.1.1",
      "pm_port": "623",
      "pm_password": "redhat",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },
    {
      "mac": [
        "52:54:00:e9:9f:4b"
      ],
      "name": "overcloud-ceph02",
      "pm_addr": "192.168.1.2",
      "pm_port": "623",
      "pm_password": "redhat",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },
        {
      "mac": [
        "52:54:00:29:18:c9"
      ],
      "name": "overcloud-ceph03",
      "pm_addr": "192.168.1.3",
      "pm_port": "623",
      "pm_password": "redhat",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    }
  ]
}
EOF

# 检查文件是否有语法错误
(undercloud) [stack@undercloud ~]$ openstack overcloud node import --validate-only ~/instackenv-ceph.json

# 导入 ceph 节点并且 introspect ceph 节点
(undercloud) [stack@undercloud ~]$ openstack overcloud node import --introspect --provide instackenv-ceph.json
Waiting for messages on queue 'tripleo' with no timeout.
3 node(s) successfully moved to the "manageable" state.
Successfully registered node UUID 0426ba65-4058-4543-94fe-4bf66b6c1011
Successfully registered node UUID ee9377d7-bb1b-48cd-abdf-d27309fbdcc8
Successfully registered node UUID d3cb0d59-09de-4364-a14e-3698cf0cc593
Waiting for introspection to finish...
Waiting for messages on queue 'tripleo' with no timeout.
Introspection of node completed:ee9377d7-bb1b-48cd-abdf-d27309fbdcc8. Status:SUCCESS. Errors:None
Introspection of node completed:0426ba65-4058-4543-94fe-4bf66b6c1011. Status:SUCCESS. Errors:None
Introspection of node completed:d3cb0d59-09de-4364-a14e-3698cf0cc593. Status:SUCCESS. Errors:None
Successfully introspected 3 node(s).
Waiting for messages on queue 'tripleo' with no timeout.
3 node(s) successfully moved to the "available" state.

# 确认所有节点已成功完成 introspection
# 字段 Started at 非空
# 字段 Finished at 非空
# 字段 Error 为 None 
(undercloud) [stack@undercloud ~]$ openstack baremetal introspection list

# 列出 baremetal node 列表
# 节点 Power State 应为 power off
# 节点 Provisioning State 应为 available
# 节点 Maintenance 应为 False
(undercloud) [stack@undercloud ~]$ openstack baremetal node list
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+
| UUID                                 | Name                | Instance UUID | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+
| 9fcbe99e-a871-4b21-a691-da3c0b1579a8 | overcloud-ctrl01    | None          | power off   | available          | False       |
| e29a1f26-8da0-4ea4-b8f1-d519bcca809c | overcloud-ctrl02    | None          | power off   | available          | False       |
| 5e1d3c77-0c4a-4585-8dc4-52c257214454 | overcloud-ctrl03    | None          | power off   | available          | False       |
| 9d8e3e89-edb5-4757-86bf-b96eb3896666 | overcloud-compute01 | None          | power off   | available          | False       |
| 4a3e168a-5248-4862-be6a-2a84f6265c19 | overcloud-compute02 | None          | power off   | available          | False       |
| 0426ba65-4058-4543-94fe-4bf66b6c1011 | overcloud-ceph01    | None          | power off   | available          | False       |
| ee9377d7-bb1b-48cd-abdf-d27309fbdcc8 | overcloud-ceph02    | None          | power off   | available          | False       |
| d3cb0d59-09de-4364-a14e-3698cf0cc593 | overcloud-ceph03    | None          | power off   | available          | False       |
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+

# 显示 baremetal node 详情
(undercloud) [stack@undercloud ~]$ openstack baremetal node show overcloud-ctrl01

# 保存 introspection 信息
# 从 introspection 信息可查询到网卡和磁盘相关信息
(undercloud) [stack@undercloud ~]$ mkdir -p introspection
(undercloud) [stack@undercloud ~]$ pushd introspection
(undercloud) [stack@undercloud ~]$ for i in $(openstack baremetal node list -f value -c Name); do openstack baremetal introspection data save $i > $i.json ; done
(undercloud) [stack@undercloud ~]$ pushd
```

```
# undercloud 重启后，如果 introspection 无法正常执行
# 可以检查系统上是否有其他 dnsmasq 服务造成 tripleo_ironic_inspector_dnsmasq.service 服务无法正常启动
(undercloud) [stack@undercloud ~]$ sudo systemctl disable libvirtd
(undercloud) [stack@undercloud ~]$ sudo systemctl stop libvirtd-ro.socket
(undercloud) [stack@undercloud ~]$ sudo systemctl stop libvirtd.socket
(undercloud) [stack@undercloud ~]$ sudo systemctl stop libvirtd-admin.socket
(undercloud) [stack@undercloud ~]$ sudo systemctl stop libvirtd 
(undercloud) [stack@undercloud ~]$ sudo ps ax | grep dnsmasq 
# kill 掉 libvirtd 对应的 dnsmasq
# 重启 tripleo_ironic_inspector_dnsmasq.service 服务
(undercloud) [stack@undercloud ~]$ sudo systemctl restart tripleo_ironic_inspector_dnsmasq.service


https://access.redhat.com/solutions/5464941
Stderr: 'iscsiadm: Cannot perform discovery. Invalid Initiatorname.\niscsiadm: Could not perform SendTargets discovery: invalid parameter\n'
https://bugzilla.redhat.com/show_bug.cgi?id=1764187
https://gitlab.cee.redhat.com/rhci-documentation/docs-Red_Hat_Enterprise_Linux_OpenStack_Platform/-/commit/652e8c538c34337af521e3636ff5478ad7ff122b


[root@undercloud ~]# systemctl -l | grep tripleo_iscsi
tripleo_iscsid.service loaded failed     failed          iscsid container                               tripleo_iscsid_healthcheck.timer loaded failed     failed          iscsid container healthcheck

[root@undercloud ~]# sudo iptables -I INPUT 8 -p tcp -m multiport --dports 3260 -m state --state NEW -m comment --comment "100 iscsid ipv4" -j ACCEPT

[root@undercloud ~]# systemctl restart tripleo_iscsid.service

[root@undercloud ~]# podman logs iscsid
...
+ exec /usr/sbin/iscsid -f
iscsid: Can not bind IPC socket

https://bugzilla.redhat.com/show_bug.cgi?id=1642582

systemctl stop iscsid.socket
systemctl disable iscsid.socket
systemctl disable iscsid
systemctl stop iscsid

```