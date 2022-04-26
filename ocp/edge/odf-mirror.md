### Test ODF mirror

```
# 安装 subctl
$ wget https://github.com/submariner-io/submariner-operator/releases/download/subctl-release-0.10/subctl-release-0.10-darwin-amd64.tar.xz

# 检查 clusterCIDR 和 serviceCIDR 网络在集群间是否重叠
# hub cluster
$ oc --kubeconfig=./hub/lb-ext.kubeconfig get networks.config.openshift.io cluster -o json | jq .spec
{
  "clusterNetwork": [
    {
      "cidr": "10.132.0.0/14",
      "hostPrefix": 23
    }
  ],
  "externalIP": {
    "policy": {}
  },
  "networkType": "OpenShiftSDN",
  "serviceNetwork": [
    "172.32.0.0/16"
  ]
}

# 检查 clusterCIDR 和 serviceCIDR 网络在集群间是否重叠
# cluster2 cluster
$ oc --kubeconfig=./cluster2/lb-ext.kubeconfig get networks.config.openshift.io cluster -o json | jq .spec
{
  "clusterNetwork": [
    {
      "cidr": "10.140.0.0/14",
      "hostPrefix": 23
    }
  ],
  "externalIP": {
    "policy": {}
  },
  "networkType": "OVNKubernetes",
  "serviceNetwork": [
    "172.71.0.0/16"
  ]
}

# hub 安装 ODF 
# 检查 hub ocs-operator 日志，看是否有报错 
$ oc --kubeconfig=./hub/lb-ext.kubeconfig -n openshift-storage logs $(oc --kubeconfig=./hub/lb-ext.kubeconfig -n openshift-storage get pods -l name=ocs-operator -o name)

# 检查 hub cluster ODF 是否就绪
oc --kubeconfig=./hub/lb-ext.kubeconfig get storagecluster -n openshift-storage ocs-storagecluster -o jsonpath='{.status.phase}{"\n"}'

# 检查 cluster3 ocs-operator 日志
$ oc --kubeconfig=./cluster3/lb-ext.kubeconfig -n openshift-storage logs $(oc --kubeconfig=./cluster3/lb-ext.kubeconfig -n openshift-storage get pods -l name=ocs-operator -o name)

$ oc --kubeconfig=./cluster3/lb-ext.kubeconfig get nodes

# 检查 cluster3 mcp 
$ oc --kubeconfig=./cluster3/lb-ext.kubeconfig -n openshift-machine-config-operator logs $(oc --kubeconfig=./cluster3/lb-ext.kubeconfig -n openshift-machine-config-operator get pods -l k8s-app="machine-config-daemon" -o name) -c machine-config-daemon
$ oc --kubeconfig=./cluster3/lb-ext.kubeconfig -n openshift-machine-config-operator logs pod/machine-config-daemon-d96m6 -c machine-config-daemon
```