#
# Cookbook Name:: oracle
# Recipe:: get_cli_version
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
## Set the client version attributes.
#

# Word of warning: the format of the strings output by 'opatch lsinventory' may
# change in future, which means the code below will have to be updated accordingly.
#
# Here's an example of the string we have to process:
# 14727310   14727310  Fri Apr 05 16:49:37 EEST 2013  DATABASE PATCH SET UPDATE 11.2.0.3.5 (INCLUDES CPU
# We need to extract: 
#  - the patch number: 14727310  in our example (use the second field; the first one isn't reliable)
#  - the timestamp: Fri Apr 05 16:49:37 EEST 2013 in our example
#  - the version string: 11.2.0.3.5 in our example.
ruby_block 'set_client_version_attr' do
  block do
    patch_info = %x(sudo -u oracle #{node[:oracle][:client][:ora_home]}/OPatch/opatch lsinventory -bugs_fixed | grep -E '(#{node[:oracle][:rdbms][:latest_patch][:dirname]}) {3}\\1.* DATABASE PATCH SET UPDATE')
    node.set[:oracle][:client][:install_info][:patch_nr] = patch_info[/(?!^.+)\b\d+/]
    node.set[:oracle][:client][:install_info][:timestamp_str] = patch_info[/[MTWFS][a-z]+ [JFMASOND][a-z]+ \d{2} \d{2}:\d{2}:\d{2} [A-Z]+ \d{4}/]
    node.set[:oracle][:client][:install_info][:version_str] = patch_info[/(\d+\.)+\d+/]
  end
  action :nothing
end
