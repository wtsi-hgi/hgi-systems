#cloud-config

hostname: ${CLOUDINIT_HOSTNAME}
fqdn: ${CLOUDINIT_HOSTNAME}.${CLOUDINIT_DOMAIN}

#repo_update: true
#repo_upgrade: all

#packages:
#  - lvm2
  
#runcmd:
#  - [ systemctl, daemon-reload ]
#  - [ systemctl, enable, docker.service ]
#  - [ systemctl, start, --no-block, docker.service ]

output:
  all: '| tee -a /var/log/cloud-init-output.log'
