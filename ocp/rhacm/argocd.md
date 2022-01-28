### 尝试一下 RHACM 与 ArgoCD 
参考：https://rcarrata.com/openshift/argo-and-acm/
```
1. 在 ACM Hub Cluster 安装 ArgoCD
until oc apply -k https://github.com/RedHat-EMEA-SSA-Team/ns-gitops/tree/bootstrap/bootstrap ; do sleep 2; done

```