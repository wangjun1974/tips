## OpenShift Virtualization 实验记录
实验手册
https://github.com/RHFieldProductManagement/openshift-virt-labs/tree/rhpds

## Network
https://docs.openshift.com/container-platform/4.3/networking/multiple_networks/configuring-bridge.html


## Storage
Persistent Storage Using iSCSI<br>
https://docs.openshift.com/container-platform/4.4/storage/persistent_storage/persistent-storage-iscsi.html

IBM Storage for Red Hat OpenShift Blueprint Version 1 Release 5<br>
https://www.redbooks.ibm.com/redpapers/pdfs/redp5565.pdf

OpenShift 4 对接 HPE 存储的例子<br>
https://www.openshift.com/blog/red-hat-openshift-certified-hpe-csi-operator-for-kubernetes-available-now

https://www.dellemc.com/resources/en-us/asset/technical-guides-support-information/solutions/h18217-openshift-container-dg.pdf

```
[asimonel-redhat.com@bastion ~]$ oc get nodes
NAME                              STATUS   ROLES    AGE   VERSION
cluster-452f-rfnck-master-0       Ready    master   23h   v1.18.3+012b3ec
cluster-452f-rfnck-master-1       Ready    master   23h   v1.18.3+012b3ec
cluster-452f-rfnck-master-2       Ready    master   23h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-4n9sq   Ready    worker   23h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-mfhzd   Ready    worker   23h   v1.18.3+012b3ec

[asimonel-redhat.com@bastion ~]$ oc get clusterversion 
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.5.4     True        False         22h     Cluster version is 4.5.4

[asimonel-redhat.com@bastion ~]$ oc get clusteroperators
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.5.4     True        False         False      22h
cloud-credential                           4.5.4     True        False         False      23h
cluster-autoscaler                         4.5.4     True        False         False      23h
config-operator                            4.5.4     True        False         False      23h
console                                    4.5.4     True        False         False      23h
csi-snapshot-controller                    4.5.4     True        False         False      67m
dns                                        4.5.4     True        False         False      23h
etcd                                       4.5.4     True        False         False      146m
image-registry                             4.5.4     True        False         False      23h
ingress                                    4.5.4     True        False         False      23h
insights                                   4.5.4     True        False         False      23h
kube-apiserver                             4.5.4     True        False         False      23h
kube-controller-manager                    4.5.4     True        False         False      23h
kube-scheduler                             4.5.4     True        False         False      23h
kube-storage-version-migrator              4.5.4     True        False         False      3h26m
machine-api                                4.5.4     True        False         False      23h
machine-approver                           4.5.4     True        False         False      23h
machine-config                             4.5.4     True        False         False      88m
marketplace                                4.5.4     True        False         False      23h
monitoring                                 4.5.4     True        False         False      51m
network                                    4.5.4     True        False         False      23h
node-tuning                                4.5.4     True        False         False      23h
openshift-apiserver                        4.5.4     True        False         False      52m
openshift-controller-manager               4.5.4     True        False         False      4h37m
openshift-samples                          4.5.4     True        False         False      23h
operator-lifecycle-manager                 4.5.4     True        False         False      23h
operator-lifecycle-manager-catalog         4.5.4     True        False         False      23h
operator-lifecycle-manager-packageserver   4.5.4     True        False         False      179m
service-ca                                 4.5.4     True        False         False      23h
storage                                    4.5.4     True        False         False      23h

[asimonel-redhat.com@bastion ~]$ oc project default
Now using project "default" on server "https://api.cluster-452f.dynamic.opentlc.com:6443".

oc new-app \
>     nodeshift/centos7-s2i-nodejs:12.x~https://github.com/vrutkovs/DuckHunt-JS
--> Found container image 5b0b75b (10 months old) from Docker Hub for "nodeshift/centos7-s2i-nodejs:12.x"

    Node.js 12.12.0 
    --------------- 
    Node.js  available as docker container is a base platform for building and running various Node.js  applications and frameworks. Node.js is a platform built on Chrome's JavaScript runtime for easily building fast, scalable network applications. Node.js uses an event-driven, non-blocking I/O model that makes it lightweight and efficient, perfect for data-intensive real-time applications that run across distributed devices.

    Tags: builder, nodejs, nodejs-12.12.0

    * An image stream tag will be created as "centos7-s2i-nodejs:12.x" that will track the source image
    * A source build using source code from https://github.com/vrutkovs/DuckHunt-JS will be created
      * The resulting image will be pushed to image stream tag "duckhunt-js:latest"
      * Every time "centos7-s2i-nodejs:12.x" changes a new build will be triggered

--> Creating resources ...
    imagestream.image.openshift.io "centos7-s2i-nodejs" created
    imagestream.image.openshift.io "duckhunt-js" created
    buildconfig.build.openshift.io "duckhunt-js" created
    deployment.apps "duckhunt-js" created
    service "duckhunt-js" created
--> Success
    Build scheduled, use 'oc logs -f bc/duckhunt-js' to track its progress.
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/duckhunt-js' 
    Run 'oc status' to view your app.

[asimonel-redhat.com@bastion ~]$ oc logs duckhunt-js-1-build -f
...
Storing signatures
Successfully pushed image-registry.openshift-image-registry.svc:5000/default/duckhunt-js@sha256:37894bbe41fca97ff21061c8981ae3a82e66d8a23ad42e4253cdb5c5778396ef
Push successful

[asimonel-redhat.com@bastion ~]$ oc get pods
NAME                           READY   STATUS      RESTARTS   AGE
duckhunt-js-1-build            0/1     Completed   0          3m12s
duckhunt-js-86b496d45b-g9567   1/1     Running     0          2m5s

[asimonel-redhat.com@bastion ~]$ oc get svc
NAME          TYPE           CLUSTER-IP      EXTERNAL-IP                            PORT(S)    AGE
duckhunt-js   ClusterIP      172.30.67.116   <none>                                 8080/TCP   3m50s
kubernetes    ClusterIP      172.30.0.1      <none>                                 443/TCP    23h
openshift     ExternalName   <none>          kubernetes.default.svc.cluster.local   <none>     23h

[asimonel-redhat.com@bastion ~]$ oc expose svc/duckhunt-js
route.route.openshift.io/duckhunt-js exposed

[asimonel-redhat.com@bastion ~]$ oc get route duckhunt-js
NAME          HOST/PORT                                                   PATH   SERVICES      PORT       TERMINATION   WILDCARD
duckhunt-js   duckhunt-js-default.apps.cluster-452f.dynamic.opentlc.com          duckhunt-js   8080-tcp                 None

[asimonel-redhat.com@bastion ~]$ oc delete deployment/duckhunt-js bc/duckhunt-js svc/duckhunt-js route/duckhunt-js
deployment.apps "duckhunt-js" deleted
buildconfig.build.openshift.io "duckhunt-js" deleted
service "duckhunt-js" deleted
route.route.openshift.io "duckhunt-js" deleted

[asimonel-redhat.com@bastion ~]$ oc get csv -n openshift-cnv  Running   0          4m22s
NAME                                      DISPLAY                    VERSION   REPLACES   PHASE
kubevirt-hyperconverged-operator.v2.4.0   OpenShift Virtualization   2.4.0                Succeeded

[asimonel-redhat.com@bastion ~]$ oc get pods -n openshift-cnv | grep -Ev "Running"
NAME                                                  READY   STATUS    RESTARTS   AGE

[asimonel-redhat.com@bastion ~]$ oc get nns -A 
NAME                              AGE
cluster-452f-rfnck-master-0       7m11s
cluster-452f-rfnck-master-1       7m2s
cluster-452f-rfnck-master-2       6m59s
cluster-452f-rfnck-worker-4n9sq   7m2s
cluster-452f-rfnck-worker-mfhzd   7m12s

[asimonel-redhat.com@bastion ~]$ oc get nns/cluster-452f-rfnck-worker-4n9sq -o yaml
apiVersion: nmstate.io/v1alpha1
kind: NodeNetworkState
metadata:
  creationTimestamp: "2020-09-01T05:30:01Z"
  generation: 1
  managedFields:
  - apiVersion: nmstate.io/v1alpha1
    fieldsType: FieldsV1
    fieldsV1:
...
status:
  currentState:
    dns-resolver:
      config:
        search: []
        server: []
      running:
        search:
        - cluster-452f.dynamic.opentlc.com
        - cluster-452f.dynamic.opentlc.com
        server:
        - 150.239.16.12
        - 150.239.16.11
        - 150.239.16.12
        - 150.239.16.11
    interfaces:
    - ipv4:
        enabled: false
      ipv6:
        enabled: false
      mac-address: 8a:4d:7b:d8:45:4a
      mtu: 8892
      name: br0
      state: down
      type: ovs-interface
    - ipv4:
        address:
        - ip: 10.0.2.143
          prefix-length: 16
        - ip: 10.0.0.7
          prefix-length: 16
        auto-dns: true
        auto-gateway: true
        auto-routes: true
        dhcp: true
        enabled: true
...

[asimonel-redhat.com@bastion ~]$  oc get nnce -n openshift-cnv
No resources found

[asimonel-redhat.com@bastion ~]$ oc project default
Already on project "default" on server "https://api.cluster-452f.dynamic.opentlc.com:6443".

[asimonel-redhat.com@bastion ~]$ cat << EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: nfs
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Delete
EOF
storageclass.storage.k8s.io/nfs created

[asimonel-redhat.com@bastion ~]$ oc get sc
NAME                 PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
nfs                  kubernetes.io/no-provisioner   Delete          Immediate              false                  17s
standard (default)   kubernetes.io/cinder           Delete          WaitForFirstConsumer   true                   23h

[asimonel-redhat.com@bastion ~]$ oc patch storageclass standard -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
storageclass.storage.k8s.io/standard patched

[asimonel-redhat.com@bastion ~]$ oc patch storageclass nfs -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
storageclass.storage.k8s.io/nfs patched

[asimonel-redhat.com@bastion ~]$ oc get sc
NAME            PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
nfs (default)   kubernetes.io/no-provisioner   Delete          Immediate              false                  2m2s
standard        kubernetes.io/cinder           Delete          WaitForFirstConsumer   true                   24h

[asimonel-redhat.com@bastion ~]$ ls -l /mnt/nfs/
total 0
drwxrwxrwx. 2 root root 6 Aug 31 02:08 four
drwxrwxrwx. 2 root root 6 Aug 31 02:08 one
drwxrwxrwx. 2 root root 6 Aug 31 02:08 three
drwxrwxrwx. 2 root root 6 Aug 31 02:08 two

[asimonel-redhat.com@bastion ~]$ ip a | grep 192
    inet 192.168.47.16/24 brd 192.168.47.255 scope global dynamic noprefixroute eth0

[asimonel-redhat.com@bastion ~]$ cat << EOF > nfs1.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv1
spec:
  accessModes:
  - ReadWriteOnce
  - ReadWriteMany
  capacity:
    storage: 10Gi
  nfs:
    path: /mnt/nfs/one
    server: 192.168.47.16
  persistentVolumeReclaimPolicy: Delete
  storageClassName: nfs
  volumeMode: Filesystem
EOF

[asimonel-redhat.com@bastion ~]$ oc apply -f nfs1.yaml
persistentvolume/nfs-pv1 created

[asimonel-redhat.com@bastion ~]$ oc get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
nfs-pv1   10Gi       RWO,RWX        Delete           Available           nfs                     56s

[asimonel-redhat.com@bastion ~]$ cat << EOF > nfs2.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv2
spec:
  accessModes:
  - ReadWriteOnce
  - ReadWriteMany
  capacity:
    storage: 10Gi
  nfs:
    path: /mnt/nfs/two
    server: 192.168.47.16
  persistentVolumeReclaimPolicy: Delete
  storageClassName: nfs
  volumeMode: Filesystem
EOF

[asimonel-redhat.com@bastion ~]$ oc apply -f nfs2.yaml
persistentvolume/nfs-pv2 created

[asimonel-redhat.com@bastion ~]$ oc get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
nfs-pv1   10Gi       RWO,RWX        Delete           Available           nfs                     2m16s
nfs-pv2   10Gi       RWO,RWX        Delete           Available           nfs                     12s

[asimonel-redhat.com@bastion ~]$ cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "centos8-nfs"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.2.2004-20200611.2.x86_64.qcow2"
spec:
  volumeMode: Filesystem
  storageClassName: nfs
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF
persistentvolumeclaim/centos8-nfs created

[asimonel-redhat.com@bastion ~]$ oc get pvc
NAME          STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
centos8-nfs   Bound    nfs-pv1   10Gi       RWO,RWX        nfs            5s

[asimonel-redhat.com@bastion ~]$ oc get pods
NAME                   READY   STATUS    RESTARTS   AGE
importer-centos8-nfs   1/1     Running   0          49s

[asimonel-redhat.com@bastion ~]$ oc logs importer-centos8-nfs -f
...
I0901 06:03:13.377883       1 qemu.go:212] 99.65
I0901 06:03:15.377155       1 data-processor.go:206] New phase: Resize
I0901 06:03:15.400063       1 data-processor.go:267] No need to resize image. Requested size: 10Gi, Image size: 10737418240.
I0901 06:03:15.400094       1 data-processor.go:206] New phase: Complete
I0901 06:03:15.400192       1 importer.go:175] Import complete

[asimonel-redhat.com@bastion ~]$ oc describe pod $(oc get pods | awk '/importer/ {print $1;}')
...
    Environment:
      IMPORTER_SOURCE:       http
      IMPORTER_ENDPOINT:     https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.2.2004-20200611.2.x86_64.qcow2
      IMPORTER_CONTENTTYPE:  kubevirt
      IMPORTER_IMAGE_SIZE:   10Gi

...

[asimonel-redhat.com@bastion ~]$ oc get pvc
NAME          STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
centos8-nfs   Bound    nfs-pv1   10Gi       RWO,RWX        nfs            12m

[asimonel-redhat.com@bastion ~]$ oc get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                 STORAGECLASS   REASON   AGE
nfs-pv1   10Gi       RWO,RWX        Delete           Bound       default/centos8-nfs   nfs                     17m
nfs-pv2   10Gi       RWO,RWX        Delete           Available                         nfs                     15m

[asimonel-redhat.com@bastion ~]$ ls -l /mnt/nfs/one/
total 2256116
-rw-r--r--. 1 root root 10737418240 Sep  1 02:03 disk.img

[asimonel-redhat.com@bastion ~]$ sudo qemu-img info /mnt/nfs/one/disk.img
image: /mnt/nfs/one/disk.img
file format: raw
virtual size: 10G (10737418240 bytes)
disk size: 2.2G

[asimonel-redhat.com@bastion ~]$ sudo file /mnt/nfs/one/disk.img
/mnt/nfs/one/disk.img: DOS/MBR boot sector

[asimonel-redhat.com@bastion ~]$ cat << EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: 50-set-selinux-for-hostpath-provisioner-worker
  labels:
    machineconfiguration.openshift.io/role: worker
spec:
  config:
    ignition:
      version: 2.2.0
    systemd:
      units:
        - contents: |
            [Unit]
            Description=Set SELinux chcon for hostpath provisioner
            Before=kubelet.service
 
            [Service]
            Type=oneshot
            RemainAfterExit=yes
            ExecStartPre=-mkdir -p /var/hpvolumes
            ExecStart=/usr/bin/chcon -Rt container_file_t /var/hpvolumes
 
            [Install]
            WantedBy=multi-user.target
          enabled: true
          name: hostpath-provisioner.service
EOF
machineconfig.machineconfiguration.openshift.io/50-set-selinux-for-hostpath-provisioner-worker created

[asimonel-redhat.com@bastion ~]$ watch -n2 oc get machineconfigpool 
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACH
INECOUNT   AGE
master   rendered-master-2d601e74b0751f834844620144122544   True      False      False      3              3                   3                     0
           24h
worker   rendered-worker-c0b3acd8c4a4bd132de1f5c8d395ff9b   True      False      False      2              2                   2                     0

[asimonel-redhat.com@bastion ~]$ oc get machineconfigpool worker -o=jsonpath="{.status.conditions[?(@.type=='Updated')].status}{\"\n\"}"
True

[asimonel-redhat.com@bastion ~]$ oc get nodes
NAME                              STATUS   ROLES    AGE   VERSION
cluster-452f-rfnck-master-0       Ready    master   24h   v1.18.3+012b3ec
cluster-452f-rfnck-master-1       Ready    master   24h   v1.18.3+012b3ec
cluster-452f-rfnck-master-2       Ready    master   24h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-4n9sq   Ready    worker   24h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-mfhzd   Ready    worker   24h   v1.18.3+012b3ec

[asimonel-redhat.com@bastion ~]$ cat << EOF | oc apply -f -
apiVersion: hostpathprovisioner.kubevirt.io/v1alpha1
kind: HostPathProvisioner
metadata:
  name: hostpath-provisioner
spec:
  imagePullPolicy: IfNotPresent
  pathConfig:
    path: "/var/hpvolumes"
    useNamingPrefix: "false"
EOF
hostpathprovisioner.hostpathprovisioner.kubevirt.io/hostpath-provisioner created

[asimonel-redhat.com@bastion ~]$ oc get pods -n openshift-cnv | grep hostpath
hostpath-provisioner-gd2z8                            1/1     Running   0          42s
hostpath-provisioner-gjzm7                            1/1     Running   0          42s
hostpath-provisioner-operator-56ffbb99d9-rpdsw        1/1     Running   0          7m57s

[asimonel-redhat.com@bastion ~]$ cat << EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hostpath-provisioner
provisioner: kubevirt.io/hostpath-provisioner
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF
storageclass.storage.k8s.io/hostpath-provisioner created

[asimonel-redhat.com@bastion ~]$ cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "centos8-hostpath"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.2.2004-20200611.2.x86_64.qcow2"
spec:
  volumeMode: Filesystem
  storageClassName: hostpath-provisioner
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF
persistentvolumeclaim/centos8-hostpath created

[asimonel-redhat.com@bastion ~]$ oc get storageclass
NAME                   PROVISIONER                        RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
hostpath-provisioner   kubevirt.io/hostpath-provisioner   Delete          WaitForFirstConsumer   false                  87s
nfs (default)          kubernetes.io/no-provisioner       Delete          Immediate              false                  40m
standard               kubernetes.io/cinder               Delete          WaitForFirstConsumer   true                   24h

[asimonel-redhat.com@bastion ~]$ oc get pvc centos8-hostpath 
NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
centos8-hostpath   Bound    pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676   29Gi       RWO            hostpath-provisioner   52s

[asimonel-redhat.com@bastion ~]$ oc get pods
NAME                        READY   STATUS    RESTARTS   AGE
importer-centos8-hostpath   1/1     Running   0          4m2s

[asimonel-redhat.com@bastion ~]$ oc logs importer-centos8-hostpath -f
...

[asimonel-redhat.com@bastion ~]$ oc get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                      STORAGECLASS           REASON   AGE
nfs-pv1                                    10Gi       RWO,RWX        Delete           Bound       default/centos8-nfs        nfs                             39m
nfs-pv2                                    10Gi       RWO,RWX        Delete           Available                              nfs                             37m
pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676   29Gi       RWO            Delete           Bound       default/centos8-hostpath   hostpath-provisioner            4m39s

[asimonel-redhat.com@bastion ~]$ oc describe pv/pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676 
Name:              pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676
Labels:            <none>
Annotations:       hostPathProvisionerIdentity: kubevirt.io/hostpath-provisioner
                   kubevirt.io/provisionOnNode: cluster-452f-rfnck-worker-mfhzd
                   pv.kubernetes.io/provisioned-by: kubevirt.io/hostpath-provisioner
Finalizers:        [kubernetes.io/pv-protection]
StorageClass:      hostpath-provisioner
Status:            Bound
Claim:             default/centos8-hostpath
Reclaim Policy:    Delete
Access Modes:      RWO
VolumeMode:        Filesystem
Capacity:          29Gi
Node Affinity:     
  Required Terms:  
    Term 0:        kubernetes.io/hostname in [cluster-452f-rfnck-worker-mfhzd]
Message:           
Source:
    Type:          HostPath (bare host directory volume)
    Path:          /var/hpvolumes/pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676
    HostPathType:  
Events:            <none>

[asimonel-redhat.com@bastion ~]$ oc debug node/cluster-452f-rfnck-worker-mfhzd
Starting pod/cluster-452f-rfnck-worker-mfhzd-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.0.1.215
If you don't see a command prompt, try pressing enter.
sh-4.2# chroot /host
sh-4.4# ls -l /var/hpvolumes/pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676/disk.img 
-rw-r--r--. 1 root root 10737418240 Sep  1 06:32 /var/hpvolumes/pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676/disk.img
sh-4.4# file /var/hpvolumes/pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676/disk.img 
/var/hpvolumes/pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676/disk.img: DOS/MBR boot sector
sh-4.4# exit
exit
sh-4.2# exit
exit

Removing debug pod ...

[asimonel-redhat.com@bastion ~]$ oc get nodes
NAME                              STATUS   ROLES    AGE   VERSION
cluster-452f-rfnck-master-0       Ready    master   25h   v1.18.3+012b3ec
cluster-452f-rfnck-master-1       Ready    master   25h   v1.18.3+012b3ec
cluster-452f-rfnck-master-2       Ready    master   25h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-4n9sq   Ready    worker   24h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-mfhzd   Ready    worker   24h   v1.18.3+012b3ec
[asimonel-redhat.com@bastion ~]$ 

apiVersion: nmstate.io/v1alpha1
kind: NodeNetworkState
metadata:
  creationTimestamp: "2020-09-01T05:30:01Z"
  generation: 1
  managedFields:
  - apiVersion: nmstate.io/v1alpha1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:ownerReferences:
          .: {}
          k:{"uid":"1ebacf52-d3a1-4cc0-91af-eb389ef9edba"}:
            .: {}
            f:apiVersion: {}
            f:kind: {}
            f:name: {}
            f:uid: {}
      f:status:
        .: {}
        f:currentState:
          .: {}
          f:dns-resolver:
            .: {}
            f:config:
              .: {}
              f:search: {}
              f:server: {}
            f:running:
              .: {}
              f:search: {}
              f:server: {}
          f:interfaces: {}
          f:route-rules:
            .: {}
            f:config: {}
          f:routes:
            .: {}
            f:config: {}
            f:running: {}
        f:lastSuccessfulUpdateTime: {}
    manager: kubernetes-nmstate
    operation: Update
    time: "2020-09-01T06:35:41Z"
  name: cluster-452f-rfnck-worker-4n9sq
  ownerReferences:
  - apiVersion: v1
    kind: Node
    name: cluster-452f-rfnck-worker-4n9sq
    uid: 1ebacf52-d3a1-4cc0-91af-eb389ef9edba
  resourceVersion: "506398"
  selfLink: /apis/nmstate.io/v1alpha1/nodenetworkstates/cluster-452f-rfnck-worker-4n9sq
  uid: 6d37cd98-e5d8-4ea2-87ca-90474ff0ff58
status:
  currentState:
    dns-resolver:
      config:
        search: []
        server: []
      running:
        search:
        - cluster-452f.dynamic.opentlc.com
        - cluster-452f.dynamic.opentlc.com
        server:
        - 150.239.16.12
        - 150.239.16.11
        - 150.239.16.12
        - 150.239.16.11
    interfaces:
    - ipv4:
        enabled: false
      ipv6:
        enabled: false
      mac-address: 72:5d:e1:88:2d:49
      mtu: 8892
      name: br0
      state: down
      type: ovs-interface
    - ipv4:
        address:
        - ip: 10.0.2.143
          prefix-length: 16
        - ip: 10.0.0.7
          prefix-length: 16
        auto-dns: true
        auto-gateway: true
        auto-routes: true
        dhcp: true
        enabled: true
      ipv6:
        address:
        - ip: fe80::ffd5:24e8:e19:3110
          prefix-length: 64
        auto-dns: true
        auto-gateway: true
        auto-routes: true
        autoconf: true
        dhcp: true
        enabled: true
      mac-address: FA:16:3E:12:EF:BD
      mtu: 8942
      name: ens3
      state: up
      type: ethernet
    - ipv4:
        address:
        - ip: 192.168.47.212
          prefix-length: 24
        auto-dns: true
        auto-gateway: true
        auto-routes: true
        dhcp: true
        enabled: true
      ipv6:
        address:
        - ip: fe80::a036:640f:5074:7d29
          prefix-length: 64
        auto-dns: true
        auto-gateway: true
        auto-routes: true
        autoconf: true
        dhcp: true
        enabled: true
      mac-address: FA:16:3E:EE:53:76
      mtu: 8942
      name: ens7
      state: up
      type: ethernet
    - ipv4:
        enabled: false
      ipv6:
        enabled: false
      mtu: 65536
      name: lo
      state: down
      type: unknown
    - ipv4:
        enabled: false
      ipv6:
        enabled: false
      mac-address: 6a:32:aa:69:da:01
      mtu: 8892
      name: tun0
      state: down
      type: ovs-interface
...


cat << EOF | oc apply -f -
apiVersion: nmstate.io/v1alpha1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: br1-ens7-policy-workers
spec:
  nodeSelector:
    node-role.kubernetes.io/worker: ""
  desiredState:
    interfaces:
      - name: br1
        description: Linux bridge with ens6 as a port
        type: linux-bridge
        state: up
        ipv4:
          dhcp: true
          enabled: true
        bridge:
          options:
            stp:
              enabled: false
          port:
            - name: ens7
EOF
nodenetworkconfigurationpolicy.nmstate.io/br1-ens7-policy-workers created

[asimonel-redhat.com@bastion ~]$ oc get nncp
NAME                      STATUS
br1-ens7-policy-workers   SuccessfullyConfigured

[asimonel-redhat.com@bastion ~]$ oc get nnce
NAME                                                      STATUS
cluster-452f-rfnck-master-0.br1-ens7-policy-workers       NodeSelectorNotMatching
cluster-452f-rfnck-master-1.br1-ens7-policy-workers       NodeSelectorNotMatching
cluster-452f-rfnck-master-2.br1-ens7-policy-workers       NodeSelectorNotMatching
cluster-452f-rfnck-worker-4n9sq.br1-ens7-policy-workers   SuccessfullyConfigured
cluster-452f-rfnck-worker-mfhzd.br1-ens7-policy-workers   SuccessfullyConfigured

oc get nncp/br1-ens7-policy-workers -o yaml

[asimonel-redhat.com@bastion ~]$ oc debug node/cluster-452f-rfnck-worker-4n9sq
Starting pod/cluster-452f-rfnck-worker-4n9sq-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.0.2.143
If you don't see a command prompt, try pressing enter.
sh-4.2# chroot /host
sh-4.4# ip a s | grep br1 
3: ens7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8942 qdisc fq_codel master br1 state UP group default qlen 1000
61: br1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8942 qdisc noqueue state UP group default qlen 1000
    inet 192.168.47.212/24 brd 192.168.47.255 scope global dynamic noprefixroute br1
sh-4.4# exit
exit
sh-4.2# exit
exit

Removing debug pod ...

[asimonel-redhat.com@bastion ~]$ cat << EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: tuning-bridge-fixed
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br1
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "groot",
    "plugins": [
      {
        "type": "cnv-bridge",
        "bridge": "br1"
      },
      {
        "type": "tuning"
      }
    ]
  }'
EOF
networkattachmentdefinition.k8s.cni.cncf.io/tuning-bridge-fixed created

[asimonel-redhat.com@bastion ~]$ oc api-resources | grep -i NetworkAttachmentDefinition 
network-attachment-definitions        net-attach-def         k8s.cni.cncf.io                             true         NetworkAttachmentDefinition

[asimonel-redhat.com@bastion ~]$ oc get net-attach-def 
NAME                  AGE
tuning-bridge-fixed   2m35s

[asimonel-redhat.com@bastion ~]$ oc get pvc
NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
centos8-hostpath   Bound    pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676   29Gi       RWO            hostpath-provisioner   32m
centos8-nfs        Bound    nfs-pv1                                    10Gi       RWO,RWX        nfs                    63m

cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  annotations:
    kubevirt.io/latest-observed-api-version: v1alpha3
    kubevirt.io/storage-observed-api-version: v1alpha3
    name.os.template.kubevirt.io/centos8.0: CentOS 8
  name: centos8-server-nfs
  namespace: default
  labels:
    app: centos8-nfs
    flavor.template.kubevirt.io/small: 'true'
    os.template.kubevirt.io/rhel8.2: 'true'
    vm.kubevirt.io/template: rhel8-server-small-v0.10.0
    vm.kubevirt.io/template.namespace: openshift
    vm.kubevirt.io/template.revision: '1'
    vm.kubevirt.io/template.version: v0.11.2
    workload.template.kubevirt.io/server: 'true'
spec:
  running: true
  template:
    metadata:
      creationTimestamp: null
      labels:
        flavor.template.kubevirt.io/small: 'true'
        os.template.kubevirt.io/rhel8.2: 'true'
        vm.kubevirt.io/template: rhel8-server-small-v0.10.0
        vm.kubevirt.io/template.namespace: openshift
        vm.kubevirt.io/template.revision: '1'
        vm.kubevirt.io/template.version: v0.11.2
        workload.template.kubevirt.io/server: 'true'
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
            - bootOrder: 1
              disk:
                bus: virtio
              name: disk0
            - disk:
                bus: virtio
              name: cloudinitdisk
          interfaces:
            - bridge: {}
              macAddress: 'de:ad:be:ef:00:01'
              model: e1000
              name:  tuning-bridge-fixed
          rng: {}
        machine:
          type: pc-q35-rhel8.2.0
        resources:
          requests:
            memory: 2Gi
      evictionStrategy: LiveMigrate
      hostname: centos8-server-nfs
      networks:
        - multus:
            networkName: tuning-bridge-fixed
          name: tuning-bridge-fixed
      terminationGracePeriodSeconds: 0
      volumes:
        - name: disk0
          persistentVolumeClaim:
            claimName: centos8-nfs
        - cloudInitNoCloud:
            userData: |-
                #cloud-config
                password: redhat
                chpasswd: {expire: False}
                write_files:
                  - content: |
                      # hi
                      DEVICE=eth0
                      HWADDR=de:ad:be:ef:00:01
                      ONBOOT=yes
                      TYPE=Ethernet
                      USERCTL=no
                      IPADDR=192.168.47.5
                      PREFIX=24
                      GATEWAY=192.168.47.1   
                      DNS1=150.239.16.11
                      DNS2=150.239.16.12
                    path:  /etc/sysconfig/network-scripts/ifcfg-eth0
                    permissions: '0644'
                runcmd:
                  - ifdown eth0
                  - ifup eth0
                  - systemctl restart qemu-guest-agent.service
          name: cloudinitdisk
EOF

[asimonel-redhat.com@bastion ~]$ oc get vm
NAME                 AGE   VOLUME
centos8-server-nfs   20s   

[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                 AGE   PHASE     IP    NODENAME
centos8-server-nfs   35s   Running         cluster-452f-rfnck-worker-mfhzd

[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                 AGE   PHASE     IP                NODENAME
centos8-server-nfs   76s   Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd

[asimonel-redhat.com@bastion ~]$ oc get pods | grep virt
virt-launcher-centos8-server-nfs-8flqg   1/1     Running   0          109s

[asimonel-redhat.com@bastion ~]$ sudo yum install kubevirt-virtctl -y

[asimonel-redhat.com@bastion ~]$ oc exec -it  virt-launcher-centos8-server-nfs-8flqg /bin/bash
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl kubectl exec [POD] -- [COMMAND] instead.

[root@centos8-server-nfs /]# ps awwx
    PID TTY      STAT   TIME COMMAND
      1 ?        Ssl    0:00 /usr/bin/virt-launcher --qemu-timeout 5m --name centos8-server-nfs --uid 1cca03ef-d80c-4aa1-bd95-9184eac2d381 --namespace default --kubevirt-share-dir /var/run/kubevirt --ephemeral-disk-dir /var/run/kubevirt-ephemeral-disks --container-disk-dir /var/run/kubevirt/container-disks --readiness-file /var/run/kubevirt-infra/healthy --grace-period-seconds 15 --hook-sidecars 0 --less-pvc-space-toleration 10 --ovmf-path /usr/share/OVMF
     16 ?        Sl     0:00 /usr/bin/virt-launcher --qemu-timeout 5m --name centos8-server-nfs --uid 1cca03ef-d80c-4aa1-bd95-9184eac2d381 --namespace default --kubevirt-share-dir /var/run/kubevirt --ephemeral-disk-dir /var/run/kubevirt-ephemeral-disks --container-disk-dir /var/run/kubevirt/container-disks --readiness-file /var/run/kubevirt-infra/healthy --grace-period-seconds 15 --hook-sidecars 0 --less-pvc-space-toleration 10 --ovmf-path /usr/share/OVMF --no-fork true
     26 ?        Sl     0:00 /usr/sbin/libvirtd
     27 ?        S      0:00 /usr/sbin/virtlogd -f /etc/libvirt/virtlogd.conf
     74 ?        Sl     0:59 /usr/libexec/qemu-kvm -name guest=default_centos8-server-nfs,debug-threads=on -S -object secret,id=masterKey0,format=raw,file=/var/lib/libvirt/qemu/domain-1-default_centos8-serv/master-key.aes -machine pc-q35-rhel8.2.0,accel=kvm,usb=off,dump-guest-core=off -cpu Cascadelake-Server,ss=on,hypervisor=on,tsc-adjust=on,umip=on,pku=on,md-clear=on,stibp=on,arch-capabilities=on,ibpb=on,amd-ssbd=on,rdctl-no=on,ibrs-all=on,skip-l1dfl-vmentry=on,mds-no=on,tsx-ctrl=on -m 2048 -overcommit mem-lock=off -smp 1,sockets=1,dies=1,cores=1,threads=1 -object iothread,id=iothread1 -uuid fe1d472c-1eb9-52e3-a84a-d6390ac9d37b -smbios type=1,manufacturer=Red Hat,product=Container-native virtualization,version=2.4.0,uuid=fe1d472c-1eb9-52e3-a84a-d6390ac9d37b,sku=2.4.0,family=Red Hat -no-user-config -nodefaults -chardev socket,id=charmonitor,fd=20,server,nowait -mon chardev=charmonitor,id=monitor,mode=control -rtc base=utc -no-shutdown -boot strict=on -device pcie-root-port,port=0x10,chassis=1,id=pci.1,bus=pcie.0,multifunction=on,addr=0x2 -device pcie-pci-bridge,id=pci.2,bus=pci.1,addr=0x0 -device pcie-root-port,port=0x11,chassis=3,id=pci.3,bus=pcie.0,addr=0x2.0x1 -device pcie-root-port,port=0x12,chassis=4,id=pci.4,bus=pcie.0,addr=0x2.0x2 -device pcie-root-port,port=0x13,chassis=5,id=pci.5,bus=pcie.0,addr=0x2.0x3 -device pcie-root-port,port=0x14,chassis=6,id=pci.6,bus=pcie.0,addr=0x2.0x4 -device pcie-root-port,port=0x15,chassis=7,id=pci.7,bus=pcie.0,addr=0x2.0x5 -device virtio-serial-pci,id=virtio-serial0,bus=pci.3,addr=0x0 -blockdev {"driver":"file","filename":"/var/run/kubevirt-private/vmi-disks/disk0/disk.img","node-name":"libvirt-2-storage","cache":{"direct":true,"no-flush":false},"auto-read-only":true,"discard":"unmap"} -blockdev {"node-name":"libvirt-2-format","read-only":false,"cache":{"direct":true,"no-flush":false},"driver":"raw","file":"libvirt-2-storage"} -device virtio-blk-pci,scsi=off,bus=pci.4,addr=0x0,drive=libvirt-2-format,id=ua-disk0,bootindex=1,write-cache=on -blockdev {"driver":"file","filename":"/var/run/kubevirt-ephemeral-disks/cloud-init-data/default/centos8-server-nfs/noCloud.iso","node-name":"libvirt-1-storage","cache":{"direct":true,"no-flush":false},"auto-read-only":true,"discard":"unmap"} -blockdev {"node-name":"libvirt-1-format","read-only":false,"cache":{"direct":true,"no-flush":false},"driver":"raw","file":"libvirt-1-storage"} -device virtio-blk-pci,scsi=off,bus=pci.5,addr=0x0,drive=libvirt-1-format,id=ua-cloudinitdisk,write-cache=on -netdev tap,fd=22,id=hostua-tuning-bridge-fixed -device e1000,netdev=hostua-tuning-bridge-fixed,id=ua-tuning-bridge-fixed,mac=de:ad:be:ef:00:01,bus=pci.2,addr=0x1 -chardev socket,id=charserial0,fd=23,server,nowait -device isa-serial,chardev=charserial0,id=serial0 -chardev socket,id=charchannel0,fd=24,server,nowait -device virtserialport,bus=virtio-serial0.0,nr=1,chardev=charchannel0,id=channel0,name=org.qemu.guest_agent.0 -vnc vnc=unix:/var/run/kubevirt-private/1cca03ef-d80c-4aa1-bd95-9184eac2d381/virt-vnc -device VGA,id=video0,vgamem_mb=16,bus=pcie.0,addr=0x1 -object rng-random,id=objrng0,filename=/dev/urandom -device virtio-rng-pci,rng=objrng0,id=rng0,bus=pci.6,addr=0x0 -sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny -msg timestamp=on
   1992 pts/0    Ss     0:00 /bin/bash
   2412 pts/0    R+     0:00 ps awwx
[root@centos8-server-nfs /]# virsh list --all
 Id   Name                         State
--------------------------------------------
 1    default_centos8-server-nfs   running

[root@centos8-server-nfs /]# virsh domblklist 1
 Target   Source
----------------------------------------------------------------------------------------------------
 vda      /var/run/kubevirt-private/vmi-disks/disk0/disk.img
 vdb      /var/run/kubevirt-ephemeral-disks/cloud-init-data/default/centos8-server-nfs/noCloud.iso

[root@centos8-server-nfs /]# mount | grep nfs
192.168.47.16:/mnt/nfs/one on /run/kubevirt-private/vmi-disks/disk0 type nfs4 (rw,relatime,vers=4.2,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.47.232,local_lock=none,addr=192.168.47.16)

[root@centos8-server-nfs /]# virsh domiflist 1
 Interface   Type     Source     Model   MAC
------------------------------------------------------------
 vnet0       bridge   k6t-net1   e1000   de:ad:be:ef:00:01

 [root@centos8-server-nfs /]# ip link | grep -A2 k6t-net1
5: net1@if16: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master k6t-net1 state UP mode DEFAULT group default 
    link/ether de:ad:be:c9:41:6b brd ff:ff:ff:ff:ff:ff link-netnsid 0
6: k6t-net1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default 
    link/ether de:ad:be:c9:41:6b brd ff:ff:ff:ff:ff:ff
7: vnet0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master k6t-net1 state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether fe:ad:be:ef:00:01 brd ff:ff:ff:ff:ff:ff

[root@centos8-server-nfs /]# virsh dumpxml 1 | grep -A8 "interface type"
    <interface type='bridge'>
      <mac address='de:ad:be:ef:00:01'/>
      <source bridge='k6t-net1'/>
      <target dev='vnet0'/>
      <model type='e1000'/>
      <mtu size='1500'/>
      <alias name='ua-tuning-bridge-fixed'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x01' function='0x0'/>
    </interface>

[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                 AGE   PHASE     IP                NODENAME
centos8-server-nfs   10m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd

[asimonel-redhat.com@bastion ~]$ oc debug node/cluster-452f-rfnck-worker-mfhzd
...
sh-4.2# chroot /host
sh-4.4# ip a | grep br1 
3: ens7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8942 qdisc fq_codel master br1 state UP group default qlen 1000
14: br1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    inet 192.168.47.232/24 brd 192.168.47.255 scope global dynamic noprefixroute br1
16: veth0395fbc1@if5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br1 state UP group default 
sh-4.4# ip link show dev veth0395fbc1 
16: veth0395fbc1@if5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br1 state UP mode DEFAULT group default 
    link/ether 2e:65:f1:40:b1:cd brd ff:ff:ff:ff:ff:ff link-netns 92a4b424-f154-4216-9987-825ed313cc51
sh-4.4# export ifindex=16
sh-4.4# ip -o link | grep ^$ifindex: | sed -n -e 's/.*\(veth[[:alnum:]]*@if[[:digit:]]*\).*/\1/p'
veth0395fbc1@if5

[asimonel-redhat.com@bastion ~]$ oc project default
Already on project "default" on server "https://api.cluster-452f.dynamic.opentlc.com:6443".

cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  annotations:
    kubevirt.io/latest-observed-api-version: v1alpha3
    kubevirt.io/storage-observed-api-version: v1alpha3
    name.os.template.kubevirt.io/centos8.0: CentOS 8
  name: centos8-server-hostpath
  namespace: default
  labels:
    app: centos8-server-hostpath
    flavor.template.kubevirt.io/small: 'true'
    os.template.kubevirt.io/rhel8.2: 'true'
    vm.kubevirt.io/template: rhel8-server-small-v0.10.0
    vm.kubevirt.io/template.namespace: openshift
    vm.kubevirt.io/template.revision: '1'
    vm.kubevirt.io/template.version: v0.11.2
    workload.template.kubevirt.io/server: 'true'
spec:
  running: true
  template:
    metadata:
      creationTimestamp: null
      labels:
        flavor.template.kubevirt.io/small: 'true'
        os.template.kubevirt.io/rhel8.2: 'true'
        vm.kubevirt.io/template: rhel8-server-small-v0.10.0
        vm.kubevirt.io/template.namespace: openshift
        vm.kubevirt.io/template.revision: '1'
        vm.kubevirt.io/template.version: v0.11.2
        workload.template.kubevirt.io/server: 'true'
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
            - bootOrder: 1
              disk:
                bus: sata
              name: centos8-hostpath
            - disk:
                bus: virtio
              name: cloudinitdisk
          interfaces:
            - bridge: {}
              macAddress: 'de:ad:be:ef:00:02'
              model: e1000
              name:  tuning-bridge-fixed
          rng: {}
        machine:
          type: pc-q35-rhel8.2.0
        resources:
          requests:
            memory: 2Gi
      evictionStrategy: LiveMigrate
      hostname: centos8-server-hostpath
      networks:
        - multus:
            networkName: tuning-bridge-fixed
          name: tuning-bridge-fixed
      terminationGracePeriodSeconds: 0
      volumes:
        - name: centos8-hostpath
          persistentVolumeClaim:
            claimName: centos8-hostpath
        - cloudInitNoCloud:
            userData: |-
                #cloud-config
                password: redhat
                chpasswd: {expire: False}
                write_files:
                  - content: |
                      # hi
                      DEVICE=eth0
                      HWADDR=de:ad:be:ef:00:02
                      ONBOOT=yes
                      TYPE=Ethernet
                      USERCTL=no
                      IPADDR=192.168.47.6
                      PREFIX=24
                      GATEWAY=192.168.47.1   
                      DNS1=150.239.16.11
                      DNS2=150.239.16.12
                    path:  /etc/sysconfig/network-scripts/ifcfg-eth0
                    permissions: '0644'
                runcmd:
                  - ifdown eth0
                  - ifup eth0
                  - systemctl restart qemu-guest-agent.service
          name: cloudinitdisk
EOF
virtualmachine.kubevirt.io/centos8-server-hostpath created

[asimonel-redhat.com@bastion ~]$ oc get pods
NAME                                          READY   STATUS    RESTARTS   AGE
virt-launcher-centos8-server-hostpath-79b9g   1/1     Running   0          75s
virt-launcher-centos8-server-nfs-8flqg        1/1     Running   0          22m

[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                      AGE   PHASE     IP                NODENAME
centos8-server-hostpath   88s   Running   192.168.47.6/24   cluster-452f-rfnck-worker-mfhzd
centos8-server-nfs        22m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd

[asimonel-redhat.com@bastion ~]$ oc describe pod virt-launcher-centos8-server-hostpath-79b9g
...


[asimonel-redhat.com@bastion ~]$ oc exec -it virt-launcher-centos8-server-hostpath-79b9g -- /bin/bash

[root@centos8-server-hostpath /]# virsh domblklist 1
 Target   Source
---------------------------------------------------------------------------------------------------------
 sda      /var/run/kubevirt-private/vmi-disks/centos8-hostpath/disk.img
 vda      /var/run/kubevirt-ephemeral-disks/cloud-init-data/default/centos8-server-hostpath/noCloud.iso

 [root@centos8-server-hostpath /]# mount | grep centos8
/dev/mapper/coreos-luks-root-nocrypt on /run/kubevirt-private/vmi-disks/centos8-hostpath type xfs (rw,relatime,seclabel,attr2,inode64,prjquota)

[asimonel-redhat.com@bastion ~]$ oc get vmi/centos8-server-hostpath
NAME                      AGE     PHASE     IP                NODENAME
centos8-server-hostpath   6m37s   Running   192.168.47.6/24   cluster-452f-rfnck-worker-mfhzd

[asimonel-redhat.com@bastion ~]$ oc get pods | grep centos8-server-hostpath
virt-launcher-centos8-server-hostpath-79b9g   1/1     Running   0          7m14s

[asimonel-redhat.com@bastion ~]$ oc describe pod virt-launcher-centos8-server-hostpath-79b9g | awk -F// '/Container ID/ {print $2;}' | tail -1
c20b8a802dbfde32870e0b048c98f9fb5f9c12460d1cd475b113aa4934034fa2

oc debug node/cluster-452f-rfnck-worker-mfhzd
...
sh-4.2# chroot /host
sh-4.4# crictl inspect c20b8a802dbfde32870e0b048c98f9fb5f9c12460d1cd475b113aa4934034fa2 | grep -A4 centos8-hostpath
        "containerPath": "/var/run/kubevirt-private/vmi-disks/centos8-hostpath",
        "hostPath": "/var/hpvolumes/pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676",
        "propagation": "PROPAGATION_PRIVATE",
        "readonly": false,
        "selinuxRelabel": false
--
          "destination": "/var/run/kubevirt-private/vmi-disks/centos8-hostpath",
          "type": "bind",
          "source": "/var/hpvolumes/pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676",
          "options": [
            "rw",
--
        "io.kubernetes.cri-o.Volumes": "[{\"container_path\":\"/etc/hosts\",\"host_path\":\"/var/lib/kubelet/pods/072048cb-ea90-4e94-b4bf-a498e9e4563b/etc-hosts\",\"readonly\":false},{\"container_path\":\"/dev/termination-log\",\"host_path\":\"/var/lib/kubelet/pods/072048cb-ea90-4e94-b4bf-a498e9e4563b/containers/compute/1a13867f\",\"readonly\":false},{\"container_path\":\"/var/run/libvirt\",\"host_path\":\"/var/lib/kubelet/pods/072048cb-ea90-4e94-b4bf-a498e9e4563b/volumes/kubernetes.io~empty-dir/libvirt-runtime\",\"readonly\":false},{\"container_path\":\"/var/run/kubevirt-infra\",\"host_path\":\"/var/lib/kubelet/pods/072048cb-ea90-4e94-b4bf-a498e9e4563b/volumes/kubernetes.io~empty-dir/infra-ready-mount\",\"readonly\":false},{\"container_path\":\"/var/run/kubevirt-ephemeral-disks\",\"host_path\":\"/var/lib/kubelet/pods/072048cb-ea90-4e94-b4bf-a498e9e4563b/volumes/kubernetes.io~empty-dir/ephemeral-disks\",\"readonly\":false},{\"container_path\":\"/var/run/kubevirt/sockets\",\"host_path\":\"/var/lib/kubelet/pods/072048cb-ea90-4e94-b4bf-a498e9e4563b/volumes/kubernetes.io~empty-dir/sockets\",\"readonly\":false},{\"container_path\":\"/var/run/kubevirt/container-disks\",\"host_path\":\"/var/lib/kubelet/pods/072048cb-ea90-4e94-b4bf-a498e9e4563b/volumes/kubernetes.io~empty-dir/container-disks\",\"readonly\":false},{\"container_path\":\"/var/run/kubevirt-private/vmi-disks/centos8-hostpath\",\"host_path\":\"/var/hpvolumes/pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676\",\"readonly\":false}]",
        "io.kubernetes.pod.name": "virt-launcher-centos8-server-hostpath-79b9g",
        "io.kubernetes.pod.namespace": "default",
        "io.kubernetes.pod.terminationGracePeriod": "30",
        "io.kubernetes.pod.uid": "072048cb-ea90-4e94-b4bf-a498e9e4563b",
sh-4.4# exit
exit
sh-4.2# exit
exit

Removing debug pod ...

[asimonel-redhat.com@bastion ~]$ oc project default
Already on project "default" on server "https://api.cluster-452f.dynamic.opentlc.com:6443".

[asimonel-redhat.com@bastion ~]$  oc get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                      STORAGECLASS           REASON   AGE
nfs-pv1                                    10Gi       RWO,RWX        Delete           Bound       default/centos8-nfs        nfs                             107m
nfs-pv2                                    10Gi       RWO,RWX        Delete           Available                              nfs                             105m
pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676   29Gi       RWO            Delete           Bound       default/centos8-hostpath   hostpath-provisioner            72m

cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "centos7-clone-nfs"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
spec:
  volumeMode: Filesystem
  storageClassName: nfs
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF
persistentvolumeclaim/centos7-clone-nfs created

[asimonel-redhat.com@bastion ~]$ oc get pods
NAME                                          READY   STATUS    RESTARTS   AGE
importer-centos7-clone-nfs                    1/1     Running   0          17s
virt-launcher-centos8-server-hostpath-79b9g   1/1     Running   0          16m
virt-launcher-centos8-server-nfs-8flqg        1/1     Running   0          37m

[asimonel-redhat.com@bastion ~]$ oc get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                       STORAGECLASS           REASON   AGE
nfs-pv1                                    10Gi       RWO,RWX        Delete           Bound    default/centos8-nfs         nfs                             110m
nfs-pv2                                    10Gi       RWO,RWX        Delete           Bound    default/centos7-clone-nfs   nfs                             108m
pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676   29Gi       RWO            Delete           Bound    default/centos8-hostpath    hostpath-provisioner            75m
[asimonel-redhat.com@bastion ~]$ oc get pvc
NAME                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
centos7-clone-nfs   Bound    nfs-pv2                                    10Gi       RWO,RWX        nfs                    97s
centos8-hostpath    Bound    pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676   29Gi       RWO            hostpath-provisioner   75m
centos8-nfs         Bound    nfs-pv1                                    10Gi       RWO,RWX        nfs                    106m

cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
 annotations:
   kubevirt.io/latest-observed-api-version: v1alpha3
   kubevirt.io/storage-observed-api-version: v1alpha3
   name.os.template.kubevirt.io/centos7.0: CentOS 7
 name: centos7-clone-nfs
 namespace: default
 labels:
   app: centos7-clone-nfs
   flavor.template.kubevirt.io/small: 'true'
   os.template.kubevirt.io/rhel7.9: 'true'
   vm.kubevirt.io/template: rhel7-server-small-v0.7.0
   vm.kubevirt.io/template.namespace: openshift
   vm.kubevirt.io/template.revision: '1'
   vm.kubevirt.io/template.version: v0.11.2
   workload.template.kubevirt.io/server: 'true'
spec:
 running: true
 template:
   metadata:
     creationTimestamp: null
     labels:
       flavor.template.kubevirt.io/small: 'true'
       os.template.kubevirt.io/rhel7.9: 'true'
       vm.kubevirt.io/template: rhel7-server-small-v0.7.0
       vm.kubevirt.io/template.namespace: openshift
       vm.kubevirt.io/template.revision: '1'
       vm.kubevirt.io/template.version: v0.11.2
   spec:
     domain:
       cpu:
         cores: 1
         sockets: 1
         threads: 1
       devices:
         disks:
           - bootOrder: 1
             disk:
               bus: virtio
             name: disk0
           - disk:
               bus: virtio
             name: cloudinitdisk
         interfaces:
           - bridge: {}
             macAddress: 'de:ad:be:ef:00:03'
             model: e1000
             name:  tuning-bridge-fixed
         rng: {}
       machine:
         type: pc-q35-rhel8.2.0
       resources:
         requests:
           memory: 2Gi
     evictionStrategy: LiveMigrate
     hostname: centos7-clone-nfs
     networks:
       - multus:
           networkName: tuning-bridge-fixed
         name: tuning-bridge-fixed
     terminationGracePeriodSeconds: 0
     volumes:
       - name: disk0
         persistentVolumeClaim:
           claimName: centos7-clone-nfs
       - cloudInitNoCloud:
           userData: |-
             #cloud-config
             password: redhat
             chpasswd: {expire: False}
             ssh_pwauth: 1
             write_files:
               - path: /etc/systemd/system/nginx.service
                 permissions: ‘0755’
                 content: |
                     [Unit]
                     Description=Nginx Podman container
                     Wants=syslog.service
                     [Service]
                     ExecStart=/usr/bin/podman run --net=host nginxdemos/hello
                     ExecStop=/usr/bin/podman stop --all
                     [Install]
                     WantedBy=multi-user.target
               - content: |
                     # hi
                     DEVICE=eth0
                     HWADDR=de:ad:be:ef:00:03
                     ONBOOT=yes
                     TYPE=Ethernet
                     USERCTL=no
                     IPADDR=192.168.47.7
                     PREFIX=24
                     GATEWAY=192.168.47.1   
                     DNS1=150.239.16.11
                     DNS2=150.239.16.12
                 path:  /etc/sysconfig/network-scripts/ifcfg-eth0
                 permissions: '0644'
             runcmd:
               - [ systemctl, restart, network ]
               - [ yum, install, -y, podman ]
               - [ systemctl, daemon-reload ]
               - [ systemctl, enable, nginx ]
               - [ systemctl, start, --no-block, nginx ]          
         name: cloudinitdisk
EOF
virtualmachine.kubevirt.io/centos7-clone-nfs created

[asimonel-redhat.com@bastion ~]$ oc get vm
NAME                      AGE   VOLUME
centos7-clone-nfs         19s   
centos8-server-hostpath   19m   
centos8-server-nfs        40m   

[asimonel-redhat.com@bastion ~]$ virtctl stop centos7-clone-nfs 
VM centos7-clone-nfs was scheduled to stop

[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                      AGE   PHASE     IP                NODENAME
centos8-server-hostpath   36m   Running   192.168.47.6/24   cluster-452f-rfnck-worker-mfhzd
centos8-server-nfs        57m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd

[asimonel-redhat.com@bastion ~]$ oc get vm
NAME                      AGE   VOLUME
centos7-clone-nfs         17m   
centos8-server-hostpath   36m   
centos8-server-nfs        57m   

cat << EOF | oc apply -f -
apiVersion: cdi.kubevirt.io/v1alpha1
kind: DataVolume
metadata:
  name: centos7-clone-dv
spec:
  source:
    pvc:
      namespace: default
      name: centos7-clone-nfs
  pvc:
    accessModes:
      - ReadWriteOnce
    storageClassName: hostpath-provisioner
    resources:
      requests:
        storage: 10Gi
EOF
datavolume.cdi.kubevirt.io/centos7-clone-dv created

watch -n5 oc get datavolume
NAME               PHASE             PROGRESS   RESTARTS   AGE
centos7-clone-dv   CloneInProgress   1.30%      0          34s
...
centos7-clone-dv   Succeeded         100.0%     0          2m59s

[asimonel-redhat.com@bastion ~]$ oc get pvc
NAME                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
centos7-clone-dv    Bound    pvc-61e23508-8f3c-446b-ae09-fa5a1a2947f5   29Gi       RWO            hostpath-provisioner   83s
centos7-clone-nfs   Bound    nfs-pv2                                    10Gi       RWO,RWX        nfs                    23m
centos8-hostpath    Bound    pvc-c7bbe5f1-09ba-4b30-8250-510ee52d7676   29Gi       RWO            hostpath-provisioner   97m
centos8-nfs         Bound    nfs-pv1                                    10Gi       RWO,RWX        nfs                    128m

cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
 annotations:
   kubevirt.io/latest-observed-api-version: v1alpha3
   kubevirt.io/storage-observed-api-version: v1alpha3
   name.os.template.kubevirt.io/centos7.0: CentOS 7
 name: centos7-clone-dv
 namespace: default
 labels:
   app: centos7-clone-dv
   flavor.template.kubevirt.io/small: 'true'
   os.template.kubevirt.io/rhel7.9: 'true'
   vm.kubevirt.io/template: rhel7-server-small-v0.7.0
   vm.kubevirt.io/template.namespace: openshift
   vm.kubevirt.io/template.revision: '1'
   vm.kubevirt.io/template.version: v0.11.2
   workload.template.kubevirt.io/server: 'true'
spec:
 running: true
 template:
   metadata:
     creationTimestamp: null
     labels:
       flavor.template.kubevirt.io/small: 'true'
       kubevirt.io/domain: centos7-clone-dv
       kubevirt.io/size: small
       os.template.kubevirt.io/centos7.0: 'true'
       vm.kubevirt.io/name: centos7-clone-dv
       workload.template.kubevirt.io/server: 'true'
   spec:
     domain:
       cpu:
         cores: 1
         sockets: 1
         threads: 1
       devices:
         disks:
           - bootOrder: 1
             disk:
               bus: virtio
             name: disk0
           - disk:
               bus: virtio
             name: cloudinitdisk
         interfaces:
           - bridge: {}
             macAddress: 'de:ad:be:ef:00:04'
             model: e1000
             name:  tuning-bridge-fixed
         rng: {}
       machine:
         type: pc-q35-rhel8.2.0
       resources:
         requests:
           memory: 2Gi
     evictionStrategy: LiveMigrate
     hostname: centos7-clone-dv
     networks:
       - multus:
           networkName: tuning-bridge-fixed
         name: tuning-bridge-fixed
     terminationGracePeriodSeconds: 0
     volumes:
       - name: disk0
         persistentVolumeClaim:
           claimName: centos7-clone-dv
       - cloudInitNoCloud:
           userData: |-
             #cloud-config
             password: redhat
             chpasswd: {expire: False}
             ssh_pwauth: 1
             write_files:
               - content: |
                     # hi
                     DEVICE=eth0
                     HWADDR=de:ad:be:ef:00:04
                     ONBOOT=yes
                     TYPE=Ethernet
                     USERCTL=no
                     IPADDR=192.168.47.8
                     PREFIX=24
                     GATEWAY=192.168.47.1   
                     DNS1=150.239.16.11
                     DNS2=150.239.16.12
                 path:  /etc/sysconfig/network-scripts/ifcfg-eth0
                 permissions: '0644'
             runcmd:
               - [ systemctl, restart, network ]
         name: cloudinitdisk
EOF
virtualmachine.kubevirt.io/centos7-clone-dv created

[asimonel-redhat.com@bastion ~]$ virtctl console centos7-clone-dv
Successfully connected to centos7-clone-dv console. The escape sequence is ^]

CentOS Linux 7 (Core)
Kernel 3.10.0-1127.el7.x86_64 on an x86_64

centos7-clone-dv login: 

[centos@centos7-clone-dv ~]$ sudo rpm -qa | grep podman
podman-1.6.4-18.el7_8.x86_64


[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                      AGE    PHASE     IP                NODENAME
centos7-clone-dv          9m3s   Running   192.168.47.8/24   cluster-452f-rfnck-worker-mfhzd
centos8-server-hostpath   51m    Running   192.168.47.6/24   cluster-452f-rfnck-worker-mfhzd
centos8-server-nfs        73m    Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd

[asimonel-redhat.com@bastion ~]$ oc delete vm/centos7-clone-dv vm/centos8-server-hostpath vm/centos7-clone-nfs
virtualmachine.kubevirt.io "centos7-clone-dv" deleted
virtualmachine.kubevirt.io "centos8-server-hostpath" deleted
virtualmachine.kubevirt.io "centos7-clone-nfs" deleted

[asimonel-redhat.com@bastion ~]$ oc get vmi 
NAME                 AGE   PHASE     IP                NODENAME
centos8-server-nfs   74m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd

[asimonel-redhat.com@bastion ~]$ oc describe vmi centos8-server-nfs | egrep -i '(eviction|migration)'
        f:evictionStrategy:
        f:migrationMethod:
  Eviction Strategy:  LiveMigrate
  Migration Method:  BlockMigration

[asimonel-redhat.com@bastion ~]$ oc describe pvc/centos8-nfs | grep "Access Modes"
Access Modes:  RWO,RWX

cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-job
spec:
  vmiName: centos8-server-nfs
EOF
virtualmachineinstancemigration.kubevirt.io/migration-job created

[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                 AGE   PHASE     IP                NODENAME
centos8-server-nfs   82m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd
[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                 AGE   PHASE     IP                NODENAME
centos8-server-nfs   82m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-4n9sq

watch -n1 "oc get virtualmachineinstancemigration/migration-job -o yaml | grep phase"
...
phase: Scheduled
phase: TargetReady
phase: Running
phase: Succeeded


cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-job2
spec:
  vmiName: centos8-server-nfs
EOF

watch -n1 "oc get virtualmachineinstancemigration/migration-job2 -o yaml | grep phase"

cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-job3
spec:
  vmiName: centos8-server-nfs
EOF

oc describe vmi centos8-server-nfs | tail -n 50

[asimonel-redhat.com@bastion ~]$ oc get nodes
NAME                              STATUS   ROLES    AGE   VERSION
cluster-452f-rfnck-master-0       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-master-1       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-master-2       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-4n9sq   Ready    worker   26h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-mfhzd   Ready    worker   26h   v1.18.3+012b3ec
[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                 AGE   PHASE     IP                NODENAME
centos8-server-nfs   90m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-4n9sq

cat << EOF | oc apply -f -
apiVersion: nodemaintenance.kubevirt.io/v1beta1
kind: NodeMaintenance
metadata:
  name: worker-maintenance
spec:
  nodeName: cluster-452f-rfnck-worker-4n9sq
  reason: "Worker Maintenance - Back Soon"
EOF

oc api-resources | grep -i maint
nodemaintenances                                             nodemaintenance.kubevirt.io                 false        NodeMaintenance

oc explain nodemaintenances

[asimonel-redhat.com@bastion ~]$ oc get nodes
NAME                              STATUS                     ROLES    AGE   VERSION
cluster-452f-rfnck-master-0       Ready                      master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-master-1       Ready                      master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-master-2       Ready                      master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-4n9sq   Ready,SchedulingDisabled   worker   26h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-mfhzd   Ready                      worker   26h   v1.18.3+012b3ec 

[asimonel-redhat.com@bastion ~]$ oc get vmi centos8-server-nfs
NAME                 AGE    PHASE     IP                NODENAME
centos8-server-nfs   104m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd

[asimonel-redhat.com@bastion ~]$ oc get nodemaintenance
NAME                 AGE
worker-maintenance   6m9s

[asimonel-redhat.com@bastion ~]$ oc delete nodemaintenance/worker-maintenance
nodemaintenance.nodemaintenance.kubevirt.io "worker-maintenance" deleted

[asimonel-redhat.com@bastion ~]$ oc get nodes
NAME                              STATUS   ROLES    AGE   VERSION
cluster-452f-rfnck-master-0       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-master-1       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-master-2       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-4n9sq   Ready    worker   26h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-mfhzd   Ready    worker   26h   v1.18.3+012b3ec

cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  annotations:
    kubevirt.io/latest-observed-api-version: v1alpha3
    kubevirt.io/storage-observed-api-version: v1alpha3
    name.os.template.kubevirt.io/centos7.0: CentOS 7
  name: centos7-masq
  namespace: default
  labels:
    app: centos7-masq
    flavor.template.kubevirt.io/small: 'true'
    os.template.kubevirt.io/rhel7.9: 'true'
    vm.kubevirt.io/template: rhel7-server-small-v0.7.0
    vm.kubevirt.io/template.namespace: openshift
    vm.kubevirt.io/template.revision: '1'
    vm.kubevirt.io/template.version: v0.11.2
    workload.template.kubevirt.io/server: 'true'
spec:
  running: false
  template:
    metadata:
      creationTimestamp: null
      labels:
        flavor.template.kubevirt.io/small: 'true'
        kubevirt.io/domain: centos7-masq
        kubevirt.io/size: small
        os.template.kubevirt.io/centos7.0: 'true'
        vm.kubevirt.io/name: centos7-masq
        workload.template.kubevirt.io/server: 'true'
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
            - bootOrder: 1
              disk:
                bus: virtio
              name: disk-0
          interfaces:
            - masquerade: {}
              model: virtio
              name: nic-0
          networkInterfaceMultiqueue: true
          rng: {}
        machine:
          type: pc-q35-rhel8.2.0
        resources:
          requests:
            memory: 2Gi
      evictionStrategy: LiveMigrate
      hostname: centos7-masq
      networks:
        - name: nic-0
          pod: {}
      terminationGracePeriodSeconds: 0
      volumes:
        - name: disk-0
          persistentVolumeClaim:
            claimName: centos7-clone-nfs
EOF
virtualmachine.kubevirt.io/centos7-masq created

[asimonel-redhat.com@bastion ~]$ oc get vm
NAME                 AGE    VOLUME
centos7-masq         12s    
centos8-server-nfs   112m   

[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                 AGE    PHASE     IP                NODENAME
centos8-server-nfs   112m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd

[asimonel-redhat.com@bastion ~]$ virtctl start centos7-masq
VM centos7-masq was scheduled to start

[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                 AGE    PHASE     IP                NODENAME
centos7-masq         10s    Running   10.131.0.53       cluster-452f-rfnck-worker-4n9sq
centos8-server-nfs   113m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd

virtctl console centos7-masq

[centos@centos7-clone-nfs ~]$ ip a 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8892 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 02:00:00:8d:2e:b2 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.2/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 86313594sec preferred_lft 86313594sec
    inet6 fe80::ff:fe8d:2eb2/64 scope link 
       valid_lft forever preferred_lft forever

virtctl expose virtualmachineinstance centos7-masq --name centos7-masq-externalport --port 80

[asimonel-redhat.com@bastion ~]$ virtctl expose virtualmachineinstance centos7-masq --name centos7-masq-externalport --port 80
Service centos7-masq-externalport successfully exposed for virtualmachineinstance centos7-masq
[asimonel-redhat.com@bastion ~]$ oc get svc
NAME                        TYPE           CLUSTER-IP     EXTERNAL-IP                            PORT(S)   AGE
centos7-masq-externalport   ClusterIP      172.30.22.47   <none>                                 80/TCP    10s
kubernetes                  ClusterIP      172.30.0.1     <none>                                 443/TCP   27h
openshift                   ExternalName   <none>         kubernetes.default.svc.cluster.local   <none>    27h

oc create route edge --service=centos7-masq-externalport
route.route.openshift.io/centos7-masq-externalport created

[asimonel-redhat.com@bastion ~]$ oc get route
NAME                        HOST/PORT                                                                 PATH   SERVICES                    PORT    TERMINATION   WILDCARD
centos7-masq-externalport   centos7-masq-externalport-default.apps.cluster-452f.dynamic.opentlc.com          centos7-masq-externalport   <all>   edge          None

virtctl expose virtualmachineinstance centos7-masq --name centos7-ssh-node --type NodePort --port 22
Service centos7-ssh-node successfully exposed for virtualmachineinstance centos7-masq

[asimonel-redhat.com@bastion ~]$ oc get svc/centos7-ssh-node
NAME               TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
centos7-ssh-node   NodePort   172.30.37.162   <none>        22:30728/TCP   29s

[asimonel-redhat.com@bastion ~]$ oc get vmi/centos7-masq
NAME           AGE     PHASE     IP            NODENAME
centos7-masq   8m30s   Running   10.131.0.53   cluster-452f-rfnck-worker-4n9sq

ssh centos@cluster-452f-rfnck-worker-4n9sq -p 30728

[asimonel-redhat.com@bastion ~]$ oc get nodes
NAME                              STATUS   ROLES    AGE   VERSION
cluster-452f-rfnck-master-0       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-master-1       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-master-2       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-4n9sq   Ready    worker   27h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-mfhzd   Ready    worker   27h   v1.18.3+012b3ec

ssh centos@cluster-452f-rfnck-worker-mfhzd -p 30728

virtctl expose virtualmachineinstance centos7-masq --name centos-ssh --port 22

[asimonel-redhat.com@bastion ~]$ oc get svc
NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP                            PORT(S)        AGE
centos-ssh                  ClusterIP      172.30.136.213   <none>                                 22/TCP         21s
centos7-masq-externalport   ClusterIP      172.30.22.47     <none>                                 80/TCP         7m12s
centos7-ssh-node            NodePort       172.30.37.162    <none>                                 22:30728/TCP   4m1s
kubernetes                  ClusterIP      172.30.0.1       <none>                                 443/TCP        27h
openshift                   ExternalName   <none>           kubernetes.default.svc.cluster.local   <none>         27h
[asimonel-redhat.com@bastion ~]$ oc get nodes
NAME                              STATUS   ROLES    AGE   VERSION
cluster-452f-rfnck-master-0       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-master-1       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-master-2       Ready    master   27h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-4n9sq   Ready    worker   27h   v1.18.3+012b3ec
cluster-452f-rfnck-worker-mfhzd   Ready    worker   27h   v1.18.3+012b3ec
[asimonel-redhat.com@bastion ~]$ oc get vmi
NAME                 AGE    PHASE     IP                NODENAME
centos7-masq         12m    Running   10.131.0.53       cluster-452f-rfnck-worker-4n9sq
centos8-server-nfs   125m   Running   192.168.47.5/24   cluster-452f-rfnck-worker-mfhzd
[asimonel-redhat.com@bastion ~]$ oc debug node/cluster-452f-rfnck-worker-4n9sq
Starting pod/cluster-452f-rfnck-worker-4n9sq-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.0.2.143
If you don't see a command prompt, try pressing enter.
sh-4.2# chroot /host
sh-4.4# ssh centos@172.30.136.213
...
[centos@centos7-clone-nfs ~]$ logout

apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv3
spec:
  accessModes:
  - ReadWriteOnce
  - ReadWriteMany
  capacity:
    storage: 10Gi
  nfs:
    path: /mnt/nfs/three
    server: 192.168.47.16
  persistentVolumeReclaimPolicy: Delete
  storageClassName: nfs
  volumeMode: Filesystem

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "centos7-ui-nfs"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
spec:
  volumeMode: Filesystem
  storageClassName: nfs
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi

[asimonel-redhat.com@bastion ~]$ oc get vm
NAME                 AGE    VOLUME
centos7-masq         50m    
centos7-ui-vm        23s    
centos8-server-nfs   162m   


```