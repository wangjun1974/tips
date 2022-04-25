### 文件夹结构
```
/opt/acm/
├── bin
│   └── cluster_operator.sh
├── clusters
│   ├── add
│   └── remove
├── hub
│   └── lb-ext.kubeconfig
└── secrets
    └── auth.json

# /opt/acm/bin/cluster_operator.sh
# 控制器，它会扫描目录 /opt/acm/clusters/add 和 /opt/acm/clusters/remove 下的配置文件，自动添加和删除集群
# 参见：https://github.com/wangjun1974/tips/blob/master/ocp/edge/cluster_operator.sh

# /opt/acm/hub/lb-ext.kubeconfig 是 hub 的 kubeconfig

# /opt/acm/secrets/auth.json 是访问 registry 的 pull secret，添加 cluster 时在 spoke cluster 里生成供 sa 使用的 pull secret

# /opt/acm/clusters/add 目录下存放要添加集群的配置文件

# /opt/acm/clusters/remove 目录下存放要删除集群的配置文件

# 配置文件格式
CLUSTER_NAME="edge-1"
cat > ${CLUSTER_NAME} <<'EOF'
CLUSTER_NAME="edge-1"
CLUSTER_KUBECONFIG="/opt/acm/clusters/${CLUSTER_NAME}/kubeconfig"
CLUSTER_API="8.130.18.107"
EOF

# 在控制器节点上通过定时任务执行 cluster_operator.sh
$ crontab -l 
*/5 * * * * /bin/bash /opt/acm/bin/cluster_operator.sh
```

### 添加集群时在 spoke cluster 执行
```
# 上传 edge-1 文件到远程主机的目录 /opt/acm/clusters/add 
# 远程主机的 cluster_operator.sh 会扫描这个目录里的文件，根据文件内容添加集群到 acm
# 在被添加的集群执行

add_cluster_to_acm()
# 定义环境变量
SSH_KEY="/root/.ssh/acm"
CLUSTER_NAME="edge-1"
REMOTE_HOST="8.140.106.163"
REMOTE_PORT="6022"
CLUSTER_API_IP="8.130.18.107"

# 生成 kubeconfig，用 CLUSTER_API 替换 127.0.0.1
mkdir -p ~/.kube
podman cp microshift:/var/lib/microshift/resources/kubeadmin/kubeconfig ~/.kube/config
sed -i "s|127.0.0.1|${CLUSTER_API_IP}|g" ~/.kube/config

# 生成配置文件
cat > ${CLUSTER_NAME} <<EOF
CLUSTER_NAME="edge-1"
CLUSTER_KUBECONFIG="/opt/acm/clusters/${CLUSTER_NAME}/kubeconfig"
CLUSTER_API="${CLUSTER_API_IP}"
EOF

# 上传配置文件和 kubeconfig
ssh -i ${SSH_KEY} -p ${REMOTE_PORT} ${REMOTE_HOST} mkdir -p /opt/acm/clusters/${CLUSTER_NAME}
scp -i ${SSH_KEY} -P ${REMOTE_PORT} ${CLUSTER_NAME} ${REMOTE_HOST}:/opt/acm/clusters/add
scp -i ${SSH_KEY} -P ${REMOTE_PORT} ~/.kube/config ${REMOTE_HOST}:/opt/acm/clusters/${CLUSTER_NAME}/kubeconfig
```

### 删除集群时在 spoke cluster 执行
```
# 上传 edge-1 文件到远程主机的目录 /opt/acm/clusters/remove 
# 远程主机的 cluster_operator.sh 程序会扫描这个目录里的文件，根据文件内容从 acm 删除集群
# 在被删除的集群执行

remove_cluster_from_acm()
# 定义环境变量
SSH_KEY="/root/.ssh/acm"
CLUSTER_NAME="edge-1"
REMOTE_HOST="8.140.106.163"
REMOTE_PORT="6022"
CLUSTER_API_IP="8.130.18.107"

# 生成配置文件
cat > ${CLUSTER_NAME} <<EOF
CLUSTER_NAME="edge-1"
CLUSTER_KUBECONFIG="/opt/acm/clusters/${CLUSTER_NAME}/kubeconfig"
CLUSTER_API="${CLUSTER_API_IP}"
EOF

# 上传配置文件和 kubeconfig
scp -i ${SSH_KEY} -P ${REMOTE_PORT} ${CLUSTER_NAME} ${REMOTE_HOST}:/opt/acm/clusters/remove
```

### 配置文件说明
```
# CLUSTER_NAME: 集群在 acm 内的名字 
# spoke cluster 通过 scp 上传配置文件到远程控制节点特定目录
# spoke cluster 与远程控制节点间通过 key 进行认证
# SSH_KEY: spoke cluster 向 ${REMOTE_HOST} 认证时要用到的 key，可以在系统安装时拷贝到系统里
# REMOTE_HOST: 上传文件的服务器
# REMOTE_PORT: 上传文件的端口
# CLUSTER_API_IP: spoke cluster 的 api endpoint，对于 microshift 来说，可以使用节点的 external ip
```
