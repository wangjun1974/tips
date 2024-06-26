### submarinner with globalnet enabled + microshift walkthrough
```
### prepare 3 microshift cluster
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig get nodes
NAME                 STATUS   ROLES    AGE   VERSION
edge-1.example.com   Ready    <none>   17h   v1.21.0
$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig get nodes
NAME                 STATUS   ROLES    AGE   VERSION
edge-2.example.com   Ready    <none>   17h   v1.21.0
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig get nodes
NAME                 STATUS   ROLES    AGE   VERSION
edge-3.example.com   Ready    <none>   17h   v1.21.0

### annotate node public-ip in on-prem env
### e.g.: kubectl annotate node $GW gateway.submariner.io/public-ip=ipv4:<1.2.3.4>
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig annotate node edge-1.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.41
$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig annotate node edge-2.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.42
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig annotate node edge-3.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.43

$ subctl version 
subctl version: v0.12.0

### Deploy submariner broker on edge-1 with globalnet enabled
$ subctl deploy-broker --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig --globalnet
 ✓ Setting up broker RBAC 
 ✓ Deploying the Submariner operator 
 ✓ Created operator CRDs
 ✓ Created operator namespace: submariner-operator
 ✓ Created operator service account and role
 ✓ Updated the privileged SCC
 ✓ Created lighthouse service account and role
 ✓ Updated the privileged SCC
 ✓ Created Lighthouse service accounts and roles
 ✓ Deployed the operator successfully
 ✓ Deploying the broker
 ✓ The broker has been deployed
 ✓ Creating broker-info.subm file
 ✓ A new IPsec PSK will be generated for broker-info.subm

### run cloud prepare generic on edge-1
$ subctl cloud prepare generic --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig
 ✓ Successfully deployed gateway nodes

### join edge-1 to broker as cluster1
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig broker-info.subm --clusterid cluster1
* broker-info.subm says broker is at: https://10.66.208.162:6443
* There are 1 labeled nodes in the cluster:
  - edge-1.example.com
        Network plugin:  generic
        Service CIDRs:   [10.43.0.0/16]
        Cluster CIDRs:   [10.42.0.0/24]
 ✓ Discovering network details
 ✓ Retrieving Globalnet information from the Broker
 ✓ Validating Globalnet configuration
 ✓ Assigning Globalnet IPs
 ✓ Allocated global CIDR 242.0.0.0/16
 ✓ Updating the Globalnet information on the Broker
 ✓ Deploying the Submariner operator 
 ✓ Created Lighthouse service accounts and roles
 ✓ Creating SA for cluster
 ✓ Deploying Submariner
 ✓ Submariner is up and running

### run cloud prepare generic on edge-2
$ subctl cloud prepare generic --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig
 ✓ Successfully deployed gateway nodes

### join edge-2 to broker as cluster2
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig broker-info.subm --clusterid cluster2
* broker-info.subm says broker is at: https://10.66.208.162:6443
* There are 1 labeled nodes in the cluster:
  - edge-2.example.com
        Network plugin:  generic
        Service CIDRs:   [10.43.0.0/16]
        Cluster CIDRs:   [10.42.0.0/24]
 ✓ Discovering network details
 ✓ Retrieving Globalnet information from the Broker
 ✓ Validating Globalnet configuration
 ✓ Assigning Globalnet IPs
 ✓ Allocated global CIDR 242.1.0.0/16
 ✓ Updating the Globalnet information on the Broker
 ✓ Deploying the Submariner operator 
 ✓ Created operator CRDs
 ✓ Created operator namespace: submariner-operator
 ✓ Created operator service account and role
 ✓ Updated the privileged SCC
 ✓ Created lighthouse service account and role
 ✓ Updated the privileged SCC
 ✓ Created Lighthouse service accounts and roles
 ✓ Deployed the operator successfully
 ✓ Creating SA for cluster
 ✓ Deploying Submariner
 ✓ Submariner is up and running

### run cloud prepare generic on edge-3
$ subctl cloud prepare generic --kubeconfig /root/kubeconfig/edge/edge-3/kubeconfig
 ✓ Successfully deployed gateway nodes

### join edge-3 to broker as cluster3
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-3/kubeconfig broker-info.subm --clusterid cluster3
* broker-info.subm says broker is at: https://10.66.208.162:6443
* There are 1 labeled nodes in the cluster:
  - edge-3.example.com
        Network plugin:  generic
        Service CIDRs:   [10.43.0.0/16]
        Cluster CIDRs:   [10.42.0.0/24]
 ✓ Discovering network details
 ✓ Retrieving Globalnet information from the Broker
 ✓ Validating Globalnet configuration
 ✓ Assigning Globalnet IPs
 ✓ Allocated global CIDR 242.2.0.0/16
 ✓ Updating the Globalnet information on the Broker
 ✓ Deploying the Submariner operator 
 ✓ Created operator CRDs
 ✓ Created operator namespace: submariner-operator
 ✓ Created operator service account and role
 ✓ Updated the privileged SCC
 ✓ Created lighthouse service account and role
 ✓ Updated the privileged SCC
 ✓ Created Lighthouse service accounts and roles
 ✓ Deployed the operator successfully
 ✓ Creating SA for cluster
 ✓ Deploying Submariner
 ✓ Submariner is up and running

### Check Submariner CRDs on edge-1/2/3
$ oc get crds --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig | grep -iE 'submariner|multicluster.x-k8s.io'
brokers.submariner.io                                2022-04-02T01:29:25Z
clusterglobalegressips.submariner.io                 2022-04-02T01:30:02Z
clusters.submariner.io                               2022-04-02T01:30:02Z
endpoints.submariner.io                              2022-04-02T01:30:02Z
gateways.submariner.io                               2022-04-02T01:30:02Z
globalegressips.submariner.io                        2022-04-02T01:30:02Z
globalingressips.submariner.io                       2022-04-02T01:30:02Z
servicediscoveries.submariner.io                     2022-04-02T01:29:25Z
serviceexports.multicluster.x-k8s.io                 2022-04-02T01:29:58Z
serviceimports.multicluster.x-k8s.io                 2022-04-02T01:29:58Z
submariners.submariner.io                            2022-04-02T01:29:25Z

$ oc get crds --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig | grep -iE 'submariner|multicluster.x-k8s.io'
brokers.submariner.io                                2022-04-02T01:53:40Z
clusterglobalegressips.submariner.io                 2022-04-02T01:54:14Z
clusters.submariner.io                               2022-04-02T01:54:14Z
endpoints.submariner.io                              2022-04-02T01:54:14Z
gateways.submariner.io                               2022-04-02T01:54:14Z
globalegressips.submariner.io                        2022-04-02T01:54:14Z
globalingressips.submariner.io                       2022-04-02T01:54:15Z
servicediscoveries.submariner.io                     2022-04-02T01:53:40Z
serviceexports.multicluster.x-k8s.io                 2022-04-02T01:54:10Z
serviceimports.multicluster.x-k8s.io                 2022-04-02T01:54:10Z
submariners.submariner.io                            2022-04-02T01:53:40Z

$ oc get crds --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig | grep -iE 'submariner|multicluster.x-k8s.io'
brokers.submariner.io                                2022-04-02T01:55:07Z
clusterglobalegressips.submariner.io                 2022-04-02T01:55:40Z
clusters.submariner.io                               2022-04-02T01:55:40Z
endpoints.submariner.io                              2022-04-02T01:55:40Z
gateways.submariner.io                               2022-04-02T01:55:40Z
globalegressips.submariner.io                        2022-04-02T01:55:41Z
globalingressips.submariner.io                       2022-04-02T01:55:41Z
servicediscoveries.submariner.io                     2022-04-02T01:55:07Z
serviceexports.multicluster.x-k8s.io                 2022-04-02T01:55:36Z
serviceimports.multicluster.x-k8s.io                 2022-04-02T01:55:36Z
submariners.submariner.io                            2022-04-02T01:55:07Z

### Get clusters in broker
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n submariner-k8s-broker get clusters.submariner.io
NAME       AGE
cluster1   5m45s
cluster2   3m45s
cluster3   2m24s

### Get Pods on edge-1/2/3
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n submariner-operator get pods
NAME                                            READY   STATUS    RESTARTS   AGE
submariner-gateway-48c5g                        1/1     Running   0          8m5s
submariner-globalnet-g9xf9                      1/1     Running   0          8m2s
submariner-lighthouse-agent-74d9c49945-jchqz    1/1     Running   0          8m1s
submariner-lighthouse-coredns-fb5884785-pbrp4   1/1     Running   0          7m59s
submariner-lighthouse-coredns-fb5884785-w252n   1/1     Running   0          7m59s
submariner-operator-7b6fd97fcf-fgmxl            1/1     Running   1          31m
submariner-routeagent-zczhw                     1/1     Running   0          8m3s

$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig -n submariner-operator get pods
NAME                                             READY   STATUS    RESTARTS   AGE
submariner-gateway-9scnk                         1/1     Running   0          40m
submariner-globalnet-9t7vv                       1/1     Running   0          40m
submariner-lighthouse-agent-7b8bd64bcb-88dhx     1/1     Running   0          40m
submariner-lighthouse-coredns-79dcc466fb-2cmmg   1/1     Running   0          40m
submariner-lighthouse-coredns-79dcc466fb-bblv2   1/1     Running   0          40m
submariner-operator-7b6fd97fcf-jlbqs             1/1     Running   1          41m
submariner-routeagent-47sng                      1/1     Running   0          40m

$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig -n submariner-operator get pods
NAME                                            READY   STATUS    RESTARTS   AGE
submariner-gateway-9lz9b                        1/1     Running   0          39m
submariner-globalnet-rwpc5                      1/1     Running   0          39m
submariner-lighthouse-agent-7c896fd965-mwmwf    1/1     Running   0          39m
submariner-lighthouse-coredns-545b557bc-7vkbq   1/1     Running   0          39m
submariner-lighthouse-coredns-545b557bc-wkckx   1/1     Running   0          39m
submariner-operator-7b6fd97fcf-jpksw            1/1     Running   1          39m
submariner-routeagent-fct9p                     1/1     Running   0          39m

### edge-1 - check node info
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig get node --selector=submariner.io/gateway=true -o wide
NAME                 STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                               KERNEL-VERSION          CONTAINER-RUNTIME
edge-1.example.com   Ready    <none>   16h   v1.21.0   10.66.208.162   <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   cri-o://1.21.6

### edge-1 - show connections
$ subctl show connections --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig
Cluster "microshift"
 ✓ Showing Connections
GATEWAY             CLUSTER   REMOTE IP      NAT  CABLE DRIVER  SUBNETS       STATUS     RTT avg.    
edge-2.example.com  cluster2  10.66.208.163  no   libreswan     242.1.0.0/16  connected  686.617µs   
edge-3.example.com  cluster3  10.66.208.164  no   libreswan     242.2.0.0/16  connected  393.546µs   

### edge-2 - check node info
$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig get node --selector=submariner.io/gateway=true -o wide
NAME                 STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                               KERNEL-VERSION          CONTAINER-RUNTIME
edge-2.example.com   Ready    <none>   16h   v1.21.0   10.66.208.163   <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   cri-o://1.21.6

### edge-2 - show connections
$ subctl show connections --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig
Cluster "microshift"
 ✓ Showing Connections
GATEWAY             CLUSTER   REMOTE IP      NAT  CABLE DRIVER  SUBNETS       STATUS     RTT avg.    
edge-1.example.com  cluster1  10.66.208.162  no   libreswan     242.0.0.0/16  connected  659.153µs   
edge-3.example.com  cluster3  10.66.208.164  no   libreswan     242.2.0.0/16  connected  577.259µs   

### edge-3 - check node info
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig get node --selector=submariner.io/gateway=true -o wide
NAME                 STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                               KERNEL-VERSION          CONTAINER-RUNTIME
edge-3.example.com   Ready    <none>   16h   v1.21.0   10.66.208.164   <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   cri-o://1.21.6

### edge-3 - show connections
$ subctl show connections --kubeconfig /root/kubeconfig/edge/edge-3/kubeconfig
Cluster "microshift"
 ✓ Showing Connections
GATEWAY             CLUSTER   REMOTE IP      NAT  CABLE DRIVER  SUBNETS       STATUS     RTT avg.    
edge-1.example.com  cluster1  10.66.208.162  no   libreswan     242.0.0.0/16  connected  467.207µs   
edge-2.example.com  cluster2  10.66.208.163  no   libreswan     242.1.0.0/16  connected  641.604µs   

###  Check Service Discovery (Lighthouse)
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig get crds | grep -iE 'multicluster.x-k8s.io'
serviceexports.multicluster.x-k8s.io                 2022-04-02T01:29:58Z
serviceimports.multicluster.x-k8s.io                 2022-04-02T01:29:58Z

$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig get crds | grep -iE 'multicluster.x-k8s.io'
serviceexports.multicluster.x-k8s.io                 2022-04-02T01:54:10Z
serviceimports.multicluster.x-k8s.io                 2022-04-02T01:54:10Z

$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig get crds | grep -iE 'multicluster.x-k8s.io'
serviceexports.multicluster.x-k8s.io                 2022-04-02T01:55:36Z
serviceimports.multicluster.x-k8s.io                 2022-04-02T01:55:36Z

### Check submariner-lighthouse-coredns service
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n submariner-operator get service submariner-lighthouse-coredns
NAME                            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
submariner-lighthouse-coredns   ClusterIP   10.43.99.88   <none>        53/UDP    14m

$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig -n submariner-operator get service submariner-lighthouse-coredns
NAME                            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
submariner-lighthouse-coredns   ClusterIP   10.43.27.110   <none>        53/UDP    12m

$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig -n submariner-operator get service submariner-lighthouse-coredns
NAME                            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
submariner-lighthouse-coredns   ClusterIP   10.43.2.162   <none>        53/UDP    11m

### Check CoreDNS Service if forward clusterset.local to Lighthouse CoreDNS server
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n openshift-dns get configmap dns-default -o yaml 
...
data:
  Corefile: |+
    #lighthouse-start AUTO-GENERATED SECTION. DO NOT EDIT
    clusterset.local:5353 {
        forward . 10.43.99.88
    }
...

$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig -n openshift-dns get configmap dns-default -o yaml 
...
data:
  Corefile: |+
    #lighthouse-start AUTO-GENERATED SECTION. DO NOT EDIT
    clusterset.local:5353 {
        forward . 10.43.27.110
    }
...

$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig -n openshift-dns get configmap dns-default -o yaml 
...
data:
  Corefile: |+
    #lighthouse-start AUTO-GENERATED SECTION. DO NOT EDIT
    clusterset.local:5353 {
        forward . 10.43.2.162
    }
...

### Create nginx-test on edge-1
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig create namespace nginx-test
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n nginx-test create deployment nginx --image=nginxinc/nginx-unprivileged:stable-alpine

$ cat <<EOF | oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx
  name: nginx
  namespace: nginx-test
spec:
  ports:
  - name: http
    port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: nginx
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
EOF

$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n nginx-test get service nginx
NAME    TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
nginx   ClusterIP   10.43.9.172   <none>        8080/TCP   29s

$ subctl --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig export service --namespace nginx-test nginx
Service exported successfully

$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n nginx-test describe serviceexports
Name:         nginx
Namespace:    nginx-test
Labels:       <none>
Annotations:  <none>
API Version:  multicluster.x-k8s.io/v1alpha1
Kind:         ServiceExport
Metadata:
  Creation Timestamp:  2022-04-02T02:12:33Z
  Generation:          1
  Resource Version:    28291
  Self Link:           /apis/multicluster.x-k8s.io/v1alpha1/namespaces/nginx-test/serviceexports/nginx
  UID:                 bac0881e-cf3e-42fb-a89d-3e077333580c
Status:
  Conditions:
    Last Transition Time:  2022-04-02T02:12:33Z
    Message:               Service doesn't have a global IP yet
    Reason:                ServiceGlobalIPUnavailable
    Status:                False
    Type:                  Valid
    Last Transition Time:  2022-04-02T02:12:33Z
    Message:               Awaiting sync of the ServiceImport to the broker
    Reason:                AwaitingSync
    Status:                False
    Type:                  Valid
    Last Transition Time:  2022-04-02T02:12:33Z
    Message:               Service was successfully synced to the broker
    Reason:                
    Status:                True
    Type:                  Valid
Events:                    <none>

$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig  get -n submariner-operator serviceimport
NAME                        TYPE           IP                  AGE
nginx-nginx-test-cluster1   ClusterSetIP   ["242.0.255.253"]   82s

$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig  get -n submariner-operator serviceimport
NAME                        TYPE           IP                  AGE
nginx-nginx-test-cluster1   ClusterSetIP   ["242.0.255.253"]   101s

### connect to nginx.nginx-test.svc.clusterset.local on edge-2
$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig create namespace nginx-test
$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig run -n nginx-test tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash
bash-5.0# curl nginx.nginx-test.svc.clusterset.local:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

### connect to nginx.nginx-test.svc.clusterset.local on edge-3
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig create namespace nginx-test
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig run -n nginx-test tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash
bash-5.0# curl nginx.nginx-test.svc.clusterset.local:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

### Day2 Operations 
```
# uninstall 
subctl uninstall --kubeconfig <path-to-kubeconfig>

