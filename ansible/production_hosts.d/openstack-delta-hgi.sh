#!/bin/bash

set -euf -o pipefail

export OS_TENANT_NAME=hgi
if [[ -z "${OS_USERNAME}" ]]; then
    >&2 echo "OS_USERNAME required"
    exit 1
fi
if [[ -z "${OS_PASSWORD}" ]]; then
    >&2 echo "OS_PASSWORD required"
    exit 1
fi
if [[ -z "${OS_AUTH_URL}" ]]; then
    >&2 echo "OS_AUTH_URL required"
    exit 1
fi

export OSI_ANSIBLE_INVENTORY_NAME_TEMPLATE=$(cat <<EOF
{%- if resource.type == "instance" -%}
{%- if resource.metadata is defined and resource.metadata.managed_by is defined and resource.metadata.managed_by == "ansible" -%}
{{ resource.name }}
{%- else -%}
{{ uuid }}
{%- endif -%}
{%- else -%}
{{ resource.name }}_{{ resource.type }}
{%- endif -%}
EOF
)

export OSI_ANSIBLE_RESOURCE_FILTER_TEMPLATE='{{ resource.type in ["instance", "network", "security_group", "volume", "image", "keypair"] }}'

export OSI_ANSIBLE_GROUPS_TEMPLATE=$(cat <<EOF
all
openstack
openstack-{{ resource.type }}s
{% if resource.metadata is defined and resource.metadata.managed_by is defined -%}
openstack-managed-by-{{ resource.metadata.managed_by }}
{% endif %}
{% set newline = joiner("\n") -%}
{% if resource.metadata is defined and resource.metadata.ansible_groups is defined -%}
{% for ansible_groups in resource.metadata.ansible_groups.split() -%}
{{ newline() }}{{ ansible_groups }}
{%- endfor -%}
{% endif -%}
EOF
)


export OSI_ANSIBLE_HOST_VARS_TEMPLATE=$(cat <<EOF
{%- if resource.type == "instance" -%}
ansible_host={{ resource.accessIPv6
| default(resource.accessIPv4, true)
| default(resource.interface_ip, true)
| default(resource.private_v4, true)}}
{% if resource.metadata is defined and resource.metadata.user is defined -%}
ansible_ssh_user={{ resource.metadata.user }}
{% endif %}
{% endif %}
{% set newline = joiner("\n") -%}
{% for attr, value in resource.items() -%}
{{ newline() }}os_{{ attr }}={{ value }}
{%- endfor -%}
EOF
)

openstackinfo -i id | yaosadis --info - "$@"
