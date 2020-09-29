```
oc get nodes -l node-role.kubernetes.io/worker -l '!node-role.kubernetes.io/infra','!node-role.kubernetes.io/master'

cat > /opt/app-root/src/support/machineset-generator.sh << 'EOF'
#!/bin/bash
export AMI=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].spec.template.
spec.providerSpec.value.ami.id}')
export CLUSTERID=$(oc get infrastructures.config.openshift.io cluster -o jsonpath='{.status.in
frastructureName}')
export REGION=$(oc get infrastructures.config.openshift.io cluster -o jsonpath='{.status.platf
ormStatus.aws.region}')
export COUNT=${1:-3}
export NAME=${2:-workerocs}
export SCALE=${3:-1}

$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/machineset-cli -scale $SCALE
 -name $NAME -count $COUNT -ami $AMI -clusterID $CLUSTERID -region $REGION
EOF

bash /opt/app-root/src/support/machineset-generator.sh 3 workerocs 0 | oc create -f -
oc get machineset -n openshift-machine-api -l machine.openshift.io/cluster-api-machine-role=workerocs -o name | xargs oc patch -n openshift-machine-api --type='json' -p '[{"op": "add", "path": "/spec/template/spec/metadata/labels", "value":{"node-role.kubernetes.io/worker":"", "role":"storage-node", "cluster.ocs.openshift.io/openshift-storage":""} }]'
oc get machineset -n openshift-machine-api -l machine.openshift.io/cluster-api-machine-role=workerocs -o name | xargs oc scale -n openshift-machine-api --replicas=1

oc get machines -n openshift-machine-api | egrep 'NAME|workerocs'

watch "oc get machinesets -n openshift-machine-api | egrep 'NAME|workerocs'"

oc get nodes -l node-role.kubernetes.io/worker -l '!node-role.kubernetes.io/infra','!node-role.kubernetes.io/master'

oc create namespace openshift-storage

oc label namespace openshift-storage "openshift.io/cluster-monitoring=true"

watch oc -n openshift-storage get csv

oc -n openshift-storage get pods

oc get storagecluster -n openshift-storage
NAME                 AGE    PHASE   CREATED AT             VERSION
ocs-storagecluster   6m3s   Ready   2020-09-15T02:38:52Z   4.4.0

oc get storagecluster -n openshift-storage ocs-storagecluster -o jsonpath='{.status.phas
e}{"\n"}'
Ready

oc get storageclass -n openshift-storage
NAME                          PROVISIONER                             AGE
gp2 (default)                 kubernetes.io/aws-ebs                   6h16m
ocs-storagecluster-ceph-rbd   openshift-storage.rbd.csi.ceph.com      8m23s
ocs-storagecluster-cephfs     openshift-storage.cephfs.csi.ceph.com   8m23s
openshift-storage.noobaa.io   openshift-storage.noobaa.io/obc         3m4s

oc -n openshift-storage get sc
NAME                          PROVISIONER                             AGE
gp2 (default)                 kubernetes.io/aws-ebs                   6h19m
ocs-storagecluster-ceph-rbd   openshift-storage.rbd.csi.ceph.com      11m
ocs-storagecluster-cephfs     openshift-storage.cephfs.csi.ceph.com   11m
openshift-storage.noobaa.io   openshift-storage.noobaa.io/obc         6m40s


oc patch OCSInitialization ocsinit -n openshift-storage --type json --patch  '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'


TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD

ceph status
ceph osd status
ceph osd tree
ceph df
rados df
ceph versions

exit

oc new-project my-database-app
oc new-app -f /opt/app-root/src/support/ocslab_rails-app.yaml -p STORAGE_CLASS=ocs-storagecluster-ceph-rbd -p VOLUME_CAPACITY=5Gi

oc get pv -o 'custom-columns=NAME:.spec.claimRef.name,PVNAME:.metadata.name,STORAGECLASS:.spec.storageClassName,VOLUMEHANDLE:.spec.csi.volumeHandle'

CSIVOL=$(oc get pv $(oc get pv | grep my-database-app | awk '{ print $1 }') -o jsonpath='{.spec.csi.volumeHandle}' | cut -d '-' -f 6- | awk '{print "csi-vol-"$1}')
echo $CSIVOL


TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD rbd -p ocs-storagecluster-cephblockpool info $CSIVOL

oc new-project my-shared-storage
oc new-app openshift/php:7.2~https://github.com/christianh814/openshift-php-upload-demo --name=file-uploader

oc logs -f bc/file-uploader -n my-shared-storage
oc expose svc/file-uploader -n my-shared-storage
oc scale --replicas=3 dc/file-uploader -n my-shared-storage
oc get pods -n my-shared-storage


oc set volume dc/file-uploader --add --name=my-shared-storage \
-t pvc --claim-mode=ReadWriteMany --claim-size=1Gi \
--claim-name=my-shared-storage --claim-class=ocs-storagecluster-cephfs \
--mount-path=/opt/app-root/src/uploaded \
-n my-shared-storage


oc get pods,pvc -n openshift-monitoring

oc -n openshift-monitoring get configmap cluster-monitoring-config

cat /opt/app-root/src/support/ocslab_cluster-monitoring-noinfra.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    prometheusK8s:
      volumeClaimTemplate:
        metadata:
          name: prometheusdb
        spec:
          storageClassName: ocs-storagecluster-ceph-rbd
          resources:
            requests:
              storage: 40Gi
    alertmanagerMain:
      volumeClaimTemplate:
        metadata:
          name: alertmanager
        spec:
          storageClassName: ocs-storagecluster-ceph-rbd
          resources:
            requests:
              storage: 40Gi

oc apply -f /opt/app-root/src/support/ocslab_cluster-monitoring-noinfra.yaml


oc -n openshift-monitoring get configmap cluster-monitoring-config -o yaml | more


oc get pods,pvc -n openshift-monitoring


noobaa status -n openshift-storage


noobaa obc create test21obc -n openshift-storage


oc get obc -n openshift-storage

oc get obc test21obc -o yaml -n openshift-storage

oc get -n openshift-storage secret test21obc -o yaml

oc get -n openshift-storage cm test21obc -o yaml

cat /opt/app-root/src/support/ocslab_obc-app-example.yaml

oc apply -f /opt/app-root/src/support/ocslab_obc-app-example.yaml

oc get pods -n obc-test -l app=obc-test

oc logs -n obc-test $(oc get pods -n obc-test -l app=obc-test -o jsonpath='{.items[0].me
tadata.name}')

oc get machinesets -n openshift-machine-api | egrep 'NAME|workerocs'
NAME                                           DESIRED   CURRENT   READY   AVAILABLE   AGE
cluster-ocs4-d6e6-6hmnh-workerocs-us-east-2a   1         1         1       1           61m
cluster-ocs4-d6e6-6hmnh-workerocs-us-east-2b   1         1         1       1           61m
cluster-ocs4-d6e6-6hmnh-workerocs-us-east-2c   1         1         1       1           61m

oc get machinesets -n openshift-machine-api -o name | grep workerocs | xargs -n1 -t oc s
cale -n openshift-machine-api --replicas=2
oc scale -n openshift-machine-api --replicas=2 machineset.machine.openshift.io/cluster-ocs4-d6
e6-6hmnh-workerocs-us-east-2a
machineset.machine.openshift.io/cluster-ocs4-d6e6-6hmnh-workerocs-us-east-2a scaled
oc scale -n openshift-machine-api --replicas=2 machineset.machine.openshift.io/cluster-ocs4-d6
e6-6hmnh-workerocs-us-east-2b
machineset.machine.openshift.io/cluster-ocs4-d6e6-6hmnh-workerocs-us-east-2b scaled
oc scale -n openshift-machine-api --replicas=2 machineset.machine.openshift.io/cluster-ocs4-d6
e6-6hmnh-workerocs-us-east-2c
machineset.machine.openshift.io/cluster-ocs4-d6e6-6hmnh-workerocs-us-east-2c scaled


watch "oc get machinesets -n openshift-machine-api | egrep 'NAME|workerocs'"

oc get nodes -l cluster.ocs.openshift.io/openshift-storage -o jsonpath='{range .items[*]
}{.metadata.name}{"\n"}'

oc get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeNam
e -n openshift-storage | grep osd
rook-ceph-osd-0-784d5c9f86-hrptr                                  Running     ip-10-0-149-239.
us-east-2.compute.internal
rook-ceph-osd-1-556854bc65-26rjp                                  Running     ip-10-0-170-93.u
s-east-2.compute.internal
rook-ceph-osd-2-8469b84fd-fhm8k                                   Running     ip-10-0-133-143.
us-east-2.compute.internal
rook-ceph-osd-prepare-ocs-deviceset-0-0-7qrs6-6r6sv               Succeeded   ip-10-0-133-143.
us-east-2.compute.internal
rook-ceph-osd-prepare-ocs-deviceset-1-0-nfcsp-xwqg6               Succeeded   ip-10-0-170-93.u
s-east-2.compute.internal
rook-ceph-osd-prepare-ocs-deviceset-2-0-hfd28-rs46b               Succeeded   ip-10-0-149-239.
us-east-2.compute.internal

TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD
ceph status
ceph osd tree
exit

oc adm must-gather

oc adm must-gather -h


```


