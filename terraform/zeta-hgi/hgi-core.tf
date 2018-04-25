data "terraform_remote_state" "hgi-core" {
  backend   = "consul"
  workspace = "${var.env}"

  config {
    address = "consul.zeta-hgi.hgi.sanger.ac.uk:8500"
    path    = "terraform/zeta-hgi-core"
    gzip    = true
  }
}

output "ssh_gateway_host" {
  value = "${data.terraform_remote_state.hgi-core.ssh_gateway_host}"
}

output "ssh_gateway_user" {
  value = "${data.terraform_remote_state.hgi-core.ssh_gateway_user}"
}
