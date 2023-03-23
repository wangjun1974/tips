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

### CODESYS Missing Library 下载
```
# Device -> PLCLogic -> Application 
# 双击 "Library Manager"
# Download Missing Librarys
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
RUN dnf install -y libpciaccess iproute net-tools && dnf clean all 
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
RUN dnf install -y iproute net-tools && dnf clean all 
COPY codesysedge-4.1.0.0-2.x86_64.rpm /tmp/codesysedge-4.1.0.0-2.x86_64.rpm
RUN rpm -ivh /tmp/codesysedge-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesysedge-4.1.0.0-2.x86_64.rpm
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
firewall-cmd --add-port=11741/tcp --zone=public --permanent
firewall-cmd --add-port=1741/udp --zone=public --permanent
firewall-cmd --add-port=4841/tcp --zone=public --permanent
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
### 参考 将 gitea 的证书添加到 additionalTrustBundle 中 
$ openssl s_client -host gitea-with-admin-openshift-operators.apps.ocp4-1.example.com -port 443 -showcerts > trace < /dev/null
$ cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /etc/pki/ca-trust/source/anchors/gitea.crt 
$ cat /etc/pki/ca-trust/source/anchors/registry.crt /etc/pki/ca-trust/source/anchors/gitea.crt > /etc/pki/ca-trust/source/anchors/ca.crt
$ oc create configmap custom-ca \
     --from-file=ca-bundle.crt=/etc/pki/ca-trust/source/anchors/ca.crt \
     -n openshift-config
$ oc patch proxy.config.openshift.io/cluster -p '{"spec":{"trustedCA":{"name":"custom-ca"}}}'  --type=merge

### CodeMeter
### 下载 CodeMeter https://www.wibu.com/support/user/user-software/file/download/9794.html 
$ mkdir codemeter
$ cp ../CodeMeter-lite-7.51.5429-500.x86_64.rpm . 
$ cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY CodeMeter-lite-7.51.5429-500.x86_64.rpm /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm
RUN dnf install -y /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm && rm -f /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm
EXPOSE 22350/tcp

ENTRYPOINT ["/usr/sbin/CodeMeterLin"]
CMD ["-f"]
EOF

$ podman build -f Dockerfile  -t registry.example.com:5000/codesys/codemeter-lite:v7.51
$ podman run --name codemeter-lite -d -t --network host --privileged registry.example.com:5000/codesys/codemeter-lite:v7.51
$ podman push registry.example.com:5000/codesys/codemeter-lite:v7.51


### CodeSys Control 报错
...
**** ERROR: CodeMCreateInitialSoftcontainer: ERROR: $Firmware$/.SoftContainer_CmRuntime.wbb file missing

### 再次迭代 CodesysControl 
$ cp ../CodeMeter-lite-7.51.5429-500.x86_64.rpm . 
$ cat > bootstrap.sh <<EOF
#!/bin/bash

# Start the first process
/usr/sbin/CodeMeterLin -f &   

# Start the second process
/opt/codesys/bin/codesyscontrol.bin /etc/CODESYSControl.cfg &
  
# Wait for any process to exit
wait -n
  
# Exit with status of process that exited first
exit $?
EOF

$ cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY CodeMeter-lite-7.51.5429-500.x86_64.rpm /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm
COPY bootstrap.sh /
RUN dnf install -y libpciaccess iproute net-tools /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm && dnf clean all && rm -f /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm && rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY PlcLogic/ /PlcLogic/
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/bin/bash"]
CMD ["/bootstrap.sh"]
EOF

$ podman build -f Dockerfile  -t registry.example.com:5000/codesys/codesyscontroldemoapp
$ podman run --name codesyscontroldemoapp -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp 

$ mkdir -p Application
$ podman cp codesyscontroldemoapp:/PlcLogic/Application/Application.app Application
$ podman cp codesyscontroldemoapp:/PlcLogic/Application/Application.crc Application
$ cat > Dockerfile.app <<EOF
FROM registry.example.com:5000/codesys/codesyscontroldemoapp:v2
COPY Application/* /PlcLogic/Application/
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/bin/bash"]
CMD ["/bootstrap.sh"]
EOF

$ podman build -f Dockerfile.app  -t registry.example.com:5000/codesys/codesyscontroldemoapp:v3
$ podman run --name codesyscontroldemoapp-v3 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v3 

$ cat Dockerfile.app-v4
FROM registry.example.com:5000/codesys/codesyscontroldemoapp:v3
RUN rm -f /PlcLogic/Application/Application.app && rm -f /PlcLogic/Application/Application.crc
COPY Test/Application.app /PlcLogic/Application/
COPY Test/Application.crc /PlcLogic/Application/
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/bin/bash"]
CMD ["/bootstrap.sh"]

$ podman build -f Dockerfile.app-v4  -t registry.example.com:5000/codesys/codesyscontroldemoapp:v4
$ podman stop codesyscontroldemoapp-v3
$ podman run --name codesyscontroldemoapp-v4 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v4


$ cat > Dockerfile.app-v5 <<EOF
FROM registry.example.com:5000/codesys/codesyscontroldemoapp:v3
RUN rm -f /PlcLogic/Application/Application.app && rm -f /PlcLogic/Application/Application.crc
COPY Demo2/Application.app /PlcLogic/Application/
COPY Demo2/Application.crc /PlcLogic/Application/
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/bin/bash"]
CMD ["/bootstrap.sh"]
EOF

$ podman build -f Dockerfile.app-v5  -t registry.example.com:5000/codesys/codesyscontroldemoapp:v5
$ podman stop codesyscontroldemoapp-v4
$ podman run --name codesyscontroldemoapp-v5 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v5

$ cat > CODESYSControl_User.cfg <<EOF
;linux
[ComponentManager]
;Component.1=CmpGateway                 ; enable when using Gateway
;Component.2=CmpGwCommDrvTcp    ; enable when using Gateway
;Component.3=CmpGwCommDrvShm    ; enable when using Gateway
;Component.1=SysPci                             ; enable when using Hilscher CIFX
;Component.2=CmpHilscherCIFX    ; enable when using Hilscher CIFX

[CmpApp]
Bootproject.RetainMismatch.Init=1
;RetainType.Applications=InSRAM
Application.1=Application

[CmpRedundancyConnectionIP]

[CmpRedundancy]

[CmpSrv]

[IoDrvEtherCAT]

[CmpUserMgr]
AsymmetricAuthKey=61ba1b30a4686f09483c0d87ba2adabe13ffeec0
SECURITY.UserMgmtEnforce=NO

[CmpSecureChannel]
CertificateHash=367fa4f5ec80190fa323db7996d4203dc39c85cb
EOF

$ cat > Dockerfile.app-v6 <<EOF
FROM registry.example.com:5000/codesys/codesyscontroldemoapp:v3
RUN rm -f /PlcLogic/Application/Application.app && rm -f /PlcLogic/Application/Application.crc
COPY Demo2/Application.app /PlcLogic/Application/
COPY Demo2/Application.crc /PlcLogic/Application/
COPY CODESYSControl_User.cfg /etc
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/bin/bash"]
CMD ["/bootstrap.sh"]
EOF

$ podman build -f Dockerfile.app-v6  -t registry.example.com:5000/codesys/codesyscontroldemoapp:v6
$ podman stop codesyscontroldemoapp-v5
$ podman run --name codesyscontroldemoapp-v6 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v6


$ cat > Dockerfile.app-v7 <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY CodeMeter-lite-7.51.5429-500.x86_64.rpm /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm
COPY bootstrap.sh /
RUN dnf install -y libpciaccess iproute net-tools /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm && dnf clean all && rm -f /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm && rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY Test/Application.app /PlcLogic/Application/
COPY Test/Application.crc /PlcLogic/Application/
COPY CODESYSControl_User.cfg /etc
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/bin/bash"]
CMD ["/bootstrap.sh"]
EOF

$ podman build -f Dockerfile.app-v7  -t registry.example.com:5000/codesys/codesyscontroldemoapp:v7
$ podman stop codesyscontroldemoapp-v5
$ podman run --name codesyscontroldemoapp-v7 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v7

### 演示1
1. 在环境里启动 gateway 容器和 runtime 容器
$ podman run --name codesysedge -d -t --network host --privileged registry.example.com:5000/codesys/codesysedge
$ podman run --name codesyscontrol -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontrol 

2. 查看 gateway 容器，查看 runtime 容器


### 
$ cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY CodeMeter-lite-7.51.5429-500.x86_64.rpm /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm
COPY bootstrap.sh /
RUN dnf install -y libpciaccess iproute net-tools /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm && dnf clean all && rm -f /tmp/CodeMeter-lite-7.51.5429-500.x86_64.rpm && rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY Demo2/Application.app /PlcLogic/Application/
COPY Demo2/Application.crc /PlcLogic/Application/
COPY CODESYSControl_User.cfg /etc
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/bin/bash"]
CMD ["/bootstrap.sh"]
EOF

$ podman build -f Dockerfile  -t registry.example.com:5000/codesys/codesyscontroldemoapp:latest
$ podman stop codesyscontrol
$ podman run --name codesyscontroldemoapp -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:latest
```


