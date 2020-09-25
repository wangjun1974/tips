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
[root@pool08-iad ~]# mkdir /ctl_plane_backups
[root@pool08-iad ~]# chmod 755 /ctl_plane_backups

[root@pool08-iad ~]# 
cat >> /etc/exports <<EOF
/ctl_plane_backups 192.0.0.0/8(rw,sync,no_root_squash,no_subtree_check)
EOF

[root@pool08-iad ~]# exportfs -a

(undercloud) [stack@undercloud ~]$ tripleo-ansible-inventory --ansible_ssh_user heat-admin --static-yaml-inventory ~/tripleo-inventory.yaml

(undercloud) [stack@undercloud ~]$ 
cat <<'EOF' > ~/undercloud_bar_rear_setup.yaml
---
# Playbook
# We install and configure ReaR in the control plane nodes
# As they are the only nodes we will like to backup now.
- become: true
  hosts: Undercloud
  name: Install ReaR
  roles:
  - role: backup-and-restore
EOF

# Bug 1860439 workaround
(undercloud) [stack@undercloud ~]$ sudo sed -i 's/  register: tripleo_backup_and_restore_exclude_paths//' /usr/share/ansible/roles/backup-and-restore/setup_rear/tasks/main.yml

# Run playbook to configure ReaR to use the NFS server
(undercloud) [stack@undercloud ~]$ 
ansible-playbook \
    -v -i ~/tripleo-inventory.yaml \
    --extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
    --become \
    --become-user root \
    --tags bar_setup_rear \
    --extra="tripleo_backup_and_restore_nfs_server=192.0.2.254" \
    ~/undercloud_bar_rear_setup.yaml

# Backup stopping the services
(undercloud) [stack@undercloud ~]$ 
ansible-playbook \
	-v -i ~/tripleo-inventory.yaml \
	--extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
	--become \
	--become-user root \
	--tags bar_create_recover_image \
	~/undercloud_bar_rear_setup.yaml

# Restore from the Backup
[root@pool08-iad ~]# virsh destroy undercloud
Domain undercloud destroyed

[root@pool08-iad ~]# mv /var/lib/libvirt/images/undercloud.qcow2 /var/lib/libvirt/images/undercloud.qcow2.original

[root@pool08-iad ~]# qemu-img create -f qcow2 /var/lib/libvirt/images/undercloud.qcow2 100G
Formatting '/var/lib/libvirt/images/undercloud.qcow2', fmt=qcow2 size=107374182400 cluster_size=65536 lazy_refcounts=off refcount_bits=16

[root@pool08-iad ~]# chmod 775 /ctl_plane_backups/undercloud/
[root@pool08-iad ~]# chmod 664 /ctl_plane_backups/undercloud/undercloud.example.com.iso
[root@pool08-iad ~]# virsh attach-disk undercloud /ctl_plane_backups/undercloud/undercloud.example.com.iso sda --type cdrom --mode readonly --config
Disk attached successfully

(undercloud) [stack@undercloud ~]$  openstack baremetal node list
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+
| UUID                                 | Name                | Instance UUID                        | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+
| ad3e3612-fa87-499b-bda4-f29f5d99952f | overcloud-compute01 | a7c556c6-b22d-405f-92a5-4955553e4de0 | power on    | active             | False       |
| 87f78af7-20af-41d0-860b-e206cac5ea87 | overcloud-compute02 | bca90171-34dc-4713-b65e-563065dc7e39 | power on    | active             | False       |
| 629e932c-e32c-438e-a3c8-403eac0e363d | overcloud-ctrl01    | d95e7a6c-c9cc-4e69-9584-a2c945a74671 | power on    | active             | False       |
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | overcloud-ctrl02    | 42d2a7eb-664d-4403-9a17-47c3f1a680a9 | power on    | active             | False       |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | overcloud-ctrl03    | 259ceb8c-557b-45cb-9d4e-75de23298dc0 | power on    | active             | False       |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | overcloud-networker | None                                 | power off   | available          | False       |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | overcloud-stor01    | None                                 | power off   | available          | False       |
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+

(undercloud) [stack@undercloud ~]$ openstack compute service list
+----+----------------+------------------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host                   | Zone     | Status  | State | Updated At                 |
+----+----------------+------------------------+----------+---------+-------+----------------------------+
|  1 | nova-conductor | undercloud.localdomain | internal | enabled | up    | 2020-09-22T06:25:11.000000 |
|  3 | nova-scheduler | undercloud.localdomain | internal | enabled | up    | 2020-09-22T06:25:15.000000 |
|  5 | nova-compute   | undercloud.localdomain | nova     | enabled | up    | 2020-09-22T06:25:16.000000 |
+----+----------------+------------------------+----------+---------+-------+----------------------------+

(undercloud) [stack@undercloud ~]$ swift download overcloud plan-environment.yaml -o - | grep Count
  ComputeCount: 2
  ControllerCount: 3

(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+
| ID                                   | Name                    | Status | Networks            | Image          | Flavor  |
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+
| 42d2a7eb-664d-4403-9a17-47c3f1a680a9 | overcloud-controller-1  | ACTIVE | ctlplane=192.0.2.23 | overcloud-full | control |
| 259ceb8c-557b-45cb-9d4e-75de23298dc0 | overcloud-controller-2  | ACTIVE | ctlplane=192.0.2.11 | overcloud-full | control |
| d95e7a6c-c9cc-4e69-9584-a2c945a74671 | overcloud-controller-0  | ACTIVE | ctlplane=192.0.2.20 | overcloud-full | control |
| bca90171-34dc-4713-b65e-563065dc7e39 | overcloud-novacompute-1 | ACTIVE | ctlplane=192.0.2.10 | overcloud-full | compute |
| a7c556c6-b22d-405f-92a5-4955553e4de0 | overcloud-novacompute-0 | ACTIVE | ctlplane=192.0.2.6  | overcloud-full | compute |
+--------------------------------------+-------------------------+--------+---------------------+----------------+---------+

# Backup and Restore Overcloud
## Install ReaR in the Overcloud

(undercloud) [stack@undercloud ~]$ 
cat <<'EOF' > ~/overcloud_bar_rear_setup.yaml
# Playbook
# We install and configure ReaR in the control plane nodes
# As they are the only nodes we will like to backup now.
- become: true
  hosts: Controller
  name: Install ReaR
  roles:
  - role: backup-and-restore
EOF

# copy yum repository config file from undercloud to controller
(undercloud) [stack@undercloud ~]$ 
ansible -i ~/tripleo-inventory.yaml \
    --become \
    --become-user root \
    -m copy \
    -a "src=/etc/yum.repos.d/open.repo dest=/etc/yum.repos.d/open.repo" \
    Controller

# Install ReaR on the Controller nodes
(undercloud) [stack@undercloud ~]$ 
ansible-playbook \
	-v -i ~/tripleo-inventory.yaml \
	--extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
	--become \
	--become-user root \
	--tags bar_setup_rear \
	--extra="tripleo_backup_and_restore_nfs_server=192.0.2.254" \
	~/overcloud_bar_rear_setup.yaml

# Perform Backup
## Snapshot backup without stop services

(undercloud) [stack@undercloud ~]$ 
ansible-playbook \
	-v -i ~/tripleo-inventory.yaml \
	--extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
	--become \
	--become-user root \
	--tags bar_create_recover_image \
	--extra="tripleo_container_cli=podman" \
	--extra="tripleo_backup_and_restore_service_manager=false" \
	~/overcloud_bar_rear_setup.yaml


# Restore from the Backup
## destroy vm overcloud-ctrl01
[root@pool08-iad ~]# virsh destroy overcloud-ctrl01

[root@pool08-iad ~]# mv /var/lib/libvirt/images/overcloud-ctrl01.qcow2 /var/lib/libvirt/images/overcloud-ctrl01.qcow2.original

[root@pool08-iad ~]# qemu-img create -f qcow2 /var/lib/libvirt/images/overcloud-ctrl01.qcow2 60G
Formatting '/var/lib/libvirt/images/overcloud-ctrl01.qcow2', fmt=qcow2 size=64424509440 cluster_size=65536 lazy_refcounts=off refcount_bits=16

[root@pool08-iad ~]# chmod 775 /ctl_plane_backups/overcloud-controller-0/
[root@pool08-iad ~]# chmod 664 /ctl_plane_backups/overcloud-controller-0/overcloud-controller-0.iso
[root@pool08-iad ~]# virsh attach-disk overcloud-ctrl01 /ctl_plane_backups/overcloud-controller-0/overcloud-controller-0.iso sda --type cdrom --mode readonly --config
Disk attached successfully

# config boot order and boot device manually add boot dev and remove boot order
[root@pool08-iad ~]# 
virsh edit overcloud-ctrl01
...
  <os>
    <type arch='x86_64' machine='pc-i440fx-rhel7.6.0'>hvm</type>
    <boot dev='hd'/>
  </os>
...

# Ceph 4 Installation Lab
# Create the Workstation node
[root@pool08-iad ~]# /bin/bash -x ./setup-env-workstation.sh

# Create the Ceph nodes
[root@pool08-iad ~]# /bin/bash -x ./setup-env-ceph4-osp16.sh

[root@pool08-iad ~]# ssh-copy-id root@192.0.2.249
[root@pool08-iad ~]# ssh root@192.0.2.249
Activate the web console with: systemctl enable --now cockpit.socket

This system is not registered to Red Hat Insights. See https://cloud.redhat.com/
To register this system, run: insights-client --register

[root@workstation ~]# 
[root@workstation ~]# dnf repolist
repo id                                                                     repo name
ansible-2.9-for-rhel-8-x86_64-rpms                                          ansible-2.9-for-rhel-8-x86_64-rpms
fast-datapath-for-rhel-8-x86_64-rpms                                        fast-datapath-for-rhel-8-x86_64-rpms
openstack-16.1-for-rhel-8-x86_64-rpms                                       openstack-16.1-for-rhel-8-x86_64-rpms
rhceph-4-tools-for-rhel-8-x86_64-rpms                                       rhceph-4-tools-for-rhel-8-x86_64-rpms
rhel-8-for-x86_64-appstream-eus-rpms                                        rhel-8-for-x86_64-appstream-eus-rpms
rhel-8-for-x86_64-baseos-eus-rpms                                           rhel-8-for-x86_64-baseos-eus-rpms
rhel-8-for-x86_64-highavailability-eus-rpms                                 rhel-8-for-x86_64-highavailability-eus-rpms

[root@workstation ~]# dnf -y install ceph-ansible

[root@workstation ~]# 
cat >> /etc/hosts <<EOF
172.18.0.61 ceph-node01 ceph-node01.example.com
172.18.0.62 ceph-node02 ceph-node02.example.com
172.18.0.63 ceph-node03 ceph-node03.example.com
EOF

[root@workstation ~]# 
cat > ceph-nodes << EOF
[all]
ceph-node01
ceph-node02
ceph-node03
EOF

[root@workstation ~]# 
cat > ceph-preqs.yaml << EOF
---
- name: Ceph Installation Pre-requisites
  hosts: all
  gather_facts: no
  vars:
  remote_user: root
  ignore_errors: yes
  tasks:

  - name: Create the admin user
    user:
      name: admin
      generate_ssh_key: yes
      ssh_key_bits: 2048
      ssh_key_file: .ssh/id_rsa
      password: $6$mZKDrweZ5e04Hcus$97I..Zb0Ywh1lQefdCRxGh2PJ/abNU/LIN7zp8d2E.uYUSmx1RLokyzYS3mUTpipvToZbYKyfMqdP6My7yYJW1

  - name: Create sudo file for admin user
    lineinfile:
      path: /etc/sudoers.d/admin
      state: present
      create: yes
      line: "admin ALL=(root) NOPASSWD:ALL"
      owner: root
      group: root
      mode: 0440

  - name: Push ssh key to hosts
    authorized_key:
      user: admin
      key: "{{ lookup('file', '/root/.ssh/id_rsa.pub') }}"
      state: present

  - name: Copy certificate
    copy:
      src: /etc/pki/ca-trust/source/anchors/classroom.crt
      dest: /etc/pki/ca-trust/source/anchors/classroom.crt

  - name:  Extract CA cert into trust chain
    command: /bin/update-ca-trust update
EOF

[root@workstation ~]# curl http://classroom.example.com/ca.crt -o /etc/pki/ca-trust/source/anchors/classroom.crt
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1172  100  1172    0     0   127k      0 --:--:-- --:--:-- --:--:--  127k

[root@workstation ~]# update-ca-trust update

[root@workstation ~]# ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''
[root@workstation ~]# ssh-copy-id 172.18.0.61
[root@workstation ~]# ssh-copy-id 172.18.0.62
[root@workstation ~]# ssh-copy-id 172.18.0.63

[root@workstation ~]# ansible-playbook -i ceph-nodes ceph-preqs.yaml

[root@workstation ~]# 
cat > ~/.ssh/config << EOF
Host ceph*
  StrictHostKeyChecking no
  User admin
EOF

[root@workstation ~]# cd /usr/share/ceph-ansible/

[root@workstation ceph-ansible]# 
cat >> hosts << EOF
[mons]
ceph-node01
ceph-node02
ceph-node03

[mgrs]
ceph-node01
ceph-node02
ceph-node03

[rgws]
ceph-node01
ceph-node02
ceph-node03

[osds]
ceph-node01
ceph-node02
ceph-node03

[grafana-server]
localhost ansible_connection=local
EOF

[root@workstation ceph-ansible]# mv ansible.cfg ansible.cfg.orig

[root@workstation ceph-ansible]# 
cat > ansible.cfg << EOF
[defaults]
inventory     = /usr/share/ceph-ansible/hosts
action_plugins = /usr/share/ceph-ansible/plugins/actions
filter_plugins = /usr/share/ceph-ansible/plugins/filter
roles_path = /usr/share/ceph-ansible/roles
log_path = /var/log/ansible.log
timeout = 60
host_key_checking = False
retry_files_enabled = False
retry_files_save_path = /usr/share/ceph-ansible/ansible-retry
[privilege_escalation]
become=True
become_method=sudo
become_user=root
become_ask_pass=False
EOF

[root@workstation ceph-ansible]# 
cat > group_vars/all.yml << EOF
---
monitor_interface: eth0.30
radosgw_interface: eth0.30
journal_size: 5120
public_network: 172.18.0.0/24
ceph_docker_image: rhceph/rhceph-4-rhel8
ceph_docker_image_tag: latest
containerized_deployment: true
ceph_docker_registry: classroom.example.com:5000
ceph_origin: repository
ceph_repository: rhcs
ceph_repository_type: local
ceph_rhcs_version: 4
dashboard_admin_user: admin
dashboard_admin_password: r3dh4t1!
grafana_admin_user: admin
grafana_admin_password: r3dh4t1!
ceph_conf_overrides:
  global:
    mon_pg_warn_min_per_osd: 0
EOF

[root@workstation ceph-ansible]# 
cat > group_vars/osds.yml << EOF
---
copy_admin_key: true

devices:
  - /dev/vdb
  - /dev/vdc

ceph_osd_docker_memory_limit: 1g
ceph_osd_docker_cpu_limit: 1
EOF

cat > group_vars/mons.yml << EOF
---
ceph_mon_docker_memory_limit: 1g
ceph_mon_docker_cpu_limit: 1
EOF

cat > group_vars/mgrs.yml << EOF
---
ceph_mgr_docker_memory_limit: 1g
ceph_mgr_docker_cpu_limit: 1
EOF

cat > group_vars/rgws.yml << EOF
---
ceph_rgw_docker_memory_limit: 1g
ceph_rgw_docker_cpu_limit: 1
EOF

[root@workstation ceph-ansible]# cp site-docker.yml.sample site-docker.yml
[root@workstation ceph-ansible]# ansible-playbook site-docker.yml
[root@workstation ceph-ansible]# cd

[root@workstation ceph-ansible]# dnf -y install ceph-common
[root@workstation ~]# scp root@ceph-node01:/etc/ceph/ceph.conf /etc/ceph/
[root@workstation ~]# scp root@ceph-node01:/etc/ceph/ceph.client.admin.keyring /etc/ceph/

[root@workstation ~]# ceph -s
  cluster:
    id:     eb0670c0-e359-4cb3-bf11-c650b82118ef
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum ceph-node01,ceph-node02,ceph-node03 (age 11m)
    mgr: ceph-node02(active, since 3m), standbys: ceph-node01, ceph-node03
    osd: 6 osds: 6 up (since 8m), 6 in (since 8m)
    rgw: 3 daemons active (ceph-node01.rgw0, ceph-node02.rgw0, ceph-node03.rgw0)
 
  task status:
 
  data:
    pools:   4 pools, 128 pgs
    objects: 223 objects, 6.6 KiB
    usage:   6.0 GiB used, 54 GiB / 60 GiB avail
    pgs:     128 active+clean

[root@workstation ~]# ceph health
HEALTH_OK

[root@workstation ~]# ceph osd tree
ID CLASS WEIGHT  TYPE NAME            STATUS REWEIGHT PRI-AFF 
-1       0.05878 root default                                 
-3       0.01959     host ceph-node01                         
 0   hdd 0.00980         osd.0            up  1.00000 1.00000 
 3   hdd 0.00980         osd.3            up  1.00000 1.00000 
-7       0.01959     host ceph-node02                         
 1   hdd 0.00980         osd.1            up  1.00000 1.00000 
 4   hdd 0.00980         osd.4            up  1.00000 1.00000 
-5       0.01959     host ceph-node03                         
 2   hdd 0.00980         osd.2            up  1.00000 1.00000 
 5   hdd 0.00980         osd.5            up  1.00000 1.00000 

[root@workstation ~]# ceph mon dump
dumped monmap epoch 1
epoch 1
fsid eb0670c0-e359-4cb3-bf11-c650b82118ef
last_changed 2020-09-22 03:42:39.385706
created 2020-09-22 03:42:39.385706
min_mon_release 14 (nautilus)
0: [v2:172.18.0.61:3300/0,v1:172.18.0.61:6789/0] mon.ceph-node01
1: [v2:172.18.0.62:3300/0,v1:172.18.0.62:6789/0] mon.ceph-node02
2: [v2:172.18.0.63:3300/0,v1:172.18.0.63:6789/0] mon.ceph-node03

[root@workstation ~]# ssh ceph-node01
Activate the web console with: systemctl enable --now cockpit.socket

This system is not registered to Red Hat Insights. See https://cloud.redhat.com/
To register this system, run: insights-client --register

Last login: Tue Sep 22 03:51:04 2020 from 172.18.0.70
[admin@ceph-node01 ~]$ 

[admin@ceph-node01 ~]$ sudo podman ps
CONTAINER ID  IMAGE                                                    COMMAND               CREATED         STATUS             PORTS  NAMES
f1f57583589a  docker.io/prom/node-exporter:v0.17.0                     --path.procfs=/ho...  10 minutes ago  Up 10 minutes ago         node-exporter
eb9bb5134892  classroom.example.com:5000/rhceph/rhceph-4-rhel8:latest                        11 minutes ago  Up 11 minutes ago         ceph-rgw-ceph-node01-rgw0
b2a9a04064bf  classroom.example.com:5000/rhceph/rhceph-4-rhel8:latest                        12 minutes ago  Up 12 minutes ago         ceph-osd-3
09c07d6f5b1a  classroom.example.com:5000/rhceph/rhceph-4-rhel8:latest                        12 minutes ago  Up 12 minutes ago         ceph-osd-0
124cb57f46d9  classroom.example.com:5000/rhceph/rhceph-4-rhel8:latest                        14 minutes ago  Up 14 minutes ago         ceph-mgr-ceph-node01
7e340886c19c  classroom.example.com:5000/rhceph/rhceph-4-rhel8:latest                        15 minutes ago  Up 15 minutes ago         ceph-mon-ceph-node01


[admin@ceph-node01 ~]$ sudo podman stats
ID             NAME                        CPU %   MEM USAGE / LIMIT   MEM %    NET IO    BLOCK IO            PIDS
09c07d6f5b1a   ceph-osd-0                  2.08%   53.03MB / 1.916GB   2.77%    -- / --   11.42MB / 19.37MB   60
124cb57f46d9   ceph-mgr-ceph-node01        9.55%   314.5MB / 1.074GB   29.29%   -- / --   9.089MB / 0B        47
7e340886c19c   ceph-mon-ceph-node01        8.24%   104.7MB / 1.074GB   9.75%    -- / --   20.21MB / 91.67MB   28
b2a9a04064bf   ceph-osd-3                  1.74%   58.24MB / 1.916GB   3.04%    -- / --   14.57MB / 27.42MB   60
eb9bb5134892   ceph-rgw-ceph-node01-rgw0   1.01%   83.78MB / 1.074GB   7.80%    -- / --   15.59MB / 0B        602
f1f57583589a   node-exporter               6.89%   10.14MB / 1.916GB   0.53%    -- / --   -- / --             4

[admin@ceph-node01 ~]$ sudo systemctl | grep "ceph-.*.service"
ceph-mgr@ceph-node01.service                                                                                                         loaded active running   Ceph Manager                                                                                                                
ceph-mon@ceph-node01.service                                                                                                         loaded active running   Ceph Monitor                                                                                                                
ceph-osd@0.service                                                                                                                   loaded active running   Ceph OSD                                                                                                                    
ceph-osd@3.service                                                                                                                   loaded active running   Ceph OSD                                                                                                                    
ceph-radosgw@rgw.ceph-node01.rgw0.service                                                                                            loaded active running   Ceph RGW                   

[admin@ceph-node01 ~]$ sudo systemctl status ceph*@*.service

# Service Telemetry Framework Lab
[root@pool08-iad ~]# su - student
[student@pool08-iad ~]$ curl -O -L https://mirror.openshift.com/pub/openshift-v4/clients/crc/1.9.0/crc-linux-amd64.tar.xz
[student@pool08-iad ~]$ tar xvfJ crc-linux-amd64.tar.xz

[student@pool08-iad ~]$ cd crc-linux-1.9.0-amd64
[student@pool08-iad crc-linux-1.9.0-amd64]$ ./crc setup

[student@pool08-iad crc-linux-1.9.0-amd64]$ ./crc start -m 16000 -c 12
...
? Image pull secret [? for help]
...
INFO Extracting bundle: crc_libvirt_4.3.10.crcbundle ...
INFO Checking size of the disk image /home/student/.crc/cache/crc_libvirt_4.3.10/crc.qcow2 ...
INFO Creating CodeReady Containers VM for OpenShift 4.3.10...
INFO Verifying validity of the cluster certificates ...
INFO Check internal and public DNS query ...
INFO Check DNS query from host ...
INFO Copying kubeconfig file to instance dir ...
INFO Cluster TLS certificates have expired, renewing them... [will take up to 5 minutes]
INFO Adding user's pull secret ...
INFO Updating cluster ID ...



INFO Starting OpenShift cluster ... [waiting 3m]
INFO
INFO To access the cluster, first set up your environment by following 'crc oc-env' instructions
INFO Then you can access it by running 'oc login -u developer -p developer https://api.crc.testing:6443'
INFO To login as an admin, run 'oc login -u kubeadmin -p HeJWN-ckbCA-Q96Ds-Sj763 https://api.crc.testing:6443'
INFO
INFO You can now run 'crc console' and use these credentials to access the OpenShift web console
Started the OpenShift cluster
WARN The cluster might report a degraded or error state. This is expected since several operators have been disabled to lower the resource usage. For more information, please consult the documentation

[student@pool08-iad crc-linux-1.9.0-amd64]$ eval $(./crc oc-env)

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc login -u kubeadmin -p HeJWN-ckbCA-Q96Ds-Sj763 https://api.crc.testing:6443

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc version
Client Version: 4.5.0-202004180718-6b061e3
Server Version: 4.3.10
Kubernetes Version: v1.16.2

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc new-project service-telemetry
Now using project "service-telemetry" on server "https://api.crc.testing:6443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app ruby~https://github.com/sclorg/ruby-ex.git

to build a new example application in Python. Or use kubectl to deploy a simple Kubernetes application:

    kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node

[student@pool04-iad crc-linux-1.9.0-amd64]$ 
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: service-telemetry-operator-group
  namespace: service-telemetry
spec:
  targetNamespaces:
  - service-telemetry
EOF

[student@pool04-iad crc-linux-1.9.0-amd64]$ 
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: operatorhubio-operators
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: quay.io/operator-framework/upstream-community-operators:latest
  displayName: OperatorHub.io Operators
  publisher: OperatorHub.io
EOF

[student@pool04-iad crc-linux-1.9.0-amd64]$ 
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  labels:
    opsrc-provider: redhat-operators-stf
  name: redhat-operators-stf
  namespace: openshift-marketplace
spec:
  authorizationToken: {}
  displayName: Red Hat STF Operators
  endpoint: https://quay.io/cnr
  publisher: Red Hat
  registryNamespace: redhat-operators-stf
  type: appregistry
EOF

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc get -nopenshift-marketplace operatorsource redhat-operators-stf
NAME                   TYPE          ENDPOINT              REGISTRY               DISPLAYNAME             PUBLISHER   STATUS      MESSAGE                                       AGE
redhat-operators-stf   appregistry   https://quay.io/cnr   redhat-operators-stf   Red Hat STF Operators   Red Hat     Succeeded   The object has been successfully reconciled   23s

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc get packagemanifests | grep "Red Hat STF"
servicetelemetry-operator                    Red Hat STF Operators      86s
smartgateway-operator                        Red Hat STF Operators      86s

[student@pool08-iad crc-linux-1.9.0-amd64]$ 
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq7-cert-manager
  namespace: openshift-operators
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: amq7-cert-manager
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc get --namespace openshift-operators csv
NAME                       DISPLAY                                         VERSION   REPLACES   PHASE
amq7-cert-manager.v1.0.0   Red Hat Integration - AMQ Certificate Manager   1.0.0                Succeeded

[student@pool08-iad crc-linux-1.9.0-amd64]$ 
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: elastic-cloud-eck
  namespace: service-telemetry
spec:
  channel: stable
  installPlanApproval: Automatic
  name: elastic-cloud-eck
  source: operatorhubio-operators
  sourceNamespace: openshift-marketplace
EOF

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc get csv
NAME                       DISPLAY                                         VERSION   REPLACES                   PHASE
amq7-cert-manager.v1.0.0   Red Hat Integration - AMQ Certificate Manager   1.0.0                                Succeeded
elastic-cloud-eck.v1.2.1   Elastic Cloud on Kubernetes                     1.2.1     elastic-cloud-eck.v1.2.0   Succeeded

[student@pool08-iad crc-linux-1.9.0-amd64]$ 
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: servicetelemetry-operator
  namespace: service-telemetry
spec:
  channel: stable
  installPlanApproval: Automatic
  name: servicetelemetry-operator
  source: redhat-operators-stf
  sourceNamespace: openshift-marketplace
EOF

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc get csv 
NAME                                DISPLAY                                         VERSION   REPLACES                              PHASE
amq7-cert-manager.v1.0.0            Red Hat Integration - AMQ Certificate Manager   1.0.0                                           Succeeded
amq7-interconnect-operator.v1.2.0   Red Hat Integration - AMQ Interconnect          1.2.0                                           Succeeded
elastic-cloud-eck.v1.2.1            Elastic Cloud on Kubernetes                     1.2.1     elastic-cloud-eck.v1.2.0              Succeeded
prometheusoperator.0.37.0           Prometheus Operator                             0.37.0    prometheusoperator.0.32.0             Succeeded
service-telemetry-operator.v1.0.3   Service Telemetry Operator                      1.0.3     service-telemetry-operator.v1.0.2-2   Succeeded
smart-gateway-operator.v1.0.4       Smart Gateway Operator                          1.0.4     smart-gateway-operator.v1.0.2-3       Succeeded

[student@pool08-iad crc-linux-1.9.0-amd64]$ 
oc apply -f - <<EOF
apiVersion: infra.watch/v1alpha1
kind: ServiceTelemetry
metadata:
  name: stf-default
  namespace: service-telemetry
spec:
  eventsEnabled: true
  metricsEnabled: true
EOF

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc logs $(oc get pod --selector='name=service-telemetry-operator' -oname) -c ansible -f

[student@pool08-iad crc-linux-1.9.0-amd64]$  oc get pods
NAME                                                              READY   STATUS    RESTARTS   AGE
alertmanager-stf-default-0                                        2/2     Running   0          97s
elastic-operator-5858dbbf55-dzlrw                                 1/1     Running   0          5m9s
elasticsearch-es-default-0                                        1/1     Running   0          80s
interconnect-operator-688f9b47bf-x5tc2                            1/1     Running   0          3m38s
prometheus-operator-6f5cf8db54-l2w4w                              1/1     Running   0          3m32s
prometheus-stf-default-0                                          3/3     Running   1          100s
service-telemetry-operator-678f8d4fc7-s7lgz                       2/2     Running   0          3m32s
smart-gateway-operator-c9798d678-n87m7                            2/2     Running   0          3m28s
stf-default-ceilometer-notification-smartgateway-66bf8bffcctt8p   1/1     Running   1          36s
stf-default-ceilometer-telemetry-smartgateway-dd8d755dc-7tfrf     1/1     Running   0          70s
stf-default-collectd-notification-smartgateway-85f4b6cd5f-vfmvw   1/1     Running   2          47s
stf-default-collectd-telemetry-smartgateway-6b978bc9-gjbh8        2/2     Running   0          83s
stf-default-interconnect-db474ccf8-wfp8w                          1/1     Running   0          102s

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc get route
NAME                             HOST/PORT                                                           PATH   SERVICES                   PORT    TERMINATION        WILDCARD
stf-default-interconnect-55671   stf-default-interconnect-55671-service-telemetry.apps-crc.testing          stf-default-interconnect   55671   passthrough/None   None
stf-default-interconnect-5671    stf-default-interconnect-5671-service-telemetry.apps-crc.testing           stf-default-interconnect   5671    passthrough/None   None
stf-default-interconnect-8672    stf-default-interconnect-8672-service-telemetry.apps-crc.testing           stf-default-interconnect   8672    edge/Redirect      None

[student@pool08-iad crc-linux-1.9.0-amd64]$ git clone https://github.com/infrawatch/dashboards
[student@pool08-iad crc-linux-1.9.0-amd64]$ cd dashboards
[student@pool08-iad dashboards]$ oc create -f deploy/subscription.yaml
subscription.operators.coreos.com/grafana-operator created

[student@pool08-iad dashboards]$  oc get csv grafana-operator.v3.2.0
NAME                      DISPLAY            VERSION   REPLACES                  PHASE
grafana-operator.v3.2.0   Grafana Operator   3.2.0     grafana-operator.v3.0.2   Succeeded

[student@pool08-iad dashboards]$ oc create -f deploy/grafana.yaml
grafana.integreatly.org/service-telemetry-grafana2 created

[student@pool08-iad dashboards]$ oc get pod -l app=grafana
NAME                                  READY   STATUS    RESTARTS   AGE
grafana-deployment-549c685ddc-m7vrf   1/1     Running   0          34s

[student@pool08-iad dashboards]$ oc create -f deploy/datasource.yaml -f deploy/rhos-dashboard.yaml
grafanadatasource.integreatly.org/service-telemetry-grafanadatasource created
grafanadashboard.integreatly.org/rhos-dashboard created

[student@pool08-iad dashboards]$ oc get route grafana-route
NAME            HOST/PORT                                          PATH   SERVICES          PORT   TERMINATION   WILDCARD
grafana-route   grafana-route-service-telemetry.apps-crc.testing          grafana-service   3000   edge          None

# Deploy Overcloud with External Ceph, Service Telemetry Framework and Advanced configuration
(undercloud) [stack@undercloud ~]$ openstack overcloud delete overcloud --yes

(undercloud) [stack@undercloud ~]$ openstack baremetal node list
/usr/lib/python3.6/site-packages/tripleoclient/v1/overcloud_delete.py:136: ResourceWarning: unclosed file <_io.BufferedReader name=6>
  python_interpreter=python_interpreter)
