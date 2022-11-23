### 状态：Progressing
```
# 目前看按照链接 "https://hypershift-docs.netlify.app/how-to/agent/create-agent-cluster/" 里的步骤，需要 Hub Cluster 和 Hosted Cluster 为 4.11
# Done: 同步 OCP 4.11.5 release image 到离线 registry 
# Done: 同步 registry.redhat.io/redhat/redhat-operator-index:v4.11 的部分 operator 到离线 registry
# Done: 安装 Hub OCP 4.11.5
# Done: 安装 ACM 2.6.2 和 MCE 2.1.2
```
 

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

### 启用 Metal3 - BareMetalHost Provisiong 
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

$ oc get pods -n openshift-machine-api | grep metal3
metal3-5c6f9879f9-4wh6h                       5/5     Running   0             14s
metal3-image-cache-szjwm                      1/1     Running   0             2m14s
metal3-image-customization-5c874cd776-t8v7b   1/1     Running   0             2m11s
```

### HyperShift with Agent CAPI + BareMetalHost + StaticIP
https://hypershift-docs.netlify.app/how-to/agent/create-agent-cluster/ 
```
# 1. 启用 Agent Installer (Assisted Service)
# 1.1 创建 Provisioning 对象
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

$ oc get pods -n openshift-machine-api | grep metal3
metal3-5c6f9879f9-4wh6h                       5/5     Running   0             14s
metal3-image-cache-szjwm                      1/1     Running   0             2m14s
metal3-image-customization-5c874cd776-t8v7b   1/1     Running   0             2m11s

# 1.2 生成 mirror-registry-config-map
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

# 1.3 生成 configmap mirror-registry-config-map
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

# 1.4 创建 configmap 指定 ISO_IMAGE_TYPE 为 full-iso
# ACM 2.6 需要把 namespace 改为 multicluster-engine
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

# 在 support 机器上启用提供 osImages 的 web service   
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
    - openshiftVersion: "4.11"
      version: "411.86.202208112011-0"
      rootFSUrl: "http://yum.example.com:8080/ocp/rhcos/rhcos-4.11.2-x86_64-live-rootfs.x86_64.img"
      url: "http://yum.example.com:8080/ocp/rhcos/rhcos-4.11.2-x86_64-live.x86_64.iso"
      cpuArchitecture: "x86_64"
EOF

# 检查一下 infrastructure-operator 日志
$ oc -n multicluster-engine logs $( oc get pods -n multicluster-engine -l control-plane='infrastructure-operator' -o name )

# 正常创建之后会有 agent 相关的 pod 被创建出来
$ oc get pods -n multicluster-engine | grep -E "assisted|agent"
agentinstalladmission-c9ffb7757-f9jql                  1/1     Running   0          95s
agentinstalladmission-c9ffb7757-pvhrr                  1/1     Running   0          95s
assisted-image-service-0                               1/1     Running   0          94s
assisted-service-655bcbdf57-vmmnf                      2/2     Running   0          95s

# 创建 ClusterImageSet 
$ cat <<EOF | oc apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: openshift-4.11.5
  namespace: multicluster-engine
spec:
   releaseImage: registry.example.com:5000/openshift/release-images:4.11.5-x86_64
EOF

$ cat <<EOF | oc apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: openshift-4.10.30
  namespace: multicluster-engine
spec:
   releaseImage: registry.example.com:5000/openshift/release-images:4.10.30-x86_64
EOF

# 安装 hypershift client
# 用 oc-mirror 同步 quay.io/openshifttest/hypershift-client:latest 到离线 registry
$ cd /tmp
$ oc image extract registry.example.com:5000/openshifttest/hypershift-client:latest --file=/hypershift
$ sudo install -m 0755 -o root -g root /tmp/hypershift /usr/local/bin/hypershift


# 安装 hypershift operator
# 用 oc-mirror 同步 quay.io/hypershift/hypershift-operator:latest 到离线 registry
$ export ADDITIONAL_TRUST_BUNDLE=/etc/pki/ca-trust/source/anchors/registry.crt
$ hypershift install --hypershift-image "quay.io/hypershift/hypershift-operator:latest" --additional-trust-bundle=/etc/pki/ca-trust/source/anchors/registry.crt

# 需要生成 'mirror-by-digest-only = false' 的 registries.conf.d/xxx.conf 的 machineconfig 
$ cd /tmp
$ cat > my_registry.conf <<EOF
[[registry]]
  prefix = ""
  location = "quay.io/hypershift"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/hypershift"

