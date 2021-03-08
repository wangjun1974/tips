```
# 备份及恢复控制节点

# 生成 playbook, playbook 可在 overcloud controller 节点上安装 ReaR
(undercloud) [stack@undercloud ~]$ cat <<'EOF' > ~/overcloud_bar_rear_setup.yaml
# Playbook
# We install and configure ReaR in the control plane nodes
# As they are the only nodes we will like to backup now.
- become: true
  hosts: Controller
  name: Install ReaR
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
	--extra="tripleo_backup_and_restore_nfs_server=192.168.122.1" \
	~/overcloud_bar_rear_setup.yaml
...
PLAY RECAP ************************************************************************************************************************************************
overcloud-controller-0     : ok=12   changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
overcloud-controller-1     : ok=12   changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
overcloud-controller-2     : ok=12   changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

# 创建 overcloud controller 备份
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
```