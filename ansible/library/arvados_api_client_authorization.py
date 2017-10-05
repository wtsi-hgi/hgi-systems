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
  arvados_api_client_authorization: 
    api_host: api.abcde.example.com
    api_token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    hostname: shell.abcde.example.com
    uuid: abcde-2x53u-shellserver0001
"""

try:
    import arvados
    HAS_ARVADOS = True
except ImportError:
    HAS_ARVADOS = False

from ansible.module_utils.basic import AnsibleModule


def main():
    module = AnsibleModule(
        argument_spec={
            "api_host": dict(required=True, type="str"),
            "api_token": dict(required=True, type="str"),
            "api_host_insecure": dict(required=False, type="bool", default=False),
            "cache": dict(required=False, type="str", default="~/.cache/arvados/discovery"),
            "hostname": dict(required=True, type="str"),
            "uuid": dict(required=True, type="str"),
            "scopes": dict(required=True, type="list"),
            "client_token": dict(required=True, type="str"),
        },
        supports_check_mode=True
    )

    if not HAS_ARVADOS:
        module.fail_json(msg="arvados is required for this module (try `pip install arvados-python-client` or `apt-get install python-arvados-python-client`)")

    api = arvados.api(version="v1", cache=module.params["cache"], host=module.params["api_host"], token=module.params["api_token"], insecure=module.params["api_host_insecure"])

    api_client_authorization = None
    update_required = False
    exists = False
    result = api.api_client_authorizations().list(filters=[["uuid","=", module.params["uuid"]]]).execute()
    assert len(result["items"]) <= 1
    if len(result["items"]) > 0:
        api_client_authorization = result["items"][0]
        exists = True
    
    if api_client_authorization is None:
        api_client_authorization = dict(uuid=module.params["uuid"])

    assert api_client_authorization["uuid"] == module.params["uuid"]

    for property in ["scopes", "client_token"]:
        if module.params[property] is not None:
            if property not in api_client_authorization or str(api_client_authorization[property]) != str(module.params[property]):
                update_required = True
                api_client_authorization[property] = module.params[property]

    if module.check_mode:
        module.exit_json(changed=update_required)
    else:
        if not update_required:
            module.exit_json(changed=False, msg="api_client_authorization resource already exists with the desired properties")
        else:
            if exists:
                try:
                    api.api_client_authorizations().update(uuid=api_client_authorization["uuid"], body=api_client_authorization).execute()
                except Exception as e:
                    module.fail_json(msg="Error while attempting to update api_client_authorization %s (hostname %s): %s" % (api_client_authorization["uuid"], api_client_authorization["hostname"], str(e)))
                module.exit_json(changed=True, msg="api_client_authorization resource updated with uuid %s" % (api_client_authorization["uuid"]))
            else:
                try:
                    api.api_client_authorizations().create(body=api_client_authorization).execute()
                except Exception as e:
                    module.fail_json(msg="Error while attempting to create api_client_authorization %s (hostname %s): %s" % (api_client_authorization["uuid"], api_client_authorization["hostname"], str(e)))
                module.exit_json(changed=True, msg="api_client_authorization resource created with uuid %s" % (api_client_authorization["uuid"]))

if __name__ == "__main__":
    main()
