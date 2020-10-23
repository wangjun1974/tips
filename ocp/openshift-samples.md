
### 参考知识库文档
https://access.redhat.com/solutions/5067531

### 设置 cluster-samples 指向本地镜像仓库
```
# 生成所需同步的镜像列表
for i in `oc get is -n openshift --no-headers | awk '{print $1}'`; do oc get is $i -n openshift -o json | jq .spec.tags[].from.name | grep registry.redhat.io | sed -e 's/"//g' | cut -d"/" -f2-; done | tee /tmp/samples-imagelist.txt

# 同步镜像到本地
export LOCAL_SECRET_JSON="${HOME}/pull-secret-2.json"
export LOCAL_REGISTRY='helper.cluster-0001.rhsacn.org:5000'

for i in `cat /tmp/samples-imagelist.txt`; do oc image mirror -a ${LOCAL_SECRET_JSON} registry.redhat.io/$i ${LOCAL_REGISTRY}/$i; done

# 如果希望略过某些 imagestream，可以修改 skippedImagestreams （可选）
oc patch configs.samples.operator.openshift.io/cluster --patch '{"spec":{"skippedImagestreams":["jenkins", "jenkins-agent-maven", "jenkins-agent-nodejs"]}}' --type=merge

# 为 cluster image object 添加 additionalTrustedCA (可选，有可能在安装时已完成此配置）
$ oc create configmap registry-config --from-file=${MIRROR_ADDR_HOSTNAME}..5000=$path/ca.crt -n openshift-config
$ oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge

# 设置 openshift-samples operator 的对象的 spec samplesRegistry，指向本地镜像仓库 
oc patch configs.samples.operator.openshift.io/cluster --patch '{"spec":{"samplesRegistry": "helper.cluster-0001.rhsacn.org:5000" }}' --type=merge

# 当 samplesRegistry spec 被修改，将触发导入过程，如果此过程未发生，则可执行以下命令触发导入过程（可选）
$ oc patch configs.samples.operator.openshift.io/cluster --patch '{"spec":{"managementState": "Removed" }}' --type merge
### 等待几秒钟 ###
$ oc patch configs.samples.operator.openshift.io/cluster --patch '{"spec":{"managementState": "Managed" }}' --type merge



```