set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../common.sh"

ensureSet INFOBLOX_USERNAME INFOBLOX_PASSWORD INFOBLOX_HOST

export INFOBLOX_SSLVERIFY=false
