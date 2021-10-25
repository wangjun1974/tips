### 杂项
Network Policy 生成工具<br>
https://editor.cilium.io/?id=en2dZle76uuVtRJo

OpenShift Project 定制<br>
https://developers.redhat.com/blog/2020/02/05/customizing-openshift-project-creation?ts=1632969031943#confirm_that_the_template_works

ChenChen 写的 Assisted Installer - OpenShift 文档<br>
https://github.com/cchen666/OpenShift-Labs/blob/main/Installation/Assisted-Installer.md

Quay.io
```
dig quay.io

quay.io. 42 IN A 52.22.41.62
quay.io. 42 IN A 34.224.196.162
quay.io. 42 IN A 52.0.232.252
quay.io. 42 IN A 3.216.152.103
quay.io. 42 IN A 3.214.183.120
quay.io. 42 IN A 50.16.140.223
quay.io. 42 IN A 3.213.173.170
quay.io. 42 IN A 3.233.133.41
```

```
osp 16.2: 在 undercloud 删除 stack 之后，overcloud 节点未被删除
执行以下命令清理 overcloud 节点
(undercloud) [stack@undercloud ~]$ for i in overcloud-ctrl01 overcloud-ctrl02 overcloud-ctrl03 overcloud-ceph01 overcloud-ceph02 overcloud-ceph03 overcloud-compute01 overcloud-compute02; do openstack baremetal node clean $i --clean-steps '[{"interface": "deploy", "step": "erase_devices_metadata"}]' ; openstack baremetal node manage $i ; openstack baremetal node provide $i ; done

(undercloud) [stack@undercloud ~]$ for i in overcloud-ctrl01 overcloud-ctrl02 overcloud-ctrl03 overcloud-ceph01 overcloud-ceph02 overcloud-ceph03 overcloud-compute01 overcloud-compute02; do openstack baremetal node maintenance unset $i ; openstack baremetal node manage $i ; openstack baremetal node provide $i ; done

查看 osp 16.2 安装日志
(undercloud) [stack@undercloud ~]$ sudo cat /var/lib/mistral/overcloud/ansible.log | grep -E 'TASK:' | cut -d '|' -f 2- | awk '!x[$0]++' | tail -10

(undercloud) [stack@undercloud ~]$ watch -n10 'sudo cat -n /var/lib/mistral/overcloud/ansible.log | grep -E "TASK:" | cut -d "|" -f 2- | cat -n | sort -uk2 | sort -n | cut -f2- | tail -10' 
https://stackoverflow.com/questions/11532157/remove-duplicate-lines-without-sorting

查看 osp16.2 ceph-ansible 安装日志
(undercloud) [stack@undercloud ~]$ watch -n10 'sudo cat -n /var/lib/mistral/overcloud/ceph-ansible/ceph_ansible_command.log | grep -E "TASK" | cut -d "|" -f 2- | cat -n | sort -uk2 | sort -n | cut -f2- | tail -10'

```

### 问题解决：更新 Mac OS 之后，git 命令报错
```
[junwang@JundeMacBook-Pro ~]$ git status
xcrun: error: invalid active developer path (/Library/Developer/CommandLineTools), missing xcrun at: /Library/Developer/CommandLineTools/usr/bin/xcrun

解决方法是重新安装开发工具 xcode-select
xcode-select --install
```

### Huawei CCE PV/PVC/StorageClass
https://support.huaweicloud.com/basics-cce/kubernetes_0030.html

### openstack vxlan 层次化端口绑定 ML2: Hierarchical Port Binding¶
https://bbs.huaweicloud.com/blogs/detail/148362<br>
https://specs.openstack.org/openstack/neutron-specs/specs/kilo/ml2-hierarchical-port-binding.html<br>

### osp 16.2 deployment failed.
```
pcs status
...
  * rabbitmq_start_0 on rabbitmq-bundle-1 'error' (1): call=2853, status='Timed Out', exitreason='', last-rc-change='2021-10-12 00:43:33Z', queued=0ms, exec=200033ms

pcs resource show rabbitmq-bundle
...
  Resource: rabbitmq (class=ocf provider=heartbeat type=rabbitmq-cluster)
   Attributes: set_policy="ha-all ^(?!amq\.).* {"ha-mode":"exactly","ha-params":2,"ha-promote-on-shutdown":"always"}"
   Meta Attrs: container-attribute-target=host notify=true
   Operations: monitor interval=10s timeout=40s (rabbitmq-monitor-interval-10s)
               start interval=0s timeout=200s (rabbitmq-start-interval-0s)
               stop interval=0s timeout=200s (rabbitmq-stop-interval-0s)

更新 resource rabbitmq 的 op start timeout
pcs resource update rabbitmq op start interval=0s timeout=400s
pcs resource update rabbitmq op monitor interval=10s timeout=120s

```

### osp 16.1 keystone oidc 的例子
https://gitlab.cee.redhat.com/sputhenp/lab/-/tree/master/templates/osp-16-1/oidc-federation

```
(overcloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph -s 
Warning: Permanently added 'overcloud-controller-0.ctlplane' (ECDSA) to the list of known hosts.
  cluster:
    id:     ea9612e6-e9fd-4897-891f-77df9acd94e8
    health: HEALTH_WARN
            mons are allowing insecure global_id reclaim
cat > ~/templates/node-info.yaml << 'EOF'
parameter_defaults:
  ControllerCount: 3
  ComputeCount: 0
  ComputeHCICount: 3

  # SchedulerHints
  ControllerSchedulerHints:
    'capabilities:node': 'controller-%index%'
  ComputeSchedulerHints:
    'capabilities:node': 'compute-%index%'
  ComputeHCISchedulerHints:
    'capabilities:node': 'computehci-%index%'
EOF
```

### osp 16.2 tripleo ipa 
在 osp 16.2 里，推荐的 ipa 集成方式不再是 novajoin 而是 tls-e ansible<br>
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.2/html/advanced_overcloud_customization/sect-tripleo-ipa<br>

### OpenShift Container Storage Planning
https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.7/pdf/planning_your_deployment/red_hat_openshift_container_storage-4.7-planning_your_deployment-en-us.pdf<br>

### OSP DCN templates
16.2<br>
central stack<br>
https://gitlab.cee.redhat.com/sputhenp/lab/-/blob/master/templates/osp-16-2/overcloud-deploy-tls-everywhere-ansible.sh<br>

edge stack<br>
https://gitlab.cee.redhat.com/sputhenp/lab/-/blob/master/templates/osp-16-2/hci-edge-1/overcloud-deploy-tls-everywhere-ansible.sh<br>

16.1<br>
central stack<br>
https://gitlab.cee.redhat.com/sputhenp/lab/-/blob/master/templates/osp-16-1/overcloud-deploy-tls-everywhere-ansible.sh<br>

edge stack<br>
https://gitlab.cee.redhat.com/sputhenp/lab/-/blob/master/templates/osp-16-1/edge-1/overcloud-deploy-tls-everywhere-ansible.sh<br>
https://gitlab.cee.redhat.com/sputhenp/lab/-/blob/master/templates/osp-16-1/edge-2/overcloud-deploy-tls-everywhere-ansible.sh<br>

