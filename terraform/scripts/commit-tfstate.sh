#!/bin/bash

set -euf -o pipefail

branch=$1

git config user.name "Mercury"
git config user.email "mercury@sanger.ac.uk"
git checkout -b ${branch}
git add terraform/terraform.tfstate

status=$(git status --porcelain | awk '$1!="??"')

if [ -n "${status}" ]; then
    git commit -m "Changes to terraform.tfstate made by terraform" || (echo "Failed to commit changes to terraform.tfstate" && exit 1)
    echo "Pushing to ${GITHUB_REPO}..."
    subrepos/gitlab-ci-git-push/git-push ${GITHUB_REPO} ${CI_BUILD_REF_NAME} || (echo "Failed to push to github" && exit 1)
    echo "Pushing to ${GITLAB_REPO}..."
    subrepos/gitlab-ci-git-push/git-push ${CI_BUILD_REPO} ${CI_BUILD_REF_NAME} || (echo "Failed to push to gitlab" && exit 1)
else
    echo "No changes to terraform state"
fi

