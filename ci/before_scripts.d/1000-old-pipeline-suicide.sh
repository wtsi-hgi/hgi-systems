SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/../common.sh"

ensureSet CI_PIPELINE_ID CI_PROJECT_ID CI_PROJECT_URL GITLAB_TOKEN

read -a unsetVariables <<< $(getUnset CI_PIPELINE_ID CI_PROJECT_ID CI_PROJECT_URL GITLAB_TOKEN)

if [[ -z ${unsetVariables+x} ]]; then
    ${SCRIPT_DIRECTORY}/../old-pipeline-suicide.py
else
    printUnset "${unsetVariables[@]}"
    >&2 echo "Not contemplating old-pipeline suicide as assuming running outside of the CI environment"
fi
