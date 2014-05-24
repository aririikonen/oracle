#
# Cookbook Name:: oracle
# Recipe:: dbbin
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
## Install Oracle RDBMS binaries.
#

# Fixing an issue with oraInventory, if it already exists from a client
# install.
file "#{node[:oracle][:ora_inventory]}/ContentsXML/comps.xml" do
  only_if { File.directory?("#{node[:oracle][:ora_inventory]}/ContentsXML" ) }
  mode '00664'
end
file "#{node[:oracle][:ora_inventory]}/ContentsXML/libs.xml" do
  only_if { File.directory?("#{node[:oracle][:ora_inventory]}/ContentsXML" ) }
  mode '00664'
end
# If client is installed first, changing group ownership to avoid
# a permission issue.
execute "chown_back_to_oinstall" do
  only_if { File.directory?("#{node[:oracle][:ora_inventory]}/ContentsXML" ) }
  command "chown -R oracle:oinstall *"
  cwd node[:oracle][:ora_inventory]
end

# Creating $ORACLE_BASE and the install directory.
[node[:oracle][:ora_base], node[:oracle][:rdbms][:install_dir]].each do |dir|
  directory dir do
    owner 'oracle'
    group 'oinstall'
    mode '0755'
    action :create
  end
end

# We need unzip to expand the install files later on.
yum_package 'unzip'

# Fetching the install media with curl and unzipping them.
# We run two resources to avoid chef-client's runaway memory usage resulting
# in the kernel killing it.
node[:oracle][:rdbms][:install_files].each do |zip_file|
  execute "fetch_oracle_media_#{zip_file}" do
    command "curl -kO #{zip_file}"
    user "oracle"
    group 'oinstall'
    cwd node[:oracle][:rdbms][:install_dir]
  end

  execute "unzip_oracle_media_#{zip_file}" do
    command "unzip #{File.basename(zip_file)}"
    user "oracle"
    group 'oinstall'
    cwd node[:oracle][:rdbms][:install_dir]
  end
end

# This oraInst.loc specifies the standard oraInventory location.
file "#{node[:oracle][:ora_base]}/oraInst.loc" do
  owner "oracle"
  group 'oinstall'
  content "inst_group=oinstall\ninventory_loc=/opt/oraInventory"
end

directory node[:oracle][:ora_inventory] do
  owner 'oracle'
  group 'oinstall'
  mode '0755'
  action :create
end

# Filesystem template.
template "#{node[:oracle][:rdbms][:install_dir]}/db11R23.rsp" do
  owner 'oracle'
  group 'oinstall'
  mode '0644'
end

# Filesystem template.
template "#{node[:oracle][:rdbms][:install_dir]}/db12c.rsp" do
  owner 'oracle'
  group 'oinstall'
  mode '0644'
end

# Running the installer. We have to run it with sudo because
# the installer fails if the user isn't a member of the dba group,
# and Chef itself doesn't provide a way to call setgroups(2).
# We also ignore an exit status of 6: runInstaller fails to realise that
# prerequisites are indeed met on CentOS 6.4.

if node[:oracle][:rdbms][:dbbin_version] == "11g"
 
  bash 'run_rdbms_installer' do
    cwd "#{node[:oracle][:rdbms][:install_dir]}/database"
    environment (node[:oracle][:rdbms][:env])
    code "sudo -Eu oracle ./runInstaller -showProgress -silent -waitforcompletion -ignoreSysPrereqs -responseFile #{node[:oracle][:rdbms][:install_dir]}/db11R23.rsp -invPtrLoc #{node[:oracle][:ora_base]}/oraInst.loc"
    returns [0, 6]
  end

  execute 'root.sh_rdbms' do
    command "#{node[:oracle][:rdbms][:ora_home]}/root.sh"
  end
 
  template "#{node[:oracle][:rdbms][:ora_home]}/network/admin/listener.ora" do
    owner 'oracle'
    group 'oinstall'
    mode '0644'
  end
  # Starting listener 
  execute 'start_listener' do
    command "#{node[:oracle][:rdbms][:ora_home]}/bin/lsnrctl start"
    user 'oracle'
    group 'oinstall'
    environment (node[:oracle][:rdbms][:env])
  end
 
  # Install sqlplus startup config file.
  cookbook_file "#{node[:oracle][:rdbms][:ora_home]}/sqlplus/admin/glogin.sql" do
    owner 'oracle'
    group 'oinstall'
    mode '0644'
  end

  template '/etc/init.d/oracle' do
    source 'ora_init_script.erb'
    mode '0755'
  end

else
 
  bash 'run_rdbms_installer' do
    cwd "#{node[:oracle][:rdbms][:install_dir]}/database"
    environment (node[:oracle][:rdbms][:env_12c])
    code "sudo -Eu oracle ./runInstaller -showProgress -silent -waitforcompletion -ignoreSysPrereqs -responseFile #{node[:oracle][:rdbms][:install_dir]}/db12c.rsp -invPtrLoc #{node[:oracle][:ora_base]}/oraInst.loc"
    returns [0, 6]
  end
 
  execute 'root.sh_rdbms' do
    command "#{node[:oracle][:rdbms][:ora_home_12c]}/root.sh"
  end
 
  # Commented out to get DBEXPRESS work out of the box
  #template "#{node[:oracle][:rdbms][:ora_home_12c]}/network/admin/listener.ora" do
  #  owner 'oracle'
  #  group 'oinstall'
  #  mode '0644'
  #end
 
  execute 'start_listener' do
    command "#{node[:oracle][:rdbms][:ora_home_12c]}/bin/lsnrctl start"
    user 'oracle'
    group 'oinstall'
    environment (node[:oracle][:rdbms][:env_12c])
  end
 
  # Install sqlplus startup config file.
  cookbook_file "#{node[:oracle][:rdbms][:ora_home_12c]}/sqlplus/admin/glogin.sql" do
    owner 'oracle'
    group 'oinstall'
    mode '0644'
  end

  template '/etc/init.d/oracle' do
    source 'ora_12c_init_script.erb'
    mode '0755'
  end

end

execute 'install_dir_cleanup' do
  command "rm -rf #{node[:oracle][:rdbms][:install_dir]}/*"
end

service 'oracle' do
  action :enable
end

# Set a flag to indicate the rdbms has been successfully installed.
ruby_block 'set_rdbms_install_flag' do
  block do
    node.set[:oracle][:rdbms][:is_installed] = true
  end
  action :create
end
