### Externaldns 与 Bind 集成

### 配置 Bind 支持 zone rfc2136 动态更新

```
# 创建生成用于保护 zone 或 rndc command channel 的动态 DNS 更新的密钥
$ tsig-keygen -a hmac-sha256 externaldns
key "externaldns" {
        algorithm hmac-sha256;
        secret "xxxxxxx";
};

# 将 内容保存在 /var/named/keys/externaldns-key.key 文件里 
$ mkdir -p /var/named/keys/
$ cat > /var/named/keys/externaldns-key.key <<EOF
key "externaldns" {
        algorithm hmac-sha256;
        secret "xxxxxxx";
};
EOF
$ chown root:named /var/named/keys/externaldns-key.key
$ chmod 640 /var/named/keys/externaldns-key.key

# 创建 Bind 下用来实现 RFC 2136 动态更新的配置文件 - /var/named/keys/dns-rfc2136.ini
$ cat <<EOF > /var/named/keys/dns-rfc2136.ini
dns_rfc2136_server = 192.168.56.64
dns_rfc2136_port = 53
dns_rfc2136_name = externaldns.
dns_rfc2136_secret = xxxxxxx
dns_rfc2136_algorithm = HMAC-SHA256
EOF
$ chown root:named /var/named/keys/dns-rfc2136.ini
$ chmod 640 /var/named/keys/dns-rfc2136.ini

# 根据 Bind 的实际情况生成 k8s.ocp4.example.com.db 内容
# 添加 zonefile; 更新 /etc/named.conf 配置
$ cat > /var/named/data/k8s.ocp4.example.com.db <<'EOF'
$ORIGIN k8s.ocp4.example.com.
$TTL 1D
@           IN SOA  k8s.ocp4.example.com. admin.k8s.ocp4.example.com. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum

@             IN NS                         ns1.ocp4.example.com.
EOF

$ cat /var/named.conf | tail -15
########### Add what's between these comments ###########
include "/var/named/keys/externaldns-key.key";
zone "k8s.ocp4.example.com" IN {
        type master;
        file "data/k8s.ocp4.example.com.db";
        allow-transfer {
          key "externaldns";
        };
        update-policy {
          grant externaldns zonesub ANY;
        };
};
########################################################
include "/etc/named.root.key";

$ rndc reload

# 测试域名可动态更新
$ nsupdate -k /var/named/keys/externaldns-key.key
> server 192.168.56.64
> update add www1.k8s.example.com 86400 a 192.168.122.69
> send

$ dig +short www1.k8s.ocp4.example.com.
192.168.122.69
```

### 在 OpenShift 集群里配置 ExternalDNS 集成 Bind RFC 2136
```
# 创建 namespace
$ oc new-project external-dns
$ oc label namespace external-dns pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged --overwrite=true security.openshift.io/scc.podSecurityLabelSync=false 

# 创建 ServiceAccount, ClusterRole, ClusterRoleBinding
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  namespace: external-dns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
rules:
- apiGroups: [""]
  resources: ["services","endpoints","pods"]
  verbs: ["get","watch","list"]
- apiGroups: ["extensions","networking.k8s.io"]
  resources: ["ingresses"] 
  verbs: ["get","watch","list"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: external-dns

# 创建 externaldns 的 deployment
---  
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: external-dns
spec:
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: registry.ocp4.example.com/smileyfritz/edo/external-dns-rhel8:1.2.0-2
        args:
        - --log-level=debug
        - --registry=txt
        - --txt-prefix=external-dns-
        - --txt-owner-id=k8s
        - --provider=rfc2136
        - --rfc2136-host=192.168.56.64
        - --rfc2136-port=53
        - --rfc2136-zone=k8s.ocp4.example.com
        - --rfc2136-tsig-secret=xxxxxxx
        - --rfc2136-tsig-secret-alg=hmac-sha256
        - --rfc2136-tsig-keyname=externaldns
        - --rfc2136-tsig-axfr
        - --source=service
        - --domain-filter=k8s.ocp4.example.com

$ oc get sa -n external-dns 
NAME           SECRETS   AGE
builder        1         5d20h
default        1         5d20h
deployer       1         5d20h
external-dns   1         5d19h

$  oc get deployment -n external-dns 
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
external-dns   1/1     1            1           5d19h
```

