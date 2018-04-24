REGION=${REGION:-}
# TODO: Reduce code duplication here
if [[ -z "$REGION" ]]; then
    echo "REGION unset or empty"
elif [[ "$REGION" == "delta-hgi" ]]; then
    export OS_USERNAME=${DELTA_OS_USERNAME}
    export OS_PASSWORD=${DELTA_OS_PASSWORD}
    export OS_AUTH_URL=${DELTA_OS_AUTH_URL}
    export OS_TENANT_NAME="hgi"
    echo "OS vars for delta-hgi set"
elif [[ "$REGION" == "delta-hgiarvados" ]]; then
    export OS_USERNAME=${DELTA_OS_USERNAME}
    export OS_PASSWORD=${DELTA_OS_PASSWORD}
    export OS_AUTH_URL=${DELTA_OS_AUTH_URL}
    export OS_TENANT_NAME="hgiarvados"
    echo "OS vars for delta-hgiarvados set"
elif [[ "$REGION" == "zeta-hgi" ]]; then
    export OS_USERNAME=${ZETA_OS_USERNAME}
    export OS_PASSWORD=${ZETA_OS_PASSWORD}
    export OS_AUTH_URL=${ZETA_OS_AUTH_URL}/v3
    export OS_PROJECT_NAME="hgi"
    export OS_USER_DOMAIN_NAME="Default"
    echo "OS vars for zeta-hgi set"
elif [[ "$REGION" == "zeta-hgiarvados" ]]; then
    export OS_USERNAME=${ZETA_OS_USERNAME}
    export OS_PASSWORD=${ZETA_OS_PASSWORD}
    export OS_AUTH_URL=${ZETA_OS_AUTH_URL}/v3
    export OS_PROJECT_NAME="hgiarvados"
    export OS_USER_DOMAIN_NAME="Default"
    echo "OS vars for zeta-hgiarvados set"
elif [[ "$REGION" == "delta-hgi-dev" ]]; then
    export OS_USERNAME=${DELTA_OS_USERNAME}
    export OS_PASSWORD=${DELTA_OS_PASSWORD}
    export OS_AUTH_URL=${DELTA_OS_AUTH_URL}
    export OS_TENANT_NAME="hgi-dev"
    echo "OS vars for delta-hgi-dev set"
elif [[ "$REGION" == "emedlab-arvados" ]]; then 
    export OS_USERNAME=${EMEDLAB_OS_USERNAME}
    export OS_PASSWORD=${EMEDLAB_OS_PASSWORD}
    export OS_AUTH_URL=${EMEDLAB_OS_AUTH_URL}
    export OS_TENANT_NAME="arvados"
    export HTTP_PROXY=${EMEDLAB_HTTP_PROXY}
    export HTTPS_PROXY=${EMEDLAB_HTTP_PROXY}
    echo "OS vars for emedlab-arvados set"
else
    >&2 echo "REGION ${REGION} not recognized in 20-os-vars.sh, not setting OS_ vars"
fi
