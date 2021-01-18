### 准备模版，配置 Fixed VIPs

```
# 生成模版文件 ~/templates/environments/fixed-ip-vips.yaml
# ControlFixedIPs 和 PublicVirtualFixedIPs 根据实际环境网络配置进行调整
# 其他网络在当前部署中未更改，因此可以延用目前的配置
cat > ~/templates/environments/fixed-ip-vips.yaml << EOF
# This template allows the IPs to be preselected for each VIP. Note that
# this template should be included after other templates which affect the
# network such as network-isolation.yaml.

resource_registry:
  OS::TripleO::Network::Ports::ExternalVipPort: ../network/ports/external.yaml
  OS::TripleO::Network::Ports::InternalApiVipPort: ../network/ports/internal_api.yaml
  OS::TripleO::Network::Ports::StorageVipPort: ../network/ports/storage.yaml
  OS::TripleO::Network::Ports::StorageMgmtVipPort: ../network/ports/storage_mgmt.yaml
  OS::TripleO::Network::Ports::RedisVipPort: ../network/ports/vip.yaml
  OS::TripleO::Network::Ports::OVNDBsVipPort: ../network/ports/vip.yaml

parameter_defaults:
  # Set the IP addresses of the VIPs here.
  # NOTE: we will eventually move to one VIP per service
  #
  ControlFixedIPs: [{'ip_address':'192.0.2.240'}]
  PublicVirtualFixedIPs: [{'ip_address':'192.168.122.40'}]
  InternalApiVirtualFixedIPs: [{'ip_address':'172.16.2.240'}]
  StorageVirtualFixedIPs: [{'ip_address':'172.16.1.240'}]
  StorageMgmtVirtualFixedIPs: [{'ip_address':'172.16.3.240'}]
  RedisVirtualFixedIPs: [{'ip_address':'172.16.2.241'}]
  OVNDBsVirtualFixedIPs: [{'ip_address':'172.16.2.242'}]
EOF
```