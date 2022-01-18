### 测试 Assisted Installer 
参考文档：<br>
https://cloud.redhat.com/blog/assisted-installer-on-premise-deep-dive<br>
https://cloud.redhat.com/blog/making-openshift-on-bare-metal-easy<br>
https://github.com/openshift/assisted-service/blob/902a54d507dc4661d0ca2977114dc8500f52ee05/docs/user-guide/restful-api-guide.md<br>
```
# Assisted Installer On-Premise Deep Dive

# 1. 安装 Assisted Install 服务
# 这个部分按照安装 openshift upi support 服务器来安装一台服务器
# hostname: ocpai.exmaple.com
# ip: 192.168.122.14/24
# gateway: 192.168.122.1
# nameserver: 192.168.122.12
# 生成 ks.cfg - ocp-ai
cat > /tmp/ks-ocp-ai.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=ens3 --hostname=ocpai.example.com --bootproto=static --ip=192.168.122.14 --netmask=255.255.255.0 --gateway=192.168.122.1 --nameserver=192.168.122.12
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
openssl-perl
%end
EOF

# 创建 jwang-ocp-ai 虚拟机，安装操作系统
virt-install --debug --name=jwang-ocp-ai --vcpus=4 --ram=32768 --disk path=/data/kvm/jwang-ocp-ai.qcow2,bus=virtio,size=100 --os-variant rhel8.0 --network network=default,model=virtio --boot menu=on --location /root/jwang/isos/rhel-8.4-x86_64-dvd.iso --initrd-inject /tmp/ks-ocp-ai.cfg --extra-args='ks=file:/ks-ocp-ai.cfg'

# 挂载 iso
mount /dev/sr0 /mnt

# 生成本地 yum 源
cat > /etc/yum.repos.d/local.repo << EOF
[baseos]
name=baseos
baseurl=file:///mnt/BaseOS
enabled=1
gpgcheck=0

[appstream]
name=appstream
baseurl=file:///mnt/AppStream
enabled=1
gpgcheck=0
EOF

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
setenforce 0

dnf install -y @container-tools
dnf groupinstall -y "Development Tools"
dnf install -y python3-pip socat make tmux git jq crun

# 设置代理（可选）
# 如果 git clone 有问题，可以考虑设置代理
PROXY_URL="10.0.10.10:3128/"

export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export ftp_proxy="$PROXY_URL"
export no_proxy="127.0.0.1,192.168.122.14,localhost,.rhsacn.org,.gcr.io,quay.io,registry.access.redhat.com,access.redhat.com,.openshift.com,.example.com"

# For curl
export HTTP_PROXY="$PROXY_URL"
export HTTPS_PROXY="$PROXY_URL"
export FTP_PROXY="$PROXY_URL"
export NO_PROXY="127.0.0.1,192.168.122.14,localhost,.rhsacn.org,.gcr.io,quay.io,registry.access.redhat.com,access.redhat.com,.openshift.com,.example.com"

git clone https://github.com/openshift/assisted-service
cd assisted-service
IP=192.168.122.12
AI_URL=http://$IP:8090
AI_IMAGE_URL=http://$IP:8888

# 修改 onprem-environment 和 Makefile，设置 URL 和 port forwarding
sed -i "s@^SERVICE_BASE_URL=.*@SERVICE_BASE_URL=$AI_URL@" onprem-environment
sed -i "s@^IMAGE_SERVICE_BASE_URL=.*@IMAGE_SERVICE_BASE_URL=$AI_IMAGE_URL@" onprem-environment
# 下面这条命令新仓库里已经不用之行 2022/01/04 
# sed -i "s/5432,8000,8090,8080/5432:5432 -p 8000:8000 -p 8090:8090 -p 8080:8080/" Makefile
make deploy-onprem
# 具体执行了哪些命令，可以参考这个 make target

export CLUSTER_SSHKEY=$(cat ~/.ssh/id_rsa.pub)
export PULL_SECRET=$(cat pull-secret.txt | jq -R .)
export REGISTRY_DOMAIN="registry.example.com:5000"
export REGISTRY_REPO="ocp4/openshift4"
cat << EOF > ./deployment-singlenodes.json
{
  "kind": "Cluster",
  "name": "ocp4-1",  
  "openshift_version": "4.9",
  "ocp_release_image": "registry.example.com:5000/ocp4/openshift4:4.9.9-x86_64",
  "base_dns_domain": "example.com",
  "hyperthreading": "all",
  "schedulable_masters": true,
  "high_availability_mode": "None",
  "user_managed_networking": true,
  "platform": {
    "type": "baremetal"
   },
  "cluster_networks": [
    {
      "cidr": "10.128.0.0/14",
      "host_prefix": 23
    }
  ],
  "service_networks": [
    {
      "cidr": "172.31.0.0/16"
    }
  ],
  "machine_networks": [
    {
      "cidr": "192.168.122.0/24"
    }
  ],
  "network_type": "OVNKubernetes",
  "additional_ntp_source": "ntp.example.com",
  "vip_dhcp_allocation": false,      
  "ssh_public_key": "$CLUSTER_SSHKEY",
  "pull_secret": $PULL_SECRET,
  "imageContentSources":  
- mirrors:
  - ${REGISTRY_DOMAIN}/${REGISTRY_REPO}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${REGISTRY_DOMAIN}/${REGISTRY_REPO}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
}
EOF

# 用 deployment-singlenodes.json 注册 cluster
AI_URL='http://192.168.122.14:8090'
curl -s -X POST "$AI_URL/api/assisted-install/v1/clusters" \
   -d @./deployment-singlenodes.json --header "Content-Type: application/json" | jq .


# 获取已注册的 cluster id
CLUSTER_ID=$(curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" -H "accept: application/json" -H "get_unregistered_clusters: false"| jq -r '.[].id')
echo $CLUSTER_ID

# 检查 cluster 状态
curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" -H "accept: application/json" -H "get_unregistered_clusters: false"| jq -r '.[].status'

# 获取 discovered hosts 发现状态
curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" \
 -H "accept: application/json" \
 -H "get_unregistered_clusters: false"| jq -r '.[].progress'

# 查看已 discovered hosts 信息
curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" \
-H "accept: application/json" \
-H "get_unregistered_clusters: false"| jq -r '.[].hosts'

# 获取 validations_info
curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" -H "accept: application/json" \
-H "get_unregistered_clusters: false"| jq -r '.[].validations_info'|jq .

# 获取 hosts inventory 信息
curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" -H "accept: application/json" \
-H "get_unregistered_clusters: false"| jq -r '.[].hosts[].inventory'|jq -r .

# 获取 host id
curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" \
-H "accept: application/json" -H "get_unregistered_clusters: false"| jq -r '.[].hosts[].id'

# 获取 host role
curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" -H "accept:    application/json" -H "get_unregistered_clusters: false"| jq -r '.[].hosts[].role'

# 可选，如果希望改变 host role 为 master，可执行以下命令
 for i in `curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true"\
   -H "accept: application/json" -H "get_unregistered_clusters: false"| jq -r '.[].hosts[].id'| awk 'NR>0' |awk '{print $1;}'`
 do curl -X PATCH "$AI_URL/api/assisted-install/v1/clusters/$CLUSTER_ID" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"hosts_roles\": [ { \"id\": \"$i\", \"role\": \"master\" } ]}"
 done

