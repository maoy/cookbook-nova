require "spec_helper"

describe "nova::network" do
  describe "ubuntu" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @chef_run.converge "nova::network"
    end

    expect_runs_nova_common_recipe

    it "installs nova network packages" do
      expect(@chef_run).to upgrade_package "iptables"
      expect(@chef_run).to upgrade_package "nova-network"
    end

    it "starts nova network on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "nova-network"
    end
  end
end
