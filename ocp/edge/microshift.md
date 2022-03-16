### microshift
https://blog.csdn.net/weixin_43902588/article/details/122190458
```
# RHEL8.4 最小化上安装 cri-o
mkdir -p /data/OCP-4.9.9/yum

# 将 rhocp-4.9-for-rhel-8-x86_64-rpm 安装源从外部拷入进来
scp /data/OCP-4.9.9/yum/rhocp-4.9-for-rhel-8-x86_64-rpms.tar.gz 192.168.122.203:/data/OCP-4.9.9/yum

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

# 安装 tar 
yum install tar gzip conntrack-tools

# 解压缩
cd /data/OCP-4.9.9/yum
tar zxf rhocp-4.9-for-rhel-8-x86_64-rpms.tar.gz

# 更新软件仓库内容
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

[rhocp-4.9-for-rhel-8-x86_64-rpms] 
name=rhocp-4.9-for-rhel-8-x86_64-rpms
baseurl=file:///data/OCP-4.9.9/yum/rhocp-4.9-for-rhel-8-x86_64-rpms/
enabled=1
gpgcheck=0 
EOF

# 安装 cri-o cri-tools
dnf module disable container-tools:rhel8
dnf module enable container-tools:3.0
dnf install -y cri-o cri-tools
systemctl enable crio --now

# 安装 podman
sudo dnf install -y podman

# 执行初始化脚本
# curl -sfL https://raw.githubusercontent.com/redhat-et/microshift/main/install.sh | bash
# curl -o https://raw.githubusercontent.com/redhat-et/microshift/main/install.sh

# 将镜像同步到本地
LOCAL_SECRET_JSON=/data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json

# quay.io/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920 docker://registry.example.com:5000/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920

# quay.io/microshift/microshift:4.8.0-0.microshift-2022-01-06-210147
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/microshift/microshift:4.8.0-0.microshift-2022-01-06-210147 docker://registry.example.com:5000/microshift/microshift:4.8.0-0.microshift-2022-01-06-210147

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

# 
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
EOF

# 生成 ~/.docker/config.json
mkdir -p ~/.docker
cat > ~/.docker/config.json <<EOF
{"auths":{"registry.example.com:5000":{"auth":"b3BlbnNoaWZ0OnJlZGhhdA=="}}}
EOF

# 拷贝 registry.example.com 的证书信任
scp registry.example.com:/etc/pki/ca-trust/source/anchors/registry.crt /etc/pki/ca-trust/source/anchors
update-ca-trust

# 尝试拉取 registry.example.com:5000/microshift/microshift:latest
podman pull registry.example.com:5000/microshift/microshift:latest

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

# 拷贝 oc 客户端
scp /data/OCP-4.9.9/ocp/ocp-client/openshift-client-linux-4.9.9.tar.gz 192.168.122.203:/root
sudo tar zxf openshift-client-linux-4.9.9.tar.gz -C /usr/local/bin oc kubectl

# 拷贝 kubeconfig
mkdir ~/.kube
podman cp microshift:/var/lib/microshift/resources/kubeadmin/kubeconfig ~/.kube/config
chown `whoami`: ~/.kube/config

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
  oc patch sa $sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
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

### 参考链接
[WIP] Add OAuth API server to Microshift #244<br>
https://github.com/redhat-et/microshift/pull/244