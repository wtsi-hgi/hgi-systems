#!/usr/bin/python3

from ansible.module_utils.arvados_common import process


def main():
    additional_argument_spec={
        "uuid": dict(required=True, type="str"),
        "hostname": dict(required=True, type="str"),
        "domain": dict(required=True, type="str"),
        "info": dict(required=False, type="dict", default=None),
    }

    filter_property = "uuid"
    filter_value_module_parameter = "uuid"

    module_parameter_to_resource_parameter_map = {
        "hostname": "hostname",
        "domain": "domain",
        "info": "info",
    }

    process("nodes", additional_argument_spec, filter_property, filter_value_module_parameter,
            module_parameter_to_resource_parameter_map)


if __name__ == "__main__":
    main()
