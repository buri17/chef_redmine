# Cookbook Name:: redmine
# Recipe:: default
#
# Copyright 2012, Alex Dergachev
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

# definition of /etc/init.d/unicorn_redmine
service "unicorn_redmine" do
  # required because the init script error codes are wrong
  supports :status => false
  action :nothing
end

# Ensure app-directory is present and have right ownership
directory node['redmine']['app_path'] do
  action :create
  owner "www-data"
  group "www-data"
end

# Checkout redmine codebase from specified git repo
# Note: running git deploy as non-root user will break SSH agent forwarding
git node['redmine']['app_path'] do
  action :checkout
  enable_submodules true
  repository node['redmine']['git_repository']
  revision node['redmine']['git_revision']
end

# Sets ownership of redmine codebase to www-data
bash "fix redmine perms" do
  code "chown -R www-data:www-data #{node['redmine']['app_path']}"
end

# Deploying rvm env autoswitcher to app_path
template "#{node['redmine']['app_path']}/.rvmrc" do
  source ".rvmrc.erb"
  owner "www-data"
  group "www-data"
  mode "0755" # This was missing, probably
end

# Custom force-trust for redmine.app_path/.rvmrc
script "trust_rvmrc" do 
  # FIXME: this silently fails unless .rvmrc is 755
  ## error on `cd /opt/redmine`:  Do you wish to trust this .rvmrc file? (/opt/redmine/.rvmrc)
  interpreter "bash"
  code <<-EOF
  source /etc/profile
  rvm rvmrc trust #{node['redmine']['app_path']}
  EOF
end

# Unicorn w/rvm for redmine init-script
template "/etc/init.d/unicorn_redmine" do
  source "unicorn_init_script.erb"
  owner  "root"
  group  "root"
  mode   "0755" # fixed permissions

  # see http://stackoverflow.com/questions/9938314/chef-how-to-run-a-template-that-creates-a-init-d-script-before-the-service-is-c/9941971#9941971
  notifies :enable, resources(:service => "unicorn_redmine")
end

# Redmine configuration for SCM and mailing
template "#{node['redmine']['app_path']}/config/configuration.yml" do
  source "configuration.yml.erb"
  owner "www-data"
  group "www-data"
  mode  "0644"
end

# Redmine unicorn configuration
template "#{node['redmine']['app_path']}/config/unicorn.rb" do
  source "unicorn.rb.erb"
  owner "www-data"
  group "www-data"
  mode  "0644"
end

# fix ownership for public/plugin_assets due to deployment order
directory "#{node['redmine']['app_path']}/public/plugin_assets" do
  owner "www-data"
  group "www-data"
  mode  "0755"
end

# Install a redmine-specific Gemfile
template "#{node['redmine']['app_path']}/Gemfile" do
  action :create_if_missing
  source "Gemfile.erb"
  owner "www-data"
  group "www-data"
  mode "0755"
end

# Run 'bundle install' to install gems based on Gemfile
rvm_shell "bundle install" do
  ruby_string node['redmine']['ruby']
  cwd node['redmine']['app_path']
  code "bundle install"
end
