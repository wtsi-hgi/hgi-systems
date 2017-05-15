#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet CI_PROJECT_DIR REGION ENV ANSIBLE_VAULT_PASSWORD

artifacts_dir="${CI_PROJECT_DIR}/artifacts"
mkdir -p "${artifacts_dir}"
echo "Listing contents of artifacts directory ${artifacts_dir}"
artifacts=$(ls "${artifacts_dir}/")

echo "Changing to terraform/${REGION} directory"
cd terraform/${REGION}

echo "Calling terraform init"
terraform init

echo "Switching to ${ENV} environment"
set +e
terraform env select ${ENV}
env_exit_status=$?
set -e
if [[ ${env_exit_status} -ne 0 ]]; then
    echo "Could not switch to ${ENV} environment, attempting to create a new one"
    terraform env new ${ENV}
fi

echo "Calling terraform refresh"
terraform refresh

echo "Calling terraform plan"
set +e
terraform plan -input=false -out plan
plan_exit_status=$?
set -e
echo "Copying plan to artifacts"
cp plan "${artifacts_dir}/"

if [[ ${plan_exit_status} -eq 0 ]]; then
    echo "Terraform plan was successful"
    echo "Generating human readable ${ENV}.tfstate.txt artifact"
    (terraform show -no-color > "${ENV}.tfstate.txt")
    cp "${ENV}.tfstate.txt" "${artifacts_dir}"
    echo "Generating human-readable plan.txt artifact"
    terraform show -no-color plan > plan.txt
    cp plan.txt "${artifacts_dir}/"
else
    >&2 echo "Terraform plan failed: ${plan_exit_status}"
    exit ${plan_exit_status}
fi

echo "Generating /tmp/ansible_vault.pw"
(echo "${ANSIBLE_VAULT_PASSWORD}" > /tmp/ansible_vault.pw)

echo "Calling terraform apply"
set +e
terraform apply -input=false -refresh=false plan
apply_exit_code=$?
set -e

if [[ ${apply_exit_code} -eq 0 ]]; then
    echo "terraform apply succeeded, generating output state artifacts"
    terraform output -json > output.json
    cp output.json "${CI_PROJECT_DIR}/artifacts/"
    terraform state pull > "${ENV}.tfstate"
    cp "${ENV}.tfstate" "${CI_PROJECT_DIR}/artifacts/"
    terraform show -no-color > "${ENV}.tfstate.txt"
    cp "${ENV}.tfstate.txt" "${CI_PROJECT_DIR}/artifacts/"
else
    >&2 echo "terraform apply failed: ${apply_exit_code}"
    exit ${apply_exit_code}
fi

