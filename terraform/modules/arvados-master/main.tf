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

resource "openstack_compute_floatingip_v2" "arvados-master" {
  provider = "openstack"
  pool     = "nova"
}

resource "openstack_compute_instance_v2" "arvados-master" {
  provider        = "openstack"
  count           = 1
  name            = "arvados-master"
  image_name      = "${var.image["name"]}"
  flavor_name     = "${var.flavour}"
  key_pair        = "${var.key_pair_ids["mercury"]}"
  security_groups = ["${var.security_group_ids["ssh"]}"]

  network {
    uuid           = "${var.network_id}"
    floating_ip    = "${openstack_compute_floatingip_v2.arvados-master.address}"
    access_network = true
  }

  metadata = {
    ansible_groups = "arvados-masters arvados-cluster-${var.arvados_cluster_id} hgi-credentials"
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

resource "infoblox_record" "arvados-master" {
  value  = "${openstack_compute_instance_v2.arvados-master.access_ip_v4}"
  name   = "arvados-api-${var.arvados_cluster_id}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

resource "infoblox_record" "arvados-master" {
  value  = "${openstack_compute_instance_v2.arvados-master.access_ip_v4}"
  name   = "arvados-ws-${var.arvados_cluster_id}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

resource "infoblox_record" "arvados-master" {
  value  = "${openstack_compute_instance_v2.arvados-master.access_ip_v4}"
  name   = "arvados-git-${var.arvados_cluster_id}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

resource "infoblox_record" "arvados-master" {
  value  = "${openstack_compute_instance_v2.arvados-master.access_ip_v4}"
  name   = "arvados-workbench-${var.arvados_cluster_id}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

output "ip" {
  value = "${openstack_compute_instance_v2.arvados-master.access_ip_v4}"
}
