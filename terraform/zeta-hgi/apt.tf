module "apt" {
  source         = "../modules/apt/v1"
  env            = "${var.env}"
  region         = "${var.region}"
  setup          = "${var.setup}"
  core_context   = "${data.terraform_remote_state.hgi-core.core_context}"
  ssh_gateway    = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  domain         = "hgi.sanger.ac.uk"
  network_name   = "main"
  image          = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  flavour        = "o1.medium"
  volume_size_gb = 5000
}
