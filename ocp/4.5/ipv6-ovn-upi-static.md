
# 参考： https://jamielinux.com/docs/libvirt-networking-handbook/nat-based-network.html


```
# 生成 /tmp/helper-ks.cfg 文件
cat > /tmp/helper-ks.cfg << 'EOF'
#version=RHEL7
ignoredisk --only-use=sda

# Partition clearing information
clearpart --all

# Use text install
text

# System language
lang en_US.UTF-8

# Keyboard layouts
keyboard us

# Network information
network --bootproto=static --device=eth0 --ip=192.168.122.122 --netmask 255.255.255.0 --gateway=192.168.122.1 --hostname=

# Root password
rootpw --iscrypted $6$q9HNZaOm8rO91oRR$eSWRwR7Hc9FBRlcEm83EiJx8MeFUQJXd.33YVDjzXkgCTiY3gcMHOvDtI6wh35Zw9.7Ql6rAo9tEZpo3y7Uy6/

# Run the Setup Agent on first boot
firstboot --enable

# Do not configure the X Window System
skipx

# System timezone
timezone Asia/Shanghai --isUtc

# Agree EULA
eula --agreed

# System services
services --enabled=NetworkManager,sshd

# Reboot after installation completes
reboot

# Disk partitioning information
autopart --type=lvm --fstype=xfs

%packages --nobase --ignoremissing --excludedocs
@core
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
EOF

# 拷贝老的 helper 虚拟机磁盘
rsync --info=progress2 /var/lib/libvirt/images/helper-sda /data/kvm/jwang-ocp452-aHelper.qcow2

# 创建新的 libvirt network openshift4v6
cat << EOF >  /data/virt-net-v6.xml
<network>
  <name>openshift4v6</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='openshift4v6' stp='on' delay='0'/>
  <domain name='openshift4v6'/>
  <ip address='192.168.8.1' netmask='255.255.255.0'>
  </ip> 
  <ip family="ipv6" address="2001:db8::1" prefix="64">
  </ip>
</network>
EOF

virsh net-define /data/virt-net-v6.xml
virsh net-start openshift4v6
virsh net-autostart --network openshift4v6

# 安装 helper 虚拟机
virt-install --import --name="jwang-ocp452-aHelper" --vcpus=2 --ram=4096 \
--disk path=/data/kvm/jwang-ocp452-aHelper.qcow2,bus=virtio \
--os-variant centos7.0 --network network=openshift4v6,model=virtio \
--graphics spice \
--noautoconsole

# 登录虚拟机 jwang-ocp452-aHelper，改变虚拟机 ip 地址
nmcli con mod 'ocp4' ipv4.method 'manual' ipv4.address '192.168.8.11/24' ipv4.gateway '192.168.8.1' 
nmcli con down ocp4 && nmcli con up ocp4 


# 下载所需软件
export MAJORBUILDNUMBER=4.5
export EXTRABUILDNUMBER=4.5.2
mkdir -p /data/ocp4/${EXTRABUILDNUMBER}

wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${MAJORBUILDNUMBER}/${EXTRABUILDNUMBER}/rhcos-${EXTRABUILDNUMBER}-x86_64-installer.x86_64.iso -P /data/ocp4/${EXTRABUILDNUMBER}
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${MAJORBUILDNUMBER}/${EXTRABUILDNUMBER}/rhcos-${EXTRABUILDNUMBER}-x86_64-metal.x86_64.raw.gz -P /data/ocp4/${EXTRABUILDNUMBER}

# 参考 https://github.com/wangzheng422/docker_env/blob/master/redhat/ocp4/4.5/4.5.disconnect.operator.md 制作启动光盘

export NGINX_DIRECTORY=/data/ocp4/${EXTRABUILDNUMBER}
export RHCOSVERSION=4.5.2
export VOLID=$(isoinfo -d -i ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-installer.x86_64.iso | awk '/Volume id/ { print $3 }')

TEMPDIR=$(mktemp -d)
echo $VOLID
echo $TEMPDIR

cd ${TEMPDIR}
# Extract the ISO content using guestfish (to avoid sudo mount)
guestfish -a ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-installer.x86_64.iso \
  -m /dev/sda tar-out / - | tar xvf -






```