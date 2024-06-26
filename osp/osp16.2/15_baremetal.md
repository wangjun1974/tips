## 如何在 overcloud 里设置 Baremetal as a Service

### 定义 overcloud baremetal provisioning 网络
```
# 定义 overcloud provisioning 虚拟网络
cat > /tmp/oc-provisioning.xml <<EOF
<network>
  <name>oc-provisioning</name>
  <ip address="172.16.4.254" netmask="255.255.255.0"/>
</network>
EOF

virsh net-define /tmp/oc-provisioning.xml
virsh net-autostart oc-provisioning
virsh net-start oc-provisioning

overcloud controller 需要有网卡连接这个网络
overcloud baremetal node 也需要有网卡连接这个网络

需要配置 provisioning 网络和 oc-provisioning 网络间的路由
WIP: 一个可以考虑的方向是用 zebra 实现
参考：https://github.com/wangjun1974/tips/blob/master/os/miscs.md#%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE%E8%B7%AF%E7%94%B1%E8%BD%AF%E4%BB%B6-zebra

另外一个可以考虑的实现方式是定义 oc_provisioning 网络
参考文档：3.2.1. Configuring a custom IPv4 provisioning network
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html-single/bare_metal_provisioning/index
```

### 检查 overcloud 节点连接 overcloud baremetal provisioning 网络
```
控制节点
controller0 - nic2 - oc-provisioning
controller1 - nic2 - oc-provisioning
controller2 - nic2 - oc-provisioning

Baremetal 节点
baremetal node1 - nic2 - oc-provisioning
```

### 定制 network_data.yaml 
```

拷贝 network_data.yaml 文件并且备份
cd templates
cp /usr/share/openstack-tripleo-heat-templates/network_data.yaml .
cp network_data.yaml network_data.yaml.sav

编辑 network_data.yaml 文件，添加以下内容
- name: OcProvisioning
  # custom network for overcloud provisioning
  enabled: true
  vip: true
  name_lower: oc_provisioning
  vlan: 70
  ip_subnet: '172.16.4.0/24'
  allocation_pools: [{'start': '172.16.4.10', 'end': '172.16.4.20'}]
  gateway_ipv6: 'fd00:fd00:fd00:7000::1'
  ipv6_subnet: 'fd00:fd00:fd00:7000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:7000::10', 'end': 'fd00:fd00:fd00:7000:ffff:ffff:ffff:fffe'}]

修改前后的文件内容对比
(undercloud) [stack@undercloud templates]$ diff -urN network_data.yaml.sav network_data.yaml
--- network_data.yaml.sav       2021-09-16 11:15:05.237873642 +0800
+++ network_data.yaml   2021-09-16 11:20:19.916059817 +0800
@@ -146,3 +146,15 @@
   ipv6_subnet: 'fd00:fd00:fd00:6000::/64'
   ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:6000::10', 'end': 'fd00:fd00:fd00:6000:ffff:ffff:ffff:fffe'}]
   mtu: 1500
+- name: OcProvisioning
+  # custom network for overcloud provisioning
+  enabled: true
+  vip: true
+  name_lower: oc_provisioning
+  ip_subnet: '172.16.4.0/24'
+  allocation_pools: [{'start': '172.16.4.10', 'end': '172.16.4.20'}]
+  gateway_ipv6: 'fd00:fd00:fd00:7000::1'
+  ipv6_subnet: 'fd00:fd00:fd00:7000::/64'
+  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:7000::10', 'end': 'fd00:fd00:fd00:7000:ffff:ffff:ffff:fffe'}]
+  mtu: 1500
```

### 编辑 roles_data.yaml 
```
拷贝并且编辑 roles_data.yaml 文件
在 Controller 的 Network 里添加
    OcProvisioning:
      subnet: oc_provisioning_subnet

(undercloud) [stack@undercloud templates]$ diff -urN roles_data.yaml.sav roles_data.yaml 
--- roles_data.yaml.sav 2021-09-16 12:12:57.138927699 +0800
+++ roles_data.yaml     2021-09-16 12:13:33.817949400 +0800
@@ -23,6 +23,8 @@
       subnet: storage_mgmt_subnet
     Tenant:
       subnet: tenant_subnet
+    OcProvisioning:
+      subnet: oc_provisioning_subnet
   # For systems with both IPv4 and IPv6, you may specify a gateway network for
   # each, such as ['ControlPlane', 'External']
   default_route_networks: ['External']
```

