### 内容引用
内容原创作者：林文炜，刘晓宇

### 说明
1.	本文内容只适用于安装运行OpenShift 4.8的试用环境，而不适用于生产环境。
2.	本文中的操作只适用于和本文相同的OpenShift安装方式和部署架构，其它安装方式和部署架构请参考Red Hat官方文档。
3.	本文中的配置说明了如何部署3 master的OpenShift集群。
4.	本文操作默认是在support节点上完成，如有例外，请参见每章节说明。

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
setVAR NFS_IP 192.168.122.12
setVAR REGISTRY_IP 192.168.122.12
setVAR USIP 192.168.122.12
setVAR LB_IP 192.168.122.12  
setVAR BOOTSTRAP_IP 192.168.122.200
setVAR MASTER0_IP 192.168.122.201
setVAR MASTER1_IP 192.168.122.202
setVAR MASTER2_IP 192.168.122.203
setVAR WORKER0_IP 192.168.122.210
setVAR WORKER1_IP 192.168.122.211

# 4.6.3.2	添加解析Zone区域
# 执行以下命令添加3个解析ZONE（如果要执行多次，需要手动删除以前增加的内容），它们分别为：
# 域名后缀              解释
# example.com          集群内部域名后缀：集群内部所有节点的主机名均采用该域名后缀
# ocp4-1.example.com   OCP集群的域名，如本例中的集群名为ocp4-1，则域名为ocp4-1.example.com
# 168.192.in-addr.arpa 用于集群内所有节点的反向解析
cat >> /etc/named.rfc1912.zones << EOF

zone "${DOMAIN}" IN {
        type master;
        file "${DOMAIN}.zone";
        allow-transfer { any; };
};

zone "${OCP_CLUSTER_ID}.${DOMAIN}" IN {
        type master;
        file "${OCP_CLUSTER_ID}.${DOMAIN}.zone";
        allow-transfer { any; };
};

zone "168.192.in-addr.arpa" IN {
        type master;
        file "168.192.in-addr.arpa.zone";
        allow-transfer { any; };
};

EOF

# 4.6.3.3	创建example.com.zone区域配置文件
cat > /var/named/${DOMAIN}.zone << EOF
\$ORIGIN ${DOMAIN}.
\$TTL 1D
@           IN SOA  ${DOMAIN}. admin.${DOMAIN}. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum

@             IN NS                         dns.${DOMAIN}.

bastion       IN A                          ${BASTION_IP}
support       IN A                          ${SUPPORT_IP}
dns           IN A                          ${DNS_IP}
ntp           IN A                          ${NTP_IP}
yum           IN A                          ${YUM_IP}
registry      IN A                          ${REGISTRY_IP}
nfs           IN A                          ${NFS_IP}

EOF

# 4.6.3.4	创建ocp4-1.example.com.zone区域配置文件
cat > /var/named/${OCP_CLUSTER_ID}.${DOMAIN}.zone << EOF
\$ORIGIN ${OCP_CLUSTER_ID}.${DOMAIN}.
\$TTL 1D
@           IN SOA  ${OCP_CLUSTER_ID}.${DOMAIN}. admin.${OCP_CLUSTER_ID}.${DOMAIN}. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum

@             IN NS                         dns.${DOMAIN}.

lb             IN A                          ${LB_IP}

api            IN A                          ${LB_IP}
api-int        IN A                          ${LB_IP}
*.apps         IN A                          ${LB_IP}

bootstrap      IN A                          ${BOOTSTRAP_IP}

master-0       IN A                          ${MASTER0_IP}
master-1       IN A                          ${MASTER1_IP}
master-2       IN A                          ${MASTER2_IP}

etcd-0         IN A                          ${MASTER0_IP}
etcd-1         IN A                          ${MASTER1_IP}
etcd-2         IN A                          ${MASTER2_IP}

worker-0       IN A                          ${WORKER0_IP}
worker-1       IN A                          ${WORKER1_IP}

_etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN}. 8640 IN SRV 0 10 2380 etcd-0.${OCP_CLUSTER_ID}.${DOMAIN}.
_etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN}. 8640 IN SRV 0 10 2380 etcd-1.${OCP_CLUSTER_ID}.${DOMAIN}.
_etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN}. 8640 IN SRV 0 10 2380 etcd-2.${OCP_CLUSTER_ID}.${DOMAIN}.

EOF

# 4.6.3.5	创建168.192.in-addr.arpa.zone反向解析区域配置文件
# 注意：以下脚本中的反向IP如果有变化需要在此手动修改。
cat > /var/named/168.192.in-addr.arpa.zone << EOF
\$TTL 1D
@           IN SOA  ${DOMAIN}. admin.${DOMAIN}. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
                                        
@                              IN NS       dns.${DOMAIN}.

13.122.168.192.in-addr.arpa.     IN PTR      bastion.${DOMAIN}.

12.122.168.192.in-addr.arpa.     IN PTR      support.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      dns.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      ntp.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      yum.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      registry.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      nfs.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      lb.${OCP_CLUSTER_ID}.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      api.${OCP_CLUSTER_ID}.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      api-int.${OCP_CLUSTER_ID}.${DOMAIN}.

200.122.168.192.in-addr.arpa.    IN PTR      bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}.

201.122.168.192.in-addr.arpa.    IN PTR      master-0.${OCP_CLUSTER_ID}.${DOMAIN}.
202.122.168.192.in-addr.arpa.    IN PTR      master-1.${OCP_CLUSTER_ID}.${DOMAIN}.
203.122.168.192.in-addr.arpa.    IN PTR      master-2.${OCP_CLUSTER_ID}.${DOMAIN}.

210.122.168.192.in-addr.arpa.    IN PTR      worker-0.${OCP_CLUSTER_ID}.${DOMAIN}.
211.122.168.192.in-addr.arpa.    IN PTR      worker-1.${OCP_CLUSTER_ID}.${DOMAIN}.

EOF

# 4.6.4	重启BIND服务
# 重启BIND服务，然后检查没有错误日志。
systemctl restart named
rndc reload
journalctl -u named

# 4.6.5	将Support节点的DNS配置指向自己
nmcli c mod $(nmcli con show |awk 'NR==2{print}'|awk '{print $1}') ipv4.dns "${DNS_IP}"
systemctl restart network
nmcli c show $(nmcli con show |awk 'NR==2{print}'|awk '{print $1}')| grep ipv4.dns

# 4.6.6	测试正反向DNS解析
# 1.	正向解析测试
dig nfs.${DOMAIN} +short
dig support.${DOMAIN} +short 
dig yum.${DOMAIN} +short
dig registry.${DOMAIN} +short
dig ntp.${DOMAIN} +short
dig lb.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig api.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig api-int.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig *.apps.${OCP_CLUSTER_ID}.${DOMAIN} +short

dig bastion.${DOMAIN} +short

dig bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} +short

dig master-0.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig etcd-0.${OCP_CLUSTER_ID}.${DOMAIN} +short

dig master-1.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig etcd-1.${OCP_CLUSTER_ID}.${DOMAIN} +short

dig master-2.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig etcd-2.${OCP_CLUSTER_ID}.${DOMAIN} +short

dig worker-0.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig worker-1.${OCP_CLUSTER_ID}.${DOMAIN} +short

dig _etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN} SRV +short

# 2.	反向解析测试
dig -x ${BASTION_IP} +short
dig -x ${SUPPORT_IP} +short
dig -x ${BOOTSTRAP_IP} +short
dig -x ${MASTER0_IP} +short
dig -x ${MASTER1_IP} +short
dig -x ${MASTER2_IP} +short
dig -x ${WORKER0_IP} +short
dig -x ${WORKER1_IP} +short

# 4.7	配置远程正式YUM源
# 4.7.1	配置Support节点的YUM源
# 1.	删除临时yum源
mv /etc/yum.repos.d/base.repo{,.bak}
# 2.	创建yum repo配置文件
setVAR YUM_DOMAIN yum.${DOMAIN}:8080
cat > /etc/yum.repos.d/ocp.repo << EOF
[rhel-7-server]
name=rhel-7-server
baseurl=http://${YUM_DOMAIN}/repo/rhel-7-server-rpms/
enabled=1
gpgcheck=0

