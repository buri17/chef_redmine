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


# Redmine database configuration
# TODO: postgresql
template "#{node['redmine']['app_path']}/config/database.yml" do
  source "database.yml.erb"
  owner "www-data"
  group "www-data"
  mode  "0600" #FIXME: are these correct?
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

  # not_if takes a block, not a boolean
  not_if {node['redmine']['db'].any?{|key, value| value == ""}}
end

# Start unicorn (notifies doesnt seem to work)
service "unicorn_redmine" do
  action :start
end
