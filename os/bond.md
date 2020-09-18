参考：https://developer.rackspace.com/blog/lacp-bonding-and-linux-configuration/
参考：https://www.kernel.org/doc/Documentation/networking/bonding.txt

这篇文章介绍如何在Linux操作系统里，基于nmcli配置bond。
常见bond模式有mode 1(active-backup)和mode 4(802.3ad)

## 配置LACP模式的bond

创建bond0，配置静态ip地址
```
nmcli con add type bond \
    con-name bond0 \
    ifname bond0 \
    mode 802.3ad \
    ipv4.method 'manual' \
    ipv4.address '10.66.208.137/24' \
    ipv4.gateway '10.66.208.254' \
    ipv4.dns '10.64.63.6'
```

设置bond0的模式为802.3ad
```
nmcli con mod id bond0 bond.options \
    mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3
```

⚠️（可选）mtu设置，有的时候为了获得更好的网络性能，需要加大链路MTU设置。一般情况无需设置
⚠️ 需要在交换机端口，bond master，bond slave分别进行设置

```
nmcli con mod id bond0 802-3-ethernet.mtu 9000 
```

添加slave，例子里把p5p1和p5p2两块网卡作为slave添加到bond0里了，需根据系统实际网卡进行调整
```
nmcli con add type bond-slave ifname p5p1 con-name p5p1 master bond0
nmcli con add type bond-slave ifname p5p2 con-name p5p2 master bond0
```

重启slave
```
nmcli con stop p5p1 && nmcli con start p5p1
nmcli con stop p5p2 && nmcli con start p5p2
```

重启bond0
```
nmcli con stop bond0 && nmcli con start bond0
```

检查bond0
```
cat /proc/net/bonding/bond0
```

## 配置主备模式的bond

设置bond0的模式为active-backup
```
nmcli con mod id bond0 bond.options \
    mode=active-backup,miimon=100
```

## 在 bond 设备上添加 vlan 
```
nmcli con add type vlan con-name bond0-vlan-12 dev bond0 id 12
nmcli con mod bond0-vlan-12 \
    ipv4.method 'manual' \
    ipv4.address '10.66.208.237/24' \
    ipv4.gateway '10.66.208.254' \
    ipv4.dns '10.64.63.6'
```