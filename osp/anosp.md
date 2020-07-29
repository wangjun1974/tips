Advanced Networking with Red Hat OpenStack Platform


# Task 1 :
# In this task, you configure a provider network to access the VMs directly from workstation without floating IPs.
#  Create a network named provider using vlan 101 and physical network datacentre
#  Create a subnet 192.168.60.0/24 with dhcp enabled, DNS 8.8.8.8 and gateway 192.168.60.1
#  Configure workstation interface eth1 to have connection to vlan 101 and IP 192.168.60.50
#  Create a new vm connected to provider network
#  Access directly from workstation to the VM



# Create a network named provider using vlan 101 and physical network datacentre
#  Create a subnet 192.168.60.0/24 with dhcp enabled, DNS 8.8.8.8 and gateway 192.168.60.1
#  Change vlan id from 101 to 100
[stack@undercloud ~]$ source overcloudrc
(overcloud) [stack@undercloud ~]$ openstack network create provider --provider-physical-network datacentre --provider-network-type vlan --provider-segment 100
<<OMITTED>>
| is_vlan_transparent       | None                                                                                                                                                             |
| location                  | cloud='', project.domain_id=, project.domain_name='Default', project.id='10e6f16ae2aa4c7b899e737d87d65129', project.name='admin', region_name='regionOne', zone= |
| mtu                       | 1500                                                                                                                                                             |
| name                      | provider                                                                                                                                                         |
| port_security_enabled     | True                                                                                                                                                             |
| project_id                | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| provider:network_type     | vlan                                                                                                                                                             |
| provider:physical_network | datacentre                                                                                                                                                       |
| provider:segmentation_id  | 100                                                                                                                                                              |
| qos_policy_id             | None                                                                                                                                                             |
| revision_number           | 1                                                                                                                                                                |
| router:external           | Internal                                                                                                                                                         |
| segments                  | None                                                                                                                                                             |
| shared                    | False                                                                                                                                                            |
| status                    | ACTIVE                                                                                                                                                           |
| subnets                   |                                                                                                                                                                  |
| tags                      |                                                                                                                                                                  |
| updated_at                | 2020-07-28T07:44:03Z                                                                                                                                             |
+---------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack subnet create provider --network provider --dhcp --subnet-range 192.168.60.0/24   --allocation-pool start=192.168.60.100,end=192.168.60.150 --gateway 192.168.60.1 --dns-nameserver 8.8.8.8
<<OMMITED>>
| dns_nameservers   | 8.8.8.8                                                                                                                                                          |
| enable_dhcp       | True                                                                                                                                                             |
| gateway_ip        | 192.168.60.1                                                                                                                                                     |
| host_routes       |                                                                                                                                                                  |
| id                | 33d7b629-7c89-4c9e-88a9-51916c1e5d1f                                                                                                                             |
| ip_version        | 4                                                                                                                                                                |
| ipv6_address_mode | None                                                                                                                                                             |
| ipv6_ra_mode      | None                                                                                                                                                             |
| location          | cloud='', project.domain_id=, project.domain_name='Default', project.id='10e6f16ae2aa4c7b899e737d87d65129', project.name='admin', region_name='regionOne', zone= |
| name              | provider                                                                                                                                                         |
| network_id        | 46fec388-762a-43cc-8cfd-828533956802                                                                                                                             |
| prefix_length     | None                                                                                                                                                             |
| project_id        | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| revision_number   | 0                                                                                                                                                                |
| segment_id        | None                                                                                                                                                             |
| service_types     |                                                                                                                                                                  |
| subnetpool_id     | None                                                                                                                                                             |
| tags              |                                                                                                                                                                  |
| updated_at        | 2020-07-28T07:46:44Z                                                                                                                                             |
+-------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ curl -L http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img -O
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   273  100   273    0     0    931      0 --:--:-- --:--:-- --:--:--   931
100   641  100   641    0     0   1936      0 --:--:-- --:--:-- --:--:--  1936
100 12.1M  100 12.1M    0     0  18.4M      0 --:--:-- --:--:-- --:--:-- 43.6M
(overcloud) [stack@undercloud ~]$ openstack image create --disk-format qcow2 --file cirros-0.4.0-x86_64-disk.img cirros
<<OMMITED>>
| name             | cirros                                                                                                                                                                                                                                                                   |
| owner            | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                                                                                                                         |
| properties       | direct_url='swift+config://ref1/glance/42b40f84-d624-49e2-895e-1528eb263d38', os_hash_algo='sha512', os_hash_value='6513f21e44aa3da349f248188a44bc304a3653a04122d8fb4535423c8e1d14cd6a153f735bb0982e2161b5b5186106570c17a9e58b64dd39390617cd5a350f78', os_hidden='False' |
| protected        | False                                                                                                                                                                                                                                                                    |
| schema           | /v2/schemas/image                                                                                                                                                                                                                                                        |
| size             | 12716032                                                                                                                                                                                                                                                                 |
| status           | active                                                                                                                                                                                                                                                                   |
| tags             |                                                                                                                                                                                                                                                                          |
| updated_at       | 2020-07-28T05:45:16Z                                                                                                                                                                                                                                                     |
| virtual_size     | None                                                                                                                                                                                                                                                                     |
| visibility       | shared                                                                                                                                                                                                                                                                   |
+------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack flavor create --ram 128 --disk 1 --vcpus 1 m1.tiny
+----------------------------+--------------------------------------+
| Field                      | Value                                |
+----------------------------+--------------------------------------+
| OS-FLV-DISABLED:disabled   | False                                |
| OS-FLV-EXT-DATA:ephemeral  | 0                                    |
| description                | None                                 |
| disk                       | 1                                    |
| extra_specs                | {}                                   |
| id                         | a60a139c-1e89-49ae-865e-7c3965581b99 |
| name                       | m1.tiny                              |
| os-flavor-access:is_public | True                                 |
| properties                 |                                      |
| ram                        | 128                                  |
| rxtx_factor                | 1.0                                  |
| swap                       | 0                                    |
| vcpus                      | 1                                    |
+----------------------------+--------------------------------------+
(overcloud) [stack@undercloud ~]$ sg_id=$(openstack security group list | grep $(openstack project show admin -f value -c id) | awk '{ print $2 }')
(overcloud) [stack@undercloud ~]$ openstack security group rule create --proto icmp $sg_id
<<OMITTED>>
| id                | ecd1b032-7fee-447e-a90f-21b61c664cc9                                                                                                                             |
| location          | cloud='', project.domain_id=, project.domain_name='Default', project.id='10e6f16ae2aa4c7b899e737d87d65129', project.name='admin', region_name='regionOne', zone= |
| name              | None                                                                                                                                                             |
| port_range_max    | None                                                                                                                                                             |
| port_range_min    | None                                                                                                                                                             |
| project_id        | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| protocol          | icmp                                                                                                                                                             |
| remote_group_id   | None                                                                                                                                                             |
| remote_ip_prefix  | 0.0.0.0/0                                                                                                                                                        |
| revision_number   | 0                                                                                                                                                                |
| security_group_id | 3f784e4d-b315-46ee-96c7-91a97f4d4cd7                                                                                                                             |
| tags              | []                                                                                                                                                               |
| updated_at        | 2020-07-28T05:48:31Z                                                                                                                                             |
+-------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack security group rule create --dst-port 22 --protocol tcp $sg_id
<<OMITTED>>
| id                | 7b8a2382-2b0e-4553-89c4-5225409399e5                                                                                                                             |
| location          | cloud='', project.domain_id=, project.domain_name='Default', project.id='10e6f16ae2aa4c7b899e737d87d65129', project.name='admin', region_name='regionOne', zone= |
| name              | None                                                                                                                                                             |
| port_range_max    | 22                                                                                                                                                               |
| port_range_min    | 22                                                                                                                                                               |
| project_id        | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| protocol          | tcp                                                                                                                                                              |
| remote_group_id   | None                                                                                                                                                             |
| remote_ip_prefix  | 0.0.0.0/0                                                                                                                                                        |
| revision_number   | 0                                                                                                                                                                |
| security_group_id | 3f784e4d-b315-46ee-96c7-91a97f4d4cd7                                                                                                                             |
| tags              | []                                                                                                                                                               |
| updated_at        | 2020-07-28T05:49:46Z                                                                                                                                             |
+-------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack security group rule create --dst-port 80 --protocol tcp $sg_id
<<OMITTED>>
| id                | 7d20cf87-8d0e-4ecf-9ef3-94b2236d706a                                                                                                                             |
| location          | cloud='', project.domain_id=, project.domain_name='Default', project.id='10e6f16ae2aa4c7b899e737d87d65129', project.name='admin', region_name='regionOne', zone= |
| name              | None                                                                                                                                                             |
| port_range_max    | 80                                                                                                                                                               |
| port_range_min    | 80                                                                                                                                                               |
| project_id        | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| protocol          | tcp                                                                                                                                                              |
| remote_group_id   | None                                                                                                                                                             |
| remote_ip_prefix  | 0.0.0.0/0                                                                                                                                                        |
| revision_number   | 0                                                                                                                                                                |
| security_group_id | 3f784e4d-b315-46ee-96c7-91a97f4d4cd7                                                                                                                             |
| tags              | []                                                                                                                                                               |
| updated_at        | 2020-07-28T05:50:53Z                                                                                                                                             |
+-------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+



# Configure workstation interface eth1 to have connection to vlan 101 and IP 192.168.60.50
# change vlan 101 to 100
[root@workstation-0eb6 ~]# nmcli con add type vlan ifname vlan100 dev eth1 id 100 ipv4.method 'manual' ipv4.address '192.168.60.50/24' 
Connection 'vlan-vlan100' (cd948667-0c80-4a03-a404-58465ce899cf) successfully added.
[root@workstation-0eb6 ~]# ip a s 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 2c:c2:60:29:83:44 brd ff:ff:ff:ff:ff:ff
    inet 192.0.2.252/24 brd 192.0.2.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::2ec2:60ff:fe29:8344/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 2c:c2:60:1b:2c:d2 brd ff:ff:ff:ff:ff:ff
    inet 1.0.0.23/8 brd 1.255.255.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::2ec2:60ff:fe1b:2cd2/64 scope link 
       valid_lft forever preferred_lft forever
5: vlan100@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 2c:c2:60:1b:2c:d2 brd ff:ff:ff:ff:ff:ff
    inet 192.168.60.50/24 brd 192.168.60.255 scope global noprefixroute vlan100
       valid_lft forever preferred_lft forever
    inet6 fe80::fc42:5795:f8aa:507b/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever


