
假设系统里有新加入的磁盘/dev/xvdg

准备xvdg，创建1个分区，这个分区占据磁盘整个大小
```
parted -s /dev/xvdg mklabel msdos 
parted -s /dev/xvdg unit mib mkpart primary 1 100%
parted -s /dev/xvdg set 1 lvm on
```

创建pv
```
pvcreate /dev/xvdg1
```

注意⚠️：
假设系统原来未使用逻辑卷则先创建卷组及逻辑卷
```
# vgcreate rhel /dev/xvdg1
# lvcreate -n backup -l +100%Free rhel
```

注意⚠️：
假设系统已使用扩展已有逻辑卷
```
# vgextend rhel /dev/xvdg1
# lvextend -l +100%Free /dev/rhel/backup /dev/xvdg1
```

```
mkdir -p /backup
mkfs.xfs /dev/rhel/backup
mount /dev/rhel/backup /backup
xfs_growfs /backup
```
