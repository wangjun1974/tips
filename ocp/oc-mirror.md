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

# 检查 index image from brew
mkdir -p multicluster-engine-klusterlet-operator-bundle/v2.0.0-23
podman run --authfile /root/pull-secret-full.json -p50051:50051 -it brew.registry.redhat.io/rh-osbs/iib:198969
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > multicluster-engine-klusterlet-operator-bundle/v2.0.0-23/packages.out
cat multicluster-engine-klusterlet-operator-bundle/v2.0.0-23/packages.out

# 从容器内拷贝 /database/index.db 到本地
# 参考 jq 的使用：https://shapeshed.com/jq-json/
podman cp 11fd2d1e933f://database/index.db multicluster-engine-klusterlet-operator-bundle/v2.0.0-23/
# 查询 index.db 内容
echo "select * from related_image \
    where operatorbundle_name like 'klusterlet%';" \
    | sqlite3 -line ./multicluster-engine-klusterlet-operator-bundle/v2.0.0-23/index.db 
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
# 记得加上 --continue-on-error 这个参数，可以遇错继续执行
# 尽可能不要用 --continue-on-error 参数
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml --continue-on-error file://output-dir

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
OPERATOR_VERSION='v1.3.0'
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
/usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir
mv output-dir/mirror_seq1_000000.tar output-dir/gitea-catalog_latest_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar 
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

### 下载地址
### 4.11 GA Version
https://console.redhat.com/openshift/downloads

### https://github.com/openshift/oc-mirror#operators
### 列出 OpenShift OperatorHub Catalog
# /usr/local/bin/oc-mirror list operators --catalogs --version=4.11
Available OpenShift OperatorHub catalogs:
OpenShift 4.11:
registry.redhat.io/redhat/redhat-operator-index:v4.11
registry.redhat.io/redhat/certified-operator-index:v4.11
registry.redhat.io/redhat/community-operator-index:v4.11
registry.redhat.io/redhat/redhat-marketplace-index:v4.11
# /usr/local/bin/oc-mirror list operators --catalogs --version=4.10
Available OpenShift OperatorHub catalogs:
OpenShift 4.10:
registry.redhat.io/redhat/redhat-operator-index:v4.10
registry.redhat.io/redhat/certified-operator-index:v4.10
registry.redhat.io/redhat/community-operator-index:v4.10
registry.redhat.io/redhat/redhat-marketplace-index:v4.10

### 列出 catalog registry.redhat.io/redhat/redhat-operator-index:v4.10 有哪些 operator
# /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10
### 列出 catalog registry.redhat.io/redhat/redhat-operator-index:v4.11 有哪些 operator
# /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.11
### 列出 catalog registry.redhat.io/redhat/redhat-operator-index:v4.10 package advanced-cluster-management channel release-2.4
# /usr/local/bin/oc-mirror list operators --package=advanced-cluster-management --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10 --channel=release-2.6
# 列出 catalog registry.redhat.io/redhat/redhat-operator-index:v4.10 package openshift-gitops-operator
# /usr/local/bin/oc-mirror list operators --package=openshift-gitops-operator --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10 
# 列出 catalog registry.redhat.io/redhat/redhat-operator-index:v4.10 package advanced-cluster-management
# /usr/local/bin/oc-mirror list operators --package=advanced-cluster-management --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10
# 列出 catalog registry.redhat.io/redhat/redhat-operator-index:v4.10 package performance-addon-operator 
# /usr/local/bin/oc-mirror list operators --package=performance-addon-operator  --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10
# 列出 catalog registry.redhat.io/redhat/redhat-operator-index:v4.10 package kubernetes-nmstate-operator 
# /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10 --package=kubernetes-nmstate-operator
# 列出 catalog registry.redhat.io/redhat/redhat-operator-index:v4.10 package multicluster-engine 
# /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10 --package=multicluster-engine

# 列出 catalog registry.redhat.io/redhat/redhat-operator-index:v4.10 package kubevirt-hyperconverged performance-addon-operator kubernetes-nmstate-operator sriov-network-operator local-storage-operator odf-operator cincinnati-operator advanced-cluster-management openshift-gitops-operator odf-lvm-operator multicluster-engine
$ for packagename in kubevirt-hyperconverged performance-addon-operator kubernetes-nmstate-operator sriov-network-operator local-storage-operator odf-operator cincinnati-operator advanced-cluster-management openshift-gitops-operator odf-lvm-operator multicluster-engine rhacs-operator ansible-automation-platform-operator
do 
  /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10 --package=${packagename}
done

### 同步 Software PLC 会用到的 Operator
### 生成 image-config-release-local.yaml
### metadata 保存在 /root/oc-mirror/oc-history 里
### 不使用 archiveSize
### 不使用 storageConfig
### storageConfig:
###  local:
###    path: /root/oc-mirror/oc-history
### 20221009
$ mkdir -p /root/oc-mirror/oc-history
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
      - name: fast-4.11
        minVersion: 4.10.30
        maxVersion: 4.11.5
        shortestPath: true
    graph: true # Include Cincinnati upgrade graph image in imageset
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.10
      packages:
        - name: kubevirt-hyperconverged
          channels:
            - name: 'stable'
              minVersion: 'v4.10.5'
              maxVersion: 'v4.10.5'            
        - name: performance-addon-operator
          channels:
            - name: '4.10'
              minVersion: 'v4.10.8'
              maxVersion: 'v4.10.8'
        - name: kubernetes-nmstate-operator
          channels:
            - name: 'stable'
              minVersion: '4.10.0-202209220918'
              maxVersion: '4.10.0-202209220918'
            - name: '4.10'
              minVersion: '4.10.0-202209220918'
              maxVersion: '4.10.0-202209220918'              
        - name: sriov-network-operator
          channels:
            - name: 'stable'
              minVersion: '4.10.0-202209231817'
              maxVersion: '4.10.0-202209231817'
            - name: '4.10'
              minVersion: '4.10.0-202209231817'
              maxVersion: '4.10.0-202209231817'              
        - name: local-storage-operator
          channels:
            - name: 'stable'
              minVersion: '4.10.0-202209080237'
              maxVersion: '4.10.0-202209080237'
            - name: '4.10'
              minVersion: '4.10.0-202209080237'
              maxVersion: '4.10.0-202209080237'              
        - name: odf-operator
          channels:
            - name: 'stable-4.10'
              minVersion: 'v4.10.6'
              maxVersion: 'v4.10.6'
            - name: 'stable-4.9'
              minVersion: 'v4.9.11'
              maxVersion: 'v4.9.11'
        - name: cincinnati-operator
          channels:
            - name: v1
              minVersion: 'v5.0.0'
              maxVersion: 'v5.0.0'
        - name: advanced-cluster-management
          channels:
            - name: release-2.6
              minVersion: 'v2.6.1'
              maxVersion: 'v2.6.1'
            - name: release-2.4
              minVersion: 'v2.4.7'
              maxVersion: 'v2.4.7'             
        - name: openshift-gitops-operator
          channels:
            - name: latest
              minVersion: 'v1.6.1'
              maxVersion: 'v1.6.1'
            - name: stable
              minVersion: 'v1.5.6'
              maxVersion: 'v1.5.6'
        - name: odf-lvm-operator
          channels:
            - name: stable-4.10
              minVersion: 'v4.10.6'
              maxVersion: 'v4.10.6'
        - name: multicluster-engine
          channels:
            - name: stable-2.1
              minVersion: 'v2.1.1'
              maxVersion: 'v2.1.1'
            - name: stable-2.0
              minVersion: 'v2.0.2'
              maxVersion: 'v2.0.2'