Undeploying stack overcloud...
Waiting for messages on queue 'tripleo' with no timeout.
Deleting plan overcloud...
Success.
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 57156)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=6, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 60272)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=8, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 58000), raddr=('192.0.2.2', 13989)>

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

(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/HostnameMap.yaml <<EOF
parameter_defaults:
  HostnameMap:
    overcloud-controller-0: lab-controller01
    overcloud-controller-1: lab-controller02
    overcloud-controller-2: lab-controller03
    overcloud-novacompute-0: lab-compute01
    overcloud-novacompute-1: lab-compute02
EOF

(undercloud) [stack@undercloud ~]$ grep -e name: -e _pools ~/templates/network_data.yaml|grep -v ipv6
- name: Storage
  allocation_pools: [{'start': '172.18.0.4', 'end': '172.18.0.250'}]
- name: StorageMgmt
  allocation_pools: [{'start': '172.19.0.4', 'end': '172.19.0.250'}]
- name: InternalApi
  allocation_pools: [{'start': '172.17.0.4', 'end': '172.17.0.250'}]
- name: Tenant
  allocation_pools: [{'start': '172.16.0.4', 'end': '172.16.0.250'}]
- name: External
  allocation_pools: [{'start': '10.0.0.4', 'end': '10.0.0.250'}]
- name: Management
  allocation_pools: [{'start': '10.0.1.4', 'end': '10.0.1.250'}]

(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/ips-from-pool-all.yaml <<EOF
parameter_defaults:
  ControllerIPs:
    # Each controller will get an IP from the lists below, first controller, first IP
    ctlplane:
    - 192.0.2.201
    - 192.0.2.202
    - 192.0.2.203
    external:
    - 10.0.0.201
    - 10.0.0.202
    - 10.0.0.203
    internal_api:
    - 172.17.0.201
    - 172.17.0.202
    - 172.17.0.203
    storage:
    - 172.18.0.201
    - 172.18.0.202
    - 172.18.0.203
    storage_mgmt:
    - 172.19.0.201
    - 172.19.0.202
    - 172.19.0.203
    tenant:
    - 172.16.0.201
    - 172.16.0.202
    - 172.16.0.203
    #management:
    #management:
    #- 172.16.4.251
  ComputeIPs:
    # Each compute will get an IP from the lists below, first compute, first IP
    ctlplane:
    - 192.0.2.211
    - 192.0.2.212
    external:
    - 10.0.0.211
    - 10.0.0.212
    internal_api:
    - 172.17.0.211
    - 172.17.0.212
    storage:
    - 172.18.0.211
    - 172.18.0.212
    storage_mgmt:
    - 172.19.0.211
    - 172.19.0.212
    tenant:
    - 172.16.0.211
    - 172.16.0.212
    #management:
    #- 172.16.4.252
### VIPs ###

  ControlFixedIPs: [{'ip_address':'192.0.2.150'}]
  InternalApiVirtualFixedIPs: [{'ip_address':'172.17.0.150'}]
  PublicVirtualFixedIPs: [{'ip_address':'10.0.0.150'}]
  StorageVirtualFixedIPs: [{'ip_address':'172.18.0.150'}]
  StorageMgmtVirtualFixedIPs: [{'ip_address':'172.19.0.150'}]
  RedisVirtualFixedIPs: [{'ip_address':'172.17.0.151'}]
EOF

[root@workstation ~]# ceph -s

[root@workstation ~]# ceph auth add client.openstack mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rwx pool=images, allow rwx pool=backups, allow rwx pool=metrics'

[root@workstation ~]# for pool in volumes images vms backups metrics; do ceph osd pool create $pool 32; done

[root@workstation ~]# cephkey=$(sudo ceph auth get-key client.openstack)
[root@workstation ~]# fsid=$(grep fsid /etc/ceph/ceph.conf | awk '{print $3}')
[root@workstation ~]# 
cat > ceph-external.yaml <<EOF
parameter_defaults:
 CephClientKey: $cephkey
 CephClusterFSID: $fsid
 CephExternalMonHost: 172.18.0.61,172.18.0.62,172.18.0.63
EOF

[root@pool08-iad ~]# ssh 192.0.2.249 cat ceph-external.yaml | ssh stack@undercloud "tee templates/ceph-external.yaml"

(undercloud) [stack@undercloud ~]$ 
cat > /home/stack/templates/stf-connectors.yaml << EOF
parameter_defaults:
  CeilometerQdrPublishEvents: true
  MetricsQdrConnectors:
  - host: stf-default-interconnect-5671-service-telemetry.apps-crc.testing
    port: 443
    role: edge
    sslProfile: sslProfile
    verifyHostname: false
EOF

[root@pool08-iad ~]# iptables -I FORWARD 1 -j ACCEPT

(undercloud) [stack@undercloud ~]$ curl -v stf-default-interconnect-5671-service-telemetry.apps-crc.testing:443
* Rebuilt URL to: stf-default-interconnect-5671-service-telemetry.apps-crc.testing:443/
*   Trying 192.168.130.11...
* TCP_NODELAY set
* Connected to stf-default-interconnect-5671-service-telemetry.apps-crc.testing (192.168.130.11) port 443 (#0)
> GET / HTTP/1.1
> Host: stf-default-interconnect-5671-service-telemetry.apps-crc.testing:443
> User-Agent: curl/7.61.1
> Accept: */*
>
* Empty reply from server
* Connection #0 to host stf-default-interconnect-5671-service-telemetry.apps-crc.testing left intact
curl: (52) Empty reply from server

(undercloud) [stack@undercloud ~]$ 
cat > ~/deploy-with-ext-ceph-stf.sh <<\EOF
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/network-isolation.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible-external.yaml \
-e $THT/environments/metrics/ceilometer-write-qdr.yaml \
-e $THT/environments/enable-stf.yaml \
-e $THT/environments/ips-from-pool-all.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/node-info.yaml \
-e $CNF/ceph-external.yaml \
-e $CNF/HostnameMap.yaml \
-e $CNF/ips-from-pool-all.yaml \
-e $CNF/stf-connectors.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml
EOF

(undercloud) [stack@undercloud ~]$ chmod 0755 ~/deploy-with-ext-ceph-stf.sh
(undercloud) [stack@undercloud ~]$ time /bin/bash -x ~/deploy-with-ext-ceph-stf.sh

Ansible passed.
Overcloud configuration completed.
Overcloud Endpoint: http://10.0.0.150:5000
Overcloud Horizon Dashboard URL: http://10.0.0.150:80/dashboard
Overcloud rc file: /home/stack/overcloudrc
Overcloud Deployed
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 56656)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=5, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 59420), raddr=('192.0.2.2', 13004)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=7, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 52070), raddr=('192.0.2.2', 13989)>

real    55m22.436s
user    0m13.182s
sys     0m1.508s

(undercloud) [stack@undercloud ~]$ openstack stack environment show overcloud

(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+------------------+--------+----------------------+----------------+---------+
| ID                                   | Name             | Status | Networks             | Image          | Flavor  |
+--------------------------------------+------------------+--------+----------------------+----------------+---------+
| 5cc91431-4764-48d4-967f-aed6518902e8 | lab-controller02 | ACTIVE | ctlplane=192.0.2.202 | overcloud-full | control |
| ed500b04-67f6-429d-b1b2-7a4a3f6cb5c8 | lab-controller01 | ACTIVE | ctlplane=192.0.2.201 | overcloud-full | control |
| f12b28d7-8c70-434b-9819-4a801a4ab012 | lab-controller03 | ACTIVE | ctlplane=192.0.2.203 | overcloud-full | control |
| 3c30899e-d9ba-446f-a3da-706443d3b424 | lab-compute02    | ACTIVE | ctlplane=192.0.2.212 | overcloud-full | compute |
| 8c158b18-a76d-4a3f-9f9a-9ed9adfb057b | lab-compute01    | ACTIVE | ctlplane=192.0.2.211 | overcloud-full | compute |
+--------------------------------------+------------------+--------+----------------------+----------------+---------+

(undercloud) [stack@undercloud ~]$ openstack network list
+--------------------------------------+--------------+--------------------------------------+
| ID                                   | Name         | Subnets                              |
+--------------------------------------+--------------+--------------------------------------+
| 17005daa-a2e5-41fc-a60c-75e2629a43c9 | external     | 2463105b-8252-47d9-bafb-9541686d2841 |
| 4cabba20-7fd2-4018-92fd-84c0c392c1ce | storage      | ea2558ff-6835-422b-847a-75b8a7f96435 |
| 8c70a7ee-a5b4-4b60-8e37-8a737b4d2e16 | tenant       | 3dd5a245-ce1a-4bac-a753-f621cd7108bf |
| a09c8328-66e1-424a-810b-4b5593e47444 | ctlplane     | 437f7ef9-54e2-461f-a8c2-73132e5c3139 |
| d067cc5d-2a1b-4164-b8f0-feca936cc51b | internal_api | 98c1bbbd-f9a7-4e33-a16f-41d9f5fdfb4e |
| dd053d92-ea5f-4ad7-bce4-376137013dac | storage_mgmt | f26b9f14-dabe-4f94-8d71-82629e5b9bd0 |
| f79af7bc-96a4-4b48-9cf7-50e659abea3b | management   | dcadc8be-91fe-4d1f-9175-463457344a86 |
+--------------------------------------+--------------+--------------------------------------+

(undercloud) [stack@undercloud ~]$ openstack subnet list
+--------------------------------------+---------------------+--------------------------------------+---------------+
| ID                                   | Name                | Network                              | Subnet        |
+--------------------------------------+---------------------+--------------------------------------+---------------+
| 2463105b-8252-47d9-bafb-9541686d2841 | external_subnet     | 17005daa-a2e5-41fc-a60c-75e2629a43c9 | 10.0.0.0/24   |
| 3dd5a245-ce1a-4bac-a753-f621cd7108bf | tenant_subnet       | 8c70a7ee-a5b4-4b60-8e37-8a737b4d2e16 | 172.16.0.0/24 |
| 437f7ef9-54e2-461f-a8c2-73132e5c3139 | ctlplane-subnet     | a09c8328-66e1-424a-810b-4b5593e47444 | 192.0.2.0/24  |
| 98c1bbbd-f9a7-4e33-a16f-41d9f5fdfb4e | internal_api_subnet | d067cc5d-2a1b-4164-b8f0-feca936cc51b | 172.17.0.0/24 |
| dcadc8be-91fe-4d1f-9175-463457344a86 | management_subnet   | f79af7bc-96a4-4b48-9cf7-50e659abea3b | 10.0.1.0/24   |
| ea2558ff-6835-422b-847a-75b8a7f96435 | storage_subnet      | 4cabba20-7fd2-4018-92fd-84c0c392c1ce | 172.18.0.0/24 |
| f26b9f14-dabe-4f94-8d71-82629e5b9bd0 | storage_mgmt_subnet | dd053d92-ea5f-4ad7-bce4-376137013dac | 172.19.0.0/24 |
+--------------------------------------+---------------------+--------------------------------------+---------------+

(undercloud) [stack@undercloud ~]$ openstack port list --device-owner " "
+--------------------------------------+-------------------------+-------------------+-----------------------------------------------------------------------------+--------+
| ID                                   | Name                    | MAC Address       | Fixed IP Addresses                                                          | Status |
+--------------------------------------+-------------------------+-------------------+-----------------------------------------------------------------------------+--------+
| 340437d0-a705-4e50-8216-6035f55e1b44 | internal_api_virtual_ip | fa:16:3e:85:e1:ba | ip_address='172.17.0.150', subnet_id='98c1bbbd-f9a7-4e33-a16f-41d9f5fdfb4e' | DOWN   |
| 559f1c76-f0c8-4dc6-b591-a84bc1e9d224 | ovn_dbs_virtual_ip      | fa:16:3e:26:ef:b6 | ip_address='172.17.0.249', subnet_id='98c1bbbd-f9a7-4e33-a16f-41d9f5fdfb4e' | DOWN   |
| 69821e50-0a86-43a0-912a-647373380f1c | control_virtual_ip      | fa:16:3e:cd:cd:cd | ip_address='192.0.2.150', subnet_id='437f7ef9-54e2-461f-a8c2-73132e5c3139'  | DOWN   |
| 77f4bf40-30a8-43a2-9861-517652d427e9 | storage_virtual_ip      | fa:16:3e:7f:7f:fa | ip_address='172.18.0.150', subnet_id='ea2558ff-6835-422b-847a-75b8a7f96435' | DOWN   |
| ac0c490c-160c-4a22-8ec7-fc9a79172951 | public_virtual_ip       | fa:16:3e:f0:a1:9f | ip_address='10.0.0.150', subnet_id='2463105b-8252-47d9-bafb-9541686d2841'   | DOWN   |
| c4039ada-647c-42ec-8d0b-bce0c9874bb0 | redis_virtual_ip        | fa:16:3e:f6:83:34 | ip_address='172.17.0.151', subnet_id='98c1bbbd-f9a7-4e33-a16f-41d9f5fdfb4e' | DOWN   |
| d887131c-dd67-4d0f-95db-f04103be4b17 | storage_mgmt_virtual_ip | fa:16:3e:9c:1b:51 | ip_address='172.19.0.150', subnet_id='f26b9f14-dabe-4f94-8d71-82629e5b9bd0' | DOWN   |
+--------------------------------------+-------------------------+-------------------+-----------------------------------------------------------------------------+--------+

(undercloud) [stack@undercloud ~]$ grep AUTH_URL ~/overcloudrc
export OS_AUTH_URL=http://10.0.0.150:5000

(overcloud) [stack@undercloud ~]$ openstack catalog list
+-----------+----------------+-------------------------------------------------------------------------------+
| Name      | Type           | Endpoints                                                                     |
+-----------+----------------+-------------------------------------------------------------------------------+
| heat-cfn  | cloudformation | regionOne                                                                     |
|           |                |   admin: http://172.17.0.150:8000/v1                                          |
|           |                | regionOne                                                                     |
|           |                |   public: http://10.0.0.150:8000/v1                                           |
|           |                | regionOne                                                                     |
|           |                |   internal: http://172.17.0.150:8000/v1                                       |
|           |                |                                                                               |
| glance    | image          | regionOne                                                                     |
|           |                |   public: http://10.0.0.150:9292                                              |
|           |                | regionOne                                                                     |
|           |                |   admin: http://172.17.0.150:9292                                             |
|           |                | regionOne                                                                     |
|           |                |   internal: http://172.17.0.150:9292                                          |
|           |                |                                                                               |
...
| nova      | compute        | regionOne                                                                     |
|           |                |   internal: http://172.17.0.150:8774/v2.1                                     |
|           |                | regionOne                                                                     |
|           |                |   public: http://10.0.0.150:8774/v2.1                                         |
|           |                | regionOne                                                                     |
|           |                |   admin: http://172.17.0.150:8774/v2.1                                        |
|           |                |                                                                               |
+-----------+----------------+-------------------------------------------------------------------------------+

cat > alias-overcloud-rc << 'EOF'
alias c0="source ~/stackrc; ssh heat-admin@$( openstack server list | grep controller01 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias c1="source ~/stackrc; ssh heat-admin@$( openstack server list | grep controller02 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias c2="source ~/stackrc; ssh heat-admin@$( openstack server list | grep controller03 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias cp0="source ~/stackrc; ssh heat-admin@$( openstack server list | grep compute01 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias cp1="source ~/stackrc; ssh heat-admin@$( openstack server list | grep compute02 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
EOF

[heat-admin@lab-controller01 ~]$ ip a | grep -e 172 -e 10.0.0
    inet 172.19.0.201/24 brd 172.19.0.255 scope global vlan40
    inet 10.0.0.201/24 brd 10.0.0.255 scope global vlan10
    inet 172.17.0.201/24 brd 172.17.0.255 scope global vlan20
    inet 172.17.0.150/32 brd 172.17.0.255 scope global vlan20
    inet 172.17.0.249/32 brd 172.17.0.255 scope global vlan20
    inet 172.18.0.201/24 brd 172.18.0.255 scope global vlan30
    inet 172.16.0.201/24 brd 172.16.0.255 scope global vlan50

[heat-admin@lab-controller01 ~]$ sudo pcs status cluster
Cluster Status:
 Cluster Summary:
   * Stack: corosync
   * Current DC: lab-controller02 (version 2.0.3-5.el8_2.1-4b1f869f0f) - partition with quorum
   * Last updated: Wed Sep 23 00:53:41 2020
   * Last change:  Tue Sep 22 10:01:04 2020 by root via cibadmin on lab-controller01
   * 15 nodes configured
   * 47 resource instances configured
 Node List:
   * Online: [ lab-controller01 lab-controller02 lab-controller03 ]
   * GuestOnline: [ galera-bundle-0@lab-controller01 galera-bundle-1@lab-controller02 galera-bundle-2@lab-controller03 ovn-dbs-bundle-0@lab-controller01 ovn-dbs-bundle-1@lab-controller02 ovn-dbs-bundle-2@lab-controller03 rabbitmq-bundle-0@lab-controller01 rabbitmq-bundle-1@lab-controller02 rabbitmq-bundle-2@lab-controller03 redis-bundle-0@lab-controller01 redis-bundle-1@lab-controller02 redis-bundle-2@lab-controller03 ]

PCSD Status:
  lab-controller02: Online
  lab-controller01: Online
  lab-controller03: Online

[heat-admin@lab-controller01 ~]$ sudo podman exec -ti haproxy-bundle-podman-0 cat /etc/haproxy/haproxy.cfg

[heat-admin@lab-controller01 ~]$ sudo podman exec -ti haproxy-bundle-podman-0 cat /etc/haproxy/haproxy.cfg | grep -A10 glance_api
listen glance_api
  bind 10.0.0.150:9292 transparent
  bind 172.17.0.150:9292 transparent
  mode http
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
  http-request set-header X-Forwarded-Proto http if !{ ssl_fc }
  http-request set-header X-Forwarded-Port %[dst_port]
  option httpchk GET /healthcheck
  server lab-controller01.internalapi.localdomain 172.17.0.201:9292 check fall 5 inter 2000 rise 2
  server lab-controller02.internalapi.localdomain 172.17.0.202:9292 check fall 5 inter 2000 rise 2
  server lab-controller03.internalapi.localdomain 172.17.0.203:9292 check fall 5 inter 2000 rise 2

[heat-admin@lab-controller01 ~]$ sudo podman exec -ti glance_api grep rbd /etc/glance/glance-api.conf | grep -v '#'
enabled_backends=default_backend:rbd
[glance.store.rbd.store]
rbd_store_ceph_conf=/etc/ceph/ceph.conf
rbd_store_user=openstack
rbd_store_pool=images

[heat-admin@lab-controller01 ~]$ sudo podman exec -ti cinder_api  grep rbd /etc/cinder/cinder.conf | grep -v '#'
volume_driver=cinder.volume.drivers.rbd.RBDDriver
rbd_ceph_conf=/etc/ceph/ceph.conf
rbd_user=openstack
rbd_pool=volumes
rbd_flatten_volume_from_snapshot=False
rbd_secret_uuid=eb0670c0-e359-4cb3-bf11-c650b82118ef


[heat-admin@lab-compute01 ~]$ sudo podman exec -ti nova_compute  grep rbd /etc/nova/nova.conf | grep -v '#'
images_type=rbd
images_rbd_pool=vms
images_rbd_ceph_conf=/etc/ceph/ceph.conf
rbd_user=openstack
rbd_secret_uuid=eb0670c0-e359-4cb3-bf11-c650b82118ef

(overcloud) [stack@undercloud ~]$ 
openstack network create public \
  --external --provider-physical-network datacentre \
  --provider-network-type vlan --provider-segment 10

(overcloud) [stack@undercloud ~]$ 
openstack subnet create public-subnet \
  --no-dhcp --network public --subnet-range 10.0.0.0/24 \
  --allocation-pool start=10.0.0.100,end=10.0.0.200  \
  --gateway 10.0.0.1 --dns-nameserver 8.8.8.8

(overcloud) [stack@undercloud ~]$ qemu-img convert -f qcow2 -O raw cirros-0.4.0-x86_64-disk.img cirros-0.4.0-x86_64-disk.raw

(overcloud) [stack@undercloud ~]$ openstack image create cirros --public --file cirros-0.4.0-x86_64-disk.raw

[root@workstation ~]# rbd --id admin -p images ls
1ce6d54d-9c7c-49bb-b1b1-61236eae2641

(overcloud) [stack@undercloud ~]$ openstack flavor create --ram 512 --disk 1 --vcpus 1 m1.tiny

(overcloud) [stack@undercloud ~]$ openstack project create test

(overcloud) [stack@undercloud ~]$ openstack user create --project test --password r3dh4t1! test

(overcloud) [stack@undercloud ~]$ openstack role add --user test --project test member

(overcloud) [stack@undercloud ~]$ sed -e 's/=admin/=test/' -e 's/OS_PASSWORD=.*/OS_PASSWORD=r3dh4t1!/' -e 's/OS_CLOUDNAME=overcloud/OS_CLOUDNAME=overcloud_test/' overcloudrc > ~/testrc

(overcloud) [stack@undercloud ~]$ source ~/testrc
(overcloud_test) [stack@undercloud ~]$ openstack network create test

(overcloud_test) [stack@undercloud ~]$ 
openstack subnet create \
 --network test \
 --gateway 192.168.123.254 \
 --allocation-pool start=192.168.123.1,end=192.168.123.253 \
 --dns-nameserver 8.8.8.8 \
 --subnet-range 192.168.123.0/24 \
 test

(overcloud_test) [stack@undercloud ~]$ openstack router create test

(overcloud_test) [stack@undercloud ~]$ openstack router set --external-gateway public test

(overcloud_test) [stack@undercloud ~]$ openstack router add subnet test test

(overcloud_test) [stack@undercloud ~]$ 
openstack security group rule create \
 --ingress \
 --ethertype IPv4 \
 --protocol tcp \
 --dst-port 22 \
  default

(overcloud_test) [stack@undercloud ~]$ 
openstack security group rule create \
 --ingress \
 --ethertype IPv4 \
 --protocol icmp \
 default

(overcloud_test) [stack@undercloud ~]$ openstack security group list

(overcloud_test) [stack@undercloud ~]$ openstack security group show default

(overcloud_test) [stack@undercloud ~]$ openstack keypair create --public-key ~/.ssh/id_rsa.pub stack

(overcloud_test) [stack@undercloud ~]$ openstack floating ip create public


openstack server create  --flavor m1.tiny \
 --image cirros  --key-name stack \
 --security-group default \
 --network test test

(overcloud_test) [stack@undercloud ~]$ openstack server add floating ip test 10.0.0.124

(overcloud_test) [stack@undercloud ~]$ openstack server list
+--------------------------------------+------+--------+----------------------------------+--------+--------+
| ID                                   | Name | Status | Networks                         | Image  | Flavor |
+--------------------------------------+------+--------+----------------------------------+--------+--------+
| df8d9837-f627-4e9e-b3d1-3c252b010988 | test | ACTIVE | test=192.168.123.245, 10.0.0.124 | cirros |        |
+--------------------------------------+------+--------+----------------------------------+--------+--------+

(overcloud_test) [stack@undercloud ~]$ ping -c 3 10.0.0.124

(overcloud_test) [stack@undercloud ~]$ ssh cirros@10.0.0.124

$ ping -c3 google.com

[root@workstation ~]# rbd  -p vms ls
df8d9837-f627-4e9e-b3d1-3c252b010988_disk

[heat-admin@lab-controller01 ~]$ sudo podman ps -f name=metrics
CONTAINER ID  IMAGE                                                                         COMMAND      CREATED       STATUS           PORTS  NAMES
f80a19f7ec40  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-qdrouterd:16.1-49  kolla_start  16 hours ago  Up 16 hours ago         metrics_qdr

[heat-admin@lab-controller01 ~]$ sudo podman ps -f name=ceilometer
CONTAINER ID  IMAGE                                                                                       COMMAND      CREATED       STATUS           PORTS  NAMES
36bfc2494733  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-ceilometer-notification:16.1-45  kolla_start  16 hours ago  Up 16 hours ago         ceilometer_agent_notification
68e81356c3e6  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-ceilometer-central:16.1-45       kolla_start  16 hours ago  Up 16 hours ago         ceilometer_agent_central

[heat-admin@lab-controller01 ~]$ sudo podman ps -f name=collectd
CONTAINER ID  IMAGE                                                                        COMMAND      CREATED       STATUS           PORTS  NAMES
c02c7781bbc4  undercloud.ctlplane.localdomain:8787/rhosp-rhel8/openstack-collectd:16.1-50  kolla_start  16 hours ago  Up 16 hours ago         collectd

[heat-admin@lab-controller01 ~]$ sudo podman exec -it metrics_qdr cat /etc/qpid-dispatch/qdrouterd.conf

[heat-admin@lab-controller01 ~]$ QIP=172.17.0.201

[heat-admin@lab-controller01 ~]$ sudo podman exec -it metrics_qdr qdstat --bus=$QIP:5666 --connections
Connections
  id   host                                                                  container                                                                                                      role    dir  security                            authentication  tenant
  ===================================================================================================================================================================================================================================================================
  1    stf-default-interconnect-5671-service-telemetry.apps-crc.testing:443  stf-default-interconnect-db474ccf8-wfp8w                                                                       edge    out  TLSv1.2(DHE-RSA-AES256-GCM-SHA384)  anonymous-user  
  15   172.17.0.201:44332                                                    openstack.org/om/container/lab-controller01/ceilometer-agent-notification/25/b13fbd5c414e4deaa838909c74a3af67  normal  in   no-security                         no-auth         
  18   172.17.0.201:51630                                                    metrics                                                                                                        normal  in   no-security                         anonymous-user  
  664  172.17.0.201:56986                                                    919ad388-c412-4d80-aa42-f819c8ec52b3                                                                           normal  in   no-security                         no-auth         

[heat-admin@lab-controller01 ~]$ sudo podman exec -it metrics_qdr qdstat --bus=$QIP:5666 --links |grep  --color=never  -e Router -e type -e === -e _edge
Router Links
  type      dir  conn id  id    peer  class   addr                  phs  cap  pri  undel  unsett  deliv    presett  psdrop  acc  rej  rel  mod  delay  rate
  ===========================================================================================================================================================
  endpoint  out  1        5           local   _edge                      250  0    0      0       1876232  1876232  0       0    0    0    0    0      33

[student@pool08-iad crc-linux-1.9.0-amd64]$ POD=$(oc get pods -l application=stf-default-interconnect  -o custom-columns=POD:.metadata.name --no-headers) 

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc exec -it  $POD -- qdstat --connections
2020-09-23 01:38:57.022871 UTC
stf-default-interconnect-db474ccf8-wfp8w

Connections
  id  host                container                                                             role    dir  security                                authentication  tenant  last dlv      uptime
  =======================================================================================================================================================================================================
  1   10.128.0.161:59072  bridge-a4                                                             edge    in   no-security                             anonymous-user          000:00:00:00  000:17:02:39
  2   10.128.0.162:55508  rcv[stf-default-ceilometer-telemetry-smartgateway-dd8d755dc-7tfrf]    edge    in   no-security                             anonymous-user          -             000:17:02:37
  3   10.128.0.164:35600  rcv[stf-default-ceilometer-notification-smartgateway-66bf8bffcctt8p]  normal  in   no-security                             anonymous-user          000:00:08:46  000:17:02:11
  4   10.128.0.163:35158  rcv[stf-default-collectd-notification-smartgateway-85f4b6cd5f-vfmvw]  normal  in   no-security                             anonymous-user          000:00:30:51  000:17:02:04
  5   10.128.0.1:33208    Router.lab-compute01.localdomain                                      edge    in   TLSv1/SSLv3(DHE-RSA-AES256-GCM-SHA384)  anonymous-user          000:00:00:02  000:15:59:41
  6   10.128.0.1:33210    Router.lab-compute02.localdomain                                      edge    in   TLSv1/SSLv3(DHE-RSA-AES256-GCM-SHA384)  anonymous-user          000:00:00:02  000:15:59:41
  7   10.128.0.1:33272    Router.lab-controller02.localdomain                                   edge    in   TLSv1/SSLv3(DHE-RSA-AES256-GCM-SHA384)  anonymous-user          000:00:00:00  000:15:59:37
  9   10.128.0.1:33284    Router.lab-controller03.localdomain                                   edge    in   TLSv1/SSLv3(DHE-RSA-AES256-GCM-SHA384)  anonymous-user          000:00:00:00  000:15:59:37
  8   10.128.0.1:33280    Router.lab-controller01.localdomain                                   edge    in   TLSv1/SSLv3(DHE-RSA-AES256-GCM-SHA384)  anonymous-user          000:00:00:04  000:15:59:37
  10  127.0.0.1:51542     0c107b4b-a771-4cd0-bab0-62e996a61b63                                  normal  in   no-security                             no-auth                 000:00:00:00  000:00:00:00

[student@pool08-iad crc-linux-1.9.0-amd64]$ oc exec -it  $POD -- qdstat --address |grep --color=never -e stf -e Addresses -e class -e === -e telemetry
stf-default-interconnect-db474ccf8-wfp8w
Router Addresses
  class   addr                                 phs  distrib    pri  local  remote  in         out        thru  fallback
  =======================================================================================================================
  mobile  collectd/telemetry                   0    multicast  -    1      0       8,795,520  8,795,520  0     0

[root@workstation ~]# dnf groupinstall "Workstation" -y
[root@workstation ~]# systemctl set-default graphical
[root@workstation ~]# reboot

[heat-admin@lab-controller01 ~]$ sudo crudini --get /var/lib/config-data/puppet-generated/keystone/etc/keystone/keystone.conf token provider 
fernet

(overcloud_test) [stack@undercloud ~]$ source ~/overcloudrc
(overcloud) [stack@undercloud ~]$ 

(overcloud) [stack@undercloud ~]$ openstack token issue
+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Field      | Value                                                                                                                                                                                   |
+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| expires    | 2020-09-23T03:24:20+0000                                                                                                                                                                |
| id         | gAAAAABfarHUKDHTD_FDLJVJeHPoGzeaVrIDS63Gm6TBBB8jY_aAICX0fCguNC1ZWUjUpG18RJMvl-7z7bKYoRWm7tj5FTOPbxJNIH3FCxy6wVd48qtoRoXhjfzQ5F6tUe3eJsZ-uQ4uWTV097CcT5LNs-uduowoTOD27o7XnHzOp4QN5OCWCn4 |
| project_id | 53c8d204c59b4725a983a8b364a0e75c                                                                                                                                                        |
| user_id    | 76178987d59245f09d1e7ca012a6a978                                                                                                                                                        |
+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

[heat-admin@lab-controller01 ~]$ sudo crudini --get /var/lib/config-data/puppet-generated/keystone/etc/keystone/keystone.conf fernet_tokens key_repository
/etc/keystone/fernet-keys

[heat-admin@lab-controller01 ~]$ sudo ls /var/lib/config-data/puppet-generated/keystone/etc/keystone/fernet-keys
0  1

[heat-admin@lab-controller01 ~]$ sudo cat /var/lib/config-data/puppet-generated/keystone/etc/keystone/fernet-keys/1
rsd1II4c2vlPfe2wM5Pj3aS-c1EugnC3cZ3ERg4H5x4=

[heat-admin@lab-controller01 ~]$ sudo cat /var/lib/config-data/puppet-generated/keystone/etc/keystone/fernet-keys/0
CbqsPe59ztViM0yVjkEpafYXbhEhdBTh9mk2lWe2Ob0=

(undercloud) [stack@undercloud ~]$ openstack workflow execution create tripleo.fernet_keys.v1.rotate_fernet_keys '{"container": "overcloud"}'
+--------------------+-------------------------------------------+
| Field              | Value                                     |
+--------------------+-------------------------------------------+
| ID                 | be419f16-a7d3-464c-b7c7-5ffc493f2706      |
| Workflow ID        | 9f8fb35f-52ce-4237-8459-8a4e363550cf      |
| Workflow name      | tripleo.fernet_keys.v1.rotate_fernet_keys |
| Workflow namespace |                                           |
| Description        |                                           |
| Task Execution ID  | <none>                                    |
| Root Execution ID  | <none>                                    |
| State              | RUNNING                                   |
| State info         | None                                      |
| Created at         | 2020-09-23 02:27:54                       |
| Updated at         | 2020-09-23 02:27:54                       |
+--------------------+-------------------------------------------+

(undercloud) [stack@undercloud ~]$ openstack workflow execution show be419f16-a7d3-464c-b7c7-5ffc493f2706 
+--------------------+-------------------------------------------+
| Field              | Value                                     |
+--------------------+-------------------------------------------+
| ID                 | be419f16-a7d3-464c-b7c7-5ffc493f2706      |
| Workflow ID        | 9f8fb35f-52ce-4237-8459-8a4e363550cf      |
| Workflow name      | tripleo.fernet_keys.v1.rotate_fernet_keys |
| Workflow namespace |                                           |
| Description        |                                           |
| Task Execution ID  | <none>                                    |
| Root Execution ID  | <none>                                    |
| State              | SUCCESS                                   |
| State info         | None                                      |
| Created at         | 2020-09-23 02:27:54                       |
| Updated at         | 2020-09-23 02:28:22                       |
+--------------------+-------------------------------------------+

[heat-admin@lab-controller01 ~]$ sudo ls /var/lib/config-data/puppet-generated/keystone/etc/keystone/fernet-keys
0  1  2

[heat-admin@lab-controller01 ~]$ sudo cat /var/lib/config-data/puppet-generated/keystone/etc/keystone/fernet-keys/2
CbqsPe59ztViM0yVjkEpafYXbhEhdBTh9mk2lWe2Ob0=

(undercloud) [stack@undercloud ~]$ openstack tripleo validator list

(undercloud) [stack@undercloud ~]$ openstack tripleo validator run --validation controller-ulimits
/usr/lib/python3.6/site-packages/tripleoclient/v1/tripleo_validator.py:437: ResourceWarning: unclosed file <_io.BufferedReader name=8>
  gathering_policy=gathering_policy)
+--------------------------------------+--------------------+--------+---------------+------------------------------------------------------+---------------------+-------------+
| UUID                                 | Validations        | Status | Host Group(s) | Status by Host                                       | Unreachable Host(s) | Duration    |
+--------------------------------------+--------------------+--------+---------------+------------------------------------------------------+---------------------+-------------+
| 525400bb-1867-9401-6c3d-00000000000b | controller-ulimits | PASSED | Controller    | lab-controller01, lab-controller02, lab-controller03 |                     | 0:00:03.253 |
+--------------------------------------+--------------------+--------+---------------+------------------------------------------------------+---------------------+-------------+
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 56904), raddr=('192.0.2.2', 13000)>


(undercloud) [stack@undercloud ~]$ openstack tripleo validator run --validation stonith-exists
+--------------------------------------+----------------+--------+---------------+------------------------------------------------------+---------------------+-------------+
| UUID                                 | Validations    | Status | Host Group(s) | Status by Host                                       | Unreachable Host(s) | Duration    |
+--------------------------------------+----------------+--------+---------------+------------------------------------------------------+---------------------+-------------+
| 525400bb-1867-8f72-8177-00000000000b | stonith-exists | FAILED | Controller    | lab-controller01, lab-controller02, lab-controller03 |                     | 0:00:03.354 |
+--------------------------------------+----------------+--------+---------------+------------------------------------------------------+---------------------+-------------+
One or more validations have failed!
/usr/lib64/python3.6/_weakrefset.py:59: ResourceWarning: unclosed file <_io.FileIO name=7 mode='rb' closefd=True>
  with _IterationGuard(self):
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 57532), raddr=('192.0.2.2', 13000)>

