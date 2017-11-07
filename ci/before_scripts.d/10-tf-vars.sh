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

# FIXME THIS IS NASTY
# These are already all configured elsewhere
# DRY this out! 
# Also in tf these are all set to -latest so this is very confusing. 
export TF_VAR_base_image_name=hgi-base-xenial-d806d486
export TF_VAR_base_image_user=ubuntu

export TF_VAR_docker_image_name=hgi-docker-xenial-6912cc07
export TF_VAR_docker_image_user=ubuntu

export TF_VAR_arvados_base_image_name=hgi-base-jessie-d806d486 
export TF_VAR_arvados_base_image_user=debian

export TF_VAR_freebsd_base_image_name=hgi-base-freebsd11-8c9ace19
export TF_VAR_freebsd_base_image_user=beastie