### stf 清空告警 
```
清空 STF 告警规则
oc apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  creationTimestamp: null
  labels:
    prometheus: default
    role: alert-rules
  name: prometheus-alarm-rules
  namespace: service-telemetry
spec: {}
EOF

重新设置 STF 告警规则
oc apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  creationTimestamp: null
  labels:
    prometheus: default
    role: alert-rules
  name: prometheus-alarm-rules
  namespace: service-telemetry
spec: {}
  groups:
    - name: ./openstack.rules
      rules:
        - alert: Collectd Instance down
          expr: absent(collectd_cpu_percent{plugin_instance="0",type_instance="idle"}) == 1
          for: 1m
EOF
```

### STF 实例例子
```
apiVersion: infra.watch/v1beta1
kind: ServiceTelemetry
metadata:
  name: default
  namespace: service-telemetry
spec:
  alertmanagerConfigManifest: |
    apiVersion: v1
    kind: Secret
    metadata:
      name: 'alertmanager-default'
      namespace: 'service-telemetry'
    type: Opaque
    stringData:
      alertmanager.yaml: |-
        global:
          resolve_timeout: 10m
        route:
          group_by: ['job']
          group_wait: 30s
          group_interval: 5m
          repeat_interval: 12h
          receiver: 'email-me'
        receivers:
        - name: 'email-me'
          email_configs:
          - to: wjqhd@hotmail.com
            from: wjqhd@hotmail.com
            smarthost: smtp-mail.outlook.com:587
            auth_username: "wjqhd@hotmail.com"
            auth_identity: "wjqhd@hotmail.com"
            auth_password: "xxxxxxxxx"
  backends:
    events:
      elasticsearch:
        enabled: true
        storage:
          persistent:
            pvcStorageRequest: 20Gi
            storageSelector: {}
          strategy: persistent
      metrics:
        prometheus:
          enabled: true
          scrapeInterval: 10s
          storage:
            persistent:
              pvcStorageRequest: 20G
              storageSelector: {}
            retention: 24h
            strategy: persistent
  clouds:
    - events:
        collectors:
          - collectorType: collectd
            debugEnabled: false
            subscriptionAddress: collectd/notify
          - collectorType: ceilometer
            debugEnabled: false
            subscriptionAddress: anycast/ceilometer/event.sample
      metrics:
        collectors:
          - collectorType: collectd
            debugEnabled: false
            subscriptionAddress: collectd/telemetry
          - collectorType: ceilometer
            debugEnabled: false
            subscriptionAddress: anycast/ceilometer/metering.sample
          - collectorType: sensubility
            debugEnabled: false
            subscriptionAddress: sensubility/telemetry
      name: cloud1
  graphing:
    enabled: true
    grafana:
      ingressEnabled: true


# 安装 Service Telemetry Operator 时 csv smart-gateway-operator.v4.0.1634178588 处于 Pending 状态
# smart-gateway-operator ServiceAccount does not exist
oc get csv smart-gateway-operator.v4.0.1634178588 -o yaml
...
  phase: Pending
  reason: RequirementsNotMet
  requirementStatus:
  - group: operators.coreos.com
    kind: ClusterServiceVersion
    message: CSV minKubeVersion (1.20.0) less than server version (v1.21.1+d8043e1)
    name: smart-gateway-operator.v4.0.1634178588
    status: Present
    version: v1alpha1
  - group: apiextensions.k8s.io
    kind: CustomResourceDefinition
    message: CRD version not served
    name: smartgateways.smartgateway.infra.watch
    status: NotPresent
    version: v1
  - group: ""
    kind: ServiceAccount
    message: Service account does not exist
    name: smart-gateway-operator
    status: NotPresent
    version: v1


# 选择手工安装 Subscription service-telemetry-operator 
# 从 v1.3.2 开始装起
#   installPlanApproval: Manual
#   startingCSV: service-telemetry-operator.v1.3.2
# oc -n service-telemetry get installplan
# oc -n service-telemetry patch $(oc -n service-telemetry get installplan -o name) --type json -p='[{"op": "replace", "path": "/spec/approved", "value":true}]'

oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: service-telemetry-operator
  namespace: service-telemetry
spec:
  channel: unstable
  installPlanApproval: Automatic
  name: service-telemetry-operator
  source: infrawatch-operators
  sourceNamespace: openshift-marketplace
EOF



$ oc -n openshift-marketplace logs $(oc -n openshift-marketplace get pods -l olm.catalogSource=infrawatch-operators -o name) 
time="2021-10-15T02:50:21Z" level=warning msg="\x1b[1;33mDEPRECATION NOTICE:\nSqlite-based catalogs and their related subcommands are deprecated. Support for\nthem will be removed in a future release. Please migrate your catalog workflows\nto the new file-based catalog format.\x1b[0m"
time="2021-10-15T02:50:21Z" level=info msg="Keeping server open for infinite seconds" database=/database/index.db port=50051
time="2021-10-15T02:50:21Z" level=info msg="serving registry" database=/database/index.db port=50051

# rsh 到 catalog registry server 容器里查看一下里面运行的程序
# /bin/opm registry server 使用的数据库是 /database/index.db
oc -n openshift-marketplace rsh $(oc -n openshift-marketplace get pods -l olm.catalogSource=infrawatch-operators -o name) 
/ # ps ax 
PID   USER     TIME  COMMAND
    1 root      0:00 /bin/opm registry serve --database /database/index.db
 2252 root      0:00 /bin/sh
 2376 root      0:00 ps ax


# 从 catalog registry server 拷贝 /database/index.db 到本地
mkdir database
oc -n openshift-marketplace rsync $(oc -n openshift-marketplace get pods -l olm.catalogSource=infrawatch-operators -o name):/database/index.db database

# 查询 index.db 有哪些 tables 
echo ".tables" | sqlite3 -line ./database/index.db 
api                channel            deprecated         properties       
api_provider       channel_entry      operatorbundle     related_image    
api_requirer       dependencies       package            schema_migrations

# 查询 index.db 的 table channel 的内容
echo "select * from channel;" | sqlite3 -line ./database/index.db

# 使用 quay.io 的个人用户加密口令，登录 quay.io
podman login -u="jwang1" -p="xxxxxx" quay.io

oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-infrawatch-operators
  namespace: openshift-marketplace
spec:
  displayName: InfraWatch Operators for STF 1.3
  image: quay.io/jwang1/redhat-operator-stf-index:v4.6
  publisher: MyInfraWatch
  sourceType: grpc
EOF
```


