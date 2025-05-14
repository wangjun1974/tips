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

### NodeHealthCheck的例子
```
apiVersion: remediation.medik8s.io/v1alpha1
kind: NodeHealthCheck
metadata:
  name: 'nodehealthcheck-cnv'
spec:
  selector:
    matchExpressions:
    - key: node-role.kubernetes.io/worker
      operator: Exists
    - key: node-role.kubernetes.io/master
      operator: DoesNotExist
  remediationTemplate:
    apiVersion: self-node-remediation.medik8s.io/v1alpha1
    kind: SelfNodeRemediationTemplate
    namespace: openshift-workload-availability
    name: self-node-remediation-automatic-strategy-template
  unhealthyConditions:
    - duration: 60s
      status: 'False'
      type: Ready
    - duration: 60s
      status: Unknown
      type: Ready
  minHealthy: 0%
```

### ubuntu ssh password auth
https://medium.com/@ravidevops2470/how-to-enable-ssh-with-password-authentication-on-ubuntu-22-04-a7cbdf476d8b

### 
```
dmsetup info --columns 
cinder--volumes-volume--120a8e2d--cf3c--43dd--a48e--7fc938c44f0d 253   9 L--w    1    1      0 LVM-Y8HA2wVMTi0o7fkMd4zc3WMvL1BMLEv94dbrUl8URTuZS9E9nd5eUe2h5RUViB30

dmsetup remove cinder--volumes-volume--120a8e2d--cf3c--43dd--a48e--7fc938c44f0d
device-mapper: remove ioctl on cinder--volumes-volume--120a8e2d--cf3c--43dd--a48e--7fc938c44f0d  failed: Device or resource busy

https://duncancloud.blogspot.com/2016/05/lvm-remove-ioctl-on-failed-device-or.html
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_storage_devices/configuring-an-iscsi-target_managing-storage-devices#removing-an-iscsi-object-using-targetcli-tool_configuring-an-iscsi-target

backstores/block/ delete iqn.2010-10.org.openstack:volume-120a8e2d-cf3c-43dd-a48e-7fc938c44f0d
iscsi/ delete iqn.2010-10.org.openstack:volume-120a8e2d-cf3c-43dd-a48e-7fc938c44f0d
  File "/usr/bin/targetcli", line 317, in main
    shell.run_interactive()
  File "/usr/lib/python3.6/site-packages/configshell_fb/shell.py", line 900, in run_interactive
    self._cli_loop()
  File "/usr/lib/python3.6/site-packages/configshell_fb/shell.py", line 729, in _cli_loop
    self.run_cmdline(cmdline)
  File "/usr/lib/python3.6/site-packages/configshell_fb/shell.py", line 843, in run_cmdline
    self._execute_command(path, command, pparams, kparams)
  File "/usr/lib/python3.6/site-packages/configshell_fb/shell.py", line 818, in _execute_command
    result = target.execute_command(command, pparams, kparams)
  File "/usr/lib/python3.6/site-packages/configshell_fb/node.py", line 1406, in execute_command
    return method(*pparams, **kparams)
  File "/usr/lib/python3.6/site-packages/targetcli/ui_backstore.py", line 309, in ui_command_delete
    child.rtsnode.delete(save=save)
  File "/usr/lib/python3.6/site-packages/rtslib_fb/tcm.py", line 269, in delete
    for lun in self._gen_attached_luns():
  File "/usr/lib/python3.6/site-packages/rtslib_fb/tcm.py", line 215, in _gen_attached_luns
    for tpgt_dir in listdir(tpgts_base):
NotADirectoryError: [Errno 20] Not a directory: '/sys/kernel/config/target/iscsi/cpus_allowed_list'

### 更新 python3-rtslib 和 target-restore
wget -O 'https://access.cdn.redhat.com/content/origin/rpms/python3-rtslib/2.1.75/4.el8/fd431d51/python3-rtslib-2.1.75-4.el8.noarch.rpm?user=b7b0b556ec14123110fb684718376553&_auth_=1715665022_55b27f93d1605041cbe3943dd3eeed2d' python3-rtslib-2.1.75-4.el8.noarch.rpm

### 查看iscsi相关信息
targetcli 
/> ls
o- / ..................................................................................................... [...]
  o- backstores .......................................................................................... [...]
  | o- block .............................................................................. [Storage Objects: 7]
  | | o- iqn.2010-10.org.openstack:volume-12170175-642f-4bc4-8d2f-e59d549eed14  [/dev/cinder-volumes/volume-12170175-642f-4bc4-8d2f-e59d549eed14 (1.0GiB) write-thru activated]
  | | | o- alua ............................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ................................................... [ALUA state: Active/optimized]
  | | o- iqn.2010-10.org.openstack:volume-4f16fa4c-a93e-4c24-92ee-9dcc48d28ff8  [/dev/cinder-volumes/volume-4f16fa4c-a93e-4c24-92ee-9dcc48d28ff8 (20.0GiB) write-thru activated]
  | | | o- alua ............................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ................................................... [ALUA state: Active/optimized]
  | | o- iqn.2010-10.org.openstack:volume-6f148688-0cd2-44ca-b3fc-02f5b4ea0c37  [/dev/cinder-volumes/volume-6f148688-0cd2-44ca-b3fc-02f5b4ea0c37 (40.0GiB) write-thru activated]
  | | | o- alua ............................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ................................................... [ALUA state: Active/optimized]
  | | o- iqn.2010-10.org.openstack:volume-93e0e615-113d-4650-b5e0-52e062172555  [/dev/cinder-volumes/volume-93e0e615-113d-4650-b5e0-52e062172555 (1.0GiB) write-thru activated]
  | | | o- alua ............................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ................................................... [ALUA state: Active/optimized]
  | | o- iqn.2010-10.org.openstack:volume-a9d79cbb-db53-4425-a1b8-29fbd66ad253  [/dev/cinder-volumes/volume-a9d79cbb-db53-4425-a1b8-29fbd66ad253 (10.0GiB) write-thru activated]
  | | | o- alua ............................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ................................................... [ALUA state: Active/optimized]
  | | o- iqn.2010-10.org.openstack:volume-b02bc9d1-7b58-4984-93fe-e3a784f0309d  [/dev/cinder-volumes/volume-b02bc9d1-7b58-4984-93fe-e3a784f0309d (20.0GiB) write-thru activated]
  | | | o- alua ............................................................................... [ALUA Groups: 1]
  | | |   o- default_tg_pt_gp ................................................... [ALUA state: Active/optimized]
  | | o- iqn.2010-10.org.openstack:volume-b0997248-9b94-4fda-b9f8-aa893387127d  [/dev/cinder-volumes/volume-b0997248-9b94-4fda-b9f8-aa893387127d (22.0GiB) write-thru activated]
  | |   o- alua ............................................................................... [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ................................................... [ALUA state: Active/optimized]
  | o- fileio ............................................................................. [Storage Objects: 0]
  | o- pscsi .............................................................................. [Storage Objects: 0]
  | o- ramdisk ............................................................................ [Storage Objects: 0]
  o- iscsi ........................................................................................ [Targets: 7]
  | o- iqn.2010-10.org.openstack:volume-12170175-642f-4bc4-8d2f-e59d549eed14 ......................... [TPGs: 1]
  | | o- tpg1 ...................................................................... [no-gen-acls, auth per-acl]
  | |   o- acls ...................................................................................... [ACLs: 1]
  | |   | o- iqn.1994-05.com.redhat:372aa22b28bc .................................. [1-way auth, Mapped LUNs: 1]
  | |   |   o- mapped_lun0  [lun0 block/iqn.2010-10.org.openstack:volume-12170175-642f-4bc4-8d2f-e59d549eed14 (rw)]
  | |   o- luns ...................................................................................... [LUNs: 1]
  | |   | o- lun0  [block/iqn.2010-10.org.openstack:volume-12170175-642f-4bc4-8d2f-e59d549eed14 (/dev/cinder-volumes/volume-12170175-642f-4bc4-8d2f-e59d549eed14) (default_tg_pt_gp)]
  | |   o- portals ................................................................................ [Portals: 1]
  | |     o- 192.168.39.125:3260 .......................................................................... [OK]
  | o- iqn.2010-10.org.openstack:volume-4f16fa4c-a93e-4c24-92ee-9dcc48d28ff8 ......................... [TPGs: 1]
  | | o- tpg1 ...................................................................... [no-gen-acls, auth per-acl]
  | |   o- acls ...................................................................................... [ACLs: 1]
  | |   | o- iqn.1994-05.com.redhat:372aa22b28bc .................................. [1-way auth, Mapped LUNs: 1]
  | |   |   o- mapped_lun0  [lun0 block/iqn.2010-10.org.openstack:volume-4f16fa4c-a93e-4c24-92ee-9dcc48d28ff8 (rw)]
  | |   o- luns ...................................................................................... [LUNs: 1]
  | |   | o- lun0  [block/iqn.2010-10.org.openstack:volume-4f16fa4c-a93e-4c24-92ee-9dcc48d28ff8 (/dev/cinder-volumes/volume-4f16fa4c-a93e-4c24-92ee-9dcc48d28ff8) (default_tg_pt_gp)]
  | |   o- portals ................................................................................ [Portals: 1]
  | |     o- 192.168.39.125:3260 .......................................................................... [OK]
  | o- iqn.2010-10.org.openstack:volume-6f148688-0cd2-44ca-b3fc-02f5b4ea0c37 ......................... [TPGs: 1]
  | | o- tpg1 ...................................................................... [no-gen-acls, auth per-acl]
  | |   o- acls ...................................................................................... [ACLs: 1]
  | |   | o- iqn.1994-05.com.redhat:372aa22b28bc .................................. [1-way auth, Mapped LUNs: 1]
  | |   |   o- mapped_lun0  [lun0 block/iqn.2010-10.org.openstack:volume-6f148688-0cd2-44ca-b3fc-02f5b4ea0c37 (rw)]
  | |   o- luns ...................................................................................... [LUNs: 1]
  | |   | o- lun0  [block/iqn.2010-10.org.openstack:volume-6f148688-0cd2-44ca-b3fc-02f5b4ea0c37 (/dev/cinder-volumes/volume-6f148688-0cd2-44ca-b3fc-02f5b4ea0c37) (default_tg_pt_gp)]
  | |   o- portals ................................................................................ [Portals: 1]
  | |     o- 192.168.39.125:3260 .......................................................................... [OK]
  | o- iqn.2010-10.org.openstack:volume-93e0e615-113d-4650-b5e0-52e062172555 ......................... [TPGs: 1]
  | | o- tpg1 ...................................................................... [no-gen-acls, auth per-acl]
  | |   o- acls ...................................................................................... [ACLs: 1]
  | |   | o- iqn.1994-05.com.redhat:372aa22b28bc .................................. [1-way auth, Mapped LUNs: 1]
  | |   |   o- mapped_lun0  [lun0 block/iqn.2010-10.org.openstack:volume-93e0e615-113d-4650-b5e0-52e062172555 (rw)]
  | |   o- luns ...................................................................................... [LUNs: 1]
  | |   | o- lun0  [block/iqn.2010-10.org.openstack:volume-93e0e615-113d-4650-b5e0-52e062172555 (/dev/cinder-volumes/volume-93e0e615-113d-4650-b5e0-52e062172555) (default_tg_pt_gp)]
  | |   o- portals ................................................................................ [Portals: 1]
  | |     o- 192.168.39.125:3260 .......................................................................... [OK]
  | o- iqn.2010-10.org.openstack:volume-a9d79cbb-db53-4425-a1b8-29fbd66ad253 ......................... [TPGs: 1]
  | | o- tpg1 ...................................................................... [no-gen-acls, auth per-acl]
  | |   o- acls ...................................................................................... [ACLs: 1]
  | |   | o- iqn.1994-05.com.redhat:372aa22b28bc .................................. [1-way auth, Mapped LUNs: 1]
  | |   |   o- mapped_lun0  [lun0 block/iqn.2010-10.org.openstack:volume-a9d79cbb-db53-4425-a1b8-29fbd66ad253 (rw)]
  | |   o- luns ...................................................................................... [LUNs: 1]
  | |   | o- lun0  [block/iqn.2010-10.org.openstack:volume-a9d79cbb-db53-4425-a1b8-29fbd66ad253 (/dev/cinder-volumes/volume-a9d79cbb-db53-4425-a1b8-29fbd66ad253) (default_tg_pt_gp)]
  | |   o- portals ................................................................................ [Portals: 1]
  | |     o- 192.168.39.125:3260 .......................................................................... [OK]
  | o- iqn.2010-10.org.openstack:volume-b02bc9d1-7b58-4984-93fe-e3a784f0309d ......................... [TPGs: 1]
  | | o- tpg1 ...................................................................... [no-gen-acls, auth per-acl]
  | |   o- acls ...................................................................................... [ACLs: 1]
  | |   | o- iqn.1994-05.com.redhat:372aa22b28bc .................................. [1-way auth, Mapped LUNs: 1]
  | |   |   o- mapped_lun0  [lun0 block/iqn.2010-10.org.openstack:volume-b02bc9d1-7b58-4984-93fe-e3a784f0309d (rw)]
  | |   o- luns ...................................................................................... [LUNs: 1]
  | |   | o- lun0  [block/iqn.2010-10.org.openstack:volume-b02bc9d1-7b58-4984-93fe-e3a784f0309d (/dev/cinder-volumes/volume-b02bc9d1-7b58-4984-93fe-e3a784f0309d) (default_tg_pt_gp)]
  | |   o- portals ................................................................................ [Portals: 1]
  | |     o- 192.168.39.125:3260 .......................................................................... [OK]
  | o- iqn.2010-10.org.openstack:volume-b0997248-9b94-4fda-b9f8-aa893387127d ......................... [TPGs: 1]
  |   o- tpg1 ...................................................................... [no-gen-acls, auth per-acl]
  |     o- acls ...................................................................................... [ACLs: 1]
  |     | o- iqn.1994-05.com.redhat:372aa22b28bc .................................. [1-way auth, Mapped LUNs: 1]
  |     |   o- mapped_lun0  [lun0 block/iqn.2010-10.org.openstack:volume-b0997248-9b94-4fda-b9f8-aa893387127d (rw)]
  |     o- luns ...................................................................................... [LUNs: 1]
  |     | o- lun0  [block/iqn.2010-10.org.openstack:volume-b0997248-9b94-4fda-b9f8-aa893387127d (/dev/cinder-volumes/volume-b0997248-9b94-4fda-b9f8-aa893387127d) (default_tg_pt_gp)]
  |     o- portals ................................................................................ [Portals: 1]
  |       o- 192.168.39.125:3260 ....
### 删除 backstore/block 下的对象
> backstores/block delete XXXXX
### 删除 iscsi 下的对象
> iscsi delete XXXX

### 删除 cinder volume
$ lvs
  LV                                          VG             Attr       LSize   Pool                Origin Data%  Meta%  Move Log Cpy%Sync Convert
  cinder-volumes-pool                         cinder-volumes twi-aotz--  19.57g                            86.94  33.32                           
  volume-120a8e2d-cf3c-43dd-a48e-7fc938c44f0d cinder-volumes Vwi-a-tz--  40.00g cinder-volumes-pool        13.16                                  
  volume-12170175-642f-4bc4-8d2f-e59d549eed14 cinder-volumes Vwi-aotz--   1.00g cinder-volumes-pool        8.12                                   
  volume-6f148688-0cd2-44ca-b3fc-02f5b4ea0c37 cinder-volumes Vwi-aotz--  40.00g cinder-volumes-pool        25.07                                  
  volume-b0997248-9b94-4fda-b9f8-aa893387127d cinder-volumes Vwi-aotz--  22.00g cinder-volumes-pool        7.46                                   
  home                                        rhel           -wi-ao----   1.26t                                                                   
  root                                        rhel           -wi-ao----  70.00g                                                                   
  swap                                        rhel           -wi-ao---- <31.44g   

$ lvremove cinder-volumes/volume-120a8e2d-cf3c-43dd-a48e-7fc938c44f0d

### 强制删除 cinder volume
$ openstack volume set --state available 93e0e615-113d-4650-b5e0-52e062172555
$ openstack volume set --detached 93e0e615-113d-4650-b5e0-52e062172555
$ openstack volume delete --force 93e0e615-113d-4650-b5e0-52e062172555
```

### 检查 ODF rbd 和 snapshot 相关信息
```
$ oc patch storagecluster ocs-storagecluster -n openshift-storage --type json --patch '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'
$ oc -n openshift-storage rsh $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)

sh-5.1$ rbd -p ocs-storagecluster-cephblockpool info csi-vol-6d517552-f9c1-4b0d-adda-8d100d4fb44c  
rbd image 'csi-vol-6d517552-f9c1-4b0d-adda-8d100d4fb44c':
        size 90 GiB in 23040 objects
        order 22 (4 MiB objects)
        snapshot_count: 0
        id: 412075328863
        block_name_prefix: rbd_data.412075328863
        format: 2
        features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
        op_features: 
        flags: 
        create_timestamp: Thu May 16 16:22:14 2024
        access_timestamp: Thu May 16 16:22:14 2024
        modify_timestamp: Thu May 16 16:22:14 2024

$ rados -p ocs-storagecluster-cephblockpool ls | grep rbd_data.412075328863 | wc -l 

### VolumeSnapshotContent的
### volumeHandle: 0001-0011-openshift-storage-0000000000000009-6d517552-f9c1-4b0d-adda-8d100d4fb44c
### 需要检查 6d517552-f9c1-4b0d-adda-8d100d4fb44c 后缀部分
$ rbd ls -l ocs-storagecluster-cephblockpool | grep 6d517552-f9c1-4b0d-adda-8d100d4fb44c
csi-snap-4f703880-3740-42c0-ace9-f892d03bcb2e
csi-snap-4f703880-3740-42c0-ace9-f892d03bcb2e@csi-snap-4f703880-3740-42c0-ace9-f892d03bcb2e


```

### openshift client latest
```
https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/
```

### nfs csi 
```
https://www.cnblogs.com/layzer/articles/nfs-csi-use.html
```

### 为 Pod Network 添加路由
```
ip route add 10.128.0.0/14 via 10.0.2.1
```

### kubevirt cnv vm example
### password: xxxxxx -- this is not a real password
```
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: rhel8-vm-01
  namespace: jwang
  finalizers:
    - kubevirt.io/virtualMachineControllerFinalize
  labels:
    app: rhel8-vm-01
    kubevirt.io/dynamic-credentials-support: 'false'
    vm.kubevirt.io/template: rhel8-server-small
    vm.kubevirt.io/template.namespace: openshift
    vm.kubevirt.io/template.revision: '1'
    vm.kubevirt.io/template.version: v0.27.0
spec:
  dataVolumeTemplates:
    - apiVersion: cdi.kubevirt.io/v1beta1
      kind: DataVolume
      metadata:
        creationTimestamp: null
        name: rhel8-vm-01
      spec:
        sourceRef:
          kind: DataSource
          name: rhel8
          namespace: openshift-virtualization-os-images
        storage:
          resources:
            requests:
              storage: 30Gi
  running: false
  template:
    metadata:
      annotations:
        vm.kubevirt.io/flavor: small
        vm.kubevirt.io/os: rhel8
        vm.kubevirt.io/workload: server
      creationTimestamp: null
      labels:
        kubevirt.io/domain: rhel8-vm-01
        kubevirt.io/size: small
    spec:
      architecture: amd64
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
            - disk:
                bus: virtio
              name: rootdisk
            - disk:
                bus: virtio
              name: cloudinitdisk
          interfaces:
            - bridge: {}
              macAddress: 02:d4:c6:00:00:1a
              model: virtio
              name: nic1
            - masquerade: {}
              macAddress: 02:d4:c6:00:00:1b
              name: nic2              
          logSerialConsole: false
          networkInterfaceMultiqueue: true
          rng: {}
        features:
          acpi: {}
          smm:
            enabled: true
        firmware:
          bootloader:
            efi: {}
        machine:
          type: pc-q35-rhel9.2.0
        memory:
          guest: 2Gi
        resources: {}
      networks:
        - multus:
            networkName: 'default/net1'
          name: nic1
        - name: nic2
          pod: {}
      terminationGracePeriodSeconds: 180
      accessCredentials:
      - sshPublicKey:
          source:
            secret:
              secretName: jwang
          propagationMethod:
            qemuGuestAgent:
              users: ["cloud-user"]
      volumes:
        - dataVolume:
            name: rhel8-vm-01
          name: rootdisk
        - cloudInitNoCloud:
            networkData: |-
              version: 2
              ethernets:
                eth1:
                  dhcp4: true
                  routes:
                    - to: 10.128.0.0/14
                      via: 10.0.2.1
                      metric: 100
            userData: |
              #cloud-config
              user: cloud-user
              password: xxxxxx
              chpasswd:
                expire: false
              rh_subscription:
                activation-key: second
                org: 'xxxxxxx'
          name: cloudinitdisk
```

### setup master and worker core user
```
### https://access.redhat.com/solutions/7010657
echo $MYBASE64STRING 
Y29yZTokNiQzQUo3Y3gyb2tNUHpHdnZNJEY0eUNaYjVzTU44d29CVDdFOUFhaktGYnRIeVBJcE0yVnZ0U0ZmS2RNcS5wREcxaDhLYUo5dkU1NjRHWWczaHA4a2dyWVR3bkRTdENZeXRkekU1d08xCg==

cat << EOF > ${IGN_PATH}/openshift/99-master-set-core-passwd.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-set-core-passwd
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$MYBASE64STRING
        mode: 420
        overwrite: true
        path: /etc/core.passwd
    systemd:
      units:
      - name: set-core-passwd.service
        enabled: true
        contents: |
          [Unit]
          Description=Set 'core' user password for out-of-band login
          [Service]
          Type=oneshot
          ExecStart=/bin/sh -c 'chpasswd -e < /etc/core.passwd'
          [Install]
          WantedBy=multi-user.target
EOF

cat << EOF > ${IGN_PATH}/openshift/99-worker-set-core-passwd.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-set-core-passwd
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$MYBASE64STRING
        mode: 420
        overwrite: true
        path: /etc/core.passwd
    systemd:
      units:
      - name: set-core-passwd.service
        enabled: true
        contents: |
          [Unit]
          Description=Set 'core' user password for out-of-band login
          [Service]
          Type=oneshot
          ExecStart=/bin/sh -c 'chpasswd -e < /etc/core.passwd'
          [Install]
          WantedBy=multi-user.target
EOF
```

### route between 2 nat network on libvirt
```
### https://serverfault.com/questions/1109903/libvirt-routing-between-two-nat-networks
<network>
  <name>default</name>
  <uuid>4eb93b42-faf0-43aa-913e-8a454d7c0a0d</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:4e:2e:84'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
  </ip>
</network>

<network>
  <name>provisioning</name>
  <uuid>79803491-ce42-47c1-ad53-638927b9fc04</uuid>
  <forward mode='nat'/>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:f1:fb:a3'/>
  <ip address='192.0.3.254' netmask='255.255.255.0'>
  </ip>
</network>

### Disable masquerading between the two networks, and
iptables -t nat -I POSTROUTING 1 -s 192.168.122.0/24 -d 192.0.3.0/24 -j ACCEPT
iptables -t nat -I POSTROUTING 1 -s 192.0.3.0/24 -d 192.168.122.0/24 -j ACCEPT

### Allow forwarding between the two networks
iptables -I FORWARD 1 -s 192.168.122.0/24 -d 192.0.3.0/24 -j ACCEPT
iptables -I FORWARD 1 -s 192.0.3.0/24 -d 192.168.122.0/24 -j ACCEPT
```

### passthrough GPU in kvm libvirt 
```
https://wiki.gentoo.org/wiki/GPU_passthrough_with_libvirt_qemu_kvm
```

