#
# Cookbook Name:: oracle
# Recipe:: createdb
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
## Create Oracle databases.
#

directory node[:oracle][:rdbms][:dbs_root] do
  owner 'oracle'
  group 'oinstall'
  mode '0755'
end

# createdb.rb uses this database template.
template "#{node[:oracle][:rdbms][:ora_home]}/assistants/dbca/templates/default_template.dbt" do
  owner 'oracle'
  group 'oinstall'
  mode '0644'
end

# Optional database template with more db options.
template "#{node[:oracle][:rdbms][:ora_home]}/assistants/dbca/templates/midrange_template.dbt" do
  owner 'oracle'
  group 'oinstall'
  mode '0644'
end

# Iterate over :oracle[:rdbms][:dbs]'s keys, Initializing dbca to
# create a database named after the key for each key whose associated
# value is false, and flipping the value afterwards.
# If :oracle[:rdbms][:dbs] is empty, we print a warning to STDOUT.
ruby_block "print_empty_db_hash_warning" do
  block do
    Chef::Log.warn(":oracle[:rdbms][:dbs] is empty; no database will be created.")
  end
  action :create
  only_if {node[:oracle][:rdbms][:dbs].empty?}
end

node[:oracle][:rdbms][:dbs].each_key do |db|
  if node[:oracle][:rdbms][:dbs][db]
    ruby_block "print_#{db}_skipped_msg" do
      block do
        Chef::Log.info("Database #{db} has already been created on this node- skipping it.")
      end
      action :create
    end

    next
  end

  ## Create database. 
  if node[:oracle][:rdbms][:dbbin_version] == "12c"
    # 12c
    bash "dbca_createdb_#{db}" do
      user "oracle"
      group "oinstall"
      environment (node[:oracle][:rdbms][:env])
      code "dbca -silent -createDatabase -emConfiguration DBEXPRESS -templateName #{node[:oracle][:rdbms][:db_create_template]} -gdbname #{db} -sid #{db} -sysPassword #{node[:oracle][:rdbms][:sys_pw]} -systemPassword #{node[:oracle][:rdbms][:system_pw]}"
    end

  else
    # 11g
    bash "dbca_createdb_#{db}" do
      user "oracle"
      group "oinstall"
      environment (node[:oracle][:rdbms][:env])
      code "dbca -silent -createDatabase -templateName #{node[:oracle][:rdbms][:db_create_template]} -gdbname #{db} -sid #{db} -sysPassword #{node[:oracle][:rdbms][:sys_pw]} -systemPassword #{node[:oracle][:rdbms][:system_pw]}"
    end

    # Add to listener.ora a stanza describing the new DB.
    ruby_block "append_#{db}_stanza_to_lsnr_conf" do
      block do
        lsnr_conf = "#{node[:oracle][:rdbms][:ora_home]}/network/admin/listener.ora"
        sid_desc_body = "(SID_DESC=(GLOBAL_DBNAME=#{db})(ORACLE_HOME=#{node[:oracle][:rdbms][:ora_home]})(SID_NAME=#{db})))"
        abort("Could not back up #{lsnr_conf}; bailing out") unless system "cp --preserve=mode,ownership #{lsnr_conf} #{lsnr_conf}.bak-$(date +%Y-%m-%d-%H%M%S)"
        File.open lsnr_conf, 'r+' do |f|
          content = f.readlines
          last_line = content[-1]
          sid_desc_header = (last_line =~ /^SID/) ? '' : 'SID_LIST_LISTENER=(SID_LIST='
          sid_desc = sid_desc_header + sid_desc_body
          content[-1] = last_line.sub(/[)\s]$/, sid_desc)
          f.rewind
          f.truncate(f.pos)
          f.write content.join
        end
      end
      action :create
    end
    
    # Configure dbcontrol.
    if node[:oracle][:rdbms][:dbconsole][:emconfig]
      # Creating em.rsp file for dbcontrol.
      template "#{node[:oracle][:rdbms][:ora_home]}/em.rsp" do
        owner 'oracle'
        group 'oinstall'
        mode '0644'
      end
      # Preparing DBSNMP user.
      bash "prepare_dbsnmp_user_#{db}" do
        user "oracle"
        group "oinstall"
        environment (node[:oracle][:rdbms][:env])
        code <<-EOH2
          export ORACLE_SID=#{db}
          sqlplus / as sysdba <<-EOL1
          ALTER USER DBSNMP ACCOUNT UNLOCK;
          ALTER USER DBSNMP IDENTIFIED BY #{node[:oracle][:rdbms][:dbsnmp_pw]};
          exit
          EOL1
        EOH2
      end
      # Change sid on em.rsp.
      execute "set_sid_to_em-rsp_#{db}" do
        command "sed -i '2s/.*/SID=#{db}/' #{node[:oracle][:rdbms][:ora_home]}/em.rsp"
        user 'oracle'
        group 'oinstall'
      end
      # Reloading the listener's configuration.
      execute "reload_listener_to_register_#{db}" do
        command "#{node[:oracle][:rdbms][:ora_home]}/bin/lsnrctl reload"
        user 'oracle'
        group 'oinstall'
        environment (node[:oracle][:rdbms][:env])
      end
      # Running emca.
      execute "conf_dbcontrol_#{db}" do
        command "export ORACLE_HOME=#{node[:oracle][:rdbms][:ora_home]}; emca -config dbcontrol db -repos create -respFile #{node[:oracle][:rdbms][:ora_home]}/em.rsp"
        user 'oracle'
        group 'oinstall'
        environment (node[:oracle][:rdbms][:env])
      end
    end
    
    # Making sure shred is available
    yum_package "coreutils" do
      action :install
      arch 'x86_64'
    end

    # Shreding the em.rsp to get rid of the passwords.
    execute "shred_em_rsp_#{db}" do
      command "/usr/bin/shred -zu #{node[:oracle][:rdbms][:ora_home]}/em.rsp"
      user 'root'
      group 'root'
    end

  end # of create database.

  # Settingi a flag to indicate, that the database has been created.
  ruby_block "set_#{db}_install_flag" do
    block do
      node.set[:oracle][:rdbms][:dbs][db] = true
    end
    action :create
  end

  # Append to tnsnames.ora a stanza describing the new DB
  execute "append_#{db}_to_tnsnames.ora" do
    command "echo '#{db} =\n  (DESCRIPTION =\n    (ADDRESS_LIST =\n      (ADDRESS = (PROTOCOL = TCP)(HOST = #{node[:fqdn]})(PORT = 1521))\n    )\n    (CONNECT_DATA =\n      (SERVICE_NAME = #{db})\n    )\n  )\n\n' >> #{node[:oracle][:rdbms][:ora_home]}/network/admin/tnsnames.ora"
    not_if "grep #{db} #{node[:oracle][:rdbms][:ora_home]}/network/admin/tnsnames.ora > /dev/null 2>&1"
  end

  # Modify the new DB's configuration in /etc/oratab.
  execute "edit_oratabs_#{db}_config" do
    command "sed -i.old '/^#{db}/s/N$/Y/' /etc/oratab"
    cwd '/etc'
  end

  # Reloading the listener's configuration.
  execute "reload_listener_to_register_#{db}" do
    command "#{node[:oracle][:rdbms][:ora_home]}/bin/lsnrctl reload"
    user 'oracle'
    group 'oinstall'
    environment (node[:oracle][:rdbms][:env])
  end

  # Creating a directory for EXPORTS directory object.
  directory "#{node[:oracle][:rdbms][:dbs_root]}/#{db}/export" do
    owner 'oracle'
    group 'dba'
    mode '0755'
  end

  # Enable block change tracking.
  # A block change tracking file for the DB is added to increase RMAN backup
  # performance during incremental backups. Instead of RMAN going through the changed
  # blocks for the whole DB, it picks them up from this file.
  bash "block_change_tracking_#{db}" do
    user "oracle"
    group "oinstall"
    environment (node[:oracle][:rdbms][:env])
    code <<-EOH3
       export ORACLE_SID=#{db}
       sqlplus / as sysdba <<-EOL2
       ALTER DATABASE ENABLE BLOCK CHANGE TRACKING USING FILE '#{node[:oracle][:rdbms][:dbs_root]}/#{db}/data1/#{db}_block_change_tracking.trk';
       CREATE DIRECTORY "EXPORT" AS '#{node[:oracle][:rdbms][:dbs_root]}/#{db}/export';
       exit
       EOL2
    EOH3
  end

  # Creating a directory for RMAN backups.
  directory "#{node[:oracle][:rdbms][:dbs_root]}/#{db}/backup1" do
    owner 'oracle'
    group 'oinstall'
    mode '0755'
  end

  # Set the ORACLE_SID correctly in oracle's .profile.
  execute "set_oracle_sid_to_oracle_profile_#{db}" do
    command "sed -i 's/ORACLE_SID=.*/ORACLE_SID=#{db}/g' /home/oracle/.profile"
    user 'oracle'
    group 'oinstall'
    environment (node[:oracle][:rdbms][:env])
  end

  # Set the ORACLE_UNQNAME correctly in oracle's .profile.
  execute "set_oracle_unqname_to_oracle_profile_#{db}" do
    command "sed -i 's/ORACLE_UNQNAME=.*/ORACLE_UNQNAME=#{db}/g' /home/oracle/.profile"
    user 'oracle'
    group 'oinstall'
    environment (node[:oracle][:rdbms][:env])
  end

end
