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

### Mac and serial port 
```
https://stackoverflow.com/questions/12254378/how-to-find-the-serial-port-number-on-mac-os-x
brew install minicom
```

### 恢复或者重装操作系统
```
https://support.apple.com/en-il/guide/mac-help/mchl338cf9a8/mac
```

### kvm usb device auto passthrough 
```
https://nickpegg.com/2021/01/kvm-usb-auto-passthrough/
cat > /etc/udev/rules.d/90-libvirt-usb.rules <<'EOF'
ACTION=="bind", \
  SUBSYSTEM=="usb", \
  ENV{ID_VENDOR_ID}=="6b62", \
  ENV{ID_MODEL_ID}=="6869", \
  RUN+="/usr/local/bin/kvm-udev attach steam"
ACTION=="remove", \
  SUBSYSTEM=="usb", \
  ENV{ID_VENDOR_ID}=="6b62", \
  ENV{ID_MODEL_ID}=="6869", \
  RUN+="/usr/local/bin/kvm-udev detach steam"
EOF

cat > /usr/local/bin/kvm-udev <<'FOF'
#!/bin/bash

# Usage: ./kvm-udev.sh attach|detach <domain>

set -e

ACTION=$1
DOMAIN=$2

CONF_FILE=$(mktemp --suffix=.kvm-udev)
cat << EOF >$CONF_FILE
<hostdev mode='subsystem' type='usb'>
  <source>
    <vendor id='0x${ID_VENDOR_ID}' />
    <product id='0x${ID_MODEL_ID}' />
  </source>
</hostdev>
EOF

virsh "${ACTION}-device" "$DOMAIN" "$CONF_FILE"
rm "$CONF_FILE"
FOF
```

### virtio-win 驱动下载
https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/

### pci device pass through
https://www.ibm.com/docs/en/linux-on-systems?topic=vfio-pass-through-pci

### 检查 ubuntu grub menu entry 
```
awk '/menuentry/ && /class/ {count++; print count-1"****"$0 }' /boot/grub/grub.cfg
```

### ubuntu 安装旧内核版本
https://community.sisense.com/t5/knowledge/how-to-install-new-kernel-or-update-existing-one-in-ubuntu/ta-p/7794
```
sudo apt list linux-*image-* | grep generic
sudo apt -fix-broken install linux-image-5.4.0-137-generic 
```

### 查询virt-install有哪些os-variant
```
virt-install --osinfo list
```

### 安装 kernel-rt-core kernel-source
```
$ dnf install yum-utils rpm-build python3-devel
$ yumdownloader --source kernel-rt-core
$ echo '%_topdir %(echo $HOME)/rpmbuild' > .rpmmacros
$ subscription-manager repos --enable=codeready-builder-for-rhel-9-x86_64-rpms

$ rpm -ivh kernel-5.14.0-362.24.1.el9_3.src.rpm
$ cd rpmbuild/SPEC
$ rpmbuild -bp kernel.spec
```

### virt-install安装ubuntu 22.04
```
virt-install -n ubuntu2204-inteleci31 --os-variant=ubuntu22.04 --memory=8192,hugepages=yes --memorybacking hugepages=yes,size=1,unit=G,locked=yes --vcpus=2 --numatune=0 --disk path=/var/lib/libvirt/images/utuntu2204-inteleci31.img,bus=virtio,cache=none,format=raw,io=threads,size=30 --network network=default,model=virtio --graphics none --console pty,target_type=serial -l /var/lib/libvirt/images/ubuntu-22.04.4-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd --extra-args 'console=ttyS0,115200n8 serial'
```