[rhel-7-server-extras] 
name=rhel-7-server-extras
baseurl=http://${YUM_DOMAIN}/repo/rhel-7-server-extras-rpms/
enabled=1
gpgcheck=0

[rhel-7-server-ose] 
name=rhel-7-server-ose
baseurl=http://${YUM_DOMAIN}/repo/rhel-7-server-ose-${OCP_MAJOR_VER}-rpms/
enabled=1
gpgcheck=0 

EOF
yum repolist

# 4.7.2	安装基础软件包，验证YUM源
# 在Support节点安装以下软件包，验证YUM源是正常的。
yum -y install wget git net-tools bridge-utils jq tree httpd-tools 

# 4.8	部署NTP服务
# 注意：下文将Support节点当做OpenShift集群的NTP服务源。如果用户已经有NTP服务，可以忽略此节，并在安装OpenShift集群后将集群节点的时间服务指向已有的NTP服务。
# 4.8.1	设置正确的时区
timedatectl set-timezone Asia/Shanghai
timedatectl status | grep 'Time zone'
# 4.8.2	配置chrony服务
# 1.	RHEL 7.8最小化安装会安装chrony时间服务软件。我们先查看chrony服务状态：
systemctl status chronyd
yum install chrony
2.	备份原始chrony.conf配置文件，再修改配置文件
cp /etc/chrony.conf{,.bak}
sed -i -e "s/^server*/#&/g" \
       -e "s/#local stratum 10/local stratum 10/g" \
       -e "s/#allow 192.168.0.0\/16/allow all/g" \
       /etc/chrony.conf
cat >> /etc/chrony.conf << EOF
server ntp.${DOMAIN} iburst
EOF
# 3.	重启chrony服务
systemctl enable --now chronyd
systemctl restart chronyd
# 4.8.3	检查chrony服务端启动
ps -auxw |grep chrony
ss -lnup |grep chronyd
systemctl status chronyd
chronyc -n sources -v

# 4.9	部署本地Docker Registry
# 该Docker Registry镜像库用于提供OCP安装过程所需的容器镜像。
# 4.9.1	创建Docker Registry相关目录
## 容器镜像库存放的根目录
setVAR REGISTRY_PATH /data/registry
mkdir -p ${REGISTRY_PATH}/{auth,certs,data}

# 4.9.2	创建访问Docker Registry的证书
# 我的方法
cat > ${REGISTRY_PATH}/certs/ssl.conf << EOF
[req]
default_bits  = 4096
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
countryName = CN
stateOrProvinceName = BJ
localityName = BJ
organizationName = Global Security
organizationalUnitName = IT Department
commonName = registry.example.com

[req_ext]
subjectAltName = @alt_names

[v3_req]
subjectAltName = @alt_names

# Key usage: this is typical for a CA certificate. However since it will
# prevent it being used as an test self-signed certificate it is best
# left out by default.
# keyUsage                = critical,keyCertSign,cRLSign

basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash

[alt_names]
DNS.1 = registry.example.com
EOF

openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout ${REGISTRY_PATH}/certs/registry.key \
  -out ${REGISTRY_PATH}/certs/registry.crt -config ${REGISTRY_PATH}/certs/ssl.conf

openssl x509 -in ${REGISTRY_PATH}/certs/registry.crt -text | head -n 14

# 文档里的方法
openssl req -newkey rsa:4096 -nodes -sha256 -keyout ${REGISTRY_PATH}/certs/registry.key -x509 -days 3650 \
  -out ${REGISTRY_PATH}/certs/registry.crt \
  -subj "/C=CN/ST=BEIJING/L=BJ/O=REDHAT/OU=IT/CN=registry.${DOMAIN}/emailAddress=admin@${DOMAIN}"
openssl x509 -in ${REGISTRY_PATH}/certs/registry.crt -text | head -n 14

# 4.9.3	安装Docker Registry
# 1.	安装docker-distribution
yum -y install docker-distribution

# 2.	创建Registry认证凭据，允许用openshift/redhat登录。
htpasswd -bBc ${REGISTRY_PATH}/auth/htpasswd openshift redhat
cat ${REGISTRY_PATH}/auth/htpasswd

# 3.	创建docker-distribution配置文件
setVAR REGISTRY_DOMAIN registry.${DOMAIN}:5000                  ## 容器镜像库的访问域名

cat << EOF > /etc/docker-distribution/registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: ${REGISTRY_PATH}/data
    delete:
        enabled: false
auth:
  htpasswd:
    realm: basic-realm
    path: ${REGISTRY_PATH}/auth/htpasswd
http:
    addr: 0.0.0.0:5000
    host: https://${REGISTRY_DOMAIN}
    tls:
      certificate: ${REGISTRY_PATH}/certs/registry.crt
      key: ${REGISTRY_PATH}/certs/registry.key
EOF
cat /etc/docker-distribution/registry/config.yml

# 4.	启动Registry镜像库服务
systemctl enable docker-distribution --now
systemctl status docker-distribution

# 4.9.4	从本地访问Docker Registry 
# 将访问Registry的证书复制到RHEL系统的默认目录，然后更新到系统中。
cp ${REGISTRY_PATH}/certs/registry.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust
curl -u openshift:redhat https://${REGISTRY_DOMAIN}/v2/_catalog

# 4.9.5	从远程访问Docker Registry
# [Bastion]
# [root@bastion ~]#
# scp root@support.example.internal:/etc/pki/ca-trust/source/anchors/registry.crt /etc/pki/ca-trust/source/anchors/
# update-ca-trust
# curl -u openshift:redhat https://${REGISTRY_DOMAIN}/v2/_catalog

# 4.9.6	导入OpenShift核心镜像到Docker Registry
# 4.9.6.1	设置基础环境变量
setVAR REGISTRY_REPO ocp4/openshift4       ## 在Docker Registry中存放OpenShift核心镜像的Repository
setVAR GODEBUG x509ignoreCN=0

# 4.9.6.2	安装镜像操作工具并登录Docker Registry
yum -y install podman skopeo 
# 用openshift/redhat登录Docker Registry，并将生成的免密登录信息追加到${PULL_SECRET_FILE文件。
setVAR PULL_SECRET_FILE ${OCP_PATH}/secret/redhat-pull-secret.json
cp ${OCP_PATH}/secret/redhat-pull-secret.json{,.bak}
podman login -u openshift -p redhat --authfile ${PULL_SECRET_FILE} ${REGISTRY_DOMAIN}
cat $PULL_SECRET_FILE | jq . 

# 4.9.6.3	向Docker Registry导入OpenShift核心镜像
tar -xvf ${OCP_PATH}/ocp-image/ocp-image-${OCP_VER}.tar -C ${OCP_PATH}/ocp-image/
rm -f ${OCP_PATH}/ocp-image/ocp-image-${OCP_VER}.tar

oc image mirror -a ${PULL_SECRET_FILE} \
     --dir=${OCP_PATH}/ocp-image/mirror_${OCP_VER} file://openshift/release:${OCP_VER}* ${REGISTRY_DOMAIN}/${REGISTRY_REPO}

# 查看已经导入镜像库镜像数量，然后查看镜像信息。
curl -u openshift:redhat https://${REGISTRY_DOMAIN}/v2/_catalog
curl -u openshift:redhat -s https://${REGISTRY_DOMAIN}/v2/${REGISTRY_REPO}/tags/list |jq -M '.["tags"][]' | wc -l
curl -u openshift:redhat -s https://${REGISTRY_DOMAIN}/v2/${REGISTRY_REPO}/tags/list |jq -M '.["name"] + ":" + .["tags"][]' 
oc adm release info -a ${PULL_SECRET_FILE} "${REGISTRY_DOMAIN}/${REGISTRY_REPO}:${OCP_VER}-x86_64" | grep -A 200 -i "Images" 


# 4.10	部署HAProxy负载均衡服务
# 1.	安装Haproxy
yum -y install haproxy
systemctl enable haproxy --now

# 2.	添加haproxy.cfg配置文件
cat <<EOF > /etc/haproxy/haproxy.cfg

# Global settings
#---------------------------------------------------------------------
global
    maxconn     20000
    log         /dev/log local0 info
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
#    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          300s
    timeout server          300s
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 20000

listen stats
    bind :9000
    mode http
    stats enable
    stats uri /

