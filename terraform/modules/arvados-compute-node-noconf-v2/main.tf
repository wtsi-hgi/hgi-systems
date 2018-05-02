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
variable "consul_keys_datacenter" {}

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
    "arvados-compute-nodes-noconf",
    "noconf",
  ]

  all_ansible_groups = "${distinct(concat(local.ansible_groups, var.extra_ansible_groups))}"
  hostname_format    = "arvados-compute-node-${var.arvados_cluster_id}-%03d"
}

data "consul_keys" "consul-agent" {
  datacenter = "${var.consul_keys_datacenter}"

  key {
    name = "consul_encrypt"
    path = "terraform/consul_encrypt"
  }

  key {
    name = "consul_acl_token"
    path = "terraform/consul_cluster_acl_agent_token"
  }

  key {
    name = "upstream_dns_servers"
    path = "terraform/upstream_dns_servers"
  }

  key {
    name = "consul_template_token"
    path = "terraform/consul_template_token"
  }
}

data "template_file" "ansible-cc-script" {
  template = "${file("${path.module}/scripts/ansible-cc.sh.tpl")}"

  vars {
    ANSIBLE_CC_DOCKER_IMAGE = "mercury/taos"                           # TODO this could be pinned to the same version we are running in?
    ANSIBLE_CC_PLAYBOOK     = "arvados-compute-cloudconfig.yml"
    ANSIBLE_CC_GROUPS       = "${join(" ", local.all_ansible_groups)}"

    ANSIBLE_CC_HOST_VARS = <<EOF
      ansible_user=ubuntu
      cc_arvados_cluster_id='${var.arvados_cluster_id}'
      cc_consul_datacenter='${var.consul_datacenter}'
      cc_upstream_dns_servers='${data.consul_keys.consul-agent.var.upstream_dns_servers}'
      cc_consul_template_token='${data.consul_keys.consul-agent.var.consul_template_token}'
      cc_consul_agent_token='${data.consul_keys.consul-agent.var.consul_acl_token}'
      cc_consul_encrypt='${data.consul_keys.consul-agent.var.consul_encrypt}'
EOF
  }
}

module "hgi-openstack-instance" {
  source          = "../hgi-openstack-instance"
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${var.core_context}"
  count           = "${var.count}"
  floating_ip_p   = false
  volume_p        = true
  volume_size_gb  = "${var.volume_size_gb}"
  name_format     = "${local.hostname_format}"
  domain          = "${var.domain}"
  flavour         = "${var.flavour}"
  hostname_format = "${local.hostname_format}"
  ssh_gateway     = "${var.ssh_gateway}"
  keypair_name    = "${var.keypair_name}"
  network_name    = "${var.network_name}"
  image           = "${var.image}"

  cloud_config_shell_script = "${data.template_file.ansible-cc-script.rendered}"

  security_group_names = [
    "ping",
    "ssh",
    "consul-client",
    "slurm-compute",
    "netdata",
    "tcp-local",
    "udp-local",
  ]

  ansible_groups = "${local.all_ansible_groups}"

  additional_dns_names = []
}

output "hgi_instance" {
  value = "${module.hgi-openstack-instance.hgi_instance}"
}
