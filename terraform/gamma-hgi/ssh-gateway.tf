resource "openstack_compute_floatingip_v2" "ssh-gateway-gamma-hgi" {
  provider = "openstack.gamma-hgi"
  pool = "nova"
}

resource "openstack_compute_instance_v2" "ssh-gateway-gamma-hgi" {
  provider = "openstack.gamma-hgi"
  count = 1
  name = "ssh-gateway-gamma-hgi"
  image_name = "${var.base_image_name}"
  flavor_name = "m1.small"
  key_pair = "${openstack_compute_keypair_v2.mercury_gamma-hgi.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_gamma-hgi.id}"]
  network {
    uuid = "${openstack_networking_network_v2.main_gamma-hgi.id}"
    floating_ip = "${openstack_compute_floatingip_v2.ssh-gateway-gamma-hgi.address}"
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
    command = "ANSIBLE_CONFIG=../../ansible/ansible-minimal.cfg ansible-playbook -i ../../ansible/production_hosts.d -l 'openstack_compute_instance_v2.ssh-gateway-gamma-hgi' ../../ansible/site.yml"
  }
}

output "ssh_gateway_gamma-hgi_ip" {
  value = "${openstack_compute_instance_v2.ssh-gateway-gamma-hgi.access_ip_v4}"
}
