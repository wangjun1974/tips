```
# save blueprints 
composer-cli blueprints save blueprint_test_rhel_for_edge

cat blueprint_test_rhel_for_edge.toml 
name = "blueprint_test_rhel_for_edge"
description = "blueprint test rhel for edge"
version = "0.0.0"
packages = []
modules = []
groups = []

# update blueprints 
cat > blueprint_test_rhel_for_edge.toml <<EOF
name = "blueprint_test_rhel_for_edge"
description = "blueprint test rhel for edge"
version = "0.0.1"
modules = []
groups = []

[[packages]]
name = "bash"
version = "*"

[[packages]]
name = "podman"
version = "*"
EOF

# push blueprints
composer-cli blueprints push blueprint_test_rhel_for_edge.toml

# check blueprints changes
composer-cli blueprints changes blueprint_test_rhel_for_edge

blueprint_test_rhel_for_edge
    2020-11-27T05:22:36Z  6da785c8e1ac2baade0446fc3b6901d62bae65ae
    Recipe blueprint_test_rhel_for_edge, version 0.0.1 saved.

    2020-11-26T08:08:47Z  866d0118eb95711ad7b7e1742d5b9393cd73b54f
    Recipe blueprint_test_rhel_for_edge, version  saved.

# update blueprints，add user admin into blueprints and change version 

cat > blueprint_test_rhel_for_edge.toml <<EOF
name = "blueprint_test_rhel_for_edge"
description = "blueprint test rhel for edge"
version = "0.0.2"
modules = []
groups = []

[[packages]]
name = "bash"
version = "*"

[[packages]]
name = "podman"
version = "*"

[[customizations.user]]
name = "admin"
description = "admin"
password = "$6$PUNf5x.lEchI551u$WKDecMqirPipvFHivMtyw/bys6CUwZeWAl9m819/APhCgNuDaHn06sRgQp5956z5cjh73shU2WsbXZQx68yX//"
home = "/home/admin/"
groups = ["wheel"]
EOF

# push blueprints
composer-cli blueprints push blueprint_test_rhel_for_edge.toml

# check blueprints changes
composer-cli blueprints changes blueprint_test_rhel_for_edge

# subscribe aws ec2 instance to Red Hat 
subscription-manager register
subscription-manager attach --auto

# disable aws rhui repo and epel 
yum-config-manager --disable rhui-client-config-server-8
yum-config-manager --disable rhel-8-baseos-rhui-rpms
yum-config-manager --disable rhel-8-appstream-rhui-rpms
yum-config-manager --disable epel
yum-config-manager --disable epel-modular

# compose image
composer-cli compose start blueprint_test_rhel_for_edge rhel-edge-commit
2020-11-27 05:52:34,467: RHSM secrets not found on host
```