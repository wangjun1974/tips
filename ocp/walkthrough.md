# 离线安装

## 网络设置

## 准备安装源

## 安装Helper节点

## Advanced Networking
```
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


```

```
# 3.1. Student tasks
## Create VMs named vm1vx/vm1gre and vm2vx/vm1gre (using vmname.img copying from cirros-nonetwork.img)


## Copy image to /var/lib/libvirt/images on rhel01

[root@rhel01 ]# cd /var/lib/libvirt/images
[root@rhel01 images]# curl -O http://www.opentlc.com/download/osp_advanced_networking/cirros-nonetwork.img
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 28.5M  100 28.5M    0     0  5084k      0  0:00:05  0:00:05 --:--:-- 6229k
[root@rhel01 images]# cp cirros-nonetwork.img /var/lib/libvirt/images/vm1vx.img
[root@rhel01 images]# cp cirros-nonetwork.img /var/lib/libvirt/images/vm1gre.img
[root@rhel01 images]# chown qemu:qemu /var/lib/libvirt/images/*.img
[root@rhel01 images]# ll
total 116864
-rw-r--r--. 1 qemu qemu 29884416 Jul 20 04:35 cirros-nonetwork.img
-rw-r--r--. 1 qemu qemu 30015488 Jul 20 02:02 vm1.img
-rw-r--r--. 1 qemu qemu 29884416 Jul 20 04:36 vm1gre.img
-rw-r--r--. 1 qemu qemu 29884416 Jul 20 04:36 vm1vx.img

## Copy image to /var/lib/libvirt/images on rhel02
[root@rhel02 ~]# cd /var/lib/libvirt/images
[root@rhel02 images]# curl -O http://www.opentlc.com/download/osp_advanced_networking/cirros-nonetwork.img
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 28.5M  100 28.5M    0     0  5085k      0  0:00:05  0:00:05 --:--:-- 6528k
[root@rhel02 images]# cp cirros-nonetwork.img /var/lib/libvirt/images/vm2vx.img
[root@rhel02 images]# cp cirros-nonetwork.img /var/lib/libvirt/images/vm2gre.img
[root@rhel02 images]# chown qemu:qemu /var/lib/libvirt/images/*.img
[root@rhel02 images]# ll
total 116864
-rw-r--r--. 1 qemu qemu 29884416 Jul 20 04:38 cirros-nonetwork.img
-rw-r--r--. 1 qemu qemu 30015488 Jul 20 02:03 vm2.img
-rw-r--r--. 1 qemu qemu 29884416 Jul 20 04:38 vm2gre.img
-rw-r--r--. 1 qemu qemu 29884416 Jul 20 04:38 vm2vx.img

## Ensure you are using bridges br-vx and br-gre
## 
[root@rhel01 images]# ovs-vsctl add-br br-vx                       
[root@rhel01 images]# ovs-vsctl add-port br-vx nic1 -- set interface nic1 type=internal
[root@rhel01 images]# ovs-vsctl add-port br-vx vx0 -- set interface vx0 type=vxlan options:remote_ip=192.0.2.246
[root@rhel01 images]# ovs-vsctl add-br br-gre
[root@rhel01 images]# ovs-vsctl add-port br-gre nic2 -- set interface nic2 type=internal
[root@rhel01 images]# ovs-vsctl add-port br-gre gre0 -- set interface gre0 type=gre options:remote_ip=192.0.2.246

[root@rhel02 images]# ovs-vsctl add-br br-vx 
[root@rhel02 images]# ovs-vsctl add-port br-vx nic1 -- set interface nic1 type=internal
[root@rhel02 images]# ovs-vsctl add-port br-vx vx0 -- set interface vx0 type=vxlan options:remote_ip=192.0.2.245
[root@rhel02 images]# ovs-vsctl add-br br-gre
[root@rhel02 images]# ovs-vsctl add-port br-gre nic2 -- set interface nic2 type=internal
[root@rhel02 images]# ovs-vsctl add-port br-gre gre0 -- set interface gre0 type=gre options:remote_ip=192.0.2.245

# make sure link is up on rhel01 and rhel02
[root@rhel01 images]# ip link set br-vx up 
[root@rhel01 images]# ip link set br-gre up 
[root@rhel01 images]# ip link set nic1 up 
[root@rhel01 images]# ip link set nic2 up 

[root@rhel02 images]# ip link set br-vx up 
[root@rhel02 images]# ip link set br-gre up
[root@rhel02 images]# ip link set nic1 up
[root@rhel02 images]# ip link set nic2 up

# Create VM vm1vx on rhel01
[root@rhel01 images]# virt-install --ram 128 --vcpus 1 --os-type linux --disk path=/var/lib/libvirt/images/vm1vx.img,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --vnc --network bridge:br-vx,model=virtio,virtualport_type=openvswitch --name vm1vx
WARNING  OS name 'linux' is deprecated, using 'generic' instead. This alias will be removed in the future.

Starting install...
Domain creation completed.

# Create VM vm1gre on rhel01
[root@rhel01 images]# virt-install --ram 128 --vcpus 1 --os-type linux --disk path=/var/lib/libvirt/images/vm1gre.img,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --vnc --network bridge:br-gre,model=virtio,virtualport_type=openvswitch --name vm1gre
WARNING  OS name 'linux' is deprecated, using 'generic' instead. This alias will be removed in the future.

Starting install...
Domain creation completed.

# Create VM vm2vx on rhel02
[root@rhel02 images]# virt-install --ram 128 --vcpus 1 --os-type linux --disk path=/var/lib/libvirt/images/vm2vx.img,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --vnc --network bridge:br-vx,model=virtio,virtualport_type=openvswitch --name vm2vx
WARNING  OS name 'linux' is deprecated, using 'generic' instead. This alias will be removed in the future.

Starting install...
Domain creation completed.

# Create VM vm2gre on rhel02
[root@rhel02 images]# virt-install --ram 128 --vcpus 1 --os-type linux --disk path=/var/lib/libvirt/images/vm2gre.img,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --vnc --network bridge:br-gre,model=virtio,virtualport_type=openvswitch --name vm2gre
WARNING  OS name 'linux' is deprecated, using 'generic' instead. This alias will be removed in the future.

Starting install...
Domain creation completed.

## Use range 192.168.101.0/24 and 192.168.102.0/24
# Connect to vm1vx and configure ip 192.168.101.30 on rhel01
[root@rhel01 images]# virsh console vm1vx 
Connected to domain vm1vx
Escape character is ^]

login as 'cirros' user. default password: 'gocubsgo'. use 'sudo' for root.
cirros login: cirros
Password: 
$ sudo ifconfig eth0 192.168.101.30 netmask 255.255.255.0 up
# Escape from vm1vx by typing ^]

# Connect to vm1gre and configure ip 192.168.102.30 on rhel01
[root@rhel01 images]# virsh console vm1gre
Connected to domain vm1gre
Escape character is ^]

login as 'cirros' user. default password: 'gocubsgo'. use 'sudo' for root.
cirros login: cirros
Password: 
$ sudo ifconfig eth0 192.168.102.30 netmask 255.255.255.0 up
# Escape from vm1vx by typing ^]

# Connect to vm2vx and configure ip 192.168.101.31 on rhel02
[root@rhel02 images]# virsh console vm2vx
Connected to domain vm2vx
Escape character is ^]

login as 'cirros' user. default password: 'gocubsgo'. use 'sudo' for root.
cirros login: cirros
Password: 
$ sudo ifconfig eth0 192.168.101.31 netmask 255.255.255.0 up
# Escape from vm1vx by typing ^]

# Connect to vm2gre and configure ip 192.168.102.31 on rhel02
[root@rhel02 images]# virsh console vm2gre
Connected to domain vm2gre
Escape character is ^]

cirros login: cirros
Password: 
$ sudo ifconfig eth0 192.168.102.31 netmask 255.255.255.0 up

# Try ping communication between VMs
# vm1vx(192.168.101.30) to vm2vx(192.168.101.31) on rhel01 
[root@rhel01 images]# virsh console vm1vx
Connected to domain vm1vx
Escape character is ^]

$ ping -c1 192.168.101.31 
PING 192.168.101.31 (192.168.101.31): 56 data bytes
64 bytes from 192.168.101.31: seq=0 ttl=64 time=2.250 ms

--- 192.168.101.31 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 2.250/2.250/2.250 ms

# vm1gre(192.168.102.30) to vm2gre(192.168.102.31) on rhel01 
[root@rhel01 images]# virsh console vm1gre
Connected to domain vm1gre
Escape character is ^]

$ ping -c1 192.168.102.31
PING 192.168.102.31 (192.168.102.31): 56 data bytes
64 bytes from 192.168.102.31: seq=0 ttl=64 time=1.726 ms

--- 192.168.102.31 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 1.726/1.726/1.726 ms

# Create VMs vm10vx on rhel01
[root@rhel01 images]# cd /var/lib/libvirt/images
[root@rhel01 images]# cp cirros-nonetwork.img vm10vx.img
[root@rhel01 images]# virt-install --ram 128 --vcpus 1 --os-type linux --disk path=/var/lib/libvirt/images/vm10vx.img,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --vnc --network bridge:br-vx,model=virtio,virtualport_type=openvswitch --name vm10vx
WARNING  OS name 'linux' is deprecated, using 'generic' instead. This alias will be removed in the future.

Starting install...
Domain creation completed.

# Set vm10vx ip address 192.168.101.40/24
[root@rhel01 images]# virsh console vm10vx
Connected to domain vm10vx
Escape character is ^]

login as 'cirros' user. default password: 'gocubsgo'. use 'sudo' for root.
cirros login: cirros
Password: 
$ sudo ifconfig eth0 192.168.101.40 netmask 255.255.255.0 up
$ 
# Escape by type ^]


# Create VMs vm20vx on rhel02
cd /var/lib/libvirt/images
cp cirros-nonetwork.img vm20vx.img
virt-install --ram 128 --vcpus 1 --os-type linux --disk path=/var/lib/libvirt/images/vm20vx.img,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --vnc --network bridge:br-vx,model=virtio,virtualport_type=openvswitch --name vm20vx

[root@rhel02 images]# virsh console vm20vx
Connected to domain vm20vx
Escape character is ^]

login as 'cirros' user. default password: 'gocubsgo'. use 'sudo' for root.
cirros login: cirros
Password: 
$ sudo ifconfig eth0 192.168.101.41 netmask 255.255.255.0 up

# Check communication between 4 VMs
# from vm20vx(192.168.101.41) ping vm10vx(192.168.101.40)
[root@rhel02 images]# virsh console vm20vx
Connected to domain vm20vx
Escape character is ^]

$ ping -c1 192.168.101.40
PING 192.168.101.40 (192.168.101.40): 56 data bytes
64 bytes from 192.168.101.40: seq=0 ttl=64 time=1.447 ms

--- 192.168.101.40 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 1.447/1.447/1.447 ms

# from vm20vx(192.168.101.41) ping vm2vx(192.168.101.31)
[root@rhel02 images]# virsh console vm20vx
Connected to domain vm20vx
Escape character is ^]

$ ping -c1 192.168.101.31
PING 192.168.101.31 (192.168.101.31): 56 data bytes
64 bytes from 192.168.101.31: seq=0 ttl=64 time=1.446 ms

--- 192.168.101.31 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 1.446/1.446/1.446 ms

# from vm20vx(192.168.101.41) ping vm1vx(192.168.101.30)
[root@rhel02 images]# virsh console vm20vx
Connected to domain vm20vx
Escape character is ^]

$ ping -c1 192.168.101.30
PING 192.168.101.30 (192.168.101.30): 56 data bytes
64 bytes from 192.168.101.30: seq=0 ttl=64 time=1.453 ms

--- 192.168.101.30 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 1.453/1.453/1.453 ms

# Use ovs-vsctl set port vnetX tag=10 for the virtual ports of new VMs
[root@rhel01 images]# virsh domiflist vm10vx 
Interface  Type       Source     Model       MAC
-------------------------------------------------------
vnet2      bridge     br-vx      virtio      52:54:00:44:a1:14
[root@rhel01 images]# ovs-vsctl set port vnet2 tag=10 

[root@rhel02 images]# virsh domiflist vm20vx
Interface  Type       Source     Model       MAC
-------------------------------------------------------
vnet2      bridge     br-vx      virtio      52:54:00:f7:4d:de
[root@rhel02 images]# ovs-vsctl set port vnet2 tag=10 

# Check only communication between different servers are working.

# from vm20vx ping vm10vx should work because these vms are in same vlan tag=10
[root@rhel02 images]# virsh console vm20vx
Connected to domain vm20vx
Escape character is ^]

$ ping -c1 192.168.101.40 
PING 192.168.101.40 (192.168.101.40): 56 data bytes
64 bytes from 192.168.101.40: seq=0 ttl=64 time=4.375 ms

--- 192.168.101.40 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 4.375/4.375/4.375 ms

# from vm20vx(192.168.101.41,vlan tag 10) ping vm1vx(192.168.101.30, no vlan tag) and from vm20vx(192.168.101.41,vlan tag 10) ping vm2vx(192.168.101.31, no vlan tag) should not work because these vm are not in same vlan
[root@rhel02 images]# virsh console vm20vx
Connected to domain vm20vx
Escape character is ^]

$ ping -c1 -W1 192.168.101.30 
PING 192.168.101.30 (192.168.101.30): 56 data bytes

--- 192.168.101.30 ping statistics ---
1 packets transmitted, 0 packets received, 100% packet loss
$ ping -c1 -W1 192.168.101.31 
PING 192.168.101.31 (192.168.101.31): 56 data bytes

--- 192.168.101.31 ping statistics ---
1 packets transmitted, 0 packets received, 100% packet loss

# Remove the vms and undefine them.
[root@rhel01 images]# virsh destroy vm1vx  
Domain vm1vx destroyed

[root@rhel01 images]# virsh destroy vm1gre
Domain vm1gre destroyed

[root@rhel01 images]# virsh destroy vm10vx
Domain vm10vx destroyed

[root@rhel01 images]# virsh undefine vm1vx
Domain vm1vx has been undefined

[root@rhel01 images]# virsh undefine vm1gre
Domain vm1gre has been undefined

[root@rhel01 images]# virsh undefine vm10vx
Domain vm10vx has been undefined

[root@rhel02 images]# for i in vm2vx vm2gre vm20vx ; do virsh destroy $i ; virsh undefine $i ; done 
Domain vm2vx destroyed

Domain vm2vx has been undefined

Domain vm2gre destroyed

Domain vm2gre has been undefined

Domain vm20vx destroyed

Domain vm20vx has been undefined

```

