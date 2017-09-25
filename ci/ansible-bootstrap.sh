#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet CI_PROJECT_DIR ANSIBLE_VAULT_PASSWORD_FILE

echo "Changing to ansible directory"
cd ansible

export ANSIBLE_CONFIG="${CI_PROJECT_DIR}/ansible/ansible.cfg"
inventory=bootstrap_hosts.d
echo "Calling ansible-playbook bootstrap.yml on inventory ${inventory}"
ansible-playbook -i ${inventory} --vault-password-file "${ANSIBLE_VAULT_PASSWORD_FILE}" bootstrap.yml
playbook_exit_status=$?

if [[ ${playbook_exit_status} -eq 0 ]]; then
    echo "ansible-playbook was successful"
else
    >&2 echo "ansible-playbook failed: ${playbook_exit_status}"
    exit ${playbook_exit_status}
fi

