variable "env" {}
variable "region" {}
variable "setup" {}

variable "core_context" {
  type    = "map"
  default = {}
}

variable "count" {}
variable "master_flavour" {}

variable "router_flavour" {}
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
  router_ansible_groups = [
    "webhook-routers",
  ]

  master_ansible_groups = [
    "webhook-masters",
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

  ansible_groups = "${distinct(concat(local.router_ansible_groups, var.extra_ansible_groups))}"
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

  ansible_groups = "${distinct(concat(local.master_ansible_groups, var.extra_ansible_groups))}"
}
