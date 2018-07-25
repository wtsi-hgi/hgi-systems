#!/bin/bash

export PASSENGER_INSTANCE_REGISTRY_DIR=/var/run/nginx/passenger
export PATH=/usr/sbin:$PATH

date=$(date)
echo "arvados_api_stuck_passenger_killer running at ${date}" >> /var/log/arvados_api_stuck_passenger_killer.log

stuck_passenger_pids=$(passenger-status --show=xml | python <(echo -e "import xmltodict\nimport json\nimport sys\nprint(json.dumps(xmltodict.parse(sys.stdin.read())))")     | jq -r '.info.supergroups.supergroup.group.processes.process[] | select(.enabled == "DETACHED") | select(.uptime | split("m")[0] > 4) | .pid' | perl -p -e 's/[[:space:]]+/ /g')

if [[ -n "${stuck_passenger_pids}" ]]; then
    echo "Killing stuck passengers: ${stuck_passenger_pids}" >> /var/log/arvados_api_stuck_passenger_killer.log
    kill -9 ${stuck_passenger_pids}
fi
