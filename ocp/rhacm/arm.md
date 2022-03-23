### 添加 arm cluster 到 ACM Hub
```
### Hub

# 创建 arm-1 cluster
export CLUSTER_NAME=arm-1
oc --kubeconfig=<hub-kubeconfig> new-project ${CLUSTER_NAME}
oc --kubeconfig=<hub-kubeconfig> label namespace ${CLUSTER_NAME} cluster.open-cluster-management.io/managedCluster=${CLUSTER_NAME}

# 定义 KlusterletAddonConfig 和 ManagedCluster
cat <<EOF | oc --kubeconfig=<hub-kubeconfig> apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${CLUSTER_NAME}
  namespace: ${CLUSTER_NAME}
spec:
  clusterName: ${CLUSTER_NAME}
  clusterNamespace: ${CLUSTER_NAME}
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: true
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  iamPolicyController:
    enabled: true
  policyController:
    enabled: true
  searchCollector:
    enabled: true
  version: 2.2.0
EOF

cat <<EOF | oc --kubeconfig=<hub-kubeconfig> apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${CLUSTER_NAME}
spec:
  hubAcceptsClient: true
EOF

# 上面的命令在 ${CLUSTER_NAME} namespace 下生成 secret ${CLUSTER_NAME}-import 
# 导出 import.yaml 和 crds.yaml 
IMPORT=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.import\.yaml}')
CRDS=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.crds\.yaml}')

### 在 arm-1 cluster 创建 open-cluster-management-agent namespace，创建 serviceaccount，修改 imagePullSecrets
podman login registry.example.com:5000 --authfile=./auth.json
oc new-project open-cluster-management-agent
oc -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc -n open-cluster-management-agent create sa klusterlet
oc -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc -n open-cluster-management-agent create sa klusterlet-registration-sa
oc -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc -n open-cluster-management-agent create sa klusterlet-work-sa
oc -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

### 在 arm-1 创建 open-cluster-management-agent-addon namespace， 创建 serviceaccount，修改 imagePullSecrets
oc new-project open-cluster-management-agent-addon
oc -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
oc -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

### 在 arm-1 cluster 切换到 open-cluster-management-agent namespace
oc project open-cluster-management-agent
echo $CRDS | base64 -d | oc apply -f -
echo $IMPORT | base64 -d | oc apply -f -

### 在 arm-1 切换到 open-cluster-management-agent-addon namespace
oc project open-cluster-management-agent-addon
for sa in klusterlet-addon-appmgr klusterlet-addon-certpolicyctrl klusterlet-addon-iampolicyctrl-sa klusterlet-addon-policyctrl klusterlet-addon-search klusterlet-addon-workmgr ; do
  oc -n open-cluster-management-agent-addon patch sa $sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
done
oc delete pod --all -n open-cluster-management-agent-addon

# 拷贝镜像
# https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=80906
# brew.registry.redhat.io/rh-osbs/rhacm2-registration-rhel8-operator:v2.5.0-2
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/rhacm2-registration-rhel8-operator:v2.5.0-2 docker://quay.ocp4.rhcnsa.com/rh-osbs/rhacm2-registration-rhel8-operator:v2.5.0-2

skopeo inspect --authfile ./pull-secret-full.json docker://brew.registry.redhat.io/rh-osbs/rhacm2-registration-rhel8-operator:v2.5.0-2
skopeo inspect --authfile ./pull-secret-full.json docker://brew.registry.redhat.io/rh-osbs/rhacm2-registration-rhel8-operator:v2.5.0-2 | grep aarch64
...
        "rhacm-2.5-rhel-8-containers-candidate-76196-20220214035701-aarch64",

skopeo inspect --authfile ./pull-secret-full.json docker://brew.registry.redhat.io/rh-osbs/rhacm2-registration-rhel8-operator:rhacm-2.5-rhel-8-containers-candidate-76196-20220214035701-aarch64


skopeo inspect --authfile ./pull-secret-full.json docker://brew.registry.redhat.io/rh-osbs/multicluster-engine-registration-operator-rhel8:v2.0.0-13

skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/multicluster-engine-registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd docker://quay.ocp4.rhcnsa.com/rh-osbs/multicluster-engine-registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd

# 保存证书，把证书里的 -----BEGIN CERTIFICATE----- 到 -----END CERTIFICATE----- 之间的内容拷贝到
# /etc/pki/ca-trust/source/anchors/example-registry-quay-ocp4.crt 
openssl s_client -host example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com -port 443 -showcerts > trace < /dev/null

# 拷贝 3 个镜像
# https://brewweb.engineering.redhat.com/brew/buildinfo?buildID=1937154
# multicluster-engine/registration-operator-rhel8
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd docker://example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd

skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd docker://example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8:2.0.0-61

skopeo copy --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd docker://example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8:2.0.0-61

podman pull example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8:2.0.0-61

skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-operator-rhel8:2.0.0-61 docker://example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8:2.0.0-61


skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd

skopeo inspect --authfile ${LOCAL_SECRET_JSON} docker://example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd

# 
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-rhel8@sha256:1d5d6418ccd87be4122cf74de81071b84ccbd4bb99124cce1db957518bbce65d docker://quay.ocp4.rhcnsa.com/rh-osbs/multicluster-engine-registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd
multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd
```