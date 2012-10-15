#TODO:
# 1. init.d scripts for unicorn_rails service
# 2. [rvm] Prefer user installation over system-wide

# Cookbook Name:: redmine
# Recipe:: dependencies
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

include_recipe "rvm::system_install"

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

