## RHEL8下同步软件仓库

```
#!/bin/bash

localPath="/repos/"
fileConn="/getPackage/"

for i in rhel-8-for-x86_64-baseos-rpms \
         rhel-8-for-x86_64-appstream-rpms \
         rhel-8-for-x86_64-highavailability-rpms \
         ansible-2.8-for-rhel-8-x86_64-rpms \
         satellite-tools-6.5-for-rhel-8-x86_64-rpms \
         openstack-16-for-rhel-8-x86_64-rpms \
         fast-datapath-for-rhel-8-x86_64-rpms \
         rhceph-4-tools-for-rhel-8-x86_64-rpms \
         rhceph-4-osd-for-rhel-8-x86_64-rpms \
         rhceph-4-mon-for-rhel-8-x86_64-rpms \
         advanced-virt-for-rhel-8-x86_64-rpms
do
  mkdir -p "$localPath"$i"$fileConn"
  rm -rf "$localPath"$i"$fileConn"repodata

  echo "sync channel $i..."
  reposync --download-path="$localPath" --download-metadata --repoid=$i

done

exit 0
```
