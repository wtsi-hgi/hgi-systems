module "hail-cluster-as45" {
  source       = "../modules/hail/cluster/hail-cluster-v1"
  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${data.terraform_remote_state.hgi-core.core_context}"
  ssh_gateway  = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  domain       = "hgi.sanger.ac.uk"
  network_name = "main"

  hail_cluster_id       = "as45"
  master_count          = 1
  compute_count         = 2
  master_image          = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  compute_image         = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  master_flavour        = "o1.large"
  compute_flavour       = "o1.large"
  master_volume_size_gb = 100
  scratch_volume_p      = false
}

module "hail-cluster-as45-2" {
  source       = "../modules/hail/cluster/hail-cluster-v1"
  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${data.terraform_remote_state.hgi-core.core_context}"
  ssh_gateway  = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  domain       = "hgi.sanger.ac.uk"
  network_name = "main"

  hail_cluster_id        = "as45-2"
  master_count           = 1
  compute_count          = 5
  master_image           = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  compute_image          = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  master_flavour         = "o1.large"
  compute_flavour        = "o1.large"
  master_volume_size_gb  = 100
  scratch_volume_size_gb = 100
}

module "hail-cluster-mercury" {
  source       = "../modules/hail/cluster/hail-cluster-v1"
  env          = "${var.env}"
  region       = "${var.region}"
  setup        = "${var.setup}"
  core_context = "${data.terraform_remote_state.hgi-core.core_context}"
  ssh_gateway  = "${data.terraform_remote_state.hgi-core.ssh_gateway}"
  domain       = "hgi.sanger.ac.uk"
  network_name = "main"

  hail_cluster_id        = "mercury"
  master_count           = 1
  compute_count          = 1
  master_image           = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-3ddcb29b}"
  compute_image          = "${data.terraform_remote_state.hgi-core.hgi-openstack-image-hgi-docker-xenial-3ddcb29b}"
  master_flavour         = "o1.medium"
  compute_flavour        = "o1.medium"
  master_volume_size_gb  = 20
  scratch_volume_size_gb = 20
}
