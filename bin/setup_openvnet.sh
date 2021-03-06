#! /bin/sh

PATH=/opt/axsh/openvnet/ruby/bin:${PATH}

# Start vnmgr and webapi.
initctl start vnet-vnmgr
initctl start vnet-webapi

sleep 10

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

# Datapath
vnctl datapaths add --uuid dp-${name} --display-name ${name} --dpid ${datapath_id} --node-id ${node_id}

# Network
vnctl networks add --uuid nw-${name} --display-name ${name}-net --ipv4-network ${network_addr} --ipv4-prefix 24 --network-mode virtual

# Interface
if [ -p /dev/stdin ]; then
  input=$(cat -)
  oldIFS=$IFS
  IFS=$'\n'
  lines=($input)

  for infc in ${lines[@]}
  do
    if_name=$(echo ${infc} | awk '{print $1}')
    if_addr=$(echo ${infc} | awk '{print $2}')
    if_mac=$(echo ${infc} | awk '{print $3}')

  vnctl interfaces add --uuid if-${if_name} \
      --mode vif --owner-datapath-uuid dp-${name} \
      --mac-address ${if_mac} \
      --network-uuid nw-${name} \
      --ipv4-address ${if_addr} \
      --port-name ${if_name}
  done

  IFS=$oldIFS
fi
