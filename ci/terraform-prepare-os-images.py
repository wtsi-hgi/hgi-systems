#!/usr/bin/env python3
import argparse
import os
import subprocess
from concurrent.futures import ThreadPoolExecutor, Future
from typing import List, Dict

_OS_IMAGE_KEY_PREFIX = "TF_VAR_"
_OS_IMAGE_KEY_SUFFIX = "_image_name"
_PREPARE_OS_IMAGE_SCRIPT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "prepare-os-image.rb")
_CHARACTER_ENCODING = "utf-8"
_MAX_CONCURRENT_DOWNLOADS = 10

_OpenStackId = str


class RunConfiguration:
    def __init__(self, image_bucket: str):
        self.image_bucket = image_bucket


def run(configuration: RunConfiguration):
    named_futures: Dict[str, Future] = []
    with ThreadPoolExecutor(max_workers=_MAX_CONCURRENT_DOWNLOADS) as executor:
        for key, value in os.environ.items():
            if key.startswith(_OS_IMAGE_KEY_PREFIX) and key.endswith(_OS_IMAGE_KEY_SUFFIX):
                named_futures[key] = executor.submit(prepare_os_image, value, configuration.image_bucket)
    # Prints IDs nice and together at the end
    for name, future in named_futures.items():
        print("%s in OpenStack with ID: %s" % (name, future.result()))


def prepare_os_image(image_name: str, image_bucket: str) -> _OpenStackId:
    completed_process = subprocess.run(
        [_PREPARE_OS_IMAGE_SCRIPT, image_name, image_bucket], stdout=subprocess.PIPE)
    if completed_process.returncode != 0:
        exit(completed_process.returncode)
    return completed_process.stdout.decode(_CHARACTER_ENCODING).strip()


def parse_arguments() -> RunConfiguration:
    parser = argparse.ArgumentParser(description="Downloads the images Terraform uses into Glance from S3 if they are "
                                                 "not already there")
    parser.add_argument("image_bucket", help="Name of the S3 bucket in which OpenStack images are stored")
    args = parser.parse_args()
    return RunConfiguration(image_bucket=args.image_bucket)


if __name__ == "__main__":
    configuration = parse_arguments()
    run(configuration)
