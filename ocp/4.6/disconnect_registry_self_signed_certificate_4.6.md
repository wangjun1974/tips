### 为离线镜像仓库制作自签名证书 - OCP 4.6
OCP 4.6 的客户端会检查自签名证书，确保证书使用了 subjectAltNames<br>
https://docs.openshift.com/container-platform/4.6/release_notes/ocp-4-6-release-notes.html#ocp-4-6-deprecated-features

制作自签名证书的步骤变为
```
mkdir -p /opt/registry/{auth,certs,data}

cd /opt/registry/certs

# 创建 ssl.conf，包含 subjectAltNames
# 注意：需包含 basicConstraints，
# 否则 update-ca-trust 脚本虽会将此证书添加到
# /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
# 但是不会添加到
# /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
cat > ssl.conf << EOF
[req]
default_bits  = 4096
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
countryName = CN
stateOrProvinceName = BJ
localityName = BJ
organizationName = Global Security
organizationalUnitName = IT Department
commonName = *.cluster-0001.rhsacn.org

[req_ext]
subjectAltName = @alt_names

[v3_req]
subjectAltName = @alt_names

# Key usage: this is typical for a CA certificate. However since it will
# prevent it being used as an test self-signed certificate it is best
# left out by default.
# keyUsage                = critical,keyCertSign,cRLSign

basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash

[alt_names]
DNS.1 = *.cluster-0001.rhsacn.org
EOF

# 使用生成的 ssl.conf 生成证书
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout domain.key -out domain.crt -config ./ssl.conf

# 拷贝证书并且更新证书信任
sudo cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors
sudo update-ca-trust extract

cd ~
 
# 重启 registry
sudo podman stop poc-registry
sudo podman start poc-registry

# 检查使用此证书的 registry 可正常访问
curl -u dummy:dummy https://helper.cluster-0001.rhsacn.org:5000/v2/_catalog

```
