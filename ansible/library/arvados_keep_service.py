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
            "service_host": dict(required=True, type="str"),
            "service_port": dict(required=False, type="int", default=25107),
            "service_ssl_flag": dict(required=False, type="str", default=False),
            "service_type": dict(required=False, type="str", choices=["disk", "blob", "proxy"], default="disk"),
        },
        supports_check_mode=True
    )

    if not HAS_ARVADOS:
        module.fail_json(msg="arvados is required for this module (try `pip install arvados-python-client` or `apt-get install python-arvados-python-client`)")

    api = arvados.api(version="v1", cache=module.params["cache"], host=module.params["api_host"], token=module.params["api_token"], insecure=module.params["api_host_insecure"])

    keep_service = None
    update_required = False
    exists = False
    result = api.keep_services().list(filters=[["service_host","=", module.params["service_host"]]]).execute()
    if len(result["items"]) > 0:
        keep_service = result["items"][0]
        exists = True
    if len(result["items"]) > 1:
        module.fail_json(msg="multiple keep_service entries for service_host %s" % (module.params["service_host"]))
    
    if keep_service is None:
        keep_service = dict(service_host=module.params["service_host"])

    assert keep_service["service_host"] == module.params["service_host"]

    for property in ["service_port", "service_ssl_flag", "service_type"]:
        if property not in keep_service or str(keep_service[property]) != str(module.params[property]):
            update_required = True
            keep_service[property] = module.params[property]

    if module.check_mode:
        module.exit_json(changed=update_required)
    else:
        if not update_required:
            module.exit_json(changed=False, msg="keep_service resource already exists with the desired properties")
        else:
            if exists:
                try:
                    api.keep_services().update(uuid=keep_service["uuid"], body=keep_service).execute()
                except Exception as e:
                    module.fail_json(msg="Error while attempting to update keep_service %s (service_host %s): %s" % (keep_service["uuid"], keep_service["service_host"], str(e)))
                module.exit_json(changed=True, msg="keep_service resource updated")
            else:
                try:
                    api.keep_services().create(body=keep_service).execute()
                except Exception as e:
                    module.fail_json(msg="Error while attempting to create keep_service (service_host %s): %s" % (keep_service["service_host"], str(e)))
                module.exit_json(changed=True, msg="keep_service resource created")

if __name__ == "__main__":
    main()