# 查看 
curl -s -X GET "$AI_URL/api/assisted-install/v1/clusters/$CLUSTER_ID/manifests/files"

# 设置 
export AIA_IMG_PATH=${OCP_PATH}/app-image/thirdparty/assisted-installer-agent
mkdir -p $AIA_IMG_PATH
skopeo copy docker://quay.io/ocpmetal/assisted-installer-agent:latest docker-archive:${AIA_IMG_PATH}/assisted-installer-agent-latest.tar.gz

[[registry]]
   prefix = ""
   location = "quay.io/ocpmetal"
   mirror-by-digest-only = false
   [[registry.mirror]]
   location = "registry.example.com:5000/ocpmetal"

# 安装 aicli
git clone https://github.com/karmab/assisted-installer-cli 
cd assisted-installer-cli
pip3 install aicli

# 查询 cluster
# aicli -U $AI_URL list cluster   
+---------+--------------------------------------+--------+-------------+
| Cluster |                  Id                  | Status |  Dns Domain |
+---------+--------------------------------------+--------+-------------+
|  ocp-1  | b769070b-e387-4f42-8bc0-14b649a1a5fe | ready  | example.com |
+---------+--------------------------------------+--------+-------------+

# aicli -U $AI_URL info cluster ocp4-1

# 生成 static_network_config
cat > static_network_config.yml <<EOF
static_network_config:
- interfaces:
    - name: ens3
      type: ethernet
      state: up
      ethernet:
        auto-negotiation: true
        duplex: full
        speed: 10000
      ipv4:
        address:
        - ip: 192.168.122.201
          prefix-length: 24
        enabled: true
      mtu: 1500
      mac-address: 52:54:00:1c:14:57
  dns-resolver:
    config:
      server:
      - 192.168.122.12
  routes:
    config:
    - destination: 192.168.122.0/24
      next-hop-address: 192.168.122.1
      next-hop-interface: ens3
    - destination: 0.0.0.0/0
      next-hop-address: 192.168.122.1
      next-hop-interface: ens3
      table-id: 254
