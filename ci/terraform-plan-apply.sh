#!/bin/bash

set -euf -o pipefail

PARALLELISM=20
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet CI_PROJECT_DIR REGION SETUP ENV ANSIBLE_VAULT_PASSWORD TERRAFORM_CONSUL_TOKEN

>&2 echo "Run information: REGION=${REGION} SETUP=${SETUP} ENV=${ENV}"

terraform_bin="${SCRIPT_DIRECTORY}/terraform.sh"

export ARTIFACTS_DIR="${CI_PROJECT_DIR}/artifacts"
mkdir -p "${ARTIFACTS_DIR}"
echo "Listing contents of artifacts directory ${ARTIFACTS_DIR}"
artifacts=$(ls "${ARTIFACTS_DIR}/")

echo "Sourcing terraform-init-workspace.sh"
. ${SCRIPT_DIRECTORY}/terraform-init-workspace.sh

echo "Calling terraform plan"
# FIXME: the -parallelism is to work around infoblox provider concurrency issues, fix this in provider and restore concurrent operations
set +e
${terraform_bin} plan -input=false -out plan -parallelism=${PARALLELISM}
plan_exit_status=$?
set -e

if [[ ${plan_exit_status} -eq 0 ]]; then
    echo "Terraform plan was successful, copying plan to artifacts"
    cp plan "${ARTIFACTS_DIR}/"
    echo "Generating human readable ${ENV}.tfstate.txt artifact"
    (${terraform_bin} show -no-color > "${ENV}.tfstate.txt")
    cp "${ENV}.tfstate.txt" "${ARTIFACTS_DIR}"
    echo "Generating human-readable plan.txt artifact"
    ${terraform_bin} show -no-color plan > plan.txt
    cp plan.txt "${ARTIFACTS_DIR}/"
else
    >&2 echo "Terraform plan failed: ${plan_exit_status}"
    exit ${plan_exit_status}
fi

echo "Generating /tmp/ansible_vault.pw"
(echo "${ANSIBLE_VAULT_PASSWORD}" > /tmp/ansible_vault.pw)

echo "Calling terraform apply"
set +e
${terraform_bin} apply -input=false -refresh=false -parallelism=${PARALLELISM} plan
apply_exit_code=$?
set -e

if [[ ${apply_exit_code} -eq 0 ]]; then
    echo "terraform apply succeeded, generating output state artifacts"
    ${terraform_bin} output -json > output.json
    cp output.json "${CI_PROJECT_DIR}/artifacts/"
    ${terraform_bin} state pull > "${ENV}.tfstate"
    cp "${ENV}.tfstate" "${CI_PROJECT_DIR}/artifacts/"
    ${terraform_bin} show -no-color > "${ENV}.tfstate.txt"
    cp "${ENV}.tfstate.txt" "${CI_PROJECT_DIR}/artifacts/"
else
    >&2 echo "terraform apply failed: ${apply_exit_code}"
    exit ${apply_exit_code}
fi
