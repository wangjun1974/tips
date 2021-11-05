### 集成 Service Telemetry Framework 
https://infrawatch.github.io/documentation/#assembly-introduction-to-stf_assembly
```
1.1 切换到普通用户
su - jwang

1.2 下载 Code Ready Container 1.9.0
注意：在实验环境下，没有选择在 CRC 下安装 STF，而是选择在 ocp1 下安装 STF，然后把 osp 集成到 ocp1 的 STF 上去
curl -O -L https://mirror.openshift.com/pub/openshift-v4/clients/crc/1.9.0/crc-linux-amd64.tar.xz

1.3 解压缩
tar xvfJ crc-linux-amd64.tar.xz

1.4 设置 crc
cd crc-linux-1.9.0-amd64
./crc setup

1.5 启动 crc 并设置使用的 cpu 和内存
./crc start -m 16000 -c 12
输入 pull-secret

1.6 设置环境变量
$ eval $(./crc oc-env)

1.7 登录 crc
oc login -u kubeadmin -p https://api.crc.testing:6443

2. 安装 Service Telemetry Framework 核心组件
2.1 创建 project service-telemetry
oc new-project service-telemetry

2.2 创建 OperatorGroup service-telemetry-operator-group
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: service-telemetry-operator-group
  namespace: service-telemetry
spec:
  targetNamespaces:
  - service-telemetry
EOF
oc get operatorgroup

2.3 创建 CatalogSource operatorhubio-operators
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: operatorhubio-operators
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: quay.io/operator-framework/upstream-community-operators:latest
  displayName: OperatorHub.io Operators
  publisher: OperatorHub.io
EOF

$ oc get catalogsource operatorhubio-operators -n openshift-marketplace
NAME                      DISPLAY                    TYPE   PUBLISHER        AGE
operatorhubio-operators   OperatorHub.io Operators   grpc   OperatorHub.io   5m28s      <== 这个是新添加的

2.4 创建 CatalogSource InfraWatch - 这个 CatalogSource 包含 Service Telemetry Operator 和 Smart Gateway Operator
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: infrawatch-operators
  namespace: openshift-marketplace
spec:
  displayName: InfraWatch Operators
  image: quay.io/infrawatch-operators/infrawatch-catalog:nightly
  publisher: InfraWatch
  sourceType: grpc
  updateStrategy:
    registryPoll:
      interval: 30m
EOF

检查 catalogsource infrawatch-operator
$ oc get -nopenshift-marketplace catalogsource infrawatch-operators
NAME                      DISPLAY                    TYPE   PUBLISHER        AGE
infrawatch-operators      InfraWatch Operators       grpc   InfraWatch       21s        <== 这个是新添加的

检查 InfraWatch 所提供的 packagemanifests 
$ oc get packagemanifests | grep InfraWatch
smart-gateway-operator                               InfraWatch Operators       18m
service-telemetry-operator                           InfraWatch Operators       18m

2.5 订阅 AMQ Cert Manager Operator
AMQ Cert Manager 不支持安装在单独 namespace 下，因此 namespace 需选择 openshift-operators

oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq7-cert-manager-operator
  namespace: openshift-operators
spec:
  channel: 1.x
  installPlanApproval: Automatic
  name: amq7-cert-manager-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

检查 amq7-cert-manager csv 
$ oc -n openshift-operators get csv amq7-cert-manager.v1.0.1
NAME                       DISPLAY                                         VERSION   REPLACES   PHASE
amq7-cert-manager.v1.0.1   Red Hat Integration - AMQ Certificate Manager   1.0.1                Succeeded

2.6 订阅 Elastic Cloud on Kubernetes Operator
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: elastic-cloud-eck
  namespace: service-telemetry
spec:
  channel: stable
  installPlanApproval: Automatic
  name: elastic-cloud-eck
  source: operatorhubio-operators
  sourceNamespace: openshift-marketplace
  startingCSV: elastic-cloud-eck.v1.7.1
EOF

如果 installPlanApproval 设置为 Manual，可以人工更改 installplan 批准状态
oc -n service-telemetry get installplan
oc -n service-telemetry patch $(oc -n service-telemetry get installplan -o name) --type json -p='[{"op": "replace", "path": "/spec/approved", "value":true}]'

查看 csv elastic-cloud-eck.v1.7.1
$ oc -n service-telemetry get csv elastic-cloud-eck.v1.7.1 
NAME                       DISPLAY                        VERSION   REPLACES                   PHASE
elastic-cloud-eck.v1.7.1   Elasticsearch (ECK) Operator   1.7.1     elastic-cloud-eck.v1.7.0   Succeeded

2.7 订阅 service telemetry operator
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: service-telemetry-operator
  namespace: service-telemetry
spec:
  channel: stable-1.2
  installPlanApproval: Automatic
  name: service-telemetry-operator
  source: infrawatch-operators
  sourceNamespace: openshift-marketplace
EOF
注意：
1. 在 OCP 4.8 console 界面下可以看到两个 Service Telemetry Operator 
2. 1 个频道为 stable-1.2，另外 1 个频道为 unstable
3. 选择安装 stable-1.2 channel

2.8 安装完后，在 service-telemetry namespace 下以下这些 csv：amq7-cert-manager, elastic-cloud-eck, service-telemetry-operator, amq7-interconnect-operator, prometheusoperator, smart-gateway-operator

$ oc -n service-telemetry get csv 
NAME                                 DISPLAY                                         VERSION    REPLACES                            PHASE
amq7-cert-manager.v1.0.1             Red Hat Integration - AMQ Certificate Manager   1.0.1                                          Succeeded
amq7-interconnect-operator.v1.10.1   Red Hat Integration - AMQ Interconnect          1.10.1     amq7-interconnect-operator.v1.2.4   Succeeded
elastic-cloud-eck.v1.7.1             Elasticsearch (ECK) Operator                    1.7.1      elastic-cloud-eck.v1.7.0            Succeeded
prometheusoperator.0.47.0            Prometheus Operator                             0.47.0     prometheusoperator.0.37.0           Succeeded
service-telemetry-operator.v1.2.0    Service Telemetry Operator                      1.2.0                                          Succeeded
smart-gateway-operator.v2.2.0        Smart Gateway Operator                          2.2.0                                          Succeeded

3.1 创建默认 Service Telemetry 
oc apply -f - <<EOF
apiVersion: infra.watch/v1beta1
kind: ServiceTelemetry
metadata:
  name: default
  namespace: service-telemetry
spec: {}
EOF

查看 pod service-telemetry-operator 的日志
$ oc logs --selector name=service-telemetry-operator -c ansible
PLAY RECAP *********************************************************************
localhost                  : ok=54   changed=0    unreachable=0    failed=0    skipped=20   rescued=0    ignored=0  

看看有哪些 pods 
$ oc get pods 
NAME                                                      READY   STATUS    RESTARTS   AGE
alertmanager-default-0                                    2/2     Running   0          22m
default-cloud1-ceil-meter-smartgateway-5ff6cd4bbb-x62jt   1/1     Running   0          21m
default-cloud1-coll-meter-smartgateway-8446fc88d9-f7kkb   2/2     Running   0          21m
default-interconnect-5657954949-xmxgt                     1/1     Running   0          22m
elastic-operator-79d6d677c5-sdts9                         1/1     Running   0          79m
interconnect-operator-74cc45cdb9-lcwzk                    1/1     Running   0          44m
prometheus-default-0                                      2/2     Running   1          22m
prometheus-operator-7f6948966b-xgvnq                      1/1     Running   0          44m
service-telemetry-operator-bd5584ccb-pd7jh                2/2     Running   0          44m
smart-gateway-operator-7fbffcbd69-xtwvg                   2/2     Running   0          44m

3.2 先尝试集成到 ocp1.rhcnsa.com 环境
生成 templates/stf-connectors.yaml 文件，其中 host 对应以下命令的输出
oc get route default-interconnect-5671 -o jsonpath='{.spec.host}{"\n"}'

cat > templates/stf-connectors.yaml <<EOF
parameter_defaults:
  CeilometerQdrPublishEvents: true
  MetricsQdrConnectors:
  - host: default-interconnect-5671-service-telemetry.apps.ocp1.rhcnsa.com
    port: 443
    role: edge
    sslProfile: sslProfile
    verifyHostname: false

  MetricsQdrSSLProfiles:
  - name: sslProfile
EOF

3.3 生成 templates/enable-stf.yaml 文件
因为是虚拟化环境，调高了 CollectdAmqpInterval，CollectdDefaultPollingInterval 和 ceilometer::agent::polling::polling_interval

根据在以下路径已经存在了 $THT/environments/enable-stf.yaml 文件，考虑这个模版文件是否可以不用生成
cat > ~/templates/enable-stf.yaml <<'EOF'
parameter_defaults:
    # only send to STF, not other publishers
    EventPipelinePublishers: []
    PipelinePublishers: []

    # manage the polling and pipeline configuration files for Ceilometer agents
    ManagePolling: true
    ManagePipeline: true

    # enable Ceilometer metrics and events
    CeilometerQdrPublishMetrics: true
    CeilometerQdrPublishEvents: true

    # enable collection of API status
    CollectdEnableSensubility: true
    CollectdSensubilityTransport: amqp1
    CollectdSensubilityResultsChannel: sensubility/telemetry

    # enable collection of containerized service metrics
    CollectdEnableLibpodstats: true

    # set collectd overrides for higher telemetry resolution and extra plugins
    # to load
    CollectdConnectionType: amqp1
    CollectdAmqpInterval: 60
    CollectdDefaultPollingInterval: 60
    CollectdExtraPlugins:
    - vmem
    - ceph

    # set standard prefixes for where metrics and events are published to QDR
    MetricsQdrAddresses:
    - prefix: 'collectd'
      distribution: multicast
    - prefix: 'anycast/ceilometer'
      distribution: multicast

    ComputeHCIExtraConfig:
        ceilometer::agent::polling::polling_interval: 60
        ceilometer::agent::polling::polling_meters:
        - cpu
        - disk.*
        - ip.*
        - image.*
        - memory
        - memory.*
        - network.*
        - perf.*
        - port
        - port.*
        - switch
        - switch.*
        - storage.*
        - volume.*

        # to avoid filling the memory buffers if disconnected from the message bus
        collectd::plugin::amqp1::send_queue_limit: 50

        # receive extra information about virtual memory
        collectd::plugin::vmem::verbose: true

        # provide name and uuid in addition to hostname for better correlation
        # to ceilometer data
        collectd::plugin::virt::hostname_format: "name uuid hostname"

        # provide the human-friendly name of the virtual instance
        collectd::plugin::virt::plugin_instance_format: metadata

        # set memcached collectd plugin to report its metrics by hostname
        # rather than host IP, ensuring metrics in the dashboard remain uniform
        collectd::plugin::memcached::instances:
          local:
            host: "%{hiera('fqdn_canonical')}"
            port: 11211

        # set ceph daemon plugin
        collectd::plugin::ceph::daemons:
           - ceph-osd.0
           - ceph-osd.1
           - ceph-osd.2
           - ceph-osd.3
           - ceph-osd.4
           - ceph-osd.5
           - ceph-osd.6
           - ceph-osd.7
           - ceph-osd.8           
EOF

# 添加 ceph 部分
根据在以下路径已经存在了 $THT/environments/enable-stf.yaml 文件，考虑这个模版文件是否可以不用生成
cat > ~/templates/enable-stf.yaml <<'EOF'
parameter_defaults:
    # only send to STF, not other publishers
    EventPipelinePublishers: []
    PipelinePublishers: []

    # manage the polling and pipeline configuration files for Ceilometer agents
    ManagePolling: true
    ManagePipeline: true

    # enable Ceilometer metrics and events
    CeilometerQdrPublishMetrics: true
    CeilometerQdrPublishEvents: true

    # enable collection of API status
    CollectdEnableSensubility: true
    CollectdSensubilityTransport: amqp1
    CollectdSensubilityResultsChannel: sensubility/telemetry

    # enable collection of containerized service metrics
    CollectdEnableLibpodstats: true

    # set collectd overrides for higher telemetry resolution and extra plugins
    # to load
    CollectdConnectionType: amqp1
    CollectdAmqpInterval: 60
    CollectdDefaultPollingInterval: 60
    CollectdExtraPlugins:
    - vmem
    - ceph

    # set standard prefixes for where metrics and events are published to QDR
    MetricsQdrAddresses:
    - prefix: 'collectd'
      distribution: multicast
    - prefix: 'anycast/ceilometer'
      distribution: multicast

    ControllerExtraConfig:
        ceilometer::agent::polling::polling_interval: 60
        ceilometer::agent::polling::polling_meters:
        - cpu
        - disk.*
        - ip.*
        - image.*
        - memory
        - memory.*
        - network.*
        - perf.*
        - port
        - port.*
        - switch
        - switch.*
        - storage.*
        - volume.*

        # to avoid filling the memory buffers if disconnected from the message bus
        collectd::plugin::amqp1::send_queue_limit: 50

        # receive extra information about virtual memory
        collectd::plugin::vmem::verbose: true

        # provide name and uuid in addition to hostname for better correlation
        # to ceilometer data
        collectd::plugin::virt::hostname_format: "name uuid hostname"

        # provide the human-friendly name of the virtual instance
        collectd::plugin::virt::plugin_instance_format: metadata

        # set memcached collectd plugin to report its metrics by hostname
        # rather than host IP, ensuring metrics in the dashboard remain uniform
        collectd::plugin::memcached::instances:
          local:
            host: "%{hiera('fqdn_canonical')}"
            port: 11211

        # set ceph daemon plugin on controller
        collectd::plugin::ceph::daemons:
           - mon.overcloud-controller-0
           - mon.overcloud-controller-1
           - mon.overcloud-controller-2

    ComputeHCIExtraConfig:
        ceilometer::agent::polling::polling_interval: 60
        ceilometer::agent::polling::polling_meters:
        - cpu
        - disk.*
        - ip.*
        - image.*
        - memory
        - memory.*
        - network.*
        - perf.*
        - port
        - port.*
        - switch
        - switch.*
        - storage.*
        - volume.*

        # to avoid filling the memory buffers if disconnected from the message bus
        collectd::plugin::amqp1::send_queue_limit: 50

        # receive extra information about virtual memory
        collectd::plugin::vmem::verbose: true

        # provide name and uuid in addition to hostname for better correlation
        # to ceilometer data
        collectd::plugin::virt::hostname_format: "name uuid hostname"

        # provide the human-friendly name of the virtual instance
        collectd::plugin::virt::plugin_instance_format: metadata

        # set memcached collectd plugin to report its metrics by hostname
        # rather than host IP, ensuring metrics in the dashboard remain uniform
        collectd::plugin::memcached::instances:
          local:
            host: "%{hiera('fqdn_canonical')}"
            port: 11211

        # set ceph daemon plugin on storage node
        collectd::plugin::ceph::daemons:
           - ceph-osd.0
           - ceph-osd.1
           - ceph-osd.2
           - ceph-osd.3
           - ceph-osd.4
           - ceph-osd.5
           - ceph-osd.6
           - ceph-osd.7
           - ceph-osd.8           
EOF


3.4 生成部署脚本
cat > deploy-ironic-overcloud-stf.sh <<'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e $THT/environments/services/ironic-overcloud.yaml \
-e $THT/environments/services/ironic-inspector.yaml \
-e $THT/environments/metrics/ceilometer-write-qdr.yaml \
-e $THT/environments/metrics/collectd-write-qdr.yaml \
-e $THT/environments/metrics/qdr-edge-only.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/node-info.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
-e $CNF/ironic.yaml \
-e $CNF/enable-stf.yaml \
-e $CNF/stf-connectors.yaml \
--ntp-server 192.0.2.1
EOF

3.5 执行部署 
$ /usr/bin/nohup /bin/bash -x deploy-ironic-overcloud-stf.sh &

4.1 安装后检查
检查 overcloud 节点 metric_qdr 的状态
$ sudo podman container inspect --format '{{.State.Status}}' metrics_qdr
running

检查 qdr 本地地址和端口
$ sudo podman exec -it metrics_qdr cat /etc/qpid-dispatch/qdrouterd.conf | grep listener -A6
listener {
    host: 172.16.2.35
    port: 5666
    authenticatePeer: no
    saslMechanisms: ANONYMOUS
}

返回本地 Apache Qpid Dispatch Router 的连接
$ sudo podman exec -it metrics_qdr qdstat --bus=172.16.2.35:5666 --connections
Connections
  id  host                                                                  container                                                                                                            role    dir  security                            authentication  tenant
  ========================================================================================================================================================================================================================================================================
  1   default-interconnect-5671-service-telemetry.apps.ocp1.rhcnsa.com:443  default-interconnect-5657954949-xmxgt                                                                                edge    out  TLSv1.2(DHE-RSA-AES256-GCM-SHA384)  anonymous-user  
  13  172.16.2.35:43916                                                     openstack.org/om/container/overcloud-controller-0/ceilometer-agent-notification/26/a52c76ab9d7f4e2f90679e4de0d66f2c  normal  in   no-security                         no-auth         
  17  172.16.2.35:48078                                                     metrics                                                                                                              normal  in   no-security                         anonymous-user  
  19  172.16.2.35:48110                                                     overcloud-controller-0.internalapi.localdomain-infrawatch-out-1631952331                                             normal  in   no-security                         no-auth         
  18  172.16.2.35:48108                                                     overcloud-controller-0.internalapi.localdomain-infrawatch-in-1631952331                                              normal  in   no-security                         anonymous-user  
  32  172.16.2.35:43056                                                     4de2bdca-8393-41b6-9b38-cb533846db59                                                                                 normal  in   no-security                         no-auth   

上面例子的输出里共有 6 个连接
1. 对外连接连接到 STF
2. 来自 ceilometer 的对内连接
3. 来自 collectd 的对内连接
4. 来自 infrawatch-out 的对内连接
5. 来自 infrawatch-in 的对内连接
6. 查询命令产生的对内连接

查看 Apache Qpid Dispatch Router 的连接详情，查看 _edge 行 deliv 列向外传递的消息
sudo podman exec -it metrics_qdr qdstat --bus=172.16.2.35:5666 --links
Router Links
  type      dir  conn id  id  peer  class   addr                                phs  cap  pri  undel  unsett  deliv  presett  psdrop  acc   rej  rel  mod  delay  rate
  ======================================================================================================================================================================
  endpoint  out  1        6         local   _edge                                    250  0    0      0       9093   0        0       9093  0    0    0    6996   0

4.2 在 OpenShift 侧查看 Apache Qpid Dispatch Router 容器
$ oc get pods -l application=default-interconnect
NAME                                    READY   STATUS    RESTARTS   AGE
default-interconnect-5657954949-xmxgt   1/1     Running   0          5h58m

在 OpenShift 侧查看 Apache Qpid Dispatch Router 容器内的连接
$ oc exec -it $(oc get pods -l application=default-interconnect -o name) -- qdstat --connections
default-interconnect-5657954949-xmxgt

Connections
  id  host                container                                                     role    dir  security                                authentication  tenant  last dlv      uptime
  ===============================================================================================================================================================================================
  1   10.128.6.138:52182  bridge-95                                                     edge    in   no-security                             anonymous-user          000:00:00:42  000:05:58:30
  8   10.130.2.20:55732   Router.overcloud-controller-0.localdomain                     edge    in   TLSv1/SSLv3(DHE-RSA-AES256-GCM-SHA384)  anonymous-user          000:00:00:02  000:01:01:21
  9   10.130.4.53:60872   rcv[default-cloud1-ceil-meter-smartgateway-5ff6cd4bbb-x62jt]  edge    in   no-security                             anonymous-user          000:00:00:02  000:00:42:07
  10  127.0.0.1:45534     3bf01cf4-caed-4464-8f75-e3e9a2f59496                          normal  in   no-security                             no-auth                 000:00:00:00  000:00:00:00

其中 Router.overcloud-controller-0.localdomain 是来自 OpenStack 节点的连接

在 OpenShift 侧查看 Apache Qpid Dispatch Router 容器内连接的消息发送接受情况
$ oc exec -it $(oc get pods -l application=default-interconnect -o name) -- qdstat --address
default-interconnect-5657954949-xmxgt

Router Addresses
  class   addr                                       phs  distrib    pri  local  remote  in      out     thru  fallback
  =======================================================================================================================
  local   $_management_internal                           closest    -    0      0       0       0       0     0
  mobile  $management                                0    closest    -    0      0       8       0       0     0
  local   $management                                     closest    -    0      0       0       0       0     0
  edge    Router.overcloud-controller-0.localdomain       balanced   -    1      0       0       0       0     0
  mobile  _$qd.addr_lookup                           0    balanced   -    0      0       0       0       0     0
  mobile  _$qd.edge_addr_tracking                    0    balanced   -    0      0       0       0       0     0
  mobile  anycast/ceilometer/metering.sample         0    balanced   -    1      0       51      51      0     0
  mobile  collectd/telemetry                         0    multicast  -    1      0       12,034  12,034  0     0
  local   qdhello                                         flood      -    0      0       0       0       0     0
  local   qdrouter                                        flood      -    0      0       0       0       0     0
  topo    qdrouter                                        flood      -    0      0       0       0       0     0
  local   qdrouter.ma                                     multicast  -    0      0       0       0       0     0
  topo    qdrouter.ma                                     multicast  -    0      0       0       0       0     0
  mobile  sensubility/telemetry                      0    balanced   -    0      0       0       0       0     0
  local   temp.68EMpW72xeFehjf                            balanced   -    1      0       0       1       0     0
  local   temp.8qUymdqdQa3B68j                            balanced   -    1      0       0       49      0     0
  local   temp.UXhkRDXXqomk_in                            balanced   -    1      0       0       0       0     0

5.1 定义一条 Prometheus 告警规则
告警对象名: name: prometheus-alarm-rules
告警规则组名: name: ./openstack.rules
告警1名称: alert: Metric Listener down
告警1条件: expr: collectd_qpid_router_status < 1
告警2名称: alert: Collectd Instance down
告警2条件: expr: absent(collectd_cpu_percent{plugin_instance="0",type_instance="idle"}) == 1
$ oc apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  creationTimestamp: null
  labels:
    prometheus: default
    role: alert-rules
  name: prometheus-alarm-rules
  namespace: service-telemetry
spec:
  groups:
    - name: ./openstack.rules
      rules:
        - alert: Metric Listener down
          expr: collectd_qpid_router_status < 1 
        - alert: Collectd Instance on host overcloud-controller-0.localdomain down
          expr: absent(collectd_cpu_percent{host="overcloud-controller-0.localdomain",plugin_instance="0",type_instance="idle"}) == 1
        - alert: Collectd Instance on host overcloud-novacompute-0.localdomain down
          expr: absent(collectd_cpu_percent{host="overcloud-novacompute-0.localdomain",plugin_instance="0",type_instance="idle"}) == 1        
EOF

有了这 2 条规则后，考虑用停止 collectd qpid 容器模拟触发 Collectd Instance down 告警 

5.2 验证规则已加载，从以下输出可以了解规则已加载
$ oc run curl --generator=run-pod/v1 --image=radial/busyboxplus:curl -i --tty
If you don't see a command prompt, try pressing enter.
[ root@curl:/ ]$ curl prometheus-operated:9090/api/v1/rules
{"status":"success","data":{"groups":[{"name":"./openstack.rules","file":"/etc/prometheus/rules/prometheus-default-rulefiles-0/service-telemetry-prometheus-alarm-rules.yaml","rules":[{"state":"inactive","name":"Metric Listener down","query":"collectd_qpid_router_status \u003c 1","duration":0,"labels":{},"annotations":{},"alerts":[],"health":"ok","evaluationTime":0.000235127,"lastEvaluation":"2021-09-22T04:49:22.160875378Z","type":"alerting"},{"state":"firing","name":"Collectd Instance down","query":"absent(collectd_cpu_percent{plugin_instance=\"0\",type_instance=\"idle\"}) == 1","duration":0,"labels":{},"annotations":{},"alerts":[{"labels":{"alertname":"Collectd Instance down","plugin_instance":"0","type_instance":"idle"},"annotations":{},"state":"firing","activeAt":"2021-09-22T04:35:22.159707604Z","value":"1e+00"}],"health":"ok","evaluationTime":0.000171787,"lastEvaluation":"2021-09-22T04:49:22.16111235Z","type":"alerting"}],"interval":30,"evaluationTime":0.00041704,"lastEvaluation":"2021-09-22T04:49:22.160870003Z"}]}}
[ root@curl:/ ]$ exit
$ oc delete pod curl

5.3 在控制节点上，执行以下命令停止 metrics_qdr 服务，这样 prometheus 就无法收集到 collectd_cpu_percent 指标了
满足了告警 ‘Collectd Instance down’ 触发的条件 
[heat-admin@overcloud-controller-0 ~]$ sudo systemctl stop tripleo_metrics_qdr.service  

5.4 编辑 ServiceTelemetry default 对象，添加 alertmanagerConfigManifest
oc edit ServiceTelemetry default

设置告警发送到邮箱 wjqhd@hotmail.com
MAIL_ACCOUNT=wjqhd@hotmail.com
HOTMAIL_AUTH_TOKEN=xxxxxx
在 spec 里添加 alertmanagerConfigManifest
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
            auth_password: "$HOTMAIL_AUTH_TOKEN"        


5.5 检查配置
$ oc get secret alertmanager-default -o jsonpath='{.data.alertmanager\.yaml}' | base64 --decode
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
    auth_password: "$GMAIL_AUTH_TOKEN"

5.6 查看告警服务状态
oc exec -it curl /bin/sh
[ root@curl:/ ]$ curl alertmanager-operated:9093/api/v1/status
{"status":"success","data":{"configYAML":"global:\n  resolve_timeout: 10m\n  http_config: {}\n  smtp_hello: localhost\n  smtp_require_tls: true\n  pagerduty_url: https://events.pagerduty.com/v2/enqueue\n  opsgenie_api_url: https://api.opsgenie.com/\n  wechat_api_url: https://qyapi.weixin.qq.com/cgi-bin/\n  victorops_api_url: https://alert.victorops.com/integrations/generic/20131114/alert/\nroute:\n  receiver: email-me\n  group_by:\n  - job\n  group_wait: 30s\n  group_interval: 5m\n  repeat_interval: 12h\nreceivers:\n- name: email-me\n  email_configs:\n  - send_resolved: false\n    to: wjqhd@hotmail.com\n    from: wjqhd@hotmail.com\n    hello: localhost\n    smarthost: smtp-mail.outlook.com:587\n    auth_username: wjqhd@hotmail.com\n    auth_password: \u003csecret\u003e\n    auth_identity: wjqhd@hotmail.com\n    headers:\n      From: wjqhd@hotmail.com\n      Subject: '{{ template \"email.default.subject\" . }}'\n      To: wjqhd@hotmail.com\n    html: '{{ template \"email.default.html\" . }}'\n    require_tls: true\ntemplates: []\n","configJSON":{"global":{"resolve_timeout":600000000000,"http_config":{"BasicAuth":null,"BearerToken":"","BearerTokenFile":"","ProxyURL":{},"TLSConfig":{"CAFile":"","CertFile":"","KeyFile":"","ServerName":"","InsecureSkipVerify":false}},"smtp_hello":"localhost","smtp_smarthost":"","smtp_require_tls":true,"pagerduty_url":"https://events.pagerduty.com/v2/enqueue","opsgenie_api_url":"https://api.opsgenie.com/","wechat_api_url":"https://qyapi.weixin.qq.com/cgi-bin/","victorops_api_url":"https://alert.victorops.com/integrations/generic/20131114/alert/"},"route":{"receiver":"email-me","group_by":["job"],"group_wait":30000000000,"group_interval":300000000000,"repeat_interval":43200000000000},"receivers":[{"name":"email-me","email_configs":[{"send_resolved":false,"to":"wjqhd@hotmail.com","from":"wjqhd@hotmail.com","hello":"localhost","smarthost":"smtp-mail.outlook.com:587","auth_username":"wjqhd@hotmail.com","auth_password":"\u003csecret\u003e","auth_identity":"wjqhd@hotmail.com","headers":{"From":"wjqhd@hotmail.com","Subject":"{{ template \"email.default.subject\" . }}","To":"wjqhd@hotmail.com"},"html":"{{ template \"email.default.html\" . }}","require_tls":true,"tls_config":{"CAFile":"","CertFile":"","KeyFile":"","ServerName":"","InsecureSkipVerify":false}}]}],"templates":null},"versionInfo":{"branch":"HEAD","buildDate":"20200617-08:54:02","buildUser":"root@dee35927357f","goVersion":"go1.14.4","revision":"4c6c03ebfe21009c546e4d1e9b92c371d67c021d","version":"0.21.0"},"uptime":"2021-09-18T23:19:40.606887467Z","clusterStatus":null}}

5.7 检查邮箱，应该收到了告警邮件

6.1 接下来设置在 ServiceTelemetry 对象里启用 Grafana
首先创建 Graphana Subscription
$ oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: grafana-operator
  namespace: service-telemetry
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: grafana-operator
  source: operatorhubio-operators
  sourceNamespace: openshift-marketplace
  startingCSV: grafana-operator.v3.10.3
EOF

6.2 编辑 ServiceTelemetry 对象 default
oc edit ServiceTelemetry default
...
spec
...
  graphing:
    enabled: true
    grafana:
      ingressEnabled: true

6.3 检查 Grafana 已部署
$ oc get pod -l app=grafana
grafana-deployment-6c4797d494-l9nr8   1/1     Running   0          17m

检查 Grafana 的 datasources
$ oc get grafanadatasources
NAME                    AGE
default-ds-prometheus   19m

获取 Grafana Route
oc get route grafana-route -o jsonpath='{"https://"}{.spec.host}{"\n"}'

检查镜像版本，要求镜像版本大于 8.1.0
$ oc get pod -l "app=grafana" -ojsonpath='{.items[0].spec.containers[0].image}'
如果版本低于 8.1.0 则更新镜像版本
$ oc patch grafana/default --type merge -p '{"spec":{"baseImage":"docker.io/grafana/grafana:8.1.0"}}'
再次检查检查镜像版本
$ oc get pod -l "app=grafana" -ojsonpath='{.items[0].spec.containers[0].image}'
docker.io/grafana/grafana:8.1.0

6.4 导入 STF Dashboard
$ oc apply -f https://raw.githubusercontent.com/infrawatch/dashboards/master/deploy/stf-1.3/rhos-dashboard.yaml
$ oc apply -f https://raw.githubusercontent.com/infrawatch/dashboards/master/deploy/stf-1.3/rhos-cloud-dashboard.yaml
$ oc apply -f https://raw.githubusercontent.com/infrawatch/dashboards/master/deploy/stf-1.3/rhos-cloudevents-dashboard.yaml


在执行完这一步之后，可以看到 STF Grafana 的 Dashboard 了
```