EOF

# 拷贝 pull-secret 到 my_pull_secret.json

# 生成 aicli_parameters.yml
cat > aicli_parameters.yml <<EOF
base_dns_domain: example.com
openshift_version: 4.9
sno: true
additional_ntp_source: ntp.example.com
$(cat static_network_config.yml)
pull_secret: my_pull_secret.json
ssh_public_key: '$(cat /root/.ssh/id_rsa.pub)'
disconnected_url: registry.example.com:5000
machine_network_cidr: "192.168.122.0/24"
cluster_network_cidr: "10.128.0.0/14"
cluster_network_host_prefix: 23
service_network_cidr: "172.30.0.0/16"
network_type: OpenShiftSDN
installconfig:
  additionalTrustBundle: |
$(cat /etc/pki/ca-trust/source/anchors/registry.crt | sed 's|^|    |')
  imageContentSources:
  - mirrors:
    - registry.example.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - registry.example.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - registry.example.com:5000/ocpmetal/assisted-installer
    source: quay.io/ocpmetal/assisted-installer
  - mirrors:
    - registry.example.com:5000/ocpmetal/assisted-installer-agent
    source: quay.io/ocpmetal/assisted-installer-agent
EOF

# 创建 cluster
aicli -U $AI_URL create cluster ocp4-1

# 查看 infraenv
[root@ocpai assisted-installer-cli]# aicli -U $AI_URL list infraenvs
Using http://192.168.122.14:8090 as base url
+------------------+--------------------------------------+---------+-------------------+----------+
|     Infraenv     |                  Id                  | Cluster | Openshift Version | Iso Type |
+------------------+--------------------------------------+---------+-------------------+----------+
| ocp4-1_infra-env | 2097fca5-3f66-4ea8-b85a-98c24c5180ca |  ocp4-1 |        4.9        | full-iso |
+------------------+--------------------------------------+---------+-------------------+----------+

# 在 discovery ISO 里添加 trustbundle
# The additional trust bundle must be embeded into discovery ignition override
# https://github.com/openshift/assisted-service/blob/master/docs/user-guide/install-customization.md#add-additionaltrustbundle-in-install-config

INFRA_ENV_ID=$(aicli -U $AI_URL list infraenvs | grep ocp4-1 | awk '{print $4}')

# 生成 registries.conf 文件
cat > /tmp/registries.conf <<EOF
unqualified-search-registries = ["registry.access.redhat.com", "docker.io"]
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-release"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer-agent"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer-agent"
EOF

request_body=$(mktemp)
jq -n --arg OVERRIDE "{\"ignition\": {\"version\": \"3.1.0\"}, \"storage\": {\"files\": [{\"path\": \"/etc/containers/registries.conf\", \"mode\": 420, \"overwrite\": true, \"user\": { \"name\": \"root\"},\"contents\": {\"source\": \"data:text/plain;base64,$(cat /tmp/registries.conf | base64 -w 0)\"}},{\"path\": \"/etc/pki/ca-trust/source/anchors/registry.crt\", \"mode\": 420, \"overwrite\": true, \"user\": { \"name\": \"root\"},\"contents\": {\"source\": \"data:text/plain;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w 0)\"}}]}}" \
'{
   "ignition_config_override": $OVERRIDE
}' > $request_body

curl \
    --header "Content-Type: application/json" \
    --request PATCH \
    --data  @$request_body \
