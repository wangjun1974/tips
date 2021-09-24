### 软件准备

需要准备的操作系统镜像
RHEL-8.4

需要准备的软件频道参见：
https://access.redhat.com/documentation/en/red_hat_openstack_platform/16.2/html/director_installation_and_usage/planning-your-undercloud#undercloud-repositories

安装虚拟机
```
# kickstart 文件参考 https://github.com/wangjun1974/tips/blob/master/os/miscs.md#rhel8-minimal-kickstart-file
virt-install --name=jwang-rhel82-undercloud --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-rhel82-undercloud.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --location /root/jwang/isos/rhel-8.4-x86_64-dvd.iso \
--console pty,target_type=serial \
--initrd-inject /tmp/ks.cfg \
--extra-args='ks=file:/ks.cfg console=ttyS0'

RHEL 8.4 的 kickstart 文件语法有改变，
注意：ks 变为了 inst.ks , ksdevice 变为了 inst.ksdevice, dns 变为了 nameserver
```

在下载服务器上执行，订阅所需软件频道
```
subscription-manager release --set=8.4
subscription-manager repos --disable=*
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-eus-rpms --enable=rhel-8-for-x86_64-appstream-eus-rpms --enable=rhel-8-for-x86_64-highavailability-eus-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms --enable=openstack-16.2-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms --enable=advanced-virt-for-rhel-8-x86_64-rpms --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms --enable=rhel-8-for-x86_64-nfv-rpms
```

在下载服务器上，生成同步软件频道的脚本
```
mkdir -p /var/www/html/repos/osp16.2
pushd /var/www/html/repos/osp16.2

# 安装 createrepo
yum install -y createrepo

cat > ./OSP16_2_repo_sync_up.sh <<'EOF'
#!/bin/bash

localPath="/var/www/html/repos/osp16.2/"
fileConn="/getPackage/"

## sync following yum repos 
# rhel-8-for-x86_64-baseos-eus-rpms
# rhel-8-for-x86_64-appstream-eus-rpms
# rhel-8-for-x86_64-highavailability-eus-rpms
# ansible-2.9-for-rhel-8-x86_64-rpms
# openstack-16.2-for-rhel-8-x86_64-rpms
# fast-datapath-for-rhel-8-x86_64-rpms
# rhceph-4-tools-for-rhel-8-x86_64-rpms
# advanced-virt-for-rhel-8-x86_64-rpms
# rhel-8-for-x86_64-nfv-rpms

for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.2-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms rhel-8-for-x86_64-nfv-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --downloadcomps --download-metadata

  echo "create repo $i..."
  time createrepo -g $(ls "$localPath"$i/repodata/*comps.xml) --update --skip-stat --cachedir /tmp/empty-cache-dir "$localPath"$i

done

exit 0
EOF

# 同步软件仓库
/usr/bin/nohup /bin/bash OSP16_2_repo_sync_up.sh &

# 同步完之后把 /var/www/html/repos/osp16.2 目录打包，下载作为离线时使用的软件仓库

```

### Yum 仓库和镜像仓库准备

OSP 在部署时需要访问镜像仓库，在一般的部署下，这个镜像仓库会部署在 undercloud 上

