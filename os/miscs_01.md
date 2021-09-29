
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

Grafana 中文入门教程 | 构建你的第一个仪表盘<br>
https://cloud.tencent.com/developer/article/1807679<br>

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

对于 RHEL 8.4 来说，一些启动参数改变了，需要注意修改一下
ks= 变成了 inst.ks=
ksdevice= 变成了 inst.ksdevice=
dns= 变成了 nameserver=

kernel path ISO11://vmlinuz-rhel-8.4
initrd path ISO11://initrd.img-rhel-8.4
kernel parameters  inst.ks=http://10.66.208.115/ks-undercloud.cfg inst.ksdevice=ens3 ip=10.66.208.121 netmask=255.255.255.0 nameserver=10.64.63.6 gateway=10.66.208.254

kernel path ISO11://vmlinuz-rhel-8.4
initrd path ISO11://initrd.img-rhel-8.4
kernel parameters  inst.ks=http://10.66.208.115/ks-helper.cfg inst.ksdevice=ens3 ip=10.66.208.125 netmask=255.255.255.0 nameserver=10.64.63.6 gateway=10.66.208.254
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

### Tripleo 的模版文件
禁用 swift 的 tripleo yaml 文件<br>
https://github.com/openstack/tripleo-heat-templates/blob/stable/train/environments/disable-swift.yaml

设置 glance 使用 cinder 作为 backend 时，如果 cinder 自身也有多个 backend，可通过设置 cinder_volume_type 指定使用某个 cinder backend。tripleo 的设置参见以下模版<br>
https://github.com/openstack/tripleo-heat-templates/blob/master/deployment/glance/glance-api-container-puppet.yaml#L588


### systemctl status <pid>
如何查询某个 pid 进程属于哪个 systemd 服务，可以用命令 'systemctl status <pid>' 来检查
https://trstringer.com/pid-find-owning-systemd-unit/<br>
```
# systemctl status 1550 
* NetworkManager.service - Network Manager
   Loaded: loaded (/usr/lib/systemd/system/NetworkManager.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2021-09-18 13:37:03 CST; 5 days ago
     Docs: man:NetworkManager(8)
 Main PID: 1480 (NetworkManager)
    Tasks: 4
   CGroup: /system.slice/NetworkManager.service
           |-1480 /usr/sbin/NetworkManager --no-daemon
           `-1550 /usr/sbin/dnsmasq --no-resolv --keep-in-foreground --no-hosts --bind-interfaces --pid-file=/var/run/NetworkManager/dnsmas...

Sep 24 11:22:41 base-pvg.redhat.ren NetworkManager[1480]: <info>  [1632453761.9975] dhcp4 (br1): canceled DHCP transaction, DHCP clie... 19958
Sep 24 11:22:41 base-pvg.redhat.ren NetworkManager[1480]: <info>  [1632453761.9975] dhcp4 (br1): state changed timeout -> done
Sep 24 11:22:41 base-pvg.redhat.ren NetworkManager[1480]: <info>  [1632453761.9979] device (br1): state change: ip-config -> failed (...aged')
Sep 24 11:22:41 base-pvg.redhat.ren NetworkManager[1480]: <warn>  [1632453761.9991] device (br1): Activation: failed for connection 'br1'
Sep 24 11:22:42 base-pvg.redhat.ren NetworkManager[1480]: <info>  [1632453762.0135] device (br1): detached bridge port em1.20
Sep 24 11:22:42 base-pvg.redhat.ren NetworkManager[1480]: <info>  [1632453762.0157] device (em1.20): state change: activated -> deact...aged')
Sep 24 11:22:42 base-pvg.redhat.ren NetworkManager[1480]: <info>  [1632453762.0183] device (br1): state change: failed -> disconnecte...aged')
Sep 24 11:22:42 base-pvg.redhat.ren NetworkManager[1480]: <info>  [1632453762.0581] device (br1): state change: disconnected -> unman...aged')
Sep 24 11:22:42 base-pvg.redhat.ren NetworkManager[1480]: <info>  [1632453762.0604] device (em1.20): state change: deactivating -> di...aged')
Sep 24 11:22:42 base-pvg.redhat.ren NetworkManager[1480]: <info>  [1632453762.0851] device (em1.20): state change: disconnected -> un...ag

安装 CodeReady Container 之后，crc 会设置 NetworkManager 做本地域名解析，会与其他 DNS 设置冲突

cat > /etc/yum.repos.d/local.repo <<EOF
[rhel-server-8.4-baseos]
name=rhel-server-8.4-baseos
baseurl=file:///mnt/BaseOS
enable=1
gpgcheck=0

[rhel-server-8.4-appstream]
name=rhel-server-8.4-appstream
baseurl=file:///mnt/AppStream
enable=1
gpgcheck=0

EOF

yum makecache
```

### 使用 rhsm-cli 下载文件
访问 https://access.redhat.com/management/api 生成用于通过 API 访问 CDN 的 Token.

运行 rhsm-cli 容器，获得文件的 checksum，然后用 checksum 下载文件
```
podman run -it -v `pwd`:/Downloads brezhnev/rhsm-cli images -t $TOKEN --cheksum $CHECKSUM
```

### 从 Red Hat Access CDN 下载文件
```
Download boot ISO from command line
https://access.redhat.com/solutions/2083653 

cat > download.sh <<EOF
wget \
  --no-check-certificate \
  --certificate=/etc/pki/entitlement/12345.pem \
  --private-key=/etc/pki/entitlement/12345-key.pem \
  --ca-certificate=/etc/rhsm/ca/redhat-entitlement-authority.pem \
  https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/iso/rhel-server-7.9-x86_64-dvd.iso
EOF
```

### OpenShift Virtualization 下自动化安装 Windows 虚拟机
https://cloud.redhat.com/blog/automatic-installation-of-a-windows-vm-using-openshift-virtualization

### AMQ Interconnect
```
AMQ Interconnect 梳理

openstack controller 节点的 metrics_qdr 的配置文件
[heat-admin@overcloud-controller-0 ~]$ sudo podman exec -it metrics_qdr /bin/sh
()[qdrouterd@overcloud-controller-0 /]$ cat /etc/qpid-dispatch/qdrouterd.conf
##
## Licensed to the Apache Software Foundation (ASF) under one
## or more contributor license agreements.  See the NOTICE file
## distributed with this work for additional information
## regarding copyright ownership.  The ASF licenses this file
## to you under the Apache License, Version 2.0 (the
## "License"); you may not use this file except in compliance
## with the License.  You may obtain a copy of the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing,
## software distributed under the License is distributed on an
## "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
## KIND, either express or implied.  See the License for the
## specific language governing permissions and limitations
## under the License
##

# See the qdrouterd.conf (5) manual page for information about this
# file's format and options.

router {
    mode: edge
    id: Router.overcloud-controller-0.localdomain
    workerThreads: 2
    debugDump: /var/log/qdrouterd
    saslConfigPath: /etc/sasl2
    saslConfigName: qdrouterd
}

sslProfile {
    name: sslProfile
}


listener {
    host: 172.16.2.168
    port: 5666
    authenticatePeer: no
    saslMechanisms: ANONYMOUS
}


connector {
    host: default-interconnect-5671-service-telemetry.apps.ocp1.rhcnsa.com
    port: 443
    role: edge
    sslProfile: sslProfile
    verifyHostname: false
}


address {
    prefix: unicast
    distribution: closest
}

address {
    prefix: exclusive
    distribution: closest
}

address {
    prefix: broadcast
    distribution: multicast
}

address {
    distribution: multicast
    prefix: collectd
}

address {
    distribution: multicast
    prefix: anycast/ceilometer
}



log {
   module: DEFAULT
   enable: info+
   timestamp: true
   output: /var/log/qdrouterd/metrics_qdr.log
}


openstack compute 节点的 metrics_qdr 的配置文件
[heat-admin@overcloud-novacompute-0 ~]$ sudo podman exec -it metrics_qdr /bin/sh
##
## Licensed to the Apache Software Foundation (ASF) under one
## or more contributor license agreements.  See the NOTICE file
## distributed with this work for additional information
## regarding copyright ownership.  The ASF licenses this file
## to you under the Apache License, Version 2.0 (the
## "License"); you may not use this file except in compliance
## with the License.  You may obtain a copy of the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing,
## software distributed under the License is distributed on an
## "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
## KIND, either express or implied.  See the License for the
## specific language governing permissions and limitations
## under the License
##

# See the qdrouterd.conf (5) manual page for information about this
# file's format and options.

router {
    mode: edge
    id: Router.overcloud-novacompute-0.localdomain
    workerThreads: 2
    debugDump: /var/log/qdrouterd
    saslConfigPath: /etc/sasl2
    saslConfigName: qdrouterd
}


sslProfile {
    name: sslProfile
}


listener {
    host: 172.16.2.158
    port: 5666
    authenticatePeer: no
    saslMechanisms: ANONYMOUS
}


connector {
    host: default-interconnect-5671-service-telemetry.apps.ocp1.rhcnsa.com
    port: 443
    role: edge
    sslProfile: sslProfile
    verifyHostname: false
}


address {
    prefix: unicast
    distribution: closest
}

address {
    prefix: exclusive
    distribution: closest
}

address {
    prefix: broadcast
    distribution: multicast
}

address {
    distribution: multicast
    prefix: collectd
}

address {
    distribution: multicast
    prefix: anycast/ceilometer
}



log {
   module: DEFAULT
   enable: info+
   timestamp: true
   output: /var/log/qdrouterd/metrics_qdr.log
}


16.1 下 metrics_qdr 的 qpid-dispatch-router 的版本为 1.8.0
[heat-admin@overcloud-controller-0 ~]$ sudo podman exec -it metrics_qdr /bin/sh
()[qdrouterd@overcloud-controller-0 /]$ rpm -qa | grep qpid
python3-qpid-proton-0.32.0-2.el8.x86_64
qpid-dispatch-router-1.8.0-2.el8.x86_64
qpid-proton-c-0.32.0-2.el8.x86_64
qpid-dispatch-tools-1.8.0-2.el8.noarch

AMQ Interconnect 文档
https://access.redhat.com/documentation/en-us/red_hat_amq/7.6/html-single/using_amq_interconnect/index#connecting-routers-router-rhel

OpenShift STF 这边的 qpid-dispatch-router 的配置
##
## Licensed to the Apache Software Foundation (ASF) under one
## or more contributor license agreements.  See the NOTICE file
## distributed with this work for additional information
## regarding copyright ownership.  The ASF licenses this file
## to you under the Apache License, Version 2.0 (the
## "License"); you may not use this file except in compliance
## with the License.  You may obtain a copy of the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing,
## software distributed under the License is distributed on an
## "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
## KIND, either express or implied.  See the License for the
## specific language governing permissions and limitations
## under the License
##

# See the qdrouterd.conf (5) manual page for information about this
# file's format and options.

router {
    mode: standalone
}

listener {
    host: 0.0.0.0
    port: amqp
    authenticatePeer: no
    saslMechanisms: ANONYMOUS
}

listener {
    host: 0.0.0.0
    port: 8672
    authenticatePeer: no
    http: yes
}

address {
    prefix: closest
    distribution: closest
}

address {
    prefix: multicast
    distribution: multicast
}

address {
    prefix: unicast
    distribution: closest
}

address {
    prefix: exclusive
    distribution: closest
}

address {
    prefix: broadcast
    distribution: multicast
}


amq interconnect 的 troubleshooting 
https://access.redhat.com/documentation/en-us/red_hat_amq/7.5/html/using_amq_interconnect/troubleshooting-router-rhel


qdrouterd.conf man page
https://www.systutorials.com/docs/linux/man/5-qdrouterd.conf/

编辑 qdrouterd 日志级别为 debug+
[root@overcloud-novacompute-0 qpid-dispatch]# cat /var/lib/config-data/puppet-generated/metrics_qdr/etc/qpid-dispatch/qdrouterd.conf 
...
log {
   module: DEFAULT
   enable: debug+
   timestamp: true
   output: /var/log/qdrouterd/metrics_qdr.log
}

重启 metrics_qdr 容器
[root@overcloud-novacompute-0 qpid-dispatch]# podman restart metrics_qdr 

报错信息

2021-09-26 04:19:22.477561 +0000 SERVER (info) [C1] Connection to default-interconnect-5671-service-telemetry.apps.ocp1.rhcnsa.com:443 failed: proton:io Name or service not known - connect to  default-interconnect-5671-service-telemetry.apps.ocp1.rhcnsa.com:443


compute node collectd pod
[root@overcloud-novacompute-0 qpid-dispatch]# podman logs c5795bd8a664
...
++ cat /run_command
+ CMD='/usr/sbin/collectd -f'
+ ARGS=
+ sudo kolla_copy_cacerts
+ [[ ! -n '' ]]
+ . kolla_extend_start
++ [[ ! -d /var/log/kolla/collectd ]]
+++ stat -c %a /var/log/kolla/collectd
++ [[ 2755 != \7\5\5 ]]
++ chmod 755 /var/log/kolla/collectd
Running command: '/usr/sbin/collectd -f'
+ echo 'Running command: '\''/usr/sbin/collectd -f'\'''
+ exec /usr/sbin/collectd -f
[2021-09-26 04:31:03] plugin_load: plugin "logfile" successfully loaded.
Error: Parsing the config file failed!

日志文件
[root@overcloud-novacompute-0 collectd]# ls -1F /var/lib/config-data/puppet-generated/collectd/etc/collectd.d/ 
05-logfile.conf
10-amqp1.conf
10-cpu.conf
10-df.conf
10-disk.conf
10-exec.conf
10-hugepages.conf
10-interface.conf
10-load.conf
10-memory.conf
10-processes.conf
10-python.conf
10-unixsock.conf
10-uptime.conf
10-virt.conf
10-vmem.conf
exec-config.conf
libpodstats.conf
processes_config.conf
python-config.conf

[root@overcloud-novacompute-0 collectd]# cat /var/log/containers/collectd/collectd.log
[2021-09-26 04:31:03] plugin_load: plugin "amqp1" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "cpu" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "df" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "disk" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "exec" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "hugepages" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "interface" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "load" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "memory" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "processes" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "python" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "unixsock" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "uptime" successfully loaded.
[2021-09-26 04:31:03] plugin_load: plugin "virt" successfully loaded.
[2021-09-26 04:31:03] virt plugin: unknown HostnameFormat field: name uuid hostname
[2021-09-26 04:31:03] plugin_load: plugin "vmem" successfully loaded.
[2021-09-26 04:31:03] UNKNOWN plugin: plugin_get_interval: Unable to determine Interval from context.
[2021-09-26 04:31:03] plugin_load: plugin "libpodstats" successfully loaded.

controller 的 collectd 配置文件
[root@overcloud-controller-0 collectd]# cat etc/collectd.conf 
# Generated by Puppet

#Hostname localhost
FQDNLookup true

AutoLoadPlugin false
#BaseDir "/var/lib/collectd"
#PluginDir "/usr/lib/collectd"
TypesDB "/usr/share/collectd/types.db" "/usr/share/collectd/types.db.libpodstats"
Interval 60
Timeout 2
ReadThreads 5
WriteThreads 5
Include "/etc/collectd.d/*.conf"

compute 的 collectd 配置文件
# Generated by Puppet

#Hostname localhost
FQDNLookup true

AutoLoadPlugin false
#BaseDir "/var/lib/collectd"
#PluginDir "/usr/lib/collectd"
TypesDB "/usr/share/collectd/types.db" "/usr/share/collectd/types.db.libpodstats"
Interval 60
Timeout 2
ReadThreads 5
WriteThreads 5
Include "/etc/collectd.d/*.conf"

controller 的 etc/collectd.d/ 下的文件
[root@overcloud-controller-0 collectd]# ls etc/collectd.d/ -1F 
05-logfile.conf
10-amqp1.conf
10-cpu.conf
10-df.conf
10-disk.conf
10-exec.conf
10-hugepages.conf
10-interface.conf
10-load.conf
10-memcached.conf
10-memory.conf
10-processes.conf
10-python.conf
10-unixsock.conf
10-uptime.conf
10-vmem.conf
exec-config.conf
libpodstats.conf
processes_config.conf
python-config.conf

compute 的 etc/collectd.d/ 下的文件 
05-logfile.conf
10-amqp1.conf
10-cpu.conf
10-df.conf
10-disk.conf
10-exec.conf
10-hugepages.conf
10-interface.conf
10-load.conf
10-memory.conf
10-processes.conf
10-python.conf
10-unixsock.conf
10-uptime.conf
10-virt.conf
10-vmem.conf
exec-config.conf
libpodstats.conf
processes_config.conf
python-config.conf

compute 的 etc/collectd.d/10-virt.conf 的内容
# Generated by Puppet
<LoadPlugin virt>
  Globals false
</LoadPlugin>

<Plugin virt>
  Connection "qemu:///system"
  HostnameFormat "name metadata hostname"
  ExtraStats "pcpu cpu_util vcpupin vcpu memory disk disk_err disk_allocation disk_capacity disk_physical domain_state job_stats_background perf"
</Plugin>

就是 HostnameFormat "name metadata hostname" 造成计算节点 collectd 容器无法启动的
将这行注释后执行 podman restart collectd，计算节点 collectd 容器就启动起来了

```

### 改变 IPA admin password
https://manastri.blogspot.com/2020/04/how-to-reset-freeipa-admin-admin.html<br>
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_identity_management/managing-dns-forwarding-in-idm_configuring-and-managing-idm<br>
```
export LDAPTLS_CACERT=/etc/ipa/ca.crt
ldappasswd -ZZ -D 'cn=directory manager' -W -S uid=admin,cn=users,cn=accounts,dc=example,dc=com -H ldap://ipa.example.com

# 设置全局 dns forwarder
ipa dnsconfig-mod --forwarder=114.114.114.114

# 查询 dns 配置
ipa dnsconfig-show
```

Training url
https://etherpad-gpte-etherpad.apps.shared-na4.na4.openshift.xxxxxxx.com/p/oc-27sep-prakhar

```
echo 'openshift:redhat' | base64

cat > pullsecret_config.json <<EOF
{"auths": {"utilityvm.example.com:5000": {"auth": "b3BlbnNoaWZ0OnJlZGhhdA==","email": "noemail@localhost"}}}
EOF

jq '.auths += {"utilityvm.example.com:5000": {"auth": "b3BlbnNoaWZ0OnJlZGhhdAo=","email": "noemail@localhost"}}' < ocp_pullsecret.json > merged_pullsecret.json

[lab-user@bastion ~]$ jq -s '.[0] * .[1]' ocp_pullsecret.json pullsecret_config.json > merged_pullsecret.json 

[lab-user@bastion ~]$ echo -n 'openshift:redhat' | base64 -w0
b3BlbnNoaWZ0OnJlZGhhdAo=
cat > pullsecret_config.json <<EOF
{
  "auths": {
    "utilityvm.example.com:5000": {
      "auth": "b3BlbnNoaWZ0OnJlZGhhdA==",
      "email": "noemail@localhost"
    }
  }  
}
EOF

podman login --authfile ./pullsecret_config.json utilityvm.example.com:5000 
Authenticating with existing credentials...
Existing credentials are invalid, please enter valid username and password


export LOCAL_REGISTRY='utilityvm.example.com:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export RELEASE_NAME='ocp-release'
export ARCHITECTURE="x86_64"
export LOCAL_SECRET_JSON="${HOME}/merged_pullsecret.json"

oc adm release info quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE}-x86_64

