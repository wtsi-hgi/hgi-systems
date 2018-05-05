# Set REGION + SETUP specific OS_ vars for all regions and setups
export all_regions=(delta zeta)
export all_setups=(hgi-ci hgi-ci-core hgi hgi-core hgiarvados hgiarvados-core hgi-dev)
for region in "${all_regions[@]}"; do
    region_uppercase_safe=$(echo "${region}" | tr '[:lower:][:punct:]' '[:upper:]_')
    for setup in "${all_setups[@]}"; do
	setup_uppercase_safe=$(echo "${setup}" | tr '[:lower:][:punct:]' '[:upper:]_')
	export ${region_uppercase_safe}_${setup_uppercase_safe}_OS_PROJECT_NAME="${setup}"
	export ${region_uppercase_safe}_${setup_uppercase_safe}_OS_PROJECT_DOMAIN_NAME="Default"
	export ${region_uppercase_safe}_${setup_uppercase_safe}_OS_USER_DOMAIN_NAME="Default"
	export ${region_uppercase_safe}_${setup_uppercase_safe}_OS_TENANT_NAME="${setup}"
	>&2 echo "${region_uppercase_safe}_${setup_uppercase_safe}_OS_ vars set for ${region} ${setup}"
    done
done
