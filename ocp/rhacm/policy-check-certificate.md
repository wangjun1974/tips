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

### ocp4-3 安装 cert-manager
KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig helm repo add jetstack https://charts.jetstack.io
KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig helm repo update
KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig helm repo list
KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.1 \
  --set installCRDs=true

### ocp4-3: 创建 Issuer
### ocp4-3: 创建 Certificate 
### Certificate 有效期为 2h
cat <<EOF | KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig oc apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: cert-issuer
  namespace: default
spec:
  selfSigned: {}
EOF

cat <<EOF | KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig oc apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: certificate-tls
  namespace: default
spec:
  commonName: foo.example.com
  dnsNames:
    - example.com
    - foo.example.com
    - bar.example.com
    - 192.168.122.140
  duration: 2h
  issuerRef:
    name: cert-issuer
    kind: Issuer
  isCA: false
  renewBefore: 1h
  secretName: cert-secret
EOF

### ocp4-3: CertificatePolicy 因不满足 minimumDuration 而被触发
(ocp4-3)$ oc get Policy policy-test.policy-check-certificate -n ocp4-3 
NAME                                   REMEDIATION ACTION   COMPLIANCE STATE   AGE
policy-test.policy-check-certificate   inform               NonCompliant       3d

(ocp4-3)$ oc get Policy policy-test.policy-check-certificate -n ocp4-3 -o yaml
...
status:
  compliant: NonCompliant
  details:
  - compliant: NonCompliant
    history:
    - eventName: policy-test.policy-check-certificate.178e78caf24c5d0d
      lastTimestamp: "2023-10-16T03:38:14Z"
      message: 'NonCompliant; 1 certificates expire in less than 300h0m0s: default:cert-secret'

### 删除 Certificate 和 Secret
KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig oc delete Certificate certificate-tls -n default
KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig oc delete Secret cert-secret -n default

### ocp4-3: 没有证书过期，Policy COMPLIANCE STATE 恢复 Complaint 状态

```