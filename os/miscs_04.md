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
```