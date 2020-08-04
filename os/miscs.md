## 查看接口状态

```
ip -s link show dev ens3
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000                                    
    link/ether 00:1a:4a:16:01:88 brd ff:ff:ff:ff:ff:ff
    RX: bytes  packets  errors  dropped overrun mcast
    33400443957 20920850 0       38209   0       0
    TX: bytes  packets  errors  dropped carrier collsns
    720256020  10566989 0       0       0       0
```

## 安装配置vsftp 
参考：https://www.unixmen.com/install-vsftp-with-virtual-users-on-centos-rhel-scientific-linux-6-4/

```
yum install vsftpd -y 

cat > /tmp/virtual_users.txt << 'EOF'
jwang
redhat123
EOF

db_load -T -t hash -f /tmp/virtual_users.txt /etc/vsftpd/virtual_users.db

cat > /etc/pam.d/vsftpd_virtual << 'EOF'
#%PAM-1.0
auth    required        pam_userdb.so   db=/etc/vsftpd/virtual_users
account required        pam_userdb.so   db=/etc/vsftpd/virtual_users
session required        pam_loginuid.so
EOF

yes | cp -f /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.sav

cat > /etc/vsftpd/vsftpd.conf << 'EOF'
# Allow anonymous FTP? (Beware - allowed by default if you comment this out).
anonymous_enable=NO

# Uncomment this to allow local users to log in.
local_enable=YES

## Enable virtual users
guest_enable=YES

## Virtual users will use the same permissions as anonymous
virtual_use_local_privs=YES

#
# Uncomment this to enable any form of FTP write command.
write_enable=YES

## PAM file name
pam_service_name=vsftpd_virtual

## Home Directory for virtual users
user_sub_token=$USER
local_root=/ftp/virtual/$USER

# You may specify an explicit list of local users to chroot() to their home
# directory. If chroot_local_user is YES, then this list becomes a list of
# users to NOT chroot().
chroot_local_user=YES

## Hide ids from user
hide_ids=YES

# Allow writable undercloud chroot mode
allow_writeable_chroot=YES
EOF

mkdir -p /ftp/virtual/jwang
chown -R ftp:ftp /ftp
# chcon -R --reference /var/ftp/pub /ftp  
# semanage fcontext -a -t public_content_rw_t "/ftp(/.*)?"
chcon -R -t public_content_rw_t /ftp/virtual/jwang
# setsebool -P ftpd_full_access 1

firewall-cmd --add-service=ftp
firewall-cmd --add-service=ftp --permanent
firewall-cmd --reload

systemctl enable vsftpd && systemctl start vsftpd
```

注意⚠️：对于rhel7来说，安装时看看是否需要（待尝试）；经尝不需要以下命令
```
yum install db4-utils db4 -y
```

注意⚠️：遇到报错，500 OOPS: vsftpd: refusing to run with writable root inside chroot()
参考：https://www.cnblogs.com/wi100sh/p/4542819.html
```
ansible server01 -m lineinfile -a 'path=/etc/vsftpd/vsftpd.conf regexp="allow_writeable_chroot" line="allow_writeable_chroot=YES"'

ansible server01 -m service -a 'name=vsftpd state=restarted'
```

## 解决Homebrew慢的方法
因为访问github慢，所以尝试解决方法为使用镜像站点，是否有效待验证
参考：
* https://www.zhihu.com/question/31360766
* https://lug.ustc.edu.cn/wiki/mirrors/help/homebrew-bottles
* https://nwafu-mirrors-help.readthedocs.io/zh_cn/homebrew-cask-versions.git.html

替换git repo
```
cd "$(brew --repo)"
git remote set-url origin https://mirrors.aliyun.com/homebrew/brew.git

cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
git remote set-url origin https://mirrors.aliyun.com/homebrew/homebrew-core.git

echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles' >> ~/.bashrc
source ~/.bashrc

cd "$(brew --repo)"/Library/Taps/homebrew/homebrew-cask
git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git

cd "$(brew --repo)"/Library/Taps/homebrew/homebrew-cask-versions
git remote set-url origin https://mirrors.nwafu.edu.cn/homebrew-cask-versions.git
```

替换homebrew bottles镜像站点
```
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles' >> ~/.bash_profile
source ~/.bash_profile
```

另外一种思路是使用socks代理，参见：https://www.zhihu.com/question/31360766

## 检查哪个软件包提供了命令 yum provides audit2allow
```
yum provides audit2allow
```

## 设置selinux bool变量
```
setsebool -P ftpd_full_access 1
```
## 配置ansible控制节点

生成inventory
```
cat >> /etc/ansible/hosts << 'EOF'
[group1]
server01 ansible_host=10.66.208.158 ansible_user=root
EOF
```

生成ssh public key，生成ssh config
```
ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''

cat > ~/.ssh/config << 'EOF'
Host *
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null

EOF
```

构建控制节点到服务器间的信任关系
```
ansible all -m authorized_key -a 'user=root state=present key="{{ lookup(\"file\",\"/root/.ssh/id_rsa.pub\") }}"' -k
```

配置bbr
```
ansible server01 -m lineinfile -a 'path=/etc/sysctl.conf regexp="net.ipv4.tcp_congestion_control" line="net.ipv4.tcp_congestion_control=bbr"'
```

另外一种方式配置bbr
```
ansible server01 -m sysctl -a 'name=net.ipv4.tcp_congestion_control value=bbr sysctl_set=yes state=present reload=yes'
```

## lftp 命令
参考：https://unix.stackexchange.com/questions/93587/lftp-login-put-file-in-remote-dir-and-exit-in-a-single-command-proper-quoting

一条命令完成认证及上传
```
$ lftp -c "open -u user,pass ftpsite.com; put -O remote/dir/ /local/file.txt" 
$ lftp -c "open -u user,pass ftpsite.com; get remote/dir/file.txt" 
$ lftp -c "open -u user,pass ftpsite.com; pget -n 2 remote/dir/file.txt -o local/dir" 
```

## 配置时间服务器(RHEL8)

### chrony 服务器
```
yum install -y chrony

cat > /etc/chrony.conf << EOF
server 127.127.1.0 iburst
allow all
local stratum 4
EOF

firewall-cmd --add-service=ntp
firewall-cmd --add-service=ntp --permanent
firewall-cmd --reload

systemctl enable chronyd && systemctl start chronyd

chronyc -n sources
chronyc -n tracking
```

