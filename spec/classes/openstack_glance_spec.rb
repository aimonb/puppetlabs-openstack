require 'spec_helper'

describe 'openstack::glance' do

  # minimum set of default parameters
  let :default_params do
    {
      :keystone_host        => '127.0.0.1',
      :auth_uri             => "http://127.0.0.1:5000/",
      :db_type              => 'mysql',
      :db_host              => '127.0.0.1',
      :glance_db_user       => 'glance',
      :glance_db_dbname     => 'glance',
      :glance_db_password   => 'glance_db_pass',
      :glance_user_password => 'glance_pass',
      :verbose              => 'False',
      :enabled              => true 
    }
  end
  
  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :puppetversion   => '2.7.x',
      :memorysize      => '2GB',
      :processorcount  => '2'
    }
  end

  let :params do
    default_params
  end

  context 'config for glance' do

    context 'when enabled' do
      it 'should contain enabled glance with defaults' do

        should contain_class('glance::api').with(
          :verbose           => 'False',
          :debug             => 'False',
          :auth_type         => 'keystone',
          :auth_host         => '127.0.0.1',
          :auth_port         => '35357',
          :keystone_tenant   => 'services',
          :keystone_user     => 'glance',
          :keystone_password => 'glance_pass',
          :sql_connection    => 'mysql://glance:glance_db_pass@127.0.0.1/glance',
          :enabled           => true
        )

        should contain_class('glance::registry').with(
          :verbose           => 'False',
          :debug             => 'False',
          :auth_type         => 'keystone',
          :auth_host         => '127.0.0.1',
          :auth_port         => '35357',
          :keystone_tenant   => 'services',
          :keystone_user     => 'glance',
          :keystone_password => 'glance_pass',
          :sql_connection    => "mysql://glance:glance_db_pass@127.0.0.1/glance",
          :enabled           => true
        )

        should contain_class('glance::backend::file')
      end
    end
    context 'when not enabled' do

      let :params do
        default_params.merge(:enabled => false)
      end

      it 'should disable glance services' do
        should contain_class('glance::api').with(
          :enabled           => false
        )

        should contain_class('glance::registry').with(
          :enabled           => false
        )
      end
    end
    context 'when params are overridden' do

      let :params do
        default_params.merge(
          :verbose               => 'False',
          :glance_user_password  => 'glance_pass2',
          :glance_db_password    => 'glance_pass3',
          :db_host               => '127.0.0.2',
          :glance_db_user        => 'dan',
          :glance_db_dbname      => 'name',
          :db_host               => '127.0.0.2'
        )
      end

      it 'should override params for glance' do
        should contain_class('glance::api').with(
          :verbose           => 'False',
          :debug             => 'False',
          :auth_type         => 'keystone',
          :auth_host         => '127.0.0.1',
          :auth_port         => '35357',
          :keystone_tenant   => 'services',
          :keystone_user     => 'glance',
          :keystone_password => 'glance_pass2',
          :sql_connection    => 'mysql://dan:glance_pass3@127.0.0.2/name'
        )

        should contain_class('glance::registry').with(
          :verbose           => 'False',
          :debug             => 'False',
          :auth_type         => 'keystone',
          :auth_host         => '127.0.0.1',
          :auth_port         => '35357',
          :keystone_tenant   => 'services',
          :keystone_user     => 'glance',
          :keystone_password => 'glance_pass2',
          :sql_connection    => "mysql://dan:glance_pass3@127.0.0.2/name"
        )
      end
    end
  end

end
