module "arvados-master-wlly8" {
  source = "../modules/arvados-master"

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

  flavour            = "m1.xlarge"
  domain             = "hgi.sanger.ac.uk"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  arvados_cluster_id   = "wlly8"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-sso-wlly8" {
  source = "../modules/arvados-sso"

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

  flavour            = "m1.medium"
  domain             = "hgi.sanger.ac.uk"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  arvados_cluster_id   = "wlly8"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-workbench-wlly8" {
  source = "../modules/arvados-workbench"

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

  flavour            = "m1.medium"
  domain             = "hgi.sanger.ac.uk"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  arvados_cluster_id   = "wlly8"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-keepproxy-wlly8" {
  source = "../modules/arvados-keepproxy"

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

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

  arvados_cluster_id   = "wlly8"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-keep-wlly8" {
  source = "../modules/arvados-keep"

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

  count              = 1
  flavour            = "m1.medium"
  domain             = "node.hgi-delta.consul"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  arvados_cluster_id   = "wlly8"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-shell-wlly8" {
  source = "../modules/arvados-shell"

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

  flavour            = "m1.small"
  domain             = "hgi.sanger.ac.uk"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  arvados_cluster_id   = "wlly8"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-compute-node-wlly8" {
  source = "../modules/arvados-compute-node"

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

  count              = 1
  flavour            = "m1.xlarge"
  domain             = "node.hgi-delta.consul"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  arvados_cluster_id   = "wlly8"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}
