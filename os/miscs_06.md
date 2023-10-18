### Restful API
```
username="admin"
password="NOT_REAL_PASSWORD"
projectname="admin"
publicapi="192.168.122.18"

echo "GET TOKEN"
curl -i \
  -H "Content-Type: application/json" \
  -d "
{ \"auth\": {
    \"identity\": {
      \"methods\": [\"password\"],
      \"password\": {
        \"user\": {
          \"name\": \"$username\",
          \"domain\": { \"id\": \"default\" },
          \"password\": \"$password\"
        }
      }
    },
    \"scope\": {
      \"project\": {
        \"name\": \"admin\",
        \"domain\": { \"id\": \"default\" }
      }
    }
  }
}" \
http://${publicapi}:5000/v3/auth/tokens 2>&1 | tee /tmp/tempfile

token=$(cat /tmp/tempfile | awk '/X-Subject-Token: /{print $NF}' | tr -d '\r' )
echo $token
export mytoken=$token

echo "GETTING IMAGES"
imageid=$(curl -s \
--header "X-Auth-Token: $mytoken" \
 http://${publicapi}:9292/v2/images | jq '.images[] | select(.name=="cirros")' | jq -r '.id' )

echo "GETTING FLAVOR"
flavorid=$(curl -s \
--header "X-Auth-Token: $mytoken" \
http://${publicapi}:8774/v2.1/flavors | jq '.flavors[] | select(.name=="m1.nano")' | jq -r '.id' ) 

echo "GET NETWORK"
networkid=$(curl -s \
-H "Accept: application/json" \
-H "X-Auth-Token: $mytoken" \
http://${publicapi}:9696/v2.0/networks | jq '.networks[] | select(.name=="private")' | jq -r '.id' )

echo "CREATE SERVER"
curl -g -i -X POST http://${publicapi}:8774/v2.1/servers \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "X-Auth-Token: $mytoken" -d "{\"server\": {\"name\": \"test-instance\", \"imageRef\": \"$imageid\", \"flavorRef\": \"$flavorid\", \"min_count\": 1, \"max_count\": 1, \"networks\": [{\"uuid\": \"$networkid\"}]}}"

echo "GET INSTANCEID"
instanceid=$(curl -s \
-H "Accept: application/json" \
--header "X-Auth-Token: $mytoken" \
-X GET http://${publicapi}:8774/v2.1/servers | jq '.servers[] | select(.name=="test-instance")' | jq -r '.id' )

echo "DELETE INSTANCE"
curl -g -i -X DELETE http://${publicapi}:8774/v2.1/servers/$instanceid \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "X-Auth-Token: $mytoken" 
```

### Grafana Dashboard 相关的信息
https://izsk.me/2019/09/07/%E5%9C%A8Grafana%E4%B8%AD%E7%BB%9F%E8%AE%A1%E7%89%A9%E7%90%86%E6%9C%BA%E4%B8%8A%E5%AE%B9%E5%99%A8%E7%8A%B6%E6%80%81%E5%88%86%E7%B1%BB%E6%B1%87%E6%80%BB/<br>
https://www.jianshu.com/p/7e7e0d06709b
```
  "targets": [
    {
      "exemplar": true,
      "expr": "sum by (resource, plugin_instance) (label_replace(collectd_virt_memory{service=~\".+-$clouds-.+\"}, \"resource\", \"$1\", \"host\", \"(.+):.+\")) + on(resource) group_right(plugin_instance) ceilometer_cpu{project=\"$projects\", service=~\".+-$clouds-.+\"}",
      "instant": true,
      "interval": "",
      "legendFormat": "{{plugin_instance}}",
      "refId": "A"
    }
  ],


"expr": "sum by (resource, plugin_instance) (label_replace(collectd_virt_memory, \"resource\", \"$1\", \"host\", \".+:(.+):.+\")) + on(resource) group_right(plugin_instance) ceilometer_cpu{project=\"$projects\"}",



sum by (resource, plugin_instance) (label_replace(collectd_virt_memory{service=~\".+-$clouds-.+\"}, \"resource\", \"$1\", \"host\", \".+:(.+):.+\")) + on(resource) group_right(plugin_instance) ceilometer_cpu{project=\"573de9f1520b4e08852cb5e17e734ede\", service=~\".+-cloud1-.+\"}


sum by (resource, plugin_instance) (label_replace(collectd_virt_memory{service=~".+-cloud1-.+"}, "resource", "$1", "host", ".+:(.+):.+")) + on(resource) group_right(plugin_instance) ceilometer_cpu{project="573de9f1520b4e08852cb5e17e73e",service=~".+-cloud1-.+"}

sum by (resource, plugin_instance) (label_replace(collectd_virt_memory{service=~".+-cloud1-.+"}, "resource", "$1", "host", ".+-.+")) + on(resource) group_right(plugin_instance) ceilometer_cpu{project="573de9f1520b4e08852cb5e17e73e"}
```

### 使用 Elasticsearch Operator 快速部署 Elasticsearch 集群
https://www.qikqiak.com/post/elastic-cloud-on-k8s/
```
# 在 STF 1.3 下创建 kibana 资源
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana
  namespace: service-telemetry
spec:
  version: 7.10.2
  nodeCount: 1
  elasticsearchRef:
    name: elasticsearch

# 注意 version: 7.10.2 与 elasticsearch 的版本一致

oc get secret
...
kibana-kb-config                                Opaque                                2      17h
kibana-kb-es-ca                                 Opaque                                2      17h
kibana-kb-http-ca-internal                      Opaque                                2      17h
kibana-kb-http-certs-internal                   Opaque                                3      17h
kibana-kb-http-certs-public                     Opaque                                2      17h
kibana-kibana-user                              Opaque                                1      17h

# TLS certification
https://www.elastic.co/guide/en/cloud-on-k8s/master/k8s-tls-certificates.html

oc run curl --image=radial/busyboxplus:curl -i --tty
curl -v -k https://kibana-kb-http:5601

cd ~/tmp
oc create route passthrough kibana-kb-route --service=kibana-kb-http --port=5601 

oc get secret elasticsearch-es-elastic-user -o jsonpath='{.data.elastic}' | base64 --decode
a16O5gq448IhL91G1GvbbQ2D
```

### 当 chrome 打开页面显示报错信息 '该网站发回了异常的错误凭据' 的处理方法
如果确认网址是正确的，可以在页面输入 'thisisunsafe'

### 计划让 STF 1.3 支持 OCP 4.8
https://github.com/infrawatch/service-telemetry-operator/pull/277

### OSP: Failure prepping block device., Code: 500 when deploying whole disk secure image
https://bugzilla.redhat.com/show_bug.cgi?id=1668858

### Encryption at Rest - Red Hat Ceph Storage 5
https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/5/html/data_security_and_hardening_guide/assembly-encryption-and-key-management

### OpenStack VaultLocker
https://github.com/openstack-charmers/vaultlocker<br>
关于在 Hashicorp Vault 中存储 LUKS dm-crypt 加密 keys

Linux Unified Key Setup
https://en.wikipedia.org/wiki/Linux_Unified_Key_Setup<br>

### 如何配置 ceph rgw multisite
https://medium.com/@avmor/how-to-configure-rgw-multisite-in-ceph-65e89a075c1f

### Pulling a docker image hosted by Satellite throws 403 error or digest verification failed error
https://access.redhat.com/solutions/3363761

### Ceph 参考架构 Cisco UCS and red hat ceph storage 4
https://www.cisco.com/c/en/us/td/docs/unified_computing/ucs/UCS_CVDs/ucs_c240m5_redhatceph4.html?dtid=osscdc000283<br>
https://blog.csdn.net/swingwang/article/details/60781084<br>
https://dnsflagday.net/2020/<br>

### osp 16.1 pre-provisioned nodes templatess
https://gitlab.cee.redhat.com/sputhenp/lab/-/tree/master/templates/osp-16-1/pre-provisioned

### Enrich your Ceph Object Storage Data Lake by leveraging Kafka as the Data Source
用 Kafka 作为胶水将数据源和 Data Lake 以及数据分析解决方案粘在一起<br>
https://itnext.io/enrich-your-ceph-object-storage-data-lake-by-leveraging-kafka-as-the-data-source-e9a4d305abcf

### RBD snapshot 是否支持 crash consistency 文档
https://github.com/ceph/ceph/pull/43764

### STF 集成
https://bugzilla.redhat.com/show_bug.cgi?id=1845943

### The future of data engineer
https://aws.amazon.com/big-data/datalakes-and-analytics/data-lake-house/

https://netflixtechblog.com/optimizing-data-warehouse-storage-7b94a48fdcbe

https://github.com/sripathikrishnan/jinjasql

https://preset.io/blog/the-future-of-the-data-engineer/

https://www.montecarlodata.com/the-future-of-the-data-engineer/

### Error
```
sudo cat /var/lib/mistral/overcloud/ansible.log | grep -E "fatal:" -A60
...
        "<13>Nov  2 10:30:35 puppet-user: Error: /Stage[main]/Tripleo::Certmonger::Neutron/Certmonger_certificate[neutron]: Could not evaluate: Could not get certificate: Server at https://helper.example.com/ipa/xml denied our request, giving up: 2100 (RPC failed at server.  Insufficient access: Insufficient 'add' privilege to add the entry 'krbprincipalname=neutron/overcloud-controller-0.internalapi.example.com@EXAMPLE.COM,cn=services,cn=accounts,dc=example,dc=com'.).",
(undercloud) [stack@undercloud ~]$ cat install-undercloud.log | grep "fatal:"  | more
...
File \"/usr/lib/python3.6/site-packages/keystoneauth1/identity/base.py\", line 134, in get_access\n    self.auth_ref = self.ge
t_auth_ref(session)\n  File \"/usr/lib/python3.6/site-packages/keystoneauth1/identity/generic/base.py\", line 206, in get_auth_ref\n    self._plug
in = self._do_create_plugin(session)\n  File \"/usr/lib/python3.6/site-packages/keystoneauth1/identity/generic/base.py\", line 161, in _do_create_
plugin\n    'auth_url is correct. %s' % e)\nkeystoneauth1.exceptions.discovery.DiscoveryFailure: Could not find versioned identity endpoints when 
attempting to authenticate. Please check that your auth_url is correct. SSL exception connecting to https://192.0.2.2:13000: HTTPSConnectionPool(h
ost='192.0.2.2', port=13000): Max retries exceeded with url: / (Caused by SSLError(SSLError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verif
y failed (_ssl.c:897)'),))\n", "module_stdout": "", "msg": "MODULE FAILURE\nSee stdout/stderr for the exact error", "rc": 1}


```

### Deploying OpenShift 4.x on non-tested platforms using the bare metal install method
https://access.redhat.com/articles/4207611


### 调试
```
virsh attach-disk jwang-rhel82-undercloud /root/jwang/isos/rhel-8.2-x86_64-dvd.iso hda --type cdrom --mode readonly --config
# ks=http://10.66.208.115/jwang-rhel82-undercloud-ks.cfg nameserver=192.168.8.1 ip=192.168.8.21::192.168.8.1:255.255.255.0:undercloud.example.com:ens3:none

# 生成 ks.cfg - jwang-rhel82-undercloud
cat > jwang-rhel82-undercloud-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart --nohome
network --device=ens3 --hostname=undercloud.example.com --bootproto=static --ip=192.168.8.21 --netmask=255.255.255.0 --gateway=192.168.8.1 --nameserver=192.168.8.1
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
%end
EOF

virsh attach-disk jwang-helper-undercloud /root/jwang/isos/rhel-8.2-x86_64-dvd.iso hda --type cdrom --mode readonly --config
# ks=http://10.66.208.115/jwang-helper-undercloud-ks.cfg nameserver=192.168.8.1 ip=192.168.8.22::192.168.8.1:255.255.255.0:helper.example.com:ens3:none

# 生成 ks.cfg - jwang-helper-undercloud
cat > jwang-helper-undercloud-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=ens3 --hostname=helper.example.com --bootproto=static --ip=192.168.8.22 --netmask=255.255.255.0 --gateway=192.168.8.1 --nameserver=192.168.8.1
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
%end
EOF

for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms
do
cat >> /etc/yum.repos.d/osp.repo << EOF
[$i]
name=$i
baseurl=file:///var/www/html/repos/osp16.1/$i/
enabled=1
gpgcheck=0

EOF
done


cat > ~/templates/node-info.yaml << 'EOF'
parameter_defaults:
  ControllerCount: 3
  ComputeCount: 0
  ComputeHCICount: 3

  # SchedulerHints
  ControllerSchedulerHints:
    'capabilities:node': 'controller-%index%'
  ComputeSchedulerHints:
    'capabilities:node': 'compute-%index%'
  ComputeHCISchedulerHints:
    'capabilities:node': 'computehci-%index%'
EOF


(undercloud) [stack@undercloud ~]$ cat > ~/deploy-enable-tls-octavia-stf.sh << 'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible.yaml \
-e $THT/environments/ceph-ansible/ceph-rgw.yaml \
-e $THT/environments/ssl/enable-internal-tls.yaml \
-e $THT/environments/ssl/tls-everywhere-endpoints-dns.yaml \
-e $THT/environments/network-isolation.yaml \
-e $CNF/environments/network-environment.yaml \
-e $CNF/environments/fixed-ips.yaml \
-e $CNF/environments/net-bond-with-vlans.yaml \
-e $THT/environments/services/octavia.yaml \
-e $THT/environments/metrics/ceilometer-write-qdr.yaml \
-e $THT/environments/metrics/collectd-write-qdr.yaml \
-e $THT/environments/metrics/qdr-edge-only.yaml \
-e ~/containers-prepare-parameter.yaml \
-e $CNF/custom-domain.yaml \
-e $CNF/node-info.yaml \
-e $CNF/enable-tls.yaml \
-e $CNF/inject-trust-anchor.yaml \
-e $CNF/keystone_domain_specific_ldap_backend.yaml \
-e $CNF/cephstorage.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
-e $CNF/enable-stf.yaml \
-e $CNF/stf-connectors.yaml \
--ntp-server 192.0.2.1
EOF
```

### openshift container storage labs
https://access.redhat.com/labs/ocssi/<br>

### OpenShift 与 Global Load Balancer
https://cloud.redhat.com/blog/global-load-balancer-for-openshift-clusters-an-operator-based-approach<br>

### 有状态应用与双数据中心的难题
https://cloud.redhat.com/blog/stateful-workloads-and-the-two-data-center-conundrum

### Disaster Recovery Strategies for Applications Running on OpenShift
https://cloud.redhat.com/blog/disaster-recovery-strategies-for-applications-running-on-openshift

```
cat > /tmp/inventory <<EOF
[controller]
192.0.2.5[1:3] ansible_user=heat-admin ansible_become=yes ansible_become_method=sudo

[computehci]
192.0.2.7[1:3] ansible_user=heat-admin ansible_become=yes ansible_become_method=sudo

EOF

(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m copy -a 'src=/tmp/10-cephdest=/etc/pki/ca-trust/source/anchors'

```

### ODH OCP 4.9
```
报错信息
csv created in namespace with multiple operatorgroups, can't pick one automatically

解决方法：创建 opendatahub namespace，在 opendatahub namespace 下创建 opendatahub 资源

报错信息
constraints not satisfiable: subscription seldon-operator-certified exists, no operators found in package seldon-operator-certified in the catalog referenced by subscription seldon-operator-certified

podman cp 的例子
https://github.com/containers/podman/blob/main/docs/source/markdown/podman-cp.1.md
```

### Ceph 与中心 prometheus 的集成
https://bugzilla.redhat.com/show_bug.cgi?id=1897250<br>
https://github.com/ceph/ceph/blob/master/src/mgr/DaemonHealthMetricCollector.cc#L33-L56<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1259160<br>
https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/5/html-single/dashboard_guide/index#network-port-requirements-for-ceph-dashboard_dash<br>
https://gitlab.consulting.redhat.com/iberia-consulting/inditex/ceph/cer-rhcs4-archive-zone<br>
https://github.com/prometheus/snmp_exporter<br>
https://gitlab.consulting.redhat.com/iberia-consulting/inditex/ceph/upgrade-rhcs4<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1902212<br>
https://documentation.suse.com/ses/7/html/ses-all/monitoring-alerting.html#prometheus-webhook-snmp<br>
https://github.com/SUSE/prometheus-webhook-snmp<br>
https://prometheus.io/docs/alerting/latest/alertmanager/#high-availability<br>
https://grafana.com/docs/grafana/latest/administration/set-up-for-high-availability<br>
https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html-single/installation_guide/index#colocation-of-containerized-ceph-daemons<br>
https://access.redhat.com/articles/1548993<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1831995<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1831995#c38<br>
https://fossies.org/linux/collectd/src/collectd.conf.in<br>

### 如何调试 ROOK
设置 ROOK_LOG_LEVEL=DEBUG 

### OSP 16.2 备份与恢复
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.2/html-single/backing_up_and_restoring_the_undercloud_and_control_plane_nodes/index<br>
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.2/html-single/back_up_and_restore_the_director_undercloud/index<br>

https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html-single/operational_measurements/index<br>


```
# https://bugzilla.redhat.com/show_bug.cgi?id=1594967
2021-11-08 03:12:57.558 77 WARNING neutron.pecan_wsgi.controllers.root [req-7e952a16-ad2c-47d5-8b12-c8b7f5720d3d 4b7041bb93c0438e921c8d6e1516a2d9 5a7854f1b7ea41169141436b1c5bf02c - default default] No controller found for: fw - returning response code 404: pecan.routing.PecanNotFound
2021-11-08 03:13:01.439 76 WARNING neutron.pecan_wsgi.controllers.root [req-52b36b8d-c615-43ca-ada4-51841a77c3c7 4b7041bb93c0438e921c8d6e1516a2d9 5a7854f1b7ea41169141436b1c5bf02c - default default] No controller found for: fw - returning response code 404: pecan.routing.PecanNotFound
2021-11-08 03:13:15.700 76 WARNING neutron.pecan_wsgi.controllers.root [req-d9f5ad06-fd2d-4536-986d-65cd6869fca4 4b7041bb93c0438e921c8d6e1516a2d9 5a7854f1b7ea41169141436b1c5bf02c - default default] No controller found for: vpn - returning response code 404: pecan.routing.PecanNotFound
2021-11-08 03:13:21.063 76 WARNING neutron.pecan_wsgi.controllers.root [req-2b5aa5c6-3b73-498a-aee6-baad8ed7d3e0 4b7041bb93c0438e921c8d6e1516a2d9 5a7854f1b7ea41169141436b1c5bf02c - default default] No controller found for: vpn - returning response code 404: pecan.routing.PecanNotFound
2021-11-08 03:13:24.775 77 WARNING neutron.pecan_wsgi.controllers.root [req-5697a4a7-194f-4e09-85be-cc146ef503ff 4b7041bb93c0438e921c8d6e1516a2d9 5a7854f1b7ea41169141436b1c5bf02c - default default] No controller found for: lbaas - returning response code 404: pecan.routing.PecanNotFound
2021-11-08 03:13:25.227 76 WARNING neutron.pecan_wsgi.controllers.root [req-12929c75-2462-436b-9e89-f497c3fb03ad 4b7041bb93c0438e921c8d6e1516a2d9 5a7854f1b7ea41169141436b1c5bf02c - default default] No controller found for: lbaas - returning response code 404: pecan.routing.PecanNotFound
2021-11-08 03:13:25.627 77 WARNING neutron.pecan_wsgi.controllers.root [req-acd8ac0e-fd6b-4457-ad78-0ba02737dde0 4b7041bb93c0438e921c8d6e1516a2d9 5a7854f1b7ea41169141436b1c5bf02c - default default] No controller found for: fw - returning response code 404: pecan.routing.PecanNotFound
2021-11-08 03:13:26.202 77 WARNING neutron.pecan_wsgi.controllers.root [req-34e17998-17c2-4756-adba-b154bdb49341 4b7041bb93c0438e921c8d6e1516a2d9 5a7854f1b7ea41169141436b1c5bf02c - default default] No controller found for: vpn - returning response code 404: pecan.routing.PecanNotFound
2021-11-08 03:13:26.534 76 WARNING neutron.pecan_wsgi.controllers.root [req-b9223895-0183-4651-b344-130b107b782d 4b7041bb93c0438e921c8d6e1516a2d9 5a7854f1b7ea41169141436b1c5bf02c - default default] No controller found for: lbaas - returning response code 404: pecan.routing.PecanNotFound
2021-11-08 03:13:27.794 76 WARNING neutron.pecan_wsgi.controllers.root [req-c2714d95-1582-4ae5-8c91-6284521055bc 4b7041bb93c0438e921c8d6e1516a2d9 5a7854f1b7ea41169141436b1c5bf02c - default default] No controller found for: lbaas - returning response code 404: pecan.routing.PecanNotFound

openstack.exceptions.HttpException: HttpException: 502: Server Error for url: https://overcloud.example.com:13696/v2.0/agents, Reason: Error reading from remote server: response from an upstream server.: The proxy server received an invalid: 502 Proxy Error: The proxy server could not handle the request GET&nbsp;/v2.0/agents.: Proxy Error


WARNING ceilometer.neutron_client [-] The resource could not be found.:neutronclient.common.exceptions.NotFound: The resource could not be found.

Nov 09 13:55:53 base-pvg.redhat.ren libvirtd[21062]: 2021-11-09 05:55:53.711+0000: 21062: error : virNetSocketReadWire:1806 : 读Hint: Some lines were ellipsized, use -l to show in full.

```

### CentOS Stream 的 EPEL 是 EPEL Next
https://fedoraproject.org/wiki/EPEL_Next

### OSP 16.1 与 collectd 
```
osp 16.1 安装的 collectd 版本

collectd-5.11.0-5.el8ost.x86_64
```

### 下载软件包及依赖
https://ostechnix.com/download-rpm-package-dependencies-centos/<br>
https://access.redhat.com/solutions/10154<br>
```
yum install --downloadonly --downloaddir=<downloaddir> <package>
```

### 为 osp collectd 容器添加 rrd plugins
```
> /tmp/osp.repo

for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms
do 
cat >> /tmp/osp.repo <<EOF
[$i]
name=$i
baseurl=http://192.0.2.1:8088/repos/osp16.1/$i/
enabled=1
gpgcheck=0

EOF
done

# 拷贝 osp.repo
cat > /tmp/inventory <<EOF
[controller]
192.0.2.5[1:3] ansible_user=heat-admin ansible_become=yes ansible_become_method=sudo

[computehci]
192.0.2.7[1:3] ansible_user=heat-admin ansible_become=yes ansible_become_method=sudo

EOF

(undercloud) [stack@undercloud ~]$ ansible -i /tmp/inventory all -m copy -a 'src=/tmp/osp.repo dest=/etc/yum.repos.d'

# 在 overcloud 节点上，挂在 collectd pod 到 host
[heat-admin@overcloud-controller-0 ~]$
sudo -i 
podman ps | grep collectd 
mnt=$(podman mount $(podman ps | grep collectd | awk '{print $1}') )

# 拷贝 /etc/yum.repos.d/osp.repo 到容器内
cp /etc/yum.repos.d/osp.repo $mnt/etc/yum.repos.d

# 为容器内安装 rrdtool
yum install --installroot=$mnt rrdtool

# 拷贝 collectd-rrdtool 软件包到容器内
cp /tmp/collectd-rrdtool-5.11.0-9.el8ost.x86_64.rpm $mnt/tmp

# 切换到容器内，安装 collectd rrdtool 插件
podman exec -it collectd sh
()[root@overcloud-controller-0 /]$ rpm -ivh /tmp/collectd-rrdtool-5.11.0-9.el8ost.x86_64.rpm --force
()[root@overcloud-controller-0 /]$ exit

# 生成 collectd rrdtool 插件配置文件
[heat-admin@overcloud-controller-0 ~]$
sudo -i
cd /var/lib/config-data/puppet-generated/collectd/etc/collectd.d
# https://frontier.town/2017/10/collectd-and-rrdtool/
cat > 10-rrdtool.conf <<EOF
LoadPlugin rrdtool
<Plugin rrdtool>
	DataDir "/var/lib/collectd/rrd"
	CreateFilesAsync false
	CacheTimeout 120
	CacheFlush   900
	WritesPerSecond 50

	# The default settings are optimised for plotting time-series graphs over pre-fixed
  # time period, but are not very helpful for simply asking "what is my average memory
  # usage for the last hour?", so we define some new ones.

	# The first one is an anomaly, as it seems that the rrd plugin enforces some
	# minimums. The result is a time-series 200 hours long with a granularity of 10s.
	RRATimeSpan 3600
	# This defines a time-series 20 hours long with a granularity of 1 minute.
	RRATimeSpan 72000
	# This defines a time-series 50 days long with a granularity of 1 hour.
	RRATimeSpan 4320000
</Plugin>
EOF

# 重启 collectd 容器
podman restart collectd

# 检查 collectd 内 rrd 目录下的内容
podman exec -it collectd sh
()[root@overcloud-controller-0 /]$ ls /var/lib/collectd/rrd/overcloud-controller-0.example.com/
ceph-ceph-mon.overcloud-controller-0       libpodstats-ceph-mgr-overcloud-controller-0       libpodstats-nova_scheduler
cpu-0                                      libpodstats-ceph-mon-overcloud-controller-0       libpodstats-nova_vnc_proxy
cpu-1                                      libpodstats-ceph-rgw-overcloud-controller-0-rgw0  libpodstats-octavia_api
cpu-2                                      libpodstats-cinder_api                            libpodstats-octavia_driver_agent
cpu-3                                      libpodstats-cinder_api_cron                       libpodstats-octavia_health_manager
df-overlay                                 libpodstats-cinder_scheduler                      libpodstats-octavia_housekeeping
df-shm                                     libpodstats-clustercheck                          libpodstats-octavia_worker
df-tmpfs                                   libpodstats-collectd                              libpodstats-ovn_controller
disk-vda                                   libpodstats-galera-bundle-podman-0                libpodstats-ovn-dbs-bundle-podman-0
disk-vda1                                  libpodstats-glance_api                            libpodstats-placement_api
disk-vda2                                  libpodstats-glance_api_tls_proxy                  libpodstats-rabbitmq-bundle-podman-0
hugepages-mm-2048Kb                        libpodstats-haproxy-bundle-podman-0               libpodstats-redis-bundle-podman-0
hugepages-node0-2048Kb                     libpodstats-heat_api                              libpodstats-redis_tls_proxy
interface-br-ex                            libpodstats-heat_api_cfn                          load
interface-br-int                           libpodstats-heat_api_cron                         memcached-local
interface-ens3                             libpodstats-heat_engine                           memory
interface-ens4                             libpodstats-horizon                               processes
interface-ens5                             libpodstats-iscsid                                uptime
interface-genev_sys_6081                   libpodstats-keystone                              vmem
interface-lo                               libpodstats-logrotate_crond                       vmem-direct
interface-o-hm0                            libpodstats-memcached                             vmem-dma
interface-ovs-system                       libpodstats-metrics_qdr                           vmem-dma32
interface-vlan20                           libpodstats-neutron_api                           vmem-kswapd
interface-vlan30                           libpodstats-neutron_server_tls_proxy              vmem-movable
interface-vlan40                           libpodstats-nova_api                              vmem-normal
interface-vlan50                           libpodstats-nova_api_cron                         vmem-throttle
libpodstats-ceilometer_agent_central       libpodstats-nova_conductor
libpodstats-ceilometer_agent_notification  libpodstats-nova_metadata

# 检查 collectd 内 rrd 目录下的 ceph 指标
()[root@overcloud-controller-0 /]$ ls /var/lib/collectd/rrd/overcloud-controller-0.example.com/ceph-ceph-mon.overcloud-controller-0 -1F | grep -Ei pg
ceph_bytes-Cluster.numPgActiveClean.rrd
ceph_bytes-Cluster.numPgActive.rrd
ceph_bytes-Cluster.numPgPeering.rrd
ceph_bytes-Cluster.numPg.rrd
ceph_bytes-Mempool.osdPglogBytes.rrd
ceph_bytes-Mempool.osdPglogItems.rrd
ceph_bytes-Mempool.pgmapBytes.rrd
ceph_bytes-Mempool.pgmapItems.rrd

```


### Ceph 监控
collectd + Graphite + Grafana
https://www.cnblogs.com/William-Guozi/p/grafana-monitor.html<br>

Grafana Ceph Cluster Dashboard，数据源来自 Prometheus
https://grafana.com/grafana/dashboards/2842<br>

Ceph Mgr Prometheus 模块
https://docs.ceph.com/en/latest/mgr/prometheus/<br>

### Ceph and OpenCAS
https://01.org/blogs/tingjie/2020/research-performance-tuning-hdd-based-ceph-cluster-using-open-cas

### DevOps 文化与实践
https://www.redhat.com/en/blog/devops-culture-and-practice-openshift-experience-driven-real-world-guide-building-empowered-teams<br>
https://www.redhat.com/en/engage/devops-culture-practice-openshift-ebooks<br>
https://www.whsmith.co.uk/products/adaptive-systems-with-domaindriven-design-wardley-maps-and-team-topologies-designing-architecture-fo/susanne-kaiser/paperback/9780137393039.html<br>
https://www.ready-to-innovate.com/<br>
https://github.com/boogiespook/rti/issues<br>
https://www.redhat.com/rhdc/managed-files/rh-slowing-down-digital-transformation-questions-ebook-f29635-202109-en_0.pdf<br>
https://voltagecontrol.com/blog/episode-60-a-future-forward-in-devops/<br>
https://www.linkedin.com/posts/andreasspanner_transformation-agile-changemanagement-activity-6836651389054263296-vtvs<br>
https://www.redhat.com/en/events/webinar/transformation-takes-practice-users-guide-open-practice-library<br>

### OSP 16.1 为 overcloud 添加 Red Hat Ceph Storage Dashboard
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html-single/deploying_an_overcloud_with_containerized_red_hat_ceph/index#adding-ceph-dashboard<br>

```
I wrote up a summary of this year's State of DevOps report on my blog over here: https://www.tomgeraghty.co.uk/index.php/the-state-of-devops-report-2021-a-summary/

https://access.redhat.com/solutions/5464941
Stderr: 'iscsiadm: Cannot perform discovery. Invalid Initiatorname.\niscsiadm: Could not perform SendTargets discovery: invalid parameter\n'
https://bugzilla.redhat.com/show_bug.cgi?id=1764187

sudo iptables -I INPUT 8 -p tcp -m multiport --dports 3260 -m state --state NEW -m comment --comment "100 iscsid ipv4" -j ACCEPT

# 检查最新文件的最后 10 行
ls -ltr | tail -1 | awk '{print $9}' | xargs cat | tail -10
watch -n5 "ls -ltr | tail -1 | awk '{print \$9}' | xargs cat | tail -10"
watch -n5 "sudo cd /var/log/containers/mistral && sudo ls -ltr | tail -1 | awk '{print \$9}' | sudo xargs cat | tail -10"
watch -n5 "sudo cd /var/log/containers/heat && sudo ls -ltr | tail -1 | awk '{print \$9}' | sudo xargs cat | tail -10"


# 部署失败，报错信息是
rhosp-rhel8/openstack-collectd:16.1'] run failed after + mkdir -p /etc/puppet

"<13>Nov  9 09:39:29 puppet-user: Error: Evaluation Error: Error while evaluating a Resource Statement, Evaluation Error: Error while evaluating a Resource Statement, Duplicate declaration: Tripleo::Profile::Base::Metrics::Collectd::Collectd_plugin[ceph] is already declared at (file: /etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd/collectd_service.pp, line: 8); cannot redeclare (file: /etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd/collectd_service.pp, line: 8) (file: /etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd/collectd_service.pp, line: 8, column: 5) (file: /etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd.pp, line: 301) on node overcloud-computehci-0.example.com",

Tripleo::Profile::Base::Metrics::Collectd::Collectd_plugin[ceph]
/etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd/collectd_service.pp
/etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd/collectd_service.pp
/etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd/collectd_service.pp
/etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd.pp

# 在所有 computehci 节点执行
sudo sed -i 's|^|#|g' /etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd/collectd_service.pp

Nov 10 03:44:30 overcloud-computehci-0.example.com puppet-user[19587]: Error: Evaluation Error: Error while evaluating a Resource Statement, Evaluation Error: Error while evaluating a Resource Statement, Duplicate declaration: Tripleo::Profile::Base::Metrics::Collectd::Collectd_plugin[ceph] is already declared at (file: /etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd/collectd_service.pp, line: 8); cannot redeclare (file: /etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd/collectd_service.pp, line: 8) (file: /etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd/collectd_service.pp, line: 8, column: 5) (file: /etc/puppet/modules/tripleo/manifests/profile/base/metrics/collectd.pp, line: 301) on node overcloud-computehci-0.example.com

https://bugzilla.redhat.com/show_bug.cgi?id=1845943


sudo iptables -I INPUT 8 -p tcp -m multiport --dports 5900:5999 -m state --state NEW -m comment --comment "100 vnc ipv4" -j ACCEPT

# Grafana 与 ceph mgr 容器
[heat-admin@overcloud-controller-0 ~]$ sudo podman ps | grep -E "mgr|grafana" 
072ab17f2678  undercloud.ctlplane.example.com:8787/rhceph/rhceph-4-dashboard-rhel8:4                                         2 hours ago        Up 2 hours ago               grafana-server
7b1f33ae193f  undercloud.ctlplane.example.com:8787/rhceph/rhceph-4-rhel8:latest                                              20 hours ago       Up 20 hours ago              ceph-mgr-overcloud-controller-0
```

### ODH 1.1.0 kfdef
https://github.com/opendatahub-io/odh-manifests/tree/v1.1.0/kfdef

### OpenShift Cluster 安装 CephFS csi
https://www.jianshu.com/p/5cbe9f58dda7

### 如何改变 Grafana password in director
[rhos-tech] [ceph-dashboard] How to change the Grafana password in director deployed ceph

### temp cmd 
```
cat > /tmp/inventory <<EOF
[controller]
192.0.2.51 ansible_user=root

[compute]
192.0.2.52 ansible_user=root

EOF

cat > /tmp/inventory <<EOF
[controller]
192.0.2.51 ansible_user=stack ansible_become=yes ansible_become_method=sudo

[compute]
192.0.2.52 ansible_user=stack ansible_become=yes ansible_become_method=sudo

EOF

报错
[ERROR] WSREP: wsrep::connect(gcomm://overcloud-controller-0.internalapi.localdomain,overcloud-controller-1.internalapi.localdomain,overcloud-controller-2.internalapi.localdomain) failed: 7

https://access.redhat.com/solutions/2085773

https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/deployed_server.html#deployed-server-with-config-download

```

### Satellite and OpenShift 4 KBase
https://access.redhat.com/solutions/5003361<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1798485<br>

### Kubernetes 1.22 对应的 csi 版本是 1.5.0 
https://github.com/kubernetes/kubernetes/blob/v1.22.0/go.mod#L28<br>
https://bugzilla.redhat.com/show_bug.cgi?id=2023197

### OSP Baremetal FIP security group
https://bugzilla.redhat.com/show_bug.cgi?id=2021261

### 使用 go modules 管理 kubernetes 依赖
https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/vendor.md

### 报错
```
[stack@overcloud-controller-0 ~]$ sudo cat /var/log/setup-ipa-client-ansible.log 
+ get_metadata_config_drive
+ '[' -f /run/cloud-init/status.json ']'
+ echo 'Unable to retrieve metadata from config drive.'
Unable to retrieve metadata from config drive.
+ return 1
+ get_metadata_network
++ timeout 300 /bin/bash -c 'data=""; while [ -z "$data" ]; do sleep $[ ( $RANDOM % 10 )  + 1 ]s; data=`curl -s http://169.254.169.254/openstack/2016-10-06/vendor_data2.json 2>/dev/null`; done; echo $data'
+ data=
+ [[ 124 != 0 ]]
+ echo 'Unable to retrieve metadata from metadata service.'
Unable to retrieve metadata from metadata service.
+ return 1
+ echo 'FATAL: No metadata available or could not read the hostname from the metadata'
FATAL: No metadata available or could not read the hostname from the metadata
+ exit 1

"<13>Nov 16 02:40:38 puppet-user: Error: /Stage[main]/Tripleo::Profile::Base::Certmonger_user/Tripleo::Certmonger::Libvirt_vnc[libvirt-vnc-server-cert]/Certmonger_certificate[libvirt-vnc-server-cert]: Could not evaluate: The certificate 'libvirt-vnc-server-cert' wasn't found in the list.",

"<13>Nov 16 03:42:56 puppet-user: Error: /Stage[main]/Tripleo::Certmonger::Ovn_controller/Certmonger_certificate[ovn_controller]: Could not evaluate: Could not get certificate: Error setting up ccache for \"host\" service on client using default keytab: Preauthentication failed.",
https://lists.fedoraproject.org/archives/list/freeipa-users@lists.fedorahosted.org/thread/ZUW57MXKU75IEKTQSHDYFSXEHI3QQCVA/?sort=date

https://lists.fedorahosted.org/archives/list/freeipa-users@lists.fedorahosted.org/thread/WDJZI4VIC6NP5LX6E3TMQCKMSG7IB4RU/

https://lists.fedorahosted.org/archives/list/freeipa-users@lists.fedorahosted.org/thread/XT5GZFGHVEQH2LH56UYC56EIXX2N6PTH/

klist -ekt /etc/krb5.keytab

[root@overcloud-controller-0 ~]# klist -k /etc/krb5.keytab 
Keytab name: FILE:/etc/krb5.keytab
KVNO Principal
---- --------------------------------------------------------------------------
   1 host/overcloud-controller-0.example.com@EXAMPLE.COM
   1 host/overcloud-controller-0.example.com@EXAMPLE.COM

http://sammoffatt.com.au/jauthtools/Kerberos/Troubleshooting

ipa host-del example.com overcloud-controller-2.storagemgmt
ipa dnsrecord-del example.com overcloud-controller-2.storagemgmt --del-all

https://access.redhat.com/solutions/642993
ipa-getkeytab -s helper.example.com -k /etc/krb5.keytab -p host/overcloud-controller-0.example.com

报错: TASK [ipaclient : Install - IPA client test] *********************************************************************************************************
fatal: [undercloud.example.com]: FAILED! => {"changed": false, "msg": "Failed to verify that helper.example.com is an IPA Server."}

https://github.com/freeipa/ansible-freeipa/issues/337

ansible-playbook -vvv \
--ssh-extra-args "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
/usr/share/ansible/tripleo-playbooks/undercloud-ipa-install.yaml

TASK [tripleo_ipa_setup : add Nova Host Manager role] ************************************************************************************************
fatal: [localhost]: FAILED! => {"changed": false, "msg": "login: Request failed: <urlopen error [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:897)>"}

TASK [tripleo_ipa_setup : add nova service] **********************************************************************************************************
task path: /usr/share/ansible/roles/tripleo_ipa_setup/tasks/add_ipa_user.yml:26

fatal: [localhost]: FAILED! => {
    "changed": false,
    "invocation": {
        "module_args": {
            "force": true,
            "hosts": null,
            "ipa_host": "helper.example.com",
            "ipa_pass": "VALUE_SPECIFIED_IN_NO_LOG_PARAMETER",
            "ipa_port": 443,
            "ipa_prot": "https",
            "ipa_timeout": 10,
            "ipa_user": "admin",
            "krbcanonicalname": "nova/undercloud.example.com",
            "name": "nova/undercloud.example.com",
            "state": "present",
            "validate_certs": true
        }
    },

    "msg": "response service_add: The host 'undercloud.example.com' does not exist to add a service to."

2021-11-17 10:50:31,304 p=1526 u=mistral n=ansible | fatal: [undercloud]: FAILED! => {
    "changed": false,
    "invocation": {
        "module_args": {
            "description": null,
            "force": true,
            "fqdn": "overcloud-computehci-0.example.com",
            "ip_address": null,
            "ipa_host": "helper.example.com",
            "ipa_pass": null,
            "ipa_port": 443,
            "ipa_prot": "https",
            "ipa_timeout": 10,
            "ipa_user": "nova/undercloud.example.com",
            "mac_address": null,
            "ns_hardware_platform": null,
            "ns_host_location": null,
            "ns_os_version": null,
            "random_password": true,
            "state": "present",
            "update_dns": null,
            "user_certificate": null,
            "validate_certs": true
        }
    },
    "msg": "host_find: HTTP Error 401: Unauthorized"
}

https://bugzilla.redhat.com/show_bug.cgi?id=1921855

(undercloud) [stack@undercloud ~]$ sudo kinit -kt /etc/novajoin/krb5.keytab nova/undercloud.example.com
kinit: Preauthentication failed while getting initial credentials

ipa privilege-find | grep -E "Privilege name:" 

https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/15/html/integrate_with_identity_service/idm-novajoin

(undercloud) [stack@undercloud ~]$ sudo kinit -kt /etc/novajoin/krb5.keytab nova/undercloud.example.com@EXAMPLE.COM 
kinit: Preauthentication failed while getting initial credentials

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/linux_domain_identity_authentication_and_policy_guide/retrieve-existing-keytabs
echo redhat123 | kinit admin
ipa-getkeytab -s helper.example.com -p nova/undercloud.example.com -k /etc/novajoin/krb5.keytab
klist
kdestroy
klist
kinit -kt /etc/novajoin/krb5.keytab nova/undercloud.example.com
klist
chmod a+r /etc/novajoin/krb5.keytab

echo redhat123 | sudo kinit admin
sudo klist
sudo ipa-join
sudo rm -f /etc/krb5.keytab
sudo ipa-getkeytab -s helper.example.com -p host/overcloud-controller-1.example.com -k /etc/krb5.keytab
sudo ls -l /etc/krb5.keytab
sudo chmod a+r /etc/krb5.keytab
klist
kdestroy -A
klist
kinit -kt /etc/krb5.keytab host/overcloud-controller-1.example.com
klist

ansible -i /tmp/inventory all -f 6 -m shell -a 'echo redhat123 | sudo kinit admin' 
ansible -i /tmp/inventory all -f 6 -m shell -a 'sudo ipa-join'
ansible -i /tmp/inventory all -f 6 -m shell -a 'sudo rm -f /etc/krb5.keytab'
ansible -i /tmp/inventory all -f 6 -m setup
# ansible 
ansible -vvv -i /tmp/inventory all -f 6 -m shell -a 'sudo echo $(hostname)'
ssh stack@192.0.2.51 "bash -c 'echo \$HOSTNAME'"
ssh stack@192.0.2.51 "bash -c 'echo \$(hostname)'"

# ssh overcloud node
sudo ipa-getkeytab -s helper.example.com -p host/$(hostname) -k /etc/krb5.keytab
# done

# ansible version
ansible -vvv -i /tmp/inventory all -f 6 -m shell -a 'sudo ipa-getkeytab -s helper.example.com -p host/$(hostname) -k /etc/krb5.keytab'


ansible -i /tmp/inventory all -f 6 -m shell -a "sudo chmod a+r /etc/krb5.keytab"
# ansible -i /tmp/inventory all -f 6 -m shell -a "kdestroy -A"
# ansible -i /tmp/inventory all -f 6 -m shell -a "kinit -kt /etc/krb5.keytab host/$hostname"
# ssh overcloud node
kdestroy -A; kinit -kt /etc/krb5.keytab host/$(hostname); klist
sudo kdestroy -A; sudo kinit -kt /etc/krb5.keytab host/$(hostname); sudo klist
# done

报错　
[jwang@undercloud ~]$ curl https://overcloud.ctlplane.example.com:8444 
curl: (51) SSL: no alternative certificate subject name matches target host name 'overcloud.ctlplane.example.com'

kinit: Keytab contains no suitable keys for host/undercloud.example.com@EXAMPLE.COM while getting initial credentials

ipa: ERROR: You must enroll a host in order to create a host service

(overcloud) [stack@undercloud ~]$ sudo cat /var/lib/mistral/overcloud/ansible.log | grep -E "fatal:" -A150 | grep Notice | head -1 | sed -e 's|\\n|\n|g'  | more
Notice: /Stage[main]/Tripleo::Profile::Pacemaker::Rabbitmq_bundle/File[/var/lib/rabbitmq/.erlang.cookie]/content: content changed '{md5}d952ac39fa2347
f946d23b9e1950f550' to '{md5}76cdd56d57e8c5b4a0845c400aac7c55'
Notice: /Stage[main]/Tripleo::Profile::Pacemaker::Rabbitmq_bundle/Exec[rabbitmq-ready]/returns: Error: unable to perform an operation on node 'rabbit@
overcloud-controller-0'. Please see diagnostics information and suggestions below.

rabbitmq_init_bundle Exited (1)


Nov 23 00:50:19 overcloud-controller-1.example.com systemd[1]: tripleo_ceilometer_agent_central_healthcheck.service: Main process exited, code=exited, status=1/FAILURE
Nov 23 00:50:19 overcloud-controller-1.example.com systemd[1]: tripleo_ceilometer_agent_central_healthcheck.service: Failed with result 'exit-code'.
Nov 23 00:50:19 overcloud-controller-1.example.com systemd[1]: Failed to start ceilometer_agent_central healthcheck.

[stack@overcloud-controller-1 ~]$ sudo systemctl status tripleo_ceilometer_agent_central_healthcheck.service 
 tripleo_ceilometer_agent_central_healthcheck.service - ceilometer_agent_central healthcheck
   Loaded: loaded (/etc/systemd/system/tripleo_ceilometer_agent_central_healthcheck.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Tue 2021-11-23 00:51:39 UTC; 3s ago
  Process: 105930 ExecStart=/usr/bin/podman exec --user root ceilometer_agent_central /openstack/healthcheck (code=exited, status=1/FAILURE)
 Main PID: 105930 (code=exited, status=1/FAILURE)

Nov 23 00:51:37 overcloud-controller-1.example.com systemd[1]: Starting ceilometer_agent_central healthcheck...
Nov 23 00:51:38 overcloud-controller-1.example.com podman[105930]: 2021-11-23 00:51:38.676923115 +0000 UTC m=+0.663368534 container exec bcdc4e363291>
Nov 23 00:51:38 overcloud-controller-1.example.com healthcheck_ceilometer_agent_central[105930]: sudo: unknown user: ceilome+
Nov 23 00:51:38 overcloud-controller-1.example.com healthcheck_ceilometer_agent_central[105930]: sudo: unable to initialize policy plugin
Nov 23 00:51:38 overcloud-controller-1.example.com healthcheck_ceilometer_agent_central[105930]: There is no ceilometer-polling process with opened R>
Nov 23 00:51:39 overcloud-controller-1.example.com healthcheck_ceilometer_agent_central[105930]: Error: non zero exit code: 1: OCI runtime error
Nov 23 00:51:39 overcloud-controller-1.example.com systemd[1]: tripleo_ceilometer_agent_central_healthcheck.service: Main process exited, code=exited>
Nov 23 00:51:39 overcloud-controller-1.example.com systemd[1]: tripleo_ceilometer_agent_central_healthcheck.service: Failed with result 'exit-code'.
Nov 23 00:51:39 overcloud-controller-1.example.com systemd[1]: Failed to start ceilometer_agent_central healthcheck.

https://bugzilla.redhat.com/show_bug.cgi?id=1902681


Nov 23 01:08:11 overcloud-controller-2.example.com systemd[1]: grafana-server.service: Control process exited, code=exited status=125
Nov 23 01:08:11 overcloud-controller-2.example.com systemd[1]: grafana-server.service: Failed with result 'exit-code'.
Nov 23 01:08:11 overcloud-controller-2.example.com systemd[1]: Failed to start grafana-server.
Nov 23 01:08:11 overcloud-controller-2.example.com podman[180363]: Error: cannot remove container a81a811c5b4e9898d86ad1c23929feaa0cf18617e6649e069494b94cd174d951 as it is running - running or paused containers cannot be removed without force: container state improper
Nov 23 01:08:11 overcloud-controller-2.example.com podman[180357]: Error: error creating container storage: the container name "ceph-mgr-overcloud-controller-2" is already in use by "3e012222cd8213d3e6ed49ee55d145ca737cb8f4663896e5b8b7b962de3fc605". You have to remove that container to be able to reuse that name.: that name is already in use
Nov 23 01:08:11 overcloud-controller-2.example.com systemd[1]: ceph-mgr@overcloud-controller-2.service: Control process exited, code=exited status=125
Nov 23 01:08:11 overcloud-controller-2.example.com systemd[1]: ceph-mgr@overcloud-controller-2.service: Failed with result 'exit-code'.
Nov 23 01:08:11 overcloud-controller-2.example.com systemd[1]: Failed to start Ceph Manager.
Nov 23 01:08:11 overcloud-controller-2.example.com podman[180442]: Error: error creating container storage: the container name "ceph-mon-overcloud-controller-2" is already in use by "a81a811c5b4e9898d86ad1c23929feaa0cf18617e6649e069494b94cd174d951". You have to remove that container to be able to reuse that name.: that name is already in use
Nov 23 01:08:11 overcloud-controller-2.example.com systemd[1]: ceph-mon@overcloud-controller-2.service: Control process exited, code=exited status=125
Nov 23 01:08:11 overcloud-controller-2.example.com systemd[1]: ceph-mon@overcloud-controller-2.service: Failed with result 'exit-code'.
Nov 23 01:08:11 overcloud-controller-2.example.com systemd[1]: Failed to start Ceph Monitor.

sudo podman stop grafana-server
sudo podman stop ceph-mgr-overcloud-controller-2
sudo podman stop ceph-mon-overcloud-controller-2
```

### Mac terminal 报错 operation not permitted 的处理
https://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/

### Mac Big Sur 设置 remote viewer
https://rizvir.com/articles/ovirt-mac-console/

### Red Hat Satellite 6 创建 internal registry 
https://access.redhat.com/solutions/3233491

### Nutanix Labs

```
ncli datastore help 
ncli storagepool help
ncli container help

ncli user help
ncli user list

ncli container create help
ncli container create name=cli-container-jun sp-name=SP01

allssh manage_ovs show_interfaces
allssh manage_ovs show_bridges
allssh manage_ovs show_uplinks

# 支持的 Guest OS
https://portal.nutanix.com/page/documents/compatibility-matrix/guestos
```

### data path operation
https://www.ovirt.org/develop/release-management/features/storage/data-path-operations.html<bf>
https://access.redhat.com/documentation/zh-cn/red_hat_virtualization/4.0/html/administration_guide/the_storage_pool_managerspm<br>
https://www.ovirt.org/develop/developer-guide/vdsm/sanlock.html<br>

### Default repositories are missing in the RHEL 9 beta UBI
https://access.redhat.com/solutions/6527961<br>
https://developers.redhat.com/articles/faqs-no-cost-red-hat-enterprise-linux<br>

### TripleO Routed Networks Deployment (Spine-and-Leaf Clos)
https://specs.openstack.org/openstack/tripleo-specs/specs/queens/tripleo-routed-networks-deployment.html<br>
[RFE][Tracker] Enable BGP Routing For Spine-Leaf Deployments<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1896551<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1791821<br>
https://specs.openstack.org/openstack/neutron-specs/specs/liberty/ipv6-prefix-delegation.html<br>
https://specs.openstack.org/openstack/neutron-specs/specs/ussuri/ml2ovs-ovn-convergence.html#feature-gap-analysis<br>
https://github.com/alauda/kube-ovn/blob/f2dc37ceca28ed984511b351ce22a040bf749975/docs/bgp.md<br>
https://object-storage-ca-ymq-1.vexxhost.net/swift/v1/6e4619c416ff4bd19e1c087f27a43eea/www-assets-prod/presentation-media/20170508-IPv6-Lessons.pdf<br>
https://etherpad.opendev.org/p/neutron-xena-ptg<br>
https://etherpad.opendev.org/p/tripleo-frr-integration<br>
https://www.youtube.com/watch?v=9DL8M1d4xLY<br>

### OCP 4.9 use aws object storage as registry storage
https://docs.openshift.com/container-platform/4.9/registry/configuring_registry_storage/configuring-registry-storage-aws-user-infrastructure.html

### 王征的 OCP 仓库
https://github.com/wangzheng422/docker_env

### OVS-DPDK - The group RxQ-to-PMD assignment type
https://developers.redhat.com/articles/2021/11/19/improve-multicore-scaling-open-vswitch-dpdk#other_rxq_considerations

### Red Hat Virtualization no longer supports software FCoE starting with version 4.4
https://access.redhat.com/solutions/5269201

### 检查控制节点的 neutron plugin ml2 extension_dirvers
```
[stack@overcloud-controller-2 ~]$ sudo grep -A10 neutron::plugins::ml2::extension_drivers  /etc/puppet/hieradata/service_configs.json
    "neutron::plugins::ml2::extension_drivers": [
        "qos",
        "port_security",
        "dns"
    ],
    "neutron::plugins::ml2::firewall_driver": "iptables_hybrid",
    "neutron::plugins::ml2::flat_networks": [
        "datacentre"
    ],
...
```
### 检查最新的 config-download 是否包含某个配置
```
(overcloud) [stack@undercloud ~]$ sudo grep -r port_security /var/lib/mistral/config-download-latest/ | grep -Ev ansible.log
/var/lib/mistral/config-download-latest/Controller/config_settings.yaml:- port_security
/var/lib/mistral/config-download-latest/group_vars/Controller:  - port_security
```

### Role Specific Parameters
https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/role_specific_parameters.html

NeutronPluginExtensions 不是一个 Role Specific Parameter

### OCS/ODF crash 处理
```
ceph health detail
ceph status
ceph crash ls
ceph crash archive-all

# 不见得需要执行
# ceph crash rm <id>
```

### Implementing Security Groups in OpenStack using OVN Port Groups
http://dani.foroselectronica.es/implementing-security-groups-in-openstack-using-ovn-port-groups-478/

### Deploying Overcloud with L3 routed networking
https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/routed_spine_leaf_network.html

### 深入理解 TripleO
https://www.bookstack.cn/read/deep-understanding-of-tripleo/%E5%B0%81%E9%9D%A2.md

# undercloud.conf 文件参数解释
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.0/html/director_installation_and_usage/installing-the-undercloud
```
# 根据以下解释，如果希望 ctlplane subnet 通过 masquerade 的方式通过 undercloud 访问外网，就把这个参数设置为 true 
masquerade
Defines whether to masquerade the network defined in the cidr for external access. This provides the Provisioning network with a degree of network address translation (NAT) so that the Provisioning network has external access through director.

# 生成 rhel 8.2 的配置文件
kernel parameters  
ks=http://10.66.208.115/ks-undercloud.cfg ksdevice=ens3 ip=10.66.208.121 netmask=255.255.255.0 dns 10.64.63.6 gateway=10.66.208.254

cat > ks-undercloud.cfg << 'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
poweroff
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart --nohome
network --device=ens3 --hostname=undercloud.example.com --bootproto=static --ip=10.66.208.121 --netmask=255.255.255.0 --gateway=10.66.208.254 --nameserver=10.64.63.6
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
createrepo
vim
yum-utils
wget
%end
EOF

> /etc/yum.repos.d/osp.repo
for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms rhel-8-for-x86_64-highavailability-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms openstack-16.1-for-rhel-8-x86_64-rpms fast-datapath-for-rhel-8-x86_64-rpms rhceph-4-tools-for-rhel-8-x86_64-rpms advanced-virt-for-rhel-8-x86_64-rpms
do
cat >> /etc/yum.repos.d/osp.repo << EOF
[$i]
name=$i
baseurl=file:///var/www/html/repos/osp16.1/$i/
enabled=1
gpgcheck=0

EOF
done

tar zcvf /tmp/osp16.1-yum-repos-$(date -I).tar.gz /var/www/html/repos/OSP16_1_repo_sync_up.sh /var/www/html/repos/osp16.1

tar zcvf /home/osp16.1-poc-registry-$(date -I).tar.gz /opt/registry


```

### 重启运行self hosted engine的服务器
参考： https://access.redhat.com/solutions/2486301
```
hosted-engine --vm-shutdown 
hosted-engine --vm-status
virsh -r list
reboot

# 重启后，执行
systemctl stop ovirt-ha-agent
systemctl stop ovirt-ha-broker
systemctl restart nfs-server
systemctl start ovirt-ha-broker
systemctl start ovirt-ha-agent

# 检查服务状态
systemctl status ovirt-ha-broker
systemctl status ovirt-ha-agent

# 检查 hosted-engine 状态
hosted-engine --vm-status
hosted-engine --vm-start
watch hosted-engine --vm-status
hosted-engine --set-maintenance --mode=none
```

### undercloud.conf 的内容
```
# cat /usr/share/python-tripleoclient/undercloud.conf.sample
# 普通部署
# 部署时定义了 subnets 和 local_subnet 
# subnets 只定义了 1 个 subnet ctlplane-subnet
# local_subnet 是 ctlplane-subnet
# ctlplane-subnet 的定义包括
# cidr 网段
# dhcp_start 和 dhcp_stop
# inspection_iprange 定义了 inttrospection 时使用的 ip 范围
# gateway
# masquerade
cat > undercloud.conf <<EOF
[DEFAULT]
undercloud_hostname = undercloud.example.com
container_images_file = containers-prepare-parameter.yaml
local_ip = 192.0.2.1/24
undercloud_public_host = 192.0.2.2
undercloud_admin_host = 192.0.2.3
subnets = ctlplane-subnet
local_subnet = ctlplane-subnet
local_interface = ens10
inspection_extras = true
undercloud_debug = false
enable_tempest = false
enable_ui = false
clean_nodes = true
overcloud_domain_name = example.com
undercloud_nameservers = 192.168.122.3

[auth]
undercloud_admin_password = redhat

[ctlplane-subnet]
cidr = 192.0.2.0/24
dhcp_start = 192.0.2.5
dhcp_end = 192.0.2.24
inspection_iprange = 192.0.2.100,192.0.2.120
gateway = 192.0.2.1
masquerade = true
EOF


```

### osp 的 rpm 版本信息可以参见 openstack-16.1-for-rhel-8-x86_64-rpms 仓库的 rhosp-release 软件包

### BaiduPCS-Go 下载
https://github.com/qjfoidnh/BaiduPCS-Go/releases/tag/v3.8.4<br>
https://github.com/GangZhuo/BaiduPCS.git<br>
https://blog.csdn.net/ykiwmy/article/details/103730962<br>
```
# 登陆
BaiduPCS-Go login -bduss=<BDUSS>
# 上传文件
BaiduPCS-Go upload osp16.1-yum-repos-2021-11-25.tar.gz /osp16.1/repos
```


### rhel8  
```
# update dnf 相关软件
# yum list all | grep dnf | grep -E "anaconda|AppStream"  | awk '{print $1}' | while read i ; do yum update -y $i ; done 

# yum clean all
# yum repolist 
# yum install -y chrony

# 查看接口 TX RX 数据包信息
ip -s link show dev ens3
```

### Red Hat Solutions - Result: hostbyte=DID_ERROR driverbyte=DRIVER_OK
https://access.redhat.com/solutions/438403

### 命令历史控制
```
关闭命令历史 
set +o history

打开命令历史
set -o history
```
 
### 记录
```
https://www.jianshu.com/p/55c22e455ec9
https://zhuanlan.zhihu.com/p/84026420
术语
PLC - Programmable Logic Controller- 可编程逻辑控制器 - 现场设备层
SCADA - Supervisory Control And Data AcquiSition System - 数据采集与监控系统 - 调度管理层
HMI - Human Machine Interface - 人机界面 - 是系统和用户之间进行交互和信息交换的媒介
PPS - Production Pull System - 生产拉动系统 - 基于预测未来消耗，有计划补充物料
MES - Manufacturing Execution System - 制造执行系统 - 面向制造企业车间执行层的生产信息化管理系统
PLM - Product Lifecycle Management - 产品生命周期管理 - 
ERP - Enterprise Resource Planning - 企业资源计划管理 全程企业资源规划 公司综合管理系统 - 管理层

https://zhuanlan.zhihu.com/p/43002417
什么是GitOps？
GitOps是一种持续交付的方式。它的核心思想是将应用系统的声明性基础架构和应用程序存放在Git版本库中。

DaemonSet 确保所有（或部分）节点运行一个 Pod 的副本。 如果 Node 与集群断开连接，那么 k8s API 中的 Daemonset Pod 将不会改变状态，并将继续保持上次报告的状态。

在网络中断期间如果节点重新启动，将不重新启动工作负载

当节点网络中断恢复节点重新加入集群时，工作负载重新启动

如果工作负载在所有 Remote Worker Nodes 上运行时建议使用 DaemonSet 运行工作负载。 DaemonSet 还支持 Service Endpoint 和 Load Balancer。

Static Pod 由特定节点上的 kubelet 守护进程管理。 与由 k8s 控制平面管理的 Pod 不同，节点的 kubelet 负责监视每个Static Pod。

在 Pod-eviction-timeout 之后调度 Pod 的其他方法；

减缓 pod evict...
通常，对于无法访问的受污染节点，控制器以每 10 秒 1 个节点的速率执行 pod evict，使用区域控制器后以每 100 秒驱逐 1 个节点的速率执行 pod evict。
少于 50 个节点的集群不会标记Tainted，并且您的集群必须具有 3 个以上的区域才能生效。

https://docs.openstack.org/neutron/wallaby/admin/ovn/router_availability_zones.html

ml2/ovn 的实现
https://docs.openstack.org/neutron/wallaby/admin/ovn/router_availability_zones.html

$ ovs-vsctl set Open_vSwitch . \
external-ids:ovn-cms-options="enable-chassis-as-gw,availability-zones=az-0:az-1:az-2"
上面的命令在 external-ids:ovn-cms-options 选项中添加了两个配置，enable-chassis-as-gw 选项告诉 OVN 驱动程序这是一个网关/网络节点，available-zones 选项指定三个可用区：az -0、az-1 和 az-2。


在 Pod-eviction-timeout 之后重新安排 Pod 的其他方法；

缺点
在没有来自 API 服务器的任何触发的情况下，是否通过节点重新启动来重新启动工作负载


减缓 pod 驱逐...
通常，对于无法访问的受污染节点，控制器以每 10 秒 1 个节点的速率驱逐 pod，使用区域控制器以每 100 秒驱逐 1 个节点的速率驱逐。少于 50 个节点的集群不会被污染，并且您的集群必须有 3 个以上的区域才能生效。

当连接恢复时，在 Pod-eviction-timeout 或 tolerationSeconds 到期之前，节点会在控制平面管理下返回
如果容忍秒数 = 0，容忍可以无限期地减轻 pod 驱逐；
或者使用给定污点的指定值延长 pod 驱逐超时；
$ openstack network agent list
+--------------------------------------+------------------------------+----------------+-------------------+-------+-------+----------------+
| ID                                   | Agent Type                   | Host           | Availability Zone | Alive | State | Binary         |
+--------------------------------------+------------------------------+----------------+-------------------+-------+-------+----------------+
| 2d1924b2-99a4-4c6c-a4f2-0be64c0cec8c | OVN Controller Gateway agent | gateway-host-0 | az0, az1, az2     | :-)   | UP    | ovn-controller |
+--------------------------------------+------------------------------+----------------+-------------------+-------+-------+----------------+

$ openstack router create --availability-zone-hint az-0 --availability-zone-hint az-1 router-0
+-------------------------+--------------------------------------+
| Field                   | Value                                |
+-------------------------+--------------------------------------+
| admin_state_up          | UP                                   |
| availability_zone_hints | az-0, az-1                           |
| availability_zones      |                                      |
| created_at              | 2020-06-04T08:29:33Z                 |
| description             |                                      |
| external_gateway_info   | null                                 |
| flavor_id               | None                                 |
| id                      | 8fd6d01a-57ad-4e91-a788-ebe48742d000 |
| name                    | router-0                             |
| project_id              | 2a364ced6c084888be0919450629de1c     |
| revision_number         | 1                                    |
| routes                  |                                      |
| status                  | ACTIVE                               |
| tags                    |                                      |
| updated_at              | 2020-06-04T08:29:33Z                 |
+-------------------------+--------------------------------------+

Playbook - 用来创建 osp 16.2 dcn 的环境
https://gitlab.cee.redhat.com/sputhenp/lab/-/blob/master/recreate-infra.yaml -e "osp_version=16" osp_sub_version=2 dcn=1"
```

### windows add route 命令
https://www.jianshu.com/p/c99c267f3f8d<br>
https://stackoverflow.com/questions/4974131/how-to-create-ssh-tunnel-using-putty-in-windows<br>
```
# 希望达到的效果是，在 Windows Putty 这边访问 127.0.0.1:13808 通过 ssh 隧道转发到 192.168.122.40:13808 上
# Connection -> SSH -> Tunnels
# Source port: 13808
# Destination: 192.168.122.40:13808
# 选中：Local
# 选中：Auto
# Add
# L13808 192.168.122.40:13808
# L80 192.168.122.40:80
# L443 192.168.122.40:443
# L8444 192.168.122.40:8444
# L3100 192.168.122.40:3100
# Open
```

```
# 在 window 这边添加主机路由
route -p add 192.168.122.1 mask 255.255.255.255 10.66.208.240

# 建立 putty ssh 隧道
# https://tecadmin.net/putty-ssh-tunnel-and-port-forwarding/

# 编辑 windows hosts 文件
# c:\Windows\System32\Drivers\etc\hosts

# Windows 10 添加证书
# https://docs.fortinet.com/document/fortiauthenticator/5.5.0/cookbook/494798/manually-importing-the-client-certificate-windows-10

# rclone 如何设置不检查证书？
# https://github.com/rclone/rclone/issues/168
# rclone.exe --no-check-certificate lsd s3:
# 注意将本地时间与 s3 服务器时间配置成一致的时间
```

### Infraed 相关资料
https://github.com/sean-m-sullivan/infrared_custom_documentation

### CephFS 
https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/5/html-single/file_system_guide/index#exporting-ceph-file-system-namespaces-over-the-nfs-protocol_fs<br>
https://documentation.suse.com/zh-cn/ses/6/html/ses-all/cha-ses-cifs.html<br>

S3 Client<br>
https://rclone.org/<br>
https://mountainduck.io/<br>

s3browse 用 s3 协议访问 ceph bucket<br>
https://blog.csdn.net/wuguifa/article/details/109605973<br>
Endpoint: overcloud.example.com:13808<br>
Use secure transfer (SSL/TLS): true<br>

rook ceph dashboard<br>
https://github.com/rook/rook/blob/master/Documentation/ceph-dashboard.md<br>

kubernetes csi drivers<br>
https://kubernetes-csi.github.io/docs/drivers.html<br>

### ImageBuild Service
https://console.redhat.com/beta/insights/image-builder<br>

### migration from self host engine to another self host engine
https://access.redhat.com/documentation/en-us/red_hat_virtualization/4.4/html/self-hosted_engine_guide/restoring_the_backup_on_a_new_self-hosted_engine_migrating_to_she<br>

### 获取 ceph rgw 的 haproxy 配置
```
# 查看 rgw 的 haproxy 配置
# 192.168.122.40 对应 public/external endpoint
[stack@overcloud-controller-0 ~]$ sudo -i cat /var/lib/config-data/puppet-generated/haproxy/etc/haproxy/haproxy.cfg | grep rgw -A12
listen ceph_rgw
  bind 172.16.1.240:8080 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem
  bind 192.168.122.40:13808 transparent ssl crt /etc/pki/tls/private/overcloud_endpoint.pem
  mode http
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
  http-request set-header X-Forwarded-Proto http if !{ ssl_fc }
  http-request set-header X-Forwarded-Port %[dst_port]
  option httpchk GET /swift/healthcheck
  redirect scheme https code 301 if { hdr(host) -i 192.168.122.40 } !{ ssl_fc }
  rsprep ^Location:\ http://(.*) Location:\ https://\1
  server overcloud-controller-0.storage.example.com 172.16.1.51:8080 ca-file /etc/ipa/ca.crt check fall 5 inter 2000 rise 2 ssl verify required verifyhost overcloud-controller-0.storage.example.com
  server overcloud-controller-1.storage.example.com 172.16.1.52:8080 ca-file /etc/ipa/ca.crt check fall 5 inter 2000 rise 2 ssl verify required verifyhost overcloud-controller-1.storage.example.com
  server overcloud-controller-2.storage.example.com 172.16.1.53:8080 ca-file /etc/ipa/ca.crt check fall 5 inter 2000 rise 2 ssl verify required verifyhost overcloud-controller-2.storage.example.com

# 从 undercloud 访问 192.168.122.40:13808 对应的 url (overcloud.example.dom)
[stack@overcloud-controller-0 ~]$ curl https://overcloud.example.com:13808
<?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>anonymous</ID><DisplayName></DisplayName></Owner><Buckets></Buckets></ListAllMyBucketsResult>
[stack@overcloud-controller-0 ~]$ 

# 创建用户
# uid: admin
# display-name: admin
# access-key: admin
# secret-key: admin123
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-rgw-overcloud-controller-0-rgw0 radosgw-admin user create --uid='admin' --display-name='admin' --access-key='admin' --secret-key='admin123'

# 安装 aws cli
# Linux
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
(overcloud) [stack@undercloud ~]$ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
(overcloud) [stack@undercloud ~]$ unzip awscliv2.zip
(overcloud) [stack@undercloud ~]$ sudo ./aws/install
# MacOS 安装注意参考 MacOS 部分 
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
$ curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
$ sudo installer -pkg AWSCLIV2.pkg -target /
$ aws --version

# 配置一下 aws s3 client
# 设置 access key
# 设置 secret key
# 注意，需要设置 Default region name，否则 mkbucket 时将会有报错
# make_bucket failed: s3://mybucket An error occurred (InvalidLocationConstraint) when calling the CreateBucket operation: The specified location-constraint is not valid

(overcloud) [stack@undercloud ~]$ aws configure 
AWS Access Key ID [None]: admin
AWS Secret Access Key [None]: admin123
Default region name [None]: us-east-1
Default output format [None]: 

# 查看 bucket
# 设置环境变量 AWS_CA_BUNDLE
# https://www.shellhacks.com/aws-cli-ssl-validation-failed-solved/
(overcloud) [stack@undercloud ~]$ export AWS_CA_BUNDLE="/etc/pki/tls/certs/ca-bundle.crt"
(overcloud) [stack@undercloud ~]$ aws --endpoint=https://overcloud.example.com:13808 s3 ls
# 创建 bucket
(overcloud) [stack@undercloud ~]$ aws --endpoint=https://overcloud.example.com:13808 s3 mb s3://mybucket
make_bucket: mybucket
# 上传文件到 bucket
(overcloud) [stack@undercloud ~]$ aws --endpoint=https://overcloud.example.com:13808 s3 cp /home/stack/overcloudrc s3://mybucket
upload: ./overcloudrc to s3://mybucket/overcloudrc  

# 设置 alias 
# https://github.com/aws/aws-cli/issues/4454
(overcloud) [stack@undercloud ~]$ alias aws='aws --endpoint-url https://overcloud.example.com:13808'
(overcloud) [stack@undercloud ~]$ aws s3 ls 
2021-11-30 09:57:51 mybucket

# 下载 rclone 
# https://downloads.rclone.org/v1.57.0/rclone-v1.57.0-linux-amd64.zip
(overcloud) [stack@undercloud ~]$ unzip /tmp/rclone-v1.57.0-linux-amd64.zip
(overcloud) [stack@undercloud ~]$ sudo cp rclone-v1.57.0-linux-amd64/rclone /usr/local/bin/ 
(overcloud) [stack@undercloud ~]$ rclone config
2021/11/30 10:13:08 NOTICE: Config file "/home/stack/.config/rclone/rclone.conf" not found - using defaults
No remotes found - make a new one
n) New remote
s) Set configuration password
q) Quit config
n/s/q> n
name> s3
Option Storage.
Type of storage to configure.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value.
 1 / 1Fichier
   \ "fichier"
 2 / Alias for an existing remote
   \ "alias"
 3 / Amazon Drive
   \ "amazon cloud drive"
 4 / Amazon S3 Compliant Storage Providers including AWS, Alibaba, Ceph, Digital Ocean, Dreamhost, IBM COS, Minio, SeaweedFS, and Tencent COS
   \ "s3"
...
Storage> 4
Option provider.
Choose your S3 provider.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value.
 1 / Amazon Web Services (AWS) S3
   \ "AWS"
 2 / Alibaba Cloud Object Storage System (OSS) formerly Aliyun
   \ "Alibaba"
 3 / Ceph Object Storage
   \ "Ceph"
 4 / Digital Ocean Spaces
   \ "DigitalOcean"
provider> 3

Option env_auth.
Get AWS credentials from runtime (environment variables or EC2/ECS meta data if no env vars).
Only applies if access_key_id and secret_access_key is blank.
Enter a boolean value (true or false). Press Enter for the default ("false").
Choose a number from below, or type in your own value.
 1 / Enter AWS credentials in the next step.
   \ "false"
 2 / Get AWS credentials from the environment (env vars or IAM).
   \ "true"
env_auth> 1

Option access_key_id.
AWS Access Key ID.
Leave blank for anonymous access or runtime credentials.
Enter a string value. Press Enter for the default ("").
access_key_id> admin

Option secret_access_key.
AWS Secret Access Key (password).
Leave blank for anonymous access or runtime credentials.
Enter a string value. Press Enter for the default ("").
secret_access_key> admin123

Option region.
Region to connect to.
Leave blank if you are using an S3 clone and you don't have a region.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value.
   / Use this if unsure.
 1 | Will use v4 signatures and an empty region.
   \ ""
   / Use this only if v4 signatures don't work.
 2 | E.g. pre Jewel/v10 CEPH.
   \ "other-v2-signature"
region> 1

Option endpoint.
Endpoint for S3 API.
Required when using an S3 clone.
Enter a string value. Press Enter for the default ("").
endpoint> https://overcloud.example.com:13808

Option location_constraint.
Location constraint - must be set to match the Region.
Leave blank if not sure. Used when creating buckets only.
Enter a string value. Press Enter for the default ("").
location_constraint> 

Option acl.
Canned ACL used when creating buckets and storing or copying objects.
This ACL is used for creating objects and if bucket_acl isn't set, for creating buckets too.
For more info visit https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl
Note that this ACL is applied when server-side copying objects as S3
doesn't copy the ACL from the source but rather writes a fresh one.
Enter a string value. Press Enter for the default ("").
acl> 

Option server_side_encryption.
The server-side encryption algorithm used when storing this object in S3.
Enter a string value. Press Enter for the default ("").
server_side_encryption>

Option sse_kms_key_id.
If using KMS ID you must provide the ARN of Key.
Enter a string value. Press Enter for the default ("").
sse_kms_key_id> 

Edit advanced config?
y) Yes
n) No (default)
y/n> 
--------------------
[s3]
type = s3
provider = Ceph
access_key_id = admin
secret_access_key = admin123
endpoint = https://overcloud.example.com:13808
--------------------
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d> 
Current remotes:

Name                 Type
====                 ====
s3                   s3

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q> q

# https://rclone.org/s3/

# 查看 all buckets
rclone lsd s3:

# 使用 rclone 时需要 unset AWS_CA_BUNDLE
# https://forum.rclone.org/t/mounting-an-amazon-s3-bucket/15106
# 否则有报错
# "Failed to create file system for mountname:bucketname: LoadCustomCABundleError: unable to load custom CA bundle, HTTPClient's transport unsupported type"
(overcloud) [stack@undercloud ~]$ unset AWS_CA_BUNDLE 
(overcloud) [stack@undercloud ~]$ rclone lsd s3:
          -1 2021-11-30 09:57:51        -1 mybucket
# 查看 bucket
(overcloud) [stack@undercloud ~]$ rclone ls s3:mybucket
     1015 overcloudrc

(overcloud) [stack@undercloud ~]$ rclone copy /home/stack/stackrc s3:mybucket
(overcloud) [stack@undercloud ~]$ rclone ls s3:mybucket
     1015 overcloudrc
      774 stackrc

# 查看 pool 的情况
(overcloud) [stack@undercloud ~]$ ssh stack@192.0.2.51
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd dump | grep pool

[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph health detail
HEALTH_WARN 10 pools have too many placement groups
POOL_TOO_MANY_PGS 10 pools have too many placement groups
    Pool vms has 128 placement groups, should have 32
    Pool volumes has 128 placement groups, should have 32
    Pool images has 128 placement groups, should have 32
    Pool .rgw.root has 128 placement groups, should have 32
    Pool default.rgw.control has 128 placement groups, should have 32
    Pool default.rgw.meta has 128 placement groups, should have 32
    Pool default.rgw.log has 128 placement groups, should have 32
    Pool default.rgw.buckets.index has 128 placement groups, should have 32
    Pool default.rgw.buckets.data has 128 placement groups, should have 32
    Pool default.rgw.buckets.non-ec has 128 placement groups, should have 32

# 查看 pool 的 autoscale-status 
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool autoscale-status 
POOL                         SIZE TARGET SIZE RATE RAW CAPACITY  RATIO TARGET RATIO EFFECTIVE RATIO BIAS PG_NUM NEW PG_NUM AUTOSCALE 
vms                            0               3.0       899.9G 0.0000                               1.0    128         32 warn      
volumes                        0               3.0       899.9G 0.0000                               1.0    128         32 warn      
images                      9216M              3.0       899.9G 0.0300                               1.0    128         32 warn      
.rgw.root                   3653               3.0       899.9G 0.0000                               1.0    128         32 warn      
default.rgw.control            0               3.0       899.9G 0.0000                               1.0    128         32 warn      
default.rgw.meta            1088               3.0       899.9G 0.0000                               1.0    128         32 warn      
default.rgw.log             4519               3.0       899.9G 0.0000                               1.0    128         32 warn      
default.rgw.buckets.index  10832               3.0       899.9G 0.0000                               1.0    128         32 warn      
default.rgw.buckets.data   30556k              3.0       899.9G 0.0001                               1.0    128         32 warn      
default.rgw.buckets.non-ec     0               3.0       899.9G 0.0000                               1.0    128         32 warn   

# 默认的 autoscale 设置为 'warn'，触发告警
# https://docs.ceph.com/en/latest/rados/operations/placement-groups/
# 手工调整为 'on'
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph config set global osd_pool_default_pg_autoscale_mode on

# 查看参数调整情况
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph config dump
WHO    MASK LEVEL    OPTION                                           VALUE                                    RO 
global      advanced osd_pool_default_pg_autoscale_mode               on                                          
  mgr       advanced mgr/dashboard/ALERTMANAGER_API_HOST              http://172.16.1.51:9093                  *  
  mgr       advanced mgr/dashboard/GRAFANA_API_PASSWORD               NOT_REAL_PASSWORD			       *  
  mgr       advanced mgr/dashboard/GRAFANA_API_SSL_VERIFY             false                                    *  
  mgr       advanced mgr/dashboard/GRAFANA_API_URL                    https://192.0.2.240:3100                 *  
  mgr       advanced mgr/dashboard/GRAFANA_API_USERNAME               admin                                    *  
  mgr       advanced mgr/dashboard/PROMETHEUS_API_HOST                http://172.16.1.51:9092                  *  
  mgr       advanced mgr/dashboard/RGW_API_ACCESS_KEY                 7LECDPNKIA22FFE78X1Y                     *  
  mgr       advanced mgr/dashboard/RGW_API_HOST                       172.16.1.51                              *  
  mgr       advanced mgr/dashboard/RGW_API_PORT                       8080                                     *  
  mgr       advanced mgr/dashboard/RGW_API_SCHEME                     https                                    *  
  mgr       advanced mgr/dashboard/RGW_API_SECRET_KEY                 lmJx68zSRUw9M13gAtZIDxzVD0KUxULroXdGInnq *  
  mgr       advanced mgr/dashboard/RGW_API_USER_ID                    ceph-dashboard                           *  
  mgr       advanced mgr/dashboard/overcloud-controller-0/server_addr 172.16.1.51                              *  
  mgr       advanced mgr/dashboard/overcloud-controller-1/server_addr 172.16.1.52                              *  
  mgr       advanced mgr/dashboard/overcloud-controller-2/server_addr 172.16.1.53                              *  
  mgr       advanced mgr/dashboard/server_port                        8444                                     *  
  mgr       advanced mgr/dashboard/ssl                                true                                     *  
  mgr       advanced mgr/dashboard/ssl_server_port                    8444                                     *  


[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph config get mon.0
WHO    MASK LEVEL    OPTION                             VALUE RO 
global      advanced osd_pool_default_pg_autoscale_mode on       
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph config get osd.0
WHO    MASK LEVEL    OPTION                             VALUE RO 
global      advanced osd_pool_default_pg_autoscale_mode on       
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph config get osd.1
WHO    MASK LEVEL    OPTION                             VALUE RO 
global      advanced osd_pool_default_pg_autoscale_mode on 

# 手工设置 pool 的 pg_autoscale_mode 为 on
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph health detail | grep Pool | awk '{print $2}' | while read i ;do echo sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set $i pg_autoscale_mode on ; done

sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set volumes pg_autoscale_mode on
sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set images pg_autoscale_mode on
sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set .rgw.root pg_autoscale_mode on
sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set default.rgw.control pg_autoscale_mode on
sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set default.rgw.meta pg_autoscale_mode on
sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set default.rgw.log pg_autoscale_mode on
sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set default.rgw.buckets.index pg_autoscale_mode on
sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set default.rgw.buckets.data pg_autoscale_mode on
sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool set default.rgw.buckets.non-ec pg_autoscale_mode on

# 这些命令执行下来之后，ceph status 转变为 ‘HEALTH_OK’ 了
# https://docs.ceph.com/en/latest/rados/operations/placement-groups/
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph health detail 
HEALTH_OK
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph osd pool autoscale-status
POOL                         SIZE TARGET SIZE RATE RAW CAPACITY  RATIO TARGET RATIO EFFECTIVE RATIO BIAS PG_NUM NEW PG_NUM AUTOSCALE 
vms                            0               3.0       899.9G 0.0000                               1.0     32            on        
volumes                        0               3.0       899.9G 0.0000                               1.0     32            on        
images                      9421M              3.0       899.9G 0.0307                               1.0     32            on        
.rgw.root                   3653               3.0       899.9G 0.0000                               1.0     32            on        
default.rgw.control            0               3.0       899.9G 0.0000                               1.0     32            on        
default.rgw.meta            1088               3.0       899.9G 0.0000                               1.0     32            on        
default.rgw.log             4548               3.0       899.9G 0.0000                               1.0     32            on        
default.rgw.buckets.index  10832               3.0       899.9G 0.0000                               1.0     32            on        
default.rgw.buckets.data   30919k              3.0       899.9G 0.0001                               1.0     32            on        
default.rgw.buckets.non-ec     0               3.0       899.9G 0.0000                               1.0     32            on  

# 查看 radosgw user 'ceph-dashboard' 相关信息 
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-rgw-overcloud-controller-0-rgw0 radosgw-admin user info --uid='ceph-dashboard'
{
    "user_id": "ceph-dashboard",  
    "display_name": "Ceph dashboard",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "subusers": [],
    "keys": [
        {
            "user": "ceph-dashboard",
            "access_key": "7LECDPNKIA22FFE78X1Y",
            "secret_key": "lmJx68zSRUw9M13gAtZIDxzVD0KUxULroXdGInnq"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "system": "true",
    "default_placement": "",
    "default_storage_class": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "user_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },                             
    "temp_url_keys": [],
    "type": "rgw",
    "mfa_ids": []
}

# 在 ceph dashboard 上访问 Object Gateway 时报 404
# https://docs.ceph.com/en/latest/mgr/dashboard/#dashboard-enabling-object-gateway
# 设置 ceph dashboard set-rgw-api-ssl-verify False
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph dashboard set-rgw-api-ssl-verify False 
Option RGW_API_SSL_VERIFY updated
[stack@overcloud-controller-0 ~]$ sudo podman exec -it ceph-mon-overcloud-controller-0 ceph config dump 
WHO    MASK LEVEL    OPTION                                           VALUE                                    RO 
[TRUNCATED]
  mgr       advanced mgr/dashboard/RGW_API_SSL_VERIFY                 false                                    *  
[TRUNCATED]

这是一些 s3 图形化客户端软件
winscp - Windows
https://winscp.net/eng/docs/guide_amazon_s3
cloudberry - Windows
https://cloudberry-explorer-for-amazon-s3.en.softonic.com/
cyberduck - Mac, Windows
https://cyberduck.io/s3/
rclone - Linux, Windows
https://rclone.org/gui/
https://github.com/guimou/rclone-web-on-openshift
```

### 增加 tripleo firewall 规则的模版
```
# 注意：
# 1. 以下模版内容可以在默认 tripleo firewall rule 的基础上追加规则
# 2. 作用的位置在 'INPUT' Chain 和 'filter' table
parameter_defaults:
  PurgeFirewallRules: true 
  ExtraConfig:
    tripleo::firewall::firewall_rules:
      '005 allow SSH from X.X.X.X/24':
        dport: 22
        proto: tcp
        source: X.X.X.X/24
      '006 allow SSH from X.X.X.X/22':
        dport: 22
        proto: tcp
        source: X.X.X.X/22
      '007 allow SSH from X.X.X.X/22':
        dport: 22
        proto: tcp
        source: X.X.X.X/22
      '008 allow SSH from X.X.X.X/21':
        dport: 22
        proto: tcp
        source: X.X.X.X/21
      '009 allow SSH from X.X.X.X/26':
        dport: 22
        proto: tcp
        source: X.X.X.X/26
      '010 allow SSH from X.X.X.X/32':
        dport: 22
        proto: tcp
        source: X.X.X.X/32
      '011 allow SSH from X.X.X.X/25':
        dport: 22
        proto: tcp
        source: X.X.X.X/25
      '012 allow SSH from X.X.X.X/24':
        dport: 22
        proto: tcp
        source: X.X.X.X/24
      '300 allow SNMP from NMS 1':
        dport: 161
        proto: udp
        source: X.X.X.X/24
      '301 allow SNMP from NMS 2':
        dport: 161
        proto: udp
        source: X.X.X.X/22
      '302 allow connection to Netdata':
        dport: 19999
      '303 allow Prometheus connections':
        dport: 9283
        proto: tcp
        source: X.X.X.X/22
```

### 报错
```
(overcloud) [stack@undercloud ~]$ aws s3 mb s3://dashboard
make_bucket failed: s3://dashboard Unable to parse response (not well-formed (invalid token): line 1, column 0), invalid XML received. Further retries may succeed:
b'{"entry_point_object_ver":{"tag":"_uSknuO-j1hIYKh1V_6uPxup","ver":1},"object_ver":{"tag":"_kFKbUVxpvcWgz4t71AqWZ2T","ver":1},"bucket_info":{"bucket":{"name":"dashboard","marker":"dd363c96-1c53-4ed7-9f92-b3c2766ef606.294168.1","bucket_id":"dd363c96-1c53-4ed7-9f92-b3c2766ef606.294168.1","tenant":"","explicit_placement":{"data_pool":"","data_extra_pool":"","index_pool":""}},"creation_time":"2021-12-01 07:03:45.758073Z","owner":"ceph-dashboard","flags":0,"zonegroup":"29d0675d-3ba5-452c-b6a7-64c0d9de3859","placement_rule":"default-placement","has_instance_obj":"true","quota":{"enabled":false,"check_on_raw":false,"max_size":-1,"max_size_kb":0,"max_objects":-1},"num_shards":11,"bi_shard_hash_type":0,"requester_pays":"false","has_website":"false","swift_versioning":"false","swift_ver_location":"","index_type":0,"mdsearch_config":[],"reshard_status":0,"new_bucket_instance_id":""}}'
```

### CephExternalMultiConfig 与 CinderRbdMultiConfig
Configuring Ceph Clients for Multiple External Ceph RBD Services<br>
CephExternalMultiConfig support was added in 16.1 specifically to support DCN topologies where
each site supports its own glance store.<br>
https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/ceph_external.html<br>

cinder support is currently not available. it's targeted for OSP-17. It will use a new CinderRbdMultiConfig THT parameter.<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1949701<br>

### 部署单节点 rhcs 5 
```
# 参考
# https://docs.ceph.com/en/latest/man/8/cephadm/#bootstrap
cephadm bootstrap --single-host-defaults

# 安装虚拟机 jwang-ceph04
# rhel 8.4
# 如果之前未清理磁盘可以执行
# sgdisk --delete /dev/sda
# sgdisk --delete /dev/sdb
# sgdisk --delete /dev/sdc
# ks=http://10.66.208.115/jwang-ceph04-ks.cfg nameserver=10.64.63.6 ip=10.66.208.125::10.66.208.254:255.255.255.0:jwang-ceph04.example.com:ens3:none

# 生成 ks.cfg - jwang-ceph04
cat > jwang-ceph04-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
halt
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
ignoredisk --only-use=sda
autopart
network --device=ens3 --hostname=jwang-ceph04.example.com --bootproto=static --ip=10.66.208.125 --netmask=255.255.255.0 --gateway=10.66.208.254 --nameserver=10.64.63.6
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
gdisk
openssl-perl
%end
EOF

# 注册系统到 rhn
subscription-manager register
subscription-manager refresh
subscription-manager list --available --matches 'Red Hat Ceph Storage'
subscription-manager attach --pool=8a85f99979908877017a0d85b3ab3c37
subscription-manager repos --disable=*
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhceph-5-tools-for-rhel-8-x86_64-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms

# 同步 rhcs5 镜像
cat > syncimgs-rhcs5 <<'EOF'
#!/bin/env bash

PUSHREGISTRY=helper.example.com:5000
FORK=4

rhosp_namespace=registry.redhat.io/rhosp-rhel8
rhosp_tag=16.1
ceph_namespace=registry.redhat.io/rhceph
ceph_image=rhceph-5-rhel8
ceph_tag=latest
ceph_alertmanager_namespace=registry.redhat.io/openshift4
ceph_alertmanager_image=ose-prometheus-alertmanager
ceph_alertmanager_tag=v4.6
ceph_grafana_namespace=registry.redhat.io/rhceph
ceph_grafana_image=rhceph-5-dashboard-rhel8
ceph_grafana_tag=5
ceph_node_exporter_namespace=registry.redhat.io/openshift4
ceph_node_exporter_image=ose-prometheus-node-exporter
ceph_node_exporter_tag=v4.6
ceph_prometheus_namespace=registry.redhat.io/openshift4
ceph_prometheus_image=ose-prometheus
ceph_prometheus_tag=v4.6

function copyimg() {
  image=${1}
  version=${2}

  release=$(skopeo inspect docker://${image}:${version} | jq -r '.Labels | (.version + "-" + .release)')
  dest="${PUSHREGISTRY}/${image#*\/}"
  echo Copying ${image} to ${dest}
  skopeo copy docker://${image}:${release} docker://${dest}:${release} --quiet
  skopeo copy docker://${image}:${version} docker://${dest}:${version} --quiet
}

copyimg "${ceph_namespace}/${ceph_image}" ${ceph_tag} &
copyimg "${ceph_alertmanager_namespace}/${ceph_alertmanager_image}" ${ceph_alertmanager_tag} &
copyimg "${ceph_grafana_namespace}/${ceph_grafana_image}" ${ceph_grafana_tag} &
copyimg "${ceph_node_exporter_namespace}/${ceph_node_exporter_image}" ${ceph_node_exporter_tag} &
copyimg "${ceph_prometheus_namespace}/${ceph_prometheus_image}" ${ceph_prometheus_tag} &
wait

#for rhosp_image in $(podman search ${rhosp_namespace} --limit 1000 --format "{{ .Name }}"); do
#  ((i=i%FORK)); ((i++==0)) && wait
#  copyimg ${rhosp_image} ${rhosp_tag} &
#done
EOF

# rhcs5 软件仓库同步脚本
[root@helper repos]# pwd
/var/www/html/repos
[root@helper repos]# cat > rhcs5_repo_sync_up.sh <<EOF
#!/bin/bash

localPath="/var/www/html/repos/rhcs5/"
fileConn="/getPackage/"

## sync following yum repos 
# rhel-8-for-x86_64-baseos-rpms
# rhel-8-for-x86_64-appstream-rpms
# ansible-2.9-for-rhel-8-x86_64-rpms
# rhceph-5-tools-for-rhel-8-x86_64-rpms

for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-appstream-rpms ansible-2.9-for-rhel-8-x86_64-rpms rhceph-5-tools-for-rhel-8-x86_64-rpms
do

  rm -rf "$localPath"$i/repodata
  echo "sync channel $i..."
  reposync -n --delete --download-path="$localPath" --repoid $i --downloadcomps --download-metadata

  #echo "create repo $i..."
  #time createrepo -g $(ls "$localPath"$i/repodata/*comps.xml) --update --skip-stat --cachedir /tmp/empty-cache-dir "$localPath"$i

done

exit 0
EOF

# 查看更新情况
watch "ls -ltr \$(ls -ltr | tail -1 | awk '{print \$9}')/\$(ls -ltr \$(ls -ltr | tail -1 | awk '{print \$9}') | tail -1 | awk '{print \$9}')"

# 在 ceph 节点上配置软件仓库
YUM_REPO_IP="10.66.208.121"
> /etc/yum.repos.d/local.repo 
for i in rhel-8-for-x86_64-baseos-eus-rpms rhel-8-for-x86_64-appstream-eus-rpms ansible-2.9-for-rhel-8-x86_64-rpms rhceph-5-tools-for-rhel-8-x86_64-rpms 
do
cat >> /etc/yum.repos.d/local.repo << EOF
[$i]
name=$i
baseurl=http://${YUM_REPO_IP}/repos/rhcs5/$i/
enabled=1
gpgcheck=0

EOF
done
# 使用本地 repo
> /etc/yum.repos.d/local.repo 
for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-appstream-rpms ansible-2.9-for-rhel-8-x86_64-rpms rhceph-5-tools-for-rhel-8-x86_64-rpms 
do
cat >> /etc/yum.repos.d/local.repo << EOF
[$i]
name=$i
baseurl=file:///var/www/html/repos/rhcs5/$i/
enabled=1
gpgcheck=0

EOF
done


# 设置 /etc/hosts
sed -i '/jwang-ceph04.example.com/d' /etc/hosts
cat >> /etc/hosts <<EOF
10.66.208.125   jwang-ceph04.example.com    jwang-ceph04
EOF
cat >> /etc/hosts <<EOF
10.66.208.121   helper.example.com
EOF

# 更新系统
dnf makecache
dnf update -y

# 安装 cephadm
dnf install -y cephadm

# 安装 podman
dnf install -y podman

# 拷贝 local registry 证书
# 建立证书信任
[root@jwang-ceph04 ~]# scp 10.66.208.121:/opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors 
domain.crt                                                                                               100% 2114   688.3KB/s   00:00    
[root@jwang-ceph04 ~]# update-ca-trust extract
# 登陆 local registry
[root@jwang-ceph04 ~]# podman login helper.example.com:5000 
Username: 
Password: 
Login Succeeded!

# 不需要执行
# 禁用 container-tools:rhel8 module 启用 container-tools:2.0 模块
# sudo dnf module disable -y container-tools:rhel8
# sudo dnf module enable -y container-tools:2.0

# 更新系统
dnf update -y

# 禁用 subscription-manager 
# subscription-manager config --rhsm.auto_enable_yum_plugins=0
# https://access.redhat.com/solutions/5838131

# 生成 ssh keypair 
ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
ssh-copy-id 10.66.208.125 

# 使用本地镜像 
# 创建单节点集群
# https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/5/html-single/installation_guide/index#configuring-a-custom-registry-for-disconnected-installation_install
# https://docs.ceph.com/en/latest/cephadm/install/
# 创建时可以为 bootstrap 传递初始配置文件
cat <<EOF > initial-ceph.conf
[global]
osd_crush_choose_leaf_type = 0
EOF
cephadm --image helper.example.com:5000/rhceph/rhceph-5-rhel8:latest bootstrap --config ./initial-ceph.conf --mon-ip 10.66.208.125 --allow-fqdn-hostname
# 目前看这种方法并不生效
cephadm shell
[ceph: root@jwang-ceph04 /]# ceph config set global osd_crush_chooseleaf_type 0
[ceph: root@jwang-ceph04 /]# ceph config dump
...
global        dev       osd_crush_chooseleaf_type              0                                                                                                                      * 
...
[ceph: root@jwang-ceph04 /]# ceph config set global osd_pool_default_size 1
[ceph: root@jwang-ceph04 /]# ceph config set global osd_pool_default_min_size 1

# 设置别名
echo "alias ceph='cephadm shell -- ceph'" >> ~/.bashrc
source ~/.bashrc

# 为节点打标签 mon
ceph orch host ls
ceph orch host label add jwang-ceph04.example.com mon

# 设置时间同步
sed -i 's|pool 2.rhel.pool.ntp.org iburst|server clock.corp.redhat.com iburst|' /etc/chrony.conf
systemctl restart chronyd
chronyc -n sources

# 查看可用设备
ceph orch device ls --refresh

# 手工添加设备
ceph orch daemon add osd jwang-ceph04.example.com:/dev/sdb
ceph orch daemon add osd jwang-ceph04.example.com:/dev/sdc
ceph orch daemon add osd jwang-ceph04.example.com:/dev/sdd

# 告警，后续分析
WARNING: The same type, major and minor should not be used for multiple devices.
WARNING: The same type, major and minor should not be used for multiple devices.

[ceph: root@jwang-ceph04 /]# ceph health detail 
HEALTH_WARN 1 failed cephadm daemon(s); Reduced data availability: 1 pg inactive; Degraded data redundancy: 1 pg undersized
[WRN] CEPHADM_FAILED_DAEMON: 1 failed cephadm daemon(s)
    daemon node-exporter.jwang-ceph04 on jwang-ceph04.example.com is in error state
[WRN] PG_AVAILABILITY: Reduced data availability: 1 pg inactive
    pg 1.0 is stuck inactive for 5m, current state undersized+peered, last acting [1]
[WRN] PG_DEGRADED: Degraded data redundancy: 1 pg undersized
    pg 1.0 is stuck undersized for 5m, current state undersized+peered, last acting [1]

# 获取 pool 的信息
[ceph: root@jwang-ceph04 /]# ceph osd dump | grep pool 
pool 1 'device_health_metrics' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 1 pgp_num 1 autoscale_mode on last_change 22 flags hashpspool stripe_width 0 pg_num_min 1 application mgr_devicehealth
# 设置 pool 的 min_size
[ceph: root@jwang-ceph04 /]# ceph osd pool set device_health_metrics min_size 1 
set pool 1 min_size to 1

[ceph: root@jwang-ceph04 /]# ceph osd dump | grep pool 
pool 1 'device_health_metrics' replicated size 3 min_size 1 crush_rule 0 object_hash rjenkins pg_num 1 pgp_num 1 autoscale_mode on last_change 23 flags hashpspool stripe_width 0 pg_num_min 1 application mgr_devicehealth

# 检查 ceph 的 health 状态
[ceph: root@jwang-ceph04 /]# ceph health detail        
HEALTH_WARN 1 failed cephadm daemon(s)
[WRN] CEPHADM_FAILED_DAEMON: 1 failed cephadm daemon(s)
    daemon node-exporter.jwang-ceph04 on jwang-ceph04.example.com is in error state

# 为节点打标签 osd
ceph orch host label add jwang-ceph04.example.com osd

# 关于 failed cephadm daemon(s)
# 原因是在节点上的 node-exporter 无法启动
# 检查 node-exporter unit 文件内容
[root@jwang-ceph04 ~]# cat /var/lib/ceph/0c1839ae-5349-11ec-9989-001a4a16016f/node-exporter.jwang-ceph04/unit.run 
set -e
# node-exporter.jwang-ceph04
! /bin/podman rm -f ceph-0c1839ae-5349-11ec-9989-001a4a16016f-node-exporter.jwang-ceph04 2> /dev/null
! /bin/podman rm -f ceph-0c1839ae-5349-11ec-9989-001a4a16016f-node-exporter-jwang-ceph04 2> /dev/null
! /bin/podman rm -f --storage ceph-0c1839ae-5349-11ec-9989-001a4a16016f-node-exporter-jwang-ceph04 2> /dev/null
! /bin/podman rm -f --storage ceph-0c1839ae-5349-11ec-9989-001a4a16016f-node-exporter.jwang-ceph04 2> /dev/null
/bin/podman run --rm --ipc=host --net=host --init --name ceph-0c1839ae-5349-11ec-9989-001a4a16016f-node-exporter-jwang-ceph04 --user 65534 -d --log-driver journald --conmon-pidfile /run/ceph-0c1839ae-5349-11ec-9989-001a4a16016f@node-exporter.jwang-ceph04.service-pid --cidfile /run/ceph-0c1839ae-5349-11ec-9989-001a4a16016f@node-exporter.jwang-ceph04.service-cid -e CONTAINER_IMAGE=registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.6 -e NODE_NAME=jwang-ceph04.example.com -e CEPH_USE_RANDOM_NONCE=1 -e TCMALLOC_MAX_TOTAL_THREAD_CACHE_BYTES=134217728 -v /proc:/host/proc:ro -v /sys:/host/sys:ro -v /:/rootfs:ro registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.6 --no-collector.timex

# 解决方法是在对应节点上手工执行 podman pull 和 podman tag
[root@jwang-ceph04 ~]# podman pull helper.example.com:5000/openshift4/ose-prometheus-node-exporter:v4.6
[root@jwang-ceph04 ~]# podman tag helper.example.com:5000/openshift4/ose-prometheus-node-exporter:v4.6 registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.6

# 为节点打标签 mds
ceph orch host label add jwang-ceph04.example.com mds
# 看看 cephfs mds 服务
ceph fs volume create cephfs
ceph orch apply mds cephfs --placement="2 jwang-ceph04.example.com jwang-ceph04.example.com"

# rhcs5 purge/remove cluster
# https://bugzilla.redhat.com/show_bug.cgi?id=1881192

# ceph status
# insufficient standby MDS daemons available
# Degraded data redundancy: 30/56 objects degraded (53.571%), 14 pgs degraded, 65 pgs undersized
# fsid 是通过 ceph status 获取到的
#   cluster:
#   id:     0c1839ae-5349-11ec-9989-001a4a16016f
[root@jwang-ceph04 ~]# cephadm rm-cluster --fsid 0c1839ae-5349-11ec-9989-001a4a16016f --force

# 部署完的信息
Ceph Dashboard is now available at:

             URL: https://jwang-ceph04.example.com:8443/
            User: admin
        Password: rvg20bg7zv

You can access the Ceph CLI with:

        sudo /usr/sbin/cephadm shell --fsid 88946910-53f0-11ec-ab5a-001a4a16016f -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

Please consider enabling telemetry to help improve Ceph:

        ceph telemetry on

For more information see:

        https://docs.ceph.com/docs/pacific/mgr/telemetry/

# 通过改 crush 设置 single node cluster
# https://linoxide.com/hwto-configure-single-node-ceph-cluster/

# 清理节点上的 osd 磁盘 device mapper
# https://www.cnblogs.com/deny/p/14214963.html
# 查看磁盘
dmsetup ls

# 删除磁盘
dmsetup remove ceph--d534c556--1abd--4739--94c8--4c6fa8bfe12c-osd--block--65634030--05cd--4305--b08a--6bd8c43d8c76
rm -f /dev/mapper/ceph--d534c556--1abd--4739--94c8--4c6fa8bfe12c-osd--block--65634030--05cd--4305--b08a--6bd8c43d8c76

dmsetup remove ceph--55676940--281c--43fc--9b71--d359acecb778-osd--block--e0b08b95--d184--4dd8--9748--e495c5225caa
rm -f /dev/mapper/ceph--55676940--281c--43fc--9b71--d359acecb778-osd--block--e0b08b95--d184--4dd8--9748--e495c5225caa

dmsetup remove ceph--9cb74522--f080--4e25--a6fa--3b6b8a893444-osd--block--82b96e58--bb69--4492--a320--993a963890c6
rm -f /dev/mapper/ceph--9cb74522--f080--4e25--a6fa--3b6b8a893444-osd--block--82b96e58--bb69--4492--a320--993a963890c6

# 查看 device-mapper 设备
[root@jwang-ceph04 ~]# dmsetup ls
rhel_jwang--ceph04-home (253:2)
ceph--5c2ef1ac--2a33--42e7--bc7c--96aec8a2550b-osd--block--5ece89a4--cabb--4d7a--8b8b--c7baa75a1cb6     (253:3)
ceph--31c8737c--4ec0--49ea--b26b--e733989461c3-osd--block--fded4dd6--696e--43df--9247--8df0cd161ce5     (253:5)
rhel_jwang--ceph04-swap (253:1)
rhel_jwang--ceph04-root (253:0)
ceph--20632c65--91ac--4924--849b--f54e392a3999-osd--block--6be9216c--153d--4959--b818--498c1e1f79b4     (253:4)
# 移除 device-mapper 设备
[root@jwang-ceph04 ~]# mkdir -p /root/backup
[root@jwang-ceph04 ~]# mv /dev/dm-3 /root/backup/
[root@jwang-ceph04 ~]# mv /dev/dm-4 /root/backup/
[root@jwang-ceph04 ~]# mv /dev/dm-5 /root/backup/

# 报错
# WARNING: The same type, major and minor should not be used for multiple devices.
# https://tracker.ceph.com/issues/51668


[root@jwang-ceph04 ~]# ceph health detail 
Inferring fsid a31452c6-53f2-11ec-a115-001a4a16016f
Inferring config /var/lib/ceph/a31452c6-53f2-11ec-a115-001a4a16016f/mon.jwang-ceph04.example.com/config
Using recent ceph image helper.example.com:5000/rhceph/rhceph-5-rhel8@sha256:7f374a6e1e8af2781a19a37146883597e7a422160ee86219ce6a5117e05a1682
...
HEALTH_WARN 1 pool(s) have no replicas configured
[WRN] POOL_NO_REDUNDANCY: 1 pool(s) have no replicas configured
    pool 'device_health_metrics' has no replicas configured

HEALTH_WARN insufficient standby MDS daemons available
[WRN] MDS_INSUFFICIENT_STANDBY: insufficient standby MDS daemons available
    have 0; want 1 more

ceph fs ls
ceph mds stat
ceph fs status 
ceph health detail
# 部署 nfs ganesha daemon
# https://docs.ceph.com/en/pacific/cephadm/services/nfs/

# 生成 cephfs client authorize
ceph fs authorize cephfs client.cephfs.1 / rw
# 注意创建适合的 keyring 文件
ceph auth get client.cephfs.1 > /etc/ceph/keyring
mkdir /tmp/cephfs
# 安装 cephfs 客户端
yum install ceph-common
yum install ceph-fuse
# 通过 ceph-fuse 挂载 cephfs
ceph-fuse -n client.cephfs.1 -m jwang-ceph04:6789 --keyring=/etc/ceph/keyring /tmp/cephfs
# 通过 kernel client 挂载 cephfs
# 注意创建适合的 secret 文件
ceph auth get-key client.cephfs.1 > /etc/ceph/secret
# https://docs.ceph.com/en/latest/cephfs/mount-using-kernel-driver/#which-kernel-version
mount -t ceph 10.66.208.125:6789:/ /tmp/cephfs -o name=cephfs.1,secretfile=/etc/ceph/secret

# 部署 rgw 服务
ceph orch host label add jwang-ceph04.example.com rgw
ceph orch apply rgw default default --placement='1 jwang-ceph04.example.com'

# 创建证书
[root@jwang-ceph04 ~]# mkdir -p /opt/rgw/certs
[root@jwang-ceph04 ~]# cd /opt/rgw/certs
[root@jwang-ceph04 certs]# openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 3650 -out domain.crt  -addext "subjectAltName = DNS:jwang-ceph04.example.com" -subj "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT Department/CN=jwang-ceph04.example.com"
[root@jwang-ceph04 certs]# cp /opt/rgw/certs/domain.crt /etc/pki/ca-trust/source/anchors/
[root@jwang-ceph04 certs]# update-ca-trust extract
# 参考：https://greenstatic.dev/posts/2020/ssl-tls-rgw-ceph-config/
[root@jwang-ceph04 ~]# cephadm shell
[ceph: root@jwang-ceph04 /]# mkdir -p /opt/rgw/certs

# 回到主机，找到 cephadm shell 对应的 pod id
[root@jwang-ceph04 ~]# podman ps | grep ceph
...
5f9feddeb888  helper.example.com:5000/rhceph/rhceph-5-rhel8@sha256:7f374a6e1e8af2781a19a37146883597e7a422160ee86219ce6a5117e05a1682  -F -L STDERR -N N...  3 days ago     Up 3 days ago                 ceph-a31452c6-53f2-11ec-a115-001a4a16016f-nfs-nfs1-jwang-ceph04
eb37459b8812  helper.example.com:5000/rhceph/rhceph-5-rhel8@sha256:7f374a6e1e8af2781a19a37146883597e7a422160ee86219ce6a5117e05a1682                        3 minutes ago  Up 3 minutes ago              interesting_poincare
[root@jwang-ceph04 ~]# podman cp /opt/rgw/certs/. eb37459b8812:/opt/rgw/certs

# 回到 cephadm shell 容器
# https://greenstatic.dev/posts/2020/ssl-tls-rgw-ceph-config/
# https://lists.ceph.io/hyperkitty/list/ceph-users@ceph.io/thread/ATIT67EMNE6VBNESBJO4JCIVCJ7Y75Q4/
[ceph: root@jwang-ceph04 /]# ceph config-key set rgw/cert//default.crt -i /opt/rgw/certs/domain.crt
[ceph: root@jwang-ceph04 /]# ceph config-key set rgw/cert//default.key -i /opt/rgw/certs/domain.key
[ceph: root@jwang-ceph04 /]# ceph config dump | grep rgw_frontends
[ceph: root@jwang-ceph04 /]# ceph config set client.rgw.default.default rgw_frontends "beast port=80 ssl_port=443 ssl_certificate=config://rgw/cert//default.crt ssl_private_key=config://rgw/cert//default.key"
[ceph: root@jwang-ceph04 /]# ceph config set client.rgw.default.jwang-ceph04.gscijv rgw_frontends "beast port=80 ssl_port=443 ssl_certificate=config://rgw/cert//default.crt ssl_private_key=config://rgw/cert//default.key"
[ceph: root@jwang-ceph04 /]# ceph config dump | grep rgw_frontends

# 从 aws 客户端访问 rgw s3 服务
[root@jwang-ceph04 ~]# export AWS_CA_BUNDLE="/etc/pki/tls/certs/ca-bundle.crt"
[root@jwang-ceph04 ~]# aws --endpoint=https://jwang-ceph04.example.com:443 s3 ls
2021-12-06 13:50:00 test

# 添加 https 到防火墙
[root@jwang-ceph04 ~]# firewall-cmd --add-service=https --permanent
[root@jwang-ceph04 ~]# firewall-cmd --reload

# 查看 ceph config-key rgw/cert//default.crt 与 rgw/cert//default.key
[ceph: root@jwang-ceph04 /]# ceph config-key get rgw/cert//default.crt
[ceph: root@jwang-ceph04 /]# ceph config-key get rgw/cert//default.key
[ceph: root@jwang-ceph04 /]# ceph config get client.rgw.default.jwang-ceph04.gscijv.rgw_frontends 


# 回到 ceph 主机
# 查看 ceph 服务
[root@jwang-ceph04 ~]# ceph orch ls
# 重启 rgw.default
[root@jwang-ceph04 ~]# ceph orch restart rgw.default

# 下载镜像并且tag镜像
# 需要在每个节点上做一遍
[root@jwang-ceph04 rhcs5]# podman pull helper.example.com:5000/openshift4/ose-prometheus:v4.6
[root@jwang-ceph04 rhcs5]# podman tag helper.example.com:5000/openshift4/ose-prometheus:v4.6 registry.redhat.io/openshift4/ose-prometheus:v4.6
[root@jwang-ceph04 rhcs5]# podman pull helper.example.com:5000/openshift4/ose-prometheus-alertmanager:v4.6
[root@jwang-ceph04 rhcs5]# podman tag helper.example.com:5000/openshift4/ose-prometheus-alertmanager:v4.6 registry.redhat.io/openshift4/ose-prometheus-alertmanager:v4.6
[root@jwang-ceph04 rhcs5]# podman pull helper.example.com:5000/rhceph/rhceph-5-dashboard-rhel8:5 
[root@jwang-ceph04 rhcs5]# podman tag helper.example.com:5000/rhceph/rhceph-5-dashboard-rhel8:5 registry.redhat.io/rhceph/rhceph-5-dashboard-rhel8:5
[root@jwang-ceph04 rhcs5]# podman tag helper.example.com:5000/rhceph/rhceph-5-dashboard-rhel8:5 registry.redhat.io/rhceph/rhceph-5-dashboard-rhel8:latest

# 更改 ceph dashboard admin password
echo -n "p@ssw0rd" > password.txt
# ceph dashboard ac-user-create admin -i password.txt administrator
ceph dashboard ac-user-set-password admin -i password.txt 

# 把 ceph dashboard 和 rgw 集成起来
# https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/5/html-single/dashboard_guide/index#management-of-ceph-object-gateway-using-the-dashboard
radosgw-admin user create --uid=test_user --display-name=TEST_USER --system
radosgw-admin user info --uid test_user
echo -n $(radosgw-admin user info --uid test_user | grep access_key | awk '{print $2}' | sed -e 's|"||g' -e 's|,$||') > access_key
echo -n $(radosgw-admin user info --uid test_user | grep secret_key | awk '{print $2}' | sed -e 's|"||g' -e 's|,$||')  > secret_key
ceph dashboard set-rgw-api-access-key -i access_key
ceph dashboard set-rgw-api-secret-key -i secret_key
ceph dashboard set-rgw-api-host 10.66.208.125
ceph dashboard set-rgw-api-port 80

# 查看 ceph dashboard feature
ceph dashboard feature status

# 部署 nfs 服务
# https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/5/html-single/dashboard_guide/index#management-of-nfs-ganesha-exports-on-the-ceph-dashboard
[ceph: root@jwang-ceph04 /]# ceph osd pool create nfs_ganesha 32 32 
pool 'nfs_ganesha' created
[ceph: root@jwang-ceph04 /]# ceph osd dump | grep pool


ceph osd pool create nfs_ganesha
ceph osd pool application enable nfs_ganesha rgw
ceph orch apply nfs nfs1 --pool nfs_ganesha --namespace nfs-ns --placement="1 jwang-ceph04.example.com"
ceph dashboard set-ganesha-clusters-rados-pool-namespace nfs_ganesha/nfs1

[root@jwang-ceph04 ~]# ceph dashboard set-ganesha-clusters-rados-pool-namespace nfs_ganesha/nfs1
Option GANESHA_CLUSTERS_RADOS_POOL_NAMESPACE updated

# 配置 nfs export object gateway
# https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/5/html-single/dashboard_guide/index#management-of-nfs-ganesha-exports-on-the-ceph-dashboard
# https://docs.google.com/document/d/1DxS3oKsBvzgcYmnERfoIpULcJVmpPG0rIzMSgRgFL24/edit?usp=sharing

[ceph: root@jwang-ceph04 /]# ceph status
  cluster:
    id:     a31452c6-53f2-11ec-a115-001a4a16016f
    health: HEALTH_WARN
            insufficient standby MDS daemons available
 
  services:
    mon:     1 daemons, quorum jwang-ceph04.example.com (age 2d)
    mgr:     jwang-ceph04.example.com.myares(active, since 3d)
    mds:     1/1 daemons up
    osd:     3 osds: 3 up (since 2d), 3 in (since 2d)
    rgw:     1 daemon active (1 hosts, 1 zones)
    rgw-nfs: 1 daemon active (1 hosts, 1 zones)
 
  data:
    volumes: 1/1 healthy
    pools:   8 pools, 201 pgs
    objects: 253 objects, 7.9 KiB
    usage:   69 MiB used, 30 GiB / 30 GiB avail
    pgs:     201 active+clean
 
  io:
    client:   7.2 KiB/s rd, 170 B/s wr, 8 op/s rd, 2 op/s wr

# 安装 nfs 客户端
[root@jwang-ceph04 ~]# yum install -y nfs-utils 
[root@jwang-ceph04 ~]# mkdir -p /tmp/nfs
[root@jwang-ceph04 ~]# mount -t nfs 10.66.208.125:/test /tmp/nfs
[root@jwang-ceph04 ~]# mount | grep nfs
10.66.208.125:/ on /tmp/nfs type nfs4 (rw,relatime,vers=4.2,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.66.208.125,local_lock=none,addr=10.66.208.125)
[root@jwang-ceph04 ~]# cd /tmp/nfs

# podman exec -it <nfspod> bash
# 编辑 /etc/ganesha/ganesha.conf
# 把 Protocols 改为 3,4
# 添加 Bind_Addr 
NFS_CORE_PARAM {
        Enable_NLM = false;
        Enable_RQUOTA = false;
        Bind_Addr = 10.66.208.125;
        Protocols = 3,4;
}
# 退出 nfspod，重启 nfs 服务
systemctl restart ceph-a31452c6-53f2-11ec-a115-001a4a16016f@nfs.nfs1.jwang-ceph04.service
systemctl status ceph-a31452c6-53f2-11ec-a115-001a4a16016f@nfs.nfs1.jwang-ceph04.service

# 挂载 nfsver3 
# 为 firewall 添加 mountd port
# 每次重启 nfs ganesha mountd port 都会改变
[root@jwang-ceph04 ~]# rpcinfo -p 10.66.208.125 | grep -E " 3 " | grep -E "tcp"
    100000    3   tcp    111  portmapper
    100003    3   tcp   2049  nfs
    100005    3   tcp  38733  mountd
[root@jwang-ceph04 ~]# firewall-cmd 
firewall-cmd --add-port=38733/tcp --permanent
firewall-cmd --add-port=57897/tcp --permanent

# mountd 的 tcp 端口每次都改变如何处理
# https://www.ibm.com/support/pages/how-force-mountdlockd-use-specific-port

firewall-cmd --reload
mount -t nfs -o nfsvers=3,proto=tcp,noacl 10.66.208.125:/test /tmp/nfs 
mount -t nfs -vvvv 10.66.208.125:/test /tmp/nfs 
mount -t nfs -o nfsvers=3,proto=tcp -vvvv 10.66.208.125:/test /tmp/nfs 

# nfs-ganesha 日志
# https://documentation.suse.com/ses/7/html/ses-all/bp-troubleshooting-nfs.html
# 获取 fsid 
# [root@jwang-ceph04 ~]# cephadm ls | grep fsid 
# 获取 instance name
# [root@jwang-ceph04 ~]# cephadm ls | grep name 
[root@jwang-ceph04 ~]# cephadm logs --fsid a31452c6-53f2-11ec-a115-001a4a16016f --name nfs.nfs1.jwang-ceph04 

# 登陆 nfs pod
# 修改 /etc/ganesha/ganesha.conf 
LOG {   
        COMPONENTS {
                ALL=FULL_DEBUG;
        }
}
# 重启 nfs ganesha 服务 

# 报错
mount.nfs: access denied by server while mounting 10.66.208.125:/test
# 社区文档 radosgw + nfs ganesha
# https://docs.ceph.com/en/latest/radosgw/nfs/

cephadm shell
# %url    rados://nfs_ganesha/nfs-ns/conf-nfs.nfs1
# rados -p nfs_ganesha -N nfs-ns get conf-nfs.nfs1 -
# %url "rados://nfs_ganesha/nfs-ns/export-1"
# rados -p nfs_ganesha -N nfs-ns get export-1 -
[ceph: root@jwang-ceph04 /]# rados -p nfs_ganesha -N nfs-ns get export-1 -
EXPORT {
    export_id = 1;
    path = "test";
    pseudo = "/test";
    access_type = "RW";
    squash = "no_root_squash";
    protocols = 4;
    transports = "TCP";
    FSAL {
        name = "RGW";
        user_id = "test_user";
        access_key_id = "JKT0TCBHNQPAZ8BGH9SP";
        secret_access_key = "aBm3DNOwicyhgy9EBNTWLISQBvZeJgNA5ArUTp1K";
    }

}
# 更新这个对象, protocols 为 3,4
[ceph: root@jwang-ceph04 /]# cat > export-1 <<EOF
EXPORT {
    export_id = 1;
    path = "test";
    pseudo = "/test";
    access_type = "RW";
    squash = "no_root_squash";
    protocols = 3,4;
    transports = "TCP";
    FSAL {
        name = "RGW";
        user_id = "test_user";
        access_key_id = "JKT0TCBHNQPAZ8BGH9SP";
        secret_access_key = "aBm3DNOwicyhgy9EBNTWLISQBvZeJgNA5ArUTp1K";
    }

}
EOF
[ceph: root@jwang-ceph04 /]# rados -p nfs_ganesha -N nfs-ns put export-1 export-1
# 检查更新
[ceph: root@jwang-ceph04 /]# rados -p nfs_ganesha -N nfs-ns get export-1 -

# 重启 nfs ganesha
[root@jwang-ceph04 ~]# systemctl restart ceph-a31452c6-53f2-11ec-a115-001a4a16016f@nfs.nfs1.jwang-ceph04.service 
# 添加 nfs version3 防火墙规则
firewall-cmd --add-service={nfs3,mountd,rpc-bind} --permanent 
firewall-cmd --reload

# 报错
[root@jwang-ceph04 ~]# mount -t nfs -o nfsvers=3 10.66.208.125:/test /tmp/nfs
...
mount.nfs: access denied by server while mounting 10.66.208.125:/test

# rpcinfo 显示 nfs vers 3 是存在的
[root@jwang-ceph04 ~]# rpcinfo -p 10.66.208.125 | grep " 3 " 
    100000    3   tcp    111  portmapper
    100000    3   udp    111  portmapper
    100003    3   udp   2049  nfs
    100003    3   tcp   2049  nfs
    100005    3   udp  59743  mountd
    100005    3   tcp  35325  mountd

# 报错
mnt_Mnt :NFS3 :INFO :MOUNT: Export entry / does not support NFS v3
# http://lists.ceph.com/pipermail/ceph-users-ceph.com/2018-June/027675.html
# https://access.redhat.com/documentation/zh-cn/red_hat_ceph_storage/3/html/object_gateway_guide_for_ubuntu/exporting-the-namespace-to-nfs-ganesha-rgw
# 登陆 nfs pod
# 修改 /etc/ganesha/ganesha.conf 
# 在 NFS_CORE_PARAM 里添加 mount_path_pseudo
NFS_CORE_PARAM {
        Enable_NLM = false;
        Enable_RQUOTA = false;
        Bind_Addr = 10.66.208.125;
        Protocols = 3,4;
        mount_path_pseudo = true;
}
# 重启 nfs ganesha 服务
# 这次可以用 nfsvers=3 加载 nfs ganesha 共享了
mount -t nfs -o nfsvers=3,proto=tcp -vvvv 10.66.208.125:/test /tmp/nfs 

# 报错
overlayfs: unrecognized mount option "volatile" or missing value
touch: setting times of 'a': No such file or directory

# 用 s3 上传文件后
# nfs 加载可以拷贝文件并且创建文件了

# 根据 ceph orch ls 的输出调整 mon 和 mgr 的 placement
ceph orch ls
ceph orch apply mon --placement="1 jwang-ceph04.example.com"
ceph orch apply mgr --placement="1 jwang-ceph04.example.com"

# 设置 ceph fs 需要的 standby mds 的数量
ceph fs ls
ceph fs set cephfs standby_count_wanted 0
# 尝试在 single node 上起两个 mds 实例，上面的命令生效了，无需执行
# ceph orch apply mds cephfs --placement="2 jwang-ceph04.example.com jwang-ceph04.example.com"

# Window 10 nfs 文件
# https://blog.csdn.net/qq_34158598/article/details/81976063
# https://kenvix.com/post/win10-mount-nfs/
# https://blog.csdn.net/a603423130/article/details/100139226
# https://jermsmit.com/mount-nfs-share-in-windows-10/
# Win_R: OptionalFeatures 
# 以下命令在 Window 10 Education 版上无需执行
# Dism /online /Get-Features
# Dism /online /Enable-Feature:NFS-Administration
# https://blog.csdn.net/liuqun69/article/details/82457617
# https://cloud.tencent.com/developer/article/1840455
# 重启 nfs client
# nfsadmin client stop
# nfsadmin client start
# https://docs.datafabric.hpe.com/62/AdministratorGuide/MountingNFSonWindowsClient.html
# ERROR: Unsupported Windows Version
# https://graspingtech.com/mount-nfs-share-windows-10/
# https://github.com/nfs-ganesha/nfs-ganesha/issues/281
# 为了让 windows nfs client 工作，需要先用 linux 客户端使用 nfs v3 mount 加载 nfs export
# 08/12/2021 03:55:57 : epoch 61b02c72 : jwang-ceph04.example.com : ganesha.nfsd-6[reaper] rados_cluster_end_grace :CLIENT ID :EVENT :Failed to remove rec-0000000000000007:nfs.nfs1.jwang-ceph04: -2
# 08/12/2021 03:55:57 : epoch 61b02c72 : jwang-ceph04.example.com : ganesha.nfsd-6[reaper] nfs_lift_grace_locked :STATE :EVENT :NFS Server Now NOT IN GRACE
# 尝试用 nfs-win
# https://github.com/billziss-gh/nfs-win
net use x: "\\nfs\test=0.0@10.66.208.125\test"
# 尝试用 fuse-nfs +  dokany
# https://github.com/Daniel-Abrecht/fuse-nfs-crossbuild-scripts/
# https://github.com/dokan-dev/dokany
# fuse-nfs.exec -D -n nfs://10.66.208.121/srv/nfs4 -m 'X:'
# Dokan Error: DokanMount Failed
# Ioctl failed with waif for code 995
# 经过测试，支持命令是
# fuse-nfs.exec -D -n nfs://10.66.208.121/srv/nfs4 -m X
# 加载 nfs-ganesha pseudo path mount
# https://github.com/sahlberg/fuse-nfs
# fuse-nfs.exec -D -u 0 -g 0 -r -n nfs://10.66.208.125/test?version=4 -m P

# 为了兼容 fuse-nfs.exe 的 libnfs version=4
# 登陆 nfs pod
# 修改 /etc/ganesha/ganesha.conf 
# 在 NFSv4 Minor_Versions 里 0
NFSv4 { 
        Delegations = false;
        RecoveryBackend = 'rados_cluster';
        Minor_Versions = 0, 1, 2;
}
# 重启 nfs pod
# 测试的情况是 fuse-nfs.exe 不稳定
# https://blog.csdn.net/qq_25675517/article/details/112339045
# NFSClient 是 ms-nfs41-client
# https://cloud.tencent.com/developer/article/1605657
# NFSClient 使用 v4.1 协议目前看效果还行

cephadm shell
[ceph: root@jwang-ceph04 /]# ceph mgr module enable nfs
[ceph: root@jwang-ceph04 /]# ceph nfs cluster info nfs1 
{
    "nfs1": [
        {
            "hostname": "jwang-ceph04.example.com",
            "ip": "10.66.208.125",
            "port": 2049
        }
    ]
}

# 日志报错
# Dec 09 09:39:26 jwang-ceph04.example.com conmon[1848901]: level=error ts=2021-12-09T01:39:26.452Z caller=dispatch.go:309 component=dispatcher msg="Notify for alerts failed" num_alerts=1 err="ceph-dashboard/webhook[0]: notify retry canceled after 7 attempts: Post \"https://10.66.208.125:8443/api/prometheus_receiver\": x509: cannot validate certificate for 10.66.208.125 because it doesn't contain any IP SANs"
# https://github.com/prometheus/prometheus/issues/1654

# systemctl -l | grep prom
# alert manager 的配置文件也在 /var/lib/ceph/a31452c6-53f2-11ec-a115-001a4a16016f/ 下
# /var/lib/ceph/a31452c6-53f2-11ec-a115-001a4a16016f/alertmanager.jwang-ceph04/etc/alertmanager/alertmanager.yml
# 添加 http_config: tls_config: insecure_skip_verify: true
global:
  resolve_timeout: 5m
  http_config:
    tls_config:
      insecure_skip_verify: true
# 重启 alertmanager service

[root@jwang-ceph04 ~]# systemctl status ceph-a31452c6-53f2-11ec-a115-001a4a16016f@prometheus.jwang-ceph04.service 
 ceph-a31452c6-53f2-11ec-a115-001a4a16016f@prometheus.jwang-ceph04.service - Ceph prometheus.jwang-ceph04 for a31452c6-53f2-11ec-a115-001>
   Loaded: loaded (/etc/systemd/system/ceph-a31452c6-53f2-11ec-a115-001a4a16016f@.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2021-12-09 10:33:57 CST; 3h 29min ago
  Process: 2411084 ExecStopPost=/bin/rm -f //run/ceph-a31452c6-53f2-11ec-a115-001a4a16016f@prometheus.jwang-ceph04.service-pid //run/ceph->
  Process: 2411083 ExecStopPost=/bin/bash /var/lib/ceph/a31452c6-53f2-11ec-a115-001a4a16016f/prometheus.jwang-ceph04/unit.poststop (code=e>
  Process: 2410974 ExecStop=/bin/bash -c /bin/podman stop ceph-a31452c6-53f2-11ec-a115-001a4a16016f-prometheus.jwang-ceph04 ; bash /var/li>
  Process: 2411088 ExecStart=/bin/bash /var/lib/ceph/a31452c6-53f2-11ec-a115-001a4a16016f/prometheus.jwang-ceph04/unit.run (code=exited, s>
  Process: 2411086 ExecStartPre=/bin/rm -f //run/ceph-a31452c6-53f2-11ec-a115-001a4a16016f@prometheus.jwang-ceph04.service-pid //run/ceph->
 Main PID: 2411209 (conmon)



# 设置 dashboard set-prometheus-api-ssl-verify 
# https://docs.ceph.com/en/latest/api/mon_command_api/
ceph dashboard set-prometheus-api-ssl-verify false
ceph orch rm prometheus
ceph orch apply prometheus

# 设置防火墙
# https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/5/html/configuration_guide/ceph-network-configuration
# Mon
[root@jwang-ceph04 ~]# firewall-cmd --zone=public --add-port=6789/tcp --permanent
[root@jwang-ceph04 ~]# firewall-cmd --zone=public --add-port=3300/tcp --permanent
# OSDs and MDS
[root@jwang-ceph04 ~]# firewall-cmd --zone=public --add-port=6800-6830/tcp --permanent
[root@jwang-ceph04 ~]# firewall-cmd --reload


```

### Windows 11 and KVM
https://getlabsdone.com/how-to-install-windows-11-on-kvm/<br>
https://blogs.ovirt.org/wp-content/uploads/2021/09/05-TPM-support-in-oVirt-Milan-Zamazal-Tomas-Golembiovsky.pdf<br>

### 用 openssl s_client 命令检查站点是否支持 TLSv1 和 SSLv3 
```
# 出于安全的考量 TLSv1 和 SSLv3 应该关闭
# echo|openssl s_client -connect xx.xxx.xx.xx:8443 -ssl3 2>/dev/null|grep -e 'Secure Renegotiation IS' -e 'Cipher is ' -e 'Protocol :'
New, TLSv1/SSLv3, Cipher is ECDHE-RSA-AES256-SHA
Secure Renegotiation IS supported
 Protocol : SSLv3
# echo|openssl s_client -connect xx.xxx.xx.xx:8443 -tls1 2>/dev/null|grep -e 'Secure Renegotiation IS' -e 'Cipher is ' -e 'Protocol :'
New, TLSv1/SSLv3, Cipher is ECDHE-RSA-AES256-SHA
Secure Renegotiation IS supported
 Protocol : TLSv1
```

### 手工生成 kubeconfig 的方法
```
# log in on the web console and select youruser > get login command
# authenticate with your user/password and click “display token”, copy the API URL and token values from there.
### replace dots with dashes on the FQDN of your API host in the following commands, EXCEPT when it is an actual URL (argument to --server)
### replace apihostfqdn, port, youruser, project, and tokenfromwebconsole with values that match your cluster

### kubectl does not require that you use those long and redundant keys, not requires that the key of a context matches the name of the project and so on, but this is how oc commands set the kubeconfig file so if you follow its conventions you should be able to switch from kubectl to oc and vice-versa if you need.
$ kubectl config set-cluster apihostfqdn:port --server=https://apihostfqdn:port
$ kubectl config set-credentials youruser/apihostfqdn:port --token=tokenfromwebconsole
$ kubectl config set-context project/apihostfqdn:port/youruser --cluster=apihostfqdn:port --user=youruser/apihostfqdn:port --namespace=project
$ kubectl config use-context project/apihostfqdn:port:6443/youruser
```

### CentOS 在 UEFI 部署下兼容 BIOS 启动的步骤
```
# yum -y install grub2-pc
# grub2-mkconfig -o /boot/grub2/grub.cfg
# grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
# grub2-install --force --target=i386-pc /dev/vda

# in order to change the boot from UEFI to BIOS, you would also need to make sure that the boot loader 
# is installed to the master boot record (on MBR systems) or create a BIOS boot partition (on GPT systems).
```

### CentOS 8 上的 nfsd 默认启用 v3, v4, v4.1 和 v4.2
https://linuxize.com/post/how-to-install-and-configure-an-nfs-server-on-centos-8/
```
sudo dnf install nfs-utils
sudo systemctl enable --now nfs-server

sudo mkdir -p /srv/nfs4/{backups,www}

cat > /etc/exports <<EOF
/srv/nfs4         *(rw,sync,no_subtree_check,no_root_squash)
EOF

# https://computingforgeeks.com/install-and-configure-nfs-server-on-centos-rhel/
sudo firewall-cmd --add-service=nfs --permanent
sudo firewall-cmd --add-service={nfs3,mountd,rpc-bind} --permanent 
sudo firewall-cmd --reload

# export nfs share on nfs server
sudo exportfs -r 

# check nfsd versions
sudo cat /proc/fs/nfsd/versions

# mount nfs with version 3
mkdir -p /tmp/nfs
mount -t nfs -o nfsvers=3 10.66.208.121:/srv/nfs4 /tmp/nfs
ls /tmp/nfs
touch /tmp/nfs/aaa
umount /tmp/nfs
```

### 一些关于 Edge 和 IoT 的链接
https://docs.microsoft.com/en-us/answers/questions/611375/installing-iot-edge-on-rhel-8.html<br>
https://mobyproject.org/<br>

### OSP 16.2 关于 virt:av module 的问题
https://bugzilla.redhat.com/show_bug.cgi?id=2027787#c4<br>
https://bugzilla.redhat.com/show_bug.cgi?id=2030377<br>

### Load Balancer 与 Kerberos
http://ssimo.org/blog/id_019.html

### 在 Windows 上配置 Acrylic DNS Proxy 实现通配符域名解析
https://mayakron.altervista.org/support/acrylic/Windows10Configuration.htm<br>
https://stackoverflow.com/questions/138162/wildcards-in-a-windows-hosts-file<br>

### Log4Shell 的缓解方法
https://access.redhat.com/security/cve/CVE-2021-44228<br>
https://access.redhat.com/solutions/6578421<br>
```
CVE-2021-44228

Mitigation
There are two possible mitigations for this flaw in versions from 2.10 to 2.14.1:
- Set the system property log4j2.formatMsgNoLookups to true, or
- Remove the JndiLookup class from the classpath. For example:

zip -q -d log4j-core-*.jar org/apache/logging/log4j/core/lookup/JndiLookup.class

On OpenShift 4 and in OpenShift Logging, the above mitigation can be applied by following this article: https://access.redhat.com/solutions/6578421
```

### WinSCP 与 S3
https://konsole.zendesk.com/hc/en-us/articles/360037885173-How-to-Access-Imports-Exports-on-S3-Using-WinSCP<br>
```
需要注意设置: 
Advanced -> Environment -> S3 -> URL style = Path
```

### Ceph使用系列之——Ceph RGW使用
https://www.codenong.com/cs106856875/

### ceph-dokan MOUNT CEPHFS ON WINDOWS
https://docs.ceph.com/en/latest/cephfs/ceph-dokan/
```
# 参考: https://docs.ceph.com/en/latest/cephfs/ceph-dokan/
# 参考: https://docs.ceph.com/en/latest/install/windows-install/
# 从以下网址下载：https://cloudbase.it/ceph-for-windows/
# Mount a Ceph cluster on Windows 10 using Ceph Dokan
# https://www.youtube.com/watch?v=MAPMO9Z7kbE
# https://cloudbase.it/ceph-on-windows-part-1/

# Windows 配置文件
C:/ProgrameData/ceph/ceph.conf

[global]
    log to stderr = true
    ; Uncomment the following to use Windows Event Log
    ; log to syslog = true
 
    run dir = C:/ProgramData/ceph/out
    crash dir = C:/ProgramData/ceph/out
 
    ; Use the following to change the cephfs client log level
    ; debug client = 2
[client]
    keyring = C:/ProgramData/ceph/keyring
    ; log file = C:/ProgramData/ceph/out/$name.$pid.log
    admin socket = C:/ProgramData/ceph/out/$name.$pid.asok
 
    ; client_permissions = true
    ; client_mount_uid = 1000
    ; client_mount_gid = 1000
[global]
    mon host = 10.66.208.125

# 创建文件 C:/ProgrameData/ceph/keyring
# 为文件添加合适的 keyring 内容
# ceph auth list
# 例如
cat > keyring <<'EOF'
[client.cephfs.1]
   key = AQCG6LZhcpH5GhAA2qal1ZACWGTJgiFsJlhjcw==
EOF
# 目前测试的情况是 client.admin 可以用 ceph-dokan.exe 挂载
# client.cephfs.1 不行

# 到 ceph-dokan.exe 所在的文件夹，挂载 cephfs 文件系统
e:\
cd "Program Files\Ceph\bin"
ceph-dokan.exe -l x

# 报错处理

```

### NetApp 加密
https://www.netapp.com/company/trust-center/security/encryption/
```
Encryption of data in transit - 传输中的数据
Encryption of data at rest - 存储上未使用的数据
Encryption of data in use - 正在使用中的数据
```

### Encrypting NFSv4 with TLS and STunnel
https://www.linuxjournal.com/content/encrypting-nfsv4-stunnel-tls

### radosgw encryption
https://docs.ceph.com/en/latest/radosgw/encryption/

### Ceph CSI encrypted pvc
https://github.com/ceph/ceph-csi/blob/devel/docs/design/proposals/encrypted-pvc.md

### NFS-RGW
https://docs.ceph.com/en/latest/radosgw/nfs/

### stunnel and OpenShift
http://cpitman.github.io/openshift/tcp/networking/2016/12/28/stunnel-and-openshift.html#.Ybfz-L1BxfV

### Ceph Mgr
https://zhuanlan.zhihu.com/p/52139003<br>
https://docs.ceph.com/en/pacific/mgr/index.html<br>
https://docs.ceph.com/en/latest/mgr/administrator/<br>

### ceph 报错信息分析
```
[root@jwang-ceph04 ~]# ceph health detail
HEALTH_WARN 96 pgs not scrubbed in time
[WRN] PG_NOT_SCRUBBED: 96 pgs not scrubbed in time
...
    pg 2.10 not scrubbed since 2021-12-03T07:00:48.798209+0000
    46 more pgs... 

https://tracker.ceph.com/issues/44959
ceph health detail | ag 'not deep-scrubbed since' | awk '{print $2}' | while read pg; do ceph pg deep-scrub $pg; done

ceph health detail | grep -E 'not scrubbed since' | awk '{print $2}' | while read pg; do echo ceph pg scrub $pg; done
ceph health detail | grep -E 'not scrubbed since' | awk '{print $2}' | while read pg; do ceph pg scrub $pg; done

# 测试重启 ceph mgr systemd 服务
systemctl stop ceph-a31452c6-53f2-11ec-a115-001a4a16016f@mgr.jwang-ceph04.example.com.myares.service
systemctl start ceph-a31452c6-53f2-11ec-a115-001a4a16016f@mgr.jwang-ceph04.example.com.myares.service
systemctl status ceph-a31452c6-53f2-11ec-a115-001a4a16016f@mgr.jwang-ceph04.example.com.myares.service

# 通过 orch module 重启 mgr
cephadm shell -- ceph orch restart mgr

# 报错 WARNING: The same type, major and minor should not be used for multiple devices.
# 这个报错是来自 podman 
# https://github.com/opencontainers/runtime-tools/issues/695
# https://tracker.ceph.com/issues/51668
# 参考本文移除 device-mapper 设备部分，可以消除这个告警
[root@jwang-ceph04 ceph]# ls -l /dev/dm*
brw-rw----. 1 root disk 253, 0 Dec  2 09:38 /dev/dm-0
brw-rw----. 1 root disk 253, 1 Dec  2 09:38 /dev/dm-1
brw-rw----. 1 root disk 253, 2 Dec  2 09:38 /dev/dm-2
brw-rw----. 1 root disk 253, 3 Dec  3 14:11 /dev/dm-3
brw-rw----. 1 root disk 253, 4 Dec  3 14:11 /dev/dm-4
brw-rw----. 1 root disk 253, 5 Dec  3 14:13 /dev/dm-5
[root@jwang-ceph04 ceph]# ls -l /dev/mapper/
total 0
brw-rw----. 1 ceph ceph 253,   4 Dec 14 15:11 ceph--20632c65--91ac--4924--849b--f54e392a3999-osd--block--6be9216c--153d--4959--b818--498c1e1f79b4
brw-rw----. 1 ceph ceph 253,   5 Dec 14 15:11 ceph--31c8737c--4ec0--49ea--b26b--e733989461c3-osd--block--fded4dd6--696e--43df--9247--8df0cd161ce5
brw-rw----. 1 ceph ceph 253,   4 Dec  3 08:07 ceph--55676940--281c--43fc--9b71--d359acecb778-osd--block--e0b08b95--d184--4dd8--9748--e495c5225caa
brw-rw----. 1 ceph ceph 253,   3 Dec 14 15:11 ceph--5c2ef1ac--2a33--42e7--bc7c--96aec8a2550b-osd--block--5ece89a4--cabb--4d7a--8b8b--c7baa75a1cb6
brw-rw----. 1 ceph ceph 253,   5 Dec  2 17:25 ceph--9cb74522--f080--4e25--a6fa--3b6b8a893444-osd--block--82b96e58--bb69--4492--a320--993a963890c6
brw-rw----. 1 ceph ceph 253,   3 Dec  2 17:25 ceph--d534c556--1abd--4739--94c8--4c6fa8bfe12c-osd--block--65634030--05cd--4305--b08a--6bd8c43d8c76


# 查看 cephadm shell - ceph-volume lvm list
cephadm shell -- ceph-volume lvm list
# 查看节点磁盘
cephadm shell -- ceph-volume inventory

# 获取 mgr 实例
ceph status 
# 查看 mgr osd_deep_scrub_interval 和 mon_warn_pg_not_deep_scrubbed_ratio 的设置
ceph config show-with-defaults mgr.jwang-ceph04.example.com.myares | egrep "osd_deep_scrub_interval|mon_warn_pg_not_deep_scrubbed_ratio"


```

### F5 SPK and ICNI
Service Proxy for Kubernetes<br>
https://clouddocs.f5.com/service-proxy/latest/spk-sp-deploy-openshift.html<br>
Intelligent CNI 2.0<br>
https://clouddocs.f5.com/service-proxy/latest/spk-sp-deploy-openshift.html<br>
https://clouddocs.f5.com/service-proxy/latest/spk-network-overview.html<br>

### collectd 相关
https://github.com/voxpupuli/puppet-collectd/tree/v12.2.0<br>
https://collectd.org/wiki/index.php/Table_of_Plugins<br>
仔细想想 collectd 并不是适合的日志转发组件

### Ceph and LUA Scripting
https://docs.ceph.com/en/latest/radosgw/lua-scripting/

### 设置 osd-max-backfills 和 osd-recovery-max-active 参数
```
podman exec <CEPH-MON> ceph tell 'osd.*' injectargs --osd-max-backfills=2 --osd-recovery-max-active=6
```

### 测试虚拟机
```
qemu-img create -f qcow2 -o preallocation=metadata /data/kvm/jwang-ocp-bHehlper.qcow2 120G 

# single node 
# 为单节点服务器定义 
# nameserver=192.168.122.1 ip=192.168.122.101::192.168.122.1:255.255.255.0:master-0.ocp4-1.example.com:ens3:none

# SNO 的文档
# https://github.com/cchen666/OpenShift-Labs/blob/main/Installation/Single-Node-Openshift.md
# libvirt 网络所提供的 dhcp 服务还是需要的，因为虚拟机默认通过 dhcp 获取 ip 地址
# 编辑 libvirt 网络
virsh net-edit default
...
  <dns>
    <host ip='192.168.122.101'>
      <hostname>api.ocp4-1.example.com</hostname>
    </host>
  </dns>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <host mac='52:54:00:1c:14:57' name='master-0.ocp4-1.example.com' ip='192.168.122.101'/>
    </dhcp>
  </ip>
  <dnsmasq:options>
    <!-- fix for the 5s timeout on DNS -->
    <!-- see https://www.math.tamu.edu/~comech/tools/linux-slow-dns-lookup/ -->
    <dnsmasq:option value="auth-server=ocp4-1.example.com,"/><!-- yes, there is a trailing coma -->
    <dnsmasq:option value="auth-zone=ocp4-1.example.com"/>
    <!-- Wildcard route -->
    <dnsmasq:option value="host-record=lb.ocp4-1.example.com,192.168.123.5"/>
    <dnsmasq:option value="cname=*.apps.ocp4-1.example.com,lb.ocp4-1.example.com"/>
  </dnsmasq:options>


# https://aboullaite.me/effectively-restarting-kvm-libvirt-network/
# https://fabianlee.org/2018/10/22/kvm-using-dnsmasq-for-libvirt-dns-resolution/

# https://serverfault.com/questions/1068551/wildcard-cname-record-specified-by-libvirts-dnsmasqoptions-namespace-doesnt-wo
# dnsmasq and libvirt
# /var/lib/libvirt/dnsmasq/default.conf
# host-record

host-record=lb.ocp4-1.example.com,192.168.122.101
host-record=api.ocp4-1.example.com,192.168.122.101
host-record=api-int.ocp4-1.example.com,192.168.122.101
host-record=master-0.ocp4-1.example.com,192.168.122.101
address=/ocp4-1.example.com/192.168.122.101
address=/apps.ocp4-1.example.com/192.168.122.101
cname=ocp4-1.example.com,lb.ocp4-1.example.com
cname=*.apps.ocp4-1.example.com,lb.ocp4-1.example.com
auth-zone=ocp4-1.example.com
auth-server=ocp4-1.example.com,*

/usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf 


local=/.ocp4-1.example.com/192.168.122.101
local=/.apps.ocp4-1.example.com/192.168.122.101
address=/console-openshift-console.apps.ocp4.terry.com/10.72.44.132
address=/oauth-openshift.apps.ocp4.terry.com/10.72.44.132
address=/bastion.ocp4.terry.com/10.72.44.127
address=/bootstrap.ocp4.terry.com/10.72.44.128
17:04 <yaoli> address=/master1.ocp4.terry.com/10.72.44.129
17:04 <yaoli> address=/master2.ocp4.terry.com/10.72.44.130
17:04 <yaoli> address=/master3.ocp4.terry.com/10.72.44.131
17:04 <yaoli> address=/etcd-0.ocp4.terry.com/10.72.44.129
17:04 <yaoli> address=/etcd-1.ocp4.terry.com/10.72.44.130
17:04 <yaoli> address=/etcd-2.ocp4.terry.com/10.72.44.131
17:04 <yaoli> address=/worker1.ocp4.terry.com/10.72.44.132
17:04 <yaoli> address=/worker2.ocp4.terry.com/10.72.44.133
17:04 <yaoli> address=/api.ocp4.terry.com/10.72.44.127
17:04 <yaoli> address=/api-int.ocp4.terry.com/10.72.44.127


cat > /etc/dnsmasq.conf <<EOF
domain-needed
resolv-file=/etc/resolv.conf.upstream
strict-order
address=/.ocp4-1.example.com/192.168.122.101
address=/.apps.ocp4-1.example.com/192.168.122.101
address=/lb.ocp4-1.example.com/192.168.122.101
address=/console-openshift-console.apps.ocp4-1.example.com/192.168.122.101
address=/oauth-openshift.apps.ocp4-1.example.com/192.168.122.101
address=/master-0.ocp4-1.example.com/192.168.122.101
address=/etcd-0.ocp4-1.example.com/192.168.122.101
address=/api.ocp4-1.example.com/192.168.122.101
address=/api-int.ocp4-1.example.com/192.168.122.101
address=/grafana-openshift-monitoring.apps.ocp4-1.example.com/192.168.122.101
address=/thanos-querier-openshift-monitoring.apps.ocp4-1.example.com/192.168.122.101
address=/prometheus-k8s-openshift-monitoring.apps.ocp4-1.example.com/192.168.122.101
address=/alertmanager-main-openshift-monitoring.apps.ocp4-1.example.com/192.168.122.101
address=/canary-openshift-ingress-canary.apps.ocp4-1.example.com/192.168.122.101
srv-host=_etcd-server-ssl._tcp.ocp4-1.example.com,etcd-0.ocp4-1.example.com,2380

no-hosts
bind-dynamic
EOF

cat > /etc/resolv.conf.upstream <<EOF
search ocp4-1.example.com
nameserver 10.64.63.6
EOF

cat > /etc/resolv.conf <<EOF
search ocp4-1.example.com
nameserver 127.0.0.1
EOF

systemctl restart dnsmasq
dnsmasq -q 
```

### Single Node OpenShift PoC
https://github.com/eranco74/bootstrap-in-place-poc<br>
https://cloud.redhat.com/blog/deploy-openshift-at-the-edge-with-single-node-openshift<br>
https://cloud.redhat.com/blog/using-the-openshift-assisted-installer-service-to-deploy-an-openshift-cluster-on-metal-and-vsphere<br>

### sshuttle for VPN
https://morning.work/page/2019-06/sshuttle.html<br>
https://linux.cn/article-11476-1.html<br>
```
安装 sshuttle
brew install sshuttle

转发
sshuttle --dns -r user@remotehost 192.168.122.0/0
sshuttle --dns -r root@10.66.208.240 192.168.122.12/32 -x 10.0.0.0/8 

openshift 报错
ingress                                    4.9.9     True        False         True       5h14m   The "default" ingress controller reports Degraded=True: DegradedConditions: One or more other status conditions indicate a degraded state: CanaryChecksSucceeding=False (CanaryChecksRepetitiveFailures: Canary route checks for the default ingress controller are failing)

https://issueexplorer.com/issue/openshift/okd/771

# Single Node OpenShift 设置使用静态 IP 地址
# need to set the value of bootstrapInPlace.installationDisk (in install-config.yaml) to use the value --copy-network <install disk>
# https://github.com/openshift/installer/blob/release-4.9/data/data/bootstrap/bootstrap-in-place/files/usr/local/bin/install-to-disk.sh.template#L19
# https://docs.openshift.com/container-platform/4.9/installing/installing_sno/install-sno-installing-sno.html#generating-the-discovery-iso-manually_install-sno-installing-sno-with-the-assisted-installer

# 手工生成使用静态IP地址的 SNO Discovery ISO
# 参考: https://docs.openshift.com/container-platform/4.9/installing/installing_sno/install-sno-installing-sno.html#generating-the-discovery-iso-manually_install-sno-installing-sno-with-the-assisted-installer


tar -xzf ${OCP_PATH}/ocp-installer/openshift-install-linux-${OCP_VER}.tar.gz -C /usr/local/sbin/

export CLUSTER_ID="ocp4-1"
export CLUSTER_PATH=/data/ocp-cluster/${CLUSTER_ID}
export IGN_PATH=${CLUSTER_PATH}/ignition
export SSH_KEY_PATH=${CLUSTER_PATH}/ssh-key
mkdir -p ${IGN_PATH}
mkdir -p ${SSH_KEY_PATH}

# 生成 CoreOS ssh key
ssh-keygen -t rsa -f ${SSH_KEY_PATH}/id_rsa -N '' 


# 生成 install-config.yaml

export PULL_SECRET_STR=$(cat ${PULL_SECRET_FILE}) 
echo ${PULL_SECRET_STR}

cat > ${IGN_PATH}/install-config.yaml <<EOF
apiVersion: v1
baseDomain: example.com
compute:
- name: worker
  replicas: 0
controlPlane:
  name: master
  replicas: 1
metadata:
  name: ${CLUSTER_ID}
networking:
  networkType: OVNKubernetes
  clusterNetworks:
  - cidr: 10.254.0.0/16
    hostPrefix: 24
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
BootstrapInPlace:
  InstallationDisk: --copy-network /dev/vda
pullSecret: '${PULL_SECRET_STR}'
sshKey: |
$( cat ${SSH_KEY_PATH}/id_rsa.pub | sed 's/^/  /g' )
EOF

mkdir -p ${CLUSTER_PATH}/sno
cd ${CLUSTER_PATH}
cp ${IGN_PATH}/install-config.yaml sno
openshift-install --dir=sno create single-node-ignition-config

alias coreos-installer='podman run --privileged --rm \
        -v /dev:/dev -v /run/udev:/run/udev -v $PWD:/data \
        -w /data quay.io/coreos/coreos-installer:release'

cp sno/bootstrap-in-place-for-live-iso.ign iso.ign

cp ${OCP_PATH}/rhcos/rhcos-${RHCOS_VER}-x86_64-live.x86_64.iso rhcos-live.x86_64.iso

coreos-installer iso ignition embed -fi iso.ign rhcos-live.x86_64.iso

# 等待安装完成
openshift-install --dir=sno wait-for install-complete

# 通过调用 Assisted Installer API 生成节点控制平面静态 IP 
# https://github.com/openshift/enhancements/blob/master/enhancements/rhcos/static-networking-enhancements.md
# https://access.redhat.com/solutions/6135171
# 按照这个步骤尝试为 assisted installer 部署的节点设置静态 IP 地址
cat > sno.yaml <<EOF
dns-resolver:
  config:
    server:
    - 192.168.122.1
interfaces:
- ipv4:
    address:
    - ip: 192.168.122.101
      prefix-length: 24
    dhcp: false
    enabled: true
  name: ens3
  state: up
  type: ethernet
routes:
  config:
  - destination: 0.0.0.0/0
    next-hop-address: 192.168.122.1
    next-hop-interface: eth0
    table-id: 254
EOF

ASSISTED_SERVICE_URL=https://api.openshift.com
CLUSTER_ID="07a16d7e-604c-4949-b4a7-901512140825"
NODE_SSH_KEY="..."
request_body=$(mktemp)

jq -n --arg SSH_KEY "$NODE_SSH_KEY" --arg NMSTATE_YAML1 "$(cat sno.yaml)" \
'{
  "ssh_public_key": $SSH_KEY,
  "image_type": "full-iso",
  "static_network_config": [
    {
      "network_yaml": $NMSTATE_YAML1,
      "mac_interface_map": [{"mac_address": "02:00:00:2c:23:a5", "logical_nic_name": "eth0"}, {"mac_address": "02:00:00:68:73:dc", "logical_nic_name": "eth1"}]
    }
  ]
}' >> $request_body

# 单节点 OpenShift 部署时，检查 SNO 的 DNS 可解析
# lb.ocp4-1.example.com
# api.ocp4-1.example.com
# api-int.ocp4-1.example.com
# 其他的域名目前尚不知道是否需要

# 环境里的 libvirt default network 的 dnsmasq 文件内容
# cat /var/lib/libvirt/dnsmasq/default.conf
##WARNING:  THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
##OVERWRITTEN AND LOST.  Changes to this configuration should be made using:
##    virsh net-edit default
## or other application using the libvirt API.
##
## dnsmasq conf file created by libvirt
strict-order
local=/.ocp4-1.example.com/192.168.122.101
local=/.apps.ocp4-1.example.com/192.168.122.101
pid-file=/var/run/libvirt/network/default.pid
except-interface=lo
bind-dynamic
interface=virbr0
dhcp-range=192.168.122.1,static
dhcp-no-override
dhcp-authoritative
dhcp-hostsfile=/var/lib/libvirt/dnsmasq/default.hostsfile
addn-hosts=/var/lib/libvirt/dnsmasq/default.addnhosts
host-record=lb.ocp4-1.example.com,192.168.122.101
host-record=master-0.ocp4-1.example.com,192.168.122.101
#cname=ocp4-1.example.com,lb.ocp4-1.example.com
#cname=*.apps.ocp4-1.example.com,lb.ocp4-1.example.com
auth-zone=ocp4-1.example.com
auth-server=ocp4-1.example.com,*
# 执行的启动命令是 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf

# virsh net-dumpxml default 的内容
<network>
  <name>default</name>
  <uuid>4eb93b42-faf0-43aa-913e-8a454d7c0a0d</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:4e:2e:84'/>
  <dns>
    <host ip='192.168.122.101'>
      <hostname>api.ocp4-1.example.com</hostname>
    </host>
  </dns>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <host mac='52:54:00:1c:14:57' name='master-0.ocp4-1.example.com' ip='192.168.122.101'/>
    </dhcp>
  </ip>
</network>

# openshift 4.9 sample operator
# https://docs.openshift.com/container-platform/4.9/openshift_images/configuring-samples-operator.html

# 为虚拟机做一个直接桥接物理网卡网桥的 dnsmasq.conf
# 其中 assisited installer 要求不能设置 ocp4-1.example.com 的通配 dns 解析
# 因此不能设置 address=/.ocp4-1.example.com/10.66.208.241

cat > /etc/dnsmasq.conf <<EOF
domain-needed
resolv-file=/etc/resolv.conf.upstream
strict-order
local=/.ocp4-1.example.com/10.66.208.241
address=/.apps.ocp4-1.example.com/10.66.208.241
address=/lb.ocp4-1.example.com/10.66.208.241
address=/console-openshift-console.apps.ocp4-1.example.com/10.66.208.241
address=/oauth-openshift.apps.ocp4-1.example.com/10.66.208.241
address=/master-0.ocp4-1.example.com/10.66.208.241
address=/etcd-0.ocp4-1.example.com/10.66.208.241
address=/api.ocp4-1.example.com/10.66.208.241
address=/api-int.ocp4-1.example.com/10.66.208.241
address=/grafana-openshift-monitoring.apps.ocp4-1.example.com/10.66.208.241
address=/thanos-querier-openshift-monitoring.apps.ocp4-1.example.com/10.66.208.241
address=/prometheus-k8s-openshift-monitoring.apps.ocp4-1.example.com/10.66.208.241
address=/alertmanager-main-openshift-monitoring.apps.ocp4-1.example.com/10.66.208.241
address=/canary-openshift-ingress-canary.apps.ocp4-1.example.com/10.66.208.241
srv-host=_etcd-server-ssl._tcp.ocp4-1.example.com,etcd-0.ocp4-1.example.com,2380

no-hosts
bind-dynamic
EOF

# 不知道为什么，dnsmasq 突然不工作了
cat > /etc/dnsmasq.conf <<EOF
domain-needed
resolv-file=/etc/resolv.conf.upstream
strict-order
address=/.ocp4-1.example.com/10.66.208.241
address=/.apps.ocp4-1.example.com/10.66.208.241
no-hosts
bind-dynamic
EOF

# brctl show 
bridge name bridge id           STP enabled     interfaces
br0         8000.782bcb199eba   no              em1
                                        vnet1
# ip a s dev br0 
6: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 78:2b:cb:19:9e:ba brd ff:ff:ff:ff:ff:ff
    inet 10.66.208.240/24 brd 10.66.208.255 scope global noprefixroute br0

# virsh dumpxml jwang-ocp452-master0 | grep interface -B5 -A5 
...
    <interface type='bridge'>
      <mac address='52:54:00:1c:14:57'/>
      <source bridge='br0'/>
      <target dev='vnet1'/>
      <model type='virtio'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>


# 创建 bridge 的命令
# 创建 bridge 类型的 conn br0
[root@undercloud #] nmcli con add type bridge con-name br0 ifname br0
# (可选) 根据实际情况设置 bridge.stp，有时可能因为 bridge.stp 设置导致网络通信不正常，⚠️：在 lab 环境不需要执行
[root@undercloud #] nmcli con mod br0 bridge.stp no

# 修改 vlan 类型的 conn ens4 设置 master 为 br0 （参考）
[root@undercloud #] nmcli con mod ens4 connection.master br0 connection.slave-type 'bridge'

[root@undercloud #] nmcli con mod br0 \
    connection.autoconnect 'yes' \
    connection.autoconnect-slaves 'yes' \
    ipv4.method 'manual' \
    ipv4.address '10.25.149.21/24' \
    ipv4.gateway '10.25.149.1' 

cat << EOF > /root/host-bridge.xml
<network>
  <name>br0</name>
  <forward mode="bridge"/>
  <bridge name="br0"/>
</network>
EOF

virsh net-define /root/host-bridge.xml
virsh net-start br0
virsh net-autostart --network br0
#virsh net-autostart --network default --disable
#virsh net-destroy default

# 报错
[root@base-pvg ocp4-cluster]# oc --kubeconfig /root/jwang/ocp4-cluster/kubeconfig get nodes
Unable to connect to the server: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kube-apiserver-lb-signer")
[root@base-pvg ocp4-cluster]# oc --kubeconfig /root/jwang/ocp4-cluster/kubeconfig login --loglevel=10 
The server uses a certificate signed by an unknown authority.
You can bypass the certificate check, but any data you send to the server could be intercepted by others.
Use insecure connections? (y/n): y

error: couldn't get https://api.ocp4-1.example.com:6443/.well-known/oauth-authorization-server: unexpected response status 404
[root@base-pvg ocp4-cluster]# oc --kubeconfig /root/jwang/ocp4-cluster/kubeconfig login --loglevel=10 

# 报错 
Error starting build: an image stream cannot be used as build output because the integrated container image registry is not configured
# https://access.redhat.com/solutions/3931871

# 测试
PROXY_URL="http://10.66.208.240:3128/"

export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export ftp_proxy="$PROXY_URL"
export no_proxy="127.0.0.1,localhost,.rhsacn.org"

# For curl
export HTTP_PROXY="$PROXY_URL"
export HTTPS_PROXY="$PROXY_URL"
export FTP_PROXY="$PROXY_URL"
export NO_PROXY="127.0.0.1,localhost,.rhsacn.org"
```

### OpenShift 4.2环境离线部署Operatorhub
下面这个不是原创，哎...<br>
https://blog.51cto.com/u_15127570/2712896<br>
https://docs.openshift.com/container-platform/4.7/operators/admin/olm-restricted-networks.html<br>
https://access.redhat.com/articles/4740011<br>
https://docs.openshift.com/container-platform/4.7/operators/understanding/olm-rh-catalogs.html#olm-rh-catalogs<br>
https://docs.openshift.com/container-platform/4.7/operators/operator_sdk/osdk-generating-csvs.html#olm-enabling-operator-for-restricted-network_osdk-generating-csvs<br>
https://docs.openshift.com/container-platform/4.7/cli_reference/opm-cli.html#opm-cli<br>
 
```
# 对于纯离线环境，首先需要修改 OperatorHub/cluster 对象，设置 /spec/disableAllDefaultSources 为 true
# Disable the sources for the default catalogs by adding disableAllDefaultSources: true to the OperatorHub object:
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

# 可选步骤:
# Pruning an index image 
# 修剪 index image
# 如果不想用默认的 source index image，而是只想使用原有的 source index image 的部分 operator
# 可以参考： https://docs.openshift.com/container-platform/4.7/operators/admin/olm-restricted-networks.html#olm-pruning-index-image_olm-restricted-networks
podman login registry.redhat.io
podman login <target_registry>

podman run -p50051:50051 -it registry.redhat.io/redhat/redhat-operator-index:v4.7
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > packages.out
# Inspect the packages.out file and identify which package names from this list you want to keep in your pruned index. For example:
# In the terminal session where you executed the podman run command, press Ctrl and C to stop the container process.

# 以下命令用 source index image - registry.redhat.io/redhat/redhat-operator-index:v4.7 
# 里选择 advanced-cluster-management,jaeger-product,quay-operator 这几个 index content
# 生成修剪后的 local index image
# 修剪后的 local index image 是 <target_registry>:<port>/<namespace>/redhat-operator-index:v4.7
opm index prune -f registry.redhat.io/redhat/redhat-operator-index:v4.7 -p advanced-cluster-management,jaeger-product,quay-operator [-i registry.redhat.io/openshift4/ose-operator-registry:v4.7] -t <target_registry>:<port>/<namespace>/redhat-operator-index:v4.7 

# 将修剪后的 local index image 推送到离线 registry 
podman push <target_registry>:<port>/<namespace>/redhat-operator-index:v4.7

# 根据 index image 
# Mirroring an Operator catalog

# 在 support.example.com 节点上
podman pull --authfile ${PULL_SECRET_FILE} registry.redhat.io/redhat/redhat-operator-index:v${OCP_MAJOR_VER}
podman pull --authfile ${PULL_SECRET_FILE} registry.redhat.io/redhat/certified-operator-index:v${OCP_MAJOR_VER}
podman pull --authfile ${PULL_SECRET_FILE} registry.redhat.io/redhat/community-operator-index:v${OCP_MAJOR_VER}
podman pull --authfile ${PULL_SECRET_FILE} registry.redhat.io/redhat/community-operator-index:v${OCP_MAJOR_VER}

```

### 更新 kubeadmin password
https://blog.andyserver.com/2021/07/rotating-the-openshift-kubeadmin-password/<br>
https://go.dev/play/<br>
```
Actual Password: BeFXW-cCUiE-LEzjW-p8yXz
Hashed Password: $2a$10$PJtmeqhl70nKFA6edvDvmOL675aiVxft33deqx6.P86NGGhl9LA0m
Data to Change in Secret: JDJhJDEwJFBKdG1lcWhsNzBuS0ZBNmVkdkR2bU9MNjc1YWlWeGZ0MzNkZXF4Ni5QODZOR0dobDlMQTBt
Program exited.

SECRET_DATA="JDJhJDEwJFBKdG1lcWhsNzBuS0ZBNmVkdkR2bU9MNjc1YWlWeGZ0MzNkZXF4Ni5QODZOR0dobDlMQTBt"
kubectl patch secret -n kube-system kubeadmin --type json -p '[{"op": "replace", "path": "/data/kubeadmin", "value": "${SECRET_DATA}"}]

# 恢复 system:admin 用户的 kubeconfig 
https://access.redhat.com/solutions/4679661
# bootstrap 虚拟机的 /var/opt/openshift/auth/kubeconfig 是 system:admin 用户的 kubeconfig

# 安装完 ocp4 后更新 ssh key 
https://access.redhat.com/solutions/3868301

# OCP4 如何为 KubeAPIServer 添加 feature-gates
https://access.redhat.com/solutions/5685971
oc edit kubeapiservers.operator.openshift.io cluster

# azure disconnected operator catalog
https://github.com/deewhyweb/azure-disconnected-operator-catalog

# 报错
JundeMacBook-Pro:docs junwang$ oc --loglevel=10 login https://api.cluster-d8x7p.d8x7p.sandbox580.opentlc.com:6443 -u user1 
I1222 15:45:32.302463   96181 request.go:1181] Response Body: {"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure","message":"configmaps 
\"motd\" is forbidden: User \"system:anonymous\" cannot get resource \"configmaps\" in API group \"\" in the namespace \"openshift\"","reason":"Forbidde
n","details":{"name":"motd","kind":"configmaps"},"code":403}    

oc adm release mirror -a ${PULL_SECRET_FILE} \
     --from=quay.io/openshift-release-dev/ocp-release:${OCP_VER}-x86_64 --to-dir=${OCP_PATH}/operator-image/mirror_${OCP_VER}

# https://www.its404.com/article/lwlfox/110442762

```


### ocp nfs 设置
```
## 存放本集群Registry数据的根目录
export OCP_CLUSTER_ID="ocp4-1"
export CLUSTER_PATH="/data/ocp-cluster/${OCP_CLUSTER_ID}"
export NFS_OCP_REGISTRY_PATH="/data/ocp-cluster/${OCP_CLUSTER_ID}/nfs/ocp-registry"
## 存放本集群用户数据的根目录
export NFS_USER_FILE_PATH="/data/ocp-cluster/${OCP_CLUSTER_ID}/nfs/userfile"
## 运行NFS Server的域名
export DOMAIN="example.com"
export NFS_DOMAIN=nfs.${DOMAIN}
## 在OCP上运行NFS Client的项目
export NFS_CLIENT_NAMESPACE="csi-nfs"
## NFS Client Image
export NFS_CLIENT_PROVISIONER_IMAGE="quay.io/external_storage/nfs-client-provisioner"  
export PROVISIONER_NAME="kubernetes-nfs"
export STORAGECLASS_NAME="sc-csi-nfs"
export OCP_REGISTRY_PVC_NAME="pvc-ocp-registry"
export OCP_REGISTRY_PV_NAME="pv-ocp-registry"


cat << EOF > ${CLUSTER_PATH}/rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa-nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cr-nfs-client-provisioner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: crb-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: sa-nfs-client-provisioner
    namespace: ${NFS_CLIENT_NAMESPACE}
roleRef:
  kind: ClusterRole
  name: cr-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: r-nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rb-nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
subjects:
  - kind: ServiceAccount
    name: sa-nfs-client-provisioner
    namespace: ${NFS_CLIENT_NAMESPACE}
roleRef:
  kind: Role
  name: r-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
EOF

# 8.3.4.2.4	创建deployment.yaml文件
cat << EOF > ${CLUSTER_PATH}/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  namespace: ${NFS_CLIENT_NAMESPACE}
  labels:
    app: nfs-client-provisioner
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: sa-nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: ${NFS_CLIENT_PROVISIONER_IMAGE}:latest
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: ${PROVISIONER_NAME}
            - name: NFS_SERVER
              value: ${NFS_DOMAIN}
            - name: NFS_PATH
              value: ${NFS_USER_FILE_PATH}
      volumes:
        - name: nfs-client-root
          nfs:
            server: ${NFS_DOMAIN}
            path: ${NFS_USER_FILE_PATH}
EOF

# 8.3.4.2.5	创建storageclass.yaml文件
cat << EOF > ${CLUSTER_PATH}/storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ${STORAGECLASS_NAME}
provisioner: ${PROVISIONER_NAME}
parameters:
  archiveOnDelete: "false"
EOF
```

### ironic inspector 检查交换机端口特性
https://docs.openstack.org/python-ironic-inspector-client/wallaby/reference/api/ironic_inspector_client.resource.html
```
(undercloud) [stack@undercloud ~]$ openstack baremetal introspection interface list LAB01PCRENK017
(undercloud) [stack@undercloud ~]$ openstack baremetal introspection interface show LAB01PCRENK017 ens11f0
switch_port_link_aggregation_enabled
switch_port_link_aggregation_id
switch_port_link_aggregation_support
```

### 关于 bash 里的字符串截取，替换，删除，条件赋值
https://www.cnblogs.com/xiaoshiwang/p/12401021.html
```
字符串按位置切片
${var:offset:length}
# offset：从第几个开始切
# length：切多长。可以是负数（从最右面开始切多长，注意负号和冒号之间必须有空格）。

字符串模式
模式：
*：代表0个或多个任意字符。
?：代表0个或1个任意字符。

字符串按模式切片（只能从行首或行尾开始切，不能切中间部分）
${var#pattern} ：功能：自左而右，查找var变量所存储的字符串中，第一次出现的pattern，删除pattern所匹配到的所有字符。 注意：匹配到的必须是从行首开始的，不能匹配中间某段。
${var##pattern} ：贪婪模式，匹配到不能再匹配到位置。
${var%pattern} ：功能：自右而左，查找var变量所存储的字符串中，第一次出现的pattern，删除pattern所匹配到的所有字符。 注意：匹配到的必须是从行尾开始的，不能匹配中间某段。
${var%%pattern} ：贪婪模式，匹配到不能再匹配到位置。

字符串替换
pattern是glob风格的
${var/pattern/substr} ：首次。查找var所表示的字符串中，第一次被pattern所匹配到的字符串，以substr替换之。
${var//pattern/substr} ：全部。查找var所表示的字符串中，所有能被pattern所匹配到的字符串，以substr替换之。
${var/#pattern/substr} ：行首。查找var所表示的字符串中，行首被pattern所匹配到的字符串，以substr替换之。
${var/%pattern/substr} ：行尾。查找var所表示的字符串中，行尾被pattern所匹配到的字符串，以substr替换之。

字符串删除
pattern是glob风格的
${var/pattern} ：删除首次。删除var表示的字符串中第一次被pattern匹配到的字符串。
${var//pattern} ：删除全部。删除var表示的字符串中所有被pattern匹配到的字符串。
${var/#pattern} ：删除行首。删除var表示的字符串中所有以pattern为行首匹配到的字符串。
${var/%pattern} ：删除行尾。删除var所表示的字符串中所有以pattern为行尾所匹配到的字符串。

字符大小写转换
${var^^} ：把var中的所有小写字母转换为大写。
${var,,} ：把var中的所有大写字母转换为小写。

变量赋值
${var:-VALUE}：如果变量var为空或者未设置，则返回VALUE；否则返回变量var的值。注意，变量var本身的值不会被修改。
${var:=VALUE}：如果变量var为空或者未设置，则返回VALUE，并将VALUE赋值给变量var；否则返回变量var的值
${var:+VALUE}：如果变量var为空或者未设置，那么不会返回任何值。否则则返回VALUE的值。注意，变量var本身的值不会被修改。
${var:?ERROR_INFO}：如果变量var为空或者未设置，则返回错误信息ERROR_INFO；否则返回变量var的值。
```

### 关于 bash 的 extglob
https://www.linuxjournal.com/content/bash-extended-globbing

### D 语言
https://dlang.org/

### Harvester HCI
https://harvesterhci.io/<br>
https://www.youtube.com/watch?v=wVBXkS1AgHg<br>

### AI 工具帮助用户
https://www.techradar.com/news/new-ai-tool-eliminates-a-common-nightmare-for-hard-drive-users

### Rancher Longhorn
https://github.com/longhorn/longhorn<br>

### Code Ready Container
https://www.linuxtechi.com/setup-single-node-openshift-cluster-rhel-8/

### Single Node OpenShift
https://www.itix.fr/blog/deploy-openshift-single-node-in-kvm/
```
为单节点 OpenShift 配置使用本地目录的 PV, StorageClass 
# 登陆 SNO 节点
# 创建 /srv/openshift/pv-{0..99} 目录
# 设置目录的访问模式 (777) 和 selinux context (svirt_sanbox_file_t)
ssh core@node.itix-dev.ocp.itix "sudo /bin/bash -c 'mkdir -p /srv/openshift/pv-{0..99} ; chmod -R 777 /srv/openshift ; chcon -R -t svirt_sandbox_file_t /srv/openshift'"

# 创建 PV 
for i in {0..99}; do
  oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-$i
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  hostPath:
    path: "/srv/openshift/pv-$i"
EOF
done

# 创建 StorageClass
oc create -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: manual
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF

# 创建为内部 image-registry 准备的 pvc 
oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-storage
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF

# 将 SNO 原来的 configs.imageregistry.operator.openshift.io/cluster 的 /spec/storge 删除
# 然后添加 
# spec:
#   storage:
#     pvc:
#       claim: "registry-storage"
oc patch configs.imageregistry.operator.openshift.io cluster --type=json --patch-file=/dev/fd/0 <<EOF
[{"op": "remove", "path": "/spec/storage" },{"op": "add", "path": "/spec/storage", "value": {"pvc":{"claim": "registry-storage"}}}]
EOF

# 将 configs.imageregistry.operator.openshift.io/cluster 的 spec.managemntState 设置为 Managed
# spec:
#   managementState: "Managed"
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch-file=/dev/fd/0 <<EOF
{"spec":{"managementState": "Managed"}}
EOF

配置 openshift-image-registry 使用
```

### dnsmasq 做 dns 服务器和 dhcp 服务器
https://www.yinxiang.com/everhub/note/89e026c1-c57b-433e-a5d6-78646ec7b6cd

### koji 架构
https://fedoraproject.org/wiki/Koji<br>
https://oepkgs.net/zh/<br>

### OpenShift Automated Release Team tooling
https://github.com/openshift/art-tools

### Yocto and OpenEmbedded
https://www.yoctoproject.org/<br>
https://github.com/openembedded<br>
https://blog.csdn.net/weixin_44410537/article/details/89741876<br>

### osp 启用 vif 的 multiqueue 
```
需要在 flavor 和 image 上设置 properties: vif_multiqueue_enabled
(overcloud) [stack@sne01vrhelu01 ~]$ openstack flavor show m1.dpdk2 -f yaml
[...]
disk: 100
name: m1.dpdk2
properties: hw:cpu_policy='dedicated', hw:cpu_thread_policy='isolate', hw:emulator_threads_policy='share',
  hw:mem_page_size='1GB', hw:vif_multiqueue_enabled='true'
ram: 4096
rxtx_factor: 1.0
vcpus: 2
```

### Why does fstrim fail on Red Hat Enterprise Linux VMs on VMware hypervisors?
https://access.redhat.com/solutions/773263
```
lsblk -s --output NAME,MAJ:MIN,DISC-ALN,DISC-GRAN,DISC-MAX,DISC-ZERO,MOUNTPOINT /dev/rhel/root

cat /sys/block/sdd/device/scsi_disk/3\:0\:0\:2/provisioning_mode 
```

### kickstart file
```
cat > jwang-ocp4-aHelper-ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=eth0 --hostname=support.example.com --bootproto=static --ip=192.168.122.12 --netmask=255.255.255.0 --gateway=192.168.122.1 --nameserver=192.168.122.1
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal
kexec-tools
tar
%end
EOF

# rhel 7.8
# ks=http://10.66.208.115/jwang-ocp4-aHelper-ks.cfg nameserver=192.168.122.1 ip=192.168.122.12::192.168.122.1:255.255.255.0:support.example.com:eth0:none

```

### 下载 OCP 介质
```
export OCP_MAJOR_VER=4.9
export OCP_VER=4.9.9
export OCP_PATH=/data/OCP-${OCP_VER}/ocp
export YUM_PATH=/data/OCP-${OCP_VER}/yum

mkdir -p ${OCP_PATH}/{app-image,ocp-client,ocp-image,ocp-installer,rhcos,secret}  ${YUM_PATH}

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

export SUB_USER=XXXXX
export SUB_PASSWD=XXXXX

subscription-manager register --force --user ${SUB_USER} --password ${SUB_PASSWD}
subscription-manager refresh
LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8" subscription-manager list --available --matches 'Red Hat OpenShift Container Platform' | grep -E "Pool ID|System Type"

subscription-manager attach --pool=<ONE-POOL-ID>

subscription-manager repos --disable="*"
subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-${OCP_MAJOR_VER}-rpms" 

yum -y install yum-utils createrepo 
for repo in $(subscription-manager repos --list-enabled | grep "Repo ID" | awk '{print $3}'); do
    reposync --gpgcheck -lmn --repoid=${repo} --download_path=${YUM_PATH}
    createrepo -v ${YUM_PATH}/${repo} -o ${YUM_PATH}/${repo} 
done

du -lh ${YUM_PATH} --max-depth=1

cd ${YUM_PATH}
for dir in $(ls --indicator-style=none ${YUM_PATH}/); do
    tar -zcvf ${YUM_PATH}/${dir}.tar.gz ${dir}; 
done

rm -rf $(ls ${YUM_PATH} |egrep -v gz)
subscription-manager unregister

curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VER}/openshift-client-linux-${OCP_VER}.tar.gz -o ${OCP_PATH}/ocp-client/openshift-client-linux-${OCP_VER}.tar.gz
tar -xzf ${OCP_PATH}/ocp-client/openshift-client-linux-${OCP_VER}.tar.gz -C /usr/local/sbin/
oc version

export PULL_SECRET_FILE=${OCP_PATH}/secret/redhat-pull-secret.json

oc adm release info "quay.io/openshift-release-dev/ocp-release:${OCP_VER}-x86_64" 
oc adm release mirror -a ${PULL_SECRET_FILE} \
     --from=quay.io/openshift-release-dev/ocp-release:${OCP_VER}-x86_64 --to-dir=${OCP_PATH}/ocp-image/mirror_${OCP_VER}
oc adm release info ${OCP_VER} --dir=${OCP_PATH}/ocp-image/mirror_${OCP_VER}  
tar -zcvf ${OCP_PATH}/ocp-image/ocp-image-${OCP_VER}.tar -C ${OCP_PATH}/ocp-image ./mirror_${OCP_VER}
rm -rf ${OCP_PATH}/ocp-image/mirror_${OCP_VER}

RHCOS_VER=$(curl -s https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${OCP_MAJOR_VER}/latest/sha256sum.txt | grep x86_64-live.x86_64 | awk -F\- '{print $2}' | head -1)
echo ${RHCOS_VER}

curl -s https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${OCP_MAJOR_VER}/latest/sha256sum.txt | awk '{print $2}' | grep rhcos
curl -L https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${OCP_MAJOR_VER}/${RHCOS_VER}/rhcos-${RHCOS_VER}-x86_64-live.x86_64.iso -o ${OCP_PATH}/rhcos/rhcos-${RHCOS_VER}-x86_64-live.x86_64.iso
ll -h ${OCP_PATH}/rhcos

curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VER}/openshift-install-linux-${OCP_VER}.tar.gz -o ${OCP_PATH}/ocp-installer/openshift-install-linux-${OCP_VER}.tar.gz
ll -h ${OCP_PATH}/ocp-installer
tar -xzf ${OCP_PATH}/ocp-installer/openshift-install-linux-${OCP_VER}.tar.gz -C /usr/local/sbin/

上传介质
# 关于参数 --checksum
# https://serverfault.com/questions/211005/rsync-difference-between-checksum-and-ignore-times-options
rsync -r -v  --copy-links --checksum --stats --progress /data/OCP-4.9.9 10.66.208.240:/data

# 看了 rsync 的参数说明后，感觉应该用
rsync -a -v  --copy-links --checksum --stats --progress /data/OCP-4.9.9 10.66.208.240:/data

```


### Single Node OpenShift
https://github.com/eranco74/bootstrap-in-place-poc/blob/main/README.md<br>

### rhel 7 通过 rescue 恢复 root 口令
https://www.thegeekdiary.com/centos-rhel-7-reset-root-password/<br>
https://access.redhat.com/discussions/1243493<br>
```
# Reboot and edit grub2

# Append rd.break to kernel

# Reboot the system
# Press CTLR+x after appending the rd.break to the kernel. This will reboot the system into emergency mode.

# Remount sysroot
mount -o remount,rw /sysroot
chroot /sysroot

# Reset root password
passwd

# SElinux relabeling
touch /.autorelabel

# sync
sync

# Reboot
exit
exit

```

### 参考以下步骤，安装 single node openshift
https://github.com/wangjun1974/tips/blob/master/ocp/offline/4.6/0-prepare.md
```
# 4.6.3	配置Zone区域        
# 4.6.3.1	设置DNS环境变量
setVAR DOMAIN example.com
setVAR OCP_CLUSTER_ID ocp4-1
setVAR BASTION_IP 192.168.122.13
setVAR SUPPORT_IP 192.168.122.12
setVAR DNS_IP 192.168.122.12
setVAR NTP_IP 192.168.122.12
setVAR YUM_IP 192.168.122.12
setVAR NFS_IP 192.168.122.12
setVAR REGISTRY_IP 192.168.122.12
setVAR USIP 192.168.122.12
setVAR LB_IP 192.168.122.12  
setVAR BOOTSTRAP_IP 192.168.122.200
setVAR MASTER0_IP 192.168.122.201

# 4.6.3.2	添加解析Zone区域
# 执行以下命令添加3个解析ZONE（如果要执行多次，需要手动删除以前增加的内容），它们分别为：
# 域名后缀              解释
# example.com          集群内部域名后缀：集群内部所有节点的主机名均采用该域名后缀
# ocp4-1.example.com   OCP集群的域名，如本例中的集群名为ocp4-1，则域名为ocp4-1.example.com
# 168.192.in-addr.arpa 用于集群内所有节点的反向解析
cat >> /etc/named.rfc1912.zones << EOF

zone "${DOMAIN}" IN {
        type master;
        file "${DOMAIN}.zone";
        allow-transfer { any; };
};

zone "${OCP_CLUSTER_ID}.${DOMAIN}" IN {
        type master;
        file "${OCP_CLUSTER_ID}.${DOMAIN}.zone";
        allow-transfer { any; };
};

zone "168.192.in-addr.arpa" IN {
        type master;
        file "168.192.in-addr.arpa.zone";
        allow-transfer { any; };
};

EOF

# 4.6.3.3	创建example.com.zone区域配置文件
cat > /var/named/${DOMAIN}.zone << EOF
\$ORIGIN ${DOMAIN}.
\$TTL 1D
@           IN SOA  ${DOMAIN}. admin.${DOMAIN}. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum

@             IN NS                         dns.${DOMAIN}.

bastion       IN A                          ${BASTION_IP}
support       IN A                          ${SUPPORT_IP}
dns           IN A                          ${DNS_IP}
ntp           IN A                          ${NTP_IP}
yum           IN A                          ${YUM_IP}
registry      IN A                          ${REGISTRY_IP}
nfs           IN A                          ${NFS_IP}

EOF

# 4.6.3.4	创建ocp4-1.example.com.zone区域配置文件
cat > /var/named/${OCP_CLUSTER_ID}.${DOMAIN}.zone << EOF
\$ORIGIN ${OCP_CLUSTER_ID}.${DOMAIN}.
\$TTL 1D
@           IN SOA  ${OCP_CLUSTER_ID}.${DOMAIN}. admin.${OCP_CLUSTER_ID}.${DOMAIN}. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum

@             IN NS                         dns.${DOMAIN}.

lb             IN A                          ${LB_IP}

api            IN A                          ${LB_IP}
api-int        IN A                          ${LB_IP}
*.apps         IN A                          ${LB_IP}

bootstrap      IN A                          ${BOOTSTRAP_IP}

master-0       IN A                          ${MASTER0_IP}

etcd-0         IN A                          ${MASTER0_IP}

_etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN}. 8640 IN SRV 0 10 2380 etcd-0.${OCP_CLUSTER_ID}.${DOMAIN}.

EOF

# 4.6.3.5	创建168.192.in-addr.arpa.zone反向解析区域配置文件
# 注意：以下脚本中的反向IP如果有变化需要在此手动修改。
cat > /var/named/168.192.in-addr.arpa.zone << EOF
\$TTL 1D
@           IN SOA  ${DOMAIN}. admin.${DOMAIN}. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
                                        
@                              IN NS       dns.${DOMAIN}.

13.122.168.192.in-addr.arpa.     IN PTR      bastion.${DOMAIN}.

12.122.168.192.in-addr.arpa.     IN PTR      support.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      dns.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      ntp.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      yum.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      registry.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      nfs.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      lb.${OCP_CLUSTER_ID}.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      api.${OCP_CLUSTER_ID}.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      api-int.${OCP_CLUSTER_ID}.${DOMAIN}.

200.122.168.192.in-addr.arpa.    IN PTR      bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}.

201.122.168.192.in-addr.arpa.    IN PTR      master-0.${OCP_CLUSTER_ID}.${DOMAIN}.
EOF

# 4.6.4	重启BIND服务
# 重启BIND服务，然后检查没有错误日志。
systemctl restart named
rndc reload
journalctl -u named

# 4.6.5	将Support节点的DNS配置指向自己
nmcli c mod "$(nmcli --fields name con show |awk 'NR==2{print}' | sed -e 's, $,,g')" ipv4.dns "${DNS_IP}"
systemctl restart network
nmcli c show "$(nmcli --fields name con show |awk 'NR==2{print}' | sed -e 's, $,,g')" | grep ipv4.dns

# 4.6.6	测试正反向DNS解析
# 1.	正向解析测试
dig nfs.${DOMAIN} +short
dig support.${DOMAIN} +short 
dig yum.${DOMAIN} +short
dig registry.${DOMAIN} +short
dig ntp.${DOMAIN} +short
dig lb.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig api.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig api-int.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig *.apps.${OCP_CLUSTER_ID}.${DOMAIN} +short

dig bastion.${DOMAIN} +short

dig bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} +short

dig master-0.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig etcd-0.${OCP_CLUSTER_ID}.${DOMAIN} +short

dig _etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN} SRV +short

# 2.	反向解析测试
dig -x ${BASTION_IP} +short
dig -x ${SUPPORT_IP} +short
dig -x ${BOOTSTRAP_IP} +short
dig -x ${MASTER0_IP} +short

# 4.7	配置远程正式YUM源
# 4.7.1	配置Support节点的YUM源
# 1.	删除临时yum源
mv /etc/yum.repos.d/base.repo{,.bak}
# 2.	创建yum repo配置文件
setVAR YUM_DOMAIN yum.${DOMAIN}:8080
cat > /etc/yum.repos.d/ocp.repo << EOF
[rhel-7-server]
name=rhel-7-server
baseurl=http://${YUM_DOMAIN}/repo/rhel-7-server-rpms/
enabled=1
gpgcheck=0

[rhel-7-server-extras] 
name=rhel-7-server-extras
baseurl=http://${YUM_DOMAIN}/repo/rhel-7-server-extras-rpms/
enabled=1
gpgcheck=0

[rhel-7-server-ose] 
name=rhel-7-server-ose
baseurl=http://${YUM_DOMAIN}/repo/rhel-7-server-ose-${OCP_MAJOR_VER}-rpms/
enabled=1
gpgcheck=0 

EOF
yum repolist

# 4.7.2	安装基础软件包，验证YUM源
# 在Support节点安装以下软件包，验证YUM源是正常的。
yum -y install wget git net-tools bridge-utils jq tree httpd-tools 

# 4.8	部署NTP服务
# 注意：下文将Support节点当做OpenShift集群的NTP服务源。如果用户已经有NTP服务，可以忽略此节，并在安装OpenShift集群后将集群节点的时间服务指向已有的NTP服务。
# 4.8.1	设置正确的时区
timedatectl set-timezone Asia/Shanghai
timedatectl status | grep 'Time zone'
# 4.8.2	配置chrony服务
# 1.	RHEL 7.8最小化安装会安装chrony时间服务软件。我们先查看chrony服务状态：
systemctl status chronyd
yum install chrony
2.	备份原始chrony.conf配置文件，再修改配置文件
cp /etc/chrony.conf{,.bak}
sed -i -e "s/^server*/#&/g" \
       -e "s/#local stratum 10/local stratum 10/g" \
       -e "s/#allow 192.168.0.0\/16/allow all/g" \
       /etc/chrony.conf
cat >> /etc/chrony.conf << EOF
server ntp.${DOMAIN} iburst
EOF
# 3.	重启chrony服务
systemctl enable --now chronyd
systemctl restart chronyd
# 4.8.3	检查chrony服务端启动
ps -auxw |grep chrony
ss -lnup |grep chronyd
systemctl status chronyd
chronyc -n sources -v

# 4.9	部署本地Docker Registry
# 该Docker Registry镜像库用于提供OCP安装过程所需的容器镜像。
# 4.9.1	创建Docker Registry相关目录
## 容器镜像库存放的根目录
setVAR REGISTRY_PATH /data/registry
mkdir -p ${REGISTRY_PATH}/{auth,certs,data}

# 文档里的方法
openssl req -newkey rsa:4096 -nodes -sha256 -keyout ${REGISTRY_PATH}/certs/registry.key -x509 -days 3650 \
  -out ${REGISTRY_PATH}/certs/registry.crt \
  -subj "/C=CN/ST=BEIJING/L=BJ/O=REDHAT/OU=IT/CN=registry.${DOMAIN}/emailAddress=admin@${DOMAIN}"
openssl x509 -in ${REGISTRY_PATH}/certs/registry.crt -text | head -n 14

# 4.9.3	安装Docker Registry
# 1.	安装docker-distribution
yum -y install docker-distribution

# 2.	创建Registry认证凭据，允许用openshift/redhat登录。
htpasswd -bBc ${REGISTRY_PATH}/auth/htpasswd openshift redhat
cat ${REGISTRY_PATH}/auth/htpasswd

# 3.	创建docker-distribution配置文件
setVAR REGISTRY_DOMAIN registry.${DOMAIN}:5000                  ## 容器镜像库的访问域名

cat << EOF > /etc/docker-distribution/registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: ${REGISTRY_PATH}/data
    delete:
        enabled: false
auth:
  htpasswd:
    realm: basic-realm
    path: ${REGISTRY_PATH}/auth/htpasswd
http:
    addr: 0.0.0.0:5000
    host: https://${REGISTRY_DOMAIN}
    tls:
      certificate: ${REGISTRY_PATH}/certs/registry.crt
      key: ${REGISTRY_PATH}/certs/registry.key
EOF
cat /etc/docker-distribution/registry/config.yml

# 4.	启动Registry镜像库服务
systemctl enable docker-distribution --now
systemctl status docker-distribution

# 4.9.4	从本地访问Docker Registry 
# 将访问Registry的证书复制到RHEL系统的默认目录，然后更新到系统中。
cp ${REGISTRY_PATH}/certs/registry.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust
curl -u openshift:redhat https://${REGISTRY_DOMAIN}/v2/_catalog

# 4.9.6	导入OpenShift核心镜像到Docker Registry
# 4.9.6.1	设置基础环境变量
setVAR REGISTRY_REPO ocp4/openshift4       ## 在Docker Registry中存放OpenShift核心镜像的Repository
setVAR GODEBUG x509ignoreCN=0

# 4.9.6.2	安装镜像操作工具并登录Docker Registry
yum -y install podman skopeo 
# 用openshift/redhat登录Docker Registry，并将生成的免密登录信息追加到${PULL_SECRET_FILE文件。
setVAR PULL_SECRET_FILE ${OCP_PATH}/secret/redhat-pull-secret.json
cp ${OCP_PATH}/secret/redhat-pull-secret.json{,.bak}
podman login -u openshift -p redhat --authfile ${PULL_SECRET_FILE} ${REGISTRY_DOMAIN}
cat $PULL_SECRET_FILE | jq -c | tee $PULL_SECRET_FILE

# 4.9.6.3	向Docker Registry导入OpenShift核心镜像
tar -xvf ${OCP_PATH}/ocp-image/ocp-image-${OCP_VER}.tar -C ${OCP_PATH}/ocp-image/
rm -f ${OCP_PATH}/ocp-image/ocp-image-${OCP_VER}.tar

oc image mirror -a ${PULL_SECRET_FILE} \
     --dir=${OCP_PATH}/ocp-image/mirror_${OCP_VER} "file://openshift/release:${OCP_VER}*" ${REGISTRY_DOMAIN}/${REGISTRY_REPO}

# 查看已经导入镜像库镜像数量，然后查看镜像信息。
curl -u openshift:redhat https://${REGISTRY_DOMAIN}/v2/_catalog
curl -u openshift:redhat -s https://${REGISTRY_DOMAIN}/v2/${REGISTRY_REPO}/tags/list |jq -M '.["tags"][]' | wc -l
curl -u openshift:redhat -s https://${REGISTRY_DOMAIN}/v2/${REGISTRY_REPO}/tags/list |jq -M '.["name"] + ":" + .["tags"][]' 
oc adm release info -a ${PULL_SECRET_FILE} "${REGISTRY_DOMAIN}/${REGISTRY_REPO}:${OCP_VER}-x86_64" | grep -A 200 -i "Images" 

# 4.10	部署HAProxy负载均衡服务
# 1.	安装Haproxy
yum -y install haproxy
systemctl enable haproxy --now

# 2.	添加haproxy.cfg配置文件
cat <<EOF > /etc/haproxy/haproxy.cfg

# Global settings
#---------------------------------------------------------------------
global
    maxconn     20000
    log         /dev/log local0 info
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
#    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          300s
    timeout server          300s
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 20000

listen stats
    bind :9000
    mode http
    stats enable
    stats uri /

frontend  openshift-api-server-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:6443
    mode tcp
    option tcplog
    default_backend openshift-api-server-${OCP_CLUSTER_ID}

frontend  machine-config-server-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:22623
    mode tcp
    option tcplog
    default_backend machine-config-server-${OCP_CLUSTER_ID}

frontend  ingress-http-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:80
    mode tcp
    option tcplog
    default_backend ingress-http-${OCP_CLUSTER_ID}

frontend  ingress-https-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:443
    mode tcp
    option tcplog
    default_backend ingress-https-${OCP_CLUSTER_ID}

backend openshift-api-server-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     bootstrap bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check

backend machine-config-server-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     bootstrap bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check

backend ingress-http-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:80 check

backend ingress-https-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:443 check
EOF
cat /etc/haproxy/haproxy.cfg

# 3.	重启HAProxy服务, 然后检查HAProxy服务
systemctl restart haproxy
ss -lntp |grep haproxy

# 5	准备定制安装文件
# 5.1	准备Ignition引导文件
# 5.1.1	安装openshift-install
tar -xzf ${OCP_PATH}/ocp-installer/openshift-install-linux-${OCP_VER}.tar.gz -C /usr/local/sbin/
openshift-install version

# 5.1.2	准备install-config.yaml文件
# 5.1.2.1	设置环境变量
setVAR OCP_CLUSTER_ID "ocp4-1"
setVAR REPLICA_WORKER 0                                             ## 在安装阶段，将WORKER的数量设为0
setVAR REPLICA_MASTER 1                                             ## 本文档的OpenShift集群只有1个master节点
setVAR CLUSTER_PATH /data/ocp-cluster/${OCP_CLUSTER_ID}
setVAR IGN_PATH ${CLUSTER_PATH}/ignition                            ## 存放Ignition相关文件的目录

# 将文件调整为 1 行
cat ${PULL_SECRET_FILE} | jq -c | tee ${PULL_SECRET_FILE}
setVAR PULL_SECRET_STR "\$(cat \${PULL_SECRET_FILE})"               ## 在安装过程使用${PULL_SECRET_FILE}拉取镜像
setVAR SSH_KEY_PATH ${CLUSTER_PATH}/ssh-key                         ## 存放ssh-key相关文件的目录
setVAR SSH_PRI_FILE ${SSH_KEY_PATH}/id_rsa                          ## 节点之间访问的私钥文件名

# 5.1.2.2	创建CoreOS SSH访问密钥
# 该密钥用于登录OpenShift集群节点的CoreOS。
mkdir -p ${IGN_PATH}
mkdir -p ${SSH_KEY_PATH}
ssh-keygen -N '' -f ${SSH_KEY_PATH}/id_rsa
ll ${SSH_KEY_PATH}
setVAR SSH_PUB_STR "\$(cat ${SSH_KEY_PATH}/id_rsa.pub)"             ## 节点之间访问的公钥文件内容
echo ${SSH_PUB_STR}

# 5.1.2.3	创建无证书的install-config.yaml文件
cat << EOF > ${IGN_PATH}/install-config.yaml
apiVersion: v1
baseDomain: ${DOMAIN}
compute:
- hyperthreading: Enabled
  name: worker
  replicas: ${REPLICA_WORKER}
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: ${REPLICA_MASTER}
metadata:
  name: ${OCP_CLUSTER_ID}
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
fips: false
pullSecret: '${PULL_SECRET_STR}'
sshKey: '${SSH_PUB_STR}'
imageContentSources: 
- mirrors:
  - ${REGISTRY_DOMAIN}/${REGISTRY_REPO}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${REGISTRY_DOMAIN}/${REGISTRY_REPO}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

# 5.1.2.4	附加Docker Registry镜像库的证书到install-config.yaml文件
cp ${REGISTRY_PATH}/certs/registry.crt ${IGN_PATH}/
sed -i -e 's/^/  /' ${IGN_PATH}/registry.crt
echo "additionalTrustBundle: |" >> ${IGN_PATH}/install-config.yaml
cat ${IGN_PATH}/registry.crt >> ${IGN_PATH}/install-config.yaml

# 5.1.2.5	查看最终的install-config.yaml文件
# 重要说明：由于install-config.yaml中的安装证书有效期只有24小时，因此如果在生成该文件后24小时没有安装好OpenShift集群，需要重新操作生成install-config.yaml和其他所有安装前的准备步骤（所有以前生成的文件可以删除掉）。
cat ${IGN_PATH}/install-config.yaml

# 5.1.2.6	备份install-config.yaml文件
cp ${IGN_PATH}/install-config.yaml{,.`date +%Y%m%d%H%M`.bak}
ll ${IGN_PATH}

# 5.1.3	准备manifest文件
# 5.1.3.1	生成manifest文件
# OpenShift集群节点在启动后会根据manifest文件生成的Ignition设置各自的操作系统配置。
openshift-install create manifests --dir ${IGN_PATH}
tree ${IGN_PATH}/manifests/ ${IGN_PATH}/openshift/

# 5.1.3.2	修改master节点的调度策略
# 单节点集群无需修改
# 修改mastersSchedulable为false, 禁用master节点运行用户负载。
sed -i 's/mastersSchedulable: true/mastersSchedulable: false/g' ${IGN_PATH}/manifests/cluster-scheduler-02-config.yml
cat ${IGN_PATH}/manifests/cluster-scheduler-02-config.yml | grep mastersSchedulable

# 5.1.3.3	为所有节点创建时钟同步配置文件
setVAR NTP_CONF $(cat << EOF | base64 -w 0
server ntp.${DOMAIN} iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF)

echo ${NTP_CONF} | base64 -d

# 创建master节点的创建时钟同步配置文件。
cat << EOF > ${IGN_PATH}/openshift/99_masters-chrony-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: masters-chrony-configuration
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
          source: data:text/plain;charset=utf-8;base64,${NTP_CONF}
        mode: 420
        overwrite: true
        path: /etc/chrony.conf
  osImageURL: ""
EOF
cat ${IGN_PATH}/openshift/99_masters-chrony-configuration.yaml

# 创建worker节点的创建时钟同步配置文件。
# 单节点集群无需执行
cat << EOF > ${IGN_PATH}/openshift/99_workers-chrony-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: workers-chrony-configuration
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
          source: data:text/plain;charset=utf-8;base64,${NTP_CONF}
        mode: 420
        overwrite: true
        path: /etc/chrony.conf
  osImageURL: ""
EOF
more ${IGN_PATH}/openshift/99_workers-chrony-configuration.yaml

# 5.1.4	创建Ignition引导文件
openshift-install create ignition-configs --dir ${IGN_PATH}/
ll ${IGN_PATH}/*.ign
jq .ignition.config ${IGN_PATH}/master.ign 
jq .ignition.config ${IGN_PATH}/worker.ign 

# 5.2	准备节点自动设置文件
# 为了方面CoreOS节点首次启动后的设置操作，所有操作都放在节点自动设置文件中，只需下载该文件执行即可完成对应节点的所有配置。
setVAR GATEWAY_IP 192.168.122.1      ## CoreOS启动时使用的GATEWAY
setVAR NETMASK 24                  ## CoreOS启动时使用的NETMASK
setVAR CONNECT_NAME "Wired connection 1"    
# CoreOS的nmcli看到的connection名称，OCP4.6 是“Wired Connection”
# CoreOS的nmcli看到的connection名称，OCP4.8 是“Wired connection 1”
# CoreOS的nmcli看到的connection名称，OCP4.9 是“Wired connection 1”
# CoreOS的nmcli看到的connection名称，OCP4.9 如果启动时输入 ip= 参数是 "ens3"

creat_auto_config_file(){

cat << EOF > ${IGN_PATH}/set-${NODE_NAME}
nmcli connection modify "${CONNECT_NAME}" ipv4.addresses ${IP}/${NETMASK}
nmcli connection modify "${CONNECT_NAME}" ipv4.dns ${DNS_IP}
nmcli connection modify "${CONNECT_NAME}" ipv4.gateway ${GATEWAY_IP}
nmcli connection modify "${CONNECT_NAME}" ipv4.method manual
nmcli connection down "${CONNECT_NAME}"
nmcli connection up "${CONNECT_NAME}"

sudo coreos-installer install /dev/sda --insecure-ignition --ignition-url=http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/${NODE_TYPE}.ign --firstboot-args 'rd.neednet=1' --copy-network
EOF
}

#创建BOOTSTRAP启动定制文件
NODE_TYPE="bootstrap"
NODE_NAME="bootstrap"
IP=${BOOTSTRAP_IP}
creat_auto_config_file
cat ${IGN_PATH}/set-${NODE_NAME}

#创建master-0启动定制文件
NODE_TYPE="master"
NODE_NAME="master-0"
IP=${MASTER0_IP}
creat_auto_config_file

#创建master-1启动定制文件
NODE_TYPE="master"
NODE_NAME="master-1"
IP=${MASTER1_IP}
creat_auto_config_file

#创建master-2启动定制文件
NODE_TYPE="master"
NODE_NAME="master-2"
IP=${MASTER2_IP}
creat_auto_config_file

#创建worker-0启动定制文件
NODE_TYPE="worker"
NODE_NAME="worker-0"
IP=${WORKER0_IP}
creat_auto_config_file

#创建worker-1启动定制文件
NODE_TYPE="worker"
NODE_NAME="worker-1"
IP=${WORKER1_IP}
creat_auto_config_file

#创建worker-2启动定制文件
NODE_TYPE="worker"
NODE_NAME="worker-2"
IP=${WORKER2_IP}
creat_auto_config_file

ll ${IGN_PATH}/set-*

# 5.3	创建文件下载目录
# 为定制文件创建Apache HTTP上的可下载目录。
chmod -R 705 ${IGN_PATH}/
cat << EOF > /etc/httpd/conf.d/ignition.conf
Alias /${OCP_CLUSTER_ID} "${IGN_PATH}/../"
<Directory "${IGN_PATH}/../">
  Options +Indexes +FollowSymLinks
  Require all granted
</Directory>
<Location /${OCP_CLUSTER_ID}>
  SetHandler None
</Location>
EOF
systemctl restart httpd

# 确认所有安装所需文件可下载。
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/bootstrap.ign | jq 
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/worker.ign | jq
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/master.ign | jq
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-bootstrap
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-master-0
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-master-1
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-master-2
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-worker-0
curl http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/set-worker-1

# 6	创建Bootstrap、Master、Worker虚拟机节点
# 具体根据不同的IaaS环境和虚机节点配置要求创建bootstrap、master-0、master-1、master-2、worker-0、worker-1虚拟机节点，方法和过程略。需要注意以下事项：
# 1.	将硬盘的启动优先级设为最高，并将rhcos-4.9.0-x86_64-live.x86_64.iso作为所有虚机的启动盘。
# 2.	为虚拟机配置一个网卡，并使用网桥类型的网络。
# 3.	虚拟机操作系统类型选择RHEL 7或RHEL 8。

# 配置 ip 地址
sudo nmcli con mod 'Wired Connection 1' connection.autoconnect 'yes' ipv4.method 'manual' ipv4.address '192.168.122.200/24' ipv4.gateway '192.168.122.1' ipv4.dns '192.168.122.12'
sudo nmcli con down 'Wired Connection 1'
sudo nmcli con up 'Wired Connection 1'

# 使用命令检查网卡配置是否成功
ip a

# 在bootstrap节点中执行以下命令，先下载自动配置文件，然后执行它。注意：由于此节点当前还未完成配置，因此只能通过IP地址获取自动配置文件。
curl -O http://<SOPPORT-IP>:8080/<OCP_CLUSTER_ID>/ignition/set-bootstrap
source set-bootstrap
# 执行命令重启bootstrap节点。
reboot


# 7.1.2	查看bootstrap节点部署进程
# 1.	删除以前ssh保留的登录主机信息。
rm -rf ~/.ssh/known_hosts
# 2.	检查bootstrap节点的镜像库mirror配置是否按照install-config.yaml的内容进行配置
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "sudo cat /etc/containers/registries.conf"
# 3.	检查bootstrap节点是否能访问到Registry。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "curl -s -u openshift:redhat https://registry.${DOMAIN}:5000/v2/_catalog"
# 4.	检查bootstrap节点的本地pods。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "sudo crictl pods"
# 5.	访问如下地址http://lb.ocp4-1.example.internal:9000/，确认只有两处bootstrap节点变为绿色。
# 6.	确认可以通过curl命令查看machine config配置服务是否启动。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "curl -kIs https://api-int.${OCP_CLUSTER_ID}.${DOMAIN}:22623/config/master"

# 7.	可通过如下命令从宏观面观察部署过程。
openshift-install wait-for install-complete --log-level=debug --dir=${IGN_PATH}

# 8.	跟踪bootstrap的日志以识别安装进度，当循环出现如下红色字体提示的内容的时候，并且haproxy的web监控界面openshift-api-server和machine-config-server的bootstrap部分变为绿色时，说明bootstrap的引导服务已经启动，此时可进入下一个阶段。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "journalctl -b -f -u bootkube.service"

# 7.2	第二阶段：部署master阶段
# 7.2.1	两次启动
# 参照bootstrap的两次启动步骤启动所有master节点，将网络参数换成各自master的地址。
# 7.2.2	查看master节点部署进程
# 在support节点执行命令检查master节点的镜像库配置是否按照install-config.yaml的内容进行配置
ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "sudo cat /etc/containers/registries.conf"
# 检查是否能够正常访问registry
ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "curl -s -u openshift:redhat https://registry.${DOMAIN}:5000/v2/_catalog"
# 安装过程中可以通过查看如下日志来跟踪安装过程。注意以下日志的红色字体部分，这些内容指示master的不同安装阶段
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "journalctl -b -f -u bootkube.service"
# 出现上述最后两条红色字体后，说明bootstrap的任务已经完成，可以已经进入后续安装部署节点
# 另外，我们也可以通过如下方法了解安装进程：
tail -f ${IGN_PATH}/.openshift_install.log 
openshift-install wait-for bootstrap-complete --log-level debug --dir ${IGN_PATH}
# 现在我们可以关闭bootstrap节点，继续进行下一个阶段部署。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "sudo shutdown -h now"
# 在安装过程中，也可以通过以下方法查看master节点的日志 
# ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "journalctl -xef"

# 复制kubeconfig文件到用户缺省目录，以便可以用oc命令访问集群。
mkdir ~/.kube
cp ${IGN_PATH}/auth/kubeconfig ~/.kube/config

# 检查节点状态，确保master的STATUS均为Ready状态
oc get node

# 7.3	第三阶段：部署worker阶段
# 单节点集群不执行
# 7.3.1	两次启动
# 参照bootstrap的两次启动步骤启动所有worker节点，将网络参数换成各自worker的地址。
# 等待 worker machine-config-daemon-firstboot service 完成
ssh -i ${SSH_PRI_FILE} core@worker-1.${OCP_CLUSTER_ID}.${DOMAIN} "sudo journalctl -f -u machine-config-daemon-firstboot.service"

# 7.3.2	批准csr请求
# 通过如下命令查看 csr批准请求，第一批出现的是“kube-apiserver-client-kubelet”相关csr。
oc get csr | grep Pending
# 执行以下命令批准请求。
oc get csr | grep Pending | awk '{print $1}' | xargs oc adm certificate approve
# 再次执行命令查看 csr批准请求，第二批出现的是“kubelet-serving”相关csr。
oc get csr | grep Pending
# 执行以下命令批准请求。
oc get csr | grep Pending | awk '{print $1}' | xargs oc adm certificate approve

# 7.3.3	查看集群部署进展
# 执行以下命令来查看集群部署是否完成，整个过程需要一些时间。出现以下红色字体部分，说明集群已经部署完成。请记下kubeadmin和对应的登录密码。
oc get node
oc get clusteroperators
oc get clusterversion
tail -f ${IGN_PATH}/.openshift_install.log
openshift-install wait-for install-complete --log-level debug --dir ${IGN_PATH}

# 检查 kube-apiserver operator 日志
oc -n openshift-kube-apiserver-operator logs $(oc get pods -n openshift-kube-apiserver-operator -o jsonpath='{ .items[*].metadata.name }') -f

# 在单节点安装时，bootstrap 完成后
# 按照这个链接里的内容，进行了针对 single node 环境的 patch
# 目前尚不确认这些 patch 是否有必要
# https://docs.google.com/document/d/1bYSwibEPfg-hq1DW7Qn2En6maswiN9C8f85aW5uYgUw/edit
# 1. 设置 etcd-operator 支持在少于 3 个 master 节点的情况下启动 etcd cluster 
# Etcd patch - allow etcd-operator to start the etcd cluster without minimum of 3 master nodes
oc --kubeconfig ${IGN_PATH}/auth/kubeconfig patch etcd cluster -p='{"spec": {"unsupportedConfigOverrides": {"useUnsupportedUnsafeNonHANonProductionUnstableEtcd": true}}}' --type=merge

# 2. 设置 cluster-authentication-operator 在少于 3 个 master 节点的情况下部署 OAuthServer 
# Authentication patch -  allow cluster-authentication-operator to deploy OAuthServer without minimum of 3 master nodes
oc --kubeconfig ${IGN_PATH}/auth/kubeconfig patch authentications.operator.openshift.io cluster -p='{"spec": {"managementState": "Managed", "unsupportedConfigOverrides": {"useUnsupportedUnsafeNonHANonProductionUnstableOAuthServer": true}}}' --type=merge

# 3. 设置 1 个 ingress router pod
# 4.9.9 上无需执行
# Make sure to have a single ingress router pod:
oc patch --kubeconfig ${IGN_PATH}/auth/kubeconfig -n openshift-ingress-operator ingresscontroller/default --patch '{"spec":{"replicas": 1}}' --type=merge

# 4. 标记 openshift-etcd namespace 下的 etcd-quorum-guard deployment 为 unmanaged: true
# 4.9.9 上没有这个 deployment
oc --kubeconfig ${IGN_PATH}/auth/kubeconfig patch clusterversion/version --type='merge' -p "$(cat <<- EOF
 spec:
    overrides:
      - group: apps/v1
        kind: Deployment
        name: etcd-quorum-guard
        namespace: openshift-etcd
        unmanaged: true
EOF
)"

# 5. 这个命令在 4.9.9 上无需执行
# 4.9.9 上没有这个 deployment
oc --kubeconfig ${IGN_PATH}/auth/kubeconfig scale --replicas=1 deployment/etcd-quorum-guard -n openshift-etcd

# 6. 查看安装进度 clusterversion
oc --kubeconfig ${IGN_PATH}/auth/kubeconfig get clusterversion

[root@support ~]# oc --kubeconfig=/data/ocp-cluster/ocp4-1/get nodes
ignition/ ssh-key/  
[root@support ~]# oc --kubeconfig=/data/ocp-cluster/ocp4-1/ignition/auth/kubeconfig get clusterversion 
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.9.9     True        False         3m33s   Cluster version is 4.9.9

[root@support ~]# oc --kubeconfig=/data/ocp-cluster/ocp4-1/ignition/auth/kubeconfig get clusteroperators 
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
authentication                             4.9.9     True        False         False      6m9s    
baremetal                                  4.9.9     True        False         False      11m     
cloud-controller-manager                   4.9.9     True        False         False      18m     
cloud-credential                           4.9.9     True        False         False      67m     
cluster-autoscaler                         4.9.9     True        False         False      13m     
config-operator                            4.9.9     True        False         False      16m     
console                                    4.9.9     True        False         False      5m51s   
csi-snapshot-controller                    4.9.9     True        False         False      15m     
dns                                        4.9.9     True        False         False      11m     
etcd                                       4.9.9     True        False         False      13m     
image-registry                             4.9.9     True        False         False      10m     
ingress                                    4.9.9     True        False         False      9m13s   
insights                                   4.9.9     True        False         False      4m24s   
kube-apiserver                             4.9.9     True        False         False      10m     
kube-controller-manager                    4.9.9     True        False         False      13m     
kube-scheduler                             4.9.9     True        False         False      14m     
kube-storage-version-migrator              4.9.9     True        False         False      16m     
machine-api                                4.9.9     True        False         False      14m     
machine-approver                           4.9.9     True        False         False      14m     
machine-config                             4.9.9     True        False         False      14m     
marketplace                                4.9.9     True        False         False      14m     
monitoring                                 4.9.9     True        False         False      6m12s   
network                                    4.9.9     True        False         False      16m     
node-tuning                                4.9.9     True        False         False      14m     
openshift-apiserver                        4.9.9     True        False         False      6m42s   
openshift-controller-manager               4.9.9     True        False         False      9m9s    
openshift-samples                          4.9.9     True        False         False      10m     
operator-lifecycle-manager                 4.9.9     True        False         False      14m     
operator-lifecycle-manager-catalog         4.9.9     True        False         False      15m     
operator-lifecycle-manager-packageserver   4.9.9     True        False         False      12m     
service-ca                                 4.9.9     True        False         False      16m     
storage                                    4.9.9     True        False         False      16m     

[root@support ~]# oc --kubeconfig=/data/ocp-cluster/ocp4-1/ignition/auth/kubeconfig get node
NAME                          STATUS   ROLES           AGE   VERSION
master-0.ocp4-1.example.com   Ready    master,worker   22m   v1.22.3+4dd1b5a

# 参考以下链接里的步骤，设置 SNO 的存储
# https://www.itix.fr/blog/deploy-openshift-single-node-in-kvm/
# 登陆 SNO 节点
# 创建 /srv/openshift/pv-{0..99} 目录
# 设置目录的访问模式 (777) 和 selinux context (svirt_sanbox_file_t)
ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN}  "sudo /bin/bash -c 'mkdir -p /srv/openshift/pv-{0..99} ; chmod -R 777 /srv/openshift ; chcon -R -t svirt_sandbox_file_t /srv/openshift'"

# 创建 PV 
for i in {0..99}; do
  oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-$i
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  hostPath:
    path: "/srv/openshift/pv-$i"
EOF
done

# 创建 StorageClass
oc create -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: manual
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF

# 创建为内部 image-registry 准备的 pvc 
oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-storage
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF

# 将 SNO 原来的 configs.imageregistry.operator.openshift.io/cluster 的 /spec/storge 删除
# 然后添加 
# spec:
#   storage:
#     pvc:
#       claim: "registry-storage"
oc patch configs.imageregistry.operator.openshift.io cluster --type=json --patch-file=/dev/fd/0 <<EOF
[{"op": "remove", "path": "/spec/storage" },{"op": "add", "path": "/spec/storage", "value": {"pvc":{"claim": "registry-storage"}}}]
EOF

# 将 configs.imageregistry.operator.openshift.io/cluster 的 spec.managemntState 设置为 Managed
# spec:
#   managementState: "Managed"
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch-file=/dev/fd/0 <<EOF
{"spec":{"managementState": "Managed"}}
EOF

# 根据 https://github.com/eranco74/bootstrap-in-place-poc/blob/main/README.md
# 测试 SNO LiveCD 方法
git clone https://github.com/eranco74/bootstrap-in-place-poc
cd bootstrap-in-place-poc
mkdir sno-workdir

# 生成 install-config.yaml
# BootstrapInPlace - InstallationDisk
# https://github.com/openshift/installer/blob/release-4.9/data/data/bootstrap/bootstrap-in-place/files/usr/local/bin/install-to-disk.sh.template#L19
cat << EOF > sno-workdir/install-config.yaml
apiVersion: v1
baseDomain: ${DOMAIN}
compute:
- hyperthreading: Enabled
  name: worker
  replicas: ${REPLICA_WORKER}
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: ${REPLICA_MASTER}
metadata:
  name: ${OCP_CLUSTER_ID}
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
BootstrapInPlace:
  InstallationDisk: --copy-network /dev/vda  
fips: false
pullSecret: '${PULL_SECRET_STR}'
sshKey: '${SSH_PUB_STR}'
imageContentSources: 
- mirrors:
  - ${REGISTRY_DOMAIN}/${REGISTRY_REPO}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${REGISTRY_DOMAIN}/${REGISTRY_REPO}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

# 5.1.2.4	附加Docker Registry镜像库的证书到install-config.yaml文件
cp ${REGISTRY_PATH}/certs/registry.crt sno-workdir/
sed -i -e 's/^/  /' sno-workdir/registry.crt
echo "additionalTrustBundle: |" >> sno-workdir/install-config.yaml
cat sno-workdir/registry.crt >> sno-workdir/install-config.yaml

# 拷贝 base.iso
cp /data/OCP-4.9.9/ocp/rhcos/rhcos-4.9.0-x86_64-live.x86_64.iso sno-workdir/base.iso

# 准备 openshift-install 
# 之前已经解压缩过了

# 生成 Manifests
INSTALLATION_DISK=/dev/vda \
RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:4.9.9-x86_64 \
INSTALLER_BIN=/usr/local/sbin/openshift-install \
INSTALLER_WORKDIR=./sno-workdir \
./manifests.sh
cp ./manifests/*.yaml $INSTALLER_WORKDIR/manifests/

# 生成 Single-Node-Ignition-Config ignition 
INSTALLATION_DISK=/dev/vda \
RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:4.9.9-x86_64 \
INSTALLER_BIN=/usr/local/sbin/openshift-install \
INSTALLER_WORKDIR=./sno-workdir \
./generate.sh

# 生成 sno embeded livecd iso
ISO_PATH=./sno-workdir/base.iso \
IGNITION_PATH=./sno-workdir/bootstrap-in-place-for-live-iso.ign \
OUTPUT_PATH=./sno-workdir/embedded.iso \
./embed.sh

# 调整 dns 
# 4.6.3.4	创建ocp4-1.example.com.zone区域配置文件
cat > /var/named/${OCP_CLUSTER_ID}.${DOMAIN}.zone << EOF
\$ORIGIN ${OCP_CLUSTER_ID}.${DOMAIN}.
\$TTL 1D
@           IN SOA  ${OCP_CLUSTER_ID}.${DOMAIN}. admin.${OCP_CLUSTER_ID}.${DOMAIN}. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum

@             IN NS                         dns.${DOMAIN}.

lb             IN A                          ${LB_IP}

api            IN A                          ${LB_IP}
api-int        IN A                          ${LB_IP}
*.apps         IN A                          ${LB_IP}

bootstrap      IN A                          ${MASTER0_IP}

master-0       IN A                          ${MASTER0_IP}

etcd-0         IN A                          ${MASTER0_IP}

_etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN}. 8640 IN SRV 0 10 2380 etcd-0.${OCP_CLUSTER_ID}.${DOMAIN}.

EOF

# 4.6.3.5	创建168.192.in-addr.arpa.zone反向解析区域配置文件
# 注意：以下脚本中的反向IP如果有变化需要在此手动修改。
cat > /var/named/168.192.in-addr.arpa.zone << EOF
\$TTL 1D
@           IN SOA  ${DOMAIN}. admin.${DOMAIN}. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
                                        
@                              IN NS       dns.${DOMAIN}.

13.122.168.192.in-addr.arpa.     IN PTR      bastion.${DOMAIN}.

12.122.168.192.in-addr.arpa.     IN PTR      support.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      dns.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      ntp.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      yum.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      registry.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      nfs.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      lb.${OCP_CLUSTER_ID}.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      api.${OCP_CLUSTER_ID}.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      api-int.${OCP_CLUSTER_ID}.${DOMAIN}.

201.122.168.192.in-addr.arpa.    IN PTR      bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}.

201.122.168.192.in-addr.arpa.    IN PTR      master-0.${OCP_CLUSTER_ID}.${DOMAIN}.
EOF

# 4.6.4	重启BIND服务
# 重启BIND服务，然后检查没有错误日志。
systemctl restart named
rndc reload
journalctl -u named

# 2.	添加haproxy.cfg配置文件
cat <<EOF > /etc/haproxy/haproxy.cfg

# Global settings
#---------------------------------------------------------------------
global
    maxconn     20000
    log         /dev/log local0 info
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
#    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          300s
    timeout server          300s
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 20000

listen stats
    bind :9000
    mode http
    stats enable
    stats uri /

frontend  openshift-api-server-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:6443
    mode tcp
    option tcplog
    default_backend openshift-api-server-${OCP_CLUSTER_ID}

frontend  machine-config-server-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:22623
    mode tcp
    option tcplog
    default_backend machine-config-server-${OCP_CLUSTER_ID}

frontend  ingress-http-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:80
    mode tcp
    option tcplog
    default_backend ingress-http-${OCP_CLUSTER_ID}

frontend  ingress-https-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:443
    mode tcp
    option tcplog
    default_backend ingress-https-${OCP_CLUSTER_ID}

backend openshift-api-server-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check

backend machine-config-server-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check

backend ingress-http-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:80 check

backend ingress-https-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:443 check
EOF
cat /etc/haproxy/haproxy.cfg

# 3.	重启HAProxy服务, 然后检查HAProxy服务
systemctl restart haproxy
ss -lntp |grep haproxy

# 6	创建 SNO 虚拟机节点
# 具体根据不同的IaaS环境和虚机节点配置要求创建 master-0 虚拟机节点，方法和过程略。需要注意以下事项：
# 1.	将硬盘的启动优先级设为最高，并将 embedded.iso 作为虚机的启动盘。
# 2.	为虚拟机配置一个网卡，并使用网桥类型的网络。
# 3.	虚拟机操作系统类型选择RHEL 7或RHEL 8。
# 启动参数添加 nameserver=192.168.122.12 ip=192.168.122.201::192.168.122.1:255.255.255.0:master-0.ocp4-1.example.com:ens3:none

# 7.1.2	查看bootstrap节点部署进程
# 1.	删除以前ssh保留的登录主机信息。
rm -rf ~/.ssh/known_hosts
# 2.	检查bootstrap节点的镜像库mirror配置是否按照install-config.yaml的内容进行配置
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "sudo cat /etc/containers/registries.conf"
# 3.	检查bootstrap节点是否能访问到Registry。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "curl -s -u openshift:redhat https://registry.${DOMAIN}:5000/v2/_catalog"
# 4.	检查bootstrap节点的本地pods。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "sudo crictl pods"
# 5.	访问如下地址http://lb.ocp4-1.example.internal:9000/，确认只有两处bootstrap节点变为绿色。
# 6.	确认可以通过curl命令查看machine config配置服务是否启动。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "curl -kIs https://api-int.${OCP_CLUSTER_ID}.${DOMAIN}:22623/config/master"

# 7.	可通过如下命令从宏观面观察部署过程。
openshift-install wait-for install-complete --log-level=debug --dir=${IGN_PATH}

# 8.	跟踪bootstrap的日志以识别安装进度，当循环出现如下红色字体提示的内容的时候，并且haproxy的web监控界面openshift-api-server和machine-config-server的bootstrap部分变为绿色时，说明bootstrap的引导服务已经启动，此时可进入下一个阶段。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "journalctl -b -f -u bootkube.service"

# 7.2	第二阶段：部署master阶段
# 7.2.1	两次启动
# 参照bootstrap的两次启动步骤启动所有master节点，将网络参数换成各自master的地址。
# 7.2.2	查看master节点部署进程
# 在support节点执行命令检查master节点的镜像库配置是否按照install-config.yaml的内容进行配置
ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "sudo cat /etc/containers/registries.conf"
# 检查是否能够正常访问registry
ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "curl -s -u openshift:redhat https://registry.${DOMAIN}:5000/v2/_catalog"
# 安装过程中可以通过查看如下日志来跟踪安装过程。注意以下日志的红色字体部分，这些内容指示master的不同安装阶段
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "journalctl -b -f -u bootkube.service"
# 出现上述最后两条红色字体后，说明bootstrap的任务已经完成，可以已经进入后续安装部署节点
# 另外，我们也可以通过如下方法了解安装进程：
tail -f ${IGN_PATH}/.openshift_install.log 
openshift-install wait-for bootstrap-complete --log-level debug --dir ${IGN_PATH}
# 现在我们可以关闭bootstrap节点，继续进行下一个阶段部署。
ssh -i ${SSH_PRI_FILE} core@bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} "sudo shutdown -h now"
# 在安装过程中，也可以通过以下方法查看master节点的日志 
# ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "journalctl -xef"

```


### 报错
```
oc image mirror -a ${PULL_SECRET_FILE} --from-dir=${OCP_PATH}/ocp-image/mirror_${OCP_VER} "file://openshift/release:${OCP_VER}-x86_64*" ${REGISTRY_DOMAIN}/${REGISTRY_REPO} --loglevel=8
I1227 21:07:46.203600    3054 config.go:128] looking for config.json at /root/.docker/config.json
I1227 21:07:46.203840    3054 config.go:94] looking for .dockercfg at /root/.dockercfg
I1227 21:07:46.204818    3054 file.go:30] Repository https://registry-1.docker.io openshift/release
I1227 21:07:46.206264    3054 options.go:59] Search for "4.9.9*" (^4\.9\.9.*.*$) found: []
F1227 21:07:46.206452    3054 helpers.go:116] error: you must specify at least one source image to pull and the destination to push to as SRC=DST or SRC
 DST [DST2 DST3 ...]

oc adm release info 4.9.9 --dir=/data/OCP-4.9.9/ocp/ocp-image/mirror_4.9.9 | tee /tmp/oc-adm-release-info-4.9.9
oc adm release info 4.6.52 --dir=/data/OCP-4.6.52/ocp/ocp-image/mirror_4.6.52 | tee /tmp/oc-adm-release-info-4.6.52

# 怀疑是运行命令时 soft link 信息丢失了
#  rsync -r -v --stats --progress <srcdir> <dsthost>:<dstdir>
# 重新创建 soft link
oc adm release info 4.9.9 --dir=/data/OCP-4.9.9/ocp/ocp-image/mirror_4.9.9 |  grep sha256 | grep -Ev "Digest|Pull" | while read name digest ; do ln -sf $digest 4.9.9-x86_64-${name} ;  done  
oc adm release info 4.9.9 --dir=/data/OCP-4.9.9/ocp/ocp-image/mirror_4.9.9 |  grep sha256 | grep -E "Digest" | while read name digest ; do ln -sf $digest 4.9.9-x86_64 ;  done

[root@support ~]# ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "sudo crictl logs 12ca25c026f51"
I1228 06:01:25.974215       1 cmd.go:209] Using service-serving-cert provided certificates
I1228 06:01:25.984675       1 observer_polling.go:159] Starting file observer
W1228 06:01:31.388600       1 builder.go:220] unable to get owner reference (falling back to namespace): Get "https://172.30.0.1:443/api/v1/namespaces/o
penshift-kube-apiserver-operator/pods/kube-apiserver-operator-6b6548968f-wswls": dial tcp 172.30.0.1:443: connect: connection refused
I1228 06:01:31.406830       1 builder.go:252] kube-apiserver-operator version 4.9.0-202111151318.p0.g3a02848.assembly.stream-3a02848-3a02848339e2e10e452
2031c1deaec9a6d553063
F1228 06:02:41.111808       1 cmd.go:138] unable to load configmap based request-header-client-ca-file: the server was unable to return a response in the time allotted, but may still be processing the request (get configmaps extension-apiserver-authentication)

[root@support ~]# ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "sudo crictl ps -a | grep apiserver"

[root@support ocp-image]# openssl s_client -showcerts -verify 5 -connect api-int.ocp4-1.example.com:6443 < /dev/null 

[root@support ~]# ssh -i ${SSH_PRI_FILE} core@master-0.${OCP_CLUSTER_ID}.${DOMAIN} "sudo crictl logs e9e10fa4eb18f 2>&1 | head -20 " 
I1228 06:15:56.019683       1 cmd.go:209] Using service-serving-cert provided certificates
I1228 06:15:56.020236       1 observer_polling.go:74] Adding reactor for file "/var/run/secrets/serving-cert/tls.crt"
I1228 06:15:56.021123       1 observer_polling.go:74] Adding reactor for file "/var/run/secrets/serving-cert/tls.key"
I1228 06:15:56.021304       1 observer_polling.go:52] Starting from specified content for file "/var/run/configmaps/config/operator-config.yaml"
I1228 06:15:56.022353       1 observer_polling.go:159] Starting file observer
I1228 06:15:56.023317       1 observer_polling.go:135] File observer successfully synced
W1228 06:15:56.032629       1 builder.go:220] unable to get owner reference (falling back to namespace): Get "https://172.30.0.1:443/api/v1/namespaces/openshift-service-ca-operator/pods": dial tcp 172.30.0.1:443: connect: connection refused
I1228 06:15:56.032902       1 builder.go:252] service-ca-operator version v4.9.0-202111151318.p0.gab44f58.assembly.stream-0-gb8f3dc1-
I1228 06:15:56.034658       1 dynamic_serving_content.go:110] "Loaded a new cert/key pair" name="serving-cert::/var/run/secrets/serving-cert/tls.crt::/var/run/secrets/serving-cert/tls.key"
I1228 06:15:57.878571       1 server.go:50] Error initializing delegating authentication (will retry): <nil>
# https://bugzilla.redhat.com/show_bug.cgi?id=1933269

```

### ACM 相关
https://cloud.redhat.com/blog/using-the-openshift-assisted-installer-service-to-deploy-an-openshift-cluster-on-metal-and-vsphere<br>
https://github.com/openshift/assisted-service/blob/master/docs/user-guide/restful-api-guide.md#setting-static-network-config<br>
```
# 执行导入命令，
# 创建了
# open-cluster-management crd
# open-cluster-management-agent namespace
# klusterlet serviceaccount
# klusterlet clusterrole
# open-cluster-management:klusterlet-admin-aggregate-clusterrole clusterrole
# klusterlet clusterrolebinding
# bootstrap-hub-kubeconfig secret
# klusterlet deployment
# klusterlet klusterlet
customresourcedefinition.apiextensions.k8s.io/klusterlets.operator.open-cluster-management.io created
namespace/open-cluster-management-agent created
serviceaccount/klusterlet created
secret/bootstrap-hub-kubeconfig created
clusterrole.rbac.authorization.k8s.io/klusterlet created
clusterrole.rbac.authorization.k8s.io/open-cluster-management:klusterlet-admin-aggregate-clusterrole created
clusterrolebinding.rbac.authorization.k8s.io/klusterlet created
deployment.apps/klusterlet created
klusterlet.operator.open-cluster-management.io/klusterlet created
```

### Disk Image Builder 创建 whole disk image 
```
# Disk Image Builder 可以创建 partition image，也可以创建 whole disk image

# Disk Image Builder 创建 whole disk image 的命令
# 命令里的 vm 参数告诉 disk-image-builder 创建 whole disk image
# ToDo: 仔细看看 disk-image-builder 相关资料
# disk-image-create rhel grub2 vm block-dev-efi -o rhel-wholedisk
```

### 镜像仓库
Docker本地镜像发布到阿里云镜像仓库以及拉取操作<br>
http://www.lzhpo.com/article/35<br>

### 暴露 mqtt 服务
```
以下命令生成一个 NodePort Service，这个 Service 可以通过 Node:Port 访问 
oc expose service tb-mqtt-transport --type=NodePort --name=tb-mqtt-transport-ingress --generator="service/v2"
```

### openshift toolbox pod 的使用 
```
$ oc debug node/ip-10-0-159-84.us-east-2.compute.internal 
Starting pod/ip-10-0-159-84us-east-2computeinternal-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.0.159.84
If you don't see a command prompt, try p
sh-4.4# chroot /host
sh-4.4# toolbox
```
### 配置 NodePort 类型的服务
```
# 暴露 Node Port 类型的服务
oc expose service tb-mqtt-transport --type=NodePort --name=tb-route-mqtt-transport --generator="service/v2"
```

### 配置 LoadBalancer Type 的服务
https://docs.openshift.com/container-platform/4.6/networking/configuring_ingress_cluster_traffic/configuring-ingress-cluster-traffic-load-balancer.html
```
创建 Type 为 LoadBalancer 的 Service
cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: tb-mqtt-ingress-lb 
spec:
  ports:
  - name: mqtt
    port: 1883 
  loadBalancerIP:
  type: LoadBalancer 
  selector:
    app: tb-mqtt-transport
EOF | oc apply -f -

yum install nmap-ncat -y

echo -en "\x10\x0d\x00\x04MQTT\x04\x00\x00\x00\x00\x01a" | nc -v a72bc4fdef91d467ba706a541fdc925f-1741428165.us-east-2.elb.amaznaws.com 1883

echo -en "\x10\x0d\x00\x04MQTT\x04\x00\x00\x00\x00\x01a" | nc -v 72.52.10.14 1883

$ nc -v a72bc4fdef91d467ba706a541fdc925f-1741428165.us-east-2.elb.amazonaws.com 1883
Connection to a72bc4fdef91d467ba706a541fdc925f-1741428165.us-east-2.elb.amazonaws.com port 1883 [tcp/ibm-mqisdp] succeeded!
```

### 镜像服务器
https://hub.daocloud.io/

### OpenShift 上运行 MQTT 服务
https://bigredstack.com/run-mosquitto-mqtt-broker-on-red-hat-openshift/<br>
https://github.com/thingsboard/thingsboard/issues/3637<br>

### 创建 debug node 指定特定的镜像作为 toolbox 镜像
https://access.redhat.com/solutions/4929021
```
$ oc debug node/ip-10-0-159-84.us-east-2.compute.internal --image=quay.io/fedora/fedora:33-x86_64
sh-4.4# chroot /host
sh-4.4# toolbox
# 安装 sysstat 软件包，其中包含 iostat 命令
[root@ip-xx-xx-xx-xx /]# yum install -y sysstat
[root@ip-xx-xx-xx-xx /]# iostat 1 1
```

### 创建带有 group 信息的 repodata
```
# support 机器创建带有 group 信息的 repodata
[root@support rhel-7-server-rpms]# pwd
/data/OCP-4.9.9/yum/rhel-7-server-rpms
[root@support rhel-7-server-rpms]# time createrepo -g $(ls $(pwd)/comps.xml) $(pwd)
[root@support rhel-7-server-rpms]# yum clean all
[root@support rhel-7-server-rpms]# yum grouplist
```

### 安装 openshift ai 虚拟机
```
# 生成 ks.cfg - ocp-ai
cat > ks-ocp-ai.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=ens3 --hostname=ocpai.example.com --bootproto=static --ip=192.168.122.14 --netmask=255.255.255.0 --gateway=192.168.122.1 --nameserver=192.168.122.12
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
openssl-perl
%end
EOF

virt-install --debug --name=jwang-ocp-ai --vcpus=4 --ram=32768 --disk path=/data/kvm/jwang-ocp-ai.qcow2,bus=virtio,size=100 --os-variant rhel8.0 --network network=default,model=virtio --boot menu=on --location /root/jwang/isos/rhel-8.4-x86_64-dvd.iso --initrd-inject /tmp/ks-ocp-ai.cfg --extra-args='ks=file:/ks-ocp-ai.cfg'
```

### 离线 OCP OLM 同步脚本
https://github.com/jparrill/ztp-the-hard-way/blob/main/docs/prerequirements/mirror-olm.md
```
#!/bin/bash -e
# Disconnected Operator Catalog Mirror and Minor Upgrade
# Variables to set, suit to your installation

export OCP_RELEASE=4.9
export OCP_RELEASE_FULL=$OCP_RELEASE.9
export ARCHITECTURE=x86_64
export SIGNATURE_BASE64_FILE="signature-sha256-$OCP_RELEASE_FULL.yaml"
export OCP_PULLSECRET_AUTHFILE='/root/pull_secret.json'
export LOCAL_REGISTRY=registry.example.com:5000
export LOCAL_REGISTRY_MIRROR_TAG=/ocp4/openshift4
export LOCAL_REGISTRY_INDEX_TAG=olm-index/redhat-operator-index:v$OCP_RELEASE
export LOCAL_REGISTRY_INDEX_TAG_COMM=olm-index/community-operator-index:v$OCP_RELEASE
export LOCAL_REGISTRY_IMAGE_TAG=olm

# Set these values to true for the catalog and miror to be created
export RH_OP='true'
export CERT_OP='false'
export COMM_OP='true'
export MARKETPLACE_OP='false'

export RH_OP_INDEX="registry.redhat.io/redhat/redhat-operator-index:v${OCP_RELEASE}"
export CERT_OP_INDEX="registry.redhat.io/redhat/certified-operator-index:v${OCP_RELEASE}"
export COMM_OP_INDEX="registry.redhat.io/redhat/community-operator-index:v${OCP_RELEASE}"
export MARKETPLACE_OP_INDEX="registry.redhat.io/redhat-marketplace-index:v${OCP_RELEASE}"
export RH_OP_PACKAGES='advanced-cluster-management,cluster-logging,kubevirt-hyperconverged,local-storage-operator,ocs-operator,performance-addon-operator,ptp-operator,sriov-network-operator'
#export RH_OP_PACKAGES='advanced-cluster-management,local-storage-operator,ocs-operator,performance-addon-operator,ptp-operator,sriov-network-operator'
export COMM_OP_PACKAGES='hive-operator'

if [ $# -lt 1 ]
then
        echo "Usage : $0 mirror|mirror-olm|upgrade"
        exit
fi

mirror () {
# Mirror redhat-operator index image

if [ "${RH_OP}" = true ]
  then
    echo "opm index prune --from-index $RH_OP_INDEX --packages $RH_OP_PACKAGES --tag $LOCAL_REGISTRY/$LOCAL_REGISTRY_INDEX_TAG"
    opm index prune --from-index $RH_OP_INDEX --packages $RH_OP_PACKAGES --tag $LOCAL_REGISTRY/$LOCAL_REGISTRY_INDEX_TAG
    GODEBUG=x509ignoreCN=0 podman push --tls-verify=false $LOCAL_REGISTRY/$LOCAL_REGISTRY_INDEX_TAG --authfile $OCP_PULLSECRET_AUTHFILE
    GODEBUG=x509ignoreCN=0 oc adm catalog mirror $LOCAL_REGISTRY/$LOCAL_REGISTRY_INDEX_TAG $LOCAL_REGISTRY/$LOCAL_REGISTRY_IMAGE_TAG --registry-config=$OCP_PULLSECRET_AUTHFILE

    cat > redhat-operator-index-manifests/catalogsource.yaml << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: $LOCAL_REGISTRY/$LOCAL_REGISTRY_INDEX_TAG
  displayName: Temp Lab
  publisher: templab
  updateStrategy:
    registryPoll:
      interval: 30m
EOF

    echo ""
    echo "To apply the Red Hat Operators catalog mirror configuration to your cluster, do the following once per cluster:"
    echo "oc apply -f ./redhat-operator-index-manifests/imageContentSourcePolicy.yaml"
    echo "oc apply -f ./redhat-operator-index-manifests/catalogsource.yaml"
fi

if [ "${CERT_OP}" = true ]
  then
    "echo 1"
fi

if [ "${COMM_OP}" = true ]
  then
    echo "opm index prune --from-index $COMM_OP_INDEX --packages $COMM_OP_PACKAGES --tag $LOCAL_REGISTRY/$LOCAL_REGISTRY_INDEX_TAG_COMM"
    opm index prune --from-index $COMM_OP_INDEX --packages $COMM_OP_PACKAGES --tag $LOCAL_REGISTRY/$LOCAL_REGISTRY_INDEX_TAG_COMM
    GODEBUG=x509ignoreCN=0 podman push --tls-verify=false $LOCAL_REGISTRY/$LOCAL_REGISTRY_INDEX_TAG_COMM --authfile $OCP_PULLSECRET_AUTHFILE
    GODEBUG=x509ignoreCN=0 oc adm catalog mirror $LOCAL_REGISTRY/$LOCAL_REGISTRY_INDEX_TAG_COMM $LOCAL_REGISTRY/$LOCAL_REGISTRY_IMAGE_TAG --registry-config=$OCP_PULLSECRET_AUTHFILE

    cat > community-operator-index-manifests/catalogsource.yaml << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-community-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: $LOCAL_REGISTRY/$LOCAL_REGISTRY_INDEX_TAG_COMM
  displayName: Temp Lab
  publisher: templab
  updateStrategy:
    registryPoll:
      interval: 30m
EOF

    echo ""
    echo "To apply the Red Hat Operators catalog mirror configuration to your cluster, do the following once per cluster:"
    echo "oc apply -f ./community-operator-index-manifests/imageContentSourcePolicy.yaml"
    echo "oc apply -f ./community-operator-index-manifests/catalogsource.yaml"

fi

if [ "${MARKETPLACE_OP}" = true ]
  then
    "echo 3"
fi

}

mirror-olm () {
# hack for broken operators

for packagemanifest in $(oc get packagemanifest -n openshift-marketplace -o name) ; do
  for package in $(oc get $packagemanifest -o jsonpath='{.status.channels[*].currentCSVDesc.relatedImages}' | sed "s/ /\n/g" | tr -d '[],' | sed 's/"/ /g') ; do
    echo
    echo "Package: ${package}"
    skopeo copy docker://$package docker://$LOCAL_REGISTRY/$LOCAL_REGISTRY_IMAGE_TAG/$(echo $package | awk -F'/' '{print $2}')-$(basename $package) --all --authfile $OCP_PULLSECRET_AUTHFILE
  done
done

}

upgrade () {
# output ConfigMap for disconnected upgrade, issue guidance on mirroring

DIGEST="$(oc adm release info quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE_FULL}-${ARCHITECTURE} | sed -n 's/Pull From: .*@//p')"
DIGEST_ALGO="${DIGEST%%:*}"
DIGEST_ENCODED="${DIGEST#*:}"
SIGNATURE_BASE64=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/signatures/openshift/release/${DIGEST_ALGO}=${DIGEST_ENCODED}/signature-1" | base64 -w0 && echo)

cat > $SIGNATURE_BASE64_FILE << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-image-${OCP_RELEASE_FULL}
  namespace: openshift-config-managed
  labels:
    release.openshift.io/verification-signatures: ""
binaryData:
  ${DIGEST_ALGO}-${DIGEST_ENCODED}: ${SIGNATURE_BASE64}
EOF

echo ""
echo "To apply the image signature ConfigMap for $OCP_RELEASE_FULL, issue:"
echo "oc apply -f $SIGNATURE_BASE64_FILE"

echo ""
echo "To start mirroring content for OpenShift $OCP_RELEASE_FULL, issue:"
echo "oc adm release mirror --registry-config $OCP_PULLSECRET_AUTHFILE --from=quay.io/openshift-release-dev/ocp-release@$DIGEST --to=$LOCAL_REGISTRY$LOCAL_REGISTRY_MIRROR_TAG --to-release-image=$LOCAL_REGISTRY$LOCAL_REGISTRY_MIRROR_TAG:${OCP_RELEASE_FULL}-${ARCHITECTURE}"

echo ""
echo "To initiate the upgrade on the cluster to $OCP_RELEASE_FULL, issue:"
echo "oc adm upgrade --allow-explicit-upgrade --to-image $LOCAL_REGISTRY$LOCAL_REGISTRY_MIRROR_TAG@$DIGEST"
}

case "$1" in
	mirror)
		mirror
		;;
	mirror-olm)
		mirror-olm
		;;
	upgrade)
		upgrade
		;;
	*)
		echo $"Usage: $0 mirror|mirror-olm|upgrade"
		exit 1
esac

exit 0
```

### 创建 AgentServiceConfig 的例子
https://cloud.redhat.com/blog/telco-5g-zero-touch-provisioning-ztp<br>
https://github.com/openshift/assisted-service/blob/master/config/samples/agent-install.openshift.io_v1beta1_agentserviceconfig.yaml<br>
```
cat << EOF | oc apply -f - 
apiVersion: agent-install.openshift.io/v1beta1
kind: AgentServiceConfig
metadata:
  name: agent
  namespace: open-cluster-management
  ### This is the annotation that injects modifications in the Assisted Service pod
  annotations:
    unsupported.agent-install.openshift.io/assisted-service-configmap: "assisted-service-config"
###
spec:
  databaseStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 40Gi
  filesystemStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 40Gi
  osImages:
  - cpuArchitecture: x86_64
    openshiftVersion: '4.9'
    rootFSUrl: https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/rhcos-live-rootfs.x86_64.img
    url: https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/rhcos-4.9.0-x86_64-live.x86_64.iso
    version: 49.84.202110081407-0
EOF

## Private Key
ssh-keygen -t rsa -N '' -f ~/.ssh/acm_id_rsa
cp ~/.ssh/acm_id_rsa ~/tmp/
ACM_PRIVATE_KEY=~/tmp/acm_id_rsa
cat << EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-ssh-private-key
  namespace: open-cluster-management
stringData:
  ssh-privatekey: |-
$(cat ${ACM_PRIVATE_KEY})
type: Opaque
EOF

## Pull Secret
PULL_SECRET_FILE=~/tmp/redhat-pull-secret.json
PULL_SECRET_STR=$(cat ${PULL_SECRET_FILE} | jq -c .)
cat <<EOF | oc apply -f - 
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-pull-secret
  namespace: open-cluster-management
stringData:
  .dockerconfigjson: '${PULL_SECRET_STR}'
EOF

#  oc get secret assisted-deployment-pull-secret -o jsonpath="{.data.\.dockerconfigjson}" | base64 --decode

## AgentClusterInstall
## SNO Cluster Definition
## AgentClusterInstall
ACM_PUBLIC_STR=$(cat ~/.ssh/acm_id_rsa.pub)
cat << EOF | oc apply -f -
apiVersion: extensions.hive.openshift.io/v1beta1
kind: AgentClusterInstall
metadata:
  name: lab-cluster-aci
  namespace: open-cluster-management
spec:
  clusterDeploymentRef:
    name: lab-cluster
  imageSetRef:
    name: img4.9.9-x86-64-appsub
  networking:
    clusterNetwork:
      - cidr: "10.128.0.0/14"
        hostPrefix: 23
    serviceNetwork:
      - "172.31.0.0/16"
    machineNetwork:
      - cidr: "192.168.122.0/24"
  provisionRequirements:
    controlPlaneAgents: 1
  sshPublicKey: "${ACM_PUBLIC_STR}"
EOF

## ClusterDeployment
cat << EOF | oc apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: lab-cluster
  namespace: open-cluster-management
spec:
  baseDomain: example.com
  clusterName: ocp4-1
  controlPlaneConfig:
    servingCertificates: {}
  installed: false
  clusterInstallRef:
    group: extensions.hive.openshift.io
    kind: AgentClusterInstall
    name: lab-cluster-aci
    version: v1beta1
  platform:
    agentBareMetal:
      agentSelector:
        matchLabels:
          bla: "aaa"
  pullSecretRef:
    name: assisted-deployment-pull-secret
EOF


## NMState Config
## https://bugzilla.redhat.com/show_bug.cgi?id=2030289
## https://docs.openshift.com/container-platform/4.9/scalability_and_performance/ztp-deploying-disconnected.html
## https://coreos.slack.com/archives/CUPJTHQ5P/p1628169479283900?thread_ts=1628081457.173400&cid=CUPJTHQ5P
cat << EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: assisted-deployment-nmstate-lab-spoke
  labels:
    cluster-name: nmstate-lab-spoke
spec:
  config:
    dns-resolver:
      config:
        server:
        - 192.168.122.1
    interfaces:
    - name: ens3
      type: ethernet
      state: up
      ipv4:
        address:
        - ip: 192.168.122.201
          prefix-length: 24
        enabled: true
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
        table-id: 254
  interfaces:
    - name: "ens3"
      macAddress: "52:54:00:1c:14:57"
EOF

## InfraEnv
cp ~/.ssh/acm_id_rsa.pub ~/tmp/
ACM_PUBLIC_KEY=~/tmp/acm_id_rsa.pub

cat << EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: lab-env
  namespace: open-cluster-management
spec:
  clusterRef:
    name: lab-cluster
    namespace: open-cluster-management
  sshAuthorizedKey: "$(cat ${ACM_PUBLIC_KEY})"
  agentLabelSelector:
    matchLabels:
      bla: "aaa"
  pullSecretRef:
    name: assisted-deployment-pull-secret
  nmStateConfigLabelSelector:
    matchLabels:
      cluster-name: nmstate-lab-spoke
EOF
oc get InfraEnv lab-env -o yaml


## SPOKE CLUSTER DEPLOYMENT
oc get pod -A | grep metal3

```


### 离线 OLM 与 operator
参考： https://zhimin-wen.medium.com/airgap-installation-for-openshift-operators-fb0a3cad8731<br>
参考：https://docs.oracle.com/en/operating-systems/oracle-linux/podman/skopeo-container-tool.html<br>
```
# 在 RHEL 8 上执行
创建定制化的 index image
podman pull registry.redhat.io/redhat/redhat-operator-index:v4.9 --authfile /data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json
podman run -p50051:50051 --name operator-index -d registry.redhat.io/redhat/redhat-operator-index:v4.9

# 安装 grpcurl 工具
# https://github.com/fullstorydev/grpcurl/releases/download/v1.8.5/grpcurl_1.8.5_linux_x86_64.tar.gz
curl -L https://github.com/fullstorydev/grpcurl/releases/download/v1.8.5/grpcurl_1.8.5_linux_x86_64.tar.gz -o grpcurl_1.8.5_linux_x86_64.tar.gz
tar zxf grpcurl_1.8.5_linux_x86_64.tar.gz -C /usr/local/bin

# 获取 index image packages 信息
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > packages.out

# 检查我们需要的 operator
# advanced-cluster-management,local-storage-operator,kubevirt-hyperconverged,submariner

# 生成 podman 本地 index image 
opm index prune -f registry.redhat.io/redhat/redhat-operator-index:v4.9 -p advanced-cluster-management,local-storage-operator,kubevirt-hyperconverged,submariner -t my-redhat-operator-index:v4.9

# 拷贝 podman 本地 index image 到 tar.gz 文件
skopeo copy containers-storage:localhost/my-redhat-operator-index:v4.9 docker-archive:my-redhat-operator-index-v4.9.tar.gz

# 拷贝 tar.gz 文件到 disconnected registry
skopeo copy --authfile /data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json docker-archive:my-redhat-operator-index-v4.9.tar.gz docker://registry.example.com:5000/olm-mirror/my-redhat-operator-index:v4.9

# 将 catalog bundle 拷贝到目录
# v2/mirror/olm-mirror/my-redhat-operator-index
# 使用修剪的 image registry.example.com:5000/olm-mirror/my-redhat-operator-index:v4.9
# 将 catalog（metadata 和 image）保存到文件系统中
# 请注意，file://mirror 将映射到当前目录中的 v2/mirror 
mkdir -p /data/OCP-4.9.9/ocp/olm-mirror/redhat-operator-index
cd /data/OCP-4.9.9/ocp/olm-mirror/redhat-operator-index 
oc adm catalog mirror registry.example.com:5000/olm-mirror/my-redhat-operator-index:v4.9 file://mirror -a /data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json
...
info: Mirroring completed in 5h39m40.14s (3.478MB/s)
error mirroring image: one or more errors occurred
wrote mirroring manifests to manifests-my-redhat-operator-index-1642043666

To upload local images to a registry, run:

        oc adm catalog mirror file://mirror/olm-mirror/my-redhat-operator-index:v4.9 REGISTRY/REPOSITORY

# 将目录上传到目标 registry
# 进入到包含 v2/mirror/olm-mirror/my-redhat-operator-index 中 v2 的目录
cd /data/OCP-4.9.9/ocp/olm-mirror/redhat-operator-index 
oc adm catalog mirror file://mirror/olm-mirror/my-redhat-operator-index:v4.9 registry.example.com:5000/olm-mirror -a /data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json

```

### 将 StatefulSet 的启动命令改为循环
```
  containers:
  - name: command-demo-container
    image: debian
    command:
      - /bin/sh
    args:
      - "-c"
      - "while true ; do echo hello; sleep 10; done"
```

### zookeeper 报错 
https://blog.csdn.net/XiyouLinux_Kangyijie/article/details/76704639<br>
https://zookeeper.apache.org/doc/r3.1.2/zookeeperStarted.html<br>
```
zoo.cfg
zookeeper
Cannot assign requested address (Bind failed)
```

### cat 查看行号
```
cat -n filename
```

### 用命令检查 CrashLoopBack 状态容器
```
  containers:
  - name: command-demo-container
    image: debian
    command:
      - /bin/sh
    args:
      - "-c"
      - "while true ; do echo hello; sleep 10; done"
```

### 为 master 指定 ImageContentSourcePolicy
```
cat << EOF | oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - 
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: openshift-release
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - rregistry.example.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

# 创建为内部 image-registry 准备的 pvc 
oc --kubeconfig=/root/kubeconfig-ocp4-1 create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-storage
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF

# 将 SNO 原来的 configs.imageregistry.operator.openshift.io/cluster 的 /spec/storge 删除
# 然后添加 
# spec:
#   storage:
#     pvc:
#       claim: "registry-storage"
oc --kubeconfig=/root/kubeconfig-ocp4-1 patch configs.imageregistry.operator.openshift.io cluster --type=json --patch-file=/dev/fd/0 <<EOF
[{"op": "remove", "path": "/spec/storage" },{"op": "add", "path": "/spec/storage", "value": {"pvc":{"claim": "registry-storage"}}}]
EOF

# 将 configs.imageregistry.operator.openshift.io/cluster 的 spec.managemntState 设置为 Managed
# spec:
#   managementState: "Managed"
oc --kubeconfig=/root/kubeconfig-ocp4-1 patch configs.imageregistry.operator.openshift.io cluster --type merge --patch-file=/dev/fd/0 <<EOF
{"spec":{"managementState": "Managed"}}
EOF
```

### 报错 systemd[1]: Failed to start User Manager for UID 0.
https://access.redhat.com/solutions/5931241
```
Jan 14 05:58:59 master-0.ocp4-1.example.com systemd[1]: Failed to start User Manager for UID 0.

报错: oc get clusteroperators 
image-registry                             4.9.9     True        False         True       5m1s    ImagePrunerDegraded: Job has reached the specified backoff limit

清除报错
https://access.redhat.com/solutions/5370391

oc --kubeconfig=/root/kubeconfig-ocp4-1 patch imagepruner.imageregistry/cluster --patch '{"spec":{"suspend":true}}' --type=merge
oc --kubeconfig=/root/kubeconfig-ocp4-1 -n openshift-image-registry delete jobs --all
```

```
# 拷贝镜像
https://github.com/containers/skopeo/issues/1440

# 保存 rhacm2/agent-service-rhel8 到本地 registry，skopeo copy -a 命令可以拷贝全部数据
skopeo copy -a --authfile ${PULL_SECRET_FILE} --format v2s2 docker://registry.redhat.io/rhacm2/agent-service-rhel8@sha256:d738f808b7cf86c47d4c5a6c8ed5cb4387ca285123a393ec5f8d18951e4e0fb2 docker://registry.example.com:5000/rhacm2/agent-service-rhel8@sha256:d738f808b7cf86c47d4c5a6c8ed5cb4387ca285123a393ec5f8d18951e4e0fb2
skopeo copy -a --authfile ${PULL_SECRET_FILE} --format v2s2 docker://registry.redhat.io/rhel8/postgresql-12@sha256:952ac9a625c7600449f0ab1970fae0a86c8a547f785e0f33bfae4365ece06336 docker://registry.example.com:5000/rhel8/postgresql-12

cat << EOF | oc --kubeconfig=/root/kubeconfig-ocp4-1 apply -f - 
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: openshift-release
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - registry.example.com:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - registry.example.com:5000/rhacm2/agent-service-rhel8
    source: registry.redhat.io/rhacm2/agent-service-rhel8
  - mirrors:
    - registry.example.com:5000/rhel8/postgresql-12
    source: registry.redhat.io/rhel8/postgresql-12    
EOF

```

```
parted -s /dev/sdb mklabel msdos 
parted -s /dev/sdb unit mib mkpart primary 1 100%
parted -s /dev/sdb set 1 lvm on
pvcreate /dev/sdb1
vgextend rhel /dev/sdb1
lvextend -l +100%FREE /dev/rhel/root /dev/sdb1 
xfs_growfs /
```

### 重建 assisted-service pod postgresql 数据库
```
1. save a copy of agentserviceconfig
oc --kubeconfig=/root/kubeconfig-ocp4-1 get agentserviceconfig agent -o yaml > agentserviceconfig.backup

2.
oc --kubeconfig=/root/kubeconfig-ocp4-1 delete agentserviceconfig agent

3.
oc --kubeconfig=/root/kubeconfig-ocp4-1 create -f agentserviceconfig.backup
```

### assisted-service pod 服务检查
```
报错
time="2022-01-18T05:21:15Z" level=fatal msg="Failed to upload boot files" func=main.main.func1 file="/remote-source/assisted-service/app/cmd/main.go:179" error="Failed uploading boot files for OCP version 4.9: Failed fetching from URL http://192.168.122.15/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/rhcos-4.9.0-x86_64-live.x86_64.iso: Get \"http://192.168.122.15/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/rhcos-4.9.0-x86_64-live.x86_64.iso\": dial tcp 192.168.122.15:80: connect: no route to host"

问题解决
在 192.168.122.15 上开启防火墙
firewall-cmd --add-service=http
firewall-cmd --add-service=http --permanent

oc --kubeconfig=/root/kubeconfig-ocp4-1 project
Using project "open-cluster-management" on server "https://api.ocp4-1.example.com:6443".

oc --kubeconfig=/root/kubeconfig-ocp4-1 get infraenv

oc --kubeconfig=/root/kubeconfig-ocp4-1 get infraenv ocp4-2 -o yaml
...
status:
  agentLabelSelector:
    matchLabels:
      infraenvs.agent-install.openshift.io: ocp4-2
  conditions:
  - lastTransitionTime: "2022-01-18T05:38:01Z"
    message: 'Failed to create image: cluster does not exist: ocp4-2, check AgentClusterInstall
      conditions: name ocp4-2 in namespace open-cluster-management'
    reason: ImageCreationError
    status: Unknown
    type: ImageCreated

oc --kubeconfig=/root/kubeconfig-ocp4-1 get AgentClusterInstall
```

```
# google-chrome 执行时设置 host-resolver-rules 
nohup /usr/bin/google-chrome-stable --restore-last-session --host-resolver-rules="MAP api.ocp-edge-cluster-0.qe.redhat.com 10.46.46.12","MAP oauth-openshift.apps.ocp-edge-cluster-0.qe.lab.redhat.com 10.46.46.12","MAP console-openshift-console.apps.ocp-edge-cluster-0.qe.lab.redhat.com 10.46.46.12","MAP grafana-openshift-monitoring.apps.ocp-edge-cluster-0.qe.redhat.com 10.46.46.12","MAP thanos-querier-openshift-monitoring.apps.ocp-edge-cluster-0.qe.redhat.com 10.46.46.12","MAP prometheus-k8s-openshift-monitoring.apps.ocp-edge-cluster-0.qe.redhat.com 10.46.46.12","MAP alertmanager-main-openshift-monitoring.apps.ocp-edge-cluster-0.qe.redhat.com 10.46.46.12","MAP multicloud-console.apps.ocp-edge-cluster-0.qe.lab.redhat.com 10.46.46.12" &

# Baremetal Host 例子
cat 07_baremetal_host.yaml 

apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: "bm-spoke-8-master"
  namespace: bm-spoke-8
  labels:
    infraenvs.agent-install.openshift.io: "bm-spoke-8"
  annotations:
    inspect.metal3.io: disabled
spec:
  online: true
  automatedCleaningMode: disabled
  bootMACAddress: E4:43:4B:BD:90:9A 
  bmc:
    address: idrac-virtualmedia+https://10.19.28.55/redfish/v1/Systems/System.Embedded.1
    credentialsName: "10.19.28.55"
    disableCertificateVerification: true

# Install RHEL 8 Hypervisor

# 启用 RHEL 8 EPEL
# https://docs.fedoraproject.org/en-US/epel/#_el8
subscription-manager repos --enable codeready-builder-for-rhel-8-$(arch)-rpms
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

# 安装虚拟化组件
sudo dnf module install virt
sudo dnf install virt-install
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# 根据需要禁用虚拟网络的 DHCP，以下是在虚拟网络 default 上，禁止 DHCP 时的例子 
if(virsh net-dumpxml default | grep dhcp &>/dev/null); then
      virsh net-update default delete ip-dhcp-range "<range start='192.168.122.2' end='192.168.122.254'/>" --live --config || { echo "Unable to disable DHCP on default network"; return 1; }
fi

# 检查 kvm_intel 的 nested 是否启用，如果未启用则启用
sudo cat /sys/module/kvm_intel/parameters/nested
sudo sed -ie 's|^#options kvm_intel nested=1|options kvm_intel nested=1|' /etc/modprobe.d/kvm.conf 
sudo modprobe -r kvm_intel
sudo modprobe kvm_intel

# 创建虚拟机磁盘目录

mkdir -p /data/kvm
chcon --reference /var/lib/libvirt /data
chcon -R --reference /var/lib/libvirt/images /data/kvm
sudo chmod a+r /data

# RHEL 7
[root@undercloud ~]# cat > /tmp/ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=eth0 --hostname=support.example.com --bootproto=static --ip=192.168.122.12 --netmask=255.255.255.0 --gateway=192.168.122.1 --nameserver=192.168.122.12
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal
kexec-tools
tar
%end
EOF

# RHEL 8
[root@undercloud ~]# cat > /tmp/ks.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=enp1s0 --hostname=support.example.com --bootproto=static --ip=192.168.122.12 --netmask=255.255.255.0 --gateway=192.168.122.1 --nameserver=192.168.122.12
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
%end
EOF

qemu-img create -f qcow2 -o preallocation=metadata /data/kvm/jwang-support-openshift.qcow2 120G

# RHEL 7
virt-install --name=jwang-support-openshift --vcpus=1 --ram=2048 \
--disk path=/data/kvm/jwang-support-openshift.qcow2,bus=virtio,size=120 \
--os-variant rhel7.0 --network network=default,model=virtio \
--boot menu=on --location /data/isos/rhel-7.9-x86_64-dvd1.iso \
--console pty,target_type=serial \
--initrd-inject /tmp/ks.cfg \
--extra-args='inst.ks=file:/ks.cfg'

# RHEL 8
virt-install --name=jwang-support-openshift --vcpus=1 --ram=2048 \
--disk path=/data/kvm/jwang-support-openshift.qcow2,bus=virtio,size=120 \
--os-variant rhel8.0 --network network=default,model=virtio \
--boot menu=on --location /data/isos/rhel-8.4-x86_64-dvd.iso \
--console pty,target_type=serial \
--initrd-inject /tmp/ks.cfg \
--extra-args='inst.ks=file:/ks.cfg'

# RHEL8 访问虚拟机console
yum install cockpit
systemctl enable --now cockpit.socket
firewall-cmd --add-service=cockpit --permanent
firewall-cmd --reload
yum install -y cockpit-machines 

安装 vncserver
yum install -y tigervnc-server virt-viewer
vncserver :3
firewall-cmd --permanent --add-port=5900/tcp
firewall-cmd --permanent --add-port=5901/tcp
firewall-cmd --permanent --add-port=5902/tcp
firewall-cmd --permanent --add-port=5903/tcp
firewall-cmd --reload

# 登陆 support.example.com
# 设置OCP安装版本信息
export OCP_MAJOR_VER=4.9
export OCP_VER=4.9.9
echo ${OCP_VER}

# 创建离线介质目录
export OCP_PATH=/data/OCP-${OCP_VER}/ocp
export YUM_PATH=/data/OCP-${OCP_VER}/yum
mkdir -p ${OCP_PATH}/{app-image,ocp-client,ocp-image,ocp-installer,rhcos,secret}  ${YUM_PATH}

# 下载离线YUM源
# 登录订阅账户并绑定OpenShift订阅
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
export SUB_USER=XXXXX
set +o history
export SUB_PASSWD=XXXXX
subscription-manager register --force --user ${SUB_USER} --password ${SUB_PASSWD}
set -o history
subscription-manager refresh
subscription-manager list --available --matches 'Red Hat OpenShift Container Platform' | grep "Pool ID"
subscription-manager attach --pool=<ONE-POOL-ID>
subscription-manager config --rhsm.baseurl=https://china.cdn.redhat.com
subscription-manager refresh
yum clean all
yum makecache

# 开启订阅频道
# 关闭所有预先启用的yum频道
subscription-manager repos --disable="*"
# 仅启用与本次部署相关的yum源
subscription-manager repos \
    --enable="rhel-8-for-x86_64-baseos-rpms" \
    --enable="rhel-8-for-x86_64-appstream-rpms" \
    --enable="rhocp-${OCP_MAJOR_VER}-for-rhel-8-x86_64-rpms" 
# 批量下载软件包
yum -y install yum-utils 
for repo in $(subscription-manager repos --list-enabled | grep "Repo ID" | awk '{print $3}'); do
    reposync -n --delete --repoid ${repo} -p ${YUM_PATH} --download-metadata
done
# 检查下载后的软件包容量
du -lh ${YUM_PATH} --max-depth=1
# 压缩打包
cd ${YUM_PATH}
for dir in $(ls --indicator-style=none ${YUM_PATH}/); do
    tar -zcvf ${YUM_PATH}/${dir}.tar.gz ${dir}; 
done



# 生成 cluster bashrc
export OCP_CLUSTER_ID="ocp4-1"
cat << EOF >> ~/.bashrc-${OCP_CLUSTER_ID}
#######################################
setVAR(){
  if [ \$# = 0 ]
  then
    echo "USAGE: "
    echo "   setVAR VAR_NAME VAR_VALUE    # Set VAR_NAME with VAR_VALUE"
    echo "   setVAR VAR_NAME              # Delete VAR_NAME"
  elif [ \$# = 1 ]
  then
    sed -i "/\${1}/d" ~/.bashrc-${OCP_CLUSTER_ID}
source ~/.bashrc-${OCP_CLUSTER_ID}
unset \${1}
    echo \${1} is empty
  else
    sed -i "/\${1}/d" ~/.bashrc-${OCP_CLUSTER_ID}
    echo export \${1}=\"\${2}\" >> ~/.bashrc-${OCP_CLUSTER_ID}
source ~/.bashrc-${OCP_CLUSTER_ID}
echo \${1}="\${2}"
  fi
  echo ${VAR_NAME}
}
#######################################
EOF
source ~/.bashrc-${OCP_CLUSTER_ID}

# 设置变量
setVAR OCP_MAJOR_VER 4.9
setVAR OCP_VER 4.9.9
setVAR RHCOS_VER 4.9.0
setVAR YUM_PATH /data/OCP-${OCP_VER}/yum     #存放yum源的目录
setVAR OCP_PATH /data/OCP-${OCP_VER}/ocp     #存放OCP原始安装介质的目录

# 安装oc客户端
tar -xzf ${OCP_PATH}/ocp-client/openshift-client-linux-${OCP_VER}.tar.gz -C /usr/local/sbin/
oc version

# 配置本地临时YUM源
# 准备YUM源所需的文件
# 先解压缩文件，然后删除压缩文件
cd ${YUM_PATH}
for file in $(ls ${YUM_PATH}/*.tar.gz); do tar -zxvf ${file} -C ${YUM_PATH}/; done
rm -rf ${YUM_PATH}/*.tar.gz

# 配置本地临时YUM源
# RHEL7
cat << EOF > /etc/yum.repos.d/base.repo
[rhel-7-server]
name=rhel-7-server
baseurl=file://${YUM_PATH}/rhel-7-server-rpms
enabled=1
gpgcheck=0
EOF


# RHEL8
# 创建以下文件，配置本地临时YUM源
cat << EOF > /etc/yum.repos.d/local.repo
[rhel-8-for-x86_64-baseos-rpms]
name=rhel-8-for-x86_64-baseos-rpms
baseurl=file://${YUM_PATH}/rhel-8-for-x86_64-baseos-rpms
enabled=1
gpgcheck=0

[rhel-8-for-x86_64-appstream-rpms]
name=rhel-8-for-x86_64-appstream-rpms
baseurl=file://${YUM_PATH}/rhel-8-for-x86_64-appstream-rpms
enabled=1
gpgcheck=0
EOF
yum repolist

# 创建基于HTTP的YUM服务
# 安装Apache HTTP服务，并将http的端口修改为8080
yum -y install httpd
systemctl enable httpd --now
sed -i -e 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf
cat /etc/httpd/conf/httpd.conf |grep "Listen 8080"
# 注意：必须将yum目录所属首级目录/data以及所有子目录权限设为705，这样才能通过http访问。
chmod -R 705 /data
# 创建指向yum目录的httpd配置文件。
cat << EOF > /etc/httpd/conf.d/yum.conf
Alias /repo "${YUM_PATH}"
<Directory "${YUM_PATH}">
  Options +Indexes +FollowSymLinks
  Require all granted
</Directory>
<Location /repo>
  SetHandler None
</Location>
EOF
# 重新启动 httpd 服务，然后验证可以访问到repo目录
systemctl restart httpd
curl http://localhost:8080/repo/

# 安装配置DNS服务
# OpenShift 4建议的域名组成为：集群名+根域名 $OCP_CLUSTER_ID.$DOMAIN
# 对于etcd，OCP要求由etcd-$INDEX格式组成。本例中由于etcd安装于master上，因此etcd的域名实际也是指向各master节点。此外，etcd还需要_etcd-server-ssl._tcp.$CLUSTERDOMMAIN的SRV记录，用于master寻找etcd节点，该域名指向etcd节点。
# 安装BIND服务
yum -y install bind bind-utils
systemctl enable named --now
# 设置BIND配置文件
# 先备份原始BIND配置文件，然后修改BIND配置，并重新加载配置
cp /etc/named.conf{,_bak}
sed -i -e "s/listen-on port.*/listen-on port 53 { any; };/" /etc/named.conf
sed -i -e "s/allow-query.*/allow-query { any; };/" /etc/named.conf
rndc reload
grep -E 'listen-on port|allow-query' /etc/named.conf 
# 注意：如果有外部的解析需求，则请确保DNS服务器可以访问外网，并添加如下配置：
# 如果有外部的解析需求，则请确保DNS服务器可以访问外网，并添加如下配置：
sed -i '/recursion yes;/a \
        forward first; \
        forwarders { 114.114.114.114; 8.8.8.8; };' /etc/named.conf
sed -i -e "s/dnssec-enable.*/dnssec-enable no;/" /etc/named.conf
sed -i -e "s/dnssec-validation.*/dnssec-validation no;/" /etc/named.conf
rndc reload

# 配置Zone区域
# 设置DNS环境变量
setVAR DOMAIN example.com
setVAR OCP_CLUSTER_ID ocp4-1
setVAR BASTION_IP 192.168.122.13
setVAR SUPPORT_IP 192.168.122.12
setVAR DNS_IP 192.168.122.12
setVAR NTP_IP 192.168.122.12
setVAR YUM_IP 192.168.122.12
setVAR REGISTRY_IP 192.168.122.12
setVAR NFS_IP 192.168.122.12
setVAR LB_IP 192.168.122.12
setVAR BOOTSTRAP_IP 192.168.122.100
setVAR MASTER0_IP 192.168.122.101
setVAR MASTER1_IP 192.168.122.102
setVAR MASTER2_IP 192.168.122.103
setVAR WORKER0_IP 192.168.122.110
setVAR WORKER1_IP 192.168.122.111

# 添加解析Zone区域
# 执行以下命令添加3个解析ZONE（如果要执行多次，需要手动删除以前增加的内容），它们分别为：
# 域名后缀                解释
# example.com           集群内部域名后缀：集群内部所有节点的主机名均采用该域名后缀
# ocp4-1.example.com    OCP集群的域名，如本例中的集群名为ocp4-1，则域名为ocp4-1.example.com
# 168.192.in-addr.arpa  用于集群内所有节点的反向解析
cat >> /etc/named.rfc1912.zones << EOF
 
zone "${DOMAIN}" IN {
        type master;
        file "${DOMAIN}.zone";
        allow-transfer { any; };
};
 
zone "${OCP_CLUSTER_ID}.${DOMAIN}" IN {
        type master;
        file "${OCP_CLUSTER_ID}.${DOMAIN}.zone";
        allow-transfer { any; };
};
 
zone "168.192.in-addr.arpa" IN {
        type master;
        file "168.192.in-addr.arpa.zone";
        allow-transfer { any; };
};
 
EOF
# 创建example.com.zone区域配置文件
cat > /var/named/${DOMAIN}.zone << EOF
\$ORIGIN ${DOMAIN}.
\$TTL 1D
@           IN SOA  ${DOMAIN}. admin.${DOMAIN}. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum
 
@             IN NS                         dns.${DOMAIN}.
 
bastion       IN A                          ${BASTION_IP}
support       IN A                          ${SUPPORT_IP}
dns           IN A                          ${DNS_IP}
ntp           IN A                          ${NTP_IP}
yum           IN A                          ${YUM_IP}
registry      IN A                          ${REGISTRY_IP}
nfs           IN A                          ${NFS_IP}
 
EOF
cat /var/named/${DOMAIN}.zone
# 创建ocp4-1.example.com.zone区域配置文件
cat > /var/named/${OCP_CLUSTER_ID}.${DOMAIN}.zone << EOF
\$ORIGIN ${OCP_CLUSTER_ID}.${DOMAIN}.
\$TTL 1D
@           IN SOA  ${OCP_CLUSTER_ID}.${DOMAIN}. admin.${OCP_CLUSTER_ID}.${DOMAIN}. (
                                        0          ; serial
                                        1D         ; refresh
                                        1H         ; retry
                                        1W         ; expire
                                        3H )       ; minimum
 
@             IN NS                         dns.${DOMAIN}.
 
lb             IN A                          ${LB_IP}
 
api            IN A                          ${LB_IP}
api-int        IN A                          ${LB_IP}
*.apps         IN A                          ${LB_IP}
 
bootstrap      IN A                          ${BOOTSTRAP_IP}
 
master-0       IN A                          ${MASTER0_IP}
master-1       IN A                          ${MASTER1_IP}
master-2       IN A                          ${MASTER2_IP}
 
etcd-0         IN A                          ${MASTER0_IP}
etcd-1         IN A                          ${MASTER1_IP}
etcd-2         IN A                          ${MASTER2_IP}
 
worker-0       IN A                          ${WORKER0_IP}
worker-1       IN A                          ${WORKER1_IP}
 
_etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN}. 8640 IN SRV 0 10 2380 etcd-0.${OCP_CLUSTER_ID}.${DOMAIN}.
_etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN}. 8640 IN SRV 0 10 2380 etcd-1.${OCP_CLUSTER_ID}.${DOMAIN}.
_etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN}. 8640 IN SRV 0 10 2380 etcd-2.${OCP_CLUSTER_ID}.${DOMAIN}.
 
EOF
cat /var/named/${OCP_CLUSTER_ID}.${DOMAIN}.zone
# 创建168.192.in-addr.arpa.zone反向解析区域配置文件
# 注意：以下脚本中的反向IP如果有变化需要在此手动修改。
cat > /var/named/168.192.in-addr.arpa.zone << EOF
\$TTL 1D
@           IN SOA  ${DOMAIN}. admin.${DOMAIN}. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
                                        
@                              IN NS       dns.${DOMAIN}.
 
13.122.168.192.in-addr.arpa.     IN PTR      bastion.${DOMAIN}.
 
12.122.168.192.in-addr.arpa.     IN PTR      support.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      dns.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      ntp.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      yum.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      registry.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      nfs.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      lb.${OCP_CLUSTER_ID}.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      api.${OCP_CLUSTER_ID}.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      api-int.${OCP_CLUSTER_ID}.${DOMAIN}.
 
100.122.168.192.in-addr.arpa.    IN PTR      bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}.
 
101.122.168.192.in-addr.arpa.    IN PTR      master-0.${OCP_CLUSTER_ID}.${DOMAIN}.
102.122.168.192.in-addr.arpa.    IN PTR      master-1.${OCP_CLUSTER_ID}.${DOMAIN}.
103.122.168.192.in-addr.arpa.    IN PTR      master-2.${OCP_CLUSTER_ID}.${DOMAIN}.
 
110.122.168.192.in-addr.arpa.    IN PTR      worker-0.${OCP_CLUSTER_ID}.${DOMAIN}.
111.122.168.192.in-addr.arpa.    IN PTR      worker-1.${OCP_CLUSTER_ID}.${DOMAIN}.
 
EOF
cat /var/named/168.192.in-addr.arpa.zone
# 重启BIND服务
# 重启BIND服务，然后检查没有错误日志。
systemctl restart named
rndc reload
journalctl -u named

# 将Support节点的DNS配置指向自己
nmcli c mod $(nmcli con show |awk 'NR==2{print}'|awk '{print $1}') ipv4.dns "${DNS_IP}"
systemctl restart NetworkManager
nmcli c show $(nmcli con show |awk 'NR==2{print}'|awk '{print $1}')| grep ipv4.dns

# 测试正反向DNS解析
# 正向解析测试
dig nfs.${DOMAIN} +short
dig support.${DOMAIN} +short 
dig yum.${DOMAIN} +short
dig registry.${DOMAIN} +short
dig ntp.${DOMAIN} +short
dig lb.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig api.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig api-int.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig *.apps.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig bastion.${DOMAIN} +short
dig bootstrap.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig master-0.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig etcd-0.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig master-1.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig etcd-1.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig master-2.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig etcd-2.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig worker-0.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig worker-1.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig _etcd-server-ssl._tcp.${OCP_CLUSTER_ID}.${DOMAIN} SRV +short

# 反向解析测试
dig -x ${BASTION_IP} +short
dig -x ${SUPPORT_IP} +short
dig -x ${BOOTSTRAP_IP} +short
dig -x ${MASTER0_IP} +short
dig -x ${MASTER1_IP} +short
dig -x ${MASTER2_IP} +short
dig -x ${WORKER0_IP} +short
dig -x ${WORKER1_IP} +short

# 配置远程正式YUM源
# 配置Support节点的YUM源
# 删除临时yum源
setVAR YUM_DOMAIN yum.${DOMAIN}:8080

# RHEL7
cat > /etc/yum.repos.d/ocp.repo << EOF
[rhel-7-server]
name=rhel-7-server
baseurl=http://${YUM_DOMAIN}/repo/rhel-7-server-rpms/
enabled=1
gpgcheck=0
 
[rhel-7-server-extras] 
name=rhel-7-server-extras
baseurl=http://${YUM_DOMAIN}/repo/rhel-7-server-extras-rpms/
enabled=1
gpgcheck=0
 
[rhel-7-server-ose] 
name=rhel-7-server-ose
baseurl=http://${YUM_DOMAIN}/repo/rhel-7-server-ose-${OCP_MAJOR_VER}-rpms/
enabled=1
gpgcheck=0 
 
EOF

# RHEL8
mv /etc/yum.repos.d/local.repo{,.bak}
cat > /etc/yum.repos.d/ocp.repo << EOF
[rhel-8-for-x86_64-baseos-rpms]
name=rhel-8-for-x86_64-baseos-rpms
baseurl=http://${YUM_DOMAIN}/repo/rhel-8-for-x86_64-baseos-rpms/
enabled=1
gpgcheck=0
 
[rhel-8-for-x86_64-appstream-rpms] 
name=rhel-8-for-x86_64-appstream-rpms
baseurl=http://${YUM_DOMAIN}/repo/rhel-8-for-x86_64-appstream-rpms/
enabled=1
gpgcheck=0
 
[rhocp-4.9-for-rhel-8-x86_64-rpms] 
name=rhocp-4.9-for-rhel-8-x86_64-rpms
baseurl=http://${YUM_DOMAIN}/repo/rhocp-4.9-for-rhel-8-x86_64-rpms/
enabled=1
gpgcheck=0 
 
EOF
yum repolist

# 安装基础软件包，验证YUM源
# 在Support节点安装以下软件包，验证YUM源是正常的。
# RHEL7 
yum -y install wget git net-tools bridge-utils jq tree httpd-tools 
# RHEL8
yum -y install podman wget git net-tools jq tree httpd-tools 

# 部署NTP服务
# 注意：下文将Support节点当做OpenShift集群的NTP服务源。如果用户已经有NTP服务，可以忽略此节，并在安装OpenShift集群后将集群节点的时间服务指向已有的NTP服务。
# 设置正确的时区
timedatectl set-timezone Asia/Shanghai
timedatectl status | grep 'Time zone'
# 配置chrony服务
# RHEL 8.4最小化安装会安装chrony时间服务软件。我们先查看chrony服务状态：
systemctl status chronyd
# 备份原始chrony.conf配置文件，再修改配置文件
cp /etc/chrony.conf{,.bak}
sed -i -e "s/^server*/#&/g" \
       -e "s/^pool*/#&/g" \
       -e "s/#local stratum 10/local stratum 10/g" \
       -e "s/#allow 192.168.0.0\/16/allow all/g" \
       /etc/chrony.conf
cat >> /etc/chrony.conf << EOF
server ntp.${DOMAIN} iburst
EOF
cat /etc/chrony.conf
# 重启chrony服务
systemctl restart chronyd
# 检查chrony服务端启动
ps -auxw |grep chrony
ss -lnup |grep chronyd
chronyc sources -v

# 部署本地Docker Registry
# 该Docker Registry镜像库用于提供OCP安装过程所需的容器镜像。
# 创建Docker Registry相关目录
setVAR REGISTRY_PATH /data/registry            ## 容器镜像库存放的根目录
mkdir -p ${REGISTRY_PATH}/{auth,certs,data}

# 创建访问Docker Registry的证书
# 在 RHEL 8 服务器上创建，然后拷贝对应文件到 RHEL 7
openssl req -newkey rsa:4096 -nodes -sha256 -keyout ${REGISTRY_PATH}/certs/registry.key -x509 -days 3650 \
  -out ${REGISTRY_PATH}/certs/registry.crt \
  -addext "subjectAltName = DNS:registry.${DOMAIN}" \
  -subj "/C=CN/ST=BEIJING/L=BJ/O=REDHAT/OU=IT/CN=registry.${DOMAIN}/emailAddress=admin@${DOMAIN}"
openssl x509 -in ${REGISTRY_PATH}/certs/registry.crt -text | head -n 14

yum -y install docker-distribution
# 创建Registry认证凭据，允许用openshift/redhat登录。
htpasswd -bBc ${REGISTRY_PATH}/auth/htpasswd openshift redhat
cat ${REGISTRY_PATH}/auth/htpasswd
# 创建docker-distribution配置文件
setVAR REGISTRY_DOMAIN registry.${DOMAIN}:5000                  ## 容器镜像库的访问域名
cat << EOF > /etc/docker-distribution/registry/config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: ${REGISTRY_PATH}/data
    delete:
        enabled: false
auth:
  htpasswd:
    realm: basic-realm
    path: ${REGISTRY_PATH}/auth/htpasswd
http:
    addr: 0.0.0.0:5000
    host: https://${REGISTRY_DOMAIN}
    tls:
      certificate: ${REGISTRY_PATH}/certs/registry.crt
      key: ${REGISTRY_PATH}/certs/registry.key
EOF
cat /etc/docker-distribution/registry/config.yml
# 启动Registry镜像库服务
systemctl enable --now docker-distribution
systemctl status docker-distribution

# 从本地访问Docker Registry 
cp ${REGISTRY_PATH}/certs/registry.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust
curl -u openshift:redhat https://${REGISTRY_DOMAIN}/v2/_catalog

# 从远程访问Docker Registry


# 导入OpenShift核心镜像到Docker Registry
setVAR REGISTRY_REPO ocp4/openshift4       ## 在Docker Registry中存放OpenShift核心镜像的Repository
# 如果生成证书时设置了 subjectAltName 不需要设置 GODEBUG
setVAR GODEBUG 509ignoreCN=0

# 安装镜像操作工具并登录Docker Registry
yum -y install podman skopeo 
setVAR PULL_SECRET_FILE ${OCP_PATH}/secret/redhat-pull-secret.json
podman login -u openshift -p redhat --authfile ${PULL_SECRET_FILE} ${REGISTRY_DOMAIN}
cat ${PULL_SECRET_FILE}
# 向Docker Registry导入OpenShift核心镜像
tar -xvf ${OCP_PATH}/ocp-image/ocp-image-${OCP_VER}.tar -C ${OCP_PATH}/ocp-image/
rm -f ${OCP_PATH}/ocp-image/ocp-image-${OCP_VER}.tar
setVAR REGISTRY_REPO 
oc image mirror -a ${PULL_SECRET_FILE} \
     --dir=${OCP_PATH}/ocp-image/mirror_${OCP_VER} file://openshift/release:${OCP_VER}* ${REGISTRY_DOMAIN}/${REGISTRY_REPO}
# 查看已经导入镜像库镜像数量，然后查看镜像信息。
curl -u openshift:redhat https://${REGISTRY_DOMAIN}/v2/_catalog
curl -u openshift:redhat -s https://${REGISTRY_DOMAIN}/v2/${REGISTRY_REPO}/tags/list |jq -M '.["tags"][]' | wc -l
curl -u openshift:redhat -s https://${REGISTRY_DOMAIN}/v2/${REGISTRY_REPO}/tags/list |jq -M '.["name"] + ":" + .["tags"][]' 
oc adm release info -a ${PULL_SECRET_FILE} "${REGISTRY_DOMAIN}/${REGISTRY_REPO}:${OCP_VER}-x86_64" | grep -A 200 -i "Images" 

# 部署HAProxy负载均衡服务
# 安装Haproxy
yum -y install haproxy
systemctl enable haproxy --now

# 添加haproxy.cfg配置文件
cat <<EOF > /etc/haproxy/haproxy.cfg
 
# Global settings
#---------------------------------------------------------------------
global
    maxconn     20000
    log         /dev/log local0 info
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon
 
    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats
 
#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
#    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          300s
    timeout server          300s
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 20000
 
listen stats
    bind :9000
    mode http
    stats enable
    stats uri /
 
frontend  openshift-api-server-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:6443
    mode tcp
    option tcplog
    default_backend openshift-api-server-${OCP_CLUSTER_ID}
 
frontend  machine-config-server-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:22623
    mode tcp
    option tcplog
    default_backend machine-config-server-${OCP_CLUSTER_ID}
 
frontend  ingress-http-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:80
    mode tcp
    option tcplog
    default_backend ingress-http-${OCP_CLUSTER_ID}
 
frontend  ingress-https-${OCP_CLUSTER_ID}
    bind lb.${OCP_CLUSTER_ID}.${DOMAIN}:443
    mode tcp
    option tcplog
    default_backend ingress-https-${OCP_CLUSTER_ID}
 
backend openshift-api-server-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     bootstrap bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check
    server     master-1 master-1.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check
    server     master-2 master-2.${OCP_CLUSTER_ID}.${DOMAIN}:6443 check
 
backend machine-config-server-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     bootstrap bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check
    server     master-0 master-0.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check
    server     master-1 master-1.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check
    server     master-2 master-2.${OCP_CLUSTER_ID}.${DOMAIN}:22623 check
 
backend ingress-http-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     worker-0 worker-0.${OCP_CLUSTER_ID}.${DOMAIN}:80 check
    server     worker-1 worker-1.${OCP_CLUSTER_ID}.${DOMAIN}:80 check
 
backend ingress-https-${OCP_CLUSTER_ID}
    balance source
    mode tcp
    server     worker-0 worker-0.${OCP_CLUSTER_ID}.${DOMAIN}:443 check
    server     worker-1 worker-1.${OCP_CLUSTER_ID}.${DOMAIN}:443 check
 
EOF
cat /etc/haproxy/haproxy.cfg

# 重启HAProxy服务, 然后检查HAProxy服务
systemctl restart haproxy
ss -lntp |grep haproxy

# 访问如下页面http://lb.ocp4-1.example.internal:9000/，确认每行颜色和下图一致。注意：为了能解析域名，运行浏览器所在节点需要将DNS设置到support节点的地址。

# 1. 安装 Assisted Install 服务
# 这个部分按照安装 openshift upi support 服务器来安装一台服务器
# hostname: ocpai.exmaple.com
# ip: 192.168.122.14/24
# gateway: 192.168.122.1
# nameserver: 192.168.122.12
# 生成 ks.cfg - ocp-ai
cat > /tmp/ks-ocp-ai.cfg <<'EOF'
lang en_US
keyboard us
timezone Asia/Shanghai --isUtc
rootpw $1$PTAR1+6M$DIYrE6zTEo5dWWzAp9as61 --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
text
cdrom
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --device=enp1s0 --hostname=ocpai.example.com --bootproto=static --ip=192.168.122.14 --netmask=255.255.255.0 --gateway=192.168.122.1 --nameserver=192.168.122.12
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
%packages
@^minimal-environment
kexec-tools
tar
openssl-perl
%end
EOF

# 创建 jwang-ocp-ai 虚拟机，安装操作系统
qemu-img create -f qcow2 -o preallocation=metadata /data/kvm/jwang-ocp-ai.qcow2 120G
virt-install --name=jwang-ocp-ai --vcpus=1 --ram=2048 --disk path=/data/kvm/jwang-ocp-ai.qcow2,bus=virtio,size=100 --os-variant rhel8.0 --network network=default,model=virtio --boot menu=on --location /data/isos/rhel-8.4-x86_64-dvd.iso --initrd-inject /tmp/ks-ocp-ai.cfg --extra-args='ks=file:/ks-ocp-ai.cfg'

# 挂载 iso
virsh change-media jwang-ocp-ai sda --source /data/isos/rhel-8.4-x86_64-dvd.iso --insert --live
mount /dev/sr0 /mnt

# 生成本地 yum 源
cat > /etc/yum.repos.d/local.repo << EOF
[baseos]
name=baseos
baseurl=file:///mnt/BaseOS
enabled=1
gpgcheck=0

[appstream]
name=appstream
baseurl=file:///mnt/AppStream
enabled=1
gpgcheck=0
EOF

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
setenforce 0

dnf install -y @container-tools
dnf groupinstall -y "Development Tools"
dnf install -y python3-pip socat make tmux git jq crun

tar zxvf /data/assisted-installer/assisted-service.tar.gz -C /root/ 
tar zxvf /data/assisted-installer/assisted-installer-cli.tar.gz -C /root/

# 加载镜像
tar zxvf /data/assisted-installer/assisted-installer-images.tar.gz -C /root/
cd /root
for i in assisted-installer-images/*.tar ; do podman load -i $i ; done

# 关闭防火墙
systemctl disable firewalld
systemctl mask firewalld
iptable -nL 

# 安装 httpd
yum install -y httpd
systemctl enable --now httpd

tar zxvf /data/assisted-installer/assisted-image-service-os-image.tar.gz -C /
curl localhost/pub/

# 拷贝 rhcos-4.9.0-x86_64-live-rootfs.x86_64.img 
cp /data/assisted-installer/rhcos-4.9.0-x86_64-live-rootfs.x86_64.img /var/www/html/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/

# 导入 assisted-image-service.tar 到 quay.io/edge-infrastructure/assisted-image-service-new
tar zxvf /data/assisted-installer/assisted-service-export.tar.gz -C /root/
cd /root/assisted-service-export/
podman import assisted-image-service.tar quay.io/edge-infrastructure/assisted-image-service-new -c CMD=/assisted-image-service -c ENV=DATA_DIR=/data -c ENV=PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

cd /root/assisted-service
cat onprem-environment | grep IMAGE

# 编辑 onprem-environment，检查以下配置
SERVICE_BASE_URL=http://192.168.122.14:8090
ASSISTED_SERVICE_HOST=127.0.0.1:8090
IMAGE_SERVICE_BASE_URL=http://192.168.122.14:8888
LISTEN_PORT=8888
OS_IMAGES=[{"openshift_version":"4.9","cpu_architecture":"x86_64","url":"http://192.168.122.14/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/rhcos-4.9.0-x86_64-live.x86_64.iso","rootfs_url":"http://192.168.122.14/pub/openshift-v4/dependencies/rhcos/4.9/4.9.0/rhcos-live-rootfs.x86_64.img","version":"49.84.202110081407-0"}]
RELEASE_IMAGES=[{"openshift_version":"4.9","cpu_architecture":"x86_64","url":"registry.example.com:5000/ocp4/openshift4:4.9.9-x86_64","version":"4.9.9","default":true}]
HW_VALIDATOR_REQUIREMENTS=[{"version":"default","master":{"cpu_cores":4,"ram_mib":16384,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":100,"packet_loss_percentage":0},"worker":{"cpu_cores":2,"ram_mib":8192,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":1000,"packet_loss_percentage":10},"sno":{"cpu_cores":8,"ram_mib":16384,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10}}]

# 检查 Makefile deploy-onprem
deploy-onprem:
        # Format: ip:hostPort:containerPort | ip::containerPort | hostPort:containerPort | containerPort
        podman pod create --name assisted-installer -p 5432:5432,8000:8000,8090:8090,8080:8080,8888:8888
        podman run -dt --pod assisted-installer --env-file onprem-environment --pull always --name postgres $(PSQL_IMAGE)
        podman run -dt --pod assisted-installer --env-file onprem-environment --pull always -v $(PWD)/deploy/ui/nginx.conf:/opt/bitnami/nginx/conf/server_blocks/nginx.conf:z --name assisted-installer-ui $(ASSISTED_UI)
        podman run -dt --pod assisted-installer --env-file onprem-environment --pull always --restart always --name assisted-image-service $(IMAGE_SERVICE)
        podman run -dt --pod assisted-installer --env-file onprem-environment ${PODMAN_PULL_FLAG} --env DUMMY_IGNITION=$(DUMMY_IGNITION) --restart always --name assisted-service $(SERVICE)
        ./hack/retry.sh 90 2 "curl -f http://127.0.0.1:8090/ready"
        ./hack/retry.sh 60 10 "curl -f http://127.0.0.1:8888/health"

# 执行以下命令启动 pod
podman pod create --name assisted-installer -p 5432:5432,8000:8000,8090:8090,8080:8080,8888:8888
podman run -dt --pod assisted-installer --env-file onprem-environment --pull never --name postgres quay.io/centos7/postgresql-12-centos7:latest
podman run -dt --pod assisted-installer --env-file onprem-environment --pull never -v ./deploy/ui/nginx.conf:/opt/bitnami/nginx/conf/server_blocks/nginx.conf:z --name assisted-installer-ui quay.io/edge-infrastructure/assisted-installer-ui:latest
podman run -dt --pod assisted-installer --env-file onprem-environment --pull never --restart always --name assisted-image-service quay.io/edge-infrastructure/assisted-image-service-new:latest
podman run -dt --pod assisted-installer --env-file onprem-environment --pull never --env DUMMY_IGNITION="False" --restart always --name assisted-service quay.io/edge-infrastructure/assisted-service:latest

# curl -v https://subscription.rhn.redhat.com --cacert /etc/rhsm/ca/redhat-uep.pem

# podman pull 镜像时指定 log-level 来获得调试信息
# podman pull xxxx --log-level=debug

# 创建 htpasswd 文件，添加用户 admin, user01 和 user02
mkdir -p /root/ocp4
htpasswd -c -B -b /root/ocp4/htpasswd admin admin
htpasswd -b /root/ocp4/htpasswd user01 redhat
htpasswd -b /root/ocp4/htpasswd user02 redhat

# 使用 htpasswd 文件创建 secret htpass-secret
oc create secret generic htpass-secret --from-file=htpasswd=/root/ocp4/htpasswd -n openshift-config

# 为 oauth.config.openshift.io/cluster 添加 htpasswd identity provider
# 因为 OAuth 对象使用 htpasswd 作为 key，因此上面的 secret 对应的文件名请注意使用 htpasswd
cat <<EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: LocalProvider 
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret 
EOF

oc adm policy add-cluster-role-to-user cluster-admin admin

cat << EOF | oc1 apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ManagedClusterSet
metadata:
  name: gitops-openshift-clusters
  spec: {}
EOF

cat << EOF | oc1 apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ManagedClusterSetBinding
metadata:
  name: gitops-openshift-clusters
  namespace: openshift-gitops
spec:
  clusterSet: gitops-openshift-clusters
EOF
```

### Install oc-mirror on rhel7
https://asciinema.org/a/uToc11VnzG0RMZrht2dsaTfo9<br>
https://golangissues.com/issues/1156078<br>
```
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux 
source ~/.bash_profile
go version

git clone https://github.com/openshift/oc-mirror
cd oc-mirror
git checkout release-4.10

make 
cp ./bin/oc-mirror /usr/local/bin
```

### Install oc-mirror on rhel8
https://golangissues.com/issues/1156078<br>
```
yum groupinstall -y "Development Tools"

yum module list go-toolset
yum module -y install go-toolset

git clone https://github.com/openshift/oc-mirror
cd oc-mirror
git checkout release-4.10

make 
cp ./bin/oc-mirror /usr/local/bin

mkdir -p /data/OCP-4.9.9/ocp/ocp-image 

# 生成 image-config-realse-local.yaml 文件
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  ocp:
    channels:
      - name: stable-4.9
        versions:
          - '4.9.9'
          - '4.9.10'
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: local-storage-operator
        - name: openshift-gitops-operator
        - name: advanced-cluster-management
EOF
mkdir -p output-dir
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# 创建 imageset 4.9.10 与 headonly operator redhat-operator-index:v4.9 
cat > /root/image-config-realse-4.9.10-operator-headless.yaml <<EOF
# This config uses the headsOnly feature which will mirror the 
# latest version of each channel within each package contained 
# within a specified operator catalog
---
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
archiveSize: 1
storageConfig:
  local:
    path: /data/OCP-4.9.10/ocp/ocp-image/oc-mirror-workspace
mirror:
  ocp:
    channels:
      - name: stable-4.9
        versions:
          - 4.9.10
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsonly: true
EOF

mkdir -p output-dir
/usr/local/bin/oc-mirror --config /root/image-config-realse-4.9.10-operator-headless.yaml file://output-dir

将离线镜像同步到目标服务器
rsync -av output-dir/mirror_seq1_000000.tar 10.66.208.240:/data/OCP-4.9.10/ocp/ocp-image

在离线环境下将导入到离线镜像仓库
oc-mirror --from ./output-dir/mirror_seq1_000000.tar docker://registry.example.com:5000 --dest-skip-tls

导入 catalogsource
cat <<EOF | oc1 apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operator-index
  namespace: openshift-marketplace
spec:
  image: registry.example.com:5000/redhat/redhat-operator-index:v4.9
  sourceType: grpc
EOF

导入 imagecontentsourcepolicy
cat <<EOF | oc1 apply -f -
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: generic-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/operator-framework
    source: operator-framework
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  labels:
    operators.openshift.org/catalog: "true"
  name: operator-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/rhacm2
    source: rhacm2
  - mirrors:
    - registry.example.com:5000/openshift-gitops-1
    source: openshift-gitops-1
  - mirrors:
    - registry.example.com:5000/openshift4
    source: openshift4
  - mirrors:
    - registry.example.com:5000/redhat
    source: registry.redhat.io/redhat
  - mirrors:
    - registry.example.com:5000/rhel8
    source: rhel8
  - mirrors:
    - registry.example.com:5000/rh-sso-7
    source: rh-sso-7
EOF

oc image mirror -a /data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json --dir=/data/OCP-4.9.10/ocp/ocp-image/oc-mirror-workspace/src "file://openshift/release:4.9.10-x86_64" registry.example.com:5000/ocp4/openshift4

检查导入的 openshift-release 
oc adm release info -a /data/OCP-4.9.9/ocp/secret/redhat-pull-secret.json registry.example.com:5000/ocp4/openshift4:4.9.10-x86_64

在离线环境下从 4.9.9 更新到 4.9.10
oc2 adm upgrade \
--allow-explicit-upgrade \
--allow-upgrade-with-warnings=true \
--force=true \
--to-image=registry.example.com:5000/ocp4/openshift4:4.9.10-x86_64
   
```

```
virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf

报错：

Feb 10 07:35:23 master2.ocp4.rhcnsa.com hyperkube[1644]: E0210 07:35:23.492091    1644 kubelet_volumes.go:154] orphaned pod "094bac69-fe7a-46cc-be2f-0e5756e2df5d" found, but volume paths are still present on disk : There were a total of 1 errors similar to this. Turn up verbosity to see them.


master2 日志里有这种报错

Feb 10 08:08:27 master2.ocp4.rhcnsa.com hyperkube[1862]: E0210 08:08:27.266189    1862 kuberuntime_manager.go:767] createPodSandbox for pod "openshift-kube-scheduler-master2.ocp4.rhcnsa.com_openshift-kube-scheduler(c816ad2e-6dc0-4547-bed6-d7f00e786192)" failed: rpc error: code = Unknown desc = failed to mount container k8s_POD_openshift-kube-scheduler-master2.ocp4.rhcnsa.com_openshift-kube-scheduler_c816ad2e-6dc0-4547-bed6-d7f00e786192_0 in pod sandbox k8s_openshift-kube-scheduler-master2.ocp4.rhcnsa.com_openshift-kube-scheduler_c816ad2e-6dc0-4547-bed6-d7f00e786192_0(27a06857ff0c3a26b515330b5c3d90059440fe6374b56193f007c03ff61f8827): error recreating the missing symlinks: error reading name of symlink for &{"a7da25a9e41a5cab49b25503dec29abb68ca9969564195e88972b62446c59c63" '\x14' %!q(os.FileMode=2147484096) {%!q(uint64=423867529) %!q(int64=63762202496) %!q(*time.Location=&{Local [{UTC 0 false}] [{-576460752303423488 0 false false}] UTC0 9223372036854775807 9223372036854775807 0xc00018faa0})} {'ﰄ' %!q(uint64=408944870) '\x03' '䇀' '\x00' '\x00' '\x00' '\x00' '\x14' 'က' '\x00' {%!q(int64=1644478738) %!q(int64=980695719)} {%!q(int64=1626605696) %!q(int64=423867529)} {%!q(int64=1626605696) %!q(int64=423867529)} ['\x00' '\x00' '\x00']}}: open /var/lib/containers/storage/overlay/a7da25a9e41a5cab49b25503dec29abb68ca9969564195e88972b62446c59c63/link: no such file or directory

按照 https://access.redhat.com/solutions/5350721 里的步骤清了一下 crio 存储


Feb 10 08:44:42 master1.ocp4.rhcnsa.com hyperkube[2088]: E0210 08:44:42.271876    2088 kuberuntime_sandbox.go:70] CreatePodSandbox for pod "csi-snapshot-controller-operator-8fc4d7584-wlt5d_openshift-cluster-storage-operator(f50e5b8a-d06f-4f15-8567-d00b7f40e0fe)" failed: rpc error: code = Unknown desc = failed to create pod network sandbox k8s_csi-snapshot-controller-operator-8fc4d7584-wlt5d_openshift-cluster-storage-operator_f50e5b8a-d06f-4f15-8567-d00b7f40e0fe_0(93397762a225c4bad23e5a9010679fa36fa679abaeff2f3904751ea03ac3ab5b): error adding pod openshift-cluster-storage-operator_csi-snapshot-controller-operator-8fc4d7584-wlt5d to CNI network "multus-cni-network": Multus: [openshift-cluster-storage-operator/csi-snapshot-controller-operator-8fc4d7584-wlt5d]: PollImmediate error waiting for ReadinessIndicatorFile: timed out waiting for the condition

oc logs network-operator-7844d6cf9f-mrlvb -n openshift-network-operator 

I0210 08:56:01.936090       1 connectivity_check_controller.go:138] ConnectivityCheckController is waiting for transition to desired version (4.8.0) to be completed.
I0210 08:56:01.943062       1 connectivity_check_controller.go:138] ConnectivityCheckController is waiting for transition to desired version (4.8.0) to be completed.
I0210 08:56:02.200207       1 log.go:181] Reconciling update to openshift-network-diagnostics/network-check-target
I0210 08:56:02.218215       1 log.go:181] Reconciling update to openshift-multus/multus
I0210 08:56:02.230981       1 log.go:181] Reconciling update to openshift-multus/multus-admission-controller
I0210 08:56:02.244647       1 log.go:181] Reconciling update to openshift-multus/network-metrics-daemon
I0210 08:56:02.453908       1 log.go:181] Reconciling update to openshift-sdn/sdn-controller
I0210 08:56:02.718022       1 log.go:181] Reconciling update to openshift-sdn/sdn

  message: |-
    DaemonSet "openshift-multus/multus" is not available (awaiting 1 nodes)
    DaemonSet "openshift-multus/network-metrics-daemon" is not available (awaiting 1 nodes)
    DaemonSet "openshift-multus/multus-admission-controller" is not available (awaiting 1 nodes)
    DaemonSet "openshift-network-diagnostics/network-check-target" is not available (awaiting 1 nodes)

oc logs cluster-image-registry-operator-5cc5bdcf6c-wfc6z -n openshift-image-registry  -f 
...
E0210 09:00:37.302551       1 controller.go:369] unable to sync: unable to sync storage configuration: exactly one storage type should be configured at the same time, got 2: [EmptyDir PVC], requeuing
I0210 09:00:37.342789       1 controller.go:357] get event from workqueue
E0210 09:00:37.343021       1 controller.go:369] unable to sync: unable to sync storage configuration: exactly one storage type should be configured at the same time, got 2: [EmptyDir PVC], requeuing
I0210 09:00:37.423275       1 controller.go:357] get event from workqueue
E0210 09:00:37.423597       1 controller.go:369] unable to sync: unable to sync storage configuration: exactly one storage type should be configured at the same time, got 2: [EmptyDir PVC], requeuing

# https://access.redhat.com/solutions/4516391
# https://access.redhat.com/solutions/5114881
# 处理的方法是 
# https://access.redhat.com/solutions/5370391
oc edit configs.imageregistry.operator.openshift.io cluster



E0210 09:33:06.324699       1 controller.go:369] unable to sync: Operation cannot be fulfilled on configs.imageregistry.operator.openshift.io "cluster": the object has been modified; please apply your changes to the latest version and try again, requeuing
W0210 09:33:12.914914       1 reflector.go:436] github.com/openshift/client-go/route/informers/externalversions/factory.go:101: watch of *v1.Route ended with: an error on the server ("unable to decode an event from the watch stream: stream error: stream ID 65; INTERNAL_ERROR") has prevented the request from succeeding

参考
https://access.redhat.com/solutions/5370391

cat <<EOF | oc2 apply -f -
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  labels:
    operators.openshift.org/catalog: "true"
  name: operator-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/rhacm2
    source: registry.redhat.io/rhacm2
EOF

报错
oc2 get clusteroperators
kube-apiserver                             4.9.9     True        True          True       18d     
 StaticPodFallbackRevisionDegraded: a static pod kube-apiserver-master-0.ocp4-2.example.com was rolled back to revision 12 due to waiting for kube-apiserver static pod to listen on port 6443: Get "https://localhost:6443/healthz/etcd": dial tcp [::1]:6443: connect: connection refused
oc2 patch kubeapiserver/cluster --type=json -p '[ {"op": "replace", "path": "/spec/forceRedeploymentReason", "value": "forced test 1" } ]'


# master 节点 kubeconfig 文件位置
/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/

报错
I0214 04:39:33.223311       1 event.go:282] Event(v1.ObjectReference{Kind:"Namespace", Namespace:"open-cluster-management-agent", Name:"open-cluster-management-agent", UID:"", APIVersion:"v1", ResourceVersion:"", FieldPath:""}): type: 'Warning' reason: 'SecretCreateFailed' Failed to create Secret/open-cluster-management-image-pull-credentials -n open-cluster-management-agent-addon: secrets "open-cluster-management-image-pull-credentials" is forbidden: unable to create new content in namespace open-cluster-management-agent-addon because it is being terminated

上传 openshift-release
cd /data/OCP-4.9.10/ocp/ocp-image/output-dir/
tar xvf mirror_seq1_000000.tar
ln -sf `pwd`/blobs v2/openshift/release/
oc image mirror -a ${LOCAL_SECRET_JSON} 'file://openshift/release:4.9.10*' ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}

# 安装 chrome on rhel8
# https://www.tecmint.com/install-google-chrome-on-rhel-8/
cat > /etc/yum.repos.d/google-chrome.repo <<'EOF'
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF

yum info google-chrome-stable
yum install -y google-chrome-stable

# https://access.redhat.com/solutions/5244121
# 当 mcp 状态处于 degrade 状态
# 可以检查 namespace openshift-machine-config-operator 的 machine-config-daemon 的日志
oc1 -n openshift-machine-config-operator logs $(oc1 -n openshift-machine-config-operator get pods -l k8s-app="machine-config-daemon" -o name) -c machine-config-daemon

# https://access.redhat.com/discussions/3536621
# systemd version cannot handle too many sessions at once

# 报错
oc -n openshift-monitoring logs $(oc -n openshift-monitoring get pods -l app="cluster-monitoring-operator" -o name) -c cluster-monitoring-operator
...
W0220 08:40:00.868298       1 tasks.go:71] task 6 of 15: Updating Alertmanager failed: waiting for Alertmanager object changes failed: waiting for Alertmanager openshift-monitoring/main: expected 3 replicas, got 0 updated replicas                                                                                                      
I0220 08:40:00.868362       1 operator.go:624] ClusterOperator reconciliation failed (attempt 1205), retrying.                                                        
W0220 08:40:00.868366       1 operator.go:627] Updating ClusterOperator status to failed after 1205 attempts.                                                         
E0220 08:40:00.879260       1 operator.go:502] Syncing "openshift-monitoring/cluster-monitoring-config" failed                                                        
E0220 08:40:00.879361       1 operator.go:503] sync "openshift-monitoring/cluster-monitoring-config" failed: cluster monitoring update failed (reason: UpdatingAlertmanagerFailed)

# Waiting for alertmanager openshift-monitoring/main during 4.6.34 to 4.7.16 upgrade
# https://bugzilla.redhat.com/show_bug.cgi?id=1976364
Bug 1976364 - Waiting for alertmanager openshift-monitoring/main during 4.6.34 to 4.7.16 upgrade

ocp4 project openshift-monitoring
ocp4 -n openshift-monitoring get pods
ocp4 -n openshift-monitoring get deployments
ocp4 -n openshift-monitoring get configmaps
ocp4 -n openshift-monitoring get configmaps prometheus-k8s-rulefiles-0 -o yaml 

# 参考 Bug 2021274 Comment 4
# https://bugzilla.redhat.com/show_bug.cgi?id=2021274

$ ocp4 -n openshift-monitoring get statefulsets
NAME                READY   AGE
alertmanager-main   0/0     8d
prometheus-k8s      2/2     8d

ocp4 -n openshift-monitoring get statefulsets prometheus-k8s -o yaml
ocp4 patch statefulset/prometheus-k8s -p '{"metadata":{"finalizers":null}}' --type=merge -n openshift-monitoring
ocp4 patch statefulset/alertmanager-main -p '{"metadata":{"finalizers":null}}' --type=merge -n openshift-monitoring

查看了一下，感觉不是 finalizers 的问题
# ocp4 -n openshift-monitoring logs $(ocp4 -n openshift-monitoring get po | grep prometheus-operator | awk '{print $1}') -c prometheus-operator | grep "tls: bad certificate"

# 查看 alertmanager.yaml 配置
oc -n openshift-monitoring get secret alertmanager-main --template='{{ index .data "alertmanager.yaml" }}' |base64 -d

# oc get co monitoring -oyaml
# oc -n openshift-monitoring get pod -o wide | grep -Ev "Completed|Running"
# oc -n openshift-monitoring describe pod ${not_running_pod}


# 参考 Bug 1953264
# https://bugzilla.redhat.com/show_bug.cgi?id=1953264

# 报错
# OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to console-openshift-console.apps.ocp4-1.example.com:443 
# curl -k -v https://console-openshift-console.apps.ocp4-1.example.com 
* Rebuilt URL to: https://console-openshift-console.apps.ocp4-1.example.com/
*   Trying 192.168.122.12...
* TCP_NODELAY set
* Connected to console-openshift-console.apps.ocp4-1.example.com (192.168.122.12) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/pki/tls/certs/ca-bundle.crt
  CApath: none
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to console-openshift-console.apps.ocp4-1.example.com:443 
* Closing connection 0
curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to console-openshift-console.apps.ocp4-1.example.com:443 


# oc2 get clusteroperators | grep -Ev " True        False         False" 
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
authentication                             4.9.9     False       False         True       15m     APIServerDeploymentAvailable: no apiserver.openshift-oauth-apiserver pods available on any node....
console                                    4.9.9     False       False         True       20m     RouteHealthAvailable: console route is not admitted
image-registry                             4.9.9     False       False         False      7m14s   NodeCADaemonAvailable: The daemon set node-ca does not have available replicas...
openshift-apiserver                        4.9.9     False       False         True       7m15s   APIServerDeploymentAvailable: no apiserver.openshift-apiserver pods available on any node....
operator-lifecycle-manager-packageserver   4.9.9     False       True          False      7m34s   ClusterServiceVersion openshift-operator-lifecycle-manager/packageserver observed in phase Failed with reason: InstallCheckFailed, message: install timeout

# https://github.com/openshift-metal3/dev-scripts/issues/721
查看 nodes
oc1 get nodes

查看 openshift-controller-manager 命名空间下的 pods 
oc1 get pods -n openshift-controller-manager

查看非 Running 和 Complete 状态的 pods，从中找无法启动的关键 pods
oc1 get pods -A  |grep -vE 'Running|Complete'


# 查看 crictl 相关命令
# https://kubernetes.io/zh/docs/tasks/debug-application-cluster/crictl/


I0221 07:44:29.958468       1 named_certificates.go:53] "Loaded SNI cert" index=0 certName="self-signed loopback" certDetail="\"
apiserver-loopback-client@1645429462\" [serving] validServingFor=[apiserver-loopback-client] issuer=\"apiserver-loopback-client-
ca@1645429461\" (2022-02-21 06:44:20 +0000 UTC to 2023-02-21 06:44:20 +0000 UTC (now=2022-02-21 07:44:29.958305661 +0000 UTC))"
I0221 07:44:30.418384       1 healthz.go:257] poststarthook/authorization.openshift.io-bootstrapclusterroles,poststarthook/authorization.openshift.io-ensureopenshift-infra check failed: healthz
[-]poststarthook/authorization.openshift.io-bootstrapclusterroles failed: not finished
[-]poststarthook/authorization.openshift.io-ensureopenshift-infra failed: not finished



oc -n openshift-kube-apiserver-operator logs kube-apiserver-operator-6b6548968f-tf94s -p 
...
I0221 06:44:08.729158       1 cmd.go:209] Using service-serving-cert provided certificates
I0221 06:44:08.754227       1 observer_polling.go:159] Starting file observer
W0221 06:44:08.876916       1 builder.go:220] unable to get owner reference (falling back to namespace): Get "https://172.30.0.1:443/api/v1/namespaces/op
enshift-kube-apiserver-operator/pods/kube-apiserver-operator-6b6548968f-tf94s": dial tcp 172.30.0.1:443: connect: connection refused
I0221 06:44:08.891150       1 builder.go:252] kube-apiserver-operator version 4.9.0-202111151318.p0.g3a02848.assembly.stream-3a02848-3a02848339e2e10e4522
031c1deaec9a6d553063
F0221 06:44:45.983306       1 cmd.go:138] unable to load configmap based request-header-client-ca-file: Get "https://172.30.0.1:443/api/v1/namespaces/kub
e-system/configmaps/extension-apiserver-authentication": dial tcp 172.30.0.1:443: connect: connection refused
goroutine 1 [running]:
k8s.io/klog/v2.stacks(0xc00013c001, 0xc0000ea300, 0x107, 0x2da)
        k8s.io/klog/v2@v2.9.0/klog.go:1026 +0xb9
k8s.io/klog/v2.(*loggingT).output(0x3d60ce0, 0xc000000003, 0x0, 0x0, 0xc0003d6700, 0x1, 0x31c38ec, 0x6, 0x8a, 0x414a00)
        k8s.io/klog/v2@v2.9.0/klog.go:975 +0x1e5
k8s.io/klog/v2.(*loggingT).printDepth(0x3d60ce0, 0xc000000003, 0x0, 0x0, 0x0, 0x0, 0x1, 0xc000260020, 0x1, 0x1)
        k8s.io/klog/v2@v2.9.0/klog.go:735 +0x185
k8s.io/klog/v2.(*loggingT).print(...)
        k8s.io/klog/v2@v2.9.0/klog.go:717
k8s.io/klog/v2.Fatal(...)
        k8s.io/klog/v2@v2.9.0/klog.go:1494
github.com/openshift/library-go/pkg/controller/controllercmd.(*ControllerCommandConfig).NewCommandWithContext.func1(0xc000526280, 0xc0005123c0, 0x0, 0x1)
        github.com/openshift/library-go@v0.0.0-20210915142033-188c3c82f817/pkg/controller/controllercmd/cmd.go:138 +0x7c5
github.com/spf13/cobra.(*Command).execute(0xc000526280, 0xc0005123b0, 0x1, 0x1, 0xc000526280, 0xc0005123b0)
        github.com/spf13/cobra@v1.1.3/command.go:856 +0x2c2
github.com/spf13/cobra.(*Command).ExecuteC(0xc000526000, 0xc000128000, 0xc000526000, 0xc000000180)
        github.com/spf13/cobra@v1.1.3/command.go:960 +0x375
github.com/spf13/cobra.(*Command).Execute(...)
        github.com/spf13/cobra@v1.1.3/command.go:897
main.main()
        github.com/openshift/cluster-kube-apiserver-operator/cmd/cluster-kube-apiserver-operator/main.go:45 +0x176


sudo crictl ps -a | grep apiserver

sudo crictl logs 76e2be6380138 2>&1 | grep -E "^E" 
E0221 09:46:49.532219      19 controller.go:152] Unable to remove old endpoints from kubernetes service: StorageError: key not found, Code: 1, Key: /kubernetes.io/masterleases/192.168.122.201, ResourceVersion: 0, AdditionalErrorMsg
...


oc1 get clusteroperators | grep -Ev "4.9.9     True        False         False" 
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
authentication                             4.9.9     False       False         True       24h     APIServerDeploymentAvailable: no apiserver.openshift-oauth-apiserver pods available on any node....
console                                    4.9.9     False       False         True       24h     DeploymentAvailable: 0 replicas available for console deployment...
image-registry                             4.9.9     True        False         True       88m     Degraded: The registry is removed...
ingress                                    4.9.9     True        False         True       8d      The "default" ingress controller reports Degraded=True: DegradedConditions: One or more other status conditions indicate a degraded state: DeploymentReplicasAllAvailable=False (DeploymentReplicasNotAvailable: 0/1 of replicas are available), CanaryChecksSucceeding=False (CanaryChecksRepetitiveFailures: Canary route checks for the default ingress controller are failing)
monitoring                                 4.9.9     False       True          True       19h     Rollout of the monitoring stack failed and is degraded. Please investigate the degraded status error.
openshift-apiserver                        4.9.9     False       False         True       19h     APIServerDeploymentAvailable: no apiserver.openshift-apiserver pods available on any node....
openshift-controller-manager               4.9.9     False       True          False      22h     Available: no daemon pods available on any node.
operator-lifecycle-manager-packageserver   4.9.9     False       True          False      151m    ClusterServiceVersion openshift-operator-lifecycle-manager/packageserver observed in phase Failed with reason: ComponentUnhealthy, message: APIServices not installed

# oc1 get pods -A | grep -Ev "Running|Complete" 
NAMESPACE                                          NAME                                                              READY   STATUS                 RESTARTS          AGE
hive                                               hive-clustersync-0                                                0/1     CreateContainerError   26 (15h ago)      4d19h
hive                                               hive-controllers-cbc6b85b7-5wltx                                  0/1     CreateContainerError   27 (15h ago)      4d19h
open-cluster-management                            application-chart-8923c-applicationui-94c4dbbbb-277wd             0/1     CreateContainerError   26 (15h ago)      4d23h
open-cluster-management                            assisted-service-56db4ff5c4-9xmlm                                 1/2     CreateContainerError   50 (6h39m ago)    25h
open-cluster-management                            clusterlifecycle-state-metrics-v2-5c6977f476-7t8zd                0/1     CreateContainerError   22 (21h ago)      4d23h
open-cluster-management                            console-chart-117b8-console-v2-8c54cbfc-lkwgk                     0/1     CrashLoopBackOff       250 (3m7s ago)    4d23h
open-cluster-management                            console-chart-117b8-console-v2-8c54cbfc-xkbq7                     0/1     CreateContainerError   30 (19h ago)      25h
open-cluster-management                            grc-09bbb-grcui-67756b9bcb-cgwnt                                  0/1     CreateContainerError   33 (10h ago)      4d23h
open-cluster-management                            grc-09bbb-grcuiapi-659856968c-5v4bd                               0/1     CreateContainerError   54 (161m ago)     4d23h
open-cluster-management                            infrastructure-operator-f9c86ccdd-8qp7r                           0/1     CreateContainerError   110 (10h ago)     4d23h
open-cluster-management                            management-ingress-a6e14-668f558b58-h7hln                         1/2     CreateContainerError   64 (10h ago)      4d23h
open-cluster-management                            multicluster-observability-operator-84955f78c5-5txxc              0/1     CreateContainerError   35 (15h ago)      8d
open-cluster-management                            multicluster-operators-application-6544f7c456-jgmsq               3/4     CreateContainerError   131 (32m ago)     8d
open-cluster-management                            multiclusterhub-operator-6c8f76c567-j6wj8                         0/1     CreateContainerError   35 (15h ago)      8d
openshift-apiserver                                apiserver-6668746879-97cmz                                        1/2     CreateContainerError   35 (19h ago)      8d
openshift-authentication                           oauth-openshift-76bcbd76d5-grsh5                                  0/1     CreateContainerError   49 (11h ago)      8d
openshift-config-operator                          openshift-config-operator-64b5bfcfc5-kwdbf                        0/1     CreateContainerError   83 (149m ago)     8d
openshift-console                                  console-5d6d74d7f5-s5b7f                                          0/1     CrashLoopBackOff       184 (94s ago)     8d
openshift-console                                  downloads-6f79767b7d-w2blh                                        0/1     CreateContainerError   28 (21h ago)      8d
openshift-controller-manager-operator              openshift-controller-manager-operator-586c7f66db-t4sk8            0/1     CreateContainerError   20 (21h ago)      8d
openshift-image-registry                           image-pruner-27423360--1-gwffp                                    0/1     Error                  1                 28h
openshift-image-registry                           image-pruner-27424800--1-bschh                                    0/1     Error                  0                 4h16m
openshift-ingress                                  router-default-d49579f44-pjf6m                                    0/1     CreateContainerError   32 (21h ago)      8d
openshift-kube-apiserver-operator                  kube-apiserver-operator-6b6548968f-tf94s                          0/1     CreateContainerError   21 (21h ago)      8d
openshift-marketplace                              marketplace-operator-5b95dfc48c-h85xg                             0/1     CreateContainerError   47 (12h ago)      8d
openshift-oauth-apiserver                          apiserver-6c7c6467c8-b6mmn                                        0/1     CreateContainerError   41 (10h ago)      8d
openshift-operator-lifecycle-manager               collect-profiles-27423240--1-4m8g2                                0/1     Error                  0                 20h
openshift-operator-lifecycle-manager               collect-profiles-27423240--1-89f7d                                0/1     Error                  0                 20h
openshift-operator-lifecycle-manager               collect-profiles-27423240--1-f8cbm                                0/1     Error                  9                 24h
openshift-operator-lifecycle-manager               collect-profiles-27423240--1-nk9kg                                0/1     Error                  0                 25h
openshift-operator-lifecycle-manager               collect-profiles-27423240--1-sq9kt                                0/1     Error                  3                 24h
openshift-operator-lifecycle-manager               collect-profiles-27423240--1-whjs2                                0/1     Error                  0                 30h
openshift-operator-lifecycle-manager               collect-profiles-27423240--1-zqwxb                                0/1     Error                  0                 20h
openshift-operator-lifecycle-manager               olm-operator-5574b98d98-jbwst                                     0/1     CreateContainerError   75 (150m ago)     8d

openshift-apiserver                                apiserver-6668746879-97cmz                                        1/2     CreateContainerError   35 (19h ago)      8d
openshift-kube-apiserver-operator                   kube-apiserver-operator-6b6548968f-tf94s                          0/1     CreateContainerError   21 (21h ago)      8d

oc1 -n openshift-kube-apiserver-operator describe pod kube-apiserver-operator-6b6548968f-tf94s 
...
Events:
  Type     Reason       Age                  From     Message
  ----     ------       ----                 ----     -------
  Warning  Failed       157m                 kubelet  Error: Kubelet may be retrying requests that are timing out in CRI-O due to system load: context deadline exceeded: error reserving ctr name k8s_kube-apiserver-operator_kube-apiserver-operator-6b6548968f-tf94s_openshift-kube-apiserver-operator_9314bf7b-6a09-451b-9c3e-9037f4252638_22 for id 3
0b38c9d5d1cf74325697bd33d50d4b9e99910d7abcf16f33e3517a799db8e5e: name is reserved
  Warning  FailedMount  122m (x32 over 22h)  kubelet  MountVolume.SetUp failed for volume "config" : failed to sync configmap cache: timed out waiting for the condition
  Warning  FailedMount  122m (x32 over 22h)  kubelet  MountVolume.SetUp failed for volume "serving-cert" : failed to sync secret cache: timed out waiting for the condition
  Warning  Failed       96m                  kubelet  Error: Kubelet may be retrying requests that are timing out in CRI-O due to system load: context deadline exceeded: error reserving ctr name k8s_kube-apiserver-operator_kube-apiserver-operator-6b6548968f-tf94s_openshift-kube-apiserver-operator_9314bf7b-6a09-451b-9c3e-9037f4252638_22 for id 1
625213ef89b3ad22acefb5e34f89e9a1d755dd9f0c900dd1e4befbaa4f34c18: name is reserved
  Warning  Failed       61m                  kubelet  Error: Kubelet may be retrying requests that are timing out in CRI-O due to system load: context deadline exceeded: error reserving ctr name k8s_kube-apiserver-operator_kube-apiserver-operator-6b6548968f-tf94s_openshift-kube-apiserver-operator_9314bf7b-6a09-451b-9c3e-9037f4252638_22 for id 6
2337fc7833640e086477388dd6aa97824c53286c65877827d9c48e76a2795a3: name is reserved
  Warning  FailedMount  51m (x28 over 22h)   kubelet  MountVolume.SetUp failed for volume "kube-api-access" : failed to sync configmap cache: timed out waiting for the condition
  Normal   Pulled       12m (x387 over 23h)  kubelet  Container image "quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:a86e33138fff72f19ed4015823e586cafafc68029bb29e39
e2cc93eb7f4eb21a" already present on machine
  Warning  Failed       75s (x324 over 23h)  kubelet  Error: context deadline exceeded

集群是在线集群，经过把 cpu 调大，集群终于恢复。image-registry operator 报 Degraded: The registry is removed...
oc get clusteroperators image-registry -o yaml 
  - lastTransitionTime: "2022-02-21T03:08:46Z"
    message: |-
      Degraded: The registry is removed
      ImagePrunerDegraded: Job has reached the specified backoff limit
    reason: ImagePrunerJobFailed::Removed
    status: "True"
    type: Degraded
# 解决方案
# https://access.redhat.com/solutions/5370391
# oc patch imagepruner.imageregistry/cluster --patch '{"spec":{"suspend":true}}' --type=merge
# oc -n openshift-image-registry delete jobs --all

测试环境下的 SNO 的硬件配置是 12 vcpu 以及 64 GB 内存

# brctl show 2>&1 | grep virbr0 -A4
virbr0          8000.5254004e2e84       yes             virbr0-nic
                                                        vnet0
                                                        vnet1
                                                        vnet2           # Hub interface
                                                        vnet3           # Spoke interface

# virsh domiflist jwang-ocp452-master0                                  # Hub cluster
Interface  Type       Source     Model       MAC
-------------------------------------------------------
vnet2      network    default    virtio      52:54:00:1c:14:57          # Hub interface

# virsh domiflist jwang-ocp452-master1                                  # Spoke cluster
Interface  Type       Source     Model       MAC
-------------------------------------------------------
vnet3      network    default    virtio      52:54:00:92:b4:e6          # Spoke interface


# vnet3 TX status / every minutes
    8984161608 5444819  0       0       0       0       
    8984267667 5445443  0       0       0       0       
    8984393722 5446014  0       0       0       0       
    8984511666 5446605  0       0       0       0       
    8984590970 5447106  0       0       0       0       
    8984656887 5447619  0       0       0       0       
    8984724713 5448156  0       0       0       0       
    8984832730 5448679  0       0       0       0       
    8984956720 5449307  0       0       0       0       
    8985036377 5449824  0       0       0       0 

# vnet3 TX bytes / every minutes
8984267667-8984161608 = 106059
8984393722-8984267667 = 126055
8984511666-8984393722 = 117944
8984590970-8984511666 = 79304
8984656887-8984590970 = 65917
8984724713-8984656887 = 67826
8984832730-8984724713 = 108017
8984956720-8984832730 = 123990
8985036377-8984956720 = 79657

# s3fs
# https://devninja.net/install-s3fs-on-aws-s3/

#!/bin/sh
date +%Y%m%d%H%M%S >> /tmp/link-status
echo '' >> /tmp/link-status
/usr/sbin/ip -s link show ens5 >> /tmp/link-status
echo '' >> /tmp/link-status

cat /tmp/link-status | grep -E "2022|0       0       0       0" | awk 'NR % 3 == 0'

# worker ens5 TX status / every minutes
    1464862589 721628   0       0       0       0       
    1511515340 735943   0       0       0       0       
    1521342737 742315   0       0       0       0       
    1525864993 747757   0       0       0       0       
    1530409740 753152   0       0       0       0       
    1543639053 759853   0       0       0       0       
    1586923101 771013   0       0       0       0       
    1616364195 780821   0       0       0       0       
    1620918129 786211   0       0       0       0       
    1625423670 791517   0       0       0       0       
    1629995814 796889   0       0       0       0     

# worker ens5 TX bytes / every minutes
1629995814-1625423670 = 4572144
1625423670-1620918129 = 4505541
1620918129-1616364195 = 4553934
1616364195-1586923101 = 29441094
1586923101-1543639053 = 43284048
1543639053-1530409740 = 13229313
1530409740-1525864993 = 4544747
1525864993-1521342737 = 4522256
1521342737-1511515340 = 9827397
1511515340-1464862589 = 46652751


# https://access.redhat.com/solutions/6542281
Invalid GPG signature for image certified-operator-index, redhat-marketplace-index, community-operator-index

1. 保存 /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv 文件
curl -s -o /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv https://www.redhat.com/security/data/55A34A82.txt
2. 保存 /etc/containers/policy.json 文件
cat > /etc/containers/policy.json <<EOF
{
  "default": [
      {
          "type": "insecureAcceptAnything"
      }
  ],
  "transports":
    {
      "docker-daemon":
          {
              "": [{"type":"insecureAcceptAnything"}]
          },
      "docker":
        {
          "registry.redhat.io/redhat/certified-operator-index": [
            {
              "type": "signedBy",
              "keyType": "GPGKeys",
              "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv"
            }
          ],
          "registry.redhat.io/redhat/community-operator-index": [
            {
              "type": "insecureAcceptAnything"
            }
          ],
          "registry.redhat.io/redhat/redhat-marketplace-index": [
            {
              "type": "signedBy",
              "keyType": "GPGKeys",
              "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv"
            }
          ],
          "registry.access.redhat.com": [
            {
              "type": "signedBy",
              "keyType": "GPGKeys",
              "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
            }
          ],
          "registry.redhat.io": [
            {
              "type": "signedBy",
              "keyType": "GPGKeys",
              "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
            }
          ]
        }
    }
}
EOF


# https://github.com/openshift-telco/ocp4-offline-operator-mirror/blob/main/redhat-operator-index.md
# 修剪或者查找 index image 的内容
# 了解哪些 operator 可以同步

curl -L https://github.com/fullstorydev/grpcurl/releases/download/v1.8.6/grpcurl_1.8.6_linux_x86_64.tar.gz -o grpcurl_1.8.6_linux_x86_64.tar.gz
tar -xvzf grpcurl_1.8.6_linux_x86_64.tar.gz -C /usr/local/bin
podman run --authfile pull-secret-full.json -p50051:50051 -it registry.redhat.io/redhat/redhat-operator-index:v4.9
podman run --authfile pull-secret-full.json -p50051:50051 -it registry.redhat.io/redhat/certified-operator-index:v4.9
podman run --authfile pull-secret-full.json -p50051:50051 -it registry.redhat.io/redhat/community-operator-index:v4.9
podman run --authfile pull-secret-full.json -p50051:50051 -it quay.io/operator-framework/upstream-community-operators:latest

# Looking at the Index using grpcurl
# 用 grpcurl 检查 index 内容
mkdir -p redhat-operator-index/v4.9
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > redhat-operator-index/v4.9/packages.out
cat redhat-operator-index/v4.9/packages.out
mkdir -p certified-operator-index/v4.9
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > certified-operator-index/v4.9/packages.out
cat certified-operator-index/v4.9/packages.out
mkdir -p community-operator-index/v4.9
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > community-operator-index/v4.9/packages.out
cat community-operator-index/v4.9/packages.out
mkdir -p upstream-community-operators/latest
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > upstream-community-operators/latest/packages.out
cat upstream-community-operators/latest/packages.out

cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
mirror:
  ocp:
    channels:
      - name: stable-4.9
        versions:
          - '4.9.9'
          - '4.9.10'
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.9
      headsOnly: false
      packages:
        - name: local-storage-operator
        - name: openshift-gitops-operator
        - name: advanced-cluster-management
        - name: redhat-oadp-operator
        - name: kubevirt-hyperconverged
        - name: odf-operator
        - name: odf-multicluster-orchestrator
    - catalog: registry.redhat.io/redhat/certified-operator-index:v4.9
      headsOnly: false
      packages:
        - name: elasticsearch-eck-operator-certified
    - catalog: registry.redhat.io/redhat/community-operator-index:v4.9
      headsOnly: false
      packages:
        - name: oadp-operator
        - name: grafana-operator
        - name: opendatahub-operator
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml file://output-dir

# https://www.jianshu.com/p/e3d8eb2a4295
# 设置 git ignore 忽略 .DS_Store 文件
cat > ~/.gitignore_global <<EOF
.DS_Store 
*/.DS_Store 
EOF

git config --global core.excludesfile ~/.gitignore_global
git rm --cached .DS_Store
find . -name .DS_Store -print0 | xargs -0 git rm --ignore-unmatch

# 安装中文语言包
yum install -y langpacks-zh_CN

# 通过 annotate 来设置 velero backup pods volumes
# https://blogs.oracle.com/cloud-infrastructure/post/backing-up-your-oke-environment-with-velero
kubectl -n testing annotate pod/oke-fsspod3 backup.velero.io/backup-volumes=oke-fsspv1


# oc-mirror 信息
error: unable to copy layer sha256:9e3fbf2caf74d81d9074643c3197ce375442f6fb9c57ee75b7b8e29c9bd6911a to file://container-native-virtualization/virt-operator: read 
tcp 10.66.208.130:58372->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:5803df1297c41013b5b4e4d729036ed2c445e81a0a1f69f6a080cd81bb7f9da8 to file://container-native-virtualization/virt-operator: read 
tcp 10.66.208.130:57848->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:36ed9651630573030fcb3301d7fe1f948e0407632cfa4c8ef3df7cf455e02b64 to file://container-native-virtualization/virt-operator: read 
tcp 10.66.208.130:57850->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:718bff4216ccf3f9d7905b03b3cdf78ac9cb0c348e171379590d9e0f7755166c to file://container-native-virtualization/virt-operator: read 
tcp 10.66.208.130:57796->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:1faceab815594ea7f9ef3545bd76321f5a30c97671240e6a7153dd93b50f06f9 to file://container-native-virtualization/virt-api: read tcp 1
0.66.208.130:58374->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:f82e74503fcfb5afd5f1e9d71afaeb27ac722a639f276a6c48274c5f002c4b07 to file://container-native-virtualization/virt-api: read tcp 1
0.66.208.130:58404->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:677bfa5b8f889cb60a34ce02911a4ee6882acc0f5b3101b24b93048de9ed8c80 to file://container-native-virtualization/virt-cdi-importer: r
ead tcp 10.66.208.130:58406->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:c07a3a47d08a9b28cf68d144e97683e34e93c99dfc6ffc924fca76ab2366930e to file://container-native-virtualization/virt-cdi-importer: r
ead tcp 10.66.208.130:58408->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:6d847cbbbd85fd693e28f7fedc117b290772d3bdde23f64b1de7dd2a414e674b to file://rhacm2/klusterlet-addon-rhel8-operator: read tcp 10.
66.208.130:58514->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:6d4e9f31661faf7b4e04c946f636bf6ffe279df92c73cd115e4ecf245b28c273 to file://container-native-virtualization/virt-launcher: read 
tcp 10.66.208.130:58512->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:bf7019a9259da8fde0f92524464fc25da5e960894409af345c9095eb6c376033 to file://rhacm2/klusterlet-addon-rhel8-operator: read tcp 10.
66.208.130:58770->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:667732b0891171852364c1e66b98506c40a3722eaf60829da194e49532c9a737 to file://rhacm2/klusterlet-addon-rhel8-operator: read tcp 10.
66.208.130:58520->104.74.144.107:443: read: connection reset by peer
error: unable to copy layer sha256:6e621b3c653a64515956100f21a430a15cca8152d400e4f8367c5519a7784157 to file://rhacm2/klusterlet-addon-rhel8-operator: read tcp 10.
66.208.130:58518->104.74.144.107:443: read: connection reset by peer
info: Mirroring completed in 3h49m34.36s (7.178MB/s)
error mirroring image: one or more errors occurred while uploading images
error: image "registry.redhat.io/container-native-virtualization/hostpath-provisioner-rhel8@sha256:70e6ab6a4a35d2b45effd355b0a0d9b76f1a35cd67cf1cb2944f2b70540385a
a" mapping "container-native-virtualization/hostpath-provisioner-rhel8": stat output-dir/oc-mirror-workspace/src/v2/container-native-virtualization/hostpath-provi
sioner-rhel8: no such file or directory

# Bypassing StackRox Admission Controller Enforcement in the CI/CD Pipeline
In case of emergency, add the annotation {"admission.stackrox.io/break-glass": "ticket-1234"} to your deployment with an updated ticket number
https://access.redhat.com/articles/5897721

# minio tenant 
oc new project minio-tenant-1
oc get namespace minio-tenant-1 -o=jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}{"\n"}'
1001010000/10000
oc project openshift-operators
oc get namespace minio-tenant-1 -o=jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}{"\n"}'
1001010000/10000


cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: minio-creds-secret
type: Opaque
data:
  accesskey: bWluaW8=
  secretkey: cjNkaDR0ITIzCg==
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: console-secret
type: Opaque
data:
  CONSOLE_PBKDF_PASSPHRASE: cmVkaGF0MTIzCg==
  CONSOLE_PBKDF_SALT: cmVkaGF0MTIzCg==
  CONSOLE_ACCESS_KEY: cmVkaGF0Cg==
  CONSOLE_SECRET_KEY: cmVkaGF0ITIzCg==
EOF


minio 报错
mc: <ERROR> Unable to initialize new alias from the provided credentials. The request signature we calculated does not match the signature you provided. Check your key and signing method.


Minio example
https://github.com/minio/operator/blob/master/examples/kustomization/tenant-tiny/tenant.yaml

# https://github.com/minio/operator/blob/master/docs/examples.md#minio-tenant-with-tls-via-customer-provided-certificates
mkcert "*.minio-tenant-1.svc.cluster.local"
mkcert "*.minio-tenant-1.minio-tenant-1.svc.cluster.local"
mkcert "*.minio-tenant-1-hl.minio-tenant-1.svc.cluster.local"

oc create secret tls minio-tls-cert --key="_wildcard.minio-tenant-1.svc.cluster.local-key.pem" --cert="_wildcard.minio-tenant-1.svc.cluster.local.pem" -n minio-tenant-1
oc create secret tls minio-buckets-cert --key="_wildcard.minio-tenant-1.minio-tenant-1.svc.cluster.local-key.pem" --cert="_wildcard.minio-tenant-1.minio-tenant-1.svc.cluster.local.pem" -n minio-tenant-1
oc create secret tls minio-hl-cert --key="_wildcard.minio-tenant-1-hl.minio-tenant-1.svc.cluster.local-key.pem" --cert="_wildcard.minio-tenant-1-hl.minio-tenant-1.svc.cluster.local.pem" -n minio-tenant-1

oc edit tenant minio-tenant-1 -n minio-tenant-1
...
  externalCertSecret:
    - name: minio-tls-cert
      type: kubernetes.io/tls
    - name: minio-buckets-cert
      type: kubernetes.io/tls
    - name: minio-hl-cert
      type: kubernetes.io/tls

# https://user-images.githubusercontent.com/30251247/111955614-b2378a80-8b24-11eb-8351-b89c653da7f1.png
# kube-controller:
#   extra_args:
#     cluster-signing-cert-file: "/etc/kubernetes/ssl/kube-ca.pem"
#     cluster-signing-key-file: "/etc/kubernetes/ssl/kube-ca-key.pem"

cat <<EOF | oc apply -f -
apiVersion: minio.min.io/v2
kind: Tenant
metadata:
  name: minio-tenant-1
  namespace: minio-tenant-1
spec:
  exposeServices:
    minio: true
    console: true
  credsSecret:
    name: minio-creds-secret
  requestAutoCert: false
  externalCertSecret:
    - name: minio-tls-cert
      type: kubernetes.io/tls
    - name: minio-buckets-cert
      type: kubernetes.io/tls
    - name: minio-hl-cert
      type: kubernetes.io/tls
  console:
    consoleSecret:
      name: console-secret
    replicas: 1
  ## Specification for MinIO Pool(s) in this Tenant.
  pools:
    ## Servers specifies the number of MinIO Tenant Pods / Servers in this pool.
    ## For standalone mode, supply 1. For distributed mode, supply 4 or more.
    ## Note that the operator does not support upgrading from standalone to distributed mode.
    - servers: 1
      ## volumesPerServer specifies the number of volumes attached per MinIO Tenant Pod / Server.
      volumesPerServer: 4
      ## This VolumeClaimTemplate is used across all the volumes provisioned for MinIO Tenant in this
      ## Pool.
      volumeClaimTemplate:
        metadata:
          name: data
        spec:
          accessModes:
            - ReadWriteOnce
          storageClassName: nfs-storage-provisioner-wait
          resources:
            requests:
              storage: 20Gi
EOF

# openshift wordpress + mysql template
https://raw.githubusercontent.com/jaredhocutt/openshift-wordpress/master/wordpress-mysql-template.yaml
oc project openshift
oc apply -f https://raw.githubusercontent.com/jaredhocutt/openshift-wordpress/master/wordpress-mysql-template.yaml

oc new-project wordrpess-test
oc new-app wordpress-mysql 

# OADP 与 Minio
# https://github.com/openshift/oadp-operator/blob/master/docs/config/noobaa/install_oadp_noobaa.md

创建 DataProtectionApplication velero-sample - 使用 minio 作为存储
cat <<EOF | oc apply -f -
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: velero-sample
spec:
  configuration:
    velero:
      defaultPlugins:
      - openshift
      - aws
  restic:
    enable: true
  backupLocations:
    - velero:
        config:
          profile: "default"
          region: minio
          s_3__url: minio-velero.apps.ocp1.rhcnsa.com
          s_3__force_path_style: "true"
          insecureSkipTLSVerify: "true"
        credential:
          name: cloud-credentials
          key: cloud
        objectStorage:
          bucket: velero
          prefix: velero
        provider: aws
        default: true
EOF

cat <<EOF | oc apply -f -
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: velero-sample
  namespace: openshift-adp
spec:
  olm_managed: true
  backup_storage_locations:
    - config:
        insecure_skip_tls_verify: true
        profile: default
        region: minio
        s_3__force_path_style: true
        s_3__url: 'http://minio-velero.apps.ocp1.rhcnsa.com'
        region: minio
      credentials_secret_ref:
        name: cloud-credentials
        namespace: openshift-adp
      name: default
      object_storage:
        bucket: velero
        prefix: velero
      provider: aws
  default_velero_plugins:
    - aws
    - openshift
  enable_restic: true
EOF

# 报错
# There is no existing backup storage location set as default

# 报错
time="2022-02-28T09:50:35Z" level=error msg="Error listing backups in backup store" backupLocation=velero-sample-1 controller=backup-sync error="rpc error: code = Unknown desc = InvalidAccessKeyId: The Access Key Id you provided does not exist in our records.\n\tstatus code: 403, request id: 16D7EA54037C55D3, host id: " error.file="/remote-source/app/velero-plugin-for-aws/object_store.go:384" error.function="main.(*ObjectStore).ListCommonPrefixes" logSource="pkg/controller/backup_sync_controller.go:182"

报错
time="2022-02-28T10:00:19Z" level=error msg="Error getting a backup store" backup-storage-location=velero-sample-1 controller=backup-storage-location error="rpc error: code = Unknown desc = config has invalid keys [insecure_skip_tls_verify s3_force_path_style s3_url]; valid keys are [region s3Url publicUrl kmsKeyId s3ForcePathStyle signatureVersion credentialsFile profile serverSideEncryption insecureSkipTLSVerify enableSharedConfig bucket prefix caCert]" error.file="/remote-source/deps/gomod/pkg/mod/github.com/vmware-tanzu/velero@v1.6.2/pkg/plugin/framework/validation.go:50" error.function=github.com/vmware-tanzu/velero/pkg/plugin/framework.validateConfigKeys logSource="pkg/controller/backup_storage_location_controller.go:100"

oc get secret cloud-credentials -o yaml -n openshift-adp
oc get backupstoragelocation -o yaml -n openshift-adp
oc get dpa -o yaml -n openshift-adp

# https://docs.google.com/document/d/1YkEQLmTVu4lS88xmoyQLAxYVm-BvrDusemPJptclvjQ/edit#
# 这个配置可以与 minio 工作在一起
# aws_access_key_id 和 aws_secret_access_key 不要加单引号
cat cloud-credentials
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
oc create secret generic cloud-credentials --namespace openshift-adp --from-file cloud=cloud-credentials

# 这个配置可以与 minio 工作在一起
cat <<EOF | oc apply -f -
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: dpa-sample
  namespace: openshift-adp
spec:
  backupLocations:
    - velero:
        config:
          profile: "default"
          region: minio
          s3Url: http://minio-velero.apps.ocp1.rhcnsa.com
          insecureSkipTLSVerify: "true" 
          s3ForcePathStyle: "true"
        credential:
          key: cloud
          name: cloud-credentials
        objectStorage:
          bucket: velero
          prefix: velero
        default: true
        provider: aws
  configuration:
    restic:
      enable: true
    velero:
      defaultPlugins:
        - aws
        - csi
        - openshift
    featureFlags:
    - EnableCSI
EOF

cat <<EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: gitea-persistent-1
  labels:
    velero.io/storage-location: default
  namespace: openshift-adp
spec:
  hooks: {}
  includedNamespaces:
  - gitea
  snapshotVolumes: false
  storageLocation: dpa-sample-1
  ttl: 2h0m0s
EOF

# 创建 restic 备份
# snapshotVolumes 设置为 false
cat <<EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: gitea-persistent-2
  labels:
    velero.io/storage-location: default
  namespace: openshift-adp
spec:
  hooks: {}
  includedNamespaces:
  - gitea
  snapshotVolumes: false
  storageLocation: dpa-sample-1
  ttl: 2h0m0s
EOF

cat <<EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: gitea
  namespace: openshift-adp
spec:
  backupName: gitea-persistent-1
  excludedResources:
  - nodes
  - events
  - events.events.k8s.io
  - backups.velero.io
  - restores.velero.io
  - resticrepositories.velero.io
  restorePVs: true
EOF

# https://blog.csdn.net/qianggezhishen/article/details/80764378
# 通过在 pv 里设定 labels，在 pvc 里设置 selector -> matchlables 将 pvc 绑定到特定 pv

MinIO 报错
# https://github.com/minio/operator/issues/983
# The solution is to move to the latest version of operator: v4.4.3

# 如果希望安装最新的 Minio Operator 需要创建 CatalogSource operatorhubio-operators
$ oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: operatorhubio-operators
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: quay.io/operator-framework/upstream-community-operators:latest
  displayName: OperatorHub.io Operators
  publisher: OperatorHub.io
EOF

$ oc -n openshift-operators logs minio-operator-689cf856f-2djfq
...
I0228 11:04:22.543972       1 main-controller.go:623] Waiting for the operator certificates to be issued the server could not find the requested resource
I0228 11:04:32.548784       1 main-controller.go:620] operator TLS secret not found%!(EXTRA string=secrets "operator-tls" not found)
E0228 11:04:32.550976       1 operator.go:104] Unexpected error during the creation of the csr/operator-openshift-operators-csr: the server could not find the requested resource

# 让 watch 与 alias 一起工作
alias watch='watch '
alias ll='ls -l '
watch ll

# 订阅 Elastic Cloud on Kubernetes Operator
$ oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: minio-operator
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: minio-operator
  source: operatorhubio-operators
  sourceNamespace: openshift-marketplace
EOF

报错
calculated deployment install is bad
# 参见 https://bugzilla.redhat.com/show_bug.cgi?id=1885398
https://github.com/operator-framework/operator-lifecycle-manager/blob/master/pkg/controller/operators/olm/operator.go#L1535
解决方法是
Edit the CSV to remove validating and mutating webhooks. Only left conversion webhook.
oc edit csv 


# 查看 olm catalog-operator 日志
ocp4 -n openshift-operator-lifecycle-manager logs catalog-operator-7b784489b9-q2dvv 
...
I0212 07:00:56.963088       1 event.go:282] Event(v1.ObjectReference{Kind:"Namespace", Namespace:"", Name:"openshift-sdn", UID:"aff65012-f357-4ca4-8f2c-259869fa2076", APIVersion:"v1", ResourceVersion:"419477570", FieldPath:""}): type: 'Warning' reason: 'ResolutionFailed' constraints not satisfiable: no operators found in channel 4.7 of package sriov-network-operator in the catalog referenced by subscription sriov-network-operator, subscription sriov-network-operator exists

报错
ResolutionFailed
ConstraintsNotSatisfiable
constraints not satisfiable: operatorhubio-operators/openshift-marketplace/stable/minio-operator.v4.4.9 and @existing/openshift-operators//minio-operator.v4.4.9 provide Tenant (minio.min.io/v1), clusterserviceversion minio-operator.v4.4.9 exists and is not referenced by a subscription, subscription minio-operator exists, subscription minio-operator requires operatorhubio-operators/openshift-marketplace/stable/minio-operator.v4.4.9

operatorhubio-operators/openshift-marketplace/stable/minio-operator.v4.4.9 && @existing/openshift-operators//minio-operator.v4.4.9 provide Tenant (minio.min.io/v1)

clusterserviceversion minio-operator.v4.4.9 && is not referenced by a subscription
subscription minio-operator exists
subscription minio-operator requires operatorhubio-operators/openshift-marketplace/stable/minio-operator.v4.4.9

# https://access.redhat.com/solutions/6751941
$ oc get events -n openshift-operators 
LAST SEEN   TYPE      REASON                OBJECT                                        MESSAGE
123m        Warning   FailedCreate          replicaset/console-84bbbd478b                 Error creating: pods "console-84bbbd478b-" is forbidden: unable to validate against any security context constraint: [provider "anyuid": Forbidden: not usable by user or serviceaccount, provider "pipelines-scc": Forbidden: not usable by user or serviceaccount, provider "stackrox-sensor": Forbidden: not usable by user or serviceaccount, spec.containers[0].securityContext.runAsUser: Invalid value: 1000: must be in the ranges: [1000380000, 1000389999], provider "nonroot": Forbidden: not usable by user or serviceaccount, provider "hostmount-anyuid": Forbidden: not usable by user or serviceaccount, provider "machine-api-termination-handler": Forbidden: not usable by user or serviceaccount, provider "hostnetwork": Forbidden: not usable by user or serviceaccount, provider "hostaccess": Forbidden: not usable by user or serviceaccount, provider "node-exporter": Forbidden: not usable by user or serviceaccount, provider "privileged": Forbidden: not usable by user or serviceaccount, provider "velero-privileged": Forbidden: not usable by user or serviceaccount]
158m        Normal    ScalingReplicaSet     deployment/console                            Scaled up replica set console-84bbbd478b to 1
123m        Warning   FailedCreate          replicaset/minio-operator-65f99cfd74          Error creating: pods "minio-operator-65f99cfd74-" is forbidden: unable to validate against any security context constraint: [provider "anyuid": Forbidden: not usable by user or serviceaccount, provider "pipelines-scc": Forbidden: not usable by user or serviceaccount, provider "stackrox-sensor": Forbidden: not usable by user or serviceaccount, spec.containers[0].securityContext.runAsUser: Invalid value: 1000: must be in the ranges: [1000380000, 1000389999], provider "nonroot": Forbidden: not usable by user or serviceaccount, provider "hostmount-anyuid": Forbidden: not usable by user or serviceaccount, provider "machine-api-termination-handler": Forbidden: not usable by user or serviceaccount, provider "hostnetwork": Forbidden: not usable by user or serviceaccount, provider "hostaccess": Forbidden: not usable by user or serviceaccount, provider "node-exporter": Forbidden: not usable by user or serviceaccount, provider "privileged": Forbidden: not usable by user or serviceaccount, provider "velero-privileged": Forbidden: not usable by user or serviceaccount]
168m        Normal    Killing               pod/minio-operator-689cf856f-2djfq            Stopping container minio-operator
158m        Normal    ScalingReplicaSet     deployment/minio-operator                     Scaled up replica set minio-operator-65f99cfd74 to 2
158m        Normal    RequirementsUnknown   clusterserviceversion/minio-operator.v4.4.9   requirements not yet checked
158m        Normal    RequirementsNotMet    clusterserviceversion/minio-operator.v4.4.9   one or more requirements couldn't be found
128m        Normal    AllRequirementsMet    clusterserviceversion/minio-operator.v4.4.9   all requirements found, attempting install
123m        Normal    InstallSucceeded      clusterserviceversion/minio-operator.v4.4.9   waiting for install components to report healthy
143m        Normal    NeedsReinstall        clusterserviceversion/minio-operator.v4.4.9   calculated deployment install is bad

# 查询 minio 相关的 packagemanifests
$ oc get packagemanifests -A | grep -i minio
openshift-marketplace   minio-operator                                      Certified Operators        226d
openshift-marketplace   minio-operator-rhmp                                 Red Hat Marketplace        226d
openshift-marketplace   minio-operator                                      OperatorHub.io Operators   18h

constraints not satisfiable: subscription minio-operator exists, @existing/openshift-operators//minio-operator.v4.4.9 and operatorhubio-operators/openshift-marketplace/stable/minio-operator.v4.4.9 provide Tenant (minio.min.io/v1), clusterserviceversion minio-operator.v4.4.9 exists and is not referenced by a subscription, subscription minio-operator requires operatorhubio-operators/openshift-marketplace/stable/minio-operator.v4.4.9
constraints not satisfiable: subscription minio-operator requires operatorhubio-operators/openshift-marketplace/stable/minio-operator.v4.4.9, subscription minio-operator exists, @existing/openshift-operators//minio-operator.v4.4.9 and operatorhubio-operators/openshift-marketplace/stable/minio-operator.v4.4.9 provide Tenant (minio.min.io/v1), clusterserviceversion minio-operator.v4.4.9 exists and is not referenced by a subscription

# 查看 channel 和 csv 
1. oc get packagemanifests -n openshift-marketplace minio-operator -o json | jq -r '.status.channels[] | {channel: .name, csv: .currentCSV}'

# 查看 installplan
2. oc get installplan -n openshift-operators

# 查看 operatorgroup
3. oc get operatorgroup -n openshift-operators

# 查看 csv
4. oc get csv -n openshift-operators

# 查看 deploy/catalog-operator 日志
5. oc logs -n openshift-operator-lifecycle-manager deploy/catalog-operator | grep '^E0'

# 查看 deploy/olm-operator 日志
6. oc logs -n openshift-operator-lifecycle-manager deploy/olm-operator | grep '^E0'


oc get subs gitea-operator -n openshift-operators -o yaml
...
  - lastTransitionTime: "2022-03-01T06:26:07Z"
    reason: ReferencedInstallPlanNotFound
    status: "True"
    type: InstallPlanMissing 
# https://bugzilla.redhat.com/show_bug.cgi?id=1744245
# https://bugzilla.redhat.com/show_bug.cgi?id=1895004

$ oc get pods -n openshift-operator-lifecycle-manager
NAME                                      READY   STATUS      RESTARTS      AGE
catalog-operator-7b784489b9-q2dvv         1/1     Running     0             18d

# 删除 openshift-operator-lifecycle-manager 下的 catalog-operator pod，这个 pod 会自动重建
$ oc delete pod catalog-operator-7b784489b9-q2dvv -n openshift-operator-lifecycle-manager

# minio 安装时的报错信息 events 报错信息
$ oc get events -n openshift-operators
LAST SEEN   TYPE      REASON                OBJECT                                        MESSAGE
3m50s       Warning   FailedCreate          replicaset/console-84bbbd478b                 Error creating: pods "console-84bbbd478b-" is forbidden: unable to validate against any security context constraint: [provider "anyuid": Forbidden: not usable by user or serviceaccount, provider "pipelines-scc": Forbidden: not usable by user or serviceaccount, provider "stackrox-sensor": Forbidden: not usable by user or serviceaccount, spec.containers[0].securityContext.runAsUser: Invalid value: 1000: must be in the ranges: [1000380000, 1000389999], provider "nonroot": Forbidden: not usable by user or serviceaccount, provider "hostmount-anyuid": Forbidden: not usable by user or serviceaccount, provider "machine-api-termination-handler": Forbidden: not usable by user or serviceaccount, provider "hostnetwork": Forbidden: not usable by user or serviceaccount, provider "hostaccess": Forbidden: not usable by user or serviceaccount, provider "node-exporter": Forbidden: not usable by user or serviceaccount, provider "privileged": Forbidden: not usable by user or serviceaccount, provider "velero-privileged": Forbidden: not usable by user or serviceaccount]
36m         Normal    ScalingReplicaSet     deployment/console                            Scaled up replica set console-84bbbd478b to 1
3m49s       Warning   FailedCreate          replicaset/minio-operator-65f99cfd74          Error creating: pods "minio-operator-65f99cfd74-" is forbidden: unable to validate against any security context constraint: [provider "anyuid": Forbidden: not usable by user or serviceaccount, provider "pipelines-scc": Forbidden: not usable by user or serviceaccount, provider "stackrox-sensor": Forbidden: not usable by user or serviceaccount, spec.containers[0].securityContext.runAsUser: Invalid value: 1000: must be in the ranges: [1000380000, 1000389999], provider "nonroot": Forbidden: not usable by user or serviceaccount, provider "hostmount-anyuid": Forbidden: not usable by user or serviceaccount, provider "machine-api-termination-handler": Forbidden: not usable by user or serviceaccount, provider "hostnetwork": Forbidden: not usable by user or serviceaccount, provider "hostaccess": Forbidden: not usable by user or serviceaccount, provider "node-exporter": Forbidden: not usable by user or serviceaccount, provider "privileged": Forbidden: not usable by user or serviceaccount, provider "velero-privileged": Forbidden: not usable by user or serviceaccount]
36m         Normal    ScalingReplicaSet     deployment/minio-operator                     Scaled up replica set minio-operator-65f99cfd74 to 2
36m         Normal    RequirementsUnknown   clusterserviceversion/minio-operator.v4.4.9   requirements not yet checked
36m         Normal    RequirementsNotMet    clusterserviceversion/minio-operator.v4.4.9   one or more requirements couldn't be found
6m57s       Normal    AllRequirementsMet    clusterserviceversion/minio-operator.v4.4.9   all requirements found, attempting install
117s        Normal    InstallSucceeded      clusterserviceversion/minio-operator.v4.4.9   waiting for install components to report healthy
36m         Normal    NeedsReinstall        clusterserviceversion/minio-operator.v4.4.9   calculated deployment install is bad

https://docs.min.io/minio/k8s/openshift/deploy-minio-tenant.html
oc get namespace openshift-operators -o=jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}{"\n"}'
1000380000/10000

oc project openshift-operators
oc adm policy add-scc-to-user anyuid -z minio-operator
oc patch deployment/cookbook --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

oc adm policy add-scc-to-user anyuid -z default -n minio-tenant-1
oc get statefulset 
oc patch statefulset/minio-tenant-1-ss-0 --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

8m19s       Normal    WaitForFirstConsumer   persistentvolumeclaim/data3-minio-tenant-1-ss-0-0   waiting for first consumer to be created before binding
2m19s       Normal    ExternalProvisioning   persistentvolumeclaim/data3-minio-tenant-1-ss-0-0   waiting for a volume to be created, either by external provisioner "nfs-storage" or manually created by system administrator
22s         Warning   ProvisioningFailed     persistentvolumeclaim/data3-minio-tenant-1-ss-0-0   failed to get target node: nodes "worker1.ocp4.rhcnsa.com" is forbidden: User "system:serviceaccount:nfs-provisioner:nfs-client-provisioner" cannot get resource "nodes" in API group "" at the cluster scope

$ oc project nfs-provisioner
$ oc adm policy add-scc-to-user privileged -z nfs-client-provisioner

https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/pull/71/files/2cad8da61c271f166e8a53c5c6866560e0466413
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]

  - verbs:
      - get
      - list
      - watch
    apiGroups:
      - ''
    resources:
      - nodes

MountVolume.SetUp failed for volume "minio-tenant-1-tls" : secret "minio-tenant-1-tls" not found

6m46s       Warning   FailedMount             pod/minio-tenant-1-ss-0-0                           Unable to attach or mount volumes: unmounted volumes=[minio-tenant-1-tls], unattached volumes=[minio-tenant-1-tls kube-api-access-bj5sm data0 data1 data2 data3]: timed out waiting for the condition
7m45s       Warning   FailedMount             pod/minio-tenant-1-ss-0-0                           MountVolume.SetUp failed for volume "minio-tenant-1-tls" : secret "minio-tenant-1-tls" not found

# https://github.com/minio/operator/issues/743
# Minio tenant stacked with 'Waiting for MinIO TLS Certificate' message #743

'minio-tenant-1/minio-tenant-1' Error waiting for pool to be ready: Get "https://minio-tenant-1-ss-0-0.minio-tenant-1-hl.minio-tenant-1.svc.cluster.local:9000/minio/admin/v3/info": x509: certificate signed by unknown authority

I0302 12:39:44.053123       1 main-controller.go:808] minio-tenant-1/minio-tenant-1 Detected we are adding a new pool
I0302 12:40:45.278290       1 monitoring.go:99] 'minio-tenant-1/minio-tenant-1' no pool is initialized
I0302 12:41:05.992717       1 main-controller.go:949] 'minio-tenant-1/minio-tenant-1' Error waiting for pool to be ready: Get "https://minio-tenant-1-ss-0-0.minio-tenant-1-hl.minio-tenant-1.svc.cluster.local:9000/minio/admin/v3/info": x509: certificate signed by unknown authority
E0302 12:41:05.992793       1 main-controller.go:559] error syncing 'minio-tenant-1/minio-tenant-1': Waiting for all pools to initialize

# https://github.com/minio/operator/blob/master/docs/examples.md#minio-tenant-with-tls-via-customer-provided-certificates

mkcert "*.minio-tenant-1.svc.cluster.local"
mkcert "*.minio-tenant-1.minio-tenant-1.svc.cluster.local"
mkcert "*.minio-tenant-1-hl.minio-tenant-1.svc.cluster.local"

oc create secret tls minio-tls-cert --key="_wildcard.minio-tenant-1.svc.cluster.local-key.pem" --cert="_wildcard.minio-tenant-1.svc.cluster.local.pem" -n minio-tenant-1
oc create secret tls minio-buckets-cert --key="_wildcard.minio-tenant-1.minio-tenant-1.svc.cluster.local-key.pem" --cert="_wildcard.minio-tenant-1.minio-tenant-1.svc.cluster.local.pem" -n minio-tenant-1
oc create secret tls minio-hl-cert --key="_wildcard.minio-tenant-1-hl.minio-tenant-1.svc.cluster.local-key.pem" --cert="_wildcard.minio-tenant-1-hl.minio-tenant-1.svc.cluster.local.pem" -n minio-tenant-1

oc edit tenant minio-tenant-1 -n minio-tenant-1
...
  externalCertSecret:
    - name: minio-tls-cert
      type: kubernetes.io/tls
    - name: minio-buckets-cert
      type: kubernetes.io/tls
    - name: minio-hl-cert
      type: kubernetes.io/tls

# Kubernetes Data Protection Working Group Minutes & Agenda
# https://docs.google.com/document/d/15tLCV3csvjHbKb16DVk-mfUmFry_Rlwo-2uG6KNGsfw/edit#heading=h.k81oezne6705

# LSO 与多路径
# https://bugzilla.redhat.com/show_bug.cgi?id=1980770

# 修剪 operator index image
opm index prune -f registry.redhat.io/redhat/redhat-operator-index:v4.9 -p cluster-kube-descheduler-operator,cluster-logging,compliance-operator, container-security-operator,cryostat-operator,elasticsearch-operator,idp-mgmt-operator-product, kiali-ossm,kubevirt-hyperconverged,local-storage-operator,metallb-operator,mtc-operator, mtv-operator,node-healthcheck-operator,ocs-operator,odf-multicluster-orchestrator,odf-operator, opentelemetry-product,performance-addon-operator,quay-bridge-operator,quay-operator,rhacs-operator, rhsso-operator,serverless-operator,service-registry-operator,servicemeshoperator,web-terminal -t $LOCAL_REGISTRY/olm-mirror/redhat-operator-index:v4.9

# fio 测试
# 随机读
fio -filename=/tmp/test_randread -direct=1 -iodepth 1 -thread -rw=randread -ioengine=psync -bs=16k -size=2G -numjobs=10 -runtime=60 -group_reporting -name=mytest

# 顺序读
fio -filename=/dev/sdb1 -direct=1 -iodepth 1 -thread -rw=read -ioengine=psync -bs=16k -size=2G -numjobs=10 -runtime=60 -group_reporting -name=mytest

# 随机写
fio -filename=/tmp/test_randwrite -direct=1 -iodepth 1 -thread -rw=randwrite -ioengine=psync -bs=16k -size=2G -numjobs=10 -runtime=60 -group_reporting -name=mytest

# 顺序写
fio -filename=/dev/sdb1 -direct=1 -iodepth 1 -thread -rw=write -ioengine=psync -bs=16k -size=2G -numjobs=10 -runtime=60 -group_reporting -name=mytest

# 混合随机读写
fio -filename=/dev/sdb1 -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=16k -size=2G -numjobs=10 -runtime=60 -group_reporting -name=mytest -ioscheduler=noop


podman save --format docker-dir -o ubi8 registry.access.redhat.com/ubi8/ubi:8.5-226.1645809065
podman load -i ubi8

cat > Dockerfile <<EOF
FROM localhost/ubi8:latest
COPY ./oc-mirror /usr/local/bin
ENTRYPOINT ["/usr/local/bin/oc-mirror", ""]
EOF

buildah bud -t oc-mirror:latest .

cat > /usr/local/bin/oc-mirror <<'EOF'
#!/bin/bash
#
# Doing it this way is just easier than trying to install python3 on EL7
# podman run --rm -ti --volume $(pwd):/srv:z localhost/filetranspiler:latest $*
podman run --rm --volume $(pwd):/srv:z localhost/oc-mirror:latest $*
##
##
EOF


08.518733   13982 kubelet_node_status.go:73] "Attempting to register node" node="master-0.ocp4-1.example.com"
08.519951   13982 kubelet_node_status.go:95] "Unable to register node with API server" err="nodes is forbidden: User \"system:anonymous\" cannot cr>
08.595079   13982 event.go:264] Server rejected event '&v1.Event{TypeMeta:v1.TypeMeta{Kind:"", APIVersion:""}, ObjectMeta:v1.ObjectMeta{Name:"maste>

报错
Mar 07 02:18:47 master-0.ocp4-1.example.com hyperkube[2753]: W0307 02:18:47.064370    2753 container.go:586] Failed to update stats for container "/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-podfc4ed746_d231_4ef0_bcce_46d4573e43d8.slice/crio-d712919bb68174a533360ac01f20a8364cc49cb0acd619ba04582867d9b38e05.scope": unable to determine device info for dir: /var/lib/containers/storage/overlay/8ac803a5779b49a3c2820fe2db4bcca24b28ffb55889fa87f3a1a4c685924c19/diff: stat failed on /var/lib/containers/storage/overlay/8ac803a5779b49a3c2820fe2db4bcca24b28ffb55889fa87f3a1a4c685924c19/diff with error: no such file or directory, continuing to push stats
# https://access.redhat.com/solutions/5748601
# 用类似思路
crictl rmi <image>
crictl pull <image>


1690495 ?        Zs     0:00 [conmon] <defunct>
1727495 ?        Z      0:00 [conmon] <defunct>
1884242 ?        Z      0:00 [conmon] <defunct>
# https://bugzilla.redhat.com/show_bug.cgi?id=1848524
# https://bugzilla.redhat.com/show_bug.cgi?id=1952137
[core@master-0 ~]$ sudo systemctl status crio
Failed to get properties: Connection timed out

检查SNO安装错误
sudo journalctl > /tmp/err 
sudo cat /tmp/err | grep -Ev "sudo|Succeeded|CEO|libpod|Started libcontainer|stat device|volatile|I0307" | tail -10

## 重要：重要：重要
# 在安装过程中，检查 SNO 节点的 /etc/containers/registries.conf 文件
# 如果内容不正确则重新生成这个文件
# 需重启 crio 服务，需重启 2 次，一次是 bootkube 阶段，一次是写入磁盘重启之后
cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', "docker.io"]
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-release"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer-agent"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer-agent"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2"
EOF
chmod a+r /etc/containers/registries.conf
systemctl restart crio.service

# 拷贝 registry.crt 到 master-0 
# 不清楚为什么 ignition 时没有将 registry.crt 和 registries.conf 文件写入到磁盘内
scp /etc/pki/ca-trust/source/anchors/registry.crt core@192.168.122.201:/tmp
ssh core@192.168.122.201 sudo cp /tmp/registry.crt /etc/pki/ca-trust/source/anchors
ssh core@192.168.122.201 sudo update-ca-trust

# 检查安装情况
cd /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs
kubectl --kubeconfig=./lb-ext.kubeconfig get nodes
kubectl --kubeconfig=./lb-ext.kubeconfig get clusterversion
kubectl --kubeconfig=./lb-ext.kubeconfig get clusteroperators
...
machine-config                                       False       True          True       26s     Cluster not available for 4.9.9

# 最后在安装完之后，需要修改 /etc/container/registries.conf 文件为
# 如果不修改回去，mcp 状态会不正常
cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', 'docker.io']
EOF

oc extract secret/pull-secret -n openshift-config --to=.
# 编辑 .dockerconfigjson 文件
# 移除 cloud.openshift.com JSON 片段
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=./.dockerconfigjson 

# 通过 mcp 更新 registries.conf 文件内容
cat > ./registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', "docker.io"]
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-release"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocp4/openshift4"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer"

[[registry]]
  prefix = ""
  location = "quay.io/ocpmetal/assisted-installer-agent"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ocpmetal/assisted-installer-agent"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2"
EOF

config_source=$(cat ./registries.conf | base64 -w 0 )

# machine config 例子
cat << EOF > ./99-master-zzz-registries-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: masters-registries-configuration
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
          source: data:text/plain;charset=utf-8;base64,${config_source}
          verification: {}
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf
  osImageURL: ""
EOF
oc apply -f ./99-master-zzz-registries-configuration.yaml

## 重要：重要：重要

# 阿里云 centos8 yum repo 问题解决
https://blog.tag.gg/showinfo-3-36184-0.html

rename '.repo' '.repo.bak' /etc/yum.repos.d/*.repo 
wget https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo -O /etc/yum.repos.d/Centos-vault-8.5.2111.repo
wget https://mirrors.aliyun.com/repo/epel-archive-8.repo -O /etc/yum.repos.d/epel-archive-8.repo

sed -i 's/mirrors.cloud.aliyuncs.com/url_tmp/g'  /etc/yum.repos.d/Centos-vault-8.5.2111.repo &&  sed -i 's/mirrors.aliyun.com/mirrors.cloud.aliyuncs.com/g' /etc/yum.repos.d/Centos-vault-8.5.2111.repo && sed -i 's/url_tmp/mirrors.aliyun.com/g' /etc/yum.repos.d/Centos-vault-8.5.2111.repo
sed -i 's/mirrors.aliyun.com/mirrors.cloud.aliyuncs.com/g' /etc/yum.repos.d/epel-archive-8.repo
yum clean all && yum makecache

parted -s /dev/sdb mklabel msdos 
parted -s /dev/sdb unit mib mkpart primary 1 100%
mkfs.xfs /dev/sdb1 


load average 高出天际
[core@master-0 ~]$ w
 04:42:11 up 23:21,  1 user,  load average: 1796.53, 1759.31, 1687.40
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
core     pts/0    192.168.122.15   04:41    4.00s  0.74s  0.21s w

[core@master-0 ~]$ w
 04:43:56 up 23:23,  1 user,  load average: 1790.65, 1763.70, 1696.40
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
core     pts/0    192.168.122.15   04:41    2.00s  0.76s  0.17s w

],Args:[],WorkingDir:,Ports:[]ContainerPort{},Env:[]EnvVar{EnvVar{Name:SERVICES,Value:image-registry.openshift-image-registry.svc,ValueFrom:nil,},EnvVar{Name:NAMESERVER,Value:172.30.0.10,ValueFrom:nil,},EnvVar{Name:CLUSTER_DOMAIN,Value:cluster.local,ValueFrom:nil,},},Resources:ResourceRequirements{Limits:ResourceList{},Requests:ResourceList{cpu: {{5 -3} {<nil>} 5m DecimalSI},memory: {{22020096 0} {<nil>} 21Mi BinarySI},},},VolumeMounts:[]VolumeMount{VolumeMount{Name:hosts-file,ReadOnly:false,MountPath:/etc/hosts,SubPath:,MountPropagation:nil,SubPathExpr:,},VolumeMount{Name:kube-api-access-r8d8c,ReadOnly:true,MountPath:/var/run/secrets/kubernetes.io/serviceaccount,SubPath:,MountPropagation:nil,SubPathExpr:,},},LivenessProbe:nil,ReadinessProbe:nil,Lifecycle:nil,TerminationMessagePath:/dev/termination-log,ImagePullPolicy:IfNotPresent,SecurityContext:&SecurityContext{Capabilities:nil,Privileged:*true,SELinuxOptions:nil,RunAsUser:nil,RunAsNonRoot:nil,ReadOnlyRootFilesystem:nil,AllowPrivilegeEscalation:nil,RunAsGroup:nil,ProcMount:nil,WindowsOptions:nil,SeccompProfile:nil,},Stdin:false,StdinOnce:false,TTY:false,EnvFrom:[]EnvFromSource{},TerminationMessagePolicy:FallbackToLogsOnError,VolumeDevices:[]VolumeDevice{},StartupProbe:nil,} start failed in pod node-resolver-jkqwb_openshift-dns(70718e05-af7d-462b-832b-5f539c9ed688): CreateContainerError: container create failed: time="2022-03-08T00:42:25-05:00" level=error msg="container_linux.go:370: starting container process caused: unknown capability \"CAP_PERFMON\""

# microshift 报错
# oc get pods -A 
openshift-dns                   node-resolver-jkqwb                   0/1     CreateContainerError   0          3h7m
...
E0308 06:02:51.021886       1 pod_workers.go:190] "Error syncing pod, skipping" err="failed to \"StartContainer\" for \"dns-node-resolver\" with CreateContainerError: \"container create failed: time=\\\"2022-03-08T01:02:50-05:00\\\" level=error msg=\\\"container_linux.go:370: starting container process caused: unknown capability \\\\\\\"CAP_PERFMON\\\\\\\"\\\"\\n\"" pod="openshift-dns/node-resolver-jkqwb" podUID=70718e05-af7d-462b-832b-5f539c9ed688

# 更新 libcap
# https://bugzilla.redhat.com/show_bug.cgi?id=1946982#c2

# etcd "took too long"
# 超 100 ms 报错
# https://access.redhat.com/solutions/5564771
# oc -n openshift-etcd logs etcd-master-0.ocp4-1.example.com -c etcd 2>&1 | grep "took too long"  
...
{"level":"warn","ts":"2022-03-09T01:59:18.782Z","caller":"etcdserver/util.go:166","msg":"apply request took too long","took":"215.870148ms","expected-duration":"200ms","prefix":"read-only range ","request":"key:\"/kubernetes.io/apiregistration.k8s.io/apiservices/v1.project.openshift.io\" ","response":"range_response_count:1 size:3290"}
{"level":"warn","ts":"2022-03-09T01:59:18.783Z","caller":"etcdserver/util.go:166","msg":"apply request took too long","took":"216.648539ms","expected-duration":"200ms","prefix":"read-only range ","request":"key:\"/kubernetes.io/configmaps/openshift-monitoring/grafana-dashboard-node-rsrc-use\" ","response":"range_response_count:1 size:37137"}
{"level":"warn","ts":"2022-03-09T01:59:18.783Z","caller":"etcdserver/util.go:166","msg":"apply request took too long","took":"288.145488ms","expected-duration":"200ms","prefix":"read-only range ","request":"key:\"/kubernetes.io/configmaps/open-cluster-management/klusterlet-addon-controller-lock\" ","response":"range_response_count:1 size:692"}

# oc rsh -n openshift-etcd etcd-master-0.ocp4-1.example.com etcdctl endpoint status --cluster -w table
Defaulted container "etcdctl" out of: etcdctl, etcd, etcd-metrics, etcd-health-monitor, setup (init), etcd-ensure-env-vars (init), etcd-resources-copy (init)
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|           ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://192.168.122.201:2379 | d0bb340a058a43d3 |   3.5.0 |  123 MB |      true |      false |         5 |    3787528 |            3787528 |        |
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+

# oc rsh -n openshift-etcd etcd-master-0.ocp4-1.example.com etcdctl endpoint status --cluster -w json
Defaulted container "etcdctl" out of: etcdctl, etcd, etcd-metrics, etcd-health-monitor, setup (init), etcd-ensure-env-vars (init), etcd-resources-copy (init)
[{"Endpoint":"https://192.168.122.201:2379","Status":{"header":{"cluster_id":12956385733825577103,"member_id":15040672598181168083,"revision":3722763,"raft_term":5},"version":"3.5.0","dbSize":123326464,"leader":15040672598181168083,"raftIndex":3791235,"raftTerm":5,"raftAppliedIndex":3791235,"dbSizeInUse":69120000}}]

# 可能的解决方法是执行 etcd defrag
# https://docs.openshift.com/container-platform/4.6/post_installation_configuration/cluster-tasks.html#etcd-defrag_post-install-cluster-tasks
# 单节点 SNO 清理
oc rsh -n openshift-etcd etcd-master-0.ocp4-1.example.com
unset ETCDCTL_ENDPOINTS
etcdctl --command-timeout=30s --endpoints=https://localhost:2379 defrag
Finished defragmenting etcd member[https://localhost:2379]
etcdctl endpoint status -w table --cluster
etcdctl alarm list

# 重启节点
Mar 09 02:32:34 master-0.ocp4-1.example.com hyperkube[2712]: [-]has-synced failed: reason withheld
Mar 09 02:32:34 master-0.ocp4-1.example.com hyperkube[2712]: [+]process-running ok
Mar 09 02:32:34 master-0.ocp4-1.example.com hyperkube[2712]: healthz check failed

# journalctl | grep -Ev "Trying to access|I0309" | tail -100 
Mar 09 00:47:16 master-0.ocp4-1.example.com hyperkube[2693]: E0309 00:47:16.282050    2693 kubelet.go:2170] "Housekeeping took longer than 15s" err="housekeeping took too
 long" seconds=62.208852755
 ...
Mar 09 00:48:13 master-0.ocp4-1.example.com hyperkube[2693]: E0309 00:48:13.797653    2693 remote_runtime.go:228] "CreateContainer in sandbox from runtime service failed"
 err="rpc error: code = DeadlineExceeded desc = context deadline exceeded" podSandboxID="5df472fc74ca530a36f9829f3df3df1582ce571d76fec3873abd2b76d8e73746"
Mar 09 00:48:13 master-0.ocp4-1.example.com hyperkube[2693]: E0309 00:48:13.800185    2693 kuberuntime_manager.go:898] container &Container{Name:klusterlet,Image:registry
.redhat.io/rhacm2/registration-rhel8-operator@sha256:e7e1b5545f4a4946f40cdd2101b5ccba9b947320debd1a244dd5244b3430a61b,Command:[],Args:[/registration-operator klusterlet],
WorkingDir:,Ports:[]ContainerPort{},Env:[]EnvVar{},Resources:ResourceRequirements{Limits:ResourceList{},Requests:ResourceList{},},VolumeMounts:[]VolumeMount{VolumeMount{N
ame:kube-api-access-nndlc,ReadOnly:true,MountPath:/var/run/secrets/kubernetes.io/serviceaccount,SubPath:,MountPropagation:nil,SubPathExpr:,},},LivenessProbe:&Probe{Handle
r:Handler{Exec:nil,HTTPGet:&HTTPGetAction{Path:/healthz,Port:{0 8443 },Host:,Scheme:HTTPS,HTTPHeaders:[]HTTPHeader{},},TCPSocket:nil,},InitialDelaySeconds:2,TimeoutSecond
s:1,PeriodSeconds:10,SuccessThreshold:1,FailureThreshold:3,TerminationGracePeriodSeconds:nil,},ReadinessProbe:&Probe{Handler:Handler{Exec:nil,HTTPGet:&HTTPGetAction{Path:
/healthz,Port:{0 8443 },Host:,Scheme:HTTPS,HTTPHeaders:[]HTTPHeader{},},TCPSocket:nil,},InitialDelaySeconds:2,TimeoutSeconds:1,PeriodSeconds:10,SuccessThreshold:1,Failure
Threshold:3,TerminationGracePeriodSeconds:nil,},Lifecycle:nil,TerminationMessagePath:/dev/termination-log,ImagePullPolicy:IfNotPresent,SecurityContext:&SecurityContext{Ca
pabilities:&Capabilities{Add:[],Drop:[KILL MKNOD SETGID SETUID],},Privileged:nil,SELinuxOptions:nil,RunAsUser:*1000700000,RunAsNonRoot:nil,ReadOnlyRootFilesystem:nil,Allo
wPrivilegeEscalation:nil,RunAsGroup:nil,ProcMount:nil,WindowsOptions:nil,SeccompProfile:nil,},Stdin:false,StdinOnce:false,TTY:false,EnvFrom:[]EnvFromSource{},TerminationM
essagePolicy:File,VolumeDevices:[]VolumeDevice{},StartupProbe:nil,} start failed in pod klusterlet-7747cc8c89-vqclz_open-cluster-management-agent(a88b429c-44e3-40d5-9be0-
6d91eca39b45): CreateContainerError: context deadline exceeded
...
Mar 09 02:58:07 master-0.ocp4-1.example.com hyperkube[2712]: E0309 02:58:07.588656    2712 pod_workers.go:836] "Error syncing pod, skipping" err="failed to \"StartContainer\" for \"cluster-image-registry-operator\" with CreateContainerError: \"context deadline exceeded\"" pod="openshift-image-registry/cluster-image-registry-operator-869b9fd7b-dx5jc" podUID=f87fade5-13c9-45bd-a1f2-e092cd7bf6e0


Mar 09 00:47:16 master-0.ocp4-1.example.com hyperkube[2693]: E0309 00:47:16.282050    2693 kubelet.go:2170] "Housekeeping took longer than 15s" err="housekeeping took too

Mar 09 00:47:17 master-0.ocp4-1.example.com hyperkube[2693]: E0309 00:47:17.145382    2693 cadvisor_stats_provider.go:415] "Partial failure issuing cadvisor.ContainerInfo
V2" err="partial failures: [\"/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-podf1260c98_d315_4534_b68a_d52c529be395.slice/crio-conmon-b7f7a98628d1a859e068f7
d285eaf6ece04c5f3021f7373bfb5ca0fb38afc5d7.scope\": RecentStats: unable to find data in memory cache], [\"/kubepods.slice/kubepods-besteffort.slice/kubepods-besteffort-po
da88b429c_44e3_40d5_9be0_6d91eca39b45.slice/crio-conmon-f50c9b7e1092e2d789cd557f51a1ddeef5f22286d581786cfcb885e86960e5b1.scope\": RecentStats: unable to find data in memo
ry cache], [\"/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-podd6d6bae0_8c1f_4466_b57e_5f3a3b9743fc.slice/crio-conmon-d2e7f6a9aaf0603f2ad4d7505efa30309d2a16
f9c2ab77394c2f65bab4f34243.scope\": RecentStats: unable to find data in memory cache], [\"/kubepods.slice/kubepods-besteffort.slice/kubepods-besteffort-poda88b429c_44e3_4
0d5_9be0_6d91eca39b45.slice/crio-fdcff3ab994e3893e23e75f9a383fa3fa70604c9103b2d2cc044b583023422c6.scope\": RecentStats: unable to find data in memory cache], [\"/kubepods
.slice/kubepods-burstable.slice/kubepods-burstable-podf1260c98_d315_4534_b68a_d52c529be395.slice/crio-5b8416a0b7991884ccd879609aec29d8e335b7c657992bf7038b6ec248fb3800.sco
pe\": RecentStats: unable to find data in memory cache]"


# cat /tmp/err | grep "Linux version 4.18.0" 
Mar 07 05:07:40 localhost kernel: Linux version 4.18.0-305.19.1.el8_4.x86_64 (mockbuild@x86-vm-09.build.eng.bos.redhat.com) (gcc version 8.4.1 20200928 (Red Hat 8.4.1-1) (GCC)) #1 SMP Tue Sep 7 07:07:31 EDT 2021
Mar 07 05:14:25 localhost kernel: Linux version 4.18.0-305.19.1.el8_4.x86_64 (mockbuild@x86-vm-09.build.eng.bos.redhat.com) (gcc version 8.4.1 20200928 (Red Hat 8.4.1-1) (GCC)) #1 SMP Tue Sep 7 07:07:31 EDT 2021
Mar 07 05:20:37 localhost kernel: Linux version 4.18.0-305.28.1.el8_4.x86_64 (mockbuild@x86-vm-08.build.eng.bos.redhat.com) (gcc version 8.4.1 20200928 (Red Hat 8.4.1-1) (GCC)) #1 SMP Mon Nov 8 07:45:47 EST 2021
Mar 08 04:47:11 localhost kernel: Linux version 4.18.0-305.28.1.el8_4.x86_64 (mockbuild@x86-vm-08.build.eng.bos.redhat.com) (gcc version 8.4.1 20200928 (Red Hat 8.4.1-1) (GCC)) #1 SMP Mon Nov 8 07:45:47 EST 2021
Mar 09 02:18:20 localhost kernel: Linux version 4.18.0-305.28.1.el8_4.x86_64 (mockbuild@x86-vm-08.build.eng.bos.redhat.com) (gcc version 8.4.1 20200928 (Red Hat 8.4.1-1) (GCC)) #1 SMP Mon Nov 8 07:45:47 EST 2021

journalctl | grep "Mar 07 05:20:37 localhost kernel: Linux version 4.18.0-305.28" -A200000 | grep "E0307" | tail -50 | more
...
Mar 07 23:55:24 master-0.ocp4-1.example.com hyperkube[25172]: E0307 23:55:24.579107   25172 manager.go:1132] Failed to create existing container: /kubepods.slice/kubepods
-burstable.slice/kubepods-burstable-pod781daf02_0425_4195_880c_82e842851cfa.slice/crio-dd0d932d6d729b873c8f4f0287a7c531b1148d6beb95c85f687a73b416ce63f4.scope: Error findi
ng container dd0d932d6d729b873c8f4f0287a7c531b1148d6beb95c85f687a73b416ce63f4: Status 404 returned error &{%!s(*http.body=&{0xc00a81cf90 <nil> <nil> false false {0 0} fal
se false false <nil>}) {%!s(int32=0) %!s(uint32=0)} %!s(bool=false) <nil> %!s(func(error) error=0x8944e0) %!s(func() error=0x894460)}


Mar 07 23:52:26 master-0.ocp4-1.example.com hyperkube[25172]: E0307 23:52:26.138197   25172 cadvisor_stats_provider.go:415] "Partial failure issuing cadvisor.ContainerInf
oV2" err="partial failures: [\"/kubepods.slice/kubepods-poda39c2f19_8f6c_46f7_8b49_8f43696bc3a4.slice\": RecentStats: unable to find data in memory cache], [\"/kubepods.s
lice/kubepods-poda0cb72ac_5d97_4aae_8f4c_41e50b2c799b.slice\": RecentStats: unable to find data in memory cache], [\"/kubepods.slice/kubepods-poda0cb72ac_5d97_4aae_8f4c_4
1e50b2c799b.slice/crio-5a9e7f14efe9bf354e33327f3afc5c27eede1815662e7ff76475ecaecf680a4e.scope\": RecentStats: unable to find data in memory cache]"
Mar 07 23:52:36 master-0.ocp4-1.example.com hyperkube[25172]: E0307 23:52:36.436249   25172 remote_runtime.go:144] "StopPodSandbox from runtime service failed" err="rpc e
rror: code = Unknown desc = failed to destroy network for pod sandbox k8s_installer-7-master-0.ocp4-1.example.com_openshift-kube-apiserver_a39c2f19-8f6c-46f7-8b49-8f43696
bc3a4_0(c70f0fafba5a8c3b472f9ddefe453745cc810c3364d038f1021ce95d91860f21): error removing pod openshift-kube-apiserver_installer-7-master-0.ocp4-1.example.com from CNI ne
twork \"multus-cni-network\": Multus: [openshift-kube-apiserver/installer-7-master-0.ocp4-1.example.com]: error getting pod: Get \"https://[api-int.ocp4-1.example.com]:64
43/api/v1/namespaces/openshift-kube-apiserver/pods/installer-7-master-0.ocp4-1.example.com?timeout=1m0s\": dial tcp 192.168.122.201:6443: connect: connection refused" pod
SandboxID="c70f0fafba5a8c3b472f9ddefe453745cc810c3364d038f1021ce95d91860f21"
Mar 07 23:52:36 master-0.ocp4-1.example.com hyperkube[25172]: E0307 23:52:36.436383   25172 kuberuntime_manager.go:992] "Failed to stop sandbox" podSandboxID={Type:cri-o 
ID:c70f0fafba5a8c3b472f9ddefe453745cc810c3364d038f1021ce95d91860f21}
Mar 07 23:52:36 master-0.ocp4-1.example.com hyperkube[25172]: E0307 23:52:36.436704   25172 kuberuntime_manager.go:752] "killPodWithSyncResult failed" err="failed to \"Ki
llPodSandbox\" for \"a39c2f19-8f6c-46f7-8b49-8f43696bc3a4\" with KillPodSandboxError: \"rpc error: code = Unknown desc = failed to destroy network for pod sandbox k8s_ins
taller-7-master-0.ocp4-1.example.com_openshift-kube-apiserver_a39c2f19-8f6c-46f7-8b49-8f43696bc3a4_0(c70f0fafba5a8c3b472f9ddefe453745cc810c3364d038f1021ce95d91860f21): er
ror removing pod openshift-kube-apiserver_installer-7-master-0.ocp4-1.example.com from CNI network \\\"multus-cni-network\\\": Multus: [openshift-kube-apiserver/installer
-7-master-0.ocp4-1.example.com]: error getting pod: Get \\\"https://[api-int.ocp4-1.example.com]:6443/api/v1/namespaces/openshift-kube-apiserver/pods/installer-7-master-0
.ocp4-1.example.com?timeout=1m0s\\\": dial tcp 192.168.122.201:6443: connect: connection refused\""


Mar 07 23:52:26 master-0.ocp4-1.example.com hyperkube[25172]: E0307 23:52:26.138197   25172 cadvisor_stats_provider.go:415] "Partial failure issuing cadvisor.ContainerInf
oV2" err="partial failures: [\"/kubepods.slice/kubepods-poda39c2f19_8f6c_46f7_8b49_8f43696bc3a4.slice\": RecentStats: unable to find data in memory cache], [\"/kubepods.s
lice/kubepods-poda0cb72ac_5d97_4aae_8f4c_41e50b2c799b.slice\": RecentStats: unable to find data in memory cache], [\"/kubepods.slice/kubepods-poda0cb72ac_5d97_4aae_8f4c_4
1e50b2c799b.slice/crio-5a9e7f14efe9bf354e33327f3afc5c27eede1815662e7ff76475ecaecf680a4e.scope\": RecentStats: unable to find data in memory cache]"
...
Mar 07 23:52:28 master-0.ocp4-1.example.com hyperkube[25172]: I0307 23:52:28.159365   25172 kubelet.go:2083] "SyncLoop UPDATE" source="api" pods=[hive/hiveadmission-88b6f
9c76-tj5mw]
Mar 07 23:52:28 master-0.ocp4-1.example.com hyperkube[25172]: W0307 23:52:28.177987   25172 manager.go:1185] Failed to process watch event {EventType:0 Name:/kubepods.sli
ce/kubepods-besteffort.slice/kubepods-besteffort-pod942ed859_6473_4d35_896a_3875885ac616.slice/crio-a7e299cefe7c5b2df12b8709c3c0d44599a5a7ce4fc68e7fe41c551f5bd1ed55.scope
 WatchSource:0}: Error finding container a7e299cefe7c5b2df12b8709c3c0d44599a5a7ce4fc68e7fe41c551f5bd1ed55: Status 404 returned error &{%!s(*http.body=&{0xc0089ba888 <nil>
 <nil> false false {0 0} false false false <nil>}) {%!s(int32=0) %!s(uint32=0)} %!s(bool=false) <nil> %!s(func(error) error=0x8944e0) %!s(func() error=0x894460)}
Mar 07 23:52:28 master-0.ocp4-1.example.com crio[1656]: time="2022-03-07 23:52:28.197060704Z" level=info msg="Ran pod sandbox a7e299cefe7c5b2df12b8709c3c0d44599a5a7ce4fc6
8e7fe41c551f5bd1ed55 with infra container: hive/hiveadmission-88b6f9c76-tj5mw/POD" id=d92aca08-0340-4a2d-8757-bc087fe1f95b name=/runtime.v1alpha2.RuntimeService/RunPodSan
dbox
Mar 07 23:52:28 master-0.ocp4-1.example.com crio[1656]: time="2022-03-07 23:52:28.224210232Z" level=info msg="Checking image status: registry.redhat.io/rhacm2/openshift-h
ive-rhel8@sha256:3a52b2d426fdce810ce8be2bc16bdafcbd0e41fef4ac5af0cf23a11ddfb875c5" id=37c069e2-c59b-46a9-9697-620be5e52f6f name=/runtime.v1alpha2.ImageService/ImageStatus
Mar 07 23:52:28 master-0.ocp4-1.example.com crio[1656]: time="2022-03-07 23:52:28.304400983Z" level=info msg="Image status: &{0xc002dfdce0 map[]}" id=37c069e2-c59b-46a9-9
697-620be5e52f6f name=/runtime.v1alpha2.ImageService/ImageStatus
Mar 07 23:52:28 master-0.ocp4-1.example.com crio[1656]: time="2022-03-07 23:52:28.314449435Z" level=info msg="Pulling image: registry.redhat.io/rhacm2/openshift-hive-rhel
8@sha256:3a52b2d426fdce810ce8be2bc16bdafcbd0e41fef4ac5af0cf23a11ddfb875c5" id=de64745c-8c51-47d2-9f1f-3a6c38c91a23 name=/runtime.v1alpha2.ImageService/PullImage

[core@master-0 ~]$ sudo ps awx | grep -Ev "Ssl|Ss|S\+| S "  | more


-----BEGIN CERTIFICATE-----
MIIDYzCCAkugAwIBAgIIQRP3xrlQftgwDQYJKoZIhvcNAQELBQAwJjEkMCIGA1UE
AwwbaW5ncmVzcy1vcGVyYXRvckAxNjI2NjA2MTU2MB4XDTIxMDcxODExMDIzOFoX
DTIzMDcxODExMDIzOVowITEfMB0GA1UEAwwWKi5hcHBzLm9jcDQucmhjbnNhLmNv
bTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOPdR9qh1gTs1iUqUcK8
IDhekCUPmJywFwRuatzydztAPcGDvj4Y5GWx2pu+D8BD2A+Q3F59904BZWb4FlTe
6kDoMvcXr9Y5HGsfIMQpJ5GdFGzNg0veDu88K1P4NAmK5C+FKVYKb83wBja/x7Ys
3g0oqXaQuESY83okJCM3zplPcXxFyqVgrC7E9A/TNJsuZvRZWGfQHIUrxsUPEiVT
jp8AwOcmyAEocm5mdNWThQGvBARdmuKuySb1/03BNbKD7qmj5x8/dz3rCyF7ufz3
JOXsKzCuv5VGBx+IEg9IX+rvlNd2MCq/dJy3oAUrSEYUjOi4ZZ/OH87fndXuMNKC
eesCAwEAAaOBmTCBljAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYBBQUH
AwEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUpW/Kg6qjguBcMYBqbilYtopB4E0w
HwYDVR0jBBgwFoAULmTEKt6hRTncC2BADMSke8A25rgwIQYDVR0RBBowGIIWKi5h
cHBzLm9jcDQucmhjbnNhLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAB97KrWlCuUgV
gcZKqw800F4VOiJGXxsEQhHQ1EMfaBNkV51LBWLiD0iJND9UDL3nOVK0DTXLNbh6
kofsI21vo3/XsJ/BofC6Pu1kFGqNiztVMh4BogCQSXkIu4K3wM04kgsj5Ynh4/Vz
3UpUqR9q7AkqBgEEX55ytIY1l/Py/KnBgj3DGVLEQuJnOOyyhsPoKFz9pMOJ/r4+
zJ+L0bpLRjsH1Zb7OPodzTHMCqPgdY/b7YOYtQcFYHSrtP5dmIIlUoLdqgCAlBGb
oIAtkZlQQFudmI6p28zbmV3zoAsY9QSFv6Gg4Eiik+lttgy86yk6OqdSF+K2kwXQ
qairhQ9Log==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDDDCCAfSgAwIBAgIBATANBgkqhkiG9w0BAQsFADAmMSQwIgYDVQQDDBtpbmdy
ZXNzLW9wZXJhdG9yQDE2MjY2MDYxNTYwHhcNMjEwNzE4MTEwMjM2WhcNMjMwNzE4
MTEwMjM3WjAmMSQwIgYDVQQDDBtpbmdyZXNzLW9wZXJhdG9yQDE2MjY2MDYxNTYw
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDB5Fjs4hC5Ade8DwMP6n46
kmSz6pNLVYIkiLLgPFrG6d17Sn5UCqujlrP9fE1o9Q4BQeeu29k43sOQ/sIKljzu
3ArOYTZvb1kaflMwJvmn0MagFR1TnSDB8kwnDeAZcdO0FK8JhJ85UDeEinF4rb1v
zf4dJEoU3pNXY9hT47vqsXo3oB59DsrbtM2ythAPkZ9vv3G0kC0HOl8rjf9IJX4V
lZZazvLv92euVyOtIHPgpbnrRUc74kWf8n5pzUDL13oFNaBMGabC+3fq8XaSwIb4
6CGLW3BFfxy+2xEToUJ+aZqNRzR+hdy3+V/Wm57I/img/FVQJ/tkBlricupcOWcP
AgMBAAGjRTBDMA4GA1UdDwEB/wQEAwICpDASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
A1UdDgQWBBQuZMQq3qFFOdwLYEAMxKR7wDbmuDANBgkqhkiG9w0BAQsFAAOCAQEA
JRWfbK0Czhoi2r/RnBHjU+PyQsSIlflgdn96N1FgevsHCz/w7wjvyYbNtdlgF+wj
KH0EwB8cR5clKIESkGsGBjUjDytrUwofpbgFt2B+Ec+iaaaVdI1F3kb/uI7XF5S1
eAVgZtPpSYkro8tCUR+fFAgypnkAkeNyYQMVX5tPTAiFrO7nO5RXdbi/Lrb68cQZ
d/rE+5X3JtgYwILS+cxVS+ScAOQfPQspsgLIXq+OitU1a8z2QvdWKK+c9sCvcXjS
I0yijITLiFyWuNLvK3wAUswYBRg9sXZX5OAKU51amR/POiVqnPPQYlJQk//JmRij
KGh+it3EJJlVTH6jVLkpEA==
-----END CERTIFICATE-----

quay.io/coreos/flannel:v0.14.0
quay.io/microshift/flannel-cni:4.8.0-0.okd-2021-10-10-030117



# quay.io/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920
skopeo copy --format v2s2 --all docker://quay.io/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920 docker://quay.ocp4.rhcnsa.com/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920

# quay.io/microshift/microshift:4.8.0-0.microshift-2022-01-06-210147
skopeo copy --format v2s2 --authfile /root/.docker/config.json --all docker://quay.io/microshift/microshift:4.8.0-0.microshift-2022-01-06-210147 docker://quay.ocp4.rhcnsa.com/microshift/microshift:4.8.0-0.microshift-2022-01-06-210147

# quay.io/microshift/flannel-cni:4.8.0-0.okd-2021-10-10-030117
skopeo copy --format v2s2 --authfile /root/.docker/config.json --all docker://quay.io/microshift/flannel-cni:4.8.0-0.okd-2021-10-10-030117 docker://quay.ocp4.rhcnsa.com/microshift/flannel-cni:4.8.0-0.okd-2021-10-10-030117

# quay.io/coreos/flannel:v0.14.0
skopeo copy --format v2s2  --authfile /root/.docker/config.json --all docker://quay.io/coreos/flannel:v0.14.0 docker://quay.ocp4.rhcnsa.com/coreos/flannel:v0.14.0

# quay.io/kubevirt/hostpath-provisioner:v0.8.0
skopeo copy --format v2s2 --authfile /root/.docker/config.json --all docker://quay.io/kubevirt/hostpath-provisioner:v0.8.0 docker://quay.ocp4.rhcnsa.com/kubevirt/hostpath-provisioner:v0.8.0

# quay.io/openshift/okd-content@sha256:bcdefdbcee8af1e634e68a850c52fe1e9cb31364525e30f5b20ee4eacb93c3e8
skopeo copy --format v2s2 --authfile /root/.docker/config.json --all docker://quay.io/openshift/okd-content@sha256:bcdefdbcee8af1e634e68a850c52fe1e9cb31364525e30f5b20ee4eacb93c3e8 docker://quay.ocp4.rhcnsa.com/openshift/okd-content@sha256:bcdefdbcee8af1e634e68a850c52fe1e9cb31364525e30f5b20ee4eacb93c3e8

# quay.io/openshift/okd-content@sha256:459f15f0e457edaf04fa1a44be6858044d9af4de276620df46dc91a565ddb4ec
skopeo copy --format v2s2 --authfile /root/.docker/config.json --all docker://quay.io/openshift/okd-content@sha256:459f15f0e457edaf04fa1a44be6858044d9af4de276620df46dc91a565ddb4ec docker://quay.ocp4.rhcnsa.com/openshift/okd-content@sha256:459f15f0e457edaf04fa1a44be6858044d9af4de276620df46dc91a565ddb4ec

# quay.io/openshift/okd-content@sha256:27f7918b5f0444e278118b2ee054f5b6fadfc4005cf91cb78106c3f5e1833edd
skopeo copy --format v2s2 --authfile /root/.docker/config.json --all docker://quay.io/openshift/okd-content@sha256:27f7918b5f0444e278118b2ee054f5b6fadfc4005cf91cb78106c3f5e1833edd docker://quay.ocp4.rhcnsa.com/openshift/okd-content@sha256:27f7918b5f0444e278118b2ee054f5b6fadfc4005cf91cb78106c3f5e1833edd

# quay.io/openshift/okd-content@sha256:01cfbbfdc11e2cbb8856f31a65c83acc7cfbd1986c1309f58c255840efcc0b64
skopeo copy --format v2s2 --authfile /root/.docker/config.json --all docker://quay.io/openshift/okd-content@sha256:01cfbbfdc11e2cbb8856f31a65c83acc7cfbd1986c1309f58c255840efcc0b64 docker://quay.ocp4.rhcnsa.com/openshift/okd-content@sha256:01cfbbfdc11e2cbb8856f31a65c83acc7cfbd1986c1309f58c255840efcc0b64

# quay.io/openshift/okd-content@sha256:dd1cd4d7b1f2d097eaa965bc5e2fe7ebfe333d6cbaeabc7879283af1a88dbf4e
skopeo copy --format v2s2 --authfile /root/.docker/config.json --all docker://quay.io/openshift/okd-content@sha256:dd1cd4d7b1f2d097eaa965bc5e2fe7ebfe333d6cbaeabc7879283af1a88dbf4e docker://quay.ocp4.rhcnsa.com/openshift/okd-content@sha256:dd1cd4d7b1f2d097eaa965bc5e2fe7ebfe333d6cbaeabc7879283af1a88dbf4e



cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ['registry.example.com:5000']
 
[[registry]]
  prefix = ""
  location = "quay.io/openshift/okd-content"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/openshift/okd-content"

[[registry]]
  prefix = ""
  location = "quay.io/microshift/flannel-cni"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/microshift/flannel-cni"

[[registry]]
  prefix = ""
  location = "quay.io/coreos/flannel"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/coreos/flannel"    

[[registry]]
  prefix = ""
  location = "quay.io/kubevirt/hostpath-provisioner"
  mirror-by-digest-only = false
 
  [[registry.mirror]]
    location = "registry.example.com:5000/kubevirt/hostpath-provisioner"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2"
EOF


skopeo copy --format v2s2 --authfile /root/.docker/config.json --all docker://k8s.gcr.io/pause:3.5 docker://quay.ocp4.rhcnsa.com/pause/pause:3.5


mkdir ~/kubeconfig/edge-1
scp root@microshift-for-gree:/var/lib/microshift/resources/kubeadmin/kubeconfig ~/kubeconfig/edge-1

EDGE_1_IP="xxxx"
gsed -i "s|127.0.0.1|${EDGE_1_IP}|g" ~/kubeconfig/edge-1/kubeconfig

oc --kubeconfig=/Users/junwang/kubeconfig/edge-1/kubeconfig get nodes

# 清理 microshift
# systemctl stop microshift
# cd /var/lib/containers
# ls /var/lib/containers
cache  sigstore  storage
# rm -rf /var/lib/containers/cache/*
# rm -rf /var/lib/containers/sigstore/*
# rm -rf /var/lib/containers/storage/*
# hostnamectl set-hostname edge-1.ocp4.rhcnsa.com
# nmcli con mod 'System eth0' +ipv4.address <ip/mask>
# systemctl start microshift

# 查看证书
openssl s_client -host <ocp-app> -port 443 -prexit -showcerts </dev/null

# 清理容器存储
# https://access.redhat.com/solutions/5350721
# oc adm drain master0.ocp4.rhcnsa.com --ignore-daemonsets --delete-local-data
# systemctl stop kubelet
# crictl stopp `crictl pods -q`        ##  "stopp" with two "p" for stopping pods
# crictl stop `crictl ps -aq`
# crictl rmp `crictl pods -q`
# rm -rf /var/lib/containers/*
# crio wipe -f
# systemctl disable kubelet crio
# systemctl enable kubelet crio
# systemctl start crio kubelet
# oc get nodes
# oc adm uncordon NODENAME

(ocp4)[root@helper ~]# oc -n openshift-etcd get pods
NAME                                        READY   STATUS      RESTARTS        AGE
etcd-master0.ocp4.rhcnsa.com                4/4     Running     17              26d
etcd-master1.ocp4.rhcnsa.com                4/4     Running     13              26d
etcd-master2.ocp4.rhcnsa.com                3/4     Running     5 (2d21h ago)   26d

# https://access.redhat.com/solutions/5564771
# oc -n openshift-etcd logs etcd-master2.ocp4.rhcnsa.com  -c etcd 2>&1 | grep "took too long"
# oc rsh -n openshift-etcd etcd-master0.ocp4.rhcnsa.com etcdctl endpoint status --cluster -w table
(ocp4)[root@helper ~]# oc rsh -n openshift-etcd etcd-master0.ocp4.rhcnsa.com etcdctl endpoint status --cluster -w table 
Defaulted container "etcdctl" out of: etcdctl, etcd, etcd-metrics, etcd-health-monitor, setup (init), etcd-ensure-env-vars (init), etcd-resources-copy (init)
+-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|          ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://172.26.168.103:2379 | 32fc244bb2fa43b7 |   3.5.0 |  1.3 GB |     false |      false |     13551 |  692073093 |          692073093 |        |
| https://172.26.168.102:2379 | 6d0d0c6969d26184 |   3.5.0 |  1.3 GB |     false |      false |     13551 |  692073095 |          692073095 |        |
| https://172.26.168.104:2379 | 83679cd94c4fae94 |   3.5.0 |  1.3 GB |      true |      false |     13551 |  692073095 |          692073095 |        |
+-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+


https://docs.openshift.com/container-platform/4.6/post_installation_configuration/cluster-tasks.html#etcd-defrag_post-install-cluster-tasks

# 非 leader 
oc -n openshift-etcd rsh etcd-master0.ocp4.rhcnsa.com
sh-4.4# unset ETCDCTL_ENDPOINTS
sh-4.4# etcdctl --command-timeout=30s --endpoints=https://localhost:2379 defrag
Finished defragmenting etcd member[https://localhost:2379]
sh-4.4# etcdctl endpoint status -w table --cluster

oc -n openshift-etcd rsh etcd-master1.ocp4.rhcnsa.com
sh-4.4# unset ETCDCTL_ENDPOINTS
sh-4.4# etcdctl --command-timeout=30s --endpoints=https://localhost:2379 defrag
Finished defragmenting etcd member[https://localhost:2379]
sh-4.4# etcdctl endpoint status -w table --cluster

# 最后处理 leader
oc -n openshift-etcd rsh etcd-master2.ocp4.rhcnsa.com
sh-4.4# unset ETCDCTL_ENDPOINTS
sh-4.4# etcdctl --command-timeout=30s --endpoints=https://localhost:2379 defrag
Finished defragmenting etcd member[https://localhost:2379]
sh-4.4# etcdctl endpoint status -w table --cluster

network                                    4.9.18    True        True          False      234d    DaemonSet "openshift-network-diagnostics/network-check-target" is not available (awaiting 1 nodes)

报错
etcd cluster "etcd": 99th percentile of gRPC requests is 0.22422727272727264s on etcd instance 172.26.168.102:9979.

# 查看 namespace test1 下有哪些 api resources
oc api-resources --verbs=list --namespaced -o name | xargs -n 1 oc get --show-kind --ignore-not-found -n test1 
oc patch perconaxtradbclusterbackup.pxc.percona.com cron-cluster1-s3-us-west-2022226000-3d2dv -n test1 -p '{"metadata":{"finalizers":[]}}' --type=merge
oc patch perconaxtradbclusterbackup.pxc.percona.com cron-cluster1-s3-us-west-202235000-3d2dv -n test1 -p '{"metadata":{"finalizers":[]}}' --type=merge
oc patch perconaxtradbcluster.pxc.percona.com cluster1 -n test1 -p '{"metadata":{"finalizers":[]}}' --type=merge
(ocp4)[root@helper ~]# oc get managedcluster
NAME            HUB ACCEPTED   MANAGED CLUSTER URLS                                           JOINED   AVAILABLE   AGE
local-cluster   true           https://api.ocp4.rhcnsa.com:6443                               True     True        24d
test1           true           https://api.cluster-66zw4.66zw4.sandbox1272.opentlc.com:6443   True     Unknown     23d

oc delete managedcluster test1


### 在 edge-1 创建 open-cluster-management-agent namespace，创建 serviceaccount，修改 imagePullSecrets
podman login quay.ocp4.rhcnsa.com --authfile=./auth.json
oc new-project open-cluster-management-agent
oc -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc -n open-cluster-management-agent create sa klusterlet
oc -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc -n open-cluster-management-agent create sa klusterlet-registration-sa
oc -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc -n open-cluster-management-agent create sa klusterlet-work-sa
oc -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

### 在 edge-1 创建 open-cluster-management-agent-addon namespace， 创建 serviceaccount，修改 imagePullSecrets
oc new-project open-cluster-management-agent-addon
oc -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
oc -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

### 在 edge-1 切换到 open-cluster-management-agent namespace
oc project open-cluster-management-agent
echo $CRDS | base64 -d | oc apply -f -
echo $IMPORT | base64 -d | oc apply -f -

skopeo copy --all  --format v2s2 --authfile /root/.docker/config.json docker://registry.redhat.io/rhacm2/registration-rhel8-operator@sha256:e7e1b5545f4a4946f40cdd2101b5ccba9b947320debd1a244dd5244b3430a61b docker://quay.ocp4.rhcnsa.com/rhacm2/registration-rhel8-operator@sha256:e7e1b5545f4a4946f40cdd2101b5ccba9b947320debd1a244dd5244b3430a61b

skopeo inspect --authfile /root/.docker/config.json docker://quay.ocp4.rhcnsa.com/rhacm2/registration-rhel8-operator@sha256:e7e1b5545f4a4946f40cdd2101b5ccba9b947320debd1a244dd5244b3430a61b

# 将数据库持久化到本地
mkdir -p /root/db
chmod a+rw /root/db
cd /root/assisted-service
podman run -dt --pod assisted-installer --env-file onprem-environment --pull never -v /root/db:/var/lib/pgsql/data:z --name postgres quay.io/centos7/postgresql-12-centos7:latest

# 为 Channel 指定自定义 CA
# https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.3/html/applications/managing-applications#using-custom-CA-certificates-for-secure-HTTPS-connection
oc get channel -A 
NAMESPACE                                                       NAME                                                         TYPE       PATHNAME                                                                            AGE
...
nswith-admin-giteaappsocp4rhcnsacom-lab-user-1-book-import-ns   nswith-admin-giteaappsocp4rhcnsacom-lab-user-1-book-import   Git        https://gitea-with-admin-gitea.apps.ocp4.rhcnsa.com/lab-user-1/book-import          24d

cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: git-ca
  namespace: nswith-admin-giteaappsocp4rhcnsacom-lab-user-1-book-import-ns
data:
  caCerts: |
    -----BEGIN CERTIFICATE-----
    MIIDYzCCAkugAwIBAgIIQRP3xrlQftgwDQYJKoZIhvcNAQELBQAwJjEkMCIGA1UE
    AwwbaW5ncmVzcy1vcGVyYXRvckAxNjI2NjA2MTU2MB4XDTIxMDcxODExMDIzOFoX
    DTIzMDcxODExMDIzOVowITEfMB0GA1UEAwwWKi5hcHBzLm9jcDQucmhjbnNhLmNv
    bTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOPdR9qh1gTs1iUqUcK8
    IDhekCUPmJywFwRuatzydztAPcGDvj4Y5GWx2pu+D8BD2A+Q3F59904BZWb4FlTe
    6kDoMvcXr9Y5HGsfIMQpJ5GdFGzNg0veDu88K1P4NAmK5C+FKVYKb83wBja/x7Ys
    3g0oqXaQuESY83okJCM3zplPcXxFyqVgrC7E9A/TNJsuZvRZWGfQHIUrxsUPEiVT
    jp8AwOcmyAEocm5mdNWThQGvBARdmuKuySb1/03BNbKD7qmj5x8/dz3rCyF7ufz3
    JOXsKzCuv5VGBx+IEg9IX+rvlNd2MCq/dJy3oAUrSEYUjOi4ZZ/OH87fndXuMNKC
    eesCAwEAAaOBmTCBljAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYBBQUH
    AwEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUpW/Kg6qjguBcMYBqbilYtopB4E0w
    HwYDVR0jBBgwFoAULmTEKt6hRTncC2BADMSke8A25rgwIQYDVR0RBBowGIIWKi5h
    cHBzLm9jcDQucmhjbnNhLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEAB97KrWlCuUgV
    gcZKqw800F4VOiJGXxsEQhHQ1EMfaBNkV51LBWLiD0iJND9UDL3nOVK0DTXLNbh6
    kofsI21vo3/XsJ/BofC6Pu1kFGqNiztVMh4BogCQSXkIu4K3wM04kgsj5Ynh4/Vz
    3UpUqR9q7AkqBgEEX55ytIY1l/Py/KnBgj3DGVLEQuJnOOyyhsPoKFz9pMOJ/r4+
    zJ+L0bpLRjsH1Zb7OPodzTHMCqPgdY/b7YOYtQcFYHSrtP5dmIIlUoLdqgCAlBGb
    oIAtkZlQQFudmI6p28zbmV3zoAsY9QSFv6Gg4Eiik+lttgy86yk6OqdSF+K2kwXQ
    qairhQ9Log==
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIDDDCCAfSgAwIBAgIBATANBgkqhkiG9w0BAQsFADAmMSQwIgYDVQQDDBtpbmdy
    ZXNzLW9wZXJhdG9yQDE2MjY2MDYxNTYwHhcNMjEwNzE4MTEwMjM2WhcNMjMwNzE4
    MTEwMjM3WjAmMSQwIgYDVQQDDBtpbmdyZXNzLW9wZXJhdG9yQDE2MjY2MDYxNTYw
    ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDB5Fjs4hC5Ade8DwMP6n46
    kmSz6pNLVYIkiLLgPFrG6d17Sn5UCqujlrP9fE1o9Q4BQeeu29k43sOQ/sIKljzu
    3ArOYTZvb1kaflMwJvmn0MagFR1TnSDB8kwnDeAZcdO0FK8JhJ85UDeEinF4rb1v
    zf4dJEoU3pNXY9hT47vqsXo3oB59DsrbtM2ythAPkZ9vv3G0kC0HOl8rjf9IJX4V
    lZZazvLv92euVyOtIHPgpbnrRUc74kWf8n5pzUDL13oFNaBMGabC+3fq8XaSwIb4
    6CGLW3BFfxy+2xEToUJ+aZqNRzR+hdy3+V/Wm57I/img/FVQJ/tkBlricupcOWcP
    AgMBAAGjRTBDMA4GA1UdDwEB/wQEAwICpDASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
    A1UdDgQWBBQuZMQq3qFFOdwLYEAMxKR7wDbmuDANBgkqhkiG9w0BAQsFAAOCAQEA
    JRWfbK0Czhoi2r/RnBHjU+PyQsSIlflgdn96N1FgevsHCz/w7wjvyYbNtdlgF+wj
    KH0EwB8cR5clKIESkGsGBjUjDytrUwofpbgFt2B+Ec+iaaaVdI1F3kb/uI7XF5S1
    eAVgZtPpSYkro8tCUR+fFAgypnkAkeNyYQMVX5tPTAiFrO7nO5RXdbi/Lrb68cQZ
    d/rE+5X3JtgYwILS+cxVS+ScAOQfPQspsgLIXq+OitU1a8z2QvdWKK+c9sCvcXjS
    I0yijITLiFyWuNLvK3wAUswYBRg9sXZX5OAKU51amR/POiVqnPPQYlJQk//JmRij
    KGh+it3EJJlVTH6jVLkpEA==
    -----END CERTIFICATE-----
EOF  


oc -n nswith-admin-giteaappsocp4rhcnsacom-lab-user-1-book-import-ns patch channel nswith-admin-giteaappsocp4rhcnsacom-lab-user-1-book-import --patch '{"spec":{"configMapRef":{"name":"git-ca"}}}' --type=merge


curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8_Stream/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:1.21.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:1.21/CentOS_8_Stream/devel:kubic:libcontainers:stable:cri-o:1.21.repo

mkdir -p /root/db
chmod -R a+rw /root/db
cd /root/db
podman cp -r postgres:/var/lib/pgsql/data .
chown -R 26:26 .
podman run -dt --pod assisted-installer --env-file onprem-environment --pull never -v /root/db:/var/lib/pgsql:z --name postgres quay.io/centos7/postgresql-12-centos7:latest

# cd /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/
# kubectl --kubeconfig=localhost.kubeconfig -n openshift-machine-config-operator logs machine-config-daemon-sz99n machine-config-daemon
...
E0311 11:31:10.370559    9928 daemon.go:1549] content mismatch for file "/etc/containers/registries.conf" (-want +got):

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml

skopeo copy --all --authfile /root/.docker/config.json docker://docker.io/redis:6.2.6-alpine docker://quay.ocp4.rhcnsa.com/redis/redis:6.2.6-alpine
skopeo copy --all --authfile /root/.docker/config.json docker://registry.redhat.io/rhel8/redis-6:latest docker://quay.ocp4.rhcnsa.com/rhel8/redis-6:latest

# 日志 
# openshift-gitops-applicationset-controller
# oc -n openshift-gitops logs openshift-gitops-applicationset-controller-5b684bf665-nq2b6 | tail -20
...
time="2022-03-12T03:06:53Z" level=info msg="Kind.Group/Version Reference" kind.apiVersion=placementdecisions.cluster.open-cluster-management.io/v1alpha1
time="2022-03-12T03:06:53Z" level=info msg="selection type" listOptions.LabelSelector="cluster.open-cluster-management.io/placement=gitops-openshift-clusters"
time="2022-03-12T03:06:53Z" level=info msg="Number of decisions found: 2"
time="2022-03-12T03:06:53Z" level=info msg="cluster: map[clusterName:edge-1 reason:]"
time="2022-03-12T03:06:53Z" level=info msg="matched cluster in ArgoCD" clusterName=edge-1
time="2022-03-12T03:06:53Z" level=info msg="cluster: map[clusterName:local-cluster reason:]"
time="2022-03-12T03:06:53Z" level=info msg="matched cluster in ArgoCD" clusterName=local-cluster
time="2022-03-12T03:06:53Z" level=info msg="generated 2 applications" generator="{<nil> <nil> <nil> <nil> <nil> 0xc000318ea0}"
time="2022-03-12T03:06:53Z" level=error msg="error occurred during application generation: application spec is invalid: InvalidSpecError: Destination server missing from app spec"

# 触发 deployment service-ca 的重新部署
oc patch deployment/service-ca -n openshift-service-ca --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

$ PASSWD=$(oc get secret openshift-gitops-cluster -n openshift-gitops -ojsonpath='{.data.admin\.password}' | base64 -d)
```

### OpenShift / RHEL / DevSecOps 汇总目录
非常好的 OpenShift / RHEL 汇总<br>
https://blog.csdn.net/weixin_43902588/article/details/105060359<br>


```
spec:
  generators:
  - list:
      elements:
      - cluster: environment-dev
        url: https://api.ocp4.rhcnsa.com:6443
      - cluster: environment-edge-1
        url: https://edge-1.ocp4.rhcnsa.com:6443
  template:
    metadata:
      name: acm-appset3-{{cluster}}
    spec:
      destination:
        namespace: book-import-3
        server: '{{url}}'
      project: default
      source:
        path: book-import
        repoURL: https://gitea-with-admin-gitea.apps.ocp4.rhcnsa.com/lab-user-1/book-import
        targetRevision: master-no-pre-post
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
        - PrunePropagationPolicy=foreground



time="2022-03-14T04:25:19Z" level=error msg="error occurred during application generation: application spec is invalid: InvalidSpecError: Destination server missing from app spec"
time="2022-03-14T04:25:28Z" level=info msg="generated 2 applications" generator="{0xc000326000 <nil> <nil> <nil> <nil> <nil>}"
time="2022-03-14T04:25:28Z" level=error msg="error occurred during application generation: application spec is invalid: InvalidSpecError: cluster 'https://edge-1.ocp4.rhcnsa.com:6443' has not been configured"


报错
$ oc logs openshift-gitops-applicationset-controller-5b684bf665-nq2b6  | tail -20 
...
time="2022-03-14T04:25:19Z" level=info msg="Kind.Group/Version Reference" kind.apiVersion=placementdecisions.cluster.open-cluster-management.io/v1alpha1
time="2022-03-14T04:25:19Z" level=info msg="selection type" listOptions.LabelSelector="cluster.open-cluster-management.io/placement=gitops-openshift-clusters"
time="2022-03-14T04:25:19Z" level=info msg="Number of decisions found: 2"
time="2022-03-14T04:25:19Z" level=info msg="cluster: map[clusterName:edge-1 reason:]"
time="2022-03-14T04:25:19Z" level=info msg="matched cluster in ArgoCD" clusterName=edge-1
time="2022-03-14T04:25:19Z" level=info msg="cluster: map[clusterName:local-cluster reason:]"
time="2022-03-14T04:25:19Z" level=info msg="matched cluster in ArgoCD" clusterName=local-cluster
time="2022-03-14T04:25:19Z" level=info msg="generated 2 applications" generator="{<nil> <nil> <nil> <nil> <nil> 0xc00019e1a0}"
time="2022-03-14T04:25:19Z" level=error msg="error occurred during application generation: application spec is invalid: InvalidSpecError: Destination server missing from app spec"
time="2022-03-14T04:25:28Z" level=info msg="generated 2 applications" generator="{0xc000326000 <nil> <nil> <nil> <nil> <nil>}"
time="2022-03-14T04:25:28Z" level=error msg="error occurred during application generation: application spec is invalid: InvalidSpecError: cluster 'https://edge-1.ocp4.rhcnsa.com:6443' has not been configured"

argocd cluster add edge-1 --kubeconfig /Users/junwang/kubeconfig/edge-1/kubeconfig --core --server https://edge-1.ocp4.rhcnsa.com:6443 --insecure

ERRO[0005] finished unary call with code Unknown         error="cannot find pod with selector: [app.kubernetes.io/name=argocd-redis-ha-haproxy app.kubernetes.io/name=argocd-redis]" grpc.code=Unknown grpc.method=Create grpc.service=cluster.ClusterService grpc.start_time="2022-03-14T13:23:37+08:00" grpc.time_ms=120.329 span.kind=server system=grpc

skopeo copy --all --authfile /root/.docker/config.json docker://gcr.io/kubebuilder/kube-rbac-proxy:v0.8.0 docker://registry.example.com:5000/kubebuilder/kube-rbac-proxy:v0.8.0

skopeo copy --all --authfile /root/.docker/config.json docker://quay.io/argoproj/argocd@sha256:bac1aeee8e78e64d81a633b9f64148274abfa003165544354e2ebf1335b6ee73 docker://registry.example.com:5000/argoproj/argocd@sha256:bac1aeee8e78e64d81a633b9f64148274abfa003165544354e2ebf1335b6ee73

skopeo copy --all --authfile /root/.docker/config.json docker://docker.io/redis@sha256:4be7fdb131e76a6c6231e820c60b8b12938cf1ff3d437da4871b9b2440f4e385 docker://registry.example.com:5000/redis@sha256:4be7fdb131e76a6c6231e820c60b8b12938cf1ff3d437da4871b9b2440f4e385

oc patch deployment/argocd-sample-redis -n argocd --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

skopeo copy --all --authfile /root/.docker/config.json docker://ghcr.io/dexidp/dex@sha256:6b3cc1c385fbc7542244614e4432f2546c619b7850d44d2379c598309a06bed8 docker://registry.example.com:5000/dexidp/dex@sha256:6b3cc1c385fbc7542244614e4432f2546c619b7850d44d2379c598309a06bed8

oc patch deployment/argocd-sample-dex-server -n argocd --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"


oc patch deployment/postgresql-gitea-with-admin -n gitea --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

```

### argocd
```
# 安装 argocd 客户端
$ ARGO_VER=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
$ sudo curl -L https://github.com/argoproj/argo-cd/releases/download/${ARGO_VER}/argocd-linux-amd64 -o /usr/local/bin/argocd
$ sudo chmod +x /usr/local/bin/argocd

$ PASSWD=$(oc get secret argocd-sample-cluster -n argocd -ojsonpath='{.data.admin\.password}' | base64 -d)
```

# 创建 gitea 
```
cat <<EOF | oc apply -f -
apiVersion: gpte.opentlc.com/v1
kind: Gitea
metadata:
  name: gitea-without-admin
spec:
  giteaSsl: false
  giteaCreateUsers: true
  giteaGenerateUserFormat: "lab-user-%d"
  giteaUserNumber: 2
  giteaUserPassword: openshift
EOF

[root@ocpai1 ocp4-1]# oc logs gitea-operator-controller-manager-6c79f4746c-69t77 -c manager -n openshift-operators 
...
 TASK [Create Gitea admin user] ******************************** 
fatal: [localhost]: FAILED! => {"changed": true, "rc": 1, "return_code": 1, "stderr": "", "stderr_lines": [], "stdout": "\u001b[36m2022/03/15 06:26:14 \u001b[0m\u001b[32mmodels/user/user.go:720:\u001b[32mCountUsers()\u001b[0m \u001b[1;32m[I]\u001b[0m [SQL]\u001b[1m\u001b[0m \u001b[1mSELECT count(*) FROM \"user\" WHERE (type=0)\u001b[0m \u001b[1m[]\u001b[0m - \u001b[1m15.037566ms\u001b[0m\n\u001b[36m2022/03/15 06:26:14 \u001b[0m\u001b[32mmain.go:117:\u001b[32mmain()\u001b[0m \u001b[1;41m[F]\u001b[0m Failed to run app with \u001b[1m[/home/gitea/gitea --config=/home/gitea/conf/app.ini admin user create --username admin --password 5bpNnBx3xZcPmNqeXzZWZ0RXZuWdDfUA --email jwang@redhat.com --must-change-password=false --admin]\u001b[0m: \u001b[1mCreateUser: name is reserved [name: admin]\u001b[0m\n", "stdout_lines": ["\u001b[36m2022/03/15 06:26:14 \u001b[0m\u001b[32mmodels/user/user.go:720:\u001b[32mCountUsers()\u001b[0m \u001b[1;32m[I]\u001b[0m [SQL]\u001b[1m\u001b[0m \u001b[1mSELECT count(*) FROM \"user\" WHERE (type=0)\u001b[0m \u001b[1m[]\u001b[0m - \u001b[1m15.037566ms\u001b[0m", "\u001b[36m2022/03/15 06:26:14 \u001b[0m\u001b[32mmain.go:117:\u001b[32mmain()\u001b[0m \u001b[1;41m[F]\u001b[0m Failed to run app with \u001b[1m[/home/gitea/gitea --config=/home/gitea/conf/app.ini admin user create --username admin --password 5bpNnBx3xZcPmNqeXzZWZ0RXZuWdDfUA --email jwang@redhat.com --must-change-password=false --admin]\u001b[0m: \u001b[1mCreateUser: name is reserved [name: admin]\u001b[0m"]}


[junwang@JundeMacBook-Pro ~/sa]$ ocl1 get pods -A                                                                                                                         
NAMESPACE                       NAME                                            READY   STATUS    RESTARTS   AGE                                                          
kube-system                     kube-flannel-ds-8xgdb                           1/1     Running   0          3h4m                                                         
kubevirt-hostpath-provisioner   kubevirt-hostpath-provisioner-klgqq             1/1     Running   0          3h4m
open-cluster-management-agent   klusterlet-b48d64b8c-jg9mk                      1/1     Running   1          2m46s
open-cluster-management-agent   klusterlet-registration-agent-cd787bc67-2b4bw   1/1     Running   0          2m17s
open-cluster-management-agent   klusterlet-work-agent-65765fc674-ptq5d          1/1     Running   1          2m17s
openshift-dns                   dns-default-9g2d7                               1/2     Running   21         3h4m
openshift-dns                   node-resolver-kxttb                             1/1     Running   0          3h4m
openshift-ingress               router-default-6c96f6bc66-wrw4s                 1/1     Running   0          3h4m
openshift-service-ca            service-ca-7bffb6f6bf-bs7c6                     1/1     Running   1          3h4m

[junwang@JundeMacBook-Pro ~/sa]$ ocl1 describe pods dns-default-9g2d7 -n openshift-dns 
...
Events:
  Type     Reason      Age                   From     Message
  ----     ------      ----                  ----     -------
  Warning  ProbeError  19m (x376 over 3h1m)  kubelet  Liveness probe error: Get "http://10.42.0.2:8080/health": dial tcp 10.42.0.2:8080: connect: connection refused
body:
  Warning  ProbeError  20s (x1770 over 3h1m)  kubelet  Readiness probe error: Get "http://10.42.0.2:8181/ready": dial tcp 10.42.0.2:8181: connect: connection refused
body:

[junwang@JundeMacBook-Pro ~/sa]$ ocl1 describe pods dns-default-9g2d7 -n openshift-dns 
...
8m13s       Warning   FailedScheduling    pod/klusterlet-addon-search-58fb475c9d-66hzj                                           0/1 nodes are available: 1 Insufficient memory.


创建 ApplicationSet 
cat <<'EOF' | ocp4.10 apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: acm-appset
  namespace: openshift-gitops
spec:
  generators:
    - clusterDecisionResource:
        configMapRef: acm-placement
        labelSelector:
          matchLabels:
            cluster.open-cluster-management.io/clusterset: gitops-openshift-clusters
        requeueAfterSeconds: 180
  template:
    metadata:
      name: 'acm-appset-{{name}}'
    spec:
      destination:
        namespace: book-import-1
        server: '{{server}}'
      project: default
      source:
        path: book-import
        repoURL: https://github.com/wangjun1974/book-import
        targetRevision: master-no-pre-post
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
        - PrunePropagationPolicy=foreground
EOF

查看 Mac 端口占用
sudo lsof -iTCP:6443 -sTCP:LISTEN 
netstat -p tcp -van | grep '^Proto\|LISTEN'

```

```
报错
Mar 17 03:20:33 microshift.edge-1.example.com microshift[74]: E0317 03:20:33.476069      74 pod_workers.go:190] "Error syncing pod, skipping" err="failed to \"StartContainer\" for \"service-ca-controller\" with CreateContainerError: \"container create failed: time=\\\"2022-03-17T03:20:33Z\\\" level=error msg=\\\"container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting \\\\\\\"cgroup\\\\\\\" to rootfs at \\\\\\\"/sys/fs/cgroup\\\\\\\" caused: stat /sys/fs/cgroup/systemd/system.slice/crio-3be10ca20c069701265c5c105832373648d02a9b3c04475a9c03cb906aa42f61.scope: no such file or directory\\\"\\n\"" pod="openshift-service-ca/service-ca-7bffb6f6bf-kc2n5" podUID=5a250e21-8a48-40be-836a-2b9a4389656a

Mar 17 03:21:59 microshift.edge-1.example.com microshift[74]: E0317 03:21:59.827091      74 remote_runtime.go:228] "CreateContainer in sandbox from runtime service failed" err="rpc error: code = Unknown desc = container create failed: time=\"2022-03-17T03:21:59Z\" level=error msg=\"container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting \\\"cgroup\\\" to rootfs at \\\"/sys/fs/cgroup\\\" caused: stat /sys/fs/cgroup/systemd/system.slice/crio-2de5e6d3c57997f368c5a0003361adda01a4cee815eb87db53aa3c280b00dbdb.scope: no such file or directory\"\n" podSandboxID="d409e51e4ad170f6f1c621df7683b9fed25f12d64042838b15f6c81c50ffab70"


Mar 17 03:21:59 microshift.edge-1.example.com microshift[74]: E0317 03:21:59.827199      74 kuberuntime_manager.go:864] container &Container{Name:kubevirt-hostpath-provisioner,Image:quay.io/kubevirt/hostpath-provisioner:v0.8.0,Command:[],Args:[],WorkingDir:,Ports:[]ContainerPort{},Env:[]EnvVar{EnvVar{Name:USE_NAMING_PREFIX,Value:false,ValueFrom:nil,},EnvVar{Name:NODE_NAME,Value:,ValueFrom:&EnvVarSource{FieldRef:&ObjectFieldSelector{APIVersion:v1,FieldPath:spec.nodeName,},ResourceFieldRef:nil,ConfigMapKeyRef:nil,SecretKeyRef:nil,},},EnvVar{Name:PV_DIR,Value:/var/hpvolumes,ValueFrom:nil,},},Resources:ResourceRequirements{Limits:ResourceList{},Requests:ResourceList{},},VolumeMounts:[]VolumeMount{VolumeMount{Name:pv-volume,ReadOnly:false,MountPath:/var/hpvolumes,SubPath:,MountPropagation:nil,SubPathExpr:,},VolumeMount{Name:kube-api-access-hffq6,ReadOnly:true,MountPath:/var/run/secrets/kubernetes.io/serviceaccount,SubPath:,MountPropagation:nil,SubPathExpr:,},},LivenessProbe:nil,ReadinessProbe:nil,Lifecycle:nil,TerminationMessagePath:/dev/termination-log,ImagePullPolicy:Always,SecurityContext:nil,Stdin:false,StdinOnce:false,TTY:false,EnvFrom:[]EnvFromSource{},TerminationMessagePolicy:File,VolumeDevices:[]VolumeDevice{},StartupProbe:nil,} start failed in pod kubevirt-hostpath-provisioner-7nxpn_kubevirt-hostpath-provisioner(85dbc6dd-5a33-43fa-896e-057f0ef29364): CreateContainerError: container create failed: time="2022-03-17T03:21:59Z" level=error msg="container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting \"cgroup\" to rootfs at \"/sys/fs/cgroup\" caused: stat /sys/fs/cgroup/systemd/system.slice/crio-2de5e6d3c57997f368c5a0003361adda01a4cee815eb87db53aa3c280b00dbdb.scope: no such file or directory"

Mar 17 03:21:59 microshift.edge-1.example.com microshift[74]: E0317 03:21:59.827269      74 pod_workers.go:190] "Error syncing pod, skipping" err="failed to \"StartContainer\" for \"kubevirt-hostpath-provisioner\" with CreateContainerError: \"container create failed: time=\\\"2022-03-17T03:21:59Z\\\" level=error msg=\\\"container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting \\\\\\\"cgroup\\\\\\\" to rootfs at \\\\\\\"/sys/fs/cgroup\\\\\\\" caused: stat /sys/fs/cgroup/systemd/system.slice/crio-2de5e6d3c57997f368c5a0003361adda01a4cee815eb87db53aa3c280b00dbdb.scope: no such file or directory\\\"\\n\"" pod="kubevirt-hostpath-provisioner/kubevirt-hostpath-provisioner-7nxpn" podUID=85dbc6dd-5a33-43fa-896e-057f0ef29364

CreateContainerError: container create failed: time="2022-03-17T03:20:23Z" level=error msg="container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting \"cgroup\" to rootfs at \"/sys/fs/cgroup\" caused: stat /sys/fs/cgroup/systemd/system.slice/crio-85dbf6bb49fa9b29734ba9031eab4cf5baf35471794c300be728125030272584.scope: no such file or directory"

Mar 17 03:46:33 microshift.edge-1.example.com crio[31]: time="2022-03-17 03:46:33.905149582Z" level=error msg="Container creation error: time=\"2022-03-17T03:46:33Z\" level=error msg=\"container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting \\\"cgroup\\\" to rootfs at \\\"/sys/fs/cgroup\\\" caused: stat /sys/fs/cgroup/systemd/system.slice/crio-22189fa0a7cd9d21cc2d802485328f7227826d651270db4161e1f6207345f574.scope: no such file or directory\"\n" id=f0a532c1-953e-457f-8f8f-399787224b08 name=/runtime.v1alpha2.RuntimeService/CreateContainer


https://bugzilla.redhat.com/show_bug.cgi#id=1732957

oc get subscription book-import-subscription-1 -n book-import -o yaml
...
apiVersion: apps.open-cluster-management.io/v1
kind: Subscription
metadata:
  annotations:
    apps.open-cluster-management.io/deployables: ""
    apps.open-cluster-management.io/git-branch: master-no-pre-post
    apps.open-cluster-management.io/git-path: book-import
    apps.open-cluster-management.io/manual-refresh-time: "2022-03-11T02:55:41.590Z"
    apps.open-cluster-management.io/reconcile-option: merge
  labels:
    app: book-import
    app.kubernetes.io/part-of: book-import
    apps.open-cluster-management.io/reconcile-rate: medium
  name: book-import-subscription-1
  namespace: book-import


oc get subscription testapp-subscription-1 -n testapp -o yaml 
...
apiVersion: apps.open-cluster-management.io/v1
kind: Subscription
metadata:
  annotations:
    apps.open-cluster-management.io/cluster-admin: "true"
    apps.open-cluster-management.io/deployables: testapp/testapp-subscription-1-book-import-book-import-deployment,testapp/testapp-subscription-1-book-import-book-import-route,testapp/testapp-subscription-1-book-import-book-import-service
    apps.open-cluster-management.io/git-branch: master-no-pre-post
    apps.open-cluster-management.io/git-current-commit: 3ebaa46e2c4bdc8c4ecc1f70cad5ab5863fb1463
    apps.open-cluster-management.io/git-path: book-import
    apps.open-cluster-management.io/reconcile-option: merge
    apps.open-cluster-management.io/topo: deployable//Deployment//book-import/3,deployable//Route//book-import/0,deployable//Service//book-import/0
    open-cluster-management.io/user-group: c3lzdGVtOmF1dGhlbnRpY2F0ZWQ6b2F1dGgsc3lzdGVtOmF1dGhlbnRpY2F0ZWQ=
    open-cluster-management.io/user-identity: YWRtaW4=
  creationTimestamp: "2022-03-15T14:20:27Z"
  generation: 2
  labels:
    app: testapp
    app.kubernetes.io/part-of: testapp
    apps.open-cluster-management.io/reconcile-rate: medium
  name: testapp-subscription-1
  namespace: testapp
  resourceVersion: "609598001"
  uid: 40d2be81-33e2-4daa-930c-4bfcee39cfec


cat > /etc/systemd/system/microshift.service <<'EOF'
[Unit]
Description=MicroShift Containerized
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target crio.service
After=network-online.target crio.service
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/usr/bin/mkdir -p /var/lib/kubelet ; /usr/bin/mkdir -p /var/hpvolumes
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon --rm --replace --sdnotify=container --label io.containers.autoupdate=registry --network=host --privileged -d --name microshift -v /var/hpvolumes:/var/hpvolumes:z,rw,rshared -v /var/run/crio/crio.sock:/var/run/crio/crio.sock:rw,rshared -v microshift-data:/var/lib/microshift:rw,rshared -v /var/lib/kubelet:/var/lib/kubelet:z,rw,rshared -v /var/log:/var/log -v /etc:/etc quay.io/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=multi-user.target default.target
EOF

oc patch deployment/router-default -n openshift-ingress --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

ocp4.10 new-project open-cluster-management-agent
ocp4.10 -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
ocp4.10 -n open-cluster-management-agent create sa klusterlet
ocp4.10 -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
ocp4.10 -n open-cluster-management-agent create sa klusterlet-registration-sa
ocp4.10 -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
ocp4.10 -n open-cluster-management-agent create sa klusterlet-work-sa
ocp4.10 -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

ocp4.10 new-project open-cluster-management-agent-addon
ocp4.10 -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
ocp4.10 -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
ocp4.10 -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

ocp4.10 project open-cluster-management-agent
echo $CRDS | base64 -d | ocp4.10 apply -f -
echo $IMPORT | base64 -d | ocp4.10 apply -f -

ocp4.10 project open-cluster-management-agent-addon
for sa in klusterlet-addon-appmgr klusterlet-addon-certpolicyctrl klusterlet-addon-iampolicyctrl-sa klusterlet-addon-policyctrl klusterlet-addon-search klusterlet-addon-workmgr ; do
  ocp4.10 -n open-cluster-management-agent-addon patch sa $sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
done
ocp4.10 delete pod --all -n open-cluster-management-agent-addon

$ oc -n open-cluster-management-agent get deployment klusterlet -o yaml | grep "image: " 
        image: registry.redhat.io/rhacm2/registration-rhel8-operator@sha256:568d3b5dc4da1dd35c68d1405c274933d6129462b5873e929e25a444c50f1d6b
$ oc -n open-cluster-management-agent get deployment klusterlet-registration-agent -o yaml | grep "image: " 
        image: registry.redhat.io/rhacm2/registration-rhel8@sha256:574b41e19bf26043f985fcfac8e8cd9384f1b37aba4d4eb3be3901ae6a427081

$ oc -n open-cluster-management-agent get deployment klusterlet-work-agent -o yaml | grep "image: " 
        image: registry.redhat.io/rhacm2/work-rhel8@sha256:b5c1519fda361b17f90ce895de2587d0b95692660fb79988ca2f21f71267ebe1


podman run -d --rm --name microshift --hostname microshift.edge-1.example.com --cgroup-manager=systemd --privileged -v microshift-data:/var/lib -p 6443:6443 quay.io/microshift/microshift-aio:latest


kernel path ISO11://vmlinuz-rhel-8.4
initrd path ISO11://initrd.img-rhel-8.4
kernel parameters  inst.ks=http://10.66.208.115/ks-helper.cfg inst.ksdevice=ens3 ip=10.66.208.125 netmask=255.255.255.0 nameserver=10.64.63.6 gateway=10.66.208.254

ipa host-add --random --force jwang.users.ipa.redhat.com

6Le00t3cgkMeOGjXOMYg8yu

cat <<EOF | ocp4.9 apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: redhat-pull-secret
  namespace: openshift-operators
data:
  .dockerconfigjson: ewogICJhdXRocyI6IHsKICAgICJxdWF5LmlvIjogewogICAgICAiYXV0aCI6ICJjbVZrYUdGMEszRjFZWGs2VHpneFYxTklVbE5LVWpFMFZVRmFRa3MxTkVkUlNFcFRNRkF4VmpSRFRGZEJTbFl4V0RKRE5GTkVOMHRQTlRsRFVUbE9NMUpGTVRJMk1USllWVEZJVWc9PSIsCiAgICAgICJlbWFpbCI6ICIiCiAgICB9CiAgfQp9
type: kubernetes.io/dockerconfigjson
EOF

oc -n openshift-operators create secret generic redhat-pull-secret --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson


cat <<EOF | ocp4.9 apply -f -
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
metadata:
  name: example-registry
  namespace: quay-enterprise
spec:
  components:
    - managed: true
      kind: clair
    - managed: true
      kind: postgres
    - managed: false
      kind: objectstorage
    - managed: true
      kind: redis
    - managed: true
      kind: horizontalpodautoscaler
    - managed: true
      kind: route
    - managed: false
      kind: mirror
    - managed: false
      kind: monitoring
    - managed: true
      kind: tls
  configBundleSecret: config-bundle-secret
EOF

报错
QuayRegistry
...
      message: >-
        required component `objectstorage` marked as unmanaged, but
        `configBundleSecret` is missing necessary fields

cat > config.yaml <<EOF
DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
 default:
 - LocalStorage
 - {storage_path: /datastorage/registry}
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE: [default]
FEATURE_USER_INITIALIZE: true
FEATURE_USER_CREATION: true
SUPER_USERS:
- quayadmin
EOF
[junwang@JundeMacBook-Pro ~/kubeconfig/ocp4.9]$ ocp4.9 create secret generic --from-file config.yaml=./config.yaml config-bundle-secret

cat > config.yaml <<EOF
DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
  default:
  - RadosGWStorage
  - access_key: minio
    secret_key: minioredhat123
    hostname: minio-velero.apps.ocp4.rhcnsa.com
    bucket_name: quay
    port: 80
    is_secure: false
    storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE: [default]
FEATURE_USER_INITIALIZE: true
FEATURE_USER_CREATION: true
SUPER_USERS:
- quayadmin
EOF
[junwang@JundeMacBook-Pro ~/kubeconfig/ocp4.9]$ ocp4 create secret generic --from-file config.yaml=./config.yaml config-bundle-secret
https://github.com/quay/quay-operator/issues/380

创建用户
 registryEndpoint: >-
    https://example-registry-quay-openshift-operators.router-default.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com

$  curl -X POST -k  https://example-registry-quay-openshift-operators.router-default.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password":"quaypass123", "email": "quayadmin@example.com", "access_token": true}'

curl -X POST -k  https://example-registry-quay-openshift-operators.router-default.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password":"quaypass123", "email": "quayadmin@example.com", "access_token": true}'


ALLOW_PULLS_WITHOUT_STRICT_LOGGING: false
AUTHENTICATION_TYPE: Database
DEFAULT_TAG_EXPIRATION: 2w
ENTERPRISE_LOGO_URL: /static/img/RH_Logo_Quay_Black_UX-horizontal.svg
FEATURE_BUILD_SUPPORT: false
FEATURE_DIRECT_LOGIN: true
FEATURE_MAILING: false
REGISTRY_TITLE: Red Hat Quay
REGISTRY_TITLE_SHORT: Red Hat Quay
TAG_EXPIRATION_OPTIONS:
- 2w
TEAM_RESYNC_STALE_TIME: 60m
TESTING: false

ALLOW_PULLS_WITHOUT_STRICT_LOGGING: false
AUTHENTICATION_TYPE: Database
BUILDLOGS_REDIS:
  host: example-registry-quay-redis
  port: 6379
DATABASE_SECRET_KEY: GC6m5g4wYmSgjZIs-6OBgnD1IxgP-oUG1qDA41-mxxTFjkv8ihW1Z792xn3jIwNfgAX0OX7-g1XOQ4YQ
DB_CONNECTION_ARGS:
  autorollback: true
  threadlocals: true
DB_URI: postgresql://example-registry-quay-database:VYsE-gUjMze0QvPXogNBT4e5KknT0ZG9@example-registry-quay-database:5432/example-registry-quay-database
DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
  default:
  - LocalStorage
  - storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE:
- default
ENTERPRISE_LOGO_URL: /static/img/RH_Logo_Quay_Black_UX-horizontal.svg
EXTERNAL_TLS_TERMINATION: false
FEATURE_BUILD_SUPPORT: false
FEATURE_DIRECT_LOGIN: true
FEATURE_MAILING: false
FEATURE_SECURITY_NOTIFICATIONS: true
FEATURE_SECURITY_SCANNER: true
PREFERRED_URL_SCHEME: https
REGISTRY_TITLE: Red Hat Quay
REGISTRY_TITLE_SHORT: Red Hat Quay
SECRET_KEY: aKtDslJbZgs0Nw-eeQO1r3yYHrYdHSwlgpYr1zWuPor3yZbX4s7IWEVtFEXw4QEUZ-s-btE25uvGOATG
SECURITY_SCANNER_INDEXING_INTERVAL: 30
SECURITY_SCANNER_V4_ENDPOINT: http://example-registry-clair-app:80
SECURITY_SCANNER_V4_NAMESPACE_WHITELIST:
- admin
SECURITY_SCANNER_V4_PSK: ZldUMXVkeUlWNzBDSS1CUzVFVk52YXA2SXlycFZCNGk=
SERVER_HOSTNAME: example-registry-quay-openshift-operators.router-default.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com
SETUP_COMPLETE: true
TAG_EXPIRATION_OPTIONS:
- 2w
TEAM_RESYNC_STALE_TIME: 60m
TESTING: false
USER_EVENTS_REDIS:
  host: example-registry-quay-redis
  port: 6379

ALLOW_PULLS_WITHOUT_STRICT_LOGGING: false
AUTHENTICATION_TYPE: Database
DEFAULT_TAG_EXPIRATION: 2w
ENTERPRISE_LOGO_URL: /static/img/RH_Logo_Quay_Black_UX-horizontal.svg
FEATURE_BUILD_SUPPORT: false
FEATURE_DIRECT_LOGIN: true
FEATURE_MAILING: false
REGISTRY_TITLE: Red Hat Quay
REGISTRY_TITLE_SHORT: Red Hat Quay
TAG_EXPIRATION_OPTIONS:
- 2w
TEAM_RESYNC_STALE_TIME: 60m
TESTING: false

cat > config.yaml <<EOF
FEATURE_USER_INITIALIZE: true
SUPER_USERS:
- quayadmin
EOF


https://docs.projectquay.io/deploy_quay_on_openshift_op_tng.html#operator-preconfigure

创建用户
$  curl -X POST -k  https://example-registry-quay-openshift-operators.router-default.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password":"quaypass123", "email": "quayadmin@example.com", "access_token": true}'

ocp4.9 create secret generic quay-admin \
--from-literal=superuser-username=quayadmin \
--from-literal=superuser-password=StrongAdminPassword \
--from-literal=superuser-email=admin@example.com


DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
 default:
 - LocalStorage
 - {storage_path: /datastorage/registry}
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE: [default]
FEATURE_USER_INITIALIZE: true
FEATURE_USER_CREATION: true
SUPER_USERS:
- quayadmin



[root@jwang ~]# podman pull example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8:2.0.0-61
Trying to pull example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8:2.0.0-61...
  Error fetching blob: invalid status code from registry 500 (Internal Server Error)
Error: Error parsing image configuration: Error fetching blob: invalid status code from registry 500 (Internal Server Error)

  configEditorCredentialsSecret: example-registry-quay-config-editor-credentials-m5f44d2f5f
  configEditorEndpoint: >-
    https://example-registry-quay-config-editor-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com
  currentVersion: 3.6.4
  lastUpdated: '2022-03-23 02:35:02.020377144 +0000 UTC'
  registryEndpoint: >-
    https://example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com

# 生成证书信任
openssl s_client -host example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /etc/pki/ca-trust/source/anchors/example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com.crt  
update-ca-trust

# 更新 pull-secret-full.json 文件，包含新镜像仓库登录信息
podman login example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com -u jwang --authfile=./pull-secret-full.json

# 拷贝镜像
skopeo copy --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd docker://example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/jwang/registration-operator-rhel8:latest


# 上传镜像
podman push example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/jwang/registration-operator-rhel8:latest --authfile=./pull-secret-full.json 
Error: error copying image to the remote destination: Error writing blob: Error uploading layer to https://example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/v2/jwang/registration-operator-rhel8/blobs/uploads/2169d2d6-9e83-45ab-b603-88696852a41f?digest=sha256%3A5a8b526f9779462159219be1a8944021b1b4b64e2b7231457e67669c7039a2ba: received unexpected HTTP status: 502 Bad Gateway

ocp4.9 get sa 
...
example-registry-quay-app

# 为 sa example-registry-quay-app 添加 anyuid scc 并触发重新部署
ocp4.9 adm policy add-scc-to-user anyuid -z example-registry-quay-app -n openshift-operators
ocp4.9 adm policy add-scc-to-user privileged -z example-registry-quay-app -n openshift-operators
ocp4.9 patch deployment/example-registry-quay-app -n openshift-operators --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"


oc patch deployment minio -n velero --patch='{"spec":{"template":{"spec":{"containers":[{"name": "minio", "image":"quay.ocp4.rhcnsa.com/minio/minio:latest"}]}}}}'


报错
Bundle unpacking failed. Reason: DeadlineExceeded, and Message: Job was active longer than specified deadline
# 参考https://access.redhat.com/solutions/6459071

# 删除 job
oc get job -n openshift-marketplace -o json | jq -r '.items[] | select(.spec.template.spec.containers[].env[].value|contains ("quay")) | .metadata.name'
70b8d2e2e039b98564c5c7b2324eeada9e4cbbe0a042a0a04a0469171e6f99e
811f6ee70978558adbf1587dc18b470b24a553ef3b557ef8fe9d753904f2e45
d30c021940e3d5db61ae62d91122a42fceeb606866fc035a4d7f65723eea42e
d5601703e93679a04c12fd9265cadd06306f243e9efa80672aada773d28ad94
e825b0832cd2a1f06f94667156d245d81a2cae16b98441d4726151cee09dedf
# 删除 configmap
# 检查 ip, subs, csv 
# 重新创建 catalog-operator
ocp4 -n openshift-operator-lifecycle-manager delete $(ocp4 -n openshift-operator-lifecycle-manager get pod -l app=catalog-operator -o name)

ocp4 -n openshift-operator-lifecycle-manager logs $(ocp4 -n openshift-operator-lifecycle-manager get pod -l app=catalog-operator -o name)

  configEditorCredentialsSecret: example-registry-quay-config-editor-credentials-kb869mg7bc
  configEditorEndpoint: >-
    https://example-registry-quay-config-editor-openshift-operators.apps.ocp4.rhcnsa.com
  currentVersion: 3.6.4
  lastUpdated: '2022-03-23 05:52:52.943245261 +0000 UTC'
  registryEndpoint: 'https://example-registry-quay-openshift-operators.apps.ocp4.rhcnsa.com'

skopeo copy --format v2s2 --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd docker://example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd


[root@jwang ~]# podman pull docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd --authfile=./pull-secret-full.json 
Trying to pull docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd...
Getting image source signatures
Copying blob e146126e9a00 skipped: already exists  
Copying blob 510abfcdf6bc [--------------------------------------] 0.0b / 0.0b
Copying blob 4a3604715398 [--------------------------------------] 0.0b / 0.0b
Copying config c573a1485d done  
Writing manifest to image destination
Storing signatures
c573a1485dd9c429083bf47f66b9411f9c5898150d1a8f3682fea55386548dc0

skopeo copy --dest-tls-verify=false --authfile ${LOCAL_SECRET_JSON} --all docker://brew.registry.redhat.io/rh-osbs/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd docker://example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8@sha256:ade2f1ba7379d591ba76788888721bb8e65d2c573b08ae78f38d984768725fdd


ocp4.10 new-project open-cluster-management-agent
ocp4.10 -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
ocp4.10 -n open-cluster-management-agent create sa klusterlet
ocp4.10 -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
ocp4.10 -n open-cluster-management-agent create sa klusterlet-registration-sa
ocp4.10 -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
ocp4.10 -n open-cluster-management-agent create sa klusterlet-work-sa
ocp4.10 -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

ocp4.10 new-project open-cluster-management-agent-addon
ocp4.10 -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
ocp4.10 -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
ocp4.10 -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

ocp4.10 project open-cluster-management-agent
echo $CRDS | base64 -d | ocp4.10 apply -f -
echo $IMPORT | base64 -d | ocp4.10 apply -f -

ocp4.10 patch deployment klusterlet -n open-cluster-management-agent --patch='{"spec":{"template":{"spec":{"containers":[{"name": "klusterlet", "image":"example-registry-quay-openshift-operators.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8:latest"}]}}}}'

# 配置 image registry cert
ocp4.10 create configmap registry-cas -n openshift-config --from-file=example-registry-quay-openshift-operators.router-default.apps.ocp4.rhcnsa.com=./example-registry-quay-openshift-operators.apps.ocp4.rhcnsa.com.crt

# 配置 image config
ocp4.10 patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge

# 触发新的 deployment
ocp4.10 patch deployment klusterlet -n open-cluster-management-agent  --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

# pull image
podman pull example-registry-quay-openshift-operators.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8:latest

# 生成证书
openssl s_client -host example-registry-quay-openshift-operators.apps.ocp4.rhcnsa.com -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /etc/pki/ca-trust/source/anchors/a.crt  
update-ca-trust

# aws --endpoint-url http://minio-velero.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/ s3 ls
# aws --endpoint-url http://minio-velero.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/ s3 mb s3://quay

# ocp4.9 quay use local s3 service
cat > config.yaml <<EOF
DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
  default:
  - RadosGWStorage
  - access_key: minio
    secret_key: minioredhat123
    hostname: minio-velero.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com
    bucket_name: quay
    port: 80
    is_secure: false
    storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE: [default]
FEATURE_USER_INITIALIZE: true
FEATURE_USER_CREATION: true
SUPER_USERS:
- quayadmin
EOF
ocp4.9 create secret generic --from-file config.yaml=./config.yaml config-bundle-secret

  configBundleSecret: config-bundle-secret


podman tag example-registry-quay-openshift-operators.apps.ocp4.rhcnsa.com/multicluster-engine/registration-operator-rhel8:latest example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/multicluster-engine/registration-operator-rhel8:latest

podman push example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/multicluster-engine/registration-operator-rhel8:latest

ocp4.10 patch deployment klusterlet -n open-cluster-management-agent --patch='{"spec":{"template":{"spec":{"containers":[{"name": "klusterlet", "image":"example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/multicluster-engine/registration-operator-rhel8:latest"}]}}}}'

ocp4.10 -n open-cluster-management-agent delete secret rhacm
ocp4.10 -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
ocp4.10 patch deployment klusterlet -n open-cluster-management-agent  --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

openssl s_client -host example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /etc/pki/ca-trust/source/anchors/a.crt  

# 报错
exec /registration-operator: exec format error

# https://brewweb.engineering.redhat.com/brew/archiveinfo?archiveID=6145027
podman pull brew.registry.redhat.io/rh-osbs/multicluster-engine-registration-operator-rhel8@sha256:3d84d7341dea1764fde345d9f7723341762fd335f033dc2d8d51c04adb41a17d
podman tag brew.registry.redhat.io/rh-osbs/multicluster-engine-registration-operator-rhel8@sha256:3d84d7341dea1764fde345d9f7723341762fd335f033dc2d8d51c04adb41a17d example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/multicluster-engine/registration-operator-rhel8:latest
podman push example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/multicluster-engine/registration-operator-rhel8:latest

### 在 arm-1 切换到 open-cluster-management-agent-addon namespace
ocp4.10 project open-cluster-management-agent-addon
for sa in klusterlet-addon-appmgr klusterlet-addon-certpolicyctrl klusterlet-addon-iampolicyctrl-sa klusterlet-addon-policyctrl klusterlet-addon-search klusterlet-addon-workmgr ; do
  ocp4.10 -n open-cluster-management-agent-addon patch sa $sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
done
ocp4.10 delete pod --all -n open-cluster-management-agent-addon

# 日志报错
...
W0323 08:27:39.964781       1 builder.go:321] unable to get cluster infrastructure status, using HA cluster values for leader election: infrastructures.config.openshift.io "cluster" is forbidden: User "system:serviceaccount:open-cluster-management-agent:klusterlet" cannot get resource "infrastructures" in API group "config.openshift.io" at the cluster scope
...
E0323 08:21:10.024083       1 leaderelection.go:330] error retrieving resource lock open-cluster-management-agent/klusterlet-lock: leases.coordination.k8s.io "klusterlet-lock" is forbidden: User "system:serviceaccount:open-cluster-management-agent:klusterlet" cannot get resource "leases" in API group "coordination.k8s.io" in the namespace "open-cluster-management-agent"

ocp4.10 adm policy add-scc-to-user anyuid -z klusterlet


podman tag brew.registry.redhat.io/rh-osbs/rhacm2-registration-rhel8@sha256:31be20d77322ac1fc2c287f894af7b929a9ec4907dbb81dd6080233b7bdab74c example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/multicluster-engine/registration-operator-rhel8:latest

[
    {
      "image-name": "registration",
      "image-version": "2.1",
      "image-tag": "2.1-ef3d555e8720c843ab68374b396e02efc24a3f65",
      "git-sha256": "ef3d555e8720c843ab68374b396e02efc24a3f65",
      "git-repository": "stolostron/multiclusterhub-repo",
      "image-remote": "quay.io/stolostron",
      "image-digest": "sha256:9be2ca81e72e5edd9b3d1d9860a126fe4a3a389a1b2c87eefd36629aef2a62a9",
      "image-key": "multiclusterhub_repo"
    }
]


oc image mirror -a ${LOCAL_SECRET_JSON} brew.registry.redhat.io/rh-osbs/rhacm2-registration-rhel8@sha256:31be20d77322ac1fc2c287f894af7b929a9ec4907dbb81dd6080233b7bdab74c example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/rh-osbs/rhacm2-registration-rhel8:latest

podman pull example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/rh-osbs/rhacm2-registration-rhel8:latest --authfile=${LOCAL_SECRET_JSON}

podman pull example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/rh-osbs/rhacm2-registration-rhel8@sha256:31be20d77322ac1fc2c287f894af7b929a9ec4907dbb81dd6080233b7bdab74c --authfile=${LOCAL_SECRET_JSON}

cat > ./registries.conf <<EOF
unqualified-search-registries = ['registry.access.redhat.com', "docker.io"]

[[registry]]
  prefix = ""
  location = "quay.io/openshift/okd-content"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/openshift/okd-content"
EOF


# 参考 https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/pdf/release_notes/red_hat_advanced_cluster_management_for_kubernetes-2.4-release_notes-en-us.pdf
cat > work-image-override.json <<EOF
[
    {
      "image-name": "rhacm2-work-rhel8",
      "image-remote": "example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/rh-osbs",
      "image-digest": "sha256:59aad37dec532c945bbe1938a04441b582bb788414afe85d9bceacfd36c111c0",
      "image-key": "work"
    }
]
EOF

ocp4 -n open-cluster-management create configmap work-image-override --fromfile=./work-image-override.json
ocp4 -n open-cluster-management annotate mch multiclusterhub --overwrite mchimageOverridesCM=work-image-override

# 同步多体系结构镜像
oc image mirror -a ${LOCAL_SECRET_JSON} --filter-by-os=.* brew.registry.redhat.io/rh-osbs/rhacm2-registration-rhel8-operator:v2.5.0-2 example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/rh-osbs/rhacm2-registration-rhel8-operator:v2.5.0-2

# 登录镜像仓库
podman login example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com

# 查看镜像 manifests
podman manifest inspect example-registry-quay-openshift-operators.apps.cluster-k9sh6.k9sh6.sandbox779.opentlc.com/rh-osbs/rhacm2-registration-rhel8-operator:v2.5.0-2

# OpenShift GitOps 1.4.4 的问题解决
oc project openshift-operators
oc edit csv openshift-gitops-operator.v1.4.4
-- vi command
%s/ff4ad30752cf0d321cd6c2c6fd4490b716607ea2960558347440f2f370a586a8/28dfb790f234e8819c7641971956a08e8c7167d6fe8d61594bb952eb5ca84ab1/g

GATEWAY_IP="8.140.106.163"


cat >> /opt/acm/clusters/remove/arm-1 <<'EOF'
CLUSTER_NAME="arm-1"
CLUSTER_KUBECONFIG="/opt/acm/clusters/${CLUSTER_NAME}/kubeconfig"
CLUSTER_API="api.cluster-2nkww.2nkww.sandbox406.opentlc.com"
EOF

remove_clusters



if [ -d /opt/acm/clusters/add ] && [ $(ls -A /opt/acm/clusters/add | wc -m) != "0" ]; then
  for i in /opt/acm/clusters/add/* ; do 
    reset_env
    source $i
    add_cluster
  done
fi

oc --kubeconfig=${HUBECONFIG} get managedcluster arm-1 >/dev/null 2>/dev/null
oc --kubeconfig=${HUBECONFIG} get managedcluster arm-2 >/dev/null 2>/dev/null


# 上传 edge-1 文件到远程主机的目录 /opt/acm/clusters/add 
# 远程主机的程序会扫描这个目录里的文件，根据文件内容添加集群到 acm
# 在被添加的集群执行
add_cluster_to_acm()
# 定义环境变量
SSH_KEY="/root/.ssh/acm"
CLUSTER_NAME="edge-1"
REMOTE_HOST="8.140.106.163"
REMOTE_PORT="6022"
CLUSTER_API="8.130.18.107"

# 生成 kubeconfig，用 CLUSTER_API 替换 127.0.0.1
mkdir -p ~/.kube
podman cp microshift:/var/lib/microshift/resources/kubeadmin/kubeconfig ~/.kube/config
sed -i "s|127.0.0.1|${CLUSTER_API}|g" ~/.kube/config

# 生成配置文件
cat > ${CLUSTER_NAME} <<'EOF'
CLUSTER_NAME="edge-1"
CLUSTER_KUBECONFIG="/opt/acm/clusters/${CLUSTER_NAME}/kubeconfig"
CLUSTER_API="8.130.18.107"
EOF

# 上传配置文件和 kubeconfig
ssh -i ${SSH_KEY} -p ${REMOTE_PORT} ${REMOTE_HOST} mkdir -p /opt/acm/clusters/${CLUSTER_NAME}
scp -i ${SSH_KEY} -P ${REMOTE_PORT} ${CLUSTER_NAME} ${REMOTE_HOST}:/opt/acm/clusters/add
scp -i ${SSH_KEY} -P ${REMOTE_PORT} ~/.kube/config ${REMOTE_HOST}:/opt/acm/clusters/${CLUSTER_NAME}/kubeconfig

# 上传 edge-1 文件到远程主机的目录 /opt/acm/clusters/remove 
# 远程主机的程序会扫描这个目录里的文件，根据文件内容从 acm 删除集群
# 在被删除的集群执行
remove_cluster_from_acm()
# 定义环境变量
SSH_KEY="/root/.ssh/acm"
CLUSTER_NAME="edge-1"
REMOTE_HOST="8.140.106.163"
REMOTE_PORT="6022"
CLUSTER_API="8.130.18.107"

# 生成配置文件
cat > ${CLUSTER_NAME} <<'EOF'
CLUSTER_NAME="edge-1"
CLUSTER_KUBECONFIG="/opt/acm/clusters/${CLUSTER_NAME}/kubeconfig"
CLUSTER_API="8.130.18.107"
EOF

# 上传配置文件和 kubeconfig
scp -i ${SSH_KEY} -P ${REMOTE_PORT} ${CLUSTER_NAME} ${REMOTE_HOST}:/opt/acm/clusters/remove


# install_quay
# create subscription
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: quay-operator
  namespace: openshift-operators
spec:
  channel: stable-3.6
  installPlanApproval: Automatic
  name: quay-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: quay-operator.v3.6.4
EOF

while IFS= read -r line; do
    if [[ "$line" == "Succeededd" ]]; then
          break;
    fi
done < <(ocp4.6 -n openshift-operators get csv quay-operator.v3.6.4 -o jsonpath='{.status.phase}')

oc -n openshift-operators get csv quay-operator.v3.6.4 -o jsonpath='{.status.phase}'


until [ $(ocp4.6 -n openshift-operators get csv quay-operator.v3.6.4 -o jsonpath='{.status.phase}') == "Succeeded" ];
do
  echo "Subscription is installing......"
  sleep 5s
done

sleep 60
oc -n velero get route console -o jsonpath='{.spec.host}'

QUAY_HOSTNAME=$(oc -n velero get route minio -o jsonpath='{.spec.host}{"\n"}')
cat > config.yaml <<EOF
DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
  default:
  - RadosGWStorage
  - access_key: minio
    secret_key: minio123
    hostname: ${QUAY_HOSTNAME}
    bucket_name: velero
    port: 80
    is_secure: false
    storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE: [default]
FEATURE_USER_INITIALIZE: true
FEATURE_USER_CREATION: true
SUPER_USERS:
- quayadmin
EOF

oc -n example-registry create secret generic --from-file config.yaml=./config.yaml config-bundle-secret



cat <<EOF | oc apply -f -
apiVersion: quay.redhat.com/v1
kind: QuayRegistry
metadata:
  name: example-registry
  namespace: example-registry
spec:
  components:
    - managed: false
      kind: clair
    - managed: true
      kind: postgres
    - managed: false
      kind: objectstorage
    - managed: true
      kind: redis
    - managed: true
      kind: horizontalpodautoscaler
    - managed: true
      kind: route
    - managed: false
      kind: mirror
    - managed: false
      kind: monitoring
    - managed: true
      kind: tls
  configBundleSecret: config-bundle-secret
EOF


DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
  default:
  - RadosGWStorage
  - access_key: minio
    secret_key: minio123
    hostname: minio-velero.apps.cluster-f8t4x.f8t4x.sandbox1457.opentlc.com
    bucket_name: velero
    port: 80
    is_secure: false
    storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE: [default]
FEATURE_USER_INITIALIZE: true
FEATURE_USER_CREATION: true
SUPER_USERS:
- quayadmin



报错
oc get events -w 
...
2m18s       Warning   FailedCreate                replicaset/example-registry-quay-redis-78b7cbf75c           (combined from similar events): Error creating: pods "example-registry-quay-redis-78b7cbf75c-pl8ds" is forbidden: [maximum memory usage per Container is 6Gi, but limit is 16Gi, maximum memory usage per Pod is 12Gi, but limit is 17179869184]
0s          Warning   FailedCreate                job/example-registry-quay-app-upgrade                       Error creating: pods "example-registry-quay-app-upgrade-84sc8" is forbidden: maximum memory usage per Container is 6Gi, but limit is 8Gi


报错
main: 2022/03/30 09:45:16.092672 certs.go:65: Info: No usable certificates found, attempting to fetch certificates from sensor ...

common/sensor: 2022/03/31 05:45:19.371762 sensor.go:255: Warn: Error fetching centrals TLS certs: verifying tls challenge: validating certificate chain: using a certificate bundle that was generated from a different Central installation than the one it is trying to connect to: x509: certificate signed by unknown authority

common/sensor: 2022/03/31 05:46:05.419091 sensor.go:318: Error: Sensor reported an error: opening stream: rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: verifying Central certificate errors: [x509: certificate signed by unknown authority, x509: certificate signed by unknown authority]"


# Submeriner
# https://submariner.io/getting-started/quickstart/kind/#prerequisites
oc adm policy add-scc-to-user privileged system:serviceaccount:submariner-operator:submariner-gateway
oc adm policy add-scc-to-user privileged system:serviceaccount:submariner-operator:submariner-routeagent
oc adm policy add-scc-to-user privileged system:serviceaccount:submariner-operator:submariner-globalnet
oc adm policy add-scc-to-user privileged system:serviceaccount:submariner-operator:submariner-lighthouse-coredns

# Broker
# Broker cluster
$ oc new-project submariner-k8s-broker 
$ git clone --depth 1 --single-branch --branch release-0.11 https://github.com/submariner-io/submariner-operator
$ oc apply -k submariner-operator/config/broker -n submariner-k8s-broker
namespace/submariner-k8s-broker configured
serviceaccount/submariner-k8s-broker-admin created
serviceaccount/submariner-k8s-broker-client created
role.rbac.authorization.k8s.io/submariner-k8s-broker-admin created
role.rbac.authorization.k8s.io/submariner-k8s-broker-cluster created
rolebinding.rbac.authorization.k8s.io/submariner-k8s-broker-admin created
rolebinding.rbac.authorization.k8s.io/submariner-k8s-broker-client created


# 设置 openshift 下 serviceaccount 的权限 
# 什么时间执行这条命令呢? 
# 在安装 operator 之前没有这些 sa
$ oc adm policy add-scc-to-user privileged system:serviceaccount:submariner-operator:submariner-gateway
$ oc adm policy add-scc-to-user privileged system:serviceaccount:submariner-operator:submariner-routeagent
(optional) $ oc adm policy add-scc-to-user privileged system:serviceaccount:submariner-operator:submariner-globalnet
(optional) $ oc adm policy add-scc-to-user privileged system:serviceaccount:submariner-operator:submariner-lighthouse-coredns


# https://submariner.io/operations/deployment/
部署 Broker
$ subctl deploy-broker --kubeconfig /Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig 
 ✓ Setting up broker RBAC                                                                                                                                   
 ✓ Deploying the Submariner operator                                                                                                                        
 ✓ Created Lighthouse service accounts and roles                                                                                                            
 ✓ Deployed the operator successfully                                                                                                                       
 ✓ Deploying the broker                                                                                                                                     
 ✓ The broker has been deployed                                                                                                                             
 ✓ Creating broker-info.subm file 
 ✓ A new IPsec PSK will be generated for broker-info.subm

# 加入集群
$ subctl join --kubeconfig /Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig broker-info.subm --clusterid cluster1
$ subctl join --kubeconfig /Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig broker-info.subm --clusterid cluster2
$ subctl join --kubeconfig /Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig broker-info.subm --clusterid cluster3

# 检查 Submariner CRDs
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig get crds | grep -iE 'submariner|multicluster.x-k8s.io'
brokers.submariner.io                                             2022-04-01T05:09:25Z
clusterglobalegressips.submariner.io                              2022-04-01T05:09:46Z
clusters.submariner.io                                            2022-04-01T05:09:46Z
endpoints.submariner.io                                           2022-04-01T05:09:46Z
gateways.submariner.io                                            2022-04-01T05:09:46Z
globalegressips.submariner.io                                     2022-04-01T05:09:46Z
globalingressips.submariner.io                                    2022-04-01T05:09:46Z
servicediscoveries.submariner.io                                  2022-04-01T05:09:41Z
serviceexports.multicluster.x-k8s.io                              2022-04-01T05:09:41Z
serviceimports.multicluster.x-k8s.io                              2022-04-01T05:09:41Z
submariners.submariner.io                                         2022-04-01T05:09:25Z

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig get crds | grep -iE 'submariner|multicluster.x-k8s.io'
brokers.submariner.io                                             2022-04-01T06:05:26Z
clusterglobalegressips.submariner.io                              2022-04-01T06:06:17Z
clusters.submariner.io                                            2022-04-01T06:06:17Z
endpoints.submariner.io                                           2022-04-01T06:06:17Z
gateways.submariner.io                                            2022-04-01T06:06:17Z
globalegressips.submariner.io                                     2022-04-01T06:06:17Z
globalingressips.submariner.io                                    2022-04-01T06:06:17Z
servicediscoveries.submariner.io                                  2022-04-01T06:05:25Z
serviceexports.multicluster.x-k8s.io                              2022-04-01T06:06:07Z
serviceimports.multicluster.x-k8s.io                              2022-04-01T06:06:07Z
submariners.submariner.io                                         2022-04-01T06:05:24Z

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig get crds | grep -iE 'submariner|multicluster.x-k8s.io'
brokers.submariner.io                                                  2022-04-01T02:48:10Z
clusterglobalegressips.submariner.io                                   2022-04-01T02:48:37Z
clusters.submariner.io                                                 2022-03-30T06:29:58Z
endpoints.submariner.io                                                2022-03-30T06:29:58Z
gateways.submariner.io                                                 2022-03-30T06:29:58Z
globalegressips.submariner.io                                          2022-04-01T02:48:37Z
globalingressips.submariner.io                                         2022-04-01T02:48:37Z
servicediscoveries.submariner.io                                       2022-04-01T02:48:29Z
serviceexports.multicluster.x-k8s.io                                   2022-04-01T02:48:29Z
serviceimports.multicluster.x-k8s.io                                   2022-03-30T06:29:58Z
submarinerconfigs.submarineraddon.open-cluster-management.io           2022-03-30T06:29:42Z
submariners.submariner.io                                              2022-04-01T02:48:10Z


$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n submariner-k8s-broker get clusters.submariner.io
NAME       AGE
cluster1   21m
cluster2   10m
cluster3   13m

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n submariner-operator get pods
NAME                                            READY   STATUS    RESTARTS   AGE
submariner-gateway-mw2qv                        1/1     Running   0          23m
submariner-lighthouse-agent-5c8b95666f-b7lbk    1/1     Running   0          23m
submariner-lighthouse-coredns-fb5884785-d55jm   1/1     Running   0          23m
submariner-lighthouse-coredns-fb5884785-vrfnp   1/1     Running   0          23m
submariner-operator-7b6fd97fcf-mp8md            1/1     Running   0          26m
submariner-routeagent-4c495                     1/1     Running   0          23m
submariner-routeagent-69mln                     1/1     Running   0          23m
submariner-routeagent-h9spb                     1/1     Running   0          23m
submariner-routeagent-kcjvw                     1/1     Running   0          23m
submariner-routeagent-pbxv4                     1/1     Running   0          23m

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig -n submariner-operator get pods
NAME                                             READY   STATUS    RESTARTS   AGE
submariner-gateway-vs2cj                         1/1     Running   0          12m
submariner-lighthouse-agent-7459b656c8-wtnh8     1/1     Running   0          12m
submariner-lighthouse-coredns-79dcc466fb-585zp   1/1     Running   0          12m
submariner-lighthouse-coredns-79dcc466fb-dmfx7   1/1     Running   0          12m
submariner-operator-7b6fd97fcf-s2lbk             1/1     Running   1          13m
submariner-routeagent-c2kvz                      1/1     Running   0          12m
submariner-routeagent-jpgsd                      1/1     Running   0          12m
submariner-routeagent-lnws7                      1/1     Running   0          12m
submariner-routeagent-m7bjs                      1/1     Running   0          12m
submariner-routeagent-skpzb                      1/1     Running   0          12m
submariner-routeagent-xxvvv                      1/1     Running   0          12m

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig -n submariner-operator get pods
NAME                                            READY   STATUS    RESTARTS   AGE
submariner-gateway-h4jtf                        1/1     Running   0          15m
submariner-lighthouse-agent-57599bdd94-9l62f    1/1     Running   0          15m
submariner-lighthouse-coredns-545b557bc-6d9k6   1/1     Running   0          15m
submariner-lighthouse-coredns-545b557bc-zwcsh   1/1     Running   0          15m
submariner-operator-7b6fd97fcf-h49gn            1/1     Running   0          16m
submariner-routeagent-7kn8w                     1/1     Running   0          15m
submariner-routeagent-8q5jq                     1/1     Running   0          15m
submariner-routeagent-gnbdw                     1/1     Running   0          15m
submariner-routeagent-kj86z                     1/1     Running   0          15m
submariner-routeagent-rr2z4                     1/1     Running   0          15m

# ocp4.9 - 查看 node 信息
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig get node --selector=submariner.io/gateway=true -o wide
NAME                                         STATUS   ROLES    AGE     VERSION                INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                                                       KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-0-184-252.us-east-2.compute.internal   Ready    worker   4h17m   v1.22.0-rc.0+894a78b   10.0.184.252   <none>        Red Hat Enterprise Linux CoreOS 49.84.202110081407-0 (Ootpa)   4.18.0-305.19.1.el8_4.x86_64   cri-o://1.22.0-73.rhaos4.9.gitbdf286c.el8

$ subctl show connections --kubeconfig /Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig 
Cluster "api-cluster-6lr59-6lr59-sandbox311-opentlc-com:6443"
 ✓ Showing Connections 
GATEWAY         CLUSTER   REMOTE IP     NAT  CABLE DRIVER  SUBNETS                       STATUS      RTT avg.    
ip-10-0-157-55  cluster3  3.134.151.45  yes  libreswan     172.30.0.0/16, 10.128.0.0/14  connecting  335.107µs   
...

# ocp4.8 - 查看 node 信息
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig get node --selector=submariner.io/gateway=true -o wide
NAME                                         STATUS   ROLES    AGE     VERSION           INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                                                       KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-0-151-235.us-east-2.compute.internal   Ready    worker   2d21h   v1.21.8+8a3bf4a   10.0.151.235   <none>        Red Hat Enterprise Linux CoreOS 48.84.202203072154-0 (Ootpa)   4.18.0-305.34.2.el8_4.x86_64   cri-o://1.21.5-2.rhaos4.8.gitaf64931.el
...

$ subctl show connections --kubeconfig /Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig
Cluster "api-cluster-lr8jz-lr8jz-sandbox1298-opentlc-com:6443"
 ✓ Showing Connections 
GATEWAY          CLUSTER   REMOTE IP    NAT  CABLE DRIVER  SUBNETS                       STATUS      RTT avg.    
ip-10-0-184-252  cluster1  3.18.211.90  yes  libreswan     172.30.0.0/16, 10.128.0.0/14  connecting  1.168767ms
...

# ocp4.6 - 查看 node 信息
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig get node --selector=submariner.io/gateway=true -o wide
NAME                                        STATUS   ROLES    AGE    VERSION           INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                       KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-0-157-55.us-east-2.compute.internal   Ready    worker   4d4h   v1.19.0+9f84db3   10.0.157.55   <none>        Red Hat Enterprise Linux CoreOS 46.82.202011061621-0 (Ootpa)   4.18.0-193.29.1.el8_2.x86_64   cri-o://1.19.0-22.rhaos4.6.gitc0306f1.el8

$ subctl show connections --kubeconfig /Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig
...
Cluster "api-cluster-f8t4x-f8t4x-sandbox1457-opentlc-com:6443"
 ✓ Showing Connections 
GATEWAY          CLUSTER   REMOTE IP    NAT  CABLE DRIVER  SUBNETS                       STATUS      RTT avg.    
ip-10-0-184-252  cluster1  3.18.211.90  yes  libreswan     172.30.0.0/16, 10.128.0.0/14  connecting  813.154µs

# 检查 Service Discovery (Lighthouse) 是否正常运行
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig get crds | grep -iE 'multicluster.x-k8s.io'
serviceexports.multicluster.x-k8s.io                              2022-04-01T05:09:41Z
serviceimports.multicluster.x-k8s.io                              2022-04-01T05:09:41Z

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig get crds | grep -iE 'multicluster.x-k8s.io'
serviceexports.multicluster.x-k8s.io                              2022-04-01T06:06:07Z
serviceimports.multicluster.x-k8s.io                              2022-04-01T06:06:07Z

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig get crds | grep -iE 'multicluster.x-k8s.io'
serviceexports.multicluster.x-k8s.io                                   2022-04-01T02:48:29Z
serviceimports.multicluster.x-k8s.io                                   2022-03-30T06:29:58Z

# 检查服务 submariner-lighthouse-coredns 是否 Ready
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n submariner-operator get service submariner-lighthouse-coredns
NAME                            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
submariner-lighthouse-coredns   ClusterIP   172.30.205.37   <none>        53/UDP    36m

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig -n submariner-operator get service submariner-lighthouse-coredns
NAME                            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
submariner-lighthouse-coredns   ClusterIP   172.30.144.30   <none>        53/UDP    25m

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig -n submariner-operator get service submariner-lighthouse-coredns
submariner-lighthouse-coredns   ClusterIP   172.30.42.198   <none>        53/UDP    29m

# 检查 CoreDNS 服务是否将请求 clusterset.local 转发给 Lighthouse CoreDNS 服务器
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n openshift-dns get configmap dns-default -o yaml 
...
data:
  Corefile: |
    # lighthouse
    clusterset.local:5353 {
        forward . 172.30.205.37
        errors
        bufsize 512
    }
...

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig -n openshift-dns get configmap dns-default -o yaml 
...
data:
  Corefile: |
    # lighthouse
    clusterset.local:5353 {
        forward . 172.30.144.30
        errors
        bufsize 512
    }
...

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig -n openshift-dns get configmap dns-default -o yaml 
...
data:
  Corefile: |
    # lighthouse
    clusterset.local:5353 {
        forward . 172.30.42.198
    }

# 创建 nginx-test 
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig create namespace nginx-test
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n nginx-test create deployment nginx --image=nginxinc/nginx-unprivileged:stable-alpine

$ cat <<EOF | oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx
  name: nginx
  namespace: nginx-test
spec:
  ports:
  - name: http
    port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: nginx
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
EOF

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n nginx-test get service nginx
NAME    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
nginx   ClusterIP   172.30.49.126   <none>        8080/TCP   43s

$ subctl --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig export service --namespace nginx-test nginx
Service exported successfully

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.9/lb-ext.kubeconfig -n nginx-test describe serviceexports
Name:         nginx
Namespace:    nginx-test
Labels:       <none>
Annotations:  <none>
API Version:  multicluster.x-k8s.io/v1alpha1
Kind:         ServiceExport
Metadata:
  Creation Timestamp:  2022-04-01T06:45:58Z
  Generation:          1
  Resource Version:    106865
  UID:                 03b41e6b-1a6a-4c16-91dd-9a35578723ed
Status:
  Conditions:
    Last Transition Time:  2022-04-01T06:45:58Z
    Message:               Awaiting sync of the ServiceImport to the broker
    Reason:                AwaitingSync
    Status:                False
    Type:                  Valid
    Last Transition Time:  2022-04-01T06:45:58Z
    Message:               Service was successfully synced to the broker
    Reason:                
    Status:                True
    Type:                  Valid
Events:                    <none>

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig  get -n submariner-operator serviceimport
NAME                        TYPE           IP                  AGE
nginx-nginx-test-cluster1   ClusterSetIP   ["172.30.49.126"]   119s

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig create namespace nginx-test
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.8/lb-ext.kubeconfig run -n nginx-test tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash
bash-5.0# curl nginx.nginx-test.svc.clusterset.local:8080
curl: (6) Could not resolve host: nginx.nginx-test.svc.clusterset.local

$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig  get -n submariner-operator serviceimport
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig create namespace nginx-test
$ oc --kubeconfig=/Users/junwang/kubeconfig/ocp4.6/lb-ext.kubeconfig run -n nginx-test tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash
bash-5.0# curl nginx.nginx-test.svc.clusterset.local:8080


# yum install -y 


https://submariner.io/getting-started/quickstart/external/

# Test mysql 


oc project test
ocp4.9 apply -f ./mariadb-galera-persistent-template4.yml 
oc adm policy add-scc-to-user anyuid -z default -n test

报错
220406 05:32:19 mysqld_safe Starting mariadbd daemon with databases from /var/opt/rh/rh-mariadb105/lib/mysql
/opt/rh/rh-mariadb105/root/usr/bin/mysqld_safe_helper: Can't create/write to file '/var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log' (Errcode: 13 "Permission denied")

mysqld_safe --wsrep-cluster-address=gcomm:// --basedir=~ --datadir=~ --pid-file=~/mariadb.pid --skip-grant-tables --skip-networking --socket=/var/run/mysql/mysql-init.sock --wsrep_on=OFF --skip-syslog &


+ eval 'nohup /opt/rh/rh-mariadb105/root/usr/libexec/mariadbd   --basedir=/opt/rh/rh-mariadb105/root/usr --datadir=/var/opt/rh/rh-mariadb105/lib/mysql --plugin-dir=/opt/rh/rh-mariadb105/root/usr/lib64/mariadb/plugin   --wsrep_on=ON --wsrep_provider=/opt/rh/rh-mariadb105/root/usr/lib64/galera/libgalera_smm.so --wsrep-cluster-address=gcomm\:// --skip-grant-tables --skip-networking --wsrep_on=OFF --log-error=/var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log --pid-file=/run/rh-mariadb105-mariadb/mariadb.pid --socket=/var/run/mysql/mysql-init.sock < /dev/null 2>&1 | /opt/rh/rh-mariadb105/root/usr/bin/mysqld_safe_helper mysql log /var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log'
++ nohup /opt/rh/rh-mariadb105/root/usr/libexec/mariadbd --basedir=/opt/rh/rh-mariadb105/root/usr --datadir=/var/opt/rh/rh-mariadb105/lib/mysql --plugin-dir=/opt/rh/rh-mariadb105/root/usr/lib64/mariadb/plugin --wsrep_on=ON --wsrep_provider=/opt/rh/rh-mariadb105/root/usr/lib64/galera/libgalera_smm.so --wsrep-cluster-address=gcomm:// --skip-grant-tables --skip-networking --wsrep_on=OFF --log-error=/var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log --pid-file=/run/rh-mariadb105-mariadb/mariadb.pid --socket=/var/run/mysql/mysql-init.sock
++ /opt/rh/rh-mariadb105/root/usr/bin/mysqld_safe_helper mysql log /var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log
/opt/rh/rh-mariadb105/root/usr/bin/mysqld_safe_helper: Can't create/write to file '/var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log' (Errcode: 13 "Permission denied")


nohup /opt/rh/rh-mariadb105/root/usr/libexec/mariadbd --basedir=/opt/rh/rh-mariadb105/root/usr --datadir=/var/lib/mysql --plugin-dir=/opt/rh/rh-mariadb105/root/usr/lib64/mariadb/plugin --wsrep_on=ON --wsrep_provider=/opt/rh/rh-mariadb105/root/usr/lib64/galera/libgalera_smm.so --wsrep-cluster-address=gcomm:// --skip-grant-tables --skip-networking --wsrep_on=OFF --log-error=~/mariadb.log --pid-file=/run/rh-mariadb105-mariadb/mariadb.pid --socket=/var/run/mysql/mysql-init.sock

2022-04-06  5:57:53 0 [ERROR] mariadbd: Can't create/write to file '/var/opt/rh/rh-mariadb105/lib/mysql/aria_log_control' (Errcode: 13 "Per
mission denied")


2022-04-06  5:57:53 0 [ERROR] InnoDB: Operating system error number 13 in a file operation.
2022-04-06  5:57:53 0 [ERROR] InnoDB: The error means mysqld does not have the access rights to the directory.
2022-04-06  5:57:53 0 [ERROR] InnoDB: Operating system error number 13 in a file operation.
2022-04-06  5:57:53 0 [ERROR] InnoDB: The error means mysqld does not have the access rights to the directory.
2022-04-06  5:57:53 0 [ERROR] InnoDB: Cannot open datafile './ibdata1'
2022-04-06  5:57:53 0 [Note] InnoDB: If the mysqld execution user is authorized, page cleaner thread priority can be changed. See the man p
age of setpriority().
2022-04-06  5:57:53 0 [ERROR] InnoDB: Could not open or create the system tablespace. If you tried to add new data files to the system tabl
espace, and it failed here, you should now edit innodb_data_file_path in my.cnf back to what it was, and remove the new ibdata files InnoDB
 created in this failed attempt. InnoDB only wrote those files full of zeros, but did not yet use them in any way. But be careful: do not r
emove old data files which contain your precious data!
2022-04-06  5:57:53 0 [ERROR] InnoDB: Database creation was aborted with error Cannot open a file. You may need to delete the ibdata1 file 
before trying to start up again.
2022-04-06  5:57:53 0 [Note] InnoDB: Starting shutdown...
2022-04-06  5:57:54 0 [ERROR] Plugin 'InnoDB' init function returned error.
2022-04-06  5:57:54 0 [ERROR] Plugin 'InnoDB' registration as a STORAGE ENGINE failed.
2022-04-06  5:57:54 0 [Note] Plugin 'FEEDBACK' is disabled.
2022-04-06  5:57:54 0 [ERROR] Failed to initialize plugins.
2022-04-06  5:57:54 0 [ERROR] Aborting
2022-04-06  5:59:03 0 [Warning] You need to use --log-bin to make --binlog-format work.


      reason: ContainersNotReady
      message: 'containers with unready status: [mariadb-galera]'

7m33s       Warning   FailedToUpdateEndpointSlices   service/galera                          Error updating Endpoint Slices for Service test/galera: failed to update galera-9s597 EndpointSlice for Service test/galera: Operation cannot be fulfilled on endpointslices.discovery.k8s.io "galera-9s597": the object has been modified; please apply your changes to the latest version and try again



```

### DB script
```
/bin/bash /usr/bin/container-entrypoint.sh
#!/bin/bash
#
# Adfinis SyGroup AG
# openshift-mariadb-galera: Container entrypoint
#

set -e
set -x

# Locations
CONTAINER_SCRIPTS_DIR="/usr/share/container-scripts/mysql"
EXTRA_DEFAULTS_FILE="/etc/opt/rh/rh-mariadb105/my.cnf.d"

# Check if the container runs in Kubernetes/OpenShift
if [ -z "$POD_NAMESPACE" ]; then
        # Single container runs in docker
        echo "POD_NAMESPACE not set, spin up single node"
else
        # Is running in Kubernetes/OpenShift, so find all other pods
        # belonging to the namespace
        echo "Galera: Finding peers"
        K8S_SVC_NAME=$(hostname -f | cut -d"." -f2)
        echo "Using service name: ${K8S_SVC_NAME}"
        cp ${CONTAINER_SCRIPTS_DIR}/galera.cnf ${EXTRA_DEFAULTS_FILE}
        /usr/bin/peer-finder -on-start="${CONTAINER_SCRIPTS_DIR}/configure-galera.sh" -service=${K8S_SVC_NAME}
fi

# We assume that mysql needs to be setup if this directory is not present
if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "Configure first time mysql"
        ${CONTAINER_SCRIPTS_DIR}/configure-mysql.sh
else
        nodelist=$(cat ${EXTRA_DEFAULTS_FILE}/galera.cnf | grep gcomm:// | awk -F 'gcomm://' '{print $2;}' | sed 's/,/ /g' )
        if [ "$nodelist" != "" ] ; then
           is_alive=0
           set +e
           for node in $nodelist ; do
              echo $node
              MYSQL_USER="readinessProbe"
              MYSQL_PASS="readinessProbe"
              MYSQL_HOST=$node
              mysql -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST} -e"SHOW DATABASES;"
              if [ $? -ne 0 ]; then
                 continue;
              else
                 is_alive=1
                 break
              fi
           done
#           if [ $is_alive -eq 0 ] ; then
#                #bootstrap database
#                mysqld --wsrep-new-cluster
#           fi
        fi
fi


CFG=/etc/opt/rh/rh-mariadb105/my.cnf.d/galera.cnf

while true;
        do

        domain=`hostname -f | awk -F\. '{for(i=2; i<NF;i++){printf $i"."}printf $NF"\n"}'`
        addrs=""
        for addr in $(nslookup $domain | grep Address: | grep -v \#53 | awk -F ':' '{print $2}' | awk '{print $1}') ; do addrs="$addr,$addrs"; done
        if [ "$PEER_DNS_IP" != "" ] ; then
            for addr in $(nslookup $domain $PEER_DNS_IP | grep Address: | grep -v \#53 | awk -F ':' '{print $2}' | awk '{print $1}') ; do addrs="$addr,$addrs"; done 
        fi
        WSREP_CLUSTER_ADDRESS=$(echo $addrs | sed s'/,$//')
        sed -i -e "s|^wsrep_cluster_address=.*$|wsrep_cluster_address=gcomm://${WSREP_CLUSTER_ADDRESS}|" ${CFG}
        MY_IP=`host $(hostname -f) | awk -F 'has address' '{print $2;}' | awk '{print $1}'`
        sed -i -e "s|^wsrep_node_address=.*$|wsrep_node_address=${MY_IP}|" ${CFG}

        is_alive=0
        nodelist=$(cat ${EXTRA_DEFAULTS_FILE}/galera.cnf | grep gcomm:// | awk -F 'gcomm://' '{print $2;}' | sed 's/,/ /g' )
        if [ "$nodelist" != "" ] ; then
           set +e
           for node in $nodelist ; do
              echo $node
              MYSQL_USER="readinessProbe"
              MYSQL_PASS="readinessProbe"
              MYSQL_HOST=$node
              mysql -u${MYSQL_USER} -p${MYSQL_PASS} -h${MYSQL_HOST} -e"SHOW DATABASES;"
              if [ $? -ne 0 ]; then
                 continue;
              else
                 is_alive=1
                 break
              fi
           done
        fi
        if [ $is_alive -eq 0 ] ; then
            for ii in $(hostname | sed 's/-/ /g') ; do nii=$ii ; done
            if [ "$nii" != "0" ] ; then
                sleep 60
            else
                mysqld --wsrep-new-cluster
            fi
        fi
        # Run mysqld
        #exec mysqld --socket=/var/run/mysql/mysql.sock --log-error=/var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log
        #mysqld --socket=/var/run/mysql/mysql.sock --log-error=/var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log
        #nodelist=$(cat ${EXTRA_DEFAULTS_FILE}/galera.cnf | grep gcomm:// | awk -F 'gcomm://' '{print $2;}')
        #mysqld --socket=/var/run/mysql/mysql.sock --log-error=/var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log --wsrep-cluster-address=gcomm://$nodelist
        mysqld
        sleep 1m
done
```


```
# 为模版里的 Pod 添加 
# securityContext: 
#  privileged: true
https://stackoverflow.com/questions/68543425/start-pod-with-root-privilege-on-openshift

# 清理环境
oc delete buildconfig rails-mysql-persistent 
oc delete deploymentconfig rails-mysql-persistent
oc delete is rails-mysql-persistent
oc delete route rails-mysql-persistent
oc delete service rails-mysql-persistent

oc delete statefulset galera
oc delete service galera

oc delete secret rails-mysql-persistent 
oc delete $(oc get secret -o name | grep mariadb-galera-persistent-storageclass) 

oc delete pvc galera-galera-0
oc delete pvc galera-galera-1
oc delete pvc galera-galera-2

# 编辑模版
# 为模版里的 StatefulSet spec->template->spec 和 spec->template->spec->containers 添加 
# securityContext: 
#  privileged: true
# 
#    template:
#      ...
#      spec:
#        securityContext:
#          privileged: true
#        containers:
#        - name: "${GALERA_PETSET_NAME}"
#          securityContext:
#            privileged: true
#          env:                
#            - name: POD_NAMESPACE
#          ...
https://stackoverflow.com/questions/68543425/start-pod-with-root-privilege-on-openshift

# 为 serviceaccount default 设置 priviledged RoleBinding
oc adm policy add-scc-to-user privileged -z default

# new-app
oc new-app --template=test/mariadb-galera-persistent-storageclass-tony -p STORAGE_CLASS="gp2" -p SOURCE_REPOSITORY_URL="https://github.com/sclorg/rails-ex.git"
...
    * With parameters: 
        * Name=rails-mysql-persistent 
        * Namespace=openshift 
        * Memory Limit=512Mi
        * Memory Limit (MYSQL)=512Mi
        * Git Repository URL=https://github.com/tonyli71/rails-ex.git
        * Git Reference=
        * Context Directory=
        * Application Hostname=
        * GitHub Webhook Secret=Iv8M7k5WbuAwLU8rJq7c7JRbyFg7fmOVlwoVEWns # generated
        * Rails Environment=production
        * Database Service Name for the MariaDB service=galera
        * GALERA_PETSET_NAME=mariadb-galera
        * NUMBER_OF_GALERA_MEMBERS=3
        * VOLUME_PV_NAME=datadir
        * VOLUME_CAPACITY=5Gi
        * DATABASE_USER=demouser
        * MYSQL_DATABASE=userdb
        * Volume Storage Class=ocs-storagecluster-ceph-mirror
        * Database Password, The password for the root user=redhat
        * DATABASE_USER_PASSWORD=NOT_REAL_PASSWORD
        * Application Username=openshift
        * Application Password=NOT_REAL_PASSWORD
        * Secret Key=NOT_REAL_KEY
        * Custom RubyGems Mirror URL=
        * Peer DNS IP on Submariner=

查询状态
$ mysql -u demouser -p
MariaDB [(none)]> show status like 'wsrep_cluster_size';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+

MariaDB [(none)]> MariaDB [(none)]> show status like 'wsrep%';
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+
| Variable_name                 | Value                                                                                                                                          |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+
| wsrep_local_state_uuid        | dde12dbd-b61d-11ec-b308-4e894382fb5d                                                                                                           |
| wsrep_protocol_version        | 10                                                                                                                                             |
| wsrep_last_committed          | 3                                                                                                                                              |
| wsrep_replicated              | 0                                                                                                                                              |
| wsrep_replicated_bytes        | 0                                                                                                                                              |
| wsrep_repl_keys               | 0                                                                                                                                              |
| wsrep_repl_keys_bytes         | 0                                                                                                                                              |
| wsrep_repl_data_bytes         | 0                                                                                                                                              |
| wsrep_repl_other_bytes        | 0                                                                                                                                              |
| wsrep_received                | 10                                                                                                                                             |
| wsrep_received_bytes          | 824                                                                                                                                            |
| wsrep_local_commits           | 0                                                                                                                                              |
| wsrep_local_cert_failures     | 0                                                                                                                                              |
| wsrep_local_replays           | 0                                                                                                                                              |
| wsrep_local_send_queue        | 0                                                                                                                                              |
| wsrep_local_send_queue_max    | 2                                                                                                                                              |
| wsrep_local_send_queue_min    | 0                                                                                                                                              |
| wsrep_local_send_queue_avg    | 0.5                                                                                                                                            |
| wsrep_local_recv_queue        | 0                                                                                                                                              |
| wsrep_local_recv_queue_max    | 1                                                                                                                                              |
| wsrep_local_recv_queue_min    | 0                                                                                                                                              |
| wsrep_local_recv_queue_avg    | 0                                                                                                                                              |
| wsrep_local_cached_downto     | 1                                                                                                                                              |
| wsrep_flow_control_paused_ns  | 0                                                                                                                                              |
| wsrep_flow_control_paused     | 0                                                                                                                                              |
| wsrep_flow_control_sent       | 0                                                                                                                                              |
| wsrep_flow_control_recv       | 0                                                                                                                                              |
| wsrep_flow_control_active     | false                                                                                                                                          |
| wsrep_flow_control_requested  | false                                                                                                                                          |
| wsrep_cert_deps_distance      | 0                                                                                                                                              |
| wsrep_apply_oooe              | 0                                                                                                                                              |
| wsrep_apply_oool              | 0                                                                                                                                              |
| wsrep_apply_window            | 0                                                                                                                                              |
| wsrep_commit_oooe             | 0                                                                                                                                              |
| wsrep_commit_oool             | 0                                                                                                                                              |
| wsrep_commit_window           | 0                                                                                                                                              |
| wsrep_local_state             | 4                                                                                                                                              |
| wsrep_local_state_comment     | Synced                                                                                                                                         |
| wsrep_cert_index_size         | 0                                                                                                                                              |
| wsrep_causal_reads            | 0                                                                                                                                              |
| wsrep_cert_interval           | 0                                                                                                                                              |
| wsrep_open_transactions       | 0                                                                                                                                              |
| wsrep_open_connections        | 0                                                                                                                                              |
| wsrep_incoming_addresses      | AUTO,AUTO,AUTO                                                                                                                                 |
| wsrep_cluster_weight          | 3                                                                                                                                              |
| wsrep_desync_count            | 0                                                                                                                                              |
| wsrep_evs_delayed             |                                                                                                                                                |
| wsrep_evs_evict_list          |                                                                                                                                                |
| wsrep_evs_repl_latency        | 0/0/0/0/0                                                                                                                                      |
| wsrep_evs_state               | OPERATIONAL                                                                                                                                    |
| wsrep_gcomm_uuid              | dde0b62e-b61d-11ec-82eb-af258099b9b2                                                                                                           |
| wsrep_gmcast_segment          | 0                                                                                                                                              |
| wsrep_applier_thread_count    | 1                                                                                                                                              |
| wsrep_cluster_capabilities    |                                                                                                                                                |
| wsrep_cluster_conf_id         | 3                                                                                                                                              |
| wsrep_cluster_size            | 3                                                                                                                                              |
| wsrep_cluster_state_uuid      | dde12dbd-b61d-11ec-b308-4e894382fb5d                                                                                                           |
| wsrep_cluster_status          | Primary                                                                                                                                        |
| wsrep_connected               | ON                                                                                                                                             |
| wsrep_local_bf_aborts         | 0                                                                                                                                              |
| wsrep_local_index             | 0                                                                                                                                              |
| wsrep_provider_capabilities   | :MULTI_MASTER:CERTIFICATION:PARALLEL_APPLYING:TRX_REPLAY:ISOLATION:PAUSE:CAUSAL_READS:INCREMENTAL_WRITESET:UNORDERED:PREORDERED:STREAMING:NBO: |
| wsrep_provider_name           | Galera                                                                                                                                         |
| wsrep_provider_vendor         | Codership Oy <info@codership.com>                                                                                                              |
| wsrep_provider_version        | 4.7(rXXXX)                                                                                                                                     |
| wsrep_ready                   | ON                                                                                                                                             |
| wsrep_rollbacker_thread_count | 1                                                                                                                                              |
| wsrep_thread_count            | 2                                                                                                                                              |
+-------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+


ocp4.7 patch statefulset/galera --type json -p='[{"op": "replace", "path": "/spec/replicas", "value":"0"}]'
ocp4.7 patch statefulset/galera --patch '{"spec":{"replicas":3}}' --type=merge

# 下载 tonyli mariadb 镜像
podman pull quay.io/tonyli71/mariadb-galera:latest 

# 本地运行 quay.io/tonyli71/mariadb-galera:latest
podman run --name test-mariadb --rm --ti quay.io/tonyli71/mariadb-galera:latest 

# copy /usr/bin/container-entrypoint.sh 
podman cp test-mariadb:/usr/bin/container-entrypoint.sh container-entrypoint.sh.orig

# 修改 container-entrypoint.sh，增加 template 参数 PEER1_DNS_IP 和 PEER2_DNS_IP
(oc-mirror)[root@jwang ~/testdb]# diff -urN container-entrypoint.sh.orig container-entrypoint.sh 
--- container-entrypoint.sh.orig        2021-10-15 00:03:14.000000000 +0800
+++ container-entrypoint.sh     2022-04-07 16:22:10.404834304 +0800
@@ -63,8 +63,11 @@
         domain=`hostname -f | awk -F\. '{for(i=2; i<NF;i++){printf $i"."}printf $NF"\n"}'`
         addrs=""
         for addr in $(nslookup $domain | grep Address: | grep -v \#53 | awk -F ':' '{print $2}' | awk '{print $1}') ; do addrs="$addr,$addrs"; done
-        if [ "$PEER_DNS_IP" != "" ] ; then
-            for addr in $(nslookup $domain $PEER_DNS_IP | grep Address: | grep -v \#53 | awk -F ':' '{print $2}' | awk '{print $1}') ; do addrs="$addr,$addrs"; done 
+        if [ "$PEER1_DNS_IP" != "" ] ; then
+            for addr in $(nslookup $domain $PEER1_DNS_IP | grep Address: | grep -v \#53 | awk -F ':' '{print $2}' | awk '{print $1}') ; do addrs="$addr,$addrs"; done 
+        fi
+        if [ "$PEER2_DNS_IP" != "" ] ; then
+            for addr in $(nslookup $domain $PEER2_DNS_IP | grep Address: | grep -v \#53 | awk -F ':' '{print $2}' | awk '{print $1}') ; do addrs="$addr,$addrs"; done 
         fi
         WSREP_CLUSTER_ADDRESS=$(echo $addrs | sed s'/,$//')
         sed -i -e "s|^wsrep_cluster_address=.*$|wsrep_cluster_address=gcomm://${WSREP_CLUSTER_ADDRESS}|" ${CFG}

podman run --name test-mariadb --rm --ti quay.io/tonyli71/mariadb-galera:latest 

# 生成 DockerFile 
cat > Dockerfile << EOF
FROM quay.io/tonyli71/mariadb-galera:latest

COPY container-entrypoint.sh /usr/bin/container-entrypoint.sh

USER root
RUN chmod a+x /usr/bin/container-entrypoint.sh

ENTRYPOINT ["/usr/bin/container-entrypoint.sh"]
EOF


# 构建镜像
podman build . -t mariadb-galera-3-cluster:latest
# tag 镜像
podman tag localhost/mariadb-galera-3-cluster:latest quay.io/jwang1/mariadb-galera-3-cluster:v1.0.2

# 登录镜像服务器
podman login -u "jwang1" quay.io
# 上传镜像
podman push quay.io/jwang1/mariadb-galera-3-cluster:v1.0.2
```

### 检查 submariner，诊断 submariner
```
$ subctl show all --kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig 
Cluster "microshift"
 ✓ Detecting broker(s)

 ✓ Showing Connections
GATEWAY             CLUSTER   REMOTE IP      NAT  CABLE DRIVER  SUBNETS       STATUS  RTT avg.
edge-1.example.com  cluster1  10.66.208.162  no   libreswan     242.0.0.0/16  error   0s
edge-3.example.com  cluster3  10.66.208.164  no   libreswan     242.2.0.0/16  error   0s

 ✓ Showing Endpoints
CLUSTER ID                    ENDPOINT IP     PUBLIC IP       CABLE DRIVER        TYPE
cluster2                      10.66.208.163   119.254.120.68  libreswan           local
cluster1                      10.66.208.162   119.254.120.68  libreswan           remote
cluster3                      10.66.208.164   119.254.120.68  libreswan           remote

 ✓ Showing Gateways
NODE                            HA STATUS       SUMMARY
edge-2.example.com              active          0 connections out of 2 are established

    Discovered network details via Submariner:
 ✓ Showing Network details
        Network plugin:  generic
        Service CIDRs:   [10.43.0.0/16]
        Cluster CIDRs:   [10.42.0.0/24]
        Global CIDR:     242.1.0.0/16

 ✓ Showing versions
COMPONENT                       REPOSITORY                                            VERSION
submariner                      quay.io/submariner                                    0.12.0
submariner-operator             quay.io/submariner                                    0.12.0
service-discovery               quay.io/submariner                                    0.12.0
COMPONENT                       REPOSITORY                                            VERSION
submariner                      quay.io/submariner                                    0.12.0
submariner-operator             quay.io/submariner                                    0.12.0
service-discovery               quay.io/submariner                                    0.12.0

Cluster "10-66-208-163:6443"
 ✓ Detecting broker(s)

 ✓ Showing Connections
GATEWAY             CLUSTER   REMOTE IP      NAT  CABLE DRIVER  SUBNETS       STATUS  RTT avg.
edge-1.example.com  cluster1  10.66.208.162  no   libreswan     242.0.0.0/16  error   0s
edge-3.example.com  cluster3  10.66.208.164  no   libreswan     242.2.0.0/16  error   0s

 ✓ Showing Endpoints
CLUSTER ID                    ENDPOINT IP     PUBLIC IP       CABLE DRIVER        TYPE
cluster2                      10.66.208.163   119.254.120.68  libreswan           local
cluster1                      10.66.208.162   119.254.120.68  libreswan           remote
cluster3                      10.66.208.164   119.254.120.68  libreswan           remote

 ✓ Showing Gateways
NODE                            HA STATUS       SUMMARY
edge-2.example.com              active          0 connections out of 2 are established

    Discovered network details via Submariner:
 ✓ Showing Network details
        Network plugin:  generic
        Service CIDRs:   [10.43.0.0/16]
        Cluster CIDRs:   [10.42.0.0/24]
        Global CIDR:     242.1.0.0/16

 ✓ Showing versions
COMPONENT                       REPOSITORY                                            VERSION
submariner                      quay.io/submariner                                    0.12.0
submariner-operator             quay.io/submariner                                    0.12.0
service-discovery               quay.io/submariner                                    0.12.0
COMPONENT                       REPOSITORY                                            VERSION
submariner                      quay.io/submariner                                    0.12.0
submariner-operator             quay.io/submariner                                    0.12.0
    
# check submariner-globalnet pod log
oc -n submariner-operator logs $(oc -n submariner-operator get pods -l app='submariner-globalnet' -o name)  | grep -Ev "^I0" -A2

# 为 grafana-serviceaccount 添加 ClusterRole cluster-monitoring-view
# 获取 bearer toke 
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z grafana-serviceaccount
oc serviceaccounts get-token grafana-serviceaccount

# submariner-gateway 日志
I0412 05:57:03.474107       1 main.go:93] Starting the submariner gateway engine
W0412 05:57:03.474916       1 client_config.go:608] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
I0412 05:57:03.483922       1 main.go:115] Creating the cable engine
E0412 05:57:13.513385       1 public_ip.go:81] Error resolving public IP with resolver api:api.ipify.org : retrieving public IP from https://api.ipify.org: Get "https://api.ipify.org": dial tcp: lookup api.ipify.org on 192.168.122.12:53: server misbehaving
E0412 05:57:23.516982       1 public_ip.go:81] Error resolving public IP with resolver api:api.my-ip.io/ip : retrieving public IP from https://api.my-ip.io/ip: Get "https://api.my-ip.io/ip": dial tcp: lookup api.my-ip.io on 192.168.122.12:53: server misbehaving
E0412 05:57:33.521753       1 public_ip.go:81] Error resolving public IP with resolver api:ip4.seeip.org : retrieving public IP from https://ip4.seeip.org: Get "https://ip4.seeip.org": dial tcp: lookup ip4.seeip.org on 192.168.122.12:53: server misbehaving
F0412 05:57:33.522169       1 main.go:267] Error creating local endpoint object: Unable to resolve public IP by any of the resolver methods: [api:api.ipify.org api:api.my-ip.io/ip api:ip4.seeip.org]
github.com/submariner-io/submariner/pkg/endpoint.getPublicIP
        github.com/submariner-io/submariner/pkg/endpoint/public_ip.go:85
github.com/submariner-io/submariner/pkg/endpoint.GetLocal
        github.com/submariner-io/submariner/pkg/endpoint/local_endpoint.go:89
main.main
        command-line-arguments/main.go:125
runtime.main
        runtime/proc.go:225
runtime.goexit
        runtime/asm_amd64.s:1371
could not determine public IP
github.com/submariner-io/submariner/pkg/endpoint.GetLocal
        github.com/submariner-io/submariner/pkg/endpoint/local_endpoint.go:91
main.main
        command-line-arguments/main.go:125
runtime.main
        runtime/proc.go:225
runtime.goexit
        runtime/asm_amd64.s:1371
```

### microshift
```
报错
W0412 09:45:37.563017       1 patch_genericapiserver.go:123] Request to "/apis/template.openshift.io/v1/templateinstances" (source IP 192.168.122.41:40244, user agent "microshift/v1.21.1 (linux/amd64) kubernetes/b09a9ce") before server is ready, possibly a sign for a broken load balancer setup.
I0412 09:45:37.567927       1 templateinstance_finalizer.go:194] Starting TemplateInstanceFinalizer controller
I0412 09:45:39.480908       1 run.go:142] Interrupt received. Stopping services
{"level":"info","ts":"2022-04-12T09:45:39.480Z","caller":"etcdserver/server.go:1485","msg":"skipped leadership transfer for single voting member cluster","local-member-id":"f955962d30473fed","current-leader-member-id":"f955962d30473fed"}
I0412 09:45:39.481896       1 tlsconfig.go:255] Shutting down DynamicServingCertificateController
I0412 09:45:39.482014       1 secure_serving.go:241] Stopped listening on [::]:10251
I0412 09:45:39.482147       1 controller.go:181] Shutting down kubernetes service endpoint reconciler
E0412 09:45:39.482316       1 manager.go:114] service kubelet exited with error: context canceled, stopping MicroShift
I0412 09:45:39.482389       1 dynamic_cafile_content.go:182] Shutting down client-ca-bundle::/var/lib/microshift/certs/ca-bundle/ca-bundle.crt
E0412 09:45:39.482454       1 manager.go:114] service microshift-mdns-controller exited with error: context canceled, stopping MicroShift
I0412 09:45:39.482593       1 configmap_cafile_content.go:223] Shutting down client-ca::kube-system::extension-apiserver-authentication::client-ca-file
I0412 09:45:39.482640       1 requestheader_controller.go:183] Shutting down RequestHeaderAuthRequestController
I0412 09:45:39.482666       1 configmap_cafile_content.go:223] Shutting down client-ca::kube-system::extension-apiserver-authentication::requestheader-client-ca-file
I0412 09:45:39.482977       1 secure_serving.go:241] Stopped listening on [::]:10252
I0412 09:45:39.483346       1 tlsconfig.go:255] Shutting down DynamicServingCertificateController
I0412 09:45:39.483591       1 secure_serving.go:241] Stopped listening on [::]:10259
I0412 09:45:39.491178       1 secure_serving.go:241] Stopped listening on 127.0.0.1:10257
E0412 09:45:39.491526       1 manager.go:114] service etcd exited with error: context canceled, stopping MicroShift
I0412 09:45:39.491621       1 run.go:148] Another interrupt received. Force terminating services
I0412 09:45:39.491638       1 run.go:152] MicroShift stopped
[root@edge1 ~]# 


ocedge1 new-project test
ocedge1 apply -f ./template.yaml 
ocedge1 adm policy add-scc-to-user privileged -z default
ocedge1 new-app --template=test/mariadb-galera-persistent-storageclass-tony -p DATABASE_SERVICE_NAME="galera" -p STORAGE_CLASS="kubevirt-hostpath-provisioner" -p NUMBER_OF_GALERA_MEMBERS="1" -p VOLUME_CAPACITY="5Gi" -p PEER1_DNS_IP="10.53.0.10" -p PEER2_DNS_IP="10.63.0.10"

ocedge2 new-project test
ocedge2 apply -f ./template.yaml 
ocedge2 adm policy add-scc-to-user privileged -z default
ocedge2 new-app --template=test/mariadb-galera-persistent-storageclass-tony -p DATABASE_SERVICE_NAME="galera" -p STORAGE_CLASS="kubevirt-hostpath-provisioner" -p NUMBER_OF_GALERA_MEMBERS="1" -p VOLUME_CAPACITY="5Gi" -p PEER1_DNS_IP="10.43.0.10" -p PEER2_DNS_IP="10.63.0.10"

ocedge3 new-project test
ocedge3 apply -f ./template.yaml 
ocedge3 adm policy add-scc-to-user privileged -z default
ocedge3 new-app --template=test/mariadb-galera-persistent-storageclass-tony -p DATABASE_SERVICE_NAME="galera" -p STORAGE_CLASS="kubevirt-hostpath-provisioner" -p NUMBER_OF_GALERA_MEMBERS="1" -p VOLUME_CAPACITY="5Gi" -p PEER1_DNS_IP="10.43.0.10" -p PEER2_DNS_IP="10.53.0.10"

# subctl --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig export service --namespace test galera3
#oc --kubeconfig=/root/kubeconfig/edge/edge-1/kubeconfig get -n submariner-operator serviceimport
#oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig get -n submariner-operator serviceimport
#oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig get -n submariner-operator serviceimport

ocedge1 delete statefulset galera
ocedge1 delete service galera
ocedge1 delete secret rails-mysql-persistent 
ocedge1 delete pvc galera-galera-0
ocedge1 delete template mariadb-galera-persistent-storageclass-tony
ocedge1 project default
ocedge1 delete namespace test

ocedge2 delete statefulset galera
ocedge2 delete service galera
ocedge2 delete secret rails-mysql-persistent 
ocedge2 delete pvc galera-galera-0
ocedge2 delete template mariadb-galera-persistent-storageclass-tony
ocedge2 project default
ocedge2 delete namespace test

ocedge3 delete statefulset galera
ocedge3 delete service galera
ocedge3 delete secret rails-mysql-persistent 
ocedge3 delete pvc galera-galera-0
ocedge3 delete template mariadb-galera-persistent-storageclass-tony
ocedge3 project default
ocedge3 delete namespace test

# Submariner blog
https://blog.csdn.net/weixin_29045001/article/details/112400459

oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig create namespace nginx-test
oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig run -n nginx-test tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash
bash-5.0# curl nginx.nginx-test.svc.clusterset.local:8080

oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig create namespace test1
oc --kubeconfig=/root/kubeconfig/edge/edge-2/kubeconfig run -n test1 tmp-shell --rm -i --tty --image quay.io/submariner/nettest -- /bin/bash


CFG=/etc/opt/rh/rh-mariadb105/my.cnf.d/galera.cnf
MY_NAME=10.42.0.73
CLUSTER_NAME=galera
WSREP_CLUSTER_ADDRESS=10.43.147.171,10.53.81.152,10.63.105.71

sed -i -e "s|^wsrep_node_address=.*$|wsrep_node_address=${MY_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_name=.*$|wsrep_cluster_name=${CLUSTER_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_address=.*$|wsrep_cluster_address=gcomm://${WSREP_CLUSTER_ADDRESS}|" ${CFG}

CONTAINER_SCRIPTS_DIR="/usr/share/container-scripts/mysql"
${CONTAINER_SCRIPTS_DIR}/configure-mysql.sh

mysqld --wsrep-new-cluster --user=mysql 
mysqld --user=mysql 
cat /var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log
> /var/opt/rh/rh-mariadb105/lib/mysql/grastate.datgrastate.dat
cat /var/opt/rh/rh-mariadb105/lib/mysql/grastate.datgrastate.dat


CFG=/etc/opt/rh/rh-mariadb105/my.cnf.d/galera.cnf
MY_NAME=10.52.0.21
CLUSTER_NAME=galera
WSREP_CLUSTER_ADDRESS=10.42.0.73,10.52.0.21,10.62.0.14

sed -i -e "s|^wsrep_node_address=.*$|wsrep_node_address=${MY_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_name=.*$|wsrep_cluster_name=${CLUSTER_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_address=.*$|wsrep_cluster_address=gcomm://${WSREP_CLUSTER_ADDRESS}|" ${CFG}

CONTAINER_SCRIPTS_DIR="/usr/share/container-scripts/mysql"
${CONTAINER_SCRIPTS_DIR}/configure-mysql.sh
mysqld --user=mysql 


CFG=/etc/opt/rh/rh-mariadb105/my.cnf.d/galera.cnf
MY_NAME=10.62.0.14
CLUSTER_NAME=galera
WSREP_CLUSTER_ADDRESS=10.42.0.73,10.52.0.21,10.62.0.14

sed -i -e "s|^wsrep_node_address=.*$|wsrep_node_address=${MY_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_name=.*$|wsrep_cluster_name=${CLUSTER_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_address=.*$|wsrep_cluster_address=gcomm://${WSREP_CLUSTER_ADDRESS}|" ${CFG}

CONTAINER_SCRIPTS_DIR="/usr/share/container-scripts/mysql"
${CONTAINER_SCRIPTS_DIR}/configure-mysql.sh
mysqld --user=mysql 




CFG=/etc/opt/rh/rh-mariadb105/my.cnf.d/galera.cnf
MY_NAME=10.42.0.19
CLUSTER_NAME=galera
WSREP_CLUSTER_ADDRESS=10.66.208.162:30567,10.66.208.163:30567,10.42.0.19

sed -i -e "s|^wsrep_node_address=.*$|wsrep_node_address=${MY_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_name=.*$|wsrep_cluster_name=${CLUSTER_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_address=.*$|wsrep_cluster_address=gcomm://${WSREP_CLUSTER_ADDRESS}|" ${CFG}

CONTAINER_SCRIPTS_DIR="/usr/share/container-scripts/mysql"
${CONTAINER_SCRIPTS_DIR}/configure-mysql.sh

mysqld --wsrep-new-cluster --user=mysql 
mysqld --user=mysql 
cat /var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log



(oc-mirror)[root@jwang ~/db]# oc --kubeconfig=/root/kubeconfig/edge/edge-3/kubeconfig get -n submariner-operator serviceimport
NAME                        TYPE           IP                  AGE
galera1-test-cluster1       ClusterSetIP   ["242.0.255.252"]   3m45s
galera2-test-cluster2       ClusterSetIP   ["242.1.255.253"]   99s
galera3-test-cluster3       ClusterSetIP   ["242.2.255.252"]   26s

CONTAINER_SCRIPTS_DIR="/usr/share/container-scripts/mysql"
EXTRA_DEFAULTS_FILE="/etc/opt/rh/rh-mariadb105/my.cnf.d"

10.42.0.24
cat <<EOF | ocedge1 apply -f -
---
apiVersion: v1
kind: Service
metadata:
  name: galera1-nodeport
  labels:
    name: galera1-nodeport
spec:
  type: NodePort
  ports:
    - port: 3306
      targetPort: 3306
      name: mysql
      nodePort: 30306
    - port: 4444
      targetPort: 4444
      name: sst
      nodePort: 30444
    - port: 4567
      targetPort: 4567
      name: replication
      nodePort: 30567
    - port: 4568
      targetPort: 4568
      name: ist
      nodePort: 30568
  selector:
    app: galera1
EOF

cat <<EOF | ocedge2 apply -f -
---
apiVersion: v1
kind: Service
metadata:
  name: galera2-nodeport
  labels:
    name: galera2-nodeport
spec:
  type: NodePort
  ports:
    - port: 3306
      targetPort: 3306
      name: mysql
      nodePort: 30306
    - port: 4444
      targetPort: 4444
      name: sst
      nodePort: 30444
    - port: 4567
      targetPort: 4567
      name: replication
      nodePort: 30567
    - port: 4568
      targetPort: 4568
      name: ist
      nodePort: 30568
  selector:
    app: galera2
EOF

cat <<EOF | ocedge3 apply -f -
---
apiVersion: v1
kind: Service
metadata:
  name: galera3-nodeport
  labels:
    name: galera3-nodeport
spec:
  type: NodePort
  ports:
    - port: 3306
      targetPort: 3306
      name: mysql
      nodePort: 30306
    - port: 4444
      targetPort: 4444
      name: sst
      nodePort: 30444
    - port: 4567
      targetPort: 4567
      name: replication
      nodePort: 30567
    - port: 4568
      targetPort: 4568
      name: ist
      nodePort: 30568
  selector:
    app: galera3
EOF

https://microshift.io/docs/user-documentation/networking/firewall/
https://mariadb.com/kb/en/configuring-mariadb-galera-cluster/

Log
/var/opt/rh/rh-mariadb105/log/mariadb/mariadb.log

2022-04-14  7:24:17 2 [Note] WSREP: Prepared SST request: rsync|10.66.208.163:4444/rsync_sst

2022-04-14  7:24:17 2 [Note] WSREP: IST receiver addr using tcp://10.66.208.163:4568
2022-04-14  7:24:17 2 [ERROR] WSREP: State Transfer Request preparation failed: bind: Cannot assign requested address Can't continue, aborting.


wsrep_provider_options="ist.recv_addr=10.66.208.163:30568"

mkdir -p /etc/microshift
cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.52.0.0/16'
  serviceCIDR: '10.53.0.0/16'
  dns: '10.53.0.10'
  domain: cluster.local
EOF

chcon -R --reference /var/lib/kubelet /etc/microshift

cat > /etc/systemd/system/microshift.service <<EOF
[Unit]
Description=MicroShift Containerized
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target crio.service
After=network-online.target crio.service
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/usr/bin/mkdir -p /var/lib/kubelet ; /usr/bin/mkdir -p /var/hpvolumes ; /usr/bin/mkdir -p /etc/microshift
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon --rm --replace --sdnotify=container --label io.containers.autoupdate=registry --network=host --privileged -d --name microshift -v /etc/microshift/config.yaml:/etc/microshift/config.yaml:z,rw,rshared -v /var/hpvolumes:/var/hpvolumes:z,rw,rshared -v /var/run/crio/crio.sock:/var/run/crio/crio.sock:rw,rshared -v microshift-data:/var/lib/microshift:rw,rshared -v /var/lib/kubelet:/var/lib/kubelet:z,rw,rshared -v /var/log:/var/log -v /etc:/etc quay.io/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=multi-user.target default.target
EOF

systemctl daemon-reload

systemctl stop microshift
/usr/bin/crictl stopp $(/usr/bin/crictl pods -q)
/usr/bin/crictl stop $(/usr/bin/crictl ps -aq)
/usr/bin/crictl rmp $(crictl pods -q)
rm -rf /var/lib/containers/*
crio wipe -f

systemctl start microshift


# edge-1
cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.42.0.0/16'
  serviceCIDR: '10.43.0.0/16'
  dns: '10.43.0.10'
  domain: cluster.local
EOF
sudo firewall-cmd --zone=trusted --add-source=10.42.0.0/16 --permanent
sudo firewall-cmd --reload

# edge-2
cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.52.0.0/16'
  serviceCIDR: '10.53.0.0/16'
  dns: '10.53.0.10'
  domain: cluster.local
EOF
sudo firewall-cmd --zone=trusted --add-source=10.52.0.0/16 --permanent
sudo firewall-cmd --reload

# edge-3
cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.62.0.0/16'
  serviceCIDR: '10.63.0.0/16'
  dns: '10.63.0.10'
  domain: cluster.local
EOF
sudo firewall-cmd --zone=trusted --add-source=10.62.0.0/16 --permanent
sudo firewall-cmd --reload

# edge-4
cat > /etc/microshift/config.yaml <<EOF
---
cluster:
  clusterCIDR: '10.72.0.0/16'
  serviceCIDR: '10.73.0.0/16'
  dns: '10.73.0.10'
  domain: cluster.local
EOF
sudo firewall-cmd --zone=trusted --add-source=10.72.0.0/16 --permanent
sudo firewall-cmd --reload

oc -n openshift-service-ca logs $(oc -n openshift-service-ca get pods -l app=service-ca -o name)
oc -n openshift-service-ca delete $(oc -n openshift-service-ca get pods -l app=service-ca -o name)

oc -n kubevirt-hostpath-provisioner delete $(oc -n kubevirt-hostpath-provisioner get pods -l k8s-app=kubevirt-hostpath-provisioner -o name)

2022-04-18T00:45:59.663Z ERR ..oller/controller.go:267 ..mariner-controller Reconciler error error="error building an authorized RestConfig for the broker: Get \"https://10.66.208.162:6443/api/v1/namespaces/submariner-k8s-broker/secrets/any\": dial tcp 10.66.208.162:6443: i/o timeout" name=submariner namespace=submariner-operator reconciler group=submariner.io reconciler kind=Submariner


subctl verify ~/ocpsitea/auth/kubeconfig ~/ocpsiteb/auth/kubeconfig --only connectivity --verbose
subctl join --kubeconfig ocpsitea/auth/kubeconfig --clusterid ocpsitea broker-info.subm --natt=false
kubectl annotate node $GW gateway.submariner.io/public-ip=ipv4:1.2.3.4
subctl join --kubeconfig /root/kubeconfig/edge/edge-1/kubeconfig --clusterid cluster1 broker-info.subm --natt=false

download submariner
wget https://github.com/submariner-io/submariner-operator/releases/download/subctl-release-0.10/subctl-release-0.10-linux-amd64.tar.xz 


```

### 修复 Windows 10 磁盘满的问题
https://www.isunshare.com/windows-10/4-ways-to-fix-c-drive-full-in-windows-10.html

### mirror and upload image commands
```
oc image mirror quay.io/submariner/lighthouse-agent:0.12.0           file://submariner/lighthouse-agent:0.12.0         
oc image mirror quay.io/submariner/lighthouse-coredns:0.12.0         file://submariner/lighthouse-coredns:0.12.0
oc image mirror quay.io/submariner/submariner-gateway:0.12.0         file://submariner/submariner-gateway:0.12.0
oc image mirror quay.io/submariner/submariner-globalnet:0.12.0       file://submariner/submariner-globalnet:0.12.0
oc image mirror quay.io/submariner/submariner-operator:0.12.0        file://submariner/submariner-operator:0.12.0
oc image mirror quay.io/submariner/submariner-route-agent:0.12.0     file://submariner/submariner-route-agent:0.12.0
oc image mirror  gcr.io/google_containers/pause:latest               file://google_containers/pause:latest

tar -cf xxxx.tar  ./

tar -xf xxxx.tar

oc image mirror  --from-dir=./  file://submariner/lighthouse-agent:0.12.0         registry.gaolantest.greeyun.com:8443/microshift/submariner/lighthouse-agent:0.12.0      
oc image mirror  --from-dir=./  file://submariner/lighthouse-coredns:0.12.0       registry.gaolantest.greeyun.com:8443/microshift/submariner/lighthouse-coredns:0.12.0    
oc image mirror  --from-dir=./  file://submariner/submariner-gateway:0.12.0       registry.gaolantest.greeyun.com:8443/microshift/submariner/submariner-gateway:0.12.0    
oc image mirror  --from-dir=./  file://submariner/submariner-globalnet:0.12.0     registry.gaolantest.greeyun.com:8443/microshift/submariner/submariner-globalnet:0.12.0  
oc image mirror  --from-dir=./  file://submariner/submariner-operator:0.12.0      registry.gaolantest.greeyun.com:8443/microshift/submariner/submariner-operator:0.12.0   
oc image mirror  --from-dir=./  file://submariner/submariner-route-agent:0.12.0   registry.gaolantest.greeyun.com:8443/microshift/submariner/submariner-route-agent:0.12.0
oc image mirror  --from-dir=./  file://google_containers/pause:latest             registry.gaolantest.greeyun.com:8443/microshift/google_containers/pause:latest 


oc image mirror docker.io/nginxinc/nginx-unprivileged:stable-alpine file://nginxinc/nginx-unprivileged:stable-alpine
oc image mirror quay.io/submariner/nettest:latest file://submariner/nettest:latest

oc image mirror  --from-dir=./  file://nginxinc/nginx-unprivileged:stable-alpine         registry.gaolantest.greeyun.com:8443/microshift/nginxinc/nginx-unprivileged:stable-alpine
oc image mirror  --from-dir=./  file://submariner/nettest:latest         registry.gaolantest.greeyun.com:8443/microshift/submariner/nettest:latest


[BUG] Microshift does not honor /etc/microshift/config.yaml clusterCIDR
What happened:
Microshift does not apply the clusterCIDR in the config file defined at /etc/microshift/config.yaml 

Example:
(rhv)[root@edge-3 ~]# cat /etc/microshift/config.yaml 
---
cluster:
  clusterCIDR: '10.62.0.0/16'
  serviceCIDR: '10.63.0.0/16'
  dns: '10.63.0.10'
  domain: cluster.local

Result:
(rhv)[root@edge-3 ~]# oc get pods -n kube-system 
NAME                    READY   STATUS    RESTARTS   AGE
kube-flannel-ds-4wws5   1/1     Running   0          47h

(rhv)[root@edge-3 ~]# oc -n kube-system rsh kube-flannel-ds-4wws5 cat /run/flannel/subnet.env 
Defaulted container "kube-flannel" out of: kube-flannel, install-cni-bin (init), install-cni (init)
FLANNEL_NETWORK=10.42.0.0/16
FLANNEL_SUBNET=10.62.0.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true

(rhv)[root@edge-3 ~]# oc get configmaps kube-flannel-cfg -n kube-system -o jsonpath='{.data.net-conf\.json}' 
{
  "Network": "10.42.0.0/16",
  "Backend": {
    "Type": "vxlan"
  }
}


How to reproduce it (as minimally and precisely as possible):
Environment:
Microshift version (use microshift version): latest
Hardware configuration: Raspberry Pi 400 (aarch64, 4GB RAM)
OS (e.g: cat /etc/os-release): Fedora CoreOS 35.20220327.3.0
Kernel (e.g. uname -a): Linux pi-master-0 5.16.16-200.fc35.aarch64 Init #1 SMP Sat Mar 19 13:35:51 UTC 2022 aarch64 aarch64 aarch64 GNU/Linux

oc new-project ${CLUSTER_NAME}
oc label namespace ${CLUSTER_NAME} cluster.open-cluster-management.io/managedCluster=${CLUSTER_NAME}

cat <<EOF | oc apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${CLUSTER_NAME}
  namespace: ${CLUSTER_NAME}
spec:
  clusterName: ${CLUSTER_NAME}
  clusterNamespace: ${CLUSTER_NAME}
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: true
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  iamPolicyController:
    enabled: true
  policyController:
    enabled: true
  searchCollector:
    enabled: true
  version: 2.2.0
EOF

cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${CLUSTER_NAME}
spec:
  hubAcceptsClient: true
EOF

IMPORT=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.import\.yaml}')
CRDS=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.crds\.yaml}')

oc get pods -A -o wide
NAMESPACE                       NAME                                  READY   STATUS    RESTARTS   AGE     IP              NODE          NOMINATED NODE   READINESS GATES
kube-system                     kube-flannel-ds-8dgpz                 1/1     Running   0          43h     172.17.30.129   gree-glg129   <none>           <none>
kubevirt-hostpath-provisioner   kubevirt-hostpath-provisioner-hhw4z   1/1     Running   0          43h     10.42.0.5       gree-glg129   <none>           <none>
openshift-dns                   dns-default-wwns7                     2/2     Running   0          3h25m   10.42.0.10      gree-glg129   <none>           <none>
openshift-dns                   node-resolver-9x6mb                   1/1     Running   0          43h     172.17.30.129   gree-glg129   <none>           <none>
openshift-ingress               router-default-6c96f6bc66-27lzm       1/1     Running   0          43h     172.17.30.129   gree-glg129   <none>           <none>
openshift-service-ca            service-ca-7bffb6f6bf-4lh8v           1/1     Running   0          43h     10.42.0.6       gree-glg129   <none>           <none>


NAME          STATUS   ROLES    AGE   VERSION
gree-glg129   Ready    <none>   44h   v1.21.0

oc get configmap kube-flannel-cfg -n kube-system -o yaml | grep -Ev "creationTimestamp|resourceVersion|selfLink|uid" | tee kube-flannel-cfg.yaml
FLANEL_NETWORK="10.62.0.0"
sed -i "s|10.42.0.0|${FLANEL_NETWORK}|g" kube-flannel-cfg.yaml
oc apply -f kube-flannel-cfg.yaml

oc -n kube-system delete $(oc -n kube-system get pods -l app=flannel -o name) 
oc -n kube-system rsh $(oc -n kube-system get pods -l app=flannel -o name) cat /run/flannel/subnet.env 

oc -n openshift-dns rsh $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) dig www.baidu.com

dnf -y install chronych
sed -i -e "s/^pool*/#&/g" \
-e "s/#log measurements statistics tracking/log measurements statistics tracking/g" \
/etc/chrony.conf
sed -i "3a server 10.2.8.44 iburst" /etc/chrony.conf

echo "$(nmcli c s eno1 | grep ipv4.address | awk '{ print $2 }' | awk -F"/" '{ print $1 }') $(hostname)" 

systemctl status microshift
systemctl status crio
podman stats microshift
$ kubectl top pod kube-flannel-ds-cvcnx  -n kube-system  
error: Metrics API not available

# check dns and flannel in microshift

oc --kubeconfig=./kubeconfig -n openshift-dns rsh $(oc --kubeconfig=./kubeconfig -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) dig api.fenchang1.gaolantest.greeyun.com.

oc -n openshift-dns rsh $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) dig api.ocp4.rhcnsa.com.

# 在没有 Metrics API 的情况下，可以查询 pod 里的 /sys/fs/cgroup/cpu/cpuacct.usage 和 /sys/fs/cgroup/memory/memory.usage_in_bytes 来获取 pod 的 cpu 与 memory 实际占用情况

oc -n openshift-dns rsh $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) cat /sys/fs/cgroup/cpu/cpuacct.usage

oc -n openshift-dns rsh $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) cat /sys/fs/cgroup/memory/memory.usage_in_bytes

# 查看 application-manager 的日志
oc --kubeconfig=./kubeconfig  -n open-cluster-management-agent-addon logs $(oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon get pods -l app=application-manager -o name) 

# 删除 dns-default pod
$ oc -n openshift-dns delete $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) 

# 查看 dns-default pod 日志
$ oc -n openshift-dns logs $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) -c dns

# 查看 service-ca pod 日志
$ oc -n openshift-service-ca logs $(oc -n openshift-service-ca get pods -l app=service-ca -o name) 

# 查看 flannel /run/flannel/subnet.env
$ oc -n kube-system rsh $(oc -n kube-system get pods -l app=flannel -o name) cat /run/flannel/subnet.env 

# 测试域名解析
$ oc -n openshift-dns rsh $(oc -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) dig <domainname>
$ ocl1 -n openshift-dns rsh $(ocl1 -n openshift-dns get pods -l dns.operator.openshift.io/daemonset-dns=default -o name) dig www.bing.com

# obtain service name from edge1/2/3
nslookup galera.test.svc.cluster.local. 10.43.0.10
nslookup galera.test.svc.cluster.local. 10.53.0.10
nslookup galera.test.svc.cluster.local. 10.63.0.10

# 添加到 trustzone 
sudo firewall-cmd --zone=trusted --add-source=10.43.0.0/16 --permanent
sudo firewall-cmd --zone=trusted --add-source=10.53.0.0/16 --permanent
sudo firewall-cmd --zone=trusted --add-source=10.63.0.0/16 --permanent
sudo firewall-cmd --reload
# 从 trustzone 删除
sudo firewall-cmd --zone=trusted --remove-source=10.43.0.0/16 --permanent
sudo firewall-cmd --zone=trusted --remove-source=10.53.0.0/16 --permanent
sudo firewall-cmd --zone=trusted --remove-source=10.63.0.0/16 --permanent
sudo firewall-cmd --reload


> /etc/yum.repos.d/rhel8.repo 
for i in rhel-8-for-x86_64-baseos-rpms rhel-8-for-x86_64-appstream-rpms
do
cat >> /etc/yum.repos.d/rhel8.repo << EOF
[$i]
name=$i
baseurl=file:///repos/rhel8/$i/
enabled=1
gpgcheck=0

EOF
done


subctl diagnose tunnel inter-cluster /root/kubeconfig/edge/edge-1/kubeconfig /root/kubeconfig/edge/edge-2/kubeconfig

oc -n nginx-test patch deployment/nginx --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"


### Test ODF mirror
# 检查 ocs-operator 日志
ocpht -n openshift-storage logs $(ocpht -n openshift-storage get pods -l name=ocs-operator -o name)


curl -L https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest/helm-linux-amd64 -o /usr/local/bin/helm
# set default storage class 
oc patch storageclass kubevirt-hostpath-provisioner -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'

oc -n default expose service my-release-mariadb-galera --type=NodePort --name=my-release-mariadb-galera-nodeport --generator="service/v2"



4.8.0-0.microshift-2022-04-20-182108

quay.io/coreos/flannel:v0.14.0
quay.io/microshift/flannel-cni:4.8.0-0.okd-2021-10-10-030117
quay.io/kubevirt/hostpath-provisioner:v0.8.0
quay.io/openshift/okd-content@sha256:bcdefdbcee8af1e634e68a850c52fe1e9cb31364525e30f5b20ee4eacb93c3e8
quay.io/openshift/okd-content@sha256:459f15f0e457edaf04fa1a44be6858044d9af4de276620df46dc91a565ddb4ec
quay.io/openshift/okd-content@sha256:27f7918b5f0444e278118b2ee054f5b6fadfc4005cf91cb78106c3f5e1833edd
quay.io/openshift/okd-content@sha256:01cfbbfdc11e2cbb8856f31a65c83acc7cfbd1986c1309f58c255840efcc0b64
quay.io/openshift/okd-content@sha256:dd1cd4d7b1f2d097eaa965bc5e2fe7ebfe333d6cbaeabc7879283af1a88dbf4e

oc image mirror quay.io/microshift/microshift:4.8.0-0.microshift-2022-04-20-182108 file://microshift/microshift:4.8.0-0.microshift-2022-04-20-182108

tar -cf xxxx.tar  ./

tar -xf xxxx.tar

oc image mirror  --from-dir=./  file://microshift/microshift:4.8.0-0.microshift-2022-04-20-182108         registry.gaolantest.greeyun.com:8443/microshift/microshift/microshift:4.8.0-0.microshift-2022-04-20-182108      


oc image mirror quay.io/coreos/flannel:v0.14.0                       file://microshift/coreos/flannel:v0.14.0            

oc image mirror quay.io/submariner/lighthouse-coredns:0.12.0         file://submariner/lighthouse-coredns:0.12.0
oc image mirror quay.io/submariner/submariner-gateway:0.12.0         file://submariner/submariner-gateway:0.12.0
oc image mirror quay.io/submariner/submariner-globalnet:0.12.0       file://submariner/submariner-globalnet:0.12.0
oc image mirror quay.io/submariner/submariner-operator:0.12.0        file://submariner/submariner-operator:0.12.0
oc image mirror quay.io/submariner/submariner-route-agent:0.12.0     file://submariner/submariner-route-agent:0.12.0
oc image mirror  gcr.io/google_containers/pause:latest               file://google_containers/pause:latest


cat <<EOF | oc create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: net-macvlan
EOF

# Galera 防火墙端口
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --permanent --zone=public --add-port=4567/tcp
sudo firewall-cmd --permanent --zone=public --add-port=4568/tcp
sudo firewall-cmd --permanent --zone=public --add-port=4444/tcp
sudo firewall-cmd --permanent --zone=public --add-port=4567/udp
sudo firewall-cmd --reload

### galera 
[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
#wsrep_sst_method = xtrabackup
# This can be insecure, because the user is only available via localhost
# We should still try to integrate it with Kubernetes secrets
#wsrep_sst_auth=xtrabackup_sst:xtrabackup_sst
default_storage_engine = innodb
binlog_format = row
innodb_autoinc_lock_mode = 2
innodb_flush_log_at_trx_commit = 0
query_cache_size = 0
query_cache_type = 0

# By default every node is standalone
#wsrep_cluster_address=gcomm://10.1.16.114
#wsrep_cluster_name=galera
#wsrep_node_address=10.1.16.114

wsrep_sst_method=mariabackup
wsrep_slave_threads=4
wsrep_cluster_address=gcomm://
wsrep_cluster_name=galera
wsrep_node_address=13.228.196.104:4567
wsrep_sst_auth="root:"
# Enabled for performance per https://mariadb.com/kb/en/innodb-system-variables/#innodb_flush_log_at_trx_commit
innodb_flush_log_at_trx_commit=2
# MYISAM REPLICATION SUPPORT #
wsrep_replicate_myisam=ON



cat /var/log/audit/audit.log | audit2allow -M a.pp 

2022-04-27 10:41:44 0 [Warning] WSREP: Member 1.0 (my-mariadb-galera-0) requested state transfer from '*any*', but it is impossible to select State Transfer donor: Resource temporarily unavailable



yum install mariadb-server-galera

SET GLOBAL wsrep_sst_auth = 'mariabackup:redhat';

CREATE USER 'mariabackup'@'localhost' IDENTIFIED BY 'redhat';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'mariabackup'@'localhost';

cat > /etc/
[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
#wsrep_sst_method = xtrabackup
# This can be insecure, because the user is only available via localhost
# We should still try to integrate it with Kubernetes secrets
#wsrep_sst_auth=xtrabackup_sst:xtrabackup_sst
default_storage_engine = innodb
binlog_format = row
innodb_autoinc_lock_mode = 2
innodb_flush_log_at_trx_commit = 0
query_cache_size = 0
query_cache_type = 0

# By default every node is standalone
#wsrep_cluster_address=gcomm://10.1.16.114
#wsrep_cluster_name=galera
#wsrep_node_address=10.1.16.114

wsrep_sst_method=mariabackup
wsrep_slave_threads=4
wsrep_cluster_address=gcomm://
wsrep_cluster_name=galera
wsrep_node_address=10.66.208.165:4567
wsrep_sst_auth="mariabackup:mypassword"
# Enabled for performance per https://mariadb.com/kb/en/innodb-system-variables/#innodb_flush_log_at_trx_commit
innodb_flush_log_at_trx_commit=2
# MYISAM REPLICATION SUPPORT #
wsrep_replicate_myisam=ON


GRANT ALL PRIVILEGES ON *.* to mariabackup@'%' IDENTIFIED BY '4Up6i4Mttw' WITH GRANT OPTION;

mariabackup:4Up6i4Mttw

报错
ErrMsg:Nacos Server did not start because dumpservice bean construction 
failure :
No DataSource set

# 修改 aws instance type
cluster-c4v6l-5rb2g-worker-us-east-2a
export NAME=cluster-c4v6l-5rb2g
ocp4.10 -n openshift-machine-api patch machineset $NAME-worker-us-east-2a \
    --type=json \
    -p='[{"op": "replace", "path": "/spec/template/spec/providerSpec/value/instanceType", "value": "m5.metal"}]'
ocp4.10 -n openshift-machine-api scale machineset $NAME-worker-us-east-2a --replicas=1

# 获取日志
ocp4.10 -n openshift-cnv logs $(ocp4.10 -n openshift-cnv get pods -l kubevirt.io=virt-operator -o name | head -1) 
ocp4.10 -n openshift-cnv logs $(ocp4.10 -n openshift-cnv get pods -l kubevirt.io=virt-operator -o name | tail -1) 

# Kubevirt API Resources
ocp4.10 api-resources | grep kubevirt

oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon

oc secrets link default my_pull_secret --for=pull

# 报错
[root@fen1unit2 ~]# crictl -D  pull registry.gaolantest.greeyun.com:8443/gaolan/dev/gaolan-gateway:latest
DEBU[0000] get image connection                         
DEBU[0000] connect using endpoint 'unix:///var/run/crio/crio.sock' with '2s' timeout 
DEBU[0000] connected successfully using endpoint: unix:///var/run/crio/crio.sock 
DEBU[0000] PullImageRequest: &PullImageRequest{Image:&ImageSpec{Image:registry.gaolantest.greeyun.com:8443/gaolan/dev/gaolan-gateway:latest,Annotations:map[string]string{},},Auth:nil,SandboxConfig:nil,} 
DEBU[0000] PullImageResponse: nil                       
FATA[0000] pulling image: rpc error: code = Unknown desc = Error reading manifest latest in registry.gaolantest.greeyun.com:8443/gaolan/dev/gaolan-gateway: unauthorized: access to the requested resource is not authorized 

oc image mirror quay.io/microshift/microshift:4.8.0-0.microshift-2022-04-20-182108 file://microshift/microshift:4.8.0-0.microshift-2022-04-20-182108
tar cf xxxx.tar ./
tar xf xxxx.tar 
oc image mirror  --from-dir=./  file://microshift/microshift:4.8.0-0.microshift-2022-04-20-182108         registry.gaolantest.greeyun.com:8443/microshift/microshift/microshift:4.8.0-0.microshift-2022-04-20-182108

{
  "auths": {
    "registry.gaolantest.greeyun.com:8443": {
      "auth": "YmFzZTpWK2lpelFGd3BFN0F3UEp1aG9OOGk0RklqZ044T1BYQUVncW9oMFluellKTkFPeEJpVFMvVmZYY0I1QjRTYlN6",
      "email": ""
    }
  }
}

setsebool -P virt_use_nfs 1

https://bugzilla.redhat.com/show_bug.cgi?id=2026621
https://chat.google.com/room/AAAAgKto59A/2SW621lTx9o

NNCP new in OCP 4.10.1 

  desiredState:
    interfaces:
      - name: br1 
        description: Linux bridge with eno3 as a port 
        type: linux-bridge 
        state: up 
        ipv4:
          address:
          - ip: 164.191.1.151
            prefix-length: 24
          enabled: true 
        bridge:
          options:
            stp:
              enabled: false
          port:
            - name: eno4
              vlan: {}  ###### This is new

desiredState->interfaces->bridge->port->vlan

oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

oc -n openshift-ingress patch deployment router-default --type json -p '[{"op": "add", "path": "/spec/", "value": true}]'
spec.template.spec.containers[0].env

oc -n openshift-ingress patch deployment router-default --type='merge'  --patch='{"spec":{"template":{"spec":{"containers":{"env":[{"name": "ROUTER_SUBDOMAIN", "value":"${name}-${namespace}.apps.example.com"}]}}}}}'

oc -n openshift-ingress set env deployment/router-default ROUTER_SUBDOMAIN="\${name}-\${namespace}.apps.example.com" ROUTER_ALLOW_WILDCARD_ROUTES="true" ROUTER_OVERRIDE_HOSTNAME="true"

[{"name": "minio", "image":"quay.ocp4.rhcnsa.com/minio/minio:latest"}]


quay.io pull secret
cat > auth.json <<EOF
{
  "auths": {
    "quay.io": {
      "auth": "andhbmcxOmlCTitxQVNqRDRaaU50ZEo5YVVUTHVaKy8yaGFBMWRJQjlBdGVxUjZFWGYxUWFPWnBjblRDTG1OYnB2N3htWUo=",
      "email": ""
    }
  }
}
EOF

ocedge1 new-project test
ocedge1 apply -f ./template.yaml 
ocedge1 new-app --template=test/mariadb-galera-persistent-storageclass-tony -p DATABASE_SERVICE_NAME="galera" -p STORAGE_CLASS="kubevirt-hostpath-provisioner" -p NUMBER_OF_GALERA_MEMBERS="1"
oc new-app --template=test/mariadb-galera-persistent-storageclass-tony -p DATABASE_SERVICE_NAME="galera" -p STORAGE_CLASS="kubevirt-hostpath-provisioner" -p NUMBER_OF_GALERA_MEMBERS="1"

oc new-app --template=test/mariadb-galera-persistent-storageclass-tony -p STORAGE_CLASS="gp2" -p SOURCE_REPOSITORY_URL="https://github.com/sclorg/rails-ex.git"

oc image mirror --from-dir=./ file://jwang/mariadb-galera-3-cluster quay.ocp4.rhcnsa.com/jwang/mariadb-galera-3-cluster

skopeo copy dir:///./v2/jwang/mariadb-galera-3-cluster:v1.0.1 docker://quay.ocp4.rhcnsa.com/jwang/mariadb-galera-3-cluster:v1.0.1

oc -n test create secret generic quay --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc -n test patch sa default -p '{"imagePullSecrets": [{"name": "quay"}]}'

https://asciinema.org/a/epCfLsub63YM0S9qgEtDXb25U

cd /etc/pki/ca-trust/sources/anchors
M_ROUTE="gaolan-web-wms-gaolan-dev.apps.fen1unit2.gaolantest.greeyun.com"
openssl s_client -host ${M_ROUTE} -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee m.crt  

Edge Route Example

apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: httpd-cert
spec:
  host: api-gateway-test.apps.domain.com
  port:
    targetPort: http
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: edge
    certificate: |
      -----BEGIN CERTIFICATE-----
      -----END CERTIFICATE-----
    caCertificate: |
      -----BEGIN CERTIFICATE-----
      -----END CERTIFICATE-----
      -----BEGIN CERTIFICATE-----
      -----END CERTIFICATE-----
    key: |
      -----BEGIN RSA PRIVATE KEY-----
      -----END RSA PRIVATE KEY-----
  to:
    kind: Service
    name: httpd


https://www.worldtimebuddy.com/cst-to-china-beijing

oc image mirror docker.io/bitnami/mysqld-exporter:0.14.0-debian-10-r45 file://baseimages/bitnami/mysqld-exporter:0.14.0-debian-10-r45
tar cf xxxx.tar ./
tar xf xxxx.tar 
oc image mirror  --from-dir=./  file://baseimages/bitnami/mysqld-exporter:0.14.0-debian-10-r45         registry.gaolantest.greeyun.com:8443/baseimages/bitnami/mysqld-exporter:0.14.0-debian-10-r45

oc -n nginx-test expose service nginx --type=NodePort --name=nginx-nodeport --generator="service/v2"
oc -n nginx-test patch svc nginx-nodeport --type json -p '[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 8080}]'

oc image mirror quay.io/jaysonzhao/galera:v1 file://baseimages/jaysonzhao/galera:v1
tar cf xxxx.tar ./
tar xf xxxx.tar 
oc image mirror  --from-dir=./  file://baseimages/jaysonzhao/galera:v1         registry.gaolantest.greeyun.com:8443/baseimages/jaysonzhao/galera:v1

Galera 集群跨多 k8s 集群
https://github.com/jaysonzhao/mariadb-galera-okd


# 查看 OpenShift 的 Entitlement
subscription-manager list --available --matches '*OpenShift Container Platform*' | grep -E "Pool ID|Entitlement Type" 

# 禁用其他软件频道，启用 rhel-8-for-x86_64-baseos-rpms, rhel-8-for-x86_64-appstream-rpms 和 rhocp-${OCP_MAJOR_VER}-for-rhel-8-x86_64-rpms
subscription-manager repos --disable="*"
subscription-manager repos \
    --enable="rhel-8-for-x86_64-baseos-rpms" \
    --enable="rhel-8-for-x86_64-appstream-rpms" \
    --enable="rhocp-${OCP_MAJOR_VER}-for-rhel-8-x86_64-rpms" 

mkdir -p ${YUM_PATH}/rhel-8-for-x86_64-baseos-rpms
mkdir -p ${YUM_PATH}/rhel-8-for-x86_64-appstream-rpms
mkdir -p ${YUM_PATH}/rhocp-${OCP_MAJOR_VER}-for-rhel-8-x86_64-rpms
# 对于 rhel8 的 appstream 软件仓库来说，需要下载并且更新 modules.yaml 文件
# 链接: https://pan.baidu.com/s/1wOR0IEW81QnMcYSE0FPWmQ?pwd=6gi7 提取码: 6gi7 复制这段内容后打开百度网盘手机App，操作更方便哦
cd /repos/rhel8/rhel-8-for-x86_64-appstream-rpms
拷贝这个文件到 /repos/rhel8/rhel-8-for-x86_64-appstream-rpms 下
modifyrepo modules.yaml repodata/
# 参见: https://bugzilla.redhat.com/show_bug.cgi?id=1795936

# 批量下载 
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
yum -y install yum-utils createrepo 
for repo in $(subscription-manager repos --list-enabled | grep "Repo ID" | awk '{print $3}'); do
    reposync --gpgcheck -n --repoid=${repo} --download-path=${YUM_PATH} --downloadcomps --download-metadata
    createrepo -v ${YUM_PATH}/${repo} -o ${YUM_PATH}/${repo} 
done



# 用 grpcurl 检查 index 内容
mkdir -p redhat-operator-index/v4.10
podman run -p50051:50051 -it registry.redhat.io/redhat/redhat-operator-index:v4.10
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > redhat-operator-index/v4.10/packages.out
cat redhat-operator-index/v4.10/packages.out
mkdir -p certified-operator-index/v4.10
podman run -p50051:50051 -it registry.redhat.io/redhat/certified-operator-index:v4.10
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > certified-operator-index/v4.10/packages.out
cat certified-operator-index/v4.10/packages.out
mkdir -p community-operator-index/v4.10
podman run -p50051:50051 -it registry.redhat.io/redhat/community-operator-index:v4.10
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > community-operator-index/v4.10/packages.out
cat community-operator-index/v4.10/packages.out
mkdir -p upstream-community-operators/latest
podman run -p50051:50051 -it quay.io/operator-framework/upstream-community-operators:latest
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > upstream-community-operators/latest/packages.out
cat upstream-community-operators/latest/packages.out
mkdir -p gitea-catalog/latest
podman run -p50051:50051 -it quay.io/gpte-devops-automation/gitea-catalog:latest
grpcurl -plaintext localhost:50051 api.Registry/ListPackages > gitea-catalog/latest/packages.out
cat gitea-catalog/latest/packages.out

# 同步 4.9.9 和 4.9.10
# 通过 operator-index 里的部分 operator 
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
storageConfig:
  local:
    path: /root/oc-workspace
mirror:
  ocp:
    channels:
      - name: fast-4.10
        versions:
          - '4.10.13'
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.10
      headsOnly: false
      packages:
        - name: rhacs-operator
EOF

oc -n sealed-secrets logs $(oc -n sealed-secrets get pods -l name=sealed-secrets-controller -o name)

oc create secret generic test-secret --from-literal=dummykey1=supersecret --from-literal=dummykey2=topsecret --dry-run=client -o yaml >test-secret.yaml

cat test-secret.yaml |kubeseal --controller-namespace sealed-secrets -o yaml --scope strict > sealedtest-secret.yaml
oc apply -f sealedtest-secret.yaml

oc describe secret/test-secret
oc describe sealedsecret/test-secret

oc create secret generic test-secret --from-literal=dummykey1=supersecret --from-literal=dummykey2=topsecret --from-literal=dummykey3=new-secret --dry-run=client -o yaml >test-secret.yaml

cat test-secret.yaml |kubeseal --controller-namespace sealed-secrets -o yaml --scope strict --merge-into sealedtest-secret.yaml

oc apply -f sealedtest-secret.yaml
oc describe secret/test-secret
oc describe sealedsecret/test-secret
```

### 如何在 ACM 里使用 Git Repo 来部署 Helm subscription
For example, if you have Git write access to a folder: https://github.com/stolostron/multicloud-operators-subscription/tree/main/examples/helmrepo-hub-channel
then you can create a Git subscription<br>
For example, https://github.com/stolostron/multicloud-operators-subscription/tree/main/examples/remote-git-sub<br>
But change the "apps.open-cluster-management.io/github-path: " to "examples/helmrepo-hub-channel"
https://github.com/stolostron/multicloud-operators-subscription/blob/main/examples/remote-git-sub/subscription.yaml#L6<br>
So now the Git subscription is watching the Helm subscription on the Git folder: "helmrepo-hub-channel"

### k8s fluentd log collect
https://jia.je/devops/2021/04/02/k8s-fluentd-log-collect/ 

### microshift metric 
https://github.com/openshift/microshift/issues/302<br>
https://github.com/kubernetes-incubator/metrics-server<br>
https://prometheus.io/blog/2021/11/16/agent/<br>
https://jiulongzaitian.gitbooks.io/kubernetes/content/yuan-ma-fen-xi/scheduler/kubelet-cadvisor.html<br>
```
kubectl apply -f https://raw.githubusercontent.com/redhat-et/ushift-workload/master/metrics-server/metrics-components.yaml

# install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# try add scc to sa
oc adm policy add-scc-to-user anyuid -z cadvisor
oc adm policy add-scc-to-user privileges -z cadvisor
oc adm policy remove-scc-from-user anyuid -z cadvisor

# https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/namespaces/kube-system/pods/kube-flannel-ds-29fjh" | jq '.'
Error from server (NotFound): podmetrics.metrics.k8s.io "kube-system/kube-flannel-ds-29fjh" not found

https://access.redhat.com/solutions/3543931
https://access.redhat.com/discussions/3404341

# 获取用户 useroauthaccesstoken
$ oc get useroauthaccesstokens
oc login --token=sha256~erNAsn1f-Kjy-zbFAipyma651l4Vf1AvPY5hQbozBjU --server=https://api...:6443

TOKEN="sha256~NOT_REAL_TOKEN"
curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/metrics
curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/metrics/cadvisor

$ oc login https://<api>:6443
$ oc get useroauthaccesstoken
$ TOKEN="<auth_token_obtained>"
$ curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/metrics
$ curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/metrics/cadvisor
$ curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/stats/summary

# 
https://docs.openshift.com/container-platform/4.9/authentication/using-service-accounts-in-applications.html

oc project kube-system
TOKEN=$(oc serviceaccounts get-token default)


# 查看 
$ kubectl get rolebinding,clusterrolebinding --all-namespaces -o jsonpath='{range .items[?(@.subjects[0].name=="SERVICE_ACCOUNT_NAME")]}[{.roleRef.kind},{.roleRef.name}]{end}'
$ oc get rolebinding,clusterrolebinding --all-namespaces -o jsonpath='{range .items[?(@.subjects[0].name=="SERVICE_ACCOUNT_NAME")]}[{.roleRef.kind},{.roleRef.name}]{end}'


$ kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
$ oc project kube-system
$ TOKEN=$(oc serviceaccounts get-token default)
$ curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/metrics
$ curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/metrics/cadvisor
$ curl -Ssk --header "Authorization: Bearer ${TOKEN}" https://localhost:10250/stats/summary


# podman logs microshift has this error
...
E0519 10:02:02.446006       1 summary_sys_containers.go:47] "Failed to get system container stats" err="failed to get cgroup stats for \"/machine.slice/libpod-8fbd4bf44dca1c09dd59f60801b9e4bb1c52897f771c04b35408e3faaf61a7c6.scope\": failed to get container info for \"/machine.slice/libpod-8fbd4bf44dca1c09dd59f60801b9e4bb1c52897f771c04b35408e3faaf61a7c6.scope\": unknown container \"/machine.slice/libpod-8fbd4bf44dca1c09dd59f60801b9e4bb1c52897f771c04b35408e3faaf61a7c6.scope\"" containerName="/machine.slice/libpod-8fbd4bf44dca1c09dd59f60801b9e4bb1c52897f771c04b35408e3faaf61a7c6.scope"
E0519 10:02:02.446036       1 summary_sys_containers.go:47] "Failed to get system container stats" err="failed to get cgroup stats for \"/system.slice/crio.service\": failed to get container info for \"/system.slice/crio.service\": unknown container \"/system.slice/crio.service\"" containerName="/system.slice/crio.service"
E0519 10:02:02.446052       1 summary_sys_containers.go:47] "Failed to get system container stats" err="failed to get cgroup stats for \"/system.slice\": failed to get container info for \"/system.slice\": unknown container \"/system.slice\"" containerName="/system.slice"

How to enable CgroupV2 on Red Hat Enterprise Linux 8
https://access.redhat.com/solutions/3777261
# grub2-editenv - list | grep kernelopts
kernelopts=root=/dev/mapper/rhel-root ro resume=/dev/mapper/rhel-swap rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb quiet 

# grub2-editenv - set "kernelopts=root=/dev/mapper/rhel-root ro resume=/dev/mapper/rhel-swap rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap systemd.unified_cgroup_hierarchy=1"

args="-i ISO11 upload RHEL-8.6.0-20220420.3-x86_64-dvd1.iso --force"
/usr/bin/expect <<EOF
set timeout -1
spawn "$prog" $args
expect "Please provide the REST API password for the admin@internal oVirt Engine user (CTRL+D to abort): "
send "$mypass\r"
expect eof
exit
EOF
```

### OpenShift 下定义 macvlan 的方法
https://www.programminghunter.com/article/98201008293/<br>
https://docs.google.com/document/d/1el-dYhNxU-Bzin3m4y5kiLnJ3ECa0q4svM01lxb_Ixs/edit<br>
https://songjlg.github.io/2021/10/21/%E5%88%A9%E7%94%A8multus-cni%E5%92%8Cmacvlan%E5%AE%9E%E7%8E%B0pod%E5%A4%9A%E7%BD%91%E5%8D%A1/<br>
```
1. 定义 NetworkAttachmentDefinition
# type 为 macvlan
# mode 为 bridge
# ipam type 为 host-local
cat > macvlan.yaml <<EOF
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf
spec: 
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "ens33",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.174.0/24",
        "rangeStart": "192.168.174.200",
        "rangeEnd": "192.168.174.216",
        "routes": [
          { "dst": "0.0.0.0/0" }
        ],
        "gateway": "192.168.174.2"
      }
    }'
EOF

2. 定义 NetworkAttachmentDefinition
# type 为 macvlan
# mode 为 bridge
# ipam type 为 whereabout
cat > macvlan.yaml <<EOF
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf
spec: 
  config: '{
      "cniVersion": "0.3.0",
      "type": "ipvlan",
      "master": "ens33",
      "mode": "bridge",
      "ipam": {
        "type": "whereabouts",
        "subnet": "192.168.100.0/24",
        "rangeStart": "192.168.100.200",
        "rangeEnd": "192.168.100.216",
        "gateway": "192.168.100.1"
      }
    }'
EOF

cat > macvlan.yaml <<EOF
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: cumucore-vlan432-macvlan
  namespace: cumucore
spec: 
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "vlan432",
      "ipam": {
        "type": "static",
        "routes": [
          { 
            "dst": "0.0.0.0/0" ,
            "gw": "172.16.12.1"
          }  
        ]
      }
    }'
EOF

---
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
  annotations:
    k8s.v1.cni.cncf.io/networks: '[{ "name": "cumucore-vlan432-macvlan", "ips": [ "172.16.12.149/24" ] }]'


oc annotate pods $(oc get pods -l app=hello -o name) k8s.v1.cni.cncf.io/networks='macvlan-conf'

oc create deploy hello --image=quay.io/tasato/hello-js:latest
oc annotate deployment hello k8s.v1.cni.cncf.io/networks='macvlan-conf'
oc rsh $(oc get pods -l app=hello -o name)

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod1
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf
spec:
  containers:
  - name: samplepod1
    command: ["/bin/bash", "-c", "sleep 2000000000000"]
    image: quay.io/tasato/hello-js:latest
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod4
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf
spec:
  containers:
  - name: samplepod4
    command: ["/bin/sh", "-c", "sleep 2000000000000"]
    image: quay.io/tasato/hello-js:latest
EOF


cat <<EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf-1
spec: 
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "ens5",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.174.0/24",
        "rangeStart": "192.168.174.200",
        "rangeEnd": "192.168.174.216",
        "routes": [
          { "dst": "0.0.0.0/0" }
        ],
        "gateway": "192.168.174.2"
      }
    }'
EOF

cat <<EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf-2
spec: 
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "ens5",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.174.0/24",
        "rangeStart": "192.168.174.217",
        "rangeEnd": "192.168.174.226",
        "routes": [
          { "dst": "0.0.0.0/0" }
        ],
        "gateway": "192.168.174.2"
      }
    }'
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod5
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf-1
spec:
  containers:
  - name: samplepod5
    command: ["/bin/sh", "-c", "sleep 2000000000000"]
    image: quay.io/tasato/hello-js:latest
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod6
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf-1
spec:
  containers:
  - name: samplepod6
    command: ["/bin/sh", "-c", "sleep 2000000000000"]
    image: quay.io/tasato/hello-js:latest
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod8
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf-2
spec:
  nodeSelector:
    kubernetes.io/hostname: 'ip-10-0-204-200.us-east-2.compute.internal'
  containers:
  - name: samplepod8
    command: ["/bin/sh", "-c", "sleep 2000000000000"]
    image: quay.io/tasato/hello-js:latest
EOF


# ipvlan net-attach-def example
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: ipvlanstaticip30
  namespace: multus-demo
spec: 
  config: '{
      "cniVersion": "0.3.1",
      "name": "ipvlanstaticip30",
      "type": "ipvlan",
      "master": "ens5",
      "mode": "l2",
      "ipam": {
        "type": "static",
        "addresses": [
          { "address": "172.26.168.30/20" }
        ]
      }
    }'
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: ipvlanstaticip31
  namespace: multus-demo
spec: 
  config: '{
      "cniVersion": "0.3.1",
      "name": "ipvlanstaticip31",
      "type": "ipvlan",
      "master": "ens5",
      "mode": "l2",
      "ipam": {
        "type": "static",
        "addresses": [
          { "address": "172.26.168.31/20" }
        ]
      }
    }'

### 阿里云为实例添加辅助私网IP
https://www.fzxm.com/help/20210616211040000.html
https://help.aliyun.com/document_detail/101180.htm#section-caq-n6w-xqj

### 腾讯云弹性网卡辅助内网IP
https://cloud.tencent.com/document/product/213/6514

### 华为云网卡管理虚拟IP地址
https://support.huaweicloud.com/usermanual-ecs/ecs_03_0506.html

### Azure网卡配置多私网IP地址
https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/virtual-network-multiple-ip-addresses-portal

### AWS网卡配置多私网IP地址
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/MultipleIP.html

### Google Alias IP Range 设置
https://cloud.google.com/migrate/compute-engine/docs/4.2/how-to/networking/using-multiple-ip-addresses
```

### 在 podman 容器里运行 oc-mirror
```
podman run -v ${PWD}:/mirror:Z --rm quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:1f88eabb65686bde3c1812fccdd17250630f1106fe26e5ced9098584c118a86c --config /mirror/cincinnati-operator.yaml file:///mirror

# https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/release.txt
# oc adm release info 可以用来查看 oc-mirror 的 sha256 digest


E0530 07:14:57.090065       1 base_controller.go:251] "ClientCertController@addon:observability-controller:signer:kubernetes.io/kube-apiserver-client" controller failed to sync "addon-edge-4-observability-controller-m9j89", err: namespaces "open-cluster-management-addon-observability" not found
E0530 07:15:01.322209       1 base_controller.go:251] "ClientCertController@addon:observability-controller:signer:open-cluster-management.io/observability-signer" controller failed to sync "addon-edge-4-observability-controller-nz67j", err: namespaces "open-cluster-management-addon-observability" not found
E0530 07:15:38.146712       1 base_controller.go:251] "ClientCertController@addon:observability-controller:signer:kubernetes.io/kube-apiserver-client" controller failed to sync "addon-edge-4-observability-controller-m9j89", err: namespaces "open-cluster-management-addon-observability" not found
E0530 07:15:42.353376       1 base_controller.go:251] "ClientCertController@addon:observability-controller:signer:open-cluster-management.io/observability-signer" controller failed to sync "addon-edge-4-observability-controller-nz67j", err: namespaces "open-cluster-management-addon-observability" not found
```

### 下载 Mac OS 更新
https://www.techglobex.net/2022/05/download-macos-11.6.6-big-sur-dmg.html<br>
```
# 进入安全模式，关机后按 Shift + 电源键开机
softwareupdate -l
softwareupdate -i 'xxx' --verbose
# 日志在 /var/log/installer.log
```

### 测试某个 serviceaccount 是否具有创建某个对象
```
oc auth can-i --as system:serviceaccount:openshift-kube-apiserver:installer-sa create pvc --namespace openshift-kube-apiserver
```

### 下载软件包
```
https://access.redhat.com/solutions/10154

sudo dnf copr enable -y @redhat-et/microshift

yum install -y yum-utils

mkdir -p /repos/cri
cd /repos/cri
yumdownloader crio cri-tools

mkdir -p /repos/microshift
cd /repos/microshift
yumdownloader --resolve --alldeps microshift


subscription-manager repos --disable=rhel-8-for-x86_64-baseos-rpms --disable=rhel-8-for-x86_64-appstream-rpms --disable=rhocp-4.10-for-rhel-8-x86_64-rpms

composer-cli compose start-ostree报错

Preparing packages...
        file /etc/issue conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-8.5-0.8.el8.x86_64
        file /etc/issue.net conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-8.5-0.8.el8.x86_64
        file /etc/os-release conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-8.5-0.8.el8.x86_64
        file /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-beta conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-8.5-0.8.el8.x86_64
        file /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-8.5-0.8.el8.x86_64
        file /etc/redhat-release conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-8.5-0.8.el8.x86_64
        file /etc/rpm/macros.dist conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-8.5-0.8.el8.x86_64
        file /etc/system-release conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-8.5-0.8.el8.x86_64
        file /usr/lib/os-release conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-8.5-0.8.el8.x86_64
        file /usr/lib/systemd/system-preset/90-default.preset conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-8.5-0.8.el8.x86_64
        file /usr/share/redhat-release/EULA conflicts between attempted installs of redhat-release-coreos-48.84-4.el8.x86_64 and redhat-release-eula-8.5-0.8.el8.x86_64
Traceback (most recent call last):
  File "/run/osbuild/bin/org.osbuild.rpm", line 334, in <module>
    r = main(args["tree"], args["inputs"], args["options"])
  File "/run/osbuild/bin/org.osbuild.rpm", line 298, in main
    ], cwd=pkgpath, check=True)
  File "/usr/lib64/python3.6/subprocess.py", line 438, in run
    output=stdout, stderr=stderr)
subprocess.CalledProcessError: Command '['rpm', '--verbose', '--root', '/run/osbuild/tree', '--nosignature', '--install', '/tmp/manifest.n5uufi8p']' returned non-zero exit status 254.


GITOPS_REPO="https://github.com/wangjun1974/microshift-config"
export UPGRADE_SERVER_IP=10.66.208.130

(oc-mirror)[root@jwang ~/rhel4edge/microshift-demos/ostree-demo]# cat c404a1b4-b9f1-4fad-8720-b9f8aab744a2-container.tar | sudo podman load 
Getting image source signatures
Copying blob e8da16f8020c [--------------------------------------] 0.0b / 0.0b
Copying config c9043fdb0f done  
Writing manifest to image destination
Storing signatures
Loaded image(s): @c9043fdb0f059a08199de4ca4f8020132a5e447ab888beeef44c9d65703bec39

cat /tmp/test | grep -o -P '(?<=[@])[a-z0-9]*'


(oc-mirror)[root@jwang ~/rhel4edge/microshift-demos/ostree-demo]# diff -urN build.sh.orig build.sh 
--- build.sh.orig   2022-06-02 17:30:23.190856599 +0800
+++ build.sh    2022-06-02 15:46:45.391367540 +0800
@@ -59,7 +59,7 @@
         title "Serving ${parent_blueprint} v${parent_version} container locally"
         sudo podman rm -f "${parent_blueprint}-server" 2>/dev/null || true
         sudo podman rmi -f "localhost/${parent_blueprint}:${parent_version}" 2>/dev/null || true
-        imageid=$(cat "./${parent_blueprint}-${parent_version}-container.tar" | sudo podman load | grep -o -P '(?<=sha256[@:])[a-z0-9]*')
+        imageid=$(cat "./${parent_blueprint}-${parent_version}-container.tar" | sudo podman load | grep -o -P '(?<=[@])[a-z0-9]*')
         sudo podman tag "${imageid}" "localhost/${parent_blueprint}:${parent_version}"
         sudo podman run -d --name="${parent_blueprint}-server" -p 8080:8080 "localhost/${parent_blueprint}:${parent_version}"

# OpenShift 的 crio-bridge.conf
sh-4.4# cat /etc/cni/net.d/100-crio-bridge.conf 
{
    "cniVersion": "0.3.1",
    "name": "crio",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "hairpinMode": true,
    "ipam": {
        "type": "host-local",
        "routes": [
            { "dst": "0.0.0.0/0" },
            { "dst": "1100:200::1/24" }
        ],
        "ranges": [
            [{ "subnet": "10.85.0.0/16" }],
            [{ "subnet": "1100:200::/24" }]
        ]
    }
}

sh-4.4# cat /etc/kubernetes/cni/net.d/00-multus.conf | jq .  
{
  "cniVersion": "0.3.1",
  "name": "multus-cni-network",
  "type": "multus",
  "namespaceIsolation": true,
  "globalNamespaces": "default,openshift-multus,openshift-sriov-network-operator",
  "logLevel": "verbose",
  "binDir": "/opt/multus/bin",
  "readinessindicatorfile": "/var/run/multus/cni/net.d/80-openshift-network.conf",
  "kubeconfig": "/etc/kubernetes/cni/net.d/multus.d/multus.kubeconfig",
  "delegates": [
    {
      "cniVersion": "0.3.1",
      "name": "openshift-sdn",
      "type": "openshift-sdn"
    }
  ]
}

sh-4.4# ls /var/lib/cni/bin  -l 
total 207344
-rwxr-xr-x. 1 root root  3784615 May 26 11:44 bandwidth
-rwxr-xr-x. 1 root root  3946168 May 26 11:45 bond
-rwxr-xr-x. 1 root root  4190849 May 26 11:44 bridge
-rwxr-xr-x. 1 root root  9765102 May 26 11:44 dhcp
-rwxr-xr-x. 1 root root 30881265 May 26 11:44 egress-router
-rwxr-xr-x. 1 root root  4337008 May 26 11:44 firewall
-rwxr-xr-x. 1 root root  3213601 May  1 12:13 flannel
-rwxr-xr-x. 1 root root  3812185 May 26 11:44 host-device
-rwxr-xr-x. 1 root root  3241068 May 26 11:44 host-local
-rwxr-xr-x. 1 root root  3923382 May 26 11:44 ipvlan
-rwxr-xr-x. 1 root root  3295304 May 26 11:44 loopback
-rwxr-xr-x. 1 root root  4008374 May 26 11:44 macvlan
-rwxr-xr-x. 1 root root 46687958 May 26 11:44 multus
-rwxr-xr-x. 1 root root 15828177 May 26 11:44 openshift-sdn
-rwxr-xr-x. 1 root root  3699558 May 26 11:44 portmap
-rwxr-xr-x. 1 root root  4105117 May 26 11:44 ptp
-rwxr-xr-x. 1 root root  2920468 May 26 11:45 route-override
-rwxr-xr-x. 1 root root  3484013 May 26 11:44 sbr
-rwxr-xr-x. 1 root root  2818372 May 26 11:44 static
-rwxr-xr-x. 1 root root  3456054 May 26 11:44 tuning
-rwxr-xr-x. 1 root root  3921593 May 26 11:44 vlan
-rwxr-xr-x. 1 root root  3523284 May 26 11:44 vrf
-rwxr-xr-x. 1 root root 43425606 May 26 11:45 whereabouts

# OpenShift Node CRIO 的配置文件里定义了 crio.network cni 插件的 binary 在哪里
sh-4.4# grep "/var/lib/cni/bin" * -ri 
crio/crio.conf.d/00-default:    "/var/lib/cni/bin",
grep: grub2-efi.cfg: No such file or directory
machine-config-daemon/orig/etc/crio/crio.conf.d/00-default.mcdorig:    "/var/lib/cni/bin",

sh-4.4# cat /etc/crio/crio.conf.d/00-default  
...
[crio.network]
network_dir = "/etc/kubernetes/cni/net.d/"
plugin_dirs = [
    "/var/lib/cni/bin",
    "/usr/libexec/cni",
]

(rhv)[root@edge-3 ~/test]# cat /etc/crio/crio.conf.d/microshift.conf 
[crio.network]
# cbr0 is the name configured by flannel in /etc/cni/net.d/ config file
# by declaring this crio will wait until that network is configured.
cni_default_network = "cbr0"

# rhel8 crio is configured to only look at /usr/libexec/cni, we override that here
plugin_dirs = [
        "/usr/libexec/cni",
        "/opt/cni/bin"
]

Kubevirt CNI 
https://kubevirt.io/2020/Multiple-Network-Attachments-with-bridge-CNI.html
https://blog.csdn.net/qq_29648159/aticle/details/119614573

contid=$(crictl ps | grep sample  | awk '{print $1}') 
pid=$(crictl inspect $contid | grep pid | head -1 | awk '{print $2}' | sed -e 's|,||' )
netnspath=/proc/$pid/ns/net # 命名空间路径

(rhv)[root@edge-3 ~/test]# cat bridge.json 
{
    "cniVersion": "0.3.1",
    "name": "br0",
    "type": "bridge",
    "bridge": "br0",
    "isDefaultGateway": false,
    "forceAddress": false,
    "ipMasq": true,
    "hairpinMode": true,
    "ipam": {
        "type": "host-local",
        "subnet": "10.10.0.0/16"
    }
}

CNI_COMMAND=ADD CNI_CONTAINERID=$contid CNI_NETNS=$netnspath CNI_IFNAME=eth1 CNI_PATH=/opt/cni/bin /opt/cni/bin/bridge < bridge.json

kubectl exec -it samplepod -- ip a

oc get networks -A 

https://cloud.redhat.com/blog/using-the-multus-cni-in-openshift
https://www.cnblogs.com/ericnie/p/11704041.html

cat <<EOF | kubectl apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: nadbr1
spec:
  config: '{"cniVersion":"0.3.1","name":"br1","plugins":[{"type":"bridge","bridge":"br1","ipam":{}},{"type":"tuning"}]}'
EOF
kubectl get net-attach-def nadbr1 -oyaml

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod1
  annotations:
    k8s.v1.cni.cncf.io/networks: nadbr1
spec:
  containers:
  - name: samplepod1
    command: ["/bin/ash", "-c", "trap : TERM INT; sleep infinity & wait"]
    image: alpine
EOF
kubectl exec -it samplepod1 -- ip a

# OpenShift 下的 multus 配置
cat /etc/cni/multus/net.d/istio-cni.conf 
{
  "cniVersion": "0.3.0",
  "name": "istio-cni",
  "type": "istio-cni",
  "log_level": "info",
  "kubernetes": {
      "kubeconfig": "/etc/cni/multus/net.d/istio-cni.kubeconfig",
      "cni_bin_dir": "/opt/multus/bin",
      "iptables_script": "istio-iptables.sh",
      "exclude_namespaces": [ "openshift-operators" ]
  }
}

https://www.jianshu.com/p/1559ff808b7c
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod2
  annotations:
    k8s.v1.cni.cncf.io/networks: nadbr1
spec:
  containers:
  - name: samplepod
    command: ["/bin/ash", "-c", "trap : TERM INT; sleep infinity & wait"]
    image: alpine
EOF

kubectl exec -it samplepod2 -- ip a


apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br10
  name: a-bridge-network
spec:
  config: '{ "cniVersion": "0.3.1", "name": "a-bridge-network", "type": "cnv-bridge",
    "bridge": "br10" }'

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod3
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf
spec:
  containers:
  - name: samplepod
    command: ["/bin/ash", "-c", "trap : TERM INT; sleep infinity & wait"]
    image: alpine
EOF  
kubectl exec -it samplepod3 -- ip a

检查 multus pod 日志
oc -n kube-system logs $(oc -n kube-system get pods -l app=multus -o name)
oc -n kube-system delete $(oc -n kube-system get pods -l app=multus -o name)


https://zhuanlan.zhihu.com/p/73863683

cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: net-bridge
  namespace: kube-system
EOF

mkdir -p /etc/cni/multus/net.d
cat > /etc/cni/multus/net.d/201-bridge.conf <<EOF
{
  "name": "net-bridge",
  "cniVersion": "0.3.1",
  "type": "bridge",
  "bridge": "br1",
  "ipam": {
      "type": "host-local",
      "ranges": [
           [
               { "subnet": "192.168.0.0/16",
                 "rangeStart": "192.168.0.1",
                 "rangeEnd": "192.168.0.100" }
           ]
      ],
      "routes": [
           { "dst": "0.0.0.0/0"}
      ]
  },
  "policy": {
       "type": "k8s"
  },
  "kubernetes": {
       "kubeconfig": "/etc/cni/net.d/multus.d/multus.kubeconfig"
  }
}
EOF

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod
  annotations:
    k8s.v1.cni.cncf.io/networks: net-bridge
spec:
  containers:
  - name: samplepod
    command: ["/bin/ash", "-c", "trap : TERM INT; sleep infinity & wait"]
    image: alpine
EOF

  annotations:
    k8s.v1.cni.cncf.io/networks: '[{
      "name": "macvlan-conf",
      "default-route": ["192.168.2.1"]
    }]'

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod
  annotations:
    k8s.v1.cni.cncf.io/networks: '[{
      "name": "net-bridge",
    }]'
spec:
  containers:
  - name: samplepod
    command: ["/bin/ash", "-c", "trap : TERM INT; sleep infinity & wait"]
    image: alpine
EOF

# 如何使用 multus
# https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/how-to-use.md


cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf-1
spec:
  config: '{
            "cniVersion": "0.3.0",
            "type": "macvlan",
            "master": "ens3",
            "mode": "bridge",
            "ipam": {
                "type": "host-local",
                "ranges": [
                    [ {
                         "subnet": "10.10.0.0/16",
                         "rangeStart": "10.10.1.20",
                         "rangeEnd": "10.10.3.50",
                         "gateway": "10.10.0.254"
                    } ]
                ]
            }
        }'
EOF

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod4
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf-1
spec:
  containers:
  - name: samplepod
    command: ["/bin/ash", "-c", "trap : TERM INT; sleep infinity & wait"]
    image: alpine
EOF

kubectl exec -it samplepod4 -- ip a


{
	"cniVersion": "0.3.1",
	"name": "multus-cni-network",
	"type": "multus",
	"namespaceIsolation": true,
	"globalNamespaces": "default",
	"logLevel": "verbose",
	"binDir": "/opt/cni/bin",
	"logFile": "/var/log/multus/multus.log",
	"readinessindicatorfile": "/etc/cni/net.d/10-ovn.conf",
	"kubeconfig": "/var/lib/microshift/resources/kubeadmin/kubeconfig",
	"delegates": [{
		"cniVersion":"0.4.0",
		"name":"ovn-kubernetes",
		"type":"ovn-k8s-cni-overlay",
		"ipam":{},
		"dns":{},
		"logFile":"/var/log/ovn-kubernetes/ovn-k8s-cni-overlay.log",
		"logLevel":"4",
		"logfile-maxsize":100,
		"logfile-maxbackups":5,
		"logfile-maxage":5
	}]
}

{
  "capabilities": {
    "portMappings": true
  },
  "cniVersion": "0.3.1",
  "delegates": [
    {
      "cniVersion": "0.3.1",
      "name": "cbr0",
      "plugins": [
        {
          "delegate": {
            "forceAddress": true,
            "hairpinMode": true,
            "isDefaultGateway": true
          },
          "type": "flannel"
        },
        {
          "capabilities": {
            "portMappings": true
          },
          "type": "portmap"
        },
		  "logFile":"/var/log/multus/flannel.log",
		  "logLevel":"4",
		  "logfile-maxsize":100,
		  "logfile-maxbackups":5,
		  "logfile-maxage":5        
      ]
    }
  ],
  "logLevel": "verbose",
  "binDir": "/opt/cni/bin",
  "logFile": "/var/log/multus/multus.log"
  "kubeconfig": "/etc/cni/net.d/multus.d/multus.kubeconfig",
  "name": "multus-cni-network",
  "type": "multus"
}


(rhv)[root@edge-3 ~/test]# cat /tmp/1.json | jq .
{
  "capabilities": {
    "portMappings": true
  },
  "cniVersion": "0.3.1",
  "delegates": [
    {
      "cniVersion": "0.3.1",
      "name": "cbr0",
      "logFile": "/var/log/multus/flannel.log",
      "logLevel": "4",
      "logfile-maxsize": 100,
      "logfile-maxbackups": 5,
      "logfile-maxage": 5,
      "plugins": [
        {
          "delegate": {
            "forceAddress": true,
            "hairpinMode": true,
            "isDefaultGateway": true
          },
          "type": "flannel"
        },
        {
          "capabilities": {
            "portMappings": true
          },
          "type": "portmap"
        }
      ]
    }
  ],
  "logLevel": "verbose",
  "binDir": "/opt/cni/bin",
  "logFile": "/var/log/multus/multus.log",
  "kubeconfig": "/etc/cni/net.d/multus.d/multus.kubeconfig",
  "name": "multus-cni-network",
  "type": "multus"
}

(rhv)[root@edge-3 ~/test]# cat /etc/cni/net.d/10-flannel.conflist 
{
  "name": "cbr0",
  "cniVersion": "0.3.1",
  "logFile": "/var/log/multus/flannel.log",
  "logLevel": "4",
  "logfile-maxsize": 100,
  "logfile-maxbackups": 5,
  "logfile-maxage": 5,
  "plugins": [
    {
      "type": "flannel",
      "delegate": {
        "hairpinMode": true,
        "forceAddress": true,
        "isDefaultGateway": true
      }
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    }
  ]
}

https://access.redhat.com/solutions/1324843
lvm mirror

# 创建 lvm mirror 
https://access.redhat.com/solutions/1324843

sh-4.4# /usr/src/multus-cni/bin/multus-daemon --help 
Usage of /usr/src/multus-cni/bin/multus-daemon:
  -additional-bin-dir string
        Additional binary directory to specify in the configurations. Used only with --multus-conf-file=auto.
  -cni-config-dir string
        CNI config dir (default "/etc/cni/net.d")
  -cni-version string
        Allows you to specify CNI spec version. Used only with --multus-conf-file=auto.
  -global-namespaces string
        Comma-separated list of namespaces which can be referred to globally when namespace isolation is enabled.
  -multus-autoconfig-dir string
        The directory path for the generated multus configuration. (default "/etc/cni/net.d")
  -multus-conf-file string
        The multus configuration file to use. By default, a new configuration is generated. (default "auto")
  -multus-kubeconfig-file-host string
        The path to the kubeconfig (default "/etc/cni/net.d/multus.d/multus.kubeconfig")
  -multus-log-compress
        compress determines if the rotated log files should be compressed using gzip (default true)
  -multus-log-file string
        Path where to multus will log. Used only with --multus-conf-file=auto.
  -multus-log-level string
        One of: debug/verbose/error/panic. Used only with --multus-conf-file=auto.
  -multus-log-max-age int
        the maximum number of days to retain old log files in their filename (default 5)
  -multus-log-max-backups int
        the maximum number of old log files to retain (default 5)
  -multus-log-max-size int
        the maximum size in megabytes of the log file before it gets rotated (default 100)
  -multus-log-to-stderr
        If the multus logs are also to be echoed to stderr.
  -multus-master-cni-file string
        The relative name of the configuration file of the cluster primary CNI.
  -namespace-isolation
        If the network resources are only available within their defined namespaces.
  -override-network-name
        Used when we need overrides the name of the multus configuration with the name of the delegated primary CNI
  -readiness-indicator-file string
        Which file should be used as the readiness indicator. Used only with --multus-conf-file=auto.
  -v    Show application version
  -version
        Show application version

      containers:
      - args:
        - -cni-version=0.3.1
        - -cni-config-dir=/host/etc/cni/net.d
        - -multus-autoconfig-dir=/host/etc/cni/net.d
        - -multus-log-to-stderr=true
        - -multus-log-level=verbose
        command:
        - /usr/src/multus-cni/bin/multus-daemon


/usr/src/multus-cni/bin/multus-daemon --cni-version=0.3.1 --cni-config-dir=/host/etc/cni/net.d --multus-conf-file=/host/etc/cni/net.d/00-multus-1.conf --multus-log-to-stderr=true --multus-log-level=verbose

oc -n kube-system logs $(oc -n kube-system get pods -l app=multus -o name)
oc -n kube-system exec -it $(oc -n kube-system get pods -l app=multus -o name) sh

sh-4.4# 
/usr/src/multus-cni/bin/multus-daemon --cni-config-dir=/host/etc/cni/net.d --multus-conf-file="/host/etc/cni/net.d/00-multus-1.conf" 


https://github.com/k8snetworkplumbingwg/multus-cni/issues/688
https://gist.github.com/janeczku/ab5139791f28bfba1e0e03cfc2963ecf
https://gist.github.com/janeczku/ab5139791f28bfba1e0e03cfc2963ecf


journalctl -u microshift |grep cni-conf-dir


https://github.com/k8snetworkplumbingwg/multus-cni/issues/849
FROM golang:1.17.9 as build

# Add everything
ADD . /usr/src/multus-cni

RUN  cd /usr/src/multus-cni && \
     ./hack/build-go.sh

FROM centos:centos7

RUN yum update -y && \
    yum clean all && \
    rm -rf /var/cache/yum

LABEL org.opencontainers.image.source https://github.com/k8snetworkplumbingwg/multus-cni
COPY --from=build /usr/src/multus-cni/bin /usr/src/multus-cni/bin
COPY --from=build /usr/src/multus-cni/LICENSE /usr/src/multus-cni/LICENSE
WORKDIR /

ADD ./images/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

/host/opt/cni/bin/multus -v     
multus-cni version:v3.8.1, commit:76c31b086136d4e0275c849bb7516446a5f4d9d9, date:2021-10-14T15:14:33+00:00


cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operators
  namespace: olm
spec:
  displayName: Red Hat Operators
  sourceType: grpc
  image: registry.redhat.io/redhat/redhat-operator-index:v4.8
  publisher: RedHat
EOF


sh-4.4# ps awwwx 
    PID TTY      STAT   TIME COMMAND
      1 ?        Ss     0:02 /bin/bash /entrypoint.sh --multus-conf-file=auto --multus-autoconfig-dir=/host/var/run/multus/cni/net.d --multus-kubeconfig-file-host=/etc/kubernetes/cni/net.d/multus.d/multus.kubeconfig --readiness-indicator-file=/var/run/multus/cni/net.d/80-openshift-network.conf --cleanup-config-on-exit=true --namespace-isolation=true --multus-log-level=verbose --cni-version=0.3.1 --additional-bin-dir=/opt/multus/bin --skip-multus-binary-copy=true - --global-namespaces=default,openshift-multus,openshift-sriov-network-operator


https://gist.github.com/janeczku/ab5139791f28bfba1e0e03cfc2963ecf


      - name: kube-multus
        # crio support requires multus:latest for now. support 3.3 or later.
        # image: ghcr.io/k8snetworkplumbingwg/multus-cni:v3.7.1
        image: docker.io/nfvpe/multus:v3.4.1
        command: ["/entrypoint.sh"]
        args:
        - "--cni-bin-dir=/host/usr/libexec/cni"
        - "--multus-conf-file=/tmp/multus-conf/70-multus.conf"
        - "--skip-multus-binary-copy=true"
        - "--multus-kubeconfig-file-host=/host/etc/cni/net.d/multus.d/multus.kubeconfig"


oc patch workmanagers.agent.open-cluster-management.io klusterlet-addon-workmgr -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch searchcollectors.agent.open-cluster-management.io klusterlet-addon-search -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch policycontrollers.agent.open-cluster-management.io klusterlet-addon-policyctrl -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch iampolicycontrollers.agent.open-cluster-management.io klusterlet-addon-iampolicyctrl -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch certpolicycontrollers.agent.open-cluster-management.io klusterlet-addon-certpolicyctrl -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch applicationmanagers.agent.open-cluster-management.io klusterlet-addon-appmgr -n open-cluster-management-agent-addon -p '{"metadata":{"finalizers":[]}}' --type=merge

oc get appliedmanifestworks.work.open-cluster-management.io -A -o name | while read i ; do echo oc delete $i ; done 

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: thanos-object-storage
  namespace: open-cluster-management-observability
type: Opaque
stringData:
  thanos.yaml: |
    type: s3
    config:
      bucket: observability
      endpoint: minio-velero.apps.cluster-mgqtt.mgqtt.sandbox1777.opentlc.com
      insecure: true
      access_key: minio
      secret_key: minio123
EOF
```


### 如何利用 oval feed 检查 ubi 镜像对已知 cve 的安全情况
```
$ curl -O https://www.redhat.com/security/data/oval/v2/RHEL8/rhel-8-including-unpatched.oval.xml.bz2

$ podman pull registry.access.redhat.com/ubi8/ubi:latest

$ oscap-podman registry.access.redhat.com/ubi8/ubi oval eval --results ubi8.xml --report
ubi8.html rhel-8-including-unpatched.oval.xml.bz2 >pass_fail.txt

$ ls -l ubi8.* pass_fail.txt
-rw-r--r--. 1 root root   258265 Dec  8 10:40 pass_fail.txt
-rw-r--r--. 1 root root  2836629 Dec  8 10:39 ubi8.html
-rw-r--r--. 1 root root 77758631 Dec  8 10:39 ubi8.xml

The OVAL feed is updated whenever known CVEs change state.
```

### 
```
cat <<EOF | oc apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${CLUSTER_NAME}
  namespace: ${CLUSTER_NAME}
spec:
  clusterName: ${CLUSTER_NAME}
  clusterNamespace: ${CLUSTER_NAME}
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: true
  clusterLabels:
    cloud: auto-detect
    vendor: microshift
  iamPolicyController:
    enabled: true
  policyController:
    enabled: true
  searchCollector:
    enabled: true
  version: 2.2.0
EOF

cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${CLUSTER_NAME}
spec:
  hubAcceptsClient: true
EOF

IMPORT=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.import\.yaml}')
CRDS=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.crds\.yaml}')


cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: thanos-object-storage
  namespace: open-cluster-management-observability
type: Opaque
stringData:
  thanos.yaml: |
    type: s3
    config:
      bucket: observability
      endpoint: minio-velero.apps.cluster-ll6wq.ll6wq.sandbox824.opentlc.com
      insecure: true
      access_key: minio
      secret_key: minio123
EOF





================
cd /root/kubeconfig/edge/edge-1
export CLUSTER_NAME=edge-1
oc new-project ${CLUSTER_NAME}
oc label namespace ${CLUSTER_NAME} cluster.open-cluster-management.io/managedCluster=${CLUSTER_NAME}

cat <<EOF | oc apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${CLUSTER_NAME}
  namespace: ${CLUSTER_NAME}
spec:
  clusterName: ${CLUSTER_NAME}
  clusterNamespace: ${CLUSTER_NAME}
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: true
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  iamPolicyController:
    enabled: true
  policyController:
    enabled: true
  searchCollector:
    enabled: true
  version: 2.2.0
EOF

cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${CLUSTER_NAME}
spec:
  hubAcceptsClient: true
EOF

IMPORT=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.import\.yaml}')
CRDS=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.crds\.yaml}')

oc --kubeconfig=./kubeconfig new-project open-cluster-management-agent
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet-registration-sa
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet-work-sa
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

oc --kubeconfig=./kubeconfig new-project open-cluster-management-agent-addon
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

oc --kubeconfig=./kubeconfig project open-cluster-management-agent
echo $CRDS | base64 -d | oc --kubeconfig=./kubeconfig apply -f -
echo $IMPORT | base64 -d | oc --kubeconfig=./kubeconfig apply -f -

oc label managedcluster edge-1 openshiftVersion-
cd /root/kubeconfig/edge/edge-1
oc --kubeconfig=./kubeconfig -n open-cluster-management-addon-observability delete $(oc --kubeconfig=./kubeconfig -n open-cluster-management-addon-observability get pods -l name='endpoint-observability-operator' -o name)

oc --kubeconfig=./kubeconfig -n open-cluster-management-addon-observability logs $(oc --kubeconfig=./kubeconfig -n open-cluster-management-addon-observability get pods -l name='endpoint-observability-operator' -o name)

cd /root/kubeconfig/edge/edge-1
oc --kubeconfig=./kubeconfig get clusterClaims product.open-cluster-management.io
oc --kubeconfig=./kubeconfig -n edge-1 delete clusterClaims version.openshift.io
oc --kubeconfig=./kubeconfig -n open-cluster-management-addon-observability delete $(oc --kubeconfig=./kubeconfig -n open-cluster-management-addon-observability get pods -l name='endpoint-observability-operator' -o name)

oc --kubeconfig=./kubeconfig -n open-cluster-management-agent delete $(oc --kubeconfig=./kubeconfig -n open-cluster-management-agent get pods -l app=klusterlet -o name)

oc --kubeconfig=./kubeconfig -n open-cluster-management-agent delete $(oc --kubeconfig=./kubeconfig -n open-cluster-management-agent get pods -l app=klusterlet-registration-agent -o name)

oc --kubeconfig=./kubeconfig -n edge-1 patch clusterClaims product.open-cluster-management.io --type json -p '[{"op": "replace", "path": "/spec/value", "value": "microshift"}]'


for i in {1..240}; do oc --kubeconfig=./kubeconfig -n submariner-operator delete pods --all; sleep 1; done

### ACM console
oc -n open-cluster-management get route multicloud-console -o jsonpath='{"https://"}{.spec.host}'
### ACM grafana console
oc -n open-cluster-management get route multicloud-console -o jsonpath='{"https://"}{.spec.host}{"/grafana"}'

```

### upload image to rhv
```
args="-i ISO11 upload rhel-8.2-discovery.iso --force"
/usr/bin/expect <<EOF
set timeout -1
spawn "$prog" $args
expect "Please provide the REST API password for the admin@internal oVirt Engine user (CTRL+D to abort): "
send "$mypass\r"
expect eof
exit
EOF

args="-i ISO11 upload CentOS-7-x86_64-DVD-2009.iso --force"
/usr/bin/expect <<EOF
set timeout -1
spawn "$prog" $args
expect "Please provide the REST API password for the admin@internal oVirt Engine user (CTRL+D to abort): "
send "$mypass\r"
expect eof
exit
EOF
```

### 集成 RHSSO 与 OpenShift 4
https://blog.csdn.net/weixin_43902588/article/details/105303056<br>
https://bugzilla.redhat.com/show_bug.cgi?id=1951812<br> 
```
# 不要用 default namespace 安装 rhsso
Issuer URL
https://keycloak-rhsso.apps.cluster-n7bsm.n7bsm.sandbox1648.opentlc.com/auth/realms/openshift
https://keycloak-rhsso.apps.cluster-htm2s.htm2s.sandbox1062.opentlc.com/auth/realms/openshift

Add Client -> openshift
  
Client Setting
  Access Type -> confendial
  Valid Redirect URs -> https://*
  Valid Redirect URs -> https://oauth-openshift.apps.cluster-n7bsm.n7bsm.sandbox1648.opentlc.com/oauth2callback/rhsso
  Valid Redirect URs -> https://oauth-openshift.apps.cluster-htm2s.htm2s.sandbox1062.opentlc.com/oauth2callback/rhsso

Client Credentials
  Secret -> b2f3f4e1-d6c1-4f68-a393-0ff735d33d16
  Secret -> ae76648f-273e-4edf-8f1d-daf27a6d8661

# 获取 keycloak 证书
K_ROUTE=$(oc -n rhsso get route keycloak -o jsonpath='{.spec.host}')
openssl s_client -host ${K_ROUTE} -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee k.crt 

Administration
  Cluster Setting -> Configuration -> OAuth -> Add -> OpenID Connect
  Add Indentity Provider：OpenID Connect -> 
  Name -> rhsso
  Client ID -> openshift
  Client Secret -> ae76648f-273e-4edf-8f1d-daf27a6d8661
  Issuer URL -> https://keycloak-rhsso.apps.cluster-htm2s.htm2s.sandbox1062.opentlc.com/auth/realms/openshift
  CA File -> k.crt
 
# 查询 identityProviders
oc get oauth/cluster -o yaml | yq eval '.spec.identityProviders[].name' -

# 查看 openshift-authentication-operator 日志
oc -n openshift-authentication-operator logs $(oc -n openshift-authentication-operator get pods -l app=authentication-operator -o name | head -1 )
...
E0624 04:57:51.866824       1 base_controller.go:272] ConfigObserver reconciliation failed: failed to apply IDP openid config: x509: certificate signed by unknown authority

$ oc get cm/router-ca -n openshift-config-managed -o jsonpath='{.data.ca\-bundle\.crt}'

# 检查 ca.crt 的 issuer 信息
$ openssl x509 -in ca.crt  -noout -subject -issuer 

# 检查 certs 的 subject 与 issuer
$ echo | openssl s_client -connect keycloak-keycloak.apps.cluster-jw9b2.jw9b2.sandbox840.opentlc.com:443 -showcerts
$ echo | openssl s_client -connect $(oc -n rhsso get route keycloak -o jsonpath='{.spec.host}{":443"}') -showcerts

# 获取 keycloak 证书
K_ROUTE=$(oc -n rhsso get route keycloak -o jsonpath='{.spec.host}')
openssl s_client -host ${K_ROUTE} -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee k.crt  
# 配置 idp 指定证书时用 m.crt 作为 CA 证书

https://oauth-openshift.apps.cluster-n7bsm.n7bsm.sandbox1648.opentlc.com/oauth2callback/openid

Usage:
  oc create clusterrolebinding NAME --clusterrole=NAME [--user=username] [--group=groupname]
[--serviceaccount=namespace:serviceaccountname] [--dry-run=server|client|none] [flags]

# 获取 idp user 信息
$ oc get identity
NAME                                          IDP NAME            IDP USER NAME                          USER NAME     USER UID
htpasswd_provider:opentlc-mgr                 htpasswd_provider   opentlc-mgr                            opentlc-mgr   6307e6b0-6a31-48fe-ae46-0e530a6def14
openid:d7264511-5b7d-4b4b-b3b1-7ad23e9519a6   openid              d7264511-5b7d-4b4b-b3b1-7ad23e9519a6   testuser      083a4068-223b-43ff-b12e-3f30bc7f2c48

# 为 idp 用户 testuser 设置 cluster-admin clusterrole
$ oc create clusterrolebinding add-cluster-admin-to-openid-testuser --clusterrole=cluster-admin --user=testuser
clusterrolebinding.rbac.authorization.k8s.io/add-cluster-admin-to-openid-testuser created
$ oc create clusterrolebinding add-cluster-admin-to-openid-testuser --clusterrole=cluster-admin --user=admin1

```

### Identity configuration management for Kubernetesid
https://identitatem.github.io/idp-mgmt-docs/quick_start.html
```
# Creating your AuthRealm

apiVersion: identityconfig.identitatem.io/v1alpha1
kind: AuthRealm
metadata:
  name: identity-config-developers
  namespace: identity-config-authrealm
spec:
  identityProviders:
  - github:
      clientID: <Github OAuth client ID>
      clientSecret:
        name: identitatem-github-client-secret
      organizations:
      - identitatem
    mappingMethod: claim
    name: identitatem-developers
    type: GitHub
  placementRef:
    name: dev-clusters-placement
  routeSubDomain: identitatem-devs
  type: dex


```
### Configure GitLab as an OAuth 2.0 authentication identity provider
https://docs.gitlab.com/ee/integration/oauth_provider.html

### SSO and Ansible Automation Platform 
```
# 创建 KeycloakRealm 
kind: KeycloakRealm
apiVersion: keycloak.org/v1alpha1
metadata:
  name: ansible-automation-platform-keycloakrealm
  namespace: rh-sso
  labels:
    app: sso
    realm: ansible-automation-platform
spec:
  realm:
    id: ansible-automation-platform
    realm: ansible-automation-platform
    enabled: true
    displayName: Ansible Automation Platform
  instanceSelector:
    matchLabels:
      app: sso

# Create KeycloakClient for Automation Hub
kind: KeycloakClient
apiVersion: keycloak.org/v1alpha1
metadata:
  name: automation-hub-client-secret
  labels:
    app: sso
    realm: ansible-automation-platform
  namespace: rhsso
spec:
  realmSelector:
    matchLabels:
      app: sso
      realm: ansible-automation-platform
  client:
    name: Automation Hub
    clientId: automation-hub
    secret: client-secret
    clientAuthenticatorType: client-secret
    description: Client for Automation Hub
    attributes:
      user.info.response.signature.alg: RS256
      request.object.signature.alg: RS256
    directAccessGrantsEnabled: true
    publicClient: true
    protocol: openid-connect
    standardFlowEnabled: true
    protocolMappers:
      - config:
          access.token.claim: "true"
          claim.name: "family_name"
          id.token.claim: "true"
          jsonType.label: String
          user.attribute: lastName
          userinfo.token.claim: "true"
        consentRequired: false
        name: family name
        protocol: openid-connect
        protocolMapper: oidc-usermodel-property-mapper
      - config:
          userinfo.token.claim: "true"
          user.attribute: email
          id.token.claim: "true"
          access.token.claim: "true"
          claim.name: email
          jsonType.label: String
        name: email
        protocol: openid-connect
        protocolMapper: oidc-usermodel-property-mapper
        consentRequired: false
      - config:
          multivalued: "true"
          access.token.claim: "true"
          claim.name: "resource_access.${client_id}.roles"
          jsonType.label: String
        name: client roles
        protocol: openid-connect
        protocolMapper: oidc-usermodel-client-role-mapper
        consentRequired: false
      - config:
          userinfo.token.claim: "true"
          user.attribute: firstName
          id.token.claim: "true"
          access.token.claim: "true"
          claim.name: given_name
          jsonType.label: String
        name: given name
        protocol: openid-connect
        protocolMapper: oidc-usermodel-property-mapper
        consentRequired: false
      - config:
          id.token.claim: "true"
          access.token.claim: "true"
          userinfo.token.claim: "true"
        name: full name
        protocol: openid-connect
        protocolMapper: oidc-full-name-mapper
        consentRequired: false
      - config:
          userinfo.token.claim: "true"
          user.attribute: username
          id.token.claim: "true"
          access.token.claim: "true"
          claim.name: preferred_username
          jsonType.label: String
        name: username
        protocol: openid-connect
        protocolMapper: oidc-usermodel-property-mapper
        consentRequired: false
      - config:
          access.token.claim: "true"
          claim.name: "group"
          full.path: "true"
          id.token.claim: "true"
          userinfo.token.claim: "true"
        consentRequired: false
        name: group
        protocol: openid-connect
        protocolMapper: oidc-group-membership-mapper
      - config:
          multivalued: 'true'
          id.token.claim: 'true'
          access.token.claim: 'true'
          userinfo.token.claim: 'true'
          usermodel.clientRoleMapping.clientId:  'automation-hub'
          claim.name: client_roles
          jsonType.label: String
        name: client_roles
        protocolMapper: oidc-usermodel-client-role-mapper
        protocol: openid-connect
      - config:
          id.token.claim: "true"
          access.token.claim: "true"
          included.client.audience: 'automation-hub'
        protocol: openid-connect
        name: audience mapper
        protocolMapper: oidc-audience-mapper
  roles:
    - name: "hubadmin"
      description: "An administrator role for Automation Hub"

# Create KeycloakUser
apiVersion: keycloak.org/v1alpha1
kind: KeycloakUser
metadata:
  name: hubadmin-user
  labels:
    app: sso
    realm: ansible-automation-platform
  namespace: rhsso
spec:
  realmSelector:
    matchLabels:
      app: sso
      realm: ansible-automation-platform
  user:
    username: hub_admin
    firstName: Hub
    lastName: Admin
    email: hub_admin@example.com
    enabled: true
    emailVerified: false
    credentials:
      - type: password
        value: ch8ngeme
    clientRoles:
      automation-hub:
        - hubadmin

# 浏览 https://<sso_host>/auth/realms/ansible-automation-platform
# 获取 public_key
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoUuPjZuuq1n3xMiBQXtCNFzDzImyfTOCB/qEhxBZwjuy1W78hZB0x93o5ylFJXldWK4Z3eREpd/6YZgX4GlljNo3La3NFICKFfagzrIy1F/SRabZbNpop9ae4Q+9Vyp+kj9NdJF300PMASeDsAq2xIWOLWkOKi1TDXDnPzceEvMnz1jNkD+41NvP406RuHGZaJGXj+GjiACqk1YHkyh4jAJuuzQOcw9Scjl6EvTAxh+5ze6Wag3QucN06gG4IGuC313tpXkecaQbV0IoXShOwqxbWgskLox3sEzfdDRmuftlZF1d0v+/5H5c03nljqjGR2Fdao2Vgh+npAJpw0aVpwIDAQAB

# 在 ansible-automation-platform namespace 下创建 Secret 'automation-hub-sso'
apiVersion: v1
kind: Secret
metadata:
  name: automation-hub-sso
  namespace: ansible-automation-platform
type: Opaque
stringData:
  keycloak_host: "keycloak-rhsso.apps.cluster-htm2s.htm2s.sandbox1062.opentlc.com"
  keycloak_port: "443"
  keycloak_protocol: "https"
  keycloak_realm: "ansible-automation-platform"
  keycloak_admin_role: "hubadmin"
  social_auth_keycloak_key: "automation-hub"
  social_auth_keycloak_secret: "client-secret"
  social_auth_keycloak_public_key: >-
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoUuPjZuuq1n3xMiBQXtCNFzDzImyfTOCB/qEhxBZwjuy1W78hZB0x93o5ylFJXldWK4Z3eREpd/6YZgX4GlljNo3La3NFICKFfagzrIy1F/SRabZbNpop9ae4Q+9Vyp+kj9NdJF300PMASeDsAq2xIWOLWkOKi1TDXDnPzceEvMnz1jNkD+41NvP406RuHGZaJGXj+GjiACqk1YHkyh4jAJuuzQOcw9Scjl6EvTAxh+5ze6Wag3QucN06gG4IGuC313tpXkecaQbV0IoXShOwqxbWgskLox3sEzfdDRmuftlZF1d0v+/5H5c03nljqjGR2Fdao2Vgh+npAJpw0aVpwIDAQAB

# 创建 AutomationHub
apiVersion: automationhub.ansible.com/v1beta1
kind: AutomationHub
metadata:
  name: private-ah
  namespace: ansible-automation-platform
spec:
  sso_secret: automation-hub-sso
  pulp_settings:
    verify_ssl: false
  route_tls_termination_mechanism: Edge
  ingress_type: Route
  loadbalancer_port: 80
  file_storage_size: 100Gi
  image_pull_policy: IfNotPresent
  web:
    replicas: 1
  file_storage_access_mode: ReadWriteMany
  content:
    log_level: INFO
    replicas: 2
  postgres_storage_requirements:
    limits:
      storage: 50Gi
    requests:
      storage: 8Gi
  api:
    log_level: INFO
    replicas: 1
  postgres_resource_requirements:
    limits:
      cpu: 1000m
      memory: 8Gi
    requests:
      cpu: 500m
      memory: 2Gi
  loadbalancer_protocol: http
  resource_manager:
    replicas: 1
  worker:
    replicas: 2

# 更新 KeyClient YAML 添加 Valid Redirect URIs 和 Web Origins settings
    redirectUris:
      - 'https://private-ah-ansible-automation-platform.apps.cluster-htm2s.htm2s.sandbox1062.opentlc.com/*'
    webOrigins:
      - 'https://private-ah-ansible-automation-platform.apps.cluster-htm2s.htm2s.sandbox1062.opentlc.com'


# 创建默认的 ansible controller
```

### RHEL for Edge and FIDO
```
讨论内容 - Jerimiah
4. I didn't understand the workflows for why you would choose certain types of ostree-builds, I am continuing to work on that. I thought you could do edge-container -> edge-installer, then install the vm from the edge-installer iso [note: no special kickstart file at this point], and then do an upgrade (a new edge-container) and have the installed vm notice the new upgrade and upgrade itself. That is not how that particular workflow works. 
4.a. What does work, and what Rich mentioned here ( https://www.osbuild.org/guides/user-guide/building-ostree-images.html ) and Matthew shows in his instruqt ( https://play.instruqt.com/rhel/invite/fxihyp66atdo ) ,  is something different. (This note is not for you Ben, but in case anyone else has made it this far) What works is do an edge-container build, then host that container, with a specialized kickstart.ks file with an ostree instruction it to find the rpm-ostree from the container. Then launch a regular rhel-9.iso install, but have inst.ks point to the http://container:/kickstart.ks file, then the newly create vm will have rpm-ostree setup that is looking back to the http://container location for updates.
4.b. I was trying to do it without a special kickstart editing step, because I thought that would be neat, and I thought it would be built automatically. It's not, no big deal. The instructions talk about what is recommended, but not why the recommendations shouldn't be deviated from. So, I found that out in one case.
```

### RHEL8.5 上构建 Image Builder
https://github.com/redhat-et/microshift-demos/tree/main/ostree-demo<br>
https://www.osbuild.org/guides/user-guide/edge-container+installer.html<br>
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/composing_installing_and_managing_rhel_for_edge_images/composing-a-rhel-for-edge-image-using-image-builder-command-line_composing-installing-managing-rhel-for-edge-images<br>
https://bugzilla.redhat.com/show_bug.cgi?id=2033192<br>
https://toml.io/en/<br>
```
subscription-manager register
### 查看可用 Red Hat OpenShift Container Platform 的 pool
subscription-manager list --available --matches 'Red Hat OpenShift Container Platform' | grep -E "Pool ID|Entitlement Type"
### 绑定合适的 pool
subscription-manager attach --pool=xxxxxxxx
### 启用软件仓库
### 问题：Image Builder 理论上应该不依赖于 subscription
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhocp-4.8-for-rhel-8-x86_64-rpms

### 安装 cockpit cockpit-composer osbuild-composer composer-cli 与 bash-completion
dnf install -y git cockpit cockpit-composer osbuild-composer composer-cli bash-completion podman genisoimage syslinux skopeo

### 启用 cockpit 和 osbuild-composer 服务
systemctl enable --now osbuild-composer.socket
systemctl enable --now cockpit.socket
### firewall-cmd -q --add-service=cockpit
### firewall-cmd -q --add-service=cockpit --permanent

### 配置 composer-cli bash 补齐
source  /etc/bash_completion.d/composer-cli

### 创建 composer repo 文件，拷贝系统默认 repo 文件
### osbuild-composer 使用的 repo 文件与 dnf 的 repo 文件不同
### 是 json 格式的文件
mkdir -p /etc/osbuild-composer/repositories
curl -L https://raw.githubusercontent.com/wangjun1974/tips/master/ocp/edge/microshift/demo/rhel-86.json -o /etc/osbuild-composer/repositories/rhel-86.json
curl -L https://raw.githubusercontent.com/wangjun1974/tips/master/ocp/edge/microshift/demo/rhel-8.json -o /etc/osbuild-composer/repositories/rhel-8.json

### 重启 osbuild-composer.service 服务
systemctl restart osbuild-composer.service

### 创建 microshift 的 osbuild-composer 的 repo source
mkdir -p microshift-demo
cd microshift-demo
cat >microshift.toml<<EOF
id = "microshift"
name = "microshift"
type = "yum-baseurl"
url = "https://download.copr.fedorainfracloud.org/results/@redhat-et/microshift/epel-8-x86_64"
check_gpg = true
check_ssl = false
system = false
EOF
### 添加 osbuild-composer 的 repo source
composer-cli sources add microshift.toml
composer-cli sources list

### 创建 openshift-cli 的 osbuild-composer 的 repo source
cat >openshiftcli.toml<<EOF
id = "oc-cli-tools"
name = "openshift-cli"
type = "yum-baseurl"
url = "https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.8/source/SRPMS"
check_gpg = true
check_ssl = true
system = true
rhsm = true
EOF
composer-cli sources add openshiftcli.toml
composer-cli sources list

### 创建 openshift-tools 的 osbuild-composer 的 repo source
cat >openshiftools.toml<<EOF
id = "oc-tools"
name = "openshift-tools"
type = "yum-baseurl"
url = "https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.8/os"
check_gpg = true
check_ssl = true
system = true
rhsm = true
EOF
composer-cli sources add openshiftools.toml
composer-cli sources list

### 下载 microshift blueprint
curl -OL https://raw.githubusercontent.com/redhat-cop/rhel-edge-automation-arch/blueprints/microshift/blueprint.toml

### 添加 blueprints 
### 解决 blueprints 的依赖关系
composer-cli blueprints push blueprint.toml
composer-cli blueprints list
composer-cli blueprints show microshift
composer-cli blueprints depresolv microshift


### 查看状态
composer-cli status show

### 查看 compose types
composer-cli compose types

### 触发类型为 edge-container 的 compose 
composer-cli compose start-ostree --ref "rhel/edge/example" microshift edge-container
### 用 journalctl 观察 compose 是否完成
### 创建时间大概15分钟
journalctl -f
### 等到消息出现
Jun 30 22:31:49 jwang-imagebuilder.example.com osbuild-worker[16129]: time="2022-06-30T22:31:49-04:00" level=info msg="Job '56665cb3-7c68-4668-83fb-9342d07d6566' (osbuild) finished"

composer-cli compose status 
composer-cli compose log 2a6ac0ca-1237-4d45-be8b-db51879b9ff0
### 保存日志
composer-cli compose logs 2a6ac0ca-1237-4d45-be8b-db51879b9ff0

### 解压缩后日志文件为 logs/osbuild.log
composer-cli compose logs 2a6ac0ca-1237-4d45-be8b-db51879b9ff0

### 获取 compose image 文件
### 在获取前建议获取 compose 对应的 logs 和 metadata
composer-cli compose log 2a6ac0ca-1237-4d45-be8b-db51879b9ff0
composer-cli compose metadata 2a6ac0ca-1237-4d45-be8b-db51879b9ff0
composer-cli compose image 2a6ac0ca-1237-4d45-be8b-db51879b9ff0
[root@jwang-imagebuilder microshift-demo]# ls -lh
total 1.1G
-rw-------. 1 root root 1.1G Jun 30 21:57 2a6ac0ca-1237-4d45-be8b-db51879b9ff0-container.tar
-rw-r--r--. 1 root root 1.1K Jun 30 21:24 blueprint.toml
-rw-r--r--. 1 root root  204 Jun 30 21:22 microshift.toml
-rw-r--r--. 1 root root  212 Jun 30 21:23 openshiftcli.toml
-rw-r--r--. 1 root root  200 Jun 30 21:24 openshiftools.toml

### 加载 container 镜像
imageid=$(cat "./2a6ac0ca-1237-4d45-be8b-db51879b9ff0-container.tar" | sudo podman load | grep -o -P '(?<=[@:])[a-z0-9]*')
### 另外一种加载镜像的方法
skopeo copy oci-archive:2a6ac0ca-1237-4d45-be8b-db51879b9ff0-container.tar containers-storage:localhost/microshift:0.0.1

### 为镜像打 tag
podman tag "${imageid}" "localhost/microshift:0.0.1"
### 启动镜像 - edge-container 镜像运行起来是个 nginx 服务
podman run -d --name="microshift-server" -p 8080:8080 "localhost/microshift:0.0.1"

### 创建 installer.toml 
cat > installer.toml <<EOF
name = "installer"

description = ""
version = "0.0.0"
modules = []
groups = []
packages = []
EOF

### 添加 blueprint 
composer-cli blueprints push installer.toml
composer-cli blueprints list

### 删除自定义 repos
rm -f /etc/osbuild-composer/repositories/rhel-8*.json
systemctl restart osbuild-composer.service

### 删除自定义 sources
composer-cli sources delete oc-cli-tools
composer-cli sources delete oc-tools
composer-cli sources delete microshift

### 触发类型为 edge-installer 的 compose 
### 这个新的 compose 基于前面的 edge-container 的 rpm-ostree
### rpm-ostree 通过 podman 运行在容器里，并通过 http://localhost:8080/repo 可访问
composer-cli compose start-ostree --ref "rhel/edge/example" --url http://localhost:8080/repo/ installer edge-installer

### 获取 edge-installer iso
### 首先通过 composer-cli compose status 获取 edge-installer 类型的 compose id
composer-cli compose status
### 然后通过 compose id 获取 edge-installer iso
composer-cli compose iso a0cea186-a5a7-47bc-be4f-693df0410683

### 用 iso 启动虚拟机
### 启动报错: virt-manager/QEMU: Could not read from CDROM (code 0009) on booting image
### https://github.com/symmetryinvestments/zfs-on-root-installer/issues/1
### https://ostechnix.com/enable-uefi-support-for-kvm-virtual-machines-in-linux/
### https://fedoraproject.org/wiki/Using_UEFI_with_QEMU
### https://www.kraxel.org/repos/
### http://www.linux-kvm.org/downloads/lersek/ovmf-whitepaper-c770f8c.txt
### https://www.server-world.info/en/note?os=CentOS_7&p=kvm&f=11

### 生成 kickstart 文件
# pwd
/root/microshift-demo
cat > edge.ks << EOF
lang en_US
keyboard us
timezone America/Vancouver --isUtc
rootpw --lock
#platform x86_64
reboot
text
ostreesetup --osname=rhel --url=http://192.168.122.203:8080/repo --ref=rhel/edge/example --nogpg
bootloader --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
firstboot --disable
EOF
### 重新创建 edge-container，包含 edge.ks 
podman stop microshift-server
podman rm microshift-server
podman run -d --rm -v /root/microshift-demo/edge.ks:/usr/share/nginx/html/edge.ks:z --name="microshift-server" -p 8080:8080 "localhost/microshift:0.0.1"

### 用 bootiso 启动虚拟机
### 添加启动参数 ip=192.168.122.204::192.168.122.1:255.255.255.0:edge1.example.com:ens3:none nameserver=192.168.122.1 inst.ks=http://192.168.122.203:8080/edge.ks

### 创建更新的 rpm-ostree 
### blueprint 文件内容参考
### https://raw.githubusercontent.com/redhat-cop/rhel-edge-automation-arch/blueprints/microshift/blueprint.toml
### https://github.com/redhat-et/microshift-demos/tree/main/ostree-demo
### https://www.osbuild.org/guides/user-guide/edge-container+installer.html


### 更新 microshift blueprints
### 解决 microshift blueprints 的依赖关系
composer-cli blueprints show microshift
composer-cli blueprints depsolve microshift

### 重新发布 microshift 0.0.2 edge-container
### 按照目前的测试情况
### 需要以下 sources 
### appstream
### baseos
### microshift
### oc-cli-tools
### oc-tools
### 不需要以下的 sources
### curl -L https://raw.githubusercontent.com/wangjun1974/tips/master/ocp/edge/microshift/demo/rhel-86.json -o /etc/osbuild-composer/repositories/rhel-86.json
### curl -L https://raw.githubusercontent.com/wangjun1974/tips/master/ocp/edge/microshift/demo/rhel-8.json -o /etc/osbuild-composer/repositories/rhel-8.json
systemctl restart osbuild-composer.service 

composer-cli sources add microshift.toml
composer-cli sources add openshiftcli.toml
composer-cli sources add openshiftools.toml

### 启动 edge-container 0.0.2 compose
composer-cli compose start-ostree --ref "rhel/edge/example" microshift edge-container

### 下载镜像
composer-cli compose status
composer-cli compose image xxx

### 更新镜像
skopeo copy oci-archive:xxx-container.tar containers-storage:localhost/microshift:0.0.2

### 重新启动 0.0.2 edge-container 
podman stop microshift-server
podman rm microshift-server
podman run -d --rm -v /root/microshift-demo/edge.ks:/usr/share/nginx/html/edge.ks:z --name="microshift-server" -p 8080:8080 "localhost/microshift:0.0.2"

### 登陆 rhel-for-edge 服务器检查更新，下载更新，安装更新
ssh redhat@192.168.122.204
rpm-ostree upgrade check

### 检查 rpm-ostree 状态
rpm-ostree status

### 重启系统
systemctl reboot

### 登陆 rhel-for-edge 服务器，检查 rpm-ostree 状态
ssh redhat@192.168.122.204
rpm-ostree status

### 在安装好的 RHEL Edge 系统里记录着在什么位置查看更新
[root@edge1 etc]# cat /etc/ostree/remotes.d/rhel.conf
[remote "rhel"]
url=http://192.168.122.203:8080/repo
gpg-verify=false

```

### 改变 Controller 与 Worker 的资源(flavor) 的方法 - OSP
```
1. for masters, you'll need to:
update the flavor used for the master, or create a new one and change the MachineSet
redeploy the masters following this manual https://docs.openshift.com/container-platform/4.10/backup_and_restore/control_plane_backup_and_restore/replacing-unhealthy-etcd-member.html
2. For workers, the easiest is to create a new flavor and deploy the new workers and remove the old ones
```

### OCP on OSP 的问题
```
Q: OSP 没有 Octavia 是否可以安装 OCP
A: 可以，安装可以正常执行；安装后的 OCP 应该不能创建 LoadBalancer 类型的 Service
```
 
### 术语解释
```
### 在 OpenShift 4 上下文里
the index image - 包含 operator 列表以及列表里每个 operator 包含的 image 的 metadata
the bundle image - 每个 operator 对应的 image

### the index image lists all the operators and metadata about the images for each operator. The bundle image is one of the images that's part of each operator.
```

### 设置 alertmanager.yaml 
```
### 设置 acm observability alertmanager 的 yaml 文件
### alertmanager.yaml 
global:
  resolve_timeout: 10m
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'ops'
receivers:
- name: 'ops'
  email_configs:
  - to: wjqhd@hotmail.com
    from: wjqhd@hotmail.com
    smarthost: smtp-mail.outlook.com:587
    auth_username: "wjqhd@hotmail.com"
    auth_identity: "wjqhd@hotmail.com"
    auth_password: "$HOTMAIL_AUTH_TOKEN"
    send_resolved: "true" 

### 设置 thanos 自定义告警规则
### 在 namespace open-cluster-management-observability 下
### 定义 configmap thanos-ruler-custom-rules
kind: ConfigMap
apiVersion: v1
metadata:
  name: thanos-ruler-custom-rules
data:
  custom_rules.yaml: |
    groups:
      - name: cluster-health
        rules:
        - alert: ManagedClusterMissing
          annotations:
            description: Managed cluster missing from ACM Hub for longer than 10 minutes
            summary: Managed cluster missing from ACM Hub
          expr: sum(kube_namespace_labels{label_cluster_open_cluster_management_io_managed_cluster!=""}) != sum(acm_managed_cluster_info{managed_cluster_id!=""})
          for: 10m
          labels:
            severity: critical
            service: managedcluster

kind: ConfigMap
apiVersion: v1
metadata:
  name: thanos-ruler-custom-rules
data:
  custom_rules.yaml: |
    groups:
      - name: cluster-health
        rules:
        - alert: ManagedClusterMissing 
          annotations:
            description: Managed cluster missing from ACM Hub for longer than 10 minutes
            summary: Managed cluster missing from ACM Hub
          expr: absent(up{job="node-exporter",cluster="edge-2"}) >0
          for: 5s
          labels:
            severity: critical
            service: managedcluster

### 查看 thanos-rule pod 日志
oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-rule' -o name | head -1 ) -c thanos-rule
oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-rule' -o name | head -2 ) -c thanos-rule
oc -n open-cluster-management-observability logs $(oc -n open-cluster-management-observability get pods -l app.kubernetes.io/name='thanos-rule' -o name | head -3 ) -c thanos-rule

observability-metrics-allowlist 

kind: ConfigMap
apiVersion: v1
metadata:
  name: observability-metrics-custom-allowlist
  namespace: open-cluster-management-observability
data:
  metrics_list.yaml: |
    names:
      - acm_managed_cluster_info
      - kube_namespace_labels
      - policy_governance_info
      - kube_state_metrics_list_total
      - kube_pod_status_phase
      - kube_pod_status_ready
      - kube_pod_container_status_waiting
      - kube_pod_container_status_waiting_reason
      - kube_pod_container_status_running
      - kube_pod_container_status_terminated
      - kube_pod_container_status_terminated_reason
      - kube_pod_container_status_ready
      - kube_pod_container_status_restarts_total
      - kube_pod_container_resource_limits_cpu_cores
      - kube_pod_container_resource_limits_memory_bytes
      - kube_pod_container_resource_requests_cpu_cores
      - kube_pod_container_resource_requests_memory_bytes
      - kube_deployment_status_replicas_available
      - kube_deployment_spec_replicas
      - kube_statefulset_status_replicas_available
      - kube_statefulset_replicas


```

### Hive 删除 clusterdeployment 时检查的顺序
```
1. 检查 deprovision pod 日志
2. 检查 hive controller pod 日志
```

### OpenStack API certificate 
```
$HOME/.config/openstack/clouds.yaml
O_ROUTE="api.osp01.prod.dal10.ibm.infra.opentlc.com"
openssl s_client -host ${O_ROUTE} -port 13000 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee o.crt

添加 additionalTrustBundle
additionalTrustBundle: |
$(cat o.crt | sed 's/^/  /g')


# 查看日志
ocp4.10 -n testosp logs $(ocp4.10 -n testosp get pods -l hive.openshift.io/cluster-deployment-name='testosp' -o name) -c installer
ocp4.10 -n testosp logs $(ocp4.10 -n testosp get pods -l hive.openshift.io/cluster-deployment-name='testosp' -o name) -c cli
ocp4.10 -n testosp logs $(ocp4.10 -n testosp get pods -l hive.openshift.io/cluster-deployment-name='testosp' -o name) -c hive
...
time="2022-07-06T08:43:17Z" level=debug msg="Using legacy API to upload RHCOS to the image \"testosp-5mwxw-rhcos\" with ID \"dfa35169-c83f-45aa-b35c-beee56ccd15f\""


[lab-user@bastion ~]$ openstack image list
...
| dfa35169-c83f-45aa-b35c-beee56ccd15f | testosp-5mwxw-rhcos                                                         | saving |


time="2022-07-06T14:41:57Z" level=debug msg="Still waiting for the Kubernetes API: Get \"https://api.testosp.dynamic.opentlc.com:6443/version\": dial tcp: lookup api.testosp.dynamic.opentlc.com on 172.30.0.10:53: no such host"

应该使用 cluster-jng2p 作为 install-config.yaml 里的字段
sh-4.4# dig api.cluster-jng2p.dynamic.opentlc.com 

; <<>> DiG 9.11.26-RedHat-9.11.26-4.el8_4 <<>> api.cluster-jng2p.dynamic.opentlc.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 15476
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;api.cluster-jng2p.dynamic.opentlc.com. IN A

;; ANSWER SECTION:
api.cluster-jng2p.dynamic.opentlc.com. 5 IN A   150.240.95.207

;; Query time: 12 msec
;; SERVER: 10.0.0.2#53(10.0.0.2)
;; WHEN: Wed Jul 06 14:41:30 UTC 2022
;; MSG SIZE  rcvd: 82

报错
time="2022-07-06T14:54:03Z" level=debug msg="installer console log: level=info msg=Credentials loaded from file \"/etc/openstack/clouds.yaml\"\nlevel=info msg=Consuming Install Config from target directory\nlevel=warning msg=Certificate 49C52D13DE4CEC5633A788B549D8C9E3C9F from additionalTrustBundle is x509 v3 but not a certificate authority\nlevel=warning msg=Certificate 49C52D13DE4CEC5633A788B549D8C9E3C9F from additionalTrustBundle is x509 v3 but not a certificate authority\nlevel=info msg=Manifests created in: manifests and openshift\nlevel=warning msg=Found override for release image. Please be warned, this is not advised\nlevel=info msg=Consuming Common Manifests from target directory\nlevel=info msg=Consuming OpenShift Install (Manifests) from target directory\nlevel=info msg=Consuming Master Machines from target directory\nlevel=info msg=Consuming Worker Machines from target directory\nlevel=info msg=Consuming Openshift Manifests from target directory\nlevel=info msg=Ignition-Configs created in: . and auth\nlevel=info msg=Consuming Bootstrap Ignition Config from target directory\nlevel=info msg=Consuming Master Ignition Config from target directory\nlevel=info msg=Consuming Worker Ignition Config from target directory\nlevel=info msg=Credentials loaded from file \"/etc/openstack/clouds.yaml\"\nlevel=info msg=Obtaining RHCOS image file from 'https://rhcos-redirector.apps.art.xq1c.p1.openshiftapps.com/art/storage/releases/rhcos-4.10/410.84.202205191234-0/x86_64/rhcos-410.84.202205191234-0-openstack.x86_64.qcow2.gz?sha256=15380a3debd92ccf466d98084938229133078c5634e4f926ed150a0c9f699375'\nlevel=warning msg=Following quotas Subnet, Network, Router are available but will be completely used pretty soon.\nlevel=info msg=Creating infrastructure resources...\nlevel=info msg=Waiting up to 20m0s (until 2:51PM) for the Kubernetes API at https://api.testosp.dynamic.opentlc.com:6443...\nlevel=error msg=Attempted to gather ClusterOperator status after installation failure: listing ClusterOperator objects: Get \"https://api.testosp.dynamic.opentlc.com:6443/apis/config.openshift.io/v1/clusteroperators\": dial tcp: lookup api.testosp.dynamic.opentlc.com on 172.30.0.10:53: no such host\nlevel=info msg=Pulling debug logs from the bootstrap machine\nlevel=error msg=Attempted to gather debug logs after installation failure: failed to create SSH client: dial tcp 150.240.95.148:22: connect: connection timed out\nlevel=error msg=Bootstrap failed to complete: Get \"https://api.testosp.dynamic.opentlc.com:6443/version\": dial tcp: lookup api.testosp.dynamic.opentlc.com on 172.30.0.10:53: no such host\nlevel=error msg=Failed waiting for Kubernetes API. This error usually happens when there is a problem on the bootstrap host that prevents creating a temporary control plane.\nlevel=error msg=Attempted to analyze the debug logs after installation failure: could not open the gather bundle: open : no such file or directory\nlevel=fatal msg=Bootstrap failed to complete\n" installID=kgnncj5s

ocp4.10 -n testosp logs $(ocp4.10 -n testosp get pods -l hive.openshift.io/cluster-deployment-name='testosp' -o name) -c hive


# 查看日志
ocp4.10 -n cluster-jng2p logs $(ocp4.10 -n cluster-jng2p get pods -l hive.openshift.io/cluster-deployment-name='cluster-jng2p' -o name) -c installer
ocp4.10 -n cluster-jng2p logs $(ocp4.10 -n cluster-jng2p get pods -l hive.openshift.io/cluster-deployment-name='cluster-jng2p' -o name) -c cli
ocp4.10 -n cluster-jng2p logs $(ocp4.10 -n cluster-jng2p get pods -l hive.openshift.io/cluster-deployment-name='cluster-jng2p' -o name) -c hive

...
time="2022-07-07T00:35:29Z" level=debug msg="bootstrap_ip = \"150.240.95.66\""
time="2022-07-07T00:35:29Z" level=debug msg="OpenShift Installer v4.10.0"
time="2022-07-07T00:35:29Z" level=debug msg="Built from commit 25b4d09c94dc4bdc0c79d8668369aeb4026b52a4"
time="2022-07-07T00:35:29Z" level=info msg="Waiting up to 20m0s (until 12:55AM) for the Kubernetes API at https://api.cluster-jng2p.dynamic.opentlc.com:6443..."
time="2022-07-07T00:35:59Z" level=debug msg="Still waiting for the Kubernetes API: Get \"https://api.cluster-jng2p.dynamic.opentlc.com:6443/version\": dial tcp 150.240.95.207:6443: i/o timeout"
time="2022-07-07T00:37:05Z" level=info msg="API v1.23.5+3afdacb up"
time="2022-07-07T00:37:05Z" level=info msg="Waiting up to 30m0s (until 1:07AM) for bootstrapping to complete..."

REDACTED LINE OF OUTPUT
time="2022-07-07T01:04:06Z" level=debug msg="Time elapsed per stage:"
time="2022-07-07T01:04:06Z" level=debug msg="           masters: 3m1s"
time="2022-07-07T01:04:06Z" level=debug msg="         bootstrap: 40s"
time="2022-07-07T01:04:06Z" level=debug msg="Bootstrap Complete: 9m52s"
time="2022-07-07T01:04:06Z" level=debug msg="               API: 1m36s"
time="2022-07-07T01:04:06Z" level=debug msg=" Bootstrap Destroy: 33s"
time="2022-07-07T01:04:06Z" level=debug msg=" Cluster Operators: 18m12s"
time="2022-07-07T01:04:06Z" level=info msg="Time elapsed: 34m12s"
time="2022-07-07T01:04:07Z" level=info msg="command completed successfully" installID=ltzrngkf
time="2022-07-07T01:04:07Z" level=info msg="saving installer output" installID=ltzrngkf
time="2022-07-07T01:04:07Z" level=debug msg="installer console log: level=info msg=Credentials loaded from file \"/etc/openstack/clouds.yaml\"\nlevel=info msg=Consuming Install Config from target directory\nlevel=info msg=Manifests created in: manifests and openshift\nlevel=warning msg=Found override for release image. Please be warned, this is not advised\nlevel=info msg=Consuming Master Machines from target directory\nlevel=info msg=Consuming Common Manifests from target directory\nlevel=info msg=Consuming Openshift Manifests from target directory\nlevel=info msg=Consuming Worker Machines from target directory\nlevel=info msg=Consuming OpenShift Install (Manifests) from target directory\nlevel=info msg=Ignition-Configs created in: . and auth\nlevel=info msg=Consuming Worker Ignition Config from target directory\nlevel=info msg=Consuming Bootstrap Ignition Config from target directory\nlevel=info msg=Consuming Master Ignition Config from target directory\nlevel=info msg=Credentials loaded from file \"/etc/openstack/clouds.yaml\"\nlevel=info msg=Obtaining RHCOS image file from 'https://rhcos-redirector.apps.art.xq1c.p1.openshiftapps.com/art/storage/releases/rhcos-4.10/410.84.202205191234-0/x86_64/rhcos-410.84.202205191234-0-openstack.x86_64.qcow2.gz?sha256=15380a3debd92ccf466d98084938229133078c5634e4f926ed150a0c9f699375'\nlevel=warning msg=Following quotas Subnet, Network, Router are available but will be completely used pretty soon.\nlevel=info msg=Creating infrastructure resources...\nlevel=info msg=Waiting up to 20m0s (until 12:55AM) for the Kubernetes API at https://api.cluster-jng2p.dynamic.opentlc.com:6443...\nlevel=info msg=API v1.23.5+3afdacb up\nlevel=info msg=Waiting up to 30m0s (until 1:07AM) for bootstrapping to complete...\nlevel=info msg=Destroying the bootstrap resources...\nlevel=info msg=Waiting up to 40m0s (until 1:25AM) for the cluster at https://api.cluster-jng2p.dynamic.opentlc.com:6443 to initialize...\nlevel=info msg=Waiting up to 10m0s (until 1:14AM) for the openshift-console route to be created...\nlevel=info msg=Install complete!\nlevel=info msg=To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/output/auth/kubeconfig'\nlevel=info msg=Access the OpenShift web-console here: https://console-openshift-console.apps.cluster-jng2p.dynamic.opentlc.com\nREDACTED LINE OF OUTPUT\nlevel=info msg=Time elapsed: 34m12s\n" installID=ltzrngkf
time="2022-07-07T01:04:07Z" level=info msg="install completed successfully" installID=ltzrngkf


### 增加 quota 
$ sudo openstack quota set --secgroups 250 --secgroup-rules 1000 --ports 1500 --subnets 250 --networks 250 <project>


# 查看日志
oc -n cluster-jng2p logs $(oc -n cluster-jng2p get pods -l hive.openshift.io/cluster-deployment-name='cluster-jng2p' -o name) -c installer
oc -n cluster-jng2p logs $(oc -n cluster-jng2p get pods -l hive.openshift.io/cluster-deployment-name='cluster-jng2p' -o name) -c cli
oc -n cluster-jng2p logs $(oc -n cluster-jng2p get pods -l hive.openshift.io/cluster-deployment-name='cluster-jng2p' -o name) -c hive

### 添加 ssh security group rule 
CLUSTERNAME="cluster-jng2p"
SGID=$(openstack security group list | grep ${CLUSTERNAME} | grep master | awk '{print $2}')
openstack security group rule create --dst-port 22 --proto tcp ${SGID}

### 查看 security group 里的 security group rules 
openstack security group show cluster-jng2p-5kmcx-master 
...
| rules           | created_at='2022-07-08T08:37:17Z', direction='ingress', ethertype='IPv4', id='0d0fa305-dc49-4920-95ce-c14e4e29f2c9', port_r
ange_max='22', port_range_min='22', protocol='tcp', remote_ip_prefix='0.0.0.0/0', updated_at='2022-07-08T08:37:17Z'                            
                           |

### 删除 security group rules
openstack security group rule delete 0d0fa305-dc49-4920-95ce-c14e4e29f2c9 

### 离线设置 install-config.yaml
platform:
  openstack:
      clusterOSImage: http://mirror.example.com/images/rhcos-43.81.201912131630.0-openstack.x86_64.qcow2.gz?sha256=ffebbd68e8a1f2a245ca19522c16c86f67f9ac8e4e0c1f0a812b068b16f7265d


### 自定义 clusterImageSet
https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.3/html/clusters/release-images 
### 自定义的例子
oc apply -f - <<EOF
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: openshift-v4.9.9
  namespace: open-cluster-management
spec:
  releaseImage: registry.example.com:5000/ocp4/openshift4:4.9.9-x86_64
EOF

oc image mirror quay.io/openshift/okd-content@sha256:bcdefdbcee8af1e634e68a850c52fe1e9cb31364525e30f5b20ee4eacb93c3e8  file://openshift/okd-content:bcdefdbc

tar -cf /tmp/xxxx.tar ./
...
tar -xf /tmp/xxxx.tar
oc image mirror --from-dir=./ file://openshift/okd-content:bcdefdbc registry.example.com:8443/openshift/okd-content:bcdefdbc

### 拷贝镜像 
https://nishipy.com/archives/1444
### 这种方法实验下来可以工作
$ mkdir -p /tmp/skopeotest 
$ skopeo copy --format v2s2 --authfile /path/auth.json --all docker://quay.io/nishipy/ansible-jupyter dir:/tmp/skopeotest 
### 将 /tmp/skopeotest 拷贝到离线
$ skopeo copy --format v2s2 --authfile /path/auth.json --all dir:/tmp/skopeotest docker://registry.example.com:5000/nishipy/ansible-jupyter

clouds:
  ocp48test:  
    auth:
      auth_url: "http://9.110.84.248:5000/v3"
      username: "admin"
      password: "admin"
      project_name: "admin"
      user_domain_name: "Default"
      project_domain_name: "Default"
    region_name: "RegionOne" 
    volume_api_version: "3"

### 在 ACS 造成 Cluster 出问题时，临时的解决方案
oc -n stackrox delete ValidatingWebhookConfiguration stackrox


apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  name: cluster-d6hlj-pkfvm-worker-us-east-2a
  namespace: openshift-machine-api
  labels:
    machine.openshift.io/cluster-api-cluster: cluster-d6hlj-pkfvm
spec:
  replicas: 1
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: cluster-d6hlj-pkfvm
      machine.openshift.io/cluster-api-machineset: cluster-d6hlj-pkfvm-worker-us-east-2a
  template:
    metadata:
      labels:
        machine.openshift.io/cluster-api-cluster: cluster-d6hlj-pkfvm
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: cluster-d6hlj-pkfvm-worker-us-east-2a
    spec:
      lifecycleHooks: {}
      metadata: {}
      providerSpec:
        value:
          userDataSecret:
            name: worker-user-data
          placement:
            availabilityZone: us-east-2a
            region: us-east-2
          credentialsSecret:
            name: aws-cloud-credentials
          instanceType: m5.4xlarge
          metadata:
            creationTimestamp: null
          blockDevices:
            - ebs:
                encrypted: true
                iops: 0
                kmsKey:
                  arn: ''
                volumeSize: 120
                volumeType: gp2
          securityGroups:
            - filters:
                - name: 'tag:Name'
                  values:
                    - cluster-d6hlj-pkfvm-worker-sg
          kind: AWSMachineProviderConfig
          tags:
            - name: kubernetes.io/cluster/cluster-d6hlj-pkfvm
              value: owned
            - name: guid
              value: d6hlj
            - name: owner
              value: unknown
            - name: platform
              value: RHPDS
            - name: uuid
              value: 49be8cec-78a5-5ed5-a2ce-39dcd36cd245
            - name: Stack
              value: project ocp4-cluster-d6hlj
            - name: env_type
              value: ocp4-cluster
          deviceIndex: 0
          ami:
            id: ami-08750efc5bc9eb5ff
          subnet:
            filters:
              - name: 'tag:Name'
                values:
                  - cluster-d6hlj-pkfvm-private-us-east-2a
          apiVersion: awsproviderconfig.openshift.io/v1beta1
          iamInstanceProfile:
            id: cluster-d6hlj-pkfvm-worker-profile

```

### 浅谈ASIL:汽车安全性等级
https://www.eet-china.com/mp/a140461.html

### AWS Certified Cloud Practitioner
https://www.examtopics.com/exams/amazon/aws-certified-cloud-practitioner/view/44/

### Google Sheet - 用 CONCATENATE 设置单元内容
https://blog.coupler.io/google-sheets-concatenate-function/#Google_Sheets_CONCATENATE_date_strings

### OpenShift Logging 的 Pods 的日志
```
# 查看 cluster-logging-operator 的日志
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l name=cluster-logging-operator -o name)

# 查看 kibana 的日志
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=kibana -o name) -c kibana
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=kibana -o name) -c kibana-proxy

# 查看 elasticsearch 的日志
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=elasticsearch -o name | head -1) -c elasticsearch
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=elasticsearch -o name | head -2 | tail -1 ) -c elasticsearch
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=elasticsearch -o name | tail -1 ) -c elasticsearch

# 查看 collector - fluentd 的日志
oc -n openshift-logging logs $(oc -n openshift-logging get pods -l component=collector -o name | head -1) -c collector

# 访问 kibana 
oc -n openshift-logging get route kibana -ojsonpath='{"https://"}{.spec.host}{"\n"}'

# 配置 OpenShift Logging
# 参考同事的 Blog https://mp.weixin.qq.com/s/2aiHX3pz37sUV1GoWozn7Q

``` 

### 查询 securitygroup rules 的 jq 指令
```
openstack security group show ostest-tw2pb-master -c rules -f json | jq '.rules[] | select(.port_range_min==22) | .remote_ip_prefix'
"10.196.0.0/28"
"10.196.0.16/28"
```

### 创建 ClusterLogForwarder 启用 audit 
https://docs.openshift.com/container-platform/4.10/logging/cluster-logging-external.html#cluster-logging-external
```
cat <<EOF | oc apply -f -
apiVersion: logging.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: instance
  namespace: openshift-logging
spec:
  pipelines:
  - inputRefs:
    - application
    - infrastructure
    - audit
    name: enable-default-log-store
    outputRefs:
    - default
EOF
```

### Grafana Log Cli - logcli 
https://github.com/grafana/loki/releases/tag/v2.5.0<br>
```
#
# Application logs:
#
$ logcli --bearer-token="$(oc whoami -t)" --addr http://lokistack-dev-openshift-logging.apps.ptsiraki-logexp.devcluster.openshift.com/api/logs/v1/application query '{kubernetes_namespace_name="my-project", kubernetes_pod_name=~"my-workload.*"} |= "error"))'

#
# Infrastructure logs:
#
$ logcli --bearer-token="$(oc whoami -t)" --addr http://lokistack-dev-openshift-logging.apps.ptsiraki-logexp.devcluster.openshift.com/api/logs/v1/infrastructure query '{kubernetes_namespace_name="openshift-operators-redhat", kubernetes_pod_name=~"loki-operator-controller-manager.*"} |= "error"))'
```

### Loki Operator - LokiStack 
https://github.com/grafana/loki/blob/main/operator/docs/operator/hack_loki_operator.md

### OpenShift Virtualization 
https://kubevirt.io/user-guide/operations/installation/#restricting-kubevirt-components-node-placement
```
# kubevirt 的参数
# kubectl patch -n openshift-cnv kubevirt kubevirt-kubevirt-hyperconverged --type merge --patch '{"spec": {"workloads": {"nodePlacement": {"nodeSelector": {"metal": "true"}}}}}'

# 1. 创建 Baremetal Node
# 添加 machineset 
# aws instance type: m5.metal

# 2. 为 metal 节点添加 label 'metal':'true'

# 3. 安装 Operator - OpenShift Virtualization

# 4. 创建 HyperConverged kubevirt-hyperconverged

# 5. 编辑 HyperConverged kubevirt-hyperconverged
# 添加 workloads: nodePlacement: nodeSelector: metal: 'true'
spec:
....
  workloads:
    nodePlacement:
      nodeSelector:
        metal: 'true'

# cnv service 
$ oc get svc -n openshift-cnv 
NAME                                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)           AGE
cdi-api                                              ClusterIP   172.30.71.219    <none>        443/TCP           43m
cdi-prometheus-metrics                               ClusterIP   172.30.30.187    <none>        8080/TCP          43m
cdi-uploadproxy                                      ClusterIP   172.30.218.195   <none>        443/TCP           43m
cluster-network-addons-operator-prometheus-metrics   ClusterIP   172.30.218.20    <none>        8080/TCP          43m
hco-webhook-service                                  ClusterIP   172.30.245.7     <none>        4343/TCP          47m
hostpath-provisioner-operator-service                ClusterIP   172.30.254.5     <none>        9443/TCP          47m
hyperconverged-cluster-cli-download                  ClusterIP   172.30.90.142    <none>        8080/TCP          43m
kubemacpool-service                                  ClusterIP   172.30.190.168   <none>        443/TCP           43m
kubevirt-hyperconverged-operator-metrics             ClusterIP   172.30.85.150    <none>        8383/TCP          43m
kubevirt-operator-webhook                            ClusterIP   172.30.37.42     <none>        443/TCP           42m
kubevirt-prometheus-metrics                          ClusterIP   172.30.226.210   <none>        443/TCP           42m
nmstate-webhook                                      ClusterIP   172.30.22.201    <none>        443/TCP           43m
node-maintenance-operator-service                    ClusterIP   172.30.177.210   <none>        443/TCP           47m
rhel9-armed-ostrich-ssh-service                      NodePort    172.30.80.142    <none>        22000:30101/TCP   23m
ssp-operator-service                                 ClusterIP   172.30.128.229   <none>        9443/TCP          47m
virt-api                                             ClusterIP   172.30.71.10     <none>        443/TCP           42m
virt-template-validator                              ClusterIP   172.30.38.150    <none>        443/TCP           43m

# 虚拟机的 ssh service 是
rhel9-armed-ostrich-ssh-service                      NodePort    172.30.80.142    <none>        22000:30101/TCP   23m

# vmi 
$ oc -n openshift-cnv get vmi
NAME                  AGE   PHASE     IP            NODENAME                                     READY
rhel9-armed-ostrich   27m   Running   10.130.2.23   ip-10-0-188-217.us-east-2.compute.internal   True

$ oc debug node/<node>
sh-4.4# cat >> /tmp/key <<EOF
...
EOF
sh-4.4# chmod 0400 /tmp/key
sh-4.4# 
sh-4.4# ssh -i /tmp/key cloud-user@ip-10-0-140-246.us-east-2.compute.internal -p 30101
sh-4.4# ssh -i /tmp/key cloud-user@10.130.2.23

### 查看 CNV pod 日志
# hco-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='hyperconverged-cluster-operator' -o name)

# ssp-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='ssp-operator' -o name)

# cdi-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='cdi-operator' -o name)

# cluster-network-addons-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='cluster-network-addons-operator' -o name)

# hostpath-provisioner-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='hostpath-provisioner-operator' -o name)

# node-maintenance-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='node-maintenance-operator' -o name)

# virt-operator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-operator' -o name | head -1)
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-operator' -o name | tail -1)

# virt-api
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-api' -o name | head -1)
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-api' -o name | tail -1)

# virt-controller
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-controller' -o name | head -1)
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-controller' -o name | tail -1)

# virt-handler
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-handler' -o name | head -1)
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-handler' -o name | tail -1)

# virt-launcher - 如果有虚拟机运行的话
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-launcher' -o name | head -1)

# virt-template-validator
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l kubevirt.io='virt-template-validator' -o name | head -1)

# hco-webhook
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='hyperconverged-cluster-webhook' -o name)

# hyperconverged-cluster-cli-download
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='hyperconverged-cluster-cli-download' -o name)

# cdi-apiserver
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l cdi.kubevirt.io='cdi-apiserver' -o name)

# cdi-deployment
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l cdi.kubevirt.io='' -o name)

# cdi-uploadproxy
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l cdi.kubevirt.io='cdi-uploadproxy' -o name)

# cdi-upload-restore - 备份恢复时会创建
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l cdi.kubevirt.io='cdi-upload-server' -o name)

# bridge-marker
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l app='bridge-marker' -o name | head -1)

# kube-cni-linux-bridge-plugin
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l app='cni-plugins' -o name | head -1)

# kubemacpool-cert-manager
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l control-plane='cert-manager' -o name)

# kubemacpool-mac-controller-manager
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l control-plane='mac-controller-manager' -o name)

# nmstate-cert-manager
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='nmstate-cert-manager' -o name)

# nmstate-handler
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='nmstate-handler' -o name | head -1)

# nmstate-webhook
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='nmstate-webhook' -o name | head -1)

# 安装 ODF
# 查看 ODF pod 日志
# ocs-operator
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l name='ocs-operator' -o name)

# odf-operator-controller-manager
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l control-plane='controller-manager' -o name) -c manager

# rook-operator
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-operator' -o name)

# noobaa-operator
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='noobaa' -l noobaa-operator='deployment' -o name)

# rook-ceph-mgr
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mgr' -l instance='a' -o name) -c mgr

# rook-ceph-mon
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mon' -l mon='a' -o name) -c mon
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mon' -l mon='b' -o name) -c mon
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mon' -l mon='c' -o name) -c mon

# rook-ceph-mds
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mds' -l mds='ocs-storagecluster-cephfilesystem-a' -o name) -c mds
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-mds' -l mds='ocs-storagecluster-cephfilesystem-b' -o name) -c mds

# rook-ceph-osd
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-osd' -l ceph-osd-id='0' -o name) -c osd
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-osd' -l ceph-osd-id='1' -o name) -c osd
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-osd' -l ceph-osd-id='2' -o name) -c osd
...

# rook-ceph-crashcollector
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-crashcollector' -o name | head -1)
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-crashcollector' -o name | head -2 | tail -1)
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='rook-ceph-crashcollector' -o name | tail -1)

# rook-ceph-osd-prepare-ocs-deviceset-gp2
$ oc -n openshift-storage logs $(oc -n openshift-storage get jobs -l app='rook-ceph-osd-prepare' -l ceph.rook.io/DeviceSet='ocs-deviceset-gp2-0' -o name)
$ oc -n openshift-storage logs $(oc -n openshift-storage get jobs -l app='rook-ceph-osd-prepare' -l ceph.rook.io/DeviceSet='ocs-deviceset-gp2-1' -o name)
$ oc -n openshift-storage logs $(oc -n openshift-storage get jobs -l app='rook-ceph-osd-prepare' -l ceph.rook.io/DeviceSet='ocs-deviceset-gp2-2' -o name)

# odf-console
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='odf-console' -o name)

# ocs-metrics-exporter
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app.kubernetes.io/name='ocs-metrics-exporter' -o name)

# noobaa-core
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='noobaa' -l noobaa-core='noobaa' -o name)

# noobaa-endpoint
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='noobaa' -l noobaa-s3='noobaa' -o name)

# noobaa-db
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='noobaa' -l noobaa-db='postgres' -o name)

# csi-addons-controller-manager
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app.kubernetes.io/name='csi-addons' -o name)

# csi-cephfsplugin-provisioner
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c csi-provisioner
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c csi-attacher
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c csi-snapshotter
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c csi-resizer
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c csi-cephfsplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin-provisioner' -o name | head -1) -c liveness-prometheus

# csi-rbdplugin-provisioner
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c csi-provisioner
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c csi-attacher
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c csi-snapshotter
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c csi-resizer
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c csi-rbdplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin-provisioner' -o name | head -1) -c liveness-prometheus

# csi-cephfsplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin' -o name | head -1) -c driver-registrar
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin' -o name | head -1) -c csi-cephfsplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-cephfsplugin' -o name | head -1) -c liveness-prometheus

# csi-rbdplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin' -o name | head -1) -c driver-registrar
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin' -o name | head -1) -c csi-rbdplugin
$ oc -n openshift-storage logs $(oc -n openshift-storage get pods -l app='csi-rbdplugin' -o name | head -1) -c liveness-prometheus

$ oc get storagecluster -A 
NAMESPACE           NAME                 AGE   PHASE   EXTERNAL   CREATED AT             VERSION
openshift-storage   ocs-storagecluster   50m   Ready              2022-08-02T07:57:24Z   4.10.0

$ oc get storageclass
NAME                          PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
gp2 (default)                 kubernetes.io/aws-ebs                   Delete          WaitForFirstConsumer   true                   18h
gp2-csi                       ebs.csi.aws.com                         Delete          WaitForFirstConsumer   true                   18h
gp3-csi                       ebs.csi.aws.com                         Delete          WaitForFirstConsumer   true                   18h
ocs-storagecluster-ceph-rbd   openshift-storage.rbd.csi.ceph.com      Delete          Immediate              true                   44m
ocs-storagecluster-cephfs     openshift-storage.cephfs.csi.ceph.com   Delete          Immediate              true                   44m
openshift-storage.noobaa.io   openshift-storage.noobaa.io/obc         Delete          Immediate              false                  42m

# openshift-virtualization template 
$ oc -n openshift-cnv logs $(oc -n openshift-cnv get pods -l name='virt-template-validator' -o name | head -1)

# kubevirt templates
# https://github.com/kubevirt/common-templates

https://github.com/kubevirt/ssp-operator
Operator that manages Scheduling, Scale and Performance addons for KubeVirt


```

### 重装 master 
```
# 从环境中抽取 master ignition 
oc extract -n openshift-machine-api secret/master-user-data --keys=userData --to=-

# 在 http server 上保存 master.ign

# 重新安装 master
```

### 测试一下 networkpolicy
```
$ oc new-project jwang

# 创建 Pod1
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod1
  namespace: jwang
spec:
  containers:
  - name: samplepod1
    command: ["/bin/bash", "-c", "sleep 2000000000000"]
    image: quay.io/jpacker/hugo-nginx:latest
EOF

# 创建 Pod2
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod2
  namespace: jwang
spec:
  containers:
  - name: samplepod2
    command: ["/bin/bash", "-c", "sleep 2000000000000"]
    image: quay.io/jpacker/hugo-nginx:latest
EOF

# 创建 deny-all networkpolicy 
# namespace 下的 pod 不能访问
cat <<EOF | oc apply -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-all
  namespace: jwang
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
EOF

### OVNKubernetes - Audit Logging about namespace network policy acl 
kind: Namespace
apiVersion: v1
metadata:
  name: example1
  annotations:
    k8s.ovn.org/acl-logging: |-
      {
        "deny": "info",
        "allow": "info"
      }

# EgressFirewall 的例子
# 集群管理员设置
# 允许访问哪个 CIDR
# 禁止访问哪些 CIDR
apiVersion: k8s.ovn.org/v1
kind: EgressFirewall
metadata:
  name: default
spec:
  egress: 
  - type: Allow
    to:
      cidrSelector: 1.2.3.0/24
  - type: Deny
    to:
      cidrSelector: 0.0.0.0/0

# 关于 EgressFirewall 的解释
Egress Firewall is only for egress traffic from pods -> things outside the cluster. It doesn't do anything between pods. Also, it's on a per-namespace basis and doesn't have a pod selector.
```

### ACM Policy - Config Management - ACM
https://cloud.redhat.com/blog/deploying-red-hat-advanced-cluster-security-with-red-hat-advanced-cluster-management-2
```
export ROX_API_TOKEN=<token>

curl https://raw.githubusercontent.com/open-cluster-management/advanced-cluster-security/main/scripts/deploy-bundle.sh -o deploy-bundle.sh
bash deploy-bundle.sh -i bundle.yaml | oc apply -f -

oc get secret -n stackrox | grep tls

# 查看 Application 
$ oc -n stackrox get application stackrox -o yaml

# 报错信息
Error: This application has no matched subscription. Make sure the subscription match selector spec.selector.matchExpressions exists and matches a Subscription resource created in the stackrox namespace.

apiVersion: app.k8s.io/v1beta1
kind: Application
metadata:
  annotations:
    email: support@stackrox.com
    kubernetes-engine.cloud.google.com/icon: data:image/png;base64,...
    meta.helm.sh/release-name: stackrox-central-services
    meta.helm.sh/release-namespace: stackrox
    open-cluster-management.io/user-group: c3lzdGVtOnNlcnZpY2VhY2NvdW50cyxzeXN0ZW06c2VydmljZWFjY291bnRzOnJoYWNzLW9wZXJhdG9yLHN5c3RlbTphdXRoZW50aWNhdGVk
    open-cluster-management.io/user-identity: c3lzdGVtOnNlcnZpY2VhY2NvdW50OnJoYWNzLW9wZXJhdG9yOnJoYWNzLW9wZXJhdG9yLWNvbnRyb2xsZXItbWFuYWdlcg==
    owner: stackrox
  creationTimestamp: "2022-08-04T06:37:54Z"
  generation: 1
  labels:
    app.kubernetes.io/instance: stackrox-central-services
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: stackrox
    app.kubernetes.io/part-of: stackrox-central-services
    app.kubernetes.io/version: 3.71.0
    helm.sh/chart: stackrox-central-services-71.0.0
  name: stackrox
  namespace: stackrox
  ownerReferences:
  - apiVersion: platform.stackrox.io/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: Central
    name: stackrox-central-services
    uid: 80c147ee-82a8-4029-84c6-4f519d549bc1
  resourceVersion: "125297"
  uid: 05a93876-302d-4b6c-b9b0-358ac15fda48

$ oc project openshift-storage
$ cat <<EOF | oc apply -f -
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: obc-aws
spec:
  bucketName: obc-aws
  storageClassName: openshift-storage.noobaa.io
  additionalConfig:
    bucketclass: noobaa-default-bucket-class
EOF

# ACM 2.4 - http_config - insecure_skip_verify
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: thanos-object-storage
  namespace: open-cluster-management-observability
type: Opaque
stringData:
  thanos.yaml: |
    type: s3
    config:
      bucket: $(oc -n openshift-storage get objectbucket obc-openshift-storage-obc-aws -o jsonpath='{.spec.endpoint.bucketName}')
      endpoint: $(oc -n openshift-storage get objectbucket obc-openshift-storage-obc-aws -o jsonpath='{.spec.endpoint.bucketHost}')
      access_key: $(oc -n openshift-storage get secret obc-aws -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d)
      secret_key: $(oc -n openshift-storage get secret obc-aws -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d)
      http_config:
        insecure_skip_verify: true
EOF
```

### 测试 ACM PolicySet 特性
https://github.com/stolostron/policy-collection/tree/main/policygenerator/policy-sets/community/openshift-plus<br>
https://github.com/stolostron/policy-generator-plugin<br>
```
# 下载并安装 PolicyGenerator kustomize plugin
$ curl -L https://github.com/stolostron/policy-generator-plugin/releases/download/v1.8.0/darwin-amd64-PolicyGenerator
$ chmod +x darwin-amd64-PolicyGenerator
$ mkdir -p ${HOME}/.config/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator
$ mv darwin-amd64-PolicyGenerator ${HOME}/.config/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator/PolicyGenerator

# 克隆 sttolostron/policy-collection git repo
$ git clone https://github.com/stolostron/policy-collection 

# 安装 community/openshift-plus policy-set
$ cd policygenerator/policy-sets/community/openshift-plus
$ kustomize build --enable-alpha-plugins | oc apply -f -
placement.cluster.open-cluster-management.io/placement-openshift-plus-clusters created
placement.cluster.open-cluster-management.io/placement-openshift-plus-hub created
placementbinding.policy.open-cluster-management.io/binding-policy-openshift-plus-hub created
placementbinding.policy.open-cluster-management.io/binding-policy-openshift-plus-hub2 created
policy.policy.open-cluster-management.io/policy-acs-central-ca-bundle created
policy.policy.open-cluster-management.io/policy-acs-central-status created
policy.policy.open-cluster-management.io/policy-acs-operator-central created
policy.policy.open-cluster-management.io/policy-advanced-managed-cluster-security created
policy.policy.open-cluster-management.io/policy-advanced-managed-cluster-status created
policy.policy.open-cluster-management.io/policy-compliance-operator-install created
policy.policy.open-cluster-management.io/policy-config-quay created
policy.policy.open-cluster-management.io/policy-ocm-observability created
policy.policy.open-cluster-management.io/policy-odf created
policy.policy.open-cluster-management.io/policy-odf-status created
policy.policy.open-cluster-management.io/policy-quay-status created
policyset.policy.open-cluster-management.io/openshift-plus-clusters created
policyset.policy.open-cluster-management.io/openshift-plus-hub created

# 检查 placementBinding
$ oc -n policies get placementBinding binding-policy-openshift-plus-hub -o yaml
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"policy.open-cluster-management.io/v1","kind":"PlacementBinding","metadata":{"annotations":{},"labels":{"open-cluster-management.io/policy-set":"openshift-plus"},"name":"binding-policy-openshift-plus-hub","namespace":"policies"},"placementRef":{"apiGroup":"cluster.open-cluster-management.io","kind":"Placement","name":"placement-openshift-plus-clusters"},"subjects":[{"apiGroup":"policy.open-cluster-management.io","kind":"PolicySet","name":"openshift-plus-clusters"}]}
  creationTimestamp: "2022-08-05T05:49:10Z"
  generation: 1
  labels:
    open-cluster-management.io/policy-set: openshift-plus
  name: binding-policy-openshift-plus-hub
  namespace: policies
  resourceVersion: "385676"
  uid: 089f23c6-ba91-43cf-a9ff-0f17ff393fc4
placementRef:
  apiGroup: cluster.open-cluster-management.io
  kind: Placement
  name: placement-openshift-plus-clusters
subjects:
- apiGroup: policy.open-cluster-management.io
  kind: PolicySet
  name: openshift-plus-clusters

# 检查 Placement
$ oc -n policies get placement placement-openshift-plus-clusters -o yaml 
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"cluster.open-cluster-management.io/v1beta1","kind":"Placement","metadata":{"annotations":{},"labels":{"open-cluster-management.io/policy-set":"openshift-plus"},"name":"placement-openshift-plus-clusters","namespace":"policies"},"spec":{"predicates":[{"requiredClusterSelector":{"labelSelector":{"matchExpressions":[{"key":"vendor","operator":"In","values":["OpenShift"]},{"key":"name","operator":"NotIn","values":["local-cluster"]}]}}}]}}
  creationTimestamp: "2022-08-05T05:49:08Z"
  generation: 1
  labels:
    open-cluster-management.io/policy-set: openshift-plus
  name: placement-openshift-plus-clusters
  namespace: policies
  resourceVersion: "385600"
  uid: 52ab1ad0-2d47-4627-b353-82c285cc45c0
spec:
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchExpressions:
        - key: vendor
          operator: In
          values:
          - OpenShift
        - key: name
          operator: NotIn
          values:
          - local-cluster
status:
  conditions:
  - lastTransitionTime: "2022-08-05T05:49:08Z"
    message: No valid ManagedClusterSetBindings found in placement namespace
    reason: NoManagedClusterSetBindings
    status: "False"
    type: PlacementSatisfied
  numberOfSelectedClusters: 0


```

### 查看 ramon 日志
https://red-hat-storage.github.io/ocs-training/training/ocs4/odf410-multisite-ramen.html
```
# 查看 ramon 日志
# Hub Cluster
$ oc -n openshift-dr-system logs $(oc -n openshift-dr-system get pods -l  app='ramen-hub' -o name) -c manager

# Managed Cluster
$ oc -n openshift-dr-system logs $(oc -n openshift-dr-system get pods -l  app='ramen-dr-cluster' -o name) -c manager

# 一些 Ramen 的 CRDs
oc api-resources | grep -Ei rep
...
volumereplicationgroups               vrg                 ramendr.openshift.io/v1alpha1                 true         VolumeReplicationGroup
volumereplicationclasses              vrc                 replication.storage.openshift.io/v1alpha1     false        VolumeReplicationClass
volumereplications                    vr                  replication.storage.openshift.io/v1alpha1     true         VolumeReplication

# volumereplicationclass 查看
$ oc get volumereplicationclasses rbd-volumereplicationclass-539797778  -o yaml 
apiVersion: replication.storage.openshift.io/v1alpha1
kind: VolumeReplicationClass
metadata:
  creationTimestamp: "2022-08-08T05:09:38Z"
  generation: 1
  name: rbd-volumereplicationclass-539797778
  resourceVersion: "109414"
  uid: dbbb227c-d589-4f54-a967-3fc82921ef4a
spec:
  parameters:
    mirroringMode: snapshot
    replication.storage.openshift.io/replication-secret-name: rook-csi-rbd-provisioner
    replication.storage.openshift.io/replication-secret-namespace: openshift-storage
    schedulingInterval: 15m
  provisioner: openshift-storage.rbd.csi.ceph.com

ocfageodf1 patch pvc busybox-pvc -n busybox-sample -p '{"metadata":{"finalizers":[]}}' --type=merge

# https://red-hat-storage.github.io/ocs-training/training/ocs4/odf410-multisite-ramen.html
# 链接里的步骤不适用于 ACM 2.5.1，label 需要调整
# the issue was related to the VRC having a label using 'matchselector' in the replicationClassSelector, that was not matched by any volumereplicationclass, after removing the label from the drpc/vrg it has been able to create the volume replication for the app PVC:
# 
# ACM 2.5.1 DRPC example
# labels 有 app 和 cluster.open-cluster-management.io/backup
apiVersion: ramendr.openshift.io/v1alpha1
kind: DRPlacementControl
metadata:
  labels:
    app: busybox-sample
    cluster.open-cluster-management.io/backup: resource
  name: busybox-drpc
  namespace: busybox-sample
spec:
  drPolicyRef:
    name: odr-policy-5m
  placementRef:
    kind: PlacementRule
    name: busybox-placement
    namespace: busybox-sample
  preferredCluster: ocp1
  pvcSelector:
    matchLabels:
      appname: busybox

```

### ACM Hub 日志
```
### ACM 2.4.5
### namespace
$ oc get projects | grep open-cluster-management
open-cluster-management                                           Active
open-cluster-management-agent                                     Active
open-cluster-management-agent-addon                               Active
open-cluster-management-hub                                       Active

### open-cluster-management-hub
### clustermanager-registration-controller 
$ oc -n open-cluster-management-hub logs $(oc -n open-cluster-management-hub get pods -l app='clustermanager-registration-controller' -o name | head -1)

### cluster-manager-registration-webhook
$ oc -n open-cluster-management-hub logs $(oc -n open-cluster-management-hub get pods -l app='cluster-manager-registration-webhook' -o name | head -1)

### cluster-manager-placement-controller
$ oc -n open-cluster-management-hub logs $(oc -n open-cluster-management-hub get pods -l app='clustermanager-placement-controller' -o name | head -1)

### cluster-manager-work-webhook
$ oc -n open-cluster-management-hub logs $(oc -n open-cluster-management-hub get pods -l app='cluster-manager-work-webhook' -o name | head -1)

### open-cluster-management
### submariner-addon
$ oc -n open-cluster-management logs $(oc -n open-cluster-management get pods -l app='submariner-addon' -o name)

NAME                                                       READY   STATUS    RESTARTS   AGE
cluster-manager-placement-controller-d64cf58bc-jrg9t       1/1     Running   0          18h
cluster-manager-placement-controller-d64cf58bc-kvb64       1/1     Running   0          18h
cluster-manager-placement-controller-d64cf58bc-pxkbg       1/1     Running   0          18h
cluster-manager-registration-controller-5c569f9696-4tltd   1/1     Running   0          18h
cluster-manager-registration-controller-5c569f9696-gn8c5   1/1     Running   0          18h
cluster-manager-registration-controller-5c569f9696-r9z2z   1/1     Running   0          18h
cluster-manager-registration-webhook-8bc7757d6-4kh7j       1/1     Running   0          18h
cluster-manager-registration-webhook-8bc7757d6-cjbmd       1/1     Running   0          18h
cluster-manager-registration-webhook-8bc7757d6-pdgl7       1/1     Running   0          18h
cluster-manager-work-webhook-5bb4d858cd-5tll9              1/1     Running   0          18h
cluster-manager-work-webhook-5bb4d858cd-jzl25              1/1     Running   0          18h
cluster-manager-work-webhook-5bb4d858cd-ndxm8              1/1     Running   0          18h


```

### 检查 submariner operator 状态 
```
# 日志
# submariner-gateway
oc -n submariner-operator logs $(oc -n submariner-operator get pods -l app='submariner-gateway' -o name)


```

### ODF 移除 OSD 的命令
```
# 移除 OSD 
# oc process -n openshift-storage ocs-osd-removal -p FORCE_OSD_REMOVAL=true -p FAILED_OSD_IDS=${failed_osd_id} | oc create -f -


```

### token 有效期
```
### 创建 token，有效期 365*24h 
oc create token ... --duration=$((365*24))h
```

### 查看 DR Hub 日志
```
### ramen-hub
$ oc -n openshift-dr-system logs $(oc -n openshift-dr-system get pods -l app='ramen-hub' -o name) -c manager

### odfmo-controller-manager
$ oc -n openshift-operators logs $(oc -n openshift-operators get pods -l control-plane='odfmo-controller-manager' -o name)

### ramen-dr-cluster
$ oc -n openshift-dr-system logs $(oc -n openshift-dr-system get pods -l app='ramen-dr-cluster' -o name) -c manager

### 验证 Primary Managed Cluster 与 2nd Managed Cluster 
### 已启用 mirror
$ oc get cephblockpool -n openshift-storage -o=jsonpath='{.items[?(@.metadata.ownerReferences[*].kind=="StorageCluster")].spec.mirroring.enabled}{"\n"}'

$ oc get pods -o name -l app=rook-ceph-rbd-mirror -n openshift-storage

#### 验证 cephblockpool mirroringStatus 为 {"daemon_health":"OK","health":"OK","image_health":"OK","states":{}}
$ oc get cephblockpool ocs-storagecluster-cephblockpool -n openshift-storage -o jsonpath='{.status.mirroringStatus.summary}{"\n"}'

### 获取 volumereplicationclass
$ oc get volumereplicationclass 

### 获取 obc 与 ob
$ oc get obc,ob -n openshift-storage

### Hub 用于同步 pvc,pv metadata 的 s3 bucket 访问信息
$ oc get secrets -n openshift-dr-system | grep Opaque
### Hub openshift-dr-system namespace 下的 configmap ramen-hub-operator-config 有 s3StoreProfiles
### 记录 s3ProfileName，DRPolicy 会用到
$ oc get cm ramen-hub-operator-config -n openshift-dr-system -o yaml | grep -A 14 s3StoreProfiles
    s3StoreProfiles:
    - s3Bucket: odrbucket-cfc80fa7fd87
      s3CompatibleEndpoint: https://s3-openshift-storage.apps.ocp2.sandbox292.opentlc.com
      s3ProfileName: s3profile-ocp2-ocs-storagecluster
      s3Region: noobaa
      s3SecretRef:
        name: 42b4c31d0f9d8a994d882b83dff285f7672bb7b
        namespace: openshift-dr-system
    - s3Bucket: odrbucket-cfc80fa7fd87
      s3CompatibleEndpoint: https://s3-openshift-storage.apps.ocp1.sandbox292.opentlc.com
      s3ProfileName: s3profile-ocp1-ocs-storagecluster
      s3Region: noobaa
      s3SecretRef:
        name: 3ad4a67e05abe42e5d0121946e38a3e09c68dfb
        namespace: openshift-dr-system

### 在 Primary ODF Cluster 和 2nd ODF Cluster 上创建 StorageClass
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-storagecluster-ceph-rbdmirror
parameters:
  clusterID: openshift-storage
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-storage
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: openshift-storage
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-storage
  imageFeatures: layering,exclusive-lock,object-map,fast-diff
  imageFormat: "2"
  pool: ocs-storagecluster-cephblockpool
provisioner: openshift-storage.rbd.csi.ceph.com
reclaimPolicy: Delete
volumeBindingMode: Immediate

### 获取 ingress 证书
### oc login - ocp1
$ oc get cm default-ingress-cert -n openshift-config-managed -o jsonpath="{['data']['ca-bundle\.crt']}" > primary.crt

### 获取 ingress 证书
### oc login - ocp2
$ oc get cm default-ingress-cert -n openshift-config-managed -o jsonpath="{['data']['ca-bundle\.crt']}" > secondary.crt

### 在 Hub, ocp1 和 ocp2 更新完 ingress 证书后
$ oc patch proxy cluster --type=merge  --patch='{"spec":{"trustedCA":{"name":"user-ca-bundle"}}}'

### Hub 检查 DRPolicy 状态
$ oc get drpolicy odr-policy-1m -n openshift-dr-system -o jsonpath='{.status.conditions[].reason}{"\n"}'

### Hub 启用自动安装 ODR Cluster Operator on Managed Cluster
$ oc edit configmap ramen-hub-operator-config -n openshift-dr-system
apiVersion: v1
data:
  ramen_manager_config.yaml: |
    apiVersion: ramendr.openshift.io/v1alpha1
    drClusterOperator:
      deploymentAutomationEnabled: true  ## <-- Add to enable installation of ODR Cluster operator on managed clusters
      catalogSourceName: redhat-operators
      catalogSourceNamespaceName: openshift-marketplace
      channelName: stable-4.10
      clusterServiceVersionName: odr-cluster-operator.v4.10.0
      namespaceName: openshift-dr-system
      packageName: odr-cluster-operator
[...]

### 在 ocp1 与 ocp2 集群上执行
$ oc get csv,pod -n openshift-dr-system

### 检查
### ocp1
$ oc get pods,pvc -n wordpress
$ oc get volumereplication,volumereplicationgroup -n wordpress

### 检查 cephblockpool 的 mirroringStatus summary
### ocp1
$ oc get cephblockpool ocs-storagecluster-cephblockpool -n openshift-storage -o jsonpath='{.status.mirroringStatus.summary}{"\n"}'
### ocp2
$ oc get cephblockpool ocs-storagecluster-cephblockpool -n openshift-storage -o jsonpath='{.status.mirroringStatus.summary}{"\n"}'
```

### MachineAutoScaler and ClusterAutoScaler
https://docs.openshift.com/container-platform/4.9/machine_management/applying-autoscaling.html#cluster-autoscaler-about_applying-autoscaling<br>
```
### 定义 MachineAutoscaler
apiVersion: autoscaling.openshift.io/v1beta1
kind: MachineAutoscaler
metadata:
  name: worker-us-east-2b
  namespace: openshift-machine-api
spec:
  maxReplicas: 2
  minReplicas: 1
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: cluster-48rlc-6bq76-worker-us-east-2b

### 定义 ClusterAutoscaler
apiVersion: "autoscaling.openshift.io/v1"
kind: "ClusterAutoscaler"
metadata:
  name: "default"
spec:
  podPriorityThreshold: -10 
  resourceLimits:
    maxNodesTotal: 7 
  scaleDown: 
    enabled: true 
    delayAfterAdd: 10m 
    delayAfterDelete: 5m 
    delayAfterFailure: 30s 
    unneededTime: 5m

### 创建应用
### https://github.com/JonkeyGuan/wordpress-odr
### 根据需要定义 resources.requests.cpu 和 resources.limits.cpu
cat wordpress/deployment.yaml
...
      containers:
      - image: bitnami/wordpress:6
        resources:
          requests:
            cpu: 4000m
          limits:
            cpu: 4000m

cat mysql/deployment.yaml
...
      containers:
      - image: bitnami/mysql:8.0
        resources:
          requests:
            cpu: 4000m
          limits:
            cpu: 4000m

### 创建 namespace
oc new-project <namespace>
### 部署应用
oc apply -k . 
```

### IPv6 and DualipStack
```
### 手工设置 ipv6 缺省路由
sudo nmcli connection modify  <con-name>  +ipv6.routes "::/0 <route>::1"
```

### 配置 NTP 的例子
https://raw.githubusercontent.com/stolostron/policy-collection/main/community/CM-Configuration-Management/policy-machineconfig-chrony.yaml
```
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: add-chrony
  annotations:
    policy.open-cluster-management.io/standards: NIST SP 800-53
    policy.open-cluster-management.io/categories: CM Configuration Management
    policy.open-cluster-management.io/controls: CM-2 Baseline Configuration
spec:
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: add-chrony-worker
        spec:
          namespaceSelector:
            exclude:
              - kube-*
            include:
              - default
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: machineconfiguration.openshift.io/v1
                kind: MachineConfig
                metadata:
                  name: 99-worker-chrony
                  labels:
                    machineconfiguration.openshift.io/role: worker
                spec:
                  config:
                    ignition:
                      version: 2.2.0
                    storage:
                      files:
                      - contents:
                          source: data:text/plain;charset=utf-8;base64,c2VydmVyIDAuZmVkb3JhLnBvb2wubnRwLm9yZyBpYnVyc3QKc2VydmVyIDEuZmVkb3JhLnBvb2wubnRwLm9yZyBpYnVyc3QKc2VydmVyIDIuZmVkb3JhLnBvb2wubnRwLm9yZyBpYnVyc3QKZHJpZnRmaWxlIC92YXIvbGliL2Nocm9ueS9kcmlmdAptYWtlc3RlcCAxLjAgMTAKcnRjc3luYwpsb2dkaXIgL3Zhci9sb2cvY2hyb255Cg==
                          verification: {}
                        filesystem: root
                        mode: 420
                        path: /etc/chrony.conf
          remediationAction: enforce
          severity: low
  remediationAction: enforce
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-add-chrony
placementRef:
  name: placement-add-chrony
  kind: PlacementRule
  apiGroup: apps.open-cluster-management.io
subjects:
- name: add-chrony
  kind: Policy
  apiGroup: policy.open-cluster-management.io
---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: placement-add-chrony
spec:
  clusterConditions:
  - status: "True"
    type: ManagedClusterConditionAvailable
  clusterSelector:
    matchExpressions:
      - {key: environment, operator: In, values: ["dev"]}


oc -n local-cluster patch Policy default.add-chrony --type=merge --patch='{"spec":{"remediationAction": "enforce"}}'

server 0.fedora.pool.ntp.org
server 1.fedora.pool.ntp.org
server 2.fedora.pool.ntp.org
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
```

### CloudOSImage 例子
```
CloudOSImage: 
https://<path.to/image>?sha256=<sha256sum of uncompressed image>
```

### 将 ClusterNetwork 从 SingleStack 改为 DualStack
https://docs.openshift.com/container-platform/4.8/networking/ovn_kubernetes_network_provider/converting-to-dual-stack.html<br>

```
### 在 AWS 上做这种改变 ovnkube-node 报错
$ oc -n openshift-ovn-kubernetes logs ovnkube-node-lx7q6 -c ovnkube-node | grep -Ev "^I0"
...
F0816 04:34:42.921856  126291 ovnkube.go:133] failed to get default gateway interface

$ cat > /tmp/clusternetwork-dualstack.yaml <<EOF
- op: add
  path: /spec/clusterNetwork/-
  value: 
    cidr: fd01::/48
    hostPrefix: 64
- op: add
  path: /spec/serviceNetwork/-
  value: fd02::/112
EOF

$ oc patch network.config.openshift.io cluster --type='json' --patch-file /tmp/clusternetwork-dualstack.yaml

$ oc describe network

oc -n openshift-network-operator logs $(oc -n openshift-network-operator get pods -l name='network-operator' -o name)

oc -n openshift-cloud-network-config-controller get pods

oc -n openshift-cloud-network-config-controller logs $(oc -n openshift-cloud-network-config-controller get pods -l app='cloud-network-config-controller' -o name)

```

### aws cli 
```
### 列出所有实例
$ aws ec2 describe-instances
$ aws ec2 describe-regions --region us-east-1 --output text
$ aws ec2 describe-instances --output text | grep -E INSTANCES
```

### install-config.yaml
```
controlPlane:
  name: master
  platform:
    openstack:
      zones: ['AZ-0', 'AZ-1', 'AZ-2']
      rootVolume:
        size: 25
        type: tripleo
        zones: ['cinderAZ0', 'cinderAZ1', 'cinderAZ0']
  replicas: 3
```

### Dev Install for developer setup openshift/openstack/ceph
https://github.com/shiftstack/dev-install

### destroy IPI cluster
```
$ openshift-install create manifests --dir <installation_directory>
$ openshift-install create install-config --dir <installation_directory>
$ openshift-install create cluster --dir <installation_directory> --log-level debug
$ openshift-install destroy cluster --dir <installation_directory> --log-level debug
```

### 查看 machine-api-controller 日志
```
$ oc -n openshift-machine-api logs $(oc -n openshift-machine-api get pods -l k8s-app='controller' -o name)
error: a container name must be specified for pod machine-api-controllers-6497cfb95-z84vj, choose one of: [machineset-controller machine-controller nodelink-controller machine-healthcheck-controller kube-rbac-proxy-machineset-mtrc kube-rbac-proxy-machine-mtrc kube-rbac-proxy-mhc-mtrc]

$ oc -n openshift-machine-api logs $(oc -n openshift-machine-api get pods -l k8s-app='controller' -o name) -c machine-controller

$ oc -n openshift-machine-api logs $(oc -n openshift-machine-api get pods -l k8s-app='controller' -o name) -c nodelink-controller

# 查看 machine 创建状态
$ oc -n openshift-machine-api logs $(oc -n openshift-machine-api get pods -l k8s-app='controller' -o name) -c machine-controller | grep "cluster-cgm5v-q54tc-worker-0-2rl4h" | grep -E "going into phase"
I0823 02:26:46.346491       1 controller.go:504] cluster-cgm5v-q54tc-worker-0-2rl4h: going into phase "Provisioning"
I0823 02:27:13.233321       1 controller.go:504] cluster-cgm5v-q54tc-worker-0-2rl4h: going into phase "Provisioned"
I0823 02:34:08.383090       1 controller.go:504] cluster-cgm5v-q54tc-worker-0-2rl4h: going into phase "Running" 

$ oc -n openshift-machine-api logs $(oc -n openshift-machine-api get pods -l cluster-autoscaler='default' -o name)
$ oc -n openshift-machine-api get cm cluster-autoscaler-status -o yaml

# 调试
> Assuming this is reproducible, I think it would be good to gather some logs
> from the cluster autoscaler at a higher log level than they are currently
> set at (-v=1), to do this you can add the environment variable
> CLUSTER_AUTOSCALER_VERBOSITY=4 to the cluster-autoscaler-operator
> deployment, before you do this you will need to disable CVO though as it
> will revert any changes that you make to the cluster-autoscaler-operator
> deployment.
https://bugzilla.redhat.com/show_bug.cgi?id=1880930



```

### 安装 Performance Addon Operator
```
### 首先安装 Performance Addon Operator

### 为 Node 添加 label
node-role.kubernetes.io/worker-rt

### 创建 MachineConfigPool worker-rt
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: worker-rt
  labels:
    machineconfiguration.openshift.io/role: worker-rt
spec:
  machineConfigSelector:
    matchExpressions:
      - {
           key: machineconfiguration.openshift.io/role,
           operator: In,
           values: [worker, worker-rt],
        }
  paused: false
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/worker-rt: ""

### 然后创建 PerformanceProfile
### 根据实际情况调整 8c16g100d 
### cpu
### hugepages
### 另外根据
### https://github.com/jordigilh/kubevirt-realtime-doc
### 不需要 additionalKernelArgs
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
  name: test-performanceprofile
spec:
  additionalKernelArgs:
    - nmi_watchdog=0
    - audit=0
    - mce=off
    - processor.max_cstate=1
    - idle=poll
    - intel_idle.max_cstate=0
  cpu:
    isolated: 2-7
    reserved: 0-1
  hugepages:
    pages:
      - count: 8
        node:0
        size: 1G
    defaultHugepagesSize: 1G
  realTimeKernel:
    enabled: true
  numa:
    topologyPolicy: "best-effort"
  nodeSelector:
    node-role.kubernetes.io/worker-rt: ""
  machineConfigPoolSelector:
    machineconfiguration.openshift.io/role: worker-rt



### https://github.com/jordigilh/kubevirt-realtime-doc/blob/main/manifests/01-performance_addon_operator/05-performanceprofile.yaml
### 可以考虑按需添加 numa topologyPolicy 
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
  name: rt
spec:
  nodeSelector:
    node-role.kubernetes.io/worker-rt: ""
  cpu:
    isolated: "1,3"
    reserved: "0"
  hugepages:
    defaultHugepagesSize: "1G"
    pages:
    - size:  "1G"
      count:  4
      node:  0
  realTimeKernel:
    enabled: true
  numa:
    topologyPolicy: "best-effort"

### 这是我找到的一个文档，关于 kubevirt and realtime
### 参考一下
### https://github.com/jordigilh/kubevirt-realtime-doc
[junwang@JundeMacBook-Pro ~/work/docs/kubevirt-realtime-doc]$ oc create -Rf manifests/02-kubevirt/
namespace/kubevirt created
customresourcedefinition.apiextensions.k8s.io/kubevirts.kubevirt.io created
priorityclass.scheduling.k8s.io/kubevirt-cluster-critical created
clusterrole.rbac.authorization.k8s.io/kubevirt.io:operator created
serviceaccount/kubevirt-operator created
role.rbac.authorization.k8s.io/kubevirt-operator created
rolebinding.rbac.authorization.k8s.io/kubevirt-operator-rolebinding created
clusterrole.rbac.authorization.k8s.io/kubevirt-operator created
clusterrolebinding.rbac.authorization.k8s.io/kubevirt-operator created
Warning: spec.template.metadata.annotations[scheduler.alpha.kubernetes.io/critical-pod]: non-functional in v1.16+; use the "priorityClassName" field instead
deployment.apps/virt-operator created
kubevirt.kubevirt.io/kubevirt created

### https://source.redhat.com/groups/public/global_industrial_sector/industrial_blog/how_to_demo_low_latency_capabilities
### https://raw.githubusercontent.com/redhat-nfvpe/container-perf-tools/master/ocp-examples/cyclictest/pod_cyclictest.yaml
### node 选择 
### kubernetes.io/hostname=ip-10-0-220-55.us-east-2.compute.internal
### 非 RT 的节点不能运行 cyclictest
### cyclictest 参数说明
### https://zhuanlan.zhihu.com/p/336381111


### cyclictest 运行命令
cyclictest -q -D 10s -p 95 -t 1 -a -h 30 -i 1000
cyclictest -q -D 10s -p 95 -t 1 -a -h 300 -i 1000

### hwlatencydetect
### https://raw.githubusercontent.com/redhat-nfvpe/container-perf-tools/master/sample-yamls/pod_hwlatdetect.yaml
/usr/bin/hwlatdetect --threshold 20 --hardlimit 1000 --duration 15s --window 10000000us --width 950000us

### 查看 Tuned Profile
oc get Tuned openshift-node-performance-rt -n openshift-cluster-node-tuning-operator -o jsonpath='{.spec.profile[0].data}'
oc get Tuned default -n openshift-cluster-node-tuning-operator -o jsonpath='{.spec.profile[0].data}'
oc get Tuned rendered -n openshift-cluster-node-tuning-operator -o jsonpath='{.spec.profile[0].data}'

```

### 下载 OpenShift 客户端
https://console.redhat.com/openshift/downloads


### 4.11 redhat-operator-index 

```
# podman ps 
CONTAINER ID  IMAGE                                                               COMMAND         CREATED        STATUS            PORTS                     NAMES
20c6641a89b3  quay.io/microshift/microshift:4.8.0-0.microshift-2022-02-04-005920  run             3 months ago   Up 3 months ago                             microshift
a30d93f0636d  registry.redhat.io/redhat/redhat-operator-index:v4.11               serve /configs  5 minutes ago  Up 5 minutes ago  0.0.0.0:50051->50051/tcp  pensive_beaver

sh-4.4$ ps ax 
    PID TTY      STAT   TIME COMMAND
      1 pts/0    Ssl+   0:24 /bin/opm serve /configs
     15 pts/1    Ss     0:00 sh
     25 pts/1    R+     0:00 ps ax

sh-4.4$ ls /configs/
3scale-operator                       devspaces                    mtv-operator                                  quay-operator
advanced-cluster-management           devworkspace-operator        multicluster-engine                           red-hat-camel-k
amq-online                            dpu-network-operator         nfd                                           redhat-oadp-operator
amq-streams                           eap                          node-healthcheck-operator                     rh-service-binding-operator
amq7-interconnect-operator            elasticsearch-operator       node-maintenance-operator                     rhacs-operator
ansible-automation-platform-operator  external-dns-operator        node-observability-operator                   rhpam-kogito-operator
ansible-cloud-addons-operator         file-integrity-operator      numaresources-operator                        rhsso-operator
apicast-operator                      fuse-apicurito               ocs-operator                                  sandboxed-containers-operator
aws-efs-csi-driver-operator           fuse-console                 odf-csi-addons-operator                       self-node-remediation
aws-load-balancer-operator            fuse-online                  odf-lvm-operator                              serverless-operator
bamoe-businessautomation-operator     gatekeeper-operator-product  odf-multicluster-orchestrator                 service-registry-operator
bamoe-kogito-operator                 integration-operator         odf-operator                                  servicemeshoperator
bare-metal-event-relay                jaeger-product               odr-cluster-operator                          skupper-operator
businessautomation-operator           jws-operator                 odr-hub-operator                              sriov-network-operator
cincinnati-operator                   kiali-ossm                   openshift-cert-manager-operator               submariner
cluster-kube-descheduler-operator     klusterlet-product           openshift-custom-metrics-autoscaler-operator  tang-operator
cluster-logging                       kubernetes-nmstate-operator  openshift-gitops-operator                     topology-aware-lifecycle-manager
clusterresourceoverride               kubevirt-hyperconverged      openshift-pipelines-operator-rh               vertical-pod-autoscaler
compliance-operator                   local-storage-operator       openshift-secondary-scheduler-operator        volsync-product
container-security-operator           loki-operator                openshift-special-resource-operator           web-terminal
costmanagement-metrics-operator       mcg-operator                 opentelemetry-product                         windows-machine-config-operator
cryostat-operator                     metallb-operator             ptp-operator
datagrid                              mtc-operator                 quay-bridge-operator

# 新的 reference 
# https://github.com/openshift/oc-mirror/blob/release-4.11/docs/imageset-config-ref.yaml
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
storageConfig:
  local:
    path: /root/oc-workspace
mirror:
  platform:
    channels:
      - name: stable-4.10
        minVersion: '4.10.22'
        maxVersion: '4.10.22'
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.10
      full: true
      packages:
        - name: advanced-cluster-management
        - name: cluster-logging
        - name: elasticsearch-operator
        - name: kubernetes-nmstate-operator
        - name: kubevirt-hyperconverged
        - name: local-storage-operator
        - name: mcg-operator
        - name: ocs-operator
        - name: odf-operator
        - name: openshift-gitops-operator
        - name: rhacs-operator
        - name: performance-addon-operator
EOF
/usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml --continue-on-error file://output-dir
Creating directory: output-dir/oc-mirror-workspace/src/publish
Creating directory: output-dir/oc-mirror-workspace/src/v2
Creating directory: output-dir/oc-mirror-workspace/src/charts
Creating directory: output-dir/oc-mirror-workspace/src/release-signatures
No metadata detected, creating new workspace
WARN[0114] DEPRECATION NOTICE:
Sqlite-based catalogs and their related subcommands are deprecated. Support for
them will be removed in a future release. Please migrate your catalog workflows
to the new file-based catalog format. 
wrote mirroring manifests to output-dir/oc-mirror-workspace/operators.1661764511/manifests-redhat-operator-index

To upload local images to a registry, run:

        oc adm catalog mirror file://redhat/redhat-operator-index:v4.10 REGISTRY/REPOSITORY


```

### 屏幕警告
```
Warning alert:Nmstate will be removed from CNAO. Runbook

Node - cluster-6jgpm-gpzsz-worker-0-bnmzr 
Namespace - openshift-network-diagnostics
Generated from check-endpoint-checkendpointsstop
Controller "CheckEndpointsStop" resync interval is set to 0s which might lead to client request throttling


Node的错误
I0830 08:42:57.824224    2245 drain.go:91] Draining failed with: [error when evicting pods/"virt-api-7c5877664c-hdsdj" -n "openshift-cnv": global timeout reached: 1m30s, error when evicting pods/"virt-controller-d767968dc-kzrpl" -n "openshift-cnv": global timeout reached: 1m30s], retrying
E0830 08:43:59.274134    2245 daemon.go:335] WARNING: ignoring DaemonSet-managed Pods: openshift-cluster-csi-drivers/openstack-cinder-csi-driver-node-2m95n, openshift-cluster-node-tuning-operator/tuned-crr7n, openshift-cnv/bridge-marker-k22lr, openshift-cnv/kube-cni-linux-bridge-plugin-hq9pl, openshift-cnv/nmstate-handler-6w2hb, openshift-cnv/virt-handler-nkl2c, openshift-dns/dns-default-wghc4, openshift-dns/node-resolver-v9hqf, openshift-image-registry/node-ca-mz6hh, openshift-ingress-canary/ingress-canary-ff7jr, openshift-machine-config-operator/machine-config-daemon-tzx79, openshift-monitoring/node-exporter-6qn64, openshift-multus/multus-additional-cni-plugins-nhs6g, openshift-multus/multus-thqq2, openshift-multus/network-metrics-daemon-4v8x7, openshift-network-diagnostics/network-check-target-crb8r, openshift-sdn/sdn-gxmbc
I0830 08:43:59.277236    2245 daemon.go:335] evicting pod openshift-cnv/virt-controller-d767968dc-kzrpl
I0830 08:43:59.277582    2245 daemon.go:335] evicting pod openshift-cnv/virt-api-7c5877664c-hdsdj
E0830 08:43:59.289770    2245 daemon.go:335] error when evicting pods/"virt-api-7c5877664c-hdsdj" -n "openshift-cnv" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.

oc logs -f -n openshift-machine-config-operator machine-config-daemon-tzx79 -c machine-config-daemon


[junwang@JundeMacBook-Pro ~]$ oc get pdb -A 
...
openshift-cnv                          nmstate-webhook                              1               N/A               1                     106m
openshift-cnv                          virt-api-pdb                                 1               N/A               0                     106m
openshift-cnv                          virt-controller-pdb                          1               N/A               0                     105m

[junwang@JundeMacBook-Pro ~]$ oc get pods -A | grep virt-api 
openshift-cnv                                      virt-api-7c5877664c-hdsdj                                     1/1     Running     0               71m
openshift-cnv                                      virt-api-7c5877664c-z8g2s                                     0/1     Pending     0               67m


# 检查 node 是否支持 kvm nested
sh-4.4# chroot /host
sh-4.4# cat /sys/module/kvm_intel/parameters/nested
1
```


### 检查一下 namespace 下有哪些对象
```
$ oc api-resources --verbs=list --namespaced=true -o name | xargs -n 1 oc get --show-kind --ignore-not-found -n kubevirt 

$ oc api-resources --verbs=list --namespaced=true -o name | while read i ; do echo oc get --show-kind --ignore-not-found -n kubevirt $i; oc get --show-kind --ignore-not-found -n kubevirt $i; echo ; done
...
oc get --show-kind --ignore-not-found -n kubevirt kubevirts.kubevirt.io
NAME                            AGE   PHASE
kubevirt.kubevirt.io/kubevirt   24m   Deleting
...


```


### 测试 latency
https://github.com/openshift-kni/cnf-features-deploy/tree/master/cnf-tests#running-latency-test<br>
```
# https://access.redhat.com/solutions/4845381
# About the OpenShift 4 kubeconfig file for system:admin
oc -n openshift-kube-apiserver extract secret/node-kubeconfigs

export KUBECONFIG="./lb-ext.kubeconfig"

podman run --rm -v $KUBECONFIG:/kubeconfig \
-e KUBECONFIG=/kubeconfig \
-e LATENCY_TEST_RUN=true \
-e LATENCY_TEST_RUNTIME=600 \
-e OSLAT_MAXIMUM_LATENCY=20 \
-e CYCLICTEST_MAXIMUM_LATENCY=20 \
-e HWLATDETECT_MAXIMUM_LATENCY=20 \
-e PERF_TEST_PROFILE=rt \
quay.io/openshift-kni/cnf-tests /usr/bin/test-run.sh -ginkgo.focus="\[performance\]\[config\]|\[performance\]\ Latency\ Test"

### 获取 must-gather 信息
# https://docs.openshift.com/container-platform/4.9/scalability_and_performance/cnf-create-performance-profiles.html
oc adm must-gather --image=registry.redhat.io/openshift4/performance-addon-operator-must-gather-rhel8:v4.10 --dest-dir=must-gather

### 以 Discovery 模式执行 Performance Profile Creator
### ??
podman run --entrypoint performance-profile-creator -v /must-gather:/must-gather:z registry.redhat.io/openshift4/performance-addon-rhel8-operator:v4.10 --info log --must-gather-dir-path ./must-gather

### 更有针对性的执行 Performance Profile Creator
podman run --entrypoint performance-profile-creator -v /must-gather:/must-gather:z registry.redhat.io/openshift4/performance-addon-rhel8-operator:v4.10 --mcp-name=worker-rt --reserved-cpu-count=2 --rt-kernel=true --split-reserved-cpus-across-numa=false --topology-manager-policy=single-numa-node --must-gather-dir-path /must-gather  --power-consumption-mode=ultra-low-latency > my-performance-profile.yaml
```

### 添加 RHEL 节点
```
https://access.redhat.com/documentation/en-us/openshift_container_platform/4.9/html/machine_management/adding-rhel-compute
# subscription-manager repos \
    --enable="rhel-8-for-x86_64-baseos-rpms" \
    --enable="rhel-8-for-x86_64-appstream-rpms" \
    --enable="rhocp-4.10-for-rhel-8-x86_64-rpms" \
    --enable="fast-datapath-for-rhel-8-x86_64-rpms"

yum -y install yum-utils createrepo 
for repo in $(subscription-manager repos --list-enabled | grep "Repo ID" | awk '{print $3}'); do
    reposync --gpgcheck -lmn --repoid=${repo} --download_path=${YUM_PATH}
    createrepo -v ${YUM_PATH}/${repo} -o ${YUM_PATH}/${repo} 
done

for repo in $(subscription-manager repos --list-enabled | grep "Repo ID" | awk '{print $3}'); do
    reposync --gpgcheck -n --repoid=${repo} --download-path=${YUM_PATH} --download-metadata
    createrepo -v ${YUM_PATH}/${repo} -o ${YUM_PATH}/${repo} 
done

for repo in rhel-7-server-rpms rhel-7-server-extras-rpms rhel-7-server-ose-${OCP_MAJOR_VER}-rpms; do
    reposync --gpgcheck -lmn --repoid=${repo} --download_path=${YUM_PATH}
    createrepo -v ${YUM_PATH}/${repo} -o ${YUM_PATH}/${repo} 
done


setVAR DOMAIN example.com
setVAR OCP_CLUSTER_ID ocp4-1
setVAR BASTION_IP 192.168.122.13
setVAR SUPPORT_IP 192.168.122.12
setVAR DNS_IP 192.168.122.12
setVAR NTP_IP 192.168.122.12
setVAR YUM_IP 192.168.122.12
setVAR REGISTRY_IP 192.168.122.12
setVAR NFS_IP 192.168.122.12
setVAR LB_IP 192.168.122.12
setVAR BOOTSTRAP_IP 192.168.122.100
setVAR MASTER0_IP 192.168.122.101
setVAR MASTER1_IP 192.168.122.102
setVAR MASTER2_IP 192.168.122.103
setVAR WORKER0_IP 192.168.122.110
setVAR WORKER1_IP 192.168.122.111

cat > /var/named/168.192.in-addr.arpa.zone << EOF
\$TTL 1D
@           IN SOA  ${DOMAIN}. admin.${DOMAIN}. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
                                        
@                              IN NS       dns.${DOMAIN}.

13.122.168.192.in-addr.arpa.     IN PTR      bastion.${DOMAIN}.

12.122.168.192.in-addr.arpa.     IN PTR      support.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      dns.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      ntp.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      yum.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      registry.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      nfs.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      lb.${OCP_CLUSTER_ID}.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      api.${OCP_CLUSTER_ID}.${DOMAIN}.
12.122.168.192.in-addr.arpa.     IN PTR      api-int.${OCP_CLUSTER_ID}.${DOMAIN}.

100.122.168.192.in-addr.arpa.    IN PTR      bootstrap.${OCP_CLUSTER_ID}.${DOMAIN}.

101.122.168.192.in-addr.arpa.    IN PTR      master-0.${OCP_CLUSTER_ID}.${DOMAIN}.
102.122.168.192.in-addr.arpa.    IN PTR      master-1.${OCP_CLUSTER_ID}.${DOMAIN}.
103.122.168.192.in-addr.arpa.    IN PTR      master-2.${OCP_CLUSTER_ID}.${DOMAIN}.

110.122.168.192.in-addr.arpa.    IN PTR      worker-0.${OCP_CLUSTER_ID}.${DOMAIN}.
111.122.168.192.in-addr.arpa.    IN PTR      worker-1.${OCP_CLUSTER_ID}.${DOMAIN}.

EOF

dig master-1.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig etcd-1.${OCP_CLUSTER_ID}.${DOMAIN} +short

dig master-2.${OCP_CLUSTER_ID}.${DOMAIN} +short
dig etcd-2.${OCP_CLUSTER_ID}.${DOMAIN} +short

setVAR PULL_SECRET_FILE ${OCP_PATH}/secret/redhat-pull-secret.json

oc adm release info 4.10.30 --dir=/data/OCP-4.10.30/ocp/ocp-image/mirror_4.10.30

setVAR GATEWAY_IP 192.168.122.1 
setVAR NETMASK 24 
setVAR CONNECT_NAME "Wired connection 1"

creat_auto_config_file(){

cat << EOF > ${IGN_PATH}/set-${NODE_NAME}
nmcli connection modify "${CONNECT_NAME}" ipv4.addresses ${IP}/${NETMASK}
nmcli connection modify "${CONNECT_NAME}" ipv4.dns ${DNS_IP}
nmcli connection modify "${CONNECT_NAME}" ipv4.gateway ${GATEWAY_IP}
nmcli connection modify "${CONNECT_NAME}" ipv4.method manual
nmcli connection down "${CONNECT_NAME}"
nmcli connection up "${CONNECT_NAME}"

sudo coreos-installer install /dev/vda --insecure-ignition --ignition-url=http://${YUM_DOMAIN}/${OCP_CLUSTER_ID}/ignition/${NODE_TYPE}.ign --firstboot-args 'rd.neednet=1' --copy-network
EOF
}
NODE_TYPE="bootstrap"
NODE_NAME="bootstrap"
IP=${BOOTSTRAP_IP}
creat_auto_config_file

NODE_TYPE="master"
NODE_NAME="master-0"
IP=${MASTER0_IP}
creat_auto_config_file

NODE_TYPE="master"
NODE_NAME="master-1"
IP=${MASTER1_IP}
creat_auto_config_file

NODE_TYPE="master"
NODE_NAME="master-2"
IP=${MASTER2_IP}
creat_auto_config_file

NODE_TYPE="worker"
NODE_NAME="worker-0"
IP=${WORKER0_IP}
creat_auto_config_file

NODE_TYPE="worker"
NODE_NAME="worker-1"
IP=${WORKER1_IP}
creat_auto_config_file

ll ${IGN_PATH}/set-*

qemu-img create -f qcow2 -o preallocation=metadata jwang-ocp452-aHelper.qcow2 100G

# https://docs.openshift.com/container-platform/4.9/support/remote_health_monitoring/opting-out-of-remote-health-reporting.html
# disconnected 环境 - 禁用 insights operator
# 获取 OpenShift4 当前 pull-secret
oc extract secret/pull-secret -n openshift-config --to=.
# 编辑 .dockerconfigjson 文件，删除 cloud.openshift.com 记录
# 更新 OpenShift4 当前 pull-secret
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=.dockerconfigjson

# 重新创建 insight operator pod
oc -n openshift-insights delete $(oc -n openshift-insights get pods -l app='insights-operator' -o name)
# 查看日志
oc -n openshift-insights logs $(oc -n openshift-insights get pods -l app='insights-operator' -o name)

# 同步 Operator - redhat-operator-index:v4.10 下的部分 operator
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.10
      full: true
      packages:
        - name: advanced-cluster-management
        - name: cluster-logging
        - name: elasticsearch-operator
        - name: kubernetes-nmstate-operator
        - name: kubevirt-hyperconverged
        - name: local-storage-operator
        - name: mcg-operator
        - name: ocs-operator
        - name: odf-operator
        - name: openshift-gitops-operator
        - name: rhacs-operator
        - name: performance-addon-operator
EOF

### 尝试同步 headsonly operator 方式
cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.10
EOF

同步 operator catalog index redhat-operator 到本地
$ /usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml --continue-on-error file://output-dir
Creating directory: output-dir/oc-mirror-workspace/src/publish
Creating directory: output-dir/oc-mirror-workspace/src/v2
Creating directory: output-dir/oc-mirror-workspace/src/charts
Creating directory: output-dir/oc-mirror-workspace/src/release-signatures
backend is not configured in /root/image-config-realse-local.yaml, using stateless mode
backend is not configured in /root/image-config-realse-local.yaml, using stateless mode
No metadata detected, creating new workspace
WARN[0145] DEPRECATION NOTICE:
Sqlite-based catalogs and their related subcommands are deprecated. Support for
them will be removed in a future release. Please migrate your catalog workflows
to the new file-based catalog format. 
wrote mirroring manifests to output-dir/oc-mirror-workspace/operators.1662343519/manifests-redhat-operator-index

To upload local images to a registry, run:

        oc adm catalog mirror file://redhat/redhat-operator-index:v4.10 REGISTRY/REPOSITORY


spec:
  additionalKernelArgs:
  - "idle=poll"
  - "rcupdate.rcu_normal_after_boot=0"
  - "efi=runtime"

### OCP 4.11
### 查看 cluster-node-tuning-operator 日志
$ oc -n openshift-cluster-node-tuning-operator logs $(oc -n openshift-cluster-node-tuning-operator get pods -l name=cluster-node-tuning-operator -o name)

### 尝试一下 OPM 同步 operator
$ opm index prune -f registry.redhat.io/redhat/redhat-operator-index:v4.10 -p kubevirt-hyperconverged,performance-addon-operator -t registry.example.com:5000/redhat/redhat-operator-index:v4.10 --skip-tls
WARN[0000] DEPRECATION NOTICE:
Sqlite-based catalogs and their related subcommands are deprecated. Support for
them will be removed in a future release. Please migrate your catalog workflows
to the new file-based catalog format.
WARN[0000] --skip-tls flag is set: this mode is insecure and meant for development purposes only.
INFO[0000] pruning the index                             packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0000] Pulling previous image registry.redhat.io/redhat/redhat-operator-index:v4.10 to get metadata  packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0000] running /usr/bin/podman pull --tls-verify=false registry.redhat.io/redhat/redhat-operator-index:v4.10  packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0007] running /usr/bin/podman pull --tls-verify=false registry.redhat.io/redhat/redhat-operator-index:v4.10  packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0011] Getting label data from previous image        packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0011] running podman inspect                        packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0011] running podman create                         packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0011] running podman cp                             packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0045] running podman rm                             packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0048] deleting packages                             pkg=3scale-operator
INFO[0048] packages: [3scale-operator]                   pkg=3scale-operator
...
INFO[0079] deleting packages                             pkg=windows-machine-config-operator
INFO[0079] packages: [windows-machine-config-operator]   pkg=windows-machine-config-operator
INFO[0079] Generating dockerfile                         packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0079] writing dockerfile: ./index.Dockerfile3975861442  packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0079] running podman build                          packages="[kubevirt-hyperconverged performance-addon-operator]"
INFO[0079] [podman build --format docker -f ./index.Dockerfile3975861442 -t registry.example.com:5000/redhat/redhat-operator-index:v4.10 .]  packages="[kubevirt-hyperconverged performance-addon-operator]"
# podman images
REPOSITORY                                                      TAG                                   IMAGE ID      CREATED        SIZE
registry.example.com:5000/redhat/redhat-operator-index          v4.10                                 6ad094adfe03  6 seconds ago  74 MB

cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.10
      packages:
        - name: kubevirt-hyperconverged
          channels:
            - name: 'stable'
              minVersion: '4.10.4'
              maxVersion: '4.10.4'            
        - name: performance-addon-operator
          channels:
            - name: '4.10'
              minVersion: '4.10.6'
              maxVersion: '4.10.6'
        - name: kubernetes-nmstate-operator
          channels:
            - name: 'stable'
              minVersion: '4.10.0-202208150436'
              maxVersion: '4.10.0-202208150436'
        - name: sriov-network-operator
          channels:
            - name: 'stable'
              minVersion: '4.10.0-202208150436'
              maxVersion: '4.10.0-202208150436'                                      
EOF
# 同步 operator catalog index redhat-operator 到本地
$ /usr/local/bin/oc-mirror --config /root/image-config-realse-local.yaml --continue-on-error file://output-dir

# 拷贝 output-dir/oc-mirror.tar.gz 到离线环境
# 上传镜像
$ /usr/local/bin/oc-mirror --from /tmp/mirror_seq1_000000.tar docker://registry.example.com:5000

# 设置禁用默认 OperatorHub Sources
$ oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

# 设置 CatalogSource 和 ImageContentSourcePolicy
$ pwd
$ /root/oc-mirror-workspace/results-1662455093
cat catalogSource-redhat-operator-index.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operator-index
  namespace: openshift-marketplace
spec:
  image: registry.example.com:5000/redhat/redhat-operator-index:v4.10
  sourceType: grpc
$ oc apply -f catalogSource-redhat-operator-index.yaml

$ cat imageContentSourcePolicy.yaml 
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  labels:
    operators.openshift.org/catalog: "true"
  name: operator-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:5000/container-native-virtualization
    source: registry.redhat.io/container-native-virtualization
  - mirrors:
    - registry.example.com:5000/openshift4
    source: registry.redhat.io/openshift4
  - mirrors:
    - registry.example.com:5000/redhat
    source: registry.redhat.io/redhat

$ oc apply -f imageContentSourcePolicy.yaml

### 拷贝虚拟机磁盘到离线环境
$ mkdir -p /tmp/skopeotest 
$ skopeo copy --format v2s2 --authfile /path/auth.json --all docker://quay.io/jordigilh/rhel8-rt:qcow2 dir:/tmp/skopeotest 
### 将 /tmp/skopeotest 拷贝到离线
$ skopeo copy --format v2s2 --authfile /path/auth.json --all dir:/tmp/skopeotest docker://registry.example.com:5000/jordigilh/rhel8-rt:qcow2

### expose vm ssh port
$ virtctl expose vmi vm-realtime --port=22 --name=vm-realtime-ssh --type=NodePort

### Test Command
nohup taskset -c 1,2,3 cyclictest --priority 1 --policy fifo -h 10 -a 1,2,3 --mainaffinity 0 -t 3 -m -q -i 200 -D 4h &
nohup taskset -c 1,2,3 rt-tests/oslat --cpu-list 1,2,3 --rtprio 1 -D 1h -w memmove -m 4K &
nohup hwlatdetect --threshold=1us --duration=1h

### OCP QEMU DISK
qemu-img create -f qcow2 -o preallocation=metadata /data/kvm/jwang-ocp452-worker0-disk1.qcow2 10G 
qemu-img create -f qcow2 -o preallocation=metadata /data/kvm/jwang-ocp452-worker1-disk1.qcow2 10G 
qemu-img create -f qcow2 -o preallocation=metadata /data/kvm/jwang-ocp452-worker2-disk1.qcow2 10G 

virsh attach-disk jwang-ocp452-worker0 /data/kvm/jwang-ocp452-worker0-disk1.qcow2 vdb --live
virsh attach-disk jwang-ocp452-worker0 /data/kvm/jwang-ocp452-worker0-disk1.qcow2 vdb --config

virsh attach-disk jwang-ocp452-worker1 /data/kvm/jwang-ocp452-worker1-disk1.qcow2 vdb --live
virsh attach-disk jwang-ocp452-worker1 /data/kvm/jwang-ocp452-worker1-disk1.qcow2 vdb --config

virsh attach-disk jwang-ocp452-worker2 /data/kvm/jwang-ocp452-worker2-disk1.qcow2 vdb --config

```

### 删除节点
https://access.redhat.com/documentation/en-us/openshift_container_platform/4.6/html/nodes/working-with-nodes#nodes-nodes-working-deleting_nodes-nodes-working
```
$ oc adm cordon worker-2.ocp4-1.example.com
$ oc adm drain worker-2.ocp4-1.example.com --force=true

# 检查 openshift update graph
https://cloud.redhat.com/blog/mirroring-openshift-registries-the-easy-way

### offline mirroring comparison
https://midu16.github.io/openshift4/2022/08/24/offline-mirroring-comparison.html
```

### 学习学习 ACM ApplicationSets - OpenShift GitOps
https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.5/html-single/applications/index#applicationset
```
### 它是如何工作的
```

### 查看 OpenShift GitOps 日志
```
# 安装 OpenShift-GitOps 会自动在 openshift-gitops namespace 下创建 ArgoCD instance 
# 用户无需创建 ArgoCD

# 查看 app.kubernetes.io/name='cluster' 的日志
$ oc -n openshift-gitops logs $(oc -n openshift-gitops get pods -l app.kubernetes.io/name='cluster' -o name)

# 看看 applicationset 的日志
$ oc -n openshift-gitops logs $(oc -n openshift-gitops get pods -l app.kubernetes.io/name='openshift-gitops-applicationset-controller' -o name)

# 看看 application 的日志
$ oc -n openshift-gitops logs $(oc -n openshift-gitops get pods -l app.kubernetes.io/name='openshift-gitops-application-controller' -o name)

# 看看 openshift-gitops-server 的日志
$ oc -n openshift-gitops logs $(oc -n openshift-gitops get pods -l app.kubernetes.io/name='openshift-gitops-server' -o name)

# 看看 dex-server 的日志
$ oc -n openshift-gitops logs $(oc -n openshift-gitops get pods -l app.kubernetes.io/name='openshift-gitops-dex-server' -o name)


$ oc get applicationset argo-acm-applicationset-1 -n openshift-gitops -o yaml
报错
...
status:
  conditions:
  - lastTransitionTime: "2022-09-19T08:04:05Z"
    message: 'application spec is invalid: InvalidSpecError: spec.source.repoURL and
      spec.source.path either spec.source.chart are required (and 1 more)'
    reason: ApplicationValidationError
    status: "True"
    type: ErrorOccurred

status:
  conditions:
  - lastTransitionTime: "2022-09-19T08:06:07Z"
    message: Successfully generated parameters for all Applications
    reason: ApplicationSetUpToDate
    status: "False"
    type: ErrorOccurred

# 测试一下创建一个 使用 generators clusters 的 ApplicationSet
# https://www.padok.fr/en/blog/introduction-argocd-applicationset
# 这个链接描述了如何为 Cluster Secret 添加 label
# matchLabels 是 Match Cluster Secret 的 label
# 观察到 cluster-secret 这个 secret 上的 label 会自动消失
# 因此 generator - clusters 不是一个稳定可靠的 generator
cat <<EOF | oc apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: argo-acm-applicationset-1
  namespace: openshift-gitops
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          gitops: test
  template:
    metadata:
      name: 'argo-acm-applicationset-1-{{name}}'
    spec:
      destination:
        namespace: wordpress
        server: '{{server}}'
      project: default
      source:
        path: apps
        repoURL: https://github.com/wangjun1974/gitops-wordpress
        targetRevision: main
      syncPolicy:
        automated:
          allowEmpty: true
          prune: true
          selfHeal: true
        syncOptions:
        - PruneLast=true
        - CreateNamespace=true
EOF

# 可以用 'clusterDicisionResource' generator
# Placement 用 cluster 是否有特定 label 来确定
# 这种用法不需要给 xxx-cluster-secret 打特定 label
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1alpha1
kind: Placement
metadata:
  name: argo-acm-applicationset-1-placement
  namespace: openshift-gitops
spec:
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchLabels:
          gitops: test
EOF

cat <<EOF | oc apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: argo-acm-applicationset-1
  namespace: openshift-gitops
spec:
  generators:
    - clusterDecisionResource:
        configMapRef: acm-placement
        labelSelector:
          matchLabels:
            cluster.open-cluster-management.io/placement: argo-acm-applicationset-1-placement
        requeueAfterSeconds: 180
  template:
    metadata:
      name: 'argo-acm-applicationset-1-{{name}}'
    spec:
      destination:
        namespace: wordpress
        server: '{{server}}'
      project: default
      source:
        path: apps
        repoURL: 'https://github.com/wangjun1974/gitops-wordpress'
        targetRevision: main
      syncPolicy:
        automated:
          allowEmpty: true
          prune: true
          selfHeal: true
        syncOptions:
          - PruneLast=true
          - Replace=true
          - CreateNamespace=true
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
data:
  config: ewogICJiZWFyZXJUb2tlbiI6ICJleUpoYkdjaU9pSlNVekkxTmlJc0ltdHBaQ0k2SWt0WlYwbExSbGhmZEZCYVpra3pOR05HWjBwNk4yRTNUMXBSUjJzdFJtRnRjblY0VlY5U2RHNDVlbmNpZlEuZXlKcGMzTWlPaUpyZFdKbGNtNWxkR1Z6TDNObGNuWnBZMlZoWTJOdmRXNTBJaXdpYTNWaVpYSnVaWFJsY3k1cGJ5OXpaWEoyYVdObFlXTmpiM1Z1ZEM5dVlXMWxjM0JoWTJVaU9pSnZjR1Z1TFdOc2RYTjBaWEl0YldGdVlXZGxiV1Z1ZEMxaFoyVnVkQzFoWkdSdmJpSXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWamNtVjBMbTVoYldVaU9pSnJiSFZ6ZEdWeWJHVjBMV0ZrWkc5dUxXRndjRzFuY2kxMGIydGxiaTFuTW14a2JDSXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMbTVoYldVaU9pSnJiSFZ6ZEdWeWJHVjBMV0ZrWkc5dUxXRndjRzFuY2lJc0ltdDFZbVZ5Ym1WMFpYTXVhVzh2YzJWeWRtbGpaV0ZqWTI5MWJuUXZjMlZ5ZG1salpTMWhZMk52ZFc1MExuVnBaQ0k2SW1VM1pqSmhZVE5tTFRrNU9HRXROREl6TUMxaE1tSXdMVGcxWlROa05qQmhORGt5TlNJc0luTjFZaUk2SW5ONWMzUmxiVHB6WlhKMmFXTmxZV05qYjNWdWREcHZjR1Z1TFdOc2RYTjBaWEl0YldGdVlXZGxiV1Z1ZEMxaFoyVnVkQzFoWkdSdmJqcHJiSFZ6ZEdWeWJHVjBMV0ZrWkc5dUxXRndjRzFuY2lKOS5LUk1yaXE0dy1DQkxDRDZ1MFdQSkk5SXZCeHJiYnUybFRjQ2VPLURoUDZmWk9wWGhmb2dDNk9iQW8zLW5fWmg1V2xLNzROQVB1UWJYXzZnVDZlQTdjTEhZaXZ2RUhNZXJudkFkVzJDQkJmZ1k2c3ozY19EMDQxN2hicGpiZ1Z0M3BFVGJLTlNPa0VERm1SMzg2WW1PcjB6TzZyZmJhcmtPbkFLSE84RFJBLVZRNjdMYWpubjM1OTU3N2RzUXJ4NEpWcjhZaWFJSUxWeEctOUJ3QjlnMnh2bnFGa0JEUGw4eHB0b3RwU0hjNm11QnRYLTFDSnV2VU9udmdUMDBIT2Rybkxvblhad0ViQ1hvX0hqUGc4eDJtUlpZaDJIWEMxWmNQb2hOTWdJZTQ2Z3ZhUjJ3eFJvWF9TRVFfRzhRUV9rel9WTDhuV2hoM3Fvb002SHdMT3RFLWciLAogICJ0bHNDbGllbnRDb25maWciOiB7CiAgICAiaW5zZWN1cmUiOiB0cnVlCiAgfQp9
  name: ZWRnZS0y
  server: aHR0cHM6Ly81NC42Ny41Ny4xMDA6NjQ0Mwo=
kind: Secret
metadata:
  labels:
    argocd.argoproj.io/secret-type: cluster
  name: edge-2-cluster-secret
  namespace: openshift-gitops
type: Opaque
EOF

# 当创建资源时，如果 CRD 未就绪，可以考虑添加 annotation: SkipDryRunOnMissingResource=true
# argocd sync options annotation 
# https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/#skip-dry-run-for-new-custom-resources-types
    argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true

```

### 查看 pid 的 processor 来确定是否在 reserved 或者 isolated 的 cpu 列表内
```
  cpu:
    isolated: "2-19,22-39,42-59,62-79"
    reserved: "0,1,40,41,20,21,60,61"
[core@worker-3 ~]$ pidof kubelet
8445
[core@worker-3 ~]$ ps -o pid,psr,comm -p 8445
    PID PSR COMMAND
   8445  61 kubelet
[core@worker-3 ~]$ pidof systemd
74891 1
[core@worker-3 ~]$ ps -o pid,psr,comm -p 74891
    PID PSR COMMAND
  74891  21 systemd
[core@worker-3 ~]$ ps -o pid,psr,comm -p 1    
    PID PSR COMMAND
      1  21 systemd
[core@worker-3 ~]$ pidof crio
8285
[core@worker-3 ~]$ ps -o pid,psr,comm -p 8285
    PID PSR COMMAND
   8285  60 crio
```

### ArgoCD 自己添加 Cluster Secret 
```
https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters
### 检查 ocm-proxyserver 的日志
$ oc -n open-cluster-management logs $(oc -n open-cluster-management get pods -l app=ocm-proxyserver -o name | head -1)  
$ oc -n open-cluster-management logs $(oc -n open-cluster-management get pods -l app=ocm-proxyserver -o name | tail -1)  
```

### 为 SNO添加 kubevirt-hostpath-provisioner
```
### https://raw.githubusercontent.com/kubevirt/hostpath-provisioner/main/deploy/kubevirt-hostpath-provisioner.yaml

oc apply -f https://raw.githubusercontent.com/kubevirt/hostpath-provisioner/main/deploy/kubevirt-hostpath-provisioner.yaml

$ oc project kubevirt-hostpath-provisioner
$ oc adm policy add-scc-to-user privileged -z kubevirt-hostpath-provisioner-admin
$ oc patch daemonset/kubevirt-hostpath-provisioner --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"

# 查看 kubevirt-hostpath-provisioner 日志
$ oc -n kubevirt-hostpath-provisioner logs $(oc -n kubevirt-hostpath-provisioner get pods -l k8s-app=kubevirt-hostpath-provisioner -o name)

# set default storage class 
$ oc patch storageclass kubevirt-hostpath-provisioner -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'

cat <<EOF | oc delete -f -
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  name: observability
spec:
  enableDownsampling: true
  observabilityAddonSpec:
    enableMetrics: true
    interval: 600
  storageConfig:
    alertmanagerStorageSize: 1Gi
    compactStorageSize: 5Gi
    metricObjectStorage:
      key: thanos.yaml
      name: thanos-object-storage
    receiveStorageSize: 5Gi
    ruleStorageSize: 1Gi
    storageClass: kubevirt-hostpath-provisioner
    storeStorageSize: 5Gi
EOF

# 报错
0s          Normal    ExternalProvisioning   persistentvolumeclaim/data-observability-thanos-store-shard-1-0      waiting for a volume to be created, either by external provisioner "kubevirt.io/hostpath-provisioner" or manually created by system administrator

# 检查 FeatureGate
# https://docs.okd.io/4.11/nodes/clusters/nodes-cluster-enabling-features.html
oc debug node/<node>
chroot /host
cat /etc/kubernetes/kubelet.conf
...

### 安装 SNO 用的 LVM Operator
https://wangzheng422.github.io/docker_env/ocp4/4.10/4.10.sno.nfs.lvm.html
https://blog.kintone.io/entry/topolvm


### Firefox 使用更早的 TLS 
https://support.mozilla.org/de/questions/1116550
security.tls.version.enable-deprecated: true
security.tls.version.min: 1

### 创建使用本地盘 LVM 的 StorageClass
# https://wangzheng422.github.io/docker_env/ocp4/4.10/4.10.sno.nfs.lvm.html
# https://blog.kintone.io/entry/topolvm
qemu-img create -f qcow2 -o preallocation=metadata /data/kvm/jwang-ocp452-master0-disk1.qcow2 100G 

# 无需执行
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:openshift-storage:topolvm-controller -n openshift-storage
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:openshift-storage:vg-manager -n openshift-storage
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:openshift-storage:topolvm-node -n openshift-storage

# 设置默认 storageclass
oc patch storageclass odf-lvm-vg1 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### 离线 Gitea
```
列出 gitea catalog 内容
$ /usr/local/bin/oc-mirror list operators --catalog=quay.io/gpte-devops-automation/gitea-catalog:latest --package=gitea-operator
NAME            DISPLAY NAME    DEFAULT CHANNEL
gitea-operator  Gitea Operator  stable

PACKAGE         CHANNEL  HEAD
gitea-operator  stable   gitea-operator.v1.3.0

OPERATOR_NAME='gitea-operator'
OPERATOR_VERSION='v1.3.0'
OPERATOR_CHANNEL='stable'

/usr/local/bin/oc-mirror list operator --catalog=quay.io/gpte-devops-automation/gitea-catalog:latest --package=${OPERATOR_NAME}

cat > image-config-realse-local.yaml <<EOF
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
mirror:
  operators:
    - catalog: quay.io/gpte-devops-automation/gitea-catalog:latest
      packages:
        - name: ${OPERATOR_NAME}
          channels:
            - name: ${OPERATOR_CHANNEL}
              minVersion: ${OPERATOR_VERSION}
              maxVersion: ${OPERATOR_VERSION}          
EOF

/usr/local/bin/oc-mirror --config ./image-config-realse-local.yaml file://output-dir
mv output-dir/mirror_seq1_000000.tar output-dir/gitea-catalog_latest_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar 
BaiduPCS-Go upload output-dir/gitea-catalog_latest_${OPERATOR_NAME}_${OPERATOR_VERSION}.tar /ocp4/oc-mirror/operator

# 添加 catalogsources gitea-catalog
# 由于 gitea operator 没有使用 digestonly 的镜像，oc-mirror 生成的 imagecontentsourcepolicy 并不能满足 Gitea Operator 运行
# 解决方法是用 skopeo copy docker:// dir:// ; skopeo copy dir:// docker:// 的方法同步镜像
# 然后根据以下 KB 来生成 MachineConfig 生成 /etc/containers/registries.conf.d/99-${noderole}-mirror-by-digest-registries.conf 文件
# https://access.redhat.com/solutions/4817401 
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: gitea-catalog
  namespace: openshift-marketplace
spec:
  image: registry.example.com:5000/gpte-devops-automation/gitea-catalog:latest
  sourceType: grpc
EOF


mkdir -p /tmp/gitea
skopeo copy --format v2s2 --all docker://registry.redhat.io/openshift4/ose-kube-rbac-proxy:v4.7.0 dir:/tmp/gitea/ose-kube-rbac-proxy
skopeo copy --format v2s2 --all docker://quay.io/gpte-devops-automation/gitea-operator:v1.3.0 dir:/tmp/gitea/gitea-operator
skopeo copy --format v2s2 --all docker://registry.redhat.io/rhel8/postgresql-12:latest dir:/tmp/gitea/postgresql-12
skopeo copy --format v2s2 --all docker://quay.io/gpte-devops-automation/gitea:latest dir:/tmp/gitea/gitea

tar cf /tmp/gitea-operator.tar /tmp/gitea
scp /tmp/gitea-operator.tar <dest>:/tmp
tar xf /tmp/gitea-operator.tar -C /

skopeo copy --format v2s2 --all dir:/tmp/gitea/ose-kube-rbac-proxy docker://registry.example.com:5000/openshift4/ose-kube-rbac-proxy:v4.7.0
skopeo copy --format v2s2 --all dir:/tmp/gitea/gitea-operator docker://registry.example.com:5000/gpte-devops-automation/gitea-operator:v1.3.0
skopeo copy --format v2s2 --all dir:/tmp/gitea/postgresql-12 docker://registry.example.com:5000/rhel8/postgresql-12:latest
skopeo copy --format v2s2 --all dir:/tmp/gitea/gitea docker://registry.example.com:5000/gpte-devops-automation/gitea:latest


cd /tmp
cat > my_registry.conf <<EOF
[[registry]]
  prefix = ""
  location = "quay.io/gpte-devops-automation"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/gpte-devops-automation"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/openshift4"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/openshift4"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhel8"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/rhel8"
EOF

cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-mirror-by-digest-registries
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(base64 -w0 my_registry.conf)
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf.d/99-master-mirror-by-digest-registries.conf
EOF

# 创建 Gitea 实例
cat <<EOF | oc apply -f -
apiVersion: gpte.opentlc.com/v1
kind: Gitea
metadata:
  name: gitea-with-admin
spec:
  giteaSsl: true
  giteaAdminUser: opentlc-mgr
  giteaAdminPassword: ""
  giteaAdminPasswordLength: 32
  giteaAdminEmail: opentlc-mgr@redhat.com
  giteaCreateUsers: true
  giteaGenerateUserFormat: "lab-user-%d"
  giteaUserNumber: 2
  giteaUserPassword: openshift
  giteaMigrateRepositories: false
EOF

# 查看 Gitea 日志
oc -n openshift-operators logs $(oc -n openshift-operators get pods -l control-plane=controller-manager -o name | grep gitea) -c manager 

# 克隆
git clone https://github.com/wangjun1974/book-import  

# 传输 book-import 到离线环境
# 进入到 book-import 目录

# git remote add neworigin https://gitea-with-admin-gitea.apps.ocp4-1.example.com/lab-user-2/book-import.git

# 处理一下证书
cd /tmp
openssl s_client -host gitea-with-admin-gitea.apps.ocp4-1.example.com -port 443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /etc/pki/ca-trust/source/anchors/gitea.crt  
update-ca-trust
cd -

# 将 repo 从文件系统同步到 gitea
# git push neworigin --all
# git push neworigin --tags

# 拷贝 quay.io/jpacker/hugo-nginx:latest 镜像
mkdir -p /tmp/book-import
skopeo copy --format v2s2 --all docker://quay.io/jpacker/hugo-nginx:latest dir:/tmp/book-import/hugo-nginx

tar cf /tmp/book-import.tar /tmp/book-import
scp /tmp/book-import.tar <dest>:/tmp
tar xf /tmp/book-import.tar -C /

skopeo copy --format v2s2 --all dir:/tmp/book-import/hugo-nginx docker://registry.example.com:5000/jpacker/hugo-nginx:latest

# 更新 /etc/containers/registries.conf.d/99-master-mirror-by-digest-registries.conf
cd /tmp
cat > my_registry.conf <<EOF
[[registry]]
  prefix = ""
  location = "quay.io/gpte-devops-automation"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/gpte-devops-automation"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/openshift4"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/openshift4"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhel8"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/rhel8"

[[registry]]
  prefix = ""
  location = "quay.io/jpacker"
  mirror-by-digest-only = false

  [[registry.mirror]]
    location = "registry.example.com:5000/jpacker"
EOF

cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-mirror-by-digest-registries
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(base64 -w0 my_registry.conf)
        filesystem: root
        mode: 420
        path: /etc/containers/registries.conf.d/99-master-mirror-by-digest-registries.conf
EOF
```

### ACM ApplicationSet Test
```
# 在 ACM 里创建 ManagedClusterSet 和 ManagedClusterSetBinding

# 为 ManagedCluster 添加 label 
argo=test

# 设置 Placement CRDs，ManagedClusterSet 选择 Cluster时 只选择 argo 是 test 的 Cluster
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1alpha1
kind: Placement
metadata:
  name: gitops-openshift-clusters
  namespace: openshift-gitops
spec:
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchExpressions:
        - key: argo
          operator: "In"
          values:
          - test
EOF

# 创建 GitOpsCluster
# argoServer 的 cluster 是登陆 openshift-gitops server 查看 cluster 获得的
cat << EOF | oc apply -f -
apiVersion: apps.open-cluster-management.io/v1beta1
kind: GitOpsCluster
metadata:
  name: argo-acm-clusters
  namespace: openshift-gitops
spec:
  argoServer:
    cluster: in-cluster
    argoNamespace: openshift-gitops
  placementRef:
    kind: Placement
    apiVersion: cluster.open-cluster-management.io/v1alpha1
    name: gitops-openshift-clusters
    namespace: openshift-gitops
EOF

# 登陆 argo UI 选择 Settings - Certificates - ADD TLS CERTIFICATE 添加 gitea-with-admin-gitea.apps.ocp4-1.example.com 的 TLS CERTIFICATE

# 在 ACM 上创建 ApplicationSet 类型的 Application
```

### 生成带 subjectAltName SAN 的证书
```
openssl req -newkey rsa:4096 -nodes -sha256 -keyout ${REGISTRY_PATH}/certs/registry.key -x509 -days 3650 \
  -out ${REGISTRY_PATH}/certs/registry.crt -addext "subjectAltName = DNS:registry.example.com" \
  -subj "/C=CN/ST=BEIJING/L=BJ/O=REDHAT/OU=IT/CN=registry.${DOMAIN}/emailAddress=admin@${DOMAIN}"
```

### 查看日志
```
oc -n open-cluster-management logs $(oc get pods -n open-cluster-management -l name=multiclusterhub-operator -o name)

oc -n open-cluster-management-agent-addon logs $(oc -n open-cluster-management-agent-addon get pods -l app=application-manager -o name) 
```

### 创建 snapshot
```
# 创建 snapshot
virsh shutdown --domain jwang-edge1
virsh snapshot-create-as --domain jwang-edge1 \
--name "20221011" \
--description "Snapshot before add microshift into ACM"

# 查看 snapshot
virsh snapshot-list --domain jwang-edge1
virsh snapshot-info --domain jwang-edge1 --snapshotname 20221011

# 恢复 snapshot
virsh snapshot-revert --domain jwang-edge1 --snapshotname 20221011 --running
```

### bind dns forwarder 不工作时的处理 
```
### 编辑 /etc/named.conf
### 设置 dnssec-validation no;
```

### 为 namespace 打 label 来绕过 pod security rule
https://bugzilla.redhat.com/show_bug.cgi?id=2124593
```
### label the namespace as a temp workaround to the pod security rule eforcement (see: https://bugzilla.redhat.com/show_bug.cgi?id=2124593)
oc  label --overwrite ns openshift-local-storage   pod-security.kubernetes.io/enforce=privileged   pod-security.kubernetes.io/warn=baseline   pod-security.kubernetes.io/audit=baseline
oc  label --overwrite ns openshift-storage   pod-security.kubernetes.io/enforce=privileged   pod-security.kubernetes.io/warn=baseline   pod-security.kubernetes.io/audit=baseline
```

### 拷贝 image-registry 镜像
```
# 生成 default-route-openshift-image-registry 的 podman 证书
mkdir -p /etc/containers/certs.d/default-route-openshift-image-registry.apps.ocp4.rhcnsa.com
cd /etc/containers/certs.d/default-route-openshift-image-registry.apps.ocp4.rhcnsa.com
openssl s_client -host default-route-openshift-image-registry.apps.ocp4.rhcnsa.com -port 443 -showcerts > /tmp/trace < /dev/null
cat /tmp/trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee ca.crt  

# 登录 ocp 集群
oc login https://api.ocp4.rhcnsa.com:6443 -u kubeadmin

# podman login openshift-image-registry
podman login default-route-openshift-image-registry.apps.ocp4.rhcnsa.com -u kubeadmin -p $(oc whoami -t) 

# 拉取 default-route-openshift-image-registry.apps.ocp4.rhcnsa.com/iotdemo/iot-software-sensor:latest 镜像
podman pull default-route-openshift-image-registry.apps.ocp4.rhcnsa.com/iotdemo/iot-software-sensor:latest 



---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    name: machine-sensor
  name: machine-sensor
spec:
  replicas: 1
  selector:
    matchLabels:
      name: machine-sensor
  template:
    metadata:
      labels:
        name: machine-sensor
    spec:
      containers:

      - image: quay.ocp4.rhcnsa.com/microshift/iotdemo/iot-software-sensor:latest
        name: machine-sensor
        ports:
        - containerPort: 8778
          name: jolokia
          protocol: TCP
        - containerPort: 8080
          name: http
          protocol: TCP
        - containerPort: 8443
          name: https
          protocol: TCP
---


apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    name: book-import
  name: book-import
spec:
  replicas: 2
  selector:
    matchLabels:
      name: book-import
  template:
    metadata:
      labels:
        name: book-import
    spec:
      containers:
      - image: quay.ocp4.rhcnsa.com/jpacker/hugo-nginx:latest
        name: book-import
        ports:
        - containerPort: 8080
          name: http-server
···

Ansible AutoMation Controller 日志
ocp4 -n ansible-automation-platform logs $(ocp4 -n ansible-automation-platform get pods -l app.kubernetes.io/component=automationcontroller -l app.kubernetes.io/name=example -o name) -c example-web

ocp4 -n ansible-automation-platform logs $(ocp4 -n ansible-automation-platform get pods -l app.kubernetes.io/component=automationcontroller -l app.kubernetes.io/name=example -o name) -c example-ee

ocp4 -n ansible-automation-platform logs $(ocp4 -n ansible-automation-platform get pods -l app.kubernetes.io/component=automationcontroller -l app.kubernetes.io/name=example -o name) -c example-task

ocp4 -n ansible-automation-platform logs $(ocp4 -n ansible-automation-platform get pods -l app.kubernetes.io/component=automationcontroller -l app.kubernetes.io/name=example -o name) -c redis



```


### Ansible Tower 设置 Ignore SSL Verification - Git
https://www.techbeatly.com/connecting-ansible-tower-to-git-server-with-self-signed-certificates/
```
Settings -> Jobs -> EXTRA ENVIRONMENT VARIABLES
{
  "GIT_SSL_NO_VERIFY": "True"
}
```

### 如何查看 Hub Subscription 日志
```
# 在 Hub 上可以检查日志，查看是否生成 AnsibleJob
$ oc -n open-cluster-management logs $(oc -n open-cluster-management get pods -l app=multicluster-operators-hub-subscription -o name)
```

### 检查 kube-apiserver-last-known-good static pod
https://bugzilla.redhat.com/show_bug.cgi?id=1985997
```
#!/usr/bin/env bash
while true
do oc get co/kube-apiserver;oc get kubeapiserver -oyaml | grep -A15 'latestAvailableRevision';sleep 30
done


[root@support ~]# oc get co/kube-apiserver;oc get kubeapiserver -oyaml | grep -A15 'latestAvailableRevision'
NAME             VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
kube-apiserver   4.10.31   True        False         True       42d     StaticPodFallbackRevisionDegraded: a static pod kube-apiserver-master-0.ocp4-1.example.com was rolled back to revision 18 due to waiting for kube-apiserver static pod to listen on port 6443: Get "https://localhost:6443/healthz/etcd": dial tcp [::1]:6443: connect: connection refused
    latestAvailableRevision: 18
    latestAvailableRevisionReason: ""
    nodeStatuses:
    - currentRevision: 18
      lastFailedCount: 1
      lastFailedReason: OperandFailedFallback
      lastFailedRevision: 18
      lastFailedRevisionErrors:
      - 'fallback to last-known-good revision 17 took place after: waiting for kube-apiserver
        static pod to listen on port 6443: Get "https://localhost:6443/healthz/etcd":
        dial tcp [::1]:6443: connect: connection refused (NetworkError)'
      lastFailedTime: "2022-10-27T00:48:08Z"
      lastFallbackCount: 1
      nodeName: master-0.ocp4-1.example.com
    readyReplicas: 0
kind: List
metadata:

[root@master-0 /]# ls -l /etc/kubernetes/static-pod-resources/kube-apiserver-last-known-good 
lrwxrwxrwx. 1 root root 82 Oct 27 01:10 /etc/kubernetes/static-pod-resources/kube-apiserver-last-known-good -> /etc/kubernetes/static-pod-resources/kube-apiserver-pod-18/kube-apiserver-pod.yaml

oc --kubeconfig=/etc/kubernetes/static-pod-resources/configmaps/kube-apiserver-cert-syncer-kubeconfig/kubeconfig get co cluster

/usr/bin/hyperkube kube-apiserver --openshift-config=/etc/kubernetes/static-pod-resources/configmaps/config/config.yaml --advertise-address=192.168.122.101 -v=2 --permit-address-sharing
```

### 创建 ingressController 
```

### zone0 里包含两台 worker 节点
$ oc get nodes
NAME                          STATUS   ROLES           AGE     VERSION
master-0.ocp4-1.example.com   Ready    master,worker   44d     v1.23.5+012e945
worker-0.zone0.example.com    Ready    worker          23m     v1.23.5+012e945
worker-1.zone0.example.com    Ready    worker          7m20s   v1.23.5+012e945

### 为 zone0 节点打标签
$ oc label node worker-0.zone0.example.com zone="zone0"
$ oc label node worker-1.zone0.example.com zone="zone0"

$ oc get nodes --show-labels 
NAME                          STATUS   ROLES           AGE   VERSION           LABELS
master-0.ocp4-1.example.com   Ready    master,worker   44d   v1.23.5+012e945   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=master-0.ocp4-1.example.com,kubernetes.io/os=linux,node-role.kubernetes.io/master=,node-role.kubernetes.io/worker=,node.openshift.io/os_id=rhcos,topology.topolvm.cybozu.com/node=master-0.ocp4-1.example.com
worker-0.zone0.example.com    Ready    worker          28m   v1.23.5+012e945   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker-0.zone0.example.com,kubernetes.io/os=linux,node-role.kubernetes.io/worker=,node.openshift.io/os_id=rhcos,topology.topolvm.cybozu.com/node=worker-0.zone0.example.com,zone=zone0
worker-1.zone0.example.com    Ready    worker          12m   v1.23.5+012e945   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker-1.zone0.example.com,kubernetes.io/os=linux,node-role.kubernetes.io/worker=,node.openshift.io/os_id=rhcos,topology.topolvm.cybozu.com/node=worker-1.zone0.example.com,zone=zone0

### 编辑 default ingresscontroller
  namespaceSelector:
    matchExpressions:
    - key: type
      operator: DoesNotExist

### 创建 zone0 的 ingressController
### https://rcarrata.com/openshift/ocp4_route_sharding/
$ cat <<EOF | oc apply -f -
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: zone0-ingress-controller
  namespace: openshift-ingress-operator
spec:
  replicas: 1
  domain: apps.zone0.example.com
  nodePlacement:
    nodeSelector:
      matchLabels:
        zone: zone0
    tolerations:
      - key: node.kubernetes.io/not-ready
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 259200
      - key: node.kubernetes.io/unreachable
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 259200
      - key: node.kubernetes.io/disk-pressure
        operator: Exists
        effect: NoSchedule
      - key: node.kubernetes.io/memory-pressure
        operator: Exists
        effect: NoSchedule
      - key: node.kubernetes.io/pid-pressure
        operator: Exists
        effect: NoSchedule
      - key: node.kubernetes.io/unschedulable
        operator: Exists
        effect: NoSchedule    
  namespaceSelector:
    matchLabels:
      type: zone0
EOF

### nfs server 
### exports
$ echo "
/srv/nfs-storage-pv-infra-registry 192.168.122.0/24(rw,sync,no_root_squash)
/srv/nfs-storage-pv-user-pvs 192.168.122.0/24(rw,sync,no_root_squash)
" >> /etc/exports

### nfs
https://examples.openshift.pub/cluster-configuration/storage/nfs/

$ oc new-project nfs-provisioner

### nfs-provisioner-rbac
cat > /usr/local/src/nfs-provisioner-rbac.yaml <<'EOF'
kind: ServiceAccount
apiVersion: v1
metadata:
  name: nfs-client-provisioner
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: nfs-provisioner
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: nfs-provisioner
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
EOF

oc adm policy add-scc-to-user privileged -z nfs-client-provisioner

cat > /usr/local/src/nfs-provisioner-deployment.yaml <<'EOF'
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-client-provisioner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-client-provisioner
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      nodeSelector:
        zone: zone0
      tolerations:
        - key: node.kubernetes.io/not-ready
          operator: Exists
          effect: NoExecute
          tolerationSeconds: 259200
        - key: node.kubernetes.io/unreachable
          operator: Exists
          effect: NoExecute
          tolerationSeconds: 259200
        - key: node.kubernetes.io/disk-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/memory-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/pid-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/unschedulable
          operator: Exists
          effect: NoSchedule
      containers:
        - name: nfs-client-provisioner
          image: registry.example.com:5000/sig-storage/nfs-subdir-external-provisioner:v4.0.0
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: nfs-storage
            - name: NFS_SERVER
              value: nfs.example.com
            - name: NFS_PATH
              value: /srv/nfs-storage-pv-user-pvs
      volumes:
        - name: nfs-client-root
          nfs:
            server: nfs.example.com
            path: /srv/nfs-storage-pv-user-pvs
EOF

### nfs 
### nfs-provisioner-sc
cat > /usr/local/src/nfs-provisioner-sc.yaml <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage-provisioner
provisioner: nfs-storage
parameters:
  archiveOnDelete: "false"
EOF


$ oc new-project wordpress
$ oc label namespace wordpress type="zone0"
$ oc apply -k .

$ virsh domiflist jwang-ocp452-master0 
Interface  Type       Source     Model       MAC
-------------------------------------------------------
vnet2      network    default    virtio      52:54:00:1c:14:57

$ virsh domiflist jwang-ocp452-worker0 
Interface  Type       Source     Model       MAC
-------------------------------------------------------
vnet4      network    default    virtio      52:54:00:7d:3e:08

$ virsh domiflist jwang-ocp452-worker1
Interface  Type       Source     Model       MAC
-------------------------------------------------------
vnet5      network    default    virtio      52:54:00:0d:cc:e6

# 在 worker-0 和 worker-1 上过滤掉的 LB 和 master 的流量
sudo iptables -I OUTPUT 1 -d 192.168.122.12/32 -j DROP
sudo iptables -I OUTPUT 1 -d 192.168.122.101/32 -j DROP

sudo crictl exec -it $(sudo crictl ps  | grep router | awk '{print $1}') /bin/sh
sudo crictl exec -it $(sudo crictl ps  | grep router | awk '{print $1}') cat /var/lib/haproxy/conf/haproxy.config | grep "server pod" 

# 查看 router 日志
$ sudo crictl logs $(sudo crictl ps  | grep router | awk '{print $1}') 


$ oc -n wordpress expose service wordpress --type=NodePort --name=wordpress-nodeport --generator="service/v2"

### 2 次 ssh 转发
ssh -i ~/.ssh/rht_classroom.rsa -J cloud-user@<public_ip>:22022 student@172.25.252.1 -p 53009

### kubelet 报错处理 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa\" found, but error not a directory occurred when trying to remove the volumes dir" numErrs=1

https://access.redhat.com/solutions/6964570
https://bugzilla.redhat.com/show_bug.cgi?id=1510167
POD_UUID=d8fd90e1-09b5-4ee1-b3b1-2c2eabe75895
ls /var/lib/kubelet/pods/${POD_UUID}/volumes/kubernetes.io~csi/pvc-bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
vol_data.json
rm -rf /var/lib/kubelet/pods/${POD_UUID}/volumes/kubernetes.io~csi/pvc-bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb

### 找到 vol_data.json
### 删除 vol_data.json 及目录
```

### 为 HPP 准备 Storage Class
https://docs.openshift.com/container-platform/4.10/virt/virtual_machines/virtual_disks/virt-configuring-local-storage-for-vms.html<br>
```
cat <<EOF | oc apply -f -
apiVersion: hostpathprovisioner.kubevirt.io/v1beta1
kind: HostPathProvisioner
metadata:
  name: hostpath-provisioner
spec:
  imagePullPolicy: IfNotPresent
  storagePools:
  - name: odf-lvm-vg1
    path: /var/hpvolumes
    pvcTemplate: 
      volumeMode: Block
      storageClassName: odf-lvm-vg1
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
  workload:
    nodeSelector:
      kubernetes.io/os: linux
EOF

cat <<EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: kubevirt-hostpath-provisioner
provisioner: kubevirt.io.hostpath-provisioner
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF

[root@support ~]# oc patch storageclass odf-lvm-vg1 -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
storageclass.storage.k8s.io/odf-lvm-vg1 patched
[root@support ~]# oc patch storageclass kubevirt-hostpath-provisioner -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
storageclass.storage.k8s.io/kubevirt-hostpath-provisioner patched

[root@support ~]# oc get sc 
NAME                                      PROVISIONER                        RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
kubevirt-hostpath-provisioner (default)   kubevirt.io/hostpath-provisioner   Delete          Immediate              false                  37s
odf-lvm-vg1                               topolvm.cybozu.com                 Delete          WaitForFirstConsumer   true                   24h

# 这个操作并不生效
oc patch cdi cdi-kubevirt-hyperconverged --patch '{"spec": {"config": {"insecureRegistries": ["registry.example.com:5000"]}}}' --type merge

# 生成 configmap my-registry-certs
oc create configmap my-registry-certs --from-file=/data/registry/certs/registry.crt

# 修改 template 的 spec.dataVolumeTemplates.spec.registry.pullMethod 为 node
# 基于这个 template 创建的虚拟机可以以 node 模式 pull vm 的 image
$ oc get template cirros cirros -o yaml
...
    spec:
      dataVolumeTemplates:
      - metadata:
          name: ${NAME}-rootdisk
          namespace: openshift-cnv
        spec:
          source:
            registry:
              pullMethod: node
              url: docker://registry.example.com:5000/kubevirt/cirros-registry-disk-demo:latest


```

### 上传镜像
```
[cnv-qe-jenkins@alex490-143-szbxl-executor imageupload-wffc-exits]$ virtctl image-upload dv cirros-dv --size=1Gi --image-path=./cirros.qcow2 --storage-class=hostpath-provisioner --access-mode=ReadWriteOnce --insecure

virtctl image-upload dv cirros-dv --size=1Gi --image-path=./cirros-0.4.0-x86_64-disk.img --storage-class=kubevirt-hostpath-provisioner --access-mode=ReadWriteOnce --insecure

kubectl port-forward -n cdi service/cdi-uploadproxy 18443:443
virtctl image-upload dv upload-dv --size=20Gi --uploadproxy-url=https://127.0.0.1:18443 --image-path=./ims.qcow2 --insecure

# demo vms
docker.io/kubevirt/cirros-registry-disk-demo:latest 
docker.io/kubevirt/fedora-cloud-registry-disk-demo:latest 

# 创建 nncp - sno
virsh net-update openshift4 add ip-dhcp-range "<range start='192.168.8.100' end='192.168.8.254'/>" --live --config

cat <<EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: master-0-bridge-policy 
spec:
  nodeSelector: 
    node-role.kubernetes.io/master: ''
  desiredState:
    interfaces:
      - name: br1
      # br1 is the name of the first available bridge interface 
        description: Linux bridge with ens10 as a port 
        type: linux-bridge
        state: up
        ipv4:
          dhcp: true
          enabled: true
        bridge:
          options:
            stp:
              enabled: false
          port:
            - name: ens10
            # ens10 is the name of the physical NIC on your node
EOF

cat << EOF | oc create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  annotations:
    description: net1
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br1
  name: net1
  namespace: openshift-cnv
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "net1", 
    "type": "cnv-bridge", 
    "bridge": "br1",
    "macspoofchk": false,
    "ipam": {}
  }'
EOF


```

### 启用 WebDAV 
https://access.redhat.com/articles/10636
```
$ mkdir -p /var/www/webdav
$ chown apache:apache /var/www/webdav
$ cat > /etc/httpd/conf.d/webdav.conf <<EOF
Alias /webdav /var/www/webdav
<Directory /var/www/webdav>
  Dav on
  Options +Indexes
  IndexOptions FancyIndexing
  Require all granted  
</Directory>
EOF
$ systemctl restart httpd
$ cadaver http://yum.example.com:8080/webdav
```

### 如何使用 k8s NetworkAttachmentDefinition
https://github.com/k8snetworkplumbingwg/k8s-net-attach-def-controller 
```
# 在 multus 的情况下，通过添加 NetworkAttachmentDefinition
# 并且让 Pod 引用 NetworkAttachmentDefinition 
# 除了 Pod 会用到 multus/NetworkAttachmentDefinition 之外
# kubevirt 虚拟机也经常会使用到 mulus/NetworkAttachmentDefinition
```

### 介绍 OpenShift Virtualization 的博客
https://blog.cudanet.org/setting-up-kubevirt/
```
# 内容写得非常详细
```

### 阿里云创建 baremetal 实例
https://bp.aliyun.com/detail/69

### 用 Patch Operator 解决 OCP 4.10/4.11 OLM 造成 master api 无法使用和访问的问题
```
# 当 OLM Operator 和 namespace 的数量达到一定数量后，OLM 会对 master api 造成较大压力
...
    olm-config-disable-csv-copy:
      patchType: application/merge-patch+json
      targetObjectRef:
        apiVersion: operators.coreos.com/v1
        kind: OLMConfig
        name: cluster        
      patchTemplate: |
        spec:
          features:
            disableCopiedCSVs: true
```

### 如何设置 systemd process 的 cpu affinity
https://www.thegeekdiary.com/how-to-set-cpu-affinity-for-systemd-process-in-centos-rhel-7/ 
```
# 查看进程 cpu affinity 的设置 
$ taskset -p [process ID]
$ ps --ppid 2 -p 2 -o uname,pid,ppid,cmd,cls,psr --deselect
```

### 启用 CIM 
```
# 这个步骤是文档上的步骤，但是实际执行时环境里并没有 provisionings 对象
$ oc patch provisioning provisioning-configuration --type merge -p '{"spec": {"watchAllNamespaces": true }}'

# 这个时候，我们需要创建一个对象
$ cat <<EOF | oc apply -f -
apiVersion: metal3.io/v1alpha1
kind: Provisioning
metadata:
  name: provisioning-configuration
spec:
  provisioningNetwork: Disabled
  watchAllNamespaces: true
EOF

# 生成 mirror-registry-config-map
$ cat <<EOF | tee /tmp/registry.conf
unqualified-search-registries = ["registry.access.redhat.com", "docker.io"]
short-name-mode = ""

[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-release"
  mirror-by-digest-only = true

  [[registry.mirror]]
    location = "registry.example.com:5000/openshift/release-images"

[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev/ocp-v4.0-art-dev"
  mirror-by-digest-only = true

  [[registry.mirror]]
    location = "registry.example.com:5000/openshift/release"

[[registry]]
  prefix = ""
  location = "registry.access.redhat.com"
  mirror-by-digest-only = true

  [[registry.mirror]]
    location = "registry.example.com:5000"

[[registry]]
  prefix = ""
  location = "registry.redhat.io"
  mirror-by-digest-only = true

  [[registry.mirror]]
    location = "registry.example.com:5000"
EOF

# ACM 2.6 需要把 namespace 指定为 multicluster-engine
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: mirror-registry-config-map
  namespace: "multicluster-engine"
  labels:
    app: assisted-service
data:
  ca-bundle.crt: |
$( cat /etc/pki/ca-trust/source/anchors/registry.crt | sed -e 's|^|    |g' )

  registries.conf: |
$( cat /tmp/registry.conf | sed -e 's|^|    |g' )
EOF

# 创建 configmap 指定 ISO_IMAGE_TYPE 为 full-iso
# ACM 2.6.1 需要把 namespace 改为 multicluster-engine
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: assisted-service-config
  namespace: multicluster-engine
  labels:
    app: assisted-service
data:
  HW_VALIDATOR_REQUIREMENTS: >-
    [{"version":"default","master":{"cpu_cores":4,"ram_mib":16384,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":100,"packet_loss_percentage":0},"worker":{"cpu_cores":2,"ram_mib":8192,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10,"network_latency_threshold_ms":1000,"packet_loss_percentage":10},"sno":{"cpu_cores":8,"ram_mib":4096,"disk_size_gb":120,"installation_disk_speed_threshold_ms":10}}]
  ISO_IMAGE_TYPE: "full-iso"
  # CONTROLLER_IMAGE: quay.io/ocpmetal/assisted-installer-controller@sha256:93f193d97556711dce20b2f11f9e2793ae26eb25ad34a23b93d74484bc497ecc
  LOG_LEVEL: "debug"
EOF

# 创建 AgentServiceConfig
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: AgentServiceConfig
metadata:
  name: agent
  namespace: multicluster-engine
  ### This is the annotation that injects modifications in the Assisted Service pod
  annotations:
    unsupported.agent-install.openshift.io/assisted-service-configmap: "assisted-service-config"
###
spec:
  databaseStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 20Gi
  filesystemStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 20Gi
  ### disconnected env need default this configmap. it contain ca-bundle.crt and registries.conf
  mirrorRegistryRef:
    name: "mirror-registry-config-map"
  osImages:
    - openshiftVersion: "4.10"
      version: "410.84.202205191234-0"
      rootFSUrl: "http://yum.example.com:8080/ocp/rhcos/rhcos-4.10.16-x86_64-live-rootfs.x86_64.img"
      url: "http://yum.example.com:8080/ocp/rhcos/rhcos-4.10.16-x86_64-live.x86_64.iso"
      cpuArchitecture: "x86_64"
EOF

# 检查一下日志
$ oc -n multicluster-engine logs $( oc get pods -n multicluster-engine -l control-plane='infrastructure-operator' -o name )

# 正常创建之后会有 agent 相关的 pod 被创建出来
$ oc get pods -n multicluster-engine 
NAME                                                   READY   STATUS    RESTARTS         AGE
agentinstalladmission-769b58c5f6-9mb7l                 1/1     Running   0                52s
agentinstalladmission-769b58c5f6-bq4sx                 1/1     Running   0                52s
assisted-image-service-0                               1/1     Running   0                52s
assisted-service-7c6988678-74nf2                       2/2     Running   0                52s

# 创建一个环境相关的 ClusterImageSet (先不采用这个方案)
$ cat <<EOF | oc apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: openshift-4.10.30
  namespace: multicluster-engine
spec:
   releaseImage: quay.io/openshift-release-dev/ocp-release:4.10.30-x86_64
EOF

# 实际的位置是在这个位置，创建时先试试本地 registry 
$ cat <<EOF | oc apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterImageSet
metadata:
  name: openshift-4.10.30
  namespace: multicluster-engine
spec:
   releaseImage: registry.example.com:5000/openshift/release-images:4.10.30-x86_64
EOF

# 创建 namespace
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ocp4-2 
  labels:
    name: ocp4-2
EOF

# 创建 NMStateConfig
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: ocp4-2
  namespace: ocp4-2
  labels:
    cluster-name: ocp4-2
spec:
  config:
    interfaces:
      - name: ens3
        type: ethernet
        state: up
        ethernet:
          auto-negotiation: true
          duplex: full
          speed: 10000
        ipv4:
          address:
          - ip: 192.168.122.111
            prefix-length: 24
          enabled: true
        mtu: 1500
        mac-address: 52:54:00:3d:7f:67
    dns-resolver:
      config:
        server:
        - 192.168.122.12
    routes:
      config:
      - destination: 192.168.122.0/24
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
        table-id: 254
  interfaces:
    - name: ens3
      macAddress: "52:54:00:3d:7f:67"
EOF

# 创建 ssh private key secret
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-ssh-private-key
  namespace: ocp4-2
stringData:
  ssh-privatekey: |-
$( cat /data/ocp-cluster/ocp4-2/ssh-key/id_rsa | sed -e 's/^/    /g' )
type: Opaque
EOF

# 创建 pullsecret secret
$ PULL_SECRET_FILE=/data/OCP-4.10.30/ocp/secret/pull-secret.json
$ PULL_SECRET_STR=$( cat ${PULL_SECRET_FILE} )
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-pull-secret
  namespace: ocp4-2
stringData: 
  .dockerconfigjson: '${PULL_SECRET_STR}'
EOF

# 创建 AgentClusterInstall
$ SSH_PUBLIC_KEY_STR=$( cat /data/ocp-cluster/ocp4-2/ssh-key/id_rsa.pub )
$ cat <<EOF | oc apply -f -
apiVersion: extensions.hive.openshift.io/v1beta1
kind: AgentClusterInstall
metadata:
  name: ocp4-2
  namespace: ocp4-2
spec:
  clusterDeploymentRef:
    name: ocp4-2
  imageSetRef:
    name: openshift-4.10.30
  networking:
    clusterNetwork:
      - cidr: "10.128.0.0/14"
        hostPrefix: 23
    serviceNetwork:
      - "172.31.0.0/16"
    machineNetwork:
      - cidr: "192.168.122.0/24"
  provisionRequirements:
    controlPlaneAgents: 1
  sshPublicKey: '${SSH_PUBLIC_KEY_STR}'
EOF

# 创建 ClusterDeployment
$ cat <<EOF | oc apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: ocp4-2
  namespace: ocp4-2
spec:
  baseDomain: example.com
  clusterName: ocp4-2
  installed: false
  clusterInstallRef:
    group: extensions.hive.openshift.io
    kind: AgentClusterInstall
    name: ocp4-2
    version: v1beta1
  platform:
    agentBareMetal:
      agentSelector:
        matchLabels:
          agent-install.openshift.io/clusterdeployment-namespace: "ocp4-2"
  pullSecretRef:
    name: assisted-deployment-pull-secret
EOF

# 创建 KlusterletAddonConfig
$ cat <<EOF | oc apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ocp4-2
  namespace: ocp4-2
spec:
  clusterName: ocp4-2
  clusterNamespace: ocp4-2
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: false
  iamPolicyController:
    enabled: false
  policyController:
    enabled: true
  searchCollector:
    enabled: false 
EOF

# 创建 ManagedCluster
$ cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ocp4-2
spec:
  hubAcceptsClient: true
EOF

# 创建 InfraEnv
$ SSH_PUBLIC_KEY_STR=$( cat /data/ocp-cluster/ocp4-2/ssh-key/id_rsa.pub )
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: ocp4-2
  namespace: ocp4-2
spec:
  additionalNTPSources:
    - ntp.example.com  
  clusterRef:
    name: ocp4-2
    namespace: ocp4-2
  sshAuthorizedKey: '${SSH_PUBLIC_KEY_STR}'
  agentLabelSelector:
    matchLabels:
      agent-install.openshift.io/clusterdeployment-namespace: "ocp4-2"
  pullSecretRef:
    name: assisted-deployment-pull-secret
  ignitionConfigOverride: '{"ignition":{"version":"3.1.0"},"storage":{"files":[{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /tmp/registry.conf | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/containers/registries.conf"},{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/pki/ca-trust/source/anchors/registry.crt"}]}}'
  nmStateConfigLabelSelector:
    matchLabels:
      cluster-name: ocp4-2
EOF

# Add Host
# Download Discovery ISO
# 用 Discovery ISO 启动节点
# 在界面 Approve Host

# 检查 assisted-service 日志
$ oc -n multicluster-engine logs $ ( oc get pods -n multicluster-engine -l app='assisted-service' -o name )

# 创建 namespace
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ocp4-3 
  labels:
    name: ocp4-3
EOF

# 创建 NMStateConfig
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: ocp4-3
  namespace: ocp4-3
  labels:
    cluster-name: ocp4-3
spec:
  config:
    interfaces:
      - name: ens3
        type: ethernet
        state: up
        ethernet:
          auto-negotiation: true
          duplex: full
          speed: 10000
        ipv4:
          address:
          - ip: 192.168.122.131
            prefix-length: 24
          enabled: true
        mtu: 1500
        mac-address: 52:54:00:d7:42:ac
    dns-resolver:
      config:
        server:
        - 192.168.122.12
    routes:
      config:
      - destination: 192.168.122.0/24
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.122.1
        next-hop-interface: ens3
        table-id: 254
  interfaces:
    - name: ens3
      macAddress: "52:54:00:d7:42:ac"
EOF

# 创建 ssh private key secret
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-ssh-private-key
  namespace: ocp4-3
stringData:
  ssh-privatekey: |-
$( cat /data/ocp-cluster/ocp4-3/ssh-key/id_rsa | sed -e 's/^/    /g' )
type: Opaque
EOF

# 创建 pullsecret secret
$ PULL_SECRET_FILE=/data/OCP-4.10.30/ocp/secret/pull-secret.json
$ PULL_SECRET_STR=$( cat ${PULL_SECRET_FILE} )
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-pull-secret
  namespace: ocp4-3
stringData: 
  .dockerconfigjson: '${PULL_SECRET_STR}'
EOF

# 创建 AgentClusterInstall
$ SSH_PUBLIC_KEY_STR=$( cat /data/ocp-cluster/ocp4-3/ssh-key/id_rsa.pub )
$ cat <<EOF | oc apply -f -
apiVersion: extensions.hive.openshift.io/v1beta1
kind: AgentClusterInstall
metadata:
  name: ocp4-3
  namespace: ocp4-3
spec:
  clusterDeploymentRef:
    name: ocp4-3
  imageSetRef:
    name: openshift-4.10.30
  networking:
    clusterNetwork:
      - cidr: "10.128.0.0/14"
        hostPrefix: 23
    serviceNetwork:
      - "172.31.0.0/16"
    machineNetwork:
      - cidr: "192.168.122.0/24"
  provisionRequirements:
    controlPlaneAgents: 1
  sshPublicKey: '${SSH_PUBLIC_KEY_STR}'
EOF

# 创建 ClusterDeployment
$ cat <<EOF | oc apply -f -
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: ocp4-3
  namespace: ocp4-3
spec:
  baseDomain: example.com
  clusterName: ocp4-3
  installed: false
  clusterInstallRef:
    group: extensions.hive.openshift.io
    kind: AgentClusterInstall
    name: ocp4-3
    version: v1beta1
  platform:
    agentBareMetal:
      agentSelector:
        matchLabels:
          agent-install.openshift.io/clusterdeployment-namespace: "ocp4-3"
  pullSecretRef:
    name: assisted-deployment-pull-secret
EOF

# 创建 KlusterletAddonConfig
$ cat <<EOF | oc apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ocp4-3
  namespace: ocp4-3
spec:
  clusterName: ocp4-3
  clusterNamespace: ocp4-3
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: false
  iamPolicyController:
    enabled: false
  policyController:
    enabled: true
  searchCollector:
    enabled: false 
EOF

# 创建 ManagedCluster
$ cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ocp4-3
spec:
  hubAcceptsClient: true
EOF

# 创建 InfraEnv
$ SSH_PUBLIC_KEY_STR=$( cat /data/ocp-cluster/ocp4-3/ssh-key/id_rsa.pub )
$ cat <<EOF | oc apply -f -
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: ocp4-3
  namespace: ocp4-3
spec:
  additionalNTPSources:
    - ntp.example.com  
  clusterRef:
    name: ocp4-3
    namespace: ocp4-3
  sshAuthorizedKey: '${SSH_PUBLIC_KEY_STR}'
  agentLabelSelector:
    matchLabels:
      agent-install.openshift.io/clusterdeployment-namespace: "ocp4-3"
  pullSecretRef:
    name: assisted-deployment-pull-secret
  ignitionConfigOverride: '{"ignition":{"version":"3.1.0"},"storage":{"files":[{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /tmp/registry.conf | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/containers/registries.conf"},{"contents":{"source":"data:text/plain;charset=utf-8;base64,$(cat /etc/pki/ca-trust/source/anchors/registry.crt | base64 -w0)","verification":{}},"filesystem":"root","mode":420,"overwrite":true,"path":"/etc/pki/ca-trust/source/anchors/registry.crt"}]}}'
  nmStateConfigLabelSelector:
    matchLabels:
      cluster-name: ocp4-3
EOF

# Add Host
# Download Discovery ISO
# 用 Discovery ISO 启动节点
# 在界面 Approve Host


```

### sushy-tools 
https://cloudcult.dev/sushy-emulator-redfish-for-the-virtualization-nation/
```
# 现在想尝试一下 sushy-tools
$ htpasswd -c -B -b /etc/sushy/sushy-emulator.htpasswd admin redhat

$ cat /etc/sushy/sushy-emulator.conf 
SUSHY_EMULATOR_LISTEN_IP = u'0.0.0.0'
SUSHY_EMULATOR_LISTEN_PORT = 8000
SUSHY_EMULATOR_SSL_CERT = None
SUSHY_EMULATOR_SSL_KEY = None
SUSHY_EMULATOR_AUTH_FILE = u'/etc/sushy/sushy-emulator.htpasswd'
SUSHY_EMULATOR_OS_CLOUD = None
SUSHY_EMULATOR_LIBVIRT_URI = u'qemu:///system'
SUSHY_EMULATOR_IGNORE_BOOT_DEVICE = False
SUSHY_EMULATOR_BOOT_LOADER_MAP = {
    u'UEFI': {
        u'x86_64': u'/usr/share/OVMF/OVMF_CODE.secboot.fd'
    },
    u'Legacy': {
        u'x86_64': None
    }
}
$ rpm -qf /usr/share/OVMF/OVMF_CODE.secboot.fd 
OVMF-20180508-6.gitee3198e672e2.el7.noarch

$ curl -L http://localhost:8000/redfish/v1/Managers/ 
- This will list the Managers you have -
$ curl -L http://localhost:8000/redfish/v1/Managers/<CSelectedManager>/VirtualMedia
```

### CentOS 7系统KVM虚拟机支持UEFI启动
https://www.dwhd.org/20200316_154619.html<br>
https://access.redhat.com/articles/1434903
```
cd /data/kvm
qemu-img create -f qcow2 -o preallocation=metadata jwang-test-01.qcow2 120G

virt-install --name jwang-test-01 \
    --ram 8192 --vcpus 2 --os-variant rhel7 \
    --cpu host,+vmx \
    --network network:default \
    --boot uefi,cdrom,fd,hd,network,menu=on \
    --noautoconsole --vnc \
    --disk path=/data/kvm/jwang-test-01.qcow2,device=disk,bus=virtio,format=qcow2 \
    --dry-run --print-xml > /tmp/jwang-test-01.xml;

virsh define /tmp/jwang-test-01.xml
```

### 非常好的介绍将 HyperShift 与 CIM/Agent Install 集成的 Blog 
https://hypershift-docs.netlify.app/how-to/agent/create-agent-cluster/

### 添加 openshift-authentication ingress-ca 
https://access.redhat.com/solutions/4505101
```
# The CA which issues the Authentication endpoint (kube-apiserver-lb-signer) is not included in the kubeconfig and therefore must be trusted in the system and/or provided with --certificate-authority=parameter in the login command
# authentication endpoint 的证书并不包含在 kubeconfig 里，需要管理员手工添加到客户端证书信任位置
$ oc rsh -n openshift-authentication $(oc -n openshift-authentication get pods -l app='oauth-openshift' -o name) cat /run/secrets/kubernetes.io/serviceaccount/ca.crt > /etc/pki/ca-trust/source/anchors/ingress-ca.crt
$ update-ca-trust extract
```

### 获取 rhcos volume id
```
$ isoinfo -d -i rhcos-4.11.2-x86_64-live.x86_64.iso | awk '/Volume id/ { print $3 }'
rhcos-411.86.202208112011-0
```

### add privileged scc to service account default in namespace kmm-operator-system - ocp 4.12
```
oc adm policy add-scc-to-user privileged -z default -n kmm-operator-system
```

### 尝试 kernel module management operator - kmm
```
# 参考：https://github.com/rh-ecosystem-edge/kernel-module-management

# 安装 kernel module management operator
$ oc apply -k https://github.com/rh-ecosystem-edge/kernel-module-management/config/default
namespace/kmm-operator-system created
customresourcedefinition.apiextensions.k8s.io/modules.kmm.sigs.k8s.io created
customresourcedefinition.apiextensions.k8s.io/preflightvalidations.kmm.sigs.k8s.io created
serviceaccount/kmm-operator-controller-manager created
role.rbac.authorization.k8s.io/kmm-operator-leader-election-role created
clusterrole.rbac.authorization.k8s.io/kmm-operator-device-plugin created
clusterrole.rbac.authorization.k8s.io/kmm-operator-manager-role created
clusterrole.rbac.authorization.k8s.io/kmm-operator-metrics-reader created
clusterrole.rbac.authorization.k8s.io/kmm-operator-module-loader created
clusterrole.rbac.authorization.k8s.io/kmm-operator-proxy-role created
rolebinding.rbac.authorization.k8s.io/kmm-operator-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/kmm-operator-manager-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/kmm-operator-proxy-rolebinding created
configmap/kmm-operator-manager-config created
configmap/kmm-operator-trusted-ca created
service/kmm-operator-controller-manager-metrics-service created
deployment.apps/kmm-operator-controller-manager created

# 
$ oc get all -n kmm-operator-system
NAME                                                   READY   STATUS    RESTARTS   AGE
pod/kmm-operator-controller-manager-6544cfbf79-kk8l7   2/2     Running   0          3m15s
NAME                                                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/kmm-operator-controller-manager-metrics-service   ClusterIP   172.30.28.83   <none>        8443/TCP   3m16s
NAME                                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kmm-operator-controller-manager   1/1     1            1           3m17s
NAME                                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/kmm-operator-controller-manager-6544cfbf79   1         1         1       3m17s


```

### 设置 image-registry
```
# 在设置完默认的 storageclass 之后
$ oc patch configs.imageregistry.operator.openshift.io cluster -p '{"spec":{"managementState": "Managed","storage":{"pvc":{"claim":""}}}}' --type=merge
# 重建 pvc image-registry-storage
$ oc delete pvc image-registry-storage -n openshift-image-registry
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: image-registry-storage
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: odf-lvm-vg1
  volumeMode: Filesystem
EOF
$ oc get clusteroperator image-registry
$ oc get configs.imageregistry.operator.openshift.io cluster -o yaml

```

### 通过 aws-cli container 运行 aws 命令
```
# aws-cli 
podman run -it --rm registry.example.com:5000/amazon/aws-cli configure
podman run -it --rm -v ~/.aws:/root/.aws registry.example.com:5000/amazon/aws-cli --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 ls
podman run -it --rm -v ~/.aws:/root/.aws registry.example.com:5000/amazon/aws-cli --endpoint=$(oc -n velero get route minio -o jsonpath='{"http://"}{.spec.host}') s3 mb s3://observability
```

### hypershift 简易测试步骤
```
# 安装
$ hypershift install

$ hypershift create cluster   --pull-secret /path/pullsecret.json --aws-creds ~/.aws/credentials --name bpareesguest4 --base-domain devcluster.openshift.com

$ hypershift create kubeconfig > kubeconfig

# 删除
$ hypershift destroy cluster   --aws-creds ~/.aws/credentials   --namespace clusters   --name bpareesguest

$ hypershift install --render | oc delete -f -
```

### 关于 ACM GRC Policy 写得的非常好的博客
https://cloud.redhat.com/blog/generating-governance-policies-using-kustomize-and-gitops<br>

### 创建 ClusterRole 和 ClusterRoleBinding 让 serviceaccount 可以用 --as=<user> 的方式执行命令
```
$ oc whoami
developer

$ oc new-project developer
Now using project "developer" on server "https://api.ocp411.ocp.local:6443".

$ oc create serviceaccount build-bot
serviceaccount/build-bot created

$ oc login -u kubeadmin ...
Login successful.

# Create a ClusterRoleBinding from the documentation at https://docs.openshift.com/container-platform/4.11/authentication/impersonating-system-admin.html

# 创建 ClusterRole 和 ClusterRoleBinding，让 serviceaccount build-bot 能以 --as=developer 的方式执行命令
$ oc create -f - <<EOF
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRole
  metadata:
    name: limited-impersonator
  rules:
  - apiGroups: [""]
    resources: ["users"]
    verbs: ["impersonate"]
    resourceNames: ["developer"]
EOF

$ oc create -f - <<EOF
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: impersonate-developer-two
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: limited-impersonator
    subjects:
    - kind: ServiceAccount
      name: build-bot
      namespace: developer
EOF

clusterrolebinding.rbac.authorization.k8s.io/impersonate-developer created
$ oc login --token $(oc get $(oc get secret -o name | grep build-bot-token) -o go-template='{{index .data "token" | base64decode}}')
Logged into "https://api.ocp411.ocp.local:6443" as "system:serviceaccount:developer:build-bot" using the token provided.

$ oc --as=developer -n developer get pods

# The OCP documentation on impersonation focuses on providing system admin rights to a user through impersonation. The Kubernetes documentation might be a bit more helpful https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation



```

### 添加 Policy 配置 registry mirror config
https://raw.githubusercontent.com/stolostron/policy-collection/main/community/CM-Configuration-Management/policy-machineconfig-chrony.yaml<br>
```
# 添加一个配置 registry mirror 的 Policy 
cat > policy-ocp4-3.yaml <<EOF
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: add-registrymirror
  annotations:
    policy.open-cluster-management.io/standards: NIST SP 800-53
    policy.open-cluster-management.io/categories: CM Configuration Management
    policy.open-cluster-management.io/controls: CM-2 Baseline Configuration
spec:
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: add-registrymirror
        spec:
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: machineconfiguration.openshift.io/v1
                kind: MachineConfig
                metadata:
                  name: 99-master-mirror-by-digest-registries
                  labels:
                    machineconfiguration.openshift.io/role: master
                spec:
                  config:
                    ignition:
                      version: 3.2.0
                    storage:
                      files:
                      - contents:
                          source: data:text/plain;charset=utf-8;base64,W1tyZWdpc3RyeV1dCiAgcHJlZml4ID0gIiIKICBsb2NhdGlvbiA9ICJyZWdpc3RyeS5yZWRoYXQuaW8vbXVsdGljbHVzdGVyLWVuZ2luZSIKICBtaXJyb3ItYnktZGlnZXN0LW9ubHkgPSB0cnVlCiAKICBbW3JlZ2lzdHJ5Lm1pcnJvcl1dCiAgICBsb2NhdGlvbiA9ICJyZWdpc3RyeS5leGFtcGxlLmNvbTo1MDAwL211bHRpY2x1c3Rlci1lbmdpbmUiCgpbW3JlZ2lzdHJ5XV0KICBwcmVmaXggPSAiIgogIGxvY2F0aW9uID0gInJlZ2lzdHJ5LnJlZGhhdC5pby9yaGFjbTIiCiAgbWlycm9yLWJ5LWRpZ2VzdC1vbmx5ID0gdHJ1ZQogCiAgW1tyZWdpc3RyeS5taXJyb3JdXQogICAgbG9jYXRpb24gPSAicmVnaXN0cnkuZXhhbXBsZS5jb206NTAwMC9yaGFjbTIiCgpbW3JlZ2lzdHJ5XV0KICBwcmVmaXggPSAiIgogIGxvY2F0aW9uID0gInF1YXkuaW8vZ3B0ZS1kZXZvcHMtYXV0b21hdGlvbiIKICBtaXJyb3ItYnktZGlnZXN0LW9ubHkgPSBmYWxzZQoKICBbW3JlZ2lzdHJ5Lm1pcnJvcl1dCiAgICBsb2NhdGlvbiA9ICJyZWdpc3RyeS5leGFtcGxlLmNvbTo1MDAwL2dwdGUtZGV2b3BzLWF1dG9tYXRpb24iCgpbW3JlZ2lzdHJ5XV0KICBwcmVmaXggPSAiIgogIGxvY2F0aW9uID0gInJlZ2lzdHJ5LnJlZGhhdC5pby9vcGVuc2hpZnQ0IgogIG1pcnJvci1ieS1kaWdlc3Qtb25seSA9IGZhbHNlCgogIFtbcmVnaXN0cnkubWlycm9yXV0KICAgIGxvY2F0aW9uID0gInJlZ2lzdHJ5LmV4YW1wbGUuY29tOjUwMDAvb3BlbnNoaWZ0NCIKCltbcmVnaXN0cnldXQogIHByZWZpeCA9ICIiCiAgbG9jYXRpb24gPSAicmVnaXN0cnkucmVkaGF0LmlvL3JoZWw4IgogIG1pcnJvci1ieS1kaWdlc3Qtb25seSA9IGZhbHNlCgogIFtbcmVnaXN0cnkubWlycm9yXV0KICAgIGxvY2F0aW9uID0gInJlZ2lzdHJ5LmV4YW1wbGUuY29tOjUwMDAvcmhlbDgiCgpbW3JlZ2lzdHJ5XV0KICBwcmVmaXggPSAiIgogIGxvY2F0aW9uID0gInF1YXkuaW8vanBhY2tlciIKICBtaXJyb3ItYnktZGlnZXN0LW9ubHkgPSBmYWxzZQoKICBbW3JlZ2lzdHJ5Lm1pcnJvcl1dCiAgICBsb2NhdGlvbiA9ICJyZWdpc3RyeS5leGFtcGxlLmNvbTo1MDAwL2pwYWNrZXIiCgpbW3JlZ2lzdHJ5XV0KICBwcmVmaXggPSAiIgogIGxvY2F0aW9uID0gImRvY2tlci5pby9iaXRuYW1pIgogIG1pcnJvci1ieS1kaWdlc3Qtb25seSA9IGZhbHNlCgogIFtbcmVnaXN0cnkubWlycm9yXV0KICAgIGxvY2F0aW9uID0gInJlZ2lzdHJ5LmV4YW1wbGUuY29tOjUwMDAvYml0bmFtaSIKCltbcmVnaXN0cnldXQogIHByZWZpeCA9ICIiCiAgbG9jYXRpb24gPSAiZG9ja2VyLmlvL21pbmlvIgogIG1pcnJvci1ieS1kaWdlc3Qtb25seSA9IGZhbHNlCgogIFtbcmVnaXN0cnkubWlycm9yXV0KICAgIGxvY2F0aW9uID0gInJlZ2lzdHJ5LmV4YW1wbGUuY29tOjUwMDAvbWluaW8iCg==
                        filesystem: root
                        mode: 420
                        path: /etc/containers/registries.conf.d/99-master-mirror-by-digest-registries.conf
          remediationAction: enforce
          severity: low
  remediationAction: inform
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-add-registrymirror
placementRef:
  name: placement-add-registrymirror
  kind: PlacementRule
  apiGroup: apps.open-cluster-management.io
subjects:
- name: add-registrymirror
  kind: Policy
  apiGroup: policy.open-cluster-management.io
---
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: placement-add-registrymirror
spec:
  clusterConditions:
  - status: "True"
    type: ManagedClusterConditionAvailable
  clusterSelector:
    matchExpressions:
      - {key: name, operator: In, values: ["ocp4-3"]}
EOF
```

### CODESYS Gateway 设置
https://blog.csdn.net/weixin_44112083/article/details/122283497<br>
```
# 双击 'Device' 
# 网关 -> 添加网关 -> 名称:'Gateway-2' -> 驱动:'TCP/IP' -> 输入 IP 地址 -> 确定
# 在 CODESYS Runtime for Linux 所在的机器上
$ /etc/init.d/codesysedge status
$ /etc/init.d/codesysedge start
$ /etc/init.d/codesysedge status
$ /etc/init.d/codesyscontrol status
$ /etc/init.d/codesyscontrol start
$ /etc/init.d/codesyscontrol status

# 扫描网络，找到 CODESYS Runtime for Linux 机器
# 选择工具栏'登陆'
# 激活下位机
# 选择工具栏'启动‘，下发程序到下位机
# 双击 'Visualization' - 可以在可视化界面里查看
```

### 使用 nightly bundle 安装 kubernetes nmstate operator 
https://github.com/openshift/kubernetes-nmstate/blob/master/hack/ocp-install-nightly-art-operators.sh<br>

### Intel ECI 3.0
https://eci.intel.com/docs/3.0/index.html<br>

### ThingsBoard Gateway
https://www.emqx.io/<br>
https://nanomq.io/<br>
https://thingsboard.io/docs/getting-started-guides/what-is-thingsboard/<br>
https://github.com/thingsboard/thingsboard-gateway<br>

### 默认的 podman registry auth pull secret 查找位置
https://github.com/containers/image/blob/main/docs/containers-auth.json.5.md<br>
```
${XDG_RUNTIME_DIR}/containers/auth.json
${XDG_CONFIG_HOME}/containers/auth.json
~/.config/containers/auth.json
$HOME/.docker/config.json
$HOME/.dockercfg
```

### 从 4.11 想 4.12 升级
https://access.redhat.com/articles/6955381<br>
https://access.redhat.com/articles/6955985<br>
```
$ oc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.11-kube-1.25-api-removals-in-4.12":"true"}}' --type=merge
```

### Community Prometheus Operator
https://www.opsramp.com/guides/prometheus-monitoring/prometheus-operator/<br>
https://blog.csdn.net/qq_34556414/article/details/122316980<br>
https://www.ibm.com/docs/en/erqa?topic=monitoring-creating-prometheus-service-monitors<br>
https://github.com/minio/docs/issues/217<br>
https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/alerting.md<br>
https://mp.weixin.qq.com/s/E6eusGZvoYd_LfjWfq6IRQ<br>
https://mp.weixin.qq.com/s/MZgMuUTWX_kyiut2DZECfw<br>
https://blog.container-solutions.com/prometheus-operator-beginners-guide<br>
https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/alerting.md<br>
```
$ kubectl port-forward svc/prometheus-operated 9090:9090

$ cat <<EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
 name: zone0-ingress-controller
 namespace: prometheus-zone0
 labels:
   zone: zone0
spec:
 namespaceSelector:
   matchNames:
   - openshift-ingress
 selector:
   matchLabels:
     ingresscontroller.operator.openshift.io/owning-ingresscontroller: zone0-ingress-controller
 endpoints:
 - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
   interval: 30s
   path: /metrics
   port: metrics
   scheme: https
   tlsConfig:
     insecureSkipVerify: True
EOF

$ cat <<EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    zone: zone0
  name: my-node-exporter
  namespace: prometheus
spec:
  endpoints:
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    interval: 30s
    port: https
    relabelings:
    - action: replace
      regex: (.*)
      replacement: $1
      sourceLabels:
      - __meta_kubernetes_pod_node_name
      targetLabel: instance
    scheme: https
    tlsConfig:
      insecureSkipVerify: True
  jobLabel: app.kubernetes.io/name
  namespaceSelector:
    matchNames:
    - openshift-monitoring
  selector:
    matchLabels:
      app.kubernetes.io/component: exporter
      app.kubernetes.io/name: node-exporter
      app.kubernetes.io/part-of: openshift-monitoring
      zone: zone0
EOF

### 刮取系统 Endpoint 需要 cluster-admin 角色
$ oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:prometheus:prometheus-k8s

# 为节点打标签
$ oc label node worker0.ocp4.rhcnsa.com zone=zone0
$ oc label node worker2.ocp4.rhcnsa.com zone=zone2
$ oc label node worker3.ocp4.rhcnsa.com zone=zone3

# 设置 prometheus-operator nodeSelector - 这个配置在 AWS Cluster 上不生效
$ oc -n prometheus-zone0 patch deployment prometheus-operator --type json -p '[{"op": "remove", "path": "/spec/template/spec/nodeSelector"}]'
$ oc -n prometheus-zone0 patch deployment prometheus-operator --type json -p '[{"op": "add", "path": "/spec/template/spec/nodeSelector", "value": {"zone": "zone0"}}]'

$ 为 pod 添加 label
$ oc get pods -n openshift-monitoring -o wide | grep worker0
node-exporter-njk8h                                      2/2     Running   0          111d   172.26.168.105   worker0.ocp4.rhcnsa.com   <none>           <none>
$ oc label pod node-exporter-njk8h -n openshift-monitoring zone=zone0
$ oc get pods -n openshift-monitoring node-exporter-njk8h --show-labels

# 创建新 svc node-exporter-zone0，label添加 zone: zone0，selector添加 zone: zone0
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: node-exporter
    app.kubernetes.io/part-of: openshift-monitoring
    app.kubernetes.io/version: 1.3.1
    zone: zone0
  name: node-exporter-zone0
  namespace: openshift-monitoring
spec:
  clusterIP: None
  clusterIPs:
  - None
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: https
    port: 9100
    protocol: TCP
    targetPort: https
  selector:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: node-exporter
    app.kubernetes.io/part-of: openshift-monitoring
    zone: zone0
  sessionAffinity: None
  type: ClusterIP
EOF

# 注意：alerting - alertmanagers -> name 对应 alertmanager 的 service name
# 不是 Alertmanager CR 的 metadata.name
$ cat <<EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: zone0
  namespace: prometheus-zone0
spec:
  evaluationInterval: 30s
  nodeSelector:
    zone: "zone0"
  serviceAccountName: prometheus-k8s
  serviceMonitorSelector:
    matchLabels:
      zone: zone0
  alerting:
    alertmanagers:
      - name: alertmanager-operated
        namespace: prometheus-zone0
        port: web
  probeSelector: {}
  podMonitorSelector: {}
  scrapeInterval: 30s
  replicas: 1
  ruleSelector: {}
  tolerations:
    - key: node.kubernetes.io/not-ready
      operator: Exists
      effect: NoExecute
      tolerationSeconds: 259200
    - key: node.kubernetes.io/unreachable
      operator: Exists
      effect: NoExecute
      tolerationSeconds: 259200
    - key: node.kubernetes.io/disk-pressure
      operator: Exists
      effect: NoSchedule
    - key: node.kubernetes.io/memory-pressure
      operator: Exists
      effect: NoSchedule
    - key: node.kubernetes.io/pid-pressure
      operator: Exists
      effect: NoSchedule
    - key: node.kubernetes.io/unschedulable
      operator: Exists
      effect: NoSchedule
EOF

$ cat <<EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: Alertmanager
metadata:
  name: alertmanager-zone0
  namespace: prometheus-zone0
spec:
  nodeSelector:
    zone: "zone0"
  alertmanagerConfigSelector: {}
  configSecret: alertmanager-alertmanager-example
  replicas: 1
  tolerations:
    - key: node.kubernetes.io/not-ready
      operator: Exists
      effect: NoExecute
      tolerationSeconds: 259200
    - key: node.kubernetes.io/unreachable
      operator: Exists
      effect: NoExecute
      tolerationSeconds: 259200
    - key: node.kubernetes.io/disk-pressure
      operator: Exists
      effect: NoSchedule
    - key: node.kubernetes.io/memory-pressure
      operator: Exists
      effect: NoSchedule
    - key: node.kubernetes.io/pid-pressure
      operator: Exists
      effect: NoSchedule
    - key: node.kubernetes.io/unschedulable
      operator: Exists
      effect: NoSchedule
EOF

# 查看 pods 运行在节点 worker0 上，节点 worker0 有label zone: zone0
$ oc get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP             NODE                      NOMINATED NODE   READINESS GATES
alertmanager-alertmanager-main-0       2/2     Running   0          26m   10.131.0.218   worker0.ocp4.rhcnsa.com   <none>           <none>
prometheus-example-0                   2/2     Running   0          30m   10.131.0.217   worker0.ocp4.rhcnsa.com   <none>           <none>
prometheus-operator-7ddc7d78cb-xrzcd   1/1     Running   0          18m   10.131.0.221   worker0.ocp4.rhcnsa.com   <none>           <none>

# 转发端口
$ oc port-forward svc/prometheus-operated 9090:9090
$ oc port-forward svc/alertmanager-operated 9093:9093

$ oc get pods -n openshift-monitoring -o wide | grep worker0
node-exporter-njk8h                                      2/2     Running   0          111d   172.26.168.105   worker0.ocp4.rhcnsa.com   <none>           <none>

$ 为 pod 添加 label
$ oc label pod node-exporter-njk8h -n openshift-monitoring zone=zone0
$ oc get pods -n openshift-monitoring node-exporter-njk8h --show-labels

### 检查日志
$ oc logs $(oc get pods -l prometheus=zone0 -o name)

```

### topolvm on new worker
https://coreos.slack.com/archives/CJW8YBDR7/p1672809645600529<br>
https://www.tecmint.com/setup-thin-provisioning-volumes-in-lvm/<br>
```
$ ssh -i /data/ocp-cluster/ocp4-1/ssh-key/id_rsa core@worker-0.zone0.example.com
$ sudo -i
$ pvcreate /dev/vdb
$ vgcreate vg1 /dev/vdb
$ lvcreate -L 90G --thinpool thin-pool-1 vg1
$ cat > /etc/topolvm/lvmd.yaml <<EOF
device-classes:
- default: true
  lvcreate-options: null
  name: vg1
  spare-gb: null
  stripe: null
  stripe-size: ""
  thin-pool:
    name: thin-pool-1
    overprovision-ratio: 10
  type: thin
  volume-group: vg1
socket-name: /run/lvmd/lvmd.sock
EOF
```

### 改 core 用户密码的 MachineConfig 的例子
https://github.com/openshift/assisted-service/blob/master/docs/set-discovery-password.md<br>
https://github.com/openshift/assisted-service/blob/master/docs/user-guide/install-customization.md#patch-the-discovery-ignition<br>
https://github.com/openshift/assisted-service/blob/master/docs/user-guide/install-customization.md#pointer-ignition<br>
```
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: worker-core-password
  labels:
    machineconfiguration.openshift.io/role: worker
spec:
  config:
    ignition:
      version: 3.2.0
    systemd:
      units:
      - name: core-password.service
        enabled: true
        contents: |
          [Unit]
          Description=Changes core password
          [Service]
          Type=oneshot
          ExecStart=/bin/bash -c "echo core:redhat | chpasswd"
          [Install]
          WantedBy=multi-user.target
```

### 安装 OpenShift 时使用 Calico CNI 
```
- set network type in install config to Calico
- use openshift-install create manifests
- curl https://projectcalico.docs.tigera.io/manifests/ocp.tgz | tar xvz --strip-components=1 -C $manifests_dir
```

### SourceHut will blacklist the Go module mirror
https://sourcehut.org/blog/2023-01-09-gomodulemirror/
```
you’ll need to set export GOPRIVATE=git.sr.ht starting on Feb 24, 2023.
```

### OCP4 检查未来即将弃用的 API
```
### 4.11.5
$ oc get apirequestcounts -o jsonpath='{range .items[?(@.status.removedInRelease!="")]}{.status.removedInRelease}{"\t"}{.status.requestCount}{"\t"}{.metadata.name}{"\n"}{end}'
1.22    989     customresourcedefinitions.v1beta1.apiextensions.k8s.io
1.26    3443    flowschemas.v1beta1.flowcontrol.apiserver.k8s.io
1.26    179     horizontalpodautoscalers.v2beta2.autoscaling
1.25    0       poddisruptionbudgets.v1beta1.policy
1.25    485     podsecuritypolicies.v1beta1.policy
1.26    313     prioritylevelconfigurations.v1beta1.flowcontrol.apiserver.k8s.io

### 4.12.0-rc6
$ oc get apirequestcounts -o jsonpath='{range .items[?(@.status.removedInRelease!="")]}{.status.removedInRelease}{"\t"}{.status.requestCount}{"\t"}{.metadata.name}{"\n"}{end}'
1.22    1259    customresourcedefinitions.v1beta1.apiextensions.k8s.io
1.26    0       flowschemas.v1beta1.flowcontrol.apiserver.k8s.io
1.26    0       horizontalpodautoscalers.v2beta2.autoscaling
1.25    0       poddisruptionbudgets.v1beta1.policy
1.25    0       podsecuritypolicies.v1beta1.policy
1.26    0       prioritylevelconfigurations.v1beta1.flowcontrol.apiserver.k8s.io
```

### 检查 OCP Upgrade Graph 比较 promote to stable-4.10 与 eus-4.10
https://github.com/openshift/cincinnati-graph-data
```
$ git --no-pager log --first-parent --date=iso --format='%ad %h %s' -20 -- channels/stable-4.10.yaml channels/eus-4.10.yaml | grep 'promote-4[.]10[.]'
2022-12-21 03:36:13 -0500 307bb44 Merge pull request #2923 from openshift-ota-bot/promote-4.10.45-to-stable-4.10
2022-12-21 03:25:47 -0500 60f20fa Merge pull request #2922 from openshift-ota-bot/promote-4.10.45-to-eus-4.10
2022-12-06 07:24:39 -0500 2875485 Merge pull request #2867 from openshift-ota-bot/promote-4.10.43-to-stable-4.10
2022-12-06 07:00:14 -0500 3625dec Merge pull request #2866 from openshift-ota-bot/promote-4.10.43-to-eus-4.10
2022-11-29 04:34:43 -0500 6b26f13 Merge pull request #2830 from openshift-ota-bot/promote-4.10.42-to-stable-4.10
2022-11-29 04:24:23 -0500 2322865 Merge pull request #2829 from openshift-ota-bot/promote-4.10.42-to-eus-4.10
2022-11-24 20:26:49 -0500 704925a Merge pull request #2816 from openshift-ota-bot/promote-4.10.41-to-stable-4.10
2022-11-24 20:08:35 -0500 5aa4543 Merge pull request #2815 from openshift-ota-bot/promote-4.10.41-to-eus-4.10
2022-11-16 13:23:08 +0000 3221308 Merge pull request #2763 from openshift-ota-bot/promote-4.10.40-to-stable-4.10
2022-11-16 13:03:55 +0000 52e44ac Merge pull request #2762 from openshift-ota-bot/promote-4.10.40-to-eus-4.10
2022-11-09 05:44:39 -0500 8be080d Merge pull request #2728 from openshift-ota-bot/promote-4.10.39-to-stable-4.10
```

### Disabling the self provisioning in OpenShift 4
https://rcarrata.com/openshift/disabling-self-provisioning-ocp4/
```
```

### docker 如何发布 udp port
https://stackoverflow.com/questions/27596409/how-do-i-publish-a-udp-port-on-docker<br>
https://docs.docker.com/engine/reference/builder/#expose
```
sudo docker run -p 53160:53160 \
    -p 53160:53160/udp -p 58846:58846 \ 
    -p 8112:8112 -t -i aostanin/deluge /start.sh

# Dockerfile
EXPOSE 8285/udp

# docker-compose
ports:
  - "9955:9955/udp"
```

### rhv scripts
```
/usr/share/ovirt-engine/dbscripts/engine-psql.sh -x -c "SELECT * FROM snapshots WHERE snapshot_id = 'SNAPSHOT_ID_OF_REGULAR_SNAPSHOT';" > /tmp/foo.

# 登陆 rhv manager 服务器
# engine database passwd 在 /etc/ovirt-engine/engine.conf.d/10-setup-database.conf 文件中
$ psql -U engine -h localhost engine 
engine=> \x on      # 调整输出格式
engine=> \dt+       # 查询 show tables
engine=> select * from vm_static where vm_name='jwang-rhel8-1';
-[ RECORD 1 ]------------------+-------------------------------------
vm_guid                        | 4dfc2a55-7942-4895-b83e-aa2d742b8a85
vm_name                        | jwang-rhel8-01

engine=> select * from vm_dynamic where vm_guid='4dfc2a55-7942-4895-b83e-aa2d742b8a85';
vm_guid                | 4dfc2a55-7942-4895-b83e-aa2d742b8a85
...
status                 | 4
...
pause_status           | 2

# 查询 describe table 
# https://www.postgresqltutorial.com/postgresql-administration/postgresql-describe-table/
SELECT 
   table_name, 
   column_name, 
   data_type 
FROM 
   information_schema.columns
WHERE 
   table_name = 'vm_dynamic';

engine=> update vm_dynamic set status=0, pause_status=0, exit_status=0 where vm_guid='4dfc2a55-7942-4895-b83e-aa2d742b8a85' ;

SELECT 
   table_name, 
   column_name, 
   data_type 
FROM 
   information_schema.columns
WHERE 
   table_name = 'vm_statistics';


SELECT 
   table_name, 
   column_name, 
   data_type 
FROM 
   information_schema.columns
WHERE 
   table_name = 'vms';

# https://www.ovirt.org/develop/developer-guide/db-issues/dbstructure.html
engine=> update vms set status=0 where vm_name='jwang-rhel8-01' ;

# https://soft-builder.com/how-to-list-views-in-postgresql-database/
SELECT table_schema, table_name 
FROM information_schema.views 
WHERE table_schema NOT IN ('information_schema', 'pg_catalog') 
ORDER BY table_schema, table_name 

engine=> \dv
engine=> \sv vms

# cat create_views.sql | grep "CREATE OR REPLACE VIEW vms AS" -A210 | grep status
    vm_dynamic.status AS status,
    vm_dynamic.pause_status AS pause_status,
    vm_dynamic.exit_status AS exit_status,
    vm_dynamic.guest_agent_status AS guest_agent_status,
  SELECT vm_id, COUNT(CASE imagestatus WHEN 4 THEN 1 END) > 0 AS has_illegal_images

# cd /usr/share/ovirt-engine/dbscripts/
# cat create_views.sql | grep "CREATE OR REPLACE VIEW vms AS" -A210 | grep host 
    fn_get_dedicated_hosts_ids_by_vm_id(vm_static.vm_guid) AS dedicated_vm_for_vds,
    vm_dynamic.vm_host AS vm_host,
    vm_static.host_cpu_flags AS host_cpu_flags,
# cat create_views.sql | grep "CREATE OR REPLACE VIEW vms AS" -A210 | grep run_on_vds_name
    vds_static.vds_name AS run_on_vds_name,
# 

engine=> select * from vm_dynamic where vm_guid='4dfc2a55-7942-4895-b83e-aa2d742b8a85' ;

engine=> update vm_dynamic set status=0 where vm_guid='4dfc2a55-7942-4895-b83e-aa2d742b8a85' ;
engine=> update vm_dynamic set pause_status=0 where vm_guid='4dfc2a55-7942-4895-b83e-aa2d742b8a85' ;
engine=> update vm_dynamic set exit_status=0 where vm_guid='4dfc2a55-7942-4895-b83e-aa2d742b8a85' ;

# cat create_views.sql | grep "CREATE OR REPLACE VIEW vms AS" -A210 | grep run_on_vds_name

engine=> update vm_dynamic set status=0, pause_status=0, exit_status=0, spice_ip=null, spice_tls_port=null, spice_port=null where vm_guid='4dfc2a55-7942-4895-b83e-aa2d742b8a85' ;



# 登陆运行虚拟机的节点
# systemctl restart vdsmd 
# 
```

### OpenShift 4.10环境中的Multus静态ip
https://www.cnblogs.com/ericnie/p/16301269.html<br>

### 地址分配器
https://www.adminsub.net/ipv4-subnet-calculator/192.168.122.140/30<br>

### UBI 以 root 用户安装 package，以 app-root 用户运行应用的例子
```
$ cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi8/python-36:latest
USER root
RUN yum update -y \
&& yum install -y \
bind-export-devel
USER app-root
CMD ["/usr/bin/myprogram"]
EOF

$ buildah bud -t localhost/ubi-python-custom:latest -f Dockerfile
```

### ACM and MCE must-gather
```
$ oc adm must-gather --image=registry.redhat.io/rhacm2/acm-must-gather-rhel8:v2.6.0 --dest-dir=<directory>

skopeo inspect docker://registry.redhat.io/rhacm2/acm-must-gather-rhel8:v2.6.1
...
    "Name": "registry.redhat.io/rhacm2/acm-must-gather-rhel8",
    "Digest": "sha256:a4d8cd60f217cde6fce606ecc726c72f111769905972882195ebcd5c5118350e",

$ oc adm must-gather --image=registry.redhat.io/rhacm2/acm-must-gather-rhel8@sha256:a4d8cd60f217cde6fce606ecc726c72f111769905972882195ebcd5c5118350e --dest-dir=/tmp
```

### 当 node-valid-hostname.service 机器的主机名因为某种原因改为 localhost 之后的处理方式
https://bugzilla.redhat.com/show_bug.cgi?id=2011378<br>
```
登陆到节点内，手工执行
$ hostnamectl set-hostname --transient master-0.ocp4-1.example.com

2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:78:9f:25 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.101/24 brd 192.168.122.255 scope global noprefixroute ens3
       valid_lft forever preferred_lft forever
    inet6 fe80::7ae7:8f76:6d77:5b5c/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
3: ens10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:b5:a9:ff brd ff:ff:ff:ff:ff:ff
4: ens11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:b6:69:fd brd ff:ff:ff:ff:ff:ff
    inet 192.168.8.187/24 brd 192.168.8.255 scope global dynamic noprefixroute ens11
       valid_lft 1953sec preferred_lft 1953sec
    inet6 fe80::efd:9306:728a:3379/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever

### 问题产生的原因是 ens11 自动获取了 ip 地址，导致 SNO 启动时 etcd 认为获取的 ip 地址与预期不符
### 解决的方法是，virsh net-edit openshift4，将 dhcp 段删掉
### virsh net-destroy openshift && virsh net-start openshift
### 重启后 SNO 恢复正常

```

### IoT Gateway Data View
```
https://thingsboard.io/docs/iot-gateway/what-is-iot-gateway/
```

### disable ipv6 in rhel8
https://linuxconfig.org/redhat-8-enable-disable-ipv6<br>
```
sysctl -w net.ipv6.conf.all.disable_ipv6=1
```

### 连接 VPN
```
### 更新 RHEL 
$ leapp preupgrade
### 修正检查问题
### https://access.redhat.com/solutions/6139192
$ leapp upgrade 

# 启用 EPEL 仓库
$ dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

# 安装 VPN 相关软件包
$ dnf install -y NetworkManager-openvpn.x86_64
$ dnf install -y /home/jwang/redhat-internal-cert-install-0.1-28.el7.noarch.rpm
$ dnf install -y /home/jwang/redhat-internal-NetworkManager-openvpn-profiles-non-gnome-0.1-55.el7.noarch.rpm

# 设置 vpn username 
$ nmcli connection modify '1 - Red Hat Global VPN' vpn.user-name my_usernmame
$ nmcli connection up '1 - Red Hat Global VPN' --ask

# kube
https://access.redhat.com/solutions/6708151


### microshift mirror initial registry
cat > /etc/containers/registries.conf.d/99-miroshift-mirror-by-digest-registries.conf << EOF
[[registry]]
  prefix = ""
  location = "quay.io/openshift-release-dev"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/openshift-release-dev"

[[registry]]
  prefix = ""
  location = "quay.io/rh-storage-partners"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rh-storage-partners"

[[registry]]
  prefix = ""
  location = "registry.access.redhat.com/ubi8"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/ubi8"

[[registry]]
  prefix = ""
  location = "registry.redhat.io/rhacm2"
  mirror-by-digest-only = true
 
  [[registry.mirror]]
    location = "registry.example.com:5000/rhacm2"
EOF
```

### 查看 OpenShift 网络配置情况
```
$ oc get network.operator.openshift.io cluster -o yaml
```

### Mac OS - Download full installer 
https://github.com/scriptingosx/DownloadFullInstaller/releases
```
$ softwareupdate --fetch-full-installer --full-installer-version 13.3.1
```

### microshift 添加第二块网卡配置
```
### 设置网卡 enp8s0 kickstart
### 这块网卡启用但是不设置 ipv4 和 ipv6
network --activate --device=enp8s0 --noipv4 --noipv6
```

### microshift 其他网卡禁用 ipv4 和 ipv6
```
$ nmcli c mod 'Wired connection 1' ipv4.method 'disabled' 
$ nmcli c mod 'Wired connection 1' ipv6.method 'disabled' 
$ nmcli c mod 'Wired connection 2' ipv4.method 'disabled' 
$ nmcli c mod 'Wired connection 2' ipv6.method 'disabled' 
```

### 执行 podman 容器的安全建议 
```
### 基本参数
podman run --userns=auto 
### 增强参数
--cap-drop=all --no-new-privs

```

### GCloud in macos
https://jansutris10.medium.com/install-google-cloud-sdk-using-homebrew-on-mac-2952c9c7b5a1

### 登录 master 节点，签名证书
```
$ oc --kubeconfig=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-int.kubeconfig get csr -o name | xargs oc --kubeconfig=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-int.kubeconfig adm certificate approve 

### 参考 solutions 里的步骤清理存储
### https://access.redhat.com/solutions/5350721
```

### ocp 测试程序
```
$ oc new-project test
$ oc new-app nodejs~https://github.com/vrutkovs/DuckHunt-JS

### 创建虚拟化用的 NNCP 
### NNCP - NodeNetworkConfigurationPolicy
$ cat << EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: br1-enp3s0-policy-workers
spec:
  nodeSelector:
    node-role.kubernetes.io/worker: ""
  desiredState:
    interfaces:
      - name: br1
        description: Linux bridge with enp3s0 as a port
        type: linux-bridge
        state: up
        ipv4:
          enabled: false
        bridge:
          options:
            stp:
              enabled: false
          port:
            - name: enp3s0
EOF

$ oc get nncp -A
$ oc get nnce -A

$ oc debug node/ocp4-worker1.aio.example.com -- chroot /host ip link show dev enp3s0
$ oc debug node/ocp4-worker1.aio.example.com -- chroot /host nmcli conn show

# 创建 net-attach-def tuning-bridge-fixed 
$ cat << EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: tuning-bridge-fixed
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br1
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "groot",
    "plugins": [
      {
        "type": "cnv-bridge",
        "bridge": "br1"
      },
      {
        "type": "tuning"
      }
    ]
  }'
EOF

$ cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  annotations:
    name.os.template.kubevirt.io/rhel8: Red Hat Enterprise Linux 8.0
  labels:
    app: rhel8-server-ocs
    kubevirt.io/os: rhel8
    os.template.kubevirt.io/rhel8: 'true'
    template.kubevirt.ui: openshift_rhel8-generic-small
    vm.kubevirt.io/template: openshift_rhel8-generic-small
    workload.template.kubevirt.io/generic: 'true'
  name: rhel8-server-ocs
spec:
  running: true
  template:
    metadata:
      labels:
        vm.kubevirt.io/name: rhel8-server-ocs
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
          - disk:
              bus: sata
            name: rhel8-ocs
          interfaces:
          - bridge: {}
            model: e1000
            name: tuning-bridge-fixed
        firmware:
          uuid: 5d307ca9-b3ef-428c-8861-06e72d69f223
        machine:
          type: q35
        resources:
          requests:
            memory: 1024M
      evictionStrategy: LiveMigrate
      networks:
        - multus:
            networkName: tuning-bridge-fixed
          name: tuning-bridge-fixed
      terminationGracePeriodSeconds: 0
      volumes:
      - name: rhel8-ocs
        persistentVolumeClaim:
          claimName: rhel8-ocs
EOF

$ oc get vm
$ oc get vmi
$ oc exec -it virt-launcher-rhel8-server-ocs-krz4q -- virsh list --all
$ oc exec -it virt-launcher-rhel8-server-ocs-krz4q -- virsh domblklist default_rhel8-server-ocs
$ oc exec -it virt-launcher-rhel8-server-ocs-krz4q -- lsblk /dev/rhel8-ocs
$ oc exec -it virt-launcher-rhel8-server-ocs-krz4q -- virsh domiflist default_rhel8-server-ocs
$ oc exec -it virt-launcher-rhel8-server-ocs-krz4q -- ip link show dev tap1
$ oc exec -it virt-launcher-rhel8-server-ocs-krz4q -- ip link | grep -A2 k6t-net1
$ oc exec -it virt-launcher-rhel8-server-ocs-krz4q -- virsh dumpxml default_rhel8-server-ocs | grep -A8 "interface type"

$ oc debug node/ocp4-worker1.aio.example.com
$ oc exec -it virt-launcher-rhel8-server-ocs-krz4q -- ip -o link | grep ^174: | sed -n -e 's/.*\(veth[[:alnum:]]*@if[[:digit:]]*\).*/\1/p'


[~] $ ip link | grep -A2 k6t-net1
[~] $ oc exec -it virt-launcher-rhel8-server-ocs-krz4q -- ip link | grep -A2 k6t-net1
4: net1@if174: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master k6t-net1 state U
P mode DEFAULT group default
    link/ether 7e:61:49:7d:a5:cf brd ff:ff:ff:ff:ff:ff link-netnsid 0
5: k6t-net1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT gro
up default
    link/ether 2a:fb:cb:4f:12:af brd ff:ff:ff:ff:ff:ff
6: tap1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master k6t-net1 state UP mod
e DEFAULT group default qlen 1000
    link/ether 2a:fb:cb:4f:12:af brd ff:ff:ff:ff:ff:ff
[~] $ oc exec -it virt-launcher-rhel8-server-ocs-krz4q -- virsh dumpxml default_rhel8-server-oc
s | grep -A8 "interface type"
    <interface type='ethernet'>
      <mac address='02:b4:ab:00:00:00'/>
      <target dev='tap1' managed='no'/>
      <model type='e1000'/>
      <mtu size='1500'/>
      <alias name='ua-tuning-bridge-fixed'/>
      <rom enabled='no'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x01' function='0x0'/>
    </interface>

[~] $ oc get vmi
NAME               AGE    PHASE     IP               NODENAME                       READY
rhel8-server-ocs   106m   Running   192.168.123.64   ocp4-worker1.aio.example.com   True
[~] $ oc debug node/ocp4-worker1.aio.example.com
Temporary namespace openshift-debug-69t67 is created for debugging node...
Starting pod/ocp4-worker1aioexamplecom-debug ...
To use host binaries, run `chroot /host`
Pod IP: 192.168.123.104
If you don't see a command prompt, try pressing enter.
sh-4.4# chroot /host
sh-4.4# export ifindex=174
sh-4.4# ip -o link | grep ^$ifindex: | sed -n -e 's/.*\(veth[[:alnum:]]*@if[[:digit:]]*\).*/\1/
''
veth66ff3281@if4
sh-4.4# ip link show veth66ff3281
174: veth66ff3281@if4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br1 stat
e UP mode DEFAULT group default
    link/ether 62:14:f4:eb:34:47 brd ff:ff:ff:ff:ff:ff link-netns 433a64e1-85df-40be-9c7e-8ed1c
0d707b2

$ oc describe vmi rhel8-server-ocs | egrep '(Eviction|Migration)'
$ cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-job
spec:
  vmiName: rhel8-server-ocs
EOF

$ oc get virtualmachineinstancemigration/migration-job -o yaml

$ cat << EOF | oc apply -f -
apiVersion: nodemaintenance.medik8s.io/v1beta1
kind: NodeMaintenance
metadata:
  name: worker-maintenance
spec:
  nodeName: ocp4-worker3.aio.example.com
  reason: "Worker Maintenance"
EOF

$ virt-customize -a /var/www/html/Fedora-Cloud-Base-34-1.2.x86_64.raw --uninstall=cloud-init --root-password password:NOT_REAL_PASSWORD --ssh-inject root:file:/root/.ssh/id_rsa.pub

$ cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "fc34-original"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "http://192.168.123.100:81/Fedora-Cloud-Base-34-1.2.x86_64.raw"
spec:
  volumeMode: Block
  storageClassName: ocs-storagecluster-ceph-rbd
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 40Gi
EOF

$ cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: fc34-original
  labels:
    app: fc34-original
    os.template.kubevirt.io/fedora34: 'true'
    vm.kubevirt.io/template-namespace: openshift
    workload.template.kubevirt.io/server: 'true'
spec:
  running: true
  template:
    metadata:
      labels:
        vm.kubevirt.io/name: fc34-original
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
            - bootOrder: 1
              disk:
                bus: virtio
              name: disk0
          interfaces:
            - bridge: {}
              model: virtio
              name: nic0
          networkInterfaceMultiqueue: true
          rng: {}
        machine:
          type: pc-q35-rhel8.1.0
        resources:
          requests:
            memory: 1024M
      evictionStrategy: LiveMigrate
      hostname: fc34-original
      networks:
        - multus:
            networkName: tuning-bridge-fixed
          name: nic0
      terminationGracePeriodSeconds: 0
      volumes:
        - name: disk0
          persistentVolumeClaim:
            claimName: fc34-original
EOF

$ dnf install podman -y

$ cat >> /etc/systemd/system/nginx.service << EOF
[Unit]
Description=Nginx Podman container
Wants=syslog.service
[Service]
ExecStart=/usr/bin/podman run --net=host quay.io/roxenham/nginxdemos:plain-text
ExecStop=/usr/bin/podman stop --all
[Install]
WantedBy=multi-user.target
EOF

$ systemctl daemon-reload && systemctl enable --now nginx
$ systemctl status nginx

$ logout
$ oc whoami
$ curl http://192.168.123.65

$ oc get vm ; oc get vmi
$ virtctl stop fc34-original
$ oc get vm

$ cat << EOF | oc apply -f -
apiVersion: cdi.kubevirt.io/v1alpha1
kind: DataVolume
metadata:
  name: fc34-clone
spec:
  source:
    pvc:
      namespace: default
      name: fc34-original
  pvc:
    volumeMode: Block
    storageClassName: ocs-storagecluster-ceph-rbd
    accessModes:
      - ReadWriteMany
    resources:
      requests:
        storage: 40Gi
EOF

[~] $ oc get datavolume fc34-clone
NAME         PHASE                             PROGRESS   RESTARTS   AGE
fc34-clone   SnapshotForSmartCloneInProgress                         19s

[~] $ oc get pvc/fc34-clone
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STOR
AGECLASS                  AGE
fc34-clone   Bound    pvc-07c1ec4c-48db-4d4c-920b-89b19625ffbe   40Gi       RWX            ocs-
storagecluster-ceph-rbd   30s

$ cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: fc34-clone
  labels:
    app: fc34-clone
    os.template.kubevirt.io/fedora34: 'true'
    vm.kubevirt.io/template-namespace: openshift
    workload.template.kubevirt.io/server: 'true'
spec:
spec:
  running: true
  template:
    metadata:
      labels:
        vm.kubevirt.io/name: fc34-clone
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
            - bootOrder: 1
              disk:
                bus: virtio
              name: disk0
          interfaces:
            - bridge: {}
              model: virtio
              name: nic0
          networkInterfaceMultiqueue: true
          rng: {}
        machine:
          type: pc-q35-rhel8.1.0
        resources:
          requests:
            memory: 2Gi
      evictionStrategy: LiveMigrate
      hostname: fc34-clone
      networks:
        - multus:
            networkName: tuning-bridge-fixed
          name: nic0
      terminationGracePeriodSeconds: 0
      volumes:
        - name: disk0
          persistentVolumeClaim:
            claimName: fc34-clone
EOF

$ oc delete vm/fc34-clone pvc/fc34-clone

$ cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  name: fc34-podnet
  labels:
    app: fc34-podnet
    os.template.kubevirt.io/fedora34: 'true'
    vm.kubevirt.io/template-namespace: openshift
    workload.template.kubevirt.io/server: 'true'
spec:
  running: true
  template:
    metadata:
      labels:
        vm.kubevirt.io/name: fc34-podnet
        flavor.template.kubevirt.io/small: 'true'
        kubevirt.io/size: small
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
            - bootOrder: 1
              disk:
                bus: virtio
              name: disk0
          interfaces:
            - name: nic0
              model: virtio
              masquerade: {}
          networkInterfaceMultiqueue: true
          rng: {}
        machine:
          type: pc-q35-rhel8.1.0
        resources:
          requests:
            memory: 2Gi
      evictionStrategy: LiveMigrate
      hostname: fc34-podnet
      networks:
        - name: nic0
          pod: {}
      terminationGracePeriodSeconds: 0
      volumes:
        - name: disk0
          persistentVolumeClaim:
            claimName: fc34-original
EOF

$ oc describe pod/virt-launcher-fc34-podnet-tf5f2 | grep -A 9 networks-status
                  k8s.v1.cni.cncf.io/networks-status:
                    [{
                        "name": "openshift-sdn",
                        "interface": "eth0",
                        "ips": [
                            "10.129.2.62"
                        ],
                        "default": true,
                        "dns": {}
                    }]

$ virtctl expose virtualmachineinstance fc34-podnet --name fc34-service --port 80
$ oc get svc/fc34-service
$ oc create route edge --service=fc34-service
$ oc get routes

$ oc project openshift-virtualization-os-images
$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "centos8"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "http://192.168.123.100:81/rhel8-kvm.img"
spec:
  volumeMode: Block
  storageClassName: ocs-storagecluster-ceph-rbd
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
EOF


[/tmp] $ oc -n openshift-cnv logs virt-controller-8b759d65-2ms9f | grep -Ev "info"
...
{"component":"virt-controller","kind":"","level":"error","msg":"Updating api version annotation
s failed","name":"mongodb-nationalparks","namespace":"parksmap-demo","pos":"vm.go:254","reason"
:"Operation cannot be fulfilled on virtualmachines.kubevirt.io \"mongodb-nationalparks\": the o
bject has been modified; please apply your changes to the latest version and try again","timest
amp":"2023-05-17T07:34:49.050997Z","uid":"051bee5d-2807-492f-87a5-2bf8ff9d1347"}
{"component":"virt-controller","kind":"","level":"error","msg":"Updating api version annotation
s failed","name":"mongodb-nationalparks","namespace":"parksmap-demo","pos":"vm.go:254","reason"
:"Operation cannot be fulfilled on virtualmachines.kubevirt.io \"mongodb-nationalparks\": the o
bject has been modified; please apply your changes to the latest version and try again","timest
amp":"2023-05-17T07:34:49.105350Z","uid":"051bee5d-2807-492f-87a5-2bf8ff9d1347"}
...

{"component":"virt-controller","kind":"","level":"error","msg":"Updating api version annotation
s failed","name":"mongodb-nationalparks","namespace":"parksmap-demo","pos":"vm.go:254","reason"
:"Operation cannot be fulfilled on virtualmachines.kubevirt.io \"mongodb-nationalparks\": the o
bject has been modified; please apply your changes to the latest version and try again","timest
amp":"2023-05-17T07:34:49.050997Z","uid":"051bee5d-2807-492f-87a5-2bf8ff9d1347"}
{"component":"virt-controller","kind":"","level":"error","msg":"Updating api version annotation
s failed","name":"mongodb-nationalparks","namespace":"parksmap-demo","pos":"vm.go:254","reason"
:"Operation cannot be fulfilled on virtualmachines.kubevirt.io \"mongodb-nationalparks\": the o
bject has been modified; please apply your changes to the latest version and try again","timest
amp":"2023-05-17T07:34:49.105350Z","uid":"051bee5d-2807-492f-87a5-2bf8ff9d1347"}

[/tmp] $ oc get datavolume mongodb-mlbparks-rootdisk -o yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  annotations:
    cdi.kubevirt.io/cloneType: ""
    cdi.kubevirt.io/storage.clone.token: eyJhbGciOiJQUzI1NiJ9.eyJleHAiOjE2ODQzMTA2MjgsImlhdCI6M
TY4NDMxMDMyOCwiaXNzIjoiY2RpLWFwaXNlcnZlciIsIm5hbWUiOiJjZW50b3M4IiwibmFtZXNwYWNlIjoib3BlbnNoaWZ0
LXZpcnR1YWxpemF0aW9uLW9zLWltYWdlcyIsIm5iZiI6MTY4NDMxMDMyOCwib3BlcnRhdGlvbiI6IkNsb25lIiwicGFyYW1
zIjp7InRhcmdldE5hbWUiOiJtb25nb2RiLW1sYnBhcmtzLXJvb3RkaXNrIiwidGFyZ2V0TmFtZXNwYWNlIjoicGFya3NtYX
AtZGVtbyJ9LCJyZXNvdXJjZSI6eyJncm91cCI6IiIsInJlc291cmNlIjoicGVyc2lzdGVudHZvbHVtZWNsYWltcyIsInZlc
nNpb24iOiJ2MSJ9fQ.mjXueZFnTSmW3FORjVBpNwYsPAsfqED5v1h1356SXkzIaQQweZ12ZPiNre7j6XWVo-rw4rQELXLDM
mQz5b-7_QPnVhLQc_gA33BUaBNng6q7wWi8wxusWIbqOmM5DOYDiSjA8LpXtMSgXEbv0K-3Odw3UyYC9iLN8fT49Xah4cgJ
DrMNZXovD4cKakWGW7rz8GSW6o-VU6cB-0YGrP4w0shUwMnSPQZw-5F1cwojgr8EjVbcsgMhJDSAFGINy-fv5rjJjD9_Cu1
4xXI8vTvEj_aJIhWgrvwlwornCWXvdrSwwnWt2lsvFXWSq5P87GQ0fA1FXXYt-bedx1gRUeO4zA
    cdi.kubevirt.io/storage.deleteAfterCompletion: "true"
  creationTimestamp: "2023-05-17T07:58:48Z"
  generation: 2
  labels:
    kubevirt.io/created-by: dbae7168-483e-4b3b-877f-fffed28b6724
  name: mongodb-mlbparks-rootdisk
  namespace: parksmap-demo
  ownerReferences:
  - apiVersion: kubevirt.io/v1
    blockOwnerDeletion: true
    controller: true
    kind: VirtualMachine
    name: mongodb-mlbparks
    uid: dbae7168-483e-4b3b-877f-fffed28b6724
  resourceVersion: "1638388"
  uid: bf88fca3-1742-439c-a6b4-ac08b0aa500d
spec:
  pvc:
    accessModes:
    - ReadWriteMany
    resources:
      requests:
        storage: 20Gi
    storageClassName: ocs-storagecluster-ceph-rbd
    volumeMode: Block
  source:
    pvc:
      name: centos8
      namespace: openshift-virtualization-os-images
status:
  conditions:
  - lastHeartbeatTime: "2023-05-17T07:58:48Z"
    lastTransitionTime: "2023-05-17T07:58:48Z"
    message: No PVC found
    reason: CloneWithoutSource
    status: Unknown
    type: Bound
  - lastHeartbeatTime: "2023-05-17T07:58:48Z"
    lastTransitionTime: "2023-05-17T07:58:48Z"
    reason: CloneWithoutSource
    status: "False"
    type: Ready
  - lastHeartbeatTime: "2023-05-17T07:58:48Z"
    lastTransitionTime: "2023-05-17T07:58:48Z"
    status: "False"
    type: Running


cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "centos8"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "http://192.168.123.100:81/rhel8-kvm.img"
spec:
  volumeMode: Block
  storageClassName: ocs-storagecluster-ceph-rbd
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
EOF

``` 

### FreeBSD 文件系统 ZFS resize
https://help.ovhcloud.com/csm/en-ie-public-cloud-compute-freebsd-resize-file-system?id=kb_article_view&sysparm_article=KB0051099<br>
https://docs.openstack.org/image-guide/freebsd-image.html<br>
```
### FreeBSD 下载地址
http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/ISO-IMAGES/12.4/


cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "freebsd"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "http://192.168.123.100:81/freebsd-disk0.raw"
spec:
  volumeMode: Block
  storageClassName: ocs-storagecluster-ceph-rbd
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
EOF

### https://kubevirt.io/user-guide/virtual_machines/interfaces_and_networks/
$ cat << EOF | oc apply -f -
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  labels:
    app: freebsd
    workload.template.kubevirt.io/generic: 'true'
  name: freebsd
spec:
  running: true
  template:
    metadata:
      labels:
        vm.kubevirt.io/name: freebsd
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
          - disk:
              bus: sata
            name: freebsd
          interfaces:
            - name: nic0
              model: rtl8139
              masquerade: {}
        firmware:
          uuid: 5d307ca9-b3ef-428c-8861-06e72d69f223
        machine:
          type: q35
        resources:
          requests:
            memory: 1024M
      evictionStrategy: LiveMigrate
      networks:
        - name: nic0
          pod: {}
      terminationGracePeriodSeconds: 0
      volumes:
      - name: freebsd
        persistentVolumeClaim:
          claimName: freebsd
EOF

### PCI-Passthrough
### https://docs.openshift.com/container-platform/4.12/virt/virtual_machines/advanced_vm_management/virt-configuring-pci-passthrough.html

### Config DHCP in FreeBSD
https://www.serverlab.ca/tutorials/unix/how-to-set-static-ip-and-dhcp-in-freebsd/
https://github.com/kubevirt/kubevirt/issues/2942

### 重新配置网络

$ cat > /etc/rc.conf <<EOF
...
ifconfig_vtnet0="inet 192.168.1.60 netmask 255.255.255.0"
defaultrouter="192.168.1.101"
...
ifconfig_re0="inet 192.168.122.161 netmask 255.255.255.0"
defaultrouter="192.168.122.1"
...
EOF

$ cat > /etc/resolv.conf <<EOF
nameserver 172.30.0.10
EOF

### 重启网络
$ service netif restart
$ service routing restart

### 手工设置 default route
$ route del default
$ route add default 192.168.122.1

### install freebsd ports
https://docs.freebsd.org/en/books/handbook/ports/#ports-using-git-method
$ pkg install git
$ git clone https://git.FreeBSD.org/ports.git /usr/ports
or 
$ git clone https://git.FreeBSD.org/ports.git -b 2023Q1 /usr/ports
$ git -C /usr/ports pull
or
$ git -C /usr/ports switch 2023Q1

$ cd /usr/ports/sysutils/sysinfo
$ make install 

### 安装 sysinfo package
$ pkg install sysinfo
$ pkg info -l sysinfo

### 添加 bsd-cloudinit
https://community.ops.io/jmarhee/preparing-a-freebsd-cloud-image-with-cloud-init-22lh
https://docs.openstack.org/image-guide/freebsd-image.html
https://www.cyberciti.biz/faq/how-to-add-delete-grant-sudo-privileges-to-users-on-freebsd-unix-server/
https://bsd-cloud-image.org/

$ pkg install ca_root_nss
$ fetch --ca-cert=/usr/local/share/certs/ca-root-nss.crt \
  https://raw.github.com/pellaeon/bsd-cloudinit-installer/master/installer.sh
$ sh ./installer.sh
$ pkg install sudo
$ echo 'freebsd ALL=(ALL) NOPASSWD: ALL' > /usr/local/etc/sudoers.d/10-cloudinit
$ shutdown -h now

### freebsd 检查内核模块
https://unixdesk.wordpress.com/2006/01/25/loading-kernel-modules-in-freebsd/

### freebsd 添加 virtio 驱动支持
### 编辑 /boot/loader.conf 文件添加

virtio_load="YES"
virtio_pci_load="YES"
virtio_blk_load="YES"
if_vtnet_load="YES"
virtio_balloon_load="YES" 

### 增加 pc-i440fx-rhel7.6.0 机器格式支持
https://github.com/RHsyseng/cnv-supplemental-templates/tree/main/templates/pc-i440fx
$ oc annotate --overwrite -n openshift-cnv hco kubevirt-hyperconverged kubevirt.kubevirt.io/jsonpatch='[{"op": "add", "path": "/spec/configuration/emulatedMachines", "value": ["q35*", "pc-q35*", "pc-i440fx-rhel7.6.0"] }]'

```

### TPM and Trusted Boot
https://fedoraproject.org/wiki/Tboot<br>
https://next.redhat.com/2021/05/13/what-can-you-do-with-a-tpm/<br>
https://www.intel.com/content/www/us/en/developer/articles/tool/intel-trusted-execution-technology.html<br>
https://lenovopress.lenovo.com/lp0599.pdf<br>
```

```

### OpenShift Helm Charts
https://github.com/openshift-helm-charts/charts<br>
```
$ helm repo add openshift-helm-charts https://charts.openshift.io/
$ helm search repo openshift-helm-charts
$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm search repo bitnami

### 创建 test project，设置 rolebinding
$ oc new-project test
$ helm install wordpress bitnami/wordpress 
$ helm list

$ cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: system:openshift:scc:privileged
  namespace: test
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:openshift:scc:privileged
subjects:
- kind: ServiceAccount
  name: wordpress-mariadb
  namespace: test
EOF

$ cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: system:openshift:scc:privileged
  namespace: test
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:openshift:scc:privileged
subjects:
- kind: ServiceAccount
  name: default
  namespace: test
EOF

$ cat > value.yaml <<EOF
containerSecurityContext:
  enabled: false
mariadb:
  primary:
    containerSecurityContext:
      enabled: false
    podSecurityContext:
      enabled: false
  serviceAccount:
    create: false
memcached:
  containerSecurityContext:
    enabled: false
  podSecurityContext:
    enabled: false
podSecurityContext:
  enabled: false
wordpressPassword: S39BKWjSkh
EOF

$ oc patch statefulset/wordpress-mariadb --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}"  

$ oc patch deployment/wordpress --patch \
   "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"last-restart\":\"`date +'%s'`\"}}}}}" 
```

### 运行 FastChat
https://github.com/lm-sys/FastChat<br>
https://www.linkedin.com/pulse/step-by-step-guide-running-vicuna-13b-large-language-nischal/<br>
https://aistudio.baidu.com/aistudio/index<br>
```
### 如何在本地运行 FastChat
### https://www.linkedin.com/pulse/step-by-step-guide-running-vicuna-13b-large-language-nischal/

### 别人做好的镜像
### https://blog.csdn.net/u010095372/article/details/130376651
$ conda activate vinuca
$ python -m fastchat.serve.cli --model-name anon8231489123/vicuna-13b-GPTQ-4bit-128g --wbits 4 --groupsize 128 --low-cpu-mem
$ python -m fastchat.serve.cli --model-name anon8231489123/vicuna-13b-GPTQ-4bit-128g --wbits 4 --groupsize 128

### 探索运行 FastChat
$ cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
RUN dnf install -y python39 libpciaccess iproute net-tools procps-ng nmap-ncat iputils diffutils git && dnf clean all 
CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF
$ podman build -f Dockerfile -t registry.example.com:5000/fastchat/fastchat:v1
$ podman run -d -t --name fastchat-v1 --network host --privileged registry.example.com:5000/fastchat/fastchat:v1

$ podman exec -it fastchat-v1 bash
$ pip install fastchat
$ mkdir -p /code/model
### 拷贝 LLaMA weights 到容器中
### LLaMA 7B weights 文件内容
LLaMA/
├── 7B
│   ├── checklist.chk
│   ├── consolidated.00.pth
│   └── params.json
├── llama.sh
├── tokenizer_checklist.chk
└── tokenizer.model
### 在容器外执行
$ podman cp LLaMA fastchat-v1:/code/model
### 回到容器内
$ cd ~
$ git clone https://github.com/lm-sys/FastChat


### 从 llama weights 转换为 huggingface 格式
$ git clone https://github.com/huggingface/transformers.git
$ cd transformers
### 需要设置参数 PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
$ PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python python3 ./src/transformers/models/llama/convert_llama_weights_to_hf.py  --input_dir /code/model/LLaMA --model_size 7B --output_dir /code/model/transformer_model_7b
dir /code/model/transformer_model_7b
Fetching all parameters from the checkpoint at /code/model/LLaMA/7B.
Loading the checkpoint in a Llama model.
Loading checkpoint shards: 100%|██████████████████████████████████████████████████████████████████████████████████████████████| 33/33 [00:17<00:00,  1.92it/s]
Saving in the Transformers format.
Saving a LlamaTokenizerFast to /code/model/transformer_model_7b.

### 克隆 vicuna-7b-delta-v1.1
$ cd ~
### 在 fastchat.model.apply_delta 时遇到报错
### 参考：https://github.com/THUDM/ChatGLM-6B/issues/770
### https://git-lfs.com/
### 首先安装 git-lfs 
### 尝试解决 sha256 不一致的问题
$ curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | bash
$ yum install git-lfs
$ git lfs install
$ git clone https://huggingface.co/lmsys/vicuna-7b-delta-v1.1
### 需要在一个内存大机器上运行
### 测试环境下，内存不足
### 用 podman-export, podman-import 的方式将容器从一台机器迁移到另外一台机器上
### $ cd /tmp; podman export -o fastchat-v1.tar fastchat-v1 ; scp /tmp/fastchat-v1.tar <dst>:/tmp
### 在目标机器上
### $ cd /tmp; cat fastchat-v1.tar | podman import -
### $ podman images
REPOSITORY                      TAG      IMAGE ID       CREATED             SIZE
<none>                          <none>   78d372e369d2   About an hour ago   61.8 GB
### $ podman tag 78d372e369d2 registry.example.com:5000/fastchat/fastchat:v1
### $ podman images
REPOSITORY                                    TAG      IMAGE ID       CREATED             SIZE
registry.example.com:5000/fastchat/fastchat   v1       78d372e369d2   About an hour ago   61.8 GB
### $ podman run --name fastchat-v1 -dt --network host --privileged registry.example.com:5000/fastchat/fastchat:v1 /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'
$ python3 -m fastchat.model.apply_delta --base-model-path /code/model/transformer_model_7b --target-model-path /code/model/vicuna_7b --delta-path /root/vicuna-7b-delta-v1.1
Loading the delta weights from /root/vicuna-7b-delta-v1.1
Loading checkpoint shards: 100%|████████████████████████████████████████████████████████████████████████████████████████████████| 2/2 [00:11<00:00,  5.84s/it]
Loading the base model from /code/model/transformer_model_7b
Loading checkpoint shards: 100%|████████████████████████████████████████████████████████████████████████████████████████████████| 2/2 [00:12<00:00,  6.44s/it]
Applying the delta
Applying delta: 100%|███████████████████████████████████████████████████████████████████████████████████████████████████████| 323/323 [00:04<00:00, 64.98it/s]
Saving the target model to /code/model/vicuna_7b
### 用 cpu 跑一下模型 
$ python3 -m fastchat.serve.cli --model-path /code/model/vicuna_7b --device cpu 

### 克隆 FastChat
### https://github.com/lm-sys/FastChat
$ cd ~
$ git clone https://github.com/lm-sys/FastChat
$ cd FastChat
### 补充运行 Web 的缺失依赖
### gradio_web_server 'ModuleNotFoundError: Linkify enabled but not installed'
$ pip3 install --upgrade pip
$ pip3 install -e .

### 启动 controller
$ cd ~
$ python3 -m fastchat.serve.controller & 
### 启动 worker
$ python3 -m fastchat.serve.model_worker --model-path /code/model/vicuna_7b --device cpu &
### 启动 webserver
$ python3 -m fastchat.serve.gradio_web_server &

### 访问 <ip>:7860 端口

### vicuna + langchain-MRKL
### https://github.com/rinnakk/vicuna-13b-delta-finetuned-langchain-MRKL/blob/main/demo.ipynb

### Oobabooga on Fedora 38
### 来自 Doug Smith 的文章
### https://hackmd.io/@dougbtv/ry5kSSqV3
### https://github.com/RedTopper/Text-Generation-Webui-Podman


### 在 RHEL8 上如何支持 NVIDIA GPU
### https://www.redhat.com/en/blog/how-use-gpus-containers-bare-metal-rhel-8

### 还是 LangChain 与 VectorDB 相关的话题
### Building an LLM open source search engine in 100 lines using LangChain and Ray
### https://www.anyscale.com/blog/llm-open-source-search-engine-langchain-ray

### LangChain 与 Chroma Vector DB 
### https://blog.langchain.dev/langchain-chroma/

### 向量数据库
### embeddings - 文本数据的数字化表达
### https://js.langchain.com/docs/modules/indexes/vector_stores/
### https://github.com/chroma-core/chroma

### LLAMA GPT4ALL
### https://towardsai.net/p/machine-learning/llama-gpt4all-simplified-local-chatgpt
### https://www.together.xyz/blog/redpajama-7b

### 什么是Prompt
### https://blog.csdn.net/weixin_41429382/article/details/129964279

### 查询 node 可分配资源
$ oc get node/$node -o jsonpath='{.status.allocatable}'
### 查询 NVIDIA GPU 
$ kubectl exec -n nvidia-gpu-operator nvidia-driver-daemonset-xxxxxxx -- nvidia-smi
### PromQL - 查询哪些 pod 申请 GPU 资源
kube_pod_container_resource_requests{job="kube-state-metrics", cluster="", resource="nvidia_com_gpu"}

### 如何将 openshift project 设置为 RHODS project 
$ oc login with user with admin permissions (needed to add labels)
$ oc new-project test-sample-enabled
### RHODS Dashboard 检查这个 label
$ oc label namespace test-sample-enabled opendatahub.io/dashboard=true
### ModelMesh Controller 检查这个 label
$ oc label namespace test-sample-enabled modelmesh-enabled=true

### End of Life Date 
### https://endoflife.date/
### 拷贝 aliyun-2 的磁盘
$ qemu-img convert -p -f qcow2 -O qcow2 aliyun_2_1903_x64_20G_nocloud_alibase_20230103.qcow2 jwang-aliyun2-1.qcow2
### 设置口令
### $ virt-customize -a jwang-aliyun2-1.qcow2 --root-password password:xxxxxxxx --uninstall cloud-init
$ virt-install --name jwang-aliyun2-1 \
    --ram 8192 --vcpus 4 --os-variant rhel7 \
    --cpu host,+vmx \
    --network network:default \
    --boot cdrom,hd,network,menu=on \
    --noautoconsole --vnc \
    --disk path=/data/kvm/jwang-aliyun2-1.qcow2,device=disk,bus=virtio,format=qcow2 \
    --dry-run --print-xml > /tmp/jwang-aliyun2-1.xml;
$ virsh define /tmp/jwang-aliyun2-1.xml

### 启用 epel - 安装 cloud-utils 软件包
$ yum install -y cloud-utils-growpart

### 禁用 cloud-init
### https://cloudinit.readthedocs.io/en/latest/howto/disable_cloud_init.html
### 如果不禁用 cloud-init
### 可以用 cloud-utils 生成 seed.img
### 为 cloud-init 提供所需的 meta-data 和 user-data
### guestfish 的用法参见
### https://rwmj.wordpress.com/2011/01/06/tip-replace-text-strings-in-a-file-using-guestfish/
### Hypervisor 上配置静态 ip 地址
$ cat > /tmp/ifcfg-eth0 <<EOF
TYPE=Ethernet
IPADDR=192.168.122.171
PREFIX=24
GATEWAY=192.168.122.1
DNS1=192.168.122.1
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=eth0
DEVICE=eth0
ONBOOT=yes
EOF

$ guestfish -a jwang-aliyun2-1.qcow2
><fs> run
><fs> list-filesystem
><fs> mount /dev/sda1 /
><fs> touch /etc/cloud/cloud-init.disabled
><fs> ! sed 's/^PasswordAuthentication no/PasswordAuthentication yes/' /tmp/sshd_config > /tmp/sshd_config.new
><fs> upload /tmp/sshd_config.new /etc/ssh/sshd_config
><fs> upload /tmp/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0
><fs> umount /
><fs> exit

### convert2RHEL
### https://www.redhat.com/en/blog/introduction-convert2rhel-now-officially-supported-convert-rhel-systems-rhel
### https://access.redhat.com/articles/5941531
### https://access.redhat.com/articles/2360841
$ curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release https://www.redhat.com/security/data/fd431d51.txt
$ curl --create-dirs -o /etc/rhsm/ca/redhat-uep.pem https://ftp.redhat.com/redhat/convert2rhel/redhat-uep.pem
$ curl -o /etc/yum.repos.d/convert2rhel.repo https://ftp.redhat.com/redhat/convert2rhel/7/convert2rhel.repo
$ yum install -y convert2rhel

### 生成新的 /etc/os-release 和 /etc/alinux-release
$ cp /etc/os-release /etc/os-release.sav
$ cp /etc/alinux-release /etc/alinux-release.sav

$ cat > /etc/os-release <<EOF
NAME="CentOS Linux"
VERSION="7.9 (Core)"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="7.9"
PRETTY_NAME="CentOS Linux release 7.9 (Core)"
ANSI_COLOR="0;31"
EOF

$ cat > /etc/alinux-release <<EOF
CentOS Linux release 7.9.2009 (Core)
EOF

### 备份并移除其他 repo 
$ mkdir -p /etc/yum.repos.d/backup
$ mv /etc/yum.repos.d/AliYun.repo /etc/yum.repos.d/backup
$ mv /etc/yum.repos.d/epel*.repo /etc/yum.repos.d/backup

$ mkdir -p /repo
### 安装 CentOS Linux 7.9 kernel 
### 挂载 CentOS Linux 7.9 ISO 
$ mount /dev/sr0 /repo
$ cat > /etc/yum.repos.d/local.repo <<EOF
[rhel-7-rpms]
name=rhel-7-rpms
baseurl=file:///repo
enabled=1
gpgcheck=0
sslcacert=/etc/rhsm/ca/redhat-uep.pem
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF
### 安装 kernel
$ yum install -y kernel 
$ reboot 

### 挂载 RHEL 7.9 ISO
$ mount /dev/sr0 /repo
$ cat > /etc/yum.repos.d/local.repo <<EOF
[rhel-7-rpms]
name=rhel-7-rpms
baseurl=file:///repo
enabled=1
gpgcheck=1
sslcacert=/etc/rhsm/ca/redhat-uep.pem
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF

### 删除 geoipupdate 包
$ yum remove -y geoipupdate
### 等待未来再安装

### 按需处理一些第三方软件包
$ mkdir -p /var/lib/convert2rhel 

### 执行 convert2rhel 替换内核
$ CONVERT2RHEL_DISABLE_TELEMETRY=1 convert2rhel --no-rhsm --enablerepo rhel-7-rpms --no-rpm-va --debug -y 2>&1 | tee /tmp/err 

### 获取待替换第三方软件包
$ cat /tmp/err | grep al7 | grep -Ev "DEBUG" | sort -n > /tmp/pkg

### 重新安装 bind-license 和 bind-export-libs
$ N=''; cat /tmp/pkg | sort -u | grep '^32:' | awk '{print $1}'  | awk -F ":" '{print $2}'  | while read i  ; do  PACKAGENAME=$(rpm --queryformat=%{NAME} -q $i | grep -v 'not installed' ); N=${PACKAGENAME}" "${N}; if [ $? -eq 0 ]; then echo ; echo ; echo -n $N ; fi ;done 
$ yum downgrade -y bind-license bind-export-libs


### 重新安装 tcpdump 和 libpcap
$ N=''; cat /tmp/pkg | sort -u | grep '^14:' | awk '{print $1}'  | awk -F ":" '{print $2}'  | while read i  ; do  PACKAGENAME=$(rpm --queryformat=%{NAME} -q $i | grep -v 'not installed' ); N=${PACKAGENAME}" "${N}; if [ $? -eq 0 ]; then echo ; echo ; echo -n $N ; fi ;done
$ yum downgrade -y tcpdump libpcap


### 重新安装 dhcp-libs dhcp-common
$ N=''; cat /tmp/pkg | sort -u | grep '^12:' | awk '{print $1}'  | awk -F ":" '{print $2}'  | while read i  ; do  PACKAGENAME=$(rpm --queryformat=%{NAME} -q $i | grep -v 'not installed' ); N=${PACKAGENAME}" "${N}; if [ $? -eq 0 ]; then echo ; echo ; echo -n $N ; fi ;done
$ yum downgrade -y dhcp-libs dhcp-common dhclient

### 重新安装 device-mapper 和 lvm2
$ N=''; cat /tmp/pkg | sort -u | grep '^7:' | awk '{print $1}'  | awk -F ":" '{print $2}'  | while read i  ; do  PACKAGENAME=$(rpm --queryformat=%{NAME} -q $i | grep -v 'not installed' ); N=${PACKAGENAME}" "${N}; if [ $? -eq 0 ]; then echo ; echo ; echo -n $N ; fi ;done
$ yum downgrade -y lvm2-libs lvm2 device-mapper-libs device-mapper-event-libs device-mapper-event device-mapper

### 重新安装 perl 
$ N=''; cat /tmp/pkg | sort -u | grep '^4:' | awk '{print $1}'  | awk -F ":" '{print $2}'  | while read i  ; do  PACKAGENAME=$(rpm --queryformat=%{NAME} -q $i | grep -v 'not installed' ); N=${PACKAGENAME}" "${N}; if [ $? -eq 0 ]; then echo ; echo ; echo -n $N ; fi ;done
$ yum downgrade -y perl-Time-HiRes perl-macros perl-libs perl

### 重新安装 irqbalance 和 traceroute 
$ N=''; cat /tmp/pkg | sort -u | grep '^3:' | awk '{print $1}'  | awk -F ":" '{print $2}'  | while read i  ; do  PACKAGENAME=$(rpm --queryformat=%{NAME} -q $i | grep -v 'not installed' ); N=${PACKAGENAME}" "${N}; if [ $? -eq 0 ]; then echo ; echo ; echo -n $N ; fi ;done
$ yum downgrade -y traceroute irqbalance

### 重新安装 ethtool, ivtv-firmware, libpng, microcode_ctl, mtr, postfix, shadow-utils, tar, vim-common, vim-minimal   
$ N=''; cat /tmp/pkg | sort -u | grep '^2:' | awk '{print $1}'  | awk -F ":" '{print $2}'  | while read i  ; do  PACKAGENAME=$(rpm --queryformat=%{NAME} -q $i | grep -v 'not installed' ); N=${PACKAGENAME}" "${N}; if [ $? -eq 0 ]; then echo ; echo ; echo -n $N ; fi ;done

$ yum downgrade -y vim-minimal vim-filesystem vim-enhanced vim-common tar shadow-utils postfix mtr microcode_ctl libpng ivtv-firmware ethtool

### 重新安装 wpa_supplicant telnet smartmontools sg3_utils-libs quota-nls quota pkgconfig perl-Pod-Simple perl-Pod-Escapes perl-parent openssl-libs openssl nfs-utils NetworkManager-tui NetworkManager-team NetworkManager-libnm NetworkManager mariadb-libs make iwl1000-firmware hardlink grub2-tools-minimal grub2-tools-extra grub2-tools grub2-pc-modules grub2-pc grub2-common grub2 gmp findutils emacs-filesystem dmidecode dbus-libs dbus cups-libs cups-client bash-completion tcp_wrappers-libs

$ N=''; cat /tmp/pkg | sort -u | grep '^1:' | awk '{print $1}'  | awk -F ":" '{print $2}'  | while read i  ; do echo $i ; PACKAGENAME=$(rpm --queryformat=%{NAME} -q $i); N=${PACKAGENAME}" "${N}; if [ $? -eq 0 ]; then echo -n $N ; fi ;done

### 需要手工补充几个软件包
### 满足软件包替换的依赖关系需要 
### glibc-common glibc glibc-devel glibc-headers nscd tcp_wrappers-libs
$ yum downgrade -y wpa_supplicant telnet smartmontools sg3_utils-libs quota-nls quota pkgconfig perl-Pod-Simple perl-Pod-Escapes perl-parent openssl-libs openssl nfs-utils NetworkManager-tui NetworkManager-team NetworkManager-libnm NetworkManager mariadb-libs make iwl1000-firmware hardlink grub2-tools-minimal grub2-tools-extra grub2-tools grub2-pc-modules grub2-pc grub2-common grub2 gmp findutils emacs-filesystem dmidecode dbus-libs dbus cups-libs cups-client bash-completion glibc-common glibc glibc-devel glibc-headers nscd tcp_wrappers-libs

### 有几个软件包需要特殊处理一下
$ yum swap -y alinux-logos redhat-logos
$ yum swap -y alinux-indexhtml redhat-indexhtml
$ yum swap -y alinux-release redhat-release
$ yum remove -y aliyun-cli

$ N=''; cat /tmp/pkg | sort -u | grep '^0:' | awk '{print $1}'  | awk -F ":" '{print $2}'  | while read i  ; do echo $i ; PACKAGENAME=$(rpm --queryformat=%{NAME} -q $i | grep -v 'not installed' ); N=${PACKAGENAME}" "${N}; if [ $? -eq 0 ]; then echo ; echo ; echo -n $N ; fi ;done

$ mv /etc/yum/protected.d/systemd.conf /etc/yum/protected.d/systemd.conf.backup 

### 删除这个软件包后
$ yum remove -y abrt-retrace-client

### 解决依赖关系
### 添加 gcc dracut-network  
$ yum downgrade -y zlib zip yum-utils yum-plugin-releasever-adapter yum-plugin-fastestmirror yum-metadata-parser yum-langpacks yum yajl xz-libs xz xmlrpc-c-client xmlrpc-c xfsprogs xfsdump xdg-utils words which wget virt-what util-linux ustr usermode usbutils usb_modeswitch-data usb_modeswitch update-motd unzip tzdata tuned time teamd tcsh sysvinit-tools systemtap-runtime system-lsb-submod-security system-lsb-core systemd-sysv systemd-python systemd-libs systemd sysstat sudo strace sssd-client sshpass sqlite spax sos socat snappy slang shared-mime-info sgpio setuptool setup setserial selinux-policy-targeted selinux-policy sed scl-utils satyr rsyslog rsync rpm-python rpm-libs rpm-build-libs rpm rpcbind rootfiles rng-tools rfkill readline rdate qrencode-libs PyYAML pyxattr python-urllib3 python-urlgrabber python-srpm-macros python-slip-dbus python-slip python-six python-setuptools python-schedutils python-rpm-macros python-requests python-repoze-lru python-pyudev python-pycurl python-pycparser python-ply python-perf python-markupsafe python-linux-procfs python-libs python-kitchen python-jwcrypto python-jsonpointer python-jsonpatch python-jinja2 python-ipaddress python-iniparse python-idna python-gobject-base python-firewall python-enum34 python-devel python-decorator python-configobj python-chardet python-cffi python-backports-ssl_match_hostname python-backports python-babel python-augeas python3-setuptools python3-pip python3-libs python3 python2-rpm-macros python2-pyasn1 python2-oauthlib python2-jsonschema python2-futures python2-cryptography python pyliblzma pygpgme pygobject2 pth psmisc psacct procps-ng popt polkit-pkla-compat polkit policycoreutils pm-utils plymouth-scripts plymouth-core-libs plymouth pixman pinfo pinentry pigz pexpect perl-Time-Local perl-threads-shared perl-threads perl-Text-ParseWords perl-Storable perl-Socket perl-Scalar-List-Utils perl-Pod-Usage perl-Pod-Perldoc perl-podlators perl-PathTools perl-HTTP-Tiny perl-Getopt-Long perl-Filter perl-File-Temp perl-File-Path perl-Exporter perl-Encode perl-constant perl-Carp pcre pciutils-libs pciutils patch passwd parted pam p11-kit-trust p11-kit os-prober openssh-server openssh-clients openssh openldap numactl-libs ntsysv ntpdate ntp nss-util nss-tools nss-sysinit nss-softokn-freebl nss-softokn nss-pem nss nspr newt-python newt net-tools ncurses-libs ncurses-base ncurses nano mpfr mozjs17 mlocate mdadm man-pages-overrides man-pages man-db mailx m4 lzo lz4 lua lsscsi lsof logrotate lm_sensors-libs linux-firmware libyaml libxml2-python libxml2 libverto-libevent libverto libuuid libutempter libuser libusbx libunistring libtool-ltdl-devel libtool-ltdl libtirpc libteam libtasn1 libtar libsysfs libstoragemgmt-python-clibs libstoragemgmt-python libstoragemgmt libstdc++ libsss_nss_idmap libsss_idmap libssh2 libss libsmartcols libsepol libsemanage libselinux-utils libselinux-python libselinux libseccomp libreport-web libreport-rhel libreport-python libreport-plugin-ureport libreport-plugin-rhtsupport libreport-plugin-mailx libreport-filesystem libreport-cli libreport libref_array libpwquality libproxy libpipeline libpciaccess libpath_utils libnl3-cli libnl3 libnl libnfsidmap libnfnetlink libnetfilter_queue libnetfilter_cttimeout libnetfilter_cthelper libnetfilter_conntrack libndp libmpc libmount libmodman libmnl libini_config libidn libgpg-error libgomp libgcrypt libgcc libfprint libffi libfastjson libevent libestr libedit libdwarf libdrm libdb-utils libdb libdaemon libcurl libcroco libconfig libcom_err libcollection libcap-ng libcap libblkid libbasicobjects libattr libassuan libaio libacl less ledmon langtable-python langtable-data langtable krb5-libs kpatch kpartx kmod-libs kmod keyutils-libs keyutils kernel kbd-misc kbd-legacy kbd json-c jansson iwl7260-firmware iwl6050-firmware iwl6000g2b-firmware iwl6000g2a-firmware iwl6000-firmware iwl5150-firmware iwl5000-firmware iwl4965-firmware iwl3945-firmware iwl3160-firmware iwl2030-firmware iwl2000-firmware iwl135-firmware iwl105-firmware iwl100-firmware iw iputils iptables ipset-libs ipset iprutils iproute initscripts info hwdata hunspell-en-US hunspell-en-GB hunspell-en hunspell hostname hdparm gzip gssproxy grubby groff-base grep gpm-libs gpgme gobject-introspection gnupg2 glib2 gettext-libs gettext gdbm gdb gawk fxload fuse-libs fuse freetype fprintd-pam fprintd firewalld-filesystem firewalld fipscheck-lib fipscheck filesystem file-libs file expat elfutils-libs elfutils-libelf elfutils-default-yama-scope elfutils efivar-libs efibootmgr ed ebtables e2fsprogs-libs e2fsprogs dyninst dracut-config-rescue dracut dosfstools diffutils desktop-file-utils deltarpm dbus-python dbus-glib cyrus-sasl-plain cyrus-sasl-lib curl cryptsetup-libs cryptsetup crontabs cronie-anacron cronie crda cracklib-dicts cracklib cpp cpio coreutils conntrack-tools cloud-utils-growpart cloud-init chrony chkconfig ca-certificates bzip2-libs bzip2 btrfs-progs bridge-utils boost-thread boost-system boost-date-time blktrace biosdevname binutils bc bash basesystem avahi-libs autogen-libopts authconfig augeas-libs audit-libs audit attr at alsa-tools-firmware alsa-lib alsa-firmware aic94xx-firmware acl abrt-tui abrt-python abrt-libs abrt-dbus abrt-addon-xorg abrt-addon-python abrt-addon-pstoreoops abrt-addon-kerneloops abrt-addon-vmcore abrt gcc dracut-network 

### 最后一部分软件包处理
$ N=''; rpm -qa | grep -Ev "el7.x86_64|el7.noarch" | grep al7 | while read i  ; do echo $i ; PACKAGENAME=$(rpm --queryformat=%{NAME} -q $i | grep -v 'not installed' ); N=${PACKAGENAME}" "${N}; if [ $? -eq 0 ]; then echo ; echo ; echo -n $N ; fi ;done

$ yum remove -y yum-plugin-fastestmirror.noarch python-repoze-lru pigz system-lsb-submod-security sshpass epel-aliyuncs-release aliyun_assist yum-plugin-releasever-adapter

$ yum upgrade -y iproute strace

$ yum downgrade -y dmraid-events dmraid device-mapper-persistent-data kexec-tools

$ mv /etc/yum/protected.d/systemd.conf.backup /etc/yum/protected.d/systemd.conf


### 删除阿里云盾
### https://hughsite.com/post/aliyun-remove-monitor.html
stop_aegis(){
	killall -9 aegis_cli >/dev/null 2>&1
	killall -9 aegis_update >/dev/null 2>&1
	killall -9 aegis_cli >/dev/null 2>&1
	killall -9 AliYunDun >/dev/null 2>&1
	killall -9 AliHids >/dev/null 2>&1
	killall -9 AliHips >/dev/null 2>&1
	killall -9 AliYunDunUpdate >/dev/null 2>&1
  printf "%-40s %40s\n" "Stopping aegis" "[  OK  ]"
}

remove_aegis(){
if [ -d /usr/local/aegis ];then
    rm -rf /usr/local/aegis/aegis_client
    rm -rf /usr/local/aegis/aegis_update
	  rm -rf /usr/local/aegis/alihids
fi
rm -rf /usr/local/aegis
}

### alicloud linux 2 image 里有 geoipupdate 
### 使用 geoipupdate 自动更新 GeoIP 数据库
### https://vickey.fun/2022/04/17/using-geoipupdate-to-auto-update-maxmind-database/


### alicloud linux 3 image 
$ qemu-img convert -p -f qcow2 -O qcow2 aliyun_3_x64_20G_nocloud_alibase_20230110.qcow2 jwang-aliyun2-2.qcow2
$ virt-customize -a jwang-aliyun2-2.qcow2 --root-password password:NOT_REAL_PASSWORD

### 
$ oc get nodes
...
Events:
  Type     Reason            Age                    From               Message
  ----     ------            ----                   ----               -------
  Warning  FailedScheduling  7m29s (x573 over 47h)  default-scheduler  0/1 nodes are available: 1 node(s) had untolerated taint {node.kubernetes.io/unreachable: }. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
  Warning  FailedScheduling  7m19s                  default-scheduler  0/1 nodes are available: 1 Too many pods. preemption: 0/1 nodes are available: 1 No preemption victims found for incoming pod.


cat <<EOF | oc apply -f -
apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
  name: rt
spec:
  machineConfigPoolSelector:
    machineconfiguration.openshift.io/role: worker
  nodeSelector:
    node-role.kubernetes.io/worker: ""
EOF

### 增加 maxPods
### https://docs.openshift.com/container-platform/4.8/nodes/nodes/nodes-nodes-managing-max-pods.html
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: set-max-pods 
spec:
  machineConfigPoolSelector:
    matchLabels:
      pools.operator.machineconfiguration.openshift.io/master: "" 
  kubeletConfig:
    maxPods: 500
EOF

### 下载视频
### yt-dlp 参数 --no-geo-bypass --cookies-from-browser
$ yt-dlp --no-geo-bypass --cookies-from-browser chrome https://youtu.be/3sjBb7sTVtE

### RHPDS/DEMO system 证书问题修复
$ oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
$ watch -n 1 oc get csr
$ watch -n 1 oc get co

### hosted-engine - 更新 rhv manager 证书 - rhv 4.1
### https://access.redhat.com/documentation/en-us/red_hat_virtualization/4.1/html/self-hosted_engine_guide/chap-maintenance_and_upgrading_resources
### https://access.redhat.com/solutions/3532921
### https://lists.ovirt.org/archives/list/users@ovirt.org/thread/3S3XZX6RVXJCU5F2E6466UPG36QAIYGL/
### 登陆到 rhv node 上
### 设置维护模式为 global 
# hosted-engine --set-maintenance --mode=global
### 登陆到 rhv manager 上
### 执行 engine-setup --offline 更新 rhv manager 证书
$ engine-setup --offline

openssl req -new -key /tmp/vdsmkey.pem -out /tmp/test_host_vdsm.csr -passin "pass:mypass" -passout "pass:mypass" -batch -subj "/"

# openssl x509 -in /etc/pki/vdsm/certs/vdsmcert.pem -noout -subject
subject= /O=rhcnsa.org/CN=node1.rhcnsa.org
subject= /O=rhcnsa.org/CN=node3.rhcnsa.org

### rhv manager 为 rhv hypervisor 生成新证书
[MANAGER]# cd /etc/pki/ovirt-engine/
$ openssl ca -batch -policy policy_match -config openssl.conf -cert ca.pem -keyfile  private/ca.pem -days +3650 -in  /tmp/test_host_vdsm.csr -out /tmp/test_host_vdsm.cer -startdate "$(date --utc --date "now -1 days" +"%y%m%d%H%M%SZ")" -subj "/O=rhcnsa.org/CN=node1.rhcnsa.org" -utf8
$ openssl ca -batch -policy policy_match -config openssl.conf -cert ca.pem -keyfile  private/ca.pem -days +3650 -in  /tmp/test_host_vdsm.csr -out /tmp/test_host_vdsm.cer -startdate "$(date --utc --date "now -1 days" +"%y%m%d%H%M%SZ")" -subj "/O=rhcnsa.org/CN=node3.rhcnsa.org" -utf8

### 拷贝证书到 rhv hypervisor - 4.1
$ scp root@<RHV-M FQDN OR IP>:/tmp/test_host_vdsm.cer /etc/pki/vdsm/certs/vdsmcert.pem

### 更新 rhv hypervisor 证书 - 4.1
[HOST]# cp /etc/pki/vdsm/certs/vdsmcert.pem /etc/pki/vdsm/libvirt-spice/server-cert.pem
[HOST]# cp /etc/pki/vdsm/certs/vdsmcert.pem /etc/pki/libvirt/clientcert.pem
[HOST]# systemctl restart libvirtd

### 尝试 oobabooga 与 text-generation-webui
### https://github.com/oobabooga/text-generation-webui

cat > Dockerfile <<EOF
FROM registry.access.redhat.com/ubi8/ubi:latest
RUN dnf install -y libpciaccess iproute net-tools procps-ng nmap-ncat iputils diffutils git unzip && dnf groupinstall -y "Development Tools" && dnf clean all && curl -LO 'https://github.com/oobabooga/text-generation-webui/releases/download/installers/oobabooga_linux.zip' && unzip oobabooga_linux.zip
CMD ["/bin/bash", "-c", "exec /bin/bash -c 'trap : TERM INT; sleep 9999999999d & wait'"]
EOF

podman build -f Dockerfile -t registry.example.com:5000/oobabooga/text-generation-webui:v1
podman run -d -t --name text-generation-webui-v1 --network host --privileged registry.example.com:5000/oobabooga/text-generation-webui:v1


### hypershift labs 
### https://github.com/redhat-cop/openshift-lab-origin/blob/master/HyperShift_Lab/Introduction.adoc

### ACM App/Sub demo github repo
### https://github.com/HichamMourad/book-import

### 
cat <<EOF > pvc_cirros.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "cirros"
  labels:
    app: containerized-data-importer
  annotations:
    cdi.kubevirt.io/storage.import.endpoint: "http://10.66.208.115/utils/vm/cirros-0.4.0-x86_64-disk.img"
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

cat <<EOF | oc apply -f -
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: "cirros-import-dv"
spec:
  source:
      http:
         url: "http://10.66.208.115/utils/vm/cirros-0.4.0-x86_64-disk.img"
  pvc:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: "1Gi"
EOF


### 创建 vm centos7-1
### DataVolumeTemplate
cat <<EOF | oc apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    app: centos7-1
  name: centos7-1
spec:
  dataVolumeTemplates:
  - apiVersion: cdi.kubevirt.io/v1beta1
    kind: DataVolume
    metadata:
      name: centos7-1
    spec:
      sourceRef:
        kind: DataSource
        name: centos7
        namespace: openshift-virtualization-os-images
      storage:
        resources:
          requests:
            storage: 30Gi
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: centos7-1
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
          - disk:
              bus: virtio
            name: rootdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          interfaces:
          - masquerade: {}
            name: default
          rng: {}
        firmware:
          bootloader:
            bios: {}
        resources:
          requests:
            memory: 1Gi
      readinessProbe:
        initialDelaySeconds: 120
        periodSeconds: 20
        timeoutSeconds: 10
        failureThreshold: 3
        successThreshold: 3
        guestAgentPing: {}
      evictionStrategy: LiveMigrate
      networks:
      - name: default
        pod: {}
      volumes:
      - dataVolume:
          name: centos7-1
        name: rootdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            user: centos
            password: 'XXXXXXXX' 
            chpasswd: { expire: False }
        name: cloudinitdisk
EOF

### 创建 vm cirros
### DataVolumeTemplate
cat <<EOF | oc apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    app: cirros-1
  name: cirros-1
spec:
  dataVolumeTemplates:
  - apiVersion: cdi.kubevirt.io/v1beta1
    kind: DataVolume
    metadata:
      name: cirros-1
    spec:
      source:
        http:
          url: http://xxx.xxx.xxx.xxx/utils/vm/cirros-0.4.0-x86_64-disk.img
      storage:
        resources:
          requests:
            storage: 1Gi
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: cirros-1
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
          - disk:
              bus: virtio
            name: rootdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          interfaces:
          - masquerade: {}
            name: default
          rng: {}
        firmware:
          bootloader:
            bios: {}
        resources:
          requests:
            memory: 256Mi
      readinessProbe:
        initialDelaySeconds: 120
        periodSeconds: 20
        timeoutSeconds: 10
        failureThreshold: 3
        successThreshold: 3
        guestAgentPing: {}
      evictionStrategy: LiveMigrate
      networks:
      - name: default
        pod: {}
      volumes:
      - dataVolume:
          name: cirros-1
        name: rootdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            user: cirros
            password: 'XXXXXXXX' 
            chpasswd: { expire: False }
        name: cloudinitdisk
EOF

### try fedora vm
### source http url
### add cloudInitNoCloud.userData.ssh_authorized_keys
cat <<EOF | oc apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    app: fedora-1
  name: fedora-1
spec:
  dataVolumeTemplates:
  - apiVersion: cdi.kubevirt.io/v1beta1
    kind: DataVolume
    metadata:
      name: fedora-1
    spec:
      source:
        http:
          url: http://XXX.XXX.XXX.XXX/utils/vm/Fedora-Cloud-Base-38-1.6.x86_64.raw.xz
      storage:
        resources:
          requests:
            storage: 10Gi
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: fedora-1
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
          - disk:
              bus: virtio
            name: rootdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          interfaces:
          - masquerade: {}
            name: default
          rng: {}
        firmware:
          bootloader:
            bios: {}
        resources:
          requests:
            memory: 1024Mi
      readinessProbe:
        initialDelaySeconds: 120
        periodSeconds: 20
        timeoutSeconds: 10
        failureThreshold: 3
        successThreshold: 3
        guestAgentPing: {}
      evictionStrategy: LiveMigrate
      networks:
      - name: default
        pod: {}
      volumes:
      - dataVolume:
          name: fedora-1
        name: rootdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            user: fedora
            password: 'XXXXXXXX'
            ssh_authorized_keys:
              - ssh-rsa AAAAB3Nza.....
            chpasswd: { expire: False }
        name: cloudinitdisk
EOF

### HyperShift with Kubevirt
### https://medium.com/@ben.swinney_ce/hypershift-with-kubevirt-564bd1f850ce
### 准备工作
### 如果 CNI 是 OpenShiftSDN，首先将 CNI 迁移为 OVNKubernetes
#### hypershift support OVNKubernetes as CNI
#### 需要将 CNI 从 OpenShiftSDN 转换为 OVNKubernetes
#### https://docs.openshift.com/container-platform/4.13/networking/ovn_kubernetes_network_provider/migrate-from-openshift-sdn.html
(hub)$ oc get Network.config.openshift.io cluster -o yaml > cluster-openshift-sdn.yaml
(hub)$ oc patch Network.operator.openshift.io cluster --type='merge' \
  --patch '{ "spec": { "migration": { "networkType": "OVNKubernetes" } } }'
(hub)$ watch 'oc get mcp' 
(hub)$ oc describe node | egrep "hostname|machineconfig"
(hub)$ oc get machineconfig <config_name> -o yaml | grep ExecStart
(hub)$ oc patch Network.config.openshift.io cluster \
  --type='merge' --patch '{ "spec": { "networkType": "OVNKubernetes" } }'
(hub)$ oc -n openshift-multus rollout status daemonset/multus
...
daemon set "multus" successfully rolled out
### reboot nodes one by one
#### 检查 status.networkType 为 OVNKubernetes
(hub)$ oc get network.config/cluster -o jsonpath='{.status.networkType}{"\n"}'
(hub)$ oc get nodes
(hub)$ oc get pods -A | grep -Ev "Complete|Running"
(hub)$ oc get co
#### 当前面的检查内容没有问题时，执行以下命令，移除 OpenShiftSDN 相关配置和资源
(hub)$ oc patch Network.operator.openshift.io cluster --type='merge' \
  --patch '{ "spec": { "migration": null } }'
(hub)$ oc patch Network.operator.openshift.io cluster --type='merge' \
  --patch '{ "spec": { "defaultNetwork": { "openshiftSDNConfig": null }}}'
(hub)$ oc delete namespace openshift-sdn    
 
### 安装 ACM
### 安装 ODF
### 安装 OpenShift Virtualization
### 安装 MetalLB
#### 启用 multiclusterengine 的 components hypershift-preview
(hub)$ oc get mce multiclusterengine -o json | jq '.spec.overrides.components' 
...
  {
    "enabled": false,
    "name": "hypershift-preview"
  },
...
(hub)$ oc patch mce multiclusterengine --type=merge -p '{"spec":{"overrides":{"components":[{"name":"hypershift-preview","enabled":true}]}}}'

(hub)$ cat <<EOF | oc apply -f -
apiVersion: addon.open-cluster-management.io/v1alpha1
kind: ManagedClusterAddOn
metadata:
  name: hypershift-addon
  namespace: local-cluster
spec:
  installNamespace: open-cluster-management-agent-addon
EOF

(hub)$ oc get pods -n hypershift

(hub)$ cat <<EOF | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: MetalLB
metadata:
  name: metallb
  namespace: metallb-system
EOF

(hub)$ cat <<EOF | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ip-addresspool
  namespace: metallb-system
spec:
  addresses:
  - 10.39.127.20-10.39.127.26
  autoAssign: true
  avoidBuggyIPs: false
EOF

(hub)$ cat <<EOF | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-adv
  namespace: metallb-system
spec:
  ipAddressPools:
    - ip-addresspool
EOF

(hub)$ oc patch ingresscontroller -n openshift-ingress-operator default --type=json -p '[{ "op": "add", "path": "/spec/routeAdmission", "value": {wildcardPolicy: "WildcardsAllowed"}}]'

(hub)$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: clusters
EOF

(hub)$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: jwang-hosted-pull-secret
  namespace: clusters
data:
  .dockerconfigjson: PULL_SECRET_HERE_IN_BASE_64
EOF


#### key 所对应的字符串需要为 15/23/31 个字符
#### 否则 kube-apiserver 会有报错
#### $ oc logs kube-apiserver-694fbcd7-d8prr -c kube-apiserver
#### E0828 05:14:01.718269       1 run.go:74] "command failed" err="error while parsing file: resources[0].providers[0].aescbc.keys[0].secret: Invalid value: \"REDACTED\": secret is not of the expected length, got 10, expected one of [16 24 32]"
(hub)$ cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: jwang-hosted-etcd-encryption-key
  namespace: clusters
type: Opaque
data:
  key: ETCD_ENCRYPTION_KEY_HERE_IN_BASE_64
EOF

(hub)$ cat <<EOF | oc apply -f -
apiVersion: hypershift.openshift.io/v1beta1
kind: HostedCluster
metadata:
  name: jwang-hosted
  namespace: clusters
spec:
  autoscaling: {}
  controllerAvailabilityPolicy: SingleReplica
  dns:
    baseDomain: ""
  etcd:
    managed:
      storage:
        persistentVolume:
          size: 4Gi
        restoreSnapshotURL: null
        type: PersistentVolume
    managementType: Managed
  fips: false
  networking:
    clusterNetwork:
    - cidr: 10.132.0.0/14
    networkType: OVNKubernetes
    serviceNetwork:
    - cidr: 172.31.0.0/16
  platform:
    kubevirt:
      baseDomainPassthrough: true
    type: KubeVirt
  pullSecret:
    name: jwang-hosted-pull-secret
  release:
    image: quay.io/openshift-release-dev/ocp-release:4.13.6-x86_64
  secretEncryption:
    aescbc:
      activeKey:
        name: jwang-hosted-etcd-encryption-key
    type: aescbc
  services:
  - service: APIServer
    servicePublishingStrategy:
      type: LoadBalancer
  - service: OAuthServer
    servicePublishingStrategy:
      type: Route
  - service: Konnectivity
    servicePublishingStrategy:
      type: Route
  - service: Ignition
    servicePublishingStrategy:
      type: Route
  - service: OVNSbDb
    servicePublishingStrategy:
      type: Route
  sshKey: {}
EOF

(hub)$ cat <<EOF | oc apply -f -
apiVersion: hypershift.openshift.io/v1beta1
kind: NodePool
metadata:
  name: jwang-hosted
  namespace: clusters
spec:
  clusterName: jwang-hosted
  management:
    autoRepair: false
    upgradeType: Replace
  nodeDrainTimeout: 0s
  platform:
    kubevirt:
      compute:
        cores: 8
        memory: 8Gi
      rootVolume:
        persistent:
          size: 50Gi
        type: Persistent
    type: KubeVirt
  release:
    image: quay.io/openshift-release-dev/ocp-release:4.13.6-x86_64
  replicas: 2
EOF

(hub)$ oc logs $(oc get pods -n hypershift -l app=operator -o name|head -1) -n hypershift
(hub)$ oc logs $(oc get pods -n hypershift -l app=operator -o name|tail -1) -n hypershift

#### HyperShift with BareMetal
#### https://labs.sysdeseng.com/hypershift-baremetal-lab/4.13/index.html


#### OpenShift Virtualization NetworkAttachmentDefinition and NodeNetworkConfigurationPolicy 的例子
#### cnv-bridge 与 vlan
#### 详细的配置参考 https://kubevirt.io/2020/Multiple-Network-Attachments-with-bridge-CNI.html
#### 思路是用 NodeNetworkConfigurationPolicy 配置节点 Bridge
#### 用 NetworkAttachmentDefinition 配置 KubeVirt VM 可用的 Network Attachment 
#### 在创建 VM 时在 network 定义时引用 Network Attachment
####       - name: br0-100
####         multus:
####           networkName: br0-100-l2
oc apply -f - <<EOF
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
  metadata:  
  name: network-attachment-vlan4-access
  namespace: jinkit-vms
  annotations:    
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/e810-25g-br1
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "network-attachment-vlan4-access",
    "type": "cnv-bridge",
    "bridge": "e810-25g-br1",
    "macspoofchk": true,
    "vlan": 4
  }'
EOF

oc apply -f - <<EOF
---
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: br1-ens1f1-policy-masters
  namespace: jinkit-vms
spec:
  nodeSelector:
    node-role.kubernetes.io/master: ""
  desiredState:
    interfaces:
      - name: e810-25g-br1
        description: Standard Linux Brige ens1f1 on E810-25G
        type: linux-bridge
        state: up
        ipv4:
          enabled: false
        bridge:
          options:
            stp:
              enabled: false
            port:
              - name: ens1f1
EOF


#### 修改 VM Termination 时间
$ virtctl stop <vm-name> --force --grace-period=0

### 支持 Access Token 的 git clone，提供 http.extraHeader 
$ git clone -c http.extraHeader='Authorization: Bearer <MY_PERSONAL_ACCESSTOKEN>' https://<server>/scm/infiac/aof2-inventories.git

#### RHEL8.6 - 安装 k8s v1.18
#### 参考 https://www.cpweb.top/1644 
#### https://www.iamlightsmile.com/articles/CentOS8%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AEkubernetes%EF%BC%88K8S%EF%BC%89/
#### https://blog.csdn.net/u013164931/article/details/105548102
#### https://segmentfault.com/a/1190000040155015
### 最小化安装
$ systemctl disable firewalld
$ systemctl stop firewalld
$ setenforce 0
$ sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
$ mount /dev/sr0 /mnt
$ cat > /etc/yum.repos.d/local.repo << 'EOF'
[baseos]
name=baseos
baseurl=file:///mnt/BaseOS
enabled=1
gpgcheck=0

[appstream]
name=appstream
baseurl=file:///mnt/AppStream
enabled=1
gpgcheck=0
EOF

### 设置国内的 k8s 安装源
$ cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

$ yum install -y yum-utils device-mapper-persistent-data lvm2

### 安装 docker
$ yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
$ yum install -y containerd.io docker-ce
### 编辑 /usr/lib/systemd/system/docker.service
### ExecStart 添加 --exec-opt native.cgroupdriver=systemd
### ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd
$ systemctl daemon-reload
$ systemctl enable --now docker.service
$ systemctl restart docker
### 检查 Cgroup Driver 为 systemd 
$ docker info | grep Cgroup
 Cgroup Driver: systemd
 Cgroup Version: 1

$ yum -y install kubectl-1.18.18 kubelet-1.18.18 kubeadm-1.18.18
$ systemctl enable kubelet && systemctl start kubelet

$ kubeadm config print init-defaults > init.default.yaml 
### 编辑 init.default.yaml
### 修改 
### advertiseAddress: 192.168.122.123
### imageRepository: registry.aliyuncs.com/google_containers
### 添加
### podSubnet: 10.244.0.0/16

### 编辑 /etc/containerd/config.toml  
### disabled_plugins = [""]
$ systemctl enable --now containerd.service


$ kubeadm config images list --config init.default.yaml
$ kubeadm config images pull --config init.default.yaml

### 禁用 swap 
$ swapoff -a 
$ systemctl restart kubelet
### 配置文件做参考
### $ kubeadm init --config=init.default.yaml --ignore-preflight-errors=all
$ kubeadm init --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v1.18.18 --service-cidr=10.96.0.0/12 --pod-network-cidr=10.244.0.0/16

$ mkdir -p $HOME/.kube
$ cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ chown $(id -u):$(id -g) $HOME/.kube/config

### 创建文件
$ mkdir -p /run/flannel
$ cat > /run/flannel/subnet.env <<EOF
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.0/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
EOF

### 安装 CNI
$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

$ kubectl get nodes
$ kubectl get pods -A

#### 删除节点及清理工作
$ kubeadm reset 
$ rm -f ~/.kube/config
$ rm -f /etc/cni/net.d/*
$ iptables -F 
### 删除 cni0 上的 ip 地址
$ ip address delete 10.244.0.1/24 dev cni0 
### 删除 kubeadm kubectl kubelet
$ yum remove -y kubeadm kubectl kubelet
### 重新安装特定版本 kubeadm kubectl kubelet
$ yum -y install kubectl-1.18.18 kubelet-1.18.18 kubeadm-1.18.18

### 删除节点 taint
$ kubectl taint nodes edge-3.example.com node-role.kubernetes.io/master-
$ kubectl describe nodes edge-3.example.com | grep -i taints
#### 在 ACM Hub 上导入 edge-3
$ export CLUSTER_NAME=edge-3
$ oc new-project ${CLUSTER_NAME}

$ cat <<EOF | oc apply -f -
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: ${CLUSTER_NAME}
  namespace: ${CLUSTER_NAME}
spec:
  clusterName: ${CLUSTER_NAME}
  clusterNamespace: ${CLUSTER_NAME}
  applicationManager:
    enabled: true
  certPolicyController:
    enabled: true
  clusterLabels:
    cloud: auto-detect
    vendor: auto-detect
  iamPolicyController:
    enabled: true
  policyController:
    enabled: true
  searchCollector:
    enabled: true
  version: 2.2.0
EOF

$ cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: ${CLUSTER_NAME}
spec:
  hubAcceptsClient: true
EOF

# 上面的命令在 ${CLUSTER_NAME} namespace 下生成 secret ${CLUSTER_NAME}-import 
# 导出 import.yaml 和 crds.yaml 
IMPORT=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.import\.yaml}')
CRDS=$(oc get -n ${CLUSTER_NAME} secret ${CLUSTER_NAME}-import -o jsonpath='{.data.crds\.yaml}')


cd /root/kubeconfig/edge/edge-3
### 编辑 kubeconfig
### server: https://edge-3.example.com:6443
openssl s_client -host edge-3.example.com -port 6443 -showcerts > trace < /dev/null
cat trace | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /etc/pki/ca-trust/source/anchors/edge-3.crt
update-ca-trust extract  

oc --kubeconfig=./kubeconfig create namespace open-cluster-management-agent


oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet-registration-sa
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet-registration-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent create sa klusterlet-work-sa
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent patch sa klusterlet-work-sa -p '{"imagePullSecrets": [{"name": "rhacm"}]}'

oc --kubeconfig=./kubeconfig create namespace open-cluster-management-agent-addon
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon create secret generic rhacm --from-file=.dockerconfigjson=auth.json --type=kubernetes.io/dockerconfigjson
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon create sa klusterlet-addon-operator
oc --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon patch sa klusterlet-addon-operator -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
#### 替换 namespace open-cluster-management-agent-addon 下所有 sa 的 imagePullSecrets
for serviceaccount in $(kubectl get serviceaccount -n open-cluster-management-agent-addon -o name)
do 
  kubectl --kubeconfig=./kubeconfig -n open-cluster-management-agent-addon patch sa ${serviceaccount} -p '{"imagePullSecrets": [{"name": "rhacm"}]}'
done

echo $CRDS | base64 -d | oc --kubeconfig=./kubeconfig apply -f -
echo $IMPORT | base64 -d | oc --kubeconfig=./kubeconfig apply -f -


### https://medium.com/@hillayamir/adding-a-trusted-ca-config-the-ingress-certificate-in-ocp-4-50bafbacd168
### 替换集群 CA 和 ingress certs
### https://thesecmaster.com/how-to-generate-a-csr-for-multi-domain-ssl-certificates-using-openssl/
### https://www.baeldung.com/openssl-self-signed-cert

### 如何安装 TKEStack 
https://github.com/tkestack/tke/blob/master/docs/guide/zh-CN/installation/installation-procedures.md

yum install --downloadonly --downloaddir=/microshift microshift

# 禁用 CrashReport
# https://iboysoft.com/wiki/reportcrash-mac.html

$ launchctl unload -w /System/Library/LaunchAgents/com.apple.ReportCrash.plist
$ sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.ReportCrash.Root.plist


### EDA 与 AAP 集成的 secret
### 创建一个 secret，secret 包含
### aap 的 url
### aap 的 access token
### 访问时是否校验 ssl
### 其中 aap 的 access token 可以在 aap 的 '访问' -> '用户' -> Token 处创建
### 因为 EDA 需要在 AAP 里创建对象，因此需要创建 Scope 为 Write 的 Token
---
apiVersion: v1
kind: Secret
metadata:
  name: aap-connection-token
stringData:
  url: "https://example-aap.apps.cluster-9tfv2.9tfv2.sandbox575.opentlc.com/"
  token: "xxxx"
  ssl_verify: "false"

### 安装 yq
BINARY=yq_linux_amd64 
LATEST=$(wget -qO- https://api.github.com/repos/mikefarah/yq/releases/latest 2>/dev/null | grep browser_download_url | grep $BINARY\"\$|awk '{print $NF}' )
sudo wget -q $LATEST -O /usr/bin/yq && sudo chmod +x /usr/bin/yq


### 安装 cert-manager 
### https://cert-manager.io/docs/installation/helm/
KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig helm repo add jetstack https://charts.jetstack.io
KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig helm repo update
KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig helm repo list
KUBECONFIG=/data/ocp-cluster/ocp4-3/auth/kubeconfig helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.1 \
  --set installCRDs=true

### ACS: 查找 scanner db 
### https://access.redhat.com/solutions/6981041
### 进入到 scanner pod terminal
### 查找 CVE-2023-38545
(central)$ oc -n stackrox get secret scanner-db-password -o jsonpath='{.data.password}' -n stackrox | base64 -d
(scanner-db-pod)$ zcat /docker-entrypoint-initdb.d/definitions.sql.gz | psql -U postgres -W postgres -c "SELECT * from vulnerability WHERE name = 'CVE-2023-38545';"

### 定义 securedCluster 对象
### 调整资源限制 scanner/sensor

### 调整 console operator
### https://docs.openshift.com/container-platform/4.13/web_console/disabling-web-console.html
### https://raw.githubusercontent.com/openshift/console-operator/master/examples/cvo-unmanage-operator.yaml
cat <<EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: ClusterVersion
metadata:
  namespace: openshift-cluster-version
  name: version
spec:
  overrides:
    - kind: Deployment
      name: console-operator
      namespace: openshift-console-operator
      unmanaged: true
      group: apps
    - kind: ClusterRole
      name: console-operator
      namespace: ""
      unmanaged: true
      group: rbac.authorization.k8s.io
EOF
### 调整 console-operator replica 为 0 
### 调整 openshift-console replica 数量
```
