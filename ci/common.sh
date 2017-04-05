function ensure_set {
    for variableName in "$@"; do
        if [ -z "${!variableName+x}" ]; then
            >&2 echo "${variableName} must be set!"
            exit 1
        fi
    done
}