#!/usr/bin/env python3

import os
import subprocess

_S3_IMAGE_BUCKET_KEY = "S3_IMAGE_BUCKET"
_OS_IMAGE_KEY_PREFIX = "TF_VAR_"
_OS_IMAGE_KEY_SUFFIX = "_image_name"
_PREPARE_OS_IMAGE_SCRIPT = os.path.join(os.path.dirname(os.path.realpath(__file__)), "prepare-os-image.rb")


def main():
    """
    Main method.
    """
    for key, value in os.environ.items():
        if key.startswith(_OS_IMAGE_KEY_PREFIX) and key.endswith(_OS_IMAGE_KEY_SUFFIX):
            print([_PREPARE_OS_IMAGE_SCRIPT, value, os.environ[_S3_IMAGE_BUCKET_KEY]])
            completed_process = subprocess.run([_PREPARE_OS_IMAGE_SCRIPT, value, os.environ[_S3_IMAGE_BUCKET_KEY]])
            if completed_process.returncode != 0:
                exit(completed_process.returncode)


if __name__ == "__main__":
    main()
