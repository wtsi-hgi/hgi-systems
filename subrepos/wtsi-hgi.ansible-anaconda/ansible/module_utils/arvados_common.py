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

from copy import deepcopy

import six

from ansible.module_utils.basic import AnsibleModule

COMMON_ARGUMENT_SPECIFICATION = {
    "api_host": dict(required=True, type="str"),
    "api_token": dict(required=True, type="str", no_log=True),
    "api_host_insecure": dict(required=False, type="bool", default=False),
    "cache": dict(required=False, type="str", default="~/.cache/arvados/discovery")
}


class TooManyResourcesSelectedException(Exception):
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
        super(TooManyResourcesSelectedException, self).__init__(
            "Multiple resource items retrieved with the filters: %s. Items: %s" % (self.filters, self.items))


class ResourceUpdateException(Exception):
    """
    Exception when updating a resource.
    """


class ResourceCreateException(Exception):
    """
    Exception when creating a resource.
    """


class ResourceListException(Exception):
    """
    TODO
    """
    def __init__(self, filters):
        """
        TODO
        :param filters:
        """
        self.filters = filters
        super(ResourceListException, self).__init__("Failed to list resources using filters: %s" % self.filters)


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


def get_resource(obj_type, api, property, value):
    """
    Gets a resource, through the given API, where the given property takes the given value.
    :param obj_type: the type of object to commit
    :type obj_type: string
    :param api: the Arvados API
    :type api: arvados.api
    :param property: the property to select on
    :type property: str
    :param value: the value the property must take
    :type value: str
    :return: tuple where the first element is the resource and the second is whether the resource already exists
    :rtype: Optional[Dict]
    :raises TooManyItemsFilteredException: raised if multiple resources have the given property with the given value
    """
    filters = [[property, "=", value]]
    try:
        result = getattr(api, obj_type)().list(filters=filters).execute()
    except Exception as e:
        raise raise_from(ResourceListException(filters), e)
    items = result["items"]
    if len(items) > 1:
        raise TooManyResourcesSelectedException(items, filters)
    elif len(items) == 1:
        exists = True
        resource = result["items"][0]
    else:
        exists = False
        resource = {property: value}
    assert resource[property] == value
    return resource, exists


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
    if isinstance(value_1, list):
        return sorted(value_1) == sorted(value_2)
    else:
        return value_1 == value_2


def default_required_value_modifier(value, existing_value):
    """
    TODO
    :param value:
    :return:
    """
    return value


def prepare_update(resource, required_property_value_map, value_equator=default_value_equator,
                   required_value_modifier=default_required_value_modifier):
    """
    Prepares an update to the given resource using the given property values.
    :param resource: the resource to update
    :type resource: Dict
    :param required_property_value_map: map where the resource property name is the key and the value is the value that
    property should take
    :type required_property_value_map: Dict[str, str]
    :param value_equator: returns `True` if the given two values are to be considered as equal
    :type value_equator: Callable[[Any, Any], bool]
    :param required_value_modifier: modifies the required value given the required value as the first argument and the
    existing value as the second
    :type required_value_modifier: Callable[[Any, Any], Any]
    :return: tuple where the first element is `True` if an update is  required and the second is a description of the
    updates, designed for human consumption
    :rtype: Tuple[bool, Dict[str, str]]
    """
    update_required = False
    property_updates = dict()
    for key, value in required_property_value_map.items():
        if value is None:
            continue

        existing_value = resource.get(key, None)
        value = required_value_modifier(value, deepcopy(existing_value))

        if key not in resource or not value_equator(existing_value, value):
            update_required = True
            resource[key] = value
            property_updates[key] = "%s => %s" % (existing_value, value)
    return update_required, property_updates


def commit_resource(obj_type, api, resource, exists):
    """
    Commit the given resource using the given API.
    :param obj_type: the type of object to commit
    :type obj_type: string
    :param api: the API to use to commit the change
    :type api: arvados.api
    :param resource: the resource to commit
    :type resource: Dict
    :param exists: `True` if the resource already exists and thus the commit should be an update
    :type exists: bool
    """
    if exists:
        try:
            getattr(api, obj_type)().update(uuid=resource["uuid"], body=resource).execute()
        except Exception as e:
            raise raise_from(ResourceUpdateException("Failed to update %s: %s" % (obj_type, str(e))), e)
    else:
        try:
            getattr(api, obj_type)().create(body=resource).execute()
        except Exception as e:
            raise raise_from(ResourceCreateException("Failed to create %s: %s" % (obj_type, str(e))), e)


