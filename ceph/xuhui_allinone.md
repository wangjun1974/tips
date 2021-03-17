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

# 拷贝软件仓库
scp osp16.1-yum-repos-2021-01-15.tar.gz root@192.168.122.101:/home
ssh root@192.168.122.101 mkdir -p /var/www/html
ssh root@192.168.122.101 tar zxvf /home/osp16.1-yum-repos-2021-01-15.tar.gz -C /

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
192.168.122.101 xuhui.example.com
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
---
dummy:
fetch_directory: ~/ceph-ansible-keys
cluster: ceph
configure_firewall: True
ceph_origin: distro
#ceph_repository: rhcs
#ceph_repository_type: cdn
ceph_rhcs_version: 4
ceph_iscsi_config_dev: false
cephx: true
monitor_interface: ens2 
ip_version: ipv4
mon_use_fqdn: false # if set to true, the MON name used will be the fqdn in the ceph.conf
public_network: 192.168.122.0/24
ceph_docker_image: rhceph/rhceph-4-rhel8
ceph_docker_image_tag: "latest"
containerized_deployment: true
ceph_docker_registry: helper.example.com:5000
ceph_docker_registry_auth: false
dashboard_admin_user: admin
dashboard_admin_password: redhat
node_exporter_container_image: helper.example.com:5000/openshift4/ose-prometheus-node-exporter:v4.1
grafana_admin_user: admin
grafana_admin_password: redhat
grafana_container_image: helper.example.com:5000/rhceph/rhceph-4-dashboard-rhel8
prometheus_container_image: helper.example.com:5000/openshift4/ose-prometheus:4.1
alertmanager_container_image: helper.example.com:5000/openshift4/ose-prometheus-alertmanager:4.1
block_db_size: -1
osd_objectstore: bluestore

ceph_conf_overrides:
  global:
    osd_pool_default_pg_num: 128
    osd_pool_default_pgp_num: 128
    osd_pool_default_size: 1
    osd_pool_default_min_size: 1
EOF

# 生成 group_vars/osds.yml 文件
cat > group_vars/osds.yml <<'EOF'
osd_scenario: lvm
osd_objectstore: bluestore
devices:
  - /dev/disk/by-path/pci-0000:00:06.0
  - /dev/disk/by-path/pci-0000:00:07.0
  - /dev/disk/by-path/pci-0000:00:08.0
EOF

# 生成 group_vars/mons.yml 文件
cat > group_vars/mons.yml <<'EOF'
ceph_mon_docker_memory_limit: 3072m
ceph_mon_docker_cpu_limit: 2
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

# 生成 /var/log/ansible 目录
mkdir -p /var/log/ansible
chmod 755 /var/log/ansible

# 准备 dashboard 镜像
# 针对 registry 执行一遍
podman pull helper.example.com:5000/rhceph/rhceph-4-dashboard-rhel8:4
podman tag helper.example.com:5000/rhceph/rhceph-4-dashboard-rhel8:4 helper.example.com:5000/rhceph/rhceph-4-dashboard-rhel8:latest
podman push helper.example.com:5000/rhceph/rhceph-4-dashboard-rhel8:latest

# 执行安装
echo y | cp site-container.yml.sample site-container.yml
ansible-playbook site-container.yml

# 根据以下步骤移除 osd 
# https://www.sebastien-han.fr/blog/2015/12/11/ceph-properly-remove-an-osd/

# 用这个配置能完成部署
# 参见邮件 Latest RHCS z-stream
cat > group_vars/osds.yml <<'EOF'
osd_auto_discovery: false
osd_scenario: lvm
devices:
  - /dev/disk/by-path/pci-0000:00:06.0
  - /dev/disk/by-path/pci-0000:00:07.0
  - /dev/disk/by-path/pci-0000:00:08.0
EOF

