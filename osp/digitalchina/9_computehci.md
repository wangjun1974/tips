# 删除已有的 overcloud
```
# 设置环境变量 THT
export THT=/usr/share/openstack-tripleo-heat-templates/

# 删除已有的 overcloud
(undercloud) [stack@undercloud ~]$ openstack stack delete overcloud --yes

# 等待删除完成
(undercloud) [stack@undercloud ~]$ watch -n5 'openstack stack resource list -n5 overcloud | grep -Ev COMP'

# 删除 plan 
(undercloud) [stack@undercloud ~]$ openstack overcloud plan delete overcloud

# 列出 role 
(undercloud) [stack@undercloud ~]$ openstack overcloud role list

# 重新生成 ~/templetes/roles_data.yaml 文件，包含 Controller, Compute, ComputeHCI 三个角色
(undercloud) [stack@undercloud ~]$ openstack overcloud roles generate -o ~/templates/roles_data.yaml Controller Compute ComputeHCI

# 重新生成 ~/rendered
(undercloud) [stack@undercloud ~]$ rm -rf ~/rendered
(undercloud) [stack@undercloud ~]$ mkdir ~/rendered

# 生成包含角色 nic config 的可定制环境文件
(undercloud) [stack@undercloud ~]$ cd $THT
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ tools/process-templates.py -r ~/templates/roles_data.yaml -n ~/templates/network_data.yaml -o ~/rendered

# 进入到 rendered 目录
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cd ~/rendered

# 拷贝 rendered/environments/network-environment.yaml 到 ~/templates/environments
(undercloud) [stack@undercloud rendered]$ cp environments/network-environment.yaml ~/templates/environments

# 重新拷贝 rendered/network 到 ~/templates
(undercloud) [stack@undercloud rendered]$ rm -rf ~/templates/network
(undercloud) [stack@undercloud rendered]$ cp -rp network ~/templates

# 拷贝 rendered/environments/net-bond-with-vlans.yaml 到 ~/templates/environments/
(undercloud) [stack@undercloud rendered]$ cp environments/net-bond-with-vlans.yaml ~/templates/environments/

# 根据需要修改 ~/templates/network/config//bond-with-vlans/controller.yaml 
# 根据需要修改 ~/templates/network/config//bond-with-vlans/compute.yaml
# 根据需要修改 ~/templates/network/config//bond-with-vlans/computehci.yaml

# 为 baremetal node 设置 properties capabilities
# 注意调整 role 和 index
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:controller-0,boot_option:local' overcloud-ctrl01
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:controller-1,boot_option:local' overcloud-ctrl02
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:controller-2,boot_option:local' overcloud-ctrl03

(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:compute-0,boot_option:local' overcloud-compute01
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:compute-1,boot_option:local' overcloud-compute02

(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:computehci-0,boot_option:local' overcloud-ceph01
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:computehci-1,boot_option:local' overcloud-ceph02
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:computehci-2,boot_option:local' overcloud-ceph03

# 重新生成 ~/templates/node-info.yaml
cat > ~/templates/node-info.yaml << 'EOF'
parameter_defaults:
  ControllerCount: 3
  ComputeCount: 2
  ComputeHCICount: 3

  # SchedulerHints
  ControllerSchedulerHints:
    'capabilities:node': 'controller-%index%'
  ComputeSchedulerHints:
    'capabilities:node': 'compute-%index%'
  ComputeHCISchedulerHints:
    'capabilities:node': 'computehci-%index%'
EOF


# 重新生成 ~/templates/environments/fixed-ips.yaml 
cat > ~/templates/environments/fixed-ips.yaml << EOF
# This template allows the IPs to be preselected for each VIP. Note that
# this template should be included after other templates which affect the
# network such as network-isolation.yaml.

resource_registry:
  OS::TripleO::Network::Ports::ExternalVipPort: ../network/ports/external.yaml
  OS::TripleO::Network::Ports::InternalApiVipPort: ../network/ports/internal_api.yaml
  OS::TripleO::Network::Ports::StorageVipPort: ../network/ports/storage.yaml
  OS::TripleO::Network::Ports::StorageMgmtVipPort: ../network/ports/storage_mgmt.yaml
  OS::TripleO::Network::Ports::RedisVipPort: ../network/ports/vip.yaml
  OS::TripleO::Network::Ports::OVNDBsVipPort: ../network/ports/vip.yaml

parameter_defaults:
  # Set the IP addresses of the VIPs here.
  # NOTE: we will eventually move to one VIP per service
  #
  ControlFixedIPs: [{'ip_address':'192.0.2.240'}]
  PublicVirtualFixedIPs: [{'ip_address':'192.168.122.40'}]
  InternalApiVirtualFixedIPs: [{'ip_address':'172.16.2.240'}]
  StorageVirtualFixedIPs: [{'ip_address':'172.16.1.240'}]
  StorageMgmtVirtualFixedIPs: [{'ip_address':'172.16.3.240'}]
  RedisVirtualFixedIPs: [{'ip_address':'172.16.2.241'}]
  OVNDBsVirtualFixedIPs: [{'ip_address':'172.16.2.242'}]

  ControllerIPs:
    ctlplane:
    - 192.0.2.51
    - 192.0.2.52
    - 192.0.2.53
    storage:
    - 172.16.1.51
    - 172.16.1.52
    - 172.16.1.53
    storage_mgmt:
    - 172.16.3.51
    - 172.16.3.52
    - 172.16.3.53
    internal_api:
    - 172.16.2.51
    - 172.16.2.52
    - 172.16.2.53
    tenant:
    - 172.16.0.51
    - 172.16.0.52
    - 172.16.0.53
    external:
    - 192.168.122.31
    - 192.168.122.32
    - 192.168.122.33

  ComputeIPs:
    ctlplane:
    - 192.0.2.61
    - 192.0.2.62
    storage:
    - 172.16.1.61
    - 172.16.1.62
    internal_api:
    - 172.16.2.61
    - 172.16.2.62
    tenant:
    - 172.16.0.61
    - 172.16.0.62

  ComputeHCIIPs:
    ctlplane:
    - 192.0.2.71
    - 192.0.2.72
    - 192.0.2.73
    storage:
    - 172.16.1.71
    - 172.16.1.72
    - 172.16.1.73
    storage_mgmt:
    - 172.16.3.71
    - 172.16.3.72
    - 172.16.3.73
    internal_api:
    - 172.16.2.71
    - 172.16.2.72
    - 172.16.2.73
    tenant:
    - 172.16.0.71
    - 172.16.0.72
    - 172.16.0.73
EOF

# 更新 ~/templates/environments/network-environment.yaml 的 dns 配置
(undercloud) [stack@undercloud ~]$ sed -i 's/  DnsServers: \[\]/  DnsServers: ["192.168.122.3"]/' ~/templates/environments/network-environment.yaml
(undercloud) [stack@undercloud ~]$ grep DnsServers ~/templates/environments/network-environment.yaml

# 继续延用 ~/deploy-enable-tls-octavia.sh
(undercloud) [stack@undercloud ~]$ cat > ~/deploy-enable-tls-octavia.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible.yaml \
-e $THT/environments/ceph-ansible/ceph-rgw.yaml \
-e $THT/environments/ssl/enable-internal-tls.yaml \
-e $THT/environments/ssl/tls-everywhere-endpoints-dns.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/fixed-ips.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e $THT/environments/services/octavia.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/custom-domain.yaml \
-e $CNF/node-info.yaml \
-e $CNF/enable-tls.yaml \
-e $CNF/inject-trust-anchor.yaml \
-e $CNF/keystone_domain_specific_ldap_backend.yaml \
-e $CNF/cephstorage.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF

# 部署 overcloud
(undercloud) [stack@undercloud ~]$ time /bin/bash ~/deploy-enable-tls-octavia.sh

# 完成部署
(overcloud) [stack@undercloud ~]$ openstack hypervisor list
+--------------------------------------+-------------------------------------+-----------------+-------------+-------+
| ID                                   | Hypervisor Hostname                 | Hypervisor Type | Host IP     | State |
+--------------------------------------+-------------------------------------+-----------------+-------------+-------+
| 8adbe348-3bae-496e-b356-7bc107e5068f | overcloud-novacompute-1.example.com | QEMU            | 172.16.2.62 | up    |
| 0332f73d-fb3b-4fd1-bd9c-37f4ec579696 | overcloud-computehci-1.example.com  | QEMU            | 172.16.2.72 | up    |
| 0cf22dcd-d3eb-4d6d-be66-664721bd317d | overcloud-novacompute-0.example.com | QEMU            | 172.16.2.61 | up    |
| d405a32b-e856-47c8-85c0-aa0b3adad152 | overcloud-computehci-2.example.com  | QEMU            | 172.16.2.73 | up    |
| f8317e9c-1298-4322-a17f-99294881ca30 | overcloud-computehci-0.example.com  | QEMU            | 172.16.2.71 | up    |
+--------------------------------------+-------------------------------------+-----------------+-------------+-------+
```