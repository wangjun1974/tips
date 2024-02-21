
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

### 安装 HuggingFace Text Generate Inference Server 
参考链接：
https://github.com/rh-aiservices-bu/llm-on-openshift/tree/main/llm-servers/hf_tgi
```
$ oc project dsp01

# 创建 pvc model-cache
# 400G
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: models-cache
  namespace: dsp01
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 400Gi
  storageClassName: ocs-storagecluster-ceph-rbd
  volumeMode: Filesystem
EOF

# 创建部署
# https://raw.githubusercontent.com/rh-aiservices-bu/llm-on-openshift/main/llm-servers/hf_tgi/deployment.yaml
cat <<EOF | oc apply -f -
kind: Deployment
apiVersion: apps/v1
metadata:
  name: hf-text-generation-inference-server
  labels:
    app: hf-text-generation-inference-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hf-text-generation-inference-server
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hf-text-generation-inference-server
    spec:
      restartPolicy: Always
      schedulerName: default-scheduler
      affinity: {}
      terminationGracePeriodSeconds: 120
      securityContext: {}
      containers:
        - resources:
            limits:
              cpu: '8'
              nvidia.com/gpu: '1'
            requests:
              cpu: '1'
          readinessProbe:
            httpGet:
              path: /health
              port: http
              scheme: HTTP
            timeoutSeconds: 5
            periodSeconds: 30
            successThreshold: 1
            failureThreshold: 3
          terminationMessagePath: /dev/termination-log
          name: server
          livenessProbe:
            httpGet:
              path: /health
              port: http
              scheme: HTTP
            timeoutSeconds: 8
            periodSeconds: 100
            successThreshold: 1
            failureThreshold: 3
          env:
            - name: MODEL_ID
              value: google/flan-t5-small
            - name: MAX_INPUT_LENGTH
              value: '1024'
            - name: MAX_TOTAL_TOKENS
              value: '2048'
            - name: QUANTIZE
              value: bitsandbytes
            - name: HUGGINGFACE_HUB_CACHE
              value: /models-cache
            - name: PORT
              value: '3000'
            - name: HOST
              value: '0.0.0.0'
            - name: HF_HUB_ENABLE_HF_TRANSFER
              value: '0'
          securityContext:
            capabilities:
              drop:
                - ALL
            runAsNonRoot: true
            allowPrivilegeEscalation: false
            seccompProfile:
              type: RuntimeDefault
          ports:
            - name: http
              containerPort: 3000
              protocol: TCP
          imagePullPolicy: IfNotPresent
          startupProbe:
            httpGet:
              path: /health
              port: http
              scheme: HTTP
            timeoutSeconds: 1
            periodSeconds: 30
            successThreshold: 1
            failureThreshold: 24
          volumeMounts:
            - name: models-cache
              mountPath: /models-cache
            - name: shm
              mountPath: /dev/shm
          terminationMessagePolicy: File
          image: 'ghcr.io/huggingface/text-generation-inference:1.2.0'
      volumes:
        - name: models-cache
          persistentVolumeClaim:
            claimName: models-cache
        - name: shm
          emptyDir:
            medium: Memory
            sizeLimit: 1Gi
      dnsPolicy: ClusterFirst
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 1
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
EOF

# 检查 pods 状态
$ oc get pods
NAME                                                   READY   STATUS    RESTARTS   AGE
hf-text-generation-inference-server-5df6759cd6-48zxb   1/1     Running   0          2m53s

# 检查日志
$ oc logs $(oc get pods -l app=hf-text-generation-inference-server -o name)

{"timestamp":"2024-02-21T05:09:46.814956Z","level":"INFO","fields":{"message":"Args { model_id: \"google/flan-t5-small\", revision: None, validation_workers: 2, sharded: None, num_shard: None, quantize: S
ome(Bitsandbytes), dtype: None, trust_remote_code: false, max_concurrent_requests: 128, max_best_of: 2, max_stop_sequences: 4, max_top_n_tokens: 5, max_input_length: 1024, max_total_tokens: 2048, waiting_
served_ratio: 1.2, max_batch_prefill_tokens: 4096, max_batch_total_tokens: None, max_waiting_tokens: 20, hostname: \"hf-text-generation-inference-server-5df6759cd6-48zxb\", port: 3000, shard_uds_path: \"/
tmp/text-generation-server\", master_addr: \"localhost\", master_port: 29500, huggingface_hub_cache: Some(\"/models-cache\"), weights_cache_override: None, disable_custom_kernels: false, cuda_memory_fract
ion: 1.0, rope_scaling: None, rope_factor: None, json_output: true, otlp_endpoint: None, cors_allow_origin: [], watermark_gamma: None, watermark_delta: None, ngrok: false, ngrok_authtoken: None, ngrok_edg
e: None, env: false }"},"target":"text_generation_launcher"}
{"timestamp":"2024-02-21T05:09:46.815155Z","level":"INFO","fields":{"message":"Starting download process."},"target":"text_generation_launcher","span":{"name":"download"},"spans":[{"name":"download"}]}
{"timestamp":"2024-02-21T05:09:51.008236Z","level":"INFO","fields":{"message":"Download file: model.safetensors\n"},"target":"text_generation_launcher"}
{"timestamp":"2024-02-21T05:09:51.984734Z","level":"INFO","fields":{"message":"Downloaded /models-cache/models--google--flan-t5-small/snapshots/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab/model.safetensors i
n 0:00:00.\n"},"target":"text_generation_launcher"}
{"timestamp":"2024-02-21T05:09:51.984862Z","level":"INFO","fields":{"message":"Download: [1/1] -- ETA: 0\n"},"target":"text_generation_launcher"}
{"timestamp":"2024-02-21T05:09:52.420748Z","level":"INFO","fields":{"message":"Successfully downloaded weights."},"target":"text_generation_launcher","span":{"name":"download"},"spans":[{"name":"download"
}]}
{"timestamp":"2024-02-21T05:09:52.421039Z","level":"INFO","fields":{"message":"Starting shard"},"target":"text_generation_launcher","span":{"rank":0,"name":"shard-manager"},"spans":[{"rank":0,"name":"shar
d-manager"}]}
{"timestamp":"2024-02-21T05:09:56.421772Z","level":"WARN","fields":{"message":"Could not import Flash Attention enabled models: GPU with CUDA capability 7 0 is not supported\n"},"target":"text_generation_
launcher"}
{"timestamp":"2024-02-21T05:09:56.424576Z","level":"WARN","fields":{"message":"Could not import Mistral model: GPU with CUDA capability 7 0 is not supported\n"},"target":"text_generation_launcher"}
{"timestamp":"2024-02-21T05:09:57.685776Z","level":"WARN","fields":{"message":"Bitsandbytes 8bit is deprecated, using `eetq` is a drop-in replacement, and has much better performnce\n"},"target":"text_gen
eration_launcher"}
{"timestamp":"2024-02-21T05:09:57.948206Z","level":"INFO","fields":{"message":"Server started at unix:///tmp/text-generation-server-0\n"},"target":"text_generation_launcher"}
{"timestamp":"2024-02-21T05:09:58.029562Z","level":"INFO","fields":{"message":"Shard ready in 5.607799614s"},"target":"text_generation_launcher","span":{"rank":0,"name":"shard-manager"},"spans":[{"rank":0
,"name":"shard-manager"}]}
{"timestamp":"2024-02-21T05:09:58.126308Z","level":"INFO","fields":{"message":"Starting Webserver"},"target":"text_generation_launcher"}
{"timestamp":"2024-02-21T05:09:58.167950Z","level":"WARN","message":"Could not find a fast tokenizer implementation for google/flan-t5-small","target":"text_generation_router","filename":"router/src/main.
rs","line_number":166}
{"timestamp":"2024-02-21T05:09:58.167999Z","level":"WARN","message":"Rust input length validation and truncation is disabled","target":"text_generation_router","filename":"router/src/main.rs","line_number
":169}
{"timestamp":"2024-02-21T05:09:58.168006Z","level":"WARN","message":"`--revision` is not set","target":"text_generation_router","filename":"router/src/main.rs","line_number":349}
{"timestamp":"2024-02-21T05:09:58.168012Z","level":"WARN","message":"We strongly advise to set it to a known supported commit.","target":"text_generation_router","filename":"router/src/main.rs","line_numb
er":350}
{"timestamp":"2024-02-21T05:09:58.306446Z","level":"INFO","message":"Serving revision 0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab of model google/flan-t5-small","target":"text_generation_router","filename":"
router/src/main.rs","line_number":371}
{"timestamp":"2024-02-21T05:09:58.311499Z","level":"INFO","message":"Warming up model","target":"text_generation_router","filename":"router/src/main.rs","line_number":213}
{"timestamp":"2024-02-21T05:10:01.304539Z","level":"WARN","message":"Model does not support automatic max batch total tokens","target":"text_generation_router","filename":"router/src/main.rs","line_number
":224}
{"timestamp":"2024-02-21T05:10:01.304575Z","level":"INFO","message":"Setting max batch total tokens to 16000","target":"text_generation_router","filename":"router/src/main.rs","line_number":246}
{"timestamp":"2024-02-21T05:10:01.304586Z","level":"INFO","message":"Connected","target":"text_generation_router","filename":"router/src/main.rs","line_number":247}
{"timestamp":"2024-02-21T05:10:01.304595Z","level":"WARN","message":"Invalid hostname, defaulting to 0.0.0.0","target":"text_generation_router","filename":"router/src/main.rs","line_number":252}

# 创建 service
cat <<EOF | oc apply -f -
kind: Service
apiVersion: v1
metadata:
  name: hf-text-generation-inference-server
  labels:
    app: hf-text-generation-inference-server
spec:
  clusterIP: None
  ipFamilies:
    - IPv4
  ports:
    - name: http
      protocol: TCP
      port: 3000
      targetPort: http
  type: ClusterIP
  ipFamilyPolicy: SingleStack
  sessionAffinity: None
  selector:
    app: hf-text-generation-inference-server
EOF

# 创建 route
$ cat <<EOF | oc apply -f -
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: hf-text-generation-inference-server
  labels:
    app: hf-text-generation-inference-server
spec:
  to:
    kind: Service
    name: hf-text-generation-inference-server
    weight: 100
  port:
    targetPort: http
  tls:
    termination: edge
  wildcardPolicy: None
EOF

$ oc get route
NAME                                  HOST/PORT                                                                              PATH   SERVICES                              PORT   TERMINATION   WILDCARD
hf-text-generation-inference-server   hf-text-generation-inference-server-dsp01.apps.cluster-26bnl.sandbox1553.opentlc.com          hf-text-generation-inference-server   http   edge          None

# 测试
$ curl -k https://$(oc get route hf-text-generation-inference-server -o jsonpath='{.spec.host}')/generate \
    -X POST \
    -d '{"inputs":"What is Deep Learning?","parameters":{"max_new_tokens":20}}' \
    -H 'Content-Type: application/json'
{"generated_text":"Deep learning is a learning process that involves learning to learn."}

$ curl -k https://$(oc get route hf-text-generation-inference-server -o jsonpath='{.spec.host}')/generate_stream \
    -X POST \
    -d '{"inputs":"What is Deep Learning?","parameters":{"max_new_tokens":20}}' \
    -H 'Content-Type: application/json'
data:{"token":{"id":9509,"text":" Deep","logprob":-0.5175781,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":1036,"text":" learning","logprob":-0.21582031,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":19,"text":" is","logprob":-1.3515625,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":3,"text":" ","logprob":-0.7524414,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":9,"text":"a","logprob":-0.0068893433,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":1036,"text":" learning","logprob":-2.4960938,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":433,"text":" process","logprob":-2.2460938,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":24,"text":" that","logprob":-0.9345703,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":5806,"text":" involves","logprob":-2.0273438,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":1036,"text":" learning","logprob":-1.1386719,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":12,"text":" to","logprob":-2.0449219,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":669,"text":" learn","logprob":-2.375,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":5,"text":".","logprob":-2.1367188,"special":false},"generated_text":null,"details":null}

data:{"token":{"id":1,"text":"</s>","logprob":-0.30688477,"special":true},"generated_text":"Deep learning is a learning process that involves learning to learn.","details":null}

# 查看进程
$ oc exec -it $(oc get pods -l app=hf-text-generation-inference-server -o name) /bin/bash
1000790000@hf-text-generation-inference-server-5df6759cd6-48zxb:/usr/src$ ps -ax
    PID TTY      STAT   TIME COMMAND
      1 ?        Ssl    0:00 text-generation-launcher --json-output
     30 ?        Sl     0:16 /opt/conda/bin/python3.10 /opt/conda/bin/text-generation-server serve google/flan-t5-small --uds-path /tmp/text-generation-server --logger-level INFO --json-output --quantize bitsandbytes
     69 ?        Sl     0:00 text-generation-router --max-concurrent-requests 128 --max-best-of 2 --max-stop-sequences 4 --max-top-n-tokens 5 --max-input-length 1024 --max-total-tokens 2048 --max-batch-prefill-tokens 4096 --waiting-served-ratio 1.2 --max-waiting-tokens 20 --validation-workers 2 --hostname hf-text-generation-inference-server-5df6759cd6-48zxb --port 3000 --master-shard-uds-path /tmp/text-generation-server-0 --tokenizer-name google/flan-t5-small --json-output
     88 pts/0    Ss     0:00 /bin/bash

# 模型文件
1000790000@hf-text-generation-inference-server-5df6759cd6-48zxb:/usr/src$ find /models-cache/models--google--flan-t5-small
/models-cache/models--google--flan-t5-small
/models-cache/models--google--flan-t5-small/blobs
/models-cache/models--google--flan-t5-small/blobs/fc669fbad1a6a82119ca3e1fa75db33ee22ca47d
/models-cache/models--google--flan-t5-small/blobs/360a0073f29a105ced4a366cda27e668b11bb73b
/models-cache/models--google--flan-t5-small/blobs/d60acb128cf7b7f2536e8f38a5b18a05535c9e14c7a355904270e15b0945ea86
/models-cache/models--google--flan-t5-small/blobs/db13bf98b7714acc4dea7621ff7f4ab93f64258e
/models-cache/models--google--flan-t5-small/blobs/495fa51e204676f1a857a9fc13c4c89f3f5ba9f480b898cebca02add25e6d749
/models-cache/models--google--flan-t5-small/blobs/2c19eb6e3b583f52d34b903b5978d3d30b6b7682
/models-cache/models--google--flan-t5-small/refs
/models-cache/models--google--flan-t5-small/refs/main
/models-cache/models--google--flan-t5-small/snapshots
/models-cache/models--google--flan-t5-small/snapshots/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab
/models-cache/models--google--flan-t5-small/snapshots/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab/tokenizer_config.json
/models-cache/models--google--flan-t5-small/snapshots/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab/model.safetensors
/models-cache/models--google--flan-t5-small/snapshots/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab/spiece.model
/models-cache/models--google--flan-t5-small/snapshots/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab/special_tokens_map.json
/models-cache/models--google--flan-t5-small/snapshots/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab/tokenizer.json
/models-cache/models--google--flan-t5-small/snapshots/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab/config.json
/models-cache/models--google--flan-t5-small/.no_exist
/models-cache/models--google--flan-t5-small/.no_exist/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab
/models-cache/models--google--flan-t5-small/.no_exist/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab/added_tokens.json
/models-cache/models--google--flan-t5-small/.no_exist/0fc9ddf78a1e988dac52e2dac162b0ede4fd74ab/adapter_config.json

# 定义一个新的 ServingRuntime
$ oc project redhat-ods-applications
$ cat <<EOF | oc apply -f -
apiVersion: serving.kserve.io/v1alpha1
kind: ServingRuntime
metadata:
  name: hf-tgi-runtime
spec:
  containers:
    - name: kserve-container
      image: ghcr.io/huggingface/text-generation-inference:1.4.0
      command: ["text-generation-launcher"]
      args:
        - "--model-id=/mnt/models/"
        - "--port=3000"
      env:
      - name: HF_HOME
        value: /tmp/hf_home
      - name: HUGGINGFACE_HUB_CACHE
        value: /tmp/hf_hub_cache
      - name: TRANSFORMER_CACHE
        value: /tmp/transformers_cache
      #resources: # configure as required
      #  requests:
      #    nvidia.com/gpu: 1
      #  limits:
      #    nvidia.com/gpu: 1
      readinessProbe: # Use exec probes instad of httpGet since the probes' port gets rewritten to the containerPort
        exec:
          command:
            - curl
            - localhost:3000/health
        initialDelaySeconds: 30
      livenessProbe:
        exec:
          command:
            - curl
            - localhost:3000/health
        initialDelaySeconds: 30
      ports:
        - containerPort: 3000
          protocol: TCP
  multiModel: false
  supportedModelFormats:
    - autoSelect: true
      name: pytorch
```

