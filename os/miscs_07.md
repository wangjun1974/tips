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
  restorecon -Rv /var/www/html
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

### 禁用ipv6
https://linuxconfig.org/how-to-disable-ipv6-on-linux
```
echo 1 | sudo tee /proc/sys/net/ipv6/conf/all/disable_ipv6
```

### 启用 windows vTPM
https://blog.csdn.net/x_idea/article/details/121783299
```
https://blog.csdn.net/x_idea/article/details/121783299
```

### get vcenter ksm provider 
https://knowledge.broadcom.com/external/article/312030/unable-to-backup-native-key-provider-whe.html
```
### ssh vcenter server
ssh root@vc.ocp4.example.com

### dcli interactive shell
dcli +server https://vc.ocp4.example.com/api +skip-server-verification +interactive

### list kms providers
dcli> com vmware vcenter cryptomanager kms providers list
|----------------|------|------|
|provider        |health|type  |
|----------------|------|------|
|NKP-VCENTER-TEST|ERROR |NATIVE|
|----------------|------|------|

### export kms providers
dcli> com vmware vcenter cryptomanager kms providers export --provider NKP-VCENTER-TEST
```

### create DataSource
```
cat <<EOF | oc apply -f -
---
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataSource
metadata:
  labels:
    instancetype.kubevirt.io/default-preference: rhel.8
  name: rhel-8.10-golden
  namespace: openshift-virtualization-os-images
spec:
  source:
    pvc:
      name: rhel-8.10-golden
      namespace: openshift-virtualization-os-images
---
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataSource
metadata:
  labels:
    instancetype.kubevirt.io/default-preference: rhel.9
  name: rhel-9.4-golden
  namespace: openshift-virtualization-os-images
spec:
  source:
    pvc:
      name: rhel-9.4-golden
      namespace: openshift-virtualization-os-images
EOF
```

### BLOG: Windows 11 security and how to get there, if you want
```
BLOG: Windows 11 security and how to get there, if you want
https://techcommunity.microsoft.com/discussions/windows11/blog-windows-11-security-and-how-to-get-there-if-you-want/4358433
```

### 挂载 window 文件共享
```
net use Z: \\192.168.56.201\share 
net use Z: \\192.168.56.201\share persistent:yes
net use Z: \\192.168.56.201\share persistent:no
去掉共享
net use /persistent:no
net use Z: /delete
```

### 修改nfs权限，让无法启动的pod启动
```
### etcd-0 pod因没有权限无法启动
Events:
  Type     Reason       Age                  From               Message
  ----     ------       ----                 ----               -------
  Normal   Scheduled    9m1s                 default-scheduler  Successfully assigned clusters-jwang-hcp-demo/etcd-0 to worker2.ocp.ap.vwg
  Warning  FailedMount  46s (x12 over 9m1s)  kubelet            MountVolume.SetUp failed for volume "pvc-f62122a0-6dd9-43f4-88b0-dbe292b55cb9" : applyFSGroup failed for vol 10.120.88.123#var/nfsshare#clus
ters-jwang-hcp-demo-data-etcd-0-pvc-f62122a0-6dd9-43f4-88b0-dbe292b55cb9#pvc-f62122a0-6dd9-43f4-88b0-dbe292b55cb9#: open /var/lib/kubelet/pods/6f1adf30-a4bf-4c37-81b2-65cbe9e61a80/volumes/kubernetes.io~cs
i/pvc-f62122a0-6dd9-43f4-88b0-dbe292b55cb9/mount/data: permission denied

### 在nfs服务器上修改目录权限
[root@helper nfsshare]# ls /var/nfsshare/clusters-jwang-hcp-demo-data-etcd-0-pvc-f62122a0-6dd9-43f4-88b0-dbe292b55cb9/ -l
total 0
drwx--S---. 3 root root 20 May 23 13:45 data
### 在nfs服务器上修改目录权限
[root@helper clusters-jwang-hcp-demo-data-etcd-0-pvc-f62122a0-6dd9-43f4-88b0-dbe292b55cb9]# chmod -R 777 data/
[root@helper clusters-jwang-hcp-demo-data-etcd-0-pvc-f62122a0-6dd9-43f4-88b0-dbe292b55cb9]# ls -al
total 4
drwxrwsr-x.  3 root root   18 May 23 13:45 .
drwxrwxrwx. 11 root root 4096 May 27 16:41 ..
drwxrwsrwx.  3 root root   20 May 23 13:45 data
```

### HCP installation on kubevirt is failing in RHOCP 4
https://access.redhat.com/solutions/7111917 
```
https://access.redhat.com/solutions/7111917 
```

### hcp create cluster kubevirt 参数
```
--root-volume-storage-class  string                 The storage class to use for machines in the NodePool
--etcd-storage-class string                   The persistent volume storage class for etcd data volumes
--vm-node-selector stringToString                  A comma separated list of key=value pairs to use as the node selector for the KubeVirt VirtualMachines to be scheduled onto. (e.g. role=kubevirt,size=large) (default [])
--control-plane-availability-policy string    Availability policy for hosted cluster components. Supported options: SingleReplica, HighlyAvailable (default "HighlyAvailable")
--infra-availability-policy string            Availability policy for infrastructure services in guest cluster. Supported options: SingleReplica, HighlyAvailable
--additional-network stringArray                   Specify additional network that should be attached to the nodes, the "name" field should point to a multus network attachment definition with the format "[namespace]/[name]", it can be specified multiple times to attach to multiple networks. Supported parameters: name:string, example: "name:ns1/nad-foo
--attach-default-network                           Specify if the default pod network should be attached to the nodes, equal symbol should be used to pass boolean value: --attach-default-network=[true|false]. This can only be set if --additional-network is configured (default true)
```

### skopeo copy 时输入 src registry 和 dest registry 的用户名和密码
```
mkdir -p /tmp/ocp-v4.0-art-dev-8eb36b
skopeo copy --format v2s2 --all --src-creds $(cat /root/.docker/config.json  | jq -r '.auths."quay.io".auth' |base64 -d) docker://quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:8eb36bfb824edeaf091a039c99145721e695cabff9751412b2ff58f1351f2954  dir:/tmp/ocp-v4.0-art-dev-8eb36b
```

### 检查 hypershift 的 operator 的 commitid
```
$ oc logs -n hypershift -lapp=operator --tail=-1 -c operator | head -1 | jq
{
  "level": "info",
  "ts": "2025-06-05T03:36:39Z",
  "logger": "setup",
  "msg": "Starting hypershift-operator-manager",
  "version": "openshift/hypershift: 5337df1bbc15958173d877e70260f63ec0a25002. Latest supported OCP: 4.18.0"
}

### 获取git commit日期
$ git show 5337df1bbc15958173d877e70260f63ec0a25002 | grep Date
Date:   Fri Mar 28 19:47:02 2025 -0400
```

### 检查 events 按照时间进行排序，由旧到新
```
oc --kubeconfig=/root/jwang-hcp-demo-kubeconfig get events --sort-by='.firstTimestamp'
```

### hcp guest cluster upgrade 问题处理
```
### 离线环境hostedcluster升级遇到ingressoperator报错CanaryChecksRepetitiveFailures的处理方法
### ingressoperator报错
### 获取 canary-openshift-ingress-canary url
$ oc --kubeconfig=/root/jwang-hcp-demo-kubeconfig get co ingress -o json | jq .status.conditions[2] 
{
  "lastTransitionTime": "2025-06-04T03:10:42Z",
  "message": "The \"default\" ingress controller reports Degraded=True: DegradedConditions: One or more other status conditions indicate a degraded state: CanaryChecksSucceeding=False (CanaryChecksRepetitiveFailures: Canary route checks for the default ingress controller are failing. Last 1 error messages:\nerror sending canary HTTP request to \"canary-openshift-ingress-canary.apps.jwang-hcp-demo.apps.ocp.ap.vwg\": Get \"https://canary-openshift-ingress-canary.apps.jwang-hcp-demo.apps.ocp.ap.vwg\": Bad Gateway (x1112 over 18h31m57s))",
  "reason": "IngressDegraded",
  "status": "True",
  "type": "Degraded"
}

### 需要从 konnectivity-agent-xxxxx pod 访问一次 canary-openshift-ingress-canary url
$ oc --kubeconfig ~/jwang-hcp-demo-kubeconfig -n kube-system rsh $(oc --kubeconfig ~/jwang-hcp-demo-kubeconfig get pods -n kube-system -l app=konnectivity-agent -o name)
sh-5.1$ curl -k https://canary-openshift-ingress-canary.apps.jwang-hcp-demo.apps.ocp.ap.vwg

oc --kubeconfig ~/jwang-hcp-demo-kubeconfig -n openshift-insights rollout restart deployment insights-operator
oc --kubeconfig ~/jwang-hcp-demo-kubeconfig get co
```

### 升级 HostedCluster 和 NodePool
```
$ oc get -n clusters HostedCluster jwang-hcp-demo -o json | jq -r '.spec.release.image="helper.ocp.ap.vwg:5000/ocp4/openshift4:4.17.5-x86_64"' | oc apply -f - 

$ oc annotate hostedcluster -n clusters jwang-hcp-demo "hypershift.openshift.io/force-upgrade-to=helper.ocp.ap.vwg:5000/ocp4/openshift4:4.17.5-x86_64" --overwrite

$ oc get NodePool -n clusters jwang-hcp-demo -o json | jq -r '.spec.release.image="helper.ocp.ap.vwg:5000/ocp4/openshift4:4.17.5-x86_64"'  | oc apply -f -
```

### 设置 mongodb admin-user 口令
```
# 停止当前的 mongod 进程
sudo pkill mongod

# 以无授权模式启动（临时）
sudo mongod --noauth --dbpath /var/lib/mongo --logpath /var/log/mongodb/mongod.log --fork

# 进入 mongo shell，切换到 admin db
mongosh
use admin

# 创建 admin-user 用户
db.createUser(
  {
    user: "admin-user",
    pwd: passwordPrompt(),
    roles: [ { role: "root", db: "admin" }, "readWriteAnyDatabase" ]
 }
)

# 如果 admin-user已存在，则更新 admin-user 口令
db.updateUser("admin-user", {
  pwd: passwordPrompt()
})

# 创建用户或更新口令后，停止并正常重启
sudo pkill mongod

# 设置权限
chown -R mongod:mongod /var/log/mongodb && chown -R mongod:mongod /var/lib/mongo 

# 启动服务
systemctl start mongod

```

### 实时虚拟机配置
```
### 参见：https://access.redhat.com/articles/6994974
### 参见：https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-using-huge-pages-with-vms

### 节点添加 label node-role.kubernetes.io/worker-rt
oc label node b0-ocp4test.ocp4.example.com node-role.kubernetes.io/worker-rt=''

### 创建 MachineConfigPool worker-rt
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: worker-rt
  labels:
    machineconfiguration.openshift.io/role: worker-rt
spec:
  machineConfigSelector:
    matchExpressions:
      - {
           key: machineconfiguration.openshift.io/role,
           operator: In,
           values: [worker, worker-rt],
        }
  paused: false
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/worker-rt: ""
EOF

### 配置 PerformanceProfile
cat <<EOF | oc apply -f -
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
  name: rt
spec:
  additionalKernelArgs:
  - audit=0
  - idle=poll
  - intel_idle.max_cstate=0
  - processor.max_cstate=0
  - mce=off
  - numa=off
  - iommu=pt
  - intel_iommu=on
  - nospectre_v2
  - nopti
  - "default_hugepagesz=1G" 
  - "hugepagesz=1G"
  - "hugepages=16"
  cpu:
    isolated: 4-31
    reserved: "0-3"
  hugepages:
    defaultHugePagesSize: 1G
    pages:
    - count: 16
      node: 0
      size: 1G
  globallyDisableIrqLoadBalancing: true
  machineConfigPoolSelector:
    machineconfiguration.openshift.io/role: worker-rt
  nodeSelector:
    node-role.kubernetes.io/worker-rt: ""
  numa:
    topologyPolicy: single-numa-node
  realTimeKernel:
    enabled: true
EOF

### 编辑虚拟机
### 去掉
metadata.annotations
   vm.kubevirt.io/validations: |
      [
        {
          "name": "minimal-required-memory",
          "path": "jsonpath::.spec.domain.memory.guest",
          "rule": "integer",
          "message": "This VM requires more memory.",
          "min": 1610612736
        }
      ]

### 编辑 spec.template.spec.domain.cpu
spec.template.spec. 
     domain:
        cpu:
          cores: 1
          sockets: 3 #需要由2改为3
          threads: 1
          dedicatedCpuPlacement: true
          isolateEmulatorThread: true
          numa:
            guestMappingPassthrough : {}
        memory:
          hugepages:
            pageSize: "1Gi"
        resources: 
          requests:
            memory: "4Gi"

```

### 更新HCP集群的方法
```
### 升级控制平面
### HostedCluster
$ oc get -n clusters HostedCluster jwang-hcp-demo -o json | jq -r '.spec.release.image="helper.ocp.ap.vwg:5000/ocp4/openshift4:4.17.5-x86_64"' | oc apply -f -
$ oc annotate hostedcluster -n clusters jwang-hcp-demo "hypershift.openshift.io/force-upgrade-to=helper.ocp.ap.vwg:5000/ocp4/openshift4:4.17.5-x86_64" --overwrite

### 观察 pod ovnkube-control-plane 是否已经重启
$ oc get pod -n clusters-jwang-hcp-demo | grep ovnkube-control-plane
ovnkube-control-plane-5894fdc59d-cvdvj                3/3     Running     0          7m2s

### 获取 hcp cluster 的 canary route
$ oc --kubeconfig ~/jwang-hcp-demo-kubeconfig get route -n openshift-ingress-canary canary -o json | jq -r '.status.ingress[].host'

### 在 hcp cluster 的 kube-system/konnectivity-agent pod 里访问 canary route
### 返回 Healthcheck requested
$ oc --kubeconfig ~/jwang-hcp-demo-kubeconfig -n kube-system exec -it $(oc --kubeconfig ~/jwang-hcp-demo-kubeconfig -n kube-system get pod -l app=konnectivity-agent -o name) -- curl -k https://$(oc --kubeconfig ~/jwang-hcp-demo-kubeconfig get route -n openshift-ingress-canary canary -o json | jq -r '.status.ingress[].host')

### 观察 HostedCluster 状态正常
$ oc get HostedCluster -n clusters jwang-hcp-demo 
NAME             VERSION   KUBECONFIG                        PROGRESS    AVAILABLE   PROGRESSING   MESSAGE
jwang-hcp-demo   4.17.5    jwang-hcp-demo-admin-kubeconfig   Completed   True        False         The hosted control plane is available
$ oc --kubeconfig ~/jwang-hcp-demo-kubeconfig get co

### 升级数据平面
### NodePool
$ oc get NodePool -n clusters jwang-hcp-demo -o json | jq -r '.spec.release.image="helper.ocp.ap.vwg:5000/ocp4/openshift4:4.17.5-x86_64"'  | oc apply -f -

### 观察新节点加入
$ oc project clusters-jwang-hcp-demo
$ oc get vmi
NAME                            AGE   PHASE     IP             NODENAME             READY
jwang-hcp-demo-dae5a3ba-jnvvg   18d   Running   10.129.3.120   worker1.ocp.ap.vwg   True
jwang-hcp-demo-xszn8-vfpmj      14m   Running   10.128.2.12    worker2.ocp.ap.vwg   True

### 观察node数量及状态
$ oc --kubeconfig ~/jwang-hcp-demo-kubeconfig get node

### 最终检查升级后的版本
$ oc get nodepool -n clusters jwang-hcp-demo -o json | jq .status.version 
"4.17.5"
```

### 从 thanos-querier 查询 openshift metrics  
```
TOKEN=$(oc whoami -t)
HOST=$(oc -n openshift-monitoring get route thanos-querier -ojsonpath='{.status.ingress[].host}')
curl -k -H "Authorization: Bearer $TOKEN" https://$HOST/api/v1/label/__name__/values 
```

### 查询 HCP 节点的 Config 是否在更新中
```
oc get nodepool jwang-hcp-demo -o json | jq '.status.conditions[] | select(.type == "UpdatingConfig" and .status == "True")'
```

### HCP 集群添加 MachineConfig/KubeletConfig 的例子
```
### MachineConfig
NTP_CONF="c2VydmVyIGhlbHBlci5vY3AuYXAudndnIGlidXJzdApkcmlmdGZpbGUgL3Zhci9saWIvY2hyb255L2RyaWZ0Cm1ha2VzdGVwIDEuMCAzCnJ0Y3N5bmMKbG9nZGlyIC92YXIvbG9nL2Nocm9ueQo="
CONFIGMAP_NAME=workers-chrony-configuration
MACHINECONFIG_NAME=workers-chrony-configuration
cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${CONFIGMAP_NAME}
  namespace: clusters
data:
  config: |
    apiVersion: machineconfiguration.openshift.io/v1
    kind: MachineConfig
    metadata:
      labels:
        machineconfiguration.openshift.io/role: worker
      name: ${MACHINECONFIG_NAME}
    spec:
      config:
        ignition:
          version: 3.2.0
        storage:
          files:
          - contents:
              source: data:text/plain;charset=utf-8;base64,${NTP_CONF}
            mode: 420
            overwrite: true
            path: /etc/chrony.conf
EOF

oc get nodepool -n clusters $CLUSTER_NAME -o json | jq '.spec.config+=[{"name":"workers-chrony-configuration"}]' | oc apply -f -

### KubeletConfig
cat <<EOF > kubelet-config.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: test-custom-kubelet
spec:
  kubeletConfig:
    allowedUnsafeSysctls: 
      - "kernel.msg*"
      - "net.core.somaxconn"
EOF

oc create configmap jwang-hcp-demo-kubeletconfig -n clusters --from-file config=kubelet-config.yaml 

oc get nodepool -n clusters jwang-hcp-demo -o json | jq '.spec.config+=[{"name":"jwang-hcp-demo-kubeletconfig"}]' | oc apply -f -

oc --kubeconfig=/root/jwang-hcp-demo-kubeconfig debug node/jwang-hcp-demo-xszn8-vfpmj -- chroot /host cat /etc/kubernetes/kubelet.conf 2>&1 | grep allowedUnsafeSysctls


```

