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
%end
EOF

# 在所有预部署节点上创建用户 stack
useradd stack
passwd stack

# 设置 sudo
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
chmod 0400 /etc/sudoers.d/stack

# 建立 undercloud 到 overcloud 节点 stack 用户 ssh public key 登录
(undercloud) [stack@undercloud ~]$ ssh-copy-id stack@192.0.2.51
(undercloud) [stack@undercloud ~]$ ssh-copy-id stack@192.0.2.52
(undercloud) [stack@undercloud ~]$ ssh-copy-id stack@192.0.2.53
(undercloud) [stack@undercloud ~]$ ssh-copy-id stack@192.0.2.71
(undercloud) [stack@undercloud ~]$ ssh-copy-id stack@192.0.2.72
(undercloud) [stack@undercloud ~]$ ssh-copy-id stack@192.0.2.73

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

# 生成 inventory
cat > /tmp/inventory <<EOF
[controller]
192.0.2.5[1:3] ansible_user=stack ansible_become=yes ansible_become_method=sudo

[computehci]
192.0.2.7[1:3] ansible_user=stack ansible_become=yes ansible_become_method=sudo

EOF

# bind mount /var/www/html/repos 到 /var/lib/ironic/httpboot/repos 
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
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m copy -a 'src=/tmp/osp.repo dest=/etc/yum.repos.d'

# 设置 container-tools repository module 为版本 2.0
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m shell -a 'cmd="dnf module disable -y container-tools:rhel8"'
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m shell -a 'cmd="dnf module enable -y container-tools:2.0"'

# 设置 virt repository module 为版本 8.2
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m shell -a 'cmd="dnf module disable -y virt:rhel"'
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m shell -a 'cmd="dnf dnf module enable -y virt:8.2"'

# 更新系统
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m yum -a 'name=* state=latest'
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m reboot

# 拷贝 cacert.pem 到 overcloud 节点
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m copy -a 'src=/home/stack/cacert.pem dest=/etc/pki/ca-trust/source/anchors'
(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m shell -a 'cmd="update-ca-trust extract"'

# 生成模版文件 neutron-port
(undercloud) [stack@undercloud ~]$ cat > ~/templates/neutron-port.yaml <<'EOF'
resource_registry:
  OS::TripleO::DeployedServer::ControlPlanePort: /usr/share/openstack-tripleo-heat-templates/deployed-server/deployed-neutron-port.yaml
  OS::TripleO::Network::Ports::RedisVipPort: /usr/share/openstack-tripleo-heat-templates/network/ports/noop.yaml
  OS::TripleO::Network::Ports::OVNDBsVipPort: /usr/share/openstack-tripleo-heat-templates/network/ports/noop.yaml

parameter_defaults:
  DeployedServerPortMap:
    control_virtual_ip:
      fixed_ips:
        - ip_address: 192.0.2.240
      subnets:
        - cidr: 24
    controller-0-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.51
      subnets:
        - cidr: 24
    controller-1-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.52
      subnets:
        - cidr: 24
    controller-2-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2..53
      subnets:
        - cidr: 24
    computehci-0-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.71
      subnets:
        - cidr: 24
    computehci-1-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.72
      subnets:
        - cidr: 24
    computehci-2-ctlplane:
      fixed_ips:
        - ip_address: 192.0.2.73
      subnets:
        - cidr: 24
EOF

# 生成模版文件
(undercloud) [stack@undercloud ~]$ cat > ~/templates/tls-parameters.yaml <<'EOF'
resource_registry:
  OS::TripleO::Services::IpaClient: /usr/share/openstack-tripleo-heat-templates/deployment/ipa/ipaservices-baremetal-ansible.yaml
parameter_defaults:
  IdMServer: helper.example.com
  IdMDomain: example.com
  IdMInstallClientPackages: True
EOF


生成部署脚本
(undercloud) [stack@undercloud ~]$ cat > ~/deploy-tls-everywhere-preprovion.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug \
--disable-validations \
--overcloud-ssh-user stack \
--templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/deployed-server-environment.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible.yaml \
-e $THT/environments/ceph-ansible/ceph-rgw.yaml \
-e $THT/environments/ssl/enable-internal-tls.yaml \
-e $THT/environments/ssl/tls-everywhere-endpoints-dns.yaml \
-e $THT/environments/services/haproxy-public-tls-certmonger.yaml \
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
-e $CNF/tls-parameters.yaml \
-e $CNF/neutron-port.yaml \
-e $CNF/cephstorage.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF
```