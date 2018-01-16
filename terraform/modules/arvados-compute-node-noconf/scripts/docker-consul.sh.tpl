#!/bin/bash
###############################################################################
# Create configuration file and systemd unit for dockerized consul
###############################################################################
set -eufx -o pipefail

consul_tmp=$(mktemp -d)
function log { >&2 echo "$$@"; }
log "Working in temp dir $${consul_tmp}"

# Process template expansions into local variables
IFS=',' read -r -a consul_retry_join <<< "${CONSUL_RETRY_JOIN}"
IFS=',' read -r -a consul_recursors <<< "${CONSUL_RECURSORS}"
consul_advertise_addr="${CONSUL_ADVERTISE_ADDR}"
consul_datacenter="${CONSUL_DATACENTER}"
consul_acl_token="${CONSUL_ACL_TOKEN}"
consul_encrypt="${CONSUL_ENCRYPT}"
consul_bind_addr="${CONSUL_BIND_ADDR}"

# Generate json from input variables
function join_by { local IFS="$$1"; shift; echo "$$*"; }
function quote_values { for i in "$$@"; do echo '"'"$$i"'"'; done }
function json_array { echo "["; echo "$$(join_by , $$(quote_values $$@))"; echo "]"; }
retry_join_json=$$(json_array "$${consul_retry_join[@]}")
recursors_json=$$(json_array "$${consul_recursors[@]}")
advertise_addr_json=$$(quote_values "$${consul_advertise_addr}")
datacenter_json=$$(quote_values "$${consul_datacenter}")
acl_token_json=$$(quote_values "$${consul_acl_token}")
encrypt_json=$$(quote_values "$${consul_encrypt}")

# Generate consul local config JSON
cat <<EOF > "$${consul_tmp}/consul_local_config.json"
{
  "leave_on_terminate": true, 
  "retry_join": $${retry_join_json},
  "recursors": $${recursors_json},
  "advertise_addr": $${advertise_addr_json},
  "datacenter": $${datacenter_json},
  "encrypt": $${encrypt_json},
  "acl_datacenter": $${datacenter_json},
  "acl_token": $${acl_token_json}
}
EOF

# Generate consul-agent systemd unit
cat <<EOF > "$${consul_tmp}/consul-agent.service"
[Unit]
Description=Dockerized Consul Agent
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill consul-agent
ExecStartPre=-/usr/bin/docker rm consul-agent
ExecStartPre=/usr/bin/docker pull consul
ExecStart=/bin/bash -c '/usr/bin/docker run --name consul-agent --net=host -e CONSUL_LOCAL_CONFIG="\$$(cat /etc/consul_local_config.json)" consul agent -bind=$${consul_bind_addr} -client=0.0.0.0'

[Install]
WantedBy=multi-user.target
EOF

#ExecStart=/usr/bin/docker run --name consul-agent --net=host -e 'CONSUL_ALLOW_PRIVILEGED_PORTS=' -e 'CONSUL_LOCAL_CONFIG='"$$(cat /etc/consul_local_config.json)" consul agent -dns-port=53 -bind=$${consul_bind_addr} -client=0.0.0.0"

# Generate consul alias
echo "alias consul='docker run --net=host consul'" > "$${consul_tmp}/consul-alias.sh"

function install_file_if_changed {
  source_dir=$$1
  dest_dir=$$2
  file_name=$$3
  log "Checking if $${file_name} has changed"
  different=$$(diff -q "$${source_dir}/$${file_name}" "$${dest_dir}/$${file_name}" && echo -n "same" || echo -n "different")
  if [ $${different} = "different" ]; then
    log "Config file has changed, moving temporary file into place"
    mv "$${source_dir}/$${file_name}" "$${dest_dir}/$${file_name}"
    echo -n "changed"
  fi
  echo -n ""
}

changed_local_config=$$(install_file_if_changed "$${consul_tmp}" /etc consul_local_config.json)
changed_service=$$(install_file_if_changed "$${consul_tmp}" /etc/systemd/system consul-agent.service)
changed_profile=$$(install_file_if_changed "$${consul_tmp}" /etc/profile.d consul-alias.sh)

log "Removing temp dir $${consul_tmp}"
rm -rf "$${consul_tmp}"

if [ -n "$${changed_service}" ]; then
    log "consul-agent service unit changed, reloading systemd daemon"
    systemctl daemon-reload
fi

if [ -n "$${changed_local_config}" ]; then
    log "consul-agent configuration changed, restarting consul-agent service"
    systemctl restart consul-agent
fi