### 海光兼容性问题的临时处理方法
```
### 同事分享的临时处理cpu兼容性问题的方法
oc rsh cluster-version-operator-xxxxx
cd /release-manifests/
ls -lh 0000_50* |grep monitoring
### 监控应该在50里面
cp -a  0000_50_cluster-monitoring-operator_05-deployment.yaml  /tmp
### 然后修改 
vi /release-manifests/0000_50_cluster-monitoring-operator_05-deployment.yaml
### 再发个信号 告诉operator reload一下
kill -USR1 1
### 这个记得要在 容器里面操作

// 找到clusterersion的节点，一般是master1第一个master节点
# oc -n openshift-cluster-version get pods -o wide

// 进入master1节点
# oc debug node/master1
# chroot /host

// 找到clusterversion容器的container id
# crictl ps | grep cluster-version

// 找到挂载目录
# crictl inspect container-id | grep -E 'path.*overlay' 

// 查询挂载属性的lowerdir位置
# mount | grep /var/lib/containers/storage/overlay/4284398addffc475f208aad1a98cd15b75c0589b132c45b264816e625e24d85e/merged

// 假设lowerdir=/var/lib/containers/storage/overlay/l/KWZRWVZKK6RKJHAMNAVDZAD2GY第一个目录就是镜像的release-manifests位置，release-manifests就在里面
# ls /var/lib/containers/storage/overlay/l/KWZRWVZKK6RKJHAMNAVDZAD2GY

// 先备份release-manifest内容，vi直接修改镜像内容
# vi /var/lib/containers/storage/overlay/l/KWZRWVZKK6RKJHAMNAVDZAD2GY/release-manifests/0000_70_dns-operator_02-deployment.yaml

// 使用oc rollout restart 重启cluster-version-operator的pod，此时可以新的release-manifests可以生效了
# oc -n openshift-cluster-version rollout restart deploy/cluster-version-operator

// 还原镜像到原始状态的话 只需要删除镜像后重启pods即可。重新pull镜像可以还原release-manifests原始状态
# podman rmi d29424caa281aba6eaa0eb5c8e9b0684552bb5d2b7fd065e51f864b342da4556
oc -n openshift-cluster-version rollout restart deploy/cluster-version-operator



方案思路：
// 找到clusterersion的节点，一般是master1第一个master节点
# oc -n openshift-cluster-version get pods -o wide

// 进入master1节点
# oc debug node/master1
# chroot /host

// 找到clusterversion容器的container id
# crictl ps | grep cluster-version

// 找到挂载目录
# crictl inspect <container-id> | grep -E 'path.*overlay' 

// 查询挂载属性的lowerdir位置
# mount | grep /var/lib/containers/storage/overlay/4284398addffc475f208aad1a98cd15b75c0589b132c45b264816e625e24d85e/merged

// 假设lowerdir=/var/lib/containers/storage/overlay/l/KWZRWVZKK6RKJHAMNAVDZAD2GY第一个目录就是镜像的release-manifests位置，release-manifests就在里面
# ls /var/lib/containers/storage/overlay/l/KWZRWVZKK6RKJHAMNAVDZAD2GY

// 先备份release-manifest内容，vi直接修改镜像layered内容

# vi /var/lib/containers/storage/overlay/l/KWZRWVZKK6RKJHAMNAVDZAD2GY/release-manifests/0000_50_cluster-monitoring-operator_05-deployment.yaml

# vi /var/lib/containers/storage/overlay/l/KWZRWVZKK6RKJHAMNAVDZAD2GY/release-manifests/0000_70_dns-operator_02-deployment.yaml

# vi /var/lib/containers/storage/overlay/l/KWZRWVZKK6RKJHAMNAVDZAD2GY/release-manifests/0000_70_cluster-network-operator_03_deployment.yaml

// 注意：必须在cluster-version-operator容器里面发kill信号，不要对宿主机发送kill信号
使用给cluster-version-operator的pod发kill信号会原地重启cluster-version-operator的pod，此时可以新的release-manifests可以生效了
# oc -n openshift-cluster-version rsh cluster-version-operator-xxxxx
$ kill -HUP `pgrep -f cluster-version-operator`

// 还原镜像到原始状态的话 只需要删除镜像后重启pods即可。重新pull镜像可以还原release-manifests原始状态
# podman rmi <image-id>
# oc -n openshift-cluster-version rollout restart deploy/cluster-version-operator
```

### OCP 离线环境安装 collectl
https://access.redhat.com/solutions/6989124
```
### 标记节点
$ oc label node worker1.ocp.ap.vwg collectl=true

### 拷贝镜像到本地镜像仓库
$ tar xvf /tmp/gmeghnag-collectl.tar -C /
$ skopeo copy --format v2s2 --all dir:/tmp/gmeghnag-collectl docker://helper.ocp.ap.vwg:5000/gmeghnag/collectl:4.3.20-ubi9 

### 解压缩manifests
$ tar xvf /tmp/github-collectl.tar 

$ cd collectl

$ cp Kustomization.yaml kustomization.yml

### 编辑文件，替换本地镜像
$ vi DaemonSet.yaml
...
        image: helper.ocp.ap.vwg:5000/gmeghnag/collectl:4.3.20-ubi9

### 部署manifests
oc apply -k .

### 为 namespace 打标签
$ oc label namespace collectl pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged security.openshift.io/scc.podSecurityLabelSync=false --overwrite=true

$ oc rollout restart daemonset collectl 

### 拷贝文件
$ mkdir -p collectl_out; oc get node -l collectl=true -o name -o json | jq '.items[].metadata.name' -r | while read NODE; do oc debug node/${NODE} -q --to-namespace=openshift-etcd -- chroot host sh -c 'cd /var/log/collectl; ls *.raw.gz' | while read FILE; do oc debug node/${NODE} -q --to-namespace=openshift-etcd -- chroot host sh -c "cd /var/log/collectl; cat $FILE" > collectl_out/${FILE}; done ; done
$ ls collectl_out/ -l

### 删除文件
oc get node -o name -l collectl=true -o name | xargs -I {} oc debug {} -q --to-namespace=openshift-etcd -- chroot host sh -c 'rm -f /var/log/collectl/*'

### 删除manifests
oc delete -k . 

### 删除目录
oc get node -o name -l collectl=true -o name | xargs -I {} oc debug {} -q --to-namespace=openshift-etcd -- chroot host sh -c 'rm -rf /var/log/collectl'

### 删除标签
oc get node -o name -l collectl=true | xargs -I {} oc label {} collectl- 
```

### 检查collectl信息
https://access.redhat.com/articles/351143
```
collectl -scnD -oT --from 11:00 --thru 11:01 -p HOSTNAME-20130416-164506.raw.gz
```

### 按照时间差删除旧文件的脚本
### 扫描LOG_DIR文件夹，与当前时间差大于MAX_AGE_MINUTES的文件会被删除
```
#!/bin/bash

# Collectl log cleanup script
# Remove log files older than 5 minutes

# Configuration variables
LOG_DIR="/var/log/collectl"
MAX_AGE_MINUTES=5
DRY_RUN=false
VERBOSE=false

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help information
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Remove collectl log files older than 5 minutes from /var/log/collectl"
    echo ""
    echo "Options:"
    echo "  -d, --dir PATH        Specify collectl log directory (default: /var/log/collectl)"
    echo "  -a, --age MINUTES     Specify maximum retention time in minutes (default: 5)"
    echo "  -n, --dry-run         Show files to be deleted without actually deleting them"
    echo "  -v, --verbose         Show detailed information"
    echo "  -h, --help            Show help information"
    echo ""
    echo "Examples:"
    echo "  $0                    # Delete files older than 5 minutes"
    echo "  $0 -n                 # Preview mode, only show files to be deleted"
    echo "  $0 -a 10 -v           # Delete files older than 10 minutes with verbose output"
    echo "  $0 -d /custom/path    # Specify custom directory"
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if directory exists and is readable
check_directory() {
    if [[ ! -d "$LOG_DIR" ]]; then
        log_error "Directory does not exist: $LOG_DIR"
        exit 1
    fi
    
    if [[ ! -r "$LOG_DIR" ]]; then
        log_error "Cannot read directory: $LOG_DIR"
        exit 1
    fi
}

# Get file modification timestamp (seconds)
get_file_timestamp() {
    local file="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        stat -f %m "$file" 2>/dev/null
    else
        # Linux
        stat -c %Y "$file" 2>/dev/null
    fi
}

# Format file size
format_size() {
    local size=$1
    if [[ $size -lt 1024 ]]; then
        echo "${size}B"
    elif [[ $size -lt 1048576 ]]; then
        echo "$((size/1024))KB"
    elif [[ $size -lt 1073741824 ]]; then
        echo "$((size/1048576))MB"
    else
        echo "$((size/1073741824))GB"
    fi
}

# Format time difference
format_time_diff() {
    local diff_minutes=$1
    if [[ $diff_minutes -lt 60 ]]; then
        echo "${diff_minutes} minutes"
    elif [[ $diff_minutes -lt 1440 ]]; then
        local hours=$((diff_minutes / 60))
        local minutes=$((diff_minutes % 60))
        if [[ $minutes -eq 0 ]]; then
            echo "${hours} hours"
        else
            echo "${hours} hours ${minutes} minutes"
        fi
    else
        local days=$((diff_minutes / 1440))
        local remaining_minutes=$((diff_minutes % 1440))
        local hours=$((remaining_minutes / 60))
        local minutes=$((remaining_minutes % 60))
        if [[ $hours -eq 0 && $minutes -eq 0 ]]; then
            echo "${days} days"
        elif [[ $minutes -eq 0 ]]; then
            echo "${days} days ${hours} hours"
        else
            echo "${days} days ${hours} hours ${minutes} minutes"
        fi
    fi
}

# Main cleanup function
cleanup_files() {
    local current_time=$(date +%s)
    local max_age_seconds=$((MAX_AGE_MINUTES * 60))
    local deleted_count=0
    local deleted_size=0
    local total_files=0
    local total_size=0
    
    log_info "Starting directory scan: $LOG_DIR"
    log_info "Removing files older than $MAX_AGE_MINUTES minutes"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "Preview mode - files will not be actually deleted"
    fi
    
    echo ""
    
    # Use find command to get all files
    while IFS= read -r -d '' file; do
        # Skip directories
        [[ -f "$file" ]] || continue
        
        total_files=$((total_files + 1))
        
        # Get file information
        local file_timestamp=$(get_file_timestamp "$file")
        local file_size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null || echo 0)
        total_size=$((total_size + file_size))
        
        if [[ -z "$file_timestamp" ]]; then
            log_warning "Cannot get file timestamp: $file"
            continue
        fi
        
        # Calculate time difference
        local time_diff=$((current_time - file_timestamp))
        local time_diff_minutes=$((time_diff / 60))
        
        # Format file modification time
        local file_date
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_date=$(date -r "$file_timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
        else
            file_date=$(date -d "@$file_timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
        fi
        
        if [[ $VERBOSE == "true" ]]; then
            local age_str=$(format_time_diff $time_diff_minutes)
            local size_str=$(format_size $file_size)
            echo "Checking file: $(basename "$file") | Size: $size_str | Modified: $file_date | Age: $age_str"
        fi
        
        # Determine if file should be deleted
        if [[ $time_diff -gt $max_age_seconds ]]; then
            local age_str=$(format_time_diff $time_diff_minutes)
            local size_str=$(format_size $file_size)
            
            if [[ "$DRY_RUN" == "true" ]]; then
                echo -e "${YELLOW}[PREVIEW]${NC} Would delete: $(basename "$file") (Size: $size_str, Age: $age_str)"
            else
                if rm "$file" 2>/dev/null; then
                    echo -e "${RED}[DELETED]${NC} $(basename "$file") (Size: $size_str, Age: $age_str)"
                    deleted_count=$((deleted_count + 1))
                    deleted_size=$((deleted_size + file_size))
                else
                    log_error "Failed to delete: $file"
                fi
            fi
        fi
        
    done < <(find "$LOG_DIR" -type f -print0 2>/dev/null)
    
    # Display statistics
    echo ""
    echo "=============== STATISTICS ==============="
    echo "Scanned directory: $LOG_DIR"
    echo "Total files: $total_files"
    echo "Total file size: $(format_size $total_size)"
    echo "Retention time: $MAX_AGE_MINUTES minutes"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Preview mode: Found $deleted_count files that can be deleted"
        echo "Space that can be freed: $(format_size $deleted_size)"
    else
        echo "Files deleted: $deleted_count"
        echo "Space freed: $(format_size $deleted_size)"
    fi
    echo "=========================================="
}

# Parameter parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -a|--age)
            if [[ "$2" =~ ^[0-9]+$ ]] && [[ "$2" -gt 0 ]]; then
                MAX_AGE_MINUTES="$2"
            else
                log_error "Invalid time parameter: $2"
                exit 1
            fi
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown parameter: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main program
main() {
    echo "Collectl Log Cleanup Script"
    echo "=========================="
    
    # Check directory
    check_directory
    
    # Display current configuration
    log_info "Configuration:"
    echo "  - Log directory: $LOG_DIR"
    echo "  - Retention time: $MAX_AGE_MINUTES minutes"
    echo "  - Preview mode: $DRY_RUN"
    echo "  - Verbose output: $VERBOSE"
    echo ""
    
    # Execute cleanup
    cleanup_files
    
    log_success "Script execution completed"
}

# Run main program
main
```

### OCP 4.19 enable developer console
https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/web_console/index#enabling-developer-perspective_web-console_web-console-overview
```
oc patch console.operator.openshift.io/cluster --type='merge' -p '{"spec":{"customization":{"perspectives":[{"id":"dev","visibility":{"state":"Enabled"}}]}}}'
```

### 为新节点添加Fusion Access for SAN所需标签
```
oc label node ip-10-0-33-224.us-east-2.compute.internal scale.spectrum.ibm.com/role='storage'
```

### download dnf module nodejs:18 profile common 
```
download dnf module nodejs:18 profile common 
mkdir -p /tmp/custom-repo
dnf module install --downloadonly --downloaddir /tmp/custom-repo \
    nodejs:18/common

dnf module install --downloadonly --downloaddir /tmp/custom-repo \
    nodejs:18/development

dnf module install --downloadonly --downloaddir /tmp/custom-repo \
    nodejs:18/s2i
```

### cdi upload prime 日志
```
oc logs cdi-upload-prime-921884ec-3f2c-42c3-b037-90db76325cdb 
I0813 06:44:28.276615       1 uploadserver.go:81] Running server on 0.0.0.0:8443
I0813 06:44:35.065280       1 uploadserver.go:361] Content type header is ""
I0813 06:44:35.065330       1 data-processor.go:348] Calculating available size
I0813 06:44:35.069446       1 data-processor.go:360] Checking out file system volume size.
I0813 06:44:35.070639       1 data-processor.go:367] Request image size not empty.
I0813 06:44:35.070659       1 data-processor.go:373] Target size 34087042032.
I0813 06:44:35.070750       1 data-processor.go:247] New phase: TransferScratch
I0813 06:44:35.378197       1 util.go:96] Writing data...
2025/08/13 06:45:10 http: TLS handshake error from 172.18.4.2:36244: EOF
I0813 06:45:24.558442       1 data-processor.go:247] New phase: ValidatePause
I0813 06:45:24.558593       1 data-processor.go:253] Validating image
E0813 06:45:24.629922       1 prlimit.go:156] failed to kill the process; os: process already finished
I0813 06:45:24.630065       1 data-processor.go:247] New phase: Pause
I0813 06:45:24.630084       1 uploadserver.go:411] Returning success to caller, continue processing in background
I0813 06:45:24.630188       1 data-processor.go:158] Resuming processing at phase Convert
I0813 06:45:24.630209       1 data-processor.go:253] Validating image
E0813 06:45:24.636151       1 prlimit.go:156] failed to kill the process; os: process already finished
I0813 06:45:24.637493       1 qemu.go:115] Running qemu-img with args: [convert -t writeback -p -O raw /scratch/tmpimage /data/disk.img]
```

### 生成DataSource
```
cat <<EOF | oc apply -f -
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataSource
metadata:
  labels:
    instancetype.kubevirt.io/default-instancetype: cx1.large
    instancetype.kubevirt.io/default-preference: rhel.9
  name: rhel-9.4-golden-nfs
  namespace: openshift-virtualization-os-images
spec:
  source:
    pvc:
      name: rhel-9-4-golden-nfs
      namespace: openshift-virtualization-os-images
EOF
```

### bootc Containerfile to add the http service to firewalld 
```
FROM registry.redhat.io/rhel10/rhel-bootc:10.0
RUN dnf install -y firewalld httpd && \
  dnf clean all && \
  firewall-offline-cmd --zone=public --add-service=http && \
  systemctl enable httpd && \
  systemctl enable firewalld
ADD html /var/www/html

Build it and create a VM from it . SSH is allowed by the firewall, by default. virt-install with passt and portForward0=8022:22,portForward1=8080:80

vm$ sudo firewall-cmd --list-services
cockpit dhcpv6-client http ssh

host$ curl 127.0.0.1:8080
Misc tests of bootc images and firewalld
```

