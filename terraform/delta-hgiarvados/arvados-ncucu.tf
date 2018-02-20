module "arvados-master" {
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

  arvados_cluster_id   = "ncucu"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-sso" {
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

  arvados_cluster_id   = "ncucu"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-workbench" {
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

  arvados_cluster_id   = "ncucu"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-keepproxy" {
  source = "../modules/arvados-keepproxy"

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

  count              = 2
  flavour            = "m1.medium"
  domain             = "hgi.sanger.ac.uk"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  arvados_cluster_id   = "ncucu"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-keep" {
  source = "../modules/arvados-keep"

  image = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }

  count              = 4
  flavour            = "m1.medium"
  domain             = "node.hgi-delta.consul"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  arvados_cluster_id   = "ncucu"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-shell" {
  source = "../modules/arvados-shell"

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

  arvados_cluster_id   = "ncucu"
  extra_ansible_groups = ["consul-cluster-delta-hgiarvados"]
}

module "arvados-compute-node-noconf" {
  source = "../modules/arvados-compute-node-noconf"

  image = {
    name = "${var.arvados_compute_node_image_name}"
    user = "${var.arvados_compute_node_image_user}"
  }

  count              = 100
  flavour            = "m1.xlarge"
  domain             = "node.delta-hgiarvados.consul"
  security_group_ids = "${module.openstack.security_group_ids}"
  key_pair_ids       = "${module.openstack.key_pair_ids}"
  network_id         = "${module.openstack.network_id}"

  bastion = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }

  arvados_cluster_id   = "ncucu"
  extra_ansible_groups = []

  consul_datacenter     = "delta-hgiarvados"
  consul_retry_join     = "${module.consul-server.retry_join}"
  upstream_dns_servers  = ["172.18.255.1", "172.18.255.2", "172.18.255.3"] # FIXME this should be defined elsewhere
  consul_template_token = "${var.consul_template_token}"
}