# remove submariner annotation from microshift nodes
oc get $(oc get nodes -o name) -o yaml
oc annotate $(oc get nodes -o name) submariner.io/cniIfaceIp-
oc annotate $(oc get nodes -o name) submariner.io/globalIp-

# NAT TRAVERSAL
# https://submariner.io/operations/nat-traversal/

# Quick Start Guide - Kind
# --natt=false
https://submariner.io/getting-started/quickstart/kind/

$ subctl deploy-broker --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig --globalnet
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig broker-info.subm --clusterid cluster1 --natt=false
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig broker-info.subm --clusterid cluster2 --natt=false
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-3/kubeconfig broker-info.subm --clusterid cluster3 --natt=false

# Submariner Troubleshooting
# https://submariner.io/operations/troubleshooting/
$ oc --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig describe Gateway -n submariner-operator

    Latency RTT:
      Average:       0s
      Last:          0s
      Max:           0s
      Min:           0s
      Std Dev:       0s
    Status:          error
    Status Message:  Failed to successfully ping the remote endpoint IP "242.2.255.254"
    Using IP:        10.66.208.164
  Ha Status:         active


```


### Submariner Gateway Firewall
```
# https://submariner.io/getting-started/
sudo firewall-cmd --zone=public --add-port=500/udp --permanent
sudo firewall-cmd --zone=public --add-port=501/udp --permanent
sudo firewall-cmd --zone=public --add-port=4490/udp --permanent
sudo firewall-cmd --zone=public --add-port=4500/udp --permanent
sudo firewall-cmd --zone=public --add-port=4501/udp --permanent
sudo firewall-cmd --zone=public --add-port=4800/udp --permanent
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

