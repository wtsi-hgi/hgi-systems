#!/bin/bash

set -euf -o pipefail

url=$1
token=$2
executor=$3
description=$4
tags=$5
extraargs=$6

output_toml="/etc/gitlab-runner.d/token-${token}.toml"

echo "attempting to register ${url} ${executor} ${description} ${tags} ${extraargs}"
gitlab-ci-multi-runner register -n --url "${url}" --registration-token "${token}" --executor "${executor}" --description "${name}" --tag-list "${tags}" ${extraargs} -c "${output_toml}"
sed -ni '/^\[\[runners\]\]/ { p; :a; n; p; ba; }' "${output_toml}"

