
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

# 更改 /etc/haproxy/haproxy.conf 的配置

# 在 ipv6 地址上监听 
listen stats
    bind :9000
    bind :::9000
    mode http
    stats enable
    stats uri /
    monitor-uri /healthz

# 修改 frontend openshift-api-server 适配 ipv6
frontend openshift-api-server
    bind :::6443
    acl worker src 2001:db8::16 2001:db8::17 2001:db8::18
    use_backend openshift-api-server-on-master if worker
    default_backend openshift-api-server
    mode tcp
    option tcplog

# 修改 backend openshift-api-server-on-master 适配 ipv6
backend openshift-api-server-on-master
    balance source
    mode tcp
    server master1 2001:db8::13:6443 check
    server master2 2001:db8::14:6443 check
    server master3 2001:db8::15:6443 check

# 修改 backend openshift-api-server 适配 ipv6
backend openshift-api-server
    balance source
    mode tcp
    server bootstrap 2001:db8::12:6443 check
    server master1 2001:db8::13:6443 check
    server master2 2001:db8::14:6443 check
    server master3 2001:db8::15:6443 check

# 修改 frontend machine-config-server 适配 ipv6
frontend machine-config-server
    bind :::22623
    acl worker src 2001:db8::16 2001:db8::17 2001:db8::18
    use_backend machine-config-server-on-master if worker
    default_backend machine-config-server
    mode tcp
    option tcplog

# 修改 backend machine-config-server-on-master 适配 ipv6
backend machine-config-server-on-master
    balance source
    mode tcp
    server master1 2001:db8::13:22623 check
    server master2 2001:db8::14:22623 check
    server master3 2001:db8::15:22623 check

# 修改 backend machine-config-server 适配 ipv6
backend machine-config-server
    balance source
    mode tcp
    server bootstrap 2001:db8::12:22623 check
    server master1 2001:db8::13:22623 check
    server master2 2001:db8::14:22623 check
    server master3 2001:db8::15:22623 check

# 修改 frontend ingress-http 适配 ipv6
frontend ingress-http
    bind :::80
    default_backend ingress-http
    mode tcp
    option tcplog

# 修改 backend ingress-http 适配 ipv6
backend ingress-http
    balance source
    mode tcp
    server master1-http-router1 2001:db8::13:80 check
    server master2-http-router2 2001:db8::14:80 check
    server master3-http-router3 2001:db8::15:80 check
    server worker1-http-router1 2001:db8::16:80 check
    server worker2-http-router2 2001:db8::17:80 check
    server worker3-http-router3 2001:db8::18:80 check

 # 修改 frontend ingress-https 适配 ipv6
 frontend ingress-https
    bind :::443
    default_backend ingress-https
    mode tcp
    option tcplog

# 修改 backend ingress-https 适配 ipv6
backend ingress-https
    balance source
    mode tcp
    server master1-https-router1 2001:db8::13:443 check
    server master2-https-router2 2001:db8::14:443 check
    server master3-https-router3 2001:db8::15:443 check
    server worker1-https-router1 2001:db8::16:443 check
    server worker2-https-router2 2001:db8::17:443 check
    server worker3-https-router3 2001:db8::18:443 check


# 登录 Hypervisor 生成光盘

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

# 4.5 以上版本需要执行
guestfish -a ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-live.x86_64.iso \
  -m /dev/sda tar-out / - | tar xvf -

