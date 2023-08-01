
```
# 创建本地安装源
mkdir -p /repo
mount /dev/sr0 /repo
cat > /etc/yum.repos.d/local.repo <<EOF
[BaseOS]
name=BaseOS
baseurl=file:///repo/BaseOS/
enabled=1
gpgcheck=0
[AppStream]
name=AppStream
baseurl=file:///repo/AppStream/
enabled=1
gpgcheck=0
EOF

# 安装 httpd
yum install -y httpd
cd /var/www/html/
mkdir repos
cd repos/

cat > repo_sync.sh <<'EOF'
#!/bin/bash
localPath="/var/www/html/repos/"
fileConn="/getPackage/"
## sync following yum repos
# rhel-8-for-x86_64-baseos-rpms
# rhel-8-for-x86_64-appstream-rpms
# rhceph-5-tools-for-rhel-8-x86_64-rpms
for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-appstream-rpms rhceph-5-tools-for-rhel-8-x86_64-rpms
do
rm -rf "$localPath"$i/repodata
echo "sync channel $i..."
reposync -n --delete --download-path="$localPath" --repoid $i --download-metadata
done
exit 0
EOF

# 注册节点，启用软件仓库，安装 reposync 工具
subscription-manager register
subscription-manager list --available --matches 'Red Hat Ceph Storage' | grep -E "Subscription Name:|Pool ID:|Entitlement Type:"
subscription-manager attach --pool=xxxx
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhceph-5-tools-for-rhel-8-x86_64-rpms
yum install -y yum-utils

# 同步软件频道
/usr/bin/nohup /bin/bash repo_sync.sh &
tail -f nohup.out

# 清理磁盘
yum install -y gdisk
sgdisk --zap-all /dev/vdb
sgdisk --zap-all /dev/vdc
sgdisk --zap-all /dev/vdd

# 扩展 /dev/rhel/root 逻辑卷
pvcreate /dev/vda4
vgextend rhel /dev/vda4
vgdisplay rhel
lvextend -l +%100Free /dev/rhel/root
lvextend -l +%100Free /dev/rhel/root /dev/vda4
lvextend -l +100%Free /dev/rhel/root /dev/vda4
xfs_growfs /

# 生成新的 local.repo 文件内容
> /etc/yum.repos.d/local.repo
for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-appstream-rpms rhceph-5-tools-for-rhel-8-x86_64-rpms ; do
cat >> /etc/yum.repos.d/local.repo << EOF
[$i]
name=$i
baseurl=file:///var/www/html/repos/$i/
enabled=1
gpgcheck=0

EOF
 done

# 更新系统
mkdir -p /etc/yum.repos.d/backup
subscription-manager config --rhsm.auto_enable_yum_plugins=0
subscription-manager repos --disable=*
mv /etc/yum.repos.d/redhat.repo /etc/yum.repos.d/backup/
yum repolist
dnf makecache
dnf update -y

# 添加 helper.example.com 到 /etc/hosts
cat >> /etc/hosts <<EOF
192.168.122.3                   helper.example.com
172.16.1.251                    jwang-ceph5-02.example.com
EOF

# 测试连通性
ping -c1 helper.example.com
ping -c1 jwang-ceph5-02.example.com

# 拷贝 registry 证书，方案 registry
ssh-keygen
ssh-copy-id 192.168.122.3
scp 192.168.122.3:/etc/pki/ca-trust/source/anchors/domain.crt /etc/pki/ca-trust/source/anchors
update-ca-trust extract
curl https://helper.example.com:5000/v2/_catalog

# 安装 cephadm
dnf install -y cephadm

# 创建目录，创建 initial-ceph.conf 文件
mkdir ceph5
cd ceph5/
cat <<EOF > initial-ceph.conf
[global]
osd_crush_choose_leaf_type = 0
EOF

# 配置 public 网络 172.16.1.0/24，vlan 30 
nmcli con add type vlan con-name ens3-vlan-30 dev ens3 id 30
nmcli con mod ens3-vlan-30 connection.autoconnect 'yes' ipv4.method 'manual' ipv4.address '172.16.1.251/24'
nmcli con down ens3-vlan-30
nmcli con up ens3-vlan-30

# 配置 cluster 网络 172.16.3.0/24, vlan 40
nmcli con add type vlan con-name ens3-vlan-40 dev ens3 id 40
nmcli con mod ens3-vlan-40 connection.autoconnect 'yes' ipv4.method 'manual' ipv4.address '172.16.3.251/24'
nmcli c down ens3-vlan-40
nmcli c up ens3-vlan-40

# 设置 alias 
echo "alias ceph='cephadm shell -- ceph'" >> ~/.bashrc
source ~/.bashrc
ceph orch host ls

# 配置时间同步
cat > /etc/chrony.conf <<EOF
pool 192.168.122.1 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
#hwtimestamp *
#minsources 2
#allow 192.168.0.0/16
#local stratum 10
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF
systemctl restart chronyd
chronyc -n sources

# 清理 osd 磁盘
dmsetup ls
dmsetup remove ceph--b0f011af--668a--476d--a76d--d988522881a7-osd--block--80cd0469--f76f--4648--94b6--4d01b6f4bc88
dmsetup remove ceph--9d61ba6d--86a8--4dea--bc5a--a47f29ee9c99-osd--block--717ab744--5d78--460a--a170--71d2d0a5b6dd
dmsetup remove ceph--7766307a--00ce--4fb3--95f0--c2bfa47ffd34-osd--block--f1969569--2413--47d7--81cc--ec1542528ab6

# 生成 registry.json 配置文件
cat > registry.json <<'EOF'
{
 "url":"helper.example.com:5000",
 "username":"a",
 "password":"a"
}
EOF

# pull image, tag image 
podman pull helper.example.com:5000/openshift4/ose-prometheus-node-exporter:v4.10
podman tag helper.example.com:5000/openshift4/ose-prometheus-node-exporter:v4.10 registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.10
podman pull helper.example.com:5000/openshift4/ose-prometheus:v4.10
podman tag helper.example.com:5000/openshift4/ose-prometheus:v4.10 registry.redhat.io/openshift4/ose-prometheus:v4.10
podman pull helper.example.com:5000/rhceph/rhceph-5-dashboard-rhel8:latest
podman tag helper.example.com:5000/rhceph/rhceph-5-dashboard-rhel8:latest registry.redhat.io/rhceph/rhceph-5-dashboard-rhel8:latest
podman pull helper.example.com:5000/openshift4/ose-prometheus-alertmanager:v4.10
podman tag helper.example.com:5000/openshift4/ose-prometheus-alertmanager:v4.10 registry.redhat.io/openshift4/ose-prometheus-alertmanager:v4.10

# bootstrap cluster 
cephadm --image helper.example.com:5000/rhceph/rhceph-5-rhel8:latest bootstrap --config ./initial-ceph.conf --mon-ip 172.16.1.251 --allow-fqdn-hostname --cluster-network 172.16.3.0/24 --registry-json /root/ceph5/registry.json
ceph orch host ls
ceph orch host label add jwang-ceph5-02.example.com mon
ceph orch host label add jwang-ceph5-02.example.com osd
ceph orch daemon add osd jwang-ceph5-02.example.com:/dev/vdb
ceph orch daemon add osd jwang-ceph5-02.example.com:/dev/vdc
ceph orch daemon add osd jwang-ceph5-02.example.com:/dev/vdd
ceph status
podman ps -a
ceph health detail

# 设置 mon_allow_pool_size_one 参数
# 设置 pool device_health_metrics min_size 1
# 设置 pool device_health_metrics size 1
ceph config set global mon_allow_pool_size_one true
ceph osd pool set device_health_metrics min_size 1
ceph osd pool set device_health_metrics size 1 --yes-i-really-mean-it
ceph health detail
ceph osd dump | grep pool
ceph health mute POOL_NO_REDUNDANCY
ceph status

# 为 openstack 集成做准备
# 创建 pool volumes/images/vms/backups
ceph osd pool create volumes 32
ceph osd pool set volumes min_size 1
ceph osd pool set volumes size 1 --yes-i-really-mean-it
ceph osd pool create images 32
ceph osd pool set images min_size 1
ceph osd pool set images size 1 --yes-i-really-mean-it
ceph osd pool create vms 32
ceph osd pool set vms min_size 1
ceph osd pool set vms size 1 --yes-i-really-mean-it
ceph osd pool create backups 32
ceph osd pool set backups min_size 1
ceph osd pool set backups size 1 --yes-i-really-mean-it

# 添加 client.openstack 
ceph auth add client.openstack mgr 'allow *' mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd pool=images, profile rbd pool=backups'
ceph auth list
ceph status

# 查看 rbd volumes
cephadm shell -- rbd ls
cephadm shell -- rbd ls vms
cephadm shell -- rbd ls volumes
cephadm shell -- rbd ls images
cephadm shell -- rbd ls backups

```
