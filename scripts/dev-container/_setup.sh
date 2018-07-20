#!/usr/bin/env bash
set -eu -o pipefail

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

>&2 echo "Updating apt cache in the background"
nohup apt update  > /dev/null 2>&1 &

>&2 echo "Setting up copy of the host user"
groupadd --gid "${HOST_USER_GROUP_ID}" "${HOST_USER_GROUP_NAME}"
useradd -G sudo -s /bin/bash -m --uid "${HOST_USER_ID}" --gid "${HOST_USER_GROUP_ID}" "${HOST_USER_NAME}"
sed -i 's/\%sudo\tALL=(ALL:ALL) ALL$/\%sudo\tALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers

>&2 echo "Install help"
cp /mnt/host/help.sh /usr/local/bin/dev-help
cp /mnt/host/help.sh /usr/local/bin/heeeelllppp
chmod 775 /usr/local/bin/dev-help /usr/local/bin/heeeelllppp

>&2 echo "Change to user ${HOST_USER_NAME} and setup user environment"
cp "${SCRIPT_DIRECTORY}/_user-setup.sh" "/home/${HOST_USER_NAME}/.bash_profile"
HOME="/home/${HOST_USER_NAME}" su -p -l "${HOST_USER_NAME}"
