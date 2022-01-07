# 生成镜像下载列表文件
```
cat > assistedinstaller.image.lst << EOF
quay.io/edge-infrastructure/assisted-service:latest
quay.io/edge-infrastructure/assisted-installer-ui:latest
quay.io/edge-infrastructure/assisted-image-service:latest
registry.access.redhat.com/ubi8/pause:latest
quay.io/centos7/postgresql-12-centos7:latest
EOF
```

# pull image
```
cat assistedinstaller.image.lst | while read i ; do podman pull ${i} ; done
```

# 保存 image
```
mkdir -p assisted-installer-images

cat assistedinstaller.image.lst | while read i ; do
  basename=$(echo ${i##*/} | awk -F':' '{print $1}' )
  podman save -o assisted-installer-images/${basename}.tar ${i}
done

tar zcvf assisted-installer-images.tar.gz assisted-installer-images/ 
```

# 拷贝 assisted-installer-images.tar.gz 到目标环境

# 加载镜像到目标
```
tar zxvf assisted-installer-images.tar.gz

for i in assisted-installer-images/*.tar ; do
  podman load -i $i
done
```