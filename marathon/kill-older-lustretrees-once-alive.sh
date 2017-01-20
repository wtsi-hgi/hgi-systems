#!/bin/bash

set -euf -o pipefail

module purge
module add hgi/jq/1.5-regex
module add hgi/marathonctl/git-20160227-3e2e8f6b

lustretree_id=$1
wait_m=$2
marathon_config="/home/mercury/marathonctl.config"
marathonctl="marathonctl -c ${marathon_config} -f json"

>&2 echo "Getting list of lustretrees other than ${lustretree_id}..."
lustretrees_to_be_killed=$(${marathonctl} group list /production/lustretree/  | jq -r '.groups[] | select(.id != "'${lustretree_id}'") | .id')
>&2 echo "Plan to kill ${lustretrees_to_be_killed} once ${lustretree_id} is healthy."

>&2 echo "Waiting for lustretree ${lustretree_id}..."
/nfs/humgen01/teams/hgi/conf/marathon/wait-for-marathon-app-group.sh ${lustretree_id} ${wait_m}

for id in ${lustretrees_to_be_killed}; do 
    >&2 echo "Destroying marathon app group ${id}..."
    ${marathonctl} group destroy ${id}
    >&2 echo "done."
done

>&2 echo "All done."
