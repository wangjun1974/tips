### 测试 Assisted Installer 
参考文档：<br>
https://cloud.redhat.com/blog/assisted-installer-on-premise-deep-dive<br>
https://cloud.redhat.com/blog/making-openshift-on-bare-metal-easy<br>
https://github.com/openshift/assisted-service/blob/902a54d507dc4661d0ca2977114dc8500f52ee05/docs/user-guide/restful-api-guide.md<br>
https://michaelkotelnikov.medium.com/deploying-single-node-bare-metal-openshift-using-advanced-cluster-management-9ec27b6663bf<br>
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
  - mirrors:
    - registry.example.com:5000/rhacm2
    source: registry.redhat.io/rhacm2
  - mirrors:
    - registry.example.com:5000/openshift-gitops-1
    source: registry.redhat.io/openshift-gitops-1
  - mirrors:
    - registry.example.com:5000/openshift4
    source: openshift4
  - mirrors:
    - registry.example.com:5000/redhat
    source: registry.redhat.io/redhat
  - mirrors:
    - registry.example.com:5000/rhel8
    source: registry.redhat.io/rhel8
  - mirrors:
    - registry.example.com:5000/rh-sso-7
    source: registry.redhat.io/rh-sso-7
EOF

# 创建 cluster
tar zxvf aicli.tar.gz -C /
yum install -y python3-pyyaml
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

# 生成 registries.conf 文件，ignition 时添加 registry.crt 和 registries.conf  
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

# 这个步骤应该不需要执行，因为 install-config 里已经有 additionalTrustbundle 部分了
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
# 如果内容不正确则重新生成这个文件
# 需重启 crio 服务，需重启 2 次，一次是 bootkube 阶段，一次是写入磁盘重启之后
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

# bootkube 完成重启后
# 拷贝 registry.crt 到 master-0 
# 不清楚为什么 ignition 时没有将 registry.crt 和 registries.conf 文件写入到磁盘内
scp /etc/pki/ca-trust/source/anchors/registry.crt core@192.168.122.201:/tmp
ssh core@192.168.122.201 sudo cp /tmp/registry.crt /etc/pki/ca-trust/source/anchors
ssh core@192.168.122.201 sudo update-ca-trust

# 最后在安装完之后，需要修改 /etc/container/registries.conf 文件为
# 如果不修改回去，mcp 状态会不正常
cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', 'docker.io']
EOF

# 在安装完成后，禁用 insight operator
# https://docs.openshift.com/container-platform/4.5/support/remote_health_monitoring/opting-out-of-remote-health-reporting.html

oc extract secret/pull-secret -n openshift-config --to=.
# 编辑 .dockerconfigjson 文件
# 移除 cloud.openshift.com JSON 片段
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=./.dockerconfigjson 

# Assisted Installer 显示
# Cluster has hosts pending user action

生成 registries.conf 文件
cat > registries.conf <<EOF
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

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer-controller"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer-controller"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/acm-operator-bundle"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/acm-operator-bundle"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/registration-rhel8-operator"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/registration-rhel8-operator"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/openshift-hive-rhel8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/openshift-hive-rhel8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/multicluster-observability-rhel8-operator"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/multicluster-observability-rhel8-operator"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/multicluster-operators-placementrule-rhel8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/multicluster-operators-placementrule-rhel8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/multicluster-operators-channel-rhel8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/multicluster-operators-channel-rhel8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/multicluster-operators-subscription-rhel8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/multicluster-operators-subscription-rhel8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/multiclusterhub-rhel8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/multiclusterhub-rhel8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/submariner-addon-rhel8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/submariner-addon-rhel8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/multicloud-integrations-rhel8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/multicloud-integrations-rhel8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/multicluster-operators-deployable-rhel8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/multicluster-operators-deployable-rhel8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2/multicluster-operators-application-rhel8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2/multicluster-operators-application-rhel8"
EOF

config_source=$(cat ./registries.conf | base64 -w 0 )

# machine config 例子
cat << EOF > ./99-master-zzz-registries-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: masters-registries-configuration
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
          source: data:text/plain;charset=utf-8;base64,${config_source}
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf
  osImageURL: ""
EOF

oc apply -f ./99-master-zzz-registries-configuration.yaml