EOF

# 同步定制化的 operator catalog redhat-operator-index 和 images 到本地
# 检查输出，处理所有错误
$ /usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml --continue-on-error file://output-dir


# 拷贝 output-dir/mirror_seq1_000000.tar 到离线环境

# 上传镜像
$ /usr/local/bin/oc-mirror --from /tmp/mirror_seq1_000000.tar docker://registry.example.com:5000
...


# 安装离线 OCP 集群

# 安装完成后，在离线 OCP 集群下 apply release-signatures 
# https://docs.openshift.com/container-platform/4.10/updating/updating-restricted-network-cluster.html#update-mirror-repository_updating-restricted-network-cluster
# https://coreos.slack.com/archives/CEGKQ43CP/p1663229617076729
# [root@support oc-mirror-workspace]# tree results-1663211170 
# results-1663211170
# ├── catalogSource-redhat-operator-index.yaml
# ├── charts
# ├── imageContentSourcePolicy.yaml
# ├── mapping.txt
# ├── release-signatures
# │   ├── signature-sha256-7f543788330d4866.json
# │   └── signature-sha256-86f3b85645c613dc.json
# └── updateService.yaml
$ oc apply -f results-1663211170/release-signatures/signature-sha256-7f543788330d4866.json
$ oc apply -f results-1663211170/release-signatures/signature-sha256-86f3b85645c613dc.json

# 禁用默认 OperatorHub CatalogSources
$ oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

# 设置 CatalogSource 和 ImageContentSourcePolicy
$ pwd
/root/oc-mirror-workspace/results-1662455093

# 查看 catalogSource-redhat-operator-index.yaml 文件内容
$ cat catalogSource-redhat-operator-index.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operator-index
  namespace: openshift-marketplace
spec:
  image: registry.example.com:5000/redhat/redhat-operator-index:v4.10
  sourceType: grpc
# 设置 CatalogSource
$ oc apply -f catalogSource-redhat-operator-index.yaml

# 查看 imageContentSourcePolicy.yaml 内容
$ cat imageContentSourcePolicy.yaml 
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: generic-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/ubi8
    source: registry.access.redhat.com/ubi8
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  labels:
    operators.openshift.org/catalog: "true"
  name: operator-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/redhat
    source: registry.redhat.io/redhat
  - mirrors:
    - registry.example.com:5000/openshift4
    source: registry.redhat.io/openshift4
  - mirrors:
    - registry.example.com:5000/container-native-virtualization
    source: registry.redhat.io/container-native-virtualization
  - mirrors:
    - registry.example.com:5000/odf4
    source: registry.redhat.io/odf4
  - mirrors:
    - registry.example.com:5000/rhel8
    source: registry.redhat.io/rhel8
  - mirrors:
    - registry.example.com:5000/rhceph
    source: registry.redhat.io/rhceph
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: release-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/openshift/release
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - registry.example.com:5000/openshift/release-images
    source: quay.io/openshift-release-dev/ocp-release

# 设置 imageContentSourcePolicy 
$ oc apply -f imageContentSourcePolicy.yaml

### 首先安装 cincinnati-operator
### https://coreos.slack.com/archives/CEGKQ43CP/p1624451445176500
### https://wangzheng422.github.io/docker_env/ocp4/4.8/4.8.update.service.html

### 然后添加 configmap，configmap 的 key 需要是 updateservice-registry
$ CERTS_PATH="/data/registry/certs"
$ oc -n openshift-config create configmap trusted-ca --from-file=updateservice-registry=${CERTS_PATH}/registry.crt
### 设置 image.config.openshift.io/cluster 的 spec.additionalTrustedCA
$ oc patch image.config.openshift.io cluster --patch '{"spec":{"additionalTrustedCA":{"name":"trusted-ca"}}}' --type=merge
$ oc get image.config.openshift.io -o json  | jq -r '.items[].spec'

# 查看 updateService.yaml 
$ cat updateService.yaml
apiVersion: updateservice.operator.openshift.io/v1
kind: UpdateService
metadata:
  name: update-service-oc-mirror
  namespace: openshift-update-service # 注意添加namespace
spec:
  graphDataImage: registry.example.com:5000/openshift/graph-image@sha256:ce648ec0aac3bbd61ed6229564fbba01851bbdde3987ab6cdaec7951d8202ca6
  releases: registry.example.com:5000/openshift/release-images
  replicas: 1 # 默认为2，SNO 改为 1

$ oc apply -f updateService.yaml

# 更新 openshift-update-service namespace serviceaccount default 的 pull secret
$ cd ${OCP_PATH}/secret
$ oc -n openshift-update-service create secret generic cincinnati --from-file=.dockerconfigjson=redhat-pull-secret.json --type=kubernetes.io/dockerconfigjson
$ oc -n openshift-update-service patch sa default -p '{"imagePullSecrets": [{"name": "cincinnati"}]}'

# 删除并重建 update-service-oc-mirror pod
$ oc -n openshift-update-service delete $(oc get pods -n openshift-update-service -l app=update-service-oc-mirror -o name)

# 查看日志
$ oc -n openshift-update-service logs $(oc get pods -n openshift-update-service -l app=update-service-oc-mirror -o name) -c graph-builder

