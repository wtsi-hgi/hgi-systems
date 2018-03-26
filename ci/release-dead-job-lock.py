#!/usr/bin/env python3

import logging
import os
from logging import StreamHandler
from urllib.parse import urlparse

from consullock.managers import ConsulLockManager
from gitlab import Gitlab, sys

logger = logging.getLogger(__name__)
logger.addHandler(StreamHandler())

JOB_ID_LOCK_METADATA_KEY = os.environ["CI_PROJECT_ID"]+"_jobId"


def is_ci_job_running(job_id: int):
    project_id = os.environ["CI_PROJECT_ID"]
    _parsed_project_url = urlparse(os.environ["CI_PROJECT_URL"])
    ci_url = "%s://%s" % (_parsed_project_url.scheme, _parsed_project_url.netloc)
    gitlab_token = os.environ["GITLAB_TOKEN"]

    gitlab_client = Gitlab(ci_url, gitlab_token, api_version=4)
    gitlab_client.auth()

    project = gitlab_client.projects.get(project_id)

    job = project.jobs.get(job_id)
    return job.attributes["status"] == "running"


def main(lock_key: str):
    lock_manager = ConsulLockManager()
    lock = lock_manager.find(lock_key)
    logger.debug(f"Lock with key \"{lock_key}\": {lock}")

    if lock is not None and lock.metadata is not None and JOB_ID_LOCK_METADATA_KEY in lock.metadata:
        job_id = lock.metadata[JOB_ID_LOCK_METADATA_KEY]
        logger.info(f"Lock currently held by CI job with ID: {job_id}")

        job_running = is_ci_job_running(job_id)
        logger.info(f"CI job with ID {job_id} {'is' if job_running else 'is not'} running")
        if not job_running:
            logger.info(f"Releasing lock for {lock.key} held by non-running job {job_id}")
            released = lock_manager.release(lock.key)
            logger.info("Released lock!" if released is not None else "Did not manage to release lock (someone else "
                                                                      "probably else released it before me)")


if __name__ == "__main__":
    main(sys.argv[1])
