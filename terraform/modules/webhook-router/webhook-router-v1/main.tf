variable "env" {}
variable "region" {}
variable "setup" {}

variable "core_context" {
  type    = "map"
  default = {}
}

variable "count" {}
variable "flavour" {}
variable "domain" {}

variable "image" {
  type = "map"
}

variable "network_name" {
  default = "main"
}

variable "keypair_name" {
  default = "mercury"
}

variable "ssh_gateway" {
  type    = "map"
  default = {}
}

variable "extra_ansible_groups" {
  type    = "list"
  default = []
}

locals {
  ansible_groups = [
    "webhook-routers",
  ]

  router_hostname_format = "webhook-router-%02d"
  master_hostname_format = "webhook-master"
}

module "webhook-router" {
  source               = "../../hgi-openstack-instance/v1"
  env                  = "${var.env}"
  region               = "${var.region}"
  setup                = "${var.setup}"
  core_context         = "${var.core_context}"
  count                = "${var.count}"
  floating_ip_p        = true
  name_format          = "${local.router_hostname_format}"
  domain               = "${var.domain}"
  flavour              = "${var.router_flavour}"
  hostname_format      = "${local.router_hostname_format}"
  ssh_gateway          = "${var.ssh_gateway}"
  keypair_name         = "${var.keypair_name}"
  network_name         = "${var.network_name}"
  image                = "${var.image}"
  additional_dns_names = ["webhook-router"]

  security_group_names = [
    "ping",
    "ssh",
    "webhook-router",
  ]

  ansible_groups = "${distinct(concat(local.ansible_groups, var.extra_ansible_groups))}"
}

module "webhook-master" {
  source          = "../../hgi-openstack-instance/v1"
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${var.core_context}"
  count           = 1
  floating_ip_p   = true
  name_format     = "${local.master_hostname_format}"
  domain          = "${var.domain}"
  flavour         = "${var.master_flavour}"
  hostname_format = "${local.master_hostname_format}"
  ssh_gateway     = "${var.ssh_gateway}"
  keypair_name    = "${var.keypair_name}"
  network_name    = "${var.network_name}"
  image           = "${var.image}"

  security_group_names = [
    "ping",
    "ssh",
    "https",
  ]

  ansible_groups = "${distinct(concat(local.ansible_groups, var.extra_ansible_groups))}"
}

output "hgi_instances" {
  value = "${module.hgi-openstack-instance.hgi_instance}"
}
