### OSP 16.1 与 Red Hat Ceph Storage Dashboard
https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html-single/deploying_an_overcloud_with_containerized_red_hat_ceph/index#adding-ceph-dashboard
```

# 添加模版 $THT/environments/ceph-ansible/ceph-dashboard.yaml
cat > deploy-enable-tls-octavia-stf-cephdashboard.sh<<'EOF'
#!/bin/bash
THT=/usr/share/openstack-tripleo-heat-templates/
CNF=~/templates/

source ~/stackrc
openstack overcloud deploy --debug --templates $THT \
-r $CNF/roles_data.yaml \
-n $CNF/network_data.yaml \
-e $THT/environments/ceph-ansible/ceph-ansible.yaml \
-e $THT/environments/ceph-ansible/ceph-rgw.yaml \
-e $THT/environments/ceph-ansible/ceph-dashboard.yaml \
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

# 获取 dashboard admin password
(undercloud) [stack@undercloud ~]$ sudo grep dashboard_admin_password /var/lib/mistral/overcloud/ceph-ansible/group_vars/all.yml

# 获取 dashboard 的地址
(undercloud) [stack@undercloud ~]$ sudo grep dashboard_frontend_vip /var/lib/mistral/overcloud/ceph-ansible/group_vars/all.yml

# 访问 Ceph dashboard
https://overcloud.ctlplane.example.com:8444
# 也可以访问
https://overcloud-controller-0.storage.example.com:8444

# 获取 dashboard admin password
(undercloud) [stack@undercloud ~]$ sudo grep grafana_admin_password /var/lib/mistral/overcloud/ceph-ansible/group_vars/all.yml

# 访问 Grafana dashboard
https://overcloud.ctlplane.example.com:3100
# 也可以访问
https://overcloud-controller-0.storage.example.com:3100

``` 

### 如何改变 Grafana password in director
[rhos-tech] [ceph-dashboard] How to change the Grafana password in director deployed ceph
```
# 检查这个模版文件
/usr/share/openstack-tripleo-heat-templates/deployment/ceph-ansible/ceph-base.yaml
```

### 手工修改 haproxy.cfg 文件
```
# 对于 OSP 16.2，可以定义 CephDashboardNetwork 参数指定 dashboard 所在的网络
# 邮件名 [rhos-tech] Ceph-Dahsboard in RHOSP16.1
[1] https://bugzilla.redhat.com/show_bug.cgi?id=1969411
[2] https://bugzilla.redhat.com/show_bug.cgi?id=1973638
[3] https://review.opendev.org/q/5dc5cdb62639fc240fd44b50b5322888fc40efc3

# 对于 OSP 16.1，目前只能手工修改
# Ceph dashboard 只支持部署到 overcloud ctrlplane 的 vip 所在的网络或者单独的 CephDashboardNetwork 上
# 可以手工修改 overcloud controller 的 haproxy 配置文件 /etc/pki/tls/private/overcloud_endpoint.pem
# 添加监听 external network 的选项
# bind 192.168.122.40:8444 transparent ssl crt /etc/pki/tls/private/overcloud_endpoint.pem

ssh heat-admin@192.0.2.51
sudo -i
cat /var/lib/config-data/puppet-generated/haproxy/etc/haproxy/haproxy.cfg
...
listen ceph_dashboard
  bind 192.0.2.240:8444 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem
  bind 192.168.122.40:8444 transparent ssl crt /etc/pki/tls/private/overcloud_endpoint.pem
  mode http
  balance source
  http-check expect rstatus 2[0-9][0-9]
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
  http-request set-header X-Forwarded-Proto http if !{ ssl_fc }
  http-request set-header X-Forwarded-Port %[dst_port]
  option httpchk HEAD /
  server overcloud-controller-0.storage.example.com 172.16.1.51:8444 check fall 5 inter 2000 rise 2 ssl check verify none verifyhost overcloud-controller-0.storage.example.com
...

listen ceph_grafana
  bind 192.0.2.240:3100 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem
  bind 192.168.122.40:3100 transparent ssl crt /etc/pki/tls/private/overcloud_endpoint.pem
  mode http
  balance source
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
  http-request set-header X-Forwarded-Proto http if !{ ssl_fc }
  http-request set-header X-Forwarded-Port %[dst_port]
  option httpchk HEAD /
  server overcloud-controller-0.storage.example.com 172.16.1.51:3100 ca-file /etc/ipa/ca.crt check fall 5 inter 2000 rise 2 ssl verify required verify
host overcloud-controller-0.storage.example.com
  server overcloud-controller-1.storage.example.com 172.16.1.52:3100 ca-file /etc/ipa/ca.crt check fall 5 inter 2000 rise 2 ssl verify required verify
host overcloud-controller-1.storage.example.com
  server overcloud-controller-2.storage.example.com 172.16.1.53:3100 ca-file /etc/ipa/ca.crt check fall 5 inter 2000 rise 2 ssl verify required verify
host overcloud-controller-2.storage.example.com
...

# 重启 haproxy 服务
pcs resource restart haproxy-bundle

# 检查并且编辑 /var/lib/config-data/puppet-generated/haproxy/etc/haproxy/haproxy.cfg 文件
sed -i -e 's|bind 192.0.2.240:3100 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem|bind 192.0.2.240:3100 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem\n  bind 192.168.122.40:3100 transparent ssl crt /etc/pki/tls/private/overcloud_endpoint.pem|' -e 's|bind 192.0.2.240:8444 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem|bind 192.0.2.240:8444 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem\n  bind 192.168.122.40:8444 transparent ssl crt /etc/pki/tls/private/overcloud_endpoint.pem|' /var/lib/config-data/puppet-generated/haproxy/etc/haproxy/haproxy.cfg

# 修改 haproxy.cfg 文件
# ceph_dashboard 和 ceph_grafana 
# bind 到 external 网络上
ansible -i /tmp/inventory controller -m shell -a "sed -i -e 's|bind 192.0.2.240:3100 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem|bind 192.0.2.240:3100 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem\n  bind 192.168.122.40:3100 transparent ssl crt /etc/pki/tls/private/overcloud_endpoint.pem|' -e 's|bind 192.0.2.240:8444 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem|bind 192.0.2.240:8444 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem\n  bind 192.168.122.40:8444 transparent ssl crt /etc/pki/tls/private/overcloud_endpoint.pem|' /var/lib/config-data/puppet-generated/haproxy/etc/haproxy/haproxy.cfg"

# 重启 haproxy-bundle
ssh stack@192.0.2.51 sudo pcs resource disable haproxy-bundle
ssh stack@192.0.2.51 sudo pcs resource enable haproxy-bundle

```