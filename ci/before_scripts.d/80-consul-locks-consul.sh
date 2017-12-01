SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../common.sh"

ensureSet LOCKS_CONSUL_HTTP_TOKEN LOCKS_CONSUL_HTTP_ADDR
