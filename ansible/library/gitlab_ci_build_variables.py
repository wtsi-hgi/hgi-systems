#!/usr/bin/python3

DOCUMENTATION = """
---
module: gitlab_ci_build_variables
short_description: Sets Gitlab project build variables
description:
  - Sets GitLab build variables for a project to those given in the variables dictionary.
author:
  - Colin Nolan <colin.nolan@sanger.ac.uk>
  - Joshua C. Randall <jcrandall@alum.mit.edu>
options:
  gitlab_url:
    description: 
      - URL for the gitlab system on which the project is hosted
    required: true
  gitlab_project:
    description:
      - Project name, usually of the form <group>/<project>
    required: false
  gitlab_token:
    description:
      - Token with which to authenticate to gitlab
    required: true
  variables:
    description:
      - Dictionary of variable name / value pairs to set for project
    required: true
requirements:
  - "python >= 3"
  - "gitlabbuildvariables"
"""

EXAMPLES = """
- name: Set gitlab build variables
  gitlab_ci_build_variables: 
    gitlab_url: https://gitlab.com
    gitlab_project: gitlab-org/gitlab-ce
    gitlab_token: xxx
    variables: 
      SECRET_VAR_1: "secret value 1"
      SECRET_VAR_2: "secret value 2"
"""

try:
    from gitlabbuildvariables.common import GitLabConfig
    from gitlabbuildvariables.update import DictBasedProjectVariablesUpdaterBuilder
    HAS_GITLABBUILDVARIABLES = True
except ImportError:
    HAS_GITLABBUILDVARIABLES = False

def main():
    module = AnsibleModule(
        argument_spec={
            "gitlab_url": {"required": True, type: "bytes"},
            "gitlab_project": {"required": False, "default": None, type: "bytes"},
            "gitlab_token": {"required": True, type: "bytes"},
            "variables": {"required": True, "type": "dict"},
        },
        supports_check_mode=True
    )

    if not HAS_GITLABBUILDVARIABLES:
        module.fail_json(msg="gitlabbuildvariables is required for this module")

    gitlab_config = GitLabConfig(module.params["gitlab_url"], module.params["gitlab_token"])
    gitlab_project = module.params["gitlab_project"]
    project_updater_builder = DictBasedProjectVariablesUpdaterBuilder({"variables": module.params["variables"]})

    updater = project_updater_builder.build(project=gitlab_project, groups=["variables"],
                                            gitlab_config=gitlab_config)

    update_required = updater.update_required()
    if module.check_mode:
        module.exit_json(changed=update_required)
    else:
        if not update_required:
            module.exit_json(changed=False, message="Gitlab build variables already set")
        else:
            updater.update()
            module.exit_json(changed=True, message="Gitlab build variables updated successfully")

from ansible.module_utils.basic import *
if __name__ == "__main__":
    main()
