#!/bin/bash

set -euf -o pipefail

artifacts_dir="${CI_PROJECT_DIR}/artifacts"
echo "Listing contents of artifacts directory ${artifacts_dir}"
artifacts=$(ls "${artifacts_dir}/")

if [[ -n "${artifacts}" ]]; then
    for artifact in ${artifacts}; do
        echo "Copying ${artifacts_dir}/${artifact} to terraform/${REGION}/"
        cp "${artifacts_dir}/${artifact}" "terraform/${REGION}/"
    done
else
    echo "No artifacts to copy"
fi

echo "Emptying artifacts directory"
rm -rf "${CI_PROJECT_DIR}/artifacts" && mkdir -p "${CI_PROJECT_DIR}/artifacts"

echo "Generating /tmp/ansible_vault.pw"
(echo "$ANSIBLE_VAULT_PASSWORD" > /tmp/ansible_vault.pw)

cd "terraform/${REGION}"

echo "Calling terraform apply"
terraform apply -input=false -state-out="${ENV}.tfstate.txt" plan
apply_exit_code=$?

echo "Copying ${ENV}.tfstate to artifacts"
cp "${ENV}.tfstate" "${CI_PROJECT_DIR}/artifacts/"

if [[ ${apply_exit_code} -eq 0 ]]; then
    echo "terraform apply succeeded, generating output state artifacts"
    terraform output -json -state "${ENV}.tfstate" > output.json
    cp output.json "${CI_PROJECT_DIR}/artifacts/"
    terraform show -no-color > "${ENV}.tfstate.txt"
    cp "${ENV}.tfstate.txt" "${CI_PROJECT_DIR}/artifacts/"
else
    >&2 echo "terraform apply failed: ${apply_exit_code}"
    exit ${apply_exit_code}
fi
