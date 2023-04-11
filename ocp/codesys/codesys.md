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

$ cat > Dockerfile.app-v13 <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
RUN dnf install -y libpciaccess iproute net-tools procps-ng nmap-ncat iputils && dnf clean all && rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
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
$ podman build -f Dockerfile.app-v13 -t registry.example.com:5000/codesys/codesyscontroldemoapp:v13
$ podman stop codesyscontroldemoapp-v9
$ podman run --name codesyscontroldemoapp-v13 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v13

$ podman save -o /tmp/codesyscontroldemoapp-v13.tar registry.example.com:5000/codesys/codesyscontroldemoapp:v13

$ cat > Dockerfile.app-v14 <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
RUN dnf install -y libpciaccess iproute net-tools procps-ng nmap-ncat iputils && dnf clean all && rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY Test/Application.app /PlcLogic/Application/
COPY Test/Application.crc /PlcLogic/Application/
COPY CODESYSControl_User.cfg /etc
COPY CODESYSControl.cfg /etc
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF

$ podman build -f Dockerfile.app-v14 -t registry.example.com:5000/codesys/codesyscontroldemoapp:v14
$ podman stop codesyscontroldemoapp-v9
$ podman run --name codesyscontroldemoapp-v14 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v14

$ podman save -o /tmp/codesyscontroldemoapp-v14.tar registry.example.com:5000/codesys/codesyscontroldemoapp:v14

$ cat > Dockerfile.app-v15 <<EOF
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
RUN dnf install -y libpciaccess iproute net-tools procps-ng nmap-ncat iputils && dnf clean all && rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY Redundancy/Application.app /PlcLogic/Application/
COPY Redundancy/Application.crc /PlcLogic/Application/
COPY CODESYSControl_User.cfg /etc
COPY CODESYSControl.cfg /etc
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
ENTRYPOINT ["/opt/codesys/bin/codesyscontrol.bin"]
CMD ["/etc/CODESYSControl.cfg"]
EOF

$ podman build -f Dockerfile.app-v15 -t registry.example.com:5000/codesys/codesyscontroldemoapp:v15
$ podman stop codesyscontroldemoapp-v9
$ podman run --name codesyscontroldemoapp-v15 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v15

$ podman save -o /tmp/codesyscontroldemoapp-v15.tar registry.example.com:5000/codesys/codesyscontroldemoapp:v15

$ cat > Dockerfile.app-v16 <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY codesyscontrol-4.1.0.0-2.x86_64.rpm /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
RUN dnf install -y libpciaccess iproute net-tools procps-ng nmap-ncat iputils diffutils && dnf clean all && rpm -ivh /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm --force && rm -f /tmp/codesyscontrol-4.1.0.0-2.x86_64.rpm
COPY Test/Application.app /PlcLogic/Application/
COPY Test/Application.crc /PlcLogic/Application/
COPY CODESYSControl_User.cfg /etc
COPY CODESYSControl.cfg /etc
EXPOSE 4840/tcp
EXPOSE 11740/tcp
EXPOSE 22350/tcp
EXPOSE 1740/udp
CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF

$ podman build -f Dockerfile.app-v16 -t registry.example.com:5000/codesys/codesyscontroldemoapp:v16
$ podman stop codesyscontroldemoapp-v9
$ podman run --name codesyscontroldemoapp-v16 -d -t --network host --privileged registry.example.com:5000/codesys/codesyscontroldemoapp:v16

$ podman save -o /tmp/codesyscontroldemoapp-v16.tar registry.example.com:5000/codesys/codesyscontroldemoapp:v16


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

### 获取 codesyscontrol 线程 id
```
# 获取 codesyscontrol 线程 id 
sh-4.4# ps -eLf | grep codesyscontrol | grep -v grep | grep -v conmon | awk '{print $4}' 
# 设置 cpu core 绑定 和 fifo scheduler 
sh-4.4# ps -eLf | grep codesyscontrol | grep -v grep | grep -v conmon | awk '{print $4}' | while read i ; do echo taskset -cp 3 $i; echo chrt -f -p 95 $i ; done 
# 设置 cpu core 绑定 和 rr scheduler 
sh-4.4# ps -eLf | grep codesyscontrol | grep -v grep | grep -v conmon | awk '{print $4}' | while read i ; do taskset -cp 3 $i; taskset -cp $i ;  chrt -r -p 50 $i ; chrt -p $i ; done 

### 测试发现，在系统完成实时性调优后，将 codesys control 及其子线程绑定到 real time core 上会获得比较好的测试数据
### Task Group 设置 Core - Free Floating
sh-4.4# ps -eLf | grep codesyscontrol | grep -v grep | grep -v conmon | awk '{print $4}' | while read i ; do taskset -cp 1,3 $i; taskset -cp $i ; done

### 查看进程的线程
$ ps -T -p <pid>
```

