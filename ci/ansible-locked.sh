#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANSIBLE_SCRIPT="${SCRIPT_DIRECTORY}/ansible.sh"

source "${SCRIPT_DIRECTORY}/common.sh"
read -a unsetVariables <<< $(getUnset CI_CONSUL_HTTP_TOKEN CI_CONSUL_HTTP_ADDR CI_JOB_ID ANSIBLE_LOCK_PREFIX CI_JOB_NAME)
if [[ -z ${unsetVariables+x} ]]; then
    >&2 echo "Getting Consul lock..."
    CONSUL_HTTP_TOKEN=${CI_CONSUL_HTTP_TOKEN} CONSUL_HTTP_ADDR=${CI_CONSUL_HTTP_ADDR} consul-lock -v execute \
         -i=10 \
         --metadata="{jobId: ${CI_JOB_ID}}" \
         --on-before-lock=ci/release-dead-job-lock.py \
         --on-before-lock=ci/old-pipeline-suicide.py \
         ${ANSIBLE_LOCK_PREFIX}/${CI_JOB_NAME} \
         "${ANSIBLE_SCRIPT}"
else
    printUnset "${unsetVariables[@]}"
    >&2 echo "Continuing without locking as necessary variables are not set"
    "${ANSIBLE_SCRIPT}"
fi
