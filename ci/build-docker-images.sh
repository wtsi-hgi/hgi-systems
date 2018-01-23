#!/usr/bin/env bash

set -euf -o pipefail

pip install -q git+https://github.com/wtsi-hgi/thrifty-builder#egg=thriftybuilder
thrifty -v

thrifty -vv docker/build-configuration.yml
