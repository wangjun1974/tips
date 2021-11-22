### 预安装节点的部署方式
```
# 参考模版
https://gitlab.cee.redhat.com/sputhenp/lab/-/blob/master/templates/osp-16-1/pre-provisioned/overcloud-deploy-tls-everywhere.sh

# 安装 overcloud-controller-0
virsh attach-disk jwang-overcloud-ctrl01 /root/jwang/isos/rhel-8.2-x86_64-dvd.iso hda --type cdrom --mode readonly --config
# 重启 
# ks=http://10.66.208.115/overcloud-controller-0-ks.cfg nameserver=192.168.122.3 ip=192.0.2.51::192.0.2.1:255.255.255.0:overcloud-controller-0.example.com:ens3:none

# 生成 ks.cfg - overcloud-controller-0
cat > overcloud-controller-0-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=ens3 --hostname=overcloud-controller-0.example.com --bootproto=static --ip=192.0.2.51 --netmask=255.255.255.0 --gateway=192.0.2.1 --nameserver=192.168.122.3
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
openssl-perl
%end
EOF

# 安装 overcloud-controller-1
virsh attach-disk jwang-overcloud-ctrl02 /root/jwang/isos/rhel-8.2-x86_64-dvd.iso hda --type cdrom --mode readonly --config
# 重启 
# ks=http://10.66.208.115/overcloud-controller-1-ks.cfg nameserver=192.168.122.3 ip=192.0.2.52::192.0.2.1:255.255.255.0:overcloud-controller-1.example.com:ens3:none

# 生成 ks.cfg - overcloud-controller-1
cat > overcloud-controller-1-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=ens3 --hostname=overcloud-controller-1.example.com --bootproto=static --ip=192.0.2.52 --netmask=255.255.255.0 --gateway=192.0.2.1 --nameserver=192.168.122.3
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
openssl-perl
%end
EOF

# 安装 overcloud-controller-2
virsh attach-disk jwang-overcloud-ctrl03 /root/jwang/isos/rhel-8.2-x86_64-dvd.iso hda --type cdrom --mode readonly --config
# 重启 
# ks=http://10.66.208.115/overcloud-controller-2-ks.cfg nameserver=192.168.122.3 ip=192.0.2.53::192.0.2.1:255.255.255.0:overcloud-controller-2.example.com:ens3:none

# 生成 ks.cfg - overcloud-controller-2
cat > overcloud-controller-2-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=ens3 --hostname=overcloud-controller-2.example.com --bootproto=static --ip=192.0.2.53 --netmask=255.255.255.0 --gateway=192.0.2.1 --nameserver=192.168.122.3
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
openssl-perl
%end
EOF

# 安装 overcloud-computehci-0
# 如果之前未清理磁盘可以执行
# sgdisk --delete /dev/vda
# sgdisk --delete /dev/vdb
# sgdisk --delete /dev/vdc
# sgdisk --delete /dev/vdd
virsh attach-disk jwang-overcloud-ceph01 /root/jwang/isos/rhel-8.2-x86_64-dvd.iso hda --type cdrom --mode readonly --config
# 重启 
# ks=http://10.66.208.115/overcloud-computehci-0-ks.cfg nameserver=192.168.122.3 ip=192.0.2.71::192.0.2.1:255.255.255.0:overcloud-computehci-0.example.com:ens3:none

# 生成 ks.cfg - overcloud-computehci-0
cat > overcloud-computehci-0-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
ignoredisk --only-use=vda
autopart
network --device=ens3 --hostname=overcloud-computehci-0.example.com --bootproto=static --ip=192.0.2.71 --netmask=255.255.255.0 --gateway=192.0.2.1 --nameserver=192.168.122.3
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
gdisk
openssl-perl
%end
EOF

# 安装 overcloud-computehci-1
virsh attach-disk jwang-overcloud-ceph02 /root/jwang/isos/rhel-8.2-x86_64-dvd.iso hda --type cdrom --mode readonly --config
# 重启 
# ks=http://10.66.208.115/overcloud-computehci-1-ks.cfg nameserver=192.168.122.3 ip=192.0.2.72::192.0.2.1:255.255.255.0:overcloud-computehci-1.example.com:ens3:none

# 生成 ks.cfg - overcloud-computehci-1
cat > overcloud-computehci-1-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
ignoredisk --only-use=vda
autopart
network --device=ens3 --hostname=overcloud-computehci-1.example.com --bootproto=static --ip=192.0.2.72 --netmask=255.255.255.0 --gateway=192.0.2.1 --nameserver=192.168.122.3
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
gdisk
openssl-perl
%end
EOF

# 安装 overcloud-computehci-2
virsh attach-disk jwang-overcloud-ceph03 /root/jwang/isos/rhel-8.2-x86_64-dvd.iso hda --type cdrom --mode readonly --config
# 重启 
# ks=http://10.66.208.115/overcloud-computehci-2-ks.cfg nameserver=192.168.122.3 ip=192.0.2.73::192.0.2.1:255.255.255.0:overcloud-computehci-2.example.com:ens3:none

# 生成 ks.cfg - overcloud-computehci-2
cat > overcloud-computehci-2-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
ignoredisk --only-use=vda
autopart
network --device=ens3 --hostname=overcloud-computehci-2.example.com --bootproto=static --ip=192.0.2.73 --netmask=255.255.255.0 --gateway=192.0.2.1 --nameserver=192.168.122.3
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
gdisk
openssl-perl
%end
EOF

# 生成 osp.repo
(undercloud) [stack@undercloud ~]$ 
> /tmp/osp.repo

for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms
do 
cat >> /tmp/osp.repo <<EOF
[$i]
name=$i
baseurl=http://192.0.2.1:8088/repos/osp16.1/$i/
enabled=1
gpgcheck=0

EOF
done

# 生成 ssh config
cat > ~/.ssh/config <<EOF
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF

# 生成 inventory
cat > /tmp/inventory <<EOF
[controller]
192.0.2.5[1:3] ansible_user=root

[computehci]
192.0.2.7[1:3] ansible_user=root

EOF

# 设置 stack 用户的 public key auth
ansible -i /tmp/inventory all -f 6 -m authorized_key -a 'user=root state=present key="{{ lookup(\"file\",\"/home/stack/.ssh/id_rsa.pub\") }}"' -k

# 为 deployed server 添加 stack 用户
ansible -i /tmp/inventory all -f 6 -m user -a 'name=stack state=present'
ansible -i /tmp/inventory all -f 6 -m shell -a 'echo "redhat" | passwd stack --stdin'
ansible -i /tmp/inventory all -f 6 -m shell -a 'echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack'
ansible -i /tmp/inventory all -f 6 -m shell -a 'chmod 400 /etc/sudoers.d/stack'

# 重新生成 inventory
cat > /tmp/inventory <<EOF
[controller]
192.0.2.5[1:3] ansible_user=stack ansible_become=yes ansible_become_method=sudo

[computehci]
192.0.2.7[1:3] ansible_user=stack ansible_become=yes ansible_become_method=sudo

EOF

# 设置 public key auth
ansible -i /tmp/inventory all -f 6 -m authorized_key -a 'user=stack state=present key="{{ lookup(\"file\",\"/home/stack/.ssh/id_rsa.pub\") }}"' -k

# 在 undercloud 上 bind mount /var/www/html/repos 到 /var/lib/ironic/httpboot/repos 
# 这里 yum 服务器用 director 的 8088 端口提供服务
# 因此需要 bind mount repos 目录到 /var/lib/ironic/httpboot/repos
(undercloud) [stack@undercloud ~]$ 
sudo -i
cd /var/lib/ironic/httpboot
mkdir -p repos
mount -o bind /var/www/html/repos repos
chown -R --reference pxelinux.cfg repos
exit
(undercloud) [stack@undercloud ~]$ 

# 拷贝 osp.repo 
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m copy -a 'src=/tmp/osp.repo dest=/etc/yum.repos.d'

# 检查 yum repo 可用 
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m shell -a 'yum install -y chrony'

# 设置 container-tools repository module 为版本 2.0
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m shell -a 'cmd="dnf module disable -y container-tools:rhel8"'
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m shell -a 'cmd="dnf module enable -y container-tools:2.0"'

# 设置 virt repository module 为版本 8.2
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m shell -a 'cmd="dnf module disable -y virt:rhel"'
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m shell -a 'cmd="dnf dnf module enable -y virt:8.2"'

# 更新系统
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m yum -a 'name=* state=latest'
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m reboot

# 在 overcloud 节点上安装 
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m yum -a 'name=python3-heat-agent* state=latest'

# 参考文档
# https://slagle.fedorapeople.org/tripleo-docs/install/advanced_deployment/deployed_server.html
# https://virtorbis.virtcompute.com/?tag=pre-provisioned-nodes

# 2021/11/11 - 继续尝试
# 参考文档： 
# https://virtorbis.virtcompute.com/?tag=pre-provisioned-nodes
# 2021/11/12 - 继续尝试
# 参考文档：
# https://opendev.org/openstack/tripleo-heat-templates/src/branch/master/deployed-server

cat > ~/templates/node-info.yaml <<EOF
parameter_defaults:
  ControllerCount: 1
  ComputeCount: 1
  ComputeHCICount: 0
EOF

cat > ~/templates/hostname-map.yaml <<EOF
parameter_defaults:
  HostnameMap:
    overcloud-controller-0: controller-00
    overcloud-novacompute-0: compute-00
EOF

cat > ~/templates/ctlplane-assignments.yaml <<EOF
resource_registry:
  OS::TripleO::DeployedServer::ControlPlanePort: /usr/share/openstack-tripleo-heat-templates/deployed-server/deployed-neutron-port.yaml
parameter_defaults:
  DeployedServerPortMap:
    controller-00-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.51
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    compute-00-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.52
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
EOF

生成部署脚本
(undercloud) [stack@undercloud ~]$ cat > ~/deploy-preprovion.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug \
--disable-validations \
--overcloud-ssh-user stack \
--overcloud-ssh-key ~/.ssh/id_rsa \
--templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/deployed-server-environment.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/node-info.yaml \
-e $CNF/hostname-map.yaml \
-e $CNF/ctlplane-assignments.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF
```

