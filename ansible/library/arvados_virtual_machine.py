#!/usr/bin/python3

DOCUMENTATION = """
---
module: arvados_virtual_machine
short_description: Sets up Arvados virtual_machine
description:
  - Creates or modifies an Arvados virtual_machine.
author:
  - Joshua C. Randall <jcrandall@alum.mit.edu>
  - Colin Nolan <colin.nolan@sanger.ac.uk>
options:
  api_host:
    description: 
      - Host name of the Arvados API server
    required: true
  api_token:
    description:
      - API client token to use for authorization with the API server
    required: true
  api_host_insecure:
    description:
      - If true, bypass certificate validations (i.e. to connect to an API server using self-signed certificates)
    required: false
    default: false
  cache:
    description:
      - path to use for Arvados discovery document cache
    required: false
    default: ~/.cache/arvados/discovery
  hostname:
    description:
      - Hostname (FQDN) of virtual machine
    required: true
  uuid:
    description:
      - UUID to use for virtual machine (format is <cluster_id>-2x53u-[0-9a-z]{15})
    required: true
  owner_uuid:
    description:
      - UUID of owner of the virtual machine (default: None which means Arvados will assign the current user as owner)
    required: false
requirements:
  - "python >= 3"
  - "arvados"
"""

EXAMPLES = """
- name: Create Arvados virtual machine
  arvados_virtual_machine: 
    api_host: api.abcde.example.com
    api_token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    hostname: shell.abcde.example.com
    uuid: abcde-2x53u-shellserver0001
"""

from ansible.module_utils.arvados_common import process


def main():
    additional_argument_spec={
        "hostname": dict(required=True, type="str"),
        "uuid": dict(required=False, type="str"),
        "owner_uuid": dict(required=False, type="str", default=None),
    }

    filter_property = "uuid"
    filter_value_module_parameter = "uuid"

    module_parameter_to_service_parameter_map = {
        "hostname": "hostname",
        "owner_uuid": "owner_uuid"
    }

    process(additional_argument_spec, filter_property, filter_value_module_parameter,
            module_parameter_to_service_parameter_map)


if __name__ == "__main__":
    main()