### gitlab merge request 模拟
```
# 创建新的 branch
$ git checkout -b my-new-branch-1
$ git status
On branch my-new-branch-1
nothing to commit, working tree clean

$ ll dockerfile/PlcLogic/Application/
total 108
-rw-r--r--. 1 root root 105976 Mar 23 14:38 Application.app
-rw-r--r--. 1 root root     20 Mar 23 14:38 Application.crc
$ ll /tmp/Demo2/
total 108
-rw-r--r--. 1 root root 105864 Mar 24 15:41 Application.app
-rw-r--r--. 1 root root     28 Mar 24 15:41 Application.crc

$ cp /tmp/Demo2/* dockerfile/PlcLogic/Application/
$ git status 
On branch my-new-branch-1
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   dockerfile/PlcLogic/Application/Application.app
        modified:   dockerfile/PlcLogic/Application/Application.crc
$ git commit -a -m 'update dockerfile/PlcLogic/Application/* on branch my-new-branch-1'

$ git push origin my-new-branch-1
```

### add config file into deployment
```
$ cat <<EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-management-plc1
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "enp2s0",
      "mode": "bridge",
      "ipam": {
            "type": "static",
            "addresses": [
              {
                "address": "192.168.57.151/24"
              }
            ]
      }
  }'
EOF

$ cat <<EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-management-plc2
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "enp2s0",
      "mode": "bridge",
      "ipam": {
            "type": "static",
            "addresses": [
              {
                "address": "192.168.57.152/24"
              }
            ]
      }
  }'
EOF

$ cat > kustomization.yaml <<EOF
resources:
- configmap1-deployment1.yaml
- configmap2-deployment1.yaml
- deployment1.yaml
- service1.yaml
- configmap1-deployment2.yaml
- configmap2-deployment2.yaml
- deployment2.yaml
- service2.yaml
EOF

$ cat > configmap1-deployment1.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: codesyscontrol1-plc1-cfg
  namespace: codesysdemo
  labels:
    app: codesyscontrol1
data:
  plc1-cfg: |
    ;linux plc1
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
    QDISC_BYPASS=1
    Linux.ProtocolFilter=3
    
    [SysSocket]
    Adapter.0.Name="net2"
    Adapter.0.EnableSetIpAndMask=1
    
    [CmpSchedule]
    SchedulerInterval=4000
    ProcessorLoad.Enable=1
    ProcessorLoad.Maximum=95
    ProcessorLoad.Interval=5000
    DisableOmittedCycleWatchdog=1
EOF

$ cat > configmap2-deployment1.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: codesyscontrol1-plc1-user-cfg
  namespace: codesysdemo
  labels:
    app: codesyscontrol1
data:
  plc1-user-cfg: |
    ;linux plc1
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
    Link1.IpAddressLocal=192.168.57.151
    Link2.IpAddressLocal=0.0.0.0
    Link1.IpAddressPeer=192.168.57.152
    Link2.IpAddressPeer=0.0.0.0
    Link1.Port=1205
    Link2.Port=1205
    
    [CmpRedundancy]
    BootupWaitTime=5000
    TcpWaitTime=2000
    StandbyWaitTime=50
    SyncWaitTime=50
    Bootproject=Application
    RedundancyTaskName=MainTask
    Ethercat=0
    Profibus=0
    PlcIdent=1
    
    [CmpSrv]
    
    [IoDrvEtherCAT]
    
    [CmpUserMgr]
    SECURITY.UserMgmtEnforce=NO
    AsymmetricAuthKey=2de9b07e5461c6d14577b4afeaebe6bf9792c887
    
    [CmpSecureChannel]
    CertificateHash=3495c7af380b94ac0af2ad2ae8ddc7ce56870ef1
EOF

# 生成 deployment1.yaml 
$ cat > deployment1.yaml <<EOF
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
        k8s.v1.cni.cncf.io/networks: codesys-management, codesys-ethercat, codesys-management-plc1          
        cpu-quota.crio.io: "disable"
    spec:
      nodeSelector:
        node-role.kubernetes.io/worker-rt: ''
      containers:
      - image: registry.ocp4.example.com:5000/codesys/codesyscontroldemoapp:v14
        name: codesyscontrol
        runtimeClassName: performance-rt
        resources:
          limits:
            #memory: "2Gi"
            cpu: "1"
          requests:
            #memory: "2Gi"
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
        volumeMounts:
        - name: codesyscontrol-plc1-cfg
          mountPath: /etc/CODESYSControl.cfg
          subPath: plc1-cfg
        - name: codesyscontrol-plc1-user-cfg
          mountPath: /etc/CODESYSControl_User.cfg
          subPath: plc1-user-cfg
      volumes:
      - name: codesyscontrol-plc1-cfg
        configMap:
          name: codesyscontrol1-plc1-cfg
      - name: codesyscontrol-plc1-user-cfg
        configMap:
          name: codesyscontrol1-plc1-user-cfg
EOF

$ cat > configmap1-deployment2.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: codesyscontrol2-plc2-cfg
  namespace: codesysdemo
  labels:
    app: codesyscontrol2
data:
  plc2-cfg: |
    ;linux plc2
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
    QDISC_BYPASS=1
    Linux.ProtocolFilter=3
    
    [SysSocket]
    Adapter.0.Name="net2"
    Adapter.0.EnableSetIpAndMask=1
    
    [CmpSchedule]
    SchedulerInterval=4000
    ProcessorLoad.Enable=1
    ProcessorLoad.Maximum=95
    ProcessorLoad.Interval=5000
    DisableOmittedCycleWatchdog=1
EOF

$ cat > configmap2-deployment2.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: codesyscontrol2-plc2-user-cfg
  namespace: codesysdemo
  labels:
    app: codesyscontrol2
data:
  plc2-user-cfg: |
    ;linux plc2
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
    Link1.IpAddressLocal=192.168.57.152
    Link2.IpAddressLocal=0.0.0.0
    Link1.IpAddressPeer=192.168.57.151
    Link2.IpAddressPeer=0.0.0.0
    Link1.Port=1205
    Link2.Port=1205
    
    [CmpRedundancy]
    BootupWaitTime=5000
    TcpWaitTime=2000
    StandbyWaitTime=50
    SyncWaitTime=50
    Bootproject=Application
    RedundancyTaskName=MainTask
    Ethercat=0
    Profibus=0
    PlcIdent=1
    
    [CmpSrv]
    
    [IoDrvEtherCAT]
    
    [CmpUserMgr]
    SECURITY.UserMgmtEnforce=NO
    AsymmetricAuthKey=2de9b07e5461c6d14577b4afeaebe6bf9792c887
    
    [CmpSecureChannel]
    CertificateHash=3495c7af380b94ac0af2ad2ae8ddc7ce56870ef1
EOF

# 生成 deployment2.yaml 
$ cat > deployment2.yaml <<EOF
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
        k8s.v1.cni.cncf.io/networks: codesys-management, codesys-ethercat, codesys-management-plc2
        cpu-quota.crio.io: "disable"
    spec:
      nodeSelector:
        node-role.kubernetes.io/worker-rt: ''
      containers:
      - image: registry.ocp4.example.com:5000/codesys/codesyscontroldemoapp:v14
        name: codesyscontrol
        runtimeClassName: performance-rt
        resources:
          limits:
            #memory: "2Gi"
            cpu: "1"
          requests:
            #memory: "2Gi"
            cpu: "1"
        securityContext:
          privileged: true         
        ports:
        - containerPort: 4840
          name: upcua
          protocol: TCP
          hostPort: 4841
        - containerPort: 11740
          name: runtimetcp
          protocol: TCP
          hostPort: 11741
        - containerPort: 1740
          name: runtimeudp
          protocol: UDP
          hostPort: 1741
        volumeMounts:
        - name: codesyscontrol-plc2-cfg
          mountPath: /etc/CODESYSControl.cfg
          subPath: plc2-cfg
        - name: codesyscontrol-plc2-user-cfg
          mountPath: /etc/CODESYSControl_User.cfg
          subPath: plc2-user-cfg
      volumes:
      - name: codesyscontrol-plc2-cfg
        configMap:
          name: codesyscontrol2-plc2-cfg
      - name: codesyscontrol-plc2-user-cfg
        configMap:
          name: codesyscontrol2-plc2-user-cfg
EOF

### CodeSys Profinet Configuration
https://help.codesys.com/webapp/_pnio_runtime_configuration_device;product=core_ProfinetIO_Configuration_Editor;version=3.5.16.0
https://help.codesys.com/webapp/_pnio_runtime_configuration_device;product=core_ProfinetIO_Configuration_Editor;version=4.1.0.0
https://content.helpme-codesys.com/en/CODESYS%20Control/_rtsl_virtualization_virtual_control.html


cat <<EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-profinet-plc1
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "host-device",
      "device": "enp4s0"
  }'
EOF

cat <<EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-redundancy-plc1
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eno1",
      "mode": "bridge",
      "ipam": {
            "type": "static",
            "addresses": [
              {
                "address": "192.168.57.151/24"
              }
            ]
      }
  }'
EOF

cat <<EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-redundancy-plc2
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eno1",
      "mode": "bridge",
      "ipam": {
            "type": "static",
            "addresses": [
              {
                "address": "192.168.57.152/24"
              }
            ]
      }
  }'
EOF
```


