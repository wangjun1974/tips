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

(undercloud) [stack@undercloud ~]$ ansible-playbook \
	-v -i ~/tripleo-inventory.yaml \
	--extra="ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
	--become \
	--become-user root \
	--tags bar_create_recover_image \
	--extra="tripleo_container_cli=podman" \
	--extra="tripleo_backup_and_restore_service_manager=false" \
	~/overcloud_bar_rear_setup.yaml --limit=overcloud-controller-0 2>&1 | tee /tmp/err1 

backup-and-restore : MySQL Grants backup

```



```
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


```