oc adm -a ${LOCAL_SECRET_JSON} release mirror \
--from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}

sha256:08acf7a2d1bd9a021ebf5138822c5816ee3bb9d8ba179b7d8144b92260ed5239 utilityvm.example.com:5000/ocp4/openshift4:4.6.15-csi-external-provisioner
info: Mirroring completed in 57.06s (120.1MB/s)

Success
Update image:  utilityvm.example.com:5000/ocp4/openshift4:4.6.15-x86_64
Mirror prefix: utilityvm.example.com:5000/ocp4/openshift4

To use the new mirrored repository to install, add the following section to the install-config.yaml:

imageContentSources:
- mirrors:
  - utilityvm.example.com:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - utilityvm.example.com:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev


To use the new mirrored repository for upgrades, use the following to create an ImageContentSourcePolicy:

apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: example
spec:
  repositoryDigestMirrors:
  - mirrors:
    - utilityvm.example.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - utilityvm.example.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev

podman pull --authfile $HOME/pullsecret_config.json utilityvm.example.com:5000/ocp4/openshift4:$OCP_RELEASE-operator-lifecycle-manager

oc adm release info -a ${LOCAL_SECRET_JSON} "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}" | head -n 18

oc adm release info -a ${LOCAL_SECRET_JSON} "quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE}" | head -n 18

oc adm release extract -a ${LOCAL_SECRET_JSON} --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}"

ls -l



setup network
nmcli con mod 'eth0' ipv4.method 'manual' ipv4.address '10.66.xxx.xxx/24' ipv4.gateway '10.66.xxx.xxx' ipv4.dns '127.0.0.1 10.xx.xx.xx' ipv4.dns-search 'cluster-0001.rhsacn.org'
nmcli con down 'eth0' && nmcli con up 'eth0'

hostnamectl set-hostname helper.cluster-0001.rhsacn.org

sed -i '/^10.66.xxx.xxx helper.cluster-0001.rhsacn.org*/d' /etc/hosts

cat >> /etc/hosts << 'EOF'
10.66.xxx.xxx helper.cluster-0001.rhsacn.org
EOF
setup repo
mkdir -p /etc/yum.repos.d/backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup

cat > /etc/yum.repos.d/w.repo << 'EOF'
[rhel-7-server-rpms]
name=rhel-7-server-rpms
baseurl=http://10.66.xxx.xxx/rhel7osp/rhel-7-server-rpms/
enabled=1
gpgcheck=0

[rhel-7-server-extras-rpms]
name=rhel-7-server-extras-rpms
baseurl=http://10.66.xxx.xxx/rhel7osp/rhel-7-server-extras-rpms/
enabled=1
gpgcheck=0


[rhel-7-server-ansible-2.9-rpms]
name=rhel-7-server-ansible-2.9-rpms
baseurl=http://10.66.xxx.xxx/rhel9osp/rhel-7-server-ansible-2.9-rpms/
enabled=1
gpgcheck=0

EOF
update system and reboot
yum -y update 
reboot
setup time service
cat > /etc/chrony.conf << 'EOF'
server $(ip a s dev eth0 | grep "inet " | awk '{print $2}' | sed -e 's|/24||' ) iburst
bindaddress $(ip a s dev eth0 | grep "inet " | awk '{print $2}' | sed -e 's|/24||' )
allow all
local stratum 4
EOF

systemctl enable chronyd && systemctl start chronyd 

chronyc -n sources
chronyc -n tracking

systemctl enable firewalld && systemctl start firewalld

firewall-cmd --permanent --add-service ntp
firewall-cmd --reload
setup helper node
yum -y install ansible git
git clone https://github.com/RedHatOfficial/ocp4-helpernode
cd ocp4-helpernode
generate vars.yml
cat > vars.yml << EOF
---
staticips: true
helper:
  name: "helper"
  ipaddr: "10.66.208.138"
  networkifacename: "eth0"
dns:
  domain: "rhsacn.org"
  clusterid: "cluster-0001"
  forwarder1: "10.64.63.6"
bootstrap:
  name: "bootstrap"
  ipaddr: "10.66.208.139"
masters:
  - name: "master0"
    ipaddr: "10.66.208.140"
  - name: "master1"
    ipaddr: "10.66.208.141"  
  - name: "master2"
    ipaddr: "10.66.208.142"  
workers:
  - name: "worker0"
    ipaddr: "10.66.208.143"
  - name: "worker1"
    ipaddr: "10.66.208.144"
  - name: "worker2"
    ipaddr: "10.66.208.145"    
EOF

ansible-playbook -e @vars.yml tasks/main.yml
disconnected env change ignore_errors to yes (optional)
cat tasks/main.yml | sed '/^- hosts: all/, /vars_files/ {/^- hosts: all/!{/vars_files/!d;};}' | sed '/^- hosts: all/a  \ \ ignore_errors: yes' | tee tasks/mail.yml.new

mv -f tasks/mail.yml.new tasks/main.yml
check status
helpernodecheck dns-masters
helpernodecheck dns-workers
helpernodecheck dns-etcd
helpernodecheck install-info
helpernodecheck haproxy
helpernodecheck services
helpernodecheck nfs-info
create helper node registry
证书部分请参考：https://github.com/wangjun1974/tips/blob/master/ocp/4.6/disconnect_registry_self_signed_certificate_4.6.md

yum -y install podman httpd httpd-tools wget jq

mkdir -p /opt/registry/{auth,certs,data}

cd /opt/registry/certs

openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 3650 -out domain.crt  -subj "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT Department/CN=*.cluster-0001.rhsacn.org"

cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

htpasswd -bBc /opt/registry/auth/htpasswd dummy dummy

firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public   --permanent
firewall-cmd --add-service=http  --permanent
firewall-cmd --reload

cat > /usr/local/bin/localregistry.sh << 'EOF'
#!/bin/bash
podman run --name poc-registry -d -p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/auth:/auth:z \
-e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry" \
-e "REGISTRY_HTTP_SECRET=ALongRandomSecretForRegistry" \
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
-v /opt/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
docker.io/library/registry:2 
EOF

chmod +x /usr/local/bin/localregistry.sh

/usr/local/bin/localregistry.sh

curl -u dummy:dummy -k https://helper.cluster-0001.rhsacn.org:5000/v2/_catalog

REPO_URL=helper.cluster-0001.rhsacn.org:5000
curl -u dummy:dummy -s -X GET https://$REPO_URL/v2/_catalog \
 | jq '.repositories[]' \
 | sort \
 | xargs -I _ curl -u dummy:dummy -s -X GET https://$REPO_URL/v2/_/tags/list
prepare artifacts
MAJORBUILDNUMBER=4.6
EXTRABUILDNUMBER=4.6.5

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${EXTRABUILDNUMBER}/openshift-client-linux-${EXTRABUILDNUMBER}.tar.gz -P /var/www/html/
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${EXTRABUILDNUMBER}/openshift-install-linux-${EXTRABUILDNUMBER}.tar.gz -P /var/www/html/

tar -xzf /var/www/html/openshift-client-linux-${EXTRABUILDNUMBER}.tar.gz -C /usr/local/bin/
tar -xzf /var/www/html/openshift-install-linux-${EXTRABUILDNUMBER}.tar.gz -C /usr/local/bin/

# download bios and iso
MAJORBUILDNUMBER=4.6
EXTRABUILDNUMBER=4.6.1
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${MAJORBUILDNUMBER}/${EXTRABUILDNUMBER}/rhcos-${EXTRABUILDNUMBER}-x86_64-live.x86_64.iso -P /var/www/html/
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${MAJORBUILDNUMBER}/${EXTRABUILDNUMBER}/rhcos-${EXTRABUILDNUMBER}-x86_64-metal.x86_64.raw.gz -P /var/www/html/

# Get pull secret
wget http://10.66.208.115/rhel9osp/pull-secret.json -P /root
jq '.auths += {"helper.cluster-0001.rhsacn.org:5000": {"auth": "ZHVtbXk6ZHVtbXk=","email": "noemail@localhost"}}' < /root/pull-secret.json > /root/pull-secret-2.json

# login registries
podman login --authfile /root/pull-secret-2.json registry.redhat.io
podman login -u wang.jun.1974 registry.access.redhat.com
podman login --authfile /root/pull-secret-2.json registry.connect.redhat.com

# setup env and record imageContentSources section from output
# see: https://docs.openshift.com/container-platform/4.5/installing/install_config/installing-restricted-networks-preparations.html
# 这里面的 OCP_RELEASE 需要与 openshift-install 的版本保持一致
export OCP_RELEASE="4.6.5"
export LOCAL_REGISTRY='helper.cluster-0001.rhsacn.org:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON="${HOME}/pull-secret-2.json"
export RELEASE_NAME='ocp-release'
export ARCHITECTURE="x86_64"
export REMOVABLE_MEDIA_PATH='/opt/registry'

# 检查 release info
oc adm release info quay.io/openshift-release-dev/ocp-release:4.6.5-x86_64

oc adm -a ${LOCAL_SECRET_JSON} release mirror \
--from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} --dry-run

# mirror to local registry
oc adm -a ${LOCAL_SECRET_JSON} release mirror \
--from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} 

# mirror to local directory (optional)
# 这个是本次测试采用的方式
oc adm release mirror -a ${LOCAL_SECRET_JSON} --to-dir=${REMOVABLE_MEDIA_PATH}/mirror quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE}

# mirror from local directory to local registry
# 这个是本次测试采用的方式
oc image mirror -a ${LOCAL_SECRET_JSON} --from-dir=/opt/registry/mirror 'file://openshift/release:4.6.5*' ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}

...
sha256:3e9704e62bb8ebaba3e9cda8176fa53de7b4e7e63b067eb94522bf6e5e93d4ea file://openshift/release:4.5.13-cluster-network-operator
info: Mirroring completed in 20ms (0B/s)

Success
Update image:  openshift/release:4.5.13

To upload local images to a registry, run:

    oc image mirror --from-dir=/opt/registry/mirror 'file://openshift/release:4.5.13*' REGISTRY/REPOSITORY

Configmap signature file /opt/registry/mirror/config/signature-sha256-8d104847fc2371a9.yaml created

# get content works with install-iso - i guess 4.5.0 iso only works with 4.5.0 OCP_RELEASE
export OCP_RELEASE="4.6.1"
export LOCAL_REGISTRY='helper.cluster-0001.rhsacn.org:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON="${HOME}/pull-secret-2.json"
export RELEASE_NAME='ocp-release'
export ARCHITECTURE="x86_64"
export REMOVABLE_MEDIA_PATH='/opt/registry'

# mirror to local registry
oc adm -a ${LOCAL_SECRET_JSON} release mirror \
--from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}

# Take the media to the restricted network environment and upload the images to the local container registry.
oc image mirror -a ${LOCAL_SECRET_JSON} --from-dir=${REMOVABLE_MEDIA_PATH}/mirror "file://openshift/release:${OCP_RELEASE}*" ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}

# catalog build need use 
# targetfile='./redhat-operators-manifests/mapping.tag.txt'
# cat $targetfile | while read line ;do echo ${line%=*};skopeo copy --format v2s2 --all docker://${line%=*} docker://${line#*=}; done


# ToDo: I could not go through this process ... (optional)
# copy catalog relate content into disconnect env
# 1. $oc adm catalog build --appregistry-org redhat-operators --from=registry.redhat.io/openshift4/ose-operator-registry:vXX  --dir=<YOUR_DIR> --to=file://offline/redhat-operators:vXX
# 2. $oc adm catalog mirror --manifests-only=true --from-dir=<YOUR_DIR> file://offline/redhat-operators:vXX localhost
# 3. $sed 's/=/=file:\/\//g' redhat-operators-manifests/mapping.txt > mapping-new.txt
# 4. $oc image mirror  -f mappings-new.txt --dir=<YOUR_DIR>
# 本次采用同步到本地的方法，再从本地上传到 local registry 的方法
# 保存到本地
export OPERATOR_OCP_RELEASE="4.6"
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://registry.redhat.io/redhat/redhat-operator-index:v${OPERATOR_OCP_RELEASE} dir://offline

# 从本地目录上传到 local registry
skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all dir://offline docker://${LOCAL_REGISTRY}/redhat/redhat-operator-index:v${OPERATOR_OCP_RELEASE}


# install install directory
rm -rf /root/ocp4
mkdir -p /root/ocp4
cd /root/ocp4

ssh-keygen -t rsa -f ~/.ssh/id_rsa -N '' 

openshift-install create install-config --dir $HOME/openstack-upi