###  OCS 培训脚本
脚本 /opt/app-root/src/support/machineset-generator.sh
```
[~] $ cat /opt/app-root/src/support/machineset-generator.sh
#!/bin/bash
export AMI=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].spec.template.s
pec.providerSpec.value.ami.id}')
export CLUSTERID=$(oc get infrastructures.config.openshift.io cluster -o jsonpath='{.status.inf
rastructureName}')
export REGION=$(oc get infrastructures.config.openshift.io cluster -o jsonpath='{.status.platfo
rmStatus.aws.region}')
export COUNT=${1:-3}
export NAME=${2:-workerocs}
export SCALE=${3:-1}

$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/machineset-cli -scale $SCALE
-name $NAME -count $COUNT -ami $AMI -clusterID $CLUSTERID -region $REGION
```

脚本 /opt/app-root/src/support/machineset-generator.sh 执行输出，生成了 3 个 MachineSet定义，每个 MachineSet 对应 1 个 AZ
```
[~] $ /bin/bash /opt/app-root/src/support/machineset-generator.sh 3 workerocs 0

---
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: cluster-beijing-01c5-nxpff
    machine.openshift.io/cluster-api-machine-role: workerocs
    machine.openshift.io/cluster-api-machine-type: workerocs
  name: cluster-beijing-01c5-nxpff-workerocs-us-east-2a
  namespace: openshift-machine-api
spec:
  replicas: 0
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: cluster-beijing-01c5-nxpff
      machine.openshift.io/cluster-api-machineset: cluster-beijing-01c5-nxpff-workerocs-us-east
-2a
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: cluster-beijing-01c5-nxpff
        machine.openshift.io/cluster-api-machine-role: workerocs
        machine.openshift.io/cluster-api-machine-type: workerocs
        machine.openshift.io/cluster-api-machineset: cluster-beijing-01c5-nxpff-workerocs-us-ea
st-2a
    spec:
      metadata:
        creationTimestamp: null
        labels:
          role: storage-node
          node-role.kubernetes.io/worker: ""
      providerSpec:
        value:
          ami:
            id: ami-0d8f77b753c0d96dd
          apiVersion: awsproviderconfig.openshift.io/v1beta1
          blockDevices:
          - ebs:
              iops: 0
              volumeSize: 120
              volumeType: gp2
          credentialsSecret:
            name: aws-cloud-credentials
          deviceIndex: 0
          iamInstanceProfile:
            id: cluster-beijing-01c5-nxpff-worker-profile
          instanceType: m5.4xlarge
          kind: AWSMachineProviderConfig
          metadata:
            creationTimestamp: null
          placement:
            availabilityZone: us-east-2a
            region: us-east-2
          publicIp: null
          securityGroups:
          - filters:
            - name: tag:Name
              values:
              - cluster-beijing-01c5-nxpff-worker-sg
          subnet:
            filters:
            - name: tag:Name
              values:
              - cluster-beijing-01c5-nxpff-private-us-east-2a
          tags:
          - name: kubernetes.io/cluster/cluster-beijing-01c5-nxpff
            value: owned
          userDataSecret:
            name: worker-user-data
      versions:
    kubelet: ""
---
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: cluster-beijing-01c5-nxpff
    machine.openshift.io/cluster-api-machine-role: workerocs
    machine.openshift.io/cluster-api-machine-type: workerocs
  name: cluster-beijing-01c5-nxpff-workerocs-us-east-2b
  namespace: openshift-machine-api
spec:
  replicas: 0
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: cluster-beijing-01c5-nxpff
      machine.openshift.io/cluster-api-machineset: cluster-beijing-01c5-nxpff-workerocs-us-east
-2b
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: cluster-beijing-01c5-nxpff
        machine.openshift.io/cluster-api-machine-role: workerocs
        machine.openshift.io/cluster-api-machine-type: workerocs
        machine.openshift.io/cluster-api-machineset: cluster-beijing-01c5-nxpff-workerocs-us-ea
st-2b
    spec:
      metadata:
        creationTimestamp: null
        labels:
          role: storage-node
          node-role.kubernetes.io/worker: ""
      providerSpec:
        value:
          ami:
            id: ami-0d8f77b753c0d96dd
          apiVersion: awsproviderconfig.openshift.io/v1beta1
          blockDevices:
          - ebs:
              iops: 0
              volumeSize: 120
              volumeType: gp2
          credentialsSecret:
            name: aws-cloud-credentials
          deviceIndex: 0
          iamInstanceProfile:
            id: cluster-beijing-01c5-nxpff-worker-profile
          instanceType: m5.4xlarge
          kind: AWSMachineProviderConfig
          metadata:
            creationTimestamp: null
          placement:
            availabilityZone: us-east-2b
            region: us-east-2
          publicIp: null
          securityGroups:
          - filters:
            - name: tag:Name
              values:
              - cluster-beijing-01c5-nxpff-worker-sg
          subnet:
            filters:
            - name: tag:Name
              values:
              - cluster-beijing-01c5-nxpff-private-us-east-2b
          tags:
          - name: kubernetes.io/cluster/cluster-beijing-01c5-nxpff
            value: owned
          userDataSecret:
            name: worker-user-data
      versions:
    kubelet: ""
---
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: cluster-beijing-01c5-nxpff
    machine.openshift.io/cluster-api-machine-role: workerocs
    machine.openshift.io/cluster-api-machine-type: workerocs
  name: cluster-beijing-01c5-nxpff-workerocs-us-east-2c
  namespace: openshift-machine-api
spec:
  replicas: 0
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: cluster-beijing-01c5-nxpff
      machine.openshift.io/cluster-api-machineset: cluster-beijing-01c5-nxpff-workerocs-us-east
-2c
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: cluster-beijing-01c5-nxpff
        machine.openshift.io/cluster-api-machine-role: workerocs
        machine.openshift.io/cluster-api-machine-type: workerocs
        machine.openshift.io/cluster-api-machineset: cluster-beijing-01c5-nxpff-workerocs-us-ea
st-2c
    spec:
      metadata:
        creationTimestamp: null
        labels:
          role: storage-node
          node-role.kubernetes.io/worker: ""
      providerSpec:
        value:
          ami:
            id: ami-0d8f77b753c0d96dd
          apiVersion: awsproviderconfig.openshift.io/v1beta1
          blockDevices:
          - ebs:
              iops: 0
              volumeSize: 120
              volumeType: gp2
          credentialsSecret:
            name: aws-cloud-credentials
          deviceIndex: 0
          iamInstanceProfile:
            id: cluster-beijing-01c5-nxpff-worker-profile
          instanceType: m5.4xlarge
          kind: AWSMachineProviderConfig
          metadata:
            creationTimestamp: null
          placement:
            availabilityZone: us-east-2c
            region: us-east-2
          publicIp: null
          securityGroups:
          - filters:
            - name: tag:Name
              values:
              - cluster-beijing-01c5-nxpff-worker-sg
          subnet:
            filters:
            - name: tag:Name
              values:
              - cluster-beijing-01c5-nxpff-private-us-east-2c
          tags:
          - name: kubernetes.io/cluster/cluster-beijing-01c5-nxpff
            value: owned
          userDataSecret:
            name: worker-user-data
      versions:
    kubelet: ""
[~] $
```