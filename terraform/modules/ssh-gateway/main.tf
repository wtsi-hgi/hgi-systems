variable "flavour" {}
variable "domain" {}
variable "network_id" {}

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

resource "openstack_networking_floatingip_v2" "ssh-gateway" {
  provider = "openstack"
  pool     = "nova"
}

resource "openstack_compute_instance_v2" "ssh-gateway" {
  provider        = "openstack"
  count           = 1
  name            = "ssh-gateway"
  image_name      = "${var.image["name"]}"
  flavor_name     = "${var.flavour}"
  key_pair        = "${var.key_pair_ids["mercury"]}"
  security_groups = ["${var.security_group_ids["ssh"]}"]

  network {
    uuid           = "${var.network_id}"
    access_network = true
  }

  user_data = "#cloud-config\nhostname: ssh\nfqdn: ssh.${var.domain}"

  metadata = {
    ansible_groups = "ssh-gateways"
    user           = "${var.image["user"]}"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]

    connection {
      type    = "ssh"
      user    = "${var.image["user"]}"
      agent   = "true"
      timeout = "2m"
    }
  }
}

resource "openstack_compute_floatingip_associate_v2" "ssh-gateway" {
    floating_ip = "${openstack_networking_floatingip_v2.ssh-gateway.address}"
    instance_id = "${openstack_compute_instance_v2.ssh-gateway.id}"
}

resource "infoblox_record" "ssh-gateway" {
  value  = "${openstack_compute_instance_v2.ssh-gateway.access_ip_v4}"
  name   = "ssh"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

output "host" {
  value      = "${openstack_compute_instance_v2.ssh-gateway.access_ip_v4}"
  depends_on = ["${openstack_compute_instance_v2.ssh-gateway}"]
}

output "user" {
  value = "${var.image["user"]}"
}
