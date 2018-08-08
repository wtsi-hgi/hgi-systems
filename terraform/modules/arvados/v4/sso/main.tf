variable "env" {}
variable "region" {}
variable "setup" {}

variable "core_context" {
  type = "map"
}

variable "flavour" {}
variable "domain" {}
variable "arvados_cluster_id" {}
variable "consul_datacenter" {}

variable "volume_size_gb" {
  default = 10
}

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
    "arvados-ssos",
    "arvados-cluster-${var.arvados_cluster_id}",
    "docker-consul-agents",
    "docker-consul-cluster-${var.consul_datacenter}",
    "hgi-credentials",
  ]

  hostname_format = "arvados-sso-${var.arvados_cluster_id}"
}

module "hgi-openstack-instance" {
  source          = "../../../hgi-openstack-instance/v1"
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${var.core_context}"
  floating_ip_p   = true
  volume_p        = true
  volume_size_gb  = "${var.volume_size_gb}"
  count           = 1
  name_format     = "${local.hostname_format}"
  hostname_format = "${local.hostname_format}"
  domain          = "${var.domain}"
  flavour         = "${var.flavour}"
  ssh_gateway     = "${var.ssh_gateway}"
  keypair_name    = "${var.keypair_name}"
  network_name    = "${var.network_name}"
  image           = "${var.image}"

  security_group_names = [
    "ping",
    "ssh",
    "https",
    "consul-client",
    "netdata",
  ]

  ansible_groups = "${distinct(concat(local.ansible_groups, var.extra_ansible_groups))}"

  additional_dns_names = []
}

output "hgi_instance" {
  value = "${module.hgi-openstack-instance.hgi_instance}"
}