single line pull-secret json file
[lab-user@bastion ~]$ jq -c . merged_pullsecret.json 
{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K3dhbmdqdW4xOTc0MWV5cmtoYTJvMzNpd3dncnV2eThub3d0M2lhOjBISTQxTUpISDAyS0tGQjhJSjhQOThPS0pDU1ZSODdaMjYwWDRWWFVTTlBaNjVFVTVFUUFITExIUzhKVzVEQ0s=","email":"jwang@redhat.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K3dhbmdqdW4xOTc0MWV5cmtoYTJvMzNpd3dncnV2eThub3d0M2lhOjBISTQxTUpISDAyS0tGQjhJSjhQOThPS0pDU1ZSODdaMjYwWDRWWFVTTlBaNjVFVTVFUUFITExIUzhKVzVEQ0s=","email":"jwang@redhat.com"},"registry.connect.redhat.com":{"auth":"NjM0MjU0OXx1aGMtMUV5UktoQTJPMzNJd3dHUnV2WThOT3dUM0lBOmV5SmhiR2NpT2lKU1V6VXhNaUo5LmV5SnpkV0lpT2lJMFltRm1NV0V6Tm1Sa05qQTBOakV4WWpFMFpHRmpaRFZpWW1ZMU1EUmtPQ0o5Lm1tdG5qRnhaNHVRZGNpM3pJWGJJTEc5UVZVWTV5WVkwem56TXBtZzRNWHhQcWdWMy1XSTJEZkJjaGpEaldWMC1xYkVYQTBDTEE1Z2F3ZHlPWllOSUFVUjAyek44Q3ZSamNQbHowdWJnLWdwZTZsVWxzZE5ydEh0cnFPVXhZTGgxdjg5WFFTX0RpY2gtR3ZkLTZNdFZsVWx0NFExVER0LW5YU0dEQURMVklQYl9LcENtb1lUVmNWaXljVFJ1bFMwSnhMSUxCQ0JlQm5ueXdyblc2Y0ZiSjRhMnkyVmlsa0F3enpLeFB6dHpPQnhJTk80RkpqU3QxRlBSLW1ubjJsZVZIU0NCYTlyN2lhUXNYUHNhSUw2cE12ZmVPcXhidEM2UUZmcVhnT0NpNkhYYXFOX3dUZVdNemZXTV9LY2lwOTM5QlNjblNFcGVmRUFldWRvRTZwZUFkbGRGbEpUNUxsdThTZVg4bmY5NXc3U1JkdTNPeWw0VW1JSGRIbWx4b2d1N3JBQXhiNnlkZXVqcndLOFBKbjdJTU0xajc4TVBrTWpnN256ZllUdHQ0MnN6RHF2QnJMS0ZrTnV3OEFBVV92TDk4WjUwZG5tUUNuOWlKNlNIcmtFYnhWUURSUno5dS1nelQ3a05pV0ZZWTJUM0tjelhidXhrdm9iUmNhalAzN0lIdG1qdTh4NGhaQVhjWnhNS0NhcWdjT2dJbzlTTXI3VXNLQkxSalFQOUpvLUlzbW9ZZHBXX25aeE1Ib0NPbUppT19MclJaRnVUS0FMOFQ1QXJEZnY3ZWZnNTBfTkItRkp1MEtVVXZfeUVvZF83VlgzNlFMVTc3UFBTQkR2RnpFUkRLdlJ6V25nTy0zSjJManZ0YkF6NW9SdFhheGtEVFZqVThxTzJhU0lRZ1ZV","email":"jwang@redhat.com"},"registry.redhat.io":{"auth":"NjM0MjU0OXx1aGMtMUV5UktoQTJPMzNJd3dHUnV2WThOT3dUM0lBOmV5SmhiR2NpT2lKU1V6VXhNaUo5LmV5SnpkV0lpT2lJMFltRm1NV0V6Tm1Sa05qQTBOakV4WWpFMFpHRmpaRFZpWW1ZMU1EUmtPQ0o5Lm1tdG5qRnhaNHVRZGNpM3pJWGJJTEc5UVZVWTV5WVkwem56TXBtZzRNWHhQcWdWMy1XSTJEZkJjaGpEaldWMC1xYkVYQTBDTEE1Z2F3ZHlPWllOSUFVUjAyek44Q3ZSamNQbHowdWJnLWdwZTZsVWxzZE5ydEh0cnFPVXhZTGgxdjg5WFFTX0RpY2gtR3ZkLTZNdFZsVWx0NFExVER0LW5YU0dEQURMVklQYl9LcENtb1lUVmNWaXljVFJ1bFMwSnhMSUxCQ0JlQm5ueXdyblc2Y0ZiSjRhMnkyVmlsa0F3enpLeFB6dHpPQnhJTk80RkpqU3QxRlBSLW1ubjJsZVZIU0NCYTlyN2lhUXNYUHNhSUw2cE12ZmVPcXhidEM2UUZmcVhnT0NpNkhYYXFOX3dUZVdNemZXTV9LY2lwOTM5QlNjblNFcGVmRUFldWRvRTZwZUFkbGRGbEpUNUxsdThTZVg4bmY5NXc3U1JkdTNPeWw0VW1JSGRIbWx4b2d1N3JBQXhiNnlkZXVqcndLOFBKbjdJTU0xajc4TVBrTWpnN256ZllUdHQ0MnN6RHF2QnJMS0ZrTnV3OEFBVV92TDk4WjUwZG5tUUNuOWlKNlNIcmtFYnhWUURSUno5dS1nelQ3a05pV0ZZWTJUM0tjelhidXhrdm9iUmNhalAzN0lIdG1qdTh4NGhaQVhjWnhNS0NhcWdjT2dJbzlTTXI3VXNLQkxSalFQOUpvLUlzbW9ZZHBXX25aeE1Ib0NPbUppT19MclJaRnVUS0FMOFQ1QXJEZnY3ZWZnNTBfTkItRkp1MEtVVXZfeUVvZF83VlgzNlFMVTc3UFBTQkR2RnpFUkRLdlJ6V25nTy0zSjJManZ0YkF6NW9SdFhheGtEVFZqVThxTzJhU0lRZ1ZV","email":"jwang@redhat.com"},"utilityvm.example.com:5000":{"auth":"b3BlbnNoaWZ0OnJlZGhhdA==","email":"noemail@localhost"}}}


cat > install-config.yaml << EOF
apiVersion: v1
baseDomain: dynamic.opentlc.com
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 0
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  creationTimestamp: null
  name: cluster-wg9lh
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 192.168.47.0/24
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  openstack:
    apiVIP: 192.168.47.5
    cloud: "wg9lh-project"
    computeFlavor: 4c16g30d
    externalDNS: null
    externalNetwork: external
    ingressVIP: 192.168.47.7
    lbFloatingIP: 52.116.164.174
    octaviaSupport: "1"
    region: ""
    trunkSupport: "0"
publish: External
pullSecret: $(echo "'")$( jq -c . ${HOME}/merged_pullsecret.json )$(echo "'")
sshKey: |
$( cat ${HOME}/.ssh/wg9lhkey.pub | sed 's/^/  /g' )
additionalTrustBundle: |
$( cat /etc/pki/ca-trust/source/anchors/ca.pem | sed 's/^/  /g' )
imageContentSources:
- mirrors:
  - utilityvm.example.com:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - utilityvm.example.com:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

openshift-install create manifests --dir $HOME/openstack-upi

[lab-user@bastion openstack-upi]$ tree
.
|-- manifests
|   |-- 04-openshift-machine-config-operator.yaml
|   |-- cloud-provider-config.yaml
|   |-- cluster-config.yaml
|   |-- cluster-dns-02-config.yml
|   |-- cluster-infrastructure-02-config.yml
|   |-- cluster-ingress-02-config.yml
|   |-- cluster-network-01-crd.yml
|   |-- cluster-network-02-config.yml
|   |-- cluster-proxy-01-config.yaml
|   |-- cluster-scheduler-02-config.yml
|   |-- cvo-overrides.yaml
|   |-- etcd-ca-bundle-configmap.yaml
|   |-- etcd-client-secret.yaml   
|   |-- etcd-metric-client-secret.yaml
|   |-- etcd-metric-serving-ca-configmap.yaml
|   |-- etcd-metric-signer-secret.yaml
|   |-- etcd-namespace.yaml
|   |-- etcd-service.yaml
|   |-- etcd-serving-ca-configmap.yaml
|   |-- etcd-signer-secret.yaml   
|   |-- image-content-source-policy-0.yaml
|   |-- image-content-source-policy-1.yaml
|   |-- kube-cloud-config.yaml
|   |-- kube-system-configmap-root-ca.yaml
|   |-- machine-config-server-tls-secret.yaml
|   |-- openshift-config-secret-pull-secret.yaml
|   `-- user-ca-bundle-config.yaml
`-- openshift
    |-- 99_cloud-creds-secret.yaml
    |-- 99_kubeadmin-password-secret.yaml
    |-- 99_openshift-cluster-api_master-machines-0.yaml
    |-- 99_openshift-cluster-api_master-machines-1.yaml
    |-- 99_openshift-cluster-api_master-machines-2.yaml
    |-- 99_openshift-cluster-api_master-user-data-secret.yaml
    |-- 99_openshift-cluster-api_worker-machineset-0.yaml
    |-- 99_openshift-cluster-api_worker-user-data-secret.yaml
    |-- 99_openshift-machineconfig_99-master-ssh.yaml
    |-- 99_openshift-machineconfig_99-worker-ssh.yaml
    |-- 99_role-cloud-creds-secret-reader.yaml
    `-- openshift-install-manifests.yaml

2 directories, 39 files

cat $HOME/openstack-upi/manifests/cluster-scheduler-02-config.yml
[lab-user@bastion openstack-upi]$ cat $HOME/openstack-upi/manifests/cluster-scheduler-02-config.yml
apiVersion: config.openshift.io/v1
kind: Scheduler
metadata:
  creationTimestamp: null
  name: cluster
spec:
  mastersSchedulable: true
  policy:
    name: ""
status: {}

[lab-user@bastion openstack-upi]$ ansible localhost -m lineinfile -a 'path="$HOME/openstack-upi/manifests/cluster-scheduler-02-config.yml" regexp="^  mastersSchedulable" line="  mastersSchedulable: false"'
localhost | CHANGED => {
    "backup": "",
    "changed": true,
    "msg": "line replaced"
}
[lab-user@bastion openstack-upi]$ cat $HOME/openstack-upi/manifests/cluster-scheduler-02-config.yml
apiVersion: config.openshift.io/v1
kind: Scheduler
metadata:
  creationTimestamp: null
  name: cluster
spec:
  mastersSchedulable: false
  policy:
    name: ""
status: {}

rm -f openshift/99_openshift-cluster-api_master-machines-*.yaml

[lab-user@bastion openstack-upi]$ openshift-install create ignition-configs --dir $HOME/openstack-upi
INFO Consuming Master Machines from target directory 
INFO Consuming Openshift Manifests from target directory 
INFO Consuming Common Manifests from target directory 
INFO Consuming Worker Machines from target directory 
INFO Consuming OpenShift Install (Manifests) from target directory 
INFO Ignition-Configs created in: /home/lab-user/openstack-upi and /home/lab-user/openstack-upi/auth 
[lab-user@bastion openstack-upi]$ ls -ltr
total 312
drwxr-x---. 2 lab-user users     50 Sep 27 01:30 auth
-rw-r-----. 1 lab-user users   1706 Sep 27 01:30 master.ign
-rw-r-----. 1 lab-user users   1706 Sep 27 01:30 worker.ign
-rw-r-----. 1 lab-user users 305565 Sep 27 01:30 bootstrap.ign
-rw-r-----. 1 lab-user users    210 Sep 27 01:30 metadata.json

[lab-user@bastion openstack-upi]$ tree
.
|-- auth
|   |-- kubeadmin-password
|   `-- kubeconfig
|-- bootstrap.ign
|-- master.ign
|-- metadata.json
`-- worker.ign

1 directory, 6 files

[lab-user@bastion openstack-upi]$ ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export INFRA_ID" line="export INFRA_ID=$(jq -r .infraID $HOME/openstack-upi/metadata.json)"'
localhost | CHANGED => {
    "backup": "",
    "changed": true,
    "msg": "line added"
}
[lab-user@bastion openstack-upi]$ source $HOME/.bashrc
[lab-user@bastion openstack-upi]$ echo $INFRA_ID
cluster-wg9lh-zwlg9

[lab-user@bastion openstack-upi]$ cat $HOME/resources/update_ignition.py
import base64
import json
import os

with open('bootstrap.ign', 'r') as f:
    ignition = json.load(f)

files = ignition['storage'].get('files', [])

infra_id = os.environ.get('INFRA_ID', 'openshift').encode()
hostname_b64 = base64.standard_b64encode(infra_id + b'-bootstrap\n').decode().strip()
files.append(
{
    'path': '/etc/hostname',
    'mode': 420,
    'contents': {
        'source': 'data:text/plain;charset=utf-8;base64,' + hostname_b64,
        'verification': {}
    },
    'filesystem': 'root',
})

dhcp_client_conf_b64 = base64.standard_b64encode(b'[main]\ndhcp=dhclient\n').decode().strip()
files.append(
{
    'path': '/etc/NetworkManager/conf.d/dhcp-client.conf',
    'mode': 420,
    'contents': {
        'source': 'data:text/plain;charset=utf-8;base64,' + dhcp_client_conf_b64,
        'verification': {}
        },
    'filesystem': 'root',
})


dhclient_cont_b64 = base64.standard_b64encode(b'send dhcp-client-identifier = hardware;\nprepend domain-name-servers 127.0.0.1;\n').decode().s
trip()
files.append(
{
    'path': '/etc/dhcp/dhclient.conf',
    'mode': 420,
    'contents': {
        'source': 'data:text/plain;charset=utf-8;base64,' + dhclient_cont_b64,
        'verification': {}
        },
    'filesystem': 'root'
})

ignition['storage']['files'] = files;

with open('bootstrap.ign', 'w') as f:
    json.dump(ignition, f)
[lab-user@bastion openstack-upi]$ 

[lab-user@bastion openstack-upi]$ cd $HOME/openstack-upi
[lab-user@bastion openstack-upi]$ python3 $HOME/resources/update_ignition.py

[lab-user@bastion openstack-upi]$ jq '.storage.files | map(select(.path=="/etc/dhcp/dhclient.conf", .path=="/etc/NetworkManager/conf.d/dhcp-client.conf", .path=="/etc/hostname"))' bootstrap.ign
[
  {
    "path": "/etc/hostname",
    "mode": 420,
    "contents": {
      "source": "data:text/plain;charset=utf-8;base64,Y2x1c3Rlci13ZzlsaC16d2xnOS1ib290c3RyYXAK",
      "verification": {}
    },
    "filesystem": "root"
  },
  {
    "path": "/etc/NetworkManager/conf.d/dhcp-client.conf",
    "mode": 420,
    "contents": {
      "source": "data:text/plain;charset=utf-8;base64,W21haW5dCmRoY3A9ZGhjbGllbnQK",
      "verification": {}
    },
    "filesystem": "root"
  },
  {
    "path": "/etc/dhcp/dhclient.conf",
    "mode": 420,
    "contents": {
      "source": "data:text/plain;charset=utf-8;base64,c2VuZCBkaGNwLWNsaWVudC1pZGVudGlmaWVyID0gaGFyZHdhcmU7CnByZXBlbmQgZG9tYWluLW5hbWUtc2VydmVycyAxMjcuMC4wLjE7Cg==",
      "verification": {}
    },
    "filesystem": "root"
  }
]

for index in $(seq 0 2); do
    MASTER_HOSTNAME="$INFRA_ID-master-$index\n"
    python -c "import base64, json, sys;
ignition = json.load(sys.stdin);
storage = ignition.get('storage', {});
files = storage.get('files', []);
files.append({'path': '/etc/hostname', 'mode': 420, 'contents': {'source': 'data:text/plain;charset=utf-8;base64,' + base64.standard_b64encode(b'$MASTER_HOSTNAME').decode().strip(), 'verification': {}}, 'filesystem': 'root'});
storage['files'] = files;
ignition['storage'] = storage
json.dump(ignition, sys.stdout)" <master.ign >"$INFRA_ID-master-$index-ignition.json"
done

[lab-user@bastion openstack-upi]$ scp bootstrap.ign utilityvm.example.com:
bootstrap.ign                                                                                               100%  301KB 113.9MB/s   00:00    
[lab-user@bastion openstack-upi]$ ssh utilityvm.example.com chmod 644 bootstrap.ign
[lab-user@bastion openstack-upi]$ 
[lab-user@bastion openstack-upi]$ ssh utilityvm.example.com sudo mv bootstrap.ign /var/www/html
[lab-user@bastion openstack-upi]$ ssh utilityvm.example.com sudo restorecon /var/www/html/bootstrap.ign

[lab-user@bastion openstack-upi]$ wget -O $HOME/mybootstrap.ign http://utilityvm.example.com/bootstrap.ign
--2021-09-27 01:40:28--  http://utilityvm.example.com/bootstrap.ign
Resolving utilityvm.example.com (utilityvm.example.com)... 192.168.47.103
Connecting to utilityvm.example.com (utilityvm.example.com)|192.168.47.103|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 307728 (301K) [application/vnd.coreos.ignition+json]
Saving to: '/home/lab-user/mybootstrap.ign'

/home/lab-user/mybootstrap.ign      100%[=================================================================>] 300.52K  --.-KB/s    in 0.001s  

2021-09-27 01:40:28 (463 MB/s) - '/home/lab-user/mybootstrap.ign' saved [307728/307728]


[lab-user@bastion openstack-upi]$ openstack port create --network "$GUID-ocp-network" --security-group "$GUID-master_sg" --fixed-ip "subnet=$GUID-ocp-subnet,ip-address=192.168.47.5" --tag openshiftClusterID="$INFRA_ID" "$INFRA_ID-api-port" -f json
{
  "admin_state_up": true,
  "allowed_address_pairs": [],
  "binding_host_id": null,
  "binding_profile": null,
  "binding_vif_details": null,
  "binding_vif_type": null,
  "binding_vnic_type": "normal",
  "created_at": "2021-09-27T05:43:05Z",
  "data_plane_status": null,
  "description": "",
  "device_id": "",
  "device_owner": "",
  "dns_assignment": [
    {
      "ip_address": "192.168.47.5",
      "hostname": "host-192-168-47-5",
      "fqdn": "host-192-168-47-5.example.com."
    }
  ],
  "dns_domain": null,
  "dns_name": "",
  "extra_dhcp_opts": [],
  "fixed_ips": [
    {
      "subnet_id": "3c780686-74cd-4800-b833-365ae671e891",
      "ip_address": "192.168.47.5"
    }
  ],
  "id": "4cc8ad77-f25a-4018-a0ae-88e8ef2b5b8c",
  "location": {
    "cloud": "wg9lh-project",
    "region_name": "regionOne",
    "zone": null,
    "project": {
      "id": "2af53bc6cb934a4096041ae9e18562d6",
      "name": "wg9lh-project",
      "domain_id": "default",
      "domain_name": null
    }
  },
  "mac_address": "fa:16:3e:9e:a7:0d",
  "name": "cluster-wg9lh-zwlg9-api-port",
  "network_id": "e59852c0-474f-4dcf-99d6-7b30bdd24a13",
  "port_security_enabled": true,
  "project_id": "2af53bc6cb934a4096041ae9e18562d6",
  "propagate_uplink_status": null,
  "qos_policy_id": null,
  "resource_request": null,
  "revision_number": 1,
  "security_group_ids": [
    "e16313c3-8f66-4065-bd58-1588a4dda51c"
  ],
  "status": "DOWN",
  "tags": [
    "openshiftClusterID=cluster-wg9lh-zwlg9"
  ],
  "trunk_details": null,
  "updated_at": "2021-09-27T05:43:05Z"
}

[lab-user@bastion openstack-upi]$ openstack port create --network "$GUID-ocp-network" --security-group "$GUID-worker_sg" --fixed-ip "subnet=$GUID-ocp-subnet,ip-address=192.168.47.7" --tag openshiftClusterID="$INFRA_ID" "$INFRA_ID-ingress-port" -f json
{
  "admin_state_up": true,
  "allowed_address_pairs": [],
  "binding_host_id": null,
  "binding_profile": null,
  "binding_vif_details": null,
  "binding_vif_type": null,
  "binding_vnic_type": "normal",  
  "created_at": "2021-09-27T05:46:01Z",
  "data_plane_status": null,
  "description": "",
  "device_id": "",
  "device_owner": "",
  "dns_assignment": [
    {
      "ip_address": "192.168.47.7",
      "hostname": "host-192-168-47-7",
      "fqdn": "host-192-168-47-7.example.com."
    }
  ],
  "dns_domain": null,

  "dns_name": "",
  "extra_dhcp_opts": [],
  "fixed_ips": [
    {
      "subnet_id": "3c780686-74cd-4800-b833-365ae671e891",
      "ip_address": "192.168.47.7"
    }
  ],
  "id": "7b513ae5-80ea-4f53-b550-120703312aa4",
  "location": {
    "cloud": "wg9lh-project",
    "region_name": "regionOne",
    "zone": null,
    "project": {
      "id": "2af53bc6cb934a4096041ae9e18562d6",
      "name": "wg9lh-project",
      "domain_id": "default",
      "domain_name": null
    }
  },
  "mac_address": "fa:16:3e:01:7f:df",
  "name": "cluster-wg9lh-zwlg9-ingress-port",
  "network_id": "e59852c0-474f-4dcf-99d6-7b30bdd24a13",
  "port_security_enabled": true,
  "project_id": "2af53bc6cb934a4096041ae9e18562d6",
  "propagate_uplink_status": null,
  "qos_policy_id": null,
  "resource_request": null,
  "revision_number": 1,
  "security_group_ids": [
    "63248770-9ed2-4a48-9ec4-03c893e5781b"
  ],
  "status": "DOWN",
  "tags": [
    "openshiftClusterID=cluster-wg9lh-zwlg9"
  ],
  "trunk_details": null,
  "updated_at": "2021-09-27T05:46:01Z"
}

openstack floating ip set --port "$INFRA_ID-api-port" $API_FIP

[lab-user@bastion openstack-upi]$ openstack floating ip set --port "$INFRA_ID-api-port" $API_FIP
[lab-user@bastion openstack-upi]$ env | grep API_FIP
API_FIP=52.116.164.174

[lab-user@bastion openstack-upi]$ openstack floating ip set --port "$INFRA_ID-ingress-port" $INGRESS_FIP
[lab-user@bastion openstack-upi]$ env | grep INGRESS_FIP
INGRESS_FIP=52.116.164.97

[lab-user@bastion openstack-upi]$ openstack floating ip list -c ID -c "Floating IP Address" -c "Fixed IP Address"
+--------------------------------------+---------------------+------------------+
| ID                                   | Floating IP Address | Fixed IP Address |
+--------------------------------------+---------------------+------------------+
| 2d985b97-0fd3-43de-8279-7c66d68fdc9b | 52.116.164.58       | 192.168.47.100   |
| 45ac13a5-0ba4-48c6-bebb-900e8236bc28 | 52.116.164.174      | 192.168.47.5     |
| 92f621d8-5226-4cef-b820-ea9706a622b2 | 52.116.164.97       | 192.168.47.7     |
+--------------------------------------+---------------------+------------------+

openstack port create \
  --network "$GUID-ocp-network" \
  --security-group "$GUID-master_sg" \
  --allowed-address ip-address=192.168.47.5 \
  --allowed-address ip-address=192.168.47.6 \
  --allowed-address ip-address=192.168.47.7 \
  --tag openshiftClusterID="$INFRA_ID" \
  "$INFRA_ID-bootstrap-port"

[lab-user@bastion openstack-upi]$ openstack port create   --network "$GUID-ocp-network"   --security-group "$GUID-master_sg"   --allowed-address ip-address=192.168.47.5   --allowed-address ip-address=192.168.47.6   --allowed-address ip-address=192.168.47.7   --tag openshiftClusterID="$INFRA_ID"   "$INFRA_ID-bootstrap-port"

openstack server create --image rhcos-ocp46 --flavor 4c16g30d --user-data "$HOME/openstack-upi/$INFRA_ID-bootstrap-ignition.json" --port "$INFRA_ID-bootstrap-port" --wait --property openshiftClusterID="$INFRA_ID" "$INFRA_ID-bootstrap"

ssh -i $HOME/.ssh/${GUID}key.pem core@$INFRA_ID-bootstrap.example.com


[lab-user@bastion openstack-upi]$ for index in $(seq 0 2); do
  openstack port create \
  --network "$GUID-ocp-network" \
  --security-group "$GUID-master_sg" \
  --allowed-address ip-address=192.168.47.5 \
  --allowed-address ip-address=192.168.47.6 \
  --allowed-address ip-address=192.168.47.7 \
  --tag openshiftClusterID="$INFRA_ID" \
  "$INFRA_ID-master-port-$index"
done

[lab-user@bastion openstack-upi]$ openstack port list | grep master 
| 87375f9c-8b3e-46b4-9282-43227a81379d | cluster-wg9lh-zwlg9-master-port-2            | fa:16:3e:e4:38:00 | ip_address='192.168.47.55', subnet_id='3c780686-74cd-4800-b833-365ae671e891'  | DOWN   |
| b0aa45e2-e182-44c8-8270-2221d8174b4c | cluster-wg9lh-zwlg9-master-port-0            | fa:16:3e:62:c7:16 | ip_address='192.168.47.24', subnet_id='3c780686-74cd-4800-b833-365ae671e891'  | DOWN   |
| ced76781-e5be-4dd5-8861-eb4a1cc9a820 | cluster-wg9lh-zwlg9-master-port-1            | fa:16:3e:d9:8e:f3 | ip_address='192.168.47.97', subnet_id='3c780686-74cd-4800-b833-365ae671e891'  | DOWN   |

[lab-user@bastion openstack-upi]$ for index in $(seq 0 2); do
  openstack server create \
  --boot-from-volume 30 \
  --image rhcos-ocp46 \
  --flavor 4c16g30d \
  --user-data "$HOME/openstack-upi/$INFRA_ID-master-$index-ignition.json" \
  --port "$INFRA_ID-master-port-$index" \
  --property openshiftClusterID="$INFRA_ID" \
  "$INFRA_ID-master-$index"
done

[lab-user@bastion openstack-upi]$ jq .ignition.config $HOME/openstack-upi/$INFRA_ID-master-0-ignition.json
{
  "merge": [
    {
      "source": "https://192.168.47.5:22623/config/master"
    }
  ]
}

[lab-user@bastion openstack-upi]$ openstack console log show "$INFRA_ID-bootstrap"
[lab-user@bastion openstack-upi]$ openstack console log show "$INFRA_ID-master-0"
[lab-user@bastion openstack-upi]$ openstack console log show "$INFRA_ID-master-1"
[lab-user@bastion openstack-upi]$ openstack console log show "$INFRA_ID-master-2"

[lab-user@bastion openstack-upi]$ ssh -i $HOME/.ssh/${GUID}key.pem core@$INFRA_ID-bootstrap.example.com
[core@cluster-wg9lh-zwlg9-bootstrap ~]$ sudo podman images
REPOSITORY                                       TAG      IMAGE ID       CREATED        SIZE
utilityvm.example.com:5000/ocp4/openshift4       <none>   1b715f0ef131   8 months ago   320 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   d822eadbccb0   8 months ago   504 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   8da8e111148f   8 months ago   325 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   9ef3b30032ac   8 months ago   318 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   d7d8f7b3a0e4   8 months ago   319 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   d72c05e8b59b   8 months ago   303 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   dbd617d0296b   8 months ago   686 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   12b0d7eb4b40   8 months ago   298 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   89073d4591f9   8 months ago   316 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   b7ba39fb2456   8 months ago   341 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   09faf63b51e8   8 months ago   337 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   b165af37a38a   8 months ago   315 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   2ec31cc23897   8 months ago   320 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   8ff6eb047e7d   8 months ago   322 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   1508976cc9d1   8 months ago   316 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   6d6df86acee3   8 months ago   416 MB
quay.io/openshift-release-dev/ocp-v4.0-art-dev   <none>   bde3177e06af   8 months ago   268 MB

[core@cluster-wg9lh-zwlg9-bootstrap ~]$ sudo cat /etc/containers/registries.conf
[[registry]]
location = "quay.io/openshift-release-dev/ocp-release"
insecure = false
mirror-by-digest-only = true

[[registry.mirror]]
location = "utilityvm.example.com:5000/ocp4/openshift4"
insecure = false


[[registry]]
location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
insecure = false
mirror-by-digest-only = true

[[registry.mirror]]
location = "utilityvm.example.com:5000/ocp4/openshift4"
insecure = false


[core@cluster-wg9lh-zwlg9-bootstrap ~]$ journalctl -b -f -u release-image.service -u bootkube.service
...
Sep 27 06:10:17 cluster-wg9lh-zwlg9-bootstrap bootkube.sh[2333]: Waiting for CEO to finish...
Sep 27 06:10:18 cluster-wg9lh-zwlg9-bootstrap bootkube.sh[2333]: I0927 06:10:18.115683       1 waitforceo.go:64] Cluster etcd operator bootstrapped successfully
Sep 27 06:10:18 cluster-wg9lh-zwlg9-bootstrap bootkube.sh[2333]: I0927 06:10:18.119462       1 waitforceo.go:58] cluster-etcd-operator bootstrap etcd
Sep 27 06:10:18 cluster-wg9lh-zwlg9-bootstrap bootkube.sh[2333]: bootkube.service complete


[lab-user@bastion openstack-upi]$ openshift-install wait-for bootstrap-complete --dir $HOME/openstack-upi
INFO Waiting up to 20m0s for the Kubernetes API at https://api.cluster-wg9lh.dynamic.opentlc.com:6443... 
INFO API v1.19.0+1833054 up                       
INFO Waiting up to 30m0s for bootstrapping to complete... 
INFO It is now safe to remove the bootstrap resources 
INFO Time elapsed: 0s

[lab-user@bastion openstack-upi]$ openstack server delete "$INFRA_ID-bootstrap"
[lab-user@bastion openstack-upi]$ openstack port delete "$INFRA_ID-bootstrap-port"

[lab-user@bastion openstack-upi]$ ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^export KUBECONFIG" line="export KUBECONFIG=$HOME/openstack-upi/auth/kubeconfig"'
localhost | CHANGED => {
    "backup": "",
    "changed": true,
    "msg": "line added"
}
[lab-user@bastion openstack-upi]$ source $HOME/.bashrc

watch oc get clusterversion

[lab-user@bastion openstack-upi]$ for index in $(seq 0 1); do
  openstack port create \
  --network "$GUID-ocp-network" \
  --security-group "$GUID-worker_sg" \
  --allowed-address ip-address=192.168.47.5 \
  --allowed-address ip-address=192.168.47.6 \
  --allowed-address ip-address=192.168.47.7 \
  --tag openshiftClusterID="$INFRA_ID" \
  "$INFRA_ID-worker-port-$index"
done

[lab-user@bastion openstack-upi]$ for index in $(seq 0 1); do
  openstack server create \
  --image rhcos-ocp46 \
  --flavor 4c16g30d \
  --user-data "$HOME/openstack-upi/worker.ign" \
  --port "$INFRA_ID-worker-port-$index" \
  --property openshiftClusterID="$INFRA_ID" \
  "$INFRA_ID-worker-$index"
done

[lab-user@bastion openstack-upi]$ jq .ignition.config $HOME/openstack-upi/worker.ign
{
  "merge": [
    {
      "source": "https://192.168.47.5:22623/config/worker"
    }
  ]
}

[lab-user@bastion openstack-upi]$ openstack console log show "$INFRA_ID-worker-0"
[lab-user@bastion openstack-upi]$ openstack console log show "$INFRA_ID-worker-1"
[lab-user@bastion openstack-upi]$ watch oc get csr 
[lab-user@bastion openstack-upi]$ oc get csr --no-headers | /usr/bin/awk '{print $1}' | xargs oc adm certificate approve

[lab-user@bastion openstack-upi]$ watch oc get nodes
[lab-user@bastion openstack-upi]$ watch oc get clusterversion

[lab-user@bastion openstack-upi]$ oc -n openshift-kube-apiserver-operator logs $(oc -n openshift-kube-apiserver-operator get pods -l app=kube-apiserver-operator -o name) -f 

[lab-user@bastion openstack-upi]$ oc get clusterversion 
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.6.15    True        False         7s      Cluster version is 4.6.15

[lab-user@bastion openstack-upi]$ openshift-install wait-for install-complete --dir=$HOME/openstack-upi
INFO Waiting up to 40m0s for the cluster at https://api.cluster-wg9lh.dynamic.opentlc.com:6443 to initialize... 
INFO Waiting up to 10m0s for the openshift-console route to be created... 
INFO Install complete!                            
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/home/lab-user/openstack-upi/auth/kubeconfig' 
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.cluster-wg9lh.dynamic.opentlc.com 
INFO Login to the console with user: "kubeadmin", and password: "BBBBB-kphko-yLTDm-AAAAA" 
INFO Time elapsed: 0s  

[lab-user@bastion openstack-upi]$ oc project openshift-image-registry
Now using project "openshift-image-registry" on server "https://api.cluster-wg9lh.dynamic.opentlc.com:6443".
[lab-user@bastion openstack-upi]$ oc get configs.imageregistry.operator.openshift.io cluster -o yaml
apiVersion: imageregistry.operator.openshift.io/v1
kind: Config
metadata:
  creationTimestamp: "2021-09-27T06:12:18Z"
  finalizers:
  - imageregistry.operator.openshift.io/finalizer
  generation: 2
  managedFields:  
...
  name: cluster
  resourceVersion: "27164"
  selfLink: /apis/imageregistry.operator.openshift.io/v1/configs/cluster
  uid: 5435a092-0c6f-4f23-8c4b-858cc8c99ab6
spec:
  httpSecret: f12e452ef4a270ef4941a86caa1a16ff93b6e0d80b63e449263c6ad57f3b99e743263930f2ee92f0505cd4bc8358c1571c8c11df5f8e31df0704d891f125ca91
  logLevel: Normal
  managementState: Managed
  observedConfig: null
  operatorLogLevel: Normal
  proxy: {}
  replicas: 2
  requests:
    read:
      maxWaitInQueue: 0s
    write:
      maxWaitInQueue: 0s
  rolloutStrategy: RollingUpdate  
  storage:
    managementState: Managed
    swift:
      authURL: https://api.orange.sc01.infra.opentlc.com:13000/v3
      authVersion: "3"
      container: cluster-wg9lh-zwlg9-image-registry-gdlywnhyddjpebrudpkaltcwyyv
      domain: Default
      regionName: regionOne
      tenant: wg9lh-project
      tenantID: 2af53bc6cb934a4096041ae9e18562d6
  unsupportedConfigOverrides: null
status:
  conditions:
  - lastTransitionTime: "2021-09-27T06:12:21Z"
    reason: Swift container Exists
    status: "True"
    type: StorageExists
  - lastTransitionTime: "2021-09-27T06:34:11Z"
    message: The registry is ready
    reason: Ready
    status: "True"
    type: Available
  - lastTransitionTime: "2021-09-27T06:34:37Z"
    message: The registry is ready
    reason: Ready
    status: "False"
    type: Progressing
  - lastTransitionTime: "2021-09-27T06:12:20Z"
    status: "False"
    type: Degraded
  - lastTransitionTime: "2021-09-27T06:12:20Z"
    status: "False"
    type: Removed
  - lastTransitionTime: "2021-09-27T06:12:24Z"
    reason: AsExpected
    status: "False"
    type: NodeCADaemonControllerDegraded
  - lastTransitionTime: "2021-09-27T06:12:25Z"
    reason: AsExpected
    status: "False"
    type: ImageRegistryCertificatesControllerDegraded
  - lastTransitionTime: "2021-09-27T06:12:25Z"
    reason: AsExpected
    status: "False"
    type: ImageConfigControllerDegraded
  generations:
  - group: apps
    hash: ""
    lastGeneration: 2
    name: image-registry
    namespace: openshift-image-registry
    resource: deployments
  - group: apps
    hash: ""
    lastGeneration: 0
    name: node-ca
    namespace: openshift-image-registry
    resource: daemonsets
  observedGeneration: 2
  readyReplicas: 0
  storage:
    managementState: Managed
    swift:
      authURL: https://api.orange.sc01.infra.opentlc.com:13000/v3
      authVersion: "3"
      container: cluster-wg9lh-zwlg9-image-registry-gdlywnhyddjpebrudpkaltcwyyv
      domain: Default
      regionName: regionOne
      tenant: wg9lh-project
      tenantID: 2af53bc6cb934a4096041ae9e18562d6
  storageManaged: true

[lab-user@bastion openstack-upi]$ oc get clusterversion 
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.6.15    True        False         7s      Cluster version is 4.6.15

[lab-user@bastion openstack-upi]$ oc get clusteroperators
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.6.15    True        False         False      16m
cloud-credential                           4.6.15    True        False         False      59m
cluster-autoscaler                         4.6.15    True        False         False      52m
config-operator                            4.6.15    True        False         False      53m
console                                    4.6.15    True        False         False      22m
csi-snapshot-controller                    4.6.15    True        False         False      53m
dns                                        4.6.15    True        False         False      52m
etcd                                       4.6.15    True        False         False      52m
image-registry                             4.6.15    True        False         False      26m
ingress                                    4.6.15    True        False         False      25m
insights                                   4.6.15    True        False         False      53m
kube-apiserver                             4.6.15    True        False         False      51m
kube-controller-manager                    4.6.15    True        False         False      50m
kube-scheduler                             4.6.15    True        False         False      50m
kube-storage-version-migrator              4.6.15    True        False         False      26m
machine-api                                4.6.15    True        False         False      44m
machine-approver                           4.6.15    True        False         False      53m
machine-config                             4.6.15    True        False         False      52m
marketplace                                4.6.15    True        False         False      52m
monitoring                                 4.6.15    True        False         False      25m
network                                    4.6.15    True        False         False      53m
node-tuning                                4.6.15    True        False         False      53m
openshift-apiserver                        4.6.15    True        False         False      43m
openshift-controller-manager               4.6.15    True        False         False      51m
openshift-samples                          4.6.15    True        False         False      42m
operator-lifecycle-manager                 4.6.15    True        False         False      52m
operator-lifecycle-manager-catalog         4.6.15    True        False         False      52m
operator-lifecycle-manager-packageserver   4.6.15    True        False         False      32m
service-ca                                 4.6.15    True        False         False      53m
storage                                    4.6.15    True        False         False      52m

[lab-user@bastion openstack-upi]$ openshift-install wait-for install-complete --dir=$HOME/openstack-upi
INFO Waiting up to 40m0s for the cluster at https://api.cluster-wg9lh.dynamic.opentlc.com:6443 to initialize... 
INFO Waiting up to 10m0s for the openshift-console route to be created... 
INFO Install complete!                            
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/home/lab-user/openstack-upi/auth/kubeconfig' 
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.cluster-wg9lh.dynamic.opentlc.com 
INFO Login to the console with user: "kubeadmin", and password: "BBBBB-kphko-yLTDm-AAAAA" 
INFO Time elapsed: 0s  


You must execute oc create -f $HOME/resources/99-scsi-device-detection-machineconfig.yml or all furthere labs will fail. This fixes a bug in how OpenShift detects new storage devices. Cinder devices have very long names. OpenShift 4.6 only supports name of up to 20 characters. This udev rule truncates the device names, so your pods can mount them properly. All worker nodes that are created as a machine will receive these udev rules, thanks to it being delivered by a machineconfig. More in upcoming modules.


[lab-user@bastion openstack-upi]$ cat $HOME/resources/99-scsi-device-detection-machineconfig.yml
---
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 02-worker-udev-scsi-symlink
  namespace: openshift-machine-api
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 3.1.0
    networkd: {}
    passwd: {}
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,IyBDcmVhdGUgc3ltbGlua3MgZm9yIHNjc2kgZGV2aWNlcyB0cnVuY2F0ZWQgYXQgMjAgY2hhcmFjdGVycyB0byBtYXRjaCBPcGVuU2hpZnQgb3BlbnN0YWNrIHZvbHVtZSBzZWFyY2g6CiMgaHR0cHM6Ly9naXRodWIuY29tL29wZW5zaGlmdC9vcmlnaW4vYmxvYi9tYXN0ZXIvdmVuZG9yL2s4cy5pby9sZWdhY3ktY2xvdWQtcHJvdmlkZXJzL29wZW5zdGFjay9vcGVuc3RhY2tfdm9sdW1lcy5nbyNMNDk4CkFDVElPTj09ImFkZCIsIEVOVntTQ1NJX0lERU5UX0xVTl9WRU5ET1J9PT0iPyoiLCBFTlZ7REVWVFlQRX09PSJkaXNrIiwgUlVOKz0iL2Jpbi9zaCAtYyAnSUQ9JGVudntTQ1NJX0lERU5UX0xVTl9WRU5ET1J9OyBsbiAtcyAuLi8uLi8kbmFtZSAvZGV2L2Rpc2svYnktaWQvc2NzaS0wJGVudntTQ1NJX1ZFTkRPUn1fJGVudntTQ1NJX01PREVMfV8ke0lEOjA6MjB9JyIKQUNUSU9OPT0icmVtb3ZlIiwgRU5We1NDU0lfSURFTlRfTFVOX1ZFTkRPUn09PSI/KiIsIEVOVntERVZUWVBFfT09ImRpc2siLCBSVU4rPSIvYmluL3NoIC1jICdJRD0kZW52e1NDU0lfSURFTlRfTFVOX1ZFTkRPUn07IHJtIC1mIC9kZXYvZGlzay9ieS1pZC9zY3NpLTAkZW52e1NDU0lfVkVORE9SfV8kZW52e1NDU0lfTU9ERUx9XyR7SUQ6MDoyMH0nIgo=
          verification: {}
        filesystem: root
        mode: 0644
        path: /etc/udev/rules.d/99-scsi-symlink.rules
  osImageURL: ""

[lab-user@bastion openstack-upi]$ echo 'IyBDcmVhdGUgc3ltbGlua3MgZm9yIHNjc2kgZGV2aWNlcyB0cnVuY2F0ZWQgYXQgMjAgY2hhcmFjdGVycyB0byBtYXRjaCBPcGVuU2hpZnQgb3BlbnN0YWNrIHZvbHVtZSBzZWFyY2g6CiMgaHR0cHM6Ly9naXRodWIuY29tL29wZW5zaGlmdC9vcmlnaW4vYmxvYi9tYXN0ZXIvdmVuZG9yL2s4cy5pby9sZWdhY3ktY2xvdWQtcHJvdmlkZXJzL29wZW5zdGFjay9vcGVuc3RhY2tfdm9sdW1lcy5nbyNMNDk4CkFDVElPTj09ImFkZCIsIEVOVntTQ1NJX0lERU5UX0xVTl9WRU5ET1J9PT0iPyoiLCBFTlZ7REVWVFlQRX09PSJkaXNrIiwgUlVOKz0iL2Jpbi9zaCAtYyAnSUQ9JGVudntTQ1NJX0lERU5UX0xVTl9WRU5ET1J9OyBsbiAtcyAuLi8uLi8kbmFtZSAvZGV2L2Rpc2svYnktaWQvc2NzaS0wJGVudntTQ1NJX1ZFTkRPUn1fJGVudntTQ1NJX01PREVMfV8ke0lEOjA6MjB9JyIKQUNUSU9OPT0icmVtb3ZlIiwgRU5We1NDU0lfSURFTlRfTFVOX1ZFTkRPUn09PSI/KiIsIEVOVntERVZUWVBFfT09ImRpc2siLCBSVU4rPSIvYmluL3NoIC1jICdJRD0kZW52e1NDU0lfSURFTlRfTFVOX1ZFTkRPUn07IHJtIC1mIC9kZXYvZGlzay9ieS1pZC9zY3NpLTAkZW52e1NDU0lfVkVORE9SfV8kZW52e1NDU0lfTU9ERUx9XyR7SUQ6MDoyMH0nIgo=' | base64 --decode
# Create symlinks for scsi devices truncated at 20 characters to match OpenShift openstack volume search:
# https://github.com/openshift/origin/blob/master/vendor/k8s.io/legacy-cloud-providers/openstack/openstack_volumes.go#L498
ACTION=="add", ENV{SCSI_IDENT_LUN_VENDOR}=="?*", ENV{DEVTYPE}=="disk", RUN+="/bin/sh -c 'ID=$env{SCSI_IDENT_LUN_VENDOR}; ln -s ../../$name /dev/disk/by-id/scsi-0$env{SCSI_VENDOR}_$env{SCSI_MODEL}_${ID:0:20}'"
ACTION=="remove", ENV{SCSI_IDENT_LUN_VENDOR}=="?*", ENV{DEVTYPE}=="disk", RUN+="/bin/sh -c 'ID=$env{SCSI_IDENT_LUN_VENDOR}; rm -f /dev/disk/by-id/scsi-0$env{SCSI_VENDOR}_$env{SCSI_MODEL}_${ID:0:20}'"

[lab-user@bastion openstack-upi]$ oc create -f $HOME/resources/99-scsi-device-detection-machineconfig.yml
```

### 下载课程教材的脚本
```
cat > download.sh <<'EOF'
#!/bin/bash

wget --referer="http://www.baidu.com" --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6" --header="Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5" --header="Accept-Language: en-us,en;q=0.5" --header="Accept-Encoding: gzip,deflate" --header="Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7" --header="Keep-Alive: 300" --random-wait --no-parent -e robots=off -r -l1 ${1} 
EOF

sh -x download.sh <someurl>
```

### Day2 Training
```
[lab-user@bastion openstack-upi]$ oc explain MachineSet.spec --recursive=true
KIND:     MachineSet
VERSION:  machine.openshift.io/v1beta1

RESOURCE: spec <Object>

DESCRIPTION:
     / [MachineSetSpec] MachineSetSpec defines the desired state of MachineSet

FIELDS:
   deletePolicy <string>
   minReadySeconds      <integer>
   replicas     <integer>
   selector     <Object>
      matchExpressions  <[]Object>
         key    <string>
         operator       <string>
         values <[]string>
      matchLabels       <map[string]string>
   template     <Object>
      metadata  <Object>
         annotations    <map[string]string>
         generateName   <string>
         labels <map[string]string>
         name   <string>
         namespace      <string>
         ownerReferences        <[]Object>
            apiVersion  <string>
            blockOwnerDeletion  <boolean>
            controller  <boolean>
            kind        <string>
            name        <string>
            uid <string>
      spec      <Object>
         metadata       <Object>
            annotations <map[string]string>
            generateName        <string>
            labels      <map[string]string>
            name        <string>
            namespace   <string>
            ownerReferences     <[]Object>
               apiVersion       <string>
               blockOwnerDeletion       <boolean>
               controller       <boolean>
               kind     <string>
               name     <string>
               uid      <string>
         providerID     <string>
         providerSpec   <Object>
            value       <map[string]>
         taints <[]Object>
            effect      <string>
            key <string>
            timeAdded   <string>
            value       <string>

[lab-user@bastion openstack-upi]$ oc get nodes
NAME                           STATUS   ROLES    AGE   VERSION
cluster-wg9lh-zwlg9-master-0   Ready    master   21h   v1.19.0+1833054
cluster-wg9lh-zwlg9-master-1   Ready    master   21h   v1.19.0+1833054
cluster-wg9lh-zwlg9-master-2   Ready    master   21h   v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-0   Ready    worker   20h   v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-1   Ready    worker   20h   v1.19.0+1833054

[lab-user@bastion openstack-upi]$ oc describe node cluster-wg9lh-zwlg9-worker-0
...
Roles:              worker
...
Labels:
...
                    node-role.kubernetes.io/worker=
...
Taints:             <none>

[lab-user@bastion openstack-upi]$ oc get machines -n openshift-machine-api
No resources found in openshift-machine-api namespace.

[lab-user@bastion openstack-upi]$ oc get machineset -n openshift-machine-api 
NAME                           DESIRED   CURRENT   READY   AVAILABLE   AGE
cluster-wg9lh-zwlg9-worker-0   0         0                             21h

[lab-user@bastion openstack-upi]$ oc get machineset cluster-wg9lh-zwlg9-worker-0 -n openshift-machine-api -o yaml 
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
...
  labels:
    machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
    machine.openshift.io/cluster-api-machine-role: worker
    machine.openshift.io/cluster-api-machine-type: worker
...
  name: cluster-wg9lh-zwlg9-worker-0
  namespace: openshift-machine-api
...
spec:
  replicas: 0
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
      machine.openshift.io/cluster-api-machineset: cluster-wg9lh-zwlg9-worker-0
  template:
    metadata:
      labels:
        machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: cluster-wg9lh-zwlg9-worker-0
    spec:
      metadata: {}
      providerSpec:
        value:
          apiVersion: openstackproviderconfig.openshift.io/v1alpha1
          cloudName: openstack
          cloudsSecret:
            name: openstack-cloud-credentials
            namespace: openshift-machine-api
          flavor: 4c16g30d
          image: cluster-wg9lh-zwlg9-rhcos
          kind: OpenstackProviderSpec
          metadata:
            creationTimestamp: null
          networks:
          - filter: {}
            subnets:
            - filter:
                name: cluster-wg9lh-zwlg9-nodes
                tags: openshiftClusterID=cluster-wg9lh-zwlg9
          securityGroups:
          - filter: {}
            name: cluster-wg9lh-zwlg9-worker
          serverMetadata:
            Name: cluster-wg9lh-zwlg9-worker
            openshiftClusterID: cluster-wg9lh-zwlg9
          tags:
          - openshiftClusterID=cluster-wg9lh-zwlg9
          trunk: true
          userDataSecret:
            name: worker-user-data

oc scale machineset cluster-wg9lh-zwlg9-worker-0 --replicas=1 -n openshift-machine-api

[lab-user@bastion openstack-upi]$ oc get machine -n openshift-machine-api
NAME                                 PHASE          TYPE   REGION   ZONE   AGE
cluster-wg9lh-zwlg9-worker-0-pmhp4   Provisioning                          13m

[lab-user@bastion openstack-upi]$ oc describe machine cluster-wg9lh-zwlg9-worker-0-pmhp4 -n openshift-machine-api 
...
Events:
  Type     Reason        Age                 From                  Message
  ----     ------        ----                ----                  -------
  Warning  FailedCreate  3m (x175 over 13m)  openstack_controller  CreateError

[lab-user@bastion openstack-upi]$ openstack server list ^C
[lab-user@bastion openstack-upi]$ oc get pods -n openshift-machine-api
NAME                                           READY   STATUS    RESTARTS   AGE
cluster-autoscaler-operator-5ffb8966c8-kbjrr   2/2     Running   1          21h
machine-api-controllers-85864d65b7-xld7n       7/7     Running   16         21h
machine-api-operator-5bf564d556-mvxql          2/2     Running   1          21h
[lab-user@bastion openstack-upi]$ 

[lab-user@bastion openstack-upi]$ oc logs machine-api-controllers-85864d65b7-xld7n -n openshift-machine-api machine-controller 
...
E0928 03:43:19.843036       1 actuator.go:550] Machine error cluster-wg9lh-zwlg9-worker-0-pmhp4: no image with the name cluster-wg9lh-zwlg9-rhcos could be found
W0928 03:43:19.843976       1 controller.go:316] cluster-wg9lh-zwlg9-worker-0-pmhp4: failed to create machine: no image with the name cluster-wg9lh-zwlg9-rhcos could be found

[lab-user@bastion openstack-upi]$ oc get pods machine-api-controllers-85864d65b7-xld7n -o json -n openshift-machine-api | jq -r .spec.containers[].name
machineset-controller
machine-controller
nodelink-controller
machine-healthcheck-controller
kube-rbac-proxy-machineset-mtrc
kube-rbac-proxy-machine-mtrc
kube-rbac-proxy-mhc-mtrc

[lab-user@bastion openstack-upi]$ oc get machineset -n openshift-machine-api 
NAME                           DESIRED   CURRENT   READY   AVAILABLE   AGE
cluster-wg9lh-zwlg9-worker-0   1         1                             21h

[lab-user@bastion openstack-upi]$ oc get machineset -n openshift-machine-api 
NAME                           DESIRED   CURRENT   READY   AVAILABLE   AGE
cluster-wg9lh-zwlg9-worker-0   1         1                             21h
[lab-user@bastion openstack-upi]$ oc scale machineset cluster-wg9lh-zwlg9-worker-0 --replicas=0 -n openshift-machine-api
machineset.machine.openshift.io/cluster-wg9lh-zwlg9-worker-0 scaled
[lab-user@bastion openstack-upi]$ oc get machineset -n openshift-machine-api
NAME                           DESIRED   CURRENT   READY   AVAILABLE   AGE
cluster-wg9lh-zwlg9-worker-0   0         0                             21h
[lab-user@bastion openstack-upi]$ oc get machines -n openshift-machine-api
No resources found in openshift-machine-api namespace.

[lab-user@bastion openstack-upi]$ oc get -n openshift-machine-api $(oc get machineset -n openshift-machine-api -o name) -o jsonpath='{.spec.template.spec.providerSpec}{"\n"}'
{"value":{"apiVersion":"openstackproviderconfig.openshift.io/v1alpha1","cloudName":"openstack","cloudsSecret":{"name":"openstack-cloud-credentials","namespace":"openshift-machine-api"},"flavor":"4c16g30d","image":"cluster-wg9lh-zwlg9-rhcos","kind":"OpenstackProviderSpec","metadata":{"creationTimestamp":null},"networks":[{"filter":{},"subnets":[{"filter":{"name":"cluster-wg9lh-zwlg9-nodes","tags":"openshiftClusterID=cluster-wg9lh-zwlg9"}}]}],"securityGroups":[{"filter":{},"name":"cluster-wg9lh-zwlg9-worker"}],"serverMetadata":{"Name":"cluster-wg9lh-zwlg9-worker","openshiftClusterID":"cluster-wg9lh-zwlg9"},"tags":["openshiftClusterID=cluster-wg9lh-zwlg9"],"trunk":true,"userDataSecret":{"name":"worker-user-data"}}}

[lab-user@bastion openstack-upi]$ oc patch machineset cluster-wg9lh-zwlg9-worker-0  -n openshift-machine-api --type merge -p '{"spec":{"template":{"spec":{"providerSpec":{"value":{"image":"rhcos-ocp46"}}}}}}'
machineset.machine.openshift.io/cluster-wg9lh-zwlg9-worker-0 patched

[lab-user@bastion openstack-upi]$ oc get -n openshift-machine-api $(oc get machineset -n openshift-machine-api -o name) -o jsonpath='{.spec.template.spec.providerSpec}{"\n"}'
{"value":{"apiVersion":"openstackproviderconfig.openshift.io/v1alpha1","cloudName":"openstack","cloudsSecret":{"name":"openstack-cloud-credentials","namespace":"openshift-machine-api"},"flavor":"4c16g30d","image":"rhcos-ocp46","kind":"OpenstackProviderSpec","metadata":{"creationTimestamp":null},"networks":[{"filter":{},"subnets":[{"filter":{"name":"cluster-wg9lh-zwlg9-nodes","tags":"openshiftClusterID=cluster-wg9lh-zwlg9"}}]}],"securityGroups":[{"filter":{},"name":"cluster-wg9lh-zwlg9-worker"}],"serverMetadata":{"Name":"cluster-wg9lh-zwlg9-worker","openshiftClusterID":"cluster-wg9lh-zwlg9"},"tags":["openshiftClusterID=cluster-wg9lh-zwlg9"],"trunk":true,"userDataSecret":{"name":"worker-user-data"}}}

oc scale machineset cluster-wg9lh-zwlg9-worker-0 --replicas=1 -n openshift-machine-api

E0928 03:58:48.170926       1 actuator.go:550] Machine error cluster-wg9lh-zwlg9-worker-0-8q4r7: error creating Openstack instance: No network was found or provided. Please check your machine configuration and try again

E0928 04:06:38.901543       1 actuator.go:550] Machine error cluster-wg9lh-zwlg9-worker-0-kgrv2: error creating Openstack instance: No network was found or provided. Please check your machine configuration and try again

https://docs.okd.io/latest/machine_management/creating_machinesets/creating-machineset-osp.html



cat > general-purpose-1a.yaml <<EOF
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
    machine.openshift.io/cluster-api-machine-role: worker
    machine.openshift.io/cluster-api-machine-type: worker
  name: general-purpose-1a
  namespace: openshift-machine-api
spec:
  replicas: 0
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
      machine.openshift.io/cluster-api-machineset: general-purpose-1a
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: general-purpose-1a
    spec:
      metadata:
        labels:
          failure-domain.beta.kubernetes.io/region: "regionOne"
          failure-domain.beta.kubernetes.io/zone: "nova"
          node-role.kubernetes.io/general-use: ""
      providerSpec:
        value:
          apiVersion: openstackproviderconfig.openshift.io/v1alpha1
          cloudName: openstack
          cloudsSecret:
            name: openstack-cloud-credentials
            namespace: openshift-machine-api
          flavor: 4c16g30d
          image: rhcos-ocp46
          kind: OpenstackProviderSpec
          networks:
          - filter: {}
            subnets:
            - filter:
                name: wg9lh-ocp-subnet
          securityGroups:
          - filter: {}
            name: wg9lh-worker_sg
          serverMetadata:
            Name: cluster-wg9lh-zwlg9-worker
            openshiftClusterID: cluster-wg9lh-zwlg9
          tags:
          - openshiftClusterID=cluster-wg9lh-zwlg9
          trunk: false
          userDataSecret:
            name: worker-user-data
EOF

cat > general-purpose-1b.yaml <<EOF
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
    machine.openshift.io/cluster-api-machine-role: worker
    machine.openshift.io/cluster-api-machine-type: worker
  name: general-purpose-1b
  namespace: openshift-machine-api
spec:
  replicas: 0
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
      machine.openshift.io/cluster-api-machineset: general-purpose-1b
  template:
    metadata:
      creationTimestamp: null
      labels:
        machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: general-purpose-1b
    spec:
      metadata:
        labels:
          failure-domain.beta.kubernetes.io/region: "regionOne"
          failure-domain.beta.kubernetes.io/zone: "nova"
          node-role.kubernetes.io/general-use: ""
      providerSpec:
        value:
          apiVersion: openstackproviderconfig.openshift.io/v1alpha1
          cloudName: openstack
          cloudsSecret:
            name: openstack-cloud-credentials
            namespace: openshift-machine-api
          flavor: 4c16g30d
          image: rhcos-ocp46
          kind: OpenstackProviderSpec
          networks:
          - filter: {}
            subnets:
            - filter:
                name: wg9lh-ocp-subnet
          securityGroups:
          - filter: {}
            name: wg9lh-worker_sg
          serverMetadata:
            Name: cluster-wg9lh-zwlg9-worker
            openshiftClusterID: cluster-wg9lh-zwlg9
          tags:
          - openshiftClusterID=cluster-wg9lh-zwlg9
          trunk: false
          userDataSecret:
            name: worker-user-data
EOF

[lab-user@bastion openstack-upi]$ oc create -f general-purpose-1a.yaml -n openshift-machine-api
machineset.machine.openshift.io/general-purpose-1a created
[lab-user@bastion openstack-upi]$ oc create -f general-purpose-1b.yaml -n openshift-machine-api
machineset.machine.openshift.io/general-purpose-1b created

oc get machineset -n openshift-machine-api
oc scale machineset general-purpose-1a --replicas=1 -n openshift-machine-api
oc scale machineset general-purpose-1b --replicas=1 -n openshift-machine-api



machine set cluster-wg9lh-zwlg9-worker-0 的错误内容可以参考 general-purpose-1b 

除了对象错误外，metadata: {} 也是错误的
      metadata:
        labels:
          failure-domain.beta.kubernetes.io/region: "regionOne"
          failure-domain.beta.kubernetes.io/zone: "nova"

把 yaml 文件内容修改完后
[lab-user@bastion openstack-upi]$ oc get machines -n openshift-machine-api 
NAME                                 PHASE     TYPE       REGION      ZONE   AGE
cluster-wg9lh-zwlg9-worker-0-zsvcb   Running   4c16g30d   regionOne   nova   8m49s
general-purpose-1a-2dc2l             Running   4c16g30d   regionOne   nova   17m
general-purpose-1b-5f48k             Running   4c16g30d   regionOne   nova   17m

[lab-user@bastion openstack-upi]$ oc get nodes
NAME                                 STATUS   ROLES                AGE    VERSION
cluster-wg9lh-zwlg9-master-0         Ready    master               23h    v1.19.0+1833054
cluster-wg9lh-zwlg9-master-1         Ready    master               23h    v1.19.0+1833054
cluster-wg9lh-zwlg9-master-2         Ready    master               23h    v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-0         Ready    worker               22h    v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-0-zsvcb   Ready    worker               55s    v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-1         Ready    worker               22h    v1.19.0+1833054
general-purpose-1a-2dc2l             Ready    general-use,worker   9m4s   v1.19.0+1833054
general-purpose-1b-5f48k             Ready    general-use,worker   8m4s   v1.19.0+1833054

[lab-user@bastion openstack-upi]$ oc adm cordon cluster-wg9lh-zwlg9-worker-0-zsvcb 
node/cluster-wg9lh-zwlg9-worker-0-zsvcb cordoned
[lab-user@bastion openstack-upi]$ oc adm cordon general-purpose-1a-2dc2l 
node/general-purpose-1a-2dc2l cordoned
[lab-user@bastion openstack-upi]$ oc adm cordon general-purpose-1b-5f48k 
node/general-purpose-1b-5f48k cordoned 

[lab-user@bastion openstack-upi]$ oc adm drain node/cluster-wg9lh-zwlg9-worker-0-zsvcb --ignore-daemonsets --delete-local-data --force
node/cluster-wg9lh-zwlg9-worker-0-zsvcb already cordoned
WARNING: ignoring DaemonSet-managed Pods: openshift-cluster-node-tuning-operator/tuned-lph74, openshift-dns/dns-default-xcxs7, openshift-image-registry/node-ca-n6sz8, openshift-machine-config-operator/machine-config-daemon-zgjhc, openshift-monitoring/node-exporter-6z22d, openshift-multus/multus-8nf9v, openshift-multus/network-metrics-daemon-ft4s9, openshift-sdn/ovs-fbbsl, openshift-sdn/sdn-c8h9n
node/cluster-wg9lh-zwlg9-worker-0-zsvcb drained

[lab-user@bastion openstack-upi]$ oc adm drain node/general-purpose-1a-2dc2l --ignore-daemonsets --delete-local-data --force
node/general-purpose-1a-2dc2l already cordoned
WARNING: ignoring DaemonSet-managed Pods: openshift-cluster-node-tuning-operator/tuned-ntk84, openshift-dns/dns-default-rlr5m, openshift-image-registry/node-ca-ghwxx, openshift-machine-config-operator/machine-config-daemon-bvcd9, openshift-monitoring/node-exporter-g9th4, openshift-multus/multus-wsgl8, openshift-multus/network-metrics-daemon-wjqwf, openshift-sdn/ovs-dbwhn, openshift-sdn/sdn-jq9wj
node/general-purpose-1a-2dc2l drained

[lab-user@bastion openstack-upi]$ oc adm drain node/general-purpose-1b-5f48k --ignore-daemonsets --delete-local-data --force
node/general-purpose-1b-5f48k already cordoned
WARNING: ignoring DaemonSet-managed Pods: openshift-cluster-node-tuning-operator/tuned-6jxnb, openshift-dns/dns-default-f8p5k, openshift-image-registry/node-ca-kxsmv, openshift-machine-config-operator/machine-config-daemon-mmzd4, openshift-monitoring/node-exporter-5mwtf, openshift-multus/multus-6qjt2, openshift-multus/network-metrics-daemon-hmz99, openshift-sdn/ovs-5qt74, openshift-sdn/sdn-4x6tj
node/general-purpose-1b-5f48k drained

[lab-user@bastion openstack-upi]$ oc get nodes
NAME                                 STATUS                     ROLES                AGE   VERSION
cluster-wg9lh-zwlg9-master-0         Ready                      master               23h   v1.19.0+1833054
cluster-wg9lh-zwlg9-master-1         Ready                      master               23h   v1.19.0+1833054
cluster-wg9lh-zwlg9-master-2         Ready                      master               23h   v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-0         Ready                      worker               22h   v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-0-zsvcb   Ready,SchedulingDisabled   worker               6m    v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-1         Ready                      worker               22h   v1.19.0+1833054
general-purpose-1a-2dc2l             Ready,SchedulingDisabled   general-use,worker   14m   v1.19.0+1833054
general-purpose-1b-5f48k             Ready,SchedulingDisabled   general-use,worker   13m   v1.19.0+1833054

[lab-user@bastion openstack-upi]$ oc get machines -n openshift-machine-api 
NAME                       PHASE     TYPE       REGION      ZONE   AGE
general-purpose-1a-bs6cs   Running   4c16g30d   regionOne   nova   11m
general-purpose-1b-gwczt   Running   4c16g30d   regionOne   nova   11m

[lab-user@bastion openstack-upi]$ oc get nodes
NAME                           STATUS   ROLES                AGE     VERSION
cluster-wg9lh-zwlg9-master-0   Ready    master               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-master-1   Ready    master               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-master-2   Ready    master               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-0   Ready    worker               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-1   Ready    worker               23h     v1.19.0+1833054
general-purpose-1a-bs6cs       Ready    general-use,worker   3m15s   v1.19.0+1833054
general-purpose-1b-gwczt       Ready    general-use,worker   3m21s   v1.19.0+1833054

[lab-user@bastion openstack-upi]$ oc adm cordon cluster-wg9lh-zwlg9-worker-0
node/cluster-wg9lh-zwlg9-worker-0 cordoned
[lab-user@bastion openstack-upi]$ oc adm cordon cluster-wg9lh-zwlg9-worker-1
node/cluster-wg9lh-zwlg9-worker-1 cordoned

[lab-user@bastion openstack-upi]$ oc adm drain node/cluster-wg9lh-zwlg9-worker-0 --ignore-daemonsets --delete-local-data --force
[lab-user@bastion openstack-upi]$ oc adm drain node/cluster-wg9lh-zwlg9-worker-1 --ignore-daemonsets --delete-local-data --force

[lab-user@bastion openstack-upi]$ oc get nodes
NAME                           STATUS                     ROLES                AGE     VERSION
cluster-wg9lh-zwlg9-master-0   Ready                      master               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-master-1   Ready                      master               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-master-2   Ready                      master               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-0   Ready,SchedulingDisabled   worker               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-worker-1   Ready,SchedulingDisabled   worker               23h     v1.19.0+1833054
general-purpose-1a-bs6cs       Ready                      general-use,worker   7m59s   v1.19.0+1833054
general-purpose-1b-gwczt       Ready                      general-use,worker   8m5s    v1.19.0+1833054

[lab-user@bastion openstack-upi]$ oc delete node cluster-wg9lh-zwlg9-worker-0 cluster-wg9lh-zwlg9-worker-1
node "cluster-wg9lh-zwlg9-worker-0" deleted
node "cluster-wg9lh-zwlg9-worker-1" deleted

[lab-user@bastion openstack-upi]$ oc get nodes
NAME                           STATUS   ROLES                AGE     VERSION
cluster-wg9lh-zwlg9-master-0   Ready    master               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-master-1   Ready    master               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-master-2   Ready    master               23h     v1.19.0+1833054
general-purpose-1a-bs6cs       Ready    general-use,worker   8m59s   v1.19.0+1833054
general-purpose-1b-gwczt       Ready    general-use,worker   9m5s    v1.19.0+1833054

3.5. Delete VMs from OpenStack
[lab-user@bastion openstack-upi]$ openstack server list --name $INFRA_ID-worker -f value -c ID | xargs openstack server delete

[lab-user@bastion openstack-upi]$ openstack server list -c ID -c Name -c Status
+--------------------------------------+------------------------------+--------+
| ID                                   | Name                         | Status |
+--------------------------------------+------------------------------+--------+
| 6f12dc68-049b-42fd-91cf-9352fe81dbed | general-purpose-1b-gwczt     | ACTIVE |
| 43e54581-c3e2-4ac5-99c1-280697909f79 | general-purpose-1a-bs6cs     | ACTIVE |
| 1747c318-9cdd-4650-ab74-c9bfd803e802 | cluster-wg9lh-zwlg9-master-2 | ACTIVE |
| e610454c-4503-417c-99e5-5f24b51d8cb2 | cluster-wg9lh-zwlg9-master-1 | ACTIVE |
| 1ce1100a-770b-4f3a-8eb8-97bd1786f1bf | cluster-wg9lh-zwlg9-master-0 | ACTIVE |
| c95fa0e4-0f24-4996-a44f-6fafd0ab80b4 | bastion                      | ACTIVE |
| f3e6f3be-012a-4e9f-b37c-ffc85073f775 | utilityvm                    | ACTIVE |
+--------------------------------------+------------------------------+--------+

cat > $HOME/infra-1a.yaml <<EOF
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
    machine.openshift.io/cluster-api-machine-role: worker
    machine.openshift.io/cluster-api-machine-type: worker
  name: infra-1a
  namespace: openshift-machine-api
spec:
  replicas: 1
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
      machine.openshift.io/cluster-api-machineset: infra-1a
  template:
    metadata:
      labels:
        machine.openshift.io/cluster-api-cluster: cluster-wg9lh-zwlg9
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: infra-1a
    spec:
      metadata:
        labels:
          failure-domain.beta.kubernetes.io/region: "regionOne"
          failure-domain.beta.kubernetes.io/zone: "nova"
          node-role.kubernetes.io/infra: ""
      providerSpec:
        value:
          apiVersion: openstackproviderconfig.openshift.io/v1alpha1
          cloudName: openstack
          cloudsSecret:
            name: openstack-cloud-credentials
            namespace: openshift-machine-api
          flavor: 4c16g30d
          image: rhcos-ocp46
          kind: OpenstackProviderSpec
          metadata:
            creationTimestamp: null
          networks:
          - filter: {}
            subnets:
            - filter:
                name: wg9lh-ocp-subnet
          securityGroups:
          - filter: {}
            name: wg9lh-worker_sg
          serverMetadata:
            Name: cluster-wg9lh-zwlg9-worker
            openshiftClusterID: cluster-wg9lh-zwlg9
          tags:
          - openshiftClusterID=cluster-wg9lh-zwlg9
          trunk: false
          userDataSecret:
            name: worker-user-data
EOF

[lab-user@bastion openstack-upi]$ oc create -f $HOME/infra-1a.yaml 
machineset.machine.openshift.io/infra-1a created

[lab-user@bastion openstack-upi]$ oc get machines -n openshift-machine-api 
NAME                       PHASE     TYPE       REGION      ZONE   AGE
general-purpose-1a-bs6cs   Running   4c16g30d   regionOne   nova   36m
general-purpose-1b-gwczt   Running   4c16g30d   regionOne   nova   36m
infra-1a-kbf7z             Running   4c16g30d   regionOne   nova   11m

[lab-user@bastion openstack-upi]$ oc get nodes
NAME                           STATUS   ROLES                AGE     VERSION
cluster-wg9lh-zwlg9-master-0   Ready    master               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-master-1   Ready    master               23h     v1.19.0+1833054
cluster-wg9lh-zwlg9-master-2   Ready    master               23h     v1.19.0+1833054
general-purpose-1a-bs6cs       Ready    general-use,worker   28m     v1.19.0+1833054
general-purpose-1b-gwczt       Ready    general-use,worker   28m     v1.19.0+1833054
infra-1a-kbf7z                 Ready    infra,worker         3m31s   v1.19.0+1833054s

[lab-user@bastion openstack-upi]$ oc explain clusterautoscaler.spec --recursive=true
KIND:     ClusterAutoscaler
VERSION:  autoscaling.openshift.io/v1

RESOURCE: spec <Object>

DESCRIPTION:
     Desired state of ClusterAutoscaler resource

FIELDS:
   balanceSimilarNodeGroups     <boolean>
   ignoreDaemonsetsUtilization  <boolean>
   maxNodeProvisionTime <string>
   maxPodGracePeriod    <integer>
   podPriorityThreshold <integer>
   resourceLimits       <Object>
      cores     <Object>
         max    <integer>
         min    <integer>
      gpus      <[]Object>
         max    <integer>
         min    <integer>
         type   <string>
      maxNodesTotal     <integer>
      memory    <Object>
         max    <integer>
         min    <integer>
   scaleDown    <Object>
      delayAfterAdd     <string>
      delayAfterDelete  <string>
      delayAfterFailure <string>
      enabled   <boolean>
      unneededTime      <string>
   skipNodesWithLocalStorage    <boolean>

oc explain clusterautoscaler.spec.balanceSimilarNodeGroups
[lab-user@bastion openstack-upi]$ oc explain clusterautoscaler.spec.balanceSimilarNodeGroups

[lab-user@bastion openstack-upi]$ oc project openshift-machine-api
Now using project "openshift-machine-api" on server "https://api.cluster-wg9lh.dynamic.opentlc.com:6443".

[lab-user@bastion openstack-upi]$ oc get machineset
NAME                           DESIRED   CURRENT   READY   AVAILABLE   AGE
cluster-wg9lh-zwlg9-worker-0   0         0                             24h
general-purpose-1a             1         1         1       1           72m
general-purpose-1b             1         1         1       1           72m
infra-1a                       1         1         1       1           17m


[lab-user@bastion openstack-upi]$ echo "apiVersion: autoscaling.openshift.io/v1beta1
> kind: MachineAutoscaler
> metadata:
>   name: ma-general-purpose-1a
>   namespace: openshift-machine-api
> spec:
>   minReplicas: 1
>   maxReplicas: 4
>   scaleTargetRef:
>     apiVersion: machine.openshift.io/v1beta1
>     kind: MachineSet
>     name: general-purpose-1a" | oc create -f - -n openshift-machine-api
machineautoscaler.autoscaling.openshift.io/ma-general-purpose-1a created

echo "apiVersion: autoscaling.openshift.io/v1beta1
kind: MachineAutoscaler
metadata:
  name: ma-general-purpose-1b
  namespace: openshift-machine-api
spec:
  minReplicas: 1
  maxReplicas: 4
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: general-purpose-1b" | oc create -f - -n openshift-machine-api

[lab-user@bastion openstack-upi]$ echo "apiVersion: autoscaling.openshift.io/v1beta1
> kind: MachineAutoscaler
> metadata:
>   name: ma-general-purpose-1b
>   namespace: openshift-machine-api
> spec:
>   minReplicas: 1
>   maxReplicas: 4
>   scaleTargetRef:
>     apiVersion: machine.openshift.io/v1beta1
>     kind: MachineSet
>     name: general-purpose-1b" | oc create -f - -n openshift-machine-api
machineautoscaler.autoscaling.openshift.io/ma-general-purpose-1b created

[lab-user@bastion openstack-upi]$ oc get machineautoscaler
NAME                    REF KIND     REF NAME             MIN   MAX   AGE
ma-general-purpose-1a   MachineSet   general-purpose-1a   1     4     30s
ma-general-purpose-1b   MachineSet   general-purpose-1b   1     4     14s

echo "
apiVersion: autoscaling.openshift.io/v1
kind: ClusterAutoscaler
metadata:
  name: default
spec:
  balanceSimilarNodeGroups: true
  podPriorityThreshold: -10
  resourceLimits:
    maxNodesTotal: 12
    cores:
      min: 4
      max: 48
    memory:
      min: 16
      max: 156
  scaleDown:
    enabled: true
    delayAfterAdd: 5m
    delayAfterDelete: 5m
    delayAfterFailure: 5m
    unneededTime: 60s" | oc create -f -

[lab-user@bastion openstack-upi]$ echo "
> apiVersion: autoscaling.openshift.io/v1
> kind: ClusterAutoscaler
> metadata:
>   name: default
> spec:
>   balanceSimilarNodeGroups: true
>   podPriorityThreshold: -10
>   resourceLimits:
>     maxNodesTotal: 12
>     cores:
>       min: 4
>       max: 48
>     memory:
>       min: 16
>       max: 156
>   scaleDown:
>     enabled: true
>     delayAfterAdd: 5m
>     delayAfterDelete: 5m
>     delayAfterFailure: 5m
>     unneededTime: 60s" | oc create -f -
clusterautoscaler.autoscaling.openshift.io/default created

[lab-user@bastion openstack-upi]$ oc describe clusterautoscaler default
...
  UID:               1adb743c-270d-47e4-af31-adccd4232ce1
Spec:
  Balance Similar Node Groups:  true
  Pod Priority Threshold:       -10
  Resource Limits:
    Cores:
      Max:            48
      Min:            4
    Max Nodes Total:  12
    Memory:
      Max:  156
      Min:  16
  Scale Down:
    Delay After Add:      5m
    Delay After Delete:   5m
    Delay After Failure:  5m
    Enabled:              true
    Unneeded Time:        60s
Events:                   <none>

oc get machineset general-purpose-1a -o json | jq '.metadata.annotations'
oc get machineset general-purpose-1b -o json | jq '.metadata.annotations'

[lab-user@bastion openstack-upi]$ oc get machineset general-purpose-1a -o json | jq '.metadata.annotations'
{
  "autoscaling.openshift.io/machineautoscaler": "openshift-machine-api/ma-general-purpose-1a",
  "machine.openshift.io/cluster-api-autoscaler-node-group-max-size": "4",
  "machine.openshift.io/cluster-api-autoscaler-node-group-min-size": "1"
}
[lab-user@bastion openstack-upi]$ oc get machineset general-purpose-1b -o json | jq '.metadata.annotations'
{
  "autoscaling.openshift.io/machineautoscaler": "openshift-machine-api/ma-general-purpose-1b",
  "machine.openshift.io/cluster-api-autoscaler-node-group-max-size": "4",
  "machine.openshift.io/cluster-api-autoscaler-node-group-min-size": "1"
}

[lab-user@bastion openstack-upi]$ oc get pods
NAME                                           READY   STATUS    RESTARTS   AGE
cluster-autoscaler-default-54957d4cf5-29ssf    1/1     Running   0          2m31s
cluster-autoscaler-operator-5ffb8966c8-kbjrr   2/2     Running   1          24h
machine-api-controllers-85864d65b7-xld7n       7/7     Running   17         24h
machine-api-operator-5bf564d556-mvxql          2/2     Running   1          24h

oc logs cluster-autoscaler-default-54957d4cf5-29ssf -n openshift-machine-api 

oc new-project work-queue

echo 'apiVersion: batch/v1
kind: Job
metadata:
  generateName: work-queue-
spec:
  template:
    spec:
      containers:
      - name: work
        image: busybox
        command: ["sleep",  "300"]
        resources:
          requests:
            memory: 500Mi
            cpu: 300m
      restartPolicy: Never
      nodeSelector:
        node-role.kubernetes.io/general-use: ""
  parallelism: 50
  completions: 50' | oc create -f - -n work-queue

oc logs cluster-autoscaler-default-54957d4cf5-29ssf -n openshift-machine-api -f 

watch -n 10 "oc get machines -n openshift-machine-api"

watch -n 10 "oc get nodes"

[lab-user@bastion ~]$ oc logs cluster-autoscaler-default-54957d4cf5-29ssf -n openshift-machine-api | grep -E "Scale-up: setting group openshift-machine-api/general-purpose"
I0928 06:18:13.074461       1 scale_up.go:663] Scale-up: setting group openshift-machine-api/general-purpose-1b size to 3
I0928 06:18:13.785987       1 scale_up.go:663] Scale-up: setting group openshift-machine-api/general-purpose-1a size to 2



CleanUp
oc delete project work-queue

oc delete machineautoscaler ma-general-purpose-1a ma-general-purpose-1b -n openshift-machine-api
oc delete clusterautoscaler default

for i in $(oc get machineset -n openshift-machine-api -o name);do oc patch $i --type=merge -p '{"spec": {"template": {"spec": {"metadata": {"labels": {"failure-domain.beta.kubernetes.io/zone": "nova"}}}}}}';done

for i in $(oc get machineset -n openshift-machine-api -o name);do oc patch $i --type=merge -p '{"spec": {"template": {"spec": {"metadata": {"labels": {"failure-domain.beta.kubernetes.io/region": "regionOne"}}}}}}';done


1.1. Configure API Certificate
ansible localhost -m lineinfile -a 'path=~/.bashrc regexp="^export API_HOSTNAME" line="export API_HOSTNAME='$(oc whoami --show-server | sed -r 's|.*//(.*):.*|\1|')'"'

ansible localhost -m lineinfile -a 'path=~/.bashrc regexp="^export INGRESS_DOMAIN" line="export INGRESS_DOMAIN='$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')'"'

source ~/.bashrc

oc create secret tls cluster-apiserver-tls --cert=$HOME/certificates/cert.pem --key=$HOME/certificates/privkey.pem -n openshift-config

echo oc patch apiservers.config.openshift.io cluster --type=merge -p '{"spec":{"servingCerts": {"namedCertificates": [{"names": ["'$API_HOSTNAME'"], "servingCertificate": {"name": "cluster-apiserver-tls"}}]}}}'

oc patch apiservers.config.openshift.io cluster --type=merge -p '{"spec":{"servingCerts": {"namedCertificates": [{"names": ["'$API_HOSTNAME'"], "servingCertificate": {"name": "cluster-apiserver-tls"}}]}}}'

watch oc get co

curl https://$API_HOSTNAME:6443/healthz -v

oc login -u system:admin $API_HOSTNAME:6443 

[lab-user@bastion openstack-upi]$ oc config set-cluster cluster-$GUID --certificate-authority=$HOME/certificates/chain.pem
Cluster "cluster-wg9lh" set.

If the oc config command above does not work you can just delete every line starting with certificate-authority-data: from your kube config files.

oc login -u system:admin

sudo cp ~/certificates/fullchain.pem /etc/pki/ca-trust/source/anchors
sudo update-ca-trust

[lab-user@bastion openstack-upi]$ oc debug node/cluster-wg9lh-zwlg9-master-0 
Creating debug namespace/openshift-debug-node-28zvn ...
Removing debug namespace/openshift-debug-node-28zvn ...
Delete "https://api.cluster-wg9lh.dynamic.opentlc.com:6443/api/v1/namespaces/openshift-debug-node-28zvnsvt8w": read tcp 192.168.47.100:39138->52.116.164.174:6443: read: connection reset by peer
Error from server (Forbidden): pods "cluster-wg9lh-zwlg9-master-0-debug" is forbidden: error looking up service account openshift-debug-node-28zvnsvt8w/default: serviceaccount "default" not found


1.2. Configure Ingress Default Certificate

[lab-user@bastion openstack-upi]$ oc project default
Now using project "default" on server "https://api.cluster-wg9lh.dynamic.opentlc.com:6443".

[lab-user@bastion openstack-upi]$ oc create secret tls default-ingress-tls --cert=$HOME/certificates/fullchain.pem --key=$HOME/certificates/privkey.pem -n openshift-ingress
secret/default-ingress-tls created

[lab-user@bastion openstack-upi]$ oc patch ingresscontroller.operator default --type=merge -p '{"spec":{"defaultCertificate": {"name": "default-ingress-tls"}}}' -n openshift-ingress-operator
ingresscontroller.operator.openshift.io/default patched

[lab-user@bastion openstack-upi]$ watch oc get pod -n openshift-ingress

watch oc get co

curl $(oc whoami --show-console) -v | head -1

2. Delegating Cluster Admin Rights
cd $HOME
touch $HOME/htpasswd
htpasswd -Bb $HOME/htpasswd andrew openshift
htpasswd -Bb $HOME/htpasswd david openshift
htpasswd -Bb $HOME/htpasswd karla openshift

oc create secret generic htpasswd --from-file=$HOME/htpasswd -n openshift-config

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: Local Password
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpasswd
EOF

watch oc get pod -n openshift-authentication

oc login -u andrew -p openshift $(oc whoami --show-server)

oc login -u system:admin

2.2. Delegate cluster-admin privileges
oc adm groups new lab-cluster-admins david karla

oc adm policy add-cluster-role-to-group cluster-admin lab-cluster-admins --rolebinding-name=lab-cluster-admins

oc login -u karla -p openshift $(oc whoami --show-server)
oc auth can-i delete node

2.3. Disable the kubeadmin user
oc delete secret kubeadmin -n kube-system



3. Configure the Container Image Registry
[lab-user@bastion ~]$ oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"defaultRoute":true}}'
config.imageregistry.operator.openshift.io/cluster patched

[lab-user@bastion ~]$ oc get configs.imageregistry.operator.openshift.io/cluster -o jsonpath='{.spec.defaultRoute}{"\n"}'
true

[lab-user@bastion ~]$ oc get route -n openshift-image-registry
NAME            HOST/PORT                                                                       PATH   SERVICES         PORT    TERMINATION   WILDCARD
default-route   default-route-openshift-image-registry.apps.cluster-wg9lh.dynamic.opentlc.com          image-registry   <all>   reencrypt     None

oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"routes":[{"name":"image-registry", "hostname":"image-registry.'$INGRESS_DOMAIN'"}]}}'

oc get route -n openshift-image-registry
[lab-user@bastion openstack-upi]$ oc get route -n openshift-image-registry
NAME             HOST/PORT                                                                       PATH   SERVICES         PORT    TERMINATION   WILDCARD
default-route    default-route-openshift-image-registry.apps.cluster-wg9lh.dynamic.opentlc.com          image-registry   <all>   reencrypt     None
image-registry   image-registry.apps.cluster-wg9lh.dynamic.opentlc.com                                  image-registry   <all>   reencrypt     None

curl https://$(oc get route -n openshift-image-registry image-registry -o jsonpath='{.spec.host}')/healthz -v

3.2. Configure a service account to push images to the registry
oc create serviceaccount registry-admin -n openshift-config

oc adm policy add-cluster-role-to-user registry-admin system:serviceaccount:openshift-config:registry-admin

oc create imagestream ubi8 -n openshift

REGISTRY_ADMIN_TOKEN=$(oc sa get-token -n openshift-config registry-admin)
UBI8_IMAGE_REPO="image-registry.$INGRESS_DOMAIN/openshift/ubi8"
skopeo copy docker://registry.access.redhat.com/ubi8:latest docker://$UBI8_IMAGE_REPO:latest --dest-creds -:$REGISTRY_ADMIN_TOKEN

podman pull $UBI8_IMAGE_REPO:latest --creds -:$REGISTRY_ADMIN_TOKEN
podman images

4. Configure SSH access to nodes
oc login -u system:admin
oc get machineconfigs.machineconfiguration.openshift.io
oc get machineconfig 99-worker-ssh -o yaml

oc new-project node-ssh

oc new-build openshift/ubi8:latest --name=node-ssh --dockerfile - <<EOF
FROM unused
RUN dnf install -y openssh-clients
CMD ["sleep", "infinity"]
EOF

oc logs -f node-ssh-1-build

oc create secret generic node-ssh --from-file=id_rsa=$HOME/.ssh/${GUID}key.pem -n node-ssh

NODE_SSH_IMAGE=$(oc get imagestream node-ssh -o jsonpath='{.status.dockerImageRepository}' -n node-ssh)
oc create deployment node-ssh --image=$NODE_SSH_IMAGE:latest --dry-run=client -o yaml -n node-ssh > $HOME/node-ssh.deployment.yaml

[lab-user@bastion openstack-upi]$ cat ~/node-ssh.deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: node-ssh
  name: node-ssh
  namespace: node-ssh
spec:
  replicas: 1
  selector:
    matchLabels:
      app: node-ssh
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: node-ssh
    spec:
      containers:
      - image: image-registry.openshift-image-registry.svc:5000/node-ssh/node-ssh:latest
        name: node-ssh
        resources: {}
        volumeMounts:
        - name: node-ssh
          mountPath: /.ssh
      volumes:
      - name: node-ssh
        secret:
          secretName: node-ssh
          defaultMode: 0600        
status: {}

oc apply -f $HOME/node-ssh.deployment.yaml

[lab-user@bastion openstack-upi]$ oc get node -l node-role.kubernetes.io/worker -o wide
NAME                       STATUS   ROLES                AGE    VERSION           INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                                                       KERNEL-VERSION                 CONTAINER-RUNTIME
general-purpose-1a-bs6cs   Ready    general-use,worker   166m   v1.19.0+1833054   192.168.47.174   <none>        Red Hat Enterprise Linux CoreOS 46.82.202101262043-0 (Ootpa)   4.18.0-193.41.1.el8_2.x86_64   cri-o://1.19.1-6.rhaos4.6.git6de578b.el8
general-purpose-1b-gwczt   Ready    general-use,worker   166m   v1.19.0+1833054   192.168.47.46    <none>        Red Hat Enterprise Linux CoreOS 46.82.202101262043-0 (Ootpa)   4.18.0-193.41.1.el8_2.x86_64   cri-o://1.19.1-6.rhaos4.6.git6de578b.el8
infra-1a-kbf7z             Ready    infra,worker         142m   v1.19.0+1833054   192.168.47.104   <none>        Red Hat Enterprise Linux CoreOS 46.82.202101262043-0 (Ootpa)   4.18.0-193.41.1.el8_2.x86_64   cri-o://1.19.1-6.rhaos4.6.git6de578b.el8

NODE_SSH_POD=$(oc get pod -l app=node-ssh -o jsonpath='{.items[0].metadata.name}')

oc exec -it $NODE_SSH_POD -- ssh core@192.168.47.104

4.2. Add an SSH key for worker machine access
ssh-keygen -t rsa -f $HOME/.ssh/node.id_rsa -N ''
cat $HOME/.ssh/node.id_rsa.pub


oc patch machineconfig 99-worker-ssh --type=json --patch="[{\"op\":\"add\", \"path\":\"/spec/config/passwd/users/0/sshAuthorizedKeys/-\", \"value\":\"$(cat $HOME/.ssh/node.id_rsa.pub)\"}]"

oc patch machineconfig 99-master-ssh --type=json --patch="[{\"op\":\"add\", \"path\":\"/spec/config/passwd/users/0/sshAuthorizedKeys/-\", \"value\":\"$(cat $HOME/.ssh/node.id_rsa.pub)\"}]"

watch oc get nodes
watch oc get nodes

oc delete secret node-ssh -n node-ssh
oc create secret generic node-ssh --from-file=id_rsa=$HOME/.ssh/node.id_rsa -n node-ssh
oc delete pod -l app=node-ssh -n node-ssh
NODE_SSH_POD=$(oc get pod -l app=node-ssh -o jsonpath='{.items[0].metadata.name}' -n node-ssh)

oc -n node-ssh exec -it $NODE_SSH_POD -- ssh core@192.168.47.24

2. Explore the Operator from Command Line
[lab-user@bastion openstack-upi]$ oc get all -n openshift-operators 
NAME                                READY   STATUS    RESTARTS   AGE
pod/nfd-operator-76d979cdc5-fxn52   1/1     Running   0          118m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nfd-operator   1/1     1            1           118m

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/nfd-operator-76d979cdc5   1         1         1       118m
oc get events -n openshift-operators

[lab-user@bastion openstack-upi]$ oc get all -n openshift-nfd
NAME                   READY   STATUS    RESTARTS   AGE
pod/nfd-master-7cxh7   1/1     Running   0          3m56s
pod/nfd-master-gz8vn   1/1     Running   0          3m56s
pod/nfd-master-hm2w7   1/1     Running   0          3m56s
pod/nfd-worker-l2dbg   1/1     Running   0          3m55s
pod/nfd-worker-l2lmd   1/1     Running   0          3m55s
pod/nfd-worker-xt4k4   1/1     Running   0          3m55s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
service/nfd-master   ClusterIP   172.30.98.135   <none>        12000/TCP   3m56s

NAME                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                     AGE
daemonset.apps/nfd-master   3         3         3       3            3           node-role.kubernetes.io/master=   3m56s
daemonset.apps/nfd-worker   3         3         3       3            3           <none>                            3m55s

```

```
oc -n openshift-apiserver-operator logs $(oc -n openshift-apiserver-operator get pods -o name)
...
I0928 09:33:59.711161       1 event.go:282] Event(v1.ObjectReference{Kind:"Deployment", Namespace:"openshift-apiserver-operator", Name:"openshift-apiserver-operator", UID:"cb5541d6-063b-4770-9795-8736765da582", APIVersion:"apps/v1", ResourceVersion:"", FieldPath:""}): type: 'Normal' reason: 'OperatorStatusChanged' Status for clusteroperator/openshift-apiserver changed: Degraded message changed from "APIServerDeploymentDegraded: 1 of 3 requested instances are unavailable for apiserver.openshift-apiserver (container is crashlooping in apiserver-5ccbc9f676-lms8j pod)" to "APIServerDeploymentDegraded: 1 of 3 requested instances are unavailable for apiserver.openshift-apiserver (crashlooping container is waiting in apiserver-5ccbc9f676-lms8j pod)"
1. Install Operator using Web Console


[lab-user@bastion openstack-upi]$ oc logs -p apiserver-5ccbc9f676-lms8j openshift-apiserver -n openshift-apiserver | grep -i fail
I0928 09:36:40.151498       1 healthz.go:243] healthz check failed: poststarthook/authorization.openshift.io-bootstrapclusterroles,poststarthook/authorization.openshift.io-ensureopenshift-infra
[-]poststarthook/authorization.openshift.io-bootstrapclusterroles failed: not finished
[-]poststarthook/authorization.openshift.io-ensureopenshift-infra failed: not finished
I0928 09:36:48.581142       1 healthz.go:243] healthz check failed: poststarthook/authorization.openshift.io-bootstrapclusterroles
[-]poststarthook/authorization.openshift.io-bootstrapclusterroles failed: not finished
I0928 09:36:51.012461       1 healthz.go:243] healthz check failed: poststarthook/authorization.openshift.io-bootstrapclusterroles
[-]poststarthook/authorization.openshift.io-bootstrapclusterroles failed: not finished


[lab-user@bastion openstack-upi]$ oc get subscription -n openshift-operators
NAME   PACKAGE   SOURCE             CHANNEL
nfd    nfd       redhat-operators   4.6

4. Install Operator Using CLI
oc get packagemanifests -n openshift-marketplace

oc describe packagemanifests nfd -n openshift-marketplace

echo "apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nfd
  namespace: openshift-operators
spec:
  channel: '4.6'
  installPlanApproval: Automatic
  name: nfd
  source: redhat-operators
  sourceNamespace: openshift-marketplace" >$HOME/nfd-sub.yaml

oc apply -f $HOME/nfd-sub.yaml

oc get installplan -n openshift-operators

oc get csv -n openshift-operators

oc get pods -n openshift-operators

echo "apiVersion: nfd.openshift.io/v1alpha1
kind: NodeFeatureDiscovery
metadata:
  name: nfd-master-server
  namespace: openshift-nfd
spec:
  namespace: openshift-nfd" >$HOME/nfd-resource.yaml

oc apply -f $HOME/nfd-resource.yaml

oc get all -n openshift-nfd

oc get nodes
[lab-user@bastion openstack-upi]$ oc get nodes
NAME                           STATUS   ROLES                AGE     VERSION
cluster-wg9lh-zwlg9-master-0   Ready    master               29h     v1.19.0+1833054
cluster-wg9lh-zwlg9-master-1   Ready    master               29h     v1.19.0+1833054
cluster-wg9lh-zwlg9-master-2   Ready    master               29h     v1.19.0+1833054
general-purpose-1a-bs6cs       Ready    general-use,worker   6h4m    v1.19.0+1833054
general-purpose-1b-gwczt       Ready    general-use,worker   6h4m    v1.19.0+1833054
infra-1a-kbf7z                 Ready    infra,worker         5h39m   v1.19.0+1833054

oc get node general-purpose-1a-bs6cs -o json | jq '.metadata.labels'

4.1. Explore ClusterServiceVersions
oc get csv -n openshift-operators

oc get csv -A

[lab-user@bastion openstack-upi]$ oc get csv nfd.4.6.0-202109030220 -n openshift-operators -o yaml 

oc get csv nfd.4.6.0-202109030220 -n openshift-operators -o json | jq '.metadata.name'
oc get csv nfd.4.6.0-202109030220 -n openshift-operators -o json | jq '.metadata.version'
oc get csv nfd.4.6.0-202109030220 -n openshift-operators -o json | jq '.spec.customresourcedefinitions.owned[].kind'

5. Disable and Enable Operator Sources
oc get catalogsource -n openshift-marketplace
[lab-user@bastion openstack-upi]$ oc get catalogsource -n openshift-marketplace
NAME                  DISPLAY               TYPE   PUBLISHER   AGE
certified-operators   Certified Operators   grpc   Red Hat     29h
community-operators   Community Operators   grpc   Red Hat     29h
redhat-marketplace    Red Hat Marketplace   grpc   Red Hat     29h
redhat-operators      Red Hat Operators     grpc   Red Hat     29h

oc get catalogsource certified-operators -n openshift-marketplace -o yaml
oc get operatorhubs
oc get operatorhubs cluster -o yaml

oc get catalogsources -n openshift-marketplace
```

### Day 3 Training
```
oc new-project my-hpa

oc new-app quay.io/gpte-devops-automation/pod-autoscale-lab:rc0 --name=pod-autoscale -n my-hpa

oc expose svc pod-autoscale

1.2. Create a Limit Range
oc explain LimitRange

cat > $HOME/my-limit-range.yaml <<EOF
apiVersion: "v1"
kind: "LimitRange"
metadata:
  name: "my-resource-limits"
spec:
  limits:
    - type: "Pod"
      max:
        cpu: "100m"
        memory: "750Mi"
      min:
        cpu: "10m"
        memory: "5Mi"
    - type: "Container"
      max:
        cpu: "100m"
        memory: "750Mi"
      min:
        cpu: "10m"
        memory: "5Mi"
      default:
        cpu: "50m"
        memory: "100Mi"
EOF

https://www.ibm.com/docs/en/configurepricequote/10.0?topic=images-creating-horizontal-pod-autoscaler
oc autoscale deployment pod-autoscale --min=1 --max=5 --cpu-percent=60 -n my-hpa

echo "
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: pod-autoscale
  namespace: my-hpa
spec:
  maxReplicas: 5
  minReplicas: 1
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: pod-autoscale
  metrics: 
  - type: Resource
    resource:
      name: cpu 
      target:
        type: Utilization
        averageUtilization: 60
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max" | oc apply -f -

oc set resources deployment.apps/pod-autoscale --requests=cpu=50m --requests=memory=5Mi --limits=cpu=100m --limits=memory=750Mi

oc patch deployment.apps/pod-autoscale --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

oc describe hpa pod-autoscale -n my-hpa
[lab-user@bastion openstack-upi]$ oc describe hpa pod-autoscale
Name:                                                  pod-autoscale
Namespace:                                             my-hpa
Labels:                                                <none>
Annotations:                                           <none>
CreationTimestamp:                                     Tue, 28 Sep 2021 23:15:52 -0400
Reference:                                             Deployment/pod-autoscale
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  0% (0) / 60%
Min replicas:                                          1
Max replicas:                                          5
Deployment pods:                                       1 current / 1 desired
Conditions:
  Type            Status  Reason            Message
  ----            ------  ------            -------
  AbleToScale     True    ReadyForNewScale  recommended size matches current size
  ScalingActive   True    ValidMetricFound  the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  True    TooFewReplicas    the desired replica count is less than the minimum replica count
  Normal   SuccessfulRescale             56s                   horizontal-pod-autoscaler  New size: 2; reason: cpu resource utilization (percentage of request) above target

oc rsh -n my-hpa $(oc get pod -n my-hpa -o name)
while true; do true ; done

oc delete hpa pod-autoscale -n my-hpa

3. Monitoring Custom Application Workloads Using the OpenShift Monitoring Stack
echo '---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    enableUserWorkload: true' | oc apply -f -

[lab-user@bastion ~]$ oc projects | grep monitor
    openshift-monitoring
    openshift-user-workload-monitoring

oc get pods -n openshift-user-workload-monitoring

3.2. Application Overview

curl http://$(oc get route pod-autoscale -n my-hpa --template='{{ .spec.host }}')/metrics
[lab-user@bastion ~]$ curl http://$(oc get route pod-autoscale -n my-hpa --template='{{ .spec.host }}')/metrics
# HELP http_requests_total The amount of requests served by the server in total
# TYPE http_requests_total counter
http_requests_total 1

3.3. Create ServiceMonitor
echo "---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: pod-autoscale-monitor
  namespace: my-hpa
spec:
  endpoints:
  - interval: 30s
    port: 8080-tcp
  selector:
    matchLabels:
      app: pod-autoscale" | oc apply -f -

oc explain ServiceMonitor.spec.endpoints.port

3.4. Using Custom Metrics to Autoscale an Application
cat <<EOF | oc apply -f -
kind: ServiceAccount
apiVersion: v1
metadata:
  name: custom-metrics-apiserver
  namespace: my-hpa
EOF

cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: custom-metrics-server-resources
rules:
- apiGroups:
  - custom.metrics.k8s.io
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: custom-metrics-resource-reader
rules:
- apiGroups:
  - ""
  resources:
  - namespaces
  - pods
  - services
  verbs:
  - get
  - list
EOF

cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: custom-metrics:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: custom-metrics-apiserver
  namespace: my-hpa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: custom-metrics-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: custom-metrics-apiserver
  namespace: my-hpa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: custom-metrics-resource-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: custom-metrics-resource-reader
subjects:
- kind: ServiceAccount
  name: custom-metrics-apiserver
  namespace: my-hpa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: hpa-controller-custom-metrics
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: custom-metrics-server-resources
subjects:
- kind: ServiceAccount
  name: horizontal-pod-autoscaler
  namespace: kube-system
EOF

cat <<EOF | oc apply -f -
apiVersion: apiregistration.k8s.io/v1beta1
kind: APIService
metadata:
  name: v1beta1.custom.metrics.k8s.io
spec:
  service:
    name: prometheus-adapter
    namespace: my-hpa
  group: custom.metrics.k8s.io
  version: v1beta1
  insecureSkipTLSVerify: true
  groupPriorityMinimum: 100
  versionPriority: 100
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: adapter-config
  namespace: my-hpa
data:
  config.yaml: |
    rules:
    - seriesQuery: 'http_requests_total {namespace!="",pod!=""}' 
      resources:
        overrides:
          namespace: {resource: "namespace"}
          pod: {resource: "pod"}
          service: {resource: "service"}
      name:
        matches: "^(.*)_total"
        as: "my_http_requests" 
      metricsQuery: 'sum(rate(<<.Series>>{<<.LabelMatchers>>}[2m])) by (<<.GroupBy>>)' 
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.alpha.openshift.io/serving-cert-secret-name: prometheus-adapter-tls
  labels:
    name: prometheus-adapter
  name: prometheus-adapter
  namespace: my-hpa
spec:
  ports:
  - name: https
    port: 443
    targetPort: 6443
  selector:
    app: prometheus-adapter
  type: ClusterIP
EOF

cat <<EOF | oc apply -f -
kind: ConfigMap
apiVersion: v1
metadata:
  name: prometheus-adapter-prometheus-config
  namespace: my-hpa
data:
  prometheus-config.yaml: |
    apiVersion: v1
    clusters:
    - cluster:
        server: https://prometheus-user-workload.openshift-user-workload-monitoring:9091
        insecure-skip-tls-verify: true
      name: prometheus-k8s
    contexts:
    - context:
        cluster: prometheus-k8s
        user: prometheus-k8s
      name: prometheus-k8s
    current-context: prometheus-k8s
    kind: Config
    preferences: {}
    users:
    - name: prometheus-k8s
      user:
        tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
EOF

PROM_IMAGE="$(oc get -n openshift-monitoring deploy/prometheus-adapter -o jsonpath='{..image}')"
echo $PROM_IMAGE

cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: prometheus-adapter
  name: prometheus-adapter
  namespace: my-hpa
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus-adapter
  template:
    metadata:
      labels:
        app: prometheus-adapter
      name: prometheus-adapter
    spec:
      serviceAccountName: custom-metrics-apiserver
      containers:
      - name: prometheus-adapter
        image: ${PROM_IMAGE} 
        args:
        - --prometheus-auth-config=/etc/prometheus-config/prometheus-config.yaml
        - --secure-port=6443
        - --tls-cert-file=/var/run/serving-cert/tls.crt
        - --tls-private-key-file=/var/run/serving-cert/tls.key
        - --logtostderr=true
        - --prometheus-url=https://prometheus-user-workload.openshift-user-workload-monitoring:9091
        - --metrics-relist-interval=1m
        - --v=4
        - --config=/etc/adapter/config.yaml
        ports:
        - containerPort: 6443
        volumeMounts:
        - name: volume-serving-cert
          mountPath: /var/run/serving-cert
          readOnly: true
        - name: config
          mountPath: /etc/adapter/
          readOnly: true
        - name: prometheus-adapter-prometheus-config
          mountPath: /etc/prometheus-config
        - name: tmp-vol
          mountPath: /tmp
      volumes:
      - name: volume-serving-cert
        secret:
          secretName: prometheus-adapter-tls
      - name: config
        configMap:
          name: adapter-config
      - name: prometheus-adapter-prometheus-config
        configMap:
          name: prometheus-adapter-prometheus-config
          defaultMode: 420
      - name: tmp-vol
        emptyDir: {}
EOF

oc logs -f deploy/prometheus-adapter

AUTOSCALE_POD="$(oc get pods -o name | awk -F/ '/autoscale/ { print $2;exit }')"

echo $AUTOSCALE_POD

oc get --raw /apis/custom.metrics.k8s.io/v1beta1/namespaces/my-hpa/pods/$AUTOSCALE_POD/my_http_requests |jq

3.5. Create Custom HPA
echo "---
kind: HorizontalPodAutoscaler
apiVersion: autoscaling/v2beta1
metadata:
  name: pod-autoscale-custom
  namespace: my-hpa
spec:
  scaleTargetRef:
    kind: Deployment
    name: pod-autoscale
    apiVersion: apps/v1
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Pods
      pods:
        metricName: my_http_requests 
        targetAverageValue: 500m" | oc create -f -

AUTOSCALE_ROUTE=$(oc get route pod-autoscale -n my-hpa -o jsonpath='{ .spec.host}')

while true;do curl http://$AUTOSCALE_ROUTE;sleep .5;done

oc describe hpa pod-autoscale-custom -n my-hpa


1. Create Quotas for Cluster

oc login -u system:admin

https://www.opentlc.com/download/ocp4_advanced_deployment/tempMultiSCOFiles/08_Monitoring_Scaling_Applications/08_2_Quotas_LimitRanges_Templates_Lab.html

oc create clusterquota for-user-andrew \
     --project-annotation-selector openshift.io/requester=andrew \
     --hard pods=25 \
     --hard requests.cpu=5 \
     --hard requests.memory=6Gi \
     --hard limits.cpu=25 \
     --hard limits.memory=40Gi \
     --hard configmaps=25 \
     --hard persistentvolumeclaims=25 \
     --hard services=25

wget https://raw.githubusercontent.com/3scale/3scale-amp-openshift-templates/2.1.0-GA/amp/amp.yml

oc login -u andrew -p openshift

oc new-project 3scale

oc create -f amp.yml

oc get template

oc new-app --template=system --param WILDCARD_DOMAIN=apps.cluster-$GUID.$GUID.ocp4.opentlc.com

oc get pods -n 3scale

oc login -u system:admin 
oc get events -A | grep quota
...
3scale                               0s          Warning   FailedCreate                   deploymentconfig/zync                          Error creating deployer pod: pods "zync-1-deploy" is forbidden: failed quota: for-user-andrew: must specify limits.cpu,limits.memory,requests.cpu,requests.memory
3scale                               0s          Warning   FailedRetry                    deploymentconfig/zync                          Stop retrying: couldn't create deployer pod for "3scale/zync-1": pods "zync-1-deploy" is forbidden: failed quota: for-user-andrew: must specify limits.cpu,limits.memory,requests.cpu,requests.memory

oc login -u andrew -p openshift
oc project default
oc delete project 3scale
oc new-project 3scale

https://docs.openshift.com/container-platform/4.8/nodes/clusters/nodes-cluster-limit-ranges.html
oc login -u system:admin
cat >> $HOME/limits.yaml << EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: 3scale-resource-limits
spec:
  limits:
  - type: Pod
    max:
      cpu: "10"
      memory: 8Gi
    min:
      cpu: 50m
      memory: 100Mi
  - type: Container
    min:
      cpu: 50m
      memory: 100Mi
    max:
      cpu: "10"
      memory: 8Gi
    default:
      cpu: 50m
      memory: 100Mi
    defaultRequest:
      cpu: 50m
      memory: 100Mi
    maxLimitRequestRatio:
      cpu: "200"
EOF

oc apply -f $HOME/limits.yaml

oc login -u andrew -p openshift
oc project 3scale
oc create -f amp.yml

oc new-app --template=system --param WILDCARD_DOMAIN=apps.cluster-$GUID.$GUID.ocp4.opentlc.com


3scale                               1s          Warning   FailedCreate                   deploymentconfig/system-sphinx                 Error creating deployer pod: pods "system-sphinx-1-deploy" is forbidden: failed quota: for-user-andrew: must specify limits.cpu,limits.memory,requests.cpu,requests.memory

oc login -u system:admin
oc patch clusterresourcequota for-user-andrew --type json \
    -p '[{"op": "replace", "path": "/spec/quota/hard/pods", "value": "35"}]'

oc rollout latest dc/system-app 


oc delete pvc system-storage -n 3scale 
echo "---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: system-storage
  namespace: 3scale
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: standard
  volumeMode: Filesystem" | oc apply -f -

oc rollout latest dc/system-sidekiq 
oc rollout latest dc/system-resque
oc rollout latest dc/system-mysql
oc rollout latest dc/system-app

oc describe rc system-mysql-1
  Warning  FailedCreate  5m7s (x12 over 25m)  replication-controller  (combined from similar events): Error creating: Pod "system-mysql-1-nqskt" is invalid: spec.containers[0].resources.requests: Invalid value: "1": must be less than or equal to cpu limit

oc patch 
oc patch dc system-mysql -n 3scale --type json -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value":"50m"}]'

oc get pods
...
system-sidekiq-3-lrgkh             0/1     OOMKilled          3          8m14s

```

```
Scheduler Lab
oc login -u system:admin
oc get nodes --show-labels|grep infra

oc get nodes --show-labels|grep infra

oc get nodes --show-labels|grep infra
2. Move Ingress Controllers, Registry and Monitoring to the Infra Node

oc get pod -n openshift-ingress-operator
oc get pod -n openshift-ingress -o wide

oc get ingresscontroller default -n openshift-ingress-operator -o yaml

oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec":{"nodePlacement":{"nodeSelector": {"matchLabels":{"node-role.kubernetes.io/infra":""}}}}}'

oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec":{"replicas": 1}}'

oc get pod -n openshift-ingress -o wide

2.2. Move Registry and Monitoring

oc patch configs.imageregistry.operator.openshift.io/cluster -n openshift-image-registry --type=merge --patch '{"spec":{"nodeSelector":{"node-role.kubernetes.io/infra":""}}}'

oc patch configs.imageregistry.operator.openshift.io/cluster -n openshift-image-registry --type=merge --patch='{"spec":{"replicas": 1}}'

oc get pods -n openshift-image-registry -o wide 

2.2.2. Solution for Monitoring
cat <<EOF > $HOME/monitoring-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |+
    prometheusOperator:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusK8s:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    alertmanagerMain:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    kubeStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    grafana:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    telemeterClient:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    k8sPrometheusAdapter:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    openshiftStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    thanosQuerier:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
EOF

oc apply -f $HOME/monitoring-cm.yaml -n openshift-monitoring

oc get pods -n openshift-monitoring -o wide

3. Taints and Tolerations
oc new-project taints
oc new-app openshift/hello-openshift:v3.10 --name=nottainted -n taints
oc scale deployment nottainted --replicas=40

oc adm taint node infra-1a-kbf7z infra=reserved:NoSchedule
oc adm taint node infra-1a-kbf7z infra=reserved:NoExecute

oc get pod -n taints -o wide --sort-by=".spec.nodeName"

oc delete project taints
oc get pod -n openshift-ingress
oc get pod -n openshift-image-registry
oc get pod -n openshift-monitoring

oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec":{"nodePlacement": {"nodeSelector": {"matchLabels": {"node-role.kubernetes.io/infra": ""}},"tolerations": [{"effect":"NoSchedule","key": "infra","value": "reserved"},{"effect":"NoExecute","key": "infra","value": "reserved"}]}}}'
oc get pod -n openshift-ingress -o wide

oc patch configs.imageregistry.operator.openshift.io cluster -n openshift-image-registry --type=merge --patch='{"spec":{"nodeSelector": {"node-role.kubernetes.io/infra": ""},"tolerations": [{"effect":"NoSchedule","key": "infra","value": "reserved"},{"effect":"NoExecute","key": "infra","value": "reserved"}]}}'

oc get pod -n openshift-image-registry -o wide

cat <<EOF > $HOME/monitoring-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    prometheusOperator:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: infra
        value: reserved
        effect: NoSchedule
      - key: infra
        value: reserved
        effect: NoExecute
    prometheusK8s:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: infra
        value: reserved
        effect: NoSchedule
      - key: infra
        value: reserved
        effect: NoExecute
    alertmanagerMain:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: infra
        value: reserved
        effect: NoSchedule
      - key: infra
        value: reserved
        effect: NoExecute
    kubeStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: infra
        value: reserved
        effect: NoSchedule
      - key: infra
        value: reserved
        effect: NoExecute
    grafana:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: infra
        value: reserved
        effect: NoSchedule
      - key: infra
        value: reserved
        effect: NoExecute
    telemeterClient:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: infra
        value: reserved
        effect: NoSchedule
      - key: infra
        value: reserved
        effect: NoExecute
    k8sPrometheusAdapter:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: infra
        value: reserved
        effect: NoSchedule
      - key: infra
        value: reserved
        effect: NoExecute
    openshiftStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: infra
        value: reserved
        effect: NoSchedule
      - key: infra
        value: reserved
        effect: NoExecute
    thanosQuerier:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      tolerations:
      - key: infra
        value: reserved
        effect: NoSchedule
      - key: infra
        value: reserved
        effect: NoExecute
EOF

oc apply -f $HOME/monitoring-cm.yaml

watch oc get pod -n openshift-monitoring -o wide --sort-by=".spec.nodeName"


4. Pod Affinity and Anti-affinity
oc scale machineset general-purpose-1a --replicas=2 -n openshift-machine-api
oc scale machineset general-purpose-1b --replicas=2 -n openshift-machine-api

oc get nodes

oc new-project scheduler
oc new-app openshift/hello-openshift:v3.10 --name=cache     -n scheduler -lapp=cache
oc new-app openshift/hello-openshift:v3.10 --name=webserver -n scheduler -lapp=webserver

oc edit deployment cache

oc scale deploy cache --replicas=2

oc get pod -o wide|grep Running

oc edit deployment webserver

oc scale deploy webserver --replicas=2

oc get pod -o wide|grep Running

oc delete all -lapp=cache
oc delete all -lapp=webserver
oc delete project scheduler

oc scale machineset general-purpose-1a --replicas=1 -n openshift-machine-api
oc scale machineset general-purpose-1b --replicas=1 -n openshift-machine-api

5. Update the Infra Node MachineSet (Optional)
oc patch machineset infra-1a -n openshift-machine-api --type='merge' --patch='{"spec": {"template": {"spec": {"taints": [{"key": "infra","value": "reserved","effect": "NoSchedule"},{"key": "infra","value": "reserved","effect": "NoExecute"}]}}}}'

oc patch machineset infra-1a -n openshift-machine-api --type='merge' --patch='{"spec": {"deletePolicy": "Oldest"}}'

oc scale machineset infra-1a --replicas=2 -n openshift-machine-api
oc scale machineset infra-1a --replicas=1 -n openshift-machine-api

oc get node -l node-role.kubernetes.io/infra=''

oc describe $(oc get node -l node-role.kubernetes.io/infra='' -o name)

[lab-user@bastion ~]$ oc describe $(oc get node -l node-role.kubernetes.io/infra='' -o name) | grep Taints -A1
Taints:             infra=reserved:NoExecute
                    infra=reserved:NoSchedule

                    
```

```
---> 07:34:51     Waiting for MySQL to start ...
2021-09-29 07:34:51 29 [Note] Plugin 'FEDERATED' is disabled.
2021-09-29 07:34:51 29 [Note] InnoDB: Using atomics to ref count buffer pool pages
2021-09-29 07:34:51 29 [Note] InnoDB: The InnoDB memory heap is disabled
2021-09-29 07:34:51 29 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
2021-09-29 07:34:51 29 [Note] InnoDB: Memory barrier is not used
2021-09-29 07:34:51 29 [Note] InnoDB: Compressed tables use zlib 1.2.7
2021-09-29 07:34:51 29 [Note] InnoDB: Using Linux native AIO
2021-09-29 07:34:51 29 [Note] InnoDB: Using CPU crc32 instructions
/usr/share/container-scripts/mysql/common.sh: line 63:    29 Killed                  ${MYSQL_PREFIX}/libexec/mysqld --defaults-file=$MYSQL_DEFAULTS_FILE --skip-networking --socket=/tmp/mysql.sock "$@"


error: pre hook failed: the pre hook failed: couldn't create lifecycle pod for system-app-1: pods "system-app-1-hook-pre" is forbidden: exceeded quota: for-user-andrew, requested: requests.memory=300Mi, used: requests.memory=6000Mi, limited: requests.memory=6Gi, aborting rollout of 3scale/system-app-1
```

