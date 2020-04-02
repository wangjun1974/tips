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
```
