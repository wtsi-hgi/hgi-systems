variable "ssh_private_key_file" {
  default = "${pathexpand("~/.ssh/id_rsa")}"
}
