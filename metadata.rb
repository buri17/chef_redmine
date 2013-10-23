name 'redmine'

maintainer       "Alex Dergachev"
maintainer_email "alex@evolvingweb.ca"
license          "Apache 2.0"
description      "Installs/Configures redmine"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

depends          "mysql"
depends          "database"
depends          "nginx"
depends          "apt"
