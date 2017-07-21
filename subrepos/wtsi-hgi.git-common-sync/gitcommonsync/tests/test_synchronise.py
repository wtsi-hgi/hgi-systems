import json
import os
import shutil
import stat
import unittest
from abc import abstractmethod, ABCMeta
from pathlib import Path
from typing import Generic, TypeVar, Dict

import gitsubrepo
from git import Repo
from gitsubrepo.exceptions import NotAGitSubrepoException

from gitcommonsync._ansible_runner import ANSIBLE_TEMPLATE_MODULE_NAME, run_ansible
from gitcommonsync.models import FileSynchronisation, SubrepoSynchronisation, TemplateSynchronisation
from gitcommonsync.repository import GitRepository, GitCheckout
from gitcommonsync.synchronisers import Synchroniser, SubrepoSynchroniser, FileSynchroniser, TemplateSynchroniser
from gitcommonsync.tests._common import get_md5, is_accessible, TestWithGitRepository, NEW_FILE_1, NEW_DIRECTORY_1, \
    TEMPLATE_VARIABLES, TEMPLATE, GITHUB_TEST_REPOSITORY
from gitcommonsync.tests.resources.information import FILE_1, \
    MASTER_BRANCH, MASTER_HEAD_COMMIT, MASTER_OLD_COMMIT, DEVELOP_BRANCH, DIRECTORY_1

SynchroniserType = TypeVar("SynchroniserType", bound=Synchroniser)


class _TestSynchroniser(Generic[SynchroniserType], TestWithGitRepository, metaclass=ABCMeta):
    """
    Base class for tests for `Synchroniser`.
    """
    @abstractmethod
    def create_synchroniser(self) -> SynchroniserType:
        """
        Creates a synchroniser to test with.
        :return: the synchroniser
        """

    def setUp(self):
        super().setUp()
        self.synchroniser = self.create_synchroniser()


