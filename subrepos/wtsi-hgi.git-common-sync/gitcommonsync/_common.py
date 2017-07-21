import os
from tempfile import TemporaryDirectory

from git import Repo


def is_subdirectory(subdirectory: str, directory: str) -> bool:
    """
    Whether the first given directory is a subdirectory of the second given directory.
    :param subdirectory: the directory that may be a subdirectory of the other
    :param directory: the directory that may contain the subdirectory
    :return: whether the subdirectory is a subdirectory of the directory
    """
    return ".." not in os.path.relpath(subdirectory, directory)


def get_head_commit(location: str, branch: str) -> str:
    """
    Gets the ID of the head commit for the given branch in the Git repository accessible at the given location.
    :param location: the location of the repository
    :param branch: the branch of interest
    :return: the (short) ID of the head commit
    """
    with TemporaryDirectory() as temp_directory:
        subrepo_remote = Repo.init(temp_directory)
        origin = subrepo_remote.create_remote("origin", location)
        fetch_infos = origin.fetch()
        for fetch_info in fetch_infos:
            if fetch_info.name == f"origin/{branch}":
                return fetch_info.commit.hexsha[0:7]