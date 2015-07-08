#! /bin/sh

nic=$1

inetary=($(ip addr show dev ${nic} | grep inet))

ipaddress=$(echo ${inetary[1]} | awk -F '[/]' '{print $1}')
netmask=$2

infoary=($(ip addr show dev ${nic} | grep 'link/ether'))
macaddress=${infoary[1]}

cat > /etc/sysconfig/network-scripts/ifcfg-${nic} <<EOF
DEVICE=${nic}
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
 set bridge     \${DEVICE} other-config:datapath-id=0000$(echo ${macaddress} | tr -d ':') --
 set bridge     \${DEVICE} other-config:hwaddr=${macaddress} --
 set-fail-mode  \${DEVICE} standalone --
 set-controller \${DEVICE} tcp:127.0.0.1:6633
"
EOF



systemctl restart openvswitch
ifup br0 ${nic}

systemctl restart network

ip addr show dev br0
ip addr show dev ${nic}

ovs-vsctl show
