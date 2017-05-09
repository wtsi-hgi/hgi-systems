#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet AWS_ACCESS_KEY_ID AWS_SECRET_KEY_ID

if [[ -d "terraform/${REGION}" ]]; then
    echo "Calling terraform validate in terraform/${REGION}"
    cd terraform/${REGION} && terraform validate
else
    >&2 echo "Path terraform/${REGION} not a directory"
    exit 1
fi
