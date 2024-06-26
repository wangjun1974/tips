### 在物理机里安装 osp 时做的准备工作

1. 配置并且记录 IPMI 信息

在硬件上配置并且记录 IPMI 的 IP，端口，用户名及口令

|节点|IPMI地址|用户名|口令|
|---|---|---|---|
|controller0|192.168.1.10|admin|password|
|controller1|192.168.1.11|admin|password|
|controller2|192.168.1.12|admin|password|
|compute0|192.168.1.13|admin|password|
|compute1|192.168.1.14|admin|password|
|compute2|192.168.1.15|admin|password|
|cephstorage0|192.168.1.16|admin|password|
|cephstorage1|192.168.1.17|admin|password|
|cephstorage2|192.168.1.18|admin|password|

2. 配置交换机
以下网络是 OpenStack 会使用到的内部网络

需要明确以下问题：
* osp 集群对应几个交换机
* 每个网络所在的交换机是什么，是否共用交换机
* 每个网络在服务器这边对应哪个或哪几个网口

以下是一个例子

|名字|vlan|网段|备注说明|对应服务器网口|
|---|---|---|---|---|
|ControlPlane|无|192.0.2.0/24|部署网络|网口1|
|External|10|10.0.0.0/24|overcloud 的 External API 和 floating ip 所在的网络|网口2和网口3|
|InternalAPI|20|172.16.2.0/24|overcloud 的 Internal API 所在的网络|网口2和网口3|
|Tenant|50|172.16.0.0/24|overcloud 租户 overlay 隧道所在的网络|网口2和网口3|
|Storage|30|172.16.1.0/24|overcloud 存储网络，内部客户端通过此网络访问存储|网口2和网口3|
|StorageMgmt|40|172.16.3.0/24|overcloud 内部存储管理网络|网口2和网口3|

### 在虚拟机里安装 osp 时做的准备工作

硬件准备：定义虚拟交换机
```
# 定义 provisioning 虚拟网络
cat > /tmp/provisioning.xml <<EOF
<network>
  <name>provisioning</name>
  <ip address="192.0.2.254" netmask="255.255.255.0"/>
</network>
EOF

virsh net-define /tmp/provisioning.xml
virsh net-autostart provisioning
virsh net-start provisioning

# 根据需要禁用虚拟网络的 DHCP，以下是在虚拟网络 default 上，禁止 DHCP 时的例子 
if(virsh net-dumpxml default | grep dhcp &>/dev/null); then
      virsh net-update default delete ip-dhcp-range "<range start='192.168.122.2' end='192.168.122.254'/>" --live --config || { echo "Unable to disable DHCP on default network"; return 1; }
fi


```

硬件准备：创建虚拟机磁盘
```
# 定义环境变量
LIBVIRT_D="/data/kvm"
CTRL_N="ctrl01 ctrl02 ctrl03"
COMPT_N="compute01 compute02"
CEPH_N="ceph01 ceph02 ceph03"
ALL_N="$CTRL_N $COMPT_N $CEPH_N"
OVERCLOUD_DISK_SIZE='100'
CEPH_OSD_DISK=3
CEPH_OSD_DISK_SIZE='100'

cd ${LIBVIRT_D}/

for i in $ALL_N;
do
  echo "Creating a ${OVERCLOUD_DISK_SIZE}GB disk image for node $i..."
  qemu-img create -f qcow2 -o preallocation=metadata jwang-overcloud-$i.qcow2 ${OVERCLOUD_DISK_SIZE}G || { echo "Unable to define disk jwang-overcloud-$i.qcow2"; return 1; }
done

for i in $CEPH_N;
do
    echo "Creating additional disk's image(s) for node $i..."
    for((n=1;n<=$CEPH_OSD_DISK;n+=1)); do
      echo "Creating additional ${CEPH_OSD_DISK_SIZE}GB disk $n - ${LIBVIRT_D}/jwang-overcloud-${i}-storage-${n}.qcow2"
    qemu-img create -f qcow2 -o preallocation=metadata jwang-overcloud-${i}-storage-${n}.qcow2 ${CEPH_OSD_DISK_SIZE}G || { echo "Unable to define disk jwang-overcloud-$i-storage-${n}.qcow2"; return 1; }
    done
    echo
done


```

