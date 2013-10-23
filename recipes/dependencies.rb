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

package "git"

# Installing ruby 1.8.7.
# NOTE: under gusteau and vagrant, we faced this issue in using system ruby:
#   https://github.com/locomote/gusteau/issues/40
package "ruby"
package "rubygems"

# workaround for http://www.redmine.org/issues/8325 (Redmine 1.2.1 requires rails 2.3.11 requires gem <= 1.6
# but no ubuntu rubygems package gives 1.8
execute "export REALLY_GEM_UPDATE_SYSTEM=1; gem update --system 1.6.2" do
  not_if "gem -v && gem -v | grep 1.6"
end

gem_package "bundler"
