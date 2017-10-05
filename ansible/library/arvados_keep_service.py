#!/usr/bin/python3

DOCUMENTATION = """
---
module: arvados_keep_service
short_description: Sets up Arvados keep_service
description:
  - Creates or modifies an Arvados keep_service.
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
  service_host:
    description:
      - Hostname (FQDN) of keep service
    required: true
  service_port:
    description:
      - Port on which keep service listens
    required: false
    default: 25107
  service_ssl_flag:
    description:
      - Keep service uses SSL
    required: false
    default: false
  service_type:
    description:
      - Keep service type
    choices: ['disk', 'blob', 'proxy']
    required: false
    default: 'disk'
requirements:
  - "python >= 3"
  - "arvados"
"""

EXAMPLES = """
- name: Create Arvados keep service
  arvados_keep_service: 
    api_host: api.abcde.example.com
    api_token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    service_host: keep0.abcde.example.com
"""

from ansible.module_utils.arvados_common import process


def main():
    additional_argument_spec = {
        "service_host": dict(required=True, type="str"),
        "service_port": dict(required=False, type="int", default=25107),
        "service_ssl_flag": dict(required=False, type="str", default=False),
        "service_type": dict(required=False, type="str", choices=["disk", "blob", "proxy"], default="disk")
    }

    filter_property = "service_host"
    filter_value_module_parameter = "service_host"

    module_parameter_to_service_parameter_map = {
        "service_port": "service_port",
        "service_ssl_flag": "service_ssl_flag",
        "service_type": "service_type"
    }

    process("keep_services", additional_argument_spec, filter_property, filter_value_module_parameter,
            module_parameter_to_service_parameter_map)


if __name__ == "__main__":
    main()
