# 参见 
# https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/8/html/performing_a_standard_rhel_installation/creating-a-bootable-usb-windows_assembly_creating-a-bootable-installation-medium

### 在 WINDOWS 中创建可引导 USB 设备

#### 先决条件
* 已下载安装 ISO 镜像<br>
* DVD ISO 镜像大于 4.7 GB，因此需要一个足够存放 ISO 镜像的 USB 闪存驱动器<br>

#### 流程
1. 从 https://github.com/FedoraQt/MediaWriter/releases 下载并安装 Fedora Media Writer<br>
2. 连接 USB 驱动器<br>
3. 运行 Fedora Media Writer<br>
4. 在窗口中点击 Custom Image 并选择之前下载的 Red Hat Enterprise Linux ISO 镜像<br>
5. 在 Write Custom Image 窗口中，选择要使用的 USB 驱动器<br>
6. 点 Write to disk 开始引导介质创建过程。操作完成前不要拔出驱动器<br>
7. 当操作完成后，卸载 USB 驱动器。USB 驱动器现在可作为引导设备使用<br>

