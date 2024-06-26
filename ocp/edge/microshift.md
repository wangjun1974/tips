### microshift
https://blog.csdn.net/weixin_43902588/article/details/122190458
```
# 挂载 rhel 8.4 ISO
mount /dev/sr0 /mnt

# 创建软件仓库
cat > /etc/yum.repos.d/local.repo <<EOF
[baseos]
name=baseos
baseurl=file:///mnt/BaseOS
enabled=1
gpgcheck=0

[appstream]
name=appstream
baseurl=file:///mnt/AppStream
enabled=1
gpgcheck=0
EOF

# 安装基本工具
yum install -y tar gzip conntrack-tools socat

# 下载 cri-o 和 cri-tools
# 链接: https://pan.baidu.com/s/1MmoDE-AHImulV9Zvs9fzSg?pwd=3rd6 提取码: 3rd6

# 安装 cri-o cri-tools
yum localinstall -y cri-o-1.21.6-3.1.el8.x86_64.rpm cri-tools-1.23.0-.el8.1.3.x86_64.rpm
systemctl enable crio --now

# 安装 podman
sudo dnf install -y podman

# 添加防火墙规则
sudo firewall-cmd --zone=trusted --add-source=10.42.0.0/16 --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5353/udp --permanent
sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
sudo firewall-cmd --zone=public --permanent --add-port=30000-32767/tcp
sudo firewall-cmd --reload

# 忽略离线镜像仓库 ‘reistry.access.redhat.com' 和 'registry.redhat.io' 的证书签名检查
# crictl pull registry.redhat.io/rhacm2/registration-rhel8-operator@sha256:3c5d2c6d885a6a03b10952fb12002ac160f859bec0d6fe6f1cc58c545dd3aa9b
# FATA[0010] pulling image: rpc error: code = Unknown desc = Source image rejected: A signature was required, but no signature exists
cat > /etc/containers/policy.json <<EOF
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker-daemon": {
            "": [
                {
                    "type": "insecureAcceptAnything"
                }
            ]
        }
    }
}
EOF

# 将镜像同步到本地，离线环境需同步镜像到本地，在线环境无需执行
LOCAL_SECRET_JSON=/data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json

# quay.io/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920 docker://registry.example.com:5000/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920

# quay.io/microshift/flannel-cni:4.8.0-0.okd-2021-10-10-030117
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/microshift/flannel-cni:4.8.0-0.okd-2021-10-10-030117 docker://registry.example.com:5000/microshift/flannel-cni:4.8.0-0.okd-2021-10-10-030117

# quay.io/coreos/flannel:v0.14.0
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/coreos/flannel:v0.14.0 docker://registry.example.com:5000/coreos/flannel:v0.14.0

# quay.io/kubevirt/hostpath-provisioner:v0.8.0
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/kubevirt/hostpath-provisioner:v0.8.0 docker://registry.example.com:5000/kubevirt/hostpath-provisioner:v0.8.0

# quay.io/openshift/okd-content@sha256:bcdefdbcee8af1e634e68a850c52fe1e9cb31364525e30f5b20ee4eacb93c3e8
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/openshift/okd-content@sha256:bcdefdbcee8af1e634e68a850c52fe1e9cb31364525e30f5b20ee4eacb93c3e8 docker://registry.example.com:5000/openshift/okd-content@sha256:bcdefdbcee8af1e634e68a850c52fe1e9cb31364525e30f5b20ee4eacb93c3e8

# quay.io/openshift/okd-content@sha256:459f15f0e457edaf04fa1a44be6858044d9af4de276620df46dc91a565ddb4ec
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/openshift/okd-content@sha256:459f15f0e457edaf04fa1a44be6858044d9af4de276620df46dc91a565ddb4ec docker://registry.example.com:5000/openshift/okd-content@sha256:459f15f0e457edaf04fa1a44be6858044d9af4de276620df46dc91a565ddb4ec

# quay.io/openshift/okd-content@sha256:27f7918b5f0444e278118b2ee054f5b6fadfc4005cf91cb78106c3f5e1833edd
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/openshift/okd-content@sha256:27f7918b5f0444e278118b2ee054f5b6fadfc4005cf91cb78106c3f5e1833edd docker://registry.example.com:5000/openshift/okd-content@sha256:27f7918b5f0444e278118b2ee054f5b6fadfc4005cf91cb78106c3f5e1833edd

# quay.io/openshift/okd-content@sha256:01cfbbfdc11e2cbb8856f31a65c83acc7cfbd1986c1309f58c255840efcc0b64
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/openshift/okd-content@sha256:01cfbbfdc11e2cbb8856f31a65c83acc7cfbd1986c1309f58c255840efcc0b64 docker://registry.example.com:5000/openshift/okd-content@sha256:01cfbbfdc11e2cbb8856f31a65c83acc7cfbd1986c1309f58c255840efcc0b64

# quay.io/openshift/okd-content@sha256:dd1cd4d7b1f2d097eaa965bc5e2fe7ebfe333d6cbaeabc7879283af1a88dbf4e
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/openshift/okd-content@sha256:dd1cd4d7b1f2d097eaa965bc5e2fe7ebfe333d6cbaeabc7879283af1a88dbf4e docker://registry.example.com:5000/openshift/okd-content@sha256:dd1cd4d7b1f2d097eaa965bc5e2fe7ebfe333d6cbaeabc7879283af1a88dbf4e

# k8s.gcr.io/pause:3.5
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://k8s.gcr.io/pause:3.5 docker://registry.example.com:5000/pause/pause:3.5


# 生成 /etc/containers/registries.conf 使用本地镜像仓库镜像
cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ['registry.example.com:5000']
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift/okd-content"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/openshift/okd-content"

[[registry]]
  prefix = ""
  location = "quay.io/microshift/flannel-cni"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/microshift/flannel-cni"

[[registry]]
  prefix = ""
  location = "quay.io/coreos/flannel"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/coreos/flannel"    

[[registry]]
  prefix = ""
  location = "quay.io/kubevirt/hostpath-provisioner"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/kubevirt/hostpath-provisioner"

[[registry]]
  prefix = ""
  location = "k8s.gcr.io/pause"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/pause/pause"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2"

[[registry]]
  prefix = ""
  location = "k8s.gcr.io/pause"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/pause/pause"
EOF

# 生成 ~/.docker/config.json
mkdir -p ~/.docker
cat > ~/.docker/config.json <<EOF
{"auths":{"registry.example.com:5000":{"auth":"b3BlbnNoaWZ0OnJlZGhhdA=="}}}
EOF

# 拷贝 registry.example.com 的证书信任
scp registry.example.com:/etc/pki/ca-trust/source/anchors/registry.crt /etc/pki/ca-trust/source/anchors
update-ca-trust

# 尝试拉取 registry.example.com:5000/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920
podman pull registry.example.com:5000/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920

# 生成 /etc/systemd/system/microshift.service，引用本地镜像 registry.example.com:5000/microshift/microshift:<imagetag>
cat > /etc/systemd/system/microshift.service <<'EOF'
[Unit]
Description=MicroShift Containerized
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target crio.service
After=network-online.target crio.service
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/usr/bin/mkdir -p /var/lib/kubelet ; /usr/bin/mkdir -p /var/hpvolumes
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon --rm --replace --sdnotify=container --label io.containers.autoupdate=registry --network=host --privileged -d --name microshift -v /var/hpvolumes:/var/hpvolumes:z,rw,rshared -v /var/run/crio/crio.sock:/var/run/crio/crio.sock:rw,rshared -v microshift-data:/var/lib/microshift:rw,rshared -v /var/lib/kubelet:/var/lib/kubelet:z,rw,rshared -v /var/log:/var/log -v /etc:/etc registry.example.com:5000/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=multi-user.target default.target
EOF
systemctl enable microshift --now
systemctl start microshift

# 下载 oc 客户端
# 链接: https://pan.baidu.com/s/1TRglppWcdqm9harAOZalfA?pwd=azdr 提取码: azdr
sudo tar zxf openshift-client-linux-4.9.26.tar.gz -C /usr/local/bin oc kubectl

# 拷贝 kubeconfig
mkdir ~/.kube
podman cp microshift:/var/lib/microshift/resources/kubeadmin/kubeconfig ~/.kube/config
chown `whoami`: ~/.kube/config

# 拷贝 kubeconfig 到 helper
# 这里 edge-x 可以是 edge-1/edge-2/edge-3/...
# EDGE_X_IP 是 microshift 节点的 IP
(helper)$ mkdir -p ~/kubeconfig/edge/<edge-x>
(helper)$ scp <edge-x>:~/.kube/config ~/kubeconfig/edge/<edge-x>/kubeconfig
(helper)$ EDGE_X_IP="aaa.bbb.ccc.ddd"
(helper)$ sed -i "s|127.0.0.1|${EDGE_X_IP}|g" ~/kubeconfig/edge/<edge-x>/kubeconfig

# 查看对象
oc get project 
NAME                           DISPLAY NAME   STATUS
default                                       Active
kube-node-lease                               Active
kube-public                                   Active
kube-system                                   Active
openshift                                     Active
openshift-controller-manager                  Active
openshift-infra                               Active
openshift-node                                Active

# 查看 microshift 版本
# oc version 
Client Version: 4.9.9
Kubernetes Version: v1.21.1

# 拷贝 quay.io/tasato/hello-js 到 registry.example.com:5000/tasato/hello-js
LOCAL_SECRET_JSON=/data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/tasato/hello-js:latest docker://registry.example.com:5000/tasato/hello-js:latest

# 在 DNS 上添加 edge-1 的解析
cat >> /etc/named.rfc1912.zones <<EOF
zone "edge-1.example.com" IN {
        type master;
        file "edge-1.example.com.zone";
        allow-transfer { any; };
};

EOF

nmcli con mod 'System eth0' +ipv4.address "192.168.122.32/24"
cat > /var/named/edge-1.example.com.zone <<'EOF'
$ORIGIN edge-1.example.com.
$TTL 1D
@           IN SOA  edge-1.example.com. admin.edge-1.example.com. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum

@             IN NS                         dns.example.com.

lb             IN A                          192.168.122.32
api            IN A                          192.168.122.32
api-int        IN A                          192.168.122.32
*.apps         IN A                          192.168.122.32

master-0       IN A                          192.168.122.203
microshift-demo IN A                          192.168.122.203

EOF


cat >> /var/named/168.192.in-addr.arpa.zone  <<'EOF'

203.122.168.192.in-addr.arpa.    IN PTR      master-0.edge-1.example.com.

203.122.168.192.in-addr.arpa.    IN PTR      microshift-demo.edge-1.example.com.

EOF

systemctl restart named

# 在负载均衡节点上添加 edge-1 的流量
# 配置 haproxy 
cat >> /etc/haproxy/haproxy.cfg <<EOF
frontend  openshift-api-server-edge-1
    bind lb.edge-1.example.com:6443
    mode tcp
    option tcplog
    default_backend openshift-api-server-edge-1

frontend  ingress-http-edge-1
    bind lb.edge-1.example.com:80
    mode tcp
    option tcplog
    default_backend ingress-http-edge-1

frontend  ingress-https-edge-1
    bind lb.edge-1.example.com:443
    mode tcp
    option tcplog
    default_backend ingress-https-edge-1

backend openshift-api-server-edge-1
    balance source
    mode tcp
    server     master-0 master-0.edge-1.example.com:6443 check

backend ingress-http-edge-1
    balance source
    mode tcp
    server     master-0 master-0.edge-1.example.com:80 check

backend ingress-https-edge-1
    balance source
    mode tcp
    server     master-0 master-0.edge-1.example.com:443 check
EOF
systemctl restart haproxy

# 在 edge-1 节点上添加防火墙规则
sudo firewall-cmd --zone=trusted --add-source=10.42.0.0/16 --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5353/udp --permanent
sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
sudo firewall-cmd --zone=public --permanent --add-port=30000-32767/tcp
sudo firewall-cmd --reload

# 创建测试程序
oc new-project test
oc create deploy hello --image=registry.example.com:5000/tasato/hello-js:latest
oc expose deploy hello --port 8080
# 暴露路由，指定路由使用的 hostname
oc expose svc hello --hostname=hello.apps.edge-1.example.com
oc get route

# 访问 hello.apps.edge-1.example.com
curl $(oc get route hello -n test -o jsonpath='{"http://"}{.spec.host}{"\n"}')
Hello ::ffff:10.42.0.1 from hello-bc68c5c66-94g7r

### 将 microshift 与 acm 集成在一起
# https://microshift.io/docs/user-documentation/how-tos/acm-with-microshift/
### Hub

### 导入 cluster 之前请先检查集群时间是否同步
### Hub and Managed Cluster

# 创建 edge-1 cluster
export CLUSTER_NAME=edge-1
oc --kubeconfig=<hub-kubeconfig> new-project ${CLUSTER_NAME}
oc --kubeconfig=<hub-kubeconfig> label namespace ${CLUSTER_NAME} cluster.open-cluster-management.io/managedCluster=${CLUSTER_NAME}

# 定义 Cluster
cat <<EOF | oc --kubeconfig=<hub-kubeconfig> apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${CLUSTER_NAME}
  namespace: ${CLUSTER_NAME}
spec:
  clusterName: ${CLUSTER_NAME}
  clusterNamespace: ${CLUSTER_NAME}
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: true
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  iamPolicyController:
    enabled: true
  policyController:
    enabled: true
  searchCollector:
    enabled: true
  version: 2.2.0
EOF

cat <<EOF | oc --kubeconfig=<hub-kubeconfig> apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${CLUSTER_NAME}
spec:
  hubAcceptsClient: true
EOF

# 上面的命令在 ${CLUSTER_NAME} namespace 下生成 secret ${CLUSTER_NAME}-import 
# 导出 import.yaml 和 crds.yaml 
IMPORT=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.import\.yaml}')
CRDS=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.crds\.yaml}')

### 在 edge-1 创建 open-cluster-management-agent namespace，创建 serviceaccount，修改 imagePullSecrets
podman login registry.example.com:5000 --authfile=./auth.json
oc new-project open-cluster-management-agent
oc -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc -n open-cluster-management-agent create sa klusterlet
oc -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc -n open-cluster-management-agent create sa klusterlet-registration-sa
oc -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc -n open-cluster-management-agent create sa klusterlet-work-sa
oc -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

### 在 edge-1 创建 open-cluster-management-agent-addon namespace， 创建 serviceaccount，修改 imagePullSecrets
oc new-project open-cluster-management-agent-addon
oc -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
oc -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

### 在 edge-1 切换到 open-cluster-management-agent namespace
oc project open-cluster-management-agent
echo $CRDS | base64 -d | oc apply -f -
echo $IMPORT | base64 -d | oc apply -f -

### 在 edge-1 切换到 open-cluster-management-agent-addon namespace
oc project open-cluster-management-agent-addon
for sa in klusterlet-addon-appmgr klusterlet-addon-certpolicyctrl klusterlet-addon-iampolicyctrl-sa klusterlet-addon-policyctrl klusterlet-addon-search klusterlet-addon-workmgr ; do
  oc -n open-cluster-management-agent-addon patch sa $sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
done
oc delete pod --all -n open-cluster-management-agent-addon
```

### 在 Hub 上清理 edge-1
```
CLUSTER_NAME='edge-1'
oc delete ManagedCluster ${CLUSTER_NAME}
```

### 配置 MicroShift 的说明
https://microshift.io/docs/user-documentation/configuring/<br>

```
mkdir -p /etc/microshift
cat > /etc/microshift/config.yaml <<EOF
--- 
dataDir: /tmp/microshift/data
LogDir: /tmp/microshift/logs
logVLevel: 4
nodeName: master-0.edge-1.rhcnsa.com
nodeIP: '8.130.18.10'
cluster:
  url: https://8.130.18.10:6443
  clusterCIDR: '10.42.0.0/16'
  serviceCIDR: '10.43.0.0/16'
  dns: '10.43.0.10'
  domain: apps.edge-1.rhcnsa.com
EOF
```

