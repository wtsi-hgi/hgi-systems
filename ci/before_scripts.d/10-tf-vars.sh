if [[ -n "${ENV}" ]]; then
    export TF_VAR_env=${ENV}
else
    >&2 echo "ENV unset or empty"
fi

if [[ -n "${REGION}" ]]; then
    export TF_VAR_region=${REGION}
else
    >&2 echo "REGION unset or empty"
fi
