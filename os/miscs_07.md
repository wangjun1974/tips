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