### 服务器IP地址
|Hostname|IP Address|Gateway|NetMask|DNS|
|---|---|---|---|---|
|support|192.168.122.12|192.168.122.1|255.255.255.0|192.168.122.12|
|bootstrap|192.168.122.200|192.168.122.1|255.255.255.0|192.168.122.12|
|master-0|192.168.122.201|192.168.122.1|255.255.255.0|192.168.122.12|
|master-1|192.168.122.202|192.168.122.1|255.255.255.0|192.168.122.12|
|master-3|192.168.122.203|192.168.122.1|255.255.255.0|192.168.122.12|
|worker-0|192.168.122.210|192.168.122.1|255.255.255.0|192.168.122.12|
|worker-1|192.168.122.211|192.168.122.1|255.255.255.0|192.168.122.12|

### 1.7	DNS域名解析规划
|DNS Part|Value|
|---|---|
|Domain|example.com|
|OCP_CLUSTER_ID|ocp4-1|

|DNS Name|IP|
|---|---|
|support.example.com|192.168.122.12|
|dns.example.com|192.168.122.12|
|nfs.example.com|192.168.122.12|
|yum.example.com|192.168.122.12|
|registry.example.com|192.168.122.12|
|lb.ocp4-1.example.com|192.168.122.12|
|api.ocp4-1.example.com|192.168.122.12|
|api-int.ocp4-1.example.com|192.168.122.12|
|*.apps.ocp4-1.example.com|192.168.122.12|
|bootstrap.ocp4-1.example.com|192.168.122.200|
|master-0.ocp4-1.example.com|192.168.122.201|
|master-1.ocp4-1.example.com|192.168.122.202|
|master-2.ocp4-1.example.com|192.168.122.203|
|worker-0.ocp4-1.example.com|192.168.122.210|
|worker-1.ocp4-1.example.com|192.168.122.211|

