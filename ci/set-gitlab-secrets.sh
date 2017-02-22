#!/bin/bash

set -euf -o pipefail

project=$1

function set_variable() {
    key=$1
    value=$2

    curl --request POST --header "PRIVATE-TOKEN: ${GITLAB_API_PRIVATE_TOKEN}" "${GITLAB_API_ENDPOINT}/projects/${project}/variables" --form "key=${key}" --form "value=${value}" || curl --request PUT --header "PRIVATE-TOKEN: ${GITLAB_API_PRIVATE_TOKEN}" "${GITLAB_API_ENDPOINT}/projects/${project}/variables/${key}" --form "value=${value}"
}

set_variable "OS_AUTH_URL" "${OS_AUTH_URL}"
set_variable "OS_TENANT_NAME" "${OS_TENANT_NAME}"
set_variable "OS_USERNAME" "${OS_USERNAME}"
set_variable "OS_PASSWORD" "${OS_PASSWORD}"