"$AI_URL/api/assisted-install/v2/infra-envs/$INFRA_ENV_ID"

# Add additionalTrustbundle in install-config
install_config_patch=$(mktemp)
jq -n --arg BUNDLE "$(cat /etc/pki/ca-trust/source/anchors/registry.crt)" \
'{
    "additionalTrustBundle": $BUNDLE
}| tojson' > $install_config_patch

CLUSTER_ID=$( aicli -U $AI_URL list cluster | grep ocp4-1 | awk '{print $4}' )
curl \
    --header "Content-Type: application/json" \
    --request PATCH \
    --data  @$install_config_patch \
"$AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/install-config"

# 设置 machine_network_cidr
# aicli_parameters.yml 里的 machine_network_cidr 不知道为什么没设置上
curl \
    --header "Content-Type: application/json" \
    --request PATCH \
    --data  "{ \"machine_network_cidr\": \"192.168.122.0/24\"}" \
"$AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID"

# 获取 iso
aicli -U $AI_URL create iso ocp4-1
Using http://192.168.122.14:8090 as base url
This api call is deprecated
Getting Iso url for infraenv ocp4-1
Using default parameter file aicli_parameters.yml
http://192.168.122.14:8888/images/442a3cab-f104-4088-9349-57f14748fee3?arch=x86_64&type=full-iso&version=4.9

# 下载 iso
DISCOVERY_ISO=$(aicli -U $AI_URL info iso ocp4-1 | grep images)
echo curl -L "'"${DISCOVERY_ISO}"'" -o /tmp/sno-ocp4-1.iso

# 更新 assisted-service container 的 ca-trust 
ASSISTED_SERVICE_CONTAINER_ID=$( podman ps | grep assisted-service | awk '{print $1}' )
podman cp /etc/pki/ca-trust/source/anchors/registry.crt ${ASSISTED_SERVICE_CONTAINER_ID}:/etc/pki/ca-trust/source/anchors
podman exec -it  ${ASSISTED_SERVICE_CONTAINER_ID} sh
sh-4.4# update-ca-trust

# 在安装过程中，检查 SNO 节点的 /etc/containers/registries.conf 文件
# 如果内容不正确则重新生成这个文件，并重启 crio 服务
cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', 'docker.io']
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-release"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"
EOF
chmod a+r /etc/containers/registries.conf
systemctl restart crio.service
```

```
# 为接口添加 ip 地址
nmcli con mod 'System eth0' +ipv4.address "192.168.122.22/24"

# 更新 /var/named/ocp4-2.example.com.zone 文件
cat > /var/named/ocp4-2.example.com.zone <<'EOF'
$ORIGIN ocp4-2.example.com.
$TTL 1D
@           IN SOA  ocp4-2.example.com. admin.ocp4-2.example.com. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum

@             IN NS                         dns.example.com.

lb             IN A                          192.168.122.22

api            IN A                          192.168.122.22
api-int        IN A                          192.168.122.22
*.apps         IN A                          192.168.122.22

bootstrap      IN A                          192.168.122.202

master-0       IN A                          192.168.122.202

etcd-0         IN A                          192.168.122.202

_etcd-server-ssl._tcp.ocp4-2.example.com. 8640 IN SRV 0 10 2380 etcd-0.ocp4-2.example.com.
EOF

# 更新 168.192.in-addr.arpa.zone 文件
cat > /var/named/168.192.in-addr.arpa.zone <<'EOF'
$TTL 1D
@           IN SOA  example.com. admin.example.com. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
                                        
@                              IN NS       dns.example.com.

13.122.168.192.in-addr.arpa.     IN PTR      bastion.example.com.

12.122.168.192.in-addr.arpa.     IN PTR      support.example.com.
12.122.168.192.in-addr.arpa.     IN PTR      dns.example.com.
12.122.168.192.in-addr.arpa.     IN PTR      ntp.example.com.
12.122.168.192.in-addr.arpa.     IN PTR      yum.example.com.
12.122.168.192.in-addr.arpa.     IN PTR      registry.example.com.
12.122.168.192.in-addr.arpa.     IN PTR      nfs.example.com.
12.122.168.192.in-addr.arpa.     IN PTR      lb.ocp4-1.example.com.
12.122.168.192.in-addr.arpa.     IN PTR      api.ocp4-1.example.com.
12.122.168.192.in-addr.arpa.     IN PTR      api-int.ocp4-1.example.com.
22.122.168.192.in-addr.arpa.     IN PTR      lb.ocp4-2.example.com.
22.122.168.192.in-addr.arpa.     IN PTR      api.ocp4-2.example.com.
22.122.168.192.in-addr.arpa.     IN PTR      api-int.ocp4-2.example.com.

