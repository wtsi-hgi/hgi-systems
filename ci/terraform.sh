#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet TERRAFORM_CONSUL_TOKEN
export CONSUL_HTTP_TOKEN="${TERRAFORM_CONSUL_TOKEN}"

terraform_bin=$(which terraform)
if [ -z "${terraform_bin}" ]; then
  >&2 echo "terraform not in PATH, cannot run terraform"
  exit 1
fi

set +e
${terraform_bin} "$@"
tf_exit_status=$?
set -e

if [[ -d "${ARTIFACTS_DIR+}" ]]; then
    if [[ -e crash.log ]]; then
	echo "Copying crash.log to artifacts dir ${ARTIFACTS_DIR}"
	cp crash.log "${ARTIFACTS_DIR}/"
    fi
fi

exit ${tf_exit_status}
