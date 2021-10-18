### 

```
# 创建 public network
# 这个网络的 vlan id 与 External 的 vlan id 相同
(overcloud) [stack@undercloud ~]$ openstack network create public \
  --external --provider-physical-network datacentre \
  --provider-network-type vlan --provider-segment 10
# 在我公司内部的环境里
(overcloud) [stack@undercloud ~]$ openstack network create public \
  --external --provider-physical-network datacentre \
  --provider-network-type flat
 
# 创建 public subnet, 根据 External 的情况调整这个
(overcloud) [stack@undercloud ~]$ openstack subnet create public-subnet \
  --no-dhcp --network public --subnet-range 192.168.122.0/24 \
  --allocation-pool start=192.168.122.100,end=192.168.122.200  \
  --gateway 192.168.122.1

# 创建租户网络 private
(overcloud) [stack@undercloud ~]$ openstack network create private

# 创建 subnet private
(overcloud) [stack@undercloud ~]$ openstack subnet create private-subnet \
  --network private \
  --gateway 172.16.1.1 \
  --subnet-range 172.16.1.0/24

# 创建虚拟路由器 router1
(overcloud) [stack@undercloud ~]$ openstack router create router1

# 将 private-subnet 添加到　router1
(overcloud) [stack@undercloud ~]$ openstack router add subnet router1 private-subnet

# 将 router1 的外部网关设置为 public
(overcloud) [stack@undercloud ~]$ openstack router set router1 --external-gateway public

# 创建 flavor m1.nano
(overcloud) [stack@undercloud ~]$ openstack flavor create m1.nano --vcpus 1 --ram 64 --disk 1

# 确认存在默认 security group
(overcloud) [stack@undercloud ~]$ openstack security group list --project admin

# 在默认 security group 中创建规则，允许 ping instance
(overcloud) [stack@undercloud ~]$ SGID=$(openstack security group list --project admin -c ID -f value)
(overcloud) [stack@undercloud ~]$ openstack security group rule create --proto icmp $SGID

# 在默认 security group 中创建规则，允许 ssh instance
(overcloud) [stack@undercloud ~]$ openstack security group rule create --dst-port 22 --proto tcp $SGID

# 下载 cirros image
(overcloud) [stack@undercloud ~]$ curl -L -O http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

# 创建 cirros glance image
(overcloud) [stack@undercloud ~]$ openstack image create cirros --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public

# 创建 instance test-instance
(overcloud) [stack@undercloud ~]$ openstack server create test-instance --network private --flavor m1.nano --image cirros

# 查看实例状态，等待实例状态变为 ACTIVE
(overcloud) [stack@undercloud ~]$ openstack server list

# 查看实例的 console log
(overcloud) [stack@undercloud ~]$ openstack console log show test-instance

# 创建 floating ip
(overcloud) [stack@undercloud ~]$ openstack floating ip create public

# 查看创建的 floating ip
(overcloud) [stack@undercloud ~]$ openstack floating ip list

# 将 floating ip 添加到实例
(overcloud) [stack@undercloud ~]$ FIP=$(openstack floating ip list -c "Floating IP Address" -f value)
(overcloud) [stack@undercloud ~]$ openstack server add floating ip test-instance $FIP

# 确认 floating ip 已添加到实例
(overcloud) [stack@undercloud ~]$ openstack server show test-instance -f json -c addresses

# 从 undercloud ping 实例的 floating ip
(overcloud) [stack@undercloud ~]$ ping -c3 $FIP
```

