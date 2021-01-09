### 软件准备

需要准备的操作系统镜像
RHEL-8.2

需要准备的软件频道参见：
https://access.redhat.com/documentation/zh-cn/red_hat_openstack_platform/16.1/html/director_installation_and_usage/undercloud-repositories

安装虚拟机
```
# kickstart 文件参考 https://github.com/wangjun1974/tips/blob/master/os/miscs.md#rhel8-minimal-kickstart-file
virt-install --name=jwang-rhel82-undercloud --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-rhel82-undercloud.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --location /root/jwang/isos/rhel-8.2-x86_64-dvd.iso \
--console pty,target_type=serial \
--initrd-inject /tmp/ks.cfg \
--extra-args='ks=file:/ks.cfg console=ttyS0'
```

在下载服务器上执行，订阅所需软件频道
```
subscription-manager repos --disable=*
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-eus-rpms --enable=rhel-8-for-x86_64-appstream-eus-rpms --enable=rhel-8-for-x86_64-highavailability-eus-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms --enable=openstack-16.1-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms --enable=advanced-virt-for-rhel-8-x86_64-rpms --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms
```

在下载服务器上，生成同步软件频道的脚本
```
mkdir -p /repos/rhel8osp
pushd /repos/rhel8osp

# 安装 createrepo
yum install -y createrepo

cat > ./OSP16_1_repo_sync_up.sh <<'EOF'
#!/bin/bash

localPath="/repos/rhel8osp/"
fileConn="/getPackage/"

## sync following yum repos 
# rhel-8-for-x86_64-baseos-eus-rpms
# rhel-8-for-x86_64-appstream-eus-rpms
# rhel-8-for-x86_64-highavailability-eus-rpms
# ansible-2.9-for-rhel-8-x86_64-rpms
# openstack-16.1-for-rhel-8-x86_64-rpms
# fast-datapath-for-rhel-8-x86_64-rpms
# rhceph-4-tools-for-rhel-8-x86_64-rpms
# advanced-virt-for-rhel-8-x86_64-rpms

for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --downloadcomps --download-metadata

  echo "create repo $i..."
  time createrepo -g $(ls "$localPath"$i/repodata/*comps.xml) --update --skip-stat --cachedir /tmp/empty-cache-dir "$localPath"$i

done

exit 0
EOF

# 同步软件仓库
/usr/bin/nohup /bin/bash OSP16_1_repo_sync_up.sh &

# 同步完之后把 /repos/rhel8osp 目录打包，下载作为离线时使用的软件仓库

```

### Yum 仓库和镜像仓库准备

OSP 在部署时需要访问镜像仓库，在一般的部署下，这个镜像仓库会部署在 undercloud 上

