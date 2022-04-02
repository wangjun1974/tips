### Test submarinar in rhpds
https://submariner.io/operations/usage/<br>
https://submariner.io/operations/deployment/subctl/<br>
```
# deploy broker
$ subctl deploy-broker --kubeconfig /Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig 
 ✓ Setting up broker RBAC                                                                                                                                   
 ✓ Deploying the Submariner operator                                                                                                                        
 ✓ Created Lighthouse service accounts and roles                                                                                                            
 ✓ Deployed the operator successfully                                                                                                                       
 ✓ Deploying the broker                                                                                                                                     
 ✓ The broker has been deployed                                                                                                                             
 ✓ Creating broker-info.subm file 
 ✓ A new IPsec PSK will be generated for broker-info.subm

# join cluster
$ subctl join --kubeconfig /Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig broker-info.subm --clusterid cluster1
$ subctl join --kubeconfig /Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig broker-info.subm --clusterid cluster2
$ subctl join --kubeconfig /Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig broker-info.subm --clusterid cluster3

# Check Submariner CRDs
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig get crds | grep -iE 'submariner|multicluster.x-k8s.io'
brokers.submariner.io                                             2022-04-01T05:09:25Z
clusterglobalegressips.submariner.io                              2022-04-01T05:09:46Z
clusters.submariner.io                                            2022-04-01T05:09:46Z
endpoints.submariner.io                                           2022-04-01T05:09:46Z
gateways.submariner.io                                            2022-04-01T05:09:46Z
globalegressips.submariner.io                                     2022-04-01T05:09:46Z
globalingressips.submariner.io                                    2022-04-01T05:09:46Z
servicediscoveries.submariner.io                                  2022-04-01T05:09:41Z
serviceexports.multicluster.x-k8s.io                              2022-04-01T05:09:41Z
serviceimports.multicluster.x-k8s.io                              2022-04-01T05:09:41Z
submariners.submariner.io                                         2022-04-01T05:09:25Z

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig get crds | grep -iE 'submariner|multicluster.x-k8s.io'
brokers.submariner.io                                             2022-04-01T06:05:26Z
clusterglobalegressips.submariner.io                              2022-04-01T06:06:17Z
clusters.submariner.io                                            2022-04-01T06:06:17Z
endpoints.submariner.io                                           2022-04-01T06:06:17Z
gateways.submariner.io                                            2022-04-01T06:06:17Z
globalegressips.submariner.io                                     2022-04-01T06:06:17Z
globalingressips.submariner.io                                    2022-04-01T06:06:17Z
servicediscoveries.submariner.io                                  2022-04-01T06:05:25Z
serviceexports.multicluster.x-k8s.io                              2022-04-01T06:06:07Z
serviceimports.multicluster.x-k8s.io                              2022-04-01T06:06:07Z
submariners.submariner.io                                         2022-04-01T06:05:24Z

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig get crds | grep -iE 'submariner|multicluster.x-k8s.io'
brokers.submariner.io                                                  2022-04-01T02:48:10Z
clusterglobalegressips.submariner.io                                   2022-04-01T02:48:37Z
clusters.submariner.io                                                 2022-03-30T06:29:58Z
endpoints.submariner.io                                                2022-03-30T06:29:58Z
gateways.submariner.io                                                 2022-03-30T06:29:58Z
globalegressips.submariner.io                                          2022-04-01T02:48:37Z
globalingressips.submariner.io                                         2022-04-01T02:48:37Z
servicediscoveries.submariner.io                                       2022-04-01T02:48:29Z
serviceexports.multicluster.x-k8s.io                                   2022-04-01T02:48:29Z
serviceimports.multicluster.x-k8s.io                                   2022-03-30T06:29:58Z
submarinerconfigs.submarineraddon.open-cluster-management.io           2022-03-30T06:29:42Z
submariners.submariner.io                                              2022-04-01T02:48:10Z


$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n submariner-k8s-broker get clusters.submariner.io
NAME       AGE
cluster1   21m
cluster2   10m
cluster3   13m

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n submariner-operator get pods
NAME                                            READY   STATUS    RESTARTS   AGE
submariner-gateway-mw2qv                        1/1     Running   0          23m
submariner-lighthouse-agent-5c8b95666f-b7lbk    1/1     Running   0          23m
submariner-lighthouse-coredns-fb5884785-d55jm   1/1     Running   0          23m
submariner-lighthouse-coredns-fb5884785-vrfnp   1/1     Running   0          23m
submariner-operator-7b6fd97fcf-mp8md            1/1     Running   0          26m
submariner-routeagent-4c495                     1/1     Running   0          23m
submariner-routeagent-69mln                     1/1     Running   0          23m
submariner-routeagent-h9spb                     1/1     Running   0          23m
submariner-routeagent-kcjvw                     1/1     Running   0          23m
submariner-routeagent-pbxv4                     1/1     Running   0          23m

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig -n submariner-operator get pods
NAME                                             READY   STATUS    RESTARTS   AGE
submariner-gateway-vs2cj                         1/1     Running   0          12m
submariner-lighthouse-agent-7459b656c8-wtnh8     1/1     Running   0          12m
submariner-lighthouse-coredns-79dcc466fb-585zp   1/1     Running   0          12m
submariner-lighthouse-coredns-79dcc466fb-dmfx7   1/1     Running   0          12m
submariner-operator-7b6fd97fcf-s2lbk             1/1     Running   1          13m
submariner-routeagent-c2kvz                      1/1     Running   0          12m
submariner-routeagent-jpgsd                      1/1     Running   0          12m
submariner-routeagent-lnws7                      1/1     Running   0          12m
submariner-routeagent-m7bjs                      1/1     Running   0          12m
submariner-routeagent-skpzb                      1/1     Running   0          12m
submariner-routeagent-xxvvv                      1/1     Running   0          12m

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig -n submariner-operator get pods
NAME                                            READY   STATUS    RESTARTS   AGE
submariner-gateway-h4jtf                        1/1     Running   0          15m
submariner-lighthouse-agent-57599bdd94-9l62f    1/1     Running   0          15m
submariner-lighthouse-coredns-545b557bc-6d9k6   1/1     Running   0          15m
submariner-lighthouse-coredns-545b557bc-zwcsh   1/1     Running   0          15m
submariner-operator-7b6fd97fcf-h49gn            1/1     Running   0          16m
submariner-routeagent-7kn8w                     1/1     Running   0          15m
submariner-routeagent-8q5jq                     1/1     Running   0          15m
submariner-routeagent-gnbdw                     1/1     Running   0          15m
submariner-routeagent-kj86z                     1/1     Running   0          15m
submariner-routeagent-rr2z4                     1/1     Running   0          15m

# ocp4.9 - check node info
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig get node --selector=submariner.io/gateway=true -o wide
NAME                                         STATUS   ROLES    AGE     VERSION                INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                                                       KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-0-184-252.us-east-2.compute.internal   Ready    worker   4h17m   v1.22.0-rc.0+894a78b   10.0.184.252   <none>        Red Hat Enterprise Linux CoreOS 49.84.202110081407-0 (Ootpa)   4.18.0-305.19.1.el8_4.x86_64   cri-o://1.22.0-73.rhaos4.9.gitbdf286c.el8

$ subctl show connections --kubeconfig /Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig 
Cluster "api-cluster-6lr59-6lr59-sandbox311-opentlc-com:6443"
 ✓ Showing Connections 
GATEWAY         CLUSTER   REMOTE IP     NAT  CABLE DRIVER  SUBNETS                       STATUS      RTT avg.    
ip-10-0-157-55  cluster3  3.134.151.45  yes  libreswan     172.30.0.0/16, 10.128.0.0/14  connecting  335.107µs   
...

# ocp4.8 - check node info
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig get node --selector=submariner.io/gateway=true -o wide
NAME                                         STATUS   ROLES    AGE     VERSION           INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                                                       KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-0-151-235.us-east-2.compute.internal   Ready    worker   2d21h   v1.21.8+8a3bf4a   10.0.151.235   <none>        Red Hat Enterprise Linux CoreOS 48.84.202203072154-0 (Ootpa)   4.18.0-305.34.2.el8_4.x86_64   cri-o://1.21.5-2.rhaos4.8.gitaf64931.el
...

$ subctl show connections --kubeconfig /Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig
Cluster "api-cluster-lr8jz-lr8jz-sandbox1298-opentlc-com:6443"
 ✓ Showing Connections 
GATEWAY          CLUSTER   REMOTE IP    NAT  CABLE DRIVER  SUBNETS                       STATUS      RTT avg.    
ip-10-0-184-252  cluster1  3.18.211.90  yes  libreswan     172.30.0.0/16, 10.128.0.0/14  connecting  1.168767ms
...

# ocp4.6 - check node info
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig get node --selector=submariner.io/gateway=true -o wide
NAME                                        STATUS   ROLES    AGE    VERSION           INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                       KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-0-157-55.us-east-2.compute.internal   Ready    worker   4d4h   v1.19.0+9f84db3   10.0.157.55   <none>        Red Hat Enterprise Linux CoreOS 46.82.202011061621-0 (Ootpa)   4.18.0-193.29.1.el8_2.x86_64   cri-o://1.19.0-22.rhaos4.6.gitc0306f1.el8

$ subctl show connections --kubeconfig /Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig
...
Cluster "api-cluster-f8t4x-f8t4x-sandbox1457-opentlc-com:6443"
 ✓ Showing Connections 
GATEWAY          CLUSTER   REMOTE IP    NAT  CABLE DRIVER  SUBNETS                       STATUS      RTT avg.    
ip-10-0-184-252  cluster1  3.18.211.90  yes  libreswan     172.30.0.0/16, 10.128.0.0/14  connecting  813.154µs


###  Check Service Discovery (Lighthouse)
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig get crds | grep -iE 'multicluster.x-k8s.io'
serviceexports.multicluster.x-k8s.io                              2022-04-01T05:09:41Z
serviceimports.multicluster.x-k8s.io                              2022-04-01T05:09:41Z

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig get crds | grep -iE 'multicluster.x-k8s.io'
serviceexports.multicluster.x-k8s.io                              2022-04-01T06:06:07Z
serviceimports.multicluster.x-k8s.io                              2022-04-01T06:06:07Z

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig get crds | grep -iE 'multicluster.x-k8s.io'
serviceexports.multicluster.x-k8s.io                                   2022-04-01T02:48:29Z
serviceimports.multicluster.x-k8s.io                                   2022-03-30T06:29:58Z

# Check submariner-lighthouse-coredns service
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n submariner-operator get service submariner-lighthouse-coredns
NAME                            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
submariner-lighthouse-coredns   ClusterIP   172.30.205.37   <none>        53/UDP    36m

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig -n submariner-operator get service submariner-lighthouse-coredns
NAME                            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
submariner-lighthouse-coredns   ClusterIP   172.30.144.30   <none>        53/UDP    25m

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig -n submariner-operator get service submariner-lighthouse-coredns
submariner-lighthouse-coredns   ClusterIP   172.30.42.198   <none>        53/UDP    29m

# Check CoreDNS Service if forward clusterset.local to Lighthouse CoreDNS server
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n openshift-dns get configmap dns-default -o yaml 
...
data:
  Corefile: |
    # lighthouse
    clusterset.local:5353 {
        forward . 172.30.205.37
        errors
        bufsize 512
    }
...

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig -n openshift-dns get configmap dns-default -o yaml 
...
data:
  Corefile: |
    # lighthouse
    clusterset.local:5353 {
        forward . 172.30.144.30
        errors
        bufsize 512
    }
...

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig -n openshift-dns get configmap dns-default -o yaml 
...
data:
  Corefile: |
    # lighthouse
    clusterset.local:5353 {
        forward . 172.30.42.198
    }

### Create nginx-test on ocp4.9
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig create namespace nginx-test
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n nginx-test create deployment nginx --image=nginxinc/nginx-unprivileged:stable-alpine

$ cat <<EOF | oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig apply -f -
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

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n nginx-test get service nginx
NAME    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
nginx   ClusterIP   172.30.49.126   <none>        8080/TCP   43s

$ subctl --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig export service --namespace nginx-test nginx
Service exported successfully

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n nginx-test describe serviceexports
Name:         nginx
Namespace:    nginx-test
Labels:       <none>
Annotations:  <none>
API Version:  multicluster.x-k8s.io/v1alpha1
Kind:         ServiceExport
Metadata:
  Creation Timestamp:  2022-04-01T06:45:58Z
  Generation:          1
  Resource Version:    106865
  UID:                 03b41e6b-1a6a-4c16-91dd-9a35578723ed
Status:
  Conditions:
    Last Transition Time:  2022-04-01T06:45:58Z
    Message:               Awaiting sync of the ServiceImport to the broker
    Reason:                AwaitingSync
    Status:                False
    Type:                  Valid
    Last Transition Time:  2022-04-01T06:45:58Z
    Message:               Service was successfully synced to the broker
    Reason:                
    Status:                True
    Type:                  Valid
Events:                    <none>

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig  get -n submariner-operator serviceimport
NAME                        TYPE           IP                  AGE
nginx-nginx-test-cluster1   ClusterSetIP   ["172.30.49.126"]   119s

### connect to nginx.nginx-test.svc.clusterset.local on ocp4.8
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig create namespace nginx-test
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig run -n nginx-test tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash
bash-5.0# curl nginx.nginx-test.svc.clusterset.local:8080
curl: (6) Could not resolve host: nginx.nginx-test.svc.clusterset.local

### connect to nginx.nginx-test.svc.clusterset.local on ocp4.6
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig  get -n submariner-operator serviceimport
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig create namespace nginx-test
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig run -n nginx-test tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash
bash-5.0# curl nginx.nginx-test.svc.clusterset.local:8080


$ subctl uninstall --kubeconfig /Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig
? This will completely uninstall Submariner from the cluster "api-cluster-f8t4x-f8t4x-sandbox1457-opentlc-com:6443". Are you sure you want to continue? Yes
 ✓ Checking if the connectivity component is installed on cluster "api-cluster-f8t4x-f8t4x-sandbox1457-opentlc-com:6443" 
 ✓ The connectivity component is installed on cluster "api-cluster-f8t4x-f8t4x-sandbox1457-opentlc-com:6443"
 ✓ Deleting the Submariner resource - this may take some time 
 ✓ Deleting the Submariner cluster roles and bindings on cluster "api-cluster-f8t4x-f8t4x-sandbox1457-opentlc-com:6443" 
 ✓ Deleted the "submariner-diagnose" cluster role and binding
 ✓ Deleted the "submariner-gateway" cluster role and binding
 ✓ Deleted the "submariner-globalnet" cluster role and binding
 ✓ Deleted the "submariner-lighthouse-agent" cluster role and binding
 ✓ Deleted the "submariner-lighthouse-coredns" cluster role and binding
 ✓ Deleted the "submariner-networkplugin-syncer" cluster role and binding
 ✓ Deleted the "submariner-operator" cluster role and binding
 ✓ Deleted the "submariner-routeagent" cluster role and binding
 ✓ Deleting the Submariner namespace "submariner-operator" on cluster "api-cluster-f8t4x-f8t4x-sandbox1457-opentlc-com:6443" 
 ✓ Deleting the broker namespace "submariner-k8s-broker" on cluster "api-cluster-f8t4x-f8t4x-sandbox1457-opentlc-com:6443" 
 ✓ Deleting the Submariner custom resource definitions on cluster "api-cluster-f8t4x-f8t4x-sandbox1457-opentlc-com:6443" 
 ✓ Deleted the "brokers.submariner.io" custom resource definition
 ✓ Deleted the "clusterglobalegressips.submariner.io" custom resource definition
 ✓ Deleted the "clusters.submariner.io" custom resource definition
 ✓ Deleted the "endpoints.submariner.io" custom resource definition
 ✓ Deleted the "gateways.submariner.io" custom resource definition
 ✓ Deleted the "globalegressips.submariner.io" custom resource definition
 ✓ Deleted the "globalingressips.submariner.io" custom resource definition
 ✓ Deleted the "servicediscoveries.submariner.io" custom resource definition
 ✓ Deleted the "submariners.submariner.io" custom resource definition
 ✓ Unlabeling gateway nodes on cluster "api-cluster-f8t4x-f8t4x-sandbox1457-opentlc-com:6443" 

$ subctl uninstall --kubeconfig /Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig
? This will completely uninstall Submariner from the cluster "api-cluster-lr8jz-lr8jz-sandbox1298-opentlc-com:6443". Are you sure you want to continue? Yes
 ✓ Checking if the connectivity component is installed on cluster "api-cluster-lr8jz-lr8jz-sandbox1298-opentlc-com:6443" 
 ✓ The connectivity component is installed on cluster "api-cluster-lr8jz-lr8jz-sandbox1298-opentlc-com:6443"
 ✓ Deleting the Submariner resource - this may take some time 
 ✓ Deleting the Submariner cluster roles and bindings on cluster "api-cluster-lr8jz-lr8jz-sandbox1298-opentlc-com:6443" 
 ✓ Deleted the "submariner-diagnose" cluster role and binding
 ✓ Deleted the "submariner-gateway" cluster role and binding
 ✓ Deleted the "submariner-globalnet" cluster role and binding
 ✓ Deleted the "submariner-lighthouse-agent" cluster role and binding
 ✓ Deleted the "submariner-lighthouse-coredns" cluster role and binding
 ✓ Deleted the "submariner-networkplugin-syncer" cluster role and binding
 ✓ Deleted the "submariner-operator" cluster role and binding
 ✓ Deleted the "submariner-routeagent" cluster role and binding
 ✓ Deleting the Submariner namespace "submariner-operator" on cluster "api-cluster-lr8jz-lr8jz-sandbox1298-opentlc-com:6443" 
 ✓ Deleting the Submariner custom resource definitions on cluster "api-cluster-lr8jz-lr8jz-sandbox1298-opentlc-com:6443" 
 ✓ Deleted the "brokers.submariner.io" custom resource definition
 ✓ Deleted the "clusterglobalegressips.submariner.io" custom resource definition
 ✓ Deleted the "clusters.submariner.io" custom resource definition
 ✓ Deleted the "endpoints.submariner.io" custom resource definition
 ✓ Deleted the "gateways.submariner.io" custom resource definition
 ✓ Deleted the "globalegressips.submariner.io" custom resource definition
 ✓ Deleted the "globalingressips.submariner.io" custom resource definition
 ✓ Deleted the "servicediscoveries.submariner.io" custom resource definition
 ✓ Deleted the "submariners.submariner.io" custom resource definition
 ✓ Unlabeling gateway nodes on cluster "api-cluster-lr8jz-lr8jz-sandbox1298-opentlc-com:6443" 

$ subctl uninstall --kubeconfig /Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig
? This will completely uninstall Submariner from the cluster "api-cluster-6lr59-6lr59-sandbox311-opentlc-com:6443". Are you sure you want to continue? Yes
 ✓ Checking if the connectivity component is installed on cluster "api-cluster-6lr59-6lr59-sandbox311-opentlc-com:6443" 
 ✓ The connectivity component is installed on cluster "api-cluster-6lr59-6lr59-sandbox311-opentlc-com:6443"
 ✓ Deleting the Submariner resource - this may take some time 
 ✓ Deleting the Submariner cluster roles and bindings on cluster "api-cluster-6lr59-6lr59-sandbox311-opentlc-com:6443" 
 ✓ Deleted the "submariner-diagnose" cluster role and binding
 ✓ Deleted the "submariner-gateway" cluster role and binding
 ✓ Deleted the "submariner-globalnet" cluster role and binding
 ✓ Deleted the "submariner-lighthouse-agent" cluster role and binding
 ✓ Deleted the "submariner-lighthouse-coredns" cluster role and binding
 ✓ Deleted the "submariner-networkplugin-syncer" cluster role and binding
 ✓ Deleted the "submariner-operator" cluster role and binding
 ✓ Deleted the "submariner-routeagent" cluster role and binding
 ✓ Deleting the Submariner namespace "submariner-operator" on cluster "api-cluster-6lr59-6lr59-sandbox311-opentlc-com:6443" 
 ✓ Deleting the broker namespace "submariner-k8s-broker" on cluster "api-cluster-6lr59-6lr59-sandbox311-opentlc-com:6443" 
 ✓ Deleting the Submariner custom resource definitions on cluster "api-cluster-6lr59-6lr59-sandbox311-opentlc-com:6443" 
 ✓ Deleted the "brokers.submariner.io" custom resource definition
 ✓ Deleted the "clusterglobalegressips.submariner.io" custom resource definition
 ✓ Deleted the "clusters.submariner.io" custom resource definition
 ✓ Deleted the "endpoints.submariner.io" custom resource definition
 ✓ Deleted the "gateways.submariner.io" custom resource definition
 ✓ Deleted the "globalegressips.submariner.io" custom resource definition
 ✓ Deleted the "globalingressips.submariner.io" custom resource definition
 ✓ Deleted the "servicediscoveries.submariner.io" custom resource definition
 ✓ Deleted the "submariners.submariner.io" custom resource definition
 ✓ Unlabeling gateway nodes on cluster "api-cluster-6lr59-6lr59-sandbox311-opentlc-com:6443" 

# Deploy submariner broker on ocp4.8 with globalnet enabled
$ subctl deploy-broker  --kubeconfig /Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig --globalnet
 ✓ Setting up broker RBAC 
 ✓ Deploying the Submariner operator 
 ✓ Created operator CRDs
 ✓ Created operator namespace: submariner-operator
 ✓ Created operator service account and role
 ✓ Created lighthouse service account and role
 ✓ Created Lighthouse service accounts and roles
 ✓ Deployed the operator successfully
 ✓ Deploying the broker 
 ✓ The broker has been deployed
 ✓ Creating broker-info.subm file 
 ⚠ Reusing IPsec PSK from existing broker-info.subm
 ✓ Backed up previous broker-info.subm to broker-info.subm.2022-04-01T15_22_28+08_00

# Prepare cloud 
subctl cloud prepare aws --ocp-metadata path/to/ocp-4.8/metadata.json
subctl cloud prepare aws --credentials <path-to-aws-credentials> --infra-id <infra> --region <region>

$ subctl join --kubeconfig /Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig broker-info.subm --clusterid cluster2
```

### 在 microshift 环境下尝试
```
$ subctl version 
subctl version: v0.12.0
# Deploy submariner broker on edge-1 with globalnet enabled
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

$ subctl cloud prepare generic --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig
 ✓ Successfully deployed gateway nodes

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

# edge-2
$ subctl cloud prepare generic --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig
 ✓ Successfully deployed gateway nodes

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

# edge-3
$ subctl cloud prepare generic --kubeconfig /root/kubeconfig/edge/edge-3/kubeconfig
 ✓ Successfully deployed gateway nodes

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

### Check Submariner CRDs 
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
$ oc get crds --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig | grep -iE 'submariner|multicluster.x-k8s.io'

### Get clusters in broker
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig -n submariner-k8s-broker get clusters.submariner.io
NAME       AGE
cluster1   5m45s
cluster2   3m45s
cluster3   2m24s

### Get Pods 
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
$ oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig -n submariner-operator get pods

### edge-1 - check node info
$ oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig get node --selector=submariner.io/gateway=true -o wide
NAME                 STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                               KERNEL-VERSION          CONTAINER-RUNTIME
edge-1.example.com   Ready    <none>   16h   v1.21.0   10.66.208.162   <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   cri-o://1.21.6

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