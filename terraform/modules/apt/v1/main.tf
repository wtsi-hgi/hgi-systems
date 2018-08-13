variable "env" {}
variable "region" {}
variable "setup" {}

variable "core_context" {
  type    = "map"
  default = {}
}

variable "flavour" {}
variable "domain" {}

variable "image" {
  type = "map"
}

variable "volume_size_gb" {
  default = 5000
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
    "aptlys",
    "hgi-credentials",
  ]

  hostname_format = "apt"
}

module "hgi-openstack-instance" {
  source          = "../../hgi-openstack-instance/v2"
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${var.core_context}"
  count           = "1"
  floating_ip_p   = true
  name_format     = "${local.hostname_format}"
  domain          = "${var.domain}"
  flavour         = "${var.flavour}"
  hostname_format = "${local.hostname_format}"
  ssh_gateway     = "${var.ssh_gateway}"
  keypair_name    = "${var.keypair_name}"
  network_name    = "${var.network_name}"
  image           = "${var.image}"
  volume_p        = true
  volume_size_gb  = "${var.volume_size_gb}"

  security_group_names = [
    "ping",
    "ssh",
    "http",
    "https",
  ]

  ansible_groups = "${distinct(concat(local.ansible_groups, var.extra_ansible_groups))}"
}

output "hgi_instances" {
  value = "${module.hgi-openstack-instance.hgi_instance}"
}
