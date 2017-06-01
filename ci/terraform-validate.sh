#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet AWS_ACCESS_KEY_ID AWS_SECRET_KEY_ID

terraform_bin=$(which terraform)
if [[ -z "${terraform_bin}" ]]; then
    >&2 echo "terraform not in path: ${PATH}"
    exit 1
fi

if [[ -d "terraform/${REGION}" ]]; then
    echo "Calling terraform validate in terraform/${REGION}"
    (cd terraform/${REGION} && terraform validate)
else
    >&2 echo "Path terraform/${REGION} not a directory"
    exit 1
fi

echo "Calling terraform fmt"
fmt_diff=$(cd terraform/${REGION} && terraform fmt -write=false -diff=true)
if [[ -n "${fmt_diff}" ]]; then
  >&2 echo 'ERROR: terraform fmt indicates formatting changes are required, suggest using a pre-commit hook to run `terraform fmt`'
  echo "${fmt_diff}"
  exit 1
fi
