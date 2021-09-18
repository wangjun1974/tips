### 集成 Service Telemetry Framework 
https://infrawatch.github.io/documentation/#assembly-introduction-to-stf_assembly
```
1.1 切换到普通用户
su - jwang

1.2 下载 Code Ready Container 1.9.0
curl -O -L https://mirror.openshift.com/pub/openshift-v4/clients/crc/1.9.0/crc-linux-amd64.tar.xz
curl -O -L https://mirror.openshift.com/pub/openshift-v4/clients/crc/1.32.1/crc-linux-amd64.tar.xz

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

2.6 订阅 AMQ Cert Manager Operator
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

检查 csv 
$ oc -n openshift-operators get csv amq7-cert-manager.v1.0.1
NAME                       DISPLAY                                         VERSION   REPLACES   PHASE
amq7-cert-manager.v1.0.1   Red Hat Integration - AMQ Certificate Manager   1.0.1                Succeeded

2.7 订阅 Elastic Cloud on Kubernetes Operator
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: elastic-cloud-eck
  namespace: service-telemetry
spec:
  channel: stable
  installPlanApproval: Manual
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

订阅 service telemetry operator
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
1. 在界面下可以看到两个 Service Telemetry Operator 
2. 1 个频道为 stable-1.2，另外 1 个频道为 unstable
3. 选择安装 stable-1.2 channel

安装完后，在 service-telemetry namespace 下以下这些 csv：amq7-cert-manager, elastic-cloud-eck, service-telemetry-operator, amq7-interconnect-operator, prometheusoperator, smart-gateway-operator

$ oc -n service-telemetry get csv 
NAME                                 DISPLAY                                         VERSION    REPLACES                            PHASE
amq7-cert-manager.v1.0.1             Red Hat Integration - AMQ Certificate Manager   1.0.1                                          Succeeded
amq7-interconnect-operator.v1.10.1   Red Hat Integration - AMQ Interconnect          1.10.1     amq7-interconnect-operator.v1.2.4   Succeeded
elastic-cloud-eck.v1.7.1             Elasticsearch (ECK) Operator                    1.7.1      elastic-cloud-eck.v1.7.0            Succeeded
prometheusoperator.0.47.0            Prometheus Operator                             0.47.0     prometheusoperator.0.37.0           Succeeded
service-telemetry-operator.v1.2.0    Service Telemetry Operator                      1.2.0                                          Succeeded
smart-gateway-operator.v2.2.0        Smart Gateway Operator                          2.2.0                                          Succeeded

创建默认 Service Telemetry 
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

配置 

先尝试集成到 rhpds 环境
生成 templates/stf-connectors.yaml 文件
cat > templates/stf-connectors.yaml <<EOF
parameter_defaults:
  CeilometerQdrPublishEvents: true
  MetricsQdrConnectors:
  - host: default-interconnect-5671-service-telemetry.apps.cluster-3e07.3e07.sandbox1882.opentlc.com
    port: 443
    role: edge
    sslProfile: sslProfile
    verifyHostname: false
EOF

cat > deploy-enable-tls-octavia-stf-noceph.sh <<'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/ssl/enable-internal-tls.yaml \
-e $THT/environments/ssl/tls-everywhere-endpoints-dns.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/fixed-ips.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e $THT/environments/services/octavia.yaml \
-e $THT/environments/metrics/ceilometer-write-qdr.yaml \
-e $THT/environments/enable-stf.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/custom-domain.yaml \
-e $CNF/node-info.yaml \
-e $CNF/enable-tls.yaml \
-e $CNF/inject-trust-anchor.yaml \
-e $CNF/keystone_domain_specific_ldap_backend.yaml \
-e $CNF/stf-connectors.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF
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