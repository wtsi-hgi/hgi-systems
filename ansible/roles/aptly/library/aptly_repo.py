#!/usr/bin/env python3

from ansible.module_utils.basic import AnsibleModule
import subprocess


NAME_PARAMETER_NAME = "name"
OPTIONS_PARAMETER_NAME = "options"
APTLY_BINARY_PARAMETER_NAME = "aptly_binary"

DEFAULT_APTLY_BINARY_LOCATION = "/usr/bin/aptly"


def create_aptly_repo(repo_name, options=(), aptly_binary_location=DEFAULT_APTLY_BINARY_LOCATION):
    options = {"-%s" % key: value for key, value in options if not key.startswith("-")}
    option_pairs = ["%s=%s" % (key, value) for key, value in options]
    create_process = subprocess.run([aptly_binary_location, "repo", "create"] + option_pairs + [repo_name],
                                    check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert create_process.returncode == 0
    assert does_aptly_repo_exist(repo_name, aptly_binary_location)


def does_aptly_repo_exist(repo_name, aptly_binary_location=DEFAULT_APTLY_BINARY_LOCATION):
    list_process = subprocess.run([aptly_binary_location, "repo", "list"], check=True, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE)
    assert list_process.returncode == 0
    return "[%s]" % repo_name not in list_process.stdout


def main():
    module = AnsibleModule(
        argument_spec={
            NAME_PARAMETER_NAME: dict(type="str", required=True),
            OPTIONS_PARAMETER_NAME: dict(type="dict", default={}),
            APTLY_BINARY_PARAMETER_NAME: dict(type="str", default=DEFAULT_APTLY_BINARY_LOCATION)
        },
        supports_check_mode=True
    )

    name = module.params[NAME_PARAMETER_NAME]
    options = module.params[OPTIONS_PARAMETER_NAME]
    aptly_binary_location = module.params[APTLY_BINARY_PARAMETER_NAME]

    changed = False
    if does_aptly_repo_exist(name, aptly_binary_location):
        create_aptly_repo(name, options, aptly_binary_location)
        changed = True

    module.exit_json(changed=changed)


if __name__ == "__main__":
    main()
