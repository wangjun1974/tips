### 测试 Assisted Installer 
参考文档：<br>
https://cloud.redhat.com/blog/assisted-installer-on-premise-deep-dive<br>
```
# Assisted Installer On-Premise Deep Dive

# 1. 安装 Assisted Install 服务
# 这个部分先安装 openshift upi support 服务器
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
setenforce 0
dnf install -y @container-tools
dnf group install "Development Tools" -y
dnf -y install python3-pip socat make tmux git jq crun
git clone https://github.com/openshift/assisted-service
cd assisted-service
IP=192.167.124.1
AI_URL=http://$IP:8090
```