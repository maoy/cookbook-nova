require "spec_helper"

describe "nova::vncproxy" do
  describe "redhat" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "nova::vncproxy"
    end

    it "starts nova vncproxy on boot" do
      expected = "openstack-nova-novncproxy"
      expect(@chef_run).to set_service_to_start_on_boot expected
    end

    it "starts nova consoleauth" do
      expect(@chef_run).to start_service "openstack-nova-console"
    end

    it "starts nova consoleauth on boot" do
      expected = "openstack-nova-console"
      expect(@chef_run).to set_service_to_start_on_boot expected
    end
  end
end