LOCAL_SECRET_JSON=/data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json
source=quay.io/ocpmetal/assisted-installer-controller:latest
local=registry.example.com:5000/ocpmetal/assisted-installer-controller:latest
podman login -u openshift -p redhat --authfile ${LOCAL_SECRET_JSON} registry.example.com:5000
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://$source docker://$local

# 禁用默认的 catalogsources
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

# 设置本地 CatalogSource
cat <<EOF | oc1 apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operator-index
  namespace: openshift-marketplace
spec:
  image: registry.example.com:5000/redhat/redhat-operator-index:v4.9
  sourceType: grpc
EOF

# 设置 ImageContentSourcePolicy
cat <<EOF | oc1 apply -f -
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: generic-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/operator-framework
    source: operator-framework
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  labels:
    operators.openshift.org/catalog: "true"
  name: operator-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/rhacm2/acm-operator-bundle
    source: registry.redhat.io/rhacm2/acm-operator-bundle
  - mirrors:
    - registry.example.com:5000/openshift-gitops-1
    source: openshift-gitops-1
  - mirrors:
    - registry.example.com:5000/openshift4
    source: openshift4
  - mirrors:
    - registry.example.com:5000/redhat
    source: registry.redhat.io/redhat
  - mirrors:
    - registry.example.com:5000/rhel8
    source: rhel8
  - mirrors:
    - registry.example.com:5000/rh-sso-7
    source: rh-sso-7
EOF

# 设置OAuth
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
# 更新 AssistedServiceConfig 包含 ISO_IMAGE_TYPE 为 full-iso
# https://coreos.slack.com/archives/CUPJTHQ5P/p1618337178015900?thread_ts=1618334807.010700&cid=CUPJTHQ5P
# https://coreos.slack.com/archives/CUPJTHQ5P/p1629814200385700
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: assisted-service-config
  namespace: open-cluster-management
  labels:
    app: assisted-service
data:
  HW_VALIDATOR_REQUIREMENTS: >-
    [{"version":"default","master":{"cpu_cores":4,"ram_mib":16384,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":100,"packet_loss_percentage":0},"worker":{"cpu_cores":2,"ram_mib":8192,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":1000,"packet_loss_percentage":10},"sno":{"cpu_cores":8,"ram_mib":4096,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10}}]
  ISO_IMAGE_TYPE: "full-iso"
  # CONTROLLER_IMAGE: quay.io/ocpmetal/assisted-installer-controller@sha256:93f193d97556711dce20b2f11f9e2793ae26eb25ad34a23b93d74484bc497ecc
  LOG_LEVEL: "debug"
EOF

# 修改 configmap assisted-service-config
# 取消 CONTROLLER_IMAGE 设置
# 重启 deployment assisted-server
oc rollout restart deployment/assisted-service -n open-cluster-management

# 创建 configmap mirror-registry-config-map
cat <<EOF | oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: mirror-registry-config-map
  namespace: "open-cluster-management"
  labels:
    app: assisted-service
data:
  ca-bundle.crt: |
$( cat /etc/pki/ca-trust/source/anchors/registry.crt | sed -e 's|^|    |g' )

  registries.conf: |
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

# 创建 AgentServiceConfig
# 在线
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
EOF

# 离线环境
# https://docs.openshift.com/container-platform-ocp/4.8/scalability_and_performance/cnf-provisioning-and-deploying-a-distributed-unit.html#cnf-installing-the-operators_installing-du
# https://github.com/openshift/assisted-service/blob/master/docs/operator.md
# https://docs.google.com/document/d/1jDrwSyKFssIh-yxJ-wSdB-OCcPvsfm06P54oTk1C6BI/edit
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
  ### disconnected env need default this configmap. it contain ca-bundle.crt and registries.conf
  mirrorRegistryRef:
    name: "mirror-registry-config-map"
  osImages:
    - openshiftVersion: "4.9"
      version: "49.84.202110081407-0"
      url: "http://192.168.122.15/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/rhcos-4.9.0-x86_64-live.x86_64.iso"
      rootFSUrl: "http://192.168.122.15/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/rhcos-live-rootfs.x86_64.img"
      cpuArchitecture: "x86_64"
EOF

