terraform {
  backend "consul" {
    address = "consul-delta-hgi.hgi.sanger.ac.uk:8500"
    path    = "terraform/delta-hgi"
  }
}
