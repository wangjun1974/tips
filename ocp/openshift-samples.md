
### 参考知识库文档
https://access.redhat.com/solutions/5067531

### 在本地同步 openshift-samples operator 所需的镜像
```
# 生成所需同步的镜像列表
for i in `oc get is -n openshift --no-headers | awk '{print $1}'`; do oc get is $i -n openshift -o json | jq .spec.tags[].from.name | grep registry.redhat.io | sed -e 's/"//g' | cut -d"/" -f2-; done | tee /tmp/samples-imagelist.txt

# 同步镜像到本地
export LOCAL_SECRET_JSON="${HOME}/pull-secret-2.json"
export LOCAL_REGISTRY='helper.cluster-0001.rhsacn.org:5000'

for i in `cat /tmp/samples-imagelist.txt`; do oc image mirror -a ${LOCAL_SECRET_JSON} registry.redhat.io/$i ${LOCAL_REGISTRY}/$i; done
```