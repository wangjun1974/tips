### CODESYS Gateway 设置
https://blog.csdn.net/weixin_44112083/article/details/122283497<br>
```
# 双击 'Device' 
# 网关 -> 添加网关 -> 名称:'Gateway-2' -> 驱动:'TCP/IP' -> 输入 IP 地址 -> 确定
# 在 CODESYS Runtime for Linux 所在的机器上
$ /etc/init.d/codesysedge status
$ /etc/init.d/codesysedge start
$ /etc/init.d/codesysedge status
$ /etc/init.d/codesyscontrol status
$ /etc/init.d/codesyscontrol start
$ /etc/init.d/codesyscontrol status

# 扫描网络，找到 CODESYS Runtime for Linux 机器
# 选择工具栏'登陆'
# 激活下位机
# 选择工具栏'启动‘，下发程序到下位机
# 双击 'Visualization' - 可以在可视化界面里查看
```

### CODESYS 安装 Addon
https://blog.csdn.net/goo__gle/article/details/117018937<br>
```
# 运行 CODESYS Installer 
# 选择 Change
# 选择 Install File
# 选择扩展名为 package 的 Addon
```

### 在 RHEL 8.6 上安装 codesyscontrol 与 codesysedge
```
1. 最小化安装 RHEL 8.6
2. 挂载 RHEL 8.6 iso
3. 创建本地软件仓库
cat > /etc/yum.repos.d/local.repo <<EOF
[BaseOS]
name=BaseOS
baseurl=file:///mnt/BaseOS/
enabled=1
gpgcheck=0

[AppStream]
name=AppStream
baseurl=file:///mnt/AppStream/
enabled=1
gpgcheck=0

EOF

4. 安装 codesyscontrol 与 codesysedge
$ ll /root/codesys_runtime/
total 17864
-rw-r--r--. 1 root root 10793015 Jan 17 09:13 codemeter-lite-7.20.4402.501-2.x86_64.rpm
-rw-r--r--. 1 root root  5510340 Jan 17 09:13 codesyscontrol-4.1.0.0-2.x86_64.rpm
-rw-r--r--. 1 root root  1980059 Jan 17 09:13 codesysedge-4.1.0.0-2.x86_64.rpm

# 安装依赖软件包 libpciaccess
# codesyscontrol 依赖 libpciaccess
$ yum install -y libpciaccess

# 安装 codesyscontrol 与 codesysedge
# 软件包有冲突，需强制安装
# Verifying...                          ################################# [100%]
# Preparing...                          ################################# [100%]
#        file / from install of codesysedge-4.1.0.0-2.x86_64 conflicts with file from package filesystem-3.8-6.el8.x86_64
#        file /etc/init.d from install of codesysedge-4.1.0.0-2.x86_64 conflicts with file from package chkconfig-1.19.1-1.el8.x86_64
#        file / from install of codesyscontrol-4.1.0.0-2.x86_64 conflicts with file from package filesystem-3.8-6.el8.x86_64
#        file /etc/init.d from install of codesyscontrol-4.1.0.0-2.x86_64 conflicts with file from package chkconfig-1.19.1-1.el8.x86_64
$ rpm -ivh codesyscontrol-4.1.0.0-2.x86_64.rpm codesysedge-4.1.0.0-2.x86_64.rpm --force

5. 制作 codesyscontrol 和 codesysedge 容器
# 尝试 UBI + codesyscontrol
# 尝试 UBI + codesysedge
$ mkdir -p ~/.config/containers
# 拷贝包含 pull secret 的 auth.json 到这个目录下

# 在 ubi 里安装 libpciaccess
# https://access.redhat.com/solutions/5558771
# https://developers.redhat.com/blog/2019/05/31/working-with-red-hat-enterprise-linux-universal-base-images-ubi#exploring_the_ubi_container_image
FROM registry.access.redhat.com/ubi8/ubi:latest
RUN SMDEV_CONTAINER_OFF=1 subscription-manager register --org=XXXXXX --activationkey=container_builds && \
    yum install -y openssh-server && \
    SMDEV_CONTAINER_OFF=1 subscription-manager unregister && \
    yum clean all && \
    echo -e '[main]\nenabled=0' >  /etc/yum/pluginconf.d/subscription-manager.conf

podman run -it registry.redhat.io/ubi8/ubi bash

# codesyscontrol
Dockerfile
cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
RUN dnf install -y libpciaccess && \
    dnf clean all 
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
RUN rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force
RUN rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 1740/udp

ENTRYPOINT ["/opt/codesys/bin/codesyscontrol.bin"]
CMD ["/etc/CODESYSControl.cfg"]
EOF

podman build -f Dockerfile  -t registry.example.com:5000/codesys/codesyscontrol 

podman run --name codesyscontrol -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontrol 

# codesysedge
$ mkdir codesysedge
$ cd codesysedge
$ cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
RUN dnf install -y iproute net-tools && \
    dnf clean all 
COPY codesysedge-4.1.0.0-2.x86_64.rpm /tmp/codesysedge-4.1.0.0-2.x86_64.rpm
RUN rpm -ivh /tmp/codesysedge-4.1.0.0-2.x86_64.rpm --force
RUN rm -f /tmp/codesysedge-4.1.0.0-2.x86_64.rpm
EXPOSE 1217/tcp
EXPOSE 1743/udp

ENTRYPOINT ["/opt/codesysedge/bin/codesysedge.bin"]
CMD ["/etc/Gateway.cfg"]
EOF

$ podman build -f Dockerfile  -t registry.example.com:5000/codesys/codesysedge 
$ podman run --name codesysedge -d -t --network host --privileged registry.example.com:5000/codesys/codesysedge 


# 开放防火墙端口
firewall-cmd --add-port=1217/tcp --zone=public --permanent
firewall-cmd --add-port=1743/udp --zone=public --permanent
firewall-cmd --add-port=11740/tcp --zone=public --permanent
firewall-cmd --add-port=1740/udp --zone=public --permanent
firewall-cmd --add-port=4840/tcp --zone=public --permanent
firewall-cmd --reload
```


