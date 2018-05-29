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
    "hail-computers",
    "hail-cluster-${var.hail_cluster_id}",
    "hgi-credentials",
  ]

  hostname_format = "${format("hail-%s-compute", var.hail_cluster_id)}-%02d"
}

module "hgi-openstack-instance" {
  source          = "../../../hgi-openstack-instance"
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${var.core_context}"
  count           = "${var.count}"
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

//resource "openstack_compute_instance_v2" "hail-compute" {
//  provider    = "openstack"
//  count       = "${var.count}"
//  name        = "hail-${var.hail_cluster_id}-compute-${count.index}"
//  image_name  = "${var.image["name"]}"
//  flavor_name = "${var.flavour}"
//  key_pair    = "${var.key_pair_ids["mercury"]}"
//
//  security_groups = [
//    "${var.security_group_ids["ping"]}",
//    "${var.security_group_ids["ssh"]}",
//    "${var.security_group_ids["https"]}",
//    "${var.security_group_ids["tcp-local"]}",
//    "${var.security_group_ids["udp-local"]}",
//  ]
//
//  network {
//    uuid           = "${var.network_id}"
//    access_network = true
//  }
//
//  user_data = "#cloud-config\nhostname: hail-${var.hail_cluster_id}-compute-${count.index}\nfqdn: hail-${var.hail_cluster_id}-compute-${count.index}.${var.domain}"
//
//  metadata = {
//    ansible_groups = "${join(" ", distinct(concat(local.ansible_groups, var.extra_ansible_groups)))}"
//    user           = "${var.image["user"]}"
//    bastion_host   = "${var.bastion["host"]}"
//    bastion_user   = "${var.bastion["user"]}"
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
//output "ip" {
//  value = "${openstack_compute_instance_v2.hail-compute.*.access_ip_v4}"
//}

