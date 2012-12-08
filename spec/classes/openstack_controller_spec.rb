require 'spec_helper'

describe 'openstack::controller' do

  # minimum set of default parameters
  let :default_params do
    {
      :private_interface     => 'eth0',
      :public_interface      => 'eth1',
      :internal_address      => '127.0.0.1',
      :public_address        => '10.0.0.1',
      :admin_email           => 'some_user@some_fake_email_address.foo',
      :admin_password        => 'ChangeMe',
      :rabbit_password       => 'rabbit_pw',
      :rabbit_virtual_host   => '/',
      :keystone_db_password  => 'keystone_pass',
      :keystone_admin_token  => 'keystone_admin_token',
      :glance_db_password    => 'glance_pass',
      :glance_user_password  => 'glance_pass',
      :nova_user_password    => 'nova_pass',
      :secret_key            => 'secret_key',
      :quantum               => false
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




  context 'keystone' do

    context 'with default params' do

      let :params do
        default_params
      end

      it { should contain_class('keystone').with(
        :verbose        => 'False',
        :debug          => 'False',
        :catalog_type   => 'sql',
        :enabled        => true,
        :admin_token    => 'keystone_admin_token',
        :sql_connection => "mysql://keystone:keystone_pass@127.0.0.1/keystone"
      ) }

      it 'should contain endpoints' do
        should contain_class('keystone::roles::admin').with(
          :email        => 'some_user@some_fake_email_address.foo',
          :password     => 'ChangeMe',
          :admin_tenant => 'admin'
        )
        should contain_class('keystone::endpoint').with(
          :public_address   => '10.0.0.1',
          :internal_address => '127.0.0.1',
          :admin_address    => '127.0.0.1',
          :region           => 'RegionOne'
        )
        {
         'nova'     => 'nova_pass',
         'cinder'   => 'cinder_pass',
         'glance'   => 'glance_pass'

        }.each do |type, pw|
          should contain_class("#{type}::keystone::auth").with(
            :password         => pw,
            :public_address   => '10.0.0.1',
            :internal_address => '10.0.0.1',
            :admin_address    => '10.0.0.1',
            :region           => 'RegionOne'
          )
         end
      end
    end
    context 'when not enabled' do

      let :params do
        default_params.merge(:enabled => false)
      end

      it 'should not configure endpoints' do
        should contain_class('keystone').with(:enabled => false)
        should_not contain_class('keystone::roles::admin')
        should_not contain_class('keystone::endpoint')
        should_not contain_class('glance::keystone::auth')
        should_not contain_class('nova::keystone::auth')
      end
    end
  end

  it do
    should contain_class('memcached').with(
      :listen_ip => '127.0.0.1'
    )
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
          :sql_connection    => 'mysql://glance:glance_pass@127.0.0.1/glance',
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
          :sql_connection    => "mysql://glance:glance_pass@127.0.0.1/glance",
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

  context 'config for nova' do
    let :facts do
      {
        :operatingsystem => 'Ubuntu',
        :osfamily        => 'Debian',
        :puppetversion   => '2.7.x',
        :memorysize      => '2GB',
        :processorcount  => '2'
      }
    end

    context 'with default params' do

      it 'should contain enabled nova services' do
        should contain_class('nova::rabbitmq').with(
          :userid       => 'nova',
          :password     => 'rabbit_pw',
          :virtual_host => '/',
          :enabled      => true
        )
        should contain_class('nova').with(
          :sql_connection      => 'mysql://nova:nova_pass@127.0.0.1/nova',
          :rabbit_host         => '127.0.0.1',
          :rabbit_userid       => 'nova',
          :rabbit_password     => 'rabbit_pw',
          :rabbit_virtual_host => '/',
          :image_service       => 'nova.image.glance.GlanceImageService',
          :glance_api_servers  => '10.0.0.1:9292',
          :verbose             => 'False',
          :service_down_time   => '60'
        )
        should contain_class('nova::api').with(
          :enabled           => true,
          :admin_tenant_name => 'services',
          :admin_user        => 'nova',
          :admin_password    => 'nova_pass',
          :volume_api_class  => 'nova.volume.cinder.API'
        )
        should contain_class('nova::cert').with(:enabled => true)
        should contain_class('nova::consoleauth').with(:enabled => true)
        should contain_class('nova::scheduler').with(:enabled => true)
        should contain_class('nova::objectstore').with(:enabled => true)
        should contain_class('nova::vncproxy').with(:enabled => true)
      end
      it { should_not contain_nova_config('auto_assign_floating_ip') }
    end
    context 'when not enabled' do
      let :params do
        default_params.merge(:enabled => false)
      end
      it 'should disable everything' do
        should contain_class('nova::rabbitmq').with(:enabled => false)
        should contain_class('nova::api').with(:enabled => false)
        should contain_class('nova::cert').with(:enabled => false)
        should contain_class('nova::consoleauth').with(:enabled => false)
        should contain_class('nova::scheduler').with(:enabled => false)
        should contain_class('nova::objectstore').with(:enabled => false)
        should contain_class('nova::vncproxy').with(:enabled => false)
      end
    end
  end


  context 'config for horizon' do

    it 'should contain enabled horizon' do
      should contain_class('horizon').with(
        :secret_key        => 'secret_key',
        :cache_server_ip   => '127.0.0.1',
        :cache_server_port => '11211',
        :swift             => false,
        :quantum           => false,
        :horizon_app_links => false
      )
    end

    describe 'when horizon is disabled' do
      let :params do
        default_params.merge(:horizon => false)
      end
      it { should_not contain_class('horizon') }
    end
  end

  context 'cinder' do

    context 'when disabled' do
      let :params do
        default_params.merge(:cinder => false)
      end
      it 'should not contain cinder classes' do
        should_not contain_class('cinder::base')
        should_not contain_class('cinder::api')
        should_not contain_class('cinder:"scheduler')
      end
    end

    context 'when enabled' do
      let :params do
        default_params
      end
      it 'should configure cinder using defaults' do
        should contain_class('cinder::base').with(
          :verbose         => 'False',
          :sql_connection  => 'mysql://cinder:cinder_pass@127.0.0.1/cinder?charset=utf8',
          :rabbit_password => 'rabbit_pw'
        )
        should contain_class('cinder::api').with_keystone_password('cinder_pass')
        should contain_class('cinder::scheduler')
      end
    end

    context 'when overriding config' do
      let :params do
        default_params.merge(
          :verbose              => 'True',
          :rabbit_password      => 'rabbit_pw2',
          :cinder_user_password => 'foo',
          :cinder_db_password   => 'bar',
          :cinder_db_user       => 'baz',
          :cinder_db_dbname     => 'blah',
          :db_host              => '127.0.0.2'
        )
      end
      it 'should configure cinder using defaults' do
        should contain_class('cinder::base').with(
          :verbose         => 'True',
          :sql_connection  => 'mysql://baz:bar@127.0.0.2/blah?charset=utf8',
          :rabbit_password => 'rabbit_pw2'
        )
        should contain_class('cinder::api').with_keystone_password('foo')
        should contain_class('cinder::scheduler')
      end
    end

  end

end
