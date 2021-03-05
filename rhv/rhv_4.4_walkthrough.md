
## 环境准备
在环境中包含两类节点，第一类是rhv manager，提供虚拟化管理功能；第二类是rhv hypervisor，用于运行虚拟机；因此在安装前需事先规划好节点的IP地址和主机名

|hostname|ip|role|
|---|---|---|
|rhvm1.rhcnsa.org|192.168.122.152/24|rhv manager|
|node1.rhcnsa.org|192.168.122.153/24|rhv hypervisor|

根据最佳实践，环境中建议提供dns和time server
|dns|gateway|ntp timeserver|
|---|---|---|
|10.64.63.6|192.168.122.1|clock.corp.redhat.com|

## 安装
### 0. 安装前准备好DNS服务器和NTP时间同步服务器（可选）
DNS为服务器提供名称解析，NTP为服务器提供时间同步服务，推荐在安装RHV前在环境里准备好DNS服务和NTP服务。

### 1. 安装RHV Manager
#### 1.1 安装RHEL7操作系统
请使用rhel-server-8.3-x86_64-dvd.iso安装RHV Manager操作系统

```
rhv4.4
|-- isos
|   `-- rhel-server-8.3-x86_64-dvd.iso
```
可选择最小化安装，安装过程设置IP地址，子网掩码，网关。同时dns服务器（可选）

#### 1.2 配置yum软件仓库

备注：假设rhv repos内容已拷贝到/repos/rhv44下，/repos/rhv44下包含以下repo

```
cd /repos/rhv44
tree -L 1 
.
/repos/rhv44/
|-- ansible-2.9-for-rhel-8-x86_64-rpms
|-- fast-datapath-for-rhel-8-x86_64-rpms
|-- jb-eap-7.3-for-rhel-8-x86_64-rpms
|-- rhel-8-for-x86_64-appstream-rpms
|-- rhel-8-for-x86_64-baseos-rpms
`-- rhv-4.4-manager-for-rhel-8-x86_64-rpms

6 directories, 0 files
```

# 备注
# 同步脚本内容
```
# 订阅软件仓库
subscription-manager repos --disable=*
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhv-4.4-manager-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms --enable=jb-eap-7.3-for-rhel-8-x86_64-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms

# 同步软件仓库
mkdir -p /repos/rhv44
cd /repos/rhv44
cat > RHV4_4_repo_sync_up.sh << 'EOF'
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

for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-appstream-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --download-metadata

done

# theses repos download old and new contents to fulfill requires
for i in rhv-4.4-manager-for-rhel-8-x86_64-rpms ansible-2.9-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms jb-eap-7.3-for-rhel-8-x86_64-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync --download-path="$localPath" --repoid $i --download-metadata

done

exit 0 
EOF

```

配置yum本地源
```
cat > /etc/yum.repos.d/w.repo << 'EOF'
[rhel-8-for-x86_64-baseos-rpms]
name=rhel-8-for-x86_64-baseos-rpms
baseurl=file:///repos/rhv44/rhel-8-for-x86_64-baseos-rpms/
enabled=1
gpgcheck=0

[rhel-8-for-x86_64-appstream-rpms]
name=rhel-8-for-x86_64-appstream-rpms
baseurl=file:///repos/rhv44/rhel-8-for-x86_64-appstream-rpms/
enabled=1
gpgcheck=0

[fast-datapath-for-rhel-8-x86_64-rpms]
name=fast-datapath-for-rhel-8-x86_64-rpms
baseurl=file:///repos/rhv44/fast-datapath-for-rhel-8-x86_64-rpms/
enabled=1
gpgcheck=0

[rhv-4.4-manager-for-rhel-8-x86_64-rpms]
name=rhv-4.4-manager-for-rhel-8-x86_64-rpms
baseurl=file:///repos/rhv44/rhv-4.4-manager-for-rhel-8-x86_64-rpms/
enabled=1
gpgcheck=0

[ansible-2.9-for-rhel-8-x86_64-rpms]
name=ansible-2.9-for-rhel-8-x86_64-rpms
baseurl=file:///repos/rhv44/ansible-2.9-for-rhel-8-x86_64-rpms/
enabled=1
gpgcheck=0

[jb-eap-7.3-for-rhel-8-x86_64-rpms]
name=jb-eap-7.3-for-rhel-8-x86_64-rpms
baseurl=file:///repos/rhv44/jb-eap-7.3-for-rhel-8-x86_64-rpms/
enabled=1
gpgcheck=0
EOF
```

#### 1.3 设置主机名
```
hostnamectl set-hostname rhvm1.rhcnsa.org

cat >> /etc/hosts << 'EOF'
10.66.208.152 rhvm1.rhcnsa.org
EOF
```

#### 1.4 设置时间服务器(可选)

注意：
1. 如果安装操作系统时已设置时间服务器，此步骤可以忽略
2. 将本机设置为时间服务器
```
yum install -y chrony

# 生成以本地时间为时间源的时间服务器配置
cat > /etc/chrony.conf << EOF
server 10.66.208.152 iburst
bindaddress 10.66.208.152
allow all
local stratum 4
EOF

# 在 firewallD 规则里开放 ntp 服务
sudo firewall-cmd --add-service=ntp
sudo firewall-cmd --add-service=ntp --permanent
sudo firewall-cmd --reload
sudo systemctl enable chronyd && sudo systemctl restart chronyd

# 查看时间源
chronyc -n sources
chronyc -n tracking
```

