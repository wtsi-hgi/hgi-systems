provider "openstack" {
  alias = "hgi"
  tenant_name = "hgi"
}

resource "openstack_compute_keypair_v2" "mercury_hgi" {
  provider = "openstack.hgi"
  name = "mercury_hgi"
  public_key = "${var.mercury_keypair}"
}

resource "openstack_compute_keypair_v2" "jr17_hgi" {
  provider = "openstack.hgi"
  name = "jr17_hgi"
  public_key = "${var.jr17_keypair}"
}

resource "openstack_compute_secgroup_v2" "ssh_hgi" {
  provider = "openstack.hgi"
  name = "ssh_hgi"
  description = "Incoming ssh access"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

