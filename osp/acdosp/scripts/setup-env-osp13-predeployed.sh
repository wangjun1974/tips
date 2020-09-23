#!/usr/bin/env bash

CLASSROOM_SERVER=10.149.23.10
IMAGES_DIR=/var/lib/libvirt/images
OFFICIAL_IMAGE=rhel7-guest-official.qcow2
PASSWORD_FOR_VMS='r3dh4t1!'
VIRT_DOMAIN='example.com'
# Define the /etc/hosts file
cat > /tmp/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

${CLASSROOM_SERVER}  classroom
EOF


### Let the user know that this will destroy his environment.

ANSWER=YES

if virsh list --all | egrep -q  'comp|net|ctrl|stor'
then
  unset ANSWER
  echo '*** WARNING ***'
  echo 'This procedure will stop all the VMs excel undercloud'
  echo 'Type uppercase YES if you understand this and want to proceed'
  read -p 'Your answer > ' ANSWER
fi

[ "${ANSWER}" != "YES" ] && exit 1

cd ${IMAGES_DIR}

# Download course specific config files for VM customization
curl -o /tmp/open.repo http://classroom/download/etc/yum.repos.d/rhosp-13.repo

cd ${IMAGES_DIR}

if virsh list --all | egrep -q  'compute|networker|ctrl|stor'
then
  for VM in overcloud-ctrl0{1,2,3} overcloud-compute0{1,2} overcloud-networker overcloud-stor0{1,2,3} 
  do
    virsh shutdown ${VM}  > /dev/null 2>&1
  done
fi




virsh net-update provisioning add ip-dhcp-host "<host mac='52:54:00:01:10:21' name='overcloud2-ctrl01' ip='172.16.0.101'/>" --live --config
virsh net-update provisioning add ip-dhcp-host "<host mac='52:54:00:01:10:22' name='overcloud2-compute01' ip='172.16.0.111'/>" --live --config


for VM in overcloud2-ctrl01 overcloud2-compute01
do
qemu-img create -f qcow2 $VM.qcow2 20G
virt-resize --expand /dev/sda3 ${OFFICIAL_IMAGE} $VM.qcow2

virt-customize -a $VM.qcow2 \
  --hostname $VM.example.com \
  --root-password password:${PASSWORD_FOR_VMS} \
  --uninstall cloud-init \
  --copy-in /tmp/hosts:/etc/ \
  --copy-in /etc/resolv.conf:/etc/ \
  --copy-in /tmp/open.repo:/etc/yum.repos.d/ \
  --selinux-relabel
done

VM=overcloud2-ctrl01
virt-install --ram 8192 --vcpus 2 --os-variant rhel7 \
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
virt-install --ram 4096 --vcpus 4 --os-variant rhel7 \
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

