#!/bin/bash

set -euf -o pipefail

artifacts_dir="${CI_PROJECT_DIR}/artifacts"
mkdir -p "${artifacts_dir}"
echo "Listing contents of artifacts directory ${artifacts_dir}"
artifacts=$(ls "${artifacts_dir}/")

echo "Changing to terraform/${REGION} directory"
cd terraform/${REGION}

echo "Calling terraform init"
terraform init

echo "Calling terraform plan"
terraform plan -input=false -out plan
plan_exit_status=$?
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
    echo "Generating dot graph plan.dot from plan"
    terraform graph plan > plan.dot
    cp plan.dot "${artifacts_dir}/"
    echo "Generating plan.png PNG from graph"
    dot -Tpng < plan.dot > plan.png
    cp plan.png "${artifacts_dir}/" 
else
    >&2 echo "Terraform plan failed: ${plan_exit_status}"
    exit ${plan_exit_status}
fi

echo "Generating /tmp/ansible_vault.pw"
(echo "$ANSIBLE_VAULT_PASSWORD" > /tmp/ansible_vault.pw)

echo "Calling terraform apply"
set +e
terraform apply -input=false plan
apply_exit_code=$?
set -e

if [[ ${apply_exit_code} -eq 0 ]]; then
    echo "terraform apply succeeded, generating output state artifacts"
    terraform output -json > output.json
    cp output.json "${CI_PROJECT_DIR}/artifacts/"
    terraform show -no-color > "${ENV}.tfstate.txt"
    cp "${ENV}.tfstate.txt" "${CI_PROJECT_DIR}/artifacts/"
else
    >&2 echo "terraform apply failed: ${apply_exit_code}"
    exit ${apply_exit_code}
fi
