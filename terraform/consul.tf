resource "openstack_compute_instance_v2" "consul-servers" {
  count = 3
  provider = "openstack.hgiarvados"
  name = "consul-server-${count.index}"
  image_name = "${var.docker_image_name}"
  flavor_name = "m1.small"
  key_pair = "${openstack_compute_keypair_v2.mercury_hgiarvados.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_hgiarvados.id}"]
  network {
    uuid = "${openstack_networking_network_v2.main_hgiarvados.id}"
    access_network = true
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname"
    ]
  }
  # provision using ansible
  provisioner "local-exec" {
    command = "ANSIBLE_CONFIG ../ansible/ansible-minimal.cfg ansible-playbook -i ../ansible/production_hosts.d -l consul-server-${count.index} ../ansible/site.yml"
  }
}

output "consul_ips" {
  value = ["${openstack_compute_instance_v2.consul-servers.*.access_ip_v4}"]
}
