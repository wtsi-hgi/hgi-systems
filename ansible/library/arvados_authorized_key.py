#!/usr/bin/python3

from ansible.module_utils.arvados_common import process

def main():
    additional_argument_spec={
        "uuid": dict(required=True, type="str"),
        "name": dict(required=True, type="str"),
        "key_type": dict(required=False, type="str", default="SSH"),
        "authorized_user_uuid": dict(required=True, type="str"),
        "public_key": dict(required=True, type="str"),
    }

    filter_property = "uuid"
    filter_value_module_parameter = "uuid"

    module_parameter_to_resource_parameter_map = {
        "name": "name",
        "key_type": "key_type",
        "authorized_user_uuid": "authorized_user_uuid",
        "public_key": "public_key",
    }

    process("authorized_keys", additional_argument_spec, filter_property, filter_value_module_parameter,
            module_parameter_to_resource_parameter_map)

if __name__ == "__main__":
    main()
