#!/usr/bin/env bash

set -eu -o pipefail

cd tests

hosts="$(ansible targets -i inventory.ini --list-hosts | tail --lines=+2 | sed -e 's/ //g')"

for host in ${hosts}; do
    >&2 echo "Waiting for host: ${host}"
    /opt/wait-for-it.sh "${host}:22"
done

ansible-playbook -i inventory.ini -v test.yml
