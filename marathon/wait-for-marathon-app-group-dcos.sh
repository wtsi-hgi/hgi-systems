#!/bin/bash

set -euf -o pipefail

module purge
module add hgi/jq/1.5-regex
module add hgi/dcoscli/0.3.6

app_group=$1
marathon_config="/home/mercury/marathonctl.config"

# get marathon config
if [ -r "${marathon_config}" ]; then
    user=$(cat "${marathon_config}" | awk '$1=="marathon.user:" {print $2}')
    if [ -z "${user}" ]; then
	>&2 echo "Could not obtain user from ${marathon_config}"
	exit 1
    fi
    pass=$(cat "${marathon_config}" | awk '$1=="marathon.password:" {print $2}')
    if [ -z "${pass}" ]; then
	>&2 echo "Could not obtain password from ${marathon_config}"
	exit 1
    fi
    hostport=$(cat "${marathon_config}" | awk '$1=="marathon.host:" {print $2}' | perl -p -e 's/^http\:\/\///')
    if [ -z "${hostport}" ]; then
	>&2 echo "Could not obtain hostport from ${marathon_config}"
	exit 1
    fi
    scheme=$(cat "${marathon_config}" | awk '$1=="marathon.host:" {print $2}' | perl -p -e 's/^(.*?)\:\/\/.*/$1/')
    if [ -z "${scheme}" ]; then
	>&2 echo "Could not obtain scheme from ${marathon_config}"
	exit 1
    fi
else
    >&2 echo "Could not find ${marathon_config} (are you on hgi-mercury-farm3?)"
    exit 1
fi

# setup dcos cli
>&2 echo "Setting up dcos"
tmp=$(mktemp -d)
export DCOS_CONFIG=${tmp}/dcos.toml
dcos < /dev/null &> /dev/null
dcos config set marathon.url ${scheme}://${user}:${pass}@${hostport}
dcos config set core.ssl_verify false

# wait for all apps to become alive
echo -n "Waiting for all apps in ${app_group} to be alive..."
app_ids=$(dcos marathon group show /${app_group} | jq -r '.apps[].id')
if [[ -z "${app_ids}" ]]; then
    echo " could not get list of app ids for group ${app_group}!"
    exit 1
fi
while true; do
    all_alive=$(for app in ${app_ids}; do dcos marathon app show ${app}; done | jq -s -r '[.[] | [.tasks[].healthCheckResults[].alive] | any] | all')
    if [[ "${all_alive}" == "true" ]]; then
	echo " all lustretree apps in group ${app_group} are alive!"
	exit 0
    fi
    echo -n "." 
    sleep 60
done

