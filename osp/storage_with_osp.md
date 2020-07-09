# day1


# day2

# day3

# day4

rbd mirror lab
file:///Users/junwang/Downloads/18_rbd_mirroring_Lab.html


```
cd /usr/share/ceph-ansible

cat > hosts << 'EOF'
[mons]
ceph-node0[1:3]

[mgrs]
ceph-node0[1:3]

[osds]
ceph-node0[1:3]

[grafana-server]
proxy01
EOF

cat > group_vars/all.yml << 'EOF'
---
###
# General Options
###
cluster: ceph
fetch_directory: /usr/share/ceph-ansible/ceph-ansible-keys
ntp_service_enabled: true
alertmanager_container_image: registry.redhat.io/openshift4/ose-prometheus-alertmanager:4.1
ceph_docker_image: rhceph/rhceph-4-rhel8
ceph_docker_image_tag: latest
ceph_docker_registry: registry.redhat.io
ceph_docker_registry_auth: true
ceph_docker_registry_password: eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJlNDNjZWU1NTdjMTM0MWNmODlmYWE5YmFiMjg1MjA3YiJ9.adlQiqx7qcHMZsNgiv8nQ3j40K1S_GvMK_WR2nUgwWBowgTrm-O1Z6JGhZF9cLqVR0chHhjP8zT8uCT6j8VQk_-nLesgldb4SXuipf6nsnKs8Tz5--RrtiQxNq4L7ythdPpCoxbRc8TIBLzgB6aMAjCrNk-GmrFoUJjLWyz2UYipOJ5nkl_NP9lcTuYd2Xw-vyk2_5NylBm6vZNqwyDTRvOBO0C4hOadvzMQALHK3HdjpqJoxd8zEjPhgkL3a1I9i6p5kZoATtJl0hkrNzluRT49UiALGO7xBYEq6atvd2F6iUZJSEYEjmqgAQQiAsI-evszoi81J4aFeaAmDCqn9API70e6hzFUM-UrQEsJPLFcrGa3spT5OPOXddVtjJrqYq5-YzOx2-GIX9e8ZNUux11wz5qrBb3H2kWt57NuskZS8jkjlq3fzZqxK03aPOkkS_Wp4cO8eBwLlg3r70gKELmXoLlYAfvK0CODieXQ-Dx_705FZck6Rs0eqAkp2tu3YWujbnw4w3WiiZoyPjJb1bkgBCWz8rgwDpE4g4YyPLxtKQ-KChT4Zi2LJiNCtnzR8mVwdq71lwO1Fu4QDfnwHt8QgFhVbCX3YdbS7Hd7Mtq8Xss_iU9yTJ4FvHnjL5uraJlkVUwv_Rzz8pxfEDKhgA9wc3FME31g5iHAe8QcUJo
ceph_docker_registry_username: 6747835|asosp
ceph_origin: repository
ceph_repository: rhcs
ceph_repository_type: cdn
ceph_rhcs_version: 4
cluster_network: 192.168.56.0/24
containerized_deployment: true
dashboard_enabled: true
dashboard_admin_password: dashboard12
docker_pull_timeout: 600s
grafana_container_image: registry.redhat.io/rhceph/rhceph-3-dashboard-rhel7:3
ip_version: ipv4
monitor_address_block: 192.168.56.0/24
node_exporter_container_image: registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.1
prometheus_container_image: registry.redhat.io/openshift4/ose-prometheus:4.1
public_network: 192.168.56.0/24

###
# Ceph Configuration Overrides
###
ceph_conf_overrides:
  global:
    mon_osd_allow_primary_afinity: true
    osd_pool_default_size: 2
    osd_pool_default_min_size: 1
    mon_pg_warn_min_per_osd: 0
    mon_pg_warn_max_per_osd: 0
    mon_pg_warn_max_object_skew: 0
    osd_pool_default_pg_num: 8
  client:
    rbd_default_features: 1
    rbd_default_format: 2

###
# Client Options
###
rbd_cache: "true"
rbd_cache_writethrough_until_flush: "false"
EOF

mkdir -p /usr/share/ceph-ansible/ceph-ansible-keys

cat > group_vars/osds.yml << 'EOF'
---

copy_admin_key: true

devices:
  - /dev/vdb
  - /dev/vdc
  - /dev/vdd
EOF

cp site-docker.yml.sample site-docker.yml

ansible-playbook -i hosts site-docker.yml

ssh root@ceph-node03 "podman exec -it ceph-osd-0 ceph -s "
```

