variable "count" {}
variable "flavour" {}
variable "domain" {}
variable "network_id" {}
variable "arvados_cluster_id" {}

variable "consul_datacenter" {}

variable "upstream_dns_servers" {
  type    = "list"
  default = []
}

variable "consul_retry_join" {
  type    = "list"
  default = []
}

variable "security_group_ids" {
  type    = "map"
  default = {}
}

variable "key_pair_ids" {
  type    = "map"
  default = {}
}

variable "image" {
  type    = "map"
  default = {}
}

variable "bastion" {
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
  ]

  hostname_format = "arvados-compute-node-${var.arvados_cluster_id}-%03d"
}

resource "openstack_networking_port_v2" "arvados-compute-port" {
  count          = "${var.count}"
  name           = "${format(local.hostname_format, count.index + 1)}"
  admin_state_up = "true"
  network_id     = "${var.network_id}"

  security_group_ids = [
    "${var.security_group_ids["ping"]}",
    "${var.security_group_ids["ssh"]}",
    "${var.security_group_ids["consul-client"]}",
    "${var.security_group_ids["slurm-compute"]}",
    "${var.security_group_ids["tcp-local"]}",
    "${var.security_group_ids["udp-local"]}",
  ]
}

data "consul_keys" "consul-agent" {
  datacenter = "${var.consul_datacenter}"

  key {
    name = "consul_encrypt"
    path = "terraform/consul_encrypt"
  }

  key {
    name = "consul_acl_token"
    path = "terraform/consul_cluster_acl_agent_token"
  }
}

data "template_file" "init-script" {
  count    = "${var.count}"
  template = "${file("${path.module}/scripts/init.cfg.tpl")}"

  vars {
    CLOUDINIT_HOSTNAME = "${format(local.hostname_format, count.index + 1)}"
    CLOUDINIT_DOMAIN   = "${var.domain}"
  }
}

data "template_file" "docker-consul-script" {
  count    = "${var.count}"
  template = "${file("${path.module}/scripts/docker-consul.sh.tpl")}"

  vars {
    CONSUL_RETRY_JOIN     = "${join(",", var.consul_retry_join)}"
    CONSUL_RECURSORS      = "${join(",", var.upstream_dns_servers)}"
    CONSUL_ADVERTISE_ADDR = "${openstack_networking_port_v2.arvados-compute-port.*.all_fixed_ips.0[count.index]}"
    CONSUL_DATACENTER     = "${var.consul_datacenter}"
    CONSUL_ACL_TOKEN      = "${data.consul_keys.consul-agent.var.consul_acl_token}"
    CONSUL_ENCRYPT        = "${data.consul_keys.consul-agent.var.consul_encrypt}"
    CONSUL_BIND_ADDR      = "${openstack_networking_port_v2.arvados-compute-port.*.all_fixed_ips.0[count.index]}"
  }
}

data "template_file" "ansible-cc-script" {
  count    = "${var.count}"
  template = "${file("${path.module}/scripts/ansible-cc.sh.tpl")}"

  vars {
    ANSIBLE_CC_DOCKER_IMAGE         = "mercury/taos"                                                                   # TODO this could be pinned to the same version we are running in?
    ANSIBLE_CC_PLAYBOOK             = "arvados-compute-cloudconfig.yml"
    ANSIBLE_CC_GROUPS               = "${join(" ", distinct(concat(local.ansible_groups, var.extra_ansible_groups)))}"
    ANSIBLE_CC_UPSTREAM_DNS_SERVERS = "${join(",", var.upstream_dns_servers)}"
    ANSIBLE_CC_CONSUL_DATACENTER    = "${var.consul_datacenter}"
  }
}

data "template_cloudinit_config" "arvados-compute-cloudinit" {
  count         = "${var.count}"
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.init-script.*.rendered[count.index]}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.docker-consul-script.*.rendered[count.index]}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.ansible-cc-script.*.rendered[count.index]}"
  }
}

resource "openstack_compute_instance_v2" "arvados-compute" {
  provider    = "openstack"
  count       = "${var.count}"
  name        = "${format(local.hostname_format, count.index + 1)}"
  image_name  = "${var.image["name"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${var.key_pair_ids["mercury"]}"

  network {
    port = "${openstack_networking_port_v2.arvados-compute-port.*.id[count.index]}"
  }

  user_data = "${data.template_cloudinit_config.arvados-compute-cloudinit.*.rendered[count.index]}"

  metadata = {
    ansible_groups = "${join(" ", distinct(concat(local.ansible_groups, var.extra_ansible_groups)))}"
    user           = "${var.image["user"]}"
    bastion_host   = "${var.bastion["host"]}"
    bastion_user   = "${var.bastion["user"]}"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]

    connection {
      type         = "ssh"
      user         = "${var.image["user"]}"
      agent        = "true"
      timeout      = "2m"
      bastion_host = "${var.bastion["host"]}"
      bastion_user = "${var.bastion["user"]}"
      host         = "${openstack_networking_port_v2.arvados-compute-port.*.all_fixed_ips.0[count.index]}"
    }
  }
}
