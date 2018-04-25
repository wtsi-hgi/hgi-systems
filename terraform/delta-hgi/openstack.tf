provider "openstack" {
  version     = "~> 1.2"
  tenant_name = "${var.env == "production" ? "hgi" : "hgi-dev"}"
}

module "openstack" {
  source          = "../modules/openstack"
  env             = "${var.env}"
  region          = "${var.region}-${var.setup}"
  mercury_keypair = "${var.mercury_keypair}"
  jr17_keypair    = "${var.jr17_keypair}"
  subnet          = "10.100.0.0/24"
}
