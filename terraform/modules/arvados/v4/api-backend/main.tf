variable "env" {}
variable "region" {}
variable "setup" {}

variable "core_context" {
  type = "map"
}

variable "count" {}
variable "flavour" {}
variable "domain" {}
variable "arvados_cluster_id" {}
variable "consul_datacenter" {}

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
    "arvados-api-backends",
    "docker-consul-agents",
    "hgi-credentials",
    "arvados-cluster-${var.arvados_cluster_id}",
    "docker-consul-cluster-${var.consul_datacenter}",
  ]

  security_group_names = [
    "ping",
    "ssh",
    "https",
    "consul-client",
    "slurm-master",
    "tcp-local",
    "udp-local",
  ]

  hostname_format = "arvados-api-backend-${var.arvados_cluster_id}-%02d"
}

module "hgi-openstack-instance" {
  source          = "../../../hgi-openstack-instance/v1"
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${var.core_context}"
  count           = "${var.count}"
  floating_ip_p   = false
  name_format     = "${local.hostname_format}"
  hostname_format = "${local.hostname_format}"
  domain          = "${var.domain}"
  flavour         = "${var.flavour}"
  ssh_gateway     = "${var.ssh_gateway}"
  keypair_name    = "${var.keypair_name}"
  network_name    = "${var.network_name}"
  image           = "${var.image}"

  security_group_names = "${local.security_group_names}"

  ansible_groups = "${distinct(concat(local.ansible_groups, var.extra_ansible_groups))}"
}

output "hgi_instance" {
  value = "${module.hgi-openstack-instance.hgi_instance}"
}
