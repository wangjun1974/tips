# 基于 CoreOS Assembler（COSA）构建 Fedora CoreOS 的中文标准操作手册
https://coreos.github.io/coreos-assembler/

本手册旨在指导工程师在企业内部使用 CoreOS Assembler（COSA） 从零构建 Fedora CoreOS（FCOS）。
COSA 是构建 CoreOS 风格系统（包括 FCOS 与 RHCOS）的官方工具链。

## 1. 前置条件
### 1.1 构建机要求
* 操作系统：任意现代 Linux（RHEL/Fedora/CentOS/Ubuntu 均可）
* CPU：支持虚拟化（KVM）
* 内存：≥ 8 GB（推荐 16 GB）
* 磁盘：≥ 60 GB（构建镜像需要大量空间）
* 网络：可访问 Fedora 官方仓库

### 1.2 必要软件
* podman（推荐）或 docker
* git
* KVM 模块已启用：
```
lsmod | grep kvm
```

## 2. 准备构建环境
### 2.1 创建构建目录
```
mkdir fcos-build
cd fcos-build
```

## 3. 获取 CoreOS Assembler（COSA）
```
podman pull quay.io/coreos-assembler/coreos-assembler:latest
```

## 4. 初始化 COSA 工作目录
COSA 需要一个“配置仓库（config repo）”来描述 FCOS 的构建规则。
官方仓库为：
```
https://github.com/coreos/fedora-coreos-config
```
执行初始化：
```
podman run --rm -ti \
  -v ${PWD}:/srv/ \
  --device /dev/kvm \
  quay.io/coreos-assembler/coreos-assembler:latest \
  init \
  --repo https://github.com/coreos/fedora-coreos-config \
  --force
```
初始化完成后，当前目录会出现：
* src/config/（FCOS 配置）
* builds/（构建输出）
* tmp/（临时文件）

## 5. 获取 RPM 包与元数据（fetch）
```
podman run --rm -ti \
  -v ${PWD}:/srv/ \
  --device /dev/kvm \
  quay.io/coreos-assembler/coreos-assembler:latest \
  fetch
```
此步骤会：
* 从 Fedora 仓库下载所有需要的 RPM 包
* 生成元数据
* 准备构建环境

## 6. 构建 Fedora CoreOS（核心步骤）
```
podman run --rm -ti \
  -v ${PWD}:/srv/ \
  --device /dev/kvm \
  quay.io/coreos-assembler/coreos-assembler:latest \
  build
```

构建内容包括：
* OSTree commit
* 操作系统 rootfs
* 内核与 initramfs
* 基础镜像（raw、qcow2 等）

构建完成后，可在：
```
builds/latest/
```
看到输出内容。

## 7. 构建额外镜像格式（buildextend）
COSA 支持生成多种镜像格式，按需执行：
### 7.1 构建 Live ISO
```
cosa buildextend-live
```
### 7.2 构建裸金属镜像（metal）
```
cosa buildextend-metal
```
### 7.3 构建 QEMU 镜像（qcow2）
```
cosa buildextend-qemu
```
### 7.4 构建 PXE 镜像
```
cosa buildextend-pxe
```
注意：执行这些命令前需进入 COSA 容器内部（见下一节）。

## 8. 进入 COSA 开发容器（可选但推荐）
为了方便反复执行命令，可以进入 COSA shell：
```
podman run --rm -ti \
  -v ${PWD}:/srv/ \
  --device /dev/kvm \
  quay.io/coreos-assembler/coreos-assembler:latest \
  bash
```
进入后即可直接运行：
```
cosa fetch
cosa build
cosa buildextend-live
```

## 9. 查看构建结果
所有构建产物位于：
```
builds/latest/
```
常见文件：
|文件类型|说明|
|---|---|
|fedora-coreos-*.qcow2|QEMU 镜像|
|fedora-coreos-*.raw.xz|裸金属镜像|
|fedora-coreos-*.iso|Live ISO|
|ostree-commit.tar|OSTree commit|
|meta.json|构建元数据|

## 10. 使用构建的 FCOS 镜像
你可以用以下方式验证镜像：
### 10.1 QEMU 启动
```
qemu-system-x86_64 \
  -m 4096 \
  -smp 2 \
  -drive if=virtio,file=fedora-coreos.qcow2 \
  -nographic
```
### 10.2 裸金属部署
使用：
* PXE
* ISO
* CoreOS Installer

例如：
```
coreos-installer install /dev/sda \
  --image-url=http://your-server/fcos.raw.xz
```

## 11. 自定义 FCOS（进阶）
你可以修改：
* src/config/manifest.yaml
* src/config/overlay.d/
* src/config/ignition/
来自定义：
* 预装软件包
* systemd 服务
* 内核参数
* SELinux 配置
* Ignition 默认内容
修改后重新执行：
```
cosa build
```
即可生成自定义 FCOS。

## 12. 常见问题（FAQ）
### Q1：构建失败，提示缺少 RPM？
检查网络或 Fedora 仓库是否可访问。
### Q2：KVM 报错？
确保宿主机启用了虚拟化：
```
egrep -o 'vmx|svm' /proc/cpuinfo
```
### Q3：如何清理构建缓存？
```
cosa clean
```

## 一句话总结
使用 COSA 构建 Fedora CoreOS 的核心流程是：
init → fetch → build → buildextend → 使用镜像。