import json
import logging
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, Future
from json import JSONDecodeError
from tempfile import TemporaryDirectory, TemporaryFile, NamedTemporaryFile

import boto3
import re
from git import Repo
from tqdm import tqdm
from typing import Set, Callable, Iterable, List, Dict

IMAGE_USE_SEARCH_SCRIPT = "./git-search.sh"
TEXT_ENCODING = "utf-8"
SUCCESS_RETURN_CODE = 0

S3_SECRET_KEY_ENVIRONMENT_VARIABLE = "S3_SECRET_KEY"
S3_ACCESS_KEY_ENVIRONMENT_VARIABLE = "S3_ACCESS_KEY"
S3_HOST_ENVIRONMENT_VARIABLE = "S3_HOST"

COMMIT_HASH_PATTERN = re.compile(".*[0-9a-f]{8}$")

ProgressCallback = Callable[[int, int], None]

logger = logging.getLogger(__name__)
logger.addHandler(logging.StreamHandler())


def get_references_in_repositories(image_hashes: Iterable[str], repository_urls: Iterable[str], max_workers: int=None):
    """
    TODO
    :param image_hashes:
    :param repository_urls:
    :param max_workers:
    :return:
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

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        reference_futures: List[Future] = []
        for repository_url in set(repository_urls):
            progress_callback = create_progress_callback(repository_url)
            future = executor.submit(get_references_in_repository, image_hashes, repository_url, progress_callback)
            reference_futures.append(future)

    # Gather references from all repositories
    references: Set[str] = set()
    for future in reference_futures:
        result = future.result()
        references.update(result)

    # Be nice and let the progress bar get to the end before returning
    progress_bar_update_executor.shutdown(wait=True)

    return references


def get_references_in_repository(references: Iterable[str], repository_url: str,
                                 progress_callback: ProgressCallback=None) -> Set[str]:
    """
    TODO
    :param repository_url:
    :param progress_callback:
    :return:
    """
    for reference in references:
        if "|" in reference:
            raise ValueError("References cannot contain pipe symbols")

    with TemporaryDirectory() as directory:
        Repo.clone_from(repository_url, directory, n=True)
        logger.debug(f"Checked out {repository_url} to {directory}")

        search_pattern = "|".join(references)
        logger.debug(f"Search pattern: {search_pattern}")
        process = subprocess.Popen([IMAGE_USE_SEARCH_SCRIPT, directory, search_pattern],
                                   stderr=subprocess.PIPE, stdout=subprocess.PIPE, encoding=TEXT_ENCODING)
        if progress_callback is not None:
            while process.poll() is None:
                raw_progress = process.stderr.readline().strip()
                try:
                    progress = json.loads(raw_progress)
                    # TODO: take out magic strings
                    progress_callback(progress["commit"], progress["total"])
                except JSONDecodeError as e:
                    pass

        stdout, _ = process.communicate()

        if process.returncode != SUCCESS_RETURN_CODE:
            # TODO: Proper exception
            raise Exception()

        return set(json.loads(stdout)) if len(stdout) > 0 else set()


def _get_ceph_client():
    """
    TODO
    :param secret_key:
    :param access_key:
    :param host:
    :return:
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


def get_image_names(bucket: str) -> Set[str]:
    """
    TODO
    :return:
    """
    s3_client = _get_ceph_client()
    objects_response = s3_client.list_objects(Bucket=bucket)
    if objects_response["IsTruncated"]:
        raise RuntimeError("boto indicated that S3 truncated the returned results (pagination not yet supported)")
    keys = (item["Key"] for item in objects_response["Contents"])
    return {key for key in keys if COMMIT_HASH_PATTERN.match(key)}


def main():
    """
    TODO
    :return:
    """
    logger.info("Getting names of images held in S3...")
    image_names = get_image_names("hgi-openstack-images")
    logger.debug(f"Image names: {image_names}")

    logger.info("Examining potential images references in repositories...")
    repositories = {
        "https://gitlab.internal.sanger.ac.uk/hgi/hgi-base-image-builder.git",
        "https://gitlab.internal.sanger.ac.uk/hgi/image-creation.git",
        "https://gitlab.internal.sanger.ac.uk/hgi/freebsd-cloud-init-image-builder.git",
        "https://gitlab.internal.sanger.ac.uk/hgi/hgi-systems.git"
    }
    logger.debug(f"Repositories: {repositories}")
    referenced_image_names = get_references_in_repositories(image_names, repositories)

    print(f"Referenced images: {image_names.intersection(referenced_image_names)}", file=sys.stderr)
    print(image_names - referenced_image_names)


if __name__ == "__main__":
    logger.setLevel(logging.DEBUG)
    main()
