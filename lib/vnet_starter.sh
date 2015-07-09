#! /bin/sh

run() {
  local e
  local E
  local T
  local oldIFS
  
  [[ ! "$-" =~ e ]] || e=1
  [[ ! "$-" =~ E ]] || E=1
  [[ ! "$-" =~ T ]] || T=1

  set +e
  set +E
  set +T

  output="$("$@" 2>&1)"
  status="$?"
  oldIFS=$IFS
  IFS=$'\n' lines=($output)

  IFS=$oldIFS
  [ -z "$e" ] || set -e
  [ -z "$E" ] || set -E
  [ -z "$T" ] || set -T
}


set_datapaths(){

  dp_name=$1

  dpid=$(echo $(cat /etc/sysconfig/network-scripts/ifcfg-br0 | grep datapath-id= | awk -F '[:=-]' '{print $5}'))

  run vnctl datapaths add \
      --uuid="dp-${dp_name}" \
      --display-name="${dp_name}" \
      --dpid="0x${dpid}" \
      --node-id="#{dp_name}"

  if [ $status -ne 0 ]; then
    echo "$output" >&2
    return $status
  fi
}

set_networks(){
  NW_PUB_NAME=$1
  NW_INT_NAME=$2


  run vnctl networks add \
      --uuid="nw-${NW_PUB_NAME}" \
      --display-name="${NW_PUB_NAME}" \
      --ipv4-network="${host_nw}" \
      --ipv4-prefix="${host_mask}" \
      --network-mode="physical"

  if [ $status -ne 0 ]; then
    echo "$output" >&2
    return $status
  fi

  virtual_nwaddr=$3
  virtual_mask=$4

  run vnctl networks add \
      --uuid="nw-${NW_INT_NAME}" \
      --display-name="${NW_INT_NAME}" \
      --ipv4-network="${virtual_nwaddr}" \
      --ipv4-prefix="${virtual_mask}" \
      --network-mode="virtual"
  if [ $status -ne 0 ]; then
    echo "$output" >&2
    return $status
  fi

}

set_interfaces() {
  DP_NAME=$1
  NW_PUB_NAME=$2
  NW_INT_NAME=$3

  run vnctl interfaces add \
      --uuid="if-${host_if}" \
      --owner-datapath-uuid="dp-${DP_NAME}" \
      --network-uuid="nw-${NW_PUB_NAME}" \
      --mac-address="${host_mac}" \
      --ipv4-address="${host_ip}" \
      --port-name="${host_if}" \
      --mode="host"

  if [ $status -ne 0 ]; then
    echo "$output" >&2
    return $status
  fi

  oldIFS=$IFS
  IFS=$'\n'
  lines=($input)
  for infc in ${lines[@]}
  do
    image=$(echo ${infc} | awk '{print $1}')
    name=$(echo ${infc} | awk '{print $2}')
    bif=$(echo ${infc} | awk '{print $3}')
    cif=$(echo ${infc} | awk '{print $4}')
    ip=$(echo ${infc} | awk '{print $5}')
    mac=$(echo ${infc} | awk '{print $6}')

    run vnctl interfaces add \
        --uuid="if-${bif}" \
        --owner-datapath-uuid="dp-${DP_NAME}" \
        --network-uuid="nw-${NW_INT_NAME}" \
        --mac-address="${mac}" \
        --ipv4-address="${ip}" \
        --port-name="${bif}"

    if [ $status -ne 0 ]; then
      echo "$output" >&2
      return $status
    fi

  done
  IFS=$oldIFS
}

set_broadcast() {
  DP_NAME=$1
  NW_PUB_NAME=$2
  host_bc=$3
  NW_INT_NAME=$4
  virt_bc=$5

  vnctl datapaths network add dp-${DP_NAME} nw-${NW_PUB_NAME} \
      --interface_uuid="if-${host_if}" \
      --broadcast-mac-address="${host_bc}"

  vnctl datapaths network add dp-${DP_NAME} nw-${NW_INT_NAME} \
      --interface_uuid="if-${host_if}" \
      --broadcast-mac-address="${virt_bc}"
}