```
# 2021/11/12: 部署成功，:-)
(undercloud) [stack@undercloud ~]$ source ~/overcloudrc
(overcloud) [stack@undercloud ~]$ openstack endpoint list
+----------------------------------+-----------+--------------+----------------+---------+-----------+--------------------------------------------
--+
| ID                               | Region    | Service Name | Service Type   | Enabled | Interface | URL                                        
  |
+----------------------------------+-----------+--------------+----------------+---------+-----------+--------------------------------------------
--+
| 0c0a5e9ff4b54e91a4c29aba8c16dd7e | regionOne | nova         | compute        | True    | public    | http://192.0.2.13:8774/v2.1                
  |
| 110f696299a24277a56f755180ec6314 | regionOne | cinderv3     | volumev3       | True    | public    | http://192.0.2.13:8776/v3/%(tenant_id)s    
  |
| 1ddb3ffddaae450281bea1afc30d2a84 | regionOne | heat         | orchestration  | True    | admin     | http://192.0.2.13:8004/v1/%(tenant_id)s    
...
(overcloud) [stack@undercloud ~]$ openstack compute service list
+--------------------------------------+----------------+---------------------------+----------+---------+-------+----------------------------+
| ID                                   | Binary         | Host                      | Zone     | Status  | State | Updated At                 |
+--------------------------------------+----------------+---------------------------+----------+---------+-------+----------------------------+
| 75b6137e-c2b7-485c-9d13-d915e1a81db4 | nova-conductor | controller-00.localdomain | internal | enabled | up    | 2021-11-12T01:48:03.000000 |
| 93c38778-eb0c-4fd0-8426-302d1c40c055 | nova-scheduler | controller-00.localdomain | internal | enabled | up    | 2021-11-12T01:48:08.000000 |
| 6f9dd990-4465-47d2-a56b-5c07b4a91512 | nova-compute   | compute-00.localdomain    | nova     | enabled | up    | 2021-11-12T01:48:08.000000 |
+--------------------------------------+----------------+---------------------------+----------+---------+-------+----------------------------+
(overcloud) [stack@undercloud ~]$ openstack volume service list
+------------------+---------------------------+------+---------+-------+----------------------------+
| Binary           | Host                      | Zone | Status  | State | Updated At                 |
+------------------+---------------------------+------+---------+-------+----------------------------+
| cinder-scheduler | controller-00.example.com | nova | enabled | up    | 2021-11-12T01:48:21.000000 |
| cinder-volume    | hostgroup@tripleo_iscsi   | nova | enabled | up    | 2021-11-12T01:48:21.000000 |
+------------------+---------------------------+------+---------+-------+----------------------------+
(overcloud) [stack@undercloud ~]$ openstack network agent list
+--------------------------------------+----------------------+---------------------------+-------------------+-------+-------+-------------------------------+
| ID                                   | Agent Type           | Host                      | Availability Zone | Alive | State | Binary                        |
+--------------------------------------+----------------------+---------------------------+-------------------+-------+-------+-------------------------------+
| 914173e9-5b68-474d-b66f-ddd73f7ede20 | OVN Controller agent | compute-00.localdomain    |                   | :-)   | UP    | ovn-controller                |
| 73c18d59-2771-4e82-86f9-626d7d33697e | OVN Metadata agent   | compute-00.localdomain    |                   | :-)   | UP    | networking-ovn-metadata-agent |
| 85179806-c77a-4ca3-95b9-9ae30a8b7ab9 | OVN Controller agent | controller-00.localdomain |                   | :-)   | UP    | ovn-controller                |
+--------------------------------------+----------------------+---------------------------+-------------------+-------+-------+-------------------------------+

# 2021/11/12
# 下一步计划是尝试在已安装服务器下部署包含 ceph 的 osp 环境

cat > ~/templates/node-info.yaml <<EOF
parameter_defaults:
  ControllerCount: 3
  ComputeCount: 0
  ComputeHCICount: 3
EOF

cat > ~/templates/ctlplane-assignments.yaml <<EOF
resource_registry:
  OS::TripleO::DeployedServer::ControlPlanePort: /usr/share/openstack-tripleo-heat-templates/deployed-server/deployed-neutron-port.yaml
parameter_defaults:
  DeployedServerPortMap:
    overcloud-controller-0-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.51
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-controller-1-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.52
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-controller-2-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.53
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-computehci-0-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.71
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-computehci-1-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.72
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-computehci-2-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.73
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
EOF

生成部署脚本
(undercloud) [stack@undercloud ~]$ cat > ~/deploy-preprovion.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug \
--disable-validations \
--overcloud-ssh-user stack \
--overcloud-ssh-key ~/.ssh/id_rsa \
--templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/deployed-server-environment.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible.yaml \
-e $THT/environments/ceph-ansible/ceph-rgw.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/node-info.yaml \
-e $CNF/ctlplane-assignments.yaml \
-e $CNF/cephstorage.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF

# 继续做部署网络隔离和固定 IP 地址的配置
# 目前的做法下，需要检查部署完后的 RedisVip 和 OVSDBsVIP 是否与 $THT/environments/fixed-ips.yaml 里定义的一致
# 参考链接：
# https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/deployed_server.html
# https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/custom_networks.html#custom-networks
# https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/provisioning/baremetal_provision.html#baremetal-provision
# https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/deployed_server.html#deployed-server-with-config-download

cat > ~/templates/ctlplane-assignments.yaml <<EOF
resource_registry:
  OS::TripleO::DeployedServer::ControlPlanePort: /usr/share/openstack-tripleo-heat-templates/deployed-server/deployed-neutron-port.yaml
  OS::TripleO::Network::Ports::ControlPlaneVipPort: /usr/share/openstack-tripleo-heat-templates/deployed-server/deployed-neutron-port.yaml

parameter_defaults:
  NeutronPublicInterface: bond1
  EC2MetadataIp: 192.0.2.1
  ControlPlaneDefaultRoute: 192.0.2.1
  DeployedServerPortMap:
    control_virtual_ip:
      fixed_ips:
        - ip_address: 192.0.2.240
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-controller-0-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.51
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-controller-1-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.52
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-controller-2-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.53
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-computehci-0-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.71
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-computehci-1-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.72
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
    overcloud-computehci-2-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.73
      subnets:
        - cidr: 192.0.2.0/24
      network:
        tags:
          - 192.0.2.0/24
EOF

生成部署脚本
(undercloud) [stack@undercloud ~]$ cat > ~/deploy-preprovion.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug \
--disable-validations \
--overcloud-ssh-user stack \
--overcloud-ssh-key ~/.ssh/id_rsa \
--templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/deployed-server-environment.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible.yaml \
-e $THT/environments/ceph-ansible/ceph-rgw.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/fixed-ips.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/node-info.yaml \
-e $CNF/ctlplane-assignments.yaml \
-e $CNF/cephstorage.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF

# 部署成功后
# 确认使用了固定的 ip 地址
(undercloud) [stack@undercloud ~]$ ssh stack@192.0.2.51 
[stack@overcloud-controller-0 ~]$ sudo pcs status | grep ip 
Cluster name: tripleo_cluster
  * ip-192.0.2.240      (ocf::heartbeat:IPaddr2):       Started overcloud-controller-0
  * ip-192.168.122.40   (ocf::heartbeat:IPaddr2):       Started overcloud-controller-1
  * ip-172.16.2.241     (ocf::heartbeat:IPaddr2):       Started overcloud-controller-2
  * ip-172.16.2.240     (ocf::heartbeat:IPaddr2):       Started overcloud-controller-0
  * ip-172.16.1.240     (ocf::heartbeat:IPaddr2):       Started overcloud-controller-1
  * ip-172.16.3.240     (ocf::heartbeat:IPaddr2):       Started overcloud-controller-2
  * ip-172.16.2.242     (ocf::heartbeat:IPaddr2):       Started overcloud-controller-0
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph status 
  cluster:
    id:     931fbdee-be5c-4968-a046-8d3a37542fea
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum overcloud-controller-0,overcloud-controller-1,overcloud-controller-2 (age 59m)
    mgr: overcloud-controller-0(active, since 56m), standbys: overcloud-controller-1, overcloud-controller-2
    osd: 9 osds: 9 up (since 54m), 9 in (since 54m)
    rgw: 3 daemons active (overcloud-controller-0.rgw0, overcloud-controller-1.rgw0, overcloud-controller-2.rgw0)
 
  task status:
 
  data:
    pools:   7 pools, 896 pgs
    objects: 190 objects, 6.7 KiB
    usage:   9.1 GiB used, 891 GiB / 900 GiB avail
    pgs:     896 active+clean

(undercloud) [stack@undercloud ~]$ source overcloudrc
(overcloud) [stack@undercloud ~]$ openstack endpoint list
+----------------------------------+-----------+--------------+----------------+---------+-----------+--------------------------------------------
-------------+
| ID                               | Region    | Service Name | Service Type   | Enabled | Interface | URL                                        
             |
+----------------------------------+-----------+--------------+----------------+---------+-----------+--------------------------------------------
-------------+
| 137a44d080e64259b27384c5ddc9315a | regionOne | cinderv3     | volumev3       | True    | admin     | http://172.16.2.240:8776/v3/%(tenant_id)s  
             |
| 1a17b23033974d0e979184e365367845 | regionOne | heat         | orchestration  | True    | admin     | http://172.16.2.240:8004/v1/%(tenant_id)s  
             |
| 1d10e3b6e25444739e46f59f610b4e6f | regionOne | neutron      | network        | True    | public    | http://192.168.122.40:9696                 
             |
| 24e17b2fe3b340eb8422f7ad853fb4c4 | regionOne | nova         | compute        | True    | internal  | http://172.16.2.240:8774/v2.1              
             |
| 3786930a94084f43a18ce9d3a0864d0a | regionOne | keystone     | identity       | True    | admin     | http://192.0.2.240:35357      
...

# 部署时用的 ansible.cfg 
# sudo cat /var/lib/mistral/overcloud/ansible.cfg
# openstack overcloud deploy 有个参数 --override-ansible-cfg 可以按需定制 ansible.cfg 
# https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/ansible_config_download.html

# 生成 $THT/tls-params.yaml 文件
(undercloud) [stack@undercloud ~]$ cat > ~/templates/tls-params.yaml << 'EOF'
resource_registry:
  OS::TripleO::Services::IpaClient: /usr/share/openstack-tripleo-heat-templates/deployment/ipa/ipaservices-baremetal-ansible.yaml
parameter_defaults:
  IdMModifyDNS: false
  IdMServer: helper.example.com
  IdMDomain: example.com
  IdMInstallClientPackages: True
  DnsSearchDomains: ["example.com"]
  DnsServers: ["192.168.122.3"]
EOF

# tls-everywhere 需要
# 创建 /etc/pki/CA 目录
# 在 overcloud 节点上安装 openssl-perl 
# 查询提供者：sudo yum provides /etc/pki/CA
# 参考链接：https://bugs.launchpad.net/tripleo/+bug/1821139
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m yum -a 'name=openssl-perl* state=latest'

# 管理员身份登陆 ipa 服务器
# 参考链接: 
# https://access.redhat.com/solutions/642993
# https://access.redhat.com/solutions/912853
# echo <pass> | sudo kinit admin
# sudo ipa-getkeytab -s helper.example.com -k /etc/krb5.keytab -p host/$(hostname)
# sudo systemctl restart certmonger
# sudo ipa-getcert list
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m shell -a 'echo redhat123 | sudo kinit admin' 
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m shell -a "chmod 0644 /etc/krb5.keytab"
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m shell -a "sudo ipa-getkeytab -s helper.example.com -k /etc/krb5.keytab -p host/$(hostname)"
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -f 6 -m systemd -a "name=certmonger state=restarted"
# 尝试失败了
# 计划先实现一下 tls-everywhere 
# 然后再回来实现 deployed-server tls-everywhere
# 参考链接: https://review.gerrithub.io/c/redhat-openstack/infrared/+/491647

# 继续尝试部署 ansible-based tls-everywhere 
生成部署脚本
(undercloud) [stack@undercloud ~]$ cat > ~/deploy-preprovion.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug \
--disable-validations \
--overcloud-ssh-user stack \
--overcloud-ssh-key ~/.ssh/id_rsa \
--templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/deployed-server-environment.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible.yaml \
-e $THT/environments/ceph-ansible/ceph-rgw.yaml \
-e $THT/environments/ssl/enable-internal-tls.yaml \
-e $THT/environments/services/haproxy-public-tls-certmonger.yaml \
-e $THT/environments/ssl/tls-everywhere-endpoints-dns.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/fixed-ips.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/custom-domain.yaml \
-e $CNF/node-info.yaml \
-e $CNF/keystone_domain_specific_ldap_backend.yaml \
-e $CNF/ctlplane-assignments.yaml \
-e $CNF/cephstorage.yaml \
-e $CNF/tls-params.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF

# 尝试 IdMModifyDNS: true
# 生成 $THT/tls-params.yaml 文件
(undercloud) [stack@undercloud ~]$ cat > ~/templates/tls-params.yaml << 'EOF'
resource_registry:
  OS::TripleO::Services::IpaClient: /usr/share/openstack-tripleo-heat-templates/deployment/ipa/ipaservices-baremetal-ansible.yaml
parameter_defaults:
  IdMModifyDNS: true
  IdMServer: helper.example.com
  IdMDomain: example.com
  IdMInstallClientPackages: True
  DnsSearchDomains: ["example.com"]
  DnsServers: ["192.168.122.3"]
EOF

# 继续尝试部署 ansible-based tls-everywhere 
# 添加 octavia, ceph dashboard 和 stf 
生成部署脚本
(undercloud) [stack@undercloud ~]$ cat > ~/deploy-preprovion.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug \
--disable-validations \
--overcloud-ssh-user stack \
--overcloud-ssh-key ~/.ssh/id_rsa \
--templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/deployed-server-environment.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible.yaml \
-e $THT/environments/ceph-ansible/ceph-rgw.yaml \
-e $THT/environments/ceph-ansible/ceph-dashboard.yaml \
-e $THT/environments/ssl/enable-internal-tls.yaml \
-e $THT/environments/services/haproxy-public-tls-certmonger.yaml \
-e $THT/environments/ssl/tls-everywhere-endpoints-dns.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/fixed-ips.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e $THT/environments/services/octavia.yaml \
-e $THT/environments/metrics/ceilometer-write-qdr.yaml \
-e $THT/environments/metrics/collectd-write-qdr.yaml \
-e $THT/environments/metrics/qdr-edge-only.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/custom-domain.yaml \
-e $CNF/node-info.yaml \
-e $CNF/enable-tls.yaml \
-e $CNF/inject-trust-anchor.yaml \
-e $CNF/keystone_domain_specific_ldap_backend.yaml \
-e $CNF/ctlplane-assignments.yaml \
-e $CNF/cephstorage.yaml \
-e $CNF/tls-params.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
-e $CNF/enable-stf.yaml \
-e $CNF/stf-connectors.yaml \
--ntp-server 192.0.2.1
EOF

在重新部署时，需手工更新 undercloud 的 /etc/novajoin/krb5.keytab 文件
echo redhat123 | sudo kinit admin
sudo ipa-getkeytab -s helper.example.com -p nova/undercloud.example.com -k /etc/novajoin/krb5.keytab
sudo chmod a+r /etc/novajoin/krb5.keytab
ls -l /etc/novajoin/krb5.keytab
klist
kdestroy
klist
kinit -kt /etc/novajoin/krb5.keytab nova/undercloud.example.com
klist
chmod a+r /etc/novajoin/krb5.keytab

在重新部署时，需手工更新 deployed server 的 krb5.keytab 文件
ansible -i /tmp/inventory all -f 6 -m shell -a 'echo redhat123 | sudo kinit admin' 
ansible -i /tmp/inventory all -f 6 -m shell -a 'sudo ipa-join'
ansible -i /tmp/inventory all -f 6 -m shell -a 'sudo rm -f /etc/krb5.keytab'
ansible -i /tmp/inventory all -f 6 -m setup
# ssh overcloud node
sudo ipa-getkeytab -s helper.example.com -p host/$(hostname) -k /etc/krb5.keytab
# done

ansible -i /tmp/inventory all -f 6 -m shell -a "sudo chmod a+r /etc/krb5.keytab"
# ansible -i /tmp/inventory all -f 6 -m shell -a "kdestroy -A"
# ansible -i /tmp/inventory all -f 6 -m shell -a "kinit -kt /etc/krb5.keytab host/$hostname"
# ssh overcloud node
kdestroy -A; kinit -kt /etc/krb5.keytab host/$(hostname); klist
sudo kdestroy -A; sudo kinit -kt /etc/krb5.keytab host/$(hostname); sudo klist
# done
```

报错记录 
```
1.
Host overcloud.example.com not found in /home/stack/.ssh/known_hosts^M
Cannot find any hosts on 'overcloud' in network 'ctlplane'

ipa dnszone-del ctlplane.example.com

2.
2021-11-02 02:38:46Z [overcloud]: CREATE_FAILED  'int' object has no attribute 'split'
参考
https://access.redhat.com/solutions/5641801

```