frontend  openshift-api-server-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:6443
    mode tcp
    option tcplog
    default_backend openshift-api-server-${OCP_CLUSTER_ID}

frontend  machine-config-server-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:22623
    mode tcp
    option tcplog
    default_backend machine-config-server-${OCP_CLUSTER_ID}

frontend  ingress-http-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:80
    mode tcp
    option tcplog
    default_backend ingress-http-${OCP_CLUSTER_ID}

frontend  ingress-https-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:443
    mode tcp
    option tcplog
    default_backend ingress-https-${OCP_CLUSTER_ID}

backend openshift-api-server-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     bootstrap bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check
    server     master-1 master-1.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check
    server     master-2 master-2.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check

backend machine-config-server-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     bootstrap bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check
    server     master-1 master-1.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check
    server     master-2 master-2.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check

backend ingress-http-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     worker-0 worker-0.${OCP_CLUSTER_ID}.${DOMAIN}:80 check
    server     worker-1 worker-1.${OCP_CLUSTER_ID}.${DOMAIN}:80 check

backend ingress-https-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     worker-0 worker-0.${OCP_CLUSTER_ID}.${DOMAIN}:443 check
    server     worker-1 worker-1.${OCP_CLUSTER_ID}.${DOMAIN}:443 check

EOF
cat /etc/haproxy/haproxy.cfg

# 3.	重启HAProxy服务, 然后检查HAProxy服务
systemctl restart haproxy
ss -lntp |grep haproxy

# 访问如下页面http://lb.ocp4-1.example.internal:9000/，确认每行颜色和下图一致。注意：为了能解析域名，运行浏览器所在节点需要将DNS设置到support节点的地址。

# 5	准备定制安装文件
# 5.1	准备Ignition引导文件
# 5.1.1	安装openshift-install
tar -xzf ${OCP_PATH}/ocp-installer/openshift-install-linux-${OCP_VER}.tar.gz -C /usr/local/sbin/
openshift-install version

# 5.1.2	准备install-config.yaml文件
# 5.1.2.1	设置环境变量
setVAR REPLICA_WORKER 0                                             ## 在安装阶段，将WORKER的数量设为0
setVAR REPLICA_MASTER 3                                             ## 本文档的OpenShift集群只有1个master节点
setVAR CLUSTER_PATH /data/ocp-cluster/${OCP_CLUSTER_ID}
setVAR IGN_PATH ${CLUSTER_PATH}/ignition                            ## 存放Ignition相关文件的目录
setVAR PULL_SECRET_STR "\$(cat \${PULL_SECRET_FILE})"                    ## 在安装过程使用${PULL_SECRET_FILE}拉取镜像
setVAR SSH_KEY_PATH ${CLUSTER_PATH}/ssh-key                         ## 存放ssh-key相关文件的目录
setVAR SSH_PRI_FILE ${SSH_KEY_PATH}/id_rsa                          ## 节点之间访问的私钥文件名

# 5.1.2.2	创建CoreOS SSH访问密钥
# 该密钥用于登录OpenShift集群节点的CoreOS。
mkdir -p ${IGN_PATH}
mkdir -p ${SSH_KEY_PATH}
ssh-keygen -N '' -f ${SSH_KEY_PATH}/id_rsa
ll ${SSH_KEY_PATH}
setVAR SSH_PUB_STR "\$(cat ${SSH_KEY_PATH}/id_rsa.pub)"             ## 节点之间访问的公钥文件内容
echo ${SSH_PUB_STR}

# 5.1.2.3	创建无证书的install-config.yaml文件
cat << EOF > ${IGN_PATH}/install-config.yaml
apiVersion: v1
baseDomain: ${DOMAIN}
compute:
- hyperthreading: Enabled
  name: worker
  replicas: ${REPLICA_WORKER}
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: ${REPLICA_MASTER}
metadata:
  name: ${OCP_CLUSTER_ID}
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
fips: false
pullSecret: '${PULL_SECRET_STR}'
sshKey: '${SSH_PUB_STR}'
imageContentSources: 
- mirrors:
  - ${REGISTRY_DOMAIN}/${REGISTRY_REPO}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${REGISTRY_DOMAIN}/${REGISTRY_REPO}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

# 5.1.2.4	附加Docker Registry镜像库的证书到install-config.yaml文件
cp ${REGISTRY_PATH}/certs/registry.crt ${IGN_PATH}/
sed -i -e 's/^/  /' ${IGN_PATH}/registry.crt
echo "additionalTrustBundle: |" >> ${IGN_PATH}/install-config.yaml
cat ${IGN_PATH}/registry.crt >> ${IGN_PATH}/install-config.yaml

# 5.1.2.5	查看最终的install-config.yaml文件
# 重要说明：由于install-config.yaml中的安装证书有效期只有24小时，因此如果在生成该文件后24小时没有安装好OpenShift集群，需要重新操作生成install-config.yaml和其他所有安装前的准备步骤（所有以前生成的文件可以删除掉）。
cat ${IGN_PATH}/install-config.yaml

# 5.1.2.6	备份install-config.yaml文件
cp ${IGN_PATH}/install-config.yaml{,.`date +%Y%m%d%H%M`.bak}
ll ${IGN_PATH}

# 5.1.3	准备manifest文件
# 5.1.3.1	生成manifest文件
# OpenShift集群节点在启动后会根据manifest文件生成的Ignition设置各自的操作系统配置。
openshift-install create manifests --dir ${IGN_PATH}
tree ${IGN_PATH}/manifests/ ${IGN_PATH}/openshift/

# 5.1.3.2	修改master节点的调度策略
# 修改mastersSchedulable为false, 禁用master节点运行用户负载。
sed -i 's/mastersSchedulable: true/mastersSchedulable: false/g' ${IGN_PATH}/manifests/cluster-scheduler-02-config.yml
cat ${IGN_PATH}/manifests/cluster-scheduler-02-config.yml | grep mastersSchedulable

# 5.1.3.3	为所有节点创建时钟同步配置文件
setVAR NTP_CONF $(cat << EOF | base64 -w 0
server ntp.${DOMAIN} iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF)

echo ${NTP_CONF} | base64 -d

# 创建master节点的创建时钟同步配置文件。
cat << EOF > ${IGN_PATH}/openshift/99_masters-chrony-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: masters-chrony-configuration
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 3.1.0
    networkd: {}
    passwd: {}
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${NTP_CONF}
        mode: 420
        overwrite: true
        path: /etc/chrony.conf
  osImageURL: ""
EOF
cat ${IGN_PATH}/openshift/99_masters-chrony-configuration.yaml

# 创建worker节点的创建时钟同步配置文件。
cat << EOF > ${IGN_PATH}/openshift/99_workers-chrony-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: workers-chrony-configuration
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 3.1.0
    networkd: {}
    passwd: {}
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${NTP_CONF}
        mode: 420
        overwrite: true
        path: /etc/chrony.conf
  osImageURL: ""
EOF
more ${IGN_PATH}/openshift/99_workers-chrony-configuration.yaml

