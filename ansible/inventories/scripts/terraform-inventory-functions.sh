function terraform_inventory {
   terraform_dir=$1
   environment=$2
   shift 2
   
   YATADIS_BIN=$(which yatadis)
   if [[ -z "${YATADIS_BIN}" ]]; then
       >&2 echo "No yatadis binary in path, cannot include Terraform dynamic inventory!"
       echo "{}"
       exit 0
   fi
   
   tenant="$(basename ${terraform_dir})"
   export TF_ANSIBLE_INVENTORY_NAME_TEMPLATE="tf.${tenant}.{{ type }}.{{ primary.expanded_attributes.name | default(primary.id) }}"
   
   export TF_ANSIBLE_RESOURCE_FILTER_TEMPLATE='{{ ( type in ["openstack_compute_instance_v2", "openstack_blockstorage_volume_v2", "openstack_compute_volume_attach_v2", "openstack_networking_floatingip_v2", "openstack_compute_floatingip_associate_v2", "infoblox_record", "null_resource"] ) and (type != "infoblox_record" or ("multi" not in name)) }}'

   export TF_ANSIBLE_GROUPS_TEMPLATE=$(cat <<EOF
{{ ["all","terraform",
"canary-terraform-${tenant}",
"tf_provider_"+provider,
"tf_type_"+type] | join("\n") }}
{% set newline = joiner("\n") -%}
{% if type != "openstack_compute_instance_v2" -%}
non-hosts
{% else -%}
{% for security_group in primary.expanded_attributes.security_groups -%}
{{ newline() }}tf_security_group_{{ security_group }}
{%- endfor -%}
{% for ansible_group in primary.expanded_attributes.metadata.ansible_groups.split() -%}
{{ newline() }}{{ ansible_group }}
{%- endfor -%}
{%- endif -%}
EOF
)

   export TF_ANSIBLE_HOST_VARS_TEMPLATE=$(cat <<EOF
{% if type == "openstack_compute_instance_v2" -%}
ansible_user={{ primary.expanded_attributes.metadata.user }}
bastion_host={{ primary.expanded_attributes.metadata.bastion_host | default("") }}
bastion_user={{ primary.expanded_attributes.metadata.bastion_user | default("") }}
ansible_host={{ primary.attributes.access_ip_v6
| default(primary.attributes.ipv6_address, true)
| default(primary.attributes.access_ip_v4, true)
| default(primary.attributes["network.0.floating_ip"], true)
| default(primary.attributes["network_interface.0.access_config.0.assigned_nat_ip"], true)
| default(primary.attributes.ipv4_address, true)
| default(primary.attributes.public_ip, true)
| default(primary.attributes.ipaddress, true)
| default(primary.attributes.vip_address, true)
| default(primary.attributes.primaryip, true)
| default(primary.attributes.ip_address, true)
| default(primary.attributes["network_interface.0.ipv6_address"], true)
| default(primary.attributes.ipv6_address_private, true)
| default(primary.attributes.private_ip, true)
| default(primary.attributes["network_interface.0.ipv4_address"], true)
| default(primary.attributes.private_ip_address, true)
| default(primary.attributes.ipv4_address_private, true)
| default(primary.attributes["network_interface.0.address"], true)
| default(primary.attributes["network.0.fixed_ip_v6"], true)
| default(primary.attributes["network.0.fixed_ip_v4"], true)}}
{% endif -%}
{% set newline = joiner("\n") -%}
{% for attr, value in primary.expanded_attributes.items() -%}
{{ newline() }}tf_{{ attr }}={{ value }}
{%- endfor -%}
EOF
)

   tmp_dir="$(mktemp -d)"
   cd "${terraform_dir}"
   >&2 echo "Initializing terraform in ${terraform_dir}"
   terraform init 1>&2

   >&2 echo "Selecting environment ${environment}"
   terraform workspace select ${environment} 1>&2 
   if [[ $? -ne 0 ]]; then
     >&2 echo "terraform environment ${environment} not available - is the remote state backend offline?"
     echo "{}"
     exit 0
   fi
   
   >&2 echo "Pulling terraform remote state to ${tmp_dir}/${environment}.tfstate"
   terraform state pull > "${tmp_dir}/${environment}.tfstate"
   
   yatadis --state "${tmp_dir}/${environment}.tfstate" "$@"

   rm -rf "${tmp_dir}"
}