# SPOKE 集群定义
# SPOKE CLUSTER DEFINITION
# 创建 Namespace
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ocp4-2
EOF

# NMState Config
# 参考 https://docs.google.com/document/d/1G-1b56huNvAtiSBBxLggvHxbYh7P29-Tz5asXstXZXw/edit#
# interfaces: macAddress
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: ocp4-2
  namespace: ocp4-2
  labels:
    cluster-name: ocp4-2
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
  interfaces:
    - name: ens3
      macAddress: "52:54:00:92:b4:e6"
EOF

# Private Key
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-ssh-private-key
  namespace: ocp4-2
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
  namespace: ocp4-2
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
  namespace: ocp4-2
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
  namespace: ocp4-2
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

# 生成 ignition config yaml
# 转换为 json
# 生成 1 行的 json
# 经验证这个是工作的
SSH_PUBLIC_KEY_STR=$( cat /root/.ssh/id_rsa.pub )
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: ocp4-2
  namespace: ocp4-2
spec:
  additionalNTPSources:
    - ntp.example.com  
  clusterRef:
    name: ocp4-2
    namespace: ocp4-2
  sshAuthorizedKey: '${SSH_PUBLIC_KEY_STR}'
  agentLabelSelector:
    matchLabels:
      bla: "aaa"
  pullSecretRef:
    name: assisted-deployment-pull-secret
  ignitionConfigOverride: '{"ignition":{"version":"3.1.0"},"storage":{"files":[{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /tmp/registries.conf | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/containers/registries.conf"},{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/pki/ca-trust/source/anchors/registry.crt"}]}}'
  nmStateConfigLabelSelector:
    matchLabels:
      cluster-name: ocp4-2
EOF


# SPOKE CLUSTER DEPLOYMENT
oc --kubeconfig=/root/kubeconfig-ocp4-1 get pods -A | grep metal

# Fully Automated ZTP
# 在我的环境里，我没有看到 provisioning-configuration
oc --kubeconfig=/root/kubeconfig-ocp4-1 patch provisioning provisioning-configuration --type merge -p '{"spec":{"watchAllNamespaces": true}}'

# Manual Spoke cluster deployment
# 1. We need to get the ISO URL from the InfraEnv CR with this command:
oc --kubeconfig=/root/kubeconfig-ocp4-1 get infraenv ocp4-2 -o jsonpath={.status.isoDownloadURL}

# 下载iso
curl -k "'"$(oc --kubeconfig=/root/kubeconfig-ocp4-1 get infraenv ocp4-2 -o jsonpath={.status.isoDownloadURL})"'" -o /tmp/sno-ocp4-2.iso 
```

### local registry self signed certs 报错
```
报错
AgentClusterInstall ocp4-2
The Spec could not be synced due to backend error: command oc adm release info -o template --template '{{.metadata.version}}' --insecure=false registry.example.com:5000/ocp4/openshift4:4.9.9-x86_64 exited with non-zero exit code 1:
error: unable to read image registry.example.com:5000/ocp4/openshift4:4.9.9-x86_64: Get "https://registry.example.com:5000/v2/": x509: certificate signed by unknown authority

# 这个报错的解决方法在 https://docs.openshift.com/container-platform/4.2/openshift_images/image-configuration.html#images-configuration-insecure_image-configuration 
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/using-shared-system-certificates_security-hardening


oc --kubeconfig=/root/kubeconfig-ocp4-1 get pod -n open-cluster-management | grep hub-subscription
multicluster-operators-hub-subscription-7bcdcb65b4-6bk5m          1/1     Running     6 (3h52m ago)     4d3h

# 无法用 oc rsync 和 oc cp 向 pod 里拷贝文件
oc rsync --kubeconfig=/root/kubeconfig-ocp4-1 -n open-cluster-management /etc/pki/ca-trust/source/anchors multicluster-operators-hub-subscription-7bcdcb65b4-6bk5m:/etc/pki/ca-trust/source/anchors

# oc --kubeconfig=/root/kubeconfig-ocp4-1 -n open-cluster-management cp /etc/pki/ca-trust/source/anchors/registry.crt multicluster-operators-hub-subscription-7bcdcb65b4-6bk5m:/tmp
time="2022-01-18T07:19:59Z" level=error msg="exec failed: container_linux.go:380: starting container process caused: exec: \"tar\": executable file not found in $PATH"
command terminated with exit code 1


