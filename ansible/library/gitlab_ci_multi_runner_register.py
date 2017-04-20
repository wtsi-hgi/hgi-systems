#!/usr/bin/python
#
# Copyright (c) 2017 Genome Research Ltd.
#
# Author: Joshua C. Randall <jcrandall@alum.mit.edu>
#
# This file is part of hgi-ansible.
#
# hgi-ansible is free software: you can redistribute it and/or modify it
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
"""

import os.path
import shlex
import subprocess
import json
from base64 import b64encode
from tempfile import NamedTemporaryFile
from ansible.module_utils.basic import AnsibleModule

def main():
    module = AnsibleModule(argument_spec={
        "description": {"required": True, "type": "str"},
        "registration_url": {"required": True, "type": "str"},
        "registration_token": {"required": True, "type": "str"},
        "config_dir": {"default": "/etc/gitlab-runner.d", "type": "str"},
        "executor": {"required": False, "type": "str"},
        "limit": {"required": False, "type": "str"},
        "tags": {"required": False, "type": "str"},
        "extra_args": {"required": False, "type": "str"},
    })

    configuration_path = "%s/description-%s.json" % (module.params["config_dir"], module.params["description"])
    output_toml_path = "%s/description-%s-token-%s-url-%s.toml" % (module.params["config_dir"], module.params["description"], module.params["registration_token"], b64encode(module.params["registration_url"]))

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
        config["tags"] = ",".join(sorted(module.params["tags"].split(","))) # canonicalize order of tags
    if "extra_args" in module.params:
        config["extra_args"] = module.params["extra_args"]

    changed=False

    if os.path.isfile(configuration_path):
        with open(configuration_path) as f:
            existing_config = json.load(f)
            if cmp(existing_config, config) == 0:
                # configuration has not changed from existing, no changes required
                module.exit_json(changed=False, message="Configuration unchanged")
            else:
                # configuration has changed, unregister and remove so we can re-register
                unregister_command = ["gitlab-ci-multi-runner", "unregister", "-c", existing_config["output_toml_path"], "-n", existing_config["description"]]
                unregister_process = subprocess.Popen(unregister_command, shell=False, stdout=subprocess.PIPE)
                unregister_process.wait()
                if unregister_process.returncode != 0:
                    module.exit_json(failed=True, changed=False, message="Failed to unregister old configuration", existing_config=existing_config)
                try:
                    os.remove(existing_config["configuration_path"])
                except OSError:
                    pass
                try:
                    os.remove(existing_config["output_toml_path"])
                except OSError:
                    pass
                changed=True

    register_command = ["gitlab-ci-multi-runner", "register", "-n", "--url", config["registration_url"], "--registration-token", config["registration_token"], "--description", config["description"]]
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
        register_output = subprocess.check_output(register_command, shell=False, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        module.exit_json(failed=True, changed=changed, message="Failed to register configuration (call to '%s' failed with status %s): %s" % (e.cmd, e.returncode, e.output), config=config)
    changed=True

    sed_command = ["sed", "-ni", "/^\[\[runners\]\]/ { p; :a; n; p; ba; }", config["output_toml_path"]]
    sed_process = subprocess.Popen(sed_command, shell=False, stdout=subprocess.PIPE)
    sed_process.wait()
    if sed_process.returncode != 0:
        module.exit_json(failed=True, changed=changed, message="Failed to process updated registration config TOML through sed", config=config)

    try:
        with NamedTemporaryFile(delete=False) as f:
            json.dump(config, f)
            f.close()
            module.atomic_move(f.name, configuration_path)

    except IOError as e:
        module.exit_json(failed=True, changed=changed, message="Failed to write config JSON to %s: %s" % (configuration_path, e))

    module.exit_json(changed=True, message="Gitlab runner registered successfully")

if __name__ == "__main__":
    main()
