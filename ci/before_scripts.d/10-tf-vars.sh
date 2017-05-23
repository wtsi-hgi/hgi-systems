if [[ -n "${ENV:-}" ]]; then
    export TF_VAR_env=${ENV}
else
    >&2 echo "ENV unset or empty"
fi

if [[ -n "${REGION:-}" ]]; then
    export TF_VAR_region=${REGION}
else
    >&2 echo "REGION unset or empty"
fi

export TF_VAR_base_image_name=hgi-base-xenial-d806d486
export TF_VAR_base_image_user=ubuntu

export TF_VAR_docker_image_name=hgi-docker-xenial-6912cc07
export TF_VAR_docker_image_user=ubuntu

export TF_VAR_arvados_base_image_name=hgi-base-jessie-d806d486 
export TF_VAR_arvados_base_image_user=debian

