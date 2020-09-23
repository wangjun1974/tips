#!/usr/bin/env bash

CLASSROOM_SERVER=10.149.23.10
IMAGES_DIR=/var/lib/libvirt/images
OFFICIAL_IMAGE=rhel7-guest-official.qcow2
PASSWORD_FOR_VMS='r3dh4t1!'
VIRT_DOMAIN='example.com'

### Let the user know that this will destroy his environment.

ANSWER=YES

if virsh list --all | egrep -q  'comp|net|ctrl|stor|undercloud'
then
  unset ANSWER
  echo '*** WARNING ***'
  echo 'This procedure will destroy the environment you currently have'
  echo 'Type uppercase YES if you understand this and want to proceed'
  read -p 'Your answer > ' ANSWER
fi

[ "${ANSWER}" != "YES" ] && exit 1

### Clean the environment

if virsh net-list --all | egrep -q "provisioning|trunk"
then
  for NETWORK in provisioning trunk
  do
    virsh net-destroy ${NETWORK}   > /dev/null 2>&1
    virsh net-undefine ${NETWORK}  > /dev/null 2>&1
  done
fi

vbmc list | awk '/undercloud/ { print $2; }' | xargs vbmc delete
vbmc list | awk '/overcloud/ { print $2; }' | xargs vbmc delete

if firewall-cmd --get-active-zones | grep -q virt
then
  firewall-cmd --delete-zone=virt --permanent
  firewall-cmd --reload
fi

cd ${IMAGES_DIR}

if virsh list --all | egrep -q  'compute|networker|ctrl|stor|undercloud'
then
  for VM in overcloud-ctrl0{1,2,3} overcloud-compute0{1,2} overcloud-networker overcloud-stor0{1,2,3} undercloud
  do
    virsh destroy ${VM}  > /dev/null 2>&1
    virsh undefine ${VM} > /dev/null 2>&1
    rm -f ${IMAGES_DIR}/${VM}.qcow2 > /dev/null 2>&1
    rm -f ${IMAGES_DIR}/${VM}-storage.qcow2 > /dev/null 2>&1
  done
fi

### Create the networks required for environment.

cat > /tmp/provisioning.xml <<EOF
<network>
  <name>provisioning</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <ip address="172.16.0.254" netmask="255.255.255.0">
  <dhcp>
      <host mac='52:54:00:01:00:21' name='ceph-node01' ip='172.16.0.61'/>
      <host mac='52:54:00:01:00:22' name='ceph-node02' ip='172.16.0.62'/>
      <host mac='52:54:00:01:00:23' name='ceph-node03' ip='172.16.0.63'/>
      <host mac='52:54:00:01:10:21' name='overcloud2-ctrl01' ip='172.16.0.91'/>
      <host mac='52:54:00:01:10:22' name='overcloud2-compute01' ip='172.16.0.92'/>
  </dhcp>
  </ip>
  <ip address="192.0.2.254" netmask="255.255.255.0"/>
</network>
EOF

cat > /tmp/trunk.xml <<EOF
<network>
  <name>trunk</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <ip address="192.168.0.1" netmask="255.255.255.0"/>
</network>
EOF

cat > /tmp/provider.xml <<EOF
<network>
  <name>provider</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <ip address="192.168.3.1" netmask="255.255.255.0"/>
</network>
EOF

for NETWORK in provisioning trunk provider
do
  virsh net-define /tmp/${NETWORK}.xml
  virsh net-autostart ${NETWORK}
  virsh net-start ${NETWORK}
done

# Add firewall rules
firewall-cmd --new-zone=virt --permanent
firewall-cmd --zone=virt --add-source=192.0.2.0/24 --permanent
firewall-cmd --zone=virt --add-source=192.168.0.0/24 --permanent
firewall-cmd --zone=virt --add-source=192.168.3.0/24 --permanent
firewall-cmd --zone=virt --set-target=ACCEPT --permanent
firewall-cmd --reload


# Create virtual machines

# Download course specific config files for VM customization
curl -o /tmp/open.repo http://classroom/open13.repo

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

${CLASSROOM_SERVER}  classroom.example.com classroom
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

virt-install --ram 16384 --vcpus 4 --os-variant rhel7 \
  --disk path=${IMAGES_DIR}/undercloud.qcow2,device=disk,bus=virtio,format=qcow2 \
  --import --noautoconsole --vnc --network network:provisioning \
  --network network:trunk --name undercloud \
  --cpu host,+vmx \
  --dry-run --print-xml > /tmp/undercloud.xml

