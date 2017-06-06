#!/usr/bin/python
#
# Copyright (c) 2017 Genome Research Ltd.
#
# Author: Joshua C. Randall <jcrandall@alum.mit.edu>
#
# This file is part of hgi-systems.
#
# hgi-systems is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# file: library/gitlab_ci_multi_runner_register.sh

DOCUMENTATION = """
---
module: gitlab_ci_multi_runner_register
short_description: Register a runner with Gitlab CI
description:
  - Registers Gitlab CI Multi Runner with one or more Gitlab servers (identified by token and URL), and
    saves runner configuration to a config.toml fragment located in a config_dir suitable for passing into
    a subsequent `assemble` task.
author:
  - Joshua C. Randall <jcrandall@alum.mit.edu>
  - Colin Nolan <colin.nolan@sanger.ac.uk>
requirements:
  - python-gitlab 
"""

try:
    from gitlab import Gitlab, GitlabDeleteError, GitlabGetError
    _HAS_DEPENDENCIES = True
except ImportError as e:
    _IMPORT_ERROR = e
    _HAS_DEPENDENCIES = False

import os.path
import shlex
import subprocess
import json
from base64 import b64encode
from tempfile import NamedTemporaryFile
from ansible.module_utils.basic import AnsibleModule


def main():
    module = AnsibleModule(argument_spec={
        "gitlab_url": {"required": True, type: "str"},
        "gitlab_token": {"required": True, type: "str"},
        "description": {"required": True, "type": "str"},
        "registration_url": {"required": True, "type": "str"},
        "registration_token": {"required": True, "type": "str"},
        "config_dir": {"default": "/etc/gitlab-runner.d", "type": "str"},
        "executor": {"required": False, "type": "str"},
        "limit": {"required": False, "type": "str"},
        "tags": {"required": False, "type": "str"},
        "extra_args": {"required": False, "type": "str"},
        "enfore_unique_description": {"required": False, "default": True, "type": "bool"}
    })

    if not _HAS_DEPENDENCIES:
        module.fail_json(msg="A required Python module is not installed: %s" % _IMPORT_ERROR)

    configuration_path = "%s/description-%s.json" % (module.params["config_dir"], module.params["description"])
    output_toml_path = "%s/description-%s-token-%s-url-%s.toml" % (
    module.params["config_dir"], module.params["description"], module.params["registration_token"],
    b64encode(module.params["registration_url"]))

    config = dict()
    config["description"] = module.params["description"]
    config["registration_url"] = module.params["registration_url"]
    config["registration_token"] = module.params["registration_token"]
    config["configuration_path"] = configuration_path
    config["output_toml_path"] = output_toml_path
    if "executor" in module.params:
        config["executor"] = module.params["executor"]
    if "limit" in module.params:
        config["limit"] = module.params["limit"]
    if "tags" in module.params:
        config["tags"] = ",".join(sorted(module.params["tags"].split(",")))  # canonicalize order of tags
    if "extra_args" in module.params:
        config["extra_args"] = module.params["extra_args"]

    changed = False

    connector = Gitlab(module.params["gitlab_url"], module.params["gitlab_token"])
    try:
        runners = connector.runners.list(all=True)
        runners_tokens = {runner: connector.runners.get(runner.id).token for runner in runners}
    except GitlabGetError as e:
        module.fail_json(
            msg="Failed to get runners from gitlab API endpoint %s: %s" % (module.params["gitlab_url"], e))

    if os.path.isfile(configuration_path):
        with open(configuration_path) as file:
            existing_config = json.load(file)

        runner_registered = get_runner_token(config["output_toml_path"]) in runners_tokens.values()
        configuration_changed = existing_config != config

        if runner_registered:
            if not configuration_changed:
                module.exit_json(changed=False, message="Configuration unchanged")
            else:
                unregister_command = ["gitlab-ci-multi-runner", "unregister", "-c", existing_config["output_toml_path"],
                                      "-n", existing_config["description"]]
                unregister_process = subprocess.Popen(unregister_command, shell=False, stdout=subprocess.PIPE)
                unregister_process.wait()
                if unregister_process.returncode != 0:
                    module.exit_json(failed=True, changed=False, message="Failed to unregister old configuration",
                                     existing_config=existing_config)
        try:
            os.remove(existing_config["configuration_path"])
        except OSError:
            pass
        try:
            os.remove(existing_config["output_toml_path"])
        except OSError:
            pass
        changed = True

    register_command = [
        "gitlab-ci-multi-runner", "register", "-n", "--leave-runner", "--url", config["registration_url"],
        "--registration-token", config["registration_token"], "--description", config["description"]]
    if "executor" in config:
        register_command.extend(["--executor", config["executor"]])
    if "limit" in config:
        register_command.extend(["--limit", config["limit"]])
    if "tags" in config:
        register_command.extend(["--tag-list", config["tags"]])
    if "extra_args" in config:
        register_command.extend(shlex.split(config["extra_args"]))
    register_command.extend(["-c", config["output_toml_path"]])
    try:
        subprocess.check_output(register_command, shell=False, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        module.exit_json(failed=True, changed=changed,
                         message="Failed to register configuration (call to '%s' failed with status %s): %s" % (
                         e.cmd, e.returncode, e.output), config=config)
    changed = True

    sed_command = ["sed", "-ni", "/^\[\[runners\]\]/ { p; :a; n; p; ba; }", config["output_toml_path"]]
    sed_process = subprocess.Popen(sed_command, shell=False, stdout=subprocess.PIPE)
    sed_process.wait()
    if sed_process.returncode != 0:
        module.exit_json(failed=True, changed=changed,
                         message="Failed to process updated registration config TOML through sed", config=config)

    try:
        with NamedTemporaryFile(delete=False) as file:
            json.dump(config, file)
            file.close()
            module.atomic_move(file.name, configuration_path)

    except IOError as e:
        module.exit_json(failed=True, changed=changed,
                         message="Failed to write config JSON to %s: %s" % (configuration_path, e))

    deleted_runners = set()
    if module.params["enfore_unique_description"]:
        registered_runner_token = get_runner_token(config["output_toml_path"])
        try:
            projects = connector.projects.list(all=True)
        except GitlabGetError as e:
            module.fail_json(
                msg="Failed to get runners/projects from gitlab API endpoint %s: %s" % (module.params["gitlab_url"], e))
        for runner in runners:
            if runner.description == config["description"] and runners_tokens[runner] != registered_runner_token:
                deleted_runners.add(runner.description)
                delete_runner(runner, projects)

    module.exit_json(changed=True, message="Gitlab runner registered successfully. Deleted %d old runner(s): %s"
                                           % (len(deleted_runners), deleted_runners))


def delete_runner(runner, projects):
    """
    Deletes the given runner.
    :param runner: the runner to delete
    :param projects: projects that may have the runner registered
    """
    # GitLab won't let us remove a runner until it's no longer associated to a project
    for project in projects:
        if runner.id in {runner.id for runner in project.runners.list(all=True)}:
            try:
                project.runners.delete(runner.id)
            except GitlabDeleteError as e:
                if "Only one project associated with the runner" in e.error_message:
                    break
                else:
                    raise
    runner.delete()


def get_runner_token(output_toml_path):
    """
    Gets the current runners registration ID by reading the givne output toml file.
    :param output_toml_path: location of the output file, produced by the registration step
    :return: 
    """
    with open(output_toml_path) as file:
        for line in file.readlines():
            if line.strip().startswith("token ="):
                return line.split("=")[1].strip().replace('"', "")


if __name__ == "__main__":
    main()
