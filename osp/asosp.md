Advanced Storage with Red Hat OpenStack Platform

========
[root@pool10-iad ~]# for i in {1..3}; do virsh shutdown ceph-node0$i; done
Domain ceph-node01 is being shutdown
 
Domain ceph-node02 is being shutdown
 
Domain ceph-node03 is being shutdown
[root@pool10-iad ~]# ssh stack@undercloud
Activate the web console with: systemctl enable --now cockpit.socket
 
This system is not registered to Red Hat Insights. See https://cloud.redhat.com/
To register this system, run: insights-client --register
 
Last login: Fri Jul 10 01:13:55 2020
[stack@undercloud ~]$ source ~/stackrc
(undercloud) [stack@undercloud ~]$ openstack overcloud delete overcloud --yes
Undeploying stack overcloud...
Waiting for messages on queue 'tripleo' with no timeout.
Deleting plan overcloud...
Success.
(undercloud) [stack@undercloud ~]$ exit
[root@pool10-iad ~]# sh -x setup-env-ipa.sh
+ CLASSROOM_SERVER=10.149.23.10
+ PASSWORD_FOR_VMS='r3dh4t1!'
+ OFFICIAL_IMAGE=rhel-8.qcow2
+ export LIBGUESTFS_PATH=/var/lib/libvirt/images/appliance/
+ LIBGUESTFS_PATH=/var/lib/libvirt/images/appliance/
 
<<OMITTED>>
+ virt-install --ram 2048 --vcpus 1 --os-variant rhel8.0 --cpu host,+vmx --disk path=/var/lib/libvirt/images/ipa.qcow2,device=disk,bus=virtio,format=qcow2 --noautoconsole --vnc --network network=trunk,mac=52:54:00:01:20:21 --name ipa --dry-run --print-xml
+ virsh define /root/host-ipa.xml
Domain ipa defined from /root/host-ipa.xml
 
+ virsh start ipa
Domain ipa started
[root@pool10-iad ~]# 
[root@pool10-iad ~]# ssh root@192.168.0.252 
The authenticity of host '192.168.0.252 (192.168.0.252)' can't be established.
ECDSA key fingerprint is SHA256:DidcsYD6y23mXNLLhDr4bNy9qPvOBpA19CCgxgqDOqg.
ECDSA key fingerprint is MD5:77:28:c1:95:9a:3c:d8:ca:a7:60:73:8f:16:25:86:a6.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.0.252' (ECDSA) to the list of known hosts.
root@192.168.0.252's password: 
Activate the web console with: systemctl enable --now cockpit.socket
 
This system is not registered to Red Hat Insights. See https://cloud.redhat.com/
To register this system, run: insights-client --register
 
[root@ipa ~]# 
[root@ipa ~]# yum module enable idm:DL1 -y
rhel-8-for-x86_64-baseos-rpms                                                                                              76 MB/s |  15 MB     00:00    
rhel-8-for-x86_64-appstream-rpms                                                                                           78 MB/s |  15 MB     00:00    
rhel-8-for-x86_64-highavailability-rpms                                                                                    61 MB/s | 1.4 MB     00:00    
ansible-2.8-for-rhel-8-x86_64-rpms                                                                                         49 MB/s | 733 kB     00:00    
fast-datapath-for-rhel-8-x86_64-rpms                                                                                      8.4 MB/s |  68 kB     00:00    
openstack-16-for-rhel-8-x86_64-rpms                                                                                        64 MB/s | 1.8 MB     00:00    
rhceph-4-tools-for-rhel-8-x86_64-rpms                                                                                     7.5 MB/s |  59 kB     00:00    
Dependencies resolved.
==========================================================================================================================================================
 Package                              Architecture                        Version                              Repository                            Size
==========================================================================================================================================================
Enabling module streams:
 389-ds                                                                   1.4                                                                            
 httpd                                                                    2.4                                                                            
 idm                                                                      DL1                                                                            
 pki-core                                                                 10.6                                                                           
 pki-deps                                                                 10.6                                                                           
 
Transaction Summary
==========================================================================================================================================================
 
Complete!
[root@ipa ~]# yum distro-sync -y
<<OMITTED>>
  rhnsd-5.0.35-3.module+el8+2754+6a08e8f4.x86_64                                    insights-client-3.0.13-1.el8_1.noarch                                
  qemu-guest-agent-15:2.12.0-88.module+el8.1.0+5708+85d8e057.3.x86_64               python3-six-1.12.0-1.el8ost.noarch                                   
  python3-dateutil-1:2.8.0-1.el8ost.noarch                                          python3-netifaces-0.10.9-2.el8ost.x86_64                             
 
Installed:
  kernel-modules-4.18.0-147.8.1.el8_1.x86_64               kernel-4.18.0-147.8.1.el8_1.x86_64              kernel-core-4.18.0-147.8.1.el8_1.x86_64       
  linux-firmware-20190516-94.git711d3297.el8.noarch        grub2-tools-efi-1:2.02-78.el8_1.1.x86_64       
 
Complete!
[root@ipa ~]# 
[root@ipa ~]# yum module install idm:DL1/dns -y
<<OMITTED>>
  nss-util-3.44.0-9.el8_1.x86_64                                                 nss-tools-3.44.0-9.el8_1.x86_64                                          
  nss-softokn-3.44.0-9.el8_1.x86_64                                              ipa-client-4.8.0-13.module+el8.1.0+4923+c6efe041.x86_64                  
  nss-softokn-freebl-3.44.0-9.el8_1.x86_64                                       python3-markupsafe-1.1.0-2.el8ost.x86_64                                 
  fontawesome-fonts-4.7.0-6.el8ost.noarch                                       
 
Complete!
[root@ipa ~]# echo "192.168.0.252 ipa.example.com" >> /etc/hosts
[root@ipa ~]# ipa-server-install -a r3dh4t1\! --hostname=ipa.example.com -r EXAMPLE.COM -p r3dh4t1\!  -n example.com -U --setup-dns  --allow-zone-overlap --auto-forwarders
<<OMITTED>>
Setup complete
 
Next steps:
        1. You must make sure these network ports are open:
                TCP Ports:
                  * 80, 443: HTTP/HTTPS
                  * 389, 636: LDAP/LDAPS
                  * 88, 464: kerberos
                  * 53: bind
                UDP Ports:
                  * 88, 464: kerberos
                  * 53: bind
                  * 123: ntp
 
        2. You can now obtain a kerberos ticket using the command: 'kinit admin'
           This ticket will allow you to use the IPA tools (e.g., ipa user-add)
           and the web user interface.
 
Be sure to back up the CA certificates stored in /root/cacert.p12
These files are required to create replicas. The password for these
files is the Directory Manager password
The ipa-server-install command was successful
 
[root@ipa ~]# echo 'r3dh4t1!' | kinit admin
Password for admin@EXAMPLE.COM: 
[root@ipa ~]# ipa dnsrecord-add example.com overcloud --a-ip-address=192.168.0.150
  Record name: overcloud
  A record: 192.168.0.150
[root@ipa ~]# ipa dnsrecord-add example.com overcloud.ctlplane --a-ip-address=192.0.2.150
  Record name: overcloud.ctlplane
  A record: 192.0.2.150
[root@ipa ~]# ipa dnsrecord-add example.com overcloud.ctlplane --a-ip-address=192.0.2.150
  Record name: overcloud.ctlplane
  A record: 192.0.2.150
[root@ipa ~]# ipa dnsrecord-add example.com overcloud.internalapi --a-ip-address=172.17.0.150
  Record name: overcloud.internalapi
  A record: 172.17.0.150
[root@ipa ~]# ipa dnsrecord-add example.com overcloud.storage --a-ip-address=172.18.0.150
  Record name: overcloud.storage
  A record: 172.18.0.150
[root@ipa ~]# ipa dnsrecord-add example.com overcloud.storagemgmt --a-ip-address=172.19.0.150
  Record name: overcloud.storagemgmt
  A record: 172.19.0.150
[root@ipa ~]# ipa dnsrecord-add example.com classroom --a-ip-address=10.149.23.10
  Record name: classroom
  A record: 10.149.23.10
