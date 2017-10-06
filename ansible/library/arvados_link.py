#!/usr/bin/python3

from ansible.module_utils.arvados_common import process

def main():
    additional_argument_spec={
        "uuid": dict(required=True, type="str"),
        "head_uuid": dict(required=True, type="str"),
        "tail_uuid": dict(required=True, type="str"),
        "link_class": dict(required=True, type="str"),
        "name": dict(required=True, type="str"),
    }

    filter_property = "uuid"
    filter_value_module_parameter = "uuid"

    module_parameter_to_resource_parameter_map = {
        "head_uuid": "head_uuid",
        "tail_uuid": "tail_uuid",
        "link_class": "link_class",
        "name": "name",
    }

    process("links", additional_argument_spec, filter_property, filter_value_module_parameter,
            module_parameter_to_resource_parameter_map)

if __name__ == "__main__":
    main()
