#!/usr/bin/env python3
import argparse
import os
import subprocess

_OS_IMAGE_KEY_PREFIX = "TF_VAR_"
_OS_IMAGE_KEY_SUFFIX = "_image_name"
_PREPARE_OS_IMAGE_SCRIPT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "prepare-os-image.rb")


class RunConfiguration:
    def __init__(self, image_bucket: str):
        self.image_bucket = image_bucket


def run(configuration: RunConfiguration):
    for key, value in os.environ.items():
        if key.startswith(_OS_IMAGE_KEY_PREFIX) and key.endswith(_OS_IMAGE_KEY_SUFFIX):
            completed_process = subprocess.run(
                [_PREPARE_OS_IMAGE_SCRIPT, value, configuration.image_bucket], stdout=subprocess.PIPE)
            if completed_process.returncode != 0:
                exit(completed_process.returncode)
            print("%s: %s" % (key, completed_process.stdout))


def parse_arguments() -> RunConfiguration:
    parser = argparse.ArgumentParser(description="Downloads the images Terraform uses into Glance from S3 if they are "
                                                 "not already there")
    parser.add_argument("image_bucket", help="Name of the S3 bucket in which OpenStack images are stored")
    args = parser.parse_args()
    return RunConfiguration(image_bucket=args.image_bucket)


if __name__ == "__main__":
    configuration = parse_arguments()
    run(configuration)
