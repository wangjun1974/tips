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
aws --endpoint=http://minio-velero.apps.cluster-m7n8k.m7n8k.sandbox1752.opentlc.com s3 ls 
aws --endpoint=http://minio-velero.apps.cluster-m7n8k.m7n8k.sandbox1752.opentlc.com s3 mb s3://observability

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
      endpoint: minio-velero.apps.cluster-r2j8m.r2j8m.sandbox212.opentlc.com
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

[[modules]]
name = "crun"
version = "*"
EOF

# 基于 blueprint.toml 创建 blueprints
composer-cli blueprints push blueprint.toml

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