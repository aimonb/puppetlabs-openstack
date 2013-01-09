#
# === Class: openstack::db::pgsql
#
# Create PgSQL databases for all components of
# OpenStack that require a database
#
# === Parameters
#
# [pgsql_root_password] Root password for pgsql. Required.
# [keystone_db_password] Password for keystone database. Required.
# [glance_db_password] Password for glance database. Required.
# [nova_db_password] Password for nova database. Required.
# [db_root_password] If a secure pgsql db should be setup. Optional .Defaults to true.
# [db_account_security] If a secure pgsql db should be setup. Optional .Defaults to true.
# [keystone_db_user] DB user for keystone. Optional. Defaults to 'keystone'.
# [keystone_db_dbname] DB name for keystone. Optional. Defaults to 'keystone'.
# [glance_db_user] DB user for glance. Optional. Defaults to 'glance'.
# [glance_db_dbname]. Name of glance DB. Optional. Defaults to 'glance'.
# [nova_db_user]. Name of nova DB user. Optional. Defaults to 'nova'.
# [nova_db_dbname]. Name of nova DB. Optional. Defaults to 'nova'.
# [allowed_hosts] List of hosts that are allowed access. Optional. Defaults to false.
# [enabled] If the db service should be started. Optional. Defaults to true.
#
# === Example
#
# class { 'openstack::db::pgsql':
#    pgsql_root_password  => 'changeme',
#    keystone_db_password => 'changeme',
#    glance_db_password   => 'changeme',
#    nova_db_password     => 'changeme',
#    allowed_hosts        => ['127.0.0.1', '10.0.0.%'],
#  }
class openstack::db::postgresql (
    # Required PgSQL
    # passwords
    $keystone_db_password,
    $glance_db_password,
    $nova_db_password,
    $cinder_db_password,
    $quantum_db_password,
    $db_account_security    = true,
    $db_root_password       = 'sql_pass',
    $db_bind_address        = '0.0.0.0',
    # Keystone
    $keystone_db_user       = 'keystone',
    $keystone_db_dbname     = 'keystone',
    # Glance
    $glance_db_user         = 'glance',
    $glance_db_dbname       = 'glance',
    # Nova
    $nova_db_user           = 'nova',
    $nova_db_dbname         = 'nova',
    # Cinder
    $cinder                 = true,
    $cinder_db_user         = 'cinder',
    $cinder_db_dbname       = 'cinder',
    # quantum
    $quantum                = true,
    $quantum_db_user        = 'quantum',
    $quantum_db_dbname      = 'quantum',
    $allowed_hosts          = false,
    $enabled                = true
) {
  # Install and configure PgSQL Server
  class { 'postgresql::server':
    pg_ver     => '9.1',
  }

  # This removes default users and guest access
  if $pgsql_account_security {
    class { 'pgsql::server::account_security': }
  }

  if ($enabled) {
    # Create the Keystone db
    class { 'keystone::db::postgresql':
      user          => $keystone_db_user,
      password      => $keystone_db_password,
      dbname        => $keystone_db_dbname,
      #allowed_hosts => $allowed_hosts,
    }

    # Create the Glance db
    class { 'glance::db::postgresql':
      user          => $glance_db_user,
      password      => $glance_db_password,
      dbname        => $glance_db_dbname,
      #allowed_hosts => $allowed_hosts,
    }

    # Create the Nova db
    class { 'nova::db::postgresql':
      user          => $nova_db_user,
      password      => $nova_db_password,
      dbname        => $nova_db_dbname,
      #allowed_hosts => $allowed_hosts,
    }

    # create cinder db
    if ($cinder) {
      class { 'cinder::db::postgresql':
        user          => $cinder_db_user,
        password      => $cinder_db_password,
        dbname        => $cinder_db_dbname,
        #allowed_hosts => $allowed_hosts,
      }
    }

    # create quantum db
    if ($quantum) {
      class { 'quantum::db::postgresql':
        user          => $quantum_db_user,
        password      => $quantum_db_password,
        dbname        => $quantum_db_dbname,
        #allowed_hosts => $allowed_hosts,
      }
    }
  }
}