# 获取 route/update-service-oc-mirror-route 的 certificate
$ openssl s_client -host $(oc get route -n openshift-update-service update-service-oc-mirror-route -o jsonpath='{.spec.host}' ) -port 443 -showcerts > trace < /dev/null
$ cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee update-service.crt  
$ cat update-service.crt | sed -e 's|^|    |g'
    -----BEGIN CERTIFICATE-----
    MIIDaTCCAlGgAwIBAgIIUPWmfgMQ5igwDQYJKoZIhvcNAQELBQAwJjEkMCIGA1UE
    AwwbaW5ncmVzcy1vcGVyYXRvckAxNjYzMTQyMzg5MB4XDTIyMDkxNDA3NTk1N1oX
    DTI0MDkxMzA3NTk1OFowJDEiMCAGA1UEAwwZKi5hcHBzLm9jcDQtMS5leGFtcGxl
    LmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANBfyiH+JGw/YhCH
    2FyG6PBR6YKRf6mdYtOVpJQoUR544hmo3eidxu3I59GNIMMUhTXfRLvHKJHEjU9g
    KQpVHbzJh7i4C2RH7tewihrA6cneoXTw6LbGmBinvnhnc7ijc0I+OcWgufBhjlFE
    T1TgbaBgYiFFUfSrgHkx2JIlYnpeeY64+HGJZjxOXB8ylecyPaJORSi4WS+DcuYu
    UFnE5b6cLBWVES8QaVlvGFvupbAnPsYzcW0khwpfNWy8qyzCxAcptpmDt4DQTp9R
    w6LAk0l7BWsJ0WIf2mSp2hdxzWK5G0lU0nTdym78D+yOW4GmxsDMdCNsA3GQSzBy
    mj2ReIcCAwEAAaOBnDCBmTAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYB
    BQUHAwEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUhHWEYa0tkQ5m1VgIGsOwL5t2
    TwcwHwYDVR0jBBgwFoAU8Co7f0NtrdYtqRvPr+498KJHgg4wJAYDVR0RBB0wG4IZ
    Ki5hcHBzLm9jcDQtMS5leGFtcGxlLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAKvuu
    FuOGHYoPLhXYNV9eRcQXNWi8u/OBT+qAbhZ6R1Bs1kf6oOv1lMJfWfYsWFVkvCsh
    1x4YQaMUNE4RYXrVToGRC8NCYL+bh001sQvSlIMy4F3ycU2LGoJAZlbgG62+21zT
    FtVjCQGmIXXgI5MzyM2RDByXH/reyOpKktHNqa0kQuewtvWPR2C472aLe4TBkfk3
    8Lg6Y7S7jmUh2kuP0hqvBEhCiAsFBKyNyqQqQqfPT7bVNey+EzY0jb+84O4xHXP6
    nnvpoICf8AruAM7gRFh6+S2rDFoE95BI7mL1n/d8iCFampT/yQwlKfzMwgYWbmZD
    7MyOC08sYXvDvwmyAA==
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIDDDCCAfSgAwIBAgIBATANBgkqhkiG9w0BAQsFADAmMSQwIgYDVQQDDBtpbmdy
    ZXNzLW9wZXJhdG9yQDE2NjMxNDIzODkwHhcNMjIwOTE0MDc1OTQ4WhcNMjQwOTEz
    MDc1OTQ5WjAmMSQwIgYDVQQDDBtpbmdyZXNzLW9wZXJhdG9yQDE2NjMxNDIzODkw
    ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDitWPpBHZd9KCK7l+JZfYt
    U6s1XfbRUvLh9PJ+hQ5buFQH7WW6vvfXkfQctNYKgKWmQ4wmbbKfP1aAYGkQkiy/
    UfarDr6MNMGW3yS3KNhRGtGy7KBv29/sTBWJYRt6taOcu8x8L3Yc3Yj1+rPAkCuE
    tR933Q2R3PnNRRtJb1eo9kb0/QN2fbBAFuEDfEhdVasUgZ5su/bWaZET44/p2OZG
    GtvdI7ShE7PIQQJoC3P2yVOr85o4gHeTZ6K3c0sUtbPgx+wl5rNnfRIH5PSGcojR
    JkTTA0v8UziVTUPu+OQx1cbV1SxTEL3URcrODyhWJYlEGkJ0X19MEYzE/Qv96hjh
    AgMBAAGjRTBDMA4GA1UdDwEB/wQEAwICpDASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
    A1UdDgQWBBTwKjt/Q22t1i2pG8+v7j3wokeCDjANBgkqhkiG9w0BAQsFAAOCAQEA
    1ZQHXzmlL/3Bw1H3JpClHYzhfAZTZx+gmbDd6EC7xhJgkdjAx+JTSLf0fCH0GTaf
    GNKyCWKNRfTtB9jFvGXwmcps0WA0tOVY1Tbsf+/5BgV9af1d8GAnJSKHqlnZeEuj
    13RoVKGMA3la3XtysGVxoMSK5LrtmYc//cjBGb4lTO0/XaLi+E5S+Pu8Ufs6hREB
    Gp36N+hByqv/I1oM6/F2V8ayl65G+lhPAOSGyd5etKKVU4HQnTUqaw7qD/c5Wrin
    tE6FJApsbqoJ4r86HIJEEnAOJAUzb4kPa85h4VmKrEYeRm6idx7LuvJ9cg8H4fVh
    wKVBAtH4TPrKz5hnjCxztA==
    -----END CERTIFICATE-----

# 将这部分内容添加到 openshift-config namespace 下的 configmap user-ca-bundle 里
$ oc -n openshift-config edit configmap user-ca-bundle

# 添加 proxy.config.openshift.io/cluster 的 spec.trustedCA 
$ oc patch proxy.config.openshift.io/cluster -p '{"spec":{"trustedCA":{"name":"user-ca-bundle"}}}'  --type=merge

# 更新 clusterversion/version 的 spec.upstream
$ NAMESPACE=openshift-update-service
$ NAME=update-service-oc-mirror
$ POLICY_ENGINE_GRAPH_URI="$(oc -n "${NAMESPACE}" get -o jsonpath='{.status.policyEngineURI}/api/upgrades_info/v1/graph{"\n"}' updateservice "${NAME}")"
$ PATCH="{\"spec\":{\"upstream\":\"${POLICY_ENGINE_GRAPH_URI}\"}}"
$ oc patch clusterversion version -p $PATCH --type merge

# (如果想改回去的话) 改回默认的 GRAPH_URL
$ POLICY_ENGINE_GRAPH_URI="https://api.openshift.com/api/upgrades_info/v1/graph"
$ PATCH="{\"spec\":{\"upstream\":\"${POLICY_ENGINE_GRAPH_URI}\"}}"
$ oc patch clusterversion version -p $PATCH --type merge

# 查看 clusterversion 对象
$ oc get clusterversion version -o yaml 

# 如果上述命令输出无报错，这个时候就可以在界面执行更新了
```

```
# 查看 channel upgrades graph 
$ curl -s "https://api.openshift.com/api/upgrades_info/v1/graph?channel=stable-4.10" | jq -r 
$ curl -s "https://update-service-oc-mirror-route-openshift-update-service.apps.ocp4-1.example.com/api/upgrades_info/v1/graph?channel=fast-4.10"

# 查看本地 release info 
$ oc adm release info registry.example.com:5000/openshift/release-images:4.10.30-x86_64
$ oc adm release info registry.example.com:5000/openshift/release-images:4.10.31-x86_64

# 通过命令更新
# oc adm upgrade —allow-explicit-upgrade —to-image registry.example.com:5000/openshift/release-images@sha256:<sha>
$ oc adm upgrade —allow-explicit-upgrade —to-image registry.example.com:5000/openshift/release-images@sha256:86f3b85645c613dc4a79d04c28b9bbd3519745f0862e30275acceadcbc409b42

### 拷贝 realtime 虚拟机磁盘到离线环境
$ mkdir -p /tmp/skopeotest 
$ skopeo copy --format v2s2 --authfile /path/auth.json --all docker://quay.io/jordigilh/rhel8-rt:qcow2 dir:/tmp/skopeotest 
### 将 /tmp/skopeotest 拷贝到离线
$ skopeo copy --format v2s2 --authfile /path/auth.json --all dir:/tmp/skopeotest docker://registry.example.com:5000/jordigilh/rhel8-rt:qcow2


$ cd /tmp
$ /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10 --package=advanced-cluster-management
NAME                         DISPLAY NAME                                DEFAULT CHANNEL
advanced-cluster-management  Advanced Cluster Management for Kubernetes  release-2.6

PACKAGE                      CHANNEL      HEAD
advanced-cluster-management  release-2.4  advanced-cluster-management.v2.4.5
advanced-cluster-management  release-2.5  advanced-cluster-management.v2.5.2
advanced-cluster-management  release-2.6  advanced-cluster-management.v2.6.1
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.10
      packages:
        - name: advanced-cluster-management
          channels:
            - name: release-2.6
              minVersion: 'v2.6.1'
              maxVersion: 'v2.6.1'                              
            - name: release-2.4
              minVersion: 'v2.4.5'
              maxVersion: 'v2.4.5'
EOF

$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml --continue-on-error file://output-dir 2>&1 | tee /tmp/err 