### 配置 controller 的 nic-config
```
修改 templates/network/config/bond-with-vlans/controller 文件

添加 br-baremetal 部分
              - type: ovs_bridge
                name: br-baremetal
                use_dhcp: false
                mtu:
                  get_param: OcProvisioningMtu
                addresses:
                - ip_netmask:
                    get_param: OcProvisioningIpSubnet
                members:
                - type: interface
                  name: ens5


参考以下 diff 结果，注意：ovs bond 不支持 slave，因此取消了 bond1
--- controller.yaml     2021-09-16 12:26:53.192422325 +0800
+++ controller.yaml.sav 2021-09-16 12:21:31.236231851 +0800
@@ -220,7 +220,7 @@
             $network_config:
               network_config:
               - type: interface
-                name: ens3
+                name: nic1
                 mtu:
                   get_param: ControlPlaneMtu
                 use_dhcp: false
@@ -239,22 +239,23 @@
                   get_param: DnsServers
                 domain:
                   get_param: DnsSearchDomains
-                mtu:
-                  get_param: ExternalMtu
-                addresses:
-                - ip_netmask:
-                    get_param: ExternalIpSubnet
-                routes:
-                  list_concat_unique:
-                    - get_param: ExternalInterfaceRoutes
-                    - - default: true
-                        next_hop:
-                          get_param: ExternalInterfaceDefaultRoute
                 members:
-                - type: interface
-                  name: ens4
+                - type: ovs_bond
+                  name: bond1
                   mtu:
                     get_attr: [MinViableMtu, value]
+                  ovs_options:
+                    get_param: BondInterfaceOvsOptions
+                  members:
+                  - type: interface
+                    name: nic2
+                    mtu:
+                      get_attr: [MinViableMtu, value]
+                    primary: true
+                  - type: interface
+                    name: nic3
+                    mtu:
+                      get_attr: [MinViableMtu, value]
                 - type: vlan
                   mtu:
                     get_param: StorageMtu
@@ -299,17 +300,31 @@
                   routes:
                     list_concat_unique:
                       - get_param: TenantInterfaceRoutes
-              - type: ovs_bridge
-                name: br-baremetal
-                use_dhcp: false
-                mtu:
-                  get_param: OcProvisioningMtu
-                addresses:
-                - ip_netmask:
-                    get_param: OcProvisioningIpSubnet
-                members:
-                - type: interface
-                  name: ens5
+                - type: vlan
+                  mtu:
+                    get_param: ExternalMtu
+                  vlan_id:
+                    get_param: ExternalNetworkVlanID
+                  addresses:
+                  - ip_netmask:
+                      get_param: ExternalIpSubnet
+                  routes:
+                    list_concat_unique:
+                      - get_param: ExternalInterfaceRoutes
+                      - - default: true
+                          next_hop:
+                            get_param: ExternalInterfaceDefaultRoute
+                - type: vlan
+                  mtu:
+                    get_param: OcProvisioningMtu
+                  vlan_id:
+                    get_param: OcProvisioningNetworkVlanID
+                  addresses:
+                  - ip_netmask:
+                      get_param: OcProvisioningIpSubnet
+                  routes:
+                    list_concat_unique:
+                      - get_param: OcProvisioningInterfaceRoutes
 outputs:
   OS::stack_id:
     description: The OsNetConfigImpl resource.

```

### 修改 templates/environment/network-environments.yaml 文件
```
添加以下内容

  ############################
  #  Neutron configuration   #
  ############################
  NeutronBridgeMappings: "datacentre:br-ex,baremetal:br-baremetal"
  NeutronFlatNetworks: datacentre,baremetal

  ServiceNetMap:
    IronicApiNetwork: oc_provisioning
    IronicNetwork: oc_provisioning
    IronicInspectorNetwork: oc_provisioning
```

