## About
The purpose of the `start.sh` script is to get the developer into an environment where they are able to develop
HGI systems. It works by gathering the secrets required to access HGI systems from GitLab and putting them into an
environment with the user's development setup. The `hgi-systems` repository is mounted in the Docker container so that
it can be worked on in the container or on the host machine.

It offers the advantages that developers:
- Do not have to spend time setting up the correct environment.
- Can develop on any machine, including their own.
- Only need to know their own GitLab token - no other secrets are permanently stored on the user's machine.


### Tools
- Ansible
- Terraform
- s3cmd
- git
- ssh (for access to HGI systems)


## Prerequisites
- git
- docker (for HGI members: use hgs4 or OpenStack instance)
- [docker-with-gitlab-secrets](https://github.com/wtsi-hgi/docker-with-gitlab-secrets) (for HGI members on network
machines use `module add module add hgi/dockerwithgitlabsecrets/latest` else `pip install dockerwithgitlabsecrets`)
- docker-with-gitlab-secrets configuration for [hgi-systems](https://github.com/wtsi-hgi/hgi-systems), e.g.
  ```
  gitlab:
    url: https://gitlab.internal.sanger.ac.uk
    token: my-gitlab-token
    project: hgi-systems
    namespace: hgi
  ```
  (For HGI members: [get your GitLab CI token here](https://gitlab.internal.sanger.ac.uk/profile/personal_access_tokens)).
 

## Usage
```bash
$ ./start.sh -h
Usage: start.sh [options]

Start hgi-systems development container

options:
-c      docker-with-gitlab-secrets configuration file location [default: /Users/cn13/.dwgs-config.yml]
-d      docker-with-gitlab-secrets executable location [default: docker-with-gitlab-secrets (on path)]
-n      Set to not pull latest taos-dev Docker image on start [default: 0]
```

### Example
```bash
$ ./start.sh
Updating taos-dev docker image...
New line characters in variable with key "SSH_PRIVATE_KEY" have been escaped to \\n
Updating apt cache in the background
Setting up copy of the host user
Change to user cn13
Setting SSH key
Setting Ansible Vault password
Setting OpenStack environment variables
Setting Terraform environment variables
Setup Git
Setting up s3cmd
Starting shell...
```

## Notes
- The container user (a copy of the host user) has password-less `sudo` access.
- `ssh-agent` is running with access to both the host user's key and the key used to access HGI systems machines.
