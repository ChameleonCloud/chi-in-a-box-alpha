log "################################"
log " Configuration pre-check"
log "################################"
log

ironic_enabled_network_interfaces() {
  crudini --get /etc/ironic/ironic.conf DEFAULT enabled_network_interfaces
}

if [[ "$(ironic_enabled_network_interfaces)" != "flat,neutron" ]]; then
  log "The ironic 'enabled_network_interfaces' had an unexpected value"
  log "or could not be retrieved. Supported value is: 'flat,neutron'"
  exit 1
else
  log "All checks passed."
  log
fi
