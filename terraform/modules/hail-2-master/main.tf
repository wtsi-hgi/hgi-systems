variable "flavour" {}
variable "domain" {}
variable "network_id" {}
variable "hail_cluster_id" {}
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

variable "extra_ansible_groups" {
  type    = "list"
  default = []
}

variable "volume_size_gb" {
  default = 20
}

locals {
  ansible_groups = [
    "hail-2-masters",
    "hail-cluster-${var.hail_cluster_id}",
    "consul-agents",
    "hgi-credentials",
  ]
}

resource "openstack_networking_floatingip_v2" "hail-master" {
  provider = "openstack"
  count    = "${var.count}"
  pool     = "nova"
}

resource "openstack_compute_instance_v2" "hail-master" {
  provider    = "openstack"
  count       = "${var.count}"
  name        = "hail-${var.hail_cluster_id}-master"
  image_name  = "${var.image["name"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${var.key_pair_ids["mercury"]}"

  security_groups = [
    "${var.security_group_ids["ping"]}",
    "${var.security_group_ids["ssh"]}",
    "${var.security_group_ids["https"]}",
    "${var.security_group_ids["tcp-local"]}",
    "${var.security_group_ids["udp-local"]}",
  ]

  network {
    uuid           = "${var.network_id}"
    access_network = true
  }

  user_data = "#cloud-config\nhostname: hail-${var.hail_cluster_id}-master\nfqdn: hail-${var.hail_cluster_id}-master.${var.domain}"

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

resource "openstack_compute_floatingip_associate_v2" "hail-master" {
  provider    = "openstack"
  count       = "${var.count}"
  floating_ip = "${openstack_networking_floatingip_v2.hail-master.*.address[count.index]}"
  instance_id = "${openstack_compute_instance_v2.hail-master.*.id[count.index]}"
}

resource "infoblox_record" "hail-master-dns" {
  count  = "${var.count}"
  value  = "${openstack_networking_floatingip_v2.hail-master.*.address[count.index]}"
  name   = "hail-${var.hail_cluster_id}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
  view   = "internal"
}

output "ip" {
  value = "${openstack_networking_floatingip_v2.hail-master.*.address}"
}

resource "openstack_blockstorage_volume_v2" "hail-master-volume" {
  count = "${var.count}"
  name  = "hail-${var.hail_cluster_id}-volume"
  size  = "${var.volume_size_gb}"
}

resource "openstack_compute_volume_attach_v2" "hail-master-volume-attach" {
  count       = "${var.count}"
  volume_id   = "${openstack_blockstorage_volume_v2.hail-master-volume.id}"
  instance_id = "${openstack_compute_instance_v2.hail-master.*.id[count.index]}"
}
