### 使用命令行方式安装 OCS 4.5
# email: Install OCS using yaml for automation purpose.

1. 创建 deploy-ocs-operator.yaml 文件
2. 文件包含 3 个对象：Namespace, OperatorGroup 和 Subscription
3. Namespace 是 ocs operator 安装的 namespace
4. OperatorGroup 指定 RBAC 作用的目标
5. Subscription 指定 channel，installPlanApproval 策略和 startingCSV
``` 
cat > deploy-ocs-operator.yaml << EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-storage
  labels:
    openshift.io/cluster-monitoring: "true"
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-storage-operatorgroup
  namespace: openshift-storage
spec:
  targetNamespaces:
  - openshift-storage
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ocs-operator
  namespace: openshift-storage
spec:
  channel: stable-4.5
  installPlanApproval: Automatic
  name: ocs-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: ocs-operator.v4.5.0
EOF

# 创建 cluster-service.yaml 文件
cat > cluster-service.yaml << EOF
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  manageNodes: false
  monDataDirHostPath: /var/lib/rook
  storageDeviceSets:
  - config: {}
    count: 1   
    dataPVCTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: "1"
        storageClassName: gp2
        volumeMode: Block
    name: ocs-deviceset
    placement: {}
    replica: 3  
    resources: {}
EOF

oc create -f cluster-service.yaml 

# VMware thin storageclass example
cat > cluster-service.yaml << EOF
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  manageNodes: false
  monPVCTemplate:
     spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
      storageClassName: thin
      volumeMode: Filesystem
  storageDeviceSets:
  - count: 1
    dataPVCTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 2Ti
        storageClassName: thin
        volumeMode: Block
    name: ocs-deviceset
    placement: {}
    portable: false
    replica: 3
    resources: {}
EOF

# aws 版本 of cluster-service.yaml
cat > cluster-service.yaml << EOF
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  manageNodes: false
  monDataDirHostPath: /var/lib/rook
  storageDeviceSets:
  - config: {}
    count: 1
    dataPVCTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: "2Ti"
        storageClassName: gp2
        volumeMode: Block
    name: ocs-deviceset
    placement: {}
    replica: 3
    resources: {}
EOF
```