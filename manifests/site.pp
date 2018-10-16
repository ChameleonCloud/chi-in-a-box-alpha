#hiera_include('classes')

node ciab01.chameleon.tacc.utexas.edu {
#node qa.tacc.chameleoncloud.org {
    #notify {"CIAB DEBUG $admin_token":}

    # SSL
    $ssl_path_base          = '/etc/pki/tls'
    $ssl_cert_base          = "$fqdn.cer"
    $ssl_key_base           = "$fqdn.key"
    $ssl_ca_base            = "$fqdn-interm.cer"
    $ssl_cert               = "$ssl_path_base/certs/$ssl_cert_base"
    $ssl_key                = "$ssl_path_base/private/$ssl_key_base"
    $ssl_ca                 = "$ssl_path_base/certs/$ssl_ca_base"

    file { "$ssl_cert":
        source          => "file:///root/$ssl_cert_base",
        ensure          => present,
        mode            => '644',
        owner           => 'root',
        group           => 'root',
    }

    file { "$ssl_key":
        source          => "file:///root/$ssl_key_base",
        ensure          => present,
        mode            => '644',
        owner           => 'root',
        group           => 'root',
    }

    file { "$ssl_ca":
        source          => "file:///root/$ssl_ca_base",
        #source          => "puppet:///modules/chameleoncloud/$ssl_ca_base",
        ensure          => present,
        mode            => '644',
        owner           => 'root',
        group           => 'root',
    }

    class { '::ca_cert':
        install_package => true
    }

    ca_cert::ca { 'InCommonRSA-Intermediate':
        ensure => 'trusted',
        source => "file://$ssl_ca",
        #source => 'https://www.incommon.org/certificates/repository/incommon-ssl.ca-bundle',
    }

    # Controller Management
#    network::interface { 'em1' :
#      enable        => true,
#      #ipaddress     => $chameleoncloud::params::controller,
#      ipaddress     => '10.20.111.250',
#      netmask       => '255.255.254.0',
#      gateway       => '10.20.111.252', # This should be disabled when the public interface is operational
#      mtu           => '1500',
#      hotplug       => 'yes',
#      peerdns       => 'yes',
#      dns1          => '10.20.111.252',
#      #defroute      => 'no'
#    }

    # Public Interface ( API / Horizon )
    network::interface { 'em2' :
      enable        => true,
      ipaddress     => $public_ip,
      netmask       => '255.255.255.0',
      gateway       => '129.114.97.254',
      mtu           => '1500',
      peerdns       => 'yes',
      dns1          => '129.114.97.1',
      dns2          => '129.114.97.2',
      defroute      => 'yes',
    }

    # Out of Band
    network::interface { 'em3' :
      enable        => true,
      ipaddress     => '172.16.110.81',
      netmask       => '255.255.252.0',
      mtu           => '1500',
    }

    #$public_endpoint_url = 'ciab01.chameleon.tacc.utexas.edu'
    #$keystone_auth_uri   = "$public_endpoint_url:35357"
    #$keystone_auth_url   = "$public_endpoint_url:5000"

    # Create admin adminrc in /root
    class { 'openstack_extras::auth_file':
      path                  => '/root/adminrc',
      password              => $admin_password,
      region_name           => $region,
      auth_url              => $keystone_public_endpoint,
#      project_name          => $admin_project_name,
#      tenant_name           => $admin_tenant_name,
    }
#    class { 'openstack_extras::auth_file':
#      path                  => '/root/openrc',
#      password              => $admin_password,
#      region_name           => $region,
#      auth_url              => $keystone_auth_url,
#    }

    class { 'memcached':
      listen_ip => $controller,
      max_memory => '10%',
    }

    class {'::chameleoncloud':}
    class {'chameleoncloud::rabbitmq':
        rabbit_user             => $rabbit_user,
        rabbit_password         => $rabbit_password,
    }

    class {'::chameleoncloud::db':
      backup_password             => $backup_password,
      server_id                   => '1',
      blazar_extra_allowed_hosts  => undef,
      gnocchi_allowed_hosts       => undef,
      db_hammers_user             => 'cc_hammers',
      db_hammers_pass             => $db_hammers_pass,
      db_readonly_user            => $db_readonly_user,
      db_readonly_pass            => $db_readonly_pass,
      mysql_root                  => $mysql_root,
      keystone_dbpass             => $keystone_dbpass,
      neutron_dbpass              => $neutron_dbpass,
      ironic_dbpass               => $ironic_dbpass,
      #db_server                   => $controller,
      db_allowed_hosts            => $controller,
    }

    class { '::chameleoncloud::keystone':
      admin_token                => $admin_token,
      admin_password             => $admin_password,
      keystone_dbpass            => $keystone_dbpass,
      keystone_auth_email        => 'chameleon-sys@tacc.utexas.edu',
      keystone_host              => $controller,
      public_endpoint            => $keystone_public_endpoint,
      admin_endpoint             => $keystone_admin_endpoint,
      instance_metrics_writer_username => $instance_metrics_writer_username,
      instance_metrics_writer_password => $instance_metrics_writer_password,
    }

    class { 'chameleoncloud::horizon':
      theme_base_dir             => '/opt/theme',
      theme_name                 => 'chameleon',
      help_url                   => "https://www.chameleoncloud.org/docs/bare-metal-user-guide/",
      horizon_secret_key         => $horizon_secret_key,
      keystone_auth_uri          => $keystone_public_endpoint,
      memcache_server_ip         => $controller,
#      portal_api_base_url        => 'https://www.chameleoncloud.org',
    }


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
      #usage_enforcement             => 'True',
      #usage_db_host                 => 'chi.uc.chameleoncloud.org',
      usage_db_host                 => '',
      usage_default_allocated       => '20000.0',
      #email_relay                   => 'relay.tacc.utexas.edu',
      require                       => Class['chameleoncloud::horizon']
    }
    chameleoncloud::service_proxy { 'blazar_public' :
        public_ip       => $public_ip,
        service_ip      => $controller,
        port            => '1234',
    }

    class { 'chameleoncloud::glance':
        glance_host                => $controller,
        glance_pass                => $glance_pass,
        glance_dbpass              => $glance_dbpass,
        public_endpoint_url        => $public_endpoint_url,
        keystone_auth_uri          => $keystone_public_endpoint,
        keystone_auth_url          => $keystone_admin_endpoint,
    }
    chameleoncloud::service_proxy { 'glance_public' :
        public_ip       => $public_ip,
        service_ip      => $controller,
        port            => '9292',
    }

    class { 'chameleoncloud::neutron':
        network_node                 => $controller,
        neutron_pass                 => $neutron_pass,
        neutron_dbpass               => $neutron_dbpass,
        db_server                    => $db_server,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        bridge_uplinks               => ["br-${physnet_interface}:${physnet_interface}" , 'br-ex:p5p1'],
        bridge_mappings              => ["physnet1:br-${physnet_interface}",'public:br-ex'],
        network_vlan_ranges          => 'physnet1:400:410',
        nova_pass                    => $nova_pass,
        keystone_auth_uri            => $keystone_public_endpoint,
        keystone_auth_url            => $keystone_admin_endpoint,
        rabbit_host                  => $rabbit_host,
        rabbit_user                  => $rabbit_user,
        rabbit_password              => $rabbit_password,
    }
    chameleoncloud::service_proxy { 'neutron_public' :
        public_ip       => $public_ip,
        service_ip      => $controller,
        port            => '9696',
    }
    class { 'chameleoncloud::neutron::networking_generic_switch':
        switches    => $neutron_ngs_switches,
    }

    # Ironic TFTP interface
    # On the Ironic Provisioning subnet
    network::interface { "br-${physnet_interface}.${ironic_provisioning_vlan}" :
        enable        => true,
        ipaddress     => $ironic_provisioning_ip,
        netmask       => '255.255.255.0',
        mtu           => '1500',
        vlan          => 'yes',
        nm_controlled => 'no',
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
        ensure                    => present,
        network_name              => 'public',
        cidr                      => '129.114.34.128/25',
        ip_version                => '4',
        gateway_ip                => '129.114.34.254',
        allocation_pools          => 'start=129.114.34.129,end=129.114.34.253',
        dns_nameservers           => '129.114.97.1',
        enable_dhcp               => false,
        tenant_name               => 'openstack',
    }

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
        ensure                    => present,
        network_name              => 'ironic-provisioning-network',
        cidr                      => '10.20.30.0/24',
        ip_version                => '4',
        gateway_ip                => $ironic_provisioning_ip,
        allocation_pools          => 'start=10.20.30.1,end=10.20.30.200',
        dns_nameservers           => '129.114.97.1',
        enable_dhcp               => true,
        tenant_name               => 'openstack',
    }

    class { 'chameleoncloud::ironic':
        ironic_host                     => $controller,
        ironic_pass                     => $ironic_pass,
        ironic_dbpass                   => $ironic_dbpass,
        rabbit_password                 => $rabbit_password,
        keystone_auth_uri               => $keystone_public_endpoint,
        keystone_auth_url               => $keystone_admin_endpoint,
        db_server                       => $controller,
        ironic_provision_subnet_gateway => $ironic_provisioning_ip,
        ironic_cleaning_network         => 'ironic-provisioning-network',
        ironic_provisioning_network     => 'ironic-provisioning-network',
        create_pxe_images               => false,
        network_node                    => $controller,
        glance_host                     => $controller,
    } #->