# Fix the fencing validation
[heat-admin@lab-controller01 ~]$ sudo pcs property show
Cluster Properties:
 OVN_REPL_INFO: lab-controller01
 cluster-infrastructure: corosync
 cluster-name: tripleo_cluster
 dc-version: 2.0.3-5.el8_2.1-4b1f869f0f
 have-watchdog: false
 redis_REPL_INFO: lab-controller01
 stonith-enabled: false

# Generate a fencing.yaml file using the following command:
 (undercloud) [stack@undercloud ~]$ openstack overcloud generate fencing --ipmi-lanplus --ipmi-level administrator --output ~/templates/fencing.yaml nodes.json

(undercloud) [stack@undercloud ~]$ head -20 ~/templates/fencing.yaml
parameter_defaults:
  EnableFencing: true
  FencingConfig:
    devices:
    - agent: fence_ipmilan
      host_mac: 52:54:00:9f:d5:9e
      params:
        ipaddr: 192.168.1.1
        ipport: '6234'
        lanplus: true
        login: admin
        passwd: password
        pcmk_host_list: lab-compute02
        privlvl: administrator
    - agent: fence_ipmilan
      host_mac: 52:54:00:cf:6d:7b
      params:
        ipaddr: 192.168.1.1
        ipport: '6235'
        lanplus: true


(undercloud) [stack@undercloud ~]$ 
cat > deploy-with-ext-ceph-stf.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/network-isolation.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible-external.yaml \
-e $THT/environments/metrics/ceilometer-write-qdr.yaml \
-e $THT/environments/enable-stf.yaml \
-e $THT/environments/ips-from-pool-all.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/node-info.yaml \
-e $CNF/ceph-external.yaml \
-e $CNF/HostnameMap.yaml \
-e $CNF/ips-from-pool-all.yaml \
-e $CNF/stf-connectors.yaml \
-e $CNF/fencing.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml
EOF

(undercloud) [stack@undercloud ~]$ time /bin/bash -x ./deploy-with-ext-ceph-stf.sh 2>&1 | tee /tmp/err 
...
Ansible passed.
Overcloud configuration completed.
Overcloud Endpoint: http://10.0.0.150:5000
Overcloud Horizon Dashboard URL: http://10.0.0.150:80/dashboard
Overcloud rc file: /home/stack/overcloudrc
Overcloud Deployed
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 33588)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=5, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 32788), raddr=('192.0.2.2', 13004)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=7, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 53688), raddr=('192.0.2.2', 13989)>

real    45m37.309s
user    0m15.198s
sys     0m1.620s

(undercloud) [stack@undercloud ~]$ openstack tripleo validator run --validation stonith-exists
/usr/lib/python3.6/site-packages/tripleoclient/v1/tripleo_validator.py:437: ResourceWarning: unclosed file <_io.BufferedReader name=8>
  gathering_policy=gathering_policy)
+--------------------------------------+----------------+--------+---------------+------------------------------------------------------+---------------------+-------------+
| UUID                                 | Validations    | Status | Host Group(s) | Status by Host                                       | Unreachable Host(s) | Duration    |
+--------------------------------------+----------------+--------+---------------+------------------------------------------------------+---------------------+-------------+
| 525400bb-1867-8741-378e-00000000000b | stonith-exists | PASSED | Controller    | lab-controller01, lab-controller02, lab-controller03 |                     | 0:00:05.193 |
+--------------------------------------+----------------+--------+---------------+------------------------------------------------------+---------------------+-------------+
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 42724), raddr=('192.0.2.2', 13000)>

(undercloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane "sudo pcs property show"
The authenticity of host 'lab-controller01.ctlplane (192.0.2.201)' can't be established.
ECDSA key fingerprint is SHA256:k0Ii1vJCRDEByMoIz0lHHnDUd0BacwPaqlRTrP5veu4.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'lab-controller01.ctlplane' (ECDSA) to the list of known hosts.
Cluster Properties:
 OVN_REPL_INFO: lab-controller01
 cluster-infrastructure: corosync
 cluster-name: tripleo_cluster
 dc-version: 2.0.3-5.el8_2.1-4b1f869f0f
 have-watchdog: false
 redis_REPL_INFO: lab-controller01
 stonith-enabled: true

 (undercloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane "sudo pcs status | grep fence"
  * stonith-fence_ipmilan-525400f9dd26  (stonith:fence_ipmilan):        Started lab-controller01
  * stonith-fence_ipmilan-5254002b9c80  (stonith:fence_ipmilan):        Started lab-controller03
  * stonith-fence_ipmilan-52540056484d  (stonith:fence_ipmilan):        Started lab-controller02

[heat-admin@lab-controller02 ~]# 
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT &&
 iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT &&
 iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 5016 -j ACCEPT &&
 iptables -A INPUT -p udp -m state --state NEW -m udp --dport 5016 -j ACCEPT &&
 iptables -A INPUT ! -i lo -j REJECT --reject-with icmp-host-prohibited &&
 iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT &&
 iptables -A OUTPUT -p tcp --sport 5016 -j ACCEPT &&
 iptables -A OUTPUT -p udp --sport 5016 -j ACCEPT &&
 iptables -A OUTPUT ! -o lo -j REJECT --reject-with icmp-host-prohibited

[heat-admin@lab-controller02 ~]$ sudo grep fencing /var/log/pacemaker/pacemaker.log |grep -v "is active"
Sep 23 03:40:01 lab-controller02 pacemaker-schedulerd[40642] (fence_guest)      info: Implying guest node ovn-dbs-bundle-0 is down (action 262) after lab-controller01 fencing
Sep 23 03:40:01 lab-controller02 pacemaker-schedulerd[40642] (fence_guest)      info: Implying guest node rabbitmq-bundle-0 is down (action 267) after lab-controller01 fencing
Sep 23 03:40:01 lab-controller02 pacemaker-schedulerd[40642] (fence_guest)      info: Implying guest node redis-bundle-0 is down (action 272) after lab-controller01 fencing
Sep 23 03:40:01 lab-controller02 pacemaker-controld  [40643] (te_fence_node)    notice: Requesting fencing (reboot) of node lab-controller01 | action=1 timeout=60000
Sep 23 03:40:01 lab-controller02 pacemaker-fenced    [40639] (initiate_remote_stonith_op)       notice: Requesting peer fencing (reboot) targeting lab-controller01 | id=ef4eb443-bbb3-4aa4-8e7e-1724ee63e76d state=0
Sep 23 03:40:01 lab-controller02 pacemaker-fenced    [40639] (call_remote_stonith)      info: Total timeout set to 60 for peer's fencing targeting lab-controller01 for pacemaker-controld.40643|id=ef4eb443-bbb3-4aa4-8e7e-1724ee63e76d
Sep 23 03:40:58 lab-controller02 pacemaker-controld  [40643] (cib_fencing_updated)      info: Fencing update 449 for lab-controller01: complete
Sep 23 03:40:58 lab-controller02 pacemaker-controld  [40643] (cib_fencing_updated)      info: Fencing update 451 for lab-controller01: complete


### day 3
# Compute Node Replacement Lab
(overcloud) [stack@undercloud ~]$ openstack hypervisor list
+--------------------------------------+---------------------------+-----------------+--------------+-------+
| ID                                   | Hypervisor Hostname       | Hypervisor Type | Host IP      | State |
+--------------------------------------+---------------------------+-----------------+--------------+-------+
| e2882f92-3ff7-4e44-ab9c-68e663b0eea0 | lab-compute02.localdomain | QEMU            | 172.17.0.212 | up    |
| 74c66213-7395-43b0-87fe-97ec9583c6dd | lab-compute01.localdomain | QEMU            | 172.17.0.211 | up    |
+--------------------------------------+---------------------------+-----------------+--------------+-------+

(overcloud) [stack@undercloud ~]$ openstack server list --all-projects --long
+--------------------------------------+------+--------+------------+-------------+----------------------------------+------------+--------------------------------------+-------------+-----------+-------------------+---------------------------+------------+
| ID                                   | Name | Status | Task State | Power State | Networks                         | Image Name | Image ID                             | Flavor Name | Flavor ID | Availability Zone | Host                      | Properties |
+--------------------------------------+------+--------+------------+-------------+----------------------------------+------------+--------------------------------------+-------------+-----------+-------------------+---------------------------+------------+
| df8d9837-f627-4e9e-b3d1-3c252b010988 | test | ACTIVE | None       | Running     | test=192.168.123.245, 10.0.0.124 | cirros     | 1ce6d54d-9c7c-49bb-b1b1-61236eae2641 |             |           | nova              | lab-compute02.localdomain |            |
+--------------------------------------+------+--------+------------+-------------+----------------------------------+------------+--------------------------------------+-------------+-----------+-------------------+---------------------------+------------+

(overcloud) [stack@undercloud ~]$ openstack compute service set lab-compute02.localdomain  nova-compute --disable
(overcloud) [stack@undercloud ~]$ openstack compute service list
+--------------------------------------+----------------+------------------------------+----------+----------+-------+----------------------------+
| ID                                   | Binary         | Host                         | Zone     | Status   | State | Updated At                 |
+--------------------------------------+----------------+------------------------------+----------+----------+-------+----------------------------+
| d0fd7711-0d73-4fc4-b203-2a303fb07d4a | nova-conductor | lab-controller01.localdomain | internal | enabled  | up    | 2020-09-23T05:31:38.000000 |
| 5e3be132-bcb0-42da-a9f5-5ab7292721de | nova-conductor | lab-controller03.localdomain | internal | enabled  | up    | 2020-09-23T05:31:41.000000 |
| b00fca95-4b46-4593-9633-22ffc2b52a67 | nova-conductor | lab-controller02.localdomain | internal | enabled  | up    | 2020-09-23T05:31:41.000000 |
| 04b3256f-72d9-416a-8ddd-2edd9997d7fe | nova-scheduler | lab-controller01.localdomain | internal | enabled  | up    | 2020-09-23T05:31:37.000000 |
| 02a3421a-cf8b-47f2-88a0-db50f8b03b68 | nova-scheduler | lab-controller02.localdomain | internal | enabled  | up    | 2020-09-23T05:31:42.000000 |
| 8f4c4221-fd76-4b7e-937c-30de17c7878f | nova-scheduler | lab-controller03.localdomain | internal | enabled  | up    | 2020-09-23T05:31:42.000000 |
| 0c7eda28-489f-41b4-bd5c-fb9184d90f1d | nova-compute   | lab-compute02.localdomain    | nova     | disabled | up    | 2020-09-23T05:31:38.000000 |
| 773ea88e-b3fc-4dcd-ac36-1a3be0440409 | nova-compute   | lab-compute01.localdomain    | nova     | enabled  | up    | 2020-09-23T05:31:43.000000 |
+--------------------------------------+----------------+------------------------------+----------+----------+-------+----------------------------+

(overcloud) [stack@undercloud ~]$ openstack server migrate --shared-migration df8d9837-f627-4e9e-b3d1-3c252b010988

(overcloud) [stack@undercloud ~]$ openstack server list --all-projects --host lab-compute02.localdomain

(overcloud) [stack@undercloud ~]$ openstack server list --all-projects --host lab-compute01.localdomain
+--------------------------------------+------+---------------+----------------------------------+--------+--------+
| ID                                   | Name | Status        | Networks                         | Image  | Flavor |
+--------------------------------------+------+---------------+----------------------------------+--------+--------+
| df8d9837-f627-4e9e-b3d1-3c252b010988 | test | VERIFY_RESIZE | test=192.168.123.245, 10.0.0.124 | cirros |        |
+--------------------------------------+------+---------------+----------------------------------+--------+--------+

(overcloud) [stack@undercloud ~]$ openstack server resize confirm df8d9837-f627-4e9e-b3d1-3c252b010988

(overcloud) [stack@undercloud ~]$ openstack server list --all-projects --host lab-compute01.localdomain
+--------------------------------------+------+--------+----------------------------------+--------+--------+
| ID                                   | Name | Status | Networks                         | Image  | Flavor |
+--------------------------------------+------+--------+----------------------------------+--------+--------+
| df8d9837-f627-4e9e-b3d1-3c252b010988 | test | ACTIVE | test=192.168.123.245, 10.0.0.124 | cirros |        |
+--------------------------------------+------+--------+----------------------------------+--------+--------+

(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+------------------+--------+----------------------+----------------+---------+
| ID                                   | Name             | Status | Networks             | Image          | Flavor  |
+--------------------------------------+------------------+--------+----------------------+----------------+---------+
| 5cc91431-4764-48d4-967f-aed6518902e8 | lab-controller02 | ACTIVE | ctlplane=192.0.2.202 | overcloud-full | control |
| ed500b04-67f6-429d-b1b2-7a4a3f6cb5c8 | lab-controller01 | ACTIVE | ctlplane=192.0.2.201 | overcloud-full | control |
| f12b28d7-8c70-434b-9819-4a801a4ab012 | lab-controller03 | ACTIVE | ctlplane=192.0.2.203 | overcloud-full | control |
| 3c30899e-d9ba-446f-a3da-706443d3b424 | lab-compute02    | ACTIVE | ctlplane=192.0.2.212 | overcloud-full | compute |
| 8c158b18-a76d-4a3f-9f9a-9ed9adfb057b | lab-compute01    | ACTIVE | ctlplane=192.0.2.211 | overcloud-full | compute |
+--------------------------------------+------------------+--------+----------------------+----------------+---------+

(undercloud) [stack@undercloud ~]$ time openstack overcloud node delete 3c30899e-d9ba-446f-a3da-706443d3b424
...
PLAY RECAP *********************************************************************
lab-compute02              : ok=13   changed=4    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0

Wednesday 23 September 2020  01:39:18 -0400 (0:00:00.061)       0:00:27.364 ***
===============================================================================

Ansible passed.
Scale-down configuration completed.
Waiting for messages on queue 'tripleo' with no timeout.
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 40786)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=5, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 43794)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=7, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 45230)>

real    8m50.590s
user    0m2.042s
sys     0m0.463s

