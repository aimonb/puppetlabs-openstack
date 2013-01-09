#
# == Class: openstack::nova::controller
#
# Class to define nova components used in a controller architecture.
# Basically everything but nova-compute and nova-volume
#
# === Parameters
#
# See params.pp
#
# === Examples
#
# class { 'openstack::nova::controller':
#   public_address     => '192.168.1.1',
#   rabbit_password    => 'changeme',
#   nova_db_password   => 'changeme',
# }
#

class openstack::nova::controller (
  # Network Required
  $public_address,
  # Rabbit Required
  $rabbit_password,
  # quantum
  $quantum                   = false,
  $quantum_user_password     = 'quantum_pass',
  # Rabbit
  $rabbit_user               = 'nova',
  $rabbit_virtual_host       = '/',
  # VNC
  $vnc_enabled               = true,
  $novncproxy_host           = '0.0.0.0',
  # General
  $keystone_host             = '127.0.0.1',
  $verbose                   = 'False',
  $enabled                   = true,
) {

  # Install / configure rabbitmq
  class { 'nova::rabbitmq':
    userid        => $rabbit_user,
    password      => $rabbit_password,
    enabled       => $enabled,
    virtual_host  => $rabbit_virtual_host,
  }

  # Set up Quantum
  if ($quantum) {
    class { 'quantum::server':
      auth_password => $quantum_user_password,
    }
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::cert',
    'nova::consoleauth',
    'nova::objectstore',
    'nova::scheduler'
  ]:
    enabled => $enabled,
  }

  if $vnc_enabled {
    class { 'nova::vncproxy':
      host    => $novncproxy_host,
      enabled => $enabled,
    }
  }

}
