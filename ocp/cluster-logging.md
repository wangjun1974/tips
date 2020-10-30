### OCP 4.5 如何设置 OpenShift Logging
参见：https://docs.openshift.com/container-platform/4.5/logging/cluster-logging-deploying.html

大致的步骤为：
1. 安装 ElasticSearch Operator 和 Cluster Logging Operator
2. 创建 Cluster Logging Instance
3. 验证安装是否正确
4. 手工创建 kibana index patterns 和 visualizations

```
创建 Cluster Logging Instance
cat > clo-instance.yaml << EOF
apiVersion: "logging.openshift.io/v1"
kind: "ClusterLogging"
metadata:
  name: "instance" 
  namespace: "openshift-logging"
spec:
  managementState: "Managed"  
  logStore:
    type: "elasticsearch"  
    retentionPolicy: 
      application:
        maxAge: 1h
      infra:
        maxAge: 1h
      audit:
        maxAge: 1h
    elasticsearch:
      nodeCount: 3 
      storage:
        storageClassName: "nfs-storage-provisioner" 
        size: 10G
      redundancyPolicy: "SingleRedundancy"
  visualization:
    type: "kibana"  
    kibana:
      replicas: 1
  curation:
    type: "curator"
    curator:
      schedule: "30 3 * * *" 
  collection:
    logs:
      type: "fluentd"  
      fluentd: {}
EOF

oc apply -f ./clo-instance.yaml

默认 cluster logging operator 没有启用 audit log 
原因是内部 es 的存储不是加密存储
如果想启用 cluster logging operator 的 audit log，需要在 ClusterLogging instance 的 metadata 里添加 annotations: clusterlogging.openshift.io/logforwardingtechpreview: enabled

cat > clo-instance.yaml << EOF
apiVersion: "logging.openshift.io/v1"
kind: "ClusterLogging"
metadata:
  annotations:
    clusterlogging.openshift.io/logforwardingtechpreview: enabled
  name: "instance" 
  namespace: "openshift-logging"
spec:
  managementState: "Managed"  
  logStore:
    type: "elasticsearch"  
    retentionPolicy: 
      application:
        maxAge: 1h
      infra:
        maxAge: 1h
      audit:
        maxAge: 1h
    elasticsearch:
      nodeCount: 3 
      storage:
        storageClassName: "nfs-storage-provisioner" 
        size: 10G
      redundancyPolicy: "SingleRedundancy"
  visualization:
    type: "kibana"  
    kibana:
      replicas: 1
  curation:
    type: "curator"
    curator:
      schedule: "30 3 * * *" 
  collection:
    logs:
      type: "fluentd"  
      fluentd: {}
EOF

延续上一个话题，在 Cluster Logging 里启用 audit log，还需要定义 LogForwarding，在 pipeline 里添加 audit.pipeline

cat > clo-logforwarding-withaudit.yaml << EOF
apiVersion: logging.openshift.io/v1alpha1
kind: LogForwarding
metadata:
  name: instance
  namespace: openshift-logging
spec:
  disableDefaultForwarding: true
  outputs:
    - name: clo-es
      type: elasticsearch
      endpoint: 'elasticsearch.openshift-logging.svc:9200' 
      secret:
        name: fluentd
  pipelines:
    - name: audit-pipeline 
      inputSource: logs.audit
      outputRefs:
        - clo-es
    - name: app-pipeline 
      inputSource: logs.app
      outputRefs:
        - clo-es
    - name: infra-pipeline 
      inputSource: logs.infra
      outputRefs:
        - clo-es
EOF
```



```
确认安装是否正确
oc get pod -n openshift-logging --selector component=elasticsearch

确认 es status
oc get pod -n openshift-logging --selector component=elasticsearch --no-headers | awk '{print $1}' | while read i ; do oc exec -n openshift-logging -c elasticsearch  ${i} -- es_cluster_health ; done 

确认 cronjob 
oc -n openshift-logging get CronJob 

确认 es indices
oc get pod -n openshift-logging --selector component=elasticsearch --no-headers | awk '{print $1}' | while read i ; do oc exec -n openshift-logging -c elasticsearch  ${i} -- indices ; done

# 参考 Bug 1866490
# https://bugzilla.redhat.com/show_bug.cgi?id=1866490
# https://blog.csdn.net/weixin_43902588/article/details/105586460

```