### 获取 odf-lvm-operator 
$ /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10 --package=odf-lvm-operator
PACKAGE           CHANNEL      HEAD
odf-lvm-operator  stable-4.10  odf-lvm-operator.v4.10.6
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.10
      packages:
        - name: odf-lvm-operator
          channels:
            - name: stable-4.10
              minVersion: 'v4.10.6'
              maxVersion: 'v4.10.6'
EOF

$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml --continue-on-error file://output-dir 2>&1 | tee /tmp/err 


### 这种方法同步镜像，在目标上传镜像会报
### uploading: registry.example.com:5000/kubevirt/hostpath-provisioner sha256:1718b0b7de8d2e193728b50312d98a1cab1efe401a14caf8ebaa701dd38e2c33 45.55MiB
### error: unable to push manifest to registry.example.com:5000/kubevirt/hostpath-provisioner: manifest invalid: manifest invalid
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: quay.io/kubevirt/hostpath-provisioner:latest
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml --continue-on-error file://output-dir 2>&1 | tee /tmp/err 


$ mkdir -p /tmp/skopeotest 
$ skopeo copy --format v2s2 --authfile /path/auth.json --all docker://quay.io/kubevirt/hostpath-provisioner dir:/tmp/skopeotest 
### 将 /tmp/skopeotest 拷贝到离线
$ skopeo copy --format v2s2 --authfile /path/auth.json --all dir:/tmp/skopeotest docker://registry.example.com:5000/kubevirt/hostpath-provisioner

$ mkdir -p /tmp/minio 
$ skopeo copy --format v2s2 --authfile /path/auth.json --all docker://docker.io/minio/minio:RELEASE.2022-07-24T01-54-52Z dir:/tmp/minio 
### 将 /tmp/skopeotest 拷贝到离线
$ skopeo copy --format v2s2 --authfile /path/auth.json --all dir:/tmp/minio docker://registry.example.com:5000/minio/minio:RELEASE.2022-07-24T01-54-52Z

# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-docker.html
$ mkdir -p /tmp/mc 
$ skopeo copy --format v2s2 --authfile /path/auth.json --all docker://docker.io/minio/mc:RELEASE.2022-07-24T02-25-13Z dir:/tmp/mc 
### 将 /tmp/skopeotest 拷贝到离线
$ skopeo copy --format v2s2 --authfile /path/auth.json --all dir:/tmp/mc docker://registry.example.com:5000/minio/mc:RELEASE.2022-07-24T02-25-13Z

$ mkdir -p /tmp/amazon
$ skopeo copy --format v2s2 --all docker://docker.io/amazon/aws-cli:latest dir:/tmp/amazon
$ tar cf /tmp/awscli.tar /tmp/amazon
$ scp /tmp/awscli.tar <dest>:/tmp
$ tar xf /tmp/awscli.tar -C /
$ skopeo copy --format v2s2 --all dir:/tmp/amazon docker://registry.example.com:5000/amazon/aws-cli:latest

### 新的思路是把 openshift release images 的同步与 operator 的同步分成两个阶段做
### 
### 第一阶段
### 同步 openshift/release
### 生成 image-config-release-local.yaml
### 不保存 metadata
### 不使用 archiveSize
### 不使用 storageConfig
### 20221010
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
      - name: fast-4.11
        minVersion: 4.10.30
        maxVersion: 4.11.5
        shortestPath: true
    graph: true # Include Cincinnati upgrade graph image in imageset
EOF

# 同步 openshift/release images 到本地
# 检查输出，处理所有错误
$ /usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml --continue-on-error file://output-dir

# 拷贝 output-dir/mirror_seq1_000000.tar 到离线环境

# 上传镜像
$ /usr/local/bin/oc-mirror --from /tmp/mirror_seq1_000000.tar docker://registry.example.com:5000 --continue-on-error

# 如果没有报错，就可以 apply imageContentSourcePolicy.yaml, updateService.yaml 和 release-signatures
$ pwd
/root/oc-mirror-workspace
$ tree results-1665368269 
results-1665368269
├── charts
├── imageContentSourcePolicy.yaml
├── mapping.txt
├── release-signatures
│   ├── signature-sha256-7f543788330d4866.json
│   └── signature-sha256-fe4d499ac9fc7d12.json
└── updateService.yaml
$ cd results-1665368269
$ oc apply -f imageContentSourcePolicy.yaml
$ oc project openshift-update-service
$ oc apply -f updateService.yaml
$ oc apply -f release-signatures/signature-sha256-7f543788330d4866.json
$ oc apply -f release-signatures/signature-sha256-fe4d499ac9fc7d12.json

### 第二阶段
### 同步 operator
### 生成 image-config-release-local.yaml
### 不保存 metadata
### 不使用 archiveSize
### 不使用 storageConfig
### 20221010
### 检查 operator 的情况
### for packagename in kubevirt-hyperconverged performance-addon-operator kubernetes-nmstate-operator sriov-network-operator local-storage-operator odf-operator cincinnati-operator advanced-cluster-management openshift-gitops-operator odf-lvm-operator multicluster-engine rhacs-operator ansible-automation-platform-operator nfd node-healthcheck-operator metallb-operator sandboxed-containers-operator 
### do 
###  /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.10 --package=${packagename}
### done

### 同步 operator 
### catalog 是 registry.redhat.io/redhat/redhat-operator-index:v4.10
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.10
      packages:
        - name: kubevirt-hyperconverged
          channels:
            - name: 'stable'
              minVersion: 'v4.10.6'
              maxVersion: 'v4.10.6'            
        - name: performance-addon-operator
          channels:
            - name: '4.10'
              minVersion: 'v4.10.9'
              maxVersion: 'v4.10.9'
        - name: kubernetes-nmstate-operator
          channels:
            - name: 'stable'
              minVersion: '4.10.0-202210211005'
              maxVersion: '4.10.0-202210211005'
            - name: '4.10'
              minVersion: '4.10.0-202210211005'
              maxVersion: '4.10.0-202210211005'              
        - name: sriov-network-operator
          channels:
            - name: 'stable'
              minVersion: '4.10.0-202210250828'
              maxVersion: '4.10.0-202210250828'
            - name: '4.10'
              minVersion: '4.10.0-202210250828'
              maxVersion: '4.10.0-202210250828'              
        - name: local-storage-operator
          channels:
            - name: 'stable'
              minVersion: '4.10.0-202210211005'
              maxVersion: '4.10.0-202210211005'
            - name: '4.10'
              minVersion: '4.10.0-202210211005'
              maxVersion: '4.10.0-202210211005'              
        - name: odf-operator
          channels:
            - name: 'stable-4.10'
              minVersion: 'v4.10.7'
              maxVersion: 'v4.10.7'
            - name: 'stable-4.9'
              minVersion: 'v4.9.11'
              maxVersion: 'v4.9.11'
        - name: cincinnati-operator
          channels:
            - name: v1
              minVersion: 'v5.0.0'
              maxVersion: 'v5.0.0'
        - name: advanced-cluster-management
          channels:
            - name: release-2.6
              minVersion: 'v2.6.2'
              maxVersion: 'v2.6.2'
            - name: release-2.5
              minVersion: 'v2.5.4'
              maxVersion: 'v2.5.4'
            - name: release-2.4
              minVersion: 'v2.4.8'
              maxVersion: 'v2.4.8'             
        - name: openshift-gitops-operator
          channels:
            - name: latest
              minVersion: 'v1.6.2'
              maxVersion: 'v1.6.2'
            - name: stable
              minVersion: 'v1.5.7'
              maxVersion: 'v1.5.7'
        - name: odf-lvm-operator
          channels:
            - name: stable-4.10
              minVersion: 'v4.10.7'
              maxVersion: 'v4.10.7'
        - name: multicluster-engine
          channels:
            - name: stable-2.1
              minVersion: 'v2.1.2'
              maxVersion: 'v2.1.2'
            - name: stable-2.0
              minVersion: 'v2.0.4'
              maxVersion: 'v2.0.4'
        - name: rhacs-operator
          channels:
            - name: latest
              minVersion: 'v3.72.1'
              maxVersion: 'v3.72.1'
        - name: ansible-automation-platform-operator
          channels:
            - name: stable-2.2-cluster-scoped
              minVersion: 'v2.2.1-0.1667857587'
              maxVersion: 'v2.2.1-0.1667857587'
            - name: stable-2.1-cluster-scoped
              minVersion: 'v2.1.3-0.1667853004'
              maxVersion: 'v2.1.3-0.1667853004'
        - name: nfd
          channels:
            - name: stable
              minVersion: '4.10.0-202210211005'
              maxVersion: '4.10.0-202210211005'
        - name: node-healthcheck-operator
          channels:
            - name: candidate
              minVersion: 'v0.2.0'
              maxVersion: 'v0.2.0'
        - name: metallb-operator
          channels:
            - name: stable
              minVersion: '4.10.0-202210211005'
              maxVersion: '4.10.0-202210211005'
        - name: sandboxed-containers-operator
          channels:
            - name: stable-1.3
              minVersion: 'v1.3.1'
              maxVersion: 'v1.3.1'
