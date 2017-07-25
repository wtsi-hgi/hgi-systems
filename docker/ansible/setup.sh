#!/usr/bin/env bash

set -ef -o pipefail

ssh_key_location_parameter="SSH_KEY_LOCATION"
vault_location_parameter="VAULT_LOCATION"

if [ -z ${!ssh_key_location_parameter} ]; then
    unsetParameter=$ssh_key_location_parameter
elif [ -z ${!vault_location_parameter} ]; then
    unsetParameter=$vault_location_parameter
fi

if [ "${unsetParameter}" ]; then
    >&2 echo "${unsetParameter} is not set"
    exit 1
fi

set -u

SSH_KEY_LOCATION=${!ssh_key_location_parameter}
VAULT_LOCATION=${!vault_location_parameter}

echo "${ssh_key_location_parameter} = ${SSH_KEY_LOCATION}"
echo "${vault_location_parameter} = ${VAULT_LOCATION}"

ln -s "${SSH_KEY_LOCATION}" ~/.ssh/id_rsa
ln -s "${SSH_KEY_LOCATION}" ~mercury/.ssh/id_rsa
ln -s "${VAULT_LOCATION}" ~/vault.pw

bash -c "$*"