```
# 1. 安装时需使用 rhel-8.4-x86_64-dvd.iso 作为操作系统的安装介质
# 这个 ISO 可在红帽官网下载
# https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.4/x86_64/product-software

# 2. 安装操作系统 

# 3. 安装完操作系统之后，执行以下配置
# 3.1 以 root 用户登录系统
# 3.2 创建 stack 用户
[root@director ~]# useradd stack

# 3.3 为 stack 用户设置口令
[root@director ~]# passwd stack

# 3.4 为 Stack 用户设置 sudo 
[root@director ~]# echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
[root@director ~]# chmod 0440 /etc/sudoers.d/stack

# 3.5 切换为 stack 用户
[root@director ~]# su - stack
[stack@director ~]$

# 3.6 创建 images 和 templates 目录
[stack@director ~]$ mkdir ~/images
[stack@director ~]$ mkdir ~/templates

# 3.7 设置主机名并检查主机名
[stack@director ~]$ sudo hostnamectl set-hostname undercloud.example.com
[stack@director ~]$ sudo hostnamectl set-hostname --transient undercloud.example.com

# 3.8 编辑 /etc/hosts 文件，添加 undercloud.example.com 对应的记录
[stack@undercloud ~]$ sudo -i
[root@undercloud ~]# cat >> /etc/hosts << 'EOF'
10.0.11.27 undercloud.example.com undercloud
EOF
[root@undercloud ~]# exit
[stack@undercloud ~]$

# 4.1 注册系统
[stack@undercloud ~]$ sudo subscription-manager register

# 4.2 列出包含 Red Hat OpenStack 的订阅，记录下订阅的 Pool ID
[stack@undercloud ~]$ sudo subscription-manager list --available --all --matches="Red Hat OpenStack"

# 4.3 为系统附加 Pool
[stack@undercloud ~]$ sudo subscription-manager attach --pool=8a85f99c727637ad0172c517131a1e6d

# 4.4 设置系统 release 为 8.4
[stack@undercloud ~]$ sudo subscription-manager release --set=8.4

# 5.1 禁用所有软件频道
[stack@undercloud ~]$ sudo subscription-manager repos --disable=*

# 5.2 启用对应软件频道
[stack@undercloud ~]$ sudo subscription-manager repos --enable=rhel-8-for-x86_64-baseos-eus-rpms --enable=rhel-8-for-x86_64-appstream-eus-rpms --enable=rhel-8-for-x86_64-highavailability-eus-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms --enable=openstack-16.1-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms --enable=advanced-virt-for-rhel-8-x86_64-rpms --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms

# 5.3 安装 httpd
[stack@undercloud ~]$ sudo yum install -y httpd

# 5.4 创建本地 repos 目录
[stack@undercloud ~]$ sudo mkdir -p /var/www/html/repos/osp16.1
[stack@undercloud ~]$ sudo -i
[root@undercloud ~]# pushd /var/www/html/repos

# 5.5 安装 createrepo，生成 repos 同步脚本
[root@undercloud repos]# yum install -y createrepo yum-utils
[root@undercloud repos]# cat > ./OSP16_2_repo_sync_up.sh <<'EOF'
#!/bin/bash

localPath="/var/www/html/repos/osp16.2/"
fileConn="/getPackage/"

## sync following yum repos 
# rhel-8-for-x86_64-baseos-eus-rpms
# rhel-8-for-x86_64-appstream-eus-rpms
# rhel-8-for-x86_64-highavailability-eus-rpms
# ansible-2.9-for-rhel-8-x86_64-rpms
# openstack-16.2-for-rhel-8-x86_64-rpms
# fast-datapath-for-rhel-8-x86_64-rpms
# rhceph-4-tools-for-rhel-8-x86_64-rpms
# advanced-virt-for-rhel-8-x86_64-rpms
# rhel-8-for-x86_64-nfv-rpms

for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.2-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms rhel-8-for-x86_64-nfv-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --downloadcomps --download-metadata

  # rhel8 no need to run createrepo
  #echo "create repo $i..."
  #time createrepo -g $(ls "$localPath"$i/repodata/*comps.xml) --update --skip-stat --cachedir /tmp/#empty-cache-dir "$localPath"$i

done

exit 0
EOF

# 5.6 同步 repos
[root@undercloud repos]# /usr/bin/nohup /bin/bash ./OSP16_2_repo_sync_up.sh &

# 5.7 重设 selinux context
[root@undercloud repos]# chcon --recursive --reference=/var/www/html /var/www/html/repos

# 5.8 开启防火墙 http 端口，启动 httpd 服务器
[root@undercloud repos]# firewall-cmd --add-service=http
[root@undercloud repos]# firewall-cmd --add-service=http --permanent
[root@undercloud repos]# firewall-cmd --reload

# 5.9 启动 httpd 服务
[root@undercloud repos]# systemctl enable httpd && systemctl start httpd

# 5.10 禁用远程 yum 源，设置本地 http yum 源
# baseurl 的 UNDERCLOUD_IP 地址
# 用本地接口名称替换 ens3
[root@undercloud repos]# subscription-manager repos --disable=*
[root@undercloud repos]# echo y | mv /etc/yum.repos.d/redhat.repo /etc/yum.repos.d/backup
[root@undercloud repos]# sed -ie 's|enabled=1|enabled=0|' /etc/yum/pluginconf.d/subscription-manager.conf

[root@undercloud repos]# UNDERCLOUD_IP=$( ip a s dev ens3 | grep -E "inet " | awk '{print $2}' | awk -F'/' '{print $1}' )
[root@undercloud repos]# > /etc/yum.repos.d/osp.repo 
[root@undercloud repos]# for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms
do
cat >> /etc/yum.repos.d/osp.repo << EOF
[$i]
name=$i
baseurl=http://${UNDERCLOUD_IP}/repos/osp16.1/$i/
enabled=1
gpgcheck=0

EOF
done

[root@undercloud repos]# exit


# 5.11 安装并设置 chrony 服务
[stack@undercloud ~]$ sudo dnf install -y chrony

# 生成以 undercloud 本地时间为时间源的时间服务器配置
[stack@undercloud ~]$ sudo -i 
[stack@undercloud ~]# cat > /etc/chrony.conf << EOF
server 192.0.2.1 iburst
bindaddress 192.0.2.1
allow all
local stratum 4
EOF
[stack@undercloud ~]# exit

# 在 firewallD 规则里开放 ntp 服务
[stack@undercloud ~]$ sudo firewall-cmd --add-service=ntp
[stack@undercloud ~]$ sudo firewall-cmd --add-service=ntp --permanent
[stack@undercloud ~]$ sudo firewall-cmd --reload
[stack@undercloud ~]$ sudo systemctl enable chronyd && sudo systemctl start chronyd

# 查看时间源
[stack@undercloud ~]$ chronyc -n sources
[stack@undercloud ~]$ chronyc -n tracking

# 5.12 设置 container-tools 模块为版本 2.0
[stack@undercloud ~]$ sudo dnf module disable -y container-tools:rhel8
[stack@undercloud ~]$ sudo dnf module enable -y container-tools:2.0

# 5.13 设置 virt 模块版本为 8.2
[stack@undercloud ~]$ sudo dnf module disable -y virt:rhel
[stack@undercloud ~]$ sudo dnf module enable -y virt:8.2

# 5.14 更新并且重启
[stack@undercloud ~]$ sudo dnf update -y
[stack@undercloud ~]$ sudo reboot

# 6 安装 director
[stack@undercloud ~]$ sudo dnf install -y python3-tripleoclient

# 7 安装 ceph-ansible
[stack@undercloud ~]$ sudo dnf install -y ceph-ansible

# 8 创建 undercloud.conf 文件
# 参数详情参见：https://github.com/wangjun1974/tips/blob/master/osp/digitalchina/1_undercloud_conf.md
cat > undercloud.conf << EOF
[DEFAULT]
undercloud_hostname = undercloud.example.com
container_images_file = containers-prepare-parameter.yaml
local_ip = 192.0.2.1/24
undercloud_public_host = 192.0.2.2
undercloud_admin_host = 192.0.2.3
#undercloud_nameservers = 192.0.2.254
subnets = ctlplane-subnet
local_subnet = ctlplane-subnet
#undercloud_service_certificate =
#generate_service_certificate = true
#certificate_generation_ca = local
local_interface = ens10
inspection_extras = true
undercloud_debug = false
enable_tempest = false
enable_ui = false
clean_nodes = true


[auth]
undercloud_admin_password = redhat

[ctlplane-subnet]
cidr = 192.0.2.0/24
dhcp_start = 192.0.2.5
dhcp_end = 192.0.2.24
inspection_iprange = 192.0.2.100,192.0.2.120
gateway = 192.0.2.1
masquerade = true
EOF

# 9.1 生成容器参数文件 containers-prepare-parameter.yaml
[stack@undercloud ~]$ openstack tripleo container image prepare default   --local-push-destination   --output-env-file containers-prepare-parameter.yaml

# 9.2 为 containers-prepare-parameter.yaml 添加 ContainerImageRegistryCredentials 参数
# 参见：https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html/advanced_overcloud_customization/sect-containerized_services#container-image-preparation-parameters
# 参见：https://access.redhat.com/RegistryAuthentication
# 在以下网址创建所需的 registry service accounts
# https://access.redhat.com/terms-based-registry/#/accounts
cat >> containers-prepare-parameter.yaml <<'EOF'
  ContainerImageRegistryCredentials:
    registry.redhat.io:
      6747835|jwang: eyJhbGciOiJSUzUxMi...
EOF

# 10. 安装 undercloud
[stack@undercloud ~]$ time openstack undercloud install

# 11. 修改 yum repo 
# 安装 undercloud 时把 http 服务从端口 80 改为了 8787
[stack@undercloud ~]$ sudo sed -ie 's|192.168.8.21|192.168.8.21:8787|g' /etc/yum.repos.d/osp.repo
[stack@undercloud ~]$ echo y | sudo mv /etc/yum.repos.d/osp.repoe /etc/yum.repos.d/backup

# 12. 安装 undercloud
[stack@undercloud ~]$ time openstack undercloud install

# 13. 检查 undercloud 状态
[stack@undercloud ~]$ source ~/stackrc
# 13.1 查看 undercloud catalog
(undercloud) [stack@undercloud ~]$ openstack catalog list
# 13.2 查看 ip 地址
(undercloud) [stack@undercloud ~]$ ip a 
# 13.3 查看 ip 路由
(undercloud) [stack@undercloud ~]$ ip r
# 13.4 检查 ovs database
(undercloud) [stack@undercloud ~]$ sudo ovs-vsctl show
# 13.5 检查 undercloud openstack 网络配置
(undercloud) [stack@undercloud ~]$ cat /etc/os-net-config/config.json | jq .
# 13.6 检查 ovs switch 基本情况
(undercloud) [stack@undercloud ~]$ sudo ovs-vsctl show
# 13.7 查看 undercloud openstack 网络情况
(undercloud) [stack@undercloud ~]$ openstack network list
(undercloud) [stack@undercloud ~]$ openstack subnet list
(undercloud) [stack@undercloud ~]$ openstack subnet show ctlplane-subnet -f json
(undercloud) [stack@undercloud ~]$ sudo podman ps
```

