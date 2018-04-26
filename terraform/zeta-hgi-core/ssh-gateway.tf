module "ssh-gateway" {
  source = "../modules/ssh-gateway"

  image = {
    name = "hgi-base-freebsd11-575611a5"
    user = "beastie"
  }

  flavour              = "m1.small"
  domain               = "zeta-hgi.hgi.sanger.ac.uk"
  security_group_ids   = "${module.openstack.security_group_ids}"
  key_pair_ids         = "${module.openstack.key_pair_ids}"
  network_id           = "${module.openstack.network_id}"
  floatingip_pool_name = "${var.openstack_floatingip_pool_name}"

  extra_ansible_groups = ["docker-consul-cluster-zeta-hgi"]
}

output "ssh_gateway_host" {
  value = "${module.ssh-gateway.host}"
}

output "ssh_gateway_user" {
  value = "${module.ssh-gateway.user}"
}
