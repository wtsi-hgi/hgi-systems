#!/usr/bin/python
import json
import subprocess

import sys
from ansible.module_utils.basic import AnsibleModule

DEFAULT_MAXIMUM_BACKUPS = 10
DEFAULT_BACKUP_NAME_SUFFIX = ""

INFO_SCRIPT_LOCATION_PARAMETER = "script"
CURRENT_BACKUPS_PARAMETER = "current"
MAXIMUM_BACKUPS_PARAMETER = "max"
BACKUP_NAME_SUFFIX_PARAMETER = "suffix"
PYTHON_EXECUTABLE_PARAMETER = "python"
MC_LOCATION_PARAMETER = "mc"
MC_CONFIG_PARAMETER = "mc-config"
MC_S3_LOCATION_PARAMETER = "mc-s3-location"

_MAX_NUMBER_OF_BACKUPS_LONG_CLI_PARAMETER = "backups"
_BACKUP_NAME_SUFFIX_LONG_CLI_PARAMETER = "suffix"
_MC_LOCATION_LONG_CLI_PARAMETER = "mc"
_MC_CONFIG_LONG_CLI_PARAMETER = "mc-config"
_MC_S3_LOCATION_LONG_CLI_PARAMETER = "mc-s3-location"

_TO_DELETE_JSON_PARAMETER = "delete"
_LATEST_BACKUP_NAME_JSON_PARAMETER = "latest"
_NEW_BACKUP_NAME_JSON_PARAMETER = "new"
_CURRENT_BACKUP_NAMES_JSON_PARAMETER = "current"


_ARGUMENT_SPEC = {
    INFO_SCRIPT_LOCATION_PARAMETER: dict(required=True, type="str"),
    CURRENT_BACKUPS_PARAMETER: dict(default=[], type="list"),
    MAXIMUM_BACKUPS_PARAMETER: dict(default=DEFAULT_MAXIMUM_BACKUPS, type="int"),
    BACKUP_NAME_SUFFIX_PARAMETER: dict(default=DEFAULT_BACKUP_NAME_SUFFIX, type="str"),
    PYTHON_EXECUTABLE_PARAMETER: dict(default=sys.executable, type="str"),
    MC_LOCATION_PARAMETER: dict(type="str"),
    MC_CONFIG_PARAMETER: dict(type="str"),
    MC_S3_LOCATION_PARAMETER: dict(type="str")
}


def main():
    module = AnsibleModule(_ARGUMENT_SPEC, supports_check_mode=False)

    script_location = module.params.get(INFO_SCRIPT_LOCATION_PARAMETER)
    current_backups = module.params.get(CURRENT_BACKUPS_PARAMETER)
    maximum_number_of_backups = module.params.get(MAXIMUM_BACKUPS_PARAMETER)
    backup_name_suffix = module.params.get(BACKUP_NAME_SUFFIX_PARAMETER)
    python_executable = module.params.get(PYTHON_EXECUTABLE_PARAMETER)

    mc_location = module.params.get(MC_LOCATION_PARAMETER)
    mc_config = module.params.get(MC_CONFIG_PARAMETER)
    mc_s3_location = module.params.get(MC_S3_LOCATION_PARAMETER)

    mc_arguments = []
    if mc_location is not None:
        if mc_s3_location is None:
            raise ValueError("`%s` must be set with `%s`" % (MC_CONFIG_PARAMETER, MC_S3_LOCATION_PARAMETER))
        mc_arguments = [
            "--%s" % _MC_LOCATION_LONG_CLI_PARAMETER, mc_location,
            "--%s" % _MC_S3_LOCATION_LONG_CLI_PARAMETER, mc_s3_location
        ]
        if mc_config is not None:
            mc_arguments += ["--%s" % _MC_CONFIG_LONG_CLI_PARAMETER, mc_config]
    arguments = [python_executable, script_location,
                 "--%s" % _MAX_NUMBER_OF_BACKUPS_LONG_CLI_PARAMETER, str(maximum_number_of_backups),
                 "--%s" % _BACKUP_NAME_SUFFIX_LONG_CLI_PARAMETER, backup_name_suffix] \
                + mc_arguments + current_backups

    process = subprocess.Popen(arguments, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    if process.returncode != 0:
        module.fail_json(msg=stderr, arguments=arguments)

    information = json.loads(stdout)

    return_values = dict(changed=False, new=information[_NEW_BACKUP_NAME_JSON_PARAMETER],
                         latest=information[_LATEST_BACKUP_NAME_JSON_PARAMETER],
                         delete=information[_TO_DELETE_JSON_PARAMETER],
                         current=information[_CURRENT_BACKUP_NAMES_JSON_PARAMETER])
    module.exit_json(**return_values)


if __name__ == "__main__":
    main()
