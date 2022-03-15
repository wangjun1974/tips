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
  name: gitops-openshift-clusters
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
# https://argocd-applicationset.readthedocs.io/en/stable/Generators-Cluster-Decision-Resource/
# https://itnext.io/level-up-your-argo-cd-game-with-applicationset-ccd874977c4c
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
      name: 'acm-appset1-{{name}}'
    spec:
      destination:
        namespace: bgdk
        server: '{{server}}'
      project: default
      source:
        path: apps/bgd/overlays/bgdk
        repoURL: https://github.com/RedHat-EMEA-SSA-Team/ns-apps/
        targetRevision: single-app
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
        - PrunePropagationPolicy=foreground
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

在 Hub Cluster 上导出 Managed Cluster 的 klusterlet-crd.yaml 和 import.yaml
---
CLUSTER_NAME="test3"
ocp4 get secret ${CLUSTER_NAME}-import -n $CLUSTER_NAME -o jsonpath={.data.crds\\.yaml} | base64 --decode > /tmp/klusterlet-crd.yaml
ocp4 get secret ${CLUSTER_NAME}-import -n $CLUSTER_NAME -o jsonpath={.data.import\\.yaml} | base64 --decode > /tmp/import.yaml

---
# On Managed/Spoke Cluster
ocp4.9 apply -f /tmp/klusterlet-crd.yaml
ocp4.9 apply -f /tmp/import.yaml 

https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/clusters/managing-your-clusters#remove-a-cluster-by-using-the-cli
https://github.com/stolostron/deploy/blob/master/hack/cleanup-managed-cluster.sh
---
在 Hub Cluster 上压缩 etcd 
ocp4 get pods -n openshift-etcd
ocp4 rsh -n openshift-etcd etcd-master0.ocp4.rhcnsa.com etcdctl endpoint status --cluster -w table
ocp4 rsh -n openshift-etcd etcd-master0.ocp4.rhcnsa.com 
sh-4.4# etcdctl compact $(etcdctl endpoint status --write-out="json" |  egrep -o '"revision":[0-9]*' | egrep -o '[0-9]*' -m1)
compacted revision 400503440

# RHACM 2.4.1 UI 有 Bug，在 UI 上删除 Cluster 之后，界面仍然显示 Managed Cluster 
# 解决的方法是在 ACM Hub 上重启 console-chart pod

# RHACM 2.4.1 UI 不显示 Applications 的处理
# https://docs.google.com/document/d/1M8yGOwXnY8w-4g-a_Pt2pJlirDTi3EYHN1Es2V0t18E/edit

cat > patchsrch.sh <<'EOF'
#!/bin/bash

export NS=$1
echo "Applying search patch in namespace $NS"

cat > manifest-oneimage.json <<EOF
[
    {
        "image-name": "search-collector-rhel8",
        "image-version": "2.4.1",
        "image-remote": "registry.redhat.io/rhacm2",
        "image-digest": "sha256:960bdc30912f856860026ad4e204d09d979de648d298496229944307597c30d4",
        "image-key": "search_collector"
    }
]
EOF

kubectl create configmap patchsrch --from-file=./manifest-oneimage.json -n $NS
kubectl annotate mch multiclusterhub --overwrite mch-imageOverridesCM=patchsrch -n $NS
EOF

sh patchsrch.sh open-cluster-management

oc delete appsub search-prod-sub -n open-cluster-management

# 学习学习 ArgoCD ApplicationSet Controller 的文档
# https://blog.argoproj.io/introducing-the-applicationset-controller-for-argo-cd-982e28b62dc5
拿 https://github.com/wangjun1974/book-import 这个仓库测试一下
### 在 ACM Hub 部署 ArgoCD/OpenShift GitOps ApplicationSets
# https://github.com/argoproj-labs/applicationset/issues/71
# https://argocd-applicationset.readthedocs.io/en/stable/Generators-Cluster-Decision-Resource/
# https://itnext.io/level-up-your-argo-cd-game-with-applicationset-ccd874977c4c
1. 
cat <<'EOF' | ocp4 apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: acm-appset2
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
      name: 'acm-appset2-{{name}}'
    spec:
      destination:
        namespace: book-import-2
        server: '{{server}}'
      project: default
      source:
        path: book-import
        repoURL: https://github.com/wangjun1974/book-import
        targetRevision: master-no-pre-post
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
        - PrunePropagationPolicy=foreground
EOF

# 安装 Red Hat GPTE Gitea Operator
# https://github.com/redhat-gpte-devopsautomation/gitea-operator
# 安装 CatalogSource
oc apply -f https://raw.githubusercontent.com/redhat-gpte-devopsautomation/gitea-operator/master/catalog_source.yaml

