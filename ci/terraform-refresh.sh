#!/bin/bash

set -euf -o pipefail

artifacts_dir="${CI_PROJECT_DIR}/artifacts/"
echo "Creating artifacts directory ${artifacts_dir}"
mkdir -p "${artifacts_dir}"

echo "Changing to terraform/${REGION} directory"
cd "terraform/${REGION}"

if [[ -e "${ENV}.tfstate" ]]; then
    echo "Calling terraform refresh on ${ENV}.tfstate"
    terraform refresh -state="${ENV}.tfstate" -backup=-
    refresh_exit_status=$?
    cp "${ENV}.tfstate" "${CI_PROJECT_DIR}/artifacts/" || echo "WARNING: ${ENV}.tfstate not present after refresh"
    if [[ ${refresh_exit_status} -eq 0 ]]; then
        echo "Terraform refresh was successful, generating human readable ${ENV}.tfstate.txt artifact"
        (terraform show -no-color "${ENV}.tfstate" > "${ENV}.tfstate.txt")
        cp "${ENV}.tfstate.txt" "${CI_PROJECT_DIR}/artifacts/"
    else
        >&2 echo "Terraform refresh failed: ${refresh_exit_status}"
        exit ${refresh_exit_status}
    fi
else
    echo "${ENV}.tfstate does not exist, skipping terraform refresh!"
fi
