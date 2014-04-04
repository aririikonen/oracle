#
# Cookbook Name:: oracle
# Recipe:: cli_latest_patch
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
## Install latest patch for Oracle Client.
#


unless node[:oracle][:client][:latest_patch][:is_installed]

  # Fetching the latest 11.2.0.3.0 patch media with curl.
  # We use curl instead of wget because the latter caused Chef Client's
  # Memory usage to balloon until the OS killed it.
  bash 'fetch_latest_patch_media_11R23' do
    user "oracli"
    group 'oinstall'
    cwd node[:oracle][:client][:install_dir]
    code <<-EOH
    curl -kO #{node[:oracle][:client][:latest_patch][:url]}
    curl -kO #{node[:oracle][:client][:opatch_update_url]}
    unzip #{File.basename(node[:oracle][:client][:latest_patch][:url])}
    EOH
  end

  # Setting up OPatch.
  bash 'patch_client_opatch' do
    user 'oracli'
    group 'oracli'
    cwd node[:oracle][:client][:ora_home]
    code <<-EOH3
    rm -rf OPatch.OLD
    mv OPatch OPatch.OLD
    unzip #{node[:oracle][:client][:install_dir]}/#{File.basename(node[:oracle][:client][:opatch_update_url])}
    EOH3
  end
  
  # Making sure ocm.rsp response file is present.
  if !node[:oracle][:client][:response_file_url].empty?
    execute "fetch_response_file" do
      command "curl -kO #{node[:oracle][:client][:response_file_url]}"
      user "oracli"
      group 'oracli'
      cwd node[:oracle][:client][:install_dir]
    end
  else
    execute 'gen_response_file' do
      command "echo | ./OPatch/ocm/bin/emocmrsp -output ./ocm.rsp foo bar && chmod 0644 ./ocm.rsp"
      user "oracli"
      group 'oracli'
      cwd node[:oracle][:client][:ora_home]
    end
  end

  # Apply latest patch.
  bash 'apply_latest_patch_client' do
    user "oracli"
    group 'oinstall'
    cwd "#{node[:oracle][:client][:install_dir]}/#{node[:oracle][:client][:latest_patch][:dirname]}"
    environment (node[:oracle][:client][:env])
    code "#{node[:oracle][:client][:ora_home]}/OPatch/opatch apply -silent -ocmrf #{node[:oracle][:client][:ora_home]}/ocm.rsp"
    notifies :create, "ruby_block[set_latest_patch_install_flag]", :immediately
    notifies :create, "ruby_block[set_client_version_attr]", :immediately
  end
  
  # Set the rdbms version attribute.
  include_recipe 'oracle::get_cli_version'
    
  # Set flag indicating latest patch has been applied.
  ruby_block 'set_latest_patch_install_flag' do
    block do
      node.set[:oracle][:client][:latest_patch][:is_installed] = true
    end
    action :nothing
  end

  # Cleaning up the downloaded latest patch files
  execute 'install_dir_client_cleanup_lp' do
    command "rm -rf #{node[:oracle][:client][:install_dir]}/*"
  end
end 
