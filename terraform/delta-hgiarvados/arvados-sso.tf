resource "openstack_compute_instance_v2" "arvados-sso-delta-hgiarvados" {
  provider = "openstack"
  count = 1
  name = "arvados-sso-delta-hgiarvados"
  image_name = "${var.arvados_base_image_name}"
  flavor_name = "m1.medium"
  key_pair = "${module.openstack.key_pair_ids["mercury"]}"
  security_groups = ["${module.openstack.security_group_ids["ssh"]}"]
  network {
    uuid = "${module.openstack.network_id}"
    access_network = true
  }

  metadata = {
    ansible_groups = "arvados-ssos,arvados-cluster-ncucu"
    user = "${var.arvados_base_image_user}"
    bastion_host = "${module.ssh-gateway.host}"
    bastion_user = "${module.ssh-gateway.user}"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname"
    ]
    connection {
      type = "ssh"
      user = "${var.arvados_base_image_user}"
      agent = "true"
      timeout = "2m"
      bastion_host = "${module.ssh-gateway.host}"
      bastion_user = "${module.ssh-gateway.user}"
    }
  }
}

output "arvados_sso_delta-hgiarvados_ip" {
  value = "${module.openstack.openstack_compute_instance_v2.arvados-sso-delta-hgiarvados.access_ip_v4}"
}

