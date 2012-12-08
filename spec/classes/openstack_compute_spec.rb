require 'spec_helper'

describe 'openstack::compute' do

  let :default_params do
    {
      :internal_address      => '0.0.0.0',
      :nova_user_password    => 'nova_pass',
      :rabbit_password       => 'rabbit_pw',
      :rabbit_virtual_host   => '/',
      :cinder_sql_connection => 'mysql://user:pass@host/dbname/',
      :quantum               => false,
      :vnc_enabled           => true
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
      should contain_class('nova::compute').with(
        :enabled                        => true,
        :vnc_enabled                    => true,
        :vncserver_proxyclient_address  => '0.0.0.0',
        :vncproxy_host                  => false
      )
      should contain_class('nova::compute::libvirt').with(
        :libvirt_type     => 'kvm',
        :vncserver_listen => '0.0.0.0'
      )
    }
  end

  describe "when overriding parameters, but not enabling volume management" do
    let :override_params do
      {
        :internal_address    => '127.0.0.1',
        :nova_user_password  => 'nova_pass',
        :rabbit_host         => 'my_host',
        :rabbit_password     => 'my_rabbit_pw',
        :rabbit_user         => 'my_rabbit_user',
        :rabbit_virtual_host => '/foo',
        :libvirt_type        => 'qemu',
        :vncproxy_host       => '127.0.0.2',
        :vnc_enabled         => true,
        :verbose             => true,
      }
    end
    let :params do
      default_params.merge(override_params)
    end
    it do
      should contain_class('nova::compute').with(
        :enabled                        => true,
        :vnc_enabled                    => true,
        :vncserver_proxyclient_address  => '127.0.0.1',
        :vncproxy_host                  => '127.0.0.2'
      )
      should contain_class('nova::compute::libvirt').with(
        :libvirt_type     => 'qemu',
        :vncserver_listen => '127.0.0.1'
      )
    end
  end

  describe "when enabling volume management" do
    let :params do
      default_params.merge({
        :manage_volumes => true
      })
    end

  end

end
