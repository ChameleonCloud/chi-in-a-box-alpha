################
# User settings
################

$email = ''

# Whether to instruct Puppet to manage the network interfaces.
# If true, Puppet will create network scripts for each of the 3 interfaces
# defined below (internal, external, out-of-band.)
$manage_interfaces = true

# IPv4 address on internal network
$private_ip = ''
# Internal interface details; only used when `manage_interfaces` is true
$private_interface = 'eno1'
$private_subnet = ''

# IPv4 address on external network
$public_ip  = ''
# External interface details; only used when `manage_interfaces` is true
$public_interface = 'eno2'
$public_subnet = ''

# IPv4 address on out-of-band network
$oob_ip = ''
# Out-of-band interface details; only used when `manage_interfaces` is true
$oob_interface = 'eno3'
$oob_subnet = ''

# VLAN id for provisioning network
$ironic_provisioning_vlan = '400'
# VLAN range for all neutron networks - must include provisioning VLAN
$tenant_network_vlan_range = "${ironic_provisioning_vlan}:410"
# IPv4 CIDR for subnet that will be used for public IP allocation
$tenant_network_public_ip_subnet = ''

# DNS servers to use for default DNS resolution on all nodes and Neutron subnets.
# You must define 2 or some Puppet recipes will not evaluate.
# (Defaults to Google DNS)
$dns_servers = ['8.8.8.8', '8.8.4.4']

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

$region = 'CIAB' # Region name

# SSL certificate loading
#
# Whether to user LetsEncrypt certificates - if true, certificates will be
# automatically loaded from the default certbot directory of /etc/letsencrypt/live/${fqdn}
$ssl_letsencrypt = false

# Note: if you are providing your own certificates, they are expected to be in
# /root at the following locations:
#   - Certificate: "${fqdn}.cer"
#   - Private key: "${fqdn}.key"
#   - Intermediate certificate: "${fqdn}-interm.cer"

##################################################################
# NOTE: it should not be necessary to modify anything below here!
##################################################################

#
# Default settings
#

$controller = $private_ip
$public_endpoint_url = $fqdn

$db_allowed_hosts = $controller
$db_hammers_user = 'cc_hammers'
$db_readonly_user = 'readonly'
$db_server = $controller
$instance_metrics_writer_username = 'instance_metrics_writer'
$keystone_admin_endpoint  = "https://${public_endpoint_url}:35357"
$keystone_public_endpoint = "https://${public_endpoint_url}:5000"
$memcache_servers = "${controller}:11211"
$rabbit_user = 'openstack'

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

$regions = [
  {
    'region_name' => $region,
    'blazar_dbserver' => $db_server,
    'blazar_dbpass' => $blazar_dbpass,
    'site' => $fqdn
  }
]