### linux downloader aria2
```
### https://installati.one/centos/8/aria2/
### https://askubuntu.com/questions/214018/how-to-make-wget-faster-or-multithreading
### -c allows continuation of download if it gets interrupted, 
### -x 10 and -s 10 allow up to 10 connections per server, 
### and -d "mydir" outputs file to directory mydir.

$ aria2c --file-allocation=none -c -x 10 -s 10 -d "mydir" URL
```

### OCP ETCD Backup and Restore
```
### https://access.redhat.com/solutions/5599961
```

### 用bbolt工具修复损坏的etcd db
```
https://devopshunger.com/coming-soon/
```

### 演示程序
```
https://medium.com/@deathbreather/setup-a-3-tier-application-in-aws-beginners-guide-d694904a7b87
```

### demo application
```
https://spring.io/guides/gs/accessing-data-mysql#initial
https://github.com/pstauffer/flask-mysql-app?tab=readme-ov-file
https://github.com/spring-guides/gs-accessing-data-mysql.git
```

### setup hash 
```
### https://rakeshjain-devops.medium.com/how-to-create-sha512-sha256-md5-password-hashes-on-command-line-2223db20c08c
### sha256
echo '<RANDOM_TEXT>' | openssl passwd -5 -stdin 
### sha512
echo '<RANDOM_TEXT>' | openssl passwd -6 -stdin
``` 


### 配置Intel i915显卡透传
```
### https://wiki.archlinux.org/index.php/Intel_GVT-g
### https://github.com/intel/gvt-linux/issues/155
### https://www.reddit.com/r/VFIO/comments/12pxo25/full_passthrough_of_12th_gen_iris_xe_seems/
```

### 强制删除处于Terminating状态的Pod
```
for p in $(kubectl get pods | grep Terminating | awk '{print $1}'); do kubectl delete pod $p --grace-period=0 --force;done
```

### QEMU and gvt-d
```
https://github.com/rikka0w0/qemu-gvt-d
```

### 检查qemu-kvm支持的机器类型
```
/usr/libexec/qemu-kvm -machine ? 
```

### 设置libvirt kvm 使用 qemu 命令参数
```
https://libvirt.org/drvqemu.html#pass-through-of-arbitrary-qemu-commands
```

### ARCN iGPU passthrough
```
https://projectacrn.github.io/latest/tutorials/gpu-passthru.html
```

### libvirt windows xml 
```
https://github.com/benwbooth/qemu/blob/master/windows.libvirt.xml
```

### 获取 pci 设备 iommu group 信息
```
for d in /sys/kernel/iommu_groups/*/devices/*; do n=${d#*/iommu_groups/*}; n=${n%%/*}; printf 'IOMMU group %s ' "$n"; lspci -nns "${d##*/}"; done;
```

### text only mode install 
```
https://askubuntu.com/questions/1024895/why-do-i-need-to-replace-quiet-splash-with-nomodeset
https://blog.dowhile0.org/2022/04/22/fedora-36-a-brave-new-drm-kms-only-world/
将启动参数从 quiet 改为 nomodeset

# 1) nomodeset
# The newest kernels have moved the video mode setting into the kernel. So all the programming of the hardware specific clock rates and registers on the video card happen in the kernel rather than in the X driver when the X server starts.. This makes it possible to have high resolution nice looking splash (boot) screens and flicker free transitions from boot splash to login screen. Unfortunately, on some cards this doesnt work properly and you end up with a black screen. Adding the nomodeset parameter instructs the kernel to not load video drivers and use BIOS modes instead until X is loaded.
```

### text mode install
```
https://access.redhat.com/documentation/zh-tw/red_hat_enterprise_linux/9/html-single/boot_options_for_rhel_installer/index#console-environment-and-display-boot-options_kickstart-and-advanced-boot-options

# 修改启动参数
# nomodeset 禁用 kernel graphics driver
# inst.text 采用 text mode 安装
# vga=text 显示模式为 vga 字符模式
nomodeset inst.text vga=text
```

### 检查 iommu group 信息
```
https://github.com/clayfreeman/gpu-passthrough?tab=readme-ov-file#blacklisting-the-gpu
cat > iommu_groups.sh <<'EOF'
#!/bin/bash
shopt -s nullglob
for d in /sys/kernel/iommu_groups/*/devices/*; do
  n=${d#*/iommu_groups/*}; n=${n%%/*}
  printf 'IOMMU Group %s ' "$n"
  lspci -nns "${d##*/}"
done;
EOF
```

### 设置 console=ttyS0，禁用本地显示
```
# iommu=pt intel_iommu=on
# earlymodules=vfio-pci
# vfio-pci.ids=8086:9a49,8086:a0c8
# video=vesafb:off,efifb:off,simplefb:off,vga:off
# nofb
# nomodeset
$ grubby --update-kernel=`grubby --default-kernel` --args="audit=0 idle=poll intel_idle.max_cstate=0 processor.max_cstate=0 mce=off numa=off iommu=pt intel_iommu=on default_hugepagesz=1G hugepagesz=1G hugepages=16 igb.blacklist=no nospectre_v2 nopti hpet=disable clocksource=tsc intel_pstate=disable intel.max_cstate=0 processor_idle.max_cstate=0 rcupdate.rcu_cpu_stall_suppress=1 nmi_watchdog=0 nosoftlockup noht numa_balancing=disable rcu_nocb_poll=1024 earlymodules=vfio-pci vfio-pci.ids=8086:9a49,8086:a0c8 video=vesafb:off,efifb:off,simplefb:off,vga:off nofb nomodeset gfxpayload=text console=ttyS0"
$ cat /proc/cmdline 
BOOT_IMAGE=(hd0,gpt2)/vmlinuz-5.14.0-427.20.1.el9_4.x86_64+rt root=/dev/mapper/rhel_dhcp--192--20-root ro rd.lvm.lv=rhel_dhcp-192-20/root crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M skew_tick=1 tsc=reliable rcupdate.rcu_normal_after_boot=1 isolcpus=managed_irq,domain,1-3 intel_pstate=disable nosoftlockup nohz=on nohz_full=1-3 rcu_nocbs=1-3 irqaffinity=0 i915.enable_gvt=1 i915.enable_guc=0 i915.blacklist=1 rd.driver.blacklist=i915 snd_hda_codec_hdmi.blacklist=1 rd.driver.blacklist=snd_hda_codec_hdmi audit=0 idle=poll intel_idle.max_cstate=0 processor.max_cstate=0 mce=off numa=off iommu=pt intel_iommu=on default_hugepagesz=1G hugepagesz=1G hugepages=16 igb.blacklist=no nospectre_v2 nopti hpet=disable clocksource=tsc intel_pstate=disable intel.max_cstate=0 processor_idle.max_cstate=0 rcupdate.rcu_cpu_stall_suppress=1 nmi_watchdog=0 nosoftlockup noht numa_balancing=disable rcu_nocb_poll=1024 earlymodules=vfio-pci vfio-pci.ids=8086:9a49,8086:a0c8 video=vesafb:off,efifb:off,simplefb:off,vga:off nofb nomodeset gfxpayload=text console=ttyS0
```

### OCP virt-launcher 替换 cert 的步骤
```
1. Obtain virt-launcher image from staging using skopeo
   skopeo copy --src-tls-verify=false docker://<TAG GOES HERE> containers-storage:virt-launcher:<TAG GOES HERE>

2. use buildah to create a new container based on virt-launcher
   buildah unshare
   cnt=$(buildah from virt-launcher:<TAG GOES HERE>)
   mnt=$(buildah mount $cnt)

3. insert keys into that image and commit it
   cp <certs> $mnt/<path inside virt-launcher>
   buildah commit $cnt virt-launcher:<NEW TAG>

4. create a cluster but tell HCO to use custom images (will need help from install upgrade an operators team on how to do that)
```

### 拷贝文件并且追踪进度
```
rsync -avh --progress source_file destination_file
```

### ubuntu 22.04 
```
### 安装 libvirt kvm virt-manager
$ apt-get update

$ apt install qemu-kvm qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf
$ usermod -aG libvirt $USER

$ apt install -y xfce4 xfce4-goodies tigervncserver
$ iptables -A INPUT -p tcp --match multiport --dports 5900:5920 -j ACCEPT
$ cat > xstartup <<'EOF'
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF
$ chmod +x ~/.vnc/xstartup

$ sudo add-apt-repository -y ppa:projectatomic/ppa
$ sudo apt update
$ sudo apt install -y podman

$ cat > /etc/containers/registries.conf <<'EOF'
[registries.search]
registries=["registry.access.redhat.com", "registry.fedoraproject.org", "docker.io"]
EOF

cat > iommu_groups.sh <<'EOF'
#!/bin/bash
# change the 999 if needed
shopt -s nullglob
for d in /sys/kernel/iommu_groups/{0..999}/devices/*; do
    n=${d#*/iommu_groups/*}; n=${n%%/*}
    printf 'IOMMU Group %s ' "$n"
    lspci -nns "${d##*/}"
done;
EOF
$ sudo sed -ie 's|ubuntu--vg-ubuntu--lv ro|ubuntu--vg-ubuntu--lv ro console=ttyS0,115200 iommu=pt intel_iommu=on default_hugepagesz=1G hugepagesz=1G hugepages=8 earlymodules=vfio-pci vfio-pci.ids=8086:9a49 3 nomodeset initcall_blacklist=sysfb_init i915.blacklist=1 rd.driver.blacklist=i915 snd_hda_codec_hdmi.blacklist=1 rd.driver.blacklist=snd_hda_codec_hdmi"|' /boot/grub/grub.cfg
```

### 拷贝iso到usb
```
dd bs=4M if=./ubuntu-22.04.4-live-server-amd64.iso of=/dev/sdc status=progress oflag=sync
```

### kubevirt network internals 
```
https://www.51cto.com/article/710845.html
https://s6.51cto.com/oss/202206/06/e115ad120d0d411933b7187f1f28e1944277d2.jpg
bash-5.1$ ip a s dev eth0 
3: eth0@if249: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc noqueue state UP group default 
    link/ether 0a:58:14:82:02:1f brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 20.130.2.31/23 brd 20.130.3.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::858:14ff:fe82:21f/64 scope link 
       valid_lft forever preferred_lft forever
bash-5.1$ ip a s dev k6t-eth0 
6: k6t-eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc noqueue state UP group default qlen 1000
    link/ether 02:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.1/24 brd 10.0.2.255 scope global k6t-eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::ff:fe00:0/64 scope link 
       valid_lft forever preferred_lft forever
bash-5.1$ ip a s dev tap0 
7: tap0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc fq_codel master k6t-eth0 state UP group default qlen 1000
    link/ether 8a:4a:ae:66:16:11 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::884a:aeff:fe66:1611/64 scope link 
       valid_lft forever preferred_lft forever
```

### 查询具有label的cpu利用率
```
具有label的节点的cpu利用率查询
https://access.redhat.com/solutions/7021585
# cpu
instance:node_cpu_utilisation:rate1m * on(instance) (group by(instance)(label_replace(kube_node_labels{label_pool="pool1"}, "instance", "$1", "node", "(.*)")))
# memory
instance:node_memory_utilisation:ratio * on(instance) (group by(instance)(label_replace(kube_node_labels{label_pool="pool1"}, "instance", "$1", "node", "(.*)")))
# network
instance:node_network_receive_bytes_excluding_lo:rate1m * on(instance) (group by(instance)(label_replace(kube_node_labels{label_pool="pool1"}, "instance", "$1", "node", "(.*)")))
instance:node_network_transmit_bytes_excluding_lo:rate1m * on(instance) (group by(instance)(label_replace(kube_node_labels{label_pool="pool1"}, "instance", "$1", "node", "(.*)")))
# disk
```

### skopeo copy container images to local registry
```
### minio
$ skopeo copy --format v2s2 --all dir:/tmp/minio/minio docker://registry.ocp4.example.com/jwang/minio:RELEASE.2022-07-24T01-54-52Z
$ skopeo copy --format v2s2 --all dir:/tmp/minio/mc docker://registry.ocp4.example.com/jwang/mc:RELEASE.2022-07-24T02-25-13Z
### aws cli 
$ skopeo copy --format v2s2 --all dir:/tmp/amazon docker://registry.ocp4.example.com/jwang/aws-cli:latest
```

### patch vm add interface 的例子
```
### 例子1
### 采用jq同时增加
### .spec.template.spec.domain.devices.interfaces
### .spec.template.spec.networks
$ oc get vm rhel-8-03 -o json | jq '.spec.template.spec.domain.devices.interfaces +=[{"bridge":{},"macAddress":"02:a6:fb:00:00:10","model":"virtio","name":"nic2"}]' | jq '.spec.template.spec.networks +=[{"multus":{"networkName":"default/test"},"name":"nic2"}]' | oc apply -f -

### 例子2
### 直接用kubectl patch
### 同时增加
### /spec/template/spec/domain/devices/interfaces/-
### /spec/template/spec/networks/-
$ kubectl patch vm rhel-8-03 --type=json -p='[{"op": "add", "path": "/spec/template/spec/domain/devices/interfaces/-", "value": {"name": "nic2", "bridge": {}}}, {"op": "add", "path": "/spec/template/spec/networks/-", "value": {"name": "nic2", "multus": {"networkName": "default/blue"}}}]'
```

### 为用户添加cluster-reader权限
```
oc adm policy add-cluster-role-to-user cluster-reader test2
kubectl auth can-i list roles -n default
kubectl auth can-i list net-attach-def -n default


cat <<'EOF' | oc apply -f -
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-nad-viewer
rules:
  - apiGroups: 
      - k8s.cni.cncf.io
    resources:
      - network-attachment-definitions
    verbs:
      - get
      - list
      - watch
EOF
oc adm policy add-cluster-role-to-user cluster-nad-viewer test2
```

### submariner blog
https://piotrminkowski.com/2024/01/15/openshift-multicluster-with-advanced-cluster-management-for-kubernetes-and-submariner/ 
```
oc login <cluster1:6443> --insecure-skip-tls-verify
oc new-project cross-site
oc create deployment hello-world-frontend --image quay.io/jonkey/skupper/hello-world-frontend:20230225
oc expose deployment hello-world-frontend --port 8080
oc expose svc hello-world-frontend
oc set env deployment hello-world-frontend BACKEND_SERVICE_HOST_="hello-world-backend.cross-site.svc.clusterset.local"
oc set env deployment hello-world-frontend BACKEND_SERVICE_PORT_="8080"
oc get route
oc create deployment hello-world-backend --image quay.io/jonkey/skupper/hello-world-backend:20230225
oc expose deployment/hello-world-backend --port 8080
cat <<EOF | oc apply -f -
apiVersion: multicluster.x-k8s.io/v1alpha1
kind: ServiceExport
metadata:
  name: hello-world-backend
  namespace: cross-site
EOF

oc login <cluster2:6443> --insecure-skip-tls-verify
oc new-project cross-site
oc create deployment hello-world-backend --image quay.io/jonkey/skupper/hello-world-backend:20230225
oc expose deployment/hello-world-backend --port 8080

cat <<EOF | oc apply -f -
apiVersion: multicluster.x-k8s.io/v1alpha1
kind: ServiceExport
metadata:
  name: hello-world-backend
  namespace: cross-site
EOF

$ kubectl --kubeconfig=kubeconfig/cluster3/kubeconfig -n default run tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash
If you don't see a command prompt, try pressing enter.
bash-5.0# dig hello-world-backend.cross-site.svc.clusterset.local.

; <<>> DiG 9.16.6 <<>> hello-world-backend.cross-site.svc.clusterset.local.
;; global options: +cmd
;; Got answer:
;; WARNING: .local is reserved for Multicast DNS
;; You are currently testing what happens when an mDNS query is leaked to DNS
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18346
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 0bc1897e9898fa40 (echoed)
;; QUESTION SECTION:
;hello-world-backend.cross-site.svc.clusterset.local. IN        A

;; ANSWER SECTION:
hello-world-backend.cross-site.svc.clusterset.local. 5 IN A 172.30.18.133

;; Query time: 3 msec
;; SERVER: 172.30.0.10#53(172.30.0.10)
;; WHEN: Wed Jun 26 05:10:45 UTC 2024
;; MSG SIZE  rcvd: 159

bash-5.0# curl 172.30.18.133:8080/api/hello
Hello, stranger.  I am Posh Processor (hello-world-backend-575f897b6b-68vp5).

bash-5.0# dig hello-world-backend.cross-site.svc.clusterset.local.

; <<>> DiG 9.16.6 <<>> hello-world-backend.cross-site.svc.clusterset.local.
;; global options: +cmd
;; Got answer:
;; WARNING: .local is reserved for Multicast DNS
;; You are currently testing what happens when an mDNS query is leaked to DNS
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 52924
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: f2da6742e858c7a8 (echoed)
;; QUESTION SECTION:
;hello-world-backend.cross-site.svc.clusterset.local. IN        A

;; ANSWER SECTION:
hello-world-backend.cross-site.svc.clusterset.local. 5 IN A 172.31.102.158

;; Query time: 5 msec
;; SERVER: 172.30.0.10#53(172.30.0.10)
;; WHEN: Wed Jun 26 05:13:38 UTC 2024
;; MSG SIZE  rcvd: 159

bash-5.0# curl 172.31.102.158:8080/api/hello
Hello, stranger.  I am Droll Droid (hello-world-backend-575f897b6b-grmvk).
```

### subctl download url
https://developers.redhat.com/content-gateway/rest/browse/pub/rhacm/clients/subctl/

### infra node and storage node 
### machineConfigSelector
### nodeSelector
```
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: infra
spec:
  machineConfigSelector:
    matchExpressions:
      - {key: machineconfiguration.openshift.io/role, operator: In, values: [worker,infra]}
  nodeSelector:
    matchExpressions:
      - key: node-role.kubernetes.io/infra
        operator: Exists
      - key: node-role.kubernetes.io/storage
        operator: DoesNotExist

---
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: storage
spec:
  machineConfigSelector:
    matchExpressions:
      - {key: machineconfiguration.openshift.io/role, operator: In, values: [worker,storage]}
  nodeSelector:
    matchExpressions:
      - key: node-role.kubernetes.io/infra
        operator: Exists
      - key: node-role.kubernetes.io/storage
        operator: Exists
```

### 设置OVN-K local gateway mode
```
### 获取配置
$ oc get network.operator.openshift.io cluster -o json | jq .spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig
{
  "ipv4": {},
  "ipv6": {},
  "routingViaHost": false
}

### 更新配置
### https://access.redhat.com/solutions/7053694
$ oc get network.operator.openshift.io cluster -o json | jq '.spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig ={"ipv4":{},"ipv6":{},"routingViaHost":true,"ipForwarding":"Global"}' | oc apply -f -

### 再次获取配置
$ oc get network.operator.openshift.io cluster -o json | jq .spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig
{
  "ipForwarding": "Global",
  "ipv4": {},
  "ipv6": {},
  "routingViaHost": true
}
```

### 安装配置xrdp
https://post4vps.com/Thread-CentOS-7-8-with-XFCE-XRDP
```
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

yum groupinstall -y "Xfce"

yum install -y xrdp
systemctl enable xrdp
systemctl start xrdp

firewall-cmd --add-port=3389/tcp --permanent
firewall-cmd --reload

echo "xfce4-session" > ~/.Xclients
chmod a+x ~/.Xclients
```

### download latest version of oc-mirror
```
https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.15.19/
https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/
```

### cleanup operator
```
operator cleanup
https://access.redhat.com/solutions/6459071
```

### hello-world
```
oc create deployment hello-world-frontend --image registry.ocp4.example.com/jwang/skupper/hello-world-frontend:20230225
oc expose deployment hello-world-frontend --port 8080
oc expose svc hello-world-frontend
oc set env deployment hello-world-frontend BACKEND_SERVICE_HOST_="hello-world-backend.cross-site.svc.cluster.local"
oc set env deployment hello-world-frontend BACKEND_SERVICE_PORT_="8080"
oc get route

oc create deployment hello-world-backend --image registry.ocp4.example.com/jwang/skupper/hello-world-backend:20230225
oc expose deployment/hello-world-backend --port 8080
```

### debug openshift pod with debug and ubi image
```
$ oc -n openshift-logging debug --image=registry.redhat.io/ubi8:latest deployment/logging-loki-distributor
$ oc -n openshift-logging debug  --image=registry.redhat.io/ubi8:latest logging-loki-ingester-0
```

### 设置 submariner 检查集群可互联以及可服务发现
```
subctl verify --kubeconfig <kubeconfig_sno2> --toconfig <kubeconfig_sno3>  --only service-discovery,connectivity --verbose --image-override=submariner-nettest=quay.io/submariner/nettest:release-0.16 
```

### 尝试更新HCO featureGates
### 首先Disable CVO
### 然后Disable OLM
### 然后Disable HCO
```
  CONTROL_PLANE_TOPOLOGY=$(oc get infrastructure cluster -o=jsonpath='{$.status.controlPlaneTopology}')
  if [[ ${CONTROL_PLANE_TOPOLOGY} != "External" ]]; then
    # Disable CVO so that it doesn't reconcile the OLM Operator
    oc scale deployment/cluster-version-operator \
      --namespace='openshift-cluster-version' \
      --replicas='0'

    # Disable OLM so that it doesn't reconcile the HCO Operator
    oc scale deployment/olm-operator \
      --namespace='openshift-operator-lifecycle-manager' \
      --replicas='0'
  fi

  # Disable HCO so that it doesn't reconcile CRs CDI, KubeVirt, ...
  hco_namespace=$(
    oc get deployments --all-namespaces \
      --field-selector=metadata.name='hco-operator' \
      --output=jsonpath='{$.items[0].metadata.namespace}'
  )
  oc scale deployment/hco-operator \
    --namespace="${hco_namespace}" \
    --replicas='0'

  # Ensure HCO pods are gone
  oc wait pods \
    --namespace="${hco_namespace}" \
    --selector='name=hyperconverged-cluster-operator' \
    --for=delete \
    --timeout='2m' ||
    echo 'failed to verify HCO pods are gone / were already gone at the point we executed oc wait'


```

### HyperConverged添加VMLiveUpdateFeatures FeatureGates的方法
https://github.com/kubevirt/hyperconverged-cluster-operator/blob/main/docs/cluster-configuration.md#jsonpatch-annotations
```
$ oc annotate --overwrite -n openshift-cnv hyperconverged kubevirt-hyperconverged kubevirt.kubevirt.io/jsonpatch='[{
      "op": "add",
      "path": "/spec/configuration/developerConfiguration/featureGates/-",
      "value": "VMLiveUpdateFeatures"
  }]'
```

### OpenShift Virtualization虚拟机LiveMigration到指定节点
```
### 虚拟机设置 spec.liveUpdateFeatures: affinity: {}
$ oc get vm rhel-8-03 -o json | jq '.spec.liveUpdateFeatures' 
null
$ oc get vm rhel-8-03 -o json | jq '.spec.liveUpdateFeatures += {"affinity":{}}' | oc apply -f -
$ oc get vm rhel-8-03 -o json | jq '.spec.liveUpdateFeatures'
{
  "affinity": {}
}

### 虚拟机运行在节点b1-ocp4test.ocp4.example.com上
$ oc get vmi rhel-8-03 
NAME        AGE   PHASE     IP            NODENAME                       READY
rhel-8-03   22m   Running   172.18.2.19   b1-ocp4test.ocp4.example.com   True

### VM对象设置迁移目标节点
$ oc get vm rhel-8-03 -o json | jq '.spec.template.spec.affinity={"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["b2-ocp4test.ocp4.example.com"]}]}]}}}' | oc apply -f -

### 触发VM迁移
$ cat <<EOF | oc apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstanceMigration
metadata:
  name: rhel-8-03-mig-00005
spec:
  vmiName: rhel-8-03
EOF

### 检查迁移执行进度
$ oc get VirtualMachineInstanceMigration rhel-8-03-mig-00003 -w | ts 
Jul 03 15:07:54 NAME                  PHASE        VMI
Jul 03 15:07:54 rhel-8-03-mig-00003   Scheduling   rhel-8-03
Jul 03 15:07:58 rhel-8-03-mig-00003   Scheduled    rhel-8-03
Jul 03 15:07:58 rhel-8-03-mig-00003   PreparingTarget   rhel-8-03
Jul 03 15:07:59 rhel-8-03-mig-00003   TargetReady       rhel-8-03
Jul 03 15:07:59 rhel-8-03-mig-00003   Running           rhel-8-03
Jul 03 15:08:07 rhel-8-03-mig-00003   Succeeded         rhel-8-03
Jul 03 15:08:07 rhel-8-03-mig-00003   Succeeded         rhel-8-03
Jul 03 15:08:07 rhel-8-03-mig-00003   Succeeded         rhel-8-03

### 检查VMI所在节点
$ oc get vmi rhel-8-03 
NAME        AGE   PHASE     IP            NODENAME                       READY
rhel-8-03   23m   Running   172.18.5.23   b2-ocp4test.ocp4.example.com   True
```