EOF
$ cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-mirror-by-digest-false-registries
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(base64 -w0 my_registry.conf)
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf.d/99-master-mirror-by-digest-false-registries.conf
EOF

$ oc get pods -n hypershift
NAME                        READY   STATUS    RESTARTS   AGE
operator-666765c55f-bm556   1/1     Running   0          3m43s

# 配置 hypershift client 所在机器的 mirror registry conf
$ cat > /etc/containers/registries.conf.d/hypershift-client.conf <<EOF
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

EOF

# 设置 hypershift management cluster --image-content-sources，这步暂时不执行，oc-mirror 已生成所需 ImageContentSourcePolicy
$ cat > /tmp/hypershift-icsp.json <<EOF
{
    "apiVersion": "operator.openshift.io/v1alpha1",
    "kind": "ImageContentSourcePolicy",
    "metadata": {
        "name": "hypershift-0"
    },
    "spec": {
        "repositoryDigestMirrors": [
            {
                "mirrors": [
                    "registry.example.com:5000/openshift/release"
                ],
                "source": "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
            },
            {
                "mirrors": [
                    "registry.example.com:5000/openshift/release-images"
                ],
                "source": "quay.io/openshift-release-dev/ocp-release"
            }
        ]
    }
}
EOF

# 创建 hosted cluster
$ export CLUSTERS_NAMESPACE="clusters"
$ export HOSTED_CLUSTER_NAME="ocp4-3"
$ export HOSTED_CONTROL_PLANE_NAMESPACE="${CLUSTERS_NAMESPACE}-${HOSTED_CLUSTER_NAME}"
$ export BASEDOMAIN="example.com"
$ export PULL_SECRET_FILE=/data/OCP-4.10.30/ocp/secret/redhat-pull-secret.json
$ export OCP_RELEASE=4.11.5-x86_64
$ export MACHINE_CIDR=192.168.122.0/24
$ export IMAGE_CONTENT_SOURCE=/tmp/hypershift-icsp.json

# 创建 namespace
$ oc create ns ${HOSTED_CONTROL_PLANE_NAMESPACE}


# 4.11 版 hypershift 支持 --api-server-address 参数
$ hypershift create cluster agent \
    --name=${HOSTED_CLUSTER_NAME} \
    --pull-secret=${PULL_SECRET_FILE} \
    --agent-namespace=${HOSTED_CONTROL_PLANE_NAMESPACE} \
    --base-domain=${BASEDOMAIN} \
    --api-server-address=api.${HOSTED_CLUSTER_NAME}.${BASEDOMAIN} \
    --node-pool-replicas=0 \
    --release-image=registry.example.com:5000/openshift/release-images:${OCP_RELEASE}

# cluster agent 目前有问题未尝试通 
# cluster none 
$ hypershift create cluster none \
    --name=${HOSTED_CLUSTER_NAME} \
    --pull-secret=${PULL_SECRET_FILE} \
    --node-pool-replicas=0 \
    --release-image=registry.example.com:5000/openshift/release-images:${OCP_RELEASE}

# 创建 NMStateConfig
# ip - worker ip
# mac-address - worker mac address
# labels - 用来选择 NMStateConfig 的 label，未来 InfraEnv 会根据 LabelSelector 来找到所需的 NMStateConfig 对象
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: worker-0
  namespace: ${HOSTED_CONTROL_PLANE_NAMESPACE}
  labels:
    cluster-name: ${HOSTED_CLUSTER_NAME}
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
        next-hop-interface: enp1s0
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.122.1
        next-hop-interface: enp1s0
        table-id: 254
  interfaces:
    - name: enp1s0
      macAddress: "52:54:00:d7:42:ac"
EOF

$ PULL_SECRET_STR=$( cat ${PULL_SECRET_FILE} )
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-pull-secret
  namespace: ${HOSTED_CONTROL_PLANE_NAMESPACE}
stringData: 
  .dockerconfigjson: '${PULL_SECRET_STR}'
EOF

$ SSH_PUBLIC_KEY_STR=$( cat /data/ocp-cluster/ocp4-3/ssh-key/id_rsa.pub )
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: ocp4-3
  namespace: ${HOSTED_CONTROL_PLANE_NAMESPACE}
