```
## 重要：重要：重要
# 在安装过程中，检查 SNO 节点的 /etc/containers/registries.conf 文件
# 如果内容不正确则重新生成这个文件
# 需重启 crio 服务，需重启 2 次，一次是 bootkube 阶段，一次是写入磁盘重启之后
cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', "docker.io"]
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-release"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer-agent"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer-agent"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2"
EOF
chmod a+r /etc/containers/registries.conf
systemctl restart crio.service

# 拷贝 registry.crt 到 master-0 
# 不清楚为什么 ignition 时没有将 registry.crt 和 registries.conf 文件写入到磁盘内
scp /etc/pki/ca-trust/source/anchors/registry.crt core@192.168.122.201:/tmp
ssh core@192.168.122.201 sudo cp /tmp/registry.crt /etc/pki/ca-trust/source/anchors
ssh core@192.168.122.201 sudo update-ca-trust

# 检查安装情况
cd /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs
kubectl --kubeconfig=./lb-ext.kubeconfig get nodes
kubectl --kubeconfig=./lb-ext.kubeconfig get clusterversion
kubectl --kubeconfig=./lb-ext.kubeconfig get clusteroperators
...
machine-config                                       False       True          True       26s     Cluster not available for 4.9.9

# 最后在安装完之后，需要修改 /etc/container/registries.conf 文件为
# 如果不修改回去，mcp 状态会不正常
cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', 'docker.io']
EOF

oc extract secret/pull-secret -n openshift-config --to=.
# 编辑 .dockerconfigjson 文件
# 移除 cloud.openshift.com JSON 片段
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=./.dockerconfigjson 

# 通过 mcp 更新 registries.conf 文件内容
cat > ./registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', "docker.io"]
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-release"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer-agent"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer-agent"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/openshift-gitops-1"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/openshift-gitops-1"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/openshift4"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/openshift4"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/redhat"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/redhat"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhel8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhel8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rh-sso-7"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rh-sso-7"
EOF

config_source=$(cat ./registries.conf | base64 -w 0 )

# machine config 例子
cat << EOF > ./99-master-zzz-registries-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: masters-registries-configuration
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 3.1.0
    networkd: {}
    passwd: {}
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${config_source}
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf
  osImageURL: ""
EOF
oc apply -f ./99-master-zzz-registries-configuration.yaml

## 重要：重要：重要

# 禁用默认的 catalogsources
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

# 设置本地 CatalogSource
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operator-index
  namespace: openshift-marketplace
spec:
  image: registry.example.com:5000/redhat/redhat-operator-index:v4.9
  sourceType: grpc
EOF

# 设置OAuth
touch $HOME/htpasswd
htpasswd -Bb $HOME/htpasswd admin redhat
htpasswd -Bb $HOME/htpasswd user1 redhat

oc --kubeconfig=/root/kubeconfig-ocp4-1 create secret generic htpasswd --from-file=$HOME/htpasswd -n openshift-config

oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: Local Password
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpasswd
EOF

oc --kubeconfig=/root/kubeconfig-ocp4-1 adm policy add-cluster-role-to-user cluster-admin admin
oc login https://api.ocp4-1.example.com:6443 -u admin 



```