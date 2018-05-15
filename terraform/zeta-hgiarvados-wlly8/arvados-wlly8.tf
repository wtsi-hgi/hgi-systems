module "arvados-cluster" {
  source                 = "../modules/arvados-v2-cluster"
  env                    = "${var.env}"
  region                 = "${var.region}"
  setup                  = "${var.setup}"
  core_context           = "${data.terraform_remote_state.hgiarvados-wlly8-core.core_context}"
  domain                 = "hgi.sanger.ac.uk"
  arvados_cluster_id     = "wlly8"
  consul_datacenter      = "${var.region}-${var.setup}"
  consul_acl_datacenter  = "${var.region}-hgi"
  consul_keys_datacenter = "${var.region}-hgi"                                                                                            # FIXME: keys are currently stored only in the hgi datacenter
  base_image             = "${data.terraform_remote_state.hgiarvados-wlly8-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  compute_node_image     = "${data.terraform_remote_state.hgiarvados-wlly8-core.hgi-openstack-image-hgi-arvados_compute-xenial-4cb02ffa}"
  keepproxy_count        = 1
  keep_count             = 1
  monitor_count          = 1
  compute_node_count     = 1
  network_name           = "main"
  ssh_gateway            = "${data.terraform_remote_state.hgiarvados-wlly8-core.ssh_gateway}"
  master_flavour         = "o1.4xlarge"
  api_db_flavour         = "o1.4xlarge"
  sso_flavour            = "o1.large"
  workbench_flavour      = "o1.large"
  keepproxy_flavour      = "o1.large"
  keep_flavour           = "o1.large"
  shell_flavour          = "o1.large"
  monitor_flavour        = "o1.medium"
  compute_node_flavour   = "m1.xlarge"
  shell_names            = ["shell", "debugshell"]
  api_db_volume_size_gb  = 1000
}

output "arvados_wlly8_json" {
  value = "${jsonencode(module.arvados-cluster.hgi_instances)}"
}
