#!/bin/bash

virsh list --all | grep -v overcloud2 |  awk '/overcloud/ { print $2 }' > /tmp/overcloud-nodes

(
for i in $(cat /tmp/overcloud-nodes); do
  virsh dumpxml $i > /tmp/$i.xml
  mac=$(xmllint --xpath '//mac[1]' /tmp/$i.xml | awk -F= '{ print $2 }' | sed 's!/>$!!')
  addr=$(vbmc show $i | awk '/address/ {print "\""$4"\"" }')
  port=$(vbmc show $i | awk '/port/ { print "\""$4"\"" }')

  cat <<EOF
      {
         "mac": [
            $mac
         ],
         "name": "$i",
         "pm_addr": $addr,
         "pm_port": $port,
         "pm_password": "password",
         "pm_type": "pxe_ipmitool",
         "pm_user": "admin"
      }
EOF
  
done
) |  jq -s '{ "nodes": . }' > instackenv.json
