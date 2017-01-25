provider "openstack" {
  alias = "hgiarvados"
  tenant_name = "hgiarvados"
}

resource "openstack_compute_keypair_v2" "mercury_hgiarvados" {
  provider = "openstack.hgiarvados"
  name = "mercury_hgiarvados"
  public_key = "${var.mercury_keypair}"
}

resource "openstack_compute_keypair_v2" "jr17_hgiarvados" {
  provider = "openstack.hgiarvados"
  name = "jr17_hgiarvados"
  public_key = "${var.jr17_keypair}"
}

resource "openstack_compute_secgroup_v2" "ssh_hgiarvados" {
  provider = "openstack.hgiarvados"
  name = "ssh_hgiarvados"
  description = "Incoming ssh access"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_networking_network_v2" "main_hgiarvados" {
  provider = "openstack.hgiarvados"
  name = "main_hgiarvados"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "main_hgiarvados" {
  provider = "openstack.hgiarvados"
  name = "main_hgiarvados"
  network_id = "${openstack_networking_network_v2.main_hgiarvados.id}"
  cidr = "10.101.0.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "main_public_hgiarvados" {
  provider = "openstack.hgiarvados"
  name = "main_public_hgiarvados"
  external_gateway = "9f50f282-2a4c-47da-88f8-c77b6655c7db"
}

resource "openstack_networking_router_interface_v2" "main_public_hgiarvados" {
  provider = "openstack.hgiarvados"
  router_id = "${openstack_networking_router_v2.main_public_hgiarvados.id}"
  subnet_id = "${openstack_networking_subnet_v2.main_hgiarvados.id}"
}
