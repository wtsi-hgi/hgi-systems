module "ssh-gateway" {
  source = "../modules/ssh-gateway-v2"

  image = "${module.hgi-openstack-image-hgi-base-freebsd11-4cb02ffa.image}"

  flavour                = "m1.small"
  domain                 = "zeta-hgiarvados.hgi.sanger.ac.uk"
  openstack_core_context = "${module.openstack.context}"

  extra_ansible_groups = ["docker-consul-cluster-zeta-hgiarvados"]
}

output "ssh_gateway_host" {
  value = "${module.ssh-gateway.host}"
}

output "ssh_gateway_user" {
  value = "${module.ssh-gateway.user}"
}
