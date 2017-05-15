#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet CI_PROJECT_DIR REGION ENV ANSIBLE_VAULT_PASSWORD_FILE

artifacts_dir="${CI_PROJECT_DIR}/artifacts"
mkdir -p "${artifacts_dir}"
echo "Listing contents of artifacts directory ${artifacts_dir}"
artifacts=$(ls "${artifacts_dir}/")

tmp_dir="$(mktemp -d)"
echo "Copying tfstate artifacts to tmp dir ${tmp_dir}"
cp "${artifacts_dir}/${ENV}.tfstate" "${tmp_dir}/"

echo "Removing artifacts dir and recreating"
rm -rf "${artifacts_dir}"
mkdir -p "${artifacts_dir}"

echo "Changing to ansible directory"
cd ansible

export TF_STATE="${tmp_dir}/${ENV}.tfstate"
export ANSIBLE_CONFIG="${CI_PROJECT_DIR}/ansible/ansible-minimal.cfg"
echo "Calling ansible-playbook"
ansible-playbook -i terraform-production_hosts.d --vault-password-file "${ANSIBLE_VAULT_PASSWORD_FILE}" site.yml
playbook_exit_status=$?
rm -rf "${tmp_dir}"

if [[ ${playbook_exit_status} -eq 0 ]]; then
    echo "ansible-playbook was successful"
else
    >&2 echo "ansible-playbook failed: ${playbook_exit_status}"
    exit ${playbook_exit_status}
fi

