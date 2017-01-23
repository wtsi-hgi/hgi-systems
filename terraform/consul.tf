resource "openstack_compute_instance_v2" "consul-servers" {
  name = "consul-server-${count.index}"
  image_name = "${var.docker_image_name}"
  flavor_name = "m1.small"
  key_pair = "${openstack_compute_keypair_v2.mercury.id}"
  security_groups = ["${openstack_compute_secgroup_v2.ssh.id}"]
  count = 5
}

output "consul_ips" {
  value = ["${openstack_compute_instance_v2.consul-servers.*.access_ip_v4}"]
}
