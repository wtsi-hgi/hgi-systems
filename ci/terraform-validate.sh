#!/bin/bash

set -euf -o pipefail

if [[ -d "terraform/${REGION}" ]]; then
    echo "Calling terragrunt validate in terraform/${REGION}"
    cd terraform/${REGION} && terragrunt validate
else
    >&2 echo "Path terraform/${REGION} not a directory"
    exit 1
fi
