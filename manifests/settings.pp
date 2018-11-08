# User-defined settings

# IPv4 address on internal network
$internalip = ''

# IPv4 address on external network
$public_ip  = ''

# IP on provisioning network
$ironic_provisioning_ip = ''

# VLAN id for provisioning network
$ironic_provisioning_vlan = ''

$neutron_ngs_switches = {
  'genericswitch:switch1' => {
    'device_type' => 'netmiko_dell_force10',
    'ip'          => '',
    'username'    => '',
    'password'    => '',
  },
  'genericswitch:switch2' => {
    'device_type' => 'netmiko_dell_force10',
    'ip'          => '',
    'username'    => '',
    'password'    => '',
  }
}

# $email = '' # Email address for...
# $region = 'CIAB' # Region name
$physnet_interface  = ''


##################################################################
# NOTE: it should not be necessary to modify anything below here!
##################################################################

#
# Default settings
#

$controller = $internalip
$public_endpoint_url = $fqdn

$db_allowed_hosts = $internalip
$db_hammers_user = 'cc_hammers'
$db_readonly_user = 'readonly'
$db_server = $internalip
$instance_metrics_writer_username = 'instance_metrics_writer'
$keystone_admin_endpoint  = "https://${public_endpoint_url}:35357"
$keystone_public_endpoint = "https://${public_endpoint_url}:5000"
$memcache_servers = "${internalip}:11211"
$rabbit_user = 'openstack'
# $regions = [
#   {
#     'region_name' => $region,
#     'blazar_dbserver' => $db_server,
#     'blazar_dbpass' => $blazar_dbpass,
#     'site' => 'tacc_ciab'
#   }
# ]

#
# The following are generated via `gensettings`
#

$admin_password = ''
$admin_token = ''
$backup_password = ''
$blazar_dbpass = ''
$blazar_pass = ''
$ceilometer_dbpass = ''
$ceilometer_pass = ''
$cinder_dbpass = ''
$cinder_pass = ''
$db_hammers_pass = ''
$db_readonly_pass = ''
$glance_dbpass = ''
$glance_pass = ''
$gnocchi_dbpass = ''
$gnocchi_pass = ''
$heat_dbpass = ''
$heat_domain_admin_password = ''
$heat_pass = ''
$horizon_secret_key = ''
$instance_metrics_writer_password = ''
$ironic_dbpass = ''
$ironic_pass = ''
$keystone_dbpass = ''
$metadata_proxy_shared_secret = ''
$mysql_root = ''
$neutron_dbpass = ''
$neutron_pass = ''
$nova_dbpass = ''
$nova_pass = ''
$nova_placement_dbpass = ''
$nova_placement_pass = ''
$rabbit_password = ''
$swift_pass = ''