### 离线metallb
```
helm repo add metallb https://metallb.github.io/metallb
helm repo update && helm fetch metallb/metallb --version=7.0.3
```

### 离线kasten
```
### 离线helm charts
$ helm repo add kasten https://charts.kasten.io/
$ helm repo update && helm fetch kasten/k10 --version=7.0.3

### 离线kasten images
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: gcr.io/kasten-images/admin:7.0.3
    - name: gcr.io/kasten-images/aggregatedapis:7.0.3
    - name: gcr.io/kasten-images/auth:7.0.3
    - name: gcr.io/kasten-images/bloblifecyclemanager:7.0.3
    - name: gcr.io/kasten-images/catalog:7.0.3
    - name: gcr.io/kasten-images/configmap-reload:7.0.3
    - name: gcr.io/kasten-images/controllermanager:7.0.3
    - name: gcr.io/kasten-images/crypto:7.0.3
    - name: gcr.io/kasten-images/dashboardbff:7.0.3
    - name: gcr.io/kasten-images/datamover:7.0.3
    - name: gcr.io/kasten-images/dex:7.0.3
    - name: gcr.io/kasten-images/emissary:7.0.3
    - name: gcr.io/kasten-images/events:7.0.3
    - name: gcr.io/kasten-images/executor:7.0.3
    - name: gcr.io/kasten-images/frontend:7.0.3
    - name: gcr.io/kasten-images/garbagecollector:7.0.3
    - name: gcr.io/kasten-images/grafana:7.0.3
    - name: gcr.io/kasten-images/init:7.0.3
    - name: gcr.io/kasten-images/jobs:7.0.3
    - name: gcr.io/kasten-images/k10fieldtools:7.0.3
    - name: gcr.io/kasten-images/k10tools:7.0.3
    - name: gcr.io/kasten-images/kanister-tools:7.0.3
    - name: gcr.io/kasten-images/kanister:7.0.3
    - name: gcr.io/kasten-images/logging:7.0.3
    - name: gcr.io/kasten-images/metering:7.0.3
    - name: gcr.io/kasten-images/metric-sidecar:7.0.3
    - name: gcr.io/kasten-images/prometheus:7.0.3
    - name: gcr.io/kasten-images/repositories:7.0.3
    - name: gcr.io/kasten-images/restorectl:7.0.3
    - name: gcr.io/kasten-images/state:7.0.3
    - name: gcr.io/kasten-images/upgrade:7.0.3
    - name: gcr.io/kasten-images/vbrintegrationapi:7.0.3
EOF
$ rm -rf output
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee -a /tmp/oc-mirror-4.15
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000

```

### openshift获取证书过期时间更新证书过期时间
```
https://github.com/crc-org/snc/issues/27
### 获取namespace和secret名称
$ oc get secret -A -o json | jq -r '.items[] | select(.metadata.annotations."auth.openshift.io/certificate-not-after" | .!=null and fromdateiso8601<='$( date --date='+1year' +%s )') | "-n \(.metadata.namespace) \(.metadata.name)"'
### 获取secret证书过期时间
$ oc get secret -A -o json | jq -r '.items[] | select(.metadata.annotations."auth.openshift.io/certificate-not-after" | .!=null and fromdateiso8601<='$( date --date='+1year' +%s )') | "-n \(.metadata.namespace) \(.metadata.name)"' | xargs -n3 oc get secret -o json | jq '.metadata.annotations."auth.openshift.io/certificate-not-after"'
### 更新证书过期时间
oc get secret -A -o json | jq -r '.items[] | select(.metadata.annotations."auth.openshift.io/certificate-not-after" | .!=null and fromdateiso8601<='$( date --date='+1year' +%s )') | "-n \(.metadata.namespace) \(.metadata.name)"' | xargs -n3 oc patch secret -p='{"metadata": {"annotations": {"auth.openshift.io/certificate-not-after": null}}}'
```

### 查看pci设备相关性
```
# lspci -Dt
```

### 检查磁盘和存储子系统 
```
$ lshw -class disk 
$ lshw -class storage
```

### 用vmexport导出导入虚拟机
```
### 创建vmexport
cat <<EOF | oc apply -f -
apiVersion: export.kubevirt.io/v1alpha1
kind: VirtualMachineExport
metadata:
  name: fedora-40-01
  namespace: test2
spec:
  source:
    apiGroup: "kubevirt.io"
    kind: VirtualMachine
    name: fedora-40-01
  ttlDuration: 1h
EOF

### 查询vmexport状态
oc get vmexport fedora-40-01 -o json | jq .status.phase

### 下载manifest
virtctl vmexport download fedora-40-01 --keep-vme --manifest --include-secret --output fedora-40-vm.yml

### 下载volume
virtctl vmexport download fedora-40-01 --keep-vme --volume fedora-bronze-dingo-31 --output fedora-40-01-disk.img.gz

### 基于snapshot创建vmexport
virtctl vmexport create --snapshot=fedora-snapshot fedora-export-snapshot

### 删除vmexport
virtctl vmexport delete fedora-export-snapshot

### 上传dv
virtctl image-upload dv fedora-rootdisk --size 30Gi --image-path fedora-vm-disk.img.gz --storage-class ocs-external-storagecluster-ceph-rbd-virtualization

### 导入vm
oc apply -f fedora-vm.yml
configmap/export-ca-cm-fedora-export created
virtualmachine.kubevirt.io/fedora-vm created
secret/header-secret-fedora-export created
```

### CNV VM Live Migration
```
获取虚拟机是否支持在线迁移
$ oc get vmi fedora-40-01 -o json | jq '.status.conditions[] | select(.type == "LiveMigratable" ) | "\(.status)"'

获取VM在线迁移策略
$ oc get vm fedora-40-01 -o json | jq .spec.template.spec.evictionStrategy 
"LiveMigrate"

设置VM在线迁移策略为None或者LiveMigrate
$ oc get vm fedora-40-01 -o json | jq '.spec.template.spec.evictionStrategy="None"' | oc apply -f -

重启VM
$ virtctl restart fedora-40-01
```

### 检查vm是否运行
```
$ oc get vm fedora-40-01 -o json | jq '.spec.running' 
true
```

### vSphere监控
```
https://blog.csdn.net/weixin_34248487/article/details/92973609
vSphere监控
```

### 检查pod的conditions
```
oc get pods virt-launcher-rhel8-jwang-06-5xdvj -o json | jq .status.conditions

  {
    "lastProbeTime": null,
    "lastTransitionTime": "2024-07-09T08:30:46Z",
    "message": "Taint manager: deleting due to NoExecute taint",
    "reason": "DeletionByTaintManager",
    "status": "True",
    "type": "DisruptionTarget"
  }


```

### 为节点添加taints
```
节点添加taint
kubectl taint nodes b4-ocp4test.ocp4.example.com 'node-role.kubernetes.io/worker-gpu'='':NoSchedule
kubectl taint nodes b1-ocp4test.ocp4.example.com 'maintenance'='true':NoSchedule

节点移除taint
kubectl taint nodes b1-ocp4test.ocp4.example.com 'maintenance'='true':NoSchedule-
kubectl taint nodes b4-ocp4test.ocp4.example.com 'node-role.kubernetes.io/worker-gpu'='':NoSchedule-
```

### 获取openshift集群的metrics列表
```
### 参见https://docs.openshift.com/container-platform/4.15/observability/monitoring/managing-metrics.html#understanding-metrics_managing-metrics
### thanos-querier的路由 
### oc get routes -n openshift-monitoring thanos-querier -o jsonpath='{.status.ingress[0].host}'
### 访问的Bearer Token
### oc whoami -t
### metric 的 endpoint
### https://$(oc get routes -n openshift-monitoring thanos-querier -o jsonpath='{.status.ingress[0].host}')/api/v1/metadata
$ curl -k -H "Authorization: Bearer $(oc whoami -t)" https://$(oc get routes -n openshift-monitoring thanos-querier -o jsonpath='{.status.ingress[0].host}')/api/v1/metadata  | jq .data
```

### build usbredirect on rhel 9.4 
```
### https://gitlab.freedesktop.org/spice/usbredir/
### https://github.com/kubevirt/kubevirt/issues/10074#issuecomment-1630423053

$ wget https://gitlab.freedesktop.org/-/project/72/uploads/211844dd64853ca4378ad7e74faf3e00/usbredir-0.13.0.tar.xz
$ tar Jxvf usbredir-0.13.0.tar.xz
$ cd usbredir-0.13.0/

$ dnf groupinstall -y 'Development Tools'
$ subscription-manager repos --enable=codeready-builder-for-rhel-8-x86_64-rpms 
$ dnf install -y meson cmake libusb-devel.x86_64 glib2-devel.x86_64

$ meson . build 
$ meson compile -C build
$ file ./build/tools/usbredirect

$ cp ./build/tools/usbredirect  /usr/local/sbin/

$ usbredirect --help
```

### Mac OSX命令行查看USB设备
```
$ ioreg -p IOUSB
$ ioreg -p IOUSB -w0 -l
$ ioreg -p IOUSB -w0 | sed 's/[^o]*o //; s/@.*$//' | grep -v '^Root.*'
```

### Chrome版本发布信息
```
https://chromiumdash.appspot.com/releases?platform=Linux
```

### linux安装chrome浏览器
```
wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
yum install ./google-chrome-stable_current_*.rpm

```

### 配置userworkload stack
```
https://docs.fedoraproject.org/en-US/infra/ocp4/sop_configure_userworkload_monitoring_stack/
```

### oc-mirror rebuild catalogs ubi9
```
### https://access.redhat.com/solutions/7062641
podman run -dt --name ubi9 -v /data/OCP-4.14.26/ocp/oc-mirror:/oc-mirror --hostname ubi9-oc-mirror --network host --privileged registry.redhat.io/ubi9 bash
cd /oc-mirror
tar xzf oc-mirror.rhel9.tar.gz  -C /usr/local/bin && chmod +x /usr/local/bin/oc-mirror
oc-mirror version --short

### podman host 主机上
podman cp /data/registry/certs/registry.crt ubi9:/etc/pki/ca-trust/source/anchors
podman cp ~/.docker ubi9:/root/
### 在 ubi9 pod里
podman exec -it ubi9 bash
update-ca-trust extract

cd /oc-mirror
/usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000 --rebuild-catalogs

```

### daocloud mirror
https://docs.daocloud.io/community/mirror/#_3

### install homebrew in container
https://github.com/Homebrew/install/issues/616
```
podman run -it -h fedora --network host --privileged quay.io/fedora/fedora:40-x86_64 /bin/bash
yum install -y curl git procps libxcrypt-compat

useradd user1
passwd user1
echo 'user1 ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/user1

su - user1

bash --version
git --version
curl --version

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew --version
brew install ffmpeg
brew install yt-dlp
yt-dlp <URL>
```

### velero and backup  
https://velero.io/docs/main/contributions/minio/
```
The example Minio yaml provided uses “empty dir”. 
```

### TrueNAS iscsi target
https://www.nakivo.com/blog/how-to-install-truenas-iscsi-target/
https://www.truenas.com/docs/solutions/integrations/containers/
https://artifacthub.io/packages/helm/truenas-csp/truenas-csp
https://github.com/hpe-storage/truenas-csp/blob/master/INSTALL.md#configure-csi-driver

### truenas csp machineconfig
```
cd /tmp
cat > my_registry.conf <<EOF
[[registry]]
  prefix = ""
  location = "quay.io/hpestorage"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "helper.ocp.ap.vwg:5000/jwang/hpestorage"

[[registry]]
  prefix = ""
  location = "registry.k8s.io/sig-storage"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "helper.ocp.ap.vwg:5000/jwang/sig-storage"

[[registry]]
  prefix = ""
  location = "quay.io/datamattsson"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.ocp4.example.com/jwang/datamattsson"
EOF

cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-mirror-truenas-csp
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(base64 -w0 my_registry.conf)
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf.d/99-master-mirror-truenas-csp.conf
EOF

cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-mirror-truenas-csp
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(base64 -w0 my_registry.conf)
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf.d/99-worker-mirror-truenas-csp.conf
EOF
```

### truenas k8s 信息
https://jonathangazeley.com/2021/01/05/using-truenas-to-provide-persistent-storage-for-kubernetes/

### 在 machineconfig 出现错误时如何恢复
https://access.redhat.com/solutions/7061142
https://gist.github.com/ikurni/067ea20449588008de4e19a07f0de5f4
https://access.redhat.com/solutions/4970731
```
### 将 machineconfiguration.openshift.io/currentConfig 和 
### machineconfiguration.openshift.io/desiredConfig 设置为
### rendered-worker-0cc133496d8b46e09c2a5c1e22e3ae37
### 将 machineconfiguration.openshift.io/reason 设置为 ''
### 将 machineconfiguration.openshift.io/state 设置为 'Done'
for i in `seq 0 3`
do 
oc patch node b${i}-ocp4test.ocp4.example.com --type merge --patch "{\"metadata\": {\"annotations\": {\"machineconfiguration.openshift.io/currentConfig\": \"rendered-worker-0cc133496d8b46e09c2a5c1e22e3ae37\"}}}"
 
oc patch node b${i}-ocp4test.ocp4.example.com --type merge --patch "{\"metadata\": {\"annotations\": {\"machineconfiguration.openshift.io/desiredConfig\": \"rendered-worker-0cc133496d8b46e09c2a5c1e22e3ae37\"}}}"

oc patch node b${i}-ocp4test.ocp4.example.com --type merge --patch '{"metadata": {"annotations": {"machineconfiguration.openshift.io/reason": ""}}}'

oc patch node b${i}-ocp4test.ocp4.example.com  --type merge --patch '{"metadata": {"annotations": {"machineconfiguration.openshift.io/state": "Done"}}}'
done

### 登录节点
rm /etc/machine-config-daemon/currentconfig 
touch /run/machine-config-daemon-force

### 如果上述操作不生效，删除pod machine-config-operator 和 machine-config-controller
oc -n openshift-machine-config-operator delete $(oc -n openshift-machine-config-operator get pod -l k8s-app='machine-config-operator' -o name)
oc -n openshift-machine-config-operator delete $(oc -n openshift-machine-config-operator get pod -l k8s-app='machine-config-controller' -o name)

### 检查日志
oc -n openshift-machine-config-operator logs $(oc -n openshift-machine-config-operator get pods -l k8s-app='machine-config-operator' -o name)
oc -n openshift-machine-config-operator logs $(oc -n openshift-machine-config-operator get pods -l k8s-app='machine-config-controller' -o name)
```

### 集成 truenas iscsi 服务到 openshift
```
### 参考
### https://www.nakivo.com/blog/how-to-install-truenas-iscsi-target/
### iscsi的portal name需配置为hpe-csi
### 这是truenas-csp所使用hpe csi plugins所要求的
### 创建apikey
### truenas iscsiapikey
### 1-tgH9r6voLAto9RSXThaa7biJlujmGkdEhgyc9ZNx3CPrdujFj3Iz3aMP5ivgLivR

oc new-project hpe-storage
oc label namespace hpe-storage pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged --overwrite=true

cat <<EOF | oc apply -f -
kind: SecurityContextConstraints
apiVersion: security.openshift.io/v1
metadata:
  name: hpe-csi-scc
allowHostDirVolumePlugin: true
allowHostIPC: true
allowHostNetwork: true
allowHostPID: true
allowHostPorts: true
allowPrivilegeEscalation: true
allowPrivilegedContainer: true
allowedCapabilities:
- '*'
defaultAddCapabilities: []
fsGroup:
  type: RunAsAny
groups: []
priority:
readOnlyRootFilesystem: false
requiredDropCapabilities: []
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
users:
- system:serviceaccount:hpe-storage:hpe-csi-controller-sa
- system:serviceaccount:hpe-storage:hpe-csi-node-sa
- system:serviceaccount:hpe-storage:hpe-csp-sa
volumes:
- '*'
EOF

### 同步所需镜像
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: quay.io/hpestorage/csi-driver:v2.4.2
    - name: quay.io/hpestorage/csi-extensions:v1.2.6
    - name: quay.io/hpestorage/volume-group-provisioner:v1.0.5    
    - name: quay.io/hpestorage/volume-group-snapshotter:v1.0.5    
    - name: quay.io/hpestorage/volume-mutator:v1.3.5
    - name: registry.k8s.io/sig-storage/csi-attacher:v4.5.0       
    - name: registry.k8s.io/sig-storage/csi-provisioner:v4.0.0    
    - name: registry.k8s.io/sig-storage/csi-resizer:v1.9.3        
    - name: registry.k8s.io/sig-storage/csi-snapshotter:v6.3.3    
    - name: quay.io/hpestorage/csi-driver:v2.4.2
    - name: registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.10.0
    - name: quay.io/hpestorage/alletra-6000-and-nimble-csp:v2.4.1
    - name: quay.io/hpestorage/alletra-9000-primera-and-3par-csp:v2.4.2
    - name: quay.io/datamattsson/truenas-csp:v2.4.2
EOF

$ rm -rf output-dir
$ /usr/local/bin/oc-mirror -v1 --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee -a /tmp/oc-mirror
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000 --rebuild-catalogs

### 创建registry config
cd /tmp
cat > my_registry.conf <<EOF
[[registry]]
  prefix = ""
  location = "quay.io/hpestorage"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.ocp4.example.com/jwang/hpestorage"

[[registry]]
  prefix = ""
  location = "registry.k8s.io/sig-storage"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.ocp4.example.com/jwang/sig-storage"

[[registry]]
  prefix = ""
  location = "quay.io/datamattsson"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.ocp4.example.com/jwang/datamattsson"
EOF

cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-mirror-truenas-csp
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(base64 -w0 my_registry.conf)
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf.d/99-master-mirror-truenas-csp.conf
EOF

cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-mirror-truenas-csp
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(base64 -w0 my_registry.conf)
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf.d/99-worker-mirror-truenas-csp.conf
EOF

### 离线 helm charts
helm repo add truenas-csp https://hpe-storage.github.io/truenas-csp/
helm pull truenas-csp/truenas-csp --version 1.1.6

### 将 truenas-csp-1.1.6.tgz 拷贝到repo
mkdir -p /var/www/html/repo
cd  /var/www/html/repo
cp <path_of_truenas-csp-1.1.6.tgz>/truenas-csp-1.1.6.tgz /var/www/html/repo
helm repo index /var/www/html/repo --url http://helper-ocp4test.ocp4.example.com:8080/repo/
helm repo add local-truenas-repo http://helper-ocp4test.ocp4.example.com:8080/repo
helm search repo local-truenas-repo 
NAME                            CHART VERSION   APP VERSION     DESCRIPTION                                       
local-truenas-repo/truenas-csp  1.1.6           2.4.2           TrueNAS Container Storage Provider Helm chart f...

### 生成 helm chart values.yaml 文件
cat <<EOF > /tmp/values.yaml
# Default values for truenas-csp.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

logDebug: false

# Tunes the CSP backend API requests
optimizeFor: "Default"

image:
  repository: quay.io/datamattsson/truenas-csp
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  tag: "v2.4.2"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # Annotations to add to the service account
  annotations: {}
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  name: ""

podAnnotations: {}

podSecurityContext: {}
  # fsGroup: 2000

securityContext: {}
  # capabilities:
  #   drop:
  #   - ALL
  # readOnlyRootFilesystem: true
  # runAsNonRoot: true
  # runAsUser: 1000

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: false
  className: ""
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: truenas-csp.hpe-storage
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 100m
    memory: 256Mi

nodeSelector: {}

tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 30
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 30

affinity: {}

# Dependencies
hpe-csi-driver:
  disable:
    nimble: true
    primera: true
    alletra6000: true
    alletra9000: true
    alletraStorageMP: true
EOF

### 创建secret truenas-secret
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: truenas-secret
  namespace: hpe-storage
stringData:
  serviceName: truenas-csp-svc
  servicePort: "8080"
  username: hpe-csi
  password: 1-tgH9r6voLAto9RSXThaa7biJlujmGkdEhgyc9ZNx3CPrdujFj3Iz3aMP5ivgLivR
  backend: 192.168.56.19
EOF

### 安装truenas-csp
helm install my-truenas-csp local-truenas-repo/truenas-csp --version 1.1.6 -f /tmp/values.yaml -n hpe-storage

oc get all -n hpe-storage
NAME                                      READY   STATUS    RESTARTS   AGE
pod/hpe-csi-controller-55ddf587dd-qfzcs   9/9     Running   0          125m
pod/hpe-csi-node-9j6hc                    2/2     Running   0          125m
pod/hpe-csi-node-blkd5                    2/2     Running   0          125m
pod/hpe-csi-node-gwpk4                    2/2     Running   0          125m
pod/hpe-csi-node-h98qq                    2/2     Running   0          125m
pod/hpe-csi-node-khr7w                    2/2     Running   0          125m
pod/hpe-csi-node-nwxp5                    2/2     Running   2          125m
pod/truenas-csp-596ccf49b9-j7tbt          1/1     Running   0          128m

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/truenas-csp-svc   ClusterIP   172.30.37.211   <none>        8080/TCP   128m

NAME                          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/hpe-csi-node   6         6         6       6            6           <none>          128m

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hpe-csi-controller   1/1     1            1           128m
deployment.apps/truenas-csp          1/1     1            1           128m

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/hpe-csi-controller-55ddf587dd   1         1         1       128m
replicaset.apps/truenas-csp-596ccf49b9          1         1         1       128m

### 创建storageclass
cat <<EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: truenas-iscsi
provisioner: csi.hpe.com
parameters:
  csi.storage.k8s.io/controller-expand-secret-name: truenas-secret
  csi.storage.k8s.io/controller-expand-secret-namespace: hpe-storage
  csi.storage.k8s.io/controller-publish-secret-name: truenas-secret
  csi.storage.k8s.io/controller-publish-secret-namespace: hpe-storage
  csi.storage.k8s.io/node-publish-secret-name: truenas-secret
  csi.storage.k8s.io/node-publish-secret-namespace: hpe-storage
  csi.storage.k8s.io/node-stage-secret-name: truenas-secret
  csi.storage.k8s.io/node-stage-secret-namespace: hpe-storage
  csi.storage.k8s.io/provisioner-secret-name: truenas-secret
  csi.storage.k8s.io/provisioner-secret-namespace: hpe-storage
  csi.storage.k8s.io/fstype: xfs
  allowOverrides: sparse,compression,deduplication,volblocksize,sync,description
  root: iscsipool01
  accessProtocol: "iscsi"
  description: "Volume created by the HPE CSI Driver for Kubernetes"
reclaimPolicy: Delete
allowVolumeExpansion: true
EOF

oc get sc 
NAME                      PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
truenas-iscsi (default)   csi.hpe.com                    Delete          Immediate              true                   123m


```

### rhel8 corosync gfs2
https://bidhankhatri.com.np/system/gfs2-filesystem-setup-in-rhel8-with-pacemaker-and-corosync/

### spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig 支持的配置
```
$ oc explain network.spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig --api-version=operator.openshift.io/v1
GROUP:      operator.openshift.io
KIND:       Network
VERSION:    v1

FIELD: gatewayConfig <Object>

DESCRIPTION:
    gatewayConfig holds the configuration for node gateway options.
    
FIELDS:
  ipForwarding  <string>
    IPForwarding controls IP forwarding for all traffic on OVN-Kubernetes
    managed interfaces (such as br-ex). By default this is set to Restricted,
    and Kubernetes related traffic is still forwarded appropriately, but other
    IP traffic will not be routed by the OCP node. If there is a desire to allow
    the host to forward traffic across OVN-Kubernetes managed interfaces, then
    set this field to "Global". The supported values are "Restricted" and
    "Global".

  routingViaHost        <boolean>
    RoutingViaHost allows pod egress traffic to exit via the ovn-k8s-mp0
    management port into the host before sending it out. If this is not set,
    traffic will always egress directly from OVN to outside without touching the
    host stack. Setting this to true means hardware offload will not be
    supported. Default is false if GatewayConfig is specified.
```

### Veeam Kasten and Red Hat OpenShift Demo
```
https://kastenhq.github.io/k10-openshift-lab.github.io/

cat <<EOF | oc apply -f -
apiVersion: apik10.kasten.io/v1alpha1
kind: K10
metadata:
  name: k10
  namespace: kasten-io
spec:
  auth:
    tokenAuth:
      enabled: true
  excludedApps:
    - kube-node-lease
    - kube-public
    - kube-system
    - openshift
    - openshift-apiserver
    - openshift-apiserver-operator
    - openshift-authentication
    - openshift-authentication-operator
    - openshift-cloud-controller-manager
    - openshift-cloud-controller-manager-operator
    - openshift-cloud-credential-operator
    - openshift-cloud-network-config-controller
    - openshift-cluster-csi-drivers
    - openshift-cluster-machine-approver
    - openshift-cluster-node-tuning-operator
    - openshift-cluster-samples-operator
    - openshift-cluster-storage-operator
    - openshift-cluster-version
    - openshift-config
    - openshift-config-managed
    - openshift-config-operator
    - openshift-console
    - openshift-console-operator
    - openshift-console-user-settings
    - openshift-controller-manager
    - openshift-controller-manager-operator
    - openshift-dns
    - openshift-dns-operator
    - openshift-etcd
    - openshift-etcd-operator
    - openshift-host-network
    - openshift-image-registry
    - openshift-infra
    - openshift-ingress
    - openshift-ingress-canary
    - openshift-ingress-operator
    - openshift-insights
    - openshift-kni-infra
    - openshift-kube-apiserver
    - openshift-kube-apiserver-operator
    - openshift-kube-controller-manager
    - openshift-kube-controller-manager-operator
    - openshift-kube-scheduler
    - openshift-kube-scheduler-operator
    - openshift-kube-storage-version-migrator
    - openshift-kube-storage-version-migrator-operator
    - openshift-machine-api
    - openshift-machine-config-operator
    - openshift-marketplace
    - openshift-monitoring
    - openshift-multus
    - openshift-network-diagnostics
    - openshift-network-operator
    - openshift-node
    - openshift-nutanix-infra
    - openshift-oauth-apiserver
    - openshift-openstack-infra
    - openshift-operator-lifecycle-manager
    - openshift-operators
    - openshift-ovirt-infra
    - openshift-ovn-kubernetes
    - openshift-route-controller-manager
    - openshift-service-ca
    - openshift-service-ca-operator
    - openshift-user-workload-monitoring
    - openshift-vsphere-infra
  global:
    persistence:
      catalog:
        size: ''
      storageClass: ''
  metering:
    mode: ''
  route:
    enabled: true
    host: ''
    tls:
      enabled: true
EOF


```

### nfs csi driver
```
https://github.com/kubernetes-csi/csi-driver-nfs/tree/master

cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  additionalImages: # List of additional images to be included in imageset
    - name: registry.k8s.io/sig-storage/csi-provisioner:v5.0.1
    - name: registry.k8s.io/sig-storage/csi-snapshotter:v8.0.1
    - name: registry.k8s.io/sig-storage/livenessprobe:v2.13.1
    - name: registry.k8s.io/sig-storage/nfsplugin:v4.8.0
    - name: registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.11.1
    - name: registry.k8s.io/sig-storage/nfsplugin:v4.8.0
    - name: registry.k8s.io/sig-storage/snapshot-controller:v8.0.1
EOF

$ rm -rf output-dir
$ /usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee -a /tmp/oc-mirror-4.15 
$ /usr/local/bin/oc-mirror --from ./mirror_seq1_000000.tar docker://registry.example.com:5000 --rebuild-catalogs

```

### OpenShift LDAP OAUTH
https://docs.openshift.com/container-platform/4.14/authentication/identity_providers/configuring-ldap-identity-provider.html
https://rhthsa.github.io/openshift-demo/infrastructure-authentication-providers.html
```
### IPA to AD then LDAP
$ ldapsearch -xLLL -h ipa.cn.example.com -b "dc=cn,dc=example,dc=com" -D "user1@cn.example.com" -w 'XXXXXXXX' -s sub "(&(objectclass=user)(objectcategory=person))"
$ openssl s_client -connect ipa.cn.example.com:636 2>/dev/null </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee ipaca.crt
$ oc create configmap ca-config-map --from-file=ipaca.crt=/<path>/ipaca.crt -n openshift-config
$ oc create secret generic ldap-secret --from-literal=bindPassword='<password>' -n openshift-config

### LDAP
$ cat <<EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: ldap
    challenge: false
    login: true
    mappingMethod: claim
    type: LDAP
    ldap:
      attributes:
        id:
        - distinguishedName
        email:
        - userPrincipalName
        name:
        - givenName
        preferredUsername:
        - sAMAccountName
      bindDN: "user1@cn.example.com" 
      bindPassword: 
        name: ldap-secret
      insecure: true 
      url: "ldap://ipa.cn.example.com:389/DC=cn,DC=example,DC=com?sAMAccountName?sub?(&(objectclass=user)(objectcategory=person))"
EOF

### LDAPS
$ cat <<EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: ldap
    challenge: false
    login: true
    mappingMethod: claim
    type: LDAP
    ldap:
      attributes:
        id:
        - distinguishedName
        email:
        - userPrincipalName
        name:
        - givenName
        preferredUsername:
        - sAMAccountName
      bindDN: "user1@cn.example.com" 
      bindPassword: 
        name: ldap-secret
      ca: 
        name: ca-config-map 
      insecure: false
      url: "ldaps://ipa.cn.example.com:636/DC=cn,DC=example,DC=com?sAMAccountName?sub?(&(objectclass=user)(objectcategory=person))"
EOF

```

### 检查NNCP配置时间
```
oc get nncp | grep intranet | awk '{print $1}' | xargs -I file sh -c 'oc get nncp file -o yaml | grep -B1 "4/4 nodes successfully configured" | grep lastTransitionTime' | sed 's/    lastTransitionTime: "//g; s/"//g' | sort | awk 'NR==1 {first=$0; next} {last=$0} END {cmd="date -d " first " +%s"; cmd | getline first_time; close(cmd); cmd="date -d " last " +%s"; cmd | getline last_time; close(cmd); total=last_time - first_time; hours=int(total/3600); minutes=int((total%3600)/60); seconds=total%60; printf "%d hours, %d minutes, %d seconds from %s to %s\n", hours, minutes, seconds, first, last}'
```

### 检查节点开机时间
```
oc get nodes -o name  | while read i ; do oc debug $i -- w 2>&1 | grep ' up ' ; done
 05:52:31 up 8 days, 20:34,  0 users,  load average: 0.56, 0.55, 0.54
 05:52:32 up 5 days, 15:17,  0 users,  load average: 0.77, 0.48, 0.32
 05:52:34 up 8 days, 20:54,  0 users,  load average: 0.40, 0.45, 0.49
 05:52:36 up 8 days, 21:03,  0 users,  load average: 0.42, 0.28, 0.36
 05:52:38 up 8 days, 21:50,  0 users,  load average: 6.31, 6.35, 6.43
```

### multipath and blacklist for single node
```
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: worker-baremetal-1
  labels:
    machineconfiguration.openshift.io/role: worker-baremetal-1
spec:
  machineConfigSelector:
    matchExpressions:
      - {
           key: machineconfiguration.openshift.io/role,
           operator: In,
           values: [worker, worker-baremetal-1],
        }
  paused: false
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/worker-baremetal-1: ""
EOF

export MULTIPATH_CONF_1=$(cat << EOF | base64 -w 0
defaults {
  user_friendly_names yes
}
devices {
  device {
    vendor "DGC"
    product ".*"
    product_blacklist "LUNZ"
    features "1 queue_if_no_path"
    hardware_handler "1 alua"
    path_grouping_policy "group_by_prio"
    path_selector "roundrobin 0"
    path_checker "emc_clariion"
    failback "immediate"
    rr_weight "uniform"
    no_path_retry "60"
    prio "alua"
    dev_loss_tmp "0"
  }
}
blacklist {
    wwid wwid2
    wwid wwid3
    wwid wwid4
}
EOF)

cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker-baremetal-1
  name: 99-worker-baremetal-1-multipathing
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
         source: data:text/plain;charset=utf-8;base64,${MULTIPATH_CONF_1}
        filesystem: root
        mode: 420
        path: /etc/multipath.conf
    systemd:
      units:
      - name: multipathd.service
        enabled: true
EOF
```
 
### change discovery iso core user password
Agent Discovery ISO 为 core 用户设置口令
https://raw.githubusercontent.com/openshift/assisted-service/master/docs/change-iso-password.sh

### 清理某个namespace下无法清理的对象
https://github.com/mvazquezc/termin8

### HCP - Data Plane MetalLB manifests
https://gist.github.com/jeniferh/1c69b8329b61988187cc66f7664f6a71

### Restart Control Plane Components
https://hypershift-docs.netlify.app/how-to/restart-control-plane-components/
```
oc annotate hostedcluster -n jwang-hcp-demo jwang-hcp-demo hypershift.openshift.io/restart-date=$(date --iso-8601=seconds)
```

### https://www.yjlink.cc/?id=3405
```

{"level":"fatal","ts":"2024-09-19T08:50:38.647215Z","caller":"etcdserver/storage.go:96","msg":"failed to open WAL","error":"fileutil: file already locked","stacktrace":"go.etcd.io/etcd/server/v3/etcdserver.readWAL\n\tgo.etcd.io/etcd/server/v3/etcdserver/storage.go:96\ngo.etcd.io/etcd/server/v3/etcdserver.restartNode\n\tgo.etcd.io/etcd/server/v3/etcdserver/raft.go:528\ngo.etcd.io/etcd/server/v3/etcdserver.NewServer\n\tgo.etcd.io/etcd/server/v3/etcdserver/server.go:539\ngo.etcd.io/etcd/server/v3/embed.StartEtcd\n\tgo.etcd.io/etcd/server/v3/embed/etcd.go:246\ngo.etcd.io/etcd/server/v3/etcdmain.startEtcd\n\tgo.etcd.io/etcd/server/v3/etcdmain/etcd.go:228\ngo.etcd.io/etcd/server/v3/etcdmain.startEtcdOrProxyV2\n\tgo.etcd.io/etcd/server/v3/etcdmain/etcd.go:123\ngo.etcd.io/etcd/server/v3/etcdmain.Main\n\tgo.etcd.io/etcd/server/v3/etcdmain/main.go:40\nmain.main\n\tgo.etcd.io/etcd/server/v3/main.go:31\nruntime.main\n\truntime/proc.go:250"}

$ rm -f /var/nfsshare/jwang-hcp-demo-jwang-hcp-demo/data-etcd-0/data/member/wal/0.tmp
oc rollout restart statefulset/etcd -n jwang-hcp-demo-jwang-hcp-demo
```

### 重新签署节点证书 
```
ssh -i <ssh_private_key> core@master

$ sudo -i
$ cd /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs
$ oc --kubeconfig=./localhost.kubeconfig get csr
$ oc --kubeconfig=./localhost.kubeconfig get csr --no-headers | grep Pending | /usr/bin/awk '{print $1}' | xargs oc --kubeconfig=./localhost.kubeconfig adm certificate approve
```

### 在集群里创建OpenShift AI所需的Object Bucket Claim
https://github.com/rh-aiservices-bu/models-aas/blob/main/deployment/model_serving/obc-rgw.yaml
```
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: models
spec:
  generateBucketName: models
  storageClassName: ocs-storagecluster-ceph-rgw
```

### 清理xfce进程
```
ps ax | grep -E  "xfce|xfwm|xfsetting|xfdesktop"  | grep -Ev grep | awk '{print $1}' | while read i ; do kill -9 $i ; done
```

### 拷贝qcow2文件，由于文件是精简格式，可以用rsync --sparse 参数拷贝
```
rsync --archive --sparse --progress /var/lib/libvirt/images/xxxx.qcow2 192.168.100.1:/exports/vms_disk_bak/ 
```

### command build usbredir
```
### rhel8 build 
$ subscription-manager repos --enable=codeready-builder-for-rhel-8-x86_64-rpms 
$ dnf install -y meson cmake libusb libusb-devel glib2-devel

### download usbredir source code
### https://gitlab.freedesktop.org/spice/usbredir/
### https://gitlab.freedesktop.org/spice/usbredir/-/archive/main/usbredir-main.tar.gz
$ cd src/usbredir
$ meson . build
$ meson compile -C build
$ file ./build/tools/usbredirect
$ cp ./build/tools/usbredirect /usr/local/bin

### redirect usb device to vm via virtctl
### patch vm object
$ oc patch vm/rhel8-vm-01 --type=merge -p '{"spec":{"template":{"spec":{"domain":{"devices":{"clientPassthrough": {}}}}}}}'
### restart vm 
$ virtctl restart rhel8-vm-01
$ oc get vm rhel8-vm-01
NAME          AGE   STATUS    READY
rhel8-vm-01   58d   Running   True
$ lsusb
...
Bus 002 Device 007: ID 0930:6544 Toshiba Corp. TransMemory-Mini / Kingston DataTraveler 2.0 Stick
...
### redirect usb device 0930:6544 to vm rhel8-vm-01
$ virtctl usbredir 0930:6544 rhel8-vm-01
```

### install old version of docker-ce
```
### https://github.com/moby/moby/issues/47207
### Docker Engine 25 breaks loading images in various Kubernetes
sudo yum list docker-ce.x86_64 --showduplicates | sort -r
sudo dnf install -y containerd docker-ce-3:23.0.6-1.el8 
```

### request openshift oauth token 
```
### 访问openshift oauth api申请短期的token
### https://oauth-openshift.apps.ocp.example.com/oauth/token/request
```

### 在ocp下运行fedora容器
```
### 在ocp下运行fedora容器
$ oc run --generator=run-pod/v1 -it fedora --image=fedora:latest /bin/bash
```

### build fedora image with sensors packages
```
mkdir fedora-sensors
cd fedora-sensors

cat > Dockerfile.sensors <<EOF
FROM registry.fedoraproject.org/fedora:latest
RUN dnf install -y lm_sensors lm_sensors-libs && dnf clean all 
CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF

podman build -f Dockerfile.sensors -t quay.io/jwang1/fedora-sensors:v1
podman push quay.io/jwang1/fedora-sensors:v1
```

### cloudinit networkData v2 
https://cloudinit.readthedocs.io/en/latest/reference/network-config-format-v2.html

### Using the Multus CNI in OpenShift
https://www.redhat.com/en/blog/using-the-multus-cni-in-openshift

### 比较 cni chaining mode 的 NetworkAttachmentDefinition 
```
https://github.com/noironetworks/cko/blob/main/docs/user-guide/cno-additional-interfaces.md#65-orchestrate-fabric-configuration-for-bridgelinux-bridge-interfaces-connected-to-pod

apiVersion: nmstate.io/v1alpha1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: bridge-bond1
spec:
  nodeSelector:
    kubernetes.io/hostname: worker1.ocpbm1.noiro.local
  desiredState:
    interfaces:
    - name: bridge-net1
      description: Linux bridge with bond1 as a port
      type: linux-bridge
      state: up
      bridge:
        port:
        - name: bond1

apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: bridge-net1
  namespace: default
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/bridge-net1
spec:
  config: |-
   '{"cniVersion": "0.3.1",
     "name": "bridge-net1", 
     "plugins":[{  
         "cniVersion": "0.3.1",
         "name": "bridge-net1",
         "type": "bridge",
         "bridge": "bridge-net1",
         "vlanTrunk": [{ "id": 105 },{ "minID": 102, "maxID": 104 }],
       },
       {
          "supportedVersions": [
              "0.3.0",
              "0.3.1",
              "0.4.0"
          ],
          "type": "netop-cni",
          "chaining-mode": true,
        }
       ]}'

### NNCP: bond and linux-bridge, NAD:cnv-bridge 
cat <<EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: intranet-bond1-4
spec:
  nodeSelector:
    node-role.kubernetes.io/worker: ''
  desiredState:
    interfaces:
      - name: bond1.4
        type: vlan
        state: up
        ipv4:
          enabled: false
        vlan:
          base-iface: bond1
          id: 4
      - name: br-bond1-4
        description: Linux bridge on bond1 vlanid 4
        type: linux-bridge
        state: up
        bridge:
          options:
            stp:
              enabled: false
          port:
          - name: bond1.4
        ipv4:
          enabled: false
EOF

cat <<EOF | oc apply -f
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: br-bond1-4
  namespace: default
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br-bond1-4
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "br-bond1-4",
    "type": "cnv-bridge",
    "bridge": "br-bond1-4"
  }'
EOF

```

### install remmina on RHEL9
https://www.geeksforgeeks.org/install-remmina-on-red-hat-enterprise-linux-rhel-9/

### pvc clone from windows disk to windows golden template
```
### https://docs.openshift.com/container-platform/4.15/virt/virtual_machines/creating_vms_custom/virt-creating-vms-uploading-images.html

### detach sysprep disk

### 重命名文件
move C:\Windows\Panther\unattend.xml C:\Windows\Panther\unattend.xml.sav

### generalize
%WINDIR%\System32\Sysprep\sysprep.exe /generalize /shutdown /oobe /mode:vm

### 关机

### 克隆 windows disk to windows golden image
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: win2k19-golden-image
    namespace: test2
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: lvms-vgb3-i
  volumeMode: Block
  resources:
    requests:
      storage: 60Gi
  dataSource:
    kind: PersistentVolumeClaim
    name: win2k19-vm-03
EOF
```

### 获取集群 install-config on day2
```
$ oc get configmap cluster-config-v1 -n kube-system -o yaml
```

### CNV 网络配置示例
```
### NNCP bond
cat <<EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: bond2 
spec:
  nodeSelector:
    node-role.kubernetes.io/worker: ''
  desiredState:
    interfaces:
      - name: bond2
        type: bond
        state: up
        ipv4:
          enabled: false
        link-aggregation:
          mode: 802.3ad
          options:
            miimon: '100'
            lacp_rate: 'fast'
          port:
            - ens6f0
            - ens6f1
      - name: ens6f0
        state: up
        type: ethernet
      - name: ens6f1
        state: up
        type: ethernet
EOF

### NNCP bridge
cat <<EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: intranet-bond2
spec:
  nodeSelector:
    node-role.kubernetes.io/worker: ''
  desiredState:
    interfaces:
      - name: br-bond2
        description: Linux bridge on bond2
        type: linux-bridge
        state: up
        bridge:
          options:
            stp:
              enabled: false
          port:
          - name: bond2
        ipv4:
          enabled: false
EOF

### NAD vm network bridge vlan
### https://docs.openshift.com/container-platform/4.16/virt/vm_networking/virt-connecting-vm-to-linux-bridge.html#virt-creating-linux-bridge-nad-cli_virt-connecting-vm-to-linux-bridge

cat <<EOF | oc apply -f
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: br-bond2-4
  namespace: default
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br-bond2-4
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "br-bond2-4",
    "type": "cnv-bridge",
    "bridge": "br-bond2",
    "macspoofchk": false, 
    "vlan": 4, 
    "disableContainerInterface": true,
    "preserveDefaultVlan": false     
  }'
EOF

### nncp bridge on eno2np1, nad 
cat <<EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: br-cnv
spec:
  nodeSelector:
    node-role.kubernetes.io/worker: ''
  desiredState:
    interfaces:
      - name: br-cnv
        description: Linux bridge on eno2np1
        type: linux-bridge
        state: up
        bridge:
          options:
            stp:
              enabled: false
          port:
          - name: eno2np1
        ipv4:
          enabled: false
EOF

cat <<EOF | oc apply -f
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: br-cnv-54
  namespace: default
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br-cnv
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "br-cnv-54",
    "type": "cnv-bridge",
    "bridge": "br-cnv",
    "macspoofchk": false,
    "vlan": 54,
    "disableContainerInterface": true,
    "preserveDefaultVlan": false    
  }'
EOF
```

### disable iptables rules for bridges - RHEL7
```
sysctl net.bridge.bridge-nf-call-iptables=0
```

### create file system and make filesystem
```
### 创建分区，创建pv,vg,lv，创建文件系统，挂载文件系统
mkdir /export
parted -s /dev/sdb mklabel msdos 
parted -s /dev/sdb unit mib mkpart primary 1 100%
parted -s /dev/sdb set 1 lvm on
pvcreate /dev/sdb1
vgcreate vol_nfs_grp1 /dev/sdb1
lvcreate -l 100%FREE -n logical_nfs_vol1 vol_nfs_grp1 
mkfs.xfs /dev/vol_nfs_grp1/logical_nfs_vol1
mount /dev/vol_nfs_grp1/logical_nfs_vol1 /export
```

### 恢复RESCUE EFI GRUB的步骤
```
mkdir /mnt/rescue

mount /dev/vdXY /mnt/rescue

mount -t proc /proc /mnt/rescue/proc
mount --rbind /sys /mnt/rescue/sys
mount --make-rslave /mnt/rescue/sys
mount --rbind /dev /mnt/rescue/dev
mount --make-rslave /mnt/rescue/dev
test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm
chmod 1777 /dev/shm

chroot /mnt/rescue /bin/bash 
source /etc/profile

mount /boot

grub-install --target=x86_64-efi --efi-directory=/boot

grub-mkconfig -o /boot/grub/grub.cfg
```

### run virt-who on openshift
https://blog.cudanet.org/openshift-virt-who-and-satellite/
```
oc new project virt-who
oc create serviceaccount virt-who
oc create clusterrole lsnodes --verb=list --resources=nodes
oc create clusterrole lsvims --verb=list --resources=vmis
oc adm policy add-cluster-role-to-user lsnodes system:serviceaccount:virt-who:virt-who
oc adm policy add-cluster-role-to-user lsvmis system:serviceaccount:virt-who:virt-who

oc get vmis -A --as=system:serviceaccount:virt-who:virt-who

# Generate a non-expiring token
cat << EOF | oc apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: virt-who-token
  namespace: virt-who
  annotations:
    kubernetes.io/service-account.name: virt-who
type: kubernetes.io/service-account-token
EOF

TOKEN=$(oc get secret virt-who-token -n virt-who -o json | jq .data.token | sed -e 's|"||g' | base64 -d)
echo $TOKEN

oc login https://api.ocp4.example.com:6443 --token=$TOKEN
oc get vmi -A
oc get node


```

### OCP-V检查ping是否能通，测试间隔0.01秒
```
ping -i 0.01 10.66.208.131
...
--- 10.66.208.131 ping statistics ---
4674 packets transmitted, 4650 packets received, 0.5% packet loss
round-trip min/avg/max/stddev = 0.311/0.756/2.458/0.143 ms

```

