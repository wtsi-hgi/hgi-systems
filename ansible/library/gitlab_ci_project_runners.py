#!/usr/bin/python3

from ansible.module_utils.basic import *
import json

try:
    from gitlab import Gitlab
    _HAS_DEPENDENCIES = True
except ImportError as e:
    _IMPORT_ERROR = e
    _HAS_DEPENDENCIES = False


DOCUMENTATION = """
---
module: gitlab_ci_project_runners
short_description: Sets Gitlab project runners
description:
  - Sets runners for a Gitlab project project to those given in the gitlab_runners list.
author:
  - Colin Nolan <colin.nolan@sanger.ac.uk>
options:
  gitlab_url:
    description: 
      - URL for the gitlab system on which the project is hosted
    required: true
  gitlab_token:
    description:
      - Token with which to authenticate to gitlab
    required: true
  gitlab_project:
    description:
      - Project name, usually of the form <group>/<project>
    required: false
  runners:
    description:
      - List of runners, identified by their descriptions (NOT their ids!)
    required: true
requirements:
  - "python >= 3"
  - "python-gitlab >= 0.18"
"""

EXAMPLES = """
- name: Set gitlab project runners
  gitlab_ci_project_runners: 
    gitlab_url: https://gitlab.com
    gitlab_project: gitlab-org/gitlab-ce
    gitlab_token: xxx
    gitlab_runners: 
      - gitlab-ci-runner-docker-01
      - gitlab-ci-runner-docker-02
"""


def main():
    module = AnsibleModule(
        argument_spec={
            "gitlab_url": {"required": True, type: "str"},
            "gitlab_token": {"required": True, type: "str"},
            "gitlab_project": {"required": True, type: "str"},
            "gitlab_runners": {"required": True, type: "list"}
        },
        supports_check_mode=True
    )

    # TODO: Ansible keeps stringifying the list! Going to hack my way through this issue for now...
    runner_descriptions = module.params["gitlab_runners"]
    if isinstance(runner_descriptions, str):
        runner_descriptions = json.loads(runner_descriptions.replace("'", "\""))
        assert isinstance(runner_descriptions, list)

    if not _HAS_DEPENDENCIES:
        module.fail_json(msg="A required Python module is not installed: %s" % _IMPORT_ERROR)

    connector = Gitlab(module.params["gitlab_url"], module.params["gitlab_token"])
    project = connector.projects.get(module.params["gitlab_project"])
    runners = {runner.description: runner.id for runner in connector.runners.list(all=True)}
    required_runner_ids = {runners[runner_description] for runner_description in runner_descriptions}
    current_runner_ids = {runner.id for runner in project.runners.list(all=True, scope="specific")}

    to_remove = current_runner_ids - required_runner_ids
    to_add = required_runner_ids - current_runner_ids
    disable_shared_runners = project.shared_runners_enabled

    update_required = len(to_add) + len(to_remove) > 0 or disable_shared_runners
    information = {
        "setup": {
            "shared_runners_enabled": project.shared_runners_enabled,
            "required": list(required_runner_ids),
            "existing": list(current_runner_ids)
        },
        "changes": {
            "remove": list(to_remove),
            "add": list(to_add),
            "disable_shared_runners": disable_shared_runners
        }
    }
    if module.check_mode:
        module.exit_json(changed=update_required, meta=information)
    else:
        if not update_required:
            module.exit_json(
                changed=False, message="Project runners for %s already set correctly" % project.path_with_namespace,
                meta=information)
        else:
            for runner_id in to_remove:
                project.runners.delete(runner_id)
            for runner_id in to_add:
                project.runners.create({"runner_id": runner_id})
            if disable_shared_runners:
                project.shared_runners_enabled = False
                project.save()
            assert {runner.id for runner in project.runners.list(all=True, scope="specific")} == required_runner_ids
            module.exit_json(
                changed=True, message="Gitlab runners set for %s" % project.path_with_namespace, meta=information)


if __name__ == "__main__":
    main()