### 为 serviceaccount 指定 imagePullSecrets
```
Alright this worked oc patch -n openshift-marketplace sa redhat-operators -p '{"imagePullSecrets": [{"name": "openshift-pull-secret"}]}' but running into other problems. But At least I'm over this hump
```

### 为 edge cluster 安装 argocd core
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml
```

### 为 Mac OSX 防火墙添加规则
https://blog.neilsabol.site/post/quickly-easily-adding-pf-packet-filter-firewall-rules-macos-osx/<br>
https://srobb.net/pf.html<br>
```
# 如果使用 Docker Desktop 在 mac 上运行 microshift 不需要调整 mac 的防火墙规则
# 但是保留用于说明如何通过命令行调整 Mac 的防火墙规则
# 每次打开 Mac 都需要执行
sudo cp /etc/pf.conf /etc/pf.conf.bak

# 编辑 /etc/pf.conf 文件，在文件末尾添加以下规则

#
# Your own rules here
#
# sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
# sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
# sudo firewall-cmd --zone=public --add-port=5353/udp --permanent
# sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
# sudo firewall-cmd --zone=public --permanent --add-port=30000-32767/tcp

# Allow port 80 tcp access
pass in inet proto tcp from any to any port 80 no state

# Allow port 443 tcp access
pass in inet proto tcp from any to any port 443 no state

# Allow port 5333 udp access
pass in inet proto udp from any to any port 5333 no state

# Allow port 6443 tcp access
pass in inet proto tcp from any to any port 6443 no state

# Allow port 30000-32767 tcp access
pass in inet proto tcp from any to any port 30000:32767 no state

# Trust subnet 10.42.0.0/16
pass in inet proto tcp from 10.42.0.0/16 to any port 0:65535 no state
pass in inet proto udp from 10.42.0.0/16 to any port 0:65535 no state
pass in inet proto tcp from any to 10.42.0.0/16 port 0:65535 no state
pass in inet proto udp from any to 10.42.0.0/16 port 0:65535 no state

# 重新加载规则
sudo pfctl -f /etc/pf.conf
```

### 在 Mac OS 上启动 microshift
```
# 启动 microshift 
docker run -d --rm --name microshift --privileged -v microshift-data:/var/lib -p 6443:6443 quay.io/microshift/microshift-aio:latest

# 启动 microshift 时指定

# 待探索
# https://golangexample.com/connect-directly-to-docker-for-mac-containers-via-ip-address/
# 启动 microshift - Mac Docker Desktop 下容器连接的是虚拟机里的网络
docker run -d --rm --name microshift --net=host --privileged -v microshift-data:/var/lib -p 6443:6443 quay.io/microshift/microshift-aio:latest

# 拷贝 kubeconfig
docker cp microshift:/var/lib/microshift/resources/kubeadmin/kubeconfig ./kubeconfig
oc get all -A --kubeconfig ./kubeconfig
```

### 替换默认通配域名
https://github.com/redhat-et/microshift/issues/614#issuecomment-1059821598
```
oc project openshift-ingress
oc edit deployment router-default
...
        - name: ROUTER_SUBDOMAIN
          value: ${name}-${namespace}.apps.edge-1.example.com
        - name: ROUTER_ALLOW_WILDCARD_ROUTES
          value: "true"
        - name: ROUTER_OVERRIDE_HOSTNAME
          value: "true"
...
```

### openshift-service-ca pod 报错处理 
```
# 如果 pod 日志有报错
# W0412 02:23:13.288571       1 reflector.go:436] k8s.io/client-go/informers/factory.go:134: watch of *v1.MutatingWebhookConfiguration ended with: very short watch: k8s.io/client-go/informers/factory.go:134: Unexpected watch close - watch lasted less than a second and no items received
# W0412 02:23:13.288625       1 reflector.go:436] k8s.io/kube-aggregator/pkg/client/informers/externalversions/factory.go:117: watch of *v1.APIService ended with: very short watch: k8s.io/kube-aggregator/pkg/client/informers/externalversions/factory.go:117: Unexpected watch close - watch lasted less than a second and no items received
# 可以删除重建 pod，这个步骤不对，问题不是出在 openshift-service-ca pod 本身
oc -n openshift-service-ca delete $(oc -n openshift-service-ca get pods -l app=service-ca -o name)
oc -n openshift-service-ca logs $(oc -n openshift-service-ca get pods -l app=service-ca -o name) 

# 检查 pod 的 IP，删除 ip 为 10.85 的 pod
# https://github.com/redhat-et/microshift/issues/356
oc get pods -A -o wide
oc get pods -A -o wide | grep -Ev "NAME|192|10.42" | awk '{print $1" "$2}' | while read namespace podname ; do oc -n $namespace delete pod $podname ; done

# 在 microshift 启动一段时间后，查看 microshift container 日志
podman logs microshift 2>&1 | grep -E "^E0" | grep -Ev "failed to get cgroup stats|could not find container" 

# 删除 IP 地址既不是 Node IP 的 Pods，也不是 clusterCIDR 的 Pods
# 根据经验看一般是 kubevirt-hostpath-provisioner 和 service-ca 这两个 Pod
oc get pods -A -o wide
oc -n openshift-service-ca delete $(oc -n openshift-service-ca get pods -l app=service-ca -o name)
oc -n kubevirt-hostpath-provisioner delete $(oc -n kubevirt-hostpath-provisioner get pods -l k8s-app=kubevirt-hostpath-provisioner -o name)
```

### 改变 clusterCIDR 和 serviceCIDR 配置 
```
# 在 microshift 节点上创建 /etc/microshift/config.yaml 
mkdir -p /etc/microshift
cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.52.0.0/16'
  serviceCIDR: '10.53.0.0/16'
  dns: '10.53.0.10'
  domain: cluster.local
EOF
chcon -R --reference /var/lib/kubelet /etc/microshift

# 重新生成 /etc/systemd/system/microshift.service 包含 /etc/microshift/config.yaml
cat > /etc/systemd/system/microshift.service <<EOF
[Unit]
Description=MicroShift Containerized
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target crio.service
After=network-online.target crio.service
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/usr/bin/mkdir -p /var/lib/kubelet ; /usr/bin/mkdir -p /var/hpvolumes ; /usr/bin/mkdir -p /etc/microshift
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon --rm --replace --sdnotify=container --label io.containers.autoupdate=registry --network=host --privileged -d --name microshift -v /etc/microshift/config.yaml:/etc/microshift/config.yaml:z,rw,rshared -v /var/hpvolumes:/var/hpvolumes:z,rw,rshared -v /var/run/crio/crio.sock:/var/run/crio/crio.sock:rw,rshared -v microshift-data:/var/lib/microshift:rw,rshared -v /var/lib/kubelet:/var/lib/kubelet:z,rw,rshared -v /var/log:/var/log -v /etc:/etc quay.io/microshift/microshift:4.8.0-0.microshift-2022-04-20-182108
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=multi-user.target default.target
EOF
systemctl daemon-reload