(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+------------------+--------+----------------------+----------------+---------+
| ID                                   | Name             | Status | Networks             | Image          | Flavor  |
+--------------------------------------+------------------+--------+----------------------+----------------+---------+
| 5cc91431-4764-48d4-967f-aed6518902e8 | lab-controller02 | ACTIVE | ctlplane=192.0.2.202 | overcloud-full | control |
| ed500b04-67f6-429d-b1b2-7a4a3f6cb5c8 | lab-controller01 | ACTIVE | ctlplane=192.0.2.201 | overcloud-full | control |
| f12b28d7-8c70-434b-9819-4a801a4ab012 | lab-controller03 | ACTIVE | ctlplane=192.0.2.203 | overcloud-full | control |
| 8c158b18-a76d-4a3f-9f9a-9ed9adfb057b | lab-compute01    | ACTIVE | ctlplane=192.0.2.211 | overcloud-full | compute |
+--------------------------------------+------------------+--------+----------------------+----------------+---------+

(undercloud) [stack@undercloud ~]$ openstack baremetal node list
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+
| UUID                                 | Name                | Instance UUID                        | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+
| ad3e3612-fa87-499b-bda4-f29f5d99952f | overcloud-compute01 | None                                 | power off   | available          | False       |
| 87f78af7-20af-41d0-860b-e206cac5ea87 | overcloud-compute02 | 8c158b18-a76d-4a3f-9f9a-9ed9adfb057b | power on    | active             | False       |
| 629e932c-e32c-438e-a3c8-403eac0e363d | overcloud-ctrl01    | ed500b04-67f6-429d-b1b2-7a4a3f6cb5c8 | power on    | active             | False       |
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | overcloud-ctrl02    | f12b28d7-8c70-434b-9819-4a801a4ab012 | power on    | active             | False       |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | overcloud-ctrl03    | 5cc91431-4764-48d4-967f-aed6518902e8 | power on    | active             | False       |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | overcloud-networker | None                                 | power off   | available          | False       |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | overcloud-stor01    | None                                 | power off   | available          | False       |
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+

[root@pool08-iad ~]# /bin/bash -x setup-env-osp16-compute03.sh 

[root@pool08-iad ~]# vbmc list
+---------------------+---------+-------------+------+
|     Domain name     |  Status |   Address   | Port |
+---------------------+---------+-------------+------+
| overcloud-compute01 | running | 192.168.1.1 | 6234 |
| overcloud-compute02 | running | 192.168.1.1 | 6235 |
| overcloud-compute03 | running | 192.168.1.1 | 6240 |
|   overcloud-ctrl01  | running | 192.168.1.1 | 6231 |
|   overcloud-ctrl02  | running | 192.168.1.1 | 6232 |
|   overcloud-ctrl03  | running | 192.168.1.1 | 6233 |
| overcloud-networker | running | 192.168.1.1 | 6239 |
|   overcloud-stor01  | running | 192.168.1.1 | 6236 |
|      undercloud     | running | 192.168.1.1 | 6230 |
+---------------------+---------+-------------+------+
Exception TypeError: "'NoneType' object is not callable" in <function _removeHandlerRef at 0x7fb41f1cbb90> ignored

[root@pool08-iad ~]# virsh list --all 
 Id    Name                           State
----------------------------------------------------
 23    undercloud                     running
 30    workstation                    running
 40    ceph-node01                    running
 41    ceph-node02                    running
 42    ceph-node03                    running
 43    crc                            running
 49    overcloud-compute02            running
 51    overcloud-ctrl02               running
 52    overcloud-ctrl03               running
 54    overcloud-ctrl01               running
 -     overcloud-compute01            shut off
 -     overcloud-compute03            shut off
 -     overcloud-networker            shut off
 -     overcloud-stor01               shut off


[root@pool08-iad ~]# /bin/bash -x ./gen_instackenv_compute03.sh 

[root@pool08-iad ~]# 
cat > instackenv_compute03.json << EOF
{
  "nodes": [
    {
      "pm_user": "admin",
      "pm_type": "pxe_ipmitool",
      "pm_password": "password",
      "pm_port": "6240",
      "pm_addr": "192.168.1.1",
      "name": "overcloud-compute03",
      "mac": [
        "52:54:00:19:68:bb"
      ]
    }
  ]
}
EOF

[root@pool08-iad ~]# scp instackenv_compute03.json stack@undercloud.example.com:~/nodes_compute03.json

(undercloud) [stack@undercloud ~]$ openstack overcloud node import --validate-only nodes_compute03.json  

(undercloud) [stack@undercloud ~]$ openstack overcloud node import --introspect --provide nodes_compute03.json 

(undercloud) [stack@undercloud ~]$ openstack baremetal node list
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+
| UUID                                 | Name                | Instance UUID                        | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+
| ad3e3612-fa87-499b-bda4-f29f5d99952f | overcloud-compute01 | None                                 | power off   | available          | False       |
| 87f78af7-20af-41d0-860b-e206cac5ea87 | overcloud-compute02 | 8c158b18-a76d-4a3f-9f9a-9ed9adfb057b | power on    | active             | False       |
| 629e932c-e32c-438e-a3c8-403eac0e363d | overcloud-ctrl01    | ed500b04-67f6-429d-b1b2-7a4a3f6cb5c8 | power on    | active             | False       |
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | overcloud-ctrl02    | f12b28d7-8c70-434b-9819-4a801a4ab012 | power on    | active             | False       |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | overcloud-ctrl03    | 5cc91431-4764-48d4-967f-aed6518902e8 | power on    | active             | False       |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | overcloud-networker | None                                 | power off   | available          | False       |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | overcloud-stor01    | None                                 | power off   | available          | False       |
| 0c523f61-cc33-4e99-8f06-4fa1690b97d8 | overcloud-compute03 | None                                 | power off   | available          | False       |
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+

(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:compute overcloud-compute03

(undercloud) [stack@undercloud ~]$ openstack baremetal node maintenance set overcloud-compute01 

(undercloud) [stack@undercloud ~]$ openstack baremetal node list
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+
| UUID                                 | Name                | Instance UUID                        | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+
| ad3e3612-fa87-499b-bda4-f29f5d99952f | overcloud-compute01 | None                                 | power off   | available          | True        |
| 87f78af7-20af-41d0-860b-e206cac5ea87 | overcloud-compute02 | 8c158b18-a76d-4a3f-9f9a-9ed9adfb057b | power on    | active             | False       |
| 629e932c-e32c-438e-a3c8-403eac0e363d | overcloud-ctrl01    | ed500b04-67f6-429d-b1b2-7a4a3f6cb5c8 | power on    | active             | False       |
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | overcloud-ctrl02    | f12b28d7-8c70-434b-9819-4a801a4ab012 | power on    | active             | False       |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | overcloud-ctrl03    | 5cc91431-4764-48d4-967f-aed6518902e8 | power on    | active             | False       |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | overcloud-networker | None                                 | power off   | available          | False       |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | overcloud-stor01    | None                                 | power off   | available          | False       |
| 0c523f61-cc33-4e99-8f06-4fa1690b97d8 | overcloud-compute03 | None                                 | power off   | available          | False       |
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+

(undercloud) [stack@undercloud ~]$ openstack overcloud profiles list
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+
| Node UUID                            | Node Name           | Provision State | Current Profile | Possible Profiles |
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+
| 87f78af7-20af-41d0-860b-e206cac5ea87 | overcloud-compute02 | active          | compute         |                   |
| 629e932c-e32c-438e-a3c8-403eac0e363d | overcloud-ctrl01    | active          | control         |                   |
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | overcloud-ctrl02    | active          | control         |                   |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | overcloud-ctrl03    | active          | control         |                   |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | overcloud-networker | available       | None            |                   |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | overcloud-stor01    | available       | None            |                   |
| 0c523f61-cc33-4e99-8f06-4fa1690b97d8 | overcloud-compute03 | available       | compute         |                   |
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+

(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/HostnameMap.yaml << EOF
parameter_defaults:
  HostnameMap:
    overcloud-controller-0: lab-controller01
    overcloud-controller-1: lab-controller02
    overcloud-controller-2: lab-controller03
    overcloud-novacompute-0: lab-compute01
    overcloud-novacompute-5: lab-compute02
EOF

(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+-------------------------+--------+----------------------+----------------+---------+
| ID                                   | Name                    | Status | Networks             | Image          | Flavor  |
+--------------------------------------+-------------------------+--------+----------------------+----------------+---------+
| b58f5fa9-257f-4b86-8ece-d3e3054ac0a3 | overcloud-novacompute-2 | ACTIVE | ctlplane=192.0.2.8   | overcloud-full | compute |
| 5cc91431-4764-48d4-967f-aed6518902e8 | lab-controller02        | ACTIVE | ctlplane=192.0.2.202 | overcloud-full | control |
| ed500b04-67f6-429d-b1b2-7a4a3f6cb5c8 | lab-controller01        | ACTIVE | ctlplane=192.0.2.201 | overcloud-full | control |
| f12b28d7-8c70-434b-9819-4a801a4ab012 | lab-controller03        | ACTIVE | ctlplane=192.0.2.203 | overcloud-full | control |
| 8c158b18-a76d-4a3f-9f9a-9ed9adfb057b | lab-compute01           | ACTIVE | ctlplane=192.0.2.211 | overcloud-full | compute |
+--------------------------------------+-------------------------+--------+----------------------+----------------+---------+

(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/HostnameMap.yaml << EOF
parameter_defaults:
  HostnameMap:
    overcloud-controller-0: lab-controller01
    overcloud-controller-1: lab-controller02
    overcloud-controller-2: lab-controller03
    overcloud-novacompute-0: lab-compute01
    overcloud-novacompute-5: lab-compute02
EOF

# 参见：https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html/advanced_overcloud_customization/sect-controlling_node_placement
(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/ips-from-pool-all.yaml <<EOF
parameter_defaults:
  ControllerIPs:
    # Each controller will get an IP from the lists below, first controller, first IP
    ctlplane:
    - 192.0.2.201
    - 192.0.2.202
    - 192.0.2.203
    external:
    - 10.0.0.201
    - 10.0.0.202
    - 10.0.0.203
    internal_api:
    - 172.17.0.201
    - 172.17.0.202
    - 172.17.0.203
    storage:
    - 172.18.0.201
    - 172.18.0.202
    - 172.18.0.203
    storage_mgmt:
    - 172.19.0.201
    - 172.19.0.202
    - 172.19.0.203
    tenant:
    - 172.16.0.201
    - 172.16.0.202
    - 172.16.0.203
    #management:
    #management:
    #- 172.16.4.251
  ComputeIPs:
    # Each compute will get an IP from the lists below, first compute, first IP
    ctlplane:
    - 192.0.2.211
    - 192.0.2.212
    - 192.0.2.212
    - 192.0.2.212
    - 192.0.2.212
    - 192.0.2.212
    external:
    - 10.0.0.211
    - 10.0.0.212
    - 10.0.0.212
    - 10.0.0.212
    - 10.0.0.212
    - 10.0.0.212
    internal_api:
    - 172.17.0.211
    - 172.17.0.212
    - 172.17.0.212
    - 172.17.0.212
    - 172.17.0.212
    - 172.17.0.212
    storage:
    - 172.18.0.211
    - 172.18.0.212
    - 172.18.0.212
    - 172.18.0.212
    - 172.18.0.212
    - 172.18.0.212
    storage_mgmt:
    - 172.19.0.211
    - 172.19.0.212
    - 172.19.0.212
    - 172.19.0.212
    - 172.19.0.212
    - 172.19.0.212
    tenant:
    - 172.16.0.211
    - 172.16.0.212
    - 172.16.0.212
    - 172.16.0.212
    - 172.16.0.212
    - 172.16.0.212
    #management:
    #- 172.16.4.252
### VIPs ###

  ControlFixedIPs: [{'ip_address':'192.0.2.150'}]
  InternalApiVirtualFixedIPs: [{'ip_address':'172.17.0.150'}]
  PublicVirtualFixedIPs: [{'ip_address':'10.0.0.150'}]
  StorageVirtualFixedIPs: [{'ip_address':'172.18.0.150'}]
  StorageMgmtVirtualFixedIPs: [{'ip_address':'172.19.0.150'}]
  RedisVirtualFixedIPs: [{'ip_address':'172.17.0.151'}]
EOF

(undercloud) [stack@undercloud ~]$ time /bin/bash -x deploy-with-ext-ceph-stf.sh
...
Ansible passed.
Overcloud configuration completed.
Overcloud Endpoint: http://10.0.0.150:5000
Overcloud Horizon Dashboard URL: http://10.0.0.150:80/dashboard
Overcloud rc file: /home/stack/overcloudrc
Overcloud Deployed
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 59552)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=5, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 36182), raddr=('192.0.2.2', 13004)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=7, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 56920), raddr=('192.0.2.2', 13989)>

real    50m30.240s
user    0m16.124s
sys     0m1.580s

# Advanced Overcloud Deployed Lab

[root@pool08-iad ~]# for i in {1..3}; do virsh shutdown ceph-node0$i; done
Domain ceph-node01 is being shutdown

Domain ceph-node02 is being shutdown

Domain ceph-node03 is being shutdown

[root@pool08-iad ~]# virsh shutdown workstation
Domain workstation is being shutdown

[root@pool08-iad ~]# /bin/bash -x ./setup-env-ipa.sh 

[root@pool08-iad ~]# ssh root@192.168.0.252

[root@ipa ~]# yum module enable idm:DL1 -y
rhel-8-for-x86_64-baseos-eus-rpms                                                                                        78 MB/s |  20 MB     00:00    
rhel-8-for-x86_64-appstream-eus-rpms                                                                                     79 MB/s |  18 MB     00:00    
rhel-8-for-x86_64-highavailability-eus-rpms                                                                              60 MB/s | 1.7 MB     00:00    
ansible-2.9-for-rhel-8-x86_64-rpms                                                                                       47 MB/s | 835 kB     00:00    
fast-datapath-for-rhel-8-x86_64-rpms                                                                                    6.8 MB/s |  91 kB     00:00    
openstack-16.1-for-rhel-8-x86_64-rpms                                                                                    55 MB/s | 1.1 MB     00:00    
rhceph-4-tools-for-rhel-8-x86_64-rpms                                                                                    14 MB/s | 120 kB     00:00    
Dependencies resolved.
========================================================================================================================================================
 Package                             Architecture                       Version                               Repository                           Size
========================================================================================================================================================
Enabling module streams:
 389-ds                                                                 1.4                                                                            
 httpd                                                                  2.4                                                                            
 idm                                                                    DL1                                                                            
 pki-core                                                               10.6                                                                           
 pki-deps                                                               10.6                                                                           

Transaction Summary
========================================================================================================================================================

Complete!

[root@ipa ~]# yum distro-sync -y

[root@ipa ~]# yum module install idm:DL1/dns -y

[root@ipa ~]# echo "192.168.0.252 ipa.example.com" >> /etc/hosts

[root@ipa ~]# ipa-server-install -a r3dh4t1\! --hostname=ipa.example.com -r EXAMPLE.COM -p r3dh4t1\!  -n example.com -U --setup-dns  --allow-zone-overlap --auto-forwarders

[root@ipa ~]# echo 'r3dh4t1!' | kinit admin
[root@ipa ~]# ipa dnsrecord-add example.com overcloud --a-ip-address=192.168.0.150

[root@ipa ~]# ipa dnsrecord-add example.com overcloud.ctlplane --a-ip-address=192.0.2.150
[root@ipa ~]# ipa dnsrecord-add example.com overcloud.internalapi --a-ip-address=172.17.0.150
[root@ipa ~]# ipa dnsrecord-add example.com overcloud.storage --a-ip-address=172.18.0.150
[root@ipa ~]# ipa dnsrecord-add example.com overcloud.storagemgmt --a-ip-address=172.19.0.150
[root@ipa ~]# ipa dnsrecord-add example.com classroom --a-ip-address=10.149.23.10

[root@ipa ~]# echo 'r3dh4t1!' | ipa user-add --first=Student --last=OpenStack student --password
[root@ipa ~]# sed -ie 's|^#RewriteRule |RewriteRule |' /etc/httpd/conf.d/ipa-pki-proxy.conf
[root@ipa ~]# cat /etc/httpd/conf.d/ipa-pki-proxy.conf | grep Rewrite
[root@ipa ~]# systemctl reload httpd

# Configure Keystone LDAP Backend
(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/keystone_domain_specific_ldap_backend.yaml <<EOF
parameter_defaults:
  KeystoneLDAPDomainEnable: true
  KeystoneLDAPBackendConfigs:
    gpte:
      url: ldap://192.168.0.252
      user: uid=admin,cn=users,cn=compat,dc=example,dc=com
      password: r3dh4t1!
      suffix: dc=example,dc=com
      user_tree_dn: cn=users,cn=accounts,dc=example,dc=com
      user_filter: ""
      user_objectclass: person
      user_id_attribute: uid
      user_name_attribute: uid
      user_allow_create: false
      user_allow_update: false
      user_allow_delete: false
EOF

# Enable TLS on Internal Endpoints
(undercloud) [stack@undercloud ~]$ sudo dnf install python3-novajoin -y

(undercloud) [stack@undercloud ~]$ sudo sed -i 's/192.168.0.1/192.168.0.252/' /etc/resolv.conf

(undercloud) [stack@undercloud ~]$ 
sudo /usr/libexec/novajoin-ipa-setup \
    --principal admin \
    --password r3dh4t1\! \
    --server ipa.example.com \
    --realm EXAMPLE.COM \
    --domain example.com \
    --hostname undercloud.example.com \
    --precreate
0BaiwLSPpZBEd2APgnd1DGw4BYa4f6MwrUK5QTJlNVv6

(undercloud) [stack@undercloud ~]$ sudo yum install -y crudini

(undercloud) [stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT enable_novajoin true
(undercloud) [stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT overcloud_domain_name example.com
(undercloud) [stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT undercloud_hostname undercloud.example.com
(undercloud) [stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT undercloud_nameservers 192.168.0.252
(undercloud) [stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT ipa_otp 0BaiwLSPpZBEd2APgnd1DGw4BYa4f6MwrUK5QTJlNVv6

(undercloud) [stack@undercloud ~]$ openstack undercloud install

(undercloud) [stack@undercloud ~]$ openstack subnet show ctlplane-subnet -c dns_nameservers -f value

(undercloud) [stack@undercloud ~]$ sed -i 's/  DnsServers: \[\]/  DnsServers: ["192.168.0.252"]/' ~/templates/environments/network-environment.yaml

(undercloud) [stack@undercloud ~]$ grep DnsServers ~/templates/environments/network-environment.yaml

(undercloud) [stack@undercloud ~]$ THT=/usr/share/openstack-tripleo-heat-templates/

(undercloud) [stack@undercloud ~]$ sed 's/localdomain/example.com/' $THT/environments/predictable-placement/custom-domain.yaml | tee ~/templates/custom-domain.yaml

# Enable TLS on Overcloud Public Endpoints
(undercloud) [stack@undercloud ~]$ grep PublicVirtualFixedIPs ~/templates/ips-from-pool-all.yaml

(undercloud) [stack@undercloud ~]$ cp ~/rendered/environments/ssl/enable-tls.yaml ~/templates

(undercloud) [stack@undercloud ~]$ cp ~/rendered/environments/ssl/inject-trust-anchor.yaml ~/templates/inject-trust-anchor.yaml

(undercloud) [stack@undercloud ~]$ sed -i 's#\.\./\.\.#/usr/share/openstack-tripleo-heat-templates#' ~/templates/inject-trust-anchor.yaml

(undercloud) [stack@undercloud ~]$ grep NodeTLSCAData ~/templates/inject-trust-anchor.yaml

(undercloud) [stack@undercloud ~]$ openssl genrsa -out ~/templates/overcloud-privkey.pem 2048

(undercloud) [stack@undercloud ~]$ openssl req -new -x509 -key ~/templates/overcloud-privkey.pem -out ~/templates/overcloud-cacert.pem -days 365 -subj '/C=US/ST=NC/L=Raleigh/O=Red Hat/OU=QE/CN=overcloud.example.com'

(undercloud) [stack@undercloud ~]$ openssl x509 -in ~/templates/overcloud-cacert.pem -text -noout

(undercloud) [stack@undercloud ~]$ cat ~/templates/overcloud-cacert.pem /etc/ipa/ca.crt  > ~/cacert.pem

(undercloud) [stack@undercloud ~]$ sudo cp ~/cacert.pem /etc/pki/ca-trust/source/anchors/ca.crt.pem

(undercloud) [stack@undercloud ~]$ sudo update-ca-trust extract

(undercloud) [stack@undercloud ~]$ cd ~/templates

(undercloud) [stack@undercloud ~]$ sed -i -e '/The contents of your certificate go here/r overcloud-cacert.pem' -e '/The contents of your certificate go here/ d' enable-tls.yaml 

(undercloud) [stack@undercloud ~]$ sed -i  -e '/-----BEGIN CERT/,/-----END CERT/{s/^/    /g}' enable-tls.yaml 

(undercloud) [stack@undercloud templates]$ sed -i -e '/The contents of the private key go here/r overcloud-privkey.pem' -e '/The contents of the private key go here/ d' enable-tls.yaml

(undercloud) [stack@undercloud templates]$ sed -i -e '/-----BEGIN RSA/,/-----END RSA/{s/^/    /g}' enable-tls.yaml

(undercloud) [stack@undercloud templates]$ sed -i "s#InternalTLSCAFile: ''#InternalTLSCAFile: '/etc/pki/ca-trust/source/anchors/ca.crt.pem'#" enable-tls.yaml

(undercloud) [stack@undercloud templates]$ sed -i -e '/The contents of your certificate go here/r /home/stack/cacert.pem' -e '/The contents of your certificate go here/ d' inject-trust-anchor.yaml

(undercloud) [stack@undercloud templates]$ sed -i  -e '/-----BEGIN CERT/,/-----END CERT/{s/^/    /g}' inject-trust-anchor.yaml

(undercloud) [stack@undercloud templates]$ cat enable-tls.yaml

(undercloud) [stack@undercloud templates]$ cat inject-trust-anchor.yaml

(undercloud) [stack@undercloud templates]$ cd 
(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/ceph-config.yaml <<EOF
parameter_defaults:
  CephConfigOverrides:
    osd_pool_default_size: 2
    osd_pool_default_min_size: 1
    mon_max_pg_per_osd: 1000
  CephAnsibleDisksConfig:
    osd_scenario: collocated
    devices:
      - /dev/vdb
EOF

# Specify Node Counts and Other Options
(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/node-info.yaml <<EOF
parameter_defaults:
  OvercloudControlFlavor: baremetal
  OvercloudComputeHCIFlavor: baremetal
  ControllerCount: 3
  ComputeHCICount: 2
  BarbicanSimpleCryptoGlobalDefault: true
EOF

(undercloud) [stack@undercloud ~]$ sed -i 's/Compute/ComputeHCI/' templates/environments/net-bond-with-vlans.yaml templates/environments/network-environment.yaml templates/ips-from-pool-all.yaml

(undercloud) [stack@undercloud ~]$ openstack overcloud roles generate Controller ComputeHCI -o templates/roles_data.yaml

# add External and external_subnet to networks section
(undercloud) [stack@undercloud ~]$ 
cat ~/templates/roles_data.yaml
...
- name: ComputeHCI
  description: |
    Compute Node role hosting Ceph OSD too
  networks:
    External:
      subnet: external_subnet
    InternalApi:
      subnet: internal_api_subnet
    Tenant:
      subnet: tenant_subnet
    Storage:
      subnet: storage_subnet
    StorageMgmt:
      subnet: storage_mgmt_subnet
...

(undercloud) [stack@undercloud ~]$ THT=/usr/share/openstack-tripleo-heat-templates/

[stack@undercloud openstack-tripleo-heat-templates]$ tools/process-templates.py -r ~/templates/roles_data.yaml -n ~/templates/network_data.yaml -o ~/rendered

(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cp ~/rendered/environments/network-isolation.yaml ~/templates/environments/
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cp ~/rendered/environments/net-bond-with-vlans.yaml ~/templates/environments/
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cp ~/rendered/network/config/bond-with-vlans/computehci.yaml ~/templates/network/config/bond-with-vlans/

# Configure Node Placement
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cd 
(undercloud) [stack@undercloud ~]$ 

(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/scheduler-hints.yaml <<EOF
parameter_defaults:
  ControllerSchedulerHints:
    'capabilities:node': 'controller-%index%'
  ComputeHCISchedulerHints:
    'capabilities:node': 'compute-%index%'
EOF

(undercloud) [stack@undercloud ~]$ source ~/stackrc
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
| 0c523f61-cc33-4e99-8f06-4fa1690b97d8 | overcloud-compute03 | None          | power off   | available          | False       |
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+

(undercloud) [stack@undercloud ~]$ openstack baremetal introspection list

(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-ctrl01 --property capabilities=node:controller-0,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-ctrl02 --property capabilities=node:controller-1,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-ctrl03 --property capabilities=node:controller-2,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-compute01 --property capabilities=node:compute-0,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-compute02 --property capabilities=node:compute-1,boot_option:local

(undercloud) [stack@undercloud ~]$ 
cat > ~/deploy-with-hci.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/ips-from-pool-all.yaml \
-e $THT/environments/cinder-backup.yaml \
-e $THT/environments/ceph-ansible/ceph-rgw.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible.yaml \
-e $THT/environments/ssl/enable-internal-tls.yaml \
-e $THT/environments/ssl/tls-everywhere-endpoints-dns.yaml \
-e $THT/environments/services/barbican.yaml \
-e $THT/environments/barbican-backend-simple-crypto.yaml \
-e $THT/environments/services/octavia.yaml \
-e $CNF/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/custom-domain.yaml \
-e $CNF/node-info.yaml \
-e $CNF/HostnameMap.yaml \
-e $CNF/ips-from-pool-all.yaml \
-e $CNF/stf-connectors.yaml \
-e $CNF/fencing.yaml \
-e $CNF/enable-tls.yaml \
-e $CNF/inject-trust-anchor.yaml \
-e $CNF/keystone_domain_specific_ldap_backend.yaml \
-e $CNF/scheduler-hints.yaml \
-e $CNF/ceph-config.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml
EOF

(undercloud) [stack@undercloud ~]$ time /bin/bash -x ./deploy-with-hci.sh 
...
PLAY RECAP *********************************************************************
lab-controller01           : ok=362  changed=208  unreachable=0    failed=0    skipped=137  rescued=0    ignored=0
lab-controller02           : ok=344  changed=208  unreachable=0    failed=0    skipped=140  rescued=0    ignored=0
lab-controller03           : ok=344  changed=208  unreachable=0    failed=0    skipped=140  rescued=0    ignored=0
overcloud-computehci-0     : ok=312  changed=174  unreachable=0    failed=0    skipped=135  rescued=0    ignored=0
overcloud-computehci-1     : ok=308  changed=174  unreachable=0    failed=0    skipped=135  rescued=0    ignored=0
undercloud                 : ok=188  changed=67   unreachable=0    failed=0    skipped=210  rescued=0    ignored=0

Wednesday 23 September 2020  10:37:35 -0400 (0:00:00.066)       0:54:47.318 ***
===============================================================================

Ansible passed.
Overcloud configuration completed.
Overcloud Endpoint: https://overcloud.example.com:13000
Overcloud Horizon Dashboard URL: https://overcloud.example.com:443/dashboard
Overcloud rc file: /home/stack/overcloudrc
Overcloud Deployed
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 53242)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=5, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 49444), raddr=('192.0.2.2', 13004)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=7, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 42068), raddr=('192.0.2.2', 13989)>

real    69m36.804s
user    0m16.171s
sys     0m1.396s

# Review Overcloud Deployment
(undercloud) [stack@undercloud ~]$ source ~/overcloudrc
(overcloud) [stack@undercloud ~]$ 

(overcloud) [stack@undercloud ~]$ cat ~/overcloudrc
(overcloud) [stack@undercloud ~]$ openstack flavor create --ram 512 --vcpus 1 m1.tiny
(overcloud) [stack@undercloud ~]$ openstack image create cirros --disk-format raw --container-format bare --public --file cirros-0.4.0-x86_64-disk.raw

(overcloud) [stack@undercloud ~]$ 
openstack network create public \
  --external --provider-physical-network datacentre \
  --provider-network-type vlan --provider-segment 10

(overcloud) [stack@undercloud ~]$
openstack subnet create public-subnet \
  --no-dhcp --network public --subnet-range 10.0.0.0/24 \
  --allocation-pool start=10.0.0.100,end=10.0.0.200  \
  --gateway 10.0.0.1 --dns-nameserver 8.8.8.8

(overcloud) [stack@undercloud ~]$ openstack network agent list

(overcloud) [stack@undercloud ~]$ openstack catalog list

(overcloud) [stack@undercloud ~]$ grep OS_AUTH_URL ~/overcloudrc
export OS_AUTH_URL=https://overcloud.example.com:13000

[heat-admin@lab-controller01 ~]$ sudo podman exec -ti haproxy-bundle-podman-0 grep "ssl crt" /etc/haproxy/haproxy.cfg

[heat-admin@lab-controller01 ~]$ sudo netstat -plnt | grep ":13.."

[heat-admin@lab-controller01 ~]$ sudo file /etc/pki/tls/private/overcloud_endpoint.pem
/etc/pki/tls/private/overcloud_endpoint.pem: PEM certificate

[heat-admin@lab-controller01 ~]$ sudo openssl x509 -noout -subject -in /etc/pki/tls/private/overcloud_endpoint.pem

# Review templates used by Barbican
(undercloud) [stack@undercloud ~]$ cat /usr/share/openstack-tripleo-heat-templates/environments/services/barbican.yaml

(undercloud) [stack@undercloud ~]$ cat /usr/share/openstack-tripleo-heat-templates/environments/barbican-backend-simple-crypto.yaml

[heat-admin@lab-controller01 ~]$ sudo podman ps -f "name=barbican*"
CONTAINER ID  IMAGE                                                                                          COMMAND      CREATED       STATUS           PORTS  NAMES
68a7593e383d  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-barbican-worker:16.1-45             kolla_start  10 hours ago  Up 10 hours ago         barbican_worker
8442fd36b6b8  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-barbican-keystone-listener:16.1-45  kolla_start  10 hours ago  Up 10 hours ago         barbican_keystone_listener
d143bf9382b2  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-barbican-api:16.1-45                kolla_start  10 hours ago  Up 10 hours ago         barbican_api

(overcloud) [stack@undercloud ~]$ openstack secret store --name rootPassword --payload 'r3dh4t1!'
+---------------+-------------------------------------------------------------------------------------+
| Field         | Value                                                                               |
+---------------+-------------------------------------------------------------------------------------+
| Secret href   | https://overcloud.example.com:13311/v1/secrets/41e39909-3b18-4dfc-bc99-73aa5a5f8b08 |
| Name          | rootPassword                                                                        |
| Created       | None                                                                                |
| Status        | None                                                                                |
| Content types | None                                                                                |
| Algorithm     | aes                                                                                 |
| Bit length    | 256                                                                                 |
| Secret type   | opaque                                                                              |
| Mode          | cbc                                                                                 |
| Expiration    | None                                                                                |
+---------------+-------------------------------------------------------------------------------------+

(overcloud) [stack@undercloud ~]$ openstack secret get  $(openstack secret list -f value -c "Secret href" --name rootPassword) --payload

(overcloud) [stack@undercloud ~]$ openstack volume type create --encryption-provider nova.volume.encryptors.luks.LuksEncryptor --encryption-cipher aes-xts-plain64 --encryption-key-size 256 --encryption-control-location front-end encryptedvolume
+-------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Field       | Value                                                                                                                                                                              |
+-------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| description | None                                                                                                                                                                               |
| encryption  | cipher='aes-xts-plain64', control_location='front-end', encryption_id='12168c04-9c50-4cfe-97d0-9e465b0b9259', key_size='256', provider='nova.volume.encryptors.luks.LuksEncryptor' |
| id          | da0a1448-daba-4654-9663-6267fe3d21cc                                                                                                                                               |
| is_public   | True                                                                                                                                                                               |
| name        | encryptedvolume                                                                                                                                                                    |
+-------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

(overcloud) [stack@undercloud ~]$ openstack volume create --size 1 --type encryptedvolume volume_encrypted_example

(overcloud) [stack@undercloud ~]$ openstack secret list
+-------------------------------------------------------------------------------------+--------------+---------------------------+--------+-----------------------------------------+-----------+------------+-------------+------+------------+
| Secret href                                                                         | Name         | Created                   | Status | Content types                           | Algorithm | Bit length | Secret type | Mode | Expiration |
+-------------------------------------------------------------------------------------+--------------+---------------------------+--------+-----------------------------------------+-----------+------------+-------------+------+------------+
| https://overcloud.example.com:13311/v1/secrets/ccee9936-f129-431e-be48-e34b8d49ac6a | None         | 2020-09-24T00:41:55+00:00 | ACTIVE | {'default': 'application/octet-stream'} | aes       |        256 | symmetric   | None | None       |
| https://overcloud.example.com:13311/v1/secrets/41e39909-3b18-4dfc-bc99-73aa5a5f8b08 | rootPassword | 2020-09-24T00:39:27+00:00 | ACTIVE | {'default': 'text/plain'}               | aes       |        256 | opaque      | cbc  | None       |
+-------------------------------------------------------------------------------------+--------------+---------------------------+--------+-----------------------------------------+-----------+------------+-------------+------+------------+

(overcloud) [stack@undercloud ~]$ openstack volume list
+--------------------------------------+--------------------------+-----------+------+-------------+
| ID                                   | Name                     | Status    | Size | Attached to |
+--------------------------------------+--------------------------+-----------+------+-------------+
| 6713e7fe-12e8-44d8-a4e5-b21b41ed9752 | volume_encrypted_example | available |    1 |             |
+--------------------------------------+--------------------------+-----------+------+-------------+

(overcloud) [stack@undercloud ~]$ openstack volume show volume_encrypted_example

# IdM authentication
(overcloud) [stack@undercloud ~]$ openstack domain list
+----------------------------------+------------+---------+--------------------+
| ID                               | Name       | Enabled | Description        |
+----------------------------------+------------+---------+--------------------+
| 3322c2894a8244b49f73da89e3fcd32b | gpte       | True    |                    |
| 3e665220f0c34bcea9d4460cbb33ae26 | heat_stack | True    |                    |
| default                          | Default    | True    | The default domain |
+----------------------------------+------------+---------+--------------------+

(overcloud) [stack@undercloud ~]$ openstack user list --domain gpte
+------------------------------------------------------------------+---------+
| ID                                                               | Name    |
+------------------------------------------------------------------+---------+
| d28497c25b649ae6a89a467829af92eb50305e22031db281de0127835af53c84 | admin   |
| 0f69c4d7c3b33f2c99bfe82761812fdd20a87ec74a0bf553390e8a8ac1be9605 | student |
+------------------------------------------------------------------+---------+

(overcloud) [stack@undercloud ~]$ openstack project create project_gpte --domain gpte

(overcloud) [stack@undercloud ~]$ openstack role add --user student --project project_gpte --user-domain gpte member

(overcloud) [stack@undercloud ~]$ 
cat > overcloudrc_student << 'EOF'
# Clear any old environment that may conflict.
for key in $( set | awk '{FS="="}  /^OS_/ {print $1}' ); do unset $key ; done
export OS_NO_CACHE=True
export COMPUTE_API_VERSION=1.1
export OS_USERNAME=student
export no_proxy=,192.168.0.150,192.168.0.250,192.168.0.150,192.168.0.250,192.168.0.150,192.168.0.250
export OS_USER_DOMAIN_NAME=gpte
export OS_VOLUME_API_VERSION=3
export OS_CLOUDNAME=overcloud_student
export OS_AUTH_URL=https://overcloud.example.com:13000//v3
export NOVA_VERSION=1.1
export OS_IMAGE_API_VERSION=2
export OS_PASSWORD=r3dh4t1!
export OS_PROJECT_DOMAIN_NAME=gpte
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME=project_gpte
export OS_AUTH_TYPE=password
export PYTHONWARNINGS="ignore:Certificate has no, ignore:A true SSLContext object is not available"

# Add OS_CLOUDNAME to PS1
if [ -z "${CLOUDPROMPT_ENABLED:-}" ]; then
    export PS1=${PS1:-""}
    export PS1=\${OS_CLOUDNAME:+"(\$OS_CLOUDNAME)"}\ $PS1
    export CLOUDPROMPT_ENABLED=1
fi
EOF

(overcloud) [stack@undercloud ~]$ source overcloudrc_student 
(overcloud_student) [stack@undercloud ~]$   

(overcloud_student) [stack@undercloud ~]$ openstack network create net1

overcloud_student) [stack@undercloud ~]$ 
openstack subnet create subnet1 \
  --network net1 \
  --dns-nameserver 8.8.4.4 --gateway 172.116.1.1 \
  --subnet-range 172.116.1.0/24

(overcloud_student) [stack@undercloud ~]$ openstack security group create sg_web 

(overcloud_student) [stack@undercloud ~]$ openstack security group list                          
(overcloud_student) [stack@undercloud ~]$ SGID=$(openstack security group list | grep  sg_web | awk '{print $2}')

openstack security group rule create --proto icmp $SGID
openstack security group rule create --dst-port 22 --proto tcp $SGID
openstack security group rule create --dst-port 80 --proto tcp $SGID

cat > webserver.sh << 'EOF'
#!/bin/sh

MYIP=$(/sbin/ifconfig eth0|grep 'inet addr'|awk -F: '{print $2}'| awk '{print $1}');
OUTPUT_STR="Welcome to $MYIP\r"
OUTPUT_LEN=${#OUTPUT_STR}

while true; do
    echo -e "HTTP/1.0 200 OK\r\nContent-Length: ${OUTPUT_LEN}\r\n\r\n${OUTPUT_STR}" | sudo nc -l -p 80
done
EOF

(overcloud_student) [stack@undercloud ~]$ source ~/overcloudrc
(overcloud) [stack@undercloud ~]$ openstack flavor create m1.nano --vcpus 1 --ram 64 --disk 1
(overcloud) [stack@undercloud ~]$ source ~/overcloudrc_student 

openstack server create --image cirros --flavor m1.nano --network net1 --security-group sg_web --user-data webserver.sh web01 --wait
openstack server create --image cirros --flavor m1.nano --network net1 --security-group sg_web --user-data webserver.sh web02 --wait

(overcloud_student) [stack@undercloud ~]$ openstack loadbalancer create --name lbweb --vip-subnet-id subnet1 --provider ovn

(overcloud_student) [stack@undercloud ~]$ openstack loadbalancer list
+--------------------------------------+-------+----------------------------------+---------------+---------------------+----------+
| id                                   | name  | project_id                       | vip_address   | provisioning_status | provider |
+--------------------------------------+-------+----------------------------------+---------------+---------------------+----------+
| 55e86b30-1714-4f6c-90fd-92553a543bcb | lbweb | a98e9e44a10d40198c5e99155b864679 | 172.116.1.242 | ACTIVE              | ovn      |
+--------------------------------------+-------+----------------------------------+---------------+---------------------+----------+

(overcloud_student) [stack@undercloud ~]$ openstack loadbalancer listener create --name listenerweb --protocol TCP --protocol-port 80 lbweb

(overcloud_student) [stack@undercloud ~]$ openstack loadbalancer listener show listenerweb 

(overcloud_student) [stack@undercloud ~]$ openstack loadbalancer pool create --name poolweb --protocol TCP  --listener listenerweb --lb-algorithm SOURCE_IP_PORT

(overcloud_student) [stack@undercloud ~]$ IPWEB01=$(openstack server show web01 -c addresses -f value | cut -d"=" -f2)
(overcloud_student) [stack@undercloud ~]$ IPWEB02=$(openstack server show web02 -c addresses -f value | cut -d"=" -f2)
(overcloud_student) [stack@undercloud ~]$ SUBNETID=$(openstack subnet show subnet1 -c id -f value)

(overcloud_student) [stack@undercloud ~]$ openstack loadbalancer member create --name web01 --address $IPWEB01 --subnet-id $SUBNETID --protocol-port 80 poolweb

(overcloud_student) [stack@undercloud ~]$ openstack loadbalancer member create --name web02 --address $IPWEB02 --subnet-id $SUBNETID --protocol-port 80 poolweb

(overcloud) [stack@undercloud ~]$ openstack network set --share public 

(overcloud_student) [stack@undercloud ~]$ openstack router create router1

(overcloud_student) [stack@undercloud ~]$ openstack router add subnet router1 subnet1
(overcloud_student) [stack@undercloud ~]$ openstack router set router1 --external-gateway public

VIP=$(openstack loadbalancer show lbweb -c vip_address -f value)
PORTID=$(openstack port list --fixed-ip ip-address=$VIP -c ID -f value)
openstack floating ip create --port $PORTID public

FLOATINGID=$(openstack floating ip list | grep $VIP | awk '{print $2}')
FLOATINGIP=$(openstack floating ip show $FLOATINGID -c floating_ip_address -f value)

curl $FLOATINGIP
curl $FLOATINGIP

[heat-admin@lab-controller01 ~]$ sudo podman exec -ti ovn_controller /bin/sh
()[root@lab-controller01 /]$ ovn-nbctl set-ssl /etc/openvswitch/northdb-privkey.pem /etc/openvswitch/northdb-cert.pem /var/lib/openvswitch/pki/
()[root@lab-controller01 /]$ ovn-nbctl set-connection pssl:6641

()[root@lab-controller01 /]$ ovn-nbctl list load_balancer

[heat-admin@lab-controller01 ~]$ sudo podman exec -ti ceph-mon-lab-controller01 ceph -s 
  cluster:
    id:     b48b21da-90b0-40e1-a511-02c61b1504cd
    health: HEALTH_WARN
            too many PGs per OSD (1024 > max 1000)
 
  services:
    mon: 3 daemons, quorum lab-controller01,lab-controller02,lab-controller03 (age 12h)
    mgr: lab-controller01(active, since 12h), standbys: lab-controller02, lab-controller03
    osd: 2 osds: 2 up (since 12h), 2 in (since 12h)
    rgw: 3 daemons active (lab-controller01.rgw0, lab-controller02.rgw0, lab-controller03.rgw0)
 
  task status:
 
  data:
    pools:   8 pools, 1024 pgs
    objects: 889 objects, 3.4 GiB
    usage:   8.4 GiB used, 112 GiB / 120 GiB avail
    pgs:     1024 active+clean


[heat-admin@lab-controller01 ~]$ sudo podman exec -it openstack-cinder-backup-podman-0 cat /etc/cinder/cinder.conf | grep backup | grep -v "^#"
backup_ceph_conf=/etc/ceph/ceph.conf
backup_ceph_user=openstack
backup_ceph_chunk_size=134217728
backup_ceph_pool=backups
backup_ceph_stripe_unit=0
backup_ceph_stripe_count=0
backup_driver=cinder.backup.drivers.ceph.CephBackupDriver

(overcloud_student) [stack@undercloud ~]$ openstack volume create --size 1 1gb-vol
(overcloud_student) [stack@undercloud ~]$ openstack volume backup create 1gb-vol --force --name 1gb-vol-backup
+-------+--------------------------------------+
| Field | Value                                |
+-------+--------------------------------------+
| id    | 4e5b4f95-276d-4506-ab9c-027e7447d2e7 |
| name  | 1gb-vol-backup                       |
+-------+--------------------------------------+

(overcloud_student) [stack@undercloud ~]$ openstack volume backup show 1gb-vol-backup
+-----------------------+--------------------------------------+
| Field                 | Value                                |
+-----------------------+--------------------------------------+
| availability_zone     | nova                                 |
| container             | backups                              |
| created_at            | 2020-09-24T02:43:53.000000           |
| data_timestamp        | 2020-09-24T02:43:53.000000           |
| description           | None                                 |
| fail_reason           | None                                 |
| has_dependent_backups | False                                |
| id                    | 4e5b4f95-276d-4506-ab9c-027e7447d2e7 |
| is_incremental        | False                                |
| name                  | 1gb-vol-backup                       |
| object_count          | 0                                    |
| size                  | 1                                    |
| snapshot_id           | None                                 |
| status                | available                            |
| updated_at            | 2020-09-24T02:44:00.000000           |
| volume_id             | 7b556f01-3871-4b64-b578-22bd22bce7fe |
+-----------------------+--------------------------------------+

[heat-admin@lab-controller01 ~]$ sudo podman exec -ti ceph-mon-lab-controller01 rbd --id openstack -p backups ls
volume-7b556f01-3871-4b64-b578-22bd22bce7fe.backup.4e5b4f95-276d-4506-ab9c-027e7447d2e7

# Composable Roles Lab
(undercloud) [stack@undercloud ~]$ source ~/stackrc
(undercloud) [stack@undercloud ~]$ openstack overcloud delete overcloud --yes
(undercloud) [stack@undercloud ~]$ openstack stack list

(undercloud) [stack@undercloud ~]$ openstack stack list

(undercloud) [stack@undercloud ~]$ openstack overcloud plan list

(undercloud) [stack@undercloud ~]$ openstack overcloud role list

(undercloud) [stack@undercloud ~]$ openstack overcloud role show ComputeInstanceHA

(undercloud) [stack@undercloud ~]$ mkdir -p ~/templates-custom/templates/

(undercloud) [stack@undercloud ~]$ openstack overcloud roles generate -o ~/templates-custom/roles_data.yaml Controller ComputeInstanceHA Networker ObjectStorage

(undercloud) [stack@undercloud ~]$ cp ~/templates/network_data.yaml ~/templates-custom/

# Add parameters of a new provider network into the ~/templates-custom/network_data.yaml file
(undercloud) [stack@undercloud ~]$ 
cat >> ~/templates-custom/network_data.yaml << EOF
- name: ProviderNetwork
  vip: false
  name_lower: provider_network
  vlan: 70
  ip_subnet: '192.168.3.0/24'
  allocation_pools: [{'start': '192.168.3.4', 'end': '192.168.3.250'}]
  gateway_ip: '192.168.3.1'
EOF

(undercloud) [stack@undercloud ~]$ cp ~/templates-custom/roles_data.yaml ~/templates-custom/roles_data.yaml.orig
(undercloud) [stack@undercloud ~]$ 
cat > patch-roles-data-templates-custom << EOF
--- /home/stack/templates-custom/roles_data.yaml.orig   2020-09-24 00:48:18.831700531 -0400
+++ /home/stack/templates-custom/roles_data.yaml        2020-09-24 00:51:06.340984487 -0400
@@ -21,8 +21,6 @@
       subnet: storage_subnet
     StorageMgmt:
       subnet: storage_mgmt_subnet
-    Tenant:
-      subnet: tenant_subnet
   # For systems with both IPv4 and IPv6, you may specify a gateway network for
   # each, such as ['ControlPlane', 'External']
   default_route_networks: ['External']
@@ -181,7 +179,6 @@
     - OS::TripleO::Services::SwiftProxy
     - OS::TripleO::Services::SwiftDispersion
     - OS::TripleO::Services::SwiftRingBuilder
-    - OS::TripleO::Services::SwiftStorage
     - OS::TripleO::Services::Timesync
     - OS::TripleO::Services::Timezone
     - OS::TripleO::Services::TripleoFirewall
@@ -203,6 +200,8 @@
       subnet: tenant_subnet
     Storage:
       subnet: storage_subnet
+    ProviderNetwork:
+      subnet: provider_network_subnet
   HostnameFormatDefault: '%stackname%-novacomputeiha-%index%'
   RoleParametersDefault:
     TunedProfileName: "virtual-host"
@@ -267,6 +266,8 @@
       subnet: internal_api_subnet
     Tenant:
       subnet: tenant_subnet
+    ProviderNetwork:
+      subnet: provider_network_subnet
   tags:
     - external_bridge
   HostnameFormatDefault: '%stackname%-networker-%index%'
EOF

(undercloud) [stack@undercloud ~]$ patch ~/templates-custom/roles_data.yaml < patch-roles-data-templates-custom 

# Render TripleO Templates
(undercloud) [stack@undercloud ~]$ mkdir ~/rendered-custom
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ tools/process-templates.py -r ~/templates-custom/roles_data.yaml -n ~/templates-custom/network_data.yaml -o ~/rendered-custom
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cd ~

# Customize Network Configuration Templates for Selected Roles
(undercloud) [stack@undercloud ~]$ cp -rp ~/rendered-custom/network ~/templates-custom/
(undercloud) [stack@undercloud ~]$ mkdir -p ~/templates-custom/environments
(undercloud) [stack@undercloud ~]$ cp ~/rendered-custom/environments/net-bond-with-vlans.yaml ~/templates-custom/environments

(undercloud) [stack@undercloud ~]$ cp ~/templates-custom/network/config/bond-with-vlans/computeinstanceha.yaml ~/templates-custom/network/config/bond-with-vlans/computeinstanceha.yaml.orig

cat > patch-network-config-computeinstanceha-templates-custom << EOF
--- /home/stack/templates-custom/network/config/bond-with-vlans/computeinstanceha.yaml.orig     2020-09-24 01:01:20.684023347 -0400
+++ /home/stack/templates-custom/network/config/bond-with-vlans/computeinstanceha.yaml  2020-09-24 01:03:28.965943346 -0400
@@ -242,17 +242,15 @@
                   routes:
                     list_concat_unique:
                       - get_param: TenantInterfaceRoutes
-                - type: vlan
-                  mtu:
-                    get_param: ProviderNetworkMtu
-                  vlan_id:
-                    get_param: ProviderNetworkNetworkVlanID
-                  addresses:
-                  - ip_netmask:
-                      get_param: ProviderNetworkIpSubnet
-                  routes:
-                    list_concat_unique:
-                      - get_param: ProviderNetworkInterfaceRoutes
+              - type: ovs_bridge
+                name: br-provider
+                use_dhcp: false
+                addresses:
+                - ip_netmask:
+                    get_param: ProviderNetworkIpSubnet
+                members:
+                - type: interface
+                  name: nic4
 outputs:
   OS::stack_id:
     description: The OsNetConfigImpl resource.
EOF

(undercloud) [stack@undercloud ~]$ patch ~/templates-custom/network/config/bond-with-vlans/computeinstanceha.yaml < patch-network-config-computeinstanceha-templates-custom 

(undercloud) [stack@undercloud ~]$ cp ~/templates-custom/network/config/bond-with-vlans/networker.yaml ~/templates-custom/network/config/bond-with-vlans/networker.yaml.orig

(undercloud) [stack@undercloud ~]$ 
cat > patch-network-networker-templates-custom << EOF
--- /home/stack/templates-custom/network/config/bond-with-vlans/networker.yaml.orig     2020-09-24 01:05:59.594501008 -0400
+++ /home/stack/templates-custom/network/config/bond-with-vlans/networker.yaml  2020-09-24 01:06:37.073893305 -0400
@@ -208,17 +208,15 @@
                   routes:
                     list_concat_unique:
                       - get_param: TenantInterfaceRoutes
-                - type: vlan
-                  mtu:
-                    get_param: ProviderNetworkMtu
-                  vlan_id:
-                    get_param: ProviderNetworkNetworkVlanID
-                  addresses:
-                  - ip_netmask:
-                      get_param: ProviderNetworkIpSubnet
-                  routes:
-                    list_concat_unique:
-                      - get_param: ProviderNetworkInterfaceRoutes
+              - type: ovs_bridge
+                name: br-provider
+                use_dhcp: false
+                addresses:
+                - ip_netmask:
+                    get_param: ProviderNetworkIpSubnet
+                members:
+                - type: interface
+                  name: nic4
 outputs:
   OS::stack_id:
     description: The OsNetConfigImpl resource.
EOF

(undercloud) [stack@undercloud ~]$ patch ~/templates-custom/network/config/bond-with-vlans/networker.yaml < patch-network-networker-templates-custom 

(undercloud) [stack@undercloud ~]$ cp ~/rendered-custom/environments/network-environment.yaml ~/templates-custom/environments/

(undercloud) [stack@undercloud ~]$ cp ~/templates-custom/environments/network-environment.yaml ~/templates-custom/environments/network-environment.yaml.orig

(undercloud) [stack@undercloud ~]$ 
cat > patch-network-environment-templates-custom << EOF
--- /home/stack/templates-custom/environments/network-environment.yaml.orig     2020-09-24 01:10:47.331835549 -0400
+++ /home/stack/templates-custom/environments/network-environment.yaml  2020-09-24 01:14:17.825422297 -0400
@@ -106,6 +106,9 @@
   NeutronNetworkType: 'geneve,vlan'
   # Neutron VLAN ranges per network, for example 'datacentre:1:499,tenant:500:1000':
   NeutronNetworkVLANRanges: 'datacentre:1:1000'
+  NeutronBridgeMappings: datacentre:br-ex,provider:br-provider
+  NeutronFlatNetworks: datacentre,provider
+  NeutronEnableDVR: false
   # Customize bonding options, e.g. "mode=4 lacp_rate=1 updelay=1000 miimon=100"
   # for Linux bonds w/LACP, or "bond_mode=active-backup" for OVS active/backup.
-  BondInterfaceOvsOptions: "bond_mode=active-backup"
\ No newline at end of file
+  BondInterfaceOvsOptions: "bond_mode=active-backup"
EOF

(undercloud) [stack@undercloud ~]$ patch ~/templates-custom/environments/network-environment.yaml < patch-network-environment-templates-custom 

(undercloud) [stack@undercloud ~]$ 
cat > ~/templates-custom/node-info.yaml << EOF
parameter_defaults:
  NetworkDeploymentActions: ['CREATE','UPDATE']

  ControllerCount: 1
  OvercloudControllerFlavor: control

  ComputeInstanceHACount: 2
  OvercloudComputeInstanceHAFlavor: compute-instance-ha

  ObjectStorageCount: 1
  OvercloudObjectStorageFlavor: swift-storage

  NetworkerCount: 1
  OvercloudNetworkerFlavor: networker

  # additional settings

  NovaReservedHostMemory: 1024
  podmanPuppetProcessCount: 1

  SwiftRawDisks: {"vdb": {}}

  # No shared storage for InstanceHA
  ExtraConfig:
    tripleo::instanceha::no_shared_storage: true
EOF

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

(undercloud) [stack@undercloud ~]$ openstack flavor create --id auto --ram 4096 --disk 40 --vcpus 1 networker
(undercloud) [stack@undercloud ~]$ openstack flavor set --property "cpu_arch"="x86_64" --property "capabilities:boot_option"="local" --property "capabilities:profile"="networker" networker
(undercloud) [stack@undercloud ~]$ openstack flavor set --property resources:VCPU=0 --property resources:MEMORY_MB=0 --property resources:DISK_GB=0 --property resources:CUSTOM_BAREMETAL=1 networker

(undercloud) [stack@undercloud ~]$ openstack flavor create --id auto --ram 4096 --disk 40 --vcpus 1 compute-instance-ha
(undercloud) [stack@undercloud ~]$ openstack flavor set --property "cpu_arch"="x86_64" --property "capabilities:boot_option"="local" --property "capabilities:profile"="compute-instance-ha" compute-instance-ha
(undercloud) [stack@undercloud ~]$ openstack flavor set --property resources:VCPU=0 --property resources:MEMORY_MB=0 --property resources:DISK_GB=0 --property resources:CUSTOM_BAREMETAL=1 compute-instance-ha

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
| 0c523f61-cc33-4e99-8f06-4fa1690b97d8 | overcloud-compute03 | available       | compute         |                   |
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+

(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-ctrl01 --property capabilities=profile:control,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-compute01 --property capabilities=profile:compute-instance-ha,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-compute02 --property capabilities=profile:compute-instance-ha,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-stor01 --property capabilities=profile:swift-storage,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-networker --property capabilities=profile:networker,boot_option:local

(undercloud) [stack@undercloud ~]$ openstack baremetal node unset overcloud-compute03 --property capabilities

(undercloud) [stack@undercloud ~]$ openstack overcloud profiles list
+--------------------------------------+---------------------+-----------------+---------------------+-------------------+
| Node UUID                            | Node Name           | Provision State | Current Profile     | Possible Profiles |
+--------------------------------------+---------------------+-----------------+---------------------+-------------------+
| ad3e3612-fa87-499b-bda4-f29f5d99952f | overcloud-compute01 | available       | compute-instance-ha |                   |
| 87f78af7-20af-41d0-860b-e206cac5ea87 | overcloud-compute02 | available       | compute-instance-ha |                   |
| 629e932c-e32c-438e-a3c8-403eac0e363d | overcloud-ctrl01    | available       | control             |                   |
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | overcloud-ctrl02    | available       | None                |                   |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | overcloud-ctrl03    | available       | None                |                   |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | overcloud-networker | available       | networker           |                   |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | overcloud-stor01    | available       | swift-storage       |                   |
| 0c523f61-cc33-4e99-8f06-4fa1690b97d8 | overcloud-compute03 | available       | None                |                   |
+--------------------------------------+---------------------+-----------------+---------------------+-------------------+

(undercloud) [stack@undercloud ~]$ openstack overcloud generate fencing --ipmi-lanplus --ipmi-level administrator --output ~/templates-custom/fencing.yaml ~/nodes.json

(undercloud) [stack@undercloud ~]$ 
cat > ~/deploy-custom.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates-custom/

source ~/stackrc
openstack overcloud deploy --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/network-isolation.yaml \
-e $THT/environments/disable-telemetry.yaml \
-e $THT/environments/compute-instanceha.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/node-info.yaml \
-e $CNF/fencing.yaml
EOF

(undercloud) [stack@undercloud ~]$ time /bin/bash -x ~/deploy-custom.sh 
...
PLAY RECAP *********************************************************************
overcloud-controller-0     : ok=341  changed=202  unreachable=0    failed=0    skipped=127  rescued=0    ignored=0
overcloud-networker-0      : ok=264  changed=145  unreachable=0    failed=0    skipped=114  rescued=0    ignored=0
overcloud-novacomputeiha-0 : ok=303  changed=175  unreachable=0    failed=0    skipped=123  rescued=0    ignored=0
overcloud-novacomputeiha-1 : ok=299  changed=175  unreachable=0    failed=0    skipped=123  rescued=0    ignored=0
overcloud-objectstorage-0  : ok=273  changed=151  unreachable=0    failed=0    skipped=113  rescued=0    ignored=0
undercloud                 : ok=87   changed=39   unreachable=0    failed=0    skipped=57   rescued=0    ignored=0

Thursday 24 September 2020  02:16:33 -0400 (0:00:00.061)       0:33:12.522 ****
===============================================================================
Waiting for messages on queue 'tripleo' with no timeout.
Host 10.0.0.246 not found in /home/stack/.ssh/known_hosts

Ansible passed.
Overcloud configuration completed.
Overcloud Endpoint: http://10.0.0.246:5000
Overcloud Horizon Dashboard URL: http://10.0.0.246:80/dashboard
Overcloud rc file: /home/stack/overcloudrc
Overcloud Deployed
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 49416)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=5, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 47250), raddr=('192.0.2.2', 13004)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=7, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 39924), raddr=('192.0.2.2', 13989)>

real    46m29.188s
user    0m9.811s
sys     0m1.324s

(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+----------------------------+--------+---------------------+----------------+---------------------+
| ID                                   | Name                       | Status | Networks            | Image          | Flavor              |
+--------------------------------------+----------------------------+--------+---------------------+----------------+---------------------+
| 0aceed1e-fb31-4b13-be2e-c7a2f8b2efdb | overcloud-controller-0     | ACTIVE | ctlplane=192.0.2.21 | overcloud-full | control             |
| 872fb535-3880-42c4-8725-eff214a17b18 | overcloud-novacomputeiha-0 | ACTIVE | ctlplane=192.0.2.18 | overcloud-full | compute-instance-ha |
| 911f79bd-7e7e-4a9e-bb43-864ce306fab2 | overcloud-novacomputeiha-1 | ACTIVE | ctlplane=192.0.2.11 | overcloud-full | compute-instance-ha |
| 256094d3-f141-45bd-be6a-edb41fb72f00 | overcloud-objectstorage-0  | ACTIVE | ctlplane=192.0.2.9  | overcloud-full | swift-storage       |
| ddf360d5-b250-4845-8b9e-d0d0d9e048c0 | overcloud-networker-0      | ACTIVE | ctlplane=192.0.2.13 | overcloud-full | networker           |
+--------------------------------------+----------------------------+--------+---------------------+----------------+---------------------+

(undercloud) [stack@undercloud ~]$ openstack baremetal node list
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+
| UUID                                 | Name                | Instance UUID                        | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+
| ad3e3612-fa87-499b-bda4-f29f5d99952f | overcloud-compute01 | 911f79bd-7e7e-4a9e-bb43-864ce306fab2 | power on    | active             | False       |
| 87f78af7-20af-41d0-860b-e206cac5ea87 | overcloud-compute02 | 872fb535-3880-42c4-8725-eff214a17b18 | power on    | active             | False       |
| 629e932c-e32c-438e-a3c8-403eac0e363d | overcloud-ctrl01    | 0aceed1e-fb31-4b13-be2e-c7a2f8b2efdb | power on    | active             | False       |
| a7aeee1d-af3a-4b18-86b6-24e8c4ba1ed4 | overcloud-ctrl02    | None                                 | power off   | available          | False       |
| 436da99c-88a9-42f9-ba17-1e38ac3e4a89 | overcloud-ctrl03    | None                                 | power off   | available          | False       |
| fdebcc21-49e6-4a6d-bb28-eca45a3985c8 | overcloud-networker | ddf360d5-b250-4845-8b9e-d0d0d9e048c0 | power on    | active             | False       |
| acf56624-065a-4dd0-acb2-ecc3079c62fd | overcloud-stor01    | 256094d3-f141-45bd-be6a-edb41fb72f00 | power on    | active             | False       |
| 0c523f61-cc33-4e99-8f06-4fa1690b97d8 | overcloud-compute03 | None                                 | power off   | available          | False       |
+--------------------------------------+---------------------+--------------------------------------+-------------+--------------------+-------------+

(overcloud) [stack@undercloud ~]$ source ~/overcloudrc
(overcloud) [stack@undercloud ~]$ openstack network create --provider-network-type flat --provider-physical-network provider provnetwork

(overcloud) [stack@undercloud ~]$ openstack subnet create  --gateway 192.168.3.1  --allocation-pool start=192.168.3.151,end=192.168.3.200  --network provnetwork --subnet-range 192.168.3.0/24 provsubnet

(overcloud) [stack@undercloud ~]$ openstack keypair create --public-key ~/.ssh/id_rsa.pub stack

(overcloud) [stack@undercloud ~]$ openstack flavor create m1.tiny --vcpus 1 --ram 64 --disk 1

(overcloud) [stack@undercloud ~]$ sg_id=$(openstack security group list --project admin -c ID -f value)
(overcloud) [stack@undercloud ~]$ openstack security group rule create --proto icmp $sg_id
(overcloud) [stack@undercloud ~]$ openstack security group rule create --dst-port 22 --proto tcp $sg_id

(overcloud) [stack@undercloud ~]$ openstack image create cirros --public --file cirros-0.4.0-x86_64-disk.raw
(overcloud) [stack@undercloud ~]$ openstack server create --flavor m1.tiny --image cirros --key-name stack --security-group $sg_id --nic net-id=provnetwork vmprov --config-drive true

(overcloud) [stack@undercloud ~]$ openstack server list

(overcloud) [stack@undercloud ~]$ provnetip=$( openstack server show vmprov -c addresses -f value | awk -F'='  '{print $2}' )

(overcloud) [stack@undercloud ~]$ ssh cirros@${provnetip}

(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+----------------------------+--------+---------------------+----------------+---------------------+
| ID                                   | Name                       | Status | Networks            | Image          | Flavor              |
+--------------------------------------+----------------------------+--------+---------------------+----------------+---------------------+
| 0aceed1e-fb31-4b13-be2e-c7a2f8b2efdb | overcloud-controller-0     | ACTIVE | ctlplane=192.0.2.21 | overcloud-full | control             |
| 872fb535-3880-42c4-8725-eff214a17b18 | overcloud-novacomputeiha-0 | ACTIVE | ctlplane=192.0.2.18 | overcloud-full | compute-instance-ha |
| 911f79bd-7e7e-4a9e-bb43-864ce306fab2 | overcloud-novacomputeiha-1 | ACTIVE | ctlplane=192.0.2.11 | overcloud-full | compute-instance-ha |
| 256094d3-f141-45bd-be6a-edb41fb72f00 | overcloud-objectstorage-0  | ACTIVE | ctlplane=192.0.2.9  | overcloud-full | swift-storage       |
| ddf360d5-b250-4845-8b9e-d0d0d9e048c0 | overcloud-networker-0      | ACTIVE | ctlplane=192.0.2.13 | overcloud-full | networker           |
+--------------------------------------+----------------------------+--------+---------------------+----------------+---------------------+

(undercloud) [stack@undercloud ~]$ 
cat > ~/.ssh/config << EOF
Host *
  StrictHostKeyChecking no
EOF

(undercloud) [stack@undercloud ~]$ 
chmod 400 ~/.ssh/config

[heat-admin@overcloud-objectstorage-0 ~]$ df /dev/vdb
Filesystem     1K-blocks   Used Available Use% Mounted on
/dev/vdb        62883840 485548  62398292   1% /srv/node/vdb

[heat-admin@overcloud-objectstorage-0 ~]$ sudo podman exec -ti  swift_object_server swift-ring-builder /etc/swift/object.builder
/etc/swift/object.builder, build version 2, id f0295f682ad545b28baf2ce69743b76c
1024 partitions, 1.000000 replicas, 1 regions, 1 zones, 1 devices, 0.00 balance, 0.00 dispersion
The minimum number of hours before a partition can be reassigned is 1 (0:11:11 remaining)
The overload factor is 0.00% (0.000000)
Ring file /etc/swift/object.ring.gz is up-to-date
Devices:   id region zone   ip address:port replication ip:port  name weight partitions balance flags meta
            0      1    1 172.19.0.137:6000   172.19.0.137:6000   vdb 100.00       1024    0.00     

[heat-admin@overcloud-objectstorage-0 ~]$ ip a s | grep 172.19
    inet 172.19.0.137/24 brd 172.19.0.255 scope global vlan40    

# Testing Evacuation with Instance HA
(overcloud) [stack@undercloud ~]$ openstack server list --long
+--------------------------------------+--------+--------+------------+-------------+---------------------------+------------+--------------------------------------+-------------+-----------+-------------------+----------------------------------------+------------+
| ID                                   | Name   | Status | Task State | Power State | Networks                  | Image Name | Image ID                             | Flavor Name | Flavor ID | Availability Zone | Host                                   | Properties |
+--------------------------------------+--------+--------+------------+-------------+---------------------------+------------+--------------------------------------+-------------+-----------+-------------------+----------------------------------------+------------+
| 55bd143b-1a70-42f4-a368-95c9138a33e1 | vmprov | ACTIVE | None       | Running     | provnetwork=192.168.3.184 | cirros     | 278b273d-3b2e-454a-87cc-60f3ed74a1e0 |             |           | nova              | overcloud-novacomputeiha-0.localdomain |            |
+--------------------------------------+--------+--------+------------+-------------+---------------------------+------------+--------------------------------------+-------------+-----------+-------------------+----------------------------------------+------------+

[heat-admin@overcloud-novacomputeiha-0 ~]$ sudo -i
[root@overcloud-novacomputeiha-0 ~]# echo c > /proc/sysrq-trigger

(overcloud) [stack@undercloud ~]$ openstack server list --long
+--------------------------------------+--------+--------+------------+-------------+---------------------------+------------+--------------------------------------+-------------+-----------+-------------------+----------------------------------------+------------+
| ID                                   | Name   | Status | Task State | Power State | Networks                  | Image Name | Image ID                             | Flavor Name | Flavor ID | Availability Zone | Host                                   | Properties |
+--------------------------------------+--------+--------+------------+-------------+---------------------------+------------+--------------------------------------+-------------+-----------+-------------------+----------------------------------------+------------+
| 55bd143b-1a70-42f4-a368-95c9138a33e1 | vmprov | ACTIVE | None       | Running     | provnetwork=192.168.3.184 | cirros     | 278b273d-3b2e-454a-87cc-60f3ed74a1e0 |             |           | nova              | overcloud-novacomputeiha-1.localdomain |            |
+--------------------------------------+--------+--------+------------+-------------+---------------------------+------------+--------------------------------------+-------------+-----------+-------------------+----------------------------------------+------------+

[heat-admin@overcloud-novacomputeiha-0 ~]$ w
 06:54:23 up 1 min,  1 user,  load average: 1.97, 0.74, 0.26
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
heat-adm pts/0    192.0.2.1        06:54    2.00s  0.01s  0.01s w


### day 4
# Deploy All in One Openstack
[root@pool08-iad ~]# /bin/sh -x /root/setup-env-allinone.sh 
...
+ virsh start allinone
Domain allinone started

[root@pool08-iad ~]# ssh-copy-id root@192.168.122.253
[root@pool08-iad ~]# ssh root@192.168.122.253

[root@allinone ~]# useradd stack
[root@allinone ~]# passwd stack
[root@allinone ~]# echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
[root@allinone ~]# logout
[root@pool08-iad ~]# ssh-copy-id stack@192.168.122.253
[root@pool08-iad ~]# ssh stack@192.168.122.253

[stack@allinone ~]$ sudo dnf install -y python3-tripleoclient
[stack@allinone ~]$ openstack tripleo container image prepare default   --local-push-destination   --output-env-file containers-prepare-parameter.yaml
[stack@allinone ~]$ sudo curl -o /etc/pki/ca-trust/source/anchors/classroom-ca.pem http://classroom.example.com/ca.crt
[stack@allinone ~]$ sudo update-ca-trust extract
[stack@allinone ~]$ sed -i "s/registry.redhat.io/classroom.example.com:5000/" containers-prepare-parameter.yaml

[stack@allinone ~]$ 
cat <<EOF > $HOME/standalone_parameters.yaml
parameter_defaults:
  CloudName: 192.0.2.253
  ControlPlaneStaticRoutes: []
  Debug: true
  DeploymentUser: $USER
  DnsServers:
    - 192.0.2.254
  DockerInsecureRegistryAddress:
    - allinone.ctlplane.localdomain:8787
    - localhost:8787
  NeutronPublicInterface: eth1
  NeutronDnsDomain: localdomain
  NeutronBridgeMappings: datacentre:br-ctlplane
  NeutronPhysicalBridge: br-ctlplane
  StandaloneEnableRoutedNetworks: false
  StandaloneHomeDir: $HOME
  StandaloneLocalMtu: 1500
EOF

# https://medium.com/@achchusnulchikam2/how-to-install-all-in-one-red-hat-openstack-platform-16-proof-of-concept-rhosp-e917b5b58e4b

[stack@allinone ~]$ sudo dnf update -y
[stack@allinone ~]$ sudo reboot

[stack@allinone ~]$ 
sudo openstack tripleo deploy \
  --templates \
  --local-ip=192.0.2.253/24 \
  -e /usr/share/openstack-tripleo-heat-templates/environments/standalone/standalone-tripleo.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovs.yaml \
  -r /usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml \
  -e $HOME/containers-prepare-parameter.yaml \
  -e $HOME/standalone_parameters.yaml \
  --output-dir $HOME \
  --standalone

...
########################################################

Deployment successful!

########################################################

##########################################################

Useful files:

The clouds.yaml file is at ~/.config/openstack/clouds.yaml

Use "export OS_CLOUD=standalone" before running the
openstack command.

##########################################################

Writing the stack virtual update mark file /var/lib/tripleo-heat-installer/update_mark_standalone

[stack@allinone ~]$ export OS_CLOUD=standalone
[stack@allinone ~]$ export GATEWAY=192.0.2.254
[stack@allinone ~]$ export PUBLIC_NETWORK_CIDR=192.0.2.0/24
[stack@allinone ~]$ export PRIVATE_NETWORK_CIDR=192.168.100.0/24
[stack@allinone ~]$ export PUBLIC_NET_START=192.0.2.50
[stack@allinone ~]$ export PUBLIC_NET_END=192.0.2.60
[stack@allinone ~]$ export DNS_SERVER=1.1.1.1

[stack@allinone ~]$ openstack flavor create --ram 512 --disk 1 --vcpu 1 --public tiny
[stack@allinone ~]$ curl -O -L https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
[stack@allinone ~]$ openstack image create cirros --container-format bare --disk-format qcow2 --public --file cirros-0.4.0-x86_64-disk.img

[stack@allinone ~]$ ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''
[stack@allinone ~]$ openstack keypair create --public-key ~/.ssh/id_rsa.pub default

[stack@allinone ~]$ openstack security group create basic
[stack@allinone ~]$ openstack security group rule create basic --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0
[stack@allinone ~]$ openstack security group rule create --protocol icmp basic
[stack@allinone ~]$ openstack security group rule create --protocol udp --dst-port 53:53 basic

[stack@allinone ~]$ openstack network create --external --provider-physical-network datacentre --provider-network-type flat public

[stack@allinone ~]$ openstack network create --internal private

[stack@allinone ~]$ openstack subnet create public-net \
    --subnet-range $PUBLIC_NETWORK_CIDR \
    --no-dhcp \
    --gateway $GATEWAY \
    --allocation-pool start=$PUBLIC_NET_START,end=$PUBLIC_NET_END \
    --network public

[stack@allinone ~]$ openstack subnet create private-net \
    --subnet-range $PRIVATE_NETWORK_CIDR \
    --network private

[stack@allinone ~]$ openstack router create vrouter
[stack@allinone ~]$ openstack router set vrouter --external-gateway public
[stack@allinone ~]$ openstack router add subnet vrouter private-net

[stack@allinone ~]$ openstack floating ip create public

[stack@allinone ~]$ sudo setenforce 0

[stack@allinone ~]$ openstack server create --flavor tiny --image cirros --key-name default --network private --security-group basic myserver

[stack@allinone ~]$ FIP=$(openstack floating ip list -c "Floating IP Address" -f value)

[stack@allinone ~]$ openstack server add floating ip myserver $FIP

[stack@allinone ~]$ ssh cirros@$FIP

# Deploy OpenStack on Pre-Installed Servers

[root@pool08-iad ~]# /bin/sh -x ~/setup-env-osp16-predeployed.sh

[root@pool08-iad ~]# virsh destroy allinone

[root@pool08-iad ~]# virsh destroy crc

# Configure the VMs
[stack@undercloud ~]$ ssh-copy-id root@192.0.2.81
[stack@undercloud ~]$ ssh-copy-id root@192.0.2.91

[stack@undercloud ~]$ ssh root@192.0.2.81 sudo yum -y install python3-heat-agent*
[stack@undercloud ~]$ ssh root@192.0.2.91 sudo yum -y install python3-heat-agent*

[root@overcloud2-ctrl01 ~]# useradd stack
[root@overcloud2-ctrl01 ~]# passwd stack
Changing password for user stack.
New password: 
Retype new password: 
passwd: all authentication tokens updated successfully.
[root@overcloud2-ctrl01 ~]# echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
stack ALL=(root) NOPASSWD:ALL
[root@overcloud2-ctrl01 ~]# chmod 0440 /etc/sudoers.d/stack

[root@overcloud2-compute01 ~]# useradd stack
[root@overcloud2-compute01 ~]# passwd stack
Changing password for user stack.
New password: 
Retype new password: 
passwd: all authentication tokens updated successfully.
[root@overcloud2-compute01 ~]# echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
stack ALL=(root) NOPASSWD:ALL
[root@overcloud2-compute01 ~]# chmod 0440 /etc/sudoers.d/stack

[stack@undercloud ~]$ ssh-copy-id stack@192.0.2.81
[stack@undercloud ~]$ ssh-copy-id stack@192.0.2.91

[stack@undercloud ~]$ source ~/stackrc 
(undercloud) [stack@undercloud ~]$ mkdir -p ~/templates_pre/environments/
(undercloud) [stack@undercloud ~]$ cd templates_pre/

(undercloud) [stack@undercloud templates_pre]$ 
cat >ctlplane.yaml <<EOF
resource_registry:
  OS::TripleO::DeployedServer::ControlPlanePort: /usr/share/openstack-tripleo-heat-templates/deployed-server/deployed-neutron-port.yaml

parameter_defaults:
  DeployedServerPortMap:
    overcloud2-ctrl01-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.81
      subnets:
        - cidr: 192.0.2.0/24

    overcloud2-compute01-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.91
      subnets:
        - cidr: 192.0.2.0/24
EOF

(undercloud) [stack@undercloud templates_pre]$ 
cat >~/templates_pre/environments/net-bond-with-vlans.yaml <<EOF
# This template configures each role to use a pair of bonded nics (nic2 and
# nic3) and configures an IP address on each relevant isolated network
# for each role. This template assumes use of network-isolation.yaml.
#
# FIXME: if/when we add functionality to heatclient to include heat
# environment files we should think about using it here to automatically
# include network-isolation.yaml.
#
# There is no longer a requirement to use net-bond-with-vlans-v6.yaml for
# nodes when deploying with IPv6. You may now define both an IPv4 network
# and an IPv6 network as default routes by adding both networks to the
# default_route_networks list for the Controller role in roles_data.yaml.
# Then include this environment file to use bond-with-vlans NIC configs.

resource_registry:
  # Network configuration assignments for the Controller
  OS::TripleO::Controller::Net::SoftwareConfig: ../network/config/bond-with-vlans/controller.yaml
  # Network configuration assignments for the ComputeHCI
  OS::TripleO::Compute::Net::SoftwareConfig: ../network/config/bond-with-vlans/compute.yaml
EOF

(undercloud) [stack@undercloud templates_pre]$ 
cat > ~/templates_pre/hostname-map.yaml << EOF
parameter_defaults:
  HostnameMap:
    overcloud-pre-controller-0: overcloud2-ctrl01
    overcloud-pre-novacompute-0: overcloud2-compute01
EOF

(undercloud) [stack@undercloud templates_pre]$ cp -ar ~/templates/network ~/templates_pre/
(undercloud) [stack@undercloud templates_pre]$ cp /usr/share/openstack-tripleo-heat-templates/deployed-server/deployed-server-roles-data.yaml .
(undercloud) [stack@undercloud templates_pre]$ cp ~/templates/network_data.yaml  .
(undercloud) [stack@undercloud templates_pre]$ cp ~/templates/environments/network-environment.yaml  environments/

(undercloud) [stack@undercloud templates_pre]$ sed -i -E 's/name_lower: (.*)/name_lower: \1_1/' network_data.yaml
(undercloud) [stack@undercloud templates_pre]$ sed -i -E 's!172.1(.).0!172.1\1.1!g' network_data.yaml
(undercloud) [stack@undercloud templates_pre]$ sed -i -E 's!172.1(.).0!172.1\1.1!g' environments/network-environment.yaml
(undercloud) [stack@undercloud templates_pre]$ sed -i 's/_subnet/_1_subnet/' deployed-server-roles-data.yaml

(undercloud) [stack@undercloud templates_pre]$ cp ~/templates_pre/environments/network-environment.yaml ~/templates_pre/environments/network-environment.yaml.orig

(undercloud) [stack@undercloud templates_pre]$ 
cat > ~/patch-network-environment-predeploy << EOF
--- /home/stack/templates_pre/environments/network-environment.yaml.orig        2020-09-24 05:17:05.147290317 -0400
+++ /home/stack/templates_pre/environments/network-environment.yaml     2020-09-24 05:18:00.555390134 -0400
@@ -91,6 +91,10 @@
   ManagementNetworkVlanID: 60
 
 
+  NetworkDeploymentActions: ['CREATE','UPDATE']
+  ControlPlaneDefaultRoute: 192.0.2.254
+
+
   # Define the DNS servers (maximum 2) for the overcloud nodes
   # When the list is not set or empty, the nameservers on the ctlplane subnets will be used.
   # (ctlplane subnets nameservers are controlled by the ``undercloud_nameservers`` option in ``undercloud.conf``)
@@ -101,4 +105,4 @@
   NeutronNetworkVLANRanges: 'datacentre:1:1000'
   # Customize bonding options, e.g. "mode=4 lacp_rate=1 updelay=1000 miimon=100"
   # for Linux bonds w/LACP, or "bond_mode=active-backup" for OVS active/backup.
-  BondInterfaceOvsOptions: "bond_mode=active-backup"
\ No newline at end of file
+  BondInterfaceOvsOptions: "bond_mode=active-backup"
EOF

(undercloud) [stack@undercloud templates_pre]$ patch ~/templates_pre/environments/network-environment.yaml < ~/patch-network-environment-predeploy 

(undercloud) [stack@undercloud templates_pre]$ cd ~
(undercloud) [stack@undercloud ~]$ 
cat > ~/deploy-pre.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates_pre/

source ~/stackrc
openstack overcloud deploy --stack overcloud-pre --templates $THT \
-r $CNF/deployed-server-roles-data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/deployed-server-environment.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/ctlplane.yaml \
-e $CNF/hostname-map.yaml \
--overcloud-ssh-user stack \
--overcloud-ssh-key ~/.ssh/id_rsa \
--disable-validations
EOF

[stack@undercloud ~]$ source ~/stackrc
(undercloud) [stack@undercloud ~]$ /bin/bash -x ~/deploy-pre.sh
...
PLAY RECAP *********************************************************************
overcloud2-compute01       : ok=298  changed=170  unreachable=0    failed=0    skipped=134  rescued=0    ignored=0   
overcloud2-ctrl01          : ok=351  changed=208  unreachable=0    failed=0    skipped=138  rescued=0    ignored=0   
undercloud                 : ok=87   changed=39   unreachable=0    failed=0    skipped=57   rescued=0    ignored=0   

Thursday 24 September 2020  06:05:19 -0400 (0:00:00.061)       0:32:05.365 **** 
=============================================================================== 
Waiting for messages on queue 'tripleo' with no timeout.
Host 192.0.2.22 not found in /home/stack/.ssh/known_hosts

Ansible passed.
Overcloud configuration completed.
Overcloud Endpoint: http://192.0.2.22:5000
Overcloud Horizon Dashboard URL: http://192.0.2.22:80/dashboard
Overcloud rc file: /home/stack/overcloud-prerc
Overcloud Deployed
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=4, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 49218)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=5, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 33172), raddr=('192.0.2.2', 13004)>
sys:1: ResourceWarning: unclosed <ssl.SSLSocket fd=7, family=AddressFamily.AF_INET, type=SocketKind.SOCK_STREAM, proto=6, laddr=('192.0.2.2', 54076), raddr=('192.0.2.2', 13989)>

real    40m49.881s
user    0m7.576s
sys     0m1.110s

(undercloud) [stack@undercloud ~]$ openstack overcloud plan list
+---------------+
| Plan Name     |
+---------------+
| overcloud-pre |
| overcloud     |
+---------------+

(undercloud) [stack@undercloud ~]$ openstack network list
+--------------------------------------+------------------+--------------------------------------+
| ID                                   | Name             | Subnets                              |
+--------------------------------------+------------------+--------------------------------------+
| 25af4239-a0d2-4935-8183-f4040bab8190 | storage          | 0823930f-3b51-40ce-b1dc-33d5784cf8c9 |
| 332d16e2-35e0-4405-b0ea-16bbb1c60407 | external         | f0ce0f32-f4f2-441c-9222-bde2525e9f6e |
| 3671e11d-3ed1-4248-a3a9-99eb95bce0b1 | management       | 882e6251-df70-4d2d-a48f-17fd9a04e1fb |
| 524bf9e2-5270-4a19-83ba-480fc2b0b6cf | internal_api     | 06a648a4-19fa-4089-9e13-8b715a7d7dc9 |
| 666da9e5-1cbe-4c3c-9263-5c45c03c4233 | tenant           | 77aae352-598b-42d8-ad20-0ffa94e4d291 |
| 8f62fe95-4ddf-4d9f-af89-cf251302d282 | provider_network | c13b8bff-8074-4b4a-8618-95bf83dab6d0 |
| 9089c502-4e84-4637-9482-6963a165585e | storage_mgmt     | 478cc501-0d71-48de-9c5f-aacf12220869 |
| a09c8328-66e1-424a-810b-4b5593e47444 | ctlplane         | 437f7ef9-54e2-461f-a8c2-73132e5c3139 |
+--------------------------------------+------------------+--------------------------------------+

(undercloud) [stack@undercloud ~]$ openstack subnet list
+--------------------------------------+-------------------------+--------------------------------------+----------------+
| ID                                   | Name                    | Network                              | Subnet         |
+--------------------------------------+-------------------------+--------------------------------------+----------------+
| 06a648a4-19fa-4089-9e13-8b715a7d7dc9 | internal_api_subnet     | 524bf9e2-5270-4a19-83ba-480fc2b0b6cf | 172.17.0.0/24  |
| 0823930f-3b51-40ce-b1dc-33d5784cf8c9 | storage_subnet          | 25af4239-a0d2-4935-8183-f4040bab8190 | 172.18.0.0/24  |
| 437f7ef9-54e2-461f-a8c2-73132e5c3139 | ctlplane-subnet         | a09c8328-66e1-424a-810b-4b5593e47444 | 192.0.2.0/24   |
| 478cc501-0d71-48de-9c5f-aacf12220869 | storage_mgmt_subnet     | 9089c502-4e84-4637-9482-6963a165585e | 172.19.0.0/24  |
| 77aae352-598b-42d8-ad20-0ffa94e4d291 | tenant_subnet           | 666da9e5-1cbe-4c3c-9263-5c45c03c4233 | 172.16.0.0/24  |
| 882e6251-df70-4d2d-a48f-17fd9a04e1fb | management_subnet       | 3671e11d-3ed1-4248-a3a9-99eb95bce0b1 | 10.0.1.0/24    |
| c13b8bff-8074-4b4a-8618-95bf83dab6d0 | provider_network_subnet | 8f62fe95-4ddf-4d9f-af89-cf251302d282 | 192.168.3.0/24 |
| f0ce0f32-f4f2-441c-9222-bde2525e9f6e | external_subnet         | 332d16e2-35e0-4405-b0ea-16bbb1c60407 | 10.0.0.0/24    |
+--------------------------------------+-------------------------+--------------------------------------+----------------+

(undercloud) [stack@undercloud ~]$ source overcloud-prerc 
(overcloud-pre) [stack@undercloud ~]$ openstack network agent list
+--------------------------------------+----------------------+----------------------------------+-------------------+-------+-------+-------------------------------+
| ID                                   | Agent Type           | Host                             | Availability Zone | Alive | State | Binary                        |
+--------------------------------------+----------------------+----------------------------------+-------------------+-------+-------+-------------------------------+
| b3470bba-07e1-4ef1-8a0e-4da7354b86a4 | OVN Controller agent | overcloud2-compute01.localdomain | n/a               | :-)   | UP    | ovn-controller                |
| b252cb35-e386-4f4a-be53-cc2cc50528b5 | OVN Metadata agent   | overcloud2-compute01.localdomain | n/a               | :-)   | UP    | networking-ovn-metadata-agent |
| e42c7f0f-fa85-4a48-b193-565a4a25e0ec | OVN Controller agent | overcloud2-ctrl01.localdomain    | n/a               | :-)   | UP    | ovn-controller                |
+--------------------------------------+----------------------+----------------------------------+-------------------+-------+-------+-------------------------------+

(overcloud-pre) [stack@undercloud ~]$ openstack compute service list
+--------------------------------------+----------------+----------------------------------+----------+---------+-------+----------------------------+
| ID                                   | Binary         | Host                             | Zone     | Status  | State | Updated At                 |
+--------------------------------------+----------------+----------------------------------+----------+---------+-------+----------------------------+
| 64506979-bd23-4edc-9f16-2ada7d131c53 | nova-conductor | overcloud2-ctrl01.localdomain    | internal | enabled | up    | 2020-09-24T10:19:59.000000 |
| 0ee75580-b21b-445c-abae-8f270aa93eed | nova-scheduler | overcloud2-ctrl01.localdomain    | internal | enabled | up    | 2020-09-24T10:19:54.000000 |
| 166964ad-3d06-4671-abbb-0e6c2368386e | nova-compute   | overcloud2-compute01.localdomain | nova     | enabled | up    | 2020-09-24T10:19:53.000000 |
+--------------------------------------+----------------+----------------------------------+----------+---------+-------+----------------------------+

[root@overcloud2-ctrl01 ~]# ovs-vsctl show 
b131ceb5-bdb8-4660-b081-0d4440bf6ffe
    Bridge br-ex
        fail_mode: standalone
        Port bond1
            Interface eth1
            Interface eth2
        Port vlan40
            tag: 40
            Interface vlan40
                type: internal
        Port br-ex
            Interface br-ex
                type: internal
        Port vlan30
            tag: 30
            Interface vlan30
                type: internal
        Port vlan50
            tag: 50
            Interface vlan50
                type: internal
        Port vlan20
            tag: 20
            Interface vlan20
                type: internal
        Port vlan10
            tag: 10
            Interface vlan10
                type: internal
    Bridge br-int
        fail_mode: secure
        Port ovn-b3470b-0
            Interface ovn-b3470b-0
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.0.2.91"}
        Port br-int
            Interface br-int
                type: internal
    ovs_version: "2.13.0"

(overcloud-pre) [stack@undercloud ~]$ 
openstack network create public \
  --external --provider-physical-network datacentre \
  --provider-network-type vlan --provider-segment 10

(overcloud-pre) [stack@undercloud ~]$ 
openstack subnet create public-subnet \
  --no-dhcp --network public --subnet-range 10.0.0.0/24 \
  --allocation-pool start=10.0.0.100,end=10.0.0.200  \
  --gateway 10.0.0.1 --dns-nameserver 8.8.8.8

(overcloud-pre) [stack@undercloud ~]$ 
openstack network create private

(overcloud-pre) [stack@undercloud ~]$ 
openstack subnet create private-subnet \
  --network private \
  --dns-nameserver 8.8.4.4 --gateway 172.16.1.1 \
  --subnet-range 172.16.1.0/24

(overcloud-pre) [stack@undercloud ~]$ openstack router create router1

(overcloud-pre) [stack@undercloud ~]$ openstack router add subnet router1 private-subnet

(overcloud-pre) [stack@undercloud ~]$ openstack router set router1 --external-gateway public

[root@overcloud2-ctrl01 ~]# podman exec -ti ovn_controller ovn-nbctl --db=tcp:$IP:6641 show
switch 395e63e8-4b8a-40ac-9839-e42626ea2280 (neutron-4a27788e-2dee-4d52-8645-76c9bba43bdb) (aka private)
    port 91189608-dbdc-4f38-8544-8e2beffdd82d
        type: localport
        addresses: ["fa:16:3e:7f:e8:04 172.16.1.2"]
    port ab6916cf-9f3d-40bb-8232-00312f75756f
        type: router
        router-port: lrp-ab6916cf-9f3d-40bb-8232-00312f75756f
switch ec62ae1e-6849-43b7-8d92-612b61431449 (neutron-dd22086f-d277-4a09-a9a7-dc7093ec08af) (aka public)
    port e0f0e187-3ce3-4bd7-9132-e72670e7137e
        type: router
        router-port: lrp-e0f0e187-3ce3-4bd7-9132-e72670e7137e
    port 43927e85-4b91-4c3b-ad53-7a3a9968835f
        type: localport
        addresses: ["fa:16:3e:f8:96:ea"]
    port provnet-dd22086f-d277-4a09-a9a7-dc7093ec08af
        type: localnet
        tag: 10
        addresses: ["unknown"]
router 9e504d9d-12d7-4008-a5d3-f81f7ff865e9 (neutron-361e1933-2b49-4f21-b186-c55fd68e9e36) (aka router1)
    port lrp-ab6916cf-9f3d-40bb-8232-00312f75756f
        mac: "fa:16:3e:77:c8:94"
        networks: ["172.16.1.1/24"]
    port lrp-e0f0e187-3ce3-4bd7-9132-e72670e7137e
        mac: "fa:16:3e:21:ae:10"
        networks: ["10.0.0.192/24"]
        gateway chassis: [b3470bba-07e1-4ef1-8a0e-4da7354b86a4 e42c7f0f-fa85-4a48-b193-565a4a25e0ec]
    nat 56aeaed2-e5d1-49c6-9afe-201dff659898
        external ip: "10.0.0.192"
        logical ip: "172.16.1.0/24"
        type: "snat"

(overcloud-pre) [stack@undercloud ~]$ openstack flavor create m1.nano --vcpus 1 --ram 64 --disk 1

(overcloud-pre) [stack@undercloud ~]$ SGID=$(openstack security group list --project admin -c ID -f value)
(overcloud-pre) [stack@undercloud ~]$ openstack security group rule create --proto icmp $SGID
(overcloud-pre) [stack@undercloud ~]$ openstack security group rule create --dst-port 22 --proto tcp $SGID

(overcloud-pre) [stack@undercloud ~]$ openstack image create cirros --public --file cirros-0.4.0-x86_64-disk.raw

(overcloud-pre) [stack@undercloud ~]$ openstack keypair create --public-key ~/.ssh/id_rsa.pub stack

(overcloud-pre) [stack@undercloud ~]$ 
openstack server create  --flavor m1.nano \
 --image cirros  --key-name stack \
 --security-group $SGID \
 --network private test
```

### day 5

```
Final Lab Instructions
  Deploy Overcloud with 3 controllers and 2 compute nodes

Networking
  Overcloud should use IPv4 for the provisioning network

Overcloud should use IPV6, ranges are defined below:
  provisioning: Used for control plane (provisioning) to provide PXE/DHCP to overcloud bare metal nodes. Subnet: 192.0.2.0/24
  trunk: Used by Overcloud for network separation:
    External - VLAN 10 - 2001:db8:fd00:1000::/64
    Internal API - VLAN 20 - fd00:fd00:fd00:2000::/64
    Storage - VLAN 30 - fd00:fd00:fd00:3000::/64
    Storage Management - VLAN 40 - fd00:fd00:fd00:4000::/64
    Tenant - VLAN 50 - fd00:fd00:fd00:5000::/64

Overcloud nodes (controller and compute) should use 192.0.2.1 as default GW instead VLAN 10

Documentation: https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html-single/ipv6_networking_for_the_overcloud/index

Storage
Use the external ceph (start the VMS)

Configure the active-active cinder: https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html/storage_guide/ch-cinder#active-active-deployment-for-high-availability

Customization
  Configure the /etc/yum.repos.d/open.repo using Swift artifacts: http://hardysteven.blogspot.com/2016/08/tripleo-deploy-artifacts-and-puppet.html

Configure the TimeZone of the nodes to CEST
  Disable telemetry

Validation
  Ensure /etc/yum.repos.d/open.repo is on the nodes
  Ensure the timezone on the nodes
  Review pacemaker about the active-active Cinder
  Create a public network using IPv6, VLAN 10 and gateway 2001:db8:fd00:1000::1 (configured on interface virbr2.10 in the hypervisor)
  Create a VM and access using the FIP from workstation
```

```
# destroy current overcloud and overcloud-pre(undercloud) 
# list current overcloud stacks
(undercloud) [stack@undercloud ~]$ openstack stack list
+--------------------------------------+---------------+----------------------------------+-----------------+----------------------+--------------+
| ID                                   | Stack Name    | Project                          | Stack Status    | Creation Time        | Updated Time |
+--------------------------------------+---------------+----------------------------------+-----------------+----------------------+--------------+
| f9c155b3-1b15-459d-a262-37db4ff30c67 | overcloud-pre | 4785aebf2a7146b0b10c04eaf0c63566 | CREATE_COMPLETE | 2020-09-24T09:28:24Z | None         |
| 371952f7-25ae-40d7-9b6a-28d544c20074 | overcloud     | 4785aebf2a7146b0b10c04eaf0c63566 | CREATE_COMPLETE | 2020-09-24T05:33:55Z | None         |
+--------------------------------------+---------------+----------------------------------+-----------------+----------------------+--------------+

# delete stack overcloud 
[stack@undercloud ~]$ openstack overcloud delete overcloud --yes
Undeploying stack overcloud...
Waiting for messages on queue 'tripleo' with no timeout.
Deleting plan overcloud...
Success.

# show remain overcloud stack
(undercloud) [stack@undercloud ~]$ openstack stack list
+--------------------------------------+---------------+----------------------------------+-----------------+----------------------+--------------+
| ID                                   | Stack Name    | Project                          | Stack Status    | Creation Time        | Updated Time |
+--------------------------------------+---------------+----------------------------------+-----------------+----------------------+--------------+
| f9c155b3-1b15-459d-a262-37db4ff30c67 | overcloud-pre | 4785aebf2a7146b0b10c04eaf0c63566 | CREATE_COMPLETE | 2020-09-24T09:28:24Z | None         |
+--------------------------------------+---------------+----------------------------------+-----------------+----------------------+--------------+

# delete stack overcloud-pre
[stack@undercloud ~]$ openstack overcloud delete overcloud-pre --yes
Undeploying stack overcloud-pre... 
Waiting for messages on queue 'tripleo' with no timeout.
Deleting plan overcloud-pre...
Success.

# list overcloud stack
(undercloud) [stack@undercloud ~]$ openstack stack list

(undercloud) [stack@undercloud ~]$ 

# list overcloud plan
(undercloud) [stack@undercloud ~]$ openstack overcloud plan list

(undercloud) [stack@undercloud ~]$ 


# Configuring an IPv6 Address on the Undercloud
(undercloud) [stack@undercloud ~]$ sudo ovs-vsctl add-port br-ctlplane vlan10 tag=10 -- set interface vlan10 type=internal
(undercloud) [stack@undercloud ~]$ sudo ip l set dev vlan10 up; sudo ip addr add 2001:db8:fd00:1000::1/64 dev vlan10
(undercloud) [stack@undercloud ~]$ sudo ip a s dev vlan10
9: vlan10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 2a:6f:d6:e0:56:a7 brd ff:ff:ff:ff:ff:ff
    inet6 2001:db8:fd00:1000::1/64 scope global 
       valid_lft forever preferred_lft forever
    inet6 fe80::286f:d6ff:fee0:56a7/64 scope link 
       valid_lft forever preferred_lft forever

# make sure barematal node is power: off, provisioning: available and maintenance: false
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
| 0c523f61-cc33-4e99-8f06-4fa1690b97d8 | overcloud-compute03 | None          | power off   | available          | False       |
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+

# tag baremetal node with control and compute profile
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:control overcloud-ctrl01
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:control overcloud-ctrl02
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:control overcloud-ctrl03
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:compute overcloud-compute01
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities=profile:compute overcloud-compute02

# unset property capabilities from overcloud-networker and overcloud-stor01
(undercloud) [stack@undercloud ~]$ openstack baremetal node unset overcloud-networker --property capabilities
(undercloud) [stack@undercloud ~]$ openstack baremetal node unset overcloud-stor01 --property capabilities

# list overcloud profiles to check again
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
| 0c523f61-cc33-4e99-8f06-4fa1690b97d8 | overcloud-compute03 | available       | None            |                   |
+--------------------------------------+---------------------+-----------------+-----------------+-------------------+

# remove old templates directory and create it again
(undercloud) [stack@undercloud ~]$ rm -rf ~/templates
(undercloud) [stack@undercloud ~]$ mkdir -p ~/templates/environments

# create node-info.yaml in ~/templates
(undercloud) [stack@undercloud ~]$ cat > /home/stack/templates/node-info.yaml << EOF
parameter_defaults:
  OvercloudControlFlavor: control
  OvercloudComputeFlavor: compute
  ControllerCount: 3
  ComputeCount: 2
EOF

# create fix-nova-reserved-host-memory.yaml in ~/templates
(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/fix-nova-reserved-host-memory.yaml << EOF
parameter_defaults:
  NovaReservedHostMemory: 1024
EOF

# Copy roles_data.yaml and network_data.yaml into ~/templates
(undercloud) [stack@undercloud ~]$ THT=/usr/share/openstack-tripleo-heat-templates
(undercloud) [stack@undercloud ~]$ cp $THT/roles_data.yaml ~/templates
(undercloud) [stack@undercloud ~]$ cp $THT/network_data.yaml ~/templates

# generate ~/templates/network_data.yaml as requirement
#    External - VLAN 10 - 2001:db8:fd00:1000::/64
#    Internal API - VLAN 20 - fd00:fd00:fd00:2000::/64
#    Storage - VLAN 30 - fd00:fd00:fd00:3000::/64
#    Storage Management - VLAN 40 - fd00:fd00:fd00:4000::/64
#    Tenant - VLAN 50 - fd00:fd00:fd00:5000::/64
#    
#    Overcloud nodes (controller and compute) should use 192.0.2.1 as default GW instead VLAN 10
#    I'm not sure Tenant network does work with ipv6 only so include ipv4 content there
(undercloud) [stack@undercloud ~]$ 
cat > /home/stack/templates/network_data.yaml << EOF
- name: Storage
  vip: true
  vlan: 30
  name_lower: storage
  ipv6: true
  ipv6_subnet: 'fd00:fd00:fd00:3000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:3000::10', 'end': 'fd00:fd00:fd00:3000:ffff:ffff:ffff:fffe'}]
- name: StorageMgmt
  name_lower: storage_mgmt
  vip: true
  vlan: 40
  ipv6: true
  ipv6_subnet: 'fd00:fd00:fd00:4000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:4000::10', 'end': 'fd00:fd00:fd00:4000:ffff:ffff:ffff:fffe'}]
- name: InternalApi
  name_lower: internal_api
  vip: true
  vlan: 20
  ipv6: true
  ipv6_subnet: 'fd00:fd00:fd00:2000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:2000::10', 'end': 'fd00:fd00:fd00:2000:ffff:ffff:ffff:fffe'}]
- name: Tenant
  vip: false  # Tenant network does not use VIPs
  name_lower: tenant
  vlan: 50
  ipv6: true
  ipv6_subnet: 'fd00:fd00:fd00:5000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:5000::10', 'end': 'fd00:fd00:fd00:5000:ffff:ffff:ffff:fffe'}]
