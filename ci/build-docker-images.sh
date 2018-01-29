#!/usr/bin/env bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet CI_CONSUL_HTTP_TOKEN CI_CONSUL_HTTP_ADDR CI_LOCK_PREFIX \
          CI_DOCKER_REGISTRY_URL CI_DOCKER_REGISTRY_USERNAME CI_DOCKER_REGISTRY_PASSWORD

echo "thriftybuilder: $(pip show thriftybuilder | grep Version)"

export CONSUL_HTTP_TOKEN=${CI_CONSUL_HTTP_TOKEN}
export CONSUL_HTTP_ADDR=${CI_CONSUL_HTTP_ADDR}

consul-lock -v execute ${CI_LOCK_PREFIX}/docker-build "thrifty -vv docker/build-configuration.yml"
