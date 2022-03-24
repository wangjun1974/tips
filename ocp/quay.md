### Deploying the Operator using the initial configuration
https://docs.projectquay.io/deploy_quay_on_openshift_op_tng.html#operator-preconfigure

### Use Project Quay
https://docs.projectquay.io/use_quay.html#user-create

```
DEBUGLOG=true
```

```
DEBUGLOG=true
DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
  default:
  - RadosGWStorage
  - access_key: minio
    secret_key: minioredhat123
    hostname: minio-velero.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com
    bucket_name: quay
    port: 80
    is_secure: false
    storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE: [default]
FEATURE_USER_INITIALIZE: true
FEATURE_USER_CREATION: true
SUPER_USERS:
- quayadmin
```