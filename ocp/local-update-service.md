```
### 首先安装 cincinnati-operator
### https://coreos.slack.com/archives/CEGKQ43CP/p1624451445176500
### https://wangzheng422.github.io/docker_env/ocp4/4.8/4.8.update.service.html

### 添加本地 registry 证书信任
### 然后添加 configmap，configmap 的 key 需要是 updateservice-registry
$ CERTS_PATH="/data/registry/certs"
$ oc -n openshift-config create configmap trusted-ca --from-file=updateservice-registry=${CERTS_PATH}/registry.crt
### 设置 image.config.openshift.io/cluster 的 spec.additionalTrustedCA
$ oc patch image.config.openshift.io cluster --patch '{"spec":{"additionalTrustedCA":{"name":"trusted-ca"}}}' --type=merge
$ oc get image.config.openshift.io -o json  | jq -r '.items[].spec'

# 查看 updateService.yaml 
$ cat updateService.yaml
apiVersion: updateservice.operator.openshift.io/v1
kind: UpdateService
metadata:
  name: update-service-oc-mirror
  namespace: openshift-update-service # 注意添加namespace
spec:
  graphDataImage: registry.example.com:5000/openshift/graph-image@sha256:ce648ec0aac3bbd61ed6229564fbba01851bbdde3987ab6cdaec7951d8202ca6
  releases: registry.example.com:5000/openshift/release-images
  replicas: 1 # 默认为2，SNO 改为 1

$ oc apply -f updateService.yaml

# 更新 openshift-update-service namespace serviceaccount default 的 pull secret
$ cd ${OCP_PATH}/secret
$ oc -n openshift-update-service create secret generic cincinnati --from-file=.dockerconfigjson=redhat-pull-secret.json --type=kubernetes.io/dockerconfigjson
$ oc -n openshift-update-service patch sa default -p '{"imagePullSecrets": [{"name": "cincinnati"}]}'

# 删除并重建 update-service-oc-mirror pod
$ oc -n openshift-update-service delete $(oc get pods -n openshift-update-service -l app=update-service-oc-mirror -o name)

# 查看日志
$ oc -n openshift-update-service logs $(oc get pods -n openshift-update-service -l app=update-service-oc-mirror -o name) -c graph-builder

# 获取 route/update-service-oc-mirror-route 的 certificate
$ openssl s_client -host $(oc get route -n openshift-update-service update-service-oc-mirror-route -o jsonpath='{.spec.host}' ) -port 443 -showcerts > trace < /dev/null
$ cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee update-service.crt  
$ cat update-service.crt | sed -e 's|^|    |g'
    -----BEGIN CERTIFICATE-----
    MIIDaTCCAlGgAwIBAgIIUPWmfgMQ5igwDQYJKoZIhvcNAQELBQAwJjEkMCIGA1UE
    AwwbaW5ncmVzcy1vcGVyYXRvckAxNjYzMTQyMzg5MB4XDTIyMDkxNDA3NTk1N1oX
    DTI0MDkxMzA3NTk1OFowJDEiMCAGA1UEAwwZKi5hcHBzLm9jcDQtMS5leGFtcGxl
    LmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANBfyiH+JGw/YhCH
    2FyG6PBR6YKRf6mdYtOVpJQoUR544hmo3eidxu3I59GNIMMUhTXfRLvHKJHEjU9g
    KQpVHbzJh7i4C2RH7tewihrA6cneoXTw6LbGmBinvnhnc7ijc0I+OcWgufBhjlFE
    T1TgbaBgYiFFUfSrgHkx2JIlYnpeeY64+HGJZjxOXB8ylecyPaJORSi4WS+DcuYu
    UFnE5b6cLBWVES8QaVlvGFvupbAnPsYzcW0khwpfNWy8qyzCxAcptpmDt4DQTp9R
    w6LAk0l7BWsJ0WIf2mSp2hdxzWK5G0lU0nTdym78D+yOW4GmxsDMdCNsA3GQSzBy
    mj2ReIcCAwEAAaOBnDCBmTAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYB
    BQUHAwEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUhHWEYa0tkQ5m1VgIGsOwL5t2
    TwcwHwYDVR0jBBgwFoAU8Co7f0NtrdYtqRvPr+498KJHgg4wJAYDVR0RBB0wG4IZ
    Ki5hcHBzLm9jcDQtMS5leGFtcGxlLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAKvuu
    FuOGHYoPLhXYNV9eRcQXNWi8u/OBT+qAbhZ6R1Bs1kf6oOv1lMJfWfYsWFVkvCsh
    1x4YQaMUNE4RYXrVToGRC8NCYL+bh001sQvSlIMy4F3ycU2LGoJAZlbgG62+21zT
    FtVjCQGmIXXgI5MzyM2RDByXH/reyOpKktHNqa0kQuewtvWPR2C472aLe4TBkfk3
    8Lg6Y7S7jmUh2kuP0hqvBEhCiAsFBKyNyqQqQqfPT7bVNey+EzY0jb+84O4xHXP6
    nnvpoICf8AruAM7gRFh6+S2rDFoE95BI7mL1n/d8iCFampT/yQwlKfzMwgYWbmZD
    7MyOC08sYXvDvwmyAA==
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIDDDCCAfSgAwIBAgIBATANBgkqhkiG9w0BAQsFADAmMSQwIgYDVQQDDBtpbmdy
    ZXNzLW9wZXJhdG9yQDE2NjMxNDIzODkwHhcNMjIwOTE0MDc1OTQ4WhcNMjQwOTEz
    MDc1OTQ5WjAmMSQwIgYDVQQDDBtpbmdyZXNzLW9wZXJhdG9yQDE2NjMxNDIzODkw
    ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDitWPpBHZd9KCK7l+JZfYt
    U6s1XfbRUvLh9PJ+hQ5buFQH7WW6vvfXkfQctNYKgKWmQ4wmbbKfP1aAYGkQkiy/
    UfarDr6MNMGW3yS3KNhRGtGy7KBv29/sTBWJYRt6taOcu8x8L3Yc3Yj1+rPAkCuE
    tR933Q2R3PnNRRtJb1eo9kb0/QN2fbBAFuEDfEhdVasUgZ5su/bWaZET44/p2OZG
    GtvdI7ShE7PIQQJoC3P2yVOr85o4gHeTZ6K3c0sUtbPgx+wl5rNnfRIH5PSGcojR
    JkTTA0v8UziVTUPu+OQx1cbV1SxTEL3URcrODyhWJYlEGkJ0X19MEYzE/Qv96hjh
    AgMBAAGjRTBDMA4GA1UdDwEB/wQEAwICpDASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
    A1UdDgQWBBTwKjt/Q22t1i2pG8+v7j3wokeCDjANBgkqhkiG9w0BAQsFAAOCAQEA
    1ZQHXzmlL/3Bw1H3JpClHYzhfAZTZx+gmbDd6EC7xhJgkdjAx+JTSLf0fCH0GTaf
    GNKyCWKNRfTtB9jFvGXwmcps0WA0tOVY1Tbsf+/5BgV9af1d8GAnJSKHqlnZeEuj
    13RoVKGMA3la3XtysGVxoMSK5LrtmYc//cjBGb4lTO0/XaLi+E5S+Pu8Ufs6hREB
    Gp36N+hByqv/I1oM6/F2V8ayl65G+lhPAOSGyd5etKKVU4HQnTUqaw7qD/c5Wrin
    tE6FJApsbqoJ4r86HIJEEnAOJAUzb4kPa85h4VmKrEYeRm6idx7LuvJ9cg8H4fVh
    wKVBAtH4TPrKz5hnjCxztA==
    -----END CERTIFICATE-----

# 将这部分内容添加到 openshift-config namespace 下的 configmap user-ca-bundle 里
$ oc -n openshift-config edit configmap user-ca-bundle

# 添加 proxy.config.openshift.io/cluster 的 spec.trustedCA 
$ oc patch proxy.config.openshift.io/cluster -p '{"spec":{"trustedCA":{"name":"user-ca-bundle"}}}'  --type=merge

# 更新 clusterversion/version 的 spec.upstream
$ NAMESPACE=openshift-update-service
$ NAME=update-service-oc-mirror
$ POLICY_ENGINE_GRAPH_URI="$(oc -n "${NAMESPACE}" get -o jsonpath='{.status.policyEngineURI}/api/upgrades_info/v1/graph{"\n"}' updateservice "${NAME}")"
$ PATCH="{\"spec\":{\"upstream\":\"${POLICY_ENGINE_GRAPH_URI}\"}}"
$ oc patch clusterversion version -p $PATCH --type merge

# (如果想改回去的话) 改回默认的 GRAPH_URL
$ POLICY_ENGINE_GRAPH_URI="https://api.openshift.com/api/upgrades_info/v1/graph"
$ PATCH="{\"spec\":{\"upstream\":\"${POLICY_ENGINE_GRAPH_URI}\"}}"
$ oc patch clusterversion version -p $PATCH --type merge

# 查看 clusterversion 对象
$ oc get clusterversion version -o yaml 

# 如果上述命令输出无报错，这个时候就可以在界面执行更新了
```