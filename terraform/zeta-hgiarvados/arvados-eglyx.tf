module "arvados-cluster" {
  source                 = "../modules/arvados-v2-cluster"
  env                    = "${var.env}"
  region                 = "${var.region}"
  setup                  = "${var.setup}"
  core_context           = "${data.terraform_remote_state.hgiarvados-core.core_context}"
  domain                 = "hgi.sanger.ac.uk"
  arvados_cluster_id     = "eglyx"
  consul_datacenter      = "${var.region}-${var.setup}"
  consul_acl_datacenter  = "${var.region}-hgi"
  consul_keys_datacenter = "${var.region}-hgi"                                                                                      # FIXME: keys are currently stored only in the hgi datacenter
  base_image             = "${data.terraform_remote_state.hgiarvados-core.hgi-openstack-image-hgi-docker-xenial-4cb02ffa}"
  compute_node_image     = "${data.terraform_remote_state.hgiarvados-core.hgi-openstack-image-hgi-arvados_compute-xenial-cb4ab41c}"
  api_logs_count         = 1
  keepproxy_count        = 8
  keep_count             = 8
  monitor_count          = 1
  compute_node_count     = 10
  network_name           = "main"
  ssh_gateway            = "${data.terraform_remote_state.hgiarvados-core.ssh_gateway}"
  master_flavour         = "o1.4xlarge"
  api_db_flavour         = "o1.4xlarge"
  api_logs_flavour       = "o1.4xlarge"
  sso_flavour            = "o1.large"
  workbench_flavour      = "o1.large"
  keepproxy_flavour      = "o1.xlarge"
  keep_flavour           = "o1.xlarge"
  shell_flavour          = "o1.large"
  monitor_flavour        = "o1.medium"
  compute_node_flavour   = "m1.xlarge"
  shell_names            = ["shell", "debugshell"]
  api_db_volume_size_gb  = 1000
}

output "arvados_eglyx_json" {
  value = "${jsonencode(module.arvados-cluster.hgi_instances)}"
}
