import logging
import os
import shutil
from abc import ABCMeta, abstractmethod
from typing import List, Dict, Callable, TypeVar, Generic, Tuple

import gitsubrepo

from gitcommonsync._ansible_runner import ANSIBLE_RSYNC_MODULE_NAME, ANSIBLE_TEMPLATE_MODULE_NAME, \
    run_ansible
from gitcommonsync._common import is_subdirectory, get_head_commit
from gitcommonsync.repository import GitRepository, GitCheckout
from gitcommonsync.models import FileSynchronisation, SubrepoSynchronisation, TemplateSynchronisation, Synchronisation

_logger = logging.getLogger(__name__)

Synchronisable = TypeVar("Synchronisable", bound=Synchronisation)
FileBasedSynchronisable = TypeVar("FileBasedSynchronisable", bound=FileSynchronisation)


class Synchroniser(Generic[Synchronisable], metaclass=ABCMeta):
    """
    Synchroniser.
    """
    @abstractmethod
    def _synchronise(self, synchronisable: Synchronisable) -> Tuple[bool, str]:
        """
        Synchronise the repository using the given synchronisation configuration.
        :param synchronisable: see `Synchroniser.synchronise`
        :return: see `Synchroniser.synchronise`
        """

    def __init__(self, repository: GitRepository):
        """
        Constructor.
        :param repository: the git repository to synchronise
        """
        self.repository = repository

    def synchronise(self, synchronisables: List[Synchronisable], dry_run: bool=False) -> List[Synchronisable]:
        """
        Synchronise the repository with the given synchronisation.
        :param synchronisables: the synchronisations to apply
        :param dry_run: will not push changes to the repote if `True`
        :return: a list of the synchronisations that have been applied
        """
        synchronised: List[Synchronisable] = []
        for synchronisable in synchronisables:
            self._prepare_for_synchronise(synchronisable)
            was_synchronised, reason = self._synchronise(synchronisable)
            # TODO: Do something useful with the reasons
            if was_synchronised:
                synchronised.append(synchronisable)

        if len(synchronised) > 0 and not dry_run:
            self.repository.push()

        return synchronised

    def _prepare_for_synchronise(self, synchronisable: Synchronisable):
        """
        Perpares to apply the given synchronisation.
        :param synchronisable: the synchronisation that is to be applied
        """
        destination = os.path.join(self.repository.checkout_location, synchronisable.destination)
        target = os.path.join(self.repository.checkout_location, destination)

        if not is_subdirectory(destination, self.repository.checkout_location):
            raise ValueError(f"Destination {synchronisable.destination} not inside of repository "
                             f"({os.path.realpath(target)})")

        intermediate_directories = os.path.dirname(target)
        if not os.path.exists(intermediate_directories):
            _logger.info(f"Creating intermediate directories: {intermediate_directories}")
            os.makedirs(intermediate_directories)


class SubrepoSynchroniser(Synchroniser[SubrepoSynchronisation]):
    """
    Subrepo synchroniser.
    """
    def _synchronise(self, synchronisable: SubrepoSynchronisation) -> Tuple[bool, str]:
        destination = os.path.join(self.repository.checkout_location, synchronisable.destination)
        required_checkout = synchronisable.checkout
        force_update = False

        if os.path.exists(destination):
            url, branch, commit = gitsubrepo.status(destination)
            current_checkout = GitCheckout(url, branch, required_checkout.directory, commit=commit)
            same_url_and_branch = current_checkout.url == required_checkout.url \
                                  and current_checkout.branch == required_checkout.branch

            if required_checkout.commit is None and same_url_and_branch:
                required_checkout.commit = get_head_commit(url, branch)

            if current_checkout == required_checkout:
                return False, f"Subrepo at {required_checkout.directory} is synchronised"
            elif not synchronisable.overwrite:
                return False, f"Subrepo at {required_checkout.directory} is not synchronised but not updating as " \
                              f"overwrite=False"
            elif same_url_and_branch:
                _logger.debug(f"Pulling subrepo at {required_checkout.directory} in an attempt to sync")
                # TODO: We could check whether the remote's head is the commit we want before doing this as it might not
                # pull to the correct commit
                new_commit = gitsubrepo.pull(destination)
                if new_commit == required_checkout.commit:
                    return True, f"Subrepo at {required_checkout.directory}: {commit} => {new_commit}"
                else:
                    force_update = True
            else:
                force_update = True

            if force_update:
                message = f"Removing subrepo at {required_checkout.directory} to force update"
                _logger.debug(message)
                shutil.rmtree(destination)
                self.repository.commit(message, [destination])

        assert not os.path.exists(destination)
        new_commit = gitsubrepo.clone(required_checkout.url, destination,
                                      branch=required_checkout.branch, commit=required_checkout.commit)
        assert new_commit != required_checkout.commit
        return True, f"Checked out subrepo: {required_checkout} (forced updated={force_update})"