#  Create a new vm connected to provider network
(overcloud) [stack@undercloud ~]$ openstack server create --image cirros --flavor m1.tiny --nic net-id=provider,v4-fixed-ip=192.168.60.110 vm1
<<OMITTED>>
| accessIPv4                          |                                                                                    |
| accessIPv6                          |                                                                                    |
| addresses                           |                                                                                    |
| adminPass                           | Ap7FAD722hD8                                                                       |
| config_drive                        |                                                                                    |
| created                             | 2020-07-28T07:51:20Z                                                               |
| description                         | None                                                                               |
| flavor                              | disk='1', ephemeral='0', , original_name='m1.tiny', ram='128', swap='0', vcpus='1' |
| hostId                              |                                                                                    |
| host_status                         |                                                                                    |
| id                                  | 28be5d20-6629-4861-a52f-292af2b1719b                                               |
| image                               | cirros (42b40f84-d624-49e2-895e-1528eb263d38)                                      |
| key_name                            | None                                                                               |
| locked                              | False                                                                              |
| locked_reason                       | None                                                                               |
| name                                | vm1                                                                                |
| progress                            | 0                                                                                  |
| project_id                          | 10e6f16ae2aa4c7b899e737d87d65129                                                   |
| properties                          |                                                                                    |
| security_groups                     | name='default'                                                                     |
| server_groups                       | []                                                                                 |
| status                              | BUILD                                                                              |
| tags                                | []                                                                                 |
| trusted_image_certificates          | None                                                                               |
| updated                             | 2020-07-28T07:51:21Z                                                               |
| user_id                             | 96853114c5e84c76be8c712ca6359e01                                                   |
| volumes_attached                    |                                                                                    |
+-------------------------------------+------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+------+--------+-------------------------+--------+--------+
| ID                                   | Name | Status | Networks                | Image  | Flavor |
+--------------------------------------+------+--------+-------------------------+--------+--------+
| 28be5d20-6629-4861-a52f-292af2b1719b | vm1  | ACTIVE | provider=192.168.60.110 | cirros |        |
+--------------------------------------+------+--------+-------------------------+--------+--------+

#  Access directly from workstation to the VM
[root@workstation-0eb6 ~]# ping -c1 192.168.60.110
PING 192.168.60.110 (192.168.60.110) 56(84) bytes of data.
64 bytes from 192.168.60.110: icmp_seq=1 ttl=64 time=9.73 ms

--- 192.168.60.110 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 9.734/9.734/9.734/0.000 ms
[root@workstation-0eb6 ~]# ssh cirros@192.168.60.110 /sbin/ifconfig 
cirros@192.168.60.110's password: 
eth0      Link encap:Ethernet  HWaddr FA:16:3E:EE:A5:7E  
          inet addr:192.168.60.110  Bcast:192.168.60.255  Mask:255.255.255.0
          inet6 addr: fe80::f816:3eff:feee:a57e/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:185 errors:0 dropped:0 overruns:0 frame:0
          TX packets:228 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:28159 (27.4 KiB)  TX bytes:25806 (25.2 KiB)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:15 errors:0 dropped:0 overruns:0 frame:0
          TX packets:15 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1 
          RX bytes:1628 (1.5 KiB)  TX bytes:1628 (1.5 KiB)


# Task 2 :
# Create two instances with something simple like "webserver" as a workload, and create a load balancer in front of them.

(overcloud) [stack@undercloud ~]$ openstack network create private --dns-domain example.com.
<<OMITTED>>
| name                      | private                                                                                                                                                          |
| port_security_enabled     | True                                                                                                                                                             |
| project_id                | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| provider:network_type     | geneve                                                                                                                                                           |
| provider:physical_network | None                                                                                                                                                             |
| provider:segmentation_id  | 59                                                                                                                                                               |
| qos_policy_id             | None                                                                                                                                                             |
| revision_number           | 1                                                                                                                                                                |
| router:external           | Internal                                                                                                                                                         |
| segments                  | None                                                                                                                                                             |
| shared                    | False                                                                                                                                                            |
| status                    | ACTIVE                                                                                                                                                           |
| subnets                   |                                                                                                                                                                  |
| tags                      |                                                                                                                                                                  |
| updated_at                | 2020-07-28T08:07:52Z                                                                                                                                             |
+---------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack subnet create sub_private --network private --subnet-range 192.168.100.0/24 --dns-nameserver 8.8.8.8
<<OMITTED>>
| dns_nameservers   | 8.8.8.8                                                                                                                                                          |
| enable_dhcp       | True                                                                                                                                                             |
| gateway_ip        | 192.168.100.1                                                                                                                                                    |
| host_routes       |                                                                                                                                                                  |
| id                | 8c304a7a-e7d4-4714-9735-40caf0b26cfc                                                                                                                             |
| ip_version        | 4                                                                                                                                                                |
| ipv6_address_mode | None                                                                                                                                                             |
| ipv6_ra_mode      | None                                                                                                                                                             |
| location          | cloud='', project.domain_id=, project.domain_name='Default', project.id='10e6f16ae2aa4c7b899e737d87d65129', project.name='admin', region_name='regionOne', zone= |
| name              | sub_private                                                                                                                                                      |
| network_id        | 9c3f43a8-a70c-4625-80d1-d076ce5bbeec                                                                                                                             |
| prefix_length     | None                                                                                                                                                             |
| project_id        | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| revision_number   | 0                                                                                                                                                                |
| segment_id        | None                                                                                                                                                             |
| service_types     |                                                                                                                                                                  |
| subnetpool_id     | None                                                                                                                                                             |
| tags              |                                                                                                                                                                  |
| updated_at        | 2020-07-28T08:10:00Z                                                                                                                                             |
+-------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack network create public  --share --external --provider-physical-network datacentre --provider-network-type vlan --provider-segment 10
<<OMITTED>>
| mtu                       | 1500                                                                                                                                                             |
| name                      | public                                                                                                                                                           |
| port_security_enabled     | True                                                                                                                                                             |
| project_id                | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| provider:network_type     | vlan                                                                                                                                                             |
| provider:physical_network | datacentre                                                                                                                                                       |
| provider:segmentation_id  | 10                                                                                                                                                               |
| qos_policy_id             | None                                                                                                                                                             |
| revision_number           | 1                                                                                                                                                                |
| router:external           | External                                                                                                                                                         |
| segments                  | None                                                                                                                                                             |
| shared                    | True                                                                                                                                                             |
| status                    | ACTIVE                                                                                                                                                           |
| subnets                   |                                                                                                                                                                  |
| tags                      |                                                                                                                                                                  |
| updated_at                | 2020-07-28T08:11:35Z                                                                                                                                             |
+---------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack subnet create public --no-dhcp --network public --subnet-range 10.0.0.0/24   --allocation-pool start=10.0.0.71,end=10.0.0.200 --gateway 10.0.0.1 --dns-nameserver 8.8.8.8
<<OMITTED>>
| dns_nameservers   | 8.8.8.8                                                                                                                                                          |
| enable_dhcp       | False                                                                                                                                                            |
| gateway_ip        | 10.0.0.1                                                                                                                                                         |
| host_routes       |                                                                                                                                                                  |
| id                | 09df1a3b-c6cd-48b4-90b9-d22443a090b5                                                                                                                             |
| ip_version        | 4                                                                                                                                                                |
| ipv6_address_mode | None                                                                                                                                                             |
| ipv6_ra_mode      | None                                                                                                                                                             |
| location          | cloud='', project.domain_id=, project.domain_name='Default', project.id='10e6f16ae2aa4c7b899e737d87d65129', project.name='admin', region_name='regionOne', zone= |
| name              | public                                                                                                                                                           |
| network_id        | 97b8dcbf-fb1a-4c89-a4c2-af9e128aba12                                                                                                                             |
| prefix_length     | None                                                                                                                                                             |
| project_id        | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| revision_number   | 0                                                                                                                                                                |
| segment_id        | None                                                                                                                                                             |
| service_types     |                                                                                                                                                                  |
| subnetpool_id     | None                                                                                                                                                             |
| tags              |                                                                                                                                                                  |
| updated_at        | 2020-07-28T08:12:54Z                                                                                                                                             |
+-------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack router create router_private
+-------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Field                   | Value                                                                                                                                                            |
+-------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| admin_state_up          | UP                                                                                                                                                               |
| availability_zone_hints | None                                                                                                                                                             |
| availability_zones      | None                                                                                                                                                             |
| created_at              | 2020-07-28T08:15:44Z                                                                                                                                             |
| description             |                                                                                                                                                                  |
| external_gateway_info   | null                                                                                                                                                             |
| flavor_id               | None                                                                                                                                                             |
| id                      | 9f6cf093-b314-43fa-b459-7285cb43e7d5                                                                                                                             |
| location                | cloud='', project.domain_id=, project.domain_name='Default', project.id='10e6f16ae2aa4c7b899e737d87d65129', project.name='admin', region_name='regionOne', zone= |
| name                    | router_private                                                                                                                                                   |
| project_id              | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| revision_number         | 0                                                                                                                                                                |
| routes                  |                                                                                                                                                                  |
| status                  | ACTIVE                                                                                                                                                           |
| tags                    |                                                                                                                                                                  |
| updated_at              | 2020-07-28T08:15:44Z                                                                                                                                             |
+-------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack router set router_private --external-gateway public
(overcloud) [stack@undercloud ~]$ openstack router add subnet router_private sub_private
(overcloud) [stack@undercloud ~]$ cat > webserver.sh << 'EOF'
#!/bin/sh

