#!/usr/bin/env bash

set -eu -o pipefail

/usr/sbin/sshd -D &
docker-entrypoint.sh postgres
