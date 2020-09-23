## Define Workstation Node
CLASSROOM_SERVER=10.149.23.10
PASSWORD_FOR_VMS='r3dh4t1!'
OFFICIAL_IMAGE=rhel-8.qcow2
export LIBGUESTFS_PATH=/var/lib/libvirt/images/appliance/

curl -o /tmp/open.repo http://classroom/open16.repo
# Define the /etc/hosts file
cat > /tmp/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

${CLASSROOM_SERVER}  classroom
EOF


cat > /tmp/ifcfg-eth0 <<EOF
DEVICE=eth0
IPADDR=192.168.122.253
GATEWAY=192.168.122.1
PREFIX=24
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
EOF

cat > /tmp/ifcfg-eth1 <<EOF
DEVICE=eth1
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=192.0.2.253
NETMASK=255.255.255.0
GATEWAY=192.0.2.254
DNS1=192.0.2.254
EOF



cd /var/lib/libvirt/images/
node=allinone
qemu-img create -f qcow2 $node.qcow2 60G
virt-resize --expand /dev/sda3 ${OFFICIAL_IMAGE} $node.qcow2

virt-customize -a $node.qcow2 \
  --hostname $node.example.com \
  --root-password password:${PASSWORD_FOR_VMS} \
  --uninstall cloud-init \
  --copy-in /tmp/hosts:/etc/ \
  --copy-in /tmp/ifcfg-eth0:/etc/sysconfig/network-scripts/ \
  --copy-in /tmp/ifcfg-eth1:/etc/sysconfig/network-scripts/ \
  --copy-in /tmp/open.repo:/etc/yum.repos.d/ \
  --selinux-relabel

virt-install --ram 16384 --vcpus 4 --os-variant rhel8.0 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/$node.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=default \
--network network=provisioning \
--name $node --dry-run --print-xml \
> /root/host-$node.xml

## Create VM
virsh define /root/host-$node.xml

## Start VM
virsh start $node