- name: External
  vip: true
  name_lower: external
  vlan: 10
  ipv6: true
  ipv6_subnet: '2001:db8:fd00:1000::/64'
  ipv6_allocation_pools: [{'start': '2001:db8:fd00:1000::10', 'end': '2001:db8:fd00:1000:ffff:ffff:ffff:fffe'}]
- name: Management
  # Management network is enabled by default for backwards-compatibility, but
  # is not included in any roles by default. Add to role definitions to use.
  enabled: true
  vip: false  # Management network does not use VIPs
  name_lower: management
  vlan: 60
  ipv6: true
  ipv6_subnet: 'fd00:fd00:fd00:6000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:6000::10', 'end': 'fd00:fd00:fd00:6000:ffff:ffff:ffff:fffe'}]
EOF

# remove rendered directory and recreate it
(undercloud) [stack@undercloud ~]$ rm -rf ~/rendered
(undercloud) [stack@undercloud ~]$ mkdir ~/rendered

# generate rendered templates with roles_data.yaml and network_data.yaml
(undercloud) [stack@undercloud ~]$ cd $THT
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ tools/process-templates.py -r ~/templates/roles_data.yaml -n ~/templates/network_data.yaml -o ~/rendered
...
jinja2 rendering role template role.role.j2.yaml
jinja2 rendering roles Controller,Compute,BlockStorage,ObjectStorage,CephStorage
rendering j2 template to file: /home/stack/rendered/./puppet/controller-role.yaml
rendering j2 template to file: /home/stack/rendered/./puppet/compute-role.yaml
rendering j2 template to file: /home/stack/rendered/./puppet/blockstorage-role.yaml
rendering j2 template to file: /home/stack/rendered/./puppet/objectstorage-role.yaml
rendering j2 template to file: /home/stack/rendered/./puppet/cephstorage-role.yaml

