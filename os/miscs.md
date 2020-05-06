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

