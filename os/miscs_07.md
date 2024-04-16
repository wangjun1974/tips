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

### 检查物理cpu情况
```
$ pidof qemu-kvm
$ cd /proc/qemu_pid
$ cd /sys/fs/cgroup/cpuset/`cat cpuset`
$ cd ..
$ cat tasks housekeeping/tasks | while read p; do echo -n $p: ; cat /proc/$p/task/$p/comm; cat /proc/$p/status | grep Cpus_allowed_list;  done
```

### install ubuntu2204 in console mode
```
$ virt-install -n utuntu2204-inteleci31 --os-variant=ubuntu22.04 --memory=8192,hugepages=yes --memorybacking hugepages=yes,size=1,unit=G,locked=yes --vcpus=4 --numatune=0 --disk path=/var/lib/libvirt/images/utuntu2204-inteleci31.img,bus=virtio,cache=none,format=raw,io=threads,size=30 --graphics none --console pty,target_type=serial -l /var/lib/libvirt/images/ubuntu-22.04.4-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd --extra-args 'console=ttyS0,115200n8 serial'
```

### apt-file search which file provides file
```
apt-file search stress-ng
apt-file search cyclictest
```