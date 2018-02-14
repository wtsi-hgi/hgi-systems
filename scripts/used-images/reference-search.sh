#!/usr/bin/env bash

set -euf -o pipefail

GREP_PATTERN="(^| |-|_|\"|')[0-9a-f]{8}($| |-|_|\"|')"

if [[ "$#" -ne 1 ]]; then
    >&2 echo "The location of the git repository to examine should be passed as the first and only argument"
    exit 1
fi
repositoryLocation="$1"

cd "${repositoryLocation}"

totalCommits=$(git rev-list --count --all)
git rev-list --all | (
    i=0
    while read commit; do
        i=$((i + 1))
        git grep -h -I -P "${GREP_PATTERN}" "${commit}" || true
        >&2 echo "{\"commit\": ${i}, \"total\": ${totalCommits}}"
    done
) | grep --only-matching -E "[0-9a-f]{8}" | sort | uniq | jq -R -s -c 'split("\n")'
