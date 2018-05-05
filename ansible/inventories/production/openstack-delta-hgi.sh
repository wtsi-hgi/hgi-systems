#!/bin/bash

set -euf -o pipefail

export OS_TENANT_NAME=hgi
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../../inventory_scripts/openstack-inventory-delta.sh"