https://drive.google.com/drive/folders/16DVMhh4M0BqnViEal_DSROX0H1mkjXvj?usp=sharing  Design Thinking的学习资料，大家有空学习一下这个思维方式

        - name: local-registry-8r7jc
          readOnly: true
          mountPath: /etc/pki/ca-trust/source/anchors
  volumes:
  ...
    - name: local-registry-8r7jc
      projected:
        sources:
          - configMap:
              name: local-registry-ca.crt
              items:        
                - key: registry.crt
                  path: registry.crt

[root@ocpai1 ocp4-2]# cd /etc/pki/ca-trust/source/anchors/
[root@ocpai1 anchors]# ls
registry.crt

这些命令不能为 deployment 添加 configmap 类型的 volume
oc --kubeconfig=/root/kubeconfig-ocp4-1 -n open-cluster-management create configmap local-registry-ca.crt --from-file=./registry.crt 

oc --kubeconfig=/root/kubeconfig-ocp4-1 -n open-cluster-management set volume deployment/multicluster-operators-hub-subscription --overwrite --add --name=local-registry-ca-volume --type=configmap --configmap-name=local-registry-ca.crt --mount-path=/etc/pki/ca-trust/sources/anchors

# 配置信任，这个配置方法不行
# oc --kubeconfig=/root/kubeconfig-ocp4-1 patch image.config.openshift.io cluster -p '{"spec":{"additionalTrustedCA":{"name":"user-ca-bundle"}}}' --type merge

# assisted service 的配置
# https://docs.google.com/document/d/1JN_KHsBpBk6vrf_aQjP9-vpmwODM5WcoJm18-k0Ofb4/edit#heading=h.sacp69wt8jj4

# 配置 additional CA 来信任 registry
# 这个方法正在尝试中
# registry.example.com:5000 在 configmap 配置过程中 key 写为 registry.example.com..5000
cd /etc/pki/ca-trust/source/anchors/
ls
registry.crt
oc --kubeconfig=/root/kubeconfig-ocp4-1 create configmap registry-config --from-file="registry.example.com..5000"=registry.crt -n openshift-config
oc --kubeconfig=/root/kubeconfig-ocp4-1 patch image.config.openshift.io/cluster -p '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}'  --type=merge

ls ca-bundle.crt 
ca-bundle.crt
oc --kubeconfig=/root/kubeconfig-ocp4-1 create configmap registry-config --from-file="registry.example.com..5000"=ca-bundle.crt -n open-cluster-management

# 需要理解这些内容
# https://github.com/RHsyseng/labs-index/blob/master/lab-kcli-ipi-baremetal/06_disconnected.sh
# https://github.com/karmab/kcli-openshift4-baremetal/blob/master/06_disconnected.sh
# https://github.com/RHsyseng/labs-index/blob/9c3fd987a76eb03c1e6687b0fc0b99735339d914/lab-kcli-ipi-baremetal/06_disconnected.sh#L58

# 真正解决疑惑的是这个链接
cat <<EOF | oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: mirror-registry-config-map
  namespace: "open-cluster-management"
  labels:
    app: assisted-service
data:
  ca-bundle.crt: |
$( cat /etc/pki/ca-trust/source/anchors/registry.crt | sed -e 's|^|    |g' )

  registries.conf: |
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

    [[registry]]
       prefix = ""
       location = "quay.io/ocpmetal"
       mirror-by-digest-only = false

       [[registry.mirror]]
       location = "mirror1.registry.corp.com:5000/ocpmetal"
EOF

### 看看这个问题
# restricted network installs with assisted-onprem deploying 4.6 clusters do not work
# https://bugzilla.redhat.com/show_bug.cgi?id=1922212

ignitionuyaml file 
cat <<EOF > /tmp/3.yml
ignition:
  version: 3.1.0
storage:
  files:
  - contents:
      source: data:text/plain;charset=utf-8;base64,$(cat /tmp/registries.conf|base64 -w0)      verification: {}
    filesystem: root
    mode: 420
    overwrite: true
    path: /etc/containers/registries.conf
  - contents:
      source: data:text/plain;charset=utf-8;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt|base64 -w0)
      verification: {}
    filesystem: root
    mode: 420
    overwrite: true
    path: /etc/pki/ca-trust/source/anchors/registry.crt