### codesys git repo 记录
```
[root@support codesys]# git remote -v 
origin  https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/codesys.git (fetch)
origin  https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/codesys.git (push)

[root@support codesys]# tree . 
.
└── apps
    ├── base
    │   ├── kustomization.yaml
    │   ├── net-attach-def.yaml
    │   └── rolebinding.yaml
    ├── codesyscontrol
    │   ├── deployment.yaml
    │   ├── kustomization.yaml
    │   ├── pvc.yaml
    │   └── service.yaml
    ├── codesysedge
    │   ├── deployment.yaml
    │   ├── kustomization.yaml
    │   └── service.yaml
    └── kustomization.yaml

4 directories, 11 files

$ cat apps/kustomization.yaml 
bases:
  - base
  - codesysedge
  - codesyscontrol


### apps/base 目录内容
$ cat apps/base/kustomization.yaml 
resources:
- rolebinding.yaml
- net-attach-def.yaml

$ cat apps/base/rolebinding.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: system:openshift:scc:privileged
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:openshift:scc:privileged
subjects:
- kind: ServiceAccount
  name: default
  namespace: codesysdemo

$ cat apps/base/net-attach-def.yaml 
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys
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

### apps/codesysedge 目录内容
$ cat apps/codesysedge/kustomization.yaml 
resources:
- deployment.yaml
- service.yaml

$ cat apps/codesysedge/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesysedge
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

$ cat apps/codesysedge/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: codesysedge
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

### apps/codesyscontrol 目录内容
$ cat apps/codesyscontrol/kustomization.yaml 
resources:
- pvc.yaml
- deployment.yaml
- service.yaml

$ cat apps/codesyscontrol/pvc.yaml 
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
      storage: 1Gi

$ cat apps/codesyscontrol/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesyscontrol
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
      - image: registry.example.com:5000/codesys/codesyscontroldemoapp:latest
        #image: registry.example.com:5000/codesys/codesyscontrol:latest
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

$ cat  apps/codesyscontrol/service.yaml 
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


### 定义多个 multus 接口
### net1 是 management，配置 ip 
### net2 是 ethercat，不配置 ip
$ cat base/kustomization.yaml 
resources:
- net-attach-def-net1.yaml
- net-attach-def-net2.yaml

$ cat base/net-attach-def-net1.yaml 
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-management
  namespace: codesys
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens10",
      "mode": "bridge",
      "ipam": {
            "type": "whereabouts",
            "range": "192.168.122.144/29"
      }
  }'
# 6 个 ip 地址
# https://www.adminsub.net/ipv4-subnet-calculator/192.168.122.144/29
# Network 192.168.122.144/29
# Broadcast: 192.168.122.151
# FirstIP: 192.168.122.145
# LastIP: 192.168.122.150
# https://www.adminsub.net/ipv4-subnet-calculator/192.168.122.144/28
# Network 192.168.122.144/28
# Broadcast: 192.168.122.159
# FirstIP: 192.168.122.145
# LastIP: 192.168.122.158
$ cat base/net-attach-def-net2.yaml 
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-ethercat
  namespace: codesys
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens11",
      "mode": "bridge"
  }'

$ cat codesysedge/kustomization.yaml 
resources:
- deployment.yaml
- service.yaml

$ cat codesysedge/deployment.yaml 
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
        k8s.v1.cni.cncf.io/networks: codesys-management
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

$ cat codesysedge/service.yaml 
apiVersion: v1
kind: Service
metadata:
  name: codesysedge
  namespace: codesys
  labels:
    service.kubernetes.io/service-proxy-name: multus-proxy
    app: codesysedge
  annotations:
    k8s.v1.cni.cncf.io/service-network: codesys-management
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

### 启动两个 codesyscontrol 实例
$ cat codesyscontrol/kustomization.yaml 
resources:
- pvc1.yaml
- deployment1.yaml
- service1.yaml
- pvc2.yaml
- deployment2.yaml
- service2.yaml

$ cat codesyscontrol/pvc1.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: codesyscontrol-pv-claim-1
  labels:
    app: codesyscontrol1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

$ cat codesyscontrol/deployment1.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesyscontrol1
  labels:
    app: codesyscontrol1
spec:
  selector:
    matchLabels:
      app: codesyscontrol1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: codesyscontrol1
      annotations:
        k8s.v1.cni.cncf.io/networks: codesys-management, codesys-ethercat
    spec:
      containers:
      - image: registry.example.com:5000/codesys/codesyscontroldemoapp:latest
        #image: registry.example.com:5000/codesys/codesyscontrol:latest
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
          claimName: codesyscontrol-pv-claim-1

$ cat codesyscontrol/service1.yaml 
apiVersion: v1
kind: Service
metadata:
  name: codesyscontrol1
  labels:
    service.kubernetes.io/service-proxy-name: multus-proxy
    app: codesyscontrol1
  annotations:
    k8s.v1.cni.cncf.io/service-network: codesys-management
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
    app: codesyscontrol1

$ cat codesyscontrol/pvc2.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: codesyscontrol-pv-claim-2
  labels:
    app: codesyscontrol2
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

$ cat codesyscontrol/deployment2.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesyscontrol2
  labels:
    app: codesyscontrol2
spec:
  selector:
    matchLabels:
      app: codesyscontrol2
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: codesyscontrol2
      annotations:
        k8s.v1.cni.cncf.io/networks: codesys-management, codesys-ethercat
    spec:
      containers:
      - image: registry.example.com:5000/codesys/codesyscontroldemoapp:latest
        #image: registry.example.com:5000/codesys/codesyscontrol:latest
        name: codesyscontrol
        securityContext:
          privileged: true         
        ports:
        - containerPort: 11741
          name: runtimetcp
          protocol: TCP
          hostPort: 11741
        - containerPort: 1741
          name: runtimeudp
          protocol: UDP
          hostPort: 1741
        volumeMounts:
        - name: codesyscontrol-persistent-storage
          mountPath: /var/opt/codesys
      volumes:
      - name: codesyscontrol-persistent-storage
        persistentVolumeClaim:
          claimName: codesyscontrol-pv-claim-2

$ cat codesyscontrol/service2.yaml 
apiVersion: v1
kind: Service
metadata:
  name: codesyscontrol2
  labels:
    service.kubernetes.io/service-proxy-name: multus-proxy
    app: codesyscontrol2
  annotations:
    k8s.v1.cni.cncf.io/service-network: codesys-management
spec:
  ports:
    - port: 11741
      name: runtimetcp
      protocol: TCP
    - port: 1741
      name: runtimeudp
      protocol: UDP
  selector:
    app: codesyscontrol2


### 生成 CodeMeter 配置文件
### Server.ini
cat > Server.ini <<EOF
[Backup]
Interval=24
Path=/var/lib/CodeMeter/Backup
UpdateCertifiedTime=0

[General]
ActionTimeIntervall=10
ApiCommunicationMode=1
BindAddress=0.0.0.0
CleanUpTimeOut=120
CmInstanceUid=2137353165
CmWANPort=22351
EnabledContainerTypes=4294967295
ExePath=/usr/sbin
HelpFile=/usr/share/doc/CodeMeter
IsCmWANServer=1
IsNetworkServer=0
LogCleanupTimeout=336
LogCmActDiag=1
LogLicenseTracking=0
LogLicenseTrackingPath=/var/log/CodeMeter
Logging=1
LogPath=/var/log/CodeMeter
MaxMessageLen=67108864
NetworkAccessFsb=0
NetworkPort=22350
NetworkTimeout=40
ProxyPort=0
ProxyServer=
ProxyUser=
UseSystemProxy=1
StartDaemon=1
TimeServerTimeout=20
TimeServerURL1=cmtime.codemeter.com
TimeServerURL2=cmtime.codemeter.us
TimeServerURL3=cmtime.codemeter.de
UDPCachingTime=20
UDPWaitingTime=1000
DiagnoseLevel=0
ApiCommunicationModeServer=1
HostNameResolveTimeout=10

[BorrowClient]

[BorrowServer]

[BorrowManage]

[CmAct\ErrorLogger]

[CmAct\PSNs]

[HTTP]
DigestAuthentication=0
RemoteRead=0
Port=22352
ReadAuthenticationEnabled=0
ReadPassword=
WritePassword=
PreparedBorrowingConfiguration=0

[TripleModeRedundancy]
TmrEnabled=0

[HTTPS]
Port=22353
Enabled=0
CertificateChainFile=
PrivateKeyFile=
EOF

$ cat > Dockerfile.app-deb <<EOF
FROM ubuntu:focal-20230126
ENV DEBIAN_FRONTEND=noninteractive
COPY codesyscontrol_linux_4.1.0.0_amd64.deb /tmp/codesyscontrol_linux_4.1.0.0_amd64.deb
COPY codemeter-lite_7.20.4402.501_amd64.deb /tmp/codemeter-lite_7.20.4402.501_amd64.deb
COPY bootstrap.sh /
RUN apt update && apt install -y libpciaccess0 iproute2 bash-completion vim && apt install -y /tmp/codemeter-lite_7.20.4402.501_amd64.deb && rm -f /tmp/codemeter-lite_7.20.4402.501_amd64.deb && apt install -y /tmp/codesyscontrol_linux_4.1.0.0_amd64.deb && rm -f /tmp/codesyscontrol_linux_4.1.0.0_amd64.deb && rm -rf /var/lib/apt/lists/*
COPY Demo2/Application.app /PlcLogic/Application/
COPY Demo2/Application.crc /PlcLogic/Application/
COPY CODESYSControl_User.cfg /etc
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/bin/bash"]
CMD ["/bootstrap.sh"]
EOF

$ podman build -f Dockerfile.app-deb -t registry.example.com:5000/codesys/codesyscontrol-ubuntu-demoapp:latest
$ podman stop codesyscontrol
$ podman run --name codesyscontrol-ubuntu-demoapp -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontrol-ubuntu-demoapp:latest

$ cat > Dockerfile.app-v9 <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
RUN dnf install -y libpciaccess iproute net-tools procps-ng && dnf clean all && rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY Test/Application.app /PlcLogic/Application/
COPY Test/Application.crc /PlcLogic/Application/
COPY CODESYSControl_User.cfg /etc
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/opt/codesys/bin/codesyscontrol.bin"]
CMD ["/etc/CODESYSControl.cfg"]
EOF

$ podman build -f Dockerfile.app-v9 -t registry.example.com:5000/codesys/codesyscontroldemoapp:v9
$ podman stop codesyscontroldemoapp-v8
$ podman run --name codesyscontroldemoapp-v9 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v9
```

