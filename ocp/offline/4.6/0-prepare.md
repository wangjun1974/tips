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


```