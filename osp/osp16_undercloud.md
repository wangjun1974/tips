## 配置

```
nmcli con mod 'ens3' ipv4.method 'manual' ipv4.address '10.66.208.121/24' ipv4.gateway '10.66.208.254' ipv4.dns '10.64.63.6'

nmcli con down ens3 && nmcli con up ens3

hostnamectl set-hostname undercloud.rhsacn.org
hostnamectl set-hostname --transient undercloud.rhsacn.org

mkdir -p /etc/yum.repos.d/backup
yes | mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup

cat << 'EOF' > /etc/yum.repos.d/w.repo
[rhel-8-for-x86_64-baseos-rpms]
name=rhel-8-for-x86_64-baseos-rpms
baseurl=http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-baseos-rpms/
enable=1
gpgcheck=0

[rhel-8-for-x86_64-appstream-rpms]
name=rhel-8-for-x86_64-appstream-rpms
baseurl=http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-appstream-rpms/
enable=1
gpgcheck=0

[rhel-8-for-x86_64-highavailability-rpms]
name=rhel-8-for-x86_64-highavailability-rpms
baseurl=http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-highavailability-rpms/
enable=1
gpgcheck=0

[ansible-2.8-for-rhel-8-x86_64-rpms]
name=ansible-2.8-for-rhel-8-x86_64-rpms
baseurl=http://10.66.208.158/rhel8osp/ansible-2.8-for-rhel-8-x86_64-rpms/
enable=1
gpgcheck=0

[openstack-16-for-rhel-8-x86_64-rpms]
name=openstack-16-for-rhel-8-x86-64-rpms​
baseurl=http://10.66.208.158/rhel8osp/openstack-16-for-rhel-8-x86_64-rpms/
enable=1
gpgcheck=0

[fast-datapath-for-rhel-8-x86_64-rpms]
name=fast-datapath-for-rhel-8-x86_64-rpms
baseurl=http://10.66.208.158/rhel8osp/fast-datapath-for-rhel-8-x86_64-rpms/
enable=1
gpgcheck=0

[advanced-virt-for-rhel-8-x86_64-rpms]
name=advanced-virt-for-rhel-8-x86_64-rpms
baseurl=http://10.66.208.158/rhel8osp/advanced-virt-for-rhel-8-x86_64-rpms/
enable=0
gpgcheck=0

EOF

NTPSERVER="10.66.208.158"
LOCALSUBNET=$(ip r s | grep ens3 | grep -v default | awk '{print $1}')

yum install -y chrony

cat > /etc/chrony.conf << EOF
server ${NTPSERVER} iburst
stratumweight 0
driftfile /var/lib/chrony/drift
rtcsync
makestep 10 3
bindcmdaddress 127.0.0.1
bindcmdaddress ::1
cmdallow 127.0.0.1
allow ${LOCALSUBNET}
keyfile /etc/chrony.keys
commandkey 1
generatecommandkey
noclientlog
logchange 0.5
logdir /var/log/chrony
EOF

systemctl enable chronyd && systemctl start chronyd

chronyc -n sources -v 
chronyc -n tracking

timedatectl status

nmcli con del 'Wired connection 1'
nmcli con add type ethernet ifname ens8 con-name ens8 
nmcli con mod 'ens8' ipv4.method 'manual' ipv4.address '192.168.208.10/24'
nmcli con down ens8 && nmcli con up ens8

firewall-cmd --get-zone-of-interface=ens8

firewall-cmd --add-service=ntp --zone=$(firewall-cmd --get-zone-of-interface=ens8)
firewall-cmd --add-service=ntp --zone=$(firewall-cmd --get-zone-of-interface=ens8) --permanent
firewall-cmd --list-all --zone=$(firewall-cmd --get-zone-of-interface=ens8)

yum update -y && reboot

yum install -y bash-completion

# install director
useradd stack
echo 'redhat' | passwd stack --stdin

echo 'stack ALL=(root) NOPASSWD:ALL' | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack

# switch to stack user
su - stack
mkdir -p ~/images
mkdir -p ~/templates

# install director
sudo yum install -y python3-tripleoclient

# prepare container image
openstack tripleo container image prepare default --local-push-destination --output-env-file containers-prepare-parameter.yaml.orig

yes | cp -f containers-prepare-parameter.yaml.orig containers-prepare-parameter.yaml

# access Registry Service Account Url: https://access.redhat.com/terms-based-registry/. 
# enter account name and account description

cat >> containers-prepare-parameter.yaml << 'EOF'
  ContainerImageRegistryCredentials:
    registry.redhat.io:
      6747835|jwang: 
  ContainerImageRegistryLogin: true    
EOF

REGISTRYTOKEN=$(curl http://10.66.208.115/rhel9osp/registry-redhat-io-jwang)

sed -ie "/6747835|jwang:/ a ${REGISTRYTOKEN}" containers-prepare-parameter.yaml
sed -ie '/6747835/ {N; s/\n//g;}' containers-prepare-parameter.yaml

cat > undercloud.conf << 'EOF'
[DEFAULT]
local_interface = ens8
enabled_hardware_types = ipmi,redfish,ilo,idrac,staging-ovirt
local_ip = 192.168.208.1/24
network_cidr = 192.168.208.0/24
undercloud_admin_host = 192.168.208.2
undercloud_public_host = 192.168.208.3
undercloud_debug = true
undercloud_hostname = undercloud.rhsacn.org
undercloud_ntp_servers = 10.66.208.158
container_images_file = containers-prepare-parameter.yaml

[ctlplane-subnet]
cidr = 192.168.208.0/24
dhcp_start = 192.168.208.20
dhcp_end = 192.168.208.120
gateway = 192.168.208.1
inspection_iprange = 192.168.208.150,192.168.208.180
masquerade = true
EOF

# install undercloud
# may need run multiple times for sync images
openstack undercloud install

source stackrc

sudo yum install -y rhosp-director-images rhosp-director-images-ipa

pushd ~/images
tar xvf /usr/share/rhosp-director-images/overcloud-full-latest-16.0.tar
tar xvf /usr/share/rhosp-director-images/ironic-python-agent-latest-16.0.tar

sudo yum install -y libguestfs-tools
sudo yum install -y libvirt virt-install libvirt-client

sudo -i
cd /home/stack/images
export LIBGUESTFS_BACKEND=direct 
virt-customize -a overcloud-full.qcow2 --root-password password:redhat
exit

openstack overcloud image upload --image-path /home/stack/images/
openstack image list
ls -l /var/lib/ironic/httpboot/

# config dns to subnet
openstack subnet list
openstack subnet set --dns-nameserver 192.168.208.1 ctlplane-subnet
openstack subnet show ctlplane-subnet

# prepare overcloud node
openstack baremetal driver list

# prepare controller vm
# virt-install --name osp16-controller0 --os-variant=rhel8.1 --ram=8192 --vcpu=4 --boot network,hd --disk path=/var/lib/libvirt/images/osp16-controller0.qcow2,bus=virtio,sparse=true,format=raw,cache=unsafe,size=80 --network network=provision --network network=default --noautoconsole --vnc --noreboot --check disk_size=off

# prepare compute vm
# virt-install --name osp16-compute0 --os-variant=rhel8.1 --ram=8192 --vcpu=4 --boot network,hd --disk path=/var/lib/libvirt/images/osp16-compute0.qcow2,bus=virtio,sparse=true,format=raw,cache=unsafe,size=80 --network network=provision --network network=default --noautoconsole --vnc --noreboot --check disk_size=off

# install virtual bmc through pip3
# pip3 install virtualbmc

# register vms into vbmc 
# vbmc add osp16-controller0 --port 6450 --username admin --password redhat
# vbmc add osp16-compute0 --port 6451 --username admin --password redhat

# start vbmc
# vbmc start osp16-controller0
# vbmc start osp16-compute0

# list vbmc
# vbmc list

# add vbmc firewall rules into libvirt zone
# firewall-cmd --add-port=6450/udp --zone=libvirt
# firewall-cmd --add-port=6451/udp --zone=libvirt
# firewall-cmd --add-port=6450/udp --zone=libvirt --permanent
# firewall-cmd --add-port=6451/udp --zone=libvirt --permanent

# install ipmitool on undercloud
# sudo yum install -y ipmitool

# check undercloud to overcloud node ipmi communication

# check undercloud -> controller ipmi communication
# ipmitool -H 192.168.208.1 -p 6450 -I lanplus -U admin -P redhat power status

# check undercloud -> compute ipmi communication
# ipmitool -H 192.168.208.1 -p 6451 -I lanplus -U admin -P redhat power status


```
