#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet CI_PROJECT_DIR REGION ANSIBLE_VAULT_PASSWORD_FILE TERRAFORM_CONSUL_TOKEN

# ansible bootstrapping only necessary for gitlab runner and consul (terraform remote state)
# if we've made it this far, gitlab runner must be working
# check to see if terraform remote state is working
echo "Testing terraform remote state for ${REGION}"
tstate=$(cd terraform/${REGION} terraform init && echo "ok")
if [[ "${tstate}" == "ok" ]]; then
    echo "Terraform remote state is ok, no need to bootstrap with ansible"
    exit 0
fi

echo "Terraform remote state was not ok:"
echo "${tstate}"
echo "Bootstrapping with ansible..."

export TMPDIR="${CI_PROJECT_DIR}/tmp"
echo "Ensuring TMPDIR=${TMPDIR} exists"
mkdir -p "${TMPDIR}"

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
