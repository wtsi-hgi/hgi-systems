variable "flavour" {}
variable "domain" {}
variable "network_id" {}
variable "consul_datacenter" {}
variable "count" {}

variable "security_group_ids" {
  type    = "map"
  default = {}
}

variable "key_pair_ids" {
  type    = "map"
  default = {}
}

variable "image" {
  type    = "map"
  default = {}
}

variable "bastion" {
  type    = "map"
  default = {}
}

resource "openstack_compute_floatingip_v2" "consul-server" {
  provider = "openstack"
  pool     = "nova"
  count    = "${var.count}"
}

resource "openstack_compute_instance_v2" "consul-server" {
  provider        = "openstack"
  count           = "${var.count}"
  name            = "consul-server-${var.consul_datacenter}"
  image_name      = "${var.image["name"]}"
  flavor_name     = "${var.flavour}"
  key_pair        = "${var.key_pair_ids["mercury"]}"
  security_groups = ["${var.security_group_ids["ssh"]}", "${var.security_group_ids["consul-server"]}"]

  network {
    uuid           = "${var.network_id}"
    floating_ip    = "${openstack_compute_floatingip_v2.consul-server.*.address[count.index]}"
    access_network = true
  }

  user_data = "#cloud-config\nhostname: consul-server-${var.consul_datacenter}-${count.index}\nfqdn: consul-server-${var.consul_datacenter}-${count.index}.${var.domain}"

  metadata = {
    ansible_groups = "consul-servers consul-clusters consul-cluster-${var.consul_datacenter} hgi-credentials"
    user           = "${var.image["user"]}"
    bastion_host   = "${var.bastion["host"]}"
    bastion_user   = "${var.bastion["user"]}"
  }

  # wait for host to be available via ssh
  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]

    connection {
      type         = "ssh"
      user         = "${var.image["user"]}"
      agent        = "true"
      timeout      = "2m"
      bastion_host = "${var.bastion["host"]}"
      bastion_user = "${var.bastion["user"]}"
    }
  }
}

resource "infoblox_record" "consul-server" {
  value  = "${openstack_compute_instance_v2.consul-server.access_ip_v4}"
  name   = "consul-server-${var.consul_datacenter}-${count.index}"
  domain = "${var.domain}"
  type   = "A"
  ttl    = 600
}

resource "openstack_blockstorage_volume_v2" "consul-server" {
  name  = "consul-server-${var.consul_datacenter}-${count.index}"
  count = "${var.count}"
  size  = 10
}

resource "openstack_compute_volume_attach_v2" "consul-server" {
  volume_id   = "${openstack_blockstorage_volume_v2.consul-server.*.id[count.index]}"
  instance_id = "${openstack_compute_instance_v2.consul-server.*.id[count.index]}"
  count       = "${var.count}"
}
