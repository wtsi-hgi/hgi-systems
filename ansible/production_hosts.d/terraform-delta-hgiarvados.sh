#!/bin/bash

YATADIS_BIN=$(which yatadis)
if [[ -z "${YATADIS_BIN}" ]]; then
    >&2 echo "No yatadis binary in path, cannot include Terraform dynamic inventory!"
    echo "{}"
    exit 0
fi

terraform_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../terraform/delta-hgiarvados"

export TF_ANSIBLE_INVENTORY_NAME_TEMPLATE='{{ name }}'

export TF_ANSIBLE_GROUPS_TEMPLATE=$(cat <<EOF
{{ ["all","terraform",
"tf_provider_"+provider,
"tf_type_"+type] | join("\n") }}
{% set newline = joiner("\n") -%}
{% for security_group in primary.expanded_attributes.security_groups -%}
{{ newline() }}tf_security_group_{{ security_group }}
{%- endfor -%}
{% for ansible_group in primary.expanded_attributes.metadata.ansible_groups.split() -%}
{{ newline() }}{{ ansible_group }}
{%- endfor -%}
EOF
)

export DEFAULT_ANSIBLE_HOST_VARS_TEMPLATE=$(cat <<EOF
ansible_ssh_user=mercury
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
{% set newline = joiner("\n") -%}
{% for attr, value in primary.expanded_attributes.items() -%}
{{ newline() }}tf_{{ attr }}={{ value }}
{%- endfor -%}
EOF
)

# export TF_ANSIBLE_GROUPS_TEMPLATE=$(cat <<EOF
# {{ ["all",
# "tf_provider_"+provider,
# "tf_type_"+type,
# "tf_name_"+primary.attributes.name] | join("\n") }}
# {% set newline = joiner("\n") -%}
# {% for security_group in primary.expanded_attributes.security_groups -%}
# {{ newline() }}tf_security_group_{{ security_group }}
# {%- endfor -%}
# {% for network in primary.expanded_attributes.network -%}
# {{ newline() }}tf_network_{{ network.name }}
# {%- endfor -%}
# EOF
# )

#export TF_STATE="${terraform_dir}/production/terraform.tfstate"

tmp_state=$(mktemp)
>&2 echo "Saving terraform state to ${tmp_state}"
(cd ${terraform_dir} && terraform state pull > ${tmp_state} 2> /dev/null)
export TF_STATE="${tmp_state}"

yatadis $@

#rm -f "${tmp_state}"
