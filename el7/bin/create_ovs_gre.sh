#! /bin/sh

vs_dev=$1
port=$2
gre_dev=$3
remote_addr=$4

inetary=($(ip addr show dev ${port} | grep inet))

ipaddress=$(echo ${inetary[1]} | awk -F '[/]' '{print $1}')

ovs-vsctl add-port ${vs_dev} ${gre_dev} -- \
    set interface ${gre_dev} \
    type=gre \
    options:local=${ipaddress} \
    options:remote_ip=${remote_addr} \
    options:pmtud=true

ovs-vsctl show
