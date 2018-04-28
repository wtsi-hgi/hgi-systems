variable "env" {}
variable "region" {}
variable "setup" {}
variable "image_name" {}
variable "image_user" {}

variable "image_url_base" {
  default = "https://hgi-openstack-images.cog.sanger.ac.uk"
}

variable "image_container_format" {
  default = "bare"
}

variable "image_disk_format" {
  default = "qcow2"
}

resource "openstack_images_image_v2" "hgi-image" {
  name             = "${var.env}-${var.region}-${var.setup}-${var.image_name}"
  image_source_url = "${var.image_url_base}/${var.image_name}"
  container_format = "${var.image_container_format}"
  disk_format      = "${var.image_disk_format}"

  #  properties {
  #    user = "${var.image_user}"
  #  }
}

output "image" {
  value = {
    id   = "${openstack_images_image_v2.hgi-image.id}"
    name = "${openstack_images_image_v2.hgi-image.name}"
    user = "${var.image_user}"
  }
}