### setup ceilometer notification driver in tripleo for STF
https://github.com/openstack/tripleo-heat-templates/blob/stable/train/environments/metrics/ceilometer-write-qdr.yaml#L15

### smartgateway tracker dashboard
https://github.com/infrawatch/dashboards/blob/master/deploy/stf-1.3/sg-tracker-dashboard.yaml

### Service Telemetry Framework Performance and Scaling
https://access.redhat.com/articles/4907241

WIP: 
1. 根据 GChat 里的信息，STF 的 ceilometer notification agent 会监听其他组件发送的 metrics 和 events，然后发送给 ceilometer central，ceilometer central 再把信息通过 QDR 发送给 Smart Gateway

2. ceilometer notification agent 还会从 rabbitmq/oslo-message 上拉取数据 (polling agent: polls data)

3. 因此 ceilometer 采集数据的时间间隔不要设置得太小，避免给 rabbitmq/oslo-message 带来过高的压力

### 备注
1. osp 16.1 下默认计算节点的 collectd virt plugin 造成 collectd pod 启动失败的问题
```
$ cat /var/lib/config-data/puppet-generated/collectd/etc/collectd.d/10-virt.conf
# Generated by Puppet
<LoadPlugin virt>
  Globals false
</LoadPlugin>

<Plugin virt>
  Connection "qemu:///system"
  HostnameFormat "name metadata hostname"
  ExtraStats "pcpu cpu_util vcpupin vcpu memory disk disk_err disk_allocation disk_capacity disk_physical domain_state job_stats_background perf"
</Plugin>

其中 HostnameFormat "name metadata hostname" 将造成 collectd 启动失败
临时的解决方案是注释掉这行
```

