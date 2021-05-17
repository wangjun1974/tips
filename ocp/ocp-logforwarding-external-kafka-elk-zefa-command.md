```
OpenShift转发日志到外部系统
原创 jonkey

简介
OpenShift的日志组件（OpenShift Logging）基于EFK（ElasticSearch, FluentD, Kibana）；
集群安装完成后，日志组件需要单独安装可以参考（OpenShift日志组件的安装与使用：https://mp.weixin.qq.com/s/2aiHX3pz37sUV1GoWozn7Q ）；在特定的情况下，需要把集群应用的日志存储在集群外；本文是在OpenShift集群的日志组件（OpenShift Logging）安装后，配置日志转发到集群外部日志系统ELK的过程记录。

前置条件
 OpenShift 4.x环境
 具备OpenShift的管理员权限
 CentOS虚拟机 2C16G(模拟外部日志系统)

安装外部日志系统
本次尝试的集群外部日志系统为：ES + Kibana + Logstash + Kafka

环境准备

工具安装
yum -y install wget vim yum-utils

添加主机名称
vim /etc/hosts

虚拟机的地址为192.168.1.245
192.168.1.245 logging.example.com

安装docker-ce
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum -y install docker-ce

安装docker-compose
wget https://github.com/docker/compose/releases/download/1.29.1/docker-compose-Linux-x86_64
mv docker-compose-Linux-x86_64 docker-compose
chmod +x docker-compose
cp docker-compose /usr/local/bin/

自动配置
systemctl enable docker
systemctl start docker
systemctl status docker

版本检查
docker version
docker-compose version

图片

针对ES的系统参数调整
echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf
sysctl -p

开同kafka和kibana端口
firewall-cmd --add-port=9092/tcp --permanent
firewall-cmd --add-port=5601/tcp --permanent
firewall-cmd --reload

启动ES和Kibana

创建特定目录
mkdir /root/es
cd /root/es

准备启动配置
vim docker-compose.yml

version: "3"
services:
  es01:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.12.1
    container_name: es01
    environment:
      - node.name=es01
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es02,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es-data01:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - elastic

  es02:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.12.1
    container_name: es02
    environment:
      - node.name=es02
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es01,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es-data02:/usr/share/elasticsearch/data
    networks:
      - elastic

  es03:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.12.1
    container_name: es03
    environment:
      - node.name=es03
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es01,es02
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es-data03:/usr/share/elasticsearch/data
    networks:
      - elastic

  kibana:
    image: docker.elastic.co/kibana/kibana:7.12.1
    container_name: kibana
    ports:
      - 5601:5601
    environment:
      ELASTICSEARCH_URL: http://es01:9200
      ELASTICSEARCH_HOSTS: '["http://es01:9200","http://es02:9200","http://es03:9200"]'
    depends_on:
      - es01
      - es02
      - es03
    networks:
      - elastic

volumes:
  es-data01:
    driver: local
  es-data02:
    driver: local
  es-data03:
    driver: local

networks:
  elastic:
    driver: bridge

启动
docker-compose up


启动Kafka

创建特定目录
mkdir /root/kafka
cd /root/kafka

准备启动配置
vim docker-compose.yml

version: "3"
services:
  zookeeper:
    image: bitnami/zookeeper:3.7.0
    restart: always
    container_name: zookeeper
    ports:
      - 2181:2181
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes
    networks:
      - elastic

  kafka:
    image: 'bitnami/kafka:2.8.0'
    restart: always
    container_name: kafka
    ports:
      - 9092:9092
    environment:
      - KAFKA_BROKER_ID=0
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://logging.example.com:9092
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_CFG_MESSAGE_MAX_BYTES=314572800
      - ALLOW_PLAINTEXT_LISTENER=yes
    depends_on:
      - zookeeper
    networks:
      - elastic

networks:
  elastic:
    driver: bridge

启动
docker-compose up


启动Logstash

创建目录
mkdir /root/logstash
cd /root/logstash

准备应用配置文件
vim logstash.yml

http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.hosts: [ "http://logging.example.com:9200" ]

准备pipeline文件
vim logstash.conf

input {
  kafka {
    bootstrap_servers => "logging.example.com:9092"
    topics => ["app-logs","infra-logs","audit-logs"]
    codec => json
    decorate_events => true
  }
}
output {
  stdout { codec => rubydebug }
  elasticsearch {
    hosts => ["logging.example.com:9200"]
    index => "%{[@metadata][kafka][topic]}-%{+YYYY.MM.dd}"
  }
}

准备启动配置文件
vim docker-compose.yml

version: "3"
services:
  logstash:
    image: logstash:7.12.1
    container_name: logstash
    ports:
      - 5044:5044
      - 5000:5000/tcp
      - 5000:5000/udp
      - 9600:9600
    environment:
      LS_JAVA_OPTS: "-Xmx512m -Xms256m"
    volumes:
      - type: bind
        source: ./logstash.yml
        target: /usr/share/logstash/config/logstash.yml
        read_only: true
      - type: bind
        source: ./logstash.conf
        target: /usr/share/logstash/pipeline/logstash.conf
        read_only: true

启动
docker-compose up

配置日志转发

日志组件参数调整

日志组件安装详情请参考：https://mp.weixin.qq.com/s/2aiHX3pz37sUV1GoWozn7Q
Fluentd的内存本次调整为limits: 512Mi


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
        maxAge: 1d
      infra:
        maxAge: 7d
      audit:
        maxAge: 7d
    elasticsearch:
      nodeCount: 3
      resources:
        limits:
          memory: 4Gi
        requests:
          cpu: 500m
          memory: 4Gi
      storage:
        size: "200G"
      redundancyPolicy: "SingleRedundancy"
  visualization: 
    type: "kibana"
    kibana:
      resources:
        limits:
          memory: 512Mi
        requests:
          cpu: 100m
          memory: 512Mi
      replicas: 1
  curation: 
    type: "curator"
    curator:
      resources:
        limits:
          memory: 256Mi
        requests:
          cpu: 100m
          memory: 256Mi
      schedule: "30 3 * * *"
  collection: 
    logs:
      type: "fluentd"
      fluentd:
        resources:
          limits:
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 256Mi

日志转发配置


apiVersion: logging.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  namespace: openshift-logging
  name: instance
spec:
  outputs:
    - name: kafka-app-logs
      type: kafka
      url: 'tcp://logging.example.com:9092/app-logs'
    - name: kafka-infra-logs
      type: kafka
      url: 'tcp://logging.example.com:9092/infra-logs'
    - name: kafka-audit-logs
      type: kafka
      url: 'tcp://logging.example.com:9092/audit-logs'
  pipelines:
    - name: forward-to-kafka-app-logs
      inputRefs:
        - application
      outputRefs:
        - kafka-app-logs
        - default
    - name: forward-to-kafka-infra-logs
      inputRefs:
        - infrastructure
      outputRefs:
        - kafka-infra-logs
        - default
    - name: forward-to-kafka-audit-logs
      inputRefs:
        - audit
      outputRefs:
        - kafka-audit-logs

验证

Logstash日志输出

登录kibana：http://logging.example.com:5601
导航到索引创建页面
创建索引如下索引
app*
infra*
audit*

导航到discover页面
可以看到，已经可以检索日志了

说明
本次安装的集群外部日志系统（ES + Kibana + Logstash + Kafka），是以验证为目的，不适用于生产环境。


OpenShift日志组件的安装与使用
原创 jonkey

简介
OpenShift的日志组件（OpenShift Logging）基于EFK（ElasticSearch, FluentD, Kibana）；OpenShift Logging 聚合了以下类型的日志：
§ application – 集群上应用日志
§ infrastructure – 集群的基础组件日志
§ audit – 集群节点审计日志。
OpenShift集群安装完成后，默认开启了监控组件，日志组件需要单独安装；本文是在OpenShift集群上安装与使用日志组件（OpenShift Logging）的过程记录。

前置条件
  OpenShift 4.x环境
  具备OpenShift的管理员权限

安装Elasticsearch Operator
搜索获取 OpenShift Elasticsearch Operator
安装5.0.2版本
选择安装模式为：All namespaces
安装成功

安装OpenShift Logging Operator
搜索获取Red Hat OpenShift Logging
安装5.0.2版本
开启对所安装项目的集群级别监控
安装成功

创建 OpenShift Logging 实例
在项目openshift-logging的已安装Red Hat OpenShift Logging下，创建ClusterLogging实例
输入ClusterLogging资源定义文件

ClusterLogging资源定义详情如下：

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
        maxAge: 1d
      infra:
        maxAge: 7d
      audit:
        maxAge: 7d
    elasticsearch:
      nodeCount: 3
      resources:
        limits:
          memory: 4Gi
        requests:
          cpu: 500m
          memory: 4Gi
      storage:
        size: "200G"
      redundancyPolicy: "SingleRedundancy"
  visualization: 
    type: "kibana"
    kibana:
      resources:
        limits:
          memory: 512Mi
        requests:
          cpu: 100m
          memory: 512Mi
      replicas: 1
  curation: 
    type: "curator"
    curator:
      resources:
        limits:
          memory: 256Mi
        requests:
          cpu: 100m
          memory: 256Mi
      schedule: "30 3 * * *"
  collection: 
    logs:
      type: "fluentd"
      fluentd:
        resources:
          limits:
            memory: 256Mi
          requests:
            cpu: 100m
            memory: 256Mi

已创建的日志组件资源情况
已创建的pod情况

导航到日志工程的路由定义页面
访问kibana：https://kibana-openshift-logging.apps.okd.example.com/
创建 app-* 日志索引
根据时间戳索引

根据时间戳创建 infra-* 日志索引
索引创建完成

导航到应用的日志页面
点击Show in Kibana，进行日志查看
```
