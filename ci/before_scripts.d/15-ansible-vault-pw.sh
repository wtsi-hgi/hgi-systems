if [[ -n "${ANSIBLE_VAULT_PASSWORD:-}" ]]; then
    export ANSIBLE_VAULT_PASSWORD_FILE=$(mktemp)
    echo "${ANSIBLE_VAULT_PASSWORD}" > "${ANSIBLE_VAULT_PASSWORD_FILE}"
else
    >&2 echo "ERROR: ANSIBLE_VAULT_PASSWORD unset or empty"
    exit 1
fi
