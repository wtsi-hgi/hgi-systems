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

resource "openstack_networking_floatingip_v2" "spark-master" {
  provider = "openstack"
  pool     = "nova"
}

resource "openstack_compute_instance_v2" "spark-master" {
  provider    = "openstack"
  count       = "${var.count}"
  name        = "spark-${var.spark_cluster_id}-master"
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

  user_data = "#cloud-config\nhostname: spark-${var.spark_cluster_id}-master\nfqdn: spark-${var.spark_cluster_id}-master.${var.domain}"

  metadata = {
    ansible_groups = "hailers spark-masters spark-cluster-${var.spark_cluster_id}-members hgi-credentials"
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

resource "openstack_compute_floatingip_associate_v2" "spark-master" {
  provider    = "openstack"
  floating_ip = "${openstack_networking_floatingip_v2.spark-master.address}"
  instance_id = "${openstack_compute_instance_v2.spark-master.id}"
}

resource "infoblox_record" "spark-master-dns" {
  value  = "${openstack_networking_floatingip_v2.spark-master.address}"
  name   = "spark-${var.spark_cluster_id}-master"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

output "ip" {
  value = "${openstack_networking_floatingip_v2.spark-master.address}"
}

# FIXME: This is here for Hail, not Spark
resource "openstack_blockstorage_volume_v2" "spark-master-volume" {
  name = "spark-${var.spark_cluster_id}-volume"
  size = 100
}

resource "openstack_compute_volume_attach_v2" "spark-master-volume-attach" {
  volume_id   = "${openstack_blockstorage_volume_v2.spark-master-volume.id}"
  instance_id = "${openstack_compute_instance_v2.spark-master.id}"
}