### GitOps - codesys
```
$ git remote -v
origin  https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/codesys.git (fetch)
origin  https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/codesys.git (push)

[root@support codesys]# tree -L 3 .
.
└── apps
    ├── base
    │   ├── kustomization.yaml
    │   ├── net-attach-def-net1.yaml
    │   ├── net-attach-def-net2.yaml
    │   └── rolebinding.yaml
    ├── codesyscontrol
    │   ├── deployment1.yaml
    │   ├── deployment2.yaml
    │   ├── kustomization.yaml
    │   ├── pvc1.yaml
    │   ├── pvc2.yaml
    │   ├── service1.yaml
    │   └── service2.yaml
    ├── codesysedge
    │   ├── deployment.yaml
    │   ├── kustomization.yaml
    │   └── service.yaml
    └── kustomization.yaml

4 directories, 15 files

$ cat apps/kustomization.yaml 
bases:
  - base
  - codesysedge
  - codesyscontrol

$ cat apps/base/kustomization.yaml 
resources:
- rolebinding.yaml
- net-attach-def-net1.yaml
- net-attach-def-net2.yaml

$ cat apps/codesysedge/kustomization.yaml 
resources:
- deployment.yaml
- service.yaml

$ cat apps/codesyscontrol/kustomization.yaml 
resources:
- pvc1.yaml
- deployment1.yaml
- service1.yaml
- pvc2.yaml
- deployment2.yaml
- service2.yaml

### apps/base
$ cat apps/base/rolebinding.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: system:openshift:scc:privileged
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:openshift:scc:privileged
subjects:
- kind: ServiceAccount
  name: default
  namespace: codesysdemo

$ cat apps/base/net-attach-def-net1.yaml 
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-management
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens10",
      "mode": "bridge",
      "ipam": {
            "type": "whereabouts",
            "range": "192.168.122.144/29"
      }
  }'

$ cat apps/base/net-attach-def-net2.yaml 
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-ethercat
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens11",
      "mode": "bridge"
  }'

### apps/codesysedge
cat apps/codesysedge/deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesysedge
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
        k8s.v1.cni.cncf.io/networks: codesys-management
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

$ cat apps/codesysedge/service.yaml 
apiVersion: v1
kind: Service
metadata:
  name: codesysedge
  labels:
    service.kubernetes.io/service-proxy-name: multus-proxy
    app: codesysedge
  annotations:
    k8s.v1.cni.cncf.io/service-network: codesys-management
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

### apps/codesyscontrol
$ cat apps/codesyscontrol/pvc1.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: codesyscontrol-pv-claim-1
  labels:
    app: codesyscontrol1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

$ cat apps/codesyscontrol/deployment1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesyscontrol1
  labels:
    app: codesyscontrol1
spec:
  selector:
    matchLabels:
      app: codesyscontrol1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: codesyscontrol1
      annotations:
        k8s.v1.cni.cncf.io/networks: codesys-management, codesys-ethercat
    spec:
      containers:
      - image: registry.example.com:5000/codesys/codesyscontroldemoapp:latest
        #image: registry.example.com:5000/codesys/codesyscontrol:latest
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
          claimName: codesyscontrol-pv-claim-1

$ cat apps/codesyscontrol/service1.yaml 
apiVersion: v1
kind: Service
metadata:
  name: codesyscontrol1
  labels:
    service.kubernetes.io/service-proxy-name: multus-proxy
    app: codesyscontrol1
  annotations:
    k8s.v1.cni.cncf.io/service-network: codesys-management
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
    app: codesyscontrol1

$ cat apps/codesyscontrol/pvc2.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: codesyscontrol-pv-claim-2
  labels:
    app: codesyscontrol2
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

$ cat apps/codesyscontrol/deployment2.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesyscontrol2
  labels:
    app: codesyscontrol2
spec:
  selector:
    matchLabels:
      app: codesyscontrol2
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: codesyscontrol2
      annotations:
        k8s.v1.cni.cncf.io/networks: codesys-management, codesys-ethercat          
    spec:
      containers:
      - image: registry.example.com:5000/codesys/codesyscontroldemoapp:latest
        #image: registry.example.com:5000/codesys/codesyscontrol:latest
        name: codesyscontrol
        securityContext:
          privileged: true         
        ports:
        - containerPort: 4841
          name: upcua
          protocol: TCP
          hostPort: 4841
        - containerPort: 11741
          name: runtimetcp
          protocol: TCP
          hostPort: 11741
        - containerPort: 1741
          name: runtimeudp
          protocol: UDP
          hostPort: 1741
        volumeMounts:
        - name: codesyscontrol-persistent-storage
          mountPath: /var/opt/codesys
      volumes:
      - name: codesyscontrol-persistent-storage
        persistentVolumeClaim:
          claimName: codesyscontrol-pv-claim-2

$ cat apps/codesyscontrol/service2.yaml 
apiVersion: v1
kind: Service
metadata:
  name: codesyscontrol2
  labels:
    service.kubernetes.io/service-proxy-name: multus-proxy
    app: codesyscontrol2
  annotations:
    k8s.v1.cni.cncf.io/service-network: codesys-management
spec:
  ports:
    - port: 4841
      name: upcua
      protocol: TCP
    - port: 11741
      name: runtimetcp
      protocol: TCP
    - port: 1741
      name: runtimeudp
      protocol: UDP
  selector:
    app: codesyscontrol2

```

