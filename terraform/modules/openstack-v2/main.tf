variable "env" {}
variable "region" {}
variable "setup" {}
variable "mercury_keypair" {}
variable "subnet" {}
variable "gateway_ip" {}
variable "external_network_name" {}
variable "floatingip_pool_name" {}

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

locals {
  keypairs = {
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

locals {
  networks = {
    main = "${openstack_networking_network_v2.main.id}"
  }

  subnets = {
    main = "${openstack_networking_subnet_v2.main.id}"
  }
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

resource "openstack_networking_router_v2" "main_ext_cog12" {
  count               = "${var.router_count}"
  provider            = "openstack"
  name                = "main_ext_cog12_${var.region}_${var.setup}_${var.env}"
  external_network_id = "${data.openstack_networking_network_v2.external_network.id}"
}

resource "openstack_networking_router_interface_v2" "main_ext_cog12" {
  provider  = "openstack"
  router_id = "${openstack_networking_router_v2.main_ext_cog12.id}"
  port_id   = "${openstack_networking_port_v2.main_ext_cog12.id}"
}

resource "openstack_networking_port_v2" "main_ext_cog12" {
  name               = "main_ext_cog12_${var.region}_${var.setup}_${var.env}"
  admin_state_up     = "true"
  network_id         = "${openstack_networking_network_v2.main.id}"
  no_security_groups = "true"
}

resource "openstack_networking_router_route_v2" "main_ext_cog12" {
  depends_on       = ["openstack_networking_router_interface_v2.main_ext_cog12"]
  router_id        = "${openstack_networking_router_v2.main_ext.id}"
  destination_cidr = "172.27.6.12/32"
  next_hop         = "${openstack_networking_port_v2.main_ext_cog12.all_fixed_ips[0]}"
}

resource "openstack_networking_router_v2" "main_ext_cog15" {
  count               = "${var.router_count}"
  provider            = "openstack"
  name                = "main_ext_cog15_${var.region}_${var.setup}_${var.env}"
  external_network_id = "${data.openstack_networking_network_v2.external_network.id}"
}

resource "openstack_networking_router_interface_v2" "main_ext_cog15" {
  provider  = "openstack"
  router_id = "${openstack_networking_router_v2.main_ext_cog15.id}"
  port_id   = "${openstack_networking_port_v2.main_ext_cog15.id}"
}

resource "openstack_networking_port_v2" "main_ext_cog15" {
  name               = "main_ext_cog15_${var.region}_${var.setup}_${var.env}"
  admin_state_up     = "true"
  network_id         = "${openstack_networking_network_v2.main.id}"
  no_security_groups = "true"
}

resource "openstack_networking_router_route_v2" "main_ext_cog15" {
  depends_on       = ["openstack_networking_router_interface_v2.main_ext_cog15"]
  router_id        = "${openstack_networking_router_v2.main_ext.id}"
  destination_cidr = "172.27.6.15/32"
  next_hop         = "${openstack_networking_port_v2.main_ext_cog15.all_fixed_ips[0]}"
}

resource "openstack_networking_router_v2" "main_ext_cog18" {
  count               = "${var.router_count}"
  provider            = "openstack"
  name                = "main_ext_cog18_${var.region}_${var.setup}_${var.env}"
  external_network_id = "${data.openstack_networking_network_v2.external_network.id}"
}

resource "openstack_networking_router_interface_v2" "main_ext_cog18" {
  provider  = "openstack"
  router_id = "${openstack_networking_router_v2.main_ext_cog18.id}"
  port_id   = "${openstack_networking_port_v2.main_ext_cog18.id}"
}

resource "openstack_networking_port_v2" "main_ext_cog18" {
  name               = "main_ext_cog18_${var.region}_${var.setup}_${var.env}"
  admin_state_up     = "true"
  network_id         = "${openstack_networking_network_v2.main.id}"
  no_security_groups = "true"
}

resource "openstack_networking_router_route_v2" "main_ext_cog18" {
  depends_on       = ["openstack_networking_router_interface_v2.main_ext_cog18"]
  router_id        = "${openstack_networking_router_v2.main_ext.id}"
  destination_cidr = "172.27.6.18/32"
  next_hop         = "${openstack_networking_port_v2.main_ext_cog18.all_fixed_ips[0]}"
}
