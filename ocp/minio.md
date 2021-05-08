参考：<br>
https://mykidong.medium.com/secure-minio-not-on-kubernetes-46dd90ccb1c<br>
https://stash.run/docs/0.7.0-rc.0/guides/minio_server/<br>
```
# 安装 onessl
curl -fsSL -o onessl https://github.com/appscode/onessl/releases/download/0.1.0/onessl-linux-amd64 \
  && chmod +x onessl \
  && sudo mv onessl /usr/local/bin/

# 生成 ca.crt 和 ca.key
onessl create ca-cert

# 生成 server cert 
# 根据需要替换 --domains 后面的域名
onessl create server-cert --domains minio-velero.apps.ocp1.rhcnsa.com

# 生成 public.crt 和 private.key
cat {server.crt,ca.crt} > public.crt
cat server.key > private.key

# 创建 minio-server-secret
# 为 minio-server-secret 打标签
oc project velero
oc create secret generic minio-server-secret --from-file=./public.crt --from-file=./private.key
oc label secret minio-server-secret app=minio -n velero

# 创建 pvc minio-pvc 
cat > minio-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  # This name uniquely identifies the PVC. Will be used in minio deployment.
  name: minio-pvc
  labels:
    app: minio
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    # This is the request for storage. Should be available in the cluster.
    requests:
      storage: 2Gi
EOF
oc apply -f ./minio-pvc.yaml 

# 根据 velero 项目里的例子创建 minio Deployment
# 参考：https://canlogger.csselectronics.com/canedge-getting-started/transfer-data/s3-server/https/
# 根据需要设置 MINIO_SECRET_KEY
cat > minio-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  # This name uniquely identifies the Deployment
  name: minio
  labels:
    app: minio
spec:
  strategy:
    type: Recreate # If pod fail, we want to recreate pod rather than restarting it.
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        # Label is used as a selector in the service.
        app: minio
    spec:
      volumes:
      # Refer to the PVC have created earlier
      - name: storage
        persistentVolumeClaim:
          # Name of the PVC created earlier
          claimName: minio-pvc
      # Refer to minio-server-secret we have created earlier
      - name: minio-server-secret
        secret:
          secretName: minio-server-secret
          items:
          - key: public.crt
            path: public.crt
          - key: private.key
            path: private.key
          - key: public.crt
            path: CAs/public.crt       
      containers:
      - name: minio
        # Pulls the default Minio image from Docker Hub
        image: minio/minio:latest
        imagePullPolicy: IfNotPresent
        args:
        - server
        - --address
        - ":9443"
        - --certs-dir
        - "${HOME}/.minio/certs"     
        - /storage
        env:
        # Minio access key and secret key
        - name: MINIO_ACCESS_KEY
          value: "minio"
        - name: MINIO_SECRET_KEY
          value: "<your minio secret key(any string)>"
        ports:
        - containerPort: 9443
        # Mount the volumes into the pod
        volumeMounts:
        - name: storage # must match the volume name, above
          mountPath: "/storage"
        - name: minio-server-secret
          mountPath: "${HOME}/.minio/certs/" # directory where the certificates will be mounted
EOF
oc apply -f ./minio-deployment.yaml

# 创建 service minio
# 根据需要调整 namespace
cat > minio-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  namespace: velero
  name: minio
  labels:
    app: minio
spec:
  # ClusterIP is recommended for production environments.
  # Change to NodePort if needed per documentation,
  # but only if you run Minio in a test/trial environment, for example with Minikube.
  type: ClusterIP
  ports:
    - port: 9443
      targetPort: 9443
      protocol: TCP
  selector:
    app: minio
EOF
oc apply -f ./minio-service.yaml 

# 创建 route minio
# 根据需要调整 namespace
cat > minio-route.yaml << EOF
apiVersion: v1
kind: Route
metadata:
  name: minio
  namespace: velero
  labels:
    app: minio
spec:
  host: minio-velero.apps.ocp1.rhcnsa.com
  port:
    targetPort: 9443
  to:
    kind: Service
    name: minio
  tls:
    termination: passthrough    
EOF
oc apply -f ./minio-route.yaml

# 配置 minio
# 下载客户端 mc client
wget https://dl.min.io/client/mc/release/linux-amd64/mc -P /usr/local/bin
chmod +x /usr/local/bin/mc

# minio 添加 host velero
/usr/local/bin/mc --insecure config host add velero $(oc get route minio -o jsonpath='https://{.spec.host}') minio minio123123

# 创建 bucket velero
/usr/local/bin/mc --insecure mb -p velero/velero
```