### 配置 ovsdpdksriov 
```
# 设置 ComputeOvsDpdkSriov 节点 BIOS
# 参考 https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html/network_functions_virtualization_planning_and_configuration_guide/ch-hardware-requirements#bios_settings

# 部署 RHOSP 使用 OVS mechanism driver
# 修改 containers-prepare-parameter.yaml, 设置 neutron_driver 参数为 null
# 参考: https://github.com/wangjun1974/ospinstall/blob/main/containers-prepare-parameter.yaml.example.md
parameter_defaults:
  ContainerImagePrepare:
  - push_destination: true
    set:
      neutron_driver: null

# 生成 ComputeOvsDpdkSriov 角色
mkdir -p ~/templates
openstack overcloud roles generate -o ~/templates/roles_data_dpdksriov.yaml Controller ComputeOvsDpdkSriov

# 将 ComputeOvsDpdkSriov 角色的内容添加到 ~/templates/roles_data.yaml 文件中
(undercloud) [stack@dell-per730-02 ovs-dpdk]$ cat templates/roles_data.yaml | grep ComputeOvsDpdkSriov -A60 -B1
###############################################################################
# Role: ComputeOvsDpdkSriov                                                   #
###############################################################################
- name: ComputeOvsDpdkSriov
  description: |
    Compute role with OvS-DPDK and SR-IOV services
  CountDefault: 1
  networks:
    - InternalApi
    - Tenant
    - Storage
  RoleParametersDefault:
    VhostuserSocketGroup: "hugetlbfs"
    TunedProfileName: "cpu-partitioning"
    NovaLibvirtRxQueueSize: 1024
    NovaLibvirtTxQueueSize: 1024
  update_serial: 25
  ServicesDefault:
    - OS::TripleO::Services::Aide
    - OS::TripleO::Services::AuditD
    - OS::TripleO::Services::BootParams
    - OS::TripleO::Services::CACerts
    - OS::TripleO::Services::CephClient
    - OS::TripleO::Services::CephExternal
    - OS::TripleO::Services::CertmongerUser
    - OS::TripleO::Services::Collectd
    - OS::TripleO::Services::ComputeCeilometerAgent
    - OS::TripleO::Services::ComputeNeutronCorePlugin
    - OS::TripleO::Services::ComputeNeutronL3Agent
    - OS::TripleO::Services::ComputeNeutronMetadataAgent
    - OS::TripleO::Services::ComputeNeutronOvsDpdk
    - OS::TripleO::Services::Docker
    - OS::TripleO::Services::IpaClient
    - OS::TripleO::Services::Ipsec
    - OS::TripleO::Services::Iscsid
    - OS::TripleO::Services::Kernel
    - OS::TripleO::Services::LoginDefs
    - OS::TripleO::Services::MetricsQdr
    - OS::TripleO::Services::Multipathd
    - OS::TripleO::Services::MySQLClient
    - OS::TripleO::Services::NeutronBgpVpnBagpipe
    - OS::TripleO::Services::NeutronSriovAgent
    - OS::TripleO::Services::NeutronSriovHostConfig
    - OS::TripleO::Services::NovaAZConfig
    - OS::TripleO::Services::NovaCompute
    - OS::TripleO::Services::NovaLibvirt
    - OS::TripleO::Services::NovaLibvirtGuests
    - OS::TripleO::Services::NovaMigrationTarget
    - OS::TripleO::Services::ContainersLogrotateCrond
    - OS::TripleO::Services::OVNController
    - OS::TripleO::Services::OVNMetadataAgent
    - OS::TripleO::Services::OvsDpdkNetcontrold
    - OS::TripleO::Services::Rhsm
    - OS::TripleO::Services::Rsyslog
    - OS::TripleO::Services::RsyslogSidecar
    - OS::TripleO::Services::Securetty
    - OS::TripleO::Services::Snmp
    - OS::TripleO::Services::Sshd
    - OS::TripleO::Services::Timesync
    - OS::TripleO::Services::Timezone
    - OS::TripleO::Services::TripleoFirewall
    - OS::TripleO::Services::TripleoPackages
    - OS::TripleO::Services::Podman
    - OS::TripleO::Services::Ptp

# 生成 ComputeDpdkSriov 节点 nic-configs
# computedpdksriov.yaml 从已有的 compute.yaml 文件拷贝
# 然后根据网卡所承载的部署网络，内部网络，dpdk 网络和 sriov 网络定制修改 computedpdksriov.yaml 文件
(undercloud) [stack@dell-per730-02 ovs-dpdk]$ cat templates/nic-configs/computedpdksriov.yaml
...
resources:
  OsNetConfigImpl:
    type: OS::Heat::SoftwareConfig
    properties:
      group: script
      config:
        str_replace:
          template:
            get_file: /usr/share/openstack-tripleo-heat-templates/network/scripts/run-os-net-config.sh
          params:
            $network_config:
              network_config:
              - type: interface
                name: eno2
                mtu:
                  get_param: ControlPlaneMtu
                use_dhcp: false
                dns_servers:
                  get_param: DnsServers
                domain:
                  get_param: DnsSearchDomains
                addresses:
                - ip_netmask:
                    list_join:
                    - /
                    - - get_param: ControlPlaneIp
                      - get_param: ControlPlaneSubnetCidr
 
              - type: interface
                name: eno1
                use_dhcp: false

              - type: vlan
                device: eno4
                use_dhcp: false
                mtu:
                  get_param: StorageMtu
                vlan_id:
                  get_param: StorageNetworkVlanID
                addresses:
                - ip_netmask:
                    get_param: StorageIpSubnet
 
              - type: vlan
                use_dhcp: false
                device: eno4
                mtu:
                  get_param: InternalApiMtu
                vlan_id:
                  get_param: InternalApiNetworkVlanID
                addresses:
                - ip_netmask:
                    get_param: InternalApiIpSubnet   

              - type: ovs_user_bridge
                name: br-dpdk0
                use_dhcp: false
                ovs_extra:
                 - str_replace:
                     template: set port br-dpdk0 tag=_VLAN_TAG_
                     params:
                       _VLAN_TAG_:
                         get_param: TenantNetworkVlanID
                addresses:
                 - ip_netmask:
                     get_param: TenantIpSubnet
                members:
                - type: ovs_dpdk_port
                  name: br-dpdk0-dpdk-port0
                  rx_queue: 1
                  members:
                  - type: interface
                    name: enp130s0f0

              - type: sriov_pf
                name: enp130s0f1
                use_dhcp: false
                numvfs: 8
                defroute: false
                nm_controlled: true
                hotplug: true
                promisc: false

# 生成 ComputeDpdkSriov Nic Partitioning 节点 nic-configs
# computedpdksriov.yaml 从已有的 compute.yaml 文件拷贝
# 然后根据网卡所承载的部署网络，内部网络，dpdk 网络和 sriov 网络定制修改 computedpdksriov.yaml 文件
# 参考：https://blueprints.launchpad.net/tripleo/+spec/sriov-vfs-as-network-interface
(undercloud) [stack@dell-per730-02 ovs-dpdk]$ cat templates/nic-configs/computedpdksriov.yaml
...
resources:
  OsNetConfigImpl:
    type: OS::Heat::SoftwareConfig
    properties:
      group: script
      config:
        str_replace:
          template:
            get_file: /usr/share/openstack-tripleo-heat-templates/network/scripts/run-os-net-config.sh
          params:
            $network_config:
              network_config:
              - type: interface
                name: eno2
                mtu:
                  get_param: ControlPlaneMtu
                use_dhcp: false
                dns_servers:
                  get_param: DnsServers
                domain:
                  get_param: DnsSearchDomains
                addresses:
                - ip_netmask:
                    list_join:
                    - /
                    - - get_param: ControlPlaneIp
                      - get_param: ControlPlaneSubnetCidr
 
              - type: interface
                name: eno1
                use_dhcp: false

              - type: vlan
                device: eno4
                use_dhcp: false
                mtu:
                  get_param: StorageMtu
                vlan_id:
                  get_param: StorageNetworkVlanID
                addresses:
                - ip_netmask:
                    get_param: StorageIpSubnet
 
              - type: vlan
                use_dhcp: false
                device: eno4
                mtu:
                  get_param: InternalApiMtu
                vlan_id:
                  get_param: InternalApiNetworkVlanID
                addresses:
                - ip_netmask:
                    get_param: InternalApiIpSubnet   

              - type: sriov_pf
                name: enp130s0f0
                use_dhcp: false
                numvfs: 8
                defroute: false
                nm_controlled: true
                hotplug: true
                promisc: false

              - type: ovs_user_bridge
                name: br-dpdk0
                use_dhcp: false
                ovs_extra:
                 - str_replace:
                     template: set port br-dpdk0 tag=_VLAN_TAG_
                     params:
                       _VLAN_TAG_:
                         get_param: TenantNetworkVlanID
                addresses:
                 - ip_netmask:
                     get_param: TenantIpSubnet
                members:
                - type: ovs_dpdk_port
                  name: br-dpdk0-dpdk-port0
                  rx_queue: 1
                  members:
                  - type: sriov_vf
                    device: enp130s0f0
                    vfid: 0


https://freesoft.dev/program/156193590

在计算节点上测试网络配置
os-net-config /etc/os-net-config/config.json --debug

https://github.com/Mellanox/k8s-rdma-sriov-dev-plugin/issues/21
https://bugzilla.redhat.com/show_bug.cgi?id=1762691

在 overcloud 计算节点上，这个程序完成 sriov 相关配置
/usr/lib/python3.6/site-packages/os_net_config/sriov_config.py

对于报错
ip link set dev enp130s0f0 vf 0 max_tx_rate 0
RTNETLINK answers: Invalid argument

编辑 /usr/lib/python3.6/site-packages/os_net_config/sriov_config.py 文件，不执行 min_tx_rate 和 max_tx_rate 的设置
 

如何通过 ip link 命令或者 sysfs 设置 min_tx_rate 和 max_tx_rate
https://community.mellanox.com/s/article/HowTo-Configure-Rate-Limit-per-VF-for-ConnectX-4-ConnectX-5-ConnectX-6


# 修改 network-environments.yaml 文件
# 在 resource_registry 段添加 OS::TripleO::ComputeOvsDpdkSriov::Net::SoftwareConfig
resource_registry:
...
  # Port assignments for the Compute DPDK-SRIOV
  OS::TripleO::ComputeOvsDpdkSriov::Net::SoftwareConfig:
    /home/stack/ovs-dpdk/templates/nic-configs/computedpdksriov.yaml
# 定义环境参数
...
  NeutronNetworkType: 'vxlan, vlan'
  NeutronTunnelTypes: 'vxlan'
  NeutronEnableDVR: false
  NeutronBridgeMappings: "datacentre:br-ex,dpdk0:br-dpdk0"
  # Neutron VLAN ranges per network, for example 'datacentre:1:499,tenant:500:1000':
  NeutronNetworkVLANRanges: 'datacentre:187:187,dpdk0:900:904,sriov-1:900:904'
  # Customize bonding options, e.g. "mode=4 lacp_rate=1 updelay=1000 miimon=100"
  # for Linux bonds w/LACP, or "bond_mode=active-backup" for OVS active/backup.
  #BondInterfaceOvsOptions: "bond_mode=active-backup"
 
  NeutronOVSFirewallDriver: openvswitch
  NovaEnableNUMALiveMigration: true

# OVS DPDK 节点配置
  ##########################
  # OVS DPDK configuration #
  ##########################
 
  ComputeOvsDpdkParameters:
    IsolCpusList: 2,18,4,20,6,22,8,24,10,26,12,28,14,30,3,19,5,21,7,23,9,25,11,27,13,29,15,31
    KernelArgs: default_hugepagesz=1GB hugepagesz=1G hugepages=32 iommu=pt intel_iommu=on
      isolcpus=2,18,4,20,6,22,8,24,10,26,12,28,14,30,3,19,5,21,7,23,9,25,11,27,13,29,15,31
    NovaReservedHostMemory: 4096
    NovaComputeCpuDedicatedSet: 4,20,6,22,8,24,10,26,12,28,14,30,5,21,7,23,9,25,11,27,13,29,15,31
    OvsDpdkCoreList: 0,16,1,17
    OvsDpdkMemoryChannels: 4
    OvsDpdkSocketMemory: "1024,4096"
    OvsPmdCoreList: 2,18,3,19

# OVS DPDK SR-IOV 节点配置
  #################################
  # OVS DPDK SR-IOV configuration #
  #################################
 
  ComputeOvsDpdkSriovParameters:
    IsolCpusList: 2,18,4,20,6,22,8,24,10,26,12,28,14,30,3,19,5,21,7,23,9,25,11,27,13,29,15,31
    KernelArgs: default_hugepagesz=1GB hugepagesz=1G hugepages=32 iommu=pt intel_iommu=on
      isolcpus=2,18,4,20,6,22,8,24,10,26,12,28,14,30,3,19,5,21,7,23,9,25,11,27,13,29,15,31
    TunedProfileName: "cpu-partitioning"
    NovaComputeCpuDedicatedSet: 4,20,6,22,8,24,10,26,12,28,14,30,5,21,7,23,9,25,11,27,13,29,15,31
    NovaReservedHostMemory: 4096
    OvsDpdkSocketMemory: "1024,4096"
    OvsDpdkMemoryChannels: "4"
    OvsDpdkCoreList: 0,16,1,17
    OvsPmdCoreList: 2,18,3,19
    NovaComputeCpuSharedSet: [0,16,1,17]
    # When using NIC partioning on SR-IOV enabled setups, 'derive_pci_passthrough_whitelist.py'
    # script will be executed which will override NovaPCIPassthrough.
    # No option to disable as of now - https://bugzilla.redhat.com/show_bug.cgi?id=1774403
    NovaPCIPassthrough:
      - devname: "enp130s0f1"
        trusted: "true"
        physical_network: "sriov-1"
 
    # NUMA aware vswitch
    # NeutronPhysnetNUMANodesMapping: {dpdk-mgmt: [0]}
    # NeutronTunnelNUMANodes: [0]
    NeutronPhysicalDevMappings:
      - sriov-1:enp130s0f1

# Scheduler Filters 配置
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

# 设置 node_info.yaml
(undercloud) [stack@dell-per730-02 ovs-dpdk]$ cat templates/node_info.yaml 
parameter_defaults:
  ControllerCount: 3
  ComputeCount: 0
  ComputeOvsDpdkCount: 3
  ComputeOvsDpdkSriovCount: 1

  ControllerSchedulerHints:
    'capabilities:node': 'controller-%index%'
  ComputeSchedulerHints:
    'capabilities:node': 'compute-%index%'
  ComputeOvsDpdkSchedulerHints:
    'capabilities:node': 'computeovsdpdk-%index%'
  ComputeOvsDpdkSriovSchedulerHints:
    'capabilities:node': 'computeovsdpdksriov-%index%'

# 为节点打标签
openstack baremetal node set --property capabilities='node:controller-0,boot_option:local' controller-0
openstack baremetal node set --property capabilities='node:controller-1,boot_option:local' controller-1
openstack baremetal node set --property capabilities='node:controller-2,boot_option:local' controller-2

openstack baremetal node set --property capabilities='node:computeovsdpdk-0,boot_option:local' computedpdk-0
openstack baremetal node set --property capabilities='node:computeovsdpdk-1,boot_option:local' computedpdk-1
openstack baremetal node set --property capabilities='node:computeovsdpdk-2,boot_option:local' computedpdk-2

openstack baremetal node set --property capabilities='node:computeovsdpdksriov-0,boot_option:local' computedpdk-3

# 修改部署脚本，包含如下模版文件
# -e $THT/environments/services/neutron-ovs.yaml
# -e $THT/environments/services/neutron-ovs-dpdk.yaml
# -e $THT/environments/services/neutron-sriov.yaml
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $CNF/node-info.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $THT/environments/services/neutron-ovs.yaml \
-e $THT/environments/services/neutron-ovs-dpdk.yaml \
-e $THT/environments/services/neutron-sriov.yaml \
-e $CNF/environments/fixed-ips.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1

创建 sriov aggregate
openstack aggregate create sriov-group-1
openstack aggregate add host sriov-group-1 overcloud-computeovsdpdksriov-0.localdomain
openstack aggregate set --property sriov=true sriov-group-1

创建 dpdk aggregate
openstack aggregate create dpdk-group-1
openstack aggregate add host dpdk-group-1 overcloud-computeovsdpdk-0.localdomain
openstack aggregate add host dpdk-group-1 overcloud-computeovsdpdk-1.localdomain
openstack aggregate add host dpdk-group-1 overcloud-computeovsdpdk-2.localdomain
openstack aggregate add host dpdk-group-1 overcloud-computeovsdpdksriov-0.localdomain
openstack aggregate set --property dpdk=true dpdk-group-1

创建 sriov network 和 subnet
openstack network create sriov-net-1 \
  --provider-physical-network sriov-1 \
  --provider-network-type vlan --provider-segment 900
openstack subnet create sriov-subnet-1 --network sriov-net-1 \
  --no-dhcp --subnet-range 192.168.2.0/24 \
  --allocation-pool start=192.168.2.100,end=192.168.2.200 --gateway 192.168.2.1

openstack network create sriov-net-2 \
  --provider-physical-network sriov-2 \
  --provider-network-type vlan --provider-segment 900
openstack subnet create sriov-subnet-2 --network sriov-net-2 \
  --no-dhcp --subnet-range 192.168.2.0/24 \
  --allocation-pool start=192.168.2.100,end=192.168.2.200 --gateway 192.168.2.1

创建 dpdk network 和 subnet
openstack network create dpdk-net-1 \
  --provider-physical-network dpdk0 \
  --provider-network-type vlan --provider-segment 900
openstack subnet create dpdk-subnet-1 --network dpdk-net-1 \
  --no-dhcp --subnet-range 192.168.2.0/24 \
  --allocation-pool start=192.168.2.50,end=192.168.2.99 --gateway 192.168.2.1

创建 dpdk ipv6 tenant network 和 subnet
openstack network create dpdk-ipv6-net-1
openstack subnet create dpdk-ipv6-subnet-1 --network dpdk-ipv6-net-1 \
  --ip-version 6 --ipv6-address-mode dhcpv6-stateful \
  --subnet-range fdf8:f53b:82e4::0/64 
（不工作）  
openstack subnet create dpdk-ipv6-subnet-1-slaac --network dpdk-ipv6-net-1 \
  --ip-version 6 --ipv6-ra-mode slaac --ipv6-address-mode slaac \
  --subnet-range fdf8:f53b:82e5::0/64 
（不工作）  
openstack subnet create dpdk-ipv6-subnet-1 --network dpdk-ipv6-net-1 \
  --ip-version 6 --ipv6-address-mode dhcpv6-stateful \
  --subnet-range fdf8:f53b:82e5::0/64


创建 security group rule 
PGID=$(openstack project show admin -c id -f value)
SGID=$(openstack security group list | grep $PGID | grep default | awk '{print $2}')
openstack security group rule create --proto icmp $SGID
openstack security group rule create --dst-port 22 --proto tcp $SGID
openstack security group rule create --proto ipv6-icmp --ingress $SGID

创建 sriov flavor
openstack flavor create m1.sriov --ram 4096 --disk 10 --vcpus 4

设置 sriov flavor property
openstack flavor set --property sriov=true --property hw:cpu_policy=dedicated --property hw:mem_page_size=1GB m1.sriov

创建 dpdk flavor
openstack flavor create m1.dpdk --ram 4096 --disk 10 --vcpus 4

设置 dpdk flavor property
openstack flavor set --property dpdk=true --property hw:cpu_policy=dedicated --property hw:mem_page_size=1GB --property hw:emulator_threads_policy=isolate m1.dpdk

上传镜像
openstack image create --file ~/rhel-8.3-x86_64-kvm-password.qcow2 --disk-format qcow2 rhel8u3

启动 dpdk 实例1
dpdk_network_id=$(openstack network show dpdk-net-1 -f value -c id)
openstack port create --network ${dpdk_network_id} dpdk-port-1 --fixed-ip ip-address=192.168.2.51

cat <<EOF > mydata.file
#cloud-config
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True
ethernets:
  eth0:
    addresses:
      - 192.168.2.51/24
EOF

dpdk_port_id=$(openstack port show dpdk-port-1 -f value -c id)
openstack server create --flavor m1.dpdk --image rhel8u3 --nic port-id=$dpdk_port_id --config-drive True --user-data mydata.file test-dpdk-1

启动 dpdk 实例2
dpdk_network_id=$(openstack network show dpdk-net-1 -f value -c id)
openstack port create --network ${dpdk_network_id} dpdk-port-2 --fixed-ip ip-address=192.168.2.52

cat <<EOF > mydata.file
#cloud-config
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True
ethernets:
  eth0:
    addresses:
      - 192.168.2.52/24
EOF

dpdk_port_id=$(openstack port show dpdk-port-2 -f value -c id)
openstack server create --flavor m1.dpdk --image rhel8u3 --nic port-id=$dpdk_port_id --config-drive True --user-data mydata.file test-dpdk-2

启动 sriov 实例
sriov_network_id=$(openstack network show sriov-net-1 -f value -c id)
openstack port create --network ${sriov_network_id} sriov-port-1 --vnic-type direct --fixed-ip ip-address=192.168.2.101

cat <<EOF > mydata.file
#cloud-config
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True
ethernets:
  eth0:
    addresses:
      - 192.168.2.101/24
EOF

sriov_port_id=$(openstack port show sriov-port-1 -f value -c id)
openstack server create --flavor m1.sriov --image rhel8u3 --nic port-id=$sriov_port_id --config-drive True --user-data mydata.file test-sriov-1

启动 sriov 双网卡实例
sriov_network_1_id=$(openstack network show sriov-net-1 -f value -c id)
openstack port create --network ${sriov_network_1_id} sriov-port-1 --vnic-type direct --fixed-ip ip-address=192.168.2.101
sriov_network_2_id=$(openstack network show sriov-net-2 -f value -c id)
openstack port create --network ${sriov_network_2_id} sriov-port-2 --vnic-type direct --fixed-ip ip-address=192.168.2.101

通过 cloud-config 配置 bond，这个配置不工作
https://cloudinit.readthedocs.io/en/latest/topics/network-config.html
https://bugs.launchpad.net/cloud-init/+bug/1701417
https://netplan.io/examples/
https://bugzilla.redhat.com/show_bug.cgi?id=1536946
cat <<EOF > mydata.file
#cloud-config
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True
ethernets:
  eth0:
    dhcp4: no
  eth1:
    dhcp4: no
bonds:
  bond0:
    interfaces: [eth0,eth1]
    addresses: [192.168.2.101/24]
    parameters:
      mode: active-backup
      mii-monitor-interval: 100
      fail-over-mac-policy: active
EOF

cat <<EOF > mydata.file
#cloud-config
disable_ec2_metadata: true
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True
network:
   version: 2
   renderer: networkd
   bonds:
       bond0:
           addresses: [192.168.2.101/24]
           gateway4: 192.168.2.1
           interfaces:
               - eth0                    
               - eth1                    
           parameters:
               mode: active-backup
               mii-monitor-interval: 100
               fail-over-mac-policy: active
       ethernets:
           eth0:
               match:
                   macaddress: 'fa:16:3e:1e:96:6f'
               addresses: []
               dhcp4: false
               dhcp6: false
           eth1:
               match:
                   macaddress: 'fa:16:3e:1e:96:6f'          
               addresses: []
               dhcp4: false
               dhcp6: false
EOF

cat <<EOF > mydata.file
#cloud-config
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True
network:
  config:
  - id: eth0
    mac_address: fa:16:3e:1e:96:6f
    mtu: 1500
    name: eth0
    subnets:
    - type: manual
    type: physical
  - id: eth1
    mac_address: fa:16:3e:1e:96:6f
    mtu: 1500
    name: eth1
    subnets:
    - type: manual
    type: physical
  - bond_interfaces:
    - eth0
    - eth1
    id: bond0
    mtu: 1500
    name: bond0
    params:
      bond-miimon: 100
      bond-mode: active-backup
      bond-xmit-hash-policy: active
    subnets:
    - address: 192.168.2.101/24
      dns_nameservers: []
      gateway: 192.168.2.1
      type: static
    type: bond
EOF

cat <<EOF > mydata.file
#cloud-config
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True

runcmd:
  - '/bin/nmcli con delete "System eth0"'
  - '/bin/nmcli con delete "System eth1"'
  - '/bin/nmcli con add type bond con-name bond0 ifname bond0 bond.options "mode=active-backup,miimon=100,fail_over_mac=active" connection.autoconnect "yes" ipv4.method "manual" ipv4.address "192.168.2.101/24"'
  - '/bin/nmcli con add type bond-slave ifname eth0 con-name eth0 master bond0'
  - '/bin/nmcli con add type bond-slave ifname eth1 con-name eth1 master bond0'

power_state:
  mode: reboot
EOF

sriov_port_1_id=$(openstack port show sriov-port-1 -f value -c id)
sriov_port_2_id=$(openstack port show sriov-port-2 -f value -c id)
openstack server create --flavor m1.sriov --image rhel8u3 --nic port-id=$sriov_port_1_id --nic port-id=$sriov_port_2_id --config-drive True --user-data mydata.file test-sriov-1

查看实例所在的 Hypervisor
openstack server show test-dpdk-1 -f yaml | grep hypervisor 
openstack server show test-dpdk-2 -f yaml | grep hypervisor 
openstack server show test-sriov-1 -f yaml | grep hypervisor
openstack server show test-dpdk-ipv6-1 -f yaml | grep hypervisor 
openstack server show test-dpdk-ipv6-2 -f yaml | grep hypervisor 


清理实例和 port
openstack server delete test-dpdk-1
openstack server delete test-dpdk-2
openstack server delete test-sriov-1
openstack port delete dpdk-port-1
openstack port delete dpdk-port-2
openstack port delete sriov-port-1


设置静态 ipv6 地址
nmcli con mod 'System eth0' \
  ipv6.method 'manual' \
  ipv6.address 'fdf8:f53b:82e5:0:f816:3eff:fe9c:9449/64'

# 通过 cloud-init config-drive 配置静态 ipv6 地址
# 配置思路是生成 version: 2 的 network 配置
# 这种方法与系统的内部 network manager 配置的结果有冲突
# 配置完后接口短期获得 ipv6 地址，过一段时间后就会被 dhcp 的配置冲掉
# 因此还是在内部结合 nmcli 的配置方法更有效
# 参考：https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v2.html
# 参考：https://serverfault.com/questions/866696/how-do-i-enable-ipv6-in-rhel-7-4-on-amazon-ec2/
# 参考：https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v2.html#network-config-v2

举例来说，在 ipv6 subnet 上创建端口，port 的 fixed ip 地址是 fdf8:f53b:82e5:0:f816:3eff:feca:b261
首先生成 cloud-init 配置文件 /etc/cloud/cloud.cfg.d/99-custom-networking.cfg
文件内容是
      network:
        version: 2
        ethernets:
          eth0:
            dhcp: false
            dhcp6: false
            match:
              name: eth0
            addresses:
              - fdf8:f53b:82e5:0:f816:3eff:feca:b261/64
然后重启实例
power_state:
  mode: reboot
  delay: now
  message: Rebooting post-config
  timeout: 30
  condition: True

cat <<EOF > mydata.file
#cloud-config
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True
write_files:
  - path: /etc/cloud/cloud.cfg.d/99-custom-networking.cfg
    owner: root:root
    permissions: 0600
    content: |
      network:
        version: 2
        ethernets:
          eth0:
            dhcp: false
            dhcp6: false
            match:
              name: eth0
            addresses:
              - fdf8:f53b:82e5:0:f816:3eff:feca:b261/64

power_state:
  mode: reboot
  delay: now
  message: Rebooting post-config
  timeout: 30
  condition: True
EOF

cat <<EOF > mydata.file
#cloud-config
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True

runcmd:
  - "/bin/nmcli -t -f uuid con | while read i ; do /bin/nmcli con delete $i; done"
  - '/bin/nmcli con add type ethernet con-name eth0 ifname eth0 connection.autoconnect "yes" ipv6.method "manual" ipv6.address "fdf8:f53b:82e5:0:f816:3eff:fe6d:edea/64"'
  - '/bin/nmcli con add type ethernet con-name eth1 ifname eth1 connection.autoconnect "yes" ipv4.method "manual" ipv4.address "192.168.2.53/24" ipv4.gateway "192.168.2.1"'

power_state:
  mode: reboot
  delay: now
  message: Rebooting post-config
  timeout: 30
  condition: True
EOF

创建2个 dpdk ipv6 port
dpdk_ipv6_network_id=$(openstack network show dpdk-ipv6-net-1 -f value -c id)
openstack port create --network ${dpdk_ipv6_network_id} dpdk-ipv6-port-1
openstack port create --network ${dpdk_ipv6_network_id} dpdk-ipv6-port-2

获取这两个 port 的 ipv6地址
dpdk_ipv6_port_1_ipv6address=$(openstack port show dpdk-ipv6-port-1 -f yaml | grep ip_address | awk '{print $3}' )
dpdk_ipv6_port_2_ipv6address=$(openstack port show dpdk-ipv6-port-2 -f yaml | grep ip_address | awk '{print $3}' )

cat <<EOF > mydata.file
#cloud-config
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True
write_files:
  - path: /etc/cloud/cloud.cfg.d/99-custom-networking.cfg
    owner: root:root
    permissions: 0600
    content: |
      network:
        version: 2
        ethernets:
          eth0:
            dhcp: false
            dhcp6: false
            match:
              name: eth0
            addresses:
              - ${dpdk_ipv6_port_1_ipv6address}/64

power_state:
  mode: reboot
  delay: now
  message: Rebooting post-config
  timeout: 30
  condition: True
EOF

dpdk_ipv6_port_1_id=$(openstack port show dpdk-ipv6-port-1 -f value -c id)
openstack server create --flavor m1.dpdk --image rhel8u3 --nic port-id=$dpdk_ipv6_port_1_id --config-drive True --user-data mydata.file test-dpdk-ipv6-1

cat <<EOF > mydata.file
#cloud-config
password: redhat
chpasswd: { expire: False }
ssh_pwauth: True
write_files:
  - path: /etc/cloud/cloud.cfg.d/99-custom-networking.cfg
    owner: root:root
    permissions: 0600
    content: |
      network:
        version: 2
        ethernets:
          eth0:
            dhcp: false
            dhcp6: false
            match:
              name: eth0
            addresses:
              - "[${dpdk_ipv6_port_2_ipv6address}/64]"

power_state:
  mode: reboot
  delay: now
  message: Rebooting post-config
  timeout: 30
  condition: True
EOF

dpdk_ipv6_port_2_id=$(openstack port show dpdk-ipv6-port-2 -f value -c id)
openstack server create --flavor m1.dpdk --image rhel8u3 --nic port-id=$dpdk_ipv6_port_2_id --config-drive True --user-data mydata.file test-dpdk-ipv6-2

# 删除 2 个 dpdk ipv6 实例
openstack server delete test-dpdk-ipv6-1
openstack server delete test-dpdk-ipv6-2

# 设置 inspection root password
(undercloud) [stack@undercloud ~]$ openssl passwd -1 redhat
$1$J5QN13Eg$fg1DdFcfDAEROPnMnkrgK1

cat /var/lib/ironic/httpboot/inspector.ipxe 
#!ipxe

:retry_boot
imgfree
kernel --timeout 60000 http://192.0.2.1:8088/agent.kernel ipa-inspection-callback-url=http://192.0.2.1:5050/v1/continue ipa-inspection-collectors=default,extra-hardware,numa-topology,logs systemd.journald.forward_to_console=yes BOOTIF=${mac} ipa-inspection-dhcp-all-interfaces=1 ipa-collect-lldp=1 rootpwd="$1$J5QN13Eg$fg1DdFcfDAEROPnMnkrgK1" initrd=agent.ramdisk || goto retry_boot
initrd --timeout 60000 http://192.0.2.1:8088/agent.ramdisk || goto retry_boot
boot

                                             
# 更新 plan
openstack overcloud deploy --templates $THT --update-plan-only -r $CNF/roles_data.yaml -n $CNF/network_data.yaml -e $CNF/node-info.yaml -e $THT/environments/network-isolation.yaml -e $CNF/environments/network-environment.yaml -e $THT/environments/services/neutron-ovs.yaml -e $THT/environments/services/neutron-ovs-dpdk.yaml -e $THT/environments/services/neutron-sriov.yaml -e $CNF/environments/net-bond-with-vlans.yaml -e ~/containers-prepare-parameter.yaml -e $CNF/fix-nova-reserved-host-memory.yaml --ntp-server 192.0.2.1

# 设置 nic partitioning， 内部网络在 sriov vf 上，dpdk ovs_user_bridge 也在 sriov vf 上
https://blueprints.launchpad.net/tripleo/+spec/sriov-vfs-as-network-interface


# 查看节点 cpu NUMA 信息
lscpu |  grep NUMA

# 报错信息
2021-06-18 13:56:51,290 p=403090 u=mistral n=ansible | fatal: [overcloud-computeovsdpdksriov-0]: FAILED! => {
    "NetworkConfig_result.stderr_lines": [
        "+ '[' -n '{\"network_config\": [{\"addresses\": [{\"ip_netmask\": \"192.0.2.23/24\"}], \"mtu\": 1500, \"name\": \"ens3\", \"routes\": [{\"default\": t
rue, \"next_hop\": \"192.0.2.1\"}], \"type\": \"interface\", \"use_dhcp\": false}, {\"addresses\": [{\"ip_netmask\": \"172.16.1.46/24\"}], \"device\": \"eno4\"
, \"mtu\": 1500, \"type\": \"vlan\", \"vlan_id\": 30}, {\"addresses\": [{\"ip_netmask\": \"172.16.0.28/24\"}], \"members\": [{\"members\": [{\"name\": \"eno5\"
, \"type\": \"interface\"}], \"name\": \"br-dpdk0-dpdk-port0\", \"rx_queue\": 1, \"type\": \"ovs_dpdk_port\"}], \"name\": \"br-dpdk0\", \"ovs_extra\": [\"set p
ort br-dpdk0 tag=50\"], \"type\": \"ovs_user_bridge\", \"use_dhcp\": false}]}' ']'",
        "+ '[' -z '' ']'",
        "+ trap configure_safe_defaults EXIT",
        "++ date +%Y-%m-%dT%H:%M:%S",
        "+ DATETIME=2021-06-18T01:55:34",
        "+ '[' -f /etc/os-net-config/config.json ']'",
        "+ mkdir -p /etc/os-net-config",
        "+ echo '{\"network_config\": [{\"addresses\": [{\"ip_netmask\": \"192.0.2.23/24\"}], \"mtu\": 1500, \"name\": \"ens3\", \"routes\": [{\"default\": tru
e, \"next_hop\": \"192.0.2.1\"}], \"type\": \"interface\", \"use_dhcp\": false}, {\"addresses\": [{\"ip_netmask\": \"172.16.1.46/24\"}], \"device\": \"eno4\", 
\"mtu\": 1500, \"type\": \"vlan\", \"vlan_id\": 30}, {\"addresses\": [{\"ip_netmask\": \"172.16.0.28/24\"}], \"members\": [{\"members\": [{\"name\": \"eno5\", 
\"type\": \"interface\"}], \"name\": \"br-dpdk0-dpdk-port0\", \"rx_queue\": 1, \"type\": \"ovs_dpdk_port\"}], \"name\": \"br-dpdk0\", \"ovs_extra\": [\"set por
t br-dpdk0 tag=50\"], \"type\": \"ovs_user_bridge\", \"use_dhcp\": false}]}'",
        "++ type -t network_config_hook",
        "+ '[' '' = function ']'",
        "+ sed -i 's/: \"bridge_name/: \"br-ex/g' /etc/os-net-config/config.json",
        "+ sed -i s/interface_name/nic1/g /etc/os-net-config/config.json",
        "+ set +e",
        "+ os-net-config -c /etc/os-net-config/config.json -v --detailed-exit-codes",
        "[2021/06/18 01:55:35 AM] [INFO] Using config file at: /etc/os-net-config/config.json",
        "[2021/06/18 01:55:35 AM] [INFO] Ifcfg net config provider created.",
        "[2021/06/18 01:55:35 AM] [INFO] Not using any mapping file.",
        "[2021/06/18 01:55:36 AM] [INFO] Finding active nics",
        "[2021/06/18 01:55:36 AM] [INFO] ens3 is an active nic",
        "[2021/06/18 01:55:36 AM] [INFO] ens4 is an active nic",
        "[2021/06/18 01:55:36 AM] [INFO] lo is not an active nic",
        "[2021/06/18 01:55:36 AM] [INFO] ens5 is an active nic",
        "[2021/06/18 01:55:36 AM] [INFO] No DPDK mapping available in path (/var/lib/os-net-config/dpdk_mapping.yaml)",
        "[2021/06/18 01:55:36 AM] [INFO] Active nics are ['ens3', 'ens4', 'ens5']",
        "[2021/06/18 01:55:36 AM] [INFO] nic2 mapped to: ens4",
        "[2021/06/18 01:55:36 AM] [INFO] nic3 mapped to: ens5",
        "[2021/06/18 01:55:36 AM] [INFO] nic1 mapped to: ens3",
        "[2021/06/18 01:55:36 AM] [INFO] adding interface: ens3",
        "[2021/06/18 01:55:36 AM] [INFO] adding custom route for interface: ens3",

考虑在 network-environments.yaml 文件里设置，让更新时网络的变化仍然生效
  NetworkDeploymentActions: ['CREATE','UPDATE']

--
        "  File \"/usr/lib/python3.6/site-packages/os_net_config/utils.py\", line 329, in bind_dpdk_interfaces",
        "    raise OvsDpdkBindException(msg)",
        "os_net_config.utils.OvsDpdkBindException: Interface eno5 cannot be found",

设备名称在虚拟机里应该是 ens3, ens4, ens5


  virt-install \
  --ram 6144 --vcpus 8 \
  --os-variant rhel7 \
  --disk path=/home/images/overcloud-node${nodeid}.qcow2,device=disk,bus=virtio,format=qcow2 \
  --noautoconsole --vnc \
  --network network:provisioning,model=e1000 \
  --network network:trunk,model=e1000 \
  --network network:trunk,model=e1000 \
  --network network:redhat,model=e1000 \
  --network network:stonith,model=e1000 \
  --name overcloud-node${nodeid} \
  --cpu SandyBridge,+vmx,cell0.id=0,cell0.cpus=0-3,cell0.memory=3072000,cell1.id=1,cell1.cpus=4-7,cell1.memory=3072000\
  --machine q35\
  --dry-run --print-xml > overcloud-node${nodeid}.xml;

COMPT_N="compute01 compute02"
COMPT_MEM='6144'
COMPT_VCPU='4'
LIBVIRT_D="/data/kvm"

# 创建计算节点虚拟机
for i in $COMPT_N;
do
    echo "Defining node jwang-overcloud-$i-temp..."
    virt-install --ram $COMPT_MEM --vcpus $COMPT_VCPU --os-variant rhel7 \
    --disk path=${LIBVIRT_D}/jwang-overcloud-$i.qcow2,device=disk,bus=virtio,format=qcow2 \
    --noautoconsole --vnc --network network:provisioning,model=e1000 \
    --network network:default,model=e1000 --network network:default,model=e1000 \
    --name jwang-overcloud-$i-temp \
    --cpu SandyBridge,+vmx \
    --machine q35 \
    --check path_in_use=off \
    --dry-run --print-xml > /tmp/jwang-overcloud-$i-temp.xml;

    # virsh define --file /tmp/jwang-overcloud-$i.xml || { echo "Unable to define jwang-overcloud-$i"; return 1; }
done

for i in computeovsdpdksriov; do
  openstack flavor create $i --ram 4096 --vcpus 1 --disk 40
  openstack flavor set --property "capabilities:boot_option"="local" \
                       --property "capabilities:profile"="${i}" ${i}
done

# Mellanox 网卡指南
https://downloads.dell.com/manuals/all-products/esuprt_data_center_infra_int/esuprt_data_center_infra_network_adapters/mellanox-adapters_users-guide_en-us.pdf

# 设置节点 vf trunk ，这种方式应该是 Mellanox 网卡特有的
https://docs.mellanox.com/pages/viewpage.action?pageId=47033949
echo "add 900 904" > /sys/class/net/enp130s0f0/device/sriov/0/trunk

ovs-vsctl show
...
    Bridge br-dpdk0
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
        fail_mode: secure
        datapath_type: netdev
        Port br-dpdk0
            tag: 191
            Interface br-dpdk0
                type: internal
        Port phy-br-dpdk0
            Interface phy-br-dpdk0
                type: patch
                options: {peer=int-br-dpdk0}
        Port br-dpdk0-dpdk-port0
            Interface br-dpdk0-dpdk-port0
                type: dpdk
                options: {dpdk-devargs="0000:82:10.0", n_rxq="1"}
    ovs_version: "2.13.2"

# 为 vf 设置 vlan, vlan 4095 是 trunk 的意思吗?
https://community.mellanox.com/s/article/howto-set-virtual-network-attributes-on-a-virtual-function--sr-iov-x

Deployment Template Library
https://gitlab.cee.redhat.com/mnietoji/deployment_templates/-/tree/master
```


