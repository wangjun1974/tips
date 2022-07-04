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

composer-cli compose status 
composer-cli compose log 2a6ac0ca-1237-4d45-be8b-db51879b9ff0
### 保存日志
composer-cli compose logs 2a6ac0ca-1237-4d45-be8b-db51879b9ff0

### 解压缩后日志文件为 logs/osbuild.log
composer-cli compose logs 2a6ac0ca-1237-4d45-be8b-db51879b9ff0

### 获取 compose image 文件
### 在获取前建议获取 compose 对应的 logs 和 metadata
composer-cli compose log 2a6ac0ca-1237-4d45-be8b-db51879b9ff0
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
### 另外一种加载镜像的方法
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
### rpm-ostree 通过 podman 运行在容器里，并通过 http://localhost:8080/repo 可访问
composer-cli compose start-ostree --ref "rhel/edge/example" --url http://localhost:8080/repo/ installer edge-installer

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