EOF

### download minimal iso
curl -k 'https://assisted-service-open-cluster-management.apps.ocp4-1.example.com/api/assisted-install/v1/clusters/0f430649-6a93-419f-876a-14899135df80/downloads/image?api_key=eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJjbHVzdGVyX2lkIjoiMGY0MzA2NDktNmE5My00MTlmLTg3NmEtMTQ4OTkxMzVkZjgwIn0.1a9ix70v09Z15RYm8EInr9o5ZDO-dJBuUPS5dJeZA3-Wf7i6yK0zUIIQDCFtje_FzySXGx8xTcity5OdKEOrKA' -o /tmp/sno-ocp4-2.iso

### 检查 iso ignition 的命令 
zcat $ISO_MOUNT_PATH/images/ignition.img | sed '1d; $d'

### 删除 Spoke Cluster Object 
oc --kubeconfig=/root/kubeconfig-ocp4-1 -n open-cluster-management 


### 
cat >> /tmp/token <<EOF
eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJjbHVzdGVyX2lkIjoiN2UwYmFkZTEtMDUzYi00ZTFhLTk1MzUtMTc4MjBiNjdhMTJkIn0.iWWYYTNwQEHILbslmTDrMxpgmBYze1gAuB6tuAUvEb5NIUG6cVLk0JlB-2k6KG--8eceXzqdp8iybUXVTg0M7g
EOF

curl  -k --header "Content-Type: application/json" --request GET "$AI_URL/api/assisted-install/v1/clusters"  

# 文档
# https://docs.openshift.com/container-platform/4.9/scalability_and_performance/ztp-deploying-disconnected.html
# 部署 SNO 非常好的文档
# https://michaelkotelnikov.medium.com/deploying-single-node-bare-metal-openshift-using-advanced-cluster-management-9ec27b6663bf

oc1 get ValidatingWebhookConfiguration
oc1 delete ValidatingWebhookConfiguration multiclusterhub-operator-validating-webhook
oc1 patch mch multiclusterhub -n open-cluster-management -p '{"metadata":{"finalizers":[]}}' --type=merge
oc1 delete mch multiclusterhub -n open-cluster-management

# 报错
Pod installer-6-master-0.ocp4-1.example.com
Failed to get config map openshift-kube-controller-manager/client-ca

# 如何降低 SNO 对资源的需求
# ok, look for a config map called assisted-service and inside of it you will see the HW_VALIDATOR_REQUIREMENTS
# https://github.com/openshift/assisted-service/blob/master/docs/operator.md#specifying-environmental-variables-via-configmap
# https://issues.redhat.com/browse/MGMT-8820

- version: default
  master:
    cpu_cores: 4
    ram_mib: 16384
    disk_size_gb: 120
    installation_disk_speed_threshold_ms: 10
    network_latency_threshold_ms: 100
    packet_loss_percentage: 0
  worker:
    cpu_cores: 2
    ram_mib: 8192
    disk_size_gb: 120
    installation_disk_speed_threshold_ms: 10
    network_latency_threshold_ms: 1000
    packet_loss_percentage: 10
  sno:
    cpu_cores: 8
    ram_mib: 32768
    disk_size_gb: 120
    installation_disk_speed_threshold_ms: 10

# ACM Application FailOver
https://github.com/stolostron/labs/blob/403150df04b3c05370df2449f29c4994eb5bf50d/introduction-to-gitops-and-policies/03_deploying_apps_to_clusters.md

# 更新 assisted-service-config configmap 实现定制化
  HW_VALIDATOR_REQUIREMENTS: >-
    [{"version":"default","master":{"cpu_cores":4,"ram_mib":16384,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":100,"packet_loss_percentage":0},"worker":{"cpu_cores":2,"ram_mib":8192,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":1000,"packet_loss_percentage":10},"sno":{"cpu_cores":8,"ram_mib":4096,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10}}]

  HW_VALIDATOR_REQUIREMENTS: >-
    [{"version":"default","master":{"cpu_cores":4,"ram_mib":16384,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":100,"packet_loss_percentage":0},"worker":{"cpu_cores":2,"ram_mib":8192,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":1000,"packet_loss_percentage":10},"sno":{"cpu_cores":8,"ram_mib":4096,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10}}]

