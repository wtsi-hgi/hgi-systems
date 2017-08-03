# Ansible Run Environment
_A sharable Docker image in which anyone (with the required secrets) can run hgi-system's Ansible._
    
## Build
From this sub-directory:
```bash
docker build -t hgi-systems-ansible .
```

## Run
With `mercury`'s SSH key and the Ansible vault password:
```bash
docker run -it --rm \
    -v ~/checkouts/hgi-systems:/hgi-systems \
    -v ~/.ssh/:/ssh-key:ro \
    -v ~/secrets/:/vault-password:ro \
    -e VAULT_LOCATION=/vault-password/vault.pw \
    -e SSH_KEY_LOCATION=/ssh-key/id_rsa \
        hgi-systems-ansible
```
