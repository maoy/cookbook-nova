require "spec_helper"

describe "nova::nova-cert" do
  describe "ubuntu" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @chef_run.converge "nova::nova-cert"
    end

    expect_runs_nova_common_recipe

    it "installs nova cert packages" do
      expect(@chef_run).to upgrade_package "nova-cert"
    end

    it "starts nova cert on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "nova-cert"
    end
  end
end
