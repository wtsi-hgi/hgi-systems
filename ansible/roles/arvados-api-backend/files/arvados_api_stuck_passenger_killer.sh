#!/bin/bash

export PASSENGER_INSTANCE_REGISTRY_DIR=/var/run/nginx/passenger
export PATH=/usr/sbin:$PATH

mkdir -p /var/www/arvados-api/current/tmp/fat_passengers

date=$(date)
echo "arvados_api_stuck_passenger_killer running at ${date}" >> /var/log/arvados_api_stuck_passenger_killer.log

find "/var/www/arvados-api/current/tmp/fat_passengers" -name \*.timestamp | while read fpts; do
    pid=$(echo ${fpts} | cut -f1 -d.)
    fts=$(cat ${fpts})
    cts=$(date +"%s")
    if [[ -d /proc/${pid} ]]; then
        cat /proc/48812/cmdline | grep '^Passenger' || (echo "${pid} is not a passenger process" >> /var/log/arvados_api_stuck_passenger_killer.log; rm ${fpts}; continue)
        echo "fat passenger ${pid} appears to still be running" >> /var/log/arvados_api_stuck_passenger_killer.log
        tsk=$((${cts}-${fts}))
        if [[ ${tsk} -gt 300 ]]; then
            echo "fat passenger ${pid} has been running for more than 300s, killing it" >> /var/log/arvados_api_stuck_passenger_killer.log
            kill -9 ${pid}
        else
            echo "fat passenger ${pid} has only been running for ${tsk}s since becoming fat. not killing it yet" >> /var/log/arvados_api_stuck_passenger_killer.log
        fi
    else
        echo "fat passenger ${pid} no longer running, removing ${fpts}"
        rm ${fpts}
    fi
done
