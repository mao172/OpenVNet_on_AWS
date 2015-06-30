#! /bin/sh

PATH=/opt/axsh/openvnet/ruby/bin:${PATH}

# Start vnmgr and webapi.
initctl start vnet-vnmgr
initctl start vnet-webapi

# Datapath

datapath_id=$(echo $(cat /etc/sysconfig/network-scripts/ifcfg-br0 | grep datapath-id= | awk -F '[:=-]' '{print $5}'))

name=${1}
node_id=${2}
network_addr=${3}

if [ "${name}" == "" ]; then
  name="test1"
fi

if [ "${node_id}" == "" ]; then
  node_id="vna"
fi

if [ "${network_addr}" == "" ]; then
  network_addr="10.0.0.0"
fi

vnctl datapaths add --uuid dp-${name} --display-name ${name} --dpid ${datapath_id} --node-id ${node_id}


# Network

vnctl networks add --uuid nw-${name} --display-name ${name}-net --ipv4-network ${network_addr} --ipv4-prefix 24 --network-mode virtual


# Interface

#

vnctl interfaces add --uuid if-inst1 \
    --mode vif --owner-datapath-uuid dp-${name} \
    --mac-address EE:99:D5:67:FD:52 \
    --network-uuid nw-${name} \
    --ipv4-address 10.0.0.1 \
    --port-name tap1
vnctl interfaces add --uuid if-inst2 \
    --mode vif --owner-datapath-uuid dp-${name} \
    --mac-address 2A:27:6E:63:5E:E5 \
    --network-uuid nw-${name} \
    --ipv4-address 10.0.0.3 \
    --port-name tap2