### 离线镜像仓库准备 (新)
```
安装 registry 基础软件
yum install -y podman httpd httpd-tools wget jq

创建目录
mkdir -p /opt/registry/{certs,data}

生成 registry 证书
cd /opt/registry/certs
openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 3650 -out domain.crt     -addext "subjectAltName = DNS:helper.example.com" -subj "/C=CN/ST=BJ/L=BJ/O=Global Security/OU=IT Department/CN=helper.example.com"

更新本地证书信任
cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

更新防火墙
firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public   --permanent
firewall-cmd --reload

生成脚本
cat > /usr/local/bin/localregistry.sh << 'EOF'
#!/bin/bash
podman run --name poc-registry -d -p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
docker.io/library/registry:latest
EOF

设置脚本可执行
chmod +x /usr/local/bin/localregistry.sh

启动镜像服务
/usr/local/bin/localregistry.sh

验证镜像服务可访问
curl https://helper.example.com:5000/v2/_catalog
cd /root

生成同步镜像脚本 syncimgs
cat > /root/syncimgs <<'EOF'
#!/bin/env bash

PUSHREGISTRY=helper.example.com:5000
FORK=4

rhosp_namespace=registry.redhat.io/rhosp-rhel8
rhosp_tag=16.2
ceph_namespace=registry.redhat.io/rhceph
ceph_image=rhceph-4-rhel8
ceph_tag=latest
ceph_alertmanager_namespace=registry.redhat.io/openshift4
ceph_alertmanager_image=ose-prometheus-alertmanager
ceph_alertmanager_tag=v4.6
ceph_grafana_namespace=registry.redhat.io/rhceph
ceph_grafana_image=rhceph-4-dashboard-rhel8
ceph_grafana_tag=4
ceph_node_exporter_namespace=registry.redhat.io/openshift4
ceph_node_exporter_image=ose-prometheus-node-exporter
ceph_node_exporter_tag=v4.6
ceph_prometheus_namespace=registry.redhat.io/openshift4
ceph_prometheus_image=ose-prometheus
ceph_prometheus_tag=v4.6

function copyimg() {
  image=${1}
  version=${2}

  release=$(skopeo inspect docker://${image}:${version} | jq -r '.Labels | (.version + "-" + .release)')
  dest="${PUSHREGISTRY}/${image#*\/}"
  echo Copying ${image} to ${dest}
  skopeo copy docker://${image}:${release} docker://${dest}:${release} --quiet
  skopeo copy docker://${image}:${version} docker://${dest}:${version} --quiet
}

copyimg "${ceph_namespace}/${ceph_image}" ${ceph_tag} &
copyimg "${ceph_alertmanager_namespace}/${ceph_alertmanager_image}" ${ceph_alertmanager_tag} &
copyimg "${ceph_grafana_namespace}/${ceph_grafana_image}" ${ceph_grafana_tag} &
copyimg "${ceph_node_exporter_namespace}/${ceph_node_exporter_image}" ${ceph_node_exporter_tag} &
copyimg "${ceph_prometheus_namespace}/${ceph_prometheus_image}" ${ceph_prometheus_tag} &
wait

for rhosp_image in $(podman search ${rhosp_namespace} --limit 1000 --format "{{ .Name }}"); do
  ((i=i%FORK)); ((i++==0)) && wait
  copyimg ${rhosp_image} ${rhosp_tag} &
done
EOF

```