### 清理 whereabouts 遗留资源 
https://access.redhat.com/solutions/5841121<br>
```

# 在创建 pods 时遇到报错
# 10m         Warning   FailedCreatePodSandBox   pod/codesysedge-65fd7b9558-z7g24                  Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create pod network sandbox k8s_codesysedge-65fd7b9558-z7g24_codesysdemo_033a21ed-e98b-4386-b44f-bf81acf7e3d0_0(53563970bd1a6fe2aa647664adf6dd54c1d2fecd72e32c1784785cd6f8c6c9f4): error adding pod codesysdemo_codesysedge-65fd7b9558-z7g24 to CNI network "multus-cni-network": plugin type="multus" name="multus-cni-network" failed (add): [codesysdemo/codesysedge-65fd7b9558-z7g24/033a21ed-e98b-4386-b44f-bf81acf7e3d0:codesys-management]: error adding container to network "codesys-management": Error at storage engine: Could not allocate IP in range: ip: 192.168.122.145 / - 192.168.122.150 / range: net.IPNet{IP:net.IP {0xc0, 0xa8, 0x7a, 0x90}, Mask:net.IPMask{0xff, 0xff, 0xff, 0xf8}}

[root@support ~]# oc get pods -A | grep where
[root@support ~]# oc get ippools.whereabouts.cni.cncf.io -A
NAMESPACE          NAME                 AGE
openshift-multus   192.168.122.140-30   22d
openshift-multus   192.168.122.144-29   7d22h
[root@support ~]# oc get overlappingrangeipreservations.whereabouts.cni.cncf.io -A
NAMESPACE          NAME              AGE
openshift-multus   192.168.122.145   26h
openshift-multus   192.168.122.146   26h
openshift-multus   192.168.122.147   26h
openshift-multus   192.168.122.148   23h
openshift-multus   192.168.122.149   22h
openshift-multus   192.168.122.150   22h

### 清理 ippools.whereabouts.cni.cncf.io
$ oc delete ippools.whereabouts.cni.cncf.io 192.168.122.140-30 -n openshift-multus
$ oc delete ippools.whereabouts.cni.cncf.io 192.168.122.144-29 -n openshift-multus
$ oc delete ippools.whereabouts.cni.cncf.io 192.168.122.144-28 -n openshift-multus

### 清理 overlappingrangeipreservations.whereabouts.cni.cncf.io 
$ for i in $(seq 145 158) ; do oc delete overlappingrangeipreservations.whereabouts.cni.cncf.io 192.168.122.${i} -n openshift-multus ; done


### 启动多具有多网络的 podman container
# 用参数 --network=host 启动容器，这个时候容器内能看到所有的主机上的网卡
[root@eci0 ~]# podman exec -it codesyscontroldemoapp-v5 /bin/bash
[root@eci0 /]# ip a s 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:26:27:3f brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.131/24 brd 192.168.122.255 scope global noprefixroute enp1s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe26:273f/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
3: enp2s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:ec:f8:13 brd ff:ff:ff:ff:ff:ff

### 基于 docker-compose 运行 codesys
### 安装 podman-docker，下载 docker-compose
### 参考链接: https://bytexd.com/how-to-install-docker-compose-on-rhel-8-almalinux-rocky-linux/
### 参考链接: https://www.redhat.com/sysadmin/podman-docker-compose
$ yum install -y podman-docker
$ curl -L https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose

# 启动 podman.socket endpoint
$ systemctl start podman.socket
# 检查 socket endpoint Restful API 工作正常
$ curl -H "Content-Type: application/json" --unix-socket /var/run/docker.sock http://localhost/_ping

### run docker compose version of codesys runtime and codesys gateway 
$ cat > compose.yaml <<EOF
version: '2'
services:
  codesysedge:
    image: registry.example.com:5000/codesys/codesysedge:latest
    network_mode: "host"
    restart: always
    ports:
      - "1217:1217/tcp"
      - "1743:1743/udp" 
  codesyscontrol1withdemoapp:
    image: registry.example.com:5000/codesys/codesyscontroldemoapp:v6
    network_mode: "host"
    restart: always
    ports:
      - "4840:4840/tcp"
      - "11740:11740/tcp"
      - "1740:1740/udp"
  codesyscontrol2withdemoapp:
    image: registry.example.com:5000/codesys/codesyscontroldemoapp:v6
    network_mode: "host"
    restart: always
    ports:
      - "4841:4841/tcp"
      - "11741:11741/tcp"
      - "1741:1741/udp"
EOF
```

