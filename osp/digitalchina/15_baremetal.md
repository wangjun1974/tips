## 如何在 overcloud 里设置 Baremetal as a Service

### 定义 overcloud baremetal provisioning 网络
```
# 定义 overcloud provisioning 虚拟网络
cat > /tmp/oc-provisioning.xml <<EOF
<network>
  <name>oc-provisioning</name>
  <ip address="192.0.3.254" netmask="255.255.255.0"/>
</network>
EOF

virsh net-define /tmp/oc-provisioning.xml
virsh net-autostart oc-provisioning
virsh net-start oc-provisioning

overcloud controller 需要有网卡连接这个网络
overcloud baremetal node 也需要有网卡连接这个网络


下面的步骤未执行 - 待验证
添加静态路由
ip -4 route add 192.0.2.0/24 via 192.0.2.254
ip -4 route add 192.0.3.0/24 via 192.0.3.254


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

### 配置 controller 的 nic-config
```
修改 templates/network/config/bond-with-vlans/controller 文件

添加 br-baremetal 部分
              - type: ovs_bridge
                name: br-baremetal
                use_dhcp: false
                members:
                - type: interface
                  name: ens5

参考以下 diff 结果，注意：ovs bond 不支持 slave，因此取消了 bond1
--- controller.yaml     2021-09-10 15:45:29.026938030 +0800
+++ controller.yaml.sav 2021-09-08 09:22:42.575230348 +0800
@@ -197,7 +197,7 @@
             $network_config:
               network_config:
               - type: interface
-                name: ens3
+                name: nic1
                 mtu:
                   get_param: ControlPlaneMtu
                 use_dhcp: false
@@ -216,22 +216,23 @@
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
@@ -276,12 +277,20 @@
                   routes:
                     list_concat_unique:
                       - get_param: TenantInterfaceRoutes
-              - type: ovs_bridge
-                name: br-baremetal
-                use_dhcp: false
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

openstack subnet create \
  --network provisioning \
  --subnet-range 192.0.3.0/24 \
  --ip-version 4 \
  --gateway 192.0.3.254 \
  --allocation-pool start=192.0.3.10,end=192.0.3.20 \
  --dhcp subnet-provisioning

创建 router
openstack router create router-provisioning

附加 subnet 到 router 
openstack router add subnet router-provisioning subnet-provisioning
```

### 配置 Overcloud Baremetal Node Cleaning 
```
添加如下内容到 templates/ironic.yaml
(overcloud) [stack@undercloud ~]$ cat >> templates/ironic.yaml <<EOF

  ############################
  #  Ironic Cleaning Network #
  ############################
  IronicCleaningNetwork: $(openstack network show provisioning -f value -c id)
EOF

重新执行 overcloud deploy 脚本 (未执行)
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
(overcloud) [stack@undercloud images]$ export DIB_LOCAL_IMAGE=rhel-8.4-x86_64-kvm.qcow2 

export DIB_YUM_REPO_CONF=/etc/yum.repos.d/backup/osp.repo

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

export DIB_YUM_REPO_CONF=/home/stack/images/local.repo

disk-image-create baremetal rhel -o rhel-image

参考链接
https://www.ibm.com/docs/zh-tw/urbancode-deploy/6.2.1?topic=coobc-using-dedicated-environment-create-chef-compatible-images-openstack-based-clouds
```

### 参考文档
https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/baremetal_overcloud.html

```
获取 token，然后创建实例
openstack --debug 的输出里有对应的调用例子
```