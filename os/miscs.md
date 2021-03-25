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

### 在 ovirt hypervisor 上执行 virsh 命令
可指定认证文件 authfile=/etc/ovirt-hosted-engine/virsh_auth.conf 
```
virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf list
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

### 实验环境 AMQ Broker 和 AMQ Broker Maven
https://www.opentlc.com/labs/amq/amq-broker-7.6.0-bin.zip<br>
https://www.opentlc.com/labs/amq/amq-broker-7.6.0-maven-repository.zip<br>

### 更新 ovirt 管理员密码
https://access.redhat.com/solutions/63677<br>
```
ovirt-aaa-jdbc-tool user password-reset admin --password-valid-to="2055-08-01 12:00:00Z"
```

### 设置 irssi 登陆时自动加入 channel
https://irssi.org/documentation/startup/#server-and-channel-automation<br>
```
/CHANNEL ADD -auto #secret IRCnet password
```

### 离线安装 qpc 
```
# upload QPC package
scp ~/Downloads/QPC\ Dependencies_76.zip root@<qpcserverip>:~
scp ~/Downloads/quipucords_server_image.tar.gz root@<qpcserverip>:~
scp ~/Downloads/postgres.9.6.10.tar root@<qpcserverip>:~

# log into qpcserver
ssh root@<qpcserverip>

# define repo
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

# prepare qpc content
mkdir /root/qpc
cd /root/qpc
mv /root/quipucords_server_image.tar.gz .
mv /root/postgres.9.6.10.tar .

# install unzip and unzip QPC\ Dependencies_76.zip
yum install -y unzip
unzip /root/QPC\ Dependencies_76.zip

# install dependency
yum install -y ansible policycoreutils-python selinux-policy selinux-policy-base selinux-policy-targeted libseccomp libtirpc

# install offline rpm packages
rpm -Uvh *.rpm --force

# install qpc server - offline
qpc-tools server install --offline-files=/root/qpc --version=0.9.2

# install qpc client - offline
qpc-tools cli install --offline-files=/root/qpc

# config qpc server, replace 10.66.208.160 with ip address in your env
qpc server config --host 10.66.208.160

# login qpc server as 'admin' user
qpc server login

# add cred
qpc cred add --type network --name cred_rhel --username root --password

# add source
qpc source add --type network --name source_rhel --hosts 10.66.208.[51:53] --cred cred_rhel

# add scan
qpc scan add --name scan_rhel --sources source_rhel

# exec scan
qpc scan start --name scan_rhel

# check if scan is complete
qpc scan list
qpc scan job --name scan_rhel | grep status 

# download scan report, scan job id is from output of command 'qpc scan list'
qpc report download --scan-job 1 --output-file=~/scan_output_rhel.tar.gz
```

### OpenShift 下如何实际路由分片
OpenShift Router Sharding for Production and Development Traffic<br>
https://www.openshift.com/blog/openshift-router-sharding-for-production-and-development-traffic

### OpenShift 下 Custom 类型的 Deployment Strategy 的例子
https://github.com/openshift/origin/issues/11963

### Github webhook 与 Jenkins 的集成
https://dzone.com/articles/adding-a-github-webhook-in-your-jenkins-pipeline

### Kata Container 的架构介绍
https://www.cnblogs.com/xiaochina/p/12812158.html<br>
https://blog.csdn.net/feeltouch/article/details/88631193<br>

### CRI-O 1.0 的介绍
https://www.redhat.com/en/blog/introducing-cri-o-10

### DEFCON 28 Safe Mode Presentations
https://www.youtube.com/playlist?list=PL9fPq3eQfaaBk9DFnyJRpxPi8Lz1n7cFv

### OSP 16.1 - new layout of the network_yaml file
https://github.com/broskos/dell-lab/blob/16.1-ExternalCeph/templates/network_data.yaml

### OpenShift 4 如何改变 MTU
https://access.redhat.com/solutions/5307301

### AMQ JMS Client 启用分布式跟踪
https://access.redhat.com/documentation/en-us/red_hat_amq/7.7/html-single/using_the_amq_jms_client/index#enabling_distributed_tracing

### OpenShift 4.5.3 在 Openstack 上的 UPI 离线安装
https://github.com/davidsajare/david-share/blob/master/OpenShift/OpenShift%204.5.3%E5%9C%A8Openstack%E4%B8%8A%E7%9A%84UPI%E7%A6%BB%E7%BA%BF%E5%AE%89%E8%A3%85.txt

### Mac OS iostat and top
```
iostat -d -K 1
top -o cpu
```

### 如何理解 Kafka 与传统消息队列解决方案
https://www.confluent.io/blog/apache-kafka-vs-enterprise-service-bus-esb-friends-enemies-or-frenemies/

### Red Hat Network Adapter Fast Datapath Feature Support Matrix
https://access.redhat.com/articles/3538141

### OCP 3.11 config map 覆盖 AMQ 配置
```
You can mount the /opt/amq/conf folder as a configmap.Then, you can edit the activemq.xml directly from the configmap.

For instance:

mkdir conf & cd conf
oc rsync amq63-amq-1-7jc97:/opt/amq/conf .
oc create configmap amq63-conf --from-file=. 
#configmap/broker-etc created
oc set volume dc/amq63-amq --overwrite --add --name=amq63-conf --type=configmap --configmap-name=amq63-conf --mount-path=/opt/amq/conf
```

### OCP4 安装后需要完成的一些任务
https://post-install-config--ocpdocs.netlify.app/openshift-enterprise/latest/post_installation_configuration/cluster-tasks.html

### 在 OpenShift 下如何为容器指定可定制化的 Satellite 软件仓库
https://github.com/atgreen/howto-change-container-yum-source

### 清理 Satellite 镜像仓库不完整镜像内容的方法
https://access.redhat.com/solutions/3363761

清理脚本
```
#!/bin/bash

docker_v2_dir="/var/lib/pulp/published/docker/v2/master/"
docker_repo=$1
#blobs missing on disk
tmp_mblobs=$(mktemp /tmp/mblob.XXXX)
#blobs with checksum errors
tmp_cblobs=$(mktemp /tmp/cblob.XXXX)

rm -f /tmp/cblob
rm -f /tmp/mblob


function Usage {

echo "Usage: $0 $organization-$docker_repo_name"
echo "  Example: $0 AcmeCorp-openshift3_metrics-hawkular"
echo ""
        exit 1
}

if [ $# -eq 0 ]    
then
        Usage   
fi

txtbld=$(tput bold)             # bold
bldred=${txtbld}$(tput setaf 1) # red
bldylw=${txtbld}$(tput setaf 3) # yellow
bldgrn=${txtbld}$(tput setaf 2) # green
txtrst=$(tput sgr0)             # reset

function safe {
        pass=${bldgrn}$1${txtrst}
        echo -e "####################\n${pass}  \n####################\n\n"
}

function crit {
        crit=${bldred}$1${txtrst}
        echo -e "####################\n${crit}  \n#################\n\n"
}

function warn {
        warn=${bldylw}$1${txtrst}
        echo -e "####################\n${warn}  \n#################\n\n"
}



safe "Checking Docker repo $docker_repo for invalid blobs, that might take time !!!"
#Follow symlinks
for blob in `find $docker_v2_dir/$docker_repo/*/blobs -type l -exec readlink -m {} ';'`;do
  #File doesn't exist
  if [ ! -f $blob ] ; then
      crit "File $blob is missing on disk"
      echo $blob >> $tmp_mblobs
  #File exists
  elif [ -f $blob ] ; then
      #checksum is correct?
      ondisk_chksum=`sha256sum $blob | awk '{print$1}'`
      #is this the best way?
      fname_chksum=`echo $blob| cut -d: -f2`
      if [ "$ondisk_chksum" != "$fname_chksum" ];then
        crit "File $blob sha256sum is wrong"
        echo $blob >> $tmp_cblobs
      fi
  fi
done


if [ -s $tmp_cblobs ] || [ -s $tmp_mblobs ] ; then
    sort $tmp_cblobs|uniq > /tmp/cblob
    sort $tmp_mblobs|uniq > /tmp/mblob

    for blob in `cat /tmp/cblob`;do
    warn "Removing $blob entry from mongoDB"
    mongo pulp_database --eval "db.units_docker_blob.remove({_storage_path: \"$blob\"})"
    done

    for blob in `cat /tmp/mblob`;do
    warn "Removing $blob entry from mongoDB"
    mongo pulp_database --eval "db.units_docker_blob.remove({_storage_path: \"$blob\"})"
    done

    #cleanup
    rm -f /tmp/mblob
    rm -f /tmp/cblob
    rm -f $tmp_cblobs
    rm -f $tmp_mblobs
    safe "Please proceed to satellite WebUI and sync docker repo $docker_repo"
else
    safe "Repo $docker_repo looks fine!!"
fi
```

### 关于 imagebuilder 的视频
https://www.youtube.com/watch?v=UopGqYs0PKA&t=7s<br>
![imagerbuilder user examples](https://github.com/wangjun1974/tips/blob/master/os/pics/imagebuild-adduser-example1.png)

### Github Pull Request(PR) 的含义
https://hackernoon.com/how-to-git-pr-from-the-command-line-a5b204a57ab1

### 很不错的关于 Github/BitBucket/Gitlab 的 Pull Request/Merge Request 工作流程
https://medium.com/@paulrohan/workflow-of-pull-request-or-merge-request-to-github-bitbucket-gitlab-b0942ec5d56e

### OCP4 fluentd 多行日志 RFE
https://docs.openshift.com/container-platform/4.5/architecture/architecture-installation.html#unmanaged-operators_architecture-installation<br>
https://issues.redhat.com/browse/RFE-706<br>

### Istio 如何实现 Deny All 策略
https://www.stackrox.com/post/2019/08/istio-security-basics-running-microservices-on-zero-trust-networks/

几个重要的讨论过程
```
You can set authz policy to deny all (https://istio.io/latest/docs/reference/config/security/authorization-policy/) for a specific workload...

yep, that's what I'm saying. mTLS + authz. We cover pretty much all of it in the DO328 course that we recently wrote. Take a look at ch08, security. Inside the course we also specify how to restrict egress, though I'm not sure which chapter that is.

'Authorization Policy scope (target) is determined by “metadata/namespace” and an optional “selector”. - “metadata/namespace” tells which namespace the policy applies. If set to root namespace, the policy applies to all namespaces in a mesh. - workload “selector” can be used to further restrict where a policy applies.'

Q: What is a _root_ ns? Is that a namespace literally called `root`, being a magic value for SM? Or are you talking about a future feature, e.g. https://kubernetes.io/blog/2020/08/14/introducing-hierarchical-namespaces/ ?
A: it's the control plane namespace

Q: Authz is ns-bound unless it's in the control plane, in which case it influences the whole SM? If that's the case, is it documented somewhere? Because this sounds like an unexpected behavior to me.
A: Set .global.configRootNamespace to define it, by default it is the control plane namespace

Q: Could you point me to the docs please? I don't see it in https://access.redhat.com/documentation/en-us/openshift_container_platform/4.5/html-single/service_mesh/index
A: See https://archive.istio.io/v1.4/docs/reference/config/security/authorization-policy/

Q: Which also doesn't mention `configRootNamespace` though..?
A: That's the AuthorizationPolicy section which describes the behaviour to be expected with policies

Q: Yep, that I understand. But I just don't know where we missed the magic behavior of root namespace, because that's important and I can't find it anywhere.
A: https://archive.istio.io/v1.4/docs/reference/config/istio.mesh.v1alpha1/
There's a table there which describes rootNamespace
but that's general and leaves the behaviour to the other sections, like the Authorization Policy
```

### OpenShift Active Directory LDAP 例子
https://examples.openshift.pub/authentication/activedirectory-ldap/

### OpenShift 4 运维
在 Google Chat OpenShift 4 里找 “OCP 4.x Day 2 Operations”

### RHEL CoreOS 相关资料
https://docs.google.com/presentation/d/1lxE7ArDTv-O3cK2QTUKBYis4tVolqQ863dgVSRg_Qbg/edit#slide=id.g518d9a1131_5_0<br>
https://docs.google.com/presentation/d/1LMqYeXoltwjeU8G8kx9DDch8JF8ysf-SJV6UMNefnxY/edit<br>

### RHEL7 升级后 vnc 报错的处理
如果报如下错误，可尝试更新系统，然后重启系统
```
 vncext:      VNC extension running!
 vncext:      Listening for VNC connections on all interface(s), port 5903
 vncext:      created VNC server for screen 0
/root/.vnc/xstartup: line 5:  7863 Terminated              /etc/X11/xinit/xinitrc
Killing Xvnc process ID 7854
```

### RHEL7 如何设置默认 Java
https://access.redhat.com/documentation/en-us/jboss_enterprise_application_platform/5/html/installation_guide/sect-use_alternatives_to_set_default_jdk
```
/usr/sbin/alternatives --config java
There are 2 programs which provide 'java'.

  Selection    Command
-----------------------------------------------
*+ 1           java-1.8.0-openjdk.x86_64 (/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.262.b10-0.el7_8.x86_64/jre/bin/java)
   2           java-11-openjdk.x86_64 (/usr/lib/jvm/java-11-openjdk-11.0.8.10-0.el7_8.x86_64/bin/java)

Enter to keep the current selection[+], or type selection number: 2
```

### 查看 openstack stack 失效资源
```
openstack stack resource -n 5 list overcloud | grep -v COMPLETE
openstack stack failures list overcloud
```

### OpenShift 4.5 文档链接
https://docs.openshift.com/container-platform/4.5/welcome/index.html<br>
https://access.redhat.com/documentation/en-us/openshift_container_platform/4.5/

### RHEL 是如何做到 ABI 兼容性的
https://access.redhat.com/articles/rhel-abi-compatibility<br>
https://mojo.redhat.com/docs/DOC-1080350

### 添加用户
```
# gen encrypt passwd
python -c "import crypt, getpass; print(crypt.crypt(getpass.getpass(), crypt.METHOD_SHA512))"

# gen chpasswd format file in form <user>:<pass>
cat > /tmp/pass << 'EOF'
tester:$6$WPuEqIRfSyKjwY6e$3eLkZXDNI6Ysn9412nF4tCgvRMMhHr0Mfx19Hw82tJdC/yOpS3c4WKk1r4c0aVY4qO.35s0101Uxme9hrHv6Q1
EOF

# Apply password by run command chpasswd
cat /tmp/pass | chpasswd -e
```

```
useradd -m tester
passwd tester

echo "tester ALL=(root) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/tester
sudo chmod 0440 /etc/sudoers.d/tester

su - tester

python -c "import crypt, getpass; print(crypt.crypt(getpass.getpass(), crypt.METHOD_SHA512))"
```

### 在 KubeVirt 下如何导入虚拟机磁盘模版并且从虚拟机磁盘模版创建虚拟机
https://kubevirt.io/2020/KubeVirt-VM-Image-Usage-Patterns.html

### 开源 IPAM 
一个开源的IP地址管理系统
https://phpipam.net/

### 在创建 OCS4 StorageCluster 之前需要满足的条件
以下命令输出的状态必须是 'Successed'
```
oc get csv -n openshift-storage -o json | jq '.items[0].status.phase'```
```

### rpm-ostree相关信息
https://rpm-ostree.readthedocs.io/en/latest/<br>
What is rpm-ostree?<br>
rpm-ostree is a hybrid image/package system. It uses libOSTree as a base image format, and accepts RPM on both the client and server side, sharing code with the dnf project; specifically libdnf.

https://github.com/coreos/rpm-ostree<br>
rpm-ostree combines libostree (an image system), with libdnf (a package system), bringing many of the benefits of both together.

```
                         +-----------------------------------------+
                         |                                         |
                         |       rpm-ostree (daemon + CLI)         |
                  +------>                                         <---------+
                  |      |     status, upgrade, rollback,          |         |
                  |      |     pkg layering, initramfs --enable    |         |
                  |      |                                         |         |
                  |      +-----------------------------------------+         |
                  |                                                          |
                  |                                                          |
                  |                                                          |
+-----------------|-------------------------+        +-----------------------|-----------------+
|                                           |        |                                         |
|         libostree (image system)          |        |            libdnf (pkg system)          |
|                                           |        |                                         |
|   C API, hardlink fs trees, system repo,  |        |    ties together libsolv (SAT solver)   |
|   commits, atomic bootloader swap         |        |    with librepo (RPM repo downloads)    |
|                                           |        |                                         |
+-------------------------------------------+        +------------------------------
```

### 关于 DCO - Developer Certificate of Origin
https://github.com/apps/dco<br>
This App enforces the Developer Certificate of Origin (DCO) on Pull Requests. It requires all commit messages to contain the Signed-off-by line with an email address that matches the commit author.<br>

### 关于 OpenShift Infra Node 的视频
https://www.youtube.com/watch?v=9VNjDh1vPXI&feature=youtu.be&t=262

### reposync and modules on RHEL8
https://www.reddit.com/r/redhat/comments/d5e1w6/reposync_and_modules_on_rhel8/
```
reposync --download-path="$localPath" --download-metadata --repoid=$i  --setopt=repo_id.module_hotfixes=1
```

### RHEL8 上同步离线仓库的方法
https://redhatnordicssa.github.io/rhel8-really-fast<br>
https://access.redhat.com/solutions/23016<br>
```
#!/bin/bash

localPath="/repos/rhel8osp/"
fileConn="/getPackage/"

## RHEL 8 OSP
# rhel-8-for-x86_64-baseos-rpms
# rhel-8-for-x86_64-appstream-rpms

for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-appstream-rpms 
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --downloadcomps --download-metadata

  #echo "create repo $i..."
  #createrepo "$localPath"$i
  #time createrepo -g $(ls "$localPath"$i/repodata/*comps.xml) --update --skip-stat --cachedir /tmp/empty-cache-dir "$localPath"$i

done

exit 0

cat RHV4_4_repo_sync_up.sh 
#!/bin/bash

localPath="/repos/rhv44/"
fileConn="/getPackage/"

## sync following yum repos 
# rhel-8-for-x86_64-baseos-rpms
# rhel-8-for-x86_64-appstream-rpms
# rhv-4.4-manager-for-rhel-8-x86_64-rpms
# ansible-2.9-for-rhel-8-x86_64-rpms
# fast-datapath-for-rhel-8-x86_64-rpms
# jb-eap-7.3-for-rhel-8-x86_64-rpms

for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-appstream-rpms rhv-4.4-manager-for-rhel-8-x86_64-rpms ansible-2.9-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms jb-eap-7.3-for-rhel-8-x86_64-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --download-metadata

done

exit 0
```

### RHEL8 reposync 的一个问题解决
--newest-only does not download the latest package<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1833074
```
2. After using "reposync -n --download-metadata --repo=<repo-id>", when a package is identified, you can download the latest and put it in the repository with no further changes. The repodata already thinks the package is there. Using rhsnd as my example.

    # yumdownloader rhnsd
    # mv rhnsd-5.0.35-3.module+el8+2754+6a08e8f4.x86_64.rpm <repo-id>/Packages/r/
```

### DNF module 相关命令
https://docs.fedoraproject.org/en-US/modularity/installing-modules/
```
  <modular command>     disable: disable a module with all its streams
                        enable: enable a module stream
                        info: print detailed information about a module
                        install: install a module profile including its packages
                        list: list all module streams, profiles and states
                        provides: list modular packages
                        remove: remove installed module profiles and their packages
                        repoquery: list packages belonging to a module
                        reset: reset a module
                        update: update packages associated with an active stream

dnf module list
...
Hint: [d]efault, [e]nabled, [x]disabled, [i]nstalled

dnf module list | grep nginx
nginx                1.14 [d]     common [d]                               nginx webserver                                                             
nginx                1.16         common [d]                               nginx webserver                                                             
dnf module list | grep nginx
...
nginx                1.14 [d]     common [d]                               nginx webserver                                                             
nginx                1.16 [e]     common [d]                               nginx webserver     

dnf module install nginx:1.16
...

dnf module list | grep nginx
...
nginx                1.14 [d]     common [d]                               nginx webserver                                                             
nginx                1.16 [e]     common [d] [i]                           nginx webserver      
```

### OSP13 with OVS/DPDK templates
https://gitlab.consulting.redhat.com/bajmera/osp13-hci-nfvi/-/blob/master/templates/nic-configs/computeovsdpdksriov.yaml

### Ansible Tower 3.7.2 如何在 RHEL 8 上安装
```
# 从红帽官网下载 rsyslog rsyslog-8.1911 rhel8 软件包
https://drive.google.com/file/d/1hGybyRfL5fFZbgXNVThspbLjs6MlpcjV/view?usp=sharing

# 从以下网址下载 ansible-tower-3.7.2 bundle rhel8 离线 repo 
https://drive.google.com/file/d/155jVxypKKPg_0zw2Rs3A0Aq7pQzwik9D/view?usp=sharing

# 在目标主机上准备 rhel8 yum repo rhel-8-for-x86_64-baseos-rpms, rhel-8-for-x86_64-appstream-rpms 和 ansible-2.8-for-rhel-8-x86_64-rpms
cat > /etc/yum.repos.d/public.repo << 'EOF'
[rhel-8-for-x86_64-baseos-rpms]
name=rhel-8-for-x86_64-baseos-rpms
baseurl=http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-baseos-rpms/
gpgcheck=0
enabled=1

[rhel-8-for-x86_64-appstream-rpms]
name=rhel-8-for-x86_64-appstream-rpms
baseurl=http://10.66.208.158/rhel8osp/rhel-8-for-x86_64-appstream-rpms/
gpgcheck=0
enabled=1

[ansible-2.8-for-rhel-8-x86_64-rpms]
name=ansible-2.8-for-rhel-8-x86_64-rpms
baseurl=http://10.66.208.158/rhel8osp/ansible-2.8-for-rhel-8-x86_64-rpms/
gpgcheck=0
enabled=1
EOF

# 在目标主机上准备本地文件，用于覆盖 ansible-tower 安装程序生成的 repo 文件
cat > /root/ansible-tower.repo << 'EOF'
[ansible-tower]
name=Ansible Tower Repository - $releasever $basearch
baseurl=file:///repos/ansible-tower
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[ansible-tower-dependencies]
name=Ansible Tower Dependencies Repository - $releasever $basearch
baseurl=file:///repos/ansible-tower-dependencies
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF

# 在目标主机上生成后台刷新脚本
cat /root/test.sh << 'EOF'
for ((;;))
do
  sleep .1
  echo yes | cp -rf /root/ansible-tower.repo /etc/yum.repos.d
done
EOF

# 在目标主机上的1个终端里运行此脚本
/bin/bash -x /root/test.sh

# 在安装主机上解压缩 3.7.2 对应的 ansible-tower-setup-latest.tar.gz 压缩包
# 进入解压后的目录
# 执行 setup 脚本
./setup 
```
### RHEL7 使用 dnf 的例子
https://blog.remirepo.net/post/2019/12/03/Install-PHP-7.4-on-CentOS-RHEL-or-Fedora<br>
https://www.vultr.com/docs/use-dnf-to-manage-software-packages-on-centos-7<br>

### 在 Ansible Tower 里使用 dynamic inventory 如何处理 group_vars
在 plugin 里创建 keyed_groups，然后在 group_vars 里创建对应的 infra_type.yml 和 environment.yml
```
I do this from an AWS inventory, but the idea should be the same. Use the Inventory plugin to pull the inventory hosts, then create groups. Those groups would then correspond to `group_vars/<group_name>.yml`


keyed_groups:
  - key: tags['infra_type']
  - key: tags['environment']

In my AWS plugin file. Then group vars that are named by infra_type tags and environment tags. According to the docs, the Azure plugin can do the same
```

### ServiceNow 与 Ansible Tower 集成
https://cloudautomation.pharriso.co.uk/post/snow-call-tower/

### Mac 上 如何查看 RHV 虚拟机的 Console
https://github.com/heinlein/ovirt-console/blob/master/ovirt-console

保存以上内容到~/bin/ovirt-console

```
mkdir -p ~/bin
pushd ~/bin
curl -O https://raw.githubusercontent.com/heinlein/ovirt-console/master/ovirt-console
chmod +x ~/bin/ovirt-console

sed -ie '/ovirt-console/d' ~/.bashrc

cat >> ~/.bashrc << 'EOF'
alias ovc='~/bin/ovirt-console ~/Downloads/console.vv'
EOF


```

### 如何在 Mac OS X 上降低 Google Chrome 的 CPU 占用
```
# make chrome be nice to other process
for f in $(pgrep 'Chrome'); do renice +20 -p $f; done

# make chrome normal
for f in $(pgrep 'Chrome'); do renice 0 -p $f; done

# make mdworker be nice to other process
sudo -i
for f in $(pgrep 'mdworker'); do renice +20 -p $f; done

# make mdworker normal
sudo -i
for f in $(pgrep 'mdworker'); do renice 0 -p $f; done
```
 
### 如何在 url 里将特殊字符进行编码
https://www.w3schools.com/tags/ref_urlencode.ASP

### 如何在 kubevirt 下通过 cloudinit 为虚拟机指定静态 IP 地址
```
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi1
  name: vmi1
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
      - disk:
          bus: virtio
        name: cloudinitdisk
      interfaces:
      - masquerade: {}
        name: default
      - bridge: {}
        name: br10
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  networks:
  - name: default
    pod: {}
  - name: br10
    multus:
      networkName: br10
  volumes:
  - containerDisk:
      image: kubevirt/fedora-cloud-container-disk-demo
    name: containerdisk
  - cloudInitNoCloud:
      networkData: |
        version: 2
        ethernets:
          eth1:
            addresses: [ 192.168.111.10/24 ]
      userData: |-
        #!/bin/bash
        echo "fedora" |passwd fedora --stdin
    name: cloudinitdisk
```

### Using Operator Lifecycle Manager on restricted networks
https://docs.openshift.com/container-platform/4.5/operators/olm-restricted-networks.html<br>

同时请参考王征写的离线 Operator Hub 和离线 Operator 的相关内容<br>
https://github.com/wangzheng422/docker_env/blob/master/redhat/ocp4/4.5/4.5.disconnect.operator.md<br>

### 在 AWS 上建立 FTP 服务
https://medium.com/tensult/configure-ftp-on-aws-ec2-85b5b56b9c94

### 更新 RHV admin@internal 用户口令
https://access.redhat.com/solutions/63677

### Open Data Hub 白皮书
https://gitlab.com/opendatahub/opendatahub.io/blob/master/pages/arch.md

### OpenShift 3.4 配置 External IP 的步骤
配置 master 和 node 的路由，以及服务的 External IP，实现：外部 -> external ip -> 主机转发 -> service iptables -> Pod 的过程
https://docs.openshift.com/container-platform/3.4/dev_guide/expose_service/expose_internal_ip_service.html

### OpenShift 4.6 复制离线 operator hub 的步骤
```
The process is simpler now, but the docs are not updated yet.
https://issues.redhat.com/browse/OSDOCS-1349 tracks that work.

A quick summary of the changes:

- You no longer need to run `oc adm catalog build` at all
- You can reference the default catalogs directly when mirroring, i.e.
`oc adm catalog mirror
registry.redhat.io/redhat/redhat-operator-index:v4.6`
- You'll need to `oc image mirror` the index image itself (i.e.
`registry.redhat.io/redhat/redhat-operator-index`), at least until `oc
adm catalog mirror` is updated to include that image.
- If you configure the ICSP for the index images to use the default
image names, there is no need to disable default catalogs via the
OperatorHub config.
```

### 同步 OperatorHub 内容到离线环境
```
- On an internet connected hosts:

1) Stand up podman registry
2) oc adm catalog build to create the catalog image for redhat-operators
3) oc adm catalog mirror to the podman registry on the connected node

This will result in all of the images being pulled into your local podman registry and a mapping.txt file. The mapping.txt file will contain lines like:

registry.redhat.io/#####   localhost:5000/######

Drag the data directory backing the podman registry and the mapping file over to the disconnected environment
Stand up a temporary podman registry with that data directory
update the mapping.txt file such that the line I referred to above now says

localhost:5000/####   registry.private.permanent:5000/#####

run oc image mirror --file mapping.txt

This will not result in any reachback to the internet on the disconnected cluster.
```

### 关于 OpenShift Lifecycle Manager 在离线环境下更新 CatalogSource version 版本的问题
```
IHAC wants to upgrade the Red Hat operator registry image in disconnected mode. Mirroring the new operator registry image and changing CatalogSource image version does the job.

2- is there any map of supported Red Hat operator registry image versions vs OpenShift versions ?
Q1. I found no documentation about this procedure in doc, is this supported ? Otherwise, what's the official procedure ?
A1. You can use the docs here for updating https://docs.openshift.com/container-platform/4.5/operators/olm-restricted-networks.html#olm-updating-operator-catalog-image_olm-restricted-networks. As you mention just update the version number of the catalogue image. If you only need a catalogue with a small list of operators, you can use the scripts here . https://github.com/arvin-a/openshift-disconnected-operators

Q2. is there any map of supported Red Hat operator registry image versions vs OpenShift versions ?
A2. There is no matrix, but on the operator level its usually n + or - 1 from the OCP version the operator version was released on. For example OCS 4.5 will be supported for OCP 4.4, 4.5, 4.6. To be on the safe side I would check with the individual engineering team for now.
```

### GitHub Merge a pull request
https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/merging-a-pull-request

### How to install the Operator on OCP4 using only CLI ?
https://access.redhat.com/solutions/5240251<br>
```
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: jaeger-product
  namespace: openshift-operators          <--- Set the target namespace, default "openshift-opeartors" supported the all namespaces Install mode.
spec:
  channel: stable                         <--- Set specific channel
  name: jager-product
  installPlanApproval: Automatic          <--- Set install plan, Automatic or Manual
  source: redhat-operators                <--- Set catalog source name
  sourceNamespace: openshift-marketplace  <--- Set catalog source namespace name

// Create new project
$ oc new-project myjaeger

// Verify the CSV is created in the new project
$ oc get csv
NAME                      DISPLAY                    VERSION   REPLACES   PHASE
jaeger-operator.v1.17.4   Red Hat OpenShift Jaeger   1.17.4

// Check "alm-examples" in the Annotations section, usually the sample CRD format is provided here.               
$ oc describe csv jaeger-operator.v1.17.4
Name:         jaeger-operator.v1.17.4
Namespace:    myjaeger
Labels:       olm.api.c9f771e815ec55e=provided
              olm.copiedFrom=myoperators
Annotations:  alm-examples:
                [
                  {
                    "apiVersion": "jaegertracing.io/v1",
                    "kind": "Jaeger",
                    "metadata": {
                      "name": "jaeger-all-in-one-inmemory"
                    }
                  }
                ]
:

// Create CRD for launching pods
$ oc create -n myjaeger -f - <<EOF
  {
    "apiVersion": "jaegertracing.io/v1",
    "kind": "Jaeger",
    "metadata": {
      "name": "jaeger-all-in-one-inmemory"
    }
  }
EOF

// Check the lauched pod though the CRD
$ oc get pod -n myjaeger
NAME                                         READY   STATUS    RESTARTS   AGE
jaeger-all-in-one-inmemory-f95749dc6-vr9vw   2/2     Running   0          21s
```

### 为 OpenShift Project 设置合理的 LimitRange
设置合适的默认 LimitRange 可以让集群资源被更合理的使用，这项设置对生产集群尤其重要
```
apiVersion: v1
kind: LimitRange
metadata:
  name: ${PROJECT_NAME}-core-resource-limits
  namespace: ${PROJECT_NAME}
spec:
   limits:
   - type: Container
     max:
       cpu: 2
       memory: 6Gi
     default:
       cpu: 500m[e]
       memory: 1.5Gi
     defaultRequest:
       cpu: 50m
       memory: 256Mi
   - type: Pod
     max:
       cpu: 2
       memory: 12Gi

# modify default limitrange for template/project-request 
oc edit template project-request -n openshift-config
```

### 在 RHEL/CentOS 7.x 上使用 ISCSI 存储或者 FC 存储
ISCSI 存储需安装 sg3_utils, device_mapper_multipath 和 iscsi-initiator-utils 软件包
```
yum install -y sg3_utils iscsi-initiator-utils device-mapper-multipath
```

FC 存储需安装 sg3_utils 和 device_mapper_multipath 软件包
```
yum install -y sg3_utils device-mapper-multipath
```

|软件包|说明|
|---|---|
| sg3_utils | 处理 SCSI 指令 |
| device-mapper-multipath | 配置服务器与存储间的多路径 |
| iscsi-initiator-utils | 运行 iscsi initiator 所需程序 |

RHEL7 与 IBM FlashSystem V7200 的 /etc/multipath.conf 配置例子
```
devices {
    device {
        vendor “IBM”
        product “2145”
        path_grouping_policy “group_by_prio”
        path_selector “service-time 0”
        prio “alua”
        path_checker “tur”
        failback “immediate”
        no_path_retry 5
        rr_weight uniform
        rr_min_io_rq “1”
        dev_loss_tmo 120
    }
}
```

### OpenShift Pipeline 相关信息
Tekton Trigers<br>
https://github.com/tektoncd/triggers

当 repository 发生预先定义的事件，通过 Webhook 的方式将事件相关信息发送给 EventListener，EventListener 通过 TriggerBinding 解析接收到的 HTTP JSON body 获得感兴趣的参数，这些参数可被 TriggerTemplate 用来作为参数传递给生成 PipelineResources 和 PipelineRun 

### 什么是 KEDA
https://keda.sh/

KEDA 是 Kubernetes Event Driven Autoscaler 的缩写。是对 Kubernetes 的 Horizontal Pod Autoscaler 的补充，可以基于事件驱动进行水平扩展

### Infiniband
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/ch-configure_infiniband_and_rdma_networks<br>
InfiniBand refers to two distinct things. The first is a physical link-layer protocol for InfiniBand networks. The second is a higher level programming API called the InfiniBand Verbs API. The InfiniBand Verbs API is an implementation of a remote direct memory access (RDMA) technology.
RDMA provides direct access from the memory of one computer to the memory of another without involving either computer’s operating system. This technology enables high-throughput, low-latency networking with low CPU utilization, which is especially useful in massively parallel computer clusters.<br>
In a typical IP data transfer, application X on machine A sends some data to application Y on machine B. As part of the transfer, the kernel on machine B must first receive the data, decode the packet headers, determine that the data belongs to application Y, wake up application Y, wait for application Y to perform a read syscall into the kernel, then it must manually copy the data from the kernel's own internal memory space into the buffer provided by application Y. This process means that most network traffic must be copied across the system's main memory bus at least twice (once when the host adapter uses DMA to put the data into the kernel-provided memory buffer, and again when the kernel moves the data to the application's memory buffer) and it also means the computer must execute a number of context switches to switch between kernel context and application Y context. Both of these things impose extremely high CPU loads on the system when network traffic is flowing at very high rates and can make other tasks to slow down.<br>
RDMA communications differ from normal IP communications because they bypass kernel intervention in the communication process, and in the process greatly reduce the CPU overhead normally needed to process network communications. The RDMA protocol allows the host adapter in the machine to know when a packet comes in from the network, which application should receive that packet, and where in the application's memory space it should go. Instead of sending the packet to the kernel to be processed and then copied into the user application's memory, it places the contents of the packet directly in the application's buffer without any further intervention necessary. However, it cannot be accomplished using the standard Berkeley Sockets API that most IP networking applications are built upon, so it must provide its own API, the InfiniBand Verbs API, and applications must be ported to this API before they can use RDMA technology directly.<br>
Red Hat Enterprise Linux 7 supports both the InfiniBand hardware and the InfiniBand Verbs API. In addition, there are two additional supported technologies that allow the InfiniBand Verbs API to be utilized on non-InfiniBand hardware:<br>
The Internet Wide Area RDMA Protocol (iWARP)<br>
iWARP is a computer networking protocol that implements remote direct memory access (RDMA) for efficient data transfer over Internet Protocol (IP) networks.<br>
The RDMA over Converged Ethernet (RoCE) protocol, which later renamed to InfiniBand over Ethernet (IBoE).<br>
RoCE is a network protocol that allows remote direct memory access (RDMA) over an Ethernet network.<br>

关于InfiniBand架构和知识点漫谈<br>
https://zhuanlan.zhihu.com/p/74238082

InfiniBand, RDMA, iWARP, RoCE , CNA, FCoE, TOE, RDMA, iWARP, iSCSI等概念<br>
https://blog.csdn.net/jhzh951753/article/details/78813666

Working with RDMA in RedHat/CentOS 7.*<br>
https://www.rdmamojo.com/2014/10/11/working-rdma-redhatcentos-7/

### Bridge 与 macvlan 的对别
https://hicu.be/bridge-vs-macvlan

### Linux 虚拟网络接口介绍
Introduction to Linux interfaces for virtual networking<br>
https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/#macvlan

### 网络性能测试工具
https://medium.com/@duhroach/tools-to-profile-networking-performance-3141870d5233

非常好的一片文章，介绍使用 netperf 和 ping 来评估网络时延，并且设定可对比的时间间隔
https://cloud.google.com/blog/products/networking/using-netperf-and-ping-to-measure-network-latency

iperf<br>
https://iperf.fr/

### How many Packets per Second per port are needed to achieve Wire-Speed?
每个端口每秒需要多少个数据包才能达到线速？<br>
https://kb.juniper.net/InfoCenter/index?page=content&id=kb14737

### RHEL6 添加 iptables 规则
```
iptables -I INPUT 1 -m state --state NEW -m tcp -p tcp --dport 5901 -j ACCEPT
iptables -I INPUT 1 -m state --state NEW -m tcp -p tcp --dport 6001 -j ACCEPT
```

### Tekton and ArgoCD
https://developers.redhat.com/blog/2020/09/03/introduction-to-tekton-and-argo-cd-for-multicluster-development/?sc_cid=7013a0000025vsOAAQ<br>
https://youtu.be/pVZ-3LEIHc8<br>

### OpenShift 4 如何指定使用的 Cipher
Ingress controller TLS profiles<br>
https://docs.openshift.com/container-platform/4.5/networking/ingress-operator.html<br>
Recommended configurations<br>
https://wiki.mozilla.org/Security/Server_Side_TLS#Recommended_configurations<br>

### OCP4 with Azure AD 
https://www.arctiq.ca/our-blog/2020/1/30/ocp4-auth-with-azure-ad/

group sync operator<br>
https://github.com/redhat-cop/group-sync-operator

### Declarative OpenShift
https://github.com/redhat-cop/declarative-openshift<br>
This repository contains sets of example resources to be used with a declarative management strategy. Please familiarize yourself with the terminology in that document before reading on.

The purpose of these examples is twofold:
* To act as supporting content for a GitOps series being written for uncontained.io
* To serve as a starting point for establishing a GitOps practice for cluster management

### OpenShift Node Tuning Operator
https://docs.openshift.com/container-platform/4.1/scalability_and_performance/using-node-tuning-operator.html

### Node feature discovery for Kubernetes
https://github.com/openshift/node-feature-discovery<br>

### Virtio-networking 系列高质量博客
https://www.redhat.com/en/virtio-networking-series

### SCTP
https://en.wikipedia.org/wiki/Stream_Control_Transmission_Protocol

### 基于 Open Data Hub 构建 ML 平台
https://www.openshift.com/blog/building-an-open-ml-platform-with-red-hat-openshift-and-open-data-hub-project

### 如何使用 Custom Resource Definition 扩展 Kubernetes 
https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/

### Writing Your First Kubernetes Operator
非常好的文章介绍如何使用 Operator SDK 帮助生成 Operator 来扩展 Kubernetes<br>
https://medium.com/faun/writing-your-first-kubernetes-operator-8f3df4453234

### 为 undercloud 添加 overcloud 控制节点登陆 alias
```
(undercloud) [stack@undercloud ~]$ 
cat >> ~/.bashrc << 'EOF'

alias c0="source ~/stackrc; ssh heat-admin@$( openstack server list | grep controller-0 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias c1="source ~/stackrc; ssh heat-admin@$( openstack server list | grep controller-1 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias c2="source ~/stackrc; ssh heat-admin@$( openstack server list | grep controller-2 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias cp0="source ~/stackrc; ssh heat-admin@$( openstack server list | grep compute-0 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
alias cp1="source ~/stackrc; ssh heat-admin@$( openstack server list | grep compute-1 | awk -F'|' '{print $5}' | awk -F'=' '{print $2}' )"
EOF
```

### RHEL8 如何同步软件频道内容
参见：https://access.redhat.com/solutions/23016
```
# yum install yum-utils createrepo
# reposync -p /var/www/html --download-metadata --repo=<repo id>

```

### 寻找占用资源较多的 kvm 虚拟机 
Quick How To: Finding IO Abuser in KVM VM<br>
https://mellowhost.com/blog/quick-how-to-finding-io-abuser-in-kvm-vm.html<br>
这篇博客介绍了 virt-top 工具，使用它可以查看哪个 kvm 虚拟机占用资源较多，尤其是 blkio 角度
```
virt-top -o blockwrrq -3 
```

### Patch code under linux
参考：https://www.cyberciti.biz/faq/appy-patch-file-using-patch-command/
```
(undercloud) [stack@undercloud ~]$ cp ~/templates-custom/roles_data.yaml ~/templates-custom/roles_data.yaml.orig
(undercloud) [stack@undercloud ~]$ 
cat > patch-roles-data-templates-custom << EOF
--- /home/stack/templates-custom/roles_data.yaml.orig   2020-09-24 00:48:18.831700531 -0400
+++ /home/stack/templates-custom/roles_data.yaml        2020-09-24 00:51:06.340984487 -0400
@@ -21,8 +21,6 @@
       subnet: storage_subnet
     StorageMgmt:
       subnet: storage_mgmt_subnet
-    Tenant:
-      subnet: tenant_subnet
   # For systems with both IPv4 and IPv6, you may specify a gateway network for
   # each, such as ['ControlPlane', 'External']
   default_route_networks: ['External']
@@ -181,7 +179,6 @@
     - OS::TripleO::Services::SwiftProxy
     - OS::TripleO::Services::SwiftDispersion
     - OS::TripleO::Services::SwiftRingBuilder
-    - OS::TripleO::Services::SwiftStorage
     - OS::TripleO::Services::Timesync
     - OS::TripleO::Services::Timezone
     - OS::TripleO::Services::TripleoFirewall
@@ -203,6 +200,8 @@
       subnet: tenant_subnet
     Storage:
       subnet: storage_subnet
+    ProviderNetwork:
+      subnet: provider_network_subnet
   HostnameFormatDefault: '%stackname%-novacomputeiha-%index%'
   RoleParametersDefault:
     TunedProfileName: "virtual-host"
@@ -267,6 +266,8 @@
       subnet: internal_api_subnet
     Tenant:
       subnet: tenant_subnet
+    ProviderNetwork:
+      subnet: provider_network_subnet
   tags:
     - external_bridge
   HostnameFormatDefault: '%stackname%-networker-%index%'
EOF

(undercloud) [stack@undercloud ~]$ patch ~/templates-custom/roles_data.yaml < patch-roles-data-templates-custom 
```

### OpenShift/OLM 下，如何通过 yaml 安装 operator 

```
Basically, OperatorGroup is required to specify where the required permission to create for an Operator, and what namespaces are required to watch the CR for an Operator.

In other words, if you want to install ArgoCD Operator to "argocd" namespace, CSV checks the OperatorGroup in target namespace to decide what namespaces need to create RBAC for deploying Operator pod and CRDs. If "InstallMode" is "OwnNamespace", create role and rolebinding at the namespace, if "AllNamespaces", create clusterrole and clusterrolebinding for the Operator. 

After installing the Operator, the Operator watches its custom resources based on the namespaces specified in the OperatorGroup.

Further information is here: Operator Multitenancy with OperatorGroups

For instance, if you create #1, #2, #3 in order, then InstallPlan is created in "argocd" -> the CSV which will create CRD, RBAC, Serviceaccount in the "argocd" targetNamespace belong to "og-for-argocd" OperatorGroup is also created by it. 
Finally, the Operator is created in the same namespace, the Operator watch if CR is created or not at only the target "argocd" namespace specified Operatorgroup. If CR is created, the Operator create required resources for ArgoCD.

#1 Create namespace(project)
apiVersion: v1
 kind: Namespace
 metadata:
   name: argocd
   
#2 Create OperatorGroup which is matched with the InstallMode.
kind: OperatorGroup
apiVersion: operators.coreos.com/v1
metadata:
  name: og-for-argocd
  namespace: argocd
spec:
  targetNamespaces:
  - argocd            <--- CSV is looking at this, then it creates required permission resources for installing the Operator.
 
#3 Create Subscription of the Operator
apiVersion: operators.coreos.com/v1alpha1
 kind: Subscription
 metadata:
   name: argocd-operator
   namespace: argocd
:

```

### OpenShift: 维护模式下把工作负载迁移到其他节点上 
https://www.techbeatly.com/2018/11/openshift-cluster-how-to-drain-or-evacuate-a-node-for-maintenance.html#.X3A3M9MzbOQ

```
oc adm manage-node compute-102 --schedulable=false
oc adm drain compute-102 --delete-local-data --ignore-daemonsets  --force
oc adm manage-node compute-102 --list-pods
# do maintenance work here
oc adm manage-node compute-102 --schedulable=true
```

### 关于 Pod Disruption Budget 的说明
https://jimmysong.io/kubernetes-handbook/concepts/pod-disruption-budget.html

### Velero 面向 Kuberenetes 的备份恢复 API
https://velero.io/<br>
https://github.com/vmware-tanzu/velero<br>

### 删除可能存在问题的文件
```
...

info: Planning completed in 570ms
uploading: helper.cluster-0001.rhsacn.org:5000/ocp4/openshift4 sha256:c9fa7d57b9028d4bd02b51cef3c3039fa7b23a8b2d9d26a6ce66b3428f6e2457 72.71MiB
warning: Layer size mismatch for sha256:c9fa7d57b9028d4bd02b51cef3c3039fa7b23a8b2d9d26a6ce66b3428f6e2457: had 76247035, wrote 78250687

find /opt/registry/mirror -name "sha256:c9fa*" -exec rm {} \;
```

### 获取 Engine 配置，设置 Engine 配置
https://www.ovirt.org/develop/developer-guide/engine/engine-config-options.html
```
# get all engine config 
engine-config -a

# get engine config about StorageDomainFailureTimeoutInMinutes
engine-config --get StorageDomainFailureTimeoutInMinutes

# set engine config about StorageDomainFailureTimeoutInMinutes to 10
engine-config --set StorageDomainFailureTimeoutInMinutes=10
```

### 查看 Ansible Task 的文件情况
```
ansible_task_pid=$(ps awx | grep "/usr/bin/python.*\.ansible/tmp" | grep -Ev "/bin/sh|grep"  | awk '{print $1}')
watch ls -l $(lsof -p $ansible_task_pid | grep ".ansible/tmp" | grep -Ev "grep" | awk '{print $9}')
```

### 通过 ovirt-shell 访问 rhv
https://www.ovirt.org/develop/release-management/features/infra/cli.html
```
cat > ~/.ovirtshellrc << EOF
[ovirt-shell]
username = admin@internal
url = https://rhvm.rhcnsa.org/ovirt-engine/api
#insecure = False
#filter = False
#timeout = -1
password = 321321
EOF

# download ca.pem from rhv manager
curl -k 'https://rhvm.rhcnsa.org/ovirt-engine/services/pki-resource?resource=ca-certificate&format=X509-PEM-CA' -o /tmp/ca.pem

# test connection
ovirt-shell -c -A /tmp/ca.pem

# remove disk
for i in bootstrap master-0 master-1 master-2 worker-0 worker-1 worker-2
do 
cat > ovirt-shell-cmd << EOF
list disks --parent-vm-name jwang-$i 
EOF

diskid=$(ovirt-shell -c -A /tmp/ca.pem -f ovirt-shell-cmd | grep id | head -1 | awk '{print $3}' )

cat > ovirt-shell-cmd << EOF
remove disk $diskid
EOF

ovirt-shell -c -A /tmp/ca.pem -f ovirt-shell-cmd

done

# remove another disk from workers
for i in worker-0 worker-1 worker-2
do 
cat > ovirt-shell-cmd << EOF
list disks --parent-vm-name jwang-$i 
EOF

diskid=$(ovirt-shell -c -A /tmp/ca.pem -f ovirt-shell-cmd | grep id | awk '{print $3}' )

cat > ovirt-shell-cmd << EOF
remove disk $diskid
EOF

ovirt-shell -c -A /tmp/ca.pem -f ovirt-shell-cmd

done

# add disk
for i in bootstrap master-0 master-1 master-2 worker-0 worker-1 worker-2
do 
cat > ovirt-shell-cmd << EOF
add disk --parent-vm-name jwang-$i --provisioned_size 85899345920 --interface virtio_scsi --format cow --storage_domains-storage_domain storage_domain.name=DS31 --bootable true --wipe_after_delete false
EOF

ovirt-shell -c -A /tmp/ca.pem -f ovirt-shell-cmd
done

# add another disk on worker nodes
for i in worker-0 worker-1 worker-2
do 
cat > ovirt-shell-cmd << EOF
add disk --parent-vm-name jwang-$i --name jwang-${i}_Disk2 --provisioned_size 85899345920 --interface virtio_scsi --format cow --storage_domains-storage_domain storage_domain.name=DS31 --wipe_after_delete false
EOF

ovirt-shell -c -A /tmp/ca.pem -f ovirt-shell-cmd
done

# activate Disk2 on workers
for i in worker-0 worker-1 worker-2
do 
cat > ovirt-shell-cmd << EOF
action disk jwang-${i}_Disk2 activate --parent-vm-name jwang-$i 
EOF

ovirt-shell -c -A /tmp/ca.pem -f ovirt-shell-cmd
done

# stop vm 
for i in bootstrap master-0 master-1 master-2 worker-0 worker-1 worker-2
do 
cat > ovirt-shell-cmd << EOF
action vm jwang-$i stop --async true
EOF

ovirt-shell -c -A /tmp/ca.pem -f ovirt-shell-cmd
done

# start vm
for i in master-0 master-1 master-2 worker-0 worker-1 worker-2
do 
cat > ovirt-shell-cmd << EOF
action vm jwang-$i start --async true
EOF

ovirt-shell -c -A /tmp/ca.pem -f ovirt-shell-cmd
done
```

# 检查 OpenShift master 节点启动日志
```
journalctl -u kubelet -u crio
pods from crictl ps -a using crictl logs <id>
```

### 检查目标主机的事件和 ocp 证书过期时间
对于证书过期报错，请检查节点时间和证书过期时间，see also: https://bugzilla.redhat.com/show_bug.cgi?id=1760181
```
date
openssl s_client -connect api.crc.testing:6443 | openssl x509 -noout -dates
```

### 检查 rhcos 的日志， openshift 部署 troubleshooting
https://access.redhat.com/articles/4292081
```
sudo journalctl > /tmp/err
cat /tmp/err | grep -Ev "I1014|kernel:|systemd|ignition|dracut|multipathd|iscsid|rhcos-fips|coreos-cryptfs|ostree-prepare-root|ostree-remount|restorecon|auditd|augenrules|chronyd|NetworkManager|sssd|dbus-daemon|network-manager|rpc.statd|rhcos-growpart|sshd|rpm-ostree|polkitd|dbus-daemon|machine-config-daemon" | more
```

### 输出 RHEL 7 nfs server 和尝试挂载 nfs 文件系统
```
# on nfs server 
systemctl restart nfs-server

# export nfs share on nfs server
exportfs -r 

# check nfs exports
showmount -e <nfs-server>

# mount nfs share on nfs client
mount -t nfs <nfs-server>:<share> /mnt
umount /mnt
```

### Variations on imagestreams in OpenShift 4
https://itnext.io/variations-on-imagestreams-in-openshift-4-f8ee5e8be633

### build custom operator catalog in disconnect ocp4 
# see: https://www.cnblogs.com/ericnie/p/11777384.html
```
mkdir -p ${HOME}/redhat-operators/build/manifests
cd ${HOME}/redhat-operators

curl https://quay.io/cnr/api/v1/packages?namespace=redhat-operators > packages.txt

cat packages.txt | sed -e 's|,"name"|\n"name"|g'  | grep local
"name":"redhat-operators/local-storage-operator","namespace":"redhat-operators","releases":["79.0.0","78.0.0","77.0.0","76.0.0","75.0.0","74.0.0","73.0.0","72.0.0","71.0.0","70.0.0","69.0.0","68.0.0","67.0.0","66.0.0","65.0.0","64.0.0","63.0.0","62.0.0","61.0.0","60.0.0","59.0.0","58.0.0","57.0.0","56.0.0","55.0.0","54.0.0","53.0.0","52.0.0","51.0.0","50.0.0","49.0.0","48.0.0","47.0.0","46.0.0","45.0.0","44.0.0","43.0.0","42.0.0","41.0.0","40.0.0","39.0.0","38.0.0","37.0.0","36.0.0","35.0.0","34.0.0","33.0.0","32.0.0","31.0.0","30.0.0","29.0.0","28.0.0","27.0.0","26.0.0","25.0.0","24.0.0","23.0.0","22.0.0","21.0.0","20.0.0","19.0.0","18.0.0","17.0.0","16.0.0","15.0.0","14.0.0","13.0.0","12.0.0","11.0.0","10.0.0","9.0.0","8.0.0","7.0.0","6.0.0","5.0.0","4.0.0","3.0.0","2.0.0","1.0.0"],"updated_at":"2020-10-05T05:06:33","visibility":"public"},{"channels":null,"created_at":"2019-10-16T20:37:32","default":"79.0.0","manifests":["helm"]

curl https://quay.io/cnr/api/v1/packages/redhat-operators/local-storage-operator/79.0.0

digest=$(curl -s https://quay.io/cnr/api/v1/packages/redhat-operators/local-storage-operator/79.0.0 | jq -r '.[]|.content.digest' )

# 将 operator 的内容保存为1个 tar.gz 的包
curl -XGET https://quay.io/cnr/api/v1/packages/redhat-operators/local-storage-operator/blobs/sha256/${digest} \
    -o local-storage-operator.tar.gz

mkdir -p manifests/ 
tar -xf local-storage-operator.tar.gz -C manifests/

tree manifests/
manifests/
`-- local-storage-operator-12k64npz
    |-- 4.2
    |   |-- local-storage-operator.v4.2.0.clusterserviceversion.yaml
    |   `-- local-volumes.crd.yaml
    |-- 4.2-s390x
    |   |-- local-storage-operator.v4.2.0.clusterserviceversion.yaml
    |   `-- local-volumes.crd.yaml
    |-- 4.3
    |   |-- local-storage-operator.v4.3.0.clusterserviceversion.yaml
    |   `-- local-volumes.crd.yaml
    |-- 4.4
    |   |-- local-storage-operator.v4.4.0.clusterserviceversion.yaml
    |   `-- local-volumes.crd.yaml
    |-- 4.5
    |   |-- local-storage-operator.v4.5.0.clusterserviceversion.yaml
    |   `-- local-volumes.crd.yaml
    `-- local-storage-operator.package.yaml

cat manifests/local-storage-operator.package.yaml
channels:
- currentCSV: local-storage-operator.4.2.36-202006230600.p0
  name: '4.2'
- currentCSV: local-storage-operator.4.2.36-202006230600.p0-s390x
  name: 4.2-s390x
- currentCSV: local-storage-operator.4.3.37-202009151447.p0
  name: '4.3'
- currentCSV: local-storage-operator.4.4.0-202009161309.p0
  name: '4.4'
- currentCSV: local-storage-operator.4.5.0-202009161248.p0
  name: '4.5'
defaultChannel: '4.5'

export LOCAL_REG="helper.cluster-0001.rhsacn.org:5000"
export LOCAL_SECRET_JSON="${HOME}/pull-secret-2.json"
export OCS_OPERATOR_VERSION="4.5"

cat manifests/local-storage-operator-12k64npz/4.5/local-storage-operator.v4.5.0.clusterserviceversion.yaml  | grep registry | sed -e "s|^.*value: ||g" -e "s|^.*image: ||g" -e "s|^.*containerImage: ||g" | sort -u | while read i ; 
do 
  echo oc image mirror --filter-by-os=\'.*\' -a ${LOCAL_SECRET_JSON} ${i} $(echo $i | sed -e "s|registry.redhat.io|${LOCAL_REG}|" -e "s|@sha256.*$|:${OCS_OPERATOR_VERSION}|")
done | tee /tmp/sync-local-storage-operator-images.sh

podman login registry.redhat.io
podman login helper.cluster-0001.rhsacn.org:5000

/bin/bash -x /tmp/sync-local-storage-operator-images.sh

sed -ie 's|registry.redhat.io|helper.cluster-0001.rhsacn.org:5000|g' manifests/local-storage-operator-12k64npz/4.5/local-storage-operator.v4.5.0.clusterserviceversion.yaml
sed -ie 's|@sha256.*$|:4.5|g' manifests/local-storage-operator-12k64npz/4.5/local-storage-operator.v4.5.0.clusterserviceversion.yaml

rm -f manifests/local-storage-operator-12k64npz/4.5/local-storage-operator.v4.5.0.clusterserviceversion.yamle

mv manifests/local-storage-operator-12k64npz /root/redhat-operators/build/manifests/

cd /root/redhat-operators/build

cat > custom-registry.Dockerfile << EOF
FROM registry.redhat.io/openshift4/ose-operator-registry:v4.5.0 AS builder

COPY manifests manifests

RUN /bin/initializer -o ./bundles.db;sleep 20 

EXPOSE 50051

ENTRYPOINT ["/bin/registry-server"]

CMD ["--database", "/registry/bundles.db"]
EOF

oc patch OperatorHub cluster --type json \
    -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

podman build -f custom-registry.Dockerfile  -t helper.cluster-0001.rhsacn.org:5000/ocp4/custom-registry 

podman push helper.cluster-0001.rhsacn.org:5000/ocp4/custom-registry

cat > my-operator-catalog.yaml << EOF 
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: My Operator Catalog
  sourceType: grpc
  image: helper.cluster-0001.rhsacn.org:5000/ocp4/custom-registry:latest
EOF

oc create -f my-operator-catalog.yaml

export OCP_RELEASE="4.5.2"
export LOCAL_REGISTRY='helper.cluster-0001.rhsacn.org:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON="${HOME}/pull-secret-2.json"
export RELEASE_NAME='ocp-release'
export ARCHITECTURE="x86_64"
export REMOVABLE_MEDIA_PATH='/opt/registry'
export OPERATOR_OCP_RELEASE="4.5"

oc adm catalog build \
  --appregistry-org redhat-operators \
  --from=registry.redhat.io/openshift4/ose-operator-registry:v${OPERATOR_OCP_RELEASE}  \
  --filter-by-os="linux/amd64" \
  -a ${LOCAL_SECRET_JSON} \
  --to=${LOCAL_REGISTRY}/olm/redhat-operators:v1 2>&1 | tee /tmp/catalog-build.log
...
time="2020-10-20T17:43:47+08:00" level=info msg=directory dir=/tmp/cache-201560791/manifests-044983308 file=web-terminal load=package
time="2020-10-20T17:43:47+08:00" level=info msg=directory dir=/tmp/cache-201560791/manifests-044983308 file=web-terminal-_656cyb8 load=package
time="2020-10-20T17:43:47+08:00" level=info msg=directory dir=/tmp/cache-201560791/manifests-044983308 file=1.0.1 load=package
Uploading ... 11.88MB/s
Uploading 9.6MB ...
Uploading 76.39MB ...
Uploading 1.81kB ...
Uploading 3.516MB ...
Uploading 96.33MB ...
Pushed sha256:178e24cabdb7b8c84d8f8326f0f3412822b2d8510ed5a3a51fdea494213ba1fb to helper.cluster-0001.rhsacn.org:5000/olm/redhat-operators:v1

# 目录 /tmp/cache-201560791/manifests-044983308 包含 operator 的 metadata
cd /tmp/cache-201560791/manifests-044983308
ls 
3scale-operator              aws-ebs-csi-driver-operator        eap                         metering-ocp                     quay-operator
advanced-cluster-management  businessautomation-operator        elasticsearch-operator      mtc-operator                     red-hat-camel-k
amq-broker                   cincinnati-operator                fuse-apicurito              nfd                              rh-service-binding-operator
amq-broker-lts               cluster-kube-descheduler-operator  fuse-console                ocs-operator                     rhsso-operator
amq-broker-rhel8             cluster-logging                    fuse-online                 openshift-pipelines-operator-rh  serverless-operator
amq-online                   clusterresourceoverride            jaeger-product              openshiftansibleservicebroker    service-registry-operator
amq-streams                  codeready-workspaces               kiali-ossm                  openshifttemplateservicebroker   servicemeshoperator
amq7-cert-manager            container-security-operator        kubevirt-hyperconverged     performance-addon-operator       sriov-network-operator
amq7-interconnect-operator   datagrid                           local-storage-operator      ptp-operator                     vertical-pod-autoscaler
apicast-operator             dv-operator                        manila-csi-driver-operator  quay-bridge-operator             web-terminal

# 进入 local-storage-operator 目录
cd local-storage-operator/local-storage-operator-0dvlnkig/4.5

pwd
/tmp/cache-201560791/manifests-044983308/local-storage-operator/local-storage-operator-0dvlnkig/4.5

grep -o 'image:.*' local-storage-operator.v4.5.0.clusterserviceversion.yaml 

image: registry.redhat.io/openshift4/ose-local-storage-diskmaker@sha256:3f8595fee46c37ce68eeeb36a7d925659b3424252cb862dbe79fa8e4cc71903a
image: registry.redhat.io/openshift4/ose-local-storage-operator@sha256:e40685aef7071d3cfd2c42c5b17d9c4309e11b4ad77c2213dc6a0903592789dd
image: registry.redhat.io/openshift4/ose-local-storage-static-provisioner@sha256:3496d6fe089a2a7b3a1cb1fdfb144b91de5a387635c8d6ac3ef1a40c0e7efb3f
image: registry.redhat.io/openshift4/ose-local-storage-operator@sha256:e40685aef7071d3cfd2c42c5b17d9c4309e11b4ad77c2213dc6a0903592789dd

# 生成 /tmp/registry-images.lst 文件
grep -o 'image:.*' local-storage-operator.v4.5.0.clusterserviceversion.yaml | awk '{print $2}'  > /tmp/registry-images.lst

# 进入 ocs-operator 4.5.0 目录
cd /tmp/cache-201560791/manifests-044983308/ocs-operator/ocs-operator-70m9f1nh/4.5.0

# 添加镜像到 /tmp/registry-images.lst 文件中
grep -o 'image:.*' *.clusterserviceversion.yaml | awk '{print $2}'  >> /tmp/registry-images.lst

# 生成 /tmp/mapping.txt 文件
cat /dev/null > /tmp/mapping.txt

  for source in `cat /tmp/registry-images.lst`; do  local=`echo $source|awk -F'@' '{print $1}'|sed 's|registry.redhat.io|helper.cluster-0001.rhsacn.org:5000|g'`   ; echo "$source=$local" >> /tmp/mapping.txt; done

# 生成 /tmp/image-policy.txt 文件
cat /dev/null > /tmp/image-policy.txt

  for source in `cat /tmp/registry-images.lst`; do  local=`echo $source|awk -F'@' '{print $1}'|sed 's/registry.redhat.io/helper.cluster-0001.rhsacn.org:5000/g'` ; mirror=`echo $source|awk -F'@' '{print $1}'`; echo "  - mirrors:" >> /tmp/image-policy.txt; echo "    - $local" >> /tmp/image-policy.txt; echo "    source: $mirror" >> /tmp/image-policy.txt; done

# 使用 skopeo copy --all 拷贝镜像
for source in `cat /tmp/registry-images.lst`; do  local=`echo $source|awk -F'@' '{print $1}'|sed 's/registry.redhat.io/helper.cluster-0001.rhsacn.org:5000/g'`   ; 
echo skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://$source docker://$local; skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://$source docker://$local; echo; done

cat > catalogsource.yaml << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: ${LOCAL_REGISTRY}/olm/redhat-operators:v1
  displayName: My Operator Catalog
  publisher: grpc
EOF

oc apply -f catalogsource.yaml

# 创建 /tmp/ImageContentSourcePolicy.yaml 文件
cat <<EOF > /tmp/ImageContentSourcePolicy.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: redhat-operators
spec:
  repositoryDigestMirrors:
$(cat /tmp/image-policy.txt)
EOF

oc apply -f /tmp/ImageContentSourcePolicy.yaml


skopeo inspect --authfile /root/pull-secret-2.json docker://registry.redhat.io/openshift4/ose-local-storage-operator@sha256:e40685aef7071d3cfd2c42c5b17d9c4309e11b4ad77c2213dc6a0903592789dd


```

### 如何暂时设置 Operator 对 CR 的管理
https://docs.openshift.com/container-platform/4.5/architecture/architecture-installation.html#unmanaged-operators_architecture-installation

### 处理 Failing to create pod sandbox on OpenShift 3 and 4 的问题
https://access.redhat.com/solutions/4321791

报错：'  Failed create pod sandbox: rpc error code: = Unknown desc = [failed to set up sandbox container.'

1. 首先尝试删除有问题的 pod，问题仍然存在
2. 然后尝试重启机器，看问题是否仍然在

### 替换不健康的 etcd member
https://docs.openshift.com/container-platform/4.4/backup_and_restore/replacing-unhealthy-etcd-member.html

```
检查 etcd 成员健康状态
oc -n openshift-etcd get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.message}{"\n"}'a
2 of 3 members are available, master1.cluster-0001.rhsacn.org is unhealthy

检查节点是否 stopped，如果节点是 stopped，则执行替换过程
oc get machines -A -ojsonpath='{range .items[*]}{@.status.nodeRef.name}{"\t"}{@.status.providerStatus.instanceState}{"\n"}' | grep -v running

如果节点是 running，则接着检查 node 是否 ready
oc get nodes -o jsonpath='{range .items[*]}{"\n"}{.metadata.name}{"\t"}{range .spec.taints[*]}{.key}{" "}' | grep unreachable

```

```
nodes=$(oc get node --no-headers -o custom-columns=NAME:.metadata.name)

for node in $nodes; do
  echo "Node: $node"
  oc describe node "$node" | awk '/machineconfiguration.openshift.io/'
  echo
done
```

### 如何关闭 OpenShift 4 虚拟机，如何恢复 OpenShift 4 虚拟机
出于安全考虑，bootstrap 证书有效期为 24 小时，之后每 30 天自动更换一次证书。因此在刚部署的 25 小时内不要关闭集群，在此后可关闭集群虚拟机，并且请在 30 天内启动虚拟机。

参考以下链接：
https://www.openshift.com/blog/enabling-openshift-4-clusters-to-stop-and-resume-cluster-vms

### 理解 OpenShift Machine Config Operator
https://www.redhat.com/en/blog/openshift-container-platform-4-how-does-machine-config-pool-work

```
# 查看 rendered-worker 文件数量

oc -n openshift-machine-api get machineconfig | grep render | grep worker | awk '{print $1}' | while read i ; do echo $i ; oc -n openshift-machine-api get machineconfig $i -o json | jq .spec.config.storage.files[].path | wc -l ; done | more  

# 查看 rendered-worker CreateTime

oc -n openshift-machine-api get machineconfig | grep render | grep worker | awk '{print $1}' | while read i ; do echo $i ; oc -n openshift-machine-api get machineconfig $i -o json | jq .metadata.creationTimestamp  ; done

rendered-worker-79175908d2f255d95306f589824c79a6
"2020-10-22T12:14:44Z"
rendered-worker-c75a95deaa58ece09cc7322019f9a0f0
"2020-10-22T11:42:12Z"
rendered-worker-d97677145fe5c3ccd616b684c725e90c
"2020-10-22T11:42:10Z"
rendered-worker-f6e7aa257f819b7f364bf9d1b7c87d20
"2020-10-22T12:30:40Z"

# 最新时间是 2020-10-22T12:30:40Z，看看哪个 machineconfig 的时间与此时间接近

oc -n openshift-machine-api get machineconfig --no-headers | grep -Ev "render" | awk '{print $1}' | while read i ; do echo $i ; oc -n openshift-machine-api get machineconfig $i -o json | jq .metadata.creationTimestamp  ; done

00-master
"2020-10-22T11:42:08Z"
00-worker
"2020-10-22T11:42:09Z"
01-master-container-runtime
"2020-10-22T11:42:09Z"
01-master-kubelet
"2020-10-22T11:42:09Z"
01-worker-container-runtime
"2020-10-22T11:42:09Z"
01-worker-kubelet
"2020-10-22T11:42:09Z"
99-master-f1635907-11d6-42f8-b36f-c9aeff7455bc-registries
"2020-10-22T11:42:09Z"
99-master-ssh
"2020-10-22T11:37:55Z"
99-worker-ea37cbd1-675c-497b-9758-dc64224b8a27-registries
"2020-10-22T11:42:10Z"
99-worker-ssh
"2020-10-22T11:37:55Z"
masters-chrony-configuration
"2020-10-22T12:14:35Z"
workers-chrony-configuration
"2020-10-22T12:14:39Z"

# 没有 2020-10-22T12:30:40Z 的 machineconfig，那为什么生成了新的 rendered 呢?

oc -n openshift-machine-api get machineconfig rendered-worker-79175908d2f255d95306f589824c79a6 -o yaml | tee /tmp/rendered-worker-79175908d2f255d95306f589824c79a6

oc -n openshift-machine-api get machineconfig rendered-worker-f6e7aa257f819b7f364bf9d1b7c87d20 -o yaml | tee /tmp/rendered-worker-f6e7aa257f819b7f364bf9d1b7c87d20

diff -urN /tmp/rendered-worker-79175908d2f255d95306f589824c79a6 /tmp/rendered-worker-f6e7aa257f819b7f364bf9d1b7c87d20
...
@@ -160,7 +160,7 @@
         mode: 420
         path: /etc/kubernetes/kubelet.conf
       - contents:
-          source: data:text/plain,unqualified-search-registries%20%3D%20%5B%22registry.access.redhat.com%22%2C%20%22docker.io%22%5D%0A%0A%5B%5Bregistry%
5D%5D%0A%20%20prefix%20%3D%20%22%22%0A%20%20location%20%3D%20%22quay.io%2Fopenshift-release-dev%2Focp-release%22%0A%20%20mirror-by-digest-only%20%3D%20tr
ue%0A%0A%20%20%5B%5Bregistry.mirror%5D%5D%0A%20%20%20%20location%20%3D%20%22helper.cluster-0001.rhsacn.org%3A5000%2Focp4%2Fopenshift4%22%0A%0A%5B%5Bregis
try%5D%5D%0A%20%20prefix%20%3D%20%22%22%0A%20%20location%20%3D%20%22quay.io%2Fopenshift-release-dev%2Focp-v4.0-art-dev%22%0A%20%20mirror-by-digest-only%2
0%3D%20true%0A%0A%20%20%5B%5Bregistry.mirror%5D%5D%0A%20%20%20%20location%20%3D%20%22helper.cluster-0001.rhsacn.org%3A5000%2Focp4%2Fopenshift4%22%0A
+          source: data:text/plain,unqualified-search-registries%20%3D%20%5B%22registry.access.redhat.com%22%2C%20%22docker.io%22%5D%0A%0A%5B%5Bregistry%
5D%5D%0A%20%20prefix%20%3D%20%22%22%0A%20%20location%20%3D%20%22quay.io%2Fopenshift-release-dev%2Focp-release%22%0A%20%20mirror-by-digest-only%20%3D%20tr
ue%0A%0A%20%20%5B%5Bregistry.mirror%5D%5D%0A%20%20%20%20location%20%3D%20%22helper.cluster-0001.rhsacn.org%3A5000%2Focp4%2Fopenshift4%22%0A%0A%5B%5Bregis
try%5D%5D%0A%20%20prefix%20%3D%20%22%22%0A%20%20location%20%3D%20%22quay.io%2Fopenshift-release-dev%2Focp-v4.0-art-dev%22%0A%20%20mirror-by-digest-only%2
0%3D%20true%0A%0A%20%20%5B%5Bregistry.mirror%5D%5D%0A%20%20%20%20location%20%3D%20%22helper.cluster-0001.rhsacn.org%3A5000%2Focp4%2Fopenshift4%22%0A%0A%5
B%5Bregistry%5D%5D%0A%20%20prefix%20%3D%20%22%22%0A%20%20location%20%3D%20%22registry.redhat.io%2Focs4%2Fcephcsi-rhel8%22%0A%20%20mirror-by-digest-only%2
0%3D%20true%0A%0A%20%20%5B%5Bregistry.mirror%5D%5D%0A%20%20%20%20location%20%3D%20%22helper.cluster-0001.rhsacn.org%3A5000%2F...

# 可以看到 /etc/kubernetes/kubelet.conf 这部分内容变化了
# 增加了新的容器镜像仓库 mirror 内容
# 这部分内容是在执行 oc apply -f oc apply -f /tmp/ImageContentSourcePolicy.yaml 之后产生的
# 谜团解开了
```

### 检查 master worker 时间同步情况 
```
for i in `seq 140 145` ; do echo 10.66.208.${i} ; ssh core@10.66.208.${i} date -u ; date -u ; echo ; done 

10.66.208.140
Warning: Permanently added '10.66.208.140' (ECDSA) to the list of known hosts.
Fri Oct 23 03:16:12 UTC 2020
Fri Oct 23 03:16:17 UTC 2020

10.66.208.141
Warning: Permanently added '10.66.208.141' (ECDSA) to the list of known hosts.
Fri Oct 23 03:16:13 UTC 2020
Fri Oct 23 03:16:19 UTC 2020

10.66.208.142
Warning: Permanently added '10.66.208.142' (ECDSA) to the list of known hosts.
Fri Oct 23 03:16:14 UTC 2020
Fri Oct 23 03:16:20 UTC 2020

10.66.208.143
Warning: Permanently added '10.66.208.143' (ECDSA) to the list of known hosts.
Fri Oct 23 03:16:15 UTC 2020
Fri Oct 23 03:16:21 UTC 2020

10.66.208.144
Warning: Permanently added '10.66.208.144' (ECDSA) to the list of known hosts.
Fri Oct 23 03:16:13 UTC 2020
Fri Oct 23 03:16:21 UTC 2020

10.66.208.145
Warning: Permanently added '10.66.208.145' (ECDSA) to the list of known hosts.
Fri Oct 23 03:16:17 UTC 2020
Fri Oct 23 03:16:22 UTC 2020
```

### 检查 ocs toolbox 无法查看 ceph status 的问题
```
TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD

# 查看 ceph status 报错
sh-4.4# ceph status
[errno 1] error connecting to the cluster

# 查看 toolbox 的 mon_host
sh-4.4# cat /etc/ceph/ceph.conf | grep mon_host
mon_host = 172.30.171.41:6789,172.30.241.175:6789,172.30.232.250:6789

# 从 svc 的输出看 mon

oc get svc -n openshift-storage --no-headers | grep mon

rook-ceph-mon-a                                    ClusterIP      172.30.241.175   <none>      6789/TCP,3300/TCP                                          13h
rook-ceph-mon-c                                    ClusterIP      172.30.232.250   <none>      6789/TCP,3300/TCP                                          13h
rook-ceph-mon-d                                    ClusterIP      172.30.171.41    <none>      6789/TCP,3300/TCP                                          85m


```

### 在升级或者更新 machineconfig 时删除 ocs 的 pdb
https://bugzilla.redhat.com/show_bug.cgi?id=1861104
```
删除 ocs pdb
oc get pdb -n openshift-storage --no-headers | awk '{print $1}'  | while read i ; do echo oc delete pdb $i -n openshift-storage ; oc delete pdb $i -n openshift-storage ; echo ; done  
```

### RHEL7 如何配置 crash dump 和 分析 crash dump
https://www.thegeekdiary.com/centos-rhel-7-how-to-configure-kdump/<br>
https://sites.google.com/site/syscookbook/rhel/rhel-kdump-rhel7<br>

```
1. 安装如下rpm包：
    kernel-devel - 和当前的内核相同版本
    kernel-debuginfo - 和当前的内核相同版本
    kernel-debuginfo-common - 和当前的内核相同版本
yum localinstall -y kernel-devel-3.10.0-862.el7.x86_64.rpm kernel-debuginfo-3.10.0-862.el7.x86_64.rpm kernel-debuginfo-common-x86_64-3.10.0-862.el7.x86_64.rpm

2. 安装 crash 
yum install -y crash

3. 执行 crash 分析
crash /usr/lib/debug/lib/modules/3.10.0-862.el7.x86_64/vmlinux \
   /var/crash/127.0.0.1-2020-10-15-14\:01\:14/vmcore

4. 参考 https://sites.google.com/site/syscookbook/rhel/rhel-kdump-rhel7 继续分析

看到的报错为：
[ 5457.639640] NMI watchdog: Watchdog detected hard LOCKUP on cpu 9
[ 5457.639691] Modules linked in:
[ 5457.639695]  vhost_net vhost macvtap macvlan tun rpcsec_gss_krb5 nfsv4 dns_resolver nfsv3 nfs fscache ebtable_filter ebtables ip6table_filter ip6_tables iptable_filter devlink bnx2fc cnic uio fcoe libfcoe libfc scsi_transport_fc scsi_tgt intel_powerclamp coretemp intel_rapl iosf_mbi kvm_intel kvm iTCO_wdt irqbypass iTCO_vendor_support dm_service_time mei_me sg pcspkr mei shpchp i2c_i801 lpc_ich ipmi_si ipmi_devintf ipmi_msghandler acpi_pad dm_multipath nfsd bridge auth_rpcgss nfs_acl lockd bonding grace ip_tables ext4 mbcache jbd2 dm_thin_pool dm_persistent_data dm_bio_prison dm_bufio libcrc32c sd_mod crc_t10dif crct10dif_generic 8021q garp mrp stp llc ast drm_kms_helper syscopyarea sysfillrect ahci sysimgblt fb_sys_fops ttm libahci igb crct10dif_pclmul crct10dif_common crc32_pclmul drm libata crc32c_intel
[ 5457.639758]  ghash_clmulni_intel mxm_wmi dca ptp aesni_intel nvme pps_core i2c_algo_bit lrw gf128mul glue_helper ablk_helper cryptd i2c_core nvme_core scsi_transport_iscsi wmi sunrpc dm_mirror dm_region_hash dm_log dm_mod
[ 5457.639777] CPU: 9 PID: 5013 Comm: CPU 0/KVM Kdump: loaded Not tainted 3.10.0-862.el7.x86_64 #1
[ 5457.639779] Hardware name: To Be Filled By O.E.M. To Be Filled By O.E.M./D1541D4I, BIOS P1.20 09/19/2016
[ 5457.639781] Call Trace:
[ 5457.639784]  <NMI>  [<ffffffff9d30d768>] dump_stack+0x19/0x1b
[ 5457.639797]  [<ffffffff9cd3fa55>] watchdog_overflow_callback+0x135/0x140
[ 5457.639802]  [<ffffffff9cd7f517>] __perf_event_overflow+0x57/0x100
[ 5457.639806]  [<ffffffff9cd87f04>] perf_event_overflow+0x14/0x20
[ 5457.639810]  [<ffffffff9cc0a580>] intel_pmu_handle_irq+0x220/0x510
[ 5457.639815]  [<ffffffff9cf4c774>] ? ioremap_page_range+0x2b4/0x450
[ 5457.639819]  [<ffffffff9cdd6944>] ? vunmap_page_range+0x234/0x470
[ 5457.639824]  [<ffffffff9d00a4d6>] ? ghes_copy_tofrom_phys+0x116/0x210
[ 5457.639828]  [<ffffffff9d00a670>] ? ghes_read_estatus+0xa0/0x190
[ 5457.639833]  [<ffffffff9d316031>] perf_event_nmi_handler+0x31/0x50
[ 5457.639837]  [<ffffffff9d31790c>] nmi_handle.isra.0+0x8c/0x150
[ 5457.639840]  [<ffffffff9d317be8>] do_nmi+0x218/0x460
[ 5457.639844]  [<ffffffff9d316d79>] end_repeat_nmi+0x1e/0x7e
[ 5457.639849]  [<ffffffff9cd088ae>] ? native_queued_spin_lock_slowpath+0x1ce/0x200
[ 5457.639853]  [<ffffffff9cd088ae>] ? native_queued_spin_lock_slowpath+0x1ce/0x200
[ 5457.639856]  [<ffffffff9cd088ae>] ? native_queued_spin_lock_slowpath+0x1ce/0x200
[ 5457.639857]  <EOE>  [<ffffffff9d30842a>] queued_spin_lock_slowpath+0xb/0xf
[ 5457.639863]  [<ffffffff9d315707>] _raw_spin_lock_irqsave+0x37/0x40
[ 5457.639868]  [<ffffffff9ccceaa1>] try_to_wake_up+0x31/0x350
[ 5457.639874]  [<ffffffffc12eb39c>] ? vmcs_set_bits+0x1c/0x20 [kvm_intel]
[ 5457.639879]  [<ffffffffc12ebb10>] ? vmx_set_hv_timer+0xb0/0xc0 [kvm_intel]
[ 5457.639883]  [<ffffffff9cccee92>] default_wake_function+0x12/0x20
[ 5457.639887]  [<ffffffff9ce308a3>] pollwake+0x73/0x90
[ 5457.639891]  [<ffffffff9cccee80>] ? wake_up_state+0x20/0x20
[ 5457.639894]  [<ffffffff9ccc4abb>] __wake_up_common+0x5b/0x90
[ 5457.639897]  [<ffffffff9ccc4b28>] __wake_up_locked_key+0x18/0x20
[ 5457.639902]  [<ffffffff9ce6ad29>] eventfd_signal+0x59/0x70
[ 5457.639918]  [<ffffffffc09814fe>] ioeventfd_write+0x7e/0xb0 [kvm]
[ 5457.639928]  [<ffffffffc097af77>] __kvm_io_bus_write+0x87/0xc0 [kvm]
[ 5457.639937]  [<ffffffffc097affd>] kvm_io_bus_write+0x4d/0x70 [kvm]
[ 5457.639943]  [<ffffffffc12f036f>] handle_ept_misconfig+0x2f/0x130 [kvm_intel]
[ 5457.639948]  [<ffffffffc12f72b4>] vmx_handle_exit+0x294/0xc90 [kvm_intel]
[ 5457.639953]  [<ffffffffc12f58bb>] ? vmx_vcpu_run+0x32b/0x8f0 [kvm_intel]
[ 5457.639958]  [<ffffffffc12f58c7>] ? vmx_vcpu_run+0x337/0x8f0 [kvm_intel]
[ 5457.639962]  [<ffffffffc12f58bb>] ? vmx_vcpu_run+0x32b/0x8f0 [kvm_intel]
[ 5457.639980]  [<ffffffffc09b79bf>] ? wait_lapic_expire+0xaf/0x190 [kvm]
[ 5457.639993]  [<ffffffffc099171d>] vcpu_enter_guest+0x64d/0x12c0 [kvm]
[ 5457.640007]  [<ffffffffc09b59d3>] ? apic_has_interrupt_for_ppr+0x83/0xb0 [kvm]
[ 5457.640020]  [<ffffffffc09b8355>] ? kvm_apic_has_interrupt+0x45/0x90 [kvm]
[ 5457.640033]  [<ffffffffc0998e58>] kvm_arch_vcpu_ioctl_run+0x358/0x480 [kvm]
[ 5457.640043]  [<ffffffffc097e441>] kvm_vcpu_ioctl+0x2b1/0x650 [kvm]
[ 5457.640047]  [<ffffffff9ce2fb90>] do_vfs_ioctl+0x350/0x560
[ 5457.640050]  [<ffffffff9d31291c>] ? __schedule+0x41c/0xa20
[ 5457.640053]  [<ffffffff9ce2fe41>] SyS_ioctl+0xa1/0xc0
[ 5457.640057]  [<ffffffff9d31f7d5>] system_call_fastpath+0x1c/0x21
[ 5457.640060] Kernel panic - not syncing: Hard LOCKUP
[ 5457.640095] CPU: 9 PID: 5013 Comm: CPU 0/KVM Kdump: loaded Not tainted 3.10.0-862.el7.x86_64 #1
[ 5457.640153] Hardware name: To Be Filled By O.E.M. To Be Filled By O.E.M./D1541D4I, BIOS P1.20 09/19/2016
[ 5457.640215] Call Trace:
[ 5457.640233]  <NMI>  [<ffffffff9d30d768>] dump_stack+0x19/0x1b
[ 5457.640277]  [<ffffffff9d307a6a>] panic+0xe8/0x21f
[ 5457.640312]  [<ffffffff9cc9142f>] nmi_panic+0x3f/0x40
[ 5457.640349]  [<ffffffff9cd3fa41>] watchdog_overflow_callback+0x121/0x140
[ 5457.640396]  [<ffffffff9cd7f517>] __perf_event_overflow+0x57/0x100
[ 5457.640439]  [<ffffffff9cd87f04>] perf_event_overflow+0x14/0x20
[ 5457.640480]  [<ffffffff9cc0a580>] intel_pmu_handle_irq+0x220/0x510
[ 5457.640523]  [<ffffffff9cf4c774>] ? ioremap_page_range+0x2b4/0x450
[ 5457.640566]  [<ffffffff9cdd6944>] ? vunmap_page_range+0x234/0x470
[ 5457.640609]  [<ffffffff9d00a4d6>] ? ghes_copy_tofrom_phys+0x116/0x210
[ 5457.640654]  [<ffffffff9d00a670>] ? ghes_read_estatus+0xa0/0x190
[ 5457.640696]  [<ffffffff9d316031>] perf_event_nmi_handler+0x31/0x50
[ 5457.640740]  [<ffffffff9d31790c>] nmi_handle.isra.0+0x8c/0x150
[ 5457.640781]  [<ffffffff9d317be8>] do_nmi+0x218/0x460
[ 5457.640816]  [<ffffffff9d316d79>] end_repeat_nmi+0x1e/0x7e
[ 5457.640856]  [<ffffffff9cd088ae>] ? native_queued_spin_lock_slowpath+0x1ce/0x200
[ 5457.640906]  [<ffffffff9cd088ae>] ? native_queued_spin_lock_slowpath+0x1ce/0x200
[ 5457.640957]  [<ffffffff9cd088ae>] ? native_queued_spin_lock_slowpath+0x1ce/0x200
[ 5457.641006]  <EOE>  [<ffffffff9d30842a>] queued_spin_lock_slowpath+0xb/0xf
[ 5457.641057]  [<ffffffff9d315707>] _raw_spin_lock_irqsave+0x37/0x40
[ 5457.641101]  [<ffffffff9ccceaa1>] try_to_wake_up+0x31/0x350
[ 5457.641143]  [<ffffffffc12eb39c>] ? vmcs_set_bits+0x1c/0x20 [kvm_intel]
[ 5457.641190]  [<ffffffffc12ebb10>] ? vmx_set_hv_timer+0xb0/0xc0 [kvm_intel]
[ 5457.641238]  [<ffffffff9cccee92>] default_wake_function+0x12/0x20
[ 5457.641280]  [<ffffffff9ce308a3>] pollwake+0x73/0x90
[ 5457.641316]  [<ffffffff9cccee80>] ? wake_up_state+0x20/0x20
[ 5457.641355]  [<ffffffff9ccc4abb>] __wake_up_common+0x5b/0x90
[ 5457.641394]  [<ffffffff9ccc4b28>] __wake_up_locked_key+0x18/0x20
[ 5457.641436]  [<ffffffff9ce6ad29>] eventfd_signal+0x59/0x70
[ 5457.641482]  [<ffffffffc09814fe>] ioeventfd_write+0x7e/0xb0 [kvm]
[ 5457.641530]  [<ffffffffc097af77>] __kvm_io_bus_write+0x87/0xc0 [kvm]
[ 5457.641580]  [<ffffffffc097affd>] kvm_io_bus_write+0x4d/0x70 [kvm]
[ 5457.641625]  [<ffffffffc12f036f>] handle_ept_misconfig+0x2f/0x130 [kvm_intel]
[ 5457.641676]  [<ffffffffc12f72b4>] vmx_handle_exit+0x294/0xc90 [kvm_intel]
[ 5457.641724]  [<ffffffffc12f58bb>] ? vmx_vcpu_run+0x32b/0x8f0 [kvm_intel]
[ 5457.641772]  [<ffffffffc12f58c7>] ? vmx_vcpu_run+0x337/0x8f0 [kvm_intel]
[ 5457.641819]  [<ffffffffc12f58bb>] ? vmx_vcpu_run+0x32b/0x8f0 [kvm_intel]
[ 5457.641876]  [<ffffffffc09b79bf>] ? wait_lapic_expire+0xaf/0x190 [kvm]
[ 5457.641930]  [<ffffffffc099171d>] vcpu_enter_guest+0x64d/0x12c0 [kvm]
[ 5457.641985]  [<ffffffffc09b59d3>] ? apic_has_interrupt_for_ppr+0x83/0xb0 [kvm]
[ 5457.642044]  [<ffffffffc09b8355>] ? kvm_apic_has_interrupt+0x45/0x90 [kvm]
[ 5457.642101]  [<ffffffffc0998e58>] kvm_arch_vcpu_ioctl_run+0x358/0x480 [kvm]
[ 5457.642155]  [<ffffffffc097e441>] kvm_vcpu_ioctl+0x2b1/0x650 [kvm]
[ 5457.642199]  [<ffffffff9ce2fb90>] do_vfs_ioctl+0x350/0x560
[ 5457.642238]  [<ffffffff9d31291c>] ? __schedule+0x41c/0xa20
[ 5457.642277]  [<ffffffff9ce2fe41>] SyS_ioctl+0xa1/0xc0
[ 5457.642313]  [<ffffffff9d31f7d5>] system_call_fastpath+0x1c/0x21

参考的 article 为 https://access.redhat.com/solutions/3469991
```

### 检查 RHCoreOS 系统日志
```
# 生成文件
sudo journalctl > /tmp/system.log

# 过滤信息
sudo cat /tmp/system.log  | grep -Ev "kernel: | systemd| multipathd| ignition| coreos| dracut| iscsid| ostree| restorecon| augenrules| NetworkManager| rhcos| machine-config-daemon| I1026 | auditd| chronyd| dbus| network-manager| rpc.statd| sssd| polkitd| rpm-ostree| dbus-daemon" | mor

# 删除临时文件
sudo rm -f /tmp/system.log

# 生成 kubelet 日志文件
sudo journalctl -u kubelet > /tmp/kubelet.log

# 检查最后的文件内容获取最新的 kubelet 进程 ID

```

### 重新生成节点 certificate
https://access.redhat.com/solutions/4923031

```
# 在跳板机生成脚本 recover_kubeconfig.sh
cat << 'EOF' > recover_kubeconfig.sh 
#!/bin/bash

set -eou pipefail

# context
intapi=$(oc get infrastructures.config.openshift.io cluster -o "jsonpath={.status.apiServerInternalURI}")
context="$(oc config current-context)"
# cluster
cluster="$(oc config view -o "jsonpath={.contexts[?(@.name==\"$context\")].context.cluster}")"
server="$(oc config view -o "jsonpath={.clusters[?(@.name==\"$cluster\")].cluster.server}")"
# token
ca_crt_data="$(oc get secret -n openshift-machine-config-operator node-bootstrapper-token -o "jsonpath={.data.ca\.crt}" | base64 --decode)"
namespace="$(oc get secret -n openshift-machine-config-operator node-bootstrapper-token  -o "jsonpath={.data.namespace}" | base64 --decode)"
token="$(oc get secret -n openshift-machine-config-operator node-bootstrapper-token -o "jsonpath={.data.token}" | base64 --decode)"

export KUBECONFIG="$(mktemp)"
oc config set-credentials "kubelet" --token="$token" >/dev/null
ca_crt="$(mktemp)"; echo "$ca_crt_data" > $ca_crt
oc config set-cluster $cluster --server="$intapi" --certificate-authority="$ca_crt" --embed-certs >/dev/null
oc config set-context kubelet --cluster="$cluster" --user="kubelet" >/dev/null
oc config use-context kubelet >/dev/null
cat "$KUBECONFIG"
EOF

# 执行脚本
sh -x recover_kubeconfig.sh > kubeconfig-bootstrap

# 拷贝 kubeconfig-bootstrap 到 node
scp kubeconfig-bootstrap core@<nodeip>:/tmp

# ssh 到 node 上备份 old node certificate
systemctl stop kubelet
mkdir -p /root/backup-certs
cp -a /var/lib/kubelet/pki /var/lib/kubelet/kubeconfig /root/backup-certs
rm -rf /var/lib/kubelet/pki /var/lib/kubelet/kubeconfig

# 拷贝生成的 kubeconfig-bootstrap 到节点的 /etc/kubernetes/kubeconfig
cp /tmp/kubeconfig-bootstrap /etc/kubernetes/kubeconfig

# 启动 kubelet
systemctl start kubelet

# 在跳板机检查 certificate request 并且批准
oc get csr
/usr/local/bin/oc get csr --no-headers | /usr/bin/awk '{print $1}' | xargs /usr/local/bin/oc adm certificate approve
```

### 删除 ocs cluster 的步骤
参考：https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.5/html-single/deploying_openshift_container_storage_on_vmware_vsphere/index#assembly_uninstalling-openshift-container-storage_rhocs

```
1. 获取使用 ocs 的 pvc 和 obc 

# 获取 pvc , storageclass == ocs-storagecluster-ceph-rbd，并且 app 不是 noobaa
oc get pvc -o=jsonpath='{range .items[?(@.spec.storageClassName=="ocs-storagecluster-ceph-rbd")]}{"Name: "}{@.metadata.name}{" Namespace: "}{@.metadata.namespace}{" Labels: "}{@.metadata.labels}{"\n"}{end}' --all-namespaces|awk '! ( /Namespace: openshift-storage/ && /app:noobaa/ )' | grep -v noobaa-default-backing-store-noobaa-pvc

# 获取 pvc , storageclass == ocs-storagecluster-cephfs
oc get pvc -o=jsonpath='{range .items[?(@.spec.storageClassName=="ocs-storagecluster-cephfs")]}{"Name: "}{@.metadata.name}{" Namespace: "}{@.metadata.namespace}{"\n"}{end}' --all-namespaces

# 获取 obc , storageclass == ocs-storagecluster-ceph-rgw
oc get obc -o=jsonpath='{range .items[?(@.spec.storageClassName=="ocs-storagecluster-ceph-rgw")]}{"Name: "}{@.metadata.name}{" Namespace: "}{@.metadata.namespace}{"\n"}{end}' --all-namespaces

# 获取 obc , storageclass == openshift-storage.noobaa.io
oc get obc -o=jsonpath='{range .items[?(@.spec.storageClassName=="openshift-storage.noobaa.io")]}{"Name: "}{@.metadata.name}{" Namespace: "}{@.metadata.namespace}{"\n"}{end}' --all-namespaces

2. 删除找到的 pvc 和 obc 
2.1 如果监控，registry 和 日志使用了OCS，参考相关链接里的步骤进行删除工作
2.2 删除其他 pvc 和 obc

3. 删除自定义 bucketclass 
# 列出自定义 bucketclass
oc get bucketclass -A  | grep -v noobaa-default-bucket-class
# 删除自定义 bucketclass
oc delete bucketclass <bucketclass name> -n <project-name>

4. 删除自定义 backingstore
# 列出自定义 backingstore
for bs in $(oc get backingstore -o name -n openshift-storage | grep -v noobaa-default-backing-store); do echo "Found backingstore $bs"; echo "Its has the following pods running :"; echo "$(oc get pods -o name -n openshift-storage | grep $(echo ${bs} | cut -f2 -d/))"; done

# 删除自定义 backingstore，删除 backingstore 前，删除对应 pod 和 pvc
for bs in $(oc get backingstore -o name -n openshift-storage | grep -v noobaa-default-backing-store); do echo "Deleting Backingstore $bs"; oc delete -n openshift-storage $bs; done

# 列出自定义 noobaa-pod
oc get pods -n openshift-storage | grep noobaa-pod | grep -v noobaa-default-backing-store-noobaa-pod

# 列出自定义 noobaa-pvc
oc get pvc -n openshift-storage --no-headers | grep -v noobaa-db | grep noobaa-pvc | grep -v noobaa-default-backing-store-noobaa-pvc

5. 列出 local volume 对象
for sc in $(oc get storageclass|grep 'kubernetes.io/no-provisioner' |grep -E $(oc get storagecluster -n openshift-storage -o jsonpath='{ .items[*].spec.storageDeviceSets[*].dataPVCTemplate.spec.storageClassName}' | sed 's/ /|/g')| awk '{ print $1 }');
do
    echo -n "StorageClass: $sc ";
    oc get storageclass $sc -o jsonpath=" { 'LocalVolume: ' }{ .metadata.labels['local\.storage\.openshift\.io/owner-name'] } { '\n' }";
done

6. 删除 storagecluster
oc delete -n openshift-storage storagecluster --all --wait=true

7. 删除 namespace 等待删除结束
oc project default
oc delete project openshift-storage --wait=true --timeout=5m
等待以下命令返回
oc get project  openshift-storage
Error from server (NotFound): namespaces "openshift-storage" not found

如果 project openshift-storage 有对象处于 Terminating 状态无法返回
可执行以下命令进行修复
# patch resource finalizers to []
oc patch CephBlockPool ocs-storagecluster-cephblockpool -n openshift-storage -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch cephfilesystems ocs-storagecluster-cephfilesystem  -n openshift-storage -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch cephobjectstores ocs-storagecluster-cephobjectstore -n openshift-storage -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch cephclusters ocs-storagecluster-cephcluster -n openshift-storage -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch backingstores noobaa-default-backing-store -n openshift-storage -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch bucketclasses noobaa-default-bucket-class -n openshift-storage -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch noobaas noobaa -n openshift-storage -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch storageclusters ocs-storagecluster -n openshift-storage -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch cephobjectstoreusers noobaa-ceph-objectstore-user -n openshift-storage -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch cephobjectstoreusers ocs-storagecluster-cephobjectstoreuser -n openshift-storage -p '{"metadata":{"finalizers":[]}}' --type=merge

8. 删除节点 storage operator artifacts (optional，彻底删除时执行)
for i in $(oc get node -l cluster.ocs.openshift.io/openshift-storage= -o jsonpath='{ .items[*].metadata.name }'); do oc debug node/${i} -- chroot /host rm -rfv /var/lib/rook; done

for i in $(oc get node -l cluster.ocs.openshift.io/openshift-storage= -o jsonpath='{ .items[*].metadata.name }'); do oc debug node/${i} -- chroot /host  ls -l /var/lib/rook; done

9. 删除 localvolume （optional，彻底删除时执行）
LV=local-block
SC=localblock

# 列出待清除的设备
oc get localvolume -n local-storage $LV -o jsonpath='{ .spec.storageClassDevices[*].devicePaths[*] }'

# 删除 localvolume
oc delete localvolume -n local-storage --wait=true $LV

# 删除与 LV 关联的 pv
oc delete pv -l storage.openshift.com/local-volume-owner-name=${LV} --wait --timeout=5m

# 删除 storageclass localblock
oc delete storageclass $SC --wait --timeout=5m

# 删除节点上与 localvolume 有关的 artifacts
[[ ! -z $SC ]] && for i in $(oc get node -l cluster.ocs.openshift.io/openshift-storage= -o jsonpath='{ .items[*].metadata.name }'); do oc debug node/${i} -- chroot /host rm -rfv /mnt/local-storage/${SC}/; done

9. 使用 sgdisk --zap-all 删除磁盘数据 （optional，彻底删除时执行）
# 获取节点列表
oc get nodes -l cluster.ocs.openshift.io/openshift-storage=
# 登录节点
oc debug node/node-xxx
# chroot
sh-4.2# chroot /host
# 设置 DISKS 变量
sh-4.2# DISKS="/dev/disk/by-id/nvme-xxxxxx /dev/disk/by-id/nvme-yyyyyy /dev/disk/by-id/nvme-zzzzzz"
# 执行 sgdisk --zap-all $disk 清除磁盘内容
sh-4.4# for disk in $DISKS; do sgdisk --zap-all $disk;done
# exit
# exit 
# 在其它节点上重复此步骤

10. 删除 openshift-storage.noobaa.io storageclass （optional，彻底删除时执行）
oc delete storageclass  openshift-storage.noobaa.io --wait=true --timeout=5m

11. 取消节点 lable 信息 （optional，彻底删除时执行）
oc label nodes  --all cluster.ocs.openshift.io/openshift-storage-
oc label nodes  --all topology.rook.io/rack-

12. 再次确认所有 ocs 相关 pv 已删除
oc get pv | egrep 'ocs-storagecluster-ceph-rbd|ocs-storagecluster-cephfs'

13. 删除 ocs 相关 crd（optional，彻底删除时执行）
oc delete crd backingstores.noobaa.io bucketclasses.noobaa.io cephblockpools.ceph.rook.io cephclusters.ceph.rook.io cephfilesystems.ceph.rook.io cephnfses.ceph.rook.io cephobjectstores.ceph.rook.io cephobjectstoreusers.ceph.rook.io noobaas.noobaa.io ocsinitializations.ocs.openshift.io  storageclusterinitializations.ocs.openshift.io storageclusters.ocs.openshift.io cephclients.ceph.rook.io --wait=true --timeout=5m
```

### 博客 Deploying OpenShift Container Storage using Local Devices
https://www.openshift.com/blog/deploying-openshift-container-storage-using-local-devices

### 找到 OpenShift4 namespace openshift-monitoring 下无法删除的资源的命令
```
oc api-resources --verbs=list --namespaced -o name | xargs -n 1 oc get --show-kind --ignore-not-found -n openshift-monitoring
```

关于 finalizer 值得详细阅读的博客<br>
这篇博客讲述了：<br>
 * 什么是 finalizer <br>
 * 为什么要有 finalizer <br>
 * 如果不使用 finalizer 可能会有什么问题 <br>
 * 如何找到 namespace 下等待删除的资源 <br>
 * 如果不通过 API，而是通过直接查询 etcd 该怎么做 <br>
https://www.openshift.com/blog/the-hidden-dangers-of-terminating-namespaces

ToDo: 需要仔细阅读一下这篇博客

### OpenShift Smaple Operator
https://github.com/openshift/cluster-samples-operator<br>
用来管理以 RHEL 镜像为基础的 ImageStream 和 Templates<br>

### OpenShift Container Platform 4.x Tested Integrations (for x86_x64)
https://access.redhat.com/articles/4763741<br>

### 重新安装 OCP 4 的 worker
Remove it from the cluster first (cordon -> drain -> oc delete node).  Then reinstall CoreOS however you like (ISO, PXE, whatever) using the same worker ignition

### 博客：在资源超分配情况下 OpenShift 如何处理 worker 节点资源 
How to Handle OpenShift Worker Nodes Resources in Overcommitted State<br>
https://www.openshift.com/blog/how-to-handle-openshift-worker-nodes-resources-in-overcommitted-state

### 生成新的 ignition 文件的步骤
https://docs.openshift.com/container-platform/4.1/installing/installing_bare_metal/installing-bare-metal.html

1. 创建新的空的目录
2. 拷贝备份好的 install-config.yaml 文件到此目录下
3. 执行命令
```
mkdir -p <new_empty_directory>
cp <backup/install-config.yaml> <new_empty_directory>
cd <new_empty_directory>
openshift-install create ignition-configs --dir=`pwd`
```

### 如何创建 serviceaccount 并且授予 anyuid 策略，然后将此 serviceaccount 与 dc/myapp 关联起来
```
# Create a ServiceAccount to let our container startup as a privileged pod
oc create serviceaccount mysa
# As `cluster-admin`, give the ServiceAccount the permission start as an anyuid pod
oc adm policy add-scc-to-user anyuid -z mysa
# Apply the ServiceAccount to the DeploymentConfig
oc patch dc/myapp --patch '{"spec":{"template":{"spec":{"serviceAccountName": "mysa"}}}}'
```

### openshift-install 也是支持 explain 命令
这个命令可以让我们了解 installconfig 在特定平台上的支持能力
```
$ openshift-install explain installconfig.platform.azure.resourceGroupName
KIND:     InstallConfig
VERSION:  v1

RESOURCE: <string>
  ResourceGroupName is the name of an already existing resource group where the cluster should be installed. This resource group should only be used for this specific cluster and the cluster components will assume assume ownership of all resources in the resource group. Destroying the cluster using installer will delete this resource group. This resource group must be empty with no other resources when trying to use it for creating a cluster. If empty, a new resource group will created for the cluster.
```

### OCP 4.6 RHV UPI document
https://github.com/openshift/installer/blob/master/docs/user/ovirt/install_upi.md

### 拷贝镜像的脚本，因为采用了 skopeo copy --all，因此拷贝前和拷贝后 sha256 不变
https://gitlab.cee.redhat.com/ltitov/openshift-disconnected-stuff/-/blob/master/copy-images.sh 
```
cat > copy-images.sh << 'EOF'
#!/bin/bash

REGEX="(.*)=(.*)"
while read p; do

# echo $p

[[ $p =~ $REGEX ]]
echo "Copy ${BASH_REMATCH[1]} to ${BASH_REMATCH[2]}"
$(which skopeo) copy --all docker://${BASH_REMATCH[1]} docker://${BASH_REMATCH[2]}

done
EOF
```

### 查看某节点上的 pod
```
oc get pods -o wide --all-namespaces | grep worker0 
```

### 问题 Error: error creating container storage: layer not known 的处理方式
划重点：这个问题在异常掉电重启时经常会遇到<br>
划重点：这个问题在异常掉电重启时经常会遇到<br>
划重点：这个问题在异常掉电重启时经常会遇到<br>

解决方案参考：
https://bugzilla.redhat.com/show_bug.cgi?id=1857224<br>

https://github.com/openshift/okd/issues/297<br>
After rebooting a node, it sometimes never transitions to the Ready state.  This may happen more frequently under load.  Typical messages are:<br>
Jun 25 14:08:07 worker-2.ostest.test.metalkube.org podman[1424]: Error: error creating container storage: layer not known<br>

```
ssh core@<workerip>

sudo systemctl stop kubelet
sudo systemctl stop crio
sudo rm -rf /var/lib/containers
sudo systemctl start crio
sudo systemctl start kubelet
```

### 介绍 OpenShift Logging 的博客
https://blog.csdn.net/weixin_43902588/article/details/105586460

### 如何在 OpenShift 下实现首次 Deployment 从外部 registry 获取 image，再次则从本地 cache 获取 image
问题： Question regarding the image registry: Suppose i want to deploy an image coming from quay.io/myproject/myapp:latest ? Will this image be cached in the registry so next time i will redeploy it the deployment will be potentially faster? <br>
回答：You can achieve this with ImageStream --reference-policy=local <br>
Your ImageStream should point to the external repo and the DC/Deployment should point to the internal registry url <br>
The image itself is only cached the first time a Pod needs it (it's "pullthrough") <br>


### 使用 fio 测试您的存储是否满足 etcd 的响应及时延要求
https://www.ibm.com/cloud/blog/using-fio-to-tell-whether-your-storage-is-fast-enough-for-etcd


### 24 小时后添加 worker nodes 到 openshift 4 集群
Adding worker nodes to the OCP 4 UPI cluster existing 24+ hours<br>
https://access.redhat.com/solutions/4799921

```
export MCS=api-int.cluster-0001.rhsacn.org:22623

echo "q" | openssl s_client -connect $MCS  -showcerts | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' | base64 --wrap=0 | tee ./api-int.base64 && \
sed --regexp-extended --in-place=.backup "s%base64,[^,]+%base64,$(cat ./api-int.base64)\"%" ./worker.ign

# upload worker.ign to web server
```

更推荐的方式是，这种方法更不容易出错
```
for master: 
  oc extract -n openshift-machine-api secret/master-user-data --keys=userData --to=-
for worker: 
  oc extract -n openshift-machine-api secret/worker-user-data --keys=userData --to=-
```

### OpenShift 4 如何创建定制化 catalog
https://docs.openshift.com/container-platform/4.5/operators/admin/olm-managing-custom-catalogs.html

### 部署 openshift 相关
部署 openshift 到已经存在的 vpc (aws) <br>
https://www.openshift.com/blog/deploy-openshift-to-existing-vpc-on-aws

### 跟踪 API Priority and Fairness Alpha featureGates
API Priority and Fairness Alpha featureGates in OpenShift v4.5 <br>
https://access.redhat.com/solutions/5448851

```
升级的时候可能会遇到 controller-manager 不断重启的报错
这个时候很有可能遇到了Bug: https://bugzilla.redhat.com/show_bug.cgi?id=1883589
解决办法参考: https://access.redhat.com/solutions/5448851

按照 workaround 1 操作

curl https://bugzilla.redhat.com/attachment.cgi?id=1721522 -o apf-configuration.yaml

oc apply -f apf-configuration.yaml

oc get flowschema

oc patch flowschema service-accounts --type=merge -p '{"spec":{"priorityLevelConfiguration":{"name":"workload-low"}}}'
oc patch prioritylevelconfiguration workload-low --type=merge -p '{"spec":{"limited":{"assuredConcurrencyShares": 100}}}'
oc patch prioritylevelconfiguration global-default --type=merge -p '{"spec":{"limited":{"assuredConcurrencyShares": 20}}}'


```

### 升级 OCP 4.5.2 到 4.5.16
```
oc get clusterversions 
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.5.16    True        False         71m     Cluster version is 4.5.16


oc get clusteroperators
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.5.16    True        False         False      22h
cloud-credential                           4.5.16    True        False         False      8d
cluster-autoscaler                         4.5.16    True        False         False      8d
config-operator                            4.5.16    True        False         False      8d
console                                    4.5.16    True        False         False      150m
csi-snapshot-controller                    4.5.16    True        False         False      20m
dns                                        4.5.16    True        False         False      4d1h
etcd                                       4.5.16    True        False         False      8d
image-registry                             4.5.16    True        False         False      102m
ingress                                    4.5.16    True        False         False      22h
insights                                   4.5.16    True        False         False      8d
kube-apiserver                             4.5.16    True        False         False      8d
kube-controller-manager                    4.5.16    True        False         False      8d
kube-scheduler                             4.5.16    True        False         False      8d
kube-storage-version-migrator              4.5.16    True        False         False      29m
machine-api                                4.5.16    True        False         False      8d
machine-approver                           4.5.16    True        False         False      8d
machine-config                             4.5.16    True        False         False      29m
marketplace                                4.5.16    True        False         False      86m
monitoring                                 4.5.16    True        False         False      28m
network                                    4.5.16    True        False         False      8d
node-tuning                                4.5.16    True        False         False      149m
openshift-apiserver                        4.5.16    True        False         False      9m33s
openshift-controller-manager               4.5.16    True        False         False      79m
openshift-samples                          4.5.16    True        False         False      147m
operator-lifecycle-manager                 4.5.16    True        False         False      8d
operator-lifecycle-manager-catalog         4.5.16    True        False         False      8d
operator-lifecycle-manager-packageserver   4.5.16    True        False         False      77m
service-ca                                 4.5.16    True        False         False      8d
storage                                    4.5.16    True        False         False      157m


```

### 如何查看 OpenShift 升级路径
https://access.redhat.com/solutions/4583231

### OCP 4.6 报错 x509: certificate relies on legacy Common Name field, use SANs or temporarily enable Common Name matching with GODEBUG=x509ignoreCN=0 的解决方法
```
Q:
Hi Team i'm trying to install OCP 4.6 in disconnected env over BM I see that cluster-version-operator-7989744785-q4mzc pod is in ImagePullBackOff with error Failed to pull image "magna012.ceph.redhat.com:5000/ocp-release@sha256:0eccf7eb882bc524b91e8b8197249080dbbb9c63ed48cabfa3f6375a8982b346": rpc error: code = Unknown desc = error pinging docker registry magna012.ceph.redhat.com:5000: Get "https://magna012.ceph.redhat.com:5000/v2/": x509: certificate relies on legacy Common Name field, use SANs or temporarily enable Common Name matching with GODEBUG=x509ignoreCN=0

A:
It tells you the error: certificate relies on legacy Common Name field.  Seems that Go 1.15 added a "feature"[0] which throws an error when there is only a CN and no SAN (Subject Alternative Name) in the certificate.  See here[1] for an example with a SAN.

[0] https://github.com/golang/go/issues/39568
[1] https://somoit.net/security/security-create-self-signed-san-certificate-openssl

```

参考：https://github.com/openshift/machine-config-operator/pull/2141
```
cat > 10-default-env-godebug.conf << EOF
[Manager]
DefaultEnvironment="GODEBUG=x509ignoreCN=0"
EOF

config_source=$(cat ./10-default-env-godebug.conf | base64 -w 0 )

cat << EOF > ./99-master-zzz-env-godebug-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: masters-env-godebug-configuration
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 2.2.0
    networkd: {}
    passwd: {}
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${config_source}
          verification: {}
        filesystem: root
        mode: 0644
        path: /etc/systemd/system.conf.d/10-default-env-godebug.conf
  osImageURL: ""
EOF

cat << EOF > ./99-worker-zzz-env-godebug-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: workers-env-godebug-configuration
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 2.2.0
    networkd: {}
    passwd: {}
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${config_source}
          verification: {}
        filesystem: root
        mode: 0644
        path: /etc/systemd/system.conf.d/10-default-env-godebug.conf
  osImageURL: ""
EOF

oc apply -f ./99-master-zzz-env-godebug-configuration.yaml
oc apply -f ./99-worker-zzz-env-godebug-configuration.yaml

检查生效情况
for i in `seq 140 145` ; do echo 10.66.208.$i ; ssh core@10.66.208.$i sudo systemctl show-environment ; echo ; done 
```


### 取消无法调度状态，恢复节点可调度状态
```
oc adm uncordon master0.cluster-0001.rhsacn.org
oc adm uncordon worker0.cluster-0001.rhsacn.org
```

### 报错处理 openshift Node degraded due to mode mismatch for file in Openshift 4
参考：https://access.redhat.com/solutions/4773161
主要的原因是 machine config 的 mode 写得不对，需要有前置的0
```
oc get mcp 
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
master   rendered-master-4ba5557b6c737373715cef560abd8dca   True      False      False      3              3                   3                     0                      8d
worker   rendered-worker-6f412baf4efc9602db15fcb966744d8b   False     True       True       3              2                   2                     1                      8d

oc get mcp -o yaml 
...
      message: 'Node worker0.cluster-0001.rhsacn.org is reporting: "unexpected on-disk state validating against rendered-worker-ae2022de78a3537d63e5acbf4bc63fb1"'
      reason: 1 nodes are reporting degraded status on sync
      status: "True"
      type: NodeDegraded
...

oc logs machine-config-daemon-2574b -n openshift-machine-config-operator -c machine-config-daemon 
...
I1103 08:17:30.257285    1925 daemon.go:1013] Validating against pending config rendered-worker-ae2022de78a3537d63e5acbf4bc63fb1
E1103 08:17:30.471840    1925 daemon.go:1403] mode mismatch for file: "/etc/systemd/system.conf.d/10-default-env-godebug.conf"; expected: --w----r--; received: --w----r--
E1103 08:17:30.471870    1925 writer.go:135] Marking Degraded due to: unexpected on-disk state validating against rendered-worker-ae2022de78a3537d63e5acbf4bc63fb1
```

### 报错处理 MachineConfigPool stuck in degraded after applying a modification in OpenShift Container Platform 4.x
这个步骤是处理上述报错的<br>
https://access.redhat.com/solutions/4773161

解决方法参考：https://access.redhat.com/solutions/5414371

### How to Find All Failed SSH login Attempts in Linux
https://www.tecmint.com/find-failed-ssh-login-attempts-in-linux/
```
cat /var/log/secure | grep "Failed password"
grep "authentication failure" /var/log/secure
grep "Failed password" /var/log/secure | awk '{print $11}' | uniq -c | sort -nr

journalctl _SYSTEMD_UNIT=sshd.service | grep "failure"
journalctl _SYSTEMD_UNIT=sshd.service | grep "Failed"
```

### How To Protect SSH With Fail2Ban on CentOS 7
https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-centos-7

```
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -P /tmp

sudo yum localinstall -y /tmp/epel-release-latest-7.noarch.rpm
sudo yum install -y fail2ban

sudo yum-config-manager --disable epel

cat > /tmp/jail.local << EOF
[DEFAULT]
# Ban hosts for one hour:
bantime = 3600

# Override /etc/fail2ban/jail.d/00-firewalld.conf:
banaction = iptables-multiport

[sshd]
enabled = true
EOF

echo y | sudo cp /tmp/jail.local /etc/fail2ban/jail.local 

sudo systemctl enable fail2ban

sudo systemctl restart fail2ban

```

### 获取 pods 里容器的名称
```
oc get pods csi-cephfsplugin-provisioner-5f8b66cc96-xg9q4 -n openshift-storage -o jsonpath='{.spec.containers[*].name}*'

csi-attacher csi-resizer csi-provisioner csi-cephfsplugin liveness-prometheus*

oc get pods csi-rbdplugin-provisioner-66f66699c8-98wph -n openshift-storage -o jsonpath='{.spec.containers[*].name}*'

csi-provisioner csi-resizer csi-attacher csi-rbdplugin liveness-prometheus*
```

### 查看系统最近重启的记录
see: https://www.cyberciti.biz/tips/linux-last-reboot-time-and-date-find-out.html
```
ssh root@x.x.x.x last reboot | less
```

### 获得 image 的 digest
```
$ skopeo inspect --creds "username:password" docker://waisbrot/wait:latest

# 例如：获取镜像 support-tools:latest 的 sha256 Digest
skopeo inspect docker://registry.redhat.io/rhel7/support-tools:latest | jq .Digest | sed -e 's|"||g' 

# 查看本地镜像的 sha256 Digest
skopeo inspect --creds dummy:dummy docker://helper.cluster-0001.rhsacn.org:5000/rhel7/support-tools | jq .Digest | sed -e 's|"||g' 

```

### 问题： [disconnected] 'registry.redhat.io/rhel7/support-tools' image is being pulled when running `oc debug node/xxx` in disconnected install.
https://bugzilla.redhat.com/show_bug.cgi?id=1728135

### 如何 ping link local ipv6 地址
https://access.redhat.com/solutions/3550082
```
# ping6 -I ethX fe80::xxx:xxxx:xxxx:xxxx
PING fe80::xxx:xxxx:xxxx:xxxx%ethX(fe80::xxx:xxxx:xxxx:xxxx) 56 data bytes
64 bytes from fe80::xxx:xxxx:xxxx:xxxx: icmp_seq=1 ttl=64 time=0.206 ms
```

禁用接口上的 ipv6 
https://www.thegeekdiary.com/centos-rhel-7-how-to-disable-ipv6-on-a-specific-interface-only/
```
sysctl -w net.ipv6.conf.br0.disable_ipv6=1
```

```
sysctl -w net.ipv6.conf.openshift4.autoconf=0
sysctl -w net.ipv6.conf.openshift4.accept_ra=0
nmcli c down openshift4 && nmcli c up openshift4

ipv6.method:                            manual
ipv6.dns:                               --
ipv6.dns-search:                        --
ipv6.dns-options:                       ""
ipv6.dns-priority:                      100
ipv6.addresses:                         2001:db8::1/64
ipv6.gateway:                           2001:db8::1
ipv6.routes:                            --
ipv6.route-metric:                      -1
ipv6.route-table:                       0 (unspec)
ipv6.routing-rules:                     --
ipv6.ignore-auto-routes:                no
ipv6.ignore-auto-dns:                   no
ipv6.never-default:                     no
ipv6.may-fail:                          yes
ipv6.ip6-privacy:                       -1 (unknown)
ipv6.addr-gen-mode:                     stable-privacy
ipv6.dhcp-duid:                         --
ipv6.dhcp-send-hostname:                yes
ipv6.dhcp-hostname:                     --
ipv6.token:                             --

# 为 Hypervisor 添加 ipv6 地址
nmcli con modify openshift4 ipv6.addresses "2001:db8::1/64" gw6 "2001:db8::1" ipv6.method manual
nmcli connection down openshift4 && nmcli connection up openshift4

nmcli con modify br0 remove ipv6.addresses "2001:db8::2/64" gw6 "2001:db8::1" ipv6.method manual
nmcli connection down br0 && nmcli connection up br0

nmcli con modify br0 -ipv6.gateway  ''
nmcli con modify br0 ipv6.addresses '' ipv6.method 'auto'
nmcli connection down br0 && nmcli connection up br0

nmcli con modify openshift4 -ipv6.gateway  ''
nmcli con modify openshift4 ipv6.addresses '' ipv6.method 'auto'
nmcli connection down openshift4 && nmcli connection up openshift4

nmcli con modify openshift4v6 ipv6.addresses "2001:db8::1/64" gw6 "2001:db8::1" ipv6.method manual
nmcli connection down openshift4v6 && nmcli connection up openshift4v6

nmcli con add con-name openshift4v6 type bridge ifname openshift4v6  
nmcli con modify openshift4v6 ipv6.addresses "2001:db8::1/64" gw6 "2001:db8::1" ipv6.method manual
nmcli connection down openshift4v6 && nmcli connection up openshift4v6
```

### OpenShift 建议的查看节点资源占用情况的方法
```
# 执行命令
oc adm top nodes
# 而不是直接登录节点，执行 free 或者查看 Prometheus 所提供的资源占用情况
# 背后的原因是 oc adm top nodes 查看的是从 kubernetes scheduler 视角出发的资源占用情况，
# 这里面包括了对 cpu/memory 资源的 requests ，而不是实际已使用资源情况
# 因为从实际已使用资源出发是满足 kubernetes scheduler 做调度的
```

### named ipv6 正向解析和反向解析的例子
https://www.sbarjatiya.com/notes_wiki/index.php/Configuring_IPv6_and_IPv4,_forward_and_reverse_DNS

```
# Sample 'named.conf' would look like
cat > /etc/named.conf <<EOF
options
{
	directory "/var/named"; // the default
	dump-file 		"data/cache_dump.db";
        statistics-file 	"data/named_stats.txt";
        memstatistics-file 	"data/named_mem_stats.txt";
	forwarders  { 192.168.36.222; 192.168.36.204; };
	forward first;
	allow-transfer {localhost; 192.168.0.0/16; };
	recursion yes;
	listen-on { any; };
	listen-on-v6 {  any; };
	max-cache-size 10M;
	files 10000;
	recursive-clients 100;
	tcp-clients 20;
	tcp-listen-queue 5;
	cleaning-interval 60;
	interface-interval 60;
	rrset-order { order cyclic; };
	edns-udp-size 4096;
	version none;
	hostname none;
	server-id none;

};


logging 
{
        channel default {
                file "data/default.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel general {
                file "data/general.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel security {
                file "data/security.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel config {
                file "data/config.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel resolver {
                file "data/resolver.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel xfer-in {
                file "data/xfer-in.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel xfer-out {
                file "data/xfer-out.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel client {
                file "data/client.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel unmatched {
                file "data/unmatched.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel network {
                file "data/network.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel queries {
                file "data/queries.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };
        channel lame-servers {
                file "data/lame-servers.log" versions 10 size 5M;
                severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
        };

	category default {default; };
	category general {general; };
	category security {security; };
	category config {config; };
	category resolver {resolver; };
	category xfer-in {xfer-in; };
	category xfer-out {xfer-out; };
	category client {client; };
	category unmatched {unmatched; };
	category network {network; };
	category queries {queries; };
	category lame-servers {lame-servers; };
};


view "localhost_resolver"
{
	match-clients 		{ 127.0.0.1; ::1; };
	match-destinations	{ 127.0.0.1; ::1; };
	recursion yes;

	zone "168.192.in-addr.arpa." {
		type master;
		file "192.168.reverse.db";
	};
	zone "ipv6test.iiit.ac.in." { 
		type master;
		file "ipv6test.iiit.ac.in.zone.db";
	};
	zone "4.9.f.4.9.2.d.1.7.5.d.f.ip6.arpa." {
		type master;
		file "fd57.1d29.4f94.reverse.db";
	};

	include "/etc/named.root.hints";
	include "/etc/named.rfc1912.zones";
};


view "internal"
{
	match-clients		{ localnets; 192.168.0.0/16; fd57:1d29:4f94::/48; };
	recursion yes;

	zone "168.192.in-addr.arpa." {
		type master;
		file "192.168.reverse.db";
	};
	zone "ipv6test.iiit.ac.in." { 
		type master;
		file "ipv6test.iiit.ac.in.zone.db";
	};
	zone "4.9.f.4.9.2.d.1.7.5.d.f.ip6.arpa." {
		type master;
		file "fd57.1d29.4f94.reverse.db";
	};
	include "/etc/named.root.hints";
};


key ddns_key
{
	algorithm hmac-md5;
#	secret "use /usr/sbin/dns-keygen to generate TSIG keys";
	secret "MlXuMXqk1WKEzxom7APg6q5MlkfFcZwiYh1BAutyZa7ButPw90fizzS1WPmN";
};


view    "external"
{
	match-clients		{ any; };
	match-destinations	{ any; };

	recursion no;
	allow-query-cache { none; };

	include "/etc/named.root.hints";
};
EOF

# Default files
named.rfc1912.zones
named.root.hints
localdomain.zone
named.broadcast
named.local
named.zero
localhost.zone
named.ip6.local
named.root

# Forward zone file
cat > /var/named/chroot/var/named/ipv6test.iiit.ac.in.zone.db <<EOF
$TTL 3600
@ SOA	ns.ipv6test.iiit.ac.in. root.ipv6test.iiit.ac.in. (1 15m 5m 30d 1h)
	NS ns.ipv6test.iiit.ac.in.

localhost	IN	A 	127.0.0.1
localhost	IN	AAAA 	::1

vm1		IN	A	192.168.201.244
vm1.ipv4	IN	A	192.168.201.244
vm1		IN	AAAA	fd57:1d29:4f94:1:216:36ff:fe00:1
vm1		IN	AAAA	fd57:1d29:4f94:a:216:36ff:fe00:1
vm1.ipv6	IN	AAAA	fd57:1d29:4f94:1:216:36ff:fe00:1
vm1.ipv6	IN	AAAA	fd57:1d29:4f94:a:216:36ff:fe00:1
ns		IN	CNAME	vm1

vm2		IN	A	192.168.201.4
vm2.ipv4	IN	A	192.168.201.4
vm2		IN	AAAA	fd57:1d29:4f94:1:216:36ff:fe00:2
vm2		IN	AAAA	fd57:1d29:4f94:a:216:36ff:fe00:2
vm2.ipv6	IN	AAAA	fd57:1d29:4f94:1:216:36ff:fe00:2
vm2.ipv6	IN	AAAA	fd57:1d29:4f94:a:216:36ff:fe00:2
vm2		IN	A	192.168.202.17
vm2.ipv4	IN	A	192.168.202.17
vm2		IN	AAAA	fd57:1d29:4f94:2:216:36ff:fe00:3
vm2		IN	AAAA	fd57:1d29:4f94:b:216:36ff:fe00:3
vm2.ipv6	IN	AAAA	fd57:1d29:4f94:2:216:36ff:fe00:3
vm2.ipv6	IN	AAAA	fd57:1d29:4f94:b:216:36ff:fe00:3

vm3		IN	A	192.168.202.30
vm3.ipv4	IN	A	192.168.202.30
vm3		IN	AAAA	fd57:1d29:4f94:2:216:36ff:fe00:4
vm3		IN	AAAA	fd57:1d29:4f94:b:216:36ff:fe00:4
vm3.ipv6	IN	AAAA	fd57:1d29:4f94:2:216:36ff:fe00:4
vm3.ipv6	IN	AAAA	fd57:1d29:4f94:b:216:36ff:fe00:4
EOF


# ipv4 Reverse zone files
cat > /var/named/chroot/var/named/192.168.reverse.db <<EOF
$TTL 3600
@ SOA	ns.ipv6test.iiit.ac.in. root.ipv6test.iiit.ac.in. (1 15m 5m 30d 1h)
	NS ns.ipv6test.iiit.ac.in.

244.201		PTR	vm1.ipv4.ipv6test.iiit.ac.in.
244.201		PTR	vm1.ipv6test.iiit.ac.in.
4.201		PTR	vm2.ipv4.ipv6test.iiit.ac.in.
4.201		PTR	vm2.ipv6test.iiit.ac.in.
17.202		PTR	vm2.ipv4.ipv6test.iiit.ac.in.
17.202		PTR	vm2.ipv6test.iiit.ac.in.
30.202		PTR	vm3.ipv4.ipv6test.iiit.ac.in.
30.202		PTR	vm3.ipv6test.iiit.ac.in.
EOF


# ipv6 Reverse zone files

cat > /var/named/chrooot/var/named/fd57.1d29.4f94.reverse.db <<EOF
$TTL 3600
@ SOA	ns.ipv6test.iiit.ac.in. root.ipv6test.iiit.ac.in. (1 15m 5m 30d 1h)
	NS ns.ipv6test.iiit.ac.in.

$ORIGIN 1.0.0.0.4.9.f.4.9.2.d.1.7.5.d.f.ip6.arpa.
;                 1 1 1 1 1 1 1
; 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6

1.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm1.ipv6.ipv6test.iiit.ac.in.
1.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm1.ipv6test.iiit.ac.in.
2.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm2.ipv6.ipv6test.iiit.ac.in.
2.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm2.ipv6test.iiit.ac.in.



$ORIGIN a.0.0.0.4.9.f.4.9.2.d.1.7.5.d.f.ip6.arpa.
;                 1 1 1 1 1 1 1
; 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6

1.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm1.ipv6.ipv6test.iiit.ac.in.
1.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm1.ipv6test.iiit.ac.in.
2.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm2.ipv6.ipv6test.iiit.ac.in.
2.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm2.ipv6test.iiit.ac.in.



$ORIGIN 2.0.0.0.4.9.f.4.9.2.d.1.7.5.d.f.ip6.arpa.
;                 1 1 1 1 1 1 1
; 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6


3.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm2.ipv6.ipv6test.iiit.ac.in.
3.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm2.ipv6test.iiit.ac.in.
4.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm3.ipv6.ipv6test.iiit.ac.in.
4.0.0.0.0.0.e.f.f.f.6.3.6.1.2.0	PTR	vm3.ipv6test.iiit.ac.in.
EOF


# Client configuration
# ipv4
DNS1=192.168.201.244
SEARCH=ipv6test.iiit.ac.in
# ipv6
DNS1=fd57:1d29:4f94:1:216:36ff:fe00:1
DNS2=fd57:1d29:4f94:a:216:36ff:fe00:1
SEARCH=ipv6test.iiit.ac.in

```

### dig 的用法
https://www.hostinger.com/tutorials/how-to-use-the-dig-command-in-linux/
```
dig -6 _etcd-server-ssl._tcp.ocp4.example.com ANY
dig -6 master1.ocp4.example.com ANY
dig -6 -x 2001:db8::11 ANY
```

### kubernetes network policies
https://banzaicloud.com/blog/network-policy/

### rhv admin 用户被 lock 的处理方法
参见：https://lists.ovirt.org/pipermail/users/2017-January/079032.html
```
# 查看锁定状态
ovirt-aaa-jdbc-tool user show admin

# 解除锁定状态
ovirt-aaa-jdbc-tool user unlock admin
```

### 使用 filetranspiler 更新 ignition 文件
https://www.openshift.com/blog/advanced-network-customizations-for-openshift-install

### 检查 openshift etcd  
参考：https://docs.openshift.com/container-platform/4.4/backup_and_restore/replacing-unhealthy-etcd-member.html
```
oc get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.message}{"\n"}'
```

### ocp 4.5.2 ipv6 cluster 报错 
```
oc -n openshift-kube-apiserver-operator logs $(oc get pods -n openshift-kube-apiserver-operator -o jsonpath='{ .items[*].metadata.name }')
...
E1113 09:06:12.019969       1 base_controller.go:180] "ConfigObserver" controller failed to sync "key", err: configmaps openshift-etcd/etcd-endpoints: no etcd endpoint addresses found

# 实际情况是 
oc get configmaps etcd-endpoints -n openshift-etcd -o yaml 
apiVersion: v1
data:
  MjAwMTpkYjg6OjE0: 2001:db8::14
  MjAwMTpkYjg6OjE1: 2001:db8::15
  MjAwMTpkYjg6OjEz: 2001:db8::13
kind: ConfigMap
metadata:
  annotations:
    alpha.installer.openshift.io/etcd-bootstrap: 2001:db8::12
  creationTimestamp: "2020-11-13T05:58:58Z"
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .: {}
          f:alpha.installer.openshift.io/etcd-bootstrap: {}
    manager: cluster-bootstrap
    operation: Update
    time: "2020-11-13T05:58:58Z"
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:data:
        .: {}
        f:MjAwMTpkYjg6OjE0: {}
        f:MjAwMTpkYjg6OjE1: {}
        f:MjAwMTpkYjg6OjEz: {}
    manager: cluster-etcd-operator
    operation: Update
    time: "2020-11-13T06:20:57Z"
  name: etcd-endpoints
  namespace: openshift-etcd
  resourceVersion: "6646"
  selfLink: /api/v1/namespaces/openshift-etcd/configmaps/etcd-endpoints
  uid: 1bce3cd5-1f79-442d-a5ec-bd89f7d03474

```

# 为 RHCOS core 用户添加口令
参考：https://bugzilla.redhat.com/show_bug.cgi?id=1801153
参考：https://www.thelinuxfaq.com/504-generate-md5-sha-256-sha-512-encrypted-passwords-linux-command

```
$ core_user_password=$(python2 -c 'import crypt; print(crypt.crypt("changeme", crypt.mksalt(crypt.METHOD_SHA512)))')

# 尝试一下用 openssl 生成 password hash
$ core_user_password=$( echo "redhat\nredhat" | xargs openssl passwd -1 )

$ core_user_sshkey=$(cat ~/.ssh/id_rsa.pub)

$ mkdir -p bootstrap-user

# 这个文件有报错，工作起来不正常
$ cat > bootstrap-user/config-core-pwhash.ign << EOF
{
    "ignition": {
        "config": {},
        "security": {
            "tls": {}
        },
        "timeouts": {},
        "version": "2.2.0"
    },
    "passwd": {
        "users": [
            {
                "name": "core",
                "groups": [
                    "sudo",
                    "wheel"
                ],
                "passwordHash": ‘"’${core_user_password}‘"’
            }
        ]
    }
}

# 试试这个文件，也不工作
$ cat > bootstrap-user/config-core-pwhash.ign << EOF
{
  "ignition": {
    "config": {},
    "timeouts": {},
    "version": "2.2.0"
  },
  "networkd": {},
  "passwd": {
    "users": [
      {
        "name": "core",
        "passwordHash": "${core_user_password}",
        "sshAuthorizedKeys": [
          "${core_user_sshkey}"
        ]
      },
      {
        "groups": [
          "wheel",
          "sudo"
        ],
        "name": "user1",
        "passwordHash": "${core_user_password}",
        "sshAuthorizedKeys": [
          "${core_user_sshkey}"
        ]
      }      
    ]
  },
  "storage": {},
  "systemd": {}
}
EOF

# 试试这个文件
$ cat > bootstrap-user/config-core-pwhash.ign << EOF
{
  "ignition": {
    "config": {},
    "timeouts": {},
    "version": "2.2.0"
  },
  "networkd": {},
  "passwd": {
    "users": [
      {
        "name": "core",
        "passwordHash": "${core_user_password}"
      }
    ]
  },
  "storage": {},
  "systemd": {}
}
EOF

# 这个工具如果需要合并 ign 文件，可以使用以下仓库里的工具版本
# https://github.com/wangzheng422/filetranspiler

mkdir -p fake
filetranspiler -i bootstrap.ign -m bootstrap-user/config-core-pwhash.ign -f fake -o bootstrap-test.ign

echo y | cp bootstrap-test.ign /var/www/html/ignition/bootstrap-static.ign 
```

### 如何通过命令获取 Certificate 内容
```
# 用 openssl 访问网址，然后使用 sed 获取 certificate 内容
[core@worker0 ~]$ echo "" | openssl s_client -connect rhel7vm.ocp4.freebsd.us:5000 -prexit 2>/dev/null | sed -n -e '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/ p' >> ssl.crt

# 指定 cert-dir 参数，用 certificate 登录 registry
[core@worker0 ~]$ podman login -u admin rhel7vm.ocp4.freebsd.us:5000 --cert-dir=.
Password: 
Login Succeeded!
```

### 如何从 tree 格式的 json 文件，生成一行压缩格式的 json 文件
```
# 参见 https://unix.stackexchange.com/questions/365614/how-to-convert-a-jsons-file-tree-structure-into-a-single-line

$ jq -c . file.json

# The -c flag to jq is the short version of the --compact-output flag and will prompt jq to generate the most compact output possible. The dot is a simple pass-through filter that won't modify any of the data.

```

### OCP4 Static IP 设置方法
https://zhimin-wen.medium.com/static-ip-for-ocp4-d2e4c1da5de

### 查看 registry 的 repository 的方法和 tags 的方法
```
# 查看 registry 的 repository 的方法
curl -u dummy:dummy https://registry.ocp4.example.com:5443/v2/_catalog | jq . 
...
    "catalog/certified-operators",
    "catalog/community-operators",
    "catalog/redhat-operators",
...

# 查看 repository 'catalog/redhat-operators' 的 tags
curl -u dummy:dummy https://registry.ocp4.example.com:5443/v2/catalog/redhat-operators/tags/list
{"name":"catalog/redhat-operators","tags":["4.5.2-20200726"]}

# 查看 repository 'catalog/certified-operators' 的 tags
curl -u dummy:dummy https://registry.ocp4.example.com:5443/v2/catalog/certified-operators/tags/list
{"name":"catalog/certified-operators","tags":["4.5.2-20200726"]}

# 查看 repository 'catalog/community-operators' 的 tags
curl -u dummy:dummy https://registry.ocp4.example.com:5443/v2/catalog/community-operators/tags/list

# 参见：https://docs.openshift.com/container-platform/4.5/operators/admin/olm-managing-custom-catalogs.html

# grpcurl 工具可以此网址下载：https://github.com/fullstorydev/grpcurl/releases/download/v1.5.0/grpcurl_1.5.0_linux_x86_64.tar.gz

# wget https://github.com/fullstorydev/grpcurl/releases/download/v1.5.0/grpcurl_1.5.0_linux_x86_64.tar.gz -P ~/Downloads
# tar zxvf ~/grpcurl_1.5.0_linux_x86_64.tar.gz -C /usr/local/bin

# 将 catalog registry images 下载到本地
podman pull registry.ocp4.example.com:5443/catalog/redhat-operators:4.5.2-20200726

# 在本地运行 catalog registry image
podman run -p 50051:50051 -it registry.ocp4.example.com:5443/catalog/redhat-operators:4.5.2-20200726

# 查询可用 Packages
grpcurl -plaintext localhost:50051 api.Registry/ListPackages

# 查询最新某个 channel 里的 opeartor bundle 
grpcurl -plaintext -d '{"pkgName":"ocs-operator","channelName":"4.5"}' localhost:50051 api.Registry/GetBundleForChannel

# 从容器内拷贝 bundles.db 到本地
# 参考 jq 的使用：https://shapeshed.com/jq-json/
podman cp $(podman ps --format json | jq '.[] | .ID ' | sed -e 's|"||g'):/bundles.db .

# 查询 bundles.db 内容
echo "select * from related_image \
    where operatorbundle_name like 'clusterlogging.4%';" \
    | sqlite3 -line ./bundles.db 

echo "select * from related_image \
    where operatorbundle_name like 'local-storage-operator.4.5%';" \
    | sqlite3 -line ./bundles.db 

# 查询 bundles.db 有哪些 tables 
echo ".tables" | sqlite3 -line ./bundles.db 

api                channel            package          
api_provider       channel_entry      related_image    
api_requirer       operatorbundle     schema_migrations

# 查询 bundles.db 的 table related_image 的内容
echo "select * from related_image;" | sqlite3 -line ./bundles.db

# 以 local-storage-operator 为例，同步所需镜像到本地
mkdir -p ./tmp
echo "select * from related_image \
    where operatorbundle_name like 'local-storage-operator.4.5%';"     | sqlite3 -line ./bundles.db | grep -o 'image =.*' | awk '{print $3}' > ./tmp/registry-images.lst

# 补充上 ocs-operator 对应的镜像到同步镜像清单
echo "select * from related_image \
    where operatorbundle_name like 'ocs-operator.v4.5.2%';"     | sqlite3 -line ./bundles.db | grep -o 'image =.*' | awk '{print $3}' >> ./tmp/registry-images.lst

# 基于同步镜像清单生成 mapping.txt 
cat /dev/null > ./tmp/mapping.txt
  for source in `cat ./tmp/registry-images.lst`; do  local=`echo $source|awk -F'@' '{print $1}'|sed 's|registry.redhat.io|helper.cluster-0001.rhsacn.org:5000|g'`   ; echo "$source=$local" >> ./tmp/mapping.txt; done

# 生成 image-policy.txt
cat /dev/null > ./tmp/image-policy.txt
  for source in `cat ./tmp/registry-images.lst`; do  local=`echo $source|awk -F'@' '{print $1}'|sed 's/registry.redhat.io/helper.cluster-0001.rhsacn.org:5000/g'` ; mirror=`echo $source|awk -F'@' '{print $1}'`; echo "  - mirrors:" >> ./tmp/image-policy.txt; echo "    - $local" >> ./tmp/image-policy.txt; echo "    source: $mirror" >> ./tmp/image-policy.txt; done

# 同步镜像到本地镜像仓库
export LOCAL_SECRET_JSON=/root/pull-secret-2.json

for source in `cat ./tmp/registry-images.lst`; do  local=`echo $source|awk -F'@' '{print $1}'|sed 's/registry.redhat.io/helper.cluster-0001.rhsacn.org:5000/g'`   ; 
echo skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://$source docker://$local; skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://$source docker://$local; echo; done

# 基于 image-policy.txt 生成 ImageContentSourcePolicy
cat <<EOF > ./tmp/ImageContentSourcePolicy.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: redhat-operators
spec:
  repositoryDigestMirrors:
$(cat ./tmp/image-policy.txt)
EOF

oc create -f ./tmp/ImageContentSourcePolicy.yaml
```

```
# sqlite 的使用
# 参见：
# https://www.sqlitetutorial.net/
# https://www.sqlitetutorial.net/sqlite-tutorial/sqlite-show-tables/

echo ".tables" | sqlite3 -line ./bundles.db 
```

```
# 从容器内拷贝 bundles.db 到本地
# 参考 jq 的使用：https://shapeshed.com/jq-json/
# 另外参考 https://www.openshift.com/blog/transferring-files-in-and-out-of-containers-in-openshift-part-1-manually-copying-files
oc -n openshift-marketplace rsync $( oc -n openshift-marketplace get pods | grep my | awk '{print $1}'):/bundles.db .

# 另外一个制作 OpenShift Offline Operator Catalog 的工具
https://github.com/arvin-a/openshift-disconnected-operators

```

```
在另外的地方看到以下讨论内容，对解决在本地运行 

IHAC trying to use OLM in disconnected environment (cluster version is 4.3.0)
After successfully building the catalog, mirroring the operators images, and deploying the catalogsource object, no packagemanifest object can be found.


➜ oc get pods -n openshift-marketplace
NAME                                    READY   STATUS    RESTARTS   AGE
marketplace-operator-664f66c947-9l5l8   1/1     Running   0          92m
my-operator-catalog-crt56               1/1     Running   0          22m

➜ oc get catalogsource -n openshift-marketplace
NAME                  DISPLAY               TYPE   PUBLISHER   AGE
my-operator-catalog   My Operator Catalog   grpc   grpc        42m

➜ oc get packagemanifest -n openshift-marketplace
No resources found in openshift-marketplace namespace.


Any hint to debug this please ?

Another symptom when testing the catalog using grpc (https://docs.openshift.com/container-platform/4.3/operators/olm-restricted-networks.html#olm-testing-operator-catalog-image_olm-restricted-networks):


➜ grpcurl -plaintext localhost:50051 api.Registry/ListPackages
{
  "name": "3scale-operator"
}
[...]
{
  "name": "sriov-network-operator"
}

➜ grpcurl -plaintext -d '{"pkgName":"cluster-logging","channelName":"4.3"}' localhost:50051 api.Registry/GetBundleForChannel
ERROR:
  Code: Unknown
  Message: no such column: api_provider.operatorbundle_name


A small update:
The catalog pod in the openshift-marketplace was showing some error:

➜ oc logs my-operator-catalog-wtl9s
WARN[0000] unable to set termination log path            error="open /dev/termination-log: permission denied"
WARN[0000] couldn't migrate db                           database=/bundles.db error="attempt to write a readonly database" port=50051
INFO[0000] serving registry                              database=/bundles.db port=50051


It appears it cannot update the schema of db, therefore leading to the grpcurl error regarding the column api_provider.operatorbundle_name. 
We created a new image based on that one, onto which we switch from user 1001 (hardcoded inside the original image) to user root.
We then use that modified image for our CatalogSource. Now the pod is no more showing error and the command oc get packagemanifest is working properly.

TLDR: the CatalogSource image built using the official documentation [1] is using a unprivileged user which is not allowed to migrate its internal database. This leads to the unavailability of getting packagemanifest. Using custom image with root user fixes this issue.

[1] https://docs.openshift.com/container-platform/4.3/operators/olm-restricted-networks.html


```


### 探索一下 OpenShfit Service Mesh 
```
# 安装 OpenShift Service Mesh on OCP 4.x
https://docs.openshift.com/container-platform/4.5/service_mesh/v1x/preparing-ossm-installation.html

# Openshift Service Mesh 应用
https://docs.openshift.com/container-platform/4.5/service_mesh/v1x/prepare-to-deploy-applications-ossm.html#ossm-tutorial-bookinfo-install_deploying-applications-ossm-v1x

# Service Mesh Control Plane
https://maistra.io/docs/installation/controlplane/

# Install service mesh control plane by command line
https://access.redhat.com/documentation/en-us/openshift_container_platform/4.6/html/service_mesh/service-mesh-2-x#ossm-control-plane-deploy_installing-ossm

oc create namespace istio-system

cat > istio-installation-v2.yaml << EOF
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: basic
  namespace: istio-system
spec:
  version: v2.0
  tracing:
    type: Jaeger
    sampling: 10000
  addons:
    jaeger:
      name: jaeger
      install:
        storage:
          type: Memory
    kiali:
      enabled: true
      name: kiali
    grafana:
      enabled: true
EOF

oc create -f ./istio-installation-v2.yaml

# 查看 istio operator 日志
# 每行输出一条，参见：https://downey.io/notes/dev/kubectl-jsonpath-new-lines/
oc -n openshift-operators logs $(oc get pods -n openshift-operators -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep istio-operator )

# 日志显示
...
{"level":"info","ts":1605607188.4549549,"logger":"servicemeshcontrolplane-controller","msg":"Completed ServiceMeshControlPlane processing","ServiceMeshControlPlane":"istio-system/basic"}


# 获取 service mesh control plane 信息
oc get smcp -n istio-system

NAME    READY   STATUS            PROFILES    VERSION   AGE
basic   9/9     ComponentsReady   [default]   2.0.0.1   10m

# 创建 bookinfo namespace
oc new-project bookinfo

# 创建 ServiceMeshMemberRoll 添加 bookinfo namespace
cat > bookinfo-servicemeshmemberroll.yaml << EOF
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
spec:
  members:
  - bookinfo
EOF

oc create -f ./bookinfo-servicemeshmemberroll.yaml

# (optional) 另外一种将 namespace bookinfo 添加到 ServiceMeshMemberRoll 的方法
oc -n istio-system patch --type='json' smmr default -p '[{"op": "add", "path": "/spec/members", "value":["'"bookinfo"'"]}]'

# 部署 bookinfo 应用
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml

service/details created
serviceaccount/bookinfo-details created
deployment.apps/details-v1 created
service/ratings created
serviceaccount/bookinfo-ratings created
deployment.apps/ratings-v1 created
service/reviews created
serviceaccount/bookinfo-reviews created
deployment.apps/reviews-v1 created
deployment.apps/reviews-v2 created
deployment.apps/reviews-v3 created
service/productpage created
serviceaccount/bookinfo-productpage created
deployment.apps/productpage-v1 created

# 创建 ingressgateway bookinfo-gateway 和 virtualservice bookinfo
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/bookinfo-gateway.yaml

gateway.networking.istio.io/bookinfo-gateway created
virtualservice.networking.istio.io/bookinfo created

# 设置 GATEWAY_URL
export GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')

# 创建 destination rules，在这个例子里面，没有启用 mutual TLS
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml

destinationrule.networking.istio.io/productpage created
destinationrule.networking.istio.io/reviews created
destinationrule.networking.istio.io/ratings created
destinationrule.networking.istio.io/details created

# 访问 bookinfo
curl -o /dev/null -s -w "%{http_code}\n" http://$GATEWAY_URL/productpage

# 多次访问 productpage 后，会生成一些 tracing 数据
for i in $(seq 1 50); do curl -o /dev/null -s -w "%{http_code}\n" http://$GATEWAY_URL/productpage ;done

# 然后可以访问 jaeger，查看 tracing 数据
export JAEGER_URL=$(oc get route -n istio-system jaeger -o jsonpath='{.spec.host}')

# 然后可以访问 kiali，查看 Data visualization and observability
export KIALI_URL=$(oc get route -n istio-system kiali -o jsonpath='{.spec.host}')
```

### OCP 4.6 RHCOS 的裸金属离线启动参数

|参数|说明|
|---|---|
|coreos.liveiso=|${LIVEISO_VOLID}|
|ignition.firstboot||
|ignition.platform.id=|metal|
|coreos.inst.install_dev=|sda|
|coreos.inst.ignition_url=|http://10.66.208.138:8080/ignition/bootstrap-static.ign|
|ip=||
|namesserver=||


### 获取 opm 命令行工具并且在 RHEL 7 上运行
opm 是 Operator Framework 提供的用来处理 Operator Bundle Format 的命令行工具
https://docs.openshift.com/container-platform/4.6/cli_reference/opm-cli.html#opm-cli

```

export REG_CREDS=/root/pull-secret-2.json

podman login registry.redhat.io

mkdir -p opm-test
pushd opm-test

oc image extract registry.redhat.io/openshift4/ose-operator-registry:v4.6 \
    -a ${REG_CREDS} \
    --path /usr/bin/opm:. \
    --confirm

cat > Dockerfile << EOF
FROM registry.redhat.io/ubi8/ubi

COPY opm /usr/bin/opm

RUN chmod a+x /usr/bin/opm

ENTRYPOINT ["/usr/bin/opm"]
EOF

podman build . -t opm:latest

cat > /usr/local/bin/opm << 'EOF'
#!/bin/bash
#
# Doing it this way is just easier than trying to install python3 on EL7
podman run --rm -ti localhost/opm:latest $*
##
##
EOF

chmod a+x /usr/local/bin/opm

```

### Dockerfile 参考
https://docs.docker.com/engine/reference/builder/

### 在本地添加 bookinfo 的镜像
```
# 获取所需 pod 名称
oc get pods -n bookinfo -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' 

# 获取所需镜像 
oc get pods -n bookinfo -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | while read i ; do oc -n bookinfo describe pod ${i} | grep 'pulling image' | tail -1 | sed -e 's|^.*Back-off pulling image "||' -e 's|"||' ; done

# pull image from server

# 生成镜像下载列表文件
cat > bookinfo.image.lst << EOF
maistra/examples-bookinfo-details-v1:1.2.0
maistra/examples-bookinfo-details-v2:1.2.0
maistra/examples-bookinfo-productpage-v1:1.2.0
maistra/examples-bookinfo-ratings-v1:1.2.0
maistra/examples-bookinfo-ratings-v2:1.2.0
maistra/examples-bookinfo-reviews-v1:1.2.0
maistra/examples-bookinfo-reviews-v2:1.2.0
maistra/examples-bookinfo-reviews-v3:1.2.0
EOF

# pull image
cat bookinfo.image.lst | while read i ; do podman pull ${i} ; done

# 保存 image
mkdir -p maistra-examples-bookinfo

cat bookinfo.image.lst | while read i ; do
  basename=$(echo $i | awk -F'/' '{print $2}' | awk -F':' '{print $1}' )
  podman save -o maistra-examples-bookinfo/${basename}.tar ${i}
done

tar zcvf maistra-examples-bookinfo.tar.gz maistra-examples-bookinfo/ 

# 拷贝 maistra-examples-bookinfo.tar.gz 到目标环境

# 加载镜像到目标
tar zxvf maistra-examples-bookinfo.tar.gz

for i in maistra-examples-bookinfo/*.tar ; do
  podman load -i $i
done

export LOCAL_REGISTRY='helper.cluster-0001.rhsacn.org:5000'
export LOCAL_SECRET_JSON="${HOME}/pull-secret-2.json"

cat bookinfo.image.lst | while read i 
do 
  repo=$( echo $i | awk -F'/' '{print $1}' )
  imagename=$( echo $i | awk -F'/' '{print $2}' | awk -F':' '{print $1}' )
  tag=$( echo $i | awk -F':' '{print $2}' )

  podman tag docker.io/${repo}/${imagename}:${tag} ${LOCAL_REGISTRY}/${repo}/${imagename}:${tag}

  podman push --authfile ${LOCAL_SECRET_JSON} ${LOCAL_REGISTRY}/${repo}/${imagename}:${tag}
done

# install jq 
# sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# sudo yum install jq -y
# sudo yum-config-manager --disable epel

cat bookinfo.image.lst | while read i 
do
  source="docker.io"
  repo=$( echo $i | awk -F'/' '{print $1}' )
  imagename=$( echo $i | awk -F'/' '{print $2}' | awk -F':' '{print $1}' )
  tag=$( echo $i | awk -F':' '{print $2}' )

  # shadigits=$( skopeo inspect --authfile /root/pull-secret-2.json docker://${LOCAL_REGISTRY}/${i} | jq .Digest | sed -e 's|"||g' )
  shadigits=$( skopeo inspect docker://${source}/${i} | jq .Digest | sed -e 's|"||g' )

  echo ${source}/${repo}/${imagename}@${shadigits}
done

cat > tmp/registry-images-bookinfo.lst << EOF
docker.io/maistra/examples-bookinfo-details-v1@sha256:f79c12fc7ea821ec7bca5697a6863d1cdb1ddb90bf9d5232c6d7aae6e3d47213
docker.io/maistra/examples-bookinfo-details-v2@sha256:9102ba929ba9ea6425d91b9a51c7dda4fcb0c728700e23708014cccd43939d5a
docker.io/maistra/examples-bookinfo-productpage-v1@sha256:82154b932cded17b6bdd45274e33472793a666ef33a576189a83d48ab8ea2348
docker.io/maistra/examples-bookinfo-ratings-v1@sha256:20fe8ed83ec6282640488ee7d50d9c178e277230ae440cae29ed6d2ca8417730
docker.io/maistra/examples-bookinfo-ratings-v2@sha256:33e9afa3067be55758c10cc65c0b84cc14949afba10d943df853250b6e275c54
docker.io/maistra/examples-bookinfo-reviews-v1@sha256:48b555a04589a7bf64a8eb1390d18e4e2f1f95c3604b5ce92029ad0e92a955c1
docker.io/maistra/examples-bookinfo-reviews-v2@sha256:a4306ef6cd1698639d3566b38bae7ed8987e9df3e2dc5da5940f542cdb0e3831
docker.io/maistra/examples-bookinfo-reviews-v3@sha256:c94bb71b3fbc624d32351881c385aa931164edcb519c0cdf7a99728b660a2028
EOF

cat /dev/null > ./tmp/mapping-bookinfo.txt
  for source in `cat ./tmp/registry-images-bookinfo.lst`; do  local=`echo $source|awk -F'@' '{print $1}'|sed 's|docker.io|helper.cluster-0001.rhsacn.org:5000|g'`   ; echo "$source=$local" >> ./tmp/mapping-bookinfo.txt; done

# 使用 skopeo copy --all 拷贝镜像，保存到本地目录
# 参见：https://github.com/containers/skopeo/blob/master/README.md
for source in `cat ./tmp/registry-images-bookinfo.lst`; do  localdir="/root/tmp/mirror/"`echo $source|awk -F'@' '{print $1}'| awk -F'/' '{print $3}'`; mkdir -p $localdir; 
echo skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://$source dir://$localdir; skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://$source dir://$localdir; echo; done

# 生成压缩文件
tar zcvf /root/tmp/bookinfo-mirror.tar.gz /root/tmp/mirror

# 拷贝压缩文件到目标主机
# 解压缩文件到指定目录
mkdir -p /root/tmp/mirror
tar zxvf bookinfo-mirror.tar.gz -C /

# 使用 skopeo copy --all 拷贝镜像，从本地目录上传到本地镜像仓库
for source in `cat ./tmp/registry-images-bookinfo.lst`; do  localdir="/root/tmp/mirror/"`echo $source|awk -F'@' '{print $1}'| awk -F'/' '{print $3}'`; local=`echo $source|awk -F'@' '{print $1}'|sed 's/docker.io/helper.cluster-0001.rhsacn.org:5000/g'`; 
echo skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all dir://$localdir docker://$local; skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all dir://$localdir docker://$local; echo; done

cat /dev/null > ./tmp/image-policy-bookinfo.txt
  for source in `cat ./tmp/registry-images-bookinfo.lst`; do  local=`echo $source|awk -F'@' '{print $1}'|sed 's/docker.io/helper.cluster-0001.rhsacn.org:5000/g'` ; mirror=`echo $source|awk -F'@' '{print $1}'`; echo "  - mirrors:" >> ./tmp/image-policy-bookinfo.txt; echo "    - $local" >> ./tmp/image-policy-bookinfo.txt; echo "    source: $mirror" >> ./tmp/image-policy-bookinfo.txt; done

cat <<EOF > ./tmp/bookinfo-ImageContentSourcePolicy.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: bookinfo
spec:
  repositoryDigestMirrors:
$(cat ./tmp/image-policy-bookinfo.txt)
EOF



oc apply -f ./tmp/bookinfo-ImageContentSourcePolicy.yaml 

# 使用 oc json type patch 方法
# https://bierkowski.com/openshift-cli-morsels-updating-objects-non-interactively/
oc patch deployment productpage-v1 -n bookinfo --type json \
    -p '[{"op": "replace", "path": "/spec/template/spec/containers/image", "value": "docker.io/maistra/examples-bookinfo-productpage-v1:1.2.0"}]'

oc patch deployment productpage-v1 -n bookinfo --patch='{"spec":{"template":{"spec":{"containers":[{"name": "productpage", "image":"helper.cluster-0001.rhsacn.org:5000/maistra/examples-bookinfo-productpage-v1:1.2.0"}]}}}}'

oc patch deployment details-v1 -n bookinfo --patch='{"spec":{"template":{"spec":{"containers":[{"name": "details", "image":"helper.cluster-0001.rhsacn.org:5000/maistra/examples-bookinfo-details-v1:1.2.0"}]}}}}'

oc patch deployment ratings-v1 -n bookinfo --patch='{"spec":{"template":{"spec":{"containers":[{"name": "ratings", "image":"helper.cluster-0001.rhsacn.org:5000/maistra/examples-bookinfo-ratings-v1:1.2.0"}]}}}}'

oc patch deployment reviews-v1 -n bookinfo --patch='{"spec":{"template":{"spec":{"containers":[{"name": "reviews", "image":"helper.cluster-0001.rhsacn.org:5000/maistra/examples-bookinfo-reviews-v1:1.2.0"}]}}}}'

oc patch deployment reviews-v2 -n bookinfo --patch='{"spec":{"template":{"spec":{"containers":[{"name": "reviews", "image":"helper.cluster-0001.rhsacn.org:5000/maistra/examples-bookinfo-reviews-v2:1.2.0"}]}}}}'

oc patch deployment reviews-v3 -n bookinfo --patch='{"spec":{"template":{"spec":{"containers":[{"name": "reviews", "image":"helper.cluster-0001.rhsacn.org:5000/maistra/examples-bookinfo-reviews-v3:1.2.0"}]}}}}'

oc create secret docker-registry local-pull-secret \
    --namespace bookinfo \
    --docker-server=helper.cluster-0001.rhsacn.org:5000 \
    --docker-username=dummy \
    --docker-password=dummy
oc patch sa default -n bookinfo --type='json' -p='[{"op":"add","path":"/imagePullSecrets/-", "value":{"name":"local-pull-secret"}}]'



```

### OpenShift 安装过程中查看日志
```
# 查看 cluster-monitoring-operator 日志
oc -n openshift-monitoring logs $(oc get pods -n openshift-monitoring -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep cluster-monitoring-operator ) -c cluster-monitoring-operator

# 查看 kube-apiserver-operator 日志
oc -n openshift-kube-apiserver-operator logs $(oc get pods -n openshift-kube-apiserver-operator -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep kube-apiserver-operator ) 
```

### Ceph placement groups autoscale
https://avengermojo.medium.com/ceph-placement-groups-autoscale-9981aeccbc21
```
ceph osd pool set rbd pg_num 64
ceph osd pool autoscale-status
ceph osd pool set rbd target_size_ratio 0.3
ceph osd pool set rbd pg_num_min 64
ceph mgr module enable pg_autoscaler
ceph osd pool autoscale-status
ceph osd pool set rbd target_size_ratio 0.1
ceph osd pool set rbd pg_autoscale_mode on
ceph osd pool stats
ceph health detail
```

### 高级命令 OpenShift oc 
```
# 根据需要显示 .metadata.name 和 kubernetes.io/arch 相关的 .metadata.labels
oc get nodes --template='{{ range .items }}{{ .metadata.name }}{{ printf " - %s\n" (index .metadata.labels "kubernetes.io/arch")}}{{ end }}'

# 同上并且打印所需标题
oc get nodes --template='{{ printf "Node\t\t\t\tArch\n" }}{{ range .items }}{{ printf "%s\t" .metadata.name }}{{ printf "%s\n" (index .metadata.labels "kubernetes.io/arch")}}{{ end }}'
```

### 修改建议
```
6.3.2.3
预制条件 - 建议添加
中心镜像仓库和本地镜像仓库对接完成

6.3.2.4
将“测试组网”内容调整到“测试目的”

6.8.1
将“测试组网”内容调整到“测试目的”
预期结果：
3. 总共有13个pod
测试步骤：
14. 并恢复某个历史版本

6.8.2
将“测试组网”内容调整到“测试目的”
并删除“区别于第8.7.11章定义的自动伸缩器，”

6.9.1
将“测试组网”内容调整到“测试目的”

6.9.2.1
将“测试组网”内容调整到“测试目的”

6.9.2.2
将“测试组网”内容调整到“测试目的”

6.9.3
将“测试组网”内容调整到“测试目的”
```

### OpenShift 如何触发新的部署
https://cookbook.openshift.org/application-lifecycle-management/how-can-i-trigger-a-new-deployment-of-an-application.html
```
# 如果使用 DeploymentConfig
oc rollout latest dc/cookbook

# 如果使用 Deployment, StatefulSet, DaemonSet, ReplicaSet or ReplicationController
oc patch deployment/cookbook --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

oc patch deployment/reviews-v2 -n bookinfo --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"
```


### 关于 imagecontentsourcepolicy 的说明
https://docs.openshift.com/container-platform/4.4/rest_api/operator_apis/imagecontentsourcepolicy-operator-openshift-io-v1alpha1.html

repositoryDigestMirrors allows images referenced by image digests in pods to be pulled from alternative mirrored repository locations. The image pull specification provided to the pod will be compared to the source locations described in RepositoryDigestMirrors and the image may be pulled down from any of the mirrors in the list instead of the specified repository allowing administrators to choose a potentially faster mirror. Only image pull specifications that have an image disgest will have this behavior applied to them - tags will continue to be pulled from the specified repository in the pull spec. Each “source” repository is treated independently; configurations for different “source” repositories don’t interact. When multiple policies are defined for the same “source” repository, the sets of defined mirrors will be merged together, preserving the relative order of the mirrors, if possible. For example, if policy A has mirrors a, b, c and policy B has mirrors c, d, e, the mirrors will be used in the order a, b, c, d, e. If the orders of mirror entries conflict (e.g. a, b vs. b, a) the configuration is not rejected but the resulting order is unspecified.


### How to find and resolve devicemapper 'device or resource busy' error
https://success.mirantis.com/article/how-to-find-and-resolve-devicemapper-device-or-resource-busy-error

```
cat > find-busy-mnt.sh << 'EOF'
#!/bin/bash

# A simple script to get information about mount points and pids and their
# mount namespaces.

if [ $# -ne 1 ];then
  echo "Usage: $0 <devicemapper-device-id>"
  exit 1
fi

ID=$1

MOUNTS=`find /proc/*/mounts | xargs grep $ID 2>/dev/null`

[ -z "$MOUNTS" ] &&  echo "No pids found" && exit 0

printf "PID\tNAME\t\tMNTNS\n"
echo "$MOUNTS" | while read LINE; do
  PID=`echo $LINE | cut -d ":" -f1 | cut -d "/" -f3`
  # Ignore self and thread-self
  if [ "$PID" == "self" ] || [ "$PID" == "thread-self" ]; then
    continue
  fi
  NAME=`ps -q $PID -o comm=`
  MNTNS=`readlink /proc/$PID/ns/mnt`
  printf "%s\t%s\t\t%s\n" "$PID" "$NAME" "$MNTNS"
done
EOF

chmod +x ./find-busy-mnt.sh

./find-busy-mnt.sh 0bfafa146431771f6024dcb9775ef47f170edb2f152f71916ba44209ca6120a

```


### 替换出问题的 master - OpenShift 4.5
https://docs.openshift.com/container-platform/4.5/backup_and_restore/replacing-unhealthy-etcd-member.html
```
[root@helper postinstall]# oc get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.message}{"\n"}'
2 of 3 members are available, master1.cluster-0001.rhsacn.org is unhealthy

# 参考以下步骤替换一个不健康的 etcd member
# https://docs.openshift.com/container-platform/4.5/backup_and_restore/replacing-unhealthy-etcd-member.html#restore-replace-stopped-etcd-member_replacing-unhealthy-etcd-member

# 获取可用 etcd member
[root@helper postinstall]# oc get pods -n openshift-etcd | grep etcd
etcd-master0.cluster-0001.rhsacn.org                4/4     Running     0          13d
etcd-master1.cluster-0001.rhsacn.org                0/4     Init:0/2    0          13d
etcd-master2.cluster-0001.rhsacn.org                4/4     Running     0          13d

# 登录可用 etcd member
[root@helper postinstall]# oc rsh -n openshift-etcd etcd-master0.cluster-0001.rhsacn.org
Defaulting container name to etcdctl.
Use 'oc describe pod/etcd-master0.cluster-0001.rhsacn.org -n openshift-etcd' to see all of the containers in this pod.
sh-4.2# 

# 查看成员列表
sh-4.2# etcdctl member list -w table
+------------------+---------+---------------------------------+----------------------------+----------------------------+------------+
|        ID        | STATUS  |              NAME               |         PEER ADDRS         |        CLIENT ADDRS        | IS LEARNER |
+------------------+---------+---------------------------------+----------------------------+----------------------------+------------+
|  8bfa54d4d3a93a1 | started | master2.cluster-0001.rhsacn.org | https://10.66.208.142:2380 | https://10.66.208.142:2379 |      false |
| 5e7fc52a2e455265 | started | master0.cluster-0001.rhsacn.org | https://10.66.208.140:2380 | https://10.66.208.140:2379 |      false |
| fbb0de49b9368d62 | started | master1.cluster-0001.rhsacn.org | https://10.66.208.141:2380 | https://10.66.208.141:2379 |      false |
+------------------+---------+---------------------------------+----------------------------+----------------------------+------------+

# 移除有问题的 etcd 成员:
sh-4.2# etcdctl member remove fbb0de49b9368d62
Member fbb0de49b9368d62 removed from cluster b632277e7db1b57f

# 再次确认 etcd 成员
sh-4.2# etcdctl member list -w table
+------------------+---------+---------------------------------+----------------------------+----------------------------+------------+
|        ID        | STATUS  |              NAME               |         PEER ADDRS         |        CLIENT ADDRS        | IS LEARNER |
+------------------+---------+---------------------------------+----------------------------+----------------------------+------------+
|  8bfa54d4d3a93a1 | started | master2.cluster-0001.rhsacn.org | https://10.66.208.142:2380 | https://10.66.208.142:2379 |      false |
| 5e7fc52a2e455265 | started | master0.cluster-0001.rhsacn.org | https://10.66.208.140:2380 | https://10.66.208.140:2379 |      false |
+------------------+---------+---------------------------------+----------------------------+----------------------------+------------+

# 列出 old secret
[root@helper postinstall]# oc get secrets -n openshift-etcd | grep master1
etcd-peer-master1.cluster-0001.rhsacn.org              kubernetes.io/tls                     2      13d
etcd-serving-master1.cluster-0001.rhsacn.org           kubernetes.io/tls                     2      13d
etcd-serving-metrics-master1.cluster-0001.rhsacn.org   kubernetes.io/tls                     2      13d

# 删除 peer setret
oc delete secret -n openshift-etcd etcd-peer-master1.cluster-0001.rhsacn.org

# 删除 serving secret
oc delete secret -n openshift-etcd etcd-serving-master1.cluster-0001.rhsacn.org

# 删除 metrics secret
oc delete secret -n openshift-etcd etcd-serving-metrics-master1.cluster-0001.rhsacn.org

# 执行 openshift-install create ignition-configs 重新生成 ign 文件
# 更新 web server 上的 ign 文件
# 重新安装 master
# 重新批准 master node 的 csr
```

### 报错处理 openshift-image-registry/image-pruner 相关的报错处理
https://docs.openshift.com/container-platform/4.4/applications/pruning-objects.html
```
# Job openshift-image-registry/image-pruner-1606089600 failed to complete.
# 把imagepruner给停掉
# https://bugzilla.redhat.com/show_bug.cgi?id=1852501#c24
oc patch imagepruner.imageregistry/cluster --patch '{"spec":{"suspend":true}}' --type=merge
oc -n openshift-image-registry delete jobs --all
```

### How to use entitled image builds to build DriverContainers with UBI on OpenShift
https://www.openshift.com/blog/how-to-use-entitled-image-builds-to-build-drivercontainers-with-ubi-on-openshift

### 报错处理 Cluster operator kube-controller-manager has been degraded for 10 mins. Operator is degraded because StaticPods_Error and cluster upgrades will be unstable.
错误消息
```
Cluster operator kube-controller-manager has been degraded for 10 mins. Operator is degraded because StaticPods_Error and cluster upgrades will be unstable.
View details
```

处理方法参见：
https://access.redhat.com/solutions/4382761
```
# 获取详细状态
oc get clusteroperator kube-controller-manager -o yaml | grep -i status -A10
status:
  conditions:
  - lastTransitionTime: "2020-11-23T07:47:23Z"
    message: 'StaticPodsDegraded: pods "kube-controller-manager-master1.cluster-0001.rhsacn.org"
      not found'
    reason: StaticPods_Error
# 重启对应 master 节点的 kubelet
ssh core@<master1> sudo systemctl restart kubelet
# 或者
oc debug node/master1.cluster-0001.rhsacn.org -- chroot /host systemctl restart kubelet

# 删除 openshift-kube-controller-manager-operator pod 触发重新创建 pod
oc -n openshift-kube-controller-manager-operator delete pod $(oc -n openshift-kube-controller-manager-operator get pods -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep kube-controller-manager-operator )

# 获取 openshift-kube-controller-manager-operator 日志
oc -n openshift-kube-controller-manager-operator logs $(oc -n openshift-kube-controller-manager-operator get pods -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep kube-controller-manager-operator )

# 实验检测不成功
# 参考 https://access.redhat.com/solutions/4849711
# 重新部署 static pods 

# 重新部署 static pods kube-apiserver
oc patch kubeapiserver/cluster --type merge -p "{\"spec\":{\"forceRedeploymentReason\":\"Forcing new revision with random number $RANDOM to make message unique\"}}"
oc get clusteroperator kube-apiserver -o yaml | grep -i status -A10

# 重新部署 static pods kube-controller-manager
oc patch kubecontrollermanager/cluster --type merge -p "{\"spec\":{\"forceRedeploymentReason\":\"Forcing new revision with random number $RANDOM to make message unique\"}}"
oc get clusteroperator kube-controller-manager -o yaml | grep -i status -A10

# 重新部署 static pods kube-scheduler
oc patch kubescheduler/cluster --type merge -p "{\"spec\":{\"forceRedeploymentReason\":\"Forcing new revision with random number $RANDOM to make message unique\"}}"
oc get clusteroperator kube-scheduler -o yaml | grep -i status -A10

```

### 检查 openshift 部署问题
```
在 master 上执行命令，查看频繁重启的 pod 是哪个 
sudo crictl ps -a 
```

### OpenShift 4 与 CIFS
https://www.openshift.com/blog/cifs-and-openshift-using-the-container-storage-interface-1

### 问题分析: istio bookinfo example 访问 productpage 返回 503
```
# 参见：https://github.com/istio/istio/issues/7564
$ curl -o /dev/null -s -w "%{http_code}\n" http://$GATEWAY_URL/productpage
503
$ env | grep GATEWAY
GATEWAY_URL=istio-ingressgateway-istio-system.apps.cluster-0001.rhsacn.org

# 网关信息
kubectl get gateway -n istio-system -o yaml

# 经过调查我的问题是没有创建 smmr 
# 知道问题后处理起来就简单了，创建 smmr，然后触发新的部署
```

### OpenShift 4.6 如何修剪 olm index image
https://docs.openshift.com/container-platform/4.6/operators/admin/olm-restricted-networks.html#olm-pruning-index-image_olm-restricted-networks

### 使用 mutating admission webhook 来调整应用
https://medium.com/ovni/writing-a-very-basic-kubernetes-mutating-admission-webhook-398dbbcb63ec

### 更新证书


```

oc create configmap user-ca-bundle --from-file=ca-bundle.crt=/opt/registry/certs/domain.crt -n openshift-config -o yaml --dry-run | oc replace -f -

oc patch proxy.config.openshift.io/cluster -p '{"spec":{"trustedCA":{"name":"user-ca-bundle"}}}'  --type=merge

oc patch proxy/cluster \
     --type=merge \
     --patch='{"spec":{"trustedCA":{"name":"user-ca-bundle"}}}'
```

### check release sha256 info
```
oc adm release info quay.io/openshift-release-dev/ocp-release:4.6.1-x86_64
...
oc adm release info quay.io/openshift-release-dev/ocp-release:4.6.5-x86_64

# 另外可以在以下网址查询
# https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.6.1/release.txt
# https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.6.5/release.txt
```

### 安装 image builder
参考：https://developers.redhat.com/blog/2019/05/08/red-hat-enterprise-linux-8-image-builder-building-custom-system-images/

更新的内容参见以下链接：
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/composing_installing_and_managing_rhel_for_edge_images/index
```
# 安装 image builder on rhel8
yum install osbuild-composer composer-cli cockpit-composer bash-completion

# 开启防火墙
firewall-cmd --add-service=cockpit && firewall-cmd --add-service=cockpit --permanent
firewall-cmd --list-services

# 启用并且启动服务 
# 有些步骤并不准确，需要进一步检验
systemctl enable --now osbuild-composer.socket
systemctl enable cockpit.socket

# 配置 composer-cli bash 补齐
source  /etc/bash_completion.d/composer-cli
```

### 查看 machine-config-operator 的日志
```
oc -n openshift-machine-config-operator logs $(oc get pods -n openshift-machine-config-operator -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep machine-config-operator)

# 查看 machine-config-operator 里的每个 pod 的日志
oc get pods -n openshift-machine-config-operator -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | while read pods ; do echo ${pods}; oc -n openshift-machine-config-operator logs ${pods} ; echo ; done
```

### Building a RHEL gold image for Azure
https://redhatsummitlabs.gitlab.io/building-a-rhel-gold-image-for-azure/

### 如何启用 cockpit 的 debug 模式
https://access.redhat.com/solutions/3387651

具体步骤在 RHEL 8 上还没有实验过
```
# 生成 cockpit 配置目录
mkdir -p /etc/systemd/system/cockpit.service.d

# 生成 debug.conf
printf '[Service]\nEnvironment=G_MESSAGES_DEBUG=cockpit-ws,cockpit-bridge\nUser=root\nGroup=\n' > /etc/systemd/system/cockpit.service.d/debug.conf

# 重新加载并重启 cockpit
systemctl daemon-reload
systemctl restart cockpit

# 查看 cockpit debug 日志
journalctl -u cockpit.service

# 禁用 cockpit debug 的步骤
# 删除 debug.conf
rm /etc/systemd/system/cockpit.service.d/debug.conf

# 重新加载并重启 cockpit
systemctl daemon-reload
systemctl restart cockpit

# 查看 composer sources
composer-cli sources list 

baseos
appstream

composer-cli sources info baseos
composer-cli sources info appstream


# 查看 composer modules
composer-cli modules list

# 查看 blueprints
composer-cli blueprints list
blueprint_test_rhel_for_edge

# 查看 blueprints 详情
composer-cli blueprints show blueprint_test_rhel_for_edge

name = "blueprint_test_rhel_for_edge"
description = "blueprint test rhel for edge"
version = "0.0.0"
packages = []
modules = []
groups = []

# 保存 blueprints 
composer-cli blueprints save blueprint_test_rhel_for_edge

cat blueprint_test_rhel_for_edge.toml 
name = "blueprint_test_rhel_for_edge"
description = "blueprint test rhel for edge"
version = "0.0.0"
packages = []
modules = []
groups = []

# 更新 blueprints 
cat > blueprint_test_rhel_for_edge.toml <<EOF
name = "blueprint_test_rhel_for_edge"
description = "blueprint test rhel for edge"
version = "0.0.1"
modules = []
groups = []

[[packages]]
name = "bash"
version = "*"

[[packages]]
name = "podman"
version = "*"
EOF

# 提交 blueprints
composer-cli blueprints push blueprint_test_rhel_for_edge.toml

# 查看 blueprints 变更历史
composer-cli blueprints changes blueprint_test_rhel_for_edge

blueprint_test_rhel_for_edge
    2020-11-27T05:22:36Z  6da785c8e1ac2baade0446fc3b6901d62bae65ae
    Recipe blueprint_test_rhel_for_edge, version 0.0.1 saved.

    2020-11-26T08:08:47Z  866d0118eb95711ad7b7e1742d5b9393cd73b54f
    Recipe blueprint_test_rhel_for_edge, version  saved.

# 更新 blueprints，添加用户到 blueprints，注意更新版本号 

cat > blueprint_test_rhel_for_edge.toml <<EOF
name = "blueprint_test_rhel_for_edge"
description = "blueprint test rhel for edge"
version = "0.0.2"
modules = []
groups = []

[[packages]]
name = "bash"
version = "*"

[[packages]]
name = "podman"
version = "*"

[[customizations.user]]
name = "admin"
description = "admin"
password = "$6$PUNf5x.lEchI551u$WKDecMqirPipvFHivMtyw/bys6CUwZeWAl9m819/APhCgNuDaHn06sRgQp5956z5cjh73shU2WsbXZQx68yX//"
home = "/home/admin/"
groups = ["wheel"]
EOF

# 提交 blueprints
composer-cli blueprints push blueprint_test_rhel_for_edge.toml

# 查看 blueprints 变更历史
composer-cli blueprints changes blueprint_test_rhel_for_edge

# 在 aws ec2 上注册系统到 Red Hat 
subscription-manager register
subscription-manager attach --auto

# 在 aws ec2 上禁用 aws rhui repo 以及 epel
yum-config-manager --disable rhui-client-config-server-8
yum-config-manager --disable rhel-8-baseos-rhui-rpms
yum-config-manager --disable rhel-8-appstream-rhui-rpms
yum-config-manager --disable epel
yum-config-manager --disable epel-modular


# 生成 compose image，image 类型为 rhel-edge-commit
composer-cli compose start blueprint_test_rhel_for_edge rhel-edge-commit

# 检查 compose 状态
composer-cli compose status
9100b821-d987-43f8-9471-c39da13b7698 RUNNING  Fri Nov 27 06:49:23 2020 blueprint_test_rhel_for_edge 0.0.2 rhel-edge-commit 

# 检查 compose info 和 日志
composer-cli compose info $(composer-cli compose status | awk '{print $1}')
composer-cli compose log $(composer-cli compose status | awk '{print $1}')

# osbuild-composer 相关运行时文件
find /var/lib/osbuild-composer

# 当 compose 状态变成 FINISHED 之后，下载 image
# 下载位置为 /var/lib/osbuild-composer/composer/results/<UUID>/compose/
composer-cli compose image $(composer-cli compose status | awk '{print $1}')

# 在工作目录下生成了格式为 UUID-commit.tar 的文件
ls -l
-rw-r--r--. 1 root root 655616000 Nov 27 07:05 9100b821-d987-43f8-9471-c39da13b7698-commit.tar

# 拷贝 UUID-commit.tar 到另外一台主机
mkdir -p /var/www/html/rhel-for-edge
mv /root/9100b821-d987-43f8-9471-c39da13b7698-commit.tar /var/www/html/rhel-for-edge/

# 切换工作目录到 /var/www/html/rhel-for-edge
pushd /var/www/html/rhel-for-edge

# 解压缩 
tar xvf 9100b821-d987-43f8-9471-c39da13b7698-commit.tar

# 列出解压缩后的文件及目录
#  - compose.json 文件
#  - repo 目录
ls -ltr
total 640256
-rw-r--r--. 1 root root 655616000 Nov 30 10:48 9100b821-d987-43f8-9471-c39da13b7698-commit.tar
-rw-r--r--. 1 root root       530 Nov 27 14:57 compose.json
drwxr-xr-x. 7 root root       134 Nov 27 14:57 repo

# 根据 compose.json 文件可以获取 ref 和 ostree-commit
# ref: rhel/8/x86_64/edge
# ostree-commit: b51ade2ec4700d27dd8858cb8f98930afbcdc346ff3a219204bff296178a94d5
cat compose.json | jq . 
{
  "ref": "rhel/8/x86_64/edge",
  "ostree-n-metadata-total": 9999,
  "ostree-n-metadata-written": 3617,
  "ostree-n-content-total": 28768,
  "ostree-n-content-written": 24502,
  "ostree-n-cache-hits": 0,
  "ostree-content-bytes-written": 1444849186,
  "ostree-commit": "b51ade2ec4700d27dd8858cb8f98930afbcdc346ff3a219204bff296178a94d5",
  "ostree-content-checksum": "ac7a78905e6235186d09822134ee93852da5eeda8f400f2e8a82adf444f2d3a9",
  "ostree-timestamp": "2020-11-27T06:57:01Z",
  "rpm-ostree-inputhash": "725127140606eb8adce222a38ad3340d38b5e7655680dcd2d797d0058b3b8a87"
}

# 检查 commit 里包含的 rpm
rpm-ostree db list rhel/8/x86_64/edge --repo=repo
ostree commit: rhel/8/x86_64/edge (b51ade2ec4700d27dd8858cb8f98930afbcdc346ff3a219204bff296178a94d5)
 ModemManager-1.10.8-2.el8.x86_64
 ...
 zlib-1.2.11-16.el8_2.x86_64


# 参考 fedora atomic 的安装方式
# 参考 https://www.projectatomic.io/docs/fedora_atomic_bare_metal_installation/

# 真正需要借鉴的内容应来自
# 参考 https://github.com/osbuild/rhel-for-edge-demo
# 生成 edge.ks 文件

# 制作启动 iso（可选）
# 这个命令在 RHEL8 上没有
# 这个命令在 fedora 里有
# mkksiso edge.ks rhel-8.3-x86_64-boot.iso boot.iso

# 安装 rhel for edge
# 用 virt-install 可以通过 --initrd-inject 和 --extra-args 传递 kickstart 文件
virt-install --name="jwang-rhel-for-edge" --vcpus=2 --ram=4096 \
--disk path=/data/kvm/jwang-rhel-for-edge-01.qcow2,bus=virtio,size=20 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --location /var/www/html/rhel-for-edge-repo/rhel-8.3-x86_64-boot.iso \
--initrd-inject /tmp/edge.ks --extra-args='ks=file:/edge.ks'

# 更新一下 blueprint: 设置用户的口令，添加 root ssh_key
ssh-keygen -t rsa -f /root/.ssh/edge -N ''
ssh_key=$(cat /root/.ssh/edge.pub)

config_password=$(python3 -c 'import crypt; print(crypt.crypt("redhat", crypt.mksalt(crypt.METHOD_SHA512)))')

cat > blueprint_test_rhel_for_edge.toml <<EOF
name = "blueprint_test_rhel_for_edge"
description = "blueprint test rhel for edge"
version = "0.0.3"
modules = []
groups = []

[[packages]]
name = "bash"
version = "*"

[[packages]]
name = "podman"
version = "*"

[[customizations.user]]
name = "admin"
description = "admin"
password = "${config_password}"
home = "/home/admin/"
groups = ["wheel"]

[[customizations.user]]
name = "root"
key = "${ssh_key}"
EOF

# 提交 blueprints
composer-cli blueprints push blueprint_test_rhel_for_edge.toml

# 查看 blueprints 变更历史
composer-cli blueprints changes blueprint_test_rhel_for_edge

# 生成 compose image
# image 类型为 rhel-edge-commit
# parent 为 rpm-ostree status 输出
# 参考：https://weldr.io/lorax/composer-cli.html
composer-cli compose start-ostree --parent b51ade2ec4700d27dd8858cb8f98930afbcdc346ff3a219204bff296178a94d5 blueprint_test_rhel_for_edge rhel-edge-commit
Compose 2d09f4f3-fc22-4bec-adc6-5f94aa779b12 added to the queue

# 检查 compose info 和 日志
version="0.0.3"
composer-cli compose info $(composer-cli compose status | grep $version | awk '{print $1}')
composer-cli compose log $(composer-cli compose status | grep $version | awk '{print $1}')

# 当 compose 状态变成 FINISHED 之后，下载 image
version="0.0.3"
composer-cli compose image $(composer-cli compose status | grep $version | awk '{print $1}')

# 将更新的 image 拷贝到 web 服务器上

# 在 rhel for edge 服务器上查看可用更新
rpm-ostree status -v 
# 如果没有可用更新，则检查更新
rpm-ostree upgrade --check

note: automatic updates (stage) are enabled
==== AUTHENTICATING FOR org.projectatomic.rpmostree1.upgrade ====
Authentication is required to update software
Multiple identities can be used for authentication:
 1.  admin
 2.  core
Choose identity to authenticate as (1-2): 2
Password: 
==== AUTHENTICATION COMPLETE ====
2 metadata, 0 content objects fetched; 15 KiB transferred in 0 seconds; 0 bytes content written
AvailableUpdate:
      Timestamp: 2020-12-01T06:27:25Z
         Commit: 00513ef74be3018bf3c5eb7c3e1fdb2849d9d623ce74b6d1d611f71dd3be025d
# 这个时候再次检查，应该可以检查到可用更新了
rpm-ostree status -v 
State: idle
AutomaticUpdates: stage; rpm-ostreed-automatic.timer: inactive
Deployments:
* ostree://edge:rhel/8/x86_64/edge
                 Timestamp: 2020-11-27T06:57:01Z
                    Commit: b51ade2ec4700d27dd8858cb8f98930afbcdc346ff3a219204bff296178a94d5
                    Staged: no
                 StateRoot: rhel

AvailableUpdate:
      Timestamp: 2020-12-01T06:27:25Z
         Commit: 00513ef74be3018bf3c5eb7c3e1fdb2849d9d623ce74b6d1d611f71dd3be025d

# 更新 update 到 stage
rpm-ostree update 

note: automatic updates (stage) are enabled
==== AUTHENTICATING FOR org.projectatomic.rpmostree1.upgrade ====
Authentication is required to update software
Multiple identities can be used for authentication:
 1.  admin
 2.  core
Choose identity to authenticate as (1-2): 2 
Password: 
==== AUTHENTICATION COMPLETE ====
Staging deployment... done
Run "systemctl reboot" to start a reboot

# 检查 rpm-ostree 
# 新的 rpm-ostree 已经准备完毕. Staged: yes
# 等待重启生效
rpm-ostree status -v
State: idle
AutomaticUpdates: stage; rpm-ostreed-automatic.timer: inactive
Deployments:
  ostree://edge:rhel/8/x86_64/edge
                 Timestamp: 2020-12-01T06:27:25Z
                    Commit: 00513ef74be3018bf3c5eb7c3e1fdb2849d9d623ce74b6d1d611f71dd3be025d
                    Staged: yes
                 StateRoot: rhel

* ostree://edge:rhel/8/x86_64/edge
                 Timestamp: 2020-11-27T06:57:01Z
                    Commit: b51ade2ec4700d27dd8858cb8f98930afbcdc346ff3a219204bff296178a94d5
                 StateRoot: rhel

# 重启系统
$ systemctl reboot

# 回退到更新之前的系统
rpm-ostree rollback
systemctl reboot


```
### 如何格式化 Google Chat 消息
https://support.google.com/chat/answer/7649118?hl=en

### sample operator 日志 
```

# OpenShift 4.6 console 上有如下报错
# 应该是没有同步这些 imagestream 的镜像到本地
Samples operator is detecting problems with imagestream image imports. You can look at the "openshift-samples" ClusterOperator object for details. Most likely there are issues with the external image registry hosting the images that needs to be investigated. Or you can consider marking samples opertaor Removed if you do not care about having sample imagestreams available. The list of ImageStreams for which samples operator is retrying imports: apicast-gateway apicurito-ui dotnet dotnet-runtime eap-cd-openshift eap-cd-runtime-openshift fuse-apicurito-generator fuse7-console fuse7-eap-openshift fuse7-java-openshift fuse7-karaf-openshift golang httpd java jboss-eap72-openjdk11-openshift-rhel8 jboss-eap73-openjdk11-openshift jboss-eap73-openjdk11-runtime-openshift jboss-eap73-openshift jboss-eap73-runtime-openshift jboss-webserver53-openjdk11-tomcat9-openshift jboss-webserver53-openjdk8-tomcat9-openshift jenkins-agent-base mariadb mysql nginx nodejs perl php postgresql python redis rhdm-decisioncentral-rhel8 rhdm-kieserver-rhel8 rhpam-businesscentral-monitoring-rhel8 rhpam-businesscentral-rhel8 rhpam-kieserver-rhel8 rhpam-smartrouter-rhel8 ruby ubi8-openjdk-11 ubi8-openjdk-8

# 查看一下 imagestream 的镜像
for i in apicast-gateway apicurito-ui dotnet dotnet-runtime eap-cd-openshift eap-cd-runtime-openshift fuse-apicurito-generator fuse7-console fuse7-eap-openshift fuse7-java-openshift fuse7-karaf-openshift golang httpd java jboss-eap72-openjdk11-openshift-rhel8 jboss-eap73-openjdk11-openshift jboss-eap73-openjdk11-runtime-openshift jboss-eap73-openshift jboss-eap73-runtime-openshift jboss-webserver53-openjdk11-tomcat9-openshift jboss-webserver53-openjdk8-tomcat9-openshift jenkins-agent-base mariadb mysql nginx nodejs perl php postgresql python redis rhdm-decisioncentral-rhel8 rhdm-kieserver-rhel8 rhpam-businesscentral-monitoring-rhel8 rhpam-businesscentral-rhel8 rhpam-kieserver-rhel8 rhpam-smartrouter-rhel8 ruby ubi8-openjdk-11 ubi8-openjdk-8; do oc get is $i -n openshift -o jsonpath='{ range .spec.tags[*]}{.from.name}{"\n"}{end}' ; done 

# 尝试同步这些镜像到本地镜像仓库
for i in apicast-gateway apicurito-ui dotnet dotnet-runtime eap-cd-openshift eap-cd-runtime-openshift fuse-apicurito-generator fuse7-console fuse7-eap-openshift fuse7-java-openshift fuse7-karaf-openshift golang httpd java jboss-eap72-openjdk11-openshift-rhel8 jboss-eap73-openjdk11-openshift jboss-eap73-openjdk11-runtime-openshift jboss-eap73-openshift jboss-eap73-runtime-openshift jboss-webserver53-openjdk11-tomcat9-openshift jboss-webserver53-openjdk8-tomcat9-openshift jenkins-agent-base mariadb mysql nginx nodejs perl php postgresql python redis rhdm-decisioncentral-rhel8 rhdm-kieserver-rhel8 rhpam-businesscentral-monitoring-rhel8 rhpam-businesscentral-rhel8 rhpam-kieserver-rhel8 rhpam-smartrouter-rhel8 ruby ubi8-openjdk-11 ubi8-openjdk-8; do oc get is $i -n openshift -o jsonpath='{ range .spec.tags[*]}{.from.name}{"\n"}{end}' ; done | grep helper.cluster-0001.rhsacn.org:5000 | sed -e 's|helper.cluster-0001.rhsacn.org:5000/||' | tee ./tmp/sample-imageslist.txt

# 

# 同步镜像
for i in `cat ./tmp/sample-imageslist.txt`; do oc image mirror -a ${LOCAL_SECRET_JSON} registry.redhat.io/$i ${LOCAL_REGISTRY}/$i; done

```


### 制造与边缘计算术语

|缩写|英文全称|中文全称|备注|
|---|---|---|---|
|PLC|Programmable Logic Controller|可编程控制器||
|HMI|Human Machine Interface|人机接口||
|SCADA|Supervisory Control and Data Acquisition|数据采集和监视控制系统||
|PPS|Production Planning & Scheduling|生产计划调度系统||
|MES|Manufacturing Execution System|制造执行系统||
|PLM|Product Lifecycle Management|产品生命周期管理系统||
|ERP|Enterprise Resource Planning|企业资源计划系统||


### 如何采用 red hat subcsription entitlement 启用 repo 安装所需软件
https://docs.openshift.com/container-platform/4.1/builds/running-entitled-builds.html

```
需要拷贝的文件包括
 /etc/pki/entitlement/
 /etc/rhsm/ca

```

另外类似的文章还包括
https://success.mirantis.com/article/how-to-pass-red-hat-enterprise-linux-entitlements-to-a-container

https://developers.redhat.com/blog/2019/05/31/working-with-red-hat-enterprise-linux-universal-base-images-ubi/


### RHEL for Edge Demo git repo
参考这个链接
https://github.com/osbuild/rhel-for-edge-demo/blob/master/edge2.ks

关于定制化可以参考这个链接
https://weldr.io/User-Configuration-With-Blueprints/

```
# 创建测试目录
mkdir -p /var/www/html/rhel-for-edge-repo
pushd /var/www/html/rhel-for-edge-repo

# 生成 kickstart 文件
cat > edge.ks << 'EOFEOF'
lang en_US.UTF-8
keyboard us
timezone UTC
zerombr
clearpart --all --initlabel
autopart --type=plain --fstype=xfs --nohome
reboot
text
network --bootproto=static --device=ens3 --ip=192.168.8.111 --netmask 255.255.255.0 --gateway=192.168.8.1 --hostname=jwangtest.example.com
user --name=core --groups=wheel --password=edge

ostreesetup --nogpg --url=http://192.168.8.11:8080/rhel-for-edge-repo/repo/ --osname=rhel --remote=edge --ref=rhel/8/x86_64/edge
%post

#stage updates as they become available. This is highly recommended
echo AutomaticUpdatePolicy=stage >> /etc/rpm-ostreed.conf

#This is a simple example that will look for staged rpm-ostree updates and apply them per the timer if they exist
cat > /etc/systemd/system/applyupdate.service << 'EOF'
[Unit]
Description=Apply Update Check

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'if [[ $(rpm-ostree status -v | grep "Staged: yes") ]]; then systemctl --message="Applying OTA update" reboot; else logger "Running latest available update"; fi'
EOF

cat > /etc/systemd/system/applyupdate.timer << EOF
[Unit]
Description=Daily Update Reboot Check.

[Timer]
#Nightly example maintenance window
OnCalendar=*-*-* 01:30:00
#weekly example for Sunday at midnight
#OnCalendar=Sun *-*-* 00:00:00

[Install]
WantedBy=multi-user.target
EOF

systemctl enable applyupdate.timer applyupdate.timer
%end

%post
#Add a podman autoupdate timer & service

cat > /etc/systemd/system/podman-auto-update.service << EOF
[Unit]
Description=Podman auto-update service
Documentation=man:podman-auto-update(1)
Wants=network.target
After=network-online.target

[Service]
ExecStart=/usr/bin/podman auto-update

[Install]
WantedBy=multi-user.target default.target
EOF

cat > /etc/systemd/system/podman-auto-update.timer << EOF
[Unit]
Description=Podman auto-update timer

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=7200

[Install]
WantedBy=timers.target
EOF

#create a unit file to run our example workload 
cat > /etc/systemd/system/container-boinc.service <<EOF
# container-boinc.service
# autogenerated by Podman 2.0.4

[Unit]
Description=Podman container-boinc.service
Documentation=man:podman-generate-systemd(1)
Wants=network.target
After=network-online.target

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
RestartSec=30s
ExecStartPre=/bin/rm -f %t/container-boinc.pid %t/container-boinc.ctr-id
ExecStart=/usr/bin/podman run --conmon-pidfile %t/container-boinc.pid --cidfile %t/container-boinc.ctr-id --cgroups=no-conmon -d --replace --label io.containers.autoupdate=image --name boinc -dt -p 31416:31416 -v /opt/appdata/boinc:/var/lib/boinc:Z boinc/client:latest
ExecStop=/usr/bin/podman stop --ignore --cidfile %t/container-boinc.ctr-id -t 10
ExecStopPost=/usr/bin/podman rm --ignore -f --cidfile %t/container-boinc.ctr-id
PIDFile=%t/container-boinc.pid
KillMode=none
Type=forking

[Install]
WantedBy=multi-user.target default.target
EOF


#Example workload from: https://fedoramagazine.org/running-rosettahome-on-a-raspberry-pi-with-fedora-iot/
#create host mount points
mkdir -p /opt/appdata/boinc/slots /opt/appdata/boinc/locale

systemctl enable podman-auto-update.timer container-boinc.service
%end
EOFEOF

# 测试使用简单一些的kickstart文件
cat > /tmp/edge.ks << 'EOFEOF'
lang en_US.UTF-8
keyboard us
timezone UTC
zerombr
clearpart --all --initlabel
autopart --type=plain --fstype=xfs --nohome
reboot
text
network --bootproto=static --device=ens3 --ip=192.168.8.111 --netmask 255.255.255.0 --gateway=192.168.8.1 --hostname=jwangtest.example.com
user --name=core --groups=wheel --password=edge

ostreesetup --nogpg --url=http://192.168.8.11:8080/rhel-for-edge-repo/repo/ --osname=rhel --remote=edge --ref=rhel/8/x86_64/edge
EOFEOF
```


### 如何在系统上用容器的方式，运行 mkksiso 工具
这个话题有待探索

```
cat > Dockerfile << EOF
FROM registry.redhat.io/ubi7/ubi
ENTRYPOINT ["/bin/bash"]
EOF

podman build . -t mkksiso:latest

podman run -rm -ti mkksiso:latestf
```

### ostreesetup 的参数
参见：
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/kickstart-commands-and-options-reference_installing-rhel-as-an-experienced-user


```
syntax
  ostreesetup --osname=OSNAME [--remote=REMOTE] --url=URL --ref=REF [--nogpg]

Mandatory options:
  --osname=OSNAME - Management root for OS installation.
  --url=URL - URL of the repository to install from.
  --ref=REF - Name of the branch from the repository to be used for installation.

Optional options:
  --remote=REMOTE - Management root for OS installation.
  --nogpg - Disable GPG key verification.

ostreesetup --nogpg --url=http://192.168.8.11:8080/rhel-for-edge-repo/repo/ --osname=rhel --remote=edge --ref=rhel/8/x86_64/edge

```


```
报错信息
09:08:54,889 INF payload.rpmostreepayload: executing ostreesetup=<pykickstart.commands.ostreesetup.RHEL8_OSTreeSetup object at 0x7f30a7d87860>
09:08:55,594 ERR payload.rpmostreepayload: Failed to pull from repository: g-io-error-quark: Server returned HTTP 404 (1)
09:08:55,596 DBG simpleline: New signal SendMessageSignal enqueued with source TextUserInterface
09:08:56,570 DBG simpleline: Pushing modal screen IpmiErrorDialog to stack
09:08:56,574 DBG simpleline: Executing inner loop
09:08:56,575 DBG simpleline: New signal RenderScreenSignal enqueued with source ScreenScheduler
09:08:56,576 DBG simpleline: Processing screen ScreenData(IpmiErrorDialog,None,True)
09:08:56,580 DBG simpleline: Input is required by ScreenData(IpmiErrorDialog,None,True) screen
```

参考内容
https://github.com/rhinstaller/anaconda/blob/master/pyanaconda/payload/rpmostreepayload.py
https://docs.fedoraproject.org/en-US/fedora-silverblue/_attachments/silverblue-cheatsheet.pdf

```
Build a rhel for edge web server

cat > Dockerfile << 'EOF'
FROM registry.access.redhat.com/ubi8/ubi
RUN yum -y install httpd && yum clean all
ADD edge.ks /var/www/html/
ARG commit=commit.tar
ADD $commit /var/www/html/
EXPOSE 80
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
EOF

iptables -I INPUT 1 -m state --state NEW -m tcp -p tcp --dport 8000 -j ACCEPT
podman run --name edge-server -d -p 8000:80 edge-server


```

### OpenShift RHCOS ignition snip to wipe disk (WIP)
```
  "storage": {
    "disks": [
      {
        "device": "/dev/sdb",
        "wipeTable": true
      },
      {
        "device": "/dev/sdc",
        "wipeTable": true
      },
      {
        "device": "/dev/sdd",
        "wipeTable": true
      }
    ]
  }  
```

### How to set up PXE boot for UEFI hardware
如何为 UEFI 硬件设置 PXE boot 启动
https://www.redhat.com/sysadmin/pxe-boot-uefi


### rsync 时指定 ssh key 来进行身份认证
```
rsync -Pav -e "ssh -i $HOME/.ssh/somekey" username@hostname:/from/dir/ /to/dir/
```

### 检查 machineconfig 里包含哪些文件
```
# 使用命令 oc get machineconfig 获取相关内容
oc get machineconfig 00-master -o jsonpath='{ range .spec.config.storage.files[*] }{ .path }{"\n"}{ end }'
/etc/pki/ca-trust/source/anchors/openshift-config-user-ca-bundle.crt
/etc/tmpfiles.d/cleanup-cni.conf
/etc/kubernetes/static-pod-resources/configmaps/cloud-config/ca-bundle.pem
/usr/local/bin/configure-ovs.sh
/etc/containers/storage.conf
/etc/NetworkManager/dispatcher.d/90-long-hostname
/etc/systemd/system.conf.d/10-default-env-godebug.conf
/etc/kubernetes/static-pod-resources/etcd-member/root-ca.crt
/etc/modules-load.d/iptables.conf
/etc/kubernetes/kubelet-ca.crt
/etc/systemd/system.conf.d/kubelet-cgroups.conf
/etc/NetworkManager/conf.d/sdn.conf
/var/lib/kubelet/config.json
/etc/kubernetes/manifests/recycler-pod.yaml
/etc/kubernetes/ca.crt
/etc/sysctl.d/forward.conf
/etc/sysctl.d/inotify.conf
/usr/local/bin/recover-kubeconfig.sh
/usr/local/sbin/set-valid-hostname.sh
/etc/kubernetes/kubelet-plugins/volume/exec/.dummy
```

### 创建一个 blueprint 
```
mkdir -p blueprints
pushd blueprints

cat > rhel-for-edge-demo.toml << EOF
name = "rhel-for-edge-demo"
description = "demo rhel for edge"
version = "0.0.1"
modules = [ ]
groups = [ ]
EOF

composer-cli blueprints push rhel-for-edge-demo.toml
composer-cli blueprints list

cat > rhel-for-edge-demo.toml <<EOF
name = "rhel-for-edge-demo"
description = "demo rhel for edge"
version = "0.0.2"
modules = []
groups = []

[[packages]]
name = "bash"
version = "*"

[[packages]]
name = "podman"
version = "*"
EOF

composer-cli blueprints push rhel-for-edge-demo.toml
composer-cli blueprints changes rhel-for-edge-demo.toml

ssh-keygen -t rsa -f /root/.ssh/edge -N ''
ssh_key=$(cat /root/.ssh/edge.pub)

config_password=$(python3 -c 'import crypt; print(crypt.crypt("redhat", crypt.mksalt(crypt.METHOD_SHA512)))')

cat > rhel-for-edge-demo.toml.toml <<EOF
name = "rhel-for-edge-demo"
description = "demo rhel for edge"
version = "0.0.3"
modules = []
groups = []

[[packages]]
name = "bash"
version = "*"

[[packages]]
name = "podman"
version = "*"

[[customizations.user]]
name = "admin"
description = "admin"
password = "${config_password}"
home = "/home/admin/"
groups = ["wheel"]

[[customizations.user]]
name = "root"
key = "${ssh_key}"
EOF
```

### 从 deployment 上删除 requests / limits 约束
参考：https://labs.consol.de/development/2019/04/08/oc-patch-unleashed.html
```
oc patch deployment rook-ceph-rgw-ocs-storagecluster-cephobjectstore-b -n openshift-storage --type json -p '[{ "op": "remove", "path": "/spec/template/spec/containers/0/resources/limits" }]'
oc patch deployment rook-ceph-rgw-ocs-storagecluster-cephobjectstore-b -n openshift-storage --type json -p '[{ "op": "remove", "path": "/spec/template/spec/containers/0/resources/requests" }]'
```

### 报错: 对于 openshift container mkdir failed (Permission denied) 的处理
```
报错信息：
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: error: can not modify /etc/nginx/conf.d/default.conf (read-only file system?)
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2020/12/02 03:36:22 [warn] 1#1: the "user" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:2
nginx: [warn] the "user" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:2
2020/12/02 03:36:22 [emerg] 1#1: mkdir() "/var/cache/nginx/client_temp" failed (13: Permission denied)
nginx: [emerg] mkdir() "/var/cache/nginx/client_temp" failed (13: Permission denied)

尝试解决：
oc project test
oc adm policy add-scc-to-user privileged -z default -n test
oc adm policy add-scc-to-user anyuid -z default -n test


oc adm policy add-scc-to-user privileged -z default -n test
oc adm policy who-can use scc privileged -n test | grep default
...
        system:serviceaccount:test:default



关于默认的 service account 和 scc 可以参考以下链接
https://docs.openshift.com/container-platform/3.6/dev_guide/service_accounts.html
https://www.openshift.com/blog/managing-sccs-in-openshift
https://docs.openshift.com/container-platform/3.4/admin_guide/manage_scc.html


# 关于 scc 有关的 Bug 记录
https://bugzilla.redhat.com/show_bug.cgi?id=1850148

# patch dc/nginx securityContext
https://github.com/sterburg/kubernetes-nginx-servicediscovery/blob/master/README.md
oc patch dc/nginx --patch='{"spec": {"template": {"spec": {"securityContext": { "runAsUser": 0 }}}}}'

# 清除 dc/mysql 的 securityContext
oc patch deploymentconfig mysql -n test --type json -p '[{ "op": "remove", "path": "/spec/template/spec/securityContext" }]'

oc patch dc/mysql --patch='{"spec": {"template": {"spec": {"securityContext": { "runAsUser": 0 }}}}}' --type=merge
oc patch dc/mysql --patch='{"spec": {"template": {"spec": {"securityContext": { "privileged": true }}}}}' --type=merge

# 保存 template
oc get template mysql-ephemeral -n openshift -o yaml > new-mysql-ephemeral-template.yaml

oc patch dc/nginx --patch='{"spec": {"template": {"spec": {"securityContext": { "runAsUser": 0 }}}}}'

oc get deployment mysql -n infra -o yaml | grep securityContext
```

### OpenShift 下使用模版部署 mysql
https://techbloc.net/archives/2607

```
oc create namespace testing

oc new-app mysql-ephemeral
```

### 修改 template 的 securityContext
```
# 保存 template 到文件
oc get template mysql-ephemeral -n openshift -o yaml > new-mysql-ephemeral-template.yaml

# 修改 template 内容
--- new-mysql-ephemeral-template.yaml.orig      2020-12-03 10:12:06.000000000 +0800
+++ new-mysql-ephemeral-template.yaml   2020-12-03 10:04:05.000000000 +0800
@@ -1,7 +1,7 @@
 apiVersion: template.openshift.io/v1
 kind: Template
 labels:
-  template: mysql-ephemeral-template
+  template: new-mysql-ephemeral-template

@@ -18,7 +18,7 @@
 
       WARNING: Any data stored will be lost upon pod destruction. Only use this template for testing
     iconClass: icon-mysql-database
-    openshift.io/display-name: MySQL (Ephemeral)
+    openshift.io/display-name: New MySQL (Ephemeral)
     openshift.io/documentation-url: https://docs.okd.io/latest/using_images/db_images/mysql.html
     openshift.io/long-description: This template provides a standalone MySQL server
       with a database created.  The database is not stored on persistent storage,

# 删除 creationTimestamp
-  creationTimestamp: "2020-11-25T12:59:40Z"

# 删除 managedFields
-  managedFields:
-  - apiVersion: template.openshift.io/v1
-    fieldsType: FieldsV1
-    fieldsV1:
-      f:labels:
-        .: {}
-        f:template: {}
-      f:message: {}
-      f:metadata:
-        f:annotations:
-          .: {}
-          f:description: {}
-          f:iconClass: {}
-          f:openshift.io/display-name: {}
-          f:openshift.io/documentation-url: {}
-          f:openshift.io/long-description: {}
-          f:openshift.io/provider-display-name: {}
-          f:openshift.io/support-url: {}
-          f:samples.operator.openshift.io/version: {}
-          f:tags: {}
-        f:labels:
-          .: {}
-          f:samples.operator.openshift.io/managed: {}
-      f:objects: {}
-      f:parameters: {}
-    manager: cluster-samples-operator
-    operation: Update
-    time: "2020-11-25T12:59:40Z"

# 修改名字
-  name: mysql-ephemeral
+  name: new-mysql-ephemeral

# 删除 resourceVersion, selfLink, uid
-  resourceVersion: "14772"
-  selfLink: /apis/template.openshift.io/v1/namespaces/openshift/templates/mysql-ephemeral
-  uid: cbf63e81-73e5-40dd-99d3-118b05583e42

# 删除 containers capabilities: {}
@@ -117,8 +85,7 @@
           name: ${DATABASE_SERVICE_NAME}
       spec:
         containers:
-        - capabilities: {}
-          env:
+        - env:

# 修改 containers 的 securityContext
@@ -167,8 +135,7 @@
             limits:
               memory: ${MEMORY_LIMIT}
           securityContext:
-            capabilities: {}
-            privileged: false
+            privileged: true


```

### OpenShift 下通过 template mysql-ephemeral 创建的容器里的日志里记录 
```
报错信息：
2020-12-03T03:07:08.454518Z 259471 [Note] Got an error reading communication packets
```

处理方法参考：https://bugzilla.redhat.com/show_bug.cgi?id=1767393 
```
# 尝试重现问题
# 设置 mysql 的 global 变量 log_error_verbosity
oc rsh pod/$(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) mysql -u root -e "set global log_error_verbosity=3;"

# 查询 mysql 的 log_err 位置
oc rsh pod/$(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) mysql -u root -e "select @@GLOBAL.log_error;"
+--------------------+
| @@GLOBAL.log_error |
+--------------------+
| stderr             |
+--------------------+

# 查询 mysql 的 log_error_verbosity 级别
oc rsh pod/$(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) mysql -u root -e "select @@GLOBAL.log_error_verbosity;"
+------------------------------+
| @@GLOBAL.log_error_verbosity |
+------------------------------+
|                            3 |
+------------------------------+

# 查看 mysql pod 日志
oc logs pod/$(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) 

# 查看 mysql pod 的 yaml 文件
oc get pod/$(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) -o yaml > $(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy).yaml
```

### rpm-ostree 检查更新
```
# rpm-ostree 检查更新
$ rpm-ostree upgrade --check 
note: automatic updates (stage) are enabled
==== AUTHENTICATING FOR org.projectatomic.rpmostree1.upgrade ====
Authentication is required to update software
Multiple identities can be used for authentication:
 1.  admin
 2.  core
Choose identity to authenticate as (1-2): 2
Password: 
==== AUTHENTICATION COMPLETE ====
1 metadata, 0 content objects fetched; 306 B transferred in 0 seconds; 0 bytes content written
AvailableUpdate:
      Timestamp: 2020-12-01T06:27:25Z
         Commit: 00513ef74be3018bf3c5eb7c3e1fdb2849d9d623ce74b6d1d611f71dd3be025d

# rpm-ostree 预览更新
$ rpm-ostree upgrade --preview
note: automatic updates (stage) are enabled
==== AUTHENTICATING FOR org.projectatomic.rpmostree1.upgrade ====
Authentication is required to update software
Multiple identities can be used for authentication:
 1.  admin
 2.  core
Choose identity to authenticate as (1-2): 2
Password: 
==== AUTHENTICATION COMPLETE ====
1 metadata, 0 content objects fetched; 306 B transferred in 0 seconds; 0 bytes content written
AvailableUpdate:
      Timestamp: 2020-12-01T06:27:25Z
         Commit: 00513ef74be3018bf3c5eb7c3e1fdb2849d9d623ce74b6d1d611f71dd3be025d

# 检查 /etc/rpm-ostreed.conf 文件内容
# AutomaticUpdatePolicy 设置为 stage
$ cat /etc/rpm-ostreed.conf
# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# For option meanings, see rpm-ostreed.conf(5).

[Daemon]
#AutomaticUpdatePolicy=none
#IdleExitTimeout=60
AutomaticUpdatePolicy=stage

# 启用 rpm-ostreed-automatic.timer 服务
# 启用这个服务后，将定期检查更新，如果有更新会根据配置首先 stage 更新
# 参见：https://www.mankier.com/8/rpm-ostreed-automatic.service

$ systemctl enable rpm-ostreed-automatic.timer --now
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-unit-files ====
Authentication is required to manage system service or unit files.
Multiple identities can be used for authentication:
 1.  admin
 2.  core
Choose identity to authenticate as (1-2): 2
Password: 
==== AUTHENTICATION COMPLETE ====
==== AUTHENTICATING FOR org.freedesktop.systemd1.reload-daemon ====
Authentication is required to reload the systemd state.
Multiple identities can be used for authentication:
 1.  admin
 2.  core
Choose identity to authenticate as (1-2): 2
Password: 
==== AUTHENTICATION COMPLETE ====
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ====
Authentication is required to start 'rpm-ostreed-automatic.timer'.
Multiple identities can be used for authentication:
 1.  admin
 2.  core
Choose identity to authenticate as (1-2): 2
Password: 
==== AUTHENTICATION COMPLETE ====
```

### openshift 下基于 image 创建 app 
参考：https://docs.openshift.com/enterprise/3.0/dev_guide/new_app.html#specifying-an-image
```

# 基于 image 创建 app
$ oc new-app image-registry.openshift-image-registry.svc:5000/openshift/mysql@sha256:809b45cb745a5e41a8f595f5991b1a9f4ec8e7c4088f82c3be8e6c461e8acd6d
--> Found container image 5804f03 (4 weeks old) from image-registry.openshift-image-registry.svc:5000 for "image-registry.openshift-image-registry.svc:5000/openshift/mysql@sha256:809b45cb745a5e41a8f595f5991b1a9f4ec8e7c4088f82c3be8e6c461e8acd6d"

    MySQL 8.0 
    --------- 
    MySQL is a multi-user, multi-threaded SQL database server. The container image provides a containerized packaging of the MySQL mysqld daemon and client application. The mysqld server daemon accepts connections from clients and provides access to content from MySQL databases on behalf of the clients.

    Tags: database, mysql, mysql80, mysql-80

    * An image stream tag will be created as "mysql:latest" that will track this image

--> Creating resources ...
    imagestream.image.openshift.io "mysql" created
    deployment.apps "mysql" created
    service "mysql" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/mysql' 
    Run 'oc status' to view your app.

# 创建了以下资源 imagestream, deployment, replicaset, service, pod
[junwang@JundeMacBook-Pro ~/tmp/ibm]$ oc get all 
NAME                        READY   STATUS             RESTARTS   AGE
pod/mysql-755969756-jjnjc   0/1     CrashLoopBackOff   2          31s

NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/mysql   ClusterIP   172.30.181.146   <none>        3306/TCP   31s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mysql   0/1     1            0           31s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/mysql-755969756    1         1         0       31s
replicaset.apps/mysql-77c9c667d5   1         0         0       31s

NAME                                   IMAGE REPOSITORY                                              TAGS     UPDATED
imagestream.image.openshift.io/mysql   image-registry.openshift-image-registry.svc:5000/test/mysql   latest   31 seconds ago

# 创建的 pod 状态为 CrashLoopBackOff
# 查看 pod 日志
oc logs $(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy)
=> sourcing 20-validate-variables.sh ...
You must either specify the following environment variables:
  MYSQL_USER (regex: '^[a-zA-Z0-9_]+$')
  MYSQL_PASSWORD (regex: '^[a-zA-Z0-9_~!@#$%^&*()-=<>,.?;:|]+$')
  MYSQL_DATABASE (regex: '^[a-zA-Z0-9_]+$')
Or the following environment variable:
  MYSQL_ROOT_PASSWORD (regex: '^[a-zA-Z0-9_~!@#$%^&*()-=<>,.?;:|]+$')
Or both.
Optional Settings:
  MYSQL_LOWER_CASE_TABLE_NAMES (default: 0)
  MYSQL_LOG_QUERIES_ENABLED (default: 0)
  MYSQL_MAX_CONNECTIONS (default: 151)
  MYSQL_FT_MIN_WORD_LEN (default: 4)
  MYSQL_FT_MAX_WORD_LEN (default: 20)
  MYSQL_AIO (default: 1)
  MYSQL_KEY_BUFFER_SIZE (default: 32M or 10% of available memory)
  MYSQL_MAX_ALLOWED_PACKET (default: 200M)
  MYSQL_TABLE_OPEN_CACHE (default: 400)
  MYSQL_SORT_BUFFER_SIZE (default: 256K)
  MYSQL_READ_BUFFER_SIZE (default: 8M or 5% of available memory)
  MYSQL_INNODB_BUFFER_POOL_SIZE (default: 32M or 50% of available memory)
  MYSQL_INNODB_LOG_FILE_SIZE (default: 8M or 15% of available memory)
  MYSQL_INNODB_LOG_BUFFER_SIZE (default: 8M or 15% of available memory)

For more information, see https://github.com/sclorg/mysql-container

# 根据日志，知道 CrashLoopBackOff 的原因是需要指定参数
# 删除 project
oc project default
oc delete project test --wait=true --timeout=5m

# 获取 project 的 信息，等待出现消息 Error from server (NotFound): namespaces "test" not found
oc get project test 
Error from server (NotFound): namespaces "test" not found

# 重建 project
oc create namespace test
oc project test

# 带参数基于 image 创建 app
oc new-app -e MYSQL_USER="mysql" -e MYSQL_PASSWORD="changeme" -e MYSQL_DATABASE="db1" -e MYSQL_ROOT_PASSWORD="changeme" image-registry.openshift-image-registry.svc:5000/openshift/mysql@sha256:809b45cb745a5e41a8f595f5991b1a9f4ec8e7c4088f82c3be8e6c461e8acd6d


```

### 学习 OpenShft4 上的 Jenkins 

Get started with Jenkins CI/CD in Red Hat OpenShift 4
https://developers.redhat.com/blog/2019/05/02/get-started-with-jenkins-ci-cd-in-red-hat-openshift-4/

```
oc create namespace test1
oc project test1
oc new-app jenkins-ephemeral

# copy jenkins images
> ./tmp/registry-images-jenkins.lst
for image in jenkins jenkins-agent-base jenkins-agent-maven jenkins-agent-nodejs
do
  oc get is ${image} -n openshift -o jsonpath='{.spec.tags[].from.name}{"\n"}' >> ./tmp/registry-images-jenkins.lst
done

for source in `cat ./tmp/registry-images-jenkins.lst`; do  local=`echo $source|awk -F'@' '{print $1}'|sed 's|quay.io/openshift-release-dev/ocp-v4.0-art-dev|helper.cluster-0001.rhsacn.org:5000/ocp4/openshift4|g'`   ; 
echo skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://$source docker://$local; echo skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://$source docker://$local; echo; done

# 拷贝 jenkins image 到本地镜像仓库
skopeo copy --format v2s2 --authfile /root/pull-secret-2.json --all docker://quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:5244eb131713eb9372a474a851a561f803c9c9b474e86f3903fc638d929f04b1 docker://helper.cluster-0001.rhsacn.org:5000/ocp4/openshift4
# 根据报错，需要同步到本地这个位置
skopeo copy --format v2s2 --authfile /root/pull-secret-2.json --all docker://quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:5244eb131713eb9372a474a851a561f803c9c9b474e86f3903fc638d929f04b1 docker://helper.cluster-0001.rhsacn.org:5000/openshift/jenkins

# import jenkins image
oc import-image jenkins -n openshift

# 触发新的部署
oc rollout latest dc/jenkins

# 查看 pod 日志
oc -n test1 describe pod $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy)
oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy)
...

# 检查
# 登录节点
oc debug node/worker0.cluster-0001.rhcnsa.org

# 登录 openshift api
oc login -u kubeadmin -p xxx https://api.cluster-0001.rhcnsa.org:6443

# 从 拉取镜像
podman login -u kubeadmin -p $(oc whoami -t)  image-registry.openshift-image-registry.svc:5000

podman pull image-registry.openshift-image-registry.svc:5000/openshift/jenkins@sha256:5244eb131713eb9372a474a851a561f803c9c9b474e86f3903fc638d929f04b1

# 为 namespace test1 添加 pull secret
oc project test1 
oc create secret docker-registry local-pull-secret \
    --namespace test1 \
    --docker-server=helper.cluster-0001.rhsacn.org:5000 \
    --docker-username=dummy \
    --docker-password=dummy
oc patch sa default -n test1 --type='json' -p='[{"op":"add","path":"/imagePullSecrets/-", "value":{"name":"local-pull-secret"}}]'
oc patch sa deployer -n test1 --type='json' -p='[{"op":"add","path":"/imagePullSecrets/-", "value":{"name":"local-pull-secret"}}]'

# 这个 Bug 可能与此有关
# https://bugzilla.redhat.com/show_bug.cgi?id=1787112
# 既然 imagecontentsourcepolicy 无法

# 想到的办法是 patch is jenkins 指向本地镜像仓库
oc patch is jenkins -n openshift --type json -p='[{"op": "replace", "path": "/spec/tags/0/from/name", "value":"helper.cluster-0001.rhsacn.org:5000/ocp4/openshift4@sha256:5244eb131713eb9372a474a851a561f803c9c9b474e86f3903fc638d929f04b1"}]'

# 然后就可以参考 https://developers.redhat.com/blog/2019/05/02/get-started-with-jenkins-ci-cd-in-red-hat-openshift-4/ 里的 Get started with Jenkins CI/CD in Red Hat OpenShift 4

# 创建 jenkins maven pipeline
$ oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/maven-pipeline.yaml
template.template.openshift.io/maven-pipeline created

# 创建 maven pipeline
oc new-app --template=maven-pipeline 
--> Deploying template "test1/maven-pipeline" to project test1                                                                                                
                                                                                                                                                              
     * With parameters:                                                                                                                                       
        * Application Name=openshift-jee-sample                                                                                                               
        * Source URL=https://github.com/openshift/openshift-jee-sample.git                                                                                    
        * Source Ref=master                                                                                                                                   
        * GitHub Webhook Secret=Iq06B4Fel606W0EcyYWmfFpSyRevUjB8xQuREmI1 # generated                                                                          
        * Generic Webhook Secret=xp1y2qDX2thgtSQVW27HFWfylQREwlJxFrrnniTA # generated                                                                         
                                                                                                                                                              
--> Creating resources ...                                                                                                                                    
    imagestream.image.openshift.io "openshift-jee-sample" created                                                                                             
    imagestream.image.openshift.io "wildfly" created                                                                                                          
    buildconfig.build.openshift.io "openshift-jee-sample" created                                                                                             
    buildconfig.build.openshift.io "openshift-jee-sample-docker" created                                                                                      
    deploymentconfig.apps.openshift.io "openshift-jee-sample" created                                                                                         
    service "openshift-jee-sample" created                                                                                                                    
    route.route.openshift.io "openshift-jee-sample" created                                                                                                   
--> Success                                                                                                                                                   
JenkinsPipeline build strategy is deprecated. Use Jenkinsfiles directly on Jenkins or OpenShift Pipelines instead                                             
    Use 'oc start-build openshift-jee-sample' to start a build.                                                                                               
    Use 'oc start-build openshift-jee-sample-docker' to start a build.                                                                                        
    Access your application via route 'openshift-jee-sample-test1.apps.cluster-0001.rhsacn.org'                                                               
    Run 'oc status' to view your app.    

# 了解一下为什么 maven 的 Pod 启动不起来
oc describe pod maven-hxr6v
...
Events:
  Type     Reason          Age               From                                      Message
  ----     ------          ----              ----                                      -------
  Normal   Scheduled       <unknown>                                                   Successfully assigned test1/maven-hxr6v to worker0.cluster-0001.rhsacn.org
  Normal   AddedInterface  20s               multus                                    Add eth0 [10.254.4.28/24]
  Normal   BackOff         19s               kubelet, worker0.cluster-0001.rhsacn.org  Back-off pulling image "image-registry.openshift-image-registry.svc:5000/openshift/jenkins-agent-maven:latest"
  Warning  Failed          19s               kubelet, worker0.cluster-0001.rhsacn.org  Error: ImagePullBackOff
  Normal   Pulling         6s (x2 over 20s)  kubelet, worker0.cluster-0001.rhsacn.org  Pulling image "image-registry.openshift-image-registry.svc:5000/openshift/jenkins-agent-maven:latest"
  Warning  Failed          5s (x2 over 19s)  kubelet, worker0.cluster-0001.rhsacn.org  Failed to pull image "image-registry.openshift-image-registry.svc:5000/openshift/jenkins-agent-maven:latest": rpc error: code = Unknown desc = Error reading manifest latest in image-registry.openshift-image-registry.svc:5000/openshift/jenkins-agent-maven: unknown: unable to pull manifest from quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:aeff0c6e915e8506bb10702431a3169a03608b43f1c41b7e157ad502a4857239: unauthorized: access to the requested resource is not authorized
  Warning  Failed          5s (x2 over 19s)  kubelet, worker0.cluster-0001.rhsacn.org  Error: ErrImagePull

# 获取 maven agent image 
skopeo copy --format v2s2 --authfile /root/pull-secret-2.json --all docker://quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:aeff0c6e915e8506bb10702431a3169a03608b43f1c41b7e157ad502a4857239 docker://helper.cluster-0001.rhsacn.org:5000/ocp4/openshift4

# 然后 patch image stream 
oc patch is jenkins-agent-maven -n openshift --type json -p='[{"op": "replace", "path": "/spec/tags/1/from/name", "value":"helper.cluster-0001.rhsacn.org:5000/ocp4/openshift4@sha256:aeff0c6e915e8506bb10702431a3169a03608b43f1c41b7e157ad502a4857239"}]'

# 在 step Build Image 出错
# 出错的阶段为 Build Image
# Build Image 将执行 oc start-build ${appName}-docker --from-file=target/ROOT.war -n ${project}
oc describe build.build.openshift.io/openshift-jee-sample-2 
...
Strategy: JenkinsPipeline
Jenkinsfile contents:
  try {
     timeout(time: 20, unit: 'MINUTES') {
        def appName="openshift-jee-sample"

...
        node {
          stage("Build Image") {
            unstash name:"war"
            def status = sh(returnStdout: true, script: "oc start-build ${appName}-docker --from-file=target/ROOT.war -n ${project}")

# 执行的是 buildconfig openshift-jee-sample-docker
# buildconfig 的 builder image 是 ImageStreamTag wildfly:latest
oc describe buildconfig openshift-jee-sample-docker         
Name:     openshift-jee-sample-docker
Namespace:      test1
Created:  3 hours ago
Labels:   app=openshift-jee-sample-docker
Annotations:    openshift.io/generated-by=OpenShiftNewApp
Latest Version: Never built

Strategy: Docker
Dockerfile:
  FROM wildfly
  COPY ROOT.war /wildfly/standalone/deployments/ROOT.war
  CMD $STI_SCRIPTS_PATH/run
From Image:     ImageStreamTag wildfly:latest
Output to:      ImageStreamTag openshift-jee-sample:latest
Binary:   provided as file "ROOT.war" on build

Build Run Policy:      Serial
Triggered by:          <none>
Builds History Limit:
        Successful:    5
        Failed:        5

# 因此首先需要看的是 imagestream wildfly 是否本地可以正常访问
# imagestream wildfly 需要同步到本地
oc get is wildfly  -o yaml
...
status:
  dockerImageRepository: image-registry.openshift-image-registry.svc:5000/test1/wildfly
  tags:
  - conditions:
    - generation: 2
      lastTransitionTime: "2020-12-04T09:21:21Z"
      message: 'Internal error occurred: docker.io/openshift/wildfly-101-centos7:latest: Get "https://production.cloudflare.docker.com/registry-v2/docker/registry/v2/blobs/sha256/42/42c046e05a707bc547fbe94eb22282563af69c849575fe769ca15f82121f1a6f/data?verify=1607076662-blh67Avgw%2FqMltCksA1wDFU%2BCfA%3D": net/http: TLS handshake timeout'

# 在能下载 image 的地方，将 image wildfly-101-centos7:latest 保存到本地目录
mkdir -p /root/tmp/mirror/wildfly
skopeo copy --format v2s2 docker://docker.io/openshift/wildfly-101-centos7:latest dir:///root/tmp/mirror/wildfly

# 将下载的目录内容同步到离线环境
# 将载的目录内容导入到本地镜像仓库
skopeo copy --format v2s2 --authfile /root/pull-secret-2.json dir:///root/tmp/mirror/wildfly docker://helper.cluster-0001.rhsacn.org:5000/openshift/wildfly-101-centos7:latest

# patch imagestream wildfly
oc -n test1 patch is wildfly --type json -p='[{"op": "replace", "path": "/spec/tags/0/from/name", "value":"helper.cluster-0001.rhsacn.org:5000/openshift/wildfly-101-centos7:latest"}]'

# 测试可以用 imagestream wildfly start build
oc start-build openshift-jee-sample-docker 

oc logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep build)
...
Adding cluster TLS certificate authority to trust store
Caching blobs under "/var/cache/blobs".

Pulling image helper.cluster-0001.rhsacn.org:5000/openshift/wildfly-101-centos7@sha256:7775d40f77e22897dc760b76f1656f67ef6bd5561b4d74fbb030b977f61d48e8 ...
Getting image source signatures
Copying blob sha256:2b5e13069964ce5fb3f2f20a2f296842239ea9785402ee9db00f7df0758e3880
Copying blob sha256:8a3400b7e31a55323583e3d585b3b0be56d9f7ae563187aec96d47ef5419982a
Copying blob sha256:734fb161cf896cf5c25a9a857a4b4d267bb5a59d5acf9ba846278ab3f3d1f5d5
Copying blob sha256:1614fb52d93087dae86cc7c5072e724dc781b4bfeb8d36130edeaeed03a75929
Copying blob sha256:45a2e645736c4c66ef34acce2407ded21f7a9b231199d3b92d6c9776df264729
Copying blob sha256:43c7d7e0ab141d1e4c63343575f432aecd5028f73ba31467c9835a02bbaaf226
Copying blob sha256:78efc9e155c4f5ac3665c4ef14339c305672468520dc0d5ad5a254ce90a1ec28
Copying blob sha256:6b5d182bcccd850d3b6313e37abc89b43b3dfa992dfd1b3256fa80b2f22dd349
Copying blob sha256:6889f5ec228fd15e1e4e8e99333405ea42a119c9899e47ce691c70a7fbf1ed67
Copying blob sha256:0dd0f9a156c69e0224eba0dcaf0aa19bde2a58213bc7000e4982473b5056c3d7
Copying blob sha256:1997c4647b2a44e91accefa73e019660f0f703c0193100ed4f1bf14d7a9a29c5
Copying config sha256:42c046e05a707bc547fbe94eb22282563af69c849575fe769ca15f82121f1a6f
Writing manifest to image destination
Storing signatures
STEP 1: FROM helper.cluster-0001.rhsacn.org:5000/openshift/wildfly-101-centos7@sha256:7775d40f77e22897dc760b76f1656f67ef6bd5561b4d74fbb030b977f61d48e8
STEP 2: COPY ROOT.war /wildfly/standalone/deployments/ROOT.war
error: build error: error building at STEP "COPY ROOT.war /wildfly/standalone/deployments/ROOT.war": error adding sources [/tmp/build/inputs/ROOT.war]: error checking on source /tmp/build/inputs/ROOT.war under "/tmp/build/inputs": copier: stat: "/ROOT.war": no such file or directory

# 现在可以再次开始 pipeline
# Build WAR 过程中查看 maven pod 的日志
oc logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep maven)

# Build Image 过程中查看 build pod 的日志
oc logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep 2-build)
...
Copying blob sha256:971549cb69b1b3e618445e49fe6db2ab6db6c9105e6dc228d5ec4845b553d53c
Copying config sha256:c728453253f67f9991850a672fbaf5e29ec84b49c1c4459bf2bf193ee52727b2
Writing manifest to image destination
Storing signatures
Successfully pushed image-registry.openshift-image-registry.svc:5000/test1/openshift-jee-sample@sha256:100db8fa14d110966592ad20a3c1941779101ab7513607091379c685d9232851
Push successful

# 在 Deploy 阶段 Pod openshift-jee-sample-1-rbjwl 运行起来了
oc logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep openshift-jee-sample-1-rbjwl)
...
12:51:01,542 INFO  [org.jboss.as.server.deployment] (MSC service thread 1-2) WFLYSRV0027: Starting deployment of "ROOT.war" (runtime-name: "ROOT.war")
12:51:01,958 INFO  [org.jboss.ws.common.management] (MSC service thread 1-5) JBWS022052: Starting JBossWS 5.1.5.Final (Apache CXF 3.1.6) 
12:51:01,999 INFO  [org.infinispan.factories.GlobalComponentRegistry] (MSC service thread 1-6) ISPN000128: Infinispan version: Infinispan 'Chakra' 8.2.4.Final
12:51:02,070 INFO  [org.infinispan.configuration.cache.EvictionConfigurationBuilder] (ServerService Thread Pool -- 58) ISPN000152: Passivation configured without an eviction policy being selected. Only manually evicted entities will be passivated.
12:51:02,070 INFO  [org.infinispan.configuration.cache.EvictionConfigurationBuilder] (ServerService Thread Pool -- 59) ISPN000152: Passivation configured without an eviction policy being selected. Only manually evicted entities will be passivated.
12:51:02,071 INFO  [org.infinispan.configuration.cache.EvictionConfigurationBuilder] (ServerService Thread Pool -- 59) ISPN000152: Passivation configured without an eviction policy being selected. Only manually evicted entities will be passivated.
12:51:02,071 INFO  [org.infinispan.configuration.cache.EvictionConfigurationBuilder] (ServerService Thread Pool -- 58) ISPN000152: Passivation configured without an eviction policy being selected. Only manually evicted entities will be passivated.
12:51:02,430 INFO  [org.wildfly.extension.undertow] (ServerService Thread Pool -- 61) WFLYUT0021: Registered web context: /
12:51:02,457 INFO  [org.jboss.as.server] (ServerService Thread Pool -- 34) WFLYSRV0010: Deployed "ROOT.war" (runtime-name : "ROOT.war")
12:51:02,547 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0060: Http management interface listening on http://0.0.0.0:9990/management
12:51:02,548 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0051: Admin console listening on http://0.0.0.0:9990
12:51:02,549 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0025: WildFly Full 10.1.0.Final (WildFly Core 2.2.0.Final) started in 3722ms - Started 398 of 647 services (400 services are lazy, passive or on-demand)

```

### kubectl cheatsheet
https://unofficial-kubernetes.readthedocs.io/en/latest/user-guide/kubectl-cheatsheet/
```
$ kubectl patch node k8s-node-1 -p '{"spec":{"unschedulable":true}}' # Partially update a node

# Update a container's image; spec.containers[*].name is required because it's a merge key
$ kubectl patch pod valid-pod -p '{"spec":{"containers":[{"name":"kubernetes-serve-hostname","image":"new image"}]}}'

# Update a container's image using a json patch with positional arrays
$ kubectl patch pod valid-pod --type='json' -p='[{"op": "replace", "path": "/spec/containers/0/image", "value":"new image"}]'
```


### 测试 jenkins template
使用的 template 文件参见：https://raw.githubusercontent.com/wangjun1974/tips/master/ocp/files/jenkins_template-jwang.yaml
```
oc create namespace infra
oc project infra

oc new-app --file=jenkins_template-jwang.yaml
oc adm policy add-scc-to-user privileged -z jenkins-privilege -n infra

oc -n infra delete pod $(oc get pods -n infra -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep deploy)

oc rollout latest dc/jenkins-privilege

oc -n infra logs $(oc get pods -n infra -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep deploy)

oc -n infra describe pod $(oc get pods -n infra -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) | grep scc 

# 这种修改并不能自动创建 pv
oc patch pvc jenkins-privilege --type json -p '[{"op": "replace", "path": "/spec/storageclassname", "value": "nfs-storage-provisioner"}]'

# 查看 pvc  
oc describe pvc jenkins-privilege 
Name:          jenkins-privilege
Namespace:     infra
StorageClass:  nfs-storage-provisioner
Status:        Pending
Volume:        
Labels:        app=jenkins-persistent-privilege
               template=jenkins-persistent-template-privilege
Annotations:   openshift.io/generated-by: OpenShiftNewApp
               volume.beta.kubernetes.io/storage-provisioner: nfs-storage
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      
Access Modes:  
VolumeMode:    Filesystem
Mounted By:    jenkins-privilege-2-hxqnx
Events:
  Type    Reason                Age               From                         Message
  ----    ------                ----              ----                         -------
  Normal  ExternalProvisioning  7s (x4 over 41s)  persistentvolume-controller  waiting for a volume to be created, either by external provisioner "nfs-storage" or manually created by system administrator

# 参考：https://blog.csdn.net/weixin_34306446/article/details/89690812
# 添加 （这步应该不是必须的）
cat > add-clusterrole-binding.yaml << EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-provisioner
subjects:
  - kind: ServiceAccount
    name: jenkins-privilege
    namespace: infra
roleRef:
  kind: ClusterRole
  name: nfs-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
EOF

oc apply -f ./add-clusterrole-binding.yaml

# 查看日志
oc -n nfs-provisioner describe pod nfs-client-provisioner-76dbdf68fd-sdhdf
...
  Warning  Failed          4h30m (x154 over 17h)  kubelet, worker1.cluster-0001.rhsacn.org  Failed to pull image "quay.io/external_storage/nfs-client-provisioner:latest": rpc error: code = Unknown desc = error pinging docker registry quay.io: Get "https://quay.io/v2/": dial tcp: lookup quay.io on 10.66.208.138:53: server misbehaving
  Normal   Pulling         70m (x202 over 4d14h)  kubelet, worker1.cluster-0001.rhsacn.org  Pulling image "quay.io/external_storage/nfs-client-provisioner:latest"
  Warning  Failed          20m (x4424 over 17h)   kubelet, worker1.cluster-0001.rhsacn.org  Error: ImagePullBackOff
  Normal   BackOff         43s (x4508 over 17h)   kubelet, worker1.cluster-0001.rhsacn.org  Back-off pulling image "quay.io/external_storage/nfs-client-provisioner:latest"

# 问题应该是由于离线镜像仓库里没有所需镜像造成的，在离线环境中同步所需镜像
skopeo copy --format v2s2 --authfile /root/pull-secret-2.json --all docker://quay.io/external_storage/nfs-client-provisioner:latest docker://helper.cluster-0001.rhsacn.org:5000/external_storage/nfs-client-provisioner:latest

# patch deployment nfs-client-provisioner 指向本地镜像仓库
oc -n nfs-provisioner patch deployment nfs-client-provisioner --type json -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "helper.cluster-0001.rhsacn.org:5000/external_storage/nfs-client-provisioner:latest"}]'

# 触发新部署
oc -n nfs-provisioner patch deployment/nfs-client-provisioner --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

# 查看日志
oc -n nfs-provisioner logs $(oc get pods -n nfs-provisioner -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}')

# rollout jenkins deploymentconfig
oc rollout latest dc/jenkins-privilege -n infra

# 查看 jenkins 日志
oc -n infra logs $(oc get pods -n infra -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy)
```

### 继续测试
```
# 登录 jenkins pod
oc -n infra rsh $(oc get pods -n infra -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy)

# 如何为 jenkins 选择合适的 jdk 版本呢
# https://itnext.io/running-jenkins-builds-in-containers-458e90ff2a7b

# 参考：https://bugzilla.redhat.com/show_bug.cgi?id=1848611
# 将默认的 JDK 版本设置为 
oc rsh maven-tkb34
sh-4.2 $ update-alternatives --config java
There are 2 programs which provide 'java'.

  Selection    Command
-----------------------------------------------
 + 1           java-11-openjdk.x86_64 (/usr/lib/jvm/java-11-openjdk-11.0.9.11-0.el8_2.x86_64/bin/java)
*  2           java-1.8.0-openjdk.x86_64 (/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.272.b10-1.el8_2.x86_64/jre/bin/java)

Enter to keep the current selection[+], or type selection number: 2

sh-4.4$ java -version 
openjdk version "1.8.0_272"
OpenJDK Runtime Environment (build 1.8.0_272-b10)
OpenJDK 64-Bit Server VM (build 25.272-b10, mixed mode)

# 查询 java 版本
oc -n infra rsh $(oc get pods -n infra -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) java -version

# update-alternatives 的帮助信息
alternatives version 1.11 - Copyright (C) 2001 Red Hat, Inc.
This may be freely redistributed under the terms of the GNU Public License.

usage: alternatives --install <link> <name> <path> <priority>
                    [--initscript <service>]
                    [--family <family>]
                    [--slave <slave_link> <slave_name> <slave_path>]*
       alternatives --remove <name> <path>
       alternatives --auto <name>
       alternatives --config <name>
       alternatives --display <name>
       alternatives --set <name> <path>
       alternatives --list
       alternatives --remove-all <name>
       alternatives --add-slave <name> <path> <slave_link> <slave_name> <slave_path>
       alternatives --remove-slave <name> <path> <slave_name>

common options: --verbose --test --help --usage --version --keep-missing
                --altdir <directory> --admindir <directory>

# update-alternatives --set 
# 更新 java 到 1.8
oc -n infra rsh $(oc get pods -n infra -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) update-alternatives --set java /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.272.b10-1.el8_2.x86_64/jre/bin/java

# 查询 java 版本
oc -n infra rsh $(oc get pods -n infra -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) java -version

```

### Enhancing your Builds on OpenShift: Chaining Builds
这个 Blog 非常值得阅读。
https://www.openshift.com/blog/chaining-builds


### 检查集群健康状态
```
echo “check pods health on masters ...”
for i in $(seq 0 2)
do
  echo master${i} 
  oc get pods --all-namespaces -o wide | grep master${i} | grep -Ev "Running|Complete"
  echo
done

echo “check pods health on workers ...”
for i in $(seq 0 2)
do
  echo worker${i} 
  oc get pods --all-namespaces -o wide | grep worker${i} | grep -Ev "Running|Complete"
  echo
done

echo “check reachable on masters ...”
DOMAIN="cluster-0001.rhsacn.org"
for i in $(seq 0 2)
do
  echo master${i} 
  IP=$( oc get nodes master${i}.${DOMAIN} -o jsonpath='{@.status.addresses[?(@.type=="InternalIP")].address}' )
  ping -c1 ${IP} >/dev/null 2>/dev/null
  if [ $? -eq 0 ]; then echo "master${i} is reachable..."; else echo "master${i} is not reachable..."; fi
  echo
done

echo “check reachable on workers ...”
DOMAIN="cluster-0001.rhsacn.org"
for i in $(seq 0 2)
do
  echo worker${i} 
  IP=$( oc get nodes worker${i}.${DOMAIN} -o jsonpath='{@.status.addresses[?(@.type=="InternalIP")].address}' )
  ping -c1 ${IP} >/dev/null 2>/dev/null
  if [ $? -eq 0 ]; then echo "worker${i} is reachable..."; else echo "worker${i} is not reachable..."; fi
  echo
done

echo “check oc debug on masters ...”
DOMAIN="cluster-0001.rhsacn.org"
for i in $(seq 0 2)
do
  echo master${i} 
  IP=$( oc get nodes master${i}.${DOMAIN} -o jsonpath='{@.status.addresses[?(@.type=="InternalIP")].address}' )
  oc debug node/master${i}.${DOMAIN} -- chroot /host crictl ps --name openvswitch -o json
done

echo “check oc debug on workers ...”
DOMAIN="cluster-0001.rhsacn.org"
for i in $(seq 0 2)
do
  echo worker${i} 
  IP=$( oc get nodes worker${i}.${DOMAIN} -o jsonpath='{@.status.addresses[?(@.type=="InternalIP")].address}' )
  oc debug node/worker${i}.${DOMAIN} -- chroot /host crictl ps --name openvswitch -o json
done

echo “check openvswitch pod on masters ...”
DOMAIN="cluster-0001.rhsacn.org"
for i in $(seq 0 2)
do
  echo master${i} 
  IP=$( oc get nodes master${i}.${DOMAIN} -o jsonpath='{@.status.addresses[?(@.type=="InternalIP")].address}' )
  oc debug node/master${i}.${DOMAIN} -- chroot /host crictl ps --name openvswitch -o json | jq '{name: .containers[0].metadata.name, state: .containers[0].state}'
done

echo “check openvswitch pod on workers ...”
DOMAIN="cluster-0001.rhsacn.org"
for i in $(seq 0 2)
do
  echo worker${i} 
  IP=$( oc get nodes worker${i}.${DOMAIN} -o jsonpath='{@.status.addresses[?(@.type=="InternalIP")].address}' )
  oc debug node/worker${i}.${DOMAIN} -- chroot /host crictl ps --name openvswitch -o json | jq '{name: .containers[0].metadata.name, state: .containers[0].state}'
done

echo “check pods logs CrashLoopBackOff on masters ...”
for i in $(seq 0 2)
do
  echo master${i} 
  oc get pods --all-namespaces -o wide | grep master${i} | grep -Ev "Running|Complete" | grep -E "CrashLoopBackOff" | awk '{print $1" "$2}' | while read namespace podname
  do 
    echo "logs of $podname in namespace $namespace"
    oc -n $namespace logs $podname -p
    echo
  done 
  echo
done

echo “check pods logs CrashLoopBackOff on workers ...”
for i in $(seq 0 2)
do
  echo worker${i} 
  oc get pods --all-namespaces -o wide | grep worker${i} | grep -Ev "Running|Complete" | grep -E "CrashLoopBackOff" | awk '{print $1" "$2}' | while read namespace podname
  do 
    echo "logs of $podname in namespace $namespace"
    oc -n $namespace logs $podname -p
    echo
  done 
  echo
done

echo “check free by oc debug on masters ...”
DOMAIN="cluster-0001.rhsacn.org"
for i in $(seq 0 2)
do
  echo master${i} 
  IP=$( oc get nodes master${i}.${DOMAIN} -o jsonpath='{@.status.addresses[?(@.type=="InternalIP")].address}' )
  oc debug node/master${i}.${DOMAIN} -- chroot /host free
done
```

### 设置 jenkins 使用 jdk 版本的方法
```
15:37 <Catherine_H> 找到两种方法 一个是在dc里面设置      
                    JAVA_HOME:III/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-3.b13.el7_5.x86_64，另一个是在jenkins UI里面说是可以指定jdk版本
15:37 <Catherine_H> https://stackoverflow.com/questions/28810477/how-to-change-the-jdk-for-a-jenkins-job
15:38 <Catherine_H>   Containers:
15:38 <Catherine_H>    jenkins:
15:38 <Catherine_H>     
Image:Iregistry.access.redhat.com/openshift3/jenkins-2-rhel7@sha256:3a51056f6817d1e9d89e549b364fd36d0050e2414602bdce7b9079c5759f13df
15:38 <Catherine_H>     Limits:
15:38 <Catherine_H>       memory:I3G
15:38 <Catherine_H>     Environment:
15:38 <Catherine_H>       JENKINS_SERVICE_NAME:IIjenkins-unimoni
15:38 <Catherine_H>       JNLP_SERVICE_NAME:IIjenkins-unimoni-jnlp
15:39 <Catherine_H>       JAVA_HOME:III/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-3.b13.el7_5.x86_64
```

### OCP 4.6 baremetal non integration 安装
来自王征所写的 OCP 4.6 baremetal non integration 安装 <br>
https://github.com/wangzheng422/docker_env/blob/master/redhat/ocp4/4.6/4.6.disconnect.bm.upi.static.ip.on.rhel8.md

来自王征所写的 OCP 4.6 baremetal ipi 安装 <br>
https://github.com/wangzheng422/docker_env/blob/master/redhat/ocp4/4.6/4.6.disconnect.bm.ipi.on.rhel8.md


### OCS 4.5 的培训材料
https://github.com/red-hat-storage/ocs-training/blob/pre-antora/ocs4postgresql/create_ocs_postgresql_template

### 查看在 aws 下 openshift-install 支持哪些 installconfig 参数
```
$ openshift-install explain installconfig.platform.aws
KIND:     InstallConfig
VERSION:  v1

RESOURCE: <object>
  AWS is the configuration used when installing on AWS.

FIELDS:
    amiID <string>
      AMIID is the AMI that should be used to boot machines for the cluster. If set, the AMI should belong to the same region as the cluster.

    defaultMachinePlatform <object>
      DefaultMachinePlatform is the default configuration used when installing on AWS for machine pools which do not define their own platform configuration.

    region <string> -required-
      Region specifies the AWS region where the cluster will be created.

    serviceEndpoints <[]object>
      ServiceEndpoints list contains custom endpoints which will override default service endpoint of AWS Services. There must be only one ServiceEndpoint for a service.
      ServiceEndpoint store the configuration for services to override existing defaults of AWS Services.

    subnets <[]string>
      Subnets specifies existing subnets (by ID) where cluster resources will be created.  Leave unset to have the installer create subnets in a new VPC on your behalf.

    userTags <object>
      UserTags additional keys and values that the installer will add as tags to all resources that it creates. Resources created by the cluster itself may not include these tags.
```

### OpenShift 4.6 AWS UPI vpc 相关信息
https://github.com/openshift/installer/blob/release-4.6/upi/aws/cloudformation/01_vpc.yaml

### OpenShift 4.6 AWS IPI vpc 相关信息
https://github.com/openshift/installer/tree/release-4.6/data/data/aws/vpc

### 为 OpenShift Service Mesh 配置 ElasticSearch 存储 
https://docs.openshift.com/container-platform/4.6/service_mesh/v2x/ossm-custom-resources.html#ossm-configuring-jaeger-elasticsearch_ossm-custom-resources-v2x

为 OpenShift Service Mesh 配置外部 ElasticSearch<br>
https://www.techbeatly.com/2020/06/openshift-4-ossm-jaegers-external-elasticsearch.html#.X9LKbVMzbOR

### PromQL query to find CPU and memory used for the last week
如何查询在之前的某段时间内，namespace 的内存用量
https://stackoverflow.com/questions/62770744/promql-query-to-find-cpu-and-memory-used-for-the-last-week
```
To check the percentage of memory used by each namespace you will need a query similar to the one below:

sum( container_memory_working_set_bytes{container="", namespace=~".+"} )|
by (namespace) / ignoring (namespace) group_left 
sum( machine_memory_bytes{}) * 100 

Disclaimers!:

The screenshot above is from Grafana for better visibility.
This query does not acknowledge changes in available RAM (changes in nodes, autoscaling of nodes, etc.).

To get the metric over a period of time in PromQL you will need to use additional function like:

avg_over_time(EXP[time]).
To go back in time and calculate resources from specific point in time you will need to use:

offset TIME
Using above pointers query should combine to:

avg_over_time( sum(container_memory_working_set_bytes{container="", namespace=~".+"} offset 45m) by (namespace)[120m:])  / ignoring (namespace) group_left 
sum( machine_memory_bytes{}) 

Above query will calculate the average percentage of memory used by each namespace and divide it by all memory in the cluster in the span of 120 minutes to present time. It will also start 45 minutes earlier from present time.

Example:

Time of running the query: 20:00
avg_over_time(EXPR[2h:])
offset 45 min

Above example will start at 17:15 and it will run the query to the 19:15. You can modify it to include the whole week :).

If you want to calculate the CPU usage by namespace you can replace this metrics with the one below:

container_cpu_usage_seconds_total{} - please check rate() function when using this metric (counter)
machine_cpu_cores{}

You could also look on this network metrics:

container_network_receive_bytes_total - please check rate() function when using this metric (counter)
container_network_transmit_bytes_total - please check rate() function when using this metric (counter)

I've included more explanation below with examples (memory), methodology of testing and dissection of used queries.

Let's assume:

Kubernetes cluster 1.18.6 (Kubespray) with 12GB of memory in total:
master node with 2GB of memory
worker-one node with 8GB of memory
worker-two node with 2GB of memory

Prometheus and Grafana installed with: Github.com: Coreos: Kube-prometheus
Namespace kruk with single ubuntu pod set to generate artificial load with below command:

$ stress-ng --vm 1 --vm-bytes <AMOUNT_OF_RAM_USED> --vm-method all -t 60m -v

The artificial load was generated with stress-ng two times:

60 minutes - 1GB of memory used
60 minutes - 2GB of memory used

The percentage of memory used by namespace kruk in this timespan:

1GB which accounts for about ~8.5% of all memory in the cluster (12GB)
2GB which accounts for about ~17.5% of all memory in the cluster (12GB)

The load from Prometheus query for kruk namespace was looking like that:

Calculation using avg_over_time(EXPR[time:]) / memory in the cluster showed the usage in the midst of about 13% ((17.5+8.5)/2) when querying the time the artificial load was generated. This should indicate that the query was correct:

As for the used query:

avg_over_time( sum( container_memory_working_set_bytes{container="", namespace="kruk"} offset 1380m )
by (namespace)[120m:]) / ignoring (namespace) group_left 
sum( machine_memory_bytes{}) * 100 

Above query is really similar to the one in the beginning but I've made some changes to show only the kruk namespace.

I divided the query explanation on 2 parts (dividend/divisor).

Dividend
container_memory_working_set_bytes{container="", namespace="kruk"}

This metric will output records of memory usage in namespace kruk. If you were to query for all namespaces look on additional explanation:

namespace=~".+" <- this regexp will match only when the value inside of namespace key is containing 1 or more characters. This is to avoid empty namespace result with aggregated metrics.

container="" <- part is used to filter the metrics. If you were to query without it you would get multiple memory usage metrics for each container/pod like below. container="" will match only when container value is empty (last row in below citation).


container_memory_working_set_bytes{container="POD",endpoint="https-metrics",id="/kubepods/podab1ed1fb-dc8c-47db-acc8-4a01e3f9ea1b/e249c12010a27f82389ebfff3c7c133f2a5da19799d2f5bb794bcdb5dc5f8bca",image="k8s.gcr.io/pause:3.2",instance="192.168.0.124:10250",job="kubelet",metrics_path="/metrics/cadvisor",name="k8s_POD_ubuntu_kruk_ab1ed1fb-dc8c-47db-acc8-4a01e3f9ea1b_0",namespace="kruk",node="worker-one",pod="ubuntu",service="kubelet"} 692224
container_memory_working_set_bytes{container="ubuntu",endpoint="https-metrics",id="/kubepods/podab1ed1fb-dc8c-47db-acc8-4a01e3f9ea1b/fae287e7043ff00da16b6e6a8688bfba0bfe30634c52e7563fcf18ac5850f6d9",image="ubuntu@sha256:5d1d5407f353843ecf8b16524bc5565aa332e9e6a1297c73a92d3e754b8a636d",instance="192.168.0.124:10250",job="kubelet",metrics_path="/metrics/cadvisor",name="k8s_ubuntu_ubuntu_kruk_ab1ed1fb-dc8c-47db-acc8-4a01e3f9ea1b_0",namespace="kruk",node="worker-one",pod="ubuntu",service="kubelet"} 2186403840
container_memory_working_set_bytes{endpoint="https-metrics",id="/kubepods/podab1ed1fb-dc8c-47db-acc8-4a01e3f9ea1b",instance="192.168.0.124:10250",job="kubelet",metrics_path="/metrics/cadvisor",namespace="kruk",node="worker-one",pod="ubuntu",service="kubelet"} 2187096064


You can read more about pause container here:

Ianlewis.org: Almighty pause container

sum( container_memory_working_set_bytes{container="", namespace="kruk"} offset 1380m )
by (namespace)

This query will sum the results by their respective namespaces. offset 1380m is used to go back in time as the tests were made in the past.

avg_over_time( sum( container_memory_working_set_bytes{container="", namespace="kruk"} offset 1380m )
by (namespace)[120m:])

This query will calculate average from memory metric across namespaces in the specified time (120m to now) starting 1380m earlier than present time.

You can read more about avg_over_time() here:

Prometheus.io: Aggregation over time
Prometheus.io: Blog: Subquery support

Divisor
sum( machine_memory_bytes{})
This metric will sum the memory available in each node in the cluster.

EXPR / ignoring (namespace) group_left 
sum( machine_memory_bytes{}) * 100 
Focusing on:

/ ignoring (namespace) group_left <- this expression will allow you to divide each "record" in the dividend (each namespace with their memory average across time) by a divisor (all memory in the cluster). You can read more about it here: Prometheus.io: Vector matching

* 100 is rather self explanatory and will multiply the result by a 100 to look more like percentages.

Additional resources:

Prometheus.io: Querying: Basics
Timber.io: Blog: Promql for humans
Grafana.com: Dashboards: 315
```

### OpenShift 从 Thanos 里查询信息
```
# 查询 storage class 
curl -k -H "Authorization: Bearer $(oc whoami -t)" "https://$(oc get routes -n openshift-monitoring thanos-querier -o jsonpath='{ .spec.host'})/api/v1/query?query=kube_storageclass_info&dedup=true"

# 查询 console 的 url
curl -k -H "Authorization: Bearer $(oc whoami -t)" "https://$(oc get routes -n openshift-monitoring thanos-querier -o jsonpath='{ .spec.host'})/api/v1/query?query=console_url&dedup=true" | jq -r '.data.result[0].metric.url'
```

### 检查 worker.ign 的证书
```
cat worker.ign | jq -r '.ignition.security.tls.certificateAuthorities[0].source' | sed -e 's|^.*base64,||'  | base64 -d | openssl x509 -text -noout -in /dev/stdin | grep -E "Not Before|Not After" 
``` 

### 检查 machine config daemon 日志
```
oc -n openshift-machine-config-operator logs $(oc get pods -n openshift-machine-config-operator -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep daemon-5c) -c machine-config-daemon 
...
E1214 08:49:32.450838    2595 writer.go:135] Marking Degraded due to: open /sys/block/sdb/queue/.rotational138096396: permission denied

oc -n openshift-machine-config-operator delete pod $(oc get pods -n openshift-machine-config-operator -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep daemon-5c)


```

### 测试 nexus3
```
mkdir -p /var/nexus3/nexus3_test

podman run -d --name nexus3 -v /var/nexus3/nexus3_test:/nexus-data sonatype/nexus3
podman run -d --name nexus3_1 -v /var/nexus3/nexus3_test:/nexus-data sonatype/nexus3

```

### install docker-ce on RHEL8
https://help.hcltechsw.com/bigfix/10.0/mcm/MCM/Config/install_docker_ce_docker_compose_on_rhel_8.html
```
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf repolist -v
sudo dnf install --nobest docker-ce

```

### 查看 OperatorHub cluster
```
oc get OperatorHub cluster -o json | jq . 
```

### 4 个方法在 OpenShift 下构建应用程序
https://dzone.com/articles/4-ways-to-build-applications-in-openshift-1 
```
# 方式1
oc new namespace test1
oc project test1
oc new-build nodejs~https://github.com/cesarvr/hello-world-nodejs --name=nodejs-build

# 查看对象
oc -n test1 get all
NAME                       READY   STATUS      RESTARTS   AGE
pod/nodejs-build-1-build   0/1     Completed   0          2m50s

NAME                                          TYPE     FROM   LATEST
buildconfig.build.openshift.io/nodejs-build   Source   Git    1

NAME                                      TYPE     FROM          STATUS     STARTED         DURATION
build.build.openshift.io/nodejs-build-1   Source   Git@5623514   Complete   2 minutes ago   1m33s

NAME                                          IMAGE REPOSITORY                                                      TAGS     UPDATED
imagestream.image.openshift.io/nodejs-build   image-registry.openshift-image-registry.svc:5000/test1/nodejs-build   latest   About a minute ago

# 查看日志
oc -n test1 logs $(oc -n test1 get pod -o jsonpath='{.items[0].metadata.name}')
Adding cluster TLS certificate authority to trust store
Caching blobs under "/var/cache/blobs".
Getting image source signatures
Copying blob sha256:6500ac87b29ffd00c8655be65a6824dfcf9fc0accc625158ef1060bcedc84ca8
Copying blob sha256:0c7bc3c1e1a396e2e329b971eeab99d8c2dcc8ce18964770bff841eedfff3397
Copying blob sha256:1b8dabac56ed728c17a670d327474ab87dc392dc17721854ea599a7753326579
Copying blob sha256:2603ccf3ba62ab3cdf4fbe4ae582ed4c9e7191d16efaf5c0bdedafe2cbdf5553
Copying blob sha256:3c6f298d7f4fcdea4dbdc5d5ac81a13a9201efcea7cfd7d4478cba6f1f08fd7e
Copying config sha256:db4e490a45d85c077a42b3ef3cc0625b63ce7d3960ee81894e9b725271fbc6b9
Writing manifest to image destination
Storing signatures
Generating dockerfile with builder image image-registry.openshift-image-registry.svc:5000/openshift/nodejs@sha256:4c2a9a7cb573190fcf8772b054f090daabc8b957cad0ba2373899ed6a70c25dd
...
STEP 1: FROM image-registry.openshift-image-registry.svc:5000/openshift/nodejs@sha256:4c2a9a7cb573190fcf8772b054f090daabc8b957cad0ba2373899ed6a70c25dd
STEP 2: LABEL "io.openshift.build.commit.date"="Sun Mar 22 11:56:47 2020 +0000"       "io.openshift.build.commit.id"="562351422e8b6b63168184a7aecaec14686e6a46"       "io.openshift.build.commit.ref"="master"       "io.openshift.build.commit.message"="Create README.md"       "io.openshift.build.source-location"="https://github.com/cesarvr/hello-world-nodejs"       "io.openshift.build.image"="image-registry.openshift-image-registry.svc:5000/openshift/nodejs@sha256:4c2a9a7cb573190fcf8772b054f090daabc8b957cad0ba2373899ed6a70c25dd"       "io.openshift.build.commit.author"="Cesar Valdez <cesarv01@yahoo.com>"
STEP 3: ENV OPENSHIFT_BUILD_NAME="nodejs-build-1"     OPENSHIFT_BUILD_NAMESPACE="test1"     OPENSHIFT_BUILD_SOURCE="https://github.com/cesarvr/hello-world-nodejs"     OPENSHIFT_BUILD_COMMIT="562351422e8b6b63168184a7aecaec14686e6a46"
STEP 4: USER root
STEP 5: COPY upload/src /tmp/src
STEP 6: RUN chown -R 1001:0 /tmp/src
STEP 7: USER 1001
STEP 8: RUN /usr/libexec/s2i/assemble
STEP 9: CMD /usr/libexec/s2i/run
STEP 10: COMMIT temp.builder.openshift.io/test1/nodejs-build-1:c8027934
Getting image source signatures
Copying blob sha256:0b5feeefca258787c519a497e76fd0537a4635b327afc7c44f578f190e0be37f
Copying blob sha256:37ab7f712dcb91a697a5bf63475f5b1723a55b3fb5af11f0c1fa42e6ec163868
Copying blob sha256:af7dc60e1bfb32557c735ee52ca2e95885bb134d84393bf2ae0169304425ffec
Copying blob sha256:7a9f4af0a3a5ba525906dea3505b4c693a9137c00823110bc7993661b13a1fb9
Copying blob sha256:e5702422d6b2e52de769904448d1e1a1bbaf521bcbcea7b07dbeb80d7e9b8c3d
Copying blob sha256:5f1a86bd6165767a26519fa41a4d6de774d494b4871326210c1e9215e746bf22
Copying config sha256:18d9c593c9878745270ff898d754ab4cc3d915115c02f653a08d964db95aee51
Writing manifest to image destination
Storing signatures
--> 18d9c593c98
18d9c593c9878745270ff898d754ab4cc3d915115c02f653a08d964db95aee51

Pushing image image-registry.openshift-image-registry.svc:5000/test1/nodejs-build:latest ...
Getting image source signatures
Copying blob sha256:5f1a86bd6165767a26519fa41a4d6de774d494b4871326210c1e9215e746bf22
Copying blob sha256:1b8dabac56ed728c17a670d327474ab87dc392dc17721854ea599a7753326579
Copying blob sha256:2603ccf3ba62ab3cdf4fbe4ae582ed4c9e7191d16efaf5c0bdedafe2cbdf5553
Copying blob sha256:0c7bc3c1e1a396e2e329b971eeab99d8c2dcc8ce18964770bff841eedfff3397
Copying blob sha256:6500ac87b29ffd00c8655be65a6824dfcf9fc0accc625158ef1060bcedc84ca8
Copying blob sha256:3c6f298d7f4fcdea4dbdc5d5ac81a13a9201efcea7cfd7d4478cba6f1f08fd7e
Copying config sha256:18d9c593c9878745270ff898d754ab4cc3d915115c02f653a08d964db95aee51
Writing manifest to image destination
Storing signatures
Successfully pushed image-registry.openshift-image-registry.svc:5000/test1/nodejs-build@sha256:a7b8e9fdcc40ca75f872d1846639e7010f4495166e228cf0b4b1e3f96
228d263
Push successful

# 部署应用
oc new-app nodejs-build --name nodejs-demo
oc expose service/nodejs-demo

# 获取路由
oc get route -o=jsonpath='{range .items[?(@.metadata.name=="nodejs-demo")]}{@.spec.host}{"\n"}{end}'

# 方式2
git clone https://github.com/cesarvr/Spring-Boot spring_boot
cd spring_boot
# generate the binary executable file in ./build/libs/
gradle bootJar

# we got a file named: hello-boot-0.1.0.jar

# 参考：https://developers.redhat.com/blog/2018/12/18/openshift-java-s2i-builder-java-11-grade/

# generate the build configuration
oc new-build java --name=java-binary-build --binary=true

oc start-build bc/java-binary-build --from-file=./build/libs/hello-boot-0.1.0.jar --follow

```


### 查看有哪些 imagestream
```
oc get is -n openshift -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
```

### Red Hat Security API Data Examples
```
cat > get_rhsa_2016_1847.py << 'EOF'
#!/usr/bin/env python
from __future__ import print_function
import sys
import requests
from datetime import datetime, timedelta

API_HOST = 'https://access.redhat.com/hydra/rest/securitydata'


def get_data(query):

    full_query = API_HOST + query
    r = requests.get(full_query)

    if r.status_code != 200:
        print('ERROR: Invalid request; returned {} for the following '
              'query:\n{}'.format(r.status_code, full_query))
        sys.exit(1)

    if not r.json():
        print('No data returned with the following query:')
        print(full_query)
        sys.exit(0)

    return r.json()


# Get a list of issues and their impacts for RHSA-2016:1847
endpoint = '/cve.json'
params = 'advisory=RHSA-2016:1847'

data = get_data(endpoint + '?' + params)

for cve in data:
    print(cve['CVE'], cve['severity'])


print('-----')
# Get a list of kernel advisories for the last 30 days and display the
# packages that they provided.
endpoint = '/cvrf.json'
date = datetime.now() - timedelta(days=30)
params = 'package=kernel&after=' + str(date.date())

data = get_data(endpoint + '?' + params)

kernel_advisories = []
for advisory in data:
    print(advisory['RHSA'], advisory['severity'], advisory['released_on'])
    print('-', '\n- '.join(advisory['released_packages']))
    kernel_advisories.append(advisory['RHSA'])


print('-----')
# From the list of advisories saved in the previous example (as
# `kernel_advisories`), get a list of affected products for each advisory.
endpoint = '/cvrf/'

for advisory in kernel_advisories:
    data = get_data(endpoint + advisory + '.json')
    print(advisory)

    product_branch = data['cvrfdoc']['product_tree']['branch']
    for product_branch in data['cvrfdoc']['product_tree']['branch']:

        if product_branch['type'] == 'Product Family':

            if type(product_branch['branch']) is dict:
                print('-', product_branch['branch']['full_product_name'])

            else:
                print('-', '\n- '.join(pr['full_product_name'] for
                                       pr in product_branch['branch']))
EOF

# 查询某个 CVE，例如: CVE-2020-10771
curl https://access.redhat.com/hydra/rest/securitydata/cve.json | jq -r '.[] | select( .CVE == "CVE-2020-10771" )'

# 根据变量查询 Red Hat Security Data API
CVE_IN_QUESTION="CVE-2020-10771"

curl https://access.redhat.com/hydra/rest/securitydata/cve.json | jq -r ".[] | select( .CVE == \"${CVE_IN_QUESTION}\" )"

# 根据变量查询 Red Hat Security Data API 并输出选择的字段
curl https://access.redhat.com/hydra/rest/securitydata/cve.json | jq -r ".[] | select( .CVE == \"${CVE_IN_QUESTION}\" ) | .CVE, .bugzilla, .advisories"

```

### OpenShift 4 上调试 etcd 的命令
```
# 原始版本
ssh -i <cert> core@<master> (or oc debug node/<node>)
crictl exec -it <etcd-member pod id> /bin/bash
export ETCDCTL_API=3 ETCDCTL_CACERT=/etc/ssl/etcd/ca.crt 
export ETCDCTL_CERT=$(find /etc/ssl/ -name *peer*crt) 
export ETCDCTL_KEY=$(find /etc/ssl/ -name *peer*key)
etcdctl get --prefix / --keys-only

# 一条命令的版本
ssh -i <cert> core@<master> (or oc debug node/<node>)
crictl exec -it $( crictl ps --name etcdctl -o json | jq -r '.containers[0].id' ) etcdctl get --prefix / --keys-only
```

### 在 RHEL7 上安装 gradle 
https://yallalabs.com/devops/how-to-install-gradle-centos-7-rhel-7/
```
wget https://services.gradle.org/distributions/gradle-6.4.1-bin.zip -P /tmp

sudo unzip -d /opt/gradle /tmp/gradle-*.zip

cat > /etc/profile.d/gradle.sh << 'EOF'
export GRADLE_HOME=/opt/gradle/gradle-6.4.1
export PATH=${GRADLE_HOME}/bin:${PATH}
EOF

source /etc/profile.d/gradle.sh

gradle -v


```

### 制作并修改 coreos iso 的工具
https://github.com/chuckersjp/coreos-iso-maker<br>

jinja template 内核参数的例子<br>
https://github.com/RedHatOfficial/ocp4-helpernode/blob/master/templates/pxe-master.j2

coreos-installer options for ISO install<br>
https://docs.openshift.com/container-platform/4.6/installing/installing_bare_metal/installing-bare-metal.html#installation-user-infra-machines-static-network_installing-bare-metal

### Layered Approach to Container and Kubernetes Security
https://www.redhat.com/en/resources/layered-approach-security-detail<br>

### Introducing Cloud Native Storage for vSphere
https://blogs.vmware.com/virtualblocks/2019/08/14/introducing-cloud-native-storage-for-vsphere/

### OpenShift 4.6 ElasticSearch Backup 相关内容
```
# 目前需要将 elasticsearch CR 设置为 unmanaged mode
# 然后修改 elasticsearch.yml，修改内容如下：
    path:
      data: /elasticsearch/persistent/${CLUSTER_NAME}/data
      logs: /elasticsearch/persistent/${CLUSTER_NAME}/logs
      repo: /elasticsearch/persistent/backup ## LINE TO ADD
```

### 在 OpenShift Build Config 里配置 sshkey git 认证
https://docs.ukcloud.com/articles/openshift/oshift-how-build-app-private-repo.html

```
# 生成用来做 git 认证的 sshkey
ssh-keygen -t rsa -b 4096 -c "jbloggs@example.com" -f my_GitHub_deploy_key

# 把 public key 添加给 git repo 
# 步骤参见：https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys

# 把 private key 做成 openshift secret
oc create secret generic myGitHubsecret --from-file=ssh-privatekey=./my_GitHub_deploy_key --type=kubernetes.io/ssh-auth
# 把 secret 添加到 builder service account 上
oc secrets link builder myGitHubsecret

# 编辑 secret 到 buildconfig 
source:
  git:
    uri: ssh://git@github.com/UKCloud/my-private-repo-name.git
  sourceSecret:
    name: myGitHubsecret

# 注意 uri 是以 ssh:// 开始的
# 另外需要注意 uri 的写法需要符合
# 参见：https://docs.openshift.com/container-platform/3.5/dev_guide/builds/build_inputs.html
# URI patterns only match Git source URIs which are conformant to RFC3986. For example, https://github.com/openshift/origin.git. They do not match the alternate SSH style that Git also uses. For example, git@github.com:openshift/origin.git.
# It is not valid to attempt to express a URI pattern in the alternate style, or to include a username/password component in a URI pattern.
```


### 创建 builder pod 
```
# 创建 secret 
oc create secret generic git-auth --from-file=ssh-privatekey=./my_GitHub_deploy_key --type=kubernetes.io/ssh-auth

# 为 service account 添加 secret
oc secret link default git-auth

# 获取所需的 image uri
oc get is nodejs-build -o jsonpath='{range .items[?(@.metadata.name=="nodejs-build")]}{@.status.dockerImageRepository}'

# 用这个 image uri 启动 pod
oc run --image="$(oc get is nodejs-build -o jsonpath='{range .items[?(@.metadata.name=="nodejs-build")]}{@.status.dockerImageRepository}')" test

# 登录 builder pod
oc rsh $(oc get pods -o jsonpath='{range .items[?(@.metadata.name=="test")]}{@.metadata.name}')

# patch pod
oc patch pod $(oc get pods -o jsonpath='{range .items[?(@.metadata.name=="test")]}{@.metadata.name}') 
```

### 为 github 帐户添加 sshkey
```
# 根据 github 的手册添加 sshkey

# 在本地添加 private key， 克隆仓库，验证 sshkey 认证可正常工作
ssh-agent bash -c 'ssh-add ~/.ssh/wjqhd_github_sshkey; git clone git@github.com:wangjun1974/hello-world-nodejs.git'
ssh-add ~/.ssh/wjqhd_github_sshkey
git clone
git status
git push

# 创建 secret 
oc create secret generic git-auth-1 --from-file=ssh-privatekey=/Users/junwang/.ssh/wjqhd_github_sshkey --type=kubernetes.io/ssh-auth

# 用 secret 作为 source-secret 建立新的 build 
oc new-build nodejs~ssh://git@github.com/wangjun1974/hello-world-nodejs.git --name=ssh-4-nodejs-build --source-secret='git-auth-1'
```

### 测试 jenkins nodejs pipeline
```
oc project default
oc create namespace test1
oc project test1 

oc new-app jenkins-ephemeral

oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml
template.template.openshift.io/jenkins-pipeline-example created

oc new-app --template=jenkins-pipeline-example

oc get is jenkins-agent-nodejs -n openshift -o jsonpath='{.status.tags[0].items[0].dockerImageReference}{"\n"}'

skopeo copy --format v2s2 --authfile /root/pull-secret-2.json --all docker://quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:89b4cc10e4fdd03494e9153685808d9ad4c7a11862e8104ebe32a0d6ba62b05d docker://helper.cluster-0001.rhsacn.org:5000/ocp4/openshift4

oc -n openshift patch is jenkins-agent-nodejs --type json -p='[{"op": "replace", "path": "/spec/tags/1/from/name", "value":"helper.cluster-0001.rhsacn.org:5000/ocp4/openshift4@sha256:89b4cc10e4fdd03494e9153685808d9ad4c7a11862e8104ebe32a0d6ba62b05d"}]'

oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep build)

oc get dc/mongodb -o jsonpath='{ .spec.triggers[0].imageChangeParams.from.name}{"\n"}'

oc patch dc/mongodb --type json -p='[{"op": "replace", "path": "/spec/triggers/0/imageChangeParams/from/name", "value":"mongodb:3.6"}]'

oc get dc/mongodb -o jsonpath='{ .spec.triggers[0].imageChangeParams.from.name}{"\n"}'

oc -n test1 describe pod $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep build)

oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep build)

oc -n test1 rsh $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep build)

oc adm policy add-scc-to-user anyuid -z default -n test1
oc adm policy add-scc-to-user anyuid -z builder -n test1

oc get build -o jsonpath='{range .items[?(@.metadata.name contains "sample-pipeline" && @.status.conditions[0].type=="Running")]}{@.metadata.name}{"\n"}'

oc get build -o jsonpath='{range .items[?(@.metadata.name=="sample-pipeline-5")]}{@.metadata.name}{"\n"}'

oc get build -o jsonpath='{range .items[?(@.metadata.name=="sample-pipeline-6")]}{@.metadata.name}{"\n"}'
oc cancel-build $(oc get build -o jsonpath='{range .items[?(@.metadata.name=="sample-pipeline-6")]}{@.metadata.name}{"\n"}')

oc get build -o jsonpath='{range .items[?(@.metadata.name=="nodejs-mongodb-example-8")]}{@.metadata.name}{"\n"}'
oc cancel-build $(oc get build -o jsonpath='{range .items[?(@.metadata.name=="nodejs-mongodb-example-8")]}{@.metadata.name}{"\n"}')

oc start-build --build-loglevel 5 sample-pipeline

# 参考：https://github.com/xiaoping378/blog/blob/master/posts/openshift%E5%AE%9E%E8%B7%B5-DevOps%E5%AE%9E%E6%88%98-1.md
# 设置 NPM_MIRROR 环境变量
oc start-build --build-loglevel 5 nodejs-mongodb-example --env="NPM_MIRROR=https://registry.npm.taobao.org"

# patch buildconfig nodejs-mongodb-example，设置环境变量 NPM_MIRROR 的值
oc -n test1 patch bc/nodejs-mongodb-example --type json -p='[{"op": "add", "path": "/spec/strategy/sourceStrategy/env/0/value", "value":"https://registry.npm.taobao.org"}]'

oc -n test1 get bc/nodejs-mongodb-example -o jsonpath='{.spec.strategy.sourceStrategy.env[0].value}{"\n"}'

oc start-build --build-loglevel 5 sample-pipeline

oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[?(@.metadata.name=="nodejs-mongodb-example-10-build")]}{@.metadata.name}{"\n"}{end}')
```

### 介绍 jsonpath 的网址
https://support.smartbear.com/alertsite/docs/monitors/api/endpoint/jsonpath.html#filters<br>
https://unofficial-kubernetes.readthedocs.io/en/latest/user-guide/jsonpath/<br>
https://medium.com/@imarunrk/certified-kubernetes-administrator-cka-tips-and-tricks-part-4-17407899ef1a


### 介绍 buildah 的网址
https://www.redhat.com/sysadmin/building-buildah

### 登录 nodejs 应用
```
# https://cli.vuejs.org/guide/installation.html
# 想实现安装 vue-cli-service
oc -n test1 rsh $(oc get pods -n test1 -o jsonpath='{ range .items[?(@.metadata.name=="nodejs-mongodb-example-1-z85qm")]}{@.metadata.name}{"\n"}{end}')
sh-4.2$ env | grep NPM
NPM_CONFIG_PREFIX=/opt/app-root/src/.npm-global
NPM_RUN=start
NPM_MIRROR=https://registry.npm.taobao.org

# 安装特定版本
# 参见：https://stackabuse.com/npm-install-specific-version-of-a-package/

sh-4.2$ npm install -g @vue/cli-service

# 安装完后，可执行程序在 .npm_global 下
sh-4.2$ ls -l ./.npm-global/bin/vue-cli-service
lrwxrwxrwx. 1 default root 59 Dec 18 01:48 ./.npm-global/bin/vue-cli-service -> ../lib/node_modules/@vue/cli-service/bin/vue-cli-service.js

# 查看 vue-cli-service 帮助
sh-4.2$ vue-cli-service --help

  Usage: vue-cli-service <command> [options]

  Commands:

    serve     start development server
    build     build for production
    inspect   inspect internal webpack config

  run vue-cli-service help [command] for usage of a specific command.


```


### 如何部署 VueJS 到 OpenShift 上
https://www.openshift.com/blog/deploy-vuejs-applications-on-openshift


### Writing Jenkins Pipeline For OpenShift Deployment
https://ruddra.com/openshift-python-jenkins-pipeline-one/<br>
https://ruddra.com/openshift-python-jenkins-pipeline-two/


### OpenShift 的 Service Account
https://docs.openshift.com/container-platform/3.6/dev_guide/service_accounts.html

每个 namespace/project 下都有 3 个默认的 service account

| Servicde Account | Usage |
|---|---|
| builder | Used by build pods. It is given the system:image-builder role, which allows pushing images to any image stream in the project using the internal Docker registry. |
| deployer | Used by deployment pods and is given the system:deployer role, which allows viewing and modifying replication controllers and pods in the project. |
| default | Used to run all other pods unless they specify a different service account. |

### kubectl cheat sheet
https://kapeli.com/cheat_sheets/Kubernetes.docset/Contents/Resources/Documents/index
```
# 查看节点的 status
kubectl get nodes -o jsonpath='{range .items[*]}{@.metadata.name}:{"\n"}{range @.status.conditions[*]}{"\t"}{@.type}={@.status}{"\n"}{end}{end}'
master0.cluster-0001.rhsacn.org:
        MemoryPressure=False
        DiskPressure=False
        PIDPressure=False
        Ready=True
...

# 查看节点的 ExternalIP
kubectl get nodes -o jsonpath='{range .items[*]}{@.metadata.name}: {@.status.addresses[?(@.type=="ExternalIP")].address}{"\n"}{end}'

# 查看节点的 InternalIP
kubectl get nodes -o jsonpath='{range .items[*]}{@.metadata.name}: {@.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'


# "jq" command useful for transformations that are too complex for jsonpath
rc_name="nodejs-mongodb-example-1"
sel=$(kubectl get rc ${rc_name} --output=json | jq -j '.spec.selector | to_entries | .[] | "\(.key)=\(.value),"')
sel=${sel%?} # Remove trailing comma
# 参见：https://bytefreaks.net/gnulinux/bash/how-to-remove-prefix-and-suffix-from-a-variable-in-bash
pods=$(kubectl get pods --selector=$sel --output=jsonpath={.items..metadata.name})
```

### 设置 npm registry ; 安装 npm 软件包 ； 升级 node
https://stackoverflow.com/questions/8191459/how-do-i-update-node-js
```
oc project default
oc delete project test-nodejs --wait=true --timeout=5m
oc create namespace test-nodejs

oc project test-nodejs

# 创建 build secret 和 build
oc create secret generic git-auth-1 --from-file=ssh-privatekey=/Users/junwang/.ssh/wjqhd_github_sshkey --type=kubernetes.io/ssh-auth
oc new-build nodejs~ssh://git@github.com/wangjun1974/hello-world-nodejs.git --name=ssh-4-nodejs-build --source-secret='git-auth-1'

# 基于 build image 运行容器
oc run --image="$(oc get is ssh-4-nodejs-build -o jsonpath='{.status.tags[0].items[0].dockerImageReference}')" test

# rsh pod test
oc rsh $(oc get pods -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep test)

# 设置 registry，安装 npm
npm set registry https://registry.npm.taobao.org

# 检查 nodejs 版本
node --version

# 安装高版本 node
npm install -g npm stable
npm install -g node
> node@15.4.0 preinstall /opt/app-root/src/.npm-global/lib/node_modules/node
> node installArchSpecificPackage
+ node-linux-x64@15.4.0
added 1 package in 15.913s

/opt/app-root/src/.npm-global/bin/node -> /opt/app-root/src/.npm-global/lib/node_modules/node/bin/node
+ node@15.4.0
added 2 packages from 1 contributor in 18.948s

# 检查 nodejs 版本
sh-4.4$ node --version 
v12.18.4

sh-4.4$ /opt/app-root/src/.npm-global/bin/node --version 
v15.4.0
```

### 使用 nodeshift 部署 nodejs 应用到 OpenShift
https://developers.redhat.com/blog/2019/08/30/easily-deploy-node-js-applications-to-red-hat-openshift-using-nodeshift/

### troubleshooting pod Back-off restarting failed container
https://managedkube.com/kubernetes/pod/failure/crashloopbackoff/k8sbot/troubleshooting/2019/02/12/pod-failure-crashloopbackoff.html


### 查询 ImageContentSourcePolicy 以及 source 和 mirrors 的关系
```
oc get ImageContentSourcePolicy -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range @.spec.repositoryDigestMirrors[*]}{"\t"}Source: {@.source}{"\n"}{"\t"}Mirror: {@.mirrors}{"\n"}{end}{end}'
```

### 检查是否能获取 jenkins 相关 imagestream 的镜像
```
# imagestream jenkins 的镜像 
oc -n openshift get is jenkins -o jsonpath='{.spec.tags[0].from.name}{"\n"}'

# 检查是否能获 jenkins 镜像
podman pull --authfile=/root/pull-secret-2.json $(oc -n openshift get is jenkins -o jsonpath='{.spec.tags[0].from.name}{"\n"}')

# imagestream jenkins-agent-base 的镜像
oc -n openshift get is jenkins-agent-base -o jsonpath='{.spec.tags[0].from.name}{"\n"}'

# 检查是否能获 jenkins-agent-base 镜像
podman pull --authfile=/root/pull-secret-2.json $(oc -n openshift get is jenkins-agent-base -o jsonpath='{.spec.tags[0].from.name}{"\n"}')

# imagestream jenkins-agent-maven 的镜像
oc -n openshift get is jenkins-agent-maven -o jsonpath='{.spec.tags[1].from.name}{"\n"}'

# 检查是否能获 jenkins-agent-maven 镜像
podman pull --authfile=/root/pull-secret-2.json $(oc -n openshift get is jenkins-agent-maven -o jsonpath='{.spec.tags[1].from.name}{"\n"}')

# imagestream jenkins-agent-nodejs 的镜像
oc -n openshift get is jenkins-agent-nodejs -o jsonpath='{.spec.tags[1].from.name}{"\n"}'

# 检查是否能获 jenkins-agent-nodejs 镜像
podman pull --authfile=/root/pull-secret-2.json $(oc -n openshift get is jenkins-agent-nodejs -o jsonpath='{.spec.tags[1].from.name}{"\n"}')
```

### 设置 Jenkins agent pod retention
https://docs.okd.io/latest/openshift_images/using_images/images-other-jenkins-agent.html 

Jenkins agent pods (slave pod) 在构建完成或停止后默认情况下会被删除。 可以通过 Kubernetes 插件 Pod Retention 设置更改此行为。 可以为所有Jenkins版本设置 Pod 保留，并为每个 Pod 模板覆盖。 

支持以下行为：
* **always** keeps the build pod regardless of build result.
* **default** uses the plug-in value (pod template only).
* **never** always deletes the pod.
* **onFailure** keeps the pod if it fails during the build.

```
podTemplate(label: "mypod",
  cloud: "openshift",
  inheritFrom: "maven",
  podRetention: onFailure(), 
  containers: [
    ...
  ]) {
  node("mypod") {
    ...
  }
}
```

Allowed values for podRetention are never(), onFailure(), always(), and default().


### OKD Jenkins example pipeline - pipeline/samplepipeline
https://github.com/openshift/origin/tree/master/examples/jenkins/pipeline

```
oc project default
oc create namespace test1
oc project test1 

oc new-app jenkins-ephemeral

oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{@.metadata.name}{"\n"}{end}'| grep -v deploy)

oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml

oc new-app --template=jenkins-pipeline-example

oc get dc/mongodb -o jsonpath='{ .spec.triggers[0].imageChangeParams.from.name}{"\n"}'
oc patch dc/mongodb --type json -p='[{"op": "replace", "path": "/spec/triggers/0/imageChangeParams/from/name", "value":"mongodb:3.6"}]'
oc get dc/mongodb -o jsonpath='{ .spec.triggers[0].imageChangeParams.from.name}{"\n"}'

# 测试使用环境变量 NPM_MIRROR 可顺利完成 build nodejs-mongodb-example
oc start-build --build-loglevel 5 nodejs-mongodb-example --env="NPM_MIRROR=https://registry.npm.taobao.org"

# patch bc/nodejs-mongodb-example
oc -n test1 patch bc/nodejs-mongodb-example --type json -p='[{"op": "add", "path": "/spec/strategy/sourceStrategy/env/0/value", "value":"https://registry.npm.taobao.org"}]'

# 检查 patch 结果
oc -n test1 get bc/nodejs-mongodb-example -o jsonpath='{.spec.strategy.sourceStrategy.env[0]}{"\n"}'

# 执行 pipeline
oc start-build --build-loglevel 5 sample-pipeline

# 查看日志
oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[?(@.metadata.name == "nodejs-mongodb-example-3-build")]}{@.metadata.name}{"\n"}{end}')

# 查看日志
oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[?(@.metadata.name == "nodejs-mongodb-example-1-cwzt4")]}{@.metadata.name}{"\n"}{end}')

```

### OKD Jenkins example pipeline - pipeline/nodejs-sample-pipeline
https://github.com/openshift/origin/blob/master/examples/jenkins/pipeline/nodejs-sample-pipeline.yaml
```
oc project default
oc delete namespace test1 --wait=true --timeout=5m 
oc get project test1 

oc create namespace test1 
oc project test1

oc new-app jenkins-ephemeral

# 查看 jenkins 容器日志
oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{@.metadata.name}{"\n"}{end}'| grep -v deploy)
# 等待日志里出现类似如下的日志内容
# 2020-12-21 06:34:03 INFO    io.fabric8.jenkins.openshiftsync.BuildWatcher reconcileRunsAndBuilds Reconciling job runs and builds

# 访问网址
oc get route jenkins -o jsonpath='{.spec.host}{"\n"}' 
jenkins-test1.apps.cluster-0001.rhsacn.org

oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/nodejs-sample-pipeline.yaml

# 每次 buildconfig 都会重新生成
# 每次 buildconfig 都会把 NPM_MIRROR 环境变量清除掉

# 我想到的办法是给 template 提供默认参数
oc get templates nodejs-mongodb-example -n openshift -o jsonpath={.parameters[17].name}
NPM_MIRROR
# 默认没有 NPM_MIRROR 参数的默认值
oc get templates nodejs-mongodb-example -n openshift -o jsonpath={.parameters[17].value}

# 设置 NPM_MIRROR 参数的默认值
oc -n openshift patch templates nodejs-mongodb-example -n openshift --type json -p '[{"op": "add", "path": "/parameters/17/value", "value": "https://registry.npm.taobao.org"}]'

# 检查设置结果
oc get templates nodejs-mongodb-example -n openshift -o jsonpath={.parameters[17].value}

oc start-build --build-loglevel 5  nodejs-sample-pipeline 
oc get builds

# 查看 nodejs agent 容器日志
oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{@.metadata.name}{"\n"}{end}'| grep nodejs | grep -v build | tail -1)

# 查看 nodejs builder 容器日志
oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{@.metadata.name}{"\n"}{end}'| grep -E nodejs | grep -E build | tail -1)
```

### OKD Jenkins example pipeline - pipeline/openshift-client-plugin-pipeline
https://github.com/openshift/origin/blob/master/examples/jenkins/pipeline/openshift-client-plugin-pipeline.yaml

```
oc project default
oc delete project test1 --wait=true --timeout=5m
oc get project test1 

oc create namespace test1
oc project test1

oc new-app jenkins-ephemeral

# 查看 jenkins 容器日志
oc -n test1 logs $(oc get pods -n test1 -o jsonpath='{ range .items[*]}{@.metadata.name}{"\n"}{end}'| grep -v deploy)
# 等待日志里出现类似如下的日志内容
# 2020-12-21 06:34:03 INFO    io.fabric8.jenkins.openshiftsync.BuildWatcher reconcileRunsAndBuilds Reconciling job runs and builds

# 访问网址
oc get route jenkins -o jsonpath='{.spec.host}{"\n"}' 
jenkins-test1.apps.cluster-0001.rhsacn.org

oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/openshift-client-plugin-pipeline.yaml
buildconfig.build.openshift.io/sample-pipeline-openshift-client-plugin created

# start build 
oc start-build sample-pipeline-openshift-client-plugin 

# 过了一段时间，在 jenkins 上可以看到如下报错
# [Pipeline] End of Pipeline
# ERROR: new-build returned an error;
# {err=error: can't lookup images: Timeout: request did not complete within requested timeout 34s
# error: unable to locate any images in image streams, local docker images with name "centos/ ruby-25-centos7"

# 首先拷贝缺少的 image stream 所需要的镜像到本地 registry
...

# 创建 image-stream
# 参考: https://dzone.com/articles/pulling-images-from-external-container-registry-to
oc -n openshift import-image centos/ruby-25-centos7:latest --from=helper.cluster-0001.rhsacn.org:5000/centos/ruby-25-centos7:latest --confirm --scheduled=true

# 出错的 pipeline 步骤是
# catch (Throwable t) {
#                        // The selector returned from newBuild will select all objects created by the operation
#                        nb = openshift.newBuild( "https://github.com/openshift/ruby-hello-world", "--name=ruby" )
# 内网把 docker.io 给屏蔽了

```



### 报错 "StaticPodsDegraded: pod/openshift-kube-scheduler-master1.cluster-0001.rhsacn.org container \"kube-scheduler\" is not ready" 的处理 
```
Status for clusteroperator/kube-scheduler changed: Degraded message changed from "NodeControllerDegraded: All master nodes are ready" to "StaticPodsDegraded: pod/openshift-kube-scheduler-master1.cluster-0001.rhsacn.org container \"kube-scheduler\" is not ready: unknown reason\nStaticPodsDegraded: pod/openshift-kube-scheduler-master1.cluster-0001.rhsacn.org container \"kube-scheduler\" is terminated: Error: n.org:6443/api/v1/namespaces/openshift-kube-scheduler/configmaps/kube-scheduler?timeout=10s\": context deadline exceeded (Client.Timeout exceeded while awaiting headers)\nStaticPodsDegraded: I1221 06:29:25.035214 1 leaderelection.go:253] successfully acquired lease openshift-kube-scheduler/kube-scheduler\nStaticPodsDegraded: I1221 06:33:25.004866 1 scheduler.go:597] \"Successfully bound pod to node\" pod=\"test1/jenkins-1-deploy\" node=\"worker0.cluster-0001.rhsacn.org\" evaluatedNodes=6 feasibleNodes=3\nStaticPodsDegraded: I1221 06:33:27.860340 1 scheduler.go:597] \"Successfully bound pod to node\" pod=\"test1/jenkins-1-r9jc4\" node=\"worker2.cluster-0001.rhsacn.org\" evaluatedNodes=6 feasibleNodes=3\nStaticPodsDegraded: I1221 06:39:11.192808 1 scheduler.go:597] \"Successfully bound pod to node\" pod=\"test1/nodejs-gwsfz\" node=\"worker0.cluster-0001.rhsacn.org\" evaluatedNodes=6 feasibleNodes=3\nStaticPodsDegraded: I1221 06:39:30.311049 1 scheduler.go:597] \"Successfully bound pod to node\" pod=\"test1/nodejs-mongodb-example-1-build\" node=\"worker0.cluster-0001.rhsacn.org\" evaluatedNodes=6 feasibleNodes=3\nStaticPodsDegraded: I1221 06:39:31.105030 1 scheduler.go:597] \"Successfully bound pod to node\" pod=\"test1/mongodb-1-deploy\" node=\"worker0.cluster-0001.rhsacn.org\" evaluatedNodes=6 feasibleNodes=3\nStaticPodsDegraded: I1221 06:39:33.986806 1 scheduler.go:597] \"Successfully bound pod to node\" pod=\"test1/mongodb-1-jdvzp\" node=\"worker0.cluster-0001.rhsacn.org\" evaluatedNodes=6 feasibleNodes=3\nStaticPodsDegraded: E1221 06:42:35.322288 1 leaderelection.go:321] error retrieving resource lock openshift-kube-scheduler/kube-scheduler: Get \"https://api-int.cluster-0001.rhsacn.org:6443/api/v1/namespaces/openshift-kube-scheduler/configmaps/kube-scheduler?timeout=10s\": context deadline exceeded (Client.Timeout exceeded while awaiting headers)\nStaticPodsDegraded: I1221 06:42:35.322346 1 leaderelection.go:278] failed to renew lease openshift-kube-scheduler/kube-scheduler: timed out waiting for the condition\nStaticPodsDegraded: E1221 06:42:35.322404 1 leaderelection.go:297] Failed to release lock: resource name may not be empty\nStaticPodsDegraded: F1221 06:42:35.322412 1 server.go:211] leaderelection lost\nStaticPodsDegraded: \nNodeControllerDegraded: All master nodes are ready"


oc -n openshift-kube-scheduler-operator get pods
NAME                                                 READY   STATUS    RESTARTS   AGE
openshift-kube-scheduler-operator-77796f7649-g7n5x   1/1     Running   68         18d

# 从 operator 的日志可以看到相关报错
oc -n openshift-kube-scheduler-operator logs $( oc -n openshift-kube-scheduler-operator get pods -o jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep operator )

oc get templates nodejs-mongodb-example -n openshift -o jsonpath={.parameters[17].name}


```


### jenkins openshift.newApp 传递参数的例子
https://github.com/openshift/jenkins-client-plugin/issues/342
```
# 以下的例子说明了如何在 jenkins pipeline 里执行 newApp 并且传递参数
echo "No proevious BuildConfig. Creating new BuildConfig."
def myNewApp = openshift.newApp(
        "${GIT_REPO}#${BRANCH}",
        "--name=${IMAGE}",
        "--context-dir=.",
        "--source-secret=gitlab",
        "-e BUILD_NUMBER=${BUILD_NUMBER}",
        "-e BUILD_ENV=${openshift.project()}",
        "-e PROFILE=stage",
        "-e SPRING_PROFILES_ACTIVE=stage",
        "-e BUILD_ENV=${openshift.project()}"
)
echo "new-app myNewApp ${myNewApp.count()} objects named: ${myNewApp.names()}"
```


### Google Doc 快捷键查询
https://support.google.com/docs/answer/179738?co=GENIE.Platform%3DDesktop&hl=en
```
# Page Up on Mac is Fn + Up Arrow 
```


### OpenShift drain 或者 evacuate 节点进行后续维护
https://medium.com/techbeatly/openshift-cluster-how-to-drain-or-evacuate-a-node-for-maintenance-e9bf051e4a4e<br>
https://docs.openshift.com/container-platform/4.1/nodes/nodes/nodes-nodes-working.html<br>
```
# 在 OCP 4.x 上的步骤
# 1. 设置节点不再接受新的调度
oc adm cordon worker2.cluster-0001.rhsacn.org

# 2. 排空节点
# 直接执行以下命令会报错
oc adm drain worker2.cluster-0001.rhsacn.org 
node/worker2.cluster-0001.rhsacn.org already cordoned
error: unable to drain node "worker2.cluster-0001.rhsacn.org", aborting command...

There are pending nodes to be drained:
 worker2.cluster-0001.rhsacn.org
cannot delete Pods with local storage (use --delete-local-data to override): openshift-marketplace/5fdfbb80a6f6d1ea7892828aae864e347bb026b3f943b1ad6e40dbf278dwqbd, openshift-monitoring/alertmanager-main-2, openshift-monitoring/grafana-6c6696ff85-xpf6r, openshift-monitoring/kube-state-metrics-6ccbdf475f-mqzhd, openshift-monitoring/prometheus-adapter-9bbb4ff66-485cm, test1/jenkins-1-2j2mt
cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): openshift-cluster-node-tuning-operator/tuned-4s8vg, openshift-dns/dns-default-vwh78, openshift-image-registry/node-ca-jql55, openshift-local-storage/diskmaker-discovery-2h7fc, openshift-machine-config-operator/machine-config-daemon-2rvd8, openshift-monitoring/node-exporter-ld2gp, openshift-multus/multus-sj949, openshift-multus/network-metrics-daemon-hzxjk, openshift-sdn/ovs-ct7g7, openshift-sdn/sdn-sjssn

# 这时根据提示执行
oc adm drain worker2.cluster-0001.rhsacn.org --delete-local-data --ignore-daemonsets
# 或者
oc adm drain worker2.cluster-0001.rhsacn.org --delete-local-data --ignore-daemonsets --force

# 执行完之后，节点上还有少量 daemonset pod 在运行
oc get pods --all-namespaces -o wide | grep worker2 
openshift-cluster-node-tuning-operator             tuned-4s8vg                                                       1/1     Running             0          8d      10.66.208.145   worker2.cluster-0001.rhsacn.org   <none>           <none>
openshift-dns                                      dns-default-vwh78                                                 3/3     Running             0          8d      10.254.3.4      worker2.cluster-0001.rhsacn.org   <none>           <none>
openshift-image-registry                           node-ca-jql55                                                     1/1     Running             0          8d      10.66.208.145   worker2.cluster-0001.rhsacn.org   <none>           <none>
openshift-local-storage                            diskmaker-discovery-2h7fc                                         1/1     Running             0          8d      10.254.3.2      worker2.cluster-0001.rhsacn.org   <none>           <none>
openshift-machine-config-operator                  machine-config-daemon-2rvd8                                       2/2     Running             0          8d      10.66.208.145   worker2.cluster-0001.rhsacn.org   <none>           <none>
openshift-monitoring                               node-exporter-ld2gp                                               2/2     Running             0          8d      10.66.208.145   worker2.cluster-0001.rhsacn.org   <none>           <none>
openshift-multus                                   multus-sj949                                                      1/1     Running             0          8d      10.66.208.145   worker2.cluster-0001.rhsacn.org   <none>           <none>
openshift-multus                                   network-metrics-daemon-hzxjk                                      2/2     Running             0          8d      10.254.3.3      worker2.cluster-0001.rhsacn.org   <none>           <none>
openshift-sdn                                      ovs-ct7g7                                                         1/1     Running             0          8d      10.66.208.145   worker2.cluster-0001.rhsacn.org   <none>           <none>
openshift-sdn                                      sdn-sjssn                                                         2/2     Running             1          8d      10.66.208.145   worker2.cluster-0001.rhsacn.org   <none>           <none>

# 3. 此时执行相关维护工作

# 4. 重启节点或者维护工作结束后
# 重新设置节点可被调度
oc adm uncordon worker2.cluster-0001.rhsacn.org
```



### 生成可以与 velero 一起工作的 pod 的 python 脚本
这个脚本来自 Andrew Block
```
#!/usr/bin/env python

import argparse
import json
import requests
import sys

parser = argparse.ArgumentParser(description='Backup Pod Creation Script.')
parser.add_argument("-t", "--token",
                    help="OpenShift Token", required=True)
parser.add_argument("-a", "--api", help="OpenShift API", required=True)
parser.add_argument("-lk", "--label-key", help="Label Key", required=True)
parser.add_argument("-lv", "--label-value", help="Label value", required=True)
parser.add_argument("-n", "--namespace", help="Namespace", required=True)
parser.add_argument("-p", "--pod_name", help="Pod Name", default="pv-backup")
args = parser.parse_args()

namespace = args.namespace
token = args.token
api = args.api
label_key = args.label_key
label_value = args.label_value
pod_name = args.pod_name


session = requests.Session()
session.verify = False
session.headers = {
    'Accept': 'application/json',
    'Authorization': 'Bearer {0}'.format(token),
}

namespace_pvc = session.get(
    "{0}/api/v1/namespaces/{1}/persistentvolumeclaims?labelSelector={2}%3D{3}".format(api, namespace, label_key, label_value))
namespace_pvc.raise_for_status()

if namespace_pvc.status_code != 200:
    print("Failed to query OpenShift API. Status code: {0}".format(
        namespace_pvc.status_code))
    sys.exit(1)

result_json = namespace_pvc.json()

pvc_names = [str(pvc['metadata']['name']) for pvc in result_json['items']]

pod = {
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
        "name": pod_name,
        "namespace": namespace,
        "annotations": {
            "backup.velero.io/backup-volumes": ",".join(pvc_names)
        },
        "labels": {
            label_key: label_value
        }
    },
    "spec": {
        "containers": [
            {
                "command": [
                    "/bin/bash",
                    "-c",
                    "while true; do sleep 10; done"
                ],
                "image": "registry.redhat.io/ubi7/ubi:latest",
                "imagePullPolicy": "IfNotPresent",
                "name": pod_name,
                "resources": {
                    "requests": {
                        "cpu": "200m",
                        "memory": "256Mi"
                    },
                    "limits": {
                        "cpu": "500m",
                        "memory": "512Mi"
                    }
                },
                "volumeMounts": []
            }
        ],
        "volumes": [],
        "restartPolicy": "Always"
    }
}

for pvc_name in pvc_names:
    pod['spec']['containers'][0]['volumeMounts'].append(
        {"name": pvc_name, "mountPath": "/tmp/{0}".format(pvc_name)})

    pod['spec']['volumes'].append(
        {"name": pvc_name, "persistentVolumeClaim": {"claimName": pvc_name}})

pod_create = session.post(
    url="{0}/api/v1/namespaces/{1}/pods".format(api, namespace), json=pod)

if pod_create.status_code != 201:
    print("Error Creating Pod. Status code: {0}".format(
        pod_create.status_code))
    sys.exit(1)

print("Pod Created. Name: {0}. Number of Volumes: {1}".format(
    pod_name, len(pvc_names)))
```


### 查询节点的 labels
```
oc get nodes -o jsonpath='{range .items[*]}{@.metadata.name}{"\n\t"}{@.metadata.labels}{"\n"}{end}'
```


### 查询反复重启的 Pods
```
# 一些 pod 有反复重启的记录
oc get pods -A |awk  '$5 != "0" {print $0}' 
```


### 为用户添加 cluster-admin 权限
https://infohub.delltechnologies.com/l/deployment-guide-red-hat-openshift-container-platform-4-2/assigning-a-cluster-admin-role-to-the-ad-user-5
```
oc adm policy add-cluster-role-to-user cluster-admin admin

oc get clusterrolebindings -o json | jq '.items[] | select(.subjects[0].name=="admin")' | jq '.roleRef.name'
"admin"
"cluster-admin"
"cluster-admins"
"system:cluster-admin"
"system:cluster-admins"

oc adm policy remove-cluster-role-from-user admin admin
oc adm policy remove-cluster-role-from-user cluster-admins admin
oc adm policy remove-cluster-role-from-user system:cluster-admin admin
oc adm policy remove-cluster-role-from-user system:cluster-admins admin
```

正确的步骤可以参考以下链接
https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.5/html-single/managing_openshift_container_storage/index#allowing-user-access-to-the-multicloud-object-gateway-console_rhocs
```
# 创建 cluster-admins 组
oc adm groups new cluster-admins

# 将组 cluster-admins 与角色 cluster-admin 绑定
oc adm policy add-cluster-role-to-group cluster-admin cluster-admins

# 添加用户到组 cluster-admins
oc adm groups add-users cluster-admins <user-name> <user-name> <user-name>...
```


### 关于 imagestream 和 deployment 的博客文章
https://developers.redhat.com/blog/2019/09/20/using-red-hat-openshift-image-streams-with-kubernetes-deployments/



### 10 步构建标准运维环境
10 Steps to Build an SOE: How Red Hat Satellite 6 Supports Setting up a Standard Operating Environment<br>
https://access.redhat.com/articles/1585273<br>

```
Step 1: Set Up Your System Management Infrastructure
Step 2: Map Your Location and Datacenter Topology
Step 3: Define your Definitive Media Library Content
Step 4: Define Your Content Lifecycle
Step 5: Define Your Core Build. Define your OS-deployment (core build) configuration and its corresponding content items
Step 6: Define Your Application Content
Step 7: Automate Your Provisioning
Step 8: Map Your IT Organization and Roles to Your Satellite 6 Setup
Step 9: Manage the Content Lifecycle Continuously
Step 10: Automate and Extend Your Setup
```


### jq 的 Tutorial
https://stedolan.github.io/jq/tutorial/<br>
https://www.softwaretestinghelp.com/github-rest-api-tutorial/<br>
https://stedolan.github.io/jq/manual/<br>
```
# 利用这篇文章介绍的技巧查询 openshift origin 仓库

# commit 信息
curl 'https://api.github.com/repos/openshift/origin/commits?per_page=5' | jq '[.[] | {message: .commit.message, name: .commit.committer.name, parents: [.parents[].html_url]}]'

# 获取 branches 信息
curl 'https://api.github.com/repos/openshift/origin/branches'  | jq '.[]'

# 利用 branches 信息里的 sha 来过滤跟 branches 相关的 commits
curl 'https://api.github.com/repos/openshift/origin/commits?sha=d7fdd4e373acc04d60de65c4705ea6d69face59c&per_page=100' | jq '[.[] | {message: .commit.message, name: .commit.committer.name}]'

curl https://access.redhat.com/sites/default/files/cdn_redhat_com_cac.json | jq '.[]'

# 利用 jq 查询 red hat cdn 地址
curl https://access.redhat.com/sites/default/files/cdn_redhat_com_cac.json | jq '{ip_prefix: .cidr_list[].ip_prefix, service: .cidr_list[].service}'

# 利用 jq 查询 red hat cdn 地址，过滤条件为 service=="RH CDN"
curl https://access.redhat.com/sites/default/files/cdn_redhat_com_cac.json | jq '.cidr_list[] | select(.service=="RH CDN")|.ip_prefix'

# 获取 redhat cdn 的 python script 
cat > get_redhat_cd_ip.py << 'EOF'
#!/usr/bin/python

import urllib2
import json

hdr = {'User-Agent':'Mozilla/5.0'}
url = "https://access.redhat.com/sites/default/files/cdn_redhat_com_cac.json"
request = urllib2.Request(url,headers=hdr)
result = urllib2.urlopen(request)
ip_list = json.load(result)
for ip in ip_list['cidr_list']:
  print ip['ip_prefix']
EOF

# 另外一个 python 脚本
# https://github.com/TheRedGreek/satellite-support/blob/check-ip/check-cdn-ips.py

cat > check-cdn-ips.py << 'EOF'
#!/bin/python

import socket
import argparse
import sys
import re
try:
    import requests
except ImportError:
    print('Please install the python-requests module.')
    sys.exit(-1)

output = ([],[])

def get_json(url):
    # Performs a GET using the passed URL location
  try:
    r = requests.get(url, timeout=15, verify=args.verify)
    r = r.json()
    ip_list = []
    for x in r['cidr_list']:
        ip = re.search('\d+.\d+.\d+.\d+', x['ip_prefix'])
        ip_list.append(ip.group())
  except ValueError:
    print  ("Json was not returned. Not Good!")
    sys.exit()
  return ip_list

def target_path(path):
    print(path)
    ip_list = []
    ip = open(path)
    try:
        for x in ip:
            x = re.search('\d+.\d+.\d+.\d+', x)
            ip_list.append(x.group())
    finally:
        ip.close()
    return ip_list

def scan(target):
    print('\n' + ' Starting Scan For ' + str(target))
    scan_ip(target, args.port, args.timeout)

def scan_ip(ipaddress, port, timeout):
    socket.setdefaulttimeout(timeout)
    try:
        sock = socket.socket()
        sock.connect((ipaddress, port))
        print("[ + ] Access " + str(ipaddress))
        output[0].append(str(ipaddress))
        sock.close()
    except:
        print("[ - ] Denied " + str(ipaddress))
        output[1].append(str(ipaddress))
        pass

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='PROG')
    parser.add_argument("--verify", default=False, help="Ignore untrusted CA")
    parser.add_argument("--timeout", type=int, default=1, help="Port timeout")
    parser.add_argument("--port", type=int, default=443, help="What port to scan against")
    parser.add_argument("--api", default="https://access.redhat.com/sites/default/files/cdn_redhat_com_cac.json", help="URL for API Call. Default is https://access.redhat.com/sites/default/files/cdn_redhat_com_cac.json")
    parser.add_argument("--path", default=None, help="Use file, if API is blocked. Use full path to file.")
    args = parser.parse_args()
 
    if args.path is not None:
        targets = target_path(args.path)
        for x in targets:
            if x != '':
                scan(x)
        print ('----------Access----------')
        print (output[0])
        print ('----------Denied----------')
        print (output[1])
    else:
        print (args.api)
        targets = get_json(args.api)
        for x in targets:
            if x != '':
                scan(x)
        print ('----------Access----------')
        print (output[0])
        print ('----------Denied----------')
        print (output[1])
EOF
```


### 如何通过 cloudinit 添加静态路由
https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v2.html#common-properties-for-all-device-types 
```
# cloudinit add static route
routes:
 - to: 0.0.0.0/0
   via: 10.23.2.1
   metric: 3
```


### 通过 configmaps 为 kubevirt 虚拟机提供 sysprep 配置文件
https://github.com/kubevirt/kubevirt/issues/2902#issuecomment-564623562
```
# 创建 configmap sysprep-config
apiVersion: v1
kind: ConfigMap
metadata:
  name: sysprep-config
data:
  Unattended.xml: |
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend"
    [...]
    </unattend>
  Autounattended.xml: |
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend"
    [...]
    </unattend>

# 将 configmap sysprep-config 作为 cdrom 添加给 virtualmachineinstance
metadata:
  name: testvmi-sysprep
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 10G
    devices:
      disks:
      - name: sysprep
        cdrom:
          bus: sata
      - name: mypvcdisk
        disk:
          bus: sata
  volumes:
    - name: mypvcdisk
      persistentVolumeClaim:
        claimName: windows-image
    - name: sysprep
      configmap:
        name: sysprep-config 
```


### OpenShift Virtualization 检查 virtualmachine.kubevirt.io 的信息
```
oc get customresourcedefinitions virtualmachines.kubevirt.io -o yaml
```

### 看看 openshift 集群最近有哪些 events 
```
# 查询 event message
oc get events -A -o jsonpath='{range .items[*]}{@.message}{"\n"}{end}'

# 查询 event creationTimestamp, lastTimestamp 和 message
oc get events -A -o jsonpath='{range .items[*]}message: {@.message}{"\n"}createTimestamp: {@.metadata.creationTimestamp}{"\n"}lastTimestamp: {@.lastTimestamp}{"\n"}{"\n"}{end}'
```


### OpenShift 4.6.x 与 ignition version 3.1.0
```
# 获取 openshift-machine-api secret worker-user-data
oc extract -n openshift-machine-api secret/worker-user-data --keys=userData --to=-

# 对于我的测试环境来说应该执行以下命令
# 获得 ignition version 2.2.0 版本的配置 
# curl -s -k https://api-int.cluster-0001.rhcnsa.org:22623/config/worker -H 'Accept: application/vnd.coreos.ignition+json;version=2.2.0, */*;q=0.1' | jq  | head -20

# 获得 ignition version 3.1.0 版本的配置 
# curl -s -k https://api-int.cluster-0001.rhcnsa.org:22623/config/worker -H 'Accept: application/vnd.coreos.ignition+json;version=3.1.0, */*;q=0.1' | jq  | head -20


$ curl -s -k https://api-int.ocp.luji.io:22623/config/worker -H 'Accept: application/vnd.coreos.ignition+json;version=3.1.0, */*;q=0.1' | jq | head -20
{
  "ignition": {
    "config": {
      "replace": {
        "verification": {}
      }
    },
    "proxy": {},
    "security": {
      "tls": {}
    },
    "timeouts": {},
    "version": "3.1.0"
  },
  "passwd": {

# So extract ignition data, encode it to base64, and use it in the vapp properties. Instead of using the original generated worker.ign

# Scott: The OS pivots directly to the cluster version, so if you use 4.1 boot media on a 4.6.9 cluster it will go directly to 4.6.9.

```


### ceph 查看 pool 里的 rados objects
```
# https://docs.ceph.com/en/latest/man/8/rados/#examples
# 查看 pool 里的 rados objects 
rados -p <pool name> ls - 

# ocs add rook toolbox
oc patch OCSInitialization ocsinit -n openshift-storage --type json --patch  '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'

TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
# 通过 rook toolbox 列出 pools
oc rsh -n openshift-storage $TOOLS_POD ceph osd lspools
1 ocs-storagecluster-cephblockpool
2 ocs-storagecluster-cephobjectstore.rgw.control
3 ocs-storagecluster-cephfilesystem-metadata
4 ocs-storagecluster-cephfilesystem-data0
5 ocs-storagecluster-cephobjectstore.rgw.meta
6 ocs-storagecluster-cephobjectstore.rgw.log
7 ocs-storagecluster-cephobjectstore.rgw.buckets.index
8 ocs-storagecluster-cephobjectstore.rgw.buckets.non-ec
9 .rgw.root
10 ocs-storagecluster-cephobjectstore.rgw.buckets.data

# 通过 rook toolbox 查看 pool 里的 rados objects
oc rsh -n openshift-storage $TOOLS_POD rados -p ocs-storagecluster-cephblockpool ls -

# 查看 
oc rsh -n openshift-storage $TOOLS_POD ceph df 
RAW STORAGE:
    CLASS     SIZE        AVAIL       USED        RAW USED     %RAW USED 
    ssd       240 GiB     236 GiB     1.4 GiB      4.4 GiB          1.83 
    TOTAL     240 GiB     236 GiB     1.4 GiB      4.4 GiB          1.83 
 
POOLS:
    POOL                                                      ID     STORED      OBJECTS     USED        %USED     MAX AVAIL 
    ocs-storagecluster-cephblockpool                           1     467 MiB         165     1.4 GiB      0.68        67 GiB 
    ocs-storagecluster-cephobjectstore.rgw.control             2         0 B           8         0 B         0        67 GiB 
    ocs-storagecluster-cephfilesystem-metadata                 3     3.8 KiB          22      96 KiB         0        67 GiB 
    ocs-storagecluster-cephfilesystem-data0                    4         0 B           0         0 B         0        67 GiB 
    ocs-storagecluster-cephobjectstore.rgw.meta                5     1.7 KiB           7      72 KiB         0        67 GiB 
    ocs-storagecluster-cephobjectstore.rgw.log                 6      23 KiB         210     427 KiB         0        67 GiB 
    ocs-storagecluster-cephobjectstore.rgw.buckets.index       7         0 B          11         0 B         0        67 GiB 
    ocs-storagecluster-cephobjectstore.rgw.buckets.non-ec      8         0 B           0         0 B         0        67 GiB 
    .rgw.root                                                  9     4.7 KiB          16     180 KiB         0        67 GiB 
    ocs-storagecluster-cephobjectstore.rgw.buckets.data       10       1 KiB           1      12 KiB         0        67 GiB 
```


### 
```
oc describe pod 5fdfbb80a6f6d1ea7892828aae864e347bb026b3f943b1ad6e40dbf278dqm8s -n openshift-marketplace

...
Events:
  Type     Reason          Age                      From                                      Message
  ----     ------          ----                     ----                                      -------
  Normal   Scheduled       <unknown>                                                          Successfully assigned openshift-marketplace/5fdfbb80a6f6d1ea7892828aae864e347bb026b3f943b1ad6e40dbf278dqm8s to worker1.cluster-0001.rhsacn.org
  Normal   AddedInterface  7d1h                     multus                                    Add eth0 [10.254.5.19/24]
  Normal   Pulled          7d1h                     kubelet, worker1.cluster-0001.rhsacn.org  Container image "quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:3bd85be1e98b6f2a4854471c3dcaefbfa594753380f6db2617c37f7da7e26ec2" already present on machine
  Normal   Created         7d1h                     kubelet, worker1.cluster-0001.rhsacn.org  Created container util
  Normal   Started         7d1h                     kubelet, worker1.cluster-0001.rhsacn.org  Started container util
  Warning  Failed          43h (x1474 over 7d1h)    kubelet, worker1.cluster-0001.rhsacn.org  Error: ErrImagePull
  Warning  Failed          11h (x1842 over 7d1h)    kubelet, worker1.cluster-0001.rhsacn.org  Failed to pull image "registry.redhat.io/rhpam-7/rhpam-operator-bundle@sha256:af5a192a66fd81506cc5361103d7e3d510992f207343f6580a91022dc1bce745": rpc error: code = Unknown desc = unable to retrieve auth token: invalid username/password: unauthorized: Please login to the Red Hat Registry using your Customer Portal credentials. Further instructions can be found here: https://access.redhat.com/RegistryAuthentication
  Normal   Pulling         3h6m (x1943 over 7d1h)   kubelet, worker1.cluster-0001.rhsacn.org  Pulling image "registry.redhat.io/rhpam-7/rhpam-operator-bundle@sha256:af5a192a66fd81506cc5361103d7e3d510992f207343f6580a91022dc1bce745"
  Warning  Failed          111m (x44071 over 7d1h)  kubelet, worker1.cluster-0001.rhsacn.org  Error: ImagePullBackOff
  Normal   BackOff         96m (x44137 over 7d1h)   kubelet, worker1.cluster-0001.rhsacn.org  Back-off pulling image "registry.redhat.io/rhpam-7/rhpam-operator-bundle@sha256:af5a192a66fd81506cc5361103d7e3d510992f207343f6580a91022dc1bce745"
  Normal   AddedInterface  91m                      multus                                    Add eth0 [10.254.5.18/24]
  Normal   Pulled          91m                      kubelet, worker1.cluster-0001.rhsacn.org  Container image "quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:3bd85be1e98b6f2a4854471c3dcaefbfa594753380f6db2617c37f7da7e26ec2" already present on machine
  Normal   Created         90m                      kubelet, worker1.cluster-0001.rhsacn.org  Created container util
  Normal   Started         90m                      kubelet, worker1.cluster-0001.rhsacn.org  Started container util
  Normal   Pulling         89m (x4 over 90m)        kubelet, worker1.cluster-0001.rhsacn.org  Pulling image "registry.redhat.io/rhpam-7/rhpam-operator-bundle@sha256:af5a192a66fd81506cc5361103d7e3d510992f207343f6580a91022dc1bce745"
  Warning  Failed          89m (x4 over 90m)        kubelet, worker1.cluster-0001.rhsacn.org  Failed to pull image "registry.redhat.io/rhpam-7/rhpam-operator-bundle@sha256:af5a192a66fd81506cc5361103d7e3d510992f207343f6580a91022dc1bce745": rpc error: code = Unknown desc = unable to retrieve auth token: invalid username/password: unauthorized: Please login to the Red Hat Registry using your Customer Portal credentials. Further instructions can be found here: https://access.redhat.com/RegistryAuthentication
  Warning  Failed          89m (x4 over 90m)        kubelet, worker1.cluster-0001.rhsacn.org  Error: ErrImagePull
  Normal   BackOff         16m (x327 over 90m)      kubelet, worker1.cluster-0001.rhsacn.org  Back-off pulling image "registry.redhat.io/rhpam-7/rhpam-operator-bundle@sha256:af5a192a66fd81506cc5361103d7e3d510992f207343f6580a91022dc1bce745"
  Warning  Failed          53s (x393 over 90m)      kubelet, worker1.cluster-0001.rhsacn.org  Error: ImagePullBackOff


# 拷贝镜像到本地目录并且打包
rm -rf /root/tmp/mirror/rhpam-7
mkdir -p /root/tmp/mirror/rhpam-7
skopeo copy --authfile /home/ec2-user/pull-secret.json --format v2s2 docker://registry.redhat.io/rhpam-7/rhpam-operator-bundle@sha256:af5a192a66fd81506cc5361103d7e3d510992f207343f6580a91022dc1bce745 dir:///root/tmp/mirror/rhpam-7
tar zcvf /tmp/mirror-rhpam-7.tar.gz /root/tmp/mirror/rhpam-7
chmod a+r /tmp/mirror-rhpam-7.tar.gz

# 拷贝镜像打包并且上传到 OpenShift 对应的本地 registry
skopeo copy --authfile /root/pull-secret-2.json --format v2s2 dir:///root/tmp/mirror/rhpam-7 docker://helper.cluster-0001.rhsacn.org:5000/rhpam-7/rhpam-operator-bundle

# 生成 rhpam7 的 imagecontentsourcepolicy
cat <<EOF > /root/tmp/rhpam-imagecontentsourcepolicy.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: icsp-rhpam-operator-bundle
spec:
  repositoryDigestMirrors:
  - mirrors:
    - helper.cluster-0001.rhsacn.org:5000/rhpam-7/rhpam-operator-bundle
    source: registry.redhat.io/rhpam-7/rhpam-operator-bundle
EOF

# 应用 rhpam7 的 imagecontentsourcepolicy
oc apply -f /root/tmp/rhpam-imagecontentsourcepolicy.yaml

# 确认 rhpam7 的 imagecontentsourcepolicy 已生效
oc get ImageContentSourcePolicy -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range @.spec.repositoryDigestMirrors[*]}{"\t"}Source: {@.source}{"\n"}{"\t"}Mirror: {@.mirrors}{"\n"}{end}{end}' | grep rhpam

oc describe pod business-automation-operator-86c5954d74-bcgk7 -n rhdm-pc-dm-demo
...
Events:
  Type     Reason          Age                    From               Message
  ----     ------          ----                   ----               -------
  Normal   Scheduled       50m                    default-scheduler  Successfully assigned rhdm-pc-dm-demo/business-automation-operator-86c5954d74-bcgk7 to worker0.cluster-0001.rhsacn.org
  Normal   AddedInterface  50m                    multus             Add eth0 [10.254.4.34/24]
  Normal   Pulling         48m (x4 over 50m)      kubelet            Pulling image "registry.redhat.io/rhpam-7/rhpam-rhel8-operator@sha256:c71a818cc9e6a45b6bb59413e2b282c3c30f2415eb506bfed34a8ebba5010288"
  Warning  Failed          48m (x4 over 49m)      kubelet            Failed to pull image "registry.redhat.io/rhpam-7/rhpam-rhel8-operator@sha256:c71a818cc9e6a45b6bb59413e2b282c3c30f2415eb506bfed34a8ebba5010288": rpc error: code = Unknown desc = unable to retrieve auth token: invalid username/password: unauthorized: Please login to the Red Hat Registry using your Customer Portal credentials. Further instructions can be found here: https://access.redhat.com/RegistryAuthentication
  Warning  Failed          48m (x4 over 49m)      kubelet            Error: ErrImagePull
  Warning  Failed          47m (x7 over 49m)      kubelet            Error: ImagePullBackOff
  Normal   BackOff         4m57s (x193 over 49m)  kubelet            Back-off pulling image "registry.redhat.io/rhpam-7/rhpam-rhel8-operator@sha256:c71a818cc9e6a45b6bb59413e2b282c3c30f2415eb506bfed34a8ebba5010288"


# 拷贝镜像到本地目录并且打包 
skopeo copy --authfile /home/ec2-user/pull-secret.json --format v2s2 docker://registry.redhat.io/rhpam-7/rhpam-rhel8-operator@sha256:c71a818cc9e6a45b6bb59413e2b282c3c30f2415eb506bfed34a8ebba5010288 dir:///root/tmp/mirror/rhpam-7
tar zcvf /tmp/mirror-rhpam-7.tar.gz /root/tmp/mirror/rhpam-7
chmod a+r /tmp/mirror-rhpam-7.tar.gz

# 拷贝镜像打包并且上传到 OpenShift 对应的本地 registry
skopeo copy --authfile /root/pull-secret-2.json --format v2s2 dir:///root/tmp/mirror/rhpam-7 docker://helper.cluster-0001.rhsacn.org:5000/rhpam-7/rhpam-rhel8-operator

# 生成 rhpam-rhel8-operator 的 imagecontentsourcepolicy
cat <<EOF > /root/tmp/rhpam-imagecontentsourcepolicy.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: icsp-rhpam-operator-bundle
spec:
  repositoryDigestMirrors:
  - mirrors:
    - helper.cluster-0001.rhsacn.org:5000/rhpam-7/rhpam-operator-bundle
    source: registry.redhat.io/rhpam-7/rhpam-operator-bundle
  - mirrors:
    - helper.cluster-0001.rhsacn.org:5000/rhpam-7/rhpam-rhel8-operator
    source: registry.redhat.io/rhpam-7/rhpam-rhel8-operator
EOF

# 应用 rhpam-rhel8-operator 的 imagecontentsourcepolicy
oc apply -f /root/tmp/rhpam-imagecontentsourcepolicy.yaml

# 确认 rhpam-rhel8-operator 的 imagecontentsourcepolicy 已生效
oc get ImageContentSourcePolicy -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range @.spec.repositoryDigestMirrors[*]}{"\t"}Source: {@.source}{"\n"}{"\t"}Mirror: {@.mirrors}{"\n"}{end}{end}' | grep rhpam-rhel8-operator

# pod console-cr-form 处于 ImagePullBackOff 状态
oc describe pod console-cr-form -n rhdm-pc-dm-demo 
Events:
  Type     Reason                  Age   From               Message
  ----     ------                  ----  ----               -------
  Normal   Scheduled               23m   default-scheduler  Successfully assigned rhdm-pc-dm-demo/console-cr-form to worker1.cluster-0001.rhsacn.org
  Warning  FailedCreatePodSandBox  22m   kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create pod network sandbox k8s_console-cr-form_rhdm-pc-dm-demo_cc18869a-e93b-4532-ad1b-ade3837dba09_0(3fa971f64813b5c90c71a66c69b79bf3556a6741ca9ed732fee969b1ae4e920a): [rhdm-pc-dm-demo/console-cr-form:openshift-sdn]: error adding container to network "openshift-sdn": CNI request failed with status 400: 'Get "https://api-int.cluster-0001.rhsacn.org:6443/api/v1/namespaces/rhdm-pc-dm-demo/pods/console-cr-form": unexpected EOF
'
  Normal   AddedInterface  22m                  multus   Add eth0 [10.254.5.35/24]
  Normal   Pulling         22m                  kubelet  Pulling image "registry.redhat.io/rhpam-7/rhpam-rhel8-operator@sha256:c71a818cc9e6a45b6bb59413e2b282c3c30f2415eb506bfed34a8ebba5010288"
  Normal   Pulled          22m                  kubelet  Successfully pulled image "registry.redhat.io/rhpam-7/rhpam-rhel8-operator@sha256:c71a818cc9e6a45b6bb59413e2b282c3c30f2415eb506bfed34a8ebba5010288" in 47.829602ms
  Normal   Started         22m                  kubelet  Started container console-cr-form
  Normal   Created         22m                  kubelet  Created container console-cr-form
  Normal   Pulling         21m (x3 over 22m)    kubelet  Pulling image "registry.redhat.io/openshift4/ose-oauth-proxy@sha256:e83d591b61b3de88586822b3b85c3158607d19141e054dc43907ba75e9a5cfbc"
  Warning  Failed          21m (x3 over 22m)    kubelet  Failed to pull image "registry.redhat.io/openshift4/ose-oauth-proxy@sha256:e83d591b61b3de88586822b3b85c3158607d19141e054dc43907ba75e9a5cfbc": rpc error: code = Unknown desc = unable to retrieve auth token: invalid username/password: unauthorized: Please login to the Red Hat Registry using your Customer Portal credentials. Further instructions can be found here: https://access.redhat.com/RegistryAuthentication
  Warning  Failed          21m (x3 over 22m)    kubelet  Error: ErrImagePull
  Warning  Failed          13m (x37 over 22m)   kubelet  Error: ImagePullBackOff
  Normal   BackOff         3m5s (x82 over 22m)  kubelet  Back-off pulling image "registry.redhat.io/openshift4/ose-oauth-proxy@sha256:e83d591b61b3de88586822b3b85c3158607d19141e054dc43907ba75e9a5cfbc"

# 拷贝镜像到本地目录并且打包 
skopeo copy --authfile /home/ec2-user/pull-secret.json --format v2s2 docker://registry.redhat.io/openshift4/ose-oauth-proxy@sha256:e83d591b61b3de88586822b3b85c3158607d19141e054dc43907ba75e9a5cfbc dir:///root/tmp/mirror/rhpam-7
tar zcvf /tmp/mirror-rhpam-7.tar.gz /root/tmp/mirror/rhpam-7
chmod a+r /tmp/mirror-rhpam-7.tar.gz

# 拷贝镜像打包并且上传到 OpenShift 对应的本地 registry
skopeo copy --authfile /root/pull-secret-2.json --format v2s2 dir:///root/tmp/mirror/rhpam-7 docker://helper.cluster-0001.rhsacn.org:5000/openshift4/ose-oauth-proxy

# 生成 ose-oauth-proxy 的 imagecontentsourcepolicy
cat <<EOF > /root/tmp/rhpam-imagecontentsourcepolicy.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: icsp-rhpam-operator-bundle
spec:
  repositoryDigestMirrors:
  - mirrors:
    - helper.cluster-0001.rhsacn.org:5000/rhpam-7/rhpam-operator-bundle
    source: registry.redhat.io/rhpam-7/rhpam-operator-bundle
  - mirrors:
    - helper.cluster-0001.rhsacn.org:5000/rhpam-7/rhpam-rhel8-operator
    source: registry.redhat.io/rhpam-7/rhpam-rhel8-operator
  - mirrors:
    - helper.cluster-0001.rhsacn.org:5000/openshift4/ose-oauth-proxy
    source: registry.redhat.io/openshift4/ose-oauth-proxy    
EOF

# 应用 rhpam-rhel8-operator 的 imagecontentsourcepolicy
oc apply -f /root/tmp/rhpam-imagecontentsourcepolicy.yaml

# 确认 ose-oauth-proxy 的 imagecontentsourcepolicy 已生效
oc get ImageContentSourcePolicy -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range @.spec.repositoryDigestMirrors[*]}{"\t"}Source: {@.source}{"\n"}{"\t"}Mirror: {@.mirrors}{"\n"}{end}{end}' | grep ose-oauth-proxy
```



### OpenShift 下 Pod 处于 CrashLoopBackOff 的原因
https://access.redhat.com/solutions/2137701
```
oc logs <pod> -p
```


### 消除 ceph HEALTH_WARN - daemons have recently crashed 告警
```
# ceph status 命令显示曾经发生过 daemons crashed
TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD ceph status
  cluster:
    id:     9d685302-c2e5-40a6-88c8-b2db1389a5f0
    health: HEALTH_WARN
            1 daemons have recently crashed
 
  services:
    mon: 3 daemons, quorum a,b,c (age 3m)
    mgr: a(active, since 59m)
    mds: ocs-storagecluster-cephfilesystem:1 {0=ocs-storagecluster-cephfilesystem-a=up:active} 1 up:standby-replay
    osd: 3 osds: 3 up (since 3m), 3 in (since 7d)
    rgw: 2 daemons active (ocs.storagecluster.cephobjectstore.a, ocs.storagecluster.cephobjectstore.b)
 
  task status:
    scrub status:
        mds.ocs-storagecluster-cephfilesystem-a: idle
        mds.ocs-storagecluster-cephfilesystem-b: idle
 
  data:
    pools:   10 pools, 176 pgs
    objects: 456 objects, 570 MiB
    usage:   4.5 GiB used, 236 GiB / 240 GiB avail
    pgs:     176 active+clean
 
  io:
    client:   853 B/s rd, 15 KiB/s wr, 1 op/s rd, 1 op/s wr

# 执行 ceph crash archive-all 消除告警信息
oc rsh -n openshift-storage $TOOLS_POD ceph crash archive-all

# ceph status 这时将显示状态 HEALTH_OK
oc rsh -n openshift-storage $TOOLS_POD ceph status 
  cluster:
    id:     9d685302-c2e5-40a6-88c8-b2db1389a5f0
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum a,b,c (age 7m)
    mgr: a(active, since 63m)
    mds: ocs-storagecluster-cephfilesystem:1 {0=ocs-storagecluster-cephfilesystem-a=up:active} 1 up:standby-replay
    osd: 3 osds: 3 up (since 8m), 3 in (since 7d)
    rgw: 2 daemons active (ocs.storagecluster.cephobjectstore.a, ocs.storagecluster.cephobjectstore.b)
 
  task status:
    scrub status:
        mds.ocs-storagecluster-cephfilesystem-a: idle
        mds.ocs-storagecluster-cephfilesystem-b: idle
 
  data:
    pools:   10 pools, 176 pgs
    objects: 456 objects, 570 MiB
    usage:   4.5 GiB used, 236 GiB / 240 GiB avail
    pgs:     176 active+clean
 
  io:
    client:   970 B/s rd, 44 KiB/s wr, 1 op/s rd, 3 op/s wr
```



### OCS pods in CrashLoopBackOff 的 日志
```
# pod csi-rbdplugin-privisioner 由容器 csi-provisioner csi-resizer csi-attacher csi-rbdplugin liveness-prometheus 组成
oc -n openshift-storage logs csi-rbdplugin-provisioner-75596f49bd-58q6v -p 
error: a container name must be specified for pod csi-rbdplugin-provisioner-75596f49bd-58q6v, choose one of: [csi-provisioner csi-resizer csi-attacher csi-rbdplugin liveness-prometheus]

# pod csi-cephfsplugin-provisioner 由容器 csi-attacher csi-resizer csi-provisioner csi-cephfsplugin liveness-prometheus 组成
oc -n openshift-storage logs csi-cephfsplugin-provisioner-7b89766c86-wzk2l  -p 
error: a container name must be specified for pod csi-cephfsplugin-provisioner-7b89766c86-wzk2l, choose one of: [csi-attacher csi-resizer csi-provisioner csi-cephfsplugin liveness-prometheus]

# 查看容器 csi-resizer 的日志
# 报错为： Failed to update lock: Operation cannot be fulfilled on leases.coordination.k8s.io
oc -n openshift-storage logs csi-cephfsplugin-provisioner-7b89766c86-wzk2l -c csi-resizer -p 
I1231 01:03:57.937452       1 main.go:68] Version : v4.3.40-202010141211.p0-0-gdfa08ed-dirty
I1231 01:03:57.939621       1 connection.go:153] Connecting to unix:///csi/csi-provisioner.sock
I1231 01:03:57.940738       1 common.go:111] Probing CSI driver for readiness
W1231 01:03:57.947444       1 metrics.go:142] metrics endpoint will not be started because `metrics-address` was not specified.
I1231 01:03:57.951559       1 leaderelection.go:242] attempting to acquire leader lease  openshift-storage/external-resizer-openshift-storage-cephfs-csi-ceph-com...
I1231 01:04:17.408926       1 leaderelection.go:252] successfully acquired lease openshift-storage/external-resizer-openshift-storage-cephfs-csi-ceph-com
I1231 01:04:17.409212       1 controller.go:190] Starting external resizer openshift-storage.cephfs.csi.ceph.com
E1231 01:05:13.981290       1 leaderelection.go:367] Failed to update lock: Operation cannot be fulfilled on leases.coordination.k8s.io "external-resizer-openshift-storage-cephfs-csi-ceph-com": the object has been modified; please apply your changes to the latest version and try again
I1231 01:05:16.524768       1 leaderelection.go:288] failed to renew lease openshift-storage/external-resizer-openshift-storage-cephfs-csi-ceph-com: timed out waiting for the condition
F1231 01:05:16.524803       1 leader_election.go:169] stopped leading
```



### Tmux Cheat Sheet
https://tmuxcheatsheet.com/



### 问题追踪
```
# 检查 etcd 的健康状况
oc get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.message}{"\n"}'
3 members are available

# etcd-master2.cluster-0001.rhsacn.org 容器有重启的现象
oc get pods -n openshift-etcd | grep etcd
etcd-master0.cluster-0001.rhsacn.org                3/3     Running     0          39d
etcd-master1.cluster-0001.rhsacn.org                3/3     Running     0          39d
etcd-master2.cluster-0001.rhsacn.org                3/3     Running     12         39d
etcd-quorum-guard-6446859dbb-98q4s                  1/1     Running     0          4d20h
etcd-quorum-guard-6446859dbb-kv69v                  1/1     Running     0          4d21h
etcd-quorum-guard-6446859dbb-xktkh                  1/1     Running     0          4d20h


646a1e76b9516       203086c2d8868ba6b079af6f4953844254f105f78dead408b1ffd441480d4300   About a minute ago   Exited              kube-apiserver  

# kube-apiserver 容器报错
sudo crictl logs 646a1e76b9516
...
W0104 07:19:30.723990      19 clientconn.go:1223] grpc: addrConn.createTransport failed to connect to {https://10.66.208.140:2379  <nil> 0 <nil>}. Err :connection error: desc = "transport: Error while dialing dial tcp 10.66.208.140:2379: connect: no route to host". Reconnecting...
W0104 07:19:31.171907      19 clientconn.go:1223] grpc: addrConn.createTransport failed to connect to {https://10.66.208.141:2379  <nil> 0 <nil>}. Err :connection error: desc = "transport: Error while dialing dial tcp 10.66.208.141:2379: connect: no route to host". Reconnecting...
W0104 07:19:31.171907      19 clientconn.go:1223] grpc: addrConn.createTransport failed to connect to {https://10.66.208.141:2379  <nil> 0 <nil>}. Err :connection error: desc = "transport: Error while dialing dial tcp 10.66.208.141:2379: connect: no route to host". Reconnecting...
Error: context deadline exceeded
I0104 07:19:33.873454       1 main.go:198] Termination finished with exit code 1
I0104 07:19:33.873527       1 main.go:151] Deleting termination lock file "/var/log/kube-apiserver/.terminating"

# 查看 etcd 容器
sudo crictl ps -a | grep etcd
5cc186030c9ef       257e20937605406e2cf28da0e6c68aa85a8487a2aca0310c089891fe97b22464   8 minutes ago        Running             etcd-metrics                                  0                   3dde48e37798c
854a1e8729cfa       257e20937605406e2cf28da0e6c68aa85a8487a2aca0310c089891fe97b22464   8 minutes ago        Running             etcd                                          0                   3dde48e37798c
8e86ea9db41e0       257e20937605406e2cf28da0e6c68aa85a8487a2aca0310c089891fe97b22464   8 minutes ago        Running             etcdctl                                       0                   3dde48e37798c
13a368506d502       257e20937605406e2cf28da0e6c68aa85a8487a2aca0310c089891fe97b22464   8 minutes ago        Exited              etcd-resources-copy                           0                   3dde48e37798c
f0294ca3a88e1       257e20937605406e2cf28da0e6c68aa85a8487a2aca0310c089891fe97b22464   8 minutes ago        Exited              etcd-ensure-env-vars  

sudo crictl logs 854a1e8729cfa 2>&1 | more

sudo crictl logs 5cc186030c9ef
sudo crictl logs 8e86ea9db41e0

# 检查 kube-apiserver 是否正常运行
sudo crictl ps -a | grep kube-apiserver 
54261045c43f6       59c8ec9cf04d0b89d3295b108606e88aeeabb02b7c4f4e5f4351623ece2a9790   42 seconds ago       Running             kube-apiserver-check-endpoints                1                   0232867cc8bac
57a06e48da93a       59c8ec9cf04d0b89d3295b108606e88aeeabb02b7c4f4e5f4351623ece2a9790   42 seconds ago       Running             kube-apiserver-cert-regeneration-controller   1                   0232867cc8bac
1cdc10270edbe       203086c2d8868ba6b079af6f4953844254f105f78dead408b1ffd441480d4300   43 seconds ago       Running             kube-apiserver                                2                   0232867cc8bac
0511b36e852a6       203086c2d8868ba6b079af6f4953844254f105f78dead408b1ffd441480d4300   3 minutes ago        Exited              kube-apiserver                                1                   0232867cc8bac
ede04ea30eff4       59c8ec9cf04d0b89d3295b108606e88aeeabb02b7c4f4e5f4351623ece2a9790   4 minutes ago        Exited              kube-apiserver-check-endpoints                0                   0232867cc8bac
b5f73b5a898b3       59c8ec9cf04d0b89d3295b108606e88aeeabb02b7c4f4e5f4351623ece2a9790   4 minutes ago        Running             kube-apiserver-insecure-readyz                0                   0232867cc8bac
fac71cd3a5449       59c8ec9cf04d0b89d3295b108606e88aeeabb02b7c4f4e5f4351623ece2a9790   4 minutes ago        Exited              kube-apiserver-cert-regeneration-controller   0                   0232867cc8bac
b7f80f39965cf       59c8ec9cf04d0b89d3295b108606e88aeeabb02b7c4f4e5f4351623ece2a9790   4 minutes ago        Running             kube-apiserver-cert-syncer                    0                   0232867cc8bac

# 检查 kube-apiserver 的日志
sudo crictl logs $( sudo crictl ps --name kube-apiserver -o json  | jq '.containers[0].id' | sed -e 's|"||g' )

# 最近退出的 pods 包括
sudo crictl ps -a | grep Exited  | more
9f6fd0fefda4c       b69fa64626c9c494d05cfd7cc160629538e84f813546f73c718a048cf255fa9d   4 minutes ago       Exited              openshift-apiserver-operat
or                  5                   8d33ad66e41a6
5765142166a4b       a2f06168344d6450be4ea6764b4072309c325c6aaec4353e92831b85fab7f8a9   4 minutes ago       Exited              packageserver             
                    7                   9bc61f77a3276
5d522fdf3b6c9       203086c2d8868ba6b079af6f4953844254f105f78dead408b1ffd441480d4300   4 minutes ago       Exited              kube-controller-manager   
                    2                   827f1f13fd39e
9fc2c390c7e8e       a21d90ad5637d38872fc9ee7cde0cf67e8a96149461f6544d45b3948e635518f   5 minutes ago       Exited              oauth-apiserver           
                    6                   9a0c507c4717f
7f845e1cc7192       59c8ec9cf04d0b89d3295b108606e88aeeabb02b7c4f4e5f4351623ece2a9790   6 minutes ago       Exited              kube-apiserver-check-endpo
ints                4                   92659af53aece
c23545dcfcf71       203086c2d8868ba6b079af6f4953844254f105f78dead408b1ffd441480d4300   6 minutes ago       Exited              kube-apiserver            
                    3                   92659af53aece
9e25c8018dc8a       e573390c6291486c9fc0796df010c5428b35b950b9246f643e3c82cb90386421   6 minutes ago       Exited              console-operator       

# 看看 console-operator 为什么退出了
sudo crictl logs 9e25c8018dc8a

# 看看 packageserver 为什么退出了
sudo crictl logs 5765142166a4b

# 最后问题通过增大 master 内存解决了，感觉也没能完全处理好


```



### OpenShift 4.6 最小资源需求
https://docs.openshift.com/container-platform/4.6/installing/installing_bare_metal/installing-restricted-networks-bare-metal.html#minimum-resource-requirements_installing-restricted-networks-bare-metal

|Machine|Operating System|vCPU|Virtual RAM|Storage|
|---|---|---|---|---|
|Bootstrap|RHCOS|4|16GB|120GB|
|Control plane|RHCOS|4|16GB|120GB|
|Compute|RHCOS or RHEL 7.6|2|8GB|120GB|



### 删除 marketplace operator 相关资源，CVO重建相关资源
修复 marketplace-operator 相关错误
```
# 删除 deployment marketplace-operator
$ oc delete deployment/marketplace-operator

# 删除拥有 marketplace-operator 标签的 replicaset 
$ oc delete rs -l name=marketplace-operator
```



### 添加 Add configmap for service CA bundle
https://github.com/openshift/cluster-ingress-operator/commit/fa2873f252311dd43a2433944b1d88622c1eb8ba
```
oc extract -n openshift-kube-apiserver-operator cm/service-network-serving-ca --to=-
# ca-bundle.crt
-----BEGIN CERTIFICATE-----
MIIDTDCCAjSgAwIBAgIIAJB/+/C6NGQwDQYJKoZIhvcNAQELBQAwRDESMBAGA1UE
CxMJb3BlbnNoaWZ0MS4wLAYDVQQDEyVrdWJlLWFwaXNlcnZlci1zZXJ2aWNlLW5l
dHdvcmstc2lnbmVyMB4XDTIwMTEyNTA2MjEwOVoXDTMwMTEyMzA2MjEwOVowRDES
MBAGA1UECxMJb3BlbnNoaWZ0MS4wLAYDVQQDEyVrdWJlLWFwaXNlcnZlci1zZXJ2
aWNlLW5ldHdvcmstc2lnbmVyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
AQEAyb5I+VIdARlznTg1SNzUi5WYRn+0V4iQAM1jYOhpnEUffhfawfCmhD+1kG6I
XeKej28BC6tnoNhWlLt6IG010z7yH/lGq6zh/G1CsAK3JxaIgU7E92KfSToPpVz6
pxYWruv+8qx3g7urOyacL60+Z+T9byyW0QSE6nl9rCKaQybPYxQdBxooQuf3tZFE
e49oO2yDMJ9pm0QfgDTEKGE9OITYdXWBlAKoKEiIzsIEMQN9tmO/+j3Tclbxr6br
rbTPMgithz5QnRbZsKjbzmRhuqNZ0RCvvOoPuLe2RhTk+KT/7qrlKoMmxL/5HhRf
6Ds9xYe8ntgSfOqT95AA1ZedOwIDAQABo0IwQDAOBgNVHQ8BAf8EBAMCAqQwDwYD
VR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQURcP7OgUdK4cgB46FZOTD8L7CMeowDQYJ
KoZIhvcNAQELBQADggEBAEVAK0uHOhd+yUD9OY9QnAu/qyL6eSVWkWQfrmSoIECG
xfJSSQWDCG91/DNQ1fwqrm0iHJqbUa6lTajJPhAmy9h+h3vrqKs9YdqLeoSlGN7W
9Y5QxFOa+xBKswKYCh5sIIWotOx6bJ9fWnPGXUbxz5PWBTJAuhAl8MghZTL6aZWK
dIJur/tJs9kuGzidE7/cs4Lgp5cwGv9rHwInUxjUGFKxN+/byHUTHggzWdzsQ8qh
oz4QdzNeR2x5oSIxyEN0SVyzhs7M6L8ZIOwpTy+PlI5jeI/WUGFl3y4mmHwlb7zy
aD8InvUVyxYMYCbqU6iZPGZw01PKBCBz1yLTyU5SY/E=
-----END CERTIFICATE-----

$ oc extract -n openshift-kube-apiserver-operator cm/service-network-serving-ca --to=.
ca-bundle.crt

$ oc create route reencrypt apiserver --service kubernetes --port https -n default --dest-ca-cert=ca-bundle.crt

openssl s_client -showcerts -connect apiserver-default.apps.cluster-0001.rhsacn.org:443


# 通过 Resourcre Locker Operator 达到类似目的
# https://github.com/redhat-cop/resource-locker-operator
# 设置目标对象 targetObjectRef
# 设置源对象和源字段 SourceObjectRefs
# 设置 Patch 模版 PatchTemplate
# 设置 Patch 类型 PatchType 
apiVersion: redhatcop.redhat.io/v1alpha1
kind: ResourceLocker
metadata:
  name: apiserver-route
spec:
  patches:
    - id: patch1
      patchTemplate: |
        spec:
          tls:
            destinationCACertificate: |
              "{{ (index . 0) }}"
      patchType: application/strategic-merge-patch+json
      sourceObjectRefs:
        - apiVersion: v1
          fieldPath: $.data.ca-bundle\.crt
          kind: ConfigMap
          name: service-network-serving-ca
          namespace: openshift-kube-apiserver-operator
      targetObjectRef:
        apiVersion: route.openshift.io/v1
        kind: Route
        name: apiserver
        namespace: default
  serviceAccountRef:
    name: default
```



### OpenShift 4 与 Helm 3
https://www.openshift.com/blog/openshift-4-3-deploy-applications-with-helm-3<br>
https://docs.openshift.com/container-platform/4.4/cli_reference/helm_cli/getting-started-with-helm-on-openshift-container-platform.html<br>
https://help.aliyun.com/document_detail/58587.html<br>

```
# 下载 helm client
curl -L https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest/helm-linux-amd64 -o /usr/local/bin/helm

chmod +x /usr/local/bin/helm

oc new-project test2

# 添加 helm 的 stable repo 和 incubator repo
helm repo add stable https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts/
helm repo add incubator https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts-incubator/
helm repo update

# 查看已安装 charts
helm list
heml ls

# 查看 repo
helm repo list 

# 搜索 repo 和 hub
helm search repo
helm search hub

# https://artifacthub.io/packages/helm/bitnami/wordpress
# 添加 bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# 安装 bitnami wordpress
helm install my-release bitnami/wordpress
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /root/ocp4/auth/kubeconfig
NAME: my-release
LAST DEPLOYED: Tue Jan  5 10:47:02 2021
NAMESPACE: test2
STATUS: deployed
REVISION: 1
NOTES:
** Please be patient while the chart is being deployed **

Your WordPress site can be accessed through the following DNS name from within your cluster:

    my-release-wordpress.test2.svc.cluster.local (port 80)

To access your WordPress site from outside the cluster follow the steps below:

1. Get the WordPress URL by running these commands:

  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        Watch the status with: 'kubectl get svc --namespace test2 -w my-release-wordpress'

   export SERVICE_IP=$(kubectl get svc --namespace test2 my-release-wordpress --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
   echo "WordPress URL: http://$SERVICE_IP/"
   echo "WordPress Admin URL: http://$SERVICE_IP/admin"

2. Open a browser and access WordPress using the obtained URL.

3. Login with the following credentials below to see your blog:

  echo Username: user
  echo Password: $(kubectl get secret --namespace test2 my-release-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)

  # 口令获取
  oc get secret my-release-wordpress -o jsonpath='{.data.wordpress-password}' | base64 -d 

# 生成 route
oc expose svc/my-release-wordpress

# 拷贝缺失镜像
oc get statefulset.apps/my-release-mariadb -o jsonpath='{.spec.template.spec.containers[0].image}'
docker.io/bitnami/mariadb:10.5.8-debian-10-r21 

oc get deployment.apps/my-release-wordpress -o jsonpath='{.spec.template.spec.containers[0].image}'
docker.io/bitnami/wordpress:5.6.0-debian-10-r9

mkdir -p /root/tmp/mirror/bitnami/mariadb
skopeo copy --format v2s2 docker://docker.io/bitnami/mariadb:10.5.8-debian-10-r21 dir:///root/tmp/mirror/bitnami/mariadb

mkdir -p /root/tmp/mirror/bitnami/wordpress
skopeo copy --format v2s2 docker://docker.io/bitnami/wordpress:5.6.0-debian-10-r9 dir:///root/tmp/mirror/bitnami/wordpress

# 上传镜像
skopeo copy --format v2s2 dir:///root/tmp/mirror/bitnami/mariadb docker://helper.cluster-0001.rhsacn.org:5000/bitnami/mariadb:10.5.8-debian-10-r21

skopeo copy --format v2s2 dir:///root/tmp/mirror/bitnami/wordpress docker://helper.cluster-0001.rhsacn.org:5000/bitnami/wordpress:5.6.0-debian-10-r9


# patch statefulset my-release-mariadb 和 deployment my-release-wordpress
oc patch statefulset my-release-mariadb -n test2 --type json \
    -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "helper.cluster-0001.rhsacn.org:5000/bitnami/mariadb:10.5.8-debian-10-r21"}]'

oc patch deployment my-release-wordpress -n test2 --type json \
    -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "helper.cluster-0001.rhsacn.org:5000/bitnami/wordpress:5.6.0-debian-10-r9"}]'

# 为 my-release-mariadb 用户添加 anyuid scc
oc adm policy add-scc-to-user anyuid -z my-release-mariadb -n test2
# 为 default 用户添加 anyuid scc
oc adm policy add-scc-to-user anyuid -z default -n test2 

# 触发重新部署
# 根据需要执行
oc patch statefulset/my-release-mariadb --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

oc patch deployment/my-release-wordpress --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

# 列出已安装的 chart
helm list
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
my-release      test2           1               2021-01-05 13:04:14.919487446 +0800 CST deployed        wordpress-10.2.1        5.6.0    
```



### OCS 下通过 rook toolbox 创建 pool 和删除 pool
```
# 启用 rook toolbox
oc patch OCSInitialization ocsinit -n openshift-storage --type json --patch  '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'

TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)

# 创建 pool ocs-storagecluster-test
oc rsh -n openshift-storage $TOOLS_POD ceph osd pool create ocs-storagecluster-test 64 64

# 查看 pool 的情况
oc rsh -n openshift-storage $TOOLS_POD ceph osd lspools
1 ocs-storagecluster-cephblockpool
2 ocs-storagecluster-cephobjectstore.rgw.control
3 ocs-storagecluster-cephfilesystem-metadata
4 ocs-storagecluster-cephfilesystem-data0
5 ocs-storagecluster-cephobjectstore.rgw.meta
6 ocs-storagecluster-cephobjectstore.rgw.log
7 ocs-storagecluster-cephobjectstore.rgw.buckets.index
8 ocs-storagecluster-cephobjectstore.rgw.buckets.non-ec
9 .rgw.root
10 ocs-storagecluster-cephobjectstore.rgw.buckets.data
11 ocs-storagecluster-test

# 删除 pool
oc rsh -n openshift-storage $TOOLS_POD ceph osd pool delete ocs-storagecluster-test ocs-storagecluster-test --yes-i-really-really-mean-it

# 查看 pool 的情况
oc rsh -n openshift-storage $TOOLS_POD ceph osd lspools
1 ocs-storagecluster-cephblockpool
2 ocs-storagecluster-cephobjectstore.rgw.control
3 ocs-storagecluster-cephfilesystem-metadata
4 ocs-storagecluster-cephfilesystem-data0
5 ocs-storagecluster-cephobjectstore.rgw.meta
6 ocs-storagecluster-cephobjectstore.rgw.log
7 ocs-storagecluster-cephobjectstore.rgw.buckets.index
8 ocs-storagecluster-cephobjectstore.rgw.buckets.non-ec
9 .rgw.root
10 ocs-storagecluster-cephobjectstore.rgw.buckets.data

# 禁用 rook toolbox
oc patch OCSInitialization ocsinit -n openshift-storage --type json --patch  '[{ "op": "replace", "path": "/spec/enableCephTools", "value": false }]'

```



### OpenShift cookbook
https://cookbook.openshift.org/users-and-role-based-access-control/how-can-i-enable-an-image-to-run-as-a-set-user-id.html


### 获取 scc 的 priority
```
oc get scc -o jsonpath='Name{"\t\t\t"}Priority{"\n"}{range .items[*]}{@.metadata.name}{"\t\t\t"}{@.priority}{"\n"}{end}' 

Name              Priority
anyuid            10
hostaccess              <nil>
hostmount-anyuid                <nil>
hostnetwork             <nil>
node-exporter           <nil>
nonroot           <nil>
noobaa            <nil>
privileged              <nil>
restricted              <nil>
rook-ceph               <nil>
rook-ceph-csi           <nil>
```



#### 删除 OCS 的 ceph pool
删除 OCS 下的 ceph pool 需要删除 k8s 下对应的 CRD 资源 CephBlockPool

删除 k8s 下对应的 CRD 资源 CephBlockPool的方法：
```
1. oc delete CephBlockPool sc-pool-2way -n openshift-storage
2. From OCP UI -> In left Nav -> Administration -> Custom Resource Definanions -> search CephBlockPool -> click on CephBlockPool -> Go to instance tab -> delete resource from right menu.
```

另外直接直接操作 ceph pool 的方法为：
```
oc patch OCSInitialization ocsinit -n openshift-storage --type json --patch  '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'

TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)

# list pools
oc rsh -n openshift-storage $TOOLS_POD ceph osd lspools

# delete pool -- carefully
oc rsh -n openshift-storage $TOOLS_POD ceph osd pool delete <pool_name> <pool_name> --yes-i-really-really-mean-it
```



### How to create a MachineSet for VMware in OpenShift 4.5 and Higher
https://access.redhat.com/solutions/5307621



### machine config template keepalived 
[0] https://github.com/openshift/machine-config-operator/blob/master/templates/master/00-master/on-prem/files/keepalived-keepalived.yaml<br>
[1] https://github.com/openshift/machine-config-operator/blob/master/templates/worker/00-worker/on-prem/files/keepalived-keepalived.yaml<br>



### 查询 pipeline operators 
```
# 查询 pipeline operator 需要的镜像
echo "select * from related_image \
    where operatorbundle_name like 'openshift-pipelines-operator%';" \
    | sqlite3 -line ./bundles.db 


# 下载 pipeline operator 需要的镜像
mkdir -p /root/jwang/mirror/openshift-pipelines-tech-preview
skopeo copy --format v2s2 docker://registry.redhat.io/openshift-pipelines-tech-preview/pipelines-rhel8-operator@sha256:78260d7b70e43ec4782176fe892fae2998e5885943f673914f5b5ff1add7b267 dir:///root/jwang/mirror/openshift-pipelines-tech-preview

# 将下载镜像拷贝到本地 registry
skopeo copy --authfile /root/ocp4/ins452/postinstall/pull-secret-2.json --format v2s2 dir:///tmp/openshift-pipelines-tech-preview docker://registry.ocp4.example.com:5443/openshift-pipelines-tech-preview/pipelines-rhel8-operator

cat <<EOF > /root/tmp/pipeline-imagecontentsourcepolicy.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: icsp-pipelines-operator
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.ocp4.example.com:5443/openshift-pipelines-tech-preview/pipelines-rhel8-operator
    source: registry.redhat.io/openshift-pipelines-tech-preview/pipelines-rhel8-operator
EOF


```



### 检查 cluster operator 
```
# 获取 cluster operator 的名字
oc get co -o jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}'

# 获取 kube-apiserver 的 id
sudo crictl ps -a | grep Running | grep "kube-apiserver " | awk '{print $1}' 

# 获取 kube-apiserver 的 日志
sudo crictl logs $(sudo crictl ps -a | grep Running | grep "kube-apiserver " | awk '{print $1}')

http://pastebin.test.redhat.com/929194


```


### 生成证书符合 OCP 4.6 要求的自签名证书
```
# 需要重新生成的证书原来保存的位置
cat /etc/docker-distribution/registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: /var/lib/registry
    delete:
        enabled: true
http:
    addr: :5443
    tls:
       certificate: /etc/crts/ocp4.example.com.crt
       key: /etc/crts/ocp4.example.com.key

cd /etc/crts

# 生成配置文件
cat > ssl.conf << EOF
[req]
default_bits  = 4096
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
countryName = CN
stateOrProvinceName = BJ
localityName = BJ
organizationName = Global Security
organizationalUnitName = IT Department
commonName = *.ocp4.example.com

[req_ext]
subjectAltName = @alt_names

[v3_req]
subjectAltName = @alt_names

# Key usage: this is typical for a CA certificate. However since it will
# prevent it being used as an test self-signed certificate it is best
# left out by default.
# keyUsage                = critical,keyCertSign,cRLSign

basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash

[alt_names]
DNS.1 = *.ocp4.example.com
DNS.2 = registry.ocp4.example.com
EOF

# 生成证书
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout ocp4.example.com.key -out ocp4.example.com.crt -config ./ssl.conf

# 拷贝证书且更新证书信任关系
cp /etc/crts/ocp4.example.com.crt /etc/pki/ca-trust/source/anchors
update-ca-trust extract

# 重启 registry 服务
systemctl restart docker-distribution
```



### 生成 ocp 4.6 ipv6 install-config.yaml 文件
```
cat > install-config.yaml.GOOD.ipv6.4_6 << EOF
apiVersion: v1
baseDomain: example.com
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  name: ocp4
networking:
  machineCIDR: 2001:0DB8::/64
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: fd01::/48
    hostPrefix: 64
  serviceNetwork:
  - fd02::/112
platform:
  none: {}
pullSecret: '{"auths":{"registry.ocp4.example.com:5443":{"auth":"YTph"}}}'
sshKey: |
$( cat /root/.ssh/id_rsa.pub | sed 's/^/  /g' )
additionalTrustBundle: |
$( cat /etc/pki/ca-trust/source/anchors/ocp4.example.com.crt | sed 's/^/  /g' )
imageContentSources:
- mirrors:
  - registry.ocp4.example.com:5443/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - registry.ocp4.example.com:5443/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF


cat > install-config.yaml.GOOD.4_6 << EOF
apiVersion: v1
baseDomain: example.com
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  name: ocp4
networking:
  clusterNetworks:
  - cidr: 10.254.0.0/16
    hostPrefix: 24
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '{"auths":{"registry.ocp4.example.com:5443":{"auth":"YTph"}}}'
sshKey: |
$( cat /root/.ssh/id_rsa.pub | sed 's/^/  /g' )
additionalTrustBundle: |
$( cat /etc/pki/ca-trust/source/anchors/ocp4.example.com.crt | sed 's/^/  /g' )
imageContentSources:
- mirrors:
  - registry.ocp4.example.com:5443/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - registry.ocp4.example.com:5443/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

```


### 配置 ip 参数的内核参数
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-configuring_ip_networking_from_the_kernel_command_line



### stop masters and workers
```
for vm in master0 master1 master2 worker0 worker1 worker2 
do
  virsh destroy jwang-ocp452-${vm}
done

for vm in master0 master1 master2 worker0 worker1 worker2 
do
  qemu-img create -f qcow2 /data/kvm/jwang-ocp452-${vm}.qcow2 120G
done

for vm in master0 master1 master2 worker0 worker1 worker2 
do
  virsh start jwang-ocp452-${vm}
done
```



### OpenShift 4 下如何替换全局 pull secret
https://access.redhat.com/solutions/4902871
```
# 如果在 openshift-config 下存在这个 secret/pull-secret
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=pull-secret.txt

# 如果在 openshift-config 下不存在这个 secret/pull-secret，则创建这个 pull secret
oc create secret generic pull-secret -n openshift-config --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=/path/to/downloaded/pull-secret 

# 检查 pods 
oc get pods -l olm.catalogSource=certified-operators -n openshift-marketplace
oc get pods -l olm.catalogSource=redhat-operators -n openshift-marketplace
oc get pods -l olm.catalogSource=community-operators -n openshift-marketplace


```



### OpenShift 4.3: Alertmanager Configuration
https://www.openshift.com/blog/openshift-4-3-alertmanager-configuration



### install helm chart by dry-run and oc apply
```
helm template ./tooling/charts/operators/ --dry-run | oc apply -f-
namespace/do500-workspaces created
namespace/do500-gitlab created
operatorgroup.operators.coreos.com/codeready-workspaces created
subscription.operators.coreos.com/codeready-workspaces created
```



### RHEL8 kickstart file
可以从网址生成
https://access.redhat.com/labsinfo/kickstartconfig

RHEL8 minimal kickstart file
```
cat > /tmp/ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=ens3 --hostname=undercloud.example.com --bootproto=static --ip=192.168.8.21 --netmask=255.255.255.0 --gateway=192.168.8.1 --nameserver=192.168.8.11
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
%end
EOF
```

RHEL8 server with gui kickstart file
```
cat > /tmp/ks-helper.cfg <<'EOF'
lang en_US
keyboard us
ignoredisk --only-use=vda
timezone Asia/Shanghai --isUtc
rootpw $1$/5O3zdx8$/h6dTG0k/W9Pso5SXHSOc/ --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=ens2 --hostname=helper.example.com --bootproto=static --ip=192.168.8.20 --netmask=255.255.255.0 --gateway=192.168.8.1 --nameserver=192.168.8.1
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
firstboot --disable
%packages
@^graphical-server-environment
firefox
%end
EOF
```

在 kickstart 里添加 kernel params 的例子<br>
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-disabling_consistent_network_device_naming
```
   bootloader --append="crashkernel=auto net.ifnames=0 biosdevname=0"
```


### 介绍 lokkit 的链接
https://www.lifewire.com/what-is-lokkit-2192255



### Nested virtualization in KVM
https://stafwag.github.io/blog/blog/2018/06/04/nested-virtualization-in-kvm/<br>
https://raw.githubusercontent.com/kashyapc/nvmx-haswell/master/SETUP-nVMX.rst

```
[root@base-pvg ~]# virsh  capabilities | virsh cpu-baseline /dev/stdin 
<cpu mode='custom' match='exact'>
  <model fallback='allow'>Westmere-IBRS</model>
  <feature policy='require' name='vmx'/>
</cpu>

编辑虚拟机，将 cpu 设置为
  <cpu mode='custom' match='exact'>
    <model fallback='allow'>Westmere-IBRS</model>
    <feature policy='require' name='vmx'/>
  </cpu>

[root@base-pvg ~]# virsh list --all | grep jwang-overcloud
 -     jwang-overcloud-ceph01         shut off
 -     jwang-overcloud-ceph02         shut off
 -     jwang-overcloud-ceph03         shut off
 -     jwang-overcloud-compute01      shut off
 -     jwang-overcloud-compute02      shut off
 -     jwang-overcloud-ctrl01         shut off
 -     jwang-overcloud-ctrl02         shut off
 -     jwang-overcloud-ctrl03         shut off



ALL_N="ctrl01 ctrl02 ctrl03 compute01 compute02 ceph01 ceph02 ceph03"

for node in $ALL_N
do
  openstack baremetal node manage overcloud-${node}
done  

openstack baremetal node list

openstack overcloud node introspect --all-manageable --provide

openstack baremetal node show overcloud-compute01 -f json
```


### 设定/取消设定 baremetal node 的 root_device 的方法，以及为节点capabilities 里添加 node:role-index 
https://docs.openstack.org/tripleo-docs/latest/install/advanced_deployment/root_device.html
```
设置root_device
openstack baremetal node set <UUID> --property root_device='{"wwn": "0x4000cca77fc4dba1"}'

取消root_device设置
openstack baremetal node unset <UUID> --property root_device

设置节点属性
openstack baremetal node set --property capabilities='node:compute-5,cpu_hugepages:true,cpu_txt:true,boot_option:local,cpu_aes:true,cpu_vt:true,cpu_hugepages_1g:true' compute3

```



### osp16 templates with ceph 
https://gitlab.cee.redhat.com/mzheng/meiyan-rhos-templates/-/tree/master/rhosp16-with-ceph<br>



### osp16 部署模版
https://gitlab.cee.redhat.com/mzheng/meiyan-rhos-templates/-/blob/master/rhosp16-with-ceph/deploy.sh



### undercloud.conf 说明
```
#
# From instack-undercloud
#

# Network CIDR for the Neutron-managed subnet for Overcloud instances.
# (string value)
# Deprecated group/name - [DEFAULT]/network_cidr
#cidr = 192.168.24.0/24

# Start of DHCP allocation range for PXE and DHCP of Overcloud
# instances on this network. (string value)
# Deprecated group/name - [DEFAULT]/dhcp_start
#dhcp_start = 192.168.24.5

# End of DHCP allocation range for PXE and DHCP of Overcloud instances
# on this network. (string value)
# Deprecated group/name - [DEFAULT]/dhcp_end
#dhcp_end = 192.168.24.24

# Temporary IP range that will be given to nodes on this network
# during the inspection process. Should not overlap with the range
# defined by dhcp_start and dhcp_end, but should be in the same ip
# subnet. (string value)
# Deprecated group/name - [DEFAULT]/inspection_iprange
#inspection_iprange = 192.168.24.100,192.168.24.120

# Network gateway for the Neutron-managed network for Overcloud
# instances on this network. (string value)
# Deprecated group/name - [DEFAULT]/network_gateway
#gateway = 192.168.24.1

# The network will be masqueraded for external access. (boolean value)
#masquerade = false
```



### 通过 jq 查看 introspection 结果
```

查看 disks 信息
(undercloud) [stack@undercloud ~]$ cat ~/introspection/overcloud-ceph01.json | jq .inventory.disks

查看第一块 disk 信息
(undercloud) [stack@undercloud ~]$ cat ~/introspection/overcloud-ceph01.json | jq .inventory.disks | jq '.[0]'
{
  "name": "/dev/vda",
  "model": "",
  "size": 107374182400,
  "rotational": true,
  "wwn": null,
  "serial": null,
  "vendor": "0x1af4",
  "wwn_with_extension": null,
  "wwn_vendor_extension": null,
  "hctl": null,
  "by_path": "/dev/disk/by-path/pci-0000:00:08.0"
}

查看所有磁盘的名字
(undercloud) [stack@undercloud ~]$ cat ~/introspection/overcloud-ceph01.json | jq .inventory.disks | jq '.[].name'
"/dev/vda"
"/dev/vdb"
"/dev/vdc"
"/dev/vdd"

查看所有 interface
(undercloud) [stack@undercloud ~]$ cat ~/introspection/overcloud-ceph01.json | jq .inventory.interfaces
[
  {
    "name": "ens4",
    "mac_address": "52:54:00:89:21:a5",
    "ipv4_address": null,
    "ipv6_address": "fe80::5054:ff:fe89:21a5%ens4",
    "has_carrier": true,
    "lldp": null,
    "vendor": "0x1af4",
    "product": "0x0001",
    "client_id": null,
    "biosdevname": null
  },
  {
    "name": "ens5",
    "mac_address": "52:54:00:16:28:d1",
    "ipv4_address": null,
    "ipv6_address": "fe80::5054:ff:fe16:28d1%ens5",
    "has_carrier": true,
    "lldp": null,
    "vendor": "0x1af4",
    "product": "0x0001",
    "client_id": null,
    "biosdevname": null
  },
  {
    "name": "ens3",
    "mac_address": "52:54:00:78:2f:e3",
    "ipv4_address": "192.0.2.102",
    "ipv6_address": "fe80::cc7:4ef4:62b0:19a7%ens3",
    "has_carrier": true,
    "lldp": null,
    "vendor": "0x1af4",
    "product": "0x0001",
    "client_id": null,
    "biosdevname": null
  }
]

# 查看启动接口
(undercloud) [stack@undercloud ~]$ cat ~/introspection/overcloud-ceph01.json | jq .interfaces
{
  "ens3": {
    "ip": "192.0.2.102",
    "mac": "52:54:00:78:2f:e3",
    "client_id": null,
    "pxe": true
  }
}

# 查看全部接口
(undercloud) [stack@undercloud ~]$ cat ~/introspection/overcloud-ceph01.json | jq .all_interfaces

# 查看启动接口
(undercloud) [stack@undercloud ~]$ cat ~/introspection/overcloud-ceph01.json | jq .boot_interface
"52:54:00:78:2f:e3"

# 查看 root_disk
(undercloud) [stack@undercloud ~]$ cat ~/introspection/overcloud-ceph01.json | jq .root_disk
{
  "name": "/dev/vda",
  "model": "",
  "size": 107374182400,
  "rotational": true,
  "wwn": null,
  "serial": null,
  "vendor": "0x1af4",
  "wwn_with_extension": null,
  "wwn_vendor_extension": null,
  "hctl": null,
  "by_path": "/dev/disk/by-path/pci-0000:00:08.0"
}
```


### osp16.1 部署失败错误信息
```
# 问题：在部署阶段，ceph-ansible 执行时，在哪里可以了解 ceph ansible 执行的情况
# 等待答案...

# 首先查看哪个节点 failed 不为 0
sudo cat /var/lib/mistral/overcloud/ansible.log | grep -E "failed"

# 然后查看这个节点的 “fatal: ” 信息
# 以下这个报错告诉我们错误原因是：时间不同步
# 解决方案是在 undercloud 上配置 chrony 服务，然后让部署指向这个时间服务
sudo cat /var/lib/mistral/overcloud/ansible.log | grep cephstorage | grep -E "fatal: " 
        "fatal: [overcloud-cephstorage-2 -> 192.0.2.18]: FAILED! => {\"attempts\": 60, \"changed\": false, \"cmd\": [\"podman\", \"exec\", \"ceph-mon-overcloud-controller-0\", \"ceph\", \"--cluster\", \"ceph\", \"-s\", \"-f\", \"json\"], \"delta\": \"0:00:01.786829\", \"end\": \"2021-01-13 05:14:19.937156\", \"rc\": 0, \"start\": \"2021-01-13 05:14:18.150327\", \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"\\n{\\\"fsid\\\":\\\"a20d5cc1-4aca-4ebb-8d50-4dc85d463817\\\",\\\"health\\\":{\\\"checks\\\":{\\\"TOO_FEW_OSDS\\\":{\\\"severity\\\":\\\"HEALTH_WARN\\\",\\\"summary\\\":{\\\"message\\\":\\\"OSD count 0 < osd_pool_default_size 3\\\"}},\\\"MON_CLOCK_SKEW\\\":{\\\"severity\\\":\\\"HEALTH_WARN\\\",\\\"summary\\\":{\\\"message\\\":\\\"clock skew detected on mon.overcloud-controller-0, mon.overcloud-controller-1\\\"}}},\\\"status\\\":\\\"HEALTH_WARN\\\"},\\\"election_epoch\\\":14,\\\"quorum\\\":[0,1,2],\\\"quorum_names\\\":[\\\"overcloud-controller-2\\\",\\\"overcloud-controller-0\\\",\\\"overcloud-controller-1\\\"],\\\"quorum_age\\\":964,\\\"monmap\\\":{\\\"epoch\\\":1,\\\"fsid\\\":\\\"a20d5cc1-4aca-4ebb-8d50-4dc85d463817\\\",\\\"modified\\\":\\\"2021-01-13 04:57:48.985026\\\",\\\"created\\\":\\\"2021-01-13 04:57:48.985026\\\",\\\"min_mon_release\\\":14,\\\"min_mon_release_name\\\":\\\"nautilus\\\",\\\"election_strategy\\\":1,\\\"disallowed_leaders: \\\":\\\"\\\",\\\"stretch_mode\\\":false,\\\"features\\\":{\\\"persistent\\\":[\\\"kraken\\\",\\\"luminous\\\",\\\"mimic\\\",\\\"osdmap-prune\\\",\\\"nautilus\\\",\\\"elector-pinging\\\"],\\\"optional\\\":[]},\\\"mons\\\":[{\\\"rank\\\":0,\\\"name\\\":\\\"overcloud-controller-2\\\",\\\"public_addrs\\\":{\\\"addrvec\\\":[{\\\"type\\\":\\\"v2\\\",\\\"addr\\\":\\\"172.16.1.75:3300\\\",\\\"nonce\\\":0},{\\\"type\\\":\\\"v1\\\",\\\"addr\\\":\\\"172.16.1.75:6789\\\",\\\"nonce\\\":0}]},\\\"addr\\\":\\\"172.16.1.75:6789/0\\\",\\\"public_addr\\\":\\\"172.16.1.75:6789/0\\\",\\\"crush_location\\\":\\\"{}\\\"},{\\\"rank\\\":1,\\\"name\\\":\\\"overcloud-controller-0\\\",\\\"public_addrs\\\":{\\\"addrvec\\\":[{\\\"type\\\":\\\"v2\\\",\\\"addr\\\":\\\"172.16.1.160:3300\\\",\\\"nonce\\\":0},{\\\"type\\\":\\\"v1\\\",\\\"addr\\\":\\\"172.16.1.160:6789\\\",\\\"nonce\\\":0}]},\\\"addr\\\":\\\"172.16.1.160:6789/0\\\",\\\"public_addr\\\":\\\"172.16.1.160:6789/0\\\",\\\"crush_location\\\":\\\"{}\\\"},{\\\"rank\\\":2,\\\"name\\\":\\\"overcloud-controller-1\\\",\\\"public_addrs\\\":{\\\"addrvec\\\":[{\\\"type\\\":\\\"v2\\\",\\\"addr\\\":\\\"172.16.1.161:3300\\\",\\\"nonce\\\":0},{\\\"type\\\":\\\"v1\\\",\\\"addr\\\":\\\"172.16.1.161:6789\\\",\\\"nonce\\\":0}]},\\\"addr\\\":\\\"172.16.1.161:6789/0\\\",\\\"public_addr\\\":\\\"172.16.1.161:6789/0\\\",\\\"crush_location\\\":\\\"{}\\\"}]},\\\"osdmap\\\":{\\\"osdmap\\\":{\\\"epoch\\\":3,\\\"num_osds\\\":0,\\\"num_up_osds\\\":0,\\\"num_in_osds\\\":0,\\\"num_remapped_pgs\\\":0}},\\\"pgmap\\\":{\\\"pgs_by_state\\\":[],\\\"num_pgs\\\":0,\\\"num_pools\\\":0,\\\"num_objects\\\":0,\\\"data_bytes\\\":0,\\\"bytes_used\\\":0,\\\"bytes_avail\\\":0,\\\"bytes_total\\\":0},\\\"fsmap\\\":{\\\"epoch\\\":1,\\\"by_rank\\\":[],\\\"up:standby\\\":0},\\\"mgrmap\\\":{\\\"epoch\\\":3,\\\"active_gid\\\":4280,\\\"active_name\\\":\\\"overcloud-controller-1\\\",\\\"active_addrs\\\":{\\\"addrvec\\\":[{\\\"type\\\":\\\"v2\\\",\\\"addr\\\":\\\"172.16.1.161:6800\\\",\\\"nonce\\\":56},{\\\"type\\\":\\\"v1\\\",\\\"addr\\\":\\\"172.16.1.161:6801\\\",\\\"nonce\\\":56}]},\\\"active_addr\\\":\\\"172.16.1.161:6801/56\\\",\\\"active_change\\\":\\\"2021-01-13 05:00:26.908354\\\",\\\"available\\\":true,\\\"standbys\\\":[{\\\"gid\\\":4281,\\\"name\\\":\\\"overcloud-controller-2\\\",\\\"available_modules\\\":[{\\\"name\\\":\\\"alerts\\\",\\\"can_run\\\":true,\\\"error_string\\\":\\\"\\\",\\\"module_options\\\":{\\\"interval\\\":{\\\"name\\\":\\\"interval\\\",\\\"type\\\":\\\"secs\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"60\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"How frequently to reexamine health status\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_destination\\\":{\\\"name\\\":\\\"smtp_destination\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"Email address to send alerts to\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_from_name\\\":{\\\"name\\\":\\\"smtp_from_name\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"Ceph\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"Email From: name\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_host\\\":{\\\"name\\\":\\\"smtp_host\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"SMTP server\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_password\\\":{\\\"name\\\":\\\"smtp_password\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"Password to authenticate with\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_port\\\":{\\\"name\\\":\\\"smtp_port\\\",\\\"type\\\":\\\"int\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"465\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"SMTP port\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_sender\\\":{\\\"name\\\":\\\"smtp_sender\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"SMTP envelope sender\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_ssl\\\":{\\\"name\\\":\\\"smtp_ssl\\\",\\\"type\\\":\\\"bool\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"True\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"Use SSL to connect to SMTP server\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_user\\\":{\\\"name\\\":\\\"smtp_user\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"User to authenticate as\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]}}},{\\\"name\\\":\\\"ansible\\\",\\\"can_run\\\":true,\\\"error_string\\\":\\\"\\\",\\\"module_options\\\":{\\\"password\\\":{\\\"name\\\":\\\"password\\\",\\\
```



### RHEL8 chronyd 服务配置

```
# 在服务器上配置，服务器本地 ip 地址是 192.0.2.1
# 时间服务监听在 192.0.2.1 地址上
# 同时注意防火墙规则允许 192.0.2.0/24 网段的机器访问 123 udp 端口
# 我不太理解为什么有了上面这条规则还需要建立下面那条规则
# -A INPUT -p udp -m multiport --dports 123 -m state --state NEW -m comment --comment "105 ntp ipv4" -j ACCEPT
# -A INPUT -s 192.0.2.0/24 -p udp -m multiport --dports 123 -m state --state NEW -m comment --comment "105 ntp ipv4" -j ACCEPT

cat > /etc/chrony.conf << EOF
server 192.0.2.1 iburst
bindaddress 192.0.2.1
allow all
local stratum 4
EOF

```



### containers-prepare-parameter.yaml 
```
parameter_defaults:
  ContainerImagePrepare:
  - push_destination: true
    set:
      ceph_alertmanager_image: ose-prometheus-alertmanager
      ceph_alertmanager_namespace: registry.redhat.io/openshift4
      ceph_alertmanager_tag: 4.1
      ceph_grafana_image: rhceph-4-dashboard-rhel8
      ceph_grafana_namespace: registry.redhat.io/rhceph
      ceph_grafana_tag: 4
      ceph_image: rhceph-4-rhel8
      ceph_namespace: registry.redhat.io/rhceph
      ceph_node_exporter_image: ose-prometheus-node-exporter
      ceph_node_exporter_namespace: registry.redhat.io/openshift4
      ceph_node_exporter_tag: v4.1
      ceph_prometheus_image: ose-prometheus
      ceph_prometheus_namespace: registry.redhat.io/openshift4
      ceph_prometheus_tag: 4.1
      ceph_tag: latest
      name_prefix: openstack-
      name_suffix: ''
      namespace: registry.redhat.io/rhosp-rhel8
      neutron_driver: ovn
      rhel_containers: false
      tag: '16.1'
    tag_from_label: '{version}-{release}'
  ContainerImageRegistryCredentials:
    registry.redhat.io:
      6747835|jwang: eyJhb...
```

```
(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+-------------------------+--------+---------------------+----------------+-----------+
| ID                                   | Name                    | Status | Networks            | Image          | Flavor    |
+--------------------------------------+-------------------------+--------+---------------------+----------------+-----------+
| e214670c-eb85-48a7-a9d9-c94b115049a1 | overcloud-controller-1  | ACTIVE | ctlplane=192.0.2.9  | overcloud-full | baremetal |
| aa9d1823-7077-4bdc-ba95-425a74ac2837 | overcloud-controller-0  | ACTIVE | ctlplane=192.0.2.23 | overcloud-full | baremetal |
| ee13c670-79dc-4ca8-9a54-13b4ededd159 | overcloud-controller-2  | ACTIVE | ctlplane=192.0.2.19 | overcloud-full | baremetal |
| 9ebe0e0f-4ffb-4679-853f-01cdae4f9722 | overcloud-novacompute-0 | ACTIVE | ctlplane=192.0.2.17 | overcloud-full | baremetal |
| de0605e9-ae98-44a3-96b0-1eeccba89b16 | overcloud-novacompute-1 | ACTIVE | ctlplane=192.0.2.24 | overcloud-full | baremetal |
| 8a75e2c0-894e-4758-a1a2-8b413b82ecfb | overcloud-cephstorage-1 | ACTIVE | ctlplane=192.0.2.21 | overcloud-full | baremetal |
| 13a207ff-6d73-41f6-8660-12cb361152ab | overcloud-cephstorage-2 | ACTIVE | ctlplane=192.0.2.8  | overcloud-full | baremetal |
| 028df777-bdb9-4b6f-9cc7-183bcad049cc | overcloud-cephstorage-0 | ACTIVE | ctlplane=192.0.2.16 | overcloud-full | baremetal |
+--------------------------------------+-------------------------+--------+---------------------+----------------+-----------+

(undercloud) [stack@undercloud ~]$ sudo cat /var/lib/mistral/overcloud/ansible.log | grep overcloud-cephstorage-0 | grep -E "fatal: " 
        "fatal: [overcloud-cephstorage-0]: FAILED! => {\"changed\": false, \"cmd\": [\"podman\", \"inspect\", \"608a40b63096\", \"2a177bdbcf58\", \"ce8e3e1a2bbd\"], \"delta\": \"0:00:00.207533\", \"end\": \"2021-01-13 10:33:25.511713\", \"msg\": \"non-zero return code\", \"rc\": 125, \"start\": \"2021-01-13 10:33:25.304180\", \"stderr\": \"Error: error getting image \\\"ce8e3e1a2bbd\\\": unable to find a name and tag match for ce8e3e1a2bbd in repotags: no such image\", \"stderr_lines\": [\"Error: error getting image \\\"ce8e3e1a2bbd\\\": unable to find a name and tag match for ce8e3e1a2bbd in repotags: no such image\"], \"stdout\": \"\", \"stdout_lines\": []}",
(undercloud) [stack@undercloud ~]$ sudo cat /var/lib/mistral/overcloud/ansible.log | grep overcloud-cephstorage-1 | grep -E "fatal: " 
        "fatal: [overcloud-cephstorage-1]: FAILED! => {\"changed\": false, \"cmd\": [\"podman\", \"inspect\", \"3106a47130b9\", \"94c20d553a8d\", \"f747960e7fcf\"], \"delta\": \"0:00:00.337421\", \"end\": \"2021-01-13 10:33:25.743865\", \"msg\": \"non-zero return code\", \"rc\": 125, \"start\": \"2021-01-13 10:33:25.406444\", \"stderr\": \"Error: error getting image \\\"f747960e7fcf\\\": unable to find a name and tag match for f747960e7fcf in repotags: no such image\", \"stderr_lines\": [\"Error: error getting image \\\"f747960e7fcf\\\": unable to find a name and tag match for f747960e7fcf in repotags: no such image\"], \"stdout\": \"\", \"stdout_lines\": []}",
(undercloud) [stack@undercloud ~]$ sudo cat /var/lib/mistral/overcloud/ansible.log | grep overcloud-cephstorage-2 | grep -E "fatal: " 
        "fatal: [overcloud-cephstorage-2]: FAILED! => {\"changed\": false, \"cmd\": [\"podman\", \"inspect\", \"51b2504f520a\", \"08817d83161a\", \"c9c197e953be\"], \"delta\": \"0:00:00.305030\", \"end\": \"2021-01-13 10:33:25.872782\", \"msg\": \"non-zero return code\", \"rc\": 125, \"start\": \"2021-01-13 10:33:25.567752\", \"stderr\": \"Error: error getting image \\\"c9c197e953be\\\": unable to find a name and tag match for c9c197e953be in repotags: no such image\", \"stderr_lines\": [\"Error: error getting image \\\"c9c197e953be\\\": unable to find a name and tag match for c9c197e953be in repotags: no such image\"], \"stdout\": \"\", \"stdout_lines\": []}",


(undercloud) [stack@undercloud ~]$ podman login registry.redhat.io
Username: 6747835|jwang
Password: 
Login Succeeded!

(undercloud) [stack@undercloud ~]$ podman pull registry.redhat.io/openshift4/ose-prometheus-alertmanager:4.1
Trying to pull registry.redhat.io/openshift4/ose-prometheus-alertmanager:4.1...
Getting image source signatures
Copying blob c1427d8de594 done
Copying blob 455ea8ab0621 done
Copying blob 935ce2f796a9 done
Copying blob bb13d92caffa done
Copying config b00b1d49b1 done
Writing manifest to image destination
Storing signatures
b00b1d49b1ebe84ed1154da252b093bcf59e4a31e8b98e4f657ec50867c4cfdd

(undercloud) [stack@undercloud ~]$ podman pull registry.redhat.io/rhceph/rhceph-4-dashboard-rhel8:4
Trying to pull registry.redhat.io/rhceph/rhceph-4-dashboard-rhel8:4...
Getting image source signatures
Copying blob cca21acb641a done
Copying blob d9e72d058dc5 done
Copying blob c921400c62b4 done
Copying config e317acb665 done
Writing manifest to image destination
Storing signatures
e317acb66510ad968a12875b6766b971aea943b536b856bc578d66877e958f43

(undercloud) [stack@undercloud ~]$ podman pull registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.1
Trying to pull registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.1...
Getting image source signatures
Copying blob 3d85e2d43a91 done
Copying blob 23302e52b49d done
Copying blob cf5693de4d3c done
Copying blob 9dcb201bed02 done
Copying config 69b00cdbb1 done
Writing manifest to image destination
Storing signatures
69b00cdbb1da73bbc3333d209f83c9a68b001c16f98d998fc54348e80f66e8e3

(undercloud) [stack@undercloud ~]$ podman pull registry.redhat.io/openshift4/ose-prometheus:4.1
Trying to pull registry.redhat.io/openshift4/ose-prometheus:4.1...
Getting image source signatures
Copying blob 455ea8ab0621 skipped: already exists
Copying blob 935ce2f796a9 skipped: already exists
Copying blob bb13d92caffa skipped: already exists
Copying blob 6785f5392033 done
Copying config 6b5d26d612 done
Writing manifest to image destination
Storing signatures
6b5d26d6121c9877b7502a1f1dc433cc5f4d5ffc762dcc8c3da525c5d3bf893a

(undercloud) [stack@undercloud ~]$ sudo cat /var/lib/mistral/overcloud/ansible.log | grep failed 
...
        "overcloud-cephstorage-0    : ok=129  changed=6    unreachable=0    failed=0    skipped=215  rescued=0    ignored=0   ",
        "overcloud-cephstorage-1    : ok=119  changed=4    unreachable=0    failed=0    skipped=207  rescued=0    ignored=0   ",
        "overcloud-cephstorage-2    : ok=120  changed=4    unreachable=0    failed=1    skipped=205  rescued=0    ignored=0   ",
        "overcloud-controller-0     : ok=199  changed=10   unreachable=0    failed=0    skipped=269  rescued=0    ignored=0   ",
        "overcloud-controller-1     : ok=170  changed=6    unreachable=0    failed=0    skipped=247  rescued=0    ignored=0   ",
        "overcloud-controller-2     : ok=170  changed=6    unreachable=0    failed=0    skipped=247  rescued=0    ignored=0   ",
        "overcloud-novacompute-0    : ok=48   changed=2    unreachable=0    failed=0    skipped=142  rescued=0    ignored=0   ",
        "overcloud-novacompute-1    : ok=48   changed=2    unreachable=0    failed=0    skipped=142  rescued=0    ignored=0   ",
    "failed_when_result": true
2021-01-13 20:18:37,803 p=120160 u=mistral n=ansible | overcloud-cephstorage-0    : ok=144  changed=42   unreachable=0    failed=0    skipped=263  rescued=0    ignored=0   
2021-01-13 20:18:37,803 p=120160 u=mistral n=ansible | overcloud-cephstorage-1    : ok=141  changed=42   unreachable=0    failed=0    skipped=263  rescued=0    ignored=0   
2021-01-13 20:18:37,803 p=120160 u=mistral n=ansible | overcloud-cephstorage-2    : ok=141  changed=42   unreachable=0    failed=0    skipped=263  rescued=0    ignored=0   
2021-01-13 20:18:37,803 p=120160 u=mistral n=ansible | overcloud-controller-0     : ok=199  changed=82   unreachable=0    failed=0    skipped=244  rescued=0    ignored=0   
2021-01-13 20:18:37,804 p=120160 u=mistral n=ansible | overcloud-controller-1     : ok=193  changed=82   unreachable=0    failed=0    skipped=240  rescued=0    ignored=0   
2021-01-13 20:18:37,804 p=120160 u=mistral n=ansible | overcloud-controller-2     : ok=193  changed=82   unreachable=0    failed=0    skipped=240  rescued=0    ignored=0   
2021-01-13 20:18:37,804 p=120160 u=mistral n=ansible | overcloud-novacompute-0    : ok=173  changed=58   unreachable=0    failed=0    skipped=240  rescued=0    ignored=0   
2021-01-13 20:18:37,804 p=120160 u=mistral n=ansible | overcloud-novacompute-1    : ok=173  changed=58   unreachable=0    failed=0    skipped=240  rescued=0    ignored=0   
2021-01-13 20:18:37,805 p=120160 u=mistral n=ansible | undercloud                 : ok=92   changed=15   unreachable=0    failed=1    skipped=39   rescued=0    ignored=0   

(undercloud) [stack@undercloud ~]$ sudo cat /var/lib/mistral/overcloud/ansible.log | grep overcloud-cephstorage-2 | grep "fatal: "  | more
        "fatal: [overcloud-cephstorage-2 -> 192.0.2.23]: FAILED! => {\"attempts\": 60, \"changed\": false, \"cmd\": [\"podman\", \"exec\", \"ceph-mon-overcloud-contro
ller-0\", \"ceph\", \"--cluster\", \"ceph\", \"-s\", \"-f\", \"json\"], \"delta\": \"0:00:01.723454\", \"end\": \"2021-01-13 12:18:31.911859\", \"rc\": 0, \"start\": 
\"2021-01-13 12:18:30.188405\", \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"\\n{\\\"fsid\\\":\\\"a20d5cc1-4aca-4ebb-8d50-4dc85d463817\\\",\\\"health\\\":{\\
\"checks\\\":{\\\"TOO_FEW_OSDS\\\":{\\\"severity\\\":\\\"HEALTH_WARN\\\",\\\"summary\\\":{\\\"message\\\":\\\"OSD count 0 < osd_pool_default_size 3\\\"}}},\\\"status\
\\":\\\"HEALTH_WARN\\\"},\\\"election_epoch\\\":8,\\\"quorum\\\":[0,1,2],\\\"quorum_names\\\":[\\\"overcloud-controller-2\\\",\\\"overcloud-controller-0\\\",\\\"overc
loud-controller-1\\\"],\\\"quorum_age\\\":18375,\\\"monmap\\\":{\\\"epoch\\\":1,\\\"fsid\\\":\\\"a20d5cc1-4aca-4ebb-8d50-4dc85d463817\\\",\\\"modified\\\":\\\"2021-01
-13 07:11:54.980500\\\",\\\"created\\\":\\\"2021-01-13 07:11:54.980500\\\",\\\"min_mon_release\\\":14,\\\"min_mon_release_name\\\":\\\"nautilus\\\",\\\"election_strat
egy\\\":1,\\\"disallowed_leaders: \\\":\\\"\\\",\\\"stretch_mode\\\":false,\\\"features\\\":{\\\"persistent\\\":[\\\"kraken\\\",\\\"luminous\\\",\\\"mimic\\\",\\\"osd
map-prune\\\",\\\"nautilus\\\",\\\"elector-pinging\\\"],\\\"optional\\\":[]},\\\"mons\\\":[{\\\"rank\\\":0,\\\"name\\\":\\\"overcloud-controller-2\\\",\\\"public_addr
s\\\":{\\\"addrvec\\\":[{\\\"type\\\":\\\"v2\\\",\\\"addr\\\":\\\"172.16.1.58:3300\\\",\\\"nonce\\\":0},{\\\"type\\\":\\\"v1\\\",\\\"addr\\\":\\\"172.16.1.58:6789\\\"
,\\\"nonce\\\":0}]},\\\"addr\\\":\\\"172.16.1.58:6789/0\\\",\\\"public_addr\\\":\\\"172.16.1.58:6789/0\\\",\\\"crush_location\\\":\\\"{}\\\"},{\\\"rank\\\":1,\\\"name
\\\":\\\"overcloud-controller-0\\\",\\\"public_addrs\\\":{\\\"addrvec\\\":[{\\\"type\\\":\\\"v2\\\",\\\"addr\\\":\\\"172.16.1.185:3300\\\",\\\"nonce\\\":0},{\\\"type\
\\":\\\"v1\\\",\\\"addr\\\":\\\"172.16.1.185:6789\\\",\\\"nonce\\\":0}]},\\\"addr\\\":\\\"172.16.1.185:6789/0\\\",\\\"public_addr\\\":\\\"172.16.1.185:6789/0\\\",\\\"
crush_location\\\":\\\"{}\\\"},{\\\"rank\\\":2,\\\"name\\\":\\\"overcloud-controller-1\\\",\\\"public_addrs\\\":{\\\"addrvec\\\":[{\\\"type\\\":\\\"v2\\\",\\\"addr\\\
":\\\"172.16.1.223:3300\\\",\\\"nonce\\\":0},{\\\"type\\\":\\\"v1\\\",\\\"addr\\\":\\\"172.16.1.223:6789\\\",\\\"nonce\\\":0}]},\\\"addr\\\":\\\"172.16.1.223:6789/0\\
\",\\\"public_addr\\\":\\\"172.16.1.223:6789/0\\\",\\\"crush_location\\\":\\\"{}\\\"}]},\\\"osdmap\\\":{\\\"osdmap\\\":{\\\"epoch\\\":5,\\\"num_osds\\\":0,\\\"num_up_
osds\\\":0,\\\"num_in_osds\\\":0,\\\"num_remapped_pgs\\\":0}},\\\"pgmap\\\":{\\\"pgs_by_state\\\":[],\\\"num_pgs\\\":0,\\\"num_pools\\\":0,\\\"num_objects\\\":0,\\\"d
ata_bytes\\\":0,\\\"bytes_used\\\":0,\\\"bytes_avail\\\":0,\\\"bytes_total\\\":0},\\\"fsmap\\\":{\\\"epoch\\\":1,\\\"by_rank\\\":[],\\\"up:standby\\\":0},\\\"mgrmap\\
\":{\\\"epoch\\\":3,\\\"active_gid\\\":4270,\\\"active_name\\\":\\\"overcloud-controller-0\\\",\\\"active_addrs\\\":{\\\"addrvec\\\":[{\\\"type\\\":\\\"v2\\\",\\\"add
r\\\":\\\"172.16.1.185:6800\\\",\\\"nonce\\\":57},{\\\"type\\\":\\\"v1\\\",\\\"addr\\\":\\\"172.16.1.185:6801\\\",\\\"nonce\\\":57}]},\\\"active_addr\\\":\\\"172.16.1
.185:6801/57\\\",\\\"active_change\\\":\\\"2021-01-13 07:14:36.479167\\\",\\\"available\\\":true,\\\"standbys\\\":[{\\\"gid\\\":4284,\\\"name\\\":\\\"overcloud-contro
ller-2\\\",\\\"available_modules\\\":[{\\\"name\\\":\\\"alerts\\\",\\\"can_run\\\":true,\\\"error_string\\\":\\\"\\\",\\\"module_options\\\":{\\\"interval\\\":{\\\"na
me\\\":\\\"interval\\\",\\\"type\\\":\\\"secs\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"60\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\
"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"How frequently to reexamine health status\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_
destination\\\":{\\\"name\\\":\\\"smtp_destination\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"\\\",\\\"min\
\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"Email address to send alerts to\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also
\\\":[]},\\\"smtp_from_name\\\":{\\\"name\\\":\\\"smtp_from_name\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\
"Ceph\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"Email From: name\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_a
lso\\\":[]},\\\"smtp_host\\\":{\\\"name\\\":\\\"smtp_host\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"\\\",\
\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"SMTP server\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"
smtp_password\\\":{\\\"name\\\":\\\"smtp_password\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"\\\",\\\"min\\
\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"Password to authenticate with\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\
":[]},\\\"smtp_port\\\":{\\\"name\\\":\\\"smtp_port\\\",\\\"type\\\":\\\"int\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"465\\\",\\\"
min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"SMTP port\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_
sender\\\":{\\\"name\\\":\\\"smtp_sender\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"\\\",\\\"min\\\":\\\"\\
\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"SMTP envelope sender\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\"smtp_ssl
\\\":{\\\"name\\\":\\\"smtp_ssl\\\",\\\"type\\\":\\\"bool\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"True\\\",\\\"min\\\":\\\"\\\",\
\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"Use SSL to connect to SMTP server\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]},\\\
"smtp_user\\\":{\\\"name\\\":\\\"smtp_user\\\",\\\"type\\\":\\\"str\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":1,\\\"default_value\\\":\\\"\\\",\\\"min\\\":\\\"
\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\\"User to authenticate as\\\",\\\"long_desc\\\":\\\"\\\",\\\"tags\\\":[],\\\"see_also\\\":[]}}},{\\\"
name\\\":\\\"ansible\\\",\\\"can_run\\\":true,\\\"error_string\\\":\\\"\\\",\\\"module_options\\\":{\\\"password\\\":{\\\"name\\\":\\\"password\\\",\\\"type\\\":\\\"s
tr\\\",\\\"level\\\":\\\"advanced\\\",\\\"flags\\\":0,\\\"default_value\\\":\\\"\\\",\\\"min\\\":\\\"\\\",\\\"max\\\":\\\"\\\",\\\"enum_allowed\\\":[],\\\"desc\\\":\\


(undercloud) [stack@undercloud ~]$ ssh heat-admin@192.0.2.9 sudo podman exec -it ceph-mon-overcloud-controller-1 ceph status
Warning: Permanently added '192.0.2.9' (ECDSA) to the list of known hosts.
  cluster:
    id:     a20d5cc1-4aca-4ebb-8d50-4dc85d463817
    health: HEALTH_WARN
            OSD count 0 < osd_pool_default_size 3

  services:
    mon: 3 daemons, quorum overcloud-controller-2,overcloud-controller-0,overcloud-controller-1 (age 6h)
    mgr: overcloud-controller-0(active, since 6h), standbys: overcloud-controller-2, overcloud-controller-1
    osd: 0 osds: 0 up, 0 in

  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   0 B used, 0 B / 0 B avail
    pgs:


(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+-------------------------+--------+---------------------+----------------+-----------+
| ID                                   | Name                    | Status | Networks            | Image          | Flavor    |
+--------------------------------------+-------------------------+--------+---------------------+----------------+-----------+
| 5f13d981-5dc7-4445-90c8-59d27cfc3f11 | overcloud-controller-0  | ACTIVE | ctlplane=192.0.2.22 | overcloud-full | baremetal |
| 45e16cb0-2c85-4500-b6eb-cd5e86897184 | overcloud-controller-2  | ACTIVE | ctlplane=192.0.2.14 | overcloud-full | baremetal |
| 522f2254-bd11-468d-9df3-e6602ad19d3c | overcloud-controller-1  | ACTIVE | ctlplane=192.0.2.10 | overcloud-full | baremetal |
| 55a8d5d1-d2f5-420a-9ed0-15ce47fc5947 | overcloud-novacompute-0 | ACTIVE | ctlplane=192.0.2.11 | overcloud-full | baremetal |
| 9bfa235b-cd5c-4929-a5c9-5a32c1ff3071 | overcloud-novacompute-1 | ACTIVE | ctlplane=192.0.2.12 | overcloud-full | baremetal |
| 415435a7-2988-411b-85cd-4cb165f3e57c | overcloud-cephstorage-1 | ACTIVE | ctlplane=192.0.2.18 | overcloud-full | baremetal |
| 715d5e7a-14e1-4a91-af02-37f31b488381 | overcloud-cephstorage-2 | ACTIVE | ctlplane=192.0.2.8  | overcloud-full | baremetal |
| 36b768b9-8ee8-4b03-8858-951f38957db8 | overcloud-cephstorage-0 | ACTIVE | ctlplane=192.0.2.15 | overcloud-full | baremetal |
+--------------------------------------+-------------------------+--------+---------------------+----------------+-----------+

Jan 14 16:58:46 overcloud-cephstorage-2 systemd[1]: ceph-osd@2.service: Main process exited, code=exited, status=1/FAILURE
Jan 14 16:58:46 overcloud-cephstorage-2 systemd[1]: ceph-osd@2.service: Failed with result 'exit-code'.
Jan 14 16:58:47 overcloud-cephstorage-2 systemd[1]: ceph-osd@8.service: Service RestartSec=10s expired, scheduling restart.
Jan 14 16:58:47 overcloud-cephstorage-2 systemd[1]: ceph-osd@8.service: Scheduled restart job, restart counter is at 1.
Jan 14 16:58:47 overcloud-cephstorage-2 podman[19320]: Error: Failed to evict container: "": Failed to find container "ceph-osd-8" in st
ate: no container with name or ID ceph-osd-8 found: no such container

Jan 14 16:58:57 overcloud-cephstorage-2 podman[19550]: 2021-01-14 16:58:57.202005292 +0000 UTC m=+0.191512529 container create 3323392dc
2ba53c7f5dddd15648b21556d930b2239e757c3ddac3e2cefe80d10 (image=undercloud.ctlplane.localdomain:8787/rhceph/rhceph-4-rhel8:latest, name=ceph-osd-2)
Jan 14 16:58:57 overcloud-cephstorage-2 podman[19550]: 2021-01-14 16:58:57.382088661 +0000 UTC m=+0.371595880 container init 3323392dc2b
a53c7f5dddd15648b21556d930b2239e757c3ddac3e2cefe80d10 (image=undercloud.ctlplane.localdomain:8787/rhceph/rhceph-4-rhel8:latest, name=ceph-osd-2)
Jan 14 16:58:57 overcloud-cephstorage-2 podman[19550]: 2021-01-14 16:58:57.408954708 +0000 UTC m=+0.398461937 container start 3323392dc2
ba53c7f5dddd15648b21556d930b2239e757c3ddac3e2cefe80d10 (image=undercloud.ctlplane.localdomain:8787/rhceph/rhceph-4-rhel8:latest, name=ceph-osd-2)
Jan 14 16:58:58 overcloud-cephstorage-2 systemd[1]: ceph-osd@5.service: Service RestartSec=10s expired, scheduling restart.
Jan 14 16:58:58 overcloud-cephstorage-2 systemd[1]: ceph-osd@5.service: Scheduled restart job, restart counter is at 2.
Jan 14 16:58:58 overcloud-cephstorage-2 podman[19657]: Error: Failed to evict container: "": Failed to find container "ceph-osd-5" in state: no container with name or ID ceph-osd-5 found: no such container
Jan 14 16:58:59 overcloud-cephstorage-2 podman[19667]: 2021-01-14 16:58:59.162784085 +0000 UTC m=+0.181366620 container create 2c1dc27c12687000b186a71c870d0613c032965b42eae03f7b50ea3fceccde92 (image=undercloud.ctlplane.localdomain:8787/rhceph/rhceph-4-rhel8:latest, name=ceph-osd-5)
Jan 14 16:58:59 overcloud-cephstorage-2 podman[19667]: 2021-01-14 16:58:59.393928331 +0000 UTC m=+0.412510872 container init 2c1dc27c126
87000b186a71c870d0613c032965b42eae03f7b50ea3fceccde92 (image=undercloud.ctlplane.localdomain:8787/rhceph/rhceph-4-rhel8:latest, name=ceph-osd-5)
Jan 14 16:58:59 overcloud-cephstorage-2 podman[19667]: 2021-01-14 16:58:59.424525557 +0000 UTC m=+0.443108087 container start 2c1dc27c12687000b186a71c870d0613c032965b42eae03f7b50ea3fceccde92 (image=undercloud.ctlplane.localdomain:8787/rhceph/rhceph-4-rhel8:latest, name=ceph-osd-5)
Jan 14 16:59:00 overcloud-cephstorage-2 podman[19781]: 2021-01-14 16:59:00.050705915 +0000 UTC m=+0.154419571 container died 3323392dc2ba53c7f5dddd15648b21556d930b2239e757c3ddac3e2cefe80d10 (image=undercloud.ctlplane.localdomain:8787/rhceph/rhceph-4-rhel8:latest, name=ceph-osd-2)
Jan 14 16:59:00 overcloud-cephstorage-2 systemd[1]: ceph-osd@8.service: Service RestartSec=10s expired, scheduling restart.
Jan 14 16:59:00 overcloud-cephstorage-2 systemd[1]: ceph-osd@8.service: Scheduled restart job, restart counter is at 2.
Jan 14 16:59:00 overcloud-cephstorage-2 podman[19781]: 2021-01-14 16:59:00.125046404 +0000 UTC m=+0.228760028 container remove 3323392dc2ba53c7f5dddd15648b21556d930b2239e757c3ddac3e2cefe80d10 (image=undercloud.ctlplane.localdomain:8787/rhceph/rhceph-4-rhel8:latest, name=ceph-osd-2)
Jan 14 16:59:00 overcloud-cephstorage-2 systemd[1]: ceph-osd@2.service: Main process exited, code=exited, status=1/FAILURE
Jan 14 16:59:00 overcloud-cephstorage-2 systemd[1]: ceph-osd@2.service: Failed with result 'exit-code'.
Jan 14 16:59:00 overcloud-cephstorage-2 podman[19793]: Error: Failed to evict container: "": Failed to find container "ceph-osd-8" in st
ate: no container with name or ID ceph-osd-8 found: no such container
Jan 14 16:59:00 overcloud-cephstorage-2 podman[19819]: 2021-01-14 16:59:00.488409559 +0000 UTC m=+0.191534068 container create 3c7cd4832
30e37951cb0bfbef43134242fa4c289371f8fd0b77caec79fd4d36f (image=undercloud.ctlplane.localdomain:8787/rhceph/rhceph-4-rhel8:latest, name=c
eph-osd-8)
Jan 14 16:59:00 overcloud-cephstorage-2 podman[19819]: 2021-01-14 16:59:00.720478003 +0000 UTC m=+0.423602485 container init 3c7cd483230
e37951cb0bfbef43134242fa4c289371f8fd0b77caec79fd4d36f (image=undercloud.ctlplane.localdomain:8787/rhceph/rhceph-4-rhel8:latest, name=ceph-osd-8)

http://pastebin.test.redhat.com/931605

```



### 导入 docker registry 镜像
https://www.mankier.com/1/podman-save
```
# 保存 docker-registry 镜像到 tar 文件
podman save --format docker-dir -o docker-registry docker.io/library/registry:2
tar cvf podman-docker-registry-v2.tar docker-registry/

# 在无法访问 docker.io 的环境里上传并且解压缩这个 tar 文件
tar xvf podman-docker-registry-v2.tar
podman load -i docker-registry

# 查看目标环境里的本地 images 
podman images
REPOSITORY                                                   TAG      IMAGE ID       CREATED         SIZE
localhost/docker-registry                                    latest   678dfa38fcfa   3 weeks ago     26.8 MB
```



### 在 helper 上建立本地 docker registry
```
yum -y install podman httpd httpd-tools wget jq

mkdir -p /opt/registry/{auth,certs,data}

cd /opt/registry/certs

openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 3650 -out domain.crt  -subj "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT Department/CN=*.example.com"

cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

htpasswd -bBc /opt/registry/auth/htpasswd dummy dummy

firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public   --permanent
firewall-cmd --add-service=http  --permanent
firewall-cmd --reload

# 在 helper 上导入 docker-registry 镜像

cat > /usr/local/bin/localregistry.sh << 'EOF'
#!/bin/bash
podman run --name poc-registry -d -p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/auth:/auth:z \
-e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry" \
-e "REGISTRY_HTTP_SECRET=ALongRandomSecretForRegistry" \
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
-v /opt/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
localhost/docker-registry:latest 
EOF

# 经实际验证 tripleo 与这种认证方式不兼容
# 因此在创建为 tripleo 工作的 registry 时，可取消认证部分
cat > /usr/local/bin/localregistry.sh << 'EOF'
#!/bin/bash
podman run --name poc-registry -d -p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
localhost/docker-registry:latest 
EOF

chmod +x /usr/local/bin/localregistry.sh

/usr/local/bin/localregistry.sh

curl -u dummy:dummy https://helper.example.com:5000/v2/_catalog

# 添加 undercloud.example.com 到 /etc/hosts
cat >> /etc/hosts << EOF
192.168.8.21 undercloud.example.com
EOF

scp /opt/registry/certs/domain.crt stack@undercloud.example.com:~
ssh stack@undercloud.example.com sudo cp /home/stack/domain.crt /etc/pki/ca-trust/source/anchors/
ssh stack@undercloud.example.com sudo update-ca-trust extract

# 在 undercloud 上添加 helper 的 hosts 记录
ssh stack@undercloud.example.com 
sudo -i
cat >> /etc/hosts << EOF

192.168.8.20 helper.example.com
EOF

curl -u dummy:dummy https://helper.example.com:5000/v2/_catalog
exit

# 在 helper 上安装 skopeo 
yum install -y skopeo

# 在 helper 上 login 到 registry.redhat.io 和 helper.example.com:5000
podman login registry.redhat.io

podman login helper.example.com:5000


cat > /usr/local/bin/syncimgs << 'EOF'
#!/bin/env bash

PUSHREGISTRY=helper.example.com:5000
FORK=4

rhosp_namespace=registry.redhat.io/rhosp-rhel8
rhosp_tag=16.1
ceph_namespace=registry.redhat.io/rhceph
ceph_image=rhceph-4-rhel8
ceph_tag=latest
ceph_alertmanager_namespace=registry.redhat.io/openshift4
ceph_alertmanager_image=ose-prometheus-alertmanager
ceph_alertmanager_tag=4.1
ceph_grafana_namespace=registry.redhat.io/rhceph
ceph_grafana_image=rhceph-4-dashboard-rhel8
ceph_grafana_tag=4
ceph_node_exporter_namespace=registry.redhat.io/openshift4
ceph_node_exporter_image=ose-prometheus-node-exporter
ceph_node_exporter_tag=v4.1
ceph_prometheus_namespace=registry.redhat.io/openshift4
ceph_prometheus_image=ose-prometheus
ceph_prometheus_tag=4.1

function copyimg() {
  image=${1}
  version=${2}

  release=$(skopeo inspect docker://${image}:${version} | jq -r '.Labels | (.version + "-" + .release)')
  dest="${PUSHREGISTRY}/${image#*\/}"
  echo Copying ${image} to ${dest}
  skopeo copy --format v2s2 docker://${image}:${release} docker://${dest}:${release}
  skopeo copy --format v2s2 docker://${image}:${version} docker://${dest}:${version}
}

copyimg "${ceph_namespace}/${ceph_image}" ${ceph_tag} &
copyimg "${ceph_alertmanager_namespace}/${ceph_alertmanager_image}" ${ceph_alertmanager_tag} &
copyimg "${ceph_grafana_namespace}/${ceph_grafana_image}" ${ceph_grafana_tag} &
copyimg "${ceph_node_exporter_namespace}/${ceph_node_exporter_image}" ${ceph_node_exporter_tag} &
copyimg "${ceph_prometheus_namespace}/${ceph_prometheus_image}" ${ceph_prometheus_tag} &
wait

for rhosp_image in $(podman search ${rhosp_namespace} --limit 1000 --format "{{ .Name }}"); do
  ((i=i%FORK)); ((i++==0)) && wait
  copyimg ${rhosp_image} ${rhosp_tag} &
done
EOF


```



### example containers-prepare-parameter.yaml
```
cat containers-prepare-parameter.yaml
# Generated with the following on 2021-01-09T20:42:45.969201
#
#   openstack tripleo container image prepare default --local-push-destination --output-env-file containers-prepare-parameter.yaml
#

parameter_defaults:
  ContainerImagePrepare:
  - push_destination: true
    set:
      ceph_alertmanager_image: ose-prometheus-alertmanager
      ceph_alertmanager_namespace: helper.example.com:5000/openshift4
      ceph_alertmanager_tag: 4.1
      ceph_grafana_image: rhceph-4-dashboard-rhel8
      ceph_grafana_namespace: helper.example.com:5000/rhceph
      ceph_grafana_tag: 4
      ceph_image: rhceph-4-rhel8
      ceph_namespace: helper.example.com:5000/rhceph
      ceph_node_exporter_image: ose-prometheus-node-exporter
      ceph_node_exporter_namespace: helper.example.com:5000/openshift4
      ceph_node_exporter_tag: v4.1
      ceph_prometheus_image: ose-prometheus
      ceph_prometheus_namespace: helper.example.com:5000/openshift4
      ceph_prometheus_tag: 4.1
      ceph_tag: latest
      name_prefix: openstack-
      name_suffix: ''
      namespace: helper.example.com:5000/rhosp-rhel8
      neutron_driver: ovn
      rhel_containers: false
      tag: '16.1'
    tag_from_label: '{version}-{release}'
  ContainerImageRegistryCredentials:
    'helper.example.com:5000':
      dummy: dummy
  DockerInsecureRegistryAddress:
    - helper.example.com:5000
```



### install tar on rhel8.2 with rhel 8.2 iso
```
mount -o loop /dev/sr0 /mnt
cat > /etc/yum.repos.d/local.repo << EOF
[baseos]
name=baseos
baseurl=file:///mnt/BaseOS
enabled=1
gpgcheck=0

[appstream]
name=appstream
baseurl=file:///mnt/AppStream
enabled=1
gpgcheck=0
EOF

yum install -y tar

```


### network manager 设置 vlan 类型连接，将 ip 地址设置在此连接上
```
nmcli con add type vlan con-name ens3-vlan-12 dev ens3 id 12
nmcli con mod ens3-vlan-12 \
    connection.autoconnect 'yes'
    ipv4.method 'manual' \
    ipv4.address '10.66.208.237/24' \
    ipv4.gateway '10.66.208.254' \
    ipv4.dns '10.64.63.6'
```



### osp16.1 生成本地 yum repo 文件
```
 
> /etc/yum.repos.d/osp.repo 

for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms
do
cat >> /etc/yum.repos.d/osp.repo << EOF
[$i]
name=$i
baseurl=file:///var/www/html/repos/osp16.1/$i/
enabled=1
gpgcheck=0

EOF
done
```


### 安装 helper 虚拟机
参考以下链接
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-network_bridging_using_the_networkmanager_command_line_tool_nmcli

参考以下链接
https://medium.com/@kbidarkar/configuring-bridges-and-vlans-using-nmcli-8cb79f45d3a6

创建网桥并且附加 vlan interface 

```
# 创建 bridge 类型的 conn br0
nmcli con add type bridge con-name br0 ifname br0
# (可选) 根据实际情况设置 bridge.stp，有时可能因为 bridge.stp 设置导致网络通信不正常
nmcli con mod br0 bridge.stp no

# 创建 vlan 类型的 conn ens3.12 设置 master 为 br0 
nmcli con add type vlan con-name ens3.12 dev ens3 id 12 master br0 connection.autoconnect 'yes'

# 为 br0 设置 ip 地址
nmcli con mod br0 \
    connection.autoconnect 'yes'
    ipv4.method 'manual' \
    ipv4.address '10.66.208.237/24' \
    ipv4.gateway '10.66.208.254' \
    ipv4.dns '10.64.63.6'

定义 libvirt network ，使用 host birdge

# 创建新的 libvirt network br0
cat << EOF > /root/host-bridge.xml
<network>
  <name>br0</name>
  <forward mode="bridge"/>
  <bridge name="br0"/>
</network>
EOF

virsh net-define /root/host-bridge.xml
virsh net-start br0
virsh net-autostart --network br0

virt-install --name=jwang-helper-undercloud --vcpus=4 --ram=32768 --disk path=/data/kvm/jwang-helper-undercloud.qcow2,bus=virtio,size=100 --os-variant rhel8.0 --network network=openshift4v6,model=virtio --boot menu=on --location /root/jwang/isos/rhel-8.2-x86_64-dvd.iso --graphics none --initrd-inject /tmp/ks-helper.cfg --extra-args='ks=file:/ks-helper.cfg console=ttyS0'

virt-install --name=jwang-rhel83-rhvm --vcpus=2 --ram=4096 --disk path=/data/kvm/jwang-rhel83-rhvm.qcow2,bus=virtio,size=120 --os-variant rhel8.0 --network network=default,model=virtio --boot menu=on --graphics none --location  /root/jwang/isos/rhel-8.3-x86_64-dvd.iso --initrd-inject /tmp/ks-helper.cfg --extra-args='ks=file:/ks-helper.cfg console=ttyS0 ip=192.168.122.152::192.168.122.1:255.255.255.0:rhvm.rhcnsa.org:ens3:none'
```


### 使用 ipmitool 控制节点电源状态
https://linux.die.net/man/1/ipmitool
```
# 检查节点的电源状态 
time ipmitool -I lanplus -H 172.16.0.95 -L ADMINISTRATOR -p 6232 -U admin power status

# 打开节点电源
time ipmitool -I lanplus -H 172.16.0.95 -L ADMINISTRATOR -p 6232 -U admin power on

# 关闭节点电源
time ipmitool -I lanplus -H 172.16.0.95 -L ADMINISTRATOR -p 6232 -U admin power off
```


### 为节点设置 Tag 
```
openstack baremetal node set --property capabilities='node:controller-0,boot_option:local' overcloud-ctrl01
openstack baremetal node set --property capabilities='node:controller-1,boot_option:local' overcloud-ctrl02
openstack baremetal node set --property capabilities='node:controller-2,boot_option:local' overcloud-ctrl03

openstack baremetal node set --property capabilities='node:compute-0,boot_option:local' overcloud-compute01
openstack baremetal node set --property capabilities='node:compute-1,boot_option:local' overcloud-compute02

openstack baremetal node set --property capabilities='node:cephstorage-0,boot_option:local' overcloud-ceph01
openstack baremetal node set --property capabilities='node:cephstorage-1,boot_option:local' overcloud-ceph02
openstack baremetal node set --property capabilities='node:cephstorage-2,boot_option:local' overcloud-ceph03
```



### overcloud deploy 报错信息
```
UnicodeEncodeError: 'ascii' codec can't encode character '\u2192' in position 1171: ordinal not in range(128)

# 目前怀疑需要在 undercloud 的 bash 里设置 LC_ALL=en_US.UTF-8
export LC_ALL=en_US.UTF-8


cat /var/lib/mistral/overcloud/ansible.log | grep "fatal: " -A3000  | grep -Ev "ok: |skipping: |changed: " | grep "failed: " 
        "failed: [overcloud-cephstorage-2 -> 192.0.2.16] (item=[{'application': 'rbd', 'name': 'images', 'pg_num': '128', 'rule_name': 'replicated_rule'}, {'msg': 'non-zero return code', 'cmd': ['podman', 'exec', 'ceph-mon-overcloud-controller-0', 'ceph', '--cluster', 'ceph', 'osd', 'pool', 'get', 'images', 'size'], 'stdout': '', 'stderr': \"Error ENOENT: unrecognized pool 'images'\\nError: non zero exit code: 2: OCI runtime error\", 'rc': 2, 'start': '2021-01-18 14:09:45.192952', 'end': '2021-01-18 14:09:46.650698', 'delta': '0:00:01.457746', 'changed': False, 'failed': False, 'invocation': {'module_args': {'_raw_params': 'podman exec ceph-mon-overcloud-controller-0 ceph --cluster ceph osd pool get images size\\n', 'warn': True, '_uses_shell': False, 'stdin_add_newline': True, 'strip_empty_ends': True, 'argv': None, 'chdir': None, 'executable': None, 'creates': None, 'removes': None, 'stdin': None}}, 'stdout_lines': [], 'stderr_lines': [\"Error ENOENT: unrecognized pool 'images'\", 'Error: non zero exit code: 2: OCI runtime error'], 'failed_when_result': False, 'item': {'application': 'rbd', 'name': 'images', 'pg_num': '128', 'rule_name': 'replicated_rule'}, 'ansible_loop_var': 'item'}]) => {\"ansible_loop_var\": \"item\", \"changed\": false, \"cmd\": [\"podman\", \"exec\", \"ceph-mon-overcloud-controller-0\", \"ceph\", \"--cluster\", \"ceph\", \"osd\", \"pool\", \"create\", \"images\", \"128\", \"128\", \"replicated\", \"replicated_rule\", \"0\"], \"delta\": \"0:00:02.779611\", \"end\": \"2021-01-18 14:09:57.253992\", \"item\": [{\"application\": \"rbd\", \"name\": \"images\", \"pg_num\": \"128\", \"rule_name\": \"replicated_rule\"}, {\"ansible_loop_var\": \"item\", \"changed\": false, \"cmd\": [\"podman\", \"exec\", \"ceph-mon-overcloud-controller-0\", \"ceph\", \"--cluster\", \"ceph\", \"osd\", \"pool\", \"get\", \"images\", \"size\"], \"delta\": \"0:00:01.457746\", \"end\": \"2021-01-18 14:09:46.650698\", \"failed\": false, \"failed_when_result\": false, \"invocation\": {\"module_args\": {\"_raw_params\": \"podman exec ceph-mon-overcloud-controller-0 ceph --cluster ceph osd pool get images size\\n\", \"_uses_shell\": false, \"argv\": null, \"chdir\": null, \"creates\": null, \"executable\": null, \"removes\": null, \"stdin\": null, \"stdin_add_newline\": true, \"strip_empty_ends\": true, \"warn\": true}}, \"item\": {\"application\": \"rbd\", \"name\": \"images\", \"pg_num\": \"128\", \"rule_name\": \"replicated_rule\"}, \"msg\": \"non-zero return code\", \"rc\": 2, \"start\": \"2021-01-18 14:09:45.192952\", \"stderr\": \"Error ENOENT: unrecognized pool 'images'\\nError: non zero exit code: 2: OCI runtime error\", \"stderr_lines\": [\"Error ENOENT: unrecognized pool 'images'\", \"Error: non zero exit code: 2: OCI runtime error\"], \"stdout\": \"\", \"stdout_lines\": []}], \"msg\": \"non-zero return code\", \"rc\": 34, \"start\": \"2021-01-18 14:09:54.474381\", \"stderr\": \"Error ERANGE:  pg_num 128 size 3 would mean 1152 total pgs, which exceeds max 900 (mon_max_pg_per_osd 300 * num_in_osds 3)\\nError: non zero exit code: 34: OCI runtime error\", \"stderr_lines\": [\"Error ERANGE:  pg_num 128 size 3 would mean 1152 total pgs, which exceeds max 900 (mon_max_pg_per_osd 300 * num_in_osds 3)\", \"Error: non zero exit code: 34: OCI runtime error\"], \"stdout\": \"\", \"stdout_lines\": []}",


报错信息为: 
Error ERANGE:  pg_num 128 size 3 would mean 1152 total pgs, which exceeds max 900 (mon_max_pg_per_osd 300 * num_in_osds 3)\\nError: non zero exit code: 34: OCI runtime error\

解决方法为调大：
mon_max_pg_per_osd


grep $(python3 -c 'print(u"\u2192")') ~/templates/network_data.yaml

# 检查当前目录下有哪些文件包含非 ASCII 字符
LC_ALL=C grep -l '[^[:print:]]' * -r 
images/overcloud-full.qcow2
images/overcloud-full.initrd
images/overcloud-full.vmlinuz
images/ironic-python-agent.initramfs
images/ironic-python-agent.kernel
nohup.out
osp16.1-yum-repos-2021-01-15.tar.gz
rendered/container_config_scripts/pacemaker_restart_bundle.sh
rendered/container_config_scripts/pacemaker_wait_bundle.sh
undercloud-install-20210118071347.tar.bzip2
undercloud-install-20210118080102.tar.bzip2

# 检查当前目录下有哪些文件包含非 ASCII 字符
LC_ALL=C find . -type f -exec  grep -l '[^[:print:]]' {} \;

# 检查文件里具体哪行包含非 ASCII 字符
LC_ALL=C grep -Hn '[^[:print:]]' ~/.bash_profile

# 打印文件第 5 行
sed -n 5p .bash_profile 

# 找到文件里是否包含特殊字符
grep "$(printf %b '\u2192')" filename

# 查看哪个文件包含字符 \u2192 
grep -r  $'\u2192' * 
```


### TripleO service deployment steps
https://jaosorior.dev/2018/tripleo-service-deployment-steps/



### 获取 introspection 信息里的磁盘
```
# 根据 introspection 信息查看磁盘
cat overcloud-ceph03.json | jq ".inventory.disks[].by_path" 
```


### 使用 by-path 的 disk 来描述 ceph osd disk
```
cat > ~/templates/cephstorage.yaml
parameter_defaults:
  CephConfigOverrides:
    mon_max_pg_per_osd: 500
  CephAnsibleDiskConfig:
    devices:
      - /dev/disk/by-path/pci-0000:00:09.0
      - /dev/disk/by-path/pci-0000:00:0a.0
      - /dev/disk/by-path/pci-0000:00:0b.0
    osd_scenario: lvm
    osd_objectstore: bluestore
```



### 检查 overcloud 节点时间是否同步
参考: 
https://stackoverflow.com/questions/9393038/ssh-breaks-out-of-while-loop-in-bash

```
# ssh 会把其他内容从标准输入里吃掉
# 可以在 ssh 命令里添加 < /dev/null
(undercloud) [stack@undercloud ~]$ openstack server list -f value -c Networks | awk -F'=' '{print $2}' | while read i ; do echo ssh heat-admin@$i date -u "< /dev/null"  ; echo echo ; done 

#!/bin/bash
ssh heat-admin@192.0.2.8 date -u < /dev/null 
echo
ssh heat-admin@192.0.2.14 date -u 
echo
ssh heat-admin@192.0.2.12 date -u
echo
ssh heat-admin@192.0.2.22 date -u
echo
ssh heat-admin@192.0.2.11 date -u
echo
ssh heat-admin@192.0.2.17 date -u
echo
ssh heat-admin@192.0.2.18 date -u
echo
ssh heat-admin@192.0.2.24 date -u
```


### YAML 的语法
https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html



### install undercloud helper 
```
# 清理磁盘
qemu-img create -f qcow2 /data/kvm/jwang-helper-undercloud.qcow2 100G

# 安装 undercloud helper 虚拟机
# 需要在 extra-args 里提供虚拟机的网络配置
# 配置方法参见
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-configuring_ip_networking_from_the_kernel_command_line
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/system_design_guide/installer-troubleshooting_system-design-guide#ip-boot-option-format-error_troubleshooting-after-installation

# 配置图形环境
virt-install --name=jwang-helper-undercloud --vcpus=2 --ram=4096 --disk path=/data/kvm/jwang-helper-undercloud.qcow2,bus=virtio,size=100 --os-variant rhel8.0 --network network=openshift4v6,model=virtio --boot menu=on --location /root/jwang/isos/rhel-8.2-x86_64-dvd.iso --initrd-inject /tmp/ks-helper.cfg --extra-args='ks=file:/ks-helper.cfg nameserver=192.168.8.1 ip=192.168.8.20::192.168.8.1:255.255.255.0:helper.example.com:ens3:none'

# 不配置图形环境
virt-install --name=jwang-helper-undercloud --vcpus=2 --ram=4096 --disk path=/data/kvm/jwang-helper-undercloud.qcow2,bus=virtio,size=100 --os-variant rhel8.0 --network network=openshift4v6,model=virtio --boot menu=on --graphics none --location /root/jwang/isos/rhel-8.2-x86_64-dvd.iso --initrd-inject /tmp/ks-helper.cfg --extra-args='ks=file:/ks-helper.cfg console=ttyS0 nameserver=192.168.8.1 ip=192.168.8.20::192.168.8.1:255.255.255.0:helper.example.com:ens3:none'

# 删除 undercloud 的 connection ens3 的 ipv4.dns 和设置 ipv6.ignore-auto-dns 为 yes
(undercloud) [stack@undercloud ~]$ sudo nmcli con mod ens3 ipv4.dns '' ipv6.ignore-auto-dns 'yes'

# 查看 arp
(undercloud) [stack@undercloud ~]$ ip neigh | grep 192.168.122.3
192.168.122.3 dev ens12 lladdr 52:54:00:d7:3f:90 STALE

# 安装完 ipa 之后，开放防火墙
https://computingforgeeks.com/how-to-install-and-configure-freeipa-server-on-rhel-centos-8/
firewall-cmd --add-service={http,https,dns,ntp,freeipa-ldap,freeipa-ldaps} --permanent
firewall-cmd --reload

# 部署报错
# tripleoclient.exceptions.ConfigDownloadInProgress: Config download already in progress with execution id 5881cbf1-1058-4833-94a2-2c8bc595adea for stack overcloud
# Bug 1892679 - 'Overcloud Deployed with error' but 'openstack overcloud failures' shows no ansible error log.
```


### ipa server 相关内容
```
卸载 ipa server 
ipa-server-install --uninstall
```


### linux 配置 pptp 客户端
https://linuxconfig.org/how-to-establish-pptp-vpn-client-connection-on-centos-rhel-7-linux
```
# 安装 pptp 客户端
yum install pptp

# 加载内核模块
modprobe nf_conntrack_pptp

# 添加认证信息到 /etc/ppp/chap-secrets 文件
# 其中用户名是 admin 口令是 00000000
echo 'admin PPTP 00000000 *' >> /etc/ppp/chap-secrets

# 生成配置文件
# 服务器地址是 36.110.27.220
mkdir -p /etc/ppp/peers
cat > /etc/ppp/peers/linuxconfig << EOF
pty "pptp 36.110.27.220 --nolaunchpppd"
name wangjun
remotename PPTP
require-mppe-128
file /etc/ppp/options.pptp
ipparam linuxconfig
EOF

# 建立 pptp 连接
pppd call linuxconfig

# 添加到 192.168.10.0/24 的路由
ip route add 192.168.10.0/24 via 36.110.27.220 dev ppp0 proto static metric 21


vncserver :1
firewall-cmd --permanent --add-port=5901/tcp

https://access.redhat.com/solutions/5566011

nf_conntrack: default automatic helper assignment has been turned off for security reasons and CT-based  firewall rule not found. Use the iptables CT target to attach helpers instead.

echo "net.netfilter.nf_conntrack_helper = 1" >> /etc/sysctl.conf
sysctl -p

# 在 Mac 上启动 ftp server
sudo -s launchctl load -w /System/Library/LaunchDaemons/ftp.plist
```



### rhel 8 列出 bridge 信息
```
# 在 rhel 8 上可以用以下命令查看 bridge 的 端口
bridge link show

6: virbr0-nic: <BROADCAST,MULTICAST> mtu 1500 master virbr0 state disabled priority 32 cost 100
15: ens35f1.10@ens35f1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 100
16: vnet0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 100
```


### 问题定位：introspection 失败 
```

 sudo podman logs  ironic_inspector_dnsmasq
...

+ echo 'Running command: '\''/sbin/dnsmasq --conf-file=/etc/ironic-inspector/dnsmasq.conf -k --log-facility=/var/log/ironic-inspector/dnsmasq.log'\'''
Running command: '/sbin/dnsmasq --conf-file=/etc/ironic-inspector/dnsmasq.conf -k --log-facility=/var/log/ironic-inspector/dnsmasq.log'
+ exec /sbin/dnsmasq --conf-file=/etc/ironic-inspector/dnsmasq.conf -k --log-facility=/var/log/ironic-inspector/dnsmasq.log

dnsmasq: failed to bind DHCP server socket: Address already in use

# 禁用 default 网络 autostart
sudo virsh net-autostart --network default --disable
sudo virsh net-destroy default

(undercloud) [stack@undercloud ~]$ sudo systemctl -l | grep ironic | grep dns
● tripleo_ironic_inspector_dnsmasq.service                                                                                             loaded failed     failed          ironic_inspector_dnsmasq container                                     
● tripleo_ironic_inspector_dnsmasq_healthcheck.timer                                                                                   loaded failed     failed          ironic_inspector_dnsmasq container healthcheck  

# 重启  tripleo_ironic_inspector_dnsmasq.service 服务
(undercloud) [stack@undercloud ~]$ sudo systemctl restart  tripleo_ironic_inspector_dnsmasq.service


(undercloud) [stack@undercloud ~]$ sudo systemctl -l | grep ironic | grep dns   tripleo_ironic_inspector_dnsmasq.service                                                                                             loaded active     running         ironic_inspector_dnsmasq container                                       
tripleo_ironic_inspector_dnsmasq_healthcheck.timer                                                                                   loaded active     waiting         ironic_inspector_dnsmasq container healthcheck 


# 处于 clean wait 状态的节点如何重新 introspect
openstack baremetal node abort overcloud-ceph02
openstack baremetal node manage overcloud-ceph02
openstack overcloud node introspect overcloud-ceph02 --provide

for i in $(seq 1 3)
do
   echo overcloud-ctrl0$i properties capabilities
   openstack baremetal node show overcloud-ctrl0$i -f json | jq '.properties.capabilities'
   echo
done

for i in $(seq 1 2)
do
   echo overcloud-compute0$i properties capabilities
   openstack baremetal node show overcloud-compute0$i -f json | jq '.properties.capabilities'
   echo
done

for i in $(seq 1 3)
do
   echo overcloud-ceph0$i properties capabilities
   openstack baremetal node show overcloud-ceph0$i -f json | jq '.properties.capabilities'
   echo
done


openstack tripleo container image list | grep docker | tee /tmp/image-list

# https://bugzilla.redhat.com/show_bug.cgi?id=1804045
sudo openstack tripleo container image push  helper.example.com:5000/rhceph/rhceph-4-rhel8:latest --debug

sudo openstack tripleo container image push  helper.example.com:5000/rhosp-rhel8/openstack-novajoin-notifier:16.1 --debug
sudo openstack tripleo container image push  helper.example.com:5000/rhosp-rhel8/openstack-novajoin-server:16.1 --debug


# 获得用户 client.rgw.overcloud-controller-0.rgw0 的信息
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane.example.com sudo podman exec -it ceph-rgw-overcloud-controller-0-rgw0 ceph auth get client.rgw.overcloud-controller-0.rgw0
Warning: Permanently added 'overcloud-controller-0.ctlplane.example.com' (ECDSA) to the list of known hosts.
exported keyring for client.rgw.overcloud-controller-0.rgw0
[client.rgw.overcloud-controller-0.rgw0]
        key = AQAxQAhg14TWMBAAqe1E59uXimnMQMOpsEOQog==
        caps mon = "allow rw"
        caps osd = "allow rwx"
```



### 问题定位: Feb 21 23:52:30 overcloud-controller-0 podman(haproxy-bundle-podman-0)[548533]: ERROR: Error: error creating container storage: the container name "haproxy-bundle-podman-0" is already in use by "6f4126f77e6ebde7326ffe1b963b31e9dad5590cacbd7ab1d0123b307229dbad". You have to remove that container to be able to reuse that name.: that name is already in use
参考类似问题：<br>
https://github.com/containers/podman/issues/2240
```
[heat-admin@overcloud-controller-0 ~]$ sudo podman ps | grep haproxy
[heat-admin@overcloud-controller-0 ~]$ sudo podman ps -a | grep haproxy
9e419db69633  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-haproxy:16.1                 /pacemaker_restar...  2 weeks ago  Exited (0) 2 weeks ago         haproxy_restart_bundle
a719de11b7e4  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-haproxy:16.1                 /container_puppet...  2 weeks ago  Exited (0) 2 weeks ago         haproxy_init_bundle

# 解决方法是执行命令 podman rm --force --storage <container_id>
sudo podman rm --force --storage 6f4126f77e6ebde7326ffe1b963b31e9dad5590cacbd7ab1d0123b307229dbad 
```


### RHEL6/7/8 性能调优参数
```

sysctl (RHEL7/8)
net.core.busy_read=50
net.core.busy_poll=50
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_early_retrans=1
kernel.numa_balancing=0

sysctl -a | grep net.ipv4.tcp_fastopen
sysctl -a | grep net.ipv4.tcp_early_retrans
sysctl -a | grep kernel.numa_balancing

modinfo ixgbe | grep -E "^parm" 

```



### Connecting OpenStack to Service Telemetry Framework
https://infrawatch.github.io/documentation/#deploying-to-non-standard-network-topologies_completing-the-stf-configuration

在使用 STF 的同时如何继续使用 Gnocchi<br>
https://github.com/infrawatch/service-telemetry-operator/blob/master/tests/infrared/16/stf-gnocchi-connectors.yaml.template<br>



### osp 16.1 undercloud rabbitmq 服务无法启动问题的分析
https://bugzilla.redhat.com/show_bug.cgi?id=1847859
```

# 文件 /var/lib/config-data/puppet-generated/rabbitmq/etc/rabbitmq/rabbitmq-env.conf
内容如下
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
NODE_IP_ADDRESS=
NODE_PORT=
RABBITMQ_CTL_DIST_PORT_MAX=25683
RABBITMQ_CTL_DIST_PORT_MIN=25673
RABBITMQ_NODENAME=rabbit@undercloud
export ERL_EPMD_ADDRESS=192.0.2.1
export ERL_INETRC=/etc/rabbitmq/inetrc

# 因此需要修改 /etc/hosts 文件
# 让 undercloud 解析到 192.0.2.1 
(undercloud) [stack@undercloud ~]$ cat /etc/hosts | grep undercloud 
192.0.2.1 undercloud.ctlplane.example.com undercloud.ctlplane undercloud
#192.168.122.2 undercloud.example.com undercloud

# 修改完后 rabbitmq 将能启动起来
(undercloud) [stack@undercloud ~]$ sudo podman ps | grep rabbitmq
(undercloud) [stack@undercloud ~]$ sudo podman exec -it rabbitmq rabbitmqctl cluster_status
```



### 确认 overcloud 满足 openshift 需要
https://docs.openshift.com/container-platform/4.6/installing/installing_openstack/installing-openstack-installer-kuryr.html#prerequisites
```

# https://docs.openshift.com/container-platform/4.6/installing/installing_openstack/installing-openstack-installer-kuryr.html#prerequisites
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo grep service_plugin /var/lib/config-data/puppet-generated/neutron/etc/neutron/neutron.conf
Warning: Permanently added 'overcloud-controller-0.ctlplane' (ECDSA) to the list of known hosts.
service_plugins=qos,ovn-router,trunk,segments

# 检查本地上游镜像仓库里有 octavia 镜像
[root@helper ~]# curl https://helper.example.com:5000/v2/_catalog  | jq . | grep octavia
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3830  100  3830    0     0  31916      0 --:--:-- --:--:-- --:--:-- 32184
    "rhosp-rhel8/openstack-octavia-api",
    "rhosp-rhel8/openstack-octavia-base",
    "rhosp-rhel8/openstack-octavia-health-manager",
    "rhosp-rhel8/openstack-octavia-housekeeping",
    "rhosp-rhel8/openstack-octavia-worker",

# 确认部署完的环境包含 octavia 服务
(overcloud) [stack@undercloud ~]$ openstack catalog show octavia -f json 
{
  "endpoints": [
    {
      "id": "6c4deabbdffe458d8169c8b09721a7a3",
      "interface": "internal",
      "region_id": "regionOne",
      "url": "https://overcloud.internalapi.example.com:9876",
      "region": "regionOne"
    },
    {
      "id": "9497b5e9e052470d9457f445672a6f8e",
      "interface": "public",
      "region_id": "regionOne",
      "url": "https://overcloud.example.com:13876",
      "region": "regionOne"
    },
    {
      "id": "fe52fa7a79cf41ec93c4917a3fc1e4f2",
      "interface": "admin",
      "region_id": "regionOne",
      "url": "https://overcloud.internalapi.example.com:9876",
      "region": "regionOne"
    }
  ],
  "id": "5ac2e927cb7748cc8fdbaaf8d3cbe154",
  "name": "octavia",
  "type": "load-balancer"
}

# 列出 octavia provider
(overcloud) [stack@undercloud ~]$ openstack loadbalancer provider list
+---------+-------------------------------------------------+
| name    | description                                     |
+---------+-------------------------------------------------+
| amphora | The Octavia Amphora driver.                     |
| octavia | Deprecated alias of the Octavia Amphora driver. |
| ovn     | Octavia OVN driver.                             |
+---------+-------------------------------------------------+

# https://docs.openshift.com/container-platform/4.6/networking/load-balancing-openstack.html#installation-osp-kuryr-octavia-configure
# kuryr 与 octavia ovn 的集成


```



### osp16.1 默认安装 overclod ceph pool 详情
```
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool ls detail 
Warning: Permanently added 'overcloud-controller-0.ctlplane' (ECDSA) to the list of known hosts.
pool 1 'vms' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 75 flags hashpspool stripe_width 0 application rbd
pool 2 'volumes' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 76 flags hashpspool stripe_width 0 application rbd
pool 3 'images' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 81 flags hashpspool,selfmanaged_snaps stripe_width 0 application rbd
        removed_snaps [1~3]
pool 4 '.rgw.root' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 43 flags hashpspool stripe_width 0 application rgw
pool 5 'default.rgw.control' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 45 flags hashpspool stripe_width 0 application rgw
pool 6 'default.rgw.meta' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 48 flags hashpspool stripe_width 0 application rgw
pool 7 'default.rgw.log' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 49 flags hashpspool stripe_width 0 application rgw
```



### RGW/S3 Archive Zone goes upstream in Ceph
https://ceph.io/planet/rgw-s3-archive-zone-goes-upstream-in-ceph/



### 配置 active-active multi site rgw
```
# keepalived.conf
# 在 haproxy 上优先级最高，是 102
# 在 haproxy2 上优先级为 101
# 在 haproxy3 上优先级为 100
cat /etc/keepalived/keepalived.conf
vrrp_script chk_haproxy {
 script "killall -0 haproxy" # check the haproxy process
 interval 2 # every 2 seconds
 weight 2 # add 2 points if OK
}
vrrp_instance VI_1 {
 interface eth1 # interface to monitor
 state MASTER # MASTER on haproxy, BACKUP on haproxy2 and haproxy 3
 virtual_router_id 51
 priority 102 # 102 on haproxy, 101 and 100 on haproxy2 and haproxy3
 virtual_ipaddress {
  x.x.254.17 # virtual ip address
 }
 track_script {
  chk_haproxy
 }
}

# rgw 的 haproxy 配置
cat /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Example configuration for a possible web application. See the
# full configuration options online.
#
# http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
  # to have these messages end up in /var/log/haproxy.log you will
  # need to:
  #
  # 1) configure syslog to accept network log events. This is done
  # by adding the '-r' option to the SYSLOGD_OPTIONS in
  # /etc/sysconfig/syslog
  #
  # 2) configure local2 events to go to the /var/log/haproxy.log
  # file. A line like the following can be added to
  # /etc/sysconfig/syslog
  #
  # local2.* /var/log/haproxy.log
  #
  log 127.0.0.1 local2

  chroot /var/lib/haproxy
  pidfile /var/run/haproxy.pid
  maxconn 4000
  user haproxy
  group haproxy
  daemon

  # turn on stats unix socket
  stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
  mode http
  log global
  option httplog
  option dontlognull
  option http-server-close
  option forwardfor except 127.0.0.0/8
  option redispatch
  retries 3
  timeout http-request 10s
  timeout queue 1m
  timeout connect 10s
  timeout client 1m
  timeout server 1m
  timeout http-keep-alive 10s
  timeout check 10s
  maxconn 3000

frontend http_web *:80
  mode http
  default_backend rgw

#frontend rgw-https
#  bind *:443 ssl crt /etc/ssl/private/example.com.pem
#  default_backend rgw

backend rgw
  balance roundrobin
  mode http
  server rgw1 10.67.128.13:8080 check
  server rgw2 10.67.128.14:8080 check
  server rgw3 10.67.128.15:8080 check

# 列出 realm
radosgw-admin realm list
{
  "default_info": "",
  "realms": []
}

# 创建 realm，然后列出 realm
radosgw-admin realm create --rgw-realm=aaa-cloud --default
radosgw-admin realm list
{
  "default_info": "cc03cc5e-a070-4147-b7fb-00f5ae490fa6",
  "realms": [
    "aaa-cloud"
  ]
}

# 创建 master zonegroup
radosgw-admin zonegroup create --rgw-zonegroup=sg --rgw-realm=aaa-cloud --master --default

# 查询 zonegroup sg 信息
radosgw-admin zonegroup get --rgw-zonegroup=sg
{
  "id": "008e8788-9efc-4e7e-9e04-719ff8da72ba",
  "name": "sg",
  "api_name": "sg",
  "is_master": "true",
  "endpoints": [],
  "hostnames": [],
  "hostnames_s3website": [],
  "master_zone": "e544879e-cd5a-424d-96dd-ccf1504429c6",
  "zones": [
    {
      "id": "bb3467a7-9d3d-4a5e-8424-ea0c4ba573f4",
      "name": "sg-az2",
      "endpoints": [
        "http:\/\/x.x.254.17"
      ],
      "log_meta": "false",
      "log_data": "true",
      "bucket_index_max_shards": 0,
      "read_only": "false"
    },
    {
      "id": "e544879e-cd5a-424d-96dd-ccf1504429c6",
      "name": "sg-az1",
      "endpoints": [
        "http:\/\/x.x.254.17"
      ],
      "log_meta": "true",
      "log_data": "true",
      "bucket_index_max_shards": 0,
      "read_only": "false"
    }
  ],
  "placement_targets": [
    {
      "name": "default-placement",
      "tags": []
    }
  ],
  "default_placement": "default-placement",
  "realm_id": "b9e54eb7-bd92-4f47-ba87-0991a8b20e5d"
}

# 创建 master zone sg-az1 
radosgw-admin zone create --rgw-zonegroup=sg --rgw-zone=sg-az1 --master --default --endpoints=http://x.x.254.17:80

# 列出 master zone sg-az1 信息
radosgw-admin zone get --rgw-zone=sg-az1
{
  "id": "e544879e-cd5a-424d-96dd-ccf1504429c6",
  "name": "sg-az1",
  "domain_root": "sg-az1.rgw.data.root",
  "control_pool": "sg-az1.rgw.control",
  "gc_pool": "sg-az1.rgw.gc",
  "log_pool": "sg-az1.rgw.log",
  "intent_log_pool": "sg-az1.rgw.intent-log",
  "usage_log_pool": "sg-az1.rgw.usage",
  "user_keys_pool": "sg-az1.rgw.users.keys",
  "user_email_pool": "sg-az1.rgw.users.email",
  "user_swift_pool": "sg-az1.rgw.users.swift",
  "user_uid_pool": "sg-az1.rgw.users.uid",
  "system_key": {
    "access_key": "DFT7FB1DMHLFLY4AYJ2S",
    "secret_key": "A0orc3jJJIZGYu0sSwouVH1eiLPe6taNKtCqDM3n"
  },
  "placement_pools": [
    {
      "key": "default-placement",
      "val": {
        "index_pool": "sg-az1.rgw.buckets.index",
        "data_pool": "sg-az1.rgw.buckets.data",
        "data_extra_pool": "sg-az1.rgw.buckets.extra",
        "index_type": 0
      }
    }
  ],
  "metadata_heap": "",
  "realm_id": "b9e54eb7-bd92-4f47-ba87-0991a8b20e5d"
}

# 删除 default Zone Group
radosgw-admin zonegroup remove --rgw-zonegroup=default --rgw-zone=default

radosgw-admin period update --commit

radosgw-admin zone delete --rgw-zone=default

radosgw-admin period update --commit

radosgw-admin zonegroup delete --rgw-zonegroup=default

radosgw-admin period update --commit

radosgw-admin zonegroup list
read_default_id : 0
{
  "default_info": "008e8788-9efc-4e7e-9e04-719ff8da72ba",
  "zonegroups": [
    "sg"
  ]
}

# 创建 sync user
radosgw-admin user create --uid="sync-user" --display-name="Synchronization User" --system

radosgw-admin zone modify --rgw-zone=sg-az1 \
  --access-key=DFT7FB1DMHLFLY4AYJ2S \
  --secret=A0orc3jJJIZGYu0sSwouVH1eiLPe6taNKtCqDM3n

radosgw-admin period update --commit

# 编辑 /usr/share/ceph-ansible/groups_var/all.yml 
ceph_conf_overrides:
  global:
    osd_pool_default_size: 3
    osd_pool_default_min_size: 2
    osd_crush_update_on_start: false
    mon_osd_full_ratio: .80
    mon_osd_nearfull_ratio: .70
  client.rgw.df-rgw-01:
    rgw_zone: "sg-az1"
    rgw_zonegroup: "sg"
  client.rgw.df-rgw-02:
    rgw_zone: "sg-az1"
    rgw_zonegroup: "sg"
  client.rgw.df-rgw-03:
    rgw_zone: "sg-az1"
    rgw_zonegroup: "sg"

cd /usr/share/ceph-ansible/
ansible-playbook rgw-standalone.yml

[root@df-rgw-01 ~]# systemctl restart ceph-radosgw.target
[root@df-rgw-02 ~]# systemctl restart ceph-radosgw.target
[root@df-rgw-03 ~]# systemctl restart ceph-radosgw.target

# 在站点 2 配置 
# 获取 realm
[root@mh-rgw-01 ~]# radosgw-admin realm pull --url=http://x.x.254.17 \
  --access-key=DFT7FB1DMHLFLY4AYJ2S \
  --secret=A0orc3jJJIZGYu0sSwouVH1eiLPe6taNKtCqDM3n

[root@mh-rgw-01 ~]# radosgw-admin realm default --rgw-realm=aaa-cloud

[root@mh-rgw-01 ~]# radosgw-admin realm list
{
  "default_info": "b9e54eb7-bd92-4f47-ba87-0991a8b20e5d",
  "realms": [
    "aaa-cloud"
  ]
}

# pull the period
[root@mh-rgw-01 ~]# radosgw-admin period pull --url=http://x.x.254.17 \
  --access-key=DFT7FB1DMHLFLY4AYJ2S \
  --secret=A0orc3jJJIZGYu0sSwouVH1eiLPe6taNKtCqDM3n

# 创建 secondary zone
[root@mh-rgw-01 ~]# radosgw-admin zone create --rgw-zonegroup=sg \
  --rgw-zone=sg-az2 --access-key=DFT7FB1DMHLFLY4AYJ2S \
  --secret=A0orc3jJJIZGYu0sSwouVH1eiLPe6taNKtCqDM3n \
  --endpoints=http://x.x.254.17

[root@mh-rgw-01 ~]# radosgw-admin zone list
{
  "default_info": "bb3467a7-9d3d-4a5e-8424-ea0c4ba573f4",
  "zones": [
    "sg-az2"
  ]
}

# update period
[root@mh-rgw-01 ~]# radosgw-admin period update --commit

# 检查同步状态
[root@mh-rgw-01 ~]# radosgw-admin sync status
2017-06-07 06:03:34.094028 7fe206f559c0 0 error in read_id for id : (2) No such file or directory
2017-06-07 06:03:34.095161 7fe206f559c0 0 error in read_id for id : (2) No such file or directory
    realm b9e54eb7-bd92-4f47-ba87-0991a8b20e5d (aaa-cloud)
  zonegroup 008e8788-9efc-4e7e-9e04-719ff8da72ba (sg)
    zone bb3467a7-9d3d-4a5e-8424-ea0c4ba573f4 (sg-az2)
metadata sync syncing
      full sync: 0/64 shards
      metadata is caught up with master
      incremental sync: 64/64 shards
data sync source: e544879e-cd5a-424d-96dd-ccf1504429c6 (sg-az1)
      syncing
      full sync: 0/128 shards
      incremental sync: 128/128 shards
      data is caught up with source

# 编辑 /usr/share/ceph-ansible/groups_var/all.yml
[root@mh-rgw-01 ~]# cat /usr/share/ceph-ansible/groups_var/all.yml
ceph_conf_overrides:
  global:
    osd_pool_default_size: 3
    osd_pool_default_min_size: 2
    osd_crush_update_on_start: false
    mon_osd_full_ratio: .80
    mon_osd_nearfull_ratio: .70
  client.rgw.mh-rgw-01:
    rgw_zone: "sg-az2"
    rgw_zonegroup: "sg"
  client.rgw.mh-rgw-02:
    rgw_zone: "sg-az2"
    rgw_zonegroup: "sg"
  client.rgw.mh-rgw-03:
    rgw_zone: "sg-az2"
    rgw_zonegroup: "sg"

[root@mh-ceph-admin ~]# cd /usr/share/ceph-ansible/
[root@mh-ceph-admin ceph-ansible]# ansible-playbook rgw-standalone.yml

[root@mh-rgw-01 ~]# systemctl restart ceph-radosgw.target
[root@mh-rgw-02 ~]# systemctl restart ceph-radosgw.target
[root@mh-rgw-03 ~]# systemctl restart ceph-radosgw.target

# 设置 s3 格式的 subdomain
# objstore.aaaconnect.cloud domain will be used for S3 object storage service.
# 每个用户有自己的 url {bucket-name}.objstore.aaaconnect.cloud
# 两个站点都需要执行

# 编辑 /usr/share/ceph-ansible/groups_var/all.yml
[root@mh-ceph-admin ~]# cd /usr/share/ceph-ansible/
[root@mh-ceph-admin ceph-ansible]# cat groups_var/all.yml
ceph_conf_overrides:
  global:
    osd_pool_default_size: 3
    osd_pool_default_min_size: 2
    osd_crush_update_on_start: false
    mon_osd_full_ratio: .80
    mon_osd_nearfull_ratio: .70
  client.rgw.mh-rgw-01:
    rgw_zone: "sg-az2"
    rgw_zonegroup: "sg"
    rgw_dns_name: "objstore.aaaconnect.cloud"
  client.rgw.mh-rgw-02:
    rgw_zone: "sg-az2"
    rgw_zonegroup: "sg"
    rgw_dns_name: "objstore.aaaconnect.cloud"
  client.rgw.mh-rgw-03:
    rgw_zone: "sg-az2"
    rgw_zonegroup: "sg"
    rgw_dns_name: "objstore.aaaconnect.cloud"

[root@mh-ceph-admin ~]# cd /usr/share/ceph-ansible/
[root@mh-ceph-admin ceph-ansible]# ansible-playbook rgw-standalone.yml
[root@mh-rgw-01 ~]# systemctl restart ceph-radosgw.target
[root@mh-rgw-02 ~]# systemctl restart ceph-radosgw.target
[root@mh-rgw-03 ~]# systemctl restart ceph-radosgw.target
```



### OpenShift Tips Cluster Version
https://openshift.tips/clusterversion/

包含以下内容
* 切换 clusterversion channel
* unmanage operators
* 生成 patch yaml 文件
* patch clusterversion 对象
* 禁用 clusterversion operator



### Red Hat Ceph Storage for Data Lake
https://gist.github.com/mmgaggle/5297770b2a38963c75f689a53990c1f6#red-hat-ceph-storage-for-data-lake



### 创建 ocs 演示应用
```
# 创建 project my-database-app
oc new-project my-database-app

# 创建演示应用 
# 设置参数
# STORAGE_CLASS=ocs-storagecluster-ceph-rbd
# VOLUME_CAPACITY=5Gi
curl -s https://raw.githubusercontent.com/red-hat-storage/ocs-training/master/training/modules/ocs4/attachments/configurable-rails-app.yaml | oc new-app -p STORAGE_CLASS=ocs-storagecluster-ceph-rbd -p VOLUME_CAPACITY=5Gi -f -

```



### Linux on Z and LinuxONE Tuning hints and tips
https://www.ibm.com/developerworks/linux/linux390/perf/index.html<br>
https://www.ibm.com/developerworks/linux/linux390/perf/tuning_database.html

Migrating from OProfile to perf, and beyond<br>
https://developer.ibm.com/technologies/linux/tutorials/migrate-from-oprofile-to-perf/



### Are there any benchmarking and performance testing tools available in Red Hat Enterprise Linux
https://access.redhat.com/solutions/173863



### UnixBench Score: An Introduction
https://www.alibabacloud.com/blog/unixbench-score-an-introduction_594677


### Podman tutorials
http://docs.podman.io/en/latest/Tutorials.html<br>
https://github.com/containers/podman/blob/master/docs/tutorials/basic_networking.md



### Relate articles and documents
How to mirror a repository in Linux<br>
https://www.redhat.com/sysadmin/how-mirror-repository<br>

How to create a local mirror of the latest update for Red Hat Enterprise Linux 5, 6, 7, 8 without using Satellite server<br>
https://access.redhat.com/solutions/23016<br>

Is there a tuned profile available for Oracle RDBMS<br>
https://access.redhat.com/solutions/2867881<br>

Are there any benchmarking and performance testing tools available in Red Hat Enterprise Linux<br>
https://access.redhat.com/solutions/173863<br>

RHEL7 Performance Tuning Guide<br>
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/performance_tuning_guide/index<br>



### OpenShift Developer Sandbox
https://developers.redhat.com/developer-sandbox<br>
https://developers.redhat.com/articles/2020/12/09/get-started-your-developer-sandbox-red-hat-openshift<br>



### Critical DaemonSets Missing Universal Toleration
关键的 DeamonSet 如何设置 Universal Toleration<br>
https://access.redhat.com/solutions/5061861



### How to Build an ACM Demo Environment
https://github.com/open-cluster-management/labs



### 使用 serviceaccount token 登录 openshift (cli)
参考 Bug 1827374 - CLI login not working when Openshift idp is configured using SSO
```
# https://developers.redhat.com/articles/2020/12/09/get-started-your-developer-sandbox-red-hat-openshift#
# https://oauth-openshift.apps.sandbox.x8i5.p1.openshiftapps.com/oauth/token/display
oc login --token=sha256~2bSKgMogSXC0EjzTlDWeh24aiDEUUt5WPmQuPMCLusw --server=https://api.sandbox.x8i5.p1.openshiftapps.com:6443

# 拿 jenkins 来测试应用
oc -n wang-jun-1974-dev new-app jenkins-ephemeral

# 生成 template
oc -n wang-jun-1974-dev create -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/maven-pipeline.yaml

# 创建 app
oc -n wang-jun-1974-dev new-app --template=maven-pipeline

# 列出 pods
oc -n wang-jun-1974-dev get pods

# patch wildfly imagestream
# https://www.wildfly.org/news/2019/10/07/WildFly-s2i-18-released/
# https://raw.githubusercontent.com/wildfly/wildfly-s2i/wf-18.0/imagestreams/wildfly-centos7.json
oc -n wang-jun-1974-dev patch is wildfly --type json -p='[{"op": "replace", "path": "/spec/tags/0/from/name", "value":"quay.io/wildfly/wildfly-centos7:17.0"}]'

# 触发 build
oc start-build openshift-jee-sample -n wang-jun-1974-dev

# 查看 logs
oc -n wang-jun-1974-dev logs openshift-jee-sample-docker-1-build

# 访问 route
curl $(oc -n wang-jun-1974-dev get routes openshift-jee-sample -o jsonpath='{ .spec.host }')

```



### 学习内容
什么是 skupper<br>
https://skupper.io/


Skupper<br>
Multicloud communication for Kubernetes<br>
Skupper is a layer 7 service interconnect. It enables secure communication across Kubernetes clusters with no VPNs or special firewall rules.<br>

With Skupper, your application can span multiple cloud providers, data centers, and regions.<br>

什么是 Submariner<br>
https://submariner.io/getting-started/architecture/globalnet/



### troubleshooting 
```
cat /tmp/err | grep -Ev 'ptp4l'
systemctl -l | grep -Ev "loaded active" 
systemctl restart glusterd

cat /var/log/glusterfs/glusterd.log | grep " E "

[2021-02-24 07:51:45.097202] E [MSGID: 106243] [glusterd.c:1797:init] 0-management: creation of 1 listeners failed, continuing with succeeded transport
[2021-02-24 07:51:45.325128] E [run.c:190:runner_log] (-->/lib64/libglusterfs.so.0(xlator_init+0x4b) [0x7fd126abbd1b] -->/usr/lib64/glusterfs/3.8.4/xlator/mgmt/glusterd.so(init+0x29e4) [0x7fd11b5529d4] -->/lib64/libglusterfs.so.0(runner_log+0x115) [0x7fd126b0b175] ) 0-glusterd: command failed: /usr/libexec/glusterfs/gsyncd -c /var/lib/glusterd/geo-replication/gsyncd_template.conf --config-set-rx remote-gsyncd /usr/libexec/glusterfs/gsyncd . .
[2021-02-24 07:51:45.325179] E [MSGID: 101019] [xlator.c:486:xlator_init] 0-management: Initialization of volume 'management' failed, review your volfile again
[2021-02-24 07:51:45.325214] E [MSGID: 101066] [graph.c:324:glusterfs_graph_init] 0-management: initializing translator failed
[2021-02-24 07:51:45.325221] E [MSGID: 101176] [graph.c:680:glusterfs_graph_activate] 0-graph: init failed

cat /etc/glusterfs/glusterd.vol 
volume management
    type mgmt/glusterd
    option working-directory /var/lib/glusterd
    option transport-type socket,rdma
    option transport.socket.keepalive-time 10
    option transport.socket.keepalive-interval 2
    option transport.socket.read-fail-log off
    option ping-timeout 0
    option event-threads 1
#   option lock-timer 180
#   option transport.address-family inet6
#   option base-port 49152
end-volume

cat /var/log/glusterfs/glusterd.log | more

# 最后发现是由于 /var 文件系统满了

systemctl -l | grep -Ev "loaded active" 

```


### Controller Role 和 Compute Role 有哪些服务上的差别

```
# 以下内容适用于 OSP 16.1 
# 保存 Controller Role 的 ServiceDefault 到文件
(overcloud) [stack@undercloud templates]$ cat roles_data.yaml | grep -E "\- name: Controller" -A186 | tail -156 | tee /tmp/controllerservice 

# 保存 Compute Role 的 ServiceDefault 到文件
(overcloud) [stack@undercloud templates]$ cat roles_data.yaml | grep -E "\- name: Compute$" -A77 | tail -48 | tee /tmp/computeservice 

# 保存 ComputeHCI Role 的 ServiceDefault 到文件
(overcloud) [stack@undercloud templates]$ cat roles_data.yaml | grep -E "\- name: ComputeHCI$" -A64 | tail -49 | tee /tmp/computehciservice 

# 哪些服务包含在 Compute Role，但是不包含在 ControllerRole 里
(overcloud) [stack@undercloud templates]$ diff -urN /tmp/controllerservice /tmp/computeservice | grep -E "^\+" 
+++ /tmp/computeservice 2021-02-25 09:43:09.310273266 +0800
+    - OS::TripleO::Services::CephClient
+    - OS::TripleO::Services::ComputeCeilometerAgent
+    - OS::TripleO::Services::ComputeNeutronCorePlugin
+    - OS::TripleO::Services::ComputeNeutronL3Agent
+    - OS::TripleO::Services::ComputeNeutronMetadataAgent
+    - OS::TripleO::Services::ComputeNeutronOvsAgent
+    - OS::TripleO::Services::NeutronBgpVpnBagpipe
+    - OS::TripleO::Services::NovaAZConfig
+    - OS::TripleO::Services::NovaCompute
+    - OS::TripleO::Services::NovaLibvirt
+    - OS::TripleO::Services::NovaLibvirtGuests
+    - OS::TripleO::Services::NovaMigrationTarget
+    - OS::TripleO::Services::OVNController
+    - OS::TripleO::Services::OVNMetadataAgent

# 哪些服务包含在 ComputeHCI Role，但是不包含在 ControllerRole 里
(overcloud) [stack@undercloud templates]$ diff -urN /tmp/controllerservice /tmp/computehciservice | grep -E "^\+" 
+++ /tmp/computehciservice      2021-02-25 10:01:03.053474381 +0800
+    - OS::TripleO::Services::CephClient
+    - OS::TripleO::Services::CephOSD
+    - OS::TripleO::Services::ComputeCeilometerAgent
+    - OS::TripleO::Services::ComputeNeutronCorePlugin
+    - OS::TripleO::Services::ComputeNeutronL3Agent
+    - OS::TripleO::Services::ComputeNeutronMetadataAgent
+    - OS::TripleO::Services::ComputeNeutronOvsAgent
+    - OS::TripleO::Services::NeutronBgpVpnBagpipe
+    - OS::TripleO::Services::NovaAZConfig
+    - OS::TripleO::Services::NovaCompute
+    - OS::TripleO::Services::NovaLibvirt
+    - OS::TripleO::Services::NovaLibvirtGuests
+    - OS::TripleO::Services::NovaMigrationTarget
+    - OS::TripleO::Services::OVNController
+    - OS::TripleO::Services::OVNMetadataAgent
```


### ceph placement group 问题定位
https://docs.ceph.com/en/latest/rados/troubleshooting/troubleshooting-pg/



### 部署 compat mode 3 节点 osp 16.1 时遇到报错
```
(undercloud) [stack@undercloud ~]$ cat /var/lib/mistral/overcloud/ansible.log | grep "fatal:" -A28
...
    "stderr": "<13>Feb 25 06:11:51 puppet-user: Warning: The function 'hiera' is deprecated in favor of using 'lookup'. See https://puppet.com/docs/puppet/5.5/deprecated_language.html\\n   (file & line not available)\n<13>Feb 25 06:12:05 puppet-user: Warning: /etc/puppet/hiera.yaml: Use of 'hiera.yaml' version 3 is deprecated. It should be converted to version 5\n<13>Feb 25 06:12:05 puppet-user:    (file: /etc/puppet/hiera.yaml)\n<13>Feb 25 06:12:05 puppet-user: Warning: Undefined variable '::deploy_config_name'; \\n   (file & line not available)\n<13>Feb 25 06:12:05 puppet-user: Warning: ModuleLoader: module 'tripleo' has unresolved dependencies - it will only see those that are resolved. Use 'puppet module list --tree' to see information about modules\\n   (file & line not available)\n<13>Feb 25 06:12:05 puppet-user: Warning: Undefined variable '::nova::params::vncproxy_service_name'; class nova::params has not been evaluated\\n   (file & line not available)\n<13>Feb 25 06:12:05 puppet-user: Warning: ModuleLoader: module 'nova' has unresolved dependencies - it will only see those that are resolved. Use 'puppet module list --tree' to see information about modules\\n   (file & line not available)\n<13>Feb 25 06:12:05 puppet-user: Warning: ModuleLoader: module 'openstacklib' has unresolved dependencies - it will only see those that are resolved. Use 'puppet module list --tree' to see information about modules\\n   (file & line not available)\n<13>Feb 25 06:12:05 puppet-user: Warning: ModuleLoader: module 'concat' has unresolved dependencies - it will only see those that are resolved. Use 'puppet module list --tree' to see information about modules\\n   (file & line not available)\n<13>Feb 25 06:12:05 puppet-user: Warning: Unknown variable: '::deployment_type'. (file: /etc/puppet/modules/tripleo/manifests/profile/base/database/mysql/client.pp, line: 89, column: 8)\n<13>Feb 25 06:12:06 puppet-user: Warning: ModuleLoader: module 'pacemaker' has unresolved dependencies - it will only see those that are resolved. Use 'puppet module list --tree' to see information about modules\\n   (file & line not available)\n<13>Feb 25 06:12:07 puppet-user: Warning: tag is a metaparam; this value will inherit to all contained resources in the tripleo::firewall::rule definition\n<13>Feb 25 06:12:07 puppet-user: Notice: Scope(Class[Tripleo::Firewall::Post]): At this stage, all network traffic is blocked.\n<13>Feb 25 06:12:07 puppet-user: Error: Evaluation Error: Error while evaluating a Resource Statement, Evaluation Error: Error while evaluating a Resource Statement, Duplicate declaration: Exec[/etc/pki/CA/certs/vnc.crt] is already declared at (file: /etc/puppet/modules/tripleo/manifests/certmonger/libvirt_vnc.pp, line: 87); cannot redeclare (file: /etc/puppet/modules/tripleo/manifests/certmonger/libvirt_vnc.pp, line: 87) (file: /etc/puppet/modules/tripleo/manifests/certmonger/libvirt_vnc.pp, line: 87, column: 5) (file: /etc/puppet/modules/tripleo/manifests/profile/base/certmonger_user.pp, line: 258) on node overcloud-controller-1.example.com",

# 参考 https://bugs.launchpad.net/tripleo/+bug/1887376
# https://git.openstack.org/cgit/openstack/tripleo-heat-templates/commit/?id=5087bc9c12fb2eda23db6c06cec82bbc7fb997a1
```



### Custom RHEL 7 Installation ISO/DVD fails with "Warning: dracut-initqueue timeout - starting timeout scripts"
https://access.redhat.com/solutions/3438961



### Add required overcloud image in the install doc for RHOSP16 stf
https://bugzilla.redhat.com/show_bug.cgi?id=1866816



### 如何设置 subscription-manager 使用国内的 CDN
https://access.redhat.com/solutions/5090421
```
# subscription-manager config --rhsm.baseurl=https://china.cdn.redhat.com
# subscription-manager refresh
# yum clean all
# yum makecache
```



### 裸金属服务器业务（BMS）的现状调研4：Huawei Bare Metal Server
http://www.brofive.org/?p=4512



### How do I re-run only ceph-ansible when using tripleo config-download?
关于如何重新执行 ceph-ansible 部分<br>
http://blog.johnlikesopenstack.com/2019/01/how-do-i-re-run-only-ceph-ansible-when.html
```
sudo cd /var/lib/mistral/config-download-latest/
sudo bash ansible-playbook-command.sh --tags external_deploy_steps
```



### RHV 4.4 RHVM Standalone LocalDB deploy
https://access.redhat.com/documentation/en-us/red_hat_virtualization/4.4/html-single/installing_red_hat_virtualization_as_a_standalone_manager_with_local_databases/index#Installing_RHEL_for_RHVM_SM_localDB_deploy
```

# 在 kvm 环境下使用 kickstart 安装虚拟机 
virt-install --name=jwang-rhel83-rhvm --vcpus=2 --ram=4096 --disk path=/data/kvm/jwang-rhel83-rhvm.qcow2,bus=virtio,size=120 --os-variant rhel8.0 --network network=default,model=virtio --boot menu=on --graphics none --location  /root/jwang/isos/rhel-8.3-x86_64-dvd.iso --initrd-inject /tmp/ks.cfg --extra-args='ks=file:/ks.cfg console=ttyS0 ip=192.168.122.152::192.168.122.1:255.255.255.0:rhvm.rhcnsa.org:ens3:none'

# 在 RHV 环境下使用 kickstart 安装虚拟机
# https://access.redhat.com/solutions/300713

kernel path ISO11://vmlinuz-rhel-8.3
initrd path ISO11://initrd.img-rhel-8.3
kernel parameters  ks=http://10.66.208.115/ks-rhvm.cfg ksdevice=ens3 ip=10.66.208.152 netmask=255.255.255.0 dns 10.64.63.6 gateway=10.66.208.254

# RHVH 的 ks.cfg 例子
liveimg --url=http://192.168.127.252/xx/squashfs.img
clearpart --all
autopart --type=thinp
rootpw --plaintext redhat
timezone --utc Asia/Shanghai
zerombr
text
reboot
%post --erroronfail
nodectl
%end


# 参考这个链接里的内容
# https://poppywan.readthedocs.io/en/latest/022-rhca/002-RH318/readme/

```



### 包含很多 Red Hat 培训课程内容的网址
https://poppywan.readthedocs.io/en/latest/022-rhca/002-RH318/readme/




### Nested KVM in rhv 相关设置
参考: https://access.redhat.com/solutions/3543721<br>
参考：https://lists.ovirt.org/pipermail/users/2017-March/080219.html<br>
```
# 安装 vdsm-hook-nestedvt 和 vdsm-hook-macspoof
# https://lists.ovirt.org/pipermail/users/2017-March/080219.html
# https://www.redhat.com/en/blog/testing-ovirt-33-nested-kvm

# engine-config --get KEY_NAME
engine-config --get UserDefinedVMProperties=macspoof
```



### oVirt SPICE console from a Mac
https://rizvir.com/articles/ovirt-mac-console/
```
# 这个链接里的步骤仍然工作
```



### puppylinux
目前的想法是在虚拟机里运行 puppylinux，然后通过 remote-viewer 访问 puppylinux 的桌面<br>
http://puppylinux.com/index.html



### RHV 如何设置让 Host 不去 activate Guest 的 LV
https://access.redhat.com/solutions/2662261<br>
https://access.redhat.com/solutions/3450192<br>

```
# In RHEL 7, systemd and lvm are eager to scan and activate anything on a system. This leads to activation of Guest internal LVs.

# 配置步骤
# 执行对象：数据中心里的每个 Host:
1. Switch host to Maintenance Mode
2. SSH to host
3. If the boot device is a local disk, blacklist it in multipath [*]
4. Run the vdsm-tool config-lvm-filter tool
5. Reboot host
6. Activate host

# /usr/bin/vdsm-tool config-lvm-filter
...
This is the recommended LVM filter for this host:

  filter = [ "a|^/dev/vda2$|", "r|.*|" ]
...
# mkdir /etc/multipath/conf.d
# vi /etc/multipath/conf.d/blacklist.conf

blacklist {
      wwid SIBM-ESXSST336732LC____F3ET0EP0Q000072428BX1
}

To find the wwid you can run:

    # udevadm info /dev/sda | grep ID_SERIAL=     E: ID_SERIAL=0QEMU_QEMU_HARDDISK_host4-data

This is explained in the linked documentation:

    https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/dm_multipath/ignore_localdisk_procedure

[*] Why it is important to blacklist the local device in mutlipath?
If not configured, in the next boot/upgrade, multipath will take over the device before lvm, lvm would not find it and the machine would fail to boot. For details, see RHV host boot into emergency mode after upgrade .
https://access.redhat.com/solutions/4000961

```


### split example
```
split -b 3900M -d rhv-4.4-repos-2021-03-03.tar.gz rhv-4.4-repos-2021-03-03.tar.gz.

ls -lh rhv-4.4-repos-2021-03-03.tar.gz.0*
-rw-r--r--. 1 root root 3.9G Mar  8 11:36 rhv-4.4-repos-2021-03-03.tar.gz.00
-rw-r--r--. 1 root root 3.9G Mar  8 11:36 rhv-4.4-repos-2021-03-03.tar.gz.01
-rw-r--r--. 1 root root 1.2G Mar  8 11:36 rhv-4.4-repos-2021-03-03.tar.gz.02
```


### 如何添加 storage domain
https://www.youtube.com/watch?v=0fRnpmav-Pw


### Build kernel module for Mellanox CX5 on RHEL 8.3
参见王征写的文档：https://github.com/wangzheng422/docker_env/blob/master/redhat/rhel/rhel8.build.kernel.repo.cache.md


### build kernel
```
yum -y install yum-utils rpm-build 

cd /root
yumdownloader --source kernel.x86_64
rpm -ivh /root/kernel-4.18.0-240.1.1.el8_3.src.rpm

cd /root/rpmbuild/SPECS

yum-builddep kernel.spec



```

### CentOS/RHEL 8: how to build the kernel RPM with native CPU optimizations
https://www.getpagespeed.com/server-setup/centos-rhel-8-how-to-build-the-kernel-rpm-with-native-optimizations

```
cat > build-install-native-kernel.sh << 'EOF'
#!/bin/bash
sudo dnf -y install https://extras.getpagespeed.com/release-latest.rpm
sudo dnf install mock replace
sudo usermod -a -G mock $USER
mkdir -p ~/kernel-native
cd ~/kernel-native
dnf download --source kernel
rpm2cpio kernel-*.src.rpm | cpio -idmv

RPM_OPT_FLAGS=`echo $(rpm -E %optflags) | sed 's@-O2@-O3@' | sed  's@-m64@-march=native@' | sed 's@-mtune=generic@-mtune=native@'`
replace '${RPM_OPT_FLAGS}' "${RPM_OPT_FLAGS}" -- kernel.spec
replace '# define buildid .local' '%define buildid .native' -- kernel.spec
mock -r epel-8-x86_64 --no-clean --no-cleanup-after --spec=$spec --sources=. --resultdir=. --buildsrpm
mock -r epel-8-x86_64 --no-clean --no-cleanup-after --rebuild --resultdir=. *.src.rpm
# sudo dnf install kernel-4*.native.*x86_64.rpm kernel-core-4*.native.*x86_64.rpm kernel-modules-4*.native.*x86_64.rpm
EOF
```

使用 mock 编译 rpm 包<br>
https://blog.packagecloud.io/eng/2015/05/11/building-rpm-packages-with-mock/

Building a custom kernel/Source RPM<br>
https://fedoraproject.org/wiki/Building_a_custom_kernel/Source_RPM

CentOS Build Kernel
https://wiki.centos.org/zh/HowTos/Custom_Kernel<br>
https://computingforgeeks.com/enable-powertools-repository-on-centos-rhel-linux/<br>
https://wiki.centos.org/HowTos/I_need_the_Kernel_Source<br>
https://vault.centos.org/8.3.2011/BaseOS/Source/SPackages/<br>
```
sudo yum groupinstall "Development Tools"
sudo yum install ncurses-devel
sudo yum install hmaccalc zlib-devel binutils-devel elfutils-libelf-devel wget

mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros

sudo wget https://vault.centos.org/8.3.2011/BaseOS/Source/SPackages/kernel-4.18.0-240.10.1.el8_3.src.rpm

rpm -ivh kernel-4.18.0-240.10.1.el8_3.src.rpm
sudo yum -y install yum-utils rpm-build 
sudo yum install libselinux-devel
sudo yum install epel-release 
sudo dnf install dnf-plugins-core
sudo dnf config-manager --set-enabled powertools

cd ~/rpmbuild/SPECS
sudo yum-builddep kernel.spec

rpmbuild -bp kernel.spec
cd ~/rpmbuild/BUILD/kernel-4.18.0-240.10.1.el8_3/linux-4.18.0-240.10.1.el8.x86_64

/bin/cp -f configs/kernel-4.18.0-$(uname -m).config .config

## 执行 make menuconfig
## 根据需要调整以下配置项目
## 按 '/' 搜索
## 以 CONFIG_NF_FLOW_TABLE_IPV4 为例
## 按 '/' 搜索，输入 CONFIG_NF_FLOW_TABLE_IPV4，然后按 1, 按 M
## 其他项目与上述过程相同，最后选择 ‘Save' 并退出 
# CONFIG_MLX5_TC_CT=y
# CONFIG_NET_ACT_CT=m
# CONFIG_SKB_EXTENSIONS=y
# CONFIG_NET_TC_SKB_EXT=y
# CONFIG_NF_FLOW_TABLE=m
# CONFIG_NF_FLOW_TABLE_IPV4=m  x
# CONFIG_NF_FLOW_TABLE_IPV6=m  x
# CONFIG_NF_FLOW_TABLE_INET=m
# CONFIG_NET_ACT_CONNMARK=m x
# CONFIG_NET_ACT_IPT=m  x
# CONFIG_NET_EMATCH_IPT=m   x
# CONFIG_NET_ACT_IFE=m  x

## 检查更改情况
cat .config | grep -E "CONFIG_MLX5_TC_CT|CONFIG_NET_ACT_CT|CONFIG_SKB_EXTENSIONS|CONFIG_NET_TC_SKB_EXT|CONFIG_NF_FLOW_TABLE|CONFIG_NF_FLOW_TABLE_IPV4|CONFIG_NF_FLOW_TABLE_IPV6|CONFIG_NF_FLOW_TABLE_INET|CONFIG_NET_ACT_CONNMARK|CONFIG_NET_ACT_IPT|CONFIG_NET_EMATCH_IPT|CONFIG_NET_ACT_IFE" 

## 在 .config 文件开始位置插入 # x86_64
sed -i '1s/^/# x86_64\n/' .config

## 将作出的修改拷贝到 /root/rpmbuild/SOURCES
/bin/cp -f .config configs/kernel-4.18.0-$(uname -m).config
/bin/cp -f .config configs/kernel-x86_64.config
/bin/cp -f configs/* ~/rpmbuild/SOURCES/

cd ~/rpmbuild/SPECS
cp kernel.spec kernel.spec.orig
# https://fedoraproject.org/wiki/Building_a_custom_kernel
# 自定义内核名称
sed -i "s/# define buildid \\.local/%define buildid \\.cuc/" kernel.spec

# 编译内核 rpm 
/usr/bin/nohup rpmbuild -bb --target=$(uname -m) --with baseonly --without debug --without debuginfo --without kabichk kernel.spec &
```

RDG: Accelerating ML and DL Workloads over Red Hat OpenShift Container Platform v4.1 with InfiniBand.<br>
https://docs.mellanox.com/pages/releaseview.action?pageId=19804150

```
cat ~/rpmbuild/BUILD/kernel-4.18.0-240.10.1.el8_3/linux-4.18.0-240.10.1.el8.cuc.x86_64/.config | grep -E "CONFIG_MLX5_TC_CT|CONFIG_NET_ACT_CT|CONFIG_SKB_EXTENSIONS|CONFIG_NET_TC_SKB_EXT|CONFIG_NF_FLOW_TABLE|CONFIG_NF_FLOW_TABLE_IPV4|CONFIG_NF_FLOW_TABLE_IPV6|CONFIG_NF_FLOW_TABLE_INET|CONFIG_NET_ACT_CONNMARK|CONFIG_NET_ACT_IPT|CONFIG_NET_EMATCH_IPT|CONFIG_NET_ACT_IFE"
```

Mellanox ASAP² Basic Debug
https://community.mellanox.com/s/article/ASAP-Basic-Debug

```
CONFIG_NET_ACT_CSUM – needed for action csum
CONFIG_NET_ACT_PEDIT – needed for header rewrite
CONFIG_NET_ACT_MIRRED – needed for basic forward
CONFIG_NET_ACT_CT – needed for connection tracking (supported from kernel 5.6)
CONFIG_NET_ACT_VLAN - needed for action vlan push/pop
CONFIG_NET_ACT_GACT
CONFIG_NET_CLS_FLOWER
CONFIG_NET_CLS_ACT
CONFIG_NET_SWITCHDEV
CONFIG_NET_TC_SKB_EXT - needed for connection tracking (supported from kernel 5.6)
CONFIG_NET_ACT_CT - needed for connection tracking (supported from kernel 5.6)
CONFIG_NFT_FLOW_OFFLOAD
CONFIG_NET_ACT_TUNNEL_KEY
CONFIG_NF_FLOW_TABLE - needed for connection tracking (supported from kernel 5.6)
CONFIG_SKB_EXTENSIONS - needed for connection tracking (supported from kernel 5.6)
CONFIG_NET_CLS_MATCHALL
CONFIG_NET_ACT_POLICE
CONFIG_MLX5_ESWITCH

cat /boot/config-4.18.0-193.28.1.el8.cuc.x86_64 | grep -E "CONFIG_NET_ACT_CSUM|CONFIG_NET_ACT_PEDIT|CONFIG_NET_ACT_MIRRED|CONFIG_NET_ACT_CT|CONFIG_NET_ACT_VLAN|CONFIG_NET_ACT_GACT|CONFIG_NET_CLS_FLOWER|CONFIG_NET_CLS_ACT|CONFIG_NET_SWITCHDEV|CONFIG_NET_TC_SKB_EXT|CONFIG_NET_ACT_CT|CONFIG_NFT_FLOW_OFFLOAD|CONFIG_NET_ACT_TUNNEL_KEY|CONFIG_NF_FLOW_TABLE|CONFIG_SKB_EXTENSIONS|CONFIG_NET_CLS_MATCHALL|CONFIG_NET_ACT_POLICE|CONFIG_MLX5_ESWITCH"

grep -E "CONFIG_MLX5_ESWITCH|CONFIG_NET_ACT_CSUM|CONFIG_NET_ACT_CT|CONFIG_NET_ACT_GACT|CONFIG_NET_ACT_MIRRED|CONFIG_NET_ACT_PEDIT|CONFIG_NET_ACT_POLICE|CONFIG_NET_ACT_TUNNEL_KEY|CONFIG_NET_ACT_VLAN|CONFIG_NET_CLS_ACT|CONFIG_NET_CLS_FLOWER|CONFIG_NET_CLS_MATCHALL|CONFIG_NET_SWITCHDEV|CONFIG_NET_TC_SKB_EXT|CONFIG_NFT_FLOW_OFFLOAD|CONFIG_NF_FLOW_TABLE|CONFIG_SKB_EXTENSIONS"

# rhel 8.3 kernel
[root@cuc ~]# cat /boot/config-4.18.0-240.el8.x86_64 | grep -E "CONFIG_MLX5_ESWITCH|CONFIG_NET_ACT_CSUM|CONFIG_NET_ACT_CT|CONFIG_NET_ACT_GACT|CONFIG_NET_ACT_MIRRED|CONFIG_NET_ACT_PEDIT|CONFIG_NET_ACT_POLICE|CONFIG_NET_ACT_TUNNEL_KEY|CONFIG_NET_ACT_VLAN|CONFIG_NET_CLS_ACT|CONFIG_NET_CLS_FLOWER|CONFIG_NET_CLS_MATCHALL|CONFIG_NET_SWITCHDEV|CONFIG_NET_TC_SKB_EXT|CONFIG_NFT_FLOW_OFFLOAD|CONFIG_NF_FLOW_TABLE|CONFIG_SKB_EXTENSIONS" | grep -Ev "^#" | sort
CONFIG_MLX5_ESWITCH=y
CONFIG_NET_ACT_CSUM=m
CONFIG_NET_ACT_CT=m
CONFIG_NET_ACT_GACT=m
CONFIG_NET_ACT_MIRRED=m
CONFIG_NET_ACT_PEDIT=m
CONFIG_NET_ACT_POLICE=m
CONFIG_NET_ACT_TUNNEL_KEY=m
CONFIG_NET_ACT_VLAN=m
CONFIG_NET_CLS_ACT=y
CONFIG_NET_CLS_FLOWER=m
CONFIG_NET_CLS_MATCHALL=m
CONFIG_NET_SWITCHDEV=y
CONFIG_NET_TC_SKB_EXT=y
CONFIG_NFT_FLOW_OFFLOAD=m
CONFIG_NF_FLOW_TABLE=m
CONFIG_NF_FLOW_TABLE_INET=m
CONFIG_SKB_EXTENSIONS=y
```

在CentOS 8 / RHEL 8上安装Open vSwitch<br>
https://zh.codepre.com/how-to-10451.html
```
sudo dnf install -y epel-release
sudo dnf install -y centos-release-openstack-ussuri
# sudo dnf install -y centos-release-nfv-openvswitch
sudo dnf install openvswitch libibverbs 

# 获取 rpm 编译选项 
# $ rpm -q --queryformat="%{NAME}: %{OPTFLAGS}\n" <package>

# DPDK 19.11 is out! Why you should update and how to do so
https://medium.com/@lhamthomas45/dpdk-19-11-is-out-why-you-should-update-and-how-to-do-so-7395810f71e

# 
sudo yumdownloader --source openvswitch2.13
sudo yum-builddep openvswitch2.13
rpm -ivh openvswitch2.13-2.13.0-79.5.1.el8.src.rpm

cd ~/rpmbuild/SPECS
rpmbuild -bb --target=`uname -m` --without check --without check_datapath_kernel openvswitch2.13.spec 2>build-err.log | tee build-info.log

# 编译 dpdk on rhel8 需卸载 mellanox ofed 5.2
# /usr/sbin/ofed_uninstall.sh

# 然后执行
# cd ~/rpmbuild/SPECS
# yum-builddep dpdk.spec


```


```
sudo subscription-manager repos --disable=* --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-baseos-source-rpms --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhel-8-for-x86_64-appstream-source-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-source-rpms --enable=openstack-16.1-for-rhel-8-x86_64-rpms --enable=codeready-builder-for-rhel-8-x86_64-rpms 
sudo yum clean all
sudo yum makecache

mkdir -p /repo
cd /repo

cat > ./repo_sync_up.sh <<'EOF'
#!/bin/bash

localPath="/repo/"
fileConn="/getPackage/"

## sync following yum repos 
# rhel-8-for-x86_64-baseos-rpms
# rhel-8-for-x86_64-baseos-source-rpms
# rhel-8-for-x86_64-appstream-rpms
# rhel-8-for-x86_64-appstream-source-rpms
# fast-datapath-for-rhel-8-x86_64-rpms
# fast-datapath-for-rhel-8-x86_64-source-rpms
# openstack-16.1-for-rhel-8-x86_64-rpms
# codeready-builder-for-rhel-8-x86_64-rpms

for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-baseos-source-rpms rhel-8-for-x86_64-appstream-rpms rhel-8-for-x86_64-appstream-source-rpms fast-datapath-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-source-rpms openstack-16.1-for-rhel-8-x86_64-rpms codeready-builder-for-rhel-8-x86_64-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync --download-path="$localPath" --repoid $i --download-metadata

done

exit 0
EOF
```



### ceph 相关的内容
在ceph中：pool、PG、OSD的关系<br>
https://www.cnblogs.com/wangmo/p/10826337.html<br>

调整ceph的pg数（pg_num， pgp_num）<br>
https://www.jianshu.com/p/ae96ee24ef6c

ceph pg, osd, pool 之间的一些查找方法<br>
https://blog.csdn.net/hello_nb1/article/details/76528243<br>
```
# pg, osd, pool 之间的一些查找方法
# 1. pg --> osd: 通过 pg 查找 osd
ceph pg map {pgid}

# 2. osd --> pg: 通过 osd 查找 pg
ceph pg ls-by-osd osd.{osdid}

# 3. pg --> pool: 通过 pg 查找 pool
ceph pg dump | grep "^{poolid}\."

# 4. pool --> pg: 通过 pool 查找 pg
# poolid 通过 ceph osd pool ls detail 可查看到
ceph pg ls-by-pool {poolname}
ceph pg ls {poolid}

# 5. object --> osd: 通过 object 查找 osd
ceph osd map {poolname} {objectname}



# 查看 pool 的详情
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool ls detail 
pool 1 'vms' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 38 flags hashpspool stripe_width 0 application rbd
pool 2 'volumes' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 39 flags hashpspool stripe_width 0 application rbd
pool 3 'images' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 54 flags hashpspool,selfmanaged_snaps stripe_width 0 application rbd
        removed_snaps [1~3]
pool 4 '.rgw.root' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 44 flags hashpspool stripe_width 0 application rgw
pool 5 'default.rgw.control' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 46 flags hashpspool stripe_width 0 application rgw
pool 6 'default.rgw.meta' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 49 flags hashpspool stripe_width 0 application rgw
pool 7 'default.rgw.log' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 50 flags hashpspool stripe_width 0 application rgw

# 看看 OSD 的使用情况
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd df 
Warning: Permanently added 'overcloud-controller-0.ctlplane' (ECDSA) to the list of known hosts.
ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA     OMAP    META     AVAIL   %USE VAR  PGS STATUS 
 0   hdd 0.09769  1.00000 100 GiB 2.1 GiB  1.1 GiB  20 KiB 1024 MiB  98 GiB 2.07 1.01 300     up 
 3   hdd 0.09769  1.00000 100 GiB 2.0 GiB 1022 MiB  20 KiB 1024 MiB  98 GiB 2.00 0.97 302     up 
 6   hdd 0.09769  1.00000 100 GiB 2.1 GiB  1.1 GiB  20 KiB 1024 MiB  98 GiB 2.09 1.02 294     up 
 1   hdd 0.09769  1.00000 100 GiB 1.8 GiB  869 MiB     0 B    1 GiB  98 GiB 1.85 0.90 275     up 
 4   hdd 0.09769  1.00000 100 GiB 2.4 GiB  1.4 GiB     0 B    1 GiB  98 GiB 2.40 1.17 343     up 
 7   hdd 0.09769  1.00000 100 GiB 1.9 GiB  934 MiB  24 KiB 1024 MiB  98 GiB 1.91 0.93 278     up 
 2   hdd 0.09769  1.00000 100 GiB 2.1 GiB  1.1 GiB     0 B    1 GiB  98 GiB 2.12 1.03 298     up 
 5   hdd 0.09769  1.00000 100 GiB 2.2 GiB  1.2 GiB     0 B    1 GiB  98 GiB 2.17 1.06 321     up 
 8   hdd 0.09769  1.00000 100 GiB 1.9 GiB  885 MiB  60 KiB 1024 MiB  98 GiB 1.86 0.91 277     up 
                    TOTAL 900 GiB  18 GiB  9.5 GiB 145 KiB  9.0 GiB 881 GiB 2.05                 
MIN/MAX VAR: 0.90/1.17  STDDEV: 0.16

PG   OBJECTS DEGRADED MISPLACED UNFOUND BYTES OMAP_BYTES* OMAP_KEYS* LOG STATE        SINCE VERSION REPORTED UP        ACTING    SCRUB_STAMP                DEEP_SCRUB_STAMP


# 查看 pool '.rgw.root' 的 pg 信息
# ceph pg ls-by-pool {poolname}
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph pg ls-by-pool .rgw.root
PG   OBJECTS DEGRADED MISPLACED UNFOUND BYTES OMAP_BYTES* OMAP_KEYS* LOG STATE        SINCE VERSION REPORTED UP        ACTING    SCRUB_STAMP                DEEP_SCRUB_STAMP
4.0        0        0         0       0     0           0          0   0 active+clean   19m     0'0  418:281 [4,0,8]p4 [4,0,8]p4 2021-03-15 06:28:22.456470 2021-03-08 15:19
:59.862615 
4.1        0        0         0       0     0           0          0   0 active+clean   19m     0'0  418:303 [2,6,1]p2 [2,6,1]p2 2021-03-15 06:25:57.798662 2021-03-15 06:25
:57.798662 
...
4.70       1        0         0       0   348           0          0   2 active+clean   16m    67'2  419:361 [2,4,3]p2 [2,4,3]p2 2021-03-15 06:47:02.089029 2021-03-15 06:47:02.089029 
...
4.77       1        0         0       0   348           0          0   2 active+clean   14m   419'2  419:312 [5,0,7]p5 [5,0,7]p5 2021-03-15 06:48:35.847218 2021-03-15 06:48:35.847218
... 


# 根据 poolid 查看与之关联的 pg
# ceph pg dump | grep "^{poolid}\." 
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph pg dump | grep "^4\." 
4.48          0                  0        0         0       0        0           0          0    0        0 active+clean 2021-03-15 06:47:25.267969       0'0    419:310 [2,1,6]          2 [2,1,6]              2        0'0 2021-03-15 06:47:25.267895             0'0 2021-03-15 06:47:25.267895             0 
4.49          0                  0        0         0       0        0           0          0    0        0 active+clean 2021-03-15 06:42:16.420103       0'0    418:291 [6,8,7]          6 [6,8,7]              6        0'0 2021-03-15 06:28:40.499086             0'0 2021-03-15 06:28:40.499086             0
...
4.7e          0                  0        0         0       0        0           0          0    0        0 active+clean 2021-03-15 06:49:28.776771       0'0    419:255 [0,4,5]          0 [0,4,5]              0        0'0 2021-03-15 06:49:28.776720             0'0 2021-03-09 06:58:46.981165             0 
4.79          0                  0        0         0       0        0           0          0    0        0 active+clean 2021-03-15 06:49:40.258519       0'0    419:304 [5,4,6]          5 [5,4,6]              5        0'0 2021-03-15 06:49:40.258460             0'0 2021-03-15 06:49:40.258460             0 
4.78          0                  0        0         0       0        0           0          0    0        0 active+clean 2021-03-15 06:42:16.434859       0'0    418:292 [0,8,7]          0 [0,8,7]              0        0'0 2021-03-15 06:25:59.023398             0'0 2021-03-15 06:25:59.023398             0 
4.7b          0                  0        0         0       0        0           0          0    0        0 active+clean 2021-03-15 06:50:05.392248       0'0    419:299 [5,3,1]          5 [5,3,1]              5        0'0 2021-03-15 06:50:05.392156             0'0 2021-03-15 06:50:05.392156             0 
4.7a          0                  0        0         0       0        0           0          0    0        0 active+clean 2021-03-15 06:42:07.069141       0'0    418:323 [2,3,1]          2 [2,3,1]              2        0'0 2021-03-15 06:30:39.129062             0'0 2021-03-15 06:30:39.129062             0


# 根据 pgid 查看与之关联的 osd
# ceph pg map {pgid}
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph pg map 4.48
osdmap e419 pg 4.48 (4.48) -> up [2,1,6] acting [2,1,6]

# 通过 osd 查找 pg
# ceph pg ls-by-osd osd.{osdid}
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph pg ls-by-osd osd.2
PG   OBJECTS DEGRADED MISPLACED UNFOUND BYTES    OMAP_BYTES* OMAP_KEYS* LOG  STATE        SINCE VERSION   REPORTED  UP        ACTING    SCRUB_STAMP                DEEP_SCRU
B_STAMP           
1.7        0        0         0       0        0           0          0    0 active+clean   36m       0'0   418:291 [6,2,7]p6 [6,2,7]p6 2021-03-15 06:30:18.656514 2021-03-0
8 21:58:13.664190 
1.b        0        0         0       0        0           0          0    0 active+clean   36m       0'0   418:333 [2,1,3]p2 [2,1,3]p2 2021-03-15 06:33:56.501144 2021-03-0
9 06:13:55.557107 
...
4.48       0        0         0       0        0           0          0    0 active+clean   32m       0'0   419:310 [2,1,6]p2 [2,1,6]p2 2021-03-15 06:47:25.267895 2021-03-1
5 06:47:25.267895 
...

# PG 的计算公式
# Total PGs = ((Total_number_of_OSD * 100) / max_replication_count) / pool_count
# 默认 openstack pool 数量是 7，max_replication_count 是 3，在实验环境下 Total_number_of_OSD 为 9
# 按照这个公式 Total PGs = ((9 *100) / 3 ) / 7 = 42，在默认部署的测试环境下这个值为 128 

# 调整ceph的pg数（pg_num， pgp_num）
# https://www.jianshu.com/p/ae96ee24ef6c

# 获取 pool vms 的 pg_num 和 pgp_num
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool get vms pg_num 
pg_num: 128
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool get vms pgp_num 
pgp_num: 128

# 检查 pool vms 的副本数量
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd dump | grep size | grep vms
pool 1 'vms' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 autoscale_mode warn last_change 38 flags hashpspool stripe_width 0 application rbd

# 设置 pool vms 的 pg_num 和 pgp_num 
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set vms pg_num 256
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set vms pgp_num 256

# 如果有其他pool，同步调整它们的pg_num和pgp_num，以使负载更加均衡

# 查看集群的 pg 数量
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph status | grep pgs
    pools:   7 pools, 896 pgs
    pgs:     896 active+clean
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph pg dump 2>/dev/null | egrep '^[0-9]+\.[0-9a-f]+\s' | wc -l
896
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph pg ls | egrep '^[0-9]+\.[0-9a-f]+\s' | wc -l

# 查看集群 pool 的类型，副本数量，以及 pg_num
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd dump | grep pool | awk '{print $1,$3,$4,$5":"$6,$13":"$14}'
pool 'vms' replicated size:3 pg_num:128
pool 'volumes' replicated size:3 pg_num:128
pool 'images' replicated size:3 pg_num:128
pool '.rgw.root' replicated size:3 pg_num:128
pool 'default.rgw.control' replicated size:3 pg_num:128
pool 'default.rgw.meta' replicated size:3 pg_num:128
pool 'default.rgw.log' replicated size:3 pg_num:128

# 从 osd 的角度来看，osd 所保存的 pg 的数量是 pool_pgnum 乘以 pool_replicated_size 之和
# 在这个例子里应该为 (3*128)*7 = 2688
# https://opengers.github.io/ceph/ceph-pgs-total-number/
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd dump | grep pool | awk '{a+=$6 * $14} END{print a}'
2688

# 用 ceph osd df tree 的输出里的第 19 个字段求和也可以获得总的 osd 层面看到的 pg 的总数
# ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA     OMAP    META     AVAIL   %USE VAR  PGS STATUS TYPE NAME                       
# -1       0.87918        - 900 GiB  18 GiB  9.5 GiB 144 KiB  9.0 GiB 881 GiB 2.05 1.00   -        root default                    
# -5       0.29306        - 300 GiB 6.2 GiB  3.2 GiB  60 KiB  3.0 GiB 294 GiB 2.05 1.00   -            host overcloud-controller-0 
#  0   hdd 0.09769  1.00000 100 GiB 2.1 GiB  1.1 GiB  20 KiB 1024 MiB  98 GiB 2.07 1.01 300     up         osd.0                   
#  3   hdd 0.09769  1.00000 100 GiB 2.0 GiB 1022 MiB  20 KiB 1024 MiB  98 GiB 2.00 0.97 302     up         osd.3                   
#  6   hdd 0.09769  1.00000 100 GiB 2.1 GiB  1.1 GiB  20 KiB 1024 MiB  98 GiB 2.09 1.02 294     up         osd.6                   
# -3       0.29306        - 300 GiB 6.2 GiB  3.2 GiB  24 KiB  3.0 GiB 294 GiB 2.05 1.00   -            host overcloud-controller-1 
#  1   hdd 0.09769  1.00000 100 GiB 1.8 GiB  869 MiB     0 B    1 GiB  98 GiB 1.85 0.90 275     up         osd.1                   
#  4   hdd 0.09769  1.00000 100 GiB 2.4 GiB  1.4 GiB     0 B    1 GiB  98 GiB 2.40 1.17 343     up         osd.4                   
#  7   hdd 0.09769  1.00000 100 GiB 1.9 GiB  934 MiB  24 KiB 1024 MiB  98 GiB 1.91 0.93 278     up         osd.7                   
# -7       0.29306        - 300 GiB 6.2 GiB  3.2 GiB  60 KiB  3.0 GiB 294 GiB 2.05 1.00   -            host overcloud-controller-2 
#  2   hdd 0.09769  1.00000 100 GiB 2.1 GiB  1.1 GiB     0 B    1 GiB  98 GiB 2.12 1.03 298     up         osd.2                   
#  5   hdd 0.09769  1.00000 100 GiB 2.2 GiB  1.2 GiB     0 B    1 GiB  98 GiB 2.17 1.06 321     up         osd.5                   
#  8   hdd 0.09769  1.00000 100 GiB 1.9 GiB  885 MiB  60 KiB 1024 MiB  98 GiB 1.86 0.91 277     up         osd.8                        
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd df tree  | grep "osd\." | awk '{a+=$19} END{print a}'
2688

# 查看 ceph pool .rgw.root 下的对象
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 rados -p .rgw.root ls
zonegroup_info.ef2d8ef7-c984-493f-b7ca-1115634d1cad
zonegroup_info.1ac8f5ad-54cf-4711-acf0-12209b12baa7
zone_info.e89400ff-e6f5-4499-9af1-05214e6b7a5c
zone_info.7c79b120-7619-412d-98c3-3e9a07adc91d
zonegroup_info.980e9bde-e852-4a36-9a21-db90bc7e80ff
zone_names.default
zonegroups_names.default

# 查看 ceph pool images 下的对象
# 其中 rbd_data.12992731673d 是 pool images 下对象的指纹
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 rados -p images ls
rbd_data.12992731673d.000000000000016f
rbd_data.12992731673d.000000000000007e
rbd_data.12992731673d.000000000000003d
rbd_data.12992731673d.00000000000000da
rbd_data.12992731673d.00000000000000b5
rbd_data.12992731673d.0000000000000115
rbd_data.12992731673d.0000000000000098
rbd_data.12992731673d.000000000000013d
rbd_data.12992731673d.0000000000000179
rbd_data.12992731673d.000000000000000f
rbd_data.12992731673d.000000000000015b
...

# 在 overcloud 环境下有 2 个 image
(overcloud) [stack@undercloud ~]$ openstack image list
+--------------------------------------+----------------------------------------+--------+
| ID                                   | Name                                   | Status |
+--------------------------------------+----------------------------------------+--------+
| 0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98 | cirros                                 | active |
| 969681be-3b1b-4929-bf42-a314845aacb2 | octavia-amphora-16.1-20201202.1.x86_64 | active |
+--------------------------------------+----------------------------------------+--------+

# 这两个 image 保存在 ceph pool images 里，可以用命令 rbd ls <poolname> 查看
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 rbd ls images
0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98
969681be-3b1b-4929-bf42-a314845aacb2

# openstack 下的 glance image cirros 的 uuid 是 0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98
# 对应的 ceph rbd 为 images/0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98
# 通过如下命令可以获得 rbd image 详情
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 rbd info images/0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98
rbd image '0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98':
        size 12 MiB in 2 objects
        order 23 (8 MiB objects)
        snapshot_count: 1
        id: 2b91e55369472
        block_name_prefix: rbd_data.2b91e55369472
        format: 2
        features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
        op_features: 
        flags: 
        create_timestamp: Mon Mar 15 09:03:27 2021
        access_timestamp: Mon Mar 15 09:03:27 2021
        modify_timestamp: Mon Mar 15 09:03:27 2021

# 看看 cirros 对应的 ceph object
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 rados -p images ls | grep rbd_data.2b91e55369472 
rbd_data.2b91e55369472.0000000000000000
rbd_data.2b91e55369472.0000000000000001 

查看 rbd 卷信息和黑名单
# rbd info volumes/5411f117-c4ea-43f9-b4db-e714b49d54a7
# ceph osd blacklist ls
```

# 关于 Erasure Code 的说明
https://blog.csdn.net/sinat_27186785/article/details/52034588<br>

Using Erasure Coding with RadosGW<br>
https://ceph.io/planet/using-erasure-coding-with-radosgw/<br>

Erasure Code<br>
https://github.com/kairen/learning-ceph/blob/master/ceph-storage-cluster/erasure-codes/README.md

# Ceph Mirror
https://source.redhat.com/communitiesatredhat/infrastructure/storage-cop/storage_community_of_practice_wiki/rhcs_4x_rbd_mirroring_steps<br>
https://docs.ceph.com/en/latest/rbd/rbd-mirroring/<br>
http://www.yangguanjun.com/2019/06/30/ceph-rbd-mirroring/<br>
https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html/block_device_guide/block_device_mirroring<br>
https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html/block_device_guide/mirroring-ceph-block-devices<br>
https://www.infoq.cn/article/9rddkkpmu10*zs9ahrwh<br>
```
rbd mirror pool enable {pool-name} {mode}

$ rbd --cluster site-a mirror pool enable image-pool image
$ rbd --cluster site-b mirror pool enable image-pool image

# site-a: create mirror bootstrap token
$ rbd --cluster site-a mirror pool peer bootstrap create --site-name site-a image-pool
eyJmc2lkIjoiOWY1MjgyZGItYjg5OS00NTk2LTgwOTgtMzIwYzFmYzM5NmYzIiwiY2xpZW50X2lkIjoicmJkLW1pcnJvci1wZWVyIiwia2V5IjoiQVFBUnczOWQwdkhvQmhBQVlMM1I4RmR5dHNJQU50bkFTZ0lOTVE9PSIsIm1vbl9ob3N0IjoiW3YyOjE5Mi4xNjguMS4zOjY4MjAsdjE6MTkyLjE2OC4xLjM6NjgyMV0ifQ==

# site-b: import site-a mirror bootstrap token
$ cat <<EOF > token
eyJmc2lkIjoiOWY1MjgyZGItYjg5OS00NTk2LTgwOTgtMzIwYzFmYzM5NmYzIiwiY2xpZW50X2lkIjoicmJkLW1pcnJvci1wZWVyIiwia2V5IjoiQVFBUnczOWQwdkhvQmhBQVlMM1I4RmR5dHNJQU50bkFTZ0lOTVE9PSIsIm1vbl9ob3N0IjoiW3YyOjE5Mi4xNjguMS4zOjY4MjAsdjE6MTkyLjE2OC4xLjM6NjgyMV0ifQ==
EOF
$ rbd --cluster site-b mirror pool peer bootstrap import --site-name site-b image-pool token

$ rbd --cluster site-a mirror pool peer add image-pool client.rbd-mirror-peer@site-b
$ rbd --cluster site-b mirror pool peer add image-pool client.rbd-mirror-peer@site-a
```

# Ceph RBD features
http://docs.ceph.org.cn/man/8/rbd/<br>

feature object-map<br>
https://www.sebastien-han.fr/blog/2015/07/06/ceph-enable-the-object-map-feature/<br>

ceph internals<br>
https://www.bookstack.cn/read/ceph-en/96ed51f9a1913a46.md<br>

RBD EXCLUSIVE LOCKS<br>
https://docs.ceph.com/en/latest/rbd/rbd-exclusive-locks/<br>

https://docs.ceph.com/en/latest/man/8/rbd/<br>

https://documentation.suse.com/ses/5.5/html/ses-all/ceph-rbd.html#ceph-rbd-mirror<br>

https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html-single/block_device_guide/index#the-rbdmap-service_block<br>
```
# --image-feature feature-name
# 指定创建 format 2 格式的 RBD 映像时，要启用的特性。可以通过重复此选项来启用多个特性。当前支持下列特性：
# layering: 支持分层
# striping: 支持条带化 v2
# exclusive-lock: 支持独占锁
# object-map: 支持对象映射（依赖 exclusive-lock ）
# fast-diff: 快速计算差异（依赖 object-map ）
# deep-flatten: 支持快照扁平化操作
# journaling: 支持记录 IO 操作（依赖独占锁）
# 
# --image-feature feature-name
# Specifies which RBD format 2 feature should be enabled when creating an image. Multiple features can be enabled by repeating this option multiple times. The following features are supported:
# layering: layering support                                        id: 1
# striping: striping v2 support                                     id: 2
# exclusive-lock: exclusive locking support                         id: 4
# object-map: object map support (requires exclusive-lock)          id: 8
# fast-diff: fast diff calculations (requires object-map)           id: 16
# deep-flatten: snapshot flatten support                            id: 32
# journaling: journaled IO support (requires exclusive-lock)        id: 64
# data-pool: erasure coded pool support                             id: 128
# 
# osp 16.1 glance image 启用了哪些 feature
#         format: 2
# 启用了：layering, exclusive-lock, object-map, fast-diff, deep-flatten
ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 rbd info images/0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98 
Warning: Permanently added 'overcloud-controller-2.ctlplane' (ECDSA) to the list of known hosts.
rbd image '0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98':
        size 12 MiB in 2 objects
        order 23 (8 MiB objects)
        snapshot_count: 1
        id: 2b91e55369472
        block_name_prefix: rbd_data.2b91e55369472
        format: 2
        features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
        op_features: 
        flags: 
        create_timestamp: Mon Mar 15 09:03:27 2021
        access_timestamp: Mon Mar 15 09:03:27 2021
        modify_timestamp: Mon Mar 15 09:03:27 2021

ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 rbd create images/a -s 1G   
ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 rbd du images/a
NAME PROVISIONED USED 
a          1 GiB  0 B 

(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 rbd info images/a 
Warning: Permanently added 'overcloud-controller-2.ctlplane' (ECDSA) to the list of known hosts.
rbd image 'a':
        size 1 GiB in 256 objects
        order 22 (4 MiB objects)
        snapshot_count: 0
        id: 374b4e4926d8f
        block_name_prefix: rbd_data.374b4e4926d8f
        format: 2
        features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
        op_features: 
        flags: 
        create_timestamp: Mon Mar 22 08:31:37 2021
        access_timestamp: Mon Mar 22 08:31:37 2021
        modify_timestamp: Mon Mar 22 08:31:37 2021

(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 rbd -p images bench --io-type write a --io-size 4096 --io-threads 1 --io-total 4096 --io-pattern rand
bench  type write io_size 4096 io_threads 1 bytes 4096 pattern random
  SEC       OPS   OPS/SEC   BYTES/SEC
elapsed:     0  ops:        1  ops/sec:    22.73  bytes/sec: 93090.83

(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 rbd du images/a
NAME PROVISIONED USED  
a          1 GiB 8 MiB

(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 rbd -p images feature enable a journaling

ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 rbd -p images info a

(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 rbd -p images info a
rbd image 'a':
        size 1 GiB in 256 objects
        order 22 (4 MiB objects)
        snapshot_count: 0
        id: 374b4e4926d8f
        block_name_prefix: rbd_data.374b4e4926d8f
        format: 2
        features: layering, exclusive-lock, object-map, fast-diff, deep-flatten, journaling
        op_features: 
        flags: 
        create_timestamp: Mon Mar 22 08:31:37 2021
        access_timestamp: Mon Mar 22 08:31:37 2021
        modify_timestamp: Mon Mar 22 08:34:41 2021
        journal: 374b4e4926d8f
        mirroring state: disabled

(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 rbd -p images rm a 
Removing image: 100% complete...done.

# 删除大的 rbd image
# 参考：https://ceph.io/geen-categorie/remove-big-rbd-image/

[root@rbd-client ~]# rbd --pool rbd snap create --snap snapname foo
[root@rbd-client ~]# rbd snap create rbd/foo@snapname

[root@rbd-client ~]# rbd --pool rbd snap ls foo
[root@rbd-client ~]# rbd snap ls rbd/foo

[root@rbd-client ~]# rbd --pool rbd snap rollback --snap snapname foo
[root@rbd-client ~]# rbd snap rollback rbd/foo@snapname

[root@rbd-client ~]# rbd --pool rbd snap rm --snap snapname foo
[root@rbd-client ~]# rbd snap rm rbd/foo@snapname

# Rook Ceph Backup 
https://gitlab.com/jrevolt/rook-ceph-backup
```

# Red Hat Ceph Storage 4.1 新特性 
https://www.redhat.com/en/blog/updating-nautilus-cornerstone-red-hats-ceph-storage-platform<br>

# RHV DR 
Can RHV manage failover to a disaster recovery (DR) site?<br>
https://access.redhat.com/solutions/2044903<br>

# 如何使用 softdog
https://access.redhat.com/solutions/3892631<br>
https://datahunter.org/watchdog<br>
https://qkxu.github.io/2019/04/15/linux%E4%B8%8B%E7%9A%84watchdog.html<br>
```
yum install -y watchdog

# 加载内核模块 softdog
modprobe softdog

# 配置重启加载 softdog
echo softdog > /etc/modules-load.d/watchdog.conf
systemctl restart systemd-modules-load

# 在加载 softdog 模块后检查
ls /dev/watchdog*
wdctl /dev/watchdog1

# 查看 watchdog 相关信息
grep . /sys/class/watchdog/watchdog0/*
grep . /sys/class/watchdog/watchdog1/*

lsof | grep watchdog0
wdmd       1258                  root    8w      CHR              251,0          0t0      14659 /dev/watchdog0

ps awwx | grep 1258
 1258 ?        SLs    0:55 /usr/sbin/wdmd

cat > /etc/watchdog.conf << EOF
watchdog-device = /dev/watchdog1
interval = 10
max-load-1 = 0
max-load-5 = 18
max-load-15 = 12
file = /var/log/messages    
change = 600
logtick = 10
ping = 10.66.208.254
EOF

systemctl enable watchdog-ping
systemctl start watchdog-ping

grep . /sys/class/watchdog/watchdog1/*

# 检查是否生效
iptables -A OUTPUT -p icmp -j DROP


```


# RHEL7 single user mode
https://www.tecmint.com/boot-into-single-user-mode-in-centos-7/
```
# edit grub boot param
linux16 ... rw init=/sysroot/bin/sh ...

# press CTRL_x

# chroot /sysroot

# reboot -f
```

# RHEL7 安装 javaws 工具
```
# 这个软件在 rhel-7-server-rpms 软件仓库里
yum install -y icedtea-web
```

# OpenStack DR
https://hystax.com/disaster-recovery-to-openstack/<br>
https://www.trilio.io/openstack-backup/<br>


# misc
```
# 检查系统日志
cat messages | grep -Ev "node2 ptp4l|systemd: Started Session |systemd-logind: New session |systemd: Starting Session |systemd-logind: Removed session |systemd: Removed slice |systemd: Stopping User Slice|systemd: Created slice User Slice|systemd: Starting User Slice |systemd: Started Security Auditing Service|augenrules|auditd|audispd|systemd: Starting Security Auditing Service|audit|rhsmd|insights|Insights|random time|lldpad|NetworkManager|Virtual Machine|lvm2-lvmetad.socket|vdsmd_init_common.sh|ovirtmgmt|systemd|dracut|journal|kernel|goferd|watchdog|vdsm-tool|phc2sys|saslpasswd2|network|imgbase|chronyd|libvirtd|kdumpctl|rhnsd|dbus|sm-notify|rpc|multipathd|sshd|iscsid|sanlock" 
```

# osp16.1: overcloud 与外部 ceph 集群的集成
https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/ceph_external.html<br>
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html-single/integrating_an_overcloud_with_an_existing_red_hat_ceph_cluster/index<br>
```
# 外部的 ceph cluster 需包含以下 pool 
volumes: Storage for OpenStack Block Storage (cinder)
images: Storage for OpenStack Image Storage (glance)
vms: Storage for instances
backups: Storage for OpenStack Block Storage Backup (cinder-backup) (实际实施时应该有 cinder-backup，因此应该有这个 pool )
metrics: Storage for OpenStack Telemetry Metrics (gnocchi) （实际实施时，根据实际监控的配置情况，这个 pool 可能有，也可能没有 ）

除此之外，还有 cephfs 的 data pool 和 metadata pool

# 创建 client.openstack 用户，具备以下权限
ceph auth add client.openstack mgr 'allow *' mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd pool=images, profile rbd pool=backups, profile rbd pool=metrics'

(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 ceph auth list
client.openstack
        key: AQAThD1gAAAAABAAFwnlKS3dVFb+BJuA3GRnYQ==
        caps: [mgr] allow *
        caps: [mon] profile rbd
        caps: [osd] profile rbd pool=vms, profile rbd pool=volumes, profile rbd pool=images

# 如果安装了 Manila + CephFS，还需要创建 client.manila 用户
ceph auth add client.manila mon 'allow r, allow command "auth del", allow command "auth caps", allow command "auth get", allow command "auth get-or-create"' osd 'allow rw' mds 'allow *' mgr 'allow *'

# 记录 client.manila 的 auth key 
ceph auth get-key client.manila

# 记录外部 ceph 集群的 cluster fsid
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-2 cat /etc/ceph/ceph.conf | grep fsid
fsid = 765cff5c-012e-4871-9d19-cf75eaf27769


# overcloud 与外部 ceph cluster 集成时用到的模版
/usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible-external.yaml

# 如果配置 Manilia + native cephfs
/usr/share/openstack-tripleo-heat-templates/environments/manila-cephfsnative-config.yaml

# 如果配置 Manila + cephfs + nfs
/usr/share/openstack-tripleo-heat-templates/environments/manila-cephfsganesha-config.yaml

# 创建 /home/stack/templates/ceph-config.yaml 模版文件
# 添加 CephClientKey，内容来自 ceph auth get-key client.openstack
# 添加 CephClusterFSID，内容来自外部 ceph cluster 的 fsid
# 添加 CephExternalMonHost，内容来自外部 ceph cluster 的 mon
cat > /home/stack/templates/ceph-config.yaml << EOF
parameter_defaults:
  # Enable use of RBD backend in nova-compute
  NovaEnableRbdBackend: true
  # Enable use of RBD backend in cinder-volume
  CinderEnableRbdBackend: true
  # Backend to use for cinder-backup
  CinderBackupBackend: ceph
  # Backend to use for glance
  GlanceBackend: rbd
  # Backend to use for gnocchi-metricsd
  GnocchiBackend: rbd
  # Name of the Ceph pool hosting Nova ephemeral images
  NovaRbdPoolName: vms
  # Name of the Ceph pool hosting Cinder volumes
  CinderRbdPoolName: volumes
  # Name of the Ceph pool hosting Cinder backups
  CinderBackupRbdPoolName: backups
  # Name of the Ceph pool hosting Glance images
  GlanceRbdPoolName: images
  # Name of the Ceph pool hosting Gnocchi metrics
  GnocchiRbdPoolName: metrics
  # Name of the user to authenticate with the external Ceph cluster
  CephClientUserName: openstack
  CephClientKey: AQDLOh1VgEp6FRAAFzT7Zw+Y9V6JJExQAsRnRQ==
  CephClusterFSID: 4b5c8c0a-ff60-454b-a1b4-9747aa737d19
  CephExternalMonHost: 172.16.1.7, 172.16.1.8
EOF

# 连接多外部集群的例子
CephExternalMultiConfig:
  - cluster: 'ceph2'
    fsid: 'af25554b-42f6-4d2b-9b9b-d08a1132d3e8'
    external_cluster_mon_ips: '172.18.0.5,172.18.0.6,172.18.0.7'
    keys:
      - name: "client.openstack"
        caps:
          mgr: "allow *"
          mon: "profile rbd"
          osd: "profile rbd pool=volumes, profile rbd pool=backups, profile rbd pool=vms, profile rbd pool=images"
        key: "AQCwmeRcAAAAABAA6SQU/bGqFjlfLro5KxrB1Q=="
        mode: "0600"
    dashboard_enabled: false
  - cluster: 'ceph3'
    fsid: 'e2cba068-5f14-4b0f-b047-acf375c0004a'
    external_cluster_mon_ips: '172.18.0.8,172.18.0.9,172.18.0.10'
    keys:
      - name: "client.openstack"
        caps:
          mgr: "allow *"
          mon: "profile rbd"
          osd: "profile rbd pool=volumes, profile rbd pool=backups, profile rbd pool=vms, profile rbd pool=images"
        key: "AQCwmeRcAAAAABAA6SQU/bGqFjlfLro5KxrB2Q=="
        mode: "0600"
    dashboard_enabled: false

# The above, in addition to the parameters from the previous section, will result in an overcloud with the following files in /etc/ceph:
ceph.client.openstack.keyring
ceph.conf
ceph2.client.openstack.keyring
ceph2.conf
ceph3.client.openstack.keyring
ceph3.conf

# 如果部署 Manila + external ceph cluster cephfs 的话
parameter_defaults:
  ManilaCephFSDataPoolName: manila_data
  ManilaCephFSMetadataPoolName: manila_metadata
  ManilaCephFSCephFSAuthId: 'manila'
  CephManilaClientKey: 'AQDLOh1VgEp6FRAAFzT7Zw+Y9V6JJExQAsRnRQ=='

# 添加 client.manila 用户并设置合适的权限
ceph auth add client.manila mgr "allow *" mon "allow r, allow command 'auth del', allow command 'auth caps', allow command 'auth get', allow command 'auth get-or-create'" mds "allow *" osd "allow rw"

# 与外部旧版本 ceph 集成需设置的参数 （Hammer）
parameter_defaults:
  ExtraConfig:
    ceph::profile::params::rbd_default_features: '1'


```

# OpenStack Backup 相关
https://wiki.openstack.org/wiki/Raksha<br>
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/10/html-single/instances_and_images_guide/index#section-create-consistent-snapshots<br>
https://docs.openstack.org/cinder/latest/admin/blockstorage-volume-backups.html<br>
https://wiki.openstack.org/wiki/Cinder/QuiescedSnapshotWithQemuGuestAgent<br>
https://github.com/vagnerfarias/osp13-backup/tree/main<br>
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html/undercloud_and_control_plane_back_up_and_restore/index<br>
https://raymii.org/s/tutorials/OpenStack_Quick_and_automatic_instance_snapshot_backups.html<br>


Site Recovery/DR solution with RedHat Openstack and HPE3PAR<br>
https://www.youtube.com/watch?v=qNRR3onC9SA<br>
没有实质性的内容，不推荐<br>

Group demo: How to build reliable disaster recovery for OpenStack<br>
https://www.youtube.com/watch?v=nVWnsKDh9tY<br>

OpenStack高可用（HA）和灾备（DR）解决方案<br>
https://blog.csdn.net/sj349781478/article/details/78522047<br>

导入镜像到 Ceph <br>
https://ceph.io/geen-categorie/openstack-import-existing-ceph-volumes-in-cinder/<br>

Volume migration between OpenStack clusters<br>
https://cloud.garr.it/support/kb/general/cinderVolumeMigration/<br>
```
export volName=volume-<hexString>
export volOSname=serverXdevVdB

cinder manage --name=$volOSname cinder-pa1-cl1@cinder-ceph-pa1-cl1#cinder-ceph-pa1-cl1 $volName

(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 /bin/bash
()[root@overcloud-controller-2 /]# cinder manage
cinder manage
usage: cinder manage [--cluster CLUSTER] [--id-type <id-type>] [--name <name>]
                     [--description <description>]
                     [--volume-type <volume-type>]
                     [--availability-zone <availability-zone>]
                     [--metadata [<key=value> [<key=value> ...]]] [--bootable]
                     <host> <identifier>

# 创建 volume 
(overcloud) [stack@undercloud ~]$ openstack volume create --size 1 test

(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd -p volumes ls 
volume-8106c740-5066-4b6c-a6e4-837afd23206a

(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd cp volumes/volume-8106c740-5066-4b6c-a6e4-837afd23206a volumes/volume-$(uuidgen)
Image copy: 100% complete...done.

(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd -p volumes ls 
volume-8106c740-5066-4b6c-a6e4-837afd23206a
volume-92b58cde-80f5-4ac4-8b61-12c100fdaa10

(overcloud) [stack@undercloud ~]$ export volName=volume-92b58cde-80f5-4ac4-8b61-12c100fdaa10    
(overcloud) [stack@undercloud ~]$ export volOSname=Server1Vda
(overcloud) [stack@undercloud ~]$ cinder manage --name=$volOSname hostgroup@tripleo_ceph#tripleo_ceph $volName
+--------------------------------+--------------------------------------+
| Property                       | Value                                |
+--------------------------------+--------------------------------------+
| attachments                    | []                                   |
| availability_zone              | nova                                 |
| bootable                       | false                                |
| consistencygroup_id            | None                                 |
| created_at                     | 2021-03-25T02:54:31.000000           |
| description                    | None                                 |
| encrypted                      | False                                |
| id                             | 181a75ec-172a-4066-b2a9-fb7b9c8a63eb |
| metadata                       | {}                                   |
| migration_status               | None                                 |
| multiattach                    | False                                |
| name                           | Server1Vda                           |
| os-vol-host-attr:host          | hostgroup@tripleo_ceph#tripleo_ceph  |
| os-vol-mig-status-attr:migstat | None                                 |
| os-vol-mig-status-attr:name_id | None                                 |
| os-vol-tenant-attr:tenant_id   | 1f76c7a530e34cf4a4958c86dc0946f8     |
| replication_status             | None                                 |
| size                           | 1                                    |
| snapshot_id                    | None                                 |
| source_volid                   | None                                 |
| status                         | available                            |
| updated_at                     | 2021-03-25T02:54:33.000000           |
| user_id                        | d44acc8f58034bcda7eaedd59e1a9be9     |
| volume_type                    | tripleo                              |
+--------------------------------+--------------------------------------+

(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd -p volumes ls 
volume-181a75ec-172a-4066-b2a9-fb7b9c8a63eb
volume-8106c740-5066-4b6c-a6e4-837afd23206a

1. 记录服务器的信息：服务器实例名称，规格，IP地址，卷名称，卷uuid
2. 虚拟机基于卷启动
3. 环境的基础配置保持两端的一致性
4. 配置租户，配额，网络，镜像
5. 根据以上信息，在新环境中恢复实例

(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd -p images ls
0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98
969681be-3b1b-4929-bf42-a314845aacb2

(overcloud) [stack@undercloud ~]$ openstack image list 
+--------------------------------------+----------------------------------------+--------+
| ID                                   | Name                                   | Status |
+--------------------------------------+----------------------------------------+--------+
| 0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98 | cirros                                 | active |
| 969681be-3b1b-4929-bf42-a314845aacb2 | octavia-amphora-16.1-20201202.1.x86_64 | active |
+--------------------------------------+----------------------------------------+--------+

(overcloud) [stack@undercloud ~]$ export imageUuid=$(uuidgen)
(overcloud) [stack@undercloud ~]$ export imageNewName=cirros1

(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd cp images/0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98 images/$imageUuid
Image copy: 100% complete...done.

(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd -p images ls
0ff57ef9-3b25-45fd-b2b3-a8fb08ac1a98
5a483e34-689b-4430-aa8f-fee8f0bdd500
969681be-3b1b-4929-bf42-a314845aacb2

# 参见： https://ceph.io/planet/importing-an-existing-ceph-rbd-image-into-glance/
# 参见： http://wordpress.hawkless.id.au/index.php/2018/04/26/openstack-queens-glance-create-an-image-from-an-existing-rbd-volume/
# 参见： https://ceph.io/geen-categorie/remove-snapshot-before-rbd/

(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd snap create images/${imageUuid}@snap
(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd snap protect images/${imageUuid}@snap

# 删除时执行
(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd snap unprotect images/${imageUuid}@snap
(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd snap purge images/${imageUuid}
(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-2.ctlplane sudo podman exec -it openstack-cinder-volume-podman-0 rbd rm images/${imageUuid}

# 用以下命令可以导入新生成的 image
(overcloud) [stack@undercloud ~]$  export CLUSTER_ID='765cff5c-012e-4871-9d19-cf75eaf27769'
(overcloud) [stack@undercloud ~]$  glance image-create \
  --disk-format raw \
  --container-format bare \
  --id $imageUuid \
  --name ${imageNewName}
(overcloud) [stack@undercloud ~]$  glance location-add --url rbd://$CLUSTER_ID/images/${imageUuid}/snap $imageUuid


```

# Intel N3000 Device driver on rhel7
```
# Install kernel header
yum install kernel-devel gcc -y

# Fetch i40e drivers from intel, on the RT compute node:
curl -o i40e-2.10.19.30.tar.gz   https://downloadcenter.intel.com/downloads/eula/24411/Intel-Network-Adapter-Driver-for-PCIe-40-Gigabit-Ethernet-Network-Connections-Under-Linux-?httpDown=https%3A%2F%2Fdownloadmirror.intel.com%2F24411%2Feng%2Fi40e-2.10.19.30.tar.gz

# Then build the RPM
rpmbuild -tb i40e-2.10.19.30.tar.gz

# Now this rpm can be installed on any compute node without the need for any repos, it doesn’t have any dependencies
yum localinstall -y i40e*.rpm

# Then reboot to allow the kernel to enumerate the interfaces:
reboot

sudo lshw -class network -businfo |grep FPGA
pci@0000:88:00.0  p5p1        network        Ethernet Controller XXV710 Intel(R) FPGA Programmable Acceleration Card N30
pci@0000:88:00.1  p5p2        network        Ethernet Controller XXV710 Intel(R) FPGA Programmable Acceleration Card N30
pci@0000:8c:00.0  p5p3        network        Ethernet Controller XXV710 Intel(R) FPGA Programmable Acceleration Card N30
pci@0000:8c:00.1  p5p4        network        Ethernet Controller XXV710 Intel(R) FPGA Programmable Acceleration Card N30
```

# Instance HA OSP 16.1
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html-single/high_availability_for_compute_instances/index<br>

When a Compute node fails, the Instance High Availability (HA) tool evacuates and re-creates the instances on a different Compute node.

Instance HA uses the following resource agents:
|Agent name|Name inside cluster|Role|
|---|---|---|
|fence_compute|fence-nova|Marks a Compute node for evacuation when the node becomes unavailable.|
|NovaEvacuate|nova-evacuate|Evacuates instances from failed nodes. This agent runs on one of the Controller nodes.|
|Dummy|compute-unfence-trigger|Releases a fenced node and enables the node to run instances again.|

The following events occur when a Compute node fails and triggers Instance HA:

At the time of failure, the IPMI agent performs first-layer fencing, which includes physically resetting the node to ensure that it shuts down and preventing data corruption or multiple identical instances on the overcloud. When the node is offline, it is considered fenced.<br>
After the physical IPMI fencing, the fence-nova agent automatically performs second-layer fencing and marks the fenced node with the “evacuate=yes” cluster per-node attribute by running the following command:

```
$ attrd_updater -n evacuate -A name="evacuate" host="FAILEDHOST" value="yes"
FAILEDHOST is the name of the failed Compute node.
```

The nova-evacuate agent continually runs in the background and periodically checks the cluster for nodes with the “evacuate=yes” attribute. When nova-evacuate detects that the fenced node contains this attribute, the agent starts evacuating the node. The evacuation process is similar to the manual instance evacuation process that you can perform at any time. For more information about instance evacuation, see Evacuating an instance.<br>
When the failed node restarts after the IPMI reset, the nova-compute process on that node also starts automatically. Because the node was previously fenced, it does not run any new instances until Pacemaker un-fences the node.<br>
When Pacemaker detects that the Compute node is online, it starts the compute-unfence-trigger resource agent on the node, which releases the node and so that it can run instances again.
Instance HA works with shared storage or local storage environments, which means that evacuated instances maintain the same network configuration, such as static IP and floating IP. The re-created instances also maintain the same characteristics inside the new Compue node.<br>



