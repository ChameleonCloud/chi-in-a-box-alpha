echo "################################"
echo " Configuration pre-check"
echo "################################"
echo

ironic_enabled_network_interfaces() {
  crudini --get /etc/ironic/ironic.conf DEFAULT enabled_network_interfaces
}

if [[ "$(ironic_enabled_network_interfaces)" != "flat,neutron" ]]; then
  echo "The ironic 'enabled_network_interfaces' had an unexpected value"
  echo "or could not be retrieved. Supported value is: 'flat,neutron'"
  exit 1
else
  echo "All checks passed."
  echo
fi
