### ODF as object storage of ACM Observability 
```
$ oc project openshift-storage
$ cat <<EOF | oc apply -f -
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: obc-aws
spec:
  bucketName: obc-aws
  storageClassName: openshift-storage.noobaa.io
  additionalConfig:
    bucketclass: noobaa-default-bucket-class
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: thanos-object-storage
  namespace: open-cluster-management-observability
type: Opaque
stringData:
  thanos.yaml: |
    type: s3
    config:
      bucket: $(oc -n openshift-storage get objectbucket obc-openshift-storage-obc-aws -o jsonpath='{.spec.endpoint.bucketName}')
      endpoint: $(oc -n openshift-storage get objectbucket obc-openshift-storage-obc-aws -o jsonpath='{.spec.endpoint.bucketHost}')
      access_key: $(oc -n openshift-storage get secret obc-aws -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d)
      secret_key: $(oc -n openshift-storage get secret obc-aws -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d)
      http_config:
        insecure_skip_verify: true
EOF
```