SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../common.sh"

ensureSet CI_PIPELINE_ID CI_PROJECT_ID CI_SERVER GITLAB_TOKEN

echo $GITLAB_CI
echo $CI_SERVER
echo $CI_PROJECT_URL
echo $CI_REPOSITORY_URL
echo $CI_ENVIRONMENT_URL
echo $CI

${SCRIPT_DIRECTORY}/../old-pipeline-suicide.py
