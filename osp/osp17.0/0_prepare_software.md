### 软件准备

需要准备的操作系统镜像
RHEL-9.0

需要准备的软件频道参见：
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/17.0/html/director_installation_and_usage/assembly_planning-your-undercloud#ref_undercloud-repositories_planning-your-undercloud


安装虚拟机
```
# kickstart 文件参考 https://github.com/wangjun1974/tips/blob/master/os/miscs.md#rhel9-kickstart-file

生成 undercloud 所使用的 ks.cfg 文件
cat > /tmp/ks.cfg <<'EOF'
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
network --device=ens3 --hostname=undercloud.example.com --bootproto=static --ip=192.168.8.21 --netmask=255.255.255.0 --gateway=192.168.8.1 --nameserver=192.168.8.1
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
createrepo
vim
httpd
%end
EOF

qemu-img create -f qcow2 -o preallocation=metadata /data/kvm/jwang-rhel90-undercloud.qcow2 120G

virt-install --name=jwang-rhel90-undercloud --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-rhel90-undercloud.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--network network=provisioning,model=virtio --network network=default,model=virtio \
--boot menu=on --location /root/jwang/isos/rhel-9.0-x86_64-dvd.iso \
--initrd-inject /tmp/ks.cfg \
--extra-args='inst.ks=file:/ks.cfg'

RHEL 9.0 的 kickstart 文件语法有改变，
注意：ks 变为了 inst.ks , ksdevice 变为了 inst.ksdevice, dns 变为了 nameserver
```

