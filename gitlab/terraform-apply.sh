#!/bin/bash

cp ${CI_PROJECT_DIR}/artifacts/* "terraform/${REGION}/"
rm -rf "${CI_PROJECT_DIR}/artifacts"
mkdir -p "${CI_PROJECT_DIR}/artifacts"

(echo "$ANSIBLE_VAULT_PASSWORD" > /tmp/ansible_vault.pw)

cd "terraform/${REGION}"

terraform apply -input=false plan -state-out="${ENV}.tfstate.txt"
success=$?
cp "${ENV}.tfstate" "${CI_PROJECT_DIR}/artifacts/"

if [[ ${success} -eq 0 ]]; then
    terraform output -json -state "${ENV}.tfstate" > output.json
    cp output.json "${CI_PROJECT_DIR}/artifacts/"
    terraform show -no-color > "${ENV}.tfstate.txt"
    cp "${ENV}.tfstate.txt" "${CI_PROJECT_DIR}/artifacts/"
fi