# copy rendered file into ~/templates
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cd ~/rendered
(undercloud) [stack@undercloud rendered]$ cp environments/network-environment.yaml ~/templates/environments
(undercloud) [stack@undercloud rendered]$ cp -rp network ~/templates
(undercloud) [stack@undercloud rendered]$ cp environments/net-bond-with-vlans.yaml ~/templates/environments/
(undercloud) [stack@undercloud rendered]$ cd

# define network environment parameters as below 
# see also: https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html-single/ipv6_networking_for_the_overcloud/index
# see also: https://access.redhat.com/solutions/2213711
cat > ~/templates/network-environment-addon.yaml << EOF
parameter_defaults:
  DnsServers: ["8.8.8.8","8.8.4.4"]
  ControlPlaneDefaultRoute: 192.0.2.1
  ControlPlaneSubnetCidr: "24"
  EC2MetadataIp: 192.0.2.1
  NetworkDeploymentActions: ['CREATE','UPDATE']
EOF

# make backup of network/config/bond-with-vlans/controller.yaml
(undercloud) [stack@undercloud ~]$ cp templates/network/config/bond-with-vlans/controller.yaml templates/network/config/bond-with-vlans/controller.yaml.orig

# generate patch file for network/config/bond-with-vlans/controller.yaml
# this patch file will setup default route on controlplane
(undercloud) [stack@undercloud ~]$ 
cat > patch-network-config-bond-with-vlan-controller << EOF
--- /home/stack/templates/network/config/bond-with-vlans/controller.yaml.orig   2020-09-25 03:16:56.580784872 -0400
+++ /home/stack/templates/network/config/bond-with-vlans/controller.yaml        2020-09-25 03:23:11.001684779 -0400
@@ -210,6 +210,9 @@
                 routes:
                   list_concat_unique:
                     - get_param: ControlPlaneStaticRoutes
