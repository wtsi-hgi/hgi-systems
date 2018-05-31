module "studentportal" {
  source       = "../modules/studentportal/studentportal-v2"
  count        = 1
  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${data.terraform_remote_state.hgi-core.core_context}"
  domain       = "hgi.sanger.ac.uk"
  image        = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-base-xenial-4cb02ffa}"
  network_name = "main"
  ssh_gateway  = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  flavour      = "o1.small"
}
