
### setup network
```
nmcli con mod 'eth0' ipv4.method 'manual' ipv4.address '10.66.xxx.xxx/24' ipv4.gateway '10.66.xxx.xxx' ipv4.dns '127.0.0.1 10.xx.xx.xx' ipv4.dns-search 'cluster-0001.rhsacn.org'
nmcli con down 'eth0' && nmcli con up 'eth0'

hostnamectl set-hostname helper.cluster-0001.rhcnsa.org

sed -i '/^10.66.xxx.xxx helper.cluster-0001.rhsacn.org*/d' /etc/hosts

cat >> /etc/hosts << 'EOF'
10.66.xxx.xxx helper.cluster-0001.rhsacn.org
EOF
```

### setup repo
```
mkdir -p /etc/yum.repos.d/backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup

cat > /etc/yum.repos.d/w.repo << 'EOF'
[rhel-7-server-rpms]
name=rhel-7-server-rpms
baseurl=http://10.66.xxx.xxx/rhel7osp/rhel-7-server-rpms/
enabled=1
gpgcheck=0

[rhel-7-server-extras-rpms]
name=rhel-7-server-extras-rpms
baseurl=http://10.66.xxx.xxx/rhel7osp/rhel-7-server-extras-rpms/
enabled=1
gpgcheck=0


[rhel-7-server-ansible-2.9-rpms]
name=rhel-7-server-ansible-2.9-rpms
baseurl=http://10.66.xxx.xxx/rhel9osp/rhel-7-server-ansible-2.9-rpms/
enabled=1
gpgcheck=0

EOF
```

### update system and reboot
```
yum -y update 
reboot
```

### setup time service
```
cat > /etc/chrony.conf << 'EOF'
server 127.127.1.0 iburst
allow all
local stratum 4
EOF

systemctl enable chronyd && systemctl start chronyd 

chronyc -n sources
chronyc -n tracking

systemctl enable firewalld && systemctl start firewalld

firewall-cmd --permanent --add-service ntp
firewall-cmd --reload
```

### setup helper node
```
yum -y install ansible git
git clone https://github.com/RedHatOfficial/ocp4-helpernode
cd ocp4-helpernode
```

#### generate vars.yml
```
cat > vars.yml << EOF
---
staticips: true
helper:
  name: "helper"
  ipaddr: "10.66.208.138"
  networkifacename: "eth0"
dns:
  domain: "rhsacn.org"
  clusterid: "cluster-0001"
  forwarder1: "10.64.63.6"
bootstrap:
  name: "bootstrap"
  ipaddr: "10.66.208.139"
masters:
  - name: "master0"
    ipaddr: "10.66.208.140"
workers:
  - name: "worker0"
    ipaddr: "10.66.208.143"
  - name: "worker1"
    ipaddr: "10.66.208.144"
EOF

ansible-playbook -e @vars.yaml tasks/main.yml
```

#### disconnected env change ignore_errors to yes (optional)
```
cat tasks/main.yml | sed '/^- hosts: all/, /vars_files/ {/^- hosts: all/!{/vars_files/!d;};}' | sed '/^- hosts: all/a  \ \ ignore_errors: yes' | tee tasks/mail.yml.new

mv -f tasks/mail.yml.new tasks/main.yml
```

#### check status
```
helpernodecheck dns-masters
helpernodecheck dns-workers
helpernodecheck dns-etcd
helpernodecheck install-info
helpernodecheck haproxy
helpernodecheck services
helpernodecheck nfs-info
```

### create helper node registry
```
yum -y install podman httpd httpd-tools wget jq

mkdir -p /opt/registry/{auth,certs,data}

cd /opt/registry/certs

openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 3650 -out domain.crt  -subj "/C=CN/ST=GD/L=SZ/O=Global Security/OU=IT Department/CN=*.cluster-0001.rhsacn.org"

cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

htpasswd -bBc /opt/registry/auth/htpasswd dummy dummy

firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public   --permanent
firewall-cmd --add-service=http  --permanent
firewall-cmd --reload

cat > /usr/local/bin/localregistry.sh << 'EOF'
#!/bin/bash
podman run --name poc-registry -d -p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/auth:/auth:z \
-e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry" \
-e "REGISTRY_HTTP_SECRET=ALongRandomSecretForRegistry" \
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
-v /opt/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
docker.io/library/registry:2 
EOF

chmod +x /usr/local/bin/localregistry.sh

/usr/local/bin/localregistry.sh

curl -u dummy:dummy -k https://helper.cluster-0001.rhsacn.org:5000/v2/_catalog

REPO_URL=helper.cluster-0001.rhsacn.org:5000
curl -u dummy:dummy -s -X GET https://$REPO_URL/v2/_catalog \
 | jq '.repositories[]' \
 | sort \
 | xargs -I _ curl -u dummy:dummy -s -X GET https://$REPO_URL/v2/_/tags/list

```