### chrony 客户端
```
NTPSERVER="clock.corp.redhat.com"
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

firewall-cmd --add-service=ntp
firewall-cmd --add-service=ntp --permanent
firewall-cmd --reload

systemctl enable chronyd && systemctl start chronyd

chronyc -n sources
chronyc -n tracking
```

## osp16 undercloud registry
OSP16的undercloud上可以运行一个本地registry，用于为undercloud和overcloud提供image

* undercloud registry的监听端口是8787
* undercloud registry的服务是httpd
* undercloud registry的存放位置是/var/lib/image-serve

### OSP13 baremetal node power
```
openstack baremetal node power on <uuid>
openstack baremetal node power off <uuid>

# check node power status
ipmitool -H 172.168.5.5 -v -I lanplus -U ADMIN -P ADMIN power status
```

### restart auditd
```
service auditd restart
```

### dnsmasq infinite lease
在dnsmasq.conf文件里包含描述mac地址，ip地址，过期时间的内容
```
dhcp-range=192.168.0.0,static
dhcp-host=aa:bb:cc:dd:ee:ff,192.168.0.199,infinite
```

### 检查ip地址范围
可以访问以下网址，例子里通过检查172.23.101.4/255.255.252.0的地址查看地址范围
http://jodies.de/ipcalc?host=172.23.101.4&mask1=255.255.252.0&mask2=

### 定期重新生成网卡配置的脚本

```
cat > /usr/local/sbin/network-con-recreate.sh << 'EOF'
#!/bin/bash

# delete all connection 
nmcli -g uuid con | while read i ; do nmcli c delete uuid ${i} ; done 

# re-create primary connection 
nmcli con add type ethernet \
    con-name eth0 \
    ifname eth0 \
    ipv4.method 'manual' \
    ipv4.address '192.168.208.137/24' \
    ipv4.gateway '192.168.208.254' \
    ipv4.dns '192.168.208.254'

# restart interface
nmcli con down eth0 && nmcli con up eth0

exit 0
EOF

chmod +x /usr/local/sbin/network-con-recreate.sh

cat > ~/cron-network-con-recreate << EOF
* */1 * * * /bin/bash /usr/local/sbin/network-con-recreate.sh
EOF

crontab ~/cron-network-con-recreate
```

### 全局忽略.DS_Store
```
echo '.DS_Store' > ~/.gitignore_global

git config --global core.excludesfile ~/.gitignore_global

find . -name .DS_Store -print0 | xargs -0 git rm --ignore-unmatch

git commit -m "Remove .DS_Store from everywhere"

git push origin master
```

### Tunnelblick配置文件
```
```

### RHCOS定制文件系统和分区
参考：Red Hat Enterprise Linux CoreOS Eval Guide
```
Separate /var/log

  "storage": {
    "disks": [
      {
        "device": "/dev/sdb",
        "wipeTable": true,
        "partitions": [
          {
            "label": "LOG",
            "sizeMiB": 0,
            "startMiB": 0,
            "wipePartitionEntry": true
          }
        ]
        }
      }
    ],
    "filesystems": [
      {
        "mount": {
          "device": "/dev/sdb1",
          "format": "xfs",
          "label": "LOG",
          "wipeFilesystem": true
        }
      }
    ]
  },
    "systemd": {
     "units": [
       {
        "name": "var-log.mount",
        "enabled": true,
        "contents": "[Mount]\nWhat=/dev/sdb1\nWhere=/var/log\nType=xfs\nOptions=defaults\n[Install]\nWantedBy=local-fs.target"
       }
     ]
   }
}
```

### Mac查看监听端口
```
lsof -nP -iTCP -sTCP:LISTEN
```

### Homebrew and Homebrew Cask
参考：https://www.jianshu.com/p/fdfa9b8e29f8?utm_campaign=hugo&utm_medium=reader_share&utm_content=note

Homebrew
```
安装软件：brew install 软件名，例：brew install wget
搜索软件：brew search 软件名，例：brew search wget
卸载软件：brew uninstall 软件名，例：brew uninstall wget
更新所有软件：brew update
更新具体软件：brew upgrade 软件名 ，例：brew upgrade git
显示已安装软件：brew list
查看软件信息：brew info／home 软件名 ，例：brew info git ／ brew home git
显示包依赖：brew reps
显示安装的服务：brew services list
安装服务启动、停止、重启：brew services start/stop/restart serverName
```

Homebrew cask
```
brew cask install alfred
```

### Calico相关资料
Calico FAQ
https://docs.projectcalico.org/v3.5/usage/troubleshooting/faq

Kubernetes Networking with Calico
https://www.tigera.io/blog/kubernetes-networking-with-calico/

External connectivity
https://docs.projectcalico.org/networking/external-connectivity#outbound-connectivity

Calico over Ethernet fabrics
https://docs.projectcalico.org/reference/architecture/design/l2-interconnect-fabric

BGP Client, BGP Route Reflector and Centralized route distribution
https://docs.projectcalico.org/reference/architecture/overview#bgp-client-bird

### 解决虚拟机spice客户端显示blank screen的问题
参考：https://bugzilla.redhat.com/show_bug.cgi?id=1611625
```
TERM=linux setterm -blank 0 -powerdown 0  -powersave off >/dev/tty0 </dev/tty0
```

### 使用lvm snapshot 备份及恢复系统

新添加的磁盘/dev/sdb创建label，创建分区，设置分区类型为lvm
```
parted -s /dev/sdb mklabel msdos 
parted -s /dev/sdb unit mib mkpart primary 1 100%
parted -s /dev/sdb set 1 lvm on
```

创建pv
```
pvcreate /dev/sdb1
```

扩展vg
```
vgextend rhel /dev/sdb1
```

为逻辑卷/dev/rhel/root，创建lvm snapshot root_snap1
```
lvcreate --size 75G --snapshot --name root_snap1 /dev/rhel/root
```

更新系统...

如果需要回滚变更，可执行以下命令，然后重启系统恢复快照
```
lvconvert --merge /dev/rhel/root_snap1
yes | cp $(ls -1F -tr /boot/grub2/grub.cfg.*.rpmsave | head -1) /boot/grub2/grub.cfg
reboot 
```

