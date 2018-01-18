function printVersion {
    local binary="$1"
    local versionGetter="$2"

    local result
    type -P "${binary}" > /dev/null && \
        result="${binary}: $(eval ${versionGetter})" || \
        result="${binary} is not installed"

    echo "${result}"
}

printVersion "python" "python --version"
printVersion "pip" "pip --version"
printVersion "terraform" "terraform --version | head -n 1"
printVersion "ansible" "ansible --version | head -n 1"
printVersion "s3cmd" "s3cmd --version"
printVersion "go" "go version"
