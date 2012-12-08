require 'spec_helper'

describe 'openstack::nova::controller' do

  # minimum set of default parameters
  let :default_params do
    {
      :public_address             => '0.0.0.0',
      :quantum                    => false,
      :quantum_user_password      => 'quantum_pass',
      :rabbit_user                => 'nova',
      :rabbit_password            => 'rabbit_pw',
      :rabbit_virtual_host        => '/',
      :vnc_enabled                => true,
      :keystone_host              => '127.0.0.1',
      :verbose                    => 'False',
      :enabled                    => true, 
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


  context 'config for nova controller' do

    context 'with default params' do
      it 'should contain enabled nova services' do
        should contain_class('nova::rabbitmq').with(
          :userid       => 'nova',
          :password     => 'rabbit_pw',
          :virtual_host => '/',
          :enabled      => true
        )
        should contain_class('nova::cert').with(:enabled => true)
        should contain_class('nova::consoleauth').with(:enabled => true)
        should contain_class('nova::objectstore').with(:enabled => true)
        should contain_class('nova::scheduler').with(:enabled => true)
        should contain_class('nova::vncproxy').with(
          :host     => '0.0.0.0',
          :enabled  => true
        )
        should_not contain_class('quantum::server')
      end
    end
    context 'when not enabled' do
      let :params do
        default_params.merge(:enabled => false)
      end
      it 'should disable everything' do
        should contain_class('nova::rabbitmq').with(:enabled => false)
        should contain_class('nova::cert').with(:enabled => false)
        should contain_class('nova::consoleauth').with(:enabled => false)
        should contain_class('nova::scheduler').with(:enabled => false)
        should contain_class('nova::objectstore').with(:enabled => false)
        should contain_class('nova::vncproxy').with(:enabled => false)
      end
    end
  end

end