### net-attach-def for Codesys
```
[root@helper-ocp4test base]# tree . 
.
├── kustomization.yaml
├── net-attach-def-management.yaml
├── net-attach-def-profinet-plc1.yaml
├── net-attach-def-profinet-plc2.yaml
├── net-attach-def-redundancy-plc1.yaml
├── net-attach-def-redundancy-plc2.yaml
└── rolebinding.yaml

0 directories, 7 files

[root@helper-ocp4test base]# cat kustomization.yaml 
resources:
- rolebinding.yaml
- net-attach-def-management.yaml
- net-attach-def-profinet-plc1.yaml
- net-attach-def-profinet-plc2.yaml
- net-attach-def-redundancy-plc1.yaml
- net-attach-def-redundancy-plc2.yaml

[root@helper-ocp4test base]# cat net-attach-def-management.yaml 
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-management
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eno1",
      "mode": "bridge",
      "ipam": {
            "type": "whereabouts",
            "range": "192.168.56.144/29"
      }
  }'

[root@helper-ocp4test base]# cat net-attach-def-profinet-plc1.yaml 
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-profinet-plc1
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "host-device",
      "device": "enp2s0",
      "ipam": {
            "type": "static",
            "addresses": [
              {
                "address": "192.168.58.151/24"
              }
            ]
      }
  }'

[root@helper-ocp4test base]# cat net-attach-def-profinet-plc2.yaml 
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-profinet-plc2
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "host-device",
      "device": "enp4s0",
      "ipam": {
            "type": "static",
            "addresses": [
              {
                "address": "192.168.58.152/24"
              }
            ]
      }
  }'

[root@helper-ocp4test base]# cat net-attach-def-redundancy-plc1.yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-redundancy-plc1
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eno1",
      "mode": "bridge",
      "ipam": {
            "type": "static",
            "addresses": [
              {
                "address": "192.168.57.151/24"
              }
            ]
      }
  }'

[root@helper-ocp4test base]# cat net-attach-def-redundancy-plc2.yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: codesys-redundancy-plc2
  namespace: codesysdemo
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eno1",
      "mode": "bridge",
      "ipam": {
            "type": "static",
            "addresses": [
              {
                "address": "192.168.57.152/24"
              }
            ]
      }
  }'


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
        k8s.v1.cni.cncf.io/networks: codesys-management, codesys-redundancy-plc1, codesys-profinet-plc1  

apiVersion: v1
kind: Service
metadata:
  name: codesyscontrol1
  labels:
    service.kubernetes.io/service-proxy-name: multus-proxy
    app: codesyscontrol1
  annotations:
    k8s.v1.cni.cncf.io/service-network: codesys-management
```


