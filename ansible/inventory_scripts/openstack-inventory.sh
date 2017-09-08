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
if [[ -z "${OS_TENANT_NAME}" ]]; then
    >&2 echo "OS_TENANT_NAME required"
    exit 1
fi

export tenant=delta-${OS_TENANT_NAME}

export OSI_ANSIBLE_INVENTORY_NAME_TEMPLATE="os.${tenant}.{{ resource.type }}.{{ resource.name }}"

export OSI_ANSIBLE_RESOURCE_FILTER_TEMPLATE='{{ resource.type in ["network", "security_group", "volume", "keypair"] or ( resource.type == "image" and resource.visibility == "private" ) or ( resource.type == "instance" and resource.metadata is defined and resource.metadata.managed_by is defined and resource.metadata.managed_by == "ansible" ) }}'

export OSI_ANSIBLE_GROUPS_TEMPLATE=$(cat <<EOF
all
openstack
openstack-{{ resource.type }}s
{% if resource.metadata is defined and resource.metadata.managed_by is defined -%}
openstack-managed-by-{{ resource.metadata.managed_by }}
{% endif %}
{% set newline = joiner("\n") -%}
{% if resource.type != "instance" or not ( resource.metadata is defined and resource.metadata.managed_by is defined and resource.metadata.managed_by == "ansible" ) -%}
non-hosts
{% endif -%}
{% if resource.metadata is defined and resource.metadata.managed_by is defined and resource.metadata.managed_by == "ansible" -%}
{% if resource.metadata is defined and resource.metadata.ansible_groups is defined -%}
{% for ansible_groups in resource.metadata.ansible_groups.split() -%}
{{ newline() }}{{ ansible_groups }}
{%- endfor -%}
{% endif -%}
{% endif -%}
EOF
)

export OSI_ANSIBLE_HOST_VARS_TEMPLATE=$(cat <<EOF
{%- if resource.type == "instance" -%}
ansible_host={{ resource.accessIPv6
| default(resource.accessIPv4, true)
| default(resource.interface_ip, true)
| default(resource.private_v4, true)}}
{% if resource.metadata is defined and resource.metadata.managed_by is defined -%}
managed_by={{ resource.metadata.managed_by }}
{% endif %}
{% if resource.metadata is defined and resource.metadata.user is defined -%}
ansible_user={{ resource.metadata.user }}
{% endif %}
{% if resource.metadata is defined and resource.metadata.host is defined -%}
ansible_host={{ resource.metadata.host }}
{% endif %}
{% if resource.metadata is defined and resource.metadata.port is defined -%}
ansible_port={{ resource.metadata.port }}
{% endif %}
{% endif %}
{% set newline = joiner("\n") -%}
{% for attr, value in resource.items() -%}
{{ newline() }}os_{{ attr }}={{ value }}
{%- endfor -%}
EOF
)

openstackinfo -i id | yaosadis --info - "$@"
