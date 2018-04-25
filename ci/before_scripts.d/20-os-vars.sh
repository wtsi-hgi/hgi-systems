REGION=${REGION:-}

if [[ -z "$REGION" ]]; then
    echo "REGION unset or empty"
fi

case $REGION in
    delta)
	export OS_USERNAME=${DELTA_OS_USERNAME}
	export OS_PASSWORD=${DELTA_OS_PASSWORD}
	export OS_AUTH_URL=${DELTA_OS_AUTH_URL}
	>&2 echo "OS credentials for delta set"
	;;
    zeta)
	export OS_USERNAME=${ZETA_OS_USERNAME}
	export OS_PASSWORD=${ZETA_OS_PASSWORD}
	export OS_AUTH_URL=${ZETA_OS_AUTH_URL}
	;;
    *)
	>&2 echo "REGION ${REGION} not recognized in 20-os-vars.sh, not setting OS_ vars"
	>&2 echo "refusing to continue without recognized REGION"
	exit 1
	;;
esac

function export_tenant_or_project {
    tenant_or_project=$1
    if [[ "${CI_JOB_STAGE}" == "terraform" ]]; then
	export OS_PROJECT_NAME="${tenant_or_project}"
	export OS_USER_DOMAIN_NAME="Default"
	>&2 echo "OS_PROJECT_NAME set to ${tenant_or_project} (using v3+ auth)"
    else
	export OS_TENANT_NAME="${tenant_or_project}"
	>&2 echo "OS_TENANT_NAME set to ${tenant_or_project} (using v2 auth)"
    fi
}

case $SETUP in
    hgi-ci|hgi-ci-*)
	export_tenant_or_project hgi-ci
	;;
    hgi-dev|hgi-dev-*)
	export_tenant_or_project hgi-dev
	;;
    hgi|hgi-*)
	export_tenant_or_project hgi
	;;
    hgiarvados|hgiarvados-*)
	export_tenant_or_project hgiarvados
	;;
esac