### 从RHEL 7.6升级到RHEL8
```
subscription-manager register
subscription-manager attach --pool=XXXXXX
subscription-manager list --installed

subscription-manager repos --disable rhel-7-server-rpms --enable rhel-7-server-eus-rpms
subscription-manager repos --enable rhel-7-server-extras-rpms
subscription-manager release --set 7.6

yum update -y
reboot

yum install -y leapp
curl http://10.66.208.115/rhel7osp/leapp-data6.tar.gz -o /root/leapp-data6.tar.gz
tar -xzf leapp-data6.tar.gz -C /etc/leapp/files

# 升级前，事前分析
leapp preupgrade --debug 2>&1 | tee /tmp/leapp-preupgrade.log

# 根据分析报告内容/var/log/leapp/leapp-report.txt，执行以下命令解决升级冲突
sed -ie 's|^#PermitRootLogin yes|PermitRootLogin yes|' /etc/ssh/sshd_config

# 执行命令
leapp upgrade --debug 2>&1 | tee /tmp/leapp.log
```

### 使用本地软件仓库和leapp从RHEL7.5升级到RHEL8
```
mkdir -p /etc/yum.repos.d/backup
mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup

cat > /etc/yum.repos.d/w.repo << 'EOF'
[rhel-7-server-rpms]
name=rhel-7-server-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-rpms/
enabled=1
gpgcheck=0

[rhel-7-server-extras-rpms]
name=rhel-7-server-extras-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-extras-rpms/
enabled=1
gpgcheck=0

EOF

mkdir -p /leapp
yum install --downloadonly --downloaddir=/leapp leapp

yum upgrade -y audit audit-libs libselinux libselinux-python libselinux-utils  libsemanage libsepol policycoreutils

yum install -y audit-libs-python bzip2 checkpolicy dnf dnf-data json-c json-glib leapp-deps libcgroup libcomps libdnf libmodulemd librepo libreport-filesystem librhsm libsemanage-python libsmartcols libsolv libyaml pciutils policycoreutils-python python-IPy python-babel python-backports python-backports-ssl_match_hostname python-enum34 python-ipaddress python-jinja2 python-markupsafe python-setuptools python2-dnf python2-futures python2-hawkey python2-leapp python2-libcomps python2-libdnf setools-libs 

pushd /leapp
rpm -ivh leapp-0.9.0-1.el7.noarch.rpm leapp-repository-0.9.0-4.el7.noarch.rpm leapp-repository-deps-0.9.0-4.el7.noarch.rpm leapp-repository-sos-plugin-0.9.0-4.el7.noarch.rpm sos-3.8-6.el7.noarch.rpm --force

popd
curl http://10.66.208.115/rhel7osp/leapp-data6.tar.gz -o /root/leapp-data6.tar.gz
tar -xzf leapp-data6.tar.gz -C /etc/leapp/files

cat >> /etc/yum.repos.d/w.repo << 'EOF'
[BASEOS]
name=BASEOS
baseurl=http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-baseos-rpms/
enabled=0
gpgcheck=0

[APPSTREAM]
name=APPSTREAM
baseurl=http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-appstream-rpms/
enabled=0
gpgcheck=0

EOF

export LEAPP_UNSUPPORTED=1
export LEAPP_DEVEL_SKIP_RHSM=1

yum install -y snactor
cd /usr/share/leapp-repository/repositories/system_upgrade/el7toel8/actors
snactor new-actor --produces CustomTargetRepository --tag IPUWorkflowTag --tag FactsPhaseTag CustomRepoActor

cp /usr/share/leapp-repository/repositories/system_upgrade/el7toel8/actors/customrepoactor/actor.py /usr/share/leapp-repository/repositories/system_upgrade/el7toel8/actors/customrepoactor/actor.py.sav

sed -ie "/(self):/a \ \ \ \ \ \ \ \ self.produce(CustomTargetRepository(repoid='APPSTREAM', name='APPSTREAM', baseurl='http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-appstream-rpms/'))" /usr/share/leapp-repository/repositories/system_upgrade/el7toel8/actors/customrepoactor/actor.py

sed -ie "/(self):/a \ \ \ \ \ \ \ \ self.produce(CustomTargetRepository(repoid='BASEOS', name='BASEOS', baseurl='http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-baseos-rpms/'))" /usr/share/leapp-repository/repositories/system_upgrade/el7toel8/actors/customrepoactor/actor.py

# 参考https://docs.google.com/document/d/1MuyO9PN9sFU0r2r01t6-OXi6RK0l1pqTFfi_UkIeGtc/edit里的步骤添加
# 编辑/usr/share/leapp-repository/repositories/system_upgrade/el7toel8/actors/customrepoactor/actor.py
#    def process(self):
#        self.produce(CustomTargetRepository(repoid='BASEOS', name='BASEOS', baseurl='http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-baseos-rpms/'))
#        self.produce(CustomTargetRepository(repoid='APPSTREAM', name='APPSTREAM', baseurl='http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-appstream-rpms/'))
#        pass

# 升级前，事前分析
LEAPP_UNSUPPORTED=1 LEAPP_DEVEL_SKIP_RHSM=1 leapp preupgrade --debug 2>&1 | tee /tmp/leapp-preupgrade.log

# 根据分析报告内容/var/log/leapp/leapp-report.txt，执行以下命令解决升级冲突
sed -ie 's|^#PermitRootLogin yes|PermitRootLogin yes|' /etc/ssh/sshd_config

# 卸载btrfs驱动
rmmod btrfs

# mv efibootorderfix actors to /tmp
mv /usr/share/leapp-repository/repositories/system_upgrade/el7toel8/actors/efibootorderfix/ /tmp/

# 升级
LEAPP_DEVEL_SKIP_RHSM=1 leapp upgrade --debug 2>&1 | tee /tmp/leapp-upgrade.log
```

### convert2rhel workthrough
参考链接：https://access.redhat.com/articles/2360841