```
手工创建 kibana index patterns 和 visualizations

# A user must have the cluster-admin role, the cluster-reader role, or both roles to list the infra and audit indices in Kibana.
$ oc auth can-i get pods/logs -n default
yes

# The audit logs are not stored in the internal OpenShift Container Platform Elasticsearch instance by default. To view the audit logs in Kibana, you must use the Log Forwarding API to configure a pipeline that uses the default output for audit logs.
# See: https://examples.openshift.pub/logging/forwarding-demo/
oc create -f - <<EOF
apiVersion: logging.openshift.io/v1alpha1
kind: LogForwarding
metadata:
  name: instance
  namespace: openshift-logging
spec:
  disableDefaultForwarding: true
  outputs:
    - name: fluentd-created-by-user
      type: forward
      endpoint: 'fluentd.fluentd.svc.cluster.local:24224'
  pipelines:
    - name: app-pipeline
      inputSource: logs.app
      outputRefs:
        - fluentd-created-by-user
    - name: infra-pipeline
      inputSource: logs.infra
      outputRefs:
        - fluentd-created-by-user
    - name: clo-default-audit-pipeline
      inputSource: logs.audit
      outputRefs:
        - fluentd-created-by-user
EOF

# 获取 logforwanding
oc -n openshift-logging get logforwarding $(oc get logforwarding -n openshift-logging -o jsonpath='{.items[0].metadata.name}{"\n"}') -o yaml

# In the OpenShift Container Platform console, click the Application Launcher app launcher and select Logging.

# Create your Kibana index patterns by clicking Management → Index Patterns → Create index pattern:
## Users must manually create index patterns to see logs for their projects. Users should create a new index pattern named app and use the @timestamp time field to view their container logs.
## Admin users must create index patterns for the app, infra, and audit indices using the @timestamp time field.

# Create Kibana Visualizations from the new index patterns.
https://bugzilla.redhat.com/show_bug.cgi?id=1867137<br>
https://docs.openshift.com/container-platform/4.5/logging/cluster-logging-upgrading.html<br>
https://medium.com/getting-started-with-the-elk-stack/introducing-kibana-59c6ddb3d085

首先确认 es 有 indices，在 kibana 里创建完 indices pattern 后，可调整 kibana Discover 页面的 Time Range 查看日志内容

另外遇到的问题包括
# https://bugzilla.redhat.com/show_bug.cgi?id=1866019
$ oc get pods -n openshift-logging | grep Error
elasticsearch-delete-infra-1603961100-54d7r     0/1     Error       0          58m

$ oc logs elasticsearch-delete-infra-1603961100-54d7r -n openshift-logging
oc logs elasticsearch-delete-infra-1603961100-54d7r -n openshift-logging                       
{"error":{"root_cause":[{"type":"security_exception","reason":"Unexpected exception indices:admin/aliases/get"}],"type":"security_exception","reason":"Unexpected exception indices:admin/aliases/get"},"status":500}
Error while attemping to determine the active write alias: {"error":{"root_cause":[{"type":"security_exception","reason":"Unexpected exception indices:admin/aliases/get"}],"type":"security_exception","reason":"Unexpected exception indices:admin/aliases/get"},"status":500}


删除 indices 
oc get pod -n openshift-logging --selector component=elasticsearch --no-headers | awk '{print $1}' | head -1 | while read pod ; do echo oc -n openshift-logging exec -c elasticsearch ${pod} -- es_util --query=infra-000002 -XDELETE; done 

确认 es indices
oc get pod -n openshift-logging --selector component=elasticsearch --no-headers | awk '{print $1}' | while read i ; do oc exec -n openshift-logging -c elasticsearch  ${i} -- indices ; done

fluentd 报错
oc logs fluentd-xh2z8 -n openshift-logging

2020-10-29 10:03:15 +0000 [warn]: [clo_default_output_es] failed to flush the buffer. retry_time=6 next_retry_seconds=2020-10-29 10:03:47 +0000 chunk="5b2cabb59c6178a072dd8eeebf3d9b22" error_class=Fluent::Plugin::ElasticsearchOutput::RecoverableRequestFailure error="could not push logs to Elasticsearch cluster ({:host=>\"elasticsearch.openshift-logging.svc.cluster.local\", :port=>9200, :scheme=>\"https\", :user=>\"fluentd\", :password=>\"obfuscated\"}): [400] {\"error\":{\"root_cause\":[{\"type\":\"illegal_argument_exception\",\"reason\":\"no write index is defined for alias [infra-write]. The write index may be explicitly disabled using is_write_index=false or the alias points to multiple indices without one being designated as a write index\"}],\"type\":\"illegal_argument_exception\",\"reason\":\"no write index is defined for alias [infra-write]. The write index may be explicitly disabled using is_write_index=false or the alias points to multiple indices without one being designated as a write index\"},\"status\":400}"
```