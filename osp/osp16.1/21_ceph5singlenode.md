### RHCS5.0 single node cluster 
```
# 安装虚拟机 jwang-ceph04
# rhel 8.4
# 如果之前未清理磁盘可以执行
# sgdisk --delete /dev/sda
# sgdisk --delete /dev/sdb
# sgdisk --delete /dev/sdc
# ks=http://10.66.208.115/jwang-ceph04-ks.cfg nameserver=10.64.63.6 ip=10.66.208.125::10.66.208.254:255.255.255.0:jwang-ceph04.example.com:ens3:none

# 生成 ks.cfg - jwang-ceph04
cat > jwang-ceph04-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
halt
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
ignoredisk --only-use=sda
autopart
network --device=ens3 --hostname=jwang-ceph04.example.com --bootproto=static --ip=10.66.208.125 --netmask=255.255.255.0 --gateway=10.66.208.254 --nameserver=10.64.63.6
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
gdisk
openssl-perl
%end
EOF

# 离线 yum repo 和离线 container registry 参考百度网盘

# 下载离线 yum repo

# 解压缩离线 yum repo
tar zxvf rhcs5-yum-repos-2021-12-02.tar.gz -C /

# 使用本地 repo
> /etc/yum.repos.d/local.repo 
for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-appstream-rpms ansible-2.9-for-rhel-8-x86_64-rpms rhceph-5-tools-for-rhel-8-x86_64-rpms 
do
cat >> /etc/yum.repos.d/local.repo << EOF
[$i]
name=$i
baseurl=file:///var/www/html/repos/rhcs5/$i/
enabled=1
gpgcheck=0

EOF
done

# 设置 /etc/hosts，添加本机和镜像服务器
sed -i '/jwang-ceph04.example.com/d' /etc/hosts
cat >> /etc/hosts <<EOF
10.66.208.125   jwang-ceph04.example.com    jwang-ceph04
EOF
cat >> /etc/hosts <<EOF
10.66.208.121   helper.example.com
EOF

# 更新系统
dnf makecache
dnf update -y

# 安装 cephadm 和 podman
dnf install -y cephadm podman

# 拷贝 local registry 证书，建立证书信任
[root@jwang-ceph04 ~]# scp 10.66.208.121:/opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors 
domain.crt                                                                                               100% 2114   688.3KB/s   00:00    
[root@jwang-ceph04 ~]# update-ca-trust extract

# 登陆 local registry
[root@jwang-ceph04 ~]# podman login helper.example.com:5000 
Username: 
Password: 
Login Succeeded!

# 生成 ssh keypair 
ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
ssh-copy-id 10.66.208.125 

# 在对应节点上手工执行 podman pull 和 podman tag
# 需要在每个节点上做一遍
[root@jwang-ceph04 ~]# podman pull helper.example.com:5000/openshift4/ose-prometheus-node-exporter:v4.6
[root@jwang-ceph04 ~]# podman tag helper.example.com:5000/openshift4/ose-prometheus-node-exporter:v4.6 registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.6

[root@jwang-ceph04 rhcs5]# podman pull helper.example.com:5000/openshift4/ose-prometheus:v4.6
[root@jwang-ceph04 rhcs5]# podman tag helper.example.com:5000/openshift4/ose-prometheus:v4.6 registry.redhat.io/openshift4/ose-prometheus:v4.6

[root@jwang-ceph04 rhcs5]# podman pull helper.example.com:5000/openshift4/ose-prometheus-alertmanager:v4.6
[root@jwang-ceph04 rhcs5]# podman tag helper.example.com:5000/openshift4/ose-prometheus-alertmanager:v4.6 registry.redhat.io/openshift4/ose-prometheus-alertmanager:v4.6

[root@jwang-ceph04 rhcs5]# podman pull helper.example.com:5000/rhceph/rhceph-5-dashboard-rhel8:5 
[root@jwang-ceph04 rhcs5]# podman tag helper.example.com:5000/rhceph/rhceph-5-dashboard-rhel8:5 registry.redhat.io/rhceph/rhceph-5-dashboard-rhel8:5
[root@jwang-ceph04 rhcs5]# podman tag helper.example.com:5000/rhceph/rhceph-5-dashboard-rhel8:5 registry.redhat.io/rhceph/rhceph-5-dashboard-rhel8:latest

# 使用本地镜像，创建集群
cephadm --image helper.example.com:5000/rhceph/rhceph-5-rhel8:latest bootstrap --mon-ip 10.66.208.125 --allow-fqdn-hostname

# 设置全局参数 osd_crush_chooseleaf_type, osd_pool_default_size, osd_pool_default_min_size
cephadm shell
[ceph: root@jwang-ceph04 /]# ceph config set global osd_crush_chooseleaf_type 0
[ceph: root@jwang-ceph04 /]# ceph config set global osd_pool_default_size 1
[ceph: root@jwang-ceph04 /]# ceph config set global osd_pool_default_min_size 1
[ceph: root@jwang-ceph04 /]# ceph config dump

# 设置命令别名
echo "alias ceph='cephadm shell -- ceph'" >> ~/.bashrc
source ~/.bashrc

# 设置时间同步
sed -i 's|pool 2.rhel.pool.ntp.org iburst|server clock.corp.redhat.com iburst|' /etc/chrony.conf
systemctl restart chronyd
chronyc -n sources

# 部署 mon 和 mgr
ceph orch ls
ceph orch apply mon --placement="1 jwang-ceph04.example.com"
ceph orch apply mgr --placement="1 jwang-ceph04.example.com"
ceph orch ls

# 查看可用设备
ceph orch device ls --refresh

# 手工添加设备
ceph orch daemon add osd jwang-ceph04.example.com:/dev/sdb
ceph orch daemon add osd jwang-ceph04.example.com:/dev/sdc
ceph orch daemon add osd jwang-ceph04.example.com:/dev/sdd

# 获取 pool 的信息
[ceph: root@jwang-ceph04 /]# ceph osd dump | grep pool 
pool 1 'device_health_metrics' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 1 pgp_num 1 autoscale_mode on last_change 22 flags hashpspool stripe_width 0 pg_num_min 1 application mgr_devicehealth

# 设置 pool 的 min_size
[ceph: root@jwang-ceph04 /]# ceph osd pool set device_health_metrics min_size 1 
set pool 1 min_size to 1

# 检查 ceph 的 health 状态
[ceph: root@jwang-ceph04 /]# ceph health detail        
HEALTH_WARN 1 failed cephadm daemon(s)
[WRN] CEPHADM_FAILED_DAEMON: 1 failed cephadm daemon(s)
    daemon node-exporter.jwang-ceph04 on jwang-ceph04.example.com is in error state

# 为节点打标签 osd
ceph orch host label add jwang-ceph04.example.com osd

# 检查 ceph 的 health 状态
[ceph: root@jwang-ceph04 /]# ceph health detail        
HEALTH_WARN 1 failed cephadm daemon(s)
[WRN] CEPHADM_FAILED_DAEMON: 1 failed cephadm daemon(s)
    daemon node-exporter.jwang-ceph04 on jwang-ceph04.example.com is in error state

# 检查 node-exporter unit 文件内容
[root@jwang-ceph04 ~]# cat /var/lib/ceph/0c1839ae-5349-11ec-9989-001a4a16016f/node-exporter.jwang-ceph04/unit.run 
set -e
# node-exporter.jwang-ceph04
! /bin/podman rm -f ceph-0c1839ae-5349-11ec-9989-001a4a16016f-node-exporter.jwang-ceph04 2> /dev/null
! /bin/podman rm -f ceph-0c1839ae-5349-11ec-9989-001a4a16016f-node-exporter-jwang-ceph04 2> /dev/null
! /bin/podman rm -f --storage ceph-0c1839ae-5349-11ec-9989-001a4a16016f-node-exporter-jwang-ceph04 2> /dev/null
! /bin/podman rm -f --storage ceph-0c1839ae-5349-11ec-9989-001a4a16016f-node-exporter.jwang-ceph04 2> /dev/null
/bin/podman run --rm --ipc=host --net=host --init --name ceph-0c1839ae-5349-11ec-9989-001a4a16016f-node-exporter-jwang-ceph04 --user 65534 -d --log-driver journald --conmon-pidfile /run/ceph-0c1839ae-5349-11ec-9989-001a4a16016f@node-exporter.jwang-ceph04.service-pid --cidfile /run/ceph-0c1839ae-5349-11ec-9989-001a4a16016f@node-exporter.jwang-ceph04.service-cid -e CONTAINER_IMAGE=registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.6 -e NODE_NAME=jwang-ceph04.example.com -e CEPH_USE_RANDOM_NONCE=1 -e TCMALLOC_MAX_TOTAL_THREAD_CACHE_BYTES=134217728 -v /proc:/host/proc:ro -v /sys:/host/sys:ro -v /:/rootfs:ro registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.6 --no-collector.timex

# 解决方法是在对应节点上手工执行 podman pull 和 podman tag
[root@jwang-ceph04 ~]# podman pull helper.example.com:5000/openshift4/ose-prometheus-node-exporter:v4.6
[root@jwang-ceph04 ~]# podman tag helper.example.com:5000/openshift4/ose-prometheus-node-exporter:v4.6 registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.6

# 部署 cephfs，以下命令的执行顺序还需要调整
ceph orch apply mds cephfs --placement="1 jwang-ceph04.example.com"
ceph orch ls
ceph fs volume create cephfs
ceph fs set cephfs standby_count_wanted 0
ceph fs ls

```

