# N.B. this output helps to keep terraform working even if no instances exist to produce output
output "image_names" {
  value = {
    "docker" = "${var.docker_image_name}"
    "base"   = "${var.base_image_name}"
  }
}
