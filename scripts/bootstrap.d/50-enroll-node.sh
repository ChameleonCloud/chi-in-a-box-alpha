echo "################################"
echo " Node enrollment"
echo "################################"
echo
echo "Looking for nodes in $NODE_CONF."
echo

nodes="$(crudini --get "$NODE_CONF")"

node_config() {
  local node="$1"
  local key="$2"
  crudini --get "$NODE_CONF" "$node" "$key"
}

create_node() {
  local node="$1"

  local ipmi_username="$(node_config "$node" "ipmi_username")"
  local ipmi_password="$(node_config "$node" "ipmi_password")"
  local ipmi_address="$(node_config "$node" "ipmi_address")"
  local ipmi_terminal_port="$(node_config "$node" "ipmi_terminal_port")"

  openstack baremetal node create -f value -c UUID \
    --name $node \
    --driver pxe_ipmitool_socat \
    --driver-info ipmi_username=$ipmi_username \
    --driver-info ipmi_password=$ipmi_password \
    --driver-info ipmi_address=$ipmi_address \
    --driver-info ipmi_terminal_port=$ipmi_terminal_port \
    --driver-info deploy_kernel=$DEPLOY_KERNEL \
    --driver-info deploy_ramdisk=$DEPLOY_RAMDISK \
    --network-interface neutron \
    --property capabilities="boot_option:local" \
    --property cpus=48 \
    --property cpu_arch=x86_64 \
    --property memory_mb=128000 \
    --property local_gb=200
}

create_node_port() {
  local node="$1"
  local node_uuid="$2"

  local mac_address = "$(node_config "$node" "mac_address")"

  openstack baremetal port create -f value -c UUID \
    --node "$node_uuid" \
    "$mac_address"
}

for node in $nodes; do
  echo "Enrolling node $node..."
  node_uuid="$(create_node "$node")"

  echo -e "\tPutting node in maintenance mode..."
  openstack baremetal node maintenance set "$node_uuid"

  echo -e "\tCreating network port..."
  port_uuid="$(create_node_port "$node" "$node_uuid")"

  echo -e "\tEnabling SOL console redirection..."
  openstack baremetal node console enable "$node_uuid"

  echo -e "\tBringing node out of maintenance mode..."
  openstack baremetal node maintenance unset "$node_uuid"
  openstack baremetal node provide

  echo -e "\tDone."
done
