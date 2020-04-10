# Red Hat Ceph Storage 硬件选择建议

## 摘要

### 服务器选择

#### 通用服务器

#### 存储服务器

### 存储目标

#### IOPS优化类型：高IOPS

#### 吞吐优化类型：高吞吐

#### 容量优化类型：高容量

## 通用原则

### 用例：如何用，怎么用

#### IOPS优化类型：高IOPS，跑MYSQL数据库，需要15k SAS盘及SSD做journal，有些高IOPS的场合可以考虑使用全闪存配置

#### 吞吐优化类型：高吞吐，提供图像，音频及视频数据，具体怎么配具体再看

#### 容量优化类型：高容量，容量型对价格敏感，所以通常不会选择高速硬盘，高带宽网卡，SSD及闪存，由于不再使用SSD做日志，数据及日志共存在硬盘上

### 存储密度

#### 硬件规划时会考虑集群规模，存储节点数量，每个节点数据盘数量及大小，存储模式及副本数量

#### 当节点硬件发生故障，这个节点上的数据会在其他节点上恢复。恢复时会通过网络复制数据，一个常见问题是小规模集群配置了非常多的数据盘，当节点发生故障时需要拷贝过多的数据，这些数据的拷贝对网络造成非常大的压力，结果影响了正常的数据访问；如果限制恢复时的数据复制对带宽的占用又会造成数据复制在很长时间内无法完成，集群无法尽快恢复到健康状态

### 相同硬件配置原则：尽可能缩小硬件配置差异性

#### 相同的磁盘控制器

#### 相同的磁盘大小

#### 相同的磁盘转速

#### 相同的机械磁盘寻道时间

#### 相同的I/O读写能力

#### 相同的网络吞吐

#### 相同的日志配置方法

### 网络带宽配置建议

#### 生产环境至少需要10Gbps Ethernet，不考虑1Gbps Ethernet

#### 假设需要复制1TB数据，用1Gbps网络需要拷贝3个小时，3TB需要9个小时

#### 假设需要复制1TB数据，用10Gbps网络需要拷贝20分钟，3TB需要1个小时

#### 当OSD失效时，Cluster会复制数据到同pool的其他OSD

#### 当多个OSD同时失效时，例如存储节点出现问题，Rack出现问题，大量的数据需要通过网络进行复制

#### 最少1块10Gbps网卡，根据需要可以配置多块10Gbps及以上的网卡

#### 如果条件允许把前端网络（public network）和后端网络 (cluster network) 放在不同的网卡及网卡绑定上

#### 由于前端网络和后端网络承载的数据量是不一样的，可以粗略认为后端网络将承载前端网络乘以osd_pool_default_size倍的数据量，因此如果有条件可为后端网络配置比前端网络更高的带宽

#### 采用多Rack设计时，接入交换交换机上联可采用Fat Tree模式，例如10Gbps以太交换机，采用40Gbps上联或者多个10Gbps用QSFP+或SFP+线捆绑成至少40Gbps上联其他Rack或Spine或汇聚交换机/汇聚路由器

### 避免使用RAID

#### Ceph本身通过复制或者Erasure Code提供冗余

#### Raid在块级别上提供冗余

#### 两者同时采用会浪费存储空间

#### Raid降级（部分出现问题）时将影响Ceph的性能

#### 有的时候服务器配置了Raid卡且必须使用，这个时候的建议是：

##### 控制器有电池支撑

##### 控制器电池有电（需定期检测）

##### 控制器启用write-back cache模式

##### 每块盘配置为1个Raid0的Virtual Volume

##### 当1个控制器下有很多盘，这个时候write back cache会成为瓶颈，需要把每块盘配置为JBOD模式来消除瓶颈

### 选择硬件时的常见错误

#### 把低性能的旧硬件拿来做Ceph节点

#### 在一个Ceph Pool里使用不同规格配置的硬件

#### 采用1Gbps的网卡

#### 使用RAID

#### 选择磁盘时只考虑价格因素，未考虑性能和吞吐

#### 磁盘控制器的性能不够

### 其他可供参考的资源

#### Red Hat Ceph Storage: Supported configurations 参见：https://bluejeans.com/9999103687

## 根据负载类型进行有针对性的性能优化