### 定期打快照脚本 - ocpv
```
### 脚本能实现某个namespace下通过定时任务打快照
### 并且删除超过过期时间的快照

#!/bin/bash
# Namespace with the VMs
NAMESPACE="tomaz-vms"
# Snapshot retention in days
RETENTION_DAYS=7
# Current date in epoch format for comparison
CURRENT_DATE=$(date +%s)
# Create snapshots for all VMs in the specified namespace
echo "Creating snapshots for all VMs in namespace: $NAMESPACE"
for vm in $(oc get vms -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}'); do
    snapshot_name="${vm}-snapshot-$(date +%Y-%m-%d)"
    echo "Creating snapshot for VM: $vm with name: $snapshot_name"
    oc create -f - <<EOF
apiVersion: snapshot.kubevirt.io/v1alpha1
kind: VirtualMachineSnapshot
metadata:
  name: $snapshot_name
  namespace: $NAMESPACE
spec:
  source:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: $vm
EOF
done
# Clean up snapshots older than RETENTION_DAYS in the specified namespace
echo "Cleaning up snapshots older than $RETENTION_DAYS days in namespace: $NAMESPACE"
# Get all snapshots in the namespace and filter them based on age
oc get virtualmachinesnapshots -n $NAMESPACE -o json | jq -c '.items[]' | while read snapshot; do
    snapshot_name=$(echo $snapshot | jq -r '.metadata.name')
    snapshot_creation_time=$(echo $snapshot | jq -r '.metadata.creationTimestamp')
    # Convert snapshot creation time to epoch for comparison
    snapshot_creation_epoch=$(date -d "$snapshot_creation_time" +%s)
    # Calculate the age of the snapshot in days
    snapshot_age=$(( (CURRENT_DATE - snapshot_creation_epoch) / 86400 ))
    # Delete the snapshot if it's older than RETENTION_DAYS
    if [ $snapshot_age -gt $RETENTION_DAYS ]; then
        echo "Deleting snapshot: $snapshot_name, which is $snapshot_age days old"
        oc delete virtualmachinesnapshot $snapshot_name -n $NAMESPACE
    else
        echo "Snapshot $snapshot_name is $snapshot_age days old and will be retained"
    fi
done

### 改进后的脚本
#!/bin/bash

# Namespace with the VMs
NAMESPACE="my-vms"
# Snapshot retention in days
RETENTION_DAYS=14
# Current date in epoch format for comparison
CURRENT_DATE=$(date +%s)

# Create snapshots for all VMs in the specified namespace
echo "Creating snapshots for all VMs in namespace: $NAMESPACE"
for vm in $(oc get vms -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}'); do
    snapshot_name="${vm}-auto-$(date +%Y-%m-%d)"
    echo "Creating snapshot for VM: $vm with name: $snapshot_name"
    oc create -f - <<EOF
apiVersion: snapshot.kubevirt.io/v1alpha1
kind: VirtualMachineSnapshot
metadata:
  name: $snapshot_name
  namespace: $NAMESPACE
spec:
  source:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: $vm
EOF
done

# Clean up snapshots older than RETENTION_DAYS in the specified namespace
echo "Cleaning up automated snapshots older than $RETENTION_DAYS days in namespace: $NAMESPACE"

# Get all snapshots in the namespace and filter them based on age
oc get virtualmachinesnapshots -n $NAMESPACE -o json | jq -c '.items[]' | while read snapshot; do
    snapshot_name=$(echo $snapshot | jq -r '.metadata.name')
    snapshot_creation_time=$(echo $snapshot | jq -r '.metadata.creationTimestamp')

    # Skip snapshots that do not start with "-auto-"
    if [[ ! "$snapshot_name" == *"-auto-"* ]]; then
        echo "Skipping manual snapshot: $snapshot_name"
        continue
    fi

    # Convert snapshot creation time to epoch for comparison
    snapshot_creation_epoch=$(date -d "$snapshot_creation_time" +%s)

    # Calculate the age of the snapshot in days
    snapshot_age=$(( (CURRENT_DATE - snapshot_creation_epoch) / 86400 ))

    # Delete the snapshot if it's older than RETENTION_DAYS
    if [ $snapshot_age -gt $RETENTION_DAYS ]; then
        echo "Deleting automated snapshot: $snapshot_name, which is $snapshot_age days old"
        oc delete virtualmachinesnapshot $snapshot_name -n $NAMESPACE
    else
        echo "Automated snapshot $snapshot_name is $snapshot_age days old and will be retained"
    fi
done
```

### 由于nfs服务器no_root_suaqsh引起的错误
```
{"component":"virt-launcher","level":"info","msg":"Collected all requested hook sidecar sockets","pos":"manager.go:88","timestamp":"2024-11-11T03:01:57.089601Z"}
{"component":"virt-launcher","level":"info","msg":"Sorted all collected sidecar sockets per hook point based on their priority and name: map[]","pos":"manager.go:91","timestamp":"2024-11-11T03:01:57.089670Z"}
{"component":"virt-launcher","level":"info","msg":"Connecting to libvirt daemon: qemu+unix:///session?socket=/var/run/libvirt/virtqemud-sock","pos":"libvirt.go:565","timestamp":"2024-11-11T03:01:57.090010Z"}
{"component":"virt-launcher","level":"info","msg":"Connecting to libvirt daemon failed: virError(Code=38, Domain=7, Message='Failed to connect socket to '/var/run/libvirt/virtqemud-sock': No such file or directory')","pos":"libvirt.go:573","timestamp":"2024-11-11T03:01:57.090315Z"}
{"component":"virt-launcher","level":"info","msg":"libvirt version: 10.0.0, package: 6.7.el9_4 (Red Hat, Inc. <http://bugzilla.redhat.com/bugzilla>, 2024-09-12-06:48:10, )","subcomponent":"libvirt","thread":"44","timestamp":"2024-11-11T03:01:57.128000Z"}
{"component":"virt-launcher","level":"info","msg":"hostname: fedora-maroon-muskox-92","subcomponent":"libvirt","thread":"44","timestamp":"2024-11-11T03:01:57.128000Z"}
{"component":"virt-launcher","level":"error","msg":"internal error: Unable to get session bus connection: Cannot spawn a message bus without a machine-id: Invalid machine ID in /var/lib/dbus/machine-id or /etc/machine-id","pos":"virGDBusGetSessionBus:126","subcomponent":"libvirt","thread":"44","timestamp":"2024-11-11T03:01:57.128000Z"}
{"component":"virt-launcher","level":"error","msg":"internal error: Unable to get system bus connection: Could not connect: No such file or directory","pos":"virGDBusGetSystemBus:99","subcomponent":"libvirt","thread":"44","timestamp":"2024-11-11T03:01:57.128000Z"}
{"component":"virt-launcher","level":"info","msg":"Connected to libvirt daemon","pos":"libvirt.go:581","timestamp":"2024-11-11T03:01:57.593556Z"}
{"component":"virt-launcher","level":"info","msg":"Registered libvirt event notify callback","pos":"client.go:563","timestamp":"2024-11-11T03:01:57.599981Z"}
{"component":"virt-launcher","level":"info","msg":"Marked as ready","pos":"virt-launcher.go:75","timestamp":"2024-11-11T03:01:57.600432Z"}
```

### Nested MachineConfig 
```
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 80-enable-nested-virt
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,b3B0aW9ucyBrdm1faW50ZWwgbmVzdGVkPTEKb3B0aW9ucyBrdm1fYW1kIG5lc3RlZD0xCg==
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/modprobe.d/kvm.conf
  osImageURL: ""
EOF
```

### NFS 
```
source ~/.bashrc-ocp
setVAR NFS_USER_FILE_PATH /data/ocp-cluster/${OCP_CLUSTER_ID}/nfs/userfile
setVAR NFS_DOMAIN helper.ocp.ap.vwg
setVAR NFS_CLIENT_NAMESPACE csi-nfs
setVAR NFS_CLIENT_PROVISIONER_IMAGE ${REGISTRY_DOMAIN}/${NFS_CLIENT_NAMESPACE}/nfs-client-provisioner:v4.0.2
setVAR PROVISIONER_NAME kubernetes-nfs
setVAR STORAGECLASS_NAME sc-csi-nfs

yum -y install nfs-utils
systemctl enable nfs-server --now
systemctl status nfs-server

mkdir -p ${NFS_USER_FILE_PATH}
chown -R nobody.nobody ${NFS_USER_FILE_PATH}
chmod -R 777 ${NFS_USER_FILE_PATH}
echo ${NFS_USER_FILE_PATH} *'(rw,sync,no_wdelay,no_root_squash,insecure)' > /etc/exports.d/userfile-${OCP_CLUSTER_ID}.exports

exportfs -rav | grep userfile
showmount -e | grep userfile

skopeo copy dir://tmp/nfs-client-provisioner docker://${REGISTRY_DOMAIN}/${NFS_CLIENT_NAMESPACE}/nfs-client-provisioner:v4.0.2
skopeo copy dir://tmp/nfs-client-provisioner docker://${REGISTRY_DOMAIN}/${NFS_CLIENT_NAMESPACE}/nfs-client-provisioner:latest
skopeo inspect --creds=openshift:redhat docker://${REGISTRY_DOMAIN}/${NFS_CLIENT_NAMESPACE}/nfs-client-provisioner:v4.0.2
skopeo inspect --creds=openshift:redhat docker://${REGISTRY_DOMAIN}/${NFS_CLIENT_NAMESPACE}/nfs-client-provisioner:latest

oc new-project ${NFS_CLIENT_NAMESPACE}
oc label namespace ${NFS_CLIENT_NAMESPACE} pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged --overwrite=true

cat << EOF > ~/rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa-nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cr-nfs-client-provisioner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: crb-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: sa-nfs-client-provisioner
    namespace: ${NFS_CLIENT_NAMESPACE}
roleRef:
  kind: ClusterRole
  name: cr-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: r-nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rb-nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
subjects:
  - kind: ServiceAccount
    name: sa-nfs-client-provisioner
    namespace: ${NFS_CLIENT_NAMESPACE}
roleRef:
  kind: Role
  name: r-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
EOF
oc apply -f ~/rbac.yaml
oc adm policy add-scc-to-user privileged -z sa-nfs-client-provisioner -n ${NFS_CLIENT_NAMESPACE}

cat << EOF > ~/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
  labels:
    app: nfs-client-provisioner
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: sa-nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: ${NFS_CLIENT_PROVISIONER_IMAGE}
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: ${PROVISIONER_NAME}
            - name: NFS_SERVER
              value: ${NFS_DOMAIN}
            - name: NFS_PATH
              value: ${NFS_USER_FILE_PATH}
      volumes:
        - name: nfs-client-root
          nfs:
            server: ${NFS_DOMAIN}
            path: ${NFS_USER_FILE_PATH}
EOF

oc apply -f ~/deployment.yaml

cat << EOF > ~/storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ${STORAGECLASS_NAME}
provisioner: ${PROVISIONER_NAME}
parameters:
  archiveOnDelete: "false"
  allowVolumeExpansion: true
EOF

oc apply -f ~/storageclass.yaml
oc patch storageclass sc-csi-nfs -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
```

### NNCP and NAD example
```
cat <<EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: br-cnv
spec:
  nodeSelector:
    node-role.kubernetes.io/worker: ''
  desiredState:
    interfaces:
      - name: br-cnv
        description: Linux bridge on eno2np1
        type: linux-bridge
        state: up
        bridge:
          options:
            stp:
              enabled: false
          port:
          - name: eno2np1
        ipv4:
          enabled: false
EOF

cat <<EOF | oc apply -f
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: br-cnv-54
  namespace: default
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br-cnv
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "br-cnv-54",
    "type": "cnv-bridge",
    "bridge": "br-cnv",
    "macspoofchk": false,
    "vlan": 54,
    "disableContainerInterface": true,
    "preserveDefaultVlan": false    
  }'
EOF
```

### source BASH ENV in tmux (interactive non-login mode)
https://unix.stackexchange.com/questions/320465/new-tmux-sessions-do-not-source-bashrc-file 
```
cat > ~/.bash_profile <<'EOF'
if [ -n "$BASH_VERSION" -a -n "$PS1" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi
EOF
```

### RDMA 无损网络和PFC（基于优先级的流量控制）ECN
https://blog.csdn.net/bandaoyu/article/details/115346857

### 虚拟机设置网卡Multiqueue支持
```
$ oc get vm rhel8-vm-01 -o json | jq .spec.template.spec.domain.devices.networkInterfaceMultiqueue=true | oc apply -f -
$ oc get vm rhel8-vm-01 -o json | jq .spec.template.spec.domain.devices.networkInterfaceMultiqueue


```

### 强制删除Terminationg状态的virt-launcher Pod
```
2m23s       Normal    Killing            pod/virt-launcher-rhel8-vm-01-8jdrt   Stopping container compute
2m24s       Warning   FailedKillPod      pod/virt-launcher-rhel8-vm-01-8jdrt   error killing pod: [failed to "KillContainer" for "compute" with KillContainerError: "rpc error: code = DeadlineExceeded desc = context deadline exceeded", failed to "KillPodSandbox" for "86d27f93-ec91-4af9-ae5c-ec2f18a36a21" with KillPodSandboxError: "rpc error: code = DeadlineExceeded desc = context deadline exceeded"]

$ oc get pods 
NAME                                       READY   STATUS        RESTARTS   AGE
virt-launcher-gitea-rhel9-pqxwh            1/1     Running       0          9d
virt-launcher-rhel-8-ivory-carp-18-hm6dq   1/1     Running       0          6d1h
virt-launcher-rhel8-vm-01-8jdrt            1/1     Terminating   0          16d

$ oc delete pod virt-launcher-rhel8-vm-01-8jdrt --force
```

### 查看virt-launcher pod支持的qemu机器类型
```
$ oc exec -it $(oc -n test2 get pods -l 'kubevirt.io/domain=rhel8-vm-01' -o name)  -- bash -c '/usr/libexec/qemu-kvm -machine ?'
Supported machines are:
pc                   RHEL 7.6.0 PC (i440FX + PIIX, 1996) (alias of pc-i440fx-rhel7.6.0)
pc-i440fx-rhel7.6.0  RHEL 7.6.0 PC (i440FX + PIIX, 1996) (default) (deprecated)
q35                  RHEL-9.4.0 PC (Q35 + ICH9, 2009) (alias of pc-q35-rhel9.4.0)
pc-q35-rhel9.4.0     RHEL-9.4.0 PC (Q35 + ICH9, 2009)
pc-q35-rhel9.2.0     RHEL-9.2.0 PC (Q35 + ICH9, 2009)
pc-q35-rhel9.0.0     RHEL-9.0.0 PC (Q35 + ICH9, 2009)
pc-q35-rhel8.6.0     RHEL-8.6.0 PC (Q35 + ICH9, 2009) (deprecated)
pc-q35-rhel8.5.0     RHEL-8.5.0 PC (Q35 + ICH9, 2009) (deprecated)
pc-q35-rhel8.4.0     RHEL-8.4.0 PC (Q35 + ICH9, 2009) (deprecated)
pc-q35-rhel8.3.0     RHEL-8.3.0 PC (Q35 + ICH9, 2009) (deprecated)
pc-q35-rhel8.2.0     RHEL-8.2.0 PC (Q35 + ICH9, 2009) (deprecated)
pc-q35-rhel8.1.0     RHEL-8.1.0 PC (Q35 + ICH9, 2009) (deprecated)
pc-q35-rhel8.0.0     RHEL-8.0.0 PC (Q35 + ICH9, 2009) (deprecated)
pc-q35-rhel7.6.0     RHEL-7.6.0 PC (Q35 + ICH9, 2009) (deprecated)
none                 empty machine
```

### skopeo copy 命令报错处理
```
skopeo copy --format v2s2 --all docker://docker.io/asciidoctor/docker-asciidoctor:latest dir:/tmp/docker-asciidoctor
...
FATA[0145] copying image 3/4 from manifest list: creating an updated image manifest: Unknown media type during manifest conversion: "application/vnd.in-toto+json" 

# 将参数调整为 --format oci
skopeo copy --format oci --all docker://docker.io/asciidoctor/docker-asciidoctor:latest dir:/tmp/docker-asciidoctor
```

### bash completion 与 oc completion
```
# .bashrc
...
if [ -f ~/.oc_completion_bash ]; then
  source ~/.oc_completion_bash
fi

[[ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]] && . "$(brew --prefix)/etc/profile.d/bash_completion.sh"

# .bash_profile
source ~/.bashrc
```

### 检查operator对应的images
```
oc get packagemanifests rhacs-operator -n openshift-marketplace -o json  | jq .status.channels[0].currentCSVDesc.relatedImages
[
  "registry.redhat.io/advanced-cluster-security/rhacs-main-rhel8@sha256:853ce8d425b52959557227dfb8cb241e6843e710be56b9aaa08fabaa294206a0",
  "registry.redhat.io/advanced-cluster-security/rhacs-scanner-db-slim-rhel8@sha256:7a149b76269ee937e2db0b9c1f63e5763c770babc9c32d6f19982163e9fc2831",
  "registry.redhat.io/advanced-cluster-security/rhacs-collector-slim-rhel8@sha256:c1eb9c5e3b62805cd30ee314fdf5b92d3ca7a3075b9d9ba02679e3d4b62240b4",
  "registry.redhat.io/advanced-cluster-security/rhacs-collector-rhel8@sha256:53e291598c0756cf0c5402107e568bdd8eb8ae37b41c4596467e09543c8b36dd",
  "registry.redhat.io/advanced-cluster-security/rhacs-scanner-rhel8@sha256:2f110138f996e4e455bb9158ca4174ebecf6053ec73c7793b596cd7094441e63",
  "registry.redhat.io/advanced-cluster-security/rhacs-rhel8-operator@sha256:bd2b9597b046a7d3726780343ef6887b9c848ca90e751e52a687166f92d890da",
  "registry.redhat.io/advanced-cluster-security/rhacs-scanner-slim-rhel8@sha256:ad8457ee562501c6fde0bba7361dfd717321af3e959de8f85156ce01f47b1622",
  "registry.redhat.io/advanced-cluster-security/rhacs-scanner-db-rhel8@sha256:03d198bbd9a30578ee57099fc1e6c795bd9ad714ad519fa5419ea89d4b446bfb",
  "registry.redhat.io/advanced-cluster-security/rhacs-roxctl-rhel8@sha256:e1e3ef9c4113c1a19a1bb304fdb79ec00abf9d54f4337d6481bf4d5943b259bd",
  "registry.redhat.io/advanced-cluster-security/rhacs-scanner-v4-db-rhel8@sha256:f29b582541b597299a37d2e7d834ad03a8bdcc140a867d6c6a3aa6cbe2bde946",
  "registry.redhat.io/advanced-cluster-security/rhacs-central-db-rhel8@sha256:3b5fffb40c68870387293458bca2ee6f035e7be0c7e95c9d7d47e806b1ee0841",
  "registry.redhat.io/advanced-cluster-security/rhacs-scanner-v4-rhel8@sha256:2f04f3b6de16da6f4d3ce4a16eff72654d45a76887764b0c54669316a0f54fa3"
]
```

### 根据packagemanifests生成下载镜像的名称
```
repo=advanced-cluster-security
mkdir -p /tmp/advanced-cluster-security

oc get packagemanifests rhacs-operator -n openshift-marketplace -o json  | jq .status.channels[0].currentCSVDesc.relatedImages | grep -Ev '\[|\]' | sed -e 's/^.*"registry/registry/g' -e 's/",$//g' -e 's/"$//g'  | while read i ; do 
  image=$i
  subimage=$(echo $i| sed -e 's,registry.redhat.io/advanced-cluster-security/,,g' -e 's,@.*$,,g')
  echo skopeo copy --format v2s2 --all docker://${image} dir:/tmp/${repo}/${subimage}
done 

skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-main-rhel8@sha256:853ce8d425b52959557227dfb8cb241e6843e710be56b9aaa08fabaa294206a0 dir:/tmp/advanced-cluster-security/rhacs-main-rhel8
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-scanner-db-slim-rhel8@sha256:7a149b76269ee937e2db0b9c1f63e5763c770babc9c32d6f19982163e9fc2831 dir:/tmp/advanced-cluster-security/rhacs-scanner-db-slim-rhel8
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-collector-slim-rhel8@sha256:c1eb9c5e3b62805cd30ee314fdf5b92d3ca7a3075b9d9ba02679e3d4b62240b4 dir:/tmp/advanced-cluster-security/rhacs-collector-slim-rhel8
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-collector-rhel8@sha256:53e291598c0756cf0c5402107e568bdd8eb8ae37b41c4596467e09543c8b36dd dir:/tmp/advanced-cluster-security/rhacs-collector-rhel8
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-scanner-rhel8@sha256:2f110138f996e4e455bb9158ca4174ebecf6053ec73c7793b596cd7094441e63 dir:/tmp/advanced-cluster-security/rhacs-scanner-rhel8
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-rhel8-operator@sha256:bd2b9597b046a7d3726780343ef6887b9c848ca90e751e52a687166f92d890da dir:/tmp/advanced-cluster-security/rhacs-rhel8-operator
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-scanner-slim-rhel8@sha256:ad8457ee562501c6fde0bba7361dfd717321af3e959de8f85156ce01f47b1622 dir:/tmp/advanced-cluster-security/rhacs-scanner-slim-rhel8
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-scanner-db-rhel8@sha256:03d198bbd9a30578ee57099fc1e6c795bd9ad714ad519fa5419ea89d4b446bfb dir:/tmp/advanced-cluster-security/rhacs-scanner-db-rhel8
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-roxctl-rhel8@sha256:e1e3ef9c4113c1a19a1bb304fdb79ec00abf9d54f4337d6481bf4d5943b259bd dir:/tmp/advanced-cluster-security/rhacs-roxctl-rhel8
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-scanner-v4-db-rhel8@sha256:f29b582541b597299a37d2e7d834ad03a8bdcc140a867d6c6a3aa6cbe2bde946 dir:/tmp/advanced-cluster-security/rhacs-scanner-v4-db-rhel8
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-central-db-rhel8@sha256:3b5fffb40c68870387293458bca2ee6f035e7be0c7e95c9d7d47e806b1ee0841 dir:/tmp/advanced-cluster-security/rhacs-central-db-rhel8
skopeo copy --format v2s2 --all docker://registry.redhat.io/advanced-cluster-security/rhacs-scanner-v4-rhel8@sha256:2f04f3b6de16da6f4d3ce4a16eff72654d45a76887764b0c54669316a0f54fa3 dir:/tmp/advanced-cluster-security/rhacs-scanner-v4-rhel8
```


### operator - 删除job和job相关的configmap
```
https://access.redhat.com/solutions/6459071

$ jobname=$(oc get job -n openshift-marketplace -o json | jq -r '.items[] | select(.spec.template.spec.containers[].env[].value|contains ("rhacs")) | .metadata.name')
$ oc delete job ${jobname} -n openshift-marketplace
$ oc delete configmap ${jobname} -n openshift-marketplace
```

### 关闭 ceph osd pool pg autoscale
```
ceph osd ls pool detail
# 检查 osd pool pg autoscale 状态
ceph osd pool autoscale-status

# 关闭 osd pool pg autoscale 
ceph osd pool set pool rbd-pool pg_autoscale_mode off

# 设置 ceph osd pool 属性
osd pool set <poolname> size|min_size|pg_num|pgp_num|pgp_num_actual|crush_rule|           set pool parameter <var> to <val>
 hashpspool|nodelete|nopgchange|nosizechange|write_fadvise_dontneed|noscrub|nodeep-scrub| 
 hit_set_type|hit_set_period|hit_set_count|hit_set_fpp|use_gmt_hitset|target_max_bytes|   
 target_max_objects|cache_target_dirty_ratio|cache_target_dirty_high_ratio|cache_target_  
 full_ratio|cache_min_flush_age|cache_min_evict_age|min_read_recency_for_promote|min_     
 write_recency_for_promote|fast_read|hit_set_grade_decay_rate|hit_set_search_last_n|      
 scrub_min_interval|scrub_max_interval|deep_scrub_interval|recovery_priority|recovery_op_ 
 priority|scrub_priority|compression_mode|compression_algorithm|compression_required_     
 ratio|compression_max_blob_size|compression_min_blob_size|csum_type|csum_min_block|csum_ 
 max_block|allow_ec_overwrites|fingerprint_algorithm|pg_autoscale_mode|pg_autoscale_bias| 
 pg_num_min|pg_num_max|target_size_bytes|target_size_ratio|dedup_tier|dedup_chunk_        
 algorithm|dedup_cdc_chunk_size|eio|bulk <val> {--yes-i-really-mean-it}  
```