制作离线 yum repo 的步骤
```
# 注册系统到 rhn
subscription-manager register
subscription-manager refresh
subscription-manager list --available --matches 'Red Hat Ceph Storage'
subscription-manager attach --pool=8a85f99979908877017a0d85b3ab3c37
subscription-manager repos --disable=*
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhceph-5-tools-for-rhel-8-x86_64-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms

# rhcs5 软件仓库同步脚本
[root@helper repos]# pwd
/var/www/html/repos
[root@helper repos]# cat > rhcs5_repo_sync_up.sh <<EOF
#!/bin/bash

localPath="/var/www/html/repos/rhcs5/"
fileConn="/getPackage/"

## sync following yum repos 
# rhel-8-for-x86_64-baseos-rpms
# rhel-8-for-x86_64-appstream-rpms
# ansible-2.9-for-rhel-8-x86_64-rpms
# rhceph-5-tools-for-rhel-8-x86_64-rpms

for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-appstream-rpms ansible-2.9-for-rhel-8-x86_64-rpms rhceph-5-tools-for-rhel-8-x86_64-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --downloadcomps --download-metadata

  #echo "create repo $i..."
  #time createrepo -g $(ls "$localPath"$i/repodata/*comps.xml) --update --skip-stat --cachedir /tmp/empty-cache-dir "$localPath"$i

done

exit 0
EOF

# 下载离线 yum repo
[root@helper repos]# /usr/bin/nohup /bin/bash -x rhcs5_repo_sync_up.sh &

# 查看下载过程中 repodata 更新情况
watch "ls -ltr \$(ls -ltr | tail -1 | awk '{print \$9}')/\$(ls -ltr \$(ls -ltr | tail -1 | awk '{print \$9}') | tail -1 | awk '{print \$9}')"
```

参考链接
```
# https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/5/html-single/installation_guide/index#configuring-a-custom-registry-for-disconnected-installation_install
# https://docs.ceph.com/en/latest/cephadm/install/
```