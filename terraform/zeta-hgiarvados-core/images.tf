module "hgi-openstack-image-hgi-base-freebsd11-4cb02ffa" {
  source     = "../modules/hgi-openstack-image"
  env        = "${var.env}"
  region     = "${var.region}"
  setup      = "${var.setup}"
  image_name = "hgi-base-freebsd11-4cb02ffa"
  image_user = "beastie"
}
