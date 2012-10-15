#TODO:
# 1. init.d scripts for unicorn_rails service
# 2. [rvm] Prefer user installation over system-wide
# Cookbook Name:: redmine
# Recipe:: default
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


# Installing rvm 1.8.7 ruby and creating gemset
rvm_environment node['redmine']['ruby']

# Defining requirements
REQUIRED_GEMS = {
  "rake"    => "0.8.7",
  "rails"   => "2.3.14",
  "rack"    => "1.1.3",
  "unicorn" => nil,
  "rubytree" => "0.5.2"
  }

# Array iteration is necessary since Ruby 1.8.7 Hash.each does not preserve
# insertion order, which was ['unicorn','rack','rake','rails','rubytree'].
# That order caused rack 1.4.1 to be installed as a dependency for unicorn,
# which conflicted with rails 2.3.14 even though rack 1.1.3 was also installed.
REQUIRED_GEMS_ORDERED = [ 'rake', 'rails', 'rack', 'rubytree', 'unicorn']

# Installing gems for rvm environment
REQUIRED_GEMS_ORDERED.each do |gem|
  version = REQUIRED_GEMS[gem]
  rvm_gem gem do
    ruby_string node['redmine']['ruby']
    version version if version
  end
end

# Optional prerequisites for RMagick
if node['redmine']['rmagick'] == "enabled"
  package "libmagick9-dev"
  rvm_gem "rmagick" do
    ruby_string node['redmine']['ruby']
  end
end


# Automatically select and install prerequisites for db support
# according to attributes. Defaults to mysql
case node['redmine']['db']['type']
  when "mysql"
    rvm_gem "mysql" do
      ruby_string node['redmine']['ruby']
    end
    package 'mysql-client'
    package "libmysqlclient-dev"  
  when "postgresql"
    rvm_gem "pg" do
      ruby_string node['redmine']['ruby']
    end
    package "libpq-dev"
end


# Unnicorn for redmine service definition
service "unicorn_redmine" do
  supports :restart => true, :reload => true
  action :nothing
end

# Ensure app-directory is present and have right ownership
directory node['redmine']['app_path'] do
  action :create
  owner "www-data"
  group "www-data"
end

# Exporting defined redmine version from git mirror https://github.com/redmine/redmine
git node['redmine']['app_path'] do
  action :export
  user 'www-data'
  group 'www-data'
  repository "https://github.com/redmine/redmine"
  revision node['redmine']['release_tag']
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

# Redmine database configuration
# TODO: postgresql
template "#{node['redmine']['app_path']}/config/database.yml" do
  source "database.yml.erb"
  owner "www-data"
  group "www-data"
  mode  "0600" #FIXME: are these correct?
end

# fix ownership for public/plugin_assets due to deployment order
directory "#{node['redmine']['app_path']}/public/plugin_assets" do
  owner "www-data"
  group "www-data"
  mode  "0755"
end

# http://www.redmine.org/projects/redmine/wiki/RedmineInstall step 4
rvm_shell "rake_task:generate_session_store" do
  ruby_string node['redmine']['ruby']
  cwd node['redmine']['app_path']
  code "rake generate_session_store"
end

# http://www.redmine.org/projects/redmine/wiki/RedmineInstall step 5 - migrating DB 
rvm_shell "rake_task:db:migrate RAILS_ENV=production" do
  ruby_string node['redmine']['ruby']
  cwd node['redmine']['app_path']
  code "rake db:migrate RAILS_ENV=production"
  notifies [:enable, :start], resources(:service => "unicorn_redmine")

  # not_if takes a block, not a boolean
  not_if {node['redmine']['db'].any?{|key, value| value == ""}}
end

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
