variable "env" {}
varaible "region" {}
variable "mercury_keypair" {}
variable "jr17_keypair" {}

###############################################################################
# Key Pairs
###############################################################################
resource "openstack_compute_keypair_v2" "mercury_${var.region}_${var.env}" {
  provider = "openstack"
  name = "mercury_${var.region}_${var.env}"
  public_key = "${var.mercury_keypair}"
}

resource "openstack_compute_keypair_v2" "jr17_${var.region}_${var.env}" {
  provider = "openstack"
  name = "jr17_${var.region}_${var.env}"
  public_key = "${var.jr17_keypair}"
}

output "key_pair_ids" {
  value = { 
    "mercury" = "${openstack_compute_keypair_v2.mercury_${var.region}_${var.env}.id}"
    "jr17" = "${openstack_compute_keypair_v2.jr17_${var.region}_${var.env}.id}"
  }
  depends_on = ["${openstack_compute_keypair_v2.jr17_${var.region}_${var.env}", "${openstack_compute_keypair_v2.mercury_${var.region}_${var.env}"]
}

###############################################################################
# Security Groups
###############################################################################
resource "openstack_compute_secgroup_v2" "ssh_${var.region}_${var.env}" {
  provider = "openstack"
  name = "ssh_${var.region}_${var.env}"
  description = "Incoming ssh access"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

output "security_group_ids" {
  value = {
    "ssh" = "${openstack_compute_secgroup_v2.ssh_${var.region}_${var.env}.id}"
  }
  depends_on = ["${openstack_compute_secgroup_v2.ssh_${var.region}_${var.env}}"]
}

###############################################################################
# Networks, Subnets, Routers
###############################################################################
resource "openstack_networking_network_v2" "main_${var.region}_${var.env}" {
  provider = "openstack"
  name = "main_${var.region}_${var.env}"
  admin_state_up = "true"
}

output "network_id" {
  value = "${openstack_networking_network_v2.main_${var.region}_${var.env}.id}"
  depends_on = "${openstack_networking_network_v2.main_${var.region}_${var.env}}"
}

resource "openstack_networking_subnet_v2" "main_${var.region}_${var.env}" {
  provider = "openstack"
  name = "main_${var.region}_${var.env}"
  network_id = "${openstack_networking_network_v2.main_${var.region}_${var.env}.id}"
  cidr = "10.101.0.0/24"
  ip_version = 4
  dns_nameservers = ["172.18.255.1", "172.18.255.2", "172.18.255.3"]
}

resource "openstack_networking_router_v2" "main_nova_${var.region}_${var.env}" {
  provider = "openstack"
  name = "main_nova_${var.region}_${var.env}"
  external_gateway = "9f50f282-2a4c-47da-88f8-c77b6655c7db"
}

resource "openstack_networking_router_interface_v2" "main_nova_${var.region}_${var.env}" {
  provider = "openstack"
  router_id = "${openstack_networking_router_v2.main_nova_${var.region}_${var.env}.id}"
  subnet_id = "${openstack_networking_subnet_v2.main_${var.region}_${var.env}.id}"
}
