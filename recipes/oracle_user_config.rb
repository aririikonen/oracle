#
# Cookbook Name:: oracle
# Recipe:: oracle_user_config
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
## Create and configure the oracle user. 
#


# Create the oracle user.
# The argument to useradd's -g option must be an already existing
# group, else useradd will raise an error.
# Therefore, we must create the oinstall group before we do the oracle user.
group 'oinstall' do
  gid node[:oracle][:user][:gid]
end

user 'oracle' do
  uid node[:oracle][:user][:uid]
  gid node[:oracle][:user][:gid]
  shell node[:oracle][:user][:shell]
  comment 'Oracle Administrator'
  supports :manage_home => true
end

yum_package File.basename(node[:oracle][:user][:shell])

# Configure the oracle user.
# Make it a member of the appropriate supplementary groups, and
# ensure its environment will be set up properly upon login.
node[:oracle][:user][:sup_grps].each_key do |grp|
  group grp do
    gid node[:oracle][:user][:sup_grps][grp]
    members ['oracle']
    append true
  end
end

template "/home/oracle/.profile" do
  action :create_if_missing
  source 'ora_profile.erb'
  owner 'oracle'
  group 'oinstall'
end

# Color setup for ls.
execute 'gen_dir_colors' do
  command '/usr/bin/dircolors -p > /home/oracle/.dir_colors'
  user 'oracle'
  group 'oinstall'
  cwd '/home/oracle'
  creates '/home/oracle/.dir_colors'
  only_if {node[:oracle][:user][:shell] != '/bin/bash'}
end

# Set the oracle user's password.
unless node[:oracle][:user][:pw_set]
  ora_edb_item = Chef::EncryptedDataBagItem.load(node[:oracle][:user][:edb], node[:oracle][:user][:edb_item])
  ora_pw = ora_edb_item['pw']

  # Note that output formatter will display the password on your terminal.
  execute 'change_oracle_user_pw' do
    command "echo oracle:#{ora_pw} | /usr/sbin/chpasswd"
  end
  
  ruby_block 'set_pw_attr' do
    block do
      node.set[:oracle][:user][:pw_set] = true
    end
    action :create
  end
end

# Set resource limits for the oracle user.
cookbook_file '/etc/security/limits.d/oracle.conf' do
  mode '0644'
  source 'ora_limits'
end
