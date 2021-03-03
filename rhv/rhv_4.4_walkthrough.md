
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

备注：假设rhv repos内容已拷贝到/repo下，/repo下包含以下repo

```
cd /repo
tree -L 1 
.
|-- jb-eap-7.3-for-rhel-8-x86_64-rpms
|-- ansible-2.9-for-rhel-8-x86_64-rpms
|-- rhv-4.4-manager-for-rhel-8-x86_64-rpms
|-- rhel-8-for-x86_64-baseos-rpms
|-- rhel-8-for-x86_64-appstream-rpms
`-- fast-datapath-for-rhel-8-x86_64-rpms

6 directories, 0 files
```

配置yum本地源
```
cat > /etc/yum.repos.d/w.repo << 'EOF'
[rhel-8-for-x86_64-baseos-rpms]
name=rhel-8-for-x86_64-baseos-rpms
baseurl=file:///repo/rhel-8-for-x86_64-baseos-rpms/
enabled=1
gpgcheck=0

[rhel-8-for-x86_64-appstream-rpms]
name=rhel-8-for-x86_64-appstream-rpms
baseurl=file:///repo/rhel-8-for-x86_64-appstream-rpms/
enabled=1
gpgcheck=0

[fast-datapath-for-rhel-8-x86_64-rpms]
name=fast-datapath-for-rhel-8-x86_64-rpms
baseurl=file:///repo/fast-datapath-for-rhel-8-x86_64-rpms/
enabled=1
gpgcheck=0

[rhv-4.4-manager-for-rhel-8-x86_64-rpms]
name=rhv-4.4-manager-for-rhel-8-x86_64-rpms
baseurl=file:///repo/rhv-4.4-manager-for-rhel-8-x86_64-rpms/
enabled=1
gpgcheck=0

[ansible-2.9-for-rhel-8-x86_64-rpms]
name=ansible-2.9-for-rhel-8-x86_64-rpms
baseurl=file:///repo/ansible-2.9-for-rhel-8-x86_64-rpms/
enabled=1
gpgcheck=0

[jb-eap-7.3-for-rhel-8-x86_64-rpms]
name=jb-eap-7.3-for-rhel-8-x86_64-rpms
baseurl=file:///repo/jb-eap-7.3-for-rhel-8-x86_64-rpms/
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
2. 请根据实际情况将clock.corp.redhat.com替换成环境里可用的ntp时间服务器
```
yum install -y ntp

cat > /etc/ntp.conf << 'EOF'
driftfile /var/lib/ntp/drift
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1 
restrict ::1
server clock.corp.redhat.com iburst
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
EOF

systemctl enable ntpd && systemctl start ntpd
```

#### 1.3 更新系统并安装RHV软件
```
yum update -y
yum install rhvm
```

#### 1.4 执行rhv manager配置
```
engine-setup
```

在执行rhv manager配置时会回答一系列问题，其中在测试时需要更改的Application mode，请将这个值改为Virt，代表虚拟化场景。

|Question|Default|Answer|
|---|---|---|
|Set up Cinderlib integration|No|No|
|Configure Engine on this host|Yes|Yes|
|Configure ovirt-provider-ovn|Yes|Yes|
|Configure Image I/O Proxy on this host|Yes|Yes|
|Configure WebSocket Proxy on this host|Yes|Yes|
|Configure Data Warehouse on this host|Yes|Yes|
|Configure VM Console Proxy on this host|Yes|Yes|
|Host fully qualified DNS name of this server [rhvm1.rhcnsa.org]|rhvm1.rhcnsa.org|rhvm1.rhcnsa.org|
|Do you want Setup to configure the firewall|Yes|Yes|
|Where is the DWH database located? (Local, Remote) [Local]|Local|Local|
|Would you like Setup to automatically configure postgresql and create DWH database, or prefer to perform that manually? (Automatic, Manual) [Automatic]|Automatic|Automatic|
|Where is the Engine database located? (Local, Remote) [Local]|Local|Local|
|Would you like Setup to automatically configure postgresql and create Engine database, or prefer to perform that manually? (Automatic, Manual) [Automatic]|Automatic|Automatic|
|Application mode (Virt, Gluster, Both)|Both|**Virt**|
|Use default credentials (admin@internal) for ovirt-provider-ovn|Yes|Yes|
|Default SAN wipe after delete|No|No|
|Organization name for certificate [rhcnsa.org]|rhcnsa.org|rhcnsa.org|
|Do you wish to set the application as the default page of the web server|Yes|Yes|
|Do you wish Setup to configure that, or prefer to perform that manually? (Automatic, Manual)|Automatic|Automatic|
|Please choose Data Warehouse sampling scale:(1) Basic (2) Full (1, 2)[1]:|1|1|

### 2. 安装RHV Hypervisor
#### 2.1 安装RHV Hypervisor

请使用RHVH-4.3-20190806.1-RHVH-x86_64-dvd1.iso安装RHV Hypervisor

下载地址：
https://access.redhat.com/downloads/content/415/ver=4.4/rhel---8/4.4/x86_64/product-software

```
rhv4.3/
|-- isos
|   |-- RHVH-4.4-20210202.0-RHVH-x86_64-dvd1.iso
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
mkdir -p /data

cat > /etc/exports << EOF
/data    *(rw)
EOF
```

##### 3.1.3 创建用户及组并设置权限
```
groupadd kvm -g 36
useradd vdsm -u 36 -g 36
chown -R vdsm:kvm /data
chmod -R 0755 /data
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