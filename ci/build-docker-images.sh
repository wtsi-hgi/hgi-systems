#!/usr/bin/env bash

set -euf -o pipefail

pip show thriftybuilder | grep Version

# FIXME: Stop stealing Consul details designed for use with Consul lock - either make own or generalise!
export CONSUL_HTTP_TOKEN=${LOCKS_CONSUL_HTTP_TOKEN}
export CONSUL_HTTP_ADDR=${LOCKS_CONSUL_HTTP_ADDR}

thrifty -vv docker/build-configuration.yml
