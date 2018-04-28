output "context" {
  value = {
    security_groups = "${local.security_groups}"
    keypairs        = "${local.keypairs}"
    networks        = "${local.networks}"

    parameters = {
      floatingip_pool_name = "${var.floatingip_pool_name}"
    }
  }
}
