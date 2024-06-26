### 将用户或者ServiceAccount添加到 open-cluster-management:subscription-admin ClusterRoleBinding 里
https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.8/html/applications/managing-applications#granting-subscription-admin-privilege
### 添加 subjects 来把用户和 ServiceAccount 添加到 ClusterRoleBinding open-cluster-management:subscription-admin 中
```
$ oc get clusterrolebinding open-cluster-management:subscription-admin
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: "2023-05-11T02:25:50Z"
  name: open-cluster-management:subscription-admin
  resourceVersion: "129576888"
  uid: 15da88af-b9db-419c-be12-95dd8bc1997f
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: open-cluster-management:subscription-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: admin
```

### ACM Policy ConfigurationPolicy 
https://cloud.redhat.com/blog/generating-governance-policies-using-kustomize-and-gitops<br>
https://github.com/stolostron/policy-collection/blob/main/community/CM-Configuration-Management/policy-machineconfig-chrony.yaml<br>
```
# 定义 ACM Policy - ConfigurationPolicy - 配置 machineconfig 
cat > policy-ocp4-3.yaml <<EOF
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: add-snobaseline
  annotations:
    policy.open-cluster-management.io/standards: NIST SP 800-53
    policy.open-cluster-management.io/categories: CM Configuration Management
    policy.open-cluster-management.io/controls: CM-2 Baseline Configuration
spec:
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: add-snobaseline
        spec:
          object-templates:
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: config.openshift.io/v1
                kind: OperatorHub
                metadata:
                  name: cluster
                spec:
                  disableAllDefaultSources: true
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: operators.coreos.com/v1alpha1
                kind: CatalogSource
                metadata:
                  name: redhat-operator-index
                  namespace: openshift-marketplace
                spec:
                  image: registry.example.com:5000/redhat/redhat-operator-index:v4.11
                  sourceType: grpc
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: operators.coreos.com/v1alpha1
                kind: CatalogSource
                metadata:
                  name: gitea-catalog
                  namespace: openshift-marketplace
                spec:
                  image: registry.example.com:5000/gpte-devops-automation/gitea-catalog:latest
                  sourceType: grpc
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: v1
                data:
                  htpasswd: YWRtaW46JDJ5JDA1JHhvVnd0NkE1VVd0bVZJSGV5ZG82Li5qWWNWNGl3T3ZPL2lRVTB0LzdpZEd0VEdVTHpPemhXCnVzZXIwMTokYXByMSRRT3VVVGtpUiRhMmFWb1B0OVJlV0ZFSG9TanMuNm4vCnVzZXIwMjokYXByMSRjS2dTdDdpcyRZMkN2NTQ3eUhMNEp6UnZZVjR5ODYuCg==
                kind: Secret
                metadata:
                  name: htpass-secret
                  namespace: openshift-config
                type: Opaque
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: config.openshift.io/v1
                kind: OAuth
                metadata:
                  name: cluster
                spec:
                  identityProviders:
                  - name: htpasswd_provider
                    mappingMethod: claim
                    type: HTPasswd
                    htpasswd:
                      fileData:
                        name: htpass-secret
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: rbac.authorization.k8s.io/v1
                kind: ClusterRoleBinding
                metadata:
                  name: cluster-admin-1
                roleRef:
                  apiGroup: rbac.authorization.k8s.io
                  kind: ClusterRole
                  name: cluster-admin
                subjects:
                - apiGroup: rbac.authorization.k8s.io
                  kind: User
                  name: admin
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: machineconfiguration.openshift.io/v1
                kind: MachineConfig
                metadata:
                  name: 99-master-mirror-by-digest-registries
                  labels:
                    machineconfiguration.openshift.io/role: master
                spec:
                  config:
                    ignition:
                      version: 3.2.0
                    storage:
                      files:
                      - contents:
                          source: data:text/plain;charset=utf-8;base64,W1tyZWdpc3RyeV1dCiAgcHJlZml4ID0gIiIKICBsb2NhdGlvbiA9ICJyZWdpc3RyeS5yZWRoYXQuaW8vbXVsdGljbHVzdGVyLWVuZ2luZSIKICBtaXJyb3ItYnktZGlnZXN0LW9ubHkgPSB0cnVlCiAKICBbW3JlZ2lzdHJ5Lm1pcnJvcl1dCiAgICBsb2NhdGlvbiA9ICJyZWdpc3RyeS5leGFtcGxlLmNvbTo1MDAwL211bHRpY2x1c3Rlci1lbmdpbmUiCgpbW3JlZ2lzdHJ5XV0KICBwcmVmaXggPSAiIgogIGxvY2F0aW9uID0gInJlZ2lzdHJ5LnJlZGhhdC5pby9yaGFjbTIiCiAgbWlycm9yLWJ5LWRpZ2VzdC1vbmx5ID0gdHJ1ZQogCiAgW1tyZWdpc3RyeS5taXJyb3JdXQogICAgbG9jYXRpb24gPSAicmVnaXN0cnkuZXhhbXBsZS5jb206NTAwMC9yaGFjbTIiCgpbW3JlZ2lzdHJ5XV0KICBwcmVmaXggPSAiIgogIGxvY2F0aW9uID0gInF1YXkuaW8vZ3B0ZS1kZXZvcHMtYXV0b21hdGlvbiIKICBtaXJyb3ItYnktZGlnZXN0LW9ubHkgPSBmYWxzZQoKICBbW3JlZ2lzdHJ5Lm1pcnJvcl1dCiAgICBsb2NhdGlvbiA9ICJyZWdpc3RyeS5leGFtcGxlLmNvbTo1MDAwL2dwdGUtZGV2b3BzLWF1dG9tYXRpb24iCgpbW3JlZ2lzdHJ5XV0KICBwcmVmaXggPSAiIgogIGxvY2F0aW9uID0gInJlZ2lzdHJ5LnJlZGhhdC5pby9vcGVuc2hpZnQ0IgogIG1pcnJvci1ieS1kaWdlc3Qtb25seSA9IGZhbHNlCgogIFtbcmVnaXN0cnkubWlycm9yXV0KICAgIGxvY2F0aW9uID0gInJlZ2lzdHJ5LmV4YW1wbGUuY29tOjUwMDAvb3BlbnNoaWZ0NCIKCltbcmVnaXN0cnldXQogIHByZWZpeCA9ICIiCiAgbG9jYXRpb24gPSAicmVnaXN0cnkucmVkaGF0LmlvL3JoZWw4IgogIG1pcnJvci1ieS1kaWdlc3Qtb25seSA9IGZhbHNlCgogIFtbcmVnaXN0cnkubWlycm9yXV0KICAgIGxvY2F0aW9uID0gInJlZ2lzdHJ5LmV4YW1wbGUuY29tOjUwMDAvcmhlbDgiCgpbW3JlZ2lzdHJ5XV0KICBwcmVmaXggPSAiIgogIGxvY2F0aW9uID0gInF1YXkuaW8vanBhY2tlciIKICBtaXJyb3ItYnktZGlnZXN0LW9ubHkgPSBmYWxzZQoKICBbW3JlZ2lzdHJ5Lm1pcnJvcl1dCiAgICBsb2NhdGlvbiA9ICJyZWdpc3RyeS5leGFtcGxlLmNvbTo1MDAwL2pwYWNrZXIiCgpbW3JlZ2lzdHJ5XV0KICBwcmVmaXggPSAiIgogIGxvY2F0aW9uID0gImRvY2tlci5pby9iaXRuYW1pIgogIG1pcnJvci1ieS1kaWdlc3Qtb25seSA9IGZhbHNlCgogIFtbcmVnaXN0cnkubWlycm9yXV0KICAgIGxvY2F0aW9uID0gInJlZ2lzdHJ5LmV4YW1wbGUuY29tOjUwMDAvYml0bmFtaSIKCltbcmVnaXN0cnldXQogIHByZWZpeCA9ICIiCiAgbG9jYXRpb24gPSAiZG9ja2VyLmlvL21pbmlvIgogIG1pcnJvci1ieS1kaWdlc3Qtb25seSA9IGZhbHNlCgogIFtbcmVnaXN0cnkubWlycm9yXV0KICAgIGxvY2F0aW9uID0gInJlZ2lzdHJ5LmV4YW1wbGUuY29tOjUwMDAvbWluaW8iCg==
                        filesystem: root
                        mode: 420
                        path: /etc/containers/registries.conf.d/99-master-mirror-by-digest-registries.conf
          remediationAction: enforce
          severity: low
  remediationAction: enforce
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-add-snobaseline
placementRef:
  name: placement-add-snobaseline
  kind: PlacementRule
  apiGroup: apps.open-cluster-management.io
subjects:
- name: add-snobaseline
  kind: Policy
  apiGroup: policy.open-cluster-management.io
---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: placement-add-snobaseline
spec:
  clusterConditions:
  - status: "True"
    type: ManagedClusterConditionAvailable
  clusterSelector:
    matchExpressions:
      - {key: name, operator: In, values: ["ocp4-3"]}
EOF
```

