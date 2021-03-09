
相关步骤参考谭春阳所写的《在BCLinux8.1上安装配置OFED+OVS-kernel硬件offload》

配置 iommu 和 HugePage
```
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

## 如果存在efi目录说明，使用的是UEFI，启动配置文件为
# find /boot/efi/EFI -name "grub.cfg"
/boot/efi/EFI/redhat/grub.cfg

## 如果不存在 /sys/firmware/efi 目录，那么物理主机使用的是 BIOS 启动方式，对应的启动配置文件为 /boot/grub2/grub.cfg

## 生成启动配置文件 - UEFI
# grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg

## 生成启动配置文件 - BIOS
# grub2-mkconfig -o /boot/grub2/grub.cfg

## 重启系统
# reboot

## 确认iommu和HugePage设置生效
## 输出里应包含 intel_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=8
# cat /proc/cmdline

## 下载驱动和dpdk+openvswitch介质
## 链接: https://pan.baidu.com/s/1B4bRcnpyAv8L-GzPB32Orw 密码: r9ck
## 这个目录包含 rhel 8.3 的软件仓库
## rhel-8-for-x86_64-baseos-rpms
## rhel-8-for-x86_64-baseos-source-rpms
## rhel-8-for-x86_64-appstream-rpms
## rhel-8-for-x86_64-supplementary-rpms
## codeready-builder-for-rhel-8-x86_64-rpms
## 需要安装的软件包括 dpdk 和 openvswitch


```