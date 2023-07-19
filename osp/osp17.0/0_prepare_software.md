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
# 参见：https://access.redhat.com/solutions/4780791
# 指定 undercloud_ntp_servers
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
undercloud_ntp_servers = 192.168.122.1
custom_env_files = /home/stack/myenv.yaml

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

cat > /home/stack/myenv.yaml <<EOF
parameter_defaults:
  ChronyAclRules:
    - allow 192.0.2.0/24
EOF

# 在线环境
# 生成容器参数文件 containers-prepare-parameter.yaml
[stack@undercloud ~]$ openstack tripleo container image prepare default   --local-push-destination   --output-env-file containers-prepare-parameter.yaml

# 为 containers-prepare-parameter.yaml 添加 ContainerImageRegistryCredentials 参数
# 参见：https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html/advanced_overcloud_customization/sect-containerized_services#container-image-preparation-parameters
# 参见：https://access.redhat.com/RegistryAuthentication
# 在以下网址创建所需的 registry service accounts
# https://access.redhat.com/terms-based-registry/#/accounts
cat >> containers-prepare-parameter.yaml <<'EOF'
  ContainerImageRegistryCredentials:
    registry.redhat.io:
      6747835|jwang: eyJhbGciOiJSUzUxMi...
EOF

# 离线环境
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

# 这个步骤应该不能解决问题
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

# 查看时间源
[stack@undercloud ~]$ chronyc -n sources
[stack@undercloud ~]$ chronyc -n tracking

# 检查 undercloud 状态
[stack@undercloud ~]$ source ~/stackrc
# 查看 undercloud catalog
(undercloud) [stack@undercloud ~]$ openstack catalog list
# 查看 ip 地址
(undercloud) [stack@undercloud ~]$ ip a 
# 查看 ip 路由
(undercloud) [stack@undercloud ~]$ ip r
# 检查 ovs database
(undercloud) [stack@undercloud ~]$ sudo ovs-vsctl show
# 检查 undercloud openstack 网络配置
(undercloud) [stack@undercloud ~]$ cat /etc/os-net-config/config.json | jq .
# 检查 ovs switch 基本情况
(undercloud) [stack@undercloud ~]$ sudo ovs-vsctl show
# 查看 undercloud openstack 网络情况
(undercloud) [stack@undercloud ~]$ openstack network list
(undercloud) [stack@undercloud ~]$ openstack subnet list
(undercloud) [stack@undercloud ~]$ openstack subnet show ctlplane-subnet -f json
(undercloud) [stack@undercloud ~]$ sudo podman ps
```

