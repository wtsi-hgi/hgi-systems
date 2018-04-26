variable "env" {}
variable "region" {}
variable "setup" {}
variable "mercury_keypair" {}
variable "subnet" {}
variable "gateway_ip" {}
variable "external_network_name" {}

variable "router_count" {
  default = 1
}

variable "dns_nameservers" {
  type    = "list"
  default = []
}

variable "host_routes" {
  type    = "list"
  default = []
}

###############################################################################
# Key Pairs
###############################################################################
resource "openstack_compute_keypair_v2" "mercury" {
  provider   = "openstack"
  name       = "mercury_${var.region}_${var.setup}_${var.env}"
  public_key = "${var.mercury_keypair}"
}

output "key_pair_ids" {
  value = {
    mercury = "${openstack_compute_keypair_v2.mercury.id}"
  }
}

###############################################################################
# Look up external network id from name
###############################################################################
data "openstack_networking_network_v2" "external_network" {
  name = "${var.external_network_name}"
}

###############################################################################
# Configure Networks, Subnets, & Routers
###############################################################################
resource "openstack_networking_network_v2" "main" {
  provider       = "openstack"
  name           = "main_${var.region}_${var.setup}_${var.env}"
  admin_state_up = "true"
}

output "network_id" {
  value      = "${openstack_networking_network_v2.main.id}"
  depends_on = ["${openstack_networking_network_v2.main}"]
}

resource "openstack_networking_subnet_v2" "main" {
  provider        = "openstack"
  name            = "main_${var.region}_${var.setup}_${var.env}"
  network_id      = "${openstack_networking_network_v2.main.id}"
  cidr            = "${var.subnet}"
  ip_version      = 4
  dns_nameservers = "${var.dns_nameservers}"
  host_routes     = "${var.host_routes}"
  gateway_ip      = "${var.gateway_ip}"
}

resource "openstack_networking_router_v2" "main_ext" {
  count               = "${var.router_count}"
  provider            = "openstack"
  name                = "main_ext_${var.region}_${var.setup}_${var.env}"
  external_network_id = "${data.openstack_networking_network_v2.external_network.id}"
}

resource "openstack_networking_router_interface_v2" "main_ext" {
  provider  = "openstack"
  router_id = "${openstack_networking_router_v2.main_ext.id}"
  subnet_id = "${openstack_networking_subnet_v2.main.id}"
}
