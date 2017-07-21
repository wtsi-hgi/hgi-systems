#!/usr/bin/env python3
EXAMPLES = """
- gitcommonsync:
    repository: git@gitlab.example.com:user/repository.git
    committer_name: Ansible Synchroniser
    committer_email: team@example.com
    key_file: /custom/id_rsa
    files:
      - src: /example/README.md
        dest: README.md
        overwrite: false
      - src: /example/directory/
        dest: config
    templates:
      - src: /example/ansible-groups.sh.j2
        dest: ci/before_scripts.d/start.sh
        variables:
          message: "Hello world"
        overwrite: true
    subrepos:
      - src: http://www.example.com/other-repository.git
        dest: subrepos/other-repository
        branch: master
        overwrite: true
"""

try:
    from gitcommonsync.synchronisers import TemplateSynchroniser, Synchronisable
    from gitcommonsync.repository import GitRepository, GitCheckout
    from gitcommonsync.models import TemplateSynchronisation, FileSynchronisation, SubrepoSynchronisation
    from gitcommonsync.helpers import synchronise
    _HAS_DEPENDENCIES = True
except ImportError as e:
    _HAS_DEPENDENCIES = False
    _IMPORT_ERROR = e

import sys
import traceback
from typing import Any, Dict, Tuple, List, Type, DefaultDict

from ansible.module_utils.basic import AnsibleModule


REPOSITORY_URL_PROPERTY = "repository"
REPOSITORY_BRANCH_PROPERTY = "branch"
REPOSITORY_COMMITTER_NAME_PROPERTY = "committer_name"
REPOSITORY_COMMITTER_EMAIL_PROPERTY = "committer_email"
REPOSITORY_KEY_FILE_PROPERTY = "key_file"

TEMPLATES_PROPERTY = "templates"
FILES_PROPERTY = "files"
SUBREPOS_PROPERTY = "subrepos"

TEMPLATE_SOURCE_PROPERTY = "src"
TEMPLATE_DESTINATION_PROPERTY = "dest"
TEMPLATE_OVERWRITE_PROPERTY = "overwrite"
TEMPLATE_VARIABLES_PROPERTY = "variables"

FILE_SOURCE_PROPERTY = "src"
FILE_DESTINATION_PROPERTY = "dest"
FILE_OVERWRITE_PROPERTY = "overwrite"

SUBREPO_URL_PROPERTY = "src"
SUBREPO_BRANCH_PROPERTY = "branch"
SUBREPO_COMMIT_PROPERTY = "commit"
SUBREPO_DIRECTORY_PROPERTY = "dest"
SUBREPO_OVERWRITE_PROPERTY = "overwrite"

CHANGED_TEMPLATES_RETURN_PROPERTY = "templates"
CHANGED_FILES_RETURN_PROPERTY = "files"
CHANGED_SUBREPOS_RETURN_PROPERTY = "subrepos"

_ARGUMENT_SPEC = {
    REPOSITORY_URL_PROPERTY: dict(required=True, type="str"),
    REPOSITORY_BRANCH_PROPERTY: dict(required=False, default="master", type="str"),
    REPOSITORY_COMMITTER_NAME_PROPERTY: dict(required=False, type="str"),
    REPOSITORY_COMMITTER_EMAIL_PROPERTY: dict(required=False, type="str"),
    REPOSITORY_KEY_FILE_PROPERTY: dict(required=False, type="str"),
    TEMPLATES_PROPERTY: dict(required=False, default=[], type="list"),
    FILES_PROPERTY: dict(required=False, default=[], type="list"),
    SUBREPOS_PROPERTY: dict(required=False, default=[], type="list")
}


def fail_if_missing_dependencies(module: AnsibleModule):
    """
    Fails if this module is missing a required dependency.
    :param module: the Ansible Module
    """
    if sys.version_info < (3, 6):
        module.fail_json(msg="Python 3.6 or above is required (current version: %s)" % sys.version_info)

    if not _HAS_DEPENDENCIES:
        module.fail_json(msg="A required Python module is not installed: %s" % traceback.format_exception(
            type(_IMPORT_ERROR), _IMPORT_ERROR, _IMPORT_ERROR.__traceback__))


