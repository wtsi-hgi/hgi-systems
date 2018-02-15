#!/usr/bin/env bash

set -euf -o pipefail

repositoryLocation="$1"
searchPattern="$2"

cd "${repositoryLocation}"

totalCommits=$(git rev-list --count --all)
git rev-list --all | (
    i=0
    while read commit; do
        i=$((i + 1))
        git grep -h -I -P "${searchPattern}" "${commit}" || true
        >&2 echo "{\"commit\": ${i}, \"total\": ${totalCommits}}"
    done
) | sort | uniq | jq -R -s -c 'split("\n")'
