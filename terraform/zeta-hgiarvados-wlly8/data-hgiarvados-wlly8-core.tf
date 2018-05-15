data "terraform_remote_state" "hgiarvados-wlly8-core" {
  backend   = "consul"
  workspace = "${var.env}"

  config {
    address = "consul.zeta-hgi.hgi.sanger.ac.uk:8500"
    path    = "terraform/zeta-hgiarvados-wlly8-core"
    gzip    = true
  }
}

output "ssh_gateway" {
  value = "${data.terraform_remote_state.hgiarvados-wlly8-core.ssh_gateway}"
}
