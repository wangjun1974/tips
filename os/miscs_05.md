### 检查证书
```
# 检查证书，可以观察证书是期望的证书，而不是中间设备的证书
openssl s_client -host <ocp-app> -port 443 -prexit -showcerts </dev/null
```

### ovirt vm ha 的实现
https://www.ovirt.org/develop/ha-vms.html<br>
https://www.ovirt.org/develop/developer-guide/vdsm/sanlock.html<br>
https://cloud.tencent.com/developer/article/1651000<br>
https://blog.didiyun.com/index.php/2018/12/27/sanlock-kvm/<br>
https://www.ovirt.org/develop/release-management/features/storage/vm-leases.html<br>
https://blog.csdn.net/maokexu123/article/details/40790939<br>
http://ahadas.com/slides/high_availability_with_no_split_brains.pdf<br>
https://github.com/oVirt/vdsm/blob/master/lib/vdsm/storage/xlease.py<br>
https://www.ovirt.org/develop/release-management/features/storage/vm-leases.html<br>
https://www.thegeekdiary.com/how-does-sanlock-work-in-redhat-virtualization/<br>

```
1. ovirt 关注的虚拟机失效情况包括
* 虚拟机所在的 host 失效
* 存储问题?
* 虚拟机的 qemu 进程 crash 

1. ovirt 下实现虚拟机 ha 时防止脑裂的主要技术
* sanlock data
* vmlease
* 控制恢复行为


LOCKSPACE = <lockspace_name>:<host_id>:<path>:<offset>
<lockspace_name>    name of lockspace
<host_id>       local host identifier in lockspace
<path>      disk to storage reserved for leases
<offset>        offset on path (bytes)

RESOURCE = <lockspace_name>:<resource_name>:<path>:<offset>[:<lver>]
<lockspace_name>    name of lockspace
<resource_name> name of resource
<path>      disk to storage reserved for leases
<offset>        offset on path (bytes)
<lver>        optional leader version or SH for shared lease


sanlock client status
# sanlock client status 
daemon faaa1a83-5ca3-490d-b150-84f61910d4f8.node1.rhcn
p -1 helper
p -1 listener
p 29563 HostedEngine
p 20320 alan-AD482-Adminsitrator
p 20576 alan-ceph-Administrator
p 20759 alan-event-Kafka
p 8724 jwang-win10-01
p -1 status
s 2b34a3a0-817f-4f92-acaa-77a4acc16e87:1:/rhev/data-center/mnt/node2.rhcnsa.org\:_ds21/2b34a3a0-817f-4f92-acaa-77a4acc16e87/dom_md/ids:0
s d41dad84-5700-4005-9735-3fb19703dad6:1:/rhev/data-center/mnt/node1.rhcnsa.org\:_ds11/d41dad84-5700-4005-9735-3fb19703dad6/dom_md/ids:0
s 1804173d-7310-42ed-95bd-2125b9d14f21:1:/rhev/data-center/mnt/node3.rhcnsa.org\:_ds31/1804173d-7310-42ed-95bd-2125b9d14f21/dom_md/ids:0
s 32e6bfba-3370-4ecd-984b-cb23b1b4725b:1:/rhev/data-center/mnt/node1\:_data/32e6bfba-3370-4ecd-984b-cb23b1b4725b/dom_md/ids:0
s hosted-engine:1:/var/run/vdsm/storage/32e6bfba-3370-4ecd-984b-cb23b1b4725b/061bcdbf-71b1-408d-a707-780769644594/6284a79b-00e9-4107-ac0f-bd128b4d074a:0
r 32e6bfba-3370-4ecd-984b-cb23b1b4725b:fa7b73dc-2481-4b02-baa9-183fda7172da:/rhev/data-center/mnt/node1\:_data/32e6bfba-3370-4ecd-984b-cb23b1b4725b/images/7c202d0a-e902-4e52-8a4b-ccf8a7c2ddde/fa7b73dc-2481-4b02-baa9-183fda7172da.lease:0:77 p 29563


Lockspaces and Resources In VDSM
https://www.ovirt.org/develop/developer-guide/vdsm/sanlock.html

VDSM 使用 Storage Domain 的 UUID 作为名称为每个 Storage Domain 分配一个 LockSpace。 

例如：
对于 Storage Domain 1dfcd18e-b179-4b95-aef6-f0fba1a3db45，
LockSpace 是 1dfcd18e-b179-4b95-aef6-f0fba1a3db45:0:/dev/1dfcd18e-b179-4b95-aef6-f0fba1a3db45/ids:0

上面的例子中
san client status 显示
...
s 2b34a3a0-817f-4f92-acaa-77a4acc16e87:1:/rhev/data-center/mnt/node2.rhcnsa.org\:_ds21/2b34a3a0-817f-4f92-acaa-77a4acc16e87/dom_md/ids:0

d41dad84-5700-4005-9735-3fb19703dad6:1:/rhev/data-center/mnt/node1.rhcnsa.org\:_ds11/d41dad84-5700-4005-9735-3fb19703dad6/dom_md/ids:0
这个是一个 Storage Domain 的 LockSpace
其中：
Storage Domain UUID 是 d41dad84-5700-4005-9735-3fb19703dad6
host id 是 1
包含 lease 的 path 是 /rhev/data-center/mnt/node1.rhcnsa.org\:_ds11/d41dad84-5700-4005-9735-3fb19703dad6/dom_md/ids
offset 是 0

另外对于资源
RESOURCE = <lockspace_name>:<resource_name>:<path>:<offset>[:<lver>]

r 32e6bfba-3370-4ecd-984b-cb23b1b4725b:fa7b73dc-2481-4b02-baa9-183fda7172da:/rhev/data-center/mnt/node1\:_data/32e6bfba-3370-4ecd-984b-cb23b1b4725b/images/7c202d0a-e902-4e52-8a4b-ccf8a7c2ddde/fa7b73dc-2481-4b02-baa9-183fda7172da.lease:0:77 p 29563

lockspace_name 是 32e6bfba-3370-4ecd-984b-cb23b1b4725b
resource_name 是 fa7b73dc-2481-4b02-baa9-183fda7172da
path 是 /rhev/data-center/mnt/node1\:_data/32e6bfba-3370-4ecd-984b-cb23b1b4725b/images/7c202d0a-e902-4e52-8a4b-ccf8a7c2ddde/fa7b73dc-2481-4b02-baa9-183fda7172da.lease
offset 是 0
lver 是 77 

lver 代表 leader version 

cat libvirtd.conf | grep -Ev "^#|^$" 


virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf list
...
 2     jwang-rhel8-01                 running

virsh -c qemu:///system?authfile=/etc/ovirt-hosted-engine/virsh_auth.conf dumpxml jwang-rhel8-01 | grep "<lease>" -A4
    <lease>
      <lockspace>2b34a3a0-817f-4f92-acaa-77a4acc16e87</lockspace>
      <key>4dfc2a55-7942-4895-b83e-aa2d742b8a85</key>
      <target path='/rhev/data-center/mnt/node2.rhcnsa.org:_ds21/2b34a3a0-817f-4f92-acaa-77a4acc16e87/dom_md/xleases' offset='3145728'/>
    </lease>

从 Host 视角查看 lockspace 的 delta lease 信息
sanlock client host_status -D

获取 sanlock 的 lockspace 下 host 的状态
sanlock client gets -h 1

我与 Nir 的邮件讨论
>
> Hello, Team,
>
> I have a question about sanlock and lockspace from ops view. Hope this is the right place for this type of question.

It depends; is this about a RHV setup or usage of sanlock on RHEL?

If this is a question about sanlock, using sanlock devel mailing list
may be a better place.
https://lists.fedorahosted.org/archives/list/sanlock-devel@lists.fedorahosted.org/

> Question:
> * as a user how could i get info how many hosts are active hosts in a lockspace?

You can query sanlock status using "sanlock client ..." commands.

This shows all the lockspaces that sanlock knows about and all the hosts
for every lockspace:

$ sudo sanlock client gets -h 1
s e9467633-ee31-4e15-b3f8-3812b374c764:1:/rhev/data-center/mnt/alpine:_01/e9467633-ee31-4e15-b3f8-3812b374c764/dom_md/ids:0
h 1 gen 13 timestamp 188815 LIVE
s 74843070-a4b3-43a4-8829-3ab8ec609bba:1:/rhev/data-center/mnt/alpine:_02/74843070-a4b3-43a4-8829-3ab8ec609bba/dom_md/ids:0
h 1 gen 13 timestamp 188817 LIVE
s 75f0e2e2-ede5-472e-9ffd-360da3172af8:1:/dev/75f0e2e2-ede5-472e-9ffd-360da3172af8/ids:0
h 1 gen 13 timestamp 188830 LIVE
s 9fcc4284-142b-4d0e-bc22-958e90564d9d:1:/dev/9fcc4284-142b-4d0e-bc22-958e90564d9d/ids:0
h 1 gen 13 timestamp 188830 LIVE
s 8fa47d3e-cfa2-490e-869e-bdff16adc335:1:/dev/8fa47d3e-cfa2-490e-869e-bdff16adc335/ids:0
h 1 gen 13 timestamp 188816 LIVE
s aecec81f-d464-4a35-9a91-6acf2ca4938c:1:/dev/aecec81f-d464-4a35-9a91-6acf2ca4938c/ids:0
h 1 gen 12 timestamp 188830 LIVE

I'm running this on the host with id 1, which is the only active host
in this oVirt setup.

After activating another host (host id 2), and waiting about 30
seconds, you see:

$ sudo sanlock client gets -h 1
s e9467633-ee31-4e15-b3f8-3812b374c764:1:/rhev/data-center/mnt/alpine:_01/e9467633-ee31-4e15-b3f8-3812b374c764/dom_md/ids:0
h 1 gen 13 timestamp 189082 LIVE
h 2 gen 6 timestamp 557 LIVE
s 74843070-a4b3-43a4-8829-3ab8ec609bba:1:/rhev/data-center/mnt/alpine:_02/74843070-a4b3-43a4-8829-3ab8ec609bba/dom_md/ids:0
h 1 gen 13 timestamp 189083 LIVE
h 2 gen 6 timestamp 557 LIVE
s 75f0e2e2-ede5-472e-9ffd-360da3172af8:1:/dev/75f0e2e2-ede5-472e-9ffd-360da3172af8/ids:0
h 1 gen 13 timestamp 189076 LIVE
h 2 gen 6 timestamp 548 LIVE
s 9fcc4284-142b-4d0e-bc22-958e90564d9d:1:/dev/9fcc4284-142b-4d0e-bc22-958e90564d9d/ids:0
h 1 gen 13 timestamp 189076 LIVE
h 2 gen 6 timestamp 548 LIVE
s 8fa47d3e-cfa2-490e-869e-bdff16adc335:1:/dev/8fa47d3e-cfa2-490e-869e-bdff16adc335/ids:0
h 1 gen 13 timestamp 189083 LIVE
h 2 gen 6 timestamp 569 LIVE
s aecec81f-d464-4a35-9a91-6acf2ca4938c:1:/dev/aecec81f-d464-4a35-9a91-6acf2ca4938c/ids:0
h 1 gen 12 timestamp 189076 LIVE
h 2 gen 5 timestamp 547 LIVE

So we have two LIVE hosts in this setup.

If we do hard shutdown of the other host (host id 2), and wait couple
of minutes,
we will see:

s e9467633-ee31-4e15-b3f8-3812b374c764:1:/rhev/data-center/mnt/alpine:_01/e9467633-ee31-4e15-b3f8-3812b374c764/dom_md/ids:0
h 1 gen 13 timestamp 189389 LIVE
h 2 gen 6 timestamp 783 FAIL
s 74843070-a4b3-43a4-8829-3ab8ec609bba:1:/rhev/data-center/mnt/alpine:_02/74843070-a4b3-43a4-8829-3ab8ec609bba/dom_md/ids:0
h 1 gen 13 timestamp 189391 LIVE
h 2 gen 6 timestamp 783 FAIL
s 75f0e2e2-ede5-472e-9ffd-360da3172af8:1:/dev/75f0e2e2-ede5-472e-9ffd-360da3172af8/ids:0
h 1 gen 13 timestamp 189383 LIVE
h 2 gen 6 timestamp 773 FAIL
s 9fcc4284-142b-4d0e-bc22-958e90564d9d:1:/dev/9fcc4284-142b-4d0e-bc22-958e90564d9d/ids:0
h 1 gen 13 timestamp 189383 LIVE
h 2 gen 6 timestamp 773 FAIL
s 8fa47d3e-cfa2-490e-869e-bdff16adc335:1:/dev/8fa47d3e-cfa2-490e-869e-bdff16adc335/ids:0
h 1 gen 13 timestamp 189391 LIVE
h 2 gen 6 timestamp 773 FAIL
s aecec81f-d464-4a35-9a91-6acf2ca4938c:1:/dev/aecec81f-d464-4a35-9a91-6acf2ca4938c/ids:0
h 1 gen 12 timestamp 189383 LIVE
h 2 gen 5 timestamp 772 FAIL

Which means the host stopped updating its lease, but it may have active
leases at this point.

After some more time, we will see:

s e9467633-ee31-4e15-b3f8-3812b374c764:1:/rhev/data-center/mnt/alpine:_01/e9467633-ee31-4e15-b3f8-3812b374c764/dom_md/ids:0
h 1 gen 13 timestamp 189512 LIVE
h 2 gen 6 timestamp 783 DEAD
s 74843070-a4b3-43a4-8829-3ab8ec609bba:1:/rhev/data-center/mnt/alpine:_02/74843070-a4b3-43a4-8829-3ab8ec609bba/dom_md/ids:0
h 1 gen 13 timestamp 189514 LIVE
h 2 gen 6 timestamp 783 DEAD
s 75f0e2e2-ede5-472e-9ffd-360da3172af8:1:/dev/75f0e2e2-ede5-472e-9ffd-360da3172af8/ids:0
h 1 gen 13 timestamp 189506 LIVE
h 2 gen 6 timestamp 773 DEAD
s 9fcc4284-142b-4d0e-bc22-958e90564d9d:1:/dev/9fcc4284-142b-4d0e-bc22-958e90564d9d/ids:0
h 1 gen 13 timestamp 189506 LIVE
h 2 gen 6 timestamp 773 DEAD
s 8fa47d3e-cfa2-490e-869e-bdff16adc335:1:/dev/8fa47d3e-cfa2-490e-869e-bdff16adc335/ids:0
h 1 gen 13 timestamp 189514 LIVE
h 2 gen 6 timestamp 773 DEAD
s aecec81f-d464-4a35-9a91-6acf2ca4938c:1:/dev/aecec81f-d464-4a35-9a91-6acf2ca4938c/ids:0
h 1 gen 12 timestamp 189506 LIVE
h 2 gen 5 timestamp 772 DEAD

Which means the host is considered DEAD, and all leases used on the host can
be used on other hosts.

To learn more about a specific lockspace, you can use:

$ sudo sanlock client host_status -s
'aecec81f-d464-4a35-9a91-6acf2ca4938c:1:/dev/aecec81f-d464-4a35-9a91-6acf2ca4938c/ids:0'
-D
1 timestamp 189650
    last_check=189671
    last_live=189671
    last_req=0
    owner_id=1
    owner_generation=12
    timestamp=189650
    io_timeout=10
    owner_name=d8635601-ea8b-4c5c-a624-41bd72b862d6
2 timestamp 772
    last_check=189671
    last_live=189322
    last_req=0
    owner_id=2
    owner_generation=5
    timestamp=772
    io_timeout=10
    owner_name=095bce26-9d5b-4ae2-b3bf-dddfc9cdf541
250 timestamp 0
    last_check=189671
    last_live=1000
    last_req=0
    owner_id=250
    owner_generation=1
    timestamp=0
    io_timeout=10
    owner_name=095bce26-9d5b-4ae2-b3bf-dddfc9cdf541

In RHV, host owner_name is the host hardware id - this can be used to locate
the host in engine. For example if I do this search in engine Hosts page:

    hw_id=095bce26-9d5b-4ae2-b3bf-dddfc9cdf541

I will find "host3" in my system.

David (sanlock author) may add more info about this.

Nir

模拟 node3 无法访问 node2 nfs 服务
在 node2 添加以下防火墙规则
iptables -I INPUT 1 -s 10.66.208.53/32 -p tcp -m conntrack --ctstate NEW,RELATED,ESTABLISHED --dport 2049 -j DROP

过一段时间后可以看到 h 3 也就是 node3 状态变为 FAIL 了，80秒未更新，h 状态变为 FAIL
[root@node2 ~]# sanlock client gets -h 3 
s 2b34a3a0-817f-4f92-acaa-77a4acc16e87:2:/rhev/data-center/mnt/node2.rhcnsa.org:_ds21/2b34a3a0-817f-4f92-acaa-77a4acc16e87/dom_md/ids:0 
h 1 gen 249 timestamp 3303294 LIVE
h 2 gen 213 timestamp 1582908 LIVE
h 3 gen 223 timestamp 3303400 FAIL

再过一段时间可以看到 h 3 也就是 node3 状态变为 DEAD 了，140秒未更新，h 状态变为 DEAD
[root@node2 ~]# sanlock client gets -h 3 
s 2b34a3a0-817f-4f92-acaa-77a4acc16e87:2:/rhev/data-center/mnt/node2.rhcnsa.org:_ds21/2b34a3a0-817f-4f92-acaa-77a4acc16e87/dom_md/ids:0 
h 1 gen 249 timestamp 3303376 LIVE
h 2 gen 213 timestamp 1582990 LIVE
h 3 gen 223 timestamp 3303400 DEAD


1. 最开始虚拟机 jwang-rhel8-01 跑在 node3 上，配置了 vmlease
2. 虚拟机的存储在 node2 所在的 nfs 上
3. 虚拟机的 lockspace 对应的 storagedomain 在 node2 nfs 上
4. 虚拟机的 vmlease 也在 node2 nfs 上
5. 为了模拟 node3 无法访问存储，在 node2 添加防火墙规则禁止访问 node2 nfs
6. 隔一段时间后， 查询lockspace会看到
h 3 gen 223 timestamp 3303400 FAIL
7. 再过一段时间后，查询lockspace会看到
h 3 gen 223 timestamp 3303400 DEAD
8. 回到 rhev 界面，可以看到 node3 已经被 wdmd 重启
9. 虚拟机 jwang-rhel8-01 在其他节点上自动重启
```

```
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
```