[root@ipa ~]# echo 'r3dh4t1!' | ipa user-add --first=Student --last=OpenStack student --password
--------------------
Added user "student"
--------------------
  User login: student
  First name: Student
  Last name: OpenStack
  Full name: Student OpenStack
  Display name: Student OpenStack
  Initials: SO
  Home directory: /home/student
  GECOS: Student OpenStack
  Login shell: /bin/sh
  Principal name: student@EXAMPLE.COM
  Principal alias: student@EXAMPLE.COM
  User password expiration: 20200710062736Z
  Email address: student@example.com
  UID: 10200001
  GID: 10200001
  Password: True
  Member of groups: ipausers
  Kerberos keys available: True
 
[root@ipa conf.d]# cd /etc/httpd/conf.d
[root@ipa conf.d]# sed -ie 's|^#RewriteRule|RewriteRule|' ipa-pki-proxy.conf           
[root@ipa conf.d]# cat ipa-pki-proxy.conf | grep RewriteRule
RewriteRule ^/ipa/crl/MasterCRL.bin http://ipa.example.com/ca/ee/ca/getCRL?op=getCRL&crlIssuingPoint=MasterCRL [L,R=301,NC]
[root@ipa conf.d]# systemctl reload httpd
[root@ipa conf.d]# exit
logout
Connection to 192.168.0.252 closed.
[root@pool10-iad ~]# ssh stack@undercloud
Activate the web console with: systemctl enable --now cockpit.socket
 
This system is not registered to Red Hat Insights. See https://cloud.redhat.com/
To register this system, run: insights-client --register
 
Last login: Fri Jul 10 01:52:33 2020 from 192.168.0.1
[stack@undercloud ~]$ 
[stack@undercloud ~]$ cat > ~/templates/keystone_domain_specific_ldap_backend.yaml <<EOF
> parameter_defaults:
>   KeystoneLDAPDomainEnable: true
>   KeystoneLDAPBackendConfigs:
>     gpte:
>       url: ldap://192.168.0.252
>       user: uid=admin,cn=users,cn=compat,dc=example,dc=com
>       password: r3dh4t1!
>       suffix: dc=example,dc=com
>       user_tree_dn: cn=users,cn=accounts,dc=example,dc=com
>       user_filter: ""
>       user_objectclass: person
>       user_id_attribute: uid
>       user_name_attribute: uid
>       user_allow_create: false
>       user_allow_update: false
>       user_allow_delete: false
> EOF
[stack@undercloud ~]$  grep PublicVirtualFixedIPs ~/templates/ips-from-pool-all.yaml
  PublicVirtualFixedIPs: [{'ip_address':'10.0.0.150'}]
[stack@undercloud ~]$ cp ~/rendered/environments/ssl/enable-tls.yaml ~/templates
[stack@undercloud ~]$ cp ~/rendered/environments/ssl/inject-trust-anchor.yaml ~/templates/inject-trust-anchor.yaml
[stack@undercloud ~]$ sed -i 's#\.\./\.\.#/usr/share/openstack-tripleo-heat-templates#' ~/templates/inject-trust-anchor.yaml
[stack@undercloud ~]$ grep NodeTLSCAData ~/templates/inject-trust-anchor.yaml
  OS::TripleO::NodeTLSCAData: /usr/share/openstack-tripleo-heat-templates/puppet/extraconfig/tls/ca-inject.yaml
[stack@undercloud ~]$ openssl genrsa -out ~/templates/overcloud-privkey.pem 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
...............................+++++
............................+++++
e is 65537 (0x010001)
[stack@undercloud ~]$ openssl req -new -x509 -key ~/templates/overcloud-privkey.pem -out ~/templates/overcloud-cacert.pem -days 365 -subj '/C=US/ST=NC/L=Raleigh/O=Red Hat/OU=QE/CN=overcloud.example.com'
[stack@undercloud ~]$ openssl x509 -in ~/templates/overcloud-cacert.pem -text -noout | head -11
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            08:6c:82:ce:b7:7b:74:dd:a5:bd:38:bf:73:2a:6e:99:c0:26:21:6f
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, ST = NC, L = Raleigh, O = Red Hat, OU = QE, CN = overcloud.example.com
        Validity
            Not Before: Jul 10 06:37:54 2020 GMT
            Not After : Jul 10 06:37:54 2021 GMT
        Subject: C = US, ST = NC, L = Raleigh, O = Red Hat, OU = QE, CN = overcloud.example.com
[stack@undercloud ~]$ sudo cp ~/templates/overcloud-cacert.pem /etc/pki/ca-trust/source/anchors/
[stack@undercloud ~]$ sudo update-ca-trust extract
[stack@undercloud templates]$ sed -i -e '/The contents of your certificate go here/r overcloud-cacert.pem' -e '/The contents of your certificate go here/ d' enable-tls.yaml
[stack@undercloud templates]$ sed -i  -e '/-----BEGIN CERT/,/-----END CERT/{s/^/    /g}' enable-tls.yaml
[stack@undercloud templates]$ sed -i -e '/The contents of the private key go here/r overcloud-privkey.pem' -e '/The contents of the private key go here/ d' enable-tls.yaml
[stack@undercloud templates]$ sed -i -e '/-----BEGIN RSA/,/-----END RSA/{s/^/    /g}' enable-tls.yaml
[stack@undercloud templates]$ sed -i -e '/The contents of your certificate go here/r overcloud-cacert.pem' -e '/The contents of your certificate go here/ d' inject-trust-anchor.yaml
[stack@undercloud templates]$ sed -i  -e '/-----BEGIN CERT/,/-----END CERT/{s/^/    /g}' inject-trust-anchor.yaml
[stack@undercloud templates]$ cat enable-tls.yaml | grep -E "SSLCertificate|SSLKey|NodeTLSData" -A2
  SSLCertificate: |
    -----BEGIN CERTIFICATE-----
    MIIDtzCCAp+gAwIBAgIUCGyCzrd7dN2lvTi/cypumcAmIW8wDQYJKoZIhvcNAQEL
--
  SSLKey: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEAnTKFXDEPl7SbfUkN176pNb3NyV+0r1QaQmLL5S8uriN8PSaR
--
  DeployedSSLCertificatePath: /etc/pki/tls/private/overcloud_endpoint.pem
 
  # *********************
[stack@undercloud templates]$ cat inject-trust-anchor.yaml | grep -E "SSLRootCertificate|NodeTLSCAData" -A2
  SSLRootCertificate: |
    -----BEGIN CERTIFICATE-----
    MIIDtzCCAp+gAwIBAgIUCGyCzrd7dN2lvTi/cypumcAmIW8wDQYJKoZIhvcNAQEL
--
  OS::TripleO::NodeTLSCAData: /usr/share/openstack-tripleo-heat-templates/puppet/extraconfig/tls/ca-inject.yaml
[stack@undercloud templates]$ cd 
[stack@undercloud ~]$ source stackrc 
(undercloud) [stack@undercloud ~]$ sudo dnf install python3-novajoin -y
<<OMITTED>>
Complete!
(undercloud) [stack@undercloud ~]$ sudo sed -i 's/192.168.0.1/192.168.0.252/' /etc/resolv.conf
(undercloud) [stack@undercloud ~]$ sudo /usr/libexec/novajoin-ipa-setup --principal admin --password r3dh4t1\! --server ipa.example.com --realm EXAMPLE.COM --domain example.com --hostname undercloud.example.com --precreate
4LseuHkS391xxGWcOza0tJjlWqlRp98G3Yh5m6TZuR5H
(undercloud) [stack@undercloud ~]$ sudo yum install -y crudini
<<OMITTED>>
Installed:
  crudini-0.9-6.el8ost.noarch                                                                                                                             
 
