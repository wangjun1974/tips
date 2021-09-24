
### Prometheus Alert Rules and AlertManager Alert Route
https://zhuanlan.zhihu.com/p/179295676<br>

Sending email with the Alertmanager via Gmail<br>
https://www.robustperception.io/sending-email-with-the-alertmanager-via-gmail<br>

自定义Prometheus告警规则<br>
https://yunlzheng.gitbook.io/prometheus-book/parti-prometheus-ji-chu/alert/prometheus-alert-rule<br>

PromQL 快速入门<br>
https://www.cnblogs.com/chanshuyi/p/04_quick_start_of_promql.html<br>

Prometheus 中文文档<br>
https://www.prometheus.wang/<br>

### Grafana Dashboard
grafana增加dashboard图形<br>
https://blog.csdn.net/weixin_44953658/article/details/114585357<br>

### tripleo error 
```
podman ps -a --filter label=container_name=heat_engine_db_sync --filter label=config_id=tripleo_step3 --format '{{.Names}}'
    "stderr": "Error executing ['podman', 'container', 'exists', 'heat_engine_db_sync']: returned 1\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=heat_engine_db_sync', '--filter', 'label=config_id=tripleo_step3', '--format', '{{.Names}}']\" - retrying without config_id\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=heat_engine_db_sync', '--format', '{{.Names}}']\"\nError executing ['podman', 'container', 'exists', 'ovn_dbs_init_bundle']: returned 1\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=ovn_dbs_init_bundle', '--filter', 'label=config_id=tripleo_step3', '--format', '{{.Names}}']\" - retrying without config_id\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=ovn_dbs_init_bundle', '--format', '{{.Names}}']\"\nError executing ['podman', 'container', 'exists', 'glance_api_db_sync']: returned 1\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=glance_api_db_sync', '--filter', 'label=config_id=tripleo_step3', '--format', '{{.Names}}']\" - retrying without config_id\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=glance_api_db_sync', '--format', '{{.Names}}']\"\nError executing ['podman', 'container', 'exists', 'keystone_db_sync']: returned 1\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=keystone_db_sync', '--filter', 'label=config_id=tripleo_step3', '--format', '{{.Names}}']\" - retrying without config_id\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=keystone_db_sync', '--format', '{{.Names}}']\"\nError executing ['podman', 'container', 'exists', 'neutron_db_sync']: returned 1\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=neutron_db_sync', '--filter', 'label=config_id=tripleo_step3', '--format', '{{.Names}}']\" - retrying without config_id\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=neutron_db_sync', '--format', '{{.Names}}']\"\nError executing ['podman', 'container', 'exists', 'cinder_api_db_sync']: returned 1\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=cinder_api_db_sync', '--filter', 'label=config_id=tripleo_step3', '--format', '{{.Names}}']\" - retrying without config_id\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'label=container_name=cinder_api_db_sync', '--format', '{{.Names}}']\"\nError executing ['podman', 'container', 'exists', 'ironic_db_sync']: returned 1\nDid not find container with \"['podman', 'ps', '-a', '--filter', 'lab

找到异常退出的容器
[root@overcloud-controller-0 ~]# podman ps -a | grep -Ev "Exited \(0|Up " 
CONTAINER ID  IMAGE                                                                                 COMMAND               CREATED         STATUS                      PORTS  NAMES
efae7f8b3719  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-ironic-inspector:16.1      curl -g -o /var/l...  15 minutes ago  Exited (18) 15 minutes ago         ironic_inspector_get_ipa
80573b71c975  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-ironic-inspector:16.1      kolla_start           18 hours ago    Exited (1) 18 hours ago            ironic_inspector_dnsmasq

检查异常退出容器的日志，以下这个错误是由于执行 curl -g -o 命令获取 IronicImageUrls 里的镜像时异常退出了
实际上这个错误不是一个非常重要的错误，但是仍然导致部署失败了
[root@overcloud-controller-0 ~# podman logs efae7f8b3719 
curl: (18) transfer closed with 6152549 bytes remaining to rea
curl: (18) transfer closed with 562895056 bytes rema
curl (http://172.16.4.14:8088/agent.kernel): response: 200, time: 0.009665, size: 2771979
curl (http://172.16.4.14:8088/agent.ramdisk): response: 200, time: 0.087707, size: 327680

出错的步骤在以下文件里
(overcloud) [stack@undercloud tmp]$ cat /usr/share/openstack-tripleo-heat-templates/deployment/ironic/ironic-inspector-container-puppet.yaml
...
              ironic_inspector_get_ipa:
                start_order: 3
                image: *ironic_inspector_image
                net: host
                user: root
                privileged: false
                detach: false
                volumes:
                  list_concat:
                    - {get_attr: [ContainersCommon, volumes]}
                    -
                      - /var/lib/kolla/config_files/ironic_inspector.json:/var/lib/kolla/config_files/config.json:ro
                      - /var/lib/ironic:/var/lib/ironic:shared,z
                environment:
                  KOLLA_CONFIG_STRATEGY: COPY_ALWAYS
                command:
                  if:
                   - ipa_images
                   - list_join:
                       - " "
                       - - "curl -g -o /var/lib/ironic/httpboot/agent.kernel"
                         - {get_param: [IPAImageURLs, 0]}
                         - "-o /var/lib/ironic/httpboot/agent.ramdisk"
                         - {get_param: [IPAImageURLs, 1]}
                   - 'true'


另外的报错
(overcloud) [stack@undercloud ~]$ openstack baremetal introspection start --wait $(openstack baremetal node show baremetal-node0 -f value -c uuid)
Waiting for introspection to finish...
Unable to establish connection to http://192.168.122.16:5050/v1/introspection/a6d00ee7-cb32-4db5-be20-de7f4bdeb9c9: ('Connection aborted.', RemoteDisconnected('Remote end closed connection without response',))

希望部署或者更新时都可以调整 overcloud 节点网络配置
https://access.redhat.com/solutions/2213711
希望部署或者更新时都可以调整 overcloud 节点网络配置，可以在 templates/environments/network-environments.yaml 文件里添加 NetworkDeploymentActions 的设置
  NetworkDeploymentActions: ['CREATE','UPDATE']

经过检查，在已经配置好 ovs bond 的计算节点上，上面的配置是没有办法把 ovs_bridge 下的 ovs_bond 拆掉变成不使用 ovs_bond 的配置
```