```
nmcli con mod 'eth0' ipv4.method 'manual' ipv4.address 'X.X.X.X/24' ipv4.gateway 'Y.Y.Y.Y' ipv4.dns 'Z.Z.Z.Z'

mkdir -p /isos
pushd isos
curl http://pek-iso.usersys.redhat.com/iso_centos/CentOS-7-x86_64-DVD-1810.iso -o CentOS-7-x86_64-DVD-1810.iso
curl http://pek-iso.usersys.redhat.com/iso_rhel/rhel-server-7.7-x86_64-dvd.iso -o rhel-server-7.7-x86_64-dvd.iso

mkdir -p /mnt/{centos,rhel}
mount -o loop /isos/CentOS-7-x86_64-DVD-1810.iso /mnt/centos
mount -o loop /isos/rhel-server-7.7-x86_64-dvd.iso /mnt/rhel

mkdir -p /etc/yum.repos.d/backup
yes | mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup

cat > /etc/yum.repos.d/centos.repo << 'EOF'
[centos-7-server-rpms-6]
name=centos-7-server-rpms-6
baseurl=file:///mnt/centos
enabled=1
gpgcheck=0
EOF

cat > /etc/yum.repos.d/rhel.repo << 'EOF'
[rhel-7-server-rpms-7]
name=rhel-7-server-rpms-7
baseurl=file:///mnt/rhel
enabled=0
gpgcheck=0
EOF

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum install -y convert2rhel

yum-config-manager --disable epel

yum update -y

reboot

mount -o loop /isos/CentOS-7-x86_64-DVD-1810.iso /mnt/centos
mount -o loop /isos/rhel-server-7.7-x86_64-dvd.iso /mnt/rhel
convert2rhel --disable-submgr --disablerepo "*" --enablerepo rhel-7-server-rpms-7 -v Server -y --debug 2>&1 | tee /tmp/convert2rhel.log

[04/21/2020 13:50:35] TASK - [Prepare: End user license agreement] ******************************
[04/21/2020 13:50:35] TASK - [Prepare: Gather system information] *******************************
[04/21/2020 13:51:08] TASK - [Prepare: Determine RHEL variant] **********************************
[04/21/2020 13:51:08] TASK - [Prepare: Backup System] *******************************************
[04/21/2020 13:51:08] TASK - [Convert: Remove blacklisted packages] *****************************
[04/21/2020 13:51:14] TASK - [Convert: Install Red Hat release package] *************************
[04/21/2020 13:51:14] TASK - [Convert: Patch yum configuration file] ****************************
[04/21/2020 13:51:14] TASK - [Convert: Package analysis] ****************************************
[04/21/2020 13:51:14] TASK - [Convert: Check required repos] ************************************
[04/21/2020 13:51:16] TASK - [Convert: Prepare kernel] ******************************************
[04/21/2020 13:52:32] TASK - [Convert: Replace packages] ****************************************
[04/21/2020 13:55:11] TASK - [Convert: List remaining non-Red Hat packages] *********************
[04/21/2020 13:55:11] TASK - [Final: Non-interactive mode] **************************************

[root@unused ~]# rpm -qa --qf '%{NAME} %{VENDOR}\n' | grep -Ev 'Red Hat' 
yum-plugin-fastestmirror CentOS
gpg-pubkey (none)
convert2rhel Fedora Project
epel-release Fedora Project

reboot
yum remove gpg-pubkey
yum remove yum-plugin-fastestmirror

```

### 安装测试虚拟机
虚拟机使用raw format磁盘，总线为scsi，驱动对应virtio-scsi，通过字符界面安装
```
virt-install --name="jwang-testvm" --vcpus=2 --ram=4096 \
--disk path=/var/lib/libvirt/images/jwang-test-01.img,format=raw,bus=scsi,size=20 \
--os-variant rhel7.0 \
--boot menu=on \
--location /var/lib/libvirt/images/isos/rhel-server-7.6-x86_64-dvd.iso \
--graphics none \
--console pty,target_type=serial --extra-args='console=ttyS0'
```

如果在安装时希望使用kickstart文件，可以参考下面的例子
```
virt-install --name="jwang-testvm" --vcpus=2 --ram=4096 \
--disk path=/var/lib/libvirt/images/jwang-test-01.img,format=raw,bus=scsi,size=20 \
--os-variant rhel7.0 \
--boot menu=on \
--location /var/lib/libvirt/images/isos/rhel-server-7.6-x86_64-dvd.iso \
--graphics none \
--network bridge:virbr0 \
--console pty,target_type=serial \
--initrd-inject /tmp/ks.cfg \
--extra-args='ks=file:/ks.cfg console=ttyS0'
```

### Minimal rhel7 kickstart example file
参考：https://gist.github.com/devynspencer/99cbcf0b09245e285ee4
```
cat > /tmp/ks.cfg << 'EOF'
#version=RHEL7
ignoredisk --only-use=sda

# Partition clearing information
clearpart --all

# Use text install
text

# System language
lang en_US.UTF-8

# Keyboard layouts
keyboard us

# Network information
network --bootproto=static --device=eth0 --ip=192.168.122.122 --netmask 255.255.255.0 --gateway=192.168.122.1 --hostname=jwangtest.example.com

# Root password
rootpw --iscrypted $6$q9HNZaOm8rO91oRR$eSWRwR7Hc9FBRlcEm83EiJx8MeFUQJXd.33YVDjzXkgCTiY3gcMHOvDtI6wh35Zw9.7Ql6rAo9tEZpo3y7Uy6/

# Run the Setup Agent on first boot
firstboot --enable

# Do not configure the X Window System
skipx

# System timezone
timezone Asia/Shanghai --isUtc

# Agree EULA
eula --agreed

# System services
services --enabled=NetworkManager,sshd

# Reboot after installation completes
reboot

# Disk partitioning information
autopart --type=lvm --fstype=xfs

%packages --nobase --ignoremissing --excludedocs
@core
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
EOF
```

### blktrace用法
参见：https://tunnelix.com/debugging-disk-issues-with-blktrace-blkparse-btrace-and-btt-in-linux-environment/
https://www.ibm.com/support/knowledgecenter/linuxonibm/com.ibm.linux.z.ldsg/ldsg_t_iodata_remote.html
https://www.hwchiu.com/blktrace-example.html
http://linuxperf.com/?p=161


服务器端
```
blktrace -l
```

客户端
```
blktrace -h <server_ip> -d <device>
e.g.
blktrace -h 10.72.32.50 -d /dev/sda
```

客户端执行i/o操作，然后服务器端退出blktrace服务端

在服务端查看blktrace产生的事物日志
```
blkparse -D 10.72.32.49-2020-05-06-12:42:33/ sda -d events.bin > events.txt
```


### Mac下直播软件OBS的设置
https://www.jianshu.com/p/ecfaac6ee7ab<br>
https://blog.csdn.net/lk142500/article/details/91491299<br>

### 什么是Systemtap，如何使用Systemtap
https://access.redhat.com/articles/882463

systemtap运行需要哪些软件包
```
systemtap, systemtap-runtime
gcc
kernel-devel, kernel-debuginfo, kernel-debuginfo-common
```

### 在Mac上启动 Web Server
```
python -m SimpleHTTPServer 8000
```

