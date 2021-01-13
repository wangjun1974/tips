### 部署 overcloud

```
# 生成部署脚本 deploy.sh
cat > ~/deploy.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $CNF/node-info.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible.yaml \
-e $THT/environments/ceph-ansible/ceph-rgw.yaml \
-e $CNF/cephstorage.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.168.8.21
EOF

# 设置脚本可执行
(undercloud) [stack@undercloud ~]$ chmod 755 ~/deploy.sh

# 开始部署
(undercloud) [stack@undercloud ~]$ time ./deploy.sh
```