variable base_image {
  type = "map"
  default = {
    name = "${var.base_image_name}"
    user = "${var.base_image_user}"
  }
}

variable debian_base_image {
  type = "map"
  default = {
    name = "${var.debian_base_image_name}"
    user = "${var.debian_base_image_user}"
  }
}

variable docker_image {
  type = "map"
  default = {
    name = "${var.docker_image_name}"
    user = "${var.docker_image_user}"
  }
}

# N.B. this output helps to keep terraform working even if no instances exist to produce output
output "image_names" {
  value = {
    "base" = "${var.base_image["name"]}"
    "debian_base" = "${var.debian_base_image["name"]}"
    "docker" = "${var.docker_image["name"]}"
  }
}
