#!/bin/bash

set -euf -o pipefail

PARALLELISM=20
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet CI_PROJECT_DIR REGION SETUP ENV ANSIBLE_VAULT_PASSWORD TERRAFORM_CONSUL_TOKEN

export CONSUL_HTTP_TOKEN="${TERRAFORM_CONSUL_TOKEN}"

artifacts_dir="${CI_PROJECT_DIR}/artifacts"
mkdir -p "${artifacts_dir}"
echo "Listing contents of artifacts directory ${artifacts_dir}"
artifacts=$(ls "${artifacts_dir}/")

region_setup="${REGION}-${SETUP}"
echo "Changing to terraform/${region_setup} directory"
cd terraform/${region_setup}

echo "Calling terraform init"
terraform init

echo "Switching to ${ENV} workspace"
set +e
terraform workspace select ${ENV}
workspace_exit_status=$?
set -e
if [[ ${workspace_exit_status} -ne 0 ]]; then
    echo "Could not switch to ${ENV} workspace, attempting to create a new one"
    terraform workspace new ${ENV}
    workspace_new_exit_status=$?
    if [[ ${workspace_new_exit_status} -ne 0 ]]; then
	>&2 echo "Could not create new workspace ${ENV} - if error is Permission Denied, check if CONSUL_HTTP_TOKEN is set correctly"
	exit ${workspace_new_exit_status}
    fi
fi

echo "Calling terraform init again"
terraform init

echo "Calling terraform get"
terraform get

echo "Calling terraform plan"
# FIXME: the -parallelism is to work around infoblox provider concurrency issues, fix this in provider and restore concurrent operations
set +e
terraform plan -input=false -out plan -parallelism=${PARALLELISM}
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

echo "Preparing required OpenStack images (S3 -> OS if not in OS)"
"${SCRIPT_DIRECTORY}/terraform-prepare-os-images-2.py plan ${S3_IMAGE_BUCKET}"

echo "Generating /tmp/ansible_vault.pw"
(echo "${ANSIBLE_VAULT_PASSWORD}" > /tmp/ansible_vault.pw)

echo "Calling terraform apply"
set +e
terraform apply -input=false -refresh=false -parallelism=${PARALLELISM} plan
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
