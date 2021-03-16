## 定义存储节点
```
# 参考 osp 节点定义
CEPH_N="ceph01 ceph02 ceph03"
CEPH_MEM='16384'
CEPH_VCPU='4'
LIBVIRT_D='/data/kvm'
CEPH_OSD_DISK=3

for i in $CEPH_N;
do
    echo "Defining node jwang-xuhui-$i..."
    virt-install --ram $CEPH_MEM --vcpus $CEPH_VCPU --os-variant rhel7 \
    --disk path=${LIBVIRT_D}/jwang-xuhui-$i.qcow2,device=disk,bus=virtio,format=qcow2 \
    $(for((n=1;n<=$CEPH_OSD_DISK;n+=1)); do echo -n "--disk path=${LIBVIRT_D}/jwang-xuhui-$i-storage-${n}.qcow2,device=disk,bus=virtio,format=qcow2 "; done) \
    --noautoconsole --vnc --network network:provisioning \
    --network network:default \
    --name jwang-xuhui-$i \
    --cpu SandyBridge,+vmx \
    --dry-run --print-xml > /tmp/jwang-overcloud-$i.xml

    virsh define --file /tmp/jwang-xuhui-$i.xml || { echo "Unable to define jwang-xuhui-$i"; return 1; }
done

# 安装一个 allinone 的 节点
cat > /tmp/ks.cfg << 'EOF'
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
ignoredisk --only-use=vda
clearpart --all --initlabel
autopart
network --device=ens2 --hostname=xuhui.example.com --bootproto=static --ip=192.168.122.101 --netmask=255.255.255.0 --gateway=192.168.122.1 --nameserver=192.168.122.1
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

echo "Defining node jwang-xuhui-ceph01..."
virt-install --debug --ram 16384 --vcpus 4 --os-variant rhel7 \
    --disk path=/data/kvm/jwang-xuhui-ceph01.qcow2,bus=virtio,size=100 \
    $(for((n=1;n<=3;n+=1)); do echo -n "--disk path=/data/kvm/jwang-xuhui-ceph01-storage-${n}.qcow2,bus=virtio,size=100 "; done) \
    --network network:default,model=virtio \
    --boot menu=on --location /root/jwang/isos/rhel-8.2-x86_64-dvd.iso \
    --graphics none \
    --console pty,target_type=serial \
    --initrd-inject /tmp/ks.cfg \
    --extra-args='ks=file:/ks.cfg console=ttyS0' \
    --name jwang-xuhui-ceph01

# 设置软件仓库
> /etc/yum.repos.d/w.repo 
for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms  ansible-2.9-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms 
do
cat >> /etc/yum.repos.d/w.repo << EOF
[$i]
name=$i
baseurl=file:///var/www/html/repos/osp16.1/$i/
enabled=1
gpgcheck=0

EOF
done
```