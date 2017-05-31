module "ssh-gateway" {
  source = "../modules/ssh-gateway"
  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }
  flavour = "m1.small"
  domain = "delta-hgiarvados.hgi.sanger.ac.uk"
  security_group_ids = "${root.security_group_ids}"
  key_pair_ids = "${root.key_pair_ids}"
  network_id = "${openstack_networking_network_v2.main_delta-hgiarvados.id}"
}
