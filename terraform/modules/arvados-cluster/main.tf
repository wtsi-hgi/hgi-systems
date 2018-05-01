variable "env" {}
variable "region" {}
variable "setup" {}

variable "domain" {}
variable "arvados_cluster_id" {}
variable "consul_datacenter" {}

variable "base_image" {
  type = "map"
}

variable "arvados_compute_node_image" {
  type = "map"
}

variable "keepproxy_count" {
  default = 2
}

variable "keep_count" {
  default = 1
}

variable "shell_count" {
  default = 1
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
  source = "../arvados-master-v2"

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

module "arvados-api-db" {
  source = "../arvados-api-db-v2"

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
  source = "../arvados-sso-v2"

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
  source = "../arvados-workbench-v2"

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
  source = "../arvados-keepproxy-v2"

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
  source = "../arvados-keep-v2"

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

# module "arvados-shell" {
#   source                 = "../arvados-shell-v2"
#   env = "${var.env}"
#   region = "${var.region}"
#   setup = "${var.setup}"
#   core_context = "${var.core_context}"

#   image = "${var.base_image}"

#   count   = "${var.shell_count}"
#   flavour = "${var.shell_flavour}"
#   domain  = "${var.domain}"

#   ssh_gateway = "${var.ssh_gateway}"

#   arvados_cluster_id   = "${var.arvados_cluster_id}"
#   extra_ansible_groups = "${var.extra_ansible_groups}"
# }

# module "arvados-monitor" {
#   source                 = "../arvados-monitor-v2"
#   env = "${var.env}"
#   region = "${var.region}"
#   setup = "${var.setup}"
#   core_context = "${var.core_context}"

#   image = "${var.base_image}"

#   count   = "${var.monitor_count}"
#   flavour = "${var.monitor_flavour}"
#   domain  = "${var.domain}"

#   ssh_gateway = "${var.ssh_gateway}"

#   arvados_cluster_id   = "${var.arvados_cluster_id}"
#   extra_ansible_groups = "${var.extra_ansible_groups}"
# }

# module "arvados-compute-node-noconf" {
#   source                 = "../arvados-compute-node-noconf-v2"
#   env = "${var.env}"
#   region = "${var.region}"
#   setup = "${var.setup}"
#   core_context = "${var.core_context}"

#   image = "${var.arvados_compute_node_image}"

#   count   = "${var.arvados_compute_node_count}"
#   flavour = "${var.compute_node_flavour}"
#   domain  = "${local.consul_domain}"

#   ssh_gateway = "${var.ssh_gateway}"

#   arvados_cluster_id   = "${var.arvados_cluster_id}"
#   extra_ansible_groups = []

#   consul_datacenter     = "delta-hgiarvados"
#   consul_retry_join     = "${module.consul-server.retry_join}"
#   upstream_dns_servers  = ["172.18.255.1", "172.18.255.2", "172.18.255.3"] # FIXME this should be defined elsewhere
#   consul_template_token = "${var.consul_template_token}"
# }

output "hgi_instances" {
  value = {
    arvados-master = "${module.arvados-master.hgi_instance}"
  }
}
