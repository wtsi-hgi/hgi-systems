#!/usr/bin/env bash

set -euf -o pipefail

if [ -z "${S3_ACCESS_KEY+x}" ]; then
    >&2 echo "S3_ACCESS_KEY must be set!"
    exit 1
fi
if [ -z "${S3_SECRET_KEY+x}" ]; then
    >&2 echo "S3_SECRET_KEY must be set!"
    exit 1
fi
if [ -z "${S3_HOST+x}" ]; then
    >&2 echo "S3_HOST must be set!"
    exit 1
fi
if [ -z "${S3_HOST_BUCKET+x}" ]; then
    >&2 echo "S3_HOST_BUCKET must be set!"
    exit 1
fi
if [ -z "${S3_IMAGE_BUCKET+x}" ]; then
    >&2 echo "S3_IMAGE_BUCKET must be set!"
    exit 1
fi

s3cmd info \
        --access_key="${S3_ACCESS_KEY}" \
        --secret_key="${S3_SECRET_KEY}" \
        --ssl \
        --host="${S3_HOST}" \
        --host-bucket="${S3_HOST_BUCKET}" \
    "s3://${S3_IMAGE_BUCKET}"
