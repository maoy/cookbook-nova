#
# Cookbook Name:: nova
# Recipe:: compute
#
# Copyright 2012, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class ::Chef::Recipe
  include ::Openstack
end

include_recipe "nova::nova-common"
#include_recipe "nova::api-metadata"
#include_recipe "nova::network"

platform_options = node["nova"]["platform"]
if node["nova"]["install_method"] == "git" then
  platform_options = node["nova"]["source_platform"]
end

nova_compute_packages = platform_options["nova_compute_packages"]

if node["nova"]["install_method"] == "package" then
  if platform?(%w(ubuntu))
    if node["nova"]["libvirt"]["virt_type"] == "kvm"
      nova_compute_packages << "nova-compute-kvm"
    elsif node["nova"]["libvirt"]["virt_type"] == "qemu"
      nova_compute_packages << "nova-compute-qemu"
    end
  end
else
  # install from source
  if platform?(%w(ubuntu))
    if node["nova"]["libvirt"]["virt_type"] == "kvm"
      nova_compute_packages << "kvm"
    elsif node["nova"]["libvirt"]["virt_type"] == "qemu"
      nova_compute_packages << "qemu"
    end
  end
end

nova_compute_packages.each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

if node["nova"]["servicegroup_driver"] == "zk" then
  package "python-zookeeper" do
    action :upgrade
  end

  bash "install evzookeeper" do
    cmd "pip install evzookeeper"
  end
end

if node["nova"]["install_method"] == "git" then
  cookbook_file "/etc/init/nova-compute.conf" do
    source "upstart/nova-compute.conf"
    mode 0644
    owner "root"
    group "root"
  end

  cookbook_file "/etc/logrotate.d/nova-compute" do
    source "logrotate.d/nova-compute"
    mode 0644
    owner "root"
    group "root"
  end
end

cookbook_file "/etc/nova/nova-compute.conf" do
  source "nova-compute.conf"
  mode   00644

  action :create
end

# run libvirt before nova-compute
include_recipe "nova::libvirt"

service "nova-compute" do
  #Note(maoy): without this provider, start action doesn't work on Ubuntu
  provider Chef::Provider::Service::Upstart
  service_name platform_options["nova_compute_service"]
  supports :status => true, :restart => true
  subscribes :restart, resources("template[/etc/nova/nova.conf]")

  action [:enable, :start]
end

