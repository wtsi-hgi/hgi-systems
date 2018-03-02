variable "env" {}
variable "region" {}
variable "mercury_keypair" {}
variable "jr17_keypair" {}
variable "subnet" {}

###############################################################################
# Key Pairs
###############################################################################
resource "openstack_compute_keypair_v2" "mercury" {
  provider   = "openstack"
  name       = "mercury_${var.region}_${var.env}"
  public_key = "${var.mercury_keypair}"
}

resource "openstack_compute_keypair_v2" "jr17" {
  provider   = "openstack"
  name       = "jr17_${var.region}_${var.env}"
  public_key = "${var.jr17_keypair}"
}

output "key_pair_ids" {
  value = {
    mercury = "${openstack_compute_keypair_v2.mercury.id}"
    jr17    = "${openstack_compute_keypair_v2.jr17.id}"
  }

  depends_on = ["${openstack_compute_keypair_v2.jr17}", "${openstack_compute_keypair_v2.mercury}"]
}

###############################################################################
# Security Groups
###############################################################################

resource "openstack_compute_secgroup_v2" "ping" {
  provider    = "openstack"
  name        = "icmp_ping_${var.region}_${var.env}"
  description = "ICMP ping"

  # All ICMP
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "consul-server" {
  provider    = "openstack"
  name        = "consul-server_${var.region}_${var.env}"
  description = "Access to consul server agent"

  # Server RPC
  rule {
    from_port   = 8300
    to_port     = 8300
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # serf LAN/WAN TCP
  rule {
    from_port   = 8301
    to_port     = 8302
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # serf LAN/WAN UDP
  rule {
    from_port   = 8301
    to_port     = 8302
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }

  # HTTP API
  rule {
    from_port   = 8500
    to_port     = 8500
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # DNS TCP
  rule {
    from_port   = 8600
    to_port     = 8600
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # DNS UDP
  rule {
    from_port   = 8600
    to_port     = 8600
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "consul-client" {
  provider    = "openstack"
  name        = "consul-client_${var.region}_${var.env}"
  description = "Access to consul client agent"

  # serf LAN TCP
  rule {
    from_port   = 8301
    to_port     = 8301
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # serf LAN UDP
  rule {
    from_port   = 8301
    to_port     = 8301
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "http" {
  provider    = "openstack"
  name        = "http_${var.region}_${var.env}"
  description = "Incoming http access"

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "http-cogs" {
  provider    = "openstack"
  name        = "http-cogs_${var.region}_${var.env}"
  description = "Incoming http access for studentportal development"

  rule {
    from_port   = 8000
    to_port     = 8000
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "https" {
  provider    = "openstack"
  name        = "https_${var.region}_${var.env}"
  description = "Incoming https access"

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "ssh" {
  provider    = "openstack"
  name        = "ssh_${var.region}_${var.env}"
  description = "Incoming ssh access"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "postgres-local" {
  provider    = "openstack"
  name        = "postgres-local_${var.region}_${var.env}"
  description = "Local network access on postgres port 5432"

  rule {
    from_port   = 5432
    to_port     = 5432
    ip_protocol = "tcp"
    cidr        = "10.0.0.0/8"
  }
}

resource "openstack_compute_secgroup_v2" "tcp-local" {
  provider    = "openstack"
  name        = "tcp-local_${var.region}_${var.env}"
  description = "Local network access from all TCP ports"

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "10.0.0.0/8"
  }
}

resource "openstack_compute_secgroup_v2" "udp-local" {
  provider    = "openstack"
  name        = "udp-local_${var.region}_${var.env}"
  description = "Local network access from all UDP ports"

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    cidr        = "10.0.0.0/8"
  }
}

resource "openstack_compute_secgroup_v2" "slurm-master" {
  provider    = "openstack"
  name        = "slurm-master_${var.region}_${var.env}"
  description = "Slurm master node"

  rule {
    from_port   = 6817
    to_port     = 6817
    ip_protocol = "tcp"
    cidr        = "10.0.0.0/8"
  }

  rule {
    from_port   = 6819
    to_port     = 6819
    ip_protocol = "tcp"
    cidr        = "10.0.0.0/8"
  }

  rule {
    from_port   = 7321
    to_port     = 7321
    ip_protocol = "tcp"
    cidr        = "10.0.0.0/8"
  }
}

resource "openstack_compute_secgroup_v2" "slurm-compute" {
  provider    = "openstack"
  name        = "slurm-compute_${var.region}_${var.env}"
  description = "Slurm compute node"

  rule {
    from_port   = 6818
    to_port     = 6818
    ip_protocol = "tcp"
    cidr        = "10.0.0.0/8"
  }
}

resource "openstack_compute_secgroup_v2" "keep-service" {
  provider    = "openstack"
  name        = "keep-service_${var.region}_${var.env}"
  description = "Arvados keep service"

  rule {
    from_port   = 25107
    to_port     = 25107
    ip_protocol = "tcp"
    cidr        = "10.0.0.0/8"
  }
}

resource "openstack_compute_secgroup_v2" "keep-proxy" {
  provider    = "openstack"
  name        = "keep-proxy_${var.region}_${var.env}"
  description = "Arvados keep proxy (keep service accessible from anywhere)"

  rule {
    from_port   = 25107
    to_port     = 25107
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "netdata" {
  provider    = "openstack"
  name        = "netdata_${var.region}_${var.env}"
  description = "Netdata web UI accessible from within tenant network"

  rule {
    from_port   = 19999
    to_port     = 19999
    ip_protocol = "tcp"
    cidr        = "10.0.0.0/8"
  }
}

resource "openstack_compute_secgroup_v2" "nfs-server" {
  provider    = "openstack"
  name        = "nfs-server_${var.region}_${var.env}"
  description = "NFS server"

  rule {
    from_port   = 111
    to_port     = 111
    ip_protocol = "tcp"
    cidr        = "10.0.0.0/8"
  }

  rule {
    from_port   = 111
    to_port     = 111
    ip_protocol = "udp"
    cidr        = "10.0.0.0/8"
  }

  rule {
    from_port   = 2049
    to_port     = 2049
    ip_protocol = "tcp"
    cidr        = "10.0.0.0/8"
  }

  rule {
    from_port   = 2049
    to_port     = 2049
    ip_protocol = "udp"
    cidr        = "10.0.0.0/8"
  }
}

output "security_group_ids" {
  value = {
    consul-client  = "${openstack_compute_secgroup_v2.consul-client.id}"
    consul-server  = "${openstack_compute_secgroup_v2.consul-server.id}"
    http           = "${openstack_compute_secgroup_v2.http.id}"
    http-cogs      = "${openstack_compute_secgroup_v2.http-cogs.id}"
    https          = "${openstack_compute_secgroup_v2.https.id}"
    ping           = "${openstack_compute_secgroup_v2.ping.id}"
    ssh            = "${openstack_compute_secgroup_v2.ssh.id}"
    postgres-local = "${openstack_compute_secgroup_v2.postgres-local.id}"
    tcp-local      = "${openstack_compute_secgroup_v2.tcp-local.id}"
    udp-local      = "${openstack_compute_secgroup_v2.udp-local.id}"
    slurm-master   = "${openstack_compute_secgroup_v2.slurm-master.id}"
    slurm-compute  = "${openstack_compute_secgroup_v2.slurm-compute.id}"
    keep-service   = "${openstack_compute_secgroup_v2.keep-service.id}"
    keep-proxy     = "${openstack_compute_secgroup_v2.keep-proxy.id}"
    netdata        = "${openstack_compute_secgroup_v2.netdata.id}"
    nfs-server     = "${openstack_compute_secgroup_v2.nfs-server.id}"
  }
}

###############################################################################
# Networks, Subnets, Routers
###############################################################################
resource "openstack_networking_network_v2" "main" {
  provider       = "openstack"
  name           = "main_${var.region}_${var.env}"
  admin_state_up = "true"
}

output "network_id" {
  value      = "${openstack_networking_network_v2.main.id}"
  depends_on = ["${openstack_networking_network_v2.main}"]
}

resource "openstack_networking_subnet_v2" "main" {
  provider        = "openstack"
  name            = "main_${var.region}_${var.env}"
  network_id      = "${openstack_networking_network_v2.main.id}"
  cidr            = "${var.subnet}"
  ip_version      = 4
  dns_nameservers = ["172.18.255.1", "172.18.255.2", "172.18.255.3"]
}

resource "openstack_networking_router_v2" "main_nova" {
  provider         = "openstack"
  name             = "main_nova_${var.region}_${var.env}"
  external_gateway = "9f50f282-2a4c-47da-88f8-c77b6655c7db"
}

resource "openstack_networking_router_interface_v2" "main_nova" {
  provider  = "openstack"
  router_id = "${openstack_networking_router_v2.main_nova.id}"
  subnet_id = "${openstack_networking_subnet_v2.main.id}"
}
