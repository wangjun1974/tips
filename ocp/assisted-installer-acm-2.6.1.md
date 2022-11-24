### ACM 2.6.1 下通过 Assisted Service 安装 SNO OCP 
```
# 创建 Provisioning 对象
$ cat <<EOF | oc apply -f -
apiVersion: metal3.io/v1alpha1
kind: Provisioning
metadata:
  name: provisioning-configuration
spec:
  disableVirtualMediaTLS: true
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
NAME                                                   READY   STATUS    RESTARTS         AGE
agentinstalladmission-769b58c5f6-9mb7l                 1/1     Running   0                52s
agentinstalladmission-769b58c5f6-bq4sx                 1/1     Running   0                52s
assisted-image-service-0                               1/1     Running   0                52s
assisted-service-7c6988678-74nf2                       2/2     Running   0                52s

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

# 创建 namespace
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ocp4-2 
  labels:
    name: ocp4-2
EOF

# 创建 NMStateConfig
# ip - SNO ip
# mac-address - SNO mac address
# labels - 用来选择 NMStateConfig 的 label，未来 LableSelector 会根据它来找到所需对象
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: ocp4-2
  namespace: ocp4-2
  labels:
    cluster-name: ocp4-2
spec:
  config:
    interfaces:
      - name: ens3
        type: ethernet
        state: up
        ethernet:
          auto-negotiation: true
          duplex: full
          speed: 10000
        ipv4:
          address:
          - ip: 192.168.122.111
            prefix-length: 24
          enabled: true
        mtu: 1500
        mac-address: 52:54:00:3d:7f:67
    dns-resolver:
      config:
        server:
        - 192.168.122.12
    routes:
      config:
      - destination: 192.168.122.0/24
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
        table-id: 254
  interfaces:
    - name: ens3
      macAddress: "52:54:00:3d:7f:67"
EOF

# 创建 ssh private key secret
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-ssh-private-key
  namespace: ocp4-2
stringData:
  ssh-privatekey: |-
$( cat /data/ocp-cluster/ocp4-2/ssh-key/id_rsa | sed -e 's/^/    /g' )
type: Opaque
EOF

# 创建 pullsecret secret
$ PULL_SECRET_FILE=/data/OCP-4.10.30/ocp/secret/pull-secret.json
$ PULL_SECRET_STR=$( cat ${PULL_SECRET_FILE} )
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-pull-secret
  namespace: ocp4-2
stringData: 
  .dockerconfigjson: '${PULL_SECRET_STR}'
EOF

# 创建 AgentClusterInstall
# 注意选择合法的 clusterNetwork
$ SSH_PUBLIC_KEY_STR=$( cat /data/ocp-cluster/ocp4-2/ssh-key/id_rsa.pub )
$ cat <<EOF | oc apply -f -
apiVersion: extensions.hive.openshift.io/v1beta1
kind: AgentClusterInstall
metadata:
  name: ocp4-2
  namespace: ocp4-2
spec:
  clusterDeploymentRef:
    name: ocp4-2
  imageSetRef:
    name: openshift-4.10.30
  networking:
    clusterNetwork:
      - cidr: "10.128.0.0/14"
        hostPrefix: 23
    serviceNetwork:
      - "172.31.0.0/16"
    machineNetwork:
      - cidr: "192.168.122.0/24"
  provisionRequirements:
    controlPlaneAgents: 1
  sshPublicKey: '${SSH_PUBLIC_KEY_STR}'
EOF

# 创建 ClusterDeployment
$ cat <<EOF | oc apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: ocp4-2
  namespace: ocp4-2
spec:
  baseDomain: example.com
  clusterName: ocp4-2
  installed: false
  clusterInstallRef:
    group: extensions.hive.openshift.io
    kind: AgentClusterInstall
    name: ocp4-2
    version: v1beta1
  platform:
    agentBareMetal:
      agentSelector:
        matchLabels:
          agent-install.openshift.io/clusterdeployment-namespace: "ocp4-2"
  pullSecretRef:
    name: assisted-deployment-pull-secret
EOF

# 创建 KlusterletAddonConfig
$ cat <<EOF | oc apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ocp4-2
  namespace: ocp4-2
spec:
  clusterName: ocp4-2
  clusterNamespace: ocp4-2
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: false
  iamPolicyController:
    enabled: false
  policyController:
    enabled: true
  searchCollector:
    enabled: false 
EOF

# 创建 ManagedCluster
$ cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ocp4-2
spec:
  hubAcceptsClient: true
EOF

# 创建 InfraEnv
$ SSH_PUBLIC_KEY_STR=$( cat /data/ocp-cluster/ocp4-2/ssh-key/id_rsa.pub )
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: ocp4-2
  namespace: ocp4-2
spec:
  additionalNTPSources:
    - ntp.example.com  
  clusterRef:
    name: ocp4-2
    namespace: ocp4-2
  sshAuthorizedKey: '${SSH_PUBLIC_KEY_STR}'
  agentLabelSelector:
    matchLabels:
      agent-install.openshift.io/clusterdeployment-namespace: "ocp4-2"
  pullSecretRef:
    name: assisted-deployment-pull-secret
  ignitionConfigOverride: '{"ignition":{"version":"3.1.0"},"storage":{"files":[{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /tmp/registry.conf | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/containers/registries.conf"},{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/pki/ca-trust/source/anchors/registry.crt"}]}}'
  nmStateConfigLabelSelector:
    matchLabels:
      cluster-name: ocp4-2
EOF

# Add Host
# Download Discovery ISO
# 用 Discovery ISO 启动节点
# 在节点启动界面输入 Tab，然后输入 nameserver=192.168.122.12 ip=192.168.122.111::192.168.122.1:255.255.255.0:master-0.ocp4-2.example.com:ens3:none
# 在界面 Approve Host
# 将自动进入 cluster ocp4-2 安装阶段
# 等待安装结束

# 检查 assisted-service 日志
$ oc -n multicluster-engine logs $ ( oc get pods -n multicluster-engine -l app='assisted-service' -o name )
```

