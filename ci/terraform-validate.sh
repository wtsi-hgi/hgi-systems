#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet AWS_ACCESS_KEY_ID AWS_SECRET_KEY_ID TERRAFORM_CONSUL_TOKEN REGION SETUP ENV

export CONSUL_HTTP_TOKEN="${TERRAFORM_CONSUL_TOKEN}"

terraform_bin=$(which terraform)
if [[ -z "${terraform_bin}" ]]; then
    >&2 echo "terraform not in path: ${PATH}"
    exit 1
fi

region_setup="${REGION}-${SETUP}"
if [[ -d "terraform/${region_setup}" ]]; then
    echo "Calling terraform validate in terraform/${region_setup}"
    (cd terraform/${region_setup} && terraform init && terraform validate)
else
    >&2 echo "Path terraform/${region_setup} not a directory"
    exit 1
fi

ci/terraform-fmt.sh "terraform/${region_setup}"
