variable "env" {
  type = "string"
}

variable "region" {
  type = "string"
}

variable "base_image_name" {
  type    = "string"
  default = "hgi-base-xenial-latest"
}

variable "base_image_user" {
  type    = "string"
  default = "ubuntu"
}

variable docker_image_name {
  type    = "string"
  default = "hgi-docker-xenial-latest"
}

variable docker_image_user {
  type    = "string"
  default = "ubuntu"
}

variable arvados_base_image_name {
  type    = "string"
  default = "hgi-base-jessie-latest"
}

variable arvados_base_image_user {
  type    = "string"
  default = "debian"
}

variable freebsd_base_image_name {
  type    = "string"
  default = "hgi-base-freebsd11-latest"
}

variable freebsd_base_image_user {
  type    = "string"
  default = "beastie"
}