### 生成 templates/ironic.yaml 文件
```
cat > templates/ironic.yaml <<EOF
parameter_defaults:
  ############################
  #  Scheduler configuration #
  ############################
  NovaSchedulerDefaultFilters:
    - "RetryFilter"
    - "AvailabilityZoneFilter"
    - "ComputeFilter"
    - "ComputeCapabilitiesFilter"
    - "ImagePropertiesFilter"
    - "ServerGroupAntiAffinityFilter"
    - "ServerGroupAffinityFilter"
    - "PciPassthroughFilter"
    - "NUMATopologyFilter"
    - "AggregateInstanceExtraSpecsFilter"

  ############################
  #  Ironic Cleaning Method  #
  ############################
  IronicCleaningDiskErase: metadata
EOF
```

### 生成部署脚本
```
cat > deploy-ironic-overcloud.sh <<'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e $THT/environments/services/ironic-overcloud.yaml \
-e $THT/environments/services/ironic-inspector.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/node-info.yaml \
-e $CNF/ironic.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF
```

### 安装完成后检查 overcloud controller 的 /var/lib/ironic 目录
```

overcloud 
[heat-admin@overcloud-controller-0 ~]$ sudo ls /var/lib/ironic/
httpboot  tftpboot
[heat-admin@overcloud-controller-0 ~]$ sudo ls /var/lib/ironic/httpboot/
boot.ipxe

```

### 配置 overcloud 部署网络
```
source overcloudrc

创建部署网络
openstack network create \
  --provider-network-type flat \
  --provider-physical-network baremetal \
  --share provisioning

根据当前的实现，overcloud baremetal provisioning network/subnet 需要路由可达 overcloud ironic 的 api，overcloud ironic api 默认在 undercloud provisioning network 上，也就是 overcloud 的部署网络上。

openstack subnet create \
  --network provisioning \
  --subnet-range 172.16.4.0/24 \
  --ip-version 4 \
  --gateway 172.16.4.250 \
  --allocation-pool start=172.16.4.30,end=172.16.4.40 \
  --dhcp subnet-provisioning

创建 router
openstack router create router-provisioning

附加 subnet 到 router 
openstack router add subnet router-provisioning subnet-provisioning
```

### 配置 Overcloud Baremetal Node Cleaning 和 Ironic Inspector Subnet 
```
查看控制节点 inspector.ipxe 文件内容
[heat-admin@overcloud-controller-0 ~]$ cat /var/lib/ironic/httpboot/inspector.ipxe 
#!ipxe

:retry_boot
imgfree
kernel --timeout 60000 http://172.16.4.18:8088/agent.kernel ipa-inspection-callback-url=http://172.16.4.18:5050/v1/continue ipa-inspection-collectors=default,logs systemd.journald.forward_to_console=yes BOOTIF=${mac} ipa-inspection-dhcp-all-interfaces=1 ipa-collect-lldp=1 ipa-debug=1 initrd=agent.ramdisk || goto retry_boot
initrd --timeout 60000 http://172.16.4.18:8088/agent.ramdisk || goto retry_boot
boot

根据实际情况配置以下参数
IronicInspectorSubnets

IPAImageURLs: agent.kernel 和 agent.ramdisk 的获取地址，可填写 undercloud ControlPlane 的地址，部署过程中，在 step_3 会执行命令 'curl -g -o file-xxx1 url-yyy1 -o file-xxx2 url-yyy2 ' 从这个 URLs 获取 agent.kernel 和 agent.ramdisk 

IronicInspectorInterface

(overcloud) [stack@undercloud ~]$ cat >> templates/ironic.yaml <<EOF

  ############################
  #  Ironic Cleaning Network #
  ############################
  IronicCleaningNetwork: $(openstack network show provisioning -f value -c id)

  ############################
  #  Ironic Inspector Subnet #
  ############################  
  IronicInspectorSubnets:
    - ip_range: 172.16.4.110,172.16.4.120
  IPAImageURLs: '["http://192.0.2.1:8088/agent.kernel", "http://192.0.2.1:8088/agent.ramdisk"]'
  IronicInspectorInterface: 'br-baremetal'  
EOF

重新执行 overcloud deploy 脚本，这个步骤必须执行
```

### 创建 baremetal flavor
```
source ~/overcloudrc
openstack flavor list
openstack flavor create \
  --id auto --ram 4096 \
  --vcpus 1 --disk 40 \
  --property baremetal=true \
  --public baremetal

https://www.cnblogs.com/jmilkfan-fanguiju/p/11825059.html
注意：以下设置是必须的
openstack flavor set --property resources:CUSTOM_BAREMETAL=1 baremetal
openstack flavor set --property resources:VCPU=0 baremetal
openstack flavor set --property resources:MEMORY_MB=0 baremetal
openstack flavor set --property resources:DISK_GB=0 baremetal  
```

