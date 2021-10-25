### 使用 RestAPI 创建实例
```

# 获取 auth token
curl -i \
  -H "Content-Type: application/json" \
  -d '
{ "auth": {
    "identity": {
      "methods": ["password"],
      "password": {
        "user": {
          "name": "project1admin",
          "domain": { "id": "default" },
          "password": "redhat"
        }
      }
    },
    "scope": {
      "project": {
        "name": "project1",
        "domain": { "id": "default" }
      }
    }
  }
}" \
https://overcloud.example.com:13000/v3/auth/tokens 2>&1 | tee /tmp/tempfile

token=$(cat /tmp/tempfile | awk '/X-Subject-Token: /{print $NF}' | tr -d '\r' )
echo $token
export mytoken=$token

# 获取 imageid
echo "GETTING IMAGES"
imageid=$(curl -s \
--header "X-Auth-Token: $mytoken" \
 https://overcloud.example.com:13292/v2/images | jq '.images[] | select(.name=="cirros")' | jq -r '.id' )

# 获取 flavorid
echo "GETTING FLAVOR"
flavorid=$(curl -s \
--header "X-Auth-Token: $mytoken" \
https://overcloud.example.com:13774/v2.1/flavors | jq '.flavors[] | select(.name=="m1.nano")' | jq -r '.id' )

# 获取 networkid
echo "GET NETWORK"
networkid=$(curl -s \
-H "Accept: application/json" \
-H "X-Auth-Token: $mytoken" \
https://overcloud.example.com:13696/v2.0/networks | jq '.networks[] | select(.name=="project1-private")' | jq -r '.id' )

# 创建 instance
echo "CREATESERVER"
curl -g -i -X POST https://overcloud.example.com:13774/v2.1/servers \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "X-Auth-Token: $mytoken" -d "{\"server\": {\"name\": \"test-instance\", \"imageRef\": \"$imageid\", \"flavorRef\": \"$flavorid\", \"min_count\": 1, \"max_count\": 1, \"networks\": [{\"uuid\": \"$networkid\"}]}}"

# 获取 instanceid
echo "GET INSTANCEID"
instanceid=$(curl -s \
-H "Accept: application/json" \
--header "X-Auth-Token: $mytoken" \
-X GET https://overcloud.example.com:13774/v2.1/servers | jq '.servers[] | select(.name=="test-instance")' | jq -r '.id' )

# 删除 instance 
echo "DELETE INSTANCE"
curl -s \
-H "Accept: application/json" \
--header "X-Auth-Token: $mytoken" \
-X DELETE https://overcloud.example.com:13774/v2.1/servers/${instanceid}

```