rm /tmp/hosts
rm /tmp/ifcfg-eth0
rm /tmp/ifcfg-eth1
rm /tmp/open.repo

virsh define --file /tmp/undercloud.xml
rm /tmp/undercloud.xml

for VM in overcloud-ctrl0{1,2,3} overcloud-compute0{1,2} overcloud-stor01 overcloud-networker
do
	qemu-img create -f qcow2 -o preallocation=metadata ${VM}.qcow2 60G
done

for VM in overcloud-stor01 overcloud-compute0{1,2}
do
	qemu-img create -f qcow2 -o preallocation=metadata ${VM}-storage.qcow2 60G
done

for VM in overcloud-ctrl0{1,2,3}
do
	virt-install --ram 12288 --vcpus 2 --os-variant rhel7 \
	--disk path=${IMAGES_DIR}/${VM}.qcow2,device=disk,bus=virtio,format=qcow2 \
	--noautoconsole --vnc --network network:provisioning \
	--network network:trunk --network network:trunk  --network network:provider\
	--name ${VM} \
	--cpu host,+vmx \
	--dry-run --print-xml > /tmp/${VM}.xml
	virsh define --file /tmp/${VM}.xml
	rm /tmp/${VM}.xml
done

for VM in overcloud-compute0{1,2}
do
	virt-install --ram 6096 --vcpus 4 --os-variant rhel7 \
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

for VM in overcloud-stor01 
do
	virt-install --ram 4096 --vcpus 2 --os-variant rhel7 \
	--disk path=${IMAGES_DIR}/${VM}.qcow2,device=disk,bus=virtio,format=qcow2 \
	--disk path=${IMAGES_DIR}/${VM}-storage.qcow2,device=disk,bus=virtio,format=qcow2 \
	--noautoconsole --vnc --network network:provisioning \
	--network network:trunk --network network:trunk \
	--name ${VM} \
	--cpu host,+vmx \
	--dry-run --print-xml > /tmp/${VM}.xml
	virsh define --file /tmp/${VM}.xml
	rm /tmp/${VM}.xml
done

virt-install --ram 4096 --vcpus 2 --os-variant rhel7 \
        --disk path=${IMAGES_DIR}/overcloud-networker.qcow2,device=disk,bus=virtio,format=qcow2 \
        --noautoconsole --vnc --network network:provisioning \
        --network network:trunk --network network:trunk --network network:provider \
        --name overcloud-networker \
        --cpu host,+vmx \
        --dry-run --print-xml > /tmp/overcloud-networker.xml
        virsh define --file /tmp/overcloud-networker.xml
        rm /tmp/overcloud-networker.xml

vbmc add undercloud --port 6230 --address 192.168.1.1
vbmc add overcloud-ctrl01 --port 6231 --address 192.168.1.1
vbmc add overcloud-ctrl02 --port 6232 --address 192.168.1.1
vbmc add overcloud-ctrl03 --port 6233 --address 192.168.1.1
vbmc add overcloud-compute01 --port 6234 --address 192.168.1.1
vbmc add overcloud-compute02 --port 6235 --address 192.168.1.1
vbmc add overcloud-stor01 --port 6236 --address 192.168.1.1
vbmc add overcloud-networker --port 6239 --address 192.168.1.1

cat >/root/vbmc-start.sh <<EOF
vbmc start undercloud
vbmc start overcloud-ctrl01
vbmc start overcloud-ctrl02
vbmc start overcloud-ctrl03
vbmc start overcloud-compute01
vbmc start overcloud-compute02
vbmc start overcloud-stor01
vbmc start overcloud-networker
EOF

chmod 755 /root/vbmc-start.sh


cat >/etc/sysconfig/network-scripts/ifcfg-virbr2.501 <<EOF
DEVICE=virbr2.501
ONBOOT=yes
NM_CONTROLLED="no"
IPADDR=10.0.0.1
PREFIX=24
VLAN=yes
ZONE=external
EOF
ifup virbr2.501

firewall-cmd --zone=external --add-interface=virbr2.501 --permanent
firewall-cmd --zone=dmz --add-masquerade --permanent
firewall-cmd --zone=internal --add-masquerade --permanent
firewall-cmd --add-port=6231-6240/udp --zone=external --permanent 
firewall-cmd --reload


