### 集成 RHSSO 与 OpenShift 4
https://blog.csdn.net/weixin_43902588/article/details/105303056<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1951812<br> 
```
# 创建 rhsso namespace
# 安装 RHSSO Operator
# 不要用 default namespace 安装 rhsso

# 创建新 Realm -> openshift
# 获取并记录 issuer url
Issuer URL
https://keycloak-rhsso.apps.cluster-n7bsm.n7bsm.sandbox1648.opentlc.com/auth/realms/openshift
https://keycloak-rhsso.apps.cluster-htm2s.htm2s.sandbox1062.opentlc.com/auth/realms/openshift

# 创建 Client 
# Valid Redirect URs 可设置为 https://*
# 可以更新 Valid Redirect URs 为 https://oauth-openshift.apps.<base-domain>/oauth2callback/<idp>
Add Client -> openshift 
Client Setting
  Access Type -> confendial
  Valid Redirect URs -> https://*
  Valid Redirect URs -> https://oauth-openshift.apps.cluster-n7bsm.n7bsm.sandbox1648.opentlc.com/oauth2callback/rhsso
  Valid Redirect URs -> https://oauth-openshift.apps.cluster-htm2s.htm2s.sandbox1062.opentlc.com/oauth2callback/rhsso

# 记录 Client Credentials
Client Credentials
  Secret -> b2f3f4e1-d6c1-4f68-a393-0ff735d33d16
  Secret -> ae76648f-273e-4edf-8f1d-daf27a6d8661

# 添加用户
# 设置用户口令

# 获取 keycloak 证书
K_ROUTE=$(oc -n rhsso get route keycloak -o jsonpath='{.spec.host}')
openssl s_client -host ${K_ROUTE} -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee k.crt 

Administration
  Cluster Setting -> Configuration -> OAuth -> Add -> OpenID Connect
  Add Indentity Provider：OpenID Connect -> 
  Name -> rhsso
  Client ID -> openshift
  Client Secret -> ae76648f-273e-4edf-8f1d-daf27a6d8661
  Issuer URL -> https://keycloak-rhsso.apps.cluster-htm2s.htm2s.sandbox1062.opentlc.com/auth/realms/openshift
  CA File -> k.crt
 
# 查询 identityProviders
oc get oauth/cluster -o yaml | yq eval '.spec.identityProviders[].name' -

# 查看 openshift-authentication-operator 日志
oc -n openshift-authentication-operator logs $(oc -n openshift-authentication-operator get pods -l app=authentication-operator -o name | head -1 )

# 在 RHPDS 下，证书不是 router ingress 证书
# 而是 Let's Encrypt 证书
# 这段证书检查内容对 RHPDS 下的环境不适用，请跳到获取 keycloak 证书部分
$ oc get cm/router-ca -n openshift-config-managed -o jsonpath='{.data.ca\-bundle\.crt}' ｜ tee ca.crt

# 检查 ca.crt 的 issuer 信息
$ openssl x509 -in ca.crt  -noout -subject -issuer 

# 检查 certs 的 subject 与 issuer
$ echo | openssl s_client -connect keycloak-keycloak.apps.cluster-jw9b2.jw9b2.sandbox840.opentlc.com:443 -showcerts
$ echo | openssl s_client -connect $(oc -n rhsso get route keycloak -o jsonpath='{.spec.host}{":443"}') -showcerts

# 获取 keycloak 证书
K_ROUTE=$(oc -n rhsso get route keycloak -o jsonpath='{.spec.host}')
openssl s_client -host ${K_ROUTE} -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee k.crt  
# 配置 idp 指定证书时用 k.crt 作为 CA 证书

# 用 idp user 登陆 openshift
# 获取 idp user 信息
$ oc get identity
NAME                                          IDP NAME            IDP USER NAME                          USER NAME     USER UID
htpasswd_provider:opentlc-mgr                 htpasswd_provider   opentlc-mgr                            opentlc-mgr   6307e6b0-6a31-48fe-ae46-0e530a6def14
openid:d7264511-5b7d-4b4b-b3b1-7ad23e9519a6   openid              d7264511-5b7d-4b4b-b3b1-7ad23e9519a6   testuser      083a4068-223b-43ff-b12e-3f30bc7f2c48

# 为 idp 用户 testuser 设置 cluster-admin clusterrole
$ oc create clusterrolebinding add-cluster-admin-to-openid-testuser --clusterrole=cluster-admin --user=testuser
clusterrolebinding.rbac.authorization.k8s.io/add-cluster-admin-to-openid-testuser created

```