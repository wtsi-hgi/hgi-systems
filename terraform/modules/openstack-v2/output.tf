output "context" {
  value = {
    maps = {
      security_groups = "${local.security_groups}"
      keypairs        = "${local.keypairs}"
      networks        = "${local.networks}"
      subnets         = "${local.subnets}"
    }

    strings = {
      floatingip_pool_name  = "${var.floatingip_pool_name}"
      external_network_name = "${var.external_network_name}"
      external_network_id   = "${data.openstack_networking_network_v2.external_network.id}"
    }

    lists = {
      dns_nameservers = "${var.dns_nameservers}"
    }
  }
}