# 5.1.4	创建Ignition引导文件
openshift-install create ignition-configs --dir ${IGN_PATH}/
ll ${IGN_PATH}/*.ign
jq .ignition.config ${IGN_PATH}/master.ign 
jq .ignition.config ${IGN_PATH}/worker.ign 

# 5.2	准备节点自动设置文件
# 为了方面CoreOS节点首次启动后的设置操作，所有操作都放在节点自动设置文件中，只需下载该文件执行即可完成对应节点的所有配置。
setVAR GATEWAY_IP 192.168.122.1      ## CoreOS启动时使用的GATEWAY
setVAR NETMASK 24                  ## CoreOS启动时使用的NETMASK
setVAR CONNECT_NAME "Wired Connection"    
# CoreOS的nmcli看到的connection名称，OCP4.6 是“Wired Connection”
# CoreOS的nmcli看到的connection名称，OCP4.8 是“Wired connection 1”

creat_auto_config_file(){

cat << EOF > ${IGN_PATH}/set-${NODE_NAME}
nmcli connection modify "${CONNECT_NAME}" ipv4.addresses ${IP}/${NETMASK}
nmcli connection modify "${CONNECT_NAME}" ipv4.dns ${DNS_IP}
nmcli connection modify "${CONNECT_NAME}" ipv4.gateway ${GATEWAY_IP}
nmcli connection modify "${CONNECT_NAME}" ipv4.method manual
nmcli connection down "${CONNECT_NAME}"
nmcli connection up "${CONNECT_NAME}"

sudo coreos-installer install /dev/sda --insecure-ignition --ignition-url=http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/${NODE_TYPE}.ign --firstboot-args 'rd.neednet=1' --copy-network
EOF
}

#创建BOOTSTRAP启动定制文件
NODE_TYPE="bootstrap"
NODE_NAME="bootstrap"
IP=${BOOTSTRAP_IP}
creat_auto_config_file
cat ${IGN_PATH}/set-${NODE_NAME}

#创建master-0启动定制文件
NODE_TYPE="master"
NODE_NAME="master-0"
IP=${MASTER0_IP}
creat_auto_config_file

#创建master-1启动定制文件
NODE_TYPE="master"
NODE_NAME="master-1"
IP=${MASTER1_IP}
creat_auto_config_file

#创建master-2启动定制文件
NODE_TYPE="master"
NODE_NAME="master-2"
IP=${MASTER2_IP}
creat_auto_config_file

#创建worker-0启动定制文件
NODE_TYPE="worker"
NODE_NAME="worker-0"
IP=${WORKER0_IP}
creat_auto_config_file

#创建worker-1启动定制文件
NODE_TYPE="worker"
NODE_NAME="worker-1"
IP=${WORKER1_IP}
creat_auto_config_file

ll ${IGN_PATH}/set-*

# 5.3	创建文件下载目录
# 为定制文件创建Apache HTTP上的可下载目录。
chmod -R 705 ${IGN_PATH}/
cat << EOF > /etc/httpd/conf.d/ignition.conf
Alias /${OCP_CLUSTER_ID} "${IGN_PATH}/../"
<Directory "${IGN_PATH}/../">
  Options +Indexes +FollowSymLinks
  Require all granted
</Directory>
<Location /${OCP_CLUSTER_ID}>
  SetHandler None
</Location>
EOF
systemctl restart httpd
# 确认所有安装所需文件可下载。
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/bootstrap.ign | jq 
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/worker.ign | jq
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/master.ign | jq
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-bootstrap
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-master-0
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-master-1
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-master-2
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-worker-0
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-worker-1

# 6	创建Bootstrap、Master、Worker虚拟机节点
# 具体根据不同的IaaS环境和虚机节点配置要求创建bootstrap、master-0、master-1、master-2、worker-0、worker-1虚拟机节点，方法和过程略。需要注意以下事项：
# 1.	将硬盘的启动优先级设为最高，并将rhcos-4.8.10-x86_64-live.x86_64.iso作为所有虚机的启动盘。
# 2.	为虚拟机配置一个网卡，并使用网桥类型的网络。
# 3.	虚拟机操作系统类型选择RHEL 7或RHEL 8。

# 7	安装OCP集群
# 7.1	第一阶段：部署bootstrap阶段
# 7.1.1	两次启动
# 配置 ip 地址
sudo nmcli con mod 'Wired Connection' connection.autoconnect 'yes' ipv4.method 'manual' ipv4.address '192.168.122.200/24' ipv4.gateway '192.168.122.1' ipv4.dns '192.168.122.12'
sudo nmcli con down 'Wired Connection'
sudo nmcli con up 'Wired Connection'

# 使用命令检查网卡配置是否成功
ip a

# 在bootstrap节点中执行以下命令，先下载自动配置文件，然后执行它。注意：由于此节点当前还未完成配置，因此只能通过IP地址获取自动配置文件。
curl -O http://<SOPPORT-IP>:8080/<OCP_CLUSTER_ID>/ignition/set-bootstrap
source set-bootstrap
# 执行命令重启bootstrap节点。
reboot

# 7.1.2	查看bootstrap节点部署进程
# 1.	删除以前ssh保留的登录主机信息。
rm -rf ~/.ssh/known_hosts
# 2.	检查bootstrap节点的镜像库mirror配置是否按照install-config.yaml的内容进行配置
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "sudo cat /etc/containers/registries.conf"
# 3.	检查bootstrap节点是否能访问到Registry。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "curl -s -u openshift:redhat https://registry.${DOMAIN}:5000/v2/_catalog"
# 4.	检查bootstrap节点的本地pods。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "sudo crictl pods"
# 5.	访问如下地址http://lb.ocp4-1.example.internal:9000/，确认只有两处bootstrap节点变为绿色。
# 6.	确认可以通过curl命令查看machine config配置服务是否启动。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "curl -kIs https://api-int.${OCP_CLUSTER_ID}.${DOMAIN}:22623/config/master"

# 7.	可通过如下命令从宏观面观察部署过程。
openshift-install wait-for install-complete --log-level=debug --dir=${IGN_PATH}

# 8.	跟踪bootstrap的日志以识别安装进度，当循环出现如下红色字体提示的内容的时候，并且haproxy的web监控界面openshift-api-server和machine-config-server的bootstrap部分变为绿色时，说明bootstrap的引导服务已经启动，此时可进入下一个阶段。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "journalctl -b -f -u bootkube.service"

# 7.2	第二阶段：部署master阶段
# 7.2.1	两次启动
# 参照bootstrap的两次启动步骤启动所有master节点，将网络参数换成各自master的地址。
# 7.2.2	查看master节点部署进程
# 在support节点执行命令检查master节点的镜像库配置是否按照install-config.yaml的内容进行配置
ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "sudo cat /etc/containers/registries.conf"
# 检查是否能够正常访问registry
ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "curl -s -u openshift:redhat https://registry.${DOMAIN}:5000/v2/_catalog"
# 安装过程中可以通过查看如下日志来跟踪安装过程。注意以下日志的红色字体部分，这些内容指示master的不同安装阶段
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "journalctl -b -f -u bootkube.service"
# 出现上述最后两条红色字体后，说明bootstrap的任务已经完成，可以已经进入后续安装部署节点
# 另外，我们也可以通过如下方法了解安装进程：
tail -f ${IGN_PATH}/.openshift_install.log 
openshift-install wait-for bootstrap-complete --log-level debug --dir ${IGN_PATH}
# 现在我们可以关闭bootstrap节点，继续进行下一个阶段部署。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "sudo shutdown -h now"
# 在安装过程中，也可以通过以下方法查看master节点的日志 
# ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "journalctl -xef"

# 复制kubeconfig文件到用户缺省目录，以便可以用oc命令访问集群。
mkdir ~/.kube
cp ${IGN_PATH}/auth/kubeconfig ~/.kube/config

# 检查节点状态，确保master的STATUS均为Ready状态
oc get node

# 7.3	第三阶段：部署worker阶段
# 7.3.1	两次启动
# 参照bootstrap的两次启动步骤启动所有worker节点，将网络参数换成各自worker的地址。
# 等待 worker machine-config-daemon-firstboot service 完成
ssh -i ${SSH_PRI_FILE} core@worker-1.${OCP_CLUSTER_ID}.${DOMAIN} "sudo journalctl -f -u machine-config-daemon-firstboot.service"

# 7.3.2	批准csr请求
# 通过如下命令查看 csr批准请求，第一批出现的是“kube-apiserver-client-kubelet”相关csr。
oc get csr | grep Pending
# 执行以下命令批准请求。
oc get csr | grep Pending | awk '{print $1}' | xargs oc adm certificate approve
# 再次执行命令查看 csr批准请求，第二批出现的是“kubelet-serving”相关csr。
oc get csr | grep Pending
# 执行以下命令批准请求。
oc get csr | grep Pending | awk '{print $1}' | xargs oc adm certificate approve

# 7.3.3	查看集群部署进展
# 执行以下命令来查看集群部署是否完成，整个过程需要一些时间。出现以下红色字体部分，说明集群已经部署完成。请记下kubeadmin和对应的登录密码。
oc get node
oc get clusteroperators
oc get clusterversion
tail -f ${IGN_PATH}/.openshift_install.log
openshift-install wait-for install-complete --log-level debug --dir ${IGN_PATH}

# 检查 kube-apiserver operator 日志
oc -n openshift-kube-apiserver-operator logs $(oc get pods -n openshift-kube-apiserver-operator -o jsonpath='{ .items[*].metadata.name }') -f

# 7.3.4	登录OpenShift
# 执行命令，将配置文件复制到用户的缺省目录。
cp ${IGN_PATH}/auth/kubeconfig ~/.kube/config
# 用初始化用户和密码登录。
# extract the ingress-ca certificate
oc -n openshift-authentication rsh $(oc get pod -n openshift-authentication -l app=oauth-openshift -o name | head -1) cat /run/secrets/kubernetes.io/serviceaccount/ca.crt > ${IGN_PATH}/ingress-ca.crt
cp ${IGN_PATH}/ingress-ca.crt /etc/pki/ca-trust/source/anchors
update-ca-trust
oc login https://api.${OCP_CLUSTER_ID}.${DOMAIN}:6443 -u kubeadmin -p <KUBEADMIN-PASSWORD>

# 7.4	第五阶段：连续运行24小时
# 在完成上述OpenShift集群安装步骤后，需要让OpenShift集群以非降级状态运行 24 小时，以完成第一次证书轮转。

# 3.2.8	下载离线ImageStream镜像包（可选）
# 3.2.8.1	创建镜像列表文件
mkdir -p ${OCP_PATH}/app-image/redhat-app/images
# 执行命令，将所有下载镜像写入app-images.txt文件。
IMAGE_LIST_FILE_NAME=${OCP_PATH}/app-image/redhat-app/app-images.txt
touch ${IMAGE_LIST_FILE_NAME}
oc project openshift
IMAGES=$(oc get is -o custom-columns=NAME:metadata.name --no-headers -l samples.operator.openshift.io/managed)
for IMAGE in ${IMAGES}
do
  i=0
  IS_KINDS=$(oc get is ${IMAGE} -o=jsonpath='{.spec.tags[*].from.kind}')
  for IS_KIND in ${IS_KINDS}
  do
    if [ $IS_KIND = "DockerImage" ]; then
        IS_ADDR=$(oc get is ${IMAGE} -o=jsonpath={.spec.tags[$i].from.name})
        SITE=${IS_ADDR:0:8}
        if [ ${SITE} = "registry" ]; then
            echo ${IS_ADDR} >> ${IMAGE_LIST_FILE_NAME}
        fi
    fi
    ((i++))
  done
done
# 3.2.8.2	测试下载
# 先以其中一个镜像为例，测试下载过程是否正常
oc image mirror -a ${PULL_SECRET_FILE} --filter-by-os=linux/amd64 registry.redhat.io/rhscl/ruby-25-rhel7:latest --dir=${OCP_PATH}/app-image/redhat-app/images file://rhscl/ruby-25-rhel7:latest
oc image info --dir=${OCP_PATH}/app-image/redhat-app/images file://rhscl/ruby-25-rhel7:latest
# 删除测试文件
rm -rf ${OCP_PATH}/app-image/redhat-app/images
# 3.2.8.3	批量下载镜像
cat ${OCP_PATH}/app-image/redhat-app/app-images.txt | while read line; do
  echo “"================> Begin downloading $line <================"”
  oc image mirror -a ${PULL_SECRET_FILE} ${line} --filter-by-os=linux/amd64 --dir=${OCP_PATH}/app-image/redhat-app/images file://$(echo ${line} | cut -d '/' -f2)/$(echo ${line} | cut -d '/' -f3)
done
du -lh ${OCP_PATH}/app-image/redhat-app/images/v2 --max-depth=1

# 3.2.8.4	检查下载镜像
# 查看已下载镜像，查看是否有下载错误出现
cat ${OCP_PATH}/app-image/redhat-app/app-images.txt | while read line; do
  oc image info --dir=${OCP_PATH}/app-image/redhat-app/images \
    file://$(echo ${line} | cut -d '/' -f2)/$(echo ${line} | cut -d '/' -f3) | grep error
  if [ $? -eq 0 ]; then
    echo "ERROR for ${line}."
  else
    echo "RIGHT for ${line}."
  fi
done

# 3.2.8.5	批量打包镜像
for dir1 in $(ls --indicator-style=none ${OCP_PATH}/app-image/redhat-app/images/v2); do
  for dir2 in $(ls --indicator-style=none ${OCP_PATH}/app-image/redhat-app/images/v2/${dir1}); do
   tar -zcvf ${OCP_PATH}/app-image/redhat-app/images/v2/${dir1}/${dir2}.tar.gz \
     -C ${OCP_PATH}/app-image/redhat-app/images/v2/${dir1} ${dir2}
  done
done

# 3.2.8.6	清除下载文件
shopt -s extglob
for dir1 in $(ls --indicator-style=none ${OCP_PATH}/app-image/redhat-app/images/v2); do
   rm -rf ${OCP_PATH}/app-image/redhat-app/images/v2/${dir1}/!(*.tar.gz)
done

# 8	集群初始化和功能验证
# 8.1.1	用户管理
# 8.1.2	新建集群管理员
# 创建包含admin用户和对应密码的文件：users.htpasswd
htpasswd -bBc ${CLUSTER_PATH}/users.htpasswd admin P@ssw0rd
# 基于users.htpasswd文件创建secret验证库
oc create secret generic htpass-secret --from-file=htpasswd=${CLUSTER_PATH}/users.htpasswd -n openshift-config
# 创建基于HTPasswd的IdentityProvider，并提供验证库htpass-secret
cat << EOF | oc apply -f -
---
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd_provider 
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF
# 授予admin用户cluster-admin权限
oc adm policy add-cluster-role-to-user cluster-admin admin

# 测试环境里如果加上 --rolebinding-name=cluster-admin 登陆 console-openshift-console 看到的界面与 kubeadmin 不一样，因此不需要执行以下两条命令
# oc adm policy add-cluster-role-to-user cluster-admin admin --rolebinding-name=cluster-admin
# oc describe clusterrolebindings cluster-admin

# 先移去缺省的KUBECONFIG对应的文件，再用admin用户通过命令行和浏览器登录（浏览器中选择“htpasswd_provider”）。
mv ~/.kube/config ~/.kube/config.bak 
oc login https://api.${OCP_CLUSTER_ID}.${DOMAIN}:6443 -u admin -p P@ssw0rd
oc get identity

# 8.1.3	新建普通用户
htpasswd -b ${CLUSTER_PATH}/users.htpasswd user1 P@ssw0rd
cat ${CLUSTER_PATH}/users.htpasswd
# 更新用户认证库secret
oc create secret generic htpass-secret --from-file=htpasswd=${CLUSTER_PATH}/users.htpasswd -n openshift-config --dry-run -o yaml | oc apply -f -
# 添加授权
oc adm policy add-cluster-role-to-user admin user1
# 登录验证，确认权限差别（也可以在浏览器控制台中看到和admin用户的区别）
oc login https://api.${OCP_CLUSTER_ID}.${DOMAIN}:6443 -u user1 -p P@ssw0rd
oc get identity

# 8.1.4	删除kubeadmin
# 在上述步骤完成后，特别是添加了具有cluster-admin role的用户后，即可删除kubeadmin用户
oc delete secret kubeadmin -n kube-system

# 8.2	部署BusyBox应用
# 8.2.1	导入BusyBox的应用镜像
setVAR BUSYBOX_IMG_PATH ${OCP_PATH}/app-image/thirdparty/busybox
skopeo copy --dest-creds=openshift:redhat docker-archive:${BUSYBOX_IMG_PATH}/busybox_1.31.1.tar.gz \
      docker://${REGISTRY_DOMAIN}/apps/busybox:1.31.1
skopeo copy --dest-creds=openshift:redhat docker-archive:${BUSYBOX_IMG_PATH}/busybox_1.31.1.tar.gz \
      docker://${REGISTRY_DOMAIN}/apps/busybox:latest
skopeo inspect --creds=openshift:redhat docker://${REGISTRY_DOMAIN}/apps/busybox:latest

# 8.2.2	部署BusyBox应用
oc new-project busybox
cat << EOF | oc apply -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox
  namespace: busybox
  labels:
    app: busybox
spec:
  replicas: 1
  selector:
    matchLabels:
      app: busybox
  template:
    metadata:
      labels:
        app: busybox
    spec:
      containers:
        - name: pod-backend
          image: ${REGISTRY_DOMAIN}/apps/busybox:latest
          command: ["sleep"]
          args: ["1000"]
EOF
oc get pod
oc rsh $(oc get pod | grep busybox | awk '{print $1}') echo HelloWorld

# 8.3	配置存储
# 8.3.1	设置存储相关环境变量
setVAR NFS_OCP_REGISTRY_PATH /data/ocp-cluster/${OCP_CLUSTER_ID}/nfs/ocp-registry	## 存放本集群Registry数据的根目录
setVAR NFS_USER_FILE_PATH    /data/ocp-cluster/${OCP_CLUSTER_ID}/nfs/userfile		## 存放本集群用户数据的根目录
setVAR NFS_DOMAIN nfs.${DOMAIN} 										## 运行NFS Server的域名
setVAR NFS_CLIENT_NAMESPACE csi-nfs									## 在OCP上运行NFS Client的项目
setVAR NFS_CLIENT_PROVISIONER_IMAGE ${REGISTRY_DOMAIN}/${NFS_CLIENT_NAMESPACE}/nfs-client-provisioner  ## NFS Client Image
setVAR PROVISIONER_NAME kubernetes-nfs
setVAR STORAGECLASS_NAME sc-csi-nfs
setVAR OCP_REGISTRY_PVC_NAME pvc-ocp-registry
setVAR OCP_REGISTRY_PV_NAME pv-ocp-registry

# 8.3.2	安装NFS服务
yum -y install nfs-utils
systemctl enable nfs-server --now
systemctl status nfs-server

# 8.3.3	配置OpenShift内部镜像库的存储
# 8.3.3.1	创建内部镜像库使用的NFS目录
mkdir -p ${NFS_OCP_REGISTRY_PATH}
chown -R nfsnobody.nfsnobody ${NFS_OCP_REGISTRY_PATH}
chmod -R 777 ${NFS_OCP_REGISTRY_PATH}

echo ${NFS_OCP_REGISTRY_PATH} *'(rw,sync,no_wdelay,no_root_squash,insecure,fsid=0)' \
> /etc/exports.d/ocp-registry-${OCP_CLUSTER_ID}.exports
cat /etc/exports.d/ocp-registry-${OCP_CLUSTER_ID}.exports

exportfs -rav | grep ocp-registry
showmount -e ${NFS_DOMAIN}

# 8.3.3.2	创建PV
cat << EOF | oc create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${OCP_REGISTRY_PV_NAME}
spec:
  capacity:
    storage: 100Gi 
  accessModes:
    - ReadWriteMany 
  persistentVolumeReclaimPolicy: Retain 
  nfs: 
    path: ${NFS_OCP_REGISTRY_PATH}
    server: ${NFS_DOMAIN}
    readOnly: false
EOF
oc get pv

# 8.3.3.3	创建PVC
oc project openshift-image-registry
cat << EOF | oc create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${OCP_REGISTRY_PVC_NAME}
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteMany      
  resources:
     requests:
       storage: 100Gi
EOF
oc get pvc

# 此时PV已经变为Bound的状态了。
oc get pv

# 8.3.3.4	指定内部镜像库使用PVC
oc patch configs.imageregistry.operator.openshift.io cluster --type merge \
  --patch '{"spec":{"storage":{"pvc":{"claim":"'${OCP_REGISTRY_PVC_NAME}'"}}}}'
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState": "Managed"}}'
oc get configs.imageregistry.operator.openshift.io cluster -o json | jq -r '.spec |.managementState,.storage'
oc get pod -n openshift-image-registry

# 8.3.4	为应用使用的存储配置NFS StorageClass
# 为了OpenShift应用能够使用存储，本文将以NFS为例说明如何为OpenShift添加StorageClass。
# 8.3.4.1	创建NFS 目录
mkdir -p ${NFS_USER_FILE_PATH}
chown -R nfsnobody.nfsnobody ${NFS_USER_FILE_PATH}
chmod -R 777 ${NFS_USER_FILE_PATH}

echo ${NFS_USER_FILE_PATH} *'(rw,sync,no_wdelay,no_root_squash,insecure)' > /etc/exports.d/userfile-${OCP_CLUSTER_ID}.exports
cat /etc/exports.d/userfile-${OCP_CLUSTER_ID}.exports

exportfs -rav | grep userfile
showmount -e | grep userfile

# 8.3.4.2	创建NFS StorageClass部署配置
# 8.3.4.2.1	导入NFS Client镜像
skopeo copy --dest-creds=openshift:redhat \
      docker-archive:${OCP_PATH}/csi/nfs/nfs-client-provisioner_v3.1.0-k8s1.11.tar.gz \
      docker://${NFS_CLIENT_PROVISIONER_IMAGE}:v3.1.0-k8s1.11
skopeo copy --dest-creds=openshift:redhat \
      docker-archive:${OCP_PATH}/csi/nfs/nfs-client-provisioner_v3.1.0-k8s1.11.tar.gz \
      docker://${NFS_CLIENT_PROVISIONER_IMAGE}:latest
curl -u openshift:redhat https://${REGISTRY_DOMAIN}/v2/_catalog 
skopeo inspect --creds=openshift:redhat docker://${NFS_CLIENT_PROVISIONER_IMAGE}:latest

# 8.3.4.2.2	从Docker Registry中删除镜像（可选）
# 1.	先允许删除镜像
sed -i 's/enabled: false/enabled: true/g' /etc/docker-distribution/registry/config.yml
# 2.	重启Docker Registry
systemctl restart docker-distribution
# 3.	删除容器镜像
skopeo delete --creds=openshift:redhat docker://${NFS_CLIENT_PROVISIONER_IMAGE}:latest
# 4.	删除blobs/layers中的镜像垃圾
registry garbage-collect /etc/docker-distribution/registry/config.yml
# 5.	重启Docker Registry，释放缓存
systemctl restart docker-distribution

# 8.3.4.2.3	创建rbac.yaml文件
cat << EOF > ${CLUSTER_PATH}/rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa-nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cr-nfs-client-provisioner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: crb-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: sa-nfs-client-provisioner
    namespace: ${NFS_CLIENT_NAMESPACE}
roleRef:
  kind: ClusterRole
  name: cr-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: r-nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rb-nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
subjects:
  - kind: ServiceAccount
    name: sa-nfs-client-provisioner
    namespace: ${NFS_CLIENT_NAMESPACE}
roleRef:
  kind: Role
  name: r-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
EOF

# 8.3.4.2.4	创建deployment.yaml文件
cat << EOF > ${CLUSTER_PATH}/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
  labels:
    app: nfs-client-provisioner
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: sa-nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: ${NFS_CLIENT_PROVISIONER_IMAGE}:latest
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: ${PROVISIONER_NAME}
            - name: NFS_SERVER
              value: ${NFS_DOMAIN}
            - name: NFS_PATH
              value: ${NFS_USER_FILE_PATH}
      volumes:
        - name: nfs-client-root
          nfs:
            server: ${NFS_DOMAIN}
            path: ${NFS_USER_FILE_PATH}
EOF

# 8.3.4.2.5	创建storageclass.yaml文件
cat << EOF > ${CLUSTER_PATH}/storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ${STORAGECLASS_NAME}
provisioner: ${PROVISIONER_NAME}
parameters:
  archiveOnDelete: "false"
EOF

# Note: archiveOnDelete： "false" 删除PVC时不会保留数据，"true"将保留PVC数据

# 8.3.4.3	执行NFS StorageClass部署配置
# 部署NFS StorageClass配置
oc new-project ${NFS_CLIENT_NAMESPACE}

oc apply -f ${CLUSTER_PATH}/rbac.yaml
oc get clusterrole,clusterrolebinding,role,rolebinding -n ${NFS_CLIENT_NAMESPACE} | grep nfs
oc describe scc hostmount-anyuid -n ${NFS_CLIENT_NAMESPACE}

oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:${NFS_CLIENT_NAMESPACE}:sa-nfs-client-provisioner
oc describe scc hostmount-anyuid -n ${NFS_CLIENT_NAMESPACE}

oc apply -f ${CLUSTER_PATH}/deployment.yaml
oc get pod -n ${NFS_CLIENT_NAMESPACE}

oc apply -f ${CLUSTER_PATH}/storageclass.yaml 
oc get storageclass 

# 配置为默认存储类
oc patch storageclass ${STORAGECLASS_NAME} -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}' 
oc get storageclass 

# 8.3.4.4	部署测试应用验证NFS存储
# 创建验证应用使用的PVC资源
oc new-project pv-demo
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-busybox
  namespace: pv-demo
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: ${STORAGECLASS_NAME}
EOF
oc get pv,pvc -n pv-demo

# 基于busybox部署backend应用
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox
  namespace: pv-demo
  labels:
    app: busybox
spec:
  replicas: 2
  selector:
    matchLabels:
      app: busybox
  template:
    metadata:
      labels:
        app: busybox
    spec:
      containers:
        - name: pod-busybox
          image: ${REGISTRY_DOMAIN}/apps/busybox:latest
          command: ["/bin/sh"]
          args: ["-c", "while true; do date >> /mnt/index.html; hostname >> /mnt/index.html; sleep $(($RANDOM % 5 + 5)); done"]
          volumeMounts:
          - name: volume-busybox
            mountPath: /mnt
      volumes:
      - name: volume-busybox
        persistentVolumeClaim:
          claimName: pvc-busybox
EOF
oc get pod -n pv-demo
# 向上面2个busybox pod其中一个创建一个新文件“/mnt/test”，然后再另一个pod中确认可以查看到该文件，说明2个pod的/mnt挂在的是NFS共享目录。
oc rsh $(oc get pod -n pv-demo | sed -n 2p | awk '{print $1}') touch /mnt/test
oc rsh $(oc get pod -n pv-demo | sed -n 3p | awk '{print $1}') ls -al /mnt/test

# 执行命令，确认${NFS_USER_FILE_PATH}下已经有busybox使用PVC的目录。
ls -al ${NFS_USER_FILE_PATH}/pv-demo-pvc-busybox-$(oc get pvc pvc-busybox -o jsonpath='{.spec.volumeName}')

# 注意：在OpenShift 4.8中由于对应的Kubernetes 1.21版本，因此需要为kube-api-server增加“RemoveSelfLink=false”参数。
请参考以下文档 https://access.redhat.com/solutions/5685971 为名为cluster的kubeapiservers.operator.openshift.io对象增加参数。
# 在完成上述修改并且等所有master节点生效后，可以执行以下命令确认生效。
# oc edit kubeapiservers.operator.openshift.io cluster
#  unsupportedConfigOverrides: 
#    apiServerArguments:
#      feature-gates:
#      - RemoveSelfLink=false
oc get -o yaml kubeapiservers.operator.openshift.io/cluster

# 9 OperatorHub 镜像包下载
# 9.1 环境变量设定
setVAR OPERATOR_VER v4.6
# 设置 CatalogSource 的快照时间，由于 OPERATOR Hub 不停的在更新，我们设置如下参数，以标记我 们制作 CatalogSource 的时间
setVAR DATE 20211223

# 9.2 获取 OperatorHub CatalogSource 镜像
# 目前，红帽主要提供了如下 4 个应用目录镜像(CatalogSource)
# 
# Catalog: redhat-operators
# Index image: https://registry.redhat.io/redhat/redhat-operator-index:v4.6
# Description: Red Hat products packaged and shipped by Red Hat. Supported by Red Hat.
# 
# Catalog: certified-operators
# Index image: http://registry.redhat.io/redhat/certified-operator-index:v4.6
# Description: Products from leading independent software vendors (ISVs). Red Hat partners with ISVs to package and ship. Supported by the ISV.
# 
# Catalog: community-operators
# Index image: https://registry.redhat.io/redhat/community-operator-index:latest
# Description: Software maintained by relevant representatives in community-operators the operator-framework/community-operators GitHub repository. No official support.
# 
# Catalog: redhat-marketplace
# Index image: https://registry.redhat.io/redhat/redhat-marketplace-index:v4.6
# Description: Certified software that can be purchased from Red Hat Marketplace.

# 本文将以最常用的 redhat、certified 和 community 三个频道的 CatalogSource 为例，将其离线下载下 来
mkdir -p /data/ocp-operator/operator/${OPERATOR_VER}-${DATE}/catalog
cd /data/ocp-operator/operator/${OPERATOR_VER}-${DATE}/catalog

# 先记录下每个目录镜像的真实版本号，以备后续更新升级时检查版本号差异之用
 
oc image info -a ${PULL_SECRET_FILE} \
--filter-by-os=linux/amd64 \
registry.redhat.io/redhat/redhat-operator-index:${OPERATOR_VER} \
-o json | jq -r '.config.config.Labels | .version+ "-" +.release' > redhat-operator-index-version.txt

oc image info -a ${PULL_SECRET_FILE} \
--filter-by-os=linux/amd64 \
registry.redhat.io/redhat/certified-operator-index:${OPERATOR_VER} \
-o json | jq -r '.config.config.Labels | .version+ "-" +.release' > certified-operator-index-version.txt
   
oc image info -a ${PULL_SECRET_FILE} \
--filter-by-os=linux/amd64 \
registry.redhat.io/redhat/community-operator-index:latest \
-o json | jq -r '.config.config.Labels | .version+ "-" +.release' > community-operator-index-version.txt
   
# 下载镜像
# 下载 redhat-operators 的 CatalogSource 镜像 
skopeo copy \
--authfile ${PULL_SECRET_FILE} \
docker://registry.redhat.io/redhat/redhat-operator-index:${OPERATOR_VER} \ docker-archive:redhat-operator-index.tar.gz

# 下载 certified-operators 的 CatalogSource 镜像 
skopeo copy \
--authfile ${PULL_SECRET_FILE} \
docker://registry.redhat.io/redhat/certified-operator-index:${OPERATOR_VER} \ docker-archive:certified-operator-index.tar.gz

# 下载 community-operators 的 CatalogSource 镜像 
skopeo copy \
--authfile ${PULL_SECRET_FILE} \
docker://registry.redhat.io/redhat/community-operator-index:${OPERATOR_VER} \ docker-archive:community-operator-index.tar.gz

# 9.3 OperatorHub 应用镜像包批量下载(可选)
# 如果使用后续“高级配置”篇中的代理网络方案的话，本章节内容无需执行
# 9.3.1 获取 OperatorHub CatalogSource 镜像列表
# 我们需要将每个频道中所包含的镜像列表导出，以便于我们进行批量下载这些应用该镜像
mkdir -p /data/ocp-operator/operator/${OPERATOR_VER}-${DATE}/manifest
export MANIFEST_DIR=/data/ocp-operator/operator/${OPERATOR_VER}-${DATE}/manifest
export REGISTRY_DOMAIN=registry.example.com:5000
cd /data/ocp-operator/operator/${OPERATOR_VER}-${DATE}/manifest

# 导出 redhat-operators 中的镜像列表
oc adm catalog mirror \
  registry.redhat.io/redhat/redhat-operator-index:${OPERATOR_VER} \
  ${REGISTRY_DOMAIN} \
  -a ${PULL_SECRET_FILE} \
  --filter-by-os="linux/amd64" \
  --manifests-only

# 导出 certified-operators 中的镜像列表
oc adm catalog mirror \
  registry.redhat.io/redhat/certified-operator-index:${OPERATOR_VER} \
  ${REGISTRY_DOMAIN} \
  -a ${PULL_SECRET_FILE} \
  --filter-by-os="linux/amd64" \
  --manifests-only

# 导出 community-operators 中的镜像列表
oc adm catalog mirror \
  registry.redhat.io/redhat/community-operator-index:latest \
  ${REGISTRY_DOMAIN} \
  -a ${PULL_SECRET_FILE} \
  --filter-by-os="linux/amd64" \
  --manifests-only
     
# 检查并统计每个频道的镜像数量
for APPREGISTRY_ORG in redhat-operator community-operator certified-operator; do
  echo ${APPREGISTRY_ORG} && cat ${MANIFEST_DIR}/manifests-${APPREGISTRY_ORG}-index-*/mapping.txt |wc -l;
