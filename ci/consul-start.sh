#!/usr/bin/env bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

# Settings
CONSUL_DATA_DIRECTORY=/tmp/consul/data

# Ensure required variables are set
ensure_set CONSUL_DATACENTER CONSUL_JOIN_ADDRESS CONSUL_ENCRYPT_KEY

# Setup consul agent
rm -rf "${CONSUL_DATA_DIRECTORY}"
mkdir -p "${CONSUL_DATA_DIRECTORY}"
consul agent \
    -data-dir "${CONSUL_DATA_DIRECTORY}" \
    -datacenter="${CONSUL_DATACENTER}" \
    -join "${CONSUL_JOIN_ADDRESS}" \
    -encrypt="${CONSUL_ENCRYPT_KEY}"
