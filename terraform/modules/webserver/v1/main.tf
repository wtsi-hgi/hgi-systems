variable "env" {}
variable "region" {}
variable "setup" {}

variable "core_context" {
  type    = "map"
  default = {}
}

variable "count" {}
variable "flavour" {}

variable "hostname_format" {}
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
    "webservers",
  ]
}

module "webserver" {
  source          = "../../hgi-openstack-instance/v1"
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${var.core_context}"
  count           = "${var.count}"
  floating_ip_p   = true
  name_format     = "${var.hostname_format}"
  domain          = "${var.domain}"
  flavour         = "${var.flavour}"
  hostname_format = "${var.hostname_format}"
  ssh_gateway     = "${var.ssh_gateway}"
  keypair_name    = "${var.keypair_name}"
  network_name    = "${var.network_name}"
  image           = "${var.image}"

  security_group_names = [
    "ping",
    "ssh",
    "http",
    "https",
  ]

  ansible_groups = "${distinct(concat(local.ansible_groups, var.extra_ansible_groups))}"
}
