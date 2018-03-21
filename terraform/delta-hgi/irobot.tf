module "irobot" {
  source = "../modules/irobot"

  image = {
    name = "hgi-docker-xenial-926b0ea4"
    user = "${var.docker_image_user}"
  }

  irobot_cluster_id  = "test"
  count              = 1
  flavour            = "m1.medium"
  domain             = "hgi.sanger.ac.uk"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }
}