### Nvidia Mellanox precompiled container build instructions for doca drivers
https://mellanox.github.io/network-operator-docs/advanced-configurations.html#precompiled-container-build-instructions-for-doca-drivers
https://raw.githubusercontent.com/Mellanox/doca-driver-build/249ff2118e4ae849d3c138ca6cbc5942f6101007/RHEL_Dockerfile
https://raw.githubusercontent.com/Mellanox/doca-driver-build/249ff2118e4ae849d3c138ca6cbc5942f6101007/dtk_nic_driver_build.sh
https://linux.mellanox.com/public/repo/doca/2.9.1/SOURCES/MLNX_OFED/
https://mellanox.github.io/network-operator-docs/advanced-configurations.html#rhcos-specific-build-parameters
```
### 参考链接
https://mellanox.github.io/network-operator-docs/advanced-configurations.html#precompiled-container-build-instructions-for-doca-drivers
### 下载以下文件
mkdir -p /tmp/build
cd /tmp/build
wget -4 https://raw.githubusercontent.com/Mellanox/doca-driver-build/249ff2118e4ae849d3c138ca6cbc5942f6101007/RHEL_Dockerfile
wget -4 https://raw.githubusercontent.com/Mellanox/doca-driver-build/249ff2118e4ae849d3c138ca6cbc5942f6101007/entrypoint.sh
wget -4 https://raw.githubusercontent.com/Mellanox/doca-driver-build/249ff2118e4ae849d3c138ca6cbc5942f6101007/dtk_nic_driver_build.sh
chmod +x *.sh

### 获取 DOCA 对应的 OFED 链接
### DOCA version 2.9.1
https://linux.mellanox.com/public/repo/doca/2.9.1/SOURCES/MLNX_OFED/MLNX_OFED_SRC-24.10-1.1.4.0.tgz
### 根据 DOCA 版本及对应的 OFED 版本设置 D_DOCA_VERSION 和 D_OFED_VERSION
### 并且设置对应的 D_OFED_URL_PATH

### 获取 D_KERNEL_VER
### 查询 https://access.redhat.com/solutions/7077108 或者在 rhcos 节点上执行 uname -a

### 获取 D_BASE_IMAGE 
### 例如
oc adm release info 4.16.26 --image-for=driver-toolkit

podman build --no-cache \
 --build-arg D_OS=rhcos4.16 \
 --build-arg D_ARCH=x86_64 \
 --build-arg D_KERNEL_VER=5.14.0-427.47.1.el9_4.x86_64 \
 --build-arg D_DOCA_VERSION=2.9.1 \
 --build-arg D_OFED_VERSION=24.10-1.1.4.0 \
 --build-arg D_OFED_URL_PATH=https://linux.mellanox.com/public/repo/doca/2.9.1/SOURCES/MLNX_OFED/MLNX_OFED_SRC-24.10-1.1.4.0.tgz \
 --build-arg D_BASE_IMAGE="quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:d0e1f1e1fa657e1bcb148ef714f9325d75ef3a21248a7cef56d404a15b143bea" \
 --build-arg D_FINAL_BASE_IMAGE=registry.access.redhat.com/ubi9/ubi:9.4 \
 --tag quay.io/jwang1/doca-driver:24.10-1.1.4.0-0-5.14.0-427.47.1.el9_4.x86_64-rhcos4.16-amd64 \
 --tag quay.io/jwang1/doca-driver:24.10-1.1.4.0-0-rhcos4.16-amd64 \
 --tag quay.io/jwang1/doca-driver:24.10-1.1.4.0-0 \
 -f RHEL_Dockerfile \
 --target precompiled . 2>&1 | tee build.log

podman push quay.io/jwang1/doca-driver:24.10-1.1.4.0-0 
podman push quay.io/jwang1/doca-driver:24.10-1.1.4.0-0-rhcos4.16-amd64
podman push quay.io/jwang1/doca-driver:24.10-1.1.4.0-0-5.14.0-427.47.1.el9_4.x86_64-rhcos4.16-amd64

```

### 配置rdmaSharedDevicePlugin
```
...
  rdmaSharedDevicePlugin:
    config: | {
      "configList": [
         {
           "resourceName": "rdma_shared_device_eth1",
           "rdmaHcaMax": 63,
           "selectors": {
             "ifNames": ["ens108np0"]
           }
         },
         {
           "resourceName": "rdma_shared_device_eth2",
           "rdmaHcaMax": 63,
           "selectors": {
             "ifNames": ["ens110np0"]
           }
         },
         {
           "resourceName": "rdma_shared_device_eth3",
           "rdmaHcaMax": 63,
           "selectors": {
             "ifNames": ["ens112np0"]
           }
         },
         {
           "resourceName": "rdma_shared_device_eth4",
           "rdmaHcaMax": 63,
           "selectors": {
             "ifNames": ["ens114np0"]
           }
         }
       ]
    }
    image: k8s-rdma-shared-dev-plugin
    repository: ghcr.io/mellanox
    version: v1.5.1
  secondaryNetwork:
    ipoib:
      image: ipoib-cni
      repository: ghcr.io/mellanox
      version: v1.2.0
  nvIpam:
    enableWebhook: false
    image: nvidia-k8s-ipam
    repository: ghcr.io/mellanox
    version: v0.2.0

```

### 配置 MacvlanNetwork
```
apiVersion: mellanox.com/v1alpha1
kind: MacvlanNetwork
metadata:
  name: rdmashared-net-eth1
spec:
  networkNamespace: default
  master: ens108np0
  mode: bridge
  mtu: 1500
  ipam: |
    {
      "type": "whereabouts",
      "range": "172.19.5.0/24",
      "exclude": [
       "172.19.5.1/32",
       "172.19.5.2/32",
       "172.19.5.3/32",
       "172.19.5.4/32",
       "172.19.5.5/32",
       "172.19.5.6/32",
       "172.19.5.7/32",
       "172.19.5.8/32",
      ],
      "gateway": "172.19.5.254"
    }

apiVersion: mellanox.com/v1alpha1
kind: MacvlanNetwork
metadata:
  name: rdmashared-net-eth2
spec:
  networkNamespace: default
  master: ens110np0
  mode: bridge
  mtu: 1500
  ipam: |
    {
      "type": "whereabouts",
      "range": "172.19.6.0/24",
      "exclude": [
       "172.19.6.1/32",
       "172.19.6.2/32",
       "172.19.6.3/32",
       "172.19.6.4/32",
       "172.19.6.5/32",
       "172.19.6.6/32",
       "172.19.6.7/32",
       "172.19.6.8/32",
      ],
      "gateway": "172.19.6.254"
    }

apiVersion: mellanox.com/v1alpha1
kind: MacvlanNetwork
metadata:
  name: rdmashared-net-eth3
spec:
  networkNamespace: default
  master: ens112np0
  mode: bridge
  mtu: 1500
  ipam: |
    {
      "type": "whereabouts",
      "range": "172.19.7.0/24",
      "exclude": [
       "172.19.7.1/32",
       "172.19.7.2/32",
       "172.19.7.3/32",
       "172.19.7.4/32",
       "172.19.7.5/32",
       "172.19.7.6/32",
       "172.19.7.7/32",
       "172.19.7.8/32",
      ],
      "gateway": "172.19.7.254"
    }

apiVersion: mellanox.com/v1alpha1
kind: MacvlanNetwork
metadata:
  name: rdmashared-net-eth4
spec:
  networkNamespace: default
  master: ens114np0
  mode: bridge
  mtu: 1500
  ipam: |
    {
      "type": "whereabouts",
      "range": "172.19.8.0/24",
      "exclude": [
       "172.19.8.1/32",
       "172.19.8.2/32",
       "172.19.8.3/32",
       "172.19.8.4/32",
       "172.19.8.5/32",
       "172.19.8.6/32",
       "172.19.8.7/32",
       "172.19.8.8/32",
      ],
      "gateway": "172.19.8.254"
    }

```

### 获取节点Capacity
```
oc describe node -l node-role.kubernetes.io/worker=| grep -E 'Capacity:|Allocatable:' -A9
```

### 测试 RDMA Shared Network 性能
```
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
name: rdma
  namespace: default
EOF

$ oc -n default adm policy add-scc-to-user privileged -z rdma

$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: rdma-eth1-07-workload
  namespace: default
  annotations:
    k8s.v1.cni.cncf.io/networks: rdmashared-net-eth1
spec:
  nodeSelector:
    kubernetes.io/hostname: worker07.ocp-wh-01.taikangcloud.com
  serviceAccountName: rdma
  containers:
  - image: quay.io/redhat_emp1/ecosys-nvidia/gpu-operator:tools
    name: rdma-eth1-07-workload
    command:
      - sh
      - -c
      - sleep inf
    securityContext:
      privileged: true
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        rdma/rdma_shared_device_eth1: 1
      requests:
        rdma/rdma_shared_device_eth1: 1
EOF

$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: rdma-eth1-08-workload
  namespace: default
  annotations:
    k8s.v1.cni.cncf.io/networks: rdmashared-net-eth1
spec:
  nodeSelector:
    kubernetes.io/hostname: worker08.ocp-wh-01.taikangcloud.com
  serviceAccountName: rdma
  containers:
  - image: quay.io/redhat_emp1/ecosys-nvidia/gpu-operator:tools
    name: rdma-eth1-08-workload
    command:
      - sh
      - -c
      - sleep inf
    securityContext:
      privileged: true
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        rdma/rdma_shared_device_eth1: 1
      requests:
        rdma/rdma_shared_device_eth1: 1
EOF

$ oc get pods -n default

$ oc -n default get pod rdma-eth1-07-workload -o yaml | grep -E 'default/rdmashared' -A3
<rdma-eth1-07-workload pod ip>

$ oc rsh -n default rdma-eth1-07-workload
sh-5.1# ib_write_bw -R --report_gbits --tos=106

$ oc rsh -n default rdma-eth1-08-workload 
sh-5.1# ib_write_bw --report_gbits <rdma-eth1-07-workload pod ip> --tos=106 --run_infinitely

```

### 检查 pod 里的 container 的内存占用情况
```
$ kubectl -n test2 top pod virt-launcher-rhel8-vm-01-hqm4d --containers 
POD                               NAME      CPU(cores)   MEMORY(bytes)   
virt-launcher-rhel8-vm-01-hqm4d   compute   7m           806Mi 

### 检查 pod 的 spec.containers[0].resources
$ oc -n test2 get pod virt-launcher-rhel8-vm-01-hqm4d -o json  | jq .spec.containers[0].resources
{
  "limits": {
    "bridge.network.kubevirt.io/br1": "1",
    "devices.kubevirt.io/kvm": "1",
    "devices.kubevirt.io/tun": "1",
    "devices.kubevirt.io/vhost-net": "1"
  },
  "requests": {
    "bridge.network.kubevirt.io/br1": "1",
    "cpu": "200m",
    "devices.kubevirt.io/kvm": "1",
    "devices.kubevirt.io/tun": "1",
    "devices.kubevirt.io/vhost-net": "1",
    "ephemeral-storage": "50M",
    "memory": "2302Mi"
  }
}

```

### 强制关机
```
virtctl stop --force=true --grace-period=0 xxx-vm
```

### 检查虚拟机内存占用 - cnv 
```
$ kubectl -n jwang top pod virt-launcher-rhel9-vm-01-c9fwz --containers 
POD                               NAME      CPU(cores)   MEMORY(bytes)   
virt-launcher-rhel9-vm-01-c9fwz   compute   92m          1253Mi

$ oc -n jwang get vm rhel9-vm-01 -o json | jq .spec.template.spec.domain.memory 
{
  "guest": "2Gi"
}

$ oc -n jwang get pod virt-launcher-rhel9-vm-01-c9fwz -o json | jq .spec.containers[0].resources.requests
{
  "bridge.network.kubevirt.io/br-vlan153": "1",
  "cpu": "100m",
  "devices.kubevirt.io/kvm": "1",
  "devices.kubevirt.io/tun": "1",
  "devices.kubevirt.io/vhost-net": "1",
  "ephemeral-storage": "50M",
  "memory": "2294Mi"
}

$ virtctl stop rhel9-vm-01

$ oc -n jwang get vm rhel9-vm-01 -o json | jq '.spec.template.spec.domain.resources.requests.memory+="2.5Gi"' | oc apply -f -

$ oc -n jwang get vm rhel9-vm-01 -o json | jq .spec.template.spec.domain.resources
{
  "requests": {
    "memory": "2560Mi"
  }
}

$ virtctl start rhel9-vm-01 
$ oc -n jwang get pod virt-launcher-rhel9-vm-01-c9fwz -o json | jq .spec.containers[0].resources.requests
{
  "bridge.network.kubevirt.io/br-vlan153": "1",
  "cpu": "100m",
  "devices.kubevirt.io/kvm": "1",
  "devices.kubevirt.io/tun": "1",
  "devices.kubevirt.io/vhost-net": "1",
  "ephemeral-storage": "50M",
  "memory": "2807Mi"
}


$ oc -n jwang get vm rhel9-vm-01 -o json | jq 'del(.spec.template.spec.domain.resources.requests)' | oc apply -f -

$ oc -n jwang get vm rhel9-vm-01 -o json | jq .spec.template.spec.domain.resources
{}

$ oc -n jwang get $(oc -n jwang get pod -l vm.kubevirt.io/name='rhel9-vm-01' -o name) -o json | jq .spec.containers[0].resources.requests
{
  "bridge.network.kubevirt.io/br-vlan153": "1",
  "cpu": "100m",
  "devices.kubevirt.io/kvm": "1",
  "devices.kubevirt.io/tun": "1",
  "devices.kubevirt.io/vhost-net": "1",
  "ephemeral-storage": "50M",
  "memory": "2294Mi"
}

### 执行内存压力测试
$ virtctl console rhel9-vm-01
$ sudo -i
# stress-ng --vm $(nproc) --vm-bytes 90% --vm-keep 

```

### etcd 性能问题分析
```
https://access.redhat.com/solutions/5489721
### 查看是否有etcd disk backend commit时间小于 0.05 的范围
histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket[5m])) < 0.05

### 查看是否有etcd disk backend commit时间过长的阶段，如果有说明有问题
histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket[5m])) > 0.03

### 通常在etcd disk backend commit时间过长的阶段也会出现etcd disk wal fsync 时间较长，两者可以进行相互印证
histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m])) > 0.015
```

### trident fcp integration
```
### 准备worker节点的多路径配置
https://docs.netapp.com/us-en/trident/trident-use/fcp.html#prepare-the-worker-node

export MULTIPATH_CONF=$(cat << EOF | base64 -w 0
defaults {
   user_friendly_names yes
   find_multipaths no
}
blacklist {
}
EOF)

cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-multipathing
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
         source: data:text/plain;charset=utf-8;base64,${MULTIPATH_CONF}
        filesystem: root
        mode: 420
        path: /etc/multipath.conf
    systemd:
      units:
      - name: multipathd.service
        enabled: true
EOF

### 配置NetApp FAS FC相关基础配置案例
https://blog.csdn.net/sjj222sjj/article/details/112972814

### RHEL 查询 WWPN 的命令
$ find /sys/class/fc_host/*/ -name 'port_name'             << retrieve path to wwpn entry
$ grep -v "zZzZ" -H /sys/class/fc_host/host*/*_name
/sys/class/fc_host/host6/fabric_name:0x100000051e900105    << switch port name, wwpn
/sys/class/fc_host/host6/node_name:0x200000e08b87de9a      <<    HBA node name, wwnn
/sys/class/fc_host/host6/port_name:0x210000e08b87de9a      <<    HBA port name, wwpn
/sys/class/fc_host/host6/symbolic_name:QLE2462 FW:v7.03.00 DVR:v8.07.00.18.07.2-k

### 配置 TridentBackendConfig
### https://docs.netapp.com/us-en/trident/trident-use/fcp.html#create-a-backend-configuration

kubectl -n trident create -f backend-tbc-ontap-san-secret.yaml
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: backend-tbc-ontap-san-secret
  namespace: trident
type: Opaque
stringData:
  username: admin
  password: 'NOTREALPASSWORD'
EOF

# TridentBackendConfig example with FC
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: backend-tbc-ontap-san
  namespace: trident
spec:
  version: 1
  backendName: ontap-san-backend
  storageDriverName: ontap-san
  managementLIF: 10.0.0.1
  sanType: fcp
  svm: trident_svm
  credentials:
    name: backend-tbc-ontap-san-secret

### Trident SCSI over FiberChannel StorageClass配置参考
### https://community.netapp.com/t5/Tech-ONTAP-Blogs/Fibre-Channel-technology-preview-support-in-Trident/ba-p/457427

### 创建StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fcp-sc
provisioner: csi.trident.netapp.io
allowVolumeExpansion: true
parameters:
  backendType: "ontap-san"
  fsType: "ext4"

### 创建 VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-snapclass
driver: csi.trident.netapp.io
deletionPolicy: Delete


```

### Google 文档编辑的文件适应页宽显示的快捷键是 
```
Command+Option+[
```

### 设置 default storageclass
```
apiVersion: lvm.topolvm.io/v1alpha1
kind: LVMCluster
metadata:
  name: test-lvmcluster
  namespace: openshift-storage
spec:
  storage:
    deviceClasses:
    - fstype: xfs
      name: vg1
      deviceSelector:
        paths:
          - /dev/vdc
      nodeSelector:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - "worker1.ocp4.example.com"
      thinPoolConfig:
        name: thin-pool-1
        overprovisionRatio: 10
        sizePercent: 90

oc patch storageclass lvms-vg1 -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'

### nodeSelector的例子
      nodeSelector:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - "worker1.ocp4.example.com"

      db:
        nodeSelector:
          kubernetes.io/hostname: "worker1.ocp4.example.com"
      db:
        resources:
          requests:
            cpu: '0.1'
            memory: 256Mi

oc run log4shell -n log4shell --image=docker.io/elastic/logstash:7.13.0
```

### upload scanner vuln updates
```
wget -4 https://install.stackrox.io/scanner/scanner-vuln-updates.zip
export ROX_API_TOKEN='ey...TNo'
export ROX_CENTRAL_ADDRESS=central-stackrox.apps.ocp4.example.com:443
roxctl scanner upload-db \
  -e "$ROX_CENTRAL_ADDRESS" \
  --insecure-skip-tls-verify \
  --scanner-db-file=scanner-vuln-updates.zip
```

### IE 如何禁用 Ennhanced Security Configuration
https://www.casbay.com/guide/kb/disable-enhanced-security-configuration-for-internet-explorer-in-windows-server-2019-2016

### 检查etcd状态

```
$ oc -n openshift-etcd rsh -c etcd etcd-master1.ocp4.example.com
sh-5.1# etcdctl endpoint status -w table
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|           ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://192.168.122.101:2379 | ded1a7fce225b098 |  3.5.14 |  106 MB |     false |      false |       126 |   33378766 |           33378766 |        |
| https://192.168.122.102:2379 | c1e3651bf07a9547 |  3.5.14 |  108 MB |      true |      false |       126 |   33378766 |           33378766 |        |
| https://192.168.122.103:2379 |  b85d428f8fd4aeb |  3.5.14 |  107 MB |     false |      false |       126 |   33378766 |           33378766 |        |
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+

### leader 是 master2
```

### windows 检查网卡 InterfaceName
```
netsh interface show interface

以下内容由OpenAI生成
unattend.xml 里设置静态 ip 地址
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" xmlns="urn:schemas-microsoft-com:unattend">
            <FirstLogonCommands>
                <SynchronousCommand>
                    <CommandLine>netsh interface ipv4 set address name="Ethernet Instance 0" static 192.168.1.100 255.255.255.0 192.168.1.1</CommandLine>
                    <Description>Set Static IP Address for the First Network Interface</Description>
                    <Order>1</Order>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
    
</unattend>
```

### StorageProfile for ocs-external-storagecluster-ceph-rbd
```
oc get storageprofile ocs-external-storagecluster-ceph-rbd -o yaml  | more
apiVersion: cdi.kubevirt.io/v1beta1
kind: StorageProfile
metadata:
  creationTimestamp: "2025-01-17T10:59:38Z"
  generation: 2
  labels:
    app: containerized-data-importer
    app.kubernetes.io/component: storage
    app.kubernetes.io/managed-by: cdi-controller
    app.kubernetes.io/part-of: hyperconverged-cluster
    app.kubernetes.io/version: 4.16.3
    cdi.kubevirt.io: ""
  name: ocs-external-storagecluster-ceph-rbd
  ownerReferences:
  - apiVersion: cdi.kubevirt.io/v1beta1
    blockOwnerDeletion: true
    controller: true
    kind: CDI
    name: cdi-kubevirt-hyperconverged
    uid: 3f6e9454-7277-4638-ac3f-d83b11b6dcd9
  resourceVersion: "59661183"
  uid: ec5f9d78-4572-4934-9568-11960a5cb0a9
spec: {}
status:
  claimPropertySets:
  - accessModes:
    - ReadWriteMany
    volumeMode: Block
  - accessModes:
    - ReadWriteOnce
    volumeMode: Block
  - accessModes:
    - ReadWriteOnce
    volumeMode: Filesystem
  cloneStrategy: csi-clone
  dataImportCronSourceFormat: snapshot
  provisioner: openshift-storage.rbd.csi.ceph.com
```

### 如何配置VMware Distributed Switch
https://www.nakivo.com/blog/vmware-distributed-switch-configuration/
```
https://www.nakivo.com/blog/vmware-distributed-switch-configuration/
```

### DeepSeek 生成的 Prometheus Metrics 查询程序
```
### 查询 histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket[5m])) > 0.03 的python 程序
### 用法是 python query_prometheus.py 2025-01-24T00:00:00Z 2025-01-24T08:00:00Z 

cat > query_prometheus.py <<'EOF'
import requests
import json
import sys  # 导入 sys 模块
from datetime import datetime

def query_prometheus():
    # Prometheus 服务器地址
    prometheus_url = "http://localhost:9090/api/v1/query_range"

    # 查询参数
    params = {
        "query": 'histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket[5m]))',
        "start": sys.argv[1],  # 从命令行参数获取 start
        "end": sys.argv[2],    # 从命令行参数获取 end
        "step": "30"           # 步长（秒）
    }

    # 发送 HTTP 请求
    response = requests.get(prometheus_url, params=params)

    # 检查请求是否成功
    if response.status_code != 200:
        print(f"请求失败，状态码：{response.status_code}")
        print(response.text)
        exit(1)

    # 解析 JSON 数据
    data = response.json()

    # 过滤出满足条件的数据点并转换为 RFC3339 格式
    print("满足条件的数据点：")
    for result in data["data"]["result"]:
        for timestamp, metric_value in result["values"]:
            if float(metric_value) > 0.03:  # 过滤条件
                # 将 Unix 时间戳转换为 RFC3339 格式
                rfc3339_time = datetime.utcfromtimestamp(int(timestamp)).strftime('%Y-%m-%dT%H:%M:%SZ')
                print(f"时间: {rfc3339_time}, 值: {metric_value}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("用法: python query_prometheus.py <start_timestamp> <end_timestamp>")
        exit(1)
    query_prometheus()
EOF
```

### 添加CA和证书
```
cd /etc/pki/ca-trust/source/anchors/
curl -LOk https://certs.corp.redhat.com/RH-IT-Root-CA.crt
curl -LOk https://certs.corp.redhat.com/certs/2022-IT-Root-CA.pem
update-ca-trust
```

### Run.AI 的调度器
https://docs.run.ai/v2.17/Researcher/scheduling/the-runai-scheduler/

