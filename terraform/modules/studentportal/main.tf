variable "flavour" {}
variable "domain" {}
variable "network_id" {}
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

resource "openstack_networking_floatingip_v2" "studentportal" {
  provider = "openstack"
  pool     = "nova"
  count    = "${var.count}"
}

resource "openstack_compute_instance_v2" "studentportal" {
  provider    = "openstack"
  count       = "${var.count}"
  name        = "studentportal-${count.index + 1}"
  image_name  = "${var.image["name"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${var.key_pair_ids["mercury"]}"

  security_groups = [
    "${var.security_group_ids["ping"]}",
    "${var.security_group_ids["ssh"]}",
    "${var.security_group_ids["http"]}",
  ]

  network {
    uuid           = "${var.network_id}"
    access_network = true
  }

  user_data = "#cloud-config\nhostname: studentportal-${count.index + 1}\nfqdn: studentportal-${count.index + 1}.${var.domain}"

  metadata = {
    ansible_groups = "dockerers"
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

resource "openstack_compute_floatingip_associate_v2" "studentportal" {
  provider    = "openstack"
  count       = "${var.count}"
  floating_ip = "${openstack_networking_floatingip_v2.studentportal.*.address[count.index]}"
  instance_id = "${openstack_compute_instance_v2.studentportal.*.id[count.index]}"
}

resource "infoblox_record" "studentportal" {
  count  = "${var.count}"
  value  = "${openstack_networking_floatingip_v2.studentportal.*.address[count.index]}"
  name   = "studentportal-${count.index + 1}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
  view   = "internal"
}

output "ip" {
  value = "${openstack_networking_floatingip_v2.studentportal.address}"
}
