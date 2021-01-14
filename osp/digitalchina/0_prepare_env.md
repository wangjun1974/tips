### 在物理机里安装 osp 时做的准备工作

1. 配置并且记录 IPMI 信息

在硬件上配置并且记录 IPMI 的 IP，端口，用户名及口令

|节点|IPMI地址|用户名|口令|
|---|---|---|---|
|controller0|192.168.1.10|admin|password|
|controller1|192.168.1.11|admin|password|
|controller2|192.168.1.12|admin|password|
|compute0|192.168.1.13|admin|password|
|compute1|192.168.1.14|admin|password|
|compute2|192.168.1.15|admin|password|
|cephstorage0|192.168.1.16|admin|password|
|cephstorage1|192.168.1.17|admin|password|
|cephstorage2|192.168.1.18|admin|password|

2. 配置交换机
以下网络是 OpenStack 会使用到的内部网络

需要明确以下问题：
* osp 集群对应几个交换机
* 每个网络所在的交换机是什么，是否共用交换机
* 每个网络在服务器这边对应哪个或哪几个网口

以下是一个例子

|名字|vlan|网段|备注说明|对应服务器网口|
|---|---|---|---|---|
|ControlPlane|无|192.0.2.0/24|部署网络|网口1|
|External|10|10.0.0.0/24|overcloud 的 External API 和 floating ip 所在的网络|网口2和网口3|
|InternalAPI|20|172.16.2.0/24|overcloud 的 Internal API 所在的网络|网口2和网口3|
|Tenant|50|172.16.0.0/24|overcloud 租户 overlay 隧道所在的网络|网口2和网口3|
|Storage|30|172.16.1.0/24|overcloud 存储网络，内部客户端通过此网络访问存储|网口2和网口3|
|StorageMgmt|40|172.16.3.0/24|overcloud 内部存储管理网络|网口2和网口3|

### 在虚拟机里安装 osp 时做的准备工作

硬件准备：定义虚拟交换机
```
# 定义 provisioning 虚拟网络
cat > /tmp/provisioning.xml <<EOF
<network>
  <name>provisioning</name>
  <ip address="192.0.2.254" netmask="255.255.255.0"/>
</network>
EOF

virsh net-define /tmp/provisioning.xml
virsh net-autostart provisioning
virsh net-start provisioning

# 根据需要禁用虚拟网络的 DHCP，以下是在虚拟网络 default 上，禁止 DHCP 时的例子 
if(virsh net-dumpxml default | grep dhcp &>/dev/null); then
      virsh net-update default delete ip-dhcp-range "<range start='192.168.122.2' end='192.168.122.254'/>" --live --config || { echo "Unable to disable DHCP on default network"; return 1; }
fi


```

硬件准备：创建虚拟机磁盘
```
# 定义环境变量
LIBVIRT_D="/data/kvm"
CTRL_N="ctrl01 ctrl02 ctrl03"
COMPT_N="compute01 compute02"
CEPH_N="ceph01 ceph02 ceph03"
ALL_N="$CTRL_N $COMPT_N $CEPH_N"
OVERCLOUD_DISK_SIZE='100'
CEPH_OSD_DISK=3
CEPH_OSD_DISK_SIZE='100'

cd ${LIBVIRT_D}/

for i in $ALL_N;
do
  echo "Creating a ${OVERCLOUD_DISK_SIZE}GB disk image for node $i..."
  qemu-img create -f qcow2 -o preallocation=metadata jwang-overcloud-$i.qcow2 ${OVERCLOUD_DISK_SIZE}G || { echo "Unable to define disk jwang-overcloud-$i.qcow2"; return 1; }
done

for i in $CEPH_N;
do
    echo "Creating additional disk's image(s) for node $i..."
    for((n=1;n<=$CEPH_OSD_DISK;n+=1)); do
      echo "Creating additional ${CEPH_OSD_DISK_SIZE}GB disk $n - ${LIBVIRT_D}/jwang-overcloud-${i}-storage-${n}.qcow2"
    qemu-img create -f qcow2 -o preallocation=metadata jwang-overcloud-${i}-storage-${n}.qcow2 ${CEPH_OSD_DISK_SIZE}G || { echo "Unable to define disk jwang-overcloud-$i-storage-${n}.qcow2"; return 1; }
    done
    echo
done


```

