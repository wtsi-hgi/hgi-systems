#!/usr/bin/python3
from typing import Dict, List, Optional

try:
    import arvados
    HAS_ARVADOS = True
except ImportError:
    HAS_ARVADOS = False

from ansible.module_utils.basic import AnsibleModule

ServiceFilter = List[List[str]]

COMMON_ARGUMENT_SPECIFICATION = {
    "api_host": dict(required=True, type="str"),
    "api_token": dict(required=True, type="str"),
    "api_host_insecure": dict(required=False, type="bool", default=False),
    "cache": dict(required=False, type="str", default="~/.cache/arvados/discovery")
}


class TooManyFilteredServicesException(Exception):
    """
    TODO
    """
    def __init__(self, items: List, service_filter: ServiceFilter):
        """
        TODO
        :param items:
        :param service_filter:
        """
        self.items = items
        self.service_filter = service_filter
        super().__init__(
            f"Multiple service items retrieved with the filter: {self.service_filter}. Items: {self.items}")


class ServiceUpdateException(Exception):
    """
    TODO
    """

class ServiceCreateException(Exception):
    """
    TODO
    """


def _fail_if_missing_modules(module: AnsibleModule):
    """
    TODO
    :param module:
    :return:
    """
    if not HAS_ARVADOS:
        module.fail_json(
            msg="arvados is required for this module (try `pip install arvados-python-client` or "
                "`apt-get install python-arvados-python-client`)")


def get_service(api: arvados.api, filters: ServiceFilter) -> Optional[Dict]:
    """
    TODO
    :param api:
    :param filters: the filter must be such that it will result in either 0 or 1 services being returned
    :return:
    :raises TooManyFilteredServicesException:
    """
    result = api.keep_services().list(filters=filters).execute()
    items = result["items"]
    if len(items) > 1:
        raise TooManyFilteredServicesException(items, filters)
    elif len(items) == 1:
        return result["items"][0]
    else:
        return None


def prepare_update(service: Dict, required_property_value_map: Dict) -> bool:
    """
    TODO
    :param service:
    :param module:
    :param required_property_value_map:
    :return:
    """
    update_required = False
    for key, value in required_property_value_map.items():
        if key not in service or str(service[key]) != str(value):
            update_required = True
            service[key] = value
    return update_required


def commit_update(api, service, exists):
    """
    TODO
    :param api:
    :param service:
    :param exists:
    :return:
    """
    if exists:
        try:
            api.keep_services().update(uuid=service["uuid"], body=service).execute()
        except Exception as e:
            raise ServiceUpdateException() from e
    else:
        try:
            api.keep_services().create(body=service).execute()
        except Exception as e:
            raise ServiceCreateException() from e


def process(additional_argument_spec: Dict[Dict], filter_property: str, filter_value_module_parameter: str,
            module_parameter_to_sevice_parameter_map: Dict[str, str]):
    """
    TODO
    :param additional_argument_spec:
    :return:
    """
    module = AnsibleModule(
        argument_spec={**COMMON_ARGUMENT_SPECIFICATION, **additional_argument_spec},
        supports_check_mode=True
    )
    _fail_if_missing_modules(module)

    api = arvados.api(version="v1", cache=module.params["cache"], host=module.params["api_host"],
                      token=module.params["api_token"], insecure=module.params["api_host_insecure"])

    filter_value = module.params[filter_value_module_parameter]
    service = get_service(api, [[filter_property, "=", filter_value]])
    if service is None:
        exists = False
        service = {filter_property: filter_value}
    else:
        exists = True
    assert service[filter_property] == filter_value

    update_required = prepare_update(
        service, {key: module.params[value] for key, value in module_parameter_to_sevice_parameter_map.items()})

    if module.check_mode:
        module.exit_json(changed=update_required)
    elif not update_required:
        module.exit_json(changed=False, msg="keep_service resource already exists with the desired properties")
    else:
        try:
            commit_update(api, service, exists)
        except ServiceUpdateException as e:
            # module.fail_json(msg="Error while attempting to update keep_service %s (service_host %s): %s"
            #                      % (service["uuid"], service["service_host"], str(e)))
            raise e
        except ServiceCreateException as e:
            # module.fail_json(msg="Error while attempting to create keep_service (service_host %s): %s"
            #                      % (service["service_host"], str(e)))
            raise e
        module.exit_json(changed=True, msg="service resource created")