### AI 模型排名
https://artificialanalysis.ai/text-to-image
```
https://artificialanalysis.ai/text-to-image
```

### 在 3 node compat cluster 上设置 loadaware descheduler with cnv
```
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-openshift-machineconfig-master-psi-karg
spec:
  kernelArguments:
    - psi=1
EOF

### 这个 Profile 适用于虚拟机
### 需要注意节点的处理器是否一致，如果不一致虚拟机会无法迁移
cat <<EOF | oc apply -f -
apiVersion: operator.openshift.io/v1
kind: KubeDescheduler
metadata:
  name: cluster
  namespace: openshift-kube-descheduler-operator
spec:
  managementState: Managed
  deschedulingIntervalSeconds: 60
  mode: "Automatic"
  profiles:
    - DevKubeVirtRelieveAndMigrate
  profileCustomizations:
    devEnableEvictionsInBackground: true
    devEnableSoftTainter: true
    devDeviationThresholds: AsymmetricLow
    devActualUtilizationProfile: PrometheusCPUCombined
EOF

### 这个Profile不适合产生实际负载的场景，例如虚拟机
apiVersion: operator.openshift.io/v1
kind: KubeDescheduler
metadata:
  name: cluster
  namespace: openshift-kube-descheduler-operator
spec:
  managementState: Managed
  logLevel: Normal
  mode: Automatic
  operatorLogLevel: Normal
  deschedulingIntervalSeconds: 60
  profileCustomizations:
    devEnableEvictionsInBackground: true
    devLowNodeUtilizationThresholds: Medium
  profiles:
    - LongLifecycle

### 3 台虚拟机都在 m2-ocp4test.ocp4.example.com 这个节点上
$ oc get vmi 
NAME                    AGE   PHASE     IP            NODENAME                       READY
rhel9-jwang-stress-01   52m   Running   172.18.1.61   m2-ocp4test.ocp4.example.com   True
rhel9-jwang-stress-02   51m   Running   172.18.1.62   m2-ocp4test.ocp4.example.com   True
rhel9-jwang-stress-03   50m   Running   172.18.1.64   m2-ocp4test.ocp4.example.com   True

### 3 台虚拟机的 cpu 基本吃满
[root@helper-ocp4test tmp]# virtctl ssh cloud-user@rhel9-jwang-stress-01 -c 'top -b -n 1 | grep -E "^%Cpu"'
%Cpu(s): 98.2 us,  0.9 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.5 hi,  0.5 si,  0.0 st
[root@helper-ocp4test tmp]# virtctl ssh cloud-user@rhel9-jwang-stress-02 -c 'top -b -n 1 | grep -E "^%Cpu"'
%Cpu(s): 98.1 us,  1.1 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.8 hi,  0.0 si,  0.0 st
[root@helper-ocp4test tmp]# virtctl ssh cloud-user@rhel9-jwang-stress-03 -c 'top -b -n 1 | grep -E "^%Cpu"'
%Cpu(s): 98.6 us,  0.9 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.5 hi,  0.0 si,  0.0 st

### 每台虚拟机配置了12个vcpu
[root@helper-ocp4test tmp]# virtctl ssh cloud-user@rhel9-jwang-stress-01 -c 'cat /proc/cpuinfo | grep processor '
processor       : 0
processor       : 1
processor       : 2
processor       : 3
processor       : 4
processor       : 5
processor       : 6
processor       : 7
processor       : 8
processor       : 9
processor       : 10
processor       : 11

### LongLifeCycle 对节点的理解是
### 节点 m0-ocp4test.ocp4.example.com 和 m1-ocp4test.ocp4.example.com 被归类为 overutilized 的节点
### 节点 m2-ocp4test.ocp4.example.com 被归类为 appropriately utilized
### 归类的条件是
### "Criteria for a node under utilization" cpu="10.00%" memory="10.00%" pods="10.00%"
### "Criteria for a node above target utilization" cpu="30.00%" memory="30.00%" pods="30.00%"
I0826 07:38:17.306483       1 toomanyrestarts.go:116] "Processing node" node="m0-ocp4test.ocp4.example.com"
I0826 07:38:17.306789       1 toomanyrestarts.go:116] "Processing node" node="m1-ocp4test.ocp4.example.com"
I0826 07:38:17.307055       1 toomanyrestarts.go:116] "Processing node" node="m2-ocp4test.ocp4.example.com"
I0826 07:38:17.307206       1 profile.go:347] "Total number of evictions/requests" extension point="Deschedule" evictedPods=0 evictionRequests=0
I0826 07:38:17.308747       1 lownodeutilization.go:210] "Node has been classified" category="overutilized" node="m1-ocp4test.ocp4.example.com" usage={"cpu":"7183m","memory":"32639Mi","pods":"111"} usagePercentage={"cpu":18,"memory":17,"pods":44}
I0826 07:38:17.308847       1 lownodeutilization.go:210] "Node has been classified" category="overutilized" node="m0-ocp4test.ocp4.example.com" usage={"cpu":"5708m","memory":"16401Mi","pods":"83"} usagePercentage={"cpu":18,"memory":6,"pods":33}
I0826 07:38:17.308881       1 lownodeutilization.go:236] "Node is appropriately utilized" node="m2-ocp4test.ocp4.example.com" usage={"cpu":"6089m","memory":"14664Mi","pods":"42"} usagePercentage={"cpu":13,"memory":8,"pods":17}
I0826 07:38:17.308899       1 lownodeutilization.go:248] "Criteria for a node under utilization" cpu="10.00%" memory="10.00%" pods="10.00%"
I0826 07:38:17.308913       1 lownodeutilization.go:249] "Number of underutilized nodes" totalNumber=0
I0826 07:38:17.308930       1 lownodeutilization.go:250] "Criteria for a node above target utilization" cpu="30.00%" memory="30.00%" pods="30.00%"
I0826 07:38:17.308943       1 lownodeutilization.go:251] "Number of overutilized nodes" totalNumber=2
I0826 07:38:17.308955       1 lownodeutilization.go:254] "No node is underutilized, nothing to do here, you might tune your thresholds further"
I0826 07:38:17.308978       1 profile.go:376] "Total number of evictions/requests" extension point="Balance" evictedPods=0 evictionRequests=0
I0826 07:38:17.309002       1 descheduler.go:403] "Number of evictions/requests" totalEvicted=0 evictionRequests=0

### 无法迁移的原因是处理器不兼容，在处理器较新的节点上启动的虚拟机由于nodeSelector导致无法迁移到处理器较旧的节点上
$ oc describe pod virt-launcher-rhel9-jwang-stress-02-t2m4f
...
Events:
  Type     Reason            Age                   From               Message
  ----     ------            ----                  ----               -------
  Warning  FailedScheduling  4m50s                 default-scheduler  0/3 nodes are available: 1 node(s) didn't match pod anti-affinity rules, 2 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 1 No preemption victims found for incoming pod, 2 Preemption is not helpful for scheduling.
  Warning  FailedScheduling  2m14s (x2 over 4m2s)  default-scheduler  0/3 nodes are available: 1 node(s) didn't match pod anti-affinity rules, 2 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 1 No preemption victims found for incoming pod, 2 Preemption is not helpful for scheduling.

### 在我的lab环境里虚拟机启动在1台较新处理器的节点上，节点具有label"cpu-feature.node.kubevirt.io/abm": "true"
### 另外两个节点由于没有这个cpu feature导致live migration时新的virt-launcher pod无法调度

[root@helper-ocp4test tmp]# oc get pods virt-launcher-rhel9-jwang-stress-03-kj8jh -o json | jq .spec.nodeSelector  | tee /tmp/descheduler_nodeSelector.json
{ 
  "cpu-feature.node.kubevirt.io/abm": "true",
  "cpu-feature.node.kubevirt.io/amd-ssbd": "true",
  "cpu-feature.node.kubevirt.io/amd-stibp": "true",
  "cpu-feature.node.kubevirt.io/arat": "true",
  "cpu-feature.node.kubevirt.io/arch-capabilities": "true",
  "cpu-feature.node.kubevirt.io/f16c": "true",
  "cpu-feature.node.kubevirt.io/flush-l1d": "true",
  "cpu-feature.node.kubevirt.io/gds-no": "true",
  "cpu-feature.node.kubevirt.io/hypervisor": "true",
  "cpu-feature.node.kubevirt.io/ibpb": "true",
  "cpu-feature.node.kubevirt.io/ibrs": "true",
  "cpu-feature.node.kubevirt.io/invtsc": "true",
  "cpu-feature.node.kubevirt.io/md-clear": "true",
  "cpu-feature.node.kubevirt.io/pdcm": "true",
  "cpu-feature.node.kubevirt.io/pdpe1gb": "true",
  "cpu-feature.node.kubevirt.io/pschange-mc-no": "true",
  "cpu-feature.node.kubevirt.io/rdrand": "true",
  "cpu-feature.node.kubevirt.io/skip-l1dfl-vmentry": "true",
  "cpu-feature.node.kubevirt.io/ss": "true",
  "cpu-feature.node.kubevirt.io/ssbd": "true",
  "cpu-feature.node.kubevirt.io/stibp": "true",
  "cpu-feature.node.kubevirt.io/tsc_adjust": "true",
  "cpu-feature.node.kubevirt.io/umip": "true",
  "cpu-feature.node.kubevirt.io/vme": "true",
  "cpu-feature.node.kubevirt.io/vmx": "true",
  "cpu-feature.node.kubevirt.io/vmx-activity-hlt": "true",
  "cpu-feature.node.kubevirt.io/vmx-activity-wait-sipi": "true",
  "cpu-feature.node.kubevirt.io/vmx-apicv-register": "true",
  "cpu-feature.node.kubevirt.io/vmx-apicv-vid": "true",
  "cpu-feature.node.kubevirt.io/vmx-apicv-x2apic": "true",
  "cpu-feature.node.kubevirt.io/vmx-apicv-xapic": "true",
  "cpu-feature.node.kubevirt.io/vmx-cr3-load-noexit": "true",
  "cpu-feature.node.kubevirt.io/vmx-cr3-store-noexit": "true",
  "cpu-feature.node.kubevirt.io/vmx-cr8-load-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-cr8-store-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-desc-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-entry-ia32e-mode": "true",
  "cpu-feature.node.kubevirt.io/vmx-entry-load-efer": "true",
  "cpu-feature.node.kubevirt.io/vmx-entry-load-pat": "true",
  "cpu-feature.node.kubevirt.io/vmx-entry-load-perf-global-ctrl": "true",
  "cpu-feature.node.kubevirt.io/vmx-entry-noload-debugctl": "true",
  "cpu-feature.node.kubevirt.io/vmx-ept": "true",
  "cpu-feature.node.kubevirt.io/vmx-ept-1gb": "true",
  "cpu-feature.node.kubevirt.io/vmx-ept-2mb": "true",
  "cpu-feature.node.kubevirt.io/vmx-ept-execonly": "true",
  "cpu-feature.node.kubevirt.io/vmx-eptad": "true",
  "cpu-feature.node.kubevirt.io/vmx-eptp-switching": "true",
  "cpu-feature.node.kubevirt.io/vmx-exit-ack-intr": "true",
  "cpu-feature.node.kubevirt.io/vmx-exit-load-efer": "true",
  "cpu-feature.node.kubevirt.io/vmx-exit-load-pat": "true",
  "cpu-feature.node.kubevirt.io/vmx-exit-load-perf-global-ctrl": "true",
  "cpu-feature.node.kubevirt.io/vmx-exit-nosave-debugctl": "true",
  "cpu-feature.node.kubevirt.io/vmx-exit-save-efer": "true",
  "cpu-feature.node.kubevirt.io/vmx-exit-save-pat": "true",
  "cpu-feature.node.kubevirt.io/vmx-exit-save-preemption-timer": "true",
  "cpu-feature.node.kubevirt.io/vmx-flexpriority": "true",
  "cpu-feature.node.kubevirt.io/vmx-hlt-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-ins-outs": "true",
  "cpu-feature.node.kubevirt.io/vmx-intr-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-invept": "true",
  "cpu-feature.node.kubevirt.io/vmx-invept-all-context": "true",
  "cpu-feature.node.kubevirt.io/vmx-invept-single-context": "true",
  "cpu-feature.node.kubevirt.io/vmx-invlpg-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-invpcid-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-invvpid": "true",
  "cpu-feature.node.kubevirt.io/vmx-invvpid-all-context": "true",
  "cpu-feature.node.kubevirt.io/vmx-invvpid-single-addr": "true",
  "cpu-feature.node.kubevirt.io/vmx-io-bitmap": "true",
  "cpu-feature.node.kubevirt.io/vmx-io-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-monitor-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-movdr-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-msr-bitmap": "true",
  "cpu-feature.node.kubevirt.io/vmx-mtf": "true",
  "cpu-feature.node.kubevirt.io/vmx-mwait-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-nmi-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-page-walk-4": "true",
  "cpu-feature.node.kubevirt.io/vmx-pause-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-pml": "true",
  "cpu-feature.node.kubevirt.io/vmx-posted-intr": "true",
  "cpu-feature.node.kubevirt.io/vmx-preemption-timer": "true",
  "cpu-feature.node.kubevirt.io/vmx-rdpmc-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-rdrand-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-rdtsc-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-rdtscp-exit": "true",
  "cpu-feature.node.kubevirt.io/vmx-secondary-ctls": "true",
  "cpu-feature.node.kubevirt.io/vmx-shadow-vmcs": "true",
  "cpu-feature.node.kubevirt.io/vmx-store-lma": "true",
  "cpu-feature.node.kubevirt.io/vmx-true-ctls": "true",
  "cpu-feature.node.kubevirt.io/vmx-tsc-offset": "true",
  "cpu-feature.node.kubevirt.io/vmx-unrestricted-guest": "true",
  "cpu-feature.node.kubevirt.io/vmx-vintr-pending": "true",
  "cpu-feature.node.kubevirt.io/vmx-vmfunc": "true",
  "cpu-feature.node.kubevirt.io/vmx-vmwrite-vmexit-fields": "true",
  "cpu-feature.node.kubevirt.io/vmx-vnmi": "true",
  "cpu-feature.node.kubevirt.io/vmx-vnmi-pending": "true",
  "cpu-feature.node.kubevirt.io/vmx-vpid": "true",
  "cpu-feature.node.kubevirt.io/vmx-wbinvd-exit": "true",
  "cpu-feature.node.kubevirt.io/xsaveopt": "true",
  "cpu-model-migration.node.kubevirt.io/Haswell-noTSX-IBRS": "true",
  "kubernetes.io/arch": "amd64",
  "kubevirt.io/schedulable": "true"
}
```

### 下载显示下载进度条
```
mkdir -p ./models/RedHatAI/Qwen3-0.6B-FP8-dynamic
huggingface-cli download RedHatAI/Qwen3-0.6B-FP8-dynamic --local-dir ./models/RedHatAI/Qwen3-0.6B-FP8-dynamic
```

### 尝试RHAIIS
```
### 启用CDI
$ sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

### 启动vllm inference server
$ HUGGING_FACE_HUB_TOKEN=XXXXXXXX HF_HUB_OFFLINE=0 /usr/bin/podman run -it --device nvidia.com/gpu=all -p 8000:8000 \
    --ipc=host \
    --env "HUGGING_FACE_HUB_TOKEN=${HUGGING_FACE_HUB_TOKEN}" \
    --env "HF_HUB_OFFLINE=${HF_HUB_OFFLINE}" \
    -v /home/dev/.cache/vllm:/home/vllm/.cache \
    --name=rhaiis \
    registry.redhat.io/rhaiis/vllm-cuda-rhel9:3.2.0-1754088865-hotfix-1 \
    --tensor-parallel-size 1 \
    --max-model-len 8192 \
    --enforce-eager --model ibm-granite/granite-3.3-2b-instruct

### 检查模型
$ curl -s http://localhost:8000/v1/models | jq
{
  "object": "list",
  "data": [
    {
      "id": "ibm-granite/granite-3.3-2b-instruct",
      "object": "model",
      "created": 1756367377,
      "owned_by": "vllm",
      "root": "ibm-granite/granite-3.3-2b-instruct",
      "parent": null,
      "max_model_len": 8192,
      "permission": [
        {
          "id": "modelperm-555136edbe3e4a95b6de8a1bc4501610",
          "object": "model_permission",
          "created": 1756367377,
          "allow_create_engine": false,
          "allow_sampling": true,
          "allow_logprobs": true,
          "allow_search_indices": false,
          "allow_view": true,
          "allow_fine_tuning": false,
          "organization": "*",
          "group": null,
          "is_blocking": false
        }
      ]
    }
  ]
}

### 监控资源占用情况
$ nvtop

### 检查GPU驱动信息
[dev@rhaiis ~]$ nvidia-smi 
Thu Aug 28 07:52:18 2025       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.65.06              Driver Version: 580.65.06      CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA A10G                    Off |   00000000:00:1E.0 Off |                    0 |
|  0%   29C    P0             59W /  300W |   20675MiB /  23028MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A            3109      C   python3                               20666MiB |
+-----------------------------------------------------------------------------------------+

### 与模型对话
$ curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ibm-granite/granite-3.3-2b-instruct",
    "messages": [
      {
        "role": "user",
        "content": "Write me 5 to 10 paragraphs about RHEL"
      }
    ],
    "temperature": 0.7,
    "max_tokens": 1500
  }' | jq

### 用程序与模型对话
$ cat << 'EOF' > api.py
from openai import OpenAI

api_key = "XXXXXXXXXX"

model = "ibm-granite/granite-3.3-2b-instruct"
base_url = "http://localhost:8000/v1/"

client = OpenAI(
    base_url=base_url,
    api_key=api_key,
)

response = client.chat.completions.create(
    model=model,
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Why is Red Hat AI Inference Server a great fit for RHEL?"}
    ]
)
print(response.choices[0].message.content)
EOF

$ python api.py
```

