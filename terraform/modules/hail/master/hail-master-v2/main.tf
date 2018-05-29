variable "env" {}
variable "region" {}
variable "setup" {}

variable "core_context" {
  type    = "map"
  default = {}
}

variable "hail_cluster_id" {}
variable "count" {}
variable "flavour" {}
variable "domain" {}

variable "volume_size_gb" {
  default = 20
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
    "hail-masters",
    "hail-cluster-${var.hail_cluster_id}",
    "hgi-credentials",
  ]

  hostname_format = "${format("hail-%s-master", var.hail_cluster_id)}-%02d"
}

module "hgi-openstack-instance" {
  source          = "../../../hgi-openstack-instance"
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${var.core_context}"
  count           = "${var.count}"
  floating_ip_p   = true
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

  security_group_names = [
    "ping",
    "ssh",
    "https",
    "tcp-local",
    "udp-local",
  ]

  ansible_groups = "${distinct(concat(local.ansible_groups, var.extra_ansible_groups))}"
}

output "hgi_instances" {
  value = "${module.hgi-openstack-instance.hgi_instance}"
}

//resource "openstack_networking_port_v2" "hail-master" {
//  count          = 1
//  name           = "${var.env}-${var.region}-${var.setup}-hail-${var.hail_cluster_id}-master-port"
//  admin_state_up = "true"
//  network_id     = "${lookup(local.openstack_networks, var.network_name)}"
//
//  security_group_ids = [
//    "${local.openstack_security_groups["ping"]}",
//    "${local.openstack_security_groups["ssh"]}",
//    "${local.openstack_security_groups["https"]}",
//    "${local.openstack_security_groups["tcp-local"]}",
//    "${local.openstack_security_groups["udp-local"]}",
//  ]
//}
//
//resource "openstack_networking_floatingip_v2" "hail-master" {
//  provider = "openstack"
//  count    = "${var.count}"
//  pool     = "${local.core_context_strings["floatingip_pool_name"]}"
//}
//
//resource "openstack_compute_instance_v2" "hail-master" {
//  provider    = "openstack"
//  count       = "${var.count}"
//  name        = "${var.env}-${var.region}-${var.setup}-hail-${var.hail_cluster_id}-master"
//  image_id    = "${var.image["id"]}"
//  flavor_name = "${var.flavour}"
//  key_pair    = "${lookup(local.openstack_keypairs, var.keypair_name)}"
//
//  network {
//    port = "${openstack_networking_port_v2.hail-master.*.id[count.index]}"
//  }
//
//  user_data = "#cloud-config\nhostname: hail-${var.hail_cluster_id}-master\nfqdn: hail-${var.hail_cluster_id}-master.${var.domain}"
//
//  metadata = {
//    ansible_groups = "${join(" ", distinct(concat(local.ansible_groups, var.extra_ansible_groups)))}"
//    user           = "${var.image["user"]}"
//    bastion_host   = "${openstack_networking_floatingip_v2.hail-master.address}"
//    bastion_user   = "${var.image["user"]}"
//  }
//
//  # wait for host to be available via ssh
//  provisioner "remote-exec" {
//    inline = [
//      "hostname",
//    ]
//
//    connection {
//      type         = "ssh"
//      user         = "${var.image["user"]}"
//      agent        = "true"
//      timeout      = "2m"
//      bastion_host = "${var.bastion["host"]}"
//      bastion_user = "${var.bastion["user"]}"
//    }
//  }
//}
//
//resource "openstack_compute_floatingip_associate_v2" "hail-master" {
//  count       = "${var.count}"
//  floating_ip = "${openstack_networking_floatingip_v2.hail-master.*.address[count.index]}"
//  instance_id = "${openstack_compute_instance_v2.hail-master.*.id[count.index]}"
//}
//
//resource "infoblox_record" "hail-master-dns" {
//  count  = "${var.count}"
//  value  = "${openstack_networking_floatingip_v2.hail-master.*.address[count.index]}"
//  name   = "hail-${var.hail_cluster_id}"
//  domain = "${var.domain}"
//  type   = "A"
//  ttl    = 600
//  view   = "internal"
//}
//
//output "ip" {
//  value = "${openstack_networking_floatingip_v2.hail-master.*.address}"
//}
//
//resource "openstack_blockstorage_volume_v2" "hail-master-volume" {
//  count = "${var.count}"
//  name  = "hail-${var.hail_cluster_id}-volume"
//  size  = "${var.volume_size_gb}"
//}
//
//resource "openstack_compute_volume_attach_v2" "hail-master-volume-attach" {
//  count       = "${var.count}"
//  volume_id   = "${openstack_blockstorage_volume_v2.hail-master-volume.id}"
//  instance_id = "${openstack_compute_instance_v2.hail-master.*.id[count.index]}"
//}