Complete!
(undercloud) [stack@undercloud ~]$ sudo chown stack:stack ~/undercloud.conf 
(undercloud) [stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT enable_novajoin true
(undercloud) [stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT overcloud_domain_name example.com
(undercloud) [stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT undercloud_hostname undercloud.example.com
(undercloud) [stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT undercloud_nameservers 192.168.0.252
(undercloud) [stack@undercloud ~]$ crudini --set ~/undercloud.conf DEFAULT ipa_otp 4LseuHkS391xxGWcOza0tJjlWqlRp98G3Yh5m6TZuR5H
(undercloud) [stack@undercloud ~]$ openstack undercloud install
<<OMITTED>>
##########################################################
 
The Undercloud has been successfully installed.
 
Useful files:
 
Password file is at /home/stack/undercloud-passwords.conf
The stackrc file is at ~/stackrc
 
Use these files to interact with OpenStack services, and
ensure they are secured.
 
##########################################################
(undercloud) [stack@undercloud ~]$ openstack subnet show ctlplane-subnet -c dns_nameservers -f value
['192.168.0.252']
(undercloud) [stack@undercloud ~]$ sed -i 's/  DnsServers: \[\]/  DnsServers: ["192.168.0.252"]/' ~/templates/environments/network-environment.yaml
(undercloud) [stack@undercloud ~]$ grep DnsServers ~/templates/environments/network-environment.yaml
  DnsServers: ["192.168.0.252"]
(undercloud) [stack@undercloud ~]$ THT=/usr/share/openstack-tripleo-heat-templates/
(undercloud) [stack@undercloud ~]$ sed 's/localdomain/example.com/' $THT/environments/predictable-placement/custom-domain.yaml | tee ~/templates/custom-domain.yaml
<<OMITTED>>
parameter_defaults:
  # The DNS domain used for the hosts. This must match the overcloud_domain_name configured on the undercloud.
  # Type: string
  CloudDomain: example.com
 
  # The DNS name of this cloud. E.g. ci-overcloud.tripleo.org
  # Type: string
  CloudName: overcloud.example.com
 
  # The DNS name of this cloud's provisioning network endpoint. E.g. 'ci-overcloud.ctlplane.tripleo.org'.
  # Type: string
  CloudNameCtlplane: overcloud.ctlplane.example.com
 
  # The DNS name of this cloud's internal_api endpoint. E.g. 'ci-overcloud.internalapi.tripleo.org'.
  # Type: string
  CloudNameInternal: overcloud.internalapi.example.com
 
  # The DNS name of this cloud's storage endpoint. E.g. 'ci-overcloud.storage.tripleo.org'.
  # Type: string
  CloudNameStorage: overcloud.storage.example.com
 
  # The DNS name of this cloud's storage_mgmt endpoint. E.g. 'ci-overcloud.storagemgmt.tripleo.org'.
  # Type: string
  CloudNameStorageManagement: overcloud.storagemgmt.example.com
(undercloud) [stack@undercloud ~]$ cat > ~/templates/ceph-config.yaml <<EOF
> parameter_defaults:
>   CephConfigOverrides:
>     osd_pool_default_size: 2
>     osd_pool_default_min_size: 1
>     mon_max_pg_per_osd: 1000
>   CephAnsibleDisksConfig:
>     osd_scenario: collocated
>     devices:
>       - /dev/vdb
> EOF
(undercloud) [stack@undercloud ~]$  cat > ~/templates/node-info.yaml <<EOF
> parameter_defaults:
>   OvercloudControlFlavor: baremetal
>   OvercloudComputeHCIFlavor: baremetal
>   ControllerCount: 3
>   ComputeHCICount: 2
>   BarbicanSimpleCryptoGlobalDefault: true
> EOF
(undercloud) [stack@undercloud ~]$ sed -i 's/Compute/ComputeHCI/' templates/environments/net-bond-with-vlans.yaml templates/environments/network-environment.yaml templates/ips-from-pool-all.yaml
(undercloud) [stack@undercloud ~]$ openstack overcloud roles generate Controller ComputeHCI -o templates/roles_data.yaml
# Add following lines into templates/roles_data.yaml ComputeHCI role
(undercloud) [stack@undercloud ~]$ vi templates/roles_data.yaml
    External:
      subnet: external_subnet
(undercloud) [stack@undercloud ~]$ THT=/usr/share/openstack-tripleo-heat-templates/
(undercloud) [stack@undercloud ~]$ cd $THT
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ tools/process-templates.py -r ~/templates/roles_data.yaml -n ~/templates/network_data.yaml -o ~/rendered
 
rendering j2 template to file: /home/stack/rendered/./puppet/controller-role.yaml
rendering j2 template to file: /home/stack/rendered/./puppet/computehci-role.yaml
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cp ~/rendered/environments/network-isolation.yaml ~/templates/environments/
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cp ~/rendered/environments/net-bond-with-vlans.yaml ~/templates/environments/
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cp ~/rendered/network/config/bond-with-vlans/computehci.yaml ~/templates/network/config/bond-with-vlans/
(undercloud) [stack@undercloud openstack-tripleo-heat-templates]$ cd 
(undercloud) [stack@undercloud ~]$ cat > ~/templates/scheduler-hints.yaml <<EOF
> parameter_defaults:
>   ControllerSchedulerHints:
>     'capabilities:node': 'controller-%index%'
>   ComputeHCISchedulerHints:
>     'capabilities:node': 'compute-%index%'
> EOF
(undercloud) [stack@undercloud ~]$ source ~/stackrc
(undercloud) [stack@undercloud ~]$ openstack baremetal node list
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+
| UUID                                 | Name                | Instance UUID | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+
| a9809617-348f-4868-a959-bc1fc8d66008 | overcloud-compute01 | None          | power off   | available          | False       |
| 1a9d691e-b2ba-4960-a06f-c2b3ca00ae72 | overcloud-compute02 | None          | power off   | available          | False       |
| ad363acd-4ea4-4842-91e8-beb92aafafad | overcloud-ctrl01    | None          | power off   | available          | False       |
| da620ce7-8ba0-4f99-b4a1-0302a05eec66 | overcloud-ctrl02    | None          | power off   | available          | False       |
| 05313bad-1ac3-4565-b95b-37ac40cc0323 | overcloud-ctrl03    | None          | power off   | available          | False       |
| be00cb2f-65a1-412d-9475-56ccbad77306 | overcloud-networker | None          | power off   | available          | False       |
| 0afc77b6-8736-456a-93b0-6e1360138c9d | overcloud-stor01    | None          | power off   | available          | False       |
+--------------------------------------+---------------------+---------------+-------------+--------------------+-------------+
(undercloud) [stack@undercloud ~]$ openstack baremetal introspection list
+--------------------------------------+---------------------+---------------------+-------+
| UUID                                 | Started at          | Finished at         | Error |
+--------------------------------------+---------------------+---------------------+-------+
| da620ce7-8ba0-4f99-b4a1-0302a05eec66 | 2020-07-06T05:00:18 | 2020-07-06T05:02:14 | None  |
| be00cb2f-65a1-412d-9475-56ccbad77306 | 2020-07-06T05:00:18 | 2020-07-06T05:02:05 | None  |
| ad363acd-4ea4-4842-91e8-beb92aafafad | 2020-07-06T05:00:18 | 2020-07-06T05:02:22 | None  |
| a9809617-348f-4868-a959-bc1fc8d66008 | 2020-07-06T05:00:18 | 2020-07-06T05:02:08 | None  |
| 1a9d691e-b2ba-4960-a06f-c2b3ca00ae72 | 2020-07-06T05:00:18 | 2020-07-06T05:01:52 | None  |
| 0afc77b6-8736-456a-93b0-6e1360138c9d | 2020-07-06T05:00:18 | 2020-07-06T05:01:57 | None  |
| 05313bad-1ac3-4565-b95b-37ac40cc0323 | 2020-07-06T05:00:18 | 2020-07-06T05:02:18 | None  |
+--------------------------------------+---------------------+---------------------+-------+
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-ctrl01 --property capabilities=node:controller-0,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-ctrl02 --property capabilities=node:controller-1,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-ctrl03 --property capabilities=node:controller-2,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-compute01 --property capabilities=node:compute-0,boot_option:local
(undercloud) [stack@undercloud ~]$ openstack baremetal node set overcloud-compute02 --property capabilities=node:compute-1,boot_option:local
(undercloud) [stack@undercloud ~]$ cat > ~/deploy-with-hci.sh << 'EOF'
> #!/bin/bash
> THT=/usr/share/openstack-tripleo-heat-templates/
> CNF=~/templates/
>
> source ~/stackrc
> openstack overcloud deploy --templates $THT \
> -r $CNF/roles_data.yaml \
> -n $CNF/network_data.yaml \
> -e $THT/environments/ips-from-pool-all.yaml \
> -e $THT/environments/cinder-backup.yaml \
> -e $THT/environments/ceph-ansible/ceph-rgw.yaml \
> -e $THT/environments/ceph-ansible/ceph-ansible.yaml \
> -e $THT/environments/ssl/enable-internal-tls.yaml \
> -e $THT/environments/ssl/tls-everywhere-endpoints-dns.yaml \
> -e $THT/environments/services/barbican.yaml \
> -e $THT/environments/barbican-backend-simple-crypto.yaml \
> -e $THT/environments/services/octavia.yaml \
> -e $CNF/environments/network-isolation.yaml \
> -e $CNF/environments/network-environment.yaml \
> -e $CNF/environments/net-bond-with-vlans.yaml \
> -e ~/containers-prepare-parameter.yaml \
> -e $CNF/custom-domain.yaml \
> -e $CNF/node-info.yaml \
> -e $CNF/HostnameMap.yaml \
> -e $CNF/ips-from-pool-all.yaml \
> -e $CNF/stf-connectors.yaml \
> -e $CNF/fencing.yaml \
> -e $CNF/enable-tls.yaml \
> -e $CNF/inject-trust-anchor.yaml \
> -e $CNF/keystone_domain_specific_ldap_backend.yaml \
> -e $CNF/scheduler-hints.yaml \
> -e $CNF/ceph-config.yaml \
> -e $CNF/fix-nova-reserved-host-memory.yaml
> EOF
(undercloud) [stack@undercloud ~]$ sh -x deploy-with-hci.sh
 
Ansible passed.
Overcloud configuration completed.
Overcloud Endpoint: https://overcloud.example.com:13000
Overcloud Horizon Dashboard URL: https://overcloud.example.com:443/dashboard
Overcloud rc file: /home/stack/overcloudrc
Overcloud Deployed
(undercloud) [stack@undercloud ~]$ source overcloudrc 
(overcloud) [stack@undercloud ~]$ openstack service list
+----------------------------------+-----------+----------------+
| ID                               | Name      | Type           |
+----------------------------------+-----------+----------------+
| 0c40cd4b49e74a4a99217dd6bf6e874d | heat      | orchestration  |
| 3dfd142725064b4f8ec28296fa7c1e06 | keystone  | identity       |
| 3ffe4e4fd9af4ad2ac7ec027809281fa | placement | placement      |
| 652abf4f9fd9430db44dc3682958b0e7 | glance    | image          |
| 6e06f9a219fb49d99aace81e14f2d537 | neutron   | network        |
| 8f99b32cd7764158816654c6fd57774d | octavia   | load-balancer  |
| a67541d67cfd42888d978a38af603359 | cinderv2  | volumev2       |
| a7f7b7af2fa144639fab1c932c7d3074 | heat-cfn  | cloudformation |
| b19ca16b82624d36992374f25320b7c4 | cinderv3  | volumev3       |
| c323ab0d987e41a2ba24705c6ebcced7 | swift     | object-store   |
| d89a17ed495046cb9d3433f196a1f1f8 | barbican  | key-manager    |
| ea2ff1c6c5074a4a9b7342124c65a958 | nova      | compute        |
+----------------------------------+-----------+----------------+

# Three RHOSP 16 Controller Node running the core RHOSP services with two RHOSP 13 Compute nodes
 
 
(undercloud) [stack@undercloud ~]$ openstack server list
+--------------------------------------+------------------------+--------+----------------------+----------------+-----------+
| ID                                   | Name                   | Status | Networks             | Image          | Flavor    |
+--------------------------------------+------------------------+--------+----------------------+----------------+-----------+
| 4108ab23-aac2-4d10-91dd-ae920c34e7b5 | lab-controller03       | ACTIVE | ctlplane=192.0.2.203 | overcloud-full | baremetal |
| 0a337045-ce4f-480c-847e-86b6adc1762f | lab-controller02       | ACTIVE | ctlplane=192.0.2.202 | overcloud-full | baremetal |
| 17f56512-44c5-446f-ad25-7e4ebf6aed39 | lab-controller01       | ACTIVE | ctlplane=192.0.2.201 | overcloud-full | baremetal |
| 3435cf97-e12b-49ed-8f2d-10bca9dc2e8c | overcloud-computehci-1 | ACTIVE | ctlplane=192.0.2.212 | overcloud-full | baremetal |
| 18070622-41ad-4a6d-8346-445828bd1af4 | overcloud-computehci-0 | ACTIVE | ctlplane=192.0.2.211 | overcloud-full | baremetal |
+--------------------------------------+------------------------+--------+----------------------+----------------+-----------+
 

# Cinder backups should be configured use a RBD backend
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane 'sudo podman ps | grep cinder'
80a462fe6057  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-cinder-backup:16.0-78               /bin/bash /usr/lo...  11 minutes ago  Up 11 minutes ago         openstack-cinder-backup-podman-0
c23891d0922a  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-cinder-scheduler:16.0-78            kolla_start           20 minutes ago  Up 20 minutes ago         cinder_scheduler
01bad4b38a69  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-cinder-api:16.0-76                  kolla_start           20 minutes ago  Up 20 minutes ago         cinder_api_cron
e811bbbfe5cc  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-cinder-api:16.0-76                  kolla_start           20 minutes ago  Up 20 minutes ago         cinder_api
 
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane 'sudo podman exec -it openstack-cinder-backup-podman-0 cat /etc/cinder/cinder.conf ' | grep backup | grep -v "^#" 
backup_ceph_conf=/etc/ceph/ceph.conf
backup_ceph_user=openstack
backup_ceph_chunk_size=134217728
backup_ceph_pool=backups
backup_ceph_stripe_unit=0
backup_ceph_stripe_count=0
backup_driver=cinder.backup.drivers.ceph.CephBackupDriver
 

# Glance should be configured to use a Ceph RBD storage pool called "images"
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane 'sudo podman exec -it glance_api cat /etc/glance/glance-api.conf ' | grep ^rbd_store_ceph_conf -B2 -A4
 
[default_backend]
rbd_store_ceph_conf=/etc/ceph/ceph.conf
rbd_store_user=openstack
rbd_store_pool=images
store_description=Default glance store backend.
 

# Glance image should be signed using keys storaed in barbican.
(overcloud) [stack@undercloud ~]$ openssl genrsa -out private_key.pem 1024
Generating RSA private key, 1024 bit long modulus (2 primes)
.........+++++
..+++++
e is 65537 (0x010001)
(overcloud) [stack@undercloud ~]$ openssl rsa -pubout -in private_key.pem -out public_key.pem
writing RSA key
(overcloud) [stack@undercloud ~]$ openssl req -new -key private_key.pem -out cert_request.csr -subj '/C=US/ST=NC/L=Raleigh/O=Red Hat/OU=QE/CN=overcloud.example.com'
(overcloud) [stack@undercloud ~]$ openssl x509 -req -days 14 -in cert_request.csr -signkey private_key.pem -out x509_signing_cert.crt
Signature ok
subject=C = US, ST = NC, L = Raleigh, O = Red Hat, OU = QE, CN = overcloud.example.com
Getting Private key
(overcloud) [stack@undercloud ~]$ openstack secret store --name signing-cert --algorithm RSA --secret-type certificate --payload-content-type "application/octet-stream" --payload-content-encoding base64  --payload "$(base64 x509_signing_cert.crt)" -c 'Secret href' -f value
https://overcloud.example.com:13311/v1/secrets/e69ba25b-30e7-484b-8c0a-4f3b2a4c3a78
(overcloud) [stack@undercloud ~]$ sudo yum install -y wget 
 
Installed:
  wget-1.19.5-8.el8_1.1.x86_64                                                                                                                           
 
Complete!
(overcloud) [stack@undercloud ~]$ wget https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
cirros-0.4.0-x86_64-disk.img           100%[=========================================================================>]  12.13M  45.7MB/s    in 0.3s    
 
2020-07-10 05:55:03 (45.7 MB/s) - âcirros-0.4.0-x86_64-disk.imgâ saved [12716032/12716032]
 
(overcloud) [stack@undercloud ~]$ openssl dgst -sha256 -sign private_key.pem -sigopt rsa_padding_mode:pss -out cirros-0.4.0.signature cirros-0.4.0-x86_64-disk.img
(overcloud) [stack@undercloud ~]$ base64 -w 0 cirros-0.4.0.signature  > cirros-0.4.0.signature.b64
(overcloud) [stack@undercloud ~]$ cirros_signature_b64=$(cat cirros-0.4.0.signature.b64)
(overcloud) [stack@undercloud ~]$ echo $cirros_signature_b64
ijasbYYytLRnkJz3WyYwclqdS5xeEnuIL+7HCnPXmSPmZ+RJhNWX9k7Lr7SNZznkxmQapbCLma8RIHc15aicrC9rN3oN7X0Qa9GoEjFBmVGtrb3LQmilcMTJ+eSci5KvhmI1Dt8VoUMxD1cyj5+TpxQl89iNmex6iX9x7Y5nqpI=
 
(overcloud) [stack@undercloud ~]$ openstack image create --container-format bare --disk-format qcow2 --property img_signature="$cirros_signature_b64" --property img_signature_certificate_uuid='e69ba25b-30e7-484b-8c0a-4f3b2a4c3a78' --property img_signature_hash_method='SHA-256' --property img_signature_key_type='RSA-PSS' cirros_0_4_0_signed < cirros-0.4.0-x86_64-disk.img
 
| status           | active                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| tags             |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| updated_at       | 2020-07-10T09:58:42Z                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| virtual_size     | None                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| visibility       | shared                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
+------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller03.ctlplane 'sudo podman exec -it glance_api grep -ri signature /var/log/glance/'
Warning: Permanently added 'lab-controller03.ctlplane' (ECDSA) to the list of known hosts.
/var/log/glance/api.log:2020-07-10 09:58:42.210 61 INFO glance.location [req-4b9fd9a5-5628-4267-abb0-523173435bdb 515c1a37073442d190089160fc8d0f1d a386e6a574fb40f5b05aaeffade27271 - default default] Successfully verified signature for image eb39973f-359c-44d6-bb34-32ff44f0f1c8

# Show the HCI Ceph status (ceph -s and ceph osd tree)
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller03.ctlplane 'sudo podman ps | grep cinder  ' 
cd266d8af1e9  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-cinder-volume:16.0-77               /bin/bash /usr/lo...  35 minutes ago     Up 35 minutes ago            openstack-cinder-volume-podman-0
84870f0a363b  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-cinder-scheduler:16.0-78            kolla_start           45 minutes ago     Up 45 minutes ago            cinder_scheduler
b995c7cc5972  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-cinder-api:16.0-76                  kolla_start           45 minutes ago     Up 45 minutes ago            cinder_api_cron
cab047e570c3  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-cinder-api:16.0-76                  kolla_start           45 minutes ago     Up 45 minutes ago            cinder_api
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller03.ctlplane 'sudo podman exec -it openstack-cinder-volume-podman-0 ceph -s ; sudo podman exec -it openstack-cinder-volume-podman-0 ceph osd tree ' 
  cluster:
    id:     b21ecd98-c27e-11ea-93f8-5254004d57e9
    health: HEALTH_WARN
            too many PGs per OSD (1024 > max 1000)
 
  services:
    mon: 3 daemons, quorum lab-controller01,lab-controller02,lab-controller03 (age 70m)
    mgr: lab-controller01(active, since 68m), standbys: lab-controller02, lab-controller03
    osd: 2 osds: 2 up (since 67m), 2 in (since 67m)
    rgw: 3 daemons active (lab-controller01.rgw0, lab-controller02.rgw0, lab-controller03.rgw0)
 
  task status:
 
  data:
    pools:   8 pools, 1024 pgs
    objects: 584 objects, 3.0 GiB
    usage:   8.0 GiB used, 110 GiB / 118 GiB avail
    pgs:     1024 active+clean
 
ID CLASS WEIGHT  TYPE NAME                       STATUS REWEIGHT PRI-AFF 
-1       0.11517 root default                                            
-5       0.05759     host overcloud-computehci-0                         
 0   hdd 0.05759         osd.0                       up  1.00000 1.00000 
-3       0.05759     host overcloud-computehci-1                         
 1   hdd 0.05759         osd.1                       up  1.00000 1.00000 

# Cinder should be configured with 3 backend storage pools, all of the type RBD
#   Volumes >4gb should Only be created in the cinder-large storage pool
#   Volumes <2gb should Only be created in the cinder-small storage pool
#   The third storage pool should be named cinder-med
#   Volumes >2gb & <4gb should be spread evenly across all 3 storage pools
 
# run on 3 controller and 2 compute
 
[heat-admin@lab-controller01 ~]$ sudo su -
[heat-admin@lab-controller01 ~]# 
cp /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf.sav
 
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf DEFAULT enabled_backends cinder-large,cinder-med,cinder-small
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf DEFAULT scheduler_default_filters AvailabilityZoneFilter,CapacityFilter
,CapabilitiesFilter,DriverFilter
 
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf DEFAULT  scheduler_default_weighers ChanceWeigher
 
# cinder-large
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large backend_host hostgroup
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large volume_backend_name cinder-large
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large volume_driver cinder.volume.drivers.rbd.RBDDriver
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large rbd_ceph_conf /etc/ceph/ceph.conf
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large rbd_user openstack
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large rbd_pool volumes
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large rbd_flatten_volume_from_snapshot False
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large rbd_secret_uuid b21ecd98-c27e-11ea-93f8-5254004d57e9
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large report_discard_supported True
 
# cinder-med
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med backend_host hostgroup
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med volume_backend_name cinder-med
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med volume_driver cinder.volume.drivers.rbd.RBDDriver
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med rbd_ceph_conf /etc/ceph/ceph.conf
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med rbd_user openstack
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med rbd_pool volumes
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med rbd_flatten_volume_from_snapshot False
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med rbd_secret_uuid b21ecd98-c27e-11ea-93f8-5254004d57e9
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med report_discard_supported True
 
# cinder-small
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small backend_host hostgroup
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small volume_backend_name cinder-small
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small volume_driver cinder.volume.drivers.rbd.RBDDriver
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small rbd_ceph_conf /etc/ceph/ceph.conf
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small rbd_user openstack
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small rbd_pool volumes
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small rbd_flatten_volume_from_snapshot False
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small rbd_secret_uuid b21ecd98-c27e-11ea-93f8-5254004d57e9
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small report_discard_supported True
 
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med goodness_function 50
sed -i 's/goodness_function = 50/goodness_function = "50"/g' /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf
 
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large goodness_function "(volume.size > 4) ? 100 : 50"
sed -i 's/(volume.size > 4) ? 100 : 50/"(volume.size > 4) ? 100 : 50"/g' /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf
 
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small goodness_function "(volume.size < 2) ? 100 : 50"
sed -i 's/(volume.size < 2) ? 100 : 50/"(volume.size < 2) ? 100 : 50"/g' /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf
 
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-large filter_function "volume.size >= 2"
sed -i 's/volume.size >= 2/"volume.size >= 2"/g' /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf
 
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-med filter_function "volume.size >= 2 and volume.size <= 4"
sed -i 's/volume.size >= 2 and volume.size <= 4/"volume.size >= 2 and volume.size <= 4"/g' /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf
 
crudini --set /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf cinder-small filter_function "volume.size <= 4"
sed -i 's/volume.size <= 4/"volume.size <= 4"/g' /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf
 
 
[root@lab-controller01 ~]# cat /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf | grep ^enabled
enabled_backends=cinder-large,cinder-med,cinder-small
 
[root@lab-controller01 ~]# cat /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf | grep ^scheduler_default_weighers
scheduler_default_weighers = ChanceWeigher
 
[root@lab-controller01 ~]# cat /var/lib/config-data/puppet-generated/cinder/etc/cinder/cinder.conf | grep "\[cinder-large\]" -A40
[cinder-large]
backend_host = hostgroup
volume_backend_name = cinder-large
volume_driver = cinder.volume.drivers.rbd.RBDDriver
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = openstack
rbd_pool = volumes
rbd_flatten_volume_from_snapshot = False
rbd_secret_uuid = b21ecd98-c27e-11ea-93f8-5254004d57e9
report_discard_supported = True
goodness_function = "(volume.size > 4) ? 100 : 50"
filter_function = "volume.size >= 2"
 
 
[cinder-med]
backend_host = hostgroup
volume_backend_name = cinder-med
volume_driver = cinder.volume.drivers.rbd.RBDDriver
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = openstack
rbd_pool = volumes
rbd_flatten_volume_from_snapshot = False
rbd_secret_uuid = b21ecd98-c27e-11ea-93f8-5254004d57e9
report_discard_supported = True
goodness_function = "50"
filter_function = "volume.size >= 2 and volume.size <= 4"
 
 
[cinder-small]
backend_host = hostgroup
volume_backend_name = cinder-small
volume_driver = cinder.volume.drivers.rbd.RBDDriver
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = openstack
rbd_pool = volumes
rbd_flatten_volume_from_snapshot = False
rbd_secret_uuid = b21ecd98-c27e-11ea-93f8-5254004d57e9
report_discard_supported = True
goodness_function = "(volume.size < 2) ? 100 : 50"
filter_function = "volume.size <= 4"
 
 
[root@lab-controller01 ~]# systemctl restart tripleo_cinder_scheduler.service tripleo_cinder_api_cron.service tripleo_cinder_api.service
 
# repeat above steps on lab-controller02 and lab-controller03
 
# restart pcs service openstack-cinder-backup and openstack-cinder-volume
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane "sudo pcs resource restart openstack-cinder-backup" 
openstack-cinder-backup successfully restarted
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane "sudo pcs resource restart openstack-cinder-volume" 
openstack-cinder-volume successfully restarted
 
# list volume
(overcloud) [stack@undercloud ~]$ openstack volume list
 
# create 1gb-vol, 1gb-vol on cinder-small
(overcloud) [stack@undercloud ~]$ openstack volume create --size 1 1gb-vol
(overcloud) [stack@undercloud ~]$ openstack volume show 1gb-vol | grep os-vol-host-attr
| os-vol-host-attr:host          | hostgroup@cinder-small#cinder-small  |
 
# create 5gb-vol, 5gb-vol on cinder-large
(overcloud) [stack@undercloud ~]$ openstack volume create --size 5 5gb-vol
(overcloud) [stack@undercloud ~]$ openstack volume show 5gb-vol | grep os-vol-host-attr
| os-vol-host-attr:host          | hostgroup@cinder-large#cinder-large  |
 
# create six 3gb-vol on cinder-med, cinder-small and cinder-large
(overcloud) [stack@undercloud ~]$ for i in `seq 1 6` ; do openstack volume create --size 3 3gb-vol-0$i ; done
(overcloud) [stack@undercloud ~]$ for i in `seq 1 6` ; do openstack volume show 3gb-vol-0$i | grep os-vol-host-attr ; done 
| os-vol-host-attr:host          | hostgroup@cinder-med#cinder-med      |
| os-vol-host-attr:host          | hostgroup@cinder-med#cinder-med      |
| os-vol-host-attr:host          | hostgroup@cinder-med#cinder-med      |
| os-vol-host-attr:host          | hostgroup@cinder-large#cinder-large  |
| os-vol-host-attr:host          | hostgroup@cinder-small#cinder-small  |
| os-vol-host-attr:host          | hostgroup@cinder-small#cinder-small  |

# Demonstrate Barbican as key manager for storing all keys.
(overcloud) [stack@undercloud ~]$ openstack secret store --name rootPassword --payload 'r3dh4t1!'
+---------------+-------------------------------------------------------------------------------------+
| Field         | Value                                                                               |
+---------------+-------------------------------------------------------------------------------------+
| Secret href   | https://overcloud.example.com:13311/v1/secrets/33d39e35-9e20-4b95-ac66-e6942de0ce24 |
| Name          | rootPassword                                                                        |
| Created       | None                                                                                |
| Status        | None                                                                                |
| Content types | None                                                                                |
| Algorithm     | aes                                                                                 |
| Bit length    | 256                                                                                 |
| Secret type   | opaque                                                                              |
| Mode          | cbc                                                                                 |
| Expiration    | None                                                                                |
+---------------+-------------------------------------------------------------------------------------+
 
(overcloud) [stack@undercloud ~]$ openstack secret get  $(openstack secret list -f value -c "Secret href" --name rootPassword) --payload
+---------+----------+
| Field   | Value    |
+---------+----------+
| Payload | r3dh4t1! |
+---------+----------+
 

# Demonstrate cinder volume encryption
(overcloud) [stack@undercloud ~]$ openstack volume type create --encryption-provider nova.volume.encryptors.luks.LuksEncryptor --encryption-cipher aes-xts-plain64 --encryption-key-size 256 --encryption-control-location front-end encryptedvolume
+-------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Field       | Value                                                                                                                                                                              |
+-------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| description | None                                                                                                                                                                               |
| encryption  | cipher='aes-xts-plain64', control_location='front-end', encryption_id='90952a91-6ca4-438d-b706-752607f38fd2', key_size='256', provider='nova.volume.encryptors.luks.LuksEncryptor' |
| id          | f59dfad1-f00a-4c80-8e5f-4a6042617df3                                                                                                                                               |
| is_public   | True                                                                                                                                                                               |
| name        | encryptedvolume                                                                                                                                                                    |
+-------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
 
(overcloud) [stack@undercloud ~]$ openstack volume create --size 1 --type encryptedvolume volume_encrypted_example
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| attachments         | []                                   |
| availability_zone   | nova                                 |
| bootable            | false                                |
| consistencygroup_id | None                                 |
| created_at          | 2020-07-10T14:35:24.000000           |
| description         | None                                 |
| encrypted           | True                                 |
| id                  | 2c2d7cc6-8eae-4cf5-af4e-0e3a07bb38eb |
| migration_status    | None                                 |
| multiattach         | False                                |
| name                | volume_encrypted_example             |
| properties          |                                      |
| replication_status  | None                                 |
| size                | 1                                    |
| snapshot_id         | None                                 |
| source_volid        | None                                 |
| status              | creating                             |
| type                | encryptedvolume                      |
| updated_at          | None                                 |
| user_id             | 515c1a37073442d190089160fc8d0f1d     |
+---------------------+--------------------------------------+
 
(overcloud) [stack@undercloud ~]$ openstack secret list
+-------------------------------------------------------------------------------------+--------------+---------------------------+--------+-----------------------------------------+-----------+------------+-------------+------+------------+
| Secret href                                                                         | Name         | Created                   | Status | Content types                           | Algorithm | Bit length | Secret type | Mode | Expiration |
+-------------------------------------------------------------------------------------+--------------+---------------------------+--------+-----------------------------------------+-----------+------------+-------------+------+------------+
| https://overcloud.example.com:13311/v1/secrets/6530f9b5-4fc8-4184-9a9d-17b3679fc723 | None         | 2020-07-10T14:35:23+00:00 | ACTIVE | {'default': 'application/octet-stream'} | aes       |        256 | symmetric   | None | None       |
| https://overcloud.example.com:13311/v1/secrets/33d39e35-9e20-4b95-ac66-e6942de0ce24 | rootPassword | 2020-07-10T14:31:45+00:00 | ACTIVE | {'default': 'text/plain'}               | aes       |        256 | opaque      | cbc  | None       |
| https://overcloud.example.com:13311/v1/secrets/e69ba25b-30e7-484b-8c0a-4f3b2a4c3a78 | signing-cert | 2020-07-10T09:51:51+00:00 | ACTIVE | {'default': 'application/octet-stream'} | RSA       |        256 | certificate | cbc  | None       |
+-------------------------------------------------------------------------------------+--------------+---------------------------+--------+-----------------------------------------+-----------+------------+-------------+------+------------+
(overcloud) [stack@undercloud ~]$  openstack volume list
+--------------------------------------+--------------------------+-----------+------+-------------+
| ID                                   | Name                     | Status    | Size | Attached to |
+--------------------------------------+--------------------------+-----------+------+-------------+
| 2c2d7cc6-8eae-4cf5-af4e-0e3a07bb38eb | volume_encrypted_example | available |    1 |             |
| 9d6fe939-d919-476c-ad1c-25a72c71e87f | 1gb-vol                  | available |    1 |             |
| 9d7042cb-18be-42d9-988a-11e39e90a516 | 5gb-vol                  | available |    5 |             |
| f4dfa8ad-64a0-4768-acb0-b432b3105ef1 | 3gb-vol-06               | available |    3 |             |
| b3bb3a6c-dbcc-4bc0-80d1-1de378b4b279 | 3gb-vol-05               | available |    3 |             |
| 1f84a23f-72b7-41e6-9cb4-c0f3b1c2e4fe | 3gb-vol-04               | available |    3 |             |
| cf93f8a2-63e1-470f-a5ca-c0439137e1a0 | 3gb-vol-03               | available |    3 |             |
| eb9d08bd-1db0-43f7-a207-0257fe083ae2 | 3gb-vol-02               | available |    3 |             |
| 9febf52a-c716-47fe-bf57-b97f33c592fe | 3gb-vol-01               | available |    3 |             |
+--------------------------------------+--------------------------+-----------+------+-------------+
(overcloud) [stack@undercloud ~]$ openstack volume show volume_encrypted_example
+--------------------------------+--------------------------------------+
| Field                          | Value                                |
+--------------------------------+--------------------------------------+
| attachments                    | []                                   |
| availability_zone              | nova                                 |
| bootable                       | false                                |
| consistencygroup_id            | None                                 |
| created_at                     | 2020-07-10T14:35:24.000000           |
| description                    | None                                 |
| encrypted                      | True                                 |
| id                             | 2c2d7cc6-8eae-4cf5-af4e-0e3a07bb38eb |
| migration_status               | None                                 |
| multiattach                    | False                                |
| name                           | volume_encrypted_example             |
| os-vol-host-attr:host          | hostgroup@cinder-small#cinder-small  |
| os-vol-mig-status-attr:migstat | None                                 |
| os-vol-mig-status-attr:name_id | None                                 |
| os-vol-tenant-attr:tenant_id   | a386e6a574fb40f5b05aaeffade27271     |
| properties                     |                                      |
| replication_status             | None                                 |
| size                           | 1                                    |
| snapshot_id                    | None                                 |
| source_volid                   | None                                 |
| status                         | available                            |
| type                           | encryptedvolume                      |
| updated_at                     | 2020-07-10T14:35:34.000000           |
| user_id                        | 515c1a37073442d190089160fc8d0f1d     |
+--------------------------------+--------------------------------------+
 
# Make a backup of one cinder volume - find where is stored. (openstack volume backup create)
(overcloud) [stack@undercloud ~]$ openstack volume backup create 1gb-vol --force --name 1gb-vol-backup
+-------+--------------------------------------+
| Field | Value                                |
+-------+--------------------------------------+
| id    | f8e3a0ab-27ef-4424-bd7d-1b74041e2d4d |
| name  | 1gb-vol-backup                       |
+-------+--------------------------------------+
(overcloud) [stack@undercloud ~]$ openstack volume backup show 1gb-vol-backup
+-----------------------+--------------------------------------+
| Field                 | Value                                |
+-----------------------+--------------------------------------+
| availability_zone     | nova                                 |
| container             | backups                              |
| created_at            | 2020-07-10T14:42:12.000000           |
| data_timestamp        | 2020-07-10T14:42:12.000000           |
| description           | None                                 |
| fail_reason           | None                                 |
| has_dependent_backups | False                                |
| id                    | f8e3a0ab-27ef-4424-bd7d-1b74041e2d4d |
| is_incremental        | False                                |
| name                  | 1gb-vol-backup                       |
| object_count          | 0                                    |
| size                  | 1                                    |
| snapshot_id           | None                                 |
| status                | available                            |
| updated_at            | 2020-07-10T14:42:19.000000           |
| volume_id             | 9d6fe939-d919-476c-ad1c-25a72c71e87f |
+-----------------------+--------------------------------------+
 
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller03.ctlplane 'sudo podman exec -it openstack-cinder-volume-podman-0 rbd --id openstack -p backups ls' 
volume-9d6fe939-d919-476c-ad1c-25a72c71e87f.backup.f8e3a0ab-27ef-4424-bd7d-1b74041e2d4d
 
 

# Additional optional requirements
#   Keystone integration with Red Hat Identity Manager (IdM)
N/A

# Additional optional requirements
#   TLS everywhere (TLS on public and internal overcloud endpoints)
(overcloud) [stack@undercloud ~]$ openstack catalog list
+-----------+----------------+-------------------------------------------------------------------------------------------------------+
| Name      | Type           | Endpoints                                                                                             |
+-----------+----------------+-------------------------------------------------------------------------------------------------------+
| heat      | orchestration  | regionOne                                                                                             |
|           |                |   admin: https://overcloud.internalapi.example.com:8004/v1/a386e6a574fb40f5b05aaeffade27271           |
|           |                | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:8004/v1/a386e6a574fb40f5b05aaeffade27271        |
|           |                | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13004/v1/a386e6a574fb40f5b05aaeffade27271                     |
|           |                |                                                                                                       |
| keystone  | identity       | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:5000                                            |
|           |                | regionOne                                                                                             |
|           |                |   admin: https://overcloud.ctlplane.example.com:35357                                                 |
|           |                | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13000                                                         |
|           |                |                                                                                                       |
| placement | placement      | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13778/placement                                               |
|           |                | regionOne                                                                                             |
|           |                |   admin: https://overcloud.internalapi.example.com:8778/placement                                     |
|           |                | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:8778/placement                                  |
|           |                |                                                                                                       |
| glance    | image          | regionOne                                                                                             |
|           |                |   admin: https://overcloud.internalapi.example.com:9292                                               |
|           |                | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13292                                                         |
|           |                | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:9292                                            |
|           |                |                                                                                                       |
| neutron   | network        | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13696                                                         |
|           |                | regionOne                                                                                             |
|           |                |   admin: https://overcloud.internalapi.example.com:9696                                               |
|           |                | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:9696                                            |
|           |                |                                                                                                       |
| octavia   | load-balancer  | regionOne                                                                                             |
|           |                |   admin: https://overcloud.internalapi.example.com:9876                                               |
|           |                | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13876                                                         |
|           |                | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:9876                                            |
|           |                |                                                                                                       |
| cinderv2  | volumev2       | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13776/v2/a386e6a574fb40f5b05aaeffade27271                     |
|           |                | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:8776/v2/a386e6a574fb40f5b05aaeffade27271        |
|           |                | regionOne                                                                                             |
|           |                |   admin: https://overcloud.internalapi.example.com:8776/v2/a386e6a574fb40f5b05aaeffade27271           |
|           |                |                                                                                                       |
| heat-cfn  | cloudformation | regionOne                                                                                             |
|           |                |   admin: https://overcloud.internalapi.example.com:8000/v1                                            |
|           |                | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13005/v1                                                      |
|           |                | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:8000/v1                                         |
|           |                |                                                                                                       |
| cinderv3  | volumev3       | regionOne                                                                                             |
|           |                |   admin: https://overcloud.internalapi.example.com:8776/v3/a386e6a574fb40f5b05aaeffade27271           |
|           |                | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13776/v3/a386e6a574fb40f5b05aaeffade27271                     |
|           |                | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:8776/v3/a386e6a574fb40f5b05aaeffade27271        |
|           |                |                                                                                                       |
| swift     | object-store   | regionOne                                                                                             |
|           |                |   internal: https://overcloud.storage.example.com:8080/swift/v1/AUTH_a386e6a574fb40f5b05aaeffade27271 |
|           |                | regionOne                                                                                             |
|           |                |   admin: https://overcloud.storage.example.com:8080/swift/v1/AUTH_a386e6a574fb40f5b05aaeffade27271    |
|           |                | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13808/swift/v1/AUTH_a386e6a574fb40f5b05aaeffade27271          |
|           |                |                                                                                                       |
| barbican  | key-manager    | regionOne                                                                                             |
|           |                |   admin: https://overcloud.internalapi.example.com:9311                                               |
|           |                | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:9311                                            |
|           |                | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13311                                                         |
|           |                |                                                                                                       |
| nova      | compute        | regionOne                                                                                             |
|           |                |   admin: https://overcloud.internalapi.example.com:8774/v2.1                                          |
|           |                | regionOne                                                                                             |
|           |                |   internal: https://overcloud.internalapi.example.com:8774/v2.1                                       |
|           |                | regionOne                                                                                             |
|           |                |   public: https://overcloud.example.com:13774/v2.1                                                    |
|           |                |                                                                                                       |
+-----------+----------------+-------------------------------------------------------------------------------------------------------+
 
 

# Test the RadosGW (Object Storage Ceph): creating a container and uploading a file.
 
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane "sudo netstat -tulpn | grep radosgw"
tcp        0      0 172.18.0.201:8080       0.0.0.0:*               LISTEN      54386/radosgw    
 
# on lab-controller01
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane "sudo podman ps | grep haproxy" 
08fdfaa89d81  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-haproxy:16.0-85                     /bin/bash /usr/lo...  2 days ago  Up 2 days ago         haproxy-bundle-podman-0
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane "sudo podman exec -it haproxy-bundle-podman-0 cat /etc/haproxy/haproxy.cfg | grep ceph_rgw -A12" 
listen ceph_rgw
  bind 10.0.0.150:13808 transparent ssl crt /etc/pki/tls/private/overcloud_endpoint.pem
  bind 172.18.0.150:8080 transparent ssl crt /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem
  mode http
  http-request set-header X-Forwarded-Proto https if { ssl_fc }
  http-request set-header X-Forwarded-Proto http if !{ ssl_fc }
  http-request set-header X-Forwarded-Port %[dst_port]
  option httpchk HEAD /
  redirect scheme https code 301 if { hdr(host) -i 10.0.0.150 } !{ ssl_fc }
  rsprep ^Location:\ http://(.*) Location:\ https://\1
  server lab-controller01.storage.example.com 172.18.0.201:8080 check fall 5 inter 2000 rise 2 verifyhost lab-controller01.storage.example.com
  server lab-controller02.storage.example.com 172.18.0.202:8080 check fall 5 inter 2000 rise 2 verifyhost lab-controller02.storage.example.com
  server lab-controller03.storage.example.com 172.18.0.203:8080 check fall 5 inter 2000 rise 2 verifyhost lab-controller03.storage.example.com
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane "sudo cp /etc/pki/tls/certs/haproxy/overcloud-haproxy-storage.pem /tmp" 
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane "sudo chmod a+r /tmp/overcloud-haproxy-storage.pem" 
(overcloud) [stack@undercloud ~]$ scp heat-admin@lab-controller01.ctlplane:/tmp/overcloud-haproxy-storage.pem overcloud-lab-controller01.storage.example.com.pem 
overcloud-haproxy-storage.pem 
(overcloud) [stack@undercloud ~]$ scp overcloud-lab-controller01.storage.example.com.pem root@192.0.2.249:/etc/pki/ca-trust/source/anchors
overcloud-lab-controller01.storage.example.com.pem                                                                     100% 5339     3.4MB/s   00:00 
(overcloud) [stack@undercloud ~]$ ssh root@192.0.2.249 "update-ca-trust extract"
(overcloud) [stack@undercloud ~]$ ssh root@192.0.2.249 "update-ca-trust update"
 
# on workstation
(overcloud) [stack@undercloud ~]$ ssh root@192.0.2.249
[root@workstation ~]# echo "address=/.lab-controller01.storage.example.com/172.18.0.201" > /etc/dnsmasq.d/rgw.conf
[root@workstation ~]# systemctl restart dnsmasq
[root@workstation ~]# dig +short @localhost onefile.lab-controller01.storage.example.com
172.18.0.201
[root@workstation ~]# sed -i '2 s/^/nameserver 127.0.0.1\n/' /etc/resolv.conf
 
# on lab-controller01
(overcloud) [stack@undercloud ~]$ ssh heat-admin@lab-controller01.ctlplane "sudo podman ps | grep haproxy" 
08fdfaa89d81  undercloud.ctlplane.example.com:8787/rhosp-rhel8/openstack-haproxy:16.0-85                     /bin/bash /usr/lo...  2 days ago  Up 2 days ago         haproxy-bundle-podman-0
 
[root@lab-controller01 ~]# podman ps | grep rgw
a10418a73290  undercloud.ctlplane.example.com:8787/rhceph/rhceph-4-rhel8:4-14                                                      6 hours ago        Up 6 hours ago               ceph-rgw-lab-controller01-rgw0
 
[root@lab-controller01 ~]# podman exec -it ceph-rgw-lab-controller01-rgw0 bash
[root@lab-controller01 /]# radosgw-admin user create --uid="operator" --display-name="S3 Operator" --email="operator@example.com" --access_key="12345" --secret="67890"
{
    "user_id": "operator",
    "display_name": "S3 Operator",
    "email": "operator@example.com",
    "suspended": 0,
    "max_buckets": 1000,
    "subusers": [],
    "keys": [
        {
            "user": "operator",
            "access_key": "12345",
            "secret_key": "67890"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
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
 
# on workstation
[root@workstation ~]# 
[root@workstation ~]# s3cmd --configure
 
Enter new values or accept defaults in brackets with Enter.
Refer to user manual for detailed description of all options.
 
Access key and Secret key are your identifiers for Amazon S3. Leave them empty for using the env variables.
Access Key [12345]: 
Secret Key [67890]: 
Default Region [US]: 
 
Use "s3.amazonaws.com" for S3 Endpoint and not modify it to the target Amazon S3.
S3 Endpoint [lab-controller01.storage.example.com:8080]: 
 
Use "%(bucket)s.s3.amazonaws.com" to the target Amazon S3. "%(bucket)s" and "%(location)s" vars can be used
if the target S3 system supports dns based buckets.
DNS-style bucket+hostname:port template for accessing a bucket [%(bucket)s.lab-controller01.storage.example.com:8080]: 
 
Encryption password is used to protect your files from reading
by unauthorized persons while in transfer to S3
Encryption password: 
Path to GPG program [/usr/bin/gpg]: 
 
When using secure HTTPS protocol all communication with Amazon S3
servers is protected from 3rd party eavesdropping. This method is
slower than plain HTTP, and can only be proxied with Python 2.7 or newer
Use HTTPS protocol [Yes]: 
 
On some networks all internet access must go through a HTTP proxy.
Try setting it here if you can't connect to S3 directly
HTTP Proxy server name: 
 
New settings:
  Access Key: 12345
  Secret Key: 67890
  Default Region: US
  S3 Endpoint: lab-controller01.storage.example.com:8080
  DNS-style bucket+hostname:port template for accessing a bucket: %(bucket)s.lab-controller01.storage.example.com:8080
  Encryption password: 
  Path to GPG program: /usr/bin/gpg
  Use HTTPS protocol: True
  HTTP Proxy server name: 
  HTTP Proxy server port: 0
 
Test access with supplied credentials? [Y/n] Y
Please wait, attempting to list all buckets...
Success. Your access key and secret key worked fine :-)
 
Now verifying that encryption works...
Not configured. Never mind.
 
Save settings? [y/N] y
Configuration saved to '/root/.s3cfg'
[root@workstation ~]# 
[root@workstation ~]# s3cmd mb s3://WEB-BUCKET
Bucket 's3://WEB-BUCKET/' created
[root@workstation ~]# echo "Hello from Ceph" > index.html
[root@workstation ~]# s3cmd put --acl-public index.html s3://WEB-BUCKET/index.html
upload: 'index.html' -> 's3://WEB-BUCKET/index.html'  [1 of 1]
 16 of 16   100% in    1s     8.32 B/s  done
Public URL of the object is: http://lab-controller01.storage.example.com:8080/WEB-BUCKET/index.html
[root@workstation ~]# curl https://lab-controller01.storage.example.com:8080/WEB-BUCKET/index.html
Hello from Ceph
[root@workstation ~]# s3cmd get s3://WEB-BUCKET/index.html downloaded.html
download: 's3://WEB-BUCKET/index.html' -> 'downloaded.html'  [1 of 1]
 16 of 16   100% in    0s    37.93 B/s  done
[root@workstation ~]# cat downloaded.html
Hello from Ceph
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


