#! /bin/sh

# Launch mysql server.
service mysqld start

# To automatically launch the mysql server at boot, execute the following command.
chkconfig mysqld on

# Set PATH environment variable as following since the OpenVNet uses its own ruby binary.
PATH=/opt/axsh/openvnet/ruby/bin:${PATH}

# Create database
cd /opt/axsh/openvnet/vnet
bundle exec rake db:drop
bundle exec rake db:create
bundle exec rake db:init