### 使用dropwatch分析drop包
参考：https://access.redhat.com/solutions/206223
``` 
1. 安装dropwatch和安装客户环境一致的内核包
# yum install -y kernel-3.10.0-957.el7
# yum install dropwatch -y
 
离线安装
# yum localinstall -y dropwatch-1.4-9.el7.x86_64.rpm
 
2. 重启系统
# systemctl reboot
 
3. 安装 debuginfo 包
# yum install -y kernel-debuginfo-3.10.0-957.el7 kernel-debuginfo-common-3.10.0-957.el7
 
离线安装
# yum localinstall -y kernel-debuginfo-3.10.0-957.el7.x86_64.rpm kernel-debuginfo-common-x86_64-3.10.0-957.el7.x86_64.rpm
 
4. 查看网卡信息：
[root@rhel7u5 ~]# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.72.37.29  netmask 255.255.254.0  broadcast 10.72.37.255
        inet6 fe80::21a:4aff:fe16:730  prefixlen 64  scopeid 0x20<link>
        inet6 2620:52:0:4824:21a:4aff:fe16:730  prefixlen 64  scopeid 0x0<global>
        ether 00:1a:4a:16:07:30  txqueuelen 1000  (Ethernet)
        RX packets 2618  bytes 560244 (547.1 KiB)
        RX errors 0  dropped 5  overruns 0  frame 0
        TX packets 721  bytes 106800 (104.2 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
 
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 48  bytes 3600 (3.5 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 48  bytes 3600 (3.5 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
 
ip -s link show 
 
5. 抓取 dropwatch 信息
[root@rhel7u5 ~]# dropwatch -l kas
Initalizing kallsyms db
dropwatch> start
Enabling monitoring...
Kernel monitoring activated.
Issue Ctrl-C to stop monitoring
1 drops at skb_queue_purge+18 (0xffffffff88a235d8)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
1 drops at skb_queue_purge+18 (0xffffffff88a235d8)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
1 drops at nf_hook_slow+f3 (0xffffffff88a785e3)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
1 drops at skb_queue_purge+18 (0xffffffff88a235d8)
1 drops at ip_rcv_finish+1d4 (0xffffffff88a82604)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
2 drops at skb_queue_purge+18 (0xffffffff88a235d8)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
1 drops at ip_rcv_finish+1d4 (0xffffffff88a82604)
1 drops at skb_queue_purge+18 (0xffffffff88a235d8)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
1 drops at __brk_limit+36c27a68 (0xffffffffc06a1a68)
^CGot a stop message
dropwatch> exit
Shutting down ...
[root@rhel7u5 ~]#
 
 
6. 把 dropwatch 的输出放入 dropwatch.txt 文件：
[root@rhel7u5 ~]# vim dropwatch.txt
[root@rhel7u5 ~]# awk '/drops at/ {t[$4" "$5]+=$1} END {for (n in t) print t[n], n}' dropwatch.txt | sort -rn
12 __brk_limit+36c27a68 (0xffffffffc06a1a68)
6 skb_queue_purge+18 (0xffffffff88a235d8)
2 ip_rcv_finish+1d4 (0xffffffff88a82604)
1 nf_hook_slow+f3 (0xffffffff88a785e3)
 
 
7. 用 eu-addr2line 查看地址对应的函数：
 
[root@rhel7u5 ~]# yum install elfutils -y
 
[root@rhel7u5 ~]# eu-addr2line -f -k 0xffffffff88a235d8
skb_queue_purge
net/core/skbuff.c:2550
[root@rhel7u5 ~]# printf "%x\n" $((0xffffffff88a235d8+0x18))
ffffffff88a235f0
 
[root@rhel7u5 ~]# eu-addr2line -f -k 0xffffffff88a235f0
skb_complete_wifi_ack
net/core/skbuff.c:3919
 
8. 查看当前的网卡信息:
 
[root@rhel7u5 ~]# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.72.37.29  netmask 255.255.254.0  broadcast 10.72.37.255
        inet6 fe80::21a:4aff:fe16:730  prefixlen 64  scopeid 0x20<link>
        inet6 2620:52:0:4824:21a:4aff:fe16:730  prefixlen 64  scopeid 0x0<global>
        ether 00:1a:4a:16:07:30  txqueuelen 1000  (Ethernet)
        RX packets 319659  bytes 569255807 (542.8 MiB)
        RX errors 0  dropped 5  overruns 0  frame 0
        TX packets 224358  bytes 19487629 (18.5 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
 
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 48  bytes 3600 (3.5 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 48  bytes 3600 (3.5 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

```

### wireshark过滤规则
过滤掉 nfs, arp, http, vrrp 和 tcp 的包可以把过滤器定义成
```
!nfs and !arp and !http and !vrrp and !tcp
```

只保留LACP包
```
lacp
```

### 分析丢包问题的方法
参考：<br>
https://access.redhat.com/solutions/2194511<br>
https://access.redhat.com/articles/1311173<br>
https://access.redhat.com/solutions/3684651

```
1. 安装如下rpm包：

    kernel-devel - 和当前的内核相同版本
    kernel-debuginfo - 和当前的内核相同版本
    kernel-debuginfo-common - 和当前的内核相同版本
    gcc
    systemtap


# yum install kernel-debuginfo-3.10.0-957.el7 kernel-devel-3.10.0-957.el7 kernel-debuginfo-common-x86_64-3.10.0-957.el7 gcc

[root@rhel7u5 ~]# rpm -qa | egrep "kernel-debuginfo|kernel-devel"
kernel-debuginfo-3.10.0-957.el7.x86_64
kernel-devel-3.10.0-957.el7.x86_64
kernel-debuginfo-common-x86_64-3.10.0-957.el7.x86_64

[root@rhel7u5 ~]# uname -r
3.10.0-957.el7.x86_64

2. 执行 stap-prep：
[root@rhel7u5 ~]# stap-prep
[root@rhel7u5 ~]#

3. 创建dropwatch2.stp文件：https://access.redhat.com/solutions/2194511
   创建monitor.sh文件：https://access.redhat.com/articles/1311173
https://access.redhat.com/solutions/3684651

4. 同时在另外的两个terminal执行 monitor.sh 和 tcpdump:
[terminal 1]
./monitor.sh -d 2

[terminal 2]
# tcpdump -i ens4 -w /tmp/vm_$(hostname)-$(date +"%Y-%m-%d-%H-%M-%S").pcap

5. 执行netstat -in查看当前的RX-DRP状态

6. 执行 stap 脚本：
[root@rhel7u5 ~]# stap --all-modules -o /tmp/dropwatch2.log dropwatch2.stp

7.执行netstat -in查看测试后的RX-DRP状态

8.收集信息：
monitor.sh:
# tar cvzf net_stats_$(hostname)-$(date +"%Y-%m-%d-%H-%M-%S").tgz *network_stats_*

tcpdump:
/tmp/vm_*

dropwatch2:
/tmp/dropwatch2.log
```

