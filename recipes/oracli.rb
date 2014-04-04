#
# Cookbook Name:: oracle
# Recipe:: oracli
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
## Configure Oracle client user, install the Oracle Client's dependencies,
## configure kernel parameters, install the binaries and apply latest patch.
#


# Set up and configure the oracle client user.
include_recipe 'oracle::oracli_user_config'

# Install dependencies and configure kernel parameters.
include_recipe 'oracle::deps_cli_install'
include_recipe 'oracle::kernel_params'

# Baseline install for Oracle client + latest patch.
include_recipe 'oracle::clibin' unless node[:oracle][:client][:is_installed]
include_recipe 'oracle::cli_latest_patch' unless node[:oracle][:client][:latest_patch][:is_installed]