### 安装 Depictor 
```
### CodeSys Installer -> Installations -> Change
### Browse - Search 输入 'Depictor'
### 选中 CodeSys Depictor，双击
### Install
```

### taskset 设置 cpu 绑定
```
sh-4.4# ps axf
...
2548207 ?        Ssl    0:00 /usr/bin/conmon -b /run/containers/storage/overlay-containers/162d7a88757cb6fd4b42baa5ac7994c0d43d184d316af8a281458114753d17f8/us
2548218 ?        Ssl    0:26  \_ /opt/codesys/bin/codesyscontrol.bin /etc/CODESYSControl.cfg

sh-4.4# taskset -cp 3 2548218

### 用 taskset 设置 cpu 绑定的原因是 
### 如果设置了 codesys runtime 的 container resource memory requests/limits 
### 将会触发 OOM 
### https://komodor.com/learn/how-to-fix-oomkilled-exit-code-137/#:~:text=What%20is%20OOMKilled%20(exit%20code,utilize%20on%20the%20host%20machine
### 
    spec:
      nodeSelector:
        node-role.kubernetes.io/worker-rt: ''
      containers:
      - image: registry.ocp4.example.com:5000/codesys/codesyscontroldemoapp:v8
        name: codesyscontrol
        runtimeClassName: performance-rt
        resources:
          limits:
            # memory: "2Gi"
            cpu: "1"
          requests:
            # memory: "2Gi"
            cpu: "1"
```


### 尝试将 runtime 的内存锁定
```
$ cat > CODESYSControl.cfg <<EOF
;linux
[SysFile]
FilePath.1=/etc/, 3S.dat
PlcLogicPrefix=1

[SysTarget]
TargetVersionMask=0
TargetVersionCompatibilityMask=0xFFFF0000

[CmpSocketCanDrv]
ScriptPath=/opt/codesys/scripts/
ScriptName=rts_set_baud.sh

[CmpSettings]
IsWriteProtected=1
FileReference.0=SysFileMap.cfg, SysFileMap
FileReference.1=/etc/CODESYSControl_User.cfg

[SysExcept]
Linux.DisableFpuOverflowException=1
Linux.DisableFpuUnderflowException=1
Linux.DisableFpuInvalidOperationException=1

[CmpOpenSSL] 
WebServer.Cert=server.cer 
WebServer.PrivateKey=server.key 
WebServer.CipherList=HIGH

[CmpLog]
Logger.0.Name=/tmp/codesyscontrol.log
Logger.0.Filter=0x0000000F
Logger.0.Enable=1
Logger.0.MaxEntries=1000
Logger.0.MaxFileSize=1000000
Logger.0.MaxFiles=1
Logger.0.Backend.0.ClassId=0x00000104 ;writes logger messages in a file
Logger.0.Type=0x314 ;Set the timestamp to RTC

[SysMem]
Linux.Memlock=1

[SysEthernet]
Linux.ProtocolFilter=3 

[CmpSchedule]
SchedulerInterval=4000
ProcessorLoad.Enable=1
ProcessorLoad.Maximum=95
ProcessorLoad.Interval=5000
DisableOmittedCycleWatchdog=1
EOF

$ cat > Dockerfile.app-v10 <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
RUN dnf install -y libpciaccess iproute net-tools procps-ng && dnf clean all && rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY Test/Application.app /PlcLogic/Application/
COPY Test/Application.crc /PlcLogic/Application/
COPY CODESYSControl_User.cfg /etc
COPY CODESYSControl.cfg /etc
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/opt/codesys/bin/codesyscontrol.bin"]
CMD ["/etc/CODESYSControl.cfg"]
EOF

$ podman build -f Dockerfile.app-v10 -t registry.example.com:5000/codesys/codesyscontroldemoapp:v10
$ podman stop codesyscontroldemoapp-v9
$ podman run --name codesyscontroldemoapp-v10 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v10
```

### Performance Profile rt
```
### 创建 PerformanceProfile rt 
### 参考配置
cat <<EOF | oc apply -f -
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
  name: rt
spec:
  additionalKernelArgs:
  - "audit=0"  
  - "idle=poll"
  - "intel_idle.max_cstate=0"
  - "processor.max_cstate=0"
  - "mce=off"
  - "numa=off"
  cpu:
    isolated: '1-3'
    reserved: '0'
  hugepages:
    pages:
      - count: 1024
        node: 0
        size: 2M
    defaultHugepagesSize: 2M
  realTimeKernel:
    enabled: true
  numa:
    topologyPolicy: "best-effort"
  nodeSelector:
    node-role.kubernetes.io/worker-rt: ""
  machineConfigPoolSelector:
    machineconfiguration.openshift.io/role: worker-rt
EOF

### 实际配置
### 去掉 numa=off 和 hugepages
### 全局禁用 globallyDisableIrqLoadBalancing
### https://docs.openshift.com/container-platform/4.9/scalability_and_performance/cnf-performance-addon-operator-for-low-latency-nodes.html#managing-device-interrupt-processing-for-guaranteed-pod-isolated-cpus_cnf-master
cat <<EOF | oc apply -f -
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
  name: rt
spec:
  globallyDisableIrqLoadBalancing: true
  additionalKernelArgs:
  - "audit=0"  
  - "idle=poll"
  - "intel_idle.max_cstate=0"
  - "processor.max_cstate=0"
  - "mce=off"
  - "i915.force_probe=*"
  cpu:
    isolated: '1-3'
    reserved: '0'
  realTimeKernel:
    enabled: true
  numa:
    topologyPolicy: "best-effort"
  nodeSelector:
    node-role.kubernetes.io/worker-rt: ""
  machineConfigPoolSelector:
    machineconfiguration.openshift.io/role: worker-rt
EOF

### 参考KCS设置主机名
### https://access.redhat.com/solutions/5676801
### ssh 到 host
$ hostnamectl set-hostname b2-ocp4test.ocp4.example.com
$ nmcli c mod 'Wired connection 1' ipv4.method 'disabled' 
$ nmcli c mod 'Wired connection 1' ipv6.method 'disabled' 
$ nmcli c mod 'Wired connection 2' ipv4.method 'disabled' 
$ nmcli c mod 'Wired connection 2' ipv6.method 'disabled' 
$ nmcli c down 'Wired connection 1' && nmcli c up 'Wired connection 1'
$ nmcli c down 'Wired connection 2' && nmcli c up 'Wired connection 2'

### 设置所有进程绑定 core 0
ps axf  | grep -Ev "6492" | awk '{print $1}' | while read i ; do taskset -p $i 2>&1 | grep -E "mask: f" | awk '{print $2}'| sed -e "s|'s||" ; done  | while read i ; do taskset -cp 0 $i ;done

### 设置 irq cpu affinity from 0-3 to core 0-2
$ find /proc/irq/ -name smp_affinity_list -exec sh -c 'i="$1"; mask=$(cat $i); file=$(echo $i); echo $file: $mask' _ {} \; | grep "0-3" | awk -F '/' '{print $4}' | while read i ;do echo "07" > /proc/irq/$i/smp_affinity ; done 
```