### 创建租户及实例
https://docs.openstack.org/mitaka/install-guide-obs/keystone-users.html
```
# 创建 project1
(overcloud) [stack@undercloud ~]$ source ~/overcloudrc
(overcloud) [stack@undercloud ~]$ openstack project create --domain default \
  --description "Project " project1

# 创建用户 project1admin
(overcloud) [stack@undercloud ~]$ openstack user create --domain default \
  --password-prompt project1admin

# 为用户 project1admin 赋予 admin 角色
(overcloud) [stack@undercloud ~]$ openstack role add --project project1 --user project1admin admin

# 创建用户 project1user1
(overcloud) [stack@undercloud ~]$ openstack user create --domain default \
  --password-prompt project1user1

# 为用户 project1user1 赋予 member 角色
(overcloud) [stack@undercloud ~]$ openstack role add --project project1 --user project1user1 member

# 创建 overcloud-project1admin-rc
(overcloud) [stack@undercloud ~]$ cp overcloudrc overcloud-project1admin-rc
(overcloud) [stack@undercloud ~]$ sed -i 's|export OS_USERNAME=admin|export OS_USERNAME=project1admin|' overcloud-project1admin-rc
(overcloud) [stack@undercloud ~]$ sed -i 's|export OS_PROJECT_NAME=admin|export OS_PROJECT_NAME=project1|' overcloud-project1admin-rc
(overcloud) [stack@undercloud ~]$ sed -i 's|export OS_PASSWORD=.*$|export OS_PASSWORD=redhat|' overcloud-project1admin-rc
(overcloud) [stack@undercloud ~]$ cat >> overcloud-project1admin-rc <<'EOF'
export PS1="(\$OS_CLOUDNAME-\$OS_USERNAME) [\u@\h \W]\$ "
EOF

# 创建 overcloud-project1user1-rc
(overcloud) [stack@undercloud ~]$ cp overcloudrc overcloud-project1user1-rc
(overcloud) [stack@undercloud ~]$ sed -i 's|export OS_USERNAME=admin|export OS_USERNAME=project1user1|' overcloud-project1user1-rc
(overcloud) [stack@undercloud ~]$ sed -i 's|export OS_PROJECT_NAME=admin|export OS_PROJECT_NAME=project1|' overcloud-project1user1-rc
(overcloud) [stack@undercloud ~]$ sed -i 's|export OS_PASSWORD=.*$|export OS_PASSWORD=redhat|' overcloud-project1user1-rc
(overcloud) [stack@undercloud ~]$ cat >> overcloud-project1user1-rc <<'EOF'
export PS1="(\$OS_CLOUDNAME-\$OS_USERNAME) [\u@\h \W]\$ "
EOF

# 切换 profile 到 overcloud-project1admin-rc
(overcloud) [stack@undercloud ~]$ source overcloud-project1admin-rc

# 创建租户网络 project1-private
(overcloud-project1admin) [stack@undercloud ~]$ openstack network create project1-private --project project1

# 创建 subnet project1-private-subnet
(overcloud-project1admin) [stack@undercloud ~]$ openstack subnet create project1-private-subnet \
  --project project1 \
  --network project1-private \
  --gateway 172.16.1.1 \
  --subnet-range 172.16.1.0/24

# 创建虚拟路由器 project1-router1
(overcloud-project1admin) [stack@undercloud ~]$ openstack router create project1-router1 --project project1

# 将 private-subnet 添加到　project1-router1
(overcloud-project1admin) [stack@undercloud ~]$ openstack router add subnet project1-router1 project1-private-subnet

# 将 router1 的外部网关设置为 public
(overcloud-project1admin) [stack@undercloud ~]$ openstack router set project1-router1 --external-gateway public

# 确认存在默认 security group
(overcloud-project1admin) [stack@undercloud ~]$ openstack security group list --project project1

# 在默认 security group 中创建规则，允许 ping instance
(overcloud-project1admin) [stack@undercloud ~]$ SGID=$(openstack security group list --project project1 -c ID -f value)
(overcloud-project1admin) [stack@undercloud ~]$ openstack security group rule create --proto icmp $SGID

# 在默认 security group 中创建规则，允许 ssh instance
(overcloud-project1admin) [stack@undercloud ~]$ openstack security group rule create --dst-port 22 --proto tcp $SGID

# 下载 cirros image
(overcloud-project1admin) [stack@undercloud ~]$ curl -L -O http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

# 创建 cirros glance image，如果 admin project 已创建 image 则可省略此步骤
(overcloud-project1admin) [stack@undercloud ~]$ openstack image create cirros --file cirros-0.4.0-x86_64-disk.img  --disk-format qcow2 --container-format bare --public

# 创建 instance test-instance
(overcloud-project1admin) [stack@undercloud ~]$ source overcloud-project1user1-rc
(overcloud-project1user1) [stack@undercloud ~]$ openstack server create test-instance --network project1-private --flavor m1.nano --image cirros

# 查看实例状态，等待实例状态变为 ACTIVE
(overcloud-project1user1) [stack@undercloud ~]$ openstack server list

# 查看实例的 console log
(overcloud-project1user1) [stack@undercloud ~]$ openstack console log show test-instance

# 创建 floating ip
(overcloud-project1user1) [stack@undercloud ~]$ openstack floating ip create public

# 查看创建的 floating ip
(overcloud-project1user1) [stack@undercloud ~]$ openstack floating ip list

# 将 floating ip 添加到实例
(overcloud-project1user1) [stack@undercloud ~]$ FIP=$(openstack floating ip list -c "Floating IP Address" -f value)
(overcloud-project1user1) [stack@undercloud ~]$ openstack server add floating ip test-instance $FIP

# 确认 floating ip 已添加到实例
(overcloud-project1user1) [stack@undercloud ~]$ openstack server show test-instance -f json -c addresses

# 从 undercloud ping 实例的 floating ip
(overcloud-project1user1) [stack@undercloud ~]$ ping -c3 $FIP
```