MYIP=$(/sbin/ifconfig eth0|grep 'inet addr'|awk -F: '{print $2}'| awk '{print $1}');
OUTPUT_STR="Welcome to $MYIP\r"
OUTPUT_LEN=${#OUTPUT_STR}

while true; do
    echo -e "HTTP/1.0 200 OK\r\nContent-Length: ${OUTPUT_LEN}\r\n\r\n${OUTPUT_STR}" | sudo nc -l -p 80
done
EOF
(overcloud) [stack@undercloud ~]$ openstack server create --image cirros --flavor m1.tiny --nic net-id=private --user-data webserver.sh web01  --wait
<<OMITTED>>
| name                                | web01                                                                                                                                                                                                                                                                                                                                                                                |
| progress                            | 0                                                                                                                                                                                                                                                                                                                                                                                    |
| project_id                          | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                                                                                                                                                                                                                                     |
| properties                          |                                                                                                                                                                                                                                                                                                                                                                                      |
| security_groups                     | name='default'                                                                                                                                                                                                                                                                                                                                                                       |
| server_groups                       | []                                                                                                                                                                                                                                                                                                                                                                                   |
| status                              | ACTIVE                                                                                                                                                                                                                                                                                                                                                                               |
| tags                                | []                                                                                                                                                                                                                                                                                                                                                                                   |
| trusted_image_certificates          | None                                                                                                                                                                                                                                                                                                                                                                                 |
| updated                             | 2020-07-28T08:21:48Z                                                                                                                                                                                                                                                                                                                                                                 |
| user_id                             | 96853114c5e84c76be8c712ca6359e01                                                                                                                                                                                                                                                                                                                                                     |
| volumes_attached                    |                                                                                                                                                                                                                                                                                                                                                                                      |
+-------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack server create --image cirros --flavor m1.tiny --nic net-id=private --user-data webserver.sh web02  --wait
<<OMITTED>>
| name                                | web02                                                                                                                                                                                                                                                                                                                                                                                |
| progress                            | 0                                                                                                                                                                                                                                                                                                                                                                                    |
| project_id                          | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                                                                                                                                                                                                                                     |
| properties                          |                                                                                                                                                                                                                                                                                                                                                                                      |
| security_groups                     | name='default'                                                                                                                                                                                                                                                                                                                                                                       |
| server_groups                       | []                                                                                                                                                                                                                                                                                                                                                                                   |
| status                              | ACTIVE                                                                                                                                                                                                                                                                                                                                                                               |
| tags                                | []                                                                                                                                                                                                                                                                                                                                                                                   |
| trusted_image_certificates          | None                                                                                                                                                                                                                                                                                                                                                                                 |
| updated                             | 2020-07-28T08:23:44Z                                                                                                                                                                                                                                                                                                                                                                 |
| user_id                             | 96853114c5e84c76be8c712ca6359e01                                                                                                                                                                                                                                                                                                                                                     |
| volumes_attached                    |                                                                                                                                                                                                                                                                                                                                                                                      |
+-------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack loadbalancer create --name lbweb --vip-subnet-id sub_private
<<OMITTED>>
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| admin_state_up      | True                                 |
| created_at          | 2020-07-28T08:25:04                  |
| description         |                                      |
| flavor_id           | None                                 |
| id                  | 4cb09ca4-8286-42a2-a163-b7b4f2609787 |
| listeners           |                                      |
| name                | lbweb                                |
| operating_status    | OFFLINE                              |
| pools               |                                      |
| project_id          | 10e6f16ae2aa4c7b899e737d87d65129     |
| provider            | amphora                              |
| provisioning_status | PENDING_CREATE                       |
| updated_at          | None                                 |
| vip_address         | 192.168.100.215                      |
| vip_network_id      | 9c3f43a8-a70c-4625-80d1-d076ce5bbeec |
| vip_port_id         | 617da847-d3df-4350-9e42-c28ae5727686 |
| vip_qos_policy_id   | None                                 |
| vip_subnet_id       | 8c304a7a-e7d4-4714-9735-40caf0b26cfc |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack loadbalancer list
+--------------------------------------+-------+----------------------------------+-----------------+---------------------+----------+
| id                                   | name  | project_id                       | vip_address     | provisioning_status | provider |
+--------------------------------------+-------+----------------------------------+-----------------+---------------------+----------+
| 388c601d-9b0b-4151-adee-2d995b13c72f | lbweb | 10e6f16ae2aa4c7b899e737d87d65129 | 192.168.100.137 | ACTIVE              | amphora  |
+--------------------------------------+-------+----------------------------------+-----------------+---------------------+----------+
(overcloud) [stack@undercloud ~]$ openstack loadbalancer listener create --name listenerweb --protocol HTTP --protocol-port 80 lbweb
+-----------------------------+--------------------------------------+
| Field                       | Value                                |
+-----------------------------+--------------------------------------+
| admin_state_up              | True                                 |
| connection_limit            | -1                                   |
| created_at                  | 2020-07-29T01:18:15                  |
| default_pool_id             | None                                 |
| default_tls_container_ref   | None                                 |
| description                 |                                      |
| id                          | ab46bb22-2260-4082-ab78-de079484e730 |
| insert_headers              | None                                 |
| l7policies                  |                                      |
| loadbalancers               | 388c601d-9b0b-4151-adee-2d995b13c72f |
| name                        | listenerweb                          |
| operating_status            | OFFLINE                              |
| project_id                  | 10e6f16ae2aa4c7b899e737d87d65129     |
| protocol                    | HTTP                                 |
| protocol_port               | 80                                   |
| provisioning_status         | PENDING_CREATE                       |
| sni_container_refs          | []                                   |
| timeout_client_data         | 50000                                |
| timeout_member_connect      | 5000                                 |
| timeout_member_data         | 50000                                |
| timeout_tcp_inspect         | 0                                    |
| updated_at                  | None                                 |
| client_ca_tls_container_ref | None                                 |
| client_authentication       | NONE                                 |
| client_crl_container_ref    | None                                 |
| allowed_cidrs               | None                                 |
+-----------------------------+--------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack loadbalancer listener show listenerweb
+-----------------------------+--------------------------------------+
| Field                       | Value                                |
+-----------------------------+--------------------------------------+
| admin_state_up              | True                                 |
| connection_limit            | -1                                   |
| created_at                  | 2020-07-29T01:18:15                  |
| default_pool_id             | None                                 |
| default_tls_container_ref   | None                                 |
| description                 |                                      |
| id                          | ab46bb22-2260-4082-ab78-de079484e730 |
| insert_headers              | None                                 |
| l7policies                  |                                      |
| loadbalancers               | 388c601d-9b0b-4151-adee-2d995b13c72f |
| name                        | listenerweb                          |
| operating_status            | ONLINE                               |
| project_id                  | 10e6f16ae2aa4c7b899e737d87d65129     |
| protocol                    | HTTP                                 |
| protocol_port               | 80                                   |
| provisioning_status         | ACTIVE                               |
| sni_container_refs          | []                                   |
| timeout_client_data         | 50000                                |
| timeout_member_connect      | 5000                                 |
| timeout_member_data         | 50000                                |
| timeout_tcp_inspect         | 0                                    |
| updated_at                  | 2020-07-29T01:18:24                  |
| client_ca_tls_container_ref | None                                 |
| client_authentication       | NONE                                 |
| client_crl_container_ref    | None                                 |
| allowed_cidrs               | None                                 |
+-----------------------------+--------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack loadbalancer pool create --name poolweb --protocol HTTP  --listener listenerweb --lb-algorithm ROUND_ROBIN
+----------------------+--------------------------------------+
| Field                | Value                                |
+----------------------+--------------------------------------+
| admin_state_up       | True                                 |
| created_at           | 2020-07-29T01:20:49                  |
| description          |                                      |
| healthmonitor_id     |                                      |
| id                   | 0f838e7b-d4d1-4ec8-ac75-f599c0e841e0 |
| lb_algorithm         | ROUND_ROBIN                          |
| listeners            | ab46bb22-2260-4082-ab78-de079484e730 |
| loadbalancers        | 388c601d-9b0b-4151-adee-2d995b13c72f |
| members              |                                      |
| name                 | poolweb                              |
| operating_status     | OFFLINE                              |
| project_id           | 10e6f16ae2aa4c7b899e737d87d65129     |
| protocol             | HTTP                                 |
| provisioning_status  | PENDING_CREATE                       |
| session_persistence  | None                                 |
| updated_at           | None                                 |
| tls_container_ref    | None                                 |
| ca_tls_container_ref | None                                 |
| crl_container_ref    | None                                 |
| tls_enabled          | False                                |
+----------------------+--------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack loadbalancer pool list
+--------------------------------------+---------+----------------------------------+---------------------+----------+--------------+----------------+
| id                                   | name    | project_id                       | provisioning_status | protocol | lb_algorithm | admin_state_up |
+--------------------------------------+---------+----------------------------------+---------------------+----------+--------------+----------------+
| 0f838e7b-d4d1-4ec8-ac75-f599c0e841e0 | poolweb | 10e6f16ae2aa4c7b899e737d87d65129 | ACTIVE              | HTTP     | ROUND_ROBIN  | True           |
+--------------------------------------+---------+----------------------------------+---------------------+----------+--------------+----------------+
(overcloud) [stack@undercloud ~]$ IPWEB01=$(openstack server show web01 -c addresses -f value | cut -d"=" -f2)
(overcloud) [stack@undercloud ~]$ IPWEB02=$(openstack server show web02 -c addresses -f value | cut -d"=" -f2)
(overcloud) [stack@undercloud ~]$ openstack loadbalancer member create --name web01 --address $IPWEB01 --protocol-port 80 poolweb
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| address             | 192.168.100.97                       |
| admin_state_up      | True                                 |
| created_at          | 2020-07-29T01:23:10                  |
| id                  | 96fd68af-e934-4e06-895f-8361ad472dda |
| name                | web01                                |
| operating_status    | NO_MONITOR                           |
| project_id          | 10e6f16ae2aa4c7b899e737d87d65129     |
| protocol_port       | 80                                   |
| provisioning_status | PENDING_CREATE                       |
| subnet_id           | None                                 |
| updated_at          | None                                 |
| weight              | 1                                    |
| monitor_port        | None                                 |
| monitor_address     | None                                 |
| backup              | False                                |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack loadbalancer member create --name web02 --address $IPWEB02 --protocol-port 80 poolweb
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| address             | 192.168.100.176                      |
| admin_state_up      | True                                 |
| created_at          | 2020-07-29T01:25:45                  |
| id                  | 4b322e8f-f96b-492c-bb14-71649eb1942e |
| name                | web02                                |
| operating_status    | NO_MONITOR                           |
| project_id          | 10e6f16ae2aa4c7b899e737d87d65129     |
| protocol_port       | 80                                   |
| provisioning_status | PENDING_CREATE                       |
| subnet_id           | None                                 |
| updated_at          | None                                 |
| weight              | 1                                    |
| monitor_port        | None                                 |
| monitor_address     | None                                 |
| backup              | False                                |
+---------------------+--------------------------------------+
(overcloud) [stack@undercloud ~]$ VIP=$(openstack loadbalancer show lbweb -c vip_address -f value)
(overcloud) [stack@undercloud ~]$ PORTID=$(openstack port list --fixed-ip ip-address=$VIP -c ID -f value)
(overcloud) [stack@undercloud ~]$ openstack floating ip create --port $PORTID public
<<OMITTED>>
| fixed_ip_address    | 192.168.100.137                                                                                                                                                                            |
| floating_ip_address | 10.0.0.86                                                                                                                                                                                  |
| floating_network_id | 2a77e9ca-baf6-4e8e-94a4-db641a95bef0                                                                                                                                                       |
| id                  | 55931d07-ceb0-4512-b514-3db525f361cc                                                                                                                                                       |
| location            | Munch({'cloud': '', 'region_name': 'regionOne', 'zone': None, 'project': Munch({'id': '10e6f16ae2aa4c7b899e737d87d65129', 'name': 'admin', 'domain_id': None, 'domain_name': 'Default'})}) |
| name                | 10.0.0.86                                                                                                                                                                                  |
| port_details        | None                                                                                                                                                                                       |
| port_id             | 2ff8ee12-01a7-4472-a984-4a612ddd0bf8                                                                                                                                                       |
| project_id          | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                                           |
| qos_policy_id       | None                                                                                                                                                                                       |
| revision_number     | 0                                                                                                                                                                                          |
| router_id           | 3607a0a9-8ce6-4e61-8423-6e3c56e1a3d0                                                                                                                                                       |
| status              | DOWN                                                                                                                                                                                       |
| subnet_id           | None                                                                                                                                                                                       |
| tags                | []                                                                                                                                                                                         |
| updated_at          | 2020-07-29T01:28:18Z                                                                                                                                                                       |
+---------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ curl 10.0.0.86      
Welcome to 192.168.100.176
(overcloud) [stack@undercloud ~]$ curl 10.0.0.86
Welcome to 192.168.100.97


# Task 3 :
# Capture Network traffic and analyze. Provide your analysis of the network traffic.

(overcloud) [stack@undercloud ~]$ openstack floating ip create --floating-ip-address 10.0.0.70 public
<<OMITTED>>
| floating_ip_address | 10.0.0.70                                                                                                                                                                                  |
| floating_network_id | 2a77e9ca-baf6-4e8e-94a4-db641a95bef0                                                                                                                                                       |
| id                  | 5d9fdabd-9a2f-4fd6-8ded-f664aaba270f                                                                                                                                                       |
| location            | Munch({'cloud': '', 'region_name': 'regionOne', 'zone': None, 'project': Munch({'id': '10e6f16ae2aa4c7b899e737d87d65129', 'name': 'admin', 'domain_id': None, 'domain_name': 'Default'})}) |
| name                | 10.0.0.70                                                                                                                                                                                  |
| port_details        | None                                                                                                                                                                                       |
| port_id             | None                                                                                                                                                                                       |
| project_id          | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                                           |
| qos_policy_id       | None                                                                                                                                                                                       |
| revision_number     | 0                                                                                                                                                                                          |
| router_id           | None                                                                                                                                                                                       |
| status              | DOWN                                                                                                                                                                                       |
| subnet_id           | None                                                                                                                                                                                       |
| tags                | []                                                                                                                                                                                         |
| updated_at          | 2020-07-29T02:12:26Z                                                                                                                                                                       |
+---------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack server add floating ip web01 10.0.0.70


(overcloud) [stack@undercloud ~]$ openstack server show web01 -f value -c addresses  
private=192.168.100.97, 10.0.0.70
(overcloud) [stack@undercloud ~]$ openstack server show web02 -f value -c addresses  
private=192.168.100.176

# login web01, from web01(192.168.100.97) ping web02(192.168.100.176)
(overcloud) [stack@undercloud ~]$ openstack server ssh web01 --login cirros
Warning: Permanently added '10.0.0.70' (ECDSA) to the list of known hosts.
cirros@10.0.0.70's password: 
$ ping 192.168.100.176
PING 192.168.100.176 (192.168.100.176): 56 data bytes
64 bytes from 192.168.100.176: seq=0 ttl=64 time=4.326 ms
64 bytes from 192.168.100.176: seq=1 ttl=64 time=0.881 ms
64 bytes from 192.168.100.176: seq=2 ttl=64 time=0.597 ms
64 bytes from 192.168.100.176: seq=3 ttl=64 time=0.914 ms
64 bytes from 192.168.100.176: seq=4 ttl=64 time=0.634 ms
64 bytes from 192.168.100.176: seq=5 ttl=64 time=0.541 ms
64 bytes from 192.168.100.176: seq=6 ttl=64 time=0.609 ms
64 bytes from 192.168.100.176: seq=7 ttl=64 time=0.904 ms
64 bytes from 192.168.100.176: seq=8 ttl=64 time=0.528 ms
64 bytes from 192.168.100.176: seq=9 ttl=64 time=0.468 ms
<<OMITTED>>

# install wireshark on compute node 
(undercloud) [stack@undercloud ~]$ sudo cp /etc/yum.repos.d/open.repo /tmp/
(undercloud) [stack@undercloud ~]$ sudo chmod a+r /tmp/open.repo
(undercloud) [stack@undercloud ~]$ openstack server list 
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+
| ID                                   | Name                    | Status | Networks            | Image          | Flavor  |
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+
| 7083d62e-9eb4-436b-9ceb-a3e8eec9947d | overcloud-controller-1  | ACTIVE | ctlplane=192.0.2.18 | overcloud-full | control |
| 13adde5a-5439-4248-8f0c-af709c1c5683 | overcloud-controller-0  | ACTIVE | ctlplane=192.0.2.17 | overcloud-full | control |
| 2758123f-6b04-4887-b47c-6fe8521cccc7 | overcloud-controller-2  | ACTIVE | ctlplane=192.0.2.8  | overcloud-full | control |
| 3c8172e1-d17c-49fa-84e0-0573c7b11a36 | overcloud-novacompute-1 | ACTIVE | ctlplane=192.0.2.21 | overcloud-full | compute |
| efab2bf9-5777-467d-8eab-094151c862d1 | overcloud-novacompute-0 | ACTIVE | ctlplane=192.0.2.15 | overcloud-full | compute |
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+
(undercloud) [stack@undercloud ~]$ scp /tmp/open.repo heat-admin@192.0.2.15:~
Warning: Permanently added '192.0.2.15' (ECDSA) to the list of known hosts.
open.repo           
[root@overcloud-novacompute-0 ~]# cp /home/heat-admin/open.repo /etc/yum.repos.d/ 
[root@overcloud-novacompute-0 ~]# yum repolist 
Updating Subscription Management repositories.
Unable to read consumer identity
/usr/lib/python3.6/site-packages/dateutil/parser/_parser.py:70: UnicodeWarning: decode() called on unicode string, see https://bugzilla.redhat.com/show_bug.cgi?id=1693751
  instream = instream.decode()

This system is not registered to Red Hat Subscription Management. You can use subscription-manager to register.
rhel-8-for-x86_64-appstream-rpms                                                                                         155 MB/s |  14 MB     00:00    
rhel-8-for-x86_64-baseos-rpms                                                                                            162 MB/s |  14 MB     00:00    
rhel-8-for-x86_64-highavailability-rpms                                                                                   52 MB/s | 1.4 MB     00:00    
openstack-16-for-rhel-8-x86_64-rpms                                                                                       59 MB/s | 1.1 MB     00:00    
fast-datapath-for-rhel-8-x86_64-rpms                                                                                     6.6 MB/s |  43 kB     00:00    
ansible-2.8-for-rhel-8-x86_64-rpms                                                                                        68 MB/s | 553 kB     00:00    
rhceph-4-tools-for-rhel-8-x86_64-rpms                                                                                    8.8 MB/s |  61 kB     00:00    
repo id                                                                  repo name                                                                 status
ansible-2.8-for-rhel-8-x86_64-rpms                                       ansible-2.8-for-rhel-8-x86_64-rpms                                          10
fast-datapath-for-rhel-8-x86_64-rpms                                     fast-datapath-for-rhel-8-x86_64-rpms                                        75
openstack-16-for-rhel-8-x86_64-rpms                                      openstack-16-for-rhel-8-x86_64-rpms                                        754
rhceph-4-tools-for-rhel-8-x86_64-rpms                                    rhceph-4-tools-for-rhel-8-x86_64-rpms                                       63
rhel-8-for-x86_64-appstream-rpms                                         rhel-8-for-x86_64-appstream-rpms                                          8589
rhel-8-for-x86_64-baseos-rpms                                            rhel-8-for-x86_64-baseos-rpms                                             3675
rhel-8-for-x86_64-highavailability-rpms                                  rhel-8-for-x86_64-highavailability-rpms                                    156

[root@overcloud-novacompute-0 ~]# yum install -y wireshark
<<OMITTED>>
Installed:
  wireshark-1:2.6.2-11.el8.x86_64                    xdg-utils-1.1.2-5.el8.noarch                       iso-codes-3.79-2.el8.noarch                      
  xcb-util-wm-0.4.1-12.el8.x86_64                    webrtc-audio-processing-0.3-8.el8.x86_64           hicolor-icon-theme-0.17-2.el8.noarch             
  lcms2-2.9-2.el8.x86_64                             libwebp-1.0.0-1.el8.x86_64                         libXi-1.7.9-7.el8.x86_64                         
  libtheora-1:1.1.1-21.el8.x86_64                    libXtst-1.2.3-7.el8.x86_64                         flac-libs-1.3.2-9.el8.x86_64                     
  gstreamer1-plugins-bad-free-1.14.0-5.el8.x86_64    gstreamer1-1.14.0-3.el8.x86_64                     libglvnd-egl-1:1.0.1-0.9.git5baa1e5.el8.x86_64   
  xcb-util-image-0.4.0-9.el8.x86_64                  libdvdnav-5.0.3-8.el8.x86_64                       libsrtp-1.5.4-8.el8.x86_64                       
  soundtouch-2.0.0-2.el8.x86_64                      libmpcdec-1.2.6-20.el8.x86_64                      graphite2-1.3.10-10.el8.x86_64                   
  libogg-2:1.3.2-10.el8.x86_64                       orc-0.4.28-2.el8.x86_64                            libwayland-egl-1.15.0-1.el8.x86_64               
  libSM-1.2.3-1.el8.x86_64                           libwayland-server-1.15.0-1.el8.x86_64              libwayland-cursor-1.15.0-1.el8.x86_64            
  libXft-2.3.2-10.el8.x86_64                         xcb-util-keysyms-0.4.0-7.el8.x86_64                libXfixes-5.0.3-7.el8.x86_64                     
  libglvnd-1:1.0.1-0.9.git5baa1e5.el8.x86_64         libglvnd-gles-1:1.0.1-0.9.git5baa1e5.el8.x86_64    libXxf86vm-1.1.4-9.el8.x86_64                    
  xcb-util-0.4.0-10.el8.x86_64                       libthai-0.1.27-2.el8.x86_64                        opus-1.3-0.4.beta.el8.x86_64                     
  libXdamage-1.1.4-14.el8.x86_64                     libdvdread-5.0.3-9.el8.x86_64                      glx-utils-8.3.0-9.el8.x86_64                     
  libsndfile-1.0.28-8.el8.x86_64                     qt5-qtdeclarative-5.11.1-3.el8.x86_64              harfbuzz-1.7.5-3.el8.x86_64                      
  xcb-util-renderutil-0.3.9-10.el8.x86_64            libwayland-client-1.15.0-1.el8.x86_64              libX11-xcb-1.6.7-1.el8.x86_64                    
  qt5-qtmultimedia-5.11.1-2.el8.x86_64               libasyncns-0.8-14.el8.x86_64                       libsmi-0.4.8-22.el8.x86_64                       
  libdatrie-0.2.9-7.el8.x86_64                       qt5-qtxmlpatterns-5.11.1-2.el8.x86_64              libxshmfence-1.3-2.el8.x86_64                    
  libvisual-1:0.4.0-24.el8.x86_64                    gsm-1.0.17-5.el8.x86_64                            gstreamer1-plugins-base-1.14.0-4.el8.x86_64      
  openal-soft-1.18.2-7.el8.x86_64                    libXv-1.0.11-7.el8.x86_64                          desktop-file-utils-0.23-8.el8.x86_64             
  libglvnd-glx-1:1.0.1-0.9.git5baa1e5.el8.x86_64     qt5-qtbase-gui-5.11.1-7.el8.x86_64                 libjpeg-turbo-1.5.3-10.el8.x86_64                
  libvorbis-1:1.3.6-2.el8.x86_64                     alsa-lib-1.1.9-4.el8.x86_64                        wireshark-cli-1:2.6.2-11.el8.x86_64              
  pango-1.42.4-6.el8.x86_64                          qt5-qtbase-5.11.1-7.el8.x86_64                     librsvg2-2.42.7-3.el8.x86_64                     
  libdrm-2.4.98-2.el8.x86_64                         qt5-qtbase-common-5.11.1-7.el8.noarch              pulseaudio-libs-glib2-11.1-23.el8.x86_64         
  pulseaudio-libs-11.1-23.el8.x86_64                 libICE-1.0.9-15.el8.x86_64                         fribidi-1.0.4-7.el8_1.x86_64                     
  mesa-libEGL-19.1.4-3.el8_1.x86_64                  wget-1.19.5-8.el8_1.1.x86_64                       mesa-libglapi-19.1.4-3.el8_1.x86_64              
  mesa-libgbm-19.1.4-3.el8_1.x86_64                  mesa-libGL-19.1.4-3.el8_1.x86_64                   xml-common-0.6.3-50.el8.noarch                   
  pcre2-utf16-10.32-1.el8.x86_64                     gdk-pixbuf2-2.36.12-5.el8.x86_64                  

Complete!

# Get instance compute info and libvirt instance domain name 
(overcloud) [stack@undercloud ~]$ openstack server show web01 -f value -c 'OS-EXT-SRV-ATTR:host'
overcloud-novacompute-0.localdomain
(overcloud) [stack@undercloud ~]$ openstack server show web01 -f value -c 'OS-EXT-SRV-ATTR:instance_name'
instance-00000005

# dump interface info and get target dev
[root@overcloud-novacompute-0 ~]# virsh dumpxml instance-00000005 | grep "<interface" -A12
    <interface type='bridge'>
      <mac address='fa:16:3e:a2:e6:89'/>
      <source bridge='br-int'/>
      <virtualport type='openvswitch'>
        <parameters interfaceid='1bf7ff06-eb78-479c-9140-f5c630f72c0b'/>
      </virtualport>
      <target dev='tap1bf7ff06-eb'/>
      <model type='virtio'/>
      <driver name='vhost' rx_queue_size='512'/>
      <mtu size='1442'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>

# tcpdump from device 
[root@overcloud-novacompute-0 ~]# tcpdump -i tap1bf7ff06-eb -n -nn host 192.168.100.176 
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on tap1bf7ff06-eb, link-type EN10MB (Ethernet), capture size 262144 bytes
02:37:03.801912 IP 192.168.100.97 > 192.168.100.176: ICMP echo request, id 36353, seq 1258, length 64
02:37:03.802680 IP 192.168.100.176 > 192.168.100.97: ICMP echo reply, id 36353, seq 1258, length 64
02:37:04.802325 IP 192.168.100.97 > 192.168.100.176: ICMP echo request, id 36353, seq 1259, length 64
02:37:04.802566 IP 192.168.100.176 > 192.168.100.97: ICMP echo reply, id 36353, seq 1259, length 64
02:37:05.802617 IP 192.168.100.97 > 192.168.100.176: ICMP echo request, id 36353, seq 1260, length 64
02:37:05.802863 IP 192.168.100.176 > 192.168.100.97: ICMP echo reply, id 36353, seq 1260, length 64
02:37:06.803016 IP 192.168.100.97 > 192.168.100.176: ICMP echo request, id 36353, seq 1261, length 64
02:37:06.803296 IP 192.168.100.176 > 192.168.100.97: ICMP echo reply, id 36353, seq 1261, length 64
^C
8 packets captured
8 packets received by filter
0 packets dropped by kernel




# Task 4 :
# Review the OVN Network - Packet Tracing and Switching configuration
# Create private network, subnet and router. Attach cirros instance to private network.
#   Show the logical ports associated with the instances.
#   Show the logical datapaths defined in the OVN Southbound DB
#   Show the logical flow from the OVN Southbound DB related to the private datapath
#   Demonstrate what happens to packets from a logical point of view. Hint - Use ovn-trace utility.
#   Show the contents of the most common database tables in the northbound and southbound databases.
#     List Logical Switches
#     List Logical Switches Ports
#     List ACLs
#     List routers
#     List router Ports
#     Get chassis information
#     Identify how OVN may transmit logical dataplane packets to this chassis
#     Get information about gateway chassis
#     List MAC Binding on OVN Database
#     List NAT on OVN Database

# Create private network, subnet and router. Attach cirros instance to private network.
(overcloud) [stack@undercloud ~]$ openstack network show private 
<<OMITTED>>
| name                      | private                                                                                                                                                          |
| port_security_enabled     | True                                                                                                                                                             |
| project_id                | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| provider:network_type     | geneve                                                                                                                                                           |
| provider:physical_network | None                                                                                                                                                             |
| provider:segmentation_id  | 66                                                                                                                                                               |
| qos_policy_id             | None                                                                                                                                                             |
| revision_number           | 2                                                                                                                                                                |
| router:external           | Internal                                                                                                                                                         |
| segments                  | None                                                                                                                                                             |
| shared                    | False                                                                                                                                                            |
| status                    | ACTIVE                                                                                                                                                           |
| subnets                   | 8a1b8c36-d7a9-4222-a9ac-5ceace6d69bf                                                                                                                             |
| tags                      |                                                                                                                                                                  |
| updated_at                | 2020-07-29T01:10:38Z                                                                                                                                             |
+---------------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+

(overcloud) [stack@undercloud ~]$ openstack subnet show sub_private 
<<OMITTED>>
| enable_dhcp       | True                                                                                                                                                             |
| gateway_ip        | 192.168.100.1                                                                                                                                                    |
| host_routes       |                                                                                                                                                                  |
| id                | 8a1b8c36-d7a9-4222-a9ac-5ceace6d69bf                                                                                                                             |
| ip_version        | 4                                                                                                                                                                |
| ipv6_address_mode | None                                                                                                                                                             |
| ipv6_ra_mode      | None                                                                                                                                                             |
| location          | cloud='', project.domain_id=, project.domain_name='Default', project.id='10e6f16ae2aa4c7b899e737d87d65129', project.name='admin', region_name='regionOne', zone= |
| name              | sub_private                                                                                                                                                      |
| network_id        | a7b7d645-184d-4780-9b87-deedcf1cdb99                                                                                                                             |
| prefix_length     | None                                                                                                                                                             |
| project_id        | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                 |
| revision_number   | 0                                                                                                                                                                |
| segment_id        | None                                                                                                                                                             |
| service_types     |                                                                                                                                                                  |
| subnetpool_id     | None                                                                                                                                                             |
| tags              |                                                                                                                                                                  |
| updated_at        | 2020-07-29T01:10:38Z                                                                                                                                             |
+-------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack router show router_private
<<OMITTED>>
| created_at              | 2020-07-29T01:11:26Z                                                                                                                                                                  |
| description             |                                                                                                                                                                                       |
| external_gateway_info   | {"network_id": "2a77e9ca-baf6-4e8e-94a4-db641a95bef0", "external_fixed_ips": [{"subnet_id": "31697e86-75d3-466f-a48c-ea0770f9215e", "ip_address": "10.0.0.76"}], "enable_snat": true} |
| flavor_id               | None                                                                                                                                                                                  |
| id                      | 3607a0a9-8ce6-4e61-8423-6e3c56e1a3d0                                                                                                                                                  |
| interfaces_info         | [{"port_id": "849b14d7-8965-4d89-9bd2-f4551acd098b", "ip_address": "192.168.100.1", "subnet_id": "8a1b8c36-d7a9-4222-a9ac-5ceace6d69bf"}]                                             |
| location                | cloud='', project.domain_id=, project.domain_name='Default', project.id='10e6f16ae2aa4c7b899e737d87d65129', project.name='admin', region_name='regionOne', zone=                      |
| name                    | router_private                                                                                                                                                                        |
| project_id              | 10e6f16ae2aa4c7b899e737d87d65129                                                                                                                                                      |
| revision_number         | 3                                                                                                                                                                                     |
| routes                  |                                                                                                                                                                                       |
| status                  | ACTIVE                                                                                                                                                                                |
| tags                    |                                                                                                                                                                                       |
| updated_at              | 2020-07-29T01:11:55Z                                                                                                                                                                  |
+-------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack floating ip list
+--------------------------------------+---------------------+------------------+--------------------------------------+--------------------------------------+----------------------------------+
| ID                                   | Floating IP Address | Fixed IP Address | Port                                 | Floating Network                     | Project                          |
+--------------------------------------+---------------------+------------------+--------------------------------------+--------------------------------------+----------------------------------+
| 55931d07-ceb0-4512-b514-3db525f361cc | 10.0.0.86           | 192.168.100.137  | 2ff8ee12-01a7-4472-a984-4a612ddd0bf8 | 2a77e9ca-baf6-4e8e-94a4-db641a95bef0 | 10e6f16ae2aa4c7b899e737d87d65129 |
| 5d9fdabd-9a2f-4fd6-8ded-f664aaba270f | 10.0.0.70           | 192.168.100.97   | 1bf7ff06-eb78-479c-9140-f5c630f72c0b | 2a77e9ca-baf6-4e8e-94a4-db641a95bef0 | 10e6f16ae2aa4c7b899e737d87d65129 |
+--------------------------------------+---------------------+------------------+--------------------------------------+--------------------------------------+----------------------------------+
(overcloud) [stack@undercloud ~]$ openstack server show web01 -f value -c addresses 
private=192.168.100.97, 10.0.0.70
(overcloud) [stack@undercloud ~]$ openstack server show web01 -f value -c 'OS-EXT-SRV-ATTR:instance_name' 
instance-00000005
(overcloud) [stack@undercloud ~]$ openstack server show web01 -f value -c 'OS-EXT-SRV-ATTR:hypervisor_hostname' 
overcloud-novacompute-0.localdomain

# dump xml to get interface id
[root@overcloud-novacompute-0 ~]# virsh dumpxml instance-00000005 | grep "<interface" -A12
    <interface type='bridge'>
      <mac address='fa:16:3e:a2:e6:89'/>
      <source bridge='br-int'/>
      <virtualport type='openvswitch'>
        <parameters interfaceid='1bf7ff06-eb78-479c-9140-f5c630f72c0b'/>
      </virtualport>
      <target dev='tap1bf7ff06-eb'/>
      <model type='virtio'/>
      <driver name='vhost' rx_queue_size='512'/>
      <mtu size='1442'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>

# get ovn-dbs-bundle 
[root@overcloud-controller-0 ~]# podman ps | grep ovn-dbs
fc41ae2ce742  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-ovn-northd:16.0-81                  /bin/bash /usr/lo...  3 hours ago   Up 3 hours ago         ovn-dbs-bundle-podman-1

[root@overcloud-controller-0 ~]# podman exec -it ovn-dbs-bundle-podman-1 ovn-nbctl show | grep '192.168.100.97"]' -B4
switch 27a67d17-20a9-4de1-9d6c-e561d37b3b91 (neutron-a7b7d645-184d-4780-9b87-deedcf1cdb99) (aka private)
    port 2ff8ee12-01a7-4472-a984-4a612ddd0bf8 (aka octavia-lb-388c601d-9b0b-4151-adee-2d995b13c72f)
        addresses: ["fa:16:3e:36:21:8f 192.168.100.137"]
    port 1bf7ff06-eb78-479c-9140-f5c630f72c0b
        addresses: ["fa:16:3e:a2:e6:89 192.168.100.97"]


#   Show the logical datapaths defined in the OVN Southbound DB
[root@overcloud-controller-0 ~]# podman exec -ti ovn-dbs-bundle-podman-1  ovn-sbctl list datapath_binding
_uuid               : 025fcd70-cae3-40ef-a50d-e8c0d37d2522
external_ids        : {logical-router="07ca9cf2-9c88-4bef-acf2-18ccb9539ca5", name="neutron-3607a0a9-8ce6-4e61-8423-6e3c56e1a3d0", "name2"=router_private}
tunnel_key          : 5

_uuid               : 36417a75-0731-4ff6-a73f-68a8fc391751
external_ids        : {logical-switch="74e58afe-8288-47c3-9c1e-f7ac03449f40", name="neutron-c06be859-24be-4319-9c09-aa68a8d24853", "name2"=provider}
tunnel_key          : 2

_uuid               : f1299f8a-5a0a-49e5-8fe4-4260f0951af5
external_ids        : {logical-switch="cd5bd34c-3909-4cba-9002-ca11bb3e3ff3", name="neutron-09d3a74b-b1e0-4b66-81ed-e303dd21eb7a", "name2"=lb-mgmt-net}
tunnel_key          : 1

_uuid               : c84b2da2-09b4-4f97-b455-d37d1b40b14e
external_ids        : {logical-switch="27a67d17-20a9-4de1-9d6c-e561d37b3b91", name="neutron-a7b7d645-184d-4780-9b87-deedcf1cdb99", "name2"=private}
tunnel_key          : 3

_uuid               : 2df0c3ef-897f-4815-af36-3e21aae26913
external_ids        : {logical-switch="6b1ee2dd-c338-46e8-bb6c-3d9f820ac0dc", name="neutron-2a77e9ca-baf6-4e8e-94a4-db641a95bef0", "name2"=public}
tunnel_key          : 4

# Show the logical flow from the OVN Southbound DB related to the private datapath
[root@overcloud-controller-0 ~]# podman exec -ti ovn-dbs-bundle-podman-1  ovn-sbctl lflow-list private
Datapath: "neutron-a7b7d645-184d-4780-9b87-deedcf1cdb99" aka "private" (c84b2da2-09b4-4f97-b455-d37d1b40b14e)  Pipeline: ingress
  table=0 (ls_in_port_sec_l2  ), priority=100  , match=(eth.src[40]), action=(drop;)
  table=0 (ls_in_port_sec_l2  ), priority=100  , match=(vlan.present), action=(drop;)
  table=0 (ls_in_port_sec_l2  ), priority=50   , match=(inport == "10d7df33-88eb-4829-9998-16973ea47397"), action=(next;)
  table=0 (ls_in_port_sec_l2  ), priority=50   , match=(inport == "1bf7ff06-eb78-479c-9140-f5c630f72c0b" && eth.src == {fa:16:3e:a2:e6:89}), action=(next;)
  table=0 (ls_in_port_sec_l2  ), priority=50   , match=(inport == "849b14d7-8965-4d89-9bd2-f4551acd098b"), action=(next;)
  table=0 (ls_in_port_sec_l2  ), priority=50   , match=(inport == "a48d07b7-9c84-47e7-a388-d04fd92d616c" && eth.src == {fa:16:3e:6a:65:af}), action=(next;)
  table=0 (ls_in_port_sec_l2  ), priority=50   , match=(inport == "fe98e1ca-15b2-43b4-b59d-1853e8d17757" && eth.src == {fa:16:3e:87:ac:49}), action=(next;)
  table=1 (ls_in_port_sec_ip  ), priority=90   , match=(inport == "1bf7ff06-eb78-479c-9140-f5c630f72c0b" && eth.src == fa:16:3e:a2:e6:89 && ip4.src == 0.0.0.0 && ip4.dst == 255.255.255.255 && udp.src == 68 && udp.dst == 67), action=(next;)
  table=1 (ls_in_port_sec_ip  ), priority=90   , match=(inport == "1bf7ff06-eb78-479c-9140-f5c630f72c0b" && eth.src == fa:16:3e:a2:e6:89 && ip4.src == {192.168.100.97}), action=(next;)
<<OMITTED>>

# Demonstrate what happens to packets from a logical point of view. Hint - Use ovn-trace utility.

(overcloud) [stack@undercloud ~]$ openstack server show web01 -f value -c addresses 
private=192.168.100.97, 10.0.0.70
(overcloud) [stack@undercloud ~]$ openstack server show web02 -f value -c addresses 
private=192.168.100.176

[root@overcloud-controller-0 ~]# podman exec -it ovn-dbs-bundle-podman-1 ovn-nbctl show | grep '192.168.100.97"]' -B1
    port 1bf7ff06-eb78-479c-9140-f5c630f72c0b
        addresses: ["fa:16:3e:a2:e6:89 192.168.100.97"]

[root@overcloud-controller-0 ~]# podman exec -it ovn-dbs-bundle-podman-1 ovn-nbctl show | grep '192.168.100.176"]' -B1
    port fe98e1ca-15b2-43b4-b59d-1853e8d17757
        addresses: ["fa:16:3e:87:ac:49 192.168.100.176"]

[root@overcloud-controller-0 ~]# ap=1bf7ff06-eb78-479c-9140-f5c630f72c0b
[root@overcloud-controller-0 ~]# bp=fe98e1ca-15b2-43b4-b59d-1853e8d17757
[root@overcloud-controller-0 ~]# AP_MAC=fa:16:3e:a2:e6:89
[root@overcloud-controller-0 ~]# BP_MAC=fa:16:3e:87:ac:49

[root@overcloud-controller-0 ~]# podman exec -ti ovn-dbs-bundle-podman-1 ovn-trace  private "inport == \"$ap\" && eth.src == $AP_MAC && eth.dst == $BP_MAC"
# reg14=0x3,vlan_tci=0x0000,dl_src=fa:16:3e:a2:e6:89,dl_dst=fa:16:3e:87:ac:49,dl_type=0x0000

ingress(dp="private", inport="1bf7ff")
--------------------------------------
 0. ls_in_port_sec_l2 (ovn-northd.c:4360): inport == "1bf7ff" && eth.src == {fa:16:3e:a2:e6:89}, priority 50, uuid 0ed254ab
    next;
17. ls_in_l2_lkup (ovn-northd.c:6330): eth.dst == fa:16:3e:87:ac:49, priority 50, uuid 79b4a08b
    outport = "fe98e1";
    output;

egress(dp="private", inport="1bf7ff", outport="fe98e1")
-------------------------------------------------------
 9. ls_out_port_sec_l2 (ovn-northd.c:4425): outport == "fe98e1" && eth.dst == {fa:16:3e:87:ac:49}, priority 50, uuid 8478decc
    output;
    /* output to "fe98e1", type "" */


# Show the contents of the most common database tables in the northbound and southbound databases.
#   List Logical Switches
[root@overcloud-controller-0 ~]#  podman exec -ti ovn-dbs-bundle-podman-1 ovn-nbctl list logical_switch
_uuid               : cd5bd34c-3909-4cba-9002-ca11bb3e3ff3
acls                : []
dns_records         : []
external_ids        : {"neutron:mtu"="1442", "neutron:network_name"=lb-mgmt-net, "neutron:qos_policy_id"=null, "neutron:revision_number"="2"}
load_balancer       : []
name                : "neutron-09d3a74b-b1e0-4b66-81ed-e303dd21eb7a"
other_config        : {}
ports               : [0cd1213c-8a3a-4d4e-9b79-fe06c5b2d0eb, 5636d333-8ca2-44e7-9947-8e8996a915f0, d2d3f731-f1fc-46f3-b3c5-bc6cecce561f, e4ce790a-4eb4-44ae-be18-904a53b22a7a, e75089c1-e84a-4c75-a93f-db01159e5af8]
qos_rules           : []

_uuid               : 6b1ee2dd-c338-46e8-bb6c-3d9f820ac0dc
acls                : []
dns_records         : []
external_ids        : {"neutron:mtu"="1500", "neutron:network_name"=public, "neutron:qos_policy_id"=null, "neutron:revision_number"="2"}
load_balancer       : []
name                : "neutron-2a77e9ca-baf6-4e8e-94a4-db641a95bef0"
other_config        : {}
ports               : [12048ec6-6a0c-4d03-bb12-5fc883aa442b, 2e04efc5-065c-43f9-b19b-a97aa47a213e, b26a5251-cf63-464d-8e5e-e482fb6de493]
qos_rules           : []

_uuid               : 74e58afe-8288-47c3-9c1e-f7ac03449f40
acls                : []
dns_records         : []
external_ids        : {"neutron:mtu"="1500", "neutron:network_name"=provider, "neutron:qos_policy_id"=null, "neutron:revision_number"="2"}
load_balancer       : []
name                : "neutron-c06be859-24be-4319-9c09-aa68a8d24853"
other_config        : {}
ports               : [3a4a4f1d-81d8-4ae4-941d-ff21c6f3a4f5, 43b17245-1fe7-4b17-8a87-f11e8f12a5d0, 8452080d-544c-4fdc-8d02-9efb9ca440a4]
qos_rules           : []

_uuid               : 27a67d17-20a9-4de1-9d6c-e561d37b3b91
acls                : []
dns_records         : []
external_ids        : {"neutron:mtu"="1442", "neutron:network_name"=private, "neutron:qos_policy_id"=null, "neutron:revision_number"="2"}
load_balancer       : []
name                : "neutron-a7b7d645-184d-4780-9b87-deedcf1cdb99"
other_config        : {}
ports               : [0295558a-e64f-40c4-a590-67540eeeadf4, 895d95ab-c48e-43de-970f-b1a48d472ef2, ae717f6a-b51b-4ac8-8e78-de31a69b34ea, cebc13e7-d5c0-41d4-8fdc-ba8b96a72ce1, d42051e4-82d5-4160-b842-13ccdb3f0300, fabe8889-0a28-4bc9-b440-ef9085435e4d]
qos_rules           : []


# List Logical Switches Ports
[root@overcloud-controller-0 ~]#  podman exec -ti ovn-dbs-bundle-podman-1 ovn-nbctl list logical_switch_port
<<OMITTED>>
_uuid               : 8452080d-544c-4fdc-8d02-9efb9ca440a4
addresses           : ["fa:16:3e:37:2e:fd 192.168.60.110"]
dhcpv4_options      : 59858fa8-0393-442d-b940-9c2ef6beb081
dhcpv6_options      : []
dynamic_addresses   : []
enabled             : true
external_ids        : {"neutron:cidrs"="192.168.60.110/24", "neutron:device_id"="66c2207b-b1ab-49a1-b2c2-3b4427c77cb5", "neutron:device_owner"="compute:nova", "neutron:network_name"="neutron-c06be859-24be-4319-9c09-aa68a8d24853", "neutron:port_name"="", "neutron:project_id"="10e6f16ae2aa4c7b899e737d87d65129", "neutron:revision_number"="4", "neutron:security_group_ids"="3f784e4d-b315-46ee-96c7-91a97f4d4cd7"}
ha_chassis_group    : []
name                : "af168d65-2c00-411f-bfa3-48130336c054"
options             : {requested-chassis="overcloud-novacompute-1.localdomain"}
parent_name         : []
port_security       : ["fa:16:3e:37:2e:fd 192.168.60.110"]
tag                 : []
tag_request         : []
type                : ""
up                  : true

_uuid               : 3a4a4f1d-81d8-4ae4-941d-ff21c6f3a4f5
addresses           : ["fa:16:3e:8f:46:03 192.168.60.100"]
dhcpv4_options      : []
dhcpv6_options      : []
dynamic_addresses   : []
enabled             : true
external_ids        : {"neutron:cidrs"="192.168.60.100/24", "neutron:device_id"="ovnmeta-c06be859-24be-4319-9c09-aa68a8d24853", "neutron:device_owner"="network:dhcp", "neutron:network_name"="neutron-c06be859-24be-4319-9c09-aa68a8d24853", "neutron:port_name"="", "neutron:project_id"="10e6f16ae2aa4c7b899e737d87d65129", "neutron:revision_number"="2", "neutron:security_group_ids"=""}
ha_chassis_group    : []
name                : "b5f0335d-8049-4094-b314-3dab2f258320"
options             : {requested-chassis=""}
parent_name         : []
port_security       : []
tag                 : []
tag_request         : []
type                : localport
up                  : false


# List ACLs
[root@overcloud-controller-0 ~]#  podman exec -ti ovn-dbs-bundle-podman-1 ovn-nbctl list acl
<<OMITTED>>
_uuid               : 743b69ef-c5e8-4265-a63f-f41bb06e7fde
action              : allow-related
direction           : from-lport
external_ids        : {"neutron:security_group_rule_id"="d024c3cd-b72e-4d34-bd16-a5228ea17a99"}
log                 : false
match               : "inport == @pg_5a43a638_241f_4436_8209_590a888dd999 && ip4"
meter               : []
name                : []
priority            : 1002
severity            : []

_uuid               : 36ed1d5f-70f1-41ee-a2af-144a66dff852
action              : drop
direction           : from-lport
external_ids        : {}
log                 : false
match               : "inport == @neutron_pg_drop && ip"
meter               : []
name                : []
priority            : 1001
severity            : []

# List routers
[root@overcloud-controller-0 ~]#  podman exec -ti ovn-dbs-bundle-podman-1 ovn-nbctl list logical_router
_uuid               : 07ca9cf2-9c88-4bef-acf2-18ccb9539ca5
enabled             : true
external_ids        : {"neutron:gw_port_id"="7c14b2ce-c0eb-44d6-93bb-3962c10e3285", "neutron:revision_number"="3", "neutron:router_name"=router_private}
load_balancer       : []
name                : "neutron-3607a0a9-8ce6-4e61-8423-6e3c56e1a3d0"
nat                 : [4f0e331d-a3e2-4b9f-b936-1ce2cabf068d, 98ed922a-c2f1-4734-ac0a-6a54d4738776, d5a954bf-c1eb-425a-a7c4-6046765061fd]
options             : {}
policies            : []
ports               : [04b7b3a9-9564-4471-a50e-e4ba2f3c1423, bad38e27-e657-4d9d-a402-157e17031999]
static_routes       : [3e6a5dfe-8c4d-481c-8015-e4b1ec23389d]



# List router Ports
[root@overcloud-controller-0 ~]#  podman exec -ti ovn-dbs-bundle-podman-1 ovn-nbctl list logical_router
_uuid               : 07ca9cf2-9c88-4bef-acf2-18ccb9539ca5
enabled             : true
external_ids        : {"neutron:gw_port_id"="7c14b2ce-c0eb-44d6-93bb-3962c10e3285", "neutron:revision_number"="3", "neutron:router_name"=router_private}
load_balancer       : []
name                : "neutron-3607a0a9-8ce6-4e61-8423-6e3c56e1a3d0"
nat                 : [4f0e331d-a3e2-4b9f-b936-1ce2cabf068d, 98ed922a-c2f1-4734-ac0a-6a54d4738776, d5a954bf-c1eb-425a-a7c4-6046765061fd]
options             : {}
policies            : []
ports               : [04b7b3a9-9564-4471-a50e-e4ba2f3c1423, bad38e27-e657-4d9d-a402-157e17031999]
static_routes       : [3e6a5dfe-8c4d-481c-8015-e4b1ec23389d]
[root@overcloud-controller-0 ~]#  podman exec -ti ovn-dbs-bundle-podman-1 ovn-nbctl list logical_router_port
_uuid               : 04b7b3a9-9564-4471-a50e-e4ba2f3c1423
enabled             : []
external_ids        : {"neutron:network_name"="neutron-a7b7d645-184d-4780-9b87-deedcf1cdb99", "neutron:revision_number"="3", "neutron:router_name"="3607a0a9-8ce6-4e61-8423-6e3c56e1a3d0", "neutron:subnet_ids"="8a1b8c36-d7a9-4222-a9ac-5ceace6d69bf"}
gateway_chassis     : []
ha_chassis_group    : []
ipv6_ra_configs     : {}
mac                 : "fa:16:3e:95:04:ba"
name                : "lrp-849b14d7-8965-4d89-9bd2-f4551acd098b"
networks            : ["192.168.100.1/24"]
options             : {}
peer                : []

_uuid               : bad38e27-e657-4d9d-a402-157e17031999
enabled             : []
external_ids        : {"neutron:network_name"="neutron-2a77e9ca-baf6-4e8e-94a4-db641a95bef0", "neutron:revision_number"="4", "neutron:router_name"="3607a0a9-8ce6-4e61-8423-6e3c56e1a3d0", "neutron:subnet_ids"="31697e86-75d3-466f-a48c-ea0770f9215e"}
gateway_chassis     : [5b3f5442-9885-42c7-b126-ccb33367a7b2, 991a8994-c283-4ae9-8f29-2f4697152861, bebc2d8d-136c-48f5-b6e6-11de6dd7ebf5, bf0ba13a-53bf-4654-bc67-1ffa8b606997, fe641eff-972e-4402-b307-f671afc259cd]
ha_chassis_group    : []
ipv6_ra_configs     : {}
mac                 : "fa:16:3e:7c:e0:39"
name                : "lrp-7c14b2ce-c0eb-44d6-93bb-3962c10e3285"
networks            : ["10.0.0.76/24"]
options             : {reside-on-redirect-chassis="true"}
peer                : []

# Get chassis information
[root@overcloud-controller-0 ~]#  podman exec -ti ovn-dbs-bundle-podman-1 ovn-sbctl list chassis
_uuid               : 24e6f3b4-d65e-4ca1-8bf3-2d66d26ba49e
encaps              : [fa963eca-a8da-4fe4-a17c-dd86f4f413f0]
external_ids        : {datapath-type=system, iface-types="erspan,geneve,gre,internal,ip6erspan,ip6gre,lisp,patch,stt,system,tap,vxlan", neutron-metadata-
proxy-networks="36417a75-0731-4ff6-a73f-68a8fc391751,f1299f8a-5a0a-49e5-8fe4-4260f0951af5,c84b2da2-09b4-4f97-b455-d37d1b40b14e", "neutron:liveness_check_
at"="2020-07-29T03:30:31.761248+00:00", "neutron:metadata_liveness_check_at"="2020-07-29T03:30:31.810868+00:00", "neutron:ovn-metadata-id"="5844d2b8-9d23
-43be-b15d-47d60f0c5ba8", "neutron:ovn-metadata-sb-cfg"="1735", ovn-bridge-mappings="datacentre:br-ex", ovn-chassis-mac-mappings="", ovn-cms-options=""}
hostname            : "overcloud-novacompute-1.localdomain"
name                : "1ed969e9-f25e-41f8-9ad8-73a61270f534"
nb_cfg              : 1735
transport_zones     : []
vtep_logical_switches: []

<<OMITTED>>
_uuid               : 5c5da4ee-276a-4dbb-bc06-2e483792849c
encaps              : [06552059-7965-42c2-a6c0-5b2f71ed8ac6]
external_ids        : {datapath-type="", iface-types="erspan,geneve,gre,internal,ip6erspan,ip6gre,lisp,patch,stt,system,tap,vxlan", "neutron:liveness_check_at"="2020-07-29T03:30:31.683651+00:00", ovn-bridge-mappings="datacentre:br-ex", ovn-chassis-mac-mappings="", ovn-cms-options=""}
hostname            : "overcloud-controller-1.localdomain"
name                : "54f18db8-da0a-43bf-bd96-8b6ca3d96513"
nb_cfg              : 1735
transport_zones     : []
vtep_logical_switches: []

_uuid               : 6e7255ea-e9b3-474e-a9be-ee6370a7a43f
encaps              : [12647c29-7ecc-4bad-a098-afad2d005c8c]
external_ids        : {datapath-type=system, iface-types="erspan,geneve,gre,internal,ip6erspan,ip6gre,lisp,patch,stt,system,tap,vxlan", neutron-metadata-proxy-networks="c84b2da2-09b4-4f97-b455-d37d1b40b14e", "neutron:liveness_check_at"="2020-07-29T03:30:31.716676+00:00", "neutron:metadata_liveness_check_at"="2020-07-29T03:30:31.739823+00:00", "neutron:ovn-metadata-id"="e76591ab-357f-4acd-96a2-4b27c0dc645c", "neutron:ovn-metadata-sb-cfg"="1735", ovn-bridge-mappings="datacentre:br-ex", ovn-chassis-mac-mappings="", ovn-cms-options=""}
hostname            : "overcloud-novacompute-0.localdomain"
name                : "a59dafa1-7110-403f-81d1-51c78560e9b7"
nb_cfg              : 1735
transport_zones     : []
vtep_logical_switches: []

# Identify how OVN may transmit logical dataplane packets to this chassis
[root@overcloud-controller-0 ~]# podman exec -ti ovn-dbs-bundle-podman-1 ovn-sbctl list Encap
_uuid               : 06552059-7965-42c2-a6c0-5b2f71ed8ac6
chassis_name        : "54f18db8-da0a-43bf-bd96-8b6ca3d96513"
ip                  : "172.16.0.130"
options             : {csum="true"}
type                : geneve

_uuid               : 13033625-3b8e-4a0d-b01e-54abd22b06b8
chassis_name        : "4b85ca37-176f-4e5b-9420-1a26e3cdbb53"
ip                  : "172.16.0.33"
options             : {csum="true"}
type                : geneve

_uuid               : 12647c29-7ecc-4bad-a098-afad2d005c8c
chassis_name        : "a59dafa1-7110-403f-81d1-51c78560e9b7"
ip                  : "172.16.0.129"
options             : {csum="true"}
type                : geneve

_uuid               : fa963eca-a8da-4fe4-a17c-dd86f4f413f0
chassis_name        : "1ed969e9-f25e-41f8-9ad8-73a61270f534"
ip                  : "172.16.0.210"
options             : {csum="true"}
type                : geneve

_uuid               : 275f438f-e4c6-4af8-9ec2-af7bd7762ebd
chassis_name        : "f05e213c-5625-4474-9382-858dbbd391b3"
ip                  : "172.16.0.230"
options             : {csum="true"}
type                : geneve

# Get information about gateway chassis
[root@overcloud-controller-0 ~]# podman exec -ti ovn-dbs-bundle-podman-1 ovn-sbctl list Chassis
_uuid               : 24e6f3b4-d65e-4ca1-8bf3-2d66d26ba49e
encaps              : [fa963eca-a8da-4fe4-a17c-dd86f4f413f0]
external_ids        : {datapath-type=system, iface-types="erspan,geneve,gre,internal,ip6erspan,ip6gre,lisp,patch,stt,system,tap,vxlan", neutron-metadata-
proxy-networks="36417a75-0731-4ff6-a73f-68a8fc391751,f1299f8a-5a0a-49e5-8fe4-4260f0951af5,c84b2da2-09b4-4f97-b455-d37d1b40b14e", "neutron:liveness_check_
at"="2020-07-29T03:36:04.770805+00:00", "neutron:metadata_liveness_check_at"="2020-07-29T03:36:04.904036+00:00", "neutron:ovn-metadata-id"="5844d2b8-9d23
-43be-b15d-47d60f0c5ba8", "neutron:ovn-metadata-sb-cfg"="1761", ovn-bridge-mappings="datacentre:br-ex", ovn-chassis-mac-mappings="", ovn-cms-options=""}
hostname            : "overcloud-novacompute-1.localdomain"
name                : "1ed969e9-f25e-41f8-9ad8-73a61270f534"
nb_cfg              : 1761
transport_zones     : []
vtep_logical_switches: []

_uuid               : bb29d7c1-b14d-4a4b-94d4-ce385ce0a221
encaps              : [13033625-3b8e-4a0d-b01e-54abd22b06b8]
external_ids        : {datapath-type="", iface-types="erspan,geneve,gre,internal,ip6erspan,ip6gre,lisp,patch,stt,system,tap,vxlan", "neutron:liveness_check_at"="2020-07-29T03:36:04.937852+00:00", ovn-bridge-mappings="datacentre:br-ex", ovn-chassis-mac-mappings="", ovn-cms-options=""}
hostname            : "overcloud-controller-2.localdomain"
name                : "4b85ca37-176f-4e5b-9420-1a26e3cdbb53"
nb_cfg              : 1761
transport_zones     : []
vtep_logical_switches: []

_uuid               : 00a6400d-cff5-445f-b0d3-540daf30746e
encaps              : [275f438f-e4c6-4af8-9ec2-af7bd7762ebd]
external_ids        : {datapath-type="", iface-types="erspan,geneve,gre,internal,ip6erspan,ip6gre,lisp,patch,stt,system,tap,vxlan", "neutron:liveness_check_at"="2020-07-29T03:36:04.725854+00:00", ovn-bridge-mappings="datacentre:br-ex", ovn-chassis-mac-mappings="", ovn-cms-options=""}
hostname            : "overcloud-controller-0.localdomain"
name                : "f05e213c-5625-4474-9382-858dbbd391b3"
nb_cfg              : 1761
transport_zones     : []
vtep_logical_switches: []

_uuid               : 5c5da4ee-276a-4dbb-bc06-2e483792849c
encaps              : [06552059-7965-42c2-a6c0-5b2f71ed8ac6]
external_ids        : {datapath-type="", iface-types="erspan,geneve,gre,internal,ip6erspan,ip6gre,lisp,patch,stt,system,tap,vxlan", "neutron:liveness_check_at"="2020-07-29T03:36:04.740147+00:00", ovn-bridge-mappings="datacentre:br-ex", ovn-chassis-mac-mappings="", ovn-cms-options=""}
hostname            : "overcloud-controller-1.localdomain"
name                : "54f18db8-da0a-43bf-bd96-8b6ca3d96513"
nb_cfg              : 1761
transport_zones     : []
vtep_logical_switches: []

_uuid               : 6e7255ea-e9b3-474e-a9be-ee6370a7a43f
encaps              : [12647c29-7ecc-4bad-a098-afad2d005c8c]
external_ids        : {datapath-type=system, iface-types="erspan,geneve,gre,internal,ip6erspan,ip6gre,lisp,patch,stt,system,tap,vxlan", neutron-metadata-proxy-networks="c84b2da2-09b4-4f97-b455-d37d1b40b14e", "neutron:liveness_check_at"="2020-07-29T03:36:04.749225+00:00", "neutron:metadata_liveness_check_at"="2020-07-29T03:36:04.766470+00:00", "neutron:ovn-metadata-id"="e76591ab-357f-4acd-96a2-4b27c0dc645c", "neutron:ovn-metadata-sb-cfg"="1761", ovn-bridge-mappings="datacentre:br-ex", ovn-chassis-mac-mappings="", ovn-cms-options=""}
hostname            : "overcloud-novacompute-0.localdomain"
name                : "a59dafa1-7110-403f-81d1-51c78560e9b7"
nb_cfg              : 1761
transport_zones     : []
vtep_logical_switches: []

# List MAC Binding on OVN Database
[root@overcloud-controller-0 ~]# podman exec -ti ovn-dbs-bundle-podman-1 ovn-sbctl  list Mac_Binding
_uuid               : d80b2d30-6db2-4c97-8988-6910bd95a1e6
datapath            : 025fcd70-cae3-40ef-a50d-e8c0d37d2522
ip                  : "192.168.100.137"
logical_port        : "lrp-849b14d7-8965-4d89-9bd2-f4551acd098b"
mac                 : "fa:16:3e:6a:65:af"

_uuid               : c8a9ee05-097e-4282-81b9-1154433b2a2b
datapath            : 025fcd70-cae3-40ef-a50d-e8c0d37d2522
ip                  : "10.0.0.251"
logical_port        : "lrp-7c14b2ce-c0eb-44d6-93bb-3962c10e3285"
mac                 : "2c:c2:60:57:70:16"

_uuid               : cd7fe1c1-2e21-4d93-92f4-32ea9215ae9b
datapath            : 025fcd70-cae3-40ef-a50d-e8c0d37d2522
ip                  : "10.0.0.12"
logical_port        : "lrp-7c14b2ce-c0eb-44d6-93bb-3962c10e3285"
mac                 : "fa:16:3e:df:fd:e0"

_uuid               : d6b0287e-5449-484e-b4f2-ba264a8f7540
datapath            : 025fcd70-cae3-40ef-a50d-e8c0d37d2522
ip                  : "192.168.100.202"
logical_port        : "lrp-849b14d7-8965-4d89-9bd2-f4551acd098b"
mac                 : "fa:16:3e:6a:65:af"

_uuid               : 52ea21d2-5b44-4bc4-bfc1-f4c3e6223cb6
datapath            : 025fcd70-cae3-40ef-a50d-e8c0d37d2522
ip                  : "10.0.0.91"
logical_port        : "lrp-7c14b2ce-c0eb-44d6-93bb-3962c10e3285"
mac                 : "ce:47:79:d5:a3:70"

_uuid               : 8b59e0db-2126-438f-a7ff-11f8765cbc03
datapath            : 025fcd70-cae3-40ef-a50d-e8c0d37d2522
ip                  : "10.0.0.1"
logical_port        : "lrp-7c14b2ce-c0eb-44d6-93bb-3962c10e3285"
mac                 : "fa:16:3e:a4:d5:db"

# List NAT on OVN Database
[root@overcloud-controller-0 ~]# podman exec -ti ovn-dbs-bundle-podman-1 ovn-nbctl  list NAT
_uuid               : 4f0e331d-a3e2-4b9f-b936-1ce2cabf068d
external_ids        : {"neutron:fip_external_mac"="fa:16:3e:81:83:89", "neutron:fip_id"="5d9fdabd-9a2f-4fd6-8ded-f664aaba270f", "neutron:fip_port_id"="1bf7ff06-eb78-479c-9140-f5c630f72c0b", "neutron:revision_number"="2", "neutron:router_name"="neutron-3607a0a9-8ce6-4e61-8423-6e3c56e1a3d0"}
external_ip         : "10.0.0.70"
external_mac        : []
logical_ip          : "192.168.100.97"
logical_port        : "1bf7ff06-eb78-479c-9140-f5c630f72c0b"
options             : {}
type                : dnat_and_snat

_uuid               : 98ed922a-c2f1-4734-ac0a-6a54d4738776
external_ids        : {}
external_ip         : "10.0.0.76"
external_mac        : []
logical_ip          : "192.168.100.0/24"
logical_port        : []
options             : {}
type                : snat

_uuid               : d5a954bf-c1eb-425a-a7c4-6046765061fd
external_ids        : {"neutron:fip_external_mac"="fa:16:3e:f2:82:f9", "neutron:fip_id"="55931d07-ceb0-4512-b514-3db525f361cc", "neutron:fip_port_id"="2ff8ee12-01a7-4472-a984-4a612ddd0bf8", "neutron:revision_number"="1", "neutron:router_name"="neutron-3607a0a9-8ce6-4e61-8423-6e3c56e1a3d0"}
external_ip         : "10.0.0.86"
external_mac        : []
logical_ip          : "192.168.100.137"
logical_port        : "2ff8ee12-01a7-4472-a984-4a612ddd0bf8"
options             : {}
type                : dnat_and_snat





