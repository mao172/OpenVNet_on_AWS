#! /bin/sh

brname=br0

macaddress=${1}
ipaddress=${2}
netmask=${3}


cat > /etc/sysconfig/network-scripts/ifcfg-${brname} <<EOF
DEVICE=${brname}
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=static
IPADDR=${ipaddress}
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
ifdown ${brname}
ifup ${brname}

ifconfig ${brname}
ovs-vsctl show
