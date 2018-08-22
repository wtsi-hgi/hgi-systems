#!/usr/bin/env python3

from enum import unique, Enum

from ansible.module_utils.basic import AnsibleModule
import subprocess

REPO_NAME_PARAMETER_NAME = "name"
STATE_PARAMETER_NAME = "state"
OPTIONS_PARAMETER_NAME = "options"
APTLY_BINARY_PARAMETER_NAME = "aptly_binary"

BYTE_STRING_ENCODING = "utf-8"
DEFAULT_APTLY_BINARY_LOCATION = "/usr/bin/aptly"

REPO_OPTIONS = {
    "comment": "Comment",
    "component": "Default Component",
    "distribution": "Default Distribution"
}


@unique
class RepoState(Enum):
    PRESENT = "present"
    ABSENT = "absent"


@unique
class ChangeState(Enum):
    DELETED = "deleted"
    EDITED = "edited"
    CREATED = "created"
    NONE = None


class RepositoryDoesNotExistError(RuntimeError):
    def __init__(self, repo_name):
        super().__init__("Repository \"%s\" does not exist" % (repo_name, ))


class InvalidRepositoryOptionsError(RuntimeError):
    def __init__(self, invalid_options):
        super().__init__("Invalid repository options: %s" % (invalid_options, ))
        self.invalid_options = invalid_options


def create_aptly_repo(repo_name, options, aptly_binary_location):
    option_pairs = _prepare_options(options)
    subprocess.run([aptly_binary_location, "repo", "create"] + option_pairs + [repo_name], check=True)
    assert does_aptly_repo_exist(repo_name, aptly_binary_location)


def edit_aptly_repo(repo_name, options, aptly_binary_location):
    if not does_aptly_repo_exist(repo_name, aptly_binary_location):
        raise RepositoryDoesNotExistError(repo_name)
    option_pairs = _prepare_options(options)
    subprocess.run([aptly_binary_location, "repo", "edit"] + option_pairs + [repo_name], check=True)


def delete_aptly_repo(repo_name, aptly_binary_location):
    subprocess.run([aptly_binary_location, "repo", "drop", repo_name], check=True)


def _prepare_options(options):
    options = {"-%s" % key: value for key, value in options.items() if not key.startswith("-")}
    return ["%s=%s" % (key, value) for key, value in options.items()]


def does_aptly_repo_exist(repo_name, aptly_binary_location):
    list_process = subprocess.run([aptly_binary_location, "repo", "list"], check=True, stdout=subprocess.PIPE)
    return "[%s]" % repo_name in list_process.stdout.decode(BYTE_STRING_ENCODING)


def get_aptly_repo_option_values(repo_name, aptly_binary_location):
    if not does_aptly_repo_exist(repo_name, aptly_binary_location):
        raise RepositoryDoesNotExistError(repo_name)
    show_process = subprocess.run([aptly_binary_location, "repo", "show", repo_name], check=True,
                                  stdout=subprocess.PIPE)

    options = {}
    key_lookup = {value: key for key, value in REPO_OPTIONS.items()}
    for line in show_process.stdout.decode(BYTE_STRING_ENCODING).split("\n"):
        if line.strip() == "":
            break
        key, value = (item.strip() for item in line.split(":"))
        if key in key_lookup:
            options[key_lookup[key]] = value

    assert validate_options(options) is None
    return options


def validate_options(options):
    invalid_keys = {key for key in options.keys() if key not in REPO_OPTIONS}
    if len(invalid_keys) > 0:
        raise InvalidRepositoryOptionsError(invalid_keys)


def repo_has_options(repo_name, options, aptly_binary_location):
    existing_options = get_aptly_repo_option_values(repo_name, aptly_binary_location)

    for name, value in options.items():
        if existing_options.get(name) != value:
            return False
    return True


def main():
    module = AnsibleModule(
        argument_spec={
            REPO_NAME_PARAMETER_NAME: dict(type="str", required=True),
            STATE_PARAMETER_NAME: dict(type="str", default=RepoState.PRESENT.value,
                                       choices=[state.value for state in RepoState]),
            OPTIONS_PARAMETER_NAME: dict(type="dict", default={}),
            APTLY_BINARY_PARAMETER_NAME: dict(type="str", default=DEFAULT_APTLY_BINARY_LOCATION),
        },
        supports_check_mode=True
    )

    repo_name = module.params[REPO_NAME_PARAMETER_NAME]
    state = RepoState(module.params[STATE_PARAMETER_NAME])
    options = module.params[OPTIONS_PARAMETER_NAME]
    aptly_binary_location = module.params[APTLY_BINARY_PARAMETER_NAME]

    validate_options(options)

    change = ChangeState.NONE
    if state == RepoState.ABSENT:
        if does_aptly_repo_exist(repo_name, aptly_binary_location):
            if not module.check_mode:
                delete_aptly_repo(repo_name, aptly_binary_location)
            change = ChangeState.DELETED
    elif state == RepoState.PRESENT:
        if not does_aptly_repo_exist(repo_name, aptly_binary_location):
            if not module.check_mode:
                create_aptly_repo(repo_name, options, aptly_binary_location)
            change = ChangeState.CREATED
            # Default options would have been set on creation
            options = get_aptly_repo_option_values(repo_name, aptly_binary_location)
        else:
            if not repo_has_options(repo_name, options, aptly_binary_location):
                if not module.check_mode:
                    edit_aptly_repo(repo_name, options, aptly_binary_location)
                change = ChangeState.EDITED
                options = get_aptly_repo_option_values(repo_name, aptly_binary_location)

    exit_kwargs = dict(changed=change != ChangeState.NONE, change=change.value)
    if change != ChangeState.DELETED:
        exit_kwargs["options"] = options
    module.exit_json(**exit_kwargs)


if __name__ == "__main__":
    main()
