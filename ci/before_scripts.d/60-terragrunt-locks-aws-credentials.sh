
set -euf -o pipefail

# TODO could limit this to terraform jobs

if [[ -n "${TERRAGRUNT_LOCKS_AWS_ACCESS_KEY_ID}" ]]; then
    export AWS_ACCESS_KEY_ID=${TERRAGRUNT_LOCKS_AWS_ACCESS_KEY_ID}
else
    >&2 echo "TERRAGRUNT_LOCKS_AWS_ACCESS_KEY_ID was unset or empty"
    exit 1
fi

if [[ -n "${TERRAGRUNT_LOCKS_AWS_SECRET_KEY_ID}" ]]; then
    export AWS_SECRET_KEY_ID=${TERRAGRUNT_LOCKS_AWS_SECRET_KEY_ID}
else
    >&2 echo "TERRAGRUNT_LOCKS_AWS_SECRET_KEY_ID was unset or empty"
    exit 1
fi

