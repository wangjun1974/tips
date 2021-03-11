
相关步骤参考谭春阳所写的《在BCLinux8.1上安装配置OFED+OVS-kernel硬件offload》
参考：OVS Offload Using ASAP2 Direct<br>
https://docs.mellanox.com/display/MLNXOFEDv471001/OVS+Offload+Using+ASAP2+Direct


```
### 配置 iommu 和 HugePage
## 在 GRUB_CMDLINE_LINUX 结尾处添加 intel_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=8
# cat /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto resume=/dev/mapper/rhel00-swap rd.lvm.lv=rhel00/root rd.lvm.lv=rhel00/swap intel_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=8"
GRUB_DISABLE_RECOVERY="true"
GRUB_ENABLE_BLSCFG=true

## 确定主机启动方式
# ls /sys/firmware/
acpi  dmi  efi  memmap  qemu_fw_cfg

## 如果存在 efi 目录说明，使用的是 UEFI，启动配置文件为
# find /boot/efi/EFI -name "grub.cfg"
/boot/efi/EFI/redhat/grub.cfg

## 如果不存在 /sys/firmware/efi 目录，那么物理主机使用的是 BIOS 启动方式，对应的启动配置文件为 /boot/grub2/grub.cfg

## 生成启动配置文件 - UEFI
# grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg

## 生成启动配置文件 - BIOS
# grub2-mkconfig -o /boot/grub2/grub.cfg

## 重启系统
# reboot

### 确认iommu和HugePage设置生效
## 输出里应包含 intel_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=8
# cat /proc/cmdline

### 下载驱动和dpdk+openvswitch介质
## 链接: https://pan.baidu.com/s/1B4bRcnpyAv8L-GzPB32Orw 密码: r9ck
## 这个目录包含软件仓库
## rhel-8-for-x86_64-baseos-rpms
## rhel-8-for-x86_64-baseos-source-rpms
## rhel-8-for-x86_64-appstream-rpms
## rhel-8-for-x86_64-supplementary-rpms
## codeready-builder-for-rhel-8-x86_64-rpms
## 下载后的文件为 rhel8.dnf.tgz.aa - rhel8.dnf.tgz.ae
## 链接: https://pan.baidu.com/s/1A9ADVV_XymTatrL20A-SrQ 提取码: qis9
## 这个目录包含软件仓库
## fast-datapath-for-rhel-8-x86_64-rpms
## openstack-16.1-for-rhel-8-x86_64-rpms 
## 需要安装的软件包括 dpdk 和 openvswitch

# mkdir -p /data
# cat rhel8.dnf.tgz.a* > rhel8.dnf.tgz
# tar zxf rhel8.dnf.tgz -C /data

# cat << EOF > /etc/yum.repos.d/remote.repo
[appstream]
name=appstream
baseurl=file:///data/dnf/rhel-8-for-x86_64-appstream-rpms
enabled=1
gpgcheck=0

[baseos]
name=baseos
baseurl=file:///data/dnf/rhel-8-for-x86_64-baseos-rpms
enabled=1
gpgcheck=0

[remote-baseos-source]
name=baseos-source
baseurl=file:///data/dnf/rhel-8-for-x86_64-baseos-source-rpms
enabled=1
gpgcheck=0

[fast-datapath]
name=fast-datapath
baseurl=file:///data/dnf/fast-datapath-for-rhel-8-x86_64-rpms
enabled=1
gpgcheck=0

[openstack-16.1]
name=openstack-16.1
baseurl=file:///data/dnf/openstack-16.1-for-rhel-8-x86_64-rpms
enabled=1
gpgcheck=0

[remote-codeready-builder]
name=supplementary
baseurl=file:///data/dnf/codeready-builder-for-rhel-8-x86_64-rpms
enabled=1
gpgcheck=0
EOF

## 更新系统并重启
# yum update -y
# reboot 

### 安装依赖包
## 注意：以下步骤可以不用在 rhel 8.3 上执行
## 安装依赖包时没有安装 epel-release
# yum groupinstall -y 'Development Tools' 'System Tools'
# yum install -y policycoreutils-python-utils
# yum install -y createrepo yum-utils rpm-build audit-libs-devel binutils-devel elfutils-devel java-devel libcap-devel ncurses-devel newt-devel numactl-devel openssl-devel pciutils-devel python3-devel perl-devel xmlto xz-devel zlib-devel perl-ExtUtils-Embed.noarch python3-docutils libpfm-devel.x86_64 bcc-tools.x86_64 llvm bc net-tools rsync
# yum install -y cmake elfutils-devel zlib-devel
# yum install -y perl pciutils gcc-gfortran tcsh expat glib2 tcl libstdc++ bc tk gtk2 atk cairo numactl pkgconfig ethtool lsof python36 gcc-gfortran tcsh pciutils tk tcl unbound

## 在 rhel 8.3 上执行
# yum update -y
# reboot 

## 安装编译环境
# yum groupinstall -y 'Development Tools'
# yum install python36 tcl tk tcsh gcc-gfortran lsof pciutils

### 安装 OFED 驱动
## 挂载 MLNX_OFED_LINUX-5.2-2.2.0.0 介质
# mkdir /mnt/ofed
# mount -o loop /path_to/MLNX_OFED_LINUX-5.2-2.2.0.0-rhel8.3-x86_64 /mnt/ofed

## 执行安装命令
# cd /mnt/ofed
# ./mlnxofedinstall --force

## 安装完成后的配置
# chkconfig --add mst
# chkconfig --add openibd

## 重启系统
# reboot

## 确认驱动生效
# modinfo mlx5_core
# ibdev2netdev -v

## 安装 openvswitch 
## 安装的软件来自 MLNX_OFED_LINUX-5.2-2.2.0.0 介质
# yum install -y RPMS/mlnx-dpdk-20.11.0-1.52220.x86_64.rpm RPMS/mlnx-dpdk-devel-20.11.0-1.52220.x86_64.rpm RPMS/

### 配置SR-IOV
## 参考文档: https://docs.mellanox.com/pages/viewpage.action?pageId=39285091
## 本文以物理网口enp216s0f0为例
## 在固件层面打开SR-IOV选项
# ethtool -i enp216s0f0
driver: mlx5_core
version: 5.2-2.0.7
firmware-version: 16.29.1030 (MT_0000000080)
expansion-rom-version: 
bus-info: 0000:d8:00.0              <== PCI id
supports-statistics: yes
supports-test: yes
supports-eeprom-access: no
supports-register-dump: no
supports-priv-flags: yes

## 根据上述命令得到 PCI id，然后执行：
# mlxconfig -y -d 0000:d8:00.0 set SRIOV_EN=1 UCTX_EN=1 NUM_OF_VFS=8
## 备注：NUM_OF_VFS 最大值 127

## 重启系统
# reboot

## 从系统层面生成 SR-IOV VF 设备
# echo 4 > /sys/class/net/enp216s0f0/device/sriov_numvfs
# ip -d link show
...
2: enp216s0f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether b8:59:9f:ce:2c:ea brd ff:ff:ff:ff:ff:ff promiscuity 0 addrgenmode none numtxqueues 1016 numrxqueues 126 gso_max_size 65536 gso_max_segs 65535 portname p0 
    vf 0 MAC 00:00:00:00:00:00, spoof checking off, link-state auto, trust off, query_rss off
    vf 1 MAC 00:00:00:00:00:00, spoof checking off, link-state auto, trust off, query_rss off
    vf 2 MAC 00:00:00:00:00:00, spoof checking off, link-state auto, trust off, query_rss off
    vf 3 MAC 00:00:00:00:00:00, spoof checking off, link-state auto, trust off, query_rss off
3: enp216s0f1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether b8:59:9f:ce:2c:eb brd ff:ff:ff:ff:ff:ff promiscuity 0 addrgenmode none numtxqueues 1016 numrxqueues 126 gso_max_size 65536 gso_max_segs 65535 portname p1 
...

## 给 representor 设备配置MAC地址
# for id in {0..3};do \
    od -An -N6 -tx1 /dev/urandom | sed -e 's/^  *//' -e 's/  */:/g'; \
done
0e:4e:1c:6c:cc:ab
e0:18:f7:1b:8f:d9
00:48:9d:d1:c9:00
60:03:82:7e:1a:d1

# ip link set enp216s0f0 vf 0 mac 0e:4e:1c:6c:cc:ab
# ip link set enp216s0f0 vf 1 mac e0:18:f7:1b:8f:d9
# ip link set enp216s0f0 vf 2 mac 00:48:9d:d1:c9:00
# ip link set enp216s0f0 vf 3 mac 60:03:82:7e:1a:d1

# ip -d link show enp216s0f0
2: enp216s0f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether b8:59:9f:ce:2c:ea brd ff:ff:ff:ff:ff:ff promiscuity 0 addrgenmode none numtxqueues 1016 numrxqueues 126 gso_max_size 65536 gso_max_segs 65535 portname p0 
    vf 0 MAC 0e:4e:1c:6c:cc:ab, spoof checking off, link-state auto, trust off, query_rss off
    vf 1 MAC e0:18:f7:1b:8f:d9, spoof checking off, link-state auto, trust off, query_rss off
    vf 2 MAC 00:48:9d:d1:c9:00, spoof checking off, link-state auto, trust off, query_rss off
    vf 3 MAC 60:03:82:7e:1a:d1, spoof checking off, link-state auto, trust off, query_rss off

### 配置 switchdev
## 解绑所有 VF
# readlink /sys/class/net/enp216s0f0/device/virtfn* | cut -d '/' -f 2
0000:d8:00.2
0000:d8:00.3
0000:d8:00.4
0000:d8:00.5

# echo 0000:d8:00.2 > /sys/bus/pci/drivers/mlx5_core/unbind
# echo 0000:d8:00.3 > /sys/bus/pci/drivers/mlx5_core/unbind
# echo 0000:d8:00.4 > /sys/bus/pci/drivers/mlx5_core/unbind
# echo 0000:d8:00.5 > /sys/bus/pci/drivers/mlx5_core/unbind

## 设置 PF 设备工作模式为 switchdev
# devlink dev eswitch set pci/0000:d8:00.0 mode switchdev

## 如果遇到失败的错误提示，那么可以先停止所有 VF 设备再尝试
# echo 0 > /sys/class/net/enp216s0f0/device/sriov_numvfs
# ip -d link show enp216s0f0
2: enp216s0f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether b8:59:9f:ce:2c:ea brd ff:ff:ff:ff:ff:ff promiscuity 0 addrgenmode none numtxqueues 1016 numrxqueues 126 gso_max_size 65536 gso_max_segs 65535 portname p0 switchid ea2cce00039f59b8

## 退回普通工作模式的命令是:
# devlink dev eswitch set pci/0000:d8:00.0 mode legacy

## 重新绑定 VF
# echo 0000:d8:00.2 > /sys/bus/pci/drivers/mlx5_core/bind
# echo 0000:d8:00.3 > /sys/bus/pci/drivers/mlx5_core/bind
# echo 0000:d8:00.4 > /sys/bus/pci/drivers/mlx5_core/bind
# echo 0000:d8:00.5 > /sys/bus/pci/drivers/mlx5_core/bind

### 配置Open vSwitch
## 启动 ovs 服务
# systemctl start openvswitch

## 添加 ovs bridge 'ovs-sriov'
# ovs-vsctl add-br ovs-sriov

## 启用硬件 offload
# ovs-vsctl set Open_vSwitch . other_config:hw-offload=true

## 重启 ovs 服务
# systemctl restart openvswitch

## 查看 ovs-vsctl list open 配置信息
# ovs-vsctl list open
...
other_config        : {hw-offload="true"}
...

## 添加 representor 设备到桥
# ovs-vsctl add-port ovs-sriov enp216s0f0
# ovs-vsctl add-port ovs-sriov enp216s0f0_0
# ovs-vsctl add-port ovs-sriov enp216s0f0_1
# ovs-vsctl add-port ovs-sriov enp216s0f0_2
# ovs-vsctl add-port ovs-sriov enp216s0f0_3
# ovs-vsctl show
c71ab696-566b-4e3a-bc73-5e2ffc7a8cf8
    Bridge ovs-sriov
        Port enp216s0f0_2
            Interface enp216s0f0_2
        Port enp216s0f0
            Interface enp216s0f0
        Port enp216s0f0_1
            Interface enp216s0f0_1
        Port enp216s0f0_3
            Interface enp216s0f0_3
        Port enp216s0f0_0
            Interface enp216s0f0_0
        Port ovs-sriov
            Interface ovs-sriov
                type: internal
    ovs_version: "2.14.1"

## 启动SR-IOV VF 和 representor 设备
# for id in {0..3};do \
    ip link set enp216s0f0v$id up; \
    ip link set enp216s0f0_$id up; \
done

### 测试和验证硬件 offload 生效
## 搭建同样配置的另一台测试机
## 这台机器作为 iperf3 的客户端。
## 安装 iperf3
## 在两台机器上都执行
# yum install -y iperf3

## 给 SR-IOV VF 设备配置 IP 地址
## 注意：必须在 SR-IOV VF 设备，而不是 representor 设备上配置IP地址才能使硬件 offload 生效。
## 分别在两台机器上配置 IP 地址，选择第一个 VF 口
## 客户端：
# ip addr add dev enp3s0f0v0 192.168.5.21/24
## 服务器端
# ip addr add dev enp216s0f0v0 192.168.5.22/24
## 启动 iperf3 服务器端
# iperf3 -s -i 1
## 使用 iperf3 客户端打流
# iperf3 -c 192.168.5.22 -i 1 -t 1800

## 从 iperf3 服务器端查看流状态
# ovs-appctl dpctl/dump-flows -m | egrep offload
ufid:9b0596d9-d3c6-4c88-aadb-087a81690c22, skb_priority(0/0),skb_mark(0/0),ct_state(0/0),ct_zone(0/0),ct_mark(0/0),ct_label(0/0),recirc_id(0),dp_hash(0/0),in_port(enp216s0f0),packet_type(ns=0/0,id=0/0),eth(src=4a:9a:3a:69:36:5c,dst=0e:4e:1c:6c:cc:ab),eth_type(0x0800),ipv4(src=0.0.0.0/0.0.0.0,dst=0.0.0.0/0.0.0.0,proto=0/0,tos=0/0,ttl=0/0,frag=no), packets:54114480, bytes:81929308428, used:0.520s, offloaded:yes, dp:tc, actions:enp216s0f0_0

# ovs-appctl dpctl/dump-flows type=offloaded
recirc_id(0),in_port(6),eth(src=4a:9a:3a:69:36:5c,dst=0e:4e:1c:6c:cc:ab),eth_type(0x0800),ipv4(frag=no), packets:136600676, bytes:206813409172, used:0.170s, actions:4


```



