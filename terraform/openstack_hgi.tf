provider "openstack" {
  alias = "openstack_hgi"
  tenant_name = "hgi"
}

resource "openstack_compute_keypair_v2" "mercury" {
  provider = "openstack_hgi"
  name = "mercury"
  public_key = "${var.mercury_keypair}"
}

resource "openstack_compute_keypair_v2" "jr17" {
  provider = "openstack_hgi"
  name = "jr17"
  public_key = "${var.jr17_keypair}"
}

resource "openstack_compute_secgroup_v2" "ssh" {
  provider = "openstack_hgi"
  name = "ssh"
  description = "Incoming ssh access"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

