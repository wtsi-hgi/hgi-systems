variable "flavour" {}
variable "domain" {}

variable "keypair_name" {
  default = "mercury"
}

variable "network_name" {
  default = "main"
}

variable "openstack_core_context" {
  type    = "map"
  default = {}
}

variable "image" {
  type    = "map"
  default = {}
}

variable "extra_ansible_groups" {
  type    = "list"
  default = []
}

variable "floatingip_pool_name" {
  default = "nova"
}

locals {
  ansible_groups = [
    "ssh-gateways",
  ]

  keypairs        = "${var.openstack_core_context["keypairs"]}"
  security_groups = "${var.openstack_core_context["security_groups"]}"
  networks        = "${var.openstack_core_context["networks"]}"
}

resource "openstack_networking_floatingip_v2" "ssh-gateway" {
  provider = "openstack"
  pool     = "${var.floatingip_pool_name}"
}

resource "openstack_compute_instance_v2" "ssh-gateway" {
  provider    = "openstack"
  count       = 1
  name        = "ssh-gateway"
  image_id    = "${var.image["id"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${lookup(local.keypairs, var.keypair_name)}"

  security_groups = [
    "${local.security_groups["ping"]}",
    "${local.security_groups["ssh"]}",
    "${local.security_groups["consul-client"]}",
  ]

  network {
    uuid           = "${lookup(local.networks, var.network_name)}"
    access_network = true
  }

  user_data = "#cloud-config\nhostname: ssh\nfqdn: ssh.${var.domain}"

  metadata = {
    ansible_groups = "${join(" ", distinct(concat(local.ansible_groups, var.extra_ansible_groups)))}"
    user           = "${var.image["user"]}"
    bastion_host   = "${openstack_networking_floatingip_v2.ssh-gateway.address}"
    bastion_user   = "${var.image["user"]}"
  }
}

resource "openstack_compute_floatingip_associate_v2" "ssh-gateway" {
  floating_ip = "${openstack_networking_floatingip_v2.ssh-gateway.address}"
  instance_id = "${openstack_compute_instance_v2.ssh-gateway.id}"
}

resource "infoblox_record" "ssh-gateway" {
  value  = "${openstack_compute_floatingip_associate_v2.ssh-gateway.floating_ip}"
  name   = "ssh"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
  view   = "internal"
}

resource "null_resource" "ssh-gateway" {
  triggers {
    ssh-host = "${openstack_compute_instance_v2.ssh-gateway.id}"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]

    connection {
      type    = "ssh"
      host    = "${openstack_compute_floatingip_associate_v2.ssh-gateway.floating_ip}"
      user    = "${var.image["user"]}"
      agent   = "true"
      timeout = "2m"
    }
  }
}

output "host" {
  value = "${openstack_compute_floatingip_associate_v2.ssh-gateway.floating_ip}"
}

output "user" {
  value = "${var.image["user"]}"
}
