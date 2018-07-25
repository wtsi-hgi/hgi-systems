#!/bin/bash

set -euf -o pipefail

PARALLELISM=20
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet CI_PROJECT_DIR REGION SETUP ENV ANSIBLE_VAULT_PASSWORD TERRAFORM_CONSUL_TOKEN

>&2 echo "Run information: REGION=${REGION} SETUP=${SETUP} ENV=${ENV}"

terraform_bin="${SCRIPT_DIRECTORY}/terraform.sh"

artifacts_dir="${CI_PROJECT_DIR}/artifacts"
mkdir -p "${artifacts_dir}"
echo "Listing contents of artifacts directory ${artifacts_dir}"
artifacts=$(ls "${artifacts_dir}/")

region_setup="${REGION}-${SETUP}"
echo "Changing to terraform/${region_setup} directory"
cd terraform/${region_setup}

echo "Calling terraform init"
${terraform_bin} init

echo "Switching to ${ENV} workspace"
set +e
${terraform_bin} workspace select ${ENV}
workspace_exit_status=$?
set -e
if [[ ${workspace_exit_status} -ne 0 ]]; then
    echo "Could not switch to ${ENV} workspace, attempting to create a new one"
    ${terraform_bin} workspace new ${ENV}
    workspace_new_exit_status=$?
    if [[ ${workspace_new_exit_status} -ne 0 ]]; then
	>&2 echo "Could not create new workspace ${ENV} - if error is Permission Denied, check if CONSUL_HTTP_TOKEN is set correctly"
	exit ${workspace_new_exit_status}
    fi
fi

echo "Calling terraform init again"
${terraform_bin} init

echo "Calling terraform get"
${terraform_bin} get