### 离线镜像仓库准备 (旧)

```
# 参考：https://source.redhat.com/communitiesatredhat/infrastructure/cloud-platforms-community-of-practice/tracks/openstackcommunityofpracticedeploydeliverarchitect/cloud_infrastructure_cop_cloud_platforms_delivery_blog/openstack_disconnected_registry_revisited

# 首先从在线镜像仓库同步镜像
# 安装 podman, skopeo, jq
- name: ensure packages are installed
  become: true
  package:
    name:
      - podman
      - skopeo
      - jq
    state: latest

# 运行 registry
- name: pull registry image
  become: true
  podman_image:
    name: registry
    pull: yes

- name: start registry container
  become: true
  command: podman run -d -p 5000:5000 --name registry registry
  ignore_errors: yes

# 配置运行非安全 registry
- name: configure insecure registries
  become: true
  ini_file:
    path: /etc/containers/registries.conf
    section: 'registries.insecure'
    option: registries
    value: "['{{ push_registry }}']"
  when:
   - (push_registry | length) > 0

# 登录 CDN registry ，执行脚本同步镜像
- name: login to source registry
  shell: |-
    podman login --username=$REGISTRY_USERNAME \
                 --password=$REGISTRY_PASSWORD \
                 --tls-verify={{ podman_tls_verify }} \
                 $REGISTRY
  environment:
    REGISTRY_USERNAME: "{{ registry_username }}"
    REGISTRY_PASSWORD: "{{ registry_password }}"
    REGISTRY: "{{ registry }}"
  register: registry_login_podman

- name: sync images
  command: "/bin/bash syncimgs"
  args:
    chdir: "{{ sync_dir_path }}"

# Ansible Roles 在这里
# https://gitlab.consulting.redhat.com/tbonds/ansible-role-rhospregistry

# 同步镜像的脚本 syncimgs
#!/bin/env bash

PUSHREGISTRY=localhost:5000
FORK=4

rhosp_namespace=registry.redhat.io/rhosp-rhel8
rhosp_tag=16.0
ceph_namespace=registry.redhat.io/rhceph
ceph_image=rhceph-4-rhel8
ceph_tag=latest
ceph_alertmanager_namespace=registry.redhat.io/openshift4
ceph_alertmanager_image=ose-prometheus-alertmanager
ceph_alertmanager_tag=4.1
ceph_grafana_namespace=registry.redhat.io/rhceph
ceph_grafana_image=rhceph-3-dashboard-rhel7
ceph_grafana_tag=3
ceph_node_exporter_namespace=registry.redhat.io/openshift4
ceph_node_exporter_image=ose-prometheus-node-exporter
ceph_node_exporter_tag=v4.1
ceph_prometheus_namespace=registry.redhat.io/openshift4
ceph_prometheus_image=ose-prometheus
ceph_prometheus_tag=4.1

function copyimg() {
  image=${1}
  version=${2}

  release=$(skopeo inspect docker://${image}:${version} | jq -r '.Labels | (.version + "-" + .release)')
  dest="${PUSHREGISTRY}/${image#*\/}"
  echo Copying ${image} to ${dest}
  skopeo copy docker://${image}:${release} docker://${dest}:${release} --quiet
  skopeo copy docker://${image}:${version} docker://${dest}:${version} --quiet
}

copyimg "${ceph_namespace}/${ceph_image}" ${ceph_tag} &
copyimg "${ceph_alertmanager_namespace}/${ceph_alertmanager_image}" ${ceph_alertmanager_tag} &
copyimg "${ceph_grafana_namespace}/${ceph_grafana_image}" ${ceph_grafana_tag} &
copyimg "${ceph_node_exporter_namespace}/${ceph_node_exporter_image}" ${ceph_node_exporter_tag} &
copyimg "${ceph_prometheus_namespace}/${ceph_prometheus_image}" ${ceph_prometheus_tag} &
wait

for rhosp_image in $(podman search ${rhosp_namespace} --limit 1000 --format "{{ .Name }}"); do
  ((i=i%FORK)); ((i++==0)) && wait
  copyimg ${rhosp_image} ${rhosp_tag} &
done

# 在 vault 里保存 registry 帐户信息
registry_username: "username"
registry_password: "password"

# defaults/main.yaml
---
- hosts: localhost
  name: setup local registry
  gather_facts: false
  roles:
  - registry
  vars:
    push_registry: "localhost:5000"
  vars_files:
    - registry_vault.yml

# 执行 playbook
$ ansible-playbook --ask-vault-pass registry.yml

# 检查本地镜像仓库
podman search localhost:5000/ --limit 10
INDEX NAME DESCRIPTION STARS OFFICIAL AUTOMATED
localhost:5000 localhost:5000/openshift4/ose-prometheus 0 
localhost:5000 localhost:5000/openshift4/ose-prometheus-alertmanager 0 
localhost:5000 localhost:5000/openshift4/ose-prometheus-node-exporter 0 
localhost:5000 localhost:5000/rhceph/rhceph-3-dashboard-rhel7 0 
localhost:5000 localhost:5000/rhceph/rhceph-4-rhel8 0 
localhost:5000 localhost:5000/rhosp-rhel8/openstack-aodh-api 0 
localhost:5000 localhost:5000/rhosp-rhel8/openstack-aodh-base 0 
localhost:5000 localhost:5000/rhosp-rhel8/openstack-aodh-evaluator 0 
localhost:5000 localhost:5000/rhosp-rhel8/openstack-aodh-listener 0 
localhost:5000 localhost:5000/rhosp-rhel8/openstack-aodh-notifier 0

# 导出本地镜像仓库内容
$ mkdir /tmp/export
$ sudo podman run --rm --volumes-from registry:ro -v /tmp/export:/export:rw,z -w /export registry tar cf registry.tar /var/lib/registry

# 在离线镜像仓库导入
$ sudo podman run -d -p 5001:5001 --name newregistry registry
0a8e4ddc39a3509be02f936fc7986eda51962aad35f41965112f45dde6bda3c0

$ sudo podman run --rm --volumes-from newregistry -v /tmp/export:/export:ro,z -w /export registry sh -c "cd / && tar xf /export/registry.tar"

# 导入后检查离线镜像仓库
$ podman search localhost:5001/ --limit 10

# 使用离线镜像仓库
$ sudo crudini --set --format ini /etc/containers/registries.conf registries.insecure "['localregistry:5000']"

$ crudini --set --format ini undercloud.conf DEFAULT container_insecure_registries localregistry:5000

$ openstack tripleo container image prepare default --local-push-destination \
 | sed 's/registry.redhat.io/localregistry:5000/g' > containers-prepare-parameter.yaml 

$ cat /tmp/containers-prepare-parameter.yaml 
# Generated with the following on 2020-05-07T16:58:48.470201
#
#   openstack tripleo container image prepare default --local-push-destination
#

parameter_defaults:
  ContainerImagePrepare:
  - push_destination: true
    set:
      ceph_alertmanager_image: ose-prometheus-alertmanager
      ceph_alertmanager_namespace: localregistry:5000/openshift4
      ceph_alertmanager_tag: 4.1
      ceph_grafana_image: rhceph-3-dashboard-rhel7
      ceph_grafana_namespace: localregistry:5000/rhceph
      ceph_grafana_tag: 3
      ceph_image: rhceph-4-rhel8
      ceph_namespace: localregistry:5000/rhceph
      ceph_node_exporter_image: ose-prometheus-node-exporter
      ceph_node_exporter_namespace: localregistry:5000/openshift4
      ceph_node_exporter_tag: v4.1
      ceph_prometheus_image: ose-prometheus
      ceph_prometheus_namespace: localregistry:5000/openshift4
      ceph_prometheus_tag: 4.1
      ceph_tag: latest
      name_prefix: openstack-
      name_suffix: ''
      namespace: localregistry:5000/rhosp-rhel8
      neutron_driver: ovn
      rhel_containers: false
      tag: '16.0'
    tag_from_label: '{version}-{release}'

# 参见
[0] RHOSP 13: Creating a True Offline Container Image Registry https://mojo.redhat.com/community/communities-at-red-hat/infrastructure/cloud-platforms-community-of-practice/openstack-community-of-practice-deploy-deliver-architect/blog/2019/06/19/rhosp-13-creating-a-true-offline-container-image-registry

[1]  [RHOSP16] Back to the disconnected registry https://mojo.redhat.com/community/communities-at-red-hat/infrastructure/cloud-platforms-community-of-practice/openstack-community-of-practice-deploy-deliver-architect/blog/2020/04/17/rhosp16-back-to-the-disconnected-registry

[2] OpenStack offline registry Ansible role https://gitlab.consulting.redhat.com/tbonds/ansible-role-rhospregistry 
```

