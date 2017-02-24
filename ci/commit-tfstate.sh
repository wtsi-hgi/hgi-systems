#!/bin/bash

set -euf -o pipefail

branch=$1
commit_message=$2
tfstate_paths=$3

echo "Current git remotes are:"
git remote -v

echo "Pulling ${CI_BUILD_REF_NAME} from git"
git pull origin ${CI_BUILD_REF_NAME}

echo "Setting git config"
git config user.name "Mercury"
git config user.email "mercury@sanger.ac.uk"

echo "Checking out new branch ${branch}"
git checkout -b ${branch}
git add "${tfstate_paths}"

echo "Getting git status"
status=$(git status --porcelain | awk '$1!="??"')

if [ -n "${status}" ]; then
    git commit -m "${commit_message}" || (echo "Failed to commit changes to ${tfstate_paths}" && exit 1)
    echo "Pushing to ${GITHUB_REPO}..."
    subrepos/gitlab-ci-git-push/git-push ${GITHUB_REPO} ${CI_BUILD_REF_NAME} || (echo "Failed to push to github" && exit 1)
    echo "Pushing to ${GITLAB_REPO}..."
    subrepos/gitlab-ci-git-push/git-push ${GITLAB_REPO} ${CI_BUILD_REF_NAME} || (echo "Failed to push to gitlab" && exit 1)
else
    echo "No changes to terraform state"
fi

