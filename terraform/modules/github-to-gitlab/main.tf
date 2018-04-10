variable "flavour" {}
variable "domain" {}
variable "network_id" {}
variable "github2gitlab_cluster_id" {}
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
  default = 250
}

locals {
  ansible_groups = [
    "github2gitlabs",
  ]
}

resource "openstack_networking_floatingip_v2" "github2gitlab" {
  provider = "openstack"
  pool     = "nova"
}

resource "openstack_compute_instance_v2" "github2gitlab" {
  provider    = "openstack"
  name        = "github2gitlab-${var.github2gitlab_cluster_id}"
  image_name  = "${var.image["name"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${var.key_pair_ids["mercury"]}"

  security_groups = [
    "${var.security_group_ids["ping"]}",
    "${var.security_group_ids["ssh"]}",
    "${var.security_group_ids["http"]}",
    "${var.security_group_ids["github2gitlab"]}",
  ]

  network {
    uuid           = "${var.network_id}"
    access_network = true
  }

  user_data = "#cloud-config\nhostname: github2gitlab-${var.github2gitlab_cluster_id}\nfqdn: github2gitlab-${var.github2gitlab_cluster_id}.${var.domain}"

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

resource "openstack_compute_floatingip_associate_v2" "github2gitlab" {
  provider    = "openstack"
  floating_ip = "${openstack_networking_floatingip_v2.github2gitlab.address}"
  instance_id = "${openstack_compute_instance_v2.github2gitlab.id}"
}

resource "infoblox_record" "github2gitlab" {
  value  = "${openstack_networking_floatingip_v2.github2gitlab.address}"
  name   = "github2gitlab-${var.github2gitlab_cluster_id}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
  view   = "internal"
}

output "ip" {
  value = "${openstack_networking_floatingip_v2.github2gitlab.address}"
}

resource "openstack_blockstorage_volume_v2" "github2gitlab-volume" {
  count = "${var.count}"
  name  = "github2gitlab-${var.github2gitlab_cluster_id}-volume"
  size  = "${var.volume_size_gb}"
}

resource "openstack_compute_volume_attach_v2" "github2gitlab-volume-attach" {
  count       = "${var.count}"
  volume_id   = "${openstack_blockstorage_volume_v2.github2gitlab-volume.id}"
  instance_id = "${openstack_compute_instance_v2.github2gitlab.*.id[count.index]}"
}
