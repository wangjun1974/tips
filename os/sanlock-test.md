### sanlock 测试过程
```
环境

1. 最开始虚拟机 jwang-rhel8-01 跑在 node3 上，配置了 vmlease
virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf dumpxml jwang-rhel8-01 | grep "<lease>" -A4






2. 虚拟机的存储在 node2 所在的 nfs 上
sanlock client status | grep <lockspace>






3. 虚拟机的 lockspace 对应的 storagedomain 在 node2 nfs 上
4. 虚拟机的 vmlease 也在 node2 nfs 上






5. 为了模拟 node3 无法访问存储，在 node2 添加防火墙规则禁止访问 node2 nfs
在 node2 添加
iptables -I INPUT 1 -s 10.66.208.53/32 -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 2049 -j DROP







6. 隔一段时间后， 查询lockspace会看到
sanlock client gets -h 3 
h 3 gen 223 timestamp 3303400 FAIL

7. 再过一段时间后，查询lockspace会看到
sanlock client gets -h 3 
h 3 gen 223 timestamp 3303400 DEAD







8. 回到 rhev 界面，可以看到 node3 已经被 wdmd 重启
9. 虚拟机 jwang-rhel8-01 在其他节点上自动重启
```