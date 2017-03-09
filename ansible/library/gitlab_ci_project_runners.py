#!/usr/bin/python3

from ansible.module_utils.basic import *

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
            "gitlab_url": {"required": True, type: "bytes"},
            "gitlab_token": {"required": True, type: "bytes"},
            "gitlab_project": {"required": True, type: "bytes"},
            "gitlab_runners": {"required": True, "type": "list"}
        },
        supports_check_mode=True
    )

    if not _HAS_DEPENDENCIES:
        module.fail_json(msg="A required dependency is not installed: %s" % _IMPORT_ERROR)

    connector = Gitlab(module.params["gitlab_url"], module.params["gitlab_token"])
    project = connector.projects.get(module.params["gitlab_project"])
    required_runners = {runner.description: runner.id for runner in connector.runners.list(all=True)}
    required_runner_ids = {required_runners[runner_description] for runner_description in module.params["gitlab_project"]}
    current_runner_ids = {runner.id for runner in project.runners.list(all=True)}

    to_remove = current_runner_ids - required_runner_ids
    to_add = required_runner_ids - current_runner_ids

    update_required = len(to_add) + len(to_remove) > 0
    if module.check_mode:
        module.exit_json(changed=update_required)
    else:
        if not update_required:
            module.exit_json(
                changed=False, message="Project runners for %s already set correctly" % project.path_with_namespace)
        else:
            for runner_id in to_remove:
                project.runners.delete(runner_id)
            for runner_id in to_add:
                project.runners.create(runner_id)
            assert {runner.id for runner in project.runners.list(all=True)} == required_runner_ids


if __name__ == "__main__":
    main()
