SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../common.sh"

ensureSet CI_PIPELINE_ID CI_PROJECT_ID CI_SERVER GITLAB_TOKEN

./old-pipeline-suicide.py
