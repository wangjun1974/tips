#!/usr/bin/env bash

CLASSROOM_SERVER=10.149.23.10
IMAGES_DIR=/var/lib/libvirt/images
OFFICIAL_IMAGE=rhel-8.qcow2
PASSWORD_FOR_VMS='r3dh4t1!'
VIRT_DOMAIN='example.com'
export LIBGUESTFS_PATH=/var/lib/libvirt/images/appliance/

cd ${IMAGES_DIR}

# Define the /etc/hosts file
cat > /tmp/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

${CLASSROOM_SERVER}  classroom.example.com classroom
EOF

for VM in overcloud-compute03
do
	qemu-img create -f qcow2 -o preallocation=metadata ${VM}.qcow2 60G
done

for VM in overcloud-compute03
do
	qemu-img create -f qcow2 -o preallocation=metadata ${VM}-storage.qcow2 60G
done

for VM in overcloud-compute03
do
	virt-install --ram 8192 --vcpus 4 --os-variant rhel8.0 \
	--disk path=${IMAGES_DIR}/${VM}.qcow2,device=disk,bus=virtio,format=qcow2 \
	--disk path=${IMAGES_DIR}/${VM}-storage.qcow2,device=disk,bus=virtio,format=qcow2 \
	--noautoconsole --vnc --network network:provisioning \
	--network network:trunk --network network:trunk  --network network:provider\
	--name ${VM} \
	--cpu host,+vmx \
	--dry-run --print-xml > /tmp/${VM}.xml
	virsh define --file /tmp/${VM}.xml
	rm /tmp/${VM}.xml
done

vbmc add overcloud-compute03 --port 6240 --address 192.168.1.1
vbmc start overcloud-compute03

cat >/root/vbmc-start.sh <<EOF
vbmc start overcloud-compute03
EOF

