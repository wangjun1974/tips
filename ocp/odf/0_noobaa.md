# 设置 noobaa resource requests / limits 
```
# 在测试资源有限时，可以考虑设置 noobaa resource requests/limits 降低资源需求
oc edit storagecluster ocs-external-storagecluster -n openshift-storage

spec:
  externalStorage:
    enable: true
  labelSelector: {}
  resources:
    noobaa-core:
      limits:
        cpu: 1
        memory: 1Gi
      requests:
        cpu: 1
        memory: 1Gi
    noobaa-db:
      limits:
        cpu: 1
        memory: 1Gi
      requests:
        cpu: 1
        memory: 1Gi
    noobaa-endpoint:
      limits:
        cpu: 1
        memory: 1Gi
      requests:
        cpu: 1
        memory: 1Gi

Restart pods
```