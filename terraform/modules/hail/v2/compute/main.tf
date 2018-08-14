variable "env" {}
variable "region" {}
variable "setup" {}

variable "core_context" {
  type    = "map"
  default = {}
}

variable "hail_cluster_id" {}
variable "count" {}
variable "flavour" {}
variable "domain" {}

variable "volume_size_gb" {
  default = 100
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
    "hail-computers",
    "hail-cluster-${var.hail_cluster_id}",
    "hgi-credentials",
  ]

  hostname_format = "${format("hail-%s-compute", var.hail_cluster_id)}-%02d"
}

module "hgi-openstack-instance" {
  source                  = "../../../hgi-openstack-instance/v2"
  env                     = "${var.env}"
  region                  = "${var.region}"
  setup                   = "${var.setup}"
  core_context            = "${var.core_context}"
  count                   = "${var.count}"
  name_format             = "${local.hostname_format}"
  domain                  = "${var.domain}"
  flavour                 = "${var.flavour}"
  hostname_format         = "${local.hostname_format}"
  ssh_gateway             = "${var.ssh_gateway}"
  keypair_name            = "${var.keypair_name}"
  network_name            = "${var.network_name}"
  image                   = "${var.image}"
  volume_p                = true
  volume_size_gb          = "${var.volume_size_gb}"
  auto_anti_affinity_name = "hail-anti-affinity-${var.hail_cluster_id}"

  security_group_names = [
    "ping",
    "ssh",
    "https",
    "tcp-local",
    "udp-local",
  ]

  ansible_groups = "${distinct(concat(local.ansible_groups, var.extra_ansible_groups))}"
}

output "hgi_instances" {
  value = "${module.hgi-openstack-instance.hgi_instance}"
}
