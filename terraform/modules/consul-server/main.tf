variable "flavour" {}
variable "domain" {}
variable "network_id" {}
variable "consul_datacenter" {}
variable "count" {}

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

locals {
  hostname_format = "${format("consul-server-%s", var.consul_datacenter)}-%02d"
}

resource "openstack_networking_floatingip_v2" "consul-server" {
  provider = "openstack"
  pool     = "nova"
  count    = "${var.count}"
}

resource "openstack_compute_instance_v2" "consul-server" {
  provider    = "openstack"
  count       = "${var.count}"
  name        = "${format(local.hostname_format, count.index + 1)}"
  image_name  = "${var.image["name"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${var.key_pair_ids["mercury"]}"

  security_groups = [
    "${var.security_group_ids["ping"]}",
    "${var.security_group_ids["ssh"]}",
    "${var.security_group_ids["consul-server"]}",
  ]

  network {
    uuid           = "${var.network_id}"
    access_network = true
  }

  user_data = "#cloud-config\nhostname: ${format(local.hostname_format, count.index + 1)}\nfqdn: ${format(local.hostname_format, count.index + 1)}.${var.domain}"

  metadata = {
    ansible_groups = "consul-servers consul-cluster-${var.consul_datacenter} hgi-credentials"
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

resource "openstack_compute_floatingip_associate_v2" "consul-server" {
  provider    = "openstack"
  count       = "${var.count}"
  floating_ip = "${openstack_networking_floatingip_v2.consul-server.*.address[count.index]}"
  instance_id = "${openstack_compute_instance_v2.consul-server.*.id[count.index]}"
}

resource "infoblox_record" "consul-server" {
  count  = "${var.count}"
  value  = "${openstack_networking_floatingip_v2.consul-server.*.address[count.index]}"
  name   = "${format(local.hostname_format, count.index + 1)}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

resource "openstack_blockstorage_volume_v2" "consul-server" {
  name  = "${format(local.hostname_format, count.index + 1)}"
  count = "${var.count}"
  size  = 10
}

resource "openstack_compute_volume_attach_v2" "consul-server" {
  volume_id   = "${openstack_blockstorage_volume_v2.consul-server.*.id[count.index]}"
  instance_id = "${openstack_compute_instance_v2.consul-server.*.id[count.index]}"
  count       = "${var.count}"
}
