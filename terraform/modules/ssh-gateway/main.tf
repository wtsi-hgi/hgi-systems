variable "flavour" {}
variable "domain" {}
variable "key_pair_id" {}
variable "network_id" {}
variable "security_groups" {
  type = "list"
  default = ["food"]
}
variable "image" {
  type = "map"
  default = {}
}

resource "openstack_compute_floatingip_v2" "ssh-gateway" {
  provider = "openstack"
  pool = "nova"
}

resource "openstack_compute_instance_v2" "ssh-gateway" {
  provider = "openstack"
  count = 1
  name = "ssh-gateway"
  image_name = "${var.image["name"]}"
  flavor_name = "${var.flavour}"
  key_pair = "${var.key_pair_id}"
  security_groups = "${var.security_groups}"
  network {
    uuid = "${var.network_id}"
    floating_ip = "${openstack_compute_floatingip_v2.ssh-gateway.address}"
    access_network = true
  }

  metadata = {
    ansible_groups = "ssh_gateways"
    user = "${var.image["user"]}"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname"
    ]
    connection {
      type = "ssh"
      user = "${var.image["user"]}"
      agent = "true"
      timeout = "2m"
    }
  }
}

resource "infoblox_record" "ssh-gateway" {
  value = "${openstack_compute_instance_v2.ssh-gateway.access_ip_v4}"
  name = "ssh"
  domain = "${var.domain}"
  type = "A"
  ttl = 600
}

output "host" {
  value = "${openstack_compute_instance_v2.ssh-gateway.access_ip_v4}"
}

output "user" {
  value = "${var.image["user"]}"
}