### 安装 support 机器
```
最小化安装 support 机器

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 设置 selinux 为 Permissive
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
# 重启
reboot 

# 上传介质
mkdir -p /data

# 从 BASTION 节点上传介质
scp -r root@<BASTION-IP>:/data/OCP-4.6.52 192.168.122.12:/data

# 设置 OCP_CLUSTER_ID
export OCP_CLUSTER_ID="ocp4-1"

cat << EOF >> ~/.bashrc-${OCP_CLUSTER_ID}
#######################################
setVAR(){
  if [ \$# = 0 ]
  then
    echo "USAGE: "
    echo "   setVAR VAR_NAME VAR_VALUE    # Set VAR_NAME with VAR_VALUE"
    echo "   setVAR VAR_NAME              # Delete VAR_NAME"
  elif [ \$# = 1 ]
  then
    sed -i "/\${1}/d" ~/.bashrc-${OCP_CLUSTER_ID}
source ~/.bashrc-${OCP_CLUSTER_ID}
unset \${1}
    echo \${1} is empty
  else
    sed -i "/\${1}/d" ~/.bashrc-${OCP_CLUSTER_ID}
    echo export \${1}=\"\${2}\" >> ~/.bashrc-${OCP_CLUSTER_ID}
source ~/.bashrc-${OCP_CLUSTER_ID}
echo \${1}="\${2}"
  fi
  echo ${VAR_NAME}
}
#######################################
EOF

source ~/.bashrc-${OCP_CLUSTER_ID}

# 设置变量
setVAR OCP_MAJOR_VER 4.6
setVAR OCP_VER 4.6.52
setVAR RHCOS_VER 4.6.47
setVAR YUM_PATH /data/OCP-${OCP_VER}/yum
setVAR OCP_PATH /data/OCP-${OCP_VER}/ocp

# 安装 oc 客户端
tar -xzf ${OCP_PATH}/ocp-client/openshift-client-linux-${OCP_VER}.tar.gz -C /usr/local/sbin/
oc version

# 4.5	配置本地临时YUM源
# 4.5.1	准备YUM源所需的文件
# 先解压缩文件，然后删除压缩文件
for file in $(ls ${YUM_PATH}/*.tar.gz); do tar -zxvf ${file} -C ${YUM_PATH}/; done
rm -rf ${YUM_PATH}/*.tar.gz

# 4.5.2	配置本地临时YUM源
# 创建以下文件，配置本地临时YUM源
cat << EOF > /etc/yum.repos.d/base.repo
[rhel-7-server]
name=rhel-7-server
baseurl=file://${YUM_PATH}/rhel-7-server-rpms
enabled=1
gpgcheck=0
EOF

# 4.5.3	创建基于HTTP的YUM服务
# 安装Apache HTTP服务，并将http的端口修改为8080
yum -y install httpd
systemctl enable httpd --now
sed -i -e 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf
cat /etc/httpd/conf/httpd.conf |grep "Listen 8080"
# 注意：必须将yum目录所属首级目录/data以及所有子目录权限设为705，这样才能通过http访问
chmod -R 705 /data
# 创建指向yum目录的httpd配置文件。
cat << EOF > /etc/httpd/conf.d/yum.conf
Alias /repo "${YUM_PATH}"
<Directory "${YUM_PATH}">
  Options +Indexes +FollowSymLinks
  Require all granted
</Directory>
<Location /repo>
  SetHandler None
</Location>
EOF
# 重新启动 httpd 服务，然后验证可以访问到repo目录
systemctl restart httpd
curl http://localhost:8080/repo/

# 4.6	安装配置DNS服务
# OpenShift 4建议的域名组成为：集群名+根域名 $OCP_CLUSTER_ID.$DOMAIN
# 对于etcd，OCP要求由etcd-$INDEX格式组成。本例中由于etcd安装于master上，因此etcd的域名实际也是指向各master节点。此外，etcd还需要_etcd-server-ssl._tcp.$CLUSTERDOMMAIN的SRV记录，用于master寻找etcd节点，该域名指向etcd节点。
# 4.6.1	安装BIND服务
yum -y install bind bind-utils
systemctl enable named --now

# 4.6.2	设置BIND配置文件
# 先备份原始BIND配置文件，然后修改BIND配置，并重新加载配置
cp /etc/named.conf{,_bak}
sed -i -e "s/listen-on port.*/listen-on port 53 { any; };/" /etc/named.conf
sed -i -e "s/allow-query.*/allow-query { any; };/" /etc/named.conf
rndc reload
grep -E 'listen-on port|allow-query' /etc/named.conf 

# 如果有外部的解析需求，则请确保DNS服务器可以访问外网，并添加如下配置：
sed -i '/recursion yes;/a \
        forward first; \
        forwarders { 192.168.122.1; };' /etc/named.conf
sed -i -e "s/dnssec-enable.*/dnssec-enable no;/" /etc/named.conf
sed -i -e "s/dnssec-validation.*/dnssec-validation no;/" /etc/named.conf
rndc reload


# 4.6.3	配置Zone区域        
# 4.6.3.1	设置DNS环境变量
setVAR DOMAIN example.com
setVAR OCP_CLUSTER_ID ocp4-1
setVAR BASTION_IP 192.168.122.13
setVAR SUPPORT_IP 192.168.122.12
setVAR DNS_IP 192.168.122.12
setVAR NTP_IP 192.168.122.12
setVAR YUM_IP 192.168.122.12
setVAR REGISTRY_IP 192.168.122.12
setVAR USIP 192.168.122.12
setVAR LB_IP 192.168.122.12  
setVAR BOOTSTRAP_IP 192.168.122.200
setVAR MASTER0_IP 192.168.122.201
setVAR MASTER1_IP 192.168.122.202
setVAR MASTER2_IP 192.168.122.203
setVAR WORKER0_IP 192.168.122.210
setVAR WORKER1_IP 192.168.122.211

```