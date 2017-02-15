#!/usr/bin/python3
from typing import Dict, Any

from ansible.module_utils.basic import *

from gitlabbuildvariables.common import GitLabConfig
from gitlabbuildvariables.updater import ProjectVariablesUpdater, ProjectsVariablesUpdater

DOCUMENTATION = """
---
module: gitlab_ci_build_variables_setter
short_description: TODO
description:
  - TODO
author:
  - Colin Nolan <colin.nolan@sanger.ac.uk>
"""

GITLAB_URL_KEY = "gitlab_url"
GITLAB_TOKEN_KEY = "gitlab_token"
GITLAB_PROJECT_KEY = "gitlab_project"
CONFIGURATION_PATH = "configuration_path"
SETTING_REPOSITORIES = "settings_repositories"
DEFAULT_SETTING_EXTENSIONS = "default_setting_extensions"

# See: https://docs.ansible.com/ansible/dev_guide/developing_modules_python3.html#reading-and-writing-to-files
DEFAULT_ENCODING = "utf-8"


def main():
    module = AnsibleModule(
        # XXX: I don't think there's a way of getting strings thanks to the "Unicode Sandwich" model that Ansible has
        # adapted to cope with Python 3:
        # https://docs.ansible.com/ansible/dev_guide/developing_modules_python3.html#unicode-sandwich
        argument_spec={
            GITLAB_URL_KEY.encode(DEFAULT_ENCODING): {"required": True, type: "bytes"},
            GITLAB_TOKEN_KEY.encode(DEFAULT_ENCODING): {"required": True, type: "bytes"},
            GITLAB_PROJECT_KEY.encode(DEFAULT_ENCODING): {"required": False, "default": None, type: "bytes"},
            CONFIGURATION_PATH.encode(DEFAULT_ENCODING): {"required": True, type: "bytes"},
            SETTING_REPOSITORIES.encode(DEFAULT_ENCODING): {"required": True, "type": "list"},
            DEFAULT_SETTING_EXTENSIONS.encode(DEFAULT_ENCODING): {"required": False, "default": [], "type": "list"}
        },
        supports_check_mode=True
    )

    # Bother thanks to the long outdated Python 2 being the ruler of this world...
    string_params = {}  # type: Dict[str, Any]
    for key, value in module.params.items():
        key = key.decode(DEFAULT_ENCODING)
        if isinstance(value, bytes):
            value = value.decode(DEFAULT_ENCODING)
        elif isinstance(value, list):
            items = []
            for item in value:
                items.append(item.decode(DEFAULT_ENCODING) if isinstance(item, bytes) else value)
            value = items

        string_params[key] = value

    gitlab_config = GitLabConfig(string_params[GITLAB_URL_KEY], string_params[GITLAB_TOKEN_KEY])
    gitlab_project = string_params[GITLAB_PROJECT_KEY]
    config_path = string_params[CONFIGURATION_PATH]
    shared_kwargs = dict(setting_repositories=string_params[SETTING_REPOSITORIES],
                         default_setting_extensions=string_params[DEFAULT_SETTING_EXTENSIONS])

    if gitlab_project is not None:
        with open(config_path, "r") as config_file:
            config = config_file.read()
        if gitlab_project not in config:
            module.exit_json(failed=True, changed=False, message="No known configuration for project: \"%s\""
                                                                 % gitlab_project)
        updater = ProjectVariablesUpdater(gitlab_project, config[gitlab_project], gitlab_config, **shared_kwargs)
    else:
        updater = ProjectsVariablesUpdater(config_path, gitlab_config, **shared_kwargs)

    update_required = updater.update_required()
    if module.check_mode:
        module.exit_json(changed=update_required)
    else:
        if not update_required:
            module.exit_json(changed=False, message="Gitlab CI build variables set as required")
        else:
            updater.update()
            module.exit_json(changed=True, message="Gitlab CI build variables updated successfully")


if __name__ == "__main__":
    main()
