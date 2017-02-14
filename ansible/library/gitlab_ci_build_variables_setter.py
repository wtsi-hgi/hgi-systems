from gitlabbuildvariables.common import GitLabConfig
from gitlabbuildvariables.updater import ProjectVariablesUpdater, ProjectsVariablesUpdater
from ansible.module_utils.basic import AnsibleModule

DOCUMENTATION = """
---
module: gitlab_ci_build_variables_setter
short_description: TODO
description:
  - TODO
author:
  - Colin Nolan <colin.nolan@sanger.ac.uk>
"""


def main():
    module = AnsibleModule(
        argument_spec={
            "gitlab_url": {"required": True, "type": "str"},
            "gitlab_token": {"required": True, "type": "str"},
            "configuration_path": {"required": True, "type": "str"},
            "settings_repositories": {"required": True, "type": "list"},
            "default_setting_extensions": {"required": False, "default": [], "type": "list"},
            "gitlab_project": {"required": False, "default": None, "type": "str"}
        },
        supports_check_mode=True
    )

    gitlab_config = GitLabConfig(module.params["gitlab_url"], module.params["gitlab_token"])
    project = module.params["gitlab_project"]
    config_path = module.params["configuration_path"]
    shared_kwargs = dict(settings_repositorie=module.params["settings_repositories"],
                         default_setting_extensions=module.params["default_setting_extensions"])

    if project is not None:
        with open(config_path, "r") as config_file:
            config = config_file.read()
        if project not in config:
            module.exit_json(failed=True, changed=False, message="No known configuration for project: \"%s\"" % project)
        updater = ProjectVariablesUpdater(project, config[project], gitlab_config, **shared_kwargs)
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
