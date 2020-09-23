## Define Ceph Nodes
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


cd /var/lib/libvirt/images/
for i in {1,2,3}; do

node=ceph-node0${i}

cat > /tmp/ifcfg-eth0 << EOF
DEVICE=eth0
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
EOF

cat > /tmp/ifcfg-eth0.30 << EOF
DEFROUTE=yes
NAME=eth0
DEVICE=eth0.30
ONBOOT=yes
IPADDR=172.18.0.6${i}
PREFIX=24
GATEWAY=172.18.0.254
DNS1=8.8.8.8
VLAN=yes
EOF


qemu-img create -f qcow2 $node.qcow2 60G
virt-resize --expand /dev/sda3 ${OFFICIAL_IMAGE} $node.qcow2

virt-customize -a $node.qcow2 \
  --hostname $node.example.com \
  --root-password password:${PASSWORD_FOR_VMS} \
  --uninstall cloud-init \
  --copy-in /tmp/hosts:/etc/ \
  --copy-in /tmp/ifcfg-eth0:/etc/sysconfig/network-scripts/ \
  --copy-in /tmp/ifcfg-eth0.30:/etc/sysconfig/network-scripts/ \
  --copy-in /tmp/open.repo:/etc/yum.repos.d/ \
  --selinux-relabel
done



qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph01a.qcow2 10g
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph01b.qcow2 10g
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph02a.qcow2 10g
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph02b.qcow2 10g
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph03a.qcow2 10g
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/ceph03b.qcow2 10g



virt-install --ram 2048 --vcpus 1 --os-variant rhel8.0 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/ceph-node01.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph01a.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph01b.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=trunk,mac=52:54:00:01:00:21 \
--name ceph-node01 --dry-run --print-xml \
> /root/host-ceph-node01.xml

virt-install --ram 2048 --vcpus 1 --os-variant rhel8.0 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/ceph-node02.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph02a.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph02b.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=trunk,mac=52:54:00:01:00:22 \
--name ceph-node02 --dry-run --print-xml \
> /root/host-ceph-node02.xml

virt-install --ram 2048 --vcpus 1 --os-variant rhel8.0 --cpu host,+vmx \
--disk path=/var/lib/libvirt/images/ceph-node03.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph03a.qcow2,device=disk,bus=virtio,format=qcow2 \
--disk path=/var/lib/libvirt/images/ceph03b.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc \
--network network=trunk,mac=52:54:00:01:00:23 \
--name ceph-node03 --dry-run --print-xml \
> /root/host-ceph-node03.xml

## Create Ceph VMs
virsh define /root/host-ceph-node01.xml
virsh define /root/host-ceph-node02.xml
virsh define /root/host-ceph-node03.xml

## Start Ceph VMs
virsh start ceph-node01
virsh start ceph-node02
virsh start ceph-node03


cat >/etc/sysconfig/network-scripts/ifcfg-virbr2.30 <<EOF
DEVICE=virbr2.30
ONBOOT=yes
NM_CONTROLLED="no"
IPADDR=172.18.0.254
PREFIX=24
VLAN=yes
ZONE=external

EOF
ifup virbr2.30 >/dev/null