201.122.168.192.in-addr.arpa.    IN PTR      bootstrap.ocp4-1.example.com.

201.122.168.192.in-addr.arpa.    IN PTR      master-0.ocp4-1.example.com.

202.122.168.192.in-addr.arpa.    IN PTR      bootstrap.ocp4-2.example.com.

202.122.168.192.in-addr.arpa.    IN PTR      master-0.ocp4-2.example.com.
EOF

# 更新 /etc/named.rfc1912.zones 文件
setVAR DOMAIN example.com
setVAR OCP_CLUSTER_ID ocp4-2
cat >> /etc/named.rfc1912.zones << EOF
zone "${OCP_CLUSTER_ID}.${DOMAIN}" IN {
        type master;
        file "${OCP_CLUSTER_ID}.${DOMAIN}.zone";
        allow-transfer { any; };
};

EOF

# 重启 dns 服务
systemctl restart named
rndc reload

# 更新 haproxy
cat >> /etc/haproxy/haproxy.cfg <<EOF

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

backend machine-config-server-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     bootstrap bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check

backend ingress-http-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:80 check

backend ingress-https-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:443 check
EOF

###
# 在 Assisted Installer 的客户端上
###
mkdir ocp4-2
cd ocp4-2

# 拷贝 pull-secret 文件到 my_pull_secret.json

# 创建 static_network_config.yml
cat > static_network_config.yml <<EOF
static_network_config:
- interfaces:
    - name: ens3
      type: ethernet
      state: up
      ethernet:
        auto-negotiation: true
        duplex: full
        speed: 10000
      ipv4:
        address:
        - ip: 192.168.122.202
          prefix-length: 24
        enabled: true
      mtu: 1500
      mac-address: 52:54:00:92:b4:e6          # 来自主机的部署网卡 mac 地址
  dns-resolver:
    config:
      server:
      - 192.168.122.12
  routes:
    config:
    - destination: 192.168.122.0/24
      next-hop-address: 192.168.122.1
      next-hop-interface: ens3
    - destination: 0.0.0.0/0
      next-hop-address: 192.168.122.1
      next-hop-interface: ens3
      table-id: 254
EOF

# 生成 
cat > aicli_parameters.yml <<EOF
base_dns_domain: example.com
openshift_version: 4.9
sno: true
additional_ntp_source: ntp.example.com
$(cat static_network_config.yml)
pull_secret: my_pull_secret.json
ssh_public_key: '$(cat /root/.ssh/id_rsa.pub)'
disconnected_url: registry.example.com:5000
machine_network_cidr: "192.168.122.0/24"
cluster_network_cidr: "10.129.0.0/14"
cluster_network_host_prefix: 23
service_network_cidr: "172.31.0.0/16"
network_type: OpenShiftSDN
installconfig:
  additionalTrustBundle: |
$(cat /etc/pki/ca-trust/source/anchors/registry.crt | sed 's|^|    |')
  imageContentSources:
  - mirrors:
    - registry.example.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - registry.example.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-release
EOF

# 创建集群 ocp4-2
aicli -U $AI_URL create cluster ocp4-2

# 查看 infraenv
aicli -U $AI_URL list infraenvs

# 获取 ocp4-2 的 infraenvs id 
INFRA_ENV_ID=$(aicli -U $AI_URL list infraenvs | grep ocp4-2 | awk '{print $4}')

# 生成 registries.conf 文件
cat > /tmp/registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', 'docker.io']
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-release"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer-agent"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer-agent"
EOF