# lsblk 的输出
vdb                                                                                                                   252:16   0  100G  0 disk 
`-ceph--block--8117b254--56c8--4282--8803--a3935a19ee2c-osd--block--07bcdfcc--8226--4f31--9ea2--be3f9d48187a          253:3    0  100G  0 lvm  
vdc                                                                                                                   252:32   0  100G  0 disk 
`-ceph--block--3f722a0b--2476--4e1c--8cf5--ce7bcee30704-osd--block--0a8b63f9--9e28--4a1b--9c69--bcf964e2405a          253:5    0  100G  0 lvm  
vdd                                                                                                                   252:48   0  100G  0 disk 
|-ceph--block--dbs--d91b8955--79cf--4d51--b05f--1a58daf51bfb-osd--block--db--ab488420--69ff--4e96--a1ad--43c17ea00218 253:4    0   50G  0 lvm  
`-ceph--block--dbs--d91b8955--79cf--4d51--b05f--1a58daf51bfb-osd--block--db--7a02ea9d--a7b1--4349--b695--3364fa79d771 253:6    0   50G  0 lvm  

# 尝试另外的 osds.yml 配置
# 用这个配置能完成部署
# 参见邮件 Latest RHCS z-stream
cat > group_vars/osds.yml <<'EOF'
osd_auto_discovery: false
osd_scenario: non-collocated
devices:
  - /dev/disk/by-path/pci-0000:00:06.0
  - /dev/disk/by-path/pci-0000:00:07.0
dedicated_devices:
  - /dev/vdd
  - /dev/vdd
EOF

# 不知道为什么如下配置未能完成部署
cat > group_vars/osds.yml <<'EOF'
osd_auto_discovery: false
osd_scenario: non-collocated
devices:
  - /dev/disk/by-path/pci-0000:00:06.0
  - /dev/disk/by-path/pci-0000:00:07.0
dedicated_devices:
  - /dev/disk/by-path/pci-0000:00:08.0
  - /dev/disk/by-path/pci-0000:00:08.0
EOF

# 接下来会看看这个配置是否能完成部署
cat > group_vars/osds.yml <<'EOF'
osd_auto_discovery: false
osd_scenario: non-collocated
devices:
  - /dev/vdb
dedicated_devices:
  - /dev/vdc
bluestore_wal_devices:
  - /dev/vdd
EOF

# lsblk 的输出
vdb                                                                                                                   252:16   0  100G  0 disk 
`-ceph--block--8117b254--56c8--4282--8803--a3935a19ee2c-osd--block--07bcdfcc--8226--4f31--9ea2--be3f9d48187a          253:3    0  100G  0 lvm  
vdc                                                                                                                   252:32   0  100G  0 disk 
`-ceph--block--3f722a0b--2476--4e1c--8cf5--ce7bcee30704-osd--block--0a8b63f9--9e28--4a1b--9c69--bcf964e2405a          253:5    0  100G  0 lvm  
vdd                                                                                                                   252:48   0  100G  0 disk 
|-ceph--block--dbs--d91b8955--79cf--4d51--b05f--1a58daf51bfb-osd--block--db--ab488420--69ff--4e96--a1ad--43c17ea00218 253:4    0   50G  0 lvm  
`-ceph--block--dbs--d91b8955--79cf--4d51--b05f--1a58daf51bfb-osd--block--db--7a02ea9d--a7b1--4349--b695--3364fa79d771 253:6    0   50G  0 lvm  


# 查看 perf counters
podman exec -it ceph-mon-xuhui ceph daemon osd.0 perf schema
podman exec -it ceph-mon-xuhui ceph daemon osd.0 perf dump 

# 关于 Bluestore 的说明
# https://xcodest.me/ceph-bluestore-and-ceph-volume.html

podman exec -it ceph-osd-0 ceph-bluestore-tool  show-label --path /var/lib/ceph/osd/ceph-0
inferring bluefs devices from bluestore path
{
    "/var/lib/ceph/osd/ceph-0/block": {
        "osd_uuid": "c8707324-d0be-4c70-a451-2a7322fa0812",
        "size": 107369988096,
        "btime": "2021-03-16 21:09:19.788363",
        "description": "main",
        "bluefs": "1",
        "ceph_fsid": "8b71d5de-4c9e-4ff5-afa8-ee00ce81843f",
        "kv_backend": "rocksdb",
        "magic": "ceph osd volume v026",
        "mkfs_done": "yes",
        "osd_key": "AQD8rVBgxehVOxAAYp0wu0CY4ZJ9QtzyB3u8ew==",
        "ready": "ready",
        "require_osd_release": "14",
        "whoami": "0"
    },
    "/var/lib/ceph/osd/ceph-0/block.db": {
        "osd_uuid": "c8707324-d0be-4c70-a451-2a7322fa0812",
        "size": 53682896896,
        "btime": "2021-03-16 21:09:19.791001",
        "description": "bluefs db"
    }
}


```



```
# example of group_vars/all.yml
---
dummy:
fetch_directory: ~/ceph-ansible-keys
cluster: ceph
configure_firewall: False
ceph_origin: repository
ceph_repository: rhcs
ceph_rhcs_version: 4
ceph_iscsi_config_dev: false
cephx: true
monitor_interface: "bond0.2670"
ip_version: ipv4
mon_use_fqdn: false # if set to true, the MON name used will be the fqdn in the ceph.conf
cephfs: cephfs # name of the ceph filesystem
cephfs_data_pool:
  name: "{{ cephfs_data if cephfs_data is defined else 'cephfs_data' }}"
  pg_num: "512"
  pgp_num: "512"
  rule_name: "replicated_rule"
  type: 1
  erasure_profile: ""
  expected_num_objects: ""
  size: "{{ osd_pool_default_size }}"
  min_size: "{{ osd_pool_default_min_size }}"
  pg_autoscale_mode: off
