provider "openstack" {
  alias = "gamma-hgiarvados"
  tenant_name = "hgiarvados"
}

resource "openstack_compute_keypair_v2" "mercury_gamma-hgiarvados" {
  provider = "openstack.gamma-hgiarvados"
  name = "mercury_gamma-hgiarvados"
  public_key = "${var.mercury_keypair}"
}

resource "openstack_compute_keypair_v2" "jr17_gamma-hgiarvados" {
  provider = "openstack.gamma-hgiarvados"
  name = "jr17_gamma-hgiarvados"
  public_key = "${var.jr17_keypair}"
}

resource "openstack_compute_secgroup_v2" "ssh_gamma-hgiarvados" {
  provider = "openstack.gamma-hgiarvados"
  name = "ssh_gamma-hgiarvados"
  description = "Incoming ssh access"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_networking_network_v2" "main_gamma-hgiarvados" {
  provider = "openstack.gamma-hgiarvados"
  name = "main_gamma-hgiarvados"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "main_gamma-hgiarvados" {
  provider = "openstack.gamma-hgiarvados"
  name = "main_gamma-hgiarvados"
  network_id = "${openstack_networking_network_v2.main_gamma-hgiarvados.id}"
  cidr = "10.101.0.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "main_nova_gamma-hgiarvados" {
  provider = "openstack.gamma-hgiarvados"
  name = "main_nova_gamma-hgiarvados"
  external_gateway = "1c682a8a-bed3-4354-9098-60d11fc608af"
}

resource "openstack_networking_router_interface_v2" "main_nova_gamma-hgiarvados" {
  provider = "openstack.gamma-hgiarvados"
  router_id = "${openstack_networking_router_v2.main_nova_gamma-hgiarvados.id}"
  subnet_id = "${openstack_networking_subnet_v2.main_gamma-hgiarvados.id}"
}
