### 与 idm 集成

### 在 helper 上安装 ipa 
参考
https://www.systutorials.com/docs/linux/man/1-ipa-server-install/<br>
https://raymii.org/s/snippets/FreeIPA_DNS_workaround_for_DNS_zone_already_exists_in_DNS_and_is_handled_by_servers.html
```

# 配置 helper 的某个网口连接 External 网络
nmcli con add type ethernet \
  con-name ens10 \
  ifname ens10 \
  connection.autoconnect 'yes' \
  ipv4.method 'manual' \
  ipv4.address '192.168.122.3/24' \
  ipv4.gateway '192.168.122.1' \
  ipv4.dns '192.168.122.3' 
nmcli con up ens10  

# 删除 virbr0 network manager connection
nmcli con delete virbr0

# 启用模块 idm:DL1  
[root@helper ~]# dnf module enable idm:DL1 -y
# 执行 distro-sync 
dnf distro-sync -y

# 安装模块 profile idm:DL1/dns
dnf module enable idm:DL1 -y
dnf module install idm:DL1/dns -y

# 配置 chrony
NTPSERVER="clock.corp.redhat.com"
LOCALSUBNET=$(ip r s | grep ens3 | grep -v default | awk '{print $1}')

yum install -y chrony
cat > /etc/chrony.conf << EOF
server ${NTPSERVER} iburst
stratumweight 0
driftfile /var/lib/chrony/drift
rtcsync
makestep 10 3
bindcmdaddress 127.0.0.1
bindcmdaddress ::1
cmdallow 127.0.0.1
allow ${LOCALSUBNET}
keyfile /etc/chrony.keys
commandkey 1
generatecommandkey
noclientlog
logchange 0.5
logdir /var/log/chrony
EOF

firewall-cmd --add-service=ntp
firewall-cmd --add-service=ntp --permanent
firewall-cmd --reload

systemctl enable chronyd
systemctl restart chronyd
chronyc -n sources
chronyc -n tracking

# 执行 ipa server 的安装
sed -ie '/helper.example.com/d ' /etc/hosts
echo "192.168.122.3 helper.example.com" >> /etc/hosts
ipa-server-install -a redhat123 --hostname=helper.example.com -r EXAMPLE.COM -p redhat123 -n example.com -U --setup-dns  --allow-zone-overlap --no-forwarders

# 或者使用 dns forwarder 
ipa-server-install -a redhat123 --hostname=helper.example.com -r EXAMPLE.COM -p redhat123 -n example.com -U --setup-dns  --allow-zone-overlap --forwarder=192.168.122.1

# 配置防火墙开放服务
firewall-cmd --add-service={http,https,dns,ntp,freeipa-ldap,freeipa-ldaps} --permanent
firewall-cmd --reload

# 设置 dns 记录
# 
[root@helper ~]#  cat >> ~/.bashrc << EOF
export LC_ALL=en_US.UTF-8
EOF
[root@helper ~]# source ~/.bashrc
[root@helper ~]# echo 'redhat123' | kinit admin
[root@helper ~]# ipa dnsrecord-add example.com overcloud --a-ip-address=192.168.122.40
[root@helper ~]# ipa dnsrecord-add example.com overcloud.ctlplane --a-ip-address=192.0.2.240
[root@helper ~]# ipa dnsrecord-add example.com overcloud.internalapi --a-ip-address=172.16.2.240
[root@helper ~]# ipa dnsrecord-add example.com overcloud.storage --a-ip-address=172.16.1.240
[root@helper ~]# ipa dnsrecord-add example.com overcloud.storagemgmt --a-ip-address=172.16.3.240

# 添加 student 用户
[root@helper ~]# echo 'redhat123' | ipa user-add --first=Student --last=OpenStack student --password

# 更新 httpd/conf.d/ipa-pki-proxy.conf 的 RewriteRule
[root@helper ~]# cd /etc/httpd/conf.d
[root@helper ~]# sed -ie 's|^#RewriteRule|RewriteRule|' ipa-pki-proxy.conf
[root@helper ~]# systemctl reload httpd
```


