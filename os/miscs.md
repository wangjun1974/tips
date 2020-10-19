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
https://redhatnordicssa.github.io/rhel8-really-fast
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

  echo "create repo $i..."
  #createrepo "$localPath"$i
  time createrepo -g $(ls "$localPath"$i/repodata/*comps.xml) --update --skip-stat --cachedir /tmp/empty-cache-dir "$localPath"$i

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
add disk --parent-vm-name jwang-$i --provisioned_size 85899345920 --interface virtio_scsi --format cow --storage_domains-storage_domain storage_domain.name=DS11 --bootable true --wipe_after_delete true
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