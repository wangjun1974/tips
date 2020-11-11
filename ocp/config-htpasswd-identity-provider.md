### 添加 htpasswd identity provider 的步骤
参考：https://docs.openshift.com/container-platform/4.1/authentication/identity_providers/configuring-htpasswd-identity-provider.html
```
# 创建 htpasswd 文件，添加用户 admin, user01 和 user02
htpasswd -c -B -b /root/ocp4/users.htpasswd admin admin
htpasswd -b /root/ocp4/users.htpasswd user01 redhat
htpasswd -b /root/ocp4/users.htpasswd user02 redhat

# 使用 htpasswd 文件创建 secret htpass-secret
oc create secret generic htpass-secret --from-file=htpasswd=/root/ocp4/users.htpasswd -n openshift-config

# 为 oauth.config.openshift.io/cluster 添加 htpasswd identity provider
cat <<EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: my_htpasswd_provider 
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret 
EOF

# 为 admin 用户添加 role system:image-builder
# 为 admin 用户添加 openshift namespace 的 role admin
# 为 admin 用户添加 cluster role admin
# 为 admin 用户添加 cluster role cluster-admin
# 为 user01 用户添加 role self-provisioner
# 为 user02 用户添加 role self-provisioner
oc login -u system:admin
oc adm policy add-role-to-user system:image-builder admin
oc adm policy add-role-to-user admin admin -n openshift
oc adm policy add-cluster-role-to-user admin admin
oc adm policy add-cluster-role-to-user cluster-admin admin
oc adm policy add-role-to-user self-provisioner user01
oc adm policy add-role-to-user self-provisioner user02

```