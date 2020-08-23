### 下载 ansible-tower-setup-bundle-3.7.2-1.tar.gz
https://releases.ansible.com/ansible-tower/setup-bundle/ansible-tower-setup-bundle-3.7.2-1.tar.gz

### 在 rhel7 上设置软件仓库
rhel7 上需要软件仓库 rhel-7-server-rpms 和 rhel-server-rhscl-7-rpms
```
cat > /etc/yum.repos.d/public.repo << 'EOF'
[rhel-7-server-rpms]
name=rhel-7-server-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-rpms/
gpgcheck=0
enabled=1

[rhel-server-rhscl-7-rpms]
name=rhel-server-rhscl-7-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-server-rhscl-7-rpms/
gpgcheck=0
enabled=1
EOF
```

### 更新 rhel7
```
yum update -y
```

### 确认版本已更新
```
cat /etc/redhat-release 
Red Hat Enterprise Linux Server release 7.8 (Maipo)
```
### 安装 ansible tower
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
EOF

./setup
...
PLAY [Install Tower isolated node(s)] ***************************************************************************************************
skipping: no hosts matched

PLAY RECAP ******************************************************************************************************************************
localhost                  : ok=172  changed=88   unreachable=0    failed=0    skipped=85   rescued=0    ignored=2   
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
```

⚠️：在执行 tower setup 的节点上需手工安装 rsync 软件包
```
yum install -y rsync
```
