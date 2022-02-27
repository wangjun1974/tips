### image-registry operator 报 Degraded: The registry is removed...
https://access.redhat.com/solutions/5370391
```
oc get clusteroperators image-registry -o yaml 
  - lastTransitionTime: "2022-02-21T03:08:46Z"
    message: |-
      Degraded: The registry is removed
      ImagePrunerDegraded: Job has reached the specified backoff limit
    reason: ImagePrunerJobFailed::Removed
    status: "True"
    type: Degraded
# 解决方案
# https://access.redhat.com/solutions/5370391
# oc patch imagepruner.imageregistry/cluster --patch '{"spec":{"suspend":true}}' --type=merge
# oc -n openshift-image-registry delete jobs --all
```

# Invalid GPG signature for image certified-operator-index, redhat-marketplace-index, community-operator-index
https://access.redhat.com/solutions/6542281
```
1. 保存 /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv 文件
curl -s -o /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv https://www.redhat.com/security/data/55A34A82.txt
2. 保存 /etc/containers/policy.json 文件
cat > /etc/containers/policy.json <<EOF
{
  "default": [
      {
          "type": "insecureAcceptAnything"
      }
  ],
  "transports":
    {
      "docker-daemon":
          {
              "": [{"type":"insecureAcceptAnything"}]
          },
      "docker":
        {
          "registry.redhat.io/redhat/certified-operator-index": [
            {
              "type": "signedBy",
              "keyType": "GPGKeys",
              "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv"
            }
          ],
          "registry.redhat.io/redhat/community-operator-index": [
            {
              "type": "insecureAcceptAnything"
            }
          ],
          "registry.redhat.io/redhat/redhat-marketplace-index": [
            {
              "type": "signedBy",
              "keyType": "GPGKeys",
              "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv"
            }
          ],
          "registry.access.redhat.com": [
            {
              "type": "signedBy",
              "keyType": "GPGKeys",
              "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
            }
          ],
          "registry.redhat.io": [
            {
              "type": "signedBy",
              "keyType": "GPGKeys",
              "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
            }
          ]
        }
    }
}
EOF
```