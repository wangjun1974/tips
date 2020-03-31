## osp16 lab 手册

参考： https://mojo.redhat.com/docs/DOC-1216651-manual-how-to-install-rhosp16-on-rhel8-in-english

### 网络拓扑
![](pics/osp16_lab_envirorment.png)

### 设置undercloud

#### 配置网络
```

```

#### 设置NTP
```
yum install -y chronyd

cat > /etc/chrony.conf << 'EOF'
pool 192.168.10.1
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 192.168.0.0/16
local stratum 10
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF


```


### 准备repo

首先注册系统，启用软件频道
```
subscription-manager register

POOLID=$(subscription-manager list --available --all --matches="Red Hat OpenStack" | grep "^Pool ID: " | awk -F': ' '{print $2}' | sed -ie 's| *||g' )

subscription-manager attach ​--pool=${POOLID}

​subscription-manager repos --disable=*

​subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhel-8-for-x86_64-highavailability-rpms --enable=ansible-2.8-for-rhel-8-x86_64-rpms --enable=openstack-16-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms
```

同步软件频道内容到本地
```
yum install -y httpd createrepo yum-utils

mkdir /var/www/html/repo 

reposync --download-metadata​ \
 --repo=​rhel-8-for-x86_64-baseos-rpms​ ​-p /var/www/html/repo

​reposync --download-metadata​ \
 --repo=​rhel-8-for-x86_64-appstream-rpms​ ​-p /var/www/html/repo

reposync --download-metadata \
 --repo=​rhel-8-for-x86_64-highavailability-rpms​ ​-p /var/www/html/repo

​reposync --download-metadata \
 --repo=​ansible-2.8-for-rhel-8-x86_64-rpms​ ​-p /var/www/html/repo

reposync --download-metadata \
 --repo=​satellite-tools-6.5-for-rhel-8-x86_64-rpms ​-p /var/www/html/repo

reposync --download-metadata \
 --repo=​openstack-16-for-rhel-8-x86_64-rpms​ ​-p /var/www/html/repo 

reposync --download-metadata \
 --repo=​fast-datapath-for-rhel-8-x86_64-rpms​ ​-p /var/www/html/repo 
```

设置registry

安装undercloud


