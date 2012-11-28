#
# This contains the base components for nova
#
# === Parameters
#
# [compute]                 (bool) Is Compute?
# [controller]              (bool) Is Controller?
# [public_interface]        (string) Public interface used to route public traffic. Required.
# [public_address]          (string) Public address for public endpoints. Required.
# [private_interface]       (string) Interface used for vm networking connectivity. Required.
# [internal_address]        (string) Internal address used for management. Required.
# [mysql_root_password]     (string) Root password for mysql server.
# [admin_email]             (string) Admin email.
# [admin_password]          (string) Admin password.
# [keystone_db_password]    (string) Keystone database password.
# [keystone_admin_token]    (string) Admin token for keystone.
# [glance_db_password]      (string) Glance DB password.
# [glance_user_password]    (string) Glance service user password.
# [nova_db_password]        (string) Nova DB password.
# [nova_user_password]      (string) Nova service password.
# [rabbit_password]         (string) Rabbit password.
# [rabbit_user]             (string) Rabbit User.
# [rabbit_virtual_host]     (string) Rabbit virtual host path for Nova. Defaults to '/'.
# [network_manager]         (string) Nova network manager to use.
# [fixed_range]             (string) Range of ipv4 network for vms.
# [floating_range]          (string) Floating ip range to create.
# [create_networks]         (bool) Create network and floating ips.
# [num_networks]            (integer) Number of networks that fixed range should be split into.
# [multi_host]              (bool) Support multi-host networking mode.
# [auto_assign_floating_ip] (bool) Automatically allocate and assign a floating IP address to virtual instances when they are launched.
# [network_config]          (hash) Hash that can be used to pass implementation specifc network settings.
# [verbose]                 (bool) Enable verbose logging.
# [horizon]                 (bool) Install Horizon.
# [secret_key]              (string) Secret key to encode cookies for Horizon.
# [cache_server_ip]         (string) Local memcached instance ip for Horizon
# [cache_server_port]       (string )local memcached instance port for Horizon
# [swift]                   (bool) Install Swift
# [quantum]                 (bool) Install Quantum
#   The next is an array of arrays, that can be used to add call-out links to the dashboard for other apps.
#   There is no specific requirement for these apps to be for monitoring, that's just the defacto purpose.
#   Each app is defined in two parts, the display name, and the URI
# [horizon_app_links]       (array) as in '[ ["Nagios","http://nagios_addr:port/path"],["Ganglia","http://ganglia_addr"] ]'
# [enabled]                 (bool) Whether services should be enabled. This parameter can be used to implement services in active-passive modes for HA. Set to false if you do not want services to auto start
#
# === Examples
#
# This example is a real implemntation example heavily using custom facts to control the class.
# Traits of this exaple:
# - No Quantum or Cinder
# - Uses nova-volume
# - Flat MultiHost networking
# - Shared RabbitMQ server with custom vhost (all work is done for you..just specify it and puppet will take care of rest.. It is then safe for other apps on other vhosts)
# - Uses a Single /16 network for VM IPs ($::fixed_range=n.n.0.0/16)
# - Note that some options are specified with their default args.. This is unecessary but we like it for explicitness.
#
#  class { 'openstack::nova_common':
#    controller                => str2bool($::is_controller),
#    compute                   => str2bool($::is_compute),
#    public_address            => $::ext_ip,
#    internal_address          => $::int_ip,
#    db_host                   => $::controller_ip,
#    rabbit_userid             => $::nova_rabbit_user,
#    rabbit_password           => $::nova_rabbit_password,
#    rabbit_host               => $::controller_ip,
#    rabbit_virtual_host       => '/nova',
#    nova_user_password        => $::keystone_admin_password,
#    nova_db_dbname            => $::nova_db_name,
#    nova_db_user              => $::nova_db_user,
#    nova_db_password          => $::nova_db_pass,
#    db_type                   => 'mysql',
#    image_service             => 'nova.image.glance.GlanceImageService',
#    glance_api_servers        => "${::controller_ip}:9292",
#    verbose                   => $::verbose,
#    cinder                    => false,
#    service_down_time         => 120,
#    enabled_apis              => 'ec2,osapi_compute,osapi_volume,metadata',
#    enabled                   => true,
#    # Network
#    public_interface          => $::ext_eth,
#    private_interface         => $::int_eth,
#    fixed_range               => $::fixed_range,
#    network_manager           => 'nova.network.manager.FlatDHCPManager',
#    network_config            => {},
#    multi_host                => true,
#    create_networks           => true,
#    network_size              =>  65535,
#    num_networks              =>  1,
#    floating_range            =>  $::float_range,
#    # Quantum
#    quantum                   => false,
#    quantum_sql_connection    => false,
#    quantum_host              => false,
#    quantum_user_password     => false,
#    # Keystone
#    keystone_host             => $::controller_ip,
#    # Nova
#    purge_nova_config         => true,
#    api                       => true,
#  }
#
##############
class openstack::nova_common(
  $compute,
  $controller,
  # Network Required
  $public_address,
  # Database Required
  $db_host,
  # Rabbit Required
  $rabbit_password,
  # Nova Required
  $nova_user_password,
  $nova_db_password,
  # Defaults
  $nova_db_user              = 'nova',
  $nova_db_dbname            = 'nova',
  $rabbit_userid             = 'nova',
  $db_type                   = 'mysql',
  $image_service             = 'nova.image.glance.GlanceImageService',
  $glance_api_servers        = undef,
  $verbose                   = 'False',
  $rabbit_host               = '127.0.0.1',
  $rabbit_virtual_host       = '/',
  $cinder                    = true,
  $internal_address          = $public_address,
  $service_down_time         = 60,
  $enabled_apis              = 'ec2,osapi_compute,metadata',
  $enabled                   = true,
  # Database
  $db_host                 = '127.0.0.1',
  $db_type                 = 'mysql',
  $mysql_root_password     = 'sql_pass',
  $mysql_bind_address      = '0.0.0.0',
  $mysql_account_security  = true,
  $allowed_hosts           = '%',
  # Network
  $public_interface              = undef,
  $private_interface             = undef,
  $internal_address        = false,
  $admin_address           = false,
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $fixed_range             = '10.0.0.0/24',
  $floating_range          = false,
  $create_networks         = true,
  $num_networks            = 1,
  $network_size            = 255,
  $multi_host              = false,
  $network_config          = {},
  $auto_assign_floating_ip   = false,
  # Quantum
  $quantum                       = false,
  $quantum_sql_connection        = false,
  $quantum_host                  = false,
  $quantum_user_password         = 'quantum',
  $quantum_db_password           = 'quantum',
  # Keystone
  $keystone_host                 = '127.0.0.1',
  $keystone_db_password          = 'keystone',
  # Cinder
  $cinder_user_password          = 'cinder',
  $cinder_db_password            = 'cinder',
  # Nova
  $purge_nova_config             = true,
  $api                           = true,
  ){

  ######## BEGIN NOVA ###########
  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }
  # Configure the db string
  case $db_type {
    'mysql': {
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}"
      $os_db_class='openstack::db::mysql'
      $db_class='db::mysql'
    }
    'pgsql': {
      $nova_db = "postgresql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}"
      $os_db_class='openstack::db::pgsql'
      $db_class='db::pgsql'
    }
    default: {
      fail("Unsupported db : ${db_type}")
    }
  }
  # Ordering
  if $controller {
    Class[$os_db_class] -> Class['nova']
    Class[$os_db_class] -> Class['nova::api']
    Class[$os_db_class] -> Class['nova::network']
    Class["glance::${db_class}"] -> Class['glance::registry']
    
    class { $os_db_class:
      mysql_root_password    => $mysql_root_password,
      mysql_bind_address     => $mysql_bind_address,
      mysql_account_security => $mysql_account_security,
      keystone_db_user       => $keystone_db_user,
      keystone_db_password   => $keystone_db_password,
      keystone_db_dbname     => $keystone_db_dbname,
      glance_db_user         => $glance_db_user,
      glance_db_password     => $glance_db_password,
      glance_db_dbname       => $glance_db_dbname,
      nova_db_user           => $nova_db_user,
      nova_db_password       => $nova_db_password,
      nova_db_dbname         => $nova_db_dbname,
      cinder                 => $cinder,
      cinder_db_user         => $cinder_db_user,
      cinder_db_password     => $cinder_db_password,
      cinder_db_dbname       => $cinder_db_dbname,
      quantum                => $quantum,
      quantum_db_user        => $quantum_db_user,
      quantum_db_password    => $quantum_db_password,
      quantum_db_dbname      => $quantum_db_dbname,
      allowed_hosts          => $allowed_hosts,
      enabled                => $enabled,
    }
    if $controller and $enabled {
      $really_create_networks = $create_networks
    } else {
      $really_create_networks = false
    }
  }
  if ($glance_api_servers == undef) {
    $real_glance_api_servers = "${public_address}:9292"
  } else {
    $real_glance_api_servers = $glance_api_servers
  }

  $sql_connection    = $nova_db
  $glance_connection = $real_glance_api_servers
  $rabbit_connection = $internal_address
  
  
  # Configure Nova
  class { 'nova':
    sql_connection      => $sql_connection,
    rabbit_userid       => $rabbit_userid,
    rabbit_password     => $rabbit_password,
    image_service       => $image_service,
    glance_api_servers  => $glance_api_servers,
    verbose             => $verbose,
    rabbit_host         => $rabbit_host,
    rabbit_virtual_host => $rabbit_virtual_host,
    service_down_time   => $service_down_time,
  } 
  if $cinder {
    $volume_api_class = 'nova.volume.cinder.API'
  } else {
    $volume_api_class = 'nova.volume.api.API'
  }

  if $api {
    # Configure nova-api
    class { 'nova::api':
      enabled           => $enabled,
      admin_user        => 'nova',
      admin_password    => $nova_user_password,
      auth_host         => $keystone_host,
      enabled_apis      => $enabled_apis, 
      volume_api_class  => $volume_api_class,
    }
  } 
  # Networking
  if $auto_assign_floating_ip {
    nova_config { 'auto_assign_floating_ip': value => 'True' }
  }
  
  # Nova Netwo rk
  if ! $quantum {

    if ! $fixed_range {
      fail("Must specify the fixed range when using nova-networks")
    }
    if $multi_host {
      include keystone::python
      nova_config {
        'multi_host':      value => 'True';
        'send_arp_for_ha': value => 'True';
      }
      if ! $public_interface {
        fail('public_interface must be defined for multi host compute nodes')
      }
      if $compute {
        $enable_network_service = true
      } else{
        $enable_network_service = false
      }
    } else {
      if $compute {
        $enable_network_service = false
      } else {
        $enable_network_service = true
      }
      nova_config {
        'multi_host':      value => 'False';
        'send_arp_for_ha': value => 'False';
      }
    }
    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => $floating_range,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => $really_create_networks,
      num_networks      => $num_networks,
      network_size      => $network_size,
      enabled           => $enable_network_service,
      install_service   => $enable_network_service,
    }
  # Quantum
  } else {
    $quantum_sql_connection = "mysql://${quantum_db_user}:${quantum_db_password}@${db_host}/${quantum_db_dbname}?charset=utf8"
    class { 'quantum':
      verbose         => $verbose,
      debug           => $verbose,
      rabbit_host     => $rabbit_host,
      rabbit_user     => $rabbit_user,
      rabbit_password => $rabbit_password,
      #sql_connection  => $quantum_sql_connection,
    }
    
    class { 'quantum::plugins::ovs':
      sql_connection      => $quantum_sql_connection,
      tenant_network_type => 'gre',
      enable_tunneling    => true,
    }

    class { 'quantum::agents::ovs':
      bridge_uplinks   => ["br-virtual:${private_interface}"],
      enable_tunneling => true,
      local_ip         => $internal_address,
    }

    class { 'quantum::agents::dhcp':
      use_namespaces => False,
    }

#    class { 'quantum::agents::l3':
#      auth_password => $quantum_user_password,
#    }
    
    # NOTE: does this have to be installed on the compute node? If not move to openstack::nova::controller class. 
    class { 'nova::network::quantum':
    #$fixed_range,
      quantum_admin_password    => $quantum_user_password,
    #$use_dhcp                  = 'True',
    #$public_interface          = undef,
      quantum_connection_host   => 'localhost',
      quantum_auth_strategy     => 'keystone',
      quantum_url               => "http://${keystone_host}:9696",
      quantum_admin_tenant_name => 'services',
      #quantum_admin_username    => 'quantum',
      quantum_admin_auth_url    => "http://${keystone_host}:35357/v2.0",
    }
  }
}
