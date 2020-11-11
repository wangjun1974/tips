
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

# 安装 helper 虚拟机
virt-install --name="jwang-ocp452-aHelper" --vcpus=2 --ram=4096 \
--disk path=/data/kvm/jwang-ocp452-aHelper.qcow2,bus=virtio,size=800 \
--os-variant centos7.0 --network network=openshift4,model=virtio \
--boot menu=on --location /data/rhel-server-7.6-x86_64-dvd.iso \
--initrd-inject /tmp/helper-ks.cfg --extra-args "inst.ks=file:/tmp/helper-ks.cfg" \
--graphics none \
--console pty,target_type=serial --extra-args='console=ttyS0'



```