```
Using Neutron
1. Check OpenStack Networking Services
2. Review enabled Network Types
3. Create a Network Environment with Neutron CLI Commands
3.1. Create a Router
3.2. Obtain Information about Neutron Ports
3.3. Operate with Floating IP
3.4. Work with ports
3.5. Disable port security: ports without security group
```

```
Classic Deployment with Open vSwitch Lab
1. Prepare the Environment
2. Review Wiring Inside Compute Node
3. North-South Traffic
4. Packet Tracing and Switching
4.1. Switching
4.2. Logical Tracing
5. Accessing OVN database content
5.1. Northbound database
5.2. Southbound database

overcloud-novacompute-0.localdomain
instance-00000006

+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+
| ID                                   | Name                    | Status | Networks            | Image          | Flavor  |
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+
| 7083d62e-9eb4-436b-9ceb-a3e8eec9947d | overcloud-controller-1  | ACTIVE | ctlplane=192.0.2.18 | overcloud-full | control |
| 13adde5a-5439-4248-8f0c-af709c1c5683 | overcloud-controller-0  | ACTIVE | ctlplane=192.0.2.17 | overcloud-full | control |
| 2758123f-6b04-4887-b47c-6fe8521cccc7 | overcloud-controller-2  | ACTIVE | ctlplane=192.0.2.8  | overcloud-full | control |
| 3c8172e1-d17c-49fa-84e0-0573c7b11a36 | overcloud-novacompute-1 | ACTIVE | ctlplane=192.0.2.21 | overcloud-full | compute |
| efab2bf9-5777-467d-8eab-094151c862d1 | overcloud-novacompute-0 | ACTIVE | ctlplane=192.0.2.15 | overcloud-full | compute |
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+

ssh heat-admin@192.0.2.15

[root@overcloud-novacompute-0 ~]# virsh dumpxml instance-00000006 | grep interface -A10

    <interface type='bridge'>
      <mac address='fa:fa:fa:d0:d0:d0'/>
      <source bridge='br-int'/>
      <virtualport type='openvswitch'>
        <parameters interfaceid='476212e4-4c1b-46c2-a4af-c1ddefba9215'/>
      </virtualport>
      <target dev='tap476212e4-4c'/>
      <model type='virtio'/>
      <driver name='vhost' rx_queue_size='512'/>
      <mtu size='1442'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>

[heat-admin@overcloud-controller-2 ~]$ sudo podman exec -it ovn-dbs-bundle-podman-0 ovn-sbctl find Port_Binding logical_port=476212e4-4c1b-46c2-a4af-c1ddefba9215 
_uuid               : b0fd65c9-f279-4182-9eb5-60749e6f56fd
chassis             : 6e7255ea-e9b3-474e-a9be-ee6370a7a43f
datapath            : 368ff0e6-8c02-40d6-98f6-242342e39adc
encap               : []
external_ids        : {name="vm1port", "neutron:cidrs"="192.168.100.101/24", "neutron:device_id"="ddbbb2e5-a2ba-4841-bb5a-40b256538dae", "neutron:device_owner"="compute:nova", "neutron:network_name"="neutron-3a3ab3a1-5aab-4026-89b1-0007ac0558da", "neutron:port_name"="vm1port", "neutron:project_id"="10e6f16ae2aa4c7b899e737d87d65129", "neutron:revision_number"="8", "neutron:security_group_ids"=""}
gateway_chassis     : []
ha_chassis_group    : []
logical_port        : "476212e4-4c1b-46c2-a4af-c1ddefba9215"
mac                 : ["fa:fa:fa:d0:d0:d0 192.168.100.101", unknown]
nat_addresses       : []
options             : {requested-chassis="overcloud-novacompute-0.localdomain"}
parent_port         : []
tag                 : []
tunnel_key          : 4
type                : ""
virtual_parent      : []


ovn-sbctl get Chassis $(ovn-sbctl find Port_Binding logical_port=cr-lrp-b4ecd092-0869-47d3-927b-a7ad014c62f0 | grep ^chassis | awk '{print $3}') hostname


```



