###############################################################################
# Security Groups
###############################################################################

resource "openstack_networking_secgroup_v2" "ping" {
  provider    = "openstack"
  name        = "icmp_ping_${var.region}_${var.env}"
  description = "ICMP ping"
}

resource "openstack_networking_secgroup_rule_v2" "ping" {
  security_group_id = "${openstack_networking_secgroup_v2.ping.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_v2" "consul-server" {
  provider    = "openstack"
  name        = "consul-server_${var.region}_${var.env}"
  description = "Access to consul server agent"
}

resource "openstack_networking_secgroup_rule_v2" "consul-server_rpc" {
  security_group_id = "${openstack_networking_secgroup_v2.consul-server.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8300
  port_range_max    = 8300
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "consul-server_serf_tcp" {
  security_group_id = "${openstack_networking_secgroup_v2.consul-server.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8301
  port_range_max    = 8302
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "consul-server_serf_udp" {
  security_group_id = "${openstack_networking_secgroup_v2.consul-server.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8301
  port_range_max    = 8302
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "consul-server_http_api" {
  security_group_id = "${openstack_networking_secgroup_v2.consul-server.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8500
  port_range_max    = 8500
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "consul-server_dns_tcp" {
  security_group_id = "${openstack_networking_secgroup_v2.consul-server.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8600
  port_range_max    = 8600
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "consul-server_dns_udp" {
  security_group_id = "${openstack_networking_secgroup_v2.consul-server.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8600
  port_range_max    = 8600
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_v2" "consul-client" {
  provider    = "openstack"
  name        = "consul-client_${var.region}_${var.env}"
  description = "Access to consul client agent"
}

resource "openstack_networking_secgroup_rule_v2" "consul-client_serf_lan_tcp" {
  security_group_id = "${openstack_networking_secgroup_v2.consul-client.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8301
  port_range_max    = 8301
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "consul-client_serf_lan_udp" {
  security_group_id = "${openstack_networking_secgroup_v2.consul-client.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8301
  port_range_max    = 8301
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_v2" "http" {
  provider    = "openstack"
  name        = "http_${var.region}_${var.env}"
  description = "Incoming http access"
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  security_group_id = "${openstack_networking_secgroup_v2.http.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_v2" "http-cogs" {
  provider    = "openstack"
  name        = "http-cogs_${var.region}_${var.env}"
  description = "Incoming http access for studentportal development"
}

resource "openstack_networking_secgroup_rule_v2" "http-cogs" {
  security_group_id = "${openstack_networking_secgroup_v2.http-cogs.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8000
  port_range_max    = 8000
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_v2" "https" {
  provider    = "openstack"
  name        = "https_${var.region}_${var.env}"
  description = "Incoming https access"
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  security_group_id = "${openstack_networking_secgroup_v2.https.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_v2" "ssh" {
  provider    = "openstack"
  name        = "ssh_${var.region}_${var.env}"
  description = "Incoming ssh access"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  security_group_id = "${openstack_networking_secgroup_v2.ssh.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_v2" "postgres-local" {
  provider    = "openstack"
  name        = "postgres-local_${var.region}_${var.env}"
  description = "Local network access on postgres port 5432"
}

resource "openstack_networking_secgroup_rule_v2" "postgres-local" {
  security_group_id = "${openstack_networking_secgroup_v2.postgres-local.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_v2" "tcp-local" {
  provider    = "openstack"
  name        = "tcp-local_${var.region}_${var.env}"
  description = "Local network access from all TCP ports"
}

resource "openstack_networking_secgroup_rule_v2" "tcp-local" {
  security_group_id = "${openstack_networking_secgroup_v2.tcp-local.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_v2" "udp-local" {
  provider    = "openstack"
  name        = "udp-local_${var.region}_${var.env}"
  description = "Local network access from all UDP ports"
}

resource "openstack_networking_secgroup_rule_v2" "udp-local" {
  security_group_id = "${openstack_networking_secgroup_v2.udp-local.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_v2" "slurm-master" {
  provider    = "openstack"
  name        = "slurm-master_${var.region}_${var.env}"
  description = "Slurm master node"
}

resource "openstack_networking_secgroup_rule_v2" "slurm-master_slurmctld" {
  security_group_id = "${openstack_networking_secgroup_v2.slurm-master.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6817
  port_range_max    = 6817
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_rule_v2" "slurm-master_slurmd" {
  security_group_id = "${openstack_networking_secgroup_v2.slurm-master.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 6819
  port_range_max    = 6819
  protocol          = "tcp"
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_rule_v2" "slurm-master_scheduler" {
  security_group_id = "${openstack_networking_secgroup_v2.slurm-master.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 7321
  port_range_max    = 7321
  protocol          = "tcp"
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_v2" "slurm-compute" {
  provider    = "openstack"
  name        = "slurm-compute_${var.region}_${var.env}"
  description = "Slurm compute node"
}

resource "openstack_networking_secgroup_rule_v2" "slurm-compute" {
  security_group_id = "${openstack_networking_secgroup_v2.slurm-compute.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6818
  port_range_max    = 6818
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_v2" "keep-service" {
  provider    = "openstack"
  name        = "keep-service_${var.region}_${var.env}"
  description = "Arvados keep service"
}

resource "openstack_networking_secgroup_rule_v2" "keep-service" {
  security_group_id = "${openstack_networking_secgroup_v2.keep-service.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 25107
  port_range_max    = 25107
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_v2" "keep-proxy" {
  provider    = "openstack"
  name        = "keep-proxy_${var.region}_${var.env}"
  description = "Arvados keep proxy (keep service accessible from anywhere)"
}

resource "openstack_networking_secgroup_rule_v2" "keep-proxy" {
  security_group_id = "${openstack_networking_secgroup_v2.keep-proxy.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 25107
  port_range_max    = 25107
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_v2" "netdata" {
  provider    = "openstack"
  name        = "netdata_${var.region}_${var.env}"
  description = "Netdata web UI accessible from within tenant network"
}

resource "openstack_networking_secgroup_rule_v2" "netdata" {
  security_group_id = "${openstack_networking_secgroup_v2.netdata.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 19999
  port_range_max    = 19999
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_v2" "nfs-server" {
  provider    = "openstack"
  name        = "nfs-server_${var.region}_${var.env}"
  description = "NFS server"
}

resource "openstack_networking_secgroup_rule_v2" "nfs-server_portmapper_tcp" {
  security_group_id = "${openstack_networking_secgroup_v2.nfs-server.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 111
  port_range_max    = 111
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_rule_v2" "nfs-server_portmapper_udp" {
  security_group_id = "${openstack_networking_secgroup_v2.nfs-server.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 111
  port_range_max    = 111
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_rule_v2" "nfs-server_nfs_tcp" {
  security_group_id = "${openstack_networking_secgroup_v2.nfs-server.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2049
  port_range_max    = 2049
  remote_ip_prefix  = "10.0.0.0/8"
}

resource "openstack_networking_secgroup_rule_v2" "nfs-server_nfs_udp" {
  security_group_id = "${openstack_networking_secgroup_v2.nfs-server.id}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 2049
  port_range_max    = 2049
  remote_ip_prefix  = "10.0.0.0/8"
}

locals {
  security_groups = {
    consul-client  = "${openstack_networking_secgroup_v2.consul-client.name}"
    consul-server  = "${openstack_networking_secgroup_v2.consul-server.name}"
    http           = "${openstack_networking_secgroup_v2.http.name}"
    http-cogs      = "${openstack_networking_secgroup_v2.http-cogs.name}"
    https          = "${openstack_networking_secgroup_v2.https.name}"
    ping           = "${openstack_networking_secgroup_v2.ping.name}"
    ssh            = "${openstack_networking_secgroup_v2.ssh.name}"
    postgres-local = "${openstack_networking_secgroup_v2.postgres-local.name}"
    tcp-local      = "${openstack_networking_secgroup_v2.tcp-local.name}"
    udp-local      = "${openstack_networking_secgroup_v2.udp-local.name}"
    slurm-master   = "${openstack_networking_secgroup_v2.slurm-master.name}"
    slurm-compute  = "${openstack_networking_secgroup_v2.slurm-compute.name}"
    keep-service   = "${openstack_networking_secgroup_v2.keep-service.name}"
    keep-proxy     = "${openstack_networking_secgroup_v2.keep-proxy.name}"
    netdata        = "${openstack_networking_secgroup_v2.netdata.name}"
    nfs-server     = "${openstack_networking_secgroup_v2.nfs-server.name}"
  }
}
