## Define IPA Node
CLASSROOM_SERVER=10.149.23.10
PASSWORD_FOR_VMS='r3dh4t1!'
OFFICIAL_IMAGE=rhel-8.qcow2
export LIBGUESTFS_PATH=/var/lib/libvirt/images/appliance/


curl -o /tmp/open.repo http://classroom/open16.repo
# Define the /etc/hosts file
cat > /tmp/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

${CLASSROOM_SERVER}  classroom classroom.example.com
EOF

cat > /tmp/ifcfg-eth0 <<EOF
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=192.168.0.252
NETMASK=255.255.255.0
GATEWAY=192.168.0.1
DNS1=192.168.0.1
EOF

cd /var/lib/libvirt/images/
node=ipa
qemu-img create -f qcow2 $node.qcow2 60G
virt-resize --expand /dev/sda3 ${OFFICIAL_IMAGE} $node.qcow2

virt-customize -a $node.qcow2 \
  --hostname $node.example.com \
  --root-password password:${PASSWORD_FOR_VMS} \
  --uninstall cloud-init \
  --copy-in /tmp/hosts:/etc/ \
  --copy-in /tmp/open.repo:/etc/yum.repos.d/ \
  --copy-in /tmp/ifcfg-eth0:/etc/sysconfig/network-scripts/ \
  --selinux-relabel

virt-install --ram 2048 --vcpus 1 --os-variant rhel8.0 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/$node.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=trunk,mac=52:54:00:01:20:21 \
--name $node --dry-run --print-xml \
> /root/host-ipa.xml

## Create IPA VM
virsh define /root/host-$node.xml

## Start IPA VM
virsh start $node