```
openstack security group create sg-web
openstack security group rule create --protocol tcp --dst-port 22 sg-web
openstack security group rule create --protocol tcp --dst-port 80 sg-web

openstack server create --image cirros --flavor m1.tiny --security-group sg-web --nic net-id=private1 web01
openstack server create --image cirros --flavor m1.tiny --security-group sg-web --nic net-id=private1 web02

openstack server list

ROUTERID=$(openstack router show router1 -c id -f value)

```

```
[heat-admin@overcloud-controller-2 ~]$ ip a s | grep vlan
9: vlan10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 10.0.0.165/24 brd 10.0.0.255 scope global vlan10
10: vlan20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.17.0.200/24 brd 172.17.0.255 scope global vlan20
11: vlan40: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.19.0.92/24 brd 172.19.0.255 scope global vlan40
12: vlan30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.18.0.122/24 brd 172.18.0.255 scope global vlan30
14: vlan50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.16.0.33/24 brd 172.16.0.255 scope global vlan50

[heat-admin@overcloud-controller-1 ~]$ sudo ip a s | grep vlan
6: vlan20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.17.0.117/24 brd 172.17.0.255 scope global vlan20
7: vlan40: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.19.0.60/24 brd 172.19.0.255 scope global vlan40
    inet 172.19.0.123/32 brd 172.19.0.255 scope global vlan40
8: vlan10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 10.0.0.249/24 brd 10.0.0.255 scope global vlan10
    inet 10.0.0.91/32 brd 10.0.0.255 scope global vlan10
9: vlan30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.18.0.189/24 brd 172.18.0.255 scope global vlan30
10: vlan50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.16.0.130/24 brd 172.16.0.255 scope global vlan50

[heat-admin@overcloud-controller-0 ~]$ ip a s | grep vlan
6: vlan40: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.19.0.210/24 brd 172.19.0.255 scope global vlan40
7: vlan20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.17.0.221/24 brd 172.17.0.255 scope global vlan20
    inet 172.17.0.25/32 brd 172.17.0.255 scope global vlan20
    inet 172.17.0.164/32 brd 172.17.0.255 scope global vlan20
8: vlan10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 10.0.0.25/24 brd 10.0.0.255 scope global vlan10
10: vlan30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.18.0.24/24 brd 172.18.0.255 scope global vlan30
    inet 172.18.0.142/32 brd 172.18.0.255 scope global vlan30
11: vlan50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 172.16.0.230/24 brd 172.16.0.255 scope global vlan50

```