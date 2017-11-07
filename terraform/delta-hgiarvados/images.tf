# N.B. this output helps to keep terraform working even if no instances exist to produce output
output "image_names" {
  value = {
    "base"         = "${var.base_image_name}"
    "arvados_base" = "${var.arvados_base_image_name}"
    "docker"       = "${var.docker_image_name}"
    "freebsd"	   = "${var.freebsd_image_name}"
  }
}
