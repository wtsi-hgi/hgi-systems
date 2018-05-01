variable "env" {}
variable "region" {}
variable "setup" {}

variable "name_format" {}
variable "domain" {}
variable "flavour" {}
variable "count" {}

variable "hostname_format" {
  default = ""
}

variable "name_format_list" {
  type    = "list"
  default = []
}

variable "hostname_format_list" {
  type    = "list"
  default = []
}

variable "additional_dns_names" {
  type    = "list"
  default = []
}

variable "cloud_config_shell_script" {
  default = <<EOF
#!/bin/sh
echo "Default cloud_config_shell_script"
EOF
}

variable "security_group_names" {
  type = "list"

  default = [
    "ping",
    "ssh",
  ]
}

variable "ssh_gateway" {
  type    = "map"
  default = {}
}

variable "floating_ip_p" {
  default = false
}

variable "volume_p" {
  default = false
}

variable "volume_size_gb" {
  default = 10
}

variable "keypair_name" {
  default = "mercury"
}

variable "network_name" {
  default = "main"
}

variable "core_context" {
  type    = "map"
  default = {}
}

variable "image" {
  type    = "map"
  default = {}
}

variable "ansible_groups" {
  type    = "list"
  default = []
}

locals {
  core_context_maps         = "${var.core_context["maps"]}"
  core_context_lists        = "${var.core_context["lists"]}"
  core_context_strings      = "${var.core_context["strings"]}"
  openstack_keypairs        = "${local.core_context_maps["keypairs"]}"
  openstack_security_groups = "${local.core_context_maps["security_groups"]}"
  openstack_networks        = "${local.core_context_maps["networks"]}"
  security_groups           = "${matchkeys(values(local.openstack_security_groups), keys(local.openstack_security_groups), var.security_group_names)}"
}

locals {
  name_formatted_p       = "${replace(var.name_format, "/.*[^%]?%[^%].*/", "formatted") == "formatted"}"
  hostname_format        = "${var.hostname_format == "" ? var.name_format : var.hostname_format}"
  hostname_formatted_p   = "${replace(local.hostname_format, "/.*[^%]?%[^%].*/", "formatted") == "formatted"}"
  hostname_format_list   = "${coalescelist(var.hostname_format_list, var.name_format_list)}"
  name_format_list_p     = "${length(var.name_format_list) > 0}"
  hostname_format_list_p = "${length(local.hostname_format_list) > 0}"

  # element() can NEVER reference an empty list, even when it is protected by a conditional 
  non_empty_list                   = [0]
  name_format_list_never_empty     = "${coalescelist(var.name_format_list, local.non_empty_list)}"
  hostname_format_list_never_empty = "${coalescelist(local.hostname_format_list, local.non_empty_list)}"
}

locals {
  additional_dns_names_count = "${length(var.additional_dns_names)}"
}

resource "openstack_networking_floatingip_v2" "floatingip" {
  count    = "${var.floating_ip_p ? var.count : 0}"
  provider = "openstack"
  pool     = "${local.core_context_strings["floatingip_pool_name"]}"
}

resource "openstack_networking_port_v2" "port" {
  count          = "${var.count}"
  name           = "${var.env}-${var.region}-${var.setup}-${local.name_formatted_p ? (local.name_format_list_p ? format(var.name_format, element(local.name_format_list_never_empty, count.index)) : format(var.name_format, count.index + 1)) : var.name_format}-port"
  admin_state_up = "true"
  network_id     = "${lookup(local.openstack_networks, var.network_name)}"

  security_group_ids = ["${local.security_groups}"]
}

data "template_file" "cloud-config-init-script" {
  count    = "${var.count}"
  template = "${file("${path.module}/scripts/init.cfg.tpl")}"

  vars {
    CLOUDINIT_HOSTNAME = "${local.hostname_formatted_p ? (local.hostname_format_list_p ? format(local.hostname_format, element(local.hostname_format_list_never_empty, count.index)) : format(local.hostname_format, count.index + 1)) : local.hostname_format}"
    CLOUDINIT_DOMAIN   = "${var.domain}"
  }
}

data "template_cloudinit_config" "cloudinit" {
  count         = "${var.count}"
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud-config-init-script.*.rendered[count.index]}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${var.cloud_config_shell_script}"
  }
}

