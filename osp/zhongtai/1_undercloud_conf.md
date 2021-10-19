### undercloud.conf 参数说明

|**Default**|参数说明|
|---|---|
|undercloud_hostname|Hostname for director’s undercloud node|
|container_images_file|Heat environment file with container image information. This can either be:<br>* Parameters for all required container images<br>* Or the ContainerImagePrepare parameter to drive the required image preparation. Usually the file containing this parameter is named containers-prepare-parameter.yaml.|
|undercloud_public_host|Hostname or IP address defined for undercloud public API|
|undercloud_admin_host|Hostname or IP address defined for director’s administrative API|
|undercloud_nameservers|DNS nameservers to be used by undercloud|
|local_ip|IP address for director’s provisioning NIC|
|subnets|List of routed network subnets for provisioning and introspection, default value only includes ctlplane-subnet subnet|
|local_subnet|Local subnet to use for PXE boot and DHCP interfaces, local_ip address should reside in this subnet, default is ctlplane-subnet|
|undercloud_service_certificate|File name of the certificate for OpenStack SSL/TLS communication|
|generate_service_certificate|If true, configure SSL service certificates|
|certificate_generation_ca|certmonger nickname of CA that signs requested certificate|
|local_interface|Chosen interface for director’s provisioning NIC|
|inspection_interface|Bridge that director uses for node introspection|
|inspection_extras|Defines whether to enable extra hardware collection during inspection process|
|inspection_runbench|Defines whether to enable benchmarking during node introspection|
|enable_node_discovery|Enables auto-discovery of bare-metal nodes|
|discovery_default_driver|Defines default driver used in auto-discovery mode|
|undercloud_debug|Sets log level of undercloud services|
|enable_tempest|Defines whether to install Tempest validation tools|
|enable_telemetry|Defines whether to install OpenStack Telemetry services in undercloud|
|enable_ui|Defines whether to install director’s web UI|
|enable_validations|Defines whether to install tools to run validations|
|ipxe_enabled|Defines whether to use iPXE or standard PXE|
|enable_routed_networks|Enable support for routed control plane networks|
|**Subnet参数**||
|cidr|Network that director uses to manage overcloud instances|
|dhcp_start, dhcp_end|Start and end of DHCP allocation range for overcloud nodes|
|gateway|Gateway IP for overcloud nodes|
|inspection_iprange|Range of IP address that director’s introspection service uses during PXE boot and provisioning process|
|masquerade|Defines if subnet needs to be masqueraded for external access|




