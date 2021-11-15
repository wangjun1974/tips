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
--ntp-server 192.0.2.1
EOF

# 根据邮件列表里的讨论，为了启用 OVN DVR HA 
# 需要传递 -e $THT/environments/services/neutron-ovn-dvr-ha.yaml 文件
# 否则 OVN DVR HA 相关参数有可能被部分配置
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
-e $THT/environments/services/neutron-ovn-dvr-ha.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF

# 设置脚本可执行
(undercloud) [stack@undercloud ~]$ chmod 755 ~/deploy.sh

# 部署前确认 undercloud 防火墙允许 overcloud 访问 time service
# 编辑 /etc/sysconfig/iptables 文件
# 在行
-A INPUT -p udp -m multiport --dports 123 -m state --state NEW -m comment --comment "105 ntp ipv4" -j ACCEPT
# 之后添加行
-A INPUT -s 192.0.2.0/24 -p udp -m multiport --dports 123 -m state --state NEW -m comment --comment "105 ntp ipv4" -j ACCEPT
# 然后重启 iptables 服务
(undercloud) [stack@undercloud ~]$ sudo systemctl restart iptables

# 开始部署
(undercloud) [stack@undercloud ~]$ time ./deploy.sh

# 部署成功后，执行 
(undercloud) [stack@undercloud ~]$ source ~/overcloudrc

# 查看 overcloud compute 服务
(overcloud) [stack@undercloud ~]$ openstack compute service list

# 部署过程中
# 查看 baremetal 节点状态
(undercloud) [stack@undercloud ~]$ watch -n10 'openstack baremetal node list'

# 查看 stack resource 状态
(undercloud) [stack@undercloud ~]$ watch -n10 'openstack stack resource list -n5 overcloud | grep -Ev COMP'

# 查看 mistral log, 检查最新日志文件的最后 10 行
(undercloud) [stack@undercloud ~]$ sudo -i
(undercloud) [stack@undercloud ~]# cd /var/log/containers/mistral
(undercloud) [stack@undercloud ~]# watch -n5 "ls -ltr | tail -1 | awk '{print \$9}' | xargs cat | tail -10"

# 查看 heat log, 检查最新日志文件的最后 10 行
(undercloud) [stack@undercloud ~]$ sudo -i
(undercloud) [stack@undercloud ~]# cd /var/log/containers/heat
(undercloud) [stack@undercloud ~]# watch -n5 "ls -ltr | tail -1 | awk '{print \$9}' | xargs cat | tail -10"

# 查看 ansible 日志
(undercloud) [stack@undercloud ~]$ watch -n10 'sudo cat /var/lib/mistral/overcloud/ansible.log | grep -E TASK | tail -10'

# 查看 ceph-ansible 日志
(undercloud) [stack@undercloud ~]$ watch -n10 'sudo cat /var/lib/mistral/overcloud/ceph-ansible/ceph_ansible_command.log | grep -E TASK | tail -10'

```