done

# Operator镜像tag信息联机修订说明
# mapping.txt文件中，存在以下几个方面问题
# 以sha256为标识的镜像，其目标镜像路径缺少tag标记，这不符合常规的镜像库管理要求（部分镜像库程序可能会拒绝此类镜像），这部分，我们会通过oc image info获取真实的tag标记并进行补全，并添加到名为mapping-tag.txt的文件中
# 上述镜像中，可能会存在如下几种情况：
# 有少量镜像的sha256不同，但镜像tag确是相同的，使用oc image info查看，实际是architecture的不同，比如一个是amd64，一个是s390，这种镜像很少，但我们需要给它标记
# 有少量上述镜像通过oc image info无法获取真实的tag标记，这些镜像有两种情况：
# 一种是镜像存在，但没有tag标记，则使用latest作为标记进行补全
# 还有一种可能实际在镜像库上并不存在（或因各种原因已被删除）
# 少数镜像是shema version1的镜像，比如etcd operator，这种镜像暂时无法使用oc image mirror和skopeo命令下载到本地文件，因为sha256会变化（直接mirror到镜像库则不会有此问题），该bug目前还和研发沟通中

# 9.3.3 Operator镜像下载第一步：镜像列表联机修订
setVAR SECRET_REG_REDHAT /data/OCP-4.6.52/ocp/secret/redhat-pull-secret.json