### 软件频道 rhel-8-for-x86_64-nfv-rpms 包含那些软件包
```
Red Hat Enterprise Linux 8 for x86_64 - Real Ti 4.5 MB/s | 213 MB     00:46    
comps.xml for repository rhel-8-for-x86_64-nfv-rpms saved
(1/22): kernel-rt-devel-4.18.0-193.28.1.rt13.77 1.5 MB/s |  15 MB     00:09    
(2/22): rt-tests-1.5-18.el8.x86_64.rpm           86 kB/s | 177 kB     00:02    
(3/22): kernel-rt-modules-extra-4.18.0-193.28.1 808 kB/s | 3.4 MB     00:04    
(4/22): tuned-profiles-nfv-2.13.0-6.el8.noarch.  17 kB/s |  32 kB     00:01    
(5/22): kernel-rt-debug-core-4.18.0-193.28.1.rt 2.0 MB/s |  52 MB     00:26    
(6/22): kernel-rt-modules-4.18.0-193.28.1.rt13. 1.8 MB/s |  24 MB     00:13    
(7/22): kernel-rt-4.18.0-193.28.1.rt13.77.el8_2 629 kB/s | 2.8 MB     00:04    
(8/22): kernel-rt-debug-devel-4.18.0-193.28.1.r 1.5 MB/s |  15 MB     00:10    
(9/22): rteval-3.0-6.el8.noarch.rpm              61 kB/s | 134 kB     00:02    
(10/22): tuned-profiles-realtime-2.13.0-6.el8.n  20 kB/s |  35 kB     00:01    
(11/22): kernel-rt-debug-modules-extra-4.18.0-1 954 kB/s | 4.1 MB     00:04    
(12/22): rteval-common-3.0-6.el8.noarch.rpm      24 kB/s |  42 kB     00:01    
(13/22): tuned-profiles-nfv-host-2.13.0-6.el8.n  19 kB/s |  36 kB     00:01    
(14/22): rt-setup-2.1-2.el8.x86_64.rpm           15 kB/s |  26 kB     00:01    
(15/22): kernel-rt-kvm-4.18.0-193.28.1.rt13.77. 1.0 MB/s | 3.2 MB     00:03    
(16/22): tuned-profiles-nfv-host-bin-0-0.1.2018  14 kB/s |  24 kB     00:01    
(17/22): tuned-profiles-nfv-guest-2.13.0-6.el8.  21 kB/s |  35 kB     00:01    
(18/22): kernel-rt-debug-kvm-4.18.0-193.28.1.rt 892 kB/s | 3.6 MB     00:04    
(19/22): kernel-rt-core-4.18.0-193.28.1.rt13.77 1.9 MB/s |  27 MB     00:14    
(20/22): kernel-rt-debug-modules-4.18.0-193.28. 2.3 MB/s |  47 MB     00:20    
(21/22): kernel-rt-debug-4.18.0-193.28.1.rt13.7 886 kB/s | 2.8 MB     00:03    
(22/22): rteval-loads-1.4-6.el8.noarch.rpm      817 kB/s | 101 MB     02:06 
```



