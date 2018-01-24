#!/usr/bin/env bash

set -euf -o pipefail

pip show thriftybuilder | grep Version

thrifty -vv docker/build-configuration.yml