```
# 1. 安装时需使用 rhel-8.2-x86_64-dvd.iso 作为操作系统的安装介质
# 这个 ISO 可在红帽官网下载
# https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.2/x86_64/product-software

# 2. 安装操作系统 

# 3. 安装完操作系统之后，执行以下配置
# 3.1 以 root 用户登录系统
# 3.2 创建 stack 用户
[root@director ~]# useradd stack

# 3.3 为 stack 用户设置口令
[root@director ~]# passwd stack

# 3.4 为 Stack 用户设置 sudo 
[root@director ~]# echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
[root@director ~]# chmod 0440 /etc/sudoers.d/stack

# 3.5 切换为 stack 用户
[root@director ~]# su - stack
[stack@director ~]$

# 3.6 创建 images 和 templates 目录
[stack@director ~]$ mkdir ~/images
[stack@director ~]$ mkdir ~/templates

# 3.7 设置主机名并检查主机名
[stack@director ~]$ sudo hostnamectl set-hostname undercloud.example.com
[stack@director ~]$ sudo hostnamectl set-hostname --transient undercloud.example.com

# 3.8 编辑 /etc/hosts 文件，添加 undercloud.example.com 对应的记录
[stack@undercloud ~]$ sudo -i
[root@undercloud ~]# cat >> /etc/hosts << 'EOF'
10.0.11.27 undercloud.example.com undercloud
EOF
[root@undercloud ~]# exit
[stack@undercloud ~]$

# 4.1 注册系统
[stack@undercloud ~]$ sudo subscription-manager register

# 4.2 列出包含 Red Hat OpenStack 的订阅，记录下订阅的 Pool ID
[stack@undercloud ~]$ sudo subscription-manager list --available --all --matches="Red Hat OpenStack"

# 4.3 为系统附加 Pool
[stack@undercloud ~]$ sudo subscription-manager attach --pool=8a85f99c727637ad0172c517131a1e6d

# 4.4 设置系统 release 为 8.2
[stack@undercloud ~]$ sudo subscription-manager release --set=8.2

# 5.1 禁用所有软件频道
[stack@undercloud ~]$ sudo subscription-manager repos --disable=*

# 5.2 启用对应软件频道
[stack@undercloud ~]$ sudo subscription-manager repos --enable=rhel-8-for-x86_64-baseos-eus-rpms --enable=rhel-8-for-x86_64-appstream-eus-rpms --enable=rhel-8-for-x86_64-highavailability-eus-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms --enable=openstack-16.1-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms --enable=advanced-virt-for-rhel-8-x86_64-rpms --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms

# 5.3 安装 httpd
[stack@undercloud ~]$ sudo yum install -y httpd

# 5.4 创建本地 repos 目录
[stack@undercloud ~]$ sudo mkdir -p /var/www/html/repos/osp16.1
[stack@undercloud ~]$ sudo -i
[root@undercloud ~]# pushd /var/www/html/repos

# 5.5 安装 createrepo，生成 repos 同步脚本
[root@undercloud repos]# yum install -y createrepo yum-utils
[root@undercloud repos]# cat > ./OSP16_1_repo_sync_up.sh <<'EOF'
#!/bin/bash

localPath="/var/www/html/repos/osp16.1/"
fileConn="/getPackage/"

## sync following yum repos 
# rhel-8-for-x86_64-baseos-eus-rpms
# rhel-8-for-x86_64-appstream-eus-rpms
# rhel-8-for-x86_64-highavailability-eus-rpms
# ansible-2.9-for-rhel-8-x86_64-rpms
# openstack-16.1-for-rhel-8-x86_64-rpms
# fast-datapath-for-rhel-8-x86_64-rpms
# rhceph-4-tools-for-rhel-8-x86_64-rpms
# advanced-virt-for-rhel-8-x86_64-rpms

for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --downloadcomps --download-metadata

  echo "create repo $i..."
  time createrepo -g $(ls "$localPath"$i/repodata/*comps.xml) --update --skip-stat --cachedir /tmp/empty-cache-dir "$localPath"$i

done

exit 0
EOF

# 5.6 同步 repos
[root@undercloud repos]# /usr/bin/nohup /bin/bash ./OSP16_1_repo_sync_up.sh &

# 5.7 重设 selinux context
[root@undercloud repos]# chcon --recursive --reference=/var/www/html /var/www/html/repos

# 5.8 开启防火墙 http 端口，启动 httpd 服务器
[root@undercloud repos]# firewall-cmd --add-service=http
[root@undercloud repos]# firewall-cmd --add-service=http --permanent
[root@undercloud repos]# firewall-cmd --reload

# 5.9 启动 httpd 服务
[root@undercloud repos]# systemctl enable httpd && systemctl start httpd

# 5.10 禁用远程 yum 源，设置本地 http yum 源
# baseurl 的 UNDERCLOUD_IP 地址
# 用本地接口名称替换 ens3
[root@undercloud repos]# subscription-manager repos --disable=*
[root@undercloud repos]# echo y | mv /etc/yum.repos.d/redhat.repo /etc/yum.repos.d/backup
[root@undercloud repos]# sed -ie 's|enabled=1|enabled=0|' /etc/yum/pluginconf.d/subscription-manager.conf

[root@undercloud repos]# UNDERCLOUD_IP=$( ip a s dev ens3 | grep -E "inet " | awk '{print $2}' | awk -F'/' '{print $1}' )
[root@undercloud repos]# > /etc/yum.repos.d/osp.repo 
[root@undercloud repos]# for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms
do
cat >> /etc/yum.repos.d/osp.repo << EOF
[$i]
name=$i
baseurl=http://${UNDERCLOUD_IP}/repos/osp16.1/$i/
enabled=1
gpgcheck=0

EOF
done

[root@undercloud repos]# exit

# 5.11 设置 container-tools 模块为版本 2.0
[stack@undercloud ~]$ sudo dnf module disable -y container-tools:rhel8
[stack@undercloud ~]$ sudo dnf module enable -y container-tools:2.0

# 5.12 设置 virt 模块版本为 8.2
[stack@undercloud ~]$ sudo dnf module disable -y virt:rhel
[stack@undercloud ~]$ sudo dnf module enable -y virt:8.2

# 5.13 更新并且重启
[stack@undercloud ~]$ sudo dnf update -y
[stack@undercloud ~]$ sudo reboot

# 6 安装 director
[stack@undercloud ~]$ sudo dnf install -y python3-tripleoclient

# 7 安装 ceph-ansible

# 8 创建 undercloud.conf 文件
cat > undercloud.conf << EOF
[DEFAULT]
undercloud_hostname = undercloud.example.com
container_images_file = containers-prepare-parameter.yaml
local_ip = 192.0.2.1/24
undercloud_public_host = 192.0.2.2
undercloud_admin_host = 192.0.2.3
undercloud_nameservers = 192.0.2.254
subnets = ctlplane-subnet
local_subnet = ctlplane-subnet
#undercloud_service_certificate =
generate_service_certificate = true
certificate_generation_ca = local
local_interface = eth0
inspection_extras = false
undercloud_debug = false
enable_tempest = false
enable_ui = false

[auth]

[ctlplane-subnet]
cidr = 192.0.2.0/24
dhcp_start = 192.0.2.5
dhcp_end = 192.0.2.24
inspection_iprange = 192.0.2.100,192.0.2.120
gateway = 192.0.2.254
EOF


```