#    ironic_config { 'pxe/image_cache_size':
#      value => '300000',
#    }
#
    chameleoncloud::service_proxy { 'ironic_public' :
        public_ip       => $public_ip,
        service_ip      => $controller,
        port            => '6385',
    }

    class { 'chameleoncloud::nova':
        nova_host                       => $controller,
        nova_pass                       => $nova_pass,
        nova_dbpass                     => $nova_dbpass,
        nova_placement_pass             => $nova_placement_pass,
        nova_placement_dbpass           => $nova_placement_dbpass,
        public_endpoint_url             => $public_endpoint_url,
        public_endpoint_ip              => $public_ip,
        neutron_password                => $neutron_pass,
        metadata_proxy_shared_secret    => $metadata_proxy_shared_secret,
        glance_host                     => $controller,
        db_server                       => $db_server,
        rabbit_password                 => $rabbit_password,
        rabbit_host                     => $controller,
        keystone_auth_uri               => $keystone_public_endpoint,
        keystone_auth_url               => $keystone_admin_endpoint,
        memcache_servers                => ["$controller:11211"],
        ironic_host                     => $controller,
        ironic_pass                     => $ironic_pass,
        network_node                    => $controller,
    }
    chameleoncloud::service_proxy { 'nova_public' :
        public_ip       => $public_ip,
        service_ip      => $controller,
        port            => '8774',
    }
    chameleoncloud::service_proxy { 'nova_placement_public' :
        public_ip       => $public_ip,
        service_ip      => $controller,
        port => '8780',
    }

}