### 创建 virtual flavor 和 image
```
source ~/overcloudrc
openstack flavor create \
  --id auto --ram 64 \
  --vcpus 1 --disk 1 \
  --property baremetal=false \
  --public m1.nano

curl -L -O http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

openstack image create cirros --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare

openstack keypair create --public-key ~/.ssh/id_rsa.pub key1
```

### 创建 baremetal image
```
上传 deploy image

$ source overcloudrc

$ openstack image create \
  --container-format aki \
  --disk-format aki \
  --public \
  --file /var/lib/ironic/httpboot/agent.kernel bm-deploy-kernel

$ openstack image create \
  --container-format ari \
  --disk-format ari \
  --public \
  --file /var/lib/ironic/httpboot/agent.ramdisk bm-deploy-ramdisk

上传 user image
(overcloud) [stack@undercloud ~]$ cd images/
(overcloud) [stack@undercloud images]$ export DIB_LOCAL_IMAGE="rhel-8.2-x86_64-kvm.qcow2"

我的使用的环境是 osp 16.1 undercloud，操作系统是 rhel 8.2，软件仓库是 rhel 8.2 eus
因此使用的镜像是 rhel-8.2-x86_64-kvm.qcow2。
注意：软件仓库和镜像需要版本一致，才能避免依赖关系冲突问题

cat > local.repo <<EOF
[rhel-8-for-x86_64-baseos-eus-rpms]
name=rhel-8-for-x86_64-baseos-eus-rpms
baseurl=http://192.168.8.21:8787/repos/osp16.1/rhel-8-for-x86_64-baseos-eus-rpms/
enabled=1
gpgcheck=0

[rhel-8-for-x86_64-appstream-eus-rpms]
name=rhel-8-for-x86_64-appstream-eus-rpms
baseurl=http://192.168.8.21:8787/repos/osp16.1/rhel-8-for-x86_64-appstream-eus-rpms/
enabled=1
gpgcheck=0
EOF

export DIB_YUM_REPO_CONF="/home/stack/images/local.repo"
export DIB_LOCAL_IMAGE="rhel-8.2-x86_64-kvm.qcow2"
export DIB_RELEASE="8"
(overcloud) [stack@undercloud images]$ disk-image-create rhel baremetal -o rhel-image
...
2021-09-14 07:18:17.612 | INFO diskimage_builder.block_device.blockdevice [-] Getting value for [image-path]
2021-09-14 07:18:18.762 | INFO diskimage_builder.block_device.level3.mount [-] Called for [mount_mkfs_root]
2021-09-14 07:18:18.762 | INFO diskimage_builder.block_device.utils [-] Calling [sudo sync]
2021-09-14 07:18:18.854 | INFO diskimage_builder.block_device.utils [-] Calling [sudo fstrim --verbose /tmp/dib_build.AemYdmS5/mnt
/]
2021-09-14 07:18:18.980 | INFO diskimage_builder.block_device.utils [-] Calling [sudo umount /tmp/dib_build.AemYdmS5/mnt/]
2021-09-14 07:18:19.907 | INFO diskimage_builder.block_device.level0.localloop [-] loopdev detach
2021-09-14 07:18:19.907 | INFO diskimage_builder.block_device.utils [-] Calling [sudo losetup -d /dev/loop0]
2021-09-14 07:18:21.374 | INFO diskimage_builder.block_device.blockdevice [-] Removing temporary state dir [/tmp/dib_build.AemYdmS5/states/block-device]
2021-09-14 07:18:21.778 | Converting image using qemu-img convert
2021-09-14 07:21:12.524 | Image file rhel-image.qcow2 created...
2021-09-14 07:21:13.150 | Build completed successfully

(overcloud) [stack@undercloud images]$ ls -ltr
...
-rw-rw-r--. 1 stack stack        366 Sep 10 21:34 local.repo
-rw-r--r--. 1 root  root  1159135232 Sep 14 14:51 rhel-8.2-x86_64-kvm.qcow2
drwxrwxr-x. 3 stack stack         27 Sep 14 15:17 rhel-image.d
-rwxr-xr-x. 1 root  root     8924528 Sep 14 15:17 rhel-image.vmlinuz          <== baremetal image kernel
-rw-r--r--. 1 root  root    53965501 Sep 14 15:17 rhel-image.initrd           <== baremetal image initrd
-rw-r--r--. 1 stack stack  801494528 Sep 14 15:21 rhel-image.qcow2            <== baremetal whole user disk image


(overcloud) [stack@undercloud images]$ cat rhel-image.d/dib-manifests/dib_arguments 
rhel baremetal -o rhel-image

(overcloud) [stack@undercloud images]$ cat rhel-image.d/dib-manifests/dib_environment 
declare -x DIB_ARGS="rhel baremetal -o rhel-image"
declare -x DIB_LOCAL_IMAGE="rhel-8.2-x86_64-kvm.qcow2"
declare -x DIB_PYTHON_EXEC="/usr/libexec/platform-python"
declare -x DIB_RELEASE="8"
declare -x DIB_YUM_REPO_CONF="/home/stack/images/local.repo"


上传镜像
(overcloud) [stack@undercloud images]$ KERNEL_ID=$(openstack image create \
  --file rhel-image.vmlinuz --public \
  --container-format aki --disk-format aki \
  -f value -c id rhel-image.vmlinuz)
(overcloud) [stack@undercloud images]$ RAMDISK_ID=$(openstack image create \
  --file rhel-image.initrd --public \
  --container-format ari --disk-format ari \
  -f value -c id rhel-image.initrd)
(overcloud) [stack@undercloud images]$ openstack image create \
  --file rhel-image.qcow2   --public \
  --container-format bare \
  --disk-format qcow2 \
  --property kernel_id=$KERNEL_ID \
  --property ramdisk_id=$RAMDISK_ID \
  rhel-image
```

