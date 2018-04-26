#!/usr/bin/env bash
set -eu -o pipefail

>&2 echo "Removing old Terraform working directories"
rm -rf /mnt/host/hgi-systems/terraform/delta-hgi/.terraform
rm -rf /mnt/host/hgi-systems/terraform/delta-hgiarvados/.terraform

>&2 echo "Setting Ansible Vault password"
echo "${ANSIBLE_VAULT_PASSWORD}" > ~/.ansible-vault.pw
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible-vault.pw

>&2 echo "Setting OpenStack environment variables"
export OS_PASSWORD="${DELTA_OS_PASSWORD}"
export OS_USERNAME="${DELTA_OS_USERNAME}"
export OS_AUTH_URL="${DELTA_OS_AUTH_URL}"

>&2 echo "Setting GitLab specific variables"
export CI_PROJECT_DIR=/mnt/host/hgi-systems/

>&2 echo "Setup Git"
# Note: copying the below files so that they can be changed
cp /mnt/host/.gitconfig ~/.gitconfig
cp /mnt/host/.gitignore_global ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global

>&2 echo "Setting SSH keys"
mkdir -p ~/.ssh
echo "${SSH_PRIVATE_KEY}" | sed 's/\\n/\n/g' > ~/.ssh/10-ci.key
ln -s /mnt/host/id_rsa ~/.ssh/0-${HOST_USER_NAME}.key
chmod -R 700 ~/.ssh
eval $(ssh-agent) > /dev/null 2>&1
ssh-add ~/.ssh/*.key > /dev/null 2>&1

>&2 echo "Sourcing before scripts"
. /mnt/host/hgi-systems/ci/source-before-scripts.sh /mnt/host/hgi-systems/ci/before_scripts.d 2>&1 | sed 's/^/    /g'

>&2 echo "Starting shell..."
bash
