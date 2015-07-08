#! /bin/sh

VERSION=5.5
MINER_VERSION=44
ENDPOINT=http://dev.mysql.com/get/Downloads/MySQL-${VERSION}/MySQL-

for sub_pkg in shared shared-compat devel server client
do
  yum install -y ${ENDPOINT}${sub_pkg}-${VERSION}.${MINER_VERSION}-1.el7.x86_64.rpm
done

systemctl start mysql
mysqladmin -uroot version