request_body=$(mktemp)
jq -n --arg OVERRIDE "{\"ignition\": {\"version\": \"3.1.0\"}, \"storage\": {\"files\": [{\"path\": \"/etc/containers/registries.conf\", \"mode\": 420, \"overwrite\": true, \"user\": { \"name\": \"root\"},\"contents\": {\"source\": \"data:text/plain;base64,$(cat /tmp/registries.conf | base64 -w 0)\"}},{\"path\": \"/etc/pki/ca-trust/source/anchors/registry.crt\", \"mode\": 420, \"overwrite\": true, \"user\": { \"name\": \"root\"},\"contents\": {\"source\": \"data:text/plain;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w 0)\"}}]}}" \
'{
   "ignition_config_override": $OVERRIDE
}' > $request_body

curl \
    --header "Content-Type: application/json" \
    --request PATCH \
    --data  @$request_body \
"$AI_URL/api/assisted-install/v2/infra-envs/$INFRA_ENV_ID"

# Add additionalTrustbundle in install-config
install_config_patch=$(mktemp)
jq -n --arg BUNDLE "$(cat /etc/pki/ca-trust/source/anchors/registry.crt)" \
'{
    "additionalTrustBundle": $BUNDLE
}| tojson' > $install_config_patch

# 获取 ocp4-2 的 cluster id
CLUSTER_ID=$( aicli -U $AI_URL list cluster | grep ocp4-2 | awk '{print $4}' )
curl \
    --header "Content-Type: application/json" \
    --request PATCH \
    --data  @$install_config_patch \
"$AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/install-config"

# 设置 machine_network_cidr
# aicli_parameters.yml 里的 machine_network_cidr 不知道为什么没设置上
curl \
    --header "Content-Type: application/json" \
    --request PATCH \
    --data  "{ \"machine_network_cidr\": \"192.168.122.0/24\"}" \
"$AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID"

# 创建 iso
aicli -U $AI_URL create iso ocp4-2

# 下载 iso
DISCOVERY_ISO=$(aicli -U $AI_URL info iso ocp4-2 | grep images)
echo curl -L "'"${DISCOVERY_ISO}"'" -o /tmp/sno-ocp4-2.iso

# 在线安装完成
[root@ocpai1 ocp4-2]# oc --kubeconfig=/root/kubeconfig-ocp4-2 --insecure-skip-tls-verify get clusteroperators
```

```
# 按照以下链接里的步骤安装 ACM
# 创建 ManageClusterHub
# https://cloud.redhat.com/blog/telco-5g-zero-touch-provisioning-ztp

oc --kubeconfig=/root/kubeconfig-ocp4-1 project open-cluster-management 

oc --kubeconfig=/root/kubeconfig-ocp4-1 get pods
NAME                                                              READY   STATUS    RESTARTS   AGE
cluster-manager-56bdd694b8-fffwh                                  1/1     Running   0          9m9s
cluster-manager-56bdd694b8-gtvpc                                  1/1     Running   0          9m9s
cluster-manager-56bdd694b8-ms2vg                                  1/1     Running   0          9m9s
hive-operator-7469c75f7b-s4lp5                                    1/1     Running   0          9m8s
multicluster-observability-operator-575f888f8c-9kbst              1/1     Running   0          9m9s
multicluster-operators-application-7b58459868-bndxt               4/4     Running   0          9m8s
multicluster-operators-channel-6796c88d5b-tfb7j                   1/1     Running   0          9m8s
multicluster-operators-hub-subscription-7bcdcb65b4-6bk5m          1/1     Running   0          9m8s
multicluster-operators-standalone-subscription-85c4b566ff-c6z4c   1/1     Running   0          9m8s
multiclusterhub-operator-5b5786bc4-694ff                          1/1     Running   0          9m9s
submariner-addon-5c76dc5668-fpwqm                                 1/1     Running   0          9m8s

oc --kubeconfig=/root/kubeconfig-ocp4-1 get HiveConfig -o yaml 

oc --kubeconfig=/root/kubeconfig-ocp4-1 patch hiveconfig hive --type merge -p '{"spec":{"targetNamespace":"hive","logLevel":"debug","featureGates":{"custom":{"enabled":["AlphaAgentInstallStrategy"]},"featureSet":"Custom"}}}'

touch $HOME/htpasswd
htpasswd -Bb $HOME/htpasswd admin redhat
htpasswd -Bb $HOME/htpasswd user1 redhat

oc --kubeconfig=/root/kubeconfig-ocp4-1 create secret generic htpasswd --from-file=$HOME/htpasswd -n openshift-config

oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: Local Password
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpasswd
EOF

