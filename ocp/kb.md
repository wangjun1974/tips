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
