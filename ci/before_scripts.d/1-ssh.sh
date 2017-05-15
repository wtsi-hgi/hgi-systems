if [[ -z "${SSH_PRIVATE_KEY}" ]]; then
    >&2 echo "SSH_PRIVATE_KEY secret variable unset or empty"
    exit 1
fi

# Run ssh-agent (inside the build environment)
eval $(ssh-agent -s)

# Add the SSH key stored in SSH_PRIVATE_KEY variable to the agent store
ssh-add <(echo "$SSH_PRIVATE_KEY")

# For Docker builds disable host key checking. Be aware that by adding that
# you are suspectible to man-in-the-middle attacks.
# WARNING: Use this only with the Docker executor, if you use it with shell
# you will overwrite your user's SSH config.
mkdir -p ~/.ssh
if [[ -f /.dockerenv ]]; then
    echo -e "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n" > ~/.ssh/config
fi

