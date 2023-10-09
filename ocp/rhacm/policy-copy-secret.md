#### 从 Hub 向 Spoke Cluster 拷贝 secret
```
# 创建 project policy-test
(hub)$ oc new-project policy-test

# 将 namespace policy-test 与 clusterset default 绑定起来
(hub)$ cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: default
  namespace: policy-test
spec:
  clusterSet: default
EOF


# 创建 Policy policy-copy-secret-local-cluster
# 创建 Placement placement-copy-secret-local-cluster
# 创建 PlacementBinding binding-copy-secret-local-cluster
# 在 Hub Cluster 上将 secret pull-secret 从 namespace openshift-config 
# 拷贝到 namespace policy-test 下的 secret pull-secret-copy
(hub)$ cat <<EOF | oc apply -f -
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: policy-copy-secret-local-cluster
  namespace: policy-test
spec:
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: cp-copy-secret-local-cluster
        spec:
          remediationAction: enforce
          severity: low
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: v1
                kind: Secret
                metadata:
                  name: pull-secret-copy
                  namespace: policy-test
                type: Opaque
                data:
                  ".dockerconfigjson": '{{ fromSecret "openshift-config" "pull-secret" ".dockerconfigjson" }}'
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-copy-secret-local-cluster
placementRef:
  name: placement-copy-secret-local-cluster
  kind: Placement
  apiGroup: cluster.open-cluster-management.io
subjects:
- name: policy-copy-secret-local-cluster
  kind: Policy
  apiGroup: policy.open-cluster-management.io
---
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: placement-copy-secret-local-cluster
spec:
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchExpressions:
        - key: name
          operator: In
          values:
          - local-cluster
EOF

# 创建 Policy policy-copy-pull-secret 
# 创建 Placement placement-copy-pull-secret
# 创建 PlacementBinding binding-copy-pull-secret
# Policy 定义目标集群 ocp4-3 需具有 secret kube-system/pull-secret
# secret kube-system/pull-secret 的 key '.dockerconfigjson'
# secret kube-system/pull-secret 的 value 来自 hub cluster 的 policy-test/pull-secret-copy 的 key '.dockerconfigjson' 的 value
(hub)$ cat <<EOF | oc apply -f -
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: policy-copy-pull-secret
  namespace: policy-test
spec:
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: cp-copy-pull-secret
        spec:
          remediationAction: enforce
          severity: low
          object-templates:
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: v1
                kind: Secret
                metadata:
                  name: pull-secret
                  namespace: kube-system
                type: Opaque
                data:
                  ".dockerconfigjson": '{{hub fromSecret "policy-test" "pull-secret-copy" ".dockerconfigjson" hub}}'
  remediationAction: enforce
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-copy-pull-secret
placementRef:
  name: placement-copy-pull-secret
  kind: Placement
  apiGroup: cluster.open-cluster-management.io
subjects:
- name: policy-copy-pull-secret
  kind: Policy
  apiGroup: policy.open-cluster-management.io
---
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: placement-copy-pull-secret
spec:
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchExpressions:
        - key: name
          operator: In
          values:
          - ocp4-3
EOF

# hub: 检查 namespace policy-test 下的 Policy 状态
(hub)$ oc get Policy -n policy-test 
NAME                               REMEDIATION ACTION   COMPLIANCE STATE   AGE
policy-copy-pull-secret            enforce              Compliant          111m
policy-copy-secret-local-cluster                        Compliant          122m

# hub: 查看 source secret 内容
(hub)$ oc get secret pull-secret-copy -n policy-test -o yaml
apiVersion: v1
data:
  .dockerconfigjson: xxx
kind: Secret
metadata:
  creationTimestamp: "2023-10-09T02:59:16Z"
  name: pull-secret-copy
  namespace: policy-test
  resourceVersion: "175121134"
  uid: 4b6db888-7f73-4f21-a8a2-5d9ade5f3610
type: Opaque

# ocp4-3: 查看 Policy 状态
(ocp4-3)$ oc --kubeconfig=./kubeconfig get Policy -n ocp4-3 
NAME                                  REMEDIATION ACTION   COMPLIANCE STATE   AGE
policy-test.policy-copy-pull-secret   enforce              Compliant          114m

# ocp4-3: 检查 target secret 内容
(ocp4-3)$ oc --kubeconfig=./kubeconfig get secret pull-secret -n kube-system -o yaml
apiVersion: v1
data:
  .dockerconfigjson: xxx
kind: Secret
metadata:
  creationTimestamp: "2023-10-09T04:52:11Z"
  name: pull-secret
  namespace: kube-system
  resourceVersion: "46623546"
  uid: 7d12ef6d-0be7-43ea-8382-bdc03eefd21f
type: Opaque
```