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
```