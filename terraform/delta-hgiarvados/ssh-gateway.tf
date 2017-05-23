resource "openstack_compute_floatingip_v2" "ssh-gateway-delta-hgiarvados" {
  provider = "openstack.delta-hgiarvados"
  pool = "nova"
}

resource "openstack_compute_instance_v2" "ssh-gateway-delta-hgiarvados" {
  provider = "openstack.delta-hgiarvados"
  count = 1
  name = "ssh-gateway-delta-hgiarvados"
  image_name = "${var.base_image_name}"
  flavor_name = "m1.small"
  key_pair = "${openstack_compute_keypair_v2.mercury_delta-hgiarvados.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_delta-hgiarvados.id}"]
  network {
    uuid = "${openstack_networking_network_v2.main_delta-hgiarvados.id}"
    floating_ip = "${openstack_compute_floatingip_v2.ssh-gateway-delta-hgiarvados.address}"
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
      user = "ubuntu"
      agent = "true"
      timeout = "2m"
    }
  }
}

resource "infoblox_record" "ssh-gateway-delta-hgiarvados" {
  value = "${openstack_compute_instance_v2.ssh-gateway-delta-hgiarvados.access_ip_v4}"
  name = "ssh"
  domain = "delta-hgiarvados.hgi.sanger.ac.uk"
  type = "A"
  ttl = 3600
}

output "ssh_gateway_delta-hgiarvados_ip" {
  value = "${openstack_compute_instance_v2.ssh-gateway-delta-hgiarvados.access_ip_v4}"
}