### DNS 配置
```
$ cat /etc/named.rfc1912.zones
...
zone "ocp4-2.example.com" IN {
        type master;
        file "ocp4-2.example.com.zone";
        allow-transfer { any; };
};

$ cat /var/named/ocp4-2.example.com.zone
$ORIGIN ocp4-2.example.com.
$TTL 1D
@           IN SOA  ocp4-2.example.com. admin.ocp4-2.example.com. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum

@             IN NS                         dns.example.com.

lb             IN A                          192.168.122.111

api            IN A                          192.168.122.111
api-int        IN A                          192.168.122.111
*.apps         IN A                          192.168.122.111

bootstrap      IN A                          192.168.122.111

master-0       IN A                          192.168.122.111

etcd-0         IN A                          192.168.122.111

_etcd-server-ssl._tcp.ocp4-2.example.com. 8640 IN SRV 0 10 2380 etcd-0.ocp4-2.example.com.

$ cat /var/named/168.192.in-addr.arpa.zone
...
111.122.168.192.in-addr.arpa.    IN PTR      master-0.ocp4-2.example.com.

```

### 考虑测试将 Assisted Service 与 Metal3 集成起来 
```
# 如果 BMC VirtualMedia 不支持 https 需要调整 Provisioning 的 spec.disableVirtualMediaTLS
$ cat <<EOF | oc apply -f -
apiVersion: metal3.io/v1alpha1
kind: Provisioning
metadata:
  name: provisioning-configuration
spec:
  disableVirtualMediaTLS: true  <------------------ This flag downgrades to http on the bmc (virtual media mount)
  provisioningNetwork: Disabled
  watchAllNamespaces: true
EOF
```

