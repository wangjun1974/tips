### 启用 Hosted control planes 这个 Technical Preview 的功能

```
# 首先获取 mce 实例
$ oc get mce 
NAME                 STATUS      AGE
multiclusterengine   Available   27d

# 在这个实例上启用 Hosted control planes
$ oc patch mce multiclusterengine --type=merge -p '{"spec":{"overrides":{"components":[{"name":"hypershift-preview","enabled": true}]}}}'

# 在 multicluster-engine namespace 下会有 'hypershift-deployment-controller' 和 'hypershift-addon-manager'  pod 被创建
$ oc get pods -n multicluster-engine | grep hypershift
hypershift-addon-manager-7c6b79bb77-sd9dr              1/1     Running   0             86s
hypershift-deployment-controller-dcd744745-s79fm       1/1     Running   0             86s


```

### 如何检查 hypershift 相关的日志
```
# 查看 hypershift-addon-manager 的日志
$ oc -n multicluster-engine logs $( oc -n multicluster-engine get pods -l app=hypershift-addon-manager -o name )

# 查看 hypershift-addon-manager 的日志
```