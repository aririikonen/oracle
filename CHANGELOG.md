# CHANGELOG for oracle

Cookbook relaunched (aririikonen/oracle).

## Future

* Please refer to README.md, chapter Roadmap.

## 1.2.0:

* Support for 12c, including DBEXPRESS
* Fixed node[:oracle][:rdbms][:install_info][:version_str], now it works with two digit version numbers (i.e. 11.2.0.3.10)

## 1.1.2:

* Added a recipe to set the oracle pre-requisities only (ora_os_setup.rb)

## 1.1.1:

* Now you can choose which dbca template you want to use (attributes/default.rb or override from roles)

## 1.1.0:

* Configure the EM dbconsole (Enterprise Manager Database Control)
* Install Oracle Client and patch it to the latest patch
* default_template.dbt has less oracle options turned on (true) by default

## < 1.1.0:

* Prior to relaunched v1.1.0, please refer to https://github.com/echaeu/echa-oracle/blob/master/CHANGELOG.md
