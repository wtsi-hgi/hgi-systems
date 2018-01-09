#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

cleanupLock() {
    CONSUL_HTTP_TOKEN=${LOCKS_CONSUL_HTTP_TOKEN} CONSUL_HTTP_ADDR=${LOCKS_CONSUL_HTTP_ADDR} consul-lock unlock \
        ${ANSIBLE_LOCK_PREFIX}/${CI_JOB_NAME}
    exit
}

read -a unsetVariables <<< $(getUnset LOCKS_CONSUL_HTTP_TOKEN LOCKS_CONSUL_HTTP_ADDR CI_JOB_ID ANSIBLE_LOCK_PREFIX CI_JOB_NAME)
if [[ -z ${unsetVariables+x} ]]; then
    trap cleanupLock INT TERM

    CONSUL_HTTP_TOKEN=${LOCKS_CONSUL_HTTP_TOKEN} CONSUL_HTTP_ADDR=${LOCKS_CONSUL_HTTP_ADDR} consul-lock -v lock \
         -i=10 \
         --metadata="{jobId: ${CI_JOB_ID}}" \
         --on-before-lock=ci/release-dead-job-lock.py \
         --on-before-lock=ci/old-pipeline-suicide.py \
         ${ANSIBLE_LOCK_PREFIX}/${CI_JOB_NAME}
else
    printUnset "${unsetVariables[@]}"
    >&2 echo "Continuing without locking as necessary variables are not set"
fi

ensureSet CI_PROJECT_DIR REGION ENV ANSIBLE_VAULT_PASSWORD_FILE
echo "Changing to ansible directory"
cd ansible

export ANSIBLE_CONFIG="${CI_PROJECT_DIR}/ansible/ansible.cfg"
inventory=terraform-${REGION}-${ENV}_hosts.d
echo "Calling ansible-playbook site.yml on inventory ${inventory}"
ansible-playbook -i ${inventory} --vault-password-file "${ANSIBLE_VAULT_PASSWORD_FILE}" site.yml -l terraform-ci
playbook_exit_status=$?

if [[ ${playbook_exit_status} -eq 0 ]]; then
    echo "ansible-playbook was successful"
else
    >&2 echo "ansible-playbook failed: ${playbook_exit_status}"
    exit ${playbook_exit_status}
fi
