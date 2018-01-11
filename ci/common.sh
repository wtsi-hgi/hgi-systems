# Library of methods that are universally useful to all CI scripts.

# Ensures the global variables with the given names are set, else prints the unset ones in a human readable form to
# stderr and exits with an error status.
# Globals:
#   None
# Arguments:
#   list of names of global variables to check
# Returns:
#   None
function ensureSet {
    local -a variableNames=("$@")
    read -a unsetVariables <<< $(getUnset "${variableNames[@]}")

    if [ ${#unsetVariables[*]} -ne 0 ]; then
        printUnset "${unsetVariables[@]}"
        exit 1
    fi
}


# Gets the unset global variables from the list of variable names given.
# Globals:
#   None
# Arguments:
#   list of names of global variables to check
# Returns:
#   subset of given list as space separated string
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


# Prints a warning that the variables with the givend names have not been set.
# Globals:
#   None
# Arguments:
#   list of names of global variables to print as unset
# Returns:
#   None
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