### Save Submariner images to local registry
```
LOCAL_SECRET_JSON=/data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json

# quay.io/submariner/lighthouse-agent:0.12.0
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/submariner/lighthouse-agent:0.12.0 docker://registry.example.com:5000/submariner/lighthouse-agent:0.12.0

# quay.io/submariner/lighthouse-coredns:0.12.0
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/submariner/lighthouse-coredns:0.12.0 docker://registry.example.com:5000/submariner/lighthouse-coredns:0.12.0

# quay.io/submariner/submariner-gateway:0.12.0
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/submariner/submariner-gateway:0.12.0 docker://registry.example.com:5000/submariner/submariner-gateway:0.12.0

# quay.io/submariner/submariner-globalnet:0.12.0
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/submariner/submariner-globalnet:0.12.0 docker://registry.example.com:5000/submariner/submariner-globalnet:0.12.0

# quay.io/submariner/submariner-operator:0.12.0
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/submariner/submariner-operator:0.12.0 docker://registry.example.com:5000/submariner/submariner-operator:0.12.0

# quay.io/submariner/submariner-route-agent:0.12.0
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://quay.io/submariner/submariner-route-agent:0.12.0 docker://registry.example.com:5000/submariner/submariner-route-agent:0.12.0

# gcr.io/google_containers/pause
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://gcr.io/google_containers/pause:latest docker://registry.example.com:5000/google_containers/pause:latest

```

