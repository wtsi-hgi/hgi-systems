if [[ -z "${ANSIBLE_CONSUL_TOKEN+x}" ]]; then
    >&2 echo "ANSIBLE_CONSUL_TOKEN must be set!"
    exit 1
fi

if [[ -z "${ANSIBLE_CONSUL_URL+x}" ]]; then
    >&2 echo "ANSIBLE_CONSUL_URL must be set!"
    exit 1
fi

