
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