### update /etc/container/registries.conf 
```
# generate /etc/containers/registries.conf using local registry mirror
cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ['registry.example.com:5000']
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift/okd-content"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/openshift/okd-content"

[[registry]]
  prefix = ""
  location = "quay.io/microshift/flannel-cni"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/microshift/flannel-cni"

[[registry]]
  prefix = ""
  location = "quay.io/coreos/flannel"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/coreos/flannel"    

[[registry]]
  prefix = ""
  location = "quay.io/kubevirt/hostpath-provisioner"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/kubevirt/hostpath-provisioner"

[[registry]]
  prefix = ""
  location = "k8s.gcr.io/pause"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/pause/pause"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2"

[[registry]]
  prefix = ""
  location = "k8s.gcr.io/pause"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/pause/pause"

[[registry]]
  prefix = ""
  location = "quay.io/submariner"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/submariner"

[[registry]]
  prefix = ""
  location = "gcr.io/google_containers"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/google_containers"     
EOF

# restart crio and microshift 
systemctl restart crio ; systemctl restart microshift
```

### check logs
```
# submariner-gateway
oc -n submariner-operator logs $(oc -n submariner-operator get pods -l app=submariner-gateway -o name)

# if logs has this type of error 
E0412 05:04:33.019441       1 token_source.go:152] Unable to rotate token: failed to read token file "/run/secrets/submariner.io/broker-secret-7qc9f/token": open /run/secrets/submariner.io/broker-secret-7qc9f/token: no such file or directory

# delete submariner-gateway pod
oc -n submariner-operator delete $(oc -n submariner-operator get pods -l app=submariner-gateway -o name)

# submariner-operator
oc -n submariner-operator logs $(oc -n submariner-operator get pods -l name=submariner-operator -o name)

# submariner-globalnet
oc -n submariner-operator logs $(oc -n submariner-operator get pods -l app=submariner-globalnet -o name)

# submariner-lighthouse-coredns
oc -n submariner-operator logs $(oc -n submariner-operator get pods -l app=submariner-lighthouse-coredns -o name | head -1)
oc -n submariner-operator logs $(oc -n submariner-operator get pods -l app=submariner-lighthouse-coredns -o name | tail -1)

# submariner-lighthouse-agent
oc -n submariner-operator logs $(oc -n submariner-operator get pods -l app=submariner-lighthouse-agent -o name)

# submariner-routeagent
oc -n submariner-operator logs $(oc -n submariner-operator get pods -l app=submariner-routeagent -o name)

```


