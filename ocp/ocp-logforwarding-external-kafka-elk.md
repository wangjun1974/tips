# OpenShift 日志转发到外部 Kafka + ELK 
```
# 参考发哥的文档安装 OpenShift Logging
# 微信公众号：撞墙秀 
# OpenShift 日志组件的安装和使用
# https://mp.weixin.qq.com/s/2aiHX3pz37sUV1GoWozn7Q
# OpenShift转发日志到外部系统
# https://mp.weixin.qq.com/s/xA2Qn6DGp_SOsWzwh0w6jg

# 切换到 openshift-logging 项目
oc project openshift-logging

# 创建 ClusterLogging 实例
# 关于 resources/requests 和 resources/limits 可根据实际需要调整
# 以下设置仅为满足实验环境验证需要
cat << EOF | oc apply -f -
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
        maxAge: 2d
      audit:
        maxAge: 2d
    elasticsearch:
      nodeCount: 3 
      storage:
        size: 100G
      resources:
        limits:
          memory: 4Gi      
        requests:
          cpu: 1m
          memory: 1Gi
      proxy:
        resources:
          limits:
            memory: 256Mi
          requests:
            cpu: 1m
            memory: 256Mi
      redundancyPolicy: "SingleRedundancy"
  visualization:
    type: "kibana"  
    kibana:
      resources:
        limits:
          memory: 1Gi
        requests:
          cpu: 1m
          memory: 1Gi
      replicas: 1
  curation:
    type: "curator"
    curator:
      resources:
        limits:
          memory: 200Mi
        requests:
          cpu: 1m
          memory: 200Mi
      schedule: "30 3 * * *" 
  collection:
    logs:
      type: "fluentd"  
      fluentd:
        resources:
          limits:
            memory: 512Mi        
          requests:
            cpu: 1m
            memory: 256Mi     
EOF

# 安装 docker-ce
sudo amazon-linux-extras install docker
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker
sudo usermod -a -G docker ec2-user

# 安装 docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
export PATH=$PATH:/usr/local/bin

# 检查软件版本
docker version
docker-compose version

# 设置 vm.max_map_count
cd /root/
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 开放操作系统防火墙端口
iptables -A INPUT -i eth0 -p tcp --dport 9092 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 5601 -j ACCEPT

# 创建目录
mkdir kafka-elk
cd kafka-elk

# 生成 logstash.yml
# 注意：请使用实际网卡名替换 eth0，后续相同命令也需要同样替换
# CentOS 7 下如果未安装 ifconfig 工具，可执行命令 ‘yum install net-tools’ 安装
cat > logstash.yml << EOF
http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.hosts: [ "http://$(ifconfig eth0 | grep -E "inet "  | awk '{print $2}'):9200" ]

EOF

# 生成 logstash.conf
cat > logstash.conf << EOF
input { 
  kafka {
    bootstrap_servers => "kafka:9092"
    topics => ["app-logs","infra-logs","audit-logs"]
    codec => json
    decorate_events => true
  }
}

output {
  stdout { codec => rubydebug }
  elasticsearch {
    hosts => ["$(ifconfig eth0 | grep -E "inet "  | awk '{print $2}'):9200"]
    index => "%{[@metadata][kafka][topic]}-%{+YYYY.MM.dd}"
  }
}
EOF

# 生成 kibana 配置文件
# 注意：请使用实际网卡名替换 eth0，后续相同命令也需要同样替换
# 注意：elasticsearch.hosts 设置为 <宿主机IP:9200>
cat > kibana.yml << EOF
server.name: kibana
server.host: "0.0.0.0"
elasticsearch.hosts: [ "http://$(ifconfig eth0 | grep -E "inet "  | awk '{print $2}'):9200" ]
xpack.monitoring.ui.container.elasticsearch.enabled: true
EOF

# 注意：KAFKA_LISTENERS 设置为 PLAINTEXT://0.0.0.0:9092
# 注意：KAFKA_ADVERTISED_LISTENERS 设置为 PLAINTEXT://<容器主机IP>:9092
cat > docker-compose.yml << EOF
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
      nofile:
        soft: 65536
        hard: 65536    
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
      nofile:
        soft: 65536
        hard: 65536    
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
      nofile:
        soft: 65536
        hard: 65536    
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
    expose:
      - 5601      
    volumes:
      - type: bind
        source: ./kibana.yml
        target: /usr/share/kibana/config/kibana.yml
        read_only: true
    networks:
      - elastic

  zookeeper:
    image: zookeeper:3.7.0
    restart: always
    container_name: zookeeper
    ports:
      - 12181:2181
    expose:
      - 2181
    networks:
      - elastic

  kafka:
    image: bitnami/kafka:2.8.0
    restart: always
    container_name: kafka
    ports:
      - 9092:9092
    environment:
      - KAFKA_BROKER_ID=1
      - KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092
      - KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://$(ifconfig eth0 | grep -E "inet "  | awk '{print $2}'):9092
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_MESSAGE_MAX_BYTES=314572800
      - KAFKA_CREATE_TOPICS="app-logs:3:1,infra-logs:3:1,audit-logs:3:1"
      - ALLOW_PLAINTEXT_LISTENER=yes
    expose:
      - 9092
    depends_on:
      - zookeeper
    networks:
      - elastic

  kafka-manager:
    image: hlebalbau/kafka-manager:3.0.0.5
    container_name: kafka-manager
    ports:
      - 19000:9000
    environment:
      ZK_HOSTS: zookeeper:2181
      APPLICATION_SECRET: "admin"
    depends_on:
      - zookeeper
    networks:
      - elastic

  logstash:
    image: logstash:7.12.1
    container_name: logstash
    ports:
      - 5044:5044
      - 5000:5000/tcp
      - 5000:5000/udp
      - 9600:9600
    environment:
      LS_JAVA_OPTS: "-Xmx256m -Xms256m"
    volumes:
      - type: bind
        source: ./logstash.yml
        target: /usr/share/logstash/config/logstash.yml
        read_only: true
      - type: bind
        source: ./logstash.conf
        target: /usr/share/logstash/pipeline/logstash.conf
        read_only: true
    depends_on:
      - kafka
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
EOF

# 生成 ClusterLogForwarder 
# 根据实际情况设置EXTERNAL_KAFKA_BROKER，转发日志到 EXTERNAL_KAFKA_BROKER
export EXTERNAL_KAFKA_BROKER="xxx.compute.amazonaws.com.cn"

cat << EOF | oc apply -f -
apiVersion: logging.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: instance 
  namespace: openshift-logging 
spec:
  outputs:
   - name: app-logs 
     type: kafka 
     url: tcp://${EXTERNAL_KAFKA_BROKER}:9092/app-logs
   - name: infra-logs
     type: kafka
     url: tcp://${EXTERNAL_KAFKA_BROKER}:9092/infra-logs 
   - name: audit-logs
     type: kafka
     url: tcp://${EXTERNAL_KAFKA_BROKER}:9092/audit-logs
  pipelines:
   - name: app-topic 
     inputRefs: 
     - application
     outputRefs: 
     - app-logs
     labels:
       logType: application 
   - name: infra-topic 
     inputRefs:
     - infrastructure
     outputRefs:
     - infra-logs
     labels:
       logType: infra
   - name: audit-topic
     inputRefs:
     - audit
     outputRefs:
     - audit-logs
     - default 
     labels:
       logType: audit
EOF

# 查看 kafka 日志
docker logs kafka

# 查看 logstash 日志
docker logs logstash

# 查询 elasticsearch 所有索引
curl -X GET 'http://127.0.0.1:9200/_cat/indices?v&pretty=true'
health status index                      uuid                   pri rep docs.count docs.deleted store.size pri.store.size
yellow open   logstash-2021.05.10-000001 BUqK_dGvSAuhxrzulOTFqA   1   1     460011            0    265.8mb        265.8mb

# 查看 kibana 日志
docker logs kibana

# 访问 kibana Web 界面
# Management -> StackManagement -> Kibana -> Index Patterns 
# 创建 Index Patterns
# Index pattern name: logstash-*, app-*, infra-*, audit-*
# Time field: @timestamp
# 创建完成后，访问
# Discover 

# ClusterLogging 资源详细定义的例子
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

# 多个 docker-compose 启动 ES + Kafka 
# 参见：https://mp.weixin.qq.com/s/xA2Qn6DGp_SOsWzwh0w6jg
```