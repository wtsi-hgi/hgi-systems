# Set REGION + SETUP specific OS_ vars for all regions and setups
export all_regions=(delta zeta)
export all_setups=(hgi-ci hgi-ci-core hgi hgi-core hgiarvados hgiarvados-core hgiarvados-wlly8 hgiarvados-wlly8-core hgi-dev)
for region in "${all_regions[@]}"; do
    region_uppercase_safe=$(echo "${region}" | tr '[:lower:][:punct:]' '[:upper:]_')
    for setup in "${all_setups[@]}"; do
	case $setup in
	    hgi-ci|hgi-ci-*)
		project=hgi-ci
		;;
	    hgi-dev|hgi-dev-*)
		project=hgi-dev
		;;
	    hgi|hgi-*)
		project=hgi
		;;
	    hgiarvados|hgiarvados-*)
		project=hgiarvados
		;;
	    *)
		>&2 echo "SETUP '${setup}' not recognized in 5-region-setup-specific-os-vars.sh, not setting tenant/project vars"
		>&2 echo "Refusing to continue without recognized SETUP"
		exit 1
		;;
	esac
	setup_uppercase_safe=$(echo "${setup}" | tr '[:lower:][:punct:]' '[:upper:]_')
	export ${region_uppercase_safe}_${setup_uppercase_safe}_OS_PROJECT_NAME="${project}"
	export ${region_uppercase_safe}_${setup_uppercase_safe}_OS_PROJECT_DOMAIN_NAME="Default"
	export ${region_uppercase_safe}_${setup_uppercase_safe}_OS_USER_DOMAIN_NAME="Default"
	export ${region_uppercase_safe}_${setup_uppercase_safe}_OS_TENANT_NAME="${project}"
	>&2 echo "${region_uppercase_safe}_${setup_uppercase_safe}_OS_ vars set for ${region} ${setup} (OS tenant/project ${project})"
    done
done