class TestSubrepoSynchroniser(_TestSynchroniser[SubrepoSynchroniser]):
    """
    Tests for `SubrepoSynchroniser`.
    """
    def create_synchroniser(self) -> SubrepoSynchroniser:
        return SubrepoSynchroniser(self.git_repository)

    def setUp(self):
        super().setUp()
        self.git_checkout = GitCheckout(self.external_git_repository_location, MASTER_BRANCH, NEW_DIRECTORY_1)
        self.git_subrepo_directory = os.path.join(self.git_directory, self.git_checkout.directory)

    def test_sync_onto_existing_non_subrepo_directory(self):
        synchronisations = [SubrepoSynchronisation(self.git_checkout)]
        os.makedirs(self.git_subrepo_directory)
        self.assertRaises(NotAGitSubrepoException, self.synchroniser.synchronise, synchronisations)

    def test_sync_to_directory_outside_repository(self):
        self.git_checkout.directory = self.external_git_repository_location
        synchronisations = [SubrepoSynchronisation(self.git_checkout)]
        self.assertRaises(ValueError, self.synchroniser.synchronise, synchronisations)

    def test_sync_new_subrepo(self):
        self.git_checkout.commit = MASTER_HEAD_COMMIT
        synchronisations = [SubrepoSynchronisation(self.git_checkout)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual(synchronisations, synchronised)
        self.assertEqual(self.external_git_repository_md5, get_md5(self.git_subrepo_directory))
        self.assertEqual(self.git_checkout.commit[0:7], gitsubrepo.status(self.git_subrepo_directory)[2])

    def test_sync_up_to_date_subrepo(self):
        gitsubrepo.clone(self.git_checkout.url, self.git_subrepo_directory, branch=self.git_checkout.branch)
        synchronisations = [SubrepoSynchronisation(self.git_checkout, overwrite=True)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual([], synchronised)

    @unittest.skipIf(not is_accessible(GITHUB_TEST_REPOSITORY), "Could not connect to GitHub")
    def test_sync_new_subrepo_from_github(self):
        self.git_checkout.url = GITHUB_TEST_REPOSITORY
        gitsubrepo.clone(self.git_checkout.url, self.git_subrepo_directory, branch=self.git_checkout.branch)
        synchronisations = [SubrepoSynchronisation(self.git_checkout)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual([], synchronised)

    def test_sync_out_of_date_subrepo_no_override(self):
        gitsubrepo.clone(self.git_checkout.url, self.git_subrepo_directory, branch=self.git_checkout.branch,
                         commit=MASTER_OLD_COMMIT)
        synchronisations = [SubrepoSynchronisation(self.git_checkout, overwrite=False)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual([], synchronised)
        self.assertEqual(MASTER_OLD_COMMIT[0:7], gitsubrepo.status(self.git_subrepo_directory)[2])

    def test_sync_out_of_date_subrepo_with_override(self):
        gitsubrepo.clone(self.git_checkout.url, self.git_subrepo_directory, branch=MASTER_BRANCH)
        self.git_repository.push()

        updated_repository = GitRepository(self.external_git_repository_location, MASTER_BRANCH)
        updated_repository_location = updated_repository.checkout(parent_directory=self.create_test_directory()[0])
        Path(os.path.join(updated_repository_location, NEW_FILE_1)).touch()
        updated_repository.commit("Updated", [os.path.join(updated_repository_location, NEW_FILE_1)])
        updated_repository.push()
        Repo(self.git_repository.checkout_location).remotes.origin.pull()

        synchronisations = [SubrepoSynchronisation(self.git_checkout, overwrite=True)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual(synchronisations, synchronised)
        self.assertTrue(os.path.exists(os.path.join(self.git_subrepo_directory, NEW_FILE_1)))

    def test_sync_out_of_date_subrepo_to_intermediate_commit(self):
        self.git_checkout.commit = MASTER_HEAD_COMMIT
        gitsubrepo.clone(self.git_checkout.url, self.git_subrepo_directory, branch=MASTER_BRANCH)
        # Push the clone commit
        self.git_repository.push()
        synchronisations = [SubrepoSynchronisation(self.git_checkout, overwrite=True)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual(synchronisations, synchronised)
        self.assertEqual(self.git_checkout.commit[0:7], gitsubrepo.status(self.git_subrepo_directory)[2])

    def test_sync_subrepo_to_different_branch(self):
        gitsubrepo.clone(self.git_checkout.url, self.git_subrepo_directory, branch=DEVELOP_BRANCH)
        synchronisations = [SubrepoSynchronisation(self.git_checkout, overwrite=True)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual(synchronisations, synchronised)
        url, branch, commit = gitsubrepo.status(self.git_subrepo_directory)
        self.assertEqual(MASTER_HEAD_COMMIT[0:7], commit)
        self.assertEqual(MASTER_BRANCH, branch)


class _TestFileBasedSynchroniser(Generic[SynchroniserType], _TestSynchroniser[SynchroniserType], metaclass=ABCMeta):
    """
    Tests for `FileBasedSynchroniser`.
    """
    def test_sync_non_existent_file(self):
        source = os.path.join(self.temp_directory, "does-not-exist")
        destination = os.path.join(self.git_directory, FILE_1)
        synchronisations = [FileSynchronisation(source, destination)]
        self.assertRaises(FileNotFoundError, self.synchroniser.synchronise, synchronisations)

    def test_sync_to_outside_repository(self):
        source, _ = self.create_test_file()
        destination = os.path.join(self.git_directory, "..", FILE_1)
        synchronisations = [FileSynchronisation(source, destination)]
        self.assertRaises(ValueError, self.synchroniser.synchronise, synchronisations)


class TestFileSynchroniser(_TestFileBasedSynchroniser[FileSynchroniser]):
    """
    Tests for `FileSynchroniser`.
    """
    def create_synchroniser(self) -> FileSynchroniser:
        return FileSynchroniser(self.git_repository)

    def test_sync_up_to_date_file(self):
        destination = os.path.join(self.git_directory, FILE_1)
        source, _ = self.create_test_file()
        shutil.copy(destination, source)
        synchronisations = [FileSynchronisation(source, destination, overwrite=True)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual(0, len(synchronised))

    def test_sync_up_to_date_directory(self):
        source = os.path.join(self.temp_directory, DIRECTORY_1) + os.path.sep
        destination = os.path.join(self.git_directory, DIRECTORY_1)
        shutil.copytree(destination, source)
        synchronisations = [FileSynchronisation(source, destination, overwrite=True)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual(0, len(synchronised))

    def test_sync_new_file(self):
        source, source_md5 = self.create_test_file()
        destination = os.path.join(self.git_directory, NEW_FILE_1)
        self._synchronise_and_assert(FileSynchronisation(source, destination, overwrite=False))

    def test_sync_new_directory(self):
        source, source_md5 = self.create_test_directory()
        destination = os.path.join(self.git_directory, NEW_DIRECTORY_1)
        self._synchronise_and_assert(FileSynchronisation(source, destination, overwrite=False))

    def test_sync_with_new_intermediate_directories(self):
        source, source_md5 = self.create_test_file()
        destination = os.path.join(self.git_directory, NEW_DIRECTORY_1, NEW_FILE_1)
        self._synchronise_and_assert(FileSynchronisation(source, destination, overwrite=False))

    def test_sync_out_of_date_file_when_no_overwrite(self):
        source, source_md5 = self.create_test_file()
        destination = os.path.join(self.git_directory, FILE_1)
        assert source_md5 != get_md5(destination)
        self._synchronise_and_assert(FileSynchronisation(source, destination, overwrite=False), expect_sync=False)

    def test_sync_out_of_date_directory_when_no_overwrite(self):
        source, source_md5 = self.create_test_directory()
        destination = os.path.join(self.git_directory, DIRECTORY_1)
        assert source_md5 != get_md5(destination)
        self._synchronise_and_assert(FileSynchronisation(source, destination, overwrite=False), expect_sync=False)

    def test_sync_out_of_date_file_when_overwrite(self):
        source, source_md5 = self.create_test_file()
        destination = os.path.join(self.git_directory, FILE_1)
        assert source_md5 != get_md5(destination)
        self._synchronise_and_assert(FileSynchronisation(source, destination, overwrite=True))

    def test_sync_out_of_date_directory_when_overwrite(self):
        source, source_md5 = self.create_test_directory()
        # We want to copy contents of directory, not the directory itself so adding / suffix
        source += os.path.sep
        destination = os.path.join(self.git_directory, DIRECTORY_1)
        assert source_md5 != get_md5(destination)
        self._synchronise_and_assert(FileSynchronisation(source, destination, overwrite=True))

    def test_sync_permissions_change(self):
        destination = os.path.join(self.git_directory, FILE_1)
        source, _ = self.create_test_file()
        shutil.copy(destination, source)
        permissions = 770
        os.chmod(source, permissions)
        assert stat.S_IMODE(os.lstat(source).st_mode) == 770
        self._synchronise_and_assert(FileSynchronisation(source, destination, overwrite=True))
        self.assertEqual(770, stat.S_IMODE(os.lstat(destination).st_mode))

    def _synchronise_and_assert(self, synchronisation: FileSynchronisation, expect_sync: bool=True):
        """
        Performs the given synchronisation and performs basic assertions on the result.
        :param synchronisation: the synchronisation to perform
        :param expect_sync: whether to expect the synchronisation to have been performed
        """
        source_md5 = get_md5(synchronisation.source)
        destination_original_md5 = get_md5(synchronisation.destination)
        synchronised = self.synchroniser.synchronise([synchronisation])

        if expect_sync:
            self.assertEqual([synchronisation], synchronised)
            self.assertEqual(get_md5(synchronisation.source), get_md5(synchronisation.destination))
        else:
            self.assertEqual(0, len(synchronised))
            self.assertEqual(destination_original_md5, get_md5(synchronisation.destination))
        self.assertEqual(source_md5, get_md5(synchronisation.source))

        repository = Repo(self.git_directory)
        self.assertFalse(Repo(self.git_directory).is_dirty(), msg=repository.git.diff())


class TestTemplateSynchroniser(_TestFileBasedSynchroniser[TemplateSynchroniser]):
    """
    Tests for `TemplateSynchroniser`.
    """
    def create_synchroniser(self) -> TemplateSynchroniser:
        return TemplateSynchroniser(self.git_repository)

    def setUp(self):
        super().setUp()
        self.template_source, _ = self.create_test_file(contents=json.dumps(TEMPLATE))
        self.template_destination = os.path.join(self.git_directory, NEW_FILE_1)

    def test_sync_template_with_incomplete_variables(self):
        synchronisations = [TemplateSynchronisation(self.template_source, self.template_destination, variables={})]
        self.assertRaises(RuntimeError, self.synchroniser.synchronise, synchronisations)

    def test_sync_new_template(self):
        synchronisations = [TemplateSynchronisation(
            self.template_source, self.template_destination, variables=TEMPLATE_VARIABLES)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual(synchronisations, synchronised)
        self.assertTrue(os.path.exists(self.template_destination))
        with open(self.template_destination, "r") as file:
            self.assertEqual(TEMPLATE_VARIABLES, json.load(file))

    def test_sync_up_to_date_template(self):
        self._write_template()
        synchronisations = [TemplateSynchronisation(
            self.template_source, self.template_destination, variables=TEMPLATE_VARIABLES, overwrite=True)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual([], synchronised)

    def test_sync_out_of_date_date_template_without_overwrite(self):
        self._write_template()
        altered_variables = {key: f"{value}-2" for key, value in TEMPLATE_VARIABLES.items()}
        synchronisations = [TemplateSynchronisation(
            self.template_source, self.template_destination, variables=altered_variables, overwrite=False)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual([], synchronised)

    def test_sync_out_of_date_date_template_with_overwrite(self):
        self._write_template()
        altered_variables = {key: f"{value}-2" for key, value in TEMPLATE_VARIABLES.items()}
        synchronisations = [TemplateSynchronisation(
            self.template_source, self.template_destination, variables=altered_variables, overwrite=True)]
        synchronised = self.synchroniser.synchronise(synchronisations)
        self.assertEqual(synchronisations, synchronised)
        with open(self.template_destination, "r") as file:
            self.assertEqual(altered_variables, json.load(file))

    def _write_template(self, template_variables: Dict[str, str]=TEMPLATE_VARIABLES):
        """
        Writes the given template variables to template being used in this test setup.
        :param template_variables: variables to populate the template with
        """
        run_ansible(
            tasks=[dict(action=dict(module=ANSIBLE_TEMPLATE_MODULE_NAME,
                                    args=dict(src=self.template_source, dest=self.template_destination)))],
            variables=template_variables
        )


del _TestSynchroniser, TestWithGitRepository, _TestFileBasedSynchroniser
