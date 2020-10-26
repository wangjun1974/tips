### Configure a Disconnected Registry and Red Hat Enterprise Linux CoreOS Cache
实验流程记录
```
[lab-user@provision ~]$ cd scripts/
[lab-user@provision scripts]$

# check version
[lab-user@provision scripts]$ oc version
Client Version: 4.5.12

# setup version to 4.5.12
[lab-user@provision scripts]$ export VERSION=4.5.12
[lab-user@provision scripts]$ echo $VERSION
4.5.12

[lab-user@provision scripts]$ ./openshift-baremetal-install version
./openshift-baremetal-install 4.5.12
built from commit 9893a482f310ee72089872f1a4caea3dbec34f28
release image quay.io/openshift-release-dev/ocp-release@sha256:d65574acbf8222bacf875f4b0128142d5ed9e687153ce8df2152ba6e0c3f2be3

# 安装 podman 和 httpd
[lab-user@provision scripts]$ sudo dnf -y install podman httpd httpd-tools

# 创建本地 registry 目录
[lab-user@provision scripts]$ sudo mkdir -p /nfs/registry/{auth,certs,data}

# 生成自签名证书
[lab-user@provision scripts]$ sudo openssl req -newkey rsa:4096 -nodes -sha256 \
    -keyout /nfs/registry/certs/domain.key -x509 -days 365 -out /nfs/registry/certs/domain.crt \
    -subj "/C=US/ST=NorthCarolina/L=Raleigh/O=Red Hat/OU=Marketing/CN=provision.$GUID.dynamic.opentlc.com"

# 拷贝证书到 $HOME/scripts 和 /etc/pki/ca-trust/source/anchors/
# 设置系统更新证书信任关系
[lab-user@provision scripts]$ sudo cp /nfs/registry/certs/domain.crt $HOME/scripts/domain.crt
[lab-user@provision scripts]$ sudo chown lab-user $HOME/scripts/domain.crt
[lab-user@provision scripts]$ sudo cp /nfs/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
[lab-user@provision scripts]$ sudo update-ca-trust extract

# 设置 registry 使用 htpasswd 的简单认证
[lab-user@provision scripts]$ sudo htpasswd -bBc /nfs/registry/auth/htpasswd dummy dummy

# 创建本地 registry
[lab-user@provision scripts]$ sudo podman create --name poc-registry --net host -p 5000:5000 \
    -v /nfs/registry/data:/var/lib/registry:z -v /nfs/registry/auth:/auth:z \
    -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry" \
    -e "REGISTRY_HTTP_SECRET=ALongRandomSecretForRegistry" \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v /nfs/registry/certs:/certs:z \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
    -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key docker.io/library/registry:2

# 启动本地 registry
[lab-user@provision scripts]$ sudo podman start poc-registry

# 检查本地 registry 内容
[lab-user@provision scripts]$ curl -u dummy:dummy -k \
    https://provision.$GUID.dynamic.opentlc.com:5000/v2/_catalog

# 准备 RHCoreOS image cache 所需目录
[lab-user@provision scripts]$ export IRONIC_DATA_DIR=/nfs/ocp/ironic
[lab-user@provision scripts]$ export IRONIC_IMAGES_DIR="${IRONIC_DATA_DIR}/html/images"
[lab-user@provision scripts]$ export IRONIC_IMAGE=quay.io/metal3-io/ironic:master
[lab-user@provision scripts]$ sudo mkdir -p $IRONIC_IMAGES_DIR
[lab-user@provision scripts]$ sudo chown -R "${USER}:users" "$IRONIC_DATA_DIR"
[lab-user@provision scripts]$ sudo find $IRONIC_DATA_DIR -type d -print0 | xargs -0 chmod 755
[lab-user@provision scripts]$ sudo chmod -R +r $IRONIC_DATA_DIR

# 创建 ironic-pod
[lab-user@provision scripts]$ sudo podman pod create -n ironic-pod

# 运行 pod
[lab-user@provision scripts]$ sudo podman run -d --net host --privileged --name httpd --pod ironic-pod \
    -v $IRONIC_DATA_DIR:/shared --entrypoint /bin/runhttpd ${IRONIC_IMAGE}

# 检查 RHCoreOS image cache 可访问
[lab-user@provision scripts]$ curl http://provision.$GUID.dynamic.opentlc.com/images

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>301 Moved Permanently</title>
</head><body>
<h1>Moved Permanently</h1>
<p>The document has moved <a href="http://provision.schmaustech.dynamic.opentlc.com/images/">here</a>.</p>
</body></html>

# 测试生成 bcrypt 口令
[lab-user@provision scripts]$ echo -n 'dummy:dummy' | base64 -w0 && echo
ZHVtbXk6ZHVtbXk=

# 将 bcrypt 口令嵌入到 reg-secret.txt 中
[lab-user@provision scripts]$ cat <<EOF > ~/reg-secret.txt
"provision.$GUID.dynamic.opentlc.com:5000": {
    "email": "dummy@redhat.com",
    "auth": "$(echo -n 'dummy:dummy' | base64 -w0)"
}
EOF

# 合并 lab pull secret 和 registry pull secret
# 添加 registry 证书为 install-config.yaml 的 additionalTrustBundle
[lab-user@provision scripts]$ export PULLSECRET=$HOME/pull-secret.json
[lab-user@provision scripts]$ cp $PULLSECRET $PULLSECRET.orig
[lab-user@provision scripts]$ cat $PULLSECRET | jq ".auths += {`cat ~/reg-secret.txt`}" > $PULLSECRET
[lab-user@provision scripts]$ cat $PULLSECRET | tr -d '[:space:]' > tmp-secret
[lab-user@provision scripts]$ mv -f tmp-secret $PULLSECRET
[lab-user@provision scripts]$ rm -f ~/reg-secret.txt
[lab-user@provision scripts]$ sed -i -e 's/^/  /' $(pwd)/domain.crt
[lab-user@provision scripts]$ echo "additionalTrustBundle: |" >> $HOME/scripts/install-config.yaml
[lab-user@provision scripts]$ cat $HOME/scripts/domain.crt >> $HOME/scripts/install-config.yaml
[lab-user@provision scripts]$ sed -i "s/pullSecret:.*/pullSecret: \'$(cat $PULLSECRET)\'/g" \
    $HOME/scripts/install-config.yaml

# 检查生成的 install-config.yaml 文件包含本地 registry 的 pull secret
[lab-user@provision scripts]$ grep pullSecret install-config.yaml | sed 's/^pullSecret: //' | tr -d \' | jq .

# 同步 ocp release image 到本地 registry
[lab-user@provision scripts]$ export UPSTREAM_REPO="quay.io/openshift-release-dev/ocp-release:$VERSION-x86_64"
[lab-user@provision scripts]$ export PULLSECRET=$HOME/pull-secret.json
[lab-user@provision scripts]$ export LOCAL_REG="provision.$GUID.dynamic.opentlc.com:5000"
[lab-user@provision scripts]$ export LOCAL_REPO='ocp4/openshift4'

# 执行镜像同步
[lab-user@provision scripts]$ oc adm release mirror -a $PULLSECRET --from=$UPSTREAM_REPO \
    --to-release-image=$LOCAL_REG/$LOCAL_REPO:$VERSION --to=$LOCAL_REG/$LOCAL_REPO
...
sha256:47e68d4ff0222a3c9ed93c184d2c20781ded48bab860573f2be2eaf7b17ee64a provision.gzswm.dynamic.opentlc.com:5000/ocp4/openshift4:4.5.12-configmap-reloader
info: Mirroring completed in 1m9.06s (92.19MB/s)

Success
Update image:  provision.gzswm.dynamic.opentlc.com:5000/ocp4/openshift4:4.5.12
Mirror prefix: provision.gzswm.dynamic.opentlc.com:5000/ocp4/openshift4

To use the new mirrored repository to install, add the following section to the install-config.yaml:

imageContentSources:
- mirrors:
  - provision.gzswm.dynamic.opentlc.com:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - provision.gzswm.dynamic.opentlc.com:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev


To use the new mirrored repository for upgrades, use the following to create an ImageContentSourcePolicy:

apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: example
spec:
  repositoryDigestMirrors:
  - mirrors:
    - provision.gzswm.dynamic.opentlc.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - provision.gzswm.dynamic.opentlc.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev

# 检查 install-config.yaml 文件包含 imageContentSources
[lab-user@provision scripts]$ grep imageContentSources $HOME/scripts/install-config.yaml -A6
imageContentSources:
- mirrors:
  - provision.gzswm.dynamic.opentlc.com:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
- mirrors:
  - provision.gzswm.dynamic.opentlc.com:5000/ocp4/openshift4
  source: registry.svc.ci.openshift.org/ocp/release

# Now that we have the images synced down we can move on to syncing the RHCOS images needed. There are two required: an RHCOS qemu image and RHCOS openstack image. The RHCOS qemu image is the image used for the bootstrap virtual machines that is created on the provisioning host during the initial phases of the deployment process. The openstack image is used to image the master and worker nodes during the deployment process.

# 获取 installer commit id
[lab-user@provision scripts]$ INSTALL_COMMIT=$(./openshift-baremetal-install version | grep commit | cut -d' ' -f4)
9893a482f310ee72089872f1a4caea3dbec34f28

# 保存 machine image info json 到环境变量
[lab-user@provision scripts]$ IMAGE_JSON=$(curl -s \
	https://raw.githubusercontent.com/openshift/installer/${INSTALL_COMMIT}/data/data/rhcos.json)

# 获取 baseURI，image.qemu 和 image.openstack

[lab-user@provision scripts]$ echo $IMAGE_JSON | jq .baseURI
"https://releases-art-rhcos.svc.ci.openshift.org/art/storage/releases/rhcos-4.5/45.82.202008010929-0/x86_64/"

[lab-user@provision scripts]$ echo $IMAGE_JSON | jq .images.qemu
{
  "path": "rhcos-45.82.202008010929-0-qemu.x86_64.qcow2.gz",
  "sha256": "80ab9b70566c50a7e0b5e62626e5ba391a5f87ac23ea17e5d7376dcc1e2d39ce",
  "size": 898670890,
  "uncompressed-sha256": "c9e2698d0f3bcc48b7c66d7db901266abf27ebd7474b6719992de2d8db96995a",
  "uncompressed-size": 2449014784
}

[lab-user@provision scripts]$ {
  "path": "rhcos-45.82.202008010929-0-openstack.x86_64.qcow2.gz",
  "sha256": "359e7c3560fdd91e64cd0d8df6a172722b10e777aef38673af6246f14838ab1a",
  "size": 896764070,
  "uncompressed-sha256": "036a497599863d9470d2ca558cca3c4685dac06243709afde40ad008dce5a8ac",
  "uncompressed-size": 2400518144
}

# 保存相关信息到环境变量
[lab-user@provision scripts]$ URL_BASE=$(echo $IMAGE_JSON | jq -r .baseURI)
[lab-user@provision scripts]$ QEMU_IMAGE_NAME=$(echo $IMAGE_JSON | jq -r .images.qemu.path)
[lab-user@provision scripts]$ QEMU_IMAGE_SHA256=$(echo $IMAGE_JSON | jq -r .images.qemu.sha256)
[lab-user@provision scripts]$ QEMU_IMAGE_UNCOMPRESSED_SHA256=$(echo $IMAGE_JSON | jq -r '.images.qemu."uncompressed-sha256"')
[lab-user@provision scripts]$ OPENSTACK_IMAGE_NAME=$(echo $IMAGE_JSON | jq -r .images.openstack.path)
[lab-user@provision scripts]$ OPENSTACK_IMAGE_SHA256=$(echo $IMAGE_JSON | jq -r .images.openstack.sha256)

# 将镜像同步到本地 cache
[lab-user@provision scripts]$ curl -L -o ${IRONIC_DATA_DIR}/html/images/${QEMU_IMAGE_NAME} \
	${URL_BASE}/${QEMU_IMAGE_NAME}
 % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   161  100   161    0     0    463      0 --:--:-- --:--:-- --:--:--   463
100  857M  100  857M    0     0  28.2M      0  0:00:30  0:00:30 --:--:-- 48.7M

[lab-user@provision scripts]$ curl -L -o ${IRONIC_DATA_DIR}/html/images/${OPENSTACK_IMAGE_NAME} \
	${URL_BASE}/${OPENSTACK_IMAGE_NAME}
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
100   161  100   161    0     0    958      0 --:--:-- --:--:-- --:--:--   958
100  855M  100  855M    0     0  47.0M      0  0:00:18  0:00:18 --:--:-- 49.3M

# 检查镜像的 SHA256 校验码
[lab-user@provision scripts]$ echo "$QEMU_IMAGE_SHA256 ${IRONIC_DATA_DIR}/html/images/${QEMU_IMAGE_NAME}" \
	| sha256sum -c
/nfs/ocp/ironic/html/images/rhcos-45.82.202008010929-0-qemu.x86_64.qcow2.gz: OK

[lab-user@provision scripts]$ echo "$OPENSTACK_IMAGE_SHA256 ${IRONIC_DATA_DIR}/html/images/${OPENSTACK_IMAGE_NAME}" \
	| sha256sum -c
/nfs/ocp/ironic/html/images/rhcos-45.82.202008010929-0-openstack.x86_64.qcow2.gz: OK

# install-config.yaml 文件设置了临时的变量
[lab-user@provision scripts]$ grep http://10.20.0.2 install-config.yaml
    bootstrapOSImage: http://10.20.0.2/images/RHCOS_QEMU_IMAGE
    clusterOSImage: http://10.20.0.2/images/RHCOS_OPENSTACK_IMAGE

# 设置 RHCOS_QEMU_IMAGE 和 RHCOS_OPENSTACK_IMAGE 变量，并且替换
[lab-user@provision scripts]$ RHCOS_QEMU_IMAGE=${QEMU_IMAGE_NAME}?sha256=${QEMU_IMAGE_UNCOMPRESSED_SHA256}

[lab-user@provision scripts]$ RHCOS_OPENSTACK_IMAGE=${OPENSTACK_IMAGE_NAME}?sha256=${OPENSTACK_IMAGE_SHA256}

[lab-user@provision scripts]$ sed -i "s/RHCOS_QEMU_IMAGE/$RHCOS_QEMU_IMAGE/g" \
	$HOME/scripts/install-config.yaml

[lab-user@provision scripts]$ sed -i "s/RHCOS_OPENSTACK_IMAGE/$RHCOS_OPENSTACK_IMAGE/g" \
	$HOME/scripts/install-config.yaml

# 查看替换结果
[lab-user@provision scripts]$ grep http://10.20.0.2 install-config.yaml
    bootstrapOSImage: http://10.20.0.2/images/rhcos-45.82.202008010929-0-qemu.x86_64.qcow2.gz?sha256=c9e2698d0f3bcc48b7c66d7db901266abf27ebd7474b6719992de2d8db96995a
    clusterOSImage: http://10.20.0.2/images/rhcos-45.82.202008010929-0-openstack.x86_64.qcow2.gz?sha256=359e7c3560fdd91e64cd0d8df6a172722b10e777aef38673af6246f14838ab1a
```

