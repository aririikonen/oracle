#
# Cookbook Name:: oracle
# Recipe:: clibin
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
## Install Oracle Client binaries.
#

# Fixing an issue with oraInventory, if it already exists from a RDBMS
# install.
file "#{node[:oracle][:ora_inventory]}/ContentsXML/comps.xml" do
  only_if { File.directory?("#{node[:oracle][:ora_inventory]}/ContentsXML" ) }
  mode '00664'
end
file "#{node[:oracle][:ora_inventory]}/ContentsXML/libs.xml" do
  only_if { File.directory?("#{node[:oracle][:ora_inventory]}/ContentsXML" ) }
  mode '00664'
end

# Creating $ORACLE_BASE and the install directory.
[node[:oracle][:ora_base], node[:oracle][:client][:install_dir]].each do |dir|
  directory dir do
    owner 'oracli'
    group 'oracli'
    mode '0755'
    action :create
  end
end

# We need unzip to expand the install files later on.
yum_package 'unzip'

# Fetching the install media with curl and unzipping them.
# We run two resources to avoid chef-client's runaway memory usage resulting
# in the kernel killing it.
node[:oracle][:client][:install_files].each do |zip_file|
  execute "fetch_media_11R23cli-#{zip_file}" do
    command "curl -kO #{zip_file}"
    user "oracli"
    group 'oracli'
    cwd node[:oracle][:client][:install_dir]
  end

  execute "unzip_media_11R23cli-#{zip_file}" do
    command "unzip #{File.basename(zip_file)}"
    user "oracli"
    group 'oracli'
    cwd node[:oracle][:client][:install_dir]
  end

# Fixed a compile error while installing the client
  execute "sed_client_cvu_config" do
    command "sed -i.bak 's/OEL4/OEL6/' cvu_config"
    user "oracli"
    group 'oracli'
    cwd "#{node[:oracle][:client][:install_dir]}/client/stage/cvu/cv/admin"
  end
end

# This oraInst.loc specifies the standard oraInventory location.
file "#{node[:oracle][:ora_base]}/oraInst.loc" do
  owner "oracli"
  group 'oinstall'
  content "inst_group=oinstall\ninventory_loc=/opt/oraInventory"
end

directory node[:oracle][:ora_inventory] do
  owner 'oracli'
  group 'oinstall'
  mode '0755'
  action :create
end

# Filesystem template.
template "#{node[:oracle][:client][:install_dir]}/cli11R23.rsp" do
  owner 'oracli'
  group 'oracli'
  mode '0644'
end

# Running the installer. We have to run it with sudo because
# the installer fails if the user isn't a member of the dba group,
# and Chef itself doesn't provide a way to call setgroups(2).
# We also ignore an exit status of 6: runInstaller fails to realise that
# prerequisites are indeed met on CentOS 6.4.
bash 'run_client_installer' do
  cwd "#{node[:oracle][:client][:install_dir]}/client"
  environment (node[:oracle][:client][:env])
  code "sudo -Eu oracli ./runInstaller -showProgress -silent -waitforcompletion -ignoreSysPrereqs -responseFile #{node[:oracle][:client][:install_dir]}/cli11R23.rsp -invPtrLoc #{node[:oracle][:ora_base]}/oraInst.loc"
  returns [0, 6]
end

execute 'root.sh_client' do
  command "#{node[:oracle][:client][:ora_home]}/root.sh"
end

execute 'install_dir_cleanup' do
  command "rm -rf #{node[:oracle][:client][:install_dir]}/*"
end

# Set a flag to indicate the rdbms has been successfully installed.
ruby_block 'set_client_install_flag' do
  block do
    node.set[:oracle][:client][:is_installed] = true
  end
  action :create
end

# Creating the tnsnames.ora file. Modify it accordingly to the
# target database.
cookbook_file "#{node[:oracle][:client][:ora_home]}/network/admin/tnsnames.ora" do
  owner 'oracli'
  group 'oracli'
  mode '0644'
end

# Install sqlplus startup config file.
cookbook_file "#{node[:oracle][:client][:ora_home]}/sqlplus/admin/glogin.sql" do
  owner 'oracli'
  group 'oracli'
  mode '0644'
end
