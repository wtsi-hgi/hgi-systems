
function ensureSet {
    unsetVariables=()
    for variableName in "$@"; do
        if [ -z "${!variableName+x}" ]; then
            unsetVariables[${#unsetVariables[*]}]="${variableName}"
        fi
    done

    if [ ${#unsetVariables[*]} -ne 0 ]; then
        variablesList=""

        for (( i=0; i<${#unsetVariables[*]}; i++)); do
            unsetVariable="\"${unsetVariables[$i]}\""
            if [ "${variablesList}" = "" ]; then
                variablesList="${unsetVariable}"
            elif [ ${i} -eq $((${#unsetVariables[*]} - 1)) ]; then
                variablesList="${variablesList} and ${unsetVariable}"
            else
                variablesList="${variablesList}, ${unsetVariable}"
            fi
        done

        >&2 echo "${variablesList} must be set!"
        exit 1
    fi
}
