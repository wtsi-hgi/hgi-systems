variable "flavour" {}
variable "domain" {}
variable "network_id" {}
variable "spark_cluster_id" {}
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

locals {
  ansible_groups = [
    "hail-computers",
    "spark-cluster-${var.spark_cluster_id}-members",
    "consul-agents",
    "hgi-credentials",
  ]
}

resource "openstack_compute_instance_v2" "spark-compute" {
  provider    = "openstack"
  count       = "${var.count}"
  name        = "spark-${var.spark_cluster_id}-compute-${count.index}"
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

  user_data = "#cloud-config\nhostname: spark-${var.spark_cluster_id}-compute-${count.index}\nfqdn: spark-${var.spark_cluster_id}-compute-${count.index}.${var.domain}"

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

#resource "infoblox_record" "spark-compute-dns" {
#  count  = "${var.count}"
#  value  = "${openstack_compute_instance_v2.spark-compute.*.access_ip_v4[count.index]}"
#  name   = "spark-${var.spark_cluster_id}-compute-${count.index}"
#  domain = "${var.domain}"
#  type   = "A"
#  ttl    = 600
#}

output "ip" {
  value = "${openstack_compute_instance_v2.spark-compute.access_ip_v4}"
}
