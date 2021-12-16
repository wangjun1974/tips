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


```