#!/usr/bin/env bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Settings
CONSUL_INSTALL_DIRECTORY=/tmp/consul/bin
CONSUL_DATA_DIRECTORY=/tmp/consul/data
CONSUL_DOWNLOAD_SOURCE=https://releases.hashicorp.com/consul/0.7.5/consul_0.7.5_linux_amd64.zip
CONSUL_DOWNLOAD_DESTINATION=/tmp/consul.zip
COMMON_SCRIPT="${SCRIPT_DIRECTORY}/common.sh"

# Ensure required variables are set
source "${COMMON_SCRIPT}"
ensure_set CONSUL_DATACENTER CONSUL_JOIN_ADDRESS CONSUL_ENCRYPT_KEY

# Install consul
mkdir -p "${CONSUL_INSTALL_DIRECTORY}"
wget "${CONSUL_DOWNLOAD_SOURCE}" -O "${CONSUL_DOWNLOAD_DESTINATION}"
unzip -d "${CONSUL_INSTALL_DIRECTORY}" "${CONSUL_DOWNLOAD_DESTINATION}"
test -f "${CONSUL_INSTALL_DIRECTORY}/consul"
rm "${CONSUL_DOWNLOAD_DESTINATION}"
export PATH="${CONSUL_INSTALL_DIRECTORY}:${PATH}"

# Setup consul agent
mkdir -p "${CONSUL_DATA_DIRECTORY}"
consul agent -data-dir "${CONSUL_DATA_DIRECTORY}" -datacenter="${CONSUL_DATACENTER}" -join "${CONSUL_JOIN_ADDRESS}" -encrypt="${CONSUL_ENCRYPT_KEY}"
