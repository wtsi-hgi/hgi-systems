module "ssh-gateway" {
  source = "../modules/ssh-gateway"
  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }
  flavour = "m1.small"
  domain = "delta-hgi.hgi.sanger.ac.uk"
  security_groups = ["${openstack_compute_secgroup_v2.ssh_delta-hgi.id}"]
  key_pair_id = "${openstack_compute_keypair_v2.mercury_delta-hgi.id}"
  network_id = "${openstack_networking_network_v2.main_delta-hgi.id}"
}
