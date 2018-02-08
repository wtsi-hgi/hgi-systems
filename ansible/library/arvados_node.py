#!/usr/bin/python3

from ansible.module_utils.arvados_common import process, default_value_equator
from ansible.module_utils.basic import AnsibleModule

UUID_PARAMETER = "uuid"
HOSTNAME_PARAMETER = "hostname"
DOMAIN_PARAMETER = "domain"
INFO_PARAMETER = "info"
MERGE_INFO_PARAMETER = "merge_info"


def main():
    additional_argument_spec={
        UUID_PARAMETER: dict(required=True, type="str"),
        HOSTNAME_PARAMETER: dict(required=True, type="str"),
        DOMAIN_PARAMETER: dict(required=True, type="str"),
        INFO_PARAMETER: dict(required=False, type="dict", default=None, no_log=True),
        MERGE_INFO_PARAMETER: dict(required=False, type="bool", default=True)
    }

    filter_property = "uuid"
    filter_value_module_parameter = UUID_PARAMETER

    module_parameter_to_resource_parameter_map = {
        HOSTNAME_PARAMETER: "hostname",
        DOMAIN_PARAMETER: "domain",
        INFO_PARAMETER: "info"
    }

    # To allow handling of other properties in `info` that we do not care about, e.g.
    # `{"ping_secret": "<secret>", "slurm_state": "idle"}`
    def merge_info_required_value_modifier(value, existing_value):
        if not isinstance(existing_value, dict):
            return value
        merged_value = existing_value.copy()
        merged_value.update(value)
        return merged_value

    merge_other_info = AnsibleModule(additional_argument_spec, bypass_checks=True,
                                     check_invalid_arguments=False).params[MERGE_INFO_PARAMETER]
    if merge_other_info:
        required_value_modifier = merge_info_required_value_modifier
    else:
        required_value_modifier = default_value_equator

    process("nodes", additional_argument_spec, filter_property, filter_value_module_parameter,
            module_parameter_to_resource_parameter_map, required_value_modifier)


if __name__ == "__main__":
    main()