### 用 ACM Config Policy 结合 RBAC 限制某个用户可以访问 application 
https://cloud.redhat.com/blog/generating-governance-policies-using-kustomize-and-gitops<br>
https://github.com/stolostron/policy-collection/blob/main/community/CM-Configuration-Management/policy-machineconfig-chrony.yaml<br>
```
# 定义 ACM Policy - ConfigurationPolicy - 配置 machineconfig 
cat > policy-rbac-hub.yaml <<EOF
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: add-rbachub
  annotations:
    policy.open-cluster-management.io/standards: NIST SP 800-53
    policy.open-cluster-management.io/categories: CM Configuration Management
    policy.open-cluster-management.io/controls: CM-2 Baseline Configuration
spec:
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: add-rbachub
        spec:
          object-templates:
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: rbac.authorization.k8s.io/v1
                kind: ClusterRoleBinding
                metadata:
                  name: clusterrolebinding-application-open-cluster-management-ocp4-3
                roleRef:
                  apiGroup: rbac.authorization.k8s.io
                  kind: ClusterRole
                  name: open-cluster-management:view:ocp4-3
                subjects:
                - apiGroup: rbac.authorization.k8s.io
                  kind: User
                  name: user01
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: rbac.authorization.k8s.io/v1
                kind: RoleBinding
                metadata:
                  name: rolebinding-application-open-cluster-management-ocp4-3
                  namespace: ocp4-3
                roleRef:
                  apiGroup: rbac.authorization.k8s.io
                  kind: ClusterRole
                  name: view
                subjects:
                - apiGroup: rbac.authorization.k8s.io
                  kind: User
                  name: user01
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: rbac.authorization.k8s.io/v1
                kind: Role
                metadata:
                  name: role-view-book-import
                  namespace: book-import
                rules:
                - apiGroups:
                  - '*'
                  resources:
                  - '*'
                  verbs:
                  - get
                  - watch
                  - list
            - complianceType: mustonlyhave
              objectDefinition:
                apiVersion: rbac.authorization.k8s.io/v1
                kind: RoleBinding
                metadata:
                  name: rolebinding-application-open-cluster-management-book-import
                  namespace: book-import
                roleRef:
                  apiGroup: rbac.authorization.k8s.io
                  kind: Role
                  name: role-view-book-import
                subjects:
                - apiGroup: rbac.authorization.k8s.io
                  kind: User
                  name: user01
          remediationAction: enforce
          severity: low
  remediationAction: enforce
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-add-rbachub
placementRef:
  name: placement-add-rbachub
  kind: PlacementRule
  apiGroup: apps.open-cluster-management.io
subjects:
- name: add-rbachub
  kind: Policy
  apiGroup: policy.open-cluster-management.io
---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: placement-add-rbachub
spec:
  clusterConditions:
  - status: "True"
    type: ManagedClusterConditionAvailable
  clusterSelector:
    matchExpressions:
      - {key: name, operator: In, values: ["local-cluster"]}
EOF
```