#### 1.3 更新系统并安装RHV软件
```
# 启用 pki-deps 模块 和 postgresql:12 
dnf module -y enable pki-deps
dnf module -y enable postgresql:12

# 删除产生冲突的软件包
yum remove crypto-policies-scripts

# 更新已安装软件到最新
dnf distro-sync --nobest -y
dnf upgrade --nobest

# 以下步骤应该不用执行，依赖关系解决通过压缩包 rhv-4.4-repos-addons-2021-03-05.tar.gz 解决
cd /repos/rhv44
dnf install -y createrepo

pushd ansible-2.9-for-rhel-8-x86_64-rpms
createrepo .
popd
pushd rhv-4.4-manager-for-rhel-8-x86_64-rpms
createrepo .
popd

# ovirt-engine 软件包在 requires 里描述了具体的 ansible 版本，因此不能只下载最新的版本
tar zxvf rhv-4.4-repos-addons-2021-03-05.tar.gz -C /

dnf clean all
dnf install rhvm -y
```

```
安装过程中的报错信息
(Fri Mar  5 13:23:50:205404 2021) [sss_cache] [sysdb_domain_cache_connect] (0x0010): DB version too new [0.22], expected [0.21] for domain implicit_files!
Lower version of database is expected!
Removing cache files in /var/lib/sss/db should fix the issue, but note that removing cache files will also remove all of your cached credentials.
Could not open available domains
useradd: sss_cache exited with status 71
useradd: Failed to flush the sssd cache.

# 解决方案
systemctl stop sssd
rm -rf /var/lib/sss/db/*
systemctl start sssd


```

#### 1.4 执行rhv manager配置
```
engine-setup
```

在执行rhv manager配置时会回答一系列问题，其中在测试时需要更改的Application mode，请将这个值改为Virt，代表虚拟化场景。

|Question|Default|Answer|
|---|---|---|
|Configure Cinderlib integration|No|No|
|Configure Engine on this host|Yes|Yes|
|Configure ovirt-provider-ovn|Yes|No|
|Configure WebSocket Proxy on this host|Yes|Yes|
|Configure Data Warehouse on this host|Yes|Yes|
|Configure Grafana on this host|Yes|Yes|
|Configure VM Console Proxy on this host|Yes|Yes|
|Host fully qualified DNS name of this server [rhvm1.rhcnsa.org]|rhvm1.rhcnsa.org|rhvm1.rhcnsa.org|
|Do you want Setup to configure the firewall|Yes|Yes|
|Where is the DWH database located? (Local, Remote) [Local]|Local|Local|
|Would you like Setup to automatically configure postgresql and create DWH database, or prefer to perform that manually? (Automatic, Manual) [Automatic]|Automatic|Automatic|
|Where is the Engine database located? (Local, Remote) [Local]|Local|Local|
|Would you like Setup to automatically configure postgresql and create Engine database, or prefer to perform that manually? (Automatic, Manual) [Automatic]|Automatic|Automatic|
|Application mode (Virt, Gluster, Both)|Both|**Virt**|
|Default SAN wipe after delete|No|No|
|Organization name for certificate [rhcnsa.org]|rhcnsa.org|rhcnsa.org|
|Do you wish to set the application as the default page of the web server|Yes|Yes|
|Do you wish Setup to configure that, or prefer to perform that manually? (Automatic, Manual)|Automatic|Automatic|
|Please choose Data Warehouse sampling scale:(1) Basic (2) Full (1, 2)[1]:|1|1|
|Use Engine admin password as initial Grafana admin password|Yes|Yes|
|Do you want Setup to continue, with amount of memory less than recommended?|No|Yes|

### 2. 安装RHV Hypervisor
#### 2.1 安装RHV Hypervisor

请使用RHVH-4.4-20210202.0-RHVH-x86_64-dvd1.iso安装RHV Hypervisor

下载地址：
https://access.redhat.com/downloads/content/415/ver=4.4/rhel---8/4.4/x86_64/product-software

```
rhv44/
|-- RHVH-4.4-20210202.0-RHVH-x86_64-dvd1.iso
```

安装步骤参考《INSTALLING RED HAT VIRTUALIZATION AS A STANDALONE MANAGER WITH LOCAL DATABASES》4.1.1 Installing Red Hat Virtualization Hosts

### 3. 准备存储和添加存储

#### 3.1 准备存储
准备存储请根据实际存储类型来决定如何准备。

准备存储步骤参考《INSTALLING RED HAT VIRTUALIZATION AS A STANDALONE MANAGER WITH LOCAL DATABASES》CHAPTER 5. PREPARING STORAGE FOR RED HAT VIRTUALIZATION

以NFS存储为例，在NFS服务器上执行

##### 3.1.1 安装所需软件
```
yum install -y nfs-utils
```

##### 3.1.2 创建输出的目录
```
mkdir -p /ds11

cat > /etc/exports << EOF
/ds11    *(rw)
EOF
```

##### 3.1.3 创建用户及组并设置权限
```
groupadd kvm -g 36
useradd vdsm -u 36 -g 36
chown -R vdsm:kvm /ds11
chmod -R 0755 /ds11
```

##### 3.1.4 启动服务
```
systemctl enable nfs-server && systemctl start nfs-server
systemctl enable rpcbind && systemctl start rpcbind
```

##### 3.1.5 设置防火墙
```
firewall-cmd --permanent --add-service mountd
firewall-cmd --permanent --add-service rpc-bind
firewall-cmd --permanent --add-service nfs
firewall-cmd --reload
```

#### 3.2 添加节点
参考《RHV4.3常用操作简易说明》中添加节点步骤

#### 3.3 添加存储
参考《RHV4.3常用操作简易说明》中添加存储步骤

#### 3.4 上传ISO
参考《RHV4.3常用操作简易说明》中上传ISO步骤