oc --kubeconfig=/root/kubeconfig-ocp4-1 adm policy add-cluster-role-to-user cluster-admin admin
oc login https://api.ocp4-1.example.com:6443 -u admin 

# 创建 SNO Local DIR Storage Class
# 登陆 SNO 节点
# 创建 /srv/openshift/pv-{0..99} 目录
# 设置目录的访问模式 (777) 和 selinux context (svirt_sanbox_file_t)
ssh core@192.168.122.201 "sudo /bin/bash -c 'mkdir -p /srv/openshift/pv-{0..99} ; chmod -R 777 /srv/openshift ; chcon -R -t svirt_sandbox_file_t /srv/openshift'"

# 创建 PV 
for i in {0..99}; do
  oc --kubeconfig=/root/kubeconfig-ocp4-1 create -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-$i
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 40Gi
  accessModes:
  - ReadWriteOnce
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  hostPath:
    path: "/srv/openshift/pv-$i"
EOF
done

# 创建 StorageClass
oc --kubeconfig=/root/kubeconfig-ocp4-1 create -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: manual
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF

# 创建 ClusterImageSet
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: openshift-v4.9.9
  namespace: open-cluster-management
spec:
  releaseImage: registry.example.com:5000/ocp4/openshift4:4.9.9-x86_64
EOF

# 创建 AssistedServiceConfig
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: assisted-service-config
  namespace: open-cluster-management
  labels:
    app: assisted-service
data:
  CONTROLLER_IMAGE: quay.io/ocpmetal/assisted-installer-controller@sha256:93f193d97556711dce20b2f11f9e2793ae26eb25ad34a23b93d74484bc497ecc
  LOG_LEVEL: "debug"
EOF

# 创建 AgentServiceConfig
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: agent-install.openshift.io/v1beta1
kind: AgentServiceConfig
metadata:
  name: agent
  namespace: open-cluster-management
  ### This is the annotation that injects modifications in the Assisted Service pod
  annotations:
    unsupported.agent-install.openshift.io/assisted-service-configmap: "assisted-service-config"
###
spec:
  databaseStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 40Gi
  filesystemStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 40Gi
  ###
  osImages:
    - openshiftVersion: "4.9"
      version: ""
      url: "http://192.168.122.15/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/rhcos-4.9.0-x86_64-live.x86_64.iso"
      rootFSUrl: "http://192.168.122.15/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/rhcos-live-rootfs.x86_64.img"
EOF

# Private Key
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-ssh-private-key
  namespace: open-cluster-management
stringData:
  ssh-privatekey: |-
$( cat /root/.ssh/id_rsa | sed -e 's/^/    /g' )
type: Opaque
EOF

# Pull Secret
PULL_SECRET_FILE=/root/assisted-installer-cli/pull-secret.txt
PULL_SECRET_STR=$( cat ${PULL_SECRET_FILE}|jq -c . )
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-pull-secret
  namespace: open-cluster-management
stringData: 
  .dockerconfigjson: '${PULL_SECRET_STR}'
EOF

# 被管理集群设置
# SNO Cluster Definition
SSH_PUBLIC_KEY_STR=$( cat /root/.ssh/id_rsa.pub )
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: extensions.hive.openshift.io/v1beta1
kind: AgentClusterInstall
metadata:
  name: ocp4-2
  namespace: open-cluster-management
spec:
  clusterDeploymentRef:
    name: ocp4-2
  imageSetRef:
    name: openshift-v4.9.9
  networking:
    clusterNetwork:
      - cidr: "10.129.0.0/14"
        hostPrefix: 23
    serviceNetwork:
      - "172.31.0.0/16"
    machineNetwork:
      - cidr: "192.168.122.0/24"
  provisionRequirements:
    controlPlaneAgents: 1
  sshPublicKey: '${SSH_PUBLIC_KEY_STR}'
EOF

# ClusterDeployment
# spec.baseDomain 
# spec.clusterName
# spec.clusterInstallRef
# spec.pullSecretRef.name
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: ocp4-2
  namespace: open-cluster-management
spec:
  baseDomain: example.com
  clusterName: ocp4-2
  controlPlaneConfig:
    servingCertificates: {}
  installed: false
  clusterInstallRef:
    group: extensions.hive.openshift.io
    kind: AgentClusterInstall
    name: ocp4-2
    version: v1beta1
  platform:
    agentBareMetal:
      agentSelector:
        matchLabels:
          bla: "aaa"
  pullSecretRef:
    name: assisted-deployment-pull-secret
