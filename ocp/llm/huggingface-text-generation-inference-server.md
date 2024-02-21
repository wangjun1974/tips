
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
