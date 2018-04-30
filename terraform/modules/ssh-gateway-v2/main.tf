variable "env" {}
variable "region" {}
variable "setup" {}

variable "core_context" {
  type    = "map"
  default = {}
}

variable "flavour" {}
variable "domain" {}

variable "keypair_name" {
  default = "mercury"
}

variable "network_name" {
  default = "main"
}

variable "image" {
  type    = "map"
  default = {}
}

variable "extra_ansible_groups" {
  type    = "list"
  default = []
}

locals {
  ansible_groups = [
    "ssh-gateways",
  ]
}

locals {
  core_context_maps    = "${var.core_context["maps"]}"
  core_context_lists   = "${var.core_context["lists"]}"
  core_context_strings = "${var.core_context["strings"]}"
}

locals {
  openstack_keypairs        = "${local.core_context_maps["keypairs"]}"
  openstack_security_groups = "${local.core_context_maps["security_groups"]}"
  openstack_networks        = "${local.core_context_maps["networks"]}"
}

resource "openstack_networking_port_v2" "ssh-gateway" {
  count          = 1
  name           = "${var.env}-${var.region}-${var.setup}-ssh-gateway-port"
  admin_state_up = "true"
  network_id     = "${lookup(local.openstack_networks, var.network_name)}"

  security_group_ids = [
    "${local.openstack_security_groups["ping"]}",
    "${local.openstack_security_groups["ssh"]}",
    "${local.openstack_security_groups["consul-client"]}",
  ]
}

resource "openstack_networking_floatingip_v2" "ssh-gateway" {
  provider = "openstack"
  pool     = "${local.core_context_strings["floatingip_pool_name"]}"
}

resource "openstack_compute_instance_v2" "ssh-gateway" {
  provider    = "openstack"
  count       = 1
  name        = "${var.env}-${var.region}-${var.setup}-ssh-gateway"
  image_id    = "${var.image["id"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${lookup(local.openstack_keypairs, var.keypair_name)}"

  network {
    port = "${openstack_networking_port_v2.ssh-gateway.*.id[count.index]}"
  }

  user_data = "#cloud-config\nhostname: ssh\nfqdn: ssh.${var.domain}"

  metadata = {
    ansible_groups = "${join(" ", distinct(concat(local.ansible_groups, var.extra_ansible_groups)))}"
    user           = "${var.image["user"]}"
    bastion_host   = "${openstack_networking_floatingip_v2.ssh-gateway.address}"
    bastion_user   = "${var.image["user"]}"
  }
}

resource "openstack_compute_floatingip_associate_v2" "ssh-gateway" {
  floating_ip = "${openstack_networking_floatingip_v2.ssh-gateway.address}"
  instance_id = "${openstack_compute_instance_v2.ssh-gateway.id}"
}

resource "infoblox_record" "ssh-gateway" {
  value  = "${openstack_compute_floatingip_associate_v2.ssh-gateway.floating_ip}"
  name   = "ssh"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
  view   = "internal"
}

resource "null_resource" "ssh-gateway" {
  triggers {
    ssh-host = "${openstack_compute_instance_v2.ssh-gateway.id}"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]

    connection {
      type    = "ssh"
      host    = "${openstack_compute_floatingip_associate_v2.ssh-gateway.floating_ip}"
      user    = "${var.image["user"]}"
      agent   = "true"
      timeout = "2m"
    }
  }
}

output "host" {
  value = "${openstack_compute_floatingip_associate_v2.ssh-gateway.floating_ip}"
}

output "user" {
  value = "${var.image["user"]}"
}