EOF

# 同步 operator 到本地
# 检查输出，处理所有错误
# https://www.ibm.com/docs/en/cloud-paks/cp-management/2.1.x?topic=installation-preparing-by-using-portable-compute-device
# 根据上面链接里的提示：如果出现 'connect reset by peer' 的消息，需要重新执行同步
$ /usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir


```

```
# 同步 minio 镜像
mkdir -p /tmp/minio
skopeo copy --format v2s2 --all docker://docker.io/minio/minio:RELEASE.2022-07-24T01-54-52Z dir:/tmp/minio/minio
skopeo copy --format v2s2 --all docker://docker.io/minio/mc:RELEASE.2022-07-24T02-25-13Z dir:/tmp/minio/mc

tar cf /tmp/minio-images.tar /tmp/minio
scp /tmp/minio-images.tar <dst>:/tmp
tar xf /tmp/minio-images.tar -C /

skopeo copy --format v2s2 --all dir:/tmp/minio/minio docker://registry.example.com:5000/minio/minio:RELEASE.2022-07-24T01-54-52Z
skopeo copy --format v2s2 --all dir:/tmp/minio/mc docker://registry.example.com:5000/minio/mc:RELEASE.2022-07-24T02-25-13Z

### 试试同步 microshift images
### 参考: https://github.com/openshift/oc-mirror/blob/main/docs/imageset-config-ref.yaml
### yum list all | grep microshift
### Repository fast-datapath-for-rhel-8-x86_64-rpms is listed more than once in the configuration
### microshift.x86_64                                      4.12.0-4.10.0_0.microshift_2022_09_08_132255_192_gcad04270.el8 @@commandline                        
### microshift-networking.x86_64                           4.12.0-4.10.0_0.microshift_2022_09_08_132255_192_gcad04270.el8 @@commandline                        
### microshift-selinux.noarch                              4.12.0-4.10.0_0.microshift_2022_09_08_132255_192_gcad04270.el8 @@commandline       
cd /tmp
cat > imageset-config.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: quay.io/microshift/ovn-kubernetes-singlenode@sha256:e97d6035754fad1660b522b8afa4dea2502d5189c8490832e762ae2afb4cf142
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:4d182d11a30e6c3c1420502bec5b1192c43c32977060c4def96ea160172f71e7
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:72c751aa148bf498839e6f37b304e3265f85af1e00578e637332a13ed9545ece
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:afcc1f59015b394e6da7d73eba32de407807da45018e3c4ecc25e5741aaae2dd
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:dd49360368f93bbe1a11b8d1ce6f0f98eeb0c9230d9801a2b08a714a92e1f655
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:e5f97df4705b6f3a222491197000b887d541e9f3a440a7456f94c82523193760
    - name: registry.access.redhat.com/ubi8/openssl@sha256:8b41865d30b7947de68a9c1747616bce4efab4f60f68f8b7016cd84d7708af6b
    - name: registry.redhat.io/odf4/odf-topolvm-rhel8@sha256:362c41177d086fc7c8d4fa4ac3bbedb18b1902e950feead9219ea59d1ad0e7ad
    - name: registry.redhat.io/openshift4/ose-csi-external-provisioner@sha256:4b7d8035055a867b14265495bd2787db608b9ff39ed4e6f65ff24488a2e488d2
    - name: registry.redhat.io/openshift4/ose-csi-external-resizer@sha256:ca34c46c4a4c1a4462b8aa89d1dbb5427114da098517954895ff797146392898
    - name: registry.redhat.io/openshift4/ose-csi-livenessprobe@sha256:e4b0f6c89a12d26babdc2feae7d13d3f281ac4d38c24614c13c230b4a29ec56e
    - name: registry.redhat.io/openshift4/ose-csi-node-driver-registrar@sha256:3babcf219371017d92f8bc3301de6c63681fcfaa8c344ec7891c8e84f31420eb
    - name: registry.k8s.io/pause:3.6
EOF
/usr/local/bin/oc-mirror --config ./imageset-config.yaml file://output-dir
scp output-dir/mirror_seq1_000000.tar <dst>:/tmp
/usr/local/bin/oc-mirror --from /tmp/mirror_seq1_000000.tar docker://registry.example.com:5000

# 这个镜像会报有错
# 尝试取消这个镜像
#     - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:afcc1f59015b394e6da7d73eba32de407807da45018e3c4ecc25e5741aaae2dd

cat > imageset-config.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: quay.io/microshift/ovn-kubernetes-singlenode@sha256:e97d6035754fad1660b522b8afa4dea2502d5189c8490832e762ae2afb4cf142
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:4d182d11a30e6c3c1420502bec5b1192c43c32977060c4def96ea160172f71e7
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:72c751aa148bf498839e6f37b304e3265f85af1e00578e637332a13ed9545ece
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:dd49360368f93bbe1a11b8d1ce6f0f98eeb0c9230d9801a2b08a714a92e1f655
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:e5f97df4705b6f3a222491197000b887d541e9f3a440a7456f94c82523193760
    - name: registry.access.redhat.com/ubi8/openssl@sha256:8b41865d30b7947de68a9c1747616bce4efab4f60f68f8b7016cd84d7708af6b
    - name: registry.redhat.io/odf4/odf-topolvm-rhel8@sha256:362c41177d086fc7c8d4fa4ac3bbedb18b1902e950feead9219ea59d1ad0e7ad
    - name: registry.redhat.io/openshift4/ose-csi-external-provisioner@sha256:4b7d8035055a867b14265495bd2787db608b9ff39ed4e6f65ff24488a2e488d2
    - name: registry.redhat.io/openshift4/ose-csi-external-resizer@sha256:ca34c46c4a4c1a4462b8aa89d1dbb5427114da098517954895ff797146392898
    - name: registry.redhat.io/openshift4/ose-csi-livenessprobe@sha256:e4b0f6c89a12d26babdc2feae7d13d3f281ac4d38c24614c13c230b4a29ec56e
    - name: registry.redhat.io/openshift4/ose-csi-node-driver-registrar@sha256:3babcf219371017d92f8bc3301de6c63681fcfaa8c344ec7891c8e84f31420eb
    - name: registry.k8s.io/pause:3.6
