if [[ -z "${TERRAFORM_CONSUL_TOKEN+x}" ]]; then
    >&2 echo "TERRAFORM_CONSUL_TOKEN must be set!"
    exit 1
fi

# FIXME: it is not possible for jobs to use different tokens with this scheme - `CONSUL_HTTP_TOKEN` should be defined in
# the job's environment
export CONSUL_HTTP_TOKEN=${TERRAFORM_CONSUL_TOKEN}
