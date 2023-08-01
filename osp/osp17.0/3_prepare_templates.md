### 

```
# 生成部署模版目录 environments 目录
(undercloud) [stack@undercloud ~]$ mkdir -p ~/templates/environments


# 根据实际情况生成 node-info.yaml
# 本次部署有 3 种类型的节点，分别是 controller, compute 和 cephstorage
# 为每种类型填上对应的节点数量
# 采用与 external ceph 集成的方式
# CephStorageCount 设置为 0
cat > /home/stack/templates/node-info.yaml << 'EOF'
parameter_defaults:
  ControllerCount: 3
  ComputeCount: 2
  CephStorageCount: 0

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

# 生成 ~/templates/cephstorage.yaml 文件
# external ceph cluster 集成 
cat > ~/templates/cephstorage.yaml <<EOF
parameter_defaults:
  CephConfigOverrides:
    mon_max_pg_per_osd: 600
  CephClientKey: AQBXFb5k87kYBBAAz+bzZ1emNKIGlVfhZD8XRw==
  CephClusterFSID: a906a9c8-29d3-11ee-b984-5254001a53cf
  CephExternalMonHost: 172.16.1.251
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
(undercloud) [stack@undercloud rendered]$ cd $THT

# 拷贝/usr/share/ansible/roles/tripleo_network_config/templates/* 到 ~/templates/
(undercloud) [stack@undercloud rendered]$ cp -r /usr/share/ansible/roles/tripleo_network_config/templates/* ~/templates/

# 执行 openstack overcloud cprovision - network provision
(undercloud) [stack@undercloud rendered]$ openstack overcloud network provision --output /home/stack/templates/overcloud-networks-deployed.yaml /home/stack/templates/network_data.yaml

# 执行 openstack overcloud network vip provision - network vip provision
(undercloud) [stack@undercloud rendered]$ cp /usr/share/openstack-tripleo-heat-templates/network-data-samples/vip-data-default-network-isolation.yaml /home/stack/templates/vip_data.yaml
(undercloud) [stack@undercloud rendered]$ openstack overcloud network vip provision --stack overcloud --output /home/stack/templates/overcloud-vip-deployed.yaml /home/stack/templates/vip_data.yaml

# 设置 baremetal node property capabilities boot_mode:bios
(undercloud) [stack@undercloud rendered]$ openstack baremetal node list -f value -c UUID| while read NODE; do openstack baremetal node set --property capabilities="boot_mode:bios,$(openstack baremetal node show $NODE -f json -c properties | jq -r .properties.capabilities | sed "s/boot_mode:[^,]*,//g")" $NODE;done

# 生成配置文件 /home/stack/templates/overcloud-baremetal-deploy.yaml
(undercloud) [stack@undercloud rendered]$ cat << EOF > /home/stack/templates/overcloud-baremetal-deploy.yaml
- name: Controller
  count: 3
  defaults:
    networks:
    - network: ctlplane
      vif: true
    - network: external
      subnet: external_subnet
    - network: internal_api
      subnet: internal_api_subnet
    - network: storage
      subnet: storage_subnet
    - network: storage_mgmt
      subnet: storage_mgmt_subnet
    - network: tenant
      subnet: tenant_subnet
    network_config:
      template: /home/stack/templates/bonds_vlans/bonds_vlans.j2
      bond_interface_ovs_options: bond_mode=active-backup
      default_route_network:
      - external
  instances:
  - hostname: overcloud-controller-0
    name: overcloud-ctrl01
  - hostname: overcloud-controller-1
    name: overcloud-ctrl02
  - hostname: overcloud-controller-2
    name: overcloud-ctrl03
- name: Compute
  count: 2
  defaults:
    networks:
    - network: ctlplane
      vif: true
    - network: internal_api
      subnet: internal_api_subnet
    - network: tenant
      subnet: tenant_subnet
    - network: storage
      subnet: storage_subnet
    network_config:
      template: /home/stack/templates/bonds_vlans/bonds_vlans.j2
      bond_interface_ovs_options: bond_mode=active-backup
  instances:
  - hostname: overcloud-novacompute-0
    name: overcloud-compute01
  - hostname: overcloud-novacompute-1
    name: overcloud-compute02
EOF

# 执行命令 openstack overcloud node provision - node provision
(undercloud) [stack@undercloud rendered]$ openstack overcloud node provision --stack overcloud --network-config --output /home/stack/templates/overcloud-baremetal-deployed.yaml /home/stack/templates/overcloud-baremetal-deploy.yaml

# 生成 /home/stack/templates/inject-trust-anchor-hiera.yaml
(undercloud) [stack@undercloud rendered]$ cat << EOF > /home/stack/templates/inject-trust-anchor-hiera.yaml
parameter_defaults:
  CAMap:
    undercloud-ca:
      content: |
$(awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' /etc/pki/ca-trust/source/anchors/cm-local-ca.pem |sed 's/^/        /g')
EOF

# 生成部署脚本
(undercloud) [stack@undercloud rendered]$ cat > ~/deploy.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/services/neutron-ovn-dvr-ha.yaml \
-e $THT/environments/external-ceph.yaml \
-e $CNF/cephstorage.yaml \
-e $CNF/overcloud-baremetal-deployed.yaml \
-e $CNF/overcloud-networks-deployed.yaml \
-e $CNF/overcloud-vip-deployed.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/inject-trust-anchor-hiera.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF

# 执行部署
(undercloud) [stack@undercloud rendered]$ /usr/bin/nohup /bin/bash -x deploy.sh &
(undercloud) [stack@undercloud rendered]$ tail -f nohup.out
```

