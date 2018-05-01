#!/bin/bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../../scripts/terraform-inventory-functions.sh"

export CONSUL_HTTP_TOKEN="${TERRAFORM_CONSUL_TOKEN}"

terraform_inventory "${SCRIPT_DIRECTORY}/../../../../terraform/delta-hgiarvados" production $@