EOF

# NMState Config
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: assisted-deployment-nmstate-ocp4-2
  labels:
    cluster-name: nmstate-ocp4-2
spec:
  config:
    interfaces:
      - name: ens3
        type: ethernet
        state: up
        ethernet:
          auto-negotiation: true
          duplex: full
          speed: 10000
        ipv4:
          address:
          - ip: 192.168.122.202
            prefix-length: 24
          enabled: true
        mtu: 1500
        mac-address: 52:54:00:92:b4:e6
    dns-resolver:
      config:
        server:
        - 192.168.122.12
    routes:
      config:
      - destination: 192.168.122.0/24
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
        table-id: 254
EOF     

# InfraEnv
# jq -n --arg OVERRIDE "{\"ignition\": {\"version\": \"3.1.0\"}, \"storage\": {\"files\": [{\"path\": \"/etc/containers/registries.conf\", \"mode\": 420, \"overwrite\": true, \"user\": { \"name\": \"root\"},\"contents\": {\"source\": \"data:text/plain;base64,$(cat /tmp/registries.conf | base64 -w 0)\"}},{\"path\": \"/etc/pki/ca-trust/source/anchors/registry.crt\", \"mode\": 420, \"overwrite\": true, \"user\": { \"name\": \"root\"},\"contents\": {\"source\": \"data:text/plain;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w 0)\"}}]}}" 

# 生成 /tmp/registries.conf 文件
cat > /tmp/registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', 'docker.io']
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-release"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer-agent"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer-agent"
EOF

SSH_PUBLIC_KEY_STR=$( cat /root/.ssh/id_rsa.pub )
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: ocp4-2
  namespace: open-cluster-management
spec:
  additionalNTPSources:
    - ntp.example.com  
  clusterRef:
    name: ocp4-2
    namespace: open-cluster-management
  sshAuthorizedKey: '${SSH_PUBLIC_KEY_STR}'
  agentLabelSelector:
    matchLabels:
      bla: "aaa"
  pullSecretRef:
    name: assisted-deployment-pull-secret
  ignitionConfigOverride: '{"ignition": {"version": "3.1.0"}, "storage": {"files": [{"path": "/etc/containers/registries.conf", "mode": 420, "overwrite": true, "user": { "name": "root" }, "contents": {"source": "data:text/plain;base64,$(cat /tmp/registries.conf | base64 -w 0)"}},{"path": "/etc/pki/ca-trust/source/anchors/registry.crt", "mode": 420, "overwrite": true, "user": { "name": "root" }, contents": {"source": "data:text/plain;base64,$(cat /tmp/registries.conf | base64 -w 0)"}}]}}'
  nmStateConfigLabelSelector:
    matchLabels:
      cluster-name: nmstate-ocp4-2
EOF

# SPOKE CLUSTER DEPLOYMENT
oc --kubeconfig=/root/kubeconfig-ocp4-1 get pods -A | grep metal

# Fully Automated ZTP
# 在我的环境里，我没有看到 provisioning-configuration
oc --kubeconfig=/root/kubeconfig-ocp4-1 patch provisioning provisioning-configuration --type merge -p '{"spec":{"watchAllNamespaces": true}}'

# Manual Spoke cluster deployment
# 1. We need to get the ISO URL from the InfraEnv CR with this command:
oc --kubeconfig=/root/kubeconfig-ocp4-1 get infraenv ocp4-2 -o jsonpath={.status.isoDownloadURL}

```

### local registry self signed certs 报错
```
报错
AgentClusterInstall ocp4-2
The Spec could not be synced due to backend error: command oc adm release info -o template --template '{{.metadata.version}}' --insecure=false registry.example.com:5000/ocp4/openshift4:4.9.9-x86_64 exited with non-zero exit code 1:
error: unable to read image registry.example.com:5000/ocp4/openshift4:4.9.9-x86_64: Get "https://registry.example.com:5000/v2/": x509: certificate signed by unknown authority

# 这个报错的解决方法在 https://docs.openshift.com/container-platform/4.2/openshift_images/image-configuration.html#images-configuration-insecure_image-configuration 
```