set -eu -o pipefail

>&2 echo "Removing old Terraform working directories"
rm -rf /mnt/host/hgi-systems/terraform/zeta-hgi/.terraform
rm -rf /mnt/host/hgi-systems/terraform/zeta-hgiarvados/.terraform

>&2 echo "Setting Ansible Vault password"
echo "${ANSIBLE_VAULT_PASSWORD}" > ~/.ansible-vault.pw
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible-vault.pw

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
. /mnt/host/hgi-systems/ci/source-before-scripts.sh /mnt/host/hgi-systems/ci/before_scripts.d 2> >(sed 's/^/  E:/g') > >(sed 's/^/  O:/g') # DO NOT USE A PIPELINE HERE OR THE VARS WILL BE SET IN SUBSHELL AND NOT PERSIST

# Note: This must go after source scripts because 3-ssh.sh writes to `config` to turn off key checking
>&2 echo "Adding SSH config"
rm ~/.ssh/config
ln -s /mnt/host/ssh-config ~/.ssh/config

dev-help

# set bash options for interactive use
set +euf +o pipefail
>&2 echo "Startup complete (use 'dev-help' for help)..."
