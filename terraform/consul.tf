resource "openstack_compute_instance_v2" "consul-servers" {
  provider = "openstack.hgiarvados"
  name = "consul-server-${count.index}"
  image_name = "${var.docker_image_name}"
  flavor_name = "m1.small"
  key_pair = "${openstack_compute_keypair_v2.mercury_hgiarvados.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_hgiarvados.id}"]
  count = 0
}

output "consul_ips" {
  value = ["${openstack_compute_instance_v2.consul-servers.*.access_ip_v4}"]
}