# 下载模型google/flan-t5-small并保存模型格式为caikit-tgis-serving所支持的格式到pvc
```
oc project dsp01
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: caikit-claim
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: setup-flan-t5-small
spec:
  volumes:
    - name: model-volume
      persistentVolumeClaim:
        claimName: caikit-claim
  restartPolicy: Never
  initContainers:
    - name: fix-volume-permissions
      image: busybox
      command: ["sh"]
      args: ["-c", "chown -R 1001:1001 /mnt/models"]
      volumeMounts:
        - mountPath: "/mnt/models/"
          name: model-volume
  containers:
    - name: download-model
      image: quay.io/opendatahub/caikit-tgis-serving:fast
      command: ["python", "-c"]
      args: [
          'import caikit_nlp;
          caikit_nlp.text_generation.TextGeneration.bootstrap(
          "google/flan-t5-small"
          ).save(
          "/mnt/models/flan-t5-small-caikit"
          )',
        ]
      env:
        - name: ALLOW_DOWNLOADS
          value: "1"
        - name: TRANSFORMERS_CACHE
          value: "/tmp"
      volumeMounts:
        - mountPath: "/mnt/models/"
          name: model-volume
EOF

# 拷贝模型文件到本地
$ mkdir -p ~/tmp/flan-t5-small-caikit/artifacts
$ cd ~/tmp/flan-t5-small-caikit/artifacts
cat <<EOF | oc apply -f -
---
apiVersion: v1
kind: Pod
metadata:
  name: check-flan-t5-small
spec:
  volumes:
    - name: model-volume
      persistentVolumeClaim:
        claimName: caikit-claim
  restartPolicy: Never
  initContainers:
    - name: fix-volume-permissions
      image: busybox
      command: ["sh"]
      args: ["-c", "chown -R 1001:1001 /mnt/models"]
      volumeMounts:
        - mountPath: "/mnt/models/"
          name: model-volume
  containers:
    - name: check-download-model
      image: quay.io/opendatahub/caikit-tgis-serving:fast
      command: ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
      volumeMounts:
        - mountPath: "/mnt/models/"
          name: model-volume
EOF

$ oc get pods check-flan-t5-small
NAME                  READY   STATUS    RESTARTS   AGE
check-flan-t5-small   1/1     Running   0          19m

# 拷贝模型文件到本地
oc exec -i check-flan-t5-small -- bash -c 'cat - < /mnt/models/flan-t5-small-caikit/artifacts/config.json'  > config.json
oc exec -i check-flan-t5-small -- bash -c 'cat - < /mnt/models/flan-t5-small-caikit/artifacts/model.safetensors'  > model.safetensors
oc exec -i check-flan-t5-small -- bash -c 'cat - < /mnt/models/flan-t5-small-caikit/artifacts/tokenizer.json'  > tokenizer.json
oc exec -i check-flan-t5-small -- bash -c 'cat - < /mnt/models/flan-t5-small-caikit/artifacts/generation_config.json'  > generation_config.json
oc exec -i check-flan-t5-small -- bash -c 'cat - < /mnt/models/flan-t5-small-caikit/artifacts/special_tokens_map.json'  > special_tokens_map.json
oc exec -i check-flan-t5-small -- bash -c 'cat - < /mnt/models/flan-t5-small-caikit/artifacts/tokenizer_config.json'  > tokenizer_config.json
cd ~/tmp/flan-t5-small-caikit

oc exec -i check-flan-t5-small -- bash -c 'cat - < /mnt/models/flan-t5-small-caikit/config.yml'  > config.yml

# 查看文件
[junwang@JundeMacBook-Pro ~/tmp/flan-t5-small-caikit]$ tree . 
.
├── artifacts
│   ├── config.json
│   ├── generation_config.json
│   ├── model.safetensors
│   ├── special_tokens_map.json
│   ├── tokenizer.json
│   └── tokenizer_config.json
└── config.yml

aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 ls

# 上传文件到 s3 buckect rhoai 下
aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 cp config.yml s3://rhoai/models/flan-t5-small-caikit/config.yml

aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 cp artifacts/config.json s3://rhoai/models/flan-t5-small-caikit/artifacts/config.json

aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 cp artifacts/generation_config.json s3://rhoai/models/flan-t5-small-caikit/artifacts/generation_config.json

aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 cp artifacts/model.safetensors s3://rhoai/models/flan-t5-small-caikit/artifacts/model.safetensors

aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 cp artifacts/special_tokens_map.json s3://rhoai/models/flan-t5-small-caikit/artifacts/special_tokens_map.json

aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 cp artifacts/tokenizer.json s3://rhoai/models/flan-t5-small-caikit/artifacts/tokenizer.json

aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 cp artifacts/tokenizer_config.json s3://rhoai/models/flan-t5-small-caikit/artifacts/tokenizer_config.json

# 查看 s3 bucket 内容
aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 ls s3://rhoai/models/flan-t5-small-caikit/
                           PRE artifacts/
2024-02-21 17:04:08        424 config.yml

aws --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 ls s3://rhoai/models/flan-t5-small-caikit/artifacts/
2024-02-21 17:05:08       1555 config.json
2024-02-21 17:07:07        142 generation_config.json
2024-02-21 17:07:43  306511872 model.safetensors
2024-02-21 17:07:51       2543 special_tokens_map.json
2024-02-21 17:07:59    2422256 tokenizer.json
2024-02-21 17:08:05      20798 tokenizer_config.json
```