### Podman login auth.json
```
${XDG_RUNTIME_DIR}/containers/auth.json
```

### OpenShift AI - Nvidia GPU - Working with Taints
https://ai-on-openshift.io/odh-rhoai/nvidia-gpus/#working-with-taints
```
apiVersion: nvidia.com/v1
kind: ClusterPolicy
metadata:
  ...
  name: gpu-cluster-policy
spec:
  vgpuDeviceManager: ...
  migManager: ...
  operator: ...
  dcgm: ...
  gfd: ...
  dcgmExporter: ...
  cdi: ...
  driver: ...
  devicePlugin: ...
  mig: ...
  sandboxDevicePlugin: ...
  validator: ...
  nodeStatusExporter: ...
  daemonsets:
    ...
    tolerations:
      - effect: NoSchedule
        key: node.cloudprovider.kubernetes.io/uninitialized
        operator: Exists
  sandboxWorkloads: ...
  gds: ...
  vgpuManager: ...
  vfioManager: ...
  toolkit: ...
```

### 获取 rhel coreos rpm package list 的方法
https://access.redhat.com/solutions/5787001
```
oc adm release info --image-for=rhel-coreos 4.16.17
PATH_TO_AUTH_FILE=/run/user/0/containers/auth.json
podman run --rm --authfile ${PATH_TO_AUTH_FILE} -it --entrypoint /bin/rpm $(oc adm release info --image-for=rhel-coreos 4.16.17) -qa
```

### Patch hostedcluster CR 添加 spec.additionalTrustBundle 和 spec.imageContentSources
```
oc -n jwang-hcp-demo patch hostedcluster jwang-hcp-demo \
  --type=json \
  --patch '
[
  {
    "op": "add",
    "path": "/spec/additionalTrustBundle",
    "value": {
      "name": "user-ca-bundle"
    }
  },
  {
    "op": "add",
    "path": "/spec/imageContentSources",
    "value": [
      {
        "source": "quay.io/openshift-release-dev/ocp-v4.0-art-dev",
        "mirrors": ["helper.ocp.ap.vwg:5000/ocp4/openshift4"]
      },
      {
        "source": "quay.io/openshift-release-dev/ocp-release",
        "mirrors": ["helper.ocp.ap.vwg:5000/ocp4/openshift4"]
      },
      {
        "source": "registry.redhat.io/rhacm2",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhacm2"]
      },
      {
        "source": "registry.redhat.io/multicluster-engine",
        "mirrors": ["helper.ocp.ap.vwg:5000/multicluster-engine"]
      },
      {
        "source": "registry.redhat.io/openshift4",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift4"]
      },
      {
        "source": "registry.redhat.io/source-to-image",
        "mirrors": ["helper.ocp.ap.vwg:5000/source-to-image"]
      },
      {
        "source": "registry.redhat.io/rhel9",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhel9"]
      },
      {
        "source": "registry.redhat.io/rhel8",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhel8"]
      },
      {
        "source": "registry.redhat.io/ubi8",
        "mirrors": ["helper.ocp.ap.vwg:5000/ubi8"]
      },
      {
        "source": "registry.redhat.io/rhmtc",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhmtc"]
      },
      {
        "source": "registry.redhat.io/openshift-update-service",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-update-service"]
      }
    ]
  }
]
'

oc -n jwang-hcp-demo patch hostedcluster jwang-hcp-demo \
  --type=json \
  --patch '
[
  {
    "op": "replace",
    "path": "/spec/imageContentSources",
    "value": [
      {
        "source": "quay.io/openshift-release-dev/ocp-v4.0-art-dev",
        "mirrors": ["helper.ocp.ap.vwg:5000/ocp4/openshift4"]
      },
      {
        "source": "quay.io/openshift-release-dev/ocp-release",
        "mirrors": ["helper.ocp.ap.vwg:5000/ocp4/openshift4"]
      },
      {
        "source": "registry.redhat.io/devworkspace",
        "mirrors": ["helper.ocp.ap.vwg:5000/devworkspace"]
      },
      {
        "source": "registry.redhat.io/workload-availability",
        "mirrors": ["helper.ocp.ap.vwg:5000/workload-availability"]
      },
      {
        "source": "registry.redhat.io/openshift-logging",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-logging"]
      },
      {
        "source": "registry.redhat.io/rhacm2",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhacm2"]
      },
      {
        "source": "registry.redhat.io/multicluster-engine",
        "mirrors": ["helper.ocp.ap.vwg:5000/multicluster-engine"]
      },
      {
        "source": "registry.redhat.io/openshift4",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift4"]
      },
      {
        "source": "registry.redhat.io/source-to-image",
        "mirrors": ["helper.ocp.ap.vwg:5000/source-to-image"]
      },
      {
        "source": "registry.redhat.io/rhel9",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhel9"]
      },
      {
        "source": "registry.redhat.io/rhel8",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhel8"]
      },
      {
        "source": "registry.redhat.io/ubi8",
        "mirrors": ["helper.ocp.ap.vwg:5000/ubi8"]
      },
      {
        "source": "registry.redhat.io/ansible-automation-platform-25",
        "mirrors": ["helper.ocp.ap.vwg:5000/ansible-automation-platform-25"]
      },
      {
        "source": "registry.redhat.io/rhceph",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhceph"]
      },
      {
        "source": "registry.redhat.io/oadp",
        "mirrors": ["helper.ocp.ap.vwg:5000/oadp"]
      },
      {
        "source": "registry.redhat.io/advanced-cluster-security",
        "mirrors": ["helper.ocp.ap.vwg:5000/advanced-cluster-security"]
      },
      {
        "source": "registry.redhat.io/openshift-update-service",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-update-service"]
      },
      {
        "source": "registry.redhat.io/ansible-automation-platform",
        "mirrors": ["helper.ocp.ap.vwg:5000/ansible-automation-platform"]
      },
      {
        "source": "registry.redhat.io/web-terminal",
        "mirrors": ["helper.ocp.ap.vwg:5000/web-terminal"]
      },
      {
        "source": "registry.redhat.io/openshift-gitops-1",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-gitops-1"]
      },
      {
        "source": "registry.redhat.io/lvms4",
        "mirrors": ["helper.ocp.ap.vwg:5000/lvms4"]
      },
      {
        "source": "registry.redhat.io/rh-sso-7",
        "mirrors": ["helper.ocp.ap.vwg:5000/rh-sso-7"]
      },
      {
        "source": "registry.redhat.io/ubi8-minimal",
        "mirrors": ["helper.ocp.ap.vwg:5000/ubi8-minimal"]
      },
      {
        "source": "registry.redhat.io/migration-toolkit-virtualization",
        "mirrors": ["helper.ocp.ap.vwg:5000/migration-toolkit-virtualization"]
      },
      {
        "source": "registry.redhat.io/openshift-pipelines",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-pipelines"]
      },
      {
        "source": "registry.redhat.io/container-native-virtualization",
        "mirrors": ["helper.ocp.ap.vwg:5000/container-native-virtualization"]
      },
      {
        "source": "registry.redhat.io/odf4",
        "mirrors": ["helper.ocp.ap.vwg:5000/odf4"]
      },
      {
        "source": "registry.redhat.io/openshift-serverless-1",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-serverless-1"]
      },
      {
        "source": "registry.redhat.io/rhmtc",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhmtc"]
      },
      {
        "source": "registry.redhat.io/openshift-update-service",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-update-service"]
      }
    ]
  }
]
'
```

### HostedCluster 添加 
```
### 在 Management Cluster namespace jwang-hcp-demo 下添加包含帐号口令的 secret
oc create secret generic htpass-secret --from-file=htpasswd=/root/ocp4/htpasswd -n jwang-hcp-demo
### 编辑 HostedCluster 添加
spec:
  configuration:
    oauth:
      identityProviders:
      - htpasswd:
          fileData:
            name: htpass-secret
        name: htpass
        type: HTPasswd

### 可以用命令完成上述配置
oc patch hostedcluster jwang-cnv-hcp \
  -n clusters \
  --type=merge \
  -p '{
    "spec": {
      "configuration": {
        "oauth": {
          "identityProviders": [
            {
              "htpasswd": {
                "fileData": {
                  "name": "htpass-secret"
                }
              },
              "name": "htpass",
              "type": "HTPasswd"
            }
          ]
        }
      }
    }
  }'

### 在 HostedCluster 里为用户添加 clusterrole/role
oc --kubeconfig=/root/Downloads/kubeconfig adm policy add-cluster-role-to-user admin admin
oc --kubeconfig=/root/Downloads/kubeconfig adm policy add-cluster-role-to-user cluster-admin admin
oc --kubeconfig=/root/Downloads/kubeconfig adm policy add-role-to-user self-provisioner user01
oc --kubeconfig=/root/Downloads/kubeconfig adm policy add-role-to-user self-provisioner user02
```

### 离线环境HostedCluster禁用DefaultSources
```
oc -n jwang-hcp-demo patch hostedcluster jwang-hcp-demo \
  --type='json' \
  --patch '
[
  {
    "op": "add",
    "path": "/spec/configuration/operatorhub",
    "value": {
      "disableAllDefaultSources": true
    }
  }
]
'
```

### 替换HostedCluster的spec.imageContentSources
```
oc -n jwang-hcp-demo patch hostedcluster jwang-hcp-demo \
  --type=json \
  --patch '
[
  {
    "op": "replace",
    "path": "/spec/imageContentSources",
    "value": [
      {
        "source": "quay.io/openshift-release-dev/ocp-v4.0-art-dev",
        "mirrors": ["helper.ocp.ap.vwg:5000/ocp4/openshift4"]
      },
      {
        "source": "quay.io/openshift-release-dev/ocp-release",
        "mirrors": ["helper.ocp.ap.vwg:5000/ocp4/openshift4"]
      },
      {
        "source": "registry.redhat.io/devworkspace",
        "mirrors": ["helper.ocp.ap.vwg:5000/devworkspace"]
      },
      {
        "source": "registry.redhat.io/workload-availability",
        "mirrors": ["helper.ocp.ap.vwg:5000/workload-availability"]
      },
      {
        "source": "registry.redhat.io/openshift-logging",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-logging"]
      },
      {
        "source": "registry.redhat.io/rhacm2",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhacm2"]
      },
      {
        "source": "registry.redhat.io/multicluster-engine",
        "mirrors": ["helper.ocp.ap.vwg:5000/multicluster-engine"]
      },
      {
        "source": "registry.redhat.io/openshift4",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift4"]
      },
      {
        "source": "registry.redhat.io/source-to-image",
        "mirrors": ["helper.ocp.ap.vwg:5000/source-to-image"]
      },
      {
        "source": "registry.redhat.io/rhel9",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhel9"]
      },
      {
        "source": "registry.redhat.io/rhel8",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhel8"]
      },
      {
        "source": "registry.redhat.io/ubi8",
        "mirrors": ["helper.ocp.ap.vwg:5000/ubi8"]
      },
      {
        "source": "registry.redhat.io/ansible-automation-platform-25",
        "mirrors": ["helper.ocp.ap.vwg:5000/ansible-automation-platform-25"]
      },
      {
        "source": "registry.redhat.io/rhceph",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhceph"]
      },
      {
        "source": "registry.redhat.io/oadp",
        "mirrors": ["helper.ocp.ap.vwg:5000/oadp"]
      },
      {
        "source": "registry.redhat.io/advanced-cluster-security",
        "mirrors": ["helper.ocp.ap.vwg:5000/advanced-cluster-security"]
      },
      {
        "source": "registry.redhat.io/openshift-update-service",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-update-service"]
      },
      {
        "source": "registry.redhat.io/ansible-automation-platform",
        "mirrors": ["helper.ocp.ap.vwg:5000/ansible-automation-platform"]
      },
      {
        "source": "registry.redhat.io/web-terminal",
        "mirrors": ["helper.ocp.ap.vwg:5000/web-terminal"]
      },
      {
        "source": "registry.redhat.io/openshift-gitops-1",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-gitops-1"]
      },
      {
        "source": "registry.redhat.io/lvms4",
        "mirrors": ["helper.ocp.ap.vwg:5000/lvms4"]
      },
      {
        "source": "registry.redhat.io/rh-sso-7",
        "mirrors": ["helper.ocp.ap.vwg:5000/rh-sso-7"]
      },
      {
        "source": "registry.redhat.io/ubi8-minimal",
        "mirrors": ["helper.ocp.ap.vwg:5000/ubi8-minimal"]
      },
      {
        "source": "registry.redhat.io/migration-toolkit-virtualization",
        "mirrors": ["helper.ocp.ap.vwg:5000/migration-toolkit-virtualization"]
      },
      {
        "source": "registry.redhat.io/openshift-pipelines",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-pipelines"]
      },
      {
        "source": "registry.redhat.io/container-native-virtualization",
        "mirrors": ["helper.ocp.ap.vwg:5000/container-native-virtualization"]
      },
      {
        "source": "registry.redhat.io/odf4",
        "mirrors": ["helper.ocp.ap.vwg:5000/odf4"]
      },
      {
        "source": "registry.redhat.io/openshift-serverless-1",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-serverless-1"]
      },
      {
        "source": "registry.redhat.io/rhmtc",
        "mirrors": ["helper.ocp.ap.vwg:5000/rhmtc"]
      },
      {
        "source": "registry.redhat.io/openshift-update-service",
        "mirrors": ["helper.ocp.ap.vwg:5000/openshift-update-service"]
      }
    ]
  }
]
'
```

### 设置 OADP
```
oc extract secret/vm-backups -n openshift-adp --keys=AWS_ACCESS_KEY_ID --to=-
oc extract secret/vm-backups -n openshift-adp --keys=AWS_SECRET_ACCESS_KEY --to=-

创建文件 credentials-velero 
cat <<EOF > credentials-velero
[default]
aws_access_key_id=<AWS_ACCESS_KEY_ID>
aws_secret_access_key=<AWS_SECRET_ACCESS_KEY>
EOF


```

### win10 如何启用远程桌面
https://guanjia.qq.com/knowledge-base/content/1390?from=clinic


### 生成uattend.xml的网址 - Windows Answer File Generator
https://windowsafg.com/server2016.html

```
%WINDIR%\System32\Sysprep\sysprep.exe /generalize /shutdown /oobe /mode:vm
```

### 获取Windows SID
```
wmic useraccount where name='%username%' get sid
```

### RHEL8 配置SMB/CIFS共享的简易流程
```
dnf install -y samba samba-client
systemctl enable --now smb nmb

cat <<EOF > /etc/samba/smb.conf 
[global]
    workgroup = WORKGROUP
    server string = Samba Server
    security = user
    map to guest = bad user
    guest account = nobody
    log file = /var/log/samba/log.%m
    max log size = 50

[SecureShare]
    comment = Secure User Share
    path = /samba/share
    valid users = @smbusers
    browseable = yes
    writable = yes
    create mask = 0664
    directory mask = 0775
EOF

sudo groupadd smbusers
sudo useradd -G smbusers user1
sudo smbpasswd -a user1

sudo mkdir -p /samba/share
sudo chmod -R 2775 /samba/share
sudo chown -R nobody:nobody /samba/share

sudo setsebool -P samba_export_all_rw=1
sudo semanage fcontext -a -t samba_share_t "/samba(/.*)?"
sudo restorecon -Rv /samba

sudo firewall-cmd --permanent --add-service=samba
sudo firewall-cmd --reload

smbclient //<server_ip_address>/SecureShare -U user1
net use Z: \\<server_ip_address>\SecureShare /user:user1
```

### 下载 hypershift cli 
https://github.com/openshift/release/blob/b4128007922810f00c92f506fb7808ca70237805/ci-operator/step-registry/hypershift/mce/dump/hypershift-mce-dump-commands.sh#L9-L30
```
downURL=$(oc get ConsoleCLIDownload hcp-cli-download -o json | jq -r '.spec.links[] | select(.text | test("Linux for x86_64")).href') && curl -k --output /tmp/hypershift.tar.gz ${downURL}
cd /tmp && tar -xvf /tmp/hypershift.tar.gz
chmod +x /tmp/hcp
HCP_CLI="/tmp/hcp"
```

### 包含ibstat的工具
```
quay.io/bschmaus/gpu-operator:tools
```

### 检查 konnectivity 是否正常工作的脚本
https://hypershift-docs.netlify.app/reference/konnectivity/#testing-the-konnectivity-server-with-curl
```
cat <<'EOF' > test-konnectivity.sh
#!/bin/bash

set -euo pipefail

workdir="$(mktemp -d)"
cp_namespace="jwang-hcp-demo-jwang-hcp-demo"

echo "work directory is: ${workdir}"

# Get the cert/CA required to use the konnectivity server as a proxy
oc get secret konnectivity-client -n ${cp_namespace} -o jsonpath='{ .data.tls\.key }' | base64 -d > "${workdir}/client.key"
oc get secret konnectivity-client -n ${cp_namespace} -o jsonpath='{ .data.tls\.crt }' | base64 -d > "${workdir}/client.crt"
oc get cm konnectivity-ca-bundle -n ${cp_namespace} -o jsonpath='{ .data.ca\.crt }' > "${workdir}/konnectivity_ca.crt"

# Get the cert/CA required to access the kubelet endpoint
oc get cm kubelet-client-ca -n ${cp_namespace} -o jsonpath='{ .data.ca\.crt }' > ${workdir}/kubelet_ca.crt
oc get secret kas-kubelet-client-crt -n ${cp_namespace} -o jsonpath='{ .data.tls\.crt }' | base64 -d > ${workdir}/kubelet_client.crt
oc get secret kas-kubelet-client-crt -n ${cp_namespace} -o jsonpath='{ .data.tls\.key }' | base64 -d > ${workdir}/kubelet_client.key

# Obtain a node IP from local machines
nodeip="$(oc get agentmachines -n ${cp_namespace} -o json | jq -r '.items[0].status.addresses[] | select(.type=="ExternalIP") | .address')"

# Forward the konnectivity server endpdoint to the local machine
oc port-forward -n ${cp_namespace} svc/konnectivity-server-local 8090:8090 &

# Allow some time for the port-forwarding to start
sleep 2

# Perform the curl command with the localhost konnectivity endpoint
curl -x "https://127.0.0.1:8090" \
  --proxy-cacert ${workdir}/konnectivity_ca.crt \
  --proxy-cert ${workdir}/client.crt \
  --proxy-key ${workdir}/client.key \
  --cacert ${workdir}/kubelet_ca.crt \
  --cert ${workdir}/kubelet_client.crt \
  --key ${workdir}/kubelet_client.key \
  "https://${nodeip}:10250/metrics"

# Kill the port-forward job
kill %1
EOF
```

### HyperShift hosted clusters, konnectivity is used via a socks or https proxy
```
### openshift-apiserver
### Communicates with webhook services for resources served by the OpenShift APIServer
### Routes ImageStream connection to remote registries through the data plane.
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=openshift-apiserver -o name) -o json | jq -r '.spec.containers[] | select (.name=="konnectivity-proxy") | .command' 
[
  "/usr/bin/control-plane-operator",
  "konnectivity-https-proxy"
]
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=openshift-apiserver -o name) -o json | jq -r '.spec.containers[] | select (.name=="konnectivity-proxy") | .args' 
[
  "run"
]

### ingress-operator
### Uses konnectivity for route health checks (routes in data plane are not necessarily accessible from the control plane)
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=ingress-operator -o name) -o json | jq -r '.spec.containers[] | select (.name=="konnectivity-proxy") | .command'
[
  "/usr/bin/control-plane-operator",
  "konnectivity-https-proxy"
]
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=ingress-operator -o name) -o json | jq -r '.spec.containers[] | select (.name=="konnectivity-proxy") | .args'
[
  "run",
  "--connect-directly-to-cloud-apis"
]

### OAuth Server
### Enables communication with identity providers that potentially are only available to the data plane network.
### http-proxy
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=oauth-openshift -o name) -o json | jq -r '.spec.containers[] | select (.name=="http-proxy") | .command'
[
  "/usr/bin/control-plane-operator",
  "konnectivity-https-proxy"
]
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=oauth-openshift -o name) -o json | jq -r '.spec.containers[] | select (.name=="http-proxy") | .args'
[
  "run",
  "--serving-port=8092"
]
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=oauth-openshift -o name) -o json | jq -r '.spec.containers[] | select (.name=="socks5-proxy") | .command'

### socks5-proxy
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=oauth-openshift -o name) -o json | jq -r '.spec.containers[] | select (.name=="socks5-proxy") | .command'
[
  "/usr/bin/control-plane-operator",
  "konnectivity-socks5-proxy"
]
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=oauth-openshift -o name) -o json | jq -r '.spec.containers[] | select (.name=="socks5-proxy") | .args'
[
  "run",
  "--resolve-from-guest-cluster-dns=true",
  "--resolve-from-management-cluster-dns=true"
]

### cluster-network-operator
### Performs proxy readiness requests through the data plane network
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=cluster-network-operator -o name) -o json | jq -r '.spec.containers[] | select (.name=="konnectivity-proxy") | .command'
[
  "/usr/bin/control-plane-operator",
  "konnectivity-socks5-proxy",
  "--disable-resolver"
]
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=cluster-network-operator -o name) -o json | jq -r '.spec.containers[] | select (.name=="konnectivity-proxy") | .args'
[
  "run"
]

### OVNKube Control Plane
### Used to enable OVN interconnect for hosted clusters
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=ovnkube-control-plane -o name) -o json | jq -r '.spec.containers[] | select (.name=="socks-proxy") | .command'
[
  "/usr/bin/control-plane-operator",
  "konnectivity-socks5-proxy"
]
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=ovnkube-control-plane -o name) -o json | jq -r '.spec.containers[] | select (.name=="socks-proxy") | .args'
[
  "run"
]

### OLM Operator
### Used for GRPC communication with in-cluster catalogs
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=olm-operator -o name) -o json | jq -r '.spec.containers[] | select (.name=="socks5-proxy") | .command'
[
  "/usr/bin/control-plane-operator",
  "konnectivity-socks5-proxy"
]
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=olm-operator -o name) -o json | jq -r '.spec.containers[] | select (.name=="socks5-proxy") | .args'
[
  "run"
]

### app: kube-apiserver
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=kube-apiserver -o name) -o json | jq -r '.spec.containers[] | select (.name=="konnectivity-server") | .command'
[
  "/usr/bin/proxy-server"
]
oc -n jwang-hcp-demo-jwang-hcp-demo get $(oc get pods -n jwang-hcp-demo-jwang-hcp-demo -l app=kube-apiserver -o name) -o json | jq -r '.spec.containers[] | select (.name=="konnectivity-server") | .args'
[
  "--logtostderr=true",
  "--log-file-max-size=0",
  "--cluster-cert",
  "/etc/konnectivity/cluster/tls.crt",
  "--cluster-key",
  "/etc/konnectivity/cluster/tls.key",
  "--server-cert",
  "/etc/konnectivity/server/tls.crt",
  "--server-key",
  "/etc/konnectivity/server/tls.key",
  "--server-ca-cert",
  "/etc/konnectivity/ca/ca.crt",
  "--server-port",
  "8090",
  "--agent-port",
  "8091",
  "--health-port",
  "2041",
  "--admin-port=8093",
  "--mode=http-connect",
  "--proxy-strategies=destHost,defaultRoute",
  "--keepalive-time",
  "30s",
  "--frontend-keepalive-time",
  "30s",
  "--server-count",
  "1",
  "--cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256"
]

### OLM Catalog Operator
### Used for GRPC communication with in-cluster catalogs

### OLM Package Server
### Used for GRPC communication with in-cluster catalogs

```