cephfs_metadata_pool:
  name: "{{ cephfs_metadata if cephfs_metadata is defined else 'cephfs_metadata' }}"
  pg_num: "128"
  pgp_num: "128"
  rule_name: "replicated_rule"
  type: 1
  erasure_profile: ""
  expected_num_objects: ""
  size: "{{ osd_pool_default_size }}"
  min_size: "{{ osd_pool_default_min_size }}"
  pg_autoscale_mode: off
cephfs_pools:
  - "{{ cephfs_data_pool }}"
  - "{{ cephfs_metadata_pool }}"
is_hci: false
hci_safety_factor: 0.2
non_hci_safety_factor: 0.7
block_db_size: -1 # block db size in bytes for the ceph-volume lvm batch. -1 means use the default of 'as big as possible'.
public_network: 10.89.223.128/27
cluster_network: 10.89.223.160/27
osd_objectstore: bluestore
ceph_conf_overrides:
  global:
    mon_clock_drift_warn_backoff: "30"
    mon_clock_drift_allowed: ".15"
    osd_pool_default_size: "3"
    osd_pool_default_min_size: "2"
    mon_osd_full_ratio: "0.95"
    mon_osd_nearfull_ratio: "0.7"
    mon_compact_on_start: true
    mon_allow_pool_delete: true
    mon_max_pg_per_osd: "300"
    osd_pool_default_pg_autoscale_mode: "off"
  osd:
    osd_client_op_priority: "63"
    osd_recovery_op_priority: "1"
    osd_backfill_scan_max: "16"
    osd_backfill_scan_min: "4"
    osd_scrub_begin_hour: "21"
    osd_scrub_end_hour: "5"
    osd_scrub_during_recovery: "false"
    osd_deep_scrub_stride: "1048576"
    osd_scrub_chunk_min: "1"
    osd_scrub_chunk_max: "5"
    osd_scrub_sleep: ".1"
    osd_recovery_max_active: "1"
    bluestore_cache_autotune: false
    bluestore_cache_size_hdd: "8589934592"
    bluestore_cache_kv_ratio: "0.2"
    bluestore_cache_meta_ratio: "0.8"
    bluestore_rocksdb_options: "compression=kNoCompression,max_write_buffer_number=32,min_write_buffer_number_to_merge=2,recycle_log_file_num=32,compaction_style=kCompactionStyleLevel,write_buffer_size=67108864,target_file_size_base=67108864,max_background_compactions=31,level0_file_num_compaction_trigger=8,level0_slowdown_writes_trigger=32,level0_stop_writes_trigger=64,max_bytes_for_level_base=536870912,compaction_threads=32,max_bytes_for_level_multiplier=8,flusher_threads=8,compaction_readahead_size=2MB"
    osd_min_log_entries: "10"
    osd_max_pg_log_entries: "10"
    osd_pg_log_dups_tracked: "10"
    osd_pg_log_trim_min: "10"
os_tuning_params:
   - { name: kernel.pid_max, value: 4194303 }
   - { name: fs.file-max, value: 26234859 }
   - { name: vm.zone_reclaim_mode , value: 0 }
   - { name: vm.vfs_cache_pressure , value: 50 }
   - { name: vm.swappiness, value: 10 }
   - { name: vm.dirty_ratio, value: 15 }
   - { name: vm.dirty_background_ratio, value: 3 }
   - { name: vm.min_free_kbytes, value: "{{ vm_min_free_kbytes }}" }
   - { name: net.core.rmem_max, value: 56623104 }
   - { name: net.core.wmem_max, value: 56623104 }
   - { name: net.core.rmem_default, value: 56623104 }
   - { name: net.core.wmem_default, value: 56623104 }
   - { name: net.core.optmem_max, value: 40960 }
   - { name: net.ipv4.tcp_rmem, value: 4096 87380 56623104   }
   - { name: net.ipv4.tcp_wmem, value: 4096 87380 56623104   }
   - { name: net.core.somaxconn, value: 1024 }
   - { name: net.core.netdev_max_backlog, value: 50000 }
   - { name: net.ipv4.tcp_max_syn_backlog, value: 30000 }
   - { name: net.ipv4.tcp_max_tw_backlog, value: 2000000 }
   - { name: net.ipv4.tcp_tw_reuse, value: 1 }
   - { name: net.ipv4.tcp_fin_timeout, value: 10 }
   - { name: net.ipv4.tcp_slow_start_after_idle, value: 0 }
   - { name: net.ipv4.conf.all.send_redirects, value: 0 }
   - { name: net.ipv4.conf.all.accept_redirects, value: 0 }
   - { name: net.ipv4.conf.all.accept_source_route, value: 0 }
   - { name: net.ipv4.tcp_mtu_probing, value: 1 }
   - { name: net.ipv4.tcp_timestamps, value: 0 }
   - { name: net.ipv4.tcp_moderate_rcvbuf, value: 0 }