resource "openstack_compute_instance_v2" "instance" {
  provider    = "openstack"
  count       = "${var.count}"
  name        = "${var.env}-${var.region}-${var.setup}-${local.name_formatted_p ? (local.name_format_list_p ? format(var.name_format, element(local.name_format_list_never_empty, count.index)) : format(var.name_format, count.index + 1)) : var.name_format}"
  image_id    = "${var.image["id"]}"
  flavor_name = "${var.flavour}"
  key_pair    = "${lookup(local.openstack_keypairs, var.keypair_name)}"

  network {
    port = "${openstack_networking_port_v2.port.*.id[count.index]}"
  }

  user_data = "${data.template_cloudinit_config.cloudinit.*.rendered[count.index]}"

  metadata = {
    ansible_groups = "${join(" ", var.ansible_groups)}"
    user           = "${var.image["user"]}"
    bastion_host   = "${var.ssh_gateway["host"]}"
    bastion_user   = "${var.ssh_gateway["user"]}"
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
      bastion_host = "${var.ssh_gateway["host"]}"
      bastion_user = "${var.ssh_gateway["user"]}"
      host         = "${openstack_networking_port_v2.port.*.all_fixed_ips.0[count.index]}"
    }
  }

  timeouts {
    create = "20m"
    delete = "20m"
  }
}

resource "openstack_compute_floatingip_associate_v2" "floatingip-instance-associate" {
  count       = "${var.floating_ip_p ? var.count : 0}"
  floating_ip = "${openstack_networking_floatingip_v2.floatingip.*.address[count.index]}"
  instance_id = "${openstack_compute_instance_v2.instance.*.id[count.index]}"
}

resource "infoblox_record" "floatingip-dns" {
  count  = "${var.floating_ip_p ? var.count : 0}"
  type   = "A"
  value  = "${element(openstack_compute_floatingip_associate_v2.floatingip-instance-associate.*.floating_ip, count.index)}"
  name   = "${local.hostname_formatted_p ? (local.hostname_format_list_p ? format(local.hostname_format, element(local.hostname_format_list_never_empty, count.index)) : format(local.hostname_format, count.index + 1)) : local.hostname_format}"
  domain = "${var.domain}"
  ttl    = 600
  view   = "internal"

  # comment = "Terraform ${var.env}-${var.region}-${var.setup}-${local.name_formatted_p ? (local.name_format_list_p ? format(var.name_format, element(local.name_format_list_never_empty, count.index)) : format(var.name_format, count.index + 1)) : var.name_format}"
}

# resource "infoblox_record_a" "floatingip-dns" {
#   count   = "${var.floating_ip_p ? var.count : 0}"
#   address = "${element(openstack_compute_floatingip_associate_v2.floatingip-instance-associate.*.floating_ip, count.index)}"
#   name    = "${local.hostname_formatted_p ? (local.hostname_format_list_p ? format(local.hostname_format, element(local.hostname_format_list_never_empty, count.index)) : format(local.hostname_format, count.index + 1)) : local.hostname_format}.${var.domain}"
#   ttl     = 600
#   view    = "internal"
#   comment = "Terraform ${var.env}-${var.region}-${var.setup}-${local.name_formatted_p ? (local.name_format_list_p ? format(var.name_format, element(local.name_format_list_never_empty, count.index)) : format(var.name_format, count.index + 1)) : var.name_format}"
# }

resource "infoblox_record" "floatingip-additional-dns" {
  count  = "${var.floating_ip_p ? (local.additional_dns_names_count*var.count) : 0}"
  type   = "A"
  value  = "${element(openstack_compute_floatingip_associate_v2.floatingip-instance-associate.*.floating_ip, (count.index/local.additional_dns_names_count))}"
  name   = "${replace(element(var.additional_dns_names, (count.index%local.additional_dns_names_count)), "/.*[^%]?%[^%].*/", "formatted") == "formatted" ? format(element(var.additional_dns_names, (count.index%local.additional_dns_names_count)+1), (count.index/local.additional_dns_names_count)) : element(var.additional_dns_names, (count.index%local.additional_dns_names_count))}"
  domain = "${var.domain}"
  ttl    = 600
  view   = "internal"

  # comment = "Terraform ${var.env}-${var.region}-${var.setup}-${local.name_formatted_p ? (local.name_format_list_p ? format(var.name_format, element(local.name_format_list_never_empty, (count.index/local.additional_dns_names_count)) : format(var.name_format, (count.index/local.additional_dns_names_count) + 1)) : var.name_format} additional_dns ${(count.index%local.additional_dns_names_count) + 1}"
}

