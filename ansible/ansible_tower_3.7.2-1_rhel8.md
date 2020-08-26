## rhel8
### 下载 ansible-tower-setup-bundle-3.7.2-1.tar.gz
https://releases.ansible.com/ansible-tower/setup-bundle/ansible-tower-setup-bundle-3.7.2-1.tar.gz
⚠️：在离线环境中，最好使用 bundle 安装包，因为此安装包包含离线安装所需的依赖内容

### 在 rhel8 上设置软件仓库
rhel8 上需要软件仓库 rhel-8-for-x86_64-baseos-rpms 和 rhel-8-for-x86_64-appstream-rpms
```
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
EOF
```

### 更新 rhel8
```
dnf update -y
```

### 确认版本已更新
```
cat /etc/redhat-release 
Red Hat Enterprise Linux release 8.2 (Ootpa)
```

### 从红帽官网下载 rsyslog 8.1911.0-6.el8
⚠️：在 rhel8 上 ansible tower 3.7.2-1 依赖 rsyslog 版本 8.1911 或更高版本，这个版本的 rsyslog 需要从红帽官网下载
https://access.redhat.com/downloads/content/rsyslog/8.1911.0-6.el8/x86_64/fd431d51/package<br>
上传并安装 
```
dnf localinstall -y ~/rsyslog-8.1911.0-6.el8.x86_64.rpm
...
Upgraded:
  rsyslog-8.1911.0-6.el8.x86_64                                                                                                          

Complete!
```

### 安装 单机版 ansible tower
```
tar zxvf ansible-tower-setup-bundle-3.7.2-1.tar.gz
cd ansible-tower-setup-bundle*

cat > inventory << 'EOF'
[tower]
localhost ansible_connection=local

[database]
localhost ansible_connection=local

[all:vars]
admin_password='redhat'

pg_host='localhost'
pg_port='5432'

pg_database='awx'
pg_username='awx'
pg_password='redhat'

nginx_http_port='80'
nginx_https_port='443'
EOF

./setup
```

### 多节点 ansible tower setup inventory
```
[tower]
jwang-tower-01.example.com

[database]
jwang-tower-db-01.example.com

[all:vars]
admin_password='redhat'

pg_host='jwang-tower-db-01.example.com'
pg_port='5432'

pg_database='awx'
pg_username='awx'
pg_password='redhat'

nginx_http_port='80'
nginx_https_port='443'
```

⚠️：在执行 tower setup 的节点上需手工安装 rsync 软件包
```
dnf install -y rsync
```