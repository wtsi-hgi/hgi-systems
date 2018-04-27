module "openstack" {
  source                = "../modules/openstack-v2"
  env                   = "${var.env}"
  region                = "${var.region}"
  setup                 = "${var.setup}"
  mercury_keypair       = "${var.mercury_keypair}"
  subnet                = "10.101.0.0/24"
  gateway_ip            = "10.101.0.1"
  dns_nameservers       = ["172.18.255.1", "172.18.255.2", "172.18.255.3"]
  host_routes           = []
  router_count          = 1
  external_network_name = "${var.openstack_external_network_name}"
}

output "core_context" {
  value = "${module.openstack.context}"
}