### PNIO Runtime Configuration Controller
https://help.codesys.com/webapp/_pnio_runtime_configuration_controller;product=core_ProfinetIO_Configuration_Editor;version=4.1.0.0<br>
https://help.codesys.com/webapp/_pnio_f_runtime_configuration;product=core_ProfinetIO_Configuration_Editor;version=4.1.0.0<br>
```
https://help.codesys.com/webapp/_pnio_runtime_configuration_controller;product=core_ProfinetIO_Configuration_Editor;version=4.1.0.0

1. 按照上述链接配置 runtime 系统 

[SysEthernet]
Linux.PACKET_QDISC_BYPASS=1
Linux.ProtocolFilter=3

$ ifconfig enp0s25 promisc up
$ ip addr add 192.168.57.166/24 dev enp0s25 


#### Profinet Controller - 确认开启防火墙端口 udp '34964' 和 '49152:65535'
#### Profinet Device - 确认开启防火墙端口 udp '34964' 和 '49152:65535'
$ sudo iptables -I INPUT 1 -p udp --dport 49152:65535 -j ACCEPT
$ sudo iptables -I INPUT 1 -p udp --dport 34964 -j ACCEPT

### Profinet Controller - 在 /etc/CODESYSControl.cfg 里添加 
### Profinet Device - 在 /etc/CODESYSControl.cfg 里添加 
[CmpBlkDrvUdp]
itf.0.AdapterName=enp4s0
itf.0.DoNotUse=1

### Profinet Controller - 在 /etc/CODESYSControl.cfg 里添加 
### Profinet Device -  在 /etc/CODESYSControl.cfg 里添加 

[SysEthernet]
Linux.PACKET_QDISC_BYPASS=1
Linux.ProtocolFilter=3

### Profinet Controller - 在 /etc/CODESYSControl.cfg 和 /etc/CODESYSControl_User.cfg 不包含 SysSocket 配置
### Profinet Device - 这个配置是 Profinet Device 需要的
[SysSocket]
Adapter.0.Name="net3"
Adapter.0.EnableSetIpAndMask=1

```


