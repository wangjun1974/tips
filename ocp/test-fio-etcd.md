### etcd 对存储有要求
etcd 使用 write ahead log ，对存储有要求，要求 99% 的 fdatasync 操作在 10 ms 里完成 <br>
参见：<br>
https://www.ibm.com/cloud/blog/using-fio-to-tell-whether-your-storage-is-fast-enough-for-etcd <br>
https://gist.github.com/acsulli/2d500e2489babea83843e1edd27a118e<br>

在 openshift 里如何使用 fio 测试 fdatasync 的例子
```
cat << EOF | oc create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fio-test
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  replicas: 1
  selector:
    matchLabels:
      app: fio-test
  template:
    metadata:
      labels:
        app: fio-test
    spec:
      containers:
      - name: fio-container
        image: wallnerryan/fiotools-aio
        ports:
        - containerPort: 8000
        env:
          - name: REMOTEFILES
            value: "https://gist.githubusercontent.com/acsulli/2c7c71594c16273a2cf087963c339568/raw/fd7d07f3dac3e4923a3c08c6d60b03b0e0b63c65/etcd.fio"
          - name: JOBFILES
            value: etcd.fio
          - name: PLOTNAME
            value: etcdtest
---
apiVersion: v1
kind: Service
metadata:
  name: fiotools-etcd
  labels:
    name: fiotools-etcd
spec:
  type: NodePort
  ports:
    - port: 8000
      targetPort: 8000
      name: http
  selector:
    app: fio-test
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: fiotools-etcd
  labels:
    name: fiotools-etcd
spec:
  port:
    targetPort: http
  to:
    kind: Service
    name: fiotools-etcd
    weight: 100
EOF
```