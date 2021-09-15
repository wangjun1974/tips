### 集成 Service Telemetry Framework 
```
1.1 切换到普通用户
su - jwang

1.2 下载 Code Ready Container 1.9.0
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
oc get catalogsource -n openshift-marketplace

2.4 创建 OperatorSource 可提供 Service Telemetry Operator 和 Smart Gateway Operator
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  labels:
    opsrc-provider: redhat-operators-stf
  name: redhat-operators-stf
  namespace: openshift-marketplace
spec:
  authorizationToken: {}
  displayName: Red Hat STF Operators
  endpoint: https://quay.io/cnr
  publisher: Red Hat
  registryNamespace: redhat-operators-stf
  type: appregistry
EOF
oc get operatorsource -n openshift-marketplace

2.5 检查 
oc get packagemanifests | grep "Red Hat STF"

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
oc get --namespace openshift-operators csv
$ oc -n openshift-operators get csv 
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
EOF
oc -n service-telemetry get installplan
oc -n service-telemetry patch installplan/install-bb8kn --type json -p='[{"op": "replace", "path": "/spec/approved", "value":true}]'



目前 ElasticSearch Cloud 的 CSV 安装遇到了障碍

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