### 使用 InitContainer 拷贝 Boot Application 到 Runtime
https://forge.codesys.com/forge/talk/Runtime/thread/90ec9d8efe/<br>
```
$ mkdir -p /data/runtimeapp/{runtime1,runtime2}
$ cat > /etc/httpd/conf.d/runtimeapp.conf <<EOF
Alias /runtimeapp "/data/runtimeapp/"
<Directory "/data/runtimeapp/">
  Options +Indexes +FollowSymLinks
  Require all granted
</Directory>
<Location /runtimeapp>
  SetHandler None
</Location>
EOF

### deployment2 会用到 codesyscontrol2-pv-claim-1.yaml 和 codesyscontrol2-pv-claim-2.yaml
[root@support codesyscontrol]# cat kustomization.yaml 
resources:
- pvc1.yaml
- configmap1-deployment1.yaml
- configmap2-deployment1.yaml
- deployment1.yaml
- service1.yaml
#- pvc2.yaml
- codesyscontrol2-pv-claim-1.yaml
- codesyscontrol2-pv-claim-2.yaml
- deployment2.yaml
- service2.yaml

[root@support codesyscontrol]# cat codesyscontrol2-pv-claim-1.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: codesyscontrol2-pv-claim-1
  labels:
    app: codesyscontrol2
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

[root@support codesyscontrol]# cat codesyscontrol2-pv-claim-2.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: codesyscontrol2-pv-claim-2
  labels:
    app: codesyscontrol2
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

### initcontainer 挂载 codesyscontrol2-pv-claim-1
### initcontainer 负责从 registry.example.com:8080 http server 上向 pvc 里拷贝 Application.app 和 Application.crc
### http://registry.example.com:8080/runtimeapp/runtime2/Application.app
### http://registry.example.com:8080/runtimeapp/runtime2/Application.crc
### http://registry.example.com:8080/runtimeapp/runtime2/CODESYSControl.cfg
### http://registry.example.com:8080/runtimeapp/runtime2/CODESYSControl_User.cfg
### 可以用相同的思路拷贝 configfile /etc/CODESYSControl.cfg 和 /etc/CODESYSControl_User.cfg 
[root@support codesyscontrol]# cat deployment2.yaml 
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
      initContainers:
      - name: copy-application-init-1
        image: registry.example.com:5000/codesys/initcontainer:v1
        imagePullPolicy: IfNotPresent
        command: ["/bin/sh"]
        args: ["-c", 'mkdir -p /var/opt/codesys/PlcLogic/Application; if [ -f /var/opt/codesys/PlcLogic/Application/Application.app ]; then echo file Application.app exist; else curl -o /var/opt/codesys/PlcLogic/Application/Application.app http://registry.example.com:8080/runtimeapp/runtime2/Application.app; fi; if [ -f /PlcLogic/Application/Application.app ]; then echo file /PlcLogic/Application/Application.app exist; else curl -o /PlcLogic/Application/Application.app http://registry.example.com:8080/runtimeapp/runtime2/Application.app; fi; if [ -f /var/opt/codesys/PlcLogic/Application/Application.crc ]; then echo file Application.crc exist; else curl -o /var/opt/codesys/PlcLogic/Application/Application.crc http://registry.example.com:8080/runtimeapp/runtime2/Application.crc; fi; if [ -f /PlcLogic/Application/Application.crc ]; then echo file /PlcLogic/Application/Application.crc exist; else curl -o /PlcLogic/Application/Application.crc http://registry.example.com:8080/runtimeapp/runtime2/Application.crc; fi; if [ -f /var/opt/codesys/CODESYSControl.cfg ]; then echo file CODESYSControl.cfg exist; else curl -o /var/opt/codesys/CODESYSControl.cfg http://registry.example.com:8080/runtimeapp/runtime2/CODESYSControl.cfg; fi; if [ -f /var/opt/codesys/CODESYSControl_User.cfg ]; then echo file CODESYSControl_User.cfg exist; else curl -o /var/opt/codesys/CODESYSControl_User.cfg http://registry.example.com:8080/runtimeapp/runtime2/CODESYSControl_User.cfg; fi']
        volumeMounts:
        - name: codesyscontrol2-pv-claim-1
          mountPath: /var/opt/codesys
        - name: codesyscontrol2-pv-claim-2
          mountPath: /PlcLogic/Application
      containers:
      - image: registry.example.com:5000/codesys/codesyscontroldemoapp:v14
        #image: registry.example.com:5000/codesys/codesyscontrol:latest
        name: codesyscontrol
        command: ['/bin/sh']
        args: ["-c", 'if [ -f /var/opt/codesys/CODESYSControl.cfg ]; then cp -fr /var/opt/codesys/CODESYSControl.cfg /etc/CODESYSControl.cfg; fi; if [ -f /var/opt/codesys/CODESYSControl_User.cfg ]; then cp -fr /var/opt/codesys/CODESYSControl_User.cfg /etc/CODESYSControl_User.cfg; fi; /etc/init.d/codesyscontrol start ; exec /bin/bash -c "trap : TERM INT; sleep 9999999999d & wait"']
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
        - name: codesyscontrol2-pv-claim-1
          mountPath: /var/opt/codesys
        - name: codesyscontrol2-pv-claim-2
          mountPath: /PlcLogic/Application
      volumes:
      - name: codesyscontrol2-pv-claim-1
        persistentVolumeClaim:
          claimName: codesyscontrol2-pv-claim-1
      - name: codesyscontrol2-pv-claim-2
        persistentVolumeClaim:
          claimName: codesyscontrol2-pv-claim-2


### 将 args 里 的 exec /bin/bash -c "trap : TERM INT; sleep 9999999999d & wait" 替换为 /opt/codesys/bin/codesyscontrol.bin /etc/CODESYSControl.cfg
### 这样看是否能自动 Pod 
        command: ['/bin/sh']
        args: ["-c", 'if [ -f /var/opt/codesys/CODESYSControl.cfg ]; then cp -fr /var/opt/codesys/CODESYSControl.cfg /etc/CODESYSControl.cfg; fi; if [ -f /var/opt/codesys/CODESYSControl_User.cfg ]; then cp -fr /var/opt/codesys/CODESYSControl_User.cfg /etc/CODESYSControl_User.cfg; fi; /opt/codesys/bin/codesyscontrol.bin /etc/CODESYSControl.cfg']
```

### 构建 alien container 镜像
```
$ cat > Dockerfile.v2 <<EOF
FROM registry.example.com:5000/codesys/alien:v1
COPY codesyscontrol_linux_4.1.0.0_amd64.deb /tmp/codesyscontrol_linux_4.1.0.0_amd64.deb
CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF
$ podman build -f Dockerfile.v2 -t registry.example.com:5000/codesys/alien:v2
$ podman run --name alien-v2 -d -t registry.example.com:5000/codesys/alien:v2
```

### 工业树莓派结合CODESYS配置EtherCAT主站
https://blog.csdn.net/Hongke_IIOT/article/details/126153235
```
### 工业树莓派结合CODESYS配置EtherCAT主站
### 如何将工业树莓派配置为EtherCAT主站
### 与伺服驱动器通讯
```

