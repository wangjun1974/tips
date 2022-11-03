### SNO 集群出现问题时的排查步骤 
```
1. 首先检查 haproxy 页面，看是否 kube-api-server 正常
2. 如果 kube-api-server 有问题则尝试 
$ sudo systemctl restart kubelet
$ sudo systemctl restart crio ; sudo systemctl restart kubelet
3. 如果经过上述操作 kube-api-server 仍有问题
$ sudo journalctl -u kubelet 2>&1 | sudo tee /tmp/kubelet.log
4. 检查日志
https://access.redhat.com/solutions/6964570
https://bugzilla.redhat.com/show_bug.cgi?id=1510167
POD_UUID=d8fd90e1-09b5-4ee1-b3b1-2c2eabe75895
ls /var/lib/kubelet/pods/${POD_UUID}/volumes/kubernetes.io~csi/pvc-bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
vol_data.json
rm -rf /var/lib/kubelet/pods/${POD_UUID}/volumes/kubernetes.io~csi/pvc-bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb

### 找到 vol_data.json
### 删除 vol_data.json 及目录
```