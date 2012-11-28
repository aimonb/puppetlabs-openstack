#
# == Class: openstack::compute
#
# Manifest to install/configure nova-compute
#
# === Parameters
#
## Required Network
# [internal_address]        (StrOpt) Interal IP address
## Required Nova
# [nova_user_password]      (StrOpt) Nova user password
## Required Rabbit
# [rabbit_password]         (StrOpt) Rabbit user password
## Quantum
# [quantum]                 (BoolOpt) Enable Quantum
# [quantum_user_password]   (StrOpt) Quantum user password
## Rabbit
# [rabbit_host]             (StrOpt) RabbitMQ server listen address
# [rabbit_user]             (StrOpt) User to connect to RabbitMQ as
# [rabbit_virtual_host]     (StrOpt) VirtualHost to use for Nova queue (set to non default if you are sharing RabbitMQ with other services)
## Virtualization
# [libvirt_type]            (StrOpt) Libvirt domain type (valid options are: kvm, lxc, qemu, uml, xen)
## VNC
# [vnc]                     (BoolOpt) Enable VNC
# [vncproxy_host]           (StrOpt) VNC Proxy Listen address
# [vncserver_listen]        (StrOpt) VNC Server listen address (This must be '0.0.0.0' if migration_support=true)
# [novncproxy_base_url]     (StrOpt) location of VNC console proxy, in the form "http://www.example.com:6080/vnc_auto.html"
## Cinder / Volumes
# [cinder]                  (BoolOpt) Enable Cinder
# [cinder_sql_connection]   (StrOpt) SQLAlchemy connection string for Cinder
# [nova_volume]             (StrOpt) Nova Volume Group to be used by Cinder 
# [iscsi_ip_address]        (StrOpt) IP Address of ISCSI Server (typically internal address)
## General
# [enabled_apis]            (ListOpt) a list of APIs to enable by default
# [migration_support]       (BoolOpt) Support Live Migration
# [verbose]                 (BoolOpt) Verbose logging
# [enabled]                 (BoolOpt) Enable Compute
#
# === Examples
#
# class { 'openstack::nova::compute':
#   internal_address   => '192.168.2.2',
#   vncproxy_host      => '192.168.1.1',
#   nova_user_password => 'changeme',
# }

class openstack::compute (
  # Required Network
  $internal_address,
  # Required Nova
  $nova_user_password,
  # Required Rabbit
  $rabbit_password,
  # Quantum
  $quantum                       = false,
  $quantum_user_password         = false,
  # Rabbit
  $rabbit_host                   = '127.0.0.1',
  $rabbit_user                   = 'nova',
  $rabbit_virtual_host           = '/',
  # Virtualization
  $libvirt_type                  = 'kvm',
  # VNC
  $vnc                           = true,
  $vncproxy_host                 = undef,
  $vncserver_listen              = false,
  $novncproxy_base_url           = 'http://127.0.0.1:6080/vnc_auto.html',
  # Cinder / Volumes
  $cinder                        = true,
  $cinder_sql_connection         = undef,
  $nova_volume                   = 'cinder-volumes',
  $iscsi_ip_address              = false,
  # General
  $enabled_apis                   = 'ec2,osapi_compute,metadata',
  $migration_support             = false,
  $verbose                       = 'False',
  $enabled                       = true
) {

  if $vncserver_listen {
    $vncserver_listen_real = $vncserver_listen
  } else {
    $vncserver_listen_real = $internal_address
  }
  if ! $iscsi_ip_address {
    $iscsi_ip_address_real=$internal_address
  }

  # Install / configure nova-compute
  class { '::nova::compute':
    enabled                       => $enabled,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $internal_address,
    vncproxy_host                 => $vncproxy_host,
    novncproxy_base_url           => $novncproxy_base_url,
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type      => $libvirt_type,
    vncserver_listen  => $vncserver_listen_real,
    migration_support => $migration_support,
  }

  # if the compute node should be configured as a multi-host
  # compute installation
  if ! $quantum {
    if $multi_host {
      include keystone::python
    }
  } else {
    if ! $quantum_user_password {
      fail('quantum user password must be set when quantum is configured')
    }


    class { 'quantum::agents::l3':
      auth_password => $quantum_user_password,
    }

    class { 'nova::compute::quantum': }

    nova_config {
      'linuxnet_interface_driver':       value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
      'linuxnet_ovs_integration_bridge': value => 'br-int';
    }
  }

  if ($cinder) {
    class { 'cinder::base':
      rabbit_password => $rabbit_password,
      rabbit_host     => $rabbit_host,
      sql_connection  => $cinder_sql_connection,
      verbose         => $verbose,
    }
    class { 'cinder::volume': }
    class { 'cinder::volume::iscsi':
      iscsi_ip_address => $iscsi_ip_address_real,
      volume_group     => $nova_volume,
    }

    # set in nova::api
    if ! defined(Nova_config['volume_api_class']) {
      nova_config { 'volume_api_class': value => 'nova.volume.cinder.API' }
    }
  }

}
