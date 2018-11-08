node default {
    # SSL
    $ssl_path_base          = '/etc/pki/tls'
    $ssl_cert_base          = "${fqdn}.cer"
    $ssl_key_base           = "${fqdn}.key"
    $ssl_ca_base            = "${fqdn}-interm.cer"
    $ssl_cert               = "${ssl_path_base}/certs/${ssl_cert_base}"
    $ssl_key                = "${ssl_path_base}/private/${ssl_key_base}"
    $ssl_ca                 = "${ssl_path_base}/certs/${ssl_ca_base}"

    file { $ssl_cert:
        ensure => present,
        source => "file:///root/${ssl_cert_base}",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    file { $ssl_key:
        ensure => present,
        source => "file:///root/${ssl_key_base}",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    file { $ssl_ca:
        ensure => present,
        source => "file:///root/${ssl_ca_base}",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    class { 'ca_cert':
        install_package => true
    }

    ca_cert::ca { 'InCommonRSA-Intermediate':
        ensure => 'trusted',
        source => "file://${ssl_ca}",
    }

    if $manage_interfaces {
        # Internal interface (OpenStack services)
        network::interface { $private_interface:
            enable    => true,
            ipaddress => $private_ip,
            netmask   => cidr_to_ipv4_netmask($private_subnet),
            gateway   => cidr_to_ipv4_gateway($private_subnet),
            mtu       => '1500',
            hotplug   => 'yes',
        }

        # Public Interface (API / Horizon)
        network::interface { $public_interface:
            enable    => true,
            ipaddress => $public_ip,
            netmask   => cidr_to_ipv4_netmask($public_subnet),
            gateway   => cidr_to_ipv4_gateway($public_subnet),
            mtu       => '1500',
            defroute  => 'yes',
            peerdns   => 'yes',
            dns1      => $dns_servers[0],
            dns2      => $dns_servers[1],
        }

        # Out of Band
        network::interface { $oob_interface:
            enable    => true,
            ipaddress => $oob_ip,
            netmask   => cidr_to_ipv4_netmask($oob_subnet),
            mtu       => '1500',
        }
    }

    # Create admin adminrc in /root
    class { 'openstack_extras::auth_file':
        path        => '/root/adminrc',
        password    => $admin_password,
        region_name => $region,
        auth_url    => $keystone_public_endpoint,
        # project_name => $admin_project_name,
        # tenant_name  => $admin_tenant_name,
    }

    class { 'memcached':
        listen_ip  => $controller,
        max_memory => '10%',
    }

    class { 'chameleoncloud': }
    class { 'chameleoncloud::rabbitmq':
        rabbit_user     => $rabbit_user,
        rabbit_password => $rabbit_password,
    }

    class { 'chameleoncloud::db':
        backup_password            => $backup_password,
        server_id                  => '1',
        blazar_extra_allowed_hosts => undef,
        gnocchi_allowed_hosts      => undef,
        db_hammers_user            => $db_hammers_user,
        db_hammers_pass            => $db_hammers_pass,
        db_readonly_user           => $db_readonly_user,
        db_readonly_pass           => $db_readonly_pass,
        mysql_root                 => $mysql_root,
        keystone_dbpass            => $keystone_dbpass,
        neutron_dbpass             => $neutron_dbpass,
        ironic_dbpass              => $ironic_dbpass,
        db_allowed_hosts           => $controller,
    }

    #
    # Keystone
    #

    class { 'chameleoncloud::keystone':
        admin_token                      => $admin_token,
        admin_password                   => $admin_password,
        keystone_dbpass                  => $keystone_dbpass,
        keystone_auth_email              => $email,
        keystone_host                    => $controller,
        public_endpoint                  => $keystone_public_endpoint,
        admin_endpoint                   => $keystone_admin_endpoint,
        instance_metrics_writer_username => $instance_metrics_writer_username,
        instance_metrics_writer_password => $instance_metrics_writer_password,
    }

    #
    # Horizon
    #

    class { 'chameleoncloud::horizon':
        theme_base_dir     => '/opt/theme',
        theme_name         => 'chameleon',
        help_url           => 'https://www.chameleoncloud.org/docs/bare-metal-user-guide/',
        horizon_secret_key => $horizon_secret_key,
        keystone_auth_uri  => $keystone_public_endpoint,
        memcache_server_ip => $controller,
        # portal_api_base_url => 'https://www.chameleoncloud.org',
    }

    #
    # Blazar
    #

    class { 'chameleoncloud::blazar':
        blazar_host                   => $controller,
        blazar_pass                   => $blazar_pass,
        blazar_dbpass                 => $blazar_dbpass,
        keystone_auth_uri             => $keystone_public_endpoint,
        keystone_auth_url             => $keystone_admin_endpoint,
        public_endpoint_url           => $public_endpoint_url,
        notify_hours_before_lease_end => '0',
        default_max_lease_duration    => '604800',
        project_max_lease_durations   => 'Chameleon:-1,admin:-1,openstack:-1,maintenance:-1',
        # usage_enforcement             => 'True',
        # usage_db_host                 => 'chi.uc.chameleoncloud.org',
        usage_db_host                 => '',
        usage_default_allocated       => '20000.0',
        # email_relay                   => 'relay.tacc.utexas.edu',
        require                       => Class['chameleoncloud::horizon']
    }
    chameleoncloud::service_proxy { 'blazar_public':
        public_ip  => $public_ip,
        service_ip => $controller,
        port       => '1234',
    }

    #
    # Glance
    #

    class { 'chameleoncloud::glance':
        glance_host         => $controller,
        glance_pass         => $glance_pass,
        glance_dbpass       => $glance_dbpass,
        public_endpoint_url => $public_endpoint_url,
        keystone_auth_uri   => $keystone_public_endpoint,
        keystone_auth_url   => $keystone_admin_endpoint,
    }
    chameleoncloud::service_proxy { 'glance_public':
        public_ip  => $public_ip,
        service_ip => $controller,
        port       => '9292',
    }

    #
    # Neutron
    #

    $tenant_network_public_ip_range = cidr_to_ipv4_range($tenant_network_public_ip_subnet)

    class { 'chameleoncloud::neutron':
        network_node                 => $controller,
        neutron_pass                 => $neutron_pass,
        neutron_dbpass               => $neutron_dbpass,
        db_server                    => $db_server,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        bridge_uplinks               => ["br-${private_interface}:${private_interface}", "br-ex:${public_interface}"],
        bridge_mappings              => ["physnet1:br-${private_interface}", 'public:br-ex'],
        network_vlan_ranges          => "physnet1:${tenant_network_vlan_range}",
        nova_pass                    => $nova_pass,
        keystone_auth_uri            => $keystone_public_endpoint,
        keystone_auth_url            => $keystone_admin_endpoint,
        rabbit_host                  => $controller,
        rabbit_user                  => $rabbit_user,
        rabbit_password              => $rabbit_password,
    }
    class { 'chameleoncloud::neutron::networking_generic_switch':
        switches    => $neutron_ngs_switches,
    }
    neutron_network { 'public':
        ensure                    => present,
        router_external           => true,
        provider_network_type     => 'flat',
        provider_physical_network => 'public',
        shared                    => false,
        tenant_name               => 'openstack',
    }
    neutron_subnet { 'public-subnet':
        ensure           => present,
        network_name     => 'public',
        cidr             => $tenant_network_public_ip_subnet,
        ip_version       => '4',
        gateway_ip       => $tenant_network_public_ip_range[-2],
        allocation_pools => "start=${tenant_network_public_ip_range[1]},end=${tenant_network_public_ip_range[-3]}",
        dns_nameservers  => $dns_servers[0],
        enable_dhcp      => false,
        tenant_name      => 'openstack',
    }
    chameleoncloud::service_proxy { 'neutron_public':
        public_ip  => $public_ip,
        service_ip => $controller,
        port       => '9696',
    }

    #
    # Ironic
    #

    # Should be last IP in the provisioning subnet
    $ironic_provisioning_subnet = '10.20.30.0/24'
    $ironic_provisioning_ip_range = cidr_to_ipv4_range($ironic_provisioning_subnet)
    $ironic_provisioning_gateway_ip = $ironic_provisioning_ip_range[-2]

    neutron_network { 'ironic-provisioning-network':
        ensure                    => present,
        router_external           => false,
        provider_network_type     => 'vlan',
        provider_physical_network => 'physnet1',
        provider_segmentation_id  => $ironic_provisioning_vlan,
        shared                    => false,
        tenant_name               => 'openstack',
    }
    neutron_subnet { 'ironic-provisioning-subnet':
        ensure           => present,
        network_name     => 'ironic-provisioning-network',
        cidr             => $ironic_provisioning_subnet,
        ip_version       => '4',
        gateway_ip       => $ironic_provisioning_gateway_ip,
        allocation_pools => "start=${ironic_provisioning_ip_range[1]},end=${ironic_provisioning_ip_range[-3]}",
        dns_nameservers  => $dns_servers,
        enable_dhcp      => true,
        tenant_name      => 'openstack',
    }
    class { 'chameleoncloud::ironic':
        ironic_host                     => $controller,
        ironic_pass                     => $ironic_pass,
        ironic_dbpass                   => $ironic_dbpass,
        rabbit_password                 => $rabbit_password,
        keystone_auth_uri               => $keystone_public_endpoint,
        keystone_auth_url               => $keystone_admin_endpoint,
        db_server                       => $controller,
        ironic_provision_subnet_gateway => $ironic_provisioning_gateway_ip,
        ironic_cleaning_network         => 'ironic-provisioning-network',
        ironic_provisioning_network     => 'ironic-provisioning-network',
        create_pxe_images               => false,
        network_node                    => $controller,
        glance_host                     => $controller,
    }
    # ironic_config { 'pxe/image_cache_size':
    #     value => '300000',
    # }
    # Ironic TFTP interface on the Ironic provisioning subnet
    network::interface { "br-${private_interface}.${ironic_provisioning_vlan}":
        enable        => true,
        ipaddress     => $ironic_provisioning_gateway_ip,
        netmask       => '255.255.255.0',
        mtu           => '1500',
        vlan          => 'yes',
        nm_controlled => 'no',
    }
    chameleoncloud::service_proxy { 'ironic_public':
        public_ip  => $public_ip,
        service_ip => $controller,
        port       => '6385',
    }

    #
    # Nova
    #

    class { 'chameleoncloud::nova':
        nova_host                    => $controller,
        nova_pass                    => $nova_pass,
        nova_dbpass                  => $nova_dbpass,
        nova_placement_pass          => $nova_placement_pass,
        nova_placement_dbpass        => $nova_placement_dbpass,
        public_endpoint_url          => $public_endpoint_url,
        public_endpoint_ip           => $public_ip,
        neutron_password             => $neutron_pass,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        glance_host                  => $controller,
        db_server                    => $db_server,
        rabbit_password              => $rabbit_password,
        rabbit_host                  => $controller,
        keystone_auth_uri            => $keystone_public_endpoint,
        keystone_auth_url            => $keystone_admin_endpoint,
        memcache_servers             => ["${controller}:11211"],
        ironic_host                  => $controller,
        ironic_pass                  => $ironic_pass,
        network_node                 => $controller,
    }
    chameleoncloud::service_proxy { 'nova_public':
        public_ip  => $public_ip,
        service_ip => $controller,
        port       => '8774',
    }
    chameleoncloud::service_proxy { 'nova_placement_public':
        public_ip  => $public_ip,
        service_ip => $controller,
        port       => '8780',
    }
}