### annotate node public-ip in on-prem env
```
### annotate node public-ip in on-prem env
### e.g.: kubectl annotate node $GW gateway.submariner.io/public-ip=ipv4:<1.2.3.4>
# kubectl annotate node $GW gateway.submariner.io/public-ip=ipv4:<1.2.3.4>
oc --kubeconfig=/root/kubeconfig/edge/edge1/kubeconfig annotate node edge1.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.41
oc --kubeconfig=/root/kubeconfig/edge/edge2/kubeconfig annotate node edge2.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.42
oc --kubeconfig=/root/kubeconfig/edge/edge3/kubeconfig annotate node edge3.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.43
```

### Patch a secret  
```
oc -n submariner-operator patch secret broker-secret-chd2k --type='json' -p='[{"op" : "replace" ,"path" : "/data/ca.crt" ,"value" : "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURTRENDQWpDZ0F3SUJBZ0lJTGdsSFUvMjZ1Njh3RFFZSktvWklodmNOQVFFTEJRQXdRakVmTUIwR0ExVUUKQ2hNV2FIUjBjSE02THk5cmRXSmxjbTVsZEdWekxuTjJZekVmTUIwR0ExVUVBeE1XYUhSMGNITTZMeTlyZFdKbApjbTVsZEdWekxuTjJZekFlRncweU1qQTBNVE13TmpNd05UTmFGdzB5TXpBME1UTXdOak13TlROYU1FSXhIekFkCkJnTlZCQW9URm1oMGRIQnpPaTh2YTNWaVpYSnVaWFJsY3k1emRtTXhIekFkQmdOVkJBTVRGbWgwZEhCek9pOHYKYTNWaVpYSnVaWFJsY3k1emRtTXdnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFDOApRNkY5N0tJTVU0bDVMelNhQ09zbHRCSTlOb25BNEVxcTkwVC92NWhFdEhVQlJORmJ5ZnVFR0lOaXNTaGd6NEcyCnRSNCtwMElRNmxsb0dTNVBDNExuR09vRnZ0Y1k3MXJQNjUvNmVMMGl2MXlISTJGMGhWa2IrRmlMWTBnWEdCTnQKbjZSSnNiV0RpN1kzRkIyeGZReUd1ZGdBUTRPM0xCcnZWSFhEekNiYkp5K3lFRVlEZVZwQ2Rnd3o4aUp4U0xtRgo2cU43aUQ4TnFvbzJLNnI5V2VFT01PNVdNd3c1cGJmSXR5VUZNVERKMG1YUUJnMnB5cFhBWW5vSk9NeXFQdWhqCnZkUlBLM2RIblFRK0ZIV1NCWWVWQVU5aGxoNGNGdkU2SnVrRFhwZ1RzZXhUalV3TUFOK0xCdEdWRlF2cFdsbC8KQ211dzZkd3J4T3F3TlQrUjBkRWhBZ01CQUFHalFqQkFNQTRHQTFVZER3RUIvd1FFQXdJQ3BEQVBCZ05WSFJNQgpBZjhFQlRBREFRSC9NQjBHQTFVZERnUVdCQlR4ajVPSjZXWDFVZ1NzMm4xdk1tdm5KNzNGT2pBTkJna3Foa2lHCjl3MEJBUXNGQUFPQ0FRRUFleHpmajlBOGlzeVp4dUwrU1kzZm01TjlsbE44ZHg5M005TWQrU3BRZDRKRmhRUDAKaFNWLzFMNVJ0RDdJWndIbmlPNzd5eXZSaFErNURlc3dpakpDakFDN08za1VMWDQ3eTNKb1dlYUgzNGR0TkV1UwpaQTZqTFkyK1duRnVwL2h6WWZvb1NFalUrQjRzRG5SOUlRUGhJUWlNd0VSRWhuSGxJMFNHZ0dxbkFCOHN0TUhSCkdhcVZYMjREY2l5aERZcEN0RVl3L3hUNStTOEZEMHBKelJPR2xLdDRCM1ZQaGJ4dXorRHhaU2NjenJkdGNNaG4Kc3B1cyt0YzBHNzl4T2xzQUpkR25oRGJuWXl3dU5yNmtUQUhWK21IZGc2d0JtOE9UektZUDlwZTRPZjU5UVdPMAo5RUVST1dWQnEyWDZ6cGVaQ2I4OFk1U3RINytYQW1DZHhxakxHQT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"}]'

oc -n submariner-operator patch secret broker-secret-chd2k --type='json' -p='[{"op" : "replace" ,"path" : "/data/namespace" ,"value" : "c3VibWFyaW5lci1rOHMtYnJva2Vy"}]'

oc -n submariner-operator patch secret broker-secret-chd2k --type='json' -p='[{"op" : "replace" ,"path" : "/data/token" ,"value" : "ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNkltVTFValE1WlZNNVJGTTNYM2gwU1habVNqWndWRUZyUVZJM2REbFNTMXBaWVdaU1FqWlZOMVZ5Um5NaWZRLmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUp6ZFdKdFlYSnBibVZ5TFdzNGN5MWljbTlyWlhJaUxDSnJkV0psY201bGRHVnpMbWx2TDNObGNuWnBZMlZoWTJOdmRXNTBMM05sWTNKbGRDNXVZVzFsSWpvaVkyeDFjM1JsY2kxamJIVnpkR1Z5TXkxMGIydGxiaTFpYkhOdGJDSXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMbTVoYldVaU9pSmpiSFZ6ZEdWeUxXTnNkWE4wWlhJeklpd2lhM1ZpWlhKdVpYUmxjeTVwYnk5elpYSjJhV05sWVdOamIzVnVkQzl6WlhKMmFXTmxMV0ZqWTI5MWJuUXVkV2xrSWpvaU56aG1NVEJpTXpFdE9XSmlaaTAwWkRFMkxXSTBNMlV0TnpnMlltRmlNbUZoWldObElpd2ljM1ZpSWpvaWMzbHpkR1Z0T25ObGNuWnBZMlZoWTJOdmRXNTBPbk4xWW0xaGNtbHVaWEl0YXpoekxXSnliMnRsY2pwamJIVnpkR1Z5TFdOc2RYTjBaWEl6SW4wLmRYal9iaUF4d2tkM0tsNzgyNC1tTTJQZHVQLWVNRFMxOHl1SWRPVEgzY053WUV3Qy1GQ2tRYmwxQi01UU1QN2ZVUHh4NU96NnRqZ29abGJtblI0bm9PdlJNSzBMOFU0cUlUX3cxallmdXR3ek9pNXR1Y1MwR2I0ekNrcnFjR1hzTktRbjduSHNDaGNzc2s5RGZPbktfWDluNzlRSFhnVHpGZ1FnMkdXRG83Mk9YdGFUMWVzMUdiNm1ZcEdENVYtd1NTU0YxS0tZQTFEcW5VNlBRdk9KbFRCZ2RheU0wcGZtNG9tdFZ4UUwtRnVLajVoTVRNTlVmcjlQWnk2Q3VPNWVlTkhiTlRSRnVvN3VVVnhBekUtMTY0QldmVlN6QTl5Q2g4c2s2TTJMd3Rkbms2allTcjdTc29SUW5xcnduY1hrYmpxc3F0YVZ0UUQ1d3ZYaHdBMWREdw=="}]'

oc -n submariner-operator patch secret broker-secret-chd2k --type='json' -p='[{"op" : "remove" ,"path" : "/data/.dockercfg"}]'


```

