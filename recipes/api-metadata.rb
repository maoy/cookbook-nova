#
# Cookbook Name:: nova
# Recipe:: api-metadata
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

require "uri"

class ::Chef::Recipe
  include ::Openstack
end

include_recipe "nova::nova-common"

platform_options = node["nova"]["platform"]
if node["nova"]["install_method"] == "git" then
  platform_options = node["nova"]["source_platform"]
end

directory "/var/lock/nova" do
  owner node["nova"]["user"]
  group node["nova"]["group"]
  mode  00700

  action :create
end

# when install from source, we don't need this
if node["nova"]["install_method"] == "package" then
  package "python-keystone" do
    action :upgrade
  end
end

platform_options["nova_api_metadata_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

if node["nova"]["install_method"] == "git" then
  cookbook_file "/etc/init/nova-api-metadata.conf" do
    source "upstart/nova-api-metadata.conf"
    mode 0644
    owner "root"
    group "root"
  end

  cookbook_file "/etc/logrotate.d/nova-api-metadata" do
    source "logrotate.d/nova-api-metadata"
    mode 0644
    owner "root"
    group "root"
  end
end

service "nova-api-metadata" do
  provider Chef::Provider::Service::Upstart
  service_name platform_options["nova_api_metadata_service"]
  supports :status => true, :restart => true
  subscribes :restart, resources("template[/etc/nova/nova.conf]")

  action [:enable, :start]
end

identity_admin_endpoint = endpoint "identity-admin"
keystone_service_role = node["nova"]["keystone_service_chef_role"]
keystone = config_by_role keystone_service_role, "keystone"

auth_uri = ::URI.decode identity_admin_endpoint.to_s
service_pass = service_password "nova"

template "/etc/nova/api-paste.ini" do
  source "api-paste.ini.erb"
  owner  node["nova"]["user"]
  group  node["nova"]["group"]
  mode   00644
  variables(
    :identity_admin_endpoint => identity_admin_endpoint,
    :service_pass => service_pass
  )

  notifies :restart, "service[nova-api-metadata]"
end
