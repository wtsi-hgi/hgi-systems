#!/usr/bin/python3

DOCUMENTATION = """
---
module: arvados_api_client_authorization
short_description: Sets up Arvados client_authorization
description:
  - Creates or modifies an Arvados client_authorization.
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
  client_token:
    description:
      - Client authorization token to create/update
    required: true
  uuid:
    required: true
  scopes:
    description:
      - List of scopes to allow the client token to acess (default: ['all'])
    required: false
requirements:
  - "python >= 3"
  - "arvados"
"""

EXAMPLES = """
- name: Create Arvados api client authorization
  arvados_api_client_authorization: 
    api_host: api.abcde.example.com
    api_token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    uuid: abcde-gj3su-0123456789abcde
    scopes:
      - "GET /arvados/v1/virtual_machines/{{ arvados_cluster_id }}-2x53u-{{ item | hash('md5') | truncate(15, True, '') }}/logins"
    client_token: "{{ arvados_cluster_root_key | pbkdf2_hmac('arvados-login-sync-{{ item }}', 32) | b36encode }}"
"""
from ansible.module_utils.arvados_common import process

def main():
    additional_argument_spec={
        "uuid": dict(required=True, type="str"),
        "scopes": dict(required=False, type="list", default=['all']),
        "client_token": dict(required=True, type="str"),
    }

    filter_property = "uuid"
    filter_value_module_parameter = "uuid"

    module_parameter_to_resource_parameter_map = {
        "scopes": "scopes",
        "client_token": "api_token",
    }

    process("api_client_authorizations", additional_argument_spec, filter_property, filter_value_module_parameter,
            module_parameter_to_resource_parameter_map)

if __name__ == "__main__":
    main()
