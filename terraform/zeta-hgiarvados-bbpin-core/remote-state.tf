terraform {
  backend "consul" {
    address = "consul.zeta-hgi.hgi.sanger.ac.uk:8500"
    path    = "terraform/zeta-hgiarvados-bbpin-core"
  }
}
