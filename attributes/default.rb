default['redmine'] = {
  'git_revision' => "1.3.1",
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
    'type' => "mysql",
    'db_host' => "localhost",
    'db_user' => "root",
    'db_name' => "redmine_production",
    'db_pass' => ""
  },
  'ruby' => "ruby-1.8.7-p330@redmine",
  'rmagick' => "disabled",
  'nginx_filenames' => ["redmine.conf"],
  'nginx_listen' => ["*:80 default_server"]
}
