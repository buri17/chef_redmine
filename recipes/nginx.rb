# Cookbook Name:: redmine
# Recipe:: nginx
#
# Copyright 2012, Oversun-Scalaxy LTD
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

# Nginx configuration
template "/etc/nginx/sites-available/redmine.conf" do
  mode "0644"
  source "redmine.conf.erb"
end

# In case of nginx recipe usage - reload nginx after linking available to enabled
link "/etc/nginx/sites-enabled/redmine.conf" do
  to "/etc/nginx/sites-available/redmine.conf"
  notifies :reload, resources(:service => "nginx")
  only_if { node['nginx'] }
end

link "/etc/nginx/sites-enabled/default" do
  action :delete
  notifies :reload, resources(:service => "nginx")
end