### Submariner add mysql firewall rules 
```
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
sudo firewall-cmd --zone=public --add-port=4444/tcp --permanent
sudo firewall-cmd --zone=public --add-port=4567/tcp --permanent
sudo firewall-cmd --zone=public --add-port=4568/tcp --permanent
sudo firewall-cmd --reload
```

### join cluster with --cable-driver=vxlan
```
### annotate node public-ip in on-prem env
### e.g.: kubectl annotate node $GW gateway.submariner.io/public-ip=ipv4:<1.2.3.4>
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig annotate node edge-1.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.41
$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig annotate node edge-2.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.42
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig annotate node edge-3.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.43

### Deploy submariner broker on edge-1 without globalnet enabled
$ subctl deploy-broker --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig 

### run cloud prepare generic on edge-1
$ subctl cloud prepare generic --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig

### join edge-1 to broker as cluster1 with cable-driver 'vxlan'
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig broker-info.subm --clusterid cluster1 --cable-driver=vxlan

### run cloud prepare generic on edge-2
$ subctl cloud prepare generic --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig

### join edge-2 to broker as cluster1 with cable-driver 'vxlan'
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig broker-info.subm --clusterid cluster2 --cable-driver=vxlan

### run cloud prepare generic on edge-3
$ subctl cloud prepare generic --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig

### join edge-3 to broker as cluster1 with cable-driver 'vxlan'
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-3/kubeconfig broker-info.subm --clusterid cluster3 --cable-driver=vxlan
```

