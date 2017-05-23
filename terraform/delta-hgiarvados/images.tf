variable base_image {
  type = "map"
  default = {
    name = "hgi-base-xenial-latest"
    user = "ubuntu"
  }
}

variable debian_base_image {
  type = "map"
  default = {
    name = "hgi-base-jessie-latest"
    user = "debian"
  }
}

variable docker_image {
  type = "map"
  default = {
    name = "hgi-docker-ubuntu-xenial-65439049"
    user = "debian"
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
