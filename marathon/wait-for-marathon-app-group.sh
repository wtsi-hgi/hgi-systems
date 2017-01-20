#!/bin/bash

set -euf -o pipefail

module purge
module add hgi/jq/1.5-regex
module add hgi/marathonctl/git-20160227-3e2e8f6b

app_group=$1
wait_m=$2
marathon_config="/home/mercury/marathonctl.config"
marathonctl="marathonctl -c ${marathon_config} -f json"

# wait for all apps to become alive
echo "Getting list of apps in ${app_group}..."
app_ids=$(${marathonctl} group list ${app_group} | jq -r '.apps[].id')
if [[ -z "${app_ids}" ]]; then
    echo " could not get list of app ids for group ${app_group}!"
    exit 1
fi
echo -n "Waiting up to ${wait_m} minutes for all apps in ${app_group} ("${app_ids}") to be alive..."
for (( c=1; c<=${wait_m}; c++ )); do
    all_alive=$(for app in ${app_ids}; do ${marathonctl} app show ${app}; done | jq -s -r '[.[] | [.app.tasks[].healthCheckResults[].alive] | any] | all' || echo -n "false")
    if [[ "${all_alive}" == "true" ]]; then
	echo " all lustretree apps in group ${app_group} are alive!"
	exit 0
    fi
    echo -n "." 
    sleep 60
done

