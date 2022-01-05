### 测试 Assisted Installer 
参考文档：<br>
https://cloud.redhat.com/blog/assisted-installer-on-premise-deep-dive<br>
```
# Assisted Installer On-Premise Deep Dive

# 1. 安装 Assisted Install 服务
# 这个部分按照安装 openshift upi support 服务器来安装一台服务器
yum groupinstall -y "Development Tools"
yum install -y python3-pip socat make tmux git jq crun

# 设置代理（可选）
# 如果 git clone 有问题，可以考虑设置代理
PROXY_URL="10.0.10.10:3128/"

export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export ftp_proxy="$PROXY_URL"
export no_proxy="127.0.0.1,localhost,.rhsacn.org,.gcr.io,.quay.io"

# For curl
export HTTP_PROXY="$PROXY_URL"
export HTTPS_PROXY="$PROXY_URL"
export FTP_PROXY="$PROXY_URL"
export NO_PROXY="127.0.0.1,localhost,.rhsacn.org,.gcr.io,.quay.io"

git clone https://github.com/openshift/assisted-service
cd assisted-service
IP=192.168.122.12
AI_URL=http://$IP:8090
AI_IMAGE_URL=http://$IP:8888

# 修改 onprem-environment 和 Makefile，设置 URL 和 port forwarding
sed -i "s@^SERVICE_BASE_URL=.*@SERVICE_BASE_URL=$AI_URL@" onprem-environment
sed -i "s@^IMAGE_SERVICE_BASE_URL=.*@IMAGE_SERVICE_BASE_URL=$AI_IMAGE_URL@" onprem-environment
# 下面这条命令新仓库里已经不用之行 2022/01/04 
# sed -i "s/5432,8000,8090,8080/5432:5432 -p 8000:8000 -p 8090:8090 -p 8080:8080/" Makefile
make deploy-onprem

```