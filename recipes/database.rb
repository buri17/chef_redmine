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

  #TODO: for redmine 2.x it should be `rake generate_secret_token`
  # see lib/tasks/initializers.rake
  code "rake generate_session_store"
end

# expression to check if DB is empty. We assume that if the settings table exists, nonempty.

db_user = node['redmine']['db']['db_user']
db_pass = node['redmine']['db']['db_pass']
db_name = node['redmine']['db']['db_name']
mysql_client_cmd = "mysql -u #{db_user} -p#{db_pass} #{db_name}"
mysql_empty_check_cmd = "echo 'SHOW TABLES' | #{mysql_client_cmd} | wc -l | xargs test 0 -eq"

# if requested in redmine['db']['load_sql_file'], load database from SQL
bash "load redmine database dump" do
  load_sql_file = node['redmine']['db']['load_sql_file']

  # 'zless FILE | CMD' is equivalent to 'zcat FILE | CMD' but supports plain-text FILEs
  code "zless #{load_sql_file} | #{mysql_client_cmd}"
  # Note: quotes are important since load_sql_file might be nil
  only_if "test -f '#{load_sql_file}' && #{mysql_empty_check_cmd}"
end

# http://www.redmine.org/projects/redmine/wiki/RedmineInstall step 6 - migrating DB 
# run plugin migrations, http://www.redmine.org/projects/redmine/wiki/Plugins
# http://www.redmine.org/projects/redmine/wiki/RedmineInstall step 7 - default roles, trackers
# creates default super-user 'admin' with password 'admin'
rvm_shell "rake_task: db:migrate and other initialization" do

  rm_1x_file = "#{node['redmine']['app_path']}/lib/tasks/migrate_plugins.rake" 
  plugin_rake_task = File.exists?(rm_1x_file) ? "db:migrate:plugins" : "redmine:plugins:migrate"

  ruby_string node['redmine']['ruby']
  cwd node['redmine']['app_path']
  code <<-EOH
    rake db:migrate RAILS_ENV=production
    rake #{plugin_rake_task} RAILS_ENV=production
    rake redmine:load_default_data REDMINE_LANG=en RAILS_ENV=production
  EOH

  only_if "#{mysql_empty_check_cmd}"
end

# (Re-)generates db/schema.rb, which should have been created by db:migrate.
# Only necessary if DB was loaded from SQL file, or after db:migrate:plugins due to bug
# See http://www.redmine.org/issues/11299
rvm_shell "rake_task:db:schema:dump" do
  ruby_string node['redmine']['ruby']
  cwd node['redmine']['app_path']
  code "rake db:schema:dump RAILS_ENV=production"
end

# Start unicorn (notifies doesnt seem to work)
service "unicorn_redmine" do
  action :start
end