报错及恢复
(combined from similar events): Error: Kubelet may be retrying requests that are timing out in CRI-O due to system load: context deadline exceeded: error reserving ctr name k8s_assisted-service_assisted-service-7795d8f895-x6tpx_open-cluster-management_c560ebd2-f6b4-4d58-9dce-50b57d1c5f93_2 for id ebb5ae1ea296d5bb7d7ca45295cbcb541a4f50c10b1d9c2a90fc1baf0b6c3814: name is reserved
https://access.redhat.com/solutions/5812571
在 SNO 这种场景下，可以尝试 systemctl restart crio.service

报错
1-2022 03:33:01" level=error msg="Next step runner has crashed and will be restarted in 1h0m0s" file="main.go:35" error="next step ru>

报错
Jan 24 03:57:59 master-0.ocp4-2.example.com agent[356762]: time="24-01-2022 03:57:59" level=error msg="Next step runner has crashed and will be restarted in 1h0m0s" file="main.go:35" error="next step runner command exited with non-zero exit code 2: time=\"2022-01-24T03:56:59Z\" level=warning msg=\"The input device is not a TTY. The --tty and --interactive flags might not work properly\"\ntime=\"2022-01-24T03:57:59Z\" level=warning msg=\"lstat /sys/fs/cgroup/devices/machine.slice/libpod-0c8a8208fd63b79a26c603d3be52b40cbc0d587c9e6653bce12b473516539c53.scope: no such file or directory\"\n"
https://bugzilla.redhat.com/show_bug.cgi?id=2014237

报错 - 重启 SNO 之后, oc get clusteroperators 
这些报错都可以通过等待消除
dns                                        4.9.9     False       True          True       69s     DNS "default" is unavailable.
network                                    4.9.9     True        True          True       3d22h   DaemonSet "openshift-multus/multus-additional-cni-plugins" rollout is not making progress - last change 2022-01-24T06:11:29Z

ssh -i /root/.ssh/id_rsa core@192.168.122.201 w 
 06:32:16 up 32 min,  0 users,  load average: 32.76, 30.87, 21.69
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT

经过了 32 分钟，SNO 完成了重启，clusteroperators 状态正常

# pod 'assisted-service' container 'assisted-service' logs
# oc logs assisted-service-8659487655-jq8gv assisted-service -p -n open-cluster-management 
...
time="2022-01-24T06:32:14Z" level=info msg="ClusterDeployment Reconcile ended" func="github.com/openshift/assisted-service/internal/controller/controllers.(*ClusterDeploymentsReconciler).Reconcile.func1" file="/remote-source/assisted-service/app/internal/controller/controllers/clusterdeployments_controller.go:114" agent_cluster_install=ocp4-2 agent_cluster_install_namespace=ocp4-2 cluster_deployment=ocp4-2 cluster_deployment_namespace=ocp4-2 go-id=825 request_id=01c84889-7237-4fd9-b792-94fb50a2ab37
time="2022-01-24T06:32:14Z" level=info msg="ClusterDeployment Reconcile started" func="github.com/openshift/assisted-service/internal/controller/controllers.(*ClusterDeploymentsReconciler).Reconcile" file="/remote-source/assisted-service/app/internal/controller/controllers/clusterdeployments_controller.go:117" cluster_deployment=ocp4-2 cluster_deployment_namespace=ocp4-2 go-id=825 request_id=e76f1747-59f2-4e9f-95fe-b06eb9126d7a
time="2022-01-24T06:32:14Z" level=debug msg="Pushing cluster event ocp4-2 ocp4-2" func="github.com/openshift/assisted-service/internal/controller/controllers.(*controllerEventsWrapper).NotifyKubeApiClusterEvent" file="/remote-source/assisted-service/app/internal/controller/controllers/controller_event_wrapper.go:92"
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x1bfa4e9]