EOF
/usr/local/bin/oc-mirror --config ./imageset-config.yaml file://output-dir

# 再尝试同步 quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:e5f97df4705b6f3a222491197000b887d541e9f3a440a7456f94c82523193760
cat > imageset-config.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:e5f97df4705b6f3a222491197000b887d541e9f3a440a7456f94c82523193760
EOF
/usr/local/bin/oc-mirror --config ./imageset-config.yaml file://output-dir

# 再尝试同步 quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:dd49360368f93bbe1a11b8d1ce6f0f98eeb0c9230d9801a2b08a714a92e1f655
cat > imageset-config.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:dd49360368f93bbe1a11b8d1ce6f0f98eeb0c9230d9801a2b08a714a92e1f655
EOF
/usr/local/bin/oc-mirror --config ./imageset-config.yaml file://output-dir

# 尝试同步 demo vm image 
# Operator 已经用 oc-mirror 的手段同步到离线 registry 里了
# docker.io/kubevirt/cirros-registry-disk-demo:latest
# docker.io/kubevirt/fedora-cloud-registry-disk-demo:latest
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: docker.io/kubevirt/cirros-registry-disk-demo:latest
    - name: docker.io/kubevirt/fedora-cloud-registry-disk-demo:latest
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
# 拷贝 output-dir/mirror_seq1_000000.tar 到离线环境并上传到离线 registry
$ /usr/local/bin/oc-mirror --from /tmp/mirror_seq1_000000.tar docker://registry.example.com:5000

# 尝试同步 hypershift-client 
# quay.io/openshifttest/hypershift-client:latest
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: quay.io/openshifttest/hypershift-client:latest
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
# 拷贝 output-dir/mirror_seq1_000000.tar 到离线环境并上传到离线 registry
$ /usr/local/bin/oc-mirror --from /tmp/mirror_seq1_000000.tar docker://registry.example.com:5000

# 尝试同步 hypershift-operator
# quay.io/hypershift/hypershift-operator:latest
# quay.io/hypershift/hypershift-operator:4.11
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: quay.io/hypershift/hypershift-operator:latest
    - name: quay.io/hypershift/hypershift-operator:4.11
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
# 拷贝 output-dir/mirror_seq1_000000.tar 到离线环境并上传到离线 registry
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000

# 同步一下 4.11 release image
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
      - name: stable-4.11
        minVersion: 4.11.5
        maxVersion: 4.11.13
        shortestPath: true
    graph: true # Include Cincinnati upgrade graph image in imageset
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
# 拷贝 output-dir/mirror_seq1_000000.tar 到离线环境并上传到离线 registry
$ /usr/local/bin/oc-mirror --from /tmp/mirror_seq1_000000.tar docker://registry.example.com:5000


### 检查 operator 的情况
### for packagename in kubevirt-hyperconverged performance-addon-operator kubernetes-nmstate-operator sriov-network-operator local-storage-operator odf-operator ocs-operator mcg-operator cincinnati-operator advanced-cluster-management openshift-gitops-operator odf-lvm-operator multicluster-engine rhacs-operator ansible-automation-platform-operator nfd node-healthcheck-operator metallb-operator sandboxed-containers-operator openshift-special-resource-operator web-terminal
### do 
###  /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.11 --package=${packagename}
### done
### 同步 operator 
### catalog 是 registry.redhat.io/redhat/redhat-operator-index:v4.11
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.11
      packages:
        - name: kubevirt-hyperconverged
          channels:
            - name: 'stable'
              minVersion: 'v4.11.0'
              maxVersion: 'v4.11.0'            
        - name: kubernetes-nmstate-operator
          channels:
            - name: 'stable'
              minVersion: '4.11.0-202211032036'
              maxVersion: '4.11.0-202211032036'              
        - name: sriov-network-operator
          channels:
            - name: 'stable'
              minVersion: '4.11.0-202211072116'
              maxVersion: '4.11.0-202211072116'            
        - name: local-storage-operator
          channels:
            - name: 'stable'
              minVersion: '4.11.0-202211072116'
              maxVersion: '4.11.0-202211072116'            
        - name: odf-operator
          channels:
            - name: 'stable-4.11'
              minVersion: 'v4.11.3'
              maxVersion: 'v4.11.3'
        - name: ocs-operator
          channels:
            - name: 'stable-4.11'
              minVersion: 'v4.11.3'
              maxVersion: 'v4.11.3'
        - name: mcg-operator
          channels:
            - name: 'stable-4.11'
              minVersion: 'v4.11.3'
              maxVersion: 'v4.11.3'              
        - name: cincinnati-operator
          channels:
            - name: v1
              minVersion: 'v5.0.0'
              maxVersion: 'v5.0.0'
        - name: advanced-cluster-management
          channels:
            - name: release-2.6
              minVersion: 'v2.6.2'
              maxVersion: 'v2.6.2'         
        - name: openshift-gitops-operator
          channels:
            - name: latest
              minVersion: 'v1.6.2'
              maxVersion: 'v1.6.2'
        - name: odf-lvm-operator
          channels:
            - name: stable-4.11
              minVersion: 'v4.11.3'
              maxVersion: 'v4.11.3'
        - name: multicluster-engine
          channels:
            - name: stable-2.1
              minVersion: 'v2.1.2'
              maxVersion: 'v2.1.2'
        - name: rhacs-operator
          channels:
            - name: latest
              minVersion: 'v3.72.1'
              maxVersion: 'v3.72.1'
        - name: ansible-automation-platform-operator
          channels:
            - name: stable-2.2-cluster-scoped
              minVersion: 'v2.2.1-0.1668659261'
              maxVersion: 'v2.2.1-0.1668659261'
        - name: nfd
          channels:
            - name: stable
              minVersion: '4.11.0-202211072116'
              maxVersion: '4.11.0-202211072116'
        - name: node-healthcheck-operator
          channels:
            - name: stable
              minVersion: 'v0.3.1'
              maxVersion: 'v0.3.1'
        - name: metallb-operator
          channels:
            - name: stable
              minVersion: '4.11.0-202211072116'
              maxVersion: '4.11.0-202211072116'
        - name: sandboxed-containers-operator
          channels:
            - name: stable-1.3
              minVersion: 'v1.3.1'
              maxVersion: 'v1.3.1'
        - name: openshift-special-resource-operator
          channels:
            - name: stable
              minVersion: '4.11.0-202211072116'
              maxVersion: '4.11.0-202211072116'
        - name: web-terminal
          channels:
            - name: fast
              minVersion: 'v1.6.0'
              maxVersion: 'v1.6.0'
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
# 拷贝 output-dir/mirror_seq1_000000.tar 到离线环境并上传到离线 registry
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000

# 同步一下 4.12 release image
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
      - name: candidate-4.12
        minVersion: 4.11.5
        maxVersion: 4.12.2
        shortestPath: true
    graph: true # Include Cincinnati upgrade graph image in imageset
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
# 拷贝 output-dir/mirror_seq1_000000.tar 到离线环境并上传到离线 registry
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000