spec:
  additionalNTPSources:
    - ntp.example.com  
  sshAuthorizedKey: '${SSH_PUBLIC_KEY_STR}'
  pullSecretRef:
    name: assisted-deployment-pull-secret
  ignitionConfigOverride: '{"ignition":{"version":"3.1.0"},"storage":{"files":[{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /tmp/registry.conf | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/containers/registries.conf"},{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/pki/ca-trust/source/anchors/registry.crt"}]}}'
  nmStateConfigLabelSelector:
    matchLabels:
      cluster-name: ${HOSTED_CLUSTER_NAME}
EOF

$ oc -n ${HOSTED_CONTROL_PLANE_NAMESPACE} get InfraEnv ${HOSTED_CLUSTER_NAME} -ojsonpath="{.status.isoDownloadURL}"

$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: worker-0-bmc-secret
  namespace: ${HOSTED_CONTROL_PLANE_NAMESPACE}
type: Opaque
data:
  username: "YWRtaW4K"
  password: "cmVkaGF0Cg=="
EOF

$ WORKER_NAME="worker-0"
$ envsubst <<"EOF" | oc apply -f -
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: worker-0
  namespace: ${HOSTED_CONTROL_PLANE_NAMESPACE}
  annotations:
    inspect.metal3.io: disabled
    bmac.agent-install.openshift.io/hostname: 'worker-0.ocp4-3.example.com'
  labels:
    infraenvs.agent-install.openshift.io: ${HOSTED_CLUSTER_NAME}
spec:
  bootMode: "UEFI"
  bmc:
    address: redfish-virtualmedia+http://192.168.122.1:8000/redfish/v1/Systems/d5c8e4f6-f5b6-4c31-a85b-4d6f9237d3a7
    credentialsName: worker-0-bmc-secret
    disableCertificateVerification: true
  bootMACAddress: "52:54:00:d7:42:ac"
  automatedCleaningMode: disabled
  online: true
EOF

$ oc -n ${HOSTED_CONTROL_PLANE_NAMESPACE} get bmh
NAME     STATE         CONSUMER   ONLINE   ERROR   AGE
ocp4-3   provisioned              true             70s

$ oc -n ${HOSTED_CONTROL_PLANE_NAMESPACE} get agent
NAME                                   CLUSTER   APPROVED   ROLE          STAGE
d5c8e4f6-f5b6-4c31-a85b-4d6f9237d3a7             false      auto-assign   

$ oc -n ${HOSTED_CONTROL_PLANE_NAMESPACE} patch agent d5c8e4f6-f5b6-4c31-a85b-4d6f9237d3a7 -p '{"spec":{"installation_disk_id":"/dev/vda","approved":true,"hostname":"worker-0.ocp4-3.example"}}' --type merge

$ oc -n ${HOSTED_CONTROL_PLANE_NAMESPACE} get agent
NAME                                   CLUSTER   APPROVED   ROLE          STAGE
d5c8e4f6-f5b6-4c31-a85b-4d6f9237d3a7             true       auto-assign   

$ envsubst <<"EOF" | oc apply -f -
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: worker-0
  namespace: ${HOSTED_CONTROL_PLANE_NAMESPACE}
  annotations:
    inspect.metal3.io: disabled
    bmac.agent-install.openshift.io/hostname: 'worker-0.ocp4-3.example.com'
  labels:
    infraenvs.agent-install.openshift.io: ${HOSTED_CLUSTER_NAME}
spec:
  bootMode: "UEFI"
  bmc:
    address: redfish-virtualmedia+http://192.168.122.1:8000/redfish/v1/Systems/d5c8e4f6-f5b6-4c31-a85b-4d6f9237d3a7
    credentialsName: worker-0-bmc-secret
    disableCertificateVerification: true
  bootMACAddress: "52:54:00:d7:42:ac"
  automatedCleaningMode: disabled
  online: true
EOF

$ oc -n ${HOSTED_CONTROL_PLANE_NAMESPACE} get bmh
NAME       STATE         CONSUMER   ONLINE   ERROR   AGE
worker-0   provisioned              true             90s

$ oc -n ${CLUSTERS_NAMESPACE} scale nodepool ${HOSTED_CLUSTER_NAME} --replicas 1

```

### 查看日志
```
# 查看 hypershift operator 的日志
$ oc -n hypershift logs $( oc get pods -n hypershift -l app='operator' -o name )

# 查看 hypershift-addon-manager 的日志
$ oc -n multicluster-engine logs $( oc -n multicluster-engine get pods -l app=hypershift-addon-manager -o name )
```