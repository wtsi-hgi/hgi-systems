#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../../inventory_scripts/openstack-inventory-functions.sh"

openstack_inventory delta hgi-ci "$@"
