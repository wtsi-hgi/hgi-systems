export VERSION=$(${VERSION_COMMAND})
if [[ $? -ne 0 ]]; then
    >&2 echo "VERSION_COMMAND exited with error $?"
    exit $?
fi

if [[ -z "${VERSION}" ]]; then
    >&2 echo "VERSION_COMMAND \"${VERSION_COMMAND}\" returned empty version string"
    exit 1
else
    echo "VERSION set to '${VERSION}'"
fi