### 在 Undercloud 上安装虚拟化软件，准备 Helper 虚拟机
```
加载 rhel 8.2 iso 到 /mnt
[root@director ~]# mount -o loop  /software/openstack/os/rhel-8.2-x86_64-dvd.iso /mnt

生成本地 yum 源
[root@director ~]# cat > /etc/yum.repos.d/local.repo << EOF
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

安装虚拟化软件
[root@director ~]# dnf module install virt
[root@director ~]# dnf install virt-install
[root@director ~]# systemctl start libvirtd

创建 bridge 类型的 conn br0
[root@undercloud #] nmcli con add type bridge con-name br0 ifname br0

(可选) 根据实际情况设置 bridge.stp，有时可能因为 bridge.stp 设置导致网络通信不正常
[root@undercloud #] nmcli con mod br0 bridge.stp no

修改 vlan 类型的 conn ens35f1.10 设置 master 为 br0 （参考）
[root@undercloud #] nmcli con mod ens35f1.10 connection.master br0 connection.slave-type 'bridge'

为 br0 设置 ip 地址（参考）
[root@undercloud #] nmcli con mod br0 \
    connection.autoconnect 'yes' \
    connection.autoconnect-slaves 'yes' \
    ipv4.method 'manual' \
    ipv4.address '192.168.10.41/24' \
    ipv4.gateway '192.168.10.1' \
    ipv4.dns '119.29.29.29'

[root@undercloud #] nmcli con up br0
[root@undercloud #] nmcli con down br0 && nmcli con up br0

查看参数状态
[root@undercloud #] nmcli con show br0

创建新的 libvirt network br0
cat << EOF > /root/host-bridge.xml
<network>
  <name>br0</name>
  <forward mode="bridge"/>
  <bridge name="br0"/>
</network>
EOF

virsh net-define /root/host-bridge.xml
virsh net-start br0
virsh net-autostart --network br0
virsh net-autostart --network default --disable
virsh net-destroy default

创建 helper 虚拟机的例子
# virt-install --name=helper-undercloud --vcpus=2 --ram=4096 --disk path=/var/lib/libvirt/images/helper-undercloud.qcow2,bus=virtio,size=100 --os-variant rhel8.0 --network network=br0,model=virtio --boot menu=on --graphics none --location  /software/openstack/rhel-8.2-x86_64-dvd.iso --initrd-inject /tmp/ks.cfg --extra-args='ks=file:/ks.cfg console=ttyS0 nameserver=119.29.29.29 ip=192.168.10.42::192.168.10.1:255.255.255.0:helper.example.com:enp1s0:none'

# ks-helper.cfg 可参考以下链接，根据实际情况在线生成
https://github.com/wangjun1974/ospinstall/blob/main/ks-helper.cfg.example.md

样例
[root@undercloud ~]# cat > /tmp/ks.cfg <<'EOF'
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
network --device=enp1s0 --hostname=helper.example.com --bootproto=static --ip=192.168.10.42 --netmask=255.255.255.0 --gateway=192.168.10.1 --nameserver=119.29.29.29
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
%end
EOF

```