def parse_configuration(arguments: Dict[str, Any]) -> Tuple["GitRepository", List["Synchronisable"]]:
    """
    Parses the configuration defined in Ansible.
    :param arguments: the arguments passed to this module by Ansible
    :return: tuple where the first element is the git repository that is to be synchronised and the seocnd is the
    configuration that defines how it is to be synchronised
    """
    repository_location = arguments[REPOSITORY_URL_PROPERTY]
    branch = arguments[REPOSITORY_BRANCH_PROPERTY]
    committer_name = arguments[REPOSITORY_COMMITTER_NAME_PROPERTY]
    committer_email = arguments[REPOSITORY_COMMITTER_EMAIL_PROPERTY]
    private_key_file = arguments[REPOSITORY_KEY_FILE_PROPERTY]

    repository = GitRepository(remote=repository_location, branch=branch, private_key_file=private_key_file,
                               committer_name_and_email=(committer_name, committer_email))

    synchronisations: List[Synchronisable] = []

    synchronisations.extend([
        TemplateSynchronisation(
            source=configuration[TEMPLATE_SOURCE_PROPERTY],
            destination=configuration[TEMPLATE_DESTINATION_PROPERTY],
            overwrite=configuration[TEMPLATE_OVERWRITE_PROPERTY]
            if TEMPLATE_OVERWRITE_PROPERTY in configuration else False,
            variables=configuration[TEMPLATE_VARIABLES_PROPERTY]
        )
        for configuration in arguments[TEMPLATES_PROPERTY]
    ])

    synchronisations.extend([
        FileSynchronisation(
            source=configuration[FILE_SOURCE_PROPERTY],
            destination=configuration[FILE_DESTINATION_PROPERTY],
            overwrite=configuration[FILE_OVERWRITE_PROPERTY] if FILE_OVERWRITE_PROPERTY in configuration else False
        )
        for configuration in arguments[FILES_PROPERTY]
    ])

    synchronisations.extend([
        SubrepoSynchronisation(
            checkout=GitCheckout(
                url=configuration[SUBREPO_URL_PROPERTY],
                branch=configuration[SUBREPO_BRANCH_PROPERTY],
                commit=configuration[SUBREPO_COMMIT_PROPERTY] if SUBREPO_COMMIT_PROPERTY in configuration else None,
                directory=configuration[SUBREPO_DIRECTORY_PROPERTY]
            ),
            overwrite=configuration[SUBREPO_OVERWRITE_PROPERTY]
            if SUBREPO_OVERWRITE_PROPERTY in configuration else False
        )
        for configuration in arguments[SUBREPOS_PROPERTY]
    ])

    return repository, synchronisations


def generate_output_information(
        synchronised_grouped_by_type: DefaultDict[Type["Synchronisable"], List["Synchronisable"]]) -> Dict[str, Any]:
    """
    Generates output information based on what synchronisations were applied.
    :param synchronised_grouped_by_type: the synchronisations applied, grouped by type
    :return: output in the form of JSON
    """
    return {
        CHANGED_FILES_RETURN_PROPERTY: [synchronisation.destination for synchronisation in
                                        synchronised_grouped_by_type[FileSynchronisation]],
        CHANGED_TEMPLATES_RETURN_PROPERTY: [synchronisation.destination for synchronisation in
                                            synchronised_grouped_by_type[TemplateSynchronisation]],
        CHANGED_SUBREPOS_RETURN_PROPERTY: [synchronisation.checkout.directory for synchronisation in
                                           synchronised_grouped_by_type[SubrepoSynchronisation]]
    }


def main():
    """
    Entrypoint.
    """
    module = AnsibleModule(
        argument_spec=_ARGUMENT_SPEC,
        supports_check_mode=True
    )
    fail_if_missing_dependencies(module)
    repository, synchronisations = parse_configuration(module.params)

    synchronised_grouped_by_type = synchronise(repository, synchronisations, dry_run=module.check_mode)
    # TODO: Consider catchable exceptions
    number_synchronised = len(sum(list(synchronised_grouped_by_type.values()), []))
    assert number_synchronised >= 0
    assert number_synchronised <= len(synchronisations)

    module.exit_json(changed=number_synchronised > 0, synchronised=generate_output_information(
        synchronised_grouped_by_type))


if __name__ == "__main__":
    main()
