#!/bin/bash

set -euf -o pipefail

if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
    >&2 echo "AWS_ACCESS_KEY_ID not set, giving up on terraform"
    exit 1
fi

if [[ -z "${AWS_SECRET_KEY_ID:-}" ]]; then
    >&2 echo "AWS_SECRET_KEY_ID not set, giving up on terraform"
    exit 1
fi

terraform_bin=$(which terraform)
if [[ -z "${terraform_bin}" ]]; then
    >&2 echo "terraform not in path: ${PATH}"
    exit 1
fi

if [[ -d "terraform/${REGION}" ]]; then
    echo "Calling terraform validate in terraform/${REGION}"
    cd terraform/${REGION} && terraform validate
else
    >&2 echo "Path terraform/${REGION} not a directory"
    exit 1
fi