goroutine 932 [running]:
github.com/openshift/assisted-service/internal/bminventory.(*bareMetalInventory).generateClusterInstallConfig(_, {_, _}, {{{0x0, 0x0}, {0x0, 0x0}, {0x0, 0x0}, 0x0, ...}, ...})
        /remote-source/assisted-service/app/internal/bminventory/inventory.go:2011 +0x1a9
github.com/openshift/assisted-service/internal/bminventory.(*bareMetalInventory).InstallClusterInternal.func3()
        /remote-source/assisted-service/app/internal/bminventory/inventory.go:1641 +0x245
created by github.com/openshift/assisted-service/internal/bminventory.(*bareMetalInventory).InstallClusterInternal
        /remote-source/assisted-service/app/internal/bminventory/inventory.go:1628 +0x8cf


Jan 24 07:01:31 master-0.ocp4-2.example.com agent[3912]: time="24-01-2022 07:01:31" level=error msg="Next step runner has crashed and will be restarted in 1h0m0s" file="main.go:35" error="next step runner command exited with non-zero exit code 2: time=\"2022-01-24T07:00:30Z\" level=warning msg=\"The input device is not a TTY. The --tty and --interactive flags might not work properly\"\ntime=\"2022-01-24T07:01:31Z\" level=warning msg=\"lstat /sys/fs/cgroup/devices/machine.slice/libpod-9cf89ec25fd2d773bc6bab90549bf172499d6875d662dea2116548112c9fd013.scope: no such file or directory\"\n"

# 根据以上报错，创建 Bug 2044175
https://bugzilla.redhat.com/show_bug.cgi?id=2044175

# InfraEnv 报错
Insufficient
Validated: The agent's validations are failing: Missing inventory or machine network CIDR,Host couldn't synchronize with any NTP server,Parse error for domain name resolutions result.

# agentclusterinstalls.extensions.hive.openshift.io "ocp4-2" was not valid:
# * spec.networking.machineNetwork: Invalid value: "string": spec.networking.machineNetwork in body must be of type object: "string"


# 经验证这个是工作的
SSH_PUBLIC_KEY_STR=$( cat /root/.ssh/id_rsa.pub )
oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: ocp4-2
  namespace: ocp4-2
spec:
  additionalNTPSources:
    - ntp.example.com  
  clusterRef:
    name: ocp4-2
    namespace: ocp4-2
  sshAuthorizedKey: '${SSH_PUBLIC_KEY_STR}'
  pullSecretRef:
    name: assisted-deployment-pull-secret
  ignitionConfigOverride: '{"ignition":{"version":"3.1.0"},"storage":{"files":[{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /tmp/registries.conf | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/containers/registries.conf"},{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/pki/ca-trust/source/anchors/registry.crt"}]}}'
  nmStateConfigLabelSelector:
    matchLabels:
      cluster-name: ocp4-2
EOF

# SiteConfig.yaml
# 定义了一个新的对象 SiteConfig
# SiteConfig 对象应该可以创建 InfraEnv, ClusterDeployment, AgentClusterInstall 和 ManagedCluster 对象
# https://docs.openshift.com/container-platform/4.9/scalability_and_performance/ztp-deploying-disconnected.html
# https://cloud.redhat.com/blog/telco-5g-zero-touch-provisioning-ztp
apiVersion: ran.openshift.io/v1
kind: SiteConfig
metadata:
  name: "sno0-openshift-edge"
  namespace: "sno0-openshift-edge"
spec:
  baseDomain: "airtel.local"
  pullSecretRef:
    name: "assisted-deployment-pull-secret"
  clusterImageSetNameRef: "img4.9.9-x86-64-appsub" 
  sshPublicKey: "********************************"
  clusters:
  - clusterName: "sno0-openshift-edge"
    clusterType: "sno"
    clusterProfile: "cu"
    numMasters: 1
    clusterLabels:
      common: true
      sites : "sno0-openshift-edge"
    clusterNetwork:
       - cidr: 10.128.0.0/14
         hostPrefix: 23
    serviceNetwork:
       - 172.30.0.0/16
    machineNetwork:
       - cidr: 172.16.68.40/29
    nodes:
       - hostName: "sno0-openshift-edge"
         bmcAddress: "idrac-virtualmedia+https://172.16.82.11/redfish/v1/Systems/System.Embedded.1" 
         bmcCredentialsName:
           name: "sno0-openshift-edge-sno0-openshift-edge-bmh-secret"
         bootMACAddress: "04:3F:72:C2:18:50"
         bootMode: "UEFI"
         rootDeviceHints:
           deviceName: "/dev/sda"
         cpuset: "0-3,4-79"
         nodeNetwork:
            interfaces:
            - name: eno1
              macAddress: "04:3F:72:C2:18:50"
            config:
               interfaces:
               - name: eno1
                 type: ethernet
                 state: up
                 macAddress: "04:3F:72:C2:18:50"
                 ipv4:
                   enabled: true
                   dhcp: true
                 ipv6:
                   enabled: false

