```
# 备份及恢复控制节点
# OSP 16.1 文档参见
# https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html/undercloud_and_control_plane_back_up_and_restore/creating-a-backup-of-the-undercloud-and-control-plane-nodes_osp-ctlplane-br

# 生成 playbook, playbook 可在 overcloud controller 节点上安装 ReaR
(undercloud) [stack@undercloud ~]$ cat <<'EOF' > ~/overcloud_bar_rear_setup.yaml
# Playbook
# We install and configure ReaR in the control plane nodes
# As they are the only nodes we will like to backup now.
- become: true
  hosts: ceph_mon
  name: Backup ceph authentication
  tasks:
    - name: Backup ceph authentication role
      include_role:
        name: backup-and-restore
        tasks_from: ceph_authentication
      tags:
      -  bar_create_recover_image
- become: true
  hosts: Controller
  name: Create the recovery images for the control plane
  roles:
  - role: backup-and-restore
EOF

# 为 overcloud controller 配置 yum repo
(undercloud) [stack@undercloud ~]$ ansible -i ~/tripleo-inventory.yaml --become --become-user root -m copy -a "src=/etc/yum.repos.d/osp.repo dest=/etc/yum.repos.d/osp.repo" Controller

# 为 overcloud controller 安装 ReaR，并且设置备份目标
(undercloud) [stack@undercloud ~]$ ansible-playbook \
	-v -i ~/tripleo-inventory.yaml \
	--extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
	--become \
	--become-user root \
	--tags bar_setup_rear \
	--extra="tripleo_backup_and_restore_nfs_server=192.0.2.254" \
	~/overcloud_bar_rear_setup.yaml
...
PLAY RECAP ************************************************************************************************************************************************
overcloud-controller-0     : ok=12   changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
overcloud-controller-1     : ok=12   changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
overcloud-controller-2     : ok=12   changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
 
# 创建 overcloud controller 备份，如果可能的话建议采用另外一种方法创建备份
# 这种方法会先停止所有服务，执行备份，然后再恢复服务
(undercloud) [stack@undercloud ~]$ ansible-playbook \
	-v -i ~/tripleo-inventory.yaml \
	--extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
	--become \
	--become-user root \
	--tags bar_create_recover_image \
	~/overcloud_bar_rear_setup.yaml

# 这种方法会创建 snapshot，基于 snapshot 进行备份，备份过程中不会停止服务，应该优选这种方法进行备份
# 涉及的变量：https://docs.openstack.org/tripleo-ansible/latest/roles/role-backup_and_restore.html
(undercloud) [stack@undercloud ~]$ ansible-playbook \
	-v -i ~/tripleo-inventory.yaml \
	--extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
	--become \
	--become-user root \
	--tags bar_create_recover_image \
	--extra="tripleo_container_cli=podman" \
	--extra="tripleo_backup_and_restore_service_manager=false" \
	~/overcloud_bar_rear_setup.yaml 

(undercloud) [stack@undercloud ~]$ ansible-playbook \
	-v -i ~/tripleo-inventory.yaml \
	--extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
	--become \
	--become-user root \
	--tags bar_create_recover_image \
	--extra="tripleo_container_cli=podman" \
	--extra="tripleo_backup_and_restore_service_manager=false" \
	~/overcloud_bar_rear_setup.yaml --limit=overcloud-controller-0 2>&1 | tee /tmp/err1 

# 备份的内容
[root@base-pvg rhv44]# ls -ltr /ctl_plane_backups/overcloud-controller-0/ /ctl_plane_backups/overcloud-controller-1/ /ctl_plane_backups/overcloud-controller-2/
total 5423664
-rw-------. 1 root root  269152256 Mar  8 17:49 overcloud-controller-2.example.com.iso
-rw-------. 1 root root        291 Mar  8 17:49 VERSION
-rw-------. 1 root root        202 Mar  8 17:49 README
-rw-------. 1 root root     744289 Mar  8 17:49 rear-overcloud-controller-2.log
-rw-------. 1 root root 5199606206 Mar  8 18:26 backup.tar.gz
-rw-------. 1 root root   84299568 Mar  8 18:26 backup.log
-rw-------. 1 root root          0 Mar  8 18:26 selinux.autorelabel

/ctl_plane_backups/overcloud-controller-1/:
total 5484856
-rw-------. 1 root root  269154304 Mar  8 17:49 overcloud-controller-1.example.com.iso
-rw-------. 1 root root        291 Mar  8 17:49 VERSION
-rw-------. 1 root root        202 Mar  8 17:49 README
-rw-------. 1 root root     743969 Mar  8 17:49 rear-overcloud-controller-1.log
-rw-------. 1 root root 5262282067 Mar  8 18:26 backup.tar.gz
-rw-------. 1 root root   84294078 Mar  8 18:26 backup.log
-rw-------. 1 root root          0 Mar  8 18:27 selinux.autorelabel

/ctl_plane_backups/overcloud-controller-0/:
total 5450000
-rw-------. 1 root root  269148160 Mar  8 17:49 overcloud-controller-0.example.com.iso
-rw-------. 1 root root        291 Mar  8 17:49 VERSION
-rw-------. 1 root root        202 Mar  8 17:49 README
-rw-------. 1 root root     744042 Mar  8 17:49 rear-overcloud-controller-0.log
-rw-------. 1 root root 5226558396 Mar  8 18:27 backup.tar.gz
-rw-------. 1 root root   84320078 Mar  8 18:27 backup.log
-rw-------. 1 root root          0 Mar  8 18:27 selinux.autorelabel

# 模拟 overcloud-controller-0 出现故障，尝试恢复 overcloud-controller-0 
[root@base-pvg rhv44]# virsh list
 Id    Name                           State
----------------------------------------------------
 132   jwang-helper-undercloud        running
 133   jwang-rhel82-undercloud        running
 137   jwang-overcloud-ceph01         running
 138   jwang-overcloud-ceph02         running
 139   jwang-overcloud-ceph03         running

# 关闭虚拟机 jwang-overcloud-ceph01
[root@base-pvg rhv44]# virsh destroy jwang-overcloud-ceph01 

# 备份虚拟机磁盘
[root@base-pvg rhv44]# mv /data/kvm/jwang-overcloud-ceph01.qcow2 /data/kvm/jwang-overcloud-ceph01.qcow2.orignal
[root@base-pvg rhv44]# mv /data/kvm/jwang-overcloud-ceph01-storage-1.qcow2 /data/kvm/jwang-overcloud-ceph01-storage-1.qcow2.orignal
[root@base-pvg rhv44]# mv /data/kvm/jwang-overcloud-ceph01-storage-2.qcow2 /data/kvm/jwang-overcloud-ceph01-storage-2.qcow2.original
[root@base-pvg rhv44]# mv /data/kvm/jwang-overcloud-ceph01-storage-3.qcow2 /data/kvm/jwang-overcloud-ceph01-storage-3.qcow2.original

# 新建虚拟机磁盘
[root@base-pvg ~]# qemu-img create -f qcow2 /data/kvm/jwang-overcloud-ceph01.qcow2 100G
[root@base-pvg ~]# qemu-img create -f qcow2 /data/kvm/jwang-overcloud-ceph01-storage-1.qcow2 100G
[root@base-pvg ~]# qemu-img create -f qcow2 /data/kvm/jwang-overcloud-ceph01-storage-2.qcow2 100G
[root@base-pvg ~]# qemu-img create -f qcow2 /data/kvm/jwang-overcloud-ceph01-storage-3.qcow2 100G

# 设置权限，为虚拟机添加 cdrom，使用 overcloud-controller-0.example.com.iso 作为 cdrom 的镜像
[root@base-pvg ~]# chmod 775 /ctl_plane_backups/overcloud-controller-0/
[root@base-pvg ~]# chmod 664 /ctl_plane_backups/overcloud-controller-0/overcloud-controller-0.example.com.iso
[root@base-pvg ~]# virsh attach-disk jwang-overcloud-ceph01 /ctl_plane_backups/overcloud-controller-0/overcloud-controller-0.example.com.iso hda --type cdrom --mode readonly --config

# 启动虚拟机，选择通过 DVD 启动，使用 ReaR 恢复虚拟机


```

