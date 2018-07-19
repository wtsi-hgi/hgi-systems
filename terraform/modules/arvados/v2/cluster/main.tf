variable "env" {}
variable "region" {}
variable "setup" {}

variable "domain" {}
variable "arvados_cluster_id" {}
variable "consul_datacenter" {}
variable "consul_acl_datacenter" {}
variable "consul_keys_datacenter" {}

variable "base_image" {
  type = "map"
}

variable "compute_node_image" {
  type = "map"
}

variable "keepproxy_count" {
  default = 2
}

variable "keep_count" {
  default = 1
}

variable "shell_names" {
  type    = "list"
  default = ["shell"]
}

variable "monitor_count" {
  default = 1
}

variable "compute_node_count" {
  default = 1
}

variable "ssh_gateway" {
  type = "map"
}

variable "core_context" {
  type = "map"
}

variable "network_name" {
  default = "main"
}

variable "master_flavour" {
  default = "m1.xlarge"
}

variable "master_volume_size_gb" {
  default = 100
}

variable "api_backend_count" {
  default = 1
}

variable "api_backend_flavour" {
  default = "o1.4xlarge"
}

variable "api_db_flavour" {
  default = "m1.2xlarge"
}

variable "api_db_volume_size_gb" {
  default = 1000
}

variable "sso_flavour" {
  default = "m1.2xlarge"
}

variable "sso_volume_size_gb" {
  default = 100
}

variable "workbench_flavour" {
  default = "m1.medium"
}

variable "keepproxy_flavour" {
  default = "m1.medium"
}

variable "keep_flavour" {
  default = "m1.medium"
}

variable "shell_flavour" {
  default = "m1.medium"
}

variable "monitor_flavour" {
  default = "m1.medium"
}

variable "compute_node_flavour" {
  default = "m1.xlarge"
}

variable "extra_ansible_groups" {
  type    = "list"
  default = []
}

locals {
  consul_domain = "node.${var.consul_datacenter}.consul"
}

module "arvados-master" {
  source = "../master"

  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${var.core_context}"
  ssh_gateway  = "${var.ssh_gateway}"

  arvados_cluster_id   = "${var.arvados_cluster_id}"
  consul_datacenter    = "${var.consul_datacenter}"
  extra_ansible_groups = "${var.extra_ansible_groups}"

  flavour = "${var.master_flavour}"
  domain  = "${var.domain}"
  image   = "${var.base_image}"

  volume_size_gb = "${var.master_volume_size_gb}"
}

module "arvados-api-backend" {
  source = "../api-backend"

  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${var.core_context}"
  ssh_gateway  = "${var.ssh_gateway}"

  arvados_cluster_id   = "${var.arvados_cluster_id}"
  consul_datacenter    = "${var.consul_datacenter}"
  extra_ansible_groups = "${var.extra_ansible_groups}"

  count   = "${var.api_backend_count}"
  flavour = "${var.api_backend_flavour}"
  domain  = "${var.domain}"
  image   = "${var.base_image}"
}

module "arvados-api-db" {
  source = "../api-db"

  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${var.core_context}"
  ssh_gateway  = "${var.ssh_gateway}"

  arvados_cluster_id   = "${var.arvados_cluster_id}"
  consul_datacenter    = "${var.consul_datacenter}"
  extra_ansible_groups = "${var.extra_ansible_groups}"

  flavour = "${var.api_db_flavour}"
  domain  = "${local.consul_domain}"
  image   = "${var.base_image}"

  volume_size_gb = "${var.api_db_volume_size_gb}"
}

module "arvados-sso" {
  source = "../sso"

  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${var.core_context}"
  ssh_gateway  = "${var.ssh_gateway}"

  arvados_cluster_id   = "${var.arvados_cluster_id}"
  consul_datacenter    = "${var.consul_datacenter}"
  extra_ansible_groups = "${var.extra_ansible_groups}"

  flavour = "${var.sso_flavour}"
  domain  = "${var.domain}"
  image   = "${var.base_image}"

  volume_size_gb = "${var.sso_volume_size_gb}"
}

module "arvados-workbench" {
  source = "../workbench"

  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${var.core_context}"
  ssh_gateway  = "${var.ssh_gateway}"

  arvados_cluster_id   = "${var.arvados_cluster_id}"
  consul_datacenter    = "${var.consul_datacenter}"
  extra_ansible_groups = "${var.extra_ansible_groups}"

  flavour = "${var.workbench_flavour}"
  domain  = "${var.domain}"
  image   = "${var.base_image}"
}

module "arvados-keepproxy" {
  source = "../keepproxy"

  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${var.core_context}"
  ssh_gateway  = "${var.ssh_gateway}"

  arvados_cluster_id   = "${var.arvados_cluster_id}"
  consul_datacenter    = "${var.consul_datacenter}"
  extra_ansible_groups = "${var.extra_ansible_groups}"

  count   = "${var.keepproxy_count}"
  flavour = "${var.keepproxy_flavour}"
  domain  = "${var.domain}"
  image   = "${var.base_image}"
}

module "arvados-keep" {
  source = "../keep"

  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${var.core_context}"
  ssh_gateway  = "${var.ssh_gateway}"

