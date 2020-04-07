## Ansible Tower 安装流程

### 设置网络
|主机名|IP|DNS|Gateway|NTP|
|tower01.rhsacn.org|10.66.208.130/24|10.72.17.5|10.66.208.254|clock.corp.redhat.com|

### 设置环境变量
```
cat > ~/env.sh << 'EOF'
export TOWER_HOSTNAME='tower01.rhsacn.org'
export TOWER_IPADDR='10.66.208.130'
export TOWER_PREFIX='24'
export TOWER_DNS_SERVER='10.72.17.5'
export TOWER_GATEWAY='10.66.208.254'
export TOWER_NTP_SERVER='clock.corp.redhat.com'
export TOWER_HTTP_REPO_SERVER='10.66.208.115'
EOF

source ~/env.sh
```

### 设置网络
假设网络接口名为eth0
```
nmcli con mod 'eth0' ipv4.method 'manual' ipv4.address ${TOWER_IPADDR}/${TOWER_PREFIX} ipv4.gateway ${TOWER_GATEWAY} ipv4.dns ${TOWER_DNS_SERVER}
nmcli con down eth0 && nmcli con up eth0
```

### 设置主机名
```
hostnamectl set-hostname ${TOWER_HOSTNAME}

cat >> /etc/hosts << EOF
${TOWER_IPADDR}  ${TOWER_HOSTNAME}
EOF
```

### 设置软件源
```
mkdir -p /etc/yum.repos.d/backup
yes | mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup

cat > /etc/yum.repos.d/w.repo << EOF
[rhel-7-server-rpms]
name=rhel-7-server-rpms
baseurl=http://${TOWER_HTTP_REPO_SERVER}/rhel7osp/rhel-7-server-rpms/
enabled=1
gpgcheck=0

[rhel-7-server-extras-rpms]
name=rhel-7-server-extras-rpms
baseurl=http://${TOWER_HTTP_REPO_SERVER}/rhel7osp/rhel-7-server-extras-rpms/
enabled=1
gpgcheck=0

EOF
```

### 配置时间服务器
```
yum install -y chrony

cat > /etc/chrony.conf << EOF
server ${TOWER_NTP_SERVER} iburst
stratumweight 0
driftfile /var/lib/chrony/drift
rtcsync
makestep 10 3
bindcmdaddress 127.0.0.1
bindcmdaddress ::1
keyfile /etc/chrony.keys
commandkey 1
generatecommandkey
noclientlog
logchange 0.5
logdir /var/log/chrony
EOF

systemctl enable chronyd
systemctl start chronyd

systemctl status chronyd
chronyc -n sources
chronyc -n tracking
```

### 下载软件
```
curl -O https://releases.ansible.com/ansible-tower/setup-bundle/ansible-tower-setup-bundle-latest.el7.tar.gz
```

### 解压缩
```
tar zxvf ansible-tower-setup*.tar.gz
cd ansible-tower-setup*
```

### 程程inventory
```
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

rabbitmq_username=tower
rabbitmq_password='redhat'
rabbitmq_cookie=cookiemonster
EOF
```

### 安装Ansible Tower
```
./setup.sh
```

