provider "openstack" {
  alias = "delta-hgiarvados"
  tenant_name = "${var.env == "production" ? "hgiarvados" : "hgi-dev"}"
}

resource "openstack_compute_keypair_v2" "mercury_delta-hgiarvados" {
  provider = "openstack.delta-hgiarvados"
  name = "mercury_delta-hgiarvados"
  public_key = "${var.mercury_keypair}"
}

resource "openstack_compute_keypair_v2" "jr17_delta-hgiarvados" {
  provider = "openstack.delta-hgiarvados"
  name = "jr17_delta-hgiarvados"
  public_key = "${var.jr17_keypair}"
}

resource "openstack_compute_secgroup_v2" "ssh_delta-hgiarvados" {
  provider = "openstack.delta-hgiarvados"
  name = "ssh_delta-hgiarvados"
  description = "Incoming ssh access"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_networking_network_v2" "main_delta-hgiarvados" {
  provider = "openstack.delta-hgiarvados"
  name = "main_delta-hgiarvados"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "main_delta-hgiarvados" {
  provider = "openstack.delta-hgiarvados"
  name = "main_delta-hgiarvados"
  network_id = "${openstack_networking_network_v2.main_delta-hgiarvados.id}"
  cidr = "10.101.0.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "main_nova_delta-hgiarvados" {
  provider = "openstack.delta-hgiarvados"
  name = "main_nova_delta-hgiarvados"
  external_gateway = "9f50f282-2a4c-47da-88f8-c77b6655c7db"
}

resource "openstack_networking_router_interface_v2" "main_nova_delta-hgiarvados" {
  provider = "openstack.delta-hgiarvados"
  router_id = "${openstack_networking_router_v2.main_nova_delta-hgiarvados.id}"
  subnet_id = "${openstack_networking_subnet_v2.main_delta-hgiarvados.id}"
}
