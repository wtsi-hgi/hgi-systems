module "hail-master-ew7" {
  source = "../modules/hail-master"
  count  = 1

  image = {
    name = "hgi-base-xenial-d806d486"
    user = "ubuntu"
  }

  flavour            = "m1.large"
  domain             = "hgi.sanger.ac.uk"
  security_group_ids = "${data.terraform_remote_state.hgi-core.openstack_security_group_ids}"
  key_pair_ids       = "${data.terraform_remote_state.hgi-core.openstack_key_pair_ids}"
  network_id         = "${data.terraform_remote_state.hgi-core.openstack_network_id}"

  bastion = {
    host = "${data.terraform_remote_state.hgi-core.ssh_gateway_host}"
    user = "${data.terraform_remote_state.hgi-core.ssh_gateway_user}"
  }

  extra_ansible_groups = ["consul-cluster-delta-hgi"]
  hail_cluster_id      = "ew7"
}

module "hail-compute-ew7" {
  source = "../modules/hail-compute"
  count  = 1

  image = {
    name = "hgi-base-xenial-d806d486"
    user = "ubuntu"
  }

  flavour            = "m1.large"
  domain             = "hgi.sanger.ac.uk"
  security_group_ids = "${data.terraform_remote_state.hgi-core.openstack_security_group_ids}"
  key_pair_ids       = "${data.terraform_remote_state.hgi-core.openstack_key_pair_ids}"
  network_id         = "${data.terraform_remote_state.hgi-core.openstack_network_id}"

  bastion = {
    host = "${data.terraform_remote_state.hgi-core.ssh_gateway_host}"
    user = "${data.terraform_remote_state.hgi-core.ssh_gateway_user}"
  }

  extra_ansible_groups = ["consul-cluster-delta-hgi"]
  hail_cluster_id      = "ew7"
}
