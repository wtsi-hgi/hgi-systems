module "hail-master-as45" {
  source          = "../modules/hail/master/hail-master-v2"
  hail_cluster_id = "as45"
  count           = 1
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${data.terraform_remote_state.hgi-core.core_context}"
  domain          = "hgi.sanger.ac.uk"
  image           = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  network_name    = "main"
  ssh_gateway     = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  flavour         = "o1.large"
  volume_size_gb  = 100
}

module "hail-compute-as45" {
  source          = "../modules/hail/compute/hail-compute-v2"
  hail_cluster_id = "as45"
  count           = 5
  env             = "${var.env}"
  region          = "${var.region}"
  setup           = "${var.setup}"
  core_context    = "${data.terraform_remote_state.hgi-core.core_context}"
  domain          = "hgi.sanger.ac.uk"
  image           = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  network_name    = "main"
  ssh_gateway     = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  flavour         = "o1.large"
}
