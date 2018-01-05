#!/bin/bash

set -uf -o pipefail

log=$(/nfs/humgen01/teams/hgi/conf/marathon/create-and-kill-lustretrees.sh 2>&1)

if [ $? -gt 0 ]; then
    >&2 echo "Could not update Lustretrees"
    >&2 echo "${log}"
    curllog=$(curl -X POST --data-urlencode 'payload={"channel": "#lustretree", "username": "mercury-lustretree", "text": "Failed to update <https://hgi.dev.sanger.ac.uk/lustretree/|LustreTree>: '"${log}"'", "icon_emoji": ":evergreen_tree:"}' "$(cat /home/mercury/mercury-slack-lustretree.webhook)" 2>&1)
    if [ $? -gt 0 ]; then
	>&2 echo "Could not notify slack of failure to update Lustretree"
	>&2 echo "${curllog}"
    fi
    exit 1
fi

latest=$(echo "${log}" | grep '^Will start lustretree servers for' | tail -n 1 | awk '{print $6}' || echo "latest")
curllog=$(curl -X POST --data-urlencode 'payload={"channel": "#lustretree", "username": "mercury-lustretree", "text": "<https://hgi.dev.sanger.ac.uk/lustretree/|LustreTree> updated to '"${latest}"'!", "icon_emoji": ":evergreen_tree:"}' "$(cat /home/mercury/mercury-slack-lustretree.webhook)" 2>&1)
if [ $? -gt 0 ]; then
    >&2 echo "Could not notify slack of successful Lustretree update"
    >&2 echo "${curllog}"
    exit 2
fi

exit 0
