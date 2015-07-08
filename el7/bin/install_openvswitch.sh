#! /bin/sh

script_path=$(cd $(dirname $0); pwd)

VERSION='2.3.2'
OVS_NAME="openvswitch-${VERSION}"

yum install gcc make automake rpm-build redhat-rpm-config python-devel openssl-devel kernel-devel kernel-debug-devel -y
yum install wget -y

adduser ovswitch

cp ${script_path}/build_openvswitch.sh /home/ovswitch/
su - ovswitch -c  "/home/ovswitch/build_openvswitch.sh ${OVS_NAME}"

yum install /home/ovswitch/rpmbuild/RPMS/x86_64/${OVS_NAME}-1.x86_64.rpm -y
systemctl start openvswitch
ovs-vsctl show
