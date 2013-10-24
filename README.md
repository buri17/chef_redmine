Redmine Cookbook 
================

Description
-----------

Chef cookbook for deploying redmine with unicorn and nginx. Uses bundler for Ruby and gem management.

[![Build Status](https://secure.travis-ci.org/dergachev/chef_redmine.png)](http://travis-ci.org/dergachev/chef_redmine)

Requirements
============

Cookbooks: mysql, nginx, database, rvm; as well as all their dependencies.
If agent forwarding is requried for cloning from a private git repo, consider using the cookbook root_ssh_agent.

As of this writing, this cookbook was tested for installing redmine 1.2 and 1.3 onto Ubuntu 12.04 system, using Vagrant and librarian-chef, and gusteau. For details, see [@dergachev/vagrant_redmine](https://github.com/dergachev/vagrant_redmine)

Recipes
=======

* redmine::dependencies - installs ruby from ubuntu packages
* redmine::default - clones redmine from specified git repository, installs dependent gems using bundler (providing a Gemfile for Redmine versions prior to 1.4), installs unicorn to serve the rails application.
* redmine::database - installs config/database.yml, creates mysql user and database, initializes database from specified SQL dump. If no SQL dump file is provided, the DB will be initialized via appropriate rake task (db:migrate, db:migrate:plugins, redmine:load_default_data).
* redmine::nginx - installs nginx, configures vhost for redmine that proxies to unicorn.

Attributes
----------

The following default attributes exposed by this cookbook:

```ruby
default['redmine'] = {
  'git_revision' => "1.2.1",
  'git_repository' => "https://github.com/redmine/redmine",
  'app_path' => "/opt/redmine/",
  'app_server_name' => 'redmine',
  'unicorn_conf' => {
    'pid' => "/tmp/pids/unicorn.pid",
    'sock' => "/tmp/sockets/unicorn.sock",
    'error_log' => "unicorn.error.log",
    'access_log' => "unicorn.access.log"
    },
  'db' => {
    'db_name' => "redmine_production",
    'db_user' => "redmine",
    'db_pass' => "redMinePass",
    'db_host' => "localhost",
    'load_sql_file' => nil
  },
  'ruby' => "ruby-1.8.7-p330@redmine",
  'rmagick' => "disabled",
  'nginx_filenames' => ["redmine.conf"],
  'nginx_listen' => "*:80 default_server"
}
```

Note the following caveats:

* If overriding node['redmine']['git_repository'] with an SSH path, be sure to
  setup either private keys for root, or enable SSH agent forwarding,
  potentially via the `root_ssh_agent::ppid` recipe. 
* If overriding node['redmine']['git_revision'] to a different version of
  redmine than the we tested, please review all the installation steps to make
  sure they're appropriate.
* node['mysql']['server_root_password'] and friends must be set approriately
* `node['redmine']['db']['load_sql_file']`:  absolute path to redmine mysql
  dump file that should be loaded, eg `/vagrant/redmine_prod.sql`. Supports
  gzipped files. This file should be installed prior to the execution of
  redmine::database, perhaps in a Vagrant shared folder, or by another recipe.

Installation and Usage
======================

Coming soon.

TODO
====

* Test for redmine 2.1, and deal with the following:
  * Replace `rake generate_session_store` with `rake generate_secret_token`
* Remove unnecessary entries from Gemfile for redmine 1.2.1
* Create Gemfile for redmine 1.3.1
* Fix up unicorn_redmine init script to emit proper codes
* Stop hardcoding RAILS_ENV=production everywhere