```
cd /usr/share/ceph-ansible

cat > hosts << 'EOF'
[mons]
ceph-mon0[1:3]

[mgrs]
ceph-mon0[1:3]

[osds]
ceph-mon0[1:3]

[grafana-server]
haproxy01
EOF

cat > group_vars/all.yml << 'EOF'
---
###
# General Options
###
cluster: ceph-remote
fetch_directory: /usr/share/ceph-ansible/ceph-ansible-keys
ntp_service_enabled: true
alertmanager_container_image: registry.redhat.io/openshift4/ose-prometheus-alertmanager:4.1
ceph_docker_image: rhceph/rhceph-4-rhel8
ceph_docker_image_tag: latest
ceph_docker_registry: registry.redhat.io
ceph_docker_registry_auth: true
ceph_docker_registry_password: eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJlNDNjZWU1NTdjMTM0MWNmODlmYWE5YmFiMjg1MjA3YiJ9.adlQiqx7qcHMZsNgiv8nQ3j40K1S_GvMK_WR2nUgwWBowgTrm-O1Z6JGhZF9cLqVR0chHhjP8zT8uCT6j8VQk_-nLesgldb4SXuipf6nsnKs8Tz5--RrtiQxNq4L7ythdPpCoxbRc8TIBLzgB6aMAjCrNk-GmrFoUJjLWyz2UYipOJ5nkl_NP9lcTuYd2Xw-vyk2_5NylBm6vZNqwyDTRvOBO0C4hOadvzMQALHK3HdjpqJoxd8zEjPhgkL3a1I9i6p5kZoATtJl0hkrNzluRT49UiALGO7xBYEq6atvd2F6iUZJSEYEjmqgAQQiAsI-evszoi81J4aFeaAmDCqn9API70e6hzFUM-UrQEsJPLFcrGa3spT5OPOXddVtjJrqYq5-YzOx2-GIX9e8ZNUux11wz5qrBb3H2kWt57NuskZS8jkjlq3fzZqxK03aPOkkS_Wp4cO8eBwLlg3r70gKELmXoLlYAfvK0CODieXQ-Dx_705FZck6Rs0eqAkp2tu3YWujbnw4w3WiiZoyPjJb1bkgBCWz8rgwDpE4g4YyPLxtKQ-KChT4Zi2LJiNCtnzR8mVwdq71lwO1Fu4QDfnwHt8QgFhVbCX3YdbS7Hd7Mtq8Xss_iU9yTJ4FvHnjL5uraJlkVUwv_Rzz8pxfEDKhgA9wc3FME31g5iHAe8QcUJo
ceph_docker_registry_username: 6747835|asosp
ceph_origin: repository
ceph_repository: rhcs
ceph_repository_type: cdn
ceph_rhcs_version: 4
cluster_network: 192.168.56.0/24
containerized_deployment: true
dashboard_enabled: true
dashboard_admin_password: dashboard12
docker_pull_timeout: 600s
grafana_container_image: registry.redhat.io/rhceph/rhceph-3-dashboard-rhel7:3
ip_version: ipv4
monitor_address_block: 192.168.56.0/24
node_exporter_container_image: registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.1
prometheus_container_image: registry.redhat.io/openshift4/ose-prometheus:4.1
public_network: 192.168.56.0/24

###
# Ceph Configuration Overrides
###
ceph_conf_overrides:
  global:
    mon_osd_allow_primary_afinity: true
    osd_pool_default_size: 2
    osd_pool_default_min_size: 1
    mon_pg_warn_min_per_osd: 0
    mon_pg_warn_max_per_osd: 0
    mon_pg_warn_max_object_skew: 0
    osd_pool_default_pg_num: 8
  client:
    rbd_default_features: 1
    rbd_default_format: 2

###
# Client Options
###
rbd_cache: "true"
rbd_cache_writethrough_until_flush: "false"
EOF

cat > group_vars/osds.yml << 'EOF'
---

copy_admin_key: true

devices:
  - /dev/vdb
EOF

cp site-docker.yml.sample site-docker.yml

ansible-playbook -i hosts site-docker.yml
```

