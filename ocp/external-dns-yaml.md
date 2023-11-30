---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: redis-network
  namespace: test
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "capabilities": { "ips": true },      
      "master": "enp1s0",
      "mode": "bridge",
      "ipam": {
            "type": "whereabouts",
            "range": "192.168.56.0/24",
            "range_start": "192.168.56.170",
            "range_end": "192.168.56.180",
            "gateway": "192.168.56.1"
      }
  }'
---
apiVersion: v1
kind: Service
metadata:
  name: ksvc
  namespace: test
  annotations:
    external-dns.alpha.kubernetes.io/hostname: k8s.ocp4.example.com
spec:
  ports:
  - port: 6379
    targetPort: 6379
    name: redis
  clusterIP: None
  selector:
    name: redis
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
  replicas: 1
  selector:
    matchLabels:
      name: redis
  template:
    metadata:
      labels:
        name: redis
      annotations:
        k8s.v1.cni.cncf.io/networks: '[{
        "name": "redis-network",
        "default-route": [ "192.168.56.1" ]
      }]'
    spec:
      nodeSelector:
         zone: "zone0"
      containers:
      - image: registry.ocp4.example.com/rhel8/redis-6:20230901
        name: redis
        ports:
        - containerPort: 6379
          name: redis
