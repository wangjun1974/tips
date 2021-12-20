### 服务器IP地址
|Hostname|IP Address|Gateway|NetMask|DNS|
|---|---|---|---|---|
|support|192.168.122.12|192.168.122.1|255.255.255.0|192.168.122.12|
|bootstrap|192.168.122.200|192.168.122.1|255.255.255.0|192.168.122.12|
|master-0|192.168.122.201|192.168.122.1|255.255.255.0|192.168.122.12|
|master-1|192.168.122.202|192.168.122.1|255.255.255.0|192.168.122.12|
|master-3|192.168.122.203|192.168.122.1|255.255.255.0|192.168.122.12|
|worker-0|192.168.122.210|192.168.122.1|255.255.255.0|192.168.122.12|
|worker-1|192.168.122.211|192.168.122.1|255.255.255.0|192.168.122.12|

### 1.7	DNS域名解析规划
|DNS Part|Value|
|---|---|
|Domain|example.com|
|OCP_CLUSTER_ID|ocp4-1|

### 安装 support 机器
```

cat > support-ks.cfg <<'EOF'
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
network --device=ens3 --hostname=support.example.com --bootproto=static --ip=192.168.122.12 --netmask=255.255.255.0 --gateway=10.66.208.254 --nameserver=10.64.63.6
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
```