#!/bin/bash

set -euf -o pipefail

artifacts_dir="${CI_PROJECT_DIR}/artifacts/"
echo "Creating artifacts directory ${artifacts_dir}"
mkdir -p "${artifacts_dir}"

echo "Changing to terraform/${REGION} directory"
cd "terraform/${REGION}"

if [[ \! -e "${ENV}.tfstate" ]]; then
    echo "${ENV}.tfstate does not exist, skipping terraform refresh!"
else
    echo "Calling terraform refresh on ${ENV}.tfstate"
    terraform refresh -state="${ENV}.tfstate" -backup=-
    terraform_exit_status=$?
    cp "terraform/${REGION}/${ENV}.tfstate" "${CI_PROJECT_DIR}/artifacts/"
    if [[ ${terraform_exit_status} -eq 0 ]]; then
        echo "Terraform refresh was successful, generating human readable ${ENV}.tfstate.txt artifact"
        (terraform show -no-color "${ENV}.tfstate" > "${ENV}.tfstate.txt")
        cp "terraform/${REGION}/${ENV}.tfstate.txt" "${CI_PROJECT_DIR}/artifacts/"
    else
        >&2 echo "Terraform refresh failed: ${terraform_exit_status}"
        exit ${terraform_exit_status}
    fi
fi
