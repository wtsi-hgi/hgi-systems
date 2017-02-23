#!/usr/bin/python3
import simplejson
from ansible.module_utils.basic import *

from gitlabbuildvariables.common import GitLabConfig
from gitlabbuildvariables.update import DictBasedProjectVariablesUpdaterBuilder

DOCUMENTATION = """
---
module: gitlab_ci_build_variables_setter
short_description: Updates a project's GitLab CI build variables
description:
  - Updates a project's GitLab CI build variables to a given configuration, which defines which variable groups the
  project should have its variables set from.
author:
  - Colin Nolan <colin.nolan@sanger.ac.uk>
"""

GITLAB_URL_KEY = "gitlab_url"
GITLAB_TOKEN_KEY = "gitlab_token"
GITLAB_PROJECT_KEY = "gitlab_project"
REQUIRED_VARIABLE_GROUPS = "required_variable_groups"
VARIABLE_GROUPS = "variable_groups"

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
            REQUIRED_VARIABLE_GROUPS.encode(DEFAULT_ENCODING): {"required": True, type: "bytes"},
            VARIABLE_GROUPS.encode(DEFAULT_ENCODING): {"required": True, "type": "dict"},
        },
        supports_check_mode=True
    )

    # Converts bytes to strings, even if they are nested in dicts and lists.
    # Bother thanks to the long outdated Python 2 being the ruler of this world...
    string_params = simplejson.loads(simplejson.dumps(module.params))

    gitlab_config = GitLabConfig(string_params[GITLAB_URL_KEY], string_params[GITLAB_TOKEN_KEY])
    gitlab_project = string_params[GITLAB_PROJECT_KEY]
    required_variable_groups = string_params[REQUIRED_VARIABLE_GROUPS]
    project_updater_builder = DictBasedProjectVariablesUpdaterBuilder(string_params[VARIABLE_GROUPS])

    updater = project_updater_builder.build(project=gitlab_project, groups=required_variable_groups,
                                            gitlab_config=gitlab_config)

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
