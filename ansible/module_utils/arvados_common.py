#!/usr/bin/python2

try:
    import arvados
    HAS_ARVADOS = True
except ImportError:
    HAS_ARVADOS = False

try:
    from future.utils import raise_from
    HAS_FUTURE = True
except ImportError:
    HAS_FUTURE = False

from ansible.module_utils.basic import AnsibleModule


COMMON_ARGUMENT_SPECIFICATION = {
    "api_host": dict(required=True, type="str"),
    "api_token": dict(required=True, type="str"),
    "api_host_insecure": dict(required=False, type="bool", default=False),
    "cache": dict(required=False, type="str", default="~/.cache/arvados/discovery")
}


class TooManyServicesSelectedException(Exception):
    """
    Exception to indicate more items than expected have been encountered.
    """
    def __init__(self, items, filters):
        """
        Constructor.
        :param items: the items encountered
        :type items: List[Dict]
        :param filters: the filter that resulted in the items
        :type filters: List[List[str]]
        """
        self.items = items
        self.filters = filters
        super(TooManyServicesSelectedException, self).__init__(
            "Multiple service items retrieved with the filters: %s. Items: %s" % (self.filters, self.items))


class ServiceUpdateException(Exception):
    """
    Exception when updating a service.
    """


class ServiceCreateException(Exception):
    """
    Exception when creating a service.
    """


class ServiceListException(Exception):
    """
    TODO
    """
    def __init__(self, filters):
        """
        TODO
        :param filters:
        """
        self.filters = filters
        super(ServiceListException, self).__init__("Failed to list services using filters: %s" % self.filters)


def _fail_if_missing_modules(module):
    """
    Triggers Ansible to fail if any required modules are missing.
    :param module: the Ansible module
    :type module: AnsibleModule
    """
    if not HAS_ARVADOS:
        module.fail_json(
            msg="arvados is required for this module (try `pip install arvados-§python-client` or "
                "`apt-get install python-arvados-python-client`)")
    if not HAS_FUTURE:
        module.fail_json(
            msg="future is required for this module (try `pip install python-future`)")


def get_service(api, property, value):
    """
    Gets a service, through the given API, where the given property takes the given value.
    :param api: the Arvados API
    :type api: arvados.api
    :param property: the property to select on
    :type property: str
    :param value: the value the property must take
    :type value: str
    :return: tuple where the first element is the service and the second is whether the service already exists
    :rtype: Optional[Dict]
    :raises TooManyItemsFilteredException: raised if multiple services have the given property with the given value
    """
    filters = [[property, "=", value]]
    try:
        result = api.keep_services().list(filters=filters).execute()
    except Exception as e:
        raise raise_from(ServiceListException(filters), e)
    items = result["items"]
    if len(items) > 1:
        raise TooManyServicesSelectedException(items, filters)
    elif len(items) == 1:
        exists = True
        service = result["items"][0]
    else:
        exists = False
        service = {property: value}
    assert service[property] == value
    return service, exists


def default_value_equator(value_1, value_2):
    """
    Returns whether the first given value is equal to the second.
    :param value_1: first value
    :type value_1: Any
    :param value_2: second value
    :type value_2: Any
    :return: `True` if
    :rtype: bool
    """
    if type(value_1) != type(value_2):
        return False
    elif isinstance(value_1, list):
        return sorted(value_1) != sorted(value_2)
    else:
        return str(value_1) == str(value_2)


def prepare_update(service, required_property_value_map, property_value_equator=default_value_equator):
    """
    Perpares an update to the given service using the given property values.
    :param service: the service to update
    :type service: Dict
    :param required_property_value_map: map where the service property name is the key and the value is the value that
    property should take
    :type required_property_value_map: Dict[str, str]
    :param property_value_equator: returns `True` if the given two values are to be considered as equal
    :type property_value_equator: Callable[[Any, Any], bool]
    :return: `True` is an update has occurred
    :rtype: bool
    """
    updated = False
    for key, value in required_property_value_map.items():
        if key not in service or not property_value_equator(service[key], value):
            updated = True
            service[key] = value
    return updated


def commit_service(api, service, exists):
    """
    Commit the given service using the given API.
    :param api: the API to use to commit the change
    :type api: arvados.api
    :param service: the service to commit
    :type service: Dict
    :param exists: `True` if the service already exists and thus the commit should be an update
    :type exists: bool
    """
    if exists:
        try:
            api.keep_services().update(uuid=service["uuid"], body=service).execute()
        except Exception as e:
            raise raise_from(ServiceUpdateException(), e)
    else:
        try:
            api.keep_services().create(body=service).execute()
        except Exception as e:
            raise raise_from(ServiceCreateException(), e)


def process(additional_argument_spec, filter_property, filter_value_module_parameter,
            module_parameter_to_service_parameter_map, value_equator=default_value_equator):
    """
    TODO
    :param additional_argument_spec: specification for additional Ansible module arguments
    :type additional_argument_spec: Dict[str, Dict]
    :param filter_property: the property to filter on when getting the service that is to be updated
    :type filter_property: str
    :param filter_value_module_parameter: the name of the module parameter from which the value of the given
    `filter_property` should be equal to
    :type filter_value_module_parameter: str
    :param module_parameter_to_service_parameter_map: map where the value is is the name of the service parameter that
    is to be set from the value of module parameter identified by the key
    :type module_parameter_to_service_parameter_map: Dict[str, str]
    :param value_equator: optional function that can be used to decide if the give value associated to a service
    parameter is equal to the given expected value
    """
    # Yey outdated Python 2 dict concat...
    argument_specification = COMMON_ARGUMENT_SPECIFICATION.copy()
    argument_specification.update(additional_argument_spec)
    module = AnsibleModule(
        argument_spec=argument_specification,
        supports_check_mode=True
    )
    _fail_if_missing_modules(module)

    api = arvados.api(version="v1", cache=module.params["cache"], host=module.params["api_host"],
                      token=module.params["api_token"], insecure=module.params["api_host_insecure"])

    filter_value = module.params[filter_value_module_parameter]
    service, exists = get_service(api, filter_property, filter_value)

    update_required = prepare_update(
        service, {key: module.params[value] for key, value in module_parameter_to_service_parameter_map.items()},
        value_equator)

    if module.check_mode:
        module.exit_json(changed=update_required)
    elif not update_required:
        module.exit_json(changed=False, msg="keep_service resource already exists with the desired properties")
    else:
        try:
            commit_service(api, service, exists)
        except ServiceUpdateException as e:
            # module.fail_json(msg="Error while attempting to update keep_service %s (service_host %s): %s"
            #                      % (service["uuid"], service["service_host"], str(e)))
            raise e
        except ServiceCreateException as e:
            # module.fail_json(msg="Error while attempting to create keep_service (service_host %s): %s"
            #                      % (service["service_host"], str(e)))
            raise e
        module.exit_json(changed=True, msg="service resource created")
