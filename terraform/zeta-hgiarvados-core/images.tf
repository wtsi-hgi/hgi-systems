module "hgi-openstack-image-hgi-base-freebsd11-4cb02ffa" {
  source     = "../modules/hgi-openstack-image"
  env        = "${var.env}"
  region     = "${var.region}"
  setup      = "${var.setup}"
  image_name = "hgi-base-freebsd11-4cb02ffa"
  image_user = "beastie"
}

output "hgi-openstack-image-hgi-base-freebsd11-4cb02ffa" {
  value = "${module.hgi-openstack-image-hgi-base-freebsd11-4cb02ffa.image}"
}

module "hgi-openstack-image-hgi-base-xenial-4cb02ffa" {
  source     = "../modules/hgi-openstack-image"
  env        = "${var.env}"
  region     = "${var.region}"
  setup      = "${var.setup}"
  image_name = "hgi-base-xenial-4cb02ffa"
  image_user = "ubuntu"
}

output "hgi-openstack-image-hgi-base-xenial-4cb02ffa" {
  value = "${module.hgi-openstack-image-hgi-base-xenial-4cb02ffa.image}"
}

module "hgi-openstack-image-hgi-docker-xenial-4cb02ffa" {
  source     = "../modules/hgi-openstack-image"
  env        = "${var.env}"
  region     = "${var.region}"
  setup      = "${var.setup}"
  image_name = "hgi-docker-xenial-4cb02ffa"
  image_user = "ubuntu"
}

output "hgi-openstack-image-hgi-docker-xenial-4cb02ffa" {
  value = "${module.hgi-openstack-image-hgi-docker-xenial-4cb02ffa.image}"
}

module "hgi-openstack-image-hgi-arvados_compute-xenial-73646368" {
  source     = "../modules/hgi-openstack-image"
  env        = "${var.env}"
  region     = "${var.region}"
  setup      = "${var.setup}"
  image_name = "hgi-arvados_compute-xenial-73646368"
  image_user = "ubuntu"
}

output "hgi-openstack-image-hgi-arvados_compute-xenial-73646368" {
  value = "${module.hgi-openstack-image-hgi-arvados_compute-xenial-73646368.image}"
}
