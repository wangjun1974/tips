## 定义存储节点
```
# 参考 osp 节点定义
CEPH_N="ceph01 ceph02 ceph03"
CEPH_MEM='16384'
CEPH_VCPU='4'
LIBVIRT_D='/data/kvm'
CEPH_OSD_DISK=3

for i in $CEPH_N;
do
    echo "Defining node jwang-xuhui-$i..."
    virt-install --ram $CEPH_MEM --vcpus $CEPH_VCPU --os-variant rhel7 \
    --disk path=${LIBVIRT_D}/jwang-xuhui-$i.qcow2,device=disk,bus=virtio,format=qcow2 \
    $(for((n=1;n<=$CEPH_OSD_DISK;n+=1)); do echo -n "--disk path=${LIBVIRT_D}/jwang-xuhui-$i-storage-${n}.qcow2,device=disk,bus=virtio,format=qcow2 "; done) \
    --noautoconsole --vnc --network network:provisioning \
    --network network:default \
    --name jwang-xuhui-$i \
    --cpu SandyBridge,+vmx \
    --dry-run --print-xml > /tmp/jwang-overcloud-$i.xml

    virsh define --file /tmp/jwang-xuhui-$i.xml || { echo "Unable to define jwang-xuhui-$i"; return 1; }
done

# 安装一个 allinone 的 节点
# 生成 ks.cfg 文件
cat > /tmp/ks.cfg << 'EOF'
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
ignoredisk --only-use=vda
clearpart --all --initlabel
autopart
network --device=ens2 --hostname=xuhui.example.com --bootproto=static --ip=192.168.122.101 --netmask=255.255.255.0 --gateway=192.168.122.1 --nameserver=192.168.122.1
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

# 安装虚拟机
echo "Defining node jwang-xuhui-ceph01..."
virt-install --debug --ram 16384 --vcpus 4 --os-variant rhel7 \
    --disk path=/data/kvm/jwang-xuhui-ceph01.qcow2,bus=virtio,size=100 \
    $(for((n=1;n<=3;n+=1)); do echo -n "--disk path=/data/kvm/jwang-xuhui-ceph01-storage-${n}.qcow2,bus=virtio,size=100 "; done) \
    --network network:default,model=virtio \
    --boot menu=on --location /root/jwang/isos/rhel-8.2-x86_64-dvd.iso \
    --graphics none \
    --console pty,target_type=serial \
    --initrd-inject /tmp/ks.cfg \
    --extra-args='ks=file:/ks.cfg console=ttyS0' \
    --name jwang-xuhui-ceph01

# 参考链接设置离线 registry
# https://github.com/wangjun1974/ospinstall/blob/main/helper_registry.example.md

# 设置软件仓库
> /etc/yum.repos.d/w.repo 
for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms  ansible-2.9-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms 
do
cat >> /etc/yum.repos.d/w.repo << EOF
[$i]
name=$i
baseurl=file:///var/www/html/repos/osp16.1/$i/
enabled=1
gpgcheck=0

EOF
done

# 添加 local registry helper.example.com 到 /etc/hosts
cat >> /etc/hosts << EOF
192.168.122.3 helper.example.com
EOF

# 拷贝 registry 的证书，更新证书信任关系
scp helper.example.com:/opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

# 访问 registry 的 catalog
curl https://helper.example.com:5000/v2/_catalog

# 设置 ssh config
cat > ~/.ssh/config << 'EOF'
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
EOF

# 安装 ceph-ansible
yum install -y ceph-ansible

# 创建 ceph-ansible-keys 目录
mkdir -p ~/ceph-ansible-keys

# 链接 ceph-ansible/group_vars
ln -s /usr/share/ceph-ansible/group_vars /etc/ansible/group_vars

cd /usr/share/ceph-ansible

# 生成测试的 group_vars/all.yml
cat > group_vars/all.yml << EOF
fetch_directory: ~/ceph-ansible-keys
monitor_interface: ens2 
public_network: 192.168.122.0/24
ceph_docker_image: rhceph/rhceph-4-rhel8
containerized_deployment: true
ceph_docker_registry: helper.example.com:5000
ceph_docker_registry_auth: false
ceph_origin: distro
#ceph_repository: rhcs
#ceph_repository_type: cdn
ceph_rhcs_version: 4
dashboard_admin_user: admin
dashboard_admin_password: redhat
node_exporter_container_image: helper.example.com:5000/openshift4/ose-prometheus-node-exporter:v4.1
grafana_admin_user: admin
grafana_admin_password: redhat
grafana_container_image: helper.example.com:5000/rhceph/rhceph-4-dashboard-rhel8
prometheus_container_image: helper.example.com:5000/openshift4/ose-prometheus:4.1
alertmanager_container_image: helper.example.com:5000/openshift4/ose-prometheus-alertmanager:4.1

ceph_conf_overrides:
  global:
    osd_pool_default_pg_num: 128
    osd_pool_default_pgp_num: 128
    osd_pool_default_size: 1
    osd_pool_default_min_size: 1
EOF

cat > group_vars/osds.yml <<'EOF'
osd_scenario: lvm
osd_objectstore: bluestore
devices:
  - /dev/disk/by-path/pci-0000:00:06.0
  - /dev/disk/by-path/pci-0000:00:07.0
  - /dev/disk/by-path/pci-0000:00:08.0
EOF

cat > /etc/ansible/hosts << 'EOF'
[mons]
xuhui ansible_host=192.168.122.101 ansible_user=root

[osds]
xuhui ansible_host=192.168.122.101 ansible_user=root

[mgrs]
xuhui ansible_host=192.168.122.101 ansible_user=root

[mdss]
xuhui ansible_host=192.168.122.101 ansible_user=root

[grafana-server]
xuhui ansible_host=192.168.122.101 ansible_user=root
EOF

# 生成 ssh key
mkdir -p ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''

# 设置密码
ansible all -m authorized_key -a 'user=root state=present key="{{ lookup(\"file\", \"/root/.ssh/id_rsa.pub\") }}"' -k

# 修改/etc/ansible/ansible.cfg
sed -ie 's|^#retry_files_save_path.*|retry_files_save_path = ~/|' /etc/ansible/ansible.cfg

# 生成目录
mkdir -p /var/log/ansible/
chmod 755 /var/log/ansible

# 执行安装
echo y | cp site-container.yml.sample site-container.yml
ansible-playbook site-container.yml

```