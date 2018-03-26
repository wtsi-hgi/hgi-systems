#!/bin/bash

set -euf -o pipefail

source /software/hgi/etc/profile.hgi

# try to create lustretrees every 5 minutes for 6 hours (60/5*6=72)
for (( c=1; c<=72; c++ )); do
    >&2 echo "Attempt ${c} to create lustretrees"
    id=$(/nfs/humgen01/teams/hgi/conf/marathon/create-lustretrees.sh | egrep '^Created AppId:' | awk -F":" '{print $2}' || echo "")
    if [ -z "${id}" ]; then
	sleep 300
    else
	break
    fi
done

if [ -z "${id}" ]; then
    >&2 echo "Could not create lustretrees"
    exit 1
else
    /nfs/humgen01/teams/hgi/conf/marathon/kill-older-lustretrees-once-alive.sh ${id} 600
    exit 0
fi
