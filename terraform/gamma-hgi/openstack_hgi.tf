provider "openstack" {
  alias = "gamma-hgi"
  tenant_name = "hgi"
}

resource "openstack_compute_keypair_v2" "mercury_gamma-hgi" {
  provider = "openstack.gamma-hgi"
  name = "mercury_gamma-hgi"
  public_key = "${var.mercury_keypair}"
}

resource "openstack_compute_keypair_v2" "jr17_gamma-hgi" {
  provider = "openstack.gamma-hgi"
  name = "jr17_gamma-hgi"
  public_key = "${var.jr17_keypair}"
}

resource "openstack_compute_secgroup_v2" "ssh_gamma-hgi" {
  provider = "openstack.gamma-hgi"
  name = "ssh_gamma-hgi"
  description = "Incoming ssh access"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_networking_network_v2" "main_gamma-hgi" {
  provider = "openstack.gamma-hgi"
  name = "main_gamma-hgi"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "main_gamma-hgi" {
  provider = "openstack.gamma-hgi"
  name = "main_gamma-hgi"
  network_id = "${openstack_networking_network_v2.main_gamma-hgi.id}"
  cidr = "10.101.0.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "main_nova_gamma-hgi" {
  provider = "openstack.gamma-hgi"
  name = "main_nova_gamma-hgi"
  external_gateway = "1c682a8a-bed3-4354-9098-60d11fc608af"
}

resource "openstack_networking_router_interface_v2" "main_nova_gamma-hgi" {
  provider = "openstack.gamma-hgi"
  router_id = "${openstack_networking_router_v2.main_nova_gamma-hgi.id}"
  subnet_id = "${openstack_networking_subnet_v2.main_gamma-hgi.id}"
}
