require 'spec_helper'

describe 'openstack::nova_common' do

  let :default_params do
    {
      :compute                => false,
      :controller             => false,
      :private_interface      => 'eth0',
      :public_address         => '0.0.0.0',
      :internal_address       => '0.0.0.0',
      :nova_user_password     => 'nova',
      :nova_db_password       => 'nova',
      :db_host                => '127.0.0.1',
      :db_bind_address        => '0.0.0.0',
      :db_account_security    => 'true',
      :db_root_password       => 'sql_pass',
      :rabbit_password        => 'rabbit_pw',
      :rabbit_virtual_host    => '/',
      :quantum                => false,
      :fixed_range            => '10.0.0.0/16',
      :enabled_apis           => 'ec2,osapi_compute,metadata',
      :multi_host             => false
    }
  end

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
    }
  end

  describe "when using default class parameters" do
    let :params do
      default_params
    end
    it {
      should contain_class('nova').with(
        :sql_connection      => 'mysql://nova:nova@127.0.0.1/nova',
        :rabbit_host         => '127.0.0.1',
        :rabbit_userid       => 'nova',
        :rabbit_password     => 'rabbit_pw',
        :rabbit_virtual_host => '/',
        :image_service       => 'nova.image.glance.GlanceImageService',
        :glance_api_servers  => 'localhost:9292',
        :verbose             => 'False'
      )
      should contain_nova_config('multi_host').with( :value => 'False' )
      should contain_nova_config('send_arp_for_ha').with( :value => 'False' )
      should contain_class('nova::api').with({
        :enabled            => true,
        :admin_user         => 'nova',
        :admin_password     => 'nova',
        :auth_host          => '127.0.0.1',
        :enabled_apis       => 'ec2,osapi_compute,metadata',
        :volume_api_class   => 'nova.volume.cinder.API',
        :sync_db            => false
      })
      should contain_class('nova::network').with({
        :enabled            => false,
        :install_service    => false,
        :private_interface  => 'eth0',
        :public_interface   => nil,
        :fixed_range        => '10.0.0.0/16',
        :floating_range     => false,
        :network_manager    => 'nova.network.manager.FlatDHCPManager',
        :config_overrides   => {},
        :create_networks    => false,
      })
    }
  end

  describe "when overriding parameters, but not enabling multi-host or volume management" do
    let :override_params do
      {
        :private_interface   => 'eth1',
        :internal_address    => '127.0.0.1',
        :public_interface    => 'eth2',
        :nova_user_password  => 'nova',
        :rabbit_host         => 'my_host',
        :rabbit_password     => 'my_rabbit_pw',
        :rabbit_virtual_host => '/foo',
        :glance_api_servers  => ['controller:9292'],
        :verbose             => true,
        :multi_host          => false,
      }
    end
    let :params do
      default_params.merge(override_params)
    end
    it do
      should contain_class('nova').with(
        :sql_connection      => 'mysql://nova:nova@127.0.0.1/nova',
        :rabbit_host         => 'my_host',
        :rabbit_userid       => 'nova',
        :rabbit_password     => 'my_rabbit_pw',
        :rabbit_virtual_host => '/foo',
        :image_service       => 'nova.image.glance.GlanceImageService',
        :glance_api_servers  => ['controller:9292'],
        :verbose             => true
      )
      should contain_nova_config('multi_host').with( :value => 'False' )
      should contain_nova_config('send_arp_for_ha').with( :value => 'False' )
      should contain_class('nova::api').with({
        :enabled            => true,
        :admin_user         => 'nova',
        :admin_password     => 'nova',
        :auth_host          => '127.0.0.1',
        :enabled_apis       => 'ec2,osapi_compute,metadata',
        :volume_api_class   => 'nova.volume.cinder.API',
        :sync_db            => false
      })
      should contain_class('nova::network').with({
        :private_interface => 'eth1',
        :public_interface  => 'eth2',
        :create_networks   => false,
        :enabled           => false,
        :install_service   => false
      })
    end
  end
  
  context 'when auto assign floating ip is assigned' do
    let :params do
      default_params.merge(:auto_assign_floating_ip => 'true')
    end
    it { should contain_nova_config('auto_assign_floating_ip').with(:value => 'True')}
  end
  describe 'when quantum is false' do
    describe 'when overriding network params and multi_host is true, controller is true and compute is true' do
      let :params do
        default_params.merge({
          :public_interface => 'eth0',
          :quantum          => false,
          :multi_host       => true,
          :controller       => true,
          :compute          => true
        })
      end
      it 'should configure nova for multi-host, enable network services and seed network' do
        should contain_class('keystone::python')
        should contain_nova_config('multi_host').with(:value => 'True')
        should contain_nova_config('send_arp_for_ha').with( :value => 'True')
        should contain_class('nova::network').with({
          :create_networks   => true,
          :enabled           => true,
          :install_service   => true
        })
      end
    end
    describe 'when overriding network params and multi_host is true, controller is true and compute is false' do
      let :params do
        default_params.merge({
          :public_interface => 'eth0',
          :quantum          => false,
          :multi_host       => true,
          :controller       => true,
          :compute          => false
        })
      end
      it 'should configure nova for multi-host, enable network services and seed network' do
        should contain_class('keystone::python')
        should contain_nova_config('multi_host').with(:value => 'True')
        should contain_nova_config('send_arp_for_ha').with( :value => 'True')
        should contain_class('nova::network').with({
          :create_networks   => true,
          :enabled           => false,
          :install_service   => false
        })
      end
    end
    describe 'when overriding network params and multi_host is true, controller is false and compute is true' do
      let :params do
        default_params.merge({
          :public_interface => 'eth0',
          :quantum          => false,
          :multi_host       => true,
          :controller       => false,
          :compute          => true
        })
      end
      it 'should configure nova for multi-host, enable network services and seed network' do
        should contain_class('keystone::python')
        should contain_nova_config('multi_host').with(:value => 'True')
        should contain_nova_config('send_arp_for_ha').with( :value => 'True')
        should contain_class('nova::network').with({
          :create_networks   => false,
          :enabled           => true,
          :install_service   => true
        })
      end
    end
    describe 'when overriding network params and multi_host is false, controller is true and compute is true' do
      let :params do
        default_params.merge({
          :public_interface => 'eth0',
          :quantum          => false,
          :multi_host       => false,
          :controller       => true,
          :compute          => true
        })
      end
      it 'should configure nova for multi-host, enable network services and seed network' do
        should contain_class('keystone::python')
        should contain_nova_config('multi_host').with(:value => 'False')
        should contain_nova_config('send_arp_for_ha').with( :value => 'False')
        should contain_class('nova::network').with({
          :create_networks   => true,
          :enabled           => true,
          :install_service   => true
        })
      end
    end
    describe 'when overriding network params and multi_host is false, controller is false and compute is true' do
      let :params do
        default_params.merge({
          :public_interface => 'eth0',
          :quantum          => false,
          :multi_host       => false,
          :controller       => false,
          :compute          => true
        })
      end
      it 'should configure nova for multi-host, enable network services and seed network' do
        should contain_class('keystone::python')
        should contain_nova_config('multi_host').with(:value => 'False')
        should contain_nova_config('send_arp_for_ha').with( :value => 'False')
        should contain_class('nova::network').with({
          :create_networks   => false,
          :enabled           => false,
          :install_service   => false
        })
      end
    end
    describe 'when overriding network params and multi_host is false, controller is true and compute is false' do
      let :params do
        default_params.merge({
          :public_interface => 'eth0',
          :quantum          => false,
          :multi_host       => false,
          :controller       => true,
          :compute          => false
        })
      end
      it 'should configure nova for multi-host, enable network services and seed network' do
        should contain_class('keystone::python')
        should contain_nova_config('multi_host').with(:value => 'False')
        should contain_nova_config('send_arp_for_ha').with( :value => 'False')
        should contain_class('nova::network').with({
          :create_networks   => true,
          :enabled           => true,
          :install_service   => true
        })
      end
    end
  end

  describe "when configuring for multi host without a public interface" do
    let :params do
      default_params.merge({
        :multi_host => true
      })
    end

    it {
      expect { should raise_error(Puppet::Error) }
    }
  end
  
  # Database
  context 'database' do

    context 'with unsupported db type' do

      let :params do
        default_params.merge({:db_type => 'sqlite'})
      end

      it do
        expect { subject }.to raise_error(Puppet::Error)
      end

    end
    context 'with default mysql params and controller is true' do

      let :params do
        default_params.merge(
          :enabled    => true,
          :db_type    => 'mysql',
          :quantum    => true,
          :cinder     => true,
          :controller => true
        )
      end

      it 'should configure mysql server' do
        param_value(subject, 'class', 'mysql::server', 'enabled').should be_true
        config_hash = param_value(subject, 'class', 'mysql::server', 'config_hash')
        config_hash['bind_address'].should == '0.0.0.0'
        config_hash['root_password'].should == 'sql_pass'
      end

      it 'should contain openstack db config' do
         should contain_class('keystone::db::mysql').with(
           :user          => 'keystone',
           :password      => 'keystone_pass',
           :dbname        => 'keystone',
           :allowed_hosts => '%'
         )
         should contain_class('glance::db::mysql').with(
           :user          => 'glance',
           :password      => 'glance_pass',
           :dbname        => 'glance',
           :allowed_hosts => '%'
         )
         should contain_class('nova::db::mysql').with(
           :user          => 'nova',
           :password      => 'nova',
           :dbname        => 'nova',
           :allowed_hosts => '%'
         )
         should contain_class('cinder::db::mysql').with(
           :user          => 'cinder',
           :password      => 'cinder_pass',
           :dbname        => 'cinder',
           :allowed_hosts => '%'
         )
         should contain_class('quantum::db::mysql').with(
           :user          => 'quantum',
           :password      => 'quantum_pass',
           :dbname        => 'quantum',
           :allowed_hosts => '%'
         )
      end


      #it { should contain_class('mysql::server::account_security')}

    end

    context 'when controller is true and quantum is false' do
      let :params do
        default_params.merge(
          :quantum => true,
          :controller => true
        )
      end

      it { should_not contain_class('nova::network') }
    end

    context 'when controller is true and cinder and quantum are false' do

      let :params do
        default_params.merge(
          :quantum    => false,
          :cinder     => false,
          :controller => true
        )
      end
      it do
         should contain_class('keystone::db::mysql').with(
           :user          => 'keystone',
           :password      => 'keystone_pass',
           :dbname        => 'keystone',
           :allowed_hosts => '%'
         )
         should contain_class('glance::db::mysql').with(
           :user          => 'glance',
           :password      => 'glance_pass',
           :dbname        => 'glance',
           :allowed_hosts => '%'
         )
         should contain_class('nova::db::mysql').with(
           :user          => 'nova',
           :password      => 'nova',
           :dbname        => 'nova',
           :allowed_hosts => '%'
         )
        should_not contain_class('quantum::db::mysql')
        should_not contain_class('cinder::db::mysql')
      end

    end

    context 'when not controller' do

      let :params do
        default_params.merge(
          {:controller => false}
        )
      end

      ['keystone', 'nova', 'glance', 'cinder', 'quantum'].each do |x|
        it { should_not contain_class("#{x}::db::mysql") }
      end
    end

    context 'when account secutiry is not enabled' do
      let :params do
        default_params.merge(
          {:mysql_account_security => false}
        )
      end

      it { should_not contain_class('mysql::server::account_security')}
    end

  end
  

end
