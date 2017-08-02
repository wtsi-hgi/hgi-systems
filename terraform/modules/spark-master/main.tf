variable "flavour" {}
variable "domain" {}
variable "network_id" {}
variable "spark_cluster_id" {}

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

resource "openstack_compute_floatingip_v2" "spark-master" {
  provider = "openstack"
  pool     = "nova"
}

resource "openstack_compute_instance_v2" "spark-master" {
  provider        = "openstack"
  count           = 1
  name            = "spark-${var.spark_cluster_id}-master"
  image_name      = "${var.image["name"]}"
  flavor_name     = "${var.flavour}"
  key_pair        = "${var.key_pair_ids["mercury"]}"
  security_groups = ["${var.security_group_ids["ssh"]}", "${var.security_group_ids["https"]}", "${var.security_group_ids["tcp-local"]}", "${var.security_group_ids["udp-local"]}"]

  network {
    uuid           = "${var.network_id}"
    floating_ip    = "${openstack_compute_floatingip_v2.spark-master.address}"
    access_network = true
  }

  metadata = {
    ansible_groups = "spark-masters spark-cluster-${var.spark_cluster_id}-members hgi-credentials"
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

resource "infoblox_record" "spark-master-dns" {
  value  = "${openstack_compute_instance_v2.spark-master.access_ip_v4}"
  name   = "spark-${var.spark_cluster_id}-master"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

output "ip" {
  value = "${openstack_compute_instance_v2.spark-master.access_ip_v4}"
}
