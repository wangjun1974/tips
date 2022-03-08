/### 在 RHEL8.4 上安装 microshift
```
# RHEL8.4 最小化上安装 cri-o
mkdir -p /data/OCP-4.9.9/yum

# 将 rhocp-4.9-for-rhel-8-x86_64-rpm 安装源从外部拷入进来
scp /data/OCP-4.9.9/yum/rhocp-4.9-for-rhel-8-x86_64-rpms.tar.gz 192.168.122.203:/data/OCP-4.9.9/yum

# 挂载光驱
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
sudo dnf install -y cri-o cri-tools
sudo systemctl enable crio --now

# 安装 podman
sudo dnf install -y podman

# 将镜像同步到本地
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

# 生成 /etc/systemd/system/microshift.service，引用本地镜像 registry.example.com:5000/microshift/microshift:latest
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

# 配置 dnsmasq
IPADDR=$(/usr/sbin/ip a s dev ens3 | /usr/bin/grep 'inet ' | /usr/bin/awk '{print $2}' | /usr/bin/sed -e 's|/24||')
dnf install -y dnsmasq
cat >> /etc/dnsmasq.conf <<EOF
address=/example.com/${IPADDR}
address=/registry.example.com/192.168.122.12
address=/microshift-demo.example.com/192.168.122.203
bind-interfaces
EOF
systemctl restart dnsmasq

nmcli con mod ens3 ipv4.dns '127.0.0.1' +ipv4.dns '192.168.122.12'
nmcli con down ens3 && nmcli con up ens3 

# 拷贝 quay.io/tasato/hello-js 到 registry.example.com:5000/tasato/hello-js
LOCAL_SECRET_JSON=/data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/tasato/hello-js:latest docker://registry.example.com:5000/tasato/hello-js:latest


# 配置一下 dns
cat >> /etc/named.rfc1912.zones <<EOF
zone "edge-1.example.com" IN {
        type master;
        file "edge-1.example.com.zone";
        allow-transfer { any; };
};

EOF

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

lb             IN A                          192.168.122.12

api            IN A                          192.168.122.12
api-int        IN A                          192.168.122.12
*.apps         IN A                          192.168.122.12

master-0       IN A                          192.168.122.203
microshift-demo IN A                          192.168.122.203

EOF


cat >> /var/named/168.192.in-addr.arpa.zone  <<'EOF'

203.122.168.192.in-addr.arpa.    IN PTR      master-0.edge-1.example.com.

203.122.168.192.in-addr.arpa.    IN PTR      microshift-demo.edge-1.example.com.

EOF

systemctl restart named

# 配置一下 haproxy 
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




# 
oc new-project test
oc create deploy hello --image=registry.example.com:5000/tasato/hello-js:latest
oc expose deploy hello --port 8080
oc expose svc hello --hostname=hello.example.com
oc get route
```

