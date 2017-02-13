#!/bin/bash

cp ${CI_PROJECT_DIR}/artifacts/* "terraform/${REGION}/"
rm -rf "${CI_PROJECT_DIR}/artifacts"
mkdir -p "${CI_PROJECT_DIR}/artifacts"

(echo "$ANSIBLE_VAULT_PASSWORD" > /tmp/ansible_vault.pw)

cd "terraform/${REGION}"

terraform apply -input=false -state-out="${ENV}.tfstate.txt" plan
apply_exit_code=$?
cp "${ENV}.tfstate" "${CI_PROJECT_DIR}/artifacts/"

if [[ ${apply_exit_code} -eq 0 ]]; then
    terraform output -json -state "${ENV}.tfstate" > output.json
    cp output.json "${CI_PROJECT_DIR}/artifacts/"
    terraform show -no-color > "${ENV}.tfstate.txt"
    cp "${ENV}.tfstate.txt" "${CI_PROJECT_DIR}/artifacts/"
else
    >&2 echo "terraform apply failed"
    exit ${apply_exit_code}
fi