### multus 
https://cloud.redhat.com/blog/using-the-multus-cni-in-openshift

### 重要的注意事项
```
### 注意: codesysedge, codesyscontrol 的 deployment 里不要用 hostNetwork:true
### 注意: codesysedge, codesyscontrol 的 deployment 里不要用 hostNetwork:true
### 注意: codesysedge, codesyscontrol 的 deployment 里不要用 hostNetwork:true
```

### PLC 相关
工业控制机器人<br>
https://blog.csdn.net/robinvista/article/details/88085020<br>
PLC编程软件: KW multiprog 和 codesys<br>
https://www.cnblogs.com/ecmangy/p/3265632.html<br>

### 报错
```
Connection aborted: AR consumer DHT expired
https://product-help.schneider-electric.com/Machine%20Expert/V1.1/en/core_ProfinetIO_Configuration_Editor/topics/_pnio_trouble_effects_and_causes.htm

Profinet Device keeps abort connection with AR alarm.ind(err)
https://forge.codesys.com/forge/talk/Runtime/thread/26c1967b5b/
```

### 将进程设置在 realtime core 上的方法
```
### 获取 codesyscontrol 进程 id 的方法
sh-4.4# ps axf | grep control1 | grep -v grep | awk '{print $1}'

sh-4.4# pstree -t -p $(ps axf | grep control1 | grep -v grep | awk '{print $1}')
conmon(2105732)-+-bash(2105742)-+-codesyscontrol.(3370021)-+-{BlkDrvTcp}(3370196)
                |               |                          |-{BlkDrvUdp}(3370197)
                |               |                          |-{CAAEventTask}(3370177)
                |               |                          |-{CMHooksTask}(3370023)
                |               |                          |-{CommCycleHook}(3370200)
                |               |                          |-{IoMgrDiagTask}(3370185)
                |               |                          |-{MainTask}(3370186)
                |               |                          |-{OPCUAClient_Net}(3370198)
                |               |                          |-{OPCUAServerSche}(3370194)
                |               |                          |-{OPCUAServerWork}(3370189)
                |               |                          |-{OPCUAServerWork}(3370190)
                |               |                          |-{OPCUAServerWork}(3370191)
                |               |                          |-{OPCUAServerWork}(3370192)
                |               |                          |-{OPCUAServerWork}(3370193)
                |               |                          |-{OPCUAServer}(3370199)
                |               |                          |-{Profinet_Commun}(3370187)
                |               |                          |-{Profinet_IOTask}(3370188)
                |               |                          |-{SchedException}(3370182)
                |               |                          |-{SchedProcessorL}(3370178)
                |               |                          |-{SchedProcessorL}(3370179)
                |               |                          |-{SchedProcessorL}(3370180)
                |               |                          |-{SchedProcessorL}(3370181)
                |               |                          |-{Schedule}(3370183)
                |               |                          |-{TaskGapTask}(3370184)
                |               |                          `-{WebServerCloseC}(3370195)
                |               `-sleep(2105835)
                `-{gmain}(2105734)

### 获取 codesyscontrol 的进程 id
sh-4.4# pstree -t -p 2105732 | grep "codesyscontrol" | sed -e 's|^.*codesyscontrol.(||' | awk -F"[().]" '{print $1}'
3370021

### 设置 codesyscontrol 进程子线程的 cpu 绑定到 core 1-3 上
sh-4.4# ps -eLf | grep $(pstree -t -p $(ps axf | grep control1 | grep -v grep | awk '{print $1}') | grep "codesyscontrol" | sed -e 's|^.*codesyscontrol.(||' | awk -F"[().]" '{print $1}') | grep -v grep | awk '{print $4}' | while read i ; do taskset -cp 1-3 $i; done

### 仍在研究是否需要这么做
```

### cpu 绑定脚本和镜像 - 这个步骤测试发现可以不使用
```
$ mkdir -p /tmp/codesyscpubinding
$ cd /tmp/codesyscpubinding
$ cat > runtimetaskset.sh <<'EOF'
#/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "usage: $0 <commandstr> <tasksetcpulist>"
  echo "   eg: $0 control1 1-3"
  exit 0
else
  COMMANDSTR=$1
  CPULIST=$2
  while true; do
    ps -eLf | grep $(pstree -t -p $(ps axf | grep $COMMANDSTR | grep -v grep | awk '{print $1}') | grep "codesyscontrol" | sed -e 's|^.*codesyscontrol.(||' | awk -F"[().]" '{print $1}') | grep -v grep | awk '{print $4}' | while read i ; do taskset -cp $CPULIST $i; done
    sleep 10
  done
fi
EOF

$ cat > Dockerfile.v1 <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
COPY runtimetaskset.sh /runtimetaskset.sh
RUN dnf install -y libpciaccess iproute net-tools procps-ng && dnf clean all && chmod 0755 /runtimetaskset.sh
CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF

$ podman build -f Dockerfile.v1 -t registry.example.com:5000/codesys/runtimetaskset:v1
$ podman run --name runtimetaskset-v1 -d -t registry.example.com:5000/codesys/runtimetaskset:v1

### runtimetaskset pod 测试
$ mkdir -p runtimetaskset
$ cd runtimetaskset
$ cat > pod.yaml <<EOF
apiVersion: v1 
kind: Pod 
metadata:
  name: runtimetaskset
