#TODO:
# 1. init.d scripts for unicorn_rails service
# 2. [rvm] Prefer user installation over system-wide

# Cookbook Name:: redmine
# Recipe:: database
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

# see https://github.com/opscode-cookbooks/mysql#usage
include_recipe "mysql::ruby"

mysql_root_connection_info = {
  :host => "localhost",
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

# create a mysql database for redmine
mysql_database node['redmine']['db']['db_name'] do
  connection mysql_root_connection_info
  action :create
end

# create a mysql user for redmine
mysql_database_user node['redmine']['db']['db_user'] do
  action        :create
  password      node['redmine']['db']['db_pass']
  connection    mysql_root_connection_info
end

# grant all privileges on the newly created DB to the redmine user
mysql_database_user node['redmine']['db']['db_user'] do
  action          :grant
  password        node['redmine']['db']['db_pass']
  database_name   node['redmine']['db']['db_name']
  host            node['redmine']['db']['db_host']
  connection      mysql_root_connection_info
end

# Redmine database configuration
# TODO: postgresql
template "#{node['redmine']['app_path']}/config/database.yml" do
  source "database.yml.erb"
  owner "www-data"
  group "www-data"
  mode  "0600" #FIXME: are these correct?
end

# http://www.redmine.org/projects/redmine/wiki/RedmineInstall step 5
rvm_shell "rake_task:generate_session_store" do
  ruby_string node['redmine']['ruby']
  cwd node['redmine']['app_path']

  #NOTE: for redmine 2.x it should be `rake generate_secret_token`
  # http://www.redmine.org/projects/redmine/wiki/RedmineInstall#Ruby-38-Ruby-on-Rails-38-Rack
  code "rake generate_session_store"
end

# http://www.redmine.org/projects/redmine/wiki/RedmineInstall step 6 - migrating DB 
# creates default super-user 'admin' with password 'admin'
rvm_shell "rake_task:db:migrate" do
  ruby_string node['redmine']['ruby']
  cwd node['redmine']['app_path']
  code "rake db:migrate RAILS_ENV=production"
end

# http://www.redmine.org/projects/redmine/wiki/RedmineInstall step 7 - default roles, trackers
rvm_shell "rake_task:redmine:load_default_data" do
  ruby_string node['redmine']['ruby']
  cwd node['redmine']['app_path']

  # see http://www.redmine.org/issues/2847 for REDMINE_LANG info
  code "rake redmine:load_default_data REDMINE_LANG=en RAILS_ENV=production"
end

# if requested in redmine['db']['load_sql_file'], load database from file
bash "load redmine database dump" do
  # x = {
  #   'db_user' => "redmine",
  #   'db_pass' => "redmineDbPass",
  #   'load_sql_file' => "/vagrant/redmine_prod.sql",
  #   'db_name' => "redmine_prod"
  # }
  x = node['redmine']['db']
  code "cat #{x['load_sql_file']} | mysql -u #{x['db_user']} -p#{x['db_pass']} #{x['db_name']} "
  only_if do
   x['load_sql_file'] && File.exists?(x['load_sql_file'])
  end
end

# Start unicorn (notifies doesnt seem to work)
service "unicorn_redmine" do
  action :start
end
