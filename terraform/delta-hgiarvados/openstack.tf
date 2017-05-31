module "openstack" {
  source = "../modules/openstack"
  tenant_name = "${var.env == "production" ? "hgiarvados" : "hgi-dev"}"
  env = "${var.env}"
  mercury_keypair = "${var.mercury_keypair}"
  jr17_keypair = "${var.jr17_keypair}"
}

