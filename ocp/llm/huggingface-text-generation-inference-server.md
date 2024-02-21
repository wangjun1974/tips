
### 创建带gpu的 machineset
instanceType为p3.2xlarge 
```
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  name: cluster-26bnl-p5mp6-worker-us-east-2a-gpu
  namespace: openshift-machine-api
  labels:
    machine.openshift.io/cluster-api-cluster: cluster-26bnl-p5mp6
spec:
  replicas: 1
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: cluster-26bnl-p5mp6
      machine.openshift.io/cluster-api-machineset: cluster-26bnl-p5mp6-worker-us-east-2a-gpu
  template:
    metadata:
      labels:
        machine.openshift.io/cluster-api-cluster: cluster-26bnl-p5mp6
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: cluster-26bnl-p5mp6-worker-us-east-2a-gpu
    spec:
      lifecycleHooks: {}
      metadata: {}
      providerSpec:
        value:
          userDataSecret:
            name: worker-user-data
          placement:
            availabilityZone: us-east-2a
            region: us-east-2
          credentialsSecret:
            name: aws-cloud-credentials
          instanceType: p3.2xlarge
          metadata:
            creationTimestamp: null
          blockDevices:
            - ebs:
                encrypted: true
                iops: 0
                kmsKey:
                  arn: ''
                volumeSize: 250
                volumeType: gp3
          securityGroups:
            - filters:
                - name: 'tag:Name'
                  values:
                    - cluster-26bnl-p5mp6-worker-sg
          kind: AWSMachineProviderConfig
          metadataServiceOptions: {}
          tags:
            - name: kubernetes.io/cluster/cluster-26bnl-p5mp6
              value: owned
            - name: Stack
              value: project ocp4-cluster-26bnl
            - name: env_type
              value: ocp4-cluster
            - name: guid
              value: 26bnl
            - name: owner
              value: unknown
            - name: platform
              value: RHPDS
            - name: uuid
              value: b66e39d8-8029-5ebb-bdc8-4e29c7d92ab0
          deviceIndex: 0
          ami:
            id: ami-01af87a6ecc18023d
          subnet:
            filters:
              - name: 'tag:Name'
                values:
                  - cluster-26bnl-p5mp6-private-us-east-2a
          apiVersion: machine.openshift.io/v1beta1
          iamInstanceProfile:
            id: cluster-26bnl-p5mp6-worker-profile
```

### 新建带gpu的节点
```
$ oc get nodes
NAME                                         STATUS   ROLES                  AGE   VERSION
ip-10-0-135-81.us-east-2.compute.internal    Ready    worker                 17h   v1.25.8+37a9a08
```

### 安装 Node Feature Discovery Operator
```
$ oc get csv -n openshift-nfd  | grep Node 
nfd.4.12.0-202402081808                   Node Feature Discovery Operator   4.12.0-202402081808    nfd.4.12.0-202401291234              Succeeded

# 创建NodeFeatureDiscovery
# https://docs.openshift.com/container-platform/4.14/hardware_enablement/psap-node-feature-discovery-operator.html
$ oc get NodeFeatureDiscovery -A 
NAMESPACE       NAME           AGE
openshift-nfd   nfd-instance   15h

# NFD为节点添加以下labels
$ oc get node ip-10-0-135-81.us-east-2.compute.internal -o yaml | grep labels -A100  | grep nvidia.com/gpu 
...
    nvidia.com/gpu-driver-upgrade-enabled: "true"
    nvidia.com/gpu-driver-upgrade-state: upgrade-done
    nvidia.com/gpu.compute.major: "7"
    nvidia.com/gpu.compute.minor: "0"
    nvidia.com/gpu.count: "1"
    nvidia.com/gpu.deploy.container-toolkit: "true"
    nvidia.com/gpu.deploy.dcgm: "true"
    nvidia.com/gpu.deploy.dcgm-exporter: "true"
    nvidia.com/gpu.deploy.device-plugin: "true"
    nvidia.com/gpu.deploy.driver: "true"
    nvidia.com/gpu.deploy.gpu-feature-discovery: "true"
    nvidia.com/gpu.deploy.node-status-exporter: "true"
    nvidia.com/gpu.deploy.nvsm: ""
    nvidia.com/gpu.deploy.operator-validator: "true"
    nvidia.com/gpu.family: volta
    nvidia.com/gpu.machine: HVM-domU
    nvidia.com/gpu.memory: "16384"
    nvidia.com/gpu.present: "true"
    nvidia.com/gpu.product: Tesla-V100-SXM2-16GB
    nvidia.com/gpu.replicas: "1"

$ oc get node ip-10-0-135-81.us-east-2.compute.internal -o yaml | grep labels -A100  | grep pci
...
    feature.node.kubernetes.io/pci-1013.present: "true"
    feature.node.kubernetes.io/pci-10de.present: "true"
    feature.node.kubernetes.io/pci-1d0f.present: "true"
```

