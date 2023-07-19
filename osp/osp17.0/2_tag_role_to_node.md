### 为节点打标签

```
(undercloud) [stack@undercloud ~]$ openstack baremetal node list
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+
| UUID                                 | Name                | Instance UUID | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+
| 9fcbe99e-a871-4b21-a691-da3c0b1579a8 | overcloud-ctrl01    | None          | power off   | available          | False       |
| e29a1f26-8da0-4ea4-b8f1-d519bcca809c | overcloud-ctrl02    | None          | power off   | available          | False       |
| 5e1d3c77-0c4a-4585-8dc4-52c257214454 | overcloud-ctrl03    | None          | power off   | available          | False       |
| 9d8e3e89-edb5-4757-86bf-b96eb3896666 | overcloud-compute01 | None          | power off   | available          | False       |
| 4a3e168a-5248-4862-be6a-2a84f6265c19 | overcloud-compute02 | None          | power off   | available          | False       |
| 0426ba65-4058-4543-94fe-4bf66b6c1011 | overcloud-ceph01    | None          | power off   | available          | False       |
| ee9377d7-bb1b-48cd-abdf-d27309fbdcc8 | overcloud-ceph02    | None          | power off   | available          | False       |
| d3cb0d59-09de-4364-a14e-3698cf0cc593 | overcloud-ceph03    | None          | power off   | available          | False       |
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+

# 为节点执行角色
# 指定的方式为添加 node:role-index 到 baremetal node 的 properties capabilities 里
# index 从 0 开始
# role 取值为 controller，compute, cephstorage ...
# 备注：rhosp 17.0 - 在 undercloud 不再采用 openstack flavor list 的方式描述 role
# role 的信息可参考 openstack flavor 的 Name 字段
(undercloud) [stack@undercloud ~]$ openstack flavor list
+--------------------------------------+---------------+------+------+-----------+-------+-----------+
| ID                                   | Name          |  RAM | Disk | Ephemeral | VCPUs | Is Public |
+--------------------------------------+---------------+------+------+-----------+-------+-----------+
| 07a38b4c-b7c1-44c0-83bf-386b411a346a | baremetal     | 4096 |   40 |         0 |     1 | True      |
| 1f3fac63-18d8-4e27-bbb9-772fd36eb68f | control       | 4096 |   40 |         0 |     1 | True      |
| 86c09173-48ca-4652-828a-1e90eb7974b9 | compute       | 4096 |   40 |         0 |     1 | True      |
| 95d9cdc2-1a6a-423d-b501-67806023cbcc | block-storage | 4096 |   40 |         0 |     1 | True      |
| e934588d-18db-4b3b-be01-1ac012177381 | ceph-storage  | 4096 |   40 |         0 |     1 | True      |
| f952495c-a348-419a-98e3-ecfb3972f8e1 | swift-storage | 4096 |   40 |         0 |     1 | True      |
+--------------------------------------+---------------+------+------+-----------+-------+-----------+


# 获取节点原来的 properties capabilities
(undercloud) [stack@undercloud ~]$  openstack baremetal node show overcloud-ctrl01 -f json | jq '.properties.capabilities' 
"cpu_aes:true,cpu_hugepages:true,cpu_hugepages_1g:true,cpu_vt:true"

# 在原来的 capabilities 基础上，添加 node:role-index,boot_option:local
# ctrol01 是第一个 controller 
# 添加 node:controller-0
# 同时添加 boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:controller-0,boot_option:local' overcloud-ctrl01

# 用同样的方法为其他 baremetal node 设置 properties capabilities
# 注意调整 role 和 index
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:controller-1,boot_option:local' overcloud-ctrl02
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:controller-2,boot_option:local' overcloud-ctrl03

(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:compute-0,boot_option:local' overcloud-compute01
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:compute-1,boot_option:local' overcloud-compute02

(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:cephstorage-0,boot_option:local' overcloud-ceph01
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:cephstorage-1,boot_option:local' overcloud-ceph02
(undercloud) [stack@undercloud ~]$ openstack baremetal node set --property capabilities='node:cephstorage-2,boot_option:local' overcloud-ceph03
```