# 在 UI 上安装 Gitea Operator

# 创建 gitea project
oc new-project gitea

# 创建 Gitea 实例
cat <<EOF | oc apply -f -
apiVersion: gpte.opentlc.com/v1
kind: Gitea
metadata:
  name: gitea-with-admin
spec:
  giteaSsl: true
  giteaAdminUser: opentlc-mgr
  giteaAdminPassword: ""
  giteaAdminPasswordLength: 32
  giteaAdminEmail: opentlc-mgr@redhat.com
  giteaCreateUsers: true
  giteaGenerateUserFormat: "lab-user-%d"
  giteaUserNumber: 2
  giteaUserPassword: openshift
  giteaMigrateRepositories: true
  giteaRepositoriesList:
  - repo: https://gitee.com/wangjun1974/book-import
    name: book-import
    private: false
EOF

创建 ApplicationSet 
cat <<'EOF' | ocp4 apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: acm-appset3
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
      name: 'acm-appset3-{{name}}'
    spec:
      destination:
        namespace: book-import-3
        server: '{{server}}'
      project: default
      source:
        path: book-import
        repoURL: https://gitea-with-admin-gitea.apps.ocp4.rhcnsa.com/lab-user-1/book-import
        targetRevision: master-no-pre-post
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
        - PrunePropagationPolicy=foreground
EOF

ArgoCD 报错
rpc error: code = Unknown desc = Get "https://gitea-with-admin-gitea.apps.ocp4.rhcnsa.com/lab-user-1/book-import/info/refs?service=git-upload-pack": x509: certificate signed by unknown authority
# 参考
# https://access.redhat.com/solutions/6678751

# 获取 gitea-with-admin-gitea.apps.ocp4.rhcnsa.com 的证书
openssl s_client -connect gitea-with-admin-gitea.apps.ocp4.rhcnsa.com:443 2>/dev/null </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | sed -e 's|^|        |g' 

# 编辑 ArgoCD CRD
# 参考 https://github.com/iam-veeramalla/openshift-gitops-examples/blob/master/argocd/GITOPS-1725/argocd-initialTLScerts.yaml
oc edit argocd openshift-gitops -n openshift-gitops

# 在 tls: 段添加 
    initialCerts:
      gitea-with-admin-gitea.apps.ocp4.rhcnsa.com: |
        -----BEGIN CERTIFICATE-----
        MIIDYzCCAkugAwIBAgIIQRP3xrlQftgwDQYJKoZIhvcNAQELBQAwJjEkMCIGA1UE
        AwwbaW5ncmVzcy1vcGVyYXRvckAxNjI2NjA2MTU2MB4XDTIxMDcxODExMDIzOFoX
        DTIzMDcxODExMDIzOVowITEfMB0GA1UEAwwWKi5hcHBzLm9jcDQucmhjbnNhLmNv
        bTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOPdR9qh1gTs1iUqUcK8
        IDhekCUPmJywFwRuatzydztAPcGDvj4Y5GWx2pu+D8BD2A+Q3F59904BZWb4FlTe
        6kDoMvcXr9Y5HGsfIMQpJ5GdFGzNg0veDu88K1P4NAmK5C+FKVYKb83wBja/x7Ys
        3g0oqXaQuESY83okJCM3zplPcXxFyqVgrC7E9A/TNJsuZvRZWGfQHIUrxsUPEiVT
        jp8AwOcmyAEocm5mdNWThQGvBARdmuKuySb1/03BNbKD7qmj5x8/dz3rCyF7ufz3
        JOXsKzCuv5VGBx+IEg9IX+rvlNd2MCq/dJy3oAUrSEYUjOi4ZZ/OH87fndXuMNKC
        eesCAwEAAaOBmTCBljAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYBBQUH
        AwEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUpW/Kg6qjguBcMYBqbilYtopB4E0w
        HwYDVR0jBBgwFoAULmTEKt6hRTncC2BADMSke8A25rgwIQYDVR0RBBowGIIWKi5h
        cHBzLm9jcDQucmhjbnNhLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAB97KrWlCuUgV
        gcZKqw800F4VOiJGXxsEQhHQ1EMfaBNkV51LBWLiD0iJND9UDL3nOVK0DTXLNbh6
        kofsI21vo3/XsJ/BofC6Pu1kFGqNiztVMh4BogCQSXkIu4K3wM04kgsj5Ynh4/Vz
        3UpUqR9q7AkqBgEEX55ytIY1l/Py/KnBgj3DGVLEQuJnOOyyhsPoKFz9pMOJ/r4+
        zJ+L0bpLRjsH1Zb7OPodzTHMCqPgdY/b7YOYtQcFYHSrtP5dmIIlUoLdqgCAlBGb
        oIAtkZlQQFudmI6p28zbmV3zoAsY9QSFv6Gg4Eiik+lttgy86yk6OqdSF+K2kwXQ
        qairhQ9Log==
        -----END CERTIFICATE-----