根据链接里的步骤替换 osd<br>
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.0/html/deploying_an_overcloud_with_containerized_red_hat_ceph/replacing_a_failed_disk<br>
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html-single/deploying_an_overcloud_with_containerized_red_hat_ceph/index#ensuring-osd-down-and-destroyed<br>
```
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd tree 
Warning: Permanently added 'overcloud-controller-0.ctlplane' (ECDSA) to the list of known hosts.
ID CLASS WEIGHT  TYPE NAME                       STATUS REWEIGHT PRI-AFF 
-1       0.87918 root default                                            
-5       0.29306     host overcloud-controller-0                         
 0   hdd 0.09769         osd.0                     down        0 1.00000 
 3   hdd 0.09769         osd.3                     down        0 1.00000 
 6   hdd 0.09769         osd.6                     down        0 1.00000 
-3       0.29306     host overcloud-controller-1                         
 1   hdd 0.09769         osd.1                       up  1.00000 1.00000 
 4   hdd 0.09769         osd.4                       up  1.00000 1.00000 
 7   hdd 0.09769         osd.7                       up  1.00000 1.00000 
-7       0.29306     host overcloud-controller-2                         
 2   hdd 0.09769         osd.2                       up  1.00000 1.00000 
 5   hdd 0.09769         osd.5                       up  1.00000 1.00000 
 8   hdd 0.09769         osd.8                       up  1.00000 1.00000 

# 模版里采用的是 by-path 的方式，因此新替换的磁盘的路径并没有改变
[heat-admin@overcloud-controller-0 ~]$ sudo ls /dev/disk/by-path/ -l 
...
lrwxrwxrwx. 1 root root  9 Mar  9 07:50 virtio-pci-0000:00:09.0 -> ../../vdb
lrwxrwxrwx. 1 root root  9 Mar  9 07:50 virtio-pci-0000:00:0a.0 -> ../../vdc
lrwxrwxrwx. 1 root root  9 Mar  9 07:50 virtio-pci-0000:00:0b.0 -> ../../vdd

[heat-admin@overcloud-controller-0 ~]$ sudo lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
vda    253:0    0  100G  0 disk 
vda1 253:1    0    1M  0 part 
vda2 253:2    0  100G  0 part /
vdb    253:16   0  100G  0 disk 
vdc    253:32   0  100G  0 disk 
vdd    253:48   0  100G  0 disk 

# 设置环境变量 MON
[heat-admin@overcloud-controller-0 ~]$ MON=$(sudo podman ps | grep ceph-mon | awk {'print $1'})

# 设置 alias ceph
alias ceph="sudo podman exec $MON ceph"

# 确认想替换的 osd 状态为 down
[heat-admin@overcloud-controller-0 ~]$ ceph osd tree | grep osd.0
 0   hdd 0.09769         osd.0                     down        0 1.00000 
[heat-admin@overcloud-controller-0 ~]$ ceph osd tree | grep osd.3
 3   hdd 0.09769         osd.3                     down        0 1.00000 
[heat-admin@overcloud-controller-0 ~]$ ceph osd tree | grep osd.6
 6   hdd 0.09769         osd.6                     down        0 1.00000 

# destroy osd
[heat-admin@overcloud-controller-0 ~]$ ceph osd destroy 0 --yes-i-really-mean-it 
destroyed osd.0
[heat-admin@overcloud-controller-0 ~]$ ceph osd destroy 3 --yes-i-really-mean-it 
destroyed osd.3
[heat-admin@overcloud-controller-0 ~]$ ceph osd destroy 6 --yes-i-really-mean-it 
destroyed osd.6

# 停止服务
[heat-admin@overcloud-controller-0 ~]$ sudo systemctl stop ceph-osd@0
[heat-admin@overcloud-controller-0 ~]$ sudo systemctl stop ceph-osd@3
[heat-admin@overcloud-controller-0 ~]$ sudo systemctl stop ceph-osd@6

# 设置环境变量 IMG，指向 ceph 镜像 id
IMG=$(sudo podman images | grep ceph | awk {'print $3'})

# 设置 alias ceph-volume 
alias ceph-volume="sudo podman run --rm --privileged --net=host --ipc=host -v /run/lock/lvm:/run/lock/lvm:z -v /var/run/udev/:/var/run/udev/:z -v /dev:/dev -v /etc/ceph:/etc/ceph:z -v /var/lib/ceph/:/var/lib/ceph/:z -v /var/log/ceph/:/var/log/ceph/:z --entrypoint=ceph-volume $IMG --cluster ceph"

# 确认 alias ceph-volume 可正常执行
[heat-admin@overcloud-controller-0 ~]$ ceph-volume lvm list
No valid Ceph lvm devices found

# 检查新磁盘，确认新磁盘设备不属于 vg 和 lvm
[heat-admin@overcloud-controller-0 ~]$ sudo pvdisplay /dev/disk/by-path/virtio-pci-0000:00:09.0
  Failed to find physical volume "/dev/vdb".
[heat-admin@overcloud-controller-0 ~]$ sudo pvdisplay /dev/disk/by-path/virtio-pci-0000:00:0a.0
  Failed to find physical volume "/dev/vdc".
[heat-admin@overcloud-controller-0 ~]$ sudo pvdisplay /dev/disk/by-path/virtio-pci-0000:00:0b.0
  Failed to find physical volume "/dev/vdd".

# 确认新的 osd 设备被清理
[heat-admin@overcloud-controller-0 ~]$ ceph-volume lvm zap /dev/disk/by-path/virtio-pci-0000:00:09.0
[heat-admin@overcloud-controller-0 ~]$ ceph-volume lvm zap /dev/disk/by-path/virtio-pci-0000:00:0a.0
[heat-admin@overcloud-controller-0 ~]$ ceph-volume lvm zap /dev/disk/by-path/virtio-pci-0000:00:0b.0

# 创建新 osd 仍使用旧的 id，传递参数 --no-systemd，在容器内需要这个参数
[heat-admin@overcloud-controller-0 ~]$ ceph-volume lvm create --osd-id 0 --data /dev/disk/by-path/virtio-pci-0000:00:09.0 --no-systemd
[heat-admin@overcloud-controller-0 ~]$ ceph-volume lvm create --osd-id 3 --data /dev/disk/by-path/virtio-pci-0000:00:0a.0 --no-systemd
[heat-admin@overcloud-controller-0 ~]$ ceph-volume lvm create --osd-id 6 --data /dev/disk/by-path/virtio-pci-0000:00:0b.0 --no-systemd

# 启动 osd systemd 服务
[heat-admin@overcloud-controller-0 ~]$ sudo systemctl start ceph-osd@0
[heat-admin@overcloud-controller-0 ~]$ sudo systemctl start ceph-osd@3
[heat-admin@overcloud-controller-0 ~]$ sudo systemctl start ceph-osd@6

# 等待一段时间，数据将同步到新恢复的 osd 上
```