在下载服务器上，生成同步软件频道的脚本
```

## sync following yum repos 
# rhel-9-for-x86_64-baseos-eus-rpms
# rhel-9-for-x86_64-appstream-eus-rpms
# rhel-9-for-x86_64-highavailability-eus-rpms
# openstack-17-for-rhel-8-x86_64-rpms
# openstack-17-tools-for-rhel-9-x86_64-rpms
# fast-datapath-for-rhel-9-x86_64-rpms
# rhceph-5-tools-for-rhel-9-x86_64-rpms


### Yum 仓库和镜像仓库准备
OSP 在部署时需要访问镜像仓库，在一般的部署下，这个镜像仓库会部署在 helper 上

# 1. 安装时需使用 rhel-9.0-x86_64-dvd.iso 作为操作系统的安装介质
# 这个 ISO 可在红帽官网下载
# https://access.redhat.com/downloads/content/479/ver=/rhel---9/9.0/x86_64/product-software

# 2. 安装操作系统 

# 3. 安装完操作系统之后，执行以下配置
# 3.1 以 root 用户登录系统
# 3.2 创建 stack 用户
[root@undercloud ~]# useradd stack

# 3.3 为 stack 用户设置口令
[root@undercloud ~]# passwd stack

# 3.4 为 Stack 用户设置 sudo 
[root@undercloud ~]# echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
[root@undercloud ~]# chmod 0440 /etc/sudoers.d/stack

# 3.5 切换为 stack 用户
[root@undercloud ~]# su - stack
[stack@undercloud ~]$

# 3.6 创建 images 和 templates 目录
[stack@undercloud ~]$ mkdir ~/images
[stack@undercloud ~]$ mkdir ~/templates

# 3.7 设置主机名并检查主机名
[stack@undercloud ~]$ sudo hostnamectl set-hostname undercloud.example.com
[stack@undercloud ~]$ sudo hostnamectl set-hostname --transient undercloud.example.com

# 3.8 编辑 /etc/hosts 文件，添加 undercloud.example.com 对应的记录
[stack@undercloud ~]$ sudo -i
[root@undercloud ~]# cat >> /etc/hosts << 'EOF'
10.0.11.27 undercloud.example.com undercloud
EOF
[root@undercloud ~]# exit
[stack@undercloud ~]$

# 禁用远程 yum 源，设置本地 yum 源
[root@undercloud repos]# subscription-manager repos --disable=*
[root@undercloud repos]# mkdir -p /etc/yum.repos.d/backup
[root@undercloud repos]# echo y | mv /etc/yum.repos.d/redhat.repo /etc/yum.repos.d/backup
[root@undercloud repos]# sed -ie 's|enabled=1|enabled=0|' /etc/yum/pluginconf.d/subscription-manager.conf

[root@undercloud repos]# > /etc/yum.repos.d/osp.repo 
[root@undercloud repos]# for i in rhel-9-for-x86_64-baseos-eus-rpms rhel-9-for-x86_64-appstream-eus-rpms rhel-9-for-x86_64-highavailability-eus-rpms openstack-17-for-rhel-9-x86_64-rpms fast-datapath-for-rhel-9-x86_64-rpms
do
cat >> /etc/yum.repos.d/osp.repo << EOF
[$i]
name=$i
baseurl=http://192.168.122.3/repos/osp17.0/$i/
enabled=1
gpgcheck=0

EOF
done

# 更新并且重启
[stack@undercloud ~]$ sudo dnf update -y
[stack@undercloud ~]$ sudo reboot

# director
[stack@undercloud ~]$ sudo dnf install -y python3-tripleoclient

# 创建 undercloud.conf 文件
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

# 假设在离线环境中配置了 container registry helper.example.com:5000
# 这个 regsitry 没有配置认证
cat > containers-prepare-parameter.yaml <<EOF
parameter_defaults:
  ContainerImagePrepare:
  - push_destination: true
    set:
      ceph_namespace: helper.example.com:5000/rhceph
      ceph_image: rhceph-5-rhel8
      ceph_tag: latest
      ceph_grafana_image: rhceph-5-dashboard-rhel8
      ceph_grafana_namespace: helper.example.com:5000/rhceph
      ceph_grafana_tag: 5
      ceph_alertmanager_image: ose-prometheus-alertmanager
      ceph_alertmanager_namespace: helper.example.com:5000/openshift4
      ceph_alertmanager_tag: v4.12
      ceph_node_exporter_image: ose-prometheus-node-exporter
      ceph_node_exporter_namespace: helper.example.com:5000/openshift4
      ceph_node_exporter_tag: v4.12
      ceph_prometheus_image: ose-prometheus
      ceph_prometheus_namespace: helper.example.com:5000/openshift4
      ceph_prometheus_tag: v4.12
      name_prefix: openstack-
      name_suffix: ''
      namespace: helper.example.com:5000/rhosp-rhel9
      neutron_driver: ovn
      rhel_containers: false
      tag: '17.0'
    tag_from_label: '{version}-{release}'
EOF

# 修改 /usr/share/ansible/roles/chrony/defaults/main.yml 文件
# 添加本地 chrony_ntp_servers
---
chrony_debug: False
chrony_role_action: all
chrony_global_server_settings: iburst
chrony_ntp_servers: 
    - 192.168.122.1
chrony_ntp_pools: []
chrony_ntp_peers: []
chrony_bind_addresses:
    - 127.0.0.1
    - ::1
chrony_acl_rules: []
chrony_service_name: chronyd
chrony_manage_service: True
chrony_manage_package: True
chrony_service_state: started
chrony_extra_options: []


# 安装 undercloud
[stack@undercloud ~]$ time openstack undercloud install

# 在安装完 undercloud 之后，设置 chronyd 服务
# 生成以 undercloud 本地时间为时间源的时间服务器配置
[stack@undercloud ~]$ sudo -i 
[stack@undercloud ~]# cat > /etc/chrony.conf << EOF
server 192.0.2.1 iburst
bindaddress 192.0.2.1
allow all
local stratum 4
EOF
[stack@undercloud ~]# exit

# 启用并启动 chronyd 服务
[stack@undercloud ~]$ sudo systemctl enable chronyd && sudo systemctl restart chronyd

# 查看时间源
[stack@undercloud ~]$ chronyc -n sources
[stack@undercloud ~]$ chronyc -n tracking

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
cat >> /etc/hosts <<EOF
192.168.122.3 helper.example.com
EOF

安装 registry 基础软件
cat > /etc/yum.repos.d/w.repo << EOF
[rhel-8-for-x86_64-baseos-eus-rpms]
name=rhel-8-for-x86_64-baseos-eus-rpms
baseurl=http://192.168.122.2/repos/osp16.2/rhel-8-for-x86_64-baseos-eus-rpms/
enabled=1
gpgcheck=0

[rhel-8-for-x86_64-appstream-eus-rpms]
name=rhel-8-for-x86_64-appstream-eus-rpms
baseurl=http://192.168.122.2/repos/osp16.2/rhel-8-for-x86_64-appstream-eus-rpms/
enabled=1
gpgcheck=0
EOF

yum install -y podman httpd httpd-tools wget jq

创建目录
mkdir -p /opt/registry/{certs,data}

将在其他服务器上准备好的 registry 压缩包解压缩
tar zxf /tmp/osp16.2-poc-registry-2021-09-27.tar.gz -C /

生成 registry 证书，如果是解压缩 registry 压缩包，这个步骤可以跳过
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

如果是离线导入时，脚本为 
cat > /usr/local/bin/localregistry.sh << 'EOF'
#!/bin/bash
podman run --name poc-registry -d -p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
localhost/docker-registry:latest
EOF

设置脚本可执行
chmod +x /usr/local/bin/localregistry.sh

启动镜像服务
/usr/local/bin/localregistry.sh

验证镜像服务可访问
curl https://helper.example.com:5000/v2/_catalog
cd /root

生成容器对应的 systemd 服务
podman generate systemd poc-registry >> /etc/systemd/system/podman.poc-registry.service
systemctl enable podman.poc-registry.service
systemctl restart podman.poc-registry.service
curl https://helper.example.com:5000/v2/_catalog

拷贝 helper 的证书到 undercloud
cat >> /etc/hosts <<EOF
192.168.122.2 undercloud.example.com
EOF

生成 ssh key pair
ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''
ssh-copy-id undercloud.example.com

拷贝证书到 undercloud
scp /opt/registry/certs/domain.crt undercloud.example.com:/etc/pki/ca-trust/source/anchors/
ssh undercloud.example.com update-ca-trust

ssh undercloud.example.com 
[root@undercloud ~]# cat >> /etc/hosts <<EOF
192.168.122.3 helper.example.com
EOF

等待 undercloud 执行完 openstack undercloud install 之后，更新 yum repo 指向 8787 端口
sed -i 's|192.168.122.2|192.168.122.2:8787|g' /etc/yum.repos.d/w.repo
```

准备离线镜像
```
在镜像下载服务器上执行以下命令

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