### 创建 cyclictest 和 stress-ng 的镜像
```
$ cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY numactl-libs-2.0.12-13.el8.x86_64.rpm /tmp/numactl-libs-2.0.12-13.el8.x86_64.rpm
COPY Judy-1.0.5-18.module_el8.5.0+728+80681c81.x86_64.rpm /tmp/Judy-1.0.5-18.module_el8.5.0+728+80681c81.x86_64.rpm
COPY stress-ng-0.13.00-5.el8.x86_64.rpm /tmp/stress-ng-0.13.00-5.el8.x86_64.rpm
COPY rt-tests-2.5-1.el8.x86_64.rpm /tmp/rt-tests-2.5-1.el8.x86_64.rpm
RUN dnf install -y libpciaccess iproute net-tools procps-ng /tmp/rt-tests-2.5-1.el8.x86_64.rpm /tmp/stress-ng-0.13.00-5.el8.x86_64.rpm /tmp/Judy-1.0.5-18.module_el8.5.0+728+80681c81.x86_64.rpm /tmp/numactl-libs-2.0.12-13.el8.x86_64.rpm && dnf clean all

CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF
$ podman build -f Dockerfile  -t registry.example.com:5000/codesys/cyclictest:v1
$ podman run --name cyclictest-v1 -d -t --network host --privileged registry.example.com:5000/codesys/cyclictest:v1

$ cat > pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cyclictest
  namespace: default
  # Disable CPU balance with CRIO (yes this is disabling it)
  annotations:
    cpu-load-balancing.crio.io: "true"
spec:
  # Map to the correct performance class in the cluster (from PAO)
  # runtimeClassName: performance-custom-class
  runtimeClassName: performance-rt
  restartPolicy: Never
  containers:
  - name: cyclictest
    image: registry.ocp4.example.com:5000/codesys/cyclictest:v1
    imagePullPolicy: IfNotPresent
    # Request and Limits must be identical for the Pod to be assigned to the QoS Guarantee
    command: ["/bin/sh", "-ec", "while :; do echo '.'; sleep 5 ; done"]
    resources:
      requests:
        memory: "200Mi"
        cpu: "1"
      limits:
        memory: "200Mi"
        cpu: "1"
    env:
    - name: DURATION
      value: "1m"
    # # Following setting not required in OCP4.6+
    # - name: DISABLE_CPU_BALANCE
    #   value: "y"
    #   # DISABLE_CPU_BALANCE requires privileged=true
    securityContext:
      privileged: true
      #capabilities:
      #  add:
      #    - SYS_NICE
      #    - IPC_LOCK
      #    - SYS_RAWIO
    volumeMounts:
    - mountPath: /dev/cpu_dma_latency
      name: cstate
  volumes:
  - name: cstate
    hostPath:
      path: /dev/cpu_dma_latency
  nodeSelector:
    node-role.kubernetes.io/worker-rt: ""
EOF

$ cat > pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cyclictest
  namespace: default
  # Disable CPU balance with CRIO (yes this is disabling it)
  annotations:
    cpu-load-balancing.crio.io: "true"
spec:
  # Map to the correct performance class in the cluster (from PAO)
  # runtimeClassName: performance-custom-class
  runtimeClassName: performance-rt
  restartPolicy: Never
  containers:
  - name: cyclictest
    image: registry.ocp4.example.com:5000/codesys/cyclictest:v1
    imagePullPolicy: IfNotPresent
    # Request and Limits must be identical for the Pod to be assigned to the QoS Guarantee
    command: ["/usr/bin/cyclictest", "--priority 1 --policy fifo -h 10 -a 1 -t 1 -m -q -i 200 -D 1h"]
    resources:
      requests:
        memory: "200Mi"
        cpu: "1"
      limits:
        memory: "200Mi"
        cpu: "1"
    env:
    - name: DURATION
      value: "1m"
    # # Following setting not required in OCP4.6+
    # - name: DISABLE_CPU_BALANCE
    #   value: "y"
    #   # DISABLE_CPU_BALANCE requires privileged=true
    securityContext:
      privileged: true
      #capabilities:
      #  add:
      #    - SYS_NICE
      #    - IPC_LOCK
      #    - SYS_RAWIO
    volumeMounts:
    - mountPath: /dev/cpu_dma_latency
      name: cstate
  volumes:
  - name: cstate
    hostPath:
      path: /dev/cpu_dma_latency
  nodeSelector:
    node-role.kubernetes.io/worker-rt: ""
EOF

### 在容器里执行压力程序
$ oc -n default rsh cyclictest
sh-4.4# mkdir -p /tmp/stress-ng
sh-4.4# cd /tmp/stress-ng
sh-4.4# /usr/bin/nohup /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0 &
sh-4.4# mkdir -p /tmp/cyclictest
sh-4.4# cd /tmp/cyclictest
sh-4.4# /usr/bin/nohup /usr/bin/cyclictest --priority 1 --policy fifo -h 10 -a 1 -t 1 -m -q -i 200 -D 1h &


### 这些 stress-ng 进程是上面的命令所施加的压力
sh-4.4# ps axf
    PID TTY      STAT   TIME COMMAND
    151 pts/0    Ss     0:00 /bin/sh
   6736 pts/0    SL     0:00  \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6737 pts/0    R      0:39  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6738 pts/0    D      0:39  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6739 pts/0    R      0:39  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6740 pts/0    D      0:39  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6741 pts/0    D      0:39  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6742 pts/0    S      0:00  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6748 pts/0    R      0:39  |   |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6743 pts/0    S      0:00  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6749 pts/0    R      0:39  |   |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6744 pts/0    S      0:00  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
  18614 pts/0    R      0:00  |   |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6745 pts/0    S      0:00  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
  18613 ?        Rs     0:00  |   |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6746 pts/0    S      0:00  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
  18615 pts/0    R      0:00  |   |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
   6747 pts/0    S      0:00  |   \_ /usr/bin/stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
  10855 pts/0    SLl    0:02  \_ /usr/bin/cyclictest --priority 1 --policy fifo -h 10 -a 1 -t 1 -m -q -i 200 -D 1h
  18612 pts/0    R+     0:00  \_ ps axf
      1 ?        Ss     0:00 /bin/sh -ec while :; do echo '.'; sleep 5 ; done
  18576 ?        S      0:00 /usr/bin/coreutils --coreutils-prog-shebang=sleep /usr/bin/sleep 5

### cyclictest 进程绑定的 core 是 1
sh-4.4# taskset -cp 10855 
pid 10855's current affinity list: 1

### core 1 的 cpu 被 stress-ng 压到 idle 为 0 的状态
sh-4.4# top -b 1 
top - 02:36:46 up 6 days, 17:39,  0 users,  load average: 13.91, 10.70, 6.02
Tasks:  23 total,   9 running,  14 sleeping,   0 stopped,   0 zombie
%Cpu0  :  6.2 us,  0.0 sy,  0.0 ni, 93.8 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu1  : 46.7 us, 53.3 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu2  :  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu3  :  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   7447.9 total,   3225.4 free,   1016.2 used,   3206.4 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.   6229.3 avail Mem 
```

