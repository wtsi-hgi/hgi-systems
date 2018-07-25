#!/bin/bash

set -euf -o pipefail
dir=$1

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
terraform_bin="${SCRIPT_DIRECTORY}/terraform.sh"

if [ \! -d "${dir}" ]; then
  >&2 echo "${dir} is not a directory, cannot run terraform fmt in it"
  exit 2
fi

>&2 echo -n "Calling terraform fmt in ${dir} directory... "
fmt_diff=$(cd ${dir} && ${terraform_bin} fmt -write=false -diff=true)
if [[ -n "${fmt_diff}" ]]; then
  >&2 echo -e "\e[31merror!\e[0m"
  >&2 echo -e '\e[31mterraform fmt indicates formatting changes are required, please run `terraform fmt` or make the following changes manually:\e[0m'
  >&2 echo -e "\e[91m${fmt_diff}\e[0m"
  exit 1
fi

>&2 echo -e "\e[32mok.\e[0m"
exit 0
