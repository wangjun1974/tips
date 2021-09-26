
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