# Metal3 在哪个版本支持 Baremetal 非 IPI 部署的 Hub
# https://github.com/openshift/installer/blob/master/data/data/manifests/openshift/baremetal-provisioning-config.yaml.template
# 4.10 支持 non Baremetal Hub
# 这时用户需要创建一个 metal3 Provisioning CR

# 报错
Bundle unpacking failed. Reason: DeadlineExceeded, and Message: Job was active longer than specified deadline
# 参考 https://access.redhat.com/solutions/6459071
# 按照以下步骤删除有问题的对象
oc get job -n openshift-marketplace -o json | jq -r '.items[] | select(.spec.template.spec.containers[].env[].value|contains ("<operator_name_keyword>")) | .metadata.name'
oc delete job <job_string_returned_above> -n openshift-marketplace
oc delete configmap <job_string_returned_above> -n openshift-marketplace
# 在界面删除 Operator
oc delete ip <operator_installplan_name> -n <user_namespace>
oc delete sub <operator_subscription_name> -n <user_namespace>
oc delete csv <operator_csv_name> -n <user_namespace>


# 报错
Feb 17 04:53:51 master-0.ocp4-1.example.com hyperkube[2045]: I0217 04:53:51.703002    2045 kubelet_pods.go:898] "Unable to retrieve pull secret, the image pull may not succeed." pod="open-cluster-management-agent/klusterlet-registration-agent-7c96c87cf6-mr9l4" secret="" err="secret \"open-cluster-management-image-pull-credentials\" not found"

# 在 open-cluster-management-agent namespace 下创建 secret open-cluster-management-image-pull-credentials
oc project open-cluster-management-agent
oc create secret generic open-cluster-management-image-pull-credentials \
    --from-file=.dockerconfigjson=/tmp/redhat-pull-secret.json \
    --type=kubernetes.io/dockerconfigjson

# 报错
sudo journalctl -u agent.service -f
Feb 19 10:41:45 master-0.ocp4-2.example.com agent[1913]: time="19-02-2022 10:41:45" level=error msg="Next step runner has crashed and will be restarted in 1h0m0s" file="main.go:35" error="next step runner command exited with non-zero exit code 2: time=\"2022-02-19T10:39:44Z\" level=warning msg=\"The input device is not a TTY. The --tty and --interactive flags might not work properly\"\ntime=\"2022-02-19T10:41:45Z\" level=warning msg=\"lstat /sys/fs/cgroup/devices/machine.slice/libpod-78bfe501fa184c8654c03c447896f2bad6f879ecd2fb5583da566c121be54d36.scope: no such file or directory\"\n"

Feb 19 11:31:26 master-0.ocp4-2.example.com agent[2005]: time="19-02-2022 11:31:26" level=warning msg="Error registering host: Internal Server Error, Failed to get cluster 9efed3dc-cab5-4593-a4cb-aa6506527283: record not found" file="register_node.go:50" request_id=2b774f5f-defc-469f-8795-237e79c8c989

为 agentclusterinstall 添加 machineNetwork
oc edit agentclusterinstall ocp4-2 -n ocp4-2
...
spec:
  clusterDeploymentRef:
    name: ocp4-2
  holdInstallation: true
  imageSetRef:
    name: openshift-v4.9.9
  networking:
    clusterNetwork:
    - cidr: 10.128.0.0/14
      hostPrefix: 23
    serviceNetwork:
    - 172.30.0.0/16
    machineNetwork:
    - cidr: 192.168.122.0/24

编辑 infraenv ocp4-2 添加
  nmStateConfigLabelSelector:
    matchLabels:
      cluster-name: ocp4-2
```