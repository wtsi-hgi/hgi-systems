provider "openstack" {
  alias = "hgiarvados"
  tenant_name = "hgiarvados"
}

resource "openstack_compute_keypair_v2" "mercury" {
  provider = "openstack.hgiarvados"
  name = "mercury"
  public_key = "${var.mercury_keypair}"
}

resource "openstack_compute_keypair_v2" "jr17" {
  provider = "openstack.hgiarvados"
  name = "jr17"
  public_key = "${var.jr17_keypair}"
}

resource "openstack_compute_secgroup_v2" "ssh" {
  provider = "openstack.hgiarvados"
  name = "ssh"
  description = "Incoming ssh access"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

