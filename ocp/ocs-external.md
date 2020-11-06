### 准备镜像
```
# 生成镜像列表
cat > /tmp/ceph-imagelist.txt << EOF
rhceph/rhceph-4-rhel8
openshift4/ose-prometheus-node-exporter:v4.1
rhceph/rhceph-4-dashboard-rhel8
openshift4/ose-prometheus:4.1
openshift4/ose-prometheus-alertmanager:4.1
EOF

# 同步镜像到本地
export LOCAL_SECRET_JSON="${HOME}/pull-secret-2.json"
export LOCAL_REGISTRY='helper.cluster-0001.rhsacn.org:5000'

for i in `cat /tmp/ceph-imagelist.txt`; do oc image mirror -a ${LOCAL_SECRET_JSON} registry.redhat.io/$i ${LOCAL_REGISTRY}/$i; done

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

[rhel-7-server-ansible-2.8-rpms]
name=rhel-7-server-ansible-2.8-rpms
baseurl=http://10.66.208.115/rhel9osp/rhel-7-server-ansible-2.8-rpms
gpgcheck=0
enabled=1
EOF


```