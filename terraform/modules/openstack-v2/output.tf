output "context" {
  value = {
    maps = {
      security_groups = "${local.security_groups}"
      keypairs        = "${local.keypairs}"
      networks        = "${local.networks}"
    }

    strings = {
      floatingip_pool_name = "${var.floatingip_pool_name}"
    }

    lists = {
      dns_nameservers = "${var.dns_nameservers}"
    }
  }
}
