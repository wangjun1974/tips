### OpenShift Logging 的 Pods 的日志
```
# 查看 cluster-logging-operator 的日志
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l name=cluster-logging-operator -o name)

# 查看 kibana 的日志
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=kibana -o name) -c kibana
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=kibana -o name) -c kibana-proxy

# 查看 elasticsearch 的日志
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=elasticsearch -o name | head -1) -c elasticsearch
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=elasticsearch -o name | head -2 | tail -1 ) -c elasticsearch
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=elasticsearch -o name | tail -1 ) -c elasticsearch

# 查看 collector - fluentd 的日志
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=collector -o name | head -1) -c collector

# 访问 kibana 
oc -n openshift-logging get route kibana -ojsonpath='{"https://"}{.spec.host}{"\n"}'

# 配置 OpenShift Logging
# 参考同事的 Blog https://mp.weixin.qq.com/s/2aiHX3pz37sUV1GoWozn7Q

``` 

### 测试 multus on microshift
https://gist.github.com/usrbinkat/0f08e0600f9a9ff64bf46d1ec9251f23
```
cat <<EOF | kubectl apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: nadbr1
spec:
  config: '{"cniVersion":"0.3.1","name":"br1","plugins":[{"type":"bridge","bridge":"br1","ipam":{}},{"type":"tuning"}]}'
EOF

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod
  namespace: nginx-test
  annotations:
    k8s.v1.cni.cncf.io/networks: nadbr1
spec:
  containers:
  - name: samplepod
    command: ["/bin/ash", "-c", "trap : TERM INT; sleep infinity & wait"]
    image: alpine
EOF
```