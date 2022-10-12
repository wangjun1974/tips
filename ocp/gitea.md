```
### Gitea Operator
### skopeo 保存镜像到本地目录
mkdir -p /tmp/gitea
skopeo copy --format v2s2 --all docker://registry.redhat.io/openshift4/ose-kube-rbac-proxy:v4.7.0 dir:/tmp/gitea/ose-kube-rbac-proxy
skopeo copy --format v2s2 --all docker://quay.io/gpte-devops-automation/gitea-operator:v1.3.0 dir:/tmp/gitea/gitea-operator
skopeo copy --format v2s2 --all docker://registry.redhat.io/rhel8/postgresql-12:latest dir:/tmp/gitea/postgresql-12
skopeo copy --format v2s2 --all docker://quay.io/gpte-devops-automation/gitea:latest dir:/tmp/gitea/gitea

### gitea-operator.tar 下载地址
### 链接: https://pan.baidu.com/s/1rANwTnP7NBaAz4dPdW9C_A?pwd=zk4h 提取码: zk4h 
### 拷贝 gitea-operator.tar 到离线环境，解压缩
tar cf /tmp/gitea-operator.tar /tmp/gitea
scp /tmp/gitea-operator.tar <dest>:/tmp
tar xf /tmp/gitea-operator.tar -C /

### 上传镜像到本地 registry
skopeo copy --format v2s2 --all dir:/tmp/gitea/ose-kube-rbac-proxy docker://registry.example.com:5000/openshift4/ose-kube-rbac-proxy:v4.7.0
skopeo copy --format v2s2 --all dir:/tmp/gitea/gitea-operator docker://registry.example.com:5000/gpte-devops-automation/gitea-operator:v1.3.0
skopeo copy --format v2s2 --all dir:/tmp/gitea/postgresql-12 docker://registry.example.com:5000/rhel8/postgresql-12:latest
skopeo copy --format v2s2 --all dir:/tmp/gitea/gitea docker://registry.example.com:5000/gpte-devops-automation/gitea:latest

### 生成 /etc/containers/registries.conf.d/99-master-mirror-by-digest-registries.conf 的 machineconfig
### 同时把 book-import 的镜像也考虑进去
### 同时把 gitops-wordpress 的镜像也考虑进去
cd /tmp
cat > my_registry.conf <<EOF
[[registry]]
  prefix = ""
  location = "quay.io/gpte-devops-automation"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/gpte-devops-automation"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/openshift4"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/openshift4"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhel8"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/rhel8"

[[registry]]
  prefix = ""
  location = "quay.io/jpacker"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/jpacker"

[[registry]]
  prefix = ""
  location = "docker.io/bitnami"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/bitnami"

[[registry]]
  prefix = ""
  location = "docker.io/minio"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/minio"
EOF

cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-mirror-by-digest-registries
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(base64 -w0 my_registry.conf)
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf.d/99-master-mirror-by-digest-registries.conf
EOF

#### 下载 gitea-catalog_latest_gitea-operator_v1.3.0.tar
#### 链接: https://pan.baidu.com/s/1Pv9O-UT0iX7UAFD7yfQypA?pwd=9xvs 提取码: 9xvs
#### 同步 gitea 到本地 registry
$ oc-mirror --from /tmp/gitea-catalog_latest_gitea-operator_v1.3.0.tar docker://registry.example.com:5000
$ oc apply -f results-1665187775/catalogSource-gitea-catalog.yaml

# 设置 default storage class
oc patch storageclass odf-lvm-vg1 -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'

# 创建 Gitea 实例
cat <<EOF | oc apply -f -
apiVersion: gpte.opentlc.com/v1
kind: Gitea
metadata:
  name: gitea-with-admin
  namespace: openshift-operators
spec:
  giteaSsl: true
  giteaAdminUser: opentlc-mgr
  giteaAdminPassword: ""
  giteaAdminPasswordLength: 32
  giteaAdminEmail: opentlc-mgr@redhat.com
  giteaCreateUsers: true
  giteaGenerateUserFormat: "lab-user-%d"
  giteaUserNumber: 2
  giteaUserPassword: openshift
  giteaMigrateRepositories: false
EOF

# 查看 Gitea 日志
oc -n openshift-operators logs $(oc -n openshift-operators get pods -l control-plane=controller-manager -o name | grep gitea) -c manager 

# 拷贝 quay.io/jpacker/hugo-nginx:latest 镜像
### 链接: https://pan.baidu.com/s/1fYPQv76D9WKvlyHa-KcrlQ?pwd=j9gx 提取码: j9gx
mkdir -p /tmp/book-import
skopeo copy --format v2s2 --all docker://quay.io/jpacker/hugo-nginx:latest dir:/tmp/book-import/hugo-nginx

tar cf /tmp/book-import.tar /tmp/book-import
scp /tmp/book-import.tar <dest>:/tmp
tar xf /tmp/book-import.tar -C /

skopeo copy --format v2s2 --all dir:/tmp/book-import/hugo-nginx docker://registry.example.com:5000/jpacker/hugo-nginx:latest

# 处理证书信任
cd /tmp
openssl s_client -host gitea-with-admin-openshift-operators.apps.ocp4-1.example.com -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /etc/pki/ca-trust/source/anchors/gitea.crt  
update-ca-trust
cd -

# 克隆仓库或者直接使用网盘上的文件 git-book-import.tar.gz
# 链接: https://pan.baidu.com/s/1FEi8xBzBqBzGd4-yNSy94w?pwd=ieba 提取码: ieba
# git clone https://github.com/wangjun1974/book-import
# 传输 book-import 到离线环境
# 进入到 book-import 目录

# 在 Gitea UI 上以 lab-user-2 身份登陆 https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com 创建 book-import 仓库
# 在 book-import 目录内添加 neworigin
# git remote add neworigin https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/book-import.git

# 将 repo 从文件系统同步到 gitea
# git push neworigin --all
# git push neworigin --tags

# gitops-wordpress 镜像
# 拷贝 docker.io/bitnami/mysql:8.0 镜像
# 拷贝 docker.io/bitnami/wordpress:6 镜像
mkdir -p /tmp/bitnami
skopeo copy --format v2s2 --all docker://docker.io/bitnami/mysql:8.0 dir:/tmp/bitnami/mysql
skopeo copy --format v2s2 --all docker://docker.io/bitnami/wordpress:6 dir:/tmp/bitnami/wordpress

tar cf /tmp/bitnami-wordpress.tar /tmp/bitnami
scp /tmp/bitnami-wordpress.tar <dest>:/tmp
tar xf /tmp/bitnami-wordpress.tar -C /

skopeo copy --format v2s2 --all dir:/tmp/bitnami/mysql docker://registry.example.com:5000/bitnami/mysql:8.0
skopeo copy --format v2s2 --all dir:/tmp/bitnami/wordpress docker://registry.example.com:5000/bitnami/wordpress:6

# 克隆仓库或者直接使用网盘上的文件 git-gitops-wordpress.tar.gz
# 链接: 链接: https://pan.baidu.com/s/1lf0ROH921cSIqzAXYuYqKw?pwd=kge5 提取码: kge5
# git clone https://github.com/wangjun1974/gitops-wordpress
# 传输 gitops-wordpress 到离线环境
# 进入到 gitops-wordpress 目录

# 在 Gitea UI 上以 lab-user-2 身份登陆 https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com 创建 gitops-wordpress 仓库
# 在 gitops-wordpress 目录内添加 neworigin
# git remote add neworigin https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/gitops-wordpress.git
# 将 repo 从文件系统同步到 gitea
# git push neworigin --all
# git push neworigin --tags
```