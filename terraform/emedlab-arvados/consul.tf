resource "openstack_compute_instance_v2" "consul-servers" {
  count           = 0
  name            = "consul-server-${count.index}"
  image_name      = "${var.docker_image_name}"
  flavor_name     = "m1.small"
  key_pair        = "${openstack_compute_keypair_v2.mercury_emedlab-arvados.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_emedlab-arvados.id}"]

  network {
    uuid = "${openstack_networking_network_v2.main_emedlab-arvados.id}"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]

    connection {
      timeout = "1m"
    }
  }

  # provision using ansible
  provisioner "local-exec" {
    command = "ANSIBLE_CONFIG ../ansible/ansible-minimal.cfg ansible-playbook -i ../ansible/production_hosts.d -l consul-server-${count.index} ../ansible/site.yml"
  }
}

output "consul_ips" {
  value = ["${openstack_compute_instance_v2.consul-servers.*.access_ip_v4}"]
}
