# 如何用 oc-mirror 同步 openshift-release 和 operator 到目标集群

### 用 grpcurl 检查 index 内容
```
# 用 grpcurl 检查 index 内容
mkdir -p redhat-operator-index/v4.9
podman run -p50051:50051 -it registry.redhat.io/redhat/redhat-operator-index:v4.9
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > redhat-operator-index/v4.9/packages.out
cat redhat-operator-index/v4.9/packages.out
mkdir -p certified-operator-index/v4.9
podman run -p50051:50051 -it registry.redhat.io/redhat/certified-operator-index:v4.9
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > certified-operator-index/v4.9/packages.out
cat certified-operator-index/v4.9/packages.out
mkdir -p community-operator-index/v4.9
podman run -p50051:50051 -it registry.redhat.io/redhat/community-operator-index:v4.9
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > community-operator-index/v4.9/packages.out
cat community-operator-index/v4.9/packages.out
mkdir -p upstream-community-operators/latest
podman run -p50051:50051 -it quay.io/operator-framework/upstream-community-operators:latest
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > upstream-community-operators/latest/packages.out
cat upstream-community-operators/latest/packages.out
mkdir -p gitea-catalog/latest
podman run -p50051:50051 -it quay.io/gpte-devops-automation/gitea-catalog:latest
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > gitea-catalog/latest/packages.out
cat gitea-catalog/latest/packages.out

```

### Install oc-mirror on rhel7
https://asciinema.org/a/uToc11VnzG0RMZrht2dsaTfo9<br>
https://golangissues.com/issues/1156078<br>
```
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux 
source ~/.bash_profile
go version

git clone https://github.com/openshift/oc-mirror
cd oc-mirror
git checkout release-4.10

sh -x hack/build.sh 
cp ./bin/oc-mirror /usr/local/bin
```

