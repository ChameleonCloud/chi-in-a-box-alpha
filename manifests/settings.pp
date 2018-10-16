$internalip = '10.20.111.250'
$public_ip  = '129.114.97.201'

$db_allowed_hosts = $internalip
$controller = $internalip

$db_server = $internalip
$public_endpoint_url = $fqdn
$keystone_public_endpoint = "https://$public_endpoint_url:5000"
$keystone_admin_endpoint  = "https://$public_endpoint_url:35357"
$memcache_servers = "${internalip}:11211"

$db_hammers_user = 'cc_hammers'
$db_hammers_pass =''
$admin_token =''
$mysql_root =''
$admin_password = ''
$keystone_dbpass =''
$glance_pass =''
$glance_dbpass =''
$nova_pass =''
$nova_dbpass =''
$nova_placement_pass =''
$nova_placement_dbpass =''
$neutron_pass =''
$neutron_dbpass =''
$metadata_proxy_shared_secret =''
$cinder_pass =''
$cinder_dbpass =''
$ironic_pass =''
$ironic_dbpass =''
$ceilometer_pass =''
$ceilometer_dbpass =''
$gnocchi_pass =''
$gnocchi_dbpass =''
$blazar_pass =''
$blazar_dbpass =''
$heat_pass =''
$heat_dbpass =''
$heat_domain_admin_password =''
$swift_pass =''
$rabbit_host = $controller
$rabbit_user = 'openstack'
$rabbit_password =''
$backup_password =''
$instance_metrics_writer_password =''
$db_readonly_pass =''
$db_readonly_user = 'readonly'

$email = 'user@host.com'
$region = 'RegionOne'

$mysql_override_options = undef
$hammers_dbpass = ''
$instance_metrics_writer_username = 'instance_metrics_writer'
$horizon_secret_key = ''
$regions            = [ { 'region_name' => $region, 'blazar_dbserver' => $db_server, 'blazar_dbpass' => $blazar_dbpass, site => 'tacc_ciab' } ]
$ironic_provisioning_vlan = '400'
$ironic_provisioning_ip = '10.20.30.254'
$physnet_interface  = 'p5p2'
$neutron_ngs_switches = {
            'genericswitch:switch1' => {
                'device_type' => 'netmiko_dell_force10',
                'ip'          => '1.2.3.4',
                'username'    => 'switch_user',
                'password'    => 'secret',
            },
            'genericswitch:switch2' => {
                'device_type' => 'netmiko_dell_force10',
                'ip'          => '1.2.3.5',
                'username'    => 'switch_user',
                'password'    => 'secret',
            }
    }

