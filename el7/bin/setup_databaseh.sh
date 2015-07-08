#! /bin/sh

PATH=${PATH}:/usr/local/bin

cd /opt/axsh/openvnet/vnet/

systemctl restart mysql

mysqladmin -uroot -f drop vnet
mysqladmin -uroot create vnet
bundle exec rake db:init
