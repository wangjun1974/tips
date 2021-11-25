### WIP
### DCN 架构说明
### 例子
### 参考架构 
https://www.youtube.com/watch?v=bsQ-ORy37wk

### 实验环境
```

[stack@undercloud ~]$ source stackrc 
(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+---------------------------+--------+-------------------------+----------------+---------------+
| ID                                   | Name                      | Status | Networks                | Image          | Flavor        |
+--------------------------------------+---------------------------+--------+-------------------------+----------------+---------------+
| 912e98bc-5017-4f42-ac0b-21eb47369ecc | dcn0-distributedcompute-0 | ACTIVE | ctlplane=192.168.100.74 | overcloud-full | baremetal     |
| c35a55ca-2674-40e5-8f27-230ad2437a88 | overcloud-controller-1    | ACTIVE | ctlplane=192.168.10.34  | overcloud-full | control0      |
| 88d4e123-1c2a-424e-9fed-0b482d064a11 | overcloud-controller-0    | ACTIVE | ctlplane=192.168.10.41  | overcloud-full | control0      |
| 780cf114-cb27-4819-97c6-340101961524 | overcloud-controller-2    | ACTIVE | ctlplane=192.168.10.48  | overcloud-full | control0      |
| 07e70b7c-962d-4172-9083-ba527abfe64e | overcloud-novacompute2-0  | ACTIVE | ctlplane=192.168.12.70  | overcloud-full | compute_leaf2 |
| e7f9fced-ba7c-4947-87c1-c345ad93d5b1 | overcloud-novacompute0-0  | ACTIVE | ctlplane=192.168.10.43  | overcloud-full | compute_leaf0 |
| 35284eb6-fe16-4b9a-a381-a6ea9882b240 | overcloud-novacompute1-0  | ACTIVE | ctlplane=192.168.11.77  | overcloud-full | compute_leaf1 |
+--------------------------------------+---------------------------+--------+-------------------------+----------------+---------------+

# 这个环境包含 spine-leaf 网络架构部署
# undercloud.conf 启用了 enable_routed_networks
# undercloud 定义了以下 subnets  
# leaf0, leaf1, leaf2 和 az1
# undercloud 和 overcloud 控制节点对应的 local_subnet 是 leaf0
(undercloud) [stack@undercloud ~]$ cat undercloud.conf 
[DEFAULT]
overcloud_domain_name = example.com
container_images_file = /home/stack/containers-prepare-parameter.yaml
generate_service_certificate = false
certificate_generation_ca = local
clean_nodes = false
enable_ui = true
local_ip = 192.168.10.10/24
undercloud_public_vip = 192.168.10.11
undercloud_admin_vip = 192.168.10.12
local_interface = nic1
enable_routed_networks = true
subnets = leaf0,leaf1,leaf2,az1
local_subnet = leaf0 

[auth]

[leaf0]
cidr = 192.168.10.0/24
dhcp_start = 192.168.10.20
dhcp_end = 192.168.10.90
inspection_iprange = 192.168.10.100,192.168.10.190
gateway = 192.168.10.1
masquerade = False

[leaf1]
cidr = 192.168.11.0/24
dhcp_start = 192.168.11.20
dhcp_end = 192.168.11.90
inspection_iprange = 192.168.11.100,192.168.11.190
gateway = 192.168.11.253
masquerade = False

[leaf2]
cidr = 192.168.12.0/24
dhcp_start = 192.168.12.20
dhcp_end = 192.168.12.90
inspection_iprange = 192.168.12.100,192.168.12.190
gateway = 192.168.12.253
masquerade = False

[az1]
cidr = 192.168.100.0/24
dhcp_start = 192.168.100.20
dhcp_end = 192.168.100.90
inspection_iprange = 192.168.100.100,192.168.100.190
gateway = 192.168.100.1
masquerade = False

# 这个环境包含两个部署
# overcloud 和 dcn0
# overcloud 是 spine-leaf 网络架构的部署 - 代表中心机房或区域机房的 osp
# dcn0 代表 1 个拉远部署
(undercloud) [stack@undercloud ~]$ openstack stack list
+--------------------------------------+------------+----------------------------------+-----------------+----------------------+--------------+
| ID                                   | Stack Name | Project                          | Stack Status    | Creation Time        | Updated Time |
+--------------------------------------+------------+----------------------------------+-----------------+----------------------+--------------+
| 64eedaf9-775c-41f7-8903-810780cef2fa | dcn0       | 8877abea66e04144af606b8ce548d2b3 | CREATE_COMPLETE | 2021-01-13T18:52:14Z | None         |
| b302c995-96b4-47cc-884e-6650221d3589 | overcloud  | 8877abea66e04144af606b8ce548d2b3 | CREATE_COMPLETE | 2021-01-13T14:05:29Z | None         |
+--------------------------------------+------------+----------------------------------+-----------------+----------------------+--------------+

# 中央站点部署脚本 
# role_data 模版为 roles_data_spine_leaf.yaml 
# network_data 模版为 network_data_spine_leaf.yaml
# 其他的模版文件包括
# environments/network-environment.yaml
# node-config.yaml

(undercloud) [stack@undercloud ~]$ cat ~/bin/overcloud-deploy.sh 
#!/bin/bash

THT=/usr/share/openstack-tripleo-heat-templates
CNF=~/templates

openstack overcloud deploy --templates \
-r $CNF/roles_data_spine_leaf.yaml \
-n $CNF/network_data_spine_leaf.yaml \
-e $THT/environments/network-isolation.yaml \
-e $THT/environments/disable-telemetry.yaml \
-e $THT/environments/low-memory-usage.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/node-config.yaml \
-e ~/containers-prepare-parameter.yaml

# DCN 部署脚本
(undercloud) [stack@undercloud ~]$ cat dcn0/deploy-dcn.sh 
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates
STACK=dcn0
source ~/stackrc
#     -e $THT/environments/network-isolation.yaml \
time openstack overcloud deploy \
     --stack $STACK \
     --templates /usr/share/openstack-tripleo-heat-templates/ \
     -r roles_data.yaml \
     -n network_data_spine_leaf.yaml \
     -e ~/dcn-common/central-export.yaml \
     -e site-name.yaml \
     -e dcn0-images-env.yaml \
     -e ~/containers-prepare-parameter.yaml \
     -e network-environment.yaml \
     -e network-environment-dcn.yaml \
     -e overrides.yaml
```