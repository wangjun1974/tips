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

# 增加 Channel 的 spec.insecureSkipVerify 为 true
oc -n ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor-ns patch Channel ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor --type json -p '[{"op": "add", "path": "/spec/insecureSkipVerify", "value": true}]'
```