```
# 在 undercloud 上生成 ~/templates/keystone_domain_specific_ldap_backend.yaml 配置文件
[stack@undercloud ~]$ cat > ~/templates/keystone_domain_specific_ldap_backend.yaml <<EOF
parameter_defaults:
  KeystoneLDAPDomainEnable: true
  KeystoneLDAPBackendConfigs:
    helper:
      url: ldap://192.168.122.3
      user: uid=admin,cn=users,cn=compat,dc=example,dc=com
      password: redhat123
      suffix: dc=example,dc=com
      user_tree_dn: cn=users,cn=accounts,dc=example,dc=com
      user_filter: ""
      user_objectclass: person
      user_id_attribute: uid
      user_name_attribute: uid
      user_allow_create: false
      user_allow_update: false
      user_allow_delete: false
EOF

# undercloud 安装 python3-novajoin
(undercloud) [stack@undercloud ~]$ sudo dnf install python3-novajoin -y

# 设置 DNS 
(undercloud) [stack@undercloud ~]$ sudo sed -i 's/192.168.122.1/192.168.122.3/' /etc/resolv.conf
(undercloud) [stack@undercloud ~]$ sudo nmcli con mod ens12 ipv4.dns '192.168.122.3'
(undercloud) [stack@undercloud ~]$ sudo nmcli con mod ens3 ipv4.dns '' ipv6.ignore-auto-dns 'yes'
(undercloud) [stack@undercloud ~]$ sudo nmcli con down ens3 && sudo nmcli con up ens3
(undercloud) [stack@undercloud ~]$ sudo nmcli con down ens12 && sudo nmcli con up ens12
(undercloud) [stack@undercloud ~]$ sudo -i 
[root@undercloud ~]# sed -ie '/undercloud.example.com/d' /etc/hosts
[root@undercloud ~]# sed -ie '/helper.example.com/d' /etc/hosts
[root@undercloud ~]# echo '192.168.122.2 undercloud.example.com' >> /etc/hosts
[root@undercloud ~]# echo '192.168.122.3 helper.example.com' >> /etc/hosts
[root@undercloud ~]# exit

# 生成 OTP 
[stack@undercloud ~]$ otp=$(sudo /usr/libexec/novajoin-ipa-setup --principal admin --password redhat123 --server helper.example.com --realm EXAMPLE.COM --domain example.com --hostname undercloud.example.com --precreate)

# 安装 crudini 
[stack@undercloud ~]$ sudo yum install -y crudini

# 修改 undercloud.conf 连接 idm 
[stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT enable_novajoin true
[stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT overcloud_domain_name example.com
[stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT undercloud_hostname undercloud.example.com
[stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT undercloud_nameservers 192.168.122.3
[stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT ipa_otp $otp

# 设置 undercloud 与 helper 时间同步
[stack@undercloud ~]$ sudo cat > /etc/chrony.conf <<EOF
server 192.168.122.3 iburst
bindaddress 192.0.2.1
allow all
local stratum 4
EOF
[stack@undercloud ~]$ sudo systemctl restart chronyd
[stack@undercloud ~]$ sudo chronyc -n sources
[stack@undercloud ~]$ sudo chronyc -n tracking

# 如果 undercloud 与 helper 时间有比较大的差距
[stack@undercloud ~]$ sudo chrnoyc -a makestep 10 -1
[stack@undercloud ~]$ sudo chronyc -n tracking

# 更新 undercloud
[stack@undercloud ~]$ openstack undercloud install

# 检查 undercloud ctlplane-subnet 的 dns_nameservers
(undercloud) [stack@undercloud ~]$ openstack subnet show ctlplane-subnet -c dns_nameservers -f value

# 更新 ~/templates/environments/network-environment.yaml 的 dns 配置
(undercloud) [stack@undercloud ~]$ sed -i 's/  DnsServers: \[\]/  DnsServers: ["192.168.122.3"]/' ~/templates/environments/network-environment.yaml
(undercloud) [stack@undercloud ~]$ grep DnsServers ~/templates/environments/network-environment.yaml

# 生成 ~/templates/custom-domain.yaml 文件
(undercloud) [stack@undercloud ~]$ THT=/usr/share/openstack-tripleo-heat-templates/
(undercloud) [stack@undercloud ~]$ sed 's/localdomain/example.com/' $THT/environments/predictable-placement/custom-domain.yaml | tee ~/templates/custom-domain.yaml

# 拷贝 enable-tls.yaml, inject-trust-anchor.yaml 
[stack@undercloud ~]$ cp ~/rendered/environments/ssl/enable-tls.yaml ~/templates
[stack@undercloud ~]$ cp ~/rendered/environments/ssl/inject-trust-anchor.yaml ~/templates/inject-trust-anchor.yaml

# 替换 inject-trust-anchor.yaml 里的相对路径到绝对路径
[stack@undercloud ~]$ sed -i 's#\.\./\.\.#/usr/share/openstack-tripleo-heat-templates#' ~/templates/inject-trust-anchor.yaml
[stack@undercloud ~]$ grep NodeTLSCAData ~/templates/inject-trust-anchor.yaml

# 生成 private ssl key
[stack@undercloud ~]$ openssl genrsa -out ~/templates/overcloud-privkey.pem 2048

# 生成自签名证书
[stack@undercloud ~]$ openssl req -new -x509 -key ~/templates/overcloud-privkey.pem -out ~/templates/overcloud-cacert.pem -days 365 -subj '/C=US/ST=NC/L=Raleigh/O=Red Hat/OU=QE/CN=overcloud.example.com'

# 查看生成的自签名证书
[stack@undercloud ~]$ openssl x509 -in ~/templates/overcloud-cacert.pem -text -noout

# 拷贝自签名证书和 IPA CA 证书到 undercloud 的 trusted store
[stack@undercloud ~]$ cat ~/templates/overcloud-cacert.pem /etc/ipa/ca.crt  > ~/cacert.pem
[stack@undercloud ~]$ sudo cp ~/cacert.pem /etc/pki/ca-trust/source/anchors/ca.crt.pem
[stack@undercloud ~]$ sudo update-ca-trust extract

# 在 enable-tls.yaml 中添加 ca cert
[stack@undercloud ~]$ cd ~/templates
[stack@undercloud templates]$ sed -i -e '/The contents of your certificate go here/r overcloud-cacert.pem' -e '/The contents of your certificate go here/ d' enable-tls.yaml
[stack@undercloud templates]$ sed -i  -e '/-----BEGIN CERT/,/-----END CERT/{s/^/    /g}' enable-tls.yaml

# 在 enable-tls.yaml 中添加 ssl private key
[stack@undercloud templates]$ sed -i -e '/The contents of the private key go here/r overcloud-privkey.pem' -e '/The contents of the private key go here/ d' enable-tls.yaml
[stack@undercloud templates]$ sed -i -e '/-----BEGIN RSA/,/-----END RSA/{s/^/    /g}' enable-tls.yaml

# 在 enable-tls.yaml 中设置 PublicTLSCAFile 指向 /etc/pki/ca-trust/source/anchors/ca.crt.pem
(undercloud) [stack@undercloud templates]$ sed -i "s#PublicTLSCAFile: ''#PublicTLSCAFile: '/etc/pki/ca-trust/source/anchors/ca.crt.pem'#" enable-tls.yaml

# 在 inject-trust-anchor.yaml 中添加 cacert.pem
[stack@undercloud templates]$ sed -i -e '/The contents of your certificate go here/r /home/stack/cacert.pem' -e '/The contents of your certificate go here/ d' inject-trust-anchor.yaml
[stack@undercloud templates]$ sed -i  -e '/-----BEGIN CERT/,/-----END CERT/{s/^/    /g}' inject-trust-anchor.yaml

# 检查 enable-tls.yaml 和 inject-trust-anchor.yaml
[stack@undercloud templates]$ cat enable-tls.yaml
[stack@undercloud templates]$ cat inject-trust-anchor.yaml
[stack@undercloud templates]$ cd ~

# 生成 deploy-enable-tls.sh 
cat > ~/deploy-enable-tls.sh << 'EOF'
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
-e ~/containers-prepare-parameter.yaml \
-e $CNF/custom-domain.yaml \
-e $CNF/node-info.yaml \
-e $CNF/enable-tls.yaml \
-e $CNF/inject-trust-anchor.yaml \
-e $CNF/keystone_domain_specific_ldap_backend.yaml \
-e $CNF/cephstorage.yaml \
-e $CNF/fix-nova-reserved-host-memory.yaml \
--ntp-server 192.0.2.1
EOF
```