### Install oc-mirror on rhel8
https://golangissues.com/issues/1156078<br>
```
yum groupinstall -y "Development Tools"

yum module list go-toolset
yum module -y install go-toolset

git clone https://github.com/openshift/oc-mirror
cd oc-mirror
git checkout release-4.10

make 
cp ./bin/oc-mirror /usr/local/bin

mkdir -p /data/OCP-4.9.9/ocp/ocp-image 

# 生成 image-config-realse-local.yaml 文件
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  ocp:
    channels:
      - name: stable-4.9
        versions:
          - '4.9.9'
          - '4.9.10'
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: local-storage-operator
        - name: openshift-gitops-operator
        - name: advanced-cluster-management
EOF
mkdir -p output-dir
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 生成 image-config-realse-local.yaml 文件
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  ocp:
    channels:
      - name: stable-4.9
        versions:
          - '4.9.9'
          - '4.9.18'
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
    - catalog: registry.redhat.io/redhat/certified-operator-index:v4.9
      headsOnly: false
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 同步 4.9.9 和 4.9.10
# 通过 operator-index 里的部分 operator 
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
storageConfig:
  local:
    path: /root/oc-workspace
mirror:
  ocp:
    channels:
      - name: stable-4.9
        versions:
          - '4.9.9'
          - '4.9.10'
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: advanced-cluster-management
        - name: cluster-logging
        - name: compliance-operator
        - name: container-security-operator
        - name: elasticsearch-operator
        - name: jaeger-product
        - name: kiali-ossm
        - name: kubernetes-nmstate-operator
        - name: kubevirt-hyperconverged
        - name: local-storage-operator
        - name: metallb-operator
        - name: ocs-operator
        - name: odf-operator
        - name: odf-multicluster-orchestrator
        - name: odr-hub-operator
        - name: odr-cluster-operator
        - name: opentelemetry-product
        - name: openshift-gitops-operator
        - name: redhat-oadp-operator
        - name: rhacs-operator
        - name: rhsso-operator
        - name: performance-addon-operator
        - name: serverless-operator
        - name: service-registry-operator
        - name: servicemeshoperator
        - name: submariner
        - name: quay-bridge-operator
        - name: quay-operator
        - name: web-terminal
        - name: windows-machine-config-operator
    - catalog: registry.redhat.io/redhat/certified-operator-index:v4.9
      headsOnly: false
      packages:
        - name: elasticsearch-eck-operator-certified
    - catalog: registry.redhat.io/redhat/community-operator-index:v4.9
      headsOnly: false
      packages:
        - name: grafana-operator
        - name: opendatahub-operator
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 cluster-logging operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
storageConfig:
  local:
    path: /root/oc-workspace
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: cluster-logging
          startingVersion: '5.3.5-20'
          channels:
            - name: 'stable'        
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 acm operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: advanced-cluster-management
          startingVersion: '2.4.2'
          channels:
            - name: 'release-2.4'        
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 compliance operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
storageConfig:
  local:
    path: /root/oc-workspace
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: compliance-operator
          startingVersion: '0.1.48'
          channels:
            - name: 'release-0.1'        
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 kube descheduler operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: cluster-kube-descheduler-operator
          startingVersion: '4.9.0-202202120107'
          channels:
            - name: 'stable'        
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 kube descheduler operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: rhacs-operator
          startingVersion: '3.68.1'
          channels:
            - name: 'rhacs-3.68'        
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 kubevirt hyperconverged operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: kubevirt-hyperconverged
          startingVersion: '4.9.3'
          channels:
            - name: 'stable'
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 odf operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: odf-operator
          startingVersion: '4.9.2'
          channels:
            - name: 'stable-4.9'
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 local storage operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: local-storage-operator
          startingVersion: '4.9.0-202202120107'
          channels:
            - name: 'stable'
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 openshift gitops operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: openshift-gitops-operator
          startingVersion: '1.4.3'
          channels:
            - name: 'stable'
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 kubernetes-nmstate-operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: kubernetes-nmstate-operator
          startingVersion: '4.9.0-202202120107'
          channels:
            - name: 'stable'
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 下载 submariner operator
OPERATOR_NAME='submariner'
OPERATOR_VERSION='0.11.2'
OPERATOR_CHANNEL='alpha-0.11'
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: submariner
          startingVersion: '0.11.2'
          channels:
            - name: 'alpha-0.11'
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir
mv output-dir/mirror_seq1_000000.tar output-dir/redhat-operator-index/v4.9/redhat_operator_index_v4.9_submariner_0.11.2.tar 
BaiduPCS-Go upload output-dir/redhat-operator-index/v4.9/redhat_operator_index_v4.9_submariner_0.11.2.tar /ocp4/oc-mirror


# 下载 quay-operator
OPERATOR_NAME='quay-operator'
OPERATOR_VERSION='3.6.3'
OPERATOR_CHANNEL='stable-3.6'
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: ${OPERATOR_NAME}
          startingVersion: ${OPERATOR_VERSION}
          channels:
            - name: ${OPERATOR_CHANNEL}
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir
mv output-dir/mirror_seq1_000000.tar output-dir/redhat-operator-index/v4.9/redhat_operator_index_v4.9_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar 
BaiduPCS-Go upload output-dir/redhat-operator-index/v4.9/redhat_operator_index_v4.9_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar /ocp4/oc-mirror

# 下载 redhat-oadp-operator
OPERATOR_NAME='redhat-oadp-operator'
OPERATOR_VERSION='1.0.1'
OPERATOR_CHANNEL='stable'
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: ${OPERATOR_NAME}
          startingVersion: ${OPERATOR_VERSION}
          channels:
            - name: ${OPERATOR_CHANNEL}
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir
mv output-dir/mirror_seq1_000000.tar output-dir/redhat-operator-index/v4.9/redhat_operator_index_v4.9_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar 
BaiduPCS-Go upload output-dir/redhat-operator-index/v4.9/redhat_operator_index_v4.9_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar /ocp4/oc-mirror


# 下载社区版 ArgoCD Operator
mkdir -p output-dir/community-operator-index/v4.9

OPERATOR_NAME='argocd-operator'
OPERATOR_VERSION='0.2.1'
OPERATOR_CHANNEL='alpha'
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/community-operator-index:v4.9
      headsOnly: false
      packages:
        - name: ${OPERATOR_NAME}
          startingVersion: ${OPERATOR_VERSION}
          channels:
            - name: ${OPERATOR_CHANNEL}
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir
mv output-dir/mirror_seq1_000000.tar output-dir/community-operator-index/v4.9/community-operator-index_v4.9_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar 
BaiduPCS-Go upload output-dir/community-operator-index/v4.9/community-operator-index_v4.9_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar /ocp4/oc-mirror

# 上传镜像到本地镜像仓库 
/usr/local/bin/oc-mirror --from output-dir/community-operator-index/v4.9/community-operator-index_v4.9_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar docker://registry.example.com:5000

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: community-operator-index
  namespace: openshift-marketplace
spec:
  image: registry.example.com:5000/redhat/community-operator-index:v4.9
  sourceType: grpc
EOF

cat <<EOF | oc apply -f -
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  labels:
    operators.openshift.org/catalog: "true"
  name: catalog-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/openshift-community-operators
    source: quay.io/openshift-community-operators
  - mirrors:
    - registry.example.com:5000/kubebuilder
    source: gcr.io/kubebuilder
  - mirrors:
    - registry.example.com:5000/argoprojlabs
    source: quay.io/argoprojlabs
  - mirrors:
    - registry.example.com:5000/redhat
    source: registry.redhat.io/redhat
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: generic-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/operator-framework
    source: quay.io/operator-framework
EOF



# 下载社区版 ArgoCD Operator
mkdir -p output-dir/gitea-catalog/latest

OPERATOR_NAME='gitea-operator'
OPERATOR_VERSION='1.3.0'
OPERATOR_CHANNEL='stable'
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: quay.io/gpte-devops-automation/gitea-catalog:latest
      headsOnly: false
      packages:
        - name: ${OPERATOR_NAME}
          startingVersion: ${OPERATOR_VERSION}
          channels:
            - name: ${OPERATOR_CHANNEL}
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir
mv output-dir/mirror_seq1_000000.tar output-dir/gitea-catalog/latest/gitea-catalog_latest_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar 
BaiduPCS-Go upload output-dir/gitea-catalog/latest/gitea-catalog_latest_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar /ocp4/oc-mirror

# 添加 catalogsources gitea-catalog
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: gitea-catalog
  namespace: openshift-marketplace
spec:
  image: registry.example.com:5000/gpte-devops-automation/gitea-catalog:latest
  sourceType: grpc
EOF

# 手工拷贝以下非 mirror-by-digest-only 的镜像
skopeo copy --all --authfile /root/.docker/config.json docker://registry.redhat.io/openshift4/ose-kube-rbac-proxy:v4.7.0 docker://registry.example.com:5000/openshift4/ose-kube-rbac-proxy:v4.7.0

skopeo copy --all --authfile /root/.docker/config.json docker://quay.io/gpte-devops-automation/gitea-operator:v1.3.0 docker://registry.example.com:5000/gpte-devops-automation/gitea-operator:v1.3.0

skopeo copy --all --authfile /root/.docker/config.json docker://quay.io/gpte-devops-automation/gitea:latest docker://registry.example.com:5000/gpte-devops-automation/gitea:latest

skopeo copy --all --authfile /root/.docker/config.json docker://registry.redhat.io/rhel8/postgresql-12:latest docker://registry.example.com:5000/rhel8/postgresql-12:latest

# 更新 mcp，让 /etc/container/registries.conf 文件包含以下内容
---
[[registry]]
  prefix = ""
  location = "registry.redhat.io/openshift4"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/openshift4"
---
[[registry]]
  prefix = ""
  location = "quay.io/gpte-devops-automation"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/gpte-devops-automation"
---
[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhel8"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/rhel8"
---


# book-import 
# 手工拷贝以下非 mirror-by-digest-only 的镜像
skopeo copy --all --authfile /root/.docker/config.json docker://quay.io/jpacker/hugo-nginx:latest docker://registry.example.com:5000/jpacker/hugo-nginx:latest


```