### 注册 baremetal 节点
```
文档里的 5.5 部分可以省略
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.2-beta/html/bare_metal_provisioning/configuring-the-bare-metal-provisioning-service-after-deployment#configuring-deploy-interfaces_bare-metal-post-deployment

生成节点的注册文件，这个节点对应 undercloud 的 overcloud-compute02
(overcloud) [stack@undercloud ~]$ cat instackenv-compute.json 
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

注意，在 overcloud 里注册节点时用的部署网卡和 undercloud 不同

cat > overcloud-nodes.yaml << EOF
nodes:
    - name: baremetal-node0
      driver: ipmi
      driver_info:
        ipmi_address: 192.168.1.5
        ipmi_port: "623"
        ipmi_username: admin
        ipmi_password: redhat
      properties:
        cpus: 4
        memory_mb: 12288
        local_gb: 40
      ports:
        - address: "52:54:00:a1:b7:7a"
EOF
```

### 生成 baremetal 节点
```
(overcloud) [stack@undercloud ~]$ openstack baremetal create overcloud-nodes.yaml
(overcloud) [stack@undercloud ~]$ openstack baremetal node list
+--------------------------------------+-----------------+---------------+-------------+--------------------+-------------+
| UUID                                 | Name            | Instance UUID | Power State | Provisioning State | Maintenance |
+--------------------------------------+-----------------+---------------+-------------+--------------------+-------------+
| cd01b1c5-d63b-4967-921f-f9fcc0322652 | baremetal-node0 | None          | None        | enroll             | False       |
+--------------------------------------+-----------------+---------------+-------------+--------------------+-------------+

5.6.4 设定 baremetal 节点对应的 deploy kernel 和 deploy initrd
(overcloud) [stack@undercloud ~]$ openstack baremetal node set $(openstack baremetal node show baremetal-node0 -f value -c uuid) \
  --driver-info deploy_kernel=$(openstack image show bm-deploy-kernel -f value -c id) \
  --driver-info deploy_ramdisk=$(openstack image show bm-deploy-ramdisk -f value -c id)

(overcloud) [stack@undercloud ~]$ openstack baremetal node show $(openstack baremetal node show baremetal-node0 -f value -c uuid) -f json | jq -r '.driver_info'

5.6.5 设定 baremetal 节点的 Provisioning State 为 managable
(overcloud) [stack@undercloud ~]$ openstack baremetal node manage $(openstack baremetal node show baremetal-node0 -f value -c uuid)

6.7.2 introspecting baremetal 节点
(overcloud) [stack@undercloud ~]$ openstack baremetal introspection start --wait $(openstack baremetal node show baremetal-node0 -f value -c uuid)

5.6.5 设定 baremetal 节点的 Provisioning State 为 available
(overcloud) [stack@undercloud ~]$ openstack baremetal node provide $(openstack baremetal node show baremetal-node0 -f value -c uuid)

获取 baremetal-node0 的 introspection 信息
(overcloud) [stack@undercloud ~]$ mkdir -p overcloud-introspection
(overcloud) [stack@undercloud ~]$ cd overcloud-introspection
(overcloud) [stack@undercloud overcloud-introspection]$ openstack baremetal introspection data save $(openstack baremetal node show baremetal-node0 -f value -c uuid) > $(openstack baremetal node show baremetal-node0 -f value -c uuid).json
(overcloud) [stack@undercloud overcloud-introspection]$ cd ~
(overcloud) [stack@undercloud ~]$ 

5.6.6 设置 baremetal 节点的 property capabilities boot_option 为 local
(overcloud) [stack@undercloud ~]$ openstack baremetal node set $(openstack baremetal node show baremetal-node0 -f value -c uuid) --property capabilities="boot_option:local"

5.7.3 创建主机组 baremetal-hosts
(overcloud) [stack@undercloud ~]$ openstack aggregate create --property baremetal=true baremetal-hosts

5.7.4 添加控制节点到主机组 baremetal-hosts
(overcloud) [stack@undercloud ~]$ openstack aggregate add host baremetal-hosts overcloud-controller-0.localdomain

5.7.5 创建主机组 virtual-hosts
(overcloud) [stack@undercloud ~]$ openstack aggregate create --property baremetal=false virtual-hosts

5.7.6 添加计算节点到主机组 virtual-hosts
(overcloud) [stack@undercloud ~]$ openstack aggregate add host virtual-hosts overcloud-novacompute-0.localdomain

手工设置 baremetal 节点的 resource-class 并且设置 resource provider inventory
(overcloud) [stack@undercloud ~]$ openstack baremetal node set $(openstack baremetal node show baremetal-node0 -f value -c uuid) --resource-class baremetal
(overcloud) [stack@undercloud ~]$ openstack resource provider inventory set --resource VCPU=4 --resource MEMORY_MB=6144 --resource DISK_GB=99 --resource CUSTOM_BAREMETAL=1 $(openstack baremetal node show baremetal-node0 -f value -c uuid)

查看 resource provider inventory
openstack resource provider inventory list $(openstack baremetal node show baremetal-node0 -f value -c uuid)

检查 resource provider
https://access.redhat.com/solutions/3537351
(overcloud) [stack@undercloud ~]$ source overcloudrc
(overcloud) [stack@undercloud ~]$ openstack resource provider list | awk '{print $2}' | egrep -v 'uuid|^$' | while read rp; do echo "=== $rp ==="; openstack resource provider show $rp ; openstack resource provider usage show $rp ; openstack resource provider inventory list --os-placement-api-version 1.2 $rp ;done
```