定义控制节点虚拟机
```
# 定义环境变量
CTRL_N="ctrl01 ctrl02 ctrl03"
CTRL_MEM='12288'
CTRL_VCPU='4'
LIBVIRT_D="/data/kvm"

# 创建控制节点虚拟机
for i in $CTRL_N;
do
    echo "Defining node jwang-overcloud-$i..."
    virt-install --ram $CTRL_MEM --vcpus $CTRL_VCPU --os-variant rhel7 \
    --disk path=${LIBVIRT_D}/jwang-overcloud-$i.qcow2,device=disk,bus=virtio,format=qcow2 \
    --noautoconsole --vnc --network network:provisioning \
    --network network:default --network network:default \
    --name jwang-overcloud-$i \
    --cpu SandyBridge,+vmx \
    --dry-run --print-xml > /tmp/jwang-overcloud-$i.xml;

    virsh define --file /tmp/jwang-overcloud-$i.xml || { echo "Unable to define jwang-overcloud-$i"; return 1; }
done

```

定义计算节点虚拟机
```
# 定义环境变量
COMPT_N="compute01 compute02"
COMPT_MEM='6144'
COMPT_VCPU='4'
LIBVIRT_D="/data/kvm"

# 创建计算节点虚拟机
for i in $COMPT_N;
do
    echo "Defining node jwang-overcloud-$i..."
    virt-install --ram $COMPT_MEM --vcpus $CTRL_VCPU --os-variant rhel7 \
    --disk path=${LIBVIRT_D}/jwang-overcloud-$i.qcow2,device=disk,bus=virtio,format=qcow2 \
    --noautoconsole --vnc --network network:provisioning \
    --network network:default --network network:default \
    --name jwang-overcloud-$i \
    --cpu SandyBridge,+vmx \
    --dry-run --print-xml > /tmp/jwang-overcloud-$i.xml;

    virsh define --file /tmp/jwang-overcloud-$i.xml || { echo "Unable to define jwang-overcloud-$i"; return 1; }
done

```

定义存储节点虚拟机
```
CEPH_N="ceph01 ceph02 ceph03"
CEPH_MEM='4096'
CEPH_VCPU='4'
LIBVIRT_D='/data/kvm'
CEPH_OSD_DISK=3

for i in $CEPH_N;
do
    echo "Defining node jwang-overcloud-$i..."
    virt-install --ram $CEPH_MEM --vcpus $CEPH_VCPU --os-variant rhel7 \
    --disk path=${LIBVIRT_D}/jwang-overcloud-$i.qcow2,device=disk,bus=virtio,format=qcow2 \
    $(for((n=1;n<=$CEPH_OSD_DISK;n+=1)); do echo -n "--disk path=${LIBVIRT_D}/jwang-overcloud-$i-storage-${n}.qcow2,device=disk,bus=virtio,format=qcow2 "; done) \
    --noautoconsole --vnc --network network:provisioning \
    --network network:default --network network:default \
    --name jwang-overcloud-$i \
    --cpu SandyBridge,+vmx \
    --dry-run --print-xml > /tmp/jwang-overcloud-$i.xml

    virsh define --file /tmp/jwang-overcloud-$i.xml || { echo "Unable to define jwang-overcloud-$i"; return 1; }
done
```


