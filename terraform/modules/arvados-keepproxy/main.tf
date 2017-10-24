variable "count" {}
variable "flavour" {}
variable "domain" {}
variable "network_id" {}
variable "arvados_cluster_id" {}

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
    "arvados-keepproxies",
    "arvados-cluster-${var.arvados_cluster_id}",
    "consul-agents",
    "hgi-credentials",
  ]

  hostname_format = "${format("arvados-keepproxy-%s", var.arvados_cluster_id)}-%02d"
}

resource "openstack_networking_floatingip_v2" "arvados-keepproxy" {
  provider = "openstack"
  pool     = "nova"
  count    = "${var.count}"
}

resource "openstack_compute_instance_v2" "arvados-keepproxy" {
  provider    = "openstack"
  count       = "${var.count}"
  name        = "${format(local.hostname_format, count.index + 1)}"
  image_name  = "${var.image["name"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${var.key_pair_ids["mercury"]}"

  security_groups = [
    "${var.security_group_ids["ping"]}",
    "${var.security_group_ids["ssh"]}",
    "${var.security_group_ids["https"]}",
    "${var.security_group_ids["consul-client"]}",
    "${var.security_group_ids["keep-proxy"]}",
  ]

  network {
    uuid           = "${var.network_id}"
    access_network = true
  }

  user_data = "#cloud-config\nhostname: ${format(local.hostname_format, count.index + 1)}\nfqdn: ${format(local.hostname_format, count.index + 1)}.${var.domain}"

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

resource "openstack_compute_floatingip_associate_v2" "arvados-keepproxy" {
  provider    = "openstack"
  count       = "${var.count}"
  floating_ip = "${openstack_networking_floatingip_v2.arvados-keepproxy.*.address[count.index]}"
  instance_id = "${openstack_compute_instance_v2.arvados-keepproxy.*.id[count.index]}"
}

resource "infoblox_record" "arvados-keepproxy" {
  count  = "${var.count}"
  value  = "${openstack_networking_floatingip_v2.arvados-keepproxy.*.address[count.index]}"
  name   = "${format(local.hostname_format, count.index + 1)}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

# FIXME: add infoblox provider support for multiple A records
resource "infoblox_record" "arvados-keep" {
  value  = "${openstack_networking_floatingip_v2.arvados-keepproxy.0.address}"
  name   = "arvados-keep-${var.arvados_cluster_id}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

resource "infoblox_record" "arvados-download" {
  value  = "${openstack_networking_floatingip_v2.arvados-keepproxy.0.address}"
  name   = "arvados-download-${var.arvados_cluster_id}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

resource "infoblox_record" "arvados-collections" {
  value  = "${openstack_networking_floatingip_v2.arvados-keepproxy.0.address}"
  name   = "arvados-collections-${var.arvados_cluster_id}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

output "ip" {
  count = "${var.count}"
  value = "${openstack_networking_floatingip_v2.arvados-keepproxy.*.address}[count.index]"
}
