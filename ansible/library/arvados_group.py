#!/usr/bin/python3

from ansible.module_utils.arvados_common import process

def main():
    additional_argument_spec={
        "uuid": dict(required=True, type="str"),
        "owner_uuid": dict(required=True, type="str"),
        "name": dict(required=True, type="str"),
    }

    filter_property = "uuid"
    filter_value_module_parameter = "uuid"

    module_parameter_to_resource_parameter_map = {
        "owner_uuid": "owner_uuid",
        "name": "name",
    }

    process("groups", additional_argument_spec, filter_property, filter_value_module_parameter,
            module_parameter_to_resource_parameter_map)

if __name__ == "__main__":
    main()
