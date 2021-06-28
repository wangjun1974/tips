### 配置 ovsdpdk 
```
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
openstack overcloud roles generate -o ~/templates/roles_data.yaml Controller ComputeOvsDpdkSriov

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

                                             
需要附加在 network-environment 文件里的参数

  NeutronOVSFirewallDriver: openvswitch
  NovaEnableNUMALiveMigration: true

  ComputeOvsDpdkSriovParameters:
    IsolCpusList: "1,2,3"
    KernelArgs: "default_hugepagesz=2M hugepagesz=2M hugepages=1024 iommu=pt intel_iommu=on isolcpus=1,2,3"
    NovaReservedHostMemory: "1024"
    NovaComputeCpuDedicatedSet: ['2,3']
    OvsDpdkCoreList: "0"
    OvsDpdkMemoryChannels: 4
    OvsDpdkSocketMemory: "1024"
    OvsPmdCoreList: "1"

更新 plan
openstack overcloud deploy --templates $THT --update-plan-only -r $CNF/roles_data.yaml -n $CNF/network_data.yaml -e $CNF/node-info.yaml -e $THT/environments/network-isolation.yaml -e $CNF/environments/network-environment.yaml -e $THT/environments/services/neutron-ovs.yaml -e $THT/environments/services/neutron-ovs-dpdk.yaml -e $THT/environments/services/neutron-sriov.yaml -e $CNF/environments/net-bond-with-vlans.yaml -e ~/containers-prepare-parameter.yaml -e $CNF/fix-nova-reserved-host-memory.yaml --ntp-server 192.0.2.1


查看节点 cpu NUMA 信息
lscpu |  grep NUMA



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
```


### 配置 sriov
```

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