### tcpdump抓包来定位rxdrop问题时如果rxdrop计数器仍然增长的处理方法
运行dropwatch2.stap的同时执行tcpdump，确认netstat -in输出里的rxdrop不再增长

### 使用cgroup限制blkio
https://andrestc.com/post/cgroups-io/

### 使用virsh设置块设备IO限流
https://fedoraproject.org/wiki/QA:Testcase_Virtualization_IO_Throttling
```
virsh blkdeviotune f18 vda
virsh blkdeviotune f18 vda --write_bytes_sec $(expr 1024 \* 1024 \* 10)
virsh blkdeviotune f18 vda
```

### 使用cgroup和systemctl设置虚拟机cpu
为某个虚拟机设置CPUQuota
```
tmpfile=$(mktemp /tmp/tmpXXXXXX)
systemd-cgls | grep machine-qemu | grep test | sed -e 's#| |-##' -e 's#| `-##' | while read i 
do
  echo systemctl set-property --runtime "'"$i"'" CPUQuota=10%
done | tee $tmpfile
sed -ie 's|x2d|\\x2d|g' $tmpfile

sh -x $tmpfile
rm -f $tmpfile
```

### 在ovirt node上执行virsh blkdeviotune
查看virsh blkdeviotune
```
prog=/usr/bin/virsh
myuser="vdsm@ovirt"
mypass="shibboleth"

args=" blkdeviotune jwang-zyjk-01 sda"
/usr/bin/expect <<EOF
set timeout -1
spawn "$prog" $args
expect "Please enter your authentication name: "
send "$myuser\r"
expect "Please enter your password:"
send "$mypass\r"
expect eof
exit
EOF
```

设置 virsh blkdeviotune 虚拟机 jwang-zyjk-01 的硬盘 sda 每秒写入字节为 10M `
```
prog=/usr/bin/virsh
myuser="vdsm@ovirt"
mypass="shibboleth"

args=" blkdeviotune jwang-zyjk-01 sda --write_bytes_sec $(expr 1024 \* 1024 \* 10)"
/usr/bin/expect <<EOF
set timeout -1
spawn "$prog" $args
expect "Please enter your authentication name: "
send "$myuser\r"
expect "Please enter your password:"
send "$mypass\r"
expect eof
exit
EOF
```

### 用tshark查看包的内容
```
# 查看有哪些包
tshark -r /tmp/pcap.ip6 

# 查看包的详情
tshark -r /tmp/pcap.ip6  -x -Y "frame.number==658"  -V
```

### quipudocs 的使用
https://quipucords.github.io/quipudocs/user.html#con-what-is-prod-common_assembly-about-common-ctxt

```
# 生成 repo 配置
cat > /etc/yum.repos.d/public.repo << 'EOF'
[rhel-7-server-rpms]
name=rhel-7-server-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-rpms
gpgcheck=0
enabled=1

[rhel-7-server-extras-rpms]
name=rhel-7-server-extras-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-extras-rpms
gpgcheck=0
enabled=1

EOF

# 在线安装 qpc-tools
yum install https://github.com/quipucords/qpc-tools/releases/latest/download/qpc-tools.el7.noarch.rpm

# qpc server install
qpc-tools server install

# qpc client install
qpc-tools cli install

# config server
qpc server config --host 10.66.208.160
# Server config /root/.config/qpc/server.config was not found.
# Server connectivity was successfully configured. The server will be contacted via "https" at host "10.66.208.160" with port "9443".

# login into server
qpc server login

# add cred
qpc cred add --type network --name qpcnetworksource --username qpctester --password --become-method su --become-user root --become-password
qpc cred add --type network --name cred_rhvhost --username root --password

# add source
qpc source add --type network --name registry --hosts 10.66.208.115 --cred qpcnetworksource
qpc source add --type network --name source_rhvhost --hosts 10.66.208.[51:53] --cred cred_rhvhost

# add scan
qpc scan add --name scan_registry1 --sources registry
qpc scan add --name scan_rhvhost1 --sources source_rhvhost

# run scan
qpc scan start --name scan_registry1
qpc scan start --name scan_rhvhost1

# view scan
qpc scan job --id 1
qpc scan list
qpc scan job --name scan_registry1

qpc scan job --id 2
qpc scan list
qpc scan job --name scan_rhvhost1

# download scan report
qpc report download --scan-job 1 --output-file=~/scan_output.tar.gz
qpc report download --scan-job 2 --output-file=~/scan_output_rhvhost.tar.gz
```

### Prometheus查询
参考：https://redhat-developer-demos.github.io/istio-tutorial/istio-tutorial/1.4.x/3monitoring-tracing.html

```
istio_requests_total{destination_service="recommendation.tutorial.svc.cluster.local"}
container_memory_rss{namespace="tutorial",container=~"customer|preference|recommendation"}
```

### 常见的pipeline包含哪些步骤
```
Build
Unit Test
Static Code Scan/Security Scan
Packaging/Publishing of Artifacts
Deploying
End to End Tests
Performance Tests
```

### Istio w/ jwt-authz
http://lab-ossm-labguides.6923.rh-us-east-1.openshiftapps.com/workshop/authentication<br>
https://istio.io/latest/docs/tasks/security/authorization/authz-jwt/

### Kiali's Graph
http://lab-ossm-labguides.6923.rh-us-east-1.openshiftapps.com/workshop/authentication

```
Within the Kiali UI select the Graph option from the left hand navigation and then choose

Namespace: -tutorial
Versioned app graph
Requests percentage
Last 1m
Every 10s
```

### Service Mesh Role Based Access Control (RBAC)
http://lab-ossm-labguides.6923.rh-us-east-1.openshiftapps.com/workshop/authentication

RbacConfig objects are used to enable and configure Authorization in the service mesh. Take a look at the following YAML:

```
apiVersion: "rbac.istio.io/v1alpha1"
kind: RbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["-tutorial"]
```

### [转发]开放分布式追踪（OpenTracing）入门与 Jaeger 实现
https://yq.aliyun.com/articles/514488

https://www.jianshu.com/p/bd11294cf83e


### 如何降低lvm thinpool meta占用率
```
lvs -a -o +devices
df -h 
fstrim -v <device_mount_point> e.g.
fstrim -v /
```

### 检查nfs的io状态
利用nfsstat和nfsiostat工具检查nfs延时
https://www.redhat.com/sysadmin/using-nfsstat-nfsiostat

### 重置crio存储

