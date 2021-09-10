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

参考以下 diff 结果
--- controller.yaml     2021-09-10 13:52:08.379474221 +0800
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
@@ -236,10 +225,14 @@
                     get_param: BondInterfaceOvsOptions
                   members:
                   - type: interface
-                    name: ens4
+                    name: nic2
                     mtu:
                       get_attr: [MinViableMtu, value]
                     primary: true
+                  - type: interface
+                    name: nic3
+                    mtu:
+                      get_attr: [MinViableMtu, value]
                 - type: vlan
                   mtu:
                     get_param: StorageMtu
@@ -284,12 +277,20 @@
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



### 参考文档
https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/baremetal_overcloud.html