### OCP 4.5 如何设置 OpenShift Logging
参见：https://docs.openshift.com/container-platform/4.5/logging/cluster-logging-deploying.html

大致的步骤为：
1. 安装 ElasticSearch Operator 和 Cluster Logging Operator
2. 创建 Cluster Logging Instance
3. 验证安装是否正确
4. 手工创建 kibana index patterns 和 visualizations