### metallb L2Advertisement 的 nodeSelectors
```
### 修改L2Advertisement的nodeSelector
oc patch L2Advertisement l2-adv-jwang -n metallb-system \
  --type='json' \
  -p '[{
    "op": "replace",
    "path": "/spec/nodeSelectors",
    "value": [
      {
        "matchLabels": {
          "kubernetes.io/hostname": "worker2.ocp.ap.vwg"
        }
      }
    ]
}]'

### 为L2Advertisement添加nodeSelectors
oc patch L2Advertisement l2-adv-jwang -n metallb-system \
  --type='json' \
  -p '[{
    "op": "add",
    "path": "/spec/nodeSelectors",
    "value": [
      {
        "matchLabels": {
          "kubernetes.io/hostname": "worker1.ocp.ap.vwg"
        }
      }
    ]
}]'

### 抓包 - 指定源主机地址和协议s
tcpdump -i enp1s0 -n -nn src host 10.120.88.141 and icmp

```

### 更新HyperShift Cluster
```
### 更新HostedCluster spec.release.image
oc get HostedCluster jwang-hcp-demo -o json | jq -r '.spec.release.image="helper.ocp.ap.vwg:5000/ocp4/openshift4:4.16.37-x86_64"' | oc apply -f -

### 更新NodePool spec.release.image
oc get NodePool nodepool-jwang-hcp-demo-1 -n jwang-hcp-demo -o json | jq -r '.spec.release.image="helper.ocp.ap.vwg:5000/ocp4/openshift4:4.16.37-x86_64"' | oc apply -f -
```

### 检查 hypershift 的 commit id
```
### 检查 hypershift 的 commit id
oc logs -n hypershift -lapp=operator --tail=-1 -c operator | head -1 | jq
{
  "level": "info",
  "ts": "2025-04-08T06:31:19Z",
  "logger": "setup",
  "msg": "Starting hypershift-operator-manager",
  "version": "openshift/hypershift: b1be2a651f26e755fd37f631273a74876a8a3893. Latest supported OCP: 4.18.0"
}
### 最高支持 4.18.0
https://github.com/openshift/hypershift/commit/b1be2a651f26e755fd37f631273a74876a8a3893

### 查询 OpenShift Release Date
https://amd64.ocp.releases.ci.openshift.org/releasestream/4-stable
```

### 设置hostpath-provisioner为虚拟机提供所需磁盘
```
---
apiVersion: hostpathprovisioner.kubevirt.io/v1beta1
kind: HostPathProvisioner
metadata:
  name: hostpath-provisioner
spec:
  imagePullPolicy: IfNotPresent
  storagePools:
  - name: local
    path: /var/hpvolumes
  workload:
    nodeSelector:
      kubernetes.io/os: linux

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hostpath-csi
provisioner: kubevirt.io.hostpath-provisioner
reclaimPolicy: Delete 
volumeBindingMode: WaitForFirstConsumer 
parameters:
  storagePool: local
```

### 改变 nfs pvc 的 owner 和 group 为 qemu
```
oc get vm -A | grep -Ev NAMESPACE | awk '{print $1" "$2}' | while read namespace vm ; do echo $namespace-$vm; done | while read i ; do ls -1 /data/ocp-cluster/ocp/nfs/userfile | grep -q $i ; if [ $? -eq 0 ]; then echo chown 107:107 -R /data/ocp-cluster/ocp/nfs/userfile/$(ls -1 /data/ocp-cluster/ocp/nfs/userfile | grep $i) ; fi;  done
```

### local docker distribution registry
```
mkdir -p /data/registry/conf
cat <<EOF > /data/registry/conf/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
  delete:
    enabled: true
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

cat <<EOF > /usr/local/bin/localregistry.sh 
#!/bin/bash
podman run --name poc-registry -d -p 5000:5000 \
-v /data/registry/conf:/etc/docker/registry:z \
-v /data/registry/data:/var/lib/registry:z \
-v /data/registry/auth:/auth:z \
-e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry" \
-e "REGISTRY_HTTP_SECRET=ALongRandomSecretForRegistry" \
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
-v /data/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/registry.key \
docker.io/library/registry:2 
EOF
```

### 清理 docker registry 里的镜像
```
### OCP cleanup
CLEANUP_REGISTRY_DOMAIN='helper.ocp.ap.vwg:5000'
CLEANUP_REGISTRY_DIR='/data/registry/data'
CLEANUP_REGISTRY_REPO='ocp4/openshift4'
CLEANUP_OCP_VER='4.16.37'

ls -1F ${CLEANUP_REGISTRY_DIR}/docker/registry/v2/repositories/${CLEANUP_REGISTRY_REPO}/_manifests/tags| grep ${CLEANUP_OCP_VER} | while read i ;do cat ${CLEANUP_REGISTRY_DIR}/docker/registry/v2/repositories/${CLEANUP_REGISTRY_REPO}/_manifests/tags/$i/current/link ; echo ;done | while read sha256 ; do curl -u 'openshift:redhat' -X DELETE https://${CLEANUP_REGISTRY_DOMAIN}/v2/${CLEANUP_REGISTRY_REPO}/manifests/$sha256; done

podman exec -it $(podman ps | grep poc-registry | awk '{print $1}') bin/registry garbage-collect /etc/docker/registry/config.yml

### cleanup operator image from docker image
CLEANUP_REGISTRY_DOMAIN='helper.ocp.ap.vwg:5000'
CLEANUP_REGISTRY_DIR='/data/registry/data'
CLEANUP_REGISTRY_REPO_PART1='migration-toolkit-virtualization'

ls -1F ${CLEANUP_REGISTRY_DIR}/docker/registry/v2/repositories/${CLEANUP_REGISTRY_REPO_PART1} | while read CLEANUP_REGISTRY_REPO_PART2 ; do ls -1F ${CLEANUP_REGISTRY_DIR}/docker/registry/v2/repositories/${CLEANUP_REGISTRY_REPO_PART1}/${CLEANUP_REGISTRY_REPO_PART2}/_manifests/tags | while read i ;do cat ${CLEANUP_REGISTRY_DIR}/docker/registry/v2/repositories/${CLEANUP_REGISTRY_REPO_PART1}/${CLEANUP_REGISTRY_REPO_PART2}/_manifests/tags/$i/current/link ; echo ;done | while read sha256 ; do curl -u 'openshift:redhat' -X DELETE https://${CLEANUP_REGISTRY_DOMAIN}/v2/${CLEANUP_REGISTRY_REPO_PART1}/${CLEANUP_REGISTRY_REPO_PART2}manifests/$sha256; done ; done

podman exec -it $(podman ps | grep poc-registry | awk '{print $1}') bin/registry garbage-collect /etc/docker/registry/config.yml
```

### cleanup outdate digests
https://gist.github.com/gbougeard/48e190f931653f99aaea668dd03759ef?permalink_comment_id=3029991#gistcomment-3029991
```
#!/bin/bash

function help() {
  cat << EOF
Usage: $(basename $0) [OPTION] REGISTRY_PATH
Find the images with outdated digests in the docker registry stored in ROOT_PATH

Available options:
  -h Display help
  -c Show the command to be run to remove the outdated digests.

Warning, be sure that you know what you are doing before remove anything. Check https://gbougeard.github.io/blog.english/2017/05/20/How-to-clean-a-docker-registry-v2.html
EOF
}

function get_repositories() {
    local registry_path=$1
    find $registry_path/repositories -type d -name _manifests
}

function get_images() {
    local repository=$1
    for tag in $(ls $repository/tags);do
        echo $repository/tags/$tag
    done
}

function get_indexes() {
    local image=$1
    ls -1 $image/index/sha256
}

function get_sha() {
    local image=$1
    cat $image/current/link | sed 's/sha256://'
}

function get_outdated_indexes() {
    local image=$1
    get_indexes $image | grep -v $(get_sha $image)
}

function number_outdated_indexes() {
    local image=$1
    get_outdated_indexes $image|wc -l
}

function has_outdated_digests() {
    local image=$1
    [ "$(number_outdated_indexes $image)" != "0" ]
}


show_commands=false
while getopts ':hc' option;do
    case "$option" in
        h) help
           exit
           ;;
        c) show_commands=true
    esac
done
shift $((OPTIND-1))

if [ "$#" -ne 1 ];then
    >&2 echo "Invalid number of parameters!"
    help
    exit 1
fi

registry_path="$1/docker/registry/v2"
if [ ! -d $registry_path ];then
    >&2 echo "Invalid registry path!"
    help
    exit 1
fi

for repository in $(get_repositories $registry_path);do
    for image in $(get_images $repository);do
        if has_outdated_digests $image ;then
            if [ "$show_commands" = true ]; then
                for hash in $(get_outdated_indexes $image);do
                    echo "rm -rf $image/index/sha256/$hash $repository/revisions/sha256/$hash"
                done
            else
                echo "There are $(number_outdated_indexes $image) outdated index for $image"
            fi
        fi
    done
done
```

### 清理 migration-toolkit-virtualization 占用的空间
```
### 清理 migration-toolkit-virtualization 占用的空间
podman exec -it $(podman ps | grep poc-registry | awk '{print $1}') rm -rf /var/lib/registry/docker/registry/v2/repositories/migration-toolkit-virtualization
podman exec -it $(podman ps | grep poc-registry | awk '{print $1}') bin/registry garbage-collect /etc/docker/registry/config.yml
```

### mirror operator to disconnected env
```
#!/bin/bash

CATALOG='registry.redhat.io/redhat/redhat-operator-index:v4.18'

for packagename in serverless-operator servicemeshoperator3
do
output=$(/usr/local/bin/oc-mirror list operators --catalog=$CATALOG --package=${packagename})
echo $output

package_name=$packagename
echo "package_name is $package_name"

default_channel=$(echo "$output" | awk 'NR==2 {print $NF}')
echo "default_channel is $default_channel"

latest_version=$(echo "$output" | grep $default_channel | tail -1 | awk '{print $NF}' | sed -e "s|^[^.]*\.||")

echo "Latest version in default channel: $latest_version"

cat > ./image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: $CATALOG
      targetCatalog: ${package_name}-$(date +"%Y%m%d")
      packages:
        - name: $package_name
          channels:
            - name: $default_channel
              minVersion: $latest_version
              maxVersion: $latest_version
EOF

rm -rf output-dir
cat ./image-config-realse-local.yaml
/usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir 2>&1 | tee /tmp/${package_name}-$(date +"%Y%m%d").log

if [ $? -eq 0 ]; then
  mv -f ./output-dir/mirror_seq1_000000.tar /var/www/html/${package_name}-$(date +"%Y%m%d")-mirror_seq1_000000.tar
fi

done
```

### 离线 csi-driver-nfs 
```

### 离线 csi-driver-nfs 镜像
mkdir -p /tmp/csi-driver-nfs/livenessprobe
mkdir -p /tmp/csi-driver-nfs/csi-node-driver-registrar
mkdir -p /tmp/csi-driver-nfs/nfsplugin
mkdir -p /tmp/csi-driver-nfs/csi-provisioner
mkdir -p /tmp/csi-driver-nfs/csi-resizer
mkdir -p /tmp/csi-driver-nfs/csi-snapshotter
mkdir -p /tmp/csi-driver-nfs/snapshot-controller

skopeo copy --format v2s2 --all docker://registry.k8s.io/sig-storage/livenessprobe:v2.15.0  dir:/tmp/csi-driver-nfs/livenessprobe
skopeo copy --format v2s2 --all docker://registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0  dir:/tmp/csi-driver-nfs/csi-node-driver-registrar
skopeo copy --format v2s2 --all docker://registry.k8s.io/sig-storage/nfsplugin:v4.11.0 dir:/tmp/csi-driver-nfs/nfsplugin
skopeo copy --format v2s2 --all docker://registry.k8s.io/sig-storage/csi-provisioner:v5.2.0 dir:/tmp/csi-driver-nfs/csi-provisioner
skopeo copy --format v2s2 --all docker://registry.k8s.io/sig-storage/csi-resizer:v1.13.1 dir:/tmp/csi-driver-nfs/csi-resizer
skopeo copy --format v2s2 --all docker://registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0 dir:/tmp/csi-driver-nfs/csi-snapshotter
skopeo copy --format v2s2 --all docker://registry.k8s.io/sig-storage/snapshot-controller:v8.2.0 dir:/tmp/csi-driver-nfs/snapshot-controller


skopeo copy --format v2s2 --all dir:/tmp/csi-driver-nfs/livenessprobe docker://helper.ocp.ap.vwg:5000/sig-storage/livenessprobe:v2.15.0
skopeo copy --format v2s2 --all dir:/tmp/csi-driver-nfs/csi-node-driver-registrar docker://helper.ocp.ap.vwg:5000/sig-storage/csi-node-driver-registrar:v2.13.0
skopeo copy --format v2s2 --all dir:/tmp/csi-driver-nfs/nfsplugin docker://helper.ocp.ap.vwg:5000/sig-storage/nfsplugin:v4.11.0
skopeo copy --format v2s2 --all dir:/tmp/csi-driver-nfs/csi-provisioner docker://helper.ocp.ap.vwg:5000/sig-storage/csi-provisioner:v5.2.0
skopeo copy --format v2s2 --all dir:/tmp/csi-driver-nfs/csi-resizer docker://helper.ocp.ap.vwg:5000/sig-storage/csi-resizer:v1.13.1
skopeo copy --format v2s2 --all dir:/tmp/csi-driver-nfs/csi-snapshotter docker://helper.ocp.ap.vwg:5000/sig-storage/csi-snapshotter:v8.2.0
skopeo copy --format v2s2 --all dir:/tmp/csi-driver-nfs/snapshot-controller docker://helper.ocp.ap.vwg:5000/sig-storage/snapshot-controller:v8.2.0

```

### enabel nested virt in ocp
https://access.redhat.com/solutions/6692341
```
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 80-enable-nested-virt
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,b3B0aW9ucyBrdm1faW50ZWwgbmVzdGVkPTEKb3B0aW9ucyBrdm1fYW1kIG5lc3RlZD0xCg==
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/modprobe.d/kvm.conf
  osImageURL: ""
EOF
```

### 创建 HostPath Storage
```
cat <<EOF | oc apply -f -
---
apiVersion: hostpathprovisioner.kubevirt.io/v1beta1
kind: HostPathProvisioner
metadata:
  name: hostpath-provisioner
spec:
  imagePullPolicy: IfNotPresent
  storagePools:
  - name: local
    path: /var/hpvolumes
  workload:
    nodeSelector:
      kubernetes.io/os: linux

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hostpath-csi
provisioner: kubevirt.io.hostpath-provisioner
reclaimPolicy: Delete 
volumeBindingMode: WaitForFirstConsumer 
parameters:
  storagePool: local
EOF
```

### export vmdk to raw and qcow2
```
datastore -> select file 'ubuntu2404-jwang-02.vmdk' -> Download -> file ubuntu2404-jwang-02_files.zip 

ls 
...
-rw-r--r--. 1 user1 user1 32212254720 Apr 29 02:45 ubuntu2404-jwang-02-flat.vmdk
-rw-r--r--. 1 user1 user1         513 Apr 29 02:48 ubuntu2404-jwang-02.vmdk

qemu-img convert -p -f vmdk -O raw ubuntu2404-jwang-02.vmdk ubuntu2404-jwang-02.img
qemu-img convert -p -f vmdk -O qcow2 ubuntu2404-jwang-02.vmdk ubuntu2404-jwang-02.qcow2

virtctl image-upload dv ubuntu2404-jwang-02 --size 31Gi --image-path ubuntu2404-jwang-02.img --storage-class ocs-external-storagecluster-ceph-rbd --insecure --force-bind
virtctl image-upload dv ubuntu2404-jwang-03 --size 31Gi --image-path ubuntu2404-jwang-02.qcow2 --storage-class ocs-external-storagecluster-ceph-rbd --insecure --force-bind
```

### 检查哪个pod提供metallb arp响应
```
oc get pods | grep speaker | awk '{print $1}' | while read i ; do echo ; echo $i ; oc logs $i | grep 'announcing' ; done

cat <<"EOF" | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: MetalLB
metadata:
  name: metallb
  namespace: metallb-system
EOF

export API_IP=10.120.88.50

envsubst <<"EOF" | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: api-public-ip
  namespace: metallb-system
spec:
  protocol: layer2
  autoAssign: true
  addresses:
    - ${API_IP}-${API_IP}
---

apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: api-public-ip
  namespace: metallb-system
spec:
  nodeSelectors:
  - matchLabels:
      node-role.kubernetes.io/worker: ""
EOF
```

### 登录kubevirt vm节点
```
$ oc project clusters-jwang-cnv-hcp 
Now using project "clusters-jwang-cnv-hcp" on server "https://api.ocp.ap.vwg:6443".

$ oc get vmi 
NAME                           AGE   PHASE     IP             NODENAME             READY
jwang-cnv-hcp-7072ce76-q22vx   48m   Running   10.128.3.69    worker2.ocp.ap.vwg   True
jwang-cnv-hcp-7072ce76-s7z9p   48m   Running   10.129.2.133   worker1.ocp.ap.vwg   True

$ virtctl ssh core@jwang-cnv-hcp-7072ce76-q22vx -i /data/ocp-cluster/ocp/ssh-key/id_rsa

$ virtctl ssh core@jwang-cnv-hcp-7072ce76-q22vx -i /data/ocp-cluster/ocp/ssh-key/id_rsa -c journalctl > journal-jwang-cnv-hcp-7072ce76-q22cx.log
```

### 在 openshift 节点上运行 oc 命令
https://access.redhat.com/solutions/6979741
```
### How to run oc command on cluster nodes in OpenShift 4.x
oc --kubeconfig=/var/lib/kubelet/kubeconfig get nodes
```

### 不推荐的更新hypershift operator的方法
```
不推荐的更新hypershift operator的方法
oc apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: hypershift-override-images
  namespace: local-cluster
data:
  hypershift-operator: ${OVERRIDE_HO_IMAGE}
EOF
```

### 检查metallb svc layer2 
```
$ oc -n clusters-jwang-cnv-hcp describe svc kube-apiserver
...
Events:
  Type    Reason        Age                  From             Message
  ----    ------        ----                 ----             -------
  Normal  nodeAssigned  121m (x2 over 121m)  metallb-speaker  announcing from node "master1.ocp.ap.vwg" with protocol "layer2"
  Normal  nodeAssigned  14m (x7 over 137m)   metallb-speaker  announcing from node "master2.ocp.ap.vwg" with protocol "layer2"
  Normal  nodeAssigned  12m (x2 over 12m)    metallb-speaker  announcing from node "master1.ocp.ap.vwg" with protocol "layer2"
$ ping 10.120.88.50
$ arp -an 
? (10.120.88.50) at 52:54:00:78:9f:25 [ether] on ens3
$ tcpdump -nn -i ens3 arp 
15:26:43.193393 ARP, Reply 10.120.88.50 is-at 52:54:00:78:9f:25, length 46
$ arping -I ens3 10.120.88.50
ARPING 10.120.88.50 from 10.120.88.123 ens3
Unicast reply from 10.120.88.50 [52:54:00:78:9F:25]  1.605ms

```


### 更新hypershift-operator镜像和hcp客户端，创建4.18集群
```
mkdir -p /tmp/2
skopeo copy --format v2s2 --all docker://quay.io/hypershift/hypershift-operator:latest dir:/tmp/2
skopeo copy --format v2s2 --all  dir:/tmp/2 docker://helper.ocp.ap.vwg:5000/hypershift/hypershift-operator:latest

oc apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: hypershift-override-images
  namespace: local-cluster
data:
  hypershift-operator: helper.ocp.ap.vwg:5000/hypershift/hypershift-operator:latest
EOF

mkdir -p /tmp/3
cd /tmp/3
oc image extract helper.ocp.ap.vwg:5000/hypershift/hypershift-operator:latest --path=/usr/bin/hcp:.
cp hcp /usr/local/bin
chmod +x /usr/local/bin/hcp 

export CLUSTER_NAME=jwang-cnv-hcp
export PULL_SECRET="/root/pull-secret.json"
export MEM="6Gi"
export CPU="2"
export WORKER_COUNT="2"

hcp create cluster kubevirt \
--name $CLUSTER_NAME \
--ssh-key /data/ocp-cluster/ocp/ssh-key/id_rsa.pub \
--node-pool-replicas $WORKER_COUNT \
--pull-secret $PULL_SECRET \
--memory $MEM \
--cores $CPU \
--release-image=helper.ocp.ap.vwg:5000/openshift/release-images:4.18.10-x86_64 \
--service-cidr 172.16.16.0/20 \
--cluster-cidr 192.168.64.0/19 \
--image-content-sources /root/icsp.yaml \
--additional-trust-bundle /etc/pki/ca-trust/source/anchors/registry.crt \
--control-plane-availability-policy SingleReplica \
--infra-availability-policy SingleReplica \
--olm-disable-default-sources \
--olm-catalog-placement Guest \
--node-upgrade-type InPlace \
--render-sensitive \
--render > jwang-cnv-hcp.yaml
```

### 获取crictl ps 输出里的 container的名字
```
### 获取容器名字
crictl ps -o json | jq -r '.containers[].metadata.name'

### 获取容器id
crictl ps -o json | jq -r '.containers[].id'

### 获取容器名对应的容器id
crictl ps -o json | jq -r '.containers[] | select(.metadata.name == "haproxy") | .id'

### 根据容器名获取日志
crictl logs $(crictl ps -o json | jq -r '.containers[] | select (.metadata.name == "csi-driver") | .id')

### 根据容器名和状态获取日志
crictl logs $(crictl ps -a -o json | jq -r '.containers[] | select (.metadata.name == "console-operator") | select (.state == "CONTAINER_EXITED") | .id')
crictl logs $(crictl ps -a -o json | jq -r '.containers[] | select (.metadata.name == "console-operator") | select (.state == "CONTAINER_RUNNING") | .id')

```

### 获取hypershift pod日志
```
### 获取etcd-0 pod日志
oc -n clusters-jwang-cnv-hcp logs $(oc get pods -n clusters-jwang-cnv-hcp -o json | jq -r '.items[] | select (.metadata.name == "etcd-0") | .metadata.name')
```

### UserDefinedNetwork VM 测试
```
### 创建 namespace 和 UserDefinedNetwork
cat <<EOF | oc apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    k8s.ovn.org/primary-user-defined-network: ""
  name: jwang-udn-poc4
---
apiVersion: k8s.ovn.org/v1
kind: UserDefinedNetwork
metadata:
  name: jwang-udn-poc4
  namespace: jwang-udn-poc4
spec:
  layer2:
    ipam:
      lifecycle: Persistent
    role: Primary
    subnets:
    - 10.200.0.0/16
  topology: Layer2
EOF

### 创建 VirtualMachine
###           interfaces:
###           - binding:
###               name: l2bridge
###             name: nic1
###
###       networks:
###       - name: nic1
###         pod: {}
cat <<EOF | oc apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: rhel-8-jwang-01
  namespace: jwang-udn-poc4
spec:
  dataVolumeTemplates:
  - metadata:
      creationTimestamp: null
      name: dv-rhel-8-jwang-01
    spec:
      source:
        pvc:
          name: rhel-8.9-golden
          namespace: openshift-virtualization-os-images
      storage:
        resources:
          requests:
            storage: 11Gi
        storageClassName: nfs-csi
  instancetype:
    kind: virtualmachineclusterinstancetype
    name: u1.medium
  preference:
    kind: virtualmachineclusterpreference
    name: rhel.8
  runStrategy: Always
  template:
    metadata:
      creationTimestamp: null
    spec:
      architecture: amd64
      domain:
        devices:
          autoattachPodInterface: false
          disks:
          - disk:
              bus: virtio
            name: rootdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          interfaces:
          - binding:
              name: l2bridge
            name: nic1
        machine:
          type: pc-q35-rhel9.4.0
        resources: {}
      networks:
      - name: nic1
        pod: {}
      subdomain: headless
      volumes:
      - dataVolume:
          name: dv-rhel-8-jwang-01
        name: rootdisk
      - cloudInitNoCloud:
          userData: |
            #cloud-config
            chpasswd:
              expire: false
            password: redhat
            user: rhel
        name: cloudinitdisk
EOF
```