# 清理之前的部署
systemctl stop microshift
/usr/bin/crictl stopp $(/usr/bin/crictl pods -q)
/usr/bin/crictl stop $(/usr/bin/crictl ps -aq)
/usr/bin/crictl rmp $(crictl pods -q)
rm -rf /var/lib/containers/*
crio wipe -f

# 重启 microshift
systemctl start microshift

# 添加防火墙规则
sudo firewall-cmd --zone=trusted --add-source=10.52.0.0/16 --permanent
sudo firewall-cmd --reload
```

### microshift config.yaml
```
# edge-1
cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.42.0.0/16'
  serviceCIDR: '10.43.0.0/16'
  dns: '10.43.0.10'
  domain: cluster.local
EOF
sudo firewall-cmd --zone=trusted --add-source=10.42.0.0/16 --permanent
sudo firewall-cmd --reload

# edge-2
cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.52.0.0/16'
  serviceCIDR: '10.53.0.0/16'
  dns: '10.53.0.10'
  domain: cluster.local
EOF
sudo firewall-cmd --zone=trusted --add-source=10.52.0.0/16 --permanent
sudo firewall-cmd --reload

# edge-3
cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.62.0.0/16'
  serviceCIDR: '10.63.0.0/16'
  dns: '10.63.0.10'
  domain: cluster.local
EOF
sudo firewall-cmd --zone=trusted --add-source=10.62.0.0/16 --permanent
sudo firewall-cmd --reload

# edge-4
cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.72.0.0/16'
  serviceCIDR: '10.73.0.0/16'
  dns: '10.73.0.10'
  domain: cluster.local
EOF
sudo firewall-cmd --zone=trusted --add-source=10.72.0.0/16 --permanent
sudo firewall-cmd --reload
```

### 删除 microshift  
```
systemctl stop microshift
#/usr/bin/crictl stopp $(/usr/bin/crictl pods -q)
#/usr/bin/crictl stop $(/usr/bin/crictl ps -aq)
#/usr/bin/crictl rmp $(crictl pods -q)
/usr/bin/crictl rm --all --force
/usr/bin/crictl rmi --all --prune
pkill -9 conmon
pkill -9 pause
crio wipe -f
rm -rf /var/lib/containers/*

以下步骤可不执行
#/usr/bin/crictl stopp $(/usr/bin/crictl pods -q)
#/usr/bin/crictl stop $(/usr/bin/crictl ps -aq)
#/usr/bin/crictl rmp $(crictl pods -q)
```

### 通过 /etc/microshift/config.yaml 设置 clusterCIDR 和 serviceCIDR 时
```
$ cat /etc/microshift/config.yaml
---
cluster:
  clusterCIDR: '10.52.0.0/16'
  serviceCIDR: '10.53.0.0/16'
  dns: '10.53.0.10'
  domain: cluster.local

# 需手动更新 flannel 的 configmap kube-flannel-cfg
$ oc get configmap kube-flannel-cfg -n kube-system -o yaml | grep -Ev "creationTimestamp|resourceVersion|selfLink|uid" | tee kube-flannel-cfg.yaml
$ FLANEL_NETWORK="10.52.0.0"
$ sed -i "s|10.42.0.0|${FLANEL_NETWORK}|g" kube-flannel-cfg.yaml
$ oc apply -f kube-flannel-cfg.yaml

# 并且删除重建 flannel pod
$ oc -n kube-system delete $(oc -n kube-system get pods -l app=flannel -o name) 

# 之后检查/run/flannel/subnet.env
$ oc -n kube-system rsh $(oc -n kube-system get pods -l app=flannel -o name) cat /run/flannel/subnet.env 
Defaulted container "kube-flannel" out of: kube-flannel, install-cni-bin (init), install-cni (init)
FLANNEL_NETWORK=10.52.0.0/16
FLANNEL_SUBNET=10.52.0.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true

# 测试域名解析
oc -n openshift-dns rsh $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) dig <domainname>
```

### 检查 dns, fannel, service-ca 
```
# check dns and flannel in microshift
oc --kubeconfig=./kubeconfig -n openshift-dns rsh $(oc --kubeconfig=./kubeconfig -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) dig api.fenchang1.gaolantest.greeyun.com.

oc -n openshift-dns rsh $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) dig api.ocp4.rhcnsa.com.

# 在没有 Metrics API 的情况下，可以查询 pod 里的 /sys/fs/cgroup/cpu/cpuacct.usage 和 /sys/fs/cgroup/memory/memory.usage_in_bytes 来获取 pod 的 cpu 与 memory 实际占用情况

oc -n openshift-dns rsh $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) cat /sys/fs/cgroup/cpu/cpuacct.usage

oc -n openshift-dns rsh $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) cat /sys/fs/cgroup/memory/memory.usage_in_bytes

# 查看 application-manager 的日志
oc --kubeconfig=./kubeconfig  -n open-cluster-management-agent-addon logs $(oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon get pods -l app=application-manager -o name) 
2.6
oc --kubeconfig=./kubeconfig  -n open-cluster-management-agent-addon logs $(oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon get pods -l component=application-manager -o name) 

# 删除 dns-default pod
$ oc -n openshift-dns delete $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) 

# 查看 dns-default pod 日志
$ oc -n openshift-dns logs $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) -c dns

# 查看 service-ca pod 日志
$ oc -n openshift-service-ca logs $(oc -n openshift-service-ca get pods -l app=service-ca -o name) 

# 查看 flannel /run/flannel/subnet.env
$ oc -n kube-system rsh $(oc -n kube-system get pods -l app=flannel -o name) cat /run/flannel/subnet.env 

# 测试域名解析
$ oc -n openshift-dns rsh $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) dig <domainname>

# 查看 kubevirt-hostpath-provisioner pod 日志
$ oc -n kubevirt-hostpath-provisioner logs $(oc -n kubevirt-hostpath-provisioner get pods -l k8s-app=kubevirt-hostpath-provisioner -o name)

# 查看 node-resolver pod 日志
$ oc -n openshift-dns logs $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-node-resolver="" -o name)

# 查看 router-default pod 日志
$ oc -n openshift-ingress logs $(oc -n openshift-ingress get pods -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller="default" -o name)

# 删除 router-default pod
$ oc -n openshift-ingress delete $(oc -n openshift-ingress get pods -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller="default" -o name)

```

### 检查 microshift pods 日志
```
# 查看 flannel pod 日志
$ oc -n kube-system logs $(oc -n kube-system get pods -l app=flannel -o name) 

# 查看 dns-default pod 日志
$ oc -n openshift-dns logs $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name)

# 查看 node-resolver pod 日志
$ oc -n openshift-dns logs $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-node-resolver="" -o name)

# 查看 router-default pod 日志
$ oc -n openshift-ingress logs $(oc -n openshift-ingress get pods -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller="default" -o name)

# 查看 service-ca pod 日志
$ oc -n openshift-service-ca logs $(oc -n openshift-service-ca get pods -l app=service-ca -o name) 

# 查看 kubevirt-hostpath-provisioner pod 日志
$ oc -n kubevirt-hostpath-provisioner logs $(oc -n kubevirt-hostpath-provisioner get pods -l k8s-app=kubevirt-hostpath-provisioner -o name)
```

### 检查 klusterlet 日志
```
# 查看 klusterlet pod 日志
$ oc -n open-cluster-management-agent logs $(oc -n open-cluster-management-agent get pods -l app=klusterlet -o name) 

# 查看 klusterlet-registration-agent pod 日志
$ oc -n open-cluster-management-agent logs $(oc -n open-cluster-management-agent get pods -l app=klusterlet-registration-agent -o name) 

# 查看 klusterlet-work-agent pod 日志
$ oc -n open-cluster-management-agent logs $(oc -n open-cluster-management-agent get pods -l app=klusterlet-manifestwork-agent -o name) 
```

### 检查 klusterlet addon 日志
```
# 查看 klusterlet-addon-operator pod 日志
$ oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l name=klusterlet-addon-operator -o name) 

# 查看 klusterlet-addon-appmgr pod 日志
$ oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l app=application-manager -o name) 

# 查看 klusterlet-addon-certpolicyctrl pod 日志
$ oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l app=cert-policy-controller -o name) 

# 查看 klusterlet-addon-policyctrl-framework pod 日志
$ oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l app=policy-framework -o name) -c spec-sync
$ oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l app=policy-framework -o name) -c status-sync
$ oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l app=policy-framework -o name) -c template-sync

# 查看 klusterlet-addon-policyctrl-config-policy pod 日志
$ oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l app=policy-config-policy -o name)

# 查看 klusterlet-addon-search pod 日志
$ oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l app=search -o name)

# 查看 klusterlet-addon-workmgr pod 日志
$ oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l app=work-manager -o name)

### ACM - 2.5.1
# 查看 klusterlet-addon-workmgr pod 日志
$ oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l component=work-manager -o name)

```

### 测试实例
```
$ oc create namespace nginx-test
$ oc -n nginx-test create deployment nginx --image=docker.io/nginxinc/nginx-unprivileged:stable-alpine

$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx
  name: nginx
  namespace: nginx-test
spec:
  ports:
  - name: http
    port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: nginx
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
EOF

$ oc -n nginx-test expose service nginx --type=NodePort --name=nginx-nodeport --generator="service/v2"

# 按需替换 nodePort
$ oc -n nginx-test patch service nginx-nodeport --type json -p '[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 8080}]'

$ oc run -n nginx-test tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash



```

### 安装数据库实例
定义 NodePort 范围
https://github.com/redhat-et/microshift/pull/649
```
# quay.io/microshift/microshift:4.8.0-0.microshift-2022-04-20-182108
# worked
# set default storage class 
oc patch storageclass kubevirt-hostpath-provisioner -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'

# 将服务暴露为 nodeport
oc -n default expose service my-release-mariadb-galera --type=NodePort --name=my-release-mariadb-galera-nodeport --generator="service/v2"

# microshift 设置 nodeport
https://github.com/redhat-et/microshift/pull/649

cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.42.0.0/16'
  serviceCIDR: '10.43.0.0/16'
  serviceNodePortRange: "3000-33000"
  dns: '10.43.0.10'
  domain: cluster.local
EOF
```

### 安装helm
```
$ cd /tmp
$ curl http://<DOWNLOADURL>/tools/helm-linux-amd64.tar.gz -o helm.tar.gz
$ tar xvfz helm.tar.gz 
$ rm helm.tar.gz 
$ chmod +x helm
$ mv helm /usr/local/bin/.

$ curl http://10.27.133.3:81/tools/charts-master.zip -o charts.zip

NAME                               STATUS   ROLES    AGE    VERSION
fen1unit1.gaolantest.greeyun.com   Ready    <none>   5d6h   v1.21.0
```

### 更新 deployment router-default 的 env，设置 route 为定制化域名格式
```
oc -n openshift-ingress set env deployment/router-default ROUTER_SUBDOMAIN="\${name}-\${namespace}.apps.example.com" ROUTER_ALLOW_WILDCARD_ROUTES="true" ROUTER_OVERRIDE_HOSTNAME="true"
```

### 更新 openshift router-default 证书
https://www.opensourcerers.org/2022/01/17/openshift-on-raspberry-pi-4/
```
[root@microshift ~]# oc create secret \ -n openshift-ingress tls letsencrypt \ --cert=cert.crt --key=cert.key
secret/letsencrypt created
[root@microshift ~]# oc set volumes \ -n openshift-ingress deployment/router-default \ --add --name=default-certificate \ --secret-name=letsencrypt --overwrite deployment.apps/router-default
volume updated
```

### 参考链接
[WIP] Add OAuth API server to Microshift #244<br>
https://github.com/redhat-et/microshift/pull/244<br>
https://microshift.io/docs/user-documentation/configuring/<br>
https://github.com/redhat-et/microshift/blob/main/test/config.yaml<br>
https://microshift.io/docs/user-documentation/how-tos/private-registries/<br>

```
https://github.com/redhat-et/microshift/pull/457
https://microshift.slack.com/archives/C025AQ0QD8B/p1639426608149600
# 区别
# -v microshift-data:/var/lib/microshift:rw,rshared
# -v /var/lib/microshift:/var/lib/microshift:rw,rshared
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon --rm --replace --sdnotify=container --label io.containers.autoupdate=registry --network=host --privileged -d --name microshift -v /var/hpvolumes:/var/hpvolumes:z,rw,rshared -v /var/run/crio/crio.sock:/var/run/crio/crio.sock:rw,rshared -v microshift-data:/var/lib/microshift:rw,rshared -v /var/lib/kubelet:/var/lib/kubelet:z,rw,rshared -v /var/log:/var/log -v /etc:/etc quay.io/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920

ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon --rm --replace --sdnotify=container --label io.containers.autoupdate=registry --network=host --privileged -d --name microshift -v /var/run/crio/crio.sock:/var/run/crio/crio.sock:rw,rshared -v /var/lib/microshift:/var/lib/microshift:rw,rshared -v /var/lib/kubelet:/var/lib/kubelet:rw,rshared -v /var/log:/var/log -e KUBECONFIG=/var/lib/microshift/resources/kubeadmin/kubeconfig quay.io/microshift/microshift:latest
```

### add metric server to microshift
https://github.com/openshift/microshift/issues/302<br>
https://github.com/kubernetes-incubator/metrics-server<br>
https://prometheus.io/blog/2021/11/16/agent/<br>
https://kubernetes-sigs.github.io/metrics-server/<br>
https://sysdig.com/blog/how-to-monitor-kubelet/<br>
https://github.com/google/cadvisor<br>
https://github.com/cri-o/cri-o/blob/main/tutorials/metrics.md<br>
https://www.cnblogs.com/zhangmingcheng/p/15770672.html<br>
https://www.cloudforecast.io/blog/cadvisor-and-kubernetes-monitoring-guide/<br>
https://observability.thomasriley.co.uk/monitoring-kubernetes/metrics/kubelet-cadvisor/<br>
https://www.rancher.cn/blog/2019/native-kubernetes-monitoring-tools-part-1<br>
```
$ kubectl apply -f https://raw.githubusercontent.com/redhat-et/ushift-workload/master/metrics-server/metrics-components.yaml
serviceaccount/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
service/metrics-server created
deployment.apps/metrics-server created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created

# try to open port 10250, 9090, 9573 for crio metrics
sudo firewall-cmd --zone=public --add-port=10250/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --add-port=9090/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --add-port=9573/tcp --permanent
sudo firewall-cmd --reload

# check metrics-server logs
oc -n kube-system logs $(oc -n kube-system get pods -l k8s-app=metrics-server -o name)
oc -n kube-system delete $(oc -n kube-system get pods -l k8s-app=metrics-server -o name)
oc -n kube-system logs $(oc -n kube-system get pods -l k8s-app=metrics-server -o name) v=4

# check metrics

# /etc/crio/crio.conf
...
# A necessary configuration for Prometheus based metrics retrieval
[crio.metrics]

# Globally enable or disable metrics support.
enable_metrics = true

# The port on which the metrics server will listen.
metrics_port = 9537

# crio metrics 
# 这个不是所需要的 metrics
curl -v http://localhost:9537/metrics

# 
E0518 09:43:53.060171       1 server.go:132] unable to fully scrape metrics: unable to fully scrape metrics from node edge-2.example.com: unable to fetch metrics from node edge-2.example.com: Get "https://10.66.208.163:10250/stats/summary?only_cpu_and_memory=true": dial tcp 10.66.208.163:10250: connect: connection refused

# error logs
E0519 01:16:37.509949       1 pathrecorder.go:107] registered "/metrics" from goroutine 1 [running]:


oc adm policy add-scc-to-user anyuid -z cadvisor
oc adm policy add-scc-to-user privileges -z cadvisor

oc adm policy remove-scc-from-user anyuid -z cadvisor




```

### obtain cadvisor metrics from microshift
```
$ kubectl create clusterrolebinding add-on-cluster-admin-to-kubesystem-default --clusterrole=cluster-admin --serviceaccount=kube-system:default
$ oc project kube-system
$ TOKEN=$(oc serviceaccounts get-token default)
$ curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/metrics
$ curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/metrics/cadvisor
$ curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/stats/summary
```

### 下一个问题是 cadvisor 下包含哪些内容
https://kubernetes.io/zh/docs/concepts/cluster-administration/system-metrics/<br>
```
$ oc project kube-system
$ kubectl create clusterrolebinding add-on-cluster-admin-to-metrics-server --clusterrole=cluster-admin --serviceaccount=kube-system:metrics-server
$ TOKEN=$(oc serviceaccounts get-token metrics-server)
```

### microshift 获取 cadvisor metrics 的处理方法
seealso:https://github.com/openshift/microshift/issues/475
```
1. enable cgroupv2 for RHEL8 
https://access.redhat.com/solutions/3777261

### check boot kernel options
$ grub2-editenv - list | grep kernelopts
kernelopts=root=/dev/mapper/rhel-root ro resume=/dev/mapper/rhel-swap rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb quiet 

### add systemd.unified_cgroup_hierarchy=1 to boot kernel options 
$ grub2-editenv - set "kernelopts=root=/dev/mapper/rhel-root ro resume=/dev/mapper/rhel-swap rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap systemd.unified_cgroup_hierarchy=1"

$ reboot

2. add cgroupv2 relate params to microshift.service unit file
### ExecStart
### --cgroup-manager=cgroupfs
### -v /sys/fs/cgroup:/sys/fs/cgroup:ro
$ cat > /etc/systemd/system/microshift.service <<'EOF'
[Unit]
Description=MicroShift Containerized
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target crio.service
After=network-online.target crio.service
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/usr/bin/mkdir -p /var/lib/kubelet ; /usr/bin/mkdir -p /var/hpvolumes ; /usr/bin/mkdir -p /etc/microshift
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroup-manager=cgroupfs --cgroups=no-conmon --rm --replace --sdnotify=container --label io.containers.autoupdate=registry --network=host --privileged -d --name microshift -v /etc/microshift/config.yaml:/etc/microshift/config.yaml:z,rw,rshared -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v /var/hpvolumes:/var/hpvolumes:z,rw,rshared -v /var/run/crio/crio.sock:/var/run/crio/crio.sock:rw,rshared -v microshift-data:/var/lib/microshift:rw,rshared -v /var/lib/kubelet:/var/lib/kubelet:z,rw,rshared -v /var/log:/var/log -v /etc:/etc quay.io/microshift/microshift:4.8.0-0.microshift-2022-04-20-182108
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=multi-user.target default.target
EOF

$ systemctl daemon-reload
$ systemctl restart crio; systemctl restart microshift

3. check microshift 'metrics/cadvisor' has container metrics
$ kubectl create clusterrolebinding add-on-cluster-admin-to-kubesystem-default --clusterrole=cluster-admin --serviceaccount=kube-system:default
$ oc project kube-system
$ TOKEN=$(oc serviceaccounts get-token default)
$ curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/metrics/cadvisor
...
container_cpu_usage_seconds_total{container="router",cpu="total",id="/system.slice/crio-53e810986873266c721099367572bb6fbd5b97ca01befab2298efe5f0416e
6c2.scope",image="quay.io/openshift/okd-content@sha256:01cfbbfdc11e2cbb8856f31a65c83acc7cfbd1986c1309f58c255840efcc0b64",name="k8s_router_router-defa
ult-6c96f6bc66-2kmf4_openshift-ingress_a3c0b24b-97b9-408f-9b8f-09f85c4abfdf_0",namespace="openshift-ingress",pod="router-default-6c96f6bc66-2kmf4"} 0
.471184 1653276165463
...
```

### 将 cadvisor 集成到 prometheus
https://prometheus.io/docs/guides/cadvisor/<br>

### User application monitoring and ACM observability?
https://thanos.io/tip/thanos/storage.md/#s3<br>
https://github.com/stolostron/acm-aap-aas-operations/pull/117/files#diff-a178efb0591fe7fc8a2ab48c6a8a1c26a135826d8b7235465452708caed78eba<br>
https://issues.redhat.com/browse/ACM-1320<br>
https://github.com/stolostron/multicluster-observability-operator/blob/main/docs/MoreAboutPersistentStorage.md<br>
https://github.com/stolostron/multicluster-observability-operator/blob/main/operators/multiclusterobservability/manifests/base/config/metrics_allowlist.yaml<br>
https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/observability/observing-environments-intro#adding-custom-metrics<br>
https://docs.google.com/document/d/1OuRHCx9lgBGFK0aadPTDOCo2ZmLMCpwEUwVjCt2c9Hc<br>
https://issues.redhat.com/browse/ACM-197<br>
https://thanos.io/tip/thanos/storage.md/#object-storage<br>

### 运行 podman manifest 命令为 image 创建或者添加 manifest
```
[kni@provisioner ~]$ podman manifest create test:v1
d8abdc1e0ed6a1352477474e06a13e007f69d126bbafc99be0dad98b9ea11bf8
You have mail in /var/spool/mail/kni
[kni@provisioner ~]$ podman manifest add test:v1 registry.connect.redhat.com/intel/sriov-fec-operator@sha256:4b68377310cb6806fe8eca8bdb5874e7ed96503c5290967ea43bf177f28aafe7
d8abdc1e0ed6a1352477474e06a13e007f69d126bbafc99be0dad98b9ea11bf8
[kni@provisioner ~]$ podman manifest inspect test:v1
{
    "schemaVersion": 2,
    "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
    "manifests": [
        {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "size": 974,
            "digest": "sha256:4b68377310cb6806fe8eca8bdb5874e7ed96503c5290967ea43bf177f28aafe7",
            "platform": {
                "architecture": "amd64",
                "os": "linux"
            }
        }
    ]
}
```


### test acm observability service
https://www.ibm.com/docs/en/spectrum-archive-ee/1.3.1?topic=reference-solution-showcase-using-minio-spectrum-archive-s3-api<br>
https://cloud.redhat.com/blog/how-your-grafana-can-fetch-metrics-from-red-hat-advanced-cluster-management-observability-observatorium-and-thanos<br>
```
oc create namespace open-cluster-management-observability
DOCKER_CONFIG_JSON=`oc extract secret/pull-secret -n openshift-config --to=-`
oc create secret generic multiclusterhub-operator-pull-secret \
    -n open-cluster-management-observability \
    --from-literal=.dockerconfigjson="$DOCKER_CONFIG_JSON" \
    --type=kubernetes.io/dockerconfigjson

# 参考步骤配置 minio
# https://github.com/wangjun1974/tips/blob/master/os/miscs.md#%E5%A4%87%E4%BB%BD-openshift-%E8%B5%84%E6%BA%90
# 20220801
# 最新的镜像创建 bucket 有问题
# 测试确认正常的版本为
# image: minio/minio:RELEASE.2022-07-24T01-54-52Z
# image: minio/mc:RELEASE.2022-07-24T02-25-13Z
aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 ls 
aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 mb s3://observability
aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 ls 

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: thanos-object-storage
  namespace: open-cluster-management-observability
type: Opaque
stringData:
  thanos.yaml: |
    type: s3
    config:
      bucket: observability
      endpoint: $(oc -n velero get route minio -o jsonpath='{.spec.host}')
      insecure: true
      access_key: minio
      secret_key: minio123
EOF

cat <<EOF | oc apply -f -
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  name: observability
spec:
  enableDownsampling: true
  observabilityAddonSpec:
    enableMetrics: true
    interval: 300
  storageConfig:
    alertmanagerStorageSize: 1Gi
    compactStorageSize: 100Gi
    metricObjectStorage:
      key: thanos.yaml
      name: thanos-object-storage
    receiveStorageSize: 100Gi
    ruleStorageSize: 1Gi
    storageClass: gp2
    storeStorageSize: 10Gi
EOF

oc get secret observability-server-ca-certs -n open-cluster-management-observability
oc get secret observability-client-ca-certs -n open-cluster-management-observability -o json | jq '.data."ca.crt"' | tee ca.crt
oc get secret observability-grafana-certs -n open-cluster-management-observability -o json | jq '.data."tls.key"' | tee tls.key

oc project open-cluster-management-observability 
# 查看 observatorium-operator 的日志
oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l control-plane='observatorium-operator' -o name)

# 查看 multicluster-observability-grafana 的日志
oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-grafana' -o name | head -1) -c grafana
oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-grafana' -o name | tail -1) -c grafana

# 获取 TOKEN 
oc get useroauthaccesstokens 
TOKEN='sha256~7l7lqp2tZ_IvwNRRcyt7cqvCaQuS1b3172R1ilxJIXY'
PROXY_ROUTE_URL=$(oc get route rbac-query-proxy -n open-cluster-management-observability -o jsonpath='{.spec.host}')
curl -Ssk --header "Authorization: Bearer ${TOKEN}"  https://${PROXY_ROUTE_URL}/api/v1/query?query=cluster_infrastructure_provider

# 参考导入 ACM Hub 的步骤，将 microshift 作为 Managed Cluster 导入到 ACM Hub 中
oc --kubeconfig=./kubeconfig new-project open-cluster-management-agent
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet-registration-sa
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet-work-sa
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

oc --kubeconfig=./kubeconfig new-project open-cluster-management-agent-addon
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

# 如果启用了 ACM Observability 注意在 ManageCluster 里创建 open-cluster-management-addon-observability namespace
# Randy George 提醒 klusterlet 会自动创建这个 namespace, 经测试这个 namespace 无需手工创建 Thanks Randy
oc --kubeconfig=./kubeconfig new-project open-cluster-management-addon-observability

oc --kubeconfig=./kubeconfig project open-cluster-management-agent
echo $CRDS | base64 -d | oc --kubeconfig=./kubeconfig apply -f -
echo $IMPORT | base64 -d | oc --kubeconfig=./kubeconfig apply -f -

### 检查 open-cluster-management-addon-observability namespace 下的 pod 日志
# prometheus
oc -n open-cluster-management-addon-observability logs $(oc -n open-cluster-management-addon-observability get pods -l app.kubernetes.io/name='prometheus' -o name)

# endpoint-observability-operator
oc -n open-cluster-management-addon-observability logs $(oc -n open-cluster-management-addon-observability get pods -l name='endpoint-observability-operator' -o name)

# metrics-collector
oc -n open-cluster-management-addon-observability logs $(oc -n open-cluster-management-addon-observability get pods -l component='metrics-collector' -o name)

# kube-state-metrics
oc -n open-cluster-management-addon-observability logs $(oc -n open-cluster-management-addon-observability get pods -l app.kubernetes.io/name='kube-state-metrics' -o name)

# node-exporter
oc -n open-cluster-management-addon-observability logs $(oc -n open-cluster-management-addon-observability get pods -l app.kubernetes.io/name='node-exporter' -o name) -c node-exporter

# ACM Observability Hub logs - ACM 2.5.1
# observatorium-operator
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l control-plane='observatorium-operator' -o name)

# observatorium-api
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='observatorium-api' -o name | head -1)
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='observatorium-api' -o name | tail -1)

# thanos-compact
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-compact' -o name)

# thanos-store
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-store' -o name | head -1)
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-store' -o name | head -2 | tail -1)
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-store' -o name | tail -1)

# thanos-store-memcached
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='memcached' -l app.kubernetes.io/component='store-cache' -o name | head -1) -c memcached
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='memcached' -l app.kubernetes.io/component='store-cache' -o name | head -1) -c exporter
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='memcached' -l app.kubernetes.io/component='store-cache' -o name | head -2 | tail -1) -c memcached
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='memcached' -l app.kubernetes.io/component='store-cache' -o name | head -2 | tail -1) -c exporter
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='memcached' -l app.kubernetes.io/component='store-cache' -o name | tail -1) -c memcached
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='memcached' -l app.kubernetes.io/component='store-cache' -o name | tail -1) -c exporter

# thanos-rule
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-rule' -o name | head -1) -c thanos-rule 
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-rule' -o name | head -1) -c configmap-reloader
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-rule' -o name | head -2 | tail -1) -c thanos-rule 
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-rule' -o name | head -2 | tail -1) -c configmap-reloader
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-rule' -o name | tail -1) -c thanos-rule 
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-rule' -o name | tail -1) -c configmap-reloader

# thanos-receive-controller
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-receive-controller' -o name)

# thanos-receive
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-receive' -o name | head -1) 
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-receive' -o name | head -2 | tail -1) 
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-receive' -o name | tail -1) 

# thanos-query
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-query' -o name | head -1) 
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-query' -o name | tail -1) 

# thanos-query-frontend
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-query-frontend' -o name | head -1) 
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-query-frontend' -o name | tail -1) 

# query-frontend-cache-memcached 
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='memcached' -l app.kubernetes.io/component='query-frontend-cache' -o name | head -1) -c memcached
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='memcached' -l app.kubernetes.io/component='query-frontend-cache' -o name | head -1) -c exporter

# alertmanager
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-alertmanager' -o name | head -1) -c alertmanager
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-alertmanager' -o name | head -1) -c alertmanager-proxy
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-alertmanager' -o name | head -1) -c config-reloader
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-alertmanager' -o name | head -2 | tail -1) -c alertmanager
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-alertmanager' -o name | head -2 | tail -1) -c alertmanager-proxy
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-alertmanager' -o name | head -2 | tail -1) -c config-reloader
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-alertmanager' -o name | tail -1) -c alertmanager
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-alertmanager' -o name | tail -1) -c alertmanager-proxy
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-alertmanager' -o name | tail -1) -c config-reloader

# grafana
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-grafana' -o name | head -1) -c grafana
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-grafana' -o name | head -1) -c grafana-dashboard-loader
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-grafana' -o name | tail -1) -c grafana
$ oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app='multicluster-observability-grafana' -o name | tail -1) -c grafana-dashboard-loader

# oc get pods -n open-cluster-management-observability 
NAME                                                      READY   STATUS    RESTARTS   AGE
observability-alertmanager-0                              3/3     Running   0          2m54s
observability-alertmanager-1                              3/3     Running   0          2m16s
observability-alertmanager-2                              3/3     Running   0          115s
observability-grafana-5479c77-9prbg                       2/2     Running   0          2m55s
observability-grafana-5479c77-r6rm8                       2/2     Running   0          2m55s
observability-observatorium-api-56764cb77c-9gvw7          1/1     Running   0          2m17s
observability-observatorium-api-56764cb77c-ntldv          1/1     Running   0          2m17s
observability-observatorium-operator-66d567cdd5-9m4bd     1/1     Running   0          2m55s
observability-rbac-query-proxy-548b586fb-wlxd2            2/2     Running   0          2m53s
observability-rbac-query-proxy-548b586fb-xhmbw            2/2     Running   0          2m53s
observability-thanos-compact-0                            1/1     Running   0          2m17s
observability-thanos-query-b6c875b95-nq4b8                1/1     Running   0          2m17s
observability-thanos-query-b6c875b95-qbw2z                1/1     Running   0          2m16s
observability-thanos-query-frontend-86db8c9f5b-b76td      1/1     Running   0          2m17s
observability-thanos-query-frontend-86db8c9f5b-wqxnk      1/1     Running   0          2m17s
observability-thanos-query-frontend-memcached-0           2/2     Running   0          2m16s
observability-thanos-query-frontend-memcached-1           2/2     Running   0          115s
observability-thanos-query-frontend-memcached-2           2/2     Running   0          108s
observability-thanos-receive-controller-f47cb55d8-pz6c4   1/1     Running   0          2m17s
observability-thanos-receive-default-0                    1/1     Running   0          2m17s
observability-thanos-receive-default-1                    1/1     Running   0          112s
observability-thanos-receive-default-2                    1/1     Running   0          90s
observability-thanos-rule-0                               2/2     Running   0          2m17s
observability-thanos-rule-1                               2/2     Running   0          105s
observability-thanos-rule-2                               2/2     Running   0          79s
observability-thanos-store-memcached-0                    2/2     Running   0          2m17s
observability-thanos-store-memcached-1                    2/2     Running   0          2m4s
observability-thanos-store-memcached-2                    2/2     Running   0          115s
observability-thanos-store-shard-0-0                      1/1     Running   0          2m17s
observability-thanos-store-shard-1-0                      1/1     Running   0          2m17s
observability-thanos-store-shard-2-0                      1/1     Running   0          2m17s

```

### rpm based microshift
```
# 更新系统到 RHEL 8.6，microshift 依赖高版本的 selinux-policy 和 selinux-policy-base 
sudo dnf update -y selinux-policy selinux-policy-base 
sudo dnf copr enable -y @redhat-et/microshift
sudo dnf install -y microshift

# 设置防火墙规则 
sudo firewall-cmd --zone=trusted --add-source=10.42.0.0/16 --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5353/udp --permanent
sudo firewall-cmd --reload

# 启动服务
sudo systemctl enable microshift --now

# 拷贝 kubeconfig
mkdir ~/.kube
sudo cat /var/lib/microshift/resources/kubeadmin/kubeconfig > ~/.kube/config

# 错误处理
# 清理时删除 /var/lib/kubelet/pods 下的目录
# 如目录无法删除注意卸载有关目录
umount $(df -HT | grep '/var/lib/kubelet/pods' | awk '{print $7}')
umount $(mount | grep kubelet | grep "volume-subpaths" | awk '{print $3}')
rm -rf /var/lib/kubelet/pods/*

```

### microshift 与 olm
```
# download operator-sdk
# https://sdk.operatorframework.io/docs/installation/
export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')

export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.21.0
curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}

# Verify the downloaded binary
gpg --keyserver keyserver.ubuntu.com --recv-keys 052996E2A20B5C7E
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt.asc
gpg -u "Operator SDK (release) <cncf-operator-sdk@cncf.io>" --verify checksums.txt.asc

# Install the release binary in your PATH
chmod +x operator-sdk_${OS}_${ARCH} && sudo mv operator-sdk_${OS}_${ARCH} /usr/local/bin/operator-sdk


# deploy the OLM, now you will have all the operator from operatorhub.io
operator-sdk olm install

# list all the available operators
kubectl get packagemanifests

# k8s logging operator 介绍
# https://cloud.tencent.com/developer/article/1810778
# https://blog.csdn.net/tao12345666333/article/details/116178235

# 添加 redhat-operators CatalogSource
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operators
  namespace: olm
spec:
  displayName: Red Hat Operators
  sourceType: grpc
  image: registry.redhat.io/redhat/redhat-operator-index:v4.8
  publisher: RedHat
EOF
```

### RHEL for Edge
https://github.com/osbuild/rhel-for-edge-demo
```
# 在 RHEL 8.3 以上版本安装 osbuild-composer cockpit-composer
yum install -y osbuild-composer cockpit-composer

# 启用 osbuild-composer.socket 
sudo systemctl enable --now osbuild-composer.socket

# 启用 osbuild-composer.service
sudo systemctl enable --now osbuild-composer.service


# 启用 cockpit.socket
# 测试环境下 cockpit.socket 里的 Image Builder -> Edit package 一直转圈
systemctl enable --now cockpit.socket

# 用命令行方式尝试一下

# 生成 blueprint.toml 
cat > blueprint.toml <<'EOF'
name = "Edge"
description = ""
version = "0.0.1"

[[packages]]
name = "microshift"
version = "*"
EOF

# 基于 blueprint.toml 创建 blueprints
composer-cli blueprints push blueprint.toml
composer-cli blueprints list 
composer-cli blueprints show Edge
composer-cli blueprints depsolve Edge

# 基于前一个步骤创建的 blueprints 创建 compose 
composer-cli compose start-ostree Edge rhel-edge-container

# 查看 compose 状态
(oc-mirror)[root@jwang ~/rhel4edge]# composer-cli compose status
d9332dc2-84bb-4e82-831a-37ed52531e49 RUNNING  Thu Jun  2 10:14:23 2022 Edge            0.0.1 edge-container   
540a4771-2fe1-466f-a90e-b5f826f3885b FINISHED Mon Apr 18 13:27:23 2022 ostree-demo     0.0.1 edge-container  

# 查看 compose 详情
(oc-mirror)[root@jwang ~/rhel4edge]# composer-cli compose info d9332dc2-84bb-4e82-831a-37ed52531e49 

# 查看 compose 日志
(oc-mirror)[root@jwang ~/rhel4edge]# composer-cli compose log d9332dc2-84bb-4e82-831a-37ed52531e49 



```


### 安装 multus
https://gist.github.com/usrbinkat/0f08e0600f9a9ff64bf46d1ec9251f23
```
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick-plugin.yml


# 查看日志
oc -n kube-system logs $(oc -n kube-system get pods -l app=multus -o name)

##################################################################################
# Configure net-attach-def

cat <<EOF | oc apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: nadbr0
spec:
  config: '{"cniVersion":"0.3.1","name":"br0","plugins":[{"type":"bridge","bridge":"br0","ipam":{}},{"type":"tuning"}]}'
EOF

kubectl get net-attach-def -oyaml




(oc-mirror)[root@jwang ~/rhel4edge]# cat blueprint.toml 
name = "Edge"
description = ""
version = "0.0.1"

[[packages]]
name = "microshift"
version = "*"

[[packages]]
name = "cri-o"
version = "*"

[[packages]]
name = "cri-tools"
version = "*"

(oc-mirror)[root@jwang ~/rhel4edge]# composer-cli blueprints push blueprint.toml 
(oc-mirror)[root@jwang ~/rhel4edge]# composer-cli blueprints list
Edge
(oc-mirror)[root@jwang ~/rhel4edge]# composer-cli blueprints depsolve Edge
ERROR: BlueprintsError: Edge: DNF error occured: DepsolveError: There was a problem depsolving ['microshift', 'kernel']: 
 Problem: conflicting requests
  - nothing provides cri-o needed by microshift-4.8.0-2022_04_20_141053.el8.x86_64
  - nothing provides cri-tools needed by microshift-4.8.0-2022_04_20_141053.el8.x86_64
blueprint: Edge v0.0.1

(oc-mirror)[root@jwang ~/rhel4edge]# yum repolist
Updating Subscription Management repositories.
repo id                                                            repo name
copr:copr.fedorainfracloud.org:group_redhat-et:microshift          Copr repo for microshift owned by @redhat-et
rhel-8-for-x86_64-appstream-rpms                                   Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
rhel-8-for-x86_64-baseos-rpms                                      Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)
rhocp-4.10-for-rhel-8-x86_64-rpms                                  Red Hat OpenShift Container Platform 4.10 for RHEL 8 x86_64 (RPMs)
```


### Install microshift on Fedora-IoT 35
https://microshift.io/docs/getting-started/<br>
```
curl -L -o /etc/yum.repos.d/fedora-modular.repo https://src.fedoraproject.org/rpms/fedora-repos/raw/rawhide/f/fedora-modular.repo
curl -L -o /etc/yum.repos.d/fedora-updates-modular.repo https://src.fedoraproject.org/rpms/fedora-repos/raw/rawhide/f/fedora-updates-modular.repo
curl -L -o /etc/yum.repos.d/group_redhat-et-microshift-fedora-35.repo https://copr.fedorainfracloud.org/coprs/g/redhat-et/microshift/repo/fedora-35/group_redhat-et-microshift-fedora-35.repo
rpm-ostree ex module enable cri-o:1.21

rpm-ostree upgrade
rpm-ostree install cri-o cri-tools microshift

systemctl reboot
```

### microshift and rhel for edge
https://github.com/redhat-et/microshift-demos/tree/main/ostree-demo
```
### 1. 启用 rhel-8-for-x86_64-baseos-rpms, rhel-8-for-x86_64-appstream-rpms 和 rhocp-4.8-for-rhel-8-x86_64-rpms 软件仓库
sudo subscription-manager repos --list-enabled | grep ID
Repo ID:   rhel-8-for-x86_64-appstream-rpms
Repo ID:   rhel-8-for-x86_64-baseos-rpms
Repo ID:   rhocp-4.8-for-rhel-8-x86_64-rpms

### 克隆 git 仓库
git clone https://github.com/redhat-et/microshift-demos.git
cd microshift-demos/ostree-demo

### 设置变量 GITOPS_REPO 和 UPGRADE_SERVER_IP
export GITOPS_REPO="https://github.com/wangjun1974/microshift-config"
export UPGRADE_SERVER_IP=10.66.208.130

### 2. 构建 ostrees 与 installer image
./prepare_builder.sh
./customize.sh
./build.sh

### 在测试环境下需要打这个补丁
(oc-mirror)[root@jwang ~/rhel4edge/microshift-demos/ostree-demo]# diff -urN build.sh.orig build.sh 
--- build.sh.orig   2022-06-02 17:30:23.190856599 +0800
+++ build.sh    2022-06-02 15:46:45.391367540 +0800
@@ -59,7 +59,7 @@
         title "Serving ${parent_blueprint} v${parent_version} container locally"
         sudo podman rm -f "${parent_blueprint}-server" 2>/dev/null || true
         sudo podman rmi -f "localhost/${parent_blueprint}:${parent_version}" 2>/dev/null || true
-        imageid=$(cat "./${parent_blueprint}-${parent_version}-container.tar" | sudo podman load | grep -o -P '(?<=sha256[@:])[a-z0-9]*')
+        imageid=$(cat "./${parent_blueprint}-${parent_version}-container.tar" | sudo podman load | grep -o -P '(?<=[@])[a-z0-9]*')
         sudo podman tag "${imageid}" "localhost/${parent_blueprint}:${parent_version}"
         sudo podman run -d --name="${parent_blueprint}-server" -p 8080:8080 "localhost/${parent_blueprint}:${parent_version}"

```

### open-cluster-management-addon-observability pods images
```
# prometheus 
# oc -n open-cluster-management-addon-observability get pods -l app.kubernetes.io/name='prometheus' -o yaml  | grep image | grep registry | sort -u 
      image: registry.redhat.io/openshift4/ose-configmap-reloader@sha256:ca6df8d39998275a1b42c761df0379911025386ca4130c1801d83f4141ee3576
      image: registry.redhat.io/rhacm2/kube-rbac-proxy-rhel8@sha256:99048f0bcce9fadafcaec2fe9c58d06721ee686f287499b14ced978841932671
      image: registry.redhat.io/rhacm2/prometheus-rhel8@sha256:66e94011bfeb917240eadba94b67fe6b2997e9aeeca6dd5cf28d65a7886999f9
# endpoint-observability-operator 用到的镜像
# oc -n open-cluster-management-addon-observability get pods -l name='endpoint-observability-operator' -o yaml | grep image | grep registry | sort -u
      image: registry.redhat.io/rhacm2/endpoint-monitoring-rhel8-operator@sha256:736a2f35323457935ed159722d2cb0d82b574210839934c96a3db70bfe70e3a5

# metrics-collector 
# oc -n open-cluster-management-addon-observability get pods -l component='metrics-collector' -o yaml | grep image | grep registry | sort -u
      image: registry.redhat.io/rhacm2/metrics-collector-rhel8@sha256:d9080554d5e946b58d60a7b4b7eae75d5a55a9be5b1e070262f9b166d418e114

# kube-state-metrics 
# oc -n open-cluster-management-addon-observability get pods -l app.kubernetes.io/name='kube-state-metrics' -o yaml | grep image | grep registry | sort -u
      image: registry.redhat.io/rhacm2/kube-rbac-proxy-rhel8@sha256:99048f0bcce9fadafcaec2fe9c58d06721ee686f287499b14ced978841932671
      image: registry.redhat.io/rhacm2/kube-state-metrics-rhel8@sha256:493db3fc9cff5cde6bfdcac91620d6cb5ece5596e5401f87f18664176c49664d

# node-exporter
# oc -n open-cluster-management-addon-observability get pods -l app.kubernetes.io/name='node-exporter' -o yaml | grep image | grep registry | sort -u
      image: registry.redhat.io/rhacm2/kube-rbac-proxy-rhel8@sha256:99048f0bcce9fadafcaec2fe9c58d06721ee686f287499b14ced978841932671
      image: registry.redhat.io/rhacm2/node-exporter-rhel8@sha256:2be52d07036590ab6387ae9154e6739d7a8b5da7330ef9d0dd59a54a5a1504e7
```

### 清理 microshift 上的 acm 内容
```
# 如果 ACM Hub 因为某种原因被删除了，
# 需要手工清理 microshift 上遗留的对象

# 查找 acm 在 managed cluster 上安装的对象
oc get crds | grep open-cluster-management  | awk '{print $1}'  | while read i ; do echo "" ; echo "======"; echo "oc get $i -A"; oc get $i -A; echo "" ; done 

# 设置 finalizers 为 []
oc patch workmanagers.agent.open-cluster-management.io klusterlet-addon-workmgr -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch searchcollectors.agent.open-cluster-management.io klusterlet-addon-search -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch policycontrollers.agent.open-cluster-management.io klusterlet-addon-policyctrl -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch iampolicycontrollers.agent.open-cluster-management.io klusterlet-addon-iampolicyctrl -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch certpolicycontrollers.agent.open-cluster-management.io klusterlet-addon-certpolicyctrl -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch applicationmanagers.agent.open-cluster-management.io klusterlet-addon-appmgr -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

# 删除 klusterlet
oc get klusterlets.operator.open-cluster-management.io -A -o name | while read i ; do oc patch $i -p '{"metadata":{"finalizers":[]}}' --type=merge; done 
oc get klusterlets.operator.open-cluster-management.io -A -o name | while read i ; do oc delete $i ; done 

# patch namespace
oc get namespace -o name | grep open-cluster-management | while read i ; do oc patch $i -p '{"metadata":{"finalizers":[]}}' --type=merge; done 

# patch pods and force delete pods
oc -n open-cluster-management-agent get pods -o name | while read i ; do oc -n open-cluster-management-agent patch $i -p '{"metadata":{"finalizers":[]}}' --type=merge; done 
oc -n open-cluster-management-agent get pods -o name | while read i ; do oc -n open-cluster-management-agent delete $i --force; done 

oc -n open-cluster-management-addon get pods -o name | while read i ; do oc -n open-cluster-management-addon patch $i -p '{"metadata":{"finalizers":[]}}' --type=merge; done 
oc -n open-cluster-management-addon get pods -o name | while read i ; do oc -n open-cluster-management-addon delete $i --force; done 

oc -n open-cluster-management-addon-observability get pods -o name | while read i ; do oc -n open-cluster-management-addon-observability patch $i -p '{"metadata":{"finalizers":[]}}' --type=merge; done 
oc -n open-cluster-management-addon-observability get pods -o name | while read i ; do oc -n open-cluster-management-addon-observability delete $i --force; done 

# 删除 namespace 
oc delete project open-cluster-management-agent open-cluster-management-agent-addon open-cluster-management-addon-observability edge-1

# 删除 clusterclaims 
oc get clusterclaims.cluster.open-cluster-management.io -o name | while read i ; do oc delete $i ; done 

# 删除 acm 安装的 appliedmanifest
oc get appliedmanifestworks.work.open-cluster-management.io -A -o name | while read i ; do oc patch $i -p '{"metadata":{"finalizers":[]}}' --type=merge; done 
oc get appliedmanifestworks.work.open-cluster-management.io -A -o name | while read i ; do oc delete $i ; done 
```

### 尝试自定义 clusterLabels vendor 为 microshift
```
# 首先 oc login 到 ACM Hub 所在的 OCP Cluster 上
# 在 ACM Hub 上执行
export CLUSTER_NAME=edge-1
oc new-project ${CLUSTER_NAME}
# 可选，在 ACM 2.6 上不执行这条命令
oc label namespace ${CLUSTER_NAME} cluster.open-cluster-management.io/managedCluster=${CLUSTER_NAME}

# 尝试设置 
# cloud 为 Bare-Metal
# vendor 为 microshift
cat <<EOF | oc apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${CLUSTER_NAME}
  namespace: ${CLUSTER_NAME}
spec:
  clusterName: ${CLUSTER_NAME}
  clusterNamespace: ${CLUSTER_NAME}
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: true
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  iamPolicyController:
    enabled: true
  policyController:
    enabled: true
  searchCollector:
    enabled: true
  version: 2.2.0
EOF

cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${CLUSTER_NAME}
spec:
  hubAcceptsClient: true
EOF

# 上面的命令在 ${CLUSTER_NAME} namespace 下生成 secret ${CLUSTER_NAME}-import 
# 导出 import.yaml 和 crds.yaml 
IMPORT=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.import\.yaml}')
CRDS=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.crds\.yaml}')

# 参考导入 ACM Hub 的步骤，将 microshift 作为 Managed Cluster 导入到 ACM Hub 中
cd /root/kubeconfig/edge/edge-1
oc --kubeconfig=./kubeconfig new-project open-cluster-management-agent
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet-registration-sa
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet-work-sa
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

oc --kubeconfig=./kubeconfig new-project open-cluster-management-agent-addon
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

### 对于 microshift 4.10 版本开始 api 上删除了 project
### oc new-project 换成 oc create namespace
oc --kubeconfig=./kubeconfig create namespace open-cluster-management-agent
oc --kubeconfig=./kubeconfig create namespace open-cluster-management-agent-addon

oc --kubeconfig=./kubeconfig project open-cluster-management-agent
echo $CRDS | base64 -d | oc --kubeconfig=./kubeconfig apply -f -
echo $IMPORT | base64 -d | oc --kubeconfig=./kubeconfig apply -f -

### 在执行完上面的命令之后，尝试循环删除 namespace 下的所有 pods 
### 这种方法经测试并不可行
for i in {1..300}; do oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon delete pods --all; sleep 1; done
### 这种方法也不生效
for i in {1..200}; do 
  oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon scale deployment klusterlet-addon-appmgr --replicas=0
  oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon scale deployment klusterlet-addon-search --replicas=0
  oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon scale deployment klusterlet-addon-workmgr --replicas=0
  sleep 1
done
```

### RHEL8.5 上构建 microshift 的 rpm-ostree image
https://github.com/redhat-et/microshift-demos/tree/main/ostree-demo<br>
https://www.osbuild.org/guides/user-guide/edge-container+installer.html<br>
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/composing_installing_and_managing_rhel_for_edge_images/composing-a-rhel-for-edge-image-using-image-builder-command-line_composing-installing-managing-rhel-for-edge-images<br>
https://bugzilla.redhat.com/show_bug.cgi?id=2033192<br>
https://toml.io/en/<br>
```
### 安装 rhel 8.5
### 注册系统到 RHN
subscription-manager register
### 查看可用 Red Hat OpenShift Container Platform 的 pool
subscription-manager list --available --matches 'Red Hat OpenShift Container Platform' | grep -E "Pool ID|Entitlement Type"
### 绑定合适的 pool
subscription-manager attach --pool=xxxxxxxx

### 启用软件仓库
### 问题：Image Builder 理论上应该不依赖于 subscription
### 但是 Image Builder 需要解析 compose 需要的软件包
### 默认 Image Builder 使用在线软件仓库获取软件内容
### 用户/管理员其实可以在在线环境构建 rpm-ostree image
### 然后在离线环境里使用并且维护构建好的 image
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhocp-4.8-for-rhel-8-x86_64-rpms

### 安装 image builder 所需软件包
dnf install -y git cockpit cockpit-composer osbuild-composer composer-cli bash-completion podman genisoimage syslinux skopeo

### 启用 cockpit 和 osbuild-composer 服务
systemctl enable --now osbuild-composer.socket
systemctl enable --now cockpit.socket

### 配置 composer-cli bash 补齐
source  /etc/bash_completion.d/composer-cli

### 创建 composer repo 文件，拷贝系统默认 repo 文件
### osbuild-composer 使用的 repo 文件与 dnf 的 repo 文件不同
### 是 json 格式的文件
### 以下是为 image builder 覆盖默认软件仓库的例子 
mkdir -p /etc/osbuild-composer/repositories
curl -L https://raw.githubusercontent.com/wangjun1974/tips/master/ocp/edge/microshift/demo/rhel-86.json -o /etc/osbuild-composer/repositories/rhel-86.json
curl -L https://raw.githubusercontent.com/wangjun1974/tips/master/ocp/edge/microshift/demo/rhel-8.json -o /etc/osbuild-composer/repositories/rhel-8.json

### 重启 osbuild-composer.service 服务
systemctl restart osbuild-composer.service

### 创建 microshift 的 osbuild-composer 的 repo source
mkdir -p microshift-demo
cd microshift-demo
cat >microshift.toml<<EOF
id = "microshift"
name = "microshift"
type = "yum-baseurl"
url = "https://download.copr.fedorainfracloud.org/results/@redhat-et/microshift/epel-8-x86_64"
check_gpg = true
check_ssl = false
system = false
EOF
### 添加 osbuild-composer 的 repo source
composer-cli sources add microshift.toml
composer-cli sources list

### 创建 openshift-cli 的 osbuild-composer 的 repo source
cat >openshiftcli.toml<<EOF
id = "oc-cli-tools"
name = "openshift-cli"
type = "yum-baseurl"
url = "https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.8/source/SRPMS"
check_gpg = true
check_ssl = true
system = true
rhsm = true
EOF
composer-cli sources add openshiftcli.toml
composer-cli sources list

### 创建 openshift-tools 的 osbuild-composer 的 repo source
cat >openshiftools.toml<<EOF
id = "oc-tools"
name = "openshift-tools"
type = "yum-baseurl"
url = "https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.8/os"
check_gpg = true
check_ssl = true
system = true
rhsm = true
EOF
composer-cli sources add openshiftools.toml
composer-cli sources list

### 下载 microshift blueprint
curl -OL https://raw.githubusercontent.com/redhat-cop/rhel-edge-automation-arch/blueprints/microshift/blueprint.toml

### 添加 blueprints 
### 解决 blueprints 的依赖关系
composer-cli blueprints push blueprint.toml
composer-cli blueprints list
composer-cli blueprints show microshift
composer-cli blueprints depresolv microshift


### 查看状态
composer-cli status show

### 查看 compose types
composer-cli compose types

### 触发类型为 edge-container 的 compose 
### 如果希望构建 rhel for edge 的镜像，也就是 rpm-ostree 格式的镜像，类型需要为 edge-container
### 这种类型的 image 构建完成后，会生成一个 oci-archive 格式的镜像
### 镜像运行后，会启动一个 nginx web 服务器，把 rpm-ostree 在 web 服务器的 repo 目录上发布出来供客户端访问
### 客户端可以从这个位置获取更新
composer-cli compose start-ostree --ref "rhel/edge/example" microshift edge-container
### 用 journalctl 观察 compose 是否完成
### 创建时间大概15分钟
journalctl -f
### 等到消息出现
Jun 30 22:31:49 jwang-imagebuilder.example.com osbuild-worker[16129]: time="2022-06-30T22:31:49-04:00" level=info msg="Job '56665cb3-7c68-4668-83fb-9342d07d6566' (osbuild) finished"

### 查看 compose 状态 
composer-cli compose status 

### 检查日志
composer-cli compose log 2a6ac0ca-1237-4d45-be8b-db51879b9ff0

### 保存日志
composer-cli compose logs 2a6ac0ca-1237-4d45-be8b-db51879b9ff0

### 解压缩后日志文件为 logs/osbuild.log
composer-cli compose logs 2a6ac0ca-1237-4d45-be8b-db51879b9ff0

### 获取 compose image 文件
### 在获取前建议获取 compose 对应的 logs 和 metadata
composer-cli compose logs 2a6ac0ca-1237-4d45-be8b-db51879b9ff0
composer-cli compose metadata 2a6ac0ca-1237-4d45-be8b-db51879b9ff0
composer-cli compose image 2a6ac0ca-1237-4d45-be8b-db51879b9ff0

[root@jwang-imagebuilder microshift-demo]# ls -lh
total 1.1G
-rw-------. 1 root root 1.1G Jun 30 21:57 2a6ac0ca-1237-4d45-be8b-db51879b9ff0-container.tar
-rw-r--r--. 1 root root 1.1K Jun 30 21:24 blueprint.toml
-rw-r--r--. 1 root root  204 Jun 30 21:22 microshift.toml
-rw-r--r--. 1 root root  212 Jun 30 21:23 openshiftcli.toml
-rw-r--r--. 1 root root  200 Jun 30 21:24 openshiftools.toml

### 加载 container 镜像
imageid=$(cat "./2a6ac0ca-1237-4d45-be8b-db51879b9ff0-container.tar" | sudo podman load | grep -o -P '(?<=[@:])[a-z0-9]*')

### 另外一种加载镜像的方法 - 推荐
skopeo copy oci-archive:2a6ac0ca-1237-4d45-be8b-db51879b9ff0-container.tar containers-storage:localhost/microshift:0.0.1

### 为镜像打 tag
podman tag "${imageid}" "localhost/microshift:0.0.1"
### 启动镜像 - edge-container 镜像运行起来是个 nginx 服务
podman run -d --name="microshift-server" -p 8080:8080 "localhost/microshift:0.0.1"

### 创建 installer.toml 
cat > installer.toml <<EOF
name = "installer"

description = ""
version = "0.0.0"
modules = []
groups = []
packages = []
EOF

### 添加 blueprint 
composer-cli blueprints push installer.toml
composer-cli blueprints list

### 删除自定义 repos
rm -f /etc/osbuild-composer/repositories/rhel-8*.json
systemctl restart osbuild-composer.service

### 删除自定义 sources
composer-cli sources delete oc-cli-tools
composer-cli sources delete oc-tools
composer-cli sources delete microshift

### 触发类型为 edge-installer 的 compose 
### 这个新的 compose 基于前面的 edge-container 的 rpm-ostree
### rpm-ostree 通过 podman 运行在容器里，并通过 http://192.168.122.203:8080/repo 可访问
### 我的测试环境下，虚拟机不支持 UEFI 启动
### 未能测试 edge-installer 格式的 ISO
composer-cli compose start-ostree --ref "rhel/edge/example" --url http://192.168.122.203:8080/repo/ installer edge-installer

### 获取 edge-installer iso
### 首先通过 composer-cli compose status 获取 edge-installer 类型的 compose id
composer-cli compose status
### 然后通过 compose id 获取 edge-installer iso
composer-cli compose iso a0cea186-a5a7-47bc-be4f-693df0410683

### 用 iso 启动虚拟机
### 启动报错: virt-manager/QEMU: Could not read from CDROM (code 0009) on booting image
### https://github.com/symmetryinvestments/zfs-on-root-installer/issues/1
### https://ostechnix.com/enable-uefi-support-for-kvm-virtual-machines-in-linux/
### https://fedoraproject.org/wiki/Using_UEFI_with_QEMU
### https://www.kraxel.org/repos/
### http://www.linux-kvm.org/downloads/lersek/ovmf-whitepaper-c770f8c.txt
### https://www.server-world.info/en/note?os=CentOS_7&p=kvm&f=11

### 生成 kickstart 文件
# pwd
/root/microshift-demo
cat > edge.ks << EOF
lang en_US
keyboard us
timezone America/Vancouver --isUtc
rootpw --lock
#platform x86_64
reboot
text
ostreesetup --osname=rhel --url=http://192.168.122.203:8080/repo --ref=rhel/edge/example --nogpg
bootloader --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
firstboot --disable
EOF
### 重新创建 edge-container，包含 edge.ks 
podman stop microshift-server
podman rm microshift-server
podman run -d --rm -v /root/microshift-demo/edge.ks:/usr/share/nginx/html/edge.ks:z --name="microshift-server" -p 8080:8080 "localhost/microshift:0.0.1"

### 用 bootiso 启动虚拟机
### 添加启动参数 ip=192.168.122.204::192.168.122.1:255.255.255.0:edge1.example.com:ens3:none nameserver=192.168.122.1 inst.ks=http://192.168.122.203:8080/edge.ks

### 创建更新的 rpm-ostree 
### blueprint 文件内容参考
### https://raw.githubusercontent.com/redhat-cop/rhel-edge-automation-arch/blueprints/microshift/blueprint.toml
### https://github.com/redhat-et/microshift-demos/tree/main/ostree-demo
### https://www.osbuild.org/guides/user-guide/edge-container+installer.html


### 更新 microshift blueprints
### 解决 microshift blueprints 的依赖关系
composer-cli blueprints show microshift
composer-cli blueprints depsolve microshift

### 重新发布 microshift 0.0.2 edge-container
### 按照目前的测试情况
### 需要以下 sources 
### appstream
### baseos
### microshift
### oc-cli-tools
### oc-tools
### 不需要以下的 sources
### curl -L https://raw.githubusercontent.com/wangjun1974/tips/master/ocp/edge/microshift/demo/rhel-86.json -o /etc/osbuild-composer/repositories/rhel-86.json
### curl -L https://raw.githubusercontent.com/wangjun1974/tips/master/ocp/edge/microshift/demo/rhel-8.json -o /etc/osbuild-composer/repositories/rhel-8.json
systemctl restart osbuild-composer.service 

composer-cli sources add microshift.toml
composer-cli sources add openshiftcli.toml
composer-cli sources add openshiftools.toml

### 启动 edge-container 0.0.2 compose
composer-cli compose start-ostree --ref "rhel/edge/example" microshift edge-container

### 下载镜像
composer-cli compose status
composer-cli compose image xxx

### 更新镜像
skopeo copy oci-archive:xxx-container.tar containers-storage:localhost/microshift:0.0.2

### 重新启动 0.0.2 edge-container 
podman stop microshift-server
podman rm microshift-server
podman run -d --rm -v /root/microshift-demo/edge.ks:/usr/share/nginx/html/edge.ks:z --name="microshift-server" -p 8080:8080 "localhost/microshift:0.0.2"

### 登陆 rhel-for-edge 服务器检查更新，下载更新，安装更新
ssh redhat@192.168.122.204
rpm-ostree upgrade check

### 检查 rpm-ostree 状态
rpm-ostree status

### 重启系统
systemctl reboot

### 登陆 rhel-for-edge 服务器，检查 rpm-ostree 状态
ssh redhat@192.168.122.204
rpm-ostree status

### 在安装好的 RHEL Edge 系统里记录着在什么位置查看更新
[root@edge1 etc]# cat /etc/ostree/remotes.d/rhel.conf
[remote "rhel"]
url=http://192.168.122.203:8080/repo
gpg-verify=false
```

### MetalLB and Kubevirt
https://kubevirt.io/2022/Virtual-Machines-with-MetalLB.html
```
# TODO try MetalLB and microshift
# https://metallb.universe.tf/installation/
# 参考这种安装方式
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.4/config/manifests/metallb-native.yaml

# 查看 controller 日志
$ oc -n metallb-system logs $(oc -n metallb-system get pods -l component='controller' -o name) 

# 查看 speaker 日志
$ oc -n metallb-system logs $(oc -n metallb-system get pods -l component='speaker' -o name) 

# 配置 address pool
# https://deploy-preview-41167--osdocs.netlify.app/openshift-enterprise/latest/networking/metallb/about-metallb.html
cat <<EOF | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: AddressPool
metadata:
  name: addresspool-sample1
  namespace: metallb-system
spec:
  protocol: layer2
  addresses:
    - 192.168.1.100-192.168.1.255
EOF

# 生成证书信任
openssl s_client -host 192.168.1.100 -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /etc/pki/ca-trust/source/anchors/a.crt  
update-ca-trust

curl -v https://192.168.1.100:443
...
*  subjectAltName does not match 192.168.1.100

# service 
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  annotations:
    metallb.universe.tf/address-pool: addresspool-sample1
  labels:
    component: work-manager
  name: klusterlet-addon-workmgr-metallb-test
  namespace: open-cluster-management-agent-addon
spec:
  allocateLoadBalancerNodePorts: true
  clusterIP: 
  clusterIPs:
  externalIPs:
  - 10.66.208.164
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: app
    port: 443
    protocol: TCP
    targetPort: 4443
  selector:
    component: work-manager
  sessionAffinity: None
  type: LoadBalancer
EOF

curl -v https://10.66.208.164:443
...
curl: (51) SSL: no alternative certificate subject name matches target host name '10.66.208.164'

```

### 清理 ACS 对象 
```
清理 microshift 上的 acs 内容
# 如果 ACS Central 因为某种原因被删除了，
# 需要手工清理 microshift 上遗留的对象

# 删除 stackrox namespace
oc delete namespace stackrox 
```

### 安装 ACS - Sensor - microshift
```
# 创建 Cluster
# DOWNLOAD YAML FILES AND KEYS
# 拷贝 sensor-<clustername>.zip 到 microshift
rm -rf /tmp/sensor
mkdir /tmp/sensor
cd /tmp/sensor
mv <path>/sensor-<clustername>.zip .

# 执行 ACS Sensor 安装
SKIP_ORCHESTRATOR_CHECK=true sh -x sensor.sh
```

### microshift in openshift
https://github.com/openshift/microshift

### MCE 2.1 如何创建 Managed Cluster
https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.5/html-single/multicluster_engine/index#create-a-cluster
```
### MCE 2.1 通过 Hive 创建 Cluster 

### 1
### 克隆仓库 git@github.com:stolostron/acm-hive-openshift-releases.git 
### 选择 origin/release-2.5 分支
$ git clone https://github.com/stolostron/acm-hive-openshift-releases
$ cd acm-hive-openshift-releases
$ git checkout origin/release-2.5

### 2
### 定义 ClusterImageSet
$ oc apply -f clusterImageSets/fast/

### 3
### https://github.com/openshift/hive/blob/master/docs/using-hive.md#using-hive
### 创建 Cluster Deployment

```

### MCE 2.0 有哪些 pods 
```
$ oc -n multicluster-engine get pods 
NAME                                                   READY   STATUS    RESTARTS   AGE
cluster-curator-controller-864c5fcd47-d7v2j            1/1     Running   0          67s
cluster-curator-controller-864c5fcd47-hxtpt            1/1     Running   0          67s
cluster-manager-7b5df6b8cb-4b5nj                       1/1     Running   0          67s
cluster-manager-7b5df6b8cb-bxntv                       1/1     Running   0          67s
cluster-manager-7b5df6b8cb-v5hrd                       1/1     Running   0          67s
clusterclaims-controller-5f8c678f9f-7rqg8              2/2     Running   0          68s
clusterclaims-controller-5f8c678f9f-h82b6              2/2     Running   0          68s
clusterlifecycle-state-metrics-v2-587c5978b9-vg8bz     1/1     Running   0          67s
console-mce-console-7b46d86995-862sx                   1/1     Running   0          68s
console-mce-console-7b46d86995-tb5dh                   1/1     Running   0          68s
discovery-operator-7d7677c5b9-6zdgf                    1/1     Running   0          68s
hive-operator-6cf774979-5p57b                          1/1     Running   0          68s
infrastructure-operator-f5b48bcf8-9ld2w                1/1     Running   0          68s
managedcluster-import-controller-v2-6695c74d89-gdmn8   1/1     Running   0          67s
managedcluster-import-controller-v2-6695c74d89-htgjm   1/1     Running   0          66s
multicluster-engine-operator-5967d987b5-nqsmk          1/1     Running   0          9m4s
multicluster-engine-operator-5967d987b5-zgm6l          1/1     Running   0          9m4s
ocm-controller-66544d4758-2qcsx                        1/1     Running   0          67s
ocm-controller-66544d4758-5r8vc                        1/1     Running   0          67s
ocm-proxyserver-57dcd75578-nl2xq                       1/1     Running   0          67s
ocm-proxyserver-57dcd75578-z5nvm                       1/1     Running   0          67s
ocm-webhook-77bc99cb75-pqq7s                           1/1     Running   0          67s
ocm-webhook-77bc99cb75-xf5h9                           1/1     Running   0          67s
provider-credential-controller-56966d95cb-bxl67        2/2     Running   0          68s

### 查看日志

### hive-operator
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l control-plane='hive-operator' -o name)

### infrastructure-operator
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l control-plane='infrastructure-operator' -o name)

### multicluster-engine-operator
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l control-plane='backplane-operator' -o name | head -1)
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l control-plane='backplane-operator' -o name | tail -1)

### ocm-controller
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l control-plane='ocm-controller' -o name | head -1)
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l control-plane='ocm-controller' -o name | tail -1)

### ocm-proxyserver
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l control-plane='ocm-proxyserver' -o name | head -1)
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l control-plane='ocm-proxyserver' -o name | tail -1)

### ocm-webhook
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l control-plane='ocm-webhook' -o name | head -1)
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l control-plane='ocm-webhook' -o name | tail -1)

### provider-credential-controller
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l name='provider-credential-controller' -o name) -c provider-credential-controller
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l name='provider-credential-controller' -o name) -c old-provider-connection

### managedcluster-import-controller-v2
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l app='managedcluster-import-controller-v2' -o name | head -1) 
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l app='managedcluster-import-controller-v2' -o name | tail -1) 

### discovery-operator
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l app='discovery-operator' -o name) 

### cluster-manager
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l app='cluster-manager' -o name | head -1) 
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l app='cluster-manager' -o name | head -2 | tail -1) 
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l app='cluster-manager' -o name | tail -1) 

### cluster-curator-controller
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l name='cluster-curator-controller' -o name | head -1) 
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l name='cluster-curator-controller' -o name | tail -1) 

### clusterclaims-controller
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l name='clusterclaims-controller' -o name | head -1) -c clusterclaims-controller
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l name='clusterclaims-controller' -o name | head -1) -c clusterpools-delete-controller
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l name='clusterclaims-controller' -o name | tail -1) -c clusterclaims-controller
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l name='clusterclaims-controller' -o name | tail -1) -c clusterpools-delete-controller

### clusterlifecycle-state-metrics-v2
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l app='clusterlifecycle-state-metrics-v2' -o name) 

### console-mce-console
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l app='console-mce' -o name | head -1) 
$ oc -n multicluster-engine logs $(oc -n multicluster-engine get pods -l app='console-mce' -o name | tail -1) 
```

### 设置域名
```
oc -n openshift-ingress set env deployment/router-default ROUTER_SUBDOMAIN="\${name}-\${namespace}.apps.edge1.example.com" ROUTER_ALLOW_WILDCARD_ROUTES="true" ROUTER_OVERRIDE_HOSTNAME="true"

```

### ACM 2.6.1 离线安装创建 mch 时需要 annotation 设置 'installer.open-cluster-management.io/mce-subscription-spec' 指定离线环境下 MCE Operator 的 catalogSource
```
cat <<EOF | oc apply -f -
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  annotations:
    installer.open-cluster-management.io/mce-subscription-spec: '{"source": "redhat-operator-index"}'
  name: multiclusterhub
  namespace: open-cluster-management
spec: {}
EOF
```

### 获取 microshift 所需的镜像
```
$  oc get pods -A | grep -Ev "NAMESPACE" | awk '{print $1" "$2}' | while read namespace podname ; do oc -n ${namespace} get pod ${podname} -o yaml | grep "image: " ; done | sort -u | sed -e 's|^.*image: ||' 
quay.io/microshift/ovn-kubernetes-singlenode@sha256:e97d6035754fad1660b522b8afa4dea2502d5189c8490832e762ae2afb4cf142
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:4d182d11a30e6c3c1420502bec5b1192c43c32977060c4def96ea160172f71e7
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:72c751aa148bf498839e6f37b304e3265f85af1e00578e637332a13ed9545ece
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:afcc1f59015b394e6da7d73eba32de407807da45018e3c4ecc25e5741aaae2dd
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:dd49360368f93bbe1a11b8d1ce6f0f98eeb0c9230d9801a2b08a714a92e1f655
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:e5f97df4705b6f3a222491197000b887d541e9f3a440a7456f94c82523193760
registry.access.redhat.com/ubi8/openssl@sha256:8b41865d30b7947de68a9c1747616bce4efab4f60f68f8b7016cd84d7708af6b
registry.redhat.io/odf4/odf-topolvm-rhel8@sha256:362c41177d086fc7c8d4fa4ac3bbedb18b1902e950feead9219ea59d1ad0e7ad
registry.redhat.io/openshift4/ose-csi-external-provisioner@sha256:4b7d8035055a867b14265495bd2787db608b9ff39ed4e6f65ff24488a2e488d2
registry.redhat.io/openshift4/ose-csi-external-resizer@sha256:ca34c46c4a4c1a4462b8aa89d1dbb5427114da098517954895ff797146392898
registry.redhat.io/openshift4/ose-csi-livenessprobe@sha256:e4b0f6c89a12d26babdc2feae7d13d3f281ac4d38c24614c13c230b4a29ec56e
registry.redhat.io/openshift4/ose-csi-node-driver-registrar@sha256:3babcf219371017d92f8bc3301de6c63681fcfaa8c344ec7891c8e84f31420eb

除了上述这些镜像外，还需要
registry.k8s.io/pause:3.6


```

### 如何查看 Hub Subscription 日志
```
# 在 Hub 上可以检查日志，查看是否生成 AnsibleJob
$ oc -n open-cluster-management logs $(oc -n open-cluster-management get pods -l app=multicluster-operators-hub-subscription -o name)

# 手工创建 AnsibleJob

cat <<EOF | oc apply -f -
---
apiVersion: tower.ansible.com/v1alpha1
kind: AnsibleJob
metadata:
  name: prejob-test
spec:
  tower_auth_secret: ansible-controller
  job_template_name: Logger
  extra_vars: {}
EOF
```

### 获取 ACM search 组件状态及日志
```
# 获取 search 组件
$ oc -n open-cluster-management get pods | grep search 

# 查看 search-api 日志
$ oc -n open-cluster-management logs $(oc -n open-cluster-management get pods -l component=search-api -o name | head -1)
$ oc -n open-cluster-management logs $(oc -n open-cluster-management get pods -l component=search-api -o name | tail -1)

# 查看 search-collector 日志
$ oc -n open-cluster-management logs $(oc -n open-cluster-management get pods -l component=search-collector -o name)

# 查看 search-aggregator 日志
$ oc -n open-cluster-management logs $(oc -n open-cluster-management get pods -l component=search-aggregator -o name)

# 查看 redisgraph 日志
$ oc -n open-cluster-management logs $(oc -n open-cluster-management get pods -l component=redisgraph -o name)

```

### Hypershift 有哪些 namespace
```
[junwang@JundeMacBook-Pro ~]$ oc get project | grep -Ev "^openshift" 
NAME                                               DISPLAY NAME   STATUS
clusters                                                          Active
clusters-development                                              Active
default                                                           Active
default-broker                                                    Active
development                                                       Active
gitea                                                             Active
hive                                                              Active
hypershift                                                        Active
klusterlet-development                                            Active
kube-node-lease                                                   Active
kube-public                                                       Active
kube-system                                                       Active
local-cluster                                                     Active
multicluster-engine                                               Active
open-cluster-management                                           Active
open-cluster-management-agent                                     Active
open-cluster-management-agent-addon                               Active
open-cluster-management-global-set                                Active
open-cluster-management-hub                                       Active


```

### ACM/MCE 相关的 console plugin
```
# 确认 plugin 存在
$ oc get consoleplugin
NAME   AGE
acm    4d15h
mce    4d15h
# 确认 plugin 启用
$ oc get consoles.operator.openshift.io cluster -o jsonpath='{.spec.plugins}'
["mce","acm"]
```

### 配置 ACM Git App/Sub Channel 使用 insecure HTTPS connection to a Git server
https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#configuring-git-channel
```
$ oc get channel -A 
NAMESPACE                                                      NAME                                                        TYPE       PATHNAME                                                                                          AGE
ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor-ns   ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor   Git        https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/book-import.git   15m

$ oc patch channel ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor -n ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor-ns --type json -p '[{"op": "add", "path": "/spec/insecureSkipVerify", "value": true}]'

$ oc get channel -A
... 
gperatorsappsocp4-1examplecom-lab-user-2-gitops-wordpress-ns   gperatorsappsocp4-1examplecom-lab-user-2-gitops-wordpress   Git        https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/gitops-wordpress.git   25s

$ oc patch channel ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor -n ghift-operatorsappsocp4-1examplecom-lab-user-2-book-impor-ns --type json -p '[{"op": "add", "path": "/spec/insecureSkipVerify", "value": true}]'
```

### 开发环境搭建
https://github.com/openshift/microshift<br>
https://github.com/openshift/microshift/blob/main/docs/devenv_rhel8.md<br>
```
# 启用 repo
$ sudo yum repolist
Updating Subscription Management repositories.
repo id                                                     repo name
fast-datapath-for-rhel-8-x86_64-rpms                        Fast Datapath for RHEL 8 x86_64 (RPMs)
rhel-8-for-x86_64-appstream-rpms                            Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
rhel-8-for-x86_64-baseos-rpms                               Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)
rhocp-4.12-el8-beta-x86_64-rpms                             Beta rhocp-4.12 RPMs for RHEL8

$ pwd
/home/microshift/microshift

# scripts/image-builder/configure.sh 脚本安装的软件包
$ cat scripts/image-builder/configure.sh 
...
sudo dnf install -y git osbuild-composer composer-cli ostree rpm-ostree \
    cockpit-composer cockpit-machines bash-completion podman genisoimage \
    createrepo yum-utils selinux-policy-devel jq wget lorax rpm-build
sudo systemctl enable osbuild-composer.socket --now
sudo systemctl enable cockpit.socket --now
sudo firewall-cmd --add-service=cockpit --permanent

# The mock utility comes from the EPEL repository
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf install -y mock 
sudo usermod -a -G mock $(whoami)
...

# 执行环境配置，检查是否有报错。如果有报错先修复报错
$ sh -x scripts/image-builder/configure.sh

# 将 pull-secret 保存在 ~/.pull-secret.json 里

# 构建
$ sh -x ~/microshift/scripts/image-builder/build.sh -pull_secret_file ~/.pull-secret.json

```

### ACM Config Policy for Images
https://gitlab.consulting.redhat.com/tbonds/acm-policies/-/blob/main/policy-images.yaml

### RHEL for Edge + microshift kickstart template 定制
```
$ cat ./scripts/image-builder/config/kickstart.ks.template
...
# 配置网络，使用 NetworkManager keyfile plugins
network --activate --device=enp1s0 --bootproto=static --ip=192.168.122.123 --netmask=255.255.255.0 --hostname=edge-3.example.com --nameserver=192.168.122.12

# %post 通过 systemd oneshot type service 配置网络
# config first boot service
cat > /etc/systemd/system/first-boot-network-config.service <<EOF
[Unit]
Description=First Boot Service Config Network Connection
Wants=network-online.target
After=network-online.target
Before=microshift-ovs-init.service microshift.service

[Service]
Type=oneshot
ExecStart=/bin/nmcli con modify 'Wired connection 1' ipv4.method 'manual' ipv4.addresses '192.168.122.123/24' ipv4.gateway '192.168.122.1' ipv4.dns '192.168.122.12'
ExecStart=/bin/nmcli con down 'Wired connection 1'
ExecStart=/bin/nmcli con up 'Wired connection 1'

[Install]
WantedBy=multi-user.target
EOF

systemctl enable first-boot-network-config

# 配置 container registry certificate
# config registry certificate
cat > /etc/pki/ca-trust/source/anchors/registry.crt <<EOF
...
EOF

# config /etc/containers/registries.conf.d/99-miroshift-mirror-by-digest-registries.conf
cat > /etc/containers/registries.conf.d/99-miroshift-mirror-by-digest-registries.conf << EOF
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/openshift-release-dev"

[[registry]]
  prefix = ""
  location = "quay.io/rh-storage-partners"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rh-storage-partners"

[[registry]]
  prefix = ""
  location = "registry.access.redhat.com/ubi8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ubi8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2"
EOF
...


$ build.sh 一些处理阶段
$ cat scripts/image-builder/build-local.sh
# Checking available disk space
# Downloading local OpenShift and MicroShift repositories
# Loading sources for OpenShift and MicroShift
# Preparing blueprints
# Loading microshift-container blueprint v0.0.1
# Building edge-container for microshift-container v0.0.1
# Loading microshift-installer blueprint v0.0.0
# Serving microshift-container v0.0.1 container locally
# Building edge-installer for microshift-installer v0.0.0, parent microshift-container v0.0.1
# Embedding kickstart in the installer image
# Done

参考：https://git.jharmison.com/james/microshift-ansible-pull
$ ls      
LICENSE  README.md  ansible-navigator.yml  ansible.cfg  app  deploy  inventory  playbooks
$ sed -i 's|10.1.1.11|192.168.122.123|' inventory/hosts 
```

### 查看 microshift 有哪些 images
```
[microshift@edge-2 microshift]$ cat /usr/share/microshift/release/release-x86_64.json | grep sha256 | awk -F": " '{print $2}' | sed -e 's|"||g' -e 's|,$||' | sort -u
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:1638cbed9207a1cc2f84af5e0c4f70f47140028c7d0154fbdc9d594dedf29062
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:3c2eaa88d1aab0565dfc3ab001c6a829a04b591dbb0265702813a9f0c22d99fd
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:5ab6561dbe5a00a9b96e1c29818d8376c8e871e6757875c9cf7f48e333425065
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:6d241d09890258c810937d8013f31ce3405412161c51b7723a590a37303862bb
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:98ab12770309ac075fbfa617028d5ba800294309b8ec64f9ab9a2170cb90e17a
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:adcdbff7f3bf4c5b27557d9b74401be60a771d691f723857da8fe34fcb016f21
quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:f3a21964b446ad1febcdb5e8469938a42a6036baa529cc24b670b839b4c2edc7
registry.access.redhat.com/ubi8/openssl@sha256:9e743d947be073808f7f1750a791a3dbd81e694e37161e8c6c6057c2c342d671
registry.redhat.io/lvms4/topolvm-rhel8@sha256:10bffded5317da9de6c45ba74f0bb10e0a08ddb2bfef23b11ac61287a37f10a1
registry.redhat.io/openshift4/ose-csi-external-provisioner@sha256:199eac2ba4c8390daa511b040315e415cfbcfa80aa7af978a33624445b96c17c
registry.redhat.io/openshift4/ose-csi-external-resizer@sha256:9d486daffd348664c00d8b80bd0da973b902f3650acdef37e1b813278ed6c107
registry.redhat.io/openshift4/ose-csi-livenessprobe@sha256:9df24be671271f5ea9414bfd08e58bc2fa3dc4bc68075002f3db0fd020b58be0
registry.redhat.io/openshift4/ose-csi-node-driver-registrar@sha256:a4319ff7c736ca9fe20500dc3e5862d6bb446f2428ea2eadfb5f042195f4f860


```

### 在新版本 microshift 上安装 multus >= 4.12
```
### 安装前准备
### 为创建 priviledged 容器，将 namespace 打上以下 label
### pod-security.kubernetes.io/audit=privileged
### pod-security.kubernetes.io/enforce=privileged 
### pod-security.kubernetes.io/warn=privileged
$ oc label namespace kube-system pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged
$ oc get namespace kube-system --show-labels

### 打完 label 之后，继续安装
### 拷贝 multus image 和 multus deployment 相关内容到 microshift
### 拷贝 multus cni git repo 
$ scp -r multus-cni redhat@192.168.122.123:/tmp 
### 拷贝 multus cni 的 image
$ scp multus-cni-snapshot.tar redhat@192.168.122.123:/tmp
### 加载 multus cni image
$ podman load -i multus-cni-snapshot.tar
### 部署 multus cni 
$ cd /tmp/multus-cni
$ oc apply -f deployments/multus-daemonset.yml
customresourcedefinition.apiextensions.k8s.io/network-attachment-definitions.k8s.cni.cncf.io created
clusterrole.rbac.authorization.k8s.io/multus created
clusterrolebinding.rbac.authorization.k8s.io/multus created
serviceaccount/multus created
configmap/multus-cni-config created
daemonset.apps/kube-multus-ds created

# 编辑 /etc/crio/crio.conf.d/microshift-ovn.conf 
# 注释 cni_default_network 行
$ cat /etc/crio/crio.conf.d/microshift-ovn.conf | grep cni_default_network 
# cni_default_network = "ovn-kubernetes"

# 重启 crio 和 microshift 服务
$ systemctl restart crio ; systemctl restart microshift

# 添加网卡，删除网卡 networkmanager connection
$ nmcli con show
$ nmcli con delete 'Wired connection 1' 

$ mkdir -p ~/git/apps/codesys/base
$ cd ~/git/apps/codesys/base
$ cat > kustomization.yaml <<EOF
resources:
- namespace.yaml
- rolebinding.yaml
- net-attach-def-management-gateway.yaml
EOF

$ cat > namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: codesysdemo
  labels:
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/warn: privileged
    security.openshift.io/scc.podSecurityLabelSync: "false"
EOF

# 这个文件不用生成，创建 namespace 时将自动创建 default serviceaccount
$ cat > serviceaccount.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
  namespace: codesysdemo
EOF

$ cat > rolebinding.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: system:openshift:scc:privileged
  namespace: codesysdemo
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:openshift:scc:privileged
subjects:
- kind: ServiceAccount
  name: default
  namespace: codesysdemo
EOF

$ cat > net-attach-def-management-gateway.yaml <<EOF
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-management-gateway
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "host-device",
      "device": "enp8s0",
      "ipam": {
            "type": "static",
            "addresses": [
              {
                "address": "192.168.58.151/24"
              }
            ]
      }
  }'
EOF

$ oc apply -k . 

$ oc get namespace codesysdemo --show-labels

$ mkdir -p ~/git/apps/codesys/codesysedge
$ cd ~/git/apps/codesys/codesysedge

$ cat > kustomization.yaml <<EOF
resources:
- deployment.yaml
EOF

$ cat > deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesysedge
  namespace: codesysdemo
  labels:
    app: codesysedge
spec:
  selector:
    matchLabels:
      app: codesysedge
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: codesysedge
      annotations:
        k8s.v1.cni.cncf.io/networks: codesys-management-gateway
    spec:
      containers:
      - image: registry.example.com:5000/codesys/codesysedge:latest
        name: codesysedge
        securityContext:
          privileged: true        
        ports:
        - containerPort: 1217
          name: gateway
          protocol: TCP
          hostPort: 1217
        - containerPort: 1743
          name: gatewayudp
          protocol: UDP
          hostPort: 1743
EOF
$ oc apply -k . 
```

### Microshift on Code Ready Container
https://github.com/praveenkumar/simple-go-server

### Zero-Touch Provisioning Of Edge Devices Using Microshift And RHEL For Edge
https://github.com/openshift/microshift/blob/main/docs/rhel4edge_iso.md<br>
https://shonpaz.medium.com/zero-touch-provisioning-of-edge-devices-using-microshift-and-rhel-for-edge-e122836fa888<br>

### 在启动 microshift 服务时不要忘记开启 firewall
```
sudo firewall-cmd --zone=trusted --add-source=10.42.0.0/16 --permanent
sudo firewall-cmd --zone=trusted --add-source=169.254.169.1 --permanent
sudo firewall-cmd --reload
```

### 尝试一下 Node-Red
https://nodered.org/
```
### 老的习惯，先基于 ubi8 做一下 node-red 的镜像
$ cat > Dockerfile.app-v1 <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
RUN dnf install -y libpciaccess iproute net-tools procps-ng nmap-ncat iputils diffutils && dnf module install -y nodejs:12 && dnf clean all && npm install -g node-red

EXPOSE 1880/tcp

CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF

$ podman build -f Dockerfile.app-v1 -t registry.example.com:5000/codesys/nodered:v1
$ podman run --name nodered-v1 -d -t --privileged --network=host registry.example.com:5000/codesys/nodered:v1

### 凌一PLC模拟器
### http://www.ly-plc.com/downloads

### 三菱 PLC 软件
### https://blog.csdn.net/CHUXUEZHE8210/article/details/128733804
### GX Developer
### GX Works2 
### GX Works3

### 虚拟工厂 Factroy IO
### https://factoryio.com/
```

### 尝试 rhel 9.2 上的 microshift
```
### 检查日志 - router-default
$ oc -n openshift-ingress logs $(oc get pods -n openshift-ingress -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default -o name)
### 如果报错
$ oc -n openshift-ingress delete $(oc get pods -n openshift-ingress -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default -o name)

### 检查日志 - ovnkube-master
$ oc -n openshift-ovn-kubernetes logs $(oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-master -o name)

### 检查日志 - ovnkube-node
$ oc -n openshift-ovn-kubernetes logs $(oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-node -o name)
### 如果报错
$ oc -n openshift-ovn-kubernetes delete $(oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-node -o name)

### microshift on rhel 9.2  
### 报错 ACM Observability 
$ oc -n open-cluster-management-agent-addon get events -w
...
5m51s       Warning   FailedCreate        replicaset/klusterlet-addon-workmgr-5867cbc6c9      Error creating: pods "klusterlet-addon-workmgr-5867cbc6c9-kd64d" is forbidden: violates PodSecurity "restricted:latest": seccompProfile (pod or container "acm-agent" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")

# 为 namespace open-cluster-management-agent-addon 添加 pod-security 相关 label
### pod-security.kubernetes.io/audit=privileged
### pod-security.kubernetes.io/enforce=privileged 
### pod-security.kubernetes.io/warn=privileged
$ oc label namespace open-cluster-management-agent-addon pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged
$ oc get namespace open-cluster-management-agent-addon --show-labels

# 触发 deployment 重新部署
$ oc -n open-cluster-management-agent-addon patch deployment/application-manager --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

$ oc -n open-cluster-management-agent-addon patch deployment/config-policy-controller --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

$ oc -n open-cluster-management-agent-addon patch deployment/klusterlet-addon-workmgr --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

# 为 namespace open-cluster-management-agent-addon-observability 添加 pod-security 相关 label
$ oc label namespace open-cluster-management-addon-observability pod-security.kubernetes.io/audit=privileged --overwrite
$ oc label namespace open-cluster-management-addon-observability pod-security.kubernetes.io/enforce=privileged --overwrite
$ oc label namespace open-cluster-management-addon-observability pod-security.kubernetes.io/warn=privileged --overwrite
$ oc get namespace open-cluster-management-addon-observability --show-labels

# 在 Hub 上删除 label 
(hub)$ oc label managedcluster edge-3 openshiftVersion-
(hub)$ oc get managedcluster edge-3 --show-labels

# 在 microshift cluster 上 添加 ClusterRole endpoint-observability-operator-clusterrole 和 ClusterRoleBinding endpoint-observability-operator-clusterrolebinding
(edge-3)$ cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: endpoint-observability-operator-clusterrole
rules:
- apiGroups:
  - observability.open-cluster-management.io
  resources:
  - observabilityaddons/finalizers
  verbs:
  - get
  - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: endpoint-observability-operator-clusterrolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: endpoint-observability-operator-clusterrole
subjects:
- kind: ServiceAccount
  name: endpoint-observability-operator-sa
  namespace: open-cluster-management-addon-observability
EOF

# 查看 events 
$ oc -n open-cluster-management-addon-observability get events -w 
$ oc get deployment -A
$ oc get statefulset -A
$ oc get daemonset -A
$ oc get pods -A

# 为 serviceaccount 添加权限
$ oc adm policy add-scc-to-user privileged -z kube-state-metrics -n open-cluster-management-addon-observability
$ oc -n open-cluster-management-addon-observability patch deployment/kube-state-metrics --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

# 为 serviceaccount 添加权限
$ oc adm policy add-scc-to-user privileged -z node-exporter -n open-cluster-management-addon-observability
$ oc -n open-cluster-management-addon-observability patch daemonset/node-exporter --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

### external api kubeconfig file 
/var/lib/microshift/resources/kubeadmin/edge-3.example.com/kubeconfig
$ cp /var/lib/microshift/resources/kubeadmin/edge-3.example.com/kubeconfig ~/.kube/config

### 检查 external api server 证书
$ echo | openssl s_client -servername 192.168.122.123 -connect 192.168.122.123:6443 | openssl x509 -text

# 测试 cluster-proxy 的程序
https://github.com/open-cluster-management-io/cluster-proxy/blob/main/examples/test-client/main.go


#### 查看 Cluster 的内容
#### RHACM 设置用户 bob 在 RHACM 里作为 Cluster ocp1 的 admin
oc --kubeconfig=/srv/workspace/ocphub/upi/auth/kubeconfig create clusterrolebinding crb-ocm-cma-bob-ocp1 --clusterrole=open-cluster-management:admin:ocp1 --user=bob
oc --kubeconfig=/srv/workspace/ocphub/upi/auth/kubeconfig create rolebinding rb-ocm-cma-bob-ocp1 -n ocp1 --clusterrole=admin --user=bob

#### 检查用户 bob 是否可查看对象 managedCluster 
oc --kubeconfig=/srv/workspace/ocphub/upi/auth/kubeconfig auth can-i list managedCluster -n ocp1 --as=bob
oc --kubeconfig=/srv/workspace/ocphub/upi/auth/kubeconfig auth can-i list managedCluster -n ocp2 --as=bob

#### 设置 bob 为 ocp1 的 admin 和 clusteradmin
oc --kubeconfig=/srv/workspace/ocp1/upi/auth/kubeconfig adm policy add-cluster-role-to-user admin bob
oc --kubeconfig=/srv/workspace/ocp1/upi/auth/kubeconfig adm policy add-cluster-role-to-user cluster-admin bob


#### 在 microshift 上安装 metallb
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.11/config/manifests/metallb-native.yaml

#### 添加 pod security labels
#### https://github.com/openshift/cluster-policy-controller/pull/127 
#### 在这个改变之后，需要添加 label security.openshift.io/scc.podSecurityLabelSync=false 
kubectl label namespace metallb-system pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged security.openshift.io/scc.podSecurityLabelSync=false --overwrite=true
kubectl get namespace metallb-system --show-labels

#### 为 serviceaccount 添加 scc
oc adm policy add-scc-to-user anyuid -z controller -n metallb-system
oc adm policy add-scc-to-user privileged -z speaker -n metallb-system

#### 触发 controller/speaker 部署
kubectl -n metallb-system patch deployment/controller --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"
kubectl -n metallb-system patch daemonset/speaker --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"   

#### 删除时运行
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.11/config/manifests/metallb-native.yaml

#### 创建 AddressPool 与 L2Advertisement
cat <<EOF | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: addresspool-sample1
  namespace: metallb-system
spec:
  addresses:
    - 192.168.122.140-192.168.122.150
EOF
cat <<EOF | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2adver
  namespace: metallb-system
EOF

#### 查看日志
#### controller
oc -n metallb-system logs $(oc get pods -n metallb-system -l component=controller -o name)
#### speaker
oc -n metallb-system logs $(oc get pods -n metallb-system -l component=speaker -o name)

#### 检查证书
echo | openssl s_client -servername 192.168.122.140 -connect 192.168.122.140:443 2>/dev/null | openssl x509 -text

oc get pods -n metallb-system controller-7dbf5bd4d4-2cghw -o yaml  | grep label -A10 


#### 安装 cert-manager operator
#### 创建 Issuer 
oc new-project test
cat <<EOF | oc apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: cert-issuer
  namespace: test
spec:
  selfSigned: {}
EOF

#### 参考
#### https://cert-manager.io/docs/concepts/certificate/
cat <<EOF | oc apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: certificate-tls
  namespace: test
spec:
  commonName: foo.example.com
  dnsNames:
    - example.com
    - foo.example.com
    - bar.example.com
    - 192.168.122.140
  duration: 20h
  issuerRef:
    name: cert-issuer
    kind: Issuer
  isCA: false
  renewBefore: 10h
  secretName: cert-secret
EOF

#### 检查 ca.crt 和 tls.crt
echo | oc get secret cert-secret -o jsonpath='{.data.ca\.crt}'| base64 -d  | openssl x509 -text | more
echo | oc get secret cert-secret -o jsonpath='{.data.tls\.crt}'| base64 -d  | openssl x509 -text | more

#### 参考晓宇的blog https://blog.csdn.net/weixin_43902588/article/details/127047109
#### 安装 Vault
helm repo add hashicorp https://helm.releases.hashicorp.com
curl -OL https://raw.githubusercontent.com/hashicorp/vault-helm/main/values.openshift.yaml
cat values.openshift.yaml
oc new-project vault
helm install vault-server hashicorp/vault -f values.openshift.yaml
# 设置 pod-security 相关 label
kubectl label namespace vault pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged security.openshift.io/scc.podSecurityLabelSync=false --overwrite=true

# 初始化 vault
oc get pod -n vault
oc exec -n vault -ti vault-server-0 -- vault operator init

# unseal vault 后 login vault
oc exec -n vault -ti vault-server-0 -- vault operator unseal hVhxM5cDiywoQgTotsGhp33CPPUpSJvmlrL0LEN4iMQl
oc exec -n vault -ti vault-server-0 -- vault operator unseal e8dQMEJG3QxapbiawfqYdUKPH+ml+8rb9N/KiZUc5D2D
oc exec -n vault -ti vault-server-0 -- vault operator unseal p4JN8UIBBXaR4RjMKulizNvbEUYMtSdgQHVKDrBF0IOR
oc exec -n vault -it vault-server-0 -- vault login hvs.wRsu6MNJLUWTiKLxULTg9FaC

# 启用 kv secret
oc exec -n vault -it vault-server-0 -- vault secrets enable -path=secret/ kv
# 创建 secret/openshiftpullsecret 
# 详细内容参见 https://blog.csdn.net/weixin_43902588/article/details/127047109
oc exec -n vault -it vault-server-0 -- vault kv put secret/openshiftpullsecret dockerconfigjson='xxxx'
# 获取 secret/openshiftpullsecret
oc exec -n vault -it vault-server-0 -- vault kv get secret/openshiftpullsecret

# 安装 external secret operator
# 创建 OperatorConfig
# 创建 Vault Root Token
# 使用 vault 服务地址和上一步生成的 vault-token 作为认证信息，创建一个 ClusterSecretStore 对象

# 创建应用项目 my-app
oc new-project my-app
# 创建一个 ExternalSecret 对象，它会通过 ClusterSecretStore 访问 Vault 后端 secret/openshiftpullsecret 中的 dockerconfigjson 主键，并将其保存到名为 pullsecret 的 Secret 中
cat << EOF | oc apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: pullsecret-eso
  namespace: my-app
spec:
  refreshInterval: "15s"
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: pullsecret
  data:
  - secretKey: dockerconfigjson
    remoteRef:
      key: secret/openshiftpullsecret
      property: dockerconfigjson
EOF
# 查看创建的 externalsecret 对象，其状态为 SecretSynced 说明已经从 Vault 后端完成 Secret 的数据同步
oc get externalsecret pullsecret-eso -n my-app
NAME             STORE           REFRESH INTERVAL   STATUS         READY
pullsecret-eso   vault-backend   15s                SecretSynced   True
# 如果 ExternalSecret 的状态是 SecretSyncedError，在处理完 ClusterSecretStore 的问题后
# kubectl annotate ExternalSecret pullsecret-eso force-sync=$(date +%s) --overwrite

# 检查 secret pullsecret 的内容
$ oc get secret pullsecret -n my-app -o yaml
apiVersion: v1
data:
  dockerconfigjson: xxx
immutable: false
kind: Secret
metadata:
  annotations:
    force-sync: "1696755881"
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"external-secrets.io/v1beta1","kind":"ExternalSecret","metadata":{"annotations":{},"name":"pullsecret-eso","namespace":"my-app"},"spec":{"data":[{"remoteRef":{"key":"secret/openshiftpullsecret","property":"dockerconfigjson"},"secretKey":"dockerconfigjson"}],"refreshInterval":"15s","secretStoreRef":{"kind":"ClusterSecretStore","name":"vault-backend"},"target":{"name":"pullsecret"}}}
    reconcile.external-secrets.io/data-hash: 76f1b4be9d97679ecff6a06a82333268
  creationTimestamp: "2023-10-08T09:04:42Z"
  labels:
    reconcile.external-secrets.io/created-by: a440d3497c63ca020299f88e0a37f5bd
  name: pullsecret
  namespace: my-app
  ownerReferences:
  - apiVersion: external-secrets.io/v1beta1
    blockOwnerDeletion: true
    controller: true
    kind: ExternalSecret
    name: pullsecret-eso
    uid: 34e754a5-d0dc-43d8-9cea-673fe163b633
  resourceVersion: "57796"
  uid: 2249f10e-9759-4df5-afde-32f5085b27f4
type: Opaque

### 获取 ACM 下 microshift 的 LoggingCA
$ oc get ManagedClusterInfo edge-3  -n edge-3 -o jsonpath='{.spec.loggingCA}' | base64 -d

### 在 k8s 上安装 nginx ingress controller - v1.18.18
### https://blog.csdn.net/D1179869625/article/details/128235603
### https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
kubectl apply -f mandatory.yaml
wget  https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/baremetal/service-nodeport.yaml
kubectl apply -f service-nodeport.yaml
kubectl get pods --namespace=ingress-nginx

### 在 k8s v1.18.18 上安装 metallb v0.12
wget https://raw.githubusercontent.com/metallb/metallb/v0.11/manifests/metallb.yaml
# 安装 metallb
kubectl create namespace metallb-system
kubectl apply -f metallb.yaml

# 创建 MetalLB 
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: my-ip-space
      protocol: layer2
      addresses:
      - 192.168.122.124/32
EOF

# 查看 service type: LoadBalancer svc klusterlet-addon-workmgr
$ kubectl get svc -A | grep klusterlet-addon-workmgr 
open-cluster-management-agent-addon           klusterlet-addon-workmgr                                          LoadBalancer   10.97.163.60     192.168.122.124                                                                     443:32407/TCP                  16h

# 查看 metallb controller 日志
$ kubectl -n metallb-system logs $(kubectl get pods -n metallb-system -l component=controller -o name) 
{"branch":"HEAD","caller":"level.go:63","commit":"v0.11.0","goversion":"gc / go1.16.9 / amd64","level":"info","msg":"MetalLB controller starting version 0.11.0 (commit v0.11.0, branch HEAD)","ts":"2023-10-11T02:00:56.604514553Z","version":"0.11.0"}
{"caller":"level.go:63","level":"info","msg":"secret succesfully created","op":"CreateMlSecret","ts":"2023-10-11T02:00:56.634476037Z"}
{"caller":"level.go:63","configmap":"metallb-system/config","event":"configLoaded","level":"info","msg":"config (re)loaded","ts":"2023-10-11T02:00:56.735633869Z"}
{"caller":"level.go:63","error":"controller not synced","level":"error","msg":"controller not synced yet, cannot allocate IP; will retry after sync","op":"allocateIP","service":"open-cluster-management-agent-addon/klusterlet-addon-workmgr","ts":"2023-10-11T02:00:56.735943508Z"}
{"caller":"level.go:63","event":"stateSynced","level":"info","msg":"controller synced, can allocate IPs now","ts":"2023-10-11T02:00:56.736948213Z"}
{"caller":"level.go:63","event":"ipAllocated","ip":"192.168.122.124","level":"info","msg":"IP address assigned by controller","service":"open-cluster-management-agent-addon/klusterlet-addon-workmgr","ts":"2023-10-11T02:00:56.741992694Z"}
{"caller":"level.go:63","event":"serviceUpdated","level":"info","msg":"updated service object","service":"open-cluster-management-agent-addon/klusterlet-addon-workmgr","ts":"2023-10-11T02:00:56.762350222Z"}

# ACM -> Search -> Pod -> Log 功能在 k8s v1.18 上这样处理后就正常了


### 查看 microshift 上的 openshift-service-ca singing-key
$ oc get secret -n openshift-service-ca signing-key -o template='{{index .data "tls.crt"}}' | base64 -d | openssl x509 -text



#### 创建

mkdir -p /var/www/html/repos/microshift
cat > reposync.sh <<'EOF'
#!/bin/bash

localPath="/var/www/html/repos/microshift/"
fileConn="/getPackage/"

# fast-datapath-for-rhel-9-x86_64-rpms
# rhocp-4.14-for-rhel-9-x86_64-rpms

for i in fast-datapath-for-rhel-9-x86_64-rpms rhocp-4.14-for-rhel-9-x86_64-rpms 
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --downloadcomps --download-metadata
  
done

exit 0
EOF
```