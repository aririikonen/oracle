#
# Cookbook Name:: oracle
# Recipe:: default
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
## Install logrorate and logrotate config for oracle's alert log.
#



package "logrotate"

# By default, this will rotate the alert_*.log files every week
# and will store 10400 weeks' worth of logs.
cookbook_file "/etc/logrotate.d/oracle-alert-log" do
  source 'oracle-alert-log'
  owner 'root'
  group 'root'
  mode '0644'
end