_Command () {
  echo "Verifying the images"
cd ${MANIFEST_DIR}/manifests-${APPREGISTRY_ORG}-index-*/
SOURCEFILE=mapping.txt
TARGETFILE=newmapping.txt
NOFOUNDFILE=nofound.txt
VERIFIED=verified.txt
SCHEMAV1=schemav1.txt
SCHEMAV2=schemav2.txt
NOORGTAG=noorgtag.txt
EXSITED=exsited.txt
 
echo -n "" > ${TARGETFILE}
echo -n "" > ${NOFOUNDFILE}
echo -n "" > ${VERIFIED}
echo -n "" > ${SCHEMAV1}
echo -n "" > ${SCHEMAV2}
echo -n "" > ${NOORGTAG}
echo -n "" > ${EXSITED}
 
cat ${SOURCEFILE} | sort | uniq | while read line;
do
  sourceimage=${line%=*};
  echo "----------------------------------------------"
  echo -e "\033[32m starting verify image: ${sourceimage} \033[0m"
# 左侧没有tag
  if [[ !  ${sourceimage} =~ ":" ]]; then
    echo ${line} >> ${NOORGTAG};
    sourceimage=${sourceimage}:latest
  if [[ ! ${line##*/} =~ ":" ]]; then
     line=${sourceimage}=${line#*=}
  fi
  fi
# 左侧有tag，右侧也有tag
  if [[ ${line##*/} =~ ":" ]]; then
    echo -e "\033[32m tag already exist \033[0m"
    strtag=`oc image info -a ${SECRET_REG_REDHAT} ${sourceimage} --filter-by-os=linux/amd64 -o json | jq -r '.config | .config.Labels.version+"-"+.config.Labels.release+"_"+.os+"-"+.architecture'`;
   # 查不到镜像
   if [ ! $strtag ]; then
     echo $line >> ${NOFOUNDFILE};
     echo -e "\033[31m can not find image! \033[0m"
   else
     echo ${line} >> ${EXSITED};
     echo ${line} >> ${TARGETFILE};
     echo -e "\033[36m this image have been verified \033[0m"
   fi
# 左侧有tag，右侧没有tag
  else
    strtag=`oc image info -a ${SECRET_REG_REDHAT} ${sourceimage} --filter-by-os=linux/amd64 -o json | jq -r '.config | .config.Labels.version+"-"+.config.Labels.release+"_"+.os+"-"+.architecture'`;
    # 查不到镜像
    if [ ! $strtag ]; then
      echo ${line%=*}
      echo -e "\033[31m can not find image! \033[0m"
      echo ${line} >> ${NOFOUNDFILE};
    # 缺少version和release的镜像，此类镜像要区分manifest schema版本
    else if [ ! ${strtag%%-*} ]; then
      echo -e "\033[33m lack version & release! \033[0m"
      echo -e "\033[33m Inspect image schema version \033[0m"
      schemaVersion=$(skopeo inspect --raw --authfile ${SECRET_REG_REDHAT} docker://${sourceimage} |jq -r .schemaVersion)
    # 发现为manifest schema v1的版本，则放到SCHEMAV1文件中
         if [ ${schemaVersion} = "1" ]; then
           echo -e "\033[31m This image manifest is schema v1! \033[0m"
           echo ${line} >> ${SCHEMAV1}
         # 发现为manifest schema v2的版本，则原样放到TARGETFILE文件中
         else if [ ${schemaVersion} = "2" ]; then
           echo -e "\033[36m This image manifest is schema v2 and without tag! \033[0m"
           echo The verified target url is: ${line#*=}
           echo ${line} >> ${SCHEMAV2}
           echo ${line} >> ${TARGETFILE};
              fi
         fi
    else
      echo -e "\033[36m this image tag have been found and added\033[0m"
      echo The original target url is: ${line#*=}
      echo The verified target url is: ${line#*=}:${strtag}
      echo ${line}:${strtag} >> ${TARGETFILE};
         fi
    fi
  fi
done
}
 
PS3='Please enter the channel: '
options=("redhat-operator" "community-operator" "certified-operator")
 
select opt in "${options[@]}"
do
  APPREGISTRY_ORG="${opt}"
    _Command
  break
done


### 安装过程报错记录
### 以下这个报错是因为手工生成的 chrony machine config 文件指定的 spec version 是 3.2
### OCP 4.6 的 machine config controller 支持的 spec version 是 2.2, 3.0, 3.1
# 报错
Dec 21 05:48:26 bootstrap.ocp4-1.example.com bootkube.sh[2319]: "99_masters-chrony-configuration.yaml": unable to get REST mapping for "99_masters-chrony-configuration.yaml": no matches for kind "MachineConfig" in version "machineconfiguration.openshift.io/v1"

Dec 21 06:16:11 bootstrap.ocp4-1.example.com hyperkube[2245]: E1221 06:16:11.287099    2245 pod_workers.go:191] Error syncing pod e2d3b3f34d40434ecdfba6a18d83a1ff ("bootstrap-machine-config-operator-bootstrap.ocp4-1.example.com_default(e2d3b3f34d40434ecdfba6a18d83a1ff)"), skipping: failed to "StartContainer" for "machine-config-controller" with CrashLoopBackOff: "back-off 2m40s restarting failed container=machine-config-controller pod=bootstrap-machine-config-operator-bootstrap.ocp4-1.example.com_default(e2d3b3f34d40434ecdfba6a18d83a1ff)"

# 报错 
# https://gist.github.com/therevoman/f5818a20fd56edd573fa853c6e2ee877
# 找到 spec version 不正确的配置文件
[core@bootstrap ~]$ sudo crictl logs b94ce7e23a70b 
I1221 06:18:23.751217       1 bootstrap.go:40] Version: v4.6.0-202111301700.p0.gc0b5ea5.assembly.stream-dirty (c0b5ea57cf1be9fb30092472809bbb9378614c2e)
I1221 06:18:23.832930       1 bootstrap.go:116] skipping "/etc/mcc/bootstrap/cluster-dns-02-config.yml" [1] manifest because of unhandled *v1.DNS
I1221 06:18:23.835966       1 bootstrap.go:116] skipping "/etc/mcc/bootstrap/cluster-infrastructure-02-config.yml" [1] manifest because of unhandled *v1.Infrastructure
I1221 06:18:23.851468       1 bootstrap.go:116] skipping "/etc/mcc/bootstrap/cluster-ingress-02-config.yml" [1] manifest because of unhandled *v1.Ingress
I1221 06:18:23.853400       1 bootstrap.go:116] skipping "/etc/mcc/bootstrap/cluster-network-02-config.yml" [1] manifest because of unhandled *v1.Network
I1221 06:18:23.854607       1 bootstrap.go:116] skipping "/etc/mcc/bootstrap/cluster-proxy-01-config.yaml" [1] manifest because of unhandled *v1.Proxy
I1221 06:18:23.856291       1 bootstrap.go:116] skipping "/etc/mcc/bootstrap/cluster-scheduler-02-config.yml" [1] manifest because of unhandled *v1.Scheduler
I1221 06:18:23.866055       1 bootstrap.go:116] skipping "/etc/mcc/bootstrap/cvo-overrides.yaml" [1] manifest because of unhandled *v1.ClusterVersion
F1221 06:18:24.239767       1 bootstrap.go:47] error running MCC[BOOTSTRAP]: parsing Ignition config failed: unknown version. Supported spec versions: 2.2, 3.0, 3.1

```