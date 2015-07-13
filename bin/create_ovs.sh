#! /bin/sh

function make_bridge() {
  local brname=$1
cat > /etc/sysconfig/network-scripts/ifcfg-${brname} <<EOF
DEVICE=${brname}
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=none
EOF

  ifdown ${brname}
  ifup ${brname}
}

make_bridge $1
