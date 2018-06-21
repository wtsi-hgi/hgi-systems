data "terraform_remote_state" "hgiarvados-bbpin-core" {
  backend   = "consul"
  workspace = "${var.env}"

  config {
    address = "consul.zeta-hgi.hgi.sanger.ac.uk:8500"
    path    = "terraform/zeta-hgiarvados-bbpin-core"
    gzip    = true
  }
}

output "ssh_gateway" {
  value = "${data.terraform_remote_state.hgiarvados-bbpin-core.ssh_gateway}"
}
