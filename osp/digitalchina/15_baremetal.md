## 如何在 overcloud 里设置 Baremetal as a Service

### 定义 overcloud baremetal provisioning 网络
```
# 定义 overcloud provisioning 虚拟网络
cat > /tmp/oc-provisioning.xml <<EOF
<network>
  <name>oc-provisioning</name>
  <ip address="192.0.3.254" netmask="255.255.255.0"/>
</network>
EOF

virsh net-define /tmp/oc-provisioning.xml
virsh net-autostart oc-provisioning
virsh net-start oc-provisioning

overcloud controller 需要有网卡连接这个网络
overcloud baremetal node 也需要有网卡连接这个网络
```

### 配置 controller 的 nic-config
```
修改 templates/
```

### 参考文档
https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/baremetal_overcloud.html