```
测试虚拟机
 -     jwang-ocp4-aHelper             shut off
 -     jwang-ocp452-bootstrap         shut off
 -     jwang-ocp452-master0           shut off
 -     jwang-ocp452-master1           shut off
 -     jwang-ocp452-master2           shut off
 -     jwang-ocp452-worker0           shut off
 -     jwang-ocp452-worker1           shut off
 -     jwang-ocp452-worker2           shut off


3.2	下载离线安装文件方法
3.2.1	设置OCP安装版本信息
export OCP_MAJOR_VER=4.8
export OCP_VER=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-${OCP_MAJOR_VER}/release.txt | \grep 'Name:' | awk '{print $NF}')
echo ${OCP_VER}

3.2.2	创建离线介质目录
export OCP_PATH=/data/OCP-${OCP_VER}/ocp
export YUM_PATH=/data/OCP-${OCP_VER}/yum
mkdir -p ${OCP_PATH}/{app-image,ocp-client,ocp-image,ocp-installer,rhcos,secret}  ${YUM_PATH}

3.2.3	下载离线YUM源
3.2.3.1	登录订阅账户并绑定OpenShift订阅
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
export SUB_USER=XXXXX
export SUB_PASSWD=XXXXX
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

subscription-manager register --force --user ${SUB_USER} --password ${SUB_PASSWD}
subscription-manager refresh
subscription-manager list --available --matches 'Red Hat OpenShift Container Platform' | grep "Pool ID"
subscription-manager attach --pool=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

3.2.3.2	开启订阅频道
3.2.3.2.1.	关闭所有预先启用的yum频道
subscription-manager repos --disable=*

3.2.3.2.2.	仅启用与本次部署相关的yum源
subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-${OCP_MAJOR_VER}-rpms" 
subscription-manager repos --list-enabled

3.2.3.3	批量下载软件包
yum -y install yum-utils createrepo 
for repo in $(subscription-manager repos --list-enabled | grep "Repo ID" | awk '{print $3}'); do
    reposync --gpgcheck -lmn --repoid=${repo} --download_path=${YUM_PATH}
    createrepo -v ${YUM_PATH}/${repo} -o ${YUM_PATH}/${repo} 
done

3.2.3.4	检查下载后的软件包容量
du -lh ${YUM_PATH} --max-depth=1

3.2.3.5	压缩打包
pushd ${YUM_PATH}
for dir in $(ls --indicator-style=none ${YUM_PATH}/); do
    tar -zcvf ${YUM_PATH}/${dir}.tar.gz ${dir}; 
done
ll -h ${YUM_PATH}/*.tar.gz

3.2.3.6	清除文件并退出订阅
rm -rf $(ls ${YUM_PATH} |egrep -v gz)
popd
subscription-manager unregister

3.2.4	下载并安装OCP客户端
curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VER}/openshift-client-linux-${OCP_VER}.tar.gz -o ${OCP_PATH}/ocp-client/openshift-client-linux-${OCP_VER}.tar.gz
tar -xzf ${OCP_PATH}/ocp-client/openshift-client-linux-${OCP_VER}.tar.gz -C /usr/local/sbin/
oc version

3.2.5	下载OCP核心镜像
3.2.5.1	获取下载镜像所需密钥
使用RedHat订阅账号登录https://cloud.redhat.com/openshift/install/pull-secret，将图中pull secret复制到${OCP_PATH}/secret/redhat-pull-secret.json文件中。

export PULL_SECRET_FILE=${OCP_PATH}/secret/redhat-pull-secret.json
jq . 

3.2.5.2	验证待下载的镜像信息
oc adm release info "quay.io/openshift-release-dev/ocp-release:${OCP_VER}-x86_64" 

3.2.5.3	启动镜像下载
oc adm release mirror -a ${PULL_SECRET_FILE} \
     --from=quay.io/openshift-release-dev/ocp-release:${OCP_VER}-x86_64 --to-dir=${OCP_PATH}/ocp-image/mirror_${OCP_VER}

3.2.5.4	检查下载镜像的有效性
oc adm release info ${OCP_VER} --dir=${OCP_PATH}/ocp-image/mirror_${OCP_VER}  

3.2.5.5	镜像打包
tar -zcvf ${OCP_PATH}/ocp-image/ocp-image-${OCP_VER}.tar -C ${OCP_PATH}/ocp-image ./mirror_${OCP_VER}

3.2.5.6	清理文件
rm -rf ${OCP_PATH}/ocp-image/mirror_${OCP_VER}

3.2.6	下载CoreOS镜像
3.2.6.1	获取CoreOS版本信息
RHCOS_VER=$(curl -s https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${OCP_MAJOR_VER}/latest/sha256sum.txt | grep x86_64-live.x86_64 | awk -F\- '{print $2}' | head -1)
echo ${RHCOS_VER}

3.2.6.2	查看不同平台的CoreOS文件列表
curl -s https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${OCP_MAJOR_VER}/latest/sha256sum.txt | awk '{print $2}' | grep rhcos

3.2.6.3	 下载CoreOS启动镜像文件
curl -L https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${OCP_MAJOR_VER}/${RHCOS_VER}/rhcos-${RHCOS_VER}-x86_64-live.x86_64.iso -o ${OCP_PATH}/rhcos/rhcos-${RHCOS_VER}-x86_64-live.x86_64.iso
ll -h ${OCP_PATH}/rhcos

3.2.7	下载openshift-install
curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VER}/openshift-install-linux-${OCP_VER}.tar.gz -o ${OCP_PATH}/ocp-installer/openshift-install-linux-${OCP_VER}.tar.gz
ll -h ${OCP_PATH}/ocp-installer
tar -xzf ${OCP_PATH}/ocp-installer/openshift-install-linux-${OCP_VER}.tar.gz -C /usr/local/sbin/

3.2.8	下载离线ImageStream镜像包（可选）
3.2.8.1	创建镜像列表文件
mkdir -p ${OCP_PATH}/app-image/redhat-app/images

执行命令，将所有下载镜像写入app-images.txt文件。
IMAGE_LIST_FILE_NAME=${OCP_PATH}/app-image/redhat-app/app-images.txt
touch ${IMAGE_LIST_FILE_NAME}
IMAGES=$(oc get is -o custom-columns=NAME:metadata.name --no-headers -l samples.operator.openshift.io/managed)
for IMAGE in ${IMAGES}
do
  i=0
  IS_KINDS=$(oc get is ${IMAGE} -o=jsonpath='{.spec.tags[*].from.kind}')
  for IS_KIND in ${IS_KINDS}
  do
    if [ $IS_KIND = "DockerImage" ]; then
        IS_ADDR=$(oc get is ${IMAGE} -o=jsonpath={.spec.tags[$i].from.name})
        SITE=${IS_ADDR:0:8}
        if [ ${SITE} = "registry" ]; then
            echo ${IS_ADDR} >> ${IMAGE_LIST_FILE_NAME}
        fi
    fi
    ((i++))
  done
done

3.2.8.2	测试下载
先以其中一个镜像为例，测试下载过程是否正常
oc image mirror -a ${PULL_SECRET_FILE} --filter-by-os=linux/amd64 registry.redhat.io/rhscl/ruby-25-rhel7:latest \
--dir=${OCP_PATH}/app-image/redhat-app/images file://rhscl/ruby-25-rhel7:latest
oc image info --dir=${OCP_PATH}/app-image/redhat-app/images file://ruby-25-rhel7:latest
tree ${OCP_PATH}/app-image/redhat-app/images

删除测试文件
rm -rf ${OCP_PATH}/app-image/redhat-app/images/*

3.2.8.3	批量下载镜像
cat ${OCP_PATH}/app-image/redhat-app/app-images.txt | while read line; do
  echo “"================> Begin downloading $line <================"”
  oc image mirror -a ${PULL_SECRET_FILE} ${line} --filter-by-os=linux/amd64 --dir=${OCP_PATH}/app-image/redhat-app/images \
    file://$(echo ${line} | cut -d '/' -f2)/$(echo ${line} | cut -d '/' -f3)
done
du -lh ${OCP_PATH}/app-image/redhat-app/images/v2 --max-depth=1

3.2.8.4	检查下载镜像
查看已下载镜像，查看是否有下载错误出现
cat ${OCP_PATH}/app-image/redhat-app/app-images.txt | while read line; do
  oc image info --dir=${OCP_PATH}/app-image/redhat-app/images \
    file://$(echo ${line} | cut -d '/' -f2)/$(echo ${line} | cut -d '/' -f3) | grep error
  if [ $? -eq 0 ]; then
    echo "ERROR for ${line}."
  else
    echo "RIGHT for ${line}."
  fi
done

3.2.8.5	批量打包镜像
for dir1 in $(ls --indicator-style=none ${OCP_PATH}/app-image/redhat-app/images/v2); do
  for dir2 in $(ls --indicator-style=none ${OCP_PATH}/app-image/redhat-app/images/v2/${dir1}); do
   tar -zcvf ${OCP_PATH}/app-image/redhat-app/images/v2/${dir1}/${dir2}.tar.gz \
     -C ${OCP_PATH}/app-image/redhat-app/images/v2/${dir1} ${dir2}
  done
done

3.2.8.6	清除下载文件
shopt -s extglob
for dir1 in $(ls --indicator-style=none ${OCP_PATH}/app-image/redhat-app/images/v2); do
   rm -rf ${OCP_PATH}/app-image/redhat-app/images/v2/${dir1}/!(*.tar.gz)
done

4.2.2	上传安装介质
mkdir /data
scp -r root@<BASTION-IP>:/data/OCP-4.8.10 /data/

4.3	设置环境变量
export OCP_CLUSTER_ID=ocp4-1
cat << EOF >> ~/.bashrc-${OCP_CLUSTER_ID}
#######################################
setVAR(){
  if [ \$# = 0 ]
  then
    echo "USAGE: "
    echo "   setVAR VAR_NAME VAR_VALUE    # Set VAR_NAME with VAR_VALUE"
    echo "   setVAR VAR_NAME              # Delete VAR_NAME"
  elif [ \$# = 1 ]
  then
    sed -i "/\${1}/d" ~/.bashrc-${OCP_CLUSTER_ID}
source ~/.bashrc-${OCP_CLUSTER_ID}
unset \${1}
    echo \${1} is empty
  else
    sed -i "/\${1}/d" ~/.bashrc-${OCP_CLUSTER_ID}
    echo export \${1}=\"\${2}\" >> ~/.bashrc-${OCP_CLUSTER_ID}
source ~/.bashrc-${OCP_CLUSTER_ID}
echo \${1}="\${2}"
  fi
  echo ${VAR_NAME}
}
#######################################
EOF

source ~/.bashrc-${OCP_CLUSTER_ID}
setVAR OCP_MAJOR_VER 4.8
setVAR OCP_VER 4.8.24
setVAR RHCOS_VER 4.8.14


# 为集群添加用户
htpasswd -bBc users.htpasswd admin P@ssw0rd
oc create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config

cat << EOF | oc apply -f -
---
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd_provider 
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF

# 下面这个命令执行后，admin 用户看到的内容与 kubeadmin 不一样
# oc adm policy add-cluster-role-to-user cluster-admin admin --rolebinding-name=cluster-admin\
# 试试这条命令f
oc adm policy add-cluster-role-to-user cluster-admin admin
oc describe clusterrolebindings cluster-admin

# 参考 https://access.redhat.com/solutions/4878721 里的步骤
# 获取 sno certificate-authority
oc get pod -n openshift-authentication -o jsonpath='{range .items[*]}{@.metadata.name}{"\n\t"}{@.metadata.labels}{"\n"}{end}'
oc get pod -n openshift-authentication
NAME                               READY   STATUS    RESTARTS   AGE
oauth-openshift-854b6ddbc5-7fw2k   1/1     Running   0          9m38s

oc get pod -n openshift-authentication -o jsonpath='{range .items[*]}{@.metadata.name}{"\n\t"}{@.metadata.labels}{"\n"}{end}'
oauth-openshift-854b6ddbc5-7fw2k
        {"app":"oauth-openshift","oauth-openshift-anti-affinity":"true","pod-template-hash":"854b6ddbc5"}

oc get pod -n openshift-authentication -l app=oauth-openshift -o name

# extract the ingress-ca certificate
oc rsh -n openshift-authentication $(oc get pod -n openshift-authentication -l app=oauth-openshift -o name) cat /run/secrets/kubernetes.io/serviceaccount/ca.crt > ingress-ca.crt

cp ingress-ca.crt /etc/pki/ca-trust/source/anchors
update-ca-trust extract

# 用 admin 用户登陆
oc login https://api.${OCP_CLUSTER_ID}.${DOMAIN}:6443 -u admin -p P@ssw0rd

# 登出
oc logout 

# 重新使用 system:admin 登陆
oc login -u system:admin

# 查看 log 详情
oc --loglevel 6 get nodes

# 配置 chrony
timedatectl status | grep 'Time zone'
systemctl status chronyd
cp /etc/chrony.conf{,.bak}

sed -i -e "s/^server*/#&/g" \
       -e "s/#local stratum 10/local stratum 10/g" \
       -e "s/#allow 192.168.0.0\/16/allow all/g" \
       /etc/chrony.conf

cat >> /etc/chrony.conf << EOF
server 192.168.122.1 iburst
EOF

cat /etc/chrony.conf

systemctl enable --now chronyd

# 
https://docs.openshift.com/container-platform/4.9/openshift_images/configuring-samples-operator.html

cat > time.sync.conf << EOF
server 192.168.122.1 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 10
rtcsync
logdir /var/log/chrony
EOF

config_source=$(cat ./time.sync.conf | base64 -w 0 )

cat << EOF > ./99-master-zzz-chrony-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: masters-chrony-configuration
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 2.2.0
    networkd: {}
    passwd: {}
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${config_source}
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/chrony.conf
  osImageURL: ""
EOF

oc apply -f ./99-master-zzz-chrony-configuration.yaml

watch oc get mcp 

# 安装 nfs 服务 - 192.168.122.1
yum -y install nfs-utils
systemctl enable nfs-server --now
systemctl status nfs-server

export OCP_CLUSTER_ID='ocp4-1'
export NFS_OCP_REGISTRY_PATH=/root/jwang/ocp4-cluster/${OCP_CLUSTER_ID}/nfs/ocp-registry
export NFS_DOMAIN='192.168.122.1'
export OCP_REGISTRY_PV_NAME="pv-ocp-registry"
export OCP_REGISTRY_PVC_NAME="pvc-ocp-registry"

mkdir -p ${NFS_OCP_REGISTRY_PATH}
chown -R nfsnobody.nfsnobody ${NFS_OCP_REGISTRY_PATH}
# https://www.thegeeksearch.com/how-to-configure-selinux-labeled-nfs-exports/
# https://serverfault.com/questions/554659/selinux-contexts-with-nfs-shares
# https://github.com/sous-chefs/nfs/issues/91
chcon -Rv public_content_t ${NFS_OCP_REGISTRY_PATH}
chmod -R 777 ${NFS_OCP_REGISTRY_PATH}
echo ${NFS_OCP_REGISTRY_PATH} *'(rw,sync,no_wdelay,no_root_squash,insecure,fsid=0)' \
> /etc/exports.d/ocp-registry-${OCP_CLUSTER_ID}.exports
cat /etc/exports.d/ocp-registry-${OCP_CLUSTER_ID}.exports

# nfs status port 如何设置
cat > /etc/sysconfig/nfs <<EOF
MOUNTD_PORT="10050"
STATD_PORT="10051"
LOCKD_TCPPORT="10052"
LOCKD_UDPPORT="10052"
RQUOTAD_PORT="10053"
STATD_OUTGOING_PORT="10054"
EOF

systemctl restart nfs
systemctl restart rpc-statd

# Portmap ports
iptables -I INPUT 1 -m state --state NEW -p tcp --dport 111 -j ACCEPT
iptables -I INPUT -m state --state NEW -p udp --dport 111 -j ACCEPT
# NFS daemon ports
iptables -I INPUT 1 -m state --state NEW -p tcp --dport 2049 -j ACCEPT
iptables -I INPUT 1 -m state --state NEW -p udp --dport 2049 -j ACCEPT
# NFS mountd ports
iptables -I INPUT 1 -m state --state NEW -p udp --dport 10050 -j ACCEPT
iptables -I INPUT 1 -m state --state NEW -p tcp --dport 10050 -j ACCEPT
# NFS status ports
iptables -I INPUT 1 -m state --state NEW -p udp --dport 10051 -j ACCEPT
iptables -I INPUT 1 -m state --state NEW -p tcp --dport 10051 -j ACCEPT
# NFS lock manager ports
iptables -I INPUT 1 -m state --state NEW -p udp --dport 10052 -j ACCEPT
iptables -I INPUT 1 -m state --state NEW -p tcp --dport 10052 -j ACCEPT
# NFS rquotad ports
iptables -I INPUT 1 -m state --state NEW -p udp --dport 10053 -j ACCEPT
iptables -I INPUT 1 -m state --state NEW -p tcp --dport 10053 -j ACCEPT

# 创建 registry pv
cat << EOF | oc create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${OCP_REGISTRY_PV_NAME}
spec:
  capacity:
    storage: 100Gi 
  accessModes:
    - ReadWriteMany 
  persistentVolumeReclaimPolicy: Retain 
  nfs: 
    path: ${NFS_OCP_REGISTRY_PATH}
    server: ${NFS_DOMAIN}
    readOnly: false
EOF

cat << EOF | oc create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${OCP_REGISTRY_PVC_NAME}
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteMany      
  resources:
     requests:
       storage: 100Gi
EOF

# 8.3.3.4	指定内部镜像库使用PVC
oc patch configs.imageregistry.operator.openshift.io cluster --type merge \
  --patch '{"spec":{"storage":{"pvc":{"claim":"'${OCP_REGISTRY_PVC_NAME}'"}}}}'
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState": "Unmanaged"}}'
oc get configs.imageregistry.operator.openshift.io cluster -o json | jq -r '.spec |.managementState,.storage'
oc get pod -n openshift-image-registry

8.3.4	为应用使用的存储配置NFS StorageClass
export NFS_USER_FILE_PATH="/root/jwang/ocp4-cluster/${OCP_CLUSTER_ID}/nfs/userfile"
mkdir -p ${NFS_USER_FILE_PATH}
chown -R nfsnobody.nfsnobody ${NFS_USER_FILE_PATH}
chmod -R 777 ${NFS_USER_FILE_PATH}
echo ${NFS_USER_FILE_PATH} *'(rw,sync,no_wdelay,no_root_squash,insecure)' > /etc/exports.d/userfile-${OCP_CLUSTER_ID}.exports
exportfs -rav | grep userfile
showmount -e | grep userfile

# 创建本地 registry
# 参考 https://github.com/wangjun1974/ospinstall/blob/main/helper_registry.example.md
tar zxvf podman-docker-registry-v2.image.tgz 
podman load -i docker-registry

# 创建脚本
mkdir -p /opt/registry/{auth,certs,data}
cd /opt/registry/certs

# openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 3650 -out domain.crt -addext "subjectAltName = DNS:registry.ocp4-1.example.com" -subj "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT Department/CN=registry.ocp4-1.example.com"

openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 3650 -out domain.crt -subj "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT Department/CN=registry.ocp4-1.example.com"
cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

cat > /usr/local/bin/localregistry.sh << 'EOF'
#!/bin/bash
podman run --name poc-registry -d -p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
localhost/docker-registry:latest 
EOF

chmod +x /usr/local/bin/localregistry.sh
/usr/local/bin/localregistry.sh

# 编辑 /etc/dnsmasq.conf
# 添加 address=/registry.ocp4-1.example.com/192.168.122.1

curl https://registry.ocp4-1.example.com:5000/v2/_catalog

# 开放 container registry 所需防火墙端口
iptables -I INPUT 1 -m state --state NEW -p tcp --dport 5000 -j ACCEPT

8.3.4.2	创建NFS StorageClass部署配置

在线集群倒入 nfs 
https://www.ibm.com/support/pages/how-do-i-create-storage-class-nfs-dynamic-storage-provisioning-openshift-environment

# 创建几个文件
cat > /usr/local/src/nfs-provisioner-rbac.yaml <<EOF
kind: ServiceAccount
apiVersion: v1
metadata:
  name: nfs-client-provisioner
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: nfs-provisioner
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: nfs-provisioner
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
EOF

cat > /usr/local/src/nfs-provisioner-deployment.yaml <<EOF
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-client-provisioner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-client-provisioner
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: quay.io/external_storage/nfs-client-provisioner:latest
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: nfs-storage
            - name: NFS_SERVER
              value: 192.168.122.1
            - name: NFS_PATH
              value: ${NFS_USER_FILE_PATH}
      volumes:
        - name: nfs-client-root
          nfs:
            server: 192.168.122.1
            path: ${NFS_USER_FILE_PATH}
EOF

cat > /usr/local/src/nfs-provisioner-sc.yaml <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage-provisioner
provisioner: nfs-storage
parameters:
  archiveOnDelete: "false"
EOF

cat > /usr/local/bin/nfs-provisioner-setup.sh <<'EEEE'
#!/bin/bash
nfsnamespace=nfs-provisioner
rbac=/usr/local/src/nfs-provisioner-rbac.yaml
deploy=/usr/local/src/nfs-provisioner-deployment.yaml
sc=/usr/local/src/nfs-provisioner-sc.yaml
#
export PATH=/usr/local/bin:$PATH
#
## Check openshift connection
if ! oc get project default -o jsonpath={.metadata.name} > /dev/null 2>&1 ; then
        echo "ERROR: Cannot connect to OpenShift. Are you sure you exported your KUBECONFIG path and are admin?"
        echo ""  
        echo "...remember this is a POST INSTALL step."
        exit 254 
fi
#
## Check to see if the namespace exists
if [ "$(oc get project default -o jsonpath={.metadata.name})" = "${nfsnamespace}" ]; then
        echo "ERROR: Seems like NFS provisioner is already deployed"
        exit 254 
fi
#
## Check to see if important files are there
for file in ${rbac} ${deploy} ${sc}
do
        [[ ! -f ${file} ]] && echo "FATAL: File ${file} does not exist" && exit 254
done
#
## Check to see if the namespace exists
if [ "$(oc get project default -o jsonpath={.metadata.name})" = "${nfsnamespace}" ]; then
        echo "ERROR: Seems like NFS provisioner is already deployed"
        exit 254 
fi
#
## Check to see if important files are there
for file in ${rbac} ${deploy} ${sc}
do
        [[ ! -f ${file} ]] && echo "FATAL: File ${file} does not exist" && exit 254
done
#
## Check if the project is already there
if oc get project ${nfsnamespace} -o jsonpath={.metadata.name} > /dev/null 2>&1 ; then
        echo "ERROR: Looks like you've already deployed the nfs-provisioner"
        exit 254 
fi
#
## If we are here; I can try and deploy
oc new-project ${nfsnamespace}
oc project ${nfsnamespace}
oc create -f ${rbac}
oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:${nfsnamespace}:nfs-client-provisioner
oc create -f ${deploy} -n ${nfsnamespace}
oc create -f ${sc}
oc annotate storageclass nfs-storage-provisioner storageclass.kubernetes.io/is-default-class="true"
oc project default
oc rollout status deployment nfs-client-provisioner -n ${nfsnamespace}
#
## Show some info
cat <<EOF

Deployment started; you should monitor it with "oc get pods -n ${nfsnamespace}"

EOF
##
##
EEEE

/bin/bash -x /usr/local/bin/nfs-provisioner-setup.sh 

# nfs 报错
# 学习一下 cchen 写的 Assisted Installer 配置
# 其中为 image registry 配置 nfs 的步骤可以参考以下内容
# https://github.com/cchen666/OpenShift-Labs/blob/main/Installation/Assisted-Installer.md


$ mkdir -p /home/imagepv
$ chown nobody:nobody /home/imagepv
$ chmod 777 /home
$ chmod 777 /home/imagepv

cat >> /etc/exports <<EOF
/home/imagepv   *(rw,sync,no_wdelay,no_root_squash,insecure,fsid=0)
EOF




cat << EOF > pv.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    path: /home/imagepv
    server: 192.168.122.1

EOF

oc apply -f pv.yaml

$ oc edit configs.imageregistry.operator.openshift.io

  managementState: Managed   <--------
  observedConfig: null
  operatorLogLevel: Normal
  proxy: {}


  storage:
    managementState: Managed <--------
    pvc:                     <--------
      claim:                 <--------

$ oc new-app https://github.com/cchen666/openshift-flask
$ oc expose svc/openshift-flask
$ curl openshift-flask-test-1.apps.ocp4-1.example.com


$ mkdir -p /home/userfile
$ chown nobody:nobody /home/userfile
$ chmod 777 /home
$ chmod 777 /home/userfile

cat >> /etc/exports <<EOF
/home/userfile   *(rw,sync,no_wdelay,no_root_squash,insecure,fsid=0)
EOF

exportfs -rav 

# 登陆 sno: 手工登陆 quay.io
# 是不是没用我的 pull-secret
# 在手工下载镜像后
# 报错:E1217 09:40:42.606518       1 controller.go:1004] provision "openshift-image-registry/image-registry-storage" class "nfs-storage-provisioner": unexpected error getting claim reference: selfLink was empty, can't make reference
# 这个报错参考:
# https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/issues/25
# 应该按照：https://access.redhat.com/solutions/5685971 里给的方法修改


# https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner

# Step 2: Get the NFS Subdir External Provisioner files
$ git clone https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
$ cd nfs-subdir-external-provisioner

# Step 3: Setup authorization
$ oc project default
$ oc delete project nfs-provisioner 
$ oc new-project nfs-provisioner
$ NS=$(oc config get-contexts|grep -e "^\*" |awk '{print $5}')
$ NAMESPACE=${NS:-default}
$ sed -i'' "s/namespace:.*/namespace: $NAMESPACE/g" ./deploy/rbac.yaml ./deploy/deployment.yaml
$ oc create -f deploy/rbac.yaml
$ oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:$NAMESPACE:nfs-client-provisioner

Step 4: Configure the NFS subdir external provisioner
# 编辑 deploy/deployment.yaml
...
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: nfs-storage
            - name: NFS_SERVER
              value: 192.168.122.1
            - name: NFS_PATH
              value: /home/userfile
      volumes:
        - name: nfs-client-root
          nfs:
            server: 192.168.122.1
            path: /home/userfile

$ oc apply -f deploy/deployment.yaml

# 编辑 deploy/class.yaml
cat > deploy/class.yaml <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage-provisioner
provisioner: nfs-storage
parameters:
  pathPattern: ${.PVC.namespace}-${.PVC.name}
  archiveOnDelete: "false"
EOF

$ oc annotate storageclass nfs-storage-provisioner storageclass.kubernetes.io/is-default-class="true"
$ oc project default
$ oc rollout status deployment nfs-client-provisioner -n ${NAMESPACE}

$ cat > deploy/test-claim.yaml <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-claim
spec:
  storageClassName: nfs-storage-provisioner
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
EOF
$ oc create -f deploy/test-claim.yaml -f deploy/test-pod.yaml
$ oc delete -f deploy/test-claim.yaml -f deploy/test-pod.yaml

# 报错 Error writing blob: Error initiating layer upload to /v2/test4/openshift-flask/blobs/uploads/ in image-registry.openshift-image-registry.svc:5000: received unexpected HTTP status: 500 Internal Server Error


# 站点1 到 站点2 的 OCP 需求
# 1. 中心站点与边缘站点之间路由可达
# 2. 中心站点可解析边缘站点域名
# 3. 边缘站点可解析中心站点域名


```