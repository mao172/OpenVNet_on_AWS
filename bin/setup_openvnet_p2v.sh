#! /bin/sh

PATH=/opt/axsh/openvnet/ruby/bin:${PATH}

# Start vnmgr and webapi.
initctl start vnet-vnmgr
initctl start vnet-webapi

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
  network_addr="10.1.11.0"
fi

host_if='eth2'
inetary=($(ifconfig br0 | grep 'inet addr'))

host_addr=$(echo ${inetary[1]} | awk -F '[: ]' '{print $2}')
host_mask=$(echo ${inetary[3]} | awk -F '[: ]' '{print $2}')

infoary=($(ifconfig br0 | grep 'HWaddr'))
host_mac=${infoary[4]}


# Datapath
vnctl datapaths add --uuid dp-${name} --display-name ${name} --dpid ${datapath_id} --node-id ${node_id}

# Network
vnctl networks add --uuid nw-${name}phys \
  --display-name ${name}-net_physical \
  --ipv4-network 172.31.48.0/20 \
  --ipv4-prefix 20 \
  --network-mode physical

vnctl networks add --uuid nw-${name}vrt \
  --display-name ${name}-net_virtual \
  --ipv4-network ${network_addr} \
  --ipv4-prefix 24 \
  --network-mode virtual

# Interface
vnctl interfaces add --uuid if-${host_if} \
  --mode vif --owner-datapath-uuid dp-${name} \
  --mac-address ${host_mac} \
  --network-uuid nw-${name}phys \
  --ipv4-address ${host_addr} \
  --port-name ${host_if}

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
      --network-uuid nw-${name}vrt \
      --ipv4-address ${if_addr} \
      --port-name ${if_name}
  done

  IFS=$oldIFS
fi

# Broadcast
vnctl datapaths network add dp-${name} nw-${name}phys \
  --interface_uuid if-${host_if} \
  --broadcast-mac-address '10:00:00:00:01:01'

vnctl datapaths network add dp-${name} nw-${name}vrt \
  --interface_uuid if-${host_if} \
  --broadcast-mac-address '10:00:00:00:01:02'


# Router
vnctl interfaces add \
      --uuid="if-rt${name}phys" \
      --owner-datapath-uuid="dp-${name}" \
      --network-uuid="nw-${name}phys" \
      --mac-address="10:00:00:00:02:01" \
      --ipv4-address="172.31.48.1" \
      --mode="simulated" \
      --enable-routing="true"

vnctl network_services add \
      --display-name="ns-rt${name}phys" \
      --interface-uuid="if-rt${name}phys" \
      --type="router"


vnctl interfaces add \
      --uuid="if-rt${name}vrt" \
      --owner-datapath-uuid="dp-${name}" \
      --network-uuid="nw-${name}vrt" \
      --mac-address="10:00:00:00:02:02" \
      --ipv4-address="10.1.11.254" \
      --mode="simulated" \
      --enable-routing="true"

vnctl network_services add \
      --display-name="ns-rt${name}vrt" \
      --interface-uuid="if-rt${name}vrt" \
      --type="router"

vnctl route_link add \
      --uuid="rl-pubint" \
      --mac-address="10:00:00:00:03:01"

vnctl datapaths route_link add dp-${name} rl-pubint \
      --interface-uuid="if-${host_if}" \
      --mac-address="10:00:00:00:03:02"


vnctl routes add \
      --interface-uuid="if-rt${name}phys" \
      --route-link-uuid="rl-pubint" \
      --network-uuid="nw-${name}phys" \
      --ipv4-network="172.31.48.0"

vnctl routes add \
      --interface-uuid="if-rt${name}vrt" \
      --route-link-uuid="rl-pubint" \
      --network-uuid="nw-${name}vrt" \
      --ipv4-network="${network_addr}"