ceph_docker_image: "rhceph/rhceph-4-rhel8"
ceph_docker_image_tag: "latest"
ceph_docker_registry: "rs-ops-casb-201:5000"
ceph_docker_registry_auth: false
containerized_deployment: True
openstack_config: true
openstack_glance_pool:
  name: "images"
  pg_num: "128"
  pgp_num: "128"
  rule_name: "replicated_rule"
  type: 1
  erasure_profile: ""
  expected_num_objects: ""
  application: "rbd"
  size: "{{ osd_pool_default_size }}"
  min_size: "{{ osd_pool_default_min_size }}"
  pg_autoscale_mode: off
openstack_cinder_pool:
  name: "volumes"
  pg_num: "1024"
  pgp_num: "1024"
  rule_name: "replicated_rule"
  type: 1
  erasure_profile: ""
  expected_num_objects: ""
  application: "rbd"
  size: "{{ osd_pool_default_size }}"
  min_size: "{{ osd_pool_default_min_size }}"
  pg_autoscale_mode: off
openstack_nova_pool:
  name: "vms"
  pg_num: "512"
  pgp_num: "512"
  rule_name: "replicated_rule"
  type: 1
  erasure_profile: ""
  expected_num_objects: ""
  application: "rbd"
  size: "{{ osd_pool_default_size }}"
  min_size: "{{ osd_pool_default_min_size }}"
  pg_autoscale_mode: off
openstack_pools:
  - "{{ openstack_glance_pool }}"
  - "{{ openstack_cinder_pool }}"
  - "{{ openstack_nova_pool }}"
dashboard_enabled: True
dashboard_protocol: https
dashboard_port: 8443
dashboard_admin_user: admin
dashboard_admin_password: dtn@2020
dashboard_crt: ''
dashboard_key: ''
dashboard_tls_external: false
dashboard_grafana_api_no_ssl_verify: "{{ true if dashboard_protocol == 'https' and not grafana_crt and not grafana_key else false }}"
node_exporter_container_image: rs-ops-casb-201:5000/openshift4/ose-prometheus-node-exporter:v4.1
grafana_admin_user: admin
grafana_admin_password: dtn@2020
grafana_crt: ''
grafana_key: ''
grafana_container_image: rs-ops-casb-201:5000/rhceph/rhceph-4-dashboard-rhel8:latest
prometheus_container_image: rs-ops-casb-201:5000/openshift4/ose-prometheus:4.1
alertmanager_container_image: rs-ops-casb-201:5000/openshift4/ose-prometheus-alertmanager:4.1

# example of group_vars/osds.yml
---
dummy:
devices:
  - /dev/sdc
  - /dev/sdd
  - /dev/sde
  - /dev/sdf
  - /dev/sdg
  - /dev/sdh
  - /dev/sdi
  - /dev/sdj
  - /dev/sdk
  - /dev/sdl
  - /dev/sdm
  - /dev/sdn
  - /dev/sdo
  - /dev/sdp
  - /dev/sdq
  - /dev/sdr
  - /dev/sds
  - /dev/sdt
  - /dev/sdu
  - /dev/sdv
  - /dev/sdw
  - /dev/sdx
  - /dev/sdy
  - /dev/sdz
```


```
# 设置环境变量 IMG，指向 ceph 镜像 id
IMG=$(sudo podman images | grep ceph | awk {'print $3'})

# 设置 alias ceph-volume 
alias ceph-volume="sudo podman run --rm --privileged --net=host --ipc=host -v /run/lock/lvm:/run/lock/lvm:z -v /var/run/udev/:/var/run/udev/:z -v /dev:/dev -v /etc/ceph:/etc/ceph:z -v /var/lib/ceph/:/var/lib/ceph/:z -v /var/log/ceph/:/var/log/ceph/:z --entrypoint=ceph-volume $IMG --cluster ceph"

# 确认 alias ceph-volume 可正常执行
[heat-admin@overcloud-controller-0 ~]$ ceph-volume lvm list

ceph-volume lvm batch --bluestore --prepare /dev/vdb /dev/vdc --db-devices /dev/vdd --wal-devices /dev/vdd --report --format=json

# 知识库文档
https://access.redhat.com/solutions/3871211
https://access.redhat.com/solutions/4241061

ceph daemon osd.<id> perf dump

podman exec -it ceph-mon-xuhui ceph daemon osd.0 perf dump | grep blue
```

文档关于如何优化使用 NVMe SSD：Using NVMe with LVM Optimally<br>
https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html-single/object_gateway_for_production_guide/index#using-nvme-with-lvm-optimally

