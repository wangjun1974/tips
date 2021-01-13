### 

```
# 生成部署模版目录 environments 目录
(undercloud) [stack@undercloud ~]$ mkdir -p ~/templates/environments


# 根据实际情况生成 node-info.yaml
# 本次部署有 3 种类型的节点，分别是 controller, compute 和 cephstorage
# 为每种类型填上对应的节点数量
cat > /home/stack/templates/node-info.yaml << 'EOF'
parameter_defaults:
  OvercloudControllerFlavor: baremetal
  OvercloudComputeFlavor: baremetal
  OvercloudCephStorageFlavor: baremetal
  ControllerCount: 3
  ComputeCount: 2
  CephStorageCount: 3

  # SchedulerHints
  ControllerSchedulerHints:
    'capabilities:node': 'controller-%index%'
  ComputeSchedulerHints:
    'capabilities:node': 'compute-%index%'
  CephStorageSchedulerHints:
    'capabilities:node': 'cephstorage-%index%'
EOF

# （可选）裸机部署不需要此设置
#  在嵌套虚拟化环境下，可通过此文件减少计算节点主机预留内存
cat > /home/stack/templates/fix-nova-reserved-host-memory.yaml << EOF
parameter_defaults:
  NovaReservedHostMemory: 1024
EOF
```


接下来配置网络部分
overcloud 网络<br>

这些网络根据实际情况调整

|名字|vlan|网段|备注说明|
|---|---|---|---|
|ControlPlane|无|192.0.2.0/24|部署网络|
|External|10|10.0.0.0/24|overcloud 的 External API 和 floating ip 所在的网络|
|InternalAPI|20|172.16.2.0/24||overcloud 的 Internal API 所在的网络|
|Tenant|50|172.16.0.0/24|overcloud 租户 overlay 隧道所在的网络|
|Storage|30|172.16.1.0/24|overcloud 存储网络，内部客户端通过此网络访问存储|
|StorageMgmt|40|172.16.3.0/24|overcloud 内部存储管理网络|
|Management|60|10.0.1.0/24|内部管理网络 - 默认未使用|

```
# 设置环境变量 THT
(undercloud) [stack@undercloud ~]$ THT=/usr/share/openstack-tripleo-heat-templates

# 拷贝默认的 roles_data.yaml 到 templetes 目录
(undercloud) [stack@undercloud ~]$ cp $THT/roles_data.yaml ~/templates

# 拷贝默认的 network_data.yaml 到 templates 目录
(undercloud) [stack@undercloud ~]$ cp $THT/network_data.yaml ~/templates

# 如果网络与 network_data.yaml 的内容不一样，可根据实际情况修改 network_data.yaml 文件
# 注意：
# 1. 只需要关注以下内部网络
# - name: Storage
# - name: StorageMgmt
# - name: InternalApi
# - name: Tenant
# - name: External
# 注意：
# 2. 网络包含以下内容
# 只需根据实际情况修改 vlan, ip_subnet, allocation_pools
- name: Storage
  vip: true
  vlan: 30
  name_lower: storage
  ip_subnet: '172.16.1.0/24'
  allocation_pools: [{'start': '172.16.1.4', 'end': '172.16.1.250'}]
  ipv6_subnet: 'fd00:fd00:fd00:3000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:3000::10', 'end': 'fd00:fd00:fd00:3000:ffff:ffff:ffff:fffe'}]
  mtu: 1500

# 对 External 来说还有 gateway_ip 可修改
- name: External
  vip: true
  name_lower: external
  vlan: 10
  ip_subnet: '10.0.0.0/24'
  allocation_pools: [{'start': '10.0.0.4', 'end': '10.0.0.250'}]
  gateway_ip: '10.0.0.1'
  ipv6_subnet: '2001:db8:fd00:1000::/64'
  ipv6_allocation_pools: [{'start': '2001:db8:fd00:1000::10', 'end': '2001:db8:fd00:1000:ffff:ffff:ffff:fffe'}]
  gateway_ipv6: '2001:db8:fd00:1000::1'
  mtu: 1500

```


