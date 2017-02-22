#!/bin/bash

set -euf -o pipefail

before_script_dirs=$@

declare -A before_scripts
for dir in ${before_script_dirs}; do
    if [ \! -d "${dir}" ]; then
        echo "before script directory ${dir} does not exist or is not a directory"
        continue
    fi
    scripts=$(ls "${dir}/" | egrep -v '(^#)|(~$)' || echo -n "")
    for script in ${scripts}; do
        script_path="${dir}/${script}"
        test -r "${script_path}" || (echo "Script ${script_path} exists but is not readable"; exit 1)
        before_scripts[${script}]="${script_path}"
    done
done

for script in $(printf '%s\n' "${!before_scripts[@]}" | sort -V); do
    script_path=${before_scripts[${script}]}
    echo "Sourcing ${script} (${script_path})..."
    source "${script_path}"
done
