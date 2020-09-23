#!/usr/bin/env bash

CLASSROOM_SERVER=10.149.23.10
IMAGES_DIR=/var/lib/libvirt/images
OFFICIAL_IMAGE=rhel7-guest-official.qcow2
PASSWORD_FOR_VMS='r3dh4t1!'
VIRT_DOMAIN='example.com'

### Let the user know that this will destroy his environment.

ANSWER=YES

if virsh list --all | egrep -q  'undercloud'
then
  unset ANSWER
  echo '*** WARNING ***'
  echo 'This procedure will destroy undercloud you currently have'
  echo 'Type uppercase YES if you understand this and want to proceed'
  read -p 'Your answer > ' ANSWER
fi

[ "${ANSWER}" != "YES" ] && exit 1

cd ${IMAGES_DIR}

if virsh list --all | egrep -q  'undercloud'
then
  for VM in  undercloud
  do
    virsh destroy ${VM}  > /dev/null 2>&1
    rm -f ${IMAGES_DIR}/${VM}.qcow2 > /dev/null 2>&1
  done
fi

# Download course specific config files for VM customization
curl -o /tmp/open.repo http://classroom.example.com/download/etc/yum.repos.d/rhosp-13.repo

# Define config files for network interfaces on the undercloud node
cat > /tmp/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="none"
ONBOOT="no"
TYPE="Ethernet"
NM_CONTROLLED="no"
EOF

cat > /tmp/ifcfg-eth1 << EOF
DEVICE="eth1"
BOOTPROTO="none"
ONBOOT="yes"
TYPE="Ethernet"
IPADDR=192.168.0.253
NETMASK=255.255.255.0
GATEWAY=192.168.0.1
NM_CONTROLLED="no"
DNS1=10.149.23.10
EOF

# Define the /etc/hosts file
cat > /tmp/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

${CLASSROOM_SERVER}  classroom
EOF

qemu-img create -f qcow2 undercloud.qcow2 60G
virt-resize --expand /dev/sda3 ${OFFICIAL_IMAGE} undercloud.qcow2
virt-customize -a undercloud.qcow2 \
  --hostname undercloud.example.com \
  --root-password password:${PASSWORD_FOR_VMS} \
  --uninstall cloud-init \
  --copy-in /tmp/hosts:/etc/ \
  --copy-in /tmp/ifcfg-eth0:/etc/sysconfig/network-scripts/ \
  --copy-in /tmp/ifcfg-eth1:/etc/sysconfig/network-scripts/ \
  --copy-in /tmp/open.repo:/etc/yum.repos.d/ \
  --selinux-relabel

rm /tmp/hosts
rm /tmp/ifcfg-eth0
rm /tmp/ifcfg-eth1
rm /tmp/open.repo

virsh start undercloud