+                    - - default: true
+                        next_hop:
+                          get_param: ControlPlaneDefaultRoute
               - type: ovs_bridge
                 name: bridge_name
                 dns_servers:
@@ -288,9 +291,6 @@
                   routes:
                     list_concat_unique:
                       - get_param: ExternalInterfaceRoutes
-                      - - default: true
-                          next_hop:
-                            get_param: ExternalInterfaceDefaultRoute
 outputs:
   OS::stack_id:
     description: The OsNetConfigImpl resource.
EOF

# apply patch to ~/templates/network/config/bond-with-vlans/controller.yaml
(undercloud) [stack@undercloud ~]$ patch ~/templates/network/config/bond-with-vlans/controller.yaml < patch-network-config-bond-with-vlan-controller 
patching file /home/stack/templates/network/config/bond-with-vlans/controller.yaml

# Storage
#   Use the external ceph (start the VMS)

# start workstaion and ceph-node01:03 on pool08-iad
[root@pool08-iad ~]# virsh start workstation
Domain workstation started

[root@pool08-iad ~]# for i in `seq 1 3`; do virsh start ceph-node0$i ; done 
Domain ceph-node01 started

Domain ceph-node02 started

Domain ceph-node03 started

# ssh login into workstation
[root@pool08-iad ~]# ssh root@192.0.2.249

# check ceph cluster status 
[root@workstation ~]# ceph -s
  cluster:
    id:     eb0670c0-e359-4cb3-bf11-c650b82118ef
    health: HEALTH_WARN
            application not enabled on 2 pool(s)
 
  services:
    mon: 3 daemons, quorum ceph-node01,ceph-node02,ceph-node03 (age 81s)
    mgr: ceph-node02(active, since 70s), standbys: ceph-node01, ceph-node03
    osd: 6 osds: 6 up (since 69s), 6 in (since 2d)
    rgw: 3 daemons active (ceph-node01.rgw0, ceph-node02.rgw0, ceph-node03.rgw0)
 
  task status:
 
  data:
    pools:   9 pools, 288 pgs
    objects: 369 objects, 249 MiB
    usage:   6.4 GiB used, 54 GiB / 60 GiB avail
    pgs:     288 active+clean

# check external-ceph.yaml on workstation
[root@workstation ~]# cat ceph-external.yaml 
parameter_defaults:
 CephClientKey: AQB/u2lf5h5cLBAA0x8fp0sbn+mgJkNJOOTZUA==
 CephClusterFSID: eb0670c0-e359-4cb3-bf11-c650b82118ef
 CephExternalMonHost: 172.18.0.61,172.18.0.62,172.18.0.63

# copy ceph-external.yaml from workstation to undercloud on hypervisor
[root@pool08-iad ~]# ssh 192.0.2.249 cat ceph-external.yaml | ssh stack@undercloud "tee templates/ceph-external.yaml"
parameter_defaults:
 CephClientKey: AQB/u2lf5h5cLBAA0x8fp0sbn+mgJkNJOOTZUA==
 CephClusterFSID: eb0670c0-e359-4cb3-bf11-c650b82118ef
 CephExternalMonHost: 172.18.0.61,172.18.0.62,172.18.0.63

# Configure the active-active cinder: https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html/storage_guide/ch-cinder#active-active-deployment-for-high-availability
# will add environment template into deployment scripts
# -e $THT/environments/cinder-volume-active-active.yaml \

# generate open.repo artifacts
(undercloud) [stack@undercloud ~]$ tar zcvf openrepo.tgz /etc/yum.repos.d/open.repo 
tar: Removing leading `/' from member names
/etc/yum.repos.d/open.repo

# upload open.repo artifacts into swift
(undercloud) [stack@undercloud ~]$ upload-swift-artifacts -f openrepo.tgz
Creating new Swift Temp-Url-Key for container: overcloud-artifacts
Creating heat environment file: /home/stack/.tripleo/environments/deployment-artifacts.yaml
Uploading file to swift: openrepo.tgz
+--------------+---------------------+----------------------------------+
| object       | container           | etag                             |
+--------------+---------------------+----------------------------------+
| openrepo.tgz | overcloud-artifacts | 3ad2df7b98401871f38ad23046cab117 |
+--------------+---------------------+----------------------------------+
Upload complete.

# check file /home/stack/.tripleo/environments/deployment-artifacts.yaml content
(undercloud) [stack@undercloud ~]$ cat /home/stack/.tripleo/environments/deployment-artifacts.yaml
# Heat environment to deploy artifacts via Swift Temp URL(s)
parameter_defaults:
    DeployArtifactURLs:
    - 'http://192.0.2.3:8080/v1/AUTH_4785aebf2a7146b0b10c04eaf0c63566/overcloud-artifacts/openrepo.tgz?temp_url_sig=cfa0bbf7d2ac316dbf4c5fad2613ca2bb4ec84c0&temp_url_expires=1632549614'

# Configure the TimeZone of the nodes to CEST
(undercloud) [stack@undercloud ~]$ 
cat > ~/templates/timezone.yaml << EOF
parameter_defaults:
  TimeZone: 'CST'
EOF

# Disable telemetry 
# with -e /usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml in deploy script

# generate deployment script
cat > ~/deploy-final.sh <<\EOF
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/network-isolation.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible-external.yaml \
-e $THT/environments/cinder-volume-active-active.yaml \
-e $THT/environments/disable-telemetry.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/network-environment-addon.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/node-info.yaml \
-e $CNF/ceph-external.yaml \
-e $CNF/timezone.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml
EOF

# run deploy script
(undercloud) [stack@undercloud ~]$ time /bin/bash -x deploy-final.sh

```