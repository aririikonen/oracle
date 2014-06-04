#
# Cookbook Name:: oracle
# Recipe:: ora_os_setup
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

# Configure Oracle user, install the RDBMS's dependencies, configure
# kernel parameters.

# Set up and configure the oracle user.
include_recipe 'oracle::oracle_user_config'

## Install dependencies and configure kernel parameters.
# Node attribute changes for 12c, if default[:oracle][:rdbms][:dbbin_version] is set to 12c
if node[:oracle][:rdbms][:dbbin_version] == "12c"
  node.set[:oracle][:rdbms][:deps] = node[:oracle][:rdbms][:deps_12c]
  include_recipe 'oracle::deps_install'
else
  include_recipe 'oracle::deps_install'
end

# Setting up kernel parameters
include_recipe 'oracle::kernel_params'
