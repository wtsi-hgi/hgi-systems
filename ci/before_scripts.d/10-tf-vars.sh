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

if [[ -n "${CONSUL_TEMPLATE_TOKEN:-}" ]]; then
    export TF_VAR_consul_template_token=${CONSUL_TEMPLATE_TOKEN}
else
    >&2 echo "CONSUL_TEMPLATE_TOKEN unset or empty"
fi

###############################################################################
# If you change these image_name values, terraform will DESTROY and RE-CREATE 
# all instances that use them! BE CAREFUL!
###############################################################################
export TF_VAR_base_image_name=hgi-base-xenial-d806d486
export TF_VAR_base_image_user=ubuntu

export TF_VAR_docker_image_name=hgi-docker-xenial-6912cc07
export TF_VAR_docker_image_user=ubuntu

export TF_VAR_freebsd_base_image_name=hgi-base-freebsd11-575611a5
export TF_VAR_freebsd_base_image_user=beastie

export TF_VAR_arvados_compute_node_image_name=hgi-arvados_compute-xenial-bb8f0dd7
export TF_VAR_arvados_compute_node_image_user=ubuntu