### 安装 Nvidia GPU Operator
Nvidia GPU Operator
https://docs.nvidia.com/datacenter/cloud-native/openshift/23.9.1/install-gpu-ocp.html
```
$ oc -n nvidia-gpu-operator get csv | grep -i gpu 
gpu-operator-certified.v23.9.1            NVIDIA GPU Operator               23.9.1                 gpu-operator-certified.v23.9.0       Succeeded

# 创建 clusterpolicies
# https://docs.nvidia.com/datacenter/cloud-native/openshift/23.9.1/install-gpu-ocp.html
$ oc get clusterpolicies -A 
NAME                 STATUS   AGE
gpu-cluster-policy   ready    2024-02-20T11:39:30Z

### 处理 Pod Security 相关设置 namespace 
$ oc label namespace nvidia-gpu-operator pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged security.openshift.io/scc.podSecurityLabelSync=false --overwrite=true
$ oc get namespace nvidia-gpu-operator --show-labels

# 查看 pods
$ oc get pods 
NAME                                                  READY   STATUS      RESTARTS   AGE
gpu-feature-discovery-9j5vt                           1/1     Running     0          120m
gpu-operator-6b97698c5b-k87vs                         1/1     Running     1          15h
nvidia-container-toolkit-daemonset-t4dhb              1/1     Running     0          120m
nvidia-cuda-validator-52gwx                           0/1     Completed   0          119m
nvidia-dcgm-exporter-56hpx                            1/1     Running     0          120m
nvidia-dcgm-xkh4r                                     1/1     Running     0          120m
nvidia-device-plugin-daemonset-9kvb5                  1/1     Running     0          120m
nvidia-driver-daemonset-412.86.202304260244-0-tv487   2/2     Running     2          15h
nvidia-node-status-exporter-phbk2                     1/1     Running     1          15h
nvidia-operator-validator-r5kf2                       1/1     Running     0          120m

# 查看 gpu 信息
$ oc -n nvidia-gpu-operator exec -it $(oc -n nvidia-gpu-operator get pod -o name -lopenshift.driver-toolkit=true) -- nvidia-smi
Wed Feb 21 03:25:41 2024       
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.129.03             Driver Version: 535.129.03   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  Tesla V100-SXM2-16GB           On  | 00000000:00:1E.0 Off |                    0 |
| N/A   37C    P0              25W / 300W |      0MiB / 16384MiB |      0%      Default |
|                                         |                      |                  N/A |
+-----------------------------------------+----------------------+----------------------+
                                                                                         
+---------------------------------------------------------------------------------------+
| Processes:                                                                            |
|  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
|        ID   ID                                                             Usage      |
|=======================================================================================|
|  No running processes found                                                           |
+---------------------------------------------------------------------------------------+

# 创建 demo 工作负载
$ oc project nvidia-gpu-operator
$ cat << EOF | oc create -f -
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vectoradd
spec:
 restartPolicy: OnFailure
 containers:
 - name: cuda-vectoradd
   image: "nvidia/samples:vectoradd-cuda11.2.1"
   resources:
     limits:
       nvidia.com/gpu: 1
EOF

# 查看 demo 工作负载日志
$ oc logs cuda-vectoradd
Copy input data from the host memory to the CUDA device
CUDA kernel launch with 196 blocks of 256 threads
Copy output data from the CUDA device to the host memory
Test PASSED
Done

```