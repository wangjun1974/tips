```

./setup-env-osp16.sh

virsh list --all 

virsh net-list

virsh net-dumpxml provisioning
<network>
  <name>provisioning</name>
  <uuid>75b80d37-73c1-437f-9ae7-420fea6e2ecc</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:52:d4:f6'/>
  <ip address='192.0.2.254' netmask='255.255.255.0'>
  </ip>
</network>

virsh net-dumpxml trunk
<network>
  <name>trunk</name>
  <uuid>ff2037bb-9dec-4b05-b40c-491d35b13d2a</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr2' stp='on' delay='0'/>
  <mac address='52:54:00:29:29:ac'/>
  <ip address='192.168.0.1' netmask='255.255.255.0'>
  </ip>
</network>

virsh domiflist overcloud-ctrl01

yum install -y cockpit cockpit-dashboard cockpit-machines

firewall-cmd --add-port=9090/tcp
firewall-cmd --add-port=9090/tcp --permanent

systemctl enable --now cockpit


virsh start undercloud

ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa 

ssh root@undercloud.example.com

[root@undercloud ~]# hostnamectl --static status 
undercloud.example.com

[root@undercloud ~]# ip a s 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:af:61:b8 brd ff:ff:ff:ff:ff:ff
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:bb:18:67 brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.253/24 brd 192.168.0.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::2d1b:c0e4:f740:5e2/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever

[root@undercloud ~]# ping -c1 www.redhat.com
PING e3396.dscx.akamaiedge.net (104.82.1.153) 56(84) bytes of data.
64 bytes from a104-82-1-153.deploy.static.akamaitechnologies.com (104.82.1.153): icmp_seq=1 ttl=51 time=1.56 ms

--- e3396.dscx.akamaiedge.net ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.561/1.561/1.561/0.000 ms

[root@undercloud ~]# useradd stack
[root@undercloud ~]# mkdir /home/stack/.ssh
[root@undercloud ~]# cp /root/.ssh/authorized_keys /home/stack/.ssh/
[root@undercloud ~]# chown -R stack:stack /home/stack/.ssh

[root@undercloud ~]# echo 'stack ALL=(root) NOPASSWD:ALL' | tee -a /etc/sudoers.d/stack
stack ALL=(root) NOPASSWD:ALL

[root@undercloud ~]# chmod 0440 /etc/sudoers.d/stack
[root@undercloud ~]# exit
logout
Connection to undercloud.example.com closed.

[root@pool08-iad ~]# ssh stack@undercloud.example.com
Activate the web console with: systemctl enable --now cockpit.socket

This system is not registered to Red Hat Insights. See https://cloud.redhat.com/
To register this system, run: insights-client --register

[stack@undercloud ~]$ 

[stack@undercloud ~]$ sudo -i
[root@undercloud ~]# 

[root@undercloud ~]# yum repolist
repo id                                                                     repo name
ansible-2.9-for-rhel-8-x86_64-rpms                                          ansible-2.9-for-rhel-8-x86_64-rpms
fast-datapath-for-rhel-8-x86_64-rpms                                        fast-datapath-for-rhel-8-x86_64-rpms
openstack-16.1-for-rhel-8-x86_64-rpms                                       openstack-16.1-for-rhel-8-x86_64-rpms
rhceph-4-tools-for-rhel-8-x86_64-rpms                                       rhceph-4-tools-for-rhel-8-x86_64-rpms
rhel-8-for-x86_64-appstream-eus-rpms                                        rhel-8-for-x86_64-appstream-eus-rpms
rhel-8-for-x86_64-baseos-eus-rpms                                           rhel-8-for-x86_64-baseos-eus-rpms
rhel-8-for-x86_64-highavailability-eus-rpms                                 rhel-8-for-x86_64-highavailability-eus-rpms
[root@undercloud ~]# 

[root@undercloud ~]# yum -y update
...
Installed:
  grub2-tools-efi-1:2.02-87.el8_2.x86_64           kernel-4.18.0-193.14.3.el8_2.x86_64                    kernel-core-4.18.0-193.14.3.el8_2.x86_64     
  kernel-modules-4.18.0-193.14.3.el8_2.x86_64      linux-firmware-20191202-97.gite8a0f4c9.el8.noarch     

Complete!

[root@undercloud ~]# curl -o /etc/pki/ca-trust/source/anchors/classroom-ca.pem http://classroom.example.com/ca.crt
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1172  100  1172    0     0   190k      0 --:--:-- --:--:-- --:--:--  190k

[root@undercloud ~]# update-ca-trust extract

[root@undercloud ~]# reboot ; exit

[root@pool08-iad ~]# ssh stack@undercloud.example.com
Activate the web console with: systemctl enable --now cockpit.socket

This system is not registered to Red Hat Insights. See https://cloud.redhat.com/
To register this system, run: insights-client --register

Last login: Mon Sep 21 00:47:54 2020 from 192.168.0.1
[stack@undercloud ~]$

[stack@undercloud ~]$ sudo yum -y install python3-tripleoclient
...

[stack@undercloud ~]$ sudo yum -y install ceph-ansible

[stack@undercloud ~]$ 
cat > /home/stack/undercloud.conf << 'EOF' 
[DEFAULT]
undercloud_hostname = undercloud.example.com
container_images_file = containers-prepare-parameter.yaml
local_ip = 192.0.2.1/24
undercloud_public_host = 192.0.2.2
undercloud_admin_host = 192.0.2.3
undercloud_nameservers = 192.0.2.254
subnets = ctlplane-subnet
local_subnet = ctlplane-subnet
#undercloud_service_certificate =
generate_service_certificate = true
certificate_generation_ca = local
local_interface = eth0
inspection_extras = false
undercloud_debug = false
enable_tempest = false
enable_ui = false

[auth]

[ctlplane-subnet]
cidr = 192.0.2.0/24
dhcp_start = 192.0.2.5
dhcp_end = 192.0.2.24
inspection_iprange = 192.0.2.100,192.0.2.120
gateway = 192.0.2.254
EOF

[stack@undercloud ~]$ openstack tripleo container image prepare default   --local-push-destination   --output-env-file containers-prepare-parameter.yaml
# Generated with the following on 2020-09-21T01:08:30.744958
#
#   openstack tripleo container image prepare default --local-push-destination --output-env-file containers-prepare-parameter.yaml
#

parameter_defaults:
  ContainerImagePrepare:
  - push_destination: true
    set:
      ceph_alertmanager_image: ose-prometheus-alertmanager
      ceph_alertmanager_namespace: registry.redhat.io/openshift4
      ceph_alertmanager_tag: 4.1
      ceph_grafana_image: rhceph-4-dashboard-rhel8
      ceph_grafana_namespace: registry.redhat.io/rhceph
      ceph_grafana_tag: 4
      ceph_image: rhceph-4-rhel8
      ceph_namespace: registry.redhat.io/rhceph
      ceph_node_exporter_image: ose-prometheus-node-exporter
      ceph_node_exporter_namespace: registry.redhat.io/openshift4
      ceph_node_exporter_tag: v4.1
      ceph_prometheus_image: ose-prometheus
      ceph_prometheus_namespace: registry.redhat.io/openshift4
      ceph_prometheus_tag: 4.1
      ceph_tag: latest
      name_prefix: openstack-
      name_suffix: ''
      namespace: registry.redhat.io/rhosp-rhel8
      neutron_driver: ovn
      rhel_containers: false
      tag: '16.1'
    tag_from_label: '{version}-{release}'

[stack@undercloud ~]$ sed -i "s/registry.redhat.io/classroom.example.com:5000/" containers-prepare-parameter.yaml

[stack@undercloud ~]$ cat containers-prepare-parameter.yaml
# Generated with the following on 2020-09-21T01:08:30.744958
#
#   openstack tripleo container image prepare default --local-push-destination --output-env-file containers-prepare-parameter.yaml
#

parameter_defaults:
  ContainerImagePrepare:
  - push_destination: true
    set:
      ceph_alertmanager_image: ose-prometheus-alertmanager
      ceph_alertmanager_namespace: classroom.example.com:5000/openshift4
      ceph_alertmanager_tag: 4.1
      ceph_grafana_image: rhceph-4-dashboard-rhel8
      ceph_grafana_namespace: classroom.example.com:5000/rhceph
      ceph_grafana_tag: 4
      ceph_image: rhceph-4-rhel8
      ceph_namespace: classroom.example.com:5000/rhceph
      ceph_node_exporter_image: ose-prometheus-node-exporter
      ceph_node_exporter_namespace: classroom.example.com:5000/openshift4
      ceph_node_exporter_tag: v4.1
      ceph_prometheus_image: ose-prometheus
      ceph_prometheus_namespace: classroom.example.com:5000/openshift4
      ceph_prometheus_tag: 4.1
      ceph_tag: latest
      name_prefix: openstack-
      name_suffix: ''
      namespace: classroom.example.com:5000/rhosp-rhel8
      neutron_driver: ovn
      rhel_containers: false
      tag: '16.1'
    tag_from_label: '{version}-{release}'


[stack@undercloud ~]$ time openstack undercloud install
...

########################################################

Deployment successful!

########################################################

Writing the stack virtual update mark file /var/lib/tripleo-heat-installer/update_mark_undercloud

##########################################################

The Undercloud has been successfully installed.

Useful files:

Password file is at /home/stack/undercloud-passwords.conf
The stackrc file is at ~/stackrc

Use these files to interact with OpenStack services, and
ensure they are secured.

##########################################################


real    23m37.367s
user    10m49.854s
sys     2m15.784s
[stack@undercloud ~]$ 

[stack@undercloud ~]$ cat ~/stackrc
# Clear any old environment that may conflict.
for key in $( set | awk -F= '/^OS_/ {print $1}' ); do unset "${key}" ; done

export OS_AUTH_TYPE=password
export OS_PASSWORD=xIDrGljuF0MxdY5TefacTueiY
export OS_AUTH_URL=https://192.0.2.2:13000
export OS_USERNAME=admin
export OS_PROJECT_NAME=admin
export COMPUTE_API_VERSION=1.1
export NOVA_VERSION=1.1
export OS_NO_CACHE=True
export OS_CLOUDNAME=undercloud
export OS_IDENTITY_API_VERSION='3'
export OS_PROJECT_DOMAIN_NAME='Default'
export OS_USER_DOMAIN_NAME='Default'
export OS_CACERT="/etc/pki/ca-trust/source/anchors/cm-local-ca.pem"
# Add OS_CLOUDNAME to PS1
if [ -z "${CLOUDPROMPT_ENABLED:-}" ]; then
    export PS1=${PS1:-""}
    export PS1=\${OS_CLOUDNAME:+"(\$OS_CLOUDNAME)"}\ $PS1
    export CLOUDPROMPT_ENABLED=1
fi

[stack@undercloud ~]$ source ~/stackrc 
(undercloud) [stack@undercloud ~]$ 

(undercloud) [stack@undercloud ~]$ openstack catalog list
+------------------+-------------------------+----------------------------------------------------------------------------+
| Name             | Type                    | Endpoints                                                                  |
+------------------+-------------------------+----------------------------------------------------------------------------+
| swift            | object-store            | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13808/v1/AUTH_4785aebf2a7146b0b10c04eaf0c63566 |
|                  |                         | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:8080                                             |
|                  |                         | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:8080/v1/AUTH_4785aebf2a7146b0b10c04eaf0c63566 |
|                  |                         |                                                                            |
| heat             | orchestration           | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:8004/v1/4785aebf2a7146b0b10c04eaf0c63566         |
|                  |                         | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:8004/v1/4785aebf2a7146b0b10c04eaf0c63566      |
|                  |                         | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13004/v1/4785aebf2a7146b0b10c04eaf0c63566      |
|                  |                         |                                                                            |
| neutron          | network                 | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13696                                          |
|                  |                         | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:9696                                             |
|                  |                         | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:9696                                          |
|                  |                         |                                                                            |
| zaqar-websocket  | messaging-websocket     | regionOne                                                                  |
|                  |                         |   admin: ws://192.0.2.3:9000                                               |
|                  |                         | regionOne                                                                  |
|                  |                         |   public: wss://192.0.2.2:9000                                             |
|                  |                         | regionOne                                                                  |
|                  |                         |   internal: ws://192.0.2.3:9000                                            |
|                  |                         |                                                                            |
| zaqar            | messaging               | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:8888                                          |
|                  |                         | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13888                                          |
|                  |                         | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:8888                                             |
|                  |                         |                                                                            |
| keystone         | identity                | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13000                                          |
|                  |                         | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:5000                                          |
|                  |                         | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:35357                                            |
|                  |                         |                                                                            |
| ironic           | baremetal               | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:6385                                             |
|                  |                         | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:6385                                          |
|                  |                         | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13385                                          |
|                  |                         |                                                 
| glance           | image                   | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:9292                                             |
|                  |                         | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13292                                          |
|                  |                         | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:9292                                          |
|                  |                         |                                                                            |
| mistral          | workflowv2              | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:8989/v2                                          |
|                  |                         | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13989/v2                                       |
|                  |                         | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:8989/v2                                       |
|                  |                         |                                                                            |
| placement        | placement               | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:8778/placement                                   |
|                  |                         | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:8778/placement                                |
|                  |                         | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13778/placement                                |
|                  |                         |                                                                            |
| nova             | compute                 | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13774/v2.1                                     |
|                  |                         | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:8774/v2.1                                     |
|                  |                         | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:8774/v2.1                                        |
|                  |                         |                                                                            |
| ironic-inspector | baremetal-introspection | regionOne                                                                  |
|                  |                         |   internal: http://192.0.2.3:5050                                          |
|                  |                         | regionOne                                                                  |
|                  |                         |   public: https://192.0.2.2:13050                                          |
|                  |                         | regionOne                                                                  |
|                  |                         |   admin: http://192.0.2.3:5050                                             |
|                  |                         |                                                                            |
+------------------+-------------------------+----------------------------------------------------------------------------+
(undercloud) [stack@undercloud ~]$

(undercloud) [stack@undercloud ~]$ ip a 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master ovs-system state UP group default qlen 1000
    link/ether 52:54:00:af:61:b8 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::5054:ff:feaf:61b8/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:bb:18:67 brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.253/24 brd 192.168.0.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::2d1b:c0e4:f740:5e2/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
4: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether fe:29:65:2b:af:4c brd ff:ff:ff:ff:ff:ff
5: br-ctlplane: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 52:54:00:af:61:b8 brd ff:ff:ff:ff:ff:ff
    inet 192.0.2.1/24 brd 192.0.2.255 scope global br-ctlplane
       valid_lft forever preferred_lft forever
    inet 192.0.2.3/32 scope global br-ctlplane
       valid_lft forever preferred_lft forever
    inet 192.0.2.2/32 scope global br-ctlplane
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:feaf:61b8/64 scope link 
       valid_lft forever preferred_lft forever
6: br-int: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 1a:55:c4:f6:7b:42 brd ff:ff:ff:ff:ff:ff

(undercloud) [stack@undercloud ~]$ ip r
default via 192.168.0.1 dev eth1 proto static metric 100 
192.0.2.0/24 dev br-ctlplane proto kernel scope link src 192.0.2.1 
192.168.0.0/24 dev eth1 proto kernel scope link src 192.168.0.253 metric 100 

(undercloud) [stack@undercloud ~]$ sudo ovs-vsctl show 
0a10778e-acd1-41e7-827d-31bf82c73ff6
    Manager "ptcp:6640:127.0.0.1"
        is_connected: true
    Bridge br-ctlplane
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
        fail_mode: secure
        datapath_type: system
        Port phy-br-ctlplane
            Interface phy-br-ctlplane
                type: patch
                options: {peer=int-br-ctlplane}
        Port eth0
            Interface eth0
        Port br-ctlplane
            Interface br-ctlplane
                type: internal
    Bridge br-int
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
        fail_mode: secure
        datapath_type: system
        Port tapf08fbd76-eb
            tag: 1
            Interface tapf08fbd76-eb
                type: internal
        Port int-br-ctlplane
            Interface int-br-ctlplane
                type: patch
                options: {peer=phy-br-ctlplane}
        Port br-int
            Interface br-int
                type: internal
    ovs_version: "2.13.0"

(undercloud) [stack@undercloud ~]$ cat /etc/os-net-config/config.json | jq .
{
  "network_config": [
    {
      "addresses": [
        {
          "ip_netmask": "192.0.2.1/24"
        }
      ],
      "dns_servers": [],
      "domain": [],
      "members": [
        {
          "mtu": 1500,
          "name": "eth0",
          "primary": true,
          "type": "interface"
        }
      ],
      "name": "br-ctlplane",
      "ovs_extra": [
        "br-set-external-id br-ctlplane bridge-id br-ctlplane"
      ],
      "routes": [],
      "type": "ovs_bridge",
      "use_dhcp": false
    }
  ]
}

(undercloud) [stack@undercloud ~]$ openstack network list
+--------------------------------------+----------+--------------------------------------+
| ID                                   | Name     | Subnets                              |
+--------------------------------------+----------+--------------------------------------+
| a09c8328-66e1-424a-810b-4b5593e47444 | ctlplane | 437f7ef9-54e2-461f-a8c2-73132e5c3139 |
+--------------------------------------+----------+--------------------------------------+

(undercloud) [stack@undercloud ~]$ openstack subnet list
+--------------------------------------+-----------------+--------------------------------------+--------------+
| ID                                   | Name            | Network                              | Subnet       |
+--------------------------------------+-----------------+--------------------------------------+--------------+
| 437f7ef9-54e2-461f-a8c2-73132e5c3139 | ctlplane-subnet | a09c8328-66e1-424a-810b-4b5593e47444 | 192.0.2.0/24 |
+--------------------------------------+-----------------+--------------------------------------+--------------+

(undercloud) [stack@undercloud ~]$ openstack subnet show ctlplane-subnet -f json
{
  "allocation_pools": [
    {
      "start": "192.0.2.5",
      "end": "192.0.2.24"
    }
  ],
  "cidr": "192.0.2.0/24",
  "created_at": "2020-09-21T05:34:00Z",
  "description": "",
  "dns_nameservers": [
    "192.0.2.254"
  ],
  "enable_dhcp": true,
  "gateway_ip": "192.0.2.254",
  "host_routes": [],
  "id": "437f7ef9-54e2-461f-a8c2-73132e5c3139",
  "ip_version": 4,
  "ipv6_address_mode": null,
  "ipv6_ra_mode": null,
  "location": {
    "cloud": "",
    "region_name": "",
    "zone": null,
    "project": {
      "id": "4785aebf2a7146b0b10c04eaf0c63566",
      "name": "admin",
      "domain_id": null,
      "domain_name": "Default"
    }
  },
  "name": "ctlplane-subnet",
  "network_id": "a09c8328-66e1-424a-810b-4b5593e47444",
  "prefix_length": null,
  "project_id": "4785aebf2a7146b0b10c04eaf0c63566",
  "revision_number": 0,
  "segment_id": null,
  "service_types": [],
  "subnetpool_id": null,
  "tags": [],
  "updated_at": "2020-09-21T05:34:00Z"
}

(undercloud) [stack@undercloud ~]$ sudo podman ps
...
be67ab1d5b31  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-iscsid:16.1-49                     kolla_start           15 minutes ago  Up 15 minutes ago         iscsid
815aab3aa24a  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-mariadb:16.1-52                    kolla_start           16 minutes ago  Up 16 minutes ago         mysql
2ff5039f0b64  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-rabbitmq:16.1-50                   kolla_start           18 minutes ago  Up 18 minutes ago         rabbitmq
9b711786125d  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-haproxy:16.1-50                    kolla_start           18 minutes ago  Up 18 minutes ago         haproxy
cb19fcf841eb  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-memcached:16.1-50                  kolla_start           18 minutes ago  Up 18 minutes ago         memcached
156bed42298e  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-keepalived:16.1-49                 /usr/local/bin/ko...  18 minutes ago  Up 18 minutes ago         keepalived

(undercloud) [stack@undercloud ~]$ sudo ip netns
qdhcp-a09c8328-66e1-424a-810b-4b5593e47444 (id: 0)

(undercloud) [stack@undercloud ~]$ sudo ip netns exec $(sudo ip netns | awk '{print $1}') ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
7: tapf08fbd76-eb: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether fa:16:3e:c3:e8:b6 brd ff:ff:ff:ff:ff:ff
    inet 192.0.2.5/24 brd 192.0.2.255 scope global tapf08fbd76-eb
       valid_lft forever preferred_lft forever
    inet6 fe80::f816:3eff:fec3:e8b6/64 scope link 
       valid_lft forever preferred_lft forever


(undercloud) [stack@undercloud ~]$ mkdir ~/images
(undercloud) [stack@undercloud ~]$ mkdir -p ~/templates/environments
(undercloud) [stack@undercloud ~]$ sudo yum -y install rhosp-director-images
...
Installed:
  binutils-2.30-73.el8.x86_64                                              dwz-0.12-9.el8.x86_64
  efi-srpm-macros-3-2.el8.noarch                                           elfutils-0.178-7.el8.x86_64
  gc-7.6.4-3.el8.x86_64                                                    gdb-headless-8.2-11.el8.x86_64
  ghc-srpm-macros-1.4.2-7.el8.noarch                                       go-srpm-macros-2-16.el8.noarch
  guile-5:2.0.14-7.el8.x86_64                                              libatomic_ops-7.6.2-3.el8.x86_64
  libbabeltrace-1.5.4-2.el8.x86_64                                         libipt-1.6.1-8.el8.x86_64
  libtool-ltdl-2.4.6-25.el8.x86_64                                         ocaml-srpm-macros-5-4.el8.noarch
  octavia-amphora-image-x86_64-16.1-20200722.1.el8ost.noarch               openblas-srpm-macros-2-2.el8.noarch
  patch-2.7.6-11.el8.x86_64                                                perl-srpm-macros-1-25.el8.noarch
  qt5-srpm-macros-5.12.5-3.el8.noarch                                      redhat-rpm-config-122-1.el8.noarch
  rhosp-director-images-16.1-20200722.1.el8ost.noarch                      rhosp-director-images-ipa-x86_64-16.1-20200722.1.el8ost.noarch
  rhosp-director-images-x86_64-16.1-20200722.1.el8ost.noarch               rhosp-release-16.1.0-3.el8ost.noarch
  rpm-build-4.14.2-37.el8.x86_64                                           rpmdevtools-8.10-7.el8.noarch
  rust-srpm-macros-5-2.el8.noarch                                          unzip-6.0-43.el8.x86_64
  zip-3.0-23.el8.x86_64                                                    zstd-1.4.2-2.el8.x86_64

Complete!

(undercloud) [stack@undercloud ~]$ tar -C ~/images -xvf /usr/share/rhosp-director-images/overcloud-full-latest.tar
overcloud-full.qcow2
overcloud-full.initrd
overcloud-full.vmlinuz
overcloud-full-rpm.manifest
overcloud-full-signature.manifest

(undercloud) [stack@undercloud ~]$ tar -C ~/images -xvf /usr/share/rhosp-director-images/ironic-python-agent-latest.tar
ironic-python-agent.initramfs
ironic-python-agent.kernel

(undercloud) [stack@undercloud ~]$ openstack overcloud image upload --image-path ~/images
Image "overcloud-full-vmlinuz" was uploaded.
+--------------------------------------+------------------------+-------------+---------+--------+
|                  ID                  |          Name          | Disk Format |   Size  | Status |
+--------------------------------------+------------------------+-------------+---------+--------+
| 6d327f7c-4420-4a0b-8912-ce2f0c507bb9 | overcloud-full-vmlinuz |     aki     | 8917856 | active |
+--------------------------------------+------------------------+-------------+---------+--------+
Image "overcloud-full-initrd" was uploaded.
+--------------------------------------+-----------------------+-------------+----------+--------+
|                  ID                  |          Name         | Disk Format |   Size   | Status |
+--------------------------------------+-----------------------+-------------+----------+--------+
| f29a0e9a-8128-45e5-a974-66e5f1e1100c | overcloud-full-initrd |     ari     | 72667789 | active |
+--------------------------------------+-----------------------+-------------+----------+--------+
Image "overcloud-full" was uploaded.
+--------------------------------------+----------------+-------------+------------+--------+
|                  ID                  |      Name      | Disk Format |    Size    | Status |
+--------------------------------------+----------------+-------------+------------+--------+
| 0b83c17e-47f2-4d94-87b4-6c65090a6bdb | overcloud-full |    qcow2    | 1090453504 | active |
+--------------------------------------+----------------+-------------+------------+--------+

(undercloud) [stack@undercloud ~]$ openstack image list
+--------------------------------------+------------------------+--------+
| ID                                   | Name                   | Status |
+--------------------------------------+------------------------+--------+
| 0b83c17e-47f2-4d94-87b4-6c65090a6bdb | overcloud-full         | active |
| f29a0e9a-8128-45e5-a974-66e5f1e1100c | overcloud-full-initrd  | active |
| 6d327f7c-4420-4a0b-8912-ce2f0c507bb9 | overcloud-full-vmlinuz | active |
+--------------------------------------+------------------------+--------+

(undercloud) [stack@undercloud ~]$ ls -al /var/lib/ironic/httpboot/
total 558004
drwxr-xr-x. 2 42422 42422        86 Sep 21 01:51 .
drwxr-xr-x. 4 42422 42422        38 Sep 21 01:17 ..
-rwxr-xr-x. 1 root  root    8917856 Sep 21 01:51 agent.kernel
-rw-r--r--. 1 root  root  562464013 Sep 21 01:51 agent.ramdisk
-rw-r--r--. 1 42422 42422       758 Sep 21 01:32 boot.ipxe
-rw-r--r--. 1 42422 42422       365 Sep 21 01:24 inspector.ipxe

(undercloud) [stack@undercloud ~]$ cat /var/lib/ironic/httpboot/inspector.ipxe
#!ipxe

:retry_boot
imgfree
kernel --timeout 60000 http://192.0.2.1:8088/agent.kernel ipa-inspection-callback-url=http://192.0.2.1:5050/v1/continue ipa-inspection-collectors=default,logs systemd.journald.forward_to_console=yes BOOTIF=${mac}  initrd=agent.ramdisk || goto retry_boot
initrd --timeout 60000 http://192.0.2.1:8088/agent.ramdisk || goto retry_boot
boot

(undercloud) [stack@undercloud ~]$ curl -s -H "Accept: application/json" http://192.0.2.1:8787/v2/_catalog | jq .
{
  "repositories": [
    "rhosp-rhel8/openstack-nova-compute-ironic",
    "rhosp-rhel8/openstack-iscsid",
    "rhosp-rhel8/openstack-ironic-conductor",
    "rhosp-rhel8/openstack-ironic-pxe",
    "rhosp-rhel8/openstack-zaqar-wsgi",
    "rhosp-rhel8/openstack-ironic-api",
    "rhosp-rhel8/openstack-nova-conductor",
    "rhosp-rhel8/openstack-rabbitmq",
    "rhosp-rhel8/openstack-keepalived",
    "rhosp-rhel8/openstack-mistral-engine",
    "rhosp-rhel8/openstack-neutron-openvswitch-agent",
    "rhosp-rhel8/openstack-mistral-executor",
    "rhosp-rhel8/openstack-ironic-neutron-agent",
    "rhosp-rhel8/openstack-qdrouterd",
    "rhosp-rhel8/openstack-swift-account",
    "rhosp-rhel8/openstack-rsyslog",
    "rhosp-rhel8/openstack-memcached",
    "rhosp-rhel8/openstack-mariadb",
    "rhosp-rhel8/openstack-swift-proxy-server",
    "rhosp-rhel8/openstack-ironic-inspector",
    "rhosp-rhel8/openstack-mistral-api",
    "rhosp-rhel8/openstack-heat-engine",
    "rhosp-rhel8/openstack-neutron-dhcp-agent",
    "rhosp-rhel8/openstack-neutron-server",
    "rhosp-rhel8/openstack-heat-api",
    "rhosp-rhel8/openstack-keystone",
    "rhosp-rhel8/openstack-glance-api",
    "rhosp-rhel8/openstack-placement-api",
    "rhosp-rhel8/openstack-haproxy",
    "rhosp-rhel8/openstack-nova-scheduler",
    "rhosp-rhel8/openstack-swift-object",
    "rhosp-rhel8/openstack-cron",
    "rhosp-rhel8/openstack-nova-api",
    "rhosp-rhel8/openstack-neutron-l3-agent",
    "rhosp-rhel8/openstack-mistral-event-engine",
    "rhosp-rhel8/openstack-swift-container"
  ]
}

(undercloud) [stack@undercloud ~]$ grep Completed /var/log/tripleo-container-image-prepare.log


[root@pool08-iad ~]# sh -x ./gen_instackenv.sh

[root@pool08-iad ~]# jq "." instackenv.json
{
  "nodes": [
    {
      "mac": [
        "52:54:00:9f:d5:9e"
      ],
      "name": "overcloud-compute01",
      "pm_addr": "192.168.1.1",
      "pm_port": "6234",
      "pm_password": "password",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },
    {
      "mac": [
        "52:54:00:cf:6d:7b"
      ],
      "name": "overcloud-compute02",
      "pm_addr": "192.168.1.1",
      "pm_port": "6235",
      "pm_password": "password",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },
    {
      "mac": [
        "52:54:00:56:48:4d"
      ],
      "name": "overcloud-ctrl01",
      "pm_addr": "192.168.1.1",
      "pm_port": "6231",
      "pm_password": "password",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },
    {
      "mac": [
        "52:54:00:f9:dd:26"
      ],
      "name": "overcloud-ctrl02",
      "pm_addr": "192.168.1.1",
      "pm_port": "6232",
      "pm_password": "password",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },
    {
      "mac": [
        "52:54:00:2b:9c:80"
      ],
      "name": "overcloud-ctrl03",
      "pm_addr": "192.168.1.1",
      "pm_port": "6233",
      "pm_password": "password",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },
    {
      "mac": [
        "52:54:00:af:c4:40"
      ],
      "name": "overcloud-networker",
      "pm_addr": "192.168.1.1",
      "pm_port": "6239",
      "pm_password": "password",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    },
    {
      "mac": [
        "52:54:00:33:60:e9"
      ],
      "name": "overcloud-stor01",
      "pm_addr": "192.168.1.1",
      "pm_port": "6236",
      "pm_password": "password",
      "pm_type": "pxe_ipmitool",
      "pm_user": "admin"
    }
  ]
}

[root@pool08-iad ~]# scp instackenv.json stack@undercloud.example.com:~/nodes.json
instackenv.json                                                                                                       100% 1758     1.8MB/s   00:00    

[root@pool08-iad ~]# sh -x ./vbmc-start.sh
+ vbmc start undercloud
+ vbmc start overcloud-ctrl01
2020-09-21 01:58:51,002.002 19624 INFO VirtualBMC [-] Virtual BMC for domain undercloud started
+ vbmc start overcloud-ctrl02
2020-09-21 01:58:51,098.098 19632 INFO VirtualBMC [-] Virtual BMC for domain overcloud-ctrl01 started
+ vbmc start overcloud-ctrl03
2020-09-21 01:58:51,194.194 19640 INFO VirtualBMC [-] Virtual BMC for domain overcloud-ctrl02 started
+ vbmc start overcloud-compute01
2020-09-21 01:58:51,286.286 19648 INFO VirtualBMC [-] Virtual BMC for domain overcloud-ctrl03 started
+ vbmc start overcloud-compute02
2020-09-21 01:58:51,378.378 19656 INFO VirtualBMC [-] Virtual BMC for domain overcloud-compute01 started
+ vbmc start overcloud-stor01
2020-09-21 01:58:51,470.470 19664 INFO VirtualBMC [-] Virtual BMC for domain overcloud-compute02 started
+ vbmc start overcloud-networker
2020-09-21 01:58:51,562.562 19672 INFO VirtualBMC [-] Virtual BMC for domain overcloud-stor01 started
+ iptables -I FORWARD 1 -j ACCEPT
2020-09-21 01:58:51,654.654 19679 INFO VirtualBMC [-] Virtual BMC for domain overcloud-networker started

[root@pool08-iad ~]# vbmc list
+---------------------+---------+-------------+------+
|     Domain name     |  Status |   Address   | Port |
+---------------------+---------+-------------+------+
| overcloud-compute01 | running | 192.168.1.1 | 6234 |
| overcloud-compute02 | running | 192.168.1.1 | 6235 |
|   overcloud-ctrl01  | running | 192.168.1.1 | 6231 |
|   overcloud-ctrl02  | running | 192.168.1.1 | 6232 |
|   overcloud-ctrl03  | running | 192.168.1.1 | 6233 |
| overcloud-networker | running | 192.168.1.1 | 6239 |
|   overcloud-stor01  | running | 192.168.1.1 | 6236 |
|      undercloud     | running | 192.168.1.1 | 6230 |
+---------------------+---------+-------------+------+
Exception TypeError: "'NoneType' object is not callable" in <function _removeHandlerRef at 0x7fc112d75b90> ignored

[root@pool08-iad ~]# mkdir -p /cinder /glance
[root@pool08-iad ~]# cat >/etc/exports <<EOF
> /cinder 192.0.0.0/8(rw,sync,no_root_squash,no_subtree_check)
> /glance 192.0.0.0/8(rw,sync,no_root_squash,no_subtree_check)
> EOF
[root@pool08-iad ~]# firewall-cmd --add-service=nfs
success
[root@pool08-iad ~]# firewall-cmd --add-service=nfs --permanent
success
[root@pool08-iad ~]# systemctl enable --now nfs-server
Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.

(undercloud) [stack@undercloud ~]$ openstack baremetal node list

(undercloud) [stack@undercloud ~]$ openstack overcloud node import --validate-only ~/nodes.json
Waiting for messages on queue 'tripleo' with no timeout.

Successfully validated environment file
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 34262), ra
ddr=('192.0.2.2', 13000)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=6, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 34916), ra
ddr=('192.0.2.2', 13989)>

(undercloud) [stack@undercloud ~]$ openstack overcloud node import --introspect --provide nodes.json
Waiting for messages on queue 'tripleo' with no timeout.

7 node(s) successfully moved to the "available" state.
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 35438)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=6, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 40050), raddr=('192.0.2.2', 13989)>

(undercloud) [stack@undercloud ~]$ openstack baremetal node list
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+
| UUID                                 | Name                | Instance UUID | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+
| ad3e3612-fa87-499b-bda4-f29f5d99952f | overcloud-compute01 | None          | power off   | available          | False       |
| 87f78af7-20af-41d0-860b-e206cac5ea87 | overcloud-compute02 | None          | power off   | available          | False       |
| 629e932c-e32c-438e-a3c8-403eac0e363d | overcloud-ctrl01    | None          | power off   | available          | False       |
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | overcloud-ctrl02    | None          | power off   | available          | False       |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | overcloud-ctrl03    | None          | power off   | available          | False       |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | overcloud-networker | None          | power off   | available          | False       |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | overcloud-stor01    | None          | power off   | available          | False       |
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+


(undercloud) [stack@undercloud ~]$ openstack baremetal node show overcloud-ctrl01
+------------------------+------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------+
| Field                  | Value                                                                                                                        
                                                                                                                                                        
                                                                                             |
+------------------------+------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------+
| allocation_uuid        | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| automated_clean        | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| bios_interface         | no-bios                                                                                                                      
                                                                                                                                                        
                                                                                             |
| boot_interface         | ipxe                                                                                                                         
                                                                                                                                                        
                                                                                             |
| chassis_uuid           | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| clean_step             | {}                                                                                                                           
                                                                                                                                                        
                                                                                             |
| conductor              | undercloud.example.com                                                                                                       
                                                                                                                                                        
                                                                                             |
| conductor_group        |                                                                                                                              
                                                                                                                                                        
                                                                                             |
| console_enabled        | False                                                                                                                        
                                                                                                                                                        
                                                                                             |
| console_interface      | ipmitool-socat                                                                                                               
                                                                                                                                                        
                                                                                             |
| created_at             | 2020-09-21T06:02:33+00:00                                                                                                    
                                                                                                                                                        
                                                                                             |
| deploy_interface       | iscsi                                                                                                                        
                                                                                                                                                        
                                                                                             |
| deploy_step            | {}                                                                                                                           
                                                                                                                                                        
                                                                                             |
| description            | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| driver                 | ipmi                                                                                                                         
                                                                                                                                                        
                                                                                             |
| driver_info            | {'deploy_kernel': 'file:///var/lib/ironic/httpboot/agent.kernel', 'rescue_kernel': 'file:///var/lib/ironic/httpboot/agent.ker
nel', 'deploy_ramdisk': 'file:///var/lib/ironic/httpboot/agent.ramdisk', 'rescue_ramdisk': 'file:///var/lib/ironic/httpboot/agent.ramdisk', 'ipmi_userna
me': 'admin', 'ipmi_password': '******', 'ipmi_port': '6231', 'ipmi_address': '192.168.1.1'} |
| driver_internal_info   | {}                                                                                                                           
                                                                                                                                                        
                                                                                             |
| extra                  | {}                                                                                                                           
                                                                                                                                                        
                                                                                             |

| fault                  | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| inspect_interface      | inspector                                                                                                                    
                                                                                                                                                        
                                                                                             |
| inspection_finished_at | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| inspection_started_at  | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| instance_info          | {}                                                                                                                           
                                                                                                                                                        
                                                                                             |
| instance_uuid          | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| last_error             | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| maintenance            | False                                                                                                                        
                                                                                                                                                        
                                                                                             |
| maintenance_reason     | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| management_interface   | ipmitool                                                                                                                     
                                                                                                                                                        
                                                                                             |

| name                   | overcloud-ctrl01                                                                                                             
                                                                                                                                                        
                                                                                             |
| network_interface      | flat                                                                                                                         
                                                                                                                                                        
                                                                                             |
| owner                  | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| power_interface        | ipmitool                                                                                                                     
                                                                                                                                                        
                                                                                             |
| power_state            | power off                                                                                                                    
                                                                                                                                                        
                                                                                             |
| properties             | {'local_gb': '59', 'cpus': '4', 'cpu_arch': 'x86_64', 'memory_mb': '24576', 'capabilities': 'cpu_vt:true,cpu_aes:true,cpu_hug
epages:true,cpu_hugepages_1g:true'}                                                                                                                     
                                                                                             |
| protected              | False                                                                                                                        
                                                                                                                                                        
                                                                                             |
| protected_reason       | None                                                                                                                         
                                                                                                                                                        
                                                                                             |
| provision_state        | available                                                                                                                    
                                                                                                                                                        
                                                                                             |
| provision_updated_at   | 2020-09-21T06:05:06+00:00                                                                                                    
                                                                                                                                                        
                                                                                             |
| raid_config            | {}                                                                                                                           
                                                                                                                                                        
                                                                                             |
| raid_interface         | no-raid                                                                                                                      
                                                                                                                                                                                                                                                     |
| rescue_interface       | agent                                                                                                                                                                                                                                                                                                                                                                             |
| reservation            | None                                                                                                                                                                                                                                                                                                                                                                              |
| resource_class         | baremetal                                                                                                                                                                                                                                                                                                                                                                         |
| storage_interface      | noop                                                                                                                                                                                                                                                                                                                                                                              |
| target_power_state     | None                                                                                                                                                                                                                                                                                                                                                                              |
| target_provision_state | None                                                                                                                                                                                                                                                                                                                                                                              |
| target_raid_config     | {}                                                                                                                                                                                                                                                                                                                                                                                |
| traits                 | []                                                                                                                                                                                                                                                                                                                                                                                |
| updated_at             | 2020-09-21T06:05:53+00:00                                                                                                                                                                                                                                                                                                                                                         |
| uuid                   | 629e932c-e32c-438e-a3c8-403eac0e363d                                                                                                                                                                                                                                                                                                                                              |
| vendor_interface       | ipmitool                                                                                                                                                                                                                                                                                                                                                                          |
+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+


(undercloud) [stack@undercloud ~]$ openstack baremetal node show overcloud-ctrl01 -f json -c driver_info
{
  "driver_info": {
    "deploy_kernel": "file:///var/lib/ironic/httpboot/agent.kernel",
    "rescue_kernel": "file:///var/lib/ironic/httpboot/agent.kernel",
    "deploy_ramdisk": "file:///var/lib/ironic/httpboot/agent.ramdisk",
    "rescue_ramdisk": "file:///var/lib/ironic/httpboot/agent.ramdisk",
    "ipmi_username": "admin",
    "ipmi_password": "******",
    "ipmi_port": "6231",
    "ipmi_address": "192.168.1.1"
  }
}


(undercloud) [stack@undercloud ~]$ openstack baremetal introspection list
+--------------------------------------+---------------------+---------------------+-------+
| UUID                                 | Started at          | Finished at         | Error |
+--------------------------------------+---------------------+---------------------+-------+
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | 2020-09-21T06:02:50 | 2020-09-21T06:04:56 | None  |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | 2020-09-21T06:02:49 | 2020-09-21T06:04:49 | None  |
| ad3e3612-fa87-499b-bda4-f29f5d99952f | 2020-09-21T06:02:48 | 2020-09-21T06:04:31 | None  |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | 2020-09-21T06:02:48 | 2020-09-21T06:04:31 | None  |
| 87f78af7-20af-41d0-860b-e206cac5ea87 | 2020-09-21T06:02:48 | 2020-09-21T06:04:56 | None  |
| 629e932c-e32c-438e-a3c8-403eac0e363d | 2020-09-21T06:02:48 | 2020-09-21T06:04:36 | None  |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | 2020-09-21T06:02:48 | 2020-09-21T06:04:44 | None  |
+--------------------------------------+---------------------+---------------------+-------+

(undercloud) [stack@undercloud ~]$ openstack baremetal node show overcloud-ctrl01 -f json -c properties
{
  "properties": {
    "local_gb": "59",
    "cpus": "4",
    "cpu_arch": "x86_64",
    "memory_mb": "24576",
    "capabilities": "cpu_vt:true,cpu_aes:true,cpu_hugepages:true,cpu_hugepages_1g:true"
  }
}

(undercloud) [stack@undercloud ~]$ openstack baremetal introspection data save overcloud-ctrl01 | jq .

(undercloud) [stack@undercloud ~]$ openstack flavor list
+--------------------------------------+---------------+------+------+-----------+-------+-----------+
| ID                                   | Name          |  RAM | Disk | Ephemeral | VCPUs | Is Public |
+--------------------------------------+---------------+------+------+-----------+-------+-----------+
| 27a5f6b9-2fac-4f74-97b8-8e6ad61c46a2 | compute       | 4096 |   40 |         0 |     1 | True      |
| 32c3ad44-df66-41f3-96f2-4cfd84bd8bd8 | control       | 4096 |   40 |         0 |     1 | True      |
| 3dc0e4e9-370b-487f-9a8b-43e2af2b05c3 | block-storage | 4096 |   40 |         0 |     1 | True      |
| 51858309-1c97-4ab3-b216-af700165c69b | ceph-storage  | 4096 |   40 |         0 |     1 | True      |
| 5371eebd-5cf1-4d37-b142-1e952808e634 | baremetal     | 4096 |   40 |         0 |     1 | True      |
| fe9011fd-a177-4bf8-b213-098d1a63b656 | swift-storage | 4096 |   40 |         0 |     1 | True      |
+--------------------------------------+---------------+------+------+-----------+-------+-----------+

(undercloud) [stack@undercloud ~]$ openstack flavor show control -f json -c properties
{
  "properties": "capabilities:profile='control', resources:CUSTOM_BAREMETAL='1', resources:DISK_GB='0', resources:MEMORY_MB='0', resources:VCPU='0'"
}

(undercloud) [stack@undercloud ~]$ openstack overcloud profiles list
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+
| Node UUID                            | Node Name           | Provision State | Current Profile | Possible Profiles |
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+
| ad3e3612-fa87-499b-bda4-f29f5d99952f | overcloud-compute01 | available       | None            |                   |
| 87f78af7-20af-41d0-860b-e206cac5ea87 | overcloud-compute02 | available       | None            |                   |
| 629e932c-e32c-438e-a3c8-403eac0e363d | overcloud-ctrl01    | available       | None            |                   |
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | overcloud-ctrl02    | available       | None            |                   |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | overcloud-ctrl03    | available       | None            |                   |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | overcloud-networker | available       | None            |                   |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | overcloud-stor01    | available       | None            |                   |
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+

(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:control overcloud-ctrl01
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:control overcloud-ctrl02
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:control overcloud-ctrl03
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:compute overcloud-compute01
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:compute overcloud-compute02

(undercloud) [stack@undercloud ~]$ openstack overcloud profiles list
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+
| Node UUID                            | Node Name           | Provision State | Current Profile | Possible Profiles |
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+
| ad3e3612-fa87-499b-bda4-f29f5d99952f | overcloud-compute01 | available       | compute         |                   |
| 87f78af7-20af-41d0-860b-e206cac5ea87 | overcloud-compute02 | available       | compute         |                   |
| 629e932c-e32c-438e-a3c8-403eac0e363d | overcloud-ctrl01    | available       | control         |                   |
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | overcloud-ctrl02    | available       | control         |                   |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | overcloud-ctrl03    | available       | control         |                   |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | overcloud-networker | available       | None            |                   |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | overcloud-stor01    | available       | None            |                   |
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+

(undercloud) [stack@undercloud ~]$ mkdir -p ~/templates/environments

(undercloud) [stack@undercloud ~]$ 
cat > /home/stack/templates/node-info.yaml << EOF
parameter_defaults:
  OvercloudControlFlavor: control
  OvercloudComputeFlavor: compute
  ControllerCount: 3
  ComputeCount: 2
EOF

(undercloud) [stack@undercloud ~]$ 
cat > /home/stack/templates/fix-nova-reserved-host-memory.yaml << EOF
parameter_defaults:
  NovaReservedHostMemory: 1024
EOF

(undercloud) [stack@undercloud ~]$ THT=/usr/share/openstack-tripleo-heat-templates
(undercloud) [stack@undercloud ~]$ cp $THT/roles_data.yaml ~/templates
(undercloud) [stack@undercloud ~]$ cp $THT/network_data.yaml ~/templates

(undercloud) [stack@undercloud ~]$ 
cat > /home/stack/templates/network_data.yaml << EOF
- name: Storage
  vip: true
  vlan: 30
  name_lower: storage
  ip_subnet: '172.18.0.0/24'
  allocation_pools: [{'start': '172.18.0.4', 'end': '172.18.0.250'}]
  ipv6_subnet: 'fd00:fd00:fd00:3000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:3000::10', 'end': 'fd00:fd00:fd00:3000:ffff:ffff:ffff:fffe'}]
- name: StorageMgmt
  name_lower: storage_mgmt
  vip: true
  vlan: 40
  ip_subnet: '172.19.0.0/24'
  allocation_pools: [{'start': '172.19.0.4', 'end': '172.19.0.250'}]
  ipv6_subnet: 'fd00:fd00:fd00:4000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:4000::10', 'end': 'fd00:fd00:fd00:4000:ffff:ffff:ffff:fffe'}]
- name: InternalApi
  name_lower: internal_api
  vip: true
  vlan: 20
  ip_subnet: '172.17.0.0/24'
  allocation_pools: [{'start': '172.17.0.4', 'end': '172.17.0.250'}]
  ipv6_subnet: 'fd00:fd00:fd00:2000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:2000::10', 'end': 'fd00:fd00:fd00:2000:ffff:ffff:ffff:fffe'}]
- name: Tenant
  vip: false  # Tenant network does not use VIPs
  name_lower: tenant
  vlan: 50
  ip_subnet: '172.16.0.0/24'
  allocation_pools: [{'start': '172.16.0.4', 'end': '172.16.0.250'}]
  # Note that tenant tunneling is only compatible with IPv4 addressing at this time.
  ipv6_subnet: 'fd00:fd00:fd00:5000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:5000::10', 'end': 'fd00:fd00:fd00:5000:ffff:ffff:ffff:fffe'}]
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
- name: Management
  # Management network is enabled by default for backwards-compatibility, but
  # is not included in any roles by default. Add to role definitions to use.
  enabled: true
  vip: false  # Management network does not use VIPs
  name_lower: management
  vlan: 60
  ip_subnet: '10.0.1.0/24'
  allocation_pools: [{'start': '10.0.1.4', 'end': '10.0.1.250'}]
  ipv6_subnet: 'fd00:fd00:fd00:6000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:6000::10', 'end': 'fd00:fd00:fd00:6000:ffff:ffff:ffff:fffe'}]
EOF

(undercloud) [stack@undercloud ~]$ mkdir ~/rendered

(undercloud) [stack@undercloud ~]$ cd $THT
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ tools/process-templates.py -r ~/templates/roles_data.yaml -n ~/templates/network_data.yaml -o ~/rendered

(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cd ~/rendered
(undercloud) [stack@undercloud rendered]$

[stack@undercloud rendered]$ cat environments/network-environment.yaml

(undercloud) [stack@undercloud rendered]$ cp environments/network-environment.yaml ~/templates/environments

(undercloud) [stack@undercloud rendered]$ cp -rp network ~/templates

(undercloud) [stack@undercloud rendered]$ cp environments/net-bond-with-vlans.yaml ~/templates/environments/

(undercloud) [stack@undercloud rendered]$ 
cat > /home/stack/templates/environments/storage-environment.yaml << EOF
parameter_defaults:
  CinderEnableIscsiBackend: false
  CinderEnableRbdBackend: false
  CinderEnableNfsBackend: true
  NovaEnableRbdBackend: false
  GlanceBackend: file

  CinderNfsMountOptions: rw,sync,context=system_u:object_r:container_file_t:s0
  CinderNfsServers: 192.0.2.254:/cinder

  GlanceNfsEnabled: true
  GlanceNfsShare: 192.0.2.254:/glance
  GlanceNfsOptions: rw,sync,context=system_u:object_r:container_file_t:s0
EOF

(undercloud) [stack@undercloud rendered]$ cd 

(undercloud) [stack@undercloud ~]$ 
cat > deploy.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/storage-environment.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/node-info.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml
EOF

(undercloud) [stack@undercloud ~]$ chmod 755 ~/deploy.sh

(undercloud) [stack@undercloud ~]$ 
time /bin/bash -x ./deploy.sh 2>&1 | tee /tmp/err
...

Ansible passed.
Overcloud configuration completed.
Overcloud Endpoint: http://10.0.0.132:5000
Overcloud Horizon Dashboard URL: http://10.0.0.132:80/dashboard
Overcloud rc file: /home/stack/overcloudrc
Overcloud Deployed
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 49442)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=5, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 56666), raddr=('192.0.2.2', 13004)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=7, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 43702), raddr=('192.0.2.2', 13989)>

real    46m24.833s
user    0m12.637s
sys     0m1.178s

(undercloud) [stack@undercloud ~]$  openstack server list
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+
| ID                                   | Name                    | Status | Networks            | Image          | Flavor  |
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+
| 42d2a7eb-664d-4403-9a17-47c3f1a680a9 | overcloud-controller-1  | ACTIVE | ctlplane=192.0.2.23 | overcloud-full | control |
| 259ceb8c-557b-45cb-9d4e-75de23298dc0 | overcloud-controller-2  | ACTIVE | ctlplane=192.0.2.11 | overcloud-full | control |
| d95e7a6c-c9cc-4e69-9584-a2c945a74671 | overcloud-controller-0  | ACTIVE | ctlplane=192.0.2.20 | overcloud-full | control |
| bca90171-34dc-4713-b65e-563065dc7e39 | overcloud-novacompute-1 | ACTIVE | ctlplane=192.0.2.10 | overcloud-full | compute |
| a7c556c6-b22d-405f-92a5-4955553e4de0 | overcloud-novacompute-0 | ACTIVE | ctlplane=192.0.2.6  | overcloud-full | compute |
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+

source ~/stackrc
ssh heat-admin@$( openstack server list | grep controller-0 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )

(undercloud) [stack@undercloud ~]$ 
cat >> ~/.bashrc << 'EOF'

alias c0="source ~/stackrc; ssh heat-admin@$( openstack server list | grep controller-0 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias c1="source ~/stackrc; ssh heat-admin@$( openstack server list | grep controller-1 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias c2="source ~/stackrc; ssh heat-admin@$( openstack server list | grep controller-2 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias cp0="source ~/stackrc; ssh heat-admin@$( openstack server list | grep compute-0 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias cp1="source ~/stackrc; ssh heat-admin@$( openstack server list | grep compute-1 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
EOF


(undercloud) [stack@undercloud ~]$ source ~/overcloudrc
(overcloud) [stack@undercloud ~]$ 

(overcloud) [stack@undercloud ~]$ openstack compute service list
+--------------------------------------+----------------+-------------------------------------+----------+---------+-------+----------------------------+
| ID                                   | Binary         | Host                                | Zone     | Status  | State | Updated At                 |
+--------------------------------------+----------------+-------------------------------------+----------+---------+-------+----------------------------+
| d4c980ff-cf39-49ff-91df-be6e22ee799c | nova-conductor | overcloud-controller-0.localdomain  | internal | enabled | up    | 2020-09-21T07:50:34.000000 |
| 51b4537b-3265-44e2-aa84-94b2d2e9c5c3 | nova-conductor | overcloud-controller-2.localdomain  | internal | enabled | up    | 2020-09-21T07:50:34.000000 |
| 21474e15-9e07-4dad-b0ff-0037be1b7fef | nova-conductor | overcloud-controller-1.localdomain  | internal | enabled | up    | 2020-09-21T07:50:25.000000 |
| 090f67db-f54a-4397-a145-8a2715fd16a4 | nova-scheduler | overcloud-controller-2.localdomain  | internal | enabled | up    | 2020-09-21T07:50:28.000000 |
| 704a2862-f7c1-493f-9006-2fee3791f434 | nova-scheduler | overcloud-controller-0.localdomain  | internal | enabled | up    | 2020-09-21T07:50:28.000000 |
| 4832da4d-a23a-4b61-9555-6da58b8da3c0 | nova-scheduler | overcloud-controller-1.localdomain  | internal | enabled | up    | 2020-09-21T07:50:28.000000 |
| c3ff3859-e03a-4cb9-8b1c-fe8e67f73730 | nova-compute   | overcloud-novacompute-1.localdomain | nova     | enabled | up    | 2020-09-21T07:50:31.000000 |
| 6ce5aa6b-0ea2-4549-a812-ea1fddfb9ccb | nova-compute   | overcloud-novacompute-0.localdomain | nova     | enabled | up    | 2020-09-21T07:50:31.000000 |
+--------------------------------------+----------------+-------------------------------------+----------+---------+-------+----------------------------+

(undercloud) [stack@undercloud ~]$ heat-admin@overcloud-controller-0.ctlplane
[heat-admin@overcloud-controller-0 ~]$ cat /etc/rhosp-release
Red Hat OpenStack Platform release 16.1.0 GA (Train)

[heat-admin@overcloud-controller-0 ~]$ cat /etc/system-release
Red Hat Enterprise Linux release 8.2 (Ootpa)

[heat-admin@overcloud-controller-0 ~]$ sudo podman ps 

[heat-admin@overcloud-controller-0 ~]$ sudo pcs status

[heat-admin@overcloud-controller-0 ~]$ sudo podman exec -ti haproxy-bundle-podman-0 cat /etc/haproxy/haproxy.cfg

(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-novacompute-0.ctlplane

[heat-admin@overcloud-novacompute-0 ~]$ sudo podman ps
CONTAINER ID  IMAGE                                                                                          COMMAND      CREATED         STATUS             PORTS  NAMES
339c8022441e  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-nova-compute:16.1-43                kolla_start  28 minutes ago  Up 28 minutes ago         nova_compute
cb3ddb333fa5  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-neutron-metadata-agent-ovn:16.1-46  kolla_start  31 minutes ago  Up 31 minutes ago         ovn_metadata_agent
1430b2fb97b2  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-ovn-controller:16.1-46              kolla_start  31 minutes ago  Up 31 minutes ago         ovn_controller
4066011c61f1  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-nova-compute:16.1-43                kolla_start  31 minutes ago  Up 31 minutes ago         nova_migration_target
2a25b48850a0  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-cron:16.1-50                        kolla_start  31 minutes ago  Up 31 minutes ago         logrotate_crond
3487df64cbf3  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-iscsid:16.1-49                      kolla_start  37 minutes ago  Up 37 minutes ago         iscsid
f50187049f8c  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-nova-libvirt:16.1-46                kolla_start  37 minutes ago  Up 37 minutes ago         nova_libvirt
a46eaf476f26  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-nova-libvirt:16.1-46                kolla_start  37 minutes ago  Up 37 minutes ago         nova_virtlogd


[heat-admin@overcloud-novacompute-0 ~]$ sudo podman exec -ti nova_compute ps auwwx
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
nova           1  0.0  0.0   4204   796 ?        Ss   07:31   0:00 dumb-init --single-child -- kolla_start
nova           7  0.4  2.0 2197908 162848 ?      Sl   07:31   0:07 /usr/bin/python3 /usr/bin/nova-compute
nova         402  0.0  0.0  47628  3896 pts/1    Rs+  08:01   0:00 ps auwwx

[heat-admin@overcloud-controller-0 ~]$ sudo ovs-vsctl show 

[heat-admin@overcloud-controller-0 ~]$ ip --brief address show
lo               UNKNOWN        127.0.0.1/8 ::1/128 
ens3             UP             192.0.2.20/24 192.0.2.8/32 fe80::5054:ff:fe56:484d/64 
ens4             UP             fe80::5054:ff:fec4:650b/64 
ens5             UP             fe80::5054:ff:fe6a:2a62/64 
ens6             UP             fe80::5054:ff:fe77:7e03/64 
ovs-system       DOWN           
br-ex            UNKNOWN        fe80::7439:afff:fe6b:6843/64 
vlan20           UNKNOWN        172.17.0.198/24 172.17.0.14/32 172.17.0.246/32 fe80::a041:98ff:fe8f:1e09/64 
vlan10           UNKNOWN        10.0.0.19/24 fe80::c498:2fff:fec3:5e87/64 
vlan40           UNKNOWN        172.19.0.106/24 fe80::dc20:c9ff:fe62:92af/64 
vlan50           UNKNOWN        172.16.0.187/24 fe80::16:2aff:fed6:c199/64 
vlan30           UNKNOWN        172.18.0.36/24 fe80::481:2eff:feaf:30e6/64 
genev_sys_6081   UNKNOWN        fe80::70ec:5dff:fe6b:f4f3/64 
br-int           DOWN           

[heat-admin@overcloud-controller-0 ~]$ jq "." /etc/os-net-config/config.json

(overcloud) [stack@undercloud ~]$ 
openstack network create public \
  --external --provider-physical-network datacentre \
  --provider-network-type vlan --provider-segment 10

(overcloud) [stack@undercloud ~]$ 
openstack subnet create public-subnet \
  --no-dhcp --network public --subnet-range 10.0.0.0/24 \
  --allocation-pool start=10.0.0.100,end=10.0.0.200  \
  --gateway 10.0.0.1 --dns-nameserver 8.8.8.8

(overcloud) [stack@undercloud ~]$ 
openstack network create private

(overcloud) [stack@undercloud ~]$ 
openstack subnet create private-subnet \
  --network private \
  --dns-nameserver 8.8.4.4 --gateway 172.16.1.1 \
  --subnet-range 172.16.1.0/24

(overcloud) [stack@undercloud ~]$ 
openstack router create router1

(overcloud) [stack@undercloud ~]$ 
openstack router add subnet router1 private-subnet

(overcloud) [stack@undercloud ~]$ 
openstack router set router1 --external-gateway public

(overcloud) [stack@undercloud ~]$ 
openstack port list --router=router1

(overcloud) [stack@undercloud ~]$ 
openstack flavor create m1.nano --vcpus 1 --ram 64 --disk 1

(overcloud) [stack@undercloud ~]$ 
openstack security group list --project admin

(overcloud) [stack@undercloud ~]$ SGID=$(openstack security group list --project admin -c ID -f value)
(overcloud) [stack@undercloud ~]$ openstack security group rule create --proto icmp $SGID
(overcloud) [stack@undercloud ~]$ openstack security group rule create --dst-port 22 --proto tcp $SGID

(overcloud) [stack@undercloud ~]$  curl -L -O http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

(overcloud) [stack@undercloud ~]$ openstack image create cirros   --file cirros-0.4.0-x86_64-disk.img   --disk-format qcow2 --container-format bare

(overcloud) [stack@undercloud ~]$ openstack server create test-instance --network private --flavor m1.nano --image cirros

(overcloud) [stack@undercloud ~]$ openstack server list

(overcloud) [stack@undercloud ~]$ openstack console log show test-instance

(overcloud) [stack@undercloud ~]$ openstack floating ip create public

(overcloud) [stack@undercloud ~]$ openstack floating ip list

(overcloud) [stack@undercloud ~]$ FIP=$(openstack floating ip list -c "Floating IP Address" -f value)
(overcloud) [stack@undercloud ~]$ openstack server add floating ip test-instance $FIP

(overcloud) [stack@undercloud ~]$ ping -c3 $FIP

(overcloud) [stack@undercloud ~]$ ssh cirros@$FIP
$ cat /etc/resolv.conf
nameserver 8.8.4.4

[heat-admin@overcloud-controller-0 ~]$ sudo crudini --get  /var/lib/config-data/puppet-generated/neutron/etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers
ovn

[heat-admin@overcloud-controller-0 ~]$ sudo crudini --get  /var/lib/config-data/puppet-generated/neutron/etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types
geneve,vlan

[heat-admin@overcloud-controller-0 ~]$ sudo podman ps -f name=ovn
CONTAINER ID  IMAGE                                                                              COMMAND               CREATED         STATUS             PORTS  NAMES
75d89f98975e  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-ovn-controller:16.1-46  kolla_start           48 minutes ago  Up 48 minutes ago         ovn_controller
5ee0f247b3e6  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-ovn-northd:16.1-45      /bin/bash /usr/lo...  54 minutes ago  Up 54 minutes ago         ovn-dbs-bundle-podman-0

[heat-admin@overcloud-controller-0 ~]$ ss -4l | grep 6641 
tcp    LISTEN  0       10        172.17.0.246:6641                 0.0.0.0:*  

[heat-admin@overcloud-controller-0 ~]$ ss -4l | grep 6642
tcp    LISTEN  0       10        172.17.0.246:6642                 0.0.0.0:*  

(overcloud) [stack@undercloud ~]$ openstack network agent list 
+--------------------------------------+----------------------+-------------------------------------+-------------------+-------+-------+-------------------------------+
| ID                                   | Agent Type           | Host                                | Availability Zone | Alive | State | Binary                        |
+--------------------------------------+----------------------+-------------------------------------+-------------------+-------+-------+-------------------------------+
| dbf52d09-f301-428a-a2ad-0a6a99118d6a | OVN Controller agent | overcloud-novacompute-0.localdomain | n/a               | :-)   | UP    | ovn-controller                |
| 1d87b125-e881-4e25-962d-850a316f1914 | OVN Metadata agent   | overcloud-novacompute-0.localdomain | n/a               | :-)   | UP    | networking-ovn-metadata-agent |
| f411fb0c-dff1-479a-ac68-97796d6c1f45 | OVN Controller agent | overcloud-novacompute-1.localdomain | n/a               | :-)   | UP    | ovn-controller                |
| 891b9ee1-842b-4aa8-9bd9-a6cc021270c3 | OVN Metadata agent   | overcloud-novacompute-1.localdomain | n/a               | :-)   | UP    | networking-ovn-metadata-agent |
| 4e896537-3e36-4eff-acba-ad793f9fe233 | OVN Controller agent | overcloud-controller-2.localdomain  | n/a               | :-)   | UP    | ovn-controller                |
| 8ede74a7-b5d3-4260-99d3-074dcf6afdbc | OVN Controller agent | overcloud-controller-0.localdomain  | n/a               | :-)   | UP    | ovn-controller                |
| a68be20c-11ea-4a9b-b9b2-00484fcc9b96 | OVN Controller agent | overcloud-controller-1.localdomain  | n/a               | :-)   | UP    | ovn-controller                |
+--------------------------------------+----------------------+-------------------------------------+-------------------+-------+-------+-------------------------------+

[heat-admin@overcloud-novacompute-0 ~]$ sudo podman ps -f name=ovn
CONTAINER ID  IMAGE                                                                                          COMMAND               CREATED         STATUS             PORTS  NAMES
a66ae3111c85  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-neutron-metadata-agent-ovn:16.1-46  /bin/bash -c HAPR...  6 minutes ago   Up 6 minutes ago          neutron-haproxy-ovnmeta-7ee90608-0e2b-4df6-9515-6cec41bd2203
cb3ddb333fa5  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-neutron-metadata-agent-ovn:16.1-46  kolla_start           50 minutes ago  Up 50 minutes ago         ovn_metadata_agent
1430b2fb97b2  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-ovn-controller:16.1-46              kolla_start           50 minutes ago  Up 50 minutes ago         ovn_controller

[heat-admin@overcloud-novacompute-0 ~]$ sudo ip netns
ovnmeta-7ee90608-0e2b-4df6-9515-6cec41bd2203 (id: 0)

[heat-admin@overcloud-controller-0 ~]$ IP=$(ss -4l | grep 6641|awk '{print $5}'|cut -d":" -f1)
[heat-admin@overcloud-controller-0 ~]$ sudo podman exec -ti ovn_controller ovn-nbctl --db=tcp:$IP:6641 show
switch f2ccad81-6c29-460b-aa3a-2045a01a1bca (neutron-5d12ed03-ca23-4738-8693-7a5141f2302d) (aka public)
    port bc3aa35d-1d5d-47a0-9716-e1ce52d79376
        type: localport
        addresses: ["fa:16:3e:8a:02:a2"]
    port 38939c52-01e2-4e9a-8eaf-156d2737e594
        type: router
        router-port: lrp-38939c52-01e2-4e9a-8eaf-156d2737e594
    port provnet-5d12ed03-ca23-4738-8693-7a5141f2302d
        type: localnet
        tag: 10
        addresses: ["unknown"]
switch 3a5a52cf-70ec-474b-8882-d7680c25e698 (neutron-e0289aed-e15a-4670-a2c7-441574f36471) (aka private)
    port 0edf3845-2501-484c-a96b-a8783b080ffa
        addresses: ["fa:16:3e:05:cd:92 172.16.1.100"]
    port 16bb228f-02e2-4099-80d5-4915ede8cd68
        type: localport
        addresses: ["fa:16:3e:19:f1:4b 172.16.1.2"]
    port a1b20d84-cd6e-4973-81c9-d73ab1a6c09f
        type: router
        router-port: lrp-a1b20d84-cd6e-4973-81c9-d73ab1a6c09f
router e010cd21-1e2d-4840-b9ab-b13b4803f7af (neutron-8f0d3b07-3670-493f-9c2a-5871da3c4449) (aka router1)
    port lrp-38939c52-01e2-4e9a-8eaf-156d2737e594
        mac: "fa:16:3e:ba:dd:95"
        networks: ["10.0.0.191/24"]
        gateway chassis: [4e896537-3e36-4eff-acba-ad793f9fe233 8ede74a7-b5d3-4260-99d3-074dcf6afdbc a68be20c-11ea-4a9b-b9b2-00484fcc9b96 f411fb0c-dff1-479a-ac68-97796d6c1f45 dbf52d09-f301-428a-a2ad-0a6a99118d6a]
    port lrp-a1b20d84-cd6e-4973-81c9-d73ab1a6c09f
        mac: "fa:16:3e:14:49:05"
        networks: ["172.16.1.1/24"]
    nat 34444f9b-02d7-4fcd-8f13-a37397b94583
        external ip: "10.0.0.191"
        logical ip: "172.16.1.0/24"
        type: "snat"
    nat 9a915bb7-b649-4ed8-9235-4baf5cf4d932
        external ip: "10.0.0.166"
        logical ip: "172.16.1.100"
        type: "dnat_and_snat"

[heat-admin@overcloud-controller-0 ~]$ sudo podman exec -ti ovn_controller ovn-nbctl --db=tcp:$IP:6641 list logical_switch_port

[heat-admin@overcloud-controller-0 ~]$ sudo podman exec -ti ovn_controller ovn-sbctl --db=tcp:$IP:6642 list datapath_binding
_uuid               : 7ee90608-0e2b-4df6-9515-6cec41bd2203
external_ids        : {logical-switch="3a5a52cf-70ec-474b-8882-d7680c25e698", name=neutron-e0289aed-e15a-4670-a2c7-441574f36471, name2=private}
tunnel_key          : 2

_uuid               : f2592706-b6f5-44e3-9cae-c5ef737300f7
external_ids        : {logical-switch="f2ccad81-6c29-460b-aa3a-2045a01a1bca", name=neutron-5d12ed03-ca23-4738-8693-7a5141f2302d, name2=public}
tunnel_key          : 1

_uuid               : b40d9ee7-7871-4052-b208-46f3cff146f1
external_ids        : {logical-router="e010cd21-1e2d-4840-b9ab-b13b4803f7af", name=neutron-8f0d3b07-3670-493f-9c2a-5871da3c4449, name2=router1}
tunnel_key          : 3

[heat-admin@overcloud-controller-0 ~]$ sudo podman exec -ti ovn_controller ovn-sbctl --db=tcp:$IP:6642 lflow-list private

[heat-admin@overcloud-controller-0 ~]$ sudo podman exec -ti ovn_controller ovn-sbctl --db=tcp:$IP:6642 find multicast_group name=_MC_flood
_uuid               : 9b21d7d2-d9ee-499f-9e40-f0a5e3dae0a4
datapath            : 7ee90608-0e2b-4df6-9515-6cec41bd2203
name                : _MC_flood
ports               : [6c08af06-e327-416b-a8d1-d5d6f876db6d, 80831a2d-4467-476b-9508-14d005980d6a, 92520c71-2eef-4971-8e16-f52761f84875]
tunnel_key          : 32768

_uuid               : 9d45a163-f82b-4276-a5ed-d56facf00f7a
datapath            : f2592706-b6f5-44e3-9cae-c5ef737300f7
name                : _MC_flood
ports               : [0cc1be07-842a-4666-b354-17d443eb81ba, 43a830eb-20ea-441f-8c8f-aa107a735118, 549560f0-83ff-4a4e-9d93-6e2160b01951]
tunnel_key          : 32768

### day 2

### day 3

### day 4

### day 5


```