spec:
  restartPolicy: Never
  hostPID: true
  containers:
  - name: runtimetaskset
    image: registry.ocp4.example.com:5000/codesys/runtimetaskset:v1
    imagePullPolicy: Always
    securityContext:
      privileged: true
  nodeSelector:
    node-role.kubernetes.io/worker-rt: ""
EOF
$ oc apply -f ./pod.yaml 
$ oc rsh runtimetaskset 
### 用 script /runtimetaskset.sh 为 runtime1 设置 cpu core 绑定 1-3
sh-4.4# /runtimetaskset.sh control1 1-3 

$ cat > cronjob.yaml <<EOF
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: codesys-cronjob-runtimetaskset-runtime1
spec:
  concurrencyPolicy: 'Forbid'
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: codesys-cronjob-runtimetaskset-control1
            image: registry.ocp4.example.com:5000/codesys/runtimetaskset:v1
            command: ["/bin/bash"]
            args: ["-c", "/runtimetaskset.sh control1 1-3"]
            securityContext:
              privileged: true
          restartPolicy: Never
          hostPID: true
          nodeSelector:
            node-role.kubernetes.io/worker-rt: ''
EOF

```

### 关于 CODESYS CODESYSControl.cfg 里的 CmpSchedule
https://forge.codesys.com/forge/talk/Engineering/thread/0797bf9f3c/<br>
https://forge.codesys.com/forge/talk/Runtime/thread/dd3a2052c9/?limit=25<br>
https://faq.codesys.com/display/CDSFAQ/Codesys+Taskkonfiguration+-+FAQ<br>
```
### CNC
CNC stands for "Computer Numerical Control" and is a term used in the manufacturing industry to describe the automated control of machine tools using a computer program. In the context of CODESYS PLC, CNC typically refers to the use of a CODESYS-based programmable logic controller (PLC) to control the operation of a CNC machine.

With a CODESYS CNC system, the PLC is responsible for controlling the motion and operation of the CNC machine based on a set of programmed instructions. This can include tasks such as tool selection, toolpath generation, and spindle speed control, among others. The use of a PLC-based CNC system offers several advantages over traditional hardware-based systems, including increased flexibility, improved accuracy, and easier integration with other automation systems.

### KNX
KNX is a standard for home and building automation that enables the integration and control of various devices and systems within a building, such as lighting, heating, ventilation, and security. In the context of CODESYS PLC, KNX typically refers to the use of a CODESYS-based programmable logic controller to control and monitor KNX devices within a building automation system.

With a CODESYS KNX system, the PLC can communicate with KNX devices using the KNX communication protocol, allowing it to control and monitor their functions. This enables the creation of intelligent building automation systems that can be easily programmed and configured using CODESYS.

The use of a CODESYS-based PLC for KNX automation offers several benefits, including the ability to integrate with other automation systems, the ability to create customized automation solutions, and the ease of use provided by the CODESYS development environment.
```

### kernel params - 
```
### I915 force_probe - kernel params
https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/i915/i915_pci.c

### BIOS
### HDC Control - Disabled
https://www.manualslib.com/manual/1263032/Supero-C7z270-Cg-L.html?page=79

### Config TDP Configurations
https://community.acer.com/en/discussion/556179/how-to-edit-tdp-limit-in-bios


```

### 启动 perf-tools 
```
$ podman run --name perf-tools -dt --privileged --network host registry.ocp4.example.com:5000/codesys/perf-tools /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'
$ hwlatdetect --threshold=1us --duration=1h --window 10000000us --width 950000us
```

### rhcos node 如何修改 kernel args
https://access.redhat.com/solutions/6891971
```
sh-4.4# rpm-ostree kargs 
random.trust_cpu=on console=tty0 console=ttyS0,115200n8 $ignition_firstboot ostree=/ostree/boot.0/rhcos/f091a58d602b0ff6f321a708b882987c06a94130b435d2c181131f7a4ce21363/0 ignition.platform.id=aws root=UUID=cc8f9c42-13d5-42df-8da7-147a1c449cd3 rw rootflags=prjquota

sh-4.4# rpm-ostree kargs --delete console=ttyS0,115200n8

sh-4.4# rpm-ostree kargs --append='<key>=<value>'

### 为节点打标签
$ oc label node b5-ocp4test.ocp4.example.com node-role.kubernetes.io/worker-rt: ''
$ oc label node b5-ocp4test.ocp4.example.com  node-role.kubernetes.io/worker-
```

### podman container 的测试数据
```
### podman 
### 1h w/o stress 的测试结果
### /usr/bin/nohup /usr/bin/cyclictest --priority 1 --policy fifo -h 10 -a 1 -t 1 -m -q -i 200 -D 1h &
# /dev/cpu_dma_latency set to 0us
# Histogram
000000 000000
000001 14362421
000002 3531577
000003 065794
000004 040164
000005 000024
000006 000012
000007 000005
000008 000003
000009 000000
# Total: 018000000
# Min Latencies: 00001
# Avg Latencies: 00001
# Max Latencies: 00008
# Histogram Overflows: 00000
# Histogram Overflow at cycle number:
# Thread 0:

### 1h w/ stress 的测试结果
### stress-ng --cpu 1 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout 0
### /usr/bin/nohup /usr/bin/cyclictest --priority 1 --policy fifo -h 10 -a 1 -t 1 -m -q -i 200 -D 1h &
# /dev/cpu_dma_latency set to 0us
# Histogram
000000 000000
000001 16171582
000002 1707750
000003 073773
000004 041681
000005 003957
000006 000625
000007 000364
000008 000190
000009 000073
# Total: 017999995
# Min Latencies: 00001
# Avg Latencies: 00001
# Max Latencies: 00010
# Histogram Overflows: 00005
# Histogram Overflow at cycle number:
# Thread 0: 3768505 4759600 4761473 6770320 14760162
```

### ocp rt worker container 的测试数据
```
### ocp rt worker 
### 1h w/o stress 的测试结果
########## container info ###########
/proc/cmdline:
BOOT_IMAGE=(hd0,gpt3)/ostree/rhcos-7f5b414cc0eec54b321c1523bf3b7f499d4ce4c6a5e86e34c61e07b7c2ba5904/vmlinuz-4.18.0-305.76.1.rt7.148.el8_4.x86_64 random.trust_cpu=on console=tty0 ignition.platform.id=metal ostree=/ostree/boot.1/rhcos/7f5b414cc0eec54b321c1523bf3b7f499d4ce4c6a5e86e34c61e07b7c2ba5904/0 root=UUID=187714fb-67ad-43d9-9f31-48b485005f53 rw rootflags=prjquota boot=UUID=5ef99b8f-b717-4f17-826a-4fe1f046eac4 skew_tick=1 nohz=on rcu_nocbs=1-3 tuned.non_isolcpus=00000001 intel_pstate=disable nosoftlockup tsc=nowatchdog intel_iommu=on iommu=pt isolcpus=managed_irq,1-3 systemd.cpu_affinity=0 audit=0 idle=poll intel_idle.max_cstate=0 processor.max_cstate=0 mce=off i915.force_probe=*
#####################################
**** uid: 0 ****
allowed cpu list: 1
cyclictest 4.18.0-305.76.1.rt7.148.el8_4.x86_64
new cpu list: 
running cmd: cyclictest -q -D 1h -p 95 -t 1 -a  -h 30 -i 1000 -m 
# /dev/cpu_dma_latency set to 0us
# Histogram
000000 000000
000001 1722948
000002 1824322
000003 024747
000004 023759
000005 002331
000006 001019
000007 000454
000008 000247
000009 000132
000010 000029
000011 000005
000012 000007
000013 000000
000014 000000
000015 000000
000016 000000
000017 000000
000018 000000
000019 000000
000020 000000
000021 000000
000022 000000
000023 000000
000024 000000
000025 000000
000026 000000
000027 000000
000028 000000
000029 000000
# Total: 003600000
# Min Latencies: 00001
# Avg Latencies: 00001
# Max Latencies: 00012
# Histogram Overflows: 00000
# Histogram Overflow at cycle number:
# Thread 0:

### ocp rt worker 
### 1h w/ stress 的测试结果
########## container info ###########
/proc/cmdline:
BOOT_IMAGE=(hd0,gpt3)/ostree/rhcos-7f5b414cc0eec54b321c1523bf3b7f499d4ce4c6a5e86e34c61e07b7c2ba5904/vmlinuz-4.18.0-305.76.1.rt7.148.el8_4.x86_64 random.trust_cpu=on console=tty0 ignition.platform.id=metal ostree=/ostree/boot.1/rhcos/7f5b414cc0eec54b321c1523bf3b7f499d4ce4c6a5e86e34c61e07b7c2ba5904/0 root=UUID=187714fb-67ad-43d9-9f31-48b485005f53 rw rootflags=prjquota boot=UUID=5ef99b8f-b717-4f17-826a-4fe1f046eac4 skew_tick=1 nohz=on rcu_nocbs=1-3 tuned.non_isolcpus=00000001 intel_pstate=disable nosoftlockup tsc=nowatchdog intel_iommu=on iommu=pt isolcpus=managed_irq,1-3 systemd.cpu_affinity=0 audit=0 idle=poll intel_idle.max_cstate=0 processor.max_cstate=0 mce=off i915.force_probe=*
#####################################
**** uid: 0 ****
allowed cpu list: 1
cyclictest 4.18.0-305.76.1.rt7.148.el8_4.x86_64
new cpu list: 
running cmd: cyclictest -q -D 1h -p 95 -t 1 -a  -h 30 -i 1000 -m 
# /dev/cpu_dma_latency set to 0us
# Histogram
000000 000000
000001 000387
000002 1774154
000003 804431
000004 784481
000005 203720
000006 011879
000007 009549
000008 004727
000009 003330
000010 002405
000011 000716
000012 000160
000013 000043
000014 000009
000015 000005
000016 000004
000017 000000
000018 000000
000019 000000
000020 000000
000021 000000
000022 000000
000023 000000
000024 000000
000025 000000
000026 000000
000027 000000
000028 000000
000029 000000
# Total: 003600000
# Min Latencies: 00001
# Avg Latencies: 00002
# Max Latencies: 00016
# Histogram Overflows: 00000
# Histogram Overflow at cycle number:
# Thread 0:
```