### Submariner 0.10
```

### download subctl 0.10
$ wget https://github.com/submariner-io/submariner-operator/releases/download/subctl-release-0.10/subctl-release-0.10-linux-amd64.tar.xz
$ tar Jxf subctl-release-0.10-linux-amd64.tar.xz
$ mv subctl-release-0.10/subctl-release-0.10-linux-amd64 /usr/local/bin/subctl 

$ subctl version
subctl version: release-0.10

### annotate node public-ip in on-prem env
### e.g.: kubectl annotate node $GW gateway.submariner.io/public-ip=ipv4:<1.2.3.4>
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig annotate node edge-1.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.41
$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig annotate node edge-2.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.42
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig annotate node edge-3.example.com gateway.submariner.io/public-ip=ipv4:172.16.0.43

$ subctl deploy-broker --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig 
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig broker-info.subm --clusterid cluster1 --natt=false
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig broker-info.subm --clusterid cluster2 --natt=false
$ subctl join --kubeconfig /root/kubeconfig/edge/edge-3/kubeconfig broker-info.subm --clusterid cluster3 --natt=false

### microshift can not verify by this method
$ subctl verify /root/kubeconfig/edge/edge-1/kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig --only connectivity --verbose

### deploy nginx on edge-1/2/3
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig create namespace nginx-test
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n nginx-test create deployment nginx --image=nginxinc/nginx-unprivileged:stable-alpine
$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig create namespace nginx-test
$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig -n nginx-test create deployment nginx --image=nginxinc/nginx-unprivileged:stable-alpine
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig create namespace nginx-test
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig -n nginx-test create deployment nginx --image=nginxinc/nginx-unprivileged:stable-alpine

### obtain pod ip
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n nginx-test get $(oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n nginx-test get pods -l app=nginx -o name) -o jsonpath='{.status.podIP}{"\n"}'
10.42.0.67
$ oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig -n nginx-test get $(oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig -n nginx-test get pods -l app=nginx -o name) -o jsonpath='{.status.podIP}{"\n"}'
10.52.0.20
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig -n nginx-test get $(oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig -n nginx-test get pods -l app=nginx -o name) -o jsonpath='{.status.podIP}{"\n"}'
10.62.0.13

### 
$ oc -n nginx-test run tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash
bash-5.0# curl 10.42.0.67:8080
bash-5.0# curl 10.52.0.20:8080
bash-5.0# curl 10.62.0.13:8080

### Describe Gateway
$ oc -n submariner-operator describe Gateway


### deployment and daemonset
$ oc get deployment -A 
NAMESPACE              NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
...
submariner-operator    submariner-lighthouse-agent     1/1     1            1           21m
submariner-operator    submariner-lighthouse-coredns   2/2     2            2           21m
submariner-operator    submariner-operator             1/1     1            1           22m

$ oc get daemonset -A 
NAMESPACE                       NAME                            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                AGE
...
submariner-operator             submariner-gateway              1         1         1       1            1           submariner.io/gateway=true   21m
submariner-operator             submariner-routeagent           1         1         1       1            1           <none>                       21m


### obtain image list
oc -n submariner-operator get deployment submariner-operator -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
oc -n submariner-operator get deployment submariner-lighthouse-agent -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
oc -n submariner-operator get deployment submariner-lighthouse-coredns -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

oc -n submariner-operator get daemonset submariner-gateway -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
oc -n submariner-operator get daemonset submariner-routeagent -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

quay.io/submariner/submariner-operator:release-0.10
quay.io/submariner/lighthouse-agent:release-0.10
quay.io/submariner/lighthouse-coredns:release-0.10
quay.io/submariner/submariner-gateway:release-0.10
quay.io/submariner/submariner-route-agent:release-0.10

### 
oc image mirror quay.io/submariner/lighthouse-agent:release-0.10          file://submariner/lighthouse-agent:release-0.10
oc image mirror quay.io/submariner/lighthouse-coredns:release-0.10        file://submariner/lighthouse-coredns:release-0.10
oc image mirror quay.io/submariner/submariner-gateway:release-0.10        file://submariner/submariner-gateway:release-0.10
oc image mirror quay.io/submariner/submariner-operator:release-0.10       file://submariner/submariner-operator:release-0.10
oc image mirror quay.io/submariner/submariner-route-agent:release-0.10    file://submariner/submariner-route-agent:release-0.10
oc image mirror gcr.io/google_containers/pause:latest             file://google_containers/pause:latest

tar -cf xxxx.tar  ./

tar -xf xxxx.tar

oc image mirror  --from-dir=./  file://submariner/lighthouse-agent:release-0.10         registry.gaolantest.greeyun.com:8443/microshift/submariner/lighthouse-agent:release-0.10      
oc image mirror  --from-dir=./  file://submariner/lighthouse-coredns:release-0.10       registry.gaolantest.greeyun.com:8443/microshift/submariner/lighthouse-coredns:release-0.10    
oc image mirror  --from-dir=./  file://submariner/submariner-gateway:release-0.10       registry.gaolantest.greeyun.com:8443/microshift/submariner/submariner-gateway:release-0.10    
oc image mirror  --from-dir=./  file://submariner/submariner-operator:release-0.10      registry.gaolantest.greeyun.com:8443/microshift/submariner/submariner-operator:release-0.10   
oc image mirror  --from-dir=./  file://submariner/submariner-route-agent:release-0.10   registry.gaolantest.greeyun.com:8443/microshift/submariner/submariner-route-agent:release-0.10
oc image mirror  --from-dir=./  file://google_containers/pause:latest             registry.gaolantest.greeyun.com:8443/microshift/google_containers/pause:latest      
```