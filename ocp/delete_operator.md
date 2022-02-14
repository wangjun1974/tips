### 如何清理有问题的 Operator 
https://access.redhat.com/solutions/6459071
```
# 按照以下步骤删除有问题的对象
# 1. 找出与 operator 有关的 job 
oc get job -n openshift-marketplace -o json | jq -r '.items[] | select(.spec.template.spec.containers[].env[].value|contains ("<operator_name_keyword>")) | .metadata.name'

# 2. 删除对应 job 和 configmap
oc delete job <job_string_returned_above> -n openshift-marketplace
oc delete configmap <job_string_returned_above> -n openshift-marketplace

# 3. 在界面删除 Operator

# 4. 检查 ip, sub 和 csv，按需删除 ip, sub 和 csv
oc delete ip <operator_installplan_name> -n <user_namespace>
oc delete sub <operator_subscription_name> -n <user_namespace>
oc delete csv <operator_csv_name> -n <user_namespace>
```