  arvados_cluster_id   = "${var.arvados_cluster_id}"
  consul_datacenter    = "${var.consul_datacenter}"
  extra_ansible_groups = "${var.extra_ansible_groups}"

  count   = "${var.keep_count}"
  flavour = "${var.keep_flavour}"
  domain  = "${local.consul_domain}"
  image   = "${var.base_image}"
}

module "arvados-shell" {
  source = "../shell"

  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${var.core_context}"
  ssh_gateway  = "${var.ssh_gateway}"

  arvados_cluster_id   = "${var.arvados_cluster_id}"
  consul_datacenter    = "${var.consul_datacenter}"
  extra_ansible_groups = "${var.extra_ansible_groups}"

  count       = "${length(var.shell_names)}"
  shell_names = "${var.shell_names}"
  flavour     = "${var.shell_flavour}"
  domain      = "${var.domain}"
  image       = "${var.base_image}"
}

module "arvados-monitor" {
  source = "../monitor"

  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${var.core_context}"
  ssh_gateway  = "${var.ssh_gateway}"

  arvados_cluster_id   = "${var.arvados_cluster_id}"
  consul_datacenter    = "${var.consul_datacenter}"
  extra_ansible_groups = "${var.extra_ansible_groups}"

  count   = "${var.monitor_count}"
  flavour = "${var.monitor_flavour}"
  domain  = "${var.domain}"
  image   = "${var.base_image}"
}

module "arvados-compute-node-noconf" {
  source = "../compute-node-noconf"

  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${var.core_context}"
  ssh_gateway  = "${var.ssh_gateway}"

  arvados_cluster_id     = "${var.arvados_cluster_id}"
  consul_datacenter      = "${var.consul_datacenter}"
  consul_acl_datacenter  = "${var.consul_acl_datacenter}"
  consul_keys_datacenter = "${var.consul_keys_datacenter}"
  extra_ansible_groups   = "${var.extra_ansible_groups}"

  count   = "${var.compute_node_count}"
  flavour = "${var.compute_node_flavour}"
  domain  = "${local.consul_domain}"
  image   = "${var.compute_node_image}"
}

output "hgi_instances" {
  value = {
    external_dns    = "${merge(module.arvados-master.hgi_instance["external_dns"], module.arvados-api-db.hgi_instance["external_dns"], module.arvados-sso.hgi_instance["external_dns"], module.arvados-workbench.hgi_instance["external_dns"], module.arvados-keepproxy.hgi_instance["external_dns"], module.arvados-keep.hgi_instance["external_dns"], module.arvados-shell.hgi_instance["external_dns"], module.arvados-monitor.hgi_instance["external_dns"])}"
    floating_ip     = "${merge(module.arvados-master.hgi_instance["floating_ip"], module.arvados-api-db.hgi_instance["floating_ip"], module.arvados-sso.hgi_instance["floating_ip"], module.arvados-workbench.hgi_instance["floating_ip"], module.arvados-keepproxy.hgi_instance["floating_ip"], module.arvados-keep.hgi_instance["floating_ip"], module.arvados-shell.hgi_instance["floating_ip"], module.arvados-monitor.hgi_instance["floating_ip"])}"
    internal_ip     = "${merge(module.arvados-master.hgi_instance["internal_ip"], module.arvados-api-db.hgi_instance["internal_ip"], module.arvados-sso.hgi_instance["internal_ip"], module.arvados-workbench.hgi_instance["internal_ip"], module.arvados-keepproxy.hgi_instance["internal_ip"], module.arvados-keep.hgi_instance["internal_ip"], module.arvados-shell.hgi_instance["internal_ip"], module.arvados-monitor.hgi_instance["internal_ip"])}"
    user            = "${merge(module.arvados-master.hgi_instance["user"], module.arvados-api-db.hgi_instance["user"], module.arvados-sso.hgi_instance["user"], module.arvados-workbench.hgi_instance["user"], module.arvados-keepproxy.hgi_instance["user"], module.arvados-keep.hgi_instance["user"], module.arvados-shell.hgi_instance["user"], module.arvados-monitor.hgi_instance["user"])}"
    security_groups = "${merge(module.arvados-master.hgi_instance["security_groups"], module.arvados-api-db.hgi_instance["security_groups"], module.arvados-sso.hgi_instance["security_groups"], module.arvados-workbench.hgi_instance["security_groups"], module.arvados-keepproxy.hgi_instance["security_groups"], module.arvados-keep.hgi_instance["security_groups"], module.arvados-shell.hgi_instance["security_groups"], module.arvados-monitor.hgi_instance["security_groups"])}"
  }
}

output "hgi_instances_by_type" {
  value = {
    arvados-master      = "${module.arvados-master.hgi_instance}"
    arvados-api-backend = "${module.arvados-api-backend.hgi_instance}"
    arvados-api-db      = "${module.arvados-api-db.hgi_instance}"
    arvados-sso         = "${module.arvados-sso.hgi_instance}"
    arvados-workbench   = "${module.arvados-workbench.hgi_instance}"
    arvados-keepproxy   = "${module.arvados-keepproxy.hgi_instance}"
    arvados-keep        = "${module.arvados-keep.hgi_instance}"
    arvados-shell       = "${module.arvados-shell.hgi_instance}"
    arvados-monitor     = "${module.arvados-monitor.hgi_instance}"
  }
}
