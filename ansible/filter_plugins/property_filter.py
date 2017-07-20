import re
from typing import Dict, Any, List

IN_LIST_PROPERTY_MANIPULATION_FILTER_NAME = "manipulate_in_list"
PROPERTY_MANIPULATION_FILTER_NAME = "manipulate"


def dict_in_list_property_manipulation(
        data: List[Dict[str, Any]], property: str, find: str= "(.*)", replace: str= "\1") -> List[Dict[str, Any]]:
    """
    Filter for manipulating a property (if it exists) in each dictionary in a given list.
    :param data: the list of dictionaries dictionary to apply the filter to
    :param property: the name of the property with the value to change
    :param find: find regex
    :param replace: replace regex
    :return: reference to the given data
    """
    if not isinstance(data, list):
        raise ValueError(f"This filter only applies to lists - {data.__class__.__name__} given")

    for value in data:
        dict_property_manipulation(value, property, find, replace)

    return data


def dict_property_manipulation(
        data: Dict[str, Any], property: str, find: str="(.*)", replace: str="\1") -> Dict[str, Any]:
    """
    Filter for manipulating a property (if it exists) in a given dictionary.
    :param data: the dictionary to apply the filter to
    :param property: the name of the property with the value to change
    :param find: find regex
    :param replace: replace regex
    :return: reference to the given data
    """
    if not isinstance(data, dict):
        raise ValueError(f"This filter only applies to dicts - {data.__class__.__name__} encountered")

    if property in data:
        data[property] = re.sub(find, replace, data[property])

    return data


class FilterModule(object):
    """
    Package the filter for use in Ansible.
    """
    def filters(self):
        return {
            IN_LIST_PROPERTY_MANIPULATION_FILTER_NAME: dict_in_list_property_manipulation,
            PROPERTY_MANIPULATION_FILTER_NAME: dict_property_manipulation
        }
