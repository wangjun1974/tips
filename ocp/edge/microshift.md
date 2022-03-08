### 在 RHEL8.4 上安装 microshift
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
yum install tar gzip

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

# 将 quay.io/microshift/microshift:latest 同步到本地 registry.example.com:5000/microshift/microshift:latest
LOCAL_SECRET_JSON=/data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/microshift/microshift:latest docker://registry.example.com:5000/microshift/microshift:latest

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
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon --rm --replace --sdnotify=container --label io.containers.autoupdate=registry --network=host --privileged -d --name microshift -v /var/hpvolumes:/var/hpvolumes:z,rw,rshared -v /var/run/crio/crio.sock:/var/run/crio/crio.sock:rw,rshared -v microshift-data:/var/lib/microshift:rw,rshared -v /var/lib/kubelet:/var/lib/kubelet:z,rw,rshared -v /var/log:/var/log -v /etc:/etc registry.example.com:5000/microshift/microshift:latest
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
address=/cluster.local/${IPADDR}
bind-interfaces
EOF
systemctl restart dnsmasq


```