set_dhcp() {
  DP_NAME=$1
  NW_NAME=$2

  dhcp_mac=$3
  dhcp_ip=$4

  vnctl interfaces add \
      --uuid="if-dhcp${NW_NAME}" \
      --owner-datapath-uuid="dp-${DP_NAME}" \
      --network-uuid="nw-${NW_NAME}" \
      --mac-address="${dhcp_mac}" \
      --ipv4-address="${dhcp_ip}" \
      --port-name="dhcp${NW_NAME}" \
      --mode="simulated"

  vnctl network_services add \
      --display-name="ns-dhcp${NW_NAME}" \
      --interface-uuid="if-dhcp${NW_NAME}" \
      --type="dhcp"
}

set_router(){
  DP_NAME=$1
  NW_NAME=$2

  router_mac=$3
  router_ip=$4

  vnctl interfaces add \
      --uuid="if-rt${NW_NAME}" \
      --owner-datapath-uuid="dp-${DP_NAME}" \
      --network-uuid="nw-${NW_NAME}" \
      --mac-address="${router_mac}" \
      --ipv4-address="${router_ip}" \
      --mode="simulated" \
      --enable-routing="true"

  vnctl network_services add \
      --display-name="ns-rt${NW_NAME}" \
      --interface-uuid="if-rt${NW_NAME}" \
      --type="router"
}

set_routelink() {
  DP_NAME=$1
  router_link_mac=$2
  router_datapath_mac=$3

  vnctl route_link add \
      --uuid="rl-pubint" \
      --mac-address="${router_link_mac}"

  vnctl datapaths route_link add dp-${DP_NAME} rl-pubint \
      --interface-uuid="if-${host_if}" \
      --mac-address="${router_datapath_mac}"
}

set_routes() {
  DP_NAME=$1
  NW_PUB_NAME=$2
  NW_INT_NAME=$3

  virtual_nwaddr=$4

  vnctl routes add \
      --interface-uuid="if-rt${NW_PUB_NAME}" \
      --route-link-uuid="rl-pubint" \
      --network-uuid="nw-${NW_PUB_NAME}" \
      --ipv4-network="${host_nw}"

  vnctl routes add \
      --interface-uuid="if-rt${NW_INT_NAME}" \
      --route-link-uuid="rl-pubint" \
      --network-uuid="nw-${NW_INT_NAME}" \
      --ipv4-network="${virtual_nwaddr}"
}

if [ -p /dev/stdin ]; then
  input=$(cat -)
fi

host_if=eth1

inetary=($(ip addr show dev br0 | grep 'inet'))

host_ip=$(echo ${inetary[1]} | awk -F '[/]' '{print $1}')

host_nw=$(ip route | grep ${host_ip} | awk '{print $1}')
host_mask=$(echo ${host_nw} | awk -F '[/]' '{print $2}')
host_nw=$(echo ${host_nw} | awk -F '[/]' '{print $1}')

infoary=($(ifconfig br0 | grep 'HWaddr'))
host_mac=${infoary[4]}

###

set_datapaths node1
set_networks public internal 192.168.99.0 24
set_interfaces node1 public internal
set_broadcast node1 public '10:00:00:00:01:01' internal '10:00:00:00:03:01'

set_dhcp node1 public '10:00:00:00:01:02' '172.31.32.254'
set_dhcp node1 internal '10:00:00:00:03:02' '192.168.99.254'

set_router node1 public '10:00:00:00:01:03' '172.31.32.1'
set_router node1 internal '10:00:00:00:03:03' '192.168.99.1'
set_routelink node1 '10:00:00:00:02:01' '10:00:00:00:02:02'

set_routes node1 public internal '192.168.99.0'

