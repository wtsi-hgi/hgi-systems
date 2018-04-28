variable "name" {}
variable "domain" {}
variable "flavour" {}

variable "hostname" {
  default = ""
}

variable "additional_dns_names" {
  type    = "list"
  default = []
}

variable "security_group_names" {
  type = "list"

  default = [
    "ping",
    "ssh",
  ]
}

variable "bastion" {
  type    = "map"
  default = {}
}

variable "floating_ip" {
  default = false
}

variable "keypair_name" {
  default = "mercury"
}

variable "network_name" {
  default = "main"
}

variable "openstack_core_context" {
  type    = "map"
  default = {}
}

variable "image" {
  type    = "map"
  default = {}
}

variable "ansible_groups" {
  type    = "list"
  default = []
}

locals {
  hostname                  = "${var.hostname == "" ? var.name : var.hostname}"
  openstack_keypairs        = "${var.openstack_core_context["keypairs"]}"
  openstack_security_groups = "${var.openstack_core_context["security_groups"]}"
  openstack_networks        = "${var.openstack_core_context["networks"]}"
  openstack_parameters      = "${var.openstack_core_context["parameters"]}"
}

resource "openstack_networking_floatingip_v2" "floatingip" {
  count    = "${var.floating_ip ? 1 : 0}"
  provider = "openstack"
  pool     = "${local.openstack_parameters["floatingip_pool_name"]}"
}

resource "openstack_compute_instance_v2" "instance" {
  provider    = "openstack"
  count       = 1
  name        = "${var.name}"
  image_id    = "${var.image["id"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${lookup(local.openstack_keypairs, var.keypair_name)}"

  security_groups = "${matchkeys(values(local.openstack_security_groups), maps(local.openstack_security_groups), var.security_group_names)}"

  network {
    uuid           = "${lookup(local.openstack_networks, var.network_name)}"
    access_network = true
  }

  user_data = "#cloud-config\nhostname: ${local.hostname}\nfqdn: ${local.hostname}.${var.domain}"

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
    }
  }
}

resource "openstack_compute_floatingip_associate_v2" "floatingip-instance-associate" {
  count       = "${var.floating_ip ? 1 : 0}"
  floating_ip = "${openstack_networking_floatingip_v2.floatingip.0.address}"
  instance_id = "${openstack_compute_instance_v2.instance.id}"
}

resource "infoblox_record" "floatingip-dns" {
  count  = "${var.floating_ip ? 1 : 0}"
  value  = "${openstack_compute_floatingip_associate_v2.floatingip-instance-associate.0.floating_ip}"
  name   = "${local.hostname}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
  view   = "internal"
}

resource "infoblox_record" "floatingip-additional-dns" {
  count  = "${var.floating_ip ? length(var.additional_dns_names) : 0}"
  value  = "${openstack_compute_floatingip_associate_v2.floatingip-instance-associate.0.floating_ip}"
  name   = "${element(var.additional_dns_names, count.index)}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
  view   = "internal"
}

output "ip" {
  value = "${var.floating_ip ? openstack_compute_floatingip_associate_v2.floatingip-instance-associate.0.floating_ip : openstack_compute_instance_v2.instance.access_ip_v4}"
}

output "user" {
  value = "${var.image["user"]}"
}
