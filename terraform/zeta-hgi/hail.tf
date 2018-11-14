module "hail-cluster-as45" {
  source       = "../modules/hail/v1/cluster"
  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${data.terraform_remote_state.hgi-core.core_context}"
  ssh_gateway  = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  domain       = "hgi.sanger.ac.uk"
  network_name = "main"

  hail_cluster_id        = "as45"
  master_count           = 1
  compute_count          = 1
  master_image           = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  compute_image          = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  master_flavour         = "o1.large"
  compute_flavour        = "o1.large"
  master_volume_size_gb  = 100
  compute_volume_size_gb = 100
}

module "hail-cluster-as45-2" {
  source       = "../modules/hail/v2/cluster"
  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${data.terraform_remote_state.hgi-core.core_context}"
  ssh_gateway  = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  domain       = "hgi.sanger.ac.uk"
  network_name = "main"

  hail_cluster_id        = "as45-2"
  master_count           = 1
  compute_count          = 7
  master_image           = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  compute_image          = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  master_flavour         = "o1.3xlarge"
  compute_flavour        = "o1.3xlarge"
  master_volume_size_gb  = 100
  compute_volume_size_gb = 100
}

module "hail-cluster-as45-3" {
  source       = "../modules/hail/v2/cluster"
  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${data.terraform_remote_state.hgi-core.core_context}"
  ssh_gateway  = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  domain       = "hgi.sanger.ac.uk"
  network_name = "main"

  hail_cluster_id        = "as45-3"
  master_count           = 1
  compute_count          = 1
  master_image           = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  compute_image          = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  master_flavour         = "o1.3xlarge"
  compute_flavour        = "o1.3xlarge"
  master_volume_size_gb  = 100
  compute_volume_size_gb = 100
}
