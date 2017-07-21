import hashlib
import os
import shutil
import unittest
from abc import ABCMeta
from tempfile import mkdtemp, mkstemp
from typing import Optional, Tuple
from zipfile import ZipFile

from checksumdir import dirhash
from git import Repo
from pip._vendor import requests

from gitcommonsync.repository import GitRepository
from gitcommonsync.tests.resources.information import EXTERNAL_REPOSITORY_ARCHIVE, EXTERNAL_REPOSITORY_NAME, BRANCH


CONTENTS = "test contents"
TEMPLATE_VARIABLES = {
    "foo": "123",
    "bar": "abc"
}
TEMPLATE = {parameter: "{{ %s }}" % parameter for parameter in TEMPLATE_VARIABLES.keys()}
GITHUB_TEST_REPOSITORY = "https://github.com/colin-nolan/test-repository.git"
BRANCH_NAME_1 = "new-branch-1"
NEW_FILE_1 = "new-file.txt"
NEW_DIRECTORY_1 = "new-directory"


def get_md5(location: str, ignore_hidden_files: bool=True) -> Optional[str]:
    """
    Gets an MD5 checksum of the file or directory at the given location.
    :param location: location of file or directory
    :param ignore_hidden_files: whether hidden files should be ignored when calculating an checksum for a directory
    :return: the MD5 checksum or `None` if the given location does not exist
    """
    if not os.path.exists(location):
        return None
    if os.path.isfile(location):
        with open(location, "rb") as file:
            content = file.read()
        return hashlib.md5(content).hexdigest()
    else:
        return dirhash(location, "md5", ignore_hidden=ignore_hidden_files)


def is_accessible(url: str) -> bool:
    """
    Checks if the given URL is accessible.

    This function attempts to get the content at the location - avoid pointing to the location of a huge file!
    :param url: the URL to check
    :return: whether the given URL is accessible
    """
    try:
        return requests.get(url).status_code == requests.codes.ok
    except Exception:
        return False


class TestWithGitRepository(unittest.TestCase, metaclass=ABCMeta):
    """
    Base class for tests involving a Git repository.
    """
    def setUp(self):
        self.temp_directory = mkdtemp()

        with ZipFile(EXTERNAL_REPOSITORY_ARCHIVE) as archive:
            archive.extractall(path=self.temp_directory)
        self.external_git_repository_location = os.path.join(self.temp_directory, EXTERNAL_REPOSITORY_NAME)
        self.external_git_repository = Repo(self.external_git_repository_location)

        self.git_repository = GitRepository(self.external_git_repository_location, BRANCH)
        self.git_directory = self.git_repository.checkout(parent_directory=self.temp_directory)
        self.external_git_repository_md5 = get_md5(self.git_directory)

    def tearDown(self):
        if os.path.exists(self.temp_directory):
            shutil.rmtree(self.temp_directory)

    def create_test_file(self, contents=CONTENTS, directory: str=None) -> Tuple[str, str]:
        directory = directory if directory is not None else self.temp_directory
        _, location = mkstemp(dir=directory)
        with open(location, "w") as file:
            file.write(contents)
        return location, get_md5(location)

    def create_test_directory(self, contains_n_files: int=3) -> Tuple[str, str]:
        location = mkdtemp(dir=self.temp_directory)
        for _ in range(contains_n_files):
            self.create_test_file(directory=location)
        return location, get_md5(location)
