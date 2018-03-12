# provider "openstack" {
#   version     = "~> 1.2"
#   tenant_name = "hgiarvados"
# }

# module "openstack-v2" {
#   source          = "../modules/openstack-v2"
#   env             = "${var.env}"
#   region          = "${var.region}"
#   mercury_keypair = "${var.mercury_keypair}"
#   jr17_keypair    = "${var.jr17_keypair}"
#   subnet          = "10.101.0.0/24"
#   gateway_ip      = "10.101.0.1"
#   dns_nameservers = ["172.18.255.1", "172.18.255.2", "172.18.255.3"]
#   host_routes     = []
# }

# add additional routers to handle RADOS GW traffic
# resource "openstack_networking_router_v2" "radosgw_nova" {
#   count            = 3
#   provider         = "openstack"
#   name             = "radosgw_nova_${var.region}_${var.env}"
#   external_gateway = "9f50f282-2a4c-47da-88f8-c77b6655c7db"
# }

# resource "openstack_networking_router_interface_v2" "radosgw_nova" {
#   provider  = "openstack"
#   router_id = "${openstack_networking_router_v2.radosgw_nova.id}"
#   subnet_id = "${openstack_networking_subnet_v2.main.id}"
# }
