#!/usr/bin/env bash

set -euf -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIRECTORY}/common.sh"

ensureSet CI_CONSUL_HTTP_TOKEN CI_CONSUL_HTTP_ADDR CI_CONSUL_DC \
          CI_LOCK_PREFIX CI_JOB_ID \
          CI_PROJECT_ID CI_PROJECT_URL GITLAB_TOKEN \
          CI_DOCKER_REGISTRY_URL CI_DOCKER_REGISTRY_USERNAME CI_DOCKER_REGISTRY_PASSWORD

# TODO: This should go into the image executing this environment
pip install -q python-gitlab

echo "thriftybuilder: $(pip show thriftybuilder | grep Version)"

CONSUL_HTTP_TOKEN=${CI_CONSUL_HTTP_TOKEN} CONSUL_HTTP_ADDR=${CI_CONSUL_HTTP_ADDR} CONSUL_DC=${CI_CONSUL_DC} consul-lock -v execute \
    -i=10 \
    --metadata="{jobId: ${CI_JOB_ID}}" \
    --on-before-lock=ci/release-dead-job-lock.py \
    ${CI_LOCK_PREFIX}/docker-build_${CI_PROJECT_ID} "thrifty -vv docker/build-configuration.yml"
