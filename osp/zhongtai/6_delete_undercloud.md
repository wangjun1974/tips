### 删除 undercloud 的镜像
参考知识库文档 https://access.redhat.com/solutions/2210421 
```

# 注意：如果镜像未删除干净，可能需要多次执行删除容器和删除镜像的操作
source stackrc
if [[ $(grep -oP " [0-9]+" /etc/rhosp-release) -ge 16 ]]; then 
  echo "OSP16+ deleting overcloud and containers";
  openstack overcloud delete overcloud -y
  sudo podman rm -f $(sudo podman ps -aq)
  sudo podman rmi $(sudo podman images -q)
fi

# 然后修改 containers-prepare-parameter.yaml
# 安装时如果遇到错误
# OSP16: creating local image mirror fails - Unknown www-authenticate value: Basic realm="Registry Realm"
# 参考：https://bugzilla.redhat.com/show_bug.cgi?id=1869583
# 注意添加 DockerInsecureRegistryAddress
cat >> containers-prepare-parameter.yaml << EOF
  DockerInsecureRegistryAddress:
    - helper.example.com:5000
EOF

# 一个修改过的 containers-prepare-parameter.yaml 的最后部分的例子
# 包含本地 ContainerImageRegistryCredentials
# 和 DockerInsecureRegistryAddress
#
  ContainerImageRegistryCredentials:
    'helper.example.com:5000':
      dummy: dummy
  DockerInsecureRegistryAddress:
    - helper.example.com:5000

# 在做完这一步之后，可以考虑重新安装 undercloud
time openstack undercloud install


```