```
# 问题定位及解决
# 执行备份时，任务 TASK backup-and-restore : MySQL Grants backup 在 overcloud-controller-0 上报错
# 调整 /usr/share/ansible/roles/backup-and-restore/backup/tasks/db_backup.yml 里的 TASK 
# 注释掉 no_log，可以获得详细的报错信息
TASK [backup-and-restore : MySQL Grants backup] ***********************************************************************************************************
fatal: [overcloud-controller-0]: FAILED! => {"changed": true, "cmd": "set -o pipefail\npodman exec e709be998990\n0ab97a9a531e bash -c \"mysql -uroot \\\n-p65vjyAaI7a -s -N \\\n-e \\\"SELECT CONCAT('\\\\\\\"SHOW GRANTS FOR ''',user,'''@''',host,''';\\\\\\\"') \\\nFROM mysql.user where (length(user) > 0 and user NOT LIKE 'root')\\\"  | xargs -n1 mysql \\\n-uroot -p65vjyAaI7a -s -N -e | sed 's/$/;/' \" > openstack-backup-mysql-grants.sql\n", "delta": "0:00:00.196657", "end": "2021-03-08 06:57:14.562541", "msg": "non-zero return code", "rc": 127, "start": "2021-03-08 06:57:14.365884", "stderr": "Error: you must provide a command to exec\n/bin/sh: line 2: 0ab97a9a531e: command not found", "stderr_lines": ["Error: you must provide a command to exec", "/bin/sh: line 2: 0ab97a9a531e: command not found"], "stdout": "", "stdout_lines": []}

(undercloud) [stack@undercloud openstack-tripleo-common]$ cat /usr/share/ansible/roles/backup-and-restore/backup/tasks/db_backup.yml  | grep Grants -A11
- name: MySQL Grants backup
  shell: |
    set -o pipefail
    {{ tripleo_container_cli }} exec {{ tripleo_backup_and_restore_mysql_container }} bash -c "mysql -uroot \
    -p{{ mysql_password.stdout }} -s -N \
    -e \"SELECT CONCAT('\\\"SHOW GRANTS FOR ''',user,'''@''',host,''';\\\"') \
    FROM mysql.user where (length(user) > 0 and user NOT LIKE 'root')\"  | xargs -n1 mysql \
    -uroot -p{{ mysql_password.stdout }} -s -N -e | sed 's/$/;/' " > openstack-backup-mysql-grants.sql
  when: mysql_password.stderr is defined
  tags:
    - bar_create_recover_image
  #no_log: "{{ not ((ansible_verbosity | int) >= 2) | bool }}"

# overcloud-controller-0 有两个容器，一个运行，一个非运行
(undercloud) [stack@undercloud openstack-tripleo-common]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman ps -a | grep -E "e709be998990|ab97a9a531e" 
Warning: Permanently added 'overcloud-controller-0.ctlplane' (ECDSA) to the list of known hosts.
e709be998990  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-mariadb:16.1                     /bin/bash /usr/lo...  3 days ago  Up 3 days ago                 galera-bundle-podman-1
0ab97a9a531e  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-mariadb:16.1                     /bin/bash /usr/lo...  6 days ago  Created                       galera-bundle-podman-0

# 删除掉非运行的容器
# 重新执行 overcloud controller 备份 playbook
(undercloud) [stack@undercloud openstack-tripleo-common]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman rm 0ab97a9a531e  
Warning: Permanently added 'overcloud-controller-0.ctlplane' (ECDSA) to the list of known hosts.
0ab97a9a531e47cb5ca528ad7480f8770c82a248b497a9fedc4f29493e648182

# 查看备份进度
watch -n5 "ssh -t heat-admin@overcloud-controller-0.ctlplane 'sudo dmesg|tail -5 '"
...
[278157.683638] SELinux: mount invalid.  Same superblock, different security settings for (dev mqueue, type mqueue)
[278164.449129] SELinux: mount invalid.  Same superblock, different security settings for (dev mqueue, type mqueue)
[278171.627351] SELinux: mount invalid.  Same superblock, different security settings for (dev mqueue, type mqueue)
[278179.729586] SELinux: mount invalid.  Same superblock, different security settings for (dev mqueue, type mqueue)
[278187.613258] SELinux: mount invalid.  Same superblock, different security settings for (dev mqueue, type mqueue)
...
# 等待消息 SELinux: mount invalid.  Same superblock, different security settings for (dev mqueue, type mqueue) 不再出现
# 这个消息属于无害消息，参见https://access.redhat.com/solutions/3348951
# SELinux is attempting to mount the mqueue device inside of the container with a different label then the host, but /dev/mqueue is shared on the host. Since there is an existing label the kernel logs this warning.
# Bug 1425278 - "SELinux: mount invalid. Same superblock, different security settings for (dev mqueue, type mqueue)" error message in logs https://bugzilla.redhat.com/show_bug.cgi?id=1425278


ssh heat-admin@overcloud-controller-0.ctlplane "sudo podman ps -a | grep Paused "  | awk '{print $1}' | while read i ; do ssh heat-admin@overcloud-controller-0.ctlplane echo "sudo podman resume $i" </dev/null ; done

ssh heat-admin@overcloud-controller-1.ctlplane "sudo podman ps -a | grep Paused "  | awk '{print $1}' | while read i ; do ssh heat-admin@overcloud-controller-1.ctlplane echo "sudo podman resume $i" </dev/null ; done

ssh heat-admin@overcloud-controller-2.ctlplane "sudo podman ps -a | grep Paused "  | awk '{print $1}' | while read i ; do ssh heat-admin@overcloud-controller-2.ctlplane echo "sudo podman resume $i" </dev/null ; done

ssh heat-admin@overcloud-controller-1.ctlplane "sudo podman ps -a | grep Paused "

# 记录时间
Mar  8 09:23:04

# 执行命令
sudo pcs resource cleanup haproxy-bundle

# 查看日志
sudo cat /var/log/messages | grep -i haproxy -A5 | grep "Mar  8 09:23" | more
...
Mar  8 09:23:47 overcloud-controller-2 pacemaker-attrd[3524]: notice: Setting fail-count-haproxy-bundle-podman-2#start_0[overcloud-controller-2]: INFINITY 
-> (unset)
Mar  8 09:23:47 overcloud-controller-2 pacemaker-attrd[3524]: notice: Setting last-failure-haproxy-bundle-podman-2#start_0[overcloud-controller-2]: 1615193
583 -> (unset)
Mar  8 09:23:47 overcloud-controller-2 pacemaker-controld[3527]: notice: State transition S_IDLE -> S_POLICY_ENGINE
Mar  8 09:23:48 overcloud-controller-2 pacemaker-schedulerd[3525]: warning: Forcing haproxy-bundle-podman-2 away from overcloud-controller-2 after 1000000 
failures (max=1000000)
Mar  8 09:23:48 overcloud-controller-2 pacemaker-schedulerd[3525]: notice: Calculated transition 39, saving inputs in /var/lib/pacemaker/pengine/pe-input-1
29.bz2
Mar  8 09:23:49 overcloud-controller-2 pacemaker-schedulerd[3525]: notice:  * Start      haproxy-bundle-podman-2              (                           o
vercloud-controller-2 )
Mar  8 09:23:49 overcloud-controller-2 pacemaker-controld[3527]: notice: Initiating monitor operation haproxy-bundle-podman-2_monitor_0 locally on overclou
d-controller-2
Mar  8 09:23:49 overcloud-controller-2 pacemaker-schedulerd[3525]: notice: Calculated transition 40, saving inputs in /var/lib/pacemaker/pengine/pe-input-1
30.bz2
Mar  8 09:23:49 overcloud-controller-2 pacemaker-controld[3527]: notice: Result of probe operation for haproxy-bundle-podman-2 on overcloud-controller-2: 7
 (not running)
Mar  8 09:23:49 overcloud-controller-2 pacemaker-controld[3527]: notice: Initiating start operation haproxy-bundle-podman-2_start_0 locally on overcloud-co
ntroller-2
Mar  8 09:23:50 overcloud-controller-2 podman(haproxy-bundle-podman-2)[209240]: INFO: running container haproxy-bundle-podman-2 for the first time
Mar  8 09:23:50 overcloud-controller-2 podman(haproxy-bundle-podman-2)[209240]: ERROR: Error: error creating container storage: the container name "haproxy
-bundle-podman-2" is already in use by "8138ca222c93069a907e7d246cde1c9fe9d6fe7d3e8222639cc499515cb78323". You have to remove that container to be able to reuse that name.: that name is already in use
...

# 尝试强制删除 orphan 容器存储 
sudo podman rm --force --storage 8138ca222c93069a907e7d246cde1c9fe9d6fe7d3e8222639cc499515cb78323

# 清理资源
sudo pcs resource cleanup haproxy-bundle
```