### ibm fusion access troubleshooting
```
### 检查internal image registry的内容
oc exec -it -n openshift-image-registry $(oc get pod -n openshift-image-registry -l docker-registry='default' -o name) -- ls -lR /registry

### 检查ibm-fusion-access的build
oc get build -n ibm-fusion-access

```

### 运行qemu-system-aarch64创建arm64虚拟机
```
0. 安装qmeu
brew install qemu

1. 准备工作
验证QEMU安装：
qemu-system-aarch64 --version
qemu-system-aarch64 -machine help | grep virt
创建VM工作目录：
mkdir -p ~/VMs/aarch64-vm
cd ~/VMs/aarch64-vm

2. 下载必需文件
下载UEFI固件（必需）：
# 下载aarch64 UEFI固件
wget https://releases.linaro.org/components/kernel/uefi-linaro/latest/release/qemu64/QEMU_EFI.fd

#查找aarch64 UEFI固件
find /usr/local/Cellar -name "edk2*" 
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-i386-code.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-loongarch64-vars.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-riscv-vars.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-x86_64-secure-code.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-i386-vars.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-loongarch64-code.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-riscv-code.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-aarch64-code.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-arm-vars.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-i386-secure-code.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-licenses.txt
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-x86_64-code.fd
/usr/local/Cellar/qemu/10.1.0/share/qemu/edk2-arm-code.fd

下载操作系统镜像：
wget -4 https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/aarch64/iso/Fedora-Server-dvd-aarch64-42-1.1.iso

3. 创建虚拟磁盘
qemu-img create -f qcow2 vm-disk.qcow2 50G

4. 创建启动脚本
创建start-vm.sh脚本：
#!/bin/bash

VM_NAME="fedora-aarch64"
DISK_IMAGE="vm-disk.qcow2"
ISO_IMAGE="Fedora-Server-dvd-aarch64-42-1.1.iso"
UEFI_FIRMWARE="edk2-aarch64-code.fd"

QEMU_AUDIO_DRV=none qemu-system-aarch64 \
    -name "${VM_NAME}" \
    -machine virt \
    -cpu cortex-a72 \
    -m 4096 \
    -bios "${UEFI_FIRMWARE}" \
    -audio driver=none \
    -device virtio-gpu-pci \
    -device virtio-keyboard \
    -device virtio-mouse \
    -device ich9-intel-hda \
    -device hda-duplex \
    -device qemu-xhci \
    -device usb-kbd \
    -device usb-mouse \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -drive file="${DISK_IMAGE}",if=virtio,format=qcow2 \
    -cdrom "${ISO_IMAGE}" \
    -boot d \
    -nographic


```

### 更新pull secret
```
### 保存当前的pull-secret
oc get secret/pull-secret -n openshift-config -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d > current-pull-secret.json

### 添加新registry的pull-secret
REGISTRY="helper-ocp4test.ocp4.example.com:5000"
USERNAME="openshift"
PASSWORD="redhat"
EMAIL="noemail@localhost"

AUTH_STRING=$(echo -n "${USERNAME}:${PASSWORD}" | base64 -w 0)
jq --arg registry "$REGISTRY" --arg auth "$AUTH_STRING" --arg email "$EMAIL" \
  '.auths += {($registry): {"auth": $auth, "email": $email}}' \
  current-pull-secret.json > updated-pull-secret.json

### 更新cluster pull secret...
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=updated-pull-secret.json

```

###  RHEL 8 设置 iscsi target 
```
### 安装 iscsi-initiator 和 iscsi target
dnf install -y iscsi-initiator-utils
dnf install -y targetcli

### 启动 target 服务
systemctl enable --now target
systemctl status target

### 生成 disk01.img 文件
mkdir -p /var/lib/iscsi_disks
truncate -s 10G /var/lib/iscsi_disks/disk01.img
chown root:root /var/lib/iscsi_disks/disk01.img
chmod 600 /var/lib/iscsi_disks/disk01.img

### 运行 targetcli 
targetcli
/> cd backstores/fileio

### 创建 disk01 fileio backstore
/backstores/fileio> create name=disk01 file_or_dev=/var/lib/iscsi_disks/disk01.img size=10G

### 创建 target
/backstores/fileio> cd /iscsi
/iscsi> create iqn.2025-09.com.example:storage.target01

### 创建 lun
/iscsi> cd iqn.2025-09.com.example:storage.target01/tpg1/luns
/iscsi/iqn.20...t01/tpg1/luns> create /backstores/fileio/disk01

### 创建 acls
/> cd /
/> /iscsi/iqn.2025-09.com.example:storage.target01/tpg1/acls create iqn.1994-05.com.redhat:47b09045abfc
/> /iscsi/iqn.2025-09.com.example:storage.target01/tpg1/acls create iqn.1994-05.com.redhat:5d75d9f09b19
/> /iscsi/iqn.2025-09.com.example:storage.target01/tpg1/acls create iqn.1994-05.com.redhat:abc24c69d3ff
/> /iscsi/iqn.2025-09.com.example:storage.target01/tpg1/acls create iqn.1994-05.com.redhat:7444c2347684

### 保存配置
/> saveconfig
/> exit

### 配置firewall
firewall-cmd --zone=public --add-port=3260/tcp --permanent
firewall-cmd --reload

### discovery portal
iscsiadm --mode discoverydb --type sendtargets --portal 192.168.56.64 --discover
192.168.56.64:3260,1 iqn.2025-09.com.example:storage.target01

### login portal
iscsiadm --mode node --targetname iqn.2025-09.com.example:storage.target01 --portal 192.168.56.64:3260 --login
```

### 为集群启用 additionalEnabledCapabilities
https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/post-installation_configuration/enabling-cluster-capabilities
```
### 获取 cluster capabilities
oc get clusterversion version -o jsonpath='{.spec.capabilities}{"\n"}{.status.capabilities}{"\n"}'

### 为 cluster 添加 capabilities
oc patch clusterversion/version --type merge -p '{"spec":{"capabilities":{"additionalEnabledCapabilities":["Build","Console","Ingress","Storage","CSISnapshot","OperatorLifecycleManager","marketplace","NodeTuning"]}}}'

### 增加 capabilities ImageRegistry
oc patch clusterversion/version --type merge -p '{"spec":{"capabilities":{"additionalEnabledCapabilities":["Build","Console","ImageRegistry","Ingress","Storage","CSISnapshot","OperatorLifecycleManager","marketplace","NodeTuning"]}}}'
```

### 设置证书信任
```
### 生成 registry1ca
openssl s_client -connect registry.ocp4.example.com:443 2>/dev/null </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee registry1ca.crt

### 生成 registry2ca
openssl s_client -connect helper-ocp4test.ocp4.example.com:5000 2>/dev/null </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee registry2ca.crt

### 将 registry1ca 和 registry2ca 合成为 registryca.pem 
cat registry1ca.crt registry2ca.crt > registryca.pem

### 设置证书信任
oc -n openshift-config delete configmap custom-ca
oc -n openshift-config create configmap custom-ca \
  --from-file=ca-bundle.crt=registryca.pem \
  --dry-run=client -o yaml | oc apply -f -

oc get proxy/cluster -o yaml
oc patch proxy/cluster \
     --type=merge \
     --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'

### 设置证书信任
oc -n openshift-config delete configmap registry-ca
oc -n openshift-config create configmap registry-ca \
  --from-file=registry.ocp4.example.com=registry1ca.crt \
  --from-file=helper-ocp4test.ocp4.example.com..5000=registry2ca.crt \
  --dry-run=client -o yaml | oc apply -f -

oc get image.config.openshift.io/cluster -o yaml
oc patch image.config.openshift.io/cluster --type=merge -p \
'{"spec":{"additionalTrustedCA":{"name":"registry-ca"}}}'
```

### 卸载 Fusion Access for SAN
https://docs.google.com/document/d/1pOR51_5yNdrfPb_zU26Rm-aFEYBEXcUvCFVsK0wsCLU/edit?tab=t.0#heading=h.p52lw56l95hi
```

for fs in $(oc -n ibm-spectrum-scale get filesystems -o custom-columns='NAME:.metadata.name' --no-headers ); do 
oc -n ibm-spectrum-scale label filesystems ${fs} \
scale.spectrum.ibm.com/allowDelete=; 
oc -n ibm-spectrum-scale delete filesystems ${fs}; 
done

oc -n ibm-spectrum-scale get localdisks \
-o custom-columns='NAME:.metadata.name' --no-headers | xargs \
-n1 oc -n ibm-spectrum-scale delete localdisks

oc delete clusters.scale.spectrum.ibm.com ibm-spectrum-scale

oc -n ibm-fusion-access get fusionaccesses.fusion.storage.openshift.io \
-o custom-columns='NAME:.metadata.name' --no-headers | xargs \
-n1 oc -n ibm-fusion-access delete \
fusionaccesses.fusion.storage.openshift.io

oc -n ibm-spectrum-scale delete pvc --all
oc get pv -o json \
  | jq -r '.items[] | select(.spec.storageClassName=="ibm-spectrum-scale-internal") | .metadata.name' \
  | xargs oc delete pv

oc delete nodemodulesconfigs.kmm.sigs.x-k8s.io -l \
  beta.kmm.node.kubernetes.io/ibm-fusion-access.gpfs-module.module-in-use=

oc -n ibm-fusion-access delete modules.kmm.sigs.x-k8s.io --all

for i in $(seq 0 2) ;do oc debug node/m${i}-ocp4test.ocp4.example.com -q -- chroot /host rmmod mmfs26 ; done
for i in $(seq 0 2) ;do oc debug node/m${i}-ocp4test.ocp4.example.com -q -- chroot /host rmmod mmfslinux ; done
for i in $(seq 0 2) ;do oc debug node/m${i}-ocp4test.ocp4.example.com -q -- chroot /host rmmod tracedev ; done


oc delete ns ibm-fusion-access \
             ibm-spectrum-scale \
             ibm-spectrum-scale-csi \
             ibm-spectrum-scale-dns \
             ibm-spectrum-scale-operator

oc get volumesnapshotclass -o json \
  | jq -r '.items[] | select(.driver=="spectrumscale.csi.ibm.com") | .metadata.name' \
  | xargs -n1 oc delete volumesnapshotclass

oc get storageclass -o json \
  | jq -r '.items[] | select(.provisioner=="spectrumscale.csi.ibm.com") | .metadata.name' \
  | xargs -n1 oc delete storageclass

oc delete storageclass ibm-spectrum-scale-internal

oc get console.operator cluster -o json | \
jq 'del(.spec.plugins[] | select(. == "fusion-access-console"))' | \
oc replace -f -

oc delete consoleplugin fusion-access-console

oc delete crd approvalrequests.scale.spectrum.ibm.com
oc delete crd asyncreplications.scale.spectrum.ibm.com
oc delete crd cachevolumeoperations.scale.spectrum.ibm.com
oc delete crd cachevolumes.scale.spectrum.ibm.com
oc delete crd callhomes.scale.spectrum.ibm.com
oc delete crd clusterinterconnects.scale.spectrum.ibm.com
oc delete crd clusters.scale.spectrum.ibm.com
oc delete crd compressionjobs.scale.spectrum.ibm.com
oc delete crd consistencygroups.scale.spectrum.ibm.com
oc delete crd csiscaleoperators.csi.ibm.com
oc delete crd daemons.scale.spectrum.ibm.com
oc delete crd diskjobs.scale.spectrum.ibm.com
oc delete crd dnsconfigs.scale.spectrum.ibm.com
oc delete crd dnss.scale.spectrum.ibm.com
oc delete crd encryptionconfigs.scale.spectrum.ibm.com
oc delete crd filesystems.scale.spectrum.ibm.com
oc delete crd fusionaccesses.fusion.storage.openshift.io
oc delete crd grafanabridges.scale.spectrum.ibm.com
oc delete crd guis.scale.spectrum.ibm.com
oc delete crd localdisks.scale.spectrum.ibm.com
oc delete crd localvolumediscoveries.fusion.storage.openshift.io
oc delete crd localvolumediscoveryresults.fusion.storage.openshift.io
oc delete crd pmcollectors.scale.spectrum.ibm.com
oc delete crd recoverygroups.scale.spectrum.ibm.com
oc delete crd regionaldrexports.scale.spectrum.ibm.com
oc delete crd regionaldrs.scale.spectrum.ibm.com
oc delete crd remoteclusters.scale.spectrum.ibm.com
oc delete crd restripefsjobs.scale.spectrum.ibm.com
oc delete crd stretchclusterinitnodes.scale.spectrum.ibm.com
oc delete crd stretchclusters.scale.spectrum.ibm.com
oc delete crd stretchclustertiebreakers.scale.spectrum.ibm.com
oc delete crd upgradeapprovals.scale.spectrum.ibm.com
oc delete crd volumes.scale.spectrum.ibm.com

oc get nodes -l scale.spectrum.ibm.com/role=storage -o json \
| jq -r ' .items[] | .metadata.name ' \
| xargs -n1 -I {} oc debug node/{} -T -- \
chroot /host sh -c "rm -rf /var/mmfs; rm -rf /var/adm/ras"

oc get nodes -l scale.spectrum.ibm.com/role=storage -o json \
| jq -r ' .items[] | .metadata.name ' \
| xargs -n1 -I {} oc label node {} \
scale.spectrum.ibm.com/daemon- \
	scale.spectrum.ibm.com/designation- \
	scale.spectrum.ibm.com/image-digest- \
	scale.spectrum.ibm.com/nsdFailureGroup- \
	scale.spectrum.ibm.com/nsdFailureGroupMappingType- \
	scale.spectrum.ibm.com/role- 

oc delete mutatingwebhookconfigurations \
            ibm-spectrum-scale-mutating-webhook-configuration

oc delete validatingwebhookconfigurations \
            ibm-spectrum-scale-validating-webhook-configuration
```

### 启用 openshift image-registry
```
### 增加 capabilities ImageRegistry
oc patch clusterversion/version --type merge -p '{"spec":{"capabilities":{"additionalEnabledCapabilities":["Build","Console","ImageRegistry","Ingress","Storage","CSISnapshot","OperatorLifecycleManager","marketplace","NodeTuning"]}}}'

### 等待 cluster operator 状态正常
oc get co

### 创建 pvc 
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: image-registry
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: ocs-external-storagecluster-ceph-rbd
  volumeMode: Filesystem
EOF

### patch configs.imageregistry.operator.openshift.io/cluster
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"storage":{"pvc":{"claim":"image-registry"}}}}'

oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"rolloutStrategy":"Recreate"}}'

oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"managementState":"Managed"}}'

### 检查 pods
oc get pods -n openshift-image-registry
NAME                                               READY   STATUS    RESTARTS   AGE
cluster-image-registry-operator-79fdcbb7f4-pzx7h   1/1     Running   0          19m
image-registry-7d7c7bd985-q24ng                    1/1     Running   0          5m2s
node-ca-4hzf9                                      1/1     Running   0          19m
node-ca-6tbn5                                      1/1     Running   0          19m
node-ca-jc5w6                                      1/1     Running   0          19m
```

