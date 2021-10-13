```
# 设置 NFS 备份目标，备份将保存在这个位置
# 创建目录，设置目录权限
[root@base-pvg ~]# mkdir /ctl_plane_backups
[root@base-pvg ~]# chmod 775 /ctl_plane_backups

# 配置 nfs 共享
[root@base-pvg ~]# cat >> /etc/exports <<EOF
/ctl_plane_backups 192.168.122.0/24(rw,sync,no_root_squash,no_subtree_check)
EOF

# 启用 nfs 服务
[root@base-pvg ~]# systemctl start nfs-server
[root@base-pvg ~]# exportfs -a

# 检查 nfs 输出
[root@base-pvg ~]# showmount -e localhost

# 在 undercloud 上安装 ReaR
# 创建 ansible inventory
(undercloud) [stack@undercloud ~]$ source ~/stackrc 
(undercloud) [stack@undercloud ~]$ tripleo-ansible-inventory --ansible_ssh_user heat-admin --static-yaml-inventory ~/tripleo-inventory.yaml
# 生成的 inventory 文件保存在 ~/tripleo-inventory.yaml 文件里

# 生成备份 playbook
(undercloud) [stack@undercloud ~]$ cat <<'EOF' > ~/undercloud_bar_rear_setup.yaml
# Playbook
# We install and configure ReaR in the control plane nodes
# As they are the only nodes we will like to backup now.
- become: true
  hosts: Undercloud
  name: Install ReaR
  roles:
  - role: backup-and-restore
EOF

# 设置 ReaR 使用 NFS 作为备份目标
(undercloud) [stack@undercloud ~]$ ansible-playbook -v -i ~/tripleo-inventory.yaml --extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" --become --become-user root --tags bar_setup_rear --extra="tripleo_backup_and_restore_nfs_server=192.168.122.1" ~/undercloud_bar_rear_setup.yaml

# 执行备份
(undercloud) [stack@undercloud ~]$ ansible-playbook \
	-v -i ~/tripleo-inventory.yaml \
	--extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
	--become \
	--become-user root \
	--tags bar_create_recover_image \
	~/undercloud_bar_rear_setup.yaml

# 使用备份恢复 undercloud 
[root@base-pvg ~]# virsh destroy jwang-rhel84-undercloud
[root@base-pvg ~]# mv /data/kvm/jwang-rhel84-undercloud.qcow2 /data/kvm/jwang-rhel84-undercloud.qcow2.original

# 创建空白硬盘
[root@base-pvg ~]# qemu-img create -f qcow2 /data/kvm/jwang-rhel84-undercloud.qcow2 120G

# 设置文件权限
[root@base-pvg ~]# chmod 775 /ctl_plane_backups/undercloud/
[root@base-pvg ~]# chmod 664 /ctl_plane_backups/undercloud/undercloud.example.com.iso

# detach-disk 然后 attach-disk
[root@base-pvg ~]# virsh detach-disk jwang-rhel84-undercloud /root/jwang/isos/rhel-8.4-x86_64-dvd.iso --persistent --config
[root@base-pvg ~]# virsh attach-disk jwang-rhel84-undercloud /ctl_plane_backups/undercloud/undercloud.example.com.iso hda --type cdrom --mode readonly --config

# 启动 undercloud 虚拟机，选择通过 DVD 启动，使用 ReaR 恢复虚拟机
```