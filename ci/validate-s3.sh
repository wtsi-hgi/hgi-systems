#!/usr/bin/env bash

set -euf -o pipefail

if [ -z "${S3_IMAGE_BUCKET+x}" ]; then
    >&2 echo "S3_IMAGE_BUCKET must be set!"
    exit 1
fi

s3cmd info "s3://${S3_IMAGE_BUCKET}"
