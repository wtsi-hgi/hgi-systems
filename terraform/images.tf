variable docker_image_name {
  default = "hgi-docker-ubuntu-xenial-65439049"
}

output "image_names" {
  value = {
    "docker" = "${var.docker_image_name}"
  }
}
