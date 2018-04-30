variable "env" {}
variable "region" {}
variable "setup" {}

variable "name_format" {}
variable "domain" {}
variable "flavour" {}
variable "count" {}

variable "hostname_format" {
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

variable "ssh_gateway" {
  type    = "map"
  default = {}
}

variable "floating_ip_p" {
  default = false
}

variable "volume_p" {
  default = false
}

variable "volume_size_gb" {
  default = 10
}

variable "keypair_name" {
  default = "mercury"
}

variable "network_name" {
  default = "main"
}

variable "core_context" {
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
  core_context_maps    = "${var.core_context["maps"]}"
  core_context_lists   = "${var.core_context["lists"]}"
  core_context_strings = "${var.core_context["strings"]}"
}

locals {
  hostname_format           = "${var.hostname_format == "" ? var.name_format : var.hostname_format}"
  openstack_keypairs        = "${local.core_context_maps["keypairs"]}"
  openstack_security_groups = "${local.core_context_maps["security_groups"]}"
  openstack_networks        = "${local.core_context_maps["networks"]}"
}

locals {
  security_groups            = "${matchkeys(values(local.openstack_security_groups), keys(local.openstack_security_groups), var.security_group_names)}"
  additional_dns_names_count = "${length(var.additional_dns_names)}"
}

resource "openstack_networking_floatingip_v2" "floatingip" {
  count    = "${var.floating_ip_p ? var.count : 0}"
  provider = "openstack"
  pool     = "${local.core_context_strings["floatingip_pool_name"]}"
}

resource "openstack_networking_port_v2" "port" {
  count          = "${var.count}"
  name           = "${var.env}-${var.region}-${var.setup}-${format(var.name_format, count.index + 1)}-port"
  admin_state_up = "true"
  network_id     = "${lookup(local.openstack_networks, var.network_name)}"

  security_group_ids = ["${local.security_groups}"]
}

resource "openstack_compute_instance_v2" "instance" {
  provider    = "openstack"
  count       = "${var.count}"
  name        = "${var.env}-${var.region}-${var.setup}-${format(var.name_format, count.index + 1)}"
  image_id    = "${var.image["id"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${lookup(local.openstack_keypairs, var.keypair_name)}"

  network {
    port = "${openstack_networking_port_v2.port.*.id[count.index]}"
  }

  user_data = "#cloud-config\nhostname: ${format(local.hostname_format, count.index + 1)}\nfqdn: ${format(local.hostname_format, count.index + 1)}.${var.domain}"

  metadata = {
    ansible_groups = "${join(" ", var.ansible_groups)}"
    user           = "${var.image["user"]}"
    bastion_host   = "${var.ssh_gateway["host"]}"
    bastion_user   = "${var.ssh_gateway["user"]}"
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
      bastion_host = "${var.ssh_gateway["host"]}"
      bastion_user = "${var.ssh_gateway["user"]}"
      host         = "${openstack_networking_port_v2.port.*.all_fixed_ips.0[count.index]}"
    }
  }
}

resource "openstack_compute_floatingip_associate_v2" "floatingip-instance-associate" {
  count       = "${var.floating_ip_p ? var.count : 0}"
  floating_ip = "${openstack_networking_floatingip_v2.floatingip.0.address}"
  instance_id = "${openstack_compute_instance_v2.instance.*.id[count.index]}"
}

resource "infoblox_record" "floatingip-dns" {
  count  = "${var.floating_ip_p ? var.count : 0}"
  value  = "${openstack_compute_floatingip_associate_v2.floatingip-instance-associate.*.floating_ip[count.index]}"
  name   = "${format(local.hostname_format, count.index + 1)}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
  view   = "internal"
}

resource "infoblox_record" "floatingip-additional-dns" {
  count  = "${var.floating_ip_p ? (local.additional_dns_names_count*var.count) : 0}"
  value  = "${openstack_compute_floatingip_associate_v2.floatingip-instance-associate.*.floating_ip[count.index/local.additional_dns_names_count]}"
  name   = "${element(var.additional_dns_names, count.index%local.additional_dns_names_count)}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
  view   = "internal"
}

resource "openstack_blockstorage_volume_v2" "volume" {
  count = "${var.volume_p ? var.count : 0}"
  name  = "${var.env}-${var.region}-${var.setup}-${format(var.name_format, count.index + 1)}-volume"
  size  = "${var.volume_size_gb}"
}

resource "openstack_compute_volume_attach_v2" "volume-attach" {
  count       = "${var.volume_p ? var.count : 0}"
  volume_id   = "${openstack_blockstorage_volume_v2.volume.*.id[count.index]}"
  instance_id = "${openstack_compute_instance_v2.instance.*.id[count.index]}"
}

output "user" {
  value = "${var.image["user"]}"
}

output "security_groups" {
  value = "${local.security_groups}"
}
