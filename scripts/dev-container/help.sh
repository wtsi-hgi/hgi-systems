#!/usr/bin/env bash

set -eu -o pipefail

sshAliases="$(grep -e ^Host ~/.ssh/config | grep -v '*' | sed 's/Host //g' | tr '\n' ' ')"

>&2 cat << EOM
# Dev Container Help Page

## SSH
The following SSH aliases are installed:
${sshAliases}
e.g. you can use "ssh $(echo "${sshAliases}" | cut -d " " -f 1)"

## Help
To display this help page, type: "dev-help" or simply yell for "heeeelllppp".
EOM