### 检查 operator 的情况
### for packagename in kubevirt-hyperconverged performance-addon-operator kubernetes-nmstate-operator sriov-network-operator local-storage-operator odf-operator cincinnati-operator advanced-cluster-management openshift-gitops-operator lvms-operator multicluster-engine rhacs-operator ansible-automation-platform-operator nfd node-healthcheck-operator metallb-operator sandboxed-containers-operator openshift-special-resource-operator  lvms-operator ocs-operator mcg-operator web-terminal openshift-pipelines-operator-rh devworkspace-operator web-terminal rhods-operator rhods-prometheus-operator nfd
### do 
###  /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.12 --package=${packagename}
### done
### 同步 operator 
### catalog 是 registry.redhat.io/redhat/redhat-operator-index:v4.12
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.12
      packages:
      packages:
        - name: kubevirt-hyperconverged
          channels:
            - name: 'stable'
              minVersion: 'v4.12.3'
              maxVersion: 'v4.12.3'            
        - name: kubernetes-nmstate-operator
          channels:
            - name: 'stable'
              minVersion: '4.12.0-202305101515'
              maxVersion: '4.12.0-202305101515'              
        - name: sriov-network-operator
          channels:
            - name: 'stable'
              minVersion: 'v4.12.0-202305101515'
              maxVersion: 'v4.12.0-202305101515'            
        - name: local-storage-operator
          channels:
            - name: 'stable'
              minVersion: 'v4.12.0-202305101515'
              maxVersion: 'v4.12.0-202305101515'            
        - name: odf-operator
          channels:
            - name: 'stable-4.12'
              minVersion: 'v4.12.3-rhodf'
              maxVersion: 'v4.12.3-rhodf'
        - name: ocs-operator
          channels:
            - name: 'stable-4.12'
              minVersion: 'v4.12.3-rhodf'
              maxVersion: 'v4.12.3-rhodf'
        - name: mcg-operator
          channels:
            - name: 'stable-4.12'
              minVersion: 'v4.12.3-rhodf'
              maxVersion: 'v4.12.3-rhodf'              
        - name: cincinnati-operator
          channels:
            - name: v1
              minVersion: 'v5.0.1'
              maxVersion: 'v5.0.1'
        - name: advanced-cluster-management
          channels:
            - name: release-2.7
              minVersion: 'v2.7.4'
              maxVersion: 'v2.7.4'         
        - name: openshift-gitops-operator
          channels:
            - name: latest
              minVersion: 'v1.8.3'
              maxVersion: 'v1.8.3'
        - name: lvms-operator
          channels:
            - name: stable-4.12
              minVersion: 'v4.12.1'
              maxVersion: 'v4.12.1'
        - name: multicluster-engine
          channels:
            - name: stable-2.2
              minVersion: 'v2.2.4'
              maxVersion: 'v2.2.4'
        - name: rhacs-operator
          channels:
            - name: stable
              minVersion: 'v4.0.1'
              maxVersion: 'v4.0.1'
        - name: ansible-automation-platform-operator
          channels:
            - name: stable-2.3-cluster-scoped
              minVersion: 'v2.3.0-0.1683301174'
              maxVersion: 'v2.3.0-0.1683301174'
        - name: nfd
          channels:
            - name: stable
              minVersion: '4.12.0-202305101515'
              maxVersion: '4.12.0-202305101515'
        - name: node-healthcheck-operator
          channels:
            - name: stable
              minVersion: 'v0.5.0'
              maxVersion: 'v0.5.0'
        - name: metallb-operator
          channels:
            - name: stable
              minVersion: '4.12.0-202305102015'
              maxVersion: '4.12.0-202305102015'
        - name: sandboxed-containers-operator
          channels:
            - name: stable-1.3
              minVersion: 'v1.3.3'
              maxVersion: 'v1.3.3'
        - name: openshift-pipelines-operator-rh
          channels:
            - name: latest
              minVersion: 'v1.10.3'
              maxVersion: 'v1.10.3'
        - name: devworkspace-operator
          channels:
            - name: fast
              minVersion: 'v0.20.0'
              maxVersion: 'v0.20.0'
        - name: web-terminal
          channels:
            - name: fast
              minVersion: 'v1.7.0-0.1684429884.p'
              maxVersion: 'v1.7.0-0.1684429884.p'
        - name: rhods-operator
          channels:
            - name: stable
              minVersion: '1.26.0'
              maxVersion: '1.26.0'
        - name: rhods-prometheus-operator
          channels:
            - name: beta
              minVersion: '4.10.0'
              maxVersion: '4.10.0'
        - name: nfd
          channels:
            - name: stable
              minVersion: '4.12.0-202305101515'
              maxVersion: '4.12.0-202305101515'              
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee ./err 
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000

### 检查 operator 的情况
### for packagename in gpu-operator-certified 
### do 
###  /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/certified-operator-index:v4.12 --package=${packagename}
### done
### 同步 operator 
### catalog 是 registry.redhat.io/redhat/certified-operator-index:v4.12
$ mkdir -p ~/4.12/certified-operator-index
$ cd ~/4.12/certified-operator-index
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/certified-operator-index:v4.12
      packages:
        - name: gpu-operator-certified
          channels:
            - name: 'v23.3'
              minVersion: 'v23.3.2'
              maxVersion: 'v23.3.2'
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000


### 检查 operator 的情况
### for packagename in prometheus 
### do 
###  /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/community-operator-index:v4.12 --package=${packagename}
### done
### 同步 operator 
### catalog 是 registry.redhat.io/redhat/community-operator-index:v4.12
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000

$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/community-operator-index:v4.12
      packages:
        - name: prometheus
          channels:
            - name: 'beta'
              minVersion: '0.56.3'
              maxVersion: '0.56.3'
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000

### 检查 operator 的情况
### for packagename in openshift-pipelines-operator-rh 
### do 
###  /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/community-operator-index:v4.11 --package=${packagename}
### done
### 同步 operator 
### catalog 是 registry.redhat.io/redhat/community-operator-index:v4.11

$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/community-operator-index:v4.12
      packages:
        - name: prometheus
          channels:
            - name: 'beta'
              minVersion: '0.56.3'
              maxVersion: '0.56.3'
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000


### 检查 operator 的情况
### for packagename in gitlab-operator-kubernetes gitlab-runner-operator 
### do 
###  /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/community-operator-index:v4.11 --package=${packagename}
### done
### 同步 operator 
### catalog 是 registry.redhat.io/redhat/community-operator-index:v4.11
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/community-operator-index:v4.11
      packages:
        - name: gitlab-operator-kubernetes
          channels:
            - name: 'stable'
              minVersion: 'v0.17.3'
              maxVersion: 'v0.17.3'
        - name: gitlab-runner-operator
          channels:
            - name: 'stable'
              minVersion: 'v1.12.0'
              maxVersion: 'v1.12.0'
        - name: cert-manager
          channels:
            - name: 'stable'
              minVersion: 'v1.11.0'
              maxVersion: 'v1.11.0'              
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000


### 4.12 operator 离线时遇到的问题
### https://issues.redhat.com/projects/CLOUDDST/issues/CLOUDDST-17020?filter=allopenissues
# unsupported: Not Found, or unsupported. V2 schema 1 manifest digest are no longer supported for image pulls.


