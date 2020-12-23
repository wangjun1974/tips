# use following command try to lower ocs 4.5 cpu/memory request and limit 
# see: https://rook.io/docs/rook/v1.4/ceph-cluster-crd.html

3 worker with 8 vcpu and 32 GB mem and it works in my environment.
```
# patch ocs cpu/memory requests and limits
cpu_limit="500m"
cpu_request="500m"
memory_limit="512Mi"
memory_request="512Mi"

for service in mds mgr mon osd noobaa-core noobaa-db rgw prepareosd crashcollector cleanup
do
  oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"'${service}'": {"Limit": {"cpu": "'${cpu_limit}'"}}}}}'
  oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"'${service}'": {"Request": {"cpu": "'${cpu_request}'"}}}}}'

  oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"'${service}'": {"Limit": {"memory": "'${memory_limit}'"}}}}}'
  oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"'${service}'": {"Request": {"memory": "'${memory_request}'"}}}}}'  
done


# rgw pod has limits/requests that could set by patch deployment object
# bellow commands works 
# patch rgw deployment resources requests and limits
for i in rook-ceph-rgw-ocs-storagecluster-cephobjectstore-a rook-ceph-rgw-ocs-storagecluster-cephobjectstore-b 
do 
  oc -n openshift-storage patch deployment ${i} --type json -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "500m"}]'
  oc -n openshift-storage patch deployment ${i} --type json -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "512Mi"}]'

  oc -n openshift-storage patch deployment ${i} --type json -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value": "500m"}]'
  oc -n openshift-storage patch deployment ${i} --type json -p '[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "512Mi"}]'
done


# following command could remove requests/limits from pod and deployment but rgw still in pending status
oc patch deployment rook-ceph-rgw-ocs-storagecluster-cephobjectstore-b -n openshift-storage --type json -p '[{ "op": "remove", "path": "/spec/template/spec/containers/0/resources/limits" }]'
oc patch deployment rook-ceph-rgw-ocs-storagecluster-cephobjectstore-b -n openshift-storage --type json -p '[{ "op": "remove", "path": "/spec/template/spec/containers/0/resources/requests" }]'

oc patch pod rook-ceph-rgw-ocs-storagecluster-cephobjectstore-b-678c5c8tcqcg -n openshift-storage --type json -p '[{ "op": "remove", "path": "/spec/containers/0/resources/limits" }]'
oc patch pod rook-ceph-rgw-ocs-storagecluster-cephobjectstore-b-678c5c8tcqcg -n openshift-storage --type json -p '[{ "op": "remove", "path": "/spec/containers/0/resources/requests" }]'


# original methods 
# patch ocs cpu request and limit 
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mds": {"Limit": {"cpu": "500m"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mds": {"Request": {"cpu": "500m"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mgr": {"Limit": {"cpu": "500m"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mgr": {"Request": {"cpu": "500m"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mon": {"Limit": {"cpu": "500m"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mon": {"Request": {"cpu": "500m"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"osd": {"Limit": {"cpu": "500m"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"osd": {"Request": {"cpu": "500m"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"noobaa-core": {"Limit": {"cpu": "500m"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"noobaa-core": {"Request": {"cpu": "500m"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"noobaa-db": {"Limit": {"cpu": "500m"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"noobaa-db": {"Request": {"cpu": "500m"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"rgw": {"Limit": {"cpu": "500m"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"rgw": {"Request": {"cpu": "500m"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"prepareosd": {"Limit": {"cpu": "500m"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"prepareosd": {"Request": {"cpu": "500m"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"crashcollector": {"Limit": {"cpu": "500m"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"crashcollector": {"Request": {"cpu": "500m"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"cleanup": {"Limit": {"cpu": "500m"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"cleanup": {"Request": {"cpu": "500m"}}}}}'

# patch ocs memory request and limit
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mds": {"Limit": {"memory": "512Mi"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mds": {"Request": {"memory": "512Mi"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mgr": {"Limit": {"memory": "512Mi"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mgr": {"Request": {"memory": "512Mi"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mon": {"Limit": {"memory": "512Mi"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"mon": {"Request": {"memory": "512Mi"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"osd": {"Limit": {"memory": "512Mi"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"osd": {"Request": {"memory": "512Mi"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"rgw": {"Limit": {"memory": "512Mi"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"rgw": {"Request": {"memory": "512Mi"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"noobaa-db": {"Limit": {"memory": "512Mi"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"noobaa-db": {"Request": {"memory": "512Mi"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"prepareosd": {"Limit": {"memory": "512Mi"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"prepareosd": {"Request": {"memory": "512Mi"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"crashcollector": {"Limit": {"memory": "512Mi"}}}}}'  
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"crashcollector": {"Request": {"memory": "512Mi"}}}}}'

oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"cleanup": {"Limit": {"memory": "512Mi"}}}}}'
oc patch StorageCluster ocs-storagecluster -n openshift-storage --type=merge --patch='{"spec":{"resources":{"cleanup": {"Request": {"memory": "512Mi"}}}}}'
```