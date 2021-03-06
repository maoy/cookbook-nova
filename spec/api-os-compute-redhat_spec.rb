require "spec_helper"

describe "nova::api-os-compute" do
  describe "redhat" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "nova::api-os-compute"
    end

    it "installs openstack api packages" do
      expect(@chef_run).to upgrade_package "openstack-nova-api"
    end

    it "starts openstack api on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "openstack-nova-api"
    end
  end
end