# Helper function to modify the config files
modify_cfg(){
  for file in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    # Append the proper image and ignition urls
    sed -e '/coreos.inst=yes/s|$| coreos.inst.install_dev=vda coreos.inst.image_url='"${URL}"'\/install\/'"${BIOSMODE}"'.raw.gz coreos.inst.ignition_url='"${URL}"'\/ignition\/'"${NODE}"'.ign ip='"${IP}"'::'"${GATEWAY}"':'"${NETMASK}"':'"${FQDN}"':'"${NET_INTERFACE}"':none:'"${DNS}"' nameserver='"${DNS}"'|' ${file} > $(pwd)/${NODE}_${file##*/}
    # Boot directly in the installation
    sed -i -e 's/default vesamenu.c32/default linux/g' -e 's/timeout 600/timeout 10/g' $(pwd)/${NODE}_${file##*/}
  done
}

# 4.5 以上版本
modify_cfg(){
  for file in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    # Append the proper image and ignition urls
    sed -e '/ignition.platform.id=metal/s|$| coreos.inst.install_dev=vda coreos.inst.ignition_url='"${URL}"'\/ignition\/'"${NODE}"'.ign ip='"${IP}"'::'"${GATEWAY}"':'"${NETMASK}"':'"${FQDN}"':'"${NET_INTERFACE}"':none:'"${DNS}"' nameserver='"${DNS}"'|' ${file} > $(pwd)/${NODE}_${file##*/}
    # Boot directly in the installation
    sed -i -e 's/default vesamenu.c32/default linux/g' -e 's/timeout 600/timeout 10/g' $(pwd)/${NODE}_${file##*/}
  done
}

URL="http://[2001:db8::11]:8080/"
GATEWAY="[2001:db8::11]"
NETMASK="64"
DNS="[2001:db8::11]"

# BOOTSTRAP
# TYPE="bootstrap"
NODE="bootstrap-static"
IP="[2001:db8::12]"
FQDN="bootstrap.ocp4.example.com"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTERS
# TYPE="master"
# MASTER-0
NODE="master-0"
IP="[2001:db8::13]"
FQDN="master1.ocp4.example.com"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTER-1
NODE="master-1"
IP="[2001:db8::14]"
FQDN="master2.ocp4.example.com"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# MASTER-2
NODE="master-2"
IP="[2001:db8::15]"
FQDN="master3.ocp4.example.com"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# WORKERS
NODE="worker-0"
IP="[2001:db8::16]"
FQDN="worker1.ocp4.example.com"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="worker-1"
IP="[2001:db8::17]"
FQDN="worker2.ocp4.example.com"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

NODE="worker-2"
IP="[2001:db8::18]"
FQDN="worker3.ocp4.example.com"
BIOSMODE="bios"
NET_INTERFACE="ens3"
modify_cfg

# Generate the images, one per node as the IP configuration is different...
# https://github.com/coreos/coreos-assembler/blob/master/src/cmd-buildextend-installer#L97-L103
for node in master-0 master-1 master-2 worker-0 worker-1 worker-2 bootstrap-static; do
  # Overwrite the grub.cfg and isolinux.cfg files for each node type
  for file in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    /bin/cp -f $(pwd)/${node}_${file##*/} ${file}
  done
  # As regular user!
  genisoimage -verbose -rock -J -joliet-long -volset ${VOLID} \
    -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -efi-boot images/efiboot.img -no-emul-boot \
    -o ${NGINX_DIRECTORY}/${node}.iso .
done

# 4.5 以上版本需要用添加 genisoimage 参数 -V ${VOLID}
for node in master-0 master-1 master-2 worker-0 worker-1 worker-2 bootstrap-static; do
  # Overwrite the grub.cfg and isolinux.cfg files for each node type
  for file in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    /bin/cp -f $(pwd)/${node}_${file##*/} ${file}
  done
  # As regular user!
  genisoimage -verbose -rock -J -joliet-long -V ${VOLID} -volset ${VOLID} \
    -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -efi-boot images/efiboot.img -no-emul-boot \
    -o ${NGINX_DIRECTORY}/${node}.iso .
done

# Optionally, clean up
cd
rm -Rf ${TEMPDIR}

# 登录 Helper
mkdir -p /root/ocp4/ins452
cd /root/ocp4/ins452

cat > install-config.yaml.ipv6 << 'EOF'
apiVersion: v1
baseDomain: example.com
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  name: ocp4
networking:
  machineCIDR: 2001:0DB8::/64
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: fd01::/48
    hostPrefix: 64
  serviceNetwork:
  - fd02::/112
platform:
  none: {}
pullSecret: '{"auths":{"registry.ocp4.example.com:5443":{"auth":"YTph"}}}'
sshKey: |
$( cat /root/.ssh/id_rsa.pub | sed 's/^/  /g' )
additionalTrustBundle: |
$( cat /etc/pki/ca-trust/source/anchors/ocp4.example.com.crt | sed 's/^/  /g' )
imageContentSources:
- mirrors:
  - registry.ocp4.example.com:5443/openshift-release-dev/ocp-release
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - registry.ocp4.example.com:5443/openshift-release-dev/ocp-release
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

cp install-config.yaml.ipv6 install-config.yaml

# 生成 ingition 文件 
openshift-install create ignition-configs --dir=/root/ocp4/ins452

mkdir -p template_vm/etc/sysconfig/network-scripts/
touch template_vm/etc/sysconfig/network-scripts/ifcfg-ens3

# dual stack
cat <<EOF > template_vm/etc/sysconfig/network-scripts/ifcfg-ens3
TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
BOOTPROTO="none"
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_FAILURE_FATAL="no"
IPV6_ADDR_GEN_MODE="stable-privacy"
NAME="ens3"
DEVICE="ens3"
ONBOOT="yes"
IPADDR="changemeipaddr"
PREFIX="24"
GATEWAY="192.168.8.1"
IPV6_PRIVACY="no"
DNS1=2001:db8::11
IPV6ADDR=changemeipv6/64
IPV6_DEFAULTGW=2001:db8::11
DOMAIN=ocp4.example.com
EOF

# single stack ipv6
cat <<EOF > template_vm/etc/sysconfig/network-scripts/ifcfg-ens3
TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
BOOTPROTO="none"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_FAILURE_FATAL="no"
IPV6_ADDR_GEN_MODE="stable-privacy"
NAME="ens3"
DEVICE="ens3"
ONBOOT="yes"
IPV6_PRIVACY="no"
DNS1=2001:db8::11
IPV6ADDR=changemeipv6/64
IPV6_DEFAULTGW=2001:db8::11
DOMAIN=ocp4.example.com
EOF

# 生成7台虚拟机的网卡配置.
cp -r template_vm bootstrap
sed -i 's/changemeipaddr/192.168.8.12/g' bootstrap/etc/sysconfig/network-scripts/ifcfg-ens3
sed -i 's/changemeipv6/2001:0DB8:0000:0000:0000:0000:0000:0012/g' bootstrap/etc/sysconfig/network-scripts/ifcfg-ens3

cp -r template_vm master-0
sed -i 's/changemeipaddr/192.168.8.13/g' master-0/etc/sysconfig/network-scripts/ifcfg-ens3
sed -i 's/changemeipv6/2001:0DB8:0000:0000:0000:0000:0000:0013/g' master-0/etc/sysconfig/network-scripts/ifcfg-ens3

cp -r template_vm master-1
sed -i 's/changemeipaddr/192.168.8.14/g' master-1/etc/sysconfig/network-scripts/ifcfg-ens3
sed -i 's/changemeipv6/2001:0DB8:0000:0000:0000:0000:0000:0014/g' master-1/etc/sysconfig/network-scripts/ifcfg-ens3

cp -r template_vm master-2
sed -i 's/changemeipaddr/192.168.8.15/g' master-2/etc/sysconfig/network-scripts/ifcfg-ens3
sed -i 's/changemeipv6/2001:0DB8:0000:0000:0000:0000:0000:0015/g' master-2/etc/sysconfig/network-scripts/ifcfg-ens3

cp -r template_vm worker-0
sed -i 's/changemeipaddr/192.168.8.16/g' worker-0/etc/sysconfig/network-scripts/ifcfg-ens3
sed -i 's/changemeipv6/2001:0DB8:0000:0000:0000:0000:0000:0016/g' worker-0/etc/sysconfig/network-scripts/ifcfg-ens3

cp -r template_vm worker-1
sed -i 's/changemeipaddr/192.168.8.17/g' worker-1/etc/sysconfig/network-scripts/ifcfg-ens3
sed -i 's/changemeipv6/2001:0DB8:0000:0000:0000:0000:0000:0017/g' worker-1/etc/sysconfig/network-scripts/ifcfg-ens3

cp -r template_vm worker-2
sed -i 's/changemeipaddr/192.168.8.18/g' worker-2/etc/sysconfig/network-scripts/ifcfg-ens3
sed -i 's/changemeipv6/2001:0DB8:0000:0000:0000:0000:0000:0018/g' worker-2/etc/sysconfig/network-scripts/ifcfg-ens3

# 生成 ignition 文件
filetranspiler -i bootstrap.ign -f bootstrap -o bootstrap-static.ign
filetranspiler -i master.ign -f master-0 -o master-0.ign
filetranspiler -i master.ign -f master-1 -o master-1.ign
filetranspiler -i master.ign -f master-2 -o master-2.ign
filetranspiler -i worker.ign -f worker-0 -o worker-0.ign
filetranspiler -i worker.ign -f worker-1 -o worker-1.ign
filetranspiler -i worker.ign -f worker-2 -o worker-2.ign

# 拷贝生成的 ignition 文件到 /var/www/html/ignition 目录下
echo y | cp bootstrap-static.ign /var/www/html/ignition/bootstrap-static.ign 
echo y | cp master-0.ign /var/www/html/ignition/master-0.ign
echo y | cp master-1.ign /var/www/html/ignition/master-1.ign
echo y | cp master-2.ign /var/www/html/ignition/master-2.ign
echo y | cp worker-0.ign /var/www/html/ignition/worker-0.ign
echo y | cp worker-1.ign /var/www/html/ignition/worker-1.ign
echo y | cp worker-2.ign /var/www/html/ignition/worker-2.ign


# 拷贝 ignition 文件
rm -f /var/www/html/ignition/*
/bin/cp -f bootstrap.ign /var/www/html/ignition/bootstrap-static.ign
/bin/cp -f master.ign /var/www/html/ignition/master-0.ign
/bin/cp -f master.ign /var/www/html/ignition/master-1.ign
/bin/cp -f master.ign /var/www/html/ignition/master-2.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-0.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-1.ign
/bin/cp -f worker.ign /var/www/html/ignition/worker-2.ign
chmod 644 /var/www/html/ignition/*

# finally, we can start install :)
# 你可以一口气把虚拟机都创建了，然后喝咖啡等着。
# 从这一步开始，到安装完毕，大概30分钟。
virt-install --name=jwang-ocp452-bootstrap --vcpus=4 --ram=8192 \
--disk path=/data/kvm/jwang-ocp452-bootstrap.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/bootstrap-static.iso 

# 想登录进coreos一探究竟？那么这么做
# ssh core@[2001:db8::12] 
# journalctl -b -f -u bootkube.service

virt-install --name=jwang-ocp452-master0 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-ocp452-master0.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-0.iso 

virt-install --name=jwang-ocp452-master1 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-ocp452-master1.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-1.iso 

virt-install --name=jwang-ocp452-master2 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-ocp452-master2.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/master-2.iso 

virt-install --name=jwang-ocp452-worker0 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-ocp452-worker0.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/worker-0.iso 

virt-install --name=jwang-ocp452-worker1 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-ocp452-worker1.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/worker-1.iso 

virt-install --name=jwang-ocp452-worker2 --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-ocp452-worker2.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --cdrom ${NGINX_DIRECTORY}/worker-2.iso 

# 停止虚拟机
for vm in bootstrap master0 master1 master2 worker0 worker1 worker2 
do
  virsh destroy jwang-ocp452-${vm}
done

# 清理磁盘
qemu-img create -f qcow2 /data/kvm/jwang-ocp452-bootstrap.qcow2 120G
qemu-img create -f qcow2 /data/kvm/jwang-ocp452-master0.qcow2 120G
qemu-img create -f qcow2 /data/kvm/jwang-ocp452-master1.qcow2 120G
qemu-img create -f qcow2 /data/kvm/jwang-ocp452-master2.qcow2 120G
qemu-img create -f qcow2 /data/kvm/jwang-ocp452-worker0.qcow2 120G
qemu-img create -f qcow2 /data/kvm/jwang-ocp452-worker1.qcow2 120G
qemu-img create -f qcow2 /data/kvm/jwang-ocp452-worker2.qcow2 120G

# 启动虚拟机
for vm in bootstrap master0 master1 master2 worker0 worker1 worker2 
do
  virsh start jwang-ocp452-${vm}
done

# single stack 在 ocp 4.5.2 上不工作
# 参见如下报错
[core@bootstrap ~]$ sudo podman login registry.ocp4.example.com:5443
Authenticating with existing credentials...
Existing credentials are invalid, please enter valid username and password
Username (a): a
Password: 
Error: error authenticating creds for "registry.ocp4.example.com:5443": error pinging docker registry registry.ocp4.example.com:5443: Get https://registry.ocp4.example.com:5443/v2/: dial tcp 192.168.7.11:5443: connect: network is unreachable


# 不清楚为什么需要在所有 master 和 worker 节点上手工登录虚拟机执行以下命令
sudo nmcli c s ens3 | grep dns
sudo nmcli c mod ens3 ipv6.ignore-auto-dns 'yes'
sudo nmcli c down ens3 && sudo nmcli c up ens3

# clusteroperator kube-apiserver 和 openshift-apiserver 处于降级状态
kube-apiserver                             4.5.2     True        False         True       24m
openshift-apiserver                        4.5.2     True        False         True       18m

# kube-apiserver 有如下报错
oc -n openshift-kube-apiserver-operator logs $(oc get pods -n openshift-kube-apiserver-operator -o jsonpath='{ .items[*].metadata.name }')
...
E0106 14:40:24.087292       1 base_controller.go:180] "ConfigObserver" controller failed to sync "key", err: configmaps openshift-etcd/etcd-endpoints: no etcd endpoint addresses found

# configmaps openshift-etcd/etcd-endpoints 的内容为
oc -n openshift-etcd get configmaps etcd-endpoints -o json 

{
    "apiVersion": "v1",
    "data": {
        "MjAwMTpkYjg6OjE0": "2001:db8::14",
        "MjAwMTpkYjg6OjE1": "2001:db8::15",
        "MjAwMTpkYjg6OjEz": "2001:db8::13"
    },
...

# Endpoint 的 data 是 ipv6 地址

# Patch configmaps etcd-endpoints, patch 之后并未生效，应该有 controller 控制这个 configmaps
oc -n openshift-etcd patch configmaps etcd-endpoints --type json -p '[{"op": "replace", "path": "/data/MjAwMTpkYjg6OjE0", "value": "2001:0DB8:0000:0000:0000:0000:0000:0014"}]'
oc -n openshift-etcd patch configmaps etcd-endpoints --type json -p '[{"op": "replace", "path": "/data/MjAwMTpkYjg6OjE1", "value": "2001:0DB8:0000:0000:0000:0000:0000:0015"}]'
oc -n openshift-etcd patch configmaps etcd-endpoints --type json -p '[{"op": "replace", "path": "/data/MjAwMTpkYjg6OjEz", "value": "2001:0DB8:0000:0000:0000:0000:0000:0013"}]'

# 生成 ISO
export MAJORBUILDNUMBER=4.6
export EXTRABUILDNUMBER=4.6.8
mkdir -p /data/ocp4/${EXTRABUILDNUMBER}

wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${MAJORBUILDNUMBER}/${EXTRABUILDNUMBER}/rhcos-${EXTRABUILDNUMBER}-x86_64-live.x86_64.iso -P /data/ocp4/${EXTRABUILDNUMBER}


export NGINX_DIRECTORY=/data/ocp4/${EXTRABUILDNUMBER}
export RHCOSVERSION=4.6.8
export VOLID=$(isoinfo -d -i ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-live.x86_64.iso | awk '/Volume id/ { print $3 }')

TEMPDIR=$(mktemp -d)
echo $VOLID
echo $TEMPDIR

cd ${TEMPDIR}
guestfish -a ${NGINX_DIRECTORY}/rhcos-${RHCOSVERSION}-x86_64-live.x86_64.iso \
  -m /dev/sda tar-out / - | tar xvf -


# 4.5 以上版本需要用添加 genisoimage 参数 -V ${VOLID}
for node in master-0 master-1 master-2 worker-0 worker-1 worker-2 bootstrap-static; do
  # Overwrite the grub.cfg and isolinux.cfg files for each node type
  for file in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    /bin/cp -f $(pwd)/${node}_${file##*/} ${file}
  done
  # As regular user!
  genisoimage -verbose -rock -J -joliet-long -V ${VOLID} -volset ${VOLID} \
    -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -efi-boot images/efiboot.img -no-emul-boot \
    -o ${NGINX_DIRECTORY}/${node}.iso .
done


# 4.6.8 live iso 的 启动参数
### BEGIN /etc/grub.d/10_linux ###
menuentry 'RHEL CoreOS (Live)' --class fedora --class gnu-linux --class gnu --class os {
        linux /images/pxeboot/vmlinuz random.trust_cpu=on rd.luks.options=discard coreos.liveiso=rhcos-46.82.202012051820-0 ignition.firstboot ignition.platform.id=metal
        initrd /images/pxeboot/initrd.img /images/ignition.img
}
```