接下来生成
```
(undercloud) [stack@undercloud ~]$ mkdir ~/rendered

# 生成包含角色 nic config 的可定制环境文件
(undercloud) [stack@undercloud ~]$ cd $THT
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ tools/process-templates.py -r ~/templates/roles_data.yaml -n ~/templates/network_data.yaml -o ~/rendered

# 进入到 rendered 目录，检查 environments/network-environment.yaml
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cd ~/rendered
(undercloud) [stack@undercloud rendered]$ cat environments/network-environment.yaml

# 拷贝 rendered/environments/network-environment.yaml 到 ~/templates/environments
(undercloud) [stack@undercloud rendered]$ cp environments/network-environment.yaml ~/templates/environments

# 拷贝 rendered/network 到 ~/templates
(undercloud) [stack@undercloud rendered]$ cp -rp network ~/templates

# 拷贝 rendered/environments/net-bond-with-vlans.yaml 到 ~/templates/environments/
# 注意：在 rendered/environments 里有很多其他模版
# 这些模版是用来描述不同场景下服务器网卡与 overcloud 内部网络的关系的
# 需根据实际情况来调整模版内容来反映网卡与 overcloud 内部网络的映射关系
(undercloud) [stack@undercloud rendered]$ cp environments/net-bond-with-vlans.yaml ~/templates/environments/

# 根据需要修改 ~/templates/network/config//bond-with-vlans/controller.yaml 
# 根据需要修改 ~/templates/network/config//bond-with-vlans/compute.yaml
# 根据需要修改 ~/templates/network/config//bond-with-vlans/ceph-storage.yaml

这个时候需要举例子

例1：服务器有三块网卡
网卡1 部署时使用，因此网卡映射 ControlPlane 
网卡2和网卡3 绑定在一起跑所有其他内部网络，希望用 linux bond 将两块网卡绑定起来，bond 模式为 active-backup

(undercloud) [stack@undercloud bond-with-vlans]$ cp controller.yaml controller.yaml.sav 
(undercloud) [stack@undercloud bond-with-vlans]$ diff -urN controller.yaml controller.yaml.sav
--- controller.yaml     2021-01-12 18:41:47.718270678 +0800
+++ controller.yaml.sav 2021-01-12 12:32:11.795270678 +0800
@@ -126,7 +126,7 @@
     description: IP address/subnet on the external network
     type: string
   ExternalNetworkVlanID:
-    default: 1
+    default: 10
     description: Vlan ID for the external network traffic.
     type: number
   ExternalMtu:
@@ -216,17 +216,6 @@
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
                 - type: ovs_bond
                   name: bond1
@@ -288,6 +277,20 @@
                   routes:
                     list_concat_unique:
                       - get_param: TenantInterfaceRoutes
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


(undercloud) [stack@undercloud bond-with-vlans]$ cp compute.yaml compute.yaml.sav 
(undercloud) [stack@undercloud bond-with-vlans]$ diff -urN compute.yaml compute.yaml.sav 
--- compute.yaml        2021-01-12 12:39:12.341270678 +0800
+++ compute.yaml.sav    2021-01-12 12:38:21.680270678 +0800
@@ -147,7 +147,7 @@
             $network_config:
               network_config:
               - type: interface
-                name: ens3
+                name: nic1
                 mtu:
                   get_param: ControlPlaneMtu
                 use_dhcp: false
@@ -178,12 +178,12 @@
                     get_param: BondInterfaceOvsOptions
                   members:
                   - type: interface
-                    name: ens4
+                    name: nic2
                     mtu:
                       get_attr: [MinViableMtu, value]
                     primary: true
                   - type: interface
-                    name: ens5
+                    name: nic3
                     mtu:
                       get_attr: [MinViableMtu, value]
                 - type: vlan

(undercloud) [stack@undercloud bond-with-vlans]$ cp ceph-storage.yaml ceph-storage.yaml.sav 
(undercloud) [stack@undercloud bond-with-vlans]$ diff -urN ceph-storage.yaml ceph-storage.yaml.sav 
--- ceph-storage.yaml   2021-01-12 12:39:45.422270678 +0800
+++ ceph-storage.yaml.sav       2021-01-12 12:39:18.687270678 +0800
@@ -124,7 +124,7 @@
             $network_config:
               network_config:
               - type: interface
-                name: ens3
+                name: nic1
                 mtu:
                   get_param: ControlPlaneMtu
                 use_dhcp: false
@@ -155,12 +155,12 @@
                     get_param: BondInterfaceOvsOptions
                   members:
                   - type: interface
-                    name: ens4
+                    name: nic2
                     mtu:
                       get_attr: [MinViableMtu, value]
                     primary: true
                   - type: interface
-                    name: ens5
+                    name: nic3
                     mtu:
                       get_attr: [MinViableMtu, value]
                 - type: vlan



```


生成 ~/templates/cephstorage.yaml 
```
# 注意这个文件的内容需根据 ceph 节点的磁盘实际情况修改 devices 部分
(undercloud) [stack@undercloud ~]$ cat > ~/templates/cephstorage.yaml << EOF
parameter_defaults:
  CephConfigOverrides:
    mon_max_pg_per_osd: 300
  CephAnsibleDisksConfig:
    devices:
      - /dev/vdb
      - /dev/vdc
      - /dev/vdd
    osd_scenario: lvm
    osd_objectstore: bluestore
EOF
```