### 试试 BMC 与 Assisted Service 一起如何工作
```
# 创建 namespace
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ocp4-3 
  labels:
    name: ocp4-3
EOF

# 创建 NMStateConfig
# ip - SNO ip
# mac-address - SNO mac address
# labels - 用来选择 NMStateConfig 的 label，未来 LableSelector 会根据它来找到所需对象
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: ocp4-3
  namespace: ocp4-3
  labels:
    cluster-name: ocp4-3
spec:
  config:
    interfaces:
      - name: enp1s0
        type: ethernet
        state: up
        ethernet:
          auto-negotiation: true
          duplex: full
          speed: 10000
        ipv4:
          address:
          - ip: 192.168.122.131
            prefix-length: 24
          enabled: true
        mtu: 1500
        mac-address: 52:54:00:d7:42:ac
    dns-resolver:
      config:
        server:
        - 192.168.122.12
    routes:
      config:
      - destination: 192.168.122.0/24
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
        table-id: 254
  interfaces:
    - name: ens3
      macAddress: "52:54:00:d7:42:ac"
EOF

# 创建 ssh private key secret
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-ssh-private-key
  namespace: ocp4-3
stringData:
  ssh-privatekey: |-
$( cat /data/ocp-cluster/ocp4-3/ssh-key/id_rsa | sed -e 's/^/    /g' )
type: Opaque
EOF

# 创建 pullsecret secret
$ PULL_SECRET_FILE=/data/OCP-4.10.30/ocp/secret/pull-secret.json
$ PULL_SECRET_STR=$( cat ${PULL_SECRET_FILE} )
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-pull-secret
  namespace: ocp4-3
stringData: 
  .dockerconfigjson: '${PULL_SECRET_STR}'
EOF

# 创建 AgentClusterInstall
# 注意选择合法的 clusterNetwork
$ SSH_PUBLIC_KEY_STR=$( cat /data/ocp-cluster/ocp4-3/ssh-key/id_rsa.pub )
$ cat <<EOF | oc apply -f -
apiVersion: extensions.hive.openshift.io/v1beta1
kind: AgentClusterInstall
metadata:
  name: ocp4-3
  namespace: ocp4-3
spec:
  clusterDeploymentRef:
    name: ocp4-3
  imageSetRef:
    name: openshift-4.10.30
  networking:
    clusterNetwork:
      - cidr: "10.128.0.0/14"
        hostPrefix: 23
    serviceNetwork:
      - "172.31.0.0/16"
    machineNetwork:
      - cidr: "192.168.122.0/24"
  provisionRequirements:
    controlPlaneAgents: 1
  sshPublicKey: '${SSH_PUBLIC_KEY_STR}'
EOF

# 创建 ClusterDeployment
$ cat <<EOF | oc apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: ocp4-3
  namespace: ocp4-3
spec:
  baseDomain: example.com
  clusterName: ocp4-3
  installed: false
  clusterInstallRef:
    group: extensions.hive.openshift.io
    kind: AgentClusterInstall
    name: ocp4-3
    version: v1beta1
  platform:
    agentBareMetal:
      agentSelector:
        matchLabels:
          cluster-name: "ocp4-3"
  pullSecretRef:
    name: assisted-deployment-pull-secret
EOF

# 创建 KlusterletAddonConfig
$ cat <<EOF | oc apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ocp4-3
  namespace: ocp4-3
spec:
  clusterName: ocp4-3
  clusterNamespace: ocp4-3
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: false
  iamPolicyController:
    enabled: false
  policyController:
    enabled: true
  searchCollector:
    enabled: false 
EOF

# 创建 ManagedCluster
$ cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ocp4-3
spec:
  hubAcceptsClient: true
EOF

# 创建 InfraEnv
# 在 SNO ZTP 流程里是否不需要 AgentSelector?
# https://access.redhat.com/documentation/en-us/openshift_container_platform/4.11/html/scalability_and_performance/ztp-deploying-disconnected#ztp-manually-install-a-single-managed-cluster_ztp-deploying-disconnected
$ SSH_PUBLIC_KEY_STR=$( cat /data/ocp-cluster/ocp4-3/ssh-key/id_rsa.pub )
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: ocp4-3
  namespace: ocp4-3
spec:
  additionalNTPSources:
    - ntp.example.com  
  clusterRef:
    name: ocp4-3
    namespace: ocp4-3
  sshAuthorizedKey: '${SSH_PUBLIC_KEY_STR}'
  agentLabelSelector:
    matchLabels:
      cluster-name: "ocp4-3"
  pullSecretRef:
    name: assisted-deployment-pull-secret
  ignitionConfigOverride: '{"ignition":{"version":"3.1.0"},"storage":{"files":[{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /tmp/registry.conf | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/containers/registries.conf"},{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/pki/ca-trust/source/anchors/registry.crt"}]}}'
  nmStateConfigLabelSelector:
    matchLabels:
      cluster-name: ocp4-3
EOF

# 创建 bmc secret 
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ocp4-3-bmc-secret
  namespace: ocp4-3
type: Opaque
data:
  username: "YWRtaW4K"
  password: "cmVkaGF0Cg=="
EOF

# 创建 BareMetalHost
$ cat <<'EOF' | oc apply -f -
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: ocp4-3
  namespace: ocp4-3
  annotations:
    inspect.metal3.io: disabled
    bmac.agent-install.openshift.io/role: "master"
  labels:
    infraenvs.agent-install.openshift.io: "ocp4-3"
spec:
  bootMode: "UEFI"
  bmc:
    address: redfish-virtualmedia+http://192.168.122.1:8000/redfish/v1/Systems/d5c8e4f6-f5b6-4c31-a85b-4d6f9237d3a7
    credentialsName: ocp4-3-bmc-secret
    disableCertificateVerification: true
  bootMACAddress: "52:54:00:d7:42:ac"
  automatedCleaningMode: disabled
  online: true
EOF

# 查看 metal3 日志
$ oc -n openshift-machine-api logs $( oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator='metal3-state' -o name ) -c metal3-baremetal-operator
$ oc -n openshift-machine-api logs $( oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator='metal3-state' -o name ) -c metal3-ironic-conductor 

```