#! /bin/sh

PATH=${PATH}:/usr/local/bin

which ruby
if [ $? -ne 0 ];then
  yum install gcc make automake sqlite-devel openssl-devel git -y
  wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.1.tar.gz

  tar xfz ruby-2.1.1.tar.gz 
  cd ruby-2.1.1

  ./configure
  make
  make install
fi

ruby -v

gem -v

gem install bundler

bundle -v

cd /opt/axsh/openvnet/vnet/

rm -rf vendor/
bundle install

cd /opt/axsh/openvnet/vnctl/
bundle install

sed -i.org -e 's/^RUBY_PATH=/#RUBY_PATH=/g' /etc/default/openvnet
sed -i -e 's/^PATH=/#PATH=/g' /etc/default/openvnet
