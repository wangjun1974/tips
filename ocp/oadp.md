### 测试 oadp 
https://docs.google.com/document/d/1YkEQLmTVu4lS88xmoyQLAxYVm-BvrDusemPJptclvjQ

```
################################
# 首先安装一个 minio 作为 s3 服务 #
################################
# 克隆 Velero repository
git clone https://github.com/vmware-tanzu/velero.git
cd velero

# 安装 MinIO
# 部署前注意改一下 MINIO_SECRET_KEY
$ oc apply -f examples/minio/00-minio-deployment.yaml

# 创建 route
$ oc project velero
$ oc expose svc minio

##################
# 安装 aws 客户端 #
################## 
# 安装 python3-pip
$ dnf install -y python3-pip

# 安装 awscli
$ pip3 install awscli --upgrade --user

# 配置 aws access key 和 aws secret key
# 参见: https://docs.min.io/docs/aws-cli-with-minio.html
$ aws configure

# 检查 ~/.aws/credentials 文件内容
$ cat ~/.aws/credentials 
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123

##############
# 创建 bucket #
##############
$ aws --endpoint-url http://minio-velero.apps.ocp1.rhcnsa.com/ s3 mb s3://velero
$ aws --endpoint-url http://minio-velero.apps.ocp1.rhcnsa.com/ s3 ls
2022-03-01 09:29:26 velero

#####################
# 安装 OADP operator #
#####################

# 创建 cloud-credentials 文件
$ MINIO_ACCESS_KEY="minio"
$ MINIO_SECRET_KEY="XXXXXX"
$ cat > cloud-credentials <<EOF 
[default]
aws_access_key_id = ${MINIO_ACCESS_KEY}
aws_secret_access_key = ${MINIO_SECRET_KEY}
EOF

# 在 openshift-adp namesapce 下创建 secret cloud-credentials
$ oc create secret generic cloud-credentials --namespace openshift-adp --from-file cloud=cloud-credentials

# 配置 DataProtectionApplication dpa-sample
# 这个配置可以与 minio 工作在一起
$ cat <<EOF | oc apply -f -
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: dpa-sample
  namespace: openshift-adp
spec:
  backupLocations:
    - velero:
        config:
          profile: "default"
          region: minio
          s3Url: http://minio-velero.apps.ocp1.rhcnsa.com
          insecureSkipTLSVerify: "true" 
          s3ForcePathStyle: "true"
        credential:
          key: cloud
          name: cloud-credentials
        objectStorage:
          bucket: velero
          prefix: velero
        default: true
        provider: aws
  configuration:
    restic:
      enable: true
    velero:
      defaultPlugins:
        - aws
        - csi
        - openshift
    featureFlags:
    - EnableCSI
EOF

# 创建备份 gitea-persistent-1 ，备份 gitea namespace
$ cat <<EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: gitea-persistent-1
  labels:
    velero.io/storage-location: default
  namespace: openshift-adp
spec:
  hooks: {}
  includedNamespaces:
  - gitea
  snapshotVolumes: false
  storageLocation: dpa-sample-1
  ttl: 2h0m0s
EOF

# 创建 restic 备份
# 创建备份 gitea-persistent-1 ，备份 gitea namespace
$ cat <<EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: gitea-persistent-5
  labels:
    velero.io/storage-location: default
  namespace: openshift-adp
spec:
  hooks: {}
  includedNamespaces:
  - gitea
  snapshotVolumes: false
  storageLocation: dpa-sample-1
  defaultVolumesToRestic: true
  ttl: 48h0m0s
EOF

# 查看备份内容
$ aws --endpoint-url http://minio-velero.apps.ocp1.rhcnsa.com/ s3 ls s3://velero/velero/backups/gitea-persistent-1/
2022-03-01 09:42:05         29 gitea-persistent-1-csi-volumesnapshotcontents.json.gz
2022-03-01 09:42:05         29 gitea-persistent-1-csi-volumesnapshots.json.gz
2022-03-01 09:41:58      15999 gitea-persistent-1-logs.gz
2022-03-01 09:42:04         29 gitea-persistent-1-podvolumebackups.json.gz
2022-03-01 09:42:05        825 gitea-persistent-1-resource-list.json.gz
2022-03-01 09:42:05         29 gitea-persistent-1-volumesnapshots.json.gz
2022-03-01 09:42:04     662707 gitea-persistent-1.tar.gz
2022-03-01 09:41:58       2632 velero-backup.json
$ aws --endpoint-url http://minio-velero.apps.ocp1.rhcnsa.com/ s3 ls s3://velero/velero/restic/gitea/
                           PRE data/
                           PRE index/
                           PRE keys/
                           PRE snapshots/
2022-03-01 10:45:57        155 config

# 下载备份内容
$ aws --endpoint-url http://minio-velero.apps.ocp1.rhcnsa.com/ s3 cp s3://velero/velero/backups/gitea-persistent-1/ /tmp --recursive


# 查看可用备份 
$ oc get backup -n openshift-adp 
NAME                 AGE
gitea-persistent-1   20m

# 从备份恢复
$ oc namespace default
$ oc delete project gitea

# 执行恢复
$ cat <<EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: gitea
  namespace: openshift-adp
spec:
  backupName: gitea-persistent-5
  excludedResources:
  - nodes
  - events
  - events.events.k8s.io
  - backups.velero.io
  - restores.velero.io
  - resticrepositories.velero.io
  restorePVs: true
EOF

# 查看执行情况
$ oc get restore gitea -n openshift-adp -o yaml 
apiVersion: velero.io/v1
kind: Restore
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"velero.io/v1","kind":"Restore","metadata":{"annotations":{},"name":"gitea","namespace":"openshift-adp"},"spec":{"backupName":"gitea-persistent-1","excludedResources":["nodes","events","events.events.k8s.io","backups.velero.io","restores.velero.io","resticrepositories.velero.io"],"restorePVs":true}}
  creationTimestamp: "2022-03-01T02:07:45Z"
  generation: 9
  name: gitea
  namespace: openshift-adp
  resourceVersion: "751808746"
  uid: 01a37941-8ccc-4ffe-9227-ea4538d8d469
spec:
  backupName: gitea-persistent-1
  excludedResources:
  - nodes
  - events
  - events.events.k8s.io
  - backups.velero.io
  - restores.velero.io
  - resticrepositories.velero.io
  restorePVs: true
status:
  completionTimestamp: "2022-03-01T02:08:28Z"
  phase: Completed
  progress:
    itemsRestored: 69
    totalItems: 69
  startTimestamp: "2022-03-01T02:07:45Z"
  warnings: 12

$ oc -n mysql-persistent-restic annotate pod/mysql-7d99fc949-zxz7r backup.velero.io/backup-volumes=mysql-data,kube-api-access-78zt8


# 查看 velero 版本
VELERO=$(oc -n openshift-adp get pods -l component=velero -o name | head -1) 
oc -n openshift-adp rsh $VELERO
sh-4.4# ./velero version
sh-4.4# ./velero backup get
NAME                 STATUS      ERRORS   WARNINGS   CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
gitea-persistent-5   Completed   0        0          2022-03-02 01:10:36 +0000 UTC   1d        dpa-sample-1       <none>

# 注意事项
# 在目标集群里需要创建与源集群同名的 StorageClass
# 因为迁移前的 PVC 如果包含 StorageClass，PVC 可以找到需要的 StorageClass

```