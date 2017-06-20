#!/usr/bin/python3

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
    required: true
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

try:
    from gitlab import Gitlab, GitlabGetError, GitlabDeleteError

    _HAS_DEPENDENCIES = True
except ImportError as e:
    _IMPORT_ERROR = e
    _HAS_DEPENDENCIES = False

from ansible.module_utils.basic import AnsibleModule
import json


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
    try:
        project = connector.projects.get(module.params["gitlab_project"])
    except GitlabGetError as e:
        module.fail_json(msg="Failed to get project %s from gitlab API endpoint %s: %s" % (module.params["gitlab_project"], module.params["gitlab_url"], e))

    try:
        runners_list = connector.runners.list(all=True)
    except GitlabGetError as e:
        module.fail_json(msg="Failed to get runners from gitlab API endpoint %s: %s" % (module.params["gitlab_url"], e))

    # Detect when there is more than one match for a runner (runner descriptions are not unique after all)
    existing_runner_descriptions = set()
    duplicates = set()
    for runner in runners_list:
        if runner.description in runner_descriptions:
            if runner.description in existing_runner_descriptions:
                duplicates.add(runner.description)
            else:
                existing_runner_descriptions.add(runner.description)
    if len(duplicates) > 0:
        module.fail_json(msg="Cannot set project runners because there is more than one match for runner(s) with the "
                             "description(s): %s" % duplicates)

    runners = {runner.description: runner.id for runner in runners_list}
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
                try:                
                    project.runners.delete(runner_id)
                except GitlabDeleteError:
                    # could not remove from project, try deleting the runner entirely
                    # TODO: should probably check this is the only project associated with the runner 
                    # and possibly require an argument such as delete_runners = True
                    try:
                        connector.runners.delete(runner_id)
                    except GitlabDeleteError as e:
                        module.fail_json(msg="Failed to delete runner %s: %s" % (runner_id, e), information=information)

            for runner_id in to_add:
                project.runners.create({"runner_id": runner_id})
            if disable_shared_runners:
                # Fixes https://github.com/wtsi-hgi/hgi-systems/issues/9 by working around issue with GitLab library:
                # https://github.com/gpocentek/python-gitlab/issues/250
                del project.name
                del project.public
                del project.visibility_level
                project.shared_runners_enabled = False
                project.save()
            assert {runner.id for runner in project.runners.list(all=True, scope="specific")} == required_runner_ids
            module.exit_json(
                changed=True, message="Gitlab runners set for %s" % project.path_with_namespace, meta=information)


if __name__ == "__main__":
    main()
