#!/usr/bin/env bash
set -euf -o pipefail

docker-compose -f tests/docker/docker-compose.test.yml rm -fs
docker-compose -f tests/docker/docker-compose.test.yml up \
    --build --abort-on-container-exit --exit-code-from test-runner --remove-orphans
