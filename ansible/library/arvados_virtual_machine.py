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
            "uuid": dict(required=False, type="str"),
            "owner_uuid": dict(required=False, type="str", default=None),
        },
        supports_check_mode=True
    )

    if not HAS_ARVADOS:
        module.fail_json(msg="arvados is required for this module (try `pip install arvados-python-client` or `apt-get install python-arvados-python-client`)")

    api = arvados.api(version="v1", cache=module.params["cache"], host=module.params["api_host"], token=module.params["api_token"], insecure=module.params["api_host_insecure"])

    virtual_machine = None
    update_required = False
    exists = False
    result = api.virtual_machines().list(filters=[["uuid","=", module.params["uuid"]]]).execute()
    assert len(result["items"]) <= 1
    if len(result["items"]) > 0:
        virtual_machine = result["items"][0]
        exists = True
    
    if virtual_machine is None:
        virtual_machine = dict(uuid=module.params["uuid"])

    assert virtual_machine["uuid"] == module.params["uuid"]

    for property in ["hostname", "owner_uuid"]:
        if module.params[property] is not None:
            if property not in virtual_machine or str(virtual_machine[property]) != str(module.params[property]):
                update_required = True
                virtual_machine[property] = module.params[property]

    if module.check_mode:
        module.exit_json(changed=update_required)
    else:
        if not update_required:
            module.exit_json(changed=False, msg="virtual_machine resource already exists with the desired properties")
        else:
            if exists:
                try:
                    api.virtual_machines().update(uuid=virtual_machine["uuid"], body=virtual_machine).execute()
                except Exception as e:
                    module.fail_json(msg="Error while attempting to update virtual_machine %s (hostname %s): %s" % (virtual_machine["uuid"], virtual_machine["hostname"], str(e)))
                module.exit_json(changed=True, msg="virtual_machine resource updated with uuid %s" % (virtual_machine["uuid"]))
            else:
                try:
                    api.virtual_machines().create(body=virtual_machine).execute()
                except Exception as e:
                    module.fail_json(msg="Error while attempting to create virtual_machine %s (hostname %s): %s" % (virtual_machine["uuid"], virtual_machine["hostname"], str(e)))
                module.exit_json(changed=True, msg="virtual_machine resource created with uuid %s" % (virtual_machine["uuid"]))

if __name__ == "__main__":
    main()
