https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/applications/managing-applications#git-SSH-connection
```
### 前面的步骤可以参见：https://github.com/wangjun1974/tips/blob/master/ocp/gitea.md

### 可以参考 https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/applications/managing-applications#insecure-http-server
### 配置 Channel 的 spec.insecureSkipVerify 为 true

# oc get Channel -A 
NAMESPACE                                                      NAME                                                        TYPE       PATHNAME                                                                                          AGE
ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor-ns   ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor   Git        https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/book-import.git   19m
open-cluster-management                                        acm-hive-openshift-releases-chn-0                           Git        https://github.com/stolostron/acm-hive-openshift-releases.git                                     40m
open-cluster-management                                        charts-v1                                                   HelmRepo   http://multiclusterhub-repo.open-cluster-management.svc.cluster.local:3000/charts                 51m

# 设置 Channel 的 spec.insecureSkipVerify 为 true
oc -n ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor-ns patch Channel ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor --type json -p '[{"op": "add", "path": "/spec/insecureSkipVerify", "value": true}]'
```

### 尝试一下 ACM 的 Argo CD ApplicationSet
```
# 安装 OpenShift GitOps Operator

# 创建 ManagedClusterSet
# Clusters -> Cluster sets -> Create cluster set -> clusterset1 -> Manage resource assignments

# 创建 ManagedClusterSetBinding
# namespace 选择 openshift-gitops
# Action -> Edit namespace bindings -> openshift-gitops

# 创建 Placement 'gitops-openshift-clusters'
# 在 namespace 'openshift-gitops' 下创建 Placement
# Placement 和 ManagedClusterSetBinding 需要在一个 namespace 下
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1alpha1
kind: Placement
metadata:
  name: gitops-openshift-clusters
  namespace: openshift-gitops
spec:
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchExpressions:
        - key: gitops
          operator: "In"
          values:
          - test
EOF

# 添加 gitea 证书到 Argo CD
# 获取 gitea 证书参见 https://github.com/wangjun1974/tips/blob/master/ocp/gitea.md
# Argo CD UI -> Settings -> Certificates -> ADD TLS CERTIFICATE

# 创建 GitOpsCluster CRDs，将 Placement 选择的 Cluster 注册到 ArgoCD cluster 里
# GitOpsCluster CRDs 的 version 为 v1beta1
# https://github.com/open-cluster-management/multicloud-integrations/blob/main/deploy/crds/apps.open-cluster-management.io_gitopsclusters.yaml#L19
# https://argocd-applicationset.readthedocs.io/en/stable/Template/
# argoServer 的 cluster 名称可以从 ArgoCD UI 的 Setting -> Cluster -> Name 处获得
cat << EOF | oc apply -f -
apiVersion: apps.open-cluster-management.io/v1beta1
kind: GitOpsCluster
metadata:
  name: argo-acm-clusters
  namespace: openshift-gitops
spec:
  argoServer:
    cluster: in-cluster
    argoNamespace: openshift-gitops
  placementRef:
    kind: Placement
    apiVersion: cluster.open-cluster-management.io/v1alpha1
    name: gitops-openshift-clusters
    namespace: openshift-gitops
EOF

# 手工为 local-cluster 添加 Lable: Name 'gitops' Value 'test'

# ACM UI 创建类型为 Argo CD ApplicationSet 的 Application
# Applications -> Create application -> Argo CD ApplicationSet -> Create Argo CD ApplicationSet
# Step1 - General -> Argo CD Application Set Name 'applicationset1' ; Argo Server 'openshift-gitops'
# Step2 - Template -> Repository Type 'Git' ; URL 'https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/book-import.git' ; Revision Type 'Branches' ; Revision 'master-no-pre-post' ; Path 'book-import' ; Remote namespace 'book-import'
# Step3 - Sync policy -> 根据需要选择 ; 未选择 'Replace resource instead ...', 'Disable kubectl validation', 'Prune properagation policy'
# Step4 - Placement -> 'Deployment application resource only on clusters matching specified labels', Cluster labels Lable 'gitops' Value 'test'
# 或者
# Step4 - Placement -> 'Select an existing placement configuration'; Placement resource 'gitops-openshift-clusters'
# Step5 - Review -> Create
```