### codesys 的脚本功能
https://content.helpme-codesys.com/en/CODESYS%20Scripting/_cds_access_cds_func_in_python_scripts.html
https://help.codesys.com/webapp/_cds_commandline;product=codesys;version=3.5.16.0#option-runscript-execute-script
https://help.codesys.com/webapp/ScriptApplication;product=ScriptEngine;version=3.5.16.0

### CodeSys 如何在命令行编译
```
# script engine
start /b /wait "C:\Program Files (x86)\CODESYS V3.5 SP16\CODESYS\Common\CODESYS.exe" --profile="CODESYS V3.5 SP16" --runscript="build.py" --noUI

# build.py
import scriptengine

project = projects.open(r"CodesysProject.project", primary = True)
application = project.active_application
application.generate_code()
messages = system.get_messages("97f48d64-a2a3-4856-b640-75c046e37ea9")
// check messages


```

### Manage Codesys Projects with Git
https://www.youtube.com/watch?v=MoBZ3g3f7Bo

### event driven ansible demo
https://www.techbeatly.com/introducing-the-event-driven-ansible-demo/
```
$ sudo firewall-cmd --zone=public --add-port=5000/tcp --permanent
$ sudo firewall-cmd --reload
$ cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi9/ubi:latest
ENV JDK_HOME /usr/lib/jvm/java-17-openjdk
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk
RUN dnf --assumeyes install gcc java-17-openjdk maven python3-devel python3-pip && pip3 install -U Jinja2 && pip3 install ansible ansible-rulebook ansible-runner wheel && pip3 install aiokafka && ansible-galaxy collection install community.general ansible.eda 

CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF
$ podman build -f Dockerfile -t registry.example.com:5000/codesys/ansiblerulebook:latest 
$ podman run --name ansiblerulebook -d -t --network host --privileged registry.example.com:5000/codesys/ansiblerulebook:latest

$ cat > Dockerfile.v2 <<EOF
FROM registry.example.com:5000/codesys/ansiblerulebook:v1
RUN dnf --assumeyes install libpciaccess iproute net-tools procps-ng && dnf clean all

CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF

$ podman build -f Dockerfile.v2 -t registry.example.com:5000/codesys/ansiblerulebook:v2
$ podman run --name ansiblerulebook -d -t --network host --privileged registry.example.com:5000/codesys/ansiblerulebook:v2

$ cat > Dockerfile.v3 <<EOF
FROM registry.example.com:5000/codesys/ansiblerulebook:v2
RUN ansible-galaxy collection install community.okd
COPY oc /root
COPY kubeconfig /root

CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF
$ podman build -f Dockerfile.v3 -t registry.example.com:5000/codesys/ansiblerulebook:v3
$ podman run --name ansiblerulebook-v3 -d -t --network host --privileged registry.example.com:5000/codesys/ansiblerulebook:v3

$ podman exec -it ansiblerulebook-v3 bash
# cd /root
# cat > inventory.yml <<EOF
localhost
EOF

# cat > webhook-example.yml <<EOF
---
- name: Listen for events on a webhook
  hosts: all
  ## Define our source for events
  sources:
    - ansible.eda.webhook:
        host: 0.0.0.0
        port: 5000
      filters:
        - ansible.eda.dashes_to_underscores:
  ## Define the conditions we are looking for
  rules:
  ##  - name: Say Hello
  ##    condition: event.payload.message == "Ansible is super cool"
  ## Define the action we should take should the condition be met
  ##    action:
  ##      run_playbook:
  ##        name: say-what.yml
    - name: Update repo
      condition: event.payload is defined
      action:
        debug:
EOF

# cat > say-what.yml <<EOF
---
- name: say thanks
  hosts: localhost
  gather_facts: false
  tasks:
    - debug:
        msg: "Thank you, {{ event.sender | default('my friend') }}!"
EOF

# ansible-rulebook -r webhook-example.yml -i inventory.yml -v

# curl -H 'Content-Type: application/json' -d "{\"message\": \"Ansible is alright\"}" 192.168.122.131:5000/endpoint
# curl -H 'Content-Type: application/json' -d "{\"message\": \"Ansible is super cool\"}" 192.168.122.131:5000/endpoint
```

### real time deployment for codesys runtime 
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: codesyscontrol1
  labels:
    app: codesyscontrol1
spec:
  selector:
    matchLabels:
      app: codesyscontrol1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: codesyscontrol1
      annotations:
        k8s.v1.cni.cncf.io/networks: codesys-management, codesys-ethercat
        cpu-quota.crio.io: "disable"
    spec:
      nodeSelector:
        node-role.kubernetes.io/worker-rt: ''
      containers:
      - image: registry.ocp4.example.com:5000/codesys/codesyscontroldemoapp:v8
        name: codesyscontrol
        runtimeClassName: performance-rt
        resources:
          limits:
            #memory: "1Gi"
            cpu: "1"
          requests:
            #memory: "1Gi"
            cpu: "1"
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
```

### performance team 使用的 pod spec 
https://github.com/redhat-nfvpe/container-perf-tools/blob/master/sample-yamls/pod_cyclictest.yaml<br>
https://docs.openshift.com/container-platform/4.12/scalability_and_performance/cnf-performing-platform-verification-latency-tests.html<br>
```
### 获取 performance team 测试用的镜像
$ mkdir -p /tmp/perf-tools
$ skopeo copy --format v2s2 --all docker://quay.io/jianzzha/perf-tools:latest dir:/tmp/perf-tools/perf-tools

$ tar cf /tmp/perf-tools.tar /tmp/perf-tools

$ scp /tmp/perf-tools.tar <dst>:/tmp

$ tar xf /tmp/perf-tools.tar -C /
$ skopeo copy --format v2s2 --all dir:/tmp/perf-tools/perf-tools docker://registry.ocp4.example.com:5000/jianzzha/perf-tools:latest