# 然后重启 Deployment openshift-gitops-server
```


### 登录 argocd  
```
# 登录 openshift-gitops 的 argocd
$ PASSWD=$(oc get secret openshift-gitops-cluster -n openshift-gitops -ojsonpath='{.data.admin\.password}' | base64 -d)
$ ARGOCD_URL=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
$ argocd login --username admin --password ${PASSWD} --insecure ${ARGOCD_URL}

# 登录 argocd 的 argocd
$ PASSWD=$(oc get secret argocd-sample-cluster -n argocd -ojsonpath='{.data.admin\.password}' | base64 -d)
$ ARGOCD_URL=$(oc get route argocd-sample-server -n argocd -o jsonpath='{.spec.host}')
$ argocd login --username admin --password ${PASSWD} --insecure ${ARGOCD_URL}

# 设置 KUBECONFIG 指向 edge-1 的 kubeconfig
# export KUBECONFIG=/root/kubeconfig/edge-1/kubeconfig 
[root@ocpai1 edge-1]# oc config get-contexts
CURRENT   NAME                                                                      CLUSTER                AUTHINFO                              NAMESPACE
          microshift                                                                microshift             user                                  default
          open-cluster-management-agent-addon/192-168-122-203:6443/system:masters   192-168-122-203:6443   system:masters/192-168-122-203:6443   open-cluster-management-agent-addon
*         open-cluster-management-agent/192-168-122-203:6443/system:masters         192-168-122-203:6443   system:masters/192-168-122-203:6443   open-cluster-management-agent
          test/192.168.122.203:6443/system:masters                                  192.168.122.203:6443   system:masters/192.168.122.203:6443   test

# 在此基础上登录 ocp4-1 cluster
[root@ocpai1 edge-1]# oc login https://api.ocp4-1.example.com:6443 -u admin 

# 获取 context
[root@ocpai1 edge-1]# oc config get-contexts
CURRENT   NAME                                                                      CLUSTER                       AUTHINFO                              NAMESPACE
*         default/api-ocp4-1-example-com:6443/admin                                 api-ocp4-1-example-com:6443   admin/api-ocp4-1-example-com:6443     default
...
          test/192.168.122.203:6443/system:masters                                  192.168.122.203:6443          system:masters/192.168.122.203:6443   test

# 将 context 重命名
$ oc config rename-context default/api-ocp4-1-example-com:6443/admin ocp4-1
$ oc config rename-context test/192.168.122.203:6443/system:masters edge-1

# 添加 argocd cluster
$ argocd cluster add ocp4-1
$ argocd cluster add edge-1

# 创建应用 
$ oc --context ocp4-1 new-project book-import 
$ argocd app create --project default --name book-import-ocp4-1 \
  --repo http://gitea-without-admin-gitea.apps.ocp4-1.example.com/test1/book-import.git \
  --path book-import/ \
  --dest-server $(argocd cluster list | grep ocp4-1 | awk '{print $1}') \
  --dest-namespace book-import \
  --revision master-no-pre-post --sync-policy automated

$ oc --context edge-1 new-project book-import 
$ argocd app create --project default --name book-import-edge-1 \
  --repo http://gitea-without-admin-gitea.apps.ocp4-1.example.com/test1/book-import.git \
  --path book-import/ \
  --dest-server $(argocd cluster list | grep edge-1 | awk '{print $1}') \
  --dest-namespace book-import \
  --revision master-no-pre-post --sync-policy automated

```

### 
```
$ argocd cluster get 'edge-1' -o yaml --grpc-web
config:
  tlsClientConfig:
    insecure: true
connectionState:
  attemptedAt: "2022-03-15T02:36:29Z"
  message: Cluster has no application and not being monitored.
  status: Unknown
info:
  applicationsCount: 0
  cacheInfo: {}
  connectionState:
    attemptedAt: "2022-03-15T02:36:29Z"
    message: Cluster has no application and not being monitored.
    status: Unknown
labels:
  apps.open-cluster-management.io/acm-cluster: "true"
  apps.open-cluster-management.io/cluster-name: edge-1
  apps.open-cluster-management.io/cluster-server: ""
name: edge-1
server: ""

# 删除 cluster edge-1
$ argocd cluster rm edge-1 --server "" --grpc-web 
FATA[0000] rpc error: code = PermissionDenied desc = permission denied 
```