### 安装 Fusion Access for SAN
```
### 第一部分
上传镜像，需要ubi镜像
/usr/local/bin/oc-mirror --from ./ubi_mirror_seq1_000000.tar docker://harbor.sewc.siemens.com/fafso 

生成ImageTagMirrorSet
cat <<EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: ImageTagMirrorSet
metadata:
  name: operator-certified-fafs-ubi9
spec:
  imageTagMirrors:
  - mirrors:
    - harbor.sewc.siemens.com/fafso/ubi9
    source: registry.redhat.io/ubi9
EOF


### 第二部分
oc get configmap -n openshift-config 
确认openshift-config namespace下没有configmap custom-ca和registry-ca

保存registryca.crt文件
openssl s_client -connect harbor.sewc.siemens.com:443 2>/dev/null </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee registryca.crt

oc -n openshift-config create configmap custom-ca \
  --from-file=ca-bundle.crt=registryca.crt \
  --dry-run=client -o yaml | oc apply -f -

oc get proxy/cluster -o yaml

确认/spec/trustedCA为空运行
oc patch proxy/cluster \
     --type=merge \
     --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'  

oc -n openshift-config create configmap registry-ca \
  --from-file=harbor.sewc.siemens.com=registryca.crt \
  --dry-run=client -o yaml | oc apply -f -

oc get image.config.openshift.io/cluster -o yaml 

确认/spec/additionalTrustedCA为空运行
oc patch image.config.openshift.io/cluster --type=merge -p \
'{"spec":{"additionalTrustedCA":{"name":"registry-ca"}}}'


### 第三部分
安装完Fusion Access for SAN Operator后
oc create secret -n ibm-fusion-access generic fusion-pullsecret --from-literal=ibm-entitlement-key=

可选 - 启用 image-registry，并且为 image-registry 设置 .spec.storage.pvc.claim
可选 - 创建 configmap kmm-image-config 和 secret kmm-push-secret
apiVersion: v1
kind: ConfigMap
metadata:
  name: kmm-image-config
  namespace: ibm-fusion-access
data:
  kmm_image_registry_url: "registry.ocp4.example.com"
  kmm_image_repo: "kmm/gpfs_compat_kmod"
  # kmm_tls_insecure: "false"
  # kmm_tls_skip_verify: "true"
  kmm_image_registry_secret_name: "kmm-push-secret"
---
apiVersion: v1
kind: Secret
metadata:
  name: kmm-push-secret
  namespace: ibm-fusion-access
data:
  .dockerconfigjson: ewogICJhdXRocyI6IHsKICAgICJyZWdpc3RyeS5vY3A0LmV4YW1wbGUuY29tIjogewogICAgICAiYXV0aCI6ICJkR1Z6ZERFNlVtVmthR0YwSVRJeiIKICAgIH0KICB9Cn0K
type: kubernetes.io/dockerconfigjson




为节点打标签 scale.spectrum.ibm.com/role=storage
oc label nodes -l node-role.kubernetes.io/master "scale.spectrum.ibm.com/role=storage"

创建Cluster
oc apply -f=- <<EOF
---
apiVersion: scale.spectrum.ibm.com/v1beta1
kind: Cluster
metadata:
  name: ibm-spectrum-scale
  namespace: ibm-spectrum-scale
spec:
  pmcollector:
    nodeSelector:
      scale.spectrum.ibm.com/role: storage
  daemon:
    nsdDevicesConfig:
      localDevicePaths:
      - devicePath: /dev/disk/by-id/*
        deviceType: generic
    clusterProfile:
      controlSetxattrImmutableSELinux: "yes"
      enforceFilesetQuotaOnRoot: "yes"
      ignorePrefetchLUNCount: "yes"
      initPrefetchBuffers: "128"
      maxblocksize: 16M
      prefetchPct: "25"
      prefetchTimeout: "30"
    nodeSelector:
      scale.spectrum.ibm.com/role: storage
    roles:
    - name: client
      resources:
        cpu: "2"
        memory: 4Gi
    - name: storage
      resources:
        cpu: "2"
        memory: 8Gi
  license:
    accept: true
    license: data-management
EOF

### 检查磁盘
oc debug node/m0-ocp4test.ocp4.example.com -q -- chroot /host ls -l /dev/disk/by-path 
oc debug node/m1-ocp4test.ocp4.example.com -q -- chroot /host ls -l /dev/disk/by-path 
oc debug node/m2-ocp4test.ocp4.example.com -q -- chroot /host ls -l /dev/disk/by-path 

### 创建 localdisks
cat <<EOF | oc apply -f -
apiVersion: scale.spectrum.ibm.com/v1beta1
kind: LocalDisk
metadata:
  name: shareddisk1
  namespace: ibm-spectrum-scale
spec:
  # After successful creation of the local disk, this parameter is no longer used
  device: /dev/sda
  # The Kubernetes node where the specified device exists at creation time.
  node: m2-ocp4test.ocp4.example.com
  # nodeConnectionSelector defines the nodes that have the shared lun directly attached to them. If left commented out, all the nodes with the label “scale.spectrum.ibm.com/role=storage” will be used
  # nodeConnectionSelector:
  #  matchExpressions:
  #  - key: node-role.kubernetes.io/worker
  #    operator: Exists
  # You could also list the node names instead
  # nodeConnectionSelector:
  #  matchExpressions:
  #  - key: kubernetes.io/hostname
  #    operator: In
  #    values:
  #      - ip-10-0-17-96.eu-central-1.compute.internal
  #      - ip-10-0-39-125.eu-central-1.compute.internal
  #      - ip-10-0-40-135.eu-central-1.compute.internal
  # set below only during testing, this will wipe existing stuff
  existingDataSkipVerify: true
EOF

cat <<EOF | oc apply -f -
apiVersion: scale.spectrum.ibm.com/v1beta1
kind: LocalDisk
metadata:
  name: shareddisk2
  namespace: ibm-spectrum-scale
spec:
  # After successful creation of the local disk, this parameter is no longer used
  device: /dev/sdb
  # The Kubernetes node where the specified device exists at creation time.
  node: m2-ocp4test.ocp4.example.com
  # nodeConnectionSelector defines the nodes that have the shared lun directly attached to them. If left commented out, all the nodes with the label “scale.spectrum.ibm.com/role=storage” will be used
  # nodeConnectionSelector:
  #  matchExpressions:
  #  - key: node-role.kubernetes.io/worker
  #    operator: Exists
  # You could also list the node names instead
  # nodeConnectionSelector:
  #  matchExpressions:
  #  - key: kubernetes.io/hostname
  #    operator: In
  #    values:
  #      - ip-10-0-17-96.eu-central-1.compute.internal
  #      - ip-10-0-39-125.eu-central-1.compute.internal
  #      - ip-10-0-40-135.eu-central-1.compute.internal
  # set below only during testing, this will wipe existing stuff
  existingDataSkipVerify: true
EOF

### 创建 Filesystem - 只包含一个localdisk
cat <<EOF | oc apply -f -
apiVersion: scale.spectrum.ibm.com/v1beta1
kind: Filesystem
metadata:
  name: localfilesystem
  namespace: ibm-spectrum-scale
spec:
  local:
    blockSize: 4M
    pools:
    - name: system
      disks:
      - shareddisk1
    # Only 1-way is supported for LFS https://www.ibm.com/docs/en/scalecontainernative/5.2.1?topic=systems-local-file-system#filesystem-spec
    replication: 1-way
    type: shared
  seLinuxOptions:
    level: s0
    role: object_r
    type: container_file_t
    user: system_u
EOF

### 用命令为Filesystem localfilesystem 添加 localdisk shareddisk2
kubectl patch filesystem localfilesystem \
  -n ibm-spectrum-scale \
  --type='json' \
  -p='[
    {
      "op": "add",
      "path": "/spec/local/pools/0/disks/-",
      "value": "shareddisk2"
    }
  ]'

### 创建 Filesystem 包含 2 个 localdisk (可选)
cat <<EOF | oc apply -f -
apiVersion: scale.spectrum.ibm.com/v1beta1
kind: Filesystem
metadata:
  name: localfilesystem
  namespace: ibm-spectrum-scale
spec:
  local:
    blockSize: 4M
    pools:
    - name: system
      disks:
      - shareddisk1
      - shareddisk2
    # Only 1-way is supported for LFS https://www.ibm.com/docs/en/scalecontainernative/5.2.1?topic=systems-local-file-system#filesystem-spec
    replication: 1-way
    type: shared
  seLinuxOptions:
    level: s0
    role: object_r
    type: container_file_t
    user: system_u
EOF

### 查看 ibm-spectrum-scale-operator 日志
oc -n ibm-spectrum-scale-operator logs $(oc get pods -n ibm-spectrum-scale-operator -l app.kubernetes.io/name="operator" -o name)

### 将文件系统设置为maintenanceMode=true
kubectl label filesystem localfilesystem -n ibm-spectrum-scale scale.spectrum.ibm.com/maintenanceMode=true

### 将文件系统设置为maintenanceMode=false
kubectl label filesystem localfilesystem -n ibm-spectrum-scale scale.spectrum.ibm.com/maintenanceMode=false --overwrite

### 检查 GPFS 的命令
https://gist.github.com/mvazquezc/ca0243452a058b730fa94e13116b4419#file-01-verify-deployment-md
https://www.ibm.com/docs/en/scalecontainernative/5.2.1?topic=installation-verifying-storage-scale-container-native-cluster

### 检查 GPFS cluster 状态
oc exec $(oc get pods -lapp.kubernetes.io/name=core \
   -ojsonpath="{.items[0].metadata.name}" -n ibm-spectrum-scale)  \
   -c gpfs -n ibm-spectrum-scale -- mmlscluster

### 检查 GPFS status
oc exec $(oc get pods -lapp.kubernetes.io/name=core \
   -ojsonpath="{.items[0].metadata.name}" -n ibm-spectrum-scale)  \
   -c gpfs -n ibm-spectrum-scale -- mmgetstate -a

### 检查文件系统挂载状态
oc exec $(oc get pods -lapp.kubernetes.io/name=core \
   -ojsonpath="{.items[0].metadata.name}" -n ibm-spectrum-scale)  \
   -c gpfs -n ibm-spectrum-scale -- mmlsmount localfilesystem -L

### 检查活跃NSD
oc exec $(oc get pods -lapp.kubernetes.io/name=core \
   -ojsonpath="{.items[0].metadata.name}" -n ibm-spectrum-scale)  \
   -c gpfs -n ibm-spectrum-scale -- mmlsnsd -M



### 收集 must-gather
oc adm must-gather --image=registry.ocp4.example.com/fafso/cpopen/ibm-spectrum-scale-must-gather:v5.2.3.1

### 调整Deployment Limits
### 可以通过修改CSV来实现
oc get csv openshift-fusion-access-operator.v0.9.3 -o json | jq -r .spec.install.spec.deployments[0].spec.template.spec.containers[0].resources.limits.memory
2Gi

### 创建VolumeSnapshotClass
cat <<EOF | oc apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: ibm-spectrum-scale-snapshot-class
driver: spectrumscale.csi.ibm.com
deletionPolicy: Delete
EOF

### 上传镜像
virtctl image-upload dv rhel-9-4-golden-gpfs --size 11Gi --image-path rhel-9.4-x86_64-kvm.qcow2 --storage-class ibm-spectrum-scale-fs-2 --insecure --force-bind

### 创建DataSource
cat <<EOF | oc apply -f -
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataSource
metadata:
  name: rhel-9-4-golden-gpfs 
  namespace: openshift-virtualization-os-images
  labels:
    instancetype.kubevirt.io/default-instancetype: cx1.large
    instancetype.kubevirt.io/default-preference: rhel.9
spec:
  source:
    pvc:
      name: rhel-9-4-golden-gpfs 
      namespace: openshift-virtualization-os-images
EOF
```

### 检查模块签名
### 生成public key/private key
### 在节点添加MOK
### 在UEFI Enroll MOK
### 重启系统检查 enrolled key
### 安装Fusion Access for SAN Operator
### 设置secureboot-signing-key和secureboot-signing-key-pub
### 创建FusionAccess对象
```
### 检查模块签名
mkdir /mnt/foo
podman run --security-opt 'label=disable' -it -v /mnt/foo:/mnt/foo:rw image-registry.openshift-image-registry.svc:5000/ibm-fusion-access/gpfs_compat_kmod:5.14.0-427.68.1.el9_4.x86_64-c7bac83afa194b9f37a4edc59628779a sh
cp -avf /opt/lib/modules/5.14.0-427.68.1.el9_4.x86_64/* /mnt/foo/
exit
modinfo /mnt/foo/mmfs26.ko 

### 检查节点是否启用 secure boot
oc debug node/m2-ocp4test.ocp4.example.com -q -- chroot /host mokutil --sb-state

### On the host where you create the keypair to upload to secureboot
### RHEL9.4 works
dnf install -y pesign nss-tools
export KEYFOLDER=/etc/pki/pesign

# 1. Create the keypair in the NSS db at /etc/pki/pesign
efikeygen --dbdir ${KEYFOLDER} \
  --self-sign \
  --module \
  --common-name 'CN=Organization signing key' \
  --nickname 'Custom Secure Boot key'

# 2. Exports the public key in “sb_cert.cer”
certutil -d ${KEYFOLDER} \
  -n 'Custom Secure Boot key' \
  -Lr > sb_cert.cer

# 3. Exports the p12 version of the private key
pk12util -o sb_cert.p12 \
           -n 'Custom Secure Boot key' \
           -d ${KEYFOLDER}

# 4. Exports the private key in “sb_cert.priv”
openssl pkcs12 \
         -in sb_cert.p12 \
         -out sb_cert.priv \
         -nocerts \
         -noenc

# 5. Copy the sb_cert.cert file on each worker node that will run the 
# core pods.
# On each worker node run the following command (will prompt for password E.g. "changeme")
mokutil --import sb_cert.cert 

# 6. Then reboot into UEFI, in the BIOS make sure Secure Boot is Enabled and during boot choose “MOK Enroll” (will change depending on vendor) and type in the password E.g. "changeme" (Note: If you miss this menu, you'll have to import the certificate again, followed by reboot.)
https://www.dell.com/support/kbdoc/zh-cn/000221584/mok-message-when-booting-linux-with-secure-boot-enabled

# 7. After the reboot, verify that our Key is correctly loaded
# check secure boot state:
mokutil --sb-state
# check enrolled keys (there will usually be three):
mokutil -l

# 8. Install the Fusion Access for SAN operator on the cluster

# 9. Upload the secret keys for KMM to consume
oc create secret generic secureboot-signing-key -n ibm-fusion-access --from-file=key=~/secure_boot_poc/sb_cert.priv
oc create secret generic secureboot-signing-key-pub -n ibm-fusion-access --from-file=cert=~/secure_boot_poc/sb_cert.cer

# 10. Create the fusion access object
# At this point the kernel modules should be signed and a secureboot enabled system with our key enrolled, will be able to modprobe them

```

### GPFS Troubleshooting Command
```
sh-5.1# mmgetstate -aLs

 Node number  Node name    Quorum  Nodes up  Total nodes  GPFS state    Remarks    
-----------------------------------------------------------------------------------
           1  m0-ocp4test    1*         3          3      active        quorum node
           2  m1-ocp4test    1*         3          3      active        quorum node
           3  m2-ocp4test    1*         3          3      active        quorum node

 Summary information 
---------------------
Number of nodes defined in the cluster:            3
Number of local nodes active in the cluster:       3
Number of remote nodes joined in this cluster:     0
Number of quorum nodes defined in the cluster:     3
Number of quorum nodes active in the cluster:      3
Quorum = 1*, Quorum achieved

sh-5.1# mmlsfs all -T

File system attributes for /dev/localfilesystem:
================================================
flag                value                    description
------------------- ------------------------ -----------------------------------
 -T                 /mnt/localfilesystem     Default mount point

sh-5.1# mmlsdisk /dev/localfilesystem
disk         driver   sector     failure holds    holds                            storage
name         type       size       group metadata data  status        availability pool
------------ -------- ------ ----------- -------- ----- ------------- ------------ ------------
shareddisk1  nsd         512           0 yes      yes   ready         up           system       

sh-5.1# tail -100 /var/adm/ras/mmfs.log.latest | grep ERROR

sh-5.1# mmlsconfig
Configuration data for cluster ibm-spectrum-scale.stg.ocp4.example.com:
-----------------------------------------------------------------------
clusterName ibm-spectrum-scale.stg.ocp4.example.com
clusterId 13606102661978813861
autoload no
dmapiFileHandleSize 32
minReleaseLevel 5.2.3.0
ccrEnabled yes
cipherList AUTHONLY
sdrNotifyAuthEnabled yes
cloudEnv general
controlSetxattrImmutableSELinux yes
ignorePrefetchLUNCount yes
initPrefetchBuffers 128
prefetchTimeout 30
tscCmdPortRange 60000-61000
traceGenSubDir /var/mmfs/tmp/traces
ignoreReplicationForQuota yes
ignoreReplicationOnStatfs yes
ignoreReplicaSpaceOnStat yes
readReplicaPolicy local
afmEnableADR no
afmNFSVersion 4.1
afmMountRetryInterval 30
maxblocksize 16M
prefetchPct 25
enforceFilesetQuotaOnRoot yes
[storage_role]
pagepool 5148192768
workerThreads 1024
maxFilesToCache 96000
maxStatCache 96000
[common]
tiebreakerDisks shareddisk1
adminMode central

File systems in cluster ibm-spectrum-scale.stg.ocp4.example.com:
----------------------------------------------------------------
/dev/localfilesystem
```

### Make a bootable Windows 10 USB drive from a Mac
https://alexlubbock.com/bootable-windows-usb-on-mac
```
https://alexlubbock.com/bootable-windows-usb-on-mac
```

### Integrate legacy applications on-premise with OpenShift clusters in the cloud
https://developers.redhat.com/developer-sandbox/activities/connect-services-across-different-environments
```
https://developers.redhat.com/developer-sandbox/activities/connect-services-across-different-environments
```

### 
https://github.com/kubevirt/containerized-data-importer/blob/main/doc/annotations.md
```
https://github.com/kubevirt/containerized-data-importer/blob/main/doc/annotations.md

```

### find_common_cpu_models.sh
 

