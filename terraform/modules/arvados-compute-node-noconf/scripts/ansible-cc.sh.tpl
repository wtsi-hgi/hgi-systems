#!/bin/bash
###############################################################################
# Run ansible locally to complete node provisioning
###############################################################################
set -eufx -o pipefail

ansible_cc_tmp=$$(mktemp -d)
function log { >&2 echo "$$@"; }
log "Working in temp dir $${ansible_cc_tmp}"

# Process template expansions into local variables
IFS=',' read -r -a ansible_cc_groups <<< "${ANSIBLE_CC_GROUPS}"
ansible_cc_consul_datacenter="${ANSIBLE_CC_CONSUL_DATACENTER}"
ansible_cc_upstream_dns_servers="${ANSIBLE_CC_UPSTREAM_DNS_SERVERS}"
ansible_cc_playbook="${ANSIBLE_CC_PLAYBOOK}"
ansible_cc_docker_image="${ANSIBLE_CC_DOCKER_IMAGE}"

# Clone hgi-systems repo
git clone --depth=1 https://gitlab.internal.sanger.ac.uk/hgi/hgi-systems.git "$${ansible_cc_tmp}/hgi-systems"
ansible_cc_tmp_ansible="$${ansible_cc_tmp}/hgi-systems/ansible"

# Generate ansible inventory
cat <<EOF > "$${ansible_cc_tmp_ansible}/cc.inv"
[cc]
localhost cc_consul_datacenter="$${ansible_cc_consul_datacenter}" cc_upstream_dns_servers="$${ansible_cc_upstream_dns_servers}"

EOF

for group in $${ansible_cc_groups[@]}; do
cat <<EOF >> "$${ansible_cc_tmp_ansible}/cc.inv"
[$${group}:children]
cc

EOF
done

log "Generated ansible inventory:
$$(cat $${ansible_cc_tmp_ansible}/cc.inv)"

log "Running ansible-playbook $${ansible_cc_playbook} using container image $${ansible_cc_docker_image}"
docker run --net=host -v $${ansible_cc_tmp_ansible}:/cc $${ansible_cc_docker_image} ansible-playbook -i "/cc/cc.inv" -c local "/cc/$${ansible_cc_playbook}"

log "Removing temp dir $${ansible_cc_tmp}"
rm -rf "$${ansible_cc_tmp}"

