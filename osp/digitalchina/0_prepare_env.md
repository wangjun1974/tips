### 在物理机里安装 osp 时做的准备工作

1. 配置并且记录 IPMI 信息
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

# RHEL7 Hypervisor 安装 vbmc 软件包
yum install -y python2-virtualbmc



```