### prepare artifacts
```
export BUILDNUMBER=$(curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.5.0/release.txt | grep 'Name:' | awk '{print $NF}')
echo ${BUILDNUMBER}

wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${BUILDNUMBER}/openshift-client-linux-${BUILDNUMBER}.tar.gz -P /var/www/html/
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${BUILDNUMBER}/openshift-install-linux-${BUILDNUMBER}.tar.gz -P /var/www/html/

tar -xzf /var/www/html/openshift-client-linux-${BUILDNUMBER}.tar.gz -C /usr/local/bin/
tar -xzf /var/www/html/openshift-install-linux-${BUILDNUMBER}.tar.gz -C /usr/local/bin/

# download bios and iso
MAJORBUILDNUMBER=4.5
EXTRABUILDNUMBER=4.5.6
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${MAJORBUILDNUMBER}/${EXTRABUILDNUMBER}/rhcos-${EXTRABUILDNUMBER}-x86_64-installer.x86_64.iso -P /var/www/html/
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${MAJORBUILDNUMBER}/${EXTRABUILDNUMBER}/rhcos-${EXTRABUILDNUMBER}-x86_64-metal.x86_64.raw.gz -P /var/www/html/

# Get pull secret
wget http://10.66.208.115/rhel9osp/pull-secret.json -P /root
jq '.auths += {"helper.cluster-0001.rhsacn.org:5000": {"auth": "ZHVtbXk6ZHVtbXk=","email": "noemail@localhost"}}' < /root/pull-secret.json > /root/pull-secret-2.json

# login registries
podman login -u wang.jun.1974 -p ****** registry.redhat.io
podman login -u wang.jun.1974 -p ****** registry.access.redhat.com
podman login -u wang.jun.1974 -p ****** registry.connect.redhat.com

# setup env and record imageContentSources section from output
# see: https://docs.openshift.com/container-platform/4.5/installing/install_config/installing-restricted-networks-preparations.html
export OCP_RELEASE="4.5.13"
export LOCAL_REGISTRY='helper.cluster-0001.rhsacn.org:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON="${HOME}/pull-secret-2.json"
export RELEASE_NAME='ocp-release'
export ARCHITECTURE="x86_64"
export REMOVABLE_MEDIA_PATH='/opt/registry'

oc adm -a ${LOCAL_SECRET_JSON} release mirror \
--from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} --dry-run

# mirror to local registry
oc adm -a ${LOCAL_SECRET_JSON} release mirror \
--from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} 

# mirror to local directory (optional)
oc adm release mirror -a ${LOCAL_SECRET_JSON} --to-dir=${REMOVABLE_MEDIA_PATH}/mirror quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE}

...
sha256:3e9704e62bb8ebaba3e9cda8176fa53de7b4e7e63b067eb94522bf6e5e93d4ea file://openshift/release:4.5.13-cluster-network-operator
info: Mirroring completed in 20ms (0B/s)

Success
Update image:  openshift/release:4.5.13

To upload local images to a registry, run:

    oc image mirror --from-dir=/opt/registry/mirror 'file://openshift/release:4.5.13*' REGISTRY/REPOSITORY

Configmap signature file /opt/registry/mirror/config/signature-sha256-8d104847fc2371a9.yaml created

# Take the media to the restricted network environment and upload the images to the local container registry.
oc image mirror -a ${LOCAL_SECRET_JSON} --from-dir=${REMOVABLE_MEDIA_PATH}/mirror "file://openshift/release:${OCP_RELEASE}*" ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}

# catalog build need use 
# targetfile='./redhat-operators-manifests/mapping.tag.txt'
# cat $targetfile | while read line ;do echo ${line%=*};skopeo copy --format v2s2 --all docker://${line%=*} docker://${line#*=}; done


OPERATOR_OCP_RELEASE="4.5"
oc adm catalog build \
  --appregistry-org redhat-operators \
  --from=registry.redhat.io/openshift4/ose-operator-registry:v${OPERATOR_OCP_RELEASE} \
  --filter-by-os='linux/amd64' \
  -a ${LOCAL_SECRET_JSON} \
  --to=${LOCAL_REGISTRY}/olm/redhat-operators:v${OPERATOR_OCP_RELEASE}

oc adm catalog mirror \
  ${LOCAL_REGISTRY}/olm/redhat-operators:v${OPERATOR_OCP_RELEASE} \
  ${LOCAL_REGISTRY} \
  -a ${LOCAL_SECRET_JSON} \
  --filter-by-os='linux/amd64'

# ToDo: I could not go through this process ... (optional)
# copy catalog relate content into disconnect env
# 1. $oc adm catalog build --appregistry-org redhat-operators --from=registry.redhat.io/openshift4/ose-operator-registry:vXX  --dir=<YOUR_DIR> --to=file://offline/redhat-operators:vXX
# 2. $oc adm catalog mirror --manifests-only=true --from-dir=<YOUR_DIR> file://offline/redhat-operators:vXX localhost
# 3. $sed 's/=/=file:\/\//g' redhat-operators-manifests/mapping.txt > mapping-new.txt
# 4. $oc image mirror  -f mappings-new.txt --dir=<YOUR_DIR>
export OPERATOR_OCP_RELEASE="4.5"
oc adm catalog build \
  --appregistry-org redhat-operators \
  --from=registry.redhat.io/openshift4/ose-operator-registry:v${OPERATOR_OCP_RELEASE} \
  --filter-by-os='linux/amd64' \
  -a ${LOCAL_SECRET_JSON} \
  --dir=${REMOVABLE_MEDIA_PATH} \
  --to-db=file:///offline/redhat-operators:v1
 
oc adm catalog mirror \
  --manifests-only=true \
  --from-dir=${REMOVABLE_MEDIA_PATH} file://offline/redhat-operators:v${OPERATOR_OCP_RELEASE} \
  ${LOCAL_REGISTRY} \
  -a ${LOCAL_SECRET_JSON} \
  --filter-by-os='linux/amd64' 

# install install directory
mkdir -p /root/ocp4
cd /root/ocp4

cat > install-config.yaml.orig << 'EOF'
apiVersion: v1
baseDomain: rhcnsa.com
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 2
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 1
metadata:
  name: ocp4
networking:
  clusterNetworks:
  - cidr: 10.254.0.0/16
    hostPrefix: 24
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '{"auths":{"helper.cluster-0001.rhcnsa.com:5000": {"auth": "ZHVtbXk6ZHVtbXk=","email": "noemail@localhost"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxT6A/FrkwtkAGJPUHsbAKqURvdRxOOoWF71dle7Or7OZkRUO2w0Dmc8D0PrWe16dLLw5Kg0SwtU/76ljDkhZDl/WGGMRzvWnypSzL/gGzWsg6IOwmqOdgMpAAa3K/f3MxaAX0tNaqEhb2flfjMUjymzKvI7/z6XbvfWryO+s1VcXZgOLMAwJMmgTtME174kixCNHfZpIqZbNS5byXlpPHQRKV+Ra1VDnz3WElg+TkhyYxRz6JA7FoHXkXbDgU0xc1TisLhadQHXVonkpXCp2OinT/J/j4y/DkTyjNHw9sBAvSf9GXthhyiCUk7pmbfJx89CEa2HtBKk0KOnJ57kgh root@cluster-0001-helper.rhcnsa.org'
additionalTrustBundle: |
  -----BEGIN CERTIFICATE-----
  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
  dA==
  -----END CERTIFICATE-----
  imageContentSources:
- mirrors:
  - helper.cluster-0001.rhcnsa.org:5000/ocp-release
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - helper.cluster-0001.rhcnsa.org:5000/ocp-release
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

cp install-config.yaml.orig /var/www/html
cp /var/www/html/install-config.yaml.orig install-config.yaml

ssh-keygen -t rsa -f ~/.ssh/id_rsa -N '' 

cat > install-config.yaml.orig << EOF
apiVersion: v1
baseDomain: rhcnsa.com
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 2
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 1
metadata:
  name: ocp4
networking:
  clusterNetworks:
  - cidr: 10.254.0.0/16
    hostPrefix: 24
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '{"auths":{"helper.cluster-0001.rhcnsa.com:5000": {"auth": "ZHVtbXk6ZHVtbXk=","email": "noemail@localhost"}}}'
sshKey: |
$( cat /root/.ssh/id_rsa.pub | sed 's/^/   /g' )
additionalTrustBundle: |
$( cat /etc/pki/ca-trust/source/anchors/domain.crt | sed 's/^/   /g' )
imageContentSources:
- mirrors:
  - helper.cluster-0001.rhcnsa.org:5000/ocp-release
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - helper.cluster-0001.rhcnsa.org:5000/ocp-release
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF

cp install-config.yaml.orig /var/www/html
cp /var/www/html/install-config.yaml.orig install-config.yaml

```