```
#!/bin/bash

# Script to find common CPU models across all Kubernetes nodes
# Generated with AI assistance (Claude Sonnet 4)
# Usage: ./find_common_cpu_models.sh [kubeconfig_path]

set -euo pipefail

# Function to display usage
usage() {
    echo "Usage: $0 [kubeconfig_path] [--debug]"
    echo "  kubeconfig_path: Optional path to kubeconfig file (defaults to ~/.kube/config)"
    echo "  --debug: Show detailed CPU model parsing information"
    echo ""
    echo "This script finds CPU models that are common across all nodes"
    echo "by examining labels that start with 'cpu-model.node.kubevirt.io'"
    echo "and reports the newest Intel and AMD models."
    exit 1
}

# Parse command line arguments
DEBUG_MODE=false
KUBECONFIG_PATH=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --debug)
            DEBUG_MODE=true
            ;;
        --help|-h)
            usage
            ;;
        *)
            if [[ -z "$KUBECONFIG_PATH" ]]; then
                KUBECONFIG_PATH="$arg"
            fi
            ;;
    esac
done

# Set default kubeconfig if not provided
if [[ -z "$KUBECONFIG_PATH" ]]; then
    KUBECONFIG_PATH="$HOME/.kube/config"
fi

# Check if kubeconfig file exists
if [[ ! -f "$KUBECONFIG_PATH" ]]; then
    echo "Error: Kubeconfig file not found at: $KUBECONFIG_PATH"
    usage
fi

# Set KUBECONFIG environment variable
export KUBECONFIG="$KUBECONFIG_PATH"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl command not found. Please install kubectl."
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

echo "Finding common CPU models across all nodes..."
echo "Using kubeconfig: $KUBECONFIG_PATH"
echo ""

# Get all node names
NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
if [[ -z "$NODES" ]]; then
    echo "Error: No nodes found in the cluster"
    exit 1
fi

echo "Found $(echo $NODES | wc -w) nodes: $(echo $NODES | tr ' ' ', ')"
echo ""

# Initialize arrays to store CPU models for each node
declare -A NODE_CPU_MODELS
declare -A ALL_CPU_MODELS

# Process each node
for node in $NODES; do
    echo "Processing node: $node"
    
    # Get all labels for the node that start with 'cpu-model.node.kubevirt.io'
    # Use a more robust approach to extract labels
    CPU_LABELS=$(kubectl get node "$node" -o json | \
                 grep -o '"cpu-model\.node\.kubevirt\.io[^"]*"' | \
                 sed 's/"//g' | \
                 sed 's/cpu-model\.node\.kubevirt\.io\///')
    
    if [[ -z "$CPU_LABELS" ]]; then
        echo "  Warning: No CPU model labels found for node $node"
        continue
    fi
    
    # CPU_LABELS now contains just the CPU model names
    CPU_MODELS="$CPU_LABELS"
    
    # Add each CPU model to the global list
    for cpu_model in $CPU_MODELS; do
        if [[ -n "$cpu_model" ]]; then
            ALL_CPU_MODELS["$cpu_model"]=1
        fi
    done
    
    # Store CPU models for this node
    NODE_CPU_MODELS["$node"]="$CPU_MODELS"
    
    echo "  Found CPU models: $(echo $CPU_MODELS | tr ' ' ', ')"
done

echo ""

# Find common CPU models across all nodes
COMMON_MODELS=""
FIRST_NODE=true

for node in $NODES; do
    if [[ -n "${NODE_CPU_MODELS[$node]:-}" ]]; then
        if [[ "$FIRST_NODE" == "true" ]]; then
            # For the first node, all its CPU models are potential common models
            COMMON_MODELS="${NODE_CPU_MODELS[$node]}"
            FIRST_NODE=false
        else
            # Find intersection with existing common models
            NEW_COMMON_MODELS=""
            for model in $COMMON_MODELS; do
                if echo "${NODE_CPU_MODELS[$node]}" | grep -q "\b$model\b"; then
                    NEW_COMMON_MODELS="$NEW_COMMON_MODELS $model"
                fi
            done
            COMMON_MODELS="$NEW_COMMON_MODELS"
        fi
    fi
done

# Function to parse CPU model and extract vendor, family, and version
parse_cpu_model() {
    local model="$1"
    local vendor=""
    local family=""
    local version=""
    
    # Convert to lowercase for easier matching
    local model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')
    
    # Detect Intel models (including KubeVirt CPU model names)
    if [[ "$model_lower" =~ intel ]] || [[ "$model_lower" =~ broadwell ]] || [[ "$model_lower" =~ haswell ]] || [[ "$model_lower" =~ ivybridge ]] || [[ "$model_lower" =~ nehalem ]] || [[ "$model_lower" =~ penryn ]] || [[ "$model_lower" =~ sandybridge ]] || [[ "$model_lower" =~ skylake ]] || [[ "$model_lower" =~ cascadelake ]] || [[ "$model_lower" =~ westmere ]]; then
        vendor="intel"
        # Extract family from KubeVirt CPU model names
        if [[ "$model_lower" =~ broadwell ]]; then
            family="broadwell"
        elif [[ "$model_lower" =~ haswell ]]; then
            family="haswell"
        elif [[ "$model_lower" =~ ivybridge ]]; then
            family="ivybridge"
        elif [[ "$model_lower" =~ nehalem ]]; then
            family="nehalem"
        elif [[ "$model_lower" =~ penryn ]]; then
            family="penryn"
        elif [[ "$model_lower" =~ sandybridge ]]; then
            family="sandybridge"
        elif [[ "$model_lower" =~ skylake ]]; then
            family="skylake"
        elif [[ "$model_lower" =~ cascadelake ]]; then
            family="cascadelake"
        elif [[ "$model_lower" =~ westmere ]]; then
            family="westmere"
        elif [[ "$model_lower" =~ xeon ]]; then
            family="xeon"
        elif [[ "$model_lower" =~ core ]]; then
            family="core"
        elif [[ "$model_lower" =~ pentium ]]; then
            family="pentium"
        elif [[ "$model_lower" =~ celeron ]]; then
            family="celeron"
        elif [[ "$model_lower" =~ atom ]]; then
            family="atom"
        else
            family="other"
        fi
        
        # Extract version number (e.g., Broadwell-v4 -> v4, Cascadelake-Server-v5 -> v5)
        if [[ "$model" =~ -v([0-9]+) ]]; then
            version="${BASH_REMATCH[1]}"
        elif [[ "$model" =~ -([0-9]+) ]]; then
            version="${BASH_REMATCH[1]}"
        elif [[ "$model" =~ ([0-9]+) ]]; then
            version="${BASH_REMATCH[1]}"
        fi
    # Detect AMD models (including KubeVirt CPU model names)
    elif [[ "$model_lower" =~ amd ]] || [[ "$model_lower" =~ epyc ]] || [[ "$model_lower" =~ ryzen ]] || [[ "$model_lower" =~ opteron ]] || [[ "$model_lower" =~ athlon ]]; then
        vendor="amd"
        # Extract family (e.g., EPYC, Ryzen, etc.)
        if [[ "$model_lower" =~ epyc ]]; then
            family="epyc"
        elif [[ "$model_lower" =~ ryzen ]]; then
            family="ryzen"
        elif [[ "$model_lower" =~ opteron ]]; then
            family="opteron"
        elif [[ "$model_lower" =~ athlon ]]; then
            family="athlon"
        else
            family="other"
        fi
        
        # Extract version number
        if [[ "$model" =~ -v([0-9]+) ]]; then
            version="${BASH_REMATCH[1]}"
        elif [[ "$model" =~ -([0-9]+) ]]; then
            version="${BASH_REMATCH[1]}"
        elif [[ "$model" =~ ([0-9]+) ]]; then
            version="${BASH_REMATCH[1]}"
        fi
    fi
    
    echo "$vendor|$family|$version"
}

# Function to get CPU family generation order (higher number = newer)
get_cpu_family_generation() {
    local family="$1"
    case "$family" in
        "penryn") echo "1" ;;
        "nehalem") echo "2" ;;
        "westmere") echo "3" ;;
        "sandybridge") echo "4" ;;
        "ivybridge") echo "5" ;;
        "haswell") echo "6" ;;
        "broadwell") echo "7" ;;
        "skylake") echo "8" ;;
        "cascadelake") echo "9" ;;
        *) echo "0" ;;
    esac
}

# Function to compare CPU model versions (higher number = newer)
compare_cpu_versions() {
    local version1="$1"
    local version2="$2"
    local family1="$3"
    local family2="$4"
    
    # Handle empty versions
    if [[ -z "$version1" && -z "$version2" ]]; then
        return 0
    elif [[ -z "$version1" ]]; then
        return 1
    elif [[ -z "$version2" ]]; then
        return 0
    fi
    
    # For numeric versions, higher number is newer
    if [[ "$version1" =~ ^[0-9]+$ && "$version2" =~ ^[0-9]+$ ]]; then
        if [[ "$version1" -gt "$version2" ]]; then
            return 0
        elif [[ "$version1" -lt "$version2" ]]; then
            return 1
        else
            return 0
        fi
    fi
    
    # For non-numeric versions, use string comparison
    if [[ "$version1" > "$version2" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to compare CPU models (considers both family generation and version)
compare_cpu_models() {
    local model1="$1"
    local model2="$2"
    
    local parsed1=$(parse_cpu_model "$model1")
    local vendor1=$(echo "$parsed1" | cut -d'|' -f1)
    local family1=$(echo "$parsed1" | cut -d'|' -f2)
    local version1=$(echo "$parsed1" | cut -d'|' -f3)
    
    local parsed2=$(parse_cpu_model "$model2")
    local vendor2=$(echo "$parsed2" | cut -d'|' -f1)
    local family2=$(echo "$parsed2" | cut -d'|' -f2)
    local version2=$(echo "$parsed2" | cut -d'|' -f3)
    
    # Must be same vendor
    if [[ "$vendor1" != "$vendor2" ]]; then
        return 1
    fi
    
    # Compare family generations first
    local gen1=$(get_cpu_family_generation "$family1")
    local gen2=$(get_cpu_family_generation "$family2")
    
    if [[ "$gen1" -gt "$gen2" ]]; then
        return 0
    elif [[ "$gen1" -lt "$gen2" ]]; then
        return 1
    fi
    
    # Same family, compare versions
    compare_cpu_versions "$version1" "$version2" "$family1" "$family2"
}

# Find newest Intel and AMD models from common models
find_newest_models() {
    local newest_intel=""
    local newest_amd=""
    
    for model in $COMMON_MODELS; do
        local parsed=$(parse_cpu_model "$model")
        local vendor=$(echo "$parsed" | cut -d'|' -f1)
        local family=$(echo "$parsed" | cut -d'|' -f2)
        local version=$(echo "$parsed" | cut -d'|' -f3)
        
        if [[ "$DEBUG_MODE" == "true" ]]; then
            echo "  DEBUG: $model -> vendor=$vendor, family=$family, version=$version"
        fi
        
        if [[ "$vendor" == "intel" ]]; then
            if [[ -z "$newest_intel" ]] || compare_cpu_models "$model" "$newest_intel"; then
                newest_intel="$model"
            fi
        elif [[ "$vendor" == "amd" ]]; then
            if [[ -z "$newest_amd" ]] || compare_cpu_models "$model" "$newest_amd"; then
                newest_amd="$model"
            fi
        fi
    done
    
    echo "$newest_intel|$newest_amd"
}

# Display results
echo "=== RESULTS ==="
echo ""

if [[ -z "$COMMON_MODELS" ]]; then
    echo "No common CPU models found across all nodes."
    echo ""
    echo "All CPU models found in the cluster:"
    for model in "${!ALL_CPU_MODELS[@]}"; do
        echo "  - $model"
    done | sort
else
    echo "Common CPU models across all nodes:"
    for model in $COMMON_MODELS; do
        echo "  - $model"
    done | sort
    
    echo ""
    echo "=== NEWEST MODELS ==="
    
    # Find newest Intel and AMD models
    newest_models=$(find_newest_models)
    newest_intel=$(echo "$newest_models" | cut -d'|' -f1)
    newest_amd=$(echo "$newest_models" | cut -d'|' -f2)
    
    if [[ -n "$newest_intel" ]]; then
        echo "Newest Intel model: $newest_intel"
    else
        echo "No Intel models found in common models"
    fi
    
    if [[ -n "$newest_amd" ]]; then
        echo "Newest AMD model: $newest_amd"
    else
        echo "No AMD models found in common models"
    fi
fi

echo ""
echo "Summary:"
echo "  Total nodes: $(echo $NODES | wc -w)"
echo "  Total unique CPU models: ${#ALL_CPU_MODELS[@]}"
echo "  Common CPU models: $(echo $COMMON_MODELS | wc -w)"
```

### 设置集群的defaultCPUModel
https://docs.okd.io/4.15/virt/virtual_machines/advanced_vm_management/virt-configuring-default-cpu-model.html
https://www.qemu.org/docs/master/system/qemu-cpu-models.html
```
### 设置集群的defaultCPUModel
### https://www.qemu.org/docs/master/system/qemu-cpu-models.html

oc patch hyperconverged kubevirt-hyperconverged -n openshift-cnv --type='json' -p='
[
  {
    "op": "add",
    "path": "/spec/defaultCPUModel",
    "value": "IvyBridge"
  }
]
'
oc patch hyperconverged kubevirt-hyperconverged -n openshift-cnv --type='json' -p='
[
  {
    "op": "replace",
    "path": "/spec/defaultCPUModel",
    "value": "IvyBridge"
  }
]
'
oc patch hyperconverged kubevirt-hyperconverged -n openshift-cnv --type='json' -p='
[
  {
    "op": "replace",
    "path": "/spec/defaultCPUModel",
    "value": "IvyBridge"
  }
]
'
```

### 卸载时检查validationwebhookconfiguration
```
### 查询validatingwebhookconfiguration，选择webhooks[].name等于kubevirt-validator.kubevirt.io的validatingwebhookconfiguration，输出validatingwebhookconfiguration的metadata.name
$ oc get validatingwebhookconfiguration -ojson | jq -r '.items[] | select(.webhooks[].name=="kubevirt-validator.kubevirt.io") | .metadata.name'

### 查询validatingwebhookconfiguration，遍历所有webhooks[]，检查.name包含kubevirt.io的validatingwebhookconfiguration，输出validatingwebhookconfiguration的metadata.name
$ oc get validatingwebhookconfiguration -o json | jq -r '.items[] | select(any(.webhooks[]; .name | test("kubevirt\\.io"))) | .metadata.name'

### 查询mutatingwebhookconfiguration，遍历所有webhooks[]，检查.name包含kubevirt.io的mutatingwebhookconfiguration，输出mutatingwebhookconfiguration的metadata.name
$ oc get mutatingwebhookconfiguration -o json | jq -r '.items[] | select(any(.webhooks[]; .name | test("kubevirt\\.io"))) | .metadata.name'

### 查询mutatingwebhookconfiguration，检查具有标签app.kubernetes.io/part-of=hyperconverged-cluster的mutatingwebhookconfiguration
$ oc get mutatingwebhookconfiguration -lapp.kubernetes.io/part-of=hyperconverged-cluster

### 查询validatingwebhookconfiguration，检查具有标签app.kubernetes.io/part-of=hyperconverged-cluster的validatingwebhookconfiguration
$ oc get validatingwebhookconfiguration -lapp.kubernetes.io/part-of=hyperconverged-cluster
```

### 生成 hashed passwd 的命令
https://access.redhat.com/solutions/221403
```
https://access.redhat.com/solutions/221403
$ openssl passwd -help 2>&1 | grep SHA
$ openssl passwd -6
Password: 
Verifying - Password: 
$6$SXXj.Gzz6n73EfKz$.j0OR1tWM8A70dPginx9OgawmHbLph0YOcKSpTzZWlcbJ17v3zEWk2NtMSM7MDRNe9RFcSVxtAFWxy0CHU2Pm.
```

### 为 core 用户设置 hashed passwd
https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/machine_configuration/index
```
podman run --rm -it --entrypoint /bin/sh quay.io/coreos/mkpasswd:latest
sh-5.2# mkpasswd -m SHA-512
Password: 

### 生成的passwdhash放在machineconfig里，用双引号包围

cat <<'EOF' | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-set-core-user-password
spec:
  config:
    ignition:
      version: 3.4.0
    passwd:
      users:
      - name: core 
        passwordHash: "<password-hash-remove>"
EOF

cat <<'EOF' | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-set-core-user-password
spec:
  config:
    ignition:
      version: 3.4.0
    passwd:
      users:
      - name: core 
        passwordHash: "<password-hash-remove>"
EOF

oc debug node/master1.ocp.ap.vwg -q -- chroot /host cat /etc/shadow | grep core
oc debug node/worker1.ocp.ap.vwg -q -- chroot /host cat /etc/shadow | grep core

```

### Backup and Restore vm
https://portal.nutanix.com/page/documents/solutions/details?targetId=TN-2030-Red-Hat-OpenShift-on-Nutanix:applications.html
```
skopeo copy --format v2s2 --all dir:/tmp/minio/minio docker://helper.ocp.ap.vwg:5000/minio/minio:latest  
skopeo copy --format v2s2 --all dir:/tmp/minio/mc docker://helper.ocp.ap.vwg:5000/minio/mc:latest


tar zxvf github-velero.tar.gz
cd velero/examples/minio/
# edit /tmp/velero/examples/minio/00-minio-deployment.yaml
[root@helper minio]# cat 00-minio-deployment.yaml | grep "image: "
        image: helper.ocp.ap.vwg:5000/minio/minio:latest
        image: helper.ocp.ap.vwg:5000/minio/mc:latest

oc apply -f ./00-minio-deployment.yaml
oc get pods
oc expose svc/minio

unzip awscliv2.zip
sudo ./aws/install

aws --endpoint=http://$(oc get route -n velero minio -o json | jq -r .spec.host) s3 ls
aws --endpoint=http://$(oc get route -n velero minio -o jsonpath='{.spec.host}') s3 ls
aws --endpoint=http://$(oc get route -n velero minio -o jsonpath='{.spec.host}') s3 mb s3://oadp-backups 
aws --endpoint=http://$(oc get route -n velero minio -o jsonpath='{.spec.host}') s3 ls

NAMESPACE=openshift-adp

export ACCESS_KEY='minio'
export SECRET_KEY='minio123'

cat << EOF > ./credentials-velero
[default]
aws_access_key_id=${ACCESS_KEY}
aws_secret_access_key=${SECRET_KEY}
EOF

oc create secret generic cloud-credentials -n openshift-adp --from-file cloud=credentials-velero

cat <<EOF | oc apply -f -
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: velero-sample
  namespace: openshift-adp
spec:
  backupLocations:
  - velero:
      config:
        insecureSkipTLSVerify: "true"
        profile: default
        region: minio
        s3ForcePathStyle: "true"
        s3Url: http://minio-velero.apps.ocp.ap.vwg
      credential:
        key: cloud
        name: cloud-credentials
      default: true
      objectStorage:
        bucket: oadp-backups
        prefix: velero
      provider: aws
  configuration:
    nodeAgent:
      enable: true
      uploaderType: kopia
    velero:
      defaultPlugins:
      - openshift
      - aws
      - csi
      - kubevirt
    featureFlags:
    - EnableCSI
EOF

oc get dpa -A 
oc get backupstoragelocations -A 

oc get storageclass
NAME                PROVISIONER      RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-csi (default)   nfs.csi.k8s.io   Delete          Immediate           true                   169d

oc get volumestorageclass
NAME                 DRIVER           DELETIONPOLICY   AGE
nfs-snapshot-class   nfs.csi.k8s.io   Delete           60d

2. add label to VolumeSnapshotClass 
oc label volumesnapshotclass nfs-snapshot-class velero.io/csi-volumesnapshot-class=true
oc patch volumesnapshotclass nfs-snapshot-class --type=merge -p '{"deletionPolicy": "Retain"}'


# https://docs.okd.io/4.18/backup_and_restore/application_backup_and_restore/installing/oadp-backup-restore-csi-snapshots.html#oadp-1-3-backing-csi-snapshots_oadp-backup-restore-csi-snapshots

cat <<EOF | oc create -f -
apiVersion: velero.io/v1
kind: Backup
metadata:
  generateName: test-
  namespace: openshift-adp
spec:
  csiSnapshotTimeout: 10m0s
  defaultVolumesToFsBackup: false
  includedNamespaces:
  - test
  snapshotVolumes: true
  snapshotMoveData: true
  storageLocation: velero-sample-1
  ttl: 72h0m0s
EOF

cat <<EOF | oc create -f -
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: restore-test
  namespace: openshift-adp
spec:
  backupName: test-49wh5
  excludedResources:
    - nodes
    - events
    - events.events.k8s.io
    - backups.velero.io
    - restores.velero.io
    - resticrepositories.velero.io
  restorePVs: true
EOF

### 下载 velero 的地址
https://github.com/vmware-tanzu/velero/releases/tag/v1.14.1

$ oc rsh <velero-pod> ./velero

$ velero -n openshift-adp get backups

$ velero -n openshift-adp describe backups test-49wh5 --details

$ velero get restores -n openshift-adp 
NAME           BACKUP       STATUS      STARTED                         COMPLETED                       ERRORS   WARNINGS   CREATED                         SELECTOR
restore-test   test-49wh5   Completed   2025-10-13 16:01:03 +0800 CST   2025-10-13 16:04:00 +0800 CST   0        10         2025-10-13 16:01:03 +0800 CST   <none>

$ velero describe restores restore-test -n openshift-adp

```

