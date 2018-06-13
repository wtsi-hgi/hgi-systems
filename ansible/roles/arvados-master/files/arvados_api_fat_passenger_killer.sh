#!/bin/bash

export PASSENGER_INSTANCE_REGISTRY_DIR=/var/run/nginx/passenger

date=$(date)
echo "arvados_api_fat_passenger_killer running at ${date}" >> /var/log/arvados_api_fat_passenger_killer.log
fat_passenger_pids=$(/usr/sbin/passenger-memory-stats | grep 'Passenger AppPreloader: /var/www/arvados-api/current' | grep -v grep | awk '$4>5000 {print $4, $1}' | sort -rg | awk '{print $2}') 2> /dev/null
for fat_passenger_pid in ${fat_passenger_pids}; do
    echo "killing ${fat_passenger_pid}"
    passenger-config detach-process ${fat_passenger_pid}
done >> /var/log/arvados_api_fat_passenger_killer.log
