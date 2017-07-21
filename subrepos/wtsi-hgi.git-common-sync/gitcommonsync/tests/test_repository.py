import unittest
from pathlib import Path

from git import Repo

from gitcommonsync.tests._common import TestWithGitRepository, BRANCH_NAME_1, NEW_FILE_1
from gitcommonsync.tests.resources.information import MASTER_BRANCH, DEVELOP_BRANCH, TAG_1_0


class TestAnsibleModule(TestWithGitRepository):
    """
    Tests runner of the Ansible tests.
    """
    def setUp(self):
        super().setUp()
        self.git_repository.tear_down()
        self.git_repository.branch = BRANCH_NAME_1

    def test_checkout_new_branch_from_existing(self):
        self._assert_usable_checkout(self.git_repository.checkout(), BRANCH_NAME_1)

    def test_checkout_new_branch_when_no_existing(self):
        repository = Repo(self.external_git_repository_location)
        repository.git.config(["receive.denyDeleteCurrent", False])
        for head in [MASTER_BRANCH, DEVELOP_BRANCH, TAG_1_0]:
            repository.git.push([f"{self.external_git_repository_location}", f":{head}"])
        assert len(repository.refs) == 0
        self._assert_usable_checkout(self.git_repository.checkout(), BRANCH_NAME_1)

    def _assert_usable_checkout(self, location: str, branch: str):
        repository = Repo(location)
        self.assertEqual(branch, repository.active_branch.name)
        Path(f"{location}/{NEW_FILE_1}").touch()
        self.git_repository.commit("testing")
        self.git_repository.push()
        self.assertIn(BRANCH_NAME_1, {ref.name.split("/")[1] for ref in repository.remotes.origin.refs})


if __name__ == "__main__":
    unittest.main()