### 关于 SPIFFE 和 SPIRE 的介绍系列
https://medium.com/@huang195/developer-friendly-zero-trust-using-spiffe-spire-part-1-introduction-a184cbdaf67e 
https://medium.com/@huang195/developer-friendly-zero-trust-using-spiffe-spire-part-2-spiffe-helper-0b5495159336
https://medium.com/@huang195/developer-friendly-zero-trust-using-spiffe-spire-part-3-seccomp-unotify-2cdf3da86033
https://medium.com/@huang195/developer-friendly-zero-trust-using-spiffe-spire-part-4-container-lifecycle-hooks-0375881bd88a
https://medium.com/@huang195/developer-friendly-zero-trust-using-spiffe-spire-part-5-container-storage-interface-csi-6119770cdfea

### 零信任安全：SPIFFE 和 SPIRE 通用身份验证的标准和实现
https://atbug.com/what-is-spiffe-and-spire/

### redhat servicemesh3 安装
https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.1/html/installing/ossm-installing-service-mesh

### 安装 red hat service mesh 3 和 kiali 以及 openshift-monitoring
https://medium.com/kialiproject/installing-openshift-service-mesh-3-with-kiali-and-openshift-monitoring-584cbddb8c24

### 为 OpenShift Virtualization 增加 machine type
https://access.redhat.com/solutions/6571471
```
### /spec/configuration/architectureConfiguration/amd64/emulatedMachines 里增加 pc-i440fx-rhel7.6.0
$ oc annotate --overwrite -n openshift-cnv hco kubevirt-hyperconverged   kubevirt.kubevirt.io/jsonpatch='[ {"op": "add", "path": "/spec/configuration/architectureConfiguration", "value": {} },  {"op": "add", "path": "/spec/configuration/architectureConfiguration/amd64", "value": {} },{"op": "add", "path": "/spec/configuration/architectureConfiguration/amd64/emulatedMachines", "value": ["q35*", "pc-q35*", "pc-i440fx-rhel7.6.0"] } ]'

$ oc get kv kubevirt-kubevirt-hyperconverged -n openshift-cnv -o yaml  | grep -A 3 emulated
```

### 查询 /usr/libexec/qemu-kvm 支持的 machine type
```
oc exec -it virt-launcher-win2k3-test-01-wjhmr -- /usr/libexec/qemu-kvm -M ?
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

### RHEL/CentOS 6 VM doesn't start after migration

https://access.redhat.com/solutions/6672391
```
$ oc patch vm ${VM_NAME} --type='json' -p='[{"op": "add", "path": "/spec/template/spec/domain/devices/useVirtioTransitional", "value": true }]' -n ${VM_NAMESPACE}
```

### Red Hat Service Mesh 3 w/ OpenTelemetry, Grafana Tempo, Kiali
https://medium.com/kialiproject/installing-openshift-service-mesh-3-tp1-with-kiali-and-grafana-tempo-6b76881ceaef
https://github.com/michaelalang/ossm-distributed-tracing

### OpenShift AI 如何与 Service Mesh 3 并存在一个 Cluster 里
https://developers.redhat.com/articles/2025/07/16/how-deploy-openshift-ai-service-mesh-3-one-cluster#testing_and_validation
```
### 安装测试 Service Mesh 3 
git clone https://github.com/bugbiteme/ossm-3-demo.git
cd ossm-3-demo
git checkout rhoai-cluster