定义控制节点虚拟机
```
# 定义环境变量
CTRL_N="ctrl01 ctrl02 ctrl03"
CTRL_MEM='12288'
CTRL_VCPU='4'
LIBVIRT_D="/data/kvm"

# 创建控制节点虚拟机
for i in $CTRL_N;
do
    echo "Defining node jwang-overcloud-$i..."
    virt-install --ram $CTRL_MEM --vcpus $CTRL_VCPU --os-variant rhel7 \
    --disk path=${LIBVIRT_D}/jwang-overcloud-$i.qcow2,device=disk,bus=virtio,format=qcow2 \
    --noautoconsole --vnc --network network:provisioning \
    --network network:default --network network:default \
    --name jwang-overcloud-$i \
    --cpu SandyBridge,+vmx \
    --dry-run --print-xml > /tmp/jwang-overcloud-$i.xml;

    virsh define --file /tmp/jwang-overcloud-$i.xml || { echo "Unable to define jwang-overcloud-$i"; return 1; }
done

```

定义计算节点虚拟机
```
# 定义环境变量
COMPT_N="compute01 compute02"
COMPT_MEM='6144'
COMPT_VCPU='4'
LIBVIRT_D="/data/kvm"

# 创建计算节点虚拟机
for i in $COMPT_N;
do
    echo "Defining node jwang-overcloud-$i..."
    virt-install --ram $COMPT_MEM --vcpus $COMPT_VCPU --os-variant rhel7 \
    --disk path=${LIBVIRT_D}/jwang-overcloud-$i.qcow2,device=disk,bus=virtio,format=qcow2 \
    --noautoconsole --vnc --network network:provisioning \
    --network network:default --network network:default \
    --name jwang-overcloud-$i \
    --cpu SandyBridge,+vmx \
    --dry-run --print-xml > /tmp/jwang-overcloud-$i.xml;

    virsh define --file /tmp/jwang-overcloud-$i.xml || { echo "Unable to define jwang-overcloud-$i"; return 1; }
done

```

定义存储节点虚拟机
```
CEPH_N="ceph01 ceph02 ceph03"
CEPH_MEM='4096'
CEPH_VCPU='4'
LIBVIRT_D='/data/kvm'
CEPH_OSD_DISK=3

for i in $CEPH_N;
do
    echo "Defining node jwang-overcloud-$i..."
    virt-install --ram $CEPH_MEM --vcpus $CEPH_VCPU --os-variant rhel7 \
    --disk path=${LIBVIRT_D}/jwang-overcloud-$i.qcow2,device=disk,bus=virtio,format=qcow2 \
    $(for((n=1;n<=$CEPH_OSD_DISK;n+=1)); do echo -n "--disk path=${LIBVIRT_D}/jwang-overcloud-$i-storage-${n}.qcow2,device=disk,bus=virtio,format=qcow2 "; done) \
    --noautoconsole --vnc --network network:provisioning \
    --network network:default --network network:default \
    --name jwang-overcloud-$i \
    --cpu SandyBridge,+vmx \
    --dry-run --print-xml > /tmp/jwang-overcloud-$i.xml

    virsh define --file /tmp/jwang-overcloud-$i.xml || { echo "Unable to define jwang-overcloud-$i"; return 1; }
done
```


