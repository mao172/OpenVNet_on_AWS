#! /bin/sh

inetary=($(ifconfig eth1 | grep 'inet addr'))

ipaddress=$(echo ${inetary[1]} | awk -F '[: ]' '{print $2}')
netmask=$(echo ${inetary[3]} | awk -F '[: ]' '{print $2}')

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br0
BOOTPROTO=none
ONBOOT=yes
HOTPLUG=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0 <<EOF
DEVICE=br0
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=static
IPADDR=${ipaddress}
NETMASK=${netmask}
HOTPLUG=no
OVS_EXTRA="
 set bridge     \${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     \${DEVICE} other_config:disable-in-band=true --
 set bridge     \${DEVICE} other-config:datapath-id=0000aaaaaaaaaaaa --
 set bridge     \${DEVICE} other-config:hwaddr=02:01:00:00:00:01 --
 set-fail-mode  \${DEVICE} standalone --
 set-controller \${DEVICE} tcp:127.0.0.1:6633
"
EOF

service openvswitch start
ifup br0 eth1

service network restart
