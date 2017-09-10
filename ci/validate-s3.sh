#!/usr/bin/env bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet S3_IMAGE_BUCKET

>&2 echo "calling s3cmd info on ${S3_IMAGE_BUCKUP}"
s3cmd info "s3://${S3_IMAGE_BUCKET}"

>&2 echo "s3cmd info appears to have worked"
exit 0