```
# 在 Hypervisor 上配置加载 dummy 内核模块
echo dummy > /etc/modules-load.d/dummy.conf
modprobe dummy

# 生成 ifcfg-dummy0 
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-dummy0
DEVICE=dummy0
ONBOOT=yes
NM_CONTROLLED="no"
IPADDR=192.168.1.1
PREFIX=24
$(for ((i=2;i<=20;i++)); do
echo IPADDR${i}=192.168.1.${i}
echo PREFIX${i}=24
done)
EOF

# 启动 dummy0
ifup dummy0

# 如果 Hypervisor 配置了 FirewallD
firewall-cmd --add-port=3128/tcp
firewall-cmd --permanent --add-port=3128/tcp

firewall-cmd --add-port=623/tcp
firewall-cmd --permanent --add-port=623/tcp

# 如果 Hypervisor 配置了 iptables
iptables -I INPUT 1 -m tcp -p tcp --dport 3128 -j ACCEPT
iptables -I INPUT 1 -m tcp -p tcp --dport 623 -j ACCEPT

# RHEL7 Hypervisor 安装 vbmc 和 ipmitool 软件包
yum install -y python2-virtualbmc ipmitool

# 配置 vbmc 
echo "Creating VirtualBMC systemd unit file"
cat << EOF > /usr/lib/systemd/system/virtualbmc@.service
[Unit]
Description=VirtualBMC %i service
After=network.target libvirtd.service

[Service]
Type=forking
PIDFile=/root/.vbmc/%i/pid
ExecStart=/bin/vbmc start %i
ExecStop=/bin/vbmc stop %i
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Adding nodes to Virtual BMC..."
count=1
for i in $(virsh list --all | awk ' /overcloud/ {print $2}'); do
    echo "Adding node $i to Virtual BMC"
    vbmc add $i --address 192.168.1.${count} --username admin --password redhat || { echo "Unable to add $i to Virtual BMC..."; return 1; }

    echo "Starting Virtual BMC service for node $i"
    systemctl enable --now virtualbmc@${i} || { echo "Unable to start Virtual BMC service for $i..."; return 1; }

    # Dammit!!!
    sleep 1

    echo "Testing IPMI connection on node $i"
    ipmitool -I lanplus -U admin -P redhat  -H 192.168.1.${count}  power status || { echo "IPMI test on node $i failed..."; return 1; }

    count=$((count+1))
done

# 配置 Hypervisor 启用 nested virtualization
echo "Configuring /etc/modprobe.d/kvm_intel.conf"
cat << EOF > /etc/modprobe.d/kvm_intel.conf
options kvm-intel nested=1
options kvm-intel enable_shadow_vmcs=1
options kvm-intel enable_apicv=1
options kvm-intel ept=1
EOF

modprobe -r kvm_intel
modprobe kvm_intel

cat /sys/module/kvm_intel/parameters/nested
Y





```



### 安装 Helper
```
# 安装 helper 服务器
virt-install --name=jwang-helper-undercloud --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-helper-undercloud.qcow2,bus=virtio,size=100 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --location /root/jwang/isos/rhel-8.2-x86_64-dvd.iso \
--graphics none \
--initrd-inject /tmp/ks-helper.cfg \
--extra-args='ks=file:/ks-helper.cfg console=ttyS0'

# 配置 yum 源
# 根据现场实际情况配置
# 这里用 undercloud 提供的 yum 源

cat > /etc/yum.repos.d/w.repo << EOF
[rhel-8-for-x86_64-baseos-eus-rpms]
name=rhel-8-for-x86_64-baseos-eus-rpms
baseurl=http://192.168.8.21:8787/repos/osp16.1/rhel-8-for-x86_64-baseos-eus-rpms/
enabled=1
gpgcheck=0

[rhel-8-for-x86_64-appstream-eus-rpms]
name=rhel-8-for-x86_64-appstream-eus-rpms
baseurl=http://192.168.8.21:8787/repos/osp16.1/rhel-8-for-x86_64-appstream-eus-rpms/
enabled=1
gpgcheck=0
EOF

```