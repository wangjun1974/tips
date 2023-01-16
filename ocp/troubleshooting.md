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

1. 另外如果 kube-api-server 启动很短时间如几分钟后自动停止
2. 可考虑将 kube-api-server 按照上述方法启动起来
3. 在 kube-api-server 启动起来以后，查找 STATUS 非 'Running' 或者 'Complete' 的 pods，删除找到的 Pods
$ oc get pods -A | grep -Ev "Running|Complete" 


```

### 在 ACM Search 功能不好用的情况下，删除 statefulset search-redisgraph
https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.2/html/troubleshooting/troubleshooting
https://bugzilla.redhat.com/show_bug.cgi?id=2042210
```
# 首先确认 search pod 是否处于 Pending 状态

# 如果 search pod 处于 Pending 状态，再检查 pvc search-redisgraph-pvc-0 是否存在

# 如果 pvc search-redisgraph-pvc-0 不存在就删除 statefulset search-redisgraph
oc delete statefulset search-redisgraph -n open-cluster-management

# 如果问题仍未得到解决，可以删除并重建 open-cluster-management 下的 search-api, search-collector, search-controller 和 search-aggregator
```