#!/usr/bin/env bash

CLASSROOM_SERVER=10.149.23.10
IMAGES_DIR=/var/lib/libvirt/images
OFFICIAL_IMAGE=rhel-8.qcow2
export LIBGUESTFS_PATH=/var/lib/libvirt/images/appliance/
PASSWORD_FOR_VMS='r3dh4t1!'
VIRT_DOMAIN='example.com'
# Define the /etc/hosts file
cat > /tmp/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

${CLASSROOM_SERVER}  classroom
EOF


cd ${IMAGES_DIR}

# Download course specific config files for VM customization
curl -o /tmp/open.repo http://classroom/open16.repo
mkdir /tmp/overcloud2-ctrl01/
mkdir /tmp/overcloud2-compute01/
cat > /tmp/overcloud2-ctrl01/ifcfg-eth0 <<EOF
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=192.0.2.81
NETMASK=255.255.255.0
GATEWAY=192.0.2.254
DNS1=192.0.2.254
EOF

cat > /tmp/overcloud2-compute01/ifcfg-eth0 <<EOF
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=192.0.2.91
NETMASK=255.255.255.0
GATEWAY=192.0.2.254
DNS1=192.0.2.254
EOF

for VM in overcloud2-ctrl01 overcloud2-compute01
do
qemu-img create -f qcow2 $VM.qcow2 20G
virt-resize --expand /dev/sda3 ${OFFICIAL_IMAGE} $VM.qcow2

virt-customize -a $VM.qcow2 \
  --hostname $VM.example.com \
  --root-password password:${PASSWORD_FOR_VMS} \
  --uninstall cloud-init \
  --copy-in /tmp/${VM}/ifcfg-eth0:/etc/sysconfig/network-scripts/ \
  --copy-in /tmp/hosts:/etc/ \
  --copy-in /etc/resolv.conf:/etc/ \
  --copy-in /tmp/open.repo:/etc/yum.repos.d/ \
  --selinux-relabel
done

VM=overcloud2-ctrl01
virt-install --ram 8192 --vcpus 2 --os-variant rhel8.0 \
--disk path=${IMAGES_DIR}/${VM}.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc --network network:provisioning,mac=52:54:00:01:10:21 \
--network network:trunk --network network:trunk \
--name ${VM} \
--cpu host,+vmx \
--dry-run --print-xml > /tmp/${VM}.xml
virsh define --file /tmp/${VM}.xml
rm /tmp/${VM}.xml
virsh start $VM
VM=overcloud2-compute01
virt-install --ram 4096 --vcpus 4 --os-variant rhel8.0 \
--disk path=${IMAGES_DIR}/${VM}.qcow2,device=disk,bus=virtio,format=qcow2 \
--noautoconsole --vnc --network network:provisioning,mac=52:54:00:01:10:22 \
--network network:trunk --network network:trunk \
--name ${VM} \
--cpu host,+vmx \
--dry-run --print-xml > /tmp/${VM}.xml
virsh define --file /tmp/${VM}.xml
virsh start $VM
rm /tmp/${VM}.xml

rm /tmp/hosts
rm /tmp/open.repo