```
cd /usr/share/ceph-ansible

cat > hosts << 'EOF'
[mons]
ceph-mon0[1:3]

[mgrs]
ceph-mon0[1:3]

[osds]
ceph-mon0[1:3]

[grafana-server]
haproxy01
EOF

cat > group_vars/all.yml << 'EOF'
---
###
# General Options
###
cluster: ceph-remote
fetch_directory: /usr/share/ceph-ansible/ceph-ansible-keys
ntp_service_enabled: true
alertmanager_container_image: registry.redhat.io/openshift4/ose-prometheus-alertmanager:4.1
ceph_docker_image: rhceph/rhceph-4-rhel8
ceph_docker_image_tag: latest
ceph_docker_registry: registry.redhat.io
ceph_docker_registry_auth: true
ceph_docker_registry_password: eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJlNDNjZWU1NTdjMTM0MWNmODlmYWE5YmFiMjg1MjA3YiJ9.adlQiqx7qcHMZsNgiv8nQ3j40K1S_GvMK_WR2nUgwWBowgTrm-O1Z6JGhZF9cLqVR0chHhjP8zT8uCT6j8VQk_-nLesgldb4SXuipf6nsnKs8Tz5--RrtiQxNq4L7ythdPpCoxbRc8TIBLzgB6aMAjCrNk-GmrFoUJjLWyz2UYipOJ5nkl_NP9lcTuYd2Xw-vyk2_5NylBm6vZNqwyDTRvOBO0C4hOadvzMQALHK3HdjpqJoxd8zEjPhgkL3a1I9i6p5kZoATtJl0hkrNzluRT49UiALGO7xBYEq6atvd2F6iUZJSEYEjmqgAQQiAsI-evszoi81J4aFeaAmDCqn9API70e6hzFUM-UrQEsJPLFcrGa3spT5OPOXddVtjJrqYq5-YzOx2-GIX9e8ZNUux11wz5qrBb3H2kWt57NuskZS8jkjlq3fzZqxK03aPOkkS_Wp4cO8eBwLlg3r70gKELmXoLlYAfvK0CODieXQ-Dx_705FZck6Rs0eqAkp2tu3YWujbnw4w3WiiZoyPjJb1bkgBCWz8rgwDpE4g4YyPLxtKQ-KChT4Zi2LJiNCtnzR8mVwdq71lwO1Fu4QDfnwHt8QgFhVbCX3YdbS7Hd7Mtq8Xss_iU9yTJ4FvHnjL5uraJlkVUwv_Rzz8pxfEDKhgA9wc3FME31g5iHAe8QcUJo
ceph_docker_registry_username: 6747835|asosp
ceph_origin: repository
ceph_repository: rhcs
ceph_repository_type: cdn
ceph_rhcs_version: 4
cluster_network: 192.168.56.0/24
containerized_deployment: true
dashboard_enabled: true
dashboard_admin_password: dashboard12
docker_pull_timeout: 600s
grafana_container_image: registry.redhat.io/rhceph/rhceph-3-dashboard-rhel7:3
ip_version: ipv4
monitor_address_block: 192.168.56.0/24
node_exporter_container_image: registry.redhat.io/openshift4/ose-prometheus-node-exporter:v4.1
prometheus_container_image: registry.redhat.io/openshift4/ose-prometheus:4.1
public_network: 192.168.56.0/24

###
# Ceph Configuration Overrides
###
ceph_conf_overrides:
  global:
    mon_osd_allow_primary_afinity: true
    osd_pool_default_size: 2
    osd_pool_default_min_size: 1
    mon_pg_warn_min_per_osd: 0
    mon_pg_warn_max_per_osd: 0
    mon_pg_warn_max_object_skew: 0
    osd_pool_default_pg_num: 8
  client:
    rbd_default_features: 1
    rbd_default_format: 2

###
# Client Options
###
rbd_cache: "true"
rbd_cache_writethrough_until_flush: "false"
EOF

cat > group_vars/osds.yml << 'EOF'
---

copy_admin_key: true

devices:
  - /dev/vdb
EOF

cp site-docker.yml.sample site-docker.yml

ansible-playbook -i hosts site-docker.yml

ceph --cluster ceph-remote -s 


```

# day5


