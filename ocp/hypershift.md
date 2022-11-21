### 启用 Hosted control planes 这个 Technical Preview 的功能
https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/multicluster_engine/index#hosted-control-planes-intro<br>
```
# 首先获取 mce 实例
$ oc get mce 
NAME                 STATUS      AGE
multiclusterengine   Available   27d

# 在这个实例上启用 Hosted control planes
$ oc patch mce multiclusterengine --type=merge -p '{"spec":{"overrides":{"components":[{"name":"hypershift-preview","enabled": true}]}}}'

# 在 multicluster-engine namespace 下会有 'hypershift-deployment-controller' 和 'hypershift-addon-manager'  pod 被创建
$ oc get pods -n multicluster-engine | grep hypershift
hypershift-addon-manager-7c6b79bb77-sd9dr              1/1     Running   0             86s
hypershift-deployment-controller-dcd744745-s79fm       1/1     Running   0             86s


```

### 如何检查 hypershift 相关的日志
```
# 查看 hypershift-addon-manager 的日志
$ oc -n multicluster-engine logs $( oc -n multicluster-engine get pods -l app=hypershift-addon-manager -o name )

# 查看 hypershift-addon-manager 的日志
```

### HyperShift with Agent CAPI
https://hypershift-docs.netlify.app/how-to/agent/create-agent-cluster/ 
```
# 测试一下 HyperShift with Agent CAPI

# 获取 HyperShift Client

# 1. 启用 Agent Installer (Assisted Service)
# 创建 Provisioning 对象
$ cat <<EOF | oc apply -f -
apiVersion: metal3.io/v1alpha1
kind: Provisioning
metadata:
  name: provisioning-configuration
spec:
  provisioningNetwork: Disabled
  watchAllNamespaces: true
EOF

# 生成 mirror-registry-config-map
$ cat <<EOF | tee /tmp/registry.conf
unqualified-search-registries = ["registry.access.redhat.com", "docker.io"]
short-name-mode = ""

[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-release"
  mirror-by-digest-only = true

  [[registry.mirror]]
    location = "registry.example.com:5000/openshift/release-images"

[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  mirror-by-digest-only = true

  [[registry.mirror]]
    location = "registry.example.com:5000/openshift/release"

[[registry]]
  prefix = ""
  location = "registry.access.redhat.com"
  mirror-by-digest-only = true

  [[registry.mirror]]
    location = "registry.example.com:5000"

[[registry]]
  prefix = ""
  location = "registry.redhat.io"
  mirror-by-digest-only = true

  [[registry.mirror]]
    location = "registry.example.com:5000"
EOF

# 生成 configmap mirror-registry-config-map
# ACM 2.6 需要把 namespace 指定为 multicluster-engine
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: mirror-registry-config-map
  namespace: "multicluster-engine"
  labels:
    app: assisted-service
data:
  ca-bundle.crt: |
$( cat /etc/pki/ca-trust/source/anchors/registry.crt | sed -e 's|^|    |g' )

  registries.conf: |
$( cat /tmp/registry.conf | sed -e 's|^|    |g' )
EOF

# 创建 configmap 指定 ISO_IMAGE_TYPE 为 full-iso
# ACM 2.6.1 需要把 namespace 改为 multicluster-engine
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: assisted-service-config
  namespace: multicluster-engine
  labels:
    app: assisted-service
data:
  HW_VALIDATOR_REQUIREMENTS: >-
    [{"version":"default","master":{"cpu_cores":4,"ram_mib":16384,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":100,"packet_loss_percentage":0},"worker":{"cpu_cores":2,"ram_mib":8192,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":1000,"packet_loss_percentage":10},"sno":{"cpu_cores":8,"ram_mib":4096,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10}}]
  ISO_IMAGE_TYPE: "full-iso"
  LOG_LEVEL: "debug"
EOF

# 在 support 上启用 /ocp 
$ cat > /etc/httpd/conf.d/ocp.conf <<EOF
Alias /ocp "/data/OCP-4.10.30/ocp"
<Directory "/data/OCP-4.10.30/ocp">
  Options +Indexes +FollowSymLinks
  Require all granted
</Directory>
<Location /ocp>
  SetHandler None
</Location>
EOF
$ systemctl restart httpd

# 创建 AgentServiceConfig
# osImages version 来自 rhcos iso
# rootFSUrl 对应 live-rootfs.x86_64.img
# url: 对应 live.x86_64.iso
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: AgentServiceConfig
metadata:
  name: agent
  namespace: multicluster-engine
  ### This is the annotation that injects modifications in the Assisted Service pod
  annotations:
    unsupported.agent-install.openshift.io/assisted-service-configmap: "assisted-service-config"
###
spec:
  databaseStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 20Gi
  filesystemStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 20Gi
  ### disconnected env need default this configmap. it contain ca-bundle.crt and registries.conf
  mirrorRegistryRef:
    name: "mirror-registry-config-map"
  osImages:
    - openshiftVersion: "4.10"
      version: "410.84.202205191234-0"
      rootFSUrl: "http://yum.example.com:8080/ocp/rhcos/rhcos-4.10.16-x86_64-live-rootfs.x86_64.img"
      url: "http://yum.example.com:8080/ocp/rhcos/rhcos-4.10.16-x86_64-live.x86_64.iso"
      cpuArchitecture: "x86_64"
EOF

# 检查一下 structure-operator 日志
$ oc -n multicluster-engine logs $( oc get pods -n multicluster-engine -l control-plane='infrastructure-operator' -o name )

# 正常创建之后会有 agent 相关的 pod 被创建出来
$ oc get pods -n multicluster-engine 

# 创建 ClusterImageSet 
$ cat <<EOF | oc apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: openshift-4.10.30
  namespace: multicluster-engine
spec:
   releaseImage: registry.example.com:5000/openshift/release-images:4.10.30-x86_64
EOF

# 获取 HyperShift Client
$ export HYPERSHIFT_RELEASE=4.10
$ podman cp $(podman create --name hypershift --rm --pull always quay.io/hypershift/hypershift-operator:${HYPERSHIFT_RELEASE}):/usr/bin/hypershift /tmp/hypershift && podman rm -f hypershift
$ sudo install -m 0755 -o root -g root /tmp/hypershift /usr/local/bin/hypershift


```