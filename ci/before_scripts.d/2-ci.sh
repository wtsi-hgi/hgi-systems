SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../common.sh"

ensureSet CI_CONSUL_HTTP_TOKEN CI_CONSUL_HTTP_ADDR
