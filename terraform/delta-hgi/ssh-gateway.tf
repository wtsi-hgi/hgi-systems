resource "openstack_compute_floatingip_v2" "ssh-gateway-delta-hgi" {
  provider = "openstack.delta-hgi"
  pool = "nova"
}

resource "openstack_compute_instance_v2" "ssh-gateway-delta-hgi" {
  provider = "openstack.delta-hgi"
  count = 1
  name = "ssh-gateway-delta-hgi"
  image_name = "${var.base_image["name"]}"
  flavor_name = "m1.small"
  key_pair = "${openstack_compute_keypair_v2.mercury_delta-hgi.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_delta-hgi.id}"]
  network {
    uuid = "${openstack_networking_network_v2.main_delta-hgi.id}"
    floating_ip = "${openstack_compute_floatingip_v2.ssh-gateway-delta-hgi.address}"
    access_network = true
  }

  metadata = {
    ansible_groups = "ssh_gateways"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname"
    ]
    connection {
      type = "ssh"
      user = "${var.base_image["user"]}"
      agent = "true"
      timeout = "2m"
    }
  }
}

resource "infoblox_record" "ssh-gateway-delta-hgi" {
  value = "${openstack_compute_instance_v2.ssh-gateway-delta-hgi.access_ip_v4}"
  name = "ssh"
  domain = "delta-hgi.hgi.sanger.ac.uk"
  type = "A"
  ttl = 3600
}

output "ssh_gateway_delta-hgi_ip" {
  value = "${openstack_compute_instance_v2.ssh-gateway-delta-hgi.access_ip_v4}"
}
