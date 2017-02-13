#!/bin/bash

set -euf -o pipefail

artifacts_dir="${CI_PROJECT_DIR}/artifacts/"
echo "Listing contents of artifacts directory ${artifacts_dir}"
artifacts=$(ls "${artifacts_dir}/"*)

echo "Copying ${artifacts} to terraform/${REGION}/"
cp ${artifacts} "terraform/${REGION}/"

echo "Emptying artifacts directory"
rm -rf "${artifacts_dir}" && mkdir -p "${artifacts_dir}"

echo "Copying ${ENV}.tfstate (from refresh job) into output artifacts"
cp "${ENV}.tfstate" "${artifacts_dir}/"

echo "Changing to terraform/${REGION} directory"
cd terraform/${REGION}

echo "Calling terraform plan"
terraform plan -state="${ENV}.tfstate" -input=false -out plan
terraform_exit_status=$?
echo "Copying plan to artifacts"
cp plan "${artifacts_dir}/"

if [[ ${terraform_exit_status} -eq 0 ]]; then
    echo "Terraform plan was successful, generating human-readable plan"
    terraform show -no-color plan > plan.txt
    cp plan.txt "${artifacts_dir}/"
    echo "Generating dot graph from plan"
    terraform graph plan > plan.dot
    cp plan.dot "${artifacts_dir}/"
    echo "Generating PNG from graph"
    dot -Tpng < plan.dot > plan.png
    cp plan.png "${artifacts_dir}/" 
else
    >&2 echo "Terraform plan failed: ${terraform_exit_status}"
    exit ${terraform_exit_status}
fi