```
### rhel 8.3 上编译内核的步骤
## 步骤参考王征写的文档里的步骤：https://github.com/wangzheng422/docker_env/blob/master/redhat/rhel/rhel8.build.kernel.repo.cache.md
## 安装 yum-utils 和 rpm-build
# yum -y install yum-utils rpm-build 

## 下载并安装 kernel src rpm
# cd /root
# yumdownloader --source kernel.x86_64
# rpm -ivh /root/kernel-4.18.0-240.1.1.el8_3.src.rpm

## 安装编译依赖
# cd /root/rpmbuild/SPECS
# yum install libselinux-devel
# yum-builddep kernel.spec

## 建立编译环境
# rpmbuild -bp kernel.spec

# https://www.cnblogs.com/luohaixian/p/9313863.html
KERNELVERION=$(uname -r | sed "s/.$(uname -m)//")
KERNELRV=$(uname -r)
KERNELSV=$(echo $KERNELRV | sed 's/_.//')

cd /root/rpmbuild/BUILD/kernel-${KERNELVERION}/linux-${KERNELSV}/

/bin/cp -f configs/kernel-4.18.0-$(uname -m).config .config

make oldconfig

make menuconfig

## 执行 make menuconfig
## 根据需要调整以下配置项目
## 按 '/' 搜索
## 以 CONFIG_NF_FLOW_TABLE_IPV4 为例
## 按 '/' 搜索，输入 CONFIG_NF_FLOW_TABLE_IPV4，然后按 1, 按 M
## 其他项目与上述过程相同，最后选择 ‘Save' 并退出 
# CONFIG_MLX5_TC_CT=y
# CONFIG_NET_ACT_CT=m
# CONFIG_SKB_EXTENSIONS=y
# CONFIG_NET_TC_SKB_EXT=y
# CONFIG_NF_FLOW_TABLE=m
# CONFIG_NF_FLOW_TABLE_IPV4=m  x
# CONFIG_NF_FLOW_TABLE_IPV6=m  x
# CONFIG_NF_FLOW_TABLE_INET=m
# CONFIG_NET_ACT_CONNMARK=m x
# CONFIG_NET_ACT_IPT=m  x
# CONFIG_NET_EMATCH_IPT=m   x
# CONFIG_NET_ACT_IFE=m  x

## 检查更改情况
cat .config | grep -E "CONFIG_MLX5_TC_CT|CONFIG_NET_ACT_CT|CONFIG_SKB_EXTENSIONS|CONFIG_NET_TC_SKB_EXT|CONFIG_NF_FLOW_TABLE|CONFIG_NF_FLOW_TABLE_IPV4|CONFIG_NF_FLOW_TABLE_IPV6|CONFIG_NF_FLOW_TABLE_INET|CONFIG_NET_ACT_CONNMARK|CONFIG_NET_ACT_IPT|CONFIG_NET_EMATCH_IPT|CONFIG_NET_ACT_IFE" 

## 在 .config 文件开始位置插入 # x86_64
sed -i '1s/^/# x86_64\n/' .config

## 将作出的修改拷贝到 /root/rpmbuild/SOURCES
/bin/cp -f .config configs/kernel-4.18.0-$(uname -m).config
/bin/cp -f .config configs/kernel-x86_64.config
/bin/cp -f configs/* ~/rpmbuild/SOURCES/

cd ~/rpmbuild/SPECS
cp kernel.spec kernel.spec.orig
# https://fedoraproject.org/wiki/Building_a_custom_kernel
# 自定义内核名称
sed -i "s/# define buildid \\.local/%define buildid \\.cuc/" kernel.spec

# 编译内核 rpm 
/usr/bin/nohup rpmbuild -bb --target=$(uname -m) --with baseonly --without debug --without debuginfo --without kabichk kernel.spec &

# 安装内核 rpm
sudo yum localinstall ~/rpmbuild/RPMS/x86_64/kernel-4.18.0-240.1.1.el8.cuc.x86_64.rpm ~/rpmbuild/RPMS/x86_64/kernel-core-4.18.0-240.1.1.el8.cuc.x86_64.rpm ~/rpmbuild/RPMS/x86_64/kernel-modules-4.18.0-240.1.1.el8.cuc.x86_64.rpm ~/rpmbuild/RPMS/x86_64/kernel-devel-4.18.0-240.1.1.el8.cuc.x86_64.rpm ~/rpmbuild/RPMS/x86_64/kernel-headers-4.18.0-240.1.1.el8.cuc.x86_64.rpm

# 重启系统
reboot

# 检查内核版本及内核配置
uname -r 
sudo cat /boot/config-$(uname -r) | grep -E "CONFIG_MLX5_TC_CT|CONFIG_NET_ACT_CT|CONFIG_SKB_EXTENSIONS|CONFIG_NET_TC_SKB_EXT|CONFIG_NF_FLOW_TABLE|CONFIG_NF_FLOW_TABLE_IPV4|CONFIG_NF_FLOW_TABLE_IPV6|CONFIG_NF_FLOW_TABLE_INET|CONFIG_NET_ACT_CONNMARK|CONFIG_NET_ACT_IPT|CONFIG_NET_EMATCH_IPT|CONFIG_NET_ACT_IFE"
```