### 启动实例
```
6.1.1 启动裸金属实例
date -u ; openstack server create \
  --nic net-id=$(openstack network show provisioning -f value -c id) \
  --flavor baremetal \
  --image $(openstack image show rhel-image -f value -c id) \
  baremetal-instance-1

查看实例和 baremetal 
watch -n10 'openstack server list ; openstack baremetal node list'

启动虚拟机实例，如果希望 virtual-instance-1 能与 baremetal-instance-1 能通信，需要为 Compute 角色添加网络 oc_provisioning，并且配置 配置 compute 的 nic-config，详情参考: 配置 controller 的 nic-config
date -u ; openstack server create \
  --key-name key1 \
  --nic net-id=$(openstack network show provisioning -f value -c id) \
  --flavor m1.nano \
  --image $(openstack image show cirros -f value -c id) \
  virtual-instance-1
```

查看 baremetal node 详细信息
```
(overcloud) [stack@undercloud ~]$ openstack baremetal node show baremetal-node0 -f json | jq . 
{
  "allocation_uuid": null,
  "automated_clean": null,
  "bios_interface": "no-bios",
  "boot_interface": "ipxe",
  "chassis_uuid": null,
  "clean_step": {},
  "conductor": "overcloud-controller-0.localdomain",
  "conductor_group": "",
  "console_enabled": false,
  "console_interface": "ipmitool-socat",
  "created_at": "2021-09-16T06:07:10+00:00",
  "deploy_interface": "iscsi",
  "deploy_step": {},
  "description": null,
  "driver": "ipmi",
  "driver_info": {
    "ipmi_address": "192.168.1.5",
    "ipmi_port": "623",
    "ipmi_username": "admin",
    "ipmi_password": "******",
    "deploy_kernel": "486599e1-c0b0-4e06-b3a5-7bfbae426089",
    "deploy_ramdisk": "a0f71886-4edb-4a79-9d5d-fd72df06ea1c"
  },
  "driver_internal_info": {
    "agent_erase_devices_iterations": 1,
    "agent_erase_devices_zeroize": true,
    "agent_continue_if_ata_erase_failed": false,
    "agent_enable_ata_secure_erase": true,
    "disk_erasure_concurrency": 1,
    "last_power_state_change": "2021-09-17T02:54:08.479314",
    "agent_version": "5.0.4.dev8",
    "agent_last_heartbeat": "2021-09-17T02:54:02.884983",
    "hardware_manager_version": {
      "generic_hardware_manager": "1.1"
    },
    "agent_cached_clean_steps": {
      "deploy": [
        {
          "step": "erase_devices",
          "priority": 10,
          "interface": "deploy",
          "reboot_requested": false,
          "abortable": true
        },
        {
          "step": "erase_devices_metadata",
          "priority": 99,
          "interface": "deploy",
          "reboot_requested": false,
          "abortable": true
        }
      ],
      "raid": [
        {
          "step": "delete_configuration",
          "priority": 0,
          "interface": "raid",
          "reboot_requested": false,
          "abortable": true
        },
        {
          "step": "create_configuration",
          "priority": 0,
          "interface": "raid",
          "reboot_requested": false,
          "abortable": true
        }
      ]
    },
    "agent_cached_clean_steps_refreshed": "2021-09-17 02:54:01.108246",
    "clean_steps": null
  },
  "extra": {},
  "fault": null,
  "inspect_interface": "inspector",
  "inspection_finished_at": null,
  "inspection_started_at": null,
  "instance_info": {},
  "instance_uuid": null,
  "last_error": null,
  "maintenance": false,
  "maintenance_reason": null,
  "management_interface": "ipmitool",
  "name": "baremetal-node0",
  "network_interface": "flat",
  "owner": null,
  "power_interface": "ipmitool",
  "power_state": "power off",
  "properties": {
    "cpus": "4",
    "memory_mb": "6144",
    "local_gb": "99",
    "capabilities": "boot_option:local,cpu_vt:true,cpu_aes:true,cpu_hugepages:true",
    "cpu_arch": "x86_64"
  },
  "protected": false,
  "protected_reason": null,
  "provision_state": "available",
  "provision_updated_at": "2021-09-17T02:54:33+00:00",
  "raid_config": {},
  "raid_interface": "no-raid",
  "rescue_interface": "agent",
  "reservation": null,
  "resource_class": null,
  "storage_interface": "noop",
  "target_power_state": null,
  "target_provision_state": null,
  "target_raid_config": {},
  "traits": [],
  "updated_at": "2021-09-17T02:54:33+00:00",
  "uuid": "70e90b26-afa6-4274-b52d-26ee9c199d29",
  "vendor_interface": "ipmitool"
}
```

### 参考文档
https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/baremetal_overcloud.html<br>
https://www.cnblogs.com/jmilkfan-fanguiju/p/11825059.html<br>
https://access.redhat.com/solutions/3537351<br>
https://docs.openstack.org/ironic/pike/install/configure-tenant-networks.html#configure-tenant-networks<br>
https://docs.openshift.com/container-platform/4.8/installing/installing_openstack/installing-openstack-installer-custom.html#installation-osp-deploying-bare-metal-machines_installing-openstack-installer-custom<br>
https://www.cnblogs.com/zhangyufei/p/8473306.html<br>
https://zhuanlan.zhihu.com/p/59639444<br>
https://wiki.openstack.org/wiki/Neutron/ML2/MechCiscoNexus#Neutron_ML2_Driver_For_Cisco_Nexus_Devices
