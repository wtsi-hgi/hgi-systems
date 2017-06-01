module "ssh-gateway" {
  source = "../modules/ssh-gateway"
  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }
  flavour = "m1.small"
  domain = "delta-hgiarvados.hgi.sanger.ac.uk"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids = "${module.openstack.key_pair_ids}"
  network_id = "${module.openstack.network_id}"
}
