provider "openstack" {
}

resource "openstack_compute_keypair_v2" "mercury" {
  name = "mercury"
  public_key = "${var.mercury_keypair}"
}

resource "openstack_compute_keypair_v2" "jr17" {
  name = "jr17"
  public_key = "${var.jr17_keypair}"
}

resource "openstack_compute_secgroup_v2" "ssh" {
  name = "ssh"
  description = "Incoming ssh access"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

#resource "openstack_compute_floatingip_v2" "" {
#  pool = "nova"
#}

