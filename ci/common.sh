function ensureSet {
    local -a variableNames=("$@")
    read -a unsetVariables <<< $(getUnset "${variableNames[@]}")

    if [ ${#unsetVariables[*]} -ne 0 ]; then
        printUnset "${unsetVariables[@]}"
        exit 1
    fi
}


function getUnset {
    local -a variableNames=("$@")
    local -a unsetVariables=()

    for variableName in "${variableNames[@]}"; do
        if [ -z "${!variableName+x}" ]; then
            unsetVariables[${#unsetVariables[*]}]="${variableName}"
        fi
    done

    if [ ${#unsetVariables[*]} -ne 0 ]; then
        echo "${unsetVariables[@]}"
    fi
}


function printUnset {
    local -a unsetVariables=("$@")

    if [ ${#unsetVariables[*]} -ne 0 ]; then
        local variablesString=""

        for (( i=0; i<${#unsetVariables[*]}; i++ )); do
            local unsetVariable="\"${unsetVariables[$i]}\""
            if [ "${variablesString}" = "" ]; then
                variablesString="${unsetVariable}"
            elif [ ${i} -eq $((${#unsetVariables[*]} - 1)) ]; then
                variablesString="${variablesString} and ${unsetVariable}"
            else
                variablesString="${variablesString}, ${unsetVariable}"
            fi
        done

        >&2 echo "${variablesString} must be set!"
    fi
}