oc login --token=sha256xxxx --server=https://api.xxx.com:6443
oc get crd gateways.gateway.networking.k8s.io &> /dev/null ||  { oc kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.0.0" | oc apply -f -; }

sh install_ossm3_demo.sh
Installing Minio for Tempo...
Installing TempoCR...
Installing OpenTelemetryCollector...
Installing OSSM3...
Installing IstioCR...
Installing Kiali...
Installing Bookinfo...
...
Ingress route for Bookinfo: http://istio-ingressgateway-istio-ingress.apps.xxxx.com/productpage  
Kiali route: https://kiali-istio-system-3.apps.xxxx.com
```

### 如何为虚拟机添加
https://issues.redhat.com/browse/CNV-51056
```
$ oc get kubevirt -n openshift-cnv  kubevirt-kubevirt-hyperconverged -o jsonpath='{.spec.configuration.developerConfiguration.featureGates}'  | jq . 
[
  "CPUManager",
  "Snapshot",
  "HotplugVolumes",
  "ExpandDisks",
  "GPU",
  "HostDevices",
  "VMExport",
  "DisableCustomSELinuxPolicy",
  "KubevirtSeccompProfile",
  "VMPersistentState",
  "NetworkBindingPlugins",
  "VMLiveUpdateFeatures",
  "DynamicPodInterfaceNaming",
  "VolumesUpdateStrategy",
  "VolumeMigration",
  "WithHostModelCPU",
  "HypervStrictCheck"
]

$ oc annotate --overwrite -n openshift-cnv hco kubevirt-hyperconverged kubevirt.kubevirt.io/jsonpatch='[{"op": "add", "path": "/spec/configuration/developerConfiguration/featureGates/-", "value": "Sidecar" }]'

$ oc get kubevirt -n openshift-cnv  kubevirt-kubevirt-hyperconverged -o jsonpath='{.spec.configuration.developerConfiguration.featureGates}'  | jq . 
[
  "CPUManager",
  "Snapshot",
  "HotplugVolumes",
  "ExpandDisks",
  "GPU",
  "HostDevices",
  "VMExport",
  "DisableCustomSELinuxPolicy",
  "KubevirtSeccompProfile",
  "VMPersistentState",
  "NetworkBindingPlugins",
  "VMLiveUpdateFeatures",
  "DynamicPodInterfaceNaming",
  "VolumesUpdateStrategy",
  "VolumeMigration",
  "WithHostModelCPU",
  "HypervStrictCheck",
  "Sidecar"
]

$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: pcihole64
  namespace: test4
data:
  pcihole64.py: |
    #!/usr/bin/env python3
    """
    This module can be used as an onDefineDomain sidecar hook in KubeVirt to
    ensure compatibility with Windows XP when using the q35 machine type.
    """

    import xml.etree.ElementTree as ET
    import sys


    def main(domain: str):
        """
        This function parses the domain XML passed in the domain argument, adds a
        pcihole64 element with value 0 to every pcie-root controller and then
        prints the modified XML to stdout.
        """

        xml = ET.ElementTree(ET.fromstring(domain))

        controllers = xml.findall("./devices/controller[@model='pcie-root']")
        for controller in controllers:
            element = ET.Element("pcihole64", {"unit": "KiB"})
            element.text = "0"
            controller.insert(0, element)

        ET.indent(xml)
        xml.write(sys.stdout, encoding="unicode")


    if __name__ == "__main__":
        main(sys.argv[4])
EOF

$ oc get configmap -n test4 pcihole64 -o jsonpath='{.data.pcihole64\.py}'

$ oc patch vm win2k3-test-01 -n test4 \
  --type merge \
  -p '{"spec":{"template":{"metadata":{"annotations":{"hooks.kubevirt.io/hookSidecars":"[{\"args\": [\"--version\", \"v1alpha3\"], \"configMap\": {\"name\": \"pcihole64\", \"key\": \"pcihole64.py\", \"hookPath\": \"/usr/bin/onDefineDomain\"}}]"}}}}}'

```

### memory overcommit 
https://developers.redhat.com/blog/2025/01/31/memory-management-openshift-virtualization#reservation_and_utilization
```
$ oc -n openshift-cnv patch HyperConverged/kubevirt-hyperconverged --type='json' -p='[ \
  { \
  "op": "replace", \
  "path": "/spec/higherWorkloadDensity/memoryOvercommitPercentage", \
  "value": 150 \
  } \
]'
hyperconverged.hco.kubevirt.io/kubevirt-hyperconverged patched
$
```

### CentOS6 Template
https://github.com/kubevirt/common-templates/blob/master/templates/centos6.tpl.yaml
https://github.com/kubevirt/common-templates/blob/master/templates/rhel7.tpl.yaml
```
需要设置
spec.template.spec.domain.devices.useVirtioTransitional: true
```

### RHEL4 MTV迁移后处理
```
### 1. 用 RHEL 4 ISO启动
### 2. 进入恢复模式 linux rescure
### 3. chroot /mnt/sysimage

### 4. 创建带sata驱动的initrd
mkinitrd --preload=sr_mod --preload=sd_mod --preload=scsi_mod --preload=achi --preload=libata /boot/initrd-$(uname -r).img $(uname -r)

mkinitrd --preload=sr_mod --preload=sd_mod --preload=scsi_mod --preload=achi --preload=libata /boot/initrd-$(uname -r)smp.img $(uname -r)smp
```

### RHEL5 MTV迁移后处理
```
### 1. 用 RHEL 5 ISO启动
### 2. 进入恢复模式 linux rescure
### 3. chroot /mnt/sysimage

### 4. 创建带virtio，带sata驱动的initrd
mkinitrd --preload=virtio-pci --preload=virtio-blk --preload=virtio-net --preload=virtio-ring --preload=sr_mod --preload=sd_mod --preload=scsi_mod --preload=achi --preload=libata /boot/initrd-2.6.18-398.el5-new.img 2.6.18-398.el5
mv /boot/initrd-2.6.18-398.el5-new.img /boot/initrd-2.6.18-398.el5.img

### RHEL5 virtio 驱动与 OpenShift Virtualization不兼容
```

### RHEL6 MTV迁移后处理
```
### 1. 用 RHEL 6 ISO启动安装，在最后阶段按 CTRL_ALT_F2
### 2. chroot /mnt/sysimage
### 3. 设置 PATH export PATH=$PATH:/sbin:/bin:/usr/sbin:/usr/bin

### 4. 创建带virtio，带sata驱动的initrd
mkinitrd --preload=virtio_pci --preload=virtio_blk --preload=virtio_scsi --preload=virtio_net --preload=virtio_ring --preload=sd_mod --preload=achi /boot/initrd-2.6.32-754.el6-new.x86_64.img 2.6.32-754.el6.x86_64
mv /boot/initrd-2.6.32-754.el6-new.x86_64.img /boot/initrd-2.6.32-754.el6.x86_64.img

### RHEL5 virtio 驱动与 OpenShift Virtualization不兼容
### 需要把 Disk 从 DataVolume 改为 PVC
```

### HDS VSP5500 static provision PV里VolumeHandle的写法
```
01--<IO-protocol>--<storagedevice-ID>--<LDEV-ID>--<LDEVnickname>
The format of the nickname is spc-<10-digit-hexadecimal-number>.
<LDEV-ID>Check these values by using the storage system management software. Specify a value by using a decimal number.

volumeHandle: 01--scsi--886000416138--15--spc-20d9858ee1
```

### 从远程 HTTPS 服务提取 TLS 证书，创建 Kubernetes ConfigMap，将证书挂载到容器，动态更新 Deployment
```
### 这段命令链条展示了一个完整流程：从远程 HTTPS 服务提取 TLS 证书 → 创建 Kubernetes ConfigMap → 将证书挂载到容器 → 动态更新 Deployment。它用于让某个服务（如 Authorino）信任一个外部服务（如 Keycloak）的 TLS 证书，实现安全通信。
$ echo quit | openssl s_client -showcerts -servername keycloak-eguzki.apps.dev-eng-ocp4-6-operator.dev.3sca.net -connect keycloak-eguzki.apps.dev-eng-ocp4-6-operator.dev.3sca.net:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > dev-eng-ocp4-6.pem

$ kubectl create configmap ca-pemstore-dev-eng-ocp4-6 --from-file=dev-eng-ocp4-6.pem -n kuadrant-system 

$ cat tls-deployment-patch.yaml
spec:
  template:
    spec:
      containers:
      - name: manager
        volumeMounts:
        - name: ca-pemstore-dev-eng-ocp4-6
          mountPath: /etc/ssl/certs/dev-eng-ocp4-6.pem
          subPath: dev-eng-ocp4-6.pem
          readOnly: false
      volumes:
      - name: ca-pemstore-dev-eng-ocp4-6
        configMap:
          name: ca-pemstore-dev-eng-ocp4-6

$ kubectl patch deployment authorino-controller-manager --type=strategic --patch "$(cat tls-deployment-patch.yaml)" -n kuadrant-system
```

### old vmware tools
https://archive.org/details/winPreVista 
https://archive.org/details/darwin_202204


### Leveraging Fiber Channel Protocol with Trident 25.02 for Persistent Storage on OpenShift 
https://community.netapp.com/t5/Tech-ONTAP-Blogs/Leveraging-Fiber-Channel-Protocol-with-Trident-25-02-for-Persistent-Storage-on/ba-p/460091

### Trident configuration for on prem openshift cluster
https://docs.netapp.com/us-en/netapp-solutions-virtualization/openshift/osv-trident-install.html#trident-configuration-for-on-prem-openshift-cluster

### 配置 NetApp TridentBackendConfig
https://access.redhat.com/articles/7091879#prepare-ocp-nodes-netapp
```
https://access.redhat.com/articles/7091879#prepare-ocp-nodes-netapp
```

### firefox in Podman
https://github.com/grzegorzk/ff_in_podman/tree/main

### run firefox in docker container
https://www.edureka.co/community/66870/how-to-run-firefox-inside-docker-container 
```
### Run xauth list command in your host machine and copy the cookies.
$ xauth list
vm1/unix:0  MIT-MAGIC-COOKIE-1  b4c39c85be9a907749dd9395f4175b0d

### Run docker container with environment variable Display and also mount /tmp/.X11-unix folder to your container.
$ docker run -it --name firefox --net=host -e DISPLAY=$DISPLAY -v /tmp/.X11-unix centos:7 bash

### Install firefox and xauth inside container.
$ yum install firefox xauth

### Add cookies that you copy from your host machine.
$ xauth add <cookies>

### Run firefox inside docker container, it will work.
$ firefox
```

### Run sandboxed Firefox with image and sound inside a container
https://hackweek.opensuse.org/22/projects/run-sandboxde-firefox-with-image-and-sound-inside-a-container
```
### All the DISPLAY, XAUTHORITY stuff allows you to access your X server from the container. Mounting /dev/dri will support the direct rendering interface, avoiding the costly RPC calls.

$ sudo podman run -it --rm -u steph \
         -e DISPLAY=$DISPLAY -e XAUTHORITY=$XAUTHORITY \
         -v /dev/dri:/dev/dri \
         -v /tmp/.X11-unix:/tmp/.X11-unix \
         -v /run/user/1000/gdm:/run/user/1000/gdm \
         -v /run/user/1000/pulse:/var/run/pulse \
         -v ${DOWNLOAD_DIR}:/home/steph/Downloads \
         ${IMAGE} firefox
```

### 检查 iscsi session, logout iscsi session
```
检查有哪些session，从session logout
iscsiadm -m session
iscsiadm -m node -T iqn.2017-09.com.example.ocp4.gpfs:sn.1 -p 192.168.56.78:3260 -u
iscsiadm -m node -T iqn.2025-09.com.example:storage.target01 -p 192.168.56.64:3260 -u
iscsiadm -m session

强制清理iscsi session
iscsiadm -m node -p 192.168.56.78:3260 -T iqn.2017-09.com.example.ocp4.gpfs:sn.1 --op update -n node.startup -v manual
iscsiadm -m node -T iqn.2017-09.com.example.ocp4.gpfs:sn.1 -p 192.168.56.78:3260 -u
iscsiadm -m node -T iqn.2017-09.com.example.ocp4.gpfs:sn.1 -p 192.168.56.78:3260 -o delete


iscsiadm -m node -p 192.168.56.64:3260 -T iqn.2025-09.com.example:storage.target01 --op update -n node.startup -v manual
iscsiadm -m node -T iqn.2025-09.com.example:storage.target01 -p 192.168.56.64:3260 -u
iscsiadm -m node -T iqn.2025-09.com.example:storage.target01 -p 192.168.56.64:3260 -o delete

```

### Fusion Access for SAN Cluster Maintenance Shutting down cluster
```
maintenance shutting down cluster
https://www.ibm.com/docs/en/scalecontainernative/5.2.3?topic=maintenance-shutting-down-cluster
```

### 恢复错误的Fusion Access for SAN FileSystem内容的步骤
```
1. 停止 CNSA operator
oc scale deployment ibm-spectrum-scale-controller-manager  -n ibm-spectrum-scale-operator --replicas=0

2. 编辑webhook
oc edit validatingwebhookconfiguration ibm-spectrum-scale-validating-webhook-configuration -n ibm-spectrum-scale
寻找
  failurePolicy: Fail
  matchPolicy: Equivalent
  name: vfilesystem.scale.spectrum.ibm.com
  namespaceSelector: {}

将 failurePolicy: Fail 修改为 failurePolicy: Ignore
重要: 搜索关键字: vfilesystem.scale.spectrum.ibm.com 不要修改其他 webhook 的 failurePolicy.

3. 从文件系统内删除掉错误的diskname
oc edit filesystem localfilesystem -n ibm-spectrum-scale

4. 将第2步修改的failurePolicy改回Fail

5. 启动CNSA operator
oc scale deployment ibm-spectrum-scale-controller-manager  -n ibm-spectrum-scale-operator --replicas=1
```

### macos上检查有哪些TCP端口被进程LISTEN
```
$ lsof -iTCP -sTCP:LISTEN -n -P

COMMAND     PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
WeChat      721 jwang  150u  IPv4 0xb975f9f9cf86e73d      0t0  TCP 127.0.0.1:14013 (LISTEN)
WeChat      721 jwang  155u  IPv4 0x4df435c6848be83a      0t0  TCP 127.0.0.1:14016 (LISTEN)
WeChat      721 jwang  160u  IPv4 0x3a05d5f489d91140      0t0  TCP 127.0.0.1:14019 (LISTEN)
WeChat      721 jwang  165u  IPv4 0xc191c409b5d9e1b8      0t0  TCP 127.0.0.1:14022 (LISTEN)
WeChat      721 jwang  174u  IPv4 0xe30743a585cfaba1      0t0  TCP 127.0.0.1:14023 (LISTEN)
netdisk_s  1230 jwang   12u  IPv4 0x4bba8c5979af5560      0t0  TCP 127.0.0.1:10000 (LISTEN)
Ollama    11096 jwang    4u  IPv4 0x6436508ef07b22dd      0t0  TCP 127.0.0.1:55894 (LISTEN)
ollama    11098 jwang    4u  IPv4 0x901e90deac2a60dc      0t0  TCP 127.0.0.1:11434 (LISTEN)
ollama    11145 jwang    5u  IPv4 0x9403c35e0069aba9      0t0  TCP 127.0.0.1:56006 (LISTEN)
```

### 本地运行llamastack 
```
# Install uv and start Ollama
ollama run llama3.2:3b --keepalive 60m

# Install server dependencies
uv venv llama-stack
source llama-stack/bin/activate
uv run --with llama-stack llama stack list-deps starter | xargs -L1 uv pip install

# Run Llama Stack server
OLLAMA_URL=http://localhost:11434 uv run --with llama-stack llama stack run starter

# Try the Python SDK
from llama_stack_client import LlamaStackClient

client = LlamaStackClient(
  base_url="http://localhost:8321"
)

response = client.chat.completions.create(
  model="Llama3.2-3B-Instruct",
  messages=[{
    "role": "user",
    "content": "What is machine learning?"
  }]
)
```

### 可以查看vm和vmi的clusterrole，可以启动和停止vm的clusterrole
```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
 name: vm-view-start-stop
rules:
 # --- View permissions (read-only across KubeVirt VM resources) ---
 - apiGroups:
   - kubevirt.io
  resources:
   - virtualmachines
   - virtualmachineinstances
  verbs:
   - get
   - list
   - watch

 # --- Allow start/stop via subresource endpoints ---
 - apiGroups:
   - subresources.kubevirt.io
  resources:
   - virtualmachines/start
   - virtualmachines/stop
  verbs:
   - update
```

### 用plaintext的方式提供openapiv2格式的输出 oc explain pod
```
oc explain pod --output=plaintext-openapiv2 --recursive=true
```

### delete more than 30 days vmsnapshot
```
### 删除大于30天的vmsnapshot

#!/bin/bash
# delete more than 30 days VirtualMachineSnapshot

# 30days timestamp
THRESHOLD_DATE=$(date -d '30 days ago' +%s)

# obtain all namespace VirtualMachineSnapshot
kubectl get vmsnapshots -A -o json | jq -r '.items[] | 
  select(
    (.metadata.creationTimestamp | fromdateiso8601) < '$THRESHOLD_DATE'
  ) | 
  [.metadata.namespace, .metadata.name] | 
  @tsv' | while IFS=$'\t' read -r namespace name; do
    echo "Deleting VirtualMachineSnapshot: $name in namespace: $namespace"
    kubectl delete vmsnapshot "$name" -n "$namespace"
done
```

### CUDN的例子
```
CUDN localnet example
# topoloty: Localnet
# localnet.physicalNetworkName: bridge1-network
# localnet.vlan.mode: Access
# localnet.vlan.access.id: 60
# localnet.role: Secondary
# localnet.ipam.mode: Disable
---
apiVersion: k8s.ovn.org/v1
kind: ClusterUserDefinedNetwork
metadata:
  name: vlan-60
spec:
  # Select namespaces where the Network-Attachment-Definition will be generated
  namespaceSelector:
    matchLabels:
      example.com/vlan-60: "enabled"
  network:
    topology: Localnet
    localnet:
      # Reference the name defined in the NNCP's bridge mapping
      physicalNetworkName: bridge1-network
      # Specify the VLAN ID for traffic segmentation
      vlan:
        mode: Access
        access:
          id: 60
      role: Secondary
      ipam:
        mode: Disabled
```

### 将vhdx的img转换为qcow2格式

```
qemu-img convert -f vhdx -O qcow2 input.vhdx output.qcow2

### Convert a QCOW2, RAW, VMDK or VDI image to VHDX
https://cloudbase.it/qemu-img-windows/

```

### 可查看虚拟机console/vnc，可启动停止重启虚拟机，可列出虚拟机的RBAC
```
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vm-manager-role
rules:
  - verbs:
      - get
    apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachineinstances/console
      - virtualmachineinstances/vnc
  - verbs:
      - update
    apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachines/start
      - virtualmachines/stop
      - virtualmachines/restart
  - verbs:
      - get
      - list
      - watch
    apiGroups:
      - kubevirt.io
    resources:
      - virtualmachines
  - verbs:
      - get
      - list
    apiGroups:
      - config.openshift.io
    resources:
      - '*'
```

### 找到10分钟之内创建的Pod 
```
### 可以用于找到迁移时相关的Pod
oc get pods -A -o json \
  | jq -r '
    .items[]
    | {ns:.metadata.namespace, name:.metadata.name, created:.metadata.creationTimestamp}
    | select((now - ( .created | fromdate )) < 600)
  '

$ oc get pods -A -o json \
  | jq -r '
    .items[]
    | {ns:.metadata.namespace, name:.metadata.name, created:.metadata.creationTimestamp}
    | select((now - ( .created | fromdate )) < 300)
  '
{
  "ns": "openshift-adp",
  "name": "test3-velero-1-kopia-65w6w-maintain-job-1764228878549-wzcd6",
  "created": "2025-11-27T07:34:38Z"
}
{
  "ns": "test4",
  "name": "virt-export-rhel9-jwang-01",
  "created": "2025-11-27T07:31:32Z"
}
{
  "ns": "test5",
  "name": "importer-prime-bb11bf81-ed87-4a06-a2ac-cc1b914ac9a5",
  "created": "2025-11-27T07:32:00Z"
}
{
  "ns": "test5",
  "name": "importer-prime-f9e3c7e9-13fc-4a02-9cae-45b68ce1ef61",
  "created": "2025-11-27T07:31:59Z"
}  
```

### install snap in RHEL 
https://snapcraft.io/docs/installing-snap-on-red-hat
```
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

dnf install -y snapd 
systemctl enable --now snapd
systemctl status snapd

snap install apt-mirror --beta

cat <<'EOF' > /var/snap/apt-mirror/current/mirrorlist
set base_path    /var/spool/apt-mirror
set mirror_path  $base_path/mirror
set skel_path    $base_path/skel
set var_path     $base_path/var
set cleanscript  $var_path/clean.sh
set postmirror_script $var_path/postmirror.sh
set defaultarch  amd64
set run_postmirror 0
set nthreads     20

############# copadata zenon 15 release for Debian 11 (bullseye) #############
deb-amd64 https://repository.copadata.com/zenon/15/release/ bullseye main
deb-arm64 https://repository.copadata.com/zenon/15/release/ bullseye main

############# copadata zenon 15 - Ubuntu 24.04 noble #############
deb-amd64 https://repository.copadata.com/zenon/15/release/ noble main
deb-arm64 https://repository.copadata.com/zenon/15/release/ noble main

clean https://repository.copadata.com/zenon/15/release/
EOF
```

### 检查etcd健康情况
```
oc exec -it -n openshift-etcd etcd-master1.ocp.ap.vwg -- etcdctl endpoint health
https://10.120.88.126:2379 is healthy: successfully committed proposal: took = 56.813904ms
https://10.120.88.125:2379 is healthy: successfully committed proposal: took = 54.294291ms
https://10.120.88.127:2379 is healthy: successfully committed proposal: took = 54.752224ms

oc exec -it -n openshift-etcd etcd-master1.ocp.ap.vwg -- etcdctl member list   
576fe01be62afa42, started, master1.ocp.ap.vwg, https://10.120.88.125:2380, https://10.120.88.125:2379, false
b7d550fb91a1de08, started, master3.ocp.ap.vwg, https://10.120.88.127:2380, https://10.120.88.127:2379, false
ef4840ddfb7e64aa, started, master2.ocp.ap.vwg, https://10.120.88.126:2380, https://10.120.88.126:2379, false
```

### k8s mcp server
```
---
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPServer
metadata:
  name: openshift
spec:
  image: quay.io/containers/kubernetes_mcp_server:latest
  proxyPort: 8000
  mcpPort: 8000
  targetPort: 8000
  transport: sse
  podTemplateSpec:
    spec:
      containers:
      - name: mcp
        command: ["./kubernetes-mcp-server"]
        args:
        - --port
        - "8000"
```

### clone pvc from namespace test4 into namespace openshift-virtualization-os-images w/ DataVolume and ClusterRole/ClusterRoleBinding
```
cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: datavolume-cloner 
rules:
- apiGroups: ["cdi.kubevirt.io"]
  resources: ["datavolumes/source"]
  verbs: ["*"]
EOF

cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: allow-clone-to-user 
  namespace: test4 
subjects:
- kind: ServiceAccount
  name: default
  namespace: openshift-virtualization-os-images 
roleRef:
  kind: ClusterRole
  name: datavolume-cloner 
  apiGroup: rbac.authorization.k8s.io
EOF

cat <<EOF | oc apply -f -
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: rhel-9-4-golden-rbd-from-test4
  namespace: openshift-virtualization-os-images
spec:
  contentType: kubevirt
  source:
    pvc:
      name: rhel-9-4-golden-rbd
      namespace: test4
  storage:
    resources:
      requests:
        storage: 10Gi
    storageClassName: ocs-external-storagecluster-ceph-rbd
EOF
```

### guidellm benchmark 进行模型测试
```
guidellm benchmark run \
  --target "http://127.0.0.1:18080/v1" \
  --model "/model/Qwen3-235B-A22B-Instruct-2507" \
  --rate-type concurrent \
  --rate 10,50,100,150,200,250,300,350,400 \
  --data "prompt_tokens=1500,output_tokens=512" \
  --max-requests 1000
```

### 更新crio_runtimes的ulimit
https://access.redhat.com/solutions/6243491
```
$ cat << EOF | base64 -w0
[crio.runtime]
default_ulimits = [
"nproc=16348:-1",
"stack=1600000:-1"
]
EOF

apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  annotations:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 02-worker-container-runtime
spec:
  config:
    ignition:
      version: 3.1.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,W2NyaW8ucnVudGltZV0KZGVmYXVsdF91bGltaXRzID0gWwoibnByb2M9MTYzNDg6LTEiLAoic3RhY2s9MTYwMDAwMDotMSIKXQo=
        mode: 420
        overwrite: true
        path: /etc/crio/crio.conf.d/10-custom
```

### google用site://<site url> <keyword>的方式在站点搜素solutions
```
site://https://access.redhat.com/solutions recover install-config.yaml
```

### 
```
# 列出macos下网卡顺序
networksetup -listnetworkserviceorder
An asterisk (*) denotes that a network service is disabled.
(1) USB 10/100/1000 LAN
(Hardware Port: USB 10/100/1000 LAN, Device: en6)

(2) USB 10/100/1000 LAN 2
(Hardware Port: USB 10/100/1000 LAN, Device: en7)

(3) USB 10/100/1000 LAN 3
(Hardware Port: USB 10/100/1000 LAN, Device: en10)

(*) USB 10/100/1000 LAN 4
(Hardware Port: USB 10/100/1000 LAN, Device: en12)

(4) Thunderbolt Bridge
(Hardware Port: Thunderbolt Bridge, Device: bridge0)

(5) Wi-Fi
(Hardware Port: Wi-Fi, Device: en0)

(6) iPhone USB
(Hardware Port: iPhone USB, Device: en11)

# macOS 的路由表默认不显示 metric，因为 macOS 不使用 Linux 那种 per‑route metric，而是使用 per‑interface 的 service order（服务顺序）来决定优先级

# macOS 的优先级来自：
#  网络服务顺序（Service Order）
#  接口状态（active / inactive）
#  路由类型（host route > network route > default route）
```
### 在 OpenShift AI 下检查 CUDA Driver Version
```
for pod in $(oc get pods -n nvidia-gpu-operator -o name | grep nvidia-driver-daemonset); do
  node=$(oc get $pod -n nvidia-gpu-operator -o jsonpath='{.spec.nodeName}')
  version=$(oc exec -n nvidia-gpu-operator $pod -c nvidia-driver-ctr -- nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
  echo "$node: Driver $version"
done
```

### Passing the following kernel arguments sets up the static ip
```
Passing the following kernel arguments sets up the static ip
ip=<ipaddress>::<defaultgw>:<netmask>:<hostname>:<iface>:none:<dns server 1>:<dns server 2>

ip=10.120.88.126::10.120.88.1:255.255.255.0:master2.ocp.ap.vwg:ens3:none:10.120.88.123
```

### How to set password for core user in iso itself for Assisted Installer method installation.
https://access.redhat.com/solutions/7073840 
```
# cat change-iso-password.sh 
#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <path to discovery .iso>"
    exit 1
fi

if [[ ! -f $1 ]]; then
    echo "ERROR: Discovery ISO not found at $1"
    exit 1
fi

DISCOVERY_ISO_HOST_PATH="$1"
DISCOVERY_ISO_HOST_DIR=$(dirname "$DISCOVERY_ISO_HOST_PATH")
function COREOS_INSTALLER() {
    podman run -v "$DISCOVERY_ISO_HOST_DIR":/data:Z --rm quay.io/coreos/coreos-installer:release "$@"
}

ISO_NAME=$(basename "$DISCOVERY_ISO_HOST_PATH" .iso)

# Container paths
DISCOVERY_ISO_PATH=/data/${ISO_NAME}.iso
DISCOVERY_ISO_WITH_PASSWORD=/data/${ISO_NAME}_with_password.iso

# Host output path
DISCOVERY_ISO_WITH_PASSWORD_HOST=$(dirname "$DISCOVERY_ISO_HOST_PATH")/$(basename "$DISCOVERY_ISO_WITH_PASSWORD")

# Prompt
read -rsp 'Please enter the password to be used by the "core" user: ' pw
echo ''
USER_PASSWORD=$(openssl passwd -6 --stdin <<<"$pw")
unset pw

# Transform original ignition
TRANSFORMED_IGNITION_PATH=$(mktemp --tmpdir="$DISCOVERY_ISO_HOST_DIR")
TRANSFORMED_IGNITION_NAME=$(basename "$TRANSFORMED_IGNITION_PATH")
COREOS_INSTALLER iso ignition show "$DISCOVERY_ISO_PATH" | jq --arg pass "$USER_PASSWORD" '.passwd.users[0].passwordHash = $pass' >"$TRANSFORMED_IGNITION_PATH"

if [[ -f "$DISCOVERY_ISO_WITH_PASSWORD_HOST" ]]; then
    echo "ERROR: $DISCOVERY_ISO_WITH_PASSWORD_HOST already exists"
    echo "Would you like to overwrite it? [y/N]"
    read -r SHOULD_OVERWRITE
    if [[ "$SHOULD_OVERWRITE" != "y" ]]; then
        echo "Exiting"
        exit 1
    fi
fi

# Generate new ISO
rm -f "$DISCOVERY_ISO_WITH_PASSWORD_HOST"
COREOS_INSTALLER iso customize --output "$DISCOVERY_ISO_WITH_PASSWORD" --force "$DISCOVERY_ISO_PATH" --live-ignition /data/"$TRANSFORMED_IGNITION_NAME"
echo 'Created ISO with your password in "'"$DISCOVERY_ISO_WITH_PASSWORD_HOST"'", the login username is "core"'
```