### 如何为 OCP 4.8 准备 STF 1.3 CatalogSource
```
# STF 1.3 支持 OCP 4.6，因此所需的 catalogsource 包含在 OCP 4.6 的 redhat-operator 里
# 如果使用 OCP 4.7/4.8 等版本，需要自己准备 STF 1.3 的 catalogsource
# catalog 修剪及准备所使用的工具是 opm
# 以下是 STF 1.3 catalogsource 在 RHEL 8.4 上准备的过程
# 准备过程参考
# https://docs.openshift.com/container-platform/4.6/operators/admin/olm-restricted-networks.html#olm-pruning-index-image_olm-restricted-networks

# 安装下载 openshift-client
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.6.4/openshift-client-linux.tar.gz
tar zxf openshift-client-linux.tar.gz -C /usr/local/bin

# 安装下载 opm
wget https://mirror.openshift.com/pub/openshift-v4/clients/opm/4.6.1/opm-linux-4.6.1.tar.gz
tar zxf opm-linux-4.6.1.tar.gz -C /usr/local/bin

# 登陆 registry.redhat.io 和 目标 registry
podman login registry.redhat.io
podman login -u="jwang1" -p="xxxxxx" quay.io

# 修剪 redhat-operator-index:v4.6 image，只保留 service-telemetry-operator 和 smart-gateway-operator
# 把结果保存为 tag quay.io/jwang1/redhat-operator-stf-index:v4.6
opm index prune \
    -f registry.redhat.io/redhat/redhat-operator-index:v4.6 \
    -p service-telemetry-operator,smart-gateway-operator \
    -t quay.io/jwang1/redhat-operator-stf-index:v4.6

# 检查本地 images
podman images
REPOSITORY                                       TAG         IMAGE ID      CREATED        SIZE
quay.io/jwang1/redhat-operator-stf-index         v4.6        77fbb80f1d16  3 minutes ago  129 MB
registry.redhat.io/redhat/redhat-operator-index  v4.6        90817f50b29b  9 hours ago    685 MB
quay.io/operator-framework/upstream-opm-builder  latest      9b70e0f2b505  3 days ago     71.4 MB

# 推送 images 到目标 registry server
podman push quay.io/jwang1/redhat-operator-stf-index:v4.6

# 在 ocp 4.8 下定义 catalogsource
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-infrawatch-operators
  namespace: openshift-marketplace
spec:
  displayName: InfraWatch Operators for STF 1.3
  image: quay.io/jwang1/redhat-operator-stf-index:v4.6
  publisher: MyInfraWatch
  sourceType: grpc
EOF
```

### STF Grafana Dashboard 报错 Panel plugin not found: grafana-polystat-panel 的处理
```
比较奇怪的地方是，登陆进 grafana pods，查看确实有这个 plugins
oc rsh $(oc get pods -l app=grafana -o name)  
/usr/share/grafana $ ls /var/lib/grafana/plugins/
grafana-polystat-panel

在查看完并且退出后，这个报错就自然消失了

```

### 创建 project, user 
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


