### 准备镜像
```
# 在镜像服务器上生成镜像列表
cat > /tmp/ceph-imagelist.txt << EOF
rhceph/rhceph-4-rhel8
openshift4/ose-prometheus-node-exporter:v4.1
rhceph/rhceph-4-dashboard-rhel8
openshift4/ose-prometheus:4.1
openshift4/ose-prometheus-alertmanager:4.1
EOF

# 同步镜像到本地镜像服务器
export LOCAL_SECRET_JSON="${HOME}/pull-secret-2.json"
export LOCAL_REGISTRY='helper.cluster-0001.rhsacn.org:5000'

for i in `cat /tmp/ceph-imagelist.txt`; do oc image mirror -a ${LOCAL_SECRET_JSON} registry.redhat.io/$i ${LOCAL_REGISTRY}/$i; done
```

### 在 ceph 节点上
```
# 配置 repo
cat > /etc/yum.repos.d/ceph.repo << EOF
[rhel-7-server-rpms]
name=rhel-7-server-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-rpms
gpgcheck=0
enabled=1

[rhel-7-server-extras-rpms]
name=rhel-7-server-extras-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-extras-rpms
gpgcheck=0
enabled=1
EOF

# 更新系统并且重启
yum update -y
reboot

# 配置新的 repo
cat > /etc/yum.repos.d/ceph.repo << EOF
[rhel-7-server-rpms]
name=rhel-7-server-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-rpms
gpgcheck=0
enabled=1

[rhel-7-server-extras-rpms]
name=rhel-7-server-extras-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-extras-rpms
gpgcheck=0
enabled=1

[rhel-7-server-rhceph-4-tools-rpms]
name=rhel-7-server-rhceph-4-tools-rpms
baseurl=http://10.66.208.115/rhel9osp/rhel-7-server-rhceph-4-tools-rpms
gpgcheck=0
enabled=1

[rhel-7-server-rhceph-4-mon-rpms]
name=rhel-7-server-rhceph-4-mon-rpms
baseurl=http://10.66.208.115/rhel9osp/rhel-7-server-rhceph-4-mon-rpms
gpgcheck=0
enabled=1

[rhel-7-server-rhceph-4-osd-rpms]
name=rhel-7-server-rhceph-4-osd-rpms
baseurl=http://10.66.208.115/rhel9osp/rhel-7-server-rhceph-4-osd-rpms
gpgcheck=0
enabled=1

[rhel-7-server-ansible-2.9-rpms]
name=rhel-7-server-ansible-2.9-rpms
baseurl=http://10.66.208.115/rhel9osp/rhel-7-server-ansible-2.9-rpms
gpgcheck=0
enabled=1
EOF

# 生成 ansible inventory
cat > /etc/ansible/hosts << EOF
[mons]
ceph04 ansible_host=10.66.208.125 ansible_user=root

[osds]
ceph04 ansible_host=10.66.208.125 ansible_user=root

[mgrs]
ceph04 ansible_host=10.66.208.125 ansible_user=root

[mdss]
ceph04 ansible_host=10.66.208.125 ansible_user=root

[rgws]
ceph04 ansible_host=10.66.208.125 ansible_user=root

EOF

# 配置 ssh authentication
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''
fi

ansible -i inventory all -m authorized_key -a 'user=root state=present key="{{ lookup(\"file\"\"/root/.ssh/id_rsa.pub\") }}"' -k

# 设置时间服务器
cat > /tmp/ceph04-ntp.conf << 'EOF'
driftfile /var/lib/ntp/drift
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1 
restrict ::1
restrict 10.66.208.0 mask 255.255.255.0 nomodify notrap
server 127.127.1.0 iburst
fudge  127.127.1.0 stratum 4
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
EOF

ansible -i inventory mons -m copy -a 'src=/tmp/ceph04-ntp.conf dest=/etc/ntp.conf'
ansible -i inventory mons -m shell -a 'systemctl enable ntpd && systemctl start ntpd'
ansible -i inventory mons -m shell -a 'ntpq -np'

# 配置防火墙
firewall-cmd --add-service=ntp
firewall-cmd --add-service=ntp --permanent
firewall-cmd --reload

# 安装 ansible 和 ceph-ansible
yum install -y ceph-ansible

# 创建 ceph-ansible-keys 目录
mkdir -p ~/ceph-ansible-keys

# 链接 /usr/share/ceph-ansible/group_vars 到 /etc/ansible/group_vars
ln -s /usr/share/ceph-ansible/group_vars /etc/ansible/group_vars

# 进入 /usr/share/ceph-ansible
cd /usr/share/ceph-ansible

# 拷贝文件
echo y | cp group_vars/all.yml.sample group_vars/all.yml
echo y | cp group_vars/osds.yml.sample group_vars/osds.yml
echo y | cp group_vars/mdss.yml.sample group_vars/mdss.yml
echo y | cp group_vars/rgws.yml.sample group_vars/rgws.yml
echo y | cp group_vars/nfss.yml.sample group_vars/nfss.yml
echo y | cp group_vars/iscsigws.yml.sample group_vars/iscsigws.yml
echo y | cp site.yml.sample site.yml
echo y | cp site-docker.yml.sample site-docker.yml

# 生成 all.yml 文件
# 因为资源紧张，设置 dashboard_enabled 为 false
# 当 groupname 包含非法字符时，ansible 2.8+ 报警。例如 groupname: grafana-server
cat > group_vars/all.yml << EOF
---
dummy:
fetch_directory: ~/ceph-ansible-keys
ceph_origin: repository
ceph_repository: rhcs
ceph_repository_type: cdn
ceph_rhcs_version: 4
monitor_interface: eth0
public_network: 10.66.208.0/24
radosgw_interface: eth0
ceph_docker_image: "rhceph/rhceph-4-rhel8"
ceph_docker_image_tag: latest
containerized_deployment: true
dashboard_enabled: false
ceph_docker_registry: helper.cluster-0001.rhsacn.org:5000
ceph_docker_registry_auth: true
ceph_docker_registry_username: dummy
ceph_docker_registry_password: dummy

dashboard_admin_user: admin
dashboard_admin_password: passw0rd
node_exporter_container_image: helper.cluster-0001.rhsacn.org:5000/openshift4/ose-prometheus-node-exporter:v4.1
grafana_admin_user: admin
grafana_admin_password: passw0rd
grafana_container_image: helper.cluster-0001.rhsacn.org:5000/rhceph/rhceph-4-dashboard-rhel8:4-7
prometheus_container_image: helper.cluster-0001.rhsacn.org:5000/openshift4/ose-prometheus:4.1
alertmanager_container_image: helper.cluster-0001.rhsacn.org:5000/openshift4/ose-prometheus-alertmanager:4.1

ceph_conf_overrides:
  global:
    osd_pool_default_pg_num: 128
    osd_pool_default_pgp_num: 128
    osd_pool_default_size: 1
    osd_pool_default_min_size: 1
    mon_max_pg_per_osd: 1024
EOF

# 生成 group_vars/osds.yml
cat > group_vars/osds.yml <<'EOF'
devices:
  - /dev/sdb
  - /dev/sdc
EOF

# 安装
ansible-playbook site-container.yml

# 检查集群健康状态
docker exec -it ceph-mon-ceph04 ceph status 
docker exec -it ceph-mon-ceph04 ceph health detail 

# 列出已有的 pool
docker exec -it ceph-mon-ceph04 ceph osd lspools

# 创建 rbd pool
docker exec -it ceph-mon-ceph04 ceph osd pool create rbd 128 128

# 列出已有的 pool
docker exec -it ceph-mon-ceph04 ceph osd lspools

# 列出已有的 pool 的详细信息
docker exec -it ceph-mon-ceph04 ceph osd pool ls detail

# 拷贝文件到 
docker cp /root/ceph-external-cluster-details-exporter.py ceph-mon-ceph04:/ceph-external-cluster-details-exporter.py

# 确认 python3 在容器里
docker exec -it ceph-mon-ceph04 python3 /ceph-external-cluster-details-exporter.py  --rbd-data-pool-name rbd --rgw-endpoint 10.66.208.125:8080

# 保存输出的内容到 external-ceph-connectioninfo.json
# 创建 OCS Storage Cluster 时，选择 external mode 同时选择这个 json 文件

# 另外一种方法是在安装节点上安装 ceph-common 
# 必要时从 mon 拷贝 相关 keyring，然后执行 ceph-external-cluster-details-exporter.py
yum install -y ceph-common
python /root/ceph-external-cluster-details-exporter.py --rbd-data-pool-name rbd --rgw-endpoint 10.66.208.125:8080 
[{"kind": "ConfigMap", "data": {"maxMonId": "0", "data": "ceph04=10.66.208.125:6789", "mapping": "{}"}, "name": "rook-ceph-mon-endpoints"}, {"kind": "Secret", "data": {"mon-secret": "mon-secret", "fsid": "3d773288-f2b5-4dd6-9edd-00490df48f26", "cluster-name": "openshift-storage", "admin-secret": "admin-secret"}, "name": "rook-ceph-mon"}, {"kind": "Secret", "data": {"userKey": "AQDTqahfQ6DHExAA7MJGOpY2MEE6CH5eTK5olw==", "userID": "client.healthchecker"}, "name": "rook-ceph-operator-creds"}, {"kind": "Secret", "data": {"userKey": "AQDTqahf2t0DFRAAaKynlMK48jDVPgJX6s0Rdw==", "userID": "csi-rbd-node"}, "name": "rook-csi-rbd-node"}, {"kind": "StorageClass", "data": {"pool": "rbd"}, "name": "ceph-rbd"}, {"kind": "Secret", "data": {"userKey": "AQDTqahfAI7bFRAAibJ9GlNABldWrF72GBRrqQ==", "userID": "csi-rbd-provisioner"}, "name": "rook-csi-rbd-provisioner"}, {"kind": "Secret", "data": {"adminID": "csi-cephfs-provisioner", "adminKey": "AQDTqahfBIdFFxAAOWjsZRZLl9o13t8Nc5jzuw=="}, "name": "rook-csi-cephfs-provisioner"}, {"kind": "Secret", "data": {"adminID": "csi-cephfs-node", "adminKey": "AQDTqahfjaeWFhAAgZAmCfzwt1lzt4sjQxB6QA=="}, "name": "rook-csi-cephfs-node"}, {"kind": "StorageClass", "data": {"pool": "cephfs_data", "fsName": "cephfs"}, "name": "cephfs"}, {"kind": "StorageClass", "data": {"endpoint": "10.66.208.125:8080", "poolPrefix": "default"}, "name": "ceph-rgw"}]


# 创建 rook ceph external cluster detail secret
cat > secret-rook-ceph-external-cluster-details.yaml << EOF
apiVersion: v1
data:
  external_cluster_details: W3sibmFtZSI6ICJyb29rLWNlcGgtbW9uLWVuZHBvaW50cyIsICJraW5kIjogIkNvbmZpZ01hcCIsICJkYXRhIjogeyJkYXRhIjogImNlcGgwND0xMC42Ni4yMDguMTI1OjY3ODkiLCAibWF4TW9uSWQiOiAiMCIsICJtYXBwaW5nIjogInt9In19LCB7Im5hbWUiOiAicm9vay1jZXBoLW1vbiIsICJraW5kIjogIlNlY3JldCIsICJkYXRhIjogeyJhZG1pbi1zZWNyZXQiOiAiYWRtaW4tc2VjcmV0IiwgImNsdXN0ZXItbmFtZSI6ICJvcGVuc2hpZnQtc3RvcmFnZSIsICJmc2lkIjogIjNkNzczMjg4LWYyYjUtNGRkNi05ZWRkLTAwNDkwZGY0OGYyNiIsICJtb24tc2VjcmV0IjogIm1vbi1zZWNyZXQifX0sIHsibmFtZSI6ICJyb29rLWNlcGgtb3BlcmF0b3ItY3JlZHMiLCAia2luZCI6ICJTZWNyZXQiLCAiZGF0YSI6IHsidXNlcklEIjogImNsaWVudC5oZWFsdGhjaGVja2VyIiwgInVzZXJLZXkiOiAiQVFEVHFhaGZRNkRIRXhBQTdNSkdPcFkyTUVFNkNINWVUSzVvbHc9PSJ9fSwgeyJuYW1lIjogInJvb2stY3NpLXJiZC1ub2RlIiwgImtpbmQiOiAiU2VjcmV0IiwgImRhdGEiOiB7InVzZXJJRCI6ICJjc2ktcmJkLW5vZGUiLCAidXNlcktleSI6ICJBUURUcWFoZjJ0MERGUkFBYUt5bmxNSzQ4akRWUGdKWDZzMFJkdz09In19LCB7Im5hbWUiOiAiY2VwaC1yYmQiLCAia2luZCI6ICJTdG9yYWdlQ2xhc3MiLCAiZGF0YSI6IHsicG9vbCI6ICJyYmQifX0sIHsibmFtZSI6ICJyb29rLWNzaS1yYmQtcHJvdmlzaW9uZXIiLCAia2luZCI6ICJTZWNyZXQiLCAiZGF0YSI6IHsidXNlcklEIjogImNzaS1yYmQtcHJvdmlzaW9uZXIiLCAidXNlcktleSI6ICJBUURUcWFoZkFJN2JGUkFBaWJKOUdsTkFCbGRXckY3MkdCUnJxUT09In19LCB7Im5hbWUiOiAicm9vay1jc2ktY2VwaGZzLXByb3Zpc2lvbmVyIiwgImtpbmQiOiAiU2VjcmV0IiwgImRhdGEiOiB7ImFkbWluSUQiOiAiY3NpLWNlcGhmcy1wcm92aXNpb25lciIsICJhZG1pbktleSI6ICJBUURUcWFoZkJJZEZGeEFBT1dqc1pSWkxsOW8xM3Q4TmM1anp1dz09In19LCB7Im5hbWUiOiAicm9vay1jc2ktY2VwaGZzLW5vZGUiLCAia2luZCI6ICJTZWNyZXQiLCAiZGF0YSI6IHsiYWRtaW5JRCI6ICJjc2ktY2VwaGZzLW5vZGUiLCAiYWRtaW5LZXkiOiAiQVFEVHFhaGZqYWVXRmhBQWdaQW1DZnp3dDFsenQ0c2pReEI2UUE9PSJ9fSwgeyJuYW1lIjogImNlcGhmcyIsICJraW5kIjogIlN0b3JhZ2VDbGFzcyIsICJkYXRhIjogeyJmc05hbWUiOiAiY2VwaGZzIiwgInBvb2wiOiAiY2VwaGZzX2RhdGEifX0sIHsibmFtZSI6ICJjZXBoLXJndyIsICJraW5kIjogIlN0b3JhZ2VDbGFzcyIsICJkYXRhIjogeyJlbmRwb2ludCI6ICIxMC42Ni4yMDguMTI1OjgwODAiLCAicG9vbFByZWZpeCI6ICJkZWZhdWx0In19XQo=
kind: Secret
metadata:
  name: rook-ceph-external-cluster-details
  namespace: openshift-storage
type: Opaque
EOF

oc create -f secret-rook-ceph-external-cluster-details.yaml

# 创建 ocs external cluster
cat << EOF > ocs-external-cluster.yaml
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-independent-storagecluster
  namespace: openshift-storage
spec:
  externalStorage:
    enable: true
  labelSelector: {}
EOF

oc create -f ocs-external-cluster.yaml

# 检查 ocs operator 日志
oc -n openshift-storage logs $( oc -n openshift-storage get pods -o jsonpath='{ range .items[*]}{.metadata.name }{"\n"}' | grep ocs-operator)

```