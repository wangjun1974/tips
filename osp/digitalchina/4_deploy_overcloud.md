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
-e $CNF/environments/net-bond-with-vlans.yaml \
-e $CNF/environments/network-environment.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml
EOF
```