### cmd 
```
5.1创建 bridge 类型的 conn br0
[root@undercloud #] nmcli con add type bridge con-name br0 ifname br0
# (可选) 根据实际情况设置 bridge.stp，有时可能因为 bridge.stp 设置导致网络通信不正常，⚠️：在 lab 环境不需要执行
[root@undercloud #] nmcli con mod br0 bridge.stp no

# 修改 vlan 类型的 conn ens4 设置 master 为 br0 （参考）
[root@undercloud #] nmcli con mod ens4 connection.master br0 connection.slave-type 'bridge'

[root@undercloud #] nmcli con mod br0 \
    connection.autoconnect 'yes' \
    connection.autoconnect-slaves 'yes' \
    ipv4.method 'manual' \
    ipv4.address '10.25.149.21/24' \
    ipv4.gateway '10.25.149.1' 


cat << EOF > /root/host-bridge.xml
<network>
  <name>br0</name>
  <forward mode="bridge"/>
  <bridge name="br0"/>
</network>
EOF

virsh net-define /root/host-bridge.xml
virsh net-start br0
virsh net-autostart --network br0
virsh net-autostart --network default --disable
virsh net-destroy default


virt-install --name=helper-undercloud --vcpus=2 --ram=4096 --disk path=/var/lib/libvirt/images/helper-undercloud.qcow2,bus=virtio,size=100 --os-variant rhel8.0 --network network=br0,model=virtio --boot menu=on --graphics none --location  /osp16.1/redhat/isos/rhel-8.2-x86_64-dvd.iso --initrd-inject /tmp/ks.cfg --extra-args='ks=file:/ks.cfg console=ttyS0 ip=10.25.149.22::10.25.149.1:255.255.255.0:helper.example.com:enp1s0:none'

cat > /tmp/ks.cfg <<'EOF'
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
clearpart --all --initlabel
autopart
network --device=enp1s0 --hostname=helper.example.com --bootproto=static --ip=10.25.149.22 --netmask=255.255.255.0 --gateway=10.25.149.1
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
tar
kexec-tools
%end
EOF


yum -y install podman httpd httpd-tools wget jq
mkdir -p /opt/registry/{auth,certs,data}
tar zxvf osp16.1-poc-registry-2021-01-15.tar.gz -C /
cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract
firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public   --permanent
firewall-cmd --reload

tar zxvf podman-docker-registry-v2.image.tgz 
podman load -i docker-registry

cat > /usr/local/bin/localregistry.sh << 'EOF'
#!/bin/bash
podman run --name poc-registry -d -p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
localhost/docker-registry:latest 
EOF

chmod +x /usr/local/bin/localregistry.sh
/usr/local/bin/localregistry.sh

helper
cat >> /etc/hosts << EOF
10.25.149.21 undercloud.example.com
EOF

scp /opt/registry/certs/domain.crt stack@undercloud.example.com:~
ssh stack@undercloud.example.com sudo cp /home/stack/domain.crt /etc/pki/ca-trust/source/anchors/
ssh stack@undercloud.example.com sudo update-ca-trust extract

undercloud
cat >> /etc/hosts << EOF
10.25.149.22 helper.example.com
EOF

curl https://helper.example.com:5000/v2/_catalog

tar zxvf /osp16.1/redhat/repos/osp16.1-yum-repos-2021-01-15.tar.gz -C /
mkdir -p /etc/yum.repos.d/backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup

> /etc/yum.repos.d/osp.repo
for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms
do
cat >> /etc/yum.repos.d/osp.repo << EOF
[$i]
name=$i
baseurl=file:///var/www/html/repos/osp16.1/$i/
enabled=1
gpgcheck=0
EOF
done

sudo dnf module disable -y container-tools:rhel8
sudo dnf module enable -y container-tools:2.0

sudo dnf module disable -y virt:rhel
sudo dnf module enable -y virt:8.2

sudo dnf update -y
sudo reboot

cat > undercloud.conf << EOF
[DEFAULT]
undercloud_hostname = undercloud.example.com
container_images_file = containers-prepare-parameter.yaml
local_ip = 192.0.2.1/24
undercloud_public_host = 192.0.2.2
undercloud_admin_host = 192.0.2.3
#undercloud_nameservers = 192.0.2.254
subnets = ctlplane-subnet
local_subnet = ctlplane-subnet
#undercloud_service_certificate =
#generate_service_certificate = true
#certificate_generation_ca = local
local_interface = eno3
inspection_extras = true
undercloud_debug = false
enable_tempest = false
enable_ui = false
clean_nodes = true

[auth]
undercloud_admin_password = redhat

[ctlplane-subnet]
cidr = 192.0.2.0/24
dhcp_start = 192.0.2.25
dhcp_end = 192.0.2.44
inspection_iprange = 192.0.2.100,192.0.2.120
gateway = 192.0.2.1
masquerade = true
EOF

cat > containers-prepare-parameter.yaml  <<EOF
parameter_defaults:
  ContainerImagePrepare:
  - push_destination: true
    set:
      ceph_alertmanager_image: ose-prometheus-alertmanager
      ceph_alertmanager_namespace: helper.example.com:5000/openshift4
      ceph_alertmanager_tag: 4.1
      ceph_grafana_image: rhceph-4-dashboard-rhel8
      ceph_grafana_namespace: helper.example.com:5000/rhceph
      ceph_grafana_tag: 4
      ceph_image: rhceph-4-rhel8
      ceph_namespace: helper.example.com:5000/rhceph
      ceph_node_exporter_image: ose-prometheus-node-exporter
      ceph_node_exporter_namespace: helper.example.com:5000/openshift4
      ceph_node_exporter_tag: v4.1
      ceph_prometheus_image: ose-prometheus
      ceph_prometheus_namespace: helper.example.com:5000/openshift4
      ceph_prometheus_tag: 4.1
      ceph_tag: latest
      name_prefix: openstack-
      name_suffix: ''
      namespace: helper.example.com:5000/rhosp-rhel8
      neutron_driver: ovn
      rhel_containers: false
      tag: '16.1'
    tag_from_label: '{version}-{release}'
EOF

cat > /etc/chrony.conf << EOF
server 192.0.2.1 iburst
bindaddress 192.0.2.1
allow all
local stratum 4
EOF

vncserver :1
firewall-cmd --permanent --add-port=5901/tcp
firewall-cmd --permanent --add-port=5902/tcp
firewall-cmd --permanent --add-port=5903/tcp

iptables -I INPUT 1 -m state --state NEW -m tcp -p tcp --dport 5901 -j ACCEPT
iptables -I INPUT 1 -m state --state NEW -m tcp -p tcp --dport 5902 -j ACCEPT
iptables -I INPUT 1 -m state --state NEW -m tcp -p tcp --dport 5903 -j ACCEPT

mkdir ~/images
mkdir -p ~/templates/environments
sudo yum -y install rhosp-director-images


tar -C ~/images -xvf /usr/share/rhosp-director-images/overcloud-full-latest.tar
tar -C ~/images -xvf /usr/share/rhosp-director-images/ironic-python-agent-latest.tar

openstack overcloud image upload --image-path ~/images
openstack image list
ls -al /var/lib/ironic/httpboot/

curl -s -H "Accept: application/json" http://192.0.2.1:8787/v2/_catalog | jq .

cat > instackenv-ctrl.json <<EOF
{
  "nodes": [
    {
      "mac": [
        "e4:3d:1a:52:d3:12"
      ],
      "name": "overcloud-ctrl01",
      "pm_addr": "192.0.2.12",
      "pm_password": "rehat#poc#6xtp",
      "pm_type": "pxe_ipmitool",
      "pm_user": "root"
    },
    {
      "mac": [
        "e4:3d:1a:52:14:76"
      ],
      "name": "overcloud-ctrl02",
      "pm_addr": "192.0.2.13",
      "pm_password": "rehat#poc#6xtp",
      "pm_type": "pxe_ipmitool",
      "pm_user": "root"
    },    
    {
      "mac": [
        "e4:3d:1a:52:14:0a"
      ],
      "name": "overcloud-ctrl03",
      "pm_addr": "192.0.2.14",
      "pm_password": "rehat#poc#6xtp",
      "pm_type": "pxe_ipmitool",
      "pm_user": "root"
    }
  ]
}
EOF

(undercloud) [stack@undercloud ~]$ mkdir -p introspection
(undercloud) [stack@undercloud ~]$ pushd introspection
(undercloud) [stack@undercloud ~]$ for i in $(openstack baremetal node list -f value -c Name); do openstack baremetal introspection data save $i > $i.json ; done

openstack baremetal introspection data save overcloud-ctrl01 > overcloud-ctrl01.json
(undercloud) [stack@undercloud ~]$ pushd

cat > instackenv-ceph.json << EOF
{
  "nodes": [
    {
      "mac": [
        "34:73:5a:9f:f1:be"
      ],
      "name": "overcloud-ceph01",
      "pm_addr": "192.0.2.15",
      "pm_password": "rehat#poc#6xtp",
      "pm_type": "pxe_ipmitool",
      "pm_user": "root"
    },
    {
      "mac": [
        "34:73:5a:9f:ea:62"
      ],
      "name": "overcloud-ceph02",
      "pm_addr": "192.0.2.16",
      "pm_password": "rehat#poc#6xtp",
      "pm_type": "pxe_ipmitool",
      "pm_user": "root"
    },
        {
      "mac": [
        "34:73:5a:a0:0a:02"
      ],
      "name": "overcloud-ceph03",
      "pm_addr": "192.0.2.17",
      "pm_password": "rehat#poc#6xtp",
      "pm_type": "pxe_ipmitool",
      "pm_user": "root"
    }
  ]
}
EOF

cd introspection
for i in $(openstack baremetal node list -f value -c Name); do openstack baremetal introspection data save $i > $i.json ; done

cd ~
for i in $(openstack baremetal node list -f value -c Name); do openstack baremetal node manage $i ; openstack baremetal introspection start --wait $i; openstack baremetal node provide $i ; done


export THT=/usr/share/openstack-tripleo-heat-templates/


openstack baremetal node set --property capabilities='node:controller-0,boot_option:local' overcloud-ctrl01
openstack baremetal node set --property capabilities='node:controller-1,boot_option:local' overcloud-ctrl02
openstack baremetal node set --property capabilities='node:controller-2,boot_option:local' overcloud-ctrl03

openstack baremetal node set --property capabilities='node:computehci-0,boot_option:local' overcloud-ceph01
openstack baremetal node set --property capabilities='node:computehci-1,boot_option:local' overcloud-ceph02
openstack baremetal node set --property capabilities='node:computehci-2,boot_option:local' overcloud-ceph03



cat > ~/templates/node-info.yaml << 'EOF'
parameter_defaults:
  ControllerCount: 3
  ComputeCount: 0
  ComputeHCICount: 3

  # SchedulerHints
  ControllerSchedulerHints:
    'capabilities:node': 'controller-%index%'
  ComputeSchedulerHints:
    'capabilities:node': 'compute-%index%'
  ComputeHCISchedulerHints:
    'capabilities:node': 'computehci-%index%'
EOF



cat overcloud-ctrl01.json | jq .inventory.disks
openstack baremetal node set --property root_device='{"serial": "Z92UKHHOF69D"}' overcloud-ctrl01


cat overcloud-ceph01.json | jq .inventory.disks
openstack baremetal node set --property root_device='{"serial": "Z92UKHHOF69D"}' overcloud-ceph01

export THT=/usr/share/openstack-tripleo-heat-templates/
openstack overcloud roles generate -o ~/templates/roles_data.yaml Controller Compute ComputeHCI

cp $THT/network_data.yaml ~/templates

rm -rf ~/rendered
mkdir ~/rendered

cd $THT
tools/process-templates.py -r ~/templates/roles_data.yaml -n ~/templates/network_data.yaml -o ~/rendered

cd ~/rendered
rm -rf ~/templates/environments
mkdir -p ~/templates/environments
cp environments/network-environment.yaml ~/templates/environments

rm -rf ~/templates/network
cp -rp network ~/templates

cp environments/net-bond-with-vlans.yaml ~/templates/environments/

cat > ~/templates/cephstorage.yaml << EOF
parameter_defaults:
  CephConfigOverrides:
    mon_max_pg_per_osd: 600
  CephAnsibleDisksConfig:
    devices:
      - /dev/disk/by-path/pci-0000:00:09.0
      - /dev/disk/by-path/pci-0000:00:0a.0
      - /dev/disk/by-path/pci-0000:00:0b.0
    osd_scenario: lvm
    osd_objectstore: bluestore
EOF

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
--ntp-server 192.0.2.1
EOF

ipxe_enabled = True
inspection_enable_uefi = True

openstack undercloud install

openstack flavor set --property capabilities:boot_mode='uefi' control

openstack baremetal node set --property capabilities='node:controller-0,boot_option:uefi' overcloud-ctrl01
openstack baremetal node set --property capabilities='node:controller-1,boot_option:uefi' overcloud-ctrl02
openstack baremetal node set --property capabilities='node:controller-2,boot_option:uefi' overcloud-ctrl03

openstack baremetal node set --property capabilities='node:computehci-0,boot_option:uefi' overcloud-ceph01
openstack baremetal node set --property capabilities='node:computehci-1,boot_option:uefi' overcloud-ceph02
openstack baremetal node set --property capabilities='node:computehci-2,boot_option:uefi' overcloud-ceph03

cd introspection
for i in $(openstack baremetal node list -f value -c Name); do openstack baremetal introspection data save $i > $i.json ; done

cd ~


二、今天主要完成了如下技术事项：
1. 收集硬件信息
2. 为节点设定root_device
3. 生成 overcloud 包含 ceph 在内的部署模版
4. 配置 overcloud 不同角色网卡与部署网络和数据网络的映射关系
5. 执行 overcloud 部署
6. 排错

目前所遇到的问题:
1. overcloud 在部署初期会通过网络启动向被部署节点磁盘写入系统，然后会重启然后从本地硬盘启动。目前部署在重启后，无法从本地硬盘启动，这个问题正在排查中

systemctl status <pid> 
查看 pid 对应的服务及 systemd 相关信息

openstack baremetal port create --node  

sudo podman exec -it neutron_conductor cat /etc/neutron/neutron.conf | grep mysql | grep connection
sudo podman exec -it mysql mysql -u neutron -p 



delete instance 
REQ: curl -g -i -X GET https://overcloud.example.com:13774/v2.1/servers/test-instance -H "Accept: application/json" -H "OpenStack-API-Version: compute 2.79" -H "User-Agent: python-novaclient" -H "X-Auth-Token: {SHA256}b82d934d1eb0742d8e98c3a948af29111b8385205fa166714501d3e4b282baa1" -H "X-OpenStack-Nova-API-Version: 2.79"
Starting new HTTPS connection (1): overcloud.example.com:13774
--
REQ: curl -g -i -X GET https://overcloud.example.com:13774/v2.1/servers?name=test-instance -H "Accept: application/json" -H "OpenStack-API-Version: compute 2.79" -H "User-Agent: python-novaclient" -H "X-Auth-Token: {SHA256}b82d934d1eb0742d8e98c3a948af29111b8385205fa166714501d3e4b282baa1" -H "X-OpenStack-Nova-API-Version: 2.79"
https://overcloud.example.com:13774 "GET /v2.1/servers?name=test-instance HTTP/1.1" 200 None
--
REQ: curl -g -i -X GET https://overcloud.example.com:13774/v2.1/servers/6b88476d-2d0a-492d-887e-6d99a7f9f7b4 -H "Accept: application/json" -H "OpenStack-API-Version: compute 2.79" -H "User-Agent: python-novaclient" -H "X-Auth-Token: {SHA256}b82d934d1eb0742d8e98c3a948af29111b8385205fa166714501d3e4b282baa1" -H "X-OpenStack-Nova-API-Version: 2.79"
https://overcloud.example.com:13774 "GET /v2.1/servers/6b88476d-2d0a-492d-887e-6d99a7f9f7b4 HTTP/1.1" 200 None
--
REQ: curl -g -i -X DELETE https://overcloud.example.com:13774/v2.1/servers/6b88476d-2d0a-492d-887e-6d99a7f9f7b4 -H "Accept: application/json" -H "OpenStack-API-Version: compute 2.79" -H "User-Agent: python-novaclient" -H "X-Auth-Token: {SHA256}b82d934d1eb0742d8e98c3a948af29111b8385205fa166714501d3e4b282baa1" -H "X-OpenStack-Nova-API-Version: 2.79"
https://overcloud.example.com:13774 "DELETE /v2.1/servers/6b88476d-2d0a-492d-887e-6d99a7f9f7b4 HTTP/1.1" 204 0

openstack server remove floating ip <instance-name> <floating-ip>


# osp 16.2 rabbitmq 日志报错
/var/log/containers/rabbitmq/rabbit\@overcloud-controller-0.log

2021-10-21 07:33:14.281 [error] <0.1159.0> Node 'rabbit@overcloud-controller-1' thinks it's clustered with node 'rabbit@overcloud-controller-0', but 'rabbit@overcloud-controller-0' disagrees
https://cloud.tencent.com/developer/article/1158754


尝试恢复 rabbitmq 资源
pcs resource disable rabbitmq-bundle
pcs resource enable rabbitmq-bundle
pcs resource cleanup rabbitmq-bundle
https://access.redhat.com/solutions/3182721

Using Curl to Interact with a RESTful API
https://blog.scottlowe.org/2014/02/19/using-curl-to-interact-with-a-restful-api/

将 json 转换为单行的网址
https://tools.knowledgewalls.com/online-multiline-to-single-line-converter

https://docs.openstack.org/keystone/pike/api_curl_examples.html

https://lrainsun.github.io/2020/07/21/keystone-scope/

curl -sd '{"auth":{"passwordCredentials":{"username": "project1admin", "password": "redhat"}}}' -H "Content-type: application/json" https://overcloud.example.com:13000/v3/auth/tokens

{
  "auth": {
    "identity": {
      "methods": [
        "password"
      ],
      "password": {
        "user": {
          "name": "project1admin",
          "domain": {
            "name": "Default"
          },
          "project": {
            "domain": {
              "name": "Default"
            }
            "name": "project1"
          },
          "password": "redhat"
        }
      }
    },
        "scope": {
            "system": {
                "all": true
            }
        }    
  }
}

    "user": {
      "domain": {
        "id": "default",
        "name": "Default"
      },
      "id": "56cf80765d744bc49f23b6e79e66ac47",
      "name": "project1admin",
      "password_expires_at": null
    },

{
    "auth": {
        "identity": {
            "methods": [
                "password"
            ],
            "password": {
                "user": {
                    "name": "project1admin",
                    "password": "redhat"
                }
            }
        },
        "scope": {
            "domain": {
                "id": "default"
            }
        }
    }
}

curl -i \
  -H "Content-Type: application/json" \
  -d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "admin",
          "password": "EUbg242vwZtuVBzDZlg0C0TKt"
        }
      },
      "scope": {
        "project": {
          "name": "admin"
        }
      }     
    }
  }
}' \
https://overcloud.example.com:13000/v3/auth/tokens 2>&1 | tee /tmp/tempfile

token=$(cat /tmp/tempfile | awk '/X-Subject-Token: /{print $NF}' | tr -d '\r' )
echo $token
export mytoken=$token


curl -i \
  -H "Content-Type: application/json" \
  -d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "admin",
          "domain": { "id": "default" },
          "password": "EUbg242vwZtuVBzDZlg0C0TKt"
        }
      },
      "scope": {
        "project": {
          "domain": {
            "id": "default"
          },
          "name": "admin"
        }
      }     
    }
  }
}' \
https://overcloud.example.com:13000/v3/auth/tokens 2>&1 | tee /tmp/tempfile

token=$(cat /tmp/tempfile | awk '/X-Subject-Token: /{print $NF}' | tr -d '\r' )
echo $token
export mytoken=$token



res=$(curl -sD - \
-H "Content-Type: application/json" \
-d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"project1admin","password":"redhat"}}},"scope":{"domain":{"id":"default"}}}}' \
https://overcloud.example.com:13000/v3/auth/tokens)


{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"project1admin","password":"redhat"}}},"scope":{"system":{"all":true}}}}

res=$( curl -sD - -o /dev/null \
-H "Content-Type: application/json" \
-d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"project1admin","password":"redhat"}}}}' \
https://overcloud.example.com:13000/v3/auth/tokens)

echo "GETTING TOKEN"
res=$( curl -sD - -o /dev/null \
-H "Content-Type: application/json" \
-d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"project1admin","domain":{"name":"Default"},"project":{"name":"project1"},"password":"redhat"}}}}}' \
https://overcloud.example.com:13000/v3/auth/tokens)

token=$(echo "$res" | awk '/X-Subject-Token: /{print $NF}' | tr -d '\r' )

echo $token
export mytoken=$token

echo "GETTING IMAGES"
imageid=$(curl -s \
--header "X-Auth-Token: $mytoken" \
 https://overcloud.example.com:13292/v2/images | jq '.images[] | select(.name=="cirros")' | jq -r '.id' )

echo "GETTING FLAVOR"
flavorid=$(curl -s \
--header "X-Auth-Token: $mytoken" \
https://overcloud.example.com:13774/v2.1/flavors | jq '.flavors[] | select(.name=="m1.nano")' | jq -r '.id' )

echo "GET NETWORK"
networkid=$(curl -s \
-H "Accept: application/json" \
-H "User-Agent: openstacksdk/0.36.5 keystoneauth1/3.17.4 python-requests/2.20.0 CPython/3.6.8" \
--header "X-Auth-Token: $mytoken" \
https://overcloud.example.com:13696/v2.0/networks | jq '.networks[] | select(.name=="project1-private")' | jq -r '.id' )

echo "CREATESERVER"
echo curl -g -i -X POST https://overcloud.example.com:13774/v2.1/servers \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "X-Auth-Token: $mytoken" -d "{\"server\": {\"name\": \"test-instance\", \"imageRef\": \"$imageid\", \"flavorRef\": \"$flavorid\", \"min_count\": 1, \"max_count\": 1, \"networks\": [{\"uuid\": \"$networkid\"}]}}"

OS_TOKEN=$(curl -isX POST $OS_AUTH_URL/v3/auth/tokens?nocatalog -H "Content-Type: application/json" -d '{ "auth": { "identity": { "methods": ["password"],"password": {"user": {"domain": {"name": "'"$OS_USER_DOMAIN_NAME"'"},"name": "'"$OS_USERNAME"'", "password": "'"$OS_PASSWORD"'"} } }, "scope": { "project": { "domain": { "name": "'"$OS_PROJECT_DOMAIN_NAME"'" }, "name": "'"$OS_PROJECT_NAME"'" } } }}' | grep X-Subject-Token | awk '{print $2}')

alias oscurl='curl -s -H "X-Auth-Token: $OS_TOKEN"'
oscurl https://overcloud.example.com:13696/v2.0/networks
출처: https://www.jacobbaek.com/1190 [Jacob Baek's home]
https://www.jacobbaek.com/1190


curl -i \
  -H "Content-Type: application/json" \
  -d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "admin",
          "domain": { "id": "default" },
          "password": "RedHat1!"
        }
      }
    },
    "scope": {
      "project": {
        "name": "admin",
        "domain": { "id": "default" }
      }
    }
  }
}' \
  "https://overcloud.example.com:5000/v3/auth/tokens" ; echo
 
 
 
 
HTTP/1.1 201 CREATED
Date: Fri, 22 Oct 2021 03:38:45 GMT
Server: Apache
Content-Length: 6709
X-Subject-Token: gAAAAABhcjJGwHeDJ72fZZTM15HFH3puMi8GFrmS4KX0VJ8kl4HhC35bYDXDymZ1AFzcPT_XBlamjlwtrzUpT0wvu0bt5nafFqzLxd8DIvrPB1T4flE5P0hV4PIm3yuJ5ge9tCv3TD9GhBXCC7UxtWeeFoPedGfvQ-hGacmBbwh-ZgOQ5KOlDpQ
Vary: X-Auth-Token
x-openstack-request-id: req-22a74d5e-2cc8-4ec2-922b-4847e5a36d53
Content-Type: application/json
 
{"token": {"methods": ["password"], "user": {"domain": {"id": "default", "name": "Default"}, "id": "02abbb9cd04b427287b7931ff7a7fbc6", "name": "admin", "password_expires_at": null}, "audit_ids": ["93GFg9ykRhmjvTlsmI2Lzg"], "expires_at": "2021-10-22T04:38:46.000000Z", "issued_at": "2021-10-22T03:38:46.000000Z", "project": {"domain": {"id": "default", "name": "Default"}, "id": "2e74c13e0f744f88849bbbf905a12fc7", "name": "admin"}, "is_domain": false, "roles": [{"id": "3607f335fdbc419aabcb86d9fe0fd5e8", "name": "member"}, {"id": "e0cecfa4accd47488a61b657bb152676", "name": "admin"}, {"id": "160363fcb7eb439c8687e423f92ddcd3", "name": "reader"}], "catalog": [{"endpoints": [{"id": "68cfd07a3a59433c9d0c0e7a1b554126", "interface": "public", "region_id": "regionOne", "url": "http://10.72.51.135:5000", "region": "regionOne"}, {"id": "92bef904faa944238c3819094d57c8de", "interface": "internal", "region_id": "regionOne", "url": "http://10.72.51.230:5000", "region": "regionOne"}, {"id": "c2b9051dec214eb0889451e141a1e35e", "interface": "admin", "region_id": "regionOne", "url": "http://192.168.24.8:35357", "region": "regionOne"}], "id": "05599436f4ea4ad8967dad43faee2b5d", "type": "identity", "name": "keystone"}, {"endpoints": [{"id": "32b7ee48690a43e1b9369243ba5c40b6", "interface": "internal", "region_id": "regionOne", "url": "http://10.72.51.230:8774/v2.1", "region": "regionOne"}, {"id": "d181c9bda35c4ba1af596471dbb0f6f2", "interface": "public", "region_id": "regionOne", "url": "http://10.72.51.135:8774/v2.1", "region": "regionOne"}, {"id": "d3b84f5fd32545a19e710848b7b44246", "interface": "admin", "region_id": "regionOne", "url": "http://10.72.51.230:8774/v2.1", "region": "regionOne"}], "id": "2c683ecacfda4606908395b82da75aee", "type": "compute", "name": "nova"}, {"endpoints": [{"id": "54361762ca854c519ab73f6826bc49e8", "interface": "public", "region_id": "regionOne", "url": "http://10.72.51.135:8004/v1/2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}, {"id": "68c7d5d877a94351a3a175604d6eb608", "interface": "admin", "region_id": "regionOne", "url": "http://10.72.51.230:8004/v1/2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}, {"id": "cfa68dae084c4471ba324d3b4d9cdb4e", "interface": "internal", "region_id": "regionOne", "url": "http://10.72.51.230:8004/v1/2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}], "id": "3c9363fd0bb5469da087ae97b8d99847", "type": "orchestration", "name": "heat"}, {"endpoints": [{"id": "14f096c2a7b44e36ac66f6bc20b8be3a", "interface": "internal", "region_id": "regionOne", "url": "http://10.72.51.230:9696", "region": "regionOne"}, {"id": "717f4fcf6c0b42a78c2d9e7af4360916", "interface": "admin", "region_id": "regionOne", "url": "http://10.72.51.230:9696", "region": "regionOne"}, {"id": "89f5d7d7c29b404b8bfd121144870084", "interface": "public", "region_id": "regionOne", "url": "http://10.72.51.135:9696", "region": "regionOne"}], "id": "559838b6b42641908ad8a2c662336873", "type": "network", "name": "neutron"}, {"endpoints": [{"id": "1030a03817724d1a96885e065c86b1ec", "interface": "public", "region_id": "regionOne", "url": "http://10.72.51.135:9292", "region": "regionOne"}, {"id": "7602062e6a2a4eae8c941963965fbf63", "interface": "admin", "region_id": "regionOne", "url": "http://10.72.51.230:9292", "region": "regionOne"}, {"id": "7dd42e479cbf4318a0f6fdd45ac9ad59", "interface": "internal", "region_id": "regionOne", "url": "http://10.72.51.230:9292", "region": "regionOne"}], "id": "5ac1de8357754403910b33b69cab46fa", "type": "image", "name": "glance"}, {"endpoints": [{"id": "0af858c9a40944e1b5ff6c121bfd4cd9", "interface": "public", "region_id": "regionOne", "url": "http://10.72.51.135:8000/v1", "region": "regionOne"}, {"id": "5c55d70871dd43d5a831788636ba025d", "interface": "admin", "region_id": "regionOne", "url": "http://10.72.51.230:8000/v1", "region": "regionOne"}, {"id": "a2da1473aa0c4a1d821c41ce20122b50", "interface": "internal", "region_id": "regionOne", "url": "http://10.72.51.230:8000/v1", "region": "regionOne"}], "id": "5c5abbe554054bdd8643a70f55ab90a9", "type": "cloudformation", "name": "heat-cfn"}, {"endpoints": [{"id": "453ad0f494734a4bad572ef99b336ff8", "interface": "internal", "region_id": "regionOne", "url": "http://10.72.51.230:8776/v2/2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}, {"id": "9000071da5c24d539642e5c02d6e563c", "interface": "public", "region_id": "regionOne", "url": "http://10.72.51.135:8776/v2/2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}, {"id": "92c682ca6b0a4d539bca3c788480a9fd", "interface": "admin", "region_id": "regionOne", "url": "http://10.72.51.230:8776/v2/2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}], "id": "68edb1f0ea064c7aad55386ba0003474", "type": "volumev2", "name": "cinderv2"}, {"endpoints": [{"id": "42f02d0ce93847f28ac3141cdd268a4d", "interface": "public", "region_id": "regionOne", "url": "http://10.72.51.135:8080/swift/v1/AUTH_2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}, {"id": "987c5e29efb24e98989a48ea87315be4", "interface": "admin", "region_id": "regionOne", "url": "http://10.72.51.210:8080/swift/v1/AUTH_2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}, {"id": "e82ade12f29b474991eb1eeb722a776f", "interface": "internal", "region_id": "regionOne", "url": "http://10.72.51.210:8080/swift/v1/AUTH_2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}], "id": "7e25ce55e1bd4a2199aa417016e11f2a", "type": "object-store", "name": "swift"}, {"endpoints": [{"id": "2b52e74c3e894e42bb270117efa0ac03", "interface": "public", "region_id": "regionOne", "url": "http://10.72.51.135:8776/v3/2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}, {"id": "5a170a018781455ebded6b0a96204e2f", "interface": "internal", "region_id": "regionOne", "url": "http://10.72.51.230:8776/v3/2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}, {"id": "9bf81d6a1ffc469184a49b98ac308036", "interface": "admin", "region_id": "regionOne", "url": "http://10.72.51.230:8776/v3/2e74c13e0f744f88849bbbf905a12fc7", "region": "regionOne"}], "id": "843506b3575e4b2c952fb00c0459b7b6", "type": "volumev3", "name": "cinderv3"}, {"endpoints": [{"id": "2f355aa1910f480d8284ebe8d63419e1", "interface": "internal", "region_id": "regionOne", "url": "http://10.72.51.230:8778/placement", "region": "regionOne"}, {"id": "d5e32f5987794e78bb3a2c068a892f45", "interface": "admin", "region_id": "regionOne", "url": "http://10.72.51.230:8778/placement", "region": "regionOne"}, {"id": "f2266539cd194c11b31a5cf247f8c3ef", "interface": "public", "region_id": "regionOne", "url": "http://10.72.51.135:8778/placement", "region": "regionOne"}], "id": "dae0f0b66f0e4afbbd432341111d678d", "type": "placement", "name": "placement"}]}}
 
 
 
 
 
$ curl -g -i -X GET http://10.72.51.135:9696/v2.0/networks.json?limit=100 -H "Accept: application/json"  -H "X-Auth-Token: gAAAAABhcjJGwHeDJ72fZZTM15HFH3puMi8GFrmS4KX0VJ8kl4HhC35bYDXDymZ1AFzcPT_XBlamjlwtrzUpT0wvu0bt5nafFqzLxd8DIvrPB1T4flE5P0hV4PIm3yuJ5ge9tCv3TD9GhBXCC7UxtWeeFoPedGfvQ-hGacmBbwh-ZgOQ5KOlDpQ"
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 2881
X-Openstack-Request-Id: req-2568faf0-6754-4fbd-a0db-700d5904bb76
Date: Fri, 22 Oct 2021 03:39:14 GMT
 
{"networks":[{"id":"13cd06d5-230e-4c7e-aac7-e21826282f10","name":"adminpriv","tenant_id":"2e74c13e0f744f88849bbbf905a12fc7","admin_state_up":true,"mtu":1450,"status":"ACTIVE","subnets":["bb68eb22-e25b-4bc2-a2ae-96a0262a6b47"],"shared":false,"availability_zone_hints":[],"availability_zones":["nova"],"ipv4_address_scope":null,"ipv6_address_scope":null,"router:external":false,"description":"","port_security_enabled":true,"qos_policy_id":null,"tags":[],"created_at":"2021-09-10T11:01:19Z","updated_at":"2021-09-10T11:01:19Z","revision_number":2,"project_id":"2e74c13e0f744f88849bbbf905a12fc7","provider:network_type":"vxlan","provider:physical_network":null,"provider:segmentation_id":1},{"id":"32bfe08d-d4d1-4375-bdaa-2446c4fbece9","name":"sriov184","tenant_id":"2e74c13e0f744f88849bbbf905a12fc7","admin_state_up":true,"mtu":1500,"status":"ACTIVE","subnets":["9fd52cdc-0fae-446c-8bb2-eda865a8ce78"],"shared":true,"availability_zone_hints":[],"availability_zones":["nova"],"ipv4_address_scope":null,"ipv6_address_scope":null,"router:external":false,"description":"","port_security_enabled":true,"qos_policy_id":null,"tags":[],"created_at":"2021-09-10T11:04:00Z","updated_at":"2021-09-26T08:06:49Z","revision_number":3,"project_id":"2e74c13e0f744f88849bbbf905a12fc7","provider:network_type":"vlan","provider:physical_network":"sriov-1","provider:segmentation_id":184},{"id":"3e59cd2c-6a66-4034-b423-3ec61933f5bc","name":"HA network tenant 2e74c13e0f744f88849bbbf905a12fc7","tenant_id":"","admin_state_up":true,"mtu":1450,"status":"ACTIVE","subnets":["d3427f35-553e-4da4-8596-b283b156f550"],"shared":false,"availability_zone_hints":[],"availability_zones":["nova"],"ipv4_address_scope":null,"ipv6_address_scope":null,"router:external":false,"description":"","port_security_enabled":true,"qos_policy_id":null,"tags":[],"created_at":"2021-10-14T07:54:08Z","updated_at":"2021-10-14T07:54:08Z","revision_number":2,"project_id":"","provider:network_type":"vxlan","provider:physical_network":null,"provider:segmentation_id":2},{"id":"acb2c2ae-adcd-409d-9c54-ddcd3c5dedbc","name":"ext183","tenant_id":"2e74c13e0f744f88849bbbf905a12fc7","admin_state_up":true,"mtu":1500,"status":"ACTIVE","subnets":["c16c2c0d-bebb-49fb-914f-9f611ff22295"],"shared":true,"availability_zone_hints":[],"availability_zones":["nova"],"ipv4_address_scope":null,"ipv6_address_scope":null,"router:external":true,"description":"","port_security_enabled":true,"qos_policy_id":null,"is_default":false,"tags":[],"created_at":"2021-09-26T02:45:37Z","updated_at":"2021-09-26T07:29:55Z","revision_number":5,"project_id":"2e74c13e0f744f88849bbbf905a12fc7","provider:network_type":"vlan","provider:physical_network":"datacentre","provider:segmentation_id":183}],"networks_links":[{"rel":"previous","href":"http://10.72.51.135:9696/v2.0/networks.json?limit=100&marker=13cd06d5-230e-4c7e-aac7-e21826282f10&page_reverse=True"}]}


curl -i \
  -H "Content-Type: application/json" \
  -d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "admin",
          "domain": { "id": "default" },
          "password": "EUbg242vwZtuVBzDZlg0C0TKt"
        }
      }
    },
    "scope": {
      "project": {
        "name": "admin",
        "domain": { "id": "default" }
      }
    }
  }
}' \
https://overcloud.example.com:13000/v3/auth/tokens 2>&1 | tee /tmp/tempfile

token=$(cat /tmp/tempfile | awk '/X-Subject-Token: /{print $NF}' | tr -d '\r' )
echo $token
export mytoken=$token

curl -i \
  -H "Content-Type: application/json" \
  -d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "project1admin",
          "domain": { "id": "default" },
          "password": "redhat"
        }
      }
    },
    "scope": {
      "project": {
        "name": "project1",
        "domain": { "id": "default" }
      }
    }
  }
}' \
https://overcloud.example.com:13000/v3/auth/tokens 2>&1 | tee /tmp/tempfile

token=$(cat /tmp/tempfile | awk '/X-Subject-Token: /{print $NF}' | tr -d '\r' )
echo $token
export mytoken=$token

set -o pipefail; puppet apply  --modulepath=/etc/puppet/modules:/opt/stack/puppet-modules:/usr/share/openstack-puppet/modules --detailed-exitcodes --summarize --color=false   /var/lib/tripleo-config/puppet_step_config.pp 2>&1 | logger -s -t puppet-user

<13>Oct 25 01:53:29 puppet-user: Error: /Stage[main]/Tripleo::Profile::Base::Certmonger_user/Tripleo::Certmonger::Haproxy[haproxy-oc_provisioning]/Concat[/etc/pki/tls/certs/haproxy/overcloud-haproxy-oc_provisioning.pem]/Concat_file[/etc/pki/tls/certs/haproxy/overcloud-haproxy-oc_provisioning.pem]: Failed to generate additional resources using 'eval_generate': Could not retrieve source(s) /etc/pki/tls/certs/haproxy/overcloud-haproxy-oc_provisioning.crt

+ openstack overcloud deploy --debug --templates /usr/share/openstack-tripleo-heat-templates/ -r /home/stack/templates//roles_data.yaml -n /home/stack/templates//network_data.yaml -e /usr/share/openstack-tripleo-heat-templates//environments/network-isolation.yaml -e /home/stack/templates//environments/network-environment.yaml -e /home/stack/templates//environments/net-bond-with-vlans.yaml -e /usr/share/openstack-tripleo-heat-templates//environments/services/ironic-overcloud.yaml -e /usr/share/openstack-tripleo-heat-templates//environments/services/ironic-inspector.yaml -e /usr/share/openstack-tripleo-heat-templates//environments/metrics/ceilometer-write-qdr.yaml -e /usr/share/openstack-tripleo-heat-templates//environments/metrics/collectd-write-qdr.yaml -e /usr/share/openstack-tripleo-heat-templates//environments/metrics/qdr-edge-only.yaml -e /home/stack/containers-prepare-parameter.yaml -e /home/stack/templates//node-info.yaml -e /home/stack/templates//fix-nova-reserved-host-memory.yaml -e /home/stack/templates//ironic.yaml -e /home/stack/templates//enable-stf.yaml -e /home/stack/templates//stf-connectors.yaml --ntp-server 192.0.2.1

```

### 如何设置来影响 page cache 的内存占用
https://access.redhat.com/solutions/32769

### TripleO config-download User’s Guide: Deploying with Ansible
https://slagle.fedorapeople.org/tripleo-docs/install/advanced_deployment/ansible_config_download.html

### 如何避免 osp 节点消耗不必要的订阅
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/13/html-single/deploying_an_overcloud_with_containerized_red_hat_ceph/index#using-the-overcloud-minimal-image-to-avoid-to-avoid-using-a-Red-Hat-subscription-entitlement