### RHV 上传镜像
```
# RHV 上传镜像
prog=/usr/bin/engine-iso-uploader
mypass="xxxxxx"

args="-i ISO11 upload rhel-8.4-x86_64-dvd.iso --force"
/usr/bin/expect <<EOF
set timeout -1
spawn "$prog" $args
expect "Please provide the REST API password for the admin@internal oVirt Engine user (CTRL+D to abort): "
send "$mypass\r"
expect eof
exit
EOF

args="-i ISO11 upload /tmp/vmlinuz-rhel-8.4 --force"
/usr/bin/expect <<EOF
set timeout -1
spawn "$prog" $args
expect "Please provide the REST API password for the admin@internal oVirt Engine user (CTRL+D to abort): "
send "$mypass\r"
expect eof
exit
EOF

args="-i ISO11 upload /tmp/initrd.img-rhel-8.4 --force"
/usr/bin/expect <<EOF
set timeout -1
spawn "$prog" $args
expect "Please provide the REST API password for the admin@internal oVirt Engine user (CTRL+D to abort): "
send "$mypass\r"
expect eof
exit
EOF

# 在 RHV 环境下使用 kickstart 安装虚拟机
# https://access.redhat.com/solutions/300713

kernel path ISO11://vmlinuz-rhel-8.4
initrd path ISO11://initrd.img-rhel-8.4
kernel parameters  ks=http://10.66.208.115/ks-undercloud.cfg ksdevice=ens3 ip=10.66.208.121 netmask=255.255.255.0 dns=10.64.63.6 gateway=10.66.208.254

```

### rhosp 16.2 同步软件
```
使用 subscription-manager 注册节点
$ sudo subscription-manager register

查找 Red Hat OpenStack Platform 16.2 的 entitlement pool
$ sudo subscription-manager list --available --all --matches="Red Hat OpenStack"

使用 subscription-manager 为节点添加包含 Red Hat OpenStack Platform 16.2 entitlement pool 
$ sudo subscription-manager attach --pool=pool_id

为节点禁用所有 repos
$ sudo subscription-manager repos --disable=*

为节点启用如下 repos
$ sudo subscription-manager repos --enable=rhel-8-for-x86_64-baseos-eus-rpms --enable=rhel-8-for-x86_64-appstream-eus-rpms --enable=rhel-8-for-x86_64-highavailability-eus-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms --enable=openstack-16.2-for-rhel-8-x86_64-rpms --enable=advanced-virt-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms --enable=rhel-8-for-x86_64-nfv-rpms

```