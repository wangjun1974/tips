### 预安装节点的部署方式
```
# 参考模版
https://gitlab.cee.redhat.com/sputhenp/lab/-/blob/master/templates/osp-16-1/pre-provisioned/overcloud-deploy-tls-everywhere.sh

# 安装 overcloud-controller-0
virsh attach-disk jwang-overcloud-ceph01 /root/jwang/isos/rhel-8.2-x86_64-dvd.iso hda --type cdrom --mode readonly --config
# 重启 
# ks=http://10.66.208.115/overcloud-controller-0-ks.cfg nameserver=192.168.122.3 ip=192.0.2.51::192.0.2.1:255.255.255.0:overcloud-controller-0.example.com:ens3:none

# 生成 ks.cfg - overcloud-controller-0
cat > overcloud-controller-0-ks.cfg <<'EOF'
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
network --device=ens3 --hostname=overcloud-controller-0.example.com --bootproto=static --ip=192.0.2.51 --netmask=255.255.255.0 --gateway=192.0.2.1 --nameserver=192.168.122.3
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

# 安装 overcloud-controller-1

# 安装 overcloud-controller-2

# 安装 overcloud-computehci-0

# 安装 overcloud-computehci-1

# 安装 overcloud-computehci-2



```