#!/usr/bin/env bash

set -euf -o pipefail

pip install -q git+https://github.com/wtsi-hgi/thrifty-builder#egg=thriftybuilder
pip show thriftybuilder | grep Version

sleep 250

thrifty -vv docker/build-configuration.yml
