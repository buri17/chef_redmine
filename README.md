Redmine Cookbook 
================

Description
-----------

Chef cookbook for deploying redmine with unicorn and nginx. Uses bundler for Ruby and gem management.

[![Build Status](https://secure.travis-ci.org/dergachev/chef_redmine.png)](http://travis-ci.org/dergachev/chef_redmine)

As of this writing, this cookbook was tested for installing redmine 1.2.1 and
1.3.3, and 2.3.3 onto Ubuntu 12.04 system, using Vagrant and librarian-chef,
and gusteau. For details, see
[@dergachev/vagrant_redmine](https://github.com/dergachev/vagrant_redmine)

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
  'git_revision' => "2.3.3",
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
    'rails_env' => "development",
    'db_name' => "redmine",
    'db_user' => "redmine",
    'db_pass' => "redMinePass",
    'db_host' => "localhost",
    'load_sql_file' => nil
  },
  'rmagick' => "disabled",
  'nginx_filenames' => ["redmine.conf"],
  'nginx_listen' => "*:80 default_server"
}

# redmine 1.2.x requires rails 2.3.11, 1.3.x requires rails 2.3.14, 1.4+ comes with own Gemfiles
default['redmine']['rails_version'] = node['redmine']['git_revision'].match(/^1.3/) ? '2.3.14' : '2.3.11'
```

Note the following caveats:

* If overriding node['redmine']['git_repository'] with an SSH path, be sure to
  setup either private keys for root, or enable SSH agent forwarding,
  potentially via the `root_ssh_agent::ppid` recipe. 
* If overriding node['redmine']['git_revision'] to a different version of
  redmine than the we tested, please review all the installation steps to make
  sure they're appropriate. Particularly consider overriding node['redmine']['rails_version'].
* node['mysql']['server_root_password'] and friends must be set approriately
* `node['redmine']['db']['load_sql_file']`:  absolute path to redmine mysql
  dump file that should be loaded, eg `/vagrant/redmine_prod.sql`. Supports
  gzipped files. This file should be installed prior to the execution of
  redmine::database, perhaps in a Vagrant shared folder, or by another recipe.
