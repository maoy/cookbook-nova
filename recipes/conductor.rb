#
# Cookbook Name:: nova
# Recipe:: conductor
#
# Copyright 2013,  AT&T, Yun Mao <yunmao@gmail.com>.
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

platform_options["nova_conductor_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

if node["nova"]["install_method"] == "git" then
  cookbook_file "/etc/init/nova-conductor.conf" do
    source "upstart/nova-conductor.conf"
    mode 0644
    owner "root"
    group "root"
    only_if { node["nova"]["release"] >= "grizzly" }
  end
end

service "nova-conductor" do
  provider Chef::Provider::Service::Upstart
  service_name platform_options["nova_conductor_service"]
  supports :status => true, :restart => true
  subscribes :restart, resources("template[/etc/nova/nova.conf]")

  action [:enable, :start]
  only_if { node["nova"]["release"] >= "grizzly" }
end