```
# 在 Hypervisor 上配置加载 dummy 内核模块
echo dummy > /etc/modules-load.d/dummy.conf
modprobe dummy

# 生成 ifcfg-dummy0 
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-dummy0
DEVICE=dummy0
ONBOOT=yes
NM_CONTROLLED="no"
IPADDR=192.168.1.1
PREFIX=24
$(for ((i=2;i<=20;i++)); do
echo IPADDR${i}=192.168.1.${i}
echo PREFIX${i}=24
done)
EOF

# 启动 dummy0
ifup dummy0

# 如果 Hypervisor 配置了 FirewallD
firewall-cmd --add-port=3128/tcp
firewall-cmd --permanent --add-port=3128/tcp

firewall-cmd --add-port=623/tcp
firewall-cmd --permanent --add-port=623/tcp

# 如果 Hypervisor 配置了 iptables
iptables -I INPUT 1 -m tcp -p tcp --dport 3128 -j ACCEPT
iptables -I INPUT 1 -m tcp -p tcp --dport 623 -j ACCEPT

# RHEL7 Hypervisor 安装 vbmc 和 ipmitool 软件包
yum install -y python2-virtualbmc ipmitool

# 配置 vbmc 
echo "Creating VirtualBMC systemd unit file"
cat << EOF > /usr/lib/systemd/system/virtualbmc@.service
[Unit]
Description=VirtualBMC %i service
After=network.target libvirtd.service

[Service]
Type=forking
PIDFile=/root/.vbmc/%i/pid
ExecStart=/bin/vbmc start %i
ExecStop=/bin/vbmc stop %i
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Adding nodes to Virtual BMC..."
count=1
for i in $(virsh list --all | awk ' /overcloud/ {print $2}'); do
    echo "Adding node $i to Virtual BMC"
    vbmc add $i --address 192.168.1.${count} --username admin --password redhat || { echo "Unable to add $i to Virtual BMC..."; return 1; }

    echo "Starting Virtual BMC service for node $i"
    systemctl enable --now virtualbmc@${i} || { echo "Unable to start Virtual BMC service for $i..."; return 1; }

    # Dammit!!!
    sleep 1

    echo "Testing IPMI connection on node $i"
    ipmitool -I lanplus -U admin -P redhat  -H 192.168.1.${count}  power status || { echo "IPMI test on node $i failed..."; return 1; }

    count=$((count+1))
done

# 配置 Hypervisor 启用 nested virtualization
echo "Configuring /etc/modprobe.d/kvm_intel.conf"
cat << EOF > /etc/modprobe.d/kvm_intel.conf
options kvm-intel nested=1
options kvm-intel enable_shadow_vmcs=1
options kvm-intel enable_apicv=1
options kvm-intel ept=1
EOF

modprobe -r kvm_intel
modprobe kvm_intel

cat /sys/module/kvm_intel/parameters/nested
Y





```



### 安装 Helper
```
cat > /tmp/ks-helper.cfg <<'EOF'
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
network --device=ens3 --hostname=helper.example.com --bootproto=static --ip=192.168.122.3 --netmask=255.255.255.0 --gateway=192.168.122.1 --nameserver=192.168.122.1
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
%end
EOF


# 安装 helper 服务器
qemu-img create -f qcow2 -o preallocation=metadata /data/kvm/jwang-rhel90-helper-undercloud.qcow2 120G
virt-install --name=jwang-rhel90-helper-undercloud --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-rhel90-helper-undercloud.qcow2,bus=virtio,size=100 \
--os-variant rhel8.0 --network network=default,model=virtio \
--boot menu=on --location /root/jwang/isos/rhel-9.0-x86_64-dvd.iso \
--initrd-inject /tmp/ks-helper.cfg \
--extra-args='ks=file:/ks-helper.cfg'

# 配置 yum 源
# 根据现场实际情况配置
# 这里用 undercloud 提供的 yum 源
# 这部分会稍后更新，使用 helper 提供的源

$ mkdir -p /repo
$ mount /dev/sr0 /repo
$ cat > /etc/yum.repos.d/local.repo << EOF
[rhel-9-for-x86_64-baseos]
name=rhel-9-for-x86_64-baseos
baseurl=file:///repo/BaseOS/
enabled=1
gpgcheck=0

[rhel-9-for-x86_64-appstream]
name=rhel-9-for-x86_64-appstream
baseurl=file:///repo/AppStream/
enabled=1
gpgcheck=0
EOF
```

注意：在下载服务器上执行，订阅所需软件频道，如果已经有下载好的 repo 压缩包，可以直接使用下载好的 repo 压缩包
注意：ansible-core 包含在 rhel-9-for-x86_64-appstream-eus-rpms 中
```
# 安装 reposync 工具
dnf install -y yum-utils 

subscription-manager release --set=9.0
subscription-manager repos --disable=*
subscription-manager repos --enable=rhel-9-for-x86_64-baseos-eus-rpms --enable=rhel-9-for-x86_64-appstream-eus-rpms --enable=rhel-9-for-x86_64-highavailability-eus-rpms --enable=openstack-17-for-rhel-9-x86_64-rpms --enable=openstack-17-tools-for-rhel-9-x86_64-rpms --enable=fast-datapath-for-rhel-9-x86_64-rpms --enable=rhceph-5-tools-for-rhel-9-x86_64-rpms
```