```
# 问题定位
# 报错信息：Error: Failed to evict container: "": Failed to find container "ceph-osd->
[heat-admin@overcloud-controller-2 ~]$ sudo systemctl status ceph-osd@2 
 ceph-osd@2.service - Ceph OSD
   Loaded: loaded (/etc/systemd/system/ceph-osd@.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2021-03-15 06:06:09 UTC; 6s ago
  Process: 138889 ExecStop=/usr/bin/sh -c /usr/bin/podman rm -f `cat //run/ceph-osd@2.service-cid` (code=exited, status=0/SUCCESS)
  Process: 140487 ExecStart=/usr/bin/podman run -d --conmon-pidfile //run/ceph-osd@2.service-pid --cidfile //run/ceph-osd@2.service-cid --rm>
  Process: 140448 ExecStartPre=/usr/bin/podman rm -f ceph-osd-2 (code=exited, status=1/FAILURE)
  Process: 140446 ExecStartPre=/usr/bin/rm -f //run/ceph-osd@2.service-pid //run/ceph-osd@2.service-cid (code=exited, status=0/SUCCESS)
 Main PID: 140554 (conmon)
    Tasks: 0 (limit: 101097)
   Memory: 2.6M
   CGroup: /system.slice/system-ceph\x2dosd.slice/ceph-osd@2.service
            140554 /usr/bin/conmon --api-version 1 -s -c 1e414cfae0f2beb8cd26739ed5810d61a12e9708cbd44d01eca304696934caf0 -u 1e414cfae0f2be>

                                                                                                                                           Mar 15 06:06:07 overcloud-controller-2.example.com systemd[1]: Starting Ceph OSD...
