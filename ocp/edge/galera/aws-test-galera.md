

参考文档: https://benjr.tw/102385


```
### 所有节点安装软件
$ yum install -y mariadb-server-galera 

### 所有节点设置防火墙
# Galera 防火墙端口
$ sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
$ sudo firewall-cmd --permanent --zone=public --add-port=4567/tcp
$ sudo firewall-cmd --permanent --zone=public --add-port=4568/tcp
$ sudo firewall-cmd --permanent --zone=public --add-port=4444/tcp
$ sudo firewall-cmd --permanent --zone=public --add-port=4567/udp
$ sudo firewall-cmd --reload

### 所有节点设置 selinux
### 不确定是否一定要执行
$ setenforce 0

### 在首节点设置  
### Bootstrap Galera
$ systemctl start mariadb
$ systemctl enable mariadb

### 设置 mysql root 口令
$ mysql_secure_installation
Set root password? [Y/n] Y
Remove anonymous users? [Y/n] Y
Disallow root login remotely? [Y/n] N
Remove test database and access to it? [Y/n] Y
Reload privilege tables now? [Y/n] Y

### 设置 root 远程权限
$ mysql -u root -p
MariaDB [(none)]> GRANT ALL PRIVILEGES ON *.* to root@'%' IDENTIFIED BY 'redhat' WITH GRANT OPTION;
MariaDB [(none)]> FLUSH PRIVILEGES;
MariaDB [(none)]> EXIT;

### 验证 mysql 可远程访问
$ mysql -u root -p -h 10.66.208.165

### 停止 mariadb 服务
$ systemctl stop mariadb

### 编辑首节点 /etc/my.cnf.d/galera.cnf 
# wsrep_cluster_address=gcomm://
# wsrep_cluster_name=galera
# wsrep_node_address=<LOCAL_IP>
# wsrep_sst_auth="root:redhat"

cat > /etc/my.cnf.d/galera <<EOF
[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
default_storage_engine = innodb
binlog_format = row
innodb_autoinc_lock_mode = 2
innodb_flush_log_at_trx_commit = 0
query_cache_size = 0
query_cache_type = 0

wsrep_sst_method=mariabackup
wsrep_slave_threads=4
wsrep_cluster_address=gcomm://
wsrep_cluster_name=galera
wsrep_node_address=10.66.208.165
wsrep_sst_auth="root:redhat"
innodb_flush_log_at_trx_commit=2
# MYISAM REPLICATION SUPPORT #
wsrep_replicate_myisam=ON
EOF

### bootstrap
# 所有节点都关机后，也是在第一个节点执行
$ galera_new_cluster
# 启动 mariadb 服务
$ systemctl start mariadb 

### 在第一个节点监控状态
$ mysql -u root -p -e "show status like 'wsrep_cluster%'"
$ mysql -u root -p -e "show status like 'wsrep_con%'"

### 查看端口
$ ss -anlp | grep -e 4567 -e 3306 -e 4568 -e 4444

### 第二个节点加入
# 编辑 /etc/my.cnf.d/galera.cnf 
# wsrep_cluster_address=gcomm://<第一个节点IP>
# wsrep_cluster_name=galera
# wsrep_node_address=<LOCAL_IP>
# wsrep_sst_auth="root:redhat"

$ cat > /etc/my.cnf.d/galera <<EOF
[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
default_storage_engine = innodb
binlog_format = row
innodb_autoinc_lock_mode = 2
innodb_flush_log_at_trx_commit = 0
query_cache_size = 0
query_cache_type = 0

wsrep_sst_method=mariabackup
wsrep_slave_threads=4
wsrep_cluster_address=gcomm://10.66.208.165
wsrep_cluster_name=galera
wsrep_node_address=10.66.208.164
wsrep_sst_auth="root:redhat"
innodb_flush_log_at_trx_commit=2
# MYISAM REPLICATION SUPPORT #
wsrep_replicate_myisam=ON
EOF

### 启动 mariadb
$ systemctl start mariadb

# 在第一个节点监控状态
$ mysql -u root -p -e "show status like 'wsrep_cluster%'"
$ mysql -u root -p -e "show status like 'wsrep_con%'"

### 第三个节点加入
# 编辑 /etc/my.cnf.d/galera.cnf 
# wsrep_cluster_address=gcomm://<第一个节点IP>
# wsrep_cluster_name=galera
# wsrep_node_address=<LOCAL_IP>
# wsrep_sst_auth="root:redhat"

$ cat > /etc/my.cnf.d/galera <<EOF
[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
default_storage_engine = innodb
binlog_format = row
innodb_autoinc_lock_mode = 2
innodb_flush_log_at_trx_commit = 0
query_cache_size = 0
query_cache_type = 0

wsrep_sst_method=mariabackup
wsrep_slave_threads=4
wsrep_cluster_address=gcomm://10.66.208.165
wsrep_cluster_name=galera
wsrep_node_address=10.66.208.163
wsrep_sst_auth="root:redhat"
innodb_flush_log_at_trx_commit=2
# MYISAM REPLICATION SUPPORT #
wsrep_replicate_myisam=ON
EOF

# 启动 mariadb
$ systemctl start mariadb

# 在第一个节点监控状态
$ mysql -u root -p -e "show status like 'wsrep_cluster%'"
$ mysql -u root -p -e "show status like 'wsrep_con%'"

# 不知道是否需要设置这个 SELinux
# setsebool -P daemons_enable_cluster_mode=on
```

### 实验环境清理节点
```
### 实验环境清理
$ systemctl stop mariadb
$ rm -rf /var/lib/mysql/*
$ rm -rf /var/lib/mysql/.sst
$ ls -al /var/lib/mysql
```
