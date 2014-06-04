Description
===========

Installs and configures the Oracle RDBMS, patches it to the latest
version and creates databases.

New features on v1.2.0

* Oracle 12c Release 1 support with DBEXPRESS

(Oracle client install is still 11g R2)

Tested with an Open Source Chef Server/Chef Client combo only.

Oracle version 11.2.0.3 was used to develop this cookbook, but the
code should work for other versions as well, with some
modifications.

At the time this cookbook was being developed the latest patch was
Patch 14727310 - 11.2.0.3.5, but it has now been updated to the
latest patch from Oracle 7/16/2013, Patch 16619892 - 11.2.0.3.7
Patch Set Update.

For guidelines on how to adapt the cookbook for other PSU versions,
see `latest_dbpatch`, under `Recipes`, below.

Quickstart (database)
=====================

* Have either an open Source Chef Server or a Hosted Chef account at
  the ready.
* Spin up a CentOS VM using your choice of hypervisor and/or Vagrant,
  and the `CentOS-6.5-x86_64-minimal.iso`, which you can get here:

  [`CentOS-6.5-x86_64-minimal.iso`](https://www.centos.org/)

* Your NIC is not up by default, make sure to edit the
  `/etc/sysconfig/ifcfg-eth0` file and run `service network start`.
* Make sure your FQDN is properly configured (test this with
  `hostname -f`), else `runInstaller` will fail.
* You don't want to transfer Oracle's binaries in the clear across
  the Internet. Set up a Web server to serve them over HTTPS unless
  you're on a secure local network.
* Create a role to override the default attribute values for the URLs
  of Oracle's install files & patches with your own; e.g.:

        name "ora_quickstart"
        description "Role applied to Oracle quickstart test machines."
        run_list 'recipe[oracle]', 'recipe[oracle::logrotate_alert_log]', 'recipe[oracle::logrotate_listener]', 'recipe[oracle::createdb]'
        override_attributes :oracle => {:rdbms => {:latest_patch => {:url => 'https://secure.server.localdomain/path/to/p16619892_112030_Linux-x86-64.zip'}, :opatch_update_url => 'https://secure.server.localdomain/path/to/p6880880_112000_Linux-x86-64.zip', :install_files => ['https://secure.server.localdomain/path/to/p10404530_112030_Linux-x86-64_1of7.zip', 'https://secure.server.localdomain/path/to/p10404530_112030_Linux-x86-64_2of7.zip']}} 

* For 12c install, add `node[:oracle][:rdbms][:dbbin_version]`
  override_attribute to the role.

        name "ora_12c_quickstart"
        description "Role applied to Oracle 12c quickstart test machines."
        run_list 'recipe[base]', 'recipe[oracle]', 'recipe[oracle::logrotate_alert_log]', 'recipe[oracle::logrotate_listener]', 'recipe[oracle::createdb]'
        override_attributes :oracle => {:rdbms => {:latest_patch => {:url => 'https://secure.server.localdomain/path/to/p18031528_121010_Linux-x86-64.zip'}, :opatch_update_url => 'https://secure.server.localdomain/path/to/p6880880_121010_Linux-x86-64.zip', :install_files => ['https://secure.server.localdomain/path/to/linuxamd64_12c_database_1of2.zip', 'https://secure.server.localdomain/path/to/linuxamd64_12c_database_2of2.zip'], :dbbin_version => '12c'}}

* You need to set up an encrypted data bag item to secure the oracle
  user's password. See Opscode's docs site for details on encrypted
  data bags:
  [encrypted data bag doc](http://docs.opscode.com/chef/essentials_data_bags.html#encrypt-a-data-bag)
  Your encrypted item requires a key named `pw`, whose value is the
  password of the oracle user- you can set that to whatever you want.
  You must set the value of `node[:oracle][:user][:edb]` to the name
  of your data bag, and that of `node[:oracle][:user][:edb_item]` to
  the name of the encrypted item; the defaults are `oracle` and
  `foo`, respectively.

* If you're using the open source Chef Server, add this line to
  /etc/chef-server/chef-server.rb:

        `erchef['s3_url_ttl'] = 9999`

  then run `chef-server-ctl reconfigure` to reconfigure Chef Server.
  This config edit avoids running into CHEF-3045, which we are liable
  to do because of the time it takes to install Oracle's binaries and
  spin up a database.

* Bootstrap the node, telling Chef to create the FOO database on it:

  11g 
        knife bootstrap HOSTNAME -r 'role[ora_quickstart]' -j '{"oracle" : {"rdbms": {"dbs": {"FOO" : false}}}}' 
  12c 
        knife bootstrap HOSTNAME -r 'role[ora_12c_quickstart]' -j '{"oracle" : {"rdbms": {"dbs": {"FOO" : false}}}}' 

* Go grab a cup of tea, as this is apt to take a fair amount of time
to complete :-)


Quickstart (client)
===================

* Only 11g client available for now.

* Follow the steps above to create a VM

* Create a role to override the default attribute values for the URLs
  of Oracle Client's install files & patches with your own; e.g.:

  **Note**, that you need only one install file for the client: `p10404530_112030_Linux-x86-64_4of7.zip`

        name "ora_cli_quickstart"
        description "Role applied to Oracle Client quickstart test machines."
        run_list 'recipe[oracle::oracli]'
        override_attributes :oracle => {:client => {:latest_patch => {:url => 'https://secure.server.localdomain/path/to/p16619892_112030_Linux-x86-64.zip'}, :opatch_update_url => 'https://secure.server.localdomain/path/to/p6880880_112000_Linux-x86-64.zip', :install_files => ['https://secure.server.localdomain/path/to/p10404530_112030_Linux-x86-64_4of7.zip']}} 

* You need to set up an encrypted data bag item to secure the oracli
  user's password. See Opscode's docs site for details on encrypted
  data bags:
  [encrypted data bag doc](http://docs.opscode.com/chef/essentials_data_bags.html#encrypt-a-data-bag)
  Your encrypted item requires a key named `pw`, whose value is the
  password of the oracli user- you can set that to whatever you want.
  You must set the value of `node[:oracle][:cliuser][:edb]` to the name
  of your data bag, and that of `node[:oracle][:cliuser][:edb_item]` to
  the name of the encrypted item; the defaults are `oracli` and
  `foo`, respectively.

* If you have already bootstrapped a node with the ora_quickstart role,
  you can easily add the `role[ora_cli_quickstart]` role to the run
  list.

        knife node run_list add <node_name> 'role[ora_cli_quickstart]'

* Otherwise just, bootstrap the node to install the client on it:

        knife bootstrap HOSTNAME -r 'role[ora_cli_quickstart]'

Requirements
============

## Oracle

See here:

[Oracle's requirements for 11g](http://docs.oracle.com/cd/E11882_01/install.112/e24321/pre_install.htm#i1011296)

[Oracle's requirements for 12c](http://docs.oracle.com/cd/E16655_01/install.121/e17720/pre_install.htm#LADBI7496)

## Chef

This cookbook was successfully tested using Chef-Client 11, in combo
with the open source Chef Server 11, as well as with Hosted Chef.

Version 1.2.0 has been tested against Chef-Client (11.10.4)
and open source Chef Server 11 (11.0.10).

If you use the open source Chef Server, because installing a
database takes a long while, and owing to
[CHEF-3045](http://tickets.opscode.com/browse/CHEF-3045), you'll want
to increase the value of `erchef['s3_url_ttl']` in
`/etc/chef-server/chef-server.rb`; which value to choose depends on the
number of databases you create, and how fast your nodes are. In most
cases, this should give you room to spare to install a couple
databases:

`erchef['s3_url_ttl'] = 9999`

then run `chef-server-ctl reconfigure` to reconfigure Chef Server.

## Platforms

* `CentOS 6.5 (x86_64)`
* `RHEL 6.5 (x86_64)`

oracle was tested on the distros/versions given above; YMMV on
older versions of their 6.x branches.
The development target was `Centos x86_64 minimal install`.
DISCLAIMER: note that, out of these platforms, Oracle Database
11g R2 and 12c R1 are only certified on RHEL 6 :-) For more detail,
check the certification matrix on My Oracle Support:
[certification matrix](https://support.oracle.com)

## Packages

* Access to My Oracle Support to download the 11g R2 install media
  and the patch files.

  You will not be able to download the 11.2.0.3 install files from
  Oracle Technology Network (OTN), since the version available there
  is 11.2.0.1. From:
  [Oracle DB Downloads page](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)

  > "11/10/11: Patch Set 11.2.0.3 for Linux, Solaris, Windows, AIX
  and HP-UX Itanium is now available on support.oracle.com. Note: it
  is a full installation (you do not need to download 11.2.0.1
  first). See the README for more info (login to My Oracle Support
  required)."

  11g
  
  Patch 16619892 (11.2.0.3.7): `p16619892_112030_Linux-x86-64.zip`  
  OPatch 6880880 (11.2.0.3.4): `p6880880_112000_Linux-x86-64.zip`  
  Oracle 11.2.0.3 media: `p10404530_112030_Linux-x86-64_1of7.zip`  
  Oracle 11.2.0.3 media: `p10404530_112030_Linux-x86-64_2of7.zip`  
  Oracle 11.2.0.3 media: `p10404530_112030_Linux-x86-64_4of7.zip`

  **Note:** You don't need all seven 11.2.0.3 media files in order to
  just install the RDBMS' binaries. `p10404530_112030_Linux-x86-64_4of7.zip`
  is for the client install.

* Download the 12.1.0.1 install files from Oracle Technology
  Network. For the PSU and OPatch patch files you need access to
  My Oracle Support as well as an active CSI.

  [Oracle DB Downloads page](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)

  12c
  
  Patch 18031528 (12.1.0.1.3): `p18031528_121010_Linux-x86-64.zip`  
  OPatch 6880880 (12.1.0.1.2): `p6880880_121010_Linux-x86-64.zip`  
  Oracle 12.1.0.1 media: `linuxamd64_12c_database_1of2.zip`   
  Oracle 12.1.0.1 media: `linuxamd64_12c_database_2of2.zip` 

## Miscellaneous

* Ensure that your FQDN is properly configured (check the output of
  `hostname -f`), else runInstaller will fail.
* At least a basic knowledge of Oracle administration will come in
  handy, in particular if you want to modify attributes' values
  and/or modify the cookbook's code or resources.
* If you want to increase the size of `/dev/shm`, edit `/etc/fstab`
  accordingly, and make sure to add this entry to `/etc/rc.local` or
  `/etc/rc.d/rc.sysinit` to have your changes persist across reboots:

  `/bin/mount -o remount /dev/shm`

  This works around a bug in RHEL and derivatives:
  [Red Hat Bugzilla Bug 669700](https://bugzilla.redhat.com/show_bug.cgi?id=669700)

* Please check Oracle database specific swap recommendations from:
  [3.1 Memory Requirements](http://docs.oracle.com/cd/E11882_01/install.112/e24326/toc.htm#BHCJCBAF)


Attributes
==========

oracle defines a single top-level namespace: `:oracle`. Values
that pertain to the whole Oracle setup (not only the RDBMS) are
defined there directly:

* `node[:oracle][:ora_base]` - sets the Oracle base's absolute pathname,
defaults to `/opt/oracle`.
* `node[:oracle][:ora_inventory]` - sets oraInventory's absolute pathname,
defaults to `/opt/oraInventory`.

`:oracle` has four children: 

* `:user`
* `:cliuser`
* `:rdbms`
* `:client`

Attributes under `:user` are specific to the oracle user, as you may
have guessed:

* `node[:oracle][:user][:uid]`
* `node[:oracle][:user][:gid]`
* `node[:oracle][:user][:shell]`- note that this is set to `/bin/ksh`
  by default.
* `node[:oracle][:user][:sup_grps]` - sets the oracle user's
  supplementary groups, a Hash whose keys are group names, and
  whose values are gids. The default value is  `{'dba' => 202}`.
* `node[:oracle][:user][:pw_set]` - a flag that indicates whether the
  `oracle_user_config` recipe has set the password of the oracle
  user (and can thus skip doing it again); defaults to `false`.
* `node[:oracle][:user][:edb]` - sets the name of the data bag from
  which we'll fetch the encrypted item storing the oracle user's
  password. Defaults to `oracle`.
* `node[:oracle][:user][:edb_item]` - sets the name of the encrypted
  item in which the oracle user's password is stored. Defaults to
  `foo`.

Attributes under `:cliuser` are specific to the oracli user, as you may
have guessed:

* `node[:oracle][:cliuser][:uid]`
* `node[:oracle][:cliuser][:gid]`
* `node[:oracle][:cliuser][:shell]`- note that this is set to `/bin/ksh`
  by default.
* `node[:oracle][:cliuser][:sup_grps]` - sets the oracli user's
  supplementary groups, a Hash whose keys are group names, and
  whose values are gids. The default value is  `{'oinstall' => 201}`.
* `node[:oracle][:cliuser][:pw_set]` - a flag that indicates whether the
  `oracli_user_config` recipe has set the password of the oracli
  user (and can thus skip doing it again); defaults to `false`.
* `node[:oracle][:cliuser][:edb]` - sets the name of the data bag from
  which we'll fetch the encrypted item storing the oracli user's
  password. Defaults to `oracli`.
* `node[:oracle][:cliuser][:edb_item]` - sets the name of the encrypted
  item in which the oracli user's password is stored. Defaults to
  `foo`.

Attributes under `:rdbms` relate to the Oracle RDBMS proper,
rather unsurprisingly:

* `node[:oracle][:rdbms][:dbbin_version]` - selection for 12c.
* `node[:oracle][:rdbms][:ora_home]` - sets the oracle home's absolute
  pathname; defaults to  `#{node[:oracle][:ora_base]}/11R23`.
* `node[:oracle][:rdbms][:is_installed]` - flag to indicate whether
  the dbbin recipe has installed the RDBMS, and can thus be skipped.
* `node[:oracle][:rdbms][:install_info]` - a Hash storing information
  about the RDBMS installed on the node (version, patch number, and
  timestamp of last patching); defaults to the empty Hash. See the
  `get_version recipe` for greater detail.
* `node[:oracle][:rdbms][:install_dir]` - sets the oracle installation
  directory's absolute pathname; defaults to `#{node[:oracle][:ora_base]}/install_dir`</br>
* `node[:oracle][:rdbms][:response_file_url]` - sets the URL of the
  response file you want Chef to use instead of having it generate a
  basic ocm.rsp itself.
* `node[:oracle][:rdbms][:deps]` - an Array storing the package names
  of the Oracle RDBMS' dependencies.
* `node[:oracle][:rdbms][:env]` - a Hash of variable names/values that
  makes up the RDBMS-specific environment for the oracle user.
* `node[:oracle][:rdbms][:install_files]` - an Array of URLs that
  specify the locations of the Oracle RDBMS' installation files:
  `p10404530_112030_Linux-x86-64_1of7.zip` and `p10404530_112030_Linux-x86-64_2of7.zip`.
* `node[:oracle][:rdbms][:sys_pw]` - sets the password for the `SYS`
  default open database user. Has a default placeholder value.
* `node[:oracle][:rdbms][:system_pw]` - sets the password for the `SYSTEM`
  default open database user. Has a default placeholder value.
* `node[:oracle][:rdbms][:dbsnmp_pw]` - sets the password for the `DBSNMP`
  default open database user. Has a default placeholder value.
* `node[:oracle][:rdbms][:opatch_update_url]` - sets the URL of the
  OPatch update (`p6880880_112000_Linux-x86-64.zip)`.
* `node[:oracle][:rdbms][:latest_patch][:url]` - URL of the latest
  Oracle RDBMS patch (`p16619892_112030_Linux-x86-64.zip`).
* `node[:oracle][:rdbms][:latest_patch][:dirname]` - sets the name of
  the latest patch's expanded directory. Will typically match the
  part of the latest patch's filename following the initial 'p', up
  until (and exclusive of) the first `_` (`16619892`, in our
  case), but this is not guaranteed.
* `node[:oracle][:rdbms][:latest_patch][:is_installed]` - flag to
  indicate whether `latest_dbpatch` recipe has patched the RDBMS, and
  can thus be skipped.
* `node[:oracle][:rdbms][:dbs]` - a Hash whose keys are database names
  and whose values are Booleans. A value of true indicates that the
  database has already been created, and should thus be skipped by
  the createdb recipe. Defaults to the empty Hash.
* `node[:oracle][:rdbms][:dbs_root]` - sets the pathname of the root
  directory for the databases.
* `node[:oracle][:rdbms][:dbconsole][:emconfig]` - `true` indicates,
  that em dbconsole will be configured for all databases after creating
  them.
* `node[:oracle][:rdbms][:dbconsole][:sysman_pw]` - sets the password
  for the `SYSMAN` default open database user. Has a default placeholder
  value.
* `node[:oracle][:rdbms][:dbconsole][:notification_email]` - sets the email
  for em dbconsole notifications. Has a default placeholder value.
* `node[:oracle][:rdbms][:dbconsole][:outgoing_mail]` - sets the mail
  server hostname. Uses `mailhost` as the default placeholder value.
* `node[:oracle][:rdbms][:db_create_template]` - sets the db template
  file name. Has a default placeholder value.

Attributes under `:client` relate to the Oracle Client proper,
rather unsurprisingly:

* `node[:oracle][:client][:ora_home]` - sets the oracli home's absolute
  pathname; defaults to  `#{node[:oracle][:ora_base]}/11R23cli`.
* `node[:oracle][:client][:is_installed]` - flag to indicate whether
  the clibin recipe has installed the client, and can thus be skipped.
* `node[:oracle][:client][:install_info]` - a Hash storing information
  about the client installed on the node (version, patch number, and
  timestamp of last patching); defaults to the empty Hash. See the
  `get_version recipe` for greater detail.
* `node[:oracle][:client][:install_dir]` - sets the oracli installation
  directory's absolute pathname; defaults to `#{node[:oracle][:ora_base]}/install_dir_client`
* `node[:oracle][:client][:response_file_url]` - sets the URL of the
  response file you want Chef to use instead of having it generate a
  basic ocm.rsp itself.
* Client recipes use the same dependencies as for the database install
  `node[:oracle][:rdbms][:deps]` - an Array storing the package names
  of the Oracle RDBMS' and Oracle Client' dependencies.
* `node[:oracle][:client][:env]` - a Hash of variable names/values that
  makes up the RDBMS-specific environment for the oracle user.</br>
* `node[:oracle][:client][:install_files]` - an Array of URLs that
  specify the locations of the Oracle Client' installation files:
  `p10404530_112030_Linux-x86-64_4of7.zip`.
* `node[:oracle][:client][:opatch_update_url]` - sets the URL of the
  OPatch update (`p6880880_112000_Linux-x86-64.zip)`.
* `node[:oracle][:client][:latest_patch][:url]` - URL of the latest
  Oracle Client patch (`p16619892_112030_Linux-x86-64.zip`).
* `node[:oracle][:client][:latest_patch][:dirname]` - sets the name of
  the latest patch's expanded directory. Will typically match the
  part of the latest patch's filename following the initial 'p', up
  until (and exclusive of) the first `_` (`16619892`, in our
  case), but this is not guaranteed.
* `node[:oracle][:client][:latest_patch][:is_installed]` - flag to
  indicate whether `latest_dbpatch` recipe has patched the Client, and
  can thus be skipped.


Recipes
=======

By order of appearance in a typical workflow:

## `default`

Includes 5 recipes, which are, in order:

* `oracle::oracle_user_config`
* `oracle::deps_install`
* `oracle::kernel_params`
* `oracle::dbbin` unless `node[:oracle][:rdbms][:is_installed]`'s value is `true`.
* `oracle::latest_dbpatch` unless `node[:oracle][:rdbms][:latest_patch][:is_installed]`'s value is `true`.

IOW, we set up the oracle user, install Oracle's dependencies, tweak
the kernel's parameters, then install the Oracle binaries (unless
we've done so already, and patch them to the latest patch version
(unless we've done so already).

## `oracli`

Includes 5 recipes, which are, in order:

* `oracle::oracli_user_config`
* `oracle::deps_cli_install`
* `oracle::kernel_params`
* `oracle::clibin` unless `node[:oracle][:client][:is_installed]`'s value is `true`.
* `oracle::cli_latest_patch` unless `node[:oracle][:client][:latest_patch][:is_installed]`'s value is `true`.

IOW, we set up the oracli user, install Oracle's dependencies, tweak
the kernel's parameters, then install the Oracle Client binaries (unless
we've done so already, and patch them to the latest patch version
(unless we've done so already).

## `oracle_user_config`

Create and configure the oracle user. Its password is only set if
`node[:oracle][:user][:pw_set]`'s value isn't true .
`node[:oracle][:user][:pw_set]`'s value is `false` by default; it's
flipped to `true` after we set the password, meaning that, if you want
to change the password after the first Chef run, you'll have to flip
it back.

The recipe expects the oracle user password to be stored in an
encrypted data bag item; the bag's name is controlled by the
`node[:oracle][:user][:edb]` attribute, whose default value is
`oracle`. The item's name is controlled by the `node[:oracle][:user][:edb_item]`
attribute, whose default value is `foo`.

The recipe requires the encrypted item to include a key named `pw`,
whose value you must set to the oracle user's password.

For more detail on encrypted data bags, see:
[Opscode's doc on encrypted data bags](http://docs.opscode.com/essentials_data_bags_encrypt.html)

## `oracli_user_config`

Create and configure the oracli user. Its password is only set if
`node[:oracle][:cliuser][:pw_set]`'s value isn't true .
`node[:oracle][:cliuser][:pw_set]`'s value is `false` by default; it's
flipped to `true` after we set the password, meaning that, if you want
to change the password after the first Chef run, you'll have to flip
it back.

The recipe expects the oracli user password to be stored in an
encrypted data bag item; the bag's name is controlled by the
`node[:oracle][:cliuser][:edb]` attribute, whose default value is
`oracli`. The item's name is controlled by the `node[:oracle][:cliuser][:edb_item]`
attribute, whose default value is `foo`.

The recipe requires the encrypted item to include a key named `pw`,
whose value you must set to the oracli user's password.

For more detail on encrypted data bags, see:
[Opscode's doc on encrypted data bags](http://docs.opscode.com/essentials_data_bags_encrypt.html)

## `deps_install`

Installs the Oracle RDBMS' dependencies, which are specified as an
Array of package names that's the value of `node[:oracle][:rdbms][:deps]`.

## `deps_cli_install`

Installs the Oracle Client' dependencies, which are specified as an
Array of package names that's the value of `node[:oracle][:client][:deps]`.

## `kernel_params`

Configures kernel parameters for Oracle. We deploy a config file to
`/etc/sysctl.d/ora_params` and reload `sysctl` settings.

## `ora_os_setup`

Includes 3 recipes, which are, in order:

* `oracle::oracle_user_config`
* `oracle::deps_install`
* `oracle::kernel_params`

The recipe will set up the oracle user, install Oracle's dependencies
and tweak the kernel's parameters.

## `dbbin`

Installs Oracle RDBMS binaries. The install files are specified as
an Array of URLs that's the value of the `node[:oracle][:rdbms][:install_files]`
attribute.

**Note:** If you use the `ora_quickstart` or `ora_12c_quickstart` roles, 
they will override the values.

## `clibin`

Installs Oracle Client binaries. The install files are specified as
an Array of URLs that's the value of the `node[:oracle][:client][:install_files]`
attribute.

**Note:** If you use the `ora_cli_quickstart` role, it will override the values.

## `latest_dbpatch`

Installs latest patch for Oracle RDBMS. The patch file is specified
as a URL that's the value of `node[:oracle][:rdbms][:latest_patch][:url]`.

Also remember to update OPatch 6880880 to the latest version.

Previous or new PSU patches should work without many changes. 11.2.0.3.4,
11.2.0.3.7 and 11.2.0.3.8 worked fine in our environment.

## `cli_latest_patch`

Installs latest patch for Oracle Client. The patch file is specified
as a URL that's the value of `node[:oracle][:client][:latest_patch][:url]`.

Also remember to update OPatch 6880880 to the latest version.

Previous or new PSU patches should work without many changes. 11.2.0.3.4,
11.2.0.3.7, 11.2.0.3.8 and 11.2.0.3.10 worked fine in our environment.

## `get_version`

Included by `latest_dbpatch`. Populates `node[:oracle][:rdbms][:install_info]`'s
Hash with key/value pairs that track the patch number, the patch's
timestamp, and the version string, as extracted from the output of:

`opatch lsinventory -bugs_fixed`

## `get_cli_version`

Included by `cli_latest_patch`. Populates `node[:oracle][:client][:install_info]`'s
Hash with key/value pairs that track the patch number, the patch's
timestamp, and the version string, as extracted from the output of:

`opatch lsinventory -bugs_fixed`

## `createdb`

Creates databases. Iterates over the keys of the `node[:oracle][:rdbms][:dbs]`'s
Hash, creating a database for each key whose value isn't truthy.
You're meant to specify this Hash yourself, for example in a role,
or as part of the bootstrap command line, e.g.:

`[snip] -j '{"oracle" : {"rdbms": {"dbs": {"FOO" : false}}}}'`

The value associated with a key is set to `true` after its
corresponding database has been created.

## `logrotate_alert_log`

logrotate config for the Oracle alert log.

## `logrotate_listener`

logrotate config for the Oracle listener's log.


Usage Notes
===========

* You can customise most installation paths and related settings;
  see the Attributes section, above, for details.
* Database is installed on the root (`/`) filesystem. DBAs are
  encouraged to improve the disk/fs layout as they see fit, and/or
  to fit local practice.
* The database template (created by DBCA) is not an Oracle best
  practise, feel free to replace it with one of your own creation.
* The database filesystem root is parameterised, using `node[:oracle][:rdbms][:dbs_root]`.
  This attribute is leveraged in the database template we ship. If
  you want to do the same with your own database template, you'll
  have to turn it into a Chef template as well (and use
  search-and-replace).
* Replace the default ocm.rsp with your own, if you want to add your
  email address for updates. Use the `$ORACLE_HOME/OPatch/ocm/bin/emocmrsp`
  command to do that (pass it the `-help` switch to check its usage).
  Then put the new reponse file on your HTTPS server and set
  `node[:oracle][:rdbms][:response_file_url]` to the file's URL.
* `dbbin` takes a long time to complete; hence the potential issue
  with CHEF-3045 for open source Chef Server users.
* By default the em console will be configured, so this will extend the
  total run time even further (between versions 1.0.4 and 1.1.0). You
  can turn it off from the `attributes/detault.rb`.
* On a similar note, `createdb` supports the creation of several DBs
  on the same host, but this is apt to take a small eternity to
  complete.
* The supplementary group `oinstall` for oracli is to align the permissions
  to access /opt/oraInventory.
* If you experience errors while generating the ocm.rsp, this might
  be due to not having connection to the internet.

Roadmap
=======

For v1.3.0

* Oracle 12c Grid Infrastructure install
* Update the 11g latest patch to 11.2.0.3.x.
* Update the 12c latest patch to 12.1.0.1.x.
* Node attribute isolation to rdbms or oracli depending on which is
  installed.

For v1.4.0

* Oracle 12c Client install
* Add OEM 11g/12c intelligent agent installation
* Ability to patch existing installations (patchbin.rb)

For v2.0.0

* Re-factor and re-architecture the cookbook
* LWRP's or HWRP's
* Modular
* Dynamic choice of Orcle version
* Use of remote_file resources

For v3.0.0

* RAC support on NFS
* RAC support on ASM

Additional Info
===============

Ari has a blog where he gets into more detail about our testing of
oracle cookbook on two cloud providers (using Hosted Chef), and Chefy
and Oracly things generally:

<http://oraarir.blogspot.fi/>

Contributing
============

1. Fork the repository on Github: [oracle's GitHub repo](https://github.com/aririikonen/oracle)
2. Create a named feature branch (like `add_component_x`)
3. Write your changes
4. Write tests for your changes (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
===================

* Author:: Ari Riikonen <ari.riikonen@gmail.com>  
* Author:: Dominique Poulain

Copyright:: 2014, Ari Riikonen

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
