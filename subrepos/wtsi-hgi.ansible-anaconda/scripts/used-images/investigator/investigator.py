import json
import logging
import os
import subprocess
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, Future
from json import JSONDecodeError
from tempfile import TemporaryDirectory

import boto3
import re
from git import Repo
from tqdm import tqdm
from typing import Set, Callable, Iterable, List, Dict, Tuple

S3_SECRET_KEY_ENVIRONMENT_VARIABLE = "S3_SECRET_KEY"
S3_ACCESS_KEY_ENVIRONMENT_VARIABLE = "S3_ACCESS_KEY"
S3_HOST_ENVIRONMENT_VARIABLE = "S3_HOST"

COMMIT_HASH_PATTERN = re.compile("[0-9a-f]{8}$")

_GIT_SEARCH_SCRIPT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "./_git-search.sh")
_GIT_SEARCH_PROGRESS_KEY = "commit"
_GIT_SEARCH_TOTAL_KEY = "total"

_TEXT_ENCODING = "utf-8"
_SUCCESS_RETURN_CODE = 0

_REGEX_OR_SYMBOL = "|"

_ProgressCallback = Callable[[int, int], None]

logger = logging.getLogger(__name__)
logger.addHandler(logging.StreamHandler())



def _get_ceph_client():
    """
    Gets Boto3 client connected to S3 based on the secrets in the environmnent.
    :return: connected S3 client
    """
    secret_key = os.getenv(S3_SECRET_KEY_ENVIRONMENT_VARIABLE)
    access_key = os.getenv(S3_ACCESS_KEY_ENVIRONMENT_VARIABLE)
    host = os.getenv(S3_HOST_ENVIRONMENT_VARIABLE)
    session = boto3.session.Session()
    return session.client(
        service_name="s3",
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        endpoint_url=f"https://{host}",
    )


def _get_image_names(bucket: str, s3_client) -> Set[str]:
    """
    Gets the name of the images in the given bucket, including only those ending in a commit hash.
    :param bucket: the bucket holding images
    :param s3_client: the connected S3 client
    :return: names of the images
    """
    objects_response = s3_client.list_objects(Bucket=bucket)
    if objects_response["IsTruncated"]:
        raise RuntimeError("boto indicated that S3 truncated the returned results (pagination not yet supported)")
    keys = (item["Key"] for item in objects_response["Contents"])
    return {key for key in keys if COMMIT_HASH_PATTERN.search(key)}


def _search_in_repositories(targets: Iterable[str], repository_urls: Iterable[str]) -> Dict[str, List[str]]:
    """
    Searches for lines containing any of the given targets in the given repositories.
    :param targets: targets to search for
    :param repository_urls: URLs of repositories to search within
    :return: dictionary where the line with the found target is the key and the repositories
    """
    progress_bar = tqdm(total=0, dynamic_ncols=True, smoothing=True)
    previous_progress: Dict[str, int] = {}
    progress_bar_update_executor = ThreadPoolExecutor(max_workers=1)

    def update_progress_bar(identifier: str, progress: int, total: int):
        # Note: this method must not be called concurrently
        if identifier not in previous_progress.keys():
            progress_bar.total += total
            previous_progress[identifier] = 0
        increase = progress - previous_progress[identifier]
        progress_bar.update(increase)
        previous_progress[identifier] += increase

    def create_progress_callback(repository_url: str):
        def progress_callback(progress: int, total: int):
            progress_bar_update_executor.submit(update_progress_bar, repository_url, progress, total)
        return progress_callback

    with ThreadPoolExecutor() as executor:
        repository_mapped_futures: Dict[str, Future] = {}
        for repository_url in set(repository_urls):
            progress_callback = create_progress_callback(repository_url)
            future = executor.submit(_search_in_repository, targets, repository_url, progress_callback)
            repository_mapped_futures[repository_url] = future

    # Gather references from all repositories
    references: Dict[str, List[str]] = {}
    for repository_url, future in repository_mapped_futures.items():
        matches = future.result()
        references[repository_url] = matches

    # Be nice and let the progress bar get to the end before returning
    progress_bar_update_executor.shutdown(wait=True)

    return references


