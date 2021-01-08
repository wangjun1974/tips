### 软件准备

需要准备的操作系统镜像
RHEL-8.2

需要准备的软件频道参见：
https://access.redhat.com/documentation/zh-cn/red_hat_openstack_platform/16.1/html/director_installation_and_usage/undercloud-repositories



在下载服务器上执行，订阅所需软件频道
```
subscription-manager repos --disable=*
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhel-8-for-x86_64-highavailability-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms --enable=openstack-16.1-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms
```

在下载服务器上，生成同步软件频道的脚本
```
mkdir -p /repos/rhel8osp
pushd /repos/rhel8osp

# 安装 createrepo
yum install -y createrepo

cat > /root/OSP16_1_repo_sync_up.sh <<'EOF'
#!/bin/bash

localPath="/repos/rhel8osp/"
fileConn="/getPackage/"

## sync following yum repos 
# rhel-8-for-x86_64-baseos-eus-rpms
# rhel-8-for-x86_64-appstream-eus-rpms
# rhel-8-for-x86_64-highavailability-eus-rpms
# ansible-2.9-for-rhel-8-x86_64-rpms
# openstack-16.1-for-rhel-8-x86_64-rpms
# fast-datapath-for-rhel-8-x86_64-rpms
# rhceph-4-tools-for-rhel-8-x86_64-rpms

for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms
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
/usr/bin/nohup /bin/bash OSP16_1_repo_sync_up.sh &

# 同步完之后把 /repos/rhel8osp 目录打包，下载作为离线时使用的软件仓库

```

### 镜像仓库准备

OSP 在部署时需要访问镜像仓库，在一般的部署下，这个镜像仓库会部署在 undercloud 上

```
# 安装时需使用 rhel-8.2-x86_64-dvd.iso
# 这个 ISO 可在红帽官网下载
# https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.2/x86_64/product-software

virt-install --name=jwang-rhel82-undercloud --vcpus=4 --ram=32768 \
--disk path=/data/kvm/jwang-rhel82-undercloud.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=openshift4v6,model=virtio \
--boot menu=on --cdrom /root/jwang/isos/rhel-8.2-x86_64-dvd.iso 
```
