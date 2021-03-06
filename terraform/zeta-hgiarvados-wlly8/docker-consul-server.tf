module "consul-server" {
  source            = "../modules/docker-consul-server/v1"
  count             = 3
  env               = "${var.env}"
  region            = "${var.region}"
  setup             = "${var.setup}"
  core_context      = "${data.terraform_remote_state.hgiarvados-wlly8-core.core_context}"
  domain            = "hgi.sanger.ac.uk"
  consul_datacenter = "${var.region}-${var.setup}"
  image             = "${data.terraform_remote_state.hgiarvados-wlly8-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  network_name      = "main"
  ssh_gateway       = "${data.terraform_remote_state.hgiarvados-wlly8-core.ssh_gateway}"
  flavour           = "o1.medium"
  volume_size_gb    = 10
}

output "consul_server_json" {
  value = "${jsonencode(module.consul-server.hgi_instances)}"
}