### Creating an OpenShift Cluster
路程记录
```
# 检查 install-config.yaml 文件，重要的地方以 <=== 标注
[lab-user@provision scripts]$ cat install-config.yaml
apiVersion: v1
baseDomain: dynamic.opentlc.com
metadata:
  name: schmaustech <===CLUSTER NAME
networking:
  networkType: OpenShiftSDN <=== NETWORK SDN TO USE ON DEPLOY
  machineCIDR: 10.20.0.0/24 <=== EXTERNAL/BAREMETAL NETWORK
compute:
- name: worker
  replicas: 2 <=== NUMBER OF WORKERS ON DEPLOYMENT
controlPlane:
  name: master
  replicas: 3 <=== NUMBER OF MASTERS ON DEPLOYMENT
  platform:
    baremetal: {}
platform:
  baremetal:
    provisioningNetworkCIDR: 172.22.0.0/24 <=== SUBNET OF PROVISIONING NETWORK
    provisioningNetworkInterface: ens3
    apiVIP: 10.20.0.110
    ingressVIP: 10.20.0.112
    dnsVIP: 10.20.0.111
    bootstrapOSImage: http://10.20.0.2/images/rhcos-45.82.202008010929-0-qemu.x86_64.qcow2.gz?sha256=c9e2698d0f3bcc48b7c66d7db901266abf27ebd7474b6719992de2d8db96995a
    clusterOSImage: http://10.20.0.2/images/rhcos-45.82.202008010929-0-openstack.x86_64.qcow2.gz?sha256=359e7c3560fdd91e64cd0d8df6a172722b10e777aef38673af6246f14838ab1a
    hosts:
      - name: master-0
        role: master
        bmc:
          address: ipmi://10.20.0.3:6204
          username: admin
          password: redhat
        bootMACAddress: de:ad:be:ef:00:40
        hardwareProfile: openstack
      - name: master-1
        role: master
        bmc:
          address: ipmi://10.20.0.3:6201
          username: admin
          password: redhat
        bootMACAddress: de:ad:be:ef:00:41
        hardwareProfile: openstack
      - name: master-2
        role: master
        bmc:
          address: ipmi://10.20.0.3:6200
          username: admin
          password: redhat
        bootMACAddress: de:ad:be:ef:00:42
        hardwareProfile: openstack
      - name: worker-0
        role: worker
        bmc:
          address: ipmi://10.20.0.3:6205
          username: admin
          password: redhat
        bootMACAddress: de:ad:be:ef:00:50
        hardwareProfile: openstack
      - name: worker-1
        role: worker
        bmc:
          address: ipmi://10.20.0.3:6202
          username: admin
          password: redhat
        bootMACAddress: de:ad:be:ef:00:51
        hardwareProfile: openstack
sshKey: 'ssh-rsa REDACTED SSH KEY lab-user@provision'
imageContentSources:
- mirrors:
  - provision.schmaustech.students.osp.opentlc.com:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
- mirrors:
  - provision.schmaustech.students.osp.opentlc.com:5000/ocp4/openshift4
  source: registry.svc.ci.openshift.org/ocp/release
pullSecret: 'REDACTED PULL SECRET'
additionalTrustBundle: |
  -----BEGIN CERTIFICATE-----
 REDACTED CERTIFICATE
  -----END CERTIFICATE-----

# 检查部署前 master, worker 处于关机状态
[lab-user@provision scripts]$ for i in 0 1 2 3 4 5
 do
 /usr/bin/ipmitool -I lanplus -H10.20.0.3 -p620$i -Uadmin -Predhat chassis power off
 done
Chassis Power Control: Down/Off
Chassis Power Control: Down/Off
Chassis Power Control: Down/Off
Chassis Power Control: Down/Off
Chassis Power Control: Down/Off
Chassis Power Control: Down/Off
[lab-user@provision scripts]$

# NOTE: These commands may fail (Unable to set Chassis Power Control to Down/Off), if the load on the underlying infrastructure is too high. If this happens, simply re-run the "script" until it succeeds for all nodes.

# 创建 manifests

# 创建 cluster state 目录 
[lab-user@provision scripts]$ mkdir $HOME/scripts/ocp

# 拷贝 install-config.yaml 文件到 cluster state 目录
[lab-user@provision scripts]$ cp $HOME/scripts/install-config.yaml $HOME/scripts/ocp

# NOTE: The installer will consume the install-config.yaml and remove the file from the state direcrtory. If you have not saved it somewhere else you can regenerate it with openshift-baremetal-install create install-config --dir=ocp on a running cluster.

# 创建 manifests 
[lab-user@provision scripts]$ $HOME/scripts/openshift-baremetal-install --dir=ocp --log-level debug create manifests
DEBUG OpenShift Installer 4.5.12                    
DEBUG Built from commit 9893a482f310ee72089872f1a4caea3dbec34f28 
DEBUG Fetching Master Machines...                  
DEBUG Loading Master Machines...                   
(...)
DEBUG   Loading Private Cluster Outbound Service... 
DEBUG   Loading Baremetal Config CR...             
DEBUG   Loading Image...                           
WARNING Discarding the Openshift Manifests that was provided in the target directory because its dependencies are dirty and it needs to be regenerated 
DEBUG   Fetching Install Config...                 
DEBUG   Reusing previously-fetched Install Config  
DEBUG   Fetching Cluster ID...                     
DEBUG   Reusing previously-fetched Cluster ID      
DEBUG   Fetching Kubeadmin Password...             
DEBUG   Generating Kubeadmin Password...           
DEBUG   Fetching OpenShift Install (Manifests)...  
DEBUG   Generating OpenShift Install (Manifests)... 
DEBUG   Fetching CloudCredsSecret...               
DEBUG   Generating CloudCredsSecret...             
DEBUG   Fetching KubeadminPasswordSecret...        
DEBUG   Generating KubeadminPasswordSecret...      
DEBUG   Fetching RoleCloudCredsSecretReader...     
DEBUG   Generating RoleCloudCredsSecretReader...   
DEBUG   Fetching Private Cluster Outbound Service... 
DEBUG   Generating Private Cluster Outbound Service... 
DEBUG   Fetching Baremetal Config CR...            
DEBUG   Generating Baremetal Config CR...          
DEBUG   Fetching Image...                          
DEBUG   Reusing previously-fetched Image           
DEBUG Generating Openshift Manifests...  

# 检查 manifests 目录
[lab-user@provision scripts]$ ls -l $HOME/scripts/ocp/manifests/
total 116
-rw-r-----. 1 lab-user users  169 Oct 14 11:08 04-openshift-machine-config-operator.yaml
-rw-r-----. 1 lab-user users 6309 Oct 14 11:08 cluster-config.yaml
-rw-r-----. 1 lab-user users  154 Oct 14 11:08 cluster-dns-02-config.yml
-rw-r-----. 1 lab-user users  542 Oct 14 11:08 cluster-infrastructure-02-config.yml
-rw-r-----. 1 lab-user users  159 Oct 14 11:08 cluster-ingress-02-config.yml
-rw-r-----. 1 lab-user users  513 Oct 14 11:08 cluster-network-01-crd.yml
-rw-r-----. 1 lab-user users  272 Oct 14 11:08 cluster-network-02-config.yml
-rw-r-----. 1 lab-user users  142 Oct 14 11:08 cluster-proxy-01-config.yaml
-rw-r-----. 1 lab-user users  171 Oct 14 11:08 cluster-scheduler-02-config.yml
-rw-r-----. 1 lab-user users  264 Oct 14 11:08 cvo-overrides.yaml
-rw-r-----. 1 lab-user users 1335 Oct 14 11:08 etcd-ca-bundle-configmap.yaml
-rw-r-----. 1 lab-user users 3962 Oct 14 11:08 etcd-client-secret.yaml
-rw-r-----. 1 lab-user users  423 Oct 14 11:08 etcd-host-service-endpoints.yaml
-rw-r-----. 1 lab-user users  271 Oct 14 11:08 etcd-host-service.yaml
-rw-r-----. 1 lab-user users 4009 Oct 14 11:08 etcd-metric-client-secret.yaml
-rw-r-----. 1 lab-user users 1359 Oct 14 11:08 etcd-metric-serving-ca-configmap.yaml
-rw-r-----. 1 lab-user users 3921 Oct 14 11:08 etcd-metric-signer-secret.yaml
-rw-r-----. 1 lab-user users  156 Oct 14 11:08 etcd-namespace.yaml
-rw-r-----. 1 lab-user users  334 Oct 14 11:08 etcd-service.yaml
-rw-r-----. 1 lab-user users 1336 Oct 14 11:08 etcd-serving-ca-configmap.yaml
-rw-r-----. 1 lab-user users 3894 Oct 14 11:08 etcd-signer-secret.yaml
-rw-r-----. 1 lab-user users  301 Oct 14 11:08 image-content-source-policy-0.yaml
-rw-r-----. 1 lab-user users  296 Oct 14 11:08 image-content-source-policy-1.yaml
-rw-r-----. 1 lab-user users  118 Oct 14 11:08 kube-cloud-config.yaml
-rw-r-----. 1 lab-user users 1304 Oct 14 11:08 kube-system-configmap-root-ca.yaml
-rw-r-----. 1 lab-user users 4094 Oct 14 11:08 machine-config-server-tls-secret.yaml
-rw-r-----. 1 lab-user users 3993 Oct 14 11:08 openshift-config-secret-pull-secret.yaml
-rw-r-----. 1 lab-user users 2411 Oct 14 11:08 user-ca-bundle-config.yaml

# 创建 cluster
[lab-user@provision scripts]$ $HOME/scripts/openshift-baremetal-install --dir=ocp --log-level debug create cluster
DEBUG OpenShift Installer 4.5.12                    
DEBUG Built from commit 9893a482f310ee72089872f1a4caea3dbec34f28 
DEBUG Fetching Metadata...                         
DEBUG Loading Metadata...                          
DEBUG   Loading Cluster ID...                      
DEBUG     Loading Install Config...                
DEBUG       Loading SSH Key...                     
DEBUG       Loading Base Domain...                 
DEBUG         Loading Platform...                  
DEBUG       Loading Cluster Name...                
DEBUG         Loading Base Domain...               
DEBUG         Loading Platform...                  
DEBUG       Loading Pull Secret...                 
DEBUG       Loading Platform...                    
DEBUG     Using Install Config loaded from state file 
DEBUG   Using Cluster ID loaded from state file
(...)
INFO Obtaining RHCOS image file from 'http://10.20.0.2/images/rhcos-45.82.202008010929-0-qemu.x86_64.qcow2.gz?sha256=c9e2698d0f3bcc48b7c66d7db901266abf27ebd7474b6719992de2d8db96995a' 
INFO The file was found in cache: /home/lab-user/.cache/openshift-installer/image_cache/ad57fdbef98553f778ac17b95b094a1a. Reusing... 
INFO Consuming OpenShift Install (Manifests) from target directory 
(...)
DEBUG module.masters.ironic_node_v1.openshift-master-host[1]: Still creating... [2m10s elapsed] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[0]: Still creating... [2m10s elapsed] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[2]: Still creating... [2m10s elapsed] 
DEBUG module.bootstrap.libvirt_volume.bootstrap: Still creating... [2m10s elapsed] 
DEBUG module.bootstrap.libvirt_ignition.bootstrap: Still creating... [2m10s elapsed] 
DEBUG module.bootstrap.libvirt_volume.bootstrap: Creation complete after 2m17s [id=/var/lib/libvirt/images/schmaustech-mhnfj-bootstrap] 
DEBUG module.bootstrap.libvirt_ignition.bootstrap: Creation complete after 2m17s [id=/var/lib/libvirt/images/schmaustech-mhnfj-bootstrap.ign;5f7b64ba-cc8f-cec4-bf8c-47a4883c9bf6] 
DEBUG module.bootstrap.libvirt_domain.bootstrap: Creating... 
DEBUG module.bootstrap.libvirt_domain.bootstrap: Creation complete after 1s [id=008b263f-363d-4685-a2ca-e8852e3b5d05] 
(...)
DEBUG module.masters.ironic_node_v1.openshift-master-host[0]: Creation complete after 24m20s [id=63c12136-0605-4b0b-a2b3-b53b992b8189] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[1]: Still creating... [24m21s elapsed] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[2]: Still creating... [24m21s elapsed] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[1]: Still creating... [24m31s elapsed] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[2]: Still creating... [24m31s elapsed] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[2]: Still creating... [24m41s elapsed] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[1]: Still creating... [24m41s elapsed] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[2]: Creation complete after 24m41s [id=a84a8327-3ecc-440c-91a2-fcf6546ab1f1] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[1]: Still creating... [24m51s elapsed] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[1]: Still creating... [25m1s elapsed] 
DEBUG module.masters.ironic_node_v1.openshift-master-host[1]: Creation complete after 25m2s [id=cb208530-0ff9-4946-bd11-b514190a56c1] 
DEBUG module.masters.data.ironic_introspection.openshift-master-introspection[0]: Refreshing state... 
DEBUG module.masters.data.ironic_introspection.openshift-master-introspection[2]: Refreshing state... 
DEBUG module.masters.data.ironic_introspection.openshift-master-introspection[1]: Refreshing state... 
DEBUG module.masters.ironic_allocation_v1.openshift-master-allocation[0]: Creating... 
DEBUG module.masters.ironic_allocation_v1.openshift-master-allocation[2]: Creating... 
DEBUG module.masters.ironic_allocation_v1.openshift-master-allocation[1]: Creating... 
DEBUG module.masters.ironic_allocation_v1.openshift-master-allocation[1]: Creation complete after 2s [id=5920c1cc-4e14-4563-b9a4-12618ca315ba] 
DEBUG module.masters.ironic_allocation_v1.openshift-master-allocation[2]: Creation complete after 3s [id=9f371836-b9bd-4bd1-9e6d-d604c6c9d1b8] 
DEBUG module.masters.ironic_allocation_v1.openshift-master-allocation[0]: Creation complete after 3s [id=0537b2e4-8ba4-42a4-9f93-0a138444ae42] 
DEBUG module.masters.ironic_deployment.openshift-master-deployment[0]: Creating... 
DEBUG module.masters.ironic_deployment.openshift-master-deployment[1]: Creating... 
DEBUG module.masters.ironic_deployment.openshift-master-deployment[2]: Creating... 
DEBUG module.masters.ironic_deployment.openshift-master-deployment[0]: Still creating... [10s elapsed] 
DEBUG module.masters.ironic_deployment.openshift-master-deployment[2]: Still creating... [10s elapsed] 
DEBUG module.masters.ironic_deployment.openshift-master-deployment[1]: Still creating... [10s elapsed] 
(...)
DEBUG module.masters.ironic_deployment.openshift-master-deployment[0]: Still creating... [9m0s elapsed] 
DEBUG module.masters.ironic_deployment.openshift-master-deployment[0]: Creation complete after 9m4s [id=63c12136-0605-4b0b-a2b3-b53b992b8189] 
DEBUG                                              
DEBUG Apply complete! Resources: 12 added, 0 changed, 0 destroyed. 
DEBUG OpenShift Installer 4.5.12                 
DEBUG Built from commit 0d5c871ce7d03f3d03ab4371dc39916a5415cf5c 
INFO Waiting up to 20m0s for the Kubernetes API at https://api.schmaustech.dynamic.opentlc.com:6443... 
INFO API v1.18.3+6c42de8 up                       
INFO Waiting up to 40m0s for bootstrapping to complete...
(...)
DEBUG Bootstrap status: complete                   
INFO Destroying the bootstrap resources... 
(...)
DEBUG Still waiting for the cluster to initialize: Working towards 4.5.12 
DEBUG Still waiting for the cluster to initialize: Working towards 4.5.12: downloading update 
DEBUG Still waiting for the cluster to initialize: Working towards 4.5.12: 0% complete 
DEBUG Still waiting for the cluster to initialize: Working towards 4.5.12: 41% complete 
DEBUG Still waiting for the cluster to initialize: Working towards 4.5.12: 57% complete 
(...)
DEBUG Still waiting for the cluster to initialize: Some cluster operators are still updating: authentication, console, csi-snapshot-controller, ingress, kube-storage-version-migrator, monitoring 
DEBUG Still waiting for the cluster to initialize: Working towards 4.5.12: 86% complete 
DEBUG Still waiting for the cluster to initialize: Working towards 4.5.12: 86% complete 
DEBUG Still waiting for the cluster to initialize: Working towards 4.5.12: 86% complete 
(...)
DEBUG Still waiting for the cluster to initialize: Working towards 4.5.12: 92% complete 
DEBUG Cluster is initialized                       
INFO Waiting up to 10m0s for the openshift-console route to be created... 
DEBUG Route found in openshift-console namespace: console 
DEBUG Route found in openshift-console namespace: downloads 
DEBUG OpenShift console route is created           
INFO Install complete!                            
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/home/lab-user/scripts/ocp/auth/kubeconfig' 
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.schmaustech.dynamic.opentlc.com 
INFO Login to the console with user: "kubeadmin", and password: "5VGM2-uMov3-4N2Vi-n5i3H" 
DEBUG Time elapsed per stage:                      
DEBUG     Infrastructure: 34m17s                   
DEBUG Bootstrap Complete: 35m56s                   
DEBUG  Bootstrap Destroy: 10s                      
DEBUG  Cluster Operators: 38m6s                    
INFO Time elapsed: 1h48m36s  
```