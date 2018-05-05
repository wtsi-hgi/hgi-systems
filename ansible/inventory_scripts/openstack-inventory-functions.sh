function openstack_inventory {
    region=$1
    setup=$2
    shift 2
    
    YAOSADIS_BIN=$(which yaosadis)
    if [[ -z "${YAOSADIS_BIN}" ]]; then
	>&2 echo "No yaosadis binary in path, cannot include openstack dynamic inventory!"
	echo "{}"
	exit 0
    fi
    
    region_uppercase_safe=$(echo "${region}" | tr '[:lower:][:punct:]' '[:upper:]_')
    setup_uppercase_safe=$(echo "${setup}" | tr '[:lower:][:punct:]' '[:upper:]_')

    >&2 echo "Clearing all existing OS_ vars... "
    while IFS= read -r -d '' envline; do
	var=$(echo "${envline}" | cut -f1 -d=)
	case "${var}" in
	    OS_*)
		unset "${var}"
		>&2 echo "    unset ${var}"
		;;
	esac
    done < <(printenv -0)

    >&2 echo "Setting OS_ vars for ${region} based on ${region_uppercase_safe}_OS_ vars... "
    while IFS= read -r -d '' envline; do
	var=$(echo "${envline}" | cut -f1 -d=)
	case "${var}" in
	    ${region_uppercase_safe}_OS_*)
		os_var=$(echo "${var}" | sed "s/^${region_uppercase_safe}_OS/OS/")
		export "${os_var}"="${!var}"
		>&2 echo "    set ${os_var} from ${var}"
		;;
	esac
    done < <(printenv -0)
    
    >&2 echo "Setting OS_ vars for ${region}-${setup} based on ${region_uppercase_safe}_${setup_uppercase_safe}_OS_ vars... "
    while IFS= read -r -d '' envline; do
	var=$(echo "${envline}" | cut -f1 -d=)
	case "${var}" in
	    ${region_uppercase_safe}_${setup_uppercase_safe}_OS_*)
		os_var=$(echo "${var}" | sed "s/^${region_uppercase_safe}_${setup_uppercase_safe}_OS/OS/")
		export "${os_var}"="${!var}"
		>&2 echo "    set ${os_var} from ${var}"
		;;
	esac
    done < <(printenv -0)
    
    if [[ -z "${OS_USERNAME}" ]]; then
	>&2 echo "OS_USERNAME required"
	echo "{}"
	exit 0
    fi
    if [[ -z "${OS_PASSWORD}" ]]; then
	>&2 echo "OS_PASSWORD required"
	echo "{}"
	exit 0
    fi
    if [[ -z "${OS_AUTH_URL}" ]]; then
	>&2 echo "OS_AUTH_URL required"
	echo "{}"
	exit 0
    fi
    if [[ -z "${OS_TENANT_NAME}" ]]; then
	>&2 echo "OS_TENANT_NAME required"
	echo "{}"
	exit 0
    fi
    
    export tenant=${region}-${setup}

    tmp_openstackinfo=$(mktemp)
    openstackinfo_bin=$(which openstackinfo)
    >&2 echo "openstack-inventory: retrieving openstackinfo for ${tenant} using ${openstackinfo_bin}, writing to ${tmp_openstackinfo}"
    ${openstackinfo_bin} -i id > "${tmp_openstackinfo}"

    export OSI_ANSIBLE_INVENTORY_NAME_TEMPLATE="os.${tenant}.{{ resource.type }}.{{ resource.name }}"

    export OSI_ANSIBLE_RESOURCE_FILTER_TEMPLATE='{{ resource.type in ["network", "security_group", "volume", "keypair"] or ( resource.type == "image" and resource.visibility == "private" ) or ( resource.type == "instance" and resource.metadata is defined and resource.metadata.managed_by is defined and resource.metadata.managed_by == "ansible" ) }}'

    export OSI_ANSIBLE_GROUPS_TEMPLATE=$(cat <<EOF
all
openstack
openstack-{{ resource.type }}s
canary-openstack-${tenant}
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

    >&2 echo "openstack-inventory: running yaosadis on ${tmp_openstackinfo}"
    ${YAOSADIS_BIN} --info "${tmp_openstackinfo}" "$@"

    >&2 echo "openstack-inventory: removing temporary openstackinfo file ${tmp_openstackinfo}"
    rm "${tmp_openstackinfo}"

    exit 0
}
