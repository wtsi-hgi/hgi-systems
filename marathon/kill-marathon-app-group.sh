#!/bin/bash

set -euf -o pipefail

module purge
module add hgi/jq/1.5-regex
module add hgi/marathonctl/git-20160227-3e2e8f6b

app_group=$1
marathon_config="/home/mercury/marathonctl.config"
marathonctl="marathonctl -c ${marathon_config} -f json"

${marathonctl} group destroy ${app_group}
