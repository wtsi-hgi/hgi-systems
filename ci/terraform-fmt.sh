#!/bin/bash

set -euf -o pipefail
dir=$1

terraform_bin=$(which terraform)
if [ -z "${terraform_bin}" ]; then
  >&2 echo "terraform not in PATH, cannot run terraform fmt"
  exit 1
fi

if [ \! -d "${dir}" ]; then
  >&2 echo "${dir} is not a directory, cannot run terraform fmt in it"
  exit 2
fi

>&2 echo -n "Calling terraform fmt in ${dir} directory... "
fmt_diff=$(cd ${dir} && ${terraform_bin} fmt -write=false -diff=true)
if [[ -n "${fmt_diff}" ]]; then
  >&2 echo "error!"
  >&2 echo -e '\e[31mERROR: terraform fmt indicates formatting changes are required, suggest using a pre-commit hook to run `terraform fmt`'
  >&2 echo -e "\e[91m${fmt_diff}"
  exit 1
fi

>&2 echo "ok."
exit 0
