#!/bin/bash

set -euf -o pipefail

export OS_TENANT_NAME=hgi
if [[ -z "${OS_USERNAME}" ]]; then
    2>&1 echo "OS_USERNAME required"
    exit 1
fi
if [[ -z "${OS_PASSWORD}" ]]; then
    2>&1 echo "OS_PASSWORD required"
    exit 1
fi
if [[ -z "${OS_AUTH_URL}" ]]; then
    2>&1 echo "OS_AUTH_URL required"
    exit 1
fi

openstackinfo -i id | yaosadis --info - "$@"