2. 部署失败，在 /var/lib/mistral/overcloud/ansible.log 里有如下报错
```
# 报错信息
        "Error running ['podman', 'create', '--name', 'metrics_qdr', '--label', 'config_id=tripleo_step1', '--label', 'container_name=metrics_qdr'
, '--label', 'managed_by=tripleo-Controller', '--label', 'config_data={\"environment\": {\"KOLLA_CONFIG_STRATEGY\": \"COPY_ALWAYS\", \"TRIPLEO_CON
FIG_HASH\": \"f039f36b2ab1566505448ba88433a14d\"}, \"healthcheck\": {\"test\": \"/openstack/healthcheck\"}, \"image\": \"undercloud.ctlplane.examp
le.com:8787/rhosp-rhel8/openstack-qdrouterd:16.1\", \"net\": \"host\", \"privileged\": false, \"restart\": \"always\", \"start_order\": 1, \"user\
": \"qdrouterd\", \"volumes\": [\"/etc/hosts:/etc/hosts:ro\", \"/etc/localtime:/etc/localtime:ro\", \"/etc/pki/ca-trust/extracted:/etc/pki/ca-trus
t/extracted:ro\", \"/etc/pki/ca-trust/source/anchors:/etc/pki/ca-trust/source/anchors:ro\", \"/etc/pki/tls/certs/ca-bundle.crt:/etc/pki/tls/certs/
ca-bundle.crt:ro\", \"/etc/pki/tls/certs/ca-bundle.trust.crt:/etc/pki/tls/certs/ca-bundle.trust.crt:ro\", \"/etc/pki/tls/cert.pem:/etc/pki/tls/cer
t.pem:ro\", \"/dev/log:/dev/log\", \"/etc/ipa/ca.crt:/etc/ipa/ca.crt:ro\", \"/etc/puppet:/etc/puppet:ro\", \"/var/lib/kolla/config_files/metrics_q
dr.json:/var/lib/kolla/config_files/config.json:ro\", \"/var/lib/config-data/puppet-generated/metrics_qdr:/var/lib/kolla/config_files/src:ro\", \"
/var/lib/metrics_qdr:/var/lib/qdrouterd:z\", \"/var/log/containers/metrics_qdr:/var/log/qdrouterd:z\", \"/etc/pki/tls/certs/metrics_qdr.crt:/var/l
ib/kolla/config_files/src-tls/etc/pki/tls/certs/metrics_qdr.crt:ro\", \"/etc/pki/tls/private/metrics_qdr.key:/var/lib/kolla/config_files/src-tls/e
tc/pki/tls/private/metrics_qdr.key:ro\", \"/etc/ipa/ca.crt:/etc/ipa/ca.crt:ro\"]}', '--conmon-pidfile=/var/run/metrics_qdr.pid', '--detach=true', 
'--log-driver', 'k8s-file', '--log-opt', 'path=/var/log/containers/stdouts/metrics_qdr.log', '--env=KOLLA_CONFIG_STRATEGY=COPY_ALWAYS', '--env=TRI
PLEO_CONFIG_HASH=f039f36b2ab1566505448ba88433a14d', '--net=host', '--privileged=false', '--user=qdrouterd', '--volume=/etc/hosts:/etc/hosts:ro', '
--volume=/etc/localtime:/etc/localtime:ro', '--volume=/etc/pki/ca-trust/extracted:/etc/pki/ca-trust/extracted:ro', '--volume=/etc/pki/ca-trust/sou
rce/anchors:/etc/pki/ca-trust/source/anchors:ro', '--volume=/etc/pki/tls/certs/ca-bundle.crt:/etc/pki/tls/certs/ca-bundle.crt:ro', '--volume=/etc/
pki/tls/certs/ca-bundle.trust.crt:/etc/pki/tls/certs/ca-bundle.trust.crt:ro', '--volume=/etc/pki/tls/cert.pem:/etc/pki/tls/cert.pem:ro', '--volume
=/dev/log:/dev/log', '--volume=/etc/ipa/ca.crt:/etc/ipa/ca.crt:ro', '--volume=/etc/puppet:/etc/puppet:ro', '--volume=/var/lib/kolla/config_files/m
etrics_qdr.json:/var/lib/kolla/config_files/config.json:ro', '--volume=/var/lib/config-data/puppet-generated/metrics_qdr:/var/lib/kolla/config_fil
es/src:ro', '--volume=/var/lib/metrics_qdr:/var/lib/qdrouterd:z', '--volume=/var/log/containers/metrics_qdr:/var/log/qdrouterd:z', '--volume=/etc/
pki/tls/certs/metrics_qdr.crt:/var/lib/kolla/config_files/src-tls/etc/pki/tls/certs/metrics_qdr.crt:ro', '--volume=/etc/pki/tls/private/metrics_qd
r.key:/var/lib/kolla/config_files/src-tls/etc/pki/tls/private/metrics_qdr.key:ro', '--volume=/etc/ipa/ca.crt:/etc/ipa/ca.crt:ro', 'undercloud.ctlp
lane.example.com:8787/rhosp-rhel8/openstack-qdrouterd:16.1']. [125]",
        "stderr: Error: /etc/ipa/ca.crt: duplicate mount destination",

# 文件 /etc/ipa/ca.crt 在多处定义
 [root@undercloud openstack-tripleo-heat-templates]# grep -r ca.crt deployment/ 
deployment/apache/apache-baremetal-puppet.j2.yaml:    default: '/etc/ipa/ca.crt'
deployment/containers-common.yaml:    default: '/etc/ipa/ca.crt'
deployment/database/mysql-client.yaml:    default: '/etc/ipa/ca.crt'
deployment/database/mysql-container-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/database/mysql-pacemaker-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/etcd/etcd-container-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/haproxy/haproxy-container-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/haproxy/haproxy-pacemaker-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/horizon/horizon-container-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/metrics/qdr-container-puppet.yaml.orig:    default: '/etc/ipa/ca.crt'
deployment/metrics/qdr-container-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/neutron/neutron-api-container-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/neutron/neutron-dhcp-container-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/neutron/neutron-plugin-ml2-ovn.yaml:    default: '/etc/ipa/ca.crt'
deployment/nova/nova-libvirt-container-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/octavia/providers/ovn-provider-config.yaml:    default: '/etc/ipa/ca.crt'
deployment/ovn/ovn-controller-container-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/ovn/ovn-dbs-pacemaker-puppet.yaml:    default: '/etc/ipa/ca.crt'
deployment/ovn/ovn-metadata-container-puppet.yaml:    default: '/etc/ipa/ca.crt'

# 其中 deployment/containers-common.yaml 已经定义了，因此 deployment/metrics/qdr-container-puppet.yaml 再定义就重复了

# 修改 undercloud 的 /usr/share/openstack-tripleo-heat-templates/deployment/metrics/qdr-container-puppet.yaml
 [root@undercloud openstack-tripleo-heat-templates]# diff -urN deployment/metrics/qdr-container-puppet.yaml.orig deployment/metrics/qdr-container-puppet.yaml
--- deployment/metrics/qdr-container-puppet.yaml.orig   2021-11-04 08:53:21.671394766 +0800
+++ deployment/metrics/qdr-container-puppet.yaml  2021-11-04 08:53:57.402394766 +0800
@@ -332,11 +332,6 @@
                   - internal_tls_enabled
                   - - /etc/pki/tls/certs/metrics_qdr.crt:/var/lib/kolla/config_files/src-tls/etc/pki/tls/certs/metrics_qdr.crt:ro
                     - /etc/pki/tls/private/metrics_qdr.key:/var/lib/kolla/config_files/src-tls/etc/pki/tls/private/metrics_qdr.key:ro
-                    - list_join:
-                      - ':'
-                      - - {get_param: InternalTLSCAFile}
-                        - {get_param: InternalTLSCAFile}
-                        - 'ro'
                   - null
             environment:
               KOLLA_CONFIG_STRATEGY: COPY_ALWAYS

# 在 undercloud 上更新 openstack-collectd 镜像
# 参考链接: https://bugzilla.redhat.com/show_bug.cgi?id=1804045
# 下载镜像
podman login registry.redhat.io 
podman pull registry.redhat.io/rhosp-rhel8/openstack-collectd:16.1.6-6

# 为镜像打标签
podman tag registry.redhat.io/rhosp-rhel8/openstack-collectd:16.1.6-6 helper.example.com:5000/rhosp-rhel8/openstack-collectd:16.1.6-6
podman tag helper.example.com:5000/rhosp-rhel8/openstack-collectd:16.1.6-6 helper.example.com:5000/rhosp-rhel8/openstack-collectd:16.1

# 上传更新的 openstack-collectd 镜像 
podman push helper.example.com:5000/rhosp-rhel8/openstack-collectd:16.1.6-6
podman push helper.example.com:5000/rhosp-rhel8/openstack-collectd:16.1

# 在 undercloud 上更新 openstack-collectd 镜像
sudo openstack --debug tripleo container image push --local helper.example.com:5000/rhosp-rhel8/openstack-collectd:16.1

# 在 overcloud 计算节点上更新 openstack-collectd 镜像
[heat-admin@overcloud-computehci-0 ~]$ sudo podman pull undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-collectd:16.1 
```

```
sum(collectd_cpu_percent{type_instance!="idle", host="overcloud-computehci-2.example.com", service=~".+-cloud1-.+"}) / count(sum by (type_instance) (collectd_cpu_percent{type_instance!="idle",host="overcloud-computehci-2.example.com", service=~".+-cloud1-.+"}))
```

```
# collectd ceph plugins
https://collectd.org/wiki/index.php/Plugin:Ceph
https://github.com/rochaporto/collectd-ceph

# Bug 1984193 - Provide configuration to collect ceph mon metrics via collectd
https://bugzilla.redhat.com/show_bug.cgi?id=1984193

# 重启 undercloud 后 rabbitmq 出现问题的处理
https://github.com/wangjun1974/tips/blob/master/os/miscs.md#osp-161-undercloud-rabbitmq-%E6%9C%8D%E5%8A%A1%E6%97%A0%E6%B3%95%E5%90%AF%E5%8A%A8%E9%97%AE%E9%A2%98%E7%9A%84%E5%88%86%E6%9E%90

(undercloud) [stack@undercloud ~]$ cat /etc/hosts | grep undercloud
192.0.2.1 undercloud.ctlplane.example.com undercloud.ctlplane undercloud

```