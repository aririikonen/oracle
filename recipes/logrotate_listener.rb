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
## Install logrotate and logrorate config for the oracle listener's log.
#


package "logrotate"

# By default, this will rotate the listener.log files every week
# and will keep the rotated logs for 5 weeks.
cookbook_file "/etc/logrotate.d/oracle-listener" do
  source 'oracle-listener'
  owner 'root'
  group 'root'
  mode '0644'
end
