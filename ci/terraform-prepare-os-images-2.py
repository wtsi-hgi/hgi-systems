#!/usr/bin/env python3
import sys

import argparse
import os
import subprocess
from concurrent.futures import ThreadPoolExecutor, Future
from typing import Dict, Set, NamedTuple, List

IMAGE_BUCKET_CLI_PARAMETER = "image_bucket"
TERRAFORM_PLAN_LOCATION_CLI_PARAMETER = "terraform_plan_location"

_PREPARE_OS_IMAGE_SCRIPT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "prepare-os-image.rb")
_CHARACTER_ENCODING = "utf-8"
_MAX_CONCURRENT_DOWNLOADS = 5

_TERRAFORM_PLAN_IMAGE_NAME_KEY = "image_name"
_TERRAFORM_PLAN_KEY_VALUE_SEPARATOR = ":"

_OpenStackId = str


class RunConfiguration(NamedTuple):
    """
    Run configuration.
    """
    terraform_plan_location: str
    image_bucket: str


def run(configuration: RunConfiguration):
    """
    Run the OS image preparation script.
    :param configuration: the run configuration
    """
    image_names = get_image_names_referenced_in_terraform_plan(configuration.terraform_plan_location)
    print("Referenced images: %s" % (image_names, ), file=sys.stderr, flush=True)

    named_futures = {}  # type: Dict[str, Future]
    with ThreadPoolExecutor(max_workers=_MAX_CONCURRENT_DOWNLOADS) as executor:
        for image_name in image_names:
            named_futures[image_name] = executor.submit(prepare_os_image, image_name, configuration.image_bucket)

    # Prints IDs nice and together at the end
    for name, future in named_futures.items():
        print("%s in OpenStack with ID: %s" % (name, future.result()), file=sys.stderr)


def prepare_os_image(image_name: str, image_bucket: str) -> _OpenStackId:
    """
    Prepares the OpenStack image by adding it from S3.
    :param image_name: the name of the image to prepare
    :param image_bucket: the bucket in S3 where images can be found
    :return: the OpenStack ID of the prepared image
    """
    completed_process = subprocess.run(
        [_PREPARE_OS_IMAGE_SCRIPT, image_name, image_bucket], stdout=subprocess.PIPE)
    if completed_process.returncode != 0:
        exit(completed_process.returncode)
    return completed_process.stdout.decode(_CHARACTER_ENCODING).strip()


def get_image_names_referenced_in_terraform_plan(terraform_plan_location: str) -> Set[str]:
    """
    Gets the names of the images referenced in the Terraform plan readable from the given location.
    :param terraform_plan_location: location of the Terraform plan
    :return: set of image names referenced in the plan
    """
    image_names: Set[str] = set()
    with open(terraform_plan_location, "r") as file:
        # Note: this parsing minimally fulfils the requirements - it will not produce optimal results. However, before
        # considering optimising this, be aware that the format of the file produced by Terraform is not stable
        for line in file.readlines():
            line = line.strip()
            if line.startswith(f"{_TERRAFORM_PLAN_IMAGE_NAME_KEY}{_TERRAFORM_PLAN_KEY_VALUE_SEPARATOR}"):
                value = "".join(line.split(_TERRAFORM_PLAN_KEY_VALUE_SEPARATOR)[1:]).split("=>")[-1].strip() \
                    .strip("\"").strip("(forces new resource)")
                image_names.add(value)
    return image_names


def _parse_cli_arguments(cli_args: List[str]) -> RunConfiguration:
    """
    Parses the given CLI arguments to get the run configuration.
    :param cli_args: the CLI arguments
    :return: the run configuration
    """
    parser = argparse.ArgumentParser(
        description="Downloads the images Terraform uses into Glance from S3 if they are not already there")
    parser.add_argument(TERRAFORM_PLAN_LOCATION_CLI_PARAMETER,
                        help="Location of the terraform plan that describes what images are to be prepared")
    parser.add_argument(IMAGE_BUCKET_CLI_PARAMETER,
                        help="Name of the S3 bucket in which OpenStack images are stored")

    args = vars(parser.parse_args(cli_args))
    return RunConfiguration(terraform_plan_location=args[TERRAFORM_PLAN_LOCATION_CLI_PARAMETER],
                            image_bucket=args[IMAGE_BUCKET_CLI_PARAMETER])


if __name__ == "__main__":
    configuration = _parse_cli_arguments(sys.argv[1:])
    run(configuration)
