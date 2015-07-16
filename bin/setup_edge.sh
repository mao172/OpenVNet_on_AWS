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

# datapath
vnctl datapaths add --uuid ${dp0_name} --display-name ${dp0_name} --dpid ${dp0_datapath_id} --node-id ${dp0_node_id}
vnctl datapaths add --uuid ${dp1_name} --display-name ${dp1_name} --dpid ${dp1_datapath_id} --node-id ${dp1_node_id}

# network
vnctl networks add --uuid ${nw_physical_uuid} --display-name ${nw_physical_uuid} --ipv4-network ${nw_physical_addr} --ipv4-prefix ${nw_physical_prefix} --network-mode physical

vnctl networks add --uuid ${nw_virtual_uuid} --display-name ${nw_virtual_uuid} --ipv4-network ${nw_virtual_addr} --ipv4-prefix ${nw_virtual_prefix} --network-mode virtual

# interface
vnctl interfaces add --uuid if-patch10 --owner-datapath-uuid dp-0 --network-uuid nw-public --mac-address 02:01:00:00:00:01 --ipv4-address 10.100.0.2 --port-name patch10 --mode patch
vnctl interfaces add --uuid if-patch00 --owner-datapath-uuid dp-1 --network-uuid nw-public --mac-address 02:01:00:00:00:02 --ipv4-address 10.100.0.3 --port-name patch00 --mode patch

#vnctl interfaces add --uuid if-edge0 --owner-datapath-uuid dp-0 --mac-address 7a:b4:f4:08:41:41 --ipv4-address 10.100.0.12 --port-name ptedge #--mode edge
#vnctl interfaces add --uuid if-edge1 --owner-datapath-uuid dp-1 --mac-address a6:31:58:ed:44:47 --ipv4-address 10.100.0.13 --port-name ptedge1 #--mode edge


vnctl interfaces add --uuid if-grenode1 --owner-datapath-uuid dp-0 --network-uuid nw-virtual --mac-address 7a:a7:15:32:ff:7a --ipv4-address 10.1.11.1 --port-name gre_node1 --mode vif
vnctl interfaces add --uuid if-grenote2 --owner-datapath-uuid dp-1 --network-uuid nw-virtual --mac-address fe:0a:61:77:35:e6 --ipv4-address 10.1.11.2 --port-name gre_node2 --mode vif

# datapath networks
vnctl datapaths network add dp-0 nw-public --broadcast-mac-address 02:01:00:01:00:01 --interface_uuid if-patch10
vnctl datapaths network add dp-1 nw-public --broadcast-mac-address 02:01:00:01:00:02 --interface_uuid if-patch00
vnctl datapaths network add dp-0 nw-virtual --broadcast-mac-address 02:01:00:02:00:01 --interface_uuid if-patch10
vnctl datapaths network add dp-1 nw-virtual --broadcast-mac-address 02:01:00:02:00:02 --interface_uuid if-patch00

# translation
#vnctl translations add --uuid tr-0 --interface-uuid if-edge0 --mode vnet_edge
#vnctl translations add --uuid tr-1 --interface-uuid if-edge1 --mode vnet_edge

#vnctl vlan_translations add --uuid vt-0 --vlan-id 100 --network-id nw-virtual --translation-uuid tr-0
#vnctl vlan_translations add --uuid vt-1 --vlan-id 101 --network-id nw-virtual --translation-uuid tr-1


curl -s -X POST \
 --data-urlencode uuid=vt-0 \
 --data-urlencode vlan_id=100 \
 --data-urlencode network_uuid=nw-virtual \
 --data-urlencode translation_uuid=tr-0 \
http://localhost:9090/api/vlan_translations

curl -s -X POST \
 --data-urlencode uuid=vt-1 \
 --data-urlencode vlan_id=101 \
 --data-urlencode network_uuid=nw-virtual \
 --data-urlencode translation_uuid=tr-1 \
http://localhost:9090/api/vlan_translations

