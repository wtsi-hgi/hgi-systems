#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

# Work-around for https://github.com/ansible/ansible/issues/35833
unset CONSUL_HTTP_TOKEN
unset CONSUL_HTTP_ADDR

ensureSet CI_PROJECT_DIR REGION SETUP ENV ANSIBLE_VAULT_PASSWORD_FILE ANSIBLE_CONSUL_TOKEN ANSIBLE_CONSUL_URL
echo "Changing to ansible directory"
cd ansible

export ANSIBLE_CONFIG="${CI_PROJECT_DIR}/ansible/ansible.cfg"
inventory="inventories/${REGION}-terraform-${SETUP}-${ENV}"
echo "Calling ansible-playbook site.yml on inventory ${inventory}"
ansible-playbook -vvv -i ${inventory} --vault-password-file "${ANSIBLE_VAULT_PASSWORD_FILE}" -l terraform-ci-${REGION}-${SETUP} site.yml
playbook_exit_status=$?

if [[ ${playbook_exit_status} -eq 0 ]]; then
    echo "ansible-playbook was successful"
else
    >&2 echo "ansible-playbook failed: ${playbook_exit_status}"
    exit ${playbook_exit_status}
fi