### OCP migration
https://ics-cert.kaspersky.com/publications/reports/2019/09/18/security-research-codesys-runtime-a-plc-control-framework-part-1/<br>
https://forge.codesys.com/forge/talk/Runtime/thread/4078a2ed28/<br>
https://www.cnblogs.com/ericnie/p/16301269.html<br>
```
# 安装 kubernetes-nmstate-operator
# 创建 codesys namespace
$ oc new-project codesys

# 为 serviceaccount default 添加 privileged scc
$ oc adm policy add-scc-to-user privileged -z default -n codesys

$ mkdir base
$ cd base
# 
# https://www.adminsub.net/ipv4-subnet-calculator/192.168.122.128/30
# Network 192.168.122.140/30
# Broadcast: 192.168.122.143
# FirstIP: 192.168.122.141
# LastIP: 192.168.122.142
cat > net-attach-def.yaml <<EOF
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys
  namespace: codesys
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens10",
      "mode": "bridge",
      "ipam": {
            "type": "whereabouts",
            "range": "192.168.122.140/30"
      }
  }'
EOF

cat > kustomization.yaml <<EOF
resources:
- net-attach-def.yaml
EOF

$ mkdir codesysedge
$ cd codesysedge

$ cat > deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesysedge
  namespace: codesys
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
        k8s.v1.cni.cncf.io/networks: codesys
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

$ cat > service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: codesysedge
  namespace: codesys
  labels:
    service.kubernetes.io/service-proxy-name: multus-proxy
    app: codesysedge
  annotations:
    k8s.v1.cni.cncf.io/service-network: codesys
spec:
  ports:
    - port: 1217
      name: gateway
      protocol: TCP
    - port: 1743
      name: gatewayudp
      protocol: UDP
  selector:
    app: codesysedge
EOF

$ cat > kustomization.yaml <<EOF
resources:
- deployment.yaml
- service.yaml
EOF

### codesyscontrol 
mkdir codesyscontrol
cd codesyscontrol

cat > deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesyscontrol
  namespace:codesys
  labels:
    app: codesyscontrol
spec:
  selector:
    matchLabels:
      app: codesyscontrol
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: codesyscontrol
      annotations:
        k8s.v1.cni.cncf.io/networks: codesys          
    spec:
      containers:
      - image: registry.example.com:5000/codesys/codesyscontrol:latest
        name: codesyscontrol
        securityContext:
          privileged: true         
        ports:
        - containerPort: 4840
          name: upcua
          protocol: TCP
          hostPort: 4840
        - containerPort: 11740
          name: runtimetcp
          protocol: TCP
          hostPort: 11740
        - containerPort: 1740
          name: runtimeudp
          protocol: UDP
          hostPort: 1740
        volumeMounts:
        - name: codesyscontrol-persistent-storage
          mountPath: /var/opt/codesys
      volumes:
      - name: codesyscontrol-persistent-storage
        persistentVolumeClaim:
          claimName: codesyscontrol-pv-claim
EOF

cat > service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: codesyscontrol
  labels:
    service.kubernetes.io/service-proxy-name: multus-proxy
    app: codesyscontrol
  annotations:
    k8s.v1.cni.cncf.io/service-network: codesys
spec:
  ports:
    - port: 4840
      name: upcua
      protocol: TCP
    - port: 11740
      name: runtimetcp
      protocol: TCP
    - port: 1740
      name: runtimeudp
      protocol: UDP
  selector:
    app: codesyscontrol
EOF

cat > pvc.yaml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: codesyscontrol-pv-claim
  labels:
    app: codesyscontrol
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

cat > kustomization.yaml <<EOF
resources:
- pvc.yaml
- deployment.yaml
- service.yaml
EOF
```

