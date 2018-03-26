#!/usr/bin/env python3
import json

from investigator.investigator import investigate


def main():
    """
    Main method.
    """
    repositories = {
        "https://gitlab.internal.sanger.ac.uk/hgi/hgi-base-image-builder.git",
        "https://gitlab.internal.sanger.ac.uk/hgi/image-creation.git",
        "https://gitlab.internal.sanger.ac.uk/hgi/freebsd-cloud-init-image-builder.git",
        "https://gitlab.internal.sanger.ac.uk/hgi/hgi-systems.git"
    }
    image_bucket = "hgi-openstack-images"

    output = investigate(repositories, image_bucket)
    print(json.dumps(output))


if __name__ == "__main__":
    main()
