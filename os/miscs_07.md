### Kubevirt VM example

### this is a example of kubevirt virtualmachine 
```
cat <<EOF | oc apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: intel-eci-ubuntu-01
  namespace: vms
spec:
  dataVolumeTemplates:
  - metadata:
      creationTimestamp: null
      name: intel-eci-ubuntu-01-disk1
    spec:
      preallocation: false
      source:
        pvc:
          name: ubuntu-dv-force-bind
          namespace: vms 
      storage:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 30Gi
        storageClassName: hostpath-csi-i
  running: false
  template:
    metadata:
      annotations:
        cpu-load-balancing.crio.io: disable
        cpu-quota.crio.io: disable
        irq-loadbalancing.crio.io: disable
      creationTimestamp: null
      labels:
        vm-name: intel-eci-unbuntu-01
    spec:
      accessCredentials:
      - sshPublicKey:
          propagationMethod:
            noCloud: {}
          source:
            secret:
              secretName: ocp-helper-ssh-pub
      architecture: amd64
      domain:
        ioThreadsPolicy: auto
        cpu:
          dedicatedCpuPlacement: true
          features:
          - name: tsc-deadline
            policy: require
          isolateEmulatorThread: true
          model: host-passthrough
          numa:
            guestMappingPassthrough: {}
          realtime: {}
        devices:
          autoattachGraphicsDevices: false
          autoattachMemBalloon: false
          autoattachSerialConsole: true
          disks:
          - bootOrder: 1
            disk:
              bus: virtio
            name: rootdisk
          - bootOrder: 2
            disk:
              bus: virtio
            name: cloudinitdisk
        machine:
          type: pc-q35-rhel9.2.0
        memory:
          hugepages:
            pageSize: 1Gi
        resources:
          limits:
            cpu: "2"
            memory: 4Gi
          requests:
            cpu: "2"
            memory: 4Gi
      nodeSelector:
        kubernetes.io/hostname: worker2.ocp.test.com  
      volumes:
      - dataVolume:
          name: intel-eci-ubuntu-01-disk1
        name: rootdisk
      - cloudInitNoCloud:
          userData: |
            #cloud-config
            chpasswd:
              expire: false
            password: XXXXXXXX
            user: ubuntu
        name: cloudinitdisk
EOF
```