```
-------------------------------------------------------
crio storage reset
-------------------------------------------------------

oc adm cordon $NODENAME

oc adm drain $NODENAME --ignore-daemonsets=true --delete-local-data=true


--on the worker node----

systemctl stop kubelet.service 

crictl stop $(crictl ps -q)

systemctl stop crio.service
systemctl stop crio-*


rm -rf /var/lib/containers/storage/*


systemctl start crio.service
systemctl start kubelet.service

--/------------------

oc adm uncordon $NODENAME

With the above, I was able to clear and repopulate all the images and containers.
```

### 如何针对OSP做CI/CD
https://mojo.redhat.com/community/communities-at-red-hat/infrastructure/cloud-platforms-community-of-practice/blog/2019/08/19/deploy-different-a-customer-tale-of-cicd-on-osp13

### virt-install的例子
https://raymii.org/s/articles/virt-install_introduction_and_copy_paste_distro_install_commands.html

### 启用windows远程桌面
https://support.microsoft.com/en-us/help/4028379/windows-10-how-to-use-remote-desktop

### 安装virtualbox extension pack
https://www.nakivo.com/blog/how-to-install-virtualbox-extension-pack/

### rhel8 安装 virsh
dnf install libvirt-client

### rhel8 virsh 禁用网络自动启动
virsh net-autostart --network default --disable

### cinder filters and weighters
openstack cinder 可以通过 filters 和 weighters 来选择后端存储，以下内容来自 Advanced Storage for OpenStack Storage 培训

```
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf DEFAULT  scheduler_default_filters AvailabilityZoneFilter,CapacityFilter,CapabilitiesFilter,DriverFilter
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf tripleo_ceph filter_function "volume.size >= 5"
sed -i 's/volume.size >= 5/"volume.size >= 5"/g' /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf tripleo_nfs filter_function "volume.size < 5"
sed -i 's/volume.size < 5/"volume.size < 5"/g' /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf
crudini --del  /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf tripleo_ceph goodness_function
crudini --del  /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf tripleo_nfs goodness_function

cat /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf | grep -Ev "^$|^#" 
cat /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf | grep scheduler_default_filters

# restart cinder services on the controller
systemctl restart tripleo_cinder_scheduler.service tripleo_cinder_api_cron.service tripleo_cinder_api.service

podman ps | grep cinder

# restart cinder volume service on the controller
pcs resource restart openstack-cinder-volume

# remove filter funtion and add goodness funtion
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf DEFAULT  scheduler_default_weighers GoodnessWeigher
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf DEFAULT  scheduler_weight_handler cinder.scheduler.weights.OrderedHostWeightHandler
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf tripleo_ceph goodness_function 50
sed -i 's/goodness_function = 50/goodness_function = "50"/g' /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf tripleo_nfs goodness_function "(volume.size > 5) ? 100 : 40"
sed -i 's/(volume.size > 5) ? 100 : 40/"(volume.size > 5) ? 100 : 40"/g' /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf
crudini --del  /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf tripleo_ceph filter_function
crudini --del  /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf tripleo_nfs filter_function

cat /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf | grep -Ev "^$|^#" 
cat /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf | grep scheduler_default_weighers
cat /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf | grep scheduler_default_filters


# restart cinder services on the controller
systemctl restart tripleo_cinder_scheduler.service tripleo_cinder_api_cron.service tripleo_cinder_api.service

podman ps | grep cinder

# restart cinder volume service on the controller
pcs resource restart openstack-cinder-volume

# delete all volumes in test env
openstack volume list --status available -c ID -f value | xargs openstack volume delete
```

### How do I configure OpenStack with Ceph?
https://access.redhat.com/solutions/2625991

### add/remove openstack server floating ip from server
```
openstack server add floating ip <server> <ip>
openstack server remove floating ip <server> <ip>
```

### 为glance image进行签名
```
## Generate a openssl key to be used for signing
# Generate private key
openssl genrsa -out private_key.pem 1024

# Generate public key from private key
openssl rsa -pubout -in private_key.pem -out public_key.pem

# Create a certification request (CSR)
openssl req -new -key private_key.pem -out cert_request.csr -subj "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT/CN=openstack.example.com"

# Generate certification from the CSR
openssl x509 -req -days 14 -in cert_request.csr -signkey private_key.pem -out x509_signing_cert.crt

## Create a new secret inside Barbican using the generated SSL cert.
openstack secret store --name signing-cert --algorithm RSA --secret-type certificate --payload-content-type "application/octet-stream" --payload-content-encoding base64  --payload "$(base64 x509_signing_cert.crt)" -c 'Secret href' -f value
# http://10.0.0.150:9311/v1/secrets/ef0a16ba-ed44-4b59-939c-42e053c29ac6

## Use private_key.pem to sign the image and generate the .signature file. Copy the private_key.pem and x509_signing_cert.crt from controller01 to undercloud
# wget https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openssl dgst -sha256 -sign private_key.pem -sigopt rsa_padding_mode:pss -out cirros-0.4.0.signature cirros-0.4.0-x86_64-disk.img

## Convert signature to Base64 and store the information in one variable.
base64 -w 0 cirros-0.4.0.signature  > cirros-0.4.0.signature.b64
cirros_signature_b64=$(cat cirros-0.4.0.signature.b64)

## Upload the image with the proper parameters
openstack image create --container-format bare --disk-format qcow2 --property img_signature="$cirros_signature_b64" --property img_signature_certificate_uuid='ef0a16ba-ed44-4b59-939c-42e053c29ac6' --property img_signature_hash_method='SHA-256' --property img_signature_key_type='RSA-PSS' cirros_0_4_0_signed < cirros-0.4.0-x86_64-disk.img
```

### rbd mirror practice
https://github.com/MiracleMa/Blog/issues/2

### 创建6个3gb的卷，让filters和weighters帮助选择合适的volume backend
```
for i in `seq 1 6` ; do openstack volume delete 3gb-vol-0$i ; done 
for i in `seq 1 6` ; do openstack volume create --size 3 3gb-vol-0$i ; done
for i in `seq 1 6` ; do openstack volume show 3gb-vol-0$i | grep os-vol-host-attr ; done 
```

### 什么是Group-Version和Kind-Resource
https://book.kubebuilder.io/cronjob-tutorial/gvks.html

### Ceph 和 SDD HDD Pool
Ceph: mix SATA and SSD within the same box<br>
这个时候主要还是通过人工编辑crush完成的<br>
https://www.sebastien-han.fr/blog/2014/08/25/ceph-mix-sata-and-ssd-within-the-same-box/<br>

