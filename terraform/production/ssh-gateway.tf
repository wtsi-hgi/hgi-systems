resource "openstack_compute_floatingip_v2" "ssh-gateway-hgiarvados" {
  provider = "openstack.hgiarvados"
  pool = "nova"
}

resource "openstack_compute_instance_v2" "ssh-gateway-hgiarvados" {
  provider = "openstack.hgiarvados"
  count = 1
  name = "ssh-gateway-hgiarvados"
  image_name = "${var.base_image_name}"
  flavor_name = "m1.small"
  key_pair = "${openstack_compute_keypair_v2.mercury_hgiarvados.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_hgiarvados.id}"]
  network {
    uuid = "${openstack_networking_network_v2.main_hgiarvados.id}"
    floating_ip = "${openstack_compute_floatingip_v2.ssh-gateway-hgiarvados.address}"
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
      timeout = "1m"
    }
  }
  # provision using ansible
  provisioner "local-exec" {
    command = "ANSIBLE_CONFIG=../../ansible/ansible-minimal.cfg ansible-playbook -i ../../ansible/production_hosts.d -l ssh-gateway-hgiarvados ../../ansible/site.yml"
  }
}

output "ssh_gateway_hgiarvados_ip" {
  value = "${openstack_compute_instance_v2.ssh-gateway-hgiarvados.access_ip_v4}"
}

### TODO this should be a module parameterised on hgi/hgiarvados

resource "openstack_compute_floatingip_v2" "ssh-gateway-hgi" {
  provider = "openstack.hgi"
  pool = "nova"
}

resource "openstack_compute_instance_v2" "ssh-gateway-hgi" {
  provider = "openstack.hgi"
  count = 1
  name = "ssh-gateway-hgi"
  image_name = "${var.base_image_name}"
  flavor_name = "m1.small"
  key_pair = "${openstack_compute_keypair_v2.mercury_hgi.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_hgi.id}"]
  network {
    uuid = "${openstack_networking_network_v2.main_hgi.id}"
    floating_ip = "${openstack_compute_floatingip_v2.ssh-gateway-hgi.address}"
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
      timeout = "1m"
    }
  }
  # provision using ansible
  provisioner "local-exec" {
    command = "ANSIBLE_CONFIG=../../ansible/ansible-minimal.cfg ansible-playbook -i ../../ansible/production_hosts.d -l ssh-gateway-hgi ../../ansible/site.yml"
  }
}

output "ssh_gateway_hgi_ip" {
  value = "${openstack_compute_instance_v2.ssh-gateway-hgi.access_ip_v4}"
}