def _to_unicode(to_convert):
    """
    Converts all (byte as we're Py2) strings in the value to unicode strings (which are returned by Arvados API).
    :param to_convert: value to converted
    :type to_convert: Union[str, List, Dict]
    :return: unicoded up value
    """
    if isinstance(to_convert, int) or isinstance(to_convert, float) or to_convert is None:
        return to_convert
    if isinstance(to_convert, str):
        return six.u(to_convert)
    elif isinstance(to_convert, list):
        return [_to_unicode(item) for item in to_convert]
    elif isinstance(to_convert, dict):
        return {_to_unicode(key): _to_unicode(value) for key, value in to_convert.items()}
    raise ValueError("Cannot convert object of type %s to unicode" % type(to_convert))


def process(obj_type, additional_argument_spec, filter_property, filter_value_module_parameter,
            module_parameter_to_resource_parameter_map, value_equator=default_value_equator,
            required_value_modifier=default_required_value_modifier):
    """
    TODO
    :param obj_type: the type of object to commit
    :type obj_type: string
    :param additional_argument_spec: specification for additional Ansible module arguments
    :type additional_argument_spec: Dict[str, Dict]
    :param filter_property: the property to filter on when getting the resource that is to be updated
    :type filter_property: str
    :param filter_value_module_parameter: the name of the module parameter from which the value of the given
    `filter_property` should be equal to
    :type filter_value_module_parameter: str
    :param module_parameter_to_resource_parameter_map: map where the value is the name of the resource parameter that
    is to be set from the value of module parameter identified by the key
    :type module_parameter_to_resource_parameter_map: Dict[str, str]
    :param value_equator: optional function that can be used to decide if the give value associated to a resource
    parameter is equal to the given expected value
    :param required_value_modifier: TODO
    :type required_value_modifier: Callable[[Any, Any], Any]
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
    try:
        getattr(api, obj_type)
    except AttributeError as e:
        module.fail_json(msg="Arvados API does not appear to support objects of type %s: %s" 
                         % (obj_type, str(e)))
        
    filter_value = module.params[filter_value_module_parameter]
    try:
        resource, exists = get_resource(obj_type, api, filter_property, filter_value)
    except ResourceListException as e:
        module.fail_json(msg="Error getting %s resource: %s"
                         % (obj_type, str(e)))

    required_property_value_map = {
        _to_unicode(resource_param): _to_unicode(module.params[module_param])
        for module_param, resource_param in module_parameter_to_resource_parameter_map.items()}
    update_required, property_updates = prepare_update(
        resource, required_property_value_map, value_equator, required_value_modifier)

    if module.check_mode:
        module.exit_json(changed=update_required)
    elif not update_required:
        module.exit_json(changed=False, msg="%s resource already exists with the desired properties" % (obj_type))
    else:
        try:
            commit_resource(obj_type, api, resource, exists)
        except ResourceUpdateException as e:
            module.fail_json(msg="Error while attempting to update %s %s=%s (%s): %s"
                                  % (obj_type, filter_property, filter_value,
                                     ', '.join(["%s:%s" 
                                                % (prop, property_updates[prop]) 
                                                for prop in property_updates.keys()]), str(e)))
        except ResourceCreateException as e:
            module.fail_json(msg="Error while attempting to create %s %s=%s (%s): %s"
                                  % (obj_type, filter_property, filter_value,
                                     ', '.join(["%s:%s" 
                                                % (prop, resource[prop]) 
                                                for prop in property_updates.keys()]), str(e)))
        except Exception as e:
            module.fail_json(msg="Error while committing %s %s=%s (%s): %s"
                                  % (obj_type, filter_property, filter_value,
                                     ', '.join(["%s:%s" 
                                                % (prop, property_updates[prop]) 
                                                for prop in property_updates.keys()]), str(e)))
        module.exit_json(changed=True, msg="%s resource created: %s"
                         % (obj_type, ', '.join(["%s:%s"
                                                 % (prop, property_updates[prop])
                                                 for prop in property_updates.keys()])))
