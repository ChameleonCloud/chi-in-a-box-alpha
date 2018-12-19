#!/usr/bin/env bash
set -e -u -o pipefail

node_conf="$(realpath $1)"

log() {
  echo "$@" >&2
}

node_config() {
  local node="$1"
  local key="$2"
  local default="${3:-}"
  crudini --get "$node_conf" "$node" "$key" \
    || (test -n "$default" && echo "$default")
}

update_node() {
  local node="$1"

  local ipmi_username="$(node_config "$node" "ipmi_username")"
  local ipmi_password="$(node_config "$node" "ipmi_password")"
  local ipmi_address="$(node_config "$node" "ipmi_address")"
  local ipmi_port="$(node_config "$node" "ipmi_port" 623)"
  local ipmi_terminal_port="$(node_config "$node" "ipmi_terminal_port")"

  declare -a cmd_args=()
  cmd_args+=(--name "$node")
  cmd_args+=(--driver pxe_ipmitool_socat)
  cmd_args+=(--driver-info "ipmi_username=$ipmi_username")
  cmd_args+=(--driver-info "ipmi_password=$ipmi_password")
  cmd_args+=(--driver-info "ipmi_address=$ipmi_address")
  cmd_args+=(--driver-info "ipmi_port=$ipmi_port")
  cmd_args+=(--driver-info "ipmi_terminal_port=$ipmi_terminal_port")
  cmd_args+=(--driver-info "deploy_kernel=$DEPLOY_KERNEL")
  cmd_args+=(--driver-info "deploy_ramdisk=$DEPLOY_RAMDISK")
  cmd_args+=(--network-interface neutron)
  cmd_args+=(--property capabilities="boot_option:local")
  cmd_args+=(--property cpus=48)
  cmd_args+=(--property cpu_arch=x86_64)
  cmd_args+=(--property memory_mb=128000)
  cmd_args+=(--property local_gb=200)

  node_uuid="$(openstack baremetal node show "$node" -f value -c uuid)" \
    && (openstack baremetal node set "$node_uuid" "${cmd_args[@]}" >/dev/null && echo "$node_uuid") \
    ||  openstack baremetal node create -f value -c uuid "${cmd_args[@]}"
}

create_node_port() {
  local node="$1"
  local node_uuid="$2"

  local mac_address="$(node_config "$node" "mac_address")"
  local switch_name="$(node_config "$node" "switch_name")"
  local switch_port_id="$(node_config "$node" "switch_port_id")"

  # This command will exit 0 even if there is no port found, need to check
  # actual output returned.
  port_uuid="$(openstack baremetal port list --node "$node_uuid" -f value -c UUID)"

  # The create command does not properly return the UUID value, need to
  # create and then re-check.
  test -n "$port_uuid" && echo "$port_uuid" \
    || (openstack baremetal port create \
        --node "$node_uuid" \
        --local-link-connection switch_info="$switch_name" \
        --local-link-connection switch_id="00:00:00:00:00:00" \
        --local-link-connection port_id="$switch_port_id" \
        "$mac_address" >/dev/null \
        && openstack baremetal port list --node "$node_uuid" -f value -c UUID)
}

create_blazar_host() {
  local node="$1"
  local node_uuid="$2"

  local node_type="$(node_config "$node" "node_type" "default")"

  blazar host-show "$node_uuid" \
    || blazar host-create \
        --extra "node_type=$node_type" \
        --extra "uid=$node_uuid" \
        "$node_uuid" >/dev/null
}

log "################################"
log " CHI-in-a-Box node enrollment"
log "################################"
log
log "Looking for nodes in $node_conf."
log

nodes="$(crudini --get "$node_conf")"

export OS_BAREMETAL_API_VERSION=1.29

for node in $nodes; do
  log "Enrolling node $node..."
  node_uuid="$(update_node "$node")"

  log -e "\tPutting node in maintenance mode..."
  openstack baremetal node maintenance set "$node_uuid"

  log -e "\tCreating network port..."
  port_uuid="$(create_node_port "$node" "$node_uuid")"

  log -e "\tEnabling SOL console redirection..."
  openstack baremetal node console enable "$node_uuid"

  log -e "\tBringing node out of maintenance mode..."
  openstack baremetal node maintenance unset "$node_uuid"
  openstack baremetal node manage "$node_uuid"
  openstack baremetal node provide "$node_uuid"

  log -e "\tMaking node reservable..."
  create_blazar_host "$node" "$node_uuid"

  log -e "\tDone."
done

log "Done."
log
