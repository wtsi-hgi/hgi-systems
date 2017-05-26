#!/bin/bash

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../inventory_scripts/terraform-inventory-functions.sh"

terraform_inventory "${SCRIPT_DIRECTORY}/../../terraform/delta-hgi" production $@