Mar 15 06:06:08 overcloud-controller-2.example.com podman[140448]: "ceph-osd-2" in state: no container with name or ID ceph-osd-2 found: no such container
Mar 15 06:06:08 overcloud-controller-2.example.com podman[140487]: 2021-03-15 06:06:08.712547413 +0000 UTC m=+0.487205666 container create 1>
Mar 15 06:06:09 overcloud-controller-2.example.com podman[140487]: 2021-03-15 06:06:09.075508809 +0000 UTC m=+0.850167731 container init 1e4>
Mar 15 06:06:09 overcloud-controller-2.example.com podman[140487]: 2021-03-15 06:06:09.129490349 +0000 UTC m=+0.904148712 container start 1e>
Mar 15 06:06:09 overcloud-controller-2.example.com podman[140487]: 1e414cfae0f2beb8cd26739ed5810d61a12e9708cbd44d01eca304696934caf0
Mar 15 06:06:09 overcloud-controller-2.example.com systemd[1]: Started Ceph OSD.

# https://bugzilla.redhat.com/show_bug.cgi?id=1834179&GoAheadAndLogIn=1
# Bug 1834179 - Error: cluster is not available on this node, overcloud reboot failed
2021-03-15 06:21:39.040 7f8362bb5dc0  0 osd.5 265 using weightedpriority op queue with priority op cut off at 64.
2021-03-15 06:21:39.042 7f8362bb5dc0 -1 osd.5 265 log_to_monitors {default=true}
2021-03-15 06:21:39.053 7f834c0f9700 -1 monclient: _check_auth_rotating possible clock skew, rotating keys expired way too early (before 2021-03-15 05:21:39.054640)
2021-03-15 06:21:49.042 7f8349724700 -1 monclient: _check_auth_rotating possible clock skew, rotating keys expired way too early (before 2021-03-15 05:21:49.043414)