def _search_in_repository(targets: Iterable[str], repository_url: str, progress_callback: _ProgressCallback=None) \
        -> Set[str]:
    """
    Searches for lines containing any of the given targets in the given repository.
    :param targets: targets to search for
    :param repository_url: URL of the Git repository to search within
    :param progress_callback: callable called when the progress, given as the first argument, changes. The second
    argument specifies the total number of progress steps
    :return: lines in the given repository that have one or more of the given targets in it
    """
    with TemporaryDirectory() as directory:
        Repo.clone_from(repository_url, directory, n=True)
        logger.debug(f"Checked out {repository_url} to {directory}")

        search_pattern = _REGEX_OR_SYMBOL.join((re.escape(target) for target in targets))
        logger.debug(f"Search pattern: {search_pattern}")
        command = [_GIT_SEARCH_SCRIPT, directory, search_pattern]
        logger.debug(f"Command: {command}")
        process = subprocess.Popen(command, stderr=subprocess.PIPE, stdout=subprocess.PIPE, encoding=_TEXT_ENCODING)
        stderr = ""
        if progress_callback is not None:
            while process.poll() is None:
                stderr_line = process.stderr.readline()
                stderr += stderr_line
                try:
                    progress = json.loads(stderr_line)
                    progress_callback(progress[_GIT_SEARCH_PROGRESS_KEY], progress[_GIT_SEARCH_TOTAL_KEY])
                except JSONDecodeError:
                    pass

        stdout, _ = process.communicate()

        if process.returncode != _SUCCESS_RETURN_CODE:
            raise subprocess.CalledProcessError(process.returncode, command, output=stdout, stderr=stderr)

        return set(json.loads(stdout)) if len(stdout) > 0 else set()


def _find_references(targets: Iterable[str], origin_mapped_sources: Dict[str, Iterable[str]]) \
        -> Dict[str, Set[Tuple[str, str]]]:
    """
    Finds all references to the given targets in the given sources.
    :param targets: the targets to find references to
    :param origin_mapped_sources: map where the key is the source origin and the value is that of the origin's sources
    that may reference one or more given targets
    :return:
    """
    reference_map = defaultdict(set)
    find_pattern = re.compile(_REGEX_OR_SYMBOL.join((re.escape(target) for target in targets)))

    for origin, sources in origin_mapped_sources.items():
        for source in sources:
            matches = find_pattern.findall(source)
            for match in matches:
                reference_map[match].add((source, origin))

    return dict(reference_map)


def _get_commit_hashes_from_image_names(image_names: Iterable[str]) -> Iterable[str]:
    """
    Gets the hashes from the given image names in the form: `.*-[0-9a-f]{8}`.
    :param image_names: image names
    :return: hashes of the given image names
    """
    image_hashes: Set[str] = set()
    for image_name in image_names:
        found_hashes = COMMIT_HASH_PATTERN.findall(image_name)
        if len(found_hashes) > 0:
            image_hashes.add(found_hashes[-1])
    return image_hashes


def investigate(repository_urls: Iterable[str], image_bucket: str):
    """
    Investigate usage of the images in the given image bucket in the given repositories.
    :param repository_urls: URLs of repositories to search for image references in
    :param image_bucket: the S3 bucket containing images
    :return: JSON serialisable output detailing image usage
    """
    logger.info(f"Getting names of images held in S3 \"{image_bucket}\" bucket...")
    image_names = _get_image_names(image_bucket, _get_ceph_client())
    logger.debug(f"Image names: {image_names}")
    image_hashes = _get_commit_hashes_from_image_names(image_names)
    logger.debug(f"Image hashes: {image_hashes}")

    logger.info("Examining potential images references in repositories...")
    logger.debug(f"Repositories: {repository_urls}")
    repository_mapped_references = _search_in_repositories(image_hashes, repository_urls)

    image_name_references = _find_references(image_names, repository_mapped_references)
    image_hash_references = _find_references(image_hashes, repository_mapped_references)
    undetermined_hash_references = {key: value for key, value in image_hash_references.items()
                                    if key not in _get_commit_hashes_from_image_names(image_name_references.keys())}

    maybe_referenced: Set[str] = set()
    for hash_reference in undetermined_hash_references.keys():
        pattern = re.compile(hash_reference)
        for image_name in image_names:
            if pattern.search(image_name):
                maybe_referenced.add(image_name)

    return {
        "referenced": list(image_name_references.keys()),
        "maybe-referenced": list(maybe_referenced),
        "not-referenced": list(image_names - image_name_references.keys() - maybe_referenced),
        "undetermined-references": {key: list(value) for key, value in undetermined_hash_references.items()}
    }