通过把 crush rule 和 device class 关联，pool 和 crush rule 关联实现 pool 到 device class 的映射<br>
https://www.bookstack.cn/read/zxj_ceph/crush-class 

### What's new in RHEL8
What’s new in RHEL 8 file systems and storage<br>
https://www.redhat.com/en/blog/whats-new-rhel-8-file-systems-and-storage

What’s new in RHEL 8.1: Kernel patching, more Insights, and right on time<br>
https://www.redhat.com/en/blog/whats-new-rhel-81-kernel-patching-more-insights-and-right-time

Red Hat expands coverage of CVE fixes<br>
https://www.redhat.com/en/blog/red-hat-expands-coverage-cve-fixes

Generate SELinux policies for containers with Udica<br>
https://www.redhat.com/en/blog/generate-selinux-policies-containers-with-udica

Using the rootless containers Tech Preview in RHEL 8.0<br>
https://www.redhat.com/en/blog/using-rootless-containers-tech-preview-rhel-80<br>
https://www.redhat.com/en/blog/preview-running-containers-without-root-rhel-76<br>

### 配置 kvm usb passthrough
https://blog.csdn.net/weixin_33716557/article/details/85104312

### cinderlib 的演示
https://asciinema.org/a/TcTR7Lu7jI0pEsd9ThEn01l7n?autoplay=1

### 检查 corosync 状态
```
corosync-cfgtool -s
```

### 调整 totem token timeout
https://access.redhat.com/solutions/221263

查看corosync心跳链路状态
```
corosync-cfgtool -s
```

查看corosync日志
```
cat /var/log/cluster/corosync.log
```

调整corosync totem token timeout，编辑/etc/corosync/corosync.conf文件
```
totem {
    version: 2
    cluster_name: tripleo_cluster
    transport: knet
    crypto_cipher: aes256
    crypto_hash: sha256
    token: 30000                          # add this line
}
```

让上面的调整生效，在每个节点上编辑corosync.conf文件，添加token，然后执行
```
pcs cluster reload corosync
```

检查修改结果
```
corosync-cmapctl | grep totem | grep token 
```

确认节点心跳状态
```
corosync-cfgtool -s
```

https://www.thegeekdiary.com/how-to-change-pacemaker-cluster-heartbeat-timeout-in-centos-rhel-7/

### OpenShift Virtualization 支持 UEFI
OpenShift Virtualization and UEFI 支持
 
需要让 virt-handler 和 virt-launcher pod 里有 UEFI 所需的 firmware
 
So just for testing I did this...
```
$ oc exec -it virt-handler-hxdvs bash
# rpm -ivh http://mirror.centos.org/centos/7/os/x86_64/Packages/OVMF-20180508-6.gitee3198e672e2.el7.noarch.rpm
# ln -sf /usr/share/OVMF/OVMF_CODE.secboot.fd /usr/share/OVMF/OVMF_CODE.fd
```

Then started a VM with-
```
firmware:
         bootloader:
           efi: {}
```

It'll fail, because virt-launcher pod won't have the symlink (but will have the RPM), so I...
```
$  oc exec -it virt-launcher-example-qv5nw bash
# ln -sf /usr/share/OVMF/OVMF_CODE.secboot.fd /usr/share/OVMF/OVMF_CODE.fd
# virsh start openshift-cnv_example
```

So what we really need is the OVMF ROM's inside of the virt-launcher/virt-handler pods as shipped then it'll just work out of the box

### 如何用好 Bash 的变量替换
How To Use Bash Parameter Substitution Like A Pro<br>
https://www.cyberciti.biz/tips/bash-shell-parameter-substitution-2.html

### 修改 ssh config 不再进行严格的 HostKey 检查
```
cat > ~/.ssh/config << 'EOF'
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null  
EOF
``` 

### 在 rhel7 上启用 software collection 软件频道并且安装 maven 3.0 
https://www.softwarecollections.org/en/scls/rhscl/maven30/

```
# On RHEL, enable RHSCL repository for you system:
sudo yum-config-manager --enable rhel-server-rhscl-7-rpms

# 2. Install the collection:
$ sudo yum install maven30

# 3. Start using the software collection:
$ scl enable maven30 bash

# At this time you should be able to use maven as a normal application. Some available command examples follow:
$ mvn --version
$ mvn package
$ mvn clean dependency:copy-dependencies package
$ mvn site
```

### 遇到不支持 STP 的设备，记得关闭 bridge.stp
在实验室里的设备不支持 STP，默认 bridge.stp 是启用的，因此创建的 bridge 跟外面无法通信。
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-network_bridging_using_the_networkmanager_command_line_tool_nmcli
```
nmcli con modify bridge-br0 bridge.stp no
```

### OpenShift Cheatsheet
http://www.mastertheboss.com/soa-cloud/openshift/openshift-cheatsheet

### ssh client config 可以让 ssh 访问快起来
根据需要配置
```
cat > ~/.ssh/config << 'EOF'
Host *
  StrictHostKeyChecking no
  CheckHostIP no
  VerifyHostKeyDNS no
  GSSAPIAuthentication no
EOF
``` 

### 为 ovirt 虚拟机设置磁盘 QoS 
```
tmpfile=$(mktemp /tmp/tmpXXXXXX)

for domain in $(virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf list | grep testvm | awk '{print $2}')
do
    if [ x$domain == 'x' ]; then
        exit 0
    else    
        for device in $(virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf domblklist ${domain} | awk '{print $1}')
        do
            echo virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf blkdeviotune ${domain} ${device} --write_bytes_sec $(expr 1024 \* 1024 \* 1)
        done
    fi
done | tee $tmpfile
sh -x $tmpfile
rm -f $tmpfile
```

### 为 ovirt 虚拟机设置网络 QoS
http://manpages.ubuntu.com/manpages/trusty/man1/virsh.1.html
```
tmpfile=$(mktemp /tmp/tmpXXXXXX)

for domain in $(virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf list | grep testvm | awk '{print $2}')
do
    if [ x$domain == 'x' ]; then
        exit 0
    else
       for device in $(virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf domiflist ${domain} | grep -E "^vnet" | awk '{print $1}')
       do
            SPEED=$(expr 1024 \* 10)
            echo virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf domiftune ${domain} ${device} --live --inbound ${SPEED},${SPEED},${SPEED} --outbound ${SPEED},${SPEED},${SPEED}
       done
    fi
done | tee $tmpfile
sh -x $tmpfile
rm -f $tmpfile
```