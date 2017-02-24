
set -euf -o pipefail

cp "${CI_PROJECT_DIR}/artifacts/${ENV}.tfstate" "terraform/${REGION}/${ENV}.tfstate" || (echo "No ${ENV}.tfstate in artifacts, skipping commit" && exit 0)

${CI_PROJECT_DIR}/ci/commit-tfstate.sh "ci-tfstate-${VERSION}" "Changes to ${ENV}.tfstate made by terraform [ci skip]" "terraform/${REGION}/${ENV}.tfstate"
