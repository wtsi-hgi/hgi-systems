variable "env" {}
variable "region" {}
variable "setup" {}

variable "domain" {}
variable "hail_cluster_id" {}

variable "master_image" {
  type = "map"
}

variable "compute_image" {
  type = "map"
}

variable "core_context" {
  type    = "map"
  default = {}
}

variable "ssh_gateway" {
  type = "map"
}

variable "network_name" {
  default = "main"
}

variable "master_count" {
  default = 1
}

variable "master_flavour" {
  default = "o1.large"
}

variable "master_volume_size_gb" {
  default = 100
}

variable "compute_volume_size_gb" {
  default = 100
}

variable "compute_count" {
  default = 0
}

variable "compute_flavour" {
  default = "o1.large"
}

variable "compute_auto_anti_affinity_p" {
  default = true
}

module "hail-master" {
  source          = "../master"
  hail_cluster_id = "${var.hail_cluster_id}"
  count           = "${var.master_count}"
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${var.core_context}"
  domain          = "${var.domain}"
  image           = "${var.master_image}"
  network_name    = "main"
  ssh_gateway     = "${var.ssh_gateway}"
  flavour         = "${var.master_flavour}"
  volume_size_gb  = "${var.master_volume_size_gb}"
}

module "hail-compute" {
  source               = "../compute"
  hail_cluster_id      = "${var.hail_cluster_id}"
  count                = "${var.compute_count}"
  env                  = "${var.env}"
  region               = "${var.region}"
  setup                = "${var.setup}"
  core_context         = "${var.core_context}"
  domain               = "${var.domain}"
  image                = "${var.compute_image}"
  network_name         = "main"
  ssh_gateway          = "${var.ssh_gateway}"
  flavour              = "${var.compute_flavour}"
  volume_size_gb       = "${var.compute_volume_size_gb}"
  auto_anti_affinity_p = "${var.compute_auto_anti_affinity_p}"
}

output "hgi_instances" {
  value = {
    external_dns    = "${merge(module.hail-master.hgi_instances["external_dns"], module.hail-compute.hgi_instances["external_dns"])}"
    floating_ip     = "${merge(module.hail-master.hgi_instances["floating_ip"], module.hail-compute.hgi_instances["floating_ip"])}"
    internal_ip     = "${merge(module.hail-master.hgi_instances["internal_ip"], module.hail-compute.hgi_instances["internal_ip"])}"
    user            = "${merge(module.hail-master.hgi_instances["user"], module.hail-compute.hgi_instances["user"])}"
    security_groups = "${merge(module.hail-master.hgi_instances["security_groups"], module.hail-compute.hgi_instances["security_groups"])}"
  }
}

output "hgi_instances_by_type" {
  value = {
    hail-master  = "${module.hail-master.hgi_instances}"
    hail-compute = "${module.hail-compute.hgi_instances}"
  }
}
