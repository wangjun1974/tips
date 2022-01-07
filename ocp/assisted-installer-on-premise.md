### 测试 Assisted Installer 
参考文档：<br>
https://cloud.redhat.com/blog/assisted-installer-on-premise-deep-dive<br>
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
EOF
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
ocp_release_image: registry.example.com:5000/ocp4/openshift4:4.9.9-x86_64
sno: true
additional_ntp_source: ntp.example.com
$(cat static_network_config.yml)
pull_secret: my_pull_secret.json
ssh_public_key: '$(cat /root/.ssh/id_rsa.pub)'
disconnected_url: registry.example.com:5000
installconfig:
  additionalTrustBundle: |
$(cat /etc/pki/ca-trust/source/anchors/registry.crt | sed 's|^|    |')
  imageContentSources:
  - mirrors:
    - registry.example.com:5000/ocp4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - registry.example.com:5000/ocp4
    source: registry.ci.openshift.org/ocp-release
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
request_body=$(mktemp)
jq -n --arg OVERRIDE "{\"ignition\": {\"version\": \"3.1.0\"}, \"storage\": {\"files\": [{\"path\": \"/etc/pki/ca-trust/source/anchors/registry.crt\", \"mode\": 420, \"overwrite\": true, \"user\": { \"name\": \"root\"},\"contents\": {\"source\": \"data:text/plain;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w 0)\"}}]}}" \
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


```