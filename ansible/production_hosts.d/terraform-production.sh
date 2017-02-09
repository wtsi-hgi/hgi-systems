#!/bin/bash

export TF_ANSIBLE_INVENTORY_NAME_TEMPLATE='{{ name }}'

export TF_ANSIBLE_GROUPS_TEMPLATE=$(cat <<EOF
{{ ["all",
"tf_provider_"+provider,
"tf_type_"+type,
"tf_name_"+primary.attributes.name] | join("\n") }}
{% set newline = joiner("\n") -%}
{% for security_group in primary.expanded_attributes.security_groups -%}
{{ newline() }}tf_security_group_{{ security_group }}
{%- endfor -%}
{% for network in primary.expanded_attributes.network -%}
{{ newline() }}tf_network_{{ network.name }}
{%- endfor -%}
EOF
)

export TF_STATE=../../terraform/production/terraform.tfstate

yatadis $@
