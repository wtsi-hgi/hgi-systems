resource "openstack_compute_instance_v2" "arvados-master-delta-hgiarvados" {
  provider = "openstack.delta-hgiarvados"
  count = 1
  name = "arvados-master-delta-hgiarvados"
  image_name = "${var.debian_base_image["name"]}"
  flavor_name = "m1.xlarge"
  key_pair = "${openstack_compute_keypair_v2.mercury_delta-hgiarvados.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_delta-hgiarvados.id}"]
  network {
    uuid = "${openstack_networking_network_v2.main_delta-hgiarvados.id}"
    access_network = true
  }

  metadata = {
    ansible_groups = "arvados-masters"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname"
    ]
    connection {
      type = "ssh"
      user = "${var.debian_base_image["user"]}"
      agent = "true"
      timeout = "2m"
      bastion_host = "${openstack_compute_instance_v2.ssh-gateway-delta-hgiarvados.access_ip_v4}"
      bastion_user = "mercury"
    }
  }
}

output "arvados_master_delta-hgiarvados_ip" {
  value = "${openstack_compute_instance_v2.arvados-master-delta-hgiarvados.access_ip_v4}"
}

