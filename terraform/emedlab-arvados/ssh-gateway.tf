resource "openstack_compute_floatingip_v2" "ssh-gateway-emedlab-arvados" {
  provider = "openstack.emedlab-arvados"
  pool = "nova"
}

resource "openstack_compute_instance_v2" "ssh-gateway-emedlab-arvados" {
  provider = "openstack.emedlab-arvados"
  count = 1
  name = "ssh-gateway-emedlab-arvados"
  image_name = "${var.base_image_name}"
  flavor_name = "m1.small"
  key_pair = "${openstack_compute_keypair_v2.mercury_emedlab-arvados.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_emedlab-arvados.id}"]
  network {
    uuid = "${openstack_networking_network_v2.main_emedlab-arvados.id}"
    floating_ip = "${openstack_compute_floatingip_v2.ssh-gateway-emedlab-arvados.address}"
    access_network = true
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
  # provision using ansible
  provisioner "local-exec" {
    command = "ANSIBLE_CONFIG=../../ansible/ansible-minimal.cfg ansible-playbook -i ../../ansible/production_hosts.d -l 'openstack_compute_instance_v2.ssh-gateway-emedlab-arvados' ../../ansible/site.yml"
  }
}

output "ssh_gateway_emedlab-arvados_ip" {
  value = "${openstack_compute_instance_v2.ssh-gateway-emedlab-arvados.access_ip_v4}"
}