# resource "infoblox_record_a" "floatingip-additional-dns" {
#   count   = "${var.floating_ip_p ? (local.additional_dns_names_count*var.count) : 0}"
#   address = "${element(openstack_compute_floatingip_associate_v2.floatingip-instance-associate.*.floating_ip, (count.index/local.additional_dns_names_count))}"
#   name    = "${replace(element(var.additional_dns_names, (count.index%local.additional_dns_names_count)), "/.*[^%]?%[^%].*/", "formatted") == "formatted" ? format(element(var.additional_dns_names, (count.index%local.additional_dns_names_count)+1), (count.index/local.additional_dns_names_count)) : element(var.additional_dns_names, (count.index%local.additional_dns_names_count))}.${var.domain}"
#   ttl     = 600
#   view    = "internal"
#   comment = "Terraform ${var.env}-${var.region}-${var.setup}-${local.name_formatted_p ? (local.name_format_list_p ? format(var.name_format, element(local.name_format_list_never_empty, (count.index/local.additional_dns_names_count)) : format(var.name_format, (count.index/local.additional_dns_names_count) + 1)) : var.name_format} additional_dns ${(count.index%local.additional_dns_names_count) + 1}"
# }

resource "openstack_blockstorage_volume_v2" "volume" {
  count = "${var.volume_p ? var.count : 0}"
  name  = "${var.env}-${var.region}-${var.setup}-${local.name_formatted_p ? (local.name_format_list_p ? format(var.name_format, element(local.name_format_list_never_empty, count.index)) : format(var.name_format, count.index + 1)) : var.name_format}-volume"
  size  = "${var.volume_size_gb}"
}

resource "openstack_compute_volume_attach_v2" "volume-attach" {
  count       = "${var.volume_p ? var.count : 0}"
  volume_id   = "${openstack_blockstorage_volume_v2.volume.*.id[count.index]}"
  instance_id = "${openstack_compute_instance_v2.instance.*.id[count.index]}"
}

locals {
  instance_names          = "${openstack_compute_instance_v2.instance.*.name}"
  first_fixed_ips         = "${openstack_networking_port_v2.port.*.all_fixed_ips.0}"
  users_list              = "${formatlist("%.0s%s", local.instance_names, var.image["user"])}"                                                                          # this is a hacky way to repeat user n times where n = length(local.instance_names)
  security_groups_list    = "${formatlist("%.0s%s", local.instance_names, join(",", local.security_groups))}"
  internal_instance_names = "${slice(openstack_compute_instance_v2.instance.*.name, 0, var.floating_ip_p ? 0 : length(openstack_compute_instance_v2.instance.*.name))}"
  external_instance_names = "${slice(openstack_compute_instance_v2.instance.*.name, 0, var.floating_ip_p ? length(openstack_compute_instance_v2.instance.*.name) : 0)}"
  external_ips            = "${openstack_compute_floatingip_associate_v2.floatingip-instance-associate.*.floating_ip}"
  external_dns_names      = "${infoblox_record.floatingip-dns.*.name}"
}

locals {
  external_dns_by_instance_name    = "${zipmap(local.external_instance_names, local.external_dns_names)}"
  floating_ip_by_instance_name     = "${zipmap(local.external_instance_names, local.external_ips)}"
  internal_ip_by_instance_name     = "${zipmap(local.instance_names, local.first_fixed_ips)}"
  user_by_instance_name            = "${zipmap(local.instance_names, local.users_list)}"
  security_groups_by_instance_name = "${zipmap(local.instance_names, local.security_groups_list)}"
}

output "external_dns_by_instance_name" {
  value = "${local.external_dns_by_instance_name}"
}

output "floating_ip_by_instance_name" {
  value = "${local.floating_ip_by_instance_name}"
}

output "internal_ip_by_instance_name" {
  value = "${local.internal_ip_by_instance_name}"
}

output "user_by_instance_name" {
  value = "${local.user_by_instance_name}"
}

output "security_groups_by_instance_name" {
  value = "${local.security_groups_by_instance_name}"
}

output "hgi_instance" {
  value = {
    external_dns    = "${local.external_dns_by_instance_name}"
    floating_ip     = "${local.floating_ip_by_instance_name}"
    internal_ip     = "${local.internal_ip_by_instance_name}"
    user            = "${local.user_by_instance_name}"
    security_groups = "${local.security_groups_by_instance_name}"
  }
}
