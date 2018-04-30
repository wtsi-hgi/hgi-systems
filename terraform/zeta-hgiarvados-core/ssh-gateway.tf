module "ssh-gateway" {
  source = "../modules/ssh-gateway-v2"
  env    = "${var.env}"
  region = "${var.region}"
  setup  = "${var.setup}"

  image = "${module.hgi-openstack-image-hgi-base-freebsd11-4cb02ffa.image}"

  flavour      = "m1.small"
  domain       = "zeta-hgiarvados.hgi.sanger.ac.uk"
  core_context = "${module.openstack.context}"

  extra_ansible_groups = ["docker-consul-cluster-zeta-hgiarvados"]
}

output "ssh_gateway" {
  value = {
    host = "${module.ssh-gateway.host}"
    user = "${module.ssh-gateway.user}"
  }
}