# 同步一下 4.12 release image
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
      - name: stable-4.12
        minVersion: 4.12.9
        maxVersion: 4.12.10
        shortestPath: true
    graph: true # Include Cincinnati upgrade graph image in imageset
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
# 拷贝 output-dir/mirror_seq1_000000.tar 到离线环境并上传到离线 registry
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000


#### 发哥用的同步OpenShift安装所需镜像到本地的命令
#### https://access.redhat.com/solutions/6976534
export OCP_RELEASE="4.11.4-x86_64"
export LOCAL_REGISTRY='registry.ocp-poc.v01.net:5000' 
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON='./pull-secret.json'
export RELEASE_NAME="ocp-release"
export GODEBUG=x509ignoreCN=0

oc adm -a ${LOCAL_SECRET_JSON} release mirror  --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE} --to-dir=./ocp-install
oc image mirror -a ${LOCAL_SECRET_JSON} --dir=./ocp-install file://openshift/release:4.11.4* ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}


# 同步一下 4.14 release image
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
      - name: stable-4.14
        minVersion: 4.14.3
        maxVersion: 4.14.3
        shortestPath: true
    graph: true # Include Cincinnati upgrade graph image in imageset
EOF

$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/err 
# 拷贝 output-dir/mirror_seq1_000000.tar 到离线环境并上传到离线 registry
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000



### 检查 operator 的情况
### for packagename in kubevirt-hyperconverged performance-addon-operator kubernetes-nmstate-operator sriov-network-operator local-storage-operator odf-operator cincinnati-operator advanced-cluster-management openshift-gitops-operator lvms-operator multicluster-engine rhacs-operator ansible-automation-platform-operator nfd node-healthcheck-operator metallb-operator sandboxed-containers-operator openshift-special-resource-operator  lvms-operator ocs-operator mcg-operator web-terminal openshift-pipelines-operator-rh devworkspace-operator web-terminal rhods-operator rhods-prometheus-operator nfd whereabouts
### do 
###  /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.12 --package=${packagename}
### done
### 同步 operator 
### catalog 是 registry.redhat.io/redhat/redhat-operator-index:v4.14
$ cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.14
      packages:
        - name: kubevirt-hyperconverged
          channels:
            - name: 'stable'
              minVersion: 'v4.14.0'
              maxVersion: 'v4.14.0'            
        - name: kubernetes-nmstate-operator
          channels:
            - name: 'stable'
              minVersion: '4.14.0-202311211133'
              maxVersion: '4.14.0-202311211133'                         
        - name: local-storage-operator
          channels:
            - name: 'stable'
              minVersion: 'v4.14.0-202311211133'
              maxVersion: 'v4.14.0-202311211133'            
        - name: odf-operator
          channels:
            - name: 'stable-4.14'
              minVersion: 'v4.14.0-rhodf'
              maxVersion: 'v4.14.0-rhodf'
        - name: ocs-operator
          channels:
            - name: 'stable-4.14'
              minVersion: 'v4.14.0-rhodf'
              maxVersion: 'v4.14.0-rhodf'
        - name: mcg-operator
          channels:
            - name: 'stable-4.14'
              minVersion: 'v4.14.0-rhodf'
              maxVersion: 'v4.14.0-rhodf'              
        - name: cincinnati-operator
          channels:
            - name: v1
              minVersion: 'v5.0.2'
              maxVersion: 'v5.0.2'
        - name: metallb-operator
          channels:
            - name: stable
              minVersion: 'v4.14.0-202311211133'
              maxVersion: 'v4.14.0-202311211133'
        - name: devworkspace-operator
          channels:
            - name: fast
              minVersion: 'v0.23.0'
              maxVersion: 'v0.23.0'
        - name: web-terminal
          channels:
            - name: fast
              minVersion: 'v1.8.0-0.1692219820.p'
              maxVersion: 'v1.8.0-0.1692219820.p'
        - name: advanced-cluster-management
          channels:
            - name: release-2.9
              minVersion: 'v2.9.0'
              maxVersion: 'v2.9.0'
        - name: multicluster-engine
          channels:
            - name: stable-2.3
              minVersion: 'v2.3.4'
              maxVersion: 'v2.3.4'
            - name: stable-2.4
              minVersion: 'v2.4.1'
              maxVersion: 'v2.4.1'
        - name: openshift-gitops-operator
          channels:
            - name: latest
              minVersion: 'v1.10.1'
              maxVersion: 'v1.10.1'
        - name: ansible-automation-platform-operator
          channels:
            - name: stable-2.4-cluster-scoped
              minVersion: 'v2.4.0-0.1700365194'
              maxVersion: 'v2.4.0-0.1700365194'
        - name: lvms-operator
          channels:
            - name: stable-4.14
              minVersion: 'v4.14.1'
              maxVersion: 'v4.14.1'
        - name: mtv-operator
          channels:
            - name: release-v2.5
              minVersion: 'v2.5.2'
              maxVersion: 'v2.5.2'
        - name: redhat-oadp-operator
          channels:
            - name: stable-1.3
              minVersion: 'v1.3.0'
              maxVersion: 'v1.3.0'
        - name: openshift-pipelines-operator-rh
          channels:
            - name: latest
              minVersion: 'v1.13.0'
              maxVersion: 'v1.13.0'
        - name: node-healthcheck-operator
          channels:
            - name: stable
              minVersion: 'v0.6.1'
              maxVersion: 'v0.6.1'
        - name: self-node-remediation
          channels:
            - name: stable
              minVersion: 'v0.7.1'
              maxVersion: 'v0.7.1'                
EOF

$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/oc-mirror 
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000

### 更新到最新的 oc-mirror 
### rhbk-operator    Keycloak Operator    stable-v22
### 然后查看 operator rhbk-oprator 的详细信息
for packagename in rhbk-operator 
do 
 /usr/local/bin/oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.14 --package=${packagename}
done
NAME           DISPLAY NAME       DEFAULT CHANNEL
rhbk-operator  Keycloak Operator  stable-v22

PACKAGE        CHANNEL     HEAD
rhbk-operator  stable-v22  rhbk-operator.v22.0.7-opr.1

### 同步 operator 
### catalog 是 registry.redhat.io/redhat/redhat-operator-index:v4.14
$ cd /tmp
$ cat > image-config-realse-local-jwang.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.14
      targetName: "jwang-catalog"
      targetTag: "4.14"
      packages:
        - name: rhbk-operator
          channels:
            - name: stable-v22
              minVersion: 'v22.0.7-opr.1'
              maxVersion: 'v22.0.7-opr.1'
EOF
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local-jwang.yaml file://output-dir 2>&1 | tee /tmp/oc-mirror-jwang
### 在目标环境里将mirror_seq1_000000.tar重命名为rhbk-mirror_seq1_000000.tar
$ /usr/local/bin/oc-mirror --from ./rhbk-mirror_seq1_000000.tar docker://registry.example.com:5000

# RHEL 7.x
$ podman run --name oc-mirror -d -t --network host -v /etc/pki/ca-trust/source/anchors/registry.crt:/etc/ssl/certs/registry.crt -v /root/.docker/config.json:/root/.docker/config.json -v .:/test --privileged registry.example.com:5000/codesys/oc-mirror:latest
$ podman exec -it oc-mirror /bin/bash
(oc-mirror)$ /oc-mirror --from /test/rhbk-mirror_seq1_000000.tar docker://registry.example.com:5000
...
Rendering catalog image "registry.example.com:5000/redhat/jwang-catalog:4.14" with file-based catalog 
...

```