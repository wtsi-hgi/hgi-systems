#!/bin/bash

set -euf -o pipefail

module purge
module add hgi/jq/1.5-regex

app_group=$1

echo -n "Waiting for all apps in ${app_group} to be alive..."
while 1; do
    all_alive=$(for app in $(dcos marathon group show /${app_group} | jq -r '.apps[].id'); do dcos marathon app show ${app}; done | jq -s -r '[.[] | [.tasks[].healthCheckResults[].alive] | any] | all')
    if [[ "${all_alive}" == "true" ]]; then
	echo "All lustretree apps in group ${app_group} are alive!"
	exit 0
    fi
    sleep 60
    echo -n "." 
done

