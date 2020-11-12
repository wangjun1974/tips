
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
nmcli con mod 'ocp4' ipv6.method 'manual' ipv6.address '2001:db8::11/64' ipv6.gateway '2001:db8::1'
nmcli con down ocp4 && nmcli con up ocp4 

cat >> /etc/hosts <<EOF
2001:db8::11 helper.ocp4.example.com helper
2001:db8::1 yum.redhat.ren
EOF

# 按照正常方法准备 ocp4-helpernode 或者 ocp4-upi-helpernode

# 添加以下内容到 /etc/named.conf 文件
# 这里使用的网络是 2001:db8::1/64 
# 对应的网络前缀是 2001:0db8:0000
# 参考: http://www.gestioip.net/cgi-bin/subnet_calculator.cgi

zone "0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa." IN {
        type    master;
        file    "0000.0db8.2001.reverse.db";
};      

# 创建 0000.0db8.2001.reverse.db 文件
cat > /var/named/0000.0db8.2001.reverse.db <<'EOF'
$TTL 1W
@       IN      SOA     ns1.ocp4.example.com.   root (
                        2020010747      ; serial
                        3H              ; refresh (3 hours)
                        30M             ; retry (30 minutes)
                        2W              ; expiry (2 weeks)
                        1W )            ; minimum (1 week)
        IN      NS      ns1.ocp4.example.com.
;
; syntax is "last octet" and the host must have fqdn with trailing dot
;
$ORIGIN 0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa.
;
1.3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0       IN      PTR     master1.ocp4.example.com.
1.4.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0       IN      PTR     master2.ocp4.example.com.
1.4.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0       IN      PTR     master3.ocp4.example.com.
;
1.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0       IN      PTR     registry.ocp4.example.com.
;
1.2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0       IN      PTR     bootstrap.ocp4.example.com.
;
1.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0       IN      PTR     api.ocp4.example.com.
1.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0       IN      PTR     api-int.ocp4.example.com.
;
1.6.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0       IN      PTR     worker1.ocp4.example.com.
1.7.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0       IN      PTR     worker2.ocp4.example.com.
1.8.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0       IN      PTR     worker3.ocp4.example.com.
;
EOF

# 添加 ipv6 正向解析到 /var/named/zonefile.db

;IPv6 part
ns1     IN      AAAA       2001:db8::11
smtp    IN      AAAA       2001:db8::11
;
helper  IN      AAAA       2001:db8::11
;
; The api points to the IP of your load balancer
api             IN      AAAA       2001:db8::11
api-int         IN      AAAA       2001:db8::11
;
; The wildcard also points to the load balancer
*.apps          IN      AAAA       2001:db8::11
;
; Create entry for the private registry
registry        IN      AAAA       2001:db8::11
;
; Create entry for the bootstrap host
bootstrap       IN      AAAA       2001:db8::12
;
; Create entries for the master hosts
master1         IN      AAAA       2001:db8::13
master2         IN      AAAA       2001:db8::14
master3         IN      AAAA       2001:db8::15
;
; Create entries for the worker hosts
worker1         IN      AAAA       2001:db8::16
worker2         IN      AAAA       2001:db8::17
worker3         IN      AAAA       2001:db8::18
;
; The ETCd cluster lives on the masters...so point these to the IP of the masters
etcd-0  IN      AAAA       2001:db8::13
etcd-1  IN      AAAA       2001:db8::14
etcd-2  IN      AAAA       2001:db8::15


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