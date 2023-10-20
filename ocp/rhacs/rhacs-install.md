### install rhacs
### 参考: https://blog.csdn.net/weixin_43902588/article/details/121772253
### 参考: https://redhat-scholars.github.io/acs-workshop/acs-workshop/index.html
### 参考: https://github.com/rcarrata/devsecops-demo
### 参考: https://github.com/RedHatDemos/SecurityDemos/blob/master/2021Labs/OpenShiftSecurity/documentation/lab4.adoc
```
### 安装 RHACS operator

### 创建 namespace stackrox
$ oc new-project stackrox

### 创建 Central
cat <<EOF | oc apply -f -
apiVersion: platform.stackrox.io/v1alpha1
kind: Central
metadata:
  name: stackrox-central-services
  namespace: stackrox
spec:
  central:
    exposure:
      loadBalancer:
        enabled: false
        port: 443
      nodePort:
        enabled: false
      route:
        enabled: true
    persistence:
      persistentVolumeClaim:
        claimName: stackrox-db
  egress:
    connectivityPolicy: Online
  scanner:
    analyzer:
      scaling:
        autoScaling: Enabled
        maxReplicas: 5
        minReplicas: 2
        replicas: 3
    scannerComponent: Enabled
EOF

### 获取 admin 口令
$ oc get secret central-htpasswd -n stackrox -o go-template='{{index .data "password" | base64decode}}'

### 导入集群
### Integrations -> 'Cluster Init Bundle' -> 'Generate Bundle' -> 'Download Kubernetes secret files'
$ oc apply -f demo-cluster-cluster-init-secrets.yaml -n stackrox
secret/admission-control-tls created
secret/collector-tls created
secret/sensor-tls created

### 创建 Secured Cluster
$ cat <<EOF | oc apply -f -
kind: SecuredCluster
apiVersion: platform.stackrox.io/v1alpha1
metadata:
  name: stackrox-secured-cluster-services
  namespace: stackrox
spec:
  clusterName: local-cluster
EOF

```