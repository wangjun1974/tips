### 尝试一下 RHACM 与 GitOps
https://redhat.highspot.com/items/611ec26b628ba209d8ecfa20#13
```

```

### 尝试一下 RHACM 与 ArgoCD 
参考：https://rcarrata.com/openshift/argo-and-acm/
```
下载 kubeconfig
oc -n openshift-kube-apiserver extract secret/node-kubeconfigs

0. 安装 kustomize

1. 在 ACM Hub Cluster 安装 Red Hat GitOps Operator

2. 
git clone https://github.com/RedHat-EMEA-SSA-Team/ns-gitops
cd ns-gitops
git checkout bootstrap

3. bootstrap gitops 
until oc apply -k bootstrap/ ; do sleep 2; done

4. 添加 ManagedClusterSet

cat << EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ManagedClusterSet
metadata:
  name: gitosp-openshift-clusters
  spec: {}
EOF

5. 设置 ManagedClusterSetBinding 将 ManagedClusterSet 与 namespace 绑定起来
cat << EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ManagedClusterSetBinding
metadata:
  name: gitops-openshift-clusters
  namespace: openshift-gitops
spec:
  clusterSet: gitops-openshift-clusters
EOF

6. 设置 Placement CRDs，ManagedClusterSet 选择 Cluster时 只选择 verdor 是 OpenShift 的 Cluster
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
        - key: vendor
          operator: "In"
          values:
          - OpenShift
EOF

7. 创建 GitOpsCluster CRDs，将 Placement 选择的 Cluster 注册到 ArgoCD cluster local-cluster 里
# GitOpsCluster CRDs 的 version 为 v1beta1
# https://github.com/open-cluster-management/multicloud-integrations/blob/main/deploy/crds/apps.open-cluster-management.io_gitopsclusters.yaml#L19
# https://argocd-applicationset.readthedocs.io/en/stable/Template/
cat << EOF | oc apply -f -
apiVersion: apps.open-cluster-management.io/v1beta1
kind: GitOpsCluster
metadata:
  name: argo-acm-clusters
  namespace: openshift-gitops
spec:
  argoServer:
    cluster: local-cluster
    argoNamespace: openshift-gitops
  placementRef:
    kind: Placement
    apiVersion: cluster.open-cluster-management.io/v1alpha1
    name: gitops-openshift-clusters
    namespace: openshift-gitops
EOF

### 在 ACM Hub 部署 ArgoCD/OpenShift GitOps ApplicationSets
# https://github.com/argoproj-labs/applicationset/issues/71
1. 
cat <<'EOF' | oc apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: acm-appsets
  namespace: openshift-gitops
spec:
  generators:
    - clusterDecisionResource:
        configMapRef: acm-placement
        labelSelector:
          matchLabels:
            cluster.open-cluster-management.io/placement: gitops-openshift-clusters
        requeueAfterSeconds: 180
  template:
    metadata:
      name: 'acm-appsets-{{cluster}}'
    spec:
      destination:
        namespace: bgdk
        server: ''
      project: default
      source:
        path: apps/bgd/overlays/bgdk
        repoURL: 'https://github.com/RedHat-EMEA-SSA-Team/ns-apps/'
        targetRevision: single-app
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
EOF

报错
在 openshift-gitops 下的 Pod openshift-gitops-applicationset-controller-5cc6fb7fd4-56l5f 的日志里有如下报错
	/remote-source/deps/gomod/pkg/mod/sigs.k8s.io/controller-runtime@v0.9.0/pkg/internal/controller/controller.go:214
time="2022-01-29T07:58:33Z" level=info msg="Kind.Group/Version Reference" kind.apiVersion=placementdecisions.cluster.open-cluster-management.io/v1alpha1
time="2022-01-29T07:58:33Z" level=info msg="selection type" listOptions.LabelSelector="cluster.open-cluster-management.io/placement=acm-appsets-placement"
time="2022-01-29T07:58:33Z" level=warning msg="no resource found, make sure you clusterDecisionResource is defined correctly"
time="2022-01-29T07:58:33Z" level=error msg="error generating params" error="no clusterDecisionResources found" generator="&{0xc00012a000 0xc000010060 0xc000bd91e0 openshift-gitops 0xc00096d290}"
time="2022-01-29T07:58:33Z" level=error msg="error generating application from params" error="no clusterDecisionResources found" generator="{<nil> <nil> <nil> <nil> <nil> 0xc00070bba0}"
2022-01-29T07:58:33.189Z	ERROR	controller-runtime.manager.controller.applicationset	Reconciler error	{"reconciler group": "argoproj.io", "reconciler kind": "ApplicationSet", "name": "acm-appsets", "namespace": "openshift-gitops", "error": "no clusterDecisionResources found"}
sigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).processNextWorkItem
```