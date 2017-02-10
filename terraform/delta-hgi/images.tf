variable base_image_name {
  default = "hgi-base-xenial-latest"
}

variable docker_image_name {
  default = "hgi-docker-ubuntu-xenial-65439049"
}

variable gitlab_runner_image_name {
  default = "gitlab-runner-ubuntu-xenial-bd395366"
}

# N.B. this output helps to keep terraform working even if no instances exist to produce output
output "image_names" {
  value = {
    "docker" = "${var.docker_image_name}"
    "base" = "${var.base_image_name}"
    "gitlab_runner" = "${var.gitlab_runner_image_name}"
  }
}
