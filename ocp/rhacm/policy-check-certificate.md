#### 通过 Policy 检查 Managed Cluster 的证书是否过期
```
### 创建 namespace
$ oc new-project policy-test

### 创建 ManagedClusterSetBinding，将 ManagedClusterSet 'default' 与 namespace 关联起来
$ cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: default
  namespace: policy-test
spec:
  clusterSet: default
EOF

### Policy 定义 CertificatePolicy
### policy-templates 里包含 CertificatePolicy cp-policy-check-certificate
### Placement 确定目标集群
### PlacementBinding 将 Policy 与 Placement 联系起来
$ cat <<EOF | oc apply -f -
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: policy-check-certificate
  namespace: policy-test
  annotations:
    policy.open-cluster-management.io/standards: NIST SP 800-53
    policy.open-cluster-management.io/categories: SC System and Communications Protection
    policy.open-cluster-management.io/controls: SC-8 Transmission Confidentiality and Integrity
spec:
  remediationAction: inform
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: CertificatePolicy # cert management expiration
        metadata:
          name: cp-policy-check-certificate
        spec:
          namespaceSelector:
            include: ["default"]
          remediationAction: inform # the policy-template spec.remediationAction is overridden by the preceding parameter value for spec.remediationAction.
          severity: low
          minimumDuration: 300h
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-check-certificate
  namespace: policy-test
placementRef:
  name: placement-check-certificate
  kind: Placement
  apiGroup: cluster.open-cluster-management.io
subjects:
- name: policy-check-certificate
  kind: Policy
  apiGroup: policy.open-cluster-management.io
---
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: placement-check-certificate
  namespace: policy-test
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
```