# 可能类似的问题，但是并不确定 https://tracker.ceph.com/issues/23460
# 最终的解决方法是重新将 3 个节点重新启动，最终恢复

# 
(undercloud) [stack@undercloud ~]$ ssh heat-admin@overcloud-controller-0.ctlplane sudo podman exec -it ceph-mon-overcloud-controller-0 ceph status 
Warning: Permanently added 'overcloud-controller-0.ctlplane' (ECDSA) to the list of known hosts.
  cluster:
    id:     765cff5c-012e-4871-9d19-cf75eaf27769
    health: HEALTH_WARN
            178 pgs not deep-scrubbed in time
 
  services:
    mon: 3 daemons, quorum overcloud-controller-0,overcloud-controller-1,overcloud-controller-2 (age 101s)
    mgr: overcloud-controller-0(active, since 67s), standbys: overcloud-controller-2, overcloud-controller-1
    osd: 9 osds: 9 up (since 48s), 9 in (since 59s)
    rgw: 3 daemons active (overcloud-controller-0.rgw0, overcloud-controller-1.rgw0, overcloud-controller-2.rgw0)
 
  task status:
 
  data:
    pools:   7 pools, 896 pgs
    objects: 612 objects, 3.0 GiB
    usage:   18 GiB used, 881 GiB / 900 GiB avail
    pgs:     896 active+clean

```