class FileBasedSynchroniser(Generic[FileBasedSynchronisable], Synchroniser[FileBasedSynchronisable], metaclass=ABCMeta):
    """
    Base class for any synchronisater that deals with individual files.
    """
    @abstractmethod
    def _synchronise_file(self, synchronisation: FileSynchronisation) -> Tuple[bool, str]:
        """
        Synchronises a file as defined by the given synchronisation configuration.
        :param synchronisation: the synchronisation configuration
        :return: tuple whether the first element is a boolean that indicates if the file was synchronised and the second
        is a human readable string detailing the reason for the choice to synchronise or not
        """

    def __init__(self, repository: GitRepository, aggregate_commits: bool=True):
        super().__init__(repository)
        self.aggregate_commits = aggregate_commits

    def synchronise(self, synchronisables: List[Synchronisable], dry_run: bool=False) -> List[Synchronisable]:
        synchronised = super().synchronise(synchronisables, dry_run=dry_run)
        if self.aggregate_commits:
            self.repository.commit(f"Synchronised {len(synchronised)} file{'' if len(synchronised) == 1 else 's'} "
                                   f"with {type(self).__name__} synchroniser.")
            self.repository.push()
        return synchronised

    def _prepare_for_synchronise(self, synchronisable: FileSynchronisation):
        if not os.path.exists(synchronisable.source):
            raise FileNotFoundError(synchronisable.source)
        if not os.path.isabs(synchronisable.source):
            raise ValueError(f"Sources cannot be relative: {synchronisable.source}")
        return super()._prepare_for_synchronise(synchronisable)

    def _synchronise(self, synchronisable: FileSynchronisation) -> Tuple[bool, str]:
        destination = os.path.join(self.repository.checkout_location, synchronisable.destination)
        target = os.path.join(self.repository.checkout_location, destination)

        if os.path.exists(target) and not synchronisable.overwrite:
            return False, f"{synchronisable.source} != {target} (overwrite={synchronisable.overwrite})"

        was_synchronised, reason = self._synchronise_file(synchronisable)
        if was_synchronised and not self.aggregate_commits:
            self.repository.commit(f"Synchronised {synchronisable.source}.")

        return was_synchronised, reason


class _AnsibleFileBasedSynchroniser(Generic[Synchronisable], FileBasedSynchroniser[Synchronisable], metaclass=ABCMeta):
    """
    Individual file synchroniser, implemented using Ansible.
    """
    def __init__(
            self, repository: GitRepository,
            ansible_action_generator: Callable[[FileSynchronisation, str], Dict],
            ansible_variables_generator: Callable[[FileSynchronisation], Dict[str, str]]=lambda synchronisation: {}):
        """
        Constructor.
        :param repository: see `Synchroniser.__init__`
        :param ansible_action_generator: generator of the action which Ansible is to perform in the form of a dictionary
        that the Ansible library can use. The first argument given is the synchronisation configuration and the second
        is the synchronisation target location
        :param ansible_variables_generator: generator of variables to be passed to Ansible, where the argument given is
        the synchronisation configuration and the return is dictionary where keys are variable names and values of the
        variable values
        """
        super().__init__(repository)
        self.ansible_action_generator = ansible_action_generator
        self.ansible_variables_generator = ansible_variables_generator

    def _synchronise_file(self, synchronisation: FileSynchronisation) -> Tuple[bool, str]:
        destination = os.path.join(self.repository.checkout_location, synchronisation.destination)
        target = os.path.join(self.repository.checkout_location, destination)

        results = run_ansible(tasks=[dict(action=self.ansible_action_generator(synchronisation, target))],
                              variables=self.ansible_variables_generator(synchronisation))
        assert len(results) <= 1
        if results[0].is_failed():
            raise RuntimeError(results[0]._result)
        if results[0].is_changed():
            return True, f"{synchronisation.source} => {target} (overwrite={synchronisation.overwrite})"
        else:
            return False, f"{synchronisation.source} == {target}"


class FileSynchroniser(_AnsibleFileBasedSynchroniser[FileSynchronisation]):
    """
    File synchroniser.
    """
    _ANSIBLE_ACTION_GENERATOR = lambda synchronisation, target: dict(
        module=ANSIBLE_RSYNC_MODULE_NAME,
        args=dict(src=synchronisation.source, dest=target, recursive=True, delete=True, archive=False, perms=True,
                  links=True, checksum=True)
    )

    def __init__(self, repository: GitRepository):
        super().__init__(repository, FileSynchroniser._ANSIBLE_ACTION_GENERATOR)


class TemplateSynchroniser(_AnsibleFileBasedSynchroniser[TemplateSynchronisation]):
    """
    Template based file synchroniser.
    """
    _ANSIBLE_ACTION_GENERATOR = lambda synchronisation, target: dict(module=ANSIBLE_TEMPLATE_MODULE_NAME,
                                                                     args=dict(src=synchronisation.source, dest=target))
    _ANSIBLE_VARIABLES_GENERATOR = lambda synchronisation: synchronisation.variables

    def __init__(self, repository: GitRepository):
        super().__init__(repository, TemplateSynchroniser._ANSIBLE_ACTION_GENERATOR,
                         TemplateSynchroniser._ANSIBLE_VARIABLES_GENERATOR)
