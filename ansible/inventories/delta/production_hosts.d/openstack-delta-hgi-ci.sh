#!/bin/bash

set -euf -o pipefail

export OS_TENANT_NAME=hgi-ci
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../scripts/openstack-inventory-delta.sh"
