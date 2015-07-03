#! /bin/sh

inetary=($(ifconfig eth1 | grep 'inet addr'))

ipaddress=$(echo ${inetary[1]} | awk -F '[: ]' '{print $2}')
netmask=$(echo ${inetary[3]} | awk -F '[: ]' '{print $2}')

infoary=($(ifconfig eth1 | grep 'HWaddr'))
macaddress=${infoary[4]}

cat > /etc/sysconfig/network-scripts/ifcfg-br0 <<EOF
DEVICE=br0
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=static
HOTPLUG=no
OVS_EXTRA="
 set bridge     \${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     \${DEVICE} other_config:disable-in-band=true --
 set bridge     \${DEVICE} other-config:datapath-id=0000$(echo ${macaddress} | tr -d ':') --
 set bridge     \${DEVICE} other-config:hwaddr=${macaddress} --
 set-fail-mode  \${DEVICE} standalone --
 set-controller \${DEVICE} tcp:127.0.0.1:6633
"
EOF

service openvswitch start
ifup br0

service network restart

ifconfig br0

ovs-vsctl show