### 生成 performance team 测试用的 pod.yaml 
cat > pod.yaml <<EOF
apiVersion: v1 
kind: Pod 
metadata:
  name: cyclictest 
  annotations:
    cpu-load-balancing.crio.io: "disable"
    irq-load-balancing.crio.io: "disable"
    cpu-quota.crio.io: "disable"
spec:
  # Map to the correct performance class in the cluster (from PAO)
  # Identify class names with "oc get runtimeclass"
  runtimeClassName: performance-rt
  restartPolicy: Never 
  containers:
  - name: container-perf-tools 
    image: registry.ocp4.example.com:5000/jianzzha/perf-tools
    imagePullPolicy: IfNotPresent
    # Request and Limits must be identical for the Pod to be assigned to the QoS Guarantee
    resources:
      requests:
        memory: "200Mi"
        cpu: "1"
      limits:
        memory: "200Mi"
        cpu: "1"
    env:
    - name: tool
      value: "cyclictest"
    - name: DURATION
      value: "1h"
    # cyclictest should run with an RT Priority of 95 when testing for RAN DU
    - name: rt_priority
      value: "95"
    - name: INTERVAL
      value: "1000"
    - name: delay
      value: "0"
    # # Following setting not required in OCP4.6+
    # - name: DISABLE_CPU_BALANCE
    #   value: "y"
    #   # DISABLE_CPU_BALANCE requires privileged=true
    securityContext:
      privileged: true
      #capabilities:
      #  add:
      #    - SYS_NICE
      #    - IPC_LOCK
      #    - SYS_RAWIO
    volumeMounts:
    - mountPath: /dev/cpu_dma_latency
      name: cstate
  volumes:
  - name: cstate
    hostPath:
      path: /dev/cpu_dma_latency
  nodeSelector:
    node-role.kubernetes.io/worker-rt: ""
EOF


### 创建可在离线环境里运行的 perf-tools 容器镜像
$ podman run --name cyclictest -d -t --network host --privileged quay.io/jianzzha/perf-tools 
$ mkdir -p /tmp/cyclictest
$ podman cp cyclictest:/root/container-tools . 
$ podman cp cyclictest:/root/run.sh . 
$ podman cp cyclictest:/root/dumb-init . 

### 编辑 run.sh
### 注释或者删除这些行，container-tools 目录内容直接从本地拷贝进去
### [ -n "${GIT_URL}" ] || GIT_URL="https://github.com/redhat-nfvpe/container-perf-tools.git"
### echo "git clone ${GIT_URL}"
### git clone ${GIT_URL} /root/container-tools

### 编辑 container-tools/cyclictest/cmd.sh
### 注释 yum install -y stress-ng 所在的行
###     # yum install -y stress-ng 2>&1 || { echo >&2 "stress-ng required but install failed. Aborting"; sleep infinity; }
### 将 stress-ng 的命令改为 --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
###        tmux new-window -t stress -n $w "taskset -c ${cpus[$(($w-1))]} stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0"

$ cat > Dockerfile <<EOF
FROM quay.io/jianzzha/perf-tools:latest
COPY run.sh /root/run.sh
COPY dumb-init /root/dumb-init
RUN mkdir -p /root/container-tools
COPY container-tools /root/container-tools
ENTRYPOINT ["/root/dumb-init","--"]
CMD ["/root/run.sh"]
EOF
$ podman build -f Dockerfile -t registry.example.com:5000/codesys/perf-tools:latest 
$ podman run --name perf-tools -d -t --network host --privileged registry.example.com:5000/codesys/perf-tools:latest 
$ podman push registry.example.com:5000/codesys/perf-tools:latest

### 查看 cyclictest 的 main thread 和 child thread 的 scheduler policy
sh-4.4# ps axf
 603120 ?        Ssl    0:00 /usr/bin/conmon -b /run/containers/storage/overlay-containers/12258eff63ab396d5c451854f42b1ff400c9ae571a36b884fd3
 603130 ?        Ss     0:00  \_ /root/dumb-init -- /root/run.sh
 603184 ?        Ss     0:00      \_ /root/dumb-init -- /root/container-tools/cyclictest/cmd.sh
 603187 ?        Ss     0:00          \_ /bin/bash /root/container-tools/cyclictest/cmd.sh
 603219 ?        SLl    0:05              \_ cyclictest -q -D 1h -p 95 -t 1 -a -h 30 -i 1000 -m
### 获取进程的线程
sh-4.4# pstree -p -t 603219
cyclictest(603219)---{cyclictest}(603220)
### 查看线程的调度策略和调度优先级
sh-4.4# chrt -p 603220 
pid 603220's current scheduling policy: SCHED_FIFO
pid 603220's current scheduling priority: 95

### 在环境里用 container image 运行一个 gitlab 实例
mkdir -p /root/gitlab/{config,logs,data}
export GITLAB_HOME=/root/gitlab

$ podman run -d -t \
  --hostname eci0.example.com \
  --publish 192.168.122.131:443:443 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab:Z \
  --volume $GITLAB_HOME/logs:/var/log/gitlab:Z \
  --volume $GITLAB_HOME/data:/var/opt/gitlab:Z \
  --shm-size 256m \
  registry.example.com:5000/gitlab/gitlab-ce:latest

# 检查口令
$ podman exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password 

# 启用 local request
https://gitlab.com/gitlab-org/gitlab/-/issues/26845
Admin -> Settings -> Network -> Outbound Requests -> Allow requests to the local network from hooks and services

# cat > .gitconfig <<EOF
[http]
        sslVerify=false
EOF

# oc -n codesysdemo create secret generic mygitconfig --from-file=.gitconfig

# cat <<EOF | oc apply -f - 
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: codesyscontroldemoapp-build
  namespace: codesysdemo
spec:
  source:
    type: Git
    git:
      uri: 'https://eci0.example.com/user1/codesyscontrolwithapp-image.git'
      ref: master
    contextDir: dockerfile
    sourceSecret:
      name: mygitconfig
  strategy:
    type: Docker
    #With this you can set a path to the docker file
    #dockerStrategy:
    # dockerfilePath: dockerfile
  output:
    to:
      kind: "DockerImage"
      name: "registry.example.com:5000/codesys/codesyscontroldemoapp:latest"
EOF

# 配置 gitlab https
# https://docs.gitlab.com/omnibus/settings/ssl/
# Configure HTTPS manually
# gitlab container 内配置证书
mkdir -p /etc/gitlab/ssl
chmod 755 /etc/gitlab/ssl
cd /etc/gitlab/ssl
openssl req -newkey rsa:4096 -nodes -sha256 -keyout eci0.example.com.key -x509 -days 3650 \
  -out eci0.example.com.crt \
  -subj "/C=CN/ST=BEIJING/L=BJ/O=REDHAT/OU=IT/CN=eci0.example.com/emailAddress=admin@example.com"

编辑 /etc/gitlab/gitlab.rb 文件
external_url "https://eci0.example.com"
letsencrypt['enable'] = false

### 在 oc client 添加证书信任
openssl s_client -host eci0.example.com -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /etc/pki/ca-trust/source/anchors/eci0.example.com.crt  
update-ca-trust extract
```