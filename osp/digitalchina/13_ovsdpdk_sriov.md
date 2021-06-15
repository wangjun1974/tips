### 配置 ovsdpdk 
```
# 部署 RHOSP 使用 OVS mechanism driver
# 修改 containers-prepare-parameter.yaml, 设置 neutron_driver 参数为 null
# 参考: https://github.com/wangjun1974/ospinstall/blob/main/containers-prepare-parameter.yaml.example.md
parameter_defaults:
  ContainerImagePrepare:
  - push_destination: true
    set:
      neutron_driver: null


```


### 配置 sriov
```

```

### 软件频道 rhel-8-for-x86_64-nfv-rpms 包含那些软件包
```
Red Hat Enterprise Linux 8 for x86_64 - Real Ti 4.5 MB/s | 213 MB     00:46    
comps.xml for repository rhel-8-for-x86_64-nfv-rpms saved
(1/22): kernel-rt-devel-4.18.0-193.28.1.rt13.77 1.5 MB/s |  15 MB     00:09    
(2/22): rt-tests-1.5-18.el8.x86_64.rpm           86 kB/s | 177 kB     00:02    
(3/22): kernel-rt-modules-extra-4.18.0-193.28.1 808 kB/s | 3.4 MB     00:04    
(4/22): tuned-profiles-nfv-2.13.0-6.el8.noarch.  17 kB/s |  32 kB     00:01    
(5/22): kernel-rt-debug-core-4.18.0-193.28.1.rt 2.0 MB/s |  52 MB     00:26    
(6/22): kernel-rt-modules-4.18.0-193.28.1.rt13. 1.8 MB/s |  24 MB     00:13    
(7/22): kernel-rt-4.18.0-193.28.1.rt13.77.el8_2 629 kB/s | 2.8 MB     00:04    
(8/22): kernel-rt-debug-devel-4.18.0-193.28.1.r 1.5 MB/s |  15 MB     00:10    
(9/22): rteval-3.0-6.el8.noarch.rpm              61 kB/s | 134 kB     00:02    
(10/22): tuned-profiles-realtime-2.13.0-6.el8.n  20 kB/s |  35 kB     00:01    
(11/22): kernel-rt-debug-modules-extra-4.18.0-1 954 kB/s | 4.1 MB     00:04    
(12/22): rteval-common-3.0-6.el8.noarch.rpm      24 kB/s |  42 kB     00:01    
(13/22): tuned-profiles-nfv-host-2.13.0-6.el8.n  19 kB/s |  36 kB     00:01    
(14/22): rt-setup-2.1-2.el8.x86_64.rpm           15 kB/s |  26 kB     00:01    
(15/22): kernel-rt-kvm-4.18.0-193.28.1.rt13.77. 1.0 MB/s | 3.2 MB     00:03    
(16/22): tuned-profiles-nfv-host-bin-0-0.1.2018  14 kB/s |  24 kB     00:01    
(17/22): tuned-profiles-nfv-guest-2.13.0-6.el8.  21 kB/s |  35 kB     00:01    
(18/22): kernel-rt-debug-kvm-4.18.0-193.28.1.rt 892 kB/s | 3.6 MB     00:04    
(19/22): kernel-rt-core-4.18.0-193.28.1.rt13.77 1.9 MB/s |  27 MB     00:14    
(20/22): kernel-rt-debug-modules-4.18.0-193.28. 2.3 MB/s |  47 MB     00:20    
(21/22): kernel-rt-debug-4.18.0-193.28.1.rt13.7 886 kB/s | 2.8 MB     00:03    
(22/22): rteval-loads-1.4-6.el8.noarch.rpm      817 kB/s | 101 MB     02:06 
```