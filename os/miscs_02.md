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