### CodeSys Runtime + Application
```
### 从 podman 容器拷贝应用程序到本地
cd codesyscontrol
podman cp codesyscontrol:/PlcLogic .

mv Dockerfile Dockerfile.bak

### Dockerfile - 拷贝带 Application 内容的 PlcLogic 目录到 Runtime Container 内
cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
RUN dnf install -y libpciaccess && dnf clean all 
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
RUN rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY PlcLogic/ /PlcLogic/
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 1740/udp

ENTRYPOINT ["/opt/codesys/bin/codesyscontrol.bin"]
CMD ["/etc/CODESYSControl.cfg"]
EOF

podman build -f Dockerfile  -t registry.example.com:5000/codesys/codesyscontroldemoapp:v1
podman push registry.example.com:5000/codesys/codesyscontroldemoapp:v1 
podman run --name codesyscontroldemoapp -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v1 

```

### 创建 Docker Build 的 BuildConfig
```
### codesyscontrol image
### 在 gitea 上创建 codesyscontrolwithapp-image git repo
### clone codesyscontrolwithapp-image git repo
$ git clone https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/codesyscontrolwithapp-image.git
$ cd codesyscontrolwithapp-image
$ ls -al 
drwxr-xr-x. 4 root root  36 Jan 30 09:55 .
drwxr-xr-x. 7 root root  95 Jan 30 09:54 ..
drwxr-xr-x. 7 root root 119 Jan 30 09:55 .git 

### 创建 dockerfile 目录
$ mkdir -p dockerfile
$ cd dockerfile

### 准备 Artifacts - Dockerfile
$ cat > Dockerfile <<EOF
FROM registry.example.com:5000/codesys/codesyscontrol:latest
COPY PlcLogic/ /PlcLogic/
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 1740/udp

ENTRYPOINT ["/opt/codesys/bin/codesyscontrol.bin"]
CMD ["/etc/CODESYSControl.cfg"]
EOF

### 拷贝 Artifacts - PlcLogic 目录
$ ls -al 
total 4
drwxr-xr-x. 3 root root  40 Jan 30 10:21 .
drwxr-xr-x. 4 root root  36 Jan 30 10:17 ..
-rw-r--r--. 1 root root 220 Jan 30 10:20 Dockerfile
drwxr-xr-x. 8 root root  98 Jan 30 10:21 PlcLogic

### 回到 codesyscontrol 目录
$ cd ../codesyscontrol

### 创建 Buildconfig
$ cat > buildconfig.yaml <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: codesyscontrolwithapp-build
  namespace: codesys
  label:
    app: codesyscontrol
spec:
  source:
    type: Git
    git:
      uri: 'https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/codesyscontrolwithapp-image.git'
      ref: master
    contextDir: dockerfile
  strategy:
    type: Docker
    #With this you can set a path to the docker file
    #dockerStrategy:
    # dockerfilePath: dockerfile
  output:
    to:
      kind: "DockerImage"
      name: "registry.example.com:5000/codesys/codesyscontrolwithapp:latest"
EOF

$ oc apply -f buildconfig.yaml
$ oc get buildconfig
$ oc start-build bc/codesyscontrolwithapp-build

### Build 包含以下报错
$ oc get build codesyscontrolwithapp-build-3 -o yaml
...
  logSnippet: |-
    Cloning "https://gitea-with-admin-openshift-operators.apps...example.com/lab-user-2/codesyscontrolwithapp-image.git" ...
    error: fatal: unable to access 'https://gitea-with-admin-o...icate problem: self signed certificate in certificate chain
  message: Failed to fetch the input source.


```