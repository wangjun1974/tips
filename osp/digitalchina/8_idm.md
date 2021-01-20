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
dnf module install idm:DL1/dns -y

# 执行 ipa server 的安装
sed -ie '/helper.example.com/d ' /etc/hosts
echo "192.168.122.3 helper.example.com" >> /etc/hosts
ipa-server-install -a redhat123 --hostname=helper.example.com -r EXAMPLE.COM -p redhat123 -n example.com -U --setup-dns  --allow-zone-overlap --no-forwarders

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

# 
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

# 
(undercloud) [stack@undercloud ~]$ sudo sed -i 's/192.168.122.1/192.168.122.3/' /etc/resolv.conf
(undercloud) [stack@undercloud ~]$ sudo nmcli con mod ens12 ipv4.dns '192.168.122.3'
(undercloud) [stack@undercloud ~]$ sudo nmcli con mod ens3 ipv4.dns '' ipv6.ignore-auto-dns 'yes'
(undercloud) [stack@undercloud ~]$ sudo nmcli con down ens3 && sudo nmcli con up ens3
(undercloud) [stack@undercloud ~]$ sudo nmcli con down ens12 && sudo nmcli con up ens12
(undercloud) [stack@undercloud ~]$ sudo -i 
[root@undercloud ~]# sed -ie '/undercloud.example.com/d '/etc/hosts
[root@undercloud ~]# sed -ie '/helper.example.com/d '/etc/hosts
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

# 更新 undercloud
[stack@undercloud ~]$ openstack undercloud install

# 检查 undercloud ctlplane-subnet 的 dns_nameservers
(undercloud) [stack@undercloud ~]$ openstack subnet show ctlplane-subnet -c dns_nameservers -f value
```
