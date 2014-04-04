#
# Cookbook Name:: oracle
# Recipe:: oracli_user_config
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
#
## Create and configure the oracle client user. 
#


# Create the oracli user.
# The argument to useradd's -g option must be an already existing
# group, else useradd will raise an error.
# Therefore, we must create the oinstall group before we do the oracli user.
group 'oracli' do
  gid node[:oracle][:cliuser][:gid]
end

user 'oracli' do
  uid node[:oracle][:cliuser][:uid]
  gid node[:oracle][:cliuser][:gid]
  shell node[:oracle][:cliuser][:shell]
  comment 'Oracle Administrator'
  supports :manage_home => true
end

yum_package File.basename(node[:oracle][:cliuser][:shell])

# Configure the oracli user.
# Make it a member of the appropriate supplementary groups, and
# ensure its environment will be set up properly upon login.
node[:oracle][:cliuser][:sup_grps].each_key do |grp|
  group grp do
    gid node[:oracle][:cliuser][:sup_grps][grp]
    members ['oracli']
    append true
  end
end

template "/home/oracli/.profile" do
  action :create_if_missing
  source 'oracli_profile.erb'
  owner 'oracli'
  group 'oracli'
end

# Color setup for ls.
execute 'gen_dir_colors' do
  command '/usr/bin/dircolors -p > /home/oracli/.dir_colors'
  user 'oracli'
  group 'oracli'
  cwd '/home/oracli'
  creates '/home/oracli/.dir_colors'
  only_if {node[:oracle][:cliuser][:shell] != '/bin/bash'}
end

# Set the oracli user's password.
unless node[:oracle][:cliuser][:pw_set]
  ora_edb_item = Chef::EncryptedDataBagItem.load(node[:oracle][:cliuser][:edb], node[:oracle][:cliuser][:edb_item])
  ora_pw = ora_edb_item['pw']

  # Note that output formatter will display the password on your terminal.
  execute 'change_oracli_user_pw' do
    command "echo oracli:#{ora_pw} | /usr/sbin/chpasswd"
  end
  
  ruby_block 'set_pw_attr' do
    block do
      node.set[:oracle][:cliuser][:pw_set] = true
    end
    action :create
  end
end

# Set resource limits for the oracli user.
cookbook_file '/etc/security/limits.d/oracli.conf' do
  mode '0644'
  source 'ora_cli_limits'
end
