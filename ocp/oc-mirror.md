# 如何用 oc-mirror 同步 openshift-release 和 operator 到目标集群

### Install oc-mirror on rhel7
https://asciinema.org/a/uToc11VnzG0RMZrht2dsaTfo9<br>
https://golangissues.com/issues/1156078<br>
```
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux 
source ~/.bash_profile
go version

git clone https://github.com/openshift/oc-mirror
cd oc-mirror
git checkout release-4.10

sh -x hack/build.sh 
cp ./bin/oc-mirror /usr/local/bin
```

### Install oc-mirror on rhel8
https://golangissues.com/issues/1156078<br>
```
yum groupinstall -y "Development Tools"

yum module list go-toolset
yum module -y install go-toolset

git clone https://github.com/openshift/oc-mirror
cd oc-mirror
git checkout release-4.10

make 
cp ./bin/oc-mirror /usr/local/bin

mkdir -p /data/OCP-4.9.9/ocp/ocp-image 

# 生成 image-config-realse-local.yaml 文件
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  ocp:
    channels:
      - name: stable-4.9
        versions:
          - '4.9.9'
          - '4.9.10'
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: local-storage-operator
        - name: openshift-gitops-operator
        - name: advanced-cluster-management
EOF
mkdir -p output-dir
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 生成 image-config-realse-local.yaml 文件
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  ocp:
    channels:
      - name: stable-4.9
        versions:
          - '4.9.9'
          - '4.9.18'
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
    - catalog: registry.redhat.io/redhat/certified-operator-index:v4.9
      headsOnly: false
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

```
