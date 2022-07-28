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