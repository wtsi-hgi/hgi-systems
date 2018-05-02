module "arvados-cluster" {
  source                 = "../modules/arvados-cluster"
  env                    = "${var.env}"
  region                 = "${var.region}"
  setup                  = "${var.setup}"
  core_context           = "${data.terraform_remote_state.hgiarvados-core.core_context}"
  domain                 = "hgi.sanger.ac.uk"
  arvados_cluster_id     = "eglyx"
  consul_datacenter      = "${var.region}-${var.setup}"
  consul_keys_datacenter = "${var.region}-hgi"                                                                                      # FIXME: keys are currently stored only in the hgi datacenter
  base_image             = "${data.terraform_remote_state.hgiarvados-core.hgi-openstack-image-hgi-base-xenial-4cb02ffa}"
  compute_node_image     = "${data.terraform_remote_state.hgiarvados-core.hgi-openstack-image-hgi-arvados_compute-xenial-4cb02ffa}"
  keepproxy_count        = 2
  keep_count             = 1
  monitor_count          = 1
  compute_node_count     = 1
  network_name           = "main"
  ssh_gateway            = "${data.terraform_remote_state.hgiarvados-core.ssh_gateway}"
  master_flavour         = "m1.xlarge"
  api_db_flavour         = "m1.2xlarge"
  sso_flavour            = "m1.2xlarge"
  workbench_flavour      = "m1.medium"
  keepproxy_flavour      = "m1.medium"
  keep_flavour           = "m1.medium"
  shell_flavour          = "m1.medium"
  monitor_flavour        = "m1.medium"
  compute_node_flavour   = "m1.xlarge"
  shell_names            = ["shell", "debugshell"]
  api_db_volume_size_gb  = 1000
}

output "arvados_eglyx_json" {
  value = "${jsonencode(module.arvados-cluster.hgi_instances)}"
}
