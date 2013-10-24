# Cookbook Name:: redmine
# Attributes:: redmine
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

default['redmine'] = {
  'git_revision' => "1.3.3",
  'git_repository' => "https://github.com/redmine/redmine",
  'app_path' => "/opt/redmine/",
  'app_server_name' => 'redmine',
  'unicorn_conf' => {
    'pid' => "/tmp/pids/unicorn.pid",
    'sock' => "/tmp/sockets/unicorn.sock",
    'error_log' => "unicorn.error.log",
    'access_log' => "unicorn.access.log"
    },
  'db' => {
    'rails_env' => "development",
    'db_name' => "redmine",
    'db_user' => "redmine",
    'db_pass' => "redMinePass",
    'db_host' => "localhost",
    'load_sql_file' => nil
  },
  'rmagick' => "disabled",
  'nginx_filenames' => ["redmine.conf"],
  'nginx_listen' => "*:80 default_server"
}

# redmine 1.2.x requires rails 2.3.11, 1.3.x requires rails 2.3.14, 1.4+ comes with own Gemfiles
default['redmine']['rails_version'] = node['redmine']['git_revision'].match(/^1.3/) ? '2.3.14' : '2.3.11'
