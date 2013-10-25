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

# Unicorn w/rvm for redmine init-script
template "/etc/init.d/unicorn_redmine" do
  source "unicorn_init_script.erb"
  owner  "root"
  group  "root"
  mode   "0755" # fixed permissions

  # see http://stackoverflow.com/questions/9938314/chef-how-to-run-a-template-that-creates-a-init-d-script-before-the-service-is-c/9941971#9941971
  notifies :enable, "service[unicorn_redmine]"
  notifies :start, "service[unicorn_redmine]"
  notifies :restart, "service[unicorn_redmine]"
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

  notifies :restart, "service[unicorn_redmine]"
end

# fix ownership for public/plugin_assets due to deployment order
directory "#{node['redmine']['app_path']}/public/plugin_assets" do
  owner "www-data"
  group "www-data"
  mode  "0755"
end

# Install a redmine-specific Gemfile
template "#{node['redmine']['app_path']}/Gemfile" do
  action :create_if_missing  # redmine >= 1.4 comes with own Gemfile
  source "Gemfile.erb"
  variables({
    :rails_version => node['redmine']['rails_version']
  })
  owner "www-data"
  group "www-data"
  mode "0755"
end

# Add our custom gems to Gemfile.local, which redmine's Gemfile supports
template "#{node['redmine']['app_path']}/Gemfile.local" do
  action :create_if_missing
  source "Gemfile.local.erb"
  owner "www-data"
  group "www-data"
  mode "0755"
end

# Redmine database configuration; must be in place before 'bundle install'
# See https://github.com/redmine/redmine/blob/master/Gemfile#L41
template "#{node['redmine']['app_path']}/config/database.yml" do
  source "database.yml.erb"
  owner "www-data"
  group "www-data"
  mode  "0600" #FIXME: are these correct?
end


bash "bundle install" do
  # NOTE: '--without test' is a workaround for this error:
  #  An error occurred while installing rubyzip (1.0.0), and Bundler cannot continue.
  #  Make sure that `gem install rubyzip -v '1.0.0'` succeeds before bundling.
  # rubyzip is required by selenium, which is in the test Gem group
  code "bundle install --without test"

  cwd node['redmine']['app_path']
end