在下载服务器上，生成同步软件频道的脚本
```
$ yum install -y httpd 

mkdir -p /var/www/html/repos/osp17.0
pushd /var/www/html/repos/osp17.0

cat > ./OSP17_0_repo_sync_up.sh <<'EOF'
#!/bin/bash

localPath="/var/www/html/repos/osp17.0/"
fileConn="/getPackage/"

## sync following yum repos 
# rhel-9-for-x86_64-baseos-eus-rpms
# rhel-9-for-x86_64-appstream-eus-rpms
# rhel-9-for-x86_64-highavailability-eus-rpms
# openstack-17-for-rhel-8-x86_64-rpms
# openstack-17-tools-for-rhel-9-x86_64-rpms
# fast-datapath-for-rhel-9-x86_64-rpms
# rhceph-5-tools-for-rhel-9-x86_64-rpms

for i in rhel-9-for-x86_64-baseos-eus-rpms rhel-9-for-x86_64-appstream-eus-rpms rhel-9-for-x86_64-highavailability-eus-rpms openstack-17-for-rhel-8-x86_64-rpms openstack-17-tools-for-rhel-9-x86_64-rpms fast-datapath-for-rhel-9-x86_64-rpms rhceph-5-tools-for-rhel-9-x86_64-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --download-metadata

done

exit 0
EOF

# 同步软件仓库
/usr/bin/nohup /bin/bash OSP17_0_repo_sync_up.sh &

# 同步完之后把 /var/www/html/repos/osp17.0 目录打包，下载作为离线时使用的软件仓库
$ tar zcvf /tmp/osp17.0-yum-repos-$(date -I).tar.gz /var/www/html/repos/osp17.0

# 重设 selinux context
[root@helper repos]# chcon --recursive --reference=/var/www/html /var/www/html/repos

# 开启防火墙 http 端口，启动 httpd 服务器
[root@helper repos]# firewall-cmd --add-service=http
[root@helper repos]# firewall-cmd --add-service=http --permanent
[root@helper repos]# firewall-cmd --reload

# 启动 httpd 服务
[root@helper repos]# systemctl enable httpd && systemctl start httpd
```


离线镜像仓库准备 (新)
```
cat >> /etc/hosts <<EOF
192.168.122.3 helper.example.com
EOF

安装 registry 基础软件
yum install -y podman httpd httpd-tools wget jq

创建目录
mkdir -p /opt/registry/{certs,data}

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
```

准备离线镜像
```

yum install -y skopeo 

cat > /root/syncimgs <<'EOF'
#!/bin/env bash

PUSHREGISTRY=helper.example.com:5000
FORK=4

rhosp_namespace=registry.redhat.io/rhosp-rhel9
rhosp_tag=17.0
ceph_namespace=registry.redhat.io/rhceph
ceph_image=rhceph-5-rhel8
ceph_tag=latest
ceph_alertmanager_namespace=registry.redhat.io/openshift4
ceph_alertmanager_image=ose-prometheus-alertmanager
ceph_alertmanager_tag=v4.12
ceph_grafana_namespace=registry.redhat.io/rhceph
ceph_grafana_image=rhceph-5-dashboard-rhel8
ceph_grafana_tag=5
ceph_node_exporter_namespace=registry.redhat.io/openshift4
ceph_node_exporter_image=ose-prometheus-node-exporter
ceph_node_exporter_tag=v4.12
ceph_prometheus_namespace=registry.redhat.io/openshift4
ceph_prometheus_image=ose-prometheus
ceph_prometheus_tag=v4.12

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

### ceph-6
cat > /root/syncimgs-ceph-6 <<'EOF'
#!/bin/env bash

PUSHREGISTRY=helper.example.com:5000
FORK=4

rhosp_namespace=registry.redhat.io/rhosp-rhel9
rhosp_tag=17.0
ceph_namespace=registry.redhat.io/rhceph
ceph_image=rhceph-6-rhel9
ceph_tag=latest
ceph_alertmanager_namespace=registry.redhat.io/openshift4
ceph_alertmanager_image=ose-prometheus-alertmanager
ceph_alertmanager_tag=v4.12
ceph_grafana_namespace=registry.redhat.io/rhceph
ceph_grafana_image=rhceph-6-dashboard-rhel9
ceph_grafana_tag=6
ceph_node_exporter_namespace=registry.redhat.io/openshift4
ceph_node_exporter_image=ose-prometheus-node-exporter
ceph_node_exporter_tag=v4.12
ceph_prometheus_namespace=registry.redhat.io/openshift4
ceph_prometheus_image=ose-prometheus
ceph_prometheus_tag=v4.12

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
EOF
```