# 创建 headless service
```
# 定义 redis headless service ksvc
# clusterIP 为 None
# hostPort 为 6379
# service有2个 annotation
# external-dns.alpha.kubernetes.io/hostname 定义可动态更新的 zone
# external-dns.alpha.kubernetes.io/endpoints-type 定义域名解析的IP对应节点的 HostIP
---
apiVersion: v1
kind: Service
metadata:
  name: ksvc
  namespace: test
  annotations:
    external-dns.alpha.kubernetes.io/hostname: k8s.ocp4.example.com
    external-dns.alpha.kubernetes.io/endpoints-type: HostIP
spec:
  ports:
  - port: 6379
    hostPort: 6379
    name: redis
  clusterIP: None
  selector:
    name: redis

# 定义 StatefulSet
# service 为前面定义的 headless service
# replicas 数量为 2
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    name: redis
  name: redis
  namespace: test
spec:
  serviceName: ksvc
  replicas: 2
  selector:
    matchLabels:
      name: redis
  template:
    metadata:
      labels:
        name: redis
    spec:
      containers:
      - image: registry.ocp4.example.com/rhel8/redis-6:20230901
        name: redis
        ports:
        - containerPort: 6379
          hostPort: 6379
          name: redis

$ oc get pods -n test | grep redis
redis-0                                    1/1     Running   0               19s
redis-1                                    1/1     Running   0               16s

# 查询 external-dns 的日志，里面包含日志
time="2023-11-27T02:53:17Z" level=debug msg="Generating matching endpoint redis-1.k8s.ocp4.example.com with HostIP 192.168.56.71"
time="2023-11-27T02:53:17Z" level=debug msg="Generating matching endpoint redis-0.k8s.ocp4.example.com with HostIP 192.168.56.81"
time="2023-11-27T02:53:17Z" level=debug msg="Endpoints generated from service: test/ksvc: [k8s.ocp4.example.com 0 IN A  192.168.56.71;192.168.56.81 [] redis-0.k8s.ocp4.example.com 0 IN A  192.168.56.81 [] redis-1.k8s.ocp4.example.com 0 IN A  192.168.56.71 []]"
time="2023-11-27T02:53:17Z" level=debug msg="AddRecord.ep=redis-0.k8s.ocp4.example.com 0 IN A  192.168.56.81 []"
time="2023-11-27T02:53:17Z" level=info msg="Adding RR: redis-0.k8s.ocp4.example.com 0 A 192.168.56.81"
time="2023-11-27T02:53:17Z" level=debug msg="AddRecord.ep=redis-1.k8s.ocp4.example.com 0 IN A  192.168.56.71 []"
time="2023-11-27T02:53:17Z" level=info msg="Adding RR: redis-1.k8s.ocp4.example.com 0 A 192.168.56.71"

# 查询 redis-0.k8s.ocp4.example.com 和 redis-1.k8s.ocp4.example.com 域名解析
$ oc -n test get pod redis-0 -o yaml | grep hostIP
  hostIP: 192.168.56.81
$ oc -n test get pod redis-1 -o yaml | grep hostIP
  hostIP: 192.168.56.71
$ dig +short redis-0.k8s.ocp4.example.com
192.168.56.81
$ dig +short redis-1.k8s.ocp4.example.com
192.168.56.71

# 访问 6379 端口
$ curl -v redis-0.k8s.ocp4.example.com:6379
* Rebuilt URL to: redis-0.k8s.ocp4.example.com:6379/
*   Trying 192.168.56.81...
* TCP_NODELAY set
* Connected to redis-0.k8s.ocp4.example.com (192.168.56.81) port 6379 (#0)
> GET / HTTP/1.1
> Host: redis-0.k8s.ocp4.example.com:6379
> User-Agent: curl/7.61.1
> Accept: */*
>
* Empty reply from server
* Connection #0 to host redis-0.k8s.ocp4.example.com left intact
curl: (52) Empty reply from server

# 监控 redis 日志里有消息
1:M 27 Nov 2023 03:05:05.642 # Possible SECURITY ATTACK detected. It looks like somebody is sending POST or Host: commands to Redis. This is likely due to an attacker attempting to use Cross Protocol Scripting to compromise your Redis instance. Connection aborted.

# 访问 redis
nc redis-0.k8s.ocp4.example.com 6379
> scan 0
> set mykey "hello"
> scan 0
> get mykey

# 查看 redis service endpoint
kubectl get endpoints ksvc -n test


oc label node w0-ocp4test.ocp4.example.com zone="zone0"
oc label node w1-ocp4test.ocp4.example.com zone="zone0"
oc label node w2-ocp4test.ocp4.example.com zone="zone0"

# 为 pod 添加 external-dns 所需的 annotation
for i in $(seq 0 3)
do
MULTUSPODIP=$(kubectl get pod redis-$i -n test -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/networks-status}' | jq -r '.[1].ips[0]')

oc patch pod redis-$i -n test --type=merge --patch-file=/dev/fd/0 <<EOF
{"metadata": {"annotations": {"external-dns.alpha.kubernetes.io/target": "$MULTUSPODIP"}}}
EOF
done

### event 监控 statefulset redis 的 events
kubectl -n test get events -w --field-selector involvedObject.name=redis 
### 将 replicas 数量从 4 减少为 3
oc scale statefulset/redis --replicas=3
### event 监控输出为 
LAST SEEN   TYPE     REASON             OBJECT              MESSAGE
0s          Normal   SuccessfulDelete   statefulset/redis   delete Pod redis-3 in StatefulSet redis successful
### 将 replicas 数量从 3 增加为 4
oc scale statefulset/redis --replicas=4
### event 监控输出为 
LAST SEEN   TYPE     REASON             OBJECT              MESSAGE
0s          Normal   SuccessfulDelete   statefulset/redis   delete Pod redis-3 in StatefulSet redis successful
0s          Normal   SuccessfulCreate   statefulset/redis   create Pod redis-3 in StatefulSet redis successful

```