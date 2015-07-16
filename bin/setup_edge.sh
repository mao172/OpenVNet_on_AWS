#! /bin/sh


#./bin/setup_ovs.sh 02:01:00:00:00:01 10.100.0.2 52.8.118.130
#ovs-vsctl add-port br0 gre_node1 -- set interface gre_node1 type=gre options:remote_ip=172.31.3.200

#./bin/setup_ovs.sh 02:01:00:00:00:02 10.100.0.3 52.8.238.28
#ovs-vsctl add-port br0 gre_node2 -- set interface gre_node2 type=gre options:remote_ip=192.168.12.61


dp0_name=dp-0
dp0_datapath_id=0x0000020100000001
dp0_node_id=vna0

dp1_name=dp-1
dp1_datapath_id=0x0000020100000002
dp1_node_id=vna1

nw_physical_uuid=nw-public
nw_physical_addr=10.100.0.0
nw_physical_prefix=24

nw_virtual_uuid=nw-virtual
nw_virtual_addr=10.1.11.0
nw_virtual_prefix=24

if_patch0_uuid=if-patch00
if_patch0_mac=02:01:00:00:00:01
if_patch0_addr=10.100.0.1
if_patch0_port=patch00

if_patch1_uuid=if-patch10
if_patch1_mac=02:01:00:00:00:02
if_patch1_addr=10.100.0.2
if_patch1_port=patch10

# datapath
vnctl datapaths add --uuid ${dp0_name} --display-name ${dp0_name} --dpid ${dp0_datapath_id} --node-id ${dp0_node_id}
vnctl datapaths add --uuid ${dp1_name} --display-name ${dp1_name} --dpid ${dp1_datapath_id} --node-id ${dp1_node_id}

# network
vnctl networks add --uuid ${nw_physical_uuid} --display-name ${nw_physical_uuid} --ipv4-network ${nw_physical_addr} --ipv4-prefix ${nw_physical_prefix} --network-mode physical

vnctl networks add --uuid ${nw_virtual_uuid} --display-name ${nw_virtual_uuid} --ipv4-network ${nw_virtual_addr} --ipv4-prefix ${nw_virtual_prefix} --network-mode virtual

# interface
vnctl interfaces add --uuid ${if_patch0_uuid} \
  --owner-datapath-uuid ${dp0_name} \
  --network-uuid ${nw_physical_uuid} \
  --mac-address ${if_patch0_mac} \
  --ipv4-address ${if_patch0_addr} \
  --port-name ${if_patch0_port} \
  --mode patch

  vnctl interfaces add --uuid ${if_patch1_uuid} \
    --owner-datapath-uuid ${dp1_name} \
    --network-uuid ${nw_physical_uuid} \
    --mac-address ${if_patch1_mac} \
    --ipv4-address ${if_patch1_addr} \
    --port-name ${if_patch1_port} \
    --mode patch


if [ -p /dev/stdin ]; then
  input=$(cat -)
  oldIFS=$IFS
  IFS=$'\n'
  lines=($input)

  for infc in ${lines[@]}
  do
    if_dpuuid=$(echo ${infc} | awk '{print $1}')
    if_name=$(echo ${infc} | awk '{print $2}')
    if_addr=$(echo ${infc} | awk '{print $3}')
    if_mac=$(echo ${infc} | awk '{print $4}')

    vnctl interfaces add --uuid if-${if_name} \
      --owner-datapath-uuid ${if_dpuuid} \
      --network-uuid ${nw_virtual_uuid} \
      --mac-address ${if_mac} \
      --ipv4-address ${if_addr} \
      --port-name ${if_name} \
      --mode vif
  done

  IFS=$oldIFS
fi

# datapath networks
vnctl datapaths network add ${dp0_name} ${nw_physical_uuid} \
  --broadcast-mac-address 02:01:00:01:00:01 \
  --interface_uuid  ${if_patch0_uuid}

vnctl datapaths network add ${dp1_name}${nw_physical_uuid} \
  --broadcast-mac-address 02:01:00:01:00:02 \
  --interface_uuid ${if_patch1_uuid}

vnctl datapaths network add ${dp0_name} ${nw_virtual_uuid} \
  --broadcast-mac-address 02:01:00:02:00:01 \
  --interface_uuid  ${if_patch0_uuid}

vnctl datapaths network add ${dp1_name} ${nw_virtual_uuid} \
  --broadcast-mac-address 02:01:00:02:00:02 \
  --interface_uuid ${if_patch1_uuid}
