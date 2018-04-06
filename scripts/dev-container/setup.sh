#!/usr/bin/env bash
set -eu -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

>&2 echo "Updating apt cache in the background"
nohup apt update  > /dev/null 2>&1 &

>&2 echo "Setting up user"
groupadd --gid "${HOST_USER_GROUP_ID}" "${HOST_USER_GROUP_NAME}"
useradd -G sudo -s /bin/bash -m --uid "${HOST_USER_ID}" --gid "${HOST_USER_GROUP_ID}" "${HOST_USER_NAME}"
sed -i 's/\%sudo\tALL=(ALL:ALL) ALL$/\%sudo\tALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers

>&2 echo "Change user"
HOME="/home/${HOST_USER_NAME}" su -p -l "${HOST_USER_NAME}" -s "${SCRIPT_DIRECTORY}/user-setup.sh"
