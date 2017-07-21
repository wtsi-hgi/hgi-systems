import os
import shutil
from tempfile import mkdtemp
from typing import List, Callable, Tuple, Any

from git import Repo, GitCommandError, IndexFile, Actor

DEFAULT_BRANCH = "master"
SSH_COMMAND = "ssh"


def requires_checkout(func):
    """
    Enforces the given `GitRepository` method only executes if the repository has been checked out.
    :param func: function of `GitRepository`
    :return: decorated method that raises `NotADirectoryError` if called when the repository has not been checked out
    """
    def decorated(self: "GitRepository", *args, **kwargs) -> Callable:
        if self.checkout_location is None:
            raise NotADirectoryError("Repository must be checked out")
        return func(self, *args, **kwargs)
    return decorated


class GitCheckout:
    """
    Git checkout.
    """
    def __init__(self, url: str, branch: str, directory: str, *, commit: str=None):
        self.url = url
        self.branch = branch
        self.directory = directory
        self.commit = commit

    def __eq__(self, other: Any) -> bool:
        return isinstance(other, type(self)) \
               and other.url == self.url \
               and other.branch == self.branch \
               and other.commit == self.commit \
               and other.directory == self.directory


class GitRepository:
    """
    Wrapper to simplify basic operations on a specific branch of a repository mirrored from a remote.
    """
    _REQUIRED_USER_CONFIG_PARAMETERS = ["user.name", "user.email"]

    def __init__(self, remote: str, branch: str, *, checkout_location: str=None,
                 committer_name_and_email: Tuple[str, str]=None, private_key_file: str=None, create_branch: bool=True):
        """
        Constructor.
        :param remote: url of the remote which this repository tracks
        :param branch: the branch on the remote that is to be checked out
        :param checkout_location: optional location in which the repository has already being checked out. Becomes the
        responsibility of this object and hence is removed on tear down
        :param committer_name_and_email: the commit author to use, where the first element is the author's name and the
        second is the author's email address. If not defined, it will be attempted to get the author from the global
        configuration
        :param private_key_file: the private key to use when cloning the repository
        :param create_branch: whether the branch should be created if it does not exist
        """
        self.remote = remote
        self.branch = branch
        self.checkout_location = checkout_location
        self.committer_name = committer_name_and_email[0] if committer_name_and_email is not None else None
        self.committer_email = committer_name_and_email[1] if committer_name_and_email is not None else None
        self.private_key_file = private_key_file
        self.create_branch = create_branch

    def tear_down(self):
        """
        Tears down any repository files on the local machine.
        """
        if os.path.exists(self.checkout_location):
            shutil.rmtree(self.checkout_location)
            self.checkout_location = None

    def checkout(self, parent_directory: str=None) -> str:
        """
        Checks out the repository into the given parent directory or temporary directory if not given.
        :param parent_directory: optional parent directory in which the repository is checked out into (in a
        sub-directory)
        :return: the checkout directory
        """
        if self.checkout_location is not None:
            raise IsADirectoryError(f"Repository already checked out in {self.checkout_location}")

        self.checkout_location = mkdtemp(dir=parent_directory)
        repository = Repo.clone_from(url=self.remote, to_path=self.checkout_location,
                                     env={"GIT_SSH_COMMAND": self._get_ssh_command()})

        if self.branch not in repository.heads and self.create_branch:
            # It doesn't appear that `create_head` can be used to create branches without basing them off a commit (i.e.
            # if it is a new repository)
            repository.git.checkout(self.branch, b=True)
        else:
            repository.heads[self.branch].checkout()

        return self.checkout_location

    @requires_checkout
    def push(self):
        """
        Commits then pushes changes to the repository.
        """
        repository = Repo(self.checkout_location)
        repository.git.update_environment(GIT_SSH_COMMAND=self._get_ssh_command())
        repository.remotes.origin.push(refspec=f"{self.branch}:{self.branch}")

    @requires_checkout
    def commit(self, commit_message: str, changed_files: List[str]=None):
        """
        Commits changes to the repository.
        :param commit_message: the message to associate to the commit
        :param changed_files: the specific files to commit. If left as `None`, all files will be committed
        """
        if changed_files is None or len(changed_files) > 0:
            repository = Repo(self.checkout_location)

            index = repository.index
            if changed_files is not None:
                added = {changed_file for changed_file in changed_files if os.path.exists(changed_file)}
                removed = set(changed_files) - added
                if len(added) > 0:
                    index.add(added)
                if len(removed) > 0:
                    index.remove(removed, r=True)
            else:
                repository.git.add(A=True)

            if len(repository.refs) == 0 or len(repository.index.diff(repository.head.commit)) > 0:
                self._commit(index, commit_message)

    def _commit(self, index: IndexFile, commit_message: str):
        """
        Commits the changes to the given index with the given commit message.
        :param index: the repository index with changes to commit
        :param commit_message: the message to associate with the commit
        """
        if self.committer_name is not None and self.committer_email is not None:
            author = Actor(self.committer_name, self.committer_email)
        else:
            for config in GitRepository._REQUIRED_USER_CONFIG_PARAMETERS:
                try:
                    index.repo.git.config(config)
                except GitCommandError as e:
                    raise RuntimeError(f"`git config --global {config}` must be set") from e
            author = None
        index.commit(commit_message, author=author)

    def _get_ssh_command(self) -> str:
        """
        Gets the SSH command required to access the repository.
        :return: the SSH command
        """
        return f"{SSH_COMMAND} -i {self.private_key_file}" if self.private_key_file is not None else SSH_COMMAND