### CRUSH是Controlled Replication Under Scalable Hashing的缩写

### CRUSH map描述集群资源拓扑

### CRUSH map同时存在于Ceph Monitor节点和Ceph Client节点

### Ceph Monitor负责维护CRUSH Map

### Ceph Client从Ceph Monitor那里获取CRUSH map，使用本地副本

### Ceph Client和Ceph OSD都使用CRUSH map和CRUSH算法来访问对象检索对象

### Ceph Client使用CRUSH map和CRUSH算法直接于OSD通信，无需每次都查询Ceph Monitor

### Ceph OSD使用CRUSH map和CRUSH算法与peer OSD通信，处理replication, backfilling和恢复

### 可以使用CRUSH map描述故障域和性能域

### Red Hat Ceph Storage 2及更早版本每个性能域都位于单独的层次结构

### Red Hat Ceph Storage 3使用Device Class来实现性能域

https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html/storage_strategies_guide/crush_administration#device_classes

https://arpnetworks.com/blog/2019/06/28/how-to-update-the-device-class-on-a-ceph-osd.html

## 硬件供应商打包方案

### IOPS优化方案

#### OSD采用NVMe SSD

#### 每个OSD配置 10 Core * 2GHz CPU，默认1个Core有两个Processor

#### 在16 GB内存的基础上，每个OSD配置 5GB 内存

#### 每12个OSD配置10Gbps网络，如public/cluster分离需分别配置

#### Journal: 数据与Journal都存放在相同磁盘上

#### 控制器为PCIe类型控制器

#### 参考配置：https://www.supermicro.com/solutions/storage_ceph.cfm

### 吞吐量优化方案

#### OSD采用7200转HDD

#### 每个OSD配置 0.5 Core * 2GHz CPU，默认1个Core有两个Processor

#### 在16 GB内存的基础上，每个OSD配置 5GB 内存

#### 每12个OSD配置10Gbps网络，如public/cluster分离需分别配置

#### Journal: 高可靠，高性能SSD或者NVMe SSD

#### OSD与Journal比例：一般SSD配置4-5:1，NVMe SSD配置12-18:1

#### 控制器为JBOD类型控制器

#### 参考配置：http://www.qct.io/solution/index/Storage-Virtualization/QxStor-Red-Hat-Ceph-Storage-Edition#specifications

#### 参考配置：http://en.community.dell.com/techcenter/cloud/m/dell_cloud_resources/20442913/download

#### 参考配置：http://en.community.dell.com/techcenter/cloud/m/dell_cloud_resources/20443454/

#### 参考配置：https://www.redhat.com/en/resources/resources-red-hat-ceph-storage-hardware-selection-guide-html

#### 参考配置：https://www.cisco.com/c/en/us/products/servers-unified-computing/ucs-c3260-rack-server/index.html

### 容量优化方案

#### OSD采用7200转HDD

#### 1块盘1个OSD

#### 每个OSD配置 0.5 Core * 2GHz CPU，默认1个Core有两个Processor

#### 在16 GB内存的基础上，每个OSD配置 5GB 内存

#### 每12个OSD配置10Gbps网络，如public/cluster分离需分别配置

#### Journal: 与OSD放在一起

#### 控制器为JBOD类型控制器

#### 参考配置：https://www.supermicro.com/solutions/datasheet_Ceph.pdf

## 最小配置建议

### 参考最小配置：https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html/hardware_guide/minimum-hardware-recommendations_hw

### 非容器化CPU需求为1个OSD对应0.5个CPU Core * 2 GHz CPU，默认1个Core有两个Processor

### 容器化以后OSD内存需求提高到1个OSD 5G内存

## 容器化后的最小配置建议

### 参考最小配置：https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html/hardware_guide/minimum-hardware-recommendations-for-containerized-ceph_hw

### 容器化以后CPU需求提高为1个容器0.5个CPU Core 2 GHz，默认1个Core有两个Processor

### 容器化以后OSD内存需求提高1个OSD 5G内存

## Red Hat Ceph Dashboard管理UI的最小配置建议

### 处理器：4个2.5 GHz处理器核心或者更高配置

### 内存：8GB

### 硬盘：50 GB

### 网络：至少1Gbps

