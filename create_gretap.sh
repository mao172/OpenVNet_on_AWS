#! /bin/sh
# Usage:
#  create_gretap NAME REMOTE_ADDR LOCAL_ADDR KEY VIRTUAL_ADDR

name=${1}
remote_addr=${2}
local_addr=${3}
virtual_addr=${5}

ip link add ${name} type gretap remote ${remote_addr} local ${local_addr}
ip addr add ${virtual_addr} dev ${name}
ip